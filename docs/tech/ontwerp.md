# Technisch ontwerp v0

Eigenaar: Technical Director · Versie 0.2 · Issues #5, #68 (event-systeem, A2), #82 (architectuur v1: AreaLoader, opslag) · Engine: Godot 4.6.3, GDScript

Dit is het eerste technisch ontwerp. Het legt de architectuur vast die nodig is om het grootste risico, de echo, te bewijzen, en schetst de systemen die daarna komen. Gameplay-regels staan hier niet; die komen van de Lead Game Designer (issue #6). Waar een technische keuze afhangt van een gameplay-regel, staat dat bij **Open vragen**.

## 1. Samenvatting

- **De spike werkt.** Een blokje beweegt 10 s (600 ticks bij 60 Hz), wordt opgenomen, en de echo eindigt op exact dezelfde positie, op 0,000000 px nauwkeurig. Dat geldt ook met 2 spelers tegelijk, terwijl de spelers live doorbewegen. 7 automatische tests draaien headless in minder dan 1 s.
- **Aanbeveling: neem toestand op, niet alleen input.** Afspelen gebeurt op basis van de opgenomen toestand (positie, snelheid, later animatie en acties). Input wordt per tick meegeschreven voor acties, debugging en eventueel later gebruik. Onderbouwing in §4.
- **Event-systeem en objecten (A2, #68):** events uit de input worden opgenomen en door de echo afgespeeld; objecten zien de lichamen van dezelfde tick met een directe vormtest, zonder tick vertraging. De Sim bewaakt C-01 (hooguit twee lichamen). Zie §4a.
- **Architectuur v1, deel 1 (T5b, #82):** kamers en een AreaLoader, waarmee de echo je door de deur volgt (E-04a), met de toestand Buiten en een controle van de indeling (§3a); opslaan en laden met schema v1, atomair schrijven, back-up en migraties (§7). De testrunner is streng gemaakt: een script dat niet laadt, maakt de suite altijd rood (§9).
- **Co-op vanaf dag één:** inputbron per speler, een Sim die alle actors in vaste volgorde stapt, een recorder per speler. De grootste co-op-risico's staan in §6.

## 2. Kernprincipes

1. **Eén vaste simulatietick: 60 Hz.** Alle gameplay draait in `_physics_process` (`physics_ticks_per_second = 60`, `physics_jitter_fix = 0`). Niets dat de echo beïnvloedt draait in `_process`. Rendering mag interpoleren; de simulatie niet.
2. **Eén klok, vaste volgorde.** De `Sim`-node is de enige met een gameplay-`_physics_process`. Per tick geldt de volgorde van **E-07b** (`docs/design/gdd.md`, door de TD bevestigd in #14): (1) de schaduw: echo's (in spawnvolgorde) zetten hun frame, of P2 stapt; (2) P1 stapt; (3) P1 wordt opgenomen; (4) events, eerst van P1, dan van de schaduw; (5) objecten werken hun stand bij. Daarna telt de Sim `tick`. Zo staat de schaduwplank al op zijn plek van tick `t` als P1 stapt (nodig voor E-07a), en hangt de volgorde niet af van de scèneboom. Alle vijf de stappen zijn gebouwd (§4a, #68). Test: `test_sim.gd`.
3. **Input komt alleen uit een inputbron.** Gameplay-code roept nooit `Input` aan. Een inputbron (`DeviceInput`, `ScriptedInput`, later bv. een `AIInput` voor demo's) geeft per tick een bitmasker. Daardoor kunnen tests, de echo en twee spelers dezelfde code voeden.
4. **Eén bewegingsfunctie.** `Motor.step(body, bits, delta)` is de enige plek waar beweging berekend wordt. Speler en input-echo gebruiken exact hetzelfde codepad.
5. **Geen verborgen bronnen van verschil.** Geen `randf()` zonder seed uit de Sim, geen echte tijd (`Time`, `OS`), geen logica in signalen die afhangt van de volgorde waarin Godot ze afvuurt.

## 3. Scènestructuur

### Spike (nu in `game/`)

```
Main (Node2D, scenes/main.tscn)
├── Floor, WallLeft, WallRight, Platform (StaticBody2D, laag "wereld")
├── Sim (scripts/sim.gd)  ← enige gameplay-_physics_process
│   ├── Player1 (PlayerActor, laag "licht")
│   ├── Player2 (PlayerActor, laag "schaduw"; alleen in co-op)
│   └── Echo1 (EchoActor, laag "schaduw"; alleen solo, C-01)
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

## 3a. Kamers en AreaLoader (T5b, #82)

**Werkaanname** (fasekader §5): de regels E-04, E-04a en E-04e en FK-3 uit `gdd.md` v0.4 (T3a, #67); co-op volgens besluit #51 (7A): P2 veroorzaakt nooit een kamerwissel; de staart D = 90 / 120 / 180 ticks (#51, 8A). Waar de gdd niets zegt, kiest de TD; de Lead Game Designer bevestigde (a) en (b) ([#82](https://github.com/cesarvangerwen-glitch/echoborn/issues/82)), (c) en (d) wachten op zijn bevestiging:

- **(a)** Ligt het middelpunt van P1 in geen enkele kamer (een gat in de indeling), dan blijft de vorige kamer gelden: geen wissel. Ligt frame `p` in geen enkele kamer, dan is de echo níét Buiten. De indeling hoort alle looppaden te dekken; een doorgang hoort bij één van beide kamers.
- **(b)** Wat geladen is, verandert in de AreaLoader-stap direct na stap (3) van E-07b. In stap (1) en (2) van die tick gold nog de vorige stand; de echo controleert direct na de wissel opnieuw, zodat hij in stap (4) en (5) al Buiten is.
- **(c)** (deel 2) Ligt het middelpunt van P2 na stap (3) in een kamer die niet geladen is, dan telt dat als "uit de kamer vallen" (C-06): P2 lost op die tick op en verschijnt 120 ticks later naast P1 (C-03). Zonder deze regel zou P2 in een kamer zonder geometrie vallen tot de leiband (C-07) na 60 ticks ingrijpt. P2 in geen enkele kamer (een gat) volgt (a): niets. De AreaLoader meldt het (signaal `partner_in_ontladen_kamer`, één keer per keer); het oplossen zelf hoort bij C-06 (Gameplay Programmer, zie §12).
- **(d)** (deel 2) Een vijand in de gestreamde inhoud van een kamer komt bij elk opnieuw laden van die kamer terug, met vol leven: zijn leven wordt niet bewaard (net als bij laden op een checkpoint, §7). Ga je een kamer uit tot hij ontlaadt (P1 twee kamers verder) en kom je terug, dan staan de vijanden er weer. Wil de LGD dat een verslagen vijand weg blijft, dan wordt dat een blijvende stand (`has_persistent_state`, een vlag) per vijand.

### Onderdelen

| Bestand | Rol |
|---|---|
| `scripts/world/kamer.gd` | Een `Kamer` (E-04e): een `Area2D` met een rechthoek uit zijn eerste `CollisionShape2D` met een `RectangleShape2D`, een `kamer_id`, een lijst `buren` en optioneel `inhoud` (een `PackedScene` die meestreamt). De rechthoek is ook de camerazone. De Area2D staat op geen laag en monitort niets: gameplay gebruikt alleen de puntcontrole `contains`, halfopen (linker- en bovenrand horen bij de kamer), dus elk punt hoort bij hooguit één kamer. |
| `scripts/world/area_loader.gd` | Kamer van P1, kamerwissel, welke kamers geladen zijn, de inhoud laden en ontladen, en `validate()`. Geen eigen `_physics_process`. |
| `scripts/echo/tail_echo.gd` | Buiten (`is_outside()`) en de reset bij een kamerwissel naar een kamer die geen buur is (`EchoReset.ROOM`). |
| `scripts/sim.gd` | `set_area_loader()` (geeft de loader ook de Sim); roept `area_loader.sim_track(tick, P1)` aan na stap (3). `add_object` laat een object dat al in de boom staat waar het is; `remove_object` meldt af (ook uit Combat; een merk op een vijand dooft). Zonder loader is alles één geladen kamer, zoals vóór T5b. |
| `scripts/objects/sim_object.gd` | `owner_layers` en `shape` zijn geëxporteerd, zodat een object in een scène kan staan. `has_persistent_state()` / `get_persistent_state()` / `set_persistent_state()`: een stand die bewaard blijft als de kamer ontlaadt (standaard geen; de hendel bewaart `on`). |

### Per tick

```
(1) echo: frame p = t − D. Ligt het middelpunt van frame p in een kamer
    die niet geladen is: Buiten (onzichtbaar, geen laag, geen plank, geen
    events, geen controles E-08; valid_from blijft staan)
(2) P1 stapt   (3) P1 wordt opgenomen
    AreaLoader.sim_track(t, P1):
        kamer = de kamer met het middelpunt van P1 (E-04e); anders blijft de vorige
        andere kamer = kamerwissel (signaal kamer_gewisseld):
            buur       -> geen reset
            geen buur  -> P1.echo_reset = ROOM (als er nog geen reset was)
        geladen = kamer van P1 + zijn buren, min geforceerd ontladen;
                  inhoud erin of eruit, in de volgorde van toevoegen:
                  erin  -> objecten krijgen hun stand uit GameState en
                           gaan (in boomvolgorde) bij de Sim
                  eruit -> stand naar GameState, objecten uit de Sim,
                           dan de inhoud weg
        P2 nu in een kamer die niet geladen is -> partner_in_ontladen_kamer
    echo.sim_after_source(t): RELEASE breekt, RESPAWN/ROOM reset (E-04a–c);
        frame p nu in een ontladen kamer -> meteen Buiten
(4) events   (5) objecten
```

### Keuzes

- **Puntcontrole, geen `Area2D`-signalen**: om dezelfde reden als A2 (§4a). Een `Area2D` meldt een lichaam pas twee ticks later; de kamerwissel moet op de tick vallen waarop het middelpunt de grens over gaat (gdd §4.6, E-04e).
- **Reset via `PlayerActor.echo_reset`**, dezelfde weg als respawn en Loslaten. Zo verwerkt de echo elke reset op één plek en in dezelfde tick.
- **Validatie**: `validate()` geeft de fouten terug (dubbele id's, geen rechthoek, overlap, onbekende buur, buren die niet wederzijds zijn, een kamer die zijn eigen buur is); `start()` logt ze met `push_error`. Een kapotte indeling is dus bij het starten meteen zichtbaar, en in een test een FAIL.
- **Streamen is in v1 synchroon**: de inhoud wordt in de tick zelf gemaakt (`instantiate`) of weggehaald (`remove_child` + `queue_free`), in vaste volgorde. Dat is deterministisch en genoeg voor de flow-kamer en de slice. In de flow-kamer zijn K1, K2 en K3 elkaars buren (FK-3), dus alles is altijd geladen en komt Buiten niet voor.
- **Debugmenu en tests**: `force_unloaded(id, true)` zet een kamer uit (gdd §4.6, E-04a (4)).
- **Startcontrole**: `start_errors(positie, kamer_id)` meldt naast `validate()` een onbekende startkamer (dan geldt de kamer van de positie), een positie die niet in de startkamer ligt, en een positie in geen enkele kamer (dan is niets geladen). `start` logt die fouten en geeft ze terug; `start_room` zegt welke kamer geldt.

### Objecten in gestreamde kamers (deel 2, R10)

- **Aan- en afmelden**: na het `instantiate` van de inhoud zoekt de loader alle `SimObject`-nodes in boomvolgorde en meldt ze bij de Sim aan; ze doen in dezelfde tick al mee in stap (4) en (5). Bij ontladen meldt hij ze eerst af, daarna gaat de inhoud weg. De volgorde in `Sim.objects` hangt zo alleen af van de volgorde van laden, dus blijft deterministisch.
- **Stand bewaren**: een object met een blijvende stand (nu de hendel, E-13) bewaart die als vlag in `loader.game_state` (een `GameState`, §7) onder `<kamer_id>/<pad in de inhoud>` (`AreaLoader.object_flag`). Schema v1 hoeft daarvoor niet te veranderen: vlaggen zijn al "alleen ware vlaggen". Bij laden zet de loader de stand terug vóór het aanmelden, zonder signaal; wie op een hendel reageert, leest `on` bij het laden. `store_objects()` schrijft de standen van de geladen kamers weg, vlak vóór een save. Zonder `game_state` begint een object na opnieuw laden in zijn standaardstand.
- **Geen blijvende stand**: een drukplaat volgt de lichamen en begint na laden los. Vijanden (`CombatTarget`) mogen in de inhoud staan; afmelden haalt ze uit Combat en dooft hun merk, maar hun leven wordt niet bewaard: ze komen bij elk opnieuw laden terug (keuze (d)). Het gemaal bewaart zijn stand al apart in `GameState.gemalen` (LM-06) en hoort in de gebiedsscène, niet in gestreamde inhoud, tot T5b deel 3 het via de autoload koppelt.
- **Niet tijdens stap (4) of (5)**: `force_unloaded` vanuit een signaal van een object (stap 4/5) zou de lijst objecten veranderen terwijl de Sim erdoor loopt. Het debugmenu roept het tussen twee ticks aan.

### Gebruik (World & Level Designer, #77)

Zet per kamer een `Area2D` met `kamer.gd` en een `CollisionShape2D` met een `RectangleShape2D` in de gebiedsscène; vul `kamer_id` en `buren` in (altijd wederzijds). In het script van de scène: `loader.collect(gebied)`, `sim.set_area_loader(loader)` en `loader.start(sim.tick, p1.position)`, na het plaatsen van P1. Het resultaat van `start` is de lijst fouten (leeg = goed). Objecten (`SimObject`) mogen in de `inhoud` van een kamer staan (deel 2); zet `loader.game_state` als hun stand moet blijven, en geef elk object een vaste naam (die zit in de vlag).

## 4. Echo-systeem

### Echo v0.4 (T16a, #76)

De echo in het spel is `TailEcho`: hij toont op tick `t` het opgenomen frame `p = t − D` (E-02; D uit `data/echo_v04.json`), wordt niet gesimuleerd, draagt de schaduwplank (E-07) en breekt als het oude pad niet meer klopt met de schaduwwereld (E-08). Alle resets lopen via één waarde `valid_from` (E-03, E-04); de enige afwijking van het pad is de merksprong (E-02m). De recorder houdt 600 frames vast, voor de finisher (C-14). De spike-onderdelen in de tabel hieronder (`EchoActor`, `EchoClip`, modus STATE/INPUT) blijven voor de spiketests en als basis voor de finisher, die de laatste 10 s afspeelt.

| Bestand | Rol |
|---|---|
| `scripts/echo/tail_echo.gd`, `echo_body.gd` | Staart-echo v0.4 (E-02–E-09, E-02m, Buiten E-04a); `echo_body.gd` is de gemeenschappelijke basis met `EchoActor` |
| `scripts/echo/tuning.gd`, `data/echo_v04.json` | Tuningwaarden (beweging, echo, gevecht) als data |
| `scripts/combat/combat.gd`, `combat_target.gd` | Aanval, schaduwmerk, kettingen, pantser (E-10a, E-14, C-12) |
| `scripts/events/meetlog.gd` | Meetlog voor de flownormen (gdd §4.5) |
| `scripts/objects/zone.gd` | `FelLicht` en `Schaduwgevaar` (E-08c/d) |
| `scripts/world/kamer.gd`, `area_loader.gd` | Kamers en AreaLoader (§3a) |
| `scripts/save/game_state.gd`, `save_service.gd` | Opslaan en laden (§7) |

### Onderdelen (gebouwd in de spike)

| Bestand | Rol |
|---|---|
| `scripts/input/input_bits.gd` | Bitmasker per tick (gdd §2.5): LEFT, RIGHT, JUMP, ATTACK, INTERACT, ECHO, DASH |
| `scripts/input/device_input.gd` | Leest `p<n>_*`-acties voor speler n |
| `scripts/input/scripted_input.gd` | Speelt een vast script af (tests) |
| `scripts/echo/motor.gd` | Gedeelde beweging (statisch, deterministisch) |
| `scripts/echo/echo_recorder.gd` | Ringbuffer, 600 ticks, O(1) schrijven, geen allocaties per tick |
| `scripts/echo/echo_clip.gd` | Bevroren, chronologische kopie voor afspelen |
| `scripts/echo/player_actor.gd` | Speler: input → Motor → recorder |
| `scripts/echo/echo_actor.gd` | Echo: speelt een clip af in modus STATE of INPUT |
| `scripts/sim.gd` | Klok en vaste stapvolgorde (E-07b, stap 1–5); bewaakt C-01 |
| `scripts/events/game_events.gd`, `event_detector.gd` | Eventsoorten en events uit inputflanken (E-10), §4a |
| `scripts/objects/sim_object.gd`, `pressure_plate.gd`, `lever.gd` | Objecten met eigenaarslaag (E-06) en directe detectie (A2), §4a |

### Datastroom per tick

```
tick t:                                   (volgorde E-07b)
  (1) schaduw
      for echo in echo's (spawnvolgorde):
          STATE: positie, snelheid = clip.post[frame]
          INPUT: Motor.step(echo, clip.inputs[frame], 1/60)
          frame += 1
      for speler in spelers met index >= 2:  (P2; stapt en neemt op zoals P1)
  (2) P1 stapt
      bits = P1.inputbron.sample(t);  events = detector.detect(t, bits)
      pre  = (positie, snelheid, op_vloer)
      Motor.step(P1, bits, 1/60)
  (3) P1.recorder.push(t, bits, pre, post=(positie, snelheid), events)
  (4) events: eerst P1, dan de schaduw (echo: clip.events[frame], of P2)
      INTERACTIE -> dichtstbijzijnde object dat het lichaam overlapt en het mag bedienen
  (5) for object in objecten (volgorde van toevoegen):
          object.sim_update(t, sim.bodies())   # directe vormtest, posities van tick t
  tick_finished(t);  echo na laatste frame weg;  t += 1
```

Met `TailEcho` is stap (1): frame `p = t − D` zetten, de plank met `body_set_state` op zijn plek zetten, en de controles van E-08. Na stap (3) volgen de AreaLoader en de resets (§3a). In de spike (`EchoActor`) start een echo met `recorder.snapshot()`: een kopie van de laatste 600 frames. De recorder schrijft daarna gewoon door, dus de speler kan direct een nieuwe opname maken terwijl de echo afspeelt. Een "altijd 10 s achter je aan"-echo is dezelfde buffer, uitgelezen op `head − 600`; die variant is technisch triviaal en hangt af van de regel die de Lead Game Designer kiest.

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

**Acties van de echo**: aanvallen, schakelaars en interacties worden niet als positie opgenomen maar als event: een eventmasker per frame (`GameEvents`, `clip.events`), gemaakt uit de inputflanken (E-10). Bij afspelen voert de Sim het event van dat frame uit in stap (4), tegen de huidige wereld en met de schaduwlaag van de echo. Objecten bepalen wie ze raakt of bedient met een directe vormtest, niet met een `Area2D` of een ruimte-query (§4a, `standaarden.md` regel 8). Schakelaars die door de echo bediend kunnen worden, hebben de schaduwlaag als eigenaarslaag (E-06).

## 4a. Event-systeem en objectdetectie (A2, #68)

**Werkaannames** (fasekader §5): de regels E-06, E-07b, E-10, E-10b en E-13 uit `gdd.md` v0.2, zolang T3a (#67) ze herschrijft; co-op volgens besluit #51 (7A): hooguit twee lichamen (C-01), P2 is in co-op de partner op de schaduwlaag (C-02 v0.2) en heeft geen eigen echo; de staartduur (± 2 s, #51) is een parameter van de echo en raakt dit systeem niet. De co-op-finisher (gedeelde echo, 8A) is nog niet gebouwd; die komt met T3b en T16c.

### Keuze A2: een directe vormtest in de tick, géén tick vertraging

Objecten (drukplaten, hendels, later zones en het schild) zien in stap (5) de lichamen van **dezelfde** tick. Een object vergelijkt zijn vlak met de vorm van elk lichaam dat de Sim doorgeeft (`Shape2D.collide` op de `global_transform` van de nodes). Dat zijn hooguit twee lichamen (C-01), dus de kosten zijn verwaarloosbaar.

Waarom niet de twee opties uit SM-punt 2 op PR #16:

| Optie | Wat het meet (Godot 4.6.3, headless) | Oordeel |
|---|---|---|
| `Area2D` met `body_entered` / `get_overlapping_bodies()` | Loopt **2 ticks** achter: de overlap wordt in de physics-stap ná `_physics_process` berekend en pas de frame daarna gemeld. | Verworpen. E-13 ("plaat precies die 30 ticks aan") klopt dan alleen verschoven. |
| `intersect_shape`-query op de physics-ruimte | Loopt **1 tick** achter. Een kinematisch lichaam (`CharacterBody2D`, `AnimatableBody2D`) krijgt zijn nieuwe positie pas in de physics-stap; ook `PhysicsServer2D.body_set_state` of `force_update_transform` verandert dat niet. | Verworpen voor bewegende lichamen. Bruikbaar tegen statische geometrie (E-08a/b: de vorm van de echo tegen laag 1 en 5). |
| **Directe vormtest** | **0 ticks**: dezelfde posities als P1 en de echo in stap 1–2 kregen. | **Gekozen.** |

Een tick vertraging accepteren had gekund, maar dan loopt alles wat de echo bedient één tick achter op wat de speler ziet, en elke regel- en testwaarde krijgt een "+1". Dat is foutgevoelig voor elke volgende regel (T3a, T3b) en voor levelontwerp; de vormtest is even goedkoop en exact.

`test_objects.gd` legt alle drie vast: `test_plates_follow_bodies_on_the_same_tick` (0 ticks verschil) en `test_physics_space_lags_behind_direct_test` (1 en 2 ticks). Wordt die laatste rood na een engine-update, dan is de volgorde van Godot veranderd: dan herbekijkt de TD deze keuze.

**Gevolg voor E-07a (schaduwplank, T16a):** P1 botst met de plank via `move_and_slide`, dus via de physics-ruimte. Een plank als `AnimatableBody2D` staat daar één tick achter. Daarom is de plank een `StaticBody2D` die in stap (1) ook met `PhysicsServer2D.body_set_state(rid, BODY_STATE_TRANSFORM, …)` op zijn plek wordt gezet (`TailEcho._sync_plank`). **Bewezen in T16a** (PR #100): `test_e07a_1_carried_by_plank_same_tick` (`test_motor.gd`) eist dat P1 in dezelfde tick met de plank meebeweegt. Zonder `body_set_state` faalt die test (39 ticks met verschil; gecontroleerd door de TD). R8 is daarmee afgelost.

### Events

- **Een event is één bit per tick per actor** (`GameEvents`: `ATTACK`, `INTERACT`), net als de input. `EventDetector` maakt ze uit de input: op de flank 0 → 1, met een herhaaltijd per soort (E-10: AANVAL 20 ticks). De tabel `FROM_INPUT` houdt bit, soort en herhaaltijd bij elkaar; T3a kan waarden wijzigen zonder code te raken.
- **De recorder neemt het eventmasker op** (`clip.events[k]`), ongeacht of het event bij P1 iets raakte (E-10). De echo voert het event van frame `p` uit tegen de **huidige** wereld, met zijn eigen laag (E-06).
- **De Sim voert events uit in stap (4)**: eerst van P1, dan van de schaduw; binnen één actor in oplopende bitvolgorde. INTERACTIE bedient het object waarvan het vlak het lichaam overlapt en dat dit lichaam mag bedienen; bij meerdere het dichtstbijzijnde middelpunt, bij gelijke afstand het eerst toegevoegde (E-10b). Elk uitgevoerd event gaat uit als signaal `Sim.event_executed(tick, soort, actor, doel)`.
- **Waar nieuwe regels inhaken.** Een nieuwe eventsoort (bv. het schaduwmerk van E-14 of de merksprong van E-02, T16a) krijgt het volgende vrije bit en een regel in `FROM_INPUT` of wordt door zijn eigen systeem gezet, en een tak in `Sim._execute`. Een echo die breekt (E-08) zet `tick_events` op 0 voor die tick. Een nieuw object erft van `SimObject` en implementeert `interact` en/of `sim_update`. Aanvallen (E-10a, E-14) zijn nog niet gebouwd: het event bestaat en wordt opgenomen, maar raakt nog niets.
- ~~Open: het bit `INTERACT` heeft nog geen InputMap-actie of toets.~~ **Opgelost** (T5a, PR #104): ATTACK, INTERACT, ECHO en DASH hebben knoppen voor beide spelers (`input.md` §2a).

### C-01 in de Sim

De Sim laat hooguit één schaduwlichaam toe: een echo óf P2. `add_echo` weigert (`false`) zolang P2 meedoet of er al een echo speelt; doet P2 mee, dan haalt de Sim een spelende echo meteen weg. Een echo die niet afspeelt, heeft geen laag, is onzichtbaar en telt niet mee voor objecten (`EchoActor.is_present()`). Na zijn laatste frame blijft hij tot het einde van die tick, zodat objecten dat frame nog zien; daarna haalt de Sim hem uit `echoes`. De node zelf ruimt de eigenaar op (`remove_echo` of `queue_free`), zodat die het resultaat nog kan lezen. Waar P2 verschijnt en wanneer de echo terugkomt (C-03, C-05), regelt de drop-in/drop-out (T16c), niet de Sim. Komt de co-op-finisher als derde lichaam (T3b), dan is `Sim.can_add_echo` de ene plek die verandert.

## 5. Input-laag voor 2 lokale spelers

- Acties per speler: `p1_left`, `p1_right`, `p1_jump`, `p1_attack`, `p1_interact`, `p1_echo`, `p1_dash`, en hetzelfde voor `p2_`. Ze worden in code gezet (`input_setup.gd`); de knoppen staan in `input.md` §2a.
- Godot-acties zijn standaard voor alle apparaten. Joypad-events krijgen daarom een vast `device`; toetsenbord-events gelden voor alle apparaten en zijn per speler verdeeld over verschillende toetsen.
- **`InputRouter`-autoload** (T5a, #69, PR #90 en #104): kent apparaten toe aan spelers op GUID ("druk op een knop om mee te doen"), regelt drop-in/drop-out en joypads die tijdens het spel (los)gekoppeld worden. De gameplay-code leest alleen inputbronnen (`RouterInput`). Model, knoppen (§2a) en tests (§5) staan in `input.md`.
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

## 7. Opslaan en laden (v1, T5b, #82)

**Werkaanname** (fasekader §5): de inhoud van de save volgt wat de flow-kamer en de slice nu nodig hebben: checkpoint (E-04b), lichtmeter en gemaal (gdd §2.12, LM-01–LM-06) en eenmalige veranderingen (sluis, eenmalige hendel E-13). Vaardigheden en verzamelobjecten komen met T3c (gdd §3); dan volgt versie 2 met een migratie.

**Schema v1** (`scripts/save/game_state.gd`; één JSON-bestand per slot, `user://saves/slot_<n>.json`):

| Veld | Type | Inhoud |
|---|---|---|
| `version` | int | `1`. Gezet door `SaveService`, niet door `GameState` |
| `gebied` | string | De gebiedsscène van het checkpoint |
| `checkpoint` | `{kamer, x, y}` | Kamer (`kamer_id`, §3a) en positie waar P1 na laden staat |
| `lichtmeter` | int | LP (LM-01) |
| `gemalen` | `{id: {vulstand, vol}}` | Vulstand `G` (0–100) en of het gemaal vol is (LM-03, LM-06) |
| `vlaggen` | `{naam: true}` | Alles wat eenmalig verandert; alleen ware vlaggen |
| `speeltijd_ticks` | int | Speeltijd in ticks, geen klokuren (§2, regel 5) |

**Niet in de save:** de echo-opname (vluchtig; na laden is de echo D ticks Leeg, zoals na een respawn, E-04), de staartlengte D (per sessie, debugmenu), live posities van vijanden en lichamen (je laadt op een checkpoint), en de besturing (een apart instellingenbestand, R3).

**Schrijven en lezen** (`scripts/save/save_service.gd`, statisch):

- **Atomair**: eerst `<pad>.tmp`, dan wordt de vorige save `<pad>.bak`, dan wordt `.tmp` de save. Een crash halverwege laat altijd een leesbare save of back-up achter; `read` valt terug op `.bak` en meldt de fout van de save zelf, en negeert een achtergebleven `.tmp` (die kan half zijn); de volgende save overschrijft hem. Is de vorige save zelf kapot en is er een back-up, dan wordt de kapotte save weggegooid en blijft de back-up staan: een kapotte save vervangt nooit een goede back-up. De volgorde werkt ook op Windows, waar hernoemen over een bestaand bestand niet mag.
- **Versies**: `migrate` brengt een save stap voor stap van versie n naar n + 1 (`builtin_migrations()`, nu leeg). Een save van een nieuwere versie, zonder versie of met een ontbrekende migratie wordt geweigerd, nooit half gelezen. `GameState.from_dict` controleert elk veld, elk type en het bereik: LP en speeltijd hele getallen van 0 tot 2^53 (eindig, en `int()` loopt niet over), een vulstand een heel getal 0–100, een positie eindig, een vlag `true`/`false`.
- **Deterministisch**: gesorteerde sleutels en getallen op volle precisie (`JSON.stringify(…, full_precision = true)`): dezelfde inhoud geeft hetzelfde bestand, en een positie komt exact terug.
- **Laden op een checkpoint**: `AreaLoader.start(tick, checkpoint.positie, checkpoint.kamer)` begint in die kamer met zijn buren geladen, zonder kamerwissel.
- `user://` is de map die Steam Cloud synchroniseert (Engine & Platform Programmer, nog te controleren op de Deck in T7).
- Nog niet in v1: de autoloads `GameState` en `SaveService` uit §3, slots en menu's, autosave bij een checkpoint en bij afsluiten (§12).

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

## 8a. Lokalisatie (T14, #74)

**Werkaannames** (kader §5): Engels is de brontaal en de standaard; Nederlands komt erbij, "in principe ja" (#51 deel 1: 5A; pitch §6). De talen zijn `en` en `nl`; de NL-vertaling zelf is fase 4, in fase 2 alleen de infrastructuur. Spelerstekst die de titel noemt, gebruikt de werktitel *Polderlight* (#96).

- **Eén bestand**: `game/locale/strings.csv`, kolommen `keys,en,nl,_context`. Een sleutel is `HOOFDLETTERS_MET_UNDERSCORE` met een prefix per scherm (`HUD_`, `MENU_`, `COMMON_`). `_context` is een notitie voor de vertaler (wat `%d` en `%s` zijn); kolommen met `_` laadt het spel niet. Opmaak met `%d`/`%s`/`%.1f` werkt zoals in GDScript.
- **Laden**: de autoload `Localization` (`scripts/locale/localization.gd`) leest het CSV-bestand zelf en geeft de vertalingen aan de `TranslationServer`. Er is dus geen import nodig (een verse clone werkt headless); `strings.csv.import` zet de importer op `keep`, zodat de editor geen `.translation`-bestanden maakt en de export het CSV-bestand ongewijzigd meeneemt. Een lege NL-cel valt terug op Engels (`locale/fallback="en"`).
- **Taal**: `--lang=nl` na `--` (`godot --path game -- --lang=nl`), anders de systeemtaal (`nl_BE`, `nl_NL` → `nl`), anders Engels. In code: `Localization.set_language("nl")`. De venstertitel volgt `GAME_TITLE`.
- **Tekst toevoegen (elke rol)**: (1) zet een regel in `strings.csv` met de Engelse tekst, waar het kan ook de Nederlandse, en context; (2) gebruik in code `tr("SLEUTEL")` (in een `static func`: `TranslationServer.translate("SLEUTEL")`), met `% [...]` erachter voor waarden; (3) in een `.tscn` zet je de sleutel zelf als `text` van een Label of Button; Godot vertaalt die. Draai de tests.
- **Wat de test bewaakt** (`tests/test_localization.gd`, met `tests/text_lint.gd`): het CSV-bestand laadt, elke sleutel heeft Engels; elke vertaling heeft dezelfde opmaakcodes in dezelfde volgorde als het Engels; elke sleutel in `tr()` of in een scène bestaat; in `scripts/`, `scenes/` en `levels/` staat geen tekst rechtstreeks in een tekstveld (`.text =`, `set_text(` …) en geen tekst van twee of meer woorden buiten `tr()`. Logregels en validatiefouten (`print`, `push_error`, `errors.append` …) zijn ontwikkelaarstekst en blijven Nederlands. Uitgezonderd: `scenes/debug/`, `prototypes/`, de bestanden in `EXEMPT_FILES` en de losse teksten in `EXEMPT_TEXTS` (elk met een reden).
- **Beperkingen**: de lint dekt alleen `.gd` en `.tscn`; tekst via `draw_string`, in `.tres` of in `.json` valt erbuiten. Een los woord in een variabele (`"Leeg"`) ziet de lint ook niet; de reviewer let op beide. Ontbrekende NL-vertalingen geeft de test alleen als notitie. Meervoud (`tr_n`) en lettertypen voor andere schriften zijn niet nodig zolang het bij EN en NL blijft.
- **Open punten**: de taalkeuze bewaren en een taalmenu (UX Designer en UI in T10, opslag van instellingen bij de TD, §7); `config/name` in `project.godot` heet nog "Echoborn": hernoemen verandert de map van `user://` (saves), dus pas samen met een vaste `custom_user_dir_name` (TD, build #79).
  - Steam-clienttaal (`Steam.getCurrentGameLanguage`) vóór de systeemtaal kiezen, zodra Steam erin zit (T7).
  - Bij de eerste exportbuild (#79) controleren dat `locale/strings.csv` in de `.pck` zit.
  - Bij de eerste editor- of importrun controleren dat de handgeschreven `strings.csv.import` (`importer="keep"`) ongewijzigd blijft (headless `--import` liet hem ongewijzigd).
  - Benoemde plaatshouders (`{room}` in plaats van `%s`) pas als een taal een andere woordvolgorde nodig heeft; tot dan bewaakt de test dat elke vertaling dezelfde opmaakcodes in dezelfde volgorde heeft.

## 9. Tests

- Minimale eigen testrunner (`game/tests/run_tests.gd`), geen plug-in nodig. Elke `test_*`-methode krijgt een context met `make_sim()`, `run_ticks()`, `check()` en `note()`.
- Commando: `godot --headless --path game --fixed-fps 60 -s res://tests/run_tests.gd` (exitcode 0/1). Details in `setup.md`.
- FAIL is ook: 0 checks, een scriptfout of enginefout tijdens de test (opgevangen met een `Logger`), of een test die niet binnen de tijdslimiet klaar is (#30).
- **Streng vóór de eerste test** (#82): de runner laadt eerst elk `.gd`-bestand onder `scripts/`, `scenes/`, `prototypes/` en `tests/` en controleert dat elke autoload uit `project.godot` bestaat. Een script dat niet laadt, is een FAIL, ook als de fout in een script valt waar een test van afhangt. De runner preloadt zelf alleen `error_log.gd`: faalt een preload van de runner, dan start Godot hem niet en is de exitcode 0 (nagemeten: een parse-fout in `sim.gd` gaf zo exitcode 0). Een fout buiten een test (bij het laden, tussen twee tests, na de laatste) telt ook als FAIL.
- Geen testhaken in gameplaycode. Tests luisteren naar signalen, zoals `Sim.actor_stepping(tick, phase, actor)` (#30).
- Open punt: een fout in een signaalhandler (bv. een test die naar `actor_stepping` luistert) geeft één foutregel per tick. De test wordt terecht FAIL, maar de uitvoer is lang; ontdubbelen in de runner kan later.
- ~~Schuld: geen test bewaakt de runner zelf. Verdwijnt `OS.add_logger()` of de time-out-lus uit `run_tests.gd`, dan blijft de suite groen. Plan: bij de overstap op GUT (R2) of de CI-workflow (R6) een meta-run toevoegen die een kapotte test draait en exit 1 verwacht.~~ **Opgelost** (#70, PR #94): de meta-run in `.github/workflows/tests.yml` eist exitcode 1 met 2 FAIL's, op Linux en Windows.
- Huidige tests:

| Test | Bewijst |
|---|---|
| `test_state_echo_reaches_same_position` | Kern-DoD: echo eindigt exact op de positie van het origineel na 10 s |
| `test_input_echo_reaches_same_position` | Input-replay is exact in een ongewijzigde wereld |
| `test_ring_buffer_keeps_last_10_seconds` | Buffer houdt precies tick 300–899 vast na 900 ticks, zonder gaten |
| `test_coop_recorders_each_give_exact_echo` | Co-op: beide spelers nemen tegelijk op; na de drop-out van P2 geeft elke opname een exacte echo (beide modi, na elkaar, C-01) terwijl P1 live doorbeweegt |
| `test_world_change_breaks_input_echo_not_state_echo` | Legt het risico van input-opname vast |
| `test_hidden_state_breaks_input_echo_at_clip_start` | Legt het risico van verborgen toestand vast |
| `test_recorder_snapshot_is_independent_copy` | Een clip verandert niet als de recorder doorschrijft |
| `test_zero_checks_is_fail` e.a. (`test_runner.gd`, 6 tests) | Runner-oordeel: 0 checks, scriptfout of niet afgerond = FAIL; schone test met checks = PASS |
| `test_tick_order_solo_steps_1_to_5`, `test_tick_order_coop_steps_1_to_5` (`test_sim.gd`) | Logtest E-07b stap 1–5: schaduw → P1 stapt → P1 opgenomen → events P1 → events schaduw → objecten, solo en co-op, ongeacht de volgorde van toevoegen |
| `test_events_p1_before_shadow_then_objects_same_tick` (`test_sim.gd`) | E-07b stap 4–5 met inhoud: P1 en echo bedienen op dezelfde tick dezelfde Wissel-hendel (eerst P1, dan de echo); een schaduwplaat ziet de echo op zijn eerste en laatste tick |
| `test_c01_never_more_than_two_bodies` (`test_sim.gd`) | C-01: 3000 ticks met twee keer meedoen en stoppen van P2: elke tick ≤ 1 schaduwlichaam en ≤ 2 lichamen, geen echo zichtbaar of botsend in co-op, nieuwe echo geweigerd in co-op |
| `test_events_on_rising_edge_with_attack_cooldown` e.a. (`test_events.gd`, 3 tests) | E-10 (flank, herhaaltijd AANVAL), echo voert een opgenomen INTERACTIE uit tegen de huidige wereld (E-06), E-10b (dichtstbijzijnde object) |
| `test_plates_follow_bodies_on_the_same_tick` (`test_objects.gd`) | A2 + E-06 + E-13: schaduw-, licht- en gedeelde plaat volgen P1 en de echo op elke tick zonder vertraging |
| `test_physics_space_lags_behind_direct_test` (`test_objects.gd`) | Legt vast waarom niet via de physics-ruimte: `intersect_shape` 1 tick, `Area2D` 2 ticks achter |
| `test_p1_sees_shadow_of_same_tick_and_is_recorded_after_step` (`test_sim.gd`) | Als P1 stapt, staat de echo al op zijn frame van dezelfde tick; P1 wordt na zijn stap opgenomen |
| Input (`test_input.gd`, `test_input_router.gd`) | Knoppen, InputRouter en drop-in/drop-out: zie de testtabel in `input.md` §5 en de knoppen in §2a |
| `test_motor.gd` (11 tests) | Beweging §2.5a (sprong, dash, buffer, coyote), lagen E-05 en de plank E-07/E-07a; `test_e07a_1_carried_by_plank_same_tick` bewijst R8 (P1 beweegt in dezelfde tick met de plank mee) |
| `test_echo_v04.gd` (12 tests) | Staart-echo v0.4: E-01, E-02 en E-03 (alle D), elke reset-oorzaak E-04, breken E-08a–d met E-08b, Loslaten E-09 |
| `test_combat.gd` (20 tests) | E-10 en E-10a met de staart, schaduwmerk E-14, merksprong E-02m (incl. INTERACTIE op de opgenomen positie), C-11e, C-12 |
| `test_meetlog.gd` (2 tests) | Meetlog deterministisch en volledig; stilstand MP-1 |
| `test_area_loader.gd` (10 tests) | E-04a (1)–(5) en E-04e uit gdd §4.6: wissel naar een buur zonder reset en de echo door dezelfde doorgang (alle D), teleport naar een kamer die geen buur is = reset (alle D), Buiten bij een ontladen kamer (P1 valt door de plank, geen INTERACTIE), validatie, P2 wisselt nooit; streamen van inhoud en een doorloop door drie kamers zonder reset (FK-3, alle D). Deel 2: objecten in gestreamde inhoud doen mee vanaf de tick van laden en zijn weg na ontladen, een Eenmalige hendel komt via GameState terug (R10); `remove_object` voor een vijand; P2 in een ontladen kamer wordt één keer gemeld (keuze (c)); de startcontrole |
| `test_save.gd` (7 tests) | Opslaan → laden exact en bytegelijk; back-up bij een kapotte save; versies en migratie; laden op een checkpoint in de goede kamer met een Lege echo; een kapotte save vervangt geen goede back-up; een achtergebleven `.tmp` na een crash (twee crashpunten); bereikcontrole in `from_dict` |
| `test_localization.gd` (7 tests) | Lokalisatie §8a: CSV geldig met Engels per sleutel, NL met dezelfde opmaakcodes als EN, elke gebruikte sleutel bestaat, geen harde spelerstekst in code of scènes (en de lint vangt die echt), taalkeuze, taalwissel EN/NL |

De tests zijn ook zonder `--fixed-fps` (in echte tijd, ±2 min) gedraaid en gaven dezelfde posities.

## 10. Risico's en technische schuld

| # | Item | Soort | Plan |
|---|---|---|---|
| R1 | Godot 4.6.3 vastgepind; determinisme van input-replay is alleen bewezen op deze build en deze machine (Linux x86_64). | Risico | Met toestand-opname is dit geen blokkade. Bij elke engine-update de tests draaien. Windows-run in CI (T6, `tests.yml`); determinisme-vergelijking tussen OS'en nog open. Open: een cross-OS-check die bewijst dat dezelfde opname op Linux en Windows dezelfde toestand oplevert, hoort bij T16a. |
| R2 | Eigen testrunner in plaats van GUT of gdUnit4. | Schuld | Volstaat voor nu. Bij meer dan ±30 tests overstappen op GUT (MIT). Daarvoor eerst opname in `docs/licenties.md` door de Business/Legal Advisor. |
| R3 | Acties in `input_setup.gd` staan in code, niet in een rebindbare config. | Schuld | Vervangen door InputRouter + opgeslagen bindings (preproductie). |
| R4 | `preload()` in plaats van `class_name` (geen globale klassennamen). | Bewuste keuze | Werkt op een verse clone zonder importcache. Heroverwegen als CI `--import` draait. Open: zodra `game/` importeerbare assets krijgt (png, wav), komt er een `--import`-stap in CI en wordt R4 heroverwogen (besluit TD, PR #94). |
| R5 | ~~Echo-acties zijn alleen een bit; er is nog geen event-systeem.~~ | Afgelost | Event-systeem en objecten gebouwd (§4a, #68). Rest: aanvallen raken nog niets (E-10a, E-14: T16a). |
| R8 | ~~De physics-ruimte ziet kinematische lichamen één tick te laat (§4a); de schaduwplank (E-07a) botst via de ruimte.~~ | Afgelost | Plank als `StaticBody2D` met `body_set_state` in stap (1), bewezen door `test_e07a_1_carried_by_plank_same_tick` (T16a, PR #100; zonder `body_set_state` faalt de test). Wordt die test rood na een engine-update, dan herbekijkt de TD §4a. |
| R6 | Geen CI: tests draaien alleen als een agent of mens ze start. | Risico | GitHub Actions-workflow met dezelfde download en hetzelfde commando. Vraagt een besluit over Actions-minuten (EP). |
| R7 | Spike-code (blokje, `spike_world.gd`) is geen productiecode. | Schuld | Vervangen in preproductie. `Motor` wordt de echte speler-controller van de Gameplay Programmer, met de regels uit §2. |
| R9 | De AreaLoader streamt synchroon (§3a). Een grote kamer kan bij het laden een hapering geven op de Steam Deck. | Risico | Meten in T7 (Engine & Platform Programmer). Zo nodig de buren van de buren vooraf laden met `ResourceLoader.load_threaded_request`; de logische regel (wat geladen is) blijft gelijk, dus de echo-tests ook. |
| R10 | ~~Objecten (`SimObject`) in gestreamde inhoud worden nog niet bij de Sim aan- en afgemeld, en hun stand gaat bij ontladen verloren.~~ | Afgelost | T5b deel 2 (§3a): aanmelden bij laden, afmelden bij ontladen, de stand via `GameState`-vlaggen; bewezen door `test_r10_objects_in_streamed_rooms`. Rest: het gemaal in gestreamde inhoud (deel 3). |

## 11. Open vragen

| Vraag | Aan |
|---|---|
| Herhaalt de echo een bevroren clip ("laatste 10 s op het moment van oproepen") of loopt hij altijd 10 s achter je aan? | Lead Game Designer (#6) |
| Wat doet een echo als zijn opgenomen pad nu geblokkeerd is: door de muur, verdwijnen, of stoppen? | Lead Game Designer (#6) |
| In co-op: is er naast de live schaduw van P2 ook nog een opgenomen echo? Wat gebeurt er bij drop-in tijdens een echo? | Lead Game Designer (#6) |
| Mag de echo andere spelers/objecten fysiek beïnvloeden (als platform, duwen)? | Lead Game Designer (#6) |
| Mogen we GitHub Actions gebruiken voor automatische tests? | Executive Producer |

## 12. Open punten

- **Tools Programmer:** (1) de Node 20-waarschuwing van de `@v4`-actions in `tests.yml` oplossen; (2) in de meta-run (`.github/ci/test_meta_broken.gd`) een geval toevoegen voor een scriptfout in een script waar een test van afhangt, vóór de eerste test: de runner vangt dat sinds #82 op (§9), de meta-run bewaakt het nog niet.
- **Lead Game Designer:** de keuzes (c) (P2 in een ontladen kamer = C-06) en (d) (vijanden in gestreamde inhoud komen bij elk opnieuw laden terug) uit §3a bevestigen of wijzigen.
- **Gameplay Programmer (C-06):** het oplossen van P2 koppelen aan `AreaLoader.partner_in_ontladen_kamer` (keuze (c), §3a), samen met de andere oorzaken van C-06.
- **Gameplay Programmer (T16c):** `valid_from` (`geldig_vanaf`) staat op de `TailEcho`-node en gaat verloren als C-01 hem weghaalt; E-09 in co-op en C-05 vragen dat hij bij P1 hoort.
- **T5b deel 3, vlag van een object:** de vlag `<kamer_id>/<nodepad>` (§3a) verliest zijn stand als een level designer de kamer of het object hernoemt; een controle (bekende vlaggen tegen de inhoud) of een migratie hoort bij deel 3.
- **Debugmenu, `force_unloaded`:** zodra het debugmenu het aanroept, een `push_error`-guard als het tijdens stap (4) of (5) gebeurt (§3a).
- **T5b, volgend deel** (Technical Director met de Engine & Platform Programmer): (3) de autoloads `GameState` en `SaveService` met slots, checkpoint-objecten en autosave (met `AreaLoader.store_objects()` vlak vóór elke save), het gemaal in gestreamde inhoud, Steam Cloud op de Deck, en zo nodig threaded laden (R9).

