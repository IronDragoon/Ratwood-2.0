/// Returns TRUE if pet-play content is enabled for mob H.
/// Offline mobs (no client prefs) default to TRUE so interactions do not break on NPCs.
/proc/modular_petplay_content_enabled_for(mob/living/carbon/human/H)
	if(!H)
		return FALSE
	if(!H.client?.prefs)
		return TRUE
	return !!H.client.prefs.petplay_enable

/// Returns TRUE if pet-play content is enabled for both participants.
/// Null user is treated as unconstrained to support non-human tool users.
/proc/modular_petplay_content_enabled_for_pair(mob/living/carbon/human/user_human, mob/living/carbon/human/target_human)
	if(user_human && !modular_petplay_content_enabled_for(user_human))
		return FALSE
	if(target_human && target_human != user_human && !modular_petplay_content_enabled_for(target_human))
		return FALSE
	return TRUE
