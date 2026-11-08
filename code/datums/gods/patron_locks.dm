/*
	Patron locks
	Jobs, advclasses and outfits can each restrict which patrons may take them, through their allowed_patrons lists.
	Every check goes through these helpers so the three levels behave the same way:
	- PATRON_LOCK_NONE: the patron is allowed as-is.
	- PATRON_LOCK_SWITCH: the patron isn't allowed, but a patron of the same faith is. Joining switches the character to it for the round.
	- PATRON_LOCK_LOCKED: nothing in the patron's faith is allowed. The role can't be taken.
*/

GLOBAL_LIST_EMPTY(outfit_allowed_patrons_cache)

/// Returns a copy of an outfit type's allowed_patrons, or null if it doesn't restrict patrons. Cached per type.
/proc/get_outfit_allowed_patrons(outfit_type)
	if(!ispath(outfit_type, /datum/outfit/job/roguetown))
		return null
	if(!(outfit_type in GLOB.outfit_allowed_patrons_cache))
		var/datum/outfit/job/roguetown/outfit = new outfit_type()
		GLOB.outfit_allowed_patrons_cache[outfit_type] = length(outfit.allowed_patrons) ? outfit.allowed_patrons.Copy() : null
		qdel(outfit)
	var/list/cached = GLOB.outfit_allowed_patrons_cache[outfit_type]
	return cached?.Copy()

/// Returns the patron types accepted by every given allowed_patrons list. Null or empty lists don't restrict.
/// Returns null when nothing restricts, and an empty list when the lists share no patron.
/proc/combine_allowed_patrons(...)
	var/list/combined
	for(var/list/allowed in args)
		if(!length(allowed))
			continue
		if(isnull(combined))
			combined = allowed.Copy()
		else
			combined &= allowed
	return combined

/// Returns the patron datums from `allowed` that share a faith with `patron`.
/proc/get_patron_switch_candidates(datum/patron/patron, list/allowed)
	. = list()
	if(!patron)
		return
	for(var/path in allowed)
		var/datum/patron/candidate = GLOB.patronlist[path]
		if(candidate && candidate.associated_faith == patron.associated_faith)
			. += candidate

/// Returns a PATRON_LOCK_* define for `patron` against a list built by combine_allowed_patrons().
/proc/get_patron_lock_status(datum/patron/patron, list/allowed)
	if(isnull(allowed))
		return PATRON_LOCK_NONE
	if(patron && (patron.type in allowed))
		return PATRON_LOCK_NONE
	if(length(get_patron_switch_candidates(patron, allowed)))
		return PATRON_LOCK_SWITCH
	return PATRON_LOCK_LOCKED

/// Returns the hover text explaining a lock, or null when there is none.
/proc/get_patron_lock_tooltip(datum/patron/patron, list/allowed, datum/patron/default_patron)
	switch(get_patron_lock_status(patron, allowed))
		if(PATRON_LOCK_SWITCH)
			var/list/names = list()
			if(default_patron)
				var/datum/patron/default_datum = GLOB.patronlist[default_patron]
				names += default_datum?.name
			else
				for(var/datum/patron/candidate as anything in get_patron_switch_candidates(patron, allowed))
					names += candidate.name
			return "This will force your patron to [english_list(names, and_text = " or ")]."
		if(PATRON_LOCK_LOCKED)
			return "Locked to [describe_allowed_patrons(allowed)]."
	return null

/// Describes an allowed_patrons list for players. A faith is named when every selectable patron in it is allowed, otherwise the patrons are named.
/proc/describe_allowed_patrons(list/allowed)
	var/list/parts = list()
	var/list/remaining = list()
	for(var/path in allowed)
		if(GLOB.preference_patrons[path])
			remaining += path
	for(var/faith_path in GLOB.patrons_by_faith)
		var/list/selectable = list()
		for(var/path in GLOB.patrons_by_faith[faith_path])
			if(GLOB.preference_patrons[path])
				selectable += path
		// A faith with one patron reads better as that patron's name.
		if(length(selectable) < 2)
			continue
		if(length(selectable - remaining))
			continue
		var/datum/faith/faith = GLOB.faithlist[faith_path]
		parts += "the [faith.name]"
		remaining -= selectable
	for(var/path in remaining)
		var/datum/patron/patron = GLOB.patronlist[path]
		parts += patron.name
	if(!length(parts))
		return "a faith you cannot follow"
	return english_list(parts, and_text = ", ")

/// Switches `target` to a patron that `allowed` accepts, if their current one isn't accepted. This lasts for the round and never touches preferences.
/// Same-faith patrons are picked first. Cross-faith is only a fallback for spawns that skip the menus, like migrants or admin spawns.
/// Returns TRUE if the patron changed.
/proc/apply_patron_lock(mob/living/carbon/human/target, list/allowed, datum/patron/default_patron)
	if(!target || !length(allowed))
		return FALSE
	var/datum/patron/old_patron = target.patron
	if(old_patron && (old_patron.type in allowed))
		return FALSE
	var/datum/patron/new_patron = default_patron
	if(!new_patron)
		var/list/same_faith = get_patron_switch_candidates(old_patron, allowed)
		if(length(same_faith))
			new_patron = pick(same_faith)
		else
			var/list/possible = list()
			for(var/path in allowed)
				if(GLOB.patronlist[path])
					possible += path
			if(!length(possible))
				return FALSE
			new_patron = pick(possible)
	target.set_patron(new_patron)
	var/change_message = span_warning("[old_patron] had not endorsed my practices in my younger years. I've since grown accustomed to [target.patron].")
	if(target.client)
		to_chat(target, change_message)
	else
		// Characters during round start are first equipped before clients are moved into them. This is a bandaid to give an important piece of information correctly to the client
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(to_chat), target, change_message), 5 SECONDS)
	return TRUE

/// The patrons this job accepts, combining its own list with its outfit's.
/datum/job/proc/get_allowed_patrons()
	return combine_allowed_patrons(allowed_patrons, get_outfit_allowed_patrons(outfit))

/// The patrons this advclass accepts, combining its own list with its outfit's.
/datum/advclass/proc/get_allowed_patrons()
	return combine_allowed_patrons(allowed_patrons, get_outfit_allowed_patrons(outfit))
