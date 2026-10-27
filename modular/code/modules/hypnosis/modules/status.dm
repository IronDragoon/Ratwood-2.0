/datum/hypnosis_module/status
	id = "status"
	name = "Status"
	desc = "Your receptiveness to hypnosis."
	role = HYPNO_ROLE_RECEIVER

/datum/hypnosis_module/status/get_ui_data(mob/living/carbon/human/user, datum/hypnosis_panel/panel)
	return list("receptive" = user.is_hypno_receptive())
