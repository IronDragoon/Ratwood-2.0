// Portal panties and the portal light: a linked pair for ERP at any distance.
// Ported from Rivermist Hollow (sheetofseaweed/Rivermist-Hollow-Vanderlin).
// Art (portal.dmi, portal_panties.dmi) by Rivermist Hollow, CC-BY-SA 3.0. The cock focus reuses the wearer's own body sprite.

#define PORTAL_KNOT_TRAIT "portal_knot"

/**
 * PORTAL FOCUS
 * What differs by the part the portal opens onto. GLOB.portal_foci holds one each, in the order the light cycles through them.
 */
/datum/portal_focus
	/// SEX_PART_CUNT, SEX_PART_COCK or SEX_PART_ANUS.
	var/part
	var/name
	/// The organ the wearer needs. Null for the anus, which only needs a chest.
	var/organ_slot
	/// The light's overlay for this focus. Null draws the wearer's own cock instead.
	var/overlay_state
	/// What the wearer feels when the panties go on.
	var/worn_line

/datum/portal_focus/New(part, name, organ_slot, overlay_state, worn_line)
	src.part = part
	src.name = name
	src.organ_slot = organ_slot
	src.overlay_state = overlay_state
	src.worn_line = worn_line

/// Whether this person has the part behind this focus.
/datum/portal_focus/proc/available_on(mob/living/carbon/human/wearer)
	if(!wearer)
		return FALSE
	return organ_slot ? !!wearer.getorganslot(organ_slot) : !!wearer.get_bodypart(BODY_ZONE_CHEST)

GLOBAL_LIST_INIT(portal_foci, list(
	new /datum/portal_focus(SEX_PART_CUNT, "cunt", ORGAN_SLOT_VAGINA, "portal_vag", "I feel magical energies focus around my loins."),
	new /datum/portal_focus(SEX_PART_COCK, "cock", ORGAN_SLOT_PENIS, null, "I feel magical energies focus around my cock."),
	new /datum/portal_focus(SEX_PART_ANUS, "ass", null, "portal_anus", "I feel magical energies focus around my backside."),
))

/proc/get_portal_focus(part)
	for(var/datum/portal_focus/focus as anything in GLOB.portal_foci)
		if(focus.part == part)
			return focus
	return null

/// Finds the portal light linking these two people (or one person to themselves), held by either of them.
/proc/find_portal_light_between(mob/living/carbon/human/first, mob/living/carbon/human/second)
	if(!ishuman(first) || !ishuman(second))
		return null
	for(var/mob/living/carbon/human/holder as anything in list(first, second))
		for(var/obj/item/portal_light/light in holder.held_items)
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

/// This person's portal panties, if they are wearing a pair right now.
/mob/living/carbon/human/proc/get_worn_portal_panties()
	RETURN_TYPE(/obj/item/undies/portal)
	var/obj/item/undies/portal/portal_undies = underwear
	if(!istype(portal_undies) || portal_undies.get_wearer() != src)
		return null
	return portal_undies

/**
 * PORTAL LIGHT
 */
/obj/item/portal_light
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
	/// world.time after which the "can't let go" reason may show again, so one attempt doesn't print it twice.
	var/next_knot_lock_notice = 0
	/// Which portal_glow_[n] colour the light shows, from the wearer's arousal. 0 while unlinked.
	var/glow_step = 0

/obj/item/portal_light/Destroy()
	break_knot_on_destroy()
	if(linked_underwear?.linked_light == src)
		linked_underwear.linked_light = null
	linked_underwear = null
	return ..()

/**
 * For either item's Destroy while a knot is tied through it: lifts the item locks now, while the link still
 * reaches both items, then yanks the knot free asynchronously, since the yank runs emotes and sleeps.
 */
/obj/item/portal_light/proc/break_knot_on_destroy()
	if(!knot_locked || !knot_sexcon)
		return
	var/datum/sex_controller/knot_controller = knot_sexcon
	set_knot_lock(FALSE)
	INVOKE_ASYNC(knot_controller, TYPE_PROC_REF(/datum/sex_controller, knot_remove), TRUE)

/obj/item/portal_light/examine(mob/user)
	. = ..()
	if(!linked_underwear)
		. += span_info("It isn't linked to anything. Touch it to a pair of portal panties to link them.")
		return
	if(!get_wearer())
		. += span_info("It is linked, but there's no one on the other side.")
		return
	var/datum/portal_focus/focus = get_portal_focus(linked_underwear.focus)
	. += span_info("It is focused on their [focus?.name]. Middle-click to refocus.")

/obj/item/portal_light/on_blocked_unequip(mob/user)
	if(!knot_locked || world.time < next_knot_lock_notice)
		return
	next_knot_lock_notice = world.time + 1 SECONDS
	to_chat(user, span_warning("I can't let go of [src]! Something is knotted through the portal. (Click the knot alert to pull free.)"))

/obj/item/portal_light/proc/get_wearer()
	return linked_underwear?.get_wearer()

/// Whoever is holding the light, in either hand.
/obj/item/portal_light/proc/get_holder()
	if(!ishuman(loc))
		return null
	var/mob/living/carbon/human/holder = loc
	if(!(src in holder.held_items))
		return null
	return holder

/obj/item/portal_light/proc/set_linked_underwear(obj/item/undies/portal/new_underwear)
	if(linked_underwear == new_underwear)
		update_portal_icon()
		return
	if(linked_underwear?.linked_light == src)
		linked_underwear.linked_light = null
	if(new_underwear?.linked_light && new_underwear.linked_light != src)
		var/obj/item/portal_light/old_light = new_underwear.linked_light
		old_light.linked_underwear = null
		old_light.update_portal_icon()
	linked_underwear = new_underwear
	if(new_underwear)
		new_underwear.linked_light = src
	update_portal_icon()

/obj/item/portal_light/proc/set_knot_lock(locked, datum/sex_controller/top_sexcon)
	knot_locked = locked
	knot_sexcon = locked ? top_sexcon : null
	if(linked_underwear)
		linked_underwear.knot_locked = locked
	if(locked)
		ADD_TRAIT(src, TRAIT_NODROP, PORTAL_KNOT_TRAIT)
	else
		REMOVE_TRAIT(src, TRAIT_NODROP, PORTAL_KNOT_TRAIT)

/// Arousal to glow colour: green, lime, yellow, orange, then red from the climax threshold.
/proc/portal_glow_step(arousal)
	return clamp(round(arousal / 25) + 1, 1, 5)

/// The wearer's groin colour, resolved the way their body's genitals resolve it: skin tone, fur or scale colour, or chest colour.
/proc/portal_flesh_color(mob/living/carbon/human/wearer)
	var/list/sources = color_key_source_list_from_carbon(wearer)
	var/flesh = "[sources[KEY_CHEST_COLOR]]"
	if(!length(flesh))
		return "#ffffff"
	if(copytext(flesh, 1, 2) != "#")
		flesh = "#[flesh]"
	return flesh

/obj/item/portal_light/proc/update_portal_icon()
	cut_overlays()
	icon_state = "unpaired"
	glow_step = 0
	var/mob/living/carbon/human/wearer = get_wearer()
	if(!wearer)
		return
	icon_state = "paired_body"
	glow_step = portal_glow_step(wearer.sexcon?.arousal)
	add_overlay(mutable_appearance(icon, "portal_glow_[glow_step]"))
	var/flesh = portal_flesh_color(wearer)
	var/mutable_appearance/sleeve = mutable_appearance(icon, "portal_sleeve_normal")
	sleeve.color = flesh
	add_overlay(sleeve)
	var/datum/portal_focus/focus = get_portal_focus(linked_underwear.focus)
	if(!focus)
		return
	if(!focus.overlay_state)
		var/mutable_appearance/cock = portal_cock_overlay(wearer)
		if(cock) // no usable sprite leaves the sleeve bare
			add_overlay(cock)
		return
	var/mutable_appearance/organ = mutable_appearance(icon, focus.overlay_state)
	organ.color = gradient("#f37272", flesh, 0.35) // pink, warmed toward their own flesh
	add_overlay(organ)

/// The wearer's arousal changed; their light redraws only when that crosses into another glow colour.
/datum/sex_controller/proc/portal_arousal_changed()
	var/mob/living/carbon/human/wearer = user
	if(!istype(wearer))
		return
	var/obj/item/portal_light/light = wearer.get_worn_portal_panties()?.linked_light
	if(light && light.glow_step != portal_glow_step(arousal))
		light.update_portal_icon()

/// Side-on portal cocks, built once per look: "[accessory type]-[icon state]-[colours]" = icon.
GLOBAL_LIST_EMPTY(portal_cock_icons)

/// Multiplied over the cock so its root darkens into the portal. Columns 13-15 hold the root in every side-on frame.
GLOBAL_DATUM(portal_cock_root_shade, /icon)

/proc/portal_get_root_shade()
	if(!GLOB.portal_cock_root_shade)
		var/icon/shade = icon('icons/blanks/32x32.dmi', "nothing")
		shade.DrawBox("#ffffff", 1, 1, 32, 32)
		shade.DrawBox("#e8e2ec", 13, 1, 13, 32)
		shade.DrawBox("#c3b6cd", 14, 1, 14, 32)
		shade.DrawBox("#9687aa", 15, 1, 15, 32)
		GLOB.portal_cock_root_shade = shade
	return GLOB.portal_cock_root_shade

/**
 * The wearer's own cock, drawn side-on poking out of the portal: their shape, size, colours and current
 * soft or hard state, from the same cached sprites as their body. Null if there's nothing to draw.
 */
/obj/item/portal_light/proc/portal_cock_overlay(mob/living/carbon/human/wearer)
	var/obj/item/organ/penis/cock = wearer.getorganslot(ORGAN_SLOT_PENIS)
	if(!cock?.accessory_type)
		return null
	var/datum/sprite_accessory/penis/accessory = SPRITE_ACCESSORY(cock.accessory_type)
	if(!accessory)
		return null
	// Skips get_appearance(), which hides the cock whenever underwear is worn.
	var/state = accessory.get_icon_state(cock, null, wearer)
	if(!state)
		return null
	var/key = "[accessory.type]-[state]-[cock.accessory_colors]"
	var/icon/side_on = GLOB.portal_cock_icons[key]
	if(!side_on)
		for(var/mutable_appearance/layer as anything in accessory.get_overlay(state, cock.accessory_colors))
			if(!findtext(layer.icon_state, "_FRONT"))
				continue
			side_on = icon(layer.icon, layer.icon_state, WEST)
			side_on.Blend(portal_get_root_shade(), ICON_MULTIPLY)
			break
		if(!side_on)
			return null
		GLOB.portal_cock_icons[key] = side_on
	var/mutable_appearance/overlay = mutable_appearance(side_on)
	// Moves the groin of the body-scale frame (15, 9) onto the portal opening (12, 14), in BYOND pixel coordinates.
	overlay.pixel_x = -3
	overlay.pixel_y = 5
	return overlay

/// The wearer's cock changed state; a light focused on it redraws to match.
/mob/living/carbon/human/proc/refresh_portal_cock()
	var/obj/item/undies/portal/portal_undies = get_worn_portal_panties()
	if(portal_undies?.focus == SEX_PART_COCK)
		portal_undies.linked_light?.update_portal_icon()

/obj/item/portal_light/attack_self(mob/user)
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

/obj/item/portal_light/MiddleClick(mob/user, params)
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
	var/list/foci = GLOB.portal_foci
	var/start = max(foci.Find(get_portal_focus(linked_underwear.focus)), 1)
	for(var/step in 1 to length(foci))
		var/datum/portal_focus/candidate = foci[((start + step - 1) % length(foci)) + 1]
		if(!candidate.available_on(wearer))
			continue
		if(candidate.part == linked_underwear.focus)
			to_chat(user, span_info("There's nothing else to focus on."))
			return
		linked_underwear.focus = candidate.part
		to_chat(user, span_info("I refocus the portal on their [candidate.name]."))
		update_portal_icon()
		return

/**
 * PORTAL PAIR CASE
 * A one-use case holding a light and panties that are already linked. Sold by the brassface and taken from loadout.
 */
/obj/item/portal_pair_case
	name = "portal pair case"
	desc = "A small gilded case holding a portal light and a pair of portal panties, already bound to one another."
	icon = 'modular/icons/obj/lewd/portal.dmi'
	icon_state = "box"
	w_class = WEIGHT_CLASS_SMALL
	grid_width = 32
	grid_height = 32

/obj/item/portal_pair_case/attack_self(mob/user)
	. = ..()
	var/obj/item/portal_light/light = new(get_turf(user))
	var/obj/item/undies/portal/panties = new(get_turf(user))
	light.set_linked_underwear(panties)
	user.playsound_local(get_turf(user), 'sound/foley/latch.ogg', 50, TRUE) // the opener alone hears it
	to_chat(user, span_notice("I open [src]; a portal light and a pair of portal panties, already linked."))
	qdel(src)
	user.put_in_hands(light)
	user.put_in_hands(panties)

/**
 * PORTAL PANTIES
 */
/obj/item/undies/portal
	name = "portal panties"
	desc = "Laced with unstable portal magic."
	icon = 'modular/icons/obj/lewd/portal.dmi'
	icon_state = "panties"
	sprite_acc = /datum/sprite_accessory/underwear/portal
	var/obj/item/portal_light/linked_light
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
	if(knot_locked)
		linked_light?.break_knot_on_destroy()
	var/obj/item/portal_light/old_light = linked_light
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
	var/datum/portal_focus/chosen = GLOB.portal_foci[length(GLOB.portal_foci)] // the ass, which everyone has
	for(var/datum/portal_focus/candidate as anything in GLOB.portal_foci)
		if(candidate.available_on(wearer))
			chosen = candidate
			break
	focus = chosen.part
	to_chat(wearer, span_info(chosen.worn_line))
	linked_light?.update_portal_icon()

/obj/item/undies/portal/can_be_removed(mob/user)
	if(knot_locked)
		to_chat(user, span_warning("[src] won't budge while something is knotted through the portal!"))
		return FALSE
	return TRUE

/obj/item/undies/portal/on_removed(mob/living/carbon/human/old_wearer)
	linked_light?.update_portal_icon()

/obj/item/undies/portal/attackby(obj/item/I, mob/user, params)
	if(!istype(I, /obj/item/portal_light))
		return ..()
	var/obj/item/portal_light/light = I
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
	if(!message)
		return
	var/mob/living/carbon/human/holder = get_worn_portal_panties()?.linked_light?.get_holder()
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
