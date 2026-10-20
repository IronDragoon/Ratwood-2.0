// Emergency response team types and the roles they can field.
// Every subtype of /datum/response_team_type shows up in the admin panel on its own, nothing else needs registering.
// Roles are ordinary advclasses, so stats, skills, traits and outfits work as they do for jobs.
//
// Adding a team:
//
// /datum/response_team_type/my_team
// 	name = "My Team"                    // shown in the admin panel and on the team's stones
// 	desc = "Who they are."              // panel tooltip
// 	affiliation = "the Somewhere"       // examines as "A <role examine_title> of the Somewhere."
// 	patron = /datum/patron/divine/noc   // or a list to roll from for each responder, like ALL_DIVINE_PATRONS
// 	roles = list(/datum/advclass/response_team/my_role)
//
// /datum/advclass/response_team/my_role
// 	name = "My Role"
// 	tutorial = "Shown to volunteers picking a role."
// 	examine_title = "guard"             // lowercase, defaults to "member"
// 	tabard_identifier = "My Role"       // jupon reads "<first name>, My Role", defaults to the role name
// 	tabard_color = CLOTHING_RED         // any hex colour, defaults to the team colour
// 	tabard_desc = "What it looks like." // optional, replaces the jupon's default description
// 	outfit = /datum/outfit/job/roguetown/response_team/my_role
//
// Every role is issued a jupon in the cloak slot, so outfits shouldn't set a cloak.

/datum/response_team_type
	var/name
	var/desc
	/// Who the team answers to, shown on examine as "A <role title> of <affiliation>."
	var/affiliation
	/// Colour of that examine line and of the team's stone messages
	var/team_color = "#d4af37"
	/// Advclass typepaths of the roles this team can field
	var/list/roles
	/// Patron typepath every responder is given, or a list of them to roll from for each responder. Null leaves the body's default.
	var/patron

/// Gives a new responder the team's patron, before their outfit so any miracles come from it
/datum/response_team_type/proc/apply_patron(mob/living/carbon/human/H)
	if(patron)
		H.set_patron(islist(patron) ? pick(patron) : patron)

/// The examine line for a member of this team in the given role
/datum/response_team_type/proc/examine_line(datum/advclass/response_team/role)
	return span_info("<font color='[team_color]'><b>\A [initial(role.examine_title)] of [affiliation].</b></font>")

/datum/response_team_type/kingsfield
	name = "Kingsfield Knights"
	desc = "Sworn swords of the Crown, sent from Kingsfield to restore order."
	affiliation = "Kingsfield"
	patron = ALL_DIVINE_PATRONS
	roles = list(
		/datum/advclass/response_team/kingsfield_knight,
		/datum/advclass/response_team/kingsfield_squire,
	)

/datum/response_team_type/holy_see
	name = "Holy See Crusaders"
	desc = "Faithful of the Holy See, dispatched to defend the Ten and their flock."
	affiliation = "the Holy See"
	patron = /datum/patron/divine/astrata
	roles = list(
		/datum/advclass/response_team/holy_see_paladin,
		/datum/advclass/response_team/holy_see_acolyte,
		/datum/advclass/response_team/holy_see_neophyte,
	)

/datum/advclass/response_team
	applies_post_equipment = FALSE
	/// What this role calls itself on examine, as in "A knight of Kingsfield."
	var/examine_title = "member"
	/// Follows the responder's first name on their jupon, as in "Aldous, Kingsfield Knight". Defaults to the role name.
	var/tabard_identifier
	/// Colour of this role's jupon. Defaults to the team colour.
	var/tabard_color
	/// Description of this role's jupon. Defaults to the jupon's own.
	var/tabard_desc

/// Responders are blank characters, so none of the player's own extras come with them
/datum/outfit/job/roguetown/response_team
	applies_player_extras = FALSE

/datum/outfit/job/roguetown/response_team/pre_equip(mob/living/carbon/human/H)
	..()
	H.adjust_blindness(-3)

// KINGSFIELD

/datum/advclass/response_team/kingsfield_knight
	name = "Kingsfield Knight"
	tutorial = "A knight of Kingsfield, answering the call of the Crown."
	examine_title = "knight"
	tabard_identifier = "Kingsfield Knight"
	tabard_color = CLOTHING_BLUE
	tabard_desc = "A jupon in the deep blue of Kingsfield, worn by the Crown's sworn knights."
	outfit = /datum/outfit/job/roguetown/response_team/kingsfield_knight
	traits_applied = list(TRAIT_HEAVYARMOR, TRAIT_STEELHEARTED)
	subclass_stats = list(
		STATKEY_STR = 2,
		STATKEY_CON = 3,
		STATKEY_WIL = 3,
		STATKEY_PER = 1,
	)
	subclass_skills = list(
		/datum/skill/combat/swords = SKILL_LEVEL_MASTER,
		/datum/skill/combat/shields = SKILL_LEVEL_EXPERT,
		/datum/skill/combat/maces = SKILL_LEVEL_EXPERT,
		/datum/skill/combat/wrestling = SKILL_LEVEL_EXPERT,
		/datum/skill/combat/unarmed = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/combat/knives = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/athletics = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/climbing = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/riding = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/reading = SKILL_LEVEL_APPRENTICE,
	)

/datum/outfit/job/roguetown/response_team/kingsfield_knight/pre_equip(mob/living/carbon/human/H)
	..()
	head = /obj/item/clothing/head/roguetown/helmet/heavy/knight
	neck = /obj/item/clothing/neck/roguetown/bevor
	armor = /obj/item/clothing/suit/roguetown/armor/plate/full
	shirt = /obj/item/clothing/suit/roguetown/armor/chainmail
	gloves = /obj/item/clothing/gloves/roguetown/plate
	wrists = /obj/item/clothing/wrists/roguetown/bracers
	pants = /obj/item/clothing/under/roguetown/chainlegs
	shoes = /obj/item/clothing/shoes/roguetown/boots/armor
	belt = /obj/item/storage/belt/rogue/leather/steel
	beltl = /obj/item/rogueweapon/scabbard/sword/noble
	l_hand = /obj/item/rogueweapon/sword/long
	backl = /obj/item/rogueweapon/shield/tower/metal
	backr = /obj/item/storage/backpack/rogue/satchel/black
	backpack_contents = list(
		/obj/item/rogueweapon/huntingknife/idagger/steel/special = 1,
		/obj/item/rogueweapon/scabbard/sheath/noble = 1,
		/obj/item/rope/chain = 1,
		/obj/item/reagent_containers/glass/bottle/rogue/healthpot = 1,
	)

/datum/advclass/response_team/kingsfield_squire
	name = "Kingsfield Squire"
	tutorial = "A squire of Kingsfield, following your knights into the fray."
	examine_title = "squire"
	tabard_identifier = "Kingsfield Squire"
	tabard_color = CLOTHING_AZURE
	tabard_desc = "A jupon in the lighter blue of Kingsfield, worn by squires in the knights' service."
	outfit = /datum/outfit/job/roguetown/response_team/kingsfield_squire
	traits_applied = list(TRAIT_MEDIUMARMOR, TRAIT_SQUIRE_REPAIR)
	subclass_stats = list(
		STATKEY_STR = 1,
		STATKEY_CON = 1,
		STATKEY_SPD = 1,
		STATKEY_PER = 1,
	)
	subclass_skills = list(
		/datum/skill/combat/swords = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/combat/maces = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/combat/shields = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/wrestling = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/unarmed = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/knives = SKILL_LEVEL_NOVICE,
		/datum/skill/craft/armorsmithing = SKILL_LEVEL_NOVICE,
		/datum/skill/craft/weaponsmithing = SKILL_LEVEL_NOVICE,
		/datum/skill/misc/athletics = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/climbing = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/reading = SKILL_LEVEL_NOVICE,
	)

/datum/outfit/job/roguetown/response_team/kingsfield_squire/pre_equip(mob/living/carbon/human/H)
	..()
	head = /obj/item/clothing/head/roguetown/helmet/kettle
	armor = /obj/item/clothing/suit/roguetown/armor/chainmail
	shirt = /obj/item/clothing/suit/roguetown/armor/gambeson
	gloves = /obj/item/clothing/gloves/roguetown/leather
	wrists = /obj/item/clothing/wrists/roguetown/bracers/leather
	pants = /obj/item/clothing/under/roguetown/chainlegs/iron
	shoes = /obj/item/clothing/shoes/roguetown/boots
	belt = /obj/item/storage/belt/rogue/leather
	beltr = /obj/item/rogueweapon/scabbard/sword
	r_hand = /obj/item/rogueweapon/sword/iron
	backl = /obj/item/rogueweapon/shield/wood
	backr = /obj/item/storage/backpack/rogue/satchel
	backpack_contents = list(
		/obj/item/rogueweapon/huntingknife/idagger = 1,
		/obj/item/rogueweapon/scabbard/sheath = 1,
		/obj/item/reagent_containers/glass/bottle/rogue/healthpot = 1,
		/obj/item/repair_kit/metal = 1,
		/obj/item/repair_kit = 1,
	)

// HOLY SEE

/datum/outfit/job/roguetown/response_team/holy_see
	/// Miracle tier granted on spawn, CLERIC_T0 for none
	var/cleric_tier = CLERIC_T0
	var/devotion_regen = CLERIC_REGEN_MINOR
	var/devotion_limit = CLERIC_REQ_1

/datum/outfit/job/roguetown/response_team/holy_see/pre_equip(mob/living/carbon/human/H)
	..()
	wrists = /obj/item/clothing/neck/roguetown/psicross/undivided
	if(cleric_tier)
		var/datum/devotion/C = new /datum/devotion(H, H.patron)
		C.grant_miracles(H, cleric_tier = cleric_tier, passive_gain = devotion_regen, devotion_limit = devotion_limit)

/datum/advclass/response_team/holy_see_paladin
	name = "Holy See Paladin"
	tutorial = "A paladin of the Holy See, the sword and shield of the faith."
	examine_title = "paladin"
	tabard_identifier = "Holy See Paladin"
	tabard_color = CLOTHING_YELLOW
	tabard_desc = "A jupon in Astrata's gold, worn by the paladins of the Holy See."
	outfit = /datum/outfit/job/roguetown/response_team/holy_see/paladin
	traits_applied = list(TRAIT_HEAVYARMOR, TRAIT_STEELHEARTED)
	subclass_stats = list(
		STATKEY_STR = 2,
		STATKEY_CON = 2,
		STATKEY_WIL = 3,
		STATKEY_PER = 1,
	)
	subclass_skills = list(
		/datum/skill/combat/swords = SKILL_LEVEL_EXPERT,
		/datum/skill/combat/maces = SKILL_LEVEL_EXPERT,
		/datum/skill/combat/shields = SKILL_LEVEL_EXPERT,
		/datum/skill/combat/wrestling = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/combat/unarmed = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/combat/knives = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/athletics = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/climbing = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/riding = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/reading = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/magic/holy = SKILL_LEVEL_JOURNEYMAN,
	)

/datum/outfit/job/roguetown/response_team/holy_see/paladin
	cleric_tier = CLERIC_T2
	devotion_limit = CLERIC_REQ_2

/datum/outfit/job/roguetown/response_team/holy_see/paladin/pre_equip(mob/living/carbon/human/H)
	..()
	head = /obj/item/clothing/head/roguetown/helmet/heavy/crusader
	neck = /obj/item/clothing/neck/roguetown/chaincoif/full
	armor = /obj/item/clothing/suit/roguetown/armor/plate/full/fluted
	shirt = /obj/item/clothing/suit/roguetown/armor/chainmail/hauberk
	gloves = /obj/item/clothing/gloves/roguetown/chain
	pants = /obj/item/clothing/under/roguetown/chainlegs
	shoes = /obj/item/clothing/shoes/roguetown/boots/armor
	belt = /obj/item/storage/belt/rogue/leather/plaquegold
	beltl = /obj/item/rogueweapon/scabbard/sword/noble
	l_hand = /obj/item/rogueweapon/sword/decorated
	backl = /obj/item/rogueweapon/shield/tower/metal
	backr = /obj/item/storage/backpack/rogue/satchel
	backpack_contents = list(
		/obj/item/flashlight/flare/torch/lantern = 1,
		/obj/item/reagent_containers/glass/bottle/alchemical/healthpotnew = 1,
	)

/datum/advclass/response_team/holy_see_acolyte
	name = "Holy See Acolyte"
	tutorial = "An acolyte of the Holy See, tending to the wounded and the faithful."
	examine_title = "acolyte"
	tabard_identifier = "Holy See Acolyte"
	tabard_color = CLOTHING_WHITE
	tabard_desc = "A plain white jupon, worn by the acolytes of the Holy See."
	outfit = /datum/outfit/job/roguetown/response_team/holy_see/acolyte
	subclass_stats = list(
		STATKEY_INT = 2,
		STATKEY_WIL = 2,
		STATKEY_SPD = 1,
	)
	subclass_skills = list(
		/datum/skill/combat/wrestling = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/combat/unarmed = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/combat/polearms = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/medicine = SKILL_LEVEL_EXPERT,
		/datum/skill/craft/alchemy = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/athletics = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/reading = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/magic/holy = SKILL_LEVEL_EXPERT,
	)

/datum/outfit/job/roguetown/response_team/holy_see/acolyte
	cleric_tier = CLERIC_T3
	devotion_regen = CLERIC_REGEN_MAJOR
	devotion_limit = CLERIC_REQ_3

/datum/outfit/job/roguetown/response_team/holy_see/acolyte/pre_equip(mob/living/carbon/human/H)
	..()
	head = /obj/item/clothing/head/roguetown/roguehood/astrata
	armor = /obj/item/clothing/suit/roguetown/shirt/robe/astrata
	shirt = /obj/item/clothing/suit/roguetown/shirt/undershirt/priest
	pants = /obj/item/clothing/under/roguetown/tights
	shoes = /obj/item/clothing/shoes/roguetown/sandals
	belt = /obj/item/storage/belt/rogue/leather/rope
	beltl = /obj/item/storage/belt/rogue/surgery_bag/full
	r_hand = /obj/item/rogueweapon/woodstaff/quarterstaff/steel
	backr = /obj/item/storage/backpack/rogue/satchel
	backpack_contents = list(
		/obj/item/book/rogue/bibble = 1,
		/obj/item/reagent_containers/glass/bottle/alchemical/healthpotnew = 2,
		/obj/item/reagent_containers/lux = 1,
	)

/datum/advclass/response_team/holy_see_neophyte
	name = "Holy See Neophyte"
	tutorial = "A neophyte of the Holy See, a holy warrior in training with much to prove."
	examine_title = "neophyte"
	tabard_identifier = "Holy See Neophyte"
	tabard_color = CLOTHING_ORANGE
	tabard_desc = "A jupon in a duller gold, worn by the neophytes of the Holy See."
	outfit = /datum/outfit/job/roguetown/response_team/holy_see/neophyte
	traits_applied = list(TRAIT_MEDIUMARMOR, TRAIT_SQUIRE_REPAIR)
	subclass_stats = list(
		STATKEY_CON = 2,
		STATKEY_STR = 1,
		STATKEY_WIL = 1,
	)
	subclass_skills = list(
		/datum/skill/combat/maces = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/combat/swords = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/combat/shields = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/wrestling = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/combat/unarmed = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/athletics = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/climbing = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/reading = SKILL_LEVEL_NOVICE,
		/datum/skill/magic/holy = SKILL_LEVEL_NOVICE,
	)

/datum/outfit/job/roguetown/response_team/holy_see/neophyte
	cleric_tier = CLERIC_T1

/datum/outfit/job/roguetown/response_team/holy_see/neophyte/pre_equip(mob/living/carbon/human/H)
	..()
	head = /obj/item/clothing/head/roguetown/helmet/leather/armorhood
	neck = /obj/item/clothing/neck/roguetown/chaincoif/iron
	armor = /obj/item/clothing/suit/roguetown/armor/chainmail/hauberk/iron
	shirt = /obj/item/clothing/suit/roguetown/armor/gambeson
	gloves = /obj/item/clothing/gloves/roguetown/chain/iron
	pants = /obj/item/clothing/under/roguetown/chainlegs/iron
	shoes = /obj/item/clothing/shoes/roguetown/boots/leather
	belt = /obj/item/storage/belt/rogue/leather
	beltr = /obj/item/rogueweapon/mace
	backl = /obj/item/rogueweapon/shield/wood
	backr = /obj/item/storage/backpack/rogue/satchel
	backpack_contents = list(
		/obj/item/reagent_containers/glass/bottle/rogue/healthpot = 1,
		/obj/item/repair_kit/metal = 1,
	)
