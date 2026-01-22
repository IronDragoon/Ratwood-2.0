/*
These are martial spells for Psydonites. 'Greater miracles', which once relied on Psydon, now pulling from the user's own form.
These are all meant to be flagellant in nature.
Given the nature of Psydon, two of these are INTENDED to be refluffed Tennite spells. Although different in power / use.
*/
//Retribution. Spend blood to empower your strikes.
//It's just refluffed divine strike. But worse.
/obj/effect/proc_holder/spell/self/psydonic_retribution
	name = "Retribution"
	desc = "You siphon a portion of your blood, in exchange for empowering your next strike. \
	Those struck will find their actions tiring and cumbersome. \
	<small><span class='bloody'>A greater miracle.</span></small>"
	overlay_state = "psy_retrib"
	recharge_time = 1 MINUTES
	movement_interrupt = FALSE
	chargedrain = 0
	chargetime = 1 SECONDS
	charging_slowdown = 2
	chargedloop = null
	associated_skill = /datum/skill/magic/holy
	req_items = list(/obj/item/clothing/neck/roguetown/psicross)
	sound = 'sound/magic/bloodheal.ogg'
	invocations = list("*warcry")
	invocation_type = "shout"
	antimagic_allowed = TRUE
	miracle = TRUE
	devotion_cost = 30

/obj/effect/proc_holder/spell/self/psydonic_retribution/cast(mob/living/user)
	if(!isliving(user))
		return FALSE
	user.blood_volume = max(user.blood_volume-100, 0)
	user.handle_blood()
	new /obj/effect/decal/cleanable/blood/puddle(user.loc)
	user.apply_status_effect(/datum/status_effect/psydonic_retribution, user.get_active_held_item())
	return TRUE

/datum/status_effect/psydonic_retribution
	id = "psydonic_retribution"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 30 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/buff/psydonic_retribution
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/buffed_item

/atom/movable/screen/alert/status_effect/buff/psydonic_retribution
	name = "Retribution"
	desc = span_bloody("I stand ready! Fight me, fiends!")
	icon_state = "call_to_arms"

/datum/status_effect/psydonic_retribution/on_creation(mob/living/new_owner, obj/item/I)
	. = ..()
	if(!.)
		return
	if(istype(I) && !(I.item_flags & ABSTRACT))
		buffed_item = WEAKREF(I)
		if(!I.light_outer_range && I.light_system == STATIC_LIGHT)
			I.set_light(1, l_color =  "#9e1919")
		RegisterSignal(I, COMSIG_ITEM_AFTERATTACK, PROC_REF(item_afterattack))
	else
		RegisterSignal(owner, COMSIG_MOB_ATTACK_HAND, PROC_REF(hand_attack))

/datum/status_effect/psydonic_retribution/on_remove()
	. = ..()
	UnregisterSignal(owner, COMSIG_MOB_ATTACK_HAND)
	if(buffed_item)
		var/obj/item/I = buffed_item.resolve()
		if(istype(I))
			I.set_light(0)
		UnregisterSignal(I, COMSIG_ITEM_AFTERATTACK)

/datum/status_effect/psydonic_retribution/proc/item_afterattack(obj/item/source, atom/target, mob/user, proximity_flag, click_parameters)
	if(!proximity_flag)
		return
	if(!isliving(target))
		return
	var/mob/living/living_target = target
	living_target.apply_status_effect(/datum/status_effect/debuff/psydonic_retribution)
	living_target.visible_message(span_warning("The strike from [user]'s weapon coats [living_target] with shards of crimson!"), vision_distance = COMBAT_MESSAGE_RANGE)
	qdel(src)

/datum/status_effect/psydonic_retribution/proc/hand_attack(datum/source, mob/living/carbon/human/M, mob/living/carbon/human/H, datum/martial_art/attacker_style)
	if(!istype(M))
		return
	if(!istype(H))
		return
	if(!istype(M.used_intent, INTENT_HARM))
		return
	H.apply_status_effect(/datum/status_effect/debuff/psydonic_retribution)
	H.visible_message(span_warning("The strike from [M]'s fist sprays [H] with droplets of blood!"), vision_distance = COMBAT_MESSAGE_RANGE)
	qdel(src)

/datum/status_effect/debuff/psydonic_retribution
	id = "psydonic_retribution_debuff"
	alert_type = /atom/movable/screen/alert/status_effect/debuff/psydonic_retribution
	effectedstats = list(STATKEY_WIL = -3, STATKEY_CON = -1)
	duration = 30 SECONDS

/atom/movable/screen/alert/status_effect/debuff/psydonic_retribution
	name = "Retribution"
	desc = "Some matter of force attempts to stay my hand...\n"
	icon_state = "restrained"

//Inspire. Meant to rally, at the cost of yourself.
//Ravoxian CtA, with blood cost and weaker. Kind of. As above.
/obj/effect/proc_holder/spell/self/psydonic_inspire
	name = "Inspire"
	desc = "At the cost of your own lyfe giving blood, you can inspire your fellow Psydonites. \
	Such grants them constitution and willpower. \
	<small><span class='bloody'>A greater miracle.</span></small>"
	overlay_state = "psy_inspire"
	recharge_time = 4 MINUTES
	req_items = list(/obj/item/clothing/neck/roguetown/psicross)
	invocations = list("For the One!!")
	invocation_type = "shout"
	sound = 'sound/magic/holyshield.ogg'
	releasedrain = 30
	miracle = TRUE
	devotion_cost = 60

/obj/effect/proc_holder/spell/self/psydonic_inspire/cast(list/targets,mob/living/user = usr)
	user.blood_volume = max(user.blood_volume-200, 0)//It's a mass AoE for an already powerful faction.
	user.handle_blood()
	new /obj/effect/decal/cleanable/blood/puddle(user.loc)
	for(var/mob/living/carbon/target in view(6, get_turf(user)))
		if(!istype(target.patron, /datum/patron/old_god))
			to_chat(target, span_danger("A presence witnesses you. For a time, it weeps."))
			continue
		if(!user.faction_check_mob(target))
			continue
		if(target.mob_biotypes & MOB_UNDEAD)
			continue
		target.apply_status_effect(/datum/status_effect/buff/psydonic_inspire)
	return TRUE

/datum/status_effect/buff/psydonic_inspire
	id = "psydonic_inspire"
	alert_type = /atom/movable/screen/alert/status_effect/buff/psydonic_inspire
	duration = 2 MINUTES
	effectedstats = list(STATKEY_WIL = 2, STATKEY_CON = 2)

/atom/movable/screen/alert/status_effect/buff/psydonic_inspire
	name = "Inspired"
	desc = span_bloody("The One witnesses us! To arms!")
	icon_state = "call_to_arms"

//Sacrosanctity. Odd name, but you take damage in exchange to regain blood.
//Avoid bleedouts by breaking your limbs or something. I 'unno. Follows the flagellant theme.
/obj/effect/proc_holder/spell/self/psydonic_sacrosanctity
	name = "Sacrosanctity"
	desc = "In exchange for your flesh, you may replenish your lyfe giving blood. \
	<small><span class='bloody'>A greater miracle.</span></small>"
	overlay_state = "psy_sacro"
	recharge_time = 1 MINUTES
	movement_interrupt = FALSE
	chargedrain = 0
	chargetime = 1 SECONDS
	charging_slowdown = 2
	chargedloop = null
	associated_skill = /datum/skill/magic/holy
	req_items = list(/obj/item/clothing/neck/roguetown/psicross)
	sound = 'sound/magic/woundheal_crunch.ogg'
	invocations = list("*whimper")
	invocation_type = "shout"
	antimagic_allowed = TRUE
	miracle = TRUE
	devotion_cost = 80

/obj/effect/proc_holder/spell/self/psydonic_sacrosanctity/cast(mob/living/user)
	if(!isliving(user))
		return FALSE
	user.blood_volume = max(user.blood_volume+200, 0)
	user.handle_blood()
	user.apply_damage(200, BRUTE, spread_damage = TRUE)//Try to beat a bleedout? A point of damage for each point of blood.
	return TRUE

//Inviolability. A shield around the user, harming any undead who strike them.
/obj/effect/proc_holder/spell/self/psydonic_inviolability
	name = "Inviolability"
	desc = "In exchange for your flesh and lyfe giving blood, you are protected from Her puppets. \
	Any undead striking you are harmed in turn. \
	<small><span class='bloody'>A greater miracle.</span></small>"
	overlay_state = "psy_invio"
	recharge_time = 6 MINUTES
	movement_interrupt = FALSE
	chargedrain = 0
	chargetime = 1 SECONDS
	charging_slowdown = 2
	chargedloop = null
	associated_skill = /datum/skill/magic/holy
	req_items = list(/obj/item/clothing/neck/roguetown/psicross)
	sound = 'sound/magic/woundheal_crunch.ogg'
	invocations = list("*rage")
	invocation_type = "shout"
	antimagic_allowed = TRUE
	miracle = TRUE
	devotion_cost = 100

/obj/effect/proc_holder/spell/self/psydonic_inviolability/cast(mob/living/user)
	if(!isliving(user))
		return FALSE
	user.blood_volume = max(user.blood_volume-300, 0)//RAAAA!!!!
	user.handle_blood()
	new /obj/effect/decal/cleanable/blood/puddle(user.loc)
	user.apply_damage(300, BRUTE, spread_damage = TRUE)
	user.apply_status_effect(/datum/status_effect/buff/inviolability)
	return TRUE

#define INVIOLABILITY_FILTER "inviolability_glow"

/atom/movable/screen/alert/status_effect/buff/inviolability
	name = "Inviolability"
	desc = "<span class='bloody'>Her puppets have no hold over my form!</span>"
	icon_state = "necravow"

/datum/status_effect/buff/inviolability
	var/outline_colour ="#9e1919"
	id = "inviolability"
	alert_type = /atom/movable/screen/alert/status_effect/buff/inviolability
	effectedstats = list(STATKEY_CON = 2)
	duration = 3 MINUTES

/datum/status_effect/buff/inviolability/on_apply()
	. = ..()
	var/filter = owner.get_filter(INVIOLABILITY_FILTER)
	if (!filter)
		owner.add_filter(INVIOLABILITY_FILTER, 2, list("type" = "outline", "color" = outline_colour, "alpha" = 200, "size" = 1))

/datum/status_effect/buff/inviolability/on_remove()
	. = ..()
	owner.remove_filter(INVIOLABILITY_FILTER)
	to_chat(owner, span_warning("I feel so cold..."))

#undef INVIOLABILITY_FILTER
