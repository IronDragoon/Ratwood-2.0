/obj/structure/bondage
	name = "restraint"
	desc = "A crude restraint meant to hold someone in place."
	icon = 'icons/roguetown/misc/structure.dmi'
	anchored = TRUE
	density = TRUE
	can_buckle = TRUE
	max_buckled_mobs = 1
	buckle_lying = 0
	buckle_prevents_pull = TRUE
	buckle_blocks_spells = TRUE
	buckleverb = "strap"
	breakoutextra = 4 MINUTES
	attacked_sound = list('sound/combat/hits/onwood/woodimpact (1).ogg', 'sound/combat/hits/onwood/woodimpact (2).ogg')
	destroy_sound = 'sound/combat/hits/onwood/destroyfurniture.ogg'
	blade_dulling = DULLING_BASHCHOP
	max_integrity = 200
	resistance_flags = NONE

	var/strap_self_time = 2 SECONDS
	var/strap_other_time = 4 SECONDS

/obj/structure/bondage/Initialize(mapload)
	. = ..()
	LAZYINITLIST(buckled_mobs)

/obj/structure/bondage/buckle_mob(mob/living/M, force = FALSE, check_loc = TRUE)
	if(!anchored)
		return FALSE

	if(has_buckled_mobs())
		return FALSE

	if(force)
		return ..()

	var/mob/living/user = usr
	if(!user)
		return ..()

	if(!istype(M, /mob/living/carbon/human))
		to_chat(user, span_warning("It doesn't look like [M.p_they()] can fit into this properly!"))
		return FALSE

	if(M != user)
		var/valid_restraint = FALSE
		var/mob/living/carbon/carbon = M
		if(carbon.handcuffed)
			valid_restraint = TRUE

		if(!valid_restraint)
			for(var/obj/item/grabbing/G in M.grabbedby)
				if(G.grab_state >= GRAB_AGGRESSIVE)
					valid_restraint = TRUE
					break

		if(!valid_restraint)
			to_chat(user, span_warning("I must grab them more forcefully or restrain them to put them in [src]."))
			return FALSE

		M.visible_message(span_danger("[user] starts strapping [M] into [src]!"), \
			span_userdanger("[user] starts strapping you into [src]!"))

		if(!do_after(user, strap_other_time, src))
			return FALSE
	else
		M.visible_message(span_notice("[user] starts positioning [user.p_them()]self into [src]..."), \
			span_notice("I start positioning myself into [src]..."))

		if(!do_after(user, strap_self_time, src))
			return FALSE

	return ..(M, force, FALSE)

/obj/structure/bondage/chains
	name = "chains"
	desc = "Heavy chains bolted into place."
	icon_state = "CHAINS"
	base_pixel_x = 0
	base_pixel_y = 0
	pixel_x = 0
	pixel_y = 0
	density = FALSE
	layer = ABOVE_MOB_LAYER
	attacked_sound = list('sound/combat/hits/onmetal/metalimpact (1).ogg', 'sound/combat/hits/onmetal/metalimpact (2).ogg')
	destroy_sound = 'sound/combat/hits/onwood/destroyfurniture.ogg'
	buckleverb = "chain"

/obj/structure/bondage/x_pillory
	name = "x-pillory"
	desc = "A brutal restraint shaped like a cross."
	icon_state = "x_pillory"
	layer = OBJ_LAYER
	plane = GAME_PLANE
	var/buckle_offset_x = 0
	var/buckle_offset_y = 2

/obj/structure/bondage/x_pillory/post_buckle_mob(mob/living/M)
	. = ..()
	M.set_mob_offsets("bed_buckle", _x = buckle_offset_x, _y = buckle_offset_y)

/obj/structure/bondage/x_pillory/post_unbuckle_mob(mob/living/M)
	. = ..()
	M.reset_offsets("bed_buckle")

/obj/structure/bondage/x_pillory/user_unbuckle_mob(mob/living/buckled_mob, mob/living/user)
	// Someone else is unbuckling the victim
	if(user != buckled_mob)
		user.visible_message(span_notice("[user] starts unstrapping [buckled_mob] from [src]..."), \
			span_notice("You start unstrapping [buckled_mob] from [src]..."))
		if(do_after(user, 3 SECONDS, src))
			return ..()
		return

	// Victim trying to unbuckle self
	to_chat(user, span_warning("You struggle against the tight straps..."))
	if(do_after(user, 10 SECONDS, src))
		user.visible_message(span_warning("[user] manages to unstrap [user.p_them()]self from [src]!"), \
			span_notice("You manage to unstrap yourself from [src]!"))
		return ..()

/*
	Gloryhole
	`dir` is the side the hole faces: the "front", where the partner stands. Only NORTH and SOUTH are supported.
	The game is viewed top-down, so things further south draw in front:
	- Facing SOUTH: the buckled mob is behind the board, and the partner is in front.
	- Facing NORTH: a partner stepped up from the front is behind the board, and the buckled mob is in front, seen from behind.
	Whoever is behind the board gets a pinned layer (GLORYHOLE_HIDDEN_LAYER) under a copy of the board drawn on the mob plane
	(GLORYHOLE_FRONT_LAYER), plus an alpha mask in the board's outline so nothing sticks out past its edges.
	Everything stays on the normal mob plane, so vision cones hide it like any other mob.
*/
/// Board sprite and board-outline mask for each facing a gloryhole supports, in icons/roguetown/misc/structure.dmi
GLOBAL_LIST_INIT(gloryhole_art, list(
	"[SOUTH]" = list("board" = "gloryhole", "mask" = "gloryhole_mask_s"),
	"[NORTH]" = list("board" = "gloryhole_n", "mask" = "gloryhole_mask_n"),
))

/// Whether a gloryhole facing has both its board sprite and mask. Facings without art can't be built.
/proc/gloryhole_has_art(facing)
	var/static/list/known_states
	if(!known_states)
		known_states = icon_states('icons/roguetown/misc/structure.dmi')
	var/list/art = GLOB.gloryhole_art["[facing]"]
	return art && (art["board"] in known_states) && (art["mask"] in known_states)

/obj/structure/bondage/gloryhole
	name = "gloryhole"
	desc = "A wooden partition with a suspicious hole."
	icon_state = "gloryhole"
	dir = SOUTH
	density = TRUE
	layer = MOB_LAYER
	plane = GAME_PLANE
	buckleverb = "position"
	buckle_blocks_spells = FALSE
	/// The buckled mob's current position as list(x, y). Set it with set_buckled_position() so the mask follows.
	var/list/buckled_position
	/// Mobs currently drawn behind the board
	var/list/mob/living/hidden_mobs = list()

/// Where the buckled mob starts, as list(x, y) pixel offsets. North mirrors south; tune both in game.
/obj/structure/bondage/gloryhole/proc/get_default_buckle_position()
	switch(dir)
		if(SOUTH)
			return list(0, 1)
		if(NORTH)
			return list(0, -1)
	return list(0, 0)

/// How far a partner slides toward the board when stepping up, as list(x, y), or null if this facing has no step-up.
/obj/structure/bondage/gloryhole/proc/get_step_up_offset()
	switch(dir)
		if(SOUTH)
			return list(0, 26)
		if(NORTH)
			return list(0, -26)
	return null

/obj/structure/bondage/gloryhole/Initialize(mapload)
	. = ..()
	init_connect_loc_element()
	update_icon()

/obj/structure/bondage/gloryhole/Destroy()
	for(var/mob/living/hidden as anything in hidden_mobs.Copy())
		release_hidden(hidden)
	return ..()

/// Faces the builder, so the builder stands at the front.
/obj/structure/bondage/gloryhole/OnCrafted(dirin, mob/user)
	. = ..()
	setDir(turn(dirin, 180))
	update_icon()

/obj/structure/bondage/gloryhole/update_icon_state()
	. = ..()
	var/list/art = GLOB.gloryhole_art["[dir]"]
	icon_state = (art && gloryhole_has_art(dir)) ? art["board"] : initial(icon_state)

/obj/structure/bondage/gloryhole/update_overlays()
	. = ..()
	// The copy of the board on the mob plane. It covers whoever is behind the board, and vision cones hide it along with them.
	. += mutable_appearance(icon, icon_state, GLORYHOLE_FRONT_LAYER, GAME_PLANE_FOV_HIDDEN)

/obj/structure/bondage/gloryhole/examine(mob/user)
	. = ..()
	if(isobserver(user))
		return
	. += "Left-click from behind to position yourself in \the [src]. Right-click from the front to step up to it."

/// Left-click from behind (or while already standing on it) to step in and position yourself, instead of dragging yourself onto it.
/obj/structure/bondage/gloryhole/attack_hand(mob/living/user)
	. = ..() // frees whoever is in it, as with any restraint
	if(. || has_buckled_mobs())
		return
	if(!ishuman(user) || !(user.mobility_flags & MOBILITY_STAND))
		return
	if(user.loc != loc)
		// Only from the back, the side facing away from the hole
		if(get_dir(loc, user) != turn(dir, 180) || !Adjacent(user))
			return
		if(!user.Move(loc, get_dir(user, loc)))
			to_chat(user, span_warning("I can't get behind \the [src]."))
			return
	user_buckle_mob(user, user)
	return TRUE

/obj/structure/bondage/gloryhole/buckle_mob(mob/living/M, force = FALSE, check_loc = TRUE)
	if(M && ishuman(M) && !has_buckled_mobs())
		if(loc != M?.loc)
			to_chat(M, span_warning("I have to be closer to service \the [src]."))
			return FALSE
	return ..()

/obj/structure/bondage/gloryhole/post_buckle_mob(mob/living/M)
	. = ..()
	// Buckling already turned them to face the hole, and can_face() keeps them there while buckled.
	var/list/start = get_default_buckle_position()
	set_buckled_position(start[1], start[2], M)
	refresh_name(M)
	M.update_vision_cone()

/obj/structure/bondage/gloryhole/post_unbuckle_mob(mob/living/M)
	. = ..()
	M.reset_offsets("bed_buckle")
	buckled_position = null
	if(M.behind_gloryhole == src)
		release_hidden(M)
	refresh_name(M)
	M.update_vision_cone()

/// Moves the buckled mob to a position on the board. The future positions menu should go through this so the mask follows.
/obj/structure/bondage/gloryhole/proc/set_buckled_position(x_offset, y_offset, mob/living/M)
	if(!M)
		M = locate() in buckled_mobs
	if(!M)
		return
	buckled_position = list(x_offset, y_offset)
	M.set_mob_offsets("bed_buckle", _x = x_offset, _y = y_offset)
	// Facing south, the buckled mob is the one behind the board.
	if(dir == SOUTH)
		hide_behind(M, M.get_standard_pixel_x_offset(), M.get_standard_pixel_y_offset())

/// Hidden mobs are anonymous, so their name has to update right away rather than on the next Life tick.
/obj/structure/bondage/gloryhole/proc/refresh_name(mob/living/M)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		H.name = H.get_visible_name()

/// Draws a mob behind the board. shift_x and shift_y are where its sprite ends up relative to its own tile, so the mask can be lined up on the board.
/obj/structure/bondage/gloryhole/proc/hide_behind(mob/living/M, shift_x = 0, shift_y = 0)
	if(M.behind_gloryhole && M.behind_gloryhole != src)
		M.behind_gloryhole.release_hidden(M)
	M.behind_gloryhole = src
	hidden_mobs |= M
	RegisterSignal(M, COMSIG_QDELETING, PROC_REF(on_hidden_deleted), override = TRUE)
	M.layer = GLORYHOLE_HIDDEN_LAYER
	apply_mask(M, shift_x, shift_y)
	M.update_vision_cone()

/// Re-pins the mask to the board after a hidden mob's sprite moved, e.g. from pixel shifting, so they can shift under the board without poking out past its edges.
/obj/structure/bondage/gloryhole/proc/update_mask(mob/living/M)
	if(M.behind_gloryhole != src)
		return
	apply_mask(M, M.pixel_x, M.pixel_y)

/// Puts the board-outline mask on a hidden mob. shift_x and shift_y are where its sprite sits relative to its own tile.
/obj/structure/bondage/gloryhole/proc/apply_mask(mob/living/M, shift_x, shift_y)
	M.remove_filter("gloryhole_mask")
	if(!gloryhole_has_art(dir))
		return
	var/mask_state = GLOB.gloryhole_art["[dir]"]["mask"]
	// The mask sits on the mob, so move it back by the mob's offset to keep it fixed on the board.
	var/mask_x = (x - M.x) * world.icon_size - shift_x
	var/mask_y = (y - M.y) * world.icon_size - shift_y
	M.add_filter("gloryhole_mask", 1, alpha_mask_filter(mask_x, mask_y, icon(icon, mask_state)))

/// Stops drawing a mob behind the board.
/obj/structure/bondage/gloryhole/proc/release_hidden(mob/living/M)
	hidden_mobs -= M
	UnregisterSignal(M, COMSIG_QDELETING)
	if(M.behind_gloryhole != src)
		return
	M.behind_gloryhole = null
	M.remove_filter("gloryhole_mask")
	M.layer = M.lying ? LYING_MOB_LAYER : initial(M.layer)
	M.update_vision_cone()

/obj/structure/bondage/gloryhole/proc/on_hidden_deleted(mob/living/source)
	SIGNAL_HANDLER
	release_hidden(source)

/obj/structure/bondage/gloryhole/attack_right(mob/living/user)
	. = ..()
	if(!ishuman(user) || !(user.mobility_flags & MOBILITY_STAND)) // must be standing
		return

	if(.)
		return
	// Only from the tile the hole faces
	if(get_dir(loc, user) != dir)
		return
	var/list/shift = get_step_up_offset()
	if(!shift)
		return
	user.setDir(turn(dir, 180)) // face the board, but don't lock it
	animate(user, pixel_x = shift[1], pixel_y = shift[2], time = 2.7)
	user.is_shifted = TRUE
	user.passthroughable |= (NORTH | EAST | SOUTH | WEST)
	// Facing north, the partner is the one behind the board. Their shift ending (moving, unshifting) releases them.
	if(dir == NORTH)
		hide_behind(user, shift[1], shift[2])

/obj/structure/bondage/gloryhole/CanPass(atom/movable/mover, turf/target)
	if(has_buckled_mobs())
		return FALSE
	return get_dir(loc, mover) != dir

/obj/structure/bondage/gloryhole/MiddleMouseDrop_T(atom/movable/dragged, mob/living/user)
	if(!has_buckled_mobs() || !ishuman(dragged))
		return ..()
	var/mob/living/buckled_user = locate() in buckled_mobs
	if(isnull(buckled_user) || !istype(buckled_user)) // nobody's home, abort
		return ..()
	if((buckled_user == user) && ishuman(user) && ishuman(dragged) && !user.mmb_intent) // if buckled mob middle click dragged onto non-gloryhole buckled mob, open sexcon
		dragged.MiddleMouseDrop_T(user, user)
		return
	if((dragged == user) && ishuman(user) && !user.mmb_intent) // if non-buckled mob middle click dragged onto gloryhole buckled mob, open sexcon
		buckled_user.MiddleMouseDrop_T(user, user)
		return
	return ..()

/obj/structure/bondage/gloryhole/proc/init_connect_loc_element()
	var/static/list/loc_connections = list(COMSIG_ATOM_EXIT = PROC_REF(on_exit))
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/structure/bondage/gloryhole/proc/on_exit(datum/source, atom/movable/leaving, atom/new_location)
	SIGNAL_HANDLER

	if(dir in CORNERDIRS)
		return

	if(isobserver(leaving))
		return

	if(get_dir(leaving.loc, new_location) != dir)
		return

	leaving.Bump(src)
	return COMPONENT_ATOM_BLOCK_EXIT

/obj/structure/bondage/torture_table
	name = "torture table"
	desc = "A cruel table meant for restraining captives."
	icon = 'icons/roguetown/misc/64x64.dmi'
	icon_state = "tort_table"
	base_pixel_x = -16
	base_pixel_y = 0
	pixel_x = -16
	pixel_y = 0
	layer = TABLE_LAYER
	plane = GAME_PLANE
	buckle_lying = 90
	breakoutextra = 2 MINUTES
	max_integrity = 250
	debris = list(/obj/item/natural/wood/plank = 1)
	var/buckle_offset_y = 8

/obj/structure/bondage/torture_table/post_buckle_mob(mob/living/M)
	. = ..()
	M.set_mob_offsets("bed_buckle", _x = 0, _y = buckle_offset_y)

/obj/structure/bondage/torture_table/post_unbuckle_mob(mob/living/M)
	. = ..()
	M.reset_offsets("bed_buckle")

/obj/structure/bondage/torture_table/user_unbuckle_mob(mob/living/buckled_mob, mob/living/user)
	// Someone else is unbuckling the victim
	if(user != buckled_mob)
		user.visible_message(span_notice("[user] starts unchaining [buckled_mob] from [src]..."), \
			span_notice("You start unchaining [buckled_mob] from [src]..."))
		if(do_after(user, 3 SECONDS, src))
			return ..()
		return

	// Victim trying to unbuckle self (long struggle)
	to_chat(user, span_warning("You struggle against the tight chains..."))
	if(do_after(user, 3 MINUTES, src))
		user.visible_message(span_warning("[user] manages to unstrap [user.p_them()]self from [src]!"), \
			span_notice("You manage to unstrap yourself from [src]!"))
		return ..()

/obj/structure/bondage/torture_table/lever
	name = "torture table lever"
	desc = "A torture table with a built-in lever mechanism. Right click to use the lever."
	icon = 'icons/roguetown/misc/64x64.dmi'
	icon_state = "tort_table_lever"

/obj/structure/bondage/torture_table/lever/attack_right(mob/user)
	. = ..()
	if(.)
		return
	if(!has_buckled_mobs())
		to_chat(user, span_warning("There is nobody to tighten the chains on..."))
		return
	var/mob/living/L = locate() in buckled_mobs
	if(!L)
		return
	if(user == L)
		to_chat(user, span_warning("I can't reach the lever..."))
		return
	playsound(src, 'sound/foley/winch.ogg', 100, extrarange = 3)
	user.visible_message(span_warning("[user] begins to ratchet the chains on [L]!"), span_warning("You start tightening the chains!"))
	if(do_after(user, 2 SECONDS, src))
		var/mob/living/L_double_check = locate() in buckled_mobs
		if(!L_double_check || L != L_double_check) // they got off, abort
			return
		var/def_zone = pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
		var/obj/item/bodypart/BP = L.get_bodypart(def_zone)
		if(BP)
			L.visible_message(span_boldwarning("Chains pull and rip into [L]'s [BP.name]!"), span_userdanger("Chains rip into my [BP.name]!"))
			L.emote("agony")
			BP.add_wound(/datum/wound/fracture)
			BP.update_disabled()
			L.apply_damage(90, BRUTE, def_zone)
			L.Paralyze(80)
