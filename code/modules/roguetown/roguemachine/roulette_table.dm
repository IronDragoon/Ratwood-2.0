#define ROULETTE_BET_STRAIGHT "straight"
#define ROULETTE_BET_RED "red"
#define ROULETTE_BET_BLACK "black"
#define ROULETTE_BET_ODD "odd"
#define ROULETTE_BET_EVEN "even"
#define ROULETTE_BET_LOW "low"
#define ROULETTE_BET_HIGH "high"
#define ROULETTE_BET_DOZEN "dozen"
#define ROULETTE_BET_COLUMN "column"

#define ROULETTE_COLOR_GREEN "green"
#define ROULETTE_COLOR_RED "red"
#define ROULETTE_COLOR_BLACK "black"

/proc/roulette_number_color(number)
	if(number == 0)
		return ROULETTE_COLOR_GREEN
	if(number in list(1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36))
		return ROULETTE_COLOR_RED
	return ROULETTE_COLOR_BLACK

/datum/roulette_bet
	var/bet_type
	var/selection
	var/amount

/datum/roulette_bet/New(new_bet_type, new_selection, new_amount)
	. = ..()
	bet_type = new_bet_type
	selection = new_selection
	amount = round(new_amount)

/datum/roulette_bet/proc/is_valid()
	if(amount <= 0)
		return FALSE
	switch(bet_type)
		if(ROULETTE_BET_STRAIGHT)
			return selection >= 0 && selection <= 36
		if(ROULETTE_BET_RED, ROULETTE_BET_BLACK, ROULETTE_BET_ODD, ROULETTE_BET_EVEN, ROULETTE_BET_LOW, ROULETTE_BET_HIGH)
			return TRUE
		if(ROULETTE_BET_DOZEN, ROULETTE_BET_COLUMN)
			return selection >= 1 && selection <= 3
	return FALSE

/datum/roulette_bet/proc/is_winner(result)
	if(!is_valid() || result < 0 || result > 36)
		return FALSE
	switch(bet_type)
		if(ROULETTE_BET_STRAIGHT)
			return result == selection
		if(ROULETTE_BET_RED)
			return roulette_number_color(result) == ROULETTE_COLOR_RED
		if(ROULETTE_BET_BLACK)
			return roulette_number_color(result) == ROULETTE_COLOR_BLACK
		if(ROULETTE_BET_ODD)
			return result && (result % 2)
		if(ROULETTE_BET_EVEN)
			return result && !(result % 2)
		if(ROULETTE_BET_LOW)
			return result >= 1 && result <= 18
		if(ROULETTE_BET_HIGH)
			return result >= 19 && result <= 36
		if(ROULETTE_BET_DOZEN)
			return result && CEILING(result / 12, 1) == selection
		if(ROULETTE_BET_COLUMN)
			return result && (((result - 1) % 3) + 1) == selection
	return FALSE

/datum/roulette_bet/proc/get_total_return(result)
	if(!is_winner(result))
		return 0
	switch(bet_type)
		if(ROULETTE_BET_STRAIGHT)
			return amount * 36
		if(ROULETTE_BET_DOZEN, ROULETTE_BET_COLUMN)
			return amount * 3
	return amount * 2

/proc/roulette_total_return_for_result(list/bets, result)
	var/total = 0
	for(var/datum/roulette_bet/bet as anything in bets)
		total += bet.get_total_return(result)
	return total

/proc/roulette_worst_case_return(list/bets)
	var/worst_case = 0
	for(var/result in 0 to 36)
		worst_case = max(worst_case, roulette_total_return_for_result(bets, result))
	return worst_case

#define ROULETTE_PHASE_IDLE "idle"
#define ROULETTE_PHASE_BETTING "betting"
#define ROULETTE_PHASE_FINAL "final"
#define ROULETTE_PHASE_READY "ready"
#define ROULETTE_PHASE_SPINNING "spinning"
#define ROULETTE_PHASE_RESULT "result"

/datum/roulette_player_wagers
	var/datum/weakref/player_ref
	var/list/bets = list()

/datum/roulette_player_wagers/New(mob/living/player)
	. = ..()
	player_ref = WEAKREF(player)

/datum/roulette_player_wagers/proc/get_total_stake()
	var/total = 0
	for(var/datum/roulette_bet/bet as anything in bets)
		total += bet.amount
	return total

/datum/roulette_player_wagers/proc/get_total_return(result)
	return roulette_total_return_for_result(bets, result)

/obj/structure/table/vtable/roulette
	name = "roulette table"
	desc = "An ancient gaming table fitted with a single-zero wheel."
	icon_state = "vtable"
	/// Mapmaker ID used to link this table to a chip exchange at roundstart.
	var/exid = 0
	var/datum/casino_ledger/ledger
	var/datum/weakref/extension_ref
	var/datum/weakref/dealer_ref
	var/phase = ROULETTE_PHASE_IDLE
	var/minimum_bet = 1
	var/final_betting_seconds = 5
	var/phase_ends_at = 0
	var/round_id = 0
	var/result_number
	var/list/player_wagers = list()
	var/removing_pair = FALSE
	var/is_extension = FALSE
	var/extension_dir = EAST

/obj/structure/table/vtable/roulette/Initialize(mapload)
	. = ..()
	if(is_extension)
		return
	if(mapload)
		return INITIALIZE_HINT_LATELOAD
	if(!ensure_extension())
		return INITIALIZE_HINT_QDEL

/obj/structure/table/vtable/roulette/LateInitialize()
	if(!ensure_extension())
		qdel(src)

/obj/structure/table/vtable/roulette/proc/ensure_extension()
	var/turf/extension_turf = get_step(src, EAST)
	if(extension_dir != EAST)
		extension_turf = get_step(src, extension_dir)
	if(!extension_turf || extension_turf.density)
		return FALSE
	var/obj/structure/table/vtable/roulette/extension/other_half = locate() in extension_turf
	if(other_half)
		var/obj/structure/table/vtable/roulette/existing_controller = other_half.controller_ref?.resolve()
		if(existing_controller && existing_controller != src)
			return FALSE
		other_half.controller_ref = WEAKREF(src)
		other_half.dir = dir
		extension_ref = WEAKREF(other_half)
		return TRUE
	for(var/atom/movable/obstacle in extension_turf)
		if(obstacle.density)
			return FALSE
	other_half = new(extension_turf, src)
	other_half.dir = dir
	extension_ref = WEAKREF(other_half)
	return TRUE

/obj/structure/table/vtable/roulette/proc/get_controller()
	if(is_extension)
		return null
	return src

/obj/structure/table/vtable/roulette/proc/is_within_link_range(atom/source, link_range)
	if(!source || source.z != z)
		return FALSE
	if(get_dist(src, source) <= link_range)
		return TRUE
	var/obj/structure/table/vtable/roulette/extension/other_half = extension_ref?.resolve()
	return other_half && other_half.z == source.z && get_dist(other_half, source) <= link_range

/obj/structure/table/vtable/roulette/roundstart

/obj/structure/table/vtable/roulette/roundstart/north
	dir = NORTH
	extension_dir = NORTH

/obj/structure/table/vtable/roulette/roundstart/south
	dir = SOUTH
	extension_dir = SOUTH

/obj/structure/table/vtable/roulette/roundstart/east
	dir = EAST
	extension_dir = EAST

/obj/structure/table/vtable/roulette/roundstart/west
	dir = WEST
	extension_dir = WEST

/obj/structure/table/vtable/roulette/Destroy()
	if(!removing_pair && has_active_wagers())
		return QDEL_HINT_LETMELIVE
	removing_pair = TRUE
	var/obj/structure/table/vtable/roulette/extension/other_half = extension_ref?.resolve()
	extension_ref = null
	if(other_half && !QDELETED(other_half))
		other_half.controller_ref = null
		qdel(other_half)
	if(ledger)
		ledger.linked_tables -= src
	ledger = null
	return ..()

/obj/structure/table/vtable/roulette/deconstruct(disassembled = TRUE, wrench_disassembly = 0)
	if(has_active_wagers())
		return
	return ..()

/obj/structure/table/vtable/roulette/proc/link_ledger(datum/casino_ledger/new_ledger)
	if(!new_ledger || has_active_wagers() || phase != ROULETTE_PHASE_IDLE)
		return FALSE
	if(ledger)
		ledger.linked_tables -= src
	ledger = new_ledger
	ledger.linked_tables[src] = TRUE
	return TRUE

/obj/structure/table/vtable/roulette/proc/get_dealer()
	return dealer_ref?.resolve()

/obj/structure/table/vtable/roulette/proc/is_dealer(mob/user)
	return user && get_dealer() == user

/obj/structure/table/vtable/roulette/proc/has_active_wagers()
	for(var/mob/player in player_wagers)
		var/datum/roulette_player_wagers/wagers = player_wagers[player]
		if(length(wagers?.bets))
			return TRUE
	return FALSE

/obj/structure/table/vtable/roulette/proc/get_all_bets(datum/roulette_bet/extra_bet)
	var/list/all_bets = list()
	for(var/mob/player in player_wagers)
		var/datum/roulette_player_wagers/wagers = player_wagers[player]
		all_bets += wagers.bets
	if(extra_bet)
		all_bets += extra_bet
	return all_bets

/obj/structure/table/vtable/roulette/proc/get_total_stake(datum/roulette_bet/extra_bet)
	var/total = 0
	for(var/datum/roulette_bet/bet as anything in get_all_bets(extra_bet))
		total += bet.amount
	return total

/obj/structure/table/vtable/roulette/proc/can_cover_bet(datum/roulette_bet/extra_bet)
	if(!ledger || !extra_bet?.is_valid())
		return FALSE
	var/list/all_bets = get_all_bets(extra_bet)
	var/projected_units = ledger.outstanding_units - get_total_stake(extra_bet) + roulette_worst_case_return(all_bets)
	return projected_units >= 0 && projected_units * ledger.exchange_rate <= ledger.reserve_mammons

/obj/structure/table/vtable/roulette/proc/try_place_bet(mob/living/user, bet_type, selection, chip_count)
	if(phase != ROULETTE_PHASE_BETTING && phase != ROULETTE_PHASE_FINAL)
		return FALSE
	var/obj/item/casino_chip/chips = user.get_active_held_item()
	if(!istype(chips) || chips.get_issuer() != ledger)
		return FALSE
	chip_count = clamp(round(chip_count), 1, chips.quantity)
	var/units = chips.unit_value * chip_count
	if(units < minimum_bet)
		return FALSE
	var/datum/roulette_bet/bet = new(bet_type, round(selection), units)
	if(!can_cover_bet(bet))
		qdel(bet)
		return FALSE
	var/datum/roulette_player_wagers/wagers = player_wagers[user]
	if(!wagers)
		wagers = new(user)
		player_wagers[user] = wagers
	wagers.bets += bet
	chips.set_quantity(chips.quantity - chip_count)
	if(chips.quantity <= 0)
		user.doUnEquip(chips)
		qdel(chips)
	return TRUE

/obj/structure/table/vtable/roulette/proc/remove_bet(mob/living/user, index)
	if(phase != ROULETTE_PHASE_BETTING && phase != ROULETTE_PHASE_FINAL)
		return FALSE
	var/datum/roulette_player_wagers/wagers = player_wagers[user]
	index = round(index)
	if(!wagers || index < 1 || index > length(wagers.bets))
		return FALSE
	var/datum/roulette_bet/bet = wagers.bets[index]
	wagers.bets.Cut(index, index + 1)
	ledger.spawn_chips(bet.amount, drop_location(), user)
	qdel(bet)
	return TRUE

/obj/structure/table/vtable/roulette/proc/start_final_betting()
	if(phase != ROULETTE_PHASE_BETTING || !has_active_wagers())
		return FALSE
	phase = ROULETTE_PHASE_FINAL
	phase_ends_at = world.time + final_betting_seconds SECONDS
	var/closing_round = round_id
	addtimer(CALLBACK(src, PROC_REF(finish_final_betting), closing_round), final_betting_seconds SECONDS)
	return TRUE

/obj/structure/table/vtable/roulette/proc/finish_final_betting(expected_round)
	if(expected_round != round_id || phase != ROULETTE_PHASE_FINAL)
		return
	phase = ROULETTE_PHASE_READY
	phase_ends_at = 0
	SStgui.update_uis(src)

/obj/structure/table/vtable/roulette/proc/spin()
	if(phase != ROULETTE_PHASE_READY || !has_active_wagers())
		return FALSE
	phase = ROULETTE_PHASE_SPINNING
	result_number = rand(0, 36)
	phase_ends_at = world.time + 3 SECONDS
	var/spinning_round = round_id
	addtimer(CALLBACK(src, PROC_REF(resolve_spin), spinning_round), 3 SECONDS)
	return TRUE

/obj/structure/table/vtable/roulette/proc/resolve_spin(expected_round)
	if(expected_round != round_id || phase != ROULETTE_PHASE_SPINNING)
		return
	var/total_stake = get_total_stake()
	var/total_return = roulette_total_return_for_result(get_all_bets(), result_number)
	if(!ledger.adjust_outstanding_units(total_return - total_stake))
		abort_round()
		return
	for(var/mob/player in player_wagers)
		var/datum/roulette_player_wagers/wagers = player_wagers[player]
		var/payout = wagers.get_total_return(result_number)
		if(payout > 0)
			var/mob/living/recipient = wagers.player_ref?.resolve()
			ledger.spawn_chips(payout, recipient ? get_turf(recipient) : drop_location(), recipient)
		for(var/datum/roulette_bet/bet as anything in wagers.bets)
			qdel(bet)
		wagers.bets.Cut()
	player_wagers = list()
	phase = ROULETTE_PHASE_RESULT
	phase_ends_at = 0
	SStgui.update_uis(src)

/obj/structure/table/vtable/roulette/proc/abort_round()
	for(var/mob/player in player_wagers)
		var/datum/roulette_player_wagers/wagers = player_wagers[player]
		var/mob/living/recipient = wagers.player_ref?.resolve()
		ledger?.spawn_chips(wagers.get_total_stake(), recipient ? get_turf(recipient) : drop_location(), recipient)
		for(var/datum/roulette_bet/bet as anything in wagers.bets)
			qdel(bet)
		wagers.bets.Cut()
	player_wagers = list()
	phase = ROULETTE_PHASE_IDLE
	phase_ends_at = 0
	round_id++
	SStgui.update_uis(src)

/obj/structure/table/vtable/roulette/attack_hand(mob/living/user)
	ui_interact(user)

/obj/structure/table/vtable/roulette/ui_state(mob/user)
	return GLOB.human_adjacent_state

/obj/structure/table/vtable/roulette/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RouletteTable")
		ui.open()

/obj/structure/table/vtable/roulette/ui_data(mob/user)
	var/list/my_bets = list()
	var/datum/roulette_player_wagers/wagers = player_wagers[user]
	if(wagers)
		var/index = 0
		for(var/datum/roulette_bet/bet as anything in wagers.bets)
			index++
			my_bets += list(list("index" = index, "type" = bet.bet_type, "selection" = bet.selection, "amount" = bet.amount))
	var/list/board_totals = list()
	for(var/datum/roulette_bet/bet as anything in get_all_bets())
		var/key = "[bet.bet_type]-[bet.selection]"
		board_totals[key] = (board_totals[key] || 0) + bet.amount
	var/obj/item/casino_chip/held_chips = user.get_active_held_item()
	var/mob/living/current_dealer = get_dealer()
	var/dealer_name = ""
	if(current_dealer)
		dealer_name = current_dealer.name
	return list(
		"linked" = ledger ? TRUE : FALSE,
		"casino_name" = ledger?.casino_name || "Unlinked Table",
		"phase" = phase,
		"seconds_remaining" = max(0, round((phase_ends_at - world.time) / 10)),
		"is_dealer" = is_dealer(user) ? TRUE : FALSE,
		"can_deal" = ledger?.is_authorized_dealer(user) ? TRUE : FALSE,
		"dealer_name" = dealer_name,
		"minimum_bet" = minimum_bet,
		"final_betting_seconds" = final_betting_seconds,
		"result_number" = phase == ROULETTE_PHASE_RESULT ? result_number : null,
		"result_color" = phase == ROULETTE_PHASE_RESULT ? roulette_number_color(result_number) : null,
		"my_bets" = my_bets,
		"board_totals" = board_totals,
		"held_chip_value" = istype(held_chips) && held_chips.get_issuer() == ledger ? held_chips.unit_value : 0,
		"held_chip_count" = istype(held_chips) && held_chips.get_issuer() == ledger ? held_chips.quantity : 0,
	)

/obj/structure/table/vtable/roulette/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	var/mob/living/user = usr
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE))
		return TRUE
	switch(action)
		if("claim_dealer")
			var/mob/living/current_dealer = get_dealer()
			if(ledger?.is_authorized_dealer(user) && (!current_dealer || !current_dealer.client))
				dealer_ref = WEAKREF(user)
				if(phase == ROULETTE_PHASE_IDLE)
					phase = ROULETTE_PHASE_BETTING
					round_id++
		if("set_rules")
			if(is_dealer(user) && !has_active_wagers() && phase == ROULETTE_PHASE_BETTING)
				minimum_bet = clamp(round(text2num(params["minimum_bet"])), 1, 1000)
				final_betting_seconds = clamp(round(text2num(params["final_seconds"])), 1, 30)
		if("place_bet")
			try_place_bet(user, params["bet_type"], text2num(params["selection"]), text2num(params["chip_count"]))
		if("remove_bet")
			remove_bet(user, text2num(params["index"]))
		if("close_bets")
			if(is_dealer(user))
				start_final_betting()
		if("spin")
			if(is_dealer(user))
				spin()
		if("next_round")
			if(is_dealer(user) && phase == ROULETTE_PHASE_RESULT)
				phase = ROULETTE_PHASE_BETTING
				result_number = null
				round_id++
		if("end_game")
			if(is_dealer(user) && !has_active_wagers())
				dealer_ref = null
				phase = ROULETTE_PHASE_IDLE
		else
			return FALSE
	SStgui.update_uis(src)
	return TRUE

/obj/structure/table/vtable/roulette/extension
	name = "roulette table"
	icon_state = "vtable2"
	is_extension = TRUE
	var/datum/weakref/controller_ref

/obj/structure/table/vtable/roulette/extension/Initialize(mapload, obj/structure/table/vtable/roulette/controller)
	. = ..()
	if(controller)
		controller_ref = WEAKREF(controller)

/obj/structure/table/vtable/roulette/extension/get_controller()
	return controller_ref?.resolve()

/obj/structure/table/vtable/roulette/extension/attack_hand(mob/living/user)
	var/obj/structure/table/vtable/roulette/controller = controller_ref?.resolve()
	controller?.ui_interact(user)

/obj/structure/table/vtable/roulette/extension/deconstruct(disassembled = TRUE, wrench_disassembly = 0)
	var/obj/structure/table/vtable/roulette/controller = controller_ref?.resolve()
	if(controller?.has_active_wagers())
		return
	return ..()

/obj/structure/table/vtable/roulette/extension/Destroy()
	var/obj/structure/table/vtable/roulette/controller = controller_ref?.resolve()
	if(controller?.has_active_wagers())
		return QDEL_HINT_LETMELIVE
	controller_ref = null
	if(controller && !controller.removing_pair)
		controller.removing_pair = TRUE
		qdel(controller)
	return ..()
