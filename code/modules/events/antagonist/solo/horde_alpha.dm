/datum/round_event_control/antagonist/solo/horde_alpha
	name = "Horde Alpha"
	tags = list(
		TAG_COMBAT,
		TAG_HAUNTED,
		TAG_VILLIAN,
	)
	roundstart = TRUE
	antag_flag = ROLE_HORDE_ALPHA
	shared_occurence_type = SHARED_HIGH_THREAT

	base_antags = 1
	maximum_antags = 1

	weight = 0 // Only rolls through the Deadite Horde round modifier
	max_occurrences = 1

	earliest_start = 0 SECONDS

	typepath = /datum/round_event/antagonist/solo/horde_alpha
	antag_datum = /datum/antagonist/zombie/alpha

	restricted_roles = DEFAULT_ANTAG_BLACKLISTED_ROLES

/datum/round_event/antagonist/solo/horde_alpha

/// The chosen player leaves their job. They wake as the Alpha in a fresh body in the Terrorbog, and the old body is removed.
/datum/round_event/antagonist/solo/horde_alpha/add_datum_to_mind(datum/mind/antag_mind)
	var/mob/living/carbon/human/old_body = antag_mind.current
	var/turf/spawn_turf = find_horde_alpha_spawn()
	if(!spawn_turf)
		message_admins("Horde Alpha: no horde_alpha landmark or bog turf on this map, [key_name_admin(antag_mind)] was not made an Alpha.")
		log_game("Horde Alpha: no spawn turf found, [key_name(antag_mind)] was not made an Alpha.")
		antag_mind.special_role = null
		return

	var/mob/living/carbon/human/alpha = new(spawn_turf)
	alpha.set_species(pick(GLOB.deadite_species))
	alpha.gender = pick(MALE, FEMALE)
	alpha.dna.species.random_character(alpha)
	var/list/deadite_firstnames = world.file2list("strings/rt/names/other/deaditenpcfirst.txt")
	var/list/deadite_lastnames = world.file2list("strings/rt/names/other/deaditenpclast.txt")
	alpha.real_name = "[pick(deadite_firstnames)] [pick(deadite_lastnames)]"
	alpha.name = alpha.real_name
	alpha.dna.real_name = alpha.real_name
	alpha.update_body()

	if(old_body)
		var/datum/job/old_job = SSjob.GetJob(old_body.job)
		if(old_job)
			old_job.current_positions = max(old_job.current_positions - 1, 0)
	forget_old_life(antag_mind)
	antag_mind.transfer_to(alpha, TRUE)
	if(old_body)
		qdel(old_body)

	var/datum/antagonist/zombie/alpha/alpha_datum = new
	alpha_datum.fresh_body = TRUE
	antag_mind.add_antag_datum(alpha_datum)
	message_admins("Horde Alpha: [key_name_admin(antag_mind)] rose in [get_area_name(spawn_turf)].")

/// Strips everything the mind carried from the job it was pulled out of. Skills live on the body, so the fresh body already starts clean.
/datum/round_event/antagonist/solo/horde_alpha/proc/forget_old_life(datum/mind/antag_mind)
	antag_mind.assigned_role = "Deadite Alpha"
	antag_mind.job_bitflag = NONE
	antag_mind.cosmetic_class_title = null
	antag_mind.known_people = list()
	antag_mind.special_items = list()
	antag_mind.wipe_memory()
	if(antag_mind.current) // Reads the body's actions, so this runs before the mind moves
		antag_mind.RemoveAllSpells()
