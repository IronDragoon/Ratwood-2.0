/*
 * Hypnosis framework (ERP, opt-in).
 *
 * Two prefs gate everything:
 *   - hypno_sender: can open the panel and send hypnotic messages, never receives them.
 *   - hypno_receiver: can open the panel and receive hypnotic messages, never sends them.
 *
 * Features are /datum/hypnosis_module subtypes (see modules/), each shown as a tab in the panel
 * when the player has the module's role. Text styles are /datum/hypnosis_style subtypes (see styles/).
 * Both register themselves from their subtypes, so adding either needs no changes here.
 */

#define HYPNO_ROLE_SENDER (1<<0)
#define HYPNO_ROLE_RECEIVER (1<<1)
#define HYPNO_ROLE_BOTH (HYPNO_ROLE_SENDER|HYPNO_ROLE_RECEIVER)

/// How many received messages the panel keeps
#define HYPNO_LOG_MAX 50
/// Range of subtle hypnotic messages, matching the subtle emote
#define HYPNO_SUBTLE_RANGE 4

GLOBAL_LIST_INIT(hypnosis_modules, init_subtypes_assoc(/datum/hypnosis_module))
GLOBAL_LIST_INIT(hypnosis_styles, init_subtypes_assoc(/datum/hypnosis_style))

/proc/get_hypnosis_module(id)
	for(var/path in GLOB.hypnosis_modules)
		var/datum/hypnosis_module/module = GLOB.hypnosis_modules[path]
		if(module.id == id)
			return module

/proc/get_hypnosis_style(id)
	for(var/path in GLOB.hypnosis_styles)
		var/datum/hypnosis_style/style = GLOB.hypnosis_styles[path]
		if(style.id == id)
			return style

/// Receptive humans in view of source within range, excluding source
/proc/get_hypno_receivers(atom/source, range)
	. = list()
	for(var/mob/living/carbon/human/H in get_hearers_in_view(range, source))
		if(H != source && H.is_hypno_receptive())
			. += H

/mob/living/carbon/human
	var/datum/hypnosis_panel/hypnosis_panel

/// Whether we have access to the sending side at all. Any future quirk or trait requirement goes here.
/mob/living/carbon/human/proc/can_hypnotize()
	return !!client?.prefs?.hypno_sender

/// Whether we can send a hypnotic message right now, giving feedback if not
/mob/living/carbon/human/proc/can_send_hypnosis()
	if(!can_hypnotize())
		return FALSE
	if(stat != CONSCIOUS)
		return FALSE
	if(is_banned_from(ckey, "Emote"))
		to_chat(src, span_boldwarning("I cannot send custom emotes (banned)."))
		return FALSE
	if(client.prefs.muted & MUTE_IC)
		to_chat(src, span_boldwarning("I cannot send IC messages (muted)."))
		return FALSE
	return TRUE

/// Whether we can receive hypnotic messages right now. No client means no prefs, so no consent.
/mob/living/carbon/human/proc/is_hypno_receptive()
	return client?.prefs?.hypno_receiver && stat == CONSCIOUS

/// Bitflag of the HYPNO_ROLE_* roles we currently have
/mob/living/carbon/human/proc/hypno_roles()
	. = NONE
	if(can_hypnotize())
		. |= HYPNO_ROLE_SENDER
	if(client?.prefs?.hypno_receiver)
		. |= HYPNO_ROLE_RECEIVER

/mob/living/carbon/human/proc/get_hypnosis_panel()
	if(!hypnosis_panel)
		hypnosis_panel = new(src)
	return hypnosis_panel

/mob/living/carbon/human/proc/update_hypnosis_verb()
	verbs -= /mob/living/carbon/human/proc/hypnotize
	if(hypno_roles())
		verbs += /mob/living/carbon/human/proc/hypnotize
	else if(hypnosis_panel)
		SStgui.close_uis(hypnosis_panel)

/mob/living/carbon/human/proc/on_hypnosis_prefs_changed()
	update_hypnosis_verb()
	if(!hypnosis_panel)
		return
	if(!client?.prefs?.hypno_receiver)
		hypnosis_panel.clear_log()
	SStgui.update_uis(hypnosis_panel)

/mob/living/carbon/human/proc/hypnotize()
	set name = "Hypnotize"
	set category = "Emotes"
	if(!hypno_roles())
		update_hypnosis_verb()
		return
	get_hypnosis_panel().ui_interact(src)

/// Delivers an already-rendered hypnotic message to us if we're receptive. Returns TRUE if delivered.
/mob/living/carbon/human/proc/receive_hypnosis(mob/sender, html, sound)
	if(!is_hypno_receptive())
		return FALSE
	to_chat(src, html)
	if(sound)
		playsound_local(src, sound, 100)
	get_hypnosis_panel().add_log_entry(sender, html)
	return TRUE
