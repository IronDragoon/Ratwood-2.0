// Portal panties and the portal light: a linked pair for ERP at any distance.
// Ported from Rivermist Hollow (sheetofseaweed/Rivermist-Hollow-Vanderlin).
// Art (portal.dmi, portal_panties.dmi) by Rivermist Hollow, CC-BY-SA 3.0.

#define PORTAL_KNOT_TRAIT "portal_knot"

/// The wearer's focus parts, in the order the light cycles through them.
#define PORTAL_FOCUS_ORDER list(SEX_PART_CUNT, SEX_PART_COCK, SEX_PART_ANUS)

/// Does this person have the organ behind a portal focus?
/proc/portal_focus_available(mob/living/carbon/human/wearer, focus)
	if(!wearer)
		return FALSE
	switch(focus)
		if(SEX_PART_CUNT)
			return !!wearer.getorganslot(ORGAN_SLOT_VAGINA)
		if(SEX_PART_COCK)
			return !!wearer.getorganslot(ORGAN_SLOT_PENIS)
		if(SEX_PART_ANUS)
			return !!wearer.get_bodypart(BODY_ZONE_CHEST)
	return FALSE

/proc/portal_focus_name(focus)
	switch(focus)
		if(SEX_PART_CUNT)
			return "cunt"
		if(SEX_PART_COCK)
			return "cock"
		if(SEX_PART_ANUS)
			return "ass"
	return "nothing"

/// Finds the portal light linking these two people (or one person to themselves), held by either of them.
/proc/find_portal_light_between(mob/living/carbon/human/first, mob/living/carbon/human/second)
	if(!ishuman(first) || !ishuman(second))
		return null
	for(var/mob/living/carbon/human/holder as anything in list(first, second))
		for(var/obj/item/portallight/light in holder.held_items)
			var/mob/living/carbon/human/wearer = light.get_wearer()
			if(!wearer)
				continue
			if(first == second)
				if(wearer == first)
					return light
				continue
			if(wearer != holder && (wearer == first || wearer == second))
				return light
	return null

/**
 * PORTAL LIGHT
 */
/obj/item/portallight
	name = "portal light"
	desc = "A softly pulsing arcane device."
	icon = 'modular/icons/obj/lewd/portal.dmi'
	icon_state = "unpaired"
	w_class = WEIGHT_CLASS_SMALL
	grid_width = 32
	grid_height = 32
	var/obj/item/undies/portal/linked_underwear
	/// Set while a knot is tied through this light. The light can't leave the holder's hand.
	var/knot_locked = FALSE
	/// The top's sex controller for the knot tied through this light, so destroying the light can pull it free.
	var/datum/sex_controller/knot_sexcon

/obj/item/portallight/Destroy()
	if(knot_locked && knot_sexcon)
		var/datum/sex_controller/knotted = knot_sexcon
		knot_sexcon = null
		knotted.knot_remove(forceful_removal = TRUE)
	if(linked_underwear?.linked_light == src)
		linked_underwear.linked_light = null
	linked_underwear = null
	return ..()

/obj/item/portallight/examine(mob/user)
	. = ..()
	if(!linked_underwear)
		. += span_info("It isn't linked to anything. Touch it to a pair of portal panties to link them.")
		return
	if(!get_wearer())
		. += span_info("It is linked, but there's no one on the other side.")
		return
	. += span_info("It is focused on their [portal_focus_name(linked_underwear.focus)]. Middle-click to refocus.")

/obj/item/portallight/proc/get_wearer()
	return linked_underwear?.get_wearer()

/// Whoever is holding the light, in either hand.
/obj/item/portallight/proc/get_holder()
	if(!ishuman(loc))
		return null
	var/mob/living/carbon/human/holder = loc
	if(!(src in holder.held_items))
		return null
	return holder

/obj/item/portallight/proc/set_linked_underwear(obj/item/undies/portal/new_underwear)
	if(linked_underwear == new_underwear)
		update_portal_icon()
		return
	if(linked_underwear?.linked_light == src)
		linked_underwear.linked_light = null
	if(new_underwear?.linked_light && new_underwear.linked_light != src)
		var/obj/item/portallight/old_light = new_underwear.linked_light
		old_light.linked_underwear = null
		old_light.update_portal_icon()
	linked_underwear = new_underwear
	if(new_underwear)
		new_underwear.linked_light = src
	update_portal_icon()

/obj/item/portallight/proc/set_knot_lock(locked, datum/sex_controller/top_sexcon)
	knot_locked = locked
	knot_sexcon = locked ? top_sexcon : null
	if(linked_underwear)
		linked_underwear.knot_locked = locked
	if(locked)
		ADD_TRAIT(src, TRAIT_NODROP, PORTAL_KNOT_TRAIT)
	else
		REMOVE_TRAIT(src, TRAIT_NODROP, PORTAL_KNOT_TRAIT)

/obj/item/portallight/proc/update_portal_icon()
	cut_overlays()
	icon_state = "unpaired"
	var/mob/living/carbon/human/wearer = get_wearer()
	if(!wearer)
		return
	icon_state = "paired"
	var/mutable_appearance/sleeve = mutable_appearance(icon, "portal_sleeve_normal")
	var/skin = "[wearer.skin_tone]"
	if(length(skin) && copytext(skin, 1, 2) != "#")
		skin = "#[skin]"
	sleeve.color = skin
	add_overlay(sleeve)
	var/organ_state
	switch(linked_underwear.focus)
		if(SEX_PART_CUNT)
			organ_state = "portal_vag"
		if(SEX_PART_ANUS)
			organ_state = "portal_anus"
	if(organ_state) // no penis sprite yet, the sleeve alone shows for that focus
		var/mutable_appearance/organ = mutable_appearance(icon, organ_state)
		organ.color = "#f37272"
		add_overlay(organ)

/obj/item/portallight/attack_self(mob/user)
	. = ..()
	var/mob/living/carbon/human/holder = user
	if(!istype(holder))
		return
	if(holder.get_active_held_item() != src)
		to_chat(holder, span_info("I need to hold the portal in my active hand."))
		return
	if(!linked_underwear)
		to_chat(holder, span_info("The portal isn't connected to anything!"))
		return
	var/mob/living/carbon/human/wearer = get_wearer()
	if(!wearer)
		to_chat(holder, span_info("There's no one on the other side!"))
		return
	// Same gate as starting a session by dragging yourself onto someone.
	if(!holder.can_do_sex())
		to_chat(holder, span_warning("I can't do this."))
		return
	if(!holder.client?.prefs?.sexable)
		to_chat(holder, span_warning("I don't want to touch anyone. (Your ERP preference, in the options)"))
		return
	if(!wearer.client?.prefs)
		to_chat(holder, span_warning("No one answers on the other side."))
		log_combat(holder, wearer, "tried portal ERP menu against d/ced")
		return
	if(!wearer.client.prefs.sexable)
		to_chat(holder, span_warning("The portal won't open. (Their ERP preference, in the options)"))
		log_combat(holder, wearer, "tried unwanted portal ERP menu against")
		return
	holder.sexcon.start(wearer)

/obj/item/portallight/MiddleClick(mob/user, params)
	. = ..()
	if(!ishuman(user) || !user.is_holding(src))
		return
	var/mob/living/carbon/human/wearer = get_wearer()
	if(!wearer)
		to_chat(user, span_info("There's no one on the other side!"))
		return
	if(linked_underwear.knot_locked)
		to_chat(user, span_warning("The portal won't shift while something is knotted through it!"))
		return
	var/list/order = PORTAL_FOCUS_ORDER
	var/start = max(order.Find(linked_underwear.focus), 1)
	for(var/step in 1 to length(order))
		var/candidate = order[((start + step - 1) % length(order)) + 1]
		if(!portal_focus_available(wearer, candidate))
			continue
		if(candidate == linked_underwear.focus)
			to_chat(user, span_info("There's nothing else to focus on."))
			return
		linked_underwear.focus = candidate
		to_chat(user, span_info("I refocus the portal on their [portal_focus_name(candidate)]."))
		update_portal_icon()
		return

/**
 * PORTAL PANTIES
 */
/obj/item/undies/portal
	name = "portal panties"
	desc = "Laced with unstable portal magic."
	icon = 'modular/icons/obj/lewd/portal.dmi'
	icon_state = "panties"
	sprite_acc = /datum/sprite_accessory/underwear/portal
	var/obj/item/portallight/linked_light
	/// Which part the portal opens onto: SEX_PART_CUNT, SEX_PART_COCK or SEX_PART_ANUS.
	var/focus = SEX_PART_CUNT
	/// Set while a knot is tied through the portal. The panties can't come off.
	var/knot_locked = FALSE

/obj/item/undies/portal/Initialize(mapload)
	. = ..()
	// Build the feature here so /obj/item/undies/attack doesn't spawn a spare pair through set_accessory_type().
	undies_feature = new /datum/bodypart_feature/underwear()
	undies_feature.accessory_type = sprite_acc

/obj/item/undies/portal/Destroy()
	if(knot_locked && linked_light?.knot_sexcon)
		var/datum/sex_controller/knotted = linked_light.knot_sexcon
		linked_light.knot_sexcon = null
		knotted.knot_remove(forceful_removal = TRUE)
	var/obj/item/portallight/old_light = linked_light
	if(old_light?.linked_underwear == src)
		old_light.linked_underwear = null
	linked_light = null
	old_light?.update_portal_icon()
	return ..()

/obj/item/undies/portal/examine(mob/user)
	. = ..()
	. += span_info(linked_light ? "It is linked to a portal light." : "It isn't linked. Touch a portal light to it to link them.")

/obj/item/undies/portal/proc/get_wearer()
	if(!ishuman(loc))
		return null
	var/mob/living/carbon/human/wearer = loc
	if(wearer.underwear != src)
		return null
	return wearer

/obj/item/undies/portal/attack(mob/M, mob/user, def_zone)
	. = ..()
	var/mob/living/carbon/human/wearer = get_wearer()
	if(wearer && wearer == M)
		on_worn(wearer)

/obj/item/undies/portal/proc/on_worn(mob/living/carbon/human/wearer)
	focus = SEX_PART_ANUS
	for(var/candidate in PORTAL_FOCUS_ORDER)
		if(portal_focus_available(wearer, candidate))
			focus = candidate
			break
	switch(focus)
		if(SEX_PART_CUNT)
			to_chat(wearer, span_info("I feel magical energies focus around my loins."))
		if(SEX_PART_COCK)
			to_chat(wearer, span_info("I feel magical energies focus around my cock."))
		else
			to_chat(wearer, span_info("I feel magical energies focus around my backside."))
	linked_light?.update_portal_icon()

/// Whether these can be taken off right now. Called by both ways of stripping underwear.
/obj/item/undies/proc/can_be_removed(mob/user)
	return TRUE

/obj/item/undies/portal/can_be_removed(mob/user)
	if(knot_locked)
		to_chat(user, span_warning("[src] won't budge while something is knotted through the portal!"))
		return FALSE
	return TRUE

/// Called after these come off a wearer.
/obj/item/undies/proc/on_removed(mob/living/carbon/human/old_wearer)
	return

/obj/item/undies/portal/on_removed(mob/living/carbon/human/old_wearer)
	linked_light?.update_portal_icon()

/obj/item/undies/portal/attackby(obj/item/I, mob/user, params)
	if(!istype(I, /obj/item/portallight))
		return ..()
	var/obj/item/portallight/light = I
	if(knot_locked || light.knot_locked)
		to_chat(user, span_warning("The link won't change while something is knotted through it!"))
		return TRUE
	if(linked_light == light)
		light.set_linked_underwear(null)
		to_chat(user, span_notice("I unlink [light] from [src]."))
		return TRUE
	light.set_linked_underwear(src)
	to_chat(user, span_notice("I link [light] to [src]."))
	return TRUE

/datum/sprite_accessory/underwear/portal
	name = "Portal Panties"
	icon = 'modular/icons/mob/lewd/portal_panties.dmi'
	icon_state = "panties"
	underwear_type = /obj/item/undies/portal
	color_disabled = TRUE

/datum/sprite_accessory/underwear/portal/get_icon_state(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	if(owner.gender == FEMALE)
		return "panties_f"
	return "panties"

/**
 * EMOTE RELAY
 * The wearer's emotes reach whoever holds the linked light, names swapped for "someone".
 */
/mob/living/carbon/human/proc/relay_emote_through_portal(message)
	var/obj/item/undies/portal/portal_undies = underwear
	if(!istype(portal_undies) || !message)
		return
	var/mob/living/carbon/human/holder = portal_undies.linked_light?.get_holder()
	if(!holder || holder == src || !holder.client)
		return
	if(holder in hearers(DEFAULT_MESSAGE_RANGE, src)) // close enough to have seen it anyway
		return
	// Longest first, so a full name is swapped before a shorter name inside it.
	var/list/names = list()
	for(var/candidate in list(real_name, name, get_visible_name(), get_face_name("")))
		if(!istext(candidate) || !length(candidate) || (candidate in names))
			continue
		var/inserted = FALSE
		for(var/i in 1 to length(names))
			if(length(candidate) > length(names[i]))
				names.Insert(i, candidate)
				inserted = TRUE
				break
		if(!inserted)
			names += candidate
	for(var/candidate in names)
		message = replacetext(message, candidate, "someone")
	to_chat(holder, span_love("<i>Through the portal,</i> someone [message]"))

#undef PORTAL_KNOT_TRAIT
#undef PORTAL_FOCUS_ORDER
