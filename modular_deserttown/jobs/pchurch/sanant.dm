//healer, apoth style approach but with some new psydon healing and obviously no pestran mentions
/datum/job/roguetown/sanant
	title = "Sanant"
	flag = SANANT
	department_flag = BASILICA
	faction = "Station"
	total_positions = 6
	spawn_positions = 6

	allowed_races = ACCEPTED_RACES
	allowed_patrons = list(/datum/patron/old_god)
	allowed_sexes = list(MALE, FEMALE)
	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED)
	outfit = /datum/outfit/job/roguetown/cataphract
	tutorial = "A healer of the Basilica; \
	Test text please ignore"
	
	display_order = JDO_SANANT
	give_bank_account = TRUE
	min_pq = 5
	max_pq = null
	round_contrib_points = 5
	social_rank = SOCIAL_RANK_MINOR_NOBLE
	virtue_restrictions = list(/datum/virtue/utility/noble)
	job_traits = list(TRAIT_MEDICINE_EXPERT, TRAIT_ALCHEMY_EXPERT, TRAIT_NOSTINK, TRAIT_EMPATH)
		job_subclasses = list(
		/datum/advclass/sanant
	)

	/datum/outfit/job/roguetown/sanant
	name = "Sanant"
	jobtype = /datum/job/roguetown/sanant
	has_loadout = TRUE
	job_bitflag = BITFLAG_HOLY_WARRIOR

/datum/advclass/sanant
	name = "Sanant"
	tutorial = "You are an accomplished physician, trained and practiced in the art of medicine. You answer to the Head Physician, who enables your practice. Woe betide the one who suffers your scalpel."
	outfit = /datum/outfit/job/roguetown/sanant/basic
	category_tags = list(CTAG_APOTH)
	subclass_stats = list(
		STATKEY_INT = 3,
		STATKEY_PER = 2,
		STATKEY_SPD = 1,
	)
	subclass_skills = list(
		/datum/skill/combat/knives = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/polearms = SKILL_LEVEL_APPRENTICE, //enhances survival chances.
		/datum/skill/combat/wrestling = SKILL_LEVEL_NOVICE,
		/datum/skill/craft/crafting = SKILL_LEVEL_NOVICE,
		/datum/skill/misc/athletics = SKILL_LEVEL_NOVICE,
		/datum/skill/misc/reading = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/medicine = SKILL_LEVEL_MASTER,
		/datum/skill/craft/sewing = SKILL_LEVEL_APPRENTICE,
		/datum/skill/craft/alchemy = SKILL_LEVEL_EXPERT,
		/datum/skill/magic/holy = SKILL_LEVEL_JOURNEYMAN,
	)

/datum/outfit/job/roguetown/sanant/basic/pre_equip(mob/living/carbon/human/H)
	..()
	H.adjust_blindness(-3)
	head = /obj/item/clothing/head/roguetown/roguehood/black
	pants = /obj/item/clothing/under/roguetown/trou/apothecary
	shirt = /obj/item/clothing/suit/roguetown/shirt/apothshirt
	armor = /obj/item/clothing/suit/roguetown/shirt/robe/black
	belt = /obj/item/storage/belt/rogue/leather/rope
	neck = /obj/item/clothing/neck/roguetown/psicross/silver
	beltl = /obj/item/storage/belt/rogue/surgery_bag/full/physician
	beltr = /obj/item/roguekey/physician //Keys need sorting
	shoes = /obj/item/clothing/shoes/roguetown/boots/leather
	backr = /obj/item/storage/backpack/rogue/satchel
	backpack_contents = list(
		/obj/item/natural/worms/leech/cheele = 1,
		/obj/item/recipe_book/alchemy = 1,
		/obj/item/storage/keyring = 1,
		/obj/item/book/rogue/bibble/psy = 1,
	)
	if(H.mind)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/diagnose/secular)
