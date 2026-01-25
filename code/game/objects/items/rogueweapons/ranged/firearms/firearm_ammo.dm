/**
 * Parent bullet.
 */
/obj/item/ammo_casing/caseless/bullet
	name = "PARENT SPHERE"
	desc = "YOU SHOULD NOT BE SEEING THIS. YELL AT CARL!!!"
	projectile_type = /obj/projectile/bullet/reusable
	icon = 'icons/roguetown/weapons/ammo.dmi'
	icon_state = "musketball"
	possible_item_intents = list(/datum/intent/use)
	dropshrink = 0.5
	max_integrity = 0.1
	w_class = WEIGHT_CLASS_TINY

/**
 * Generic ammo used by handgonnes and arquebuses
 */

/obj/item/ammo_casing/caseless/bullet/lead
	name = "lead sphere"
	desc = "A small lead sphere. This should go well with smokepowder."
	projectile_type = /obj/projectile/bullet/lead
	caliber = "lead_sphere"

/obj/projectile/bullet/lead
	name = "lead sphere"
	damage = 60
	damage_type = BRUTE
	icon = 'icons/roguetown/weapons/ammo.dmi'
	icon_state = "musketball_proj"
	ammo_type = /obj/item/ammo_casing/caseless/bullet/lead
	range = 25		//Higher than arrow, but not halfway through the entire town.
	hitsound = 'sound/combat/hits/hi_arrow2.ogg'
	embedchance = 100
	woundclass = BCLASS_PIERCE
	flag = "piercing"
	armor_penetration = 60
	speed = 0.1
	npc_simple_damage_mult = 4//240
	accuracy = 90
	bonus_accuracy = 10

/obj/projectile/bullet/lead/on_hit(atom/target)
	. = ..()

	var/mob/living/L = firer
	if(!L || !L.mind)
		return

	var/skill_multiplier = 0

	if(isliving(target)) // If the target theyre shooting at is a mob/living
		var/mob/living/T = target
		if(T.stat != DEAD) // If theyre alive
			skill_multiplier = 4

	if(skill_multiplier && can_train_combat_skill(L, /datum/skill/combat/firearms, SKILL_LEVEL_EXPERT))
		L.mind.add_sleep_experience(/datum/skill/combat/firearms, L.STAINT * skill_multiplier)

/**
 * Now, actual grapeshot, for the proper blunderbuss.
 */

/obj/item/ammo_casing/caseless/bullet/grapeshot
	name = "grapeshot"
	desc = "A collection of tiny metal beads. This should go well with smokepowder."
	projectile_type = /obj/projectile/bullet/grapeshot
	caliber = "grapeshot"
	icon_state = "grapeshot"
	pellets = 6
	variance = 30

/obj/projectile/bullet/grapeshot
	name = "grapeshot"
	damage = 15
	damage_type = BRUTE
	icon = 'icons/roguetown/weapons/ammo.dmi'
	icon_state = "musketball_proj"
	ammo_type = /obj/item/ammo_casing/caseless/bullet/grapeshot
	range = 15
	hitsound = 'sound/combat/hits/hi_arrow2.ogg'
	embedchance = 100
	woundclass = BCLASS_PIERCE
	flag = "piercing"
	armor_penetration = 60
	speed = 0.1
	npc_simple_damage_mult = 8//720 potential.
	accuracy = 90
	bonus_accuracy = 10

/obj/projectile/bullet/grapeshot/on_hit(atom/target)
	. = ..()

	var/mob/living/L = firer
	if(!L || !L.mind)
		return

	var/skill_multiplier = 0

	if(isliving(target)) // If the target theyre shooting at is a mob/living
		var/mob/living/T = target
		if(T.stat != DEAD) // If theyre alive
			skill_multiplier = 4

	if(skill_multiplier && can_train_combat_skill(L, /datum/skill/combat/firearms, SKILL_LEVEL_EXPERT))
		L.mind.add_sleep_experience(/datum/skill/combat/firearms, L.STAINT * skill_multiplier)


/obj/projectile/bullet/rogue/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(istype(target, /mob/living/carbon/human))
		var/mob/living/carbon/human/M = target
		var/list/screams = list("painscream", "paincrit")
		var/check = rand(1, 12)//12CON or higher to beat this every time.
		if(isliving(target))
			if(check > M.STACON)
				M.emote(screams)
				M.Knockdown(rand(15,30))
				M.Immobilize(rand(30,60))

//The actual ammo.
/obj/item/quiver/bullet
	name = "lead ball pouch"
	desc = "This pouch can hold a handful of musket balls, or, perhaps, grapeshot."
	icon = 'icons/roguetown/weapons/ammo.dmi'
	icon_state = "slingpouch"//Need another sprite.
	item_state = "slingpouch"
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_NECK
	max_storage = 8
	w_class = WEIGHT_CLASS_NORMAL
	grid_height = 64
	grid_width = 32

/obj/item/quiver/bullet/attack_turf(turf/T, mob/living/user)
	if(arrows.len >= max_storage)
		to_chat(user, span_warning("My [src.name] is full!"))
		return
	to_chat(user, span_notice("I begin to gather the ammunition..."))
	for(var/obj/item/ammo_casing/caseless/bullet in T.contents)
		if(do_after(user, 5))
			if(!eatarrow(bullet))
				break

/obj/item/quiver/bullet/attackby(obj/A, loc, params)
	if(A.type in subtypesof(/obj/item/ammo_casing/caseless/bullet))
		if(arrows.len < max_storage)
			if(ismob(loc))
				var/mob/M = loc
				M.doUnEquip(A, TRUE, src, TRUE, silent = TRUE)
			else
				A.forceMove(src)
			arrows += A
			update_icon()
		else
			to_chat(loc, span_warning("Full!"))
		return
	if(istype(A, /obj/item/gun/ballistic/firearm))
		var/obj/item/gun/ballistic/firearm/B = A
		if(arrows.len && !B.chambered)
			for(var/AR in arrows)
				if(istype(AR, /obj/item/ammo_casing/caseless/bullet))
					arrows -= AR
					B.attackby(AR, loc, params)
					break
		return
	..()

/obj/item/quiver/bullet/attack_right(mob/user)
	if(arrows.len)
		var/obj/O = arrows[arrows.len]
		arrows -= O
		O.forceMove(user.loc)
		user.put_in_hands(O)
		update_icon()
		return TRUE

/obj/item/quiver/bullet/update_icon()
	return

/obj/item/quiver/bullet/lead/Initialize()
	. = ..()
	for(var/i in 1 to max_storage)
		var/obj/item/ammo_casing/caseless/bullet/lead/B = new()
		arrows += B
	update_icon()

/obj/item/quiver/bullet/grapeshot/Initialize()
	. = ..()
	for(var/i in 1 to max_storage)
		var/obj/item/ammo_casing/caseless/bullet/grapeshot/B = new()
		arrows += B
	update_icon()