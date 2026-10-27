/*
 * A hypnosis feature, shown as one tab in the panel. Subtypes register themselves.
 * The TGUI side picks the tab component by id (tgui/packages/tgui/interfaces/Hypnosis/).
 */
/datum/hypnosis_module
	/// Unique id, also used by the TGUI side to pick the tab component
	var/id
	var/name
	var/desc
	/// HYPNO_ROLE_* flags. The tab shows if the player has any of them.
	var/role = HYPNO_ROLE_BOTH
	/// Style types this module may use, or null for all
	var/list/allowed_styles
	/// Style type used when the player hasn't picked an allowed one
	var/default_style = /datum/hypnosis_style/hypnotic
	/// Played to each receiver
	var/sound = 'sound/misc/subtle_emote.ogg'

/datum/hypnosis_module/proc/allows_style(datum/hypnosis_style/style)
	return !allowed_styles || (style.type in allowed_styles)

/// Data for this module's tab
/datum/hypnosis_module/proc/get_ui_data(mob/living/carbon/human/user, datum/hypnosis_panel/panel)
	return list()

/// Handles an op sent from this module's tab. Return TRUE to update the UI.
/datum/hypnosis_module/proc/execute(mob/living/carbon/human/user, datum/hypnosis_panel/panel, op, list/params)
	return FALSE

/// Builds the final message HTML. Override to change how a module's messages look.
/datum/hypnosis_module/proc/format_message(mob/living/carbon/human/user, text, datum/hypnosis_style/style, list/options)
	return "<b>[user]</b> " + style.render(text, options)
