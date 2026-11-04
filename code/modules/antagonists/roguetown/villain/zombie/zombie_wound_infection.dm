#define ZOMBIE_INFECTION_PROBABILITY 20 	/// Zombie infection probability for bites on a wound
#define ZOMBIE_INFECTION_TIME 2 MINUTES	/// Time taken until zombie infection kicks in (unit wakes up as a zombie)
#define HORDE_ALPHA_INFECTION_PROBABILITY 40	/// The Horde Alpha's bites and chews take hold more easily

/// Chance a bite or chew from this deadite infects. Null source gets the normal chance.
/proc/get_zombie_infection_chance(mob/living/carbon/human/source)
	if(source && get_horde_alpha_datum(source))
		return HORDE_ALPHA_INFECTION_PROBABILITY
	return ZOMBIE_INFECTION_PROBABILITY

/*
	ZOMBIFICATION
*/
/// Source is whoever inflicted the wound. Must be passed, not read off usr, this runs from bite
/// handlers and INVOKE_ASYNC where usr is unreliable and the deadite check would answer for the wrong mob
/datum/wound/proc/zombie_infect_attempt(mob/living/carbon/human/source)
	if (QDELETED(src) || QDELETED(owner) || QDELETED(bodypart_owner))
		return
	if(!ishuman(source) || !source.is_risen_deadite())
		return
	if (werewolf_infection_timer || !ishuman(owner)) // Already turning into something else
		return
	if(!prob(get_zombie_infection_chance(source)))	//Failed the probability of infection
		return

	var/mob/living/carbon/human/wound_owner = owner

	wound_owner.attempt_zombie_infection(source = source, infection_type = "wound", wake_delay = ZOMBIE_INFECTION_TIME) //Infect the unit

	severity = WOUND_SEVERITY_BIOHAZARD //Show the wound
	if (bodypart_owner)
		sortTim(bodypart_owner.wounds, GLOBAL_PROC_REF(cmp_wound_severity_dsc))
	return TRUE

#undef ZOMBIE_INFECTION_TIME
