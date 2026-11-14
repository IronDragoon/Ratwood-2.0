/// Target value for every subject in view, instead of one subject's ref
#define HYPNO_EMOTE_ALL_IN_VIEW "all_in_view"

/datum/hypnosis_module/emote
	id = "emote"
	name = "Hypnotic Emote"
	desc = "Send an emote in your hypnotic style to the minds you hold in a trance."
	role = HYPNO_ROLE_SENDER

/datum/hypnosis_module/emote/get_ui_data(mob/living/carbon/human/user, datum/hypnosis_panel/panel)
	var/list/allowed = list()
	for(var/path in GLOB.hypnosis_styles)
		var/datum/hypnosis_style/style = GLOB.hypnosis_styles[path]
		if(allows_style(style))
			allowed += style.id
	var/datum/hypnosis_style/current = panel.get_style_for(src)
	return list(
		"targets" = panel.target_entries,
		"subjects_in_view" = panel.subjects_in_view,
		"allowed_styles" = allowed,
		"style" = current.id,
		"preview_html" = panel.preview_html,
	)

/datum/hypnosis_module/emote/execute(mob/living/carbon/human/user, datum/hypnosis_panel/panel, op, list/params)
	switch(op)
		if("set_style")
			var/datum/hypnosis_style/style = get_hypnosis_style(params["style"])
			if(style && allows_style(style) && user.client)
				user.client.prefs.hypno_style = style.id
				user.client.prefs.save_preferences()
			return TRUE
		if("preview")
			var/message = clean_message(user, params["message"])
			panel.preview_html = message ? format_message(user, message, panel.get_style_for(src), list()) : null
			return TRUE
		if("send")
			send(user, panel, params)
			return TRUE
	return FALSE

/// Cleans raw input the same way as Subtle(big). Returns null if nothing is left.
/datum/hypnosis_module/emote/proc/clean_message(mob/living/carbon/human/user, message)
	if(!istext(message) || !length(message))
		return null
	message = replacetext(message, regex("\\r", "g"), "")
	message = trim(copytext_char(html_encode(message), 1, MAX_MESSAGE_LEN))
	message = accent_emote_quotes(message, user)
	message = parsemarkdown_basic(message, limited = TRUE, barebones = TRUE)
	message = replacetext(message, regex("\\n", "g"), "<br>")
	return length(message) ? message : null

/datum/hypnosis_module/emote/proc/send(mob/living/carbon/human/user, datum/hypnosis_panel/panel, list/params)
	if(!user.can_send_hypnosis())
		return
	if(GLOB.say_disabled)
		to_chat(user, span_danger("Speech is currently admin-disabled."))
		return
	var/message = clean_message(user, params["message"])
	if(!message)
		return
	var/target = params["target"]
	var/list/recipients = get_recipients(user, target)
	if(!recipients)
		to_chat(user, span_boldwarning("That mind is no longer within your reach, refresh and try again."))
		return

	var/html = format_message(user, message, panel.get_style_for(src), list())
	user.log_message("HYPNOSIS ([target == HYPNO_EMOTE_ALL_IN_VIEW ? "SUBJECTS IN VIEW" : "SUBJECT"]) - [message]", LOG_EMOTE)
	to_chat(user, html)
	panel.preview_html = null
	var/delivered = 0
	for(var/mob/living/carbon/human/receiver as anything in recipients)
		if(receiver.receive_hypnosis(html, sound))
			delivered++
	if(!delivered)
		to_chat(user, span_warning("None of your subjects are here to receive it."))

/// Only our own subjects ever receive. Returns null if a single picked subject is no longer valid.
/datum/hypnosis_module/emote/proc/get_recipients(mob/living/carbon/human/user, target)
	var/list/subjects = user.get_hypnotic_subject_bodies()
	if(target == HYPNO_EMOTE_ALL_IN_VIEW)
		. = list()
		for(var/mob/living/carbon/human/H in get_hearers_in_view(world.view, user))
			if(H in subjects)
				. += H
		return
	if(!istext(target))
		return null
	var/mob/living/carbon/human/picked = locate(target)
	if(!istype(picked) || !(picked in subjects))
		return null
	return list(picked)

#undef HYPNO_EMOTE_ALL_IN_VIEW
