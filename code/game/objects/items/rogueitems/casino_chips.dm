#define MAX_CASINO_CHIP_STACK 20

/obj/item/casino_chip
	name = "casino chip"
	desc = "A stamped gaming token redeemable at its issuing cashier."
	icon = 'icons/roguetown/items/valuable.dmi'
	icon_state = "a1"
	w_class = WEIGHT_CLASS_TINY
	dropshrink = 0.2
	drop_sound = 'sound/foley/coinphy (1).ogg'
	resistance_flags = FIRE_PROOF
	var/quantity = 1
	var/unit_value = 1
	var/datum/weakref/issuer_ref

/obj/item/casino_chip/Initialize(mapload, chip_amount, datum/casino_ledger/issuer)
	. = ..()
	if(chip_amount >= 1)
		quantity = min(floor(chip_amount), MAX_CASINO_CHIP_STACK)
	if(issuer)
		issuer_ref = WEAKREF(issuer)
	update_icon()

/obj/item/casino_chip/proc/get_issuer()
	return issuer_ref?.resolve()

/obj/item/casino_chip/proc/get_total_units()
	return unit_value * quantity

/obj/item/casino_chip/Crossed(atom/movable/crossing)
	. = ..()
	if(istype(crossing, /obj/item/casino_chip) && isturf(loc))
		var/obj/item/casino_chip/other = crossing
		merge(other)

/obj/item/casino_chip/proc/set_quantity(new_quantity)
	quantity = new_quantity
	update_icon()

/obj/item/casino_chip/examine(mob/user)
	. = ..()
	var/datum/casino_ledger/issuer = get_issuer()
	. += span_info("It represents [unit_value] chip unit\s and this stack contains [quantity].")
	if(issuer)
		. += span_info("[issuer.casino_name] redeems each unit for [issuer.exchange_rate] mammon\s.")
	else
		. += span_warning("Its issuing house no longer exists.")

/obj/item/casino_chip/proc/can_merge(obj/item/casino_chip/other)
	return other && other.type == type && other.get_issuer() == get_issuer()

/obj/item/casino_chip/proc/merge(obj/item/casino_chip/other, mob/user)
	if(!can_merge(other))
		return FALSE
	var/amount = min(other.quantity, MAX_CASINO_CHIP_STACK - quantity)
	if(amount <= 0)
		return FALSE
	set_quantity(quantity + amount)
	other.set_quantity(other.quantity - amount)
	if(other.quantity <= 0)
		if(user)
			user.doUnEquip(other)
		qdel(other)
	playsound(loc, 'sound/foley/coins1.ogg', 100, TRUE, -2)
	return TRUE

/obj/item/casino_chip/attackby(obj/item/item, mob/user)
	if(istype(item, /obj/item/casino_chip))
		var/obj/item/casino_chip/other = item
		if(item_flags & IN_STORAGE)
			merge(other, user)
		else
			other.merge(src, user)
		return
	return ..()

/obj/item/casino_chip/attack_right(mob/user)
	if(user.get_active_held_item() || quantity <= 1)
		return ..()
	var/obj/item/casino_chip/chip = new type(null, 1, get_issuer())
	set_quantity(quantity - 1)
	user.put_in_hands(chip)
	playsound(loc, 'sound/foley/coinphy (2).ogg', 100, TRUE, -2)

/obj/item/casino_chip/attack_hand(mob/user)
	if(user.get_inactive_held_item() != src || quantity <= 1)
		return ..()
	var/amount = input(user, "How many chips do you want to split?", null, round(quantity / 2)) as null|num
	if(QDELETED(user) || QDELETED(src) || !user.Adjacent(src))
		return
	amount = clamp(round(amount), 0, quantity)
	if(!amount || amount >= quantity)
		return ..()
	var/obj/item/casino_chip/chip = new type(null, amount, get_issuer())
	set_quantity(quantity - amount)
	user.put_in_hands(chip)
	playsound(loc, 'sound/foley/coins1.ogg', 100, TRUE, -2)

/obj/item/casino_chip/update_icon()
	. = ..()
	name = quantity == 1 ? initial(name) : "[initial(name)]s"
	desc = initial(desc)
	dropshrink = quantity == 1 ? 0.2 : 1

/obj/item/casino_chip/five
	name = "blue casino chip"
	color = "#4f7db8"
	unit_value = 5

/obj/item/casino_chip/ten
	name = "red casino chip"
	color = "#a8443f"
	unit_value = 10

/obj/item/casino_chip/twenty_five
	name = "green casino chip"
	color = "#4f7f55"
	unit_value = 25

/obj/item/casino_chip/hundred
	name = "black casino chip"
	color = "#343434"
	unit_value = 100

#undef MAX_CASINO_CHIP_STACK
