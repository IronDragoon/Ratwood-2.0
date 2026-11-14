/*
 * One per human, created the first time they open the panel or receive a hypnotic message.
 * Owns the TGUI window and the state modules share: the received log and the cached target list.
 * The chosen style is a saved pref (prefs.hypno_style), not panel state. The window doesn't
 * auto-update; anything that changes state calls SStgui.update_uis(src) or returns TRUE from ui_act.
 */
/datum/hypnosis_panel
	var/mob/living/carbon/human/owner
	/// Newest last. Each entry is list("time", "html").
	var/list/received_log = list()
	/// Server-rendered preview of the sender's draft, exactly as it would be sent
	var/preview_html
	/// Our subjects who can receive right now, as list("ref", "name") entries.
	/// Rebuilt on open, on refresh and whenever one of our suggestions changes.
	var/list/target_entries = list()
	/// How many of those were in view at the last refresh
	var/subjects_in_view = 0

/datum/hypnosis_panel/New(mob/living/carbon/human/new_owner)
	owner = new_owner
	..()

/datum/hypnosis_panel/Destroy()
	SStgui.close_uis(src)
	owner = null
	received_log = null
	target_entries = null
	return ..()

/datum/hypnosis_panel/ui_interact(mob/user, datum/tgui/ui)
	if(user != owner)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		refresh_targets()
		ui = new(user, src, "Hypnosis", "Hypnosis")
		ui.set_state(GLOB.conscious_state)
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/hypnosis_panel/ui_static_data(mob/user)
	var/list/data = list()
	var/list/styles = list()
	for(var/path in GLOB.hypnosis_styles)
		var/datum/hypnosis_style/style = GLOB.hypnosis_styles[path]
		styles += list(list(
			"id" = style.id,
			"name" = style.name,
			"desc" = style.desc,
			"css_class" = style.css_class,
		))
	data["styles"] = styles
	return data

/datum/hypnosis_panel/ui_data(mob/user)
	var/list/data = list()
	var/roles = owner.hypno_roles()
	var/list/modules = list()
	for(var/path in GLOB.hypnosis_modules)
		var/datum/hypnosis_module/module = GLOB.hypnosis_modules[path]
		if(!(module.role & roles))
			continue
		modules += list(list(
			"id" = module.id,
			"name" = module.name,
			"desc" = module.desc,
			"data" = module.get_ui_data(owner, src),
		))
	data["modules"] = modules
	return data

/datum/hypnosis_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE
	if(ui.user != owner)
		return TRUE
	switch(action)
		if("refresh_targets")
			refresh_targets()
			return TRUE
		if("module")
			var/datum/hypnosis_module/module = get_hypnosis_module(params["module"])
			if(!module || !(module.role & owner.hypno_roles()))
				return TRUE
			return module.execute(owner, src, params["op"], params)
	return FALSE

/// Only our own subjects can be messaged. Any of them from any distance, even hidden.
/datum/hypnosis_panel/proc/refresh_targets()
	target_entries = list()
	var/list/subjects = owner.get_hypnotic_subject_bodies()
	for(var/mob/living/carbon/human/H as anything in subjects)
		target_entries += list(list("ref" = REF(H), "name" = H.real_name))
	subjects_in_view = 0
	for(var/mob/living/carbon/human/H in get_hearers_in_view(world.view, owner))
		if(H in subjects)
			subjects_in_view++

/// The style to use for module, honouring the player's saved style when the module allows it
/datum/hypnosis_panel/proc/get_style_for(datum/hypnosis_module/module)
	var/datum/hypnosis_style/style = get_hypnosis_style(owner.get_hypno_style_id())
	if(module.allows_style(style))
		return style
	return GLOB.hypnosis_styles[module.default_style]

/datum/hypnosis_panel/proc/add_log_entry(html)
	received_log += list(list(
		"time" = station_time_timestamp("hh:mm"),
		"html" = html,
	))
	if(length(received_log) > HYPNO_LOG_MAX)
		received_log.Cut(1, length(received_log) - HYPNO_LOG_MAX + 1)
	SStgui.update_uis(src)

/datum/hypnosis_panel/proc/clear_log()
	received_log.Cut()
	SStgui.update_uis(src)
