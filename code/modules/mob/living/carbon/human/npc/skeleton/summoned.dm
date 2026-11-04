/mob/living/carbon/human/species/skeleton/npc/summoned
	var/mob/living/caster // The summoner who owns this NPC
	var/list/friendly_factions = list() // factions to not target
	skel_outfit = /datum/outfit/job/roguetown/npc/skeleton/npc/summoned


/datum/outfit/job/roguetown/npc/skeleton/npc/summoned/pre_equip(mob/living/carbon/human/H)
	.=..()
	H.STASTR = 14
	H.STASPD = 8
	H.STACON = 6 // Slightly tougher now!
	H.STAWIL = 15
	H.STAINT = 1
	name = "Skeleton Soldier"
	cloak = /obj/item/clothing/cloak/stabard/surcoat/guard // Ooo Spooky Old Dead MAA
	head = /obj/item/clothing/head/roguetown/helmet/heavy/ancient/decrepit
	mask = /obj/item/clothing/mask/rogue/facemask/ancient/decrepit
	armor = /obj/item/clothing/suit/roguetown/armor/plate/half/ancient/decrepit
	shirt = /obj/item/clothing/suit/roguetown/armor/chainmail/ancient/decrepit
	wrists = /obj/item/clothing/wrists/roguetown/bracers/ancient/decrepit
	pants = /obj/item/clothing/under/roguetown/chainlegs/kilt/ancient/decrepit
	shoes = /obj/item/clothing/shoes/roguetown/boots/armor/ancient/decrepit
	neck = /obj/item/clothing/neck/roguetown/chaincoif/ancient/decrepit
	gloves = /obj/item/clothing/gloves/roguetown/chain/ancient/decrepit
	if(prob(33))
		l_hand = /obj/item/rogueweapon/spear/ancient/decrepit
	else if(prob(33))
		l_hand = /obj/item/rogueweapon/flail/sflail/ancient/decrepit
		r_hand = /obj/item/rogueweapon/shield/tower/metal/ancient/decrepit
	else
		l_hand = /obj/item/rogueweapon/sword/short/gladius/ancient/decrepit // ave
		r_hand = /obj/item/rogueweapon/shield/tower/metal/ancient/decrepit


	H.adjust_skillrank(/datum/skill/combat/polearms, 3, TRUE)
	H.adjust_skillrank(/datum/skill/combat/maces, 3, TRUE)
	H.adjust_skillrank(/datum/skill/combat/axes, 3, TRUE)
	H.adjust_skillrank(/datum/skill/combat/swords, 3, TRUE)
	H.adjust_skillrank(/datum/skill/combat/knives, 3, TRUE)
	H.adjust_skillrank(/datum/skill/combat/shields, 3, TRUE)
	H.adjust_skillrank(/datum/skill/combat/unarmed, 3, TRUE)
	H.adjust_skillrank(/datum/skill/combat/wrestling, 3, TRUE)
	H.adjust_skillrank(/datum/skill/misc/swimming, 3, TRUE)
	H.adjust_skillrank(/datum/skill/misc/climbing, 3, TRUE)

/mob/living/carbon/human/species/skeleton/npc/summoned/should_target(atom/target)
	if(ismob(target))
		var/mob/living/L = target
		if(L == caster)
			return FALSE
		if(L.faction && (L.faction in faction))
			return FALSE
	return ..() // fall back to normal targeting

/mob/living/carbon/human/species/skeleton/npc/summoned/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/commandable_minion)

/// Binds this skeleton to its summoner, who can then command it
/mob/living/carbon/human/species/skeleton/npc/summoned/proc/bind_to_caster(mob/living/new_caster)
	caster = new_caster
	var/datum/component/commandable_minion/orders = GetComponent(/datum/component/commandable_minion)
	orders?.set_master(new_caster)
	return orders
