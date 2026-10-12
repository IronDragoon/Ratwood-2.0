//This file describes functionality of a fake wall (or a false wall, as they were described in TG)
//This wall however reacts to a message, or a redstone signal if given a redstone_id
//Map it over an open turf; the floor beneath is revealed when it slides open
/obj/structure/falsewall
	plane = WALL_PLANE
	density = TRUE
	opacity = TRUE
	smooth = SMOOTH_MORE
	smooth_diag = FALSE
	climbable = FALSE
	can_be_unanchored = FALSE
	layer = 2.05
	break_sound = 'sound/combat/hits/onstone/stonedeath.ogg'
	attacked_sound = list('sound/combat/hits/onstone/wallhit.ogg', 'sound/combat/hits/onstone/wallhit2.ogg', 'sound/combat/hits/onstone/wallhit3.ogg')
	var/smooth_icon = null
	var/in_motion = FALSE
	var/original_layer = 2.05
	var/slide_direction = null
	var/slide_distance = 24
	var/open_message = ""
	var/close_message = ""
	var/is_closed = TRUE

/obj/structure/falsewall/stone
	name = "stone wall"
	desc = "A wall of smooth unyielding stone."
	icon = 'icons/turf/walls/stone_wall.dmi'
	icon_state = "stone"
	max_integrity = 1800
	canSmoothWith = list(/obj/structure/falsewall/stone, /turf/closed/wall/mineral/rogue/stone)
	var/fake_icon = 'icons/turf/walls/wall.dmi'
	var/mineral_amount = 2
	var/walltype = /turf/closed/wall
	var/opening = FALSE
	damage_deflection = 10

/obj/structure/falsewall/stone/moss
	icon = 'icons/turf/walls/mossy_stone.dmi'

/obj/structure/falsewall/stone/blue_moss
	icon = 'icons/turf/walls/blue_mossy.dmi'

/obj/structure/falsewall/stone/red_moss
	icon = 'icons/turf/walls/red_mossy.dmi'

/obj/structure/falsewall/craftstone
	name = "stone wall"
	desc = "A durable wall made from specially-crafted stone."
	icon = 'icons/turf/walls/craftstone.dmi'
	icon_state = "box"
	max_integrity = 2200
	damage_deflection = 10
	canSmoothWith = list(/obj/structure/falsewall/craftstone, /turf/closed/wall/mineral/rogue/craftstone)

/obj/structure/falsewall/stonebrick
	name = "brick wall"
	desc = "Rows of overlapping bricks form this wall."
	icon = 'icons/turf/walls/stonebrick.dmi'
	icon_state = "stonebrick"
	max_integrity = 1500
	damage_deflection = 20
	canSmoothWith = list(/obj/structure/falsewall/stonebrick, /turf/closed/wall/mineral/rogue/stonebrick, /turf/closed/wall/mineral/rogue/wooddark)

/obj/structure/falsewall/brick
	name = "brick wall"
	desc = "Rows of overlapping bricks held together by mortar form a nigh-impenetrable wall of stone."
	icon = 'icons/turf/walls/brick_wall.dmi'
	icon_state = "brick"
	max_integrity = 2000
	damage_deflection = 20
	canSmoothWith = list(/obj/structure/falsewall/brick, /turf/closed/wall/mineral/rogue/brick)

/obj/structure/falsewall/wood
	name = "wooden wall"
	desc = "A rough-hewn wall of wood."
	icon = 'icons/turf/walls/roguewood.dmi'
	icon_state = "wood"
	max_integrity = 1100
	break_sound = 'sound/combat/hits/onwood/destroywalldoor.ogg'
	attacked_sound = list('sound/combat/hits/onwood/woodimpact (1).ogg','sound/combat/hits/onwood/woodimpact (2).ogg')
	canSmoothWith = list(/obj/structure/falsewall/wood, /turf/closed/wall/mineral/rogue/wood, /obj/structure/roguewindow, /obj/structure/roguetent, /turf/closed/wall/mineral/rogue/wooddark)

/obj/structure/falsewall/Initialize(mapload)
	. = ..()
	if(smooth_icon)
		icon = smooth_icon
	find_smoothing_dir()
	become_hearing_sensitive()

/obj/structure/falsewall/proc/find_smoothing_dir()
	for (var/direction in GLOB.cardinals)
		for(var/allowed_type in canSmoothWith)
			if (allowed_type == src.type)
				continue
			if (find_type_in_direction(src, direction))
				slide_direction = direction
				return

/obj/structure/falsewall/proc/open()
	if(QDELETED(src) || in_motion || !is_closed)
		return
	in_motion = TRUE
	density = FALSE
	opacity = FALSE
	if (isnull(slide_direction))
		animate(src, transform = matrix().Scale(1, 0.1), pixel_y = -14, time = 5)
		addtimer(CALLBACK(src, PROC_REF(finish_opening), FALSE), 6)
	else
		layer = layer - 0.01
		var/target_x = pixel_x
		var/target_y = pixel_y
		switch(slide_direction)
			if(NORTH)
				target_y += slide_distance
			if(SOUTH)
				target_y -= slide_distance
			if(EAST)
				target_x += slide_distance
			if(WEST)
				target_x -= slide_distance
		animate(src, pixel_x = target_x, pixel_y = target_y, time = 5)
		addtimer(CALLBACK(src, PROC_REF(finish_opening), TRUE), 6)


/obj/structure/falsewall/proc/finish_opening(do_update_icon)
	in_motion = FALSE
	is_closed = FALSE
	if(do_update_icon)
		update_icon()

/obj/structure/falsewall/proc/finish_closing(restore_layer)
	density = TRUE
	opacity = TRUE
	if(restore_layer)
		layer = original_layer
	in_motion = FALSE
	is_closed = TRUE
	if(restore_layer)
		update_icon()

/obj/structure/falsewall/proc/close()
	if(QDELETED(src) || in_motion || is_closed || (locate(/mob/living) in loc))
		return
	in_motion = TRUE
	if(isnull(slide_direction))
		animate(src, transform = matrix().Scale(1, 1), pixel_y = 0, time = 5)
		addtimer(CALLBACK(src, PROC_REF(finish_closing), FALSE), 6)
	else
		animate(src, pixel_x = 0, pixel_y = 0, time = 5)
		addtimer(CALLBACK(src, PROC_REF(finish_closing), TRUE), 6)


/obj/structure/falsewall/Hear(message, atom/movable/speaker, message_language, raw_message, radio_freq, list/spans, message_mode)
	. = ..()
	if(speaker == src)
		return
	if(obj_broken)
		return
	if(!ishuman(speaker))
		return
	if(open_message != "" && findtext(message, open_message))
		open()
	if(close_message != "" && findtext(message, close_message))
		close()

/obj/structure/falsewall/redstone_triggered(mob/user)
	if(is_closed)
		open()
	else
		close()

/obj/structure/falsewall/handle_mouseover(location, control, params)
	.=..()
	usr.client.mouseovertext.maptext = {"<span style='font-size:8pt;font-family:"Pterra";color:#607d65;text-shadow:0 0 10px #fff, 0 0 20px #fff, 0 0 30px #e60073, 0 0 40px #e60073, 0 0 50px #e60073, 0 0 60px #e60073, 0 0 70px #e60073;' class='center maptext '>[name]"}
	return
