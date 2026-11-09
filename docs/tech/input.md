# Input voor 2 controllers en drop-in/drop-out

Eigenaar: Engine & Platform Programmer · Versie 0 · Issue [#69](https://github.com/cesarvangerwen-glitch/echoborn/issues/69) (T5a, `docs/productie/fase-2-kader.md` §2)

Dit document beschrijft de `InputRouter`: welk apparaat bij welke speler hoort, en hoe spelers meedoen en stoppen. Het werkt `ontwerp.md` §5 ("volgende stap: InputRouter") en C5 uit, en dekt het invoerdeel van R19 (`docs/productie/risico.md`). Wat er in het spel gebeurt bij meedoen of stoppen (plaatsing, de echo die overneemt) is gameplay: dat bouwt T16c op de signalen hieronder.

## 1. Werkaannames (kader §5)

| # | Aanname | Bron |
|---|---|---|
| W1 | Maximaal **2 plaatsen**: plaats 1 = de speler (solo met echo), plaats 2 = de partner in co-op. | besluit #51, optie 7A ("max. twee lichamen") |
| W2 | Knoppen volgens het **voorstel in gdd §2.5**: meedoen = Start/Menu op een vrije pad of Enter op de P2-helft van het toetsenbord; stoppen = Select/View (toetsenbord Backspace) **60 ticks** vasthouden; apparaat van de partner **180 ticks** weg = stoppen (C-05). Het rebindscherm is van de UX Designer. | gdd §2.5, C-03, C-05, §2.9 |
| W3 | **Plaats 1 neemt elke knop** op elk apparaat (titelscherm: "druk op een knop"). Plaats 1 stopt nooit via de router; terug naar het menu is UX. | eigen aanname, niet in de gdd |
| W4 | Een plaats waarvan het apparaat weg is, **wacht**. Komt dezelfde GUID terug, dan krijgt die pad de plaats terug zonder knop. Een **ander** apparaat mag een wachtende plaats overnemen (lege batterij, andere pad gepakt): elke knop voor plaats 1, meedoen voor plaats 2. Plaats 1 wacht onbeperkt (pauze is UX/gameplay). | eigen aanname |
| W5 | De knop die liet meedoen, doet in het spel niets tot hij is losgelaten (Enter is ook springen). | eigen aanname |
| W6 | De bits blijven die van de spike (`input_bits.gd`). De volledige bitset uit gdd §2.5 (T16a) voegt alleen regels toe aan `KEYS` en `PAD_BUTTONS` in `input_setup.gd`. | gdd §2.5 |

## 2. Model

- **Apparaat**: `kb1` (WASD-helft), `kb2` (pijltjeshelft) of `joy<index>`. Toetsenbord en joypad 0 hebben in Godot allebei `device == 0`; de router onderscheidt ze op het type event, niet op het nummer.
- **GUID**: `Input.get_joy_guid(index)`. Een GUID hoort bij een **model**, niet bij één exemplaar: twee identieke pads hebben dezelfde GUID. Daarom stuurt de router op index (welk apparaat speelt nu) en gebruikt hij de GUID alleen om een teruggekeerde pad te herkennen. Bij twee wachtende plaatsen met dezelfde GUID krijgt de laagste plaats de eerste pad terug.
- **Plaats**: `FREE` (vrij), `ACTIVE` (speelt) of `SUSPENDED` (apparaat weg, wacht). Een vrije of wachtende plaats geeft bits 0.
- **Pauze en focus**: het autoload draait met `PROCESS_MODE_ALWAYS`, zodat een knop die je tijdens de pauze loslaat niet blijft hangen; `step()` telt niet zolang de boom gepauzeerd is. Bij focusverlies (alt-tab, Steam-overlay) zet `release_all_controls()` alle knoppen los.
- **Ticks**: `step()` telt de stopknop en de tijd dat een apparaat weg is. Standaard loopt dat in `_physics_process` van het autoload (in de boom vóór de Sim). Moet het exact op de Sim-tick vallen, dan zet T16c `InputRouter.set_physics_process(false)` en roept de Sim `step()` aan.

| Situatie | Gevolg | Signaal |
|---|---|---|
| Knop op een apparaat zonder plaats, plaats 1 vrij of wachtend | plaats 1 voor dit apparaat | `slot_joined(1, device)` of `slot_resumed` |
| Meedoen op een apparaat zonder plaats, plaats 2 vrij of wachtend | plaats 2 voor dit apparaat | `slot_joined(2, device)` of `slot_resumed` |
| Derde apparaat | niets | — |
| Partner houdt stoppen 59 ticks / 60 ticks | blijft / plaats 2 vrij | `slot_left(2, "stoppen")` |
| Pad met een plaats ontkoppeld | plaats wacht, bits 0 | `slot_suspended(slot)` |
| Zelfde GUID sluit aan (ook op een andere index) | plaats terug | `slot_resumed(slot, device)` |
| Pad van de partner 179 / 180 ticks weg | wacht / plaats 2 vrij | `slot_left(2, "apparaat weg")` |

## 3. Gebruik in code

- `InputRouter.source_for(slot)` geeft een inputbron (`sample(tick) -> int`) voor `PlayerActor.setup`, net als `DeviceInput`. Gameplaycode leest nog steeds alleen een inputbron (standaarden §4.2).
- Signalen: `slot_joined`, `slot_left`, `slot_suspended`, `slot_resumed`. Gameplay (T16c) maakt hierop het lichaam van de partner aan of laat het oplossen.
- `release_slot(slot)` maakt een plaats vrij (bv. terug naar het titelscherm).
- `guid_lookup` is de bron van GUID's: standaard `Input.get_joy_guid`; tests geven een vaste tabel, en een latere Steamworks-laag kan hier een eigen ID geven.
- De spike (`scenes/main.gd`) gebruikt nog `DeviceInput` met vaste joypad 0 en 1. Die acties blijven werken. Overzetten is twee regels en gebeurt in T16c, zodat deze PR niet botst met T4 (#68).

## 4. Controle op echte hardware (Steam Deck + 2e pad)

Headless zijn er geen controllers; de tests (§5) sturen gesimuleerde events. Op echte hardware controleer je de GUID-koppeling met het controlescherm `game/scenes/debug/input_debug.tscn`. Het toont de aangesloten pads (index, naam, GUID, `get_joy_info`), beide plaatsen met bits, en een log; elke logregel staat ook op stdout.

Starten: `godot --path game res://scenes/debug/input_debug.tscn` (Desktop Mode, vanuit Konsole), of een Linux-export van die scène als niet-Steam-game in Game Mode.

| Stap | Doen | Verwacht |
|---|---|---|
| 1 | Start zonder 2e pad. | De ingebouwde besturing staat in de lijst. Noteer index, naam en GUID. |
| 2 | Druk A op de Deck, laat los; beweeg stick en d-pad; druk A. | Plaats 1 speelt met `joy<n>`; bits `L`/`R`, daarna `J`. De eerste A springt niet (W5). |
| 3 | Sluit de 2e pad aan (USB of Bluetooth). Druk A, daarna Start. | Log `joy<m> aan`. A doet niets; Start: plaats 2 speelt. De bits van beide plaatsen lopen niet door elkaar. |
| 4 | Koppel de 2e pad los en binnen 3 s weer aan. | `plaats 2: apparaat weg, wacht`, dan `plaats 2: terug met joy<k>`. De index mag anders zijn. Noteer of de GUID gelijk bleef. |
| 5 | Koppel de 2e pad los en wacht langer dan 3 s. | `plaats 2: weg (apparaat weg)`. |
| 6 | Druk Start; houd Select/View korter dan 1 s, daarna langer dan 1 s vast. | Kort: plaats 2 blijft. Lang: `plaats 2: weg (stoppen)`. |
| 7 | Herhaal 1–6 in Game Mode met Steam Input **aan** en **uit** (controllerinstellingen van de game), en in Desktop Mode. | Noteer per modus naam en GUID van beide pads. |
| 8 | Als er twee identieke pads zijn: herhaal 3–4 met beide. | Beide pads krijgen een eigen plaats; de teruggekeerde pad gaat naar de wachtende plaats. |

**Waar het mis kan gaan.** Met Steam Input aan meldt Steam elke pad als virtuele pad ("Steam Virtual Gamepad"). Dan kunnen alle pads dezelfde GUID hebben (zoals bij twee identieke pads, §2) en kan de index na opnieuw aansluiten wisselen. Herkennen werkt dan alleen nog op volgorde. **Vallen twee pads met dezelfde GUID tegelijk weg** (bv. een USB-hub los, of Steam die zijn virtuele pads opnieuw opbouwt), dan wachten beide plaatsen. De eerste pad die terugkomt, krijgt plaats 1 en de tweede plaats 2, ongeacht wie welke pad vasthoudt. Spelers kunnen dus van lichaam wisselen. Er blijft niets hangen en er valt niemand weg (binnen 180 ticks); de spelers ruilen hun pad of stoppen en doen opnieuw mee. Controleer dit in stap 7 door beide pads tegelijk los te koppelen en ze in omgekeerde volgorde weer aan te sluiten. Blijkt dat in stap 7, dan wordt `guid_lookup` gevuld met de Steam Input-handle (Steamworks, later) of `get_joy_info`, als daar een vaste ID in staat.

De resultaten van een hardwarerun komen in deze sectie, met datum, modus en de genoteerde GUID's.

## 5. Tests

`game/tests/test_input_router.gd` (draaien zoals in `setup.md`):

| Test | Bewijst |
|---|---|
| `test_join_fills_slot_1_then_slot_2_and_never_a_third` | Eerste knop = plaats 1; alleen Start vult plaats 2; een derde apparaat krijgt niets (W1–W3) |
| `test_keyboard_half_joins_and_does_not_mix_with_joypad_0` | Enter op de P2-helft laat meedoen zonder te springen (W5); toetsenbord en joypad 0 (beide device 0) sturen elkaar niet; stick van links naar rechts laat geen LEFT hangen |
| `test_leave_hold_59_stays_60_leaves_and_slot_1_never_leaves` | C-05: stoppen 59 ticks blijft, 60 weg; loslaten zet de teller terug; plaats 1 stopt niet; opnieuw meedoen lukt |
| `test_reconnect_with_new_index_resumes_by_guid_and_180_ticks_drops_out` | Zelfde GUID op een nieuwe index krijgt de plaats terug; ingedrukte knoppen blijven niet hangen; C-05: 179 ticks weg blijft, 180 weg |
| `test_identical_pads_share_guid_but_stay_separate` | Twee pads met één GUID lopen niet door elkaar; de teruggekeerde pad gaat naar de wachtende plaats |
| `test_other_device_takes_over_a_waiting_slot` | W4: een ander apparaat neemt een wachtende plaats over |
| `test_drop_in_and_out_drive_player_in_sim` | In een draaiende Sim staat een `PlayerActor` op een vrije plaats stil, beweegt na meedoen en stopt na stoppen |
| `test_sim_can_drive_step_after_set_physics_process_false` | Overdracht voor T16c: na `set_physics_process(false)` telt de router niet zelf; roept de Sim `step()` aan, dan valt C-05 op de 60e Sim-tick |
| `test_autoload_exists_and_viewport_events_reach_router` | Het autoload staat in `project.godot`; echte events via de viewport komen aan |
| `test_pause_and_focus_loss_leave_no_stuck_controls` | Loslaten tijdens een pauze komt aan; de stopknop telt niet door tijdens de pauze; focusverlies zet alle knoppen los |
| `test_debug_scene_shows_both_slots` | Het controlescherm van §4 laadt zonder fouten |

## Open punten

- Hardwarerun op een Steam Deck met een 2e pad (§4): eigenaar engine-platform-programmer, vóór de eerste co-op-speltest in T16c ([#78](https://github.com/cesarvangerwen-glitch/echoborn/issues/78)); er is geen hardware in de werkomgeving.
- `kb1` (WASD) kan niet als partner meedoen: de gdd geeft alleen Enter op de P2-helft. Speelt P1 met een pad, dan moet een toetsenbordspeler de pijltjes gebruiken. Keuze voor de UX Designer.
- W4 laat een wachtende plaats 1 vóór een vrije plaats 2 gaan: valt de pad van een solospeler weg en drukt een vriend op Start, dan wordt die vriend P1 en moet de teruggekeerde pad als P2 meedoen. Keuze voor UX Designer en LGD.
- Bindings staan nog in code (`ontwerp.md` R3); herbinden en opslaan horen bij het rebindscherm (UX) en het save-systeem.
- `ontwerp.md` §5 en de testtabel in §9 kunnen naar dit document verwijzen (Technical Director).
