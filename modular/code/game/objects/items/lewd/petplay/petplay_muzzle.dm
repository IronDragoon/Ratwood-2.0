/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle
	name = "locking muzzle"
	desc = "A fitted steel muzzle with a small lock worked into the side of the jaw."
	icon_state = "kazengunmouthguard"
	item_state = "kazengunmouthguard"
	body_parts_covered = FACE|MOUTH
	flags_cover = MASKCOVERSMOUTH
	var/obj/item/roguekey/petplay/generated_key = null
	var/mob/living/carbon/human/petplay_victim = null

/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/Initialize(mapload)
	. = ..()
	if(!lockhash)
		lockhash = rand(100000, 999999)
		while(lockhash in GLOB.lockhashes)
			lockhash = rand(100000, 999999)
		GLOB.lockhashes += lockhash
	LoadComponent(/datum/component/intimate_action_guard/petplay)

/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/Destroy()
	var/datum/component/intimate_action_guard/petplay/action_guard_component = GetComponent(/datum/component/intimate_action_guard/petplay)
	if(action_guard_component)
		action_guard_component.unbind_from_wearer(petplay_victim)
	return ..()

/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/equipped(mob/user, slot)
	. = ..()
	if(slot != SLOT_WEAR_MASK || !ishuman(user))
		return

	var/mob/living/carbon/human/H = user
	petplay_victim = H
	var/datum/component/intimate_action_guard/petplay/action_guard_component = LoadComponent(/datum/component/intimate_action_guard/petplay)
	if(action_guard_component)
		action_guard_component.bind_to_wearer(H)
	if(!generated_key || QDELETED(generated_key))
		generate_petplay_key(H, H)
	else
		sync_generated_key_metadata(H)
	if(locked)
		ADD_TRAIT(src, TRAIT_NODROP, "petplay-lock")
	else
		REMOVE_TRAIT(src, TRAIT_NODROP, "petplay-lock")

/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/dropped(mob/user)
	. = ..()
	var/datum/component/intimate_action_guard/petplay/action_guard_component = GetComponent(/datum/component/intimate_action_guard/petplay)
	if(action_guard_component)
		action_guard_component.unbind_from_wearer(petplay_victim)
	petplay_victim = null

/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/examine(mob/user)
	. = ..()
	. += span_notice("The latch is [locked ? "locked" : "unlocked"].")

/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/canStrip(mob/stripper, mob/owner)
	if(locked)
		return FALSE
	return ..()

/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/proc/is_hardmode_active()
	return petplay_victim?.client?.prefs?.petplay_hardmode == PETPLAY_HARDMODE_ENABLED

/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/proc/get_lock_denial_string()
	return pick_petplay_string("petplay_lock_messages.json", is_hardmode_active() ? "petplay_hardmode_denial" : "petplay_lock_denial")

/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/proc/is_generated_unlock_key(obj/item/interaction_item)
	if(!interaction_item || !generated_key || QDELETED(generated_key))
		return FALSE
	return interaction_item == generated_key

/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/proc/sync_generated_key_metadata(mob/living/carbon/human/H, mob/user = null)
	if(!H || !generated_key || QDELETED(generated_key))
		return

	var/obj/item/roguekey/petplay/new_key = generated_key
	var/was_hardmode_key = new_key.hardmode_indestructible
	new_key.name = "[H]'s muzzle key"
	new_key.desc = "A small key cut for [H]'s locking muzzle."
	new_key.hardmode_indestructible = FALSE

	if(is_hardmode_active())
		new_key.hardmode_indestructible = TRUE
		new_key.name = "[H]'s binding key"
		new_key.desc = "A small key bearing the weight of [H]'s permanent muzzle binding."
		if(user && !was_hardmode_key)
			to_chat(user, span_warning("The key feels heavier than it should. [H]'s freedom now rests in your hands."))

/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/proc/generate_petplay_key(mob/user, mob/living/carbon/human/H)
	if(!user || !H)
		return
	var/obj/item/roguekey/petplay/new_key = generated_key
	if(!new_key || QDELETED(new_key))
		new_key = new(get_turf(user))
		new_key.lockhash = src.lockhash
		generated_key = new_key
	sync_generated_key_metadata(H, user)

/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/proc/set_petplay_locked_state(mob/living/carbon/human/H, should_lock, mob/user = null, obj/item/interaction_item = null, interaction_source = "manual")
	if(!H)
		H = petplay_victim
	if(!H || H.wear_mask != src)
		return FALSE

	var/new_locked_state = !!should_lock
	var/old_locked_state = locked
	locked = new_locked_state

	if(new_locked_state)
		ADD_TRAIT(src, TRAIT_NODROP, "petplay-lock")
	else
		REMOVE_TRAIT(src, TRAIT_NODROP, "petplay-lock")

	if(old_locked_state == new_locked_state)
		return FALSE

	sync_generated_key_metadata(H, user)
	to_chat(H, new_locked_state ? span_warning(pick_petplay_string("petplay_lock_messages.json", "petplay_lock_click")) : span_notice(pick_petplay_string("petplay_lock_messages.json", "petplay_unlock_click")))
	return TRUE
