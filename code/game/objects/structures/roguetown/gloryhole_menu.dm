/*
	The gloryhole's side panel in the ERP menu.
	Left-clicking the gloryhole opens the user's sexcon menu with this panel beside it (see /datum/sex_controller/proc/show_ui()).
	What the panel offers depends on where the viewer stands, from get_role().
*/

/// Whether user can open the ERP menu on other, by the same rules as middle-dragging onto them
/obj/structure/bondage/gloryhole/proc/can_erp_with(mob/living/carbon/human/user, mob/living/carbon/human/other)
	if(!user.can_do_sex() || !user.client?.prefs?.sexable)
		return FALSE
	return !!other.client?.prefs?.sexable

/// Opens the ERP menu with this gloryhole's panel. It targets whoever is on the other side of the board, or the user themselves.
/obj/structure/bondage/gloryhole/proc/open_menu(mob/living/carbon/human/user)
	if(!ishuman(user) || !user.sexcon || get_role(user) == GLORYHOLE_ROLE_NONE)
		return
	if(!user.can_do_sex())
		to_chat(user, span_warning("I can't do this."))
		return
	if(!user.client?.prefs?.sexable)
		to_chat(user, span_warning("I don't want to use \the [src]. (Your ERP preference, in the options)"))
		return
	var/datum/sex_controller/controller = user.sexcon
	controller.gloryhole_panel = src
	if(!controller.current_action)
		var/mob/living/carbon/human/other = (get_role(user) == GLORYHOLE_ROLE_OCCUPANT) ? partner : get_occupant()
		controller.set_target((other && other != user && can_erp_with(user, other)) ? other : user)
	controller.show_ui()

/// Redraws the menus of everyone whose open menu shows this panel, plus `extra`
/obj/structure/bondage/gloryhole/proc/refresh_menus(mob/living/carbon/human/extra)
	var/list/viewers = list()
	for(var/mob/living/carbon/human/viewer in list(get_occupant(), partner, extra))
		viewers |= viewer
	for(var/mob/living/carbon/human/viewer as anything in viewers)
		var/datum/sex_controller/controller = viewer.sexcon
		if(controller?.menu_open && controller.gloryhole_panel == src)
			controller.show_ui()

/// A panel button. With a blocked_reason it's greyed out, and the reason shows on hover.
/obj/structure/bondage/gloryhole/proc/panel_link(label, task, blocked_reason)
	if(blocked_reason)
		return "<a class='linkOff' title='[html_encode(blocked_reason)]'>[label]</a>"
	return "<a href='?src=[REF(src)];task=[task]'>[label]</a>"

/// One button per placement the occupant has, with the current one highlighted
/obj/structure/bondage/gloryhole/proc/placement_buttons(mob/living/carbon/human/occupant, task)
	var/list/links = list()
	for(var/which in GLOB.gloryhole_placement_parts)
		if(!is_placement_offered(occupant, which))
			continue
		var/label = get_placement_label(which)
		if(which == placement)
			links += "<a class='linkOn'>[label]</a>"
		else
			links += panel_link(label, "[task];placement=[which]", get_placement_block_reason(occupant, which))
	return "<center>[links.Join(" ")]</center>"

/// The placements a free occupant offers, read-only, with the current one highlighted
/obj/structure/bondage/gloryhole/proc/placement_list(mob/living/carbon/human/occupant)
	var/list/entries = list()
	for(var/which in GLOB.gloryhole_placement_parts)
		if(which == GLORYHOLE_PLACEMENT_NEUTRAL || !is_placement_offered(occupant, which) || get_placement_block_reason(occupant, which))
			continue
		var/label = get_placement_label(which)
		entries += (which == placement) ? "<a class='linkOn'>[label]</a>" : label
	if(!length(entries))
		return "<center><i>Nothing on offer.</i></center>"
	return "<center>On offer: [entries.Join(", ")]</center>"

/obj/structure/bondage/gloryhole/proc/get_panel_html(mob/living/carbon/human/user)
	validate_placement()
	var/mob/living/carbon/human/occupant = get_occupant()
	var/pressed = get_placement_part_name(placement)
	var/list/dat = list("<center><b>[uppertext(name)]</b></center><br>")
	switch(get_role(user))
		if(GLORYHOLE_ROLE_OCCUPANT)
			if(occupant_restrained)
				if(placement == GLORYHOLE_PLACEMENT_NEUTRAL)
					dat += "<center>Nothing of mine is pressed against the hole.</center><br>"
				else
					dat += "<center>They've made me press my [pressed] to the hole.</center><br>"
				dat += "<center>[panel_link(struggling ? "Stop struggling" : "Struggle free", "struggle")]</center>"
			else
				dat += "<center><i>Press against the hole:</i></center>"
				dat += placement_buttons(occupant, "place")
				dat += "<br><center>[panel_link("Unbuckle", "unbuckle")]</center>"
		if(GLORYHOLE_ROLE_FRONT)
			if(partner != user)
				dat += "<center>[panel_link("Step up", "step_up", partner ? "Someone is already up against it." : null)]</center><br>"
			if(!occupant)
				dat += "<center>Nobody is on the other side.</center>"
			else
				if(placement == GLORYHOLE_PLACEMENT_NEUTRAL)
					dat += "<center>Nothing is pressed against the hole.</center><br>"
				else
					dat += "<center>A [pressed] is pressed against the hole.</center><br>"
				if(occupant_restrained)
					dat += "<center><i>Tell them to press against the hole:</i></center>"
					dat += placement_buttons(occupant, "command")
				else
					dat += placement_list(occupant)
				if(can_release(occupant))
					dat += "<br><center>[panel_link("Unbuckle them", "release")]</center>"
		if(GLORYHOLE_ROLE_BEHIND)
			if(occupant)
				dat += "<center>Someone is already in it.</center>"
			else
				dat += "<center>[panel_link("Buckle yourself in", "buckle_self")]</center>"
				var/mob/living/carbon/human/victim = get_buckle_candidate(user)
				if(victim)
					dat += "<center>[panel_link("Buckle [victim] in", "buckle_other")]</center>"
		else
			dat += "<center>[occupant ? "Someone is in it." : "It's empty."]</center>"
	return dat.Join()

/obj/structure/bondage/gloryhole/Topic(href, href_list)
	. = ..()
	var/mob/living/carbon/human/user = usr
	if(!istype(user) || user.stat != CONSCIOUS)
		return
	var/role = get_role(user)
	if(role == GLORYHOLE_ROLE_NONE)
		return
	switch(href_list["task"])
		if("buckle_self")
			try_buckle_self(user)
		if("buckle_other")
			try_buckle_other(user)
		if("step_up")
			step_up(user)
		if("place")
			if(role == GLORYHOLE_ROLE_OCCUPANT && !occupant_restrained)
				set_placement(href_list["placement"], user)
		if("command")
			var/mob/living/carbon/human/occupant = get_occupant()
			if(occupant && role == GLORYHOLE_ROLE_FRONT && occupant_restrained && set_placement(href_list["placement"], user))
				log_combat(user, occupant, "made them press their [get_placement_part_name(placement)] against a gloryhole")
		if("unbuckle")
			if(role == GLORYHOLE_ROLE_OCCUPANT && !occupant_restrained)
				user_unbuckle_mob(user, user)
		if("struggle")
			if(role == GLORYHOLE_ROLE_OCCUPANT)
				toggle_struggle(user)
		if("release")
			try_release(user)
	if(user.sexcon?.menu_open)
		user.sexcon.show_ui()
