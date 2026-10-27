/*
 * A look for hypnotic text. Subtypes register themselves. Each css_class lives in
 * tgui/packages/tgui/styles/interfaces/Hypnosis.scss, which both the chat panel and the
 * Hypnosis window load, so the panel can preview it.
 *
 * options is for future player-tweakable styles. Any style that uses them must validate every
 * value server-side (hex colours, clamped sizes, choices from a fixed list) and must never put
 * player text straight into a style attribute.
 */
/datum/hypnosis_style
	/// Unique id, sent to and from the UI
	var/id
	var/name
	var/desc
	var/css_class
	/// Player-tweakable options this style declares. Empty for every v1 style.
	var/list/options = list()

/// Wraps already-sanitized text in this style
/datum/hypnosis_style/proc/render(text, list/options)
	return "<span class='[css_class]'>[text]</span>"

/datum/hypnosis_style/hypnotic
	id = "hypnotic"
	name = "Hypnotic"
	desc = "A slow pulse through deep purples."
	css_class = "hypno-hypnotic"

/datum/hypnosis_style/lustful
	id = "lustful"
	name = "Lustful"
	desc = "A warm pulse of pinks and magentas."
	css_class = "hypno-lustful"

/datum/hypnosis_style/whisper
	id = "whisper"
	name = "Whisper"
	desc = "Small and soft, fading in and out."
	css_class = "hypno-whisper"
