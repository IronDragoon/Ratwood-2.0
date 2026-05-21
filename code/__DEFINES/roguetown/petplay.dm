#define PETPLAY_HARDMODE_DISABLED 0
#define PETPLAY_HARDMODE_ENABLED 1

/// Root directory for all pet-play flavor-text JSON banks.
/// Used by pick_petplay_string() and anywhere a raw strings() call targets the pet-play string dir.
#define PETPLAY_STRINGS_PATH "modular/code/game/objects/items/lewd/petplay/strings"

/// Picks a random entry from a pet-play string bank.
/// Usage: pick_petplay_string("petplay_lock_messages.json", "petplay_lock_denial")
#define pick_petplay_string(FILE, KEY) (pick(strings(FILE, KEY, PETPLAY_STRINGS_PATH)))
