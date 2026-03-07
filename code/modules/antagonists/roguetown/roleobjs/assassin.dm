/datum/antagonist/assassin
	name = "Assassin"
	roundend_category = "assassins"
	antagpanel_category = "Assassins"
	show_name_in_check_antagonists = FALSE

/datum/antagonist/assassin/get_antag_cap_weight()
	return 0.5

/datum/antagonist/assassin/on_gain()
	. = ..()
	if(owner)
		owner.special_role = "assassin"

/datum/antagonist/assassin/on_removal()
	. = ..()
	if(owner)
		owner.special_role = null
