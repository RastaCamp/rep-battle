# Quest Mode Assets

Source folder: `quest/` (project root)  
Synced to: `assets/images/quest/` via `tool/sync_quest_images.py`

## Enemies (all matched)

| Enemy ID     | Source file        | Asset path                              |
|-------------|----------------------|-----------------------------------------|
| rust_goblin | rust goblin.PNG      | assets/images/quest/rust_goblin.png     |
| dust_sprite | dust sprite.PNG      | assets/images/quest/dust_sprite.png     |
| iron_rat    | iron rat.PNG         | assets/images/quest/iron_rat.png        |
| iron_brute  | iron brute.PNG       | assets/images/quest/iron_brute.png      |

## Room types (all matched)

| Type      | Source file           | Asset path                            |
|-----------|------------------------|---------------------------------------|
| combat    | room type combat.PNG   | assets/images/quest/room_combat.png   |
| rest      | room type rest.PNG     | assets/images/quest/room_rest.png     |
| trap      | room type trap.PNG     | assets/images/quest/room_trap.png     |
| treasure  | room type treasure.PNG | assets/images/quest/room_treasure.png |
| boss      | room type boss.PNG     | assets/images/quest/room_boss.png     |

## Loot items

| Item ID        | Source file                 | Status                          |
|----------------|-----------------------------|---------------------------------|
| protein_shake  | loot item protien shake.PNG | OK                              |
| skip_token     | loot item skip token.PNG    | OK                              |
| armor_plate    | loot item armor.PNG         | OK                              |
| lucky_card     | loot item lucky card.PNG    | OK                              |
| combo_charm    | loot item combo charm.PNG   | OK                              |
| crown_of_kings | loot item crown of kings.PNG| OK                              |
| titan_heart    | loot item titan heart.PNG   | OK                              |
| energy_drink   | *(none)*                    | **MISSING** — uses armor_plate placeholder |

## Inventory UI (optional extras)

| Asset | Source |
|-------|--------|
| ui_protein_shake.png | backpack items 2 protein shakes.PNG |
| ui_skip.png | backpack items 1 skip.PNG |
| ui_lucky_card.png | backpack items 1 lucky card.PNG |
| ui_relic_slot.png | backpack items relic slot.PNG |

## Not in folder yet (future)

- Dungeon background art per dungeon
- Quest music tracks
- Dedicated `energy_drink` loot icon

Re-run after adding art: `python tool/sync_quest_images.py`
