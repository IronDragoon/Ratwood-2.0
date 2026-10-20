// Emergency response teams: an admin picks a team type and role slots, offers it to ghosts,
// then dispatches whoever readied up. Team types and roles live in response_team_types.dm.

#define RESPONSE_STAGE_SETUP "setup"
#define RESPONSE_STAGE_LOCKED "locked"
#define RESPONSE_STAGE_GATHERING "gathering"
#define RESPONSE_STAGE_ACTIVE "active"

#define RESPONSE_ROLE_MAX 5
#define RESPONSE_OFFER_TIMEOUT (2 MINUTES)
/// Oldest stone messages drop out of the panel's log past this many
#define RESPONSE_LOG_MAX 200

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
	/// Character name, kept so it can be freed even if the body is destroyed
	var/name
	var/datum/weakref/body
	var/datum/weakref/stone
	/// Weakrefs to every item the responder spawned with, stone included
	var/list/issued = list()
	/// Whether issued has been filled in, which waits until they've made any choices their outfit asks for
	var/kit_recorded = FALSE

/// Deletes the body and its issued kit, and sends the player back to the lobby if they're still the responder or its ghost
/datum/response_member/proc/despawn()
	var/mob/living/carbon/human/H = body?.resolve()
	clear_gear(H)
	H?.forget_identity()
	GLOB.chosen_names -= name
	var/mob/player = get_mob_by_ckey(ckey)
	if(player?.client && (player == H || isobserver(player)))
		player.return_to_lobby()
		if(player != H)
			qdel(player)
	qdel(H)

/// Deletes the issued kit wherever it ended up. Anything picked up in the round, stowed in the kit or still on the body, is left on the floor.
/datum/response_member/proc/clear_gear(mob/living/carbon/human/H)
	var/list/kit = list()
	// Still choosing their gear, so nothing on them can be loot yet
	if(H && !kit_recorded)
		kit = H.get_all_carried_items()
	for(var/datum/weakref/ref as anything in issued)
		var/obj/item/I = ref.resolve()
		if(I)
			kit += I
	for(var/obj/item/I as anything in kit)
		for(var/obj/item/stowed in I.contents)
			if(!(stowed in kit))
				stowed.forceMove(get_turf(I))
	if(H)
		for(var/obj/item/I in H.get_equipped_items(TRUE) + H.held_items)
			if(!(I in kit))
				H.dropItemToGround(I, force = TRUE)
	for(var/obj/item/I as anything in kit)
		if(!QDELETED(I))
			qdel(I)

/// Personal scomstone that only talks to the rest of the team, and receives admin messages.
/// It is bound to the responder it was issued to and crumbles if anyone else takes it.
/obj/item/scomstone/response_team
	name = "response stone"
	desc = "A plain ring set with a bright, steady gem. It hums with the voices of your company."
	icon_state = "ring_crownscom"
	messagereceivedsound = 'sound/misc/garrisonscom.ogg'
	hearrange = 0
	sellprice = 0
	cooldown = 5 SECONDS
	/// The responder this stone was issued to
	var/datum/weakref/owner

/obj/item/scomstone/response_team/Initialize(mapload)
	. = ..()
	SSroguemachine.scomm_machines -= src
	scomstone_number = null

/obj/item/scomstone/response_team/equipped(mob/user, slot, initial)
	. = ..()
	if(!is_owner(user))
		crumble(user)

/obj/item/scomstone/response_team/proc/is_owner(mob/user)
	return user && user == owner?.resolve()

/obj/item/scomstone/response_team/proc/crumble(mob/user)
	to_chat(user, span_warning("[src] crumbles to dust in my grasp."))
	// Deferred so the equip that triggered this can finish with a valid item
	QDEL_IN(src, 0)

/obj/item/scomstone/response_team/attack_right(mob/living/carbon/human/user)
	if(!is_owner(user))
		crumble(user)
		return
	if(user.restrained() || user.incapacitated())
		to_chat(user, span_warning("I cannot use this while restrained or incapacitated!"))
		return
	if(on_cooldown)
		to_chat(user, span_warning("[src] is still humming from my last message."))
		return
	user.changeNext_move(CLICK_CD_INTENTCAP)
	visible_message(span_notice("[user] presses their ring against their mouth."))
	var/input_text = trim(input(user, "Enter your message:", "Message"), MAX_MESSAGE_LEN)
	// Anything could have happened while they were typing
	if(!input_text || QDELETED(src) || on_cooldown || loc != user || !is_owner(user))
		return
	if(user.stat != CONSCIOUS || user.restrained() || user.incapacitated())
		return
	user.whisper(input_text)
	user.log_talk(input_text, LOG_SAY, tag = "response stone")
	on_cooldown = TRUE
	addtimer(VARSET_CALLBACK(src, on_cooldown, FALSE), cooldown)
	GLOB.response_team.relay(html_encode(input_text), src, user.voicecolor_override || user.voice_color)
	GLOB.response_team.log_chat(user.real_name, user.ckey, "Team", input_text)

/// Jupon every responder wears, named and coloured for their role so the team is easy to pick out.
/// The design is fixed, set from the role's tabard vars when it is issued.
/obj/item/clothing/cloak/stabard/surcoat/response_team
	desc = "A jupon in the colours of a sworn company."
	sellprice = 0
	picked = TRUE

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
	/// Raw text, encode before putting it in chat
	var/mission = ""
	/// Raw text, encode before putting it in chat
	var/reason = ""
	var/caller_ckey
	/// Bumped on every call so late answers to an old prompt are ignored
	var/call_id = 0
	/// ckey -> /datum/response_member, the waiting room and then the deployed team
	var/list/members = list()
	/// ckey -> call_id of an offer prompt still open, so offering the same call again doesn't stack a second one
	var/list/pending_offers = list()
	/// ckeys kicked from this call, who aren't offered it again
	var/list/kicked = list()
	/// Every stone message of the deployment in the order sent, for the admin panel. Messages are raw text.
	var/list/chat_log = list()

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
	kicked = list()
	chat_log = list()
	update_static_data_for_all_viewers()

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

/// Mobs that are free to answer or deploy. Spirits are left out, their key belongs to a body elsewhere.
/datum/response_team/proc/is_available(mob/M)
	return M?.client && (isobserver(M) || isnewplayer(M))

/datum/response_team/proc/is_banned(mob/M)
	return is_banned_from(M.ckey, ROLE_RESPONSE_TEAM)

/// User can be a mob or a client
/datum/response_team/proc/log_response(user, message)
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
		var/datum/response_team_type/team = team_types[path]
		types += list(list(
			"id" = "[path]",
			"name" = team.name,
			"desc" = team.desc,
		))
	data["types"] = types
	data["role_max"] = RESPONSE_ROLE_MAX
	data["mission_max"] = MAX_MESSAGE_LEN
	// Static so the whole log is only resent when a message is added, not on every update
	if(check_rights_for(user.client, R_ADMIN))
		data["chat_log"] = chat_log
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
			entry["name"] = member.name
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
			if(stage != RESPONSE_STAGE_GATHERING || !self || !(role in slots) || self.role == role)
				return
			if(count_role(role) >= slots[role])
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
					kicked |= target.ckey
					to_chat(get_mob_by_ckey(target.ckey), span_warning("You have been removed from the emergency response."))
					log_response(user, "kicked [target.key] from the [team_type.name] response team waiting room.")
					return TRUE
				if("reoffer")
					var/sent = send_offers()
					log_response(user, "offered the [team_type.name] response team again, to [sent] player\s.")
					return TRUE
				if("dispatch")
					return dispatch(user)
				if("cancel_team")
					return cancel_team(user)
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
					if(!isobserver(user))
						C.admin_ghost()
					// admin_ghost() can be declined from the lobby
					var/mob/dead/observer/ghost = C.mob
					if(isobserver(ghost))
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
	var/new_reason = tgui_input_text(user, "Why is this team being called?", "Reason for Team", max_length = MAX_MESSAGE_LEN, multiline = TRUE, encode = FALSE)
	if(!new_reason || stage != RESPONSE_STAGE_SETUP || !can_control(user))
		return
	reason = new_reason
	caller_ckey = user.ckey
	stage = RESPONSE_STAGE_LOCKED
	log_response(user, "prepared a [team_type.name] response team ([slot_summary()]). Reason: [html_encode(reason)]. Mission: [mission ? html_encode(mission) : "none"]")
	return TRUE

/// Offers the call to everyone eligible who isn't already queued, being asked, or kicked. Returns how many were asked.
/datum/response_team/proc/send_offers()
	. = 0
	for(var/mob/M as anything in GLOB.player_list)
		if(!is_available(M))
			continue
		if(check_rights_for(M.client, R_ADMIN) ? !offer_admins : !offer_ghosts)
			continue
		if(members[M.ckey] || pending_offers[M.ckey] == call_id || (M.ckey in kicked))
			continue
		if(M.ckey in GLOB.poll_ignore[POLL_IGNORE_RESPONSE_TEAM])
			continue
		if(is_banned(M))
			continue
		offer(M, call_id)
		.++

/datum/response_team/proc/offer(mob/M, id)
	set waitfor = FALSE
	// Kept rather than read from M later, which may be gone by the time they answer
	var/offered_ckey = M.ckey
	pending_offers[offered_ckey] = id
	window_flash(M.client)
	var/answer = askuser(M, "An emergency response has been called, will you answer?", "Emergency Response", "Yes", "No", "Never for this round", StealFocus = FALSE, Timeout = RESPONSE_OFFER_TIMEOUT)
	// A newer call may have offered again while this prompt was open
	if(pending_offers[offered_ckey] == id)
		pending_offers -= offered_ckey
	if(answer == 3)
		GLOB.poll_ignore[POLL_IGNORE_RESPONSE_TEAM] |= offered_ckey
		return
	if(answer != 1 || QDELETED(M) || members[M.ckey])
		return
	if(id != call_id || stage != RESPONSE_STAGE_GATHERING)
		to_chat(M, span_warning("That emergency response is no longer gathering."))
		return
	if(!is_available(M))
		to_chat(M, span_warning("You can only answer an emergency response as a ghost or from the lobby."))
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

/datum/response_team/proc/cancel_team(mob/user)
	if(tgui_alert(user, "Call off this response? Everyone waiting will be sent away.", "Cancel Team", list("Yes", "No")) != "Yes")
		return
	if(stage != RESPONSE_STAGE_GATHERING || !can_control(user))
		return
	call_off(user, "cancelled the [team_type.name] response team.")

/// Sends everyone waiting away and resets the panel
/datum/response_team/proc/call_off(mob/user, log_message)
	for(var/member_ckey in members)
		to_chat(get_mob_by_ckey(member_ckey), span_warning("The emergency response has been called off."))
	log_response(user, log_message)
	reset()

/datum/response_team/proc/dispatch(mob/user)
	// The dispatcher may be deploying too, and their key leaves this mob as they spawn
	var/client/dispatcher = user.client
	if(!length(GLOB.response_team_spawns))
		to_chat(user, span_warning("This map has no ERT response spawn landmark, so the team has been called off."))
		call_off(user, "tried to dispatch the [team_type.name] response team, but the map has no response spawn so it was called off.")
		return
	var/list/deployed = list()
	for(var/member_ckey in members)
		var/datum/response_member/member = members[member_ckey]
		var/mob/M = get_mob_by_ckey(member_ckey)
		if(member.ready && member.role && is_available(M) && !is_banned(M))
			deployed += member
	if(!length(deployed))
		to_chat(user, span_warning("Nobody is ready to deploy."))
		return
	stage = RESPONSE_STAGE_ACTIVE
	var/list/roster = list()
	for(var/member_ckey in members.Copy())
		var/datum/response_member/member = members[member_ckey]
		var/mob/M = get_mob_by_ckey(member_ckey)
		if(!(member in deployed))
			members -= member_ckey
			to_chat(M, span_warning("The emergency response has been dispatched without you."))
			continue
		spawn_member(member, M, pick(GLOB.response_team_spawns))
		var/datum/advclass/role = member.role
		roster += "[member.ckey] as [member.name], [initial(role.name)]"
	log_response(dispatcher, "dispatched the [team_type.name] response team: [english_list(roster)].")
	return TRUE

/// Puts the responder in a fresh body and equips them. Sleeps while they answer any choices their role's outfit asks for.
/datum/response_team/proc/spawn_member(datum/response_member/member, mob/M, turf/T)
	set waitfor = FALSE
	SStgui.close_user_uis(M, src)
	if(isnewplayer(M))
		var/mob/dead/new_player/N = M
		N.close_spawn_windows()
	var/mob/living/carbon/human/species/human/northern/H = new(T)
	member.body = WEAKREF(H)
	// Same pool new arrivals fall back to when their chosen name is taken.
	// Named before the key moves in, so dispatch() can log the name without waiting on login.
	H.fully_replace_character_name(null, H.dna.species.random_name(H.gender, TRUE))
	GLOB.chosen_names += H.real_name
	member.name = H.real_name
	H.key = M.key
	// A blank character with no vice. This is the free "No Flaw", not the one from character setup that costs triumphs.
	H.charflaw = new /datum/charflaw/eznoflaw()
	H.vices += H.charflaw
	H.charflaw.on_mob_creation(H)
	var/datum/response_team_type/spawning_type = team_type
	spawning_type.apply_patron(H)
	var/datum/advclass/response_team/role = SSrole_class_handler.classes_by_type[member.role]
	role.equip_responder(H)
	// Removed, or the deployment ended, while they were choosing
	if(QDELETED(H) || member.removed)
		return
	spawning_type.remove_withheld(H)
	if(spawning_type.give_jupon)
		issue_jupon(H, role, spawning_type)
	var/obj/item/scomstone/response_team/stone = new(H)
	stone.name = "[spawning_type.name] stone"
	// Bound before equipping, or the stone crumbles on its own wearer
	stone.owner = WEAKREF(H)
	issue_item(H, stone, SLOT_RING)
	member.stone = WEAKREF(stone)
	// Remembered so ending the deployment deletes the kit but not anything picked up along the way
	for(var/obj/item/I as anything in H.get_all_carried_items())
		member.issued += WEAKREF(I)
	member.kit_recorded = TRUE
	to_chat(H, span_boldannounce("I am [H.real_name], a [role.name] of the [spawning_type.name]."))
	if(mission)
		to_chat(H, span_notice("<b>Mission:</b> [html_encode(mission)]"))
	to_chat(H, span_notice("Right click my [stone.name] to speak with the rest of the team. It will crumble in anyone else's hands."))

/// Puts a named jupon in the role's colours in the cloak slot. Any cloak there is replaced, unless it's a bag, which is moved elsewhere.
/datum/response_team/proc/issue_jupon(mob/living/carbon/human/H, datum/advclass/response_team/role, datum/response_team_type/spawning_type)
	var/obj/item/old_cloak = H.cloak
	if(old_cloak?.GetComponent(/datum/component/storage))
		H.dropItemToGround(old_cloak, force = TRUE)
	else
		qdel(old_cloak)
		old_cloak = null
	var/obj/item/clothing/cloak/stabard/surcoat/response_team/jupon = new(H)
	jupon.name = "[H.first_name()], [role.tabard_identifier || role.name]"
	jupon.color = role.tabard_color || spawning_type.team_color
	if(role.tabard_desc)
		jupon.desc = role.tabard_desc
	jupon.update_icon()
	issue_item(H, jupon, SLOT_CLOAK)
	if(old_cloak && !H.equip_to_appropriate_slot(old_cloak))
		H.put_in_hands(old_cloak)

/// Puts an item on the responder in the given slot if it's free, otherwise in a hand, otherwise at their feet
/datum/response_team/proc/issue_item(mob/living/carbon/human/H, obj/item/I, slot)
	if(H.equip_to_slot_if_possible(I, slot, disable_warning = TRUE))
		return
	if(!H.put_in_hands(I))
		I.forceMove(H.drop_location())

/// Sends a team stone message in the team colour to every deployed member, or only the one given
/datum/response_team/proc/relay(message, atom/source, tcolor, datum/response_member/only)
	message = "<big><span style='color: [team_type.team_color]'>[message]</span></big>"
	for(var/member_ckey in members)
		var/datum/response_member/member = members[member_ckey]
		if(!only || member == only)
			var/obj/item/scomstone/response_team/stone = member.stone?.resolve()
			stone?.repeat_message(message, source, tcolor)

/datum/response_team/proc/message_member(mob/user, datum/response_member/member)
	var/obj/item/scomstone/response_team/stone = member?.stone?.resolve()
	if(!stone || member.removed)
		to_chat(user, span_warning("That responder no longer has their stone."))
		return
	var/message = tgui_input_text(user, "Message to the stone of [member.key]", "Direct Message", max_length = MAX_MESSAGE_LEN, encode = FALSE)
	if(!message || QDELETED(stone))
		return
	relay("<b>[html_encode(message)]</b>", only = member)
	log_chat(user.key, user.ckey, member.name, message, from_admin = TRUE)
	log_response(user, "messaged response team member [member.key]: [html_encode(message)]")

/datum/response_team/proc/broadcast(mob/user)
	var/message = tgui_input_text(user, "Message for the whole team", "Broadcast to Team", max_length = MAX_MESSAGE_LEN, encode = FALSE)
	if(!message || stage != RESPONSE_STAGE_ACTIVE)
		return
	relay("<b>[html_encode(message)]</b>")
	log_chat(user.key, user.ckey, "Team", message, from_admin = TRUE)
	log_response(user, "broadcast to the [team_type.name] response team: [html_encode(message)]")

/// Adds a stone message to the panel's log. Sender is the character's name, or the admin's key for admin messages.
/datum/response_team/proc/log_chat(sender, sender_ckey, recipient, message, from_admin = FALSE)
	chat_log += list(list(
		"time" = gameTimestamp(),
		"sender" = sender,
		"ckey" = sender_ckey,
		"to" = recipient,
		"admin" = from_admin,
		"message" = message,
	))
	if(length(chat_log) > RESPONSE_LOG_MAX)
		chat_log.Cut(1, 2)
	update_static_data_for_all_viewers()

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
	if(stage != RESPONSE_STAGE_ACTIVE)
		return
	for(var/member_ckey in members)
		var/datum/response_member/member = members[member_ckey]
		if(!member.removed)
			member.despawn()
	log_response(user, "ended the deployment of the [team_type.name] response team.")
	reset()

/// The deployed responder this mob is, if any
/mob/living/carbon/human/proc/get_response_member()
	var/datum/response_team/team = GLOB.response_team
	if(team.stage != RESPONSE_STAGE_ACTIVE)
		return
	for(var/member_ckey in team.members)
		var/datum/response_member/member = team.members[member_ckey]
		if(member.body?.resolve() == src)
			return member

/// Examine lines for a deployed responder: the team's "A knight of Kingsfield.", then the faithful's line if the examiner shares the team's faith
/mob/living/carbon/human/proc/get_response_team_examine(mob/user)
	var/datum/response_member/member = get_response_member()
	if(!member)
		return
	var/datum/response_team_type/team_type = GLOB.response_team.team_type
	. = list(team_type.examine_line(member.role))
	if(team_type.is_faithful(user))
		. += team_type.faithful_line()

/// Whether the examiner shares this responder's team's faith, and so sees its line in place of the Inquisition's
/mob/living/carbon/human/proc/is_known_responder(mob/user)
	return get_response_member() && GLOB.response_team.team_type.is_faithful(user)

/// Every item on this mob, including ones inside other items
/mob/living/carbon/human/proc/get_all_carried_items()
	. = list()
	// Each of these is the top of its own tree, so nothing is counted twice
	for(var/obj/item/gear in get_equipped_items(TRUE) + held_items)
		. += gear.GetAllContents(/obj/item)

#undef RESPONSE_STAGE_SETUP
#undef RESPONSE_STAGE_LOCKED
#undef RESPONSE_STAGE_GATHERING
#undef RESPONSE_STAGE_ACTIVE
#undef RESPONSE_ROLE_MAX
#undef RESPONSE_OFFER_TIMEOUT
#undef RESPONSE_LOG_MAX
