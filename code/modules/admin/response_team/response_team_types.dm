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
// Unless the team sets give_jupon = FALSE, every role is issued a jupon in the cloak slot, so outfits shouldn't set a cloak.
//
// A role can instead be built on an existing class, taking its outfit, stats, skills, traits and languages:
//
// /datum/advclass/response_team/my_inquisitor
// 	name = "My Inquisitor"
// 	based_on = /datum/advclass/puritan/arbiter
// 	traits_applied = list(TRAIT_INQUISITION) // added to the class's own, for traits its job gives rather than the class
//
// Borrowed outfits often hand out things only a local posting should have, like keys or money. List those in the
// team's withheld_items and they're taken away once the responder is equipped. Override after_equip() on the role
// for anything else the class's job would have given, like spells.
//
// Optional team extras:
// 	give_jupon = FALSE                                // responders keep their outfit's own cloak instead of a named jupon
// 	withheld_items = list(/obj/item/roguekey)          // item types (and subtypes) taken off responders after equipping
// 	faithful_patron = /datum/patron/old_god           // followers of this patron see faithful_examine on responders,
// 	faithful_examine = "One of ours, sent from afar." // in place of the Inquisition's own examine line

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
	/// Item types, subtypes included, taken off responders once equipped. For outfits borrowed from jobs that hand out local keys, comms, money or paperwork.
	var/list/withheld_items
	/// Followers of this patron see faithful_examine on the team's responders, in place of the Inquisition's examine line
	var/faithful_patron
	var/faithful_examine
	/// Whether responders are issued a named jupon in their role's colours. Without it they keep whatever cloak their outfit gives.
	var/give_jupon = TRUE

/// Gives a new responder the team's patron, before their outfit so any miracles come from it
/datum/response_team_type/proc/apply_patron(mob/living/carbon/human/H)
	if(patron)
		H.set_patron(islist(patron) ? pick(patron) : patron)

/// Takes away anything in withheld_items the responder's outfit gave them
/datum/response_team_type/proc/remove_withheld(mob/living/carbon/human/H)
	if(!length(withheld_items))
		return
	for(var/obj/item/I as anything in H.get_all_carried_items())
		if(!QDELETED(I) && is_type_in_list(I, withheld_items))
			qdel(I)

/// The examine line for a member of this team in the given role
/datum/response_team_type/proc/examine_line(datum/advclass/response_team/role)
	return span_info("<font color='[team_color]'><b>\A [initial(role.examine_title)] of [affiliation].</b></font>")

/// Whether this examiner follows the faith that knows this team on sight
/datum/response_team_type/proc/is_faithful(mob/living/examiner)
	return faithful_examine && istype(examiner) && istype(examiner.patron, faithful_patron)

/datum/response_team_type/proc/faithful_line()
	return span_info("<font color='[team_color]'><b>[faithful_examine]</b></font>")

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

/datum/response_team_type/ordo_otavanus
	name = "Ordo Otavanus"
	desc = "The Orthodoxy's own hunters, sent from Otava when the local Inquisition cannot be trusted to suffice."
	affiliation = "the Ordo Otavanus"
	team_color = "#c0c0c0"
	patron = /datum/patron/old_god
	give_jupon = FALSE
	faithful_patron = /datum/patron/old_god
	faithful_examine = "A Member of the Orthodoxy's Ordo Otavanus! It must be something serious..."
	// The Inquisition's outfits are built for the local sect. The signet ring is its comms, and its slot is needed for the team's stone.
	withheld_items = list(
		/obj/item/roguekey,
		/obj/item/storage/keyring,
		/obj/item/storage/belt/rogue/pouch/coins,
		/obj/item/paper/inqslip,
		/obj/item/clothing/ring/signet/silver/inqscomm,
	)
	roles = list(
		/datum/advclass/response_team/ordo/arbiter,
		/datum/advclass/response_team/ordo/inspector,
		/datum/advclass/response_team/ordo/ordinator,
		/datum/advclass/response_team/ordo/orthodoxist/adjudicator,
		/datum/advclass/response_team/ordo/orthodoxist/arbalist,
		/datum/advclass/response_team/ordo/orthodoxist/confessor,
		/datum/advclass/response_team/ordo/orthodoxist/disciple,
		/datum/advclass/response_team/ordo/orthodoxist/psyaltrist,
		/datum/advclass/response_team/ordo/orthodoxist/sojourner,
		/datum/advclass/response_team/ordo/absolver,
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
	/// An existing advclass this role is built on. Its outfit, stats, skills, languages and music are used unless the role sets its own,
	/// and its traits are added to the role's. Its tutorial is used if the role doesn't give one.
	var/based_on

/datum/advclass/response_team/New()
	. = ..()
	if(!based_on)
		return
	var/datum/advclass/base = new based_on
	if(tutorial == initial(tutorial))
		tutorial = base.tutorial
	for(var/var_name in list("outfit", "subclass_stats", "subclass_skills", "subclass_languages", "subclass_virtues", "subclass_social_rank", "cmode_music"))
		if(isnull(vars[var_name]))
			vars[var_name] = base.vars[var_name]
	if(!subclass_spellpoints)
		subclass_spellpoints = base.subclass_spellpoints
	traits_applied = base.traits_applied | traits_applied
	// Responders answer to their team, not the local sect, so they don't lead it or spend its marques
	traits_applied -= TRAIT_PURITAN
	qdel(base)

/// Equips a responder as a blank character, with nothing from the player's own character.
/// Unlike equipme() this waits for any choices the outfit asks for, loadout included, so the kit is complete when it returns.
/datum/advclass/response_team/proc/equip_responder(mob/living/carbon/human/H)
	var/datum/outfit/job/roguetown/kit = new outfit
	kit.applies_player_extras = FALSE
	// They're already in the body, so the loadout can be asked for now rather than after the usual delay
	kit.loadout_now = TRUE
	H.equipOutfit(kit)
	if(QDELETED(H))
		return
	H.advjob = name
	if(cmode_music)
		H.cmode_music = cmode_music
	for(var/trait in traits_applied)
		if(!(trait in H.dna.species.banned_traits))
			ADD_TRAIT(H, trait, ADVENTURER_TRAIT)
	if(HAS_TRAIT(H, TRAIT_MEDIUMARMOR) || HAS_TRAIT(H, TRAIT_HEAVYARMOR))
		H.def_intent_change(INTENT_PARRY)
	for(var/language in subclass_languages)
		H.grant_language(language)
	for(var/stat in subclass_stats)
		H.change_stat(stat, subclass_stats[stat])
	for(var/skill in subclass_skills)
		H.adjust_skillrank_up_to(skill, subclass_skills[skill], TRUE)
	if(subclass_spellpoints > 0)
		H.mind?.adjust_spellpoints(subclass_spellpoints)
	if(subclass_social_rank)
		H.social_rank = subclass_social_rank
	for(var/virtue in subclass_virtues)
		apply_virtue(H, new virtue)
	after_equip(H)

/// For anything else the role needs once equipped, like spells a borrowed class's job would have given
/datum/advclass/response_team/proc/after_equip(mob/living/carbon/human/H)
	return

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

// ORDO OTAVANUS
// Built on the Inquisition's own classes, so they stay in step with them.

/datum/advclass/response_team/ordo

/datum/advclass/response_team/ordo/arbiter
	name = "Ordo Arbiter"
	examine_title = "arbiter"
	based_on = /datum/advclass/puritan/arbiter

/datum/advclass/response_team/ordo/inspector
	name = "Ordo Inspector"
	examine_title = "inspector"
	based_on = /datum/advclass/puritan/inspector

/datum/advclass/response_team/ordo/ordinator
	name = "Ordo Ordinator"
	examine_title = "ordinator"
	based_on = /datum/advclass/puritan/ordinator

/// The Orthodoxist job gives these to all its classes, rather than the classes themselves
/datum/advclass/response_team/ordo/orthodoxist
	traits_applied = list(TRAIT_OUTLANDER, TRAIT_STEELHEARTED, TRAIT_INQUISITION)

/datum/advclass/response_team/ordo/orthodoxist/adjudicator
	name = "Ordo Adjudicator"
	examine_title = "adjudicator"
	based_on = /datum/advclass/psydoniantemplar

/datum/advclass/response_team/ordo/orthodoxist/arbalist
	name = "Ordo Arbalist"
	examine_title = "arbalist"
	based_on = /datum/advclass/arbalist

/datum/advclass/response_team/ordo/orthodoxist/confessor
	name = "Ordo Confessor"
	examine_title = "confessor"
	based_on = /datum/advclass/confessor

/datum/advclass/response_team/ordo/orthodoxist/disciple
	name = "Ordo Disciple"
	examine_title = "disciple"
	based_on = /datum/advclass/disciple

/datum/advclass/response_team/ordo/orthodoxist/psyaltrist
	name = "Ordo Psyaltrist"
	examine_title = "psyaltrist"
	based_on = /datum/advclass/psyaltrist

/datum/advclass/response_team/ordo/orthodoxist/sojourner
	name = "Ordo Sojourner"
	examine_title = "sojourner"
	based_on = /datum/advclass/sojourner

/datum/advclass/response_team/ordo/absolver
	name = "Ordo Absolver"
	examine_title = "absolver"
	based_on = /datum/advclass/absolver
	// The Absolver job gives these rather than its class
	traits_applied = list(
		TRAIT_NOPAINSTUN,
		TRAIT_PACIFISM,
		TRAIT_LUX_FREAK,
		TRAIT_EMPATH,
		TRAIT_CRITICAL_RESISTANCE,
		TRAIT_BLOOD_RESISTANCE,
		TRAIT_SILVER_BLESSED,
		TRAIT_STEELHEARTED,
		TRAIT_INQUISITION,
		TRAIT_RITUALIST,
		TRAIT_SELF_AWARE,
	)

/// The Absolver job grants these on spawn rather than its class
/datum/advclass/response_team/ordo/absolver/after_equip(mob/living/carbon/human/H)
	if(!H.mind)
		return
	H.mind.AddSpell(new /obj/effect/proc_holder/spell/self/psydonpersist)
	H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/psydonlux_tamper)
	H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/psydonabsolve)
	H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/diagnose/secular)
	H.mind.teach_crafting_recipe(/datum/crafting_recipe/roguetown/alchemy/qsabsolution)
