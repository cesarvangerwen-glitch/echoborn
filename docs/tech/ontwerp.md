# Technisch ontwerp v0

Eigenaar: Technical Director · Versie 0 (conceptfase) · Issue #5 · Engine: Godot 4.6.3, GDScript

Dit is het eerste technisch ontwerp. Het legt de architectuur vast die nodig is om het grootste risico, de echo, te bewijzen, en schetst de systemen die daarna komen. Gameplay-regels staan hier niet; die komen van de Lead Game Designer (issue #6). Waar een technische keuze afhangt van een gameplay-regel, staat dat bij **Open vragen**.

## 1. Samenvatting

- **De spike werkt.** Een blokje beweegt 10 s (600 ticks bij 60 Hz), wordt opgenomen, en de echo eindigt op exact dezelfde positie, op 0,000000 px nauwkeurig. Dat geldt ook met 2 spelers tegelijk, terwijl de spelers live doorbewegen. 7 automatische tests draaien headless in minder dan 1 s.
- **Aanbeveling: neem toestand op, niet alleen input.** Afspelen gebeurt op basis van de opgenomen toestand (positie, snelheid, later animatie en acties). Input wordt per tick meegeschreven voor acties, debugging en eventueel later gebruik. Onderbouwing in §4.
- **Co-op vanaf dag één:** inputbron per speler, een Sim die alle actors in vaste volgorde stapt, een recorder per speler. De grootste co-op-risico's staan in §6.

## 2. Kernprincipes

1. **Eén vaste simulatietick: 60 Hz.** Alle gameplay draait in `_physics_process` (`physics_ticks_per_second = 60`, `physics_jitter_fix = 0`). Niets dat de echo beïnvloedt draait in `_process`. Rendering mag interpoleren; de simulatie niet.
2. **Eén klok, vaste volgorde.** De `Sim`-node is de enige met een gameplay-`_physics_process`. Per tick geldt de volgorde van **E-07b** (`docs/design/gdd.md`, door de TD bevestigd in #14): (1) de schaduw: echo's (in spawnvolgorde) zetten hun frame, of P2 stapt; (2) P1 stapt; (3) P1 wordt opgenomen; (4) events, eerst van P1, dan van de schaduw; (5) objecten werken hun stand bij. Daarna telt de Sim `tick`. Zo staat de schaduwplank al op zijn plek van tick `t` als P1 stapt (nodig voor E-07a), en hangt de volgorde niet af van de scèneboom. De spike doet (1) t/m (3); (4) en (5) komen met het event-systeem (R5). Test: `test_sim.gd`.
3. **Input komt alleen uit een inputbron.** Gameplay-code roept nooit `Input` aan. Een inputbron (`DeviceInput`, `ScriptedInput`, later bv. een `AIInput` voor demo's) geeft per tick een bitmasker. Daardoor kunnen tests, de echo en twee spelers dezelfde code voeden.
4. **Eén bewegingsfunctie.** `Motor.step(body, bits, delta)` is de enige plek waar beweging berekend wordt. Speler en input-echo gebruiken exact hetzelfde codepad.
5. **Geen verborgen bronnen van verschil.** Geen `randf()` zonder seed uit de Sim, geen echte tijd (`Time`, `OS`), geen logica in signalen die afhangt van de volgorde waarin Godot ze afvuurt.

## 3. Scènestructuur

### Spike (nu in `game/`)

```
Main (Node2D, scenes/main.tscn)
├── Floor, WallLeft, WallRight, Platform (StaticBody2D, laag "wereld")
├── Sim (scripts/sim.gd)  ← enige gameplay-_physics_process
│   ├── Player1, Player2 (PlayerActor, laag "licht")
│   └── Echo1, Echo2 (EchoActor, laag "schaduw")
└── Camera2D
```

### Doelstructuur (voorstel, preproductie)

```
Main
├── GameState (autoload)      fase, voortgang, vlaggen; enige bron voor save
├── InputRouter (autoload)    koppelt apparaten aan spelers, drop-in/drop-out
├── SaveService (autoload)    lezen/schrijven user://, versies, migratie
├── AreaLoader                laadt één gebied (scène per gebied), streamt kamers
│   └── Area_<naam>.tscn
│       ├── LightLayer        geometrie/props die alleen in licht bestaan
│       ├── ShadowLayer       geometrie/props die alleen in schaduw bestaan
│       ├── Shared            geometrie in beide
│       └── Sim               spelers, echo's, vijanden, schakelaars
├── SharedCamera              volgt beide spelers (lokale co-op, één scherm)
└── UI (CanvasLayer)          HUD, pauze, menu's (UX/UI Artist)
```

Gebieden zijn losse scènes, zodat World & Level Designers parallel kunnen werken zonder mergeconflicten in één groot bestand.

## 4. Echo-systeem

### Onderdelen (gebouwd in de spike)

| Bestand | Rol |
|---|---|
| `scripts/input/input_bits.gd` | Bitmasker per tick: LEFT, RIGHT, JUMP, ACTION |
| `scripts/input/device_input.gd` | Leest `p<n>_*`-acties voor speler n |
| `scripts/input/scripted_input.gd` | Speelt een vast script af (tests) |
| `scripts/echo/motor.gd` | Gedeelde beweging (statisch, deterministisch) |
| `scripts/echo/echo_recorder.gd` | Ringbuffer, 600 ticks, O(1) schrijven, geen allocaties per tick |
| `scripts/echo/echo_clip.gd` | Bevroren, chronologische kopie voor afspelen |
| `scripts/echo/player_actor.gd` | Speler: input → Motor → recorder |
| `scripts/echo/echo_actor.gd` | Echo: speelt een clip af in modus STATE of INPUT |
| `scripts/sim.gd` | Klok en vaste stapvolgorde |

### Datastroom per tick

```
tick t:                                   (volgorde E-07b)
  (1) schaduw
      for echo in echo's (spawnvolgorde):
          STATE: positie, snelheid = clip.post[frame]
          INPUT: Motor.step(echo, clip.inputs[frame], 1/60)
          frame += 1
      for speler in spelers met index >= 2:  (P2; stapt en neemt op zoals P1)
  (2)+(3) P1
      bits = P1.inputbron.sample(t)
      pre  = (positie, snelheid, op_vloer)
      Motor.step(P1, bits, 1/60)
      P1.recorder.push(t, bits, pre, post=(positie, snelheid))
  (4) events, (5) objecten               (nog niet in de spike)
  t += 1
```

Een echo start met `recorder.snapshot()`: een kopie van de laatste 600 frames. De recorder schrijft daarna gewoon door, dus de speler kan direct een nieuwe opname maken terwijl de echo afspeelt. Een "altijd 10 s achter je aan"-echo is dezelfde buffer, uitgelezen op `head − 600`; die variant is technisch triviaal en hangt af van de regel die de Lead Game Designer kiest.

### Kosten

Per frame: tick (4 B), input (4 B), 4 × Vector2 (32 B), vloervlag (1 B) = 41 B. Per speler 600 × 41 B ≈ **24 kB**. Twee spelers plus een paar echo's samen blijven onder 0,2 MB. Schrijven kost een handvol array-toewijzingen per tick. Geheugen en CPU zijn geen risico.

### Aanbeveling: toestand opnemen of input opnemen

| | Toestand opnemen (STATE) | Input opnemen (INPUT) |
|---|---|---|
| Exact herhalen in dezelfde wereld | Ja, per definitie (test: 0,000 px) | Ja, in deze build en op deze machine (test: 0,000 px) |
| Wereld is veranderd (deur dicht, blok verschoven, andere speler in de weg) | Echo volgt toch het oude pad | **Echo wijkt af** (test: 164 px na één extra blok) |
| Verborgen toestand (op de vloer, coyote time, cooldowns, animatiestatus) | Wordt mee opgenomen | **Moet allemaal exact herstelbaar zijn**, anders wijkt de echo af (test: clip die begint met een sprong mist die sprong, 101 px afwijking) |
| Gevoelig voor engine-/platformverschillen in floating point, physics-volgorde, framedrops | Nee | Ja. GodotPhysics2D is niet gegarandeerd bit-exact tussen builds of CPU's. |
| Geheugen | ±24 kB per speler | ±2,4 kB per speler |
| Echo kan reageren op de wereld (geduwd worden, vallen als de vloer weg is) | Niet vanzelf | Ja |
| Debuggen en reproduceren van bugs | Goed: je ziet precies waar de echo was | Goed: je kunt een sessie opnieuw afspelen |

**Aanbeveling: toestand opnemen als bron voor het afspelen, en input meeschrijven als event-spoor.** Redenen:

1. **De kernfantasie is "je schaduw herhaalt wat jij deed".** Spelers bouwen puzzels en gevechten op de verwachting dat de echo precies doet wat ze zagen. Bij input-opname kan één veranderd detail (een vijand die anders staat, een deur die net dichtging, speler 2 die in de weg staat) de echo laten afwijken, en het effect stapelt zich op over 10 s. Dat voelt voor de speler als een bug.
2. **Robuust tegen alles wat we niet in de hand hebben**: engine-patches, physics-volgorde, framedrops op de Steam Deck, en verborgen toestand die we vergeten te herstellen. De spike laat zien dat één vergeten vlag (`is_on_floor`) al genoeg is.
3. **Goedkoop**: 24 kB per speler is verwaarloosbaar.
4. **Input meeschrijven kost bijna niets** en houdt twee deuren open: acties van de echo (aanval, schakelaar, dash) worden als events op hun tick opnieuw uitgevoerd tegen de *huidige* wereld, en we kunnen later een hybride maken als het design dat vraagt.

**Wat dit betekent voor gameplay** (beslissing van de Lead Game Designer, niet van TD): bij toestand-opname botst een echo niet vanzelf met dingen die na de opname veranderd zijn. Er is een regel nodig voor wat er gebeurt als het pad geblokkeerd is: door de muur heen (schaduw), verdwijnen, of stoppen. Technisch zijn alle drie eenvoudig: een `ShapeCast2D` op de schaduwlaag kan elke tick controleren of het opgenomen punt vrij is.

**Acties van de echo**: aanvallen, schakelaars en interacties worden niet als positie opgenomen maar als event (`ACTION`-bit, later een eigen eventlijst per frame). Bij afspelen voert de echo het event op die tick uit, met een hitbox/`Area2D` op de schaduwlaag. Schakelaars die door de echo bediend kunnen worden, luisteren naar de schaduwlaag.

## 5. Input-laag voor 2 lokale spelers

- Acties per speler: `p1_left`, `p1_right`, `p1_jump`, `p1_action`, en hetzelfde voor `p2_`. In de spike worden ze in code gezet (`input_setup.gd`): P1 toetsenbord WASD + spatie + E en joypad 0; P2 pijltjes + Enter + rechter Ctrl en joypad 1.
- Godot-acties zijn standaard voor alle apparaten. Joypad-events krijgen daarom een vast `device`; toetsenbord-events gelden voor alle apparaten en zijn per speler verdeeld over verschillende toetsen.
- **Volgende stap (preproductie): `InputRouter`-autoload.** Die kent apparaten dynamisch toe aan spelers ("druk op een knop om mee te doen"), regelt drop-in/drop-out, en houdt rekening met joypads die tijdens het spel (los)gekoppeld worden (`Input.joy_connection_changed`). De gameplay-code verandert daarvoor niet: die leest alleen inputbronnen.
- Rebinding en opgeslagen besturing: UX Designer bepaalt het scherm, Engine & Platform Programmer bouwt het, opslag via SaveService.
- Steam Input en Steam Deck: Steam vertaalt controllers naar standaard-joypads; testen op een Deck in preproductie (Engine & Platform Programmer).

## 6. Co-op-risico's

| # | Risico | Kans | Impact | Maatregel |
|---|---|---|---|---|
| C1 | **Wie bestuurt de schaduw in co-op?** Volgens de pitch bestuurt P2 de schaduw live. Dan is er in co-op geen opgenomen echo, of juist twee. Dat verandert welke systemen tegelijk actief zijn. | Hoog | Hoog | Architectuur ondersteunt beide (echo is een actor met een clip; een live schaduw is een PlayerActor op de schaduwlaag). Regel nodig van Lead Game Designer (#6). |
| C2 | **Drop-in/drop-out tijdens een opname of afspelen.** P2 stapt in terwijl de echo van P1 loopt: wordt de echo gestopt, overgenomen door P2, of blijft hij? | Hoog | Midden | Recorder per speler, onafhankelijk; regel van LGD. Test toevoegen zodra de regel er is. |
| C3 | **Echo's beïnvloeden elkaar of de andere speler** (echo als platform waar P2 op staat, echo duwt een blok waar P1 tegenaan loopt). Bij toestand-opname is de echo een bewegend platform zonder massa; bij input-opname ontstaan kettingreacties die niet meer exact te herhalen zijn. | Midden | Hoog | Toestand-opname voor de echo zelf; echo als `AnimatableBody2D` als hij een platform moet zijn. Botsingen tussen lagen expliciet per laag instellen (§8). |
| C4 | **Volgorde van verwerking.** Als P1 en P2 in dezelfde tick op hetzelfde object inwerken, bepaalt de volgorde de uitkomst. | Midden | Midden | Opgelost in de spike: de Sim stapt in vaste volgorde. Regel in `standaarden.md`: geen gameplay-`_physics_process` buiten de Sim. |
| C5 | **Inputapparaten**: twee spelers op één toetsenbord (ghosting, max. aantal toetsen tegelijk), joypad-index die wisselt na opnieuw aansluiten, Steam Input die apparaten anders nummert. | Midden | Midden | InputRouter met toewijzing op apparaat-GUID; test met 2 joypads en op Steam Deck in preproductie. |
| C6 | **Gedeelde camera**: twee spelers die uit elkaar lopen, plus echo's die ergens anders zijn. | Hoog | Midden | Camera zoomt tot een maximum, daarna een leash of teleport; regel van LGD/UX. Geen technisch blokkerend risico. |
| C7 | **Prestaties op de Steam Deck met 2 spelers + echo's + licht/schaduw.** | Laag | Midden | Echo zelf is goedkoop (§4). Lichtkosten meten bij de stijltests (#7) met de Technical Artist. |
| C8 | **Framedrops**: bij een trage frame doet Godot meerdere physics-ticks (max. 8). De simulatie blijft dan correct; input van die frames wordt per tick opnieuw gelezen, dus één druk kan over meerdere ticks vallen. | Laag | Laag | Toestand-opname maakt de echo hier ongevoelig voor. Voor input: edge-detectie (ingedrukt deze tick) in de inputbron, niet in gameplay. |

## 7. Save-systeem (schets)

- Eén bestand per slot in `user://saves/slot_<n>.json`, met een `version`-veld en migratiefuncties per versie.
- Bron van waarheid: `GameState` (voortgang, vaardigheden, geopende deuren, verzamelde items, positie bij checkpoint). Scènes slaan zelf niets op.
- Opslaan bij checkpoints en bij afsluiten; schrijven naar een tijdelijk bestand en dan hernoemen, zodat een crash geen kapotte save oplevert.
- Echo-opnames worden **niet** opgeslagen (ze zijn 10 s en vluchtig), tenzij design anders vraagt.
- Steam Cloud: `user://` is de map die Steam Cloud synchroniseert (Engine & Platform Programmer).
- Test: rondreis opslaan → laden → gelijk, plus het laden van een save van een oudere versie.

## 8. Licht- en schaduwlagen

De wereld heeft een lichtlaag en een schaduwlaag, en dat is de basis van de gating. Technisch splitsen we dat in twee dingen die los van elkaar te regelen zijn:

**Physics-lagen** (in `project.godot` en `scripts/world/layers.gd`):

| Laag | Naam | Wat erop staat |
|---|---|---|
| 1 | wereld | Geometrie die in beide werelden bestaat |
| 2 | licht | Levende spelers |
| 3 | schaduw | Echo's (en in co-op mogelijk de live schaduw van P2) |
| 4 | licht-geometrie (gepland) | Muren/platforms die alleen in licht bestaan |
| 5 | schaduw-geometrie (gepland) | Muren/platforms die alleen in schaduw bestaan |

Spelers maskeren 1 + 4, echo's 1 + 5. Zo kan een echo door een lichtmuur heen en een speler niet, zonder extra code. Schakelaars die alleen een echo kan bedienen, maskeren laag 3.

**Visueel**: `CanvasItem.light_mask` en `PointLight2D`/`LightOccluder2D` voor de lichtlaag, en een aparte `CanvasLayer` of shader voor de schaduwwereld. De pipeline (en of 2D of 2.5D) is aan de Art Director (#7) en de Technical Artist; de physics-lagen hierboven werken in beide gevallen.

## 9. Tests

- Minimale eigen testrunner (`game/tests/run_tests.gd`), geen plug-in nodig. Elke `test_*`-methode krijgt een context met `make_sim()`, `run_ticks()`, `check()` en `note()`.
- Commando: `godot --headless --path game --fixed-fps 60 -s res://tests/run_tests.gd` (exitcode 0/1). Details in `setup.md`.
- FAIL is ook: 0 checks, een scriptfout of enginefout tijdens de test (opgevangen met een `Logger`), of een test die niet binnen de tijdslimiet klaar is (#30).
- Geen testhaken in gameplaycode. Tests luisteren naar signalen, zoals `Sim.actor_stepping(tick, phase, actor)` (#30).
- Huidige tests:

| Test | Bewijst |
|---|---|
| `test_state_echo_reaches_same_position` | Kern-DoD: echo eindigt exact op de positie van het origineel na 10 s |
| `test_input_echo_reaches_same_position` | Input-replay is exact in een ongewijzigde wereld |
| `test_ring_buffer_keeps_last_10_seconds` | Buffer houdt precies tick 300–899 vast na 900 ticks, zonder gaten |
| `test_two_players_each_get_exact_echo` | 2 spelers, elk een exacte echo (beide modi), terwijl de spelers live doorbewegen |
| `test_world_change_breaks_input_echo_not_state_echo` | Legt het risico van input-opname vast |
| `test_hidden_state_breaks_input_echo_at_clip_start` | Legt het risico van verborgen toestand vast |
| `test_recorder_snapshot_is_independent_copy` | Een clip verandert niet als de recorder doorschrijft |
| `test_zero_checks_is_fail` e.a. (`test_runner.gd`, 5 tests) | Runner-oordeel: 0 checks, scriptfout of niet afgerond = FAIL; schone test met checks = PASS |
| `test_tick_order_shadow_before_p1` (`test_sim.gd`) | Logtest E-07b: per tick echo → P2 → P1, ongeacht de volgorde van toevoegen |
| `test_p1_sees_shadow_of_same_tick_and_is_recorded_after_step` (`test_sim.gd`) | Als P1 stapt, staat de echo al op zijn frame van dezelfde tick; P1 wordt na zijn stap opgenomen |
| `test_p2_action_only_on_right_ctrl` (`test_input.gd`) | P2-echo alleen op rechter Ctrl, niet op linker |

De tests zijn ook zonder `--fixed-fps` (in echte tijd, ±2 min) gedraaid en gaven dezelfde posities.

## 10. Risico's en technische schuld

| # | Item | Soort | Plan |
|---|---|---|---|
| R1 | Godot 4.6.3 vastgepind; determinisme van input-replay is alleen bewezen op deze build en deze machine (Linux x86_64). | Risico | Met toestand-opname is dit geen blokkade. Bij elke engine-update de tests draaien. Windows-run in preproductie (Engine & Platform Programmer). |
| R2 | Eigen testrunner in plaats van GUT of gdUnit4. | Schuld | Volstaat voor nu. Bij meer dan ±30 tests overstappen op GUT (MIT). Daarvoor eerst opname in `docs/licenties.md` door de Business/Legal Advisor. |
| R3 | Acties in `input_setup.gd` staan in code, niet in een rebindbare config. | Schuld | Vervangen door InputRouter + opgeslagen bindings (preproductie). |
| R4 | `preload()` in plaats van `class_name` (geen globale klassennamen). | Bewuste keuze | Werkt op een verse clone zonder importcache. Heroverwegen als CI `--import` draait. |
| R5 | Echo-acties (aanval, schakelaar) zijn alleen een bit; er is nog geen event-systeem. | Schuld | Eventlijst per frame zodra combat- en puzzelregels bekend zijn (#6). |
| R6 | Geen CI: tests draaien alleen als een agent of mens ze start. | Risico | GitHub Actions-workflow met dezelfde download en hetzelfde commando. Vraagt een besluit over Actions-minuten (EP). |
| R7 | Spike-code (blokje, `spike_world.gd`) is geen productiecode. | Schuld | Vervangen in preproductie. `Motor` wordt de echte speler-controller van de Gameplay Programmer, met de regels uit §2. |

## 11. Open vragen

| Vraag | Aan |
|---|---|
| Herhaalt de echo een bevroren clip ("laatste 10 s op het moment van oproepen") of loopt hij altijd 10 s achter je aan? | Lead Game Designer (#6) |
| Wat doet een echo als zijn opgenomen pad nu geblokkeerd is: door de muur, verdwijnen, of stoppen? | Lead Game Designer (#6) |
| In co-op: is er naast de live schaduw van P2 ook nog een opgenomen echo? Wat gebeurt er bij drop-in tijdens een echo? | Lead Game Designer (#6) |
| Mag de echo andere spelers/objecten fysiek beïnvloeden (als platform, duwen)? | Lead Game Designer (#6) |
| Mogen we GitHub Actions gebruiken voor automatische tests? | Executive Producer |
