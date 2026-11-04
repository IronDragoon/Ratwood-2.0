#define HORDE_ALPHA_STARTING_HORDE 6
#define HORDE_ALPHA_MAX_HORDE 15
#define HORDE_ALPHA_ROT_TARGET 5
/// How close, while following, a horde deadite picks fights when the horde is aggressive
#define HORDE_ENGAGE_RANGE 5

/// Living players who have turned into deadites this round, the Horde Alpha's objective counts these
GLOBAL_VAR_INIT(deadite_players_turned, 0)

/// Where the roundstart Horde Alpha wakes. Place deep in the Terrorbog.
/obj/effect/landmark/horde_alpha
	name = "Horde Alpha"

/**
 * A smarter, stronger deadite that leads a horde of NPC deadites.
 *
 * Keeps the deadite rules (z-cant, rot, silver weakness, infectious bite, spellblock) but can run,
 * use its hands properly and sees in colour. It can't be cured or revived. When it dies its horde goes wild.
 */
/datum/antagonist/zombie/alpha
	name = "Horde Alpha"
	roundend_category = "Horde Alpha"
	antagpanel_category = "Deadite"
	job_rank = ROLE_HORDE_ALPHA
	show_in_roundend = TRUE
	antag_flags = NONE
	// Same hud as deadites so the horde and the Alpha see each other, but the Alpha stands out
	antag_hud_name = "horde_alpha_hud"
	confess_lines = list(
		"THE HORDE HUNGERS!",
		"ALL FLESH ROTS IN THE END!",
		"WE ARE MANY!",
	)
	/// Set by the roundstart event when the Alpha wakes in a fresh body. That body gets gear and the name and body prompts.
	var/fresh_body = FALSE
	/// Whether the horde picks fights while following, see /datum/antagonist/zombie/alpha/proc/set_horde_aggressive()
	var/horde_aggressive = TRUE
	/// Weakrefs to the NPC deadites bound to this Alpha
	var/list/datum/weakref/horde = list()
	/// The body the horde answers to
	var/datum/weakref/alpha_body_ref
	/// Deadite traits the Alpha sheds
	var/static/list/traits_alpha_removed = list(
		TRAIT_NORUN,
		TRAIT_CHUNKYFINGERS,
	)
	/// Traits only the Alpha has
	var/static/list/traits_alpha = list(
		TRAIT_DNR,
	)
	var/static/list/alpha_spells = list(
		/obj/effect/proc_holder/spell/invoked/command_horde,
		/obj/effect/proc_holder/spell/self/horde_stance,
		/obj/effect/proc_holder/spell/invoked/rally_deadite,
	)

/datum/antagonist/zombie/alpha/on_gain(admin_granted = FALSE)
	// Snapshot only. The Alpha turns right away rather than on the deadite wake timer.
	. = ..(FALSE)
	if(QDELETED(src) || !ishuman(owner?.current))
		return
	var/mob/living/carbon/human/alpha = owner.current
	alpha.infected = FALSE
	transform_zombie()
	if(QDELETED(src) || !has_turned)
		return
	alpha_body_ref = WEAKREF(alpha)
	RegisterSignal(alpha, COMSIG_LIVING_DEATH, PROC_REF(on_alpha_death))
	RegisterSignal(alpha, COMSIG_PARENT_EXAMINE, PROC_REF(on_alpha_examine))
	forge_objectives()
	spawn_starting_horde()
	if(fresh_body)
		addtimer(CALLBACK(alpha, TYPE_PROC_REF(/mob/living/carbon/human, choose_name_popup), "HORDE ALPHA"), 3 SECONDS)
		addtimer(CALLBACK(alpha, TYPE_PROC_REF(/mob/living/carbon/human, choose_pronouns_and_body)), 7 SECONDS)
	greet()

/datum/antagonist/zombie/alpha/transform_zombie()
	..()
	var/mob/living/carbon/human/alpha = owner?.current
	if(QDELETED(src) || !has_turned || !ishuman(alpha))
		return
	for(var/trait in traits_alpha_removed)
		REMOVE_TRAIT(alpha, trait, "[type]")
	for(var/trait in traits_alpha)
		ADD_TRAIT(alpha, trait, "[type]")
	alpha.remove_client_colour(/datum/client_colour/monochrome)
	// Player deadites see in monochrome, so the Alpha's hud icon skips client colour to stand out
	var/image/hud_icon = alpha.hud_list?[ANTAG_HUD]
	if(hud_icon)
		hud_icon.appearance_flags |= NO_CLIENT_COLOR

	alpha.STASTR = 14
	alpha.STACON = 14
	alpha.STAWIL = 14
	alpha.STASPD = 10
	alpha.STAINT = 10

	alpha.adjust_skillrank_up_to(/datum/skill/combat/unarmed, SKILL_LEVEL_JOURNEYMAN, TRUE)
	alpha.adjust_skillrank_up_to(/datum/skill/combat/wrestling, SKILL_LEVEL_JOURNEYMAN, TRUE)
	alpha.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_APPRENTICE, TRUE)
	alpha.adjust_skillrank_up_to(/datum/skill/combat/axes, SKILL_LEVEL_APPRENTICE, TRUE)
	alpha.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_APPRENTICE, TRUE)

	if(fresh_body)
		alpha.equipOutfit(/datum/outfit/horde_alpha)

	for(var/spell_type in alpha_spells)
		owner.AddSpell(new spell_type)

/datum/antagonist/zombie/alpha/on_removal()
	release_horde()
	var/mob/living/carbon/human/alpha = alpha_body_ref?.resolve()
	if(alpha)
		UnregisterSignal(alpha, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_EXAMINE))
		for(var/trait in traits_alpha)
			REMOVE_TRAIT(alpha, trait, "[type]")
		// The hud image stays on the body, so later antag icons on it go back to normal
		var/image/hud_icon = alpha.hud_list?[ANTAG_HUD]
		if(hud_icon)
			hud_icon.appearance_flags &= ~NO_CLIENT_COLOR
	for(var/spell_type in alpha_spells)
		owner?.RemoveSpell(spell_type)
	return ..()

/datum/antagonist/zombie/alpha/Destroy()
	release_horde()
	return ..()

/datum/antagonist/zombie/alpha/greet()
	to_chat(owner.current, span_userdanger("I rise from the Terrorbog, and I remember. The others only hunger. I hunger, and I THINK."))
	to_chat(owner.current, span_danger("The dead around me heed my will. Lead them with Command Horde, set their temper with Horde Stance, and bind more of the wandering dead with Rally Deadite."))
	to_chat(owner.current, span_warning("I speak only the tongue of the dead, though I still understand the living. No cure will save me, and no god will raise me. When I fall, the horde scatters."))
	owner.announce_objectives()

/datum/antagonist/zombie/alpha/proc/forge_objectives()
	var/datum/objective/horde_rot/rot = new
	rot.owner = owner
	objectives += rot

/datum/antagonist/zombie/alpha/proc/on_alpha_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/alpha = source
	examine_list += span_danger("[alpha.p_their(TRUE)] eyes hold a terrible, hungry cunning.")

/datum/antagonist/zombie/alpha/proc/on_alpha_death(datum/source, gibbed)
	SIGNAL_HANDLER
	release_horde()

/// The living deadites bound to this Alpha, pruning the dead and the lost
/datum/antagonist/zombie/alpha/proc/get_horde()
	var/list/members = list()
	var/mob/living/carbon/human/alpha = alpha_body_ref?.resolve()
	for(var/datum/weakref/member_ref as anything in horde.Copy())
		var/mob/living/carbon/human/member = member_ref.resolve()
		var/datum/component/commandable_minion/orders = member?.GetComponent(/datum/component/commandable_minion)
		if(QDELETED(member) || member.stat == DEAD || !orders || orders.master != alpha)
			horde -= member_ref
			continue
		members += member
	return members

/datum/antagonist/zombie/alpha/proc/can_bind_more()
	return length(get_horde()) < HORDE_ALPHA_MAX_HORDE

/// Binds an NPC deadite to this Alpha. It follows the Alpha and takes the current stance.
/datum/antagonist/zombie/alpha/proc/bind_deadite(mob/living/carbon/human/deadite)
	var/mob/living/carbon/human/alpha = alpha_body_ref?.resolve()
	if(!alpha || !istype(deadite))
		return FALSE
	var/datum/component/commandable_minion/orders = deadite.AddComponent(/datum/component/commandable_minion, alpha, MINION_COMMAND_FOLLOW, HORDE_ENGAGE_RANGE)
	if(!orders)
		return FALSE
	orders.set_command(MINION_COMMAND_FOLLOW, alpha)
	deadite.faction |= list("undead", "zombie")
	deadite.del_on_deaggro = null
	deadite.aggressive = horde_aggressive
	horde += WEAKREF(deadite)
	return TRUE

/datum/antagonist/zombie/alpha/proc/spawn_starting_horde()
	var/mob/living/carbon/human/alpha = owner?.current
	var/turf/center = get_turf(alpha)
	if(!center)
		return
	var/list/turf/open_turfs = list()
	for(var/turf/open/candidate in range(2, center))
		if(candidate == center || candidate.is_blocked_turf(TRUE))
			continue
		open_turfs += candidate
	for(var/i in 1 to HORDE_ALPHA_STARTING_HORDE)
		var/turf/spawn_turf = length(open_turfs) ? pick_n_take(open_turfs) : center
		var/mob/living/carbon/human/species/npc/deadite/deadite = new(spawn_turf)
		bind_deadite(deadite)

/// Unbinds the whole horde. They go back to being wild deadites.
/datum/antagonist/zombie/alpha/proc/release_horde()
	for(var/mob/living/carbon/human/member as anything in get_horde())
		qdel(member.GetComponent(/datum/component/commandable_minion))
		member.aggressive = TRUE
		member.visible_message(span_warning("[member] lets out a confused moan and stops following anyone."))
	horde.Cut()

/// Aggressive: the horde attacks the living it meets while following. Passive: it fights only when ordered.
/datum/antagonist/zombie/alpha/proc/set_horde_aggressive(new_state)
	horde_aggressive = new_state
	for(var/mob/living/carbon/human/member as anything in get_horde())
		member.aggressive = horde_aggressive
		if(!horde_aggressive && member.mode == NPC_AI_HUNT)
			member.back_to_idle()

/// Returns the Horde Alpha datum of a mob or body, if it is one
/proc/get_horde_alpha_datum(mob/living/target)
	var/datum/antagonist/zombie/deadite = get_deadite_antag_for_body(target)
	if(istype(deadite, /datum/antagonist/zombie/alpha))
		return deadite
	return null

/// A turf for the roundstart Alpha, a horde_alpha landmark first, then any free turf in a bog
/proc/find_horde_alpha_spawn()
	var/list/turf/landmark_turfs = list()
	for(var/obj/effect/landmark/horde_alpha/landmark in GLOB.landmarks_list)
		var/turf/landmark_turf = get_turf(landmark)
		if(landmark_turf)
			landmark_turfs += landmark_turf
	if(length(landmark_turfs))
		return pick(landmark_turfs)

	var/list/turf/bog_turfs = list()
	for(var/area/bog_area as anything in get_horde_bog_areas())
		for(var/turf/open/candidate in bog_area)
			if(candidate.is_blocked_turf(TRUE) || istransparentturf(candidate))
				continue
			bog_turfs += candidate
	if(length(bog_turfs))
		return pick(bog_turfs)
	return null

/// Every Terrorbog area on the current map
/proc/get_horde_bog_areas()
	var/list/bog_areas = list()
	for(var/area/candidate as anything in GLOB.sortedAreas)
		if(istype(candidate, /area/rogue/outdoors/bog) || istype(candidate, /area/rogue/outdoors/bograt))
			bog_areas += candidate
	return bog_areas

/datum/outfit/horde_alpha
	name = "Horde Alpha"
	armor = /obj/item/clothing/suit/roguetown/shirt/rags
	shirt = /obj/item/clothing/suit/roguetown/armor/chainmail/ancient/decrepit
	pants = /obj/item/clothing/under/roguetown/tights/vagrant
	neck = /obj/item/clothing/neck/roguetown/chaincoif/ancient/decrepit

/datum/objective/horde_rot
	name = "Spread the rot"
	explanation_text = "Spread the rot. Turn living folk into deadites."
	target_amount = HORDE_ALPHA_ROT_TARGET
	/// How many players had turned when this objective was given
	var/turned_at_start = 0

/datum/objective/horde_rot/New(text, datum/mind/owner)
	turned_at_start = GLOB.deadite_players_turned
	. = ..()
	update_explanation_text()

/datum/objective/horde_rot/update_explanation_text()
	explanation_text = "Spread the rot. Turn [target_amount] living folk into deadites."

/datum/objective/horde_rot/check_completion()
	return (GLOB.deadite_players_turned - turned_at_start) >= target_amount

// ---------------------------------------------------------------------------
// Alpha abilities. All ignore the deadite spellblock.
// ---------------------------------------------------------------------------

/obj/effect/proc_holder/spell/invoked/command_horde
	name = "Command Horde"
	desc = "Cast on myself to have the horde follow me. Cast on the ground to send it there. Cast on a living creature to set the horde upon it. Cast on one of my deadites to make it hold its ground, or follow again."
	overlay_icon = 'icons/mob/actions/zizomiracles.dmi'
	action_icon = 'icons/mob/actions/zizomiracles.dmi'
	overlay_state = "ZIZO"
	range = 15
	chargedrain = 0
	chargetime = 0
	releasedrain = 0
	recharge_time = 3 SECONDS
	ignore_cockblock = TRUE
	antimagic_allowed = TRUE

/obj/effect/proc_holder/spell/invoked/command_horde/cast(list/targets, mob/living/user)
	var/atom/target = targets[1]
	if(!target || !user.mind?.has_antag_datum(/datum/antagonist/zombie/alpha))
		revert_cast()
		return FALSE

	var/list/horde_orders = get_commanded_minions(user, range)
	if(!length(horde_orders))
		to_chat(user, span_warning("None of my horde is near enough to heed me."))
		revert_cast()
		return FALSE

	if(target == user)
		for(var/datum/component/commandable_minion/orders as anything in horde_orders)
			orders.set_command(MINION_COMMAND_FOLLOW, user)
		to_chat(user, span_notice("My horde gathers behind me."))
		return TRUE

	if(isliving(target))
		var/mob/living/living_target = target
		var/datum/component/commandable_minion/target_orders = living_target.GetComponent(/datum/component/commandable_minion)
		if(target_orders?.master == user)
			if(target_orders.command_mode == MINION_COMMAND_IDLE)
				target_orders.set_command(MINION_COMMAND_FOLLOW, user)
				target_orders.receive_command_text("turns and shambles after [user].")
			else
				target_orders.set_command(MINION_COMMAND_IDLE)
				target_orders.receive_command_text("stops and stands its ground.")
			return TRUE
		if(living_target.stat != DEAD)
			for(var/datum/component/commandable_minion/orders as anything in horde_orders)
				var/mob/living/carbon/human/member = orders.parent
				member.add_enemy(living_target)
				orders.set_command(MINION_COMMAND_ATTACK, living_target)
			user.visible_message(span_danger("[user] points at [living_target], and the dead turn as one!"))
			return TRUE
		target = get_turf(living_target)

	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		revert_cast()
		return FALSE
	for(var/datum/component/commandable_minion/orders as anything in horde_orders)
		orders.set_command(MINION_COMMAND_MOVE, target_turf)
	to_chat(user, span_notice("My horde shambles toward where I point."))
	return TRUE

/obj/effect/proc_holder/spell/self/horde_stance
	name = "Horde Stance"
	desc = "Switch my horde between attacking any living thing it meets and fighting only when I order it to."
	overlay_icon = 'icons/mob/actions/zizomiracles.dmi'
	action_icon = 'icons/mob/actions/zizomiracles.dmi'
	overlay_state = "skeleton_formation"
	recharge_time = 2 SECONDS
	ignore_cockblock = TRUE
	antimagic_allowed = TRUE

/obj/effect/proc_holder/spell/self/horde_stance/cast(list/targets, mob/living/user)
	var/datum/antagonist/zombie/alpha/alpha_datum = user.mind?.has_antag_datum(/datum/antagonist/zombie/alpha)
	if(!alpha_datum)
		revert_cast()
		return FALSE
	alpha_datum.set_horde_aggressive(!alpha_datum.horde_aggressive)
	if(alpha_datum.horde_aggressive)
		to_chat(user, span_danger("My horde is AGGRESSIVE. It will fall upon the living it meets."))
	else
		to_chat(user, span_notice("My horde is PASSIVE. It will fight only when I command it."))
	return TRUE

/obj/effect/proc_holder/spell/invoked/rally_deadite
	name = "Rally Deadite"
	desc = "Bind a wandering deadite to my horde. It must be close."
	overlay_icon = 'icons/mob/actions/zizomiracles.dmi'
	action_icon = 'icons/mob/actions/zizomiracles.dmi'
	overlay_state = "deadite_tame"
	range = 4
	warnie = "sydwarning"
	chargedrain = 0
	chargetime = 5 SECONDS
	releasedrain = 0
	recharge_time = 30 SECONDS
	charging_slowdown = 1
	chargedloop = /datum/looping_sound/invokegen
	no_early_release = TRUE
	ignore_cockblock = TRUE
	antimagic_allowed = TRUE

/obj/effect/proc_holder/spell/invoked/rally_deadite/cast(list/targets, mob/living/user)
	var/datum/antagonist/zombie/alpha/alpha_datum = user.mind?.has_antag_datum(/datum/antagonist/zombie/alpha)
	if(!alpha_datum)
		revert_cast()
		return FALSE

	var/mob/living/carbon/human/species/npc/deadite/target = targets[1]
	if(!istype(target) || target.stat == DEAD)
		to_chat(user, span_warning("Only the wandering dead can join my horde."))
		revert_cast()
		return FALSE
	if(target.key || target.mind?.key)
		to_chat(user, span_warning("[target] has a will of its own."))
		revert_cast()
		return FALSE
	if(target.GetComponent(/datum/component/commandable_minion))
		to_chat(user, span_warning("[target] already follows another."))
		revert_cast()
		return FALSE
	if(!("undead" in target.faction) || !target.is_risen_deadite())
		to_chat(user, span_warning("[target] does not answer the call of the dead."))
		revert_cast()
		return FALSE
	if(!alpha_datum.can_bind_more())
		to_chat(user, span_warning("My horde is as large as I can hold."))
		revert_cast()
		return FALSE

	if(!alpha_datum.bind_deadite(target))
		revert_cast()
		return FALSE
	target.visible_message(span_danger("[target] turns its head toward [user] and shambles to [user.p_their()] side."))
	return TRUE

#undef HORDE_ALPHA_STARTING_HORDE
#undef HORDE_ALPHA_MAX_HORDE
#undef HORDE_ALPHA_ROT_TARGET
#undef HORDE_ENGAGE_RANGE
