/datum/hypnosis_module/subjects
	id = "subjects"
	name = "Subjects"
	desc = "Minds you hold in a trance, and the suggestions you've left in them."
	role = HYPNO_ROLE_SENDER

/datum/hypnosis_module/subjects/get_ui_data(mob/living/carbon/human/user, datum/hypnosis_panel/panel)
	var/list/entries = list()
	if(user.mind)
		for(var/datum/hypnotic_suggestion/suggestion as anything in user.mind.get_hypnotic_subjects())
			var/datum/mind/target_mind = suggestion.target_mind_ref?.resolve()
			var/mob/living/carbon/human/body = target_mind?.current
			entries += list(list(
				"ref" = REF(suggestion),
				"name" = suggestion.subject_name(),
				"phrase" = suggestion.phrase,
				"awaiting" = suggestion.capture_open && !suggestion.phrase,
				"reachable" = istype(body) && body.is_hypno_receptive(),
			))
	return list("subjects" = entries)

/datum/hypnosis_module/subjects/execute(mob/living/carbon/human/user, datum/hypnosis_panel/panel, op, list/params)
	var/datum/hypnotic_suggestion/suggestion = locate(params["ref"])
	if(!istype(suggestion) || QDELETED(suggestion) || !user.mind || suggestion.caster_mind_ref?.resolve() != user.mind)
		return TRUE
	switch(op)
		if("release")
			suggestion.release(user)
		if("suggest")
			if(user.can_send_hypnosis() && istext(params["text"]))
				suggestion.suggest_from_afar(user, params["text"])
	return TRUE
