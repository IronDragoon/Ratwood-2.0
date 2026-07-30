//healer, apoth style approach but with some new psydon healing and obviously no pestran mentions
/datum/job/roguetown/sanant
	title = "Sanant"
	flag = SANANT
	department_flag = GARRISON
	faction = "Station"
	total_positions = 3
	spawn_positions = 3
	allowed_races = RACES_TOLERATED_UP
	allowed_sexes = list(MALE, FEMALE)
	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED)
	tutorial = "A Cataphract with expert training; \
	Born into petty nobility and raised as a squire from a young age, now you guard the royal family, answer to their commands, and act as a last beacon of chivalry in these dark times. \
	You're wholly dedicated to the standing Regent and their safety. Do not fail."
	display_order = JDO_KNIGHT
	whitelist_req = TRUE
	outfit = /datum/outfit/job/roguetown/cataphract
	advclass_cat_rolls = list(CTAG_CATAPHRACT = 20)
	job_traits = list(TRAIT_NOBLE, TRAIT_STEELHEARTED, TRAIT_GUARDSMAN)
	give_bank_account = 22
	noble_income = 10
	min_pq = 8
	max_pq = null
	round_contrib_points = 2
