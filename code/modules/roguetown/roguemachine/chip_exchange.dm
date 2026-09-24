/datum/casino_ledger
	var/casino_name = "Unnamed Gaming House"
	var/exchange_rate = 1
	var/reserve_mammons = 0
	var/outstanding_units = 0
	var/datum/weakref/owner_ref
	var/list/authorized_dealers = list()
	var/list/linked_tables = list()

/datum/casino_ledger/New(mob/living/owner)
	. = ..()
	if(owner)
		owner_ref = WEAKREF(owner)
		casino_name = "[owner.real_name]'s Gaming House"
		authorized_dealers[owner] = TRUE

/datum/casino_ledger/proc/is_owner(mob/user)
	return user && owner_ref?.resolve() == user

/datum/casino_ledger/proc/is_authorized_dealer(mob/user)
	return user && authorized_dealers[user]

/datum/casino_ledger/proc/set_dealer(mob/living/user, authorized)
	if(!user)
		return FALSE
	if(authorized)
		authorized_dealers[user] = TRUE
	else if(!is_owner(user))
		authorized_dealers -= user
	return TRUE

/datum/casino_ledger/proc/get_liability()
	return outstanding_units * exchange_rate

/datum/casino_ledger/proc/get_owner_equity()
	return max(0, reserve_mammons - get_liability())

/datum/casino_ledger/proc/can_set_rate(new_rate)
	return outstanding_units <= 0 && reserve_mammons <= 0 && new_rate >= 1

/datum/casino_ledger/proc/set_rate(new_rate)
	new_rate = round(new_rate)
	if(!can_set_rate(new_rate))
		return FALSE
	exchange_rate = new_rate
	return TRUE

/datum/casino_ledger/proc/back_units(units)
	units = round(units)
	var/cost = units * exchange_rate
	if(units <= 0 || reserve_mammons < get_liability() + cost)
		return FALSE
	outstanding_units += units
	return TRUE

/datum/casino_ledger/proc/redeem_units(units)
	units = round(units)
	var/payout = units * exchange_rate
	if(units <= 0 || outstanding_units < units || reserve_mammons < payout)
		return 0
	outstanding_units -= units
	reserve_mammons -= payout
	return payout

/datum/casino_ledger/proc/adjust_outstanding_units(delta)
	var/new_total = outstanding_units + round(delta)
	if(new_total < 0 || new_total * exchange_rate > reserve_mammons)
		return FALSE
	outstanding_units = new_total
	return TRUE

/datum/casino_ledger/proc/spawn_chips(units, atom/location, mob/user)
	units = round(units)
	if(units <= 0)
		return
	var/list/denominations = list(
		"100" = /obj/item/casino_chip/hundred,
		"25" = /obj/item/casino_chip/twenty_five,
		"10" = /obj/item/casino_chip/ten,
		"5" = /obj/item/casino_chip/five,
		"1" = /obj/item/casino_chip,
	)
	for(var/denomination_key in denominations)
		var/denomination = text2num(denomination_key)
		var/count = floor(units / denomination)
		units %= denomination
		while(count > 0)
			var/stack_size = min(count, 20)
			var/chip_type = denominations[denomination_key]
			var/obj/item/casino_chip/chips = new chip_type(location, stack_size, src)
			if(user)
				user.put_in_hands(chips)
			count -= stack_size

/obj/structure/roguemachine/chip_exchange
	name = "chip exchange"
	desc = "A cashier's machine for exchanging mammons and gaming chips."
	icon = 'icons/roguetown/misc/machines.dmi'
	icon_state = "lottery"
	density = TRUE
	anchored = TRUE
	var/datum/casino_ledger/ledger
	var/list/pending_credit = list()

/obj/structure/roguemachine/chip_exchange/attack_hand(mob/living/user)
	ui_interact(user)

/obj/structure/roguemachine/chip_exchange/attackby(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/roguecoin))
		var/obj/item/roguecoin/coins = item
		pending_credit[user] = (pending_credit[user] || 0) + coins.get_real_price()
		qdel(coins)
		SStgui.update_uis(src)
		return
	if(istype(item, /obj/item/casino_chip))
		try_redeem_chips(item, user)
		return
	return ..()

/obj/structure/roguemachine/chip_exchange/proc/try_redeem_chips(obj/item/casino_chip/chips, mob/living/user)
	if(!ledger || chips.get_issuer() != ledger)
		to_chat(user, span_warning("These chips belong to another gaming house."))
		return FALSE
	var/payout = ledger.redeem_units(chips.get_total_units())
	if(!payout)
		to_chat(user, span_warning("The cashier cannot honor these chips."))
		return FALSE
	qdel(chips)
	budget2change(payout, user)
	SStgui.update_uis(src)
	return TRUE

/obj/structure/roguemachine/chip_exchange/proc/try_buy_chips(mob/living/user, denomination, count)
	if(!ledger)
		return FALSE
	denomination = round(denomination)
	count = round(count)
	if(!(denomination in list(1, 5, 10, 25, 100)) || count <= 0)
		return FALSE
	var/units = denomination * count
	var/cost = units * ledger.exchange_rate
	if((pending_credit[user] || 0) < cost)
		return FALSE
	ledger.reserve_mammons += cost
	if(!ledger.back_units(units))
		ledger.reserve_mammons -= cost
		return FALSE
	pending_credit[user] -= cost
	ledger.spawn_chips(units, drop_location(), user)
	return TRUE

/obj/structure/roguemachine/chip_exchange/proc/refund_credit(mob/living/user)
	var/refund = pending_credit[user] || 0
	if(refund <= 0)
		return FALSE
	pending_credit[user] = 0
	budget2change(refund, user)
	return TRUE

/obj/structure/roguemachine/chip_exchange/ui_state(mob/user)
	return GLOB.human_adjacent_state

/obj/structure/roguemachine/chip_exchange/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ChipExchange")
		ui.open()

/obj/structure/roguemachine/chip_exchange/ui_data(mob/user)
	var/list/data = list(
		"claimed" = ledger ? TRUE : FALSE,
		"is_owner" = ledger?.is_owner(user) ? TRUE : FALSE,
		"casino_name" = ledger?.casino_name || "Unclaimed Gaming House",
		"exchange_rate" = ledger?.exchange_rate || 1,
		"reserve" = ledger?.reserve_mammons || 0,
		"liability" = ledger?.get_liability() || 0,
		"equity" = ledger?.get_owner_equity() || 0,
		"outstanding_units" = ledger?.outstanding_units || 0,
		"pending_credit" = pending_credit[user] || 0,
	)
	var/list/nearby_people = list()
	var/list/nearby_tables = list()
	if(ledger?.is_owner(user))
		for(var/mob/living/person in range(2, src))
			nearby_people += list(list(
				"ref" = REF(person),
				"name" = person.real_name,
				"authorized" = ledger.is_authorized_dealer(person) ? TRUE : FALSE,
			))
		for(var/obj/structure/table/vtable/roulette/table in range(2, src))
			nearby_tables += list(list(
				"ref" = REF(table),
				"name" = table.name,
				"linked" = table.ledger == ledger ? TRUE : FALSE,
			))
	data["nearby_people"] = nearby_people
	data["nearby_tables"] = nearby_tables
	return data

/obj/structure/roguemachine/chip_exchange/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	var/mob/living/user = usr
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE))
		return TRUE
	switch(action)
		if("claim")
			if(!ledger)
				ledger = new(user)
		if("set_rate")
			if(ledger?.is_owner(user))
				ledger.set_rate(text2num(params["rate"]))
		if("fund_house")
			if(ledger?.is_owner(user))
				var/amount = pending_credit[user] || 0
				if(amount > 0)
					pending_credit[user] = 0
					ledger.reserve_mammons += amount
		if("withdraw_equity")
			if(ledger?.is_owner(user))
				var/amount = min(round(text2num(params["amount"])), ledger.get_owner_equity())
				if(amount > 0)
					ledger.reserve_mammons -= amount
					budget2change(amount, user)
		if("authorize_dealer")
			if(ledger?.is_owner(user))
				var/mob/living/dealer = locate(params["ref"])
				if(dealer && dealer.z == z && get_dist(dealer, src) <= 2)
					ledger.set_dealer(dealer, !ledger.is_authorized_dealer(dealer))
		if("link_table")
			if(ledger?.is_owner(user))
				var/obj/structure/table/vtable/roulette/table = locate(params["ref"])
				if(table && table.z == z && get_dist(table, src) <= 2)
					table.link_ledger(ledger)
		if("buy")
			try_buy_chips(user, text2num(params["denomination"]), text2num(params["count"]))
		if("refund")
			refund_credit(user)
		else
			return FALSE
	SStgui.update_uis(src)
	return TRUE
