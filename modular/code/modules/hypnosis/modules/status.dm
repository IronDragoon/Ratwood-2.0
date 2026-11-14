/datum/hypnosis_module/status
	id = "status"
	name = "Status"
	desc = "Your receptiveness to hypnosis, and any trance or suggestion you're under."
	role = HYPNO_ROLE_RECEIVER

/datum/hypnosis_module/status/get_ui_data(mob/living/carbon/human/user, datum/hypnosis_panel/panel)
	// Set by the Hypnotic Influence quirk (modular_azurepeak/quirks/hypnotic_gaze.dm)
	var/datum/hypnotic_suggestion/suggestion = user.mind?.hypnotic_suggestion
	return list(
		"receptive" = user.is_hypno_receptive(),
		"trance" = !!suggestion,
		"phrase" = suggestion?.phrase,
	)
