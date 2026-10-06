#define PRINTER_COOLDOWN 600 // The time between printing manuscripts and binding books
#define PRINTING_TIME 250 // The time it takes to actually print something using the printing press

/obj/machinery/printingpress
	name = "printing press"
	icon = 'icons/roguetown/misc/machines.dmi'
	icon_state = "Ppress_Clean"
	desc = "The Archivist's wonder. Gears, ink, and wood blocks can turn the written word to the printed word."
	density = TRUE
	var/cooldown = 0
	var/printing = FALSE
	var/has_paper = FALSE
	var/obj/item/paper/loaded_paper
	var/obj/item/output_item

	var/static/list/manuel_name_to_path = list()

/obj/machinery/printingpress/examine(mob/user)
	. = ..()
	. += span_info("Insert blank paper, then right-click to select a book to print. Use an empty hand to retrieve paper or a finished book. Apply a finished player book or signed canvas to archive it.")
	if(printing)
		. += span_info("It is currently printing.")
	else
		if(output_item)
			. += span_info("It has a finished book ready. Use an empty hand to retrieve it.")
		else if(!QDELETED(loaded_paper) && loaded_paper.loc == src)
			. += span_info("It has blank paper loaded.")
		else
			. += span_info("It is empty and has no paper loaded.")
		if(cooldown > world.time)
			. += span_info("It is currently recalibrating and cannot print yet.")

/obj/machinery/printingpress/attackby(obj/item/O, mob/user, list/modifiers)
	if(printing)
		to_chat(user, span_warning("[src] is currently printing. Please wait."))
		return
	if(output_item)
		to_chat(user, span_notice("Please retrieve the printed item before inserting new items."))
		return
	if(istype(O, /obj/item/canvas))
		var/obj/item/canvas/M = O
		if(!M.author || !M.title)
			to_chat(user, span_notice("This canvas isn't signed."))
			return
		// Prompt the user to upload the manuscript
		var/choice = tgui_alert(user, "Do you want to add the painting to the archive?", "Confirm", list("Yes", "No"))
		if(choice == "Yes")
			if(QDELETED(M) || !user.canUseTopic(src, BE_CLOSE) || !user.Adjacent(M))
				return
			upload_painting(user, M)
		else
			to_chat(user, span_notice("You decide not to upload the painting."))
		return

	if(istype(O, /obj/item/manuscript))
		to_chat(user, span_notice("Finish this manuscript with a book crafting kit and give it a title and author before uploading it."))
		return

	if(istype(O, /obj/item/book/rogue/playerbook))
		var/obj/item/book/rogue/playerbook/PB = O
		if(!PB.written)
			to_chat(user, span_notice("This book has yet to be authored and titled. You'll need to do so before uploading it."))
			return
		var/choice = tgui_alert(user, "Do you want to add the book to the archive?", "Confirm", list("Yes", "No"))
		if(choice == "Yes")
			if(QDELETED(PB) || !user.canUseTopic(src, BE_CLOSE) || !user.Adjacent(PB))
				return
			upload_manuscript(user, PB)
		else
			to_chat(user, span_notice("You decide not to upload the book."))
		return
	// THIS IS FOR LOADING BLANK PAPER AS MATERIAL
	if((O.type == /obj/item/paper) && !has_paper)
		var/obj/item/paper/paper = O
		if(paper.info)
			to_chat(user, span_warning("The paper needs to be blank to be put into [src]."))
			return
		if(!user.transferItemToLoc(paper, src))
			to_chat(user, span_warning("You can't insert [paper] into [src]."))
			return
		has_paper = TRUE
		loaded_paper = paper
		src.icon_state = "Ppress_Prepared"
		to_chat(user, span_warning("You insert the blank paper into [src]."))
		return
	return ..()

/obj/machinery/printingpress/attack_hand(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	if(printing)
		to_chat(user, span_warning("[src] is currently printing. Please wait."))
		return
	if(output_item)
		// Try to put the item into the user's hands
		if(!user.put_in_hands(output_item))
			output_item.forceMove(get_turf(user))
		else
			to_chat(user, span_warning("You retrieve [output_item] from [src]."))
		output_item = null
		src.icon_state = "Ppress_Clean"
		return
	if(loaded_paper)
		var/obj/item/paper/P = loaded_paper
		if(!user.put_in_hands(P))
			P.forceMove(get_turf(user)) // If not, drop it at the user's location
		to_chat(user, span_warning("You retrieve [P.name] from [src]."))
		has_paper = FALSE
		loaded_paper = null
		src.icon_state = "Ppress_Clean"
		return
	else
		// Default interaction or message
		to_chat(user, span_warning("[src] is empty."))
		return

/obj/machinery/printingpress/attack_right(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	if(printing)
		to_chat(user, span_warning("[src] is currently printing. Please wait."))
		return
	if(output_item)
		to_chat(user, span_warning("There is a finished product in [src]. Use an empty hand to retrieve it."))
		return
	if(!has_paper)
		to_chat(user, span_warning("[src] requires a blank piece of paper to print."))
		return
	var/choice = input(user, "Choose an option for \the [src]") as null|anything in list("Print The Book", "Print a Tome of Justice", "Print from the Archive", "Profession Manual")
	switch(choice)
		if ("Print The Verses and Acts of the Ten")
			start_printing(user, "bibble")
		if ("Print a Tome of Justice")
			start_printing(user, "justice")
		if ("Print from the Archive")
			choose_search_parameters(user)
		if("Profession Manual")
			if(!length(manuel_name_to_path))
				for(var/obj/item/recipe_book/book as anything in subtypesof(/obj/item/recipe_book))
					if(!initial(book.can_spawn))
						continue
					manuel_name_to_path |= initial(book.name)
					manuel_name_to_path[initial(book.name)] = book
			choice = input(user, "Choose an option for \the [src]") as null|anything in manuel_name_to_path
			if(choice)
				start_printing(user, manuel_name_to_path[choice])

/obj/machinery/printingpress/proc/start_printing(mob/user, print_type, id = null)
	if(!user || !user.canUseTopic(src, BE_CLOSE))
		return
	if(printing)
		to_chat(user, span_warning("[src] is currently printing. Please wait."))
		return
	if(output_item)
		to_chat(user, span_warning("Retrieve the finished book before printing another."))
		return
	if(QDELETED(loaded_paper) || loaded_paper.loc != src)
		has_paper = FALSE
		loaded_paper = null
		to_chat(user, span_warning("[src] requires a blank piece of paper to print."))
		return
	if(cooldown > world.time)
		to_chat(user, span_warning("[src] is still recalibrating."))
		return
	if(print_type == "archive")
		var/list/available_books = SSlibrarian.pull_player_book_titles()
		if(!(id in available_books) || !length(SSlibrarian.file2playerbook(id)))
			to_chat(user, span_warning("This book is no longer in the archive."))
			return
	else if(print_type != "bibble" && print_type != "justice" && !ispath(print_type, /obj/item/recipe_book))
		to_chat(user, span_warning("That book cannot be printed."))
		return
	printing = TRUE
	src.icon_state = "Ppress_Printing"
	to_chat(user, span_warning("[src] starts printing..."))
	playsound(src, 'sound/misc/ppress.ogg', 100, FALSE)
	// Delete the blank paper as it's consumed during printing
	if(loaded_paper)
		qdel(loaded_paper)
		loaded_paper = null
		has_paper = FALSE
	sleep(PRINTING_TIME)
	if(QDELETED(src))
		return
	if(print_type == "bibble")
		print_bibble(user)
	else if(print_type == "justice")
		print_justice(user)
	else if(print_type == "archive")
		print_manuscript(user, id)
	else if (ispath(print_type))
		var/obj/item/recipe_book/path = print_type
		var/obj/item/recipe_book/book = new path(src)
		output_item = book
		visible_message("<span class='notice'>The printing press hums as it produces [book.name].</span>")

	// Printing is done
	record_round_statistic(STATS_BOOKS_PRINTED)
	printing = FALSE
	src.icon_state = "Ppress_Done"
	cooldown = world.time + PRINTER_COOLDOWN

/obj/machinery/printingpress/proc/upload_manuscript(mob/user, obj/item/book/rogue/playerbook/PB)
	if(!PB.written)
		to_chat(user, span_warning("Finish authoring this book before uploading it."))
		return
	if(SSlibrarian.playerbook2file(PB.player_book_text, PB.player_book_title, PB.player_book_author, PB.player_book_author_ckey, PB.player_book_icon, user, PB.player_book_date))
		PB.is_in_round_player_generated = FALSE

/obj/machinery/printingpress/proc/upload_painting(mob/user, obj/item/canvas/M)
	return M.upload_painting(user)

/obj/machinery/printingpress/proc/print_bibble(mob/user)
	// Creates a static book (Bibble)
	var/obj/item/book/rogue/bibble/B = new(src)
	output_item = B
	visible_message("<span class='notice'>The printing press hums as it produces [B.name].</span>")

/obj/machinery/printingpress/proc/print_justice(mob/user)
	// Creates a static book (Tome of Justice)
	var/obj/item/book/rogue/law/B = new(src)
	output_item = B
	visible_message("<span class='notice'>[src] hums as it produces [B.name].</span>")

/obj/machinery/printingpress/proc/print_manuscript(mob/user, id)
	output_item = new /obj/item/book/rogue/playerbook(src, FALSE, null, null, id)

/obj/machinery/printingpress/proc/choose_search_parameters(mob/user)
	var/search_title = input(user, "Enter the title (optional):") as text|null
	var/search_author = input(user, "Enter the author (optional):") as text|null
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	search_manuscripts(user, search_title, search_author)

/obj/machinery/printingpress/proc/search_manuscripts(mob/user, search_title, search_author)
	var/list/available_books = SSlibrarian.pull_player_book_titles()
	if(isnull(available_books))
		to_chat(user, span_warning("The book archive index is unavailable. Please notify an administrator."))
		return
	var/dat = "<h3>Book Search Results:</h3><br>"
	dat += "<table><tr><th>Title</th><th>Author</th><th>Written</th><th>Print</th></tr>"
	var/matches = 0
	for(var/filename in available_books)
		var/list/book = SSlibrarian.file2playerbook(filename)
		if(!book["book_title"])
			continue
		if(search_title && !findtext(book["book_title"], search_title))
			continue
		if(search_author && !findtext(book["author"], search_author))
			continue
		matches++
		dat += "<tr><td>[player_archive_display_text(book["book_title"])]</td><td>[player_archive_display_text(book["author"])]</td><td>[player_archive_display_text(book["ic_date"])]</td><td><a href='byond://?src=[REF(src)];print=1;filename=[url_encode(filename)]'>Print</a></td></tr>"

	if(!matches)
		dat += "<tr><td colspan='4'>No results found.</td></tr>"

	dat += "</table>"
	var/datum/browser/popup = new(user, "printing press", "Which book to print?", 460, 500)
	popup.set_content(dat)
	popup.open()

/obj/machinery/printingpress/Topic(href, href_list)
	. = ..()
	if(!usr || !usr.canUseTopic(src, BE_CLOSE))
		return
	if("print" in href_list)
		start_printing(usr, "archive", href_list["filename"])

#undef PRINTER_COOLDOWN
#undef PRINTING_TIME
