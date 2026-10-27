/datum/hypnosis_module/received
	id = "received"
	name = "Received"
	desc = "Hypnotic messages you've received this round."
	role = HYPNO_ROLE_RECEIVER

/datum/hypnosis_module/received/get_ui_data(mob/living/carbon/human/user, datum/hypnosis_panel/panel)
	return list("log" = panel.received_log)

/datum/hypnosis_module/received/execute(mob/living/carbon/human/user, datum/hypnosis_panel/panel, op, list/params)
	if(op == "clear")
		panel.clear_log()
		return TRUE
	return FALSE
