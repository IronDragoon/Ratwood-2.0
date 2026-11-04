/**
 * Lets a human NPC take follow / move / attack / idle orders from a master.
 *
 * The human NPC loop asks this component first each tick, see /mob/living/carbon/human/proc/process_ai().
 * Follow and move orders take the whole turn. Attack and idle orders hand the turn back to the normal AI.
 * Used by summoned skeletons (necromancer) and the Horde Alpha's deadites.
 */
/datum/component/commandable_minion
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Who gives the orders. Null for unowned minions, which still take admin orders.
	var/mob/living/master
	/// One of MINION_COMMAND_FOLLOW / MOVE / ATTACK / IDLE
	var/command_mode = MINION_COMMAND_IDLE
	/// Turf or mob, depending on the order
	var/atom/command_target
	/// What to fall back to once an attack order ends. MINION_COMMAND_FOLLOW follows the master.
	var/default_mode = MINION_COMMAND_IDLE
	/// While following, an aggressive minion engages hostiles this close. 0 never engages.
	var/engage_range = 0
	/// A fight picked up while following is dropped once the target is this far from the leader.
	var/leash_range = 8
	/// Throttles the engage scan while following
	var/next_engage_scan = 0

/datum/component/commandable_minion/Initialize(mob/living/master, default_mode = MINION_COMMAND_IDLE, engage_range = 0)
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	src.default_mode = default_mode
	src.engage_range = engage_range
	if(master)
		set_master(master)

/datum/component/commandable_minion/Destroy(force, silent)
	set_master(null)
	clear_command_target()
	return ..()

/datum/component/commandable_minion/proc/set_master(mob/living/new_master)
	if(new_master == master)
		return
	// The target's qdel signal is skipped while it is the master, so re-home it around the swap
	var/atom/kept_target = command_target
	clear_command_target()
	if(master)
		UnregisterSignal(master, COMSIG_PARENT_QDELETING)
	master = new_master
	if(master)
		RegisterSignal(master, COMSIG_PARENT_QDELETING, PROC_REF(on_master_qdel))
	command_target = kept_target
	if(ismob(command_target) && command_target != master)
		RegisterSignal(command_target, COMSIG_PARENT_QDELETING, PROC_REF(on_command_target_qdel))

/datum/component/commandable_minion/proc/on_master_qdel(datum/source)
	SIGNAL_HANDLER
	if(command_target == source) // following the master, which registers no target signal
		command_target = null
		command_mode = MINION_COMMAND_IDLE
	set_master(null)

/// Gives an order. Invalid targets for the order are ignored and the current order is kept.
/datum/component/commandable_minion/proc/set_command(command, atom/target)
	switch(command)
		if(MINION_COMMAND_FOLLOW)
			if(!ismob(target))
				return FALSE
		if(MINION_COMMAND_MOVE)
			if(!isturf(target))
				return FALSE
		if(MINION_COMMAND_ATTACK)
			if(!ismob(target))
				return FALSE
		if(MINION_COMMAND_IDLE)
			target = null
		else
			return FALSE
	clear_command_target()
	command_mode = command
	command_target = target
	// The master's own qdel handler already covers following the master
	if(ismob(command_target) && command_target != master)
		RegisterSignal(command_target, COMSIG_PARENT_QDELETING, PROC_REF(on_command_target_qdel))
	return TRUE

/datum/component/commandable_minion/proc/clear_command_target()
	if(ismob(command_target) && command_target != master)
		UnregisterSignal(command_target, COMSIG_PARENT_QDELETING)
	command_target = null

/datum/component/commandable_minion/proc/on_command_target_qdel(datum/source)
	SIGNAL_HANDLER
	clear_command_target()
	command_mode = MINION_COMMAND_IDLE

/// Ends an attack order, going back to the default order
/datum/component/commandable_minion/proc/return_to_default()
	if(default_mode == MINION_COMMAND_FOLLOW && master && !QDELETED(master))
		set_command(MINION_COMMAND_FOLLOW, master)
	else
		set_command(MINION_COMMAND_IDLE)

/datum/component/commandable_minion/proc/receive_command_text(msg)
	var/mob/living/carbon/human/minion = parent
	if(!minion.IsDeadOrIncap())
		minion.visible_message("<b>[minion]</b> [msg]")

/// Runs the current order. Returns TRUE when the order used the turn, FALSE to let the normal AI run.
/datum/component/commandable_minion/proc/process_command()
	var/mob/living/carbon/human/minion = parent
	switch(command_mode)
		if(MINION_COMMAND_FOLLOW)
			return process_follow(minion)
		if(MINION_COMMAND_MOVE)
			return process_move(minion)
		if(MINION_COMMAND_ATTACK)
			return process_attack(minion)
	return FALSE

/datum/component/commandable_minion/proc/process_follow(mob/living/carbon/human/minion)
	if(!command_target || !ismob(command_target))
		command_mode = MINION_COMMAND_IDLE
		walk(minion, 0)
		return TRUE

	if(try_engage(minion))
		return FALSE // the normal AI fights

	var/turf/target_turf = get_turf(command_target)
	if(!target_turf)
		command_mode = MINION_COMMAND_IDLE
		walk(minion, 0)
		return TRUE

	var/dist = get_dist(minion, command_target)

	// === Handle different z-levels ===
	if(target_turf.z != minion.z)
		var/target_z = target_turf.z

		var/obj/structure/stairs/the_stairs = locate() in get_turf(minion)
		if(the_stairs)
			var/move_dir = (target_z > minion.z) ? the_stairs.dir : GLOB.reverse_dir[the_stairs.dir]
			var/turf/next_step = the_stairs.get_target_loc(move_dir)
			if(next_step)
				minion.Move(next_step)
				return TRUE
			else
				step_to(minion, the_stairs)
				return TRUE

		if(HAS_TRAIT(minion, TRAIT_ZJUMP))
			if(minion.npc_try_jump_to(target_turf))
				return TRUE
			sleep(1 SECONDS)
			return TRUE

		for(var/obj/structure/stairs/S in view(5, minion))
			var/dir_to_stairs = get_dir(minion, S)
			if((target_z > minion.z && S.dir == dir_to_stairs) || (target_z < minion.z && GLOB.reverse_dir[S.dir] == dir_to_stairs))
				step_to(minion, S)
				return TRUE

		walk(minion, 0)
		return TRUE

	// === Same-z follow ===
	if(dist > 2)
		walk_to(minion, command_target, 0, 2)
	else
		walk(minion, 0)
	return TRUE

/// While following, an aggressive minion with an engage range fights hostiles near it. TRUE while fighting.
/datum/component/commandable_minion/proc/try_engage(mob/living/carbon/human/minion)
	if(!engage_range || !minion.aggressive)
		return FALSE
	if(minion.mode == NPC_AI_HUNT && minion.target)
		if(get_dist(minion.target, command_target) <= leash_range && minion.should_target(minion.target))
			return TRUE
		minion.back_to_idle()
	if(world.time < next_engage_scan)
		return FALSE
	next_engage_scan = world.time + 2 SECONDS
	for(var/mob/living/candidate in view(engage_range, minion))
		if(candidate == command_target || get_dist(candidate, command_target) > leash_range)
			continue
		if(minion.should_target(candidate))
			walk(minion, 0)
			minion.retaliate(candidate)
			return TRUE
	return FALSE

/datum/component/commandable_minion/proc/process_move(mob/living/carbon/human/minion)
	walk_to(minion, 0)
	if(!command_target)
		command_mode = MINION_COMMAND_IDLE
		minion.clear_path()
		minion.pathfinding_target = null
		return TRUE

	if(get_dist(minion, command_target) <= 1)
		command_mode = MINION_COMMAND_IDLE
		command_target = null
		minion.clear_path()
		minion.pathfinding_target = null
		return TRUE

	if(minion.pathfinding_target != command_target)
		minion.start_pathing_to(command_target)

	if(length(minion.myPath))
		minion.move_along_path()
	return TRUE

/datum/component/commandable_minion/proc/process_attack(mob/living/carbon/human/minion)
	walk_to(minion, 0)
	if(command_target && ismob(command_target))
		if(!minion.should_target(command_target))
			return_to_default()
			return TRUE
		minion.target = command_target
		return FALSE

	return_to_default()
	return TRUE

/// Every living commandable minion bound to master within range of center
/proc/get_commanded_minions(mob/living/master, range = 15, atom/center)
	var/list/minions = list()
	if(!master)
		return minions
	for(var/mob/living/carbon/human/minion in view(range, center || master))
		if(minion.stat == DEAD)
			continue
		var/datum/component/commandable_minion/orders = minion.GetComponent(/datum/component/commandable_minion)
		if(orders?.master == master)
			minions += orders
	return minions
