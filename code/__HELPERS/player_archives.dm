// Shared helpers for the persistent player book and painting archives (SSlibrarian and SSpaintings).

/// Returns the URL-encoded archive filename for a title, or null if the title cannot be stored safely.
/proc/player_archive_filename(title)
	if(!istext(title) || !length(trim(title)) || length(title) > MAX_NAME_LEN)
		return
	if(copytext(title, 1, 2) == "_")
		return
	var/file_name = url_encode(title)
	var/static/regex/unsafe_filename = regex(@{"[\\/:*?"<>|]"})
	if(length(file_name) > 150 || unsafe_filename.Find(file_name))
		return
	return file_name

/proc/player_archive_feedback(mob/user, message, success = FALSE)
	if(!user)
		return
	to_chat(user, success ? span_notice(message) : span_warning(message))

/// Escapes player-supplied archive text for HTML output, without double-encoding text that was already encoded on input.
/proc/player_archive_display_text(text, fallback = "Unknown")
	if(isnull(text) || text == "")
		return html_encode(fallback)
	return html_encode(html_decode("[text]"))

/// Archived books and paintings are always signed with the creator's true name.
/proc/player_archive_author_name(mob/user)
	return player_archive_display_text(user?.real_name)

/// Loads every archive entry in a directory, keyed by filename without the .json extension.
/proc/load_player_archive(directory)
	. = list()
	for(var/file_name in flist(directory))
		if(copytext(file_name, 1, 2) == "_" || copytext(file_name, -5) != ".json")
			continue
		var/list/contents = safe_json_decode(file2text("[directory][file_name]"))
		if(!islist(contents))
			log_world("Player archive file [directory][file_name] contains invalid JSON and was skipped.")
			continue
		.[copytext(file_name, 1, -5)] = contents

/proc/write_player_archive_file(path, list/contents)
	fdel(path)
	if(!text2file(json_encode(contents), path))
		message_admins("Unable to save archive file [path].")
		return FALSE
	return TRUE
