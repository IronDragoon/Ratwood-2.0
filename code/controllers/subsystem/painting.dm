#define PLAYER_PAINTING_DIRECTORY "data/player_generated_paintings/"
#define PLAYER_PAINTING_INDEX "_painting_titles.json"
#define PLAYER_PAINTING_IMAGE_DIRECTORY "data/player_generated_paintings/paintings/"

SUBSYSTEM_DEF(paintings)
	name = "Paintings"
	init_order = INIT_ORDER_PATH
	flags = SS_NO_FIRE

	var/list/paintings = list()

/datum/controller/subsystem/paintings/Initialize(start_timeofday)
	read_player_archive_index(PLAYER_PAINTING_DIRECTORY, PLAYER_PAINTING_INDEX, TRUE)
	update_paintings()
	return ..()

/// Older paintings were saved with the raw title as the filename; only look those up when the title is path safe.
/datum/controller/subsystem/paintings/proc/get_legacy_painting_filename(title)
	if(!istext(title))
		return
	var/static/regex/unsafe_filename = regex(@{"[\\/:*?"<>|]"})
	if(!length(title) || unsafe_filename.Find(title))
		return
	return "[PLAYER_PAINTING_IMAGE_DIRECTORY][title].png"

/datum/controller/subsystem/paintings/proc/get_painting_filename(title)
	var/encoded_path = "[PLAYER_PAINTING_IMAGE_DIRECTORY][url_encode(title)].png"
	if(fexists(encoded_path))
		return encoded_path
	for(var/recovery_path in list("[encoded_path].tmp", "[encoded_path].bak"))
		if(fexists(recovery_path))
			if(fcopy(recovery_path, encoded_path))
				message_admins("Recovered painting image [encoded_path].")
				return encoded_path
			message_admins("Unable to recover painting image [encoded_path] from [recovery_path].")
	var/legacy_path = get_legacy_painting_filename(title)
	if(legacy_path && fexists(legacy_path))
		return legacy_path
	return encoded_path

/datum/controller/subsystem/paintings/proc/update_paintings()
	paintings = list()
	for(var/painting in pull_player_painting_titles())
		var/list/painting_data = file2playerpainting(painting)
		if(length(painting_data))
			paintings[painting] = painting_data

/datum/controller/subsystem/paintings/proc/pull_player_painting_titles()
	return read_player_archive_index(PLAYER_PAINTING_DIRECTORY, PLAYER_PAINTING_INDEX)

/datum/controller/subsystem/paintings/proc/file2playerpainting(filename)
	if(!is_safe_player_archive_filename(filename))
		return list()
	var/list/contents = read_player_archive_file("[PLAYER_PAINTING_DIRECTORY][filename].json")
	return islist(contents) ? contents : list()

/datum/controller/subsystem/paintings/proc/playerpainting2file(icon/painting, painting_title = "Unknown", author = "Unknown", author_ckey = "Unknown", canvas_size, obj/item/canvas/canvas, mob/user)
	if(!painting)
		player_archive_feedback(user, "There is no painting to archive!")
		return FALSE
	if(!(istext(painting_title) && istext(author) && istext(author_ckey)))
		player_archive_feedback(user, "This painting is incorrectly formatted!")
		return FALSE
	var/file_name = player_archive_filename(painting_title)
	if(!file_name)
		player_archive_feedback(user, "That title cannot be archived. Use a shorter title that does not begin with an underscore.")
		return FALSE

	var/json_path = "[PLAYER_PAINTING_DIRECTORY][file_name].json"
	var/list/existing = file2playerpainting(file_name)
	if(length(existing) || fexists(json_path))
		if(existing["author_ckey"] != author_ckey)
			player_archive_feedback(user, "There is already a painting by this title!")
			return FALSE
		if(canvas?.reject)
			player_archive_feedback(user, "The painter has refused to replace [painting_title].")
			return FALSE
		var/client/author_client = GLOB.directory[ckey(author_ckey)]
		if(!author_client)
			player_archive_feedback(user, "The painter must be present to replace their painting titled [painting_title].")
			return FALSE
		var/replace = tgui_alert(author_client, "Someone wants to replace [html_decode(painting_title)] with another one by you, do you want to replace this?", "Confirm", list("Yes", "No"))
		if(replace != "Yes")
			if(canvas)
				canvas.reject = TRUE
			player_archive_feedback(user, "The painter has refused to replace [painting_title].")
			return FALSE
		// Another painter may have claimed the title while the alert was open.
		existing = file2playerpainting(file_name)
		if(length(existing) && existing["author_ckey"] != author_ckey)
			player_archive_feedback(user, "There is already a painting by this title!")
			return FALSE

	var/image_path = "[PLAYER_PAINTING_IMAGE_DIRECTORY][file_name].png"
	var/temp_image_path = "[image_path].tmp"
	fdel(temp_image_path)
	if(!fcopy(painting, temp_image_path) || !commit_player_archive_file(temp_image_path, image_path))
		player_archive_feedback(user, "The archive could not store this painting.")
		return FALSE
	var/list/contents = list("painting_title" = "[painting_title]", "author" = "[author]", "author_ckey" = "[author_ckey]", "canvas_size" = canvas_size, "ic_date" = get_ic_date_short_as_string())
	if(!write_player_archive_file(json_path, contents))
		player_archive_feedback(user, "The archive could not store this painting.")
		return FALSE
	var/legacy_path = get_legacy_painting_filename(painting_title)
	if(legacy_path && legacy_path != image_path && fexists(legacy_path))
		fdel(legacy_path)

	var/list/index = pull_player_painting_titles()
	index |= file_name
	if(!write_player_archive_file("[PLAYER_PAINTING_DIRECTORY][PLAYER_PAINTING_INDEX]", index))
		player_archive_feedback(user, "The archive could not store this painting.")
		return FALSE
	message_admins("Painting [player_archive_display_text(painting_title)] has been saved to the player painting database by [player_archive_display_text(author_ckey)]([player_archive_display_text(author)])")
	player_archive_feedback(user, "You have a feeling the painting will remain in the archive for a very long time...", TRUE)
	return TRUE

/// Returns the metadata of a random archived painting of the given size whose image exists, or null if there are none.
/datum/controller/subsystem/paintings/proc/get_random_painting_data(canvas_size)
	var/list/painting_titles = pull_player_painting_titles()
	if(!islist(painting_titles))
		return
	painting_titles = painting_titles.Copy()
	while(length(painting_titles))
		var/list/paint_list = file2playerpainting(pick_n_take(painting_titles))
		if(!paint_list["painting_title"] || paint_list["canvas_size"] != canvas_size)
			continue
		if(!fexists(get_painting_filename(paint_list["painting_title"])))
			continue
		return paint_list

/datum/controller/subsystem/paintings/proc/del_player_painting(painting_title)
	if(!istext(painting_title) || !length(painting_title))
		return FALSE

	var/encoded_title = url_encode(painting_title)
	var/json_file = "[PLAYER_PAINTING_DIRECTORY][encoded_title].json"
	if(!is_safe_player_archive_filename(encoded_title) || !fexists(json_file))
		return FALSE

	if(!fdel(json_file))
		message_admins("Unable to delete archived painting [json_file].")
		return FALSE
	fdel("[json_file].tmp")
	fdel("[json_file].bak")
	var/image_path = "[PLAYER_PAINTING_IMAGE_DIRECTORY][encoded_title].png"
	fdel(image_path)
	fdel("[image_path].tmp")
	fdel("[image_path].bak")
	var/legacy_path = get_legacy_painting_filename(painting_title)
	if(legacy_path && fexists(legacy_path))
		fdel(legacy_path)
	var/list/index = pull_player_painting_titles()
	index -= encoded_title
	return write_player_archive_file("[PLAYER_PAINTING_DIRECTORY][PLAYER_PAINTING_INDEX]", index)

#undef PLAYER_PAINTING_DIRECTORY
#undef PLAYER_PAINTING_INDEX
#undef PLAYER_PAINTING_IMAGE_DIRECTORY
