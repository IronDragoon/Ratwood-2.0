/datum/job/roguetown/assassin
	title = "Assassin"
	flag = ASSASSIN
	department_flag = WANDERERS
	faction = "Station"
	total_positions = 4
	spawn_positions = 1
	allowed_races = RACES_ALL_KINDS
	tutorial = "You are a chosen assassin of Graggar, sent to the Vale to seek targets in His name and sacrifice them for glory! Strike fast and strike from the shadows, fulfil his will!"
	outfit = null
	outfit_female = null
	display_order = JDO_ASSASSIN
	show_in_credits = FALSE
	min_pq = 40		//This is a class that lets you effectively no-esc someone. So.. responsibility.
	max_pq = null

	obsfuscated_job = TRUE

	advclass_cat_rolls = list(CTAG_ASSASSIN = 20)
	PQ_boost_divider = 10
	round_contrib_points = 2
	
	announce_latejoin = FALSE
	wanderer_examine = TRUE
	advjob_examine = FALSE	//We don't want anyone knowing what type of assassin you are.
	always_show_on_latechoices = TRUE
	job_reopens_slots_on_death = FALSE
	same_job_respawn_delay = 1 MINUTES
	virtue_restrictions = list(/datum/virtue/heretic/zchurch_keyholder) //all assassin classes automatically get this

	// Base job traits, we give one-specialty trait per role.
	job_traits = list(
		TRAIT_ASSASSIN,
		TRAIT_STEELHEARTED,
		TRAIT_HERESIARCH,
		TRAIT_ZURCH,	//Just so they can use the Zurch.
		TRAIT_ANTISCRYING,
		TRAIT_SELF_SUSTENANCE,
		TRAIT_OUTLAW,
	)
	cmode_music = 'sound/music/cmode/antag/combat_assassin.ogg'
	// Choices between: Ranged build, poison knife-fighter w/ poison knife, garrote user/kidnapper build
	job_subclasses = list(
		/datum/advclass/assassin/ranger,
		/datum/advclass/assassin/poisoner,
		/datum/advclass/assassin/hitman,
	)

/datum/job/roguetown/assassin/after_spawn(mob/living/L, mob/M, latejoin = TRUE)
	..()
	if(L)
		var/mob/living/carbon/human/H = L
		// Assign assassin antagonist datum so assassins appear in antag list
		if(H.mind && !H.mind.has_antag_datum(/datum/antagonist/assassin))
			var/datum/antagonist/new_antag = new /datum/antagonist/assassin()
			H.mind.add_antag_datum(new_antag)
			
// Verb for the assassin to remember their targets.
/mob/living/carbon/human/proc/who_targets() 
	set name = "Remember Targets"
	set category = "Graggar"
	if(!mind)
		return
	mind.recall_targets(src)

/datum/antagonist/assassin/on_life(mob/user)
	if(!user)
		return
	var/mob/living/carbon/human/H = user
	H.verbs |= /mob/living/carbon/human/proc/who_targets
	
// Proc for assassins to be given a bounty
// I have decided to enforce them to recieve a 'max' bounty with no player choice. They are an assassin, and explicitly aiming to kill a target or targets
// This could be replaced in future with the ability to change to a lower bounty if this seems more suitable.
/proc/assassin_add_bounty(mob/living/carbon/human/H)
	var/bounty_poster = "The Justiciary of The Vale"
	var/race = H.dna.species
	var/gender = H.gender
	var/list/d_list = H.get_mob_descriptors()
	var/descriptor_height = build_coalesce_description_nofluff(d_list, H, list(MOB_DESCRIPTOR_SLOT_HEIGHT), "%DESC1%")
	var/descriptor_body = build_coalesce_description_nofluff(d_list, H, list(MOB_DESCRIPTOR_SLOT_BODY), "%DESC1%")
	var/descriptor_voice = build_coalesce_description_nofluff(d_list, H, list(MOB_DESCRIPTOR_SLOT_VOICE), "%DESC1%")
	var/bounty_total = rand(300, 500)
	GLOB.outlawed_players += H.real_name
	var/my_crime = "is a known Assassin of the Gragarrite Cult."

	add_bounty(H.real_name, race, gender, descriptor_height, descriptor_body, descriptor_voice, bounty_total, FALSE, my_crime, bounty_poster)
	to_chat(H, span_danger("You are playing an Antagonist role. By choosing to spawn as an Assassin, you are expected to actively create conflict with other players. Failing to play this role with the appropriate gravitas may result in punishment for Low Roleplay standards."))

/proc/update_assassin_slots()
	var/datum/job/assassin_job = SSjob.GetJob("Assassin")
	if(!assassin_job)
		return

	var/player_count = length(GLOB.joined_player_list)
	var/slots = 1

	//Add 1 slot for every 20 players over 75. Less than 75 players, 2 slots. 95 or more players, 3 slots. 115 or more players, 4 slots - etc.
	if(player_count > 75)
		var/extra = floor((player_count - 75) / 20)
		slots += extra

	//1 slot minimum, 4 maximum.
	slots = min(slots, 4)

	assassin_job.total_positions = slots
	assassin_job.spawn_positions = slots

