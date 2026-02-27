/datum/sprite_accessory/chastity_wear
	abstract_type = /datum/sprite_accessory/chastity_wear
	icon = 'icons/roguetown/items/cages.dmi'
	color_key_name = "chastity_wear"
	var/chastity_wear_type
	var/hides_breasts = FALSE //Whether this chastity item covers breasts or not
	var/covers_rear = TRUE //Whether the item reveals the genitals of the wearer or not

/datum/sprite_accessory/chastity_wear/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	generic_gender_feature_adjust(appearance_list, organ, bodypart, owner, OFFSET_UNDIES, OFFSET_UNDIES_F)

/datum/sprite_accessory/chastity_wear/is_visible(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	if(hides_breasts)
		if(is_human_part_visible(owner, HIDECROTCH) || is_human_part_visible(owner, HIDEBOOB))
			return TRUE	
	return is_human_part_visible(owner, HIDECROTCH)

/datum/sprite_accessory/chastity_wear/cage_standard
	name = "cage_standard"
	icon_state = "cage_standard_h_m"
	chastity_wear_type = /obj/item/chastity

/datum/sprite_accessory/chastity_wear/cage_standard/get_icon_state(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)

	if(owner.gender == FEMALE && is_species(owner,/datum/species/human))
		return "cage_standard_h_f"
	if(owner.gender == MALE && is_species(owner,/datum/species/dwarf))
		return "cage_standard_d_m"
	if(owner.gender == FEMALE && is_species(owner,/datum/species/dwarf))
		return "cage_standard_d_f"
	if(is_species(owner,/datum/species/elf))
		return "cage_standard_e_m"
	return "cage_standard_h_m"
