// Emergency response teams: an admin picks a team type and role slots, offers it to ghosts,
// then dispatches whoever readied up. Team types and roles live in response_team_types.dm.

#define RESPONSE_STAGE_SETUP "setup"
#define RESPONSE_STAGE_LOCKED "locked"
#define RESPONSE_STAGE_GATHERING "gathering"
#define RESPONSE_STAGE_ACTIVE "active"

#define RESPONSE_ROLE_MAX 5
#define RESPONSE_OFFER_TIMEOUT (2 MINUTES)
#define RESPONSE_SCOM_COLOR "#d4af37"

GLOBAL_DATUM_INIT(response_team, /datum/response_team, new)
GLOBAL_LIST_EMPTY(response_team_spawns)

/client/proc/response_team_panel()
	set category = "-GameMaster-"
	set name = "Emergency Response Team"
	if(!check_rights(R_ADMIN))
		return
	GLOB.response_team.ui_interact(mob)

/obj/effect/landmark/response_team
	name = "ERT response spawn"
	icon = 'icons/mob/landmarks.dmi'
	icon_state = "arrow"

/obj/effect/landmark/response_team/Initialize(mapload)
	. = ..()
	GLOB.response_team_spawns += loc

/// A player in the waiting room, and later on the field
/datum/response_member
	var/ckey
	var/key
	var/admin = FALSE
	/// Advclass typepath of the chosen role
	var/role
	var/ready = FALSE
	var/removed = FALSE
	var/datum/weakref/body
	var/datum/weakref/stone

/// Deletes the body and everything on it, and sends the player back to the lobby if they're still attached to it
/datum/response_member/proc/despawn()
	var/mob/living/carbon/human/H = body?.resolve()
	if(!H)
		return
	var/mob/player = H.client ? H : H.get_ghost(TRUE, TRUE)
	if(H.mind)
		H.mind.unknow_all_people()
		for(var/datum/mind/MF in get_minds())
			H.mind.become_unknown_to(MF)
	GLOB.chosen_names -= H.real_name
	if(player?.client)
		SSdroning.kill_droning(player.client)
		SSdroning.kill_loop(player.client)
		SSdroning.kill_rain(player.client)
		var/mob/dead/new_player/NP = new()
		NP.key = player.key
		if(player != H)
			qdel(player)
	for(var/obj/item/I as anything in H.get_all_gear())
		qdel(I)
	qdel(H)

/// Personal scomstone that only talks to the rest of the team, and receives admin messages
/obj/item/scomstone/response_team
	name = "response stone"
	desc = "A plain ring set with a bright, steady gem. It hums with the voices of your company."
	icon_state = "ring_crownscom"
	messagereceivedsound = 'sound/misc/garrisonscom.ogg'
	hearrange = 0
	sellprice = 0

/obj/item/scomstone/response_team/Initialize(mapload)
	. = ..()
	SSroguemachine.scomm_machines -= src
	scomstone_number = null

/obj/item/scomstone/response_team/attack_right(mob/living/carbon/human/user)
	if(user.restrained() || user.incapacitated())
		to_chat(user, span_warning("I cannot use this while restrained or incapacitated!"))
		return
	user.changeNext_move(CLICK_CD_INTENTCAP)
	visible_message(span_notice("[user] presses their ring against their mouth."))
	var/input_text = input(user, "Enter your message:", "Message")
	if(!input_text)
		return
	user.whisper(input_text)
	var/usedcolor = user.voicecolor_override || user.voice_color
	GLOB.response_team.relay("<big><span style='color: [RESPONSE_SCOM_COLOR]'>[input_text]</span></big>", src, usedcolor)

/// Admin message, styled so it stands out from the team's own chatter
/obj/item/scomstone/response_team/proc/receive_admin(message)
	repeat_message("<big><b><span style='color: [RESPONSE_SCOM_COLOR]'>[message]</span></b></big>")

/datum/ui_state/response_team_state/can_use_topic(src_object, mob/user)
	if(check_rights_for(user.client, R_ADMIN))
		return UI_INTERACTIVE
	var/datum/response_team/team = src_object
	if(team.stage == RESPONSE_STAGE_GATHERING && team.members[user.ckey])
		return UI_INTERACTIVE
	return UI_CLOSE

GLOBAL_DATUM_INIT(response_team_state, /datum/ui_state/response_team_state, new)

/// Only one response can be prepared or deployed at a time
/datum/response_team
	var/stage = RESPONSE_STAGE_SETUP
	/// Team type path -> instance
	var/list/team_types = list()
	var/datum/response_team_type/team_type
	/// Role path -> slots requested
	var/list/slots = list()
	var/offer_admins = TRUE
	var/offer_ghosts = TRUE
	var/mission = ""
	var/reason = ""
	var/caller_ckey
	/// Bumped on every call so late answers to an old prompt are ignored
	var/call_id = 0
	/// ckey -> /datum/response_member, the waiting room and then the deployed team
	var/list/members = list()

/datum/response_team/New()
	for(var/path in subtypesof(/datum/response_team_type))
		team_types[path] = new path

/datum/response_team/proc/reset()
	stage = RESPONSE_STAGE_SETUP
	team_type = null
	slots = list()
	offer_admins = TRUE
	offer_ghosts = TRUE
	mission = ""
	reason = ""
	caller_ckey = null
	members = list()
	SStgui.update_uis(src)

/// The caller runs the call until it deploys, unless they disconnect. Any admin can manage an active team.
/datum/response_team/proc/can_control(mob/user)
	if(!check_rights_for(user?.client, R_ADMIN))
		return FALSE
	if(stage == RESPONSE_STAGE_LOCKED || stage == RESPONSE_STAGE_GATHERING)
		return user.ckey == caller_ckey || !GLOB.directory[caller_ckey]
	return TRUE

/datum/response_team/proc/count_role(role)
	. = 0
	for(var/member_ckey in members)
		var/datum/response_member/member = members[member_ckey]
		if(member.role == role)
			.++

/datum/response_team/proc/slot_summary()
	var/list/parts = list()
	for(var/datum/advclass/role as anything in slots)
		if(slots[role])
			parts += "[slots[role]]x [initial(role.name)]"
	return english_list(parts, "no roles")

/// Mobs that are free to answer or deploy
/datum/response_team/proc/is_available(mob/M)
	return M?.client && (isobserver(M) || isnewplayer(M) || istype(M, /mob/living/carbon/spirit))

/datum/response_team/proc/log_response(mob/user, message)
	log_admin("[key_name(user)] [message]")
	message_admins(span_danger("[key_name_admin(user)] [message]"))

/datum/response_team/ui_state(mob/user)
	return GLOB.response_team_state

/datum/response_team/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ResponseTeamPanel", "Emergency Response")
		ui.open()

/datum/response_team/ui_static_data(mob/user)
	var/list/data = list()
	var/list/types = list()
	for(var/path in team_types)
		var/datum/response_team_type/type = team_types[path]
		types += list(list(
			"id" = "[path]",
			"name" = type.name,
			"desc" = type.desc,
		))
	data["types"] = types
	data["role_max"] = RESPONSE_ROLE_MAX
	return data

/datum/response_team/ui_data(mob/user)
	var/list/data = list()
	var/is_admin = check_rights_for(user.client, R_ADMIN)
	data["stage"] = stage
	data["is_admin"] = is_admin
	data["can_control"] = can_control(user)
	data["team_type"] = team_type ? "[team_type.type]" : null
	data["team_name"] = team_type?.name
	data["mission"] = mission
	var/list/roles = list()
	for(var/datum/advclass/role as anything in slots)
		roles += list(list(
			"id" = "[role]",
			"name" = initial(role.name),
			"desc" = initial(role.tutorial),
			"total" = slots[role],
			"taken" = count_role(role),
		))
	data["roles"] = roles
	var/list/member_data = list()
	for(var/member_ckey in members)
		var/datum/response_member/member = members[member_ckey]
		var/self = member_ckey == user.ckey
		var/list/entry = list(
			"ckey" = (is_admin || self) ? member_ckey : "Unknown",
			"self" = self,
			"admin" = is_admin && member.admin,
			"role" = member.role ? "[member.role]" : null,
			"ready" = member.ready,
		)
		if(is_admin && stage == RESPONSE_STAGE_ACTIVE)
			var/mob/living/carbon/human/H = member.body?.resolve()
			entry["name"] = H?.real_name
			entry["removed"] = member.removed
			if(member.removed)
				entry["status"] = "Removed"
			else if(!H)
				entry["status"] = "Gone"
			else
				entry["status"] = H.stat == DEAD ? "Dead" : "Alive"
		member_data += list(entry)
	data["members"] = member_data
	if(is_admin)
		data["offer_admins"] = offer_admins
		data["offer_ghosts"] = offer_ghosts
		data["caller"] = caller_ckey
		data["reason"] = reason
	return data

/datum/response_team/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui.user
	var/datum/response_member/self = members[user.ckey]
	// Waiting room actions, open to anyone queued
	switch(action)
		if("pick_role")
			var/role = text2path(params["role"])
			if(stage != RESPONSE_STAGE_GATHERING || !self || !(role in slots))
				return
			if(self.role != role && count_role(role) >= slots[role])
				return
			self.role = role
			self.ready = FALSE
			return TRUE
		if("ready")
			if(stage != RESPONSE_STAGE_GATHERING || !self?.role)
				return
			self.ready = !self.ready
			return TRUE
		if("withdraw")
			if(stage != RESPONSE_STAGE_GATHERING || !self)
				return
			members -= user.ckey
			return TRUE

	if(!can_control(user))
		return
	var/datum/response_member/target = members[params["ckey"]]
	switch(stage)
		if(RESPONSE_STAGE_SETUP)
			switch(action)
				if("select_type")
					team_type = team_types[text2path(params["type"])]
					slots = list()
					for(var/role in team_type?.roles)
						slots[role] = 0
					return TRUE
				if("set_slots")
					var/role = text2path(params["role"])
					if(!(role in slots))
						return
					slots[role] = clamp(round(text2num(params["amount"])), 0, RESPONSE_ROLE_MAX)
					return TRUE
				if("toggle_admins")
					offer_admins = !offer_admins
					return TRUE
				if("toggle_ghosts")
					offer_ghosts = !offer_ghosts
					return TRUE
				if("confirm")
					mission = trim(params["mission"], MAX_MESSAGE_LEN)
					return confirm(user)
		if(RESPONSE_STAGE_LOCKED)
			switch(action)
				if("cancel_call")
					log_response(user, "cancelled the [team_type.name] response team before calling it.")
					reset()
					SStgui.close_uis(src)
					return
				if("call")
					stage = RESPONSE_STAGE_GATHERING
					call_id++
					send_offers()
					log_response(user, "called for the [team_type.name] response team.")
					return TRUE
		if(RESPONSE_STAGE_GATHERING)
			switch(action)
				if("kick")
					if(!target)
						return
					members -= target.ckey
					to_chat(get_mob_by_ckey(target.ckey), span_warning("You have been removed from the emergency response."))
					log_response(user, "kicked [target.key] from the [team_type.name] response team waiting room.")
					return TRUE
				if("dispatch")
					return dispatch(user)
				if("cancel_team")
					for(var/member_ckey in members)
						to_chat(get_mob_by_ckey(member_ckey), span_warning("The emergency response has been called off."))
					log_response(user, "cancelled the [team_type.name] response team.")
					reset()
					return
		if(RESPONSE_STAGE_ACTIVE)
			switch(action)
				if("pp")
					var/mob/M = target?.body?.resolve() || get_mob_by_ckey(target?.ckey)
					if(M)
						user.client.holder.show_player_panel(M)
					return
				if("follow")
					var/mob/M = target?.body?.resolve()
					if(!M)
						return
					var/client/C = user.client
					if(!isobserver(user) && !C.admin_ghost())
						return
					var/mob/dead/observer/ghost = C.mob
					ghost.ManualFollow(M)
					return
				if("message")
					return message_member(user, target)
				if("remove")
					return remove_member(user, target)
				if("broadcast")
					return broadcast(user)
				if("end")
					return end_deployment(user)

/datum/response_team/proc/confirm(mob/user)
	if(!team_type)
		return
	var/total = 0
	for(var/role in slots)
		total += slots[role]
	if(!total)
		to_chat(user, span_warning("The response team needs at least one role."))
		return
	if(!offer_admins && !offer_ghosts)
		to_chat(user, span_warning("The response team must be offered to admins, ghosts or both."))
		return
	var/new_reason = tgui_input_text(user, "Why is this team being called?", "Reason for Team", multiline = TRUE)
	if(!new_reason || stage != RESPONSE_STAGE_SETUP || !can_control(user))
		return
	reason = new_reason
	caller_ckey = user.ckey
	stage = RESPONSE_STAGE_LOCKED
	log_response(user, "prepared a [team_type.name] response team ([slot_summary()]). Reason: [reason]")
	return TRUE

/datum/response_team/proc/send_offers()
	for(var/mob/M as anything in GLOB.player_list)
		if(!is_available(M))
			continue
		if(check_rights_for(M.client, R_ADMIN) ? !offer_admins : !offer_ghosts)
			continue
		if(M.ckey in GLOB.poll_ignore[POLL_IGNORE_RESPONSE_TEAM])
			continue
		offer(M, call_id)

/datum/response_team/proc/offer(mob/M, id)
	set waitfor = FALSE
	window_flash(M.client)
	var/answer = askuser(M, "An emergency response has been called, will you answer?", "Emergency Response", "Yes", "No", "Never for this round", StealFocus = FALSE, Timeout = RESPONSE_OFFER_TIMEOUT)
	if(answer == 3)
		GLOB.poll_ignore[POLL_IGNORE_RESPONSE_TEAM] |= M.ckey
		return
	if(answer != 1 || id != call_id || stage != RESPONSE_STAGE_GATHERING || !is_available(M) || members[M.ckey])
		return
	var/datum/response_member/member = new
	member.ckey = M.ckey
	member.key = M.key
	member.admin = check_rights_for(M.client, R_ADMIN)
	members[M.ckey] = member
	to_chat(M, span_notice("You answer the call. <a href=\"?src=[REF(src)];open=1\">Open the waiting room</a>"))
	ui_interact(M)
	to_chat(GLOB.directory[caller_ckey], span_notice("[M.key] has answered the [team_type.name] response."))
	SStgui.update_uis(src)

/datum/response_team/Topic(href, list/href_list)
	. = ..()
	if(href_list["open"] && stage == RESPONSE_STAGE_GATHERING && members[usr.ckey])
		ui_interact(usr)

/datum/response_team/proc/dispatch(mob/user)
	var/list/deployed = list()
	for(var/member_ckey in members)
		var/datum/response_member/member = members[member_ckey]
		if(member.ready && member.role && is_available(get_mob_by_ckey(member_ckey)))
			deployed += member
	if(!length(deployed))
		to_chat(user, span_warning("Nobody is ready to deploy."))
		return
	if(!length(GLOB.response_team_spawns))
		to_chat(user, span_warning("There is no ERT response spawn landmark, the team will arrive at your location."))
	stage = RESPONSE_STAGE_ACTIVE
	var/list/roster = list()
	for(var/member_ckey in members.Copy())
		var/datum/response_member/member = members[member_ckey]
		var/mob/M = get_mob_by_ckey(member_ckey)
		if(!(member in deployed))
			members -= member_ckey
			to_chat(M, span_warning("The emergency response has been dispatched without you."))
			continue
		var/turf/T = length(GLOB.response_team_spawns) ? pick(GLOB.response_team_spawns) : get_turf(user)
		spawn_member(member, M, T)
		var/datum/advclass/role = member.role
		roster += "[member.ckey] as [initial(role.name)]"
	log_response(user, "dispatched the [team_type.name] response team: [english_list(roster)].")
	return TRUE

/datum/response_team/proc/spawn_member(datum/response_member/member, mob/M, turf/T)
	SStgui.close_user_uis(M, src)
	if(isnewplayer(M))
		var/mob/dead/new_player/N = M
		N.close_spawn_windows()
	var/mob/living/carbon/human/species/human/northern/H = new(T)
	H.key = M.key
	var/datum/advclass/role = SSrole_class_handler.classes_by_type[member.role]
	role.equipme(H)
	ADD_TRAIT(H, TRAIT_RESPONSE_TEAM, TRAIT_GENERIC)
	var/obj/item/scomstone/response_team/stone = new(H)
	stone.name = "[team_type.name] stone"
	if(!H.equip_to_slot_if_possible(stone, SLOT_RING, disable_warning = TRUE))
		H.put_in_hands(stone)
	member.body = WEAKREF(H)
	member.stone = WEAKREF(stone)
	to_chat(H, span_boldannounce("I am a [role.name] of the [team_type.name]."))
	if(mission)
		to_chat(H, span_notice("<b>Mission:</b> [mission]"))
	to_chat(H, span_notice("Right click my [stone.name] to speak with the rest of the team."))

/// Sends a team scomstone message to every deployed member
/datum/response_team/proc/relay(message, atom/source, tcolor)
	for(var/member_ckey in members)
		var/datum/response_member/member = members[member_ckey]
		var/obj/item/scomstone/response_team/stone = member.stone?.resolve()
		stone?.repeat_message(message, source, tcolor)

/datum/response_team/proc/message_member(mob/user, datum/response_member/member)
	var/obj/item/scomstone/response_team/stone = member?.stone?.resolve()
	if(!stone || member.removed)
		to_chat(user, span_warning("That responder no longer has their stone."))
		return
	var/message = tgui_input_text(user, "Message to the stone of [member.key]", "Direct Message")
	if(!message || QDELETED(stone))
		return
	stone.receive_admin(message)
	log_response(user, "messaged response team member [member.key]: [message]")

/datum/response_team/proc/broadcast(mob/user)
	var/message = tgui_input_text(user, "Message for the whole team", "Broadcast to Team")
	if(!message || stage != RESPONSE_STAGE_ACTIVE)
		return
	for(var/member_ckey in members)
		var/datum/response_member/member = members[member_ckey]
		var/obj/item/scomstone/response_team/stone = member.stone?.resolve()
		stone?.receive_admin(message)
	log_response(user, "broadcast to the [team_type.name] response team: [message]")

/datum/response_team/proc/remove_member(mob/user, datum/response_member/member)
	if(!member || member.removed)
		return
	if(tgui_alert(user, "Remove [member.key] from the response team? Their body and gear will be deleted.", "Remove Responder", list("Yes", "No")) != "Yes")
		return
	if(member.removed || stage != RESPONSE_STAGE_ACTIVE)
		return
	member.removed = TRUE
	member.despawn()
	log_response(user, "removed [member.key] from the [team_type.name] response team.")
	return TRUE

/datum/response_team/proc/end_deployment(mob/user)
	if(tgui_alert(user, "Are you sure you want to end this deployment?", "End Deployment", list("Yes", "No")) != "Yes")
		return
	if(stage != RESPONSE_STAGE_ACTIVE)
		return
	for(var/member_ckey in members)
		var/datum/response_member/member = members[member_ckey]
		if(!member.removed)
			member.despawn()
	log_response(user, "ended the deployment of the [team_type.name] response team.")
	reset()

/// Responders have no job, so they examine as their role instead
/mob/living/carbon/human/get_role_title()
	. = ..()
	if(!. && HAS_TRAIT(src, TRAIT_RESPONSE_TEAM))
		return advjob

#undef RESPONSE_STAGE_SETUP
#undef RESPONSE_STAGE_LOCKED
#undef RESPONSE_STAGE_GATHERING
#undef RESPONSE_STAGE_ACTIVE
#undef RESPONSE_ROLE_MAX
#undef RESPONSE_OFFER_TIMEOUT
#undef RESPONSE_SCOM_COLOR
