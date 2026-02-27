/obj/item/chastity
	name = "chastity"
	desc = "An absolute necessity."
	icon = 'icons/roguetown/items/cages.dmi'
	icon_state = "cage_standard"
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE
	obj_flags = CAN_BE_HIT
	break_sound = 'sound/foley/cloth_rip.ogg'
	blade_dulling = DULLING_CUT
	max_integrity = 200
	integrity_failure = 0.1
	drop_sound = 'sound/foley/dropsound/cloth_drop.ogg'
	slot_flags = ITEM_SLOT_MOUTH
	var/gendered
	var/race
	var/datum/bodypart_feature/underwear/chastity_feature
	var/covers_breasts = FALSE
	sewrepair = TRUE
	var/covers_rear = TRUE
	grid_height = 32
	grid_width = 32
	throw_speed = 0.5
	var/sprite_acc = /datum/sprite_accessory/chastity_wear/cage_standard

/obj/item/chastity/attack(mob/M, mob/user, def_zone)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(!H.underwear)
			if(!get_location_accessible(H, BODY_ZONE_PRECISE_GROIN))
				return
			if(!chastity_feature)
				var/datum/bodypart_feature/underwear/chastity_new = new /datum/bodypart_feature/underwear()
				chastity_new.set_accessory_type(sprite_acc, color, H)
				chastity_feature = chastity_new
			user.visible_message(span_notice("[user] tries to put [src] on [H]..."))
			if(do_after(user, 50, needhand = 1, target = H))
				var/obj/item/bodypart/chest = H.get_bodypart(BODY_ZONE_CHEST)
				chest.add_bodypart_feature(chastity_feature)
				user.dropItemToGround(src)
				forceMove(H)
				H.underwear = src
				chastity_feature.accessory_colors = color

/obj/item/chastity/Destroy()
	chastity_feature = null
	return ..()

// Chastity Items
/obj/item/chastity/cage_standard
	name = "Chastity Cage"
	desc = "A small metal cage, for preventing access to the wearer's penis."
	icon_state = "cage_standard"
	sprite_acc = /datum/sprite_accessory/chastity_wear/cage_standard
	covers_rear = FALSE
