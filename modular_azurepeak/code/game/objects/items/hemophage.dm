/obj/item/reagent_containers/glass/bottle/alchemical/sanguineous
	name = "Sanguineous Phial"
	desc = "A ritual phial prepared to capture stolen vitality."
	icon_state = "sanguineous_phial"
	color = "#ffffff"
	reagent_flags = DRAINABLE | TRANSPARENT
	possible_item_intents = list(INTENT_FILL)
	var/is_spoiled = FALSE
	var/spoil_timer_generation = 0
	var/phial_mode = "fill"
	var/allowed_reagent = /datum/reagent/medicine/vital_essence
	var/spoiled_reagent = /datum/reagent/medicine/spoiled_essence

/obj/item/reagent_containers/glass/bottle/alchemical/sanguineous/update_icon(dont_fill = FALSE)
	cut_overlays()
	if(closed)
		add_overlay("sanguineous_phial_cork")
	
	if(dont_fill)
		return

	underlays.Cut()

	if(reagents.total_volume)
		var/mutable_appearance/filling = mutable_appearance(icon)
		var/percent = round((reagents.total_volume / volume) * 100)
		
		if(percent <= 33)
			filling.icon_state = "sanguineous_phial_fill1"
		else if(percent <= 66)
			filling.icon_state = "sanguineous_phial_fill2"
		else
			filling.icon_state = "sanguineous_phial_fill3"
		
		filling.alpha = mix_alpha_from_reagents(reagents.reagent_list)
		filling.color = mix_color_from_reagents(reagents.reagent_list)
		underlays += filling

/obj/item/reagent_containers/glass/bottle/alchemical/sanguineous/Initialize()
	. = ..()
	update_phial_intents()
	update_phial_state()

/obj/item/reagent_containers/glass/bottle/alchemical/sanguineous/attack_self(mob/user)
	. = ..()
	update_phial_state()

/obj/item/reagent_containers/glass/bottle/alchemical/sanguineous/do_open(mob/user, no_msg = FALSE, no_snd = FALSE)
	. = ..()
	if(phial_mode == "feed" && !is_spoiled && reagents?.total_volume)
		spoil_timer_generation++
		addtimer(CALLBACK(src, PROC_REF(spoil_contents), spoil_timer_generation), 5 MINUTES)
		if(user)
			to_chat(user, span_warning("I uncork [src]. The essence within will not keep for long."))
	update_phial_state()

/obj/item/reagent_containers/glass/bottle/alchemical/sanguineous/do_close(mob/user, no_msg = FALSE, no_snd = FALSE)
	. = ..()
	update_phial_state()

/obj/item/reagent_containers/glass/bottle/alchemical/sanguineous/on_reagent_change(changetype)
	. = ..()
	lock_to_vital_essence()
	if(reagents.total_volume <= 0 && phial_mode == "feed")
		shatter_phial()

/obj/item/reagent_containers/glass/bottle/alchemical/sanguineous/attack(mob/living/M, mob/living/user, def_zone)
	if(phial_mode == "feed")
		if(closed)
			to_chat(user, span_warning("I must uncork the phial before feeding from it."))
			return
		if(reagents.total_volume <= 0)
			to_chat(user, span_warning("The phial is empty."))
			return
		return ..()

	if(closed)
		to_chat(user, span_warning("I must uncork the phial before harvesting into it."))
		return
	if(user.used_intent.type != INTENT_FILL)
		to_chat(user, span_warning("This phial is empty. I should use fill intent to harvest from a wound."))
		return
	if(!isliving(M))
		return ..()
	if(!HAS_TRAIT(user, TRAIT_HEMOPHAGE))
		to_chat(user, span_warning("Only hemophages can harvest vital essence with this phial."))
		return
	if(reagents.total_volume >= volume)
		to_chat(user, span_warning("The phial is already full."))
		return
	if(HAS_TRAIT(M, TRAIT_HEMOPHAGE))
		to_chat(user, span_warning("A halfbloods's essence will not answer this rite."))
		return
	if(M.mind?.has_antag_datum(/datum/antagonist/vampire))
		to_chat(user, span_warning("A kindred's blood is too profane for this phial."))
		return
	if(M.blood_volume <= 0)
		to_chat(user, span_warning("There is no vital essence left to harvest from [M]."))
		return

	var/target_zone = check_zone(def_zone)
	var/harvest_site
	if(iscarbon(M))
		var/mob/living/carbon/target = M
		var/obj/item/bodypart/target_part = target.get_bodypart(target_zone)
		if(!target_part)
			to_chat(user, span_warning("I can't find a limb there to harvest from."))
			return
		var/has_wounding_bleed = FALSE
		if(target_part?.wounds?.len)
			for(var/datum/wound/wound as anything in target_part.wounds)
				if(wound?.bleed_rate > 0)
					has_wounding_bleed = TRUE
					break
		if(target_part.get_bleed_rate() <= 0 && !has_wounding_bleed)
			if(target_part.wounds?.len)
				to_chat(user, span_warning("That limb's wounds are clotted or not actively bleeding."))
			else
				to_chat(user, span_warning("That limb has no open wound to harvest from."))
			return
		harvest_site = parse_zone(target_zone)
	else if(issimple(M))
		var/mob/living/simple_animal/simple_target = M
		if(simple_target.health >= simple_target.maxHealth)
			to_chat(user, span_warning("[simple_target] has no open wound to harvest from."))
			return
		harvest_site = simple_target.simple_limb_hit(target_zone)
		if(!harvest_site)
			harvest_site = "wound"
	else
		to_chat(user, span_warning("This creature's vitality cannot be harvested with [src]."))
		return

	if(!do_after(user, 25, target = M))
		return

	var/fill_amount = min(volume - reagents.total_volume, M.blood_volume)
	if(fill_amount <= 0)
		to_chat(user, span_warning("There is not enough blood left in this wound to prepare the phial."))
		return

	M.blood_volume = max(M.blood_volume - fill_amount, 0)
	reagents.add_reagent(allowed_reagent, fill_amount)
	phial_mode = "feed"
	update_phial_intents()
	to_chat(user, span_notice("I siphon vital essence from [M]'s [harvest_site] into [src]. I should cork it or drink now."))
	M.visible_message(span_warning("[user] harvests from [M]'s bleeding [harvest_site] with [src]."), span_userdanger("[user] harvests from my bleeding [harvest_site]!"))
	update_icon()
	update_phial_state()

/obj/item/reagent_containers/glass/bottle/alchemical/sanguineous/attack_obj(obj/target, mob/living/user)
	if(user.used_intent.type == INTENT_POUR || user.used_intent.type == INTENT_FILL || user.used_intent.type == INTENT_SPLASH)
		to_chat(user, span_warning("This ritual phial cannot be used to pour, fill, or splash into other vessels."))
		return
	return ..()

/obj/item/reagent_containers/glass/bottle/alchemical/sanguineous/proc/spoil_contents(timer_generation)
	if(QDELETED(src) || is_spoiled)
		return
	if(timer_generation != spoil_timer_generation)
		return
	if(closed)
		return
	if(reagents.total_volume <= 0)
		return
	var/vital_amount = reagents.get_reagent_amount(allowed_reagent)
	if(vital_amount > 0)
		reagents.remove_reagent(allowed_reagent, vital_amount)
		reagents.add_reagent(spoiled_reagent, vital_amount)
	is_spoiled = TRUE
	update_phial_state()

/obj/item/reagent_containers/glass/bottle/alchemical/sanguineous/on_enter_storage(datum/component/storage/concrete/S, mob/M)
	. = ..()
	if(S?.does_not_spill || closed || !reagents?.total_volume)
		return
	if(M)
		to_chat(M, span_warning("I stash [src] uncorked, and it spills inside the container."))
	reagents.clear_reagents()
	update_phial_state()

/obj/item/reagent_containers/glass/bottle/alchemical/sanguineous/proc/update_phial_state()
	if(phial_mode == "fill")
		name = "empty Sanguineous Phial"
		desc = closed ? "A ritual phial made to be filled from a bleeding wound. It is corked." : "A ritual phial made to be filled from a bleeding wound. It is uncorked."
		return
	if(is_spoiled)
		name = "spoiled Sanguineous Phial"
		desc = closed ? "A corked phial whose stolen essence has already spoiled." : "An uncorked phial whose stolen essence has spoiled."
		return
	if(closed)
		name = "sealed Sanguineous Phial"
		desc = "A ritual phial corked against spoilage."
		return
	name = "unsealed Sanguineous Phial"
	desc = "A ritual phial left open to the air. The essence inside is beginning to turn."

/obj/item/reagent_containers/glass/bottle/alchemical/sanguineous/proc/update_phial_intents()
	if(phial_mode == "fill")
		possible_item_intents = list(INTENT_FILL)
		return
	possible_item_intents = list(INTENT_POUR)

/obj/item/reagent_containers/glass/bottle/alchemical/sanguineous/proc/lock_to_vital_essence()
	if(!reagents)
		return
	for(var/datum/reagent/R as anything in reagents.reagent_list)
		if(R.type != allowed_reagent && R.type != spoiled_reagent)
			reagents.remove_reagent(R.type, R.volume)

/obj/item/reagent_containers/glass/bottle/alchemical/sanguineous/proc/shatter_phial()
	visible_message(span_warning("The phial disintegrates as the last drop of vital essence leaves it."))
	qdel(src)
