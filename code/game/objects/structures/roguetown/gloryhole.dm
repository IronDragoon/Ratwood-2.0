/*
	Gloryhole
	`dir` is the side the hole faces: the "front", where the partner stands. Only NORTH and SOUTH are supported.
	The game is viewed top-down, so things further south draw in front:
	- Facing SOUTH: the buckled mob is behind the board, and the partner is in front.
	- Facing NORTH: a partner stepped up from the front is behind the board, and the buckled mob is in front, seen from behind.
	Whoever is behind the board gets a pinned layer (GLORYHOLE_HIDDEN_LAYER) under a copy of the board drawn on the mob plane
	(GLORYHOLE_FRONT_LAYER), plus an alpha mask in the board's outline so nothing sticks out past its edges.
	Everything stays on the normal mob plane, so vision cones hide it like any other mob.

	Left-clicking is the only way to use it. It opens the ERP menu with a side panel (gloryhole_menu.dm) whose buttons depend
	on where you stand (get_role()). The occupant presses one part against the hole at a time (a GLORYHOLE_PLACEMENT_*),
	and sex actions involving the occupant may only use that part (gloryhole_allows_sex_action()).
*/
/// Board sprite, board-outline mask and hole height for each facing a gloryhole supports, in icons/roguetown/misc/structure.dmi.
/// hole_y is the height of the hole's centre in pixels from the bottom of the tile.
GLOBAL_LIST_INIT(gloryhole_art, list(
	"[SOUTH]" = list("board" = "gloryhole", "mask" = "gloryhole_mask_s", "hole_y" = 11.5),
	"[NORTH]" = list("board" = "gloryhole_n", "mask" = "gloryhole_mask_n", "hole_y" = 11.5),
))

/// The occupant's parts that sex actions may use while in each placement
GLOBAL_LIST_INIT(gloryhole_placement_parts, list(
	GLORYHOLE_PLACEMENT_NEUTRAL = SEX_PART_NULL,
	GLORYHOLE_PLACEMENT_MOUTH = SEX_PART_JAWS,
	GLORYHOLE_PLACEMENT_COCK = SEX_PART_COCK | SEX_PART_BALLS | SEX_PART_SLIT_SHEATH | SEX_PART_GROIN,
	GLORYHOLE_PLACEMENT_ASS = SEX_PART_ANUS | SEX_PART_CUNT | SEX_PART_GROIN,
))

/// Whether a gloryhole facing has both its board sprite and mask. Facings without art can't be built.
/proc/gloryhole_has_art(facing)
	var/static/list/known_states
	if(!known_states)
		known_states = icon_states('icons/roguetown/misc/structure.dmi')
	var/list/art = GLOB.gloryhole_art["[facing]"]
	return art && (art["board"] in known_states) && (art["mask"] in known_states)

/// Whether a sex action fits the placement of any gloryhole occupant involved in it. Acting on yourself is never limited.
/proc/gloryhole_allows_sex_action(datum/sex_action/action, mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!target || user == target)
		return TRUE
	var/obj/structure/bondage/gloryhole/hole = user.buckled
	if(istype(hole) && !hole.placement_allows(action.get_gloryhole_parts(user, target, TRUE)))
		return FALSE
	hole = target.buckled
	if(istype(hole) && !hole.placement_allows(action.get_gloryhole_parts(user, target, FALSE)))
		return FALSE
	return TRUE

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
	/// What the occupant presses against the hole, a GLORYHOLE_PLACEMENT_* define. Change it with set_placement().
	var/placement = GLORYHOLE_PLACEMENT_NEUTRAL
	/// Whether the occupant was chained when strapped in. They can only struggle free, and the partner picks their placement.
	var/occupant_restrained = FALSE
	/// Whether the restrained occupant is struggling free right now
	var/struggling = FALSE
	/// Whoever is stepped up to the front of the board. Only one at a time.
	var/mob/living/carbon/human/partner
	/// Mouth height in pixels on a sprite with no face offset. Species offsets and sprite scale are worked out from it. Tune in game.
	var/mouth_height = 23.5
	/// Crotch height in pixels on a sprite with no underwear offset. Species offsets and sprite scale are worked out from it. Tune in game.
	var/groin_height = 8.5

/// Where the buckled mob sits in the neutral placement, as list(x, y) pixel offsets
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
	if(partner)
		release_partner(partner)
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

/obj/structure/bondage/gloryhole/proc/get_occupant()
	RETURN_TYPE(/mob/living/carbon/human)
	return locate(/mob/living/carbon/human) in buckled_mobs

/// Where a mob stands relative to the board, as a GLORYHOLE_ROLE_* define
/obj/structure/bondage/gloryhole/proc/get_role(mob/living/user)
	if(user in buckled_mobs)
		return GLORYHOLE_ROLE_OCCUPANT
	if(!isturf(user.loc) || user.z != z || get_dist(user, src) > 1)
		return GLORYHOLE_ROLE_NONE
	if(user.loc == loc)
		return GLORYHOLE_ROLE_BEHIND
	var/side = get_dir(loc, user)
	if(side == dir)
		return GLORYHOLE_ROLE_FRONT
	if(side == turn(dir, 180))
		return GLORYHOLE_ROLE_BEHIND
	return GLORYHOLE_ROLE_SIDE

/// Whether someone sees the board from behind, where the hole's other side isn't on show
/obj/structure/bondage/gloryhole/proc/is_behind(mob/user)
	if(user.z != z || user.loc == loc)
		return TRUE
	return dir == SOUTH ? (user.y > y) : (user.y < y)

// Left-click is the only way to use it, and it never frees whoever is inside as other restraints do.
/obj/structure/bondage/gloryhole/attack_hand(mob/living/user)
	if(ishuman(user))
		open_menu(user)
	return TRUE

// A handcuffed occupant's clicks don't reach attack_hand(), but they still need the menu to struggle free.
/mob/living/carbon/human/RestrainedClickOn(atom/A)
	var/obj/structure/bondage/gloryhole/hole = A
	if(istype(hole) && buckled == hole)
		hole.open_menu(src)
		return
	return ..()

/obj/structure/bondage/gloryhole/attack_right(mob/user)
	return TRUE

/obj/structure/bondage/gloryhole/MouseDrop_T(atom/movable/dropping, mob/living/user)
	return

/obj/structure/bondage/gloryhole/examine(mob/user)
	. = ..()
	if(isobserver(user))
		return
	. += "Left-click to use \the [src]."
	var/mob/living/carbon/human/occupant = get_occupant()
	if(!occupant)
		return
	validate_placement()
	if(placement == GLORYHOLE_PLACEMENT_NEUTRAL || is_behind(user) || !user.client?.prefs?.sexable)
		return
	. += get_examine_lines(occupant, user)

/// The pink lines saying what's pressed against the hole
/obj/structure/bondage/gloryhole/proc/get_examine_lines(mob/living/carbon/human/occupant, mob/user)
	var/list/lines = list()
	switch(placement)
		if(GLORYHOLE_PLACEMENT_MOUTH)
			lines += pink_text("A pair of lips is pressed against the hole.", user)
		if(GLORYHOLE_PLACEMENT_COCK)
			var/cock = describe_part(occupant, /datum/mob_descriptor/penis, user)
			if(!cock)
				lines += pink_text("Something is pressed against the hole.", user)
			else
				lines += pink_text("Pressed through the hole is [cock].", user)
				var/balls = describe_part(occupant, /datum/mob_descriptor/testicles, user)
				if(balls)
					lines += pink_text("Hanging beneath it: [balls].", user)
		if(GLORYHOLE_PLACEMENT_ASS)
			lines += pink_text("A rear is pressed against the hole.", user)
			var/list/on_show = list()
			for(var/descriptor_type in list(/datum/mob_descriptor/vagina, /datum/mob_descriptor/penis))
				var/part = describe_part(occupant, descriptor_type, user)
				if(part)
					on_show += part
			if(length(on_show))
				lines += pink_text("Below it, [english_list(on_show)] can be seen, though not pressed against the hole.", user)
	if(occupant.chastity_device && placement != GLORYHOLE_PLACEMENT_MOUTH)
		lines += pink_text("[occupant.p_they(TRUE)] [occupant.p_are()] secured in [occupant.get_examine_item_name_with_hover(user, occupant.chastity_device)].", user)
		var/toy_line = occupant.human_chastity_toy_examine_line(user, occupant.p_their(), "[occupant.p_they(TRUE)] [occupant.p_have()]")
		if(toy_line)
			lines += toy_line
	return lines

/// A genital's examine description, coloured as the normal examine colours it, or null if it can't be described (e.g. hidden).
/obj/structure/bondage/gloryhole/proc/describe_part(mob/living/carbon/human/occupant, descriptor_type, mob/user)
	var/datum/mob_descriptor/descriptor = MOB_DESCRIPTOR(descriptor_type)
	if(!descriptor.can_describe(occupant) || !descriptor.can_user_see(occupant, user))
		return null
	var/text = descriptor.get_description_for_watcher(occupant, user)
	var/color = descriptor.get_descriptor_color(occupant, user)
	return color ? "<span style='color:[color]'>[text]</span>" : text

/// Colours a line in the genital descriptor pink, if the viewer has descriptor colours on
/obj/structure/bondage/gloryhole/proc/pink_text(text, mob/user)
	var/datum/preferences/prefs = user?.client?.prefs
	if(prefs && !prefs.descriptor_color)
		return span_info(text)
	return "<span style='color:#ff66cc'>[text]</span>"

// Only try_buckle_self() and try_buckle_other() put people in, after their own checks.
/obj/structure/bondage/gloryhole/buckle_mob(mob/living/M, force = FALSE, check_loc = TRUE)
	if(!force)
		return FALSE
	return ..()

// Nobody else can pull an occupant out (the front partner has "Unbuckle them" in the panel), and a restrained occupant has to struggle.
/obj/structure/bondage/gloryhole/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	if(user != buckled_mob)
		return
	if(occupant_restrained)
		toggle_struggle(buckled_mob)
		return
	return ..()

/obj/structure/bondage/gloryhole/post_buckle_mob(mob/living/M)
	. = ..()
	placement = GLORYHOLE_PLACEMENT_NEUTRAL
	struggling = FALSE
	apply_placement(M)
	refresh_name(M)
	M.update_vision_cone()
	if(ishuman(M))
		INVOKE_ASYNC(src, PROC_REF(open_menu), M)
	refresh_menus()

/obj/structure/bondage/gloryhole/post_unbuckle_mob(mob/living/M)
	. = ..()
	M.reset_offsets("bed_buckle")
	buckled_position = null
	placement = GLORYHOLE_PLACEMENT_NEUTRAL
	occupant_restrained = FALSE
	struggling = FALSE
	if(M.behind_gloryhole == src)
		release_hidden(M)
	refresh_name(M)
	M.update_vision_cone()
	refresh_menus(M)

/// Someone this user could strap in: held in an aggressive grab, or fireman-carried.
/obj/structure/bondage/gloryhole/proc/get_buckle_candidate(mob/living/carbon/human/user)
	RETURN_TYPE(/mob/living/carbon/human)
	for(var/mob/living/carbon/human/carried in user.buckled_mobs)
		return carried
	var/mob/living/carbon/human/held = user.pulling
	if(istype(held) && user.get_highest_grab_state_on(held) >= GRAB_AGGRESSIVE)
		return held
	return null

/// Steps in from behind (or from its own tile) and positions yourself in it.
/obj/structure/bondage/gloryhole/proc/try_buckle_self(mob/living/carbon/human/user)
	if(has_buckled_mobs() || get_role(user) != GLORYHOLE_ROLE_BEHIND || !(user.mobility_flags & MOBILITY_STAND))
		return
	if(!user.client?.prefs?.sexable)
		to_chat(user, span_warning("I don't want to use \the [src]. (Your ERP preference, in the options)"))
		return
	if(user.loc != loc && !user.Move(loc, get_dir(user, loc)))
		to_chat(user, span_warning("I can't get behind \the [src]."))
		return
	user.visible_message(span_notice("[user] starts positioning [user.p_them()]self into \the [src]..."), \
		span_notice("I start positioning myself into \the [src]..."))
	if(!do_after(user, strap_self_time, target = src))
		return
	if(has_buckled_mobs() || user.loc != loc)
		return
	occupant_restrained = FALSE
	buckle_mob(user, force = TRUE)

/// Straps in someone the user is grabbing or carrying. If they're chained, they're restrained for their whole stay.
/obj/structure/bondage/gloryhole/proc/try_buckle_other(mob/living/carbon/human/user)
	var/mob/living/carbon/human/victim = get_buckle_candidate(user)
	if(!victim || has_buckled_mobs() || get_role(user) != GLORYHOLE_ROLE_BEHIND)
		return
	if(!victim.client?.prefs?.sexable)
		to_chat(user, span_warning("[victim] doesn't want to be put in \the [src]. (Their ERP preference, in the options)"))
		return
	victim.visible_message(span_danger("[user] starts strapping [victim] into \the [src]!"), \
		span_userdanger("[user] starts strapping me into \the [src]!"))
	if(!do_after(user, strap_other_time, target = src))
		return
	if(has_buckled_mobs() || get_buckle_candidate(user) != victim || get_role(user) != GLORYHOLE_ROLE_BEHIND)
		return
	if(victim.buckled == user) // set down from a fireman carry
		user.unbuckle_mob(victim, TRUE)
	occupant_restrained = !!victim.handcuffed
	if(!buckle_mob(victim, force = TRUE, check_loc = FALSE))
		occupant_restrained = FALSE
		return
	log_combat(user, victim, "strapped into a gloryhole[occupant_restrained ? " while restrained" : ""]")

/// Whether the front partner may pull the occupant out: they're restrained, or not there to leave by themselves.
/obj/structure/bondage/gloryhole/proc/can_release(mob/living/carbon/human/occupant)
	return occupant_restrained || !occupant.client || occupant.stat != CONSCIOUS

/obj/structure/bondage/gloryhole/proc/try_release(mob/living/carbon/human/user)
	var/mob/living/carbon/human/occupant = get_occupant()
	if(!occupant || get_role(user) != GLORYHOLE_ROLE_FRONT || !can_release(occupant))
		return
	user.visible_message(span_notice("[user] starts freeing [occupant] from \the [src]..."), \
		span_notice("I start freeing [occupant] from \the [src]..."))
	if(!do_after(user, 3 SECONDS, target = src))
		return
	if(occupant != get_occupant() || get_role(user) != GLORYHOLE_ROLE_FRONT || !can_release(occupant))
		return
	user.visible_message(span_notice("[user] frees [occupant] from \the [src]."), \
		span_notice("I free [occupant] from \the [src]."))
	log_combat(user, occupant, "released from a gloryhole")
	unbuckle_mob(occupant, TRUE)

/// Starts or stops a restrained occupant's struggle to get free
/obj/structure/bondage/gloryhole/proc/toggle_struggle(mob/living/carbon/human/occupant)
	if(occupant != get_occupant() || !occupant_restrained)
		return
	if(struggling)
		struggling = FALSE // struggle_free()'s do_after sees this and stops
		return
	if(occupant.doing)
		to_chat(occupant, span_warning("I'm too busy to struggle."))
		return
	struggling = TRUE
	occupant.visible_message(span_warning("[occupant] starts struggling against \the [src]!"), \
		span_warning("I start struggling against \the [src]..."))
	refresh_menus()
	INVOKE_ASYNC(src, PROC_REF(struggle_free), occupant)

/obj/structure/bondage/gloryhole/proc/struggle_free(mob/living/carbon/human/occupant)
	var/freed = do_after(occupant, 10 SECONDS, needhand = FALSE, target = src, extra_checks = CALLBACK(src, PROC_REF(is_struggling), occupant))
	struggling = FALSE
	if(occupant != get_occupant())
		return
	if(!freed)
		to_chat(occupant, span_warning("I stop struggling."))
		refresh_menus()
		return
	occupant.visible_message(span_warning("[occupant] struggles free of \the [src]!"), \
		span_notice("I struggle free of \the [src]!"))
	unbuckle_mob(occupant, TRUE)

/obj/structure/bondage/gloryhole/proc/is_struggling(mob/living/carbon/human/occupant)
	return struggling && occupant == get_occupant()

/// Slides up to the hole from the front. Only one partner at a time.
/obj/structure/bondage/gloryhole/proc/step_up(mob/living/carbon/human/user)
	if(get_role(user) != GLORYHOLE_ROLE_FRONT || partner == user || !(user.mobility_flags & MOBILITY_STAND))
		return
	if(partner)
		to_chat(user, span_warning("Someone is already up against \the [src]."))
		return
	var/list/shift = get_step_up_offset()
	if(!shift)
		return
	user.setDir(turn(dir, 180)) // face the board, but don't lock it
	animate(user, pixel_x = shift[1], pixel_y = shift[2], time = 2.7)
	user.is_shifted = TRUE
	user.passthroughable |= (NORTH | EAST | SOUTH | WEST)
	partner = user
	user.stepped_up_gloryhole = src
	RegisterSignal(user, COMSIG_QDELETING, PROC_REF(on_tracked_mob_deleted), override = TRUE)
	// Facing north, the partner is the one behind the board. Their shift ending (moving, unshifting) releases them.
	if(dir == NORTH)
		hide_behind(user, shift[1], shift[2])
	// The occupant's menu turns to the new partner, unless they're busy
	var/mob/living/carbon/human/occupant = get_occupant()
	if(occupant?.sexcon && !occupant.sexcon.current_action && can_erp_with(occupant, user))
		occupant.sexcon.set_target(user)
	open_menu(user)
	refresh_menus()

/// Ends a partner's step-up. Called when their step-up slide ends (unpixel_shift()), or when the gloryhole goes.
/obj/structure/bondage/gloryhole/proc/release_partner(mob/living/carbon/human/M)
	if(partner != M)
		return
	partner = null
	M.stepped_up_gloryhole = null
	if(M.behind_gloryhole == src)
		release_hidden(M)
	else
		UnregisterSignal(M, COMSIG_QDELETING)
	if(M.sexcon?.gloryhole_panel == src)
		M.sexcon.gloryhole_panel = null
		if(M.sexcon.menu_open)
			M.sexcon.show_ui()
	refresh_menus()

/// What the occupant can press against the hole at all, depending on their anatomy
/obj/structure/bondage/gloryhole/proc/is_placement_offered(mob/living/carbon/human/occupant, which)
	if(which == GLORYHOLE_PLACEMENT_COCK)
		return !!occupant.getorganslot(ORGAN_SLOT_PENIS)
	return (which in GLOB.gloryhole_placement_parts)

/// Why the occupant can't use a placement right now, or null if they can
/obj/structure/bondage/gloryhole/proc/get_placement_block_reason(mob/living/carbon/human/occupant, which)
	switch(which)
		if(GLORYHOLE_PLACEMENT_NEUTRAL)
			return null
		if(GLORYHOLE_PLACEMENT_MOUTH)
			return occupant.get_bodypart(BODY_ZONE_HEAD) ? null : "The head isn't attached."
	// Everything else is at groin level
	if(occupant.get_taur_tail())
		return "The body is too long to reach the hole that way."
	if(which == GLORYHOLE_PLACEMENT_COCK)
		if(occupant.sexcon?.has_chastity_penis())
			return "It's locked in chastity."
	else
		var/vagina_free = occupant.getorganslot(ORGAN_SLOT_VAGINA) && !occupant.sexcon?.has_chastity_vagina()
		if(occupant.sexcon?.has_chastity_anal() && !vagina_free)
			return "Everything back there is locked in chastity."
	if(!get_location_accessible(occupant, BODY_ZONE_PRECISE_GROIN) && !occupant.sexcon?.bottom_exposed)
		return "Clothes are in the way."
	return null

/// Whether every occupant part a sex action uses is the one pressed against the hole
/obj/structure/bondage/gloryhole/proc/placement_allows(parts)
	if(!parts)
		return FALSE
	return !(parts & ~GLOB.gloryhole_placement_parts[placement])

/obj/structure/bondage/gloryhole/proc/get_placement_label(which)
	switch(which)
		if(GLORYHOLE_PLACEMENT_MOUTH)
			return "Mouth"
		if(GLORYHOLE_PLACEMENT_COCK)
			return "Cock"
		if(GLORYHOLE_PLACEMENT_ASS)
			return "Ass"
	return "Neutral"

/// The part pressed against the hole, as it reads in a sentence
/obj/structure/bondage/gloryhole/proc/get_placement_part_name(which)
	switch(which)
		if(GLORYHOLE_PLACEMENT_MOUTH)
			return "mouth"
		if(GLORYHOLE_PLACEMENT_COCK)
			return "cock"
		if(GLORYHOLE_PLACEMENT_ASS)
			return "rear"
	return "nothing"

/// Changes what the occupant presses against the hole. `by` is whoever chose it: the occupant, or the partner for a restrained occupant.
/// Returns TRUE if it changed.
/obj/structure/bondage/gloryhole/proc/set_placement(which, mob/living/carbon/human/by)
	var/mob/living/carbon/human/occupant = get_occupant()
	if(!occupant || which == placement || !is_placement_offered(occupant, which))
		return FALSE
	var/reason = get_placement_block_reason(occupant, which)
	if(reason)
		if(by)
			to_chat(by, span_warning(reason))
		return FALSE
	placement = which
	apply_placement(occupant)
	if(by)
		announce_placement(occupant, by)
	stop_unfitting_actions()
	refresh_menus()
	return TRUE

/// Drops the occupant back to neutral if what they're pressing against the hole stopped being possible, e.g. their clothes went back on
/obj/structure/bondage/gloryhole/proc/validate_placement()
	var/mob/living/carbon/human/occupant = get_occupant()
	if(!occupant || placement == GLORYHOLE_PLACEMENT_NEUTRAL || !get_placement_block_reason(occupant, placement))
		return
	to_chat(occupant, span_warning("I can't keep my [get_placement_part_name(placement)] pressed against \the [src]."))
	set_placement(GLORYHOLE_PLACEMENT_NEUTRAL)

/obj/structure/bondage/gloryhole/proc/announce_placement(mob/living/carbon/human/occupant, mob/living/carbon/human/by)
	var/range = by.sexcon?.do_subtle_action ? 1 : DEFAULT_MESSAGE_RANGE
	var/part = get_placement_part_name(placement)
	if(placement == GLORYHOLE_PLACEMENT_NEUTRAL)
		if(by == occupant)
			occupant.visible_message(span_love("[occupant] pulls back from \the [src]."), span_love("I pull back from \the [src]."), vision_distance = range)
		else
			by.visible_message(span_love("[by] makes [occupant] pull back from \the [src]."), span_love("I make [occupant] pull back from \the [src]."), vision_distance = range)
		return
	if(by == occupant)
		occupant.visible_message(span_love("[occupant] presses [occupant.p_their()] [part] against \the [src]."), \
			span_love("I press my [part] against \the [src]."), vision_distance = range)
	else
		by.visible_message(span_love("[by] makes [occupant] press [occupant.p_their()] [part] against \the [src]."), \
			span_love("I make [occupant] press [occupant.p_their()] [part] against \the [src]."), vision_distance = range)

/// Stops any running sex action near the board that the current placement no longer allows
/obj/structure/bondage/gloryhole/proc/stop_unfitting_actions()
	for(var/mob/living/carbon/human/nearby in range(1, src))
		var/datum/sex_controller/controller = nearby.sexcon
		if(controller?.current_action && !controller.can_perform_action(controller.current_action, nearby.incapacitated()))
			controller.try_stop_current_action()

/// Moves the occupant to match their placement: facing the hole for mouth and cock, facing away for ass, at the right height for their body.
/obj/structure/bondage/gloryhole/proc/apply_placement(mob/living/M)
	var/list/offset = get_placement_offset(M, placement)
	set_buckled_position(offset[1], offset[2], M)
	M.setDir(placement == GLORYHOLE_PLACEMENT_ASS ? turn(dir, 180) : dir)

/// How far to shift the occupant so the placed part lines up with the hole, as list(x, y)
/obj/structure/bondage/gloryhole/proc/get_placement_offset(mob/living/M, which)
	if(which == GLORYHOLE_PLACEMENT_NEUTRAL || !ishuman(M))
		return get_default_buckle_position()
	var/mob/living/carbon/human/H = M
	var/list/art = GLOB.gloryhole_art["[dir]"]
	var/hole_y = art ? art["hole_y"] : 11.5
	var/feature_y
	if(which == GLORYHOLE_PLACEMENT_MOUTH)
		feature_y = mouth_height + get_species_offset_y(H, OFFSET_FACE, OFFSET_FACE_F)
	else
		feature_y = groin_height + get_species_offset_y(H, OFFSET_UNDIES, OFFSET_UNDIES_F)
	// Sprite Scale scales up from the feet, so a point at height y ends up at y * scale
	var/scale = H.dna?.current_body_size || 1
	return list(0, round(hole_y - feature_y * scale, 1))

/// The vertical part of a species' sprite offset for a feature, picking the male or female entry as the body does
/obj/structure/bondage/gloryhole/proc/get_species_offset_y(mob/living/carbon/human/H, male_key, female_key)
	var/list/features = H.dna?.species?.offset_features
	if(!features)
		return 0
	var/list/feature = features[H.gender == MALE ? male_key : female_key]
	return feature ? feature[2] : 0

/// Moves the buckled mob to a position on the board. Placements go through this so the mask follows.
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
	RegisterSignal(M, COMSIG_QDELETING, PROC_REF(on_tracked_mob_deleted), override = TRUE)
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
	if(M != partner)
		UnregisterSignal(M, COMSIG_QDELETING)
	if(M.behind_gloryhole != src)
		return
	M.behind_gloryhole = null
	M.remove_filter("gloryhole_mask")
	M.layer = M.lying ? LYING_MOB_LAYER : initial(M.layer)
	M.update_vision_cone()

/obj/structure/bondage/gloryhole/proc/on_tracked_mob_deleted(mob/living/source)
	SIGNAL_HANDLER
	if(source == partner)
		release_partner(source)
	release_hidden(source)

/obj/structure/bondage/gloryhole/CanPass(atom/movable/mover, turf/target)
	if(has_buckled_mobs())
		return FALSE
	return get_dir(loc, mover) != dir

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
