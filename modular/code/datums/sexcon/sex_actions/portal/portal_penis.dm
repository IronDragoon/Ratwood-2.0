// Portal actions on the wearer's cock.

/**
 * STROKING
 */
/datum/sex_action/portal/stroke
	name = "Portal: stroke cock"
	category = SEX_CATEGORY_HANDS
	target_sex_part = SEX_PART_COCK
	portal_focus = SEX_PART_COCK
	needs_free_hand = TRUE
	twitch_text = "twitches, hips bucking at some unseen touch."

/datum/sex_action/portal/stroke/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.sexcon.show_progress = 0
	portal_tell(user, target, \
		span_warning("I reach through the portal and wrap my hand around their cock."), \
		span_love("A distant hand wraps around my cock through the portal!"), \
		span_warning("I reach through the portal and wrap my hand around my own cock."))
	portal_holder_vague(user, target)

/datum/sex_action/portal/stroke/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/do_subtle = user.sexcon.do_subtle_action
	user.sexcon.show_progress = !do_subtle
	portal_action_message(user, target, \
		"I %FORCE% stroke their cock through the portal.", \
		"Someone %FORCE% strokes my cock through the portal.", \
		"I %FORCE% stroke my own cock through the portal.")
	if(!do_subtle)
		user.sexcon.generic_sex_noise()
	user.sexcon.perform_sex_action(target, 2, 0, TRUE)
	// It spills out of the light, over the holder.
	target.sexcon.handle_passive_ejaculation(user)
	portal_twitch(user, target)

/datum/sex_action/portal/stroke/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	portal_tell(user, target, \
		span_notice("I let go and draw my hand back out of the portal."), \
		span_notice("The hand on my cock lets go."), \
		span_notice("I let go and draw my hand back out of the portal."))

/datum/sex_action/portal/stroke/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(..())
		return TRUE
	return target.sexcon.finished_check()

/**
 * SUCKING
 */
/datum/sex_action/portal/suck
	name = "Portal: suck cock"
	category = SEX_CATEGORY_PENETRATE
	user_sex_part = SEX_PART_JAWS
	target_sex_part = SEX_PART_COCK
	portal_focus = SEX_PART_COCK
	knot_on_finish = TRUE
	holder_vague_text = "presses a pulsing portal light to their lips."
	twitch_text = "shivers, hips twitching as if something unseen sucks at them."

/datum/sex_action/portal/suck/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.sexcon.show_progress = FALSE
	portal_tell(user, target, \
		span_warning("I press my mouth to the portal and take their cock in."), \
		span_love("Warm lips close around my cock through the portal!"), \
		span_warning("I press my mouth to the portal and take my own cock in."))
	portal_holder_vague(user, target)

/datum/sex_action/portal/suck/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/do_subtle = user.sexcon.do_subtle_action
	user.sexcon.show_progress = !do_subtle
	if(!user.sexcon.do_knot_action_as_bottom)
		portal_action_message(user, target, \
			"I %FORCE% suck their cock through the portal.", \
			"Someone %FORCE% sucks my cock through the portal.", \
			"I %FORCE% suck my own cock through the portal.")
	else
		portal_action_message(user, target, \
			"I %FORCE% suck their cock through the portal, taking the knot into my mouth.", \
			"Someone %FORCE% sucks my cock through the portal, taking the knot into their mouth.", \
			"I %FORCE% suck my own cock through the portal, taking the knot into my mouth.")
	if(!do_subtle)
		user.sexcon.oralcourse_noise(user)

	user.sexcon.perform_sex_action(target, 2, 0, TRUE)
	if(!target.sexcon.considered_limp())
		user.sexcon.perform_deepthroat_oxyloss(user, 1.3)
	if(target.sexcon.check_active_ejaculation())
		portal_tell(user, target, \
			span_love("They cum into my mouth through the portal!"), \
			span_love("I cum into someone's mouth through the portal!"), \
			span_love("I cum into my own mouth through the portal!"))
		for(var/i = 1; i <= target.sexcon.get_load_bursts(); i++)
			target.sexcon.cum_into(oral = TRUE, splashed_user = user, knot_action = src, knot_swap_roles = TRUE, knot_btm = user, consume_charge = i == 1 ? TRUE : FALSE)
			sleep(10)
	portal_twitch(user, target)

/datum/sex_action/portal/suck/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	portal_tell(user, target, \
		span_notice("I pull my mouth back from the portal."), \
		span_notice("The lips on my cock pull away."), \
		span_notice("I pull my mouth back from the portal."))

/datum/sex_action/portal/suck/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(..())
		return TRUE
	return target.sexcon.finished_check()

/**
 * RIDING: THE HOLDER'S HOLE ON THE WEARER'S COCK
 */
/datum/sex_action/portal/ride
	name = "Portal: ride cock (cunt)"
	stamina_cost = 1.0
	allow_self = FALSE // same act as fucking your own hole through the portal
	category = SEX_CATEGORY_PENETRATE
	user_sex_part = SEX_PART_CUNT
	target_sex_part = SEX_PART_COCK
	target_needs_functional = TRUE
	portal_focus = SEX_PART_COCK
	knot_on_finish = TRUE
	holder_vague_text = "sinks down onto a pulsing portal light."
	twitch_text = "jolts, hips jerking up into something unseen."
	var/hole_word = "cunt"

/datum/sex_action/portal/ride/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	portal_tell(user, target, \
		span_warning("I sink my [hole_word] down onto their cock through the portal."), \
		span_love("Something slick sinks down onto my cock through the portal!"))
	portal_holder_vague(user, target)
	playsound_erp(user, list('sound/misc/mat/insert (1).ogg','sound/misc/mat/insert (2).ogg'), 20, TRUE, extrarange = 0, travel = SOUND_TRAVEL_LEAKING)

/datum/sex_action/portal/ride/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!user.sexcon.do_knot_action_as_bottom)
		portal_action_message(user, target, \
			"I %FORCE% ride their cock with my [hole_word] through the portal.", \
			"Someone %FORCE% rides my cock through the portal.")
	else
		portal_action_message(user, target, \
			"I %FORCE% knot-ride their cock with my [hole_word] through the portal.", \
			"Someone %FORCE% knot-rides my cock through the portal.")
	user.sexcon.intercourse_noise(user)

	var/obj/item/organ/penis/their_cock = target.getorganslot(ORGAN_SLOT_PENIS)
	target.sexcon.perform_sex_action(target, 2, 0, TRUE, involved_penis = their_cock)
	if(target.sexcon.check_active_ejaculation())
		portal_tell(user, target, \
			span_love("They cum deep into my [hole_word] through the portal!"), \
			span_love("I cum deep into someone through the portal!"))
		for(var/i = 1; i <= target.sexcon.get_load_bursts(); i++)
			sleep(10)
			target.sexcon.cum_into(splashed_user = user, knot_action = src, knot_swap_roles = TRUE, knot_btm = user, orifice = user_sex_part, consume_charge = i == 1 ? TRUE : FALSE)
			try_portal_impregnate(user, target)
		target.virginity = FALSE
		user.virginity = FALSE

	if(target.sexcon.considered_limp())
		target.sexcon.perform_sex_action(user, 1.2, 3, FALSE, involved_penis = their_cock)
	else
		target.sexcon.perform_sex_action(user, 2.4, 7, FALSE, involved_penis = their_cock)
	user.sexcon.handle_passive_ejaculation()
	portal_twitch(user, target)

/datum/sex_action/portal/ride/proc/try_portal_impregnate(mob/living/carbon/human/user, mob/living/carbon/human/target)
	target.try_impregnate(user)

/datum/sex_action/portal/ride/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	portal_tell(user, target, \
		span_notice("I lift myself off their cock and away from the portal."), \
		span_notice("The slick warmth slides off my cock."))

/datum/sex_action/portal/ride/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(..())
		return TRUE
	return user.sexcon.finished_check()

/datum/sex_action/portal/ride/anal
	name = "Portal: ride cock (ass)"
	user_sex_part = SEX_PART_ANUS
	hole_word = "ass"

/datum/sex_action/portal/ride/anal/try_portal_impregnate(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(HAS_TRAIT(user, TRAIT_BAOTHA_FERTILITY_BOON) && !user.getorganslot(ORGAN_SLOT_VAGINA))
		target.try_impregnate(user)
