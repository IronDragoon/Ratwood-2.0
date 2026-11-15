// Portal actions: the holder of a portal light reaches the wearer of the linked portal panties at any distance.
// The wearer never learns who is on the other side, and bystanders only see the light and the twitching.
// Ported from Rivermist Hollow (sheetofseaweed/Rivermist-Hollow-Vanderlin), rewritten for this sexcon.

#define PORTAL_TWITCH_COOLDOWN (20 SECONDS)
#define PORTAL_TWITCH_RANGE 3

/mob/living/carbon/human
	/// world.time after which the next portal twitch line may show.
	var/next_portal_twitch = 0

/datum/sex_action/portal
	abstract_type = /datum/sex_action/portal
	check_same_tile = FALSE
	aggro_grab_instead_same_tile = FALSE
	remote_action = TRUE
	/// The panties' focus this action needs.
	var/portal_focus = SEX_PART_NULL
	/// Whether the holder can do this to themselves while wearing the panties.
	var/allow_self = TRUE
	/// Hand actions need the hand not holding the light to be free.
	var/needs_free_hand = FALSE
	/// What people near the holder see in place of the act.
	var/holder_vague_text = "fiddles with a pulsing portal light."
	/// What people right beside the wearer see now and then.
	var/twitch_text = "twitches, hips jerking at some unseen touch."

/// The light in the user's active hand, if it opens onto the target.
/datum/sex_action/portal/proc/get_portal_light(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/portallight/light = user?.get_active_held_item()
	if(!istype(light))
		return null
	if(!target || light.get_wearer() != target)
		return null
	return light

/// Whether the wearer's focused part can take this action: organ present, not behind chastity, working if needed.
/datum/sex_action/portal/proc/portal_part_usable(mob/living/carbon/human/target)
	switch(portal_focus)
		if(SEX_PART_CUNT)
			if(!target.getorganslot(ORGAN_SLOT_VAGINA) || target.sexcon.has_chastity_vagina())
				return FALSE
			if(target_needs_functional && !target.sexcon.can_use_vagina())
				return FALSE
		if(SEX_PART_COCK)
			if(!target.getorganslot(ORGAN_SLOT_PENIS) || target.sexcon.has_chastity_penis())
				return FALSE
			if(target_needs_functional && !target.sexcon.can_use_penis())
				return FALSE
		if(SEX_PART_ANUS)
			if(target.sexcon.has_chastity_anal())
				return FALSE
		else
			return FALSE
	return TRUE

/datum/sex_action/portal/proc/portal_ready(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/portallight/light = get_portal_light(user, target)
	if(!light)
		return FALSE
	if(light.linked_underwear.focus != portal_focus)
		return FALSE
	return portal_focus_available(target, portal_focus)

/datum/sex_action/portal/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target && !allow_self)
		return FALSE
	if(!portal_ready(user, target))
		return FALSE
	// The holder's own parts must exist; chastity and clothing only grey the action out.
	if((user_sex_part & SEX_PART_COCK) && !user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	if((user_sex_part & SEX_PART_CUNT) && !user.getorganslot(ORGAN_SLOT_VAGINA))
		return FALSE
	return TRUE

/datum/sex_action/portal/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target && !allow_self)
		return FALSE
	if(!portal_ready(user, target))
		return FALSE
	if(!portal_part_usable(target))
		return FALSE
	if(needs_free_hand && user.get_inactive_held_item())
		return FALSE
	// The holder's side is ordinary: their own part has to be reachable and free.
	return user_parts_are_accessible(user, target)

/datum/sex_action/portal/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return !portal_ready(user, target)

/// Sends one line to the holder, one to the wearer, or the self line when they are the same person.
/datum/sex_action/portal/proc/portal_tell(mob/living/carbon/human/user, mob/living/carbon/human/target, holder_msg, wearer_msg, self_msg)
	if(user == target)
		if(self_msg)
			to_chat(user, self_msg)
		return
	if(holder_msg)
		to_chat(user, holder_msg)
	if(wearer_msg)
		to_chat(target, wearer_msg)

/// The per-cycle action lines, which follow the sexcon's repeat suppression.
/datum/sex_action/portal/proc/portal_action_message(mob/living/carbon/human/user, mob/living/carbon/human/target, holder_msg, wearer_msg, self_msg)
	if(user.sexcon.suppress_action_messages)
		return
	var/force_adjective = user.sexcon.get_generic_force_adjective(is_stealth = user.sexcon.do_subtle_action)
	portal_tell(user, target, \
		user.sexcon.spanify_force(replacetext(holder_msg, "%FORCE%", force_adjective)), \
		user.sexcon.spanify_force(replacetext(wearer_msg, "%FORCE%", force_adjective)), \
		user.sexcon.spanify_force(replacetext(self_msg, "%FORCE%", force_adjective)))
	portal_holder_vague(user, target)

/// The vague line people around the holder see.
/datum/sex_action/portal/proc/portal_holder_vague(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!holder_vague_text)
		return
	user.visible_message(span_notice("[user] [holder_vague_text]"), vision_distance = (user.sexcon.do_subtle_action ? 1 : DEFAULT_MESSAGE_RANGE), ignored_mobs = list(user, target))

/// Now and then, people right beside the wearer notice them twitch.
/datum/sex_action/portal/proc/portal_twitch(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target || !twitch_text)
		return
	if(user.sexcon.do_subtle_action)
		return
	if(world.time < target.next_portal_twitch)
		return
	target.next_portal_twitch = world.time + PORTAL_TWITCH_COOLDOWN
	target.visible_message(span_notice("[target] [twitch_text]"), vision_distance = PORTAL_TWITCH_RANGE, ignored_mobs = list(user, target))

#undef PORTAL_TWITCH_COOLDOWN
#undef PORTAL_TWITCH_RANGE
