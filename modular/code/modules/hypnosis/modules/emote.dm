#define HYPNO_EMOTE_SUBTLE "subtle"
#define HYPNO_EMOTE_OPEN "open"

/// Subtle area targets, mapped to their range
GLOBAL_LIST_INIT(hypnosis_emote_areas, list(
	"area_same_tile" = 0,
	"area_adjacent" = 1,
	"area_all" = HYPNO_SUBTLE_RANGE,
))

/datum/hypnosis_module/emote
	id = "emote"
	name = "Hypnotic Emote"
	desc = "Send a subtle or open emote in a hypnotic style to receptive minds nearby."
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
		"receptive_count" = panel.receptive_count,
		"allowed_styles" = allowed,
		"style" = current.id,
	)

/datum/hypnosis_module/emote/execute(mob/living/carbon/human/user, datum/hypnosis_panel/panel, op, list/params)
	switch(op)
		if("set_style")
			var/datum/hypnosis_style/style = get_hypnosis_style(params["style"])
			if(style && allows_style(style))
				panel.selected_style_id = style.id
			return TRUE
		if("send")
			send(user, panel, params)
			return TRUE
	return FALSE

/datum/hypnosis_module/emote/proc/send(mob/living/carbon/human/user, datum/hypnosis_panel/panel, list/params)
	if(!user.can_send_hypnosis())
		return
	if(GLOB.say_disabled)
		to_chat(user, span_danger("Speech is currently admin-disabled."))
		return
	var/mode = params["mode"]
	if(mode != HYPNO_EMOTE_SUBTLE && mode != HYPNO_EMOTE_OPEN)
		return
	var/message = params["message"]
	if(!istext(message) || !length(message))
		return

	// Same cleaning as Subtle(big)
	message = replacetext(message, regex("\\r", "g"), "")
	message = trim(copytext_char(html_encode(message), 1, MAX_MESSAGE_LEN))
	message = accent_emote_quotes(message, user)
	message = parsemarkdown_basic(message, limited = TRUE, barebones = TRUE)
	message = replacetext(message, regex("\\n", "g"), "<br>")
	if(!length(message))
		return

	var/list/recipients
	if(mode == HYPNO_EMOTE_OPEN)
		recipients = get_hypno_receivers(user, world.view)
	else
		recipients = get_subtle_recipients(user, params["target"])
		if(!recipients)
			to_chat(user, span_boldwarning("That mind is no longer within reach, refresh and try again."))
			return

	var/html = format_message(user, message, panel.get_style_for(src), list())
	user.log_message("HYPNOSIS ([uppertext(mode)]) - [message]", LOG_EMOTE)
	to_chat(user, html)
	var/delivered = 0
	for(var/mob/living/carbon/human/receiver as anything in recipients)
		if(receiver.receive_hypnosis(user, html, sound))
			delivered++
	if(!delivered)
		to_chat(user, span_warning("No receptive minds nearby."))

/// Recipients of a subtle message, or null if a single picked target is no longer valid
/datum/hypnosis_module/emote/proc/get_subtle_recipients(mob/living/carbon/human/user, target)
	var/list/in_range = get_hypno_receivers(user, HYPNO_SUBTLE_RANGE)
	if(target in GLOB.hypnosis_emote_areas)
		var/distance = GLOB.hypnosis_emote_areas[target]
		var/turf/user_turf = get_turf(user)
		. = list()
		for(var/mob/living/carbon/human/H as anything in in_range)
			if(get_dist(get_turf(H), user_turf) <= distance)
				. += H
		return
	if(!istext(target))
		return null
	var/mob/living/carbon/human/picked = locate(target)
	if(!(picked in in_range) || picked.rogue_sneaking || picked.name == "Unknown")
		return null
	return list(picked)

#undef HYPNO_EMOTE_SUBTLE
#undef HYPNO_EMOTE_OPEN
