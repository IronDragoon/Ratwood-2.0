SUBSYSTEM_DEF(librarian)
	name = "Librarian"
	init_order = INIT_ORDER_PATH
	flags = SS_NO_FIRE
	var/list/books = list()

/datum/controller/subsystem/librarian/proc/get_book(input)
	if(!input)
		return list()
	if(books.Find(input))
		return books[input]
	books[input] = file2book(input)
	return books[input]

/proc/file2book(filename)
	if(!filename)
		return list()
	var/json_file = file("strings/books/[filename]")
	testing("filebegin")
	if(fexists(json_file))
		testing("file1")
		var/list/configuration = json_decode(file2text(json_file))
		var/list/contents = configuration["Contents"]
		if(isnull(contents))
			testing("file2")
			return list()
		return contents
	testing("file4")
	return list()


#define PLAYER_BOOK_DIRECTORY "data/player_generated_books/"
#define PLAYER_BOOK_INDEX "_book_titles.json"

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

/// Returns TRUE if an archive filename can be read without leaving its archive folder.
/proc/is_safe_player_archive_filename(file_name)
	return istext(file_name) && length(file_name) && !findtext(file_name, "/") && !findtext(file_name, "\\")

/proc/player_archive_feedback(mob/user, message, success = FALSE)
	if(!user)
		return
	to_chat(user, success ? span_notice(message) : span_warning(message))

/// Escapes player-supplied archive text for HTML output, without double-encoding text that was already encoded on input.
/proc/player_archive_display_text(text, fallback = "Unknown")
	if(isnull(text) || text == "")
		return html_encode(fallback)
	return html_encode(html_decode("[text]"))

/// Writes through a temporary file so an interrupted save does not truncate the existing file.
/proc/write_player_archive_file(path, list/contents)
	var/temp_path = "[path].tmp"
	fdel(temp_path)
	if(!text2file(json_encode(contents), temp_path))
		return FALSE
	fdel(path)
	. = fcopy(temp_path, path)
	fdel(temp_path)

/proc/scan_player_archive(directory)
	var/list/index = list()
	for(var/file_name in flist(directory))
		if(copytext(file_name, -5) != ".json" || copytext(file_name, 1, 2) == "_")
			continue
		index += copytext(file_name, 1, -5)
	return index

/proc/write_player_archive_index(directory, index_name, list/index)
	var/index_path = "[directory][index_name]"
	var/temp_path = "[index_path].tmp"
	fdel(temp_path)
	if(!text2file(json_encode(index), temp_path))
		return FALSE
	fdel(index_path)
	if(!fcopy(temp_path, index_path))
		return FALSE
	fdel(temp_path)
	return TRUE

/// Reads an archive index, recovering from an interrupted write or rebuilding it from the archive folder if needed.
/proc/read_player_archive_index(directory, index_name)
	var/index_path = "[directory][index_name]"
	for(var/path in list(index_path, "[index_path].tmp"))
		if(!fexists(path))
			continue
		var/list/index = safe_json_decode(file2text(path))
		if(!islist(index))
			continue
		if(path != index_path)
			write_player_archive_index(directory, index_name, index)
		return index
	var/list/rebuilt = scan_player_archive(directory)
	if(length(rebuilt))
		message_admins("[index_path] was missing or unreadable and has been rebuilt from [length(rebuilt)] archived file\s.")
	write_player_archive_index(directory, index_name, rebuilt)
	return rebuilt

/// Makes the archive index match the files on disk, removing stale or duplicate entries.
/proc/repair_player_archive_index(directory, index_name)
	var/list/index = read_player_archive_index(directory, index_name)
	var/list/scanned = scan_player_archive(directory)
	if(length(index) == length(scanned) && !length(index ^ scanned))
		return
	write_player_archive_index(directory, index_name, scanned)

/datum/controller/subsystem/librarian/Initialize(start_timeofday)
	repair_player_archive_index(PLAYER_BOOK_DIRECTORY, PLAYER_BOOK_INDEX)
	return ..()

/datum/controller/subsystem/librarian/proc/playerbook2file(input, book_title = "Unknown", author = "Unknown", author_ckey = "Unknown", icon = "basic_book", mob/user, ic_date)
	if(!input)
		player_archive_feedback(user, "There is no text in the book!")
		return FALSE
	if(!ic_date)
		ic_date = get_ic_date_short_as_string()
	if(!(istext(input) && istext(book_title) && istext(author) && istext(author_ckey) && istext(icon) && istext(ic_date)))
		player_archive_feedback(user, "This book is incorrectly formatted!")
		return FALSE
	var/file_name = player_archive_filename(book_title)
	if(!file_name)
		player_archive_feedback(user, "That title cannot be archived. Use a shorter title that does not begin with an underscore.")
		return FALSE
	if(fexists("[PLAYER_BOOK_DIRECTORY][file_name].json"))
		player_archive_feedback(user, "There is already a book by this title!")
		return FALSE

	var/list/contents = list("book_title" = "[book_title]", "author" = "[author]", "author_ckey" = "[author_ckey]", "icon" = "[icon]", "text" = "[input]", "ic_date" = "[ic_date]")
	if(!save_player_book(file_name, contents))
		player_archive_feedback(user, "The archive could not store this book.")
		return FALSE
	message_admins("Book [player_archive_display_text(book_title)] has been saved to the player book database by [player_archive_display_text(author_ckey)]([player_archive_display_text(author)])")
	player_archive_feedback(user, "You have a feeling the newly written book will remain in the archive for a very long time...", TRUE)
	return TRUE

/datum/controller/subsystem/librarian/proc/save_player_book(file_name, list/contents)
	if(!write_player_archive_file("[PLAYER_BOOK_DIRECTORY][file_name].json", contents))
		return FALSE
	var/list/index = pull_player_book_titles()
	index |= file_name
	return write_player_archive_index(PLAYER_BOOK_DIRECTORY, PLAYER_BOOK_INDEX, index)

/datum/controller/subsystem/librarian/proc/file2playerbook(filename)
	if(!is_safe_player_archive_filename(filename))
		return list()
	var/json_file = "[PLAYER_BOOK_DIRECTORY][filename].json"
	if(!fexists(json_file))
		return list()
	var/list/contents = safe_json_decode(file2text(json_file))
	return islist(contents) ? contents : list()

/datum/controller/subsystem/librarian/proc/del_player_book(book_title)
	if(!is_safe_player_archive_filename(book_title))
		return FALSE
	var/json_file = "[PLAYER_BOOK_DIRECTORY][book_title].json"
	if(!fexists(json_file))
		return FALSE
	fdel(json_file)
	var/list/index = pull_player_book_titles()
	index -= book_title
	return write_player_archive_index(PLAYER_BOOK_DIRECTORY, PLAYER_BOOK_INDEX, index)

/datum/controller/subsystem/librarian/proc/pull_player_book_titles()
	return read_player_archive_index(PLAYER_BOOK_DIRECTORY, PLAYER_BOOK_INDEX)

/datum/controller/subsystem/librarian/proc/amend_player_book(book_title, amend_type, amend_text)
	if(!istext(amend_text) || !length(trim(amend_text)) || !(amend_type in list("book_title", "author", "icon")))
		return FALSE
	var/list/contents = file2playerbook(book_title)
	if(!length(contents))
		return FALSE
	contents[amend_type] = amend_text
	var/new_file_name = book_title
	if(amend_type == "book_title")
		new_file_name = player_archive_filename(amend_text)
		if(!new_file_name)
			return FALSE
		if(new_file_name != book_title && fexists("[PLAYER_BOOK_DIRECTORY][new_file_name].json"))
			return FALSE
	// Write the amended copy before removing the original so a failed save cannot lose the book.
	if(!write_player_archive_file("[PLAYER_BOOK_DIRECTORY][new_file_name].json", contents))
		return FALSE
	var/list/index = pull_player_book_titles()
	if(new_file_name != book_title)
		fdel("[PLAYER_BOOK_DIRECTORY][book_title].json")
		index -= book_title
	index |= new_file_name
	return write_player_archive_index(PLAYER_BOOK_DIRECTORY, PLAYER_BOOK_INDEX, index)

#undef PLAYER_BOOK_DIRECTORY
#undef PLAYER_BOOK_INDEX
