# NPC Portrait Mapping

Source folder: `NPC PICTURES/`  
Game assets: `assets/images/npcs/{profile_id}.png`

Run after adding art: `python tool/sync_npc_images.py`

## Coverage (29 profiles)

All 29 NPCs in `assets/data/npc_profiles.json` have synced portraits.

| Profile ID | Source file(s) |
|------------|----------------|
| anton_40 | ANTON.PNG |
| mia_12 | MIA.PNG |
| rosa_67 | ROSA.PNG |
| derek_28 | DEREK.PNG |
| jin_19 | JIN.PNG |
| carmen_35 | CARMEN.PNG |
| tyler_16 | TYLER.PNG |
| grace_52 | GRACE.PNG |
| omar_45 | OMAR.PNG |
| lily_9 | LILY.PNG |
| vic_31 | VIC.PNG |
| elena_24 | ELENA.PNG |
| frank_58 | FRANK.PNG (+ CAR MECHANIC… duplicate art) |
| zoe_22 | ZOE.PNG |
| sam_70 | SAM.PNG |
| nova_27 | NOVA.PNG |
| rex_43 | REX.PNG |
| milo_34 | MILO.PNG |
| brock_26 | BROCK.PNG |
| iris_38 | IRIS.PNG |
| cole_33 | COLE.PNG |
| hank_49 | HANK.PNG |
| zion_41 | ZION.PNG |
| bigmoe_37 | BIIG MOE.PNG |
| devin_21 | DEVIN.PNG |
| trish_42 | TRISH.PNG |
| marcus_47 | MARCUS.PNG |
| nina_29 | NINA.PNG |
| sasha_31 | SASHA.PNG |

## Unmapped art (no profile yet)

| File | Notes |
|------|--------|
| **ELDERLY HBP FEMALE.PNG** | No matching profile ID. Could be a future NPC, or alternate portrait for Rosa/Grace/Omar if you assign one in `sync_npc_images.py`. |

## Player avatars

- Default human portrait: `assets/images/avatars/player_default.png` (from `1 player.PNG`)
- Humans can pick any portrait in match setup or Settings → **Default player portrait**
- NPC portraits (`npc:{id}`) are also selectable for human players
