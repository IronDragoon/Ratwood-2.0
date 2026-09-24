/datum/unit_test/roulette_outcomes

/datum/unit_test/roulette_outcomes/Run()
	TEST_ASSERT_EQUAL(roulette_number_color(0), ROULETTE_COLOR_GREEN, "Zero should be green.")
	TEST_ASSERT_EQUAL(roulette_number_color(1), ROULETTE_COLOR_RED, "One should be red.")
	TEST_ASSERT_EQUAL(roulette_number_color(2), ROULETTE_COLOR_BLACK, "Two should be black.")

	var/datum/roulette_bet/straight = new(ROULETTE_BET_STRAIGHT, 17, 5)
	TEST_ASSERT(straight.is_winner(17), "A straight bet should cover its selected number.")
	TEST_ASSERT_EQUAL(straight.get_total_return(17), 180, "A straight win should return stake plus 35:1 winnings.")
	TEST_ASSERT_EQUAL(straight.get_total_return(18), 0, "A straight bet should lose on other numbers.")

	var/datum/roulette_bet/red = new(ROULETTE_BET_RED, null, 5)
	TEST_ASSERT(red.is_winner(1), "A red bet should win on red numbers.")
	TEST_ASSERT(!red.is_winner(0), "Outside bets should lose on zero.")
	TEST_ASSERT_EQUAL(red.get_total_return(1), 10, "An even-money win should return twice the stake.")

	var/datum/roulette_bet/dozen = new(ROULETTE_BET_DOZEN, 2, 5)
	TEST_ASSERT(dozen.is_winner(13), "The second dozen should cover 13.")
	TEST_ASSERT(dozen.is_winner(24), "The second dozen should cover 24.")
	TEST_ASSERT(!dozen.is_winner(25), "The second dozen should not cover 25.")
	TEST_ASSERT_EQUAL(dozen.get_total_return(13), 15, "A dozen win should return three times the stake.")

	var/datum/roulette_bet/column = new(ROULETTE_BET_COLUMN, 3, 5)
	TEST_ASSERT(column.is_winner(3), "The third column should cover 3.")
	TEST_ASSERT(column.is_winner(36), "The third column should cover 36.")
	TEST_ASSERT(!column.is_winner(35), "The third column should not cover 35.")

	var/list/bets = list(straight, red, dozen, column)
	TEST_ASSERT_EQUAL(roulette_total_return_for_result(bets, 17), 195, "Aggregate returns should include every winning bet.")
	TEST_ASSERT_EQUAL(roulette_worst_case_return(bets), 195, "Worst-case liability should scan all 37 outcomes.")

/datum/unit_test/casino_ledger

/datum/unit_test/casino_ledger/Run()
	var/datum/casino_ledger/ledger = new()
	TEST_ASSERT(ledger.set_rate(2), "An empty casino should allow its exchange rate to change.")
	ledger.reserve_mammons = 200
	TEST_ASSERT(ledger.back_units(50), "A funded casino should back chip issuance.")
	TEST_ASSERT_EQUAL(ledger.get_liability(), 100, "Chip liability should use the locked exchange rate.")
	TEST_ASSERT_EQUAL(ledger.get_owner_equity(), 100, "Only reserve above liabilities should be owner equity.")
	TEST_ASSERT(!ledger.set_rate(3), "A casino with circulating chips must lock its exchange rate.")
	TEST_ASSERT(!ledger.adjust_outstanding_units(51), "The ledger must reject unbacked chip winnings.")
	TEST_ASSERT(ledger.adjust_outstanding_units(50), "The ledger should allow winnings covered by its reserve.")
	TEST_ASSERT_EQUAL(ledger.redeem_units(25), 50, "Redemption should pay units at the locked rate.")
	TEST_ASSERT_EQUAL(ledger.reserve_mammons, 150, "Redemption should remove physical reserve value.")
	TEST_ASSERT_EQUAL(ledger.outstanding_units, 75, "Redemption should retire chip units.")

/datum/unit_test/roulette_table_liability

/datum/unit_test/roulette_table_liability/Run()
	var/obj/structure/table/vtable/roulette/table = new(run_loc_floor_bottom_left)
	var/obj/structure/table/vtable/roulette/extension/extension = table.extension_ref?.resolve()
	TEST_ASSERT_NOTNULL(extension, "A roulette controller should create its second table half.")
	table.extension_ref = null
	extension.controller_ref = null
	TEST_ASSERT(table.ensure_extension(), "A roulette controller should adopt a pre-placed extension.")
	TEST_ASSERT_EQUAL(table.extension_ref?.resolve(), extension, "Adoption should reuse the mapped extension rather than create another half.")
	TEST_ASSERT_EQUAL(extension.controller_ref?.resolve(), table, "The adopted extension should point back to its controller.")
	TEST_ASSERT_EQUAL(extension.get_controller(), table, "Both table halves should resolve to the same controller.")
	var/datum/casino_ledger/ledger = new()
	ledger.reserve_mammons = 100
	ledger.outstanding_units = 100
	TEST_ASSERT(table.link_ledger(ledger), "An idle roulette table should link to a casino ledger.")
	var/datum/roulette_bet/red_bet = new(ROULETTE_BET_RED, 0, 10)
	TEST_ASSERT(!table.can_cover_bet(red_bet), "A table should reject a wager whose winning return exceeds backing.")
	ledger.reserve_mammons += 10
	TEST_ASSERT(table.can_cover_bet(red_bet), "Additional house reserve should make the same wager solvent.")
	table.exid = 7
	var/obj/structure/roguemachine/chip_exchange/exchange = new(run_loc_floor_bottom_left)
	exchange.exid = 7
	exchange.link_mapped_tables()
	TEST_ASSERT_EQUAL(table.ledger, exchange.ledger, "Matching exchange IDs should link at roundstart.")
	TEST_ASSERT(exchange.ledger.linked_tables[table], "The linked ledger should record the table controller.")
	TEST_ASSERT(!exchange.ledger.linked_tables[extension], "The linked ledger should not record the extension as a second table.")
	qdel(red_bet)
	qdel(exchange)
	qdel(table)
