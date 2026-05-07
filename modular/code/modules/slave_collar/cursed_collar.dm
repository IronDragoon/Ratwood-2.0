/obj/item/clothing/neck/roguetown/cursed_collar
	name = "cursed collar"
	always_show_examine_link = TRUE
	desc = "A sinister looking collar with ruby studs. It seems to radiate a dark energy. \nLooks like you'd need someone else's help to take it off."
	// Credit regarding sprites to Necbro
	// https://github.com/StoneHedgeSS13/StoneHedge/commit/9ddc09d4cb91903beff6d523c91aef75312d5163
	icon = 'modular_stonehedge/icons/clothing/armor/neck.dmi'
	mob_overlay_icon = 'modular_stonehedge/icons/clothing/armor/onmob/neck.dmi'
	icon_state = "cursed_collar"
	item_state = "cursed_collar"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_NECK
	body_parts_covered = NECK
	resistance_flags = INDESTRUCTIBLE
	leashable = TRUE
	var/mob/living/carbon/human/victim = null
	var/datum/mind/collar_master = null
	var/list/collar_owners = list()
	var/silenced = FALSE
	var/applying = FALSE
	/// Round-persistent counter for non-self ejaculation events received by the current wearer.
	var/received_cum_count = 0

/obj/item/clothing/neck/roguetown/cursed_collar/proc/normalize_owner_data()
	if(!islist(collar_owners))
		collar_owners = list()

	// Purge null/deleted minds. Iterate a copy to avoid skip-on-removal bugs.
	for(var/datum/mind/M in collar_owners.Copy())
		if(!M || QDELETED(M))
			collar_owners -= M

	// Re-sync collar_master only if it is still alive and not already present.
	if(collar_master && !QDELETED(collar_master) && !(collar_master in collar_owners))
		collar_owners += collar_master

	if(length(collar_owners) > 2)
		collar_owners.Cut(3)

	collar_master = length(collar_owners) ? collar_owners[1] : null

/obj/item/clothing/neck/roguetown/cursed_collar/proc/get_owner_minds()
	normalize_owner_data()
	return collar_owners.Copy()

/obj/item/clothing/neck/roguetown/cursed_collar/proc/get_primary_master()
	normalize_owner_data()
	return collar_master

/obj/item/clothing/neck/roguetown/cursed_collar/proc/has_owner(datum/mind/owner_mind)
	if(!owner_mind)
		return FALSE
	normalize_owner_data()
	return (owner_mind in collar_owners)

/obj/item/clothing/neck/roguetown/cursed_collar/proc/set_sole_owner(datum/mind/owner_mind)
	normalize_owner_data()
	collar_owners.Cut()
	if(owner_mind)
		collar_owners += owner_mind
	collar_master = owner_mind

/obj/item/clothing/neck/roguetown/cursed_collar/proc/add_shared_owner(datum/mind/owner_mind)
	if(!owner_mind)
		return FALSE
	normalize_owner_data()
	if(owner_mind in collar_owners)
		return TRUE
	if(length(collar_owners) >= 2)
		return FALSE
	collar_owners += owner_mind
	collar_master = length(collar_owners) ? collar_owners[1] : null
	return TRUE

/obj/item/clothing/neck/roguetown/cursed_collar/proc/ensure_owner_component(datum/mind/owner_mind)
	if(!owner_mind)
		return null
	var/datum/component/collar_master/CM = owner_mind.GetComponent(/datum/component/collar_master)
	if(!CM)
		CM = owner_mind.AddComponent(/datum/component/collar_master)
	return CM

/obj/item/clothing/neck/roguetown/cursed_collar/proc/grant_owner_control_for_wearer(mob/living/carbon/human/wearer)
	if(!wearer)
		return FALSE
	var/added = FALSE
	for(var/datum/mind/owner_mind in get_owner_minds())
		var/datum/component/collar_master/CM = ensure_owner_component(owner_mind)
		if(CM && CM.add_pet(wearer))
			added = TRUE
	return added

/obj/item/clothing/neck/roguetown/cursed_collar/proc/revoke_owner_control_for_wearer(datum/mind/owner_mind, mob/living/carbon/human/wearer)
	if(!owner_mind || !wearer)
		return FALSE
	var/datum/component/collar_master/CM = owner_mind.GetComponent(/datum/component/collar_master)
	if(!CM)
		return FALSE
	if(wearer in CM.my_pets)
		return CM.remove_pet_without_releasing(wearer)
	return FALSE

/obj/item/clothing/neck/roguetown/cursed_collar/proc/revoke_owner_control_for_wearer_silent(datum/mind/owner_mind, mob/living/carbon/human/wearer)
	if(!owner_mind || !wearer)
		return FALSE
	var/datum/component/collar_master/CM = owner_mind.GetComponent(/datum/component/collar_master)
	if(!CM)
		return FALSE
	if(wearer in CM.my_pets)
		return CM.remove_pet_without_releasing(wearer, silent_pet = TRUE)
	return FALSE

/obj/item/clothing/neck/roguetown/cursed_collar/examine(mob/user)
	. = ..()
	if(received_cum_count == 1)
		. += span_notice("1 tally mark is etched into the collar's metal surface.")
	else if(received_cum_count > 1)
		. += span_notice("[received_cum_count] tally marks are etched into the collar's metal surface.")

/obj/item/clothing/neck/roguetown/cursed_collar/proc/record_nonself_ejaculation(mob/living/carbon/human/source, mob/living/carbon/human/wearer)
	if(!source || !wearer)
		return FALSE
	if(source == wearer)
		return FALSE
	if(loc != wearer)
		return FALSE
	var/added = get_tally_increment_for_source(source)
	received_cum_count += added
	var/tally_msg = added == 1 ? "A metal scraping sound is briefly heard, a tally mark suddenly appears on [wearer]'s collar." : "A metal scraping sound is briefly heard, two tally marks suddenly appear on [wearer]'s collar."
	for(var/mob/M in viewers(1, wearer))
		to_chat(M, span_notice(tally_msg))
	return TRUE

/obj/item/clothing/neck/roguetown/cursed_collar/proc/get_tally_increment_for_source(mob/living/carbon/human/source)
	return tally_increment_for_ejaculation_source(source)

/obj/item/clothing/neck/roguetown/cursed_collar/proc/reset_received_cum_count()
	received_cum_count = 0

/obj/item/clothing/neck/roguetown/cursed_collar/attack(mob/living/carbon/human/C, mob/living/user)
	if(!istype(C))
		return ..()

	if(C.get_item_by_slot(SLOT_NECK))
		to_chat(user, span_warning("[C] is already wearing something around their neck!"))
		return

	var/obj/item/chastity/existing_chastity = C.chastity_device
	if(istype(existing_chastity) && existing_chastity.chastity_cursed)
		to_chat(user, span_warning("[C] is already bound by cursed chastity."))
		return

	var/datum/mind/master_mind = get_primary_master()
	// Track whether we auto-claim ownership so we can roll it back on failure.
	var/newly_claimed = FALSE
	if(!master_mind)
		master_mind = user?.mind
		if(!master_mind)
			to_chat(user, span_warning("The collar rejects binding without an imprinted master."))
			return
		newly_claimed = TRUE

	if(applying)
		return

	var/surrender_mod = 1
	if(C.surrendering || C.compliance)
		surrender_mod = 0.5

	applying = TRUE
	if(do_mob(user, C, 50 * surrender_mod))
		playsound(loc, 'sound/foley/equip/equip_armor_plate.ogg', 30, TRUE, -2)

		// Claim ownership now that the action succeeded.
		if(newly_claimed)
			set_sole_owner(master_mind)

		// Try to equip
		if(!C.equip_to_slot_if_possible(src, SLOT_NECK, TRUE, TRUE))
			to_chat(user, span_warning("You fail to lock the collar around [C]'s neck!"))
			applying = FALSE
			return

		// Add pet to each owner component so all owners can control the same wearer.
		if(!grant_owner_control_for_wearer(C))
			to_chat(user, span_warning("The collar fails to bind [C]."))
			C.dropItemToGround(src, force = TRUE)
			applying = FALSE
			return

		SEND_SIGNAL(C, COMSIG_CARBON_COLLAR_BOUND, master_mind, src)
		ADD_TRAIT(src, TRAIT_NODROP, CURSED_ITEM_TRAIT)
		log_combat(user, C, "tried to collar", addition="with [src]")
	applying = FALSE

/obj/item/clothing/neck/roguetown/cursed_collar/attack_self(mob/user)
	. = ..()
	if(!user?.mind)
		return
	var/datum/mind/current_master = get_primary_master()
	if(!current_master)
		if(tgui_alert(user, "Become the master of this collar?", "Cursed Collar", list("Yes", "No")) != "Yes")
			return
		ensure_owner_component(user.mind)
		set_sole_owner(user.mind)
		to_chat(user, span_userdanger("You feel the collar being imprinted with your will."))
		return

	if(has_owner(user.mind))
		to_chat(user, span_notice("The collar already recognizes your ownership."))
		return

	var/current_owner_name = current_master?.current?.real_name || "Unknown"
	var/choice = tgui_alert(user, "This collar is already owned by [current_owner_name].", "Cursed Collar", list("Take Over Ownership", "Join Shared Ownership", "Cancel"))
	if(choice == "Cancel" || !choice)
		return

	if(choice == "Take Over Ownership")
		var/list/old_owners = get_owner_minds()
		ensure_owner_component(user.mind)
		set_sole_owner(user.mind)
		if(ishuman(loc))
			var/mob/living/carbon/human/wearer = loc
			for(var/datum/mind/old_owner in old_owners)
				if(old_owner == user.mind)
					continue
				revoke_owner_control_for_wearer_silent(old_owner, wearer)
			grant_owner_control_for_wearer(wearer)
		to_chat(user, span_userdanger("You seize full ownership of the collar."))
		return

	if(choice == "Join Shared Ownership")
		if(!add_shared_owner(user.mind))
			to_chat(user, span_warning("This collar already has the maximum number of owners."))
			return
		ensure_owner_component(user.mind)
		if(ishuman(loc))
			var/mob/living/carbon/human/wearer = loc
			grant_owner_control_for_wearer(wearer)
			to_chat(user, span_notice("You bind your will to share ownership with [current_owner_name]."))
		else
			to_chat(user, span_notice("You bind your will to share ownership with [current_owner_name]. Your control will activate once the collar is worn."))


/obj/item/clothing/neck/roguetown/cursed_collar/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(slot != SLOT_NECK)
		return

	if(applying)
		return

	var/datum/mind/master_mind = get_primary_master()
	if(!master_mind)
		return

	// Defer one tick so equip state is fully settled before prompt/lock logic.
	addtimer(CALLBACK(src, PROC_REF(handle_equip), user), 0.1 SECONDS)

/obj/item/clothing/neck/roguetown/cursed_collar/proc/handle_equip(mob/living/carbon/human/user)
	// By the time this timer fires the collar may have been removed (race, admin delete, etc.).
	if(!user || user.get_item_by_slot(SLOT_NECK) != src)
		return

	if(istype(user, /mob/living/carbon/human/dummy))
		return

	if(user?.mind && has_owner(user.mind))
		to_chat(user, span_warning("The collar rejects self-binding. It must be fastened by another master."))
		user.dropItemToGround(src, force = TRUE)
		return

	if(!user.mind)
		user.visible_message(span_warning("\The [src] fails to lock around [user]'s neck."))
		user.dropItemToGround(src, force = TRUE)
		return

	var/obj/item/chastity/existing_chastity = user.chastity_device
	if(istype(existing_chastity) && existing_chastity.chastity_cursed)
		to_chat(user, span_warning("The collar recoils from the cursed chastity already binding you."))
		user.dropItemToGround(src, force = TRUE)
		return

	var/datum/mind/master_mind = get_primary_master()
	if(SEND_SIGNAL(user, COMSIG_CARBON_COLLAR_BIND_ATTEMPT, master_mind, src) & COMPONENT_COLLAR_BIND_BLOCK)
		to_chat(user, span_warning("The collar resists binding right now."))
		user.dropItemToGround(src, force = TRUE)
		return

	if(tgui_alert(user, "Submit to the collar's control?", "Cursed Collar", list("Yes!", "No")) != "Yes!")
		user.visible_message(span_warning("[user] resists the collar's control."))
		to_chat(user, span_warning("Your defiant will prevents the collar from binding to you!"))
		user.dropItemToGround(src, force = TRUE)
		return

	if(!grant_owner_control_for_wearer(user))
		to_chat(user, span_warning("The collar fails to bind to you."))
		user.dropItemToGround(src, force = TRUE)
		return

	SEND_SIGNAL(user, COMSIG_CARBON_COLLAR_BOUND, master_mind, src)
	ADD_TRAIT(src, TRAIT_NODROP, CURSED_ITEM_TRAIT)

	user.visible_message(span_warning("Cursed collar around [user]'s neck clicks shut!"), \
							span_userdanger("Cursed collar around your neck clicks shut!"))
	playsound(loc, 'sound/foley/equip/equip_armor_plate.ogg', 30, TRUE, -2)

	// Only send the gain signal once master is set
	addtimer(CALLBACK(src, PROC_REF(send_collar_signal), user), 2)

/obj/item/clothing/neck/roguetown/cursed_collar/dropped(mob/living/carbon/human/user)
	. = ..()
	reset_received_cum_count()
	if(!user)
		return
	SEND_SIGNAL(user, COMSIG_CARBON_LOSE_COLLAR)

	for(var/datum/mind/owner_mind in get_owner_minds())
		var/datum/component/collar_master/CM = owner_mind.GetComponent(/datum/component/collar_master)
		if(CM && (user in CM.my_pets))
			CM.remove_pet(user)

	REMOVE_TRAIT(src, TRAIT_NODROP, CURSED_ITEM_TRAIT)

/obj/item/clothing/neck/roguetown/cursed_collar/canStrip(mob/living/carbon/human/stripper, mob/living/carbon/human/owner)
	// Some strip call sites may not pass owner; infer from loc when possible.
	if(!owner && ishuman(loc))
		owner = loc

	if(has_owner(stripper?.mind))
		return TRUE

	return ..()

/obj/item/clothing/neck/roguetown/cursed_collar/doStrip(mob/living/carbon/human/stripper, mob/living/carbon/human/owner)
	if(!owner && ishuman(loc))
		owner = loc

	if(has_owner(stripper?.mind))
		REMOVE_TRAIT(src, TRAIT_NODROP, CURSED_ITEM_TRAIT)
		if(owner)
			SEND_SIGNAL(owner, COMSIG_CARBON_LOSE_COLLAR)
		return owner ? owner.dropItemToGround(src, force = TRUE) : FALSE

	return ..()

/obj/item/clothing/neck/roguetown/cursed_collar/proc/send_collar_signal(mob/living/carbon/human/user)
	if(!get_primary_master()) // Don't send signal if no master
		SEND_SIGNAL(user, COMSIG_CARBON_LOSE_COLLAR)
		return
	SEND_SIGNAL(user, COMSIG_CARBON_GAIN_COLLAR, src)
