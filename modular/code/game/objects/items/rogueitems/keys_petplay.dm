/obj/item/roguekey/petplay
	name = "muzzle key"
	desc = "A small key for a locking muzzle."
	icon_state = "mazekey"

/obj/item/roguekey/petplay/attack_self(mob/user)
	if(!ishuman(user))
		return ..()
	var/mob/living/carbon/human/U = user
	if(U.cmode && hardmode_indestructible)
		try_break_hardmode_key(U)
		return
	return attack(user, user, user.zone_selected)

/obj/item/roguekey/petplay/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(target == user && ishuman(user))
		var/mob/living/carbon/human/U = user
		if(U.cmode && hardmode_indestructible)
			try_break_hardmode_key(U)
			return
		attack(user, user, user.zone_selected)
		return
	return ..()

/obj/item/roguekey/petplay/proc/try_break_hardmode_key(mob/living/carbon/human/user)
	var/choice = tgui_alert(user,
		"This key carries the same permanent binding as the muzzle it opens. With fierce intent you could shatter it forever.",
		"Destroy Key",
		list("Shatter it", "Cancel"))
	if(choice != "Shatter it")
		return
	if(QDELETED(src) || !istype(user.get_active_held_item(), /obj/item/roguekey/petplay))
		return
	user.visible_message(span_warning("[user] strains with fierce intent and shatters [src] in [user.p_their()] grasp!"), span_warning("I strain with fierce intent, forcing [src] to shatter in my grasp!"))
	playsound(get_turf(user), 'sound/foley/doors/lockrattle.ogg', 100, TRUE)
	qdel(src)

/obj/item/roguekey/petplay/attack(mob/M, mob/user, def_zone)
	if(!ishuman(M))
		return ..()

	var/mob/living/carbon/human/H = M
	var/mob/living/carbon/human/user_human = null
	if(ishuman(user))
		user_human = user

	if(!modular_petplay_content_enabled_for_pair(user_human, H))
		to_chat(user, span_warning("Pet-play content is disabled for one of the participants."))
		return TRUE

	var/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/device = H.wear_mask
	if(!istype(device))
		to_chat(user, span_warning("[H] isn't wearing a lockable muzzle."))
		return TRUE

	if(device.lockhash != src.lockhash)
		var/found_key = FALSE
		for(var/obj/item/storage/keyring/K in user.held_items)
			if(!K.contents.Find(/obj/item/roguekey/petplay))
				continue
			for(var/obj/item/roguekey/petplay/KE in K.contents)
				if(KE.lockhash == device.lockhash)
					found_key = TRUE
					break
			if(found_key)
				break
		if(!found_key)
			to_chat(user, span_warning("This key doesn't fit [H]'s muzzle."))
			playsound(src, 'sound/foley/doors/lockrattle.ogg', 100)
			return TRUE

	if(device.locked && device.is_hardmode_active() && !device.is_generated_unlock_key(src))
		to_chat(user, span_warning(device.get_lock_denial_string()))
		playsound(src, 'sound/foley/doors/lockrattle.ogg', 100)
		return TRUE

	if(device.locked)
		user.visible_message(span_notice("[user] unlocks [H]'s muzzle with [src]."))
		playsound(src, 'sound/foley/doors/lock.ogg', 100)
		device.set_petplay_locked_state(H, FALSE, user, src, "key")
	else
		user.visible_message(span_notice("[user] locks [H]'s muzzle with [src]."))
		playsound(src, 'sound/foley/doors/lock.ogg', 100)
		device.set_petplay_locked_state(H, TRUE, user, src, "key")

	return TRUE
