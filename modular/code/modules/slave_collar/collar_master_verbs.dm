/mob/proc/collar_master_help()
	set name = "Collar Help"
	set category = "Collar Tab"

	var/datum/component/collar_master/CM = mind?.GetComponent(/datum/component/collar_master)
	if(!CM)
		return

	var/help_text = {"<span class='notice'><b>Collar Control — quick reference</b>
	All commands are accessed via the <b>Collar Control</b> panel (Collar Tab).

	<b>Pet management</b>
	- Select pets using the checkboxes, then issue commands.
	- Listen: relay a pet's heard speech and emotes to your chat.
	- Release Selected: drop one or more pets from your control.
	- Release All Pets: immediately release all pets (Collar Tab verb).

	<b>Discipline</b>
	- Shock: electric punishment.
	- Force Surrender: stuns and submits the pet.
	- Force Strip: removes the pet's worn clothing.

	<b>Behaviour</b>
	- Toggle Speech: forces the pet to speak only in animal noises.
	- Toggle Clothing: forbid or permit the pet from wearing clothes.
	- Toggle Arousal: start / stop a periodic arousal loop.
	- Toggle Orgasm Denial: prevent the pet from reaching climax.
	- Toggle Love: apply or remove a forced-love status effect.
	- Toggle Hallucinations: inflict or cure mild hallucination trauma.

	<b>Communication</b>
	- Send Message: whisper through the collar to the pet.
	- Impose Will: send an unfiltered narrative message to the pet.
	- Force Action: compel the pet to say or emote a specific phrase.

	<b>Cursed chastity (requires pet to have a cursed device)</b>
	- Lock / unlock, set front access mode, toggle anal access, spikes, flat cage.

	Note: most commands share a [CM.command_cooldown/10]s cooldown.
	Currently controlling [length(CM.my_pets)] pets.</span>"}

	to_chat(src, help_text)


/mob/proc/collar_master_releaseall()
	set name = "Release All Pets"
	set category = "Collar Tab"

	var/datum/component/collar_master/CM = mind?.GetComponent(/datum/component/collar_master)
	if(!CM)
		return
	qdel(CM)
