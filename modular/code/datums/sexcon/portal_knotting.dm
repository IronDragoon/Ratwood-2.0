// Knots tied through a portal light. Instead of tethering two bodies, the knot locks the light in the
// holder's hand and the panties on the wearer until it ends. Messages never name the other side.

/datum/sex_controller
	/// TRUE while this controller's knot is tied through a portal light.
	var/knot_via_portal = FALSE
	/// The portal light the knot is tied through, locked until the knot ends.
	var/obj/item/portal_light/knot_portal_light

/// Unlocks the light and panties and clears the portal flags on both ends of the knot.
/datum/sex_controller/proc/portal_knot_release()
	var/obj/item/portal_light/locked_light
	var/list/controllers = list(src)
	var/mob/living/carbon/human/top = knotted_owner
	var/mob/living/carbon/human/btm = knotted_recipient
	if(istype(top) && top.sexcon)
		controllers |= top.sexcon
	if(istype(btm) && btm.sexcon)
		controllers |= btm.sexcon
	for(var/datum/sex_controller/controller as anything in controllers)
		if(controller.knot_portal_light)
			locked_light = controller.knot_portal_light
		controller.knot_portal_light = null
		controller.knot_via_portal = FALSE
	// Unlock even while the light is being deleted, so the panties never stay stuck on.
	locked_light?.set_knot_lock(FALSE)

/// The knot catches. Called on the top's controller.
/datum/sex_controller/proc/portal_knot_tie_message(mob/living/carbon/human/btm, btm_forced)
	var/knot_word = get_knot_synonym()
	if(btm == user)
		to_chat(user, span_notice("My [knot_word] swells and ties inside me through the portal!"))
		return
	if(btm_forced)
		to_chat(btm, span_notice("I force myself down onto the [knot_word] through the portal!"))
		to_chat(user, span_notice("Something forces itself down onto my [knot_word] through the portal!"))
	else
		to_chat(user, span_notice("My [knot_word] swells and ties through the portal."))
		to_chat(btm, span_notice("Something swells and ties inside me through the portal!"))

/// The top climaxes while knotted. Called on the top's controller. Private at both ends, like every portal line.
/datum/sex_controller/proc/portal_knot_climax_message(is_oral_knot)
	if(knotted_recipient == user)
		to_chat(user, span_love(is_oral_knot ? "I climax down my own throat through the portal!" : "I climax deep inside myself through the portal!"))
		return
	to_chat(user, span_love("I climax deep through the portal!"))
	to_chat(knotted_recipient, span_love(is_oral_knot ? "Someone climaxes down my throat through the portal!" : "Someone climaxes deep inside me through the portal!"))

/// A climax that spills out of a portal at portal_holder's end. Called on the climaxer's controller. Private at both ends.
/datum/sex_controller/proc/portal_climax_message(mob/living/carbon/human/portal_holder)
	if(portal_holder == user)
		to_chat(user, span_love("I climax, and it spills back out of the portal over me!"))
		return
	to_chat(user, span_love("I climax through the portal!"))
	to_chat(portal_holder, span_love("Someone climaxes through the portal, spilling over me!"))

/// The knot comes out, gently or with a yank. Sent privately so neither side is named.
/proc/portal_knot_remove_message(mob/living/carbon/human/top, mob/living/carbon/human/btm, forceful, btm_removed)
	var/knot_word = top.sexcon.get_knot_synonym()
	if(top == btm)
		to_chat(top, span_notice(forceful ? "I yank my [knot_word] free through the portal!" : "My [knot_word] slips free through the portal."))
		return
	if(btm_removed)
		to_chat(btm, span_notice(forceful ? "I yank myself free of the [knot_word] through the portal!" : "I slip free of the [knot_word] through the portal."))
		to_chat(top, span_notice(forceful ? "Something yanks itself free of my [knot_word] through the portal!" : "Something slips free of my [knot_word] through the portal."))
		return
	to_chat(top, span_notice(forceful ? "I yank my [knot_word] free through the portal!" : "My [knot_word] slips free through the portal."))
	to_chat(btm, span_notice(forceful ? "The [knot_word] is yanked out of me through the portal!" : "The [knot_word] slips out of me through the portal."))
