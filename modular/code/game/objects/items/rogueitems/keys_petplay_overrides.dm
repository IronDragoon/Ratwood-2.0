/obj/item/roguekey/lord/proc/modular_petplay_attack(mob/M, mob/user, def_zone)
	if(!ishuman(M))
		return null

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

	if(device.locked && device.is_hardmode_active())
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

/obj/item/lockpick/proc/modular_petplay_attack(mob/M, mob/user, def_zone)
	if(!ishuman(M))
		return null
	if(!ishuman(user))
		to_chat(user, span_warning("I can't get enough control to pick this lock."))
		return TRUE

	var/mob/living/carbon/human/H = M
	var/mob/living/carbon/human/U = user

	if(!modular_petplay_content_enabled_for_pair(U, H))
		to_chat(user, span_warning("Pet-play content is disabled for one of the participants."))
		return TRUE

	var/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/device = H.wear_mask
	if(!istype(device))
		to_chat(user, span_warning("[H] isn't wearing a lockable muzzle."))
		return TRUE
	if(!device.locked)
		to_chat(user, span_notice("[H]'s muzzle is already unlocked."))
		return TRUE
	if(device.is_hardmode_active())
		playsound(src, 'sound/items/pickbad.ogg', 40, TRUE)
		to_chat(user, span_warning(device.get_lock_denial_string()))
		return TRUE

	var/pickskill = U.get_skill_level(/datum/skill/misc/lockpicking)
	var/perbonus = U.STAPER / 5
	var/picktime = clamp(60 - (pickskill * 8), 15, 60)
	var/pickchance = 25 + (pickskill * 10) + perbonus
	pickchance *= picklvl
	pickchance = clamp(pickchance, 5, 95)

	user.visible_message(span_notice("[user] starts picking the lock on [H]'s muzzle..."), span_notice("I start picking the lock on [H]'s muzzle..."))
	if(!do_after(user, picktime, target = H))
		return TRUE

	var/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/current_device = H.wear_mask
	if(!istype(current_device))
		to_chat(user, span_warning("The lock is no longer there."))
		return TRUE
	if(!current_device.locked)
		to_chat(user, span_notice("[H]'s muzzle is already unlocked."))
		return TRUE
	if(current_device.is_hardmode_active())
		playsound(src, 'sound/items/pickbad.ogg', 40, TRUE)
		to_chat(user, span_warning(current_device.get_lock_denial_string()))
		return TRUE

	if(prob(pickchance))
		playsound(src, pick('sound/items/pickgood1.ogg', 'sound/items/pickgood2.ogg'), 30, TRUE)
		to_chat(user, span_green("The lock gives way."))
		current_device.set_petplay_locked_state(H, FALSE, user, src, "lockpick")
		if(U.mind)
			add_sleep_experience(U, /datum/skill/misc/lockpicking, U.STAINT / 2)
	else
		playsound(src, 'sound/items/pickbad.ogg', 40, TRUE)
		take_damage(1, BRUTE, "blunt")
		to_chat(user, span_warning("Clack."))
		if(U.mind)
			add_sleep_experience(U, /datum/skill/misc/lockpicking, U.STAINT / 4)

	return TRUE

/obj/item/melee/touch_attack/lesserknock/proc/modular_petplay_attack(mob/M, mob/user, def_zone)
	if(!ishuman(M))
		return null
	if(!ishuman(user))
		to_chat(user, span_warning("I can't get enough control to pick this lock."))
		return TRUE

	var/mob/living/carbon/human/H = M
	var/mob/living/carbon/human/U = user

	if(!modular_petplay_content_enabled_for_pair(U, H))
		to_chat(user, span_warning("Pet-play content is disabled for one of the participants."))
		return TRUE

	var/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/device = H.wear_mask
	if(!istype(device))
		to_chat(user, span_warning("[H] isn't wearing a lockable muzzle."))
		return TRUE
	if(!device.locked)
		to_chat(user, span_notice("[H]'s muzzle is already unlocked."))
		return TRUE
	if(device.is_hardmode_active())
		playsound(src, 'sound/items/pickbad.ogg', 40, TRUE)
		to_chat(user, span_warning(device.get_lock_denial_string()))
		return TRUE

	var/pickskill = U.get_skill_level(/datum/skill/misc/lockpicking)
	var/perbonus = U.STAPER / 5
	var/picktime = clamp(60 - (pickskill * 8), 15, 60)
	var/pickchance = 25 + (pickskill * 10) + perbonus
	pickchance *= picklvl
	pickchance = clamp(pickchance, 5, 95)

	user.visible_message(span_notice("[user] traces the spectral lockpick across [H]'s muzzle lock..."), span_notice("I guide the spectral pick into [H]'s muzzle lock..."))
	if(!do_after(user, picktime, target = H))
		return TRUE

	var/obj/item/clothing/mask/rogue/facemask/steel/petplay_muzzle/current_device = H.wear_mask
	if(!istype(current_device))
		to_chat(user, span_warning("The lock is no longer there."))
		return TRUE
	if(!current_device.locked)
		to_chat(user, span_notice("[H]'s muzzle is already unlocked."))
		return TRUE
	if(current_device.is_hardmode_active())
		playsound(src, 'sound/items/pickbad.ogg', 40, TRUE)
		to_chat(user, span_warning(current_device.get_lock_denial_string()))
		return TRUE

	if(prob(pickchance))
		playsound(src, pick('sound/items/pickgood1.ogg', 'sound/items/pickgood2.ogg'), 30, TRUE)
		to_chat(user, span_green("The lock gives way."))
		current_device.set_petplay_locked_state(H, FALSE, user, src, "lockpick")
		if(U.mind)
			add_sleep_experience(U, /datum/skill/misc/lockpicking, U.STAINT / 2)
	else
		playsound(src, 'sound/items/pickbad.ogg', 40, TRUE)
		take_damage(1, BRUTE, "blunt")
		to_chat(user, span_warning("Clack. The arcyne focus wavers."))
		if(U.mind)
			add_sleep_experience(U, /datum/skill/misc/lockpicking, U.STAINT / 4)

	return TRUE
