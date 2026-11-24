// Portal actions on the wearer's cunt or ass.

/**
 * FINGERING
 */
/datum/sex_action/portal/finger
	name = "Portal: finger cunt"
	category = SEX_CATEGORY_HANDS
	target_sex_part = SEX_PART_CUNT
	portal_focus = SEX_PART_CUNT
	needs_free_hand = TRUE
	var/hole_word = "cunt"
	var/target_pain = 4

/datum/sex_action/portal/finger/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	portal_tell(user, target, \
		span_warning("I reach through the portal and start fingering their [hole_word]."), \
		span_love("A distant touch reaches me through the portal!"), \
		span_warning("I reach through the portal and start fingering my own [hole_word]."))
	portal_holder_vague(user, target)

/datum/sex_action/portal/finger/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	portal_action_message(user, target, \
		"I %FORCE% finger their [hole_word] through the portal.", \
		"Someone %FORCE% fingers my [hole_word] through the portal.", \
		"I %FORCE% finger my own [hole_word] through the portal.")
	if(!user.sexcon.do_subtle_action)
		user.sexcon.generic_sex_noise()
	user.sexcon.perform_sex_action(target, 2, target_pain, TRUE)
	portal_wearer_passive(user, target)
	portal_twitch(user, target)

/datum/sex_action/portal/finger/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	portal_tell(user, target, \
		span_notice("I draw my hand back out of the portal."), \
		span_notice("The distant touch on me fades away."), \
		span_notice("I draw my hand back out of the portal."))

/datum/sex_action/portal/finger/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(..())
		return TRUE
	return target.sexcon.finished_check()

/datum/sex_action/portal/finger/anal
	name = "Portal: finger ass"
	target_sex_part = SEX_PART_ANUS
	portal_focus = SEX_PART_ANUS
	hole_word = "ass"
	target_pain = 6

/**
 * ORAL: LICK AND RIM
 */
/datum/sex_action/portal/lick
	name = "Portal: lick cunt"
	user_sex_part = SEX_PART_JAWS
	target_sex_part = SEX_PART_CUNT
	portal_focus = SEX_PART_CUNT
	holder_vague_text = "presses a pulsing portal light to their lips."
	twitch_text = "shivers, thighs twitching as if something unseen licks at them."

/datum/sex_action/portal/lick/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.sexcon.show_progress = FALSE
	portal_tell(user, target, \
		span_warning("I press my mouth to the portal and find their cunt."), \
		span_love("Warm sensations bloom between my legs!"), \
		span_warning("I press my mouth to the portal and find my own cunt."))
	portal_holder_vague(user, target)

/datum/sex_action/portal/lick/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/do_subtle = user.sexcon.do_subtle_action
	user.sexcon.show_progress = !do_subtle
	portal_action_message(user, target, \
		"I %FORCE% lick their cunt through the portal.", \
		"Someone %FORCE% licks my cunt through the portal.", \
		"I %FORCE% lick my own cunt through the portal.")
	if(!do_subtle)
		user.sexcon.make_sucking_noise()
	user.sexcon.perform_sex_action(target, 2, 3, TRUE)
	user.sexcon.perform_sex_action(user, 0.5, 0, FALSE)
	if(target.sexcon.check_active_ejaculation())
		portal_tell(user, target, \
			span_love("They gush into my mouth through the portal!"), \
			span_love("I gush into someone's mouth through the portal!"), \
			span_love("I gush into my own mouth through the portal!"))
		target.sexcon.cum_into(oral = TRUE, splashed_user = user, portal_holder = user)
	portal_twitch(user, target)

/datum/sex_action/portal/lick/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	portal_tell(user, target, \
		span_notice("I pull my mouth back from the portal."), \
		span_notice("The sensations on me from the portal fade away."), \
		span_notice("I pull my mouth back from the portal."))

/datum/sex_action/portal/lick/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(..())
		return TRUE
	return target.sexcon.finished_check()

/datum/sex_action/portal/rim
	name = "Portal: rim ass"
	user_sex_part = SEX_PART_JAWS
	target_sex_part = SEX_PART_ANUS
	portal_focus = SEX_PART_ANUS
	holder_vague_text = "presses a pulsing portal light to their lips."
	twitch_text = "shivers, as if something unseen licks at their backside."

/datum/sex_action/portal/rim/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.sexcon.show_progress = FALSE
	portal_tell(user, target, \
		span_warning("I press my mouth to the portal and find their ass."), \
		span_love("A warm tongue teases my backside through the portal!"), \
		span_warning("I press my mouth to the portal and find my own ass."))
	portal_holder_vague(user, target)

/datum/sex_action/portal/rim/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/do_subtle = user.sexcon.do_subtle_action
	user.sexcon.show_progress = !do_subtle
	portal_action_message(user, target, \
		"I %FORCE% rim their ass through the portal.", \
		"Someone %FORCE% rims my ass through the portal.", \
		"I %FORCE% rim my own ass through the portal.")
	if(!do_subtle)
		user.sexcon.make_sucking_noise()
	user.sexcon.perform_sex_action(target, 2, 0, TRUE)
	portal_wearer_passive(user, target)
	portal_twitch(user, target)

/datum/sex_action/portal/rim/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	portal_tell(user, target, \
		span_notice("I pull my mouth back from the portal."), \
		span_notice("The tongue at my backside fades away."), \
		span_notice("I pull my mouth back from the portal."))

/datum/sex_action/portal/rim/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(..())
		return TRUE
	return target.sexcon.finished_check()

/**
 * THE HOLDER'S COCK IN THE WEARER'S HOLE
 */
/datum/sex_action/portal/fuck
	name = "Portal: fuck cunt"
	stamina_cost = 1.0
	category = SEX_CATEGORY_PENETRATE
	user_sex_part = SEX_PART_COCK
	user_needs_functional = TRUE
	target_sex_part = SEX_PART_CUNT
	portal_focus = SEX_PART_CUNT
	knot_on_finish = TRUE
	holder_vague_text = "works a pulsing portal light over their groin."
	twitch_text = "jolts, hips jerking to some unseen rhythm."
	var/hole_word = "cunt"

/datum/sex_action/portal/fuck/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	portal_tell(user, target, \
		span_warning("I slide my cock into the portal and into their [hole_word]."), \
		span_love("Something pushes into my [hole_word] through the portal!"), \
		span_warning("I slide my cock into the portal and into my own [hole_word]."))
	portal_holder_vague(user, target)
	playsound_erp(user, list('sound/misc/mat/insert (1).ogg','sound/misc/mat/insert (2).ogg'), 20, TRUE, extrarange = 0, travel = SOUND_TRAVEL_LEAKING)

/datum/sex_action/portal/fuck/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!user.sexcon.do_knot_action)
		portal_action_message(user, target, \
			"I %FORCE% fuck their [hole_word] through the portal.", \
			"Someone %FORCE% fucks my [hole_word] through the portal.", \
			"I %FORCE% fuck my own [hole_word] through the portal.")
	else
		portal_action_message(user, target, \
			"I %FORCE% knot-fuck their [hole_word] through the portal.", \
			"Someone %FORCE% knot-fucks my [hole_word] through the portal.", \
			"I %FORCE% knot-fuck my own [hole_word] through the portal.")
	user.sexcon.intercourse_noise(user)

	user.sexcon.perform_sex_action(user, 2, 0, TRUE)
	if(user.sexcon.check_active_ejaculation())
		portal_tell(user, target, \
			span_love("I cum deep into their [hole_word] through the portal!"), \
			span_love("Someone cums deep into my [hole_word] through the portal!"), \
			span_love("I cum deep into my own [hole_word] through the portal!"))
		for(var/i = 1; i <= user.sexcon.get_load_bursts(); i++)
			user.sexcon.cum_into(splashed_user = target, knot_action = src, knot_btm = target, orifice = target_sex_part, consume_charge = i == 1 ? TRUE : FALSE, portal_holder = user)
			try_portal_impregnate(user, target)
			sleep(10)
		user.virginity = FALSE
		target.virginity = FALSE

	if(user.sexcon.considered_limp())
		user.sexcon.perform_sex_action(target, 1.2, 3, FALSE)
	else
		user.sexcon.perform_sex_action(target, 2, !user.sexcon.do_knot_action ? 3 : 7, FALSE)
	portal_wearer_passive(user, target)
	portal_twitch(user, target)

/datum/sex_action/portal/fuck/proc/try_portal_impregnate(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.try_impregnate(target)

/datum/sex_action/portal/fuck/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	portal_tell(user, target, \
		span_notice("I pull my cock back out of the portal."), \
		span_notice("The cock pulls out of me through the portal."), \
		span_notice("I pull my cock back out of the portal."))

/datum/sex_action/portal/fuck/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(..())
		return TRUE
	return user.sexcon.finished_check()

/datum/sex_action/portal/fuck/anal
	name = "Portal: fuck ass"
	target_sex_part = SEX_PART_ANUS
	portal_focus = SEX_PART_ANUS
	hole_word = "ass"

/datum/sex_action/portal/fuck/anal/try_portal_impregnate(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(HAS_TRAIT(target, TRAIT_BAOTHA_FERTILITY_BOON) && !target.getorganslot(ORGAN_SLOT_VAGINA))
		user.try_impregnate(target)

/**
 * GRINDING: THE HOLDER'S HOLE AGAINST THE WEARER'S
 */
/datum/sex_action/portal/grind
	name = "Portal: grind cunts"
	stamina_cost = 0.4
	allow_self = FALSE
	user_sex_part = SEX_PART_CUNT
	target_sex_part = SEX_PART_CUNT
	portal_focus = SEX_PART_CUNT
	holder_vague_text = "grinds against a pulsing portal light."
	twitch_text = "squirms, hips rocking against some slick, unseen weight."
	var/hole_word = "cunt"
	var/grind_pain = 2

/datum/sex_action/portal/grind/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	portal_tell(user, target, \
		span_warning("I press my [hole_word] to the portal, against theirs."), \
		span_love("A slick warmth grinds against my [hole_word] through the portal!"))
	portal_holder_vague(user, target)

/datum/sex_action/portal/grind/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	portal_action_message(user, target, \
		"I %FORCE% grind my [hole_word] against theirs through the portal.", \
		"Someone %FORCE% grinds against my [hole_word] through the portal.")
	user.sexcon.intercourse_noise(user)
	user.sexcon.perform_sex_action(user, 2, grind_pain, TRUE)
	user.sexcon.handle_passive_ejaculation()
	user.sexcon.perform_sex_action(target, 1.5, grind_pain, TRUE)
	portal_wearer_passive(user, target)
	portal_twitch(user, target)

/datum/sex_action/portal/grind/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	portal_tell(user, target, \
		span_notice("I pull back from the portal, still tingling."), \
		span_notice("The slick grinding through the portal fades away."))

/datum/sex_action/portal/grind/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(..())
		return TRUE
	return user.sexcon.finished_check()

/datum/sex_action/portal/grind/anal
	name = "Portal: grind asses"
	user_sex_part = SEX_PART_ANUS
	target_sex_part = SEX_PART_ANUS
	portal_focus = SEX_PART_ANUS
	hole_word = "ass"
	grind_pain = 3
