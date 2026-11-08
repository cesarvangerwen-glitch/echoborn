# Codestandaarden v0

Eigenaar: Technical Director · Versie 0 · Issue #5

Geldt voor alle code in `game/`. De Technical Director reviewt alle code van programmeurs hierop (WERKWIJZE §5). Afwijken mag, met een reden in de PR.

## 1. GDScript-stijl

- Basis: de officiële [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html). Hieronder wat we daarbovenop afspreken.
- Inspringen met **tabs**. Regels bij voorkeur ≤ 100 tekens.
- **Statische types overal**: parameters, returnwaarden en variabelen waar het type niet triviaal volgt uit `:=`. `Variant` alleen met reden.
- Volgorde in een script: `extends` → `##`-docstring → `signal` → `enum` → `const` → `@export` → publieke `var` → private `var` (`_naam`) → `_init`/`_ready` → publieke functies → private functies.
- Elk script begint met een `##`-docstring van 1–3 regels: wat het is en waarom het bestaat.
- Commentaar en docstrings in het **Nederlands**; code-identifiers in het **Engels** (Godot-API is Engels; gemengde namen lezen slecht).
- Geen code uitgecommentarieerd laten staan; daarvoor is git.

## 2. Naamgeving

| Wat | Stijl | Voorbeeld |
|---|---|---|
| Bestanden en mappen | `snake_case` | `echo_recorder.gd`, `area_forest.tscn` |
| Functies, variabelen, signalen | `snake_case` | `sim_step()`, `player_index`, `playback_finished` |
| Private leden | `_snake_case` | `_head`, `_spawn_echo()` |
| Constanten en enum-waarden | `CONSTANT_CASE` | `TEN_SECONDS`, `Mode.STATE` |
| Enums | `PascalCase` | `Mode` |
| Gepreloade scripts (als type) | `PascalCase` | `const EchoRecorder = preload(...)` |
| Nodes in een scène | `PascalCase` | `Player1`, `ShadowLayer` |
| Input-acties | `p<n>_<actie>` | `p1_jump`, `p2_action` |
| Physics-lagen | Nederlands, klein | `wereld`, `licht`, `schaduw` |

## 3. `preload` in plaats van `class_name`

We gebruiken voorlopig **geen `class_name`**. Scripts verwijzen naar elkaar met `const X = preload("res://...")`. Reden: `class_name` vereist de importcache (`.godot/`), die niet in git staat; een verse clone faalt dan headless tot iemand `--import` draait. Met `preload` werkt `godot --headless ... -s res://tests/run_tests.gd` direct. Heroverwegen zodra CI de import vast draait (ontwerp R4).

## 4. Regels voor determinisme (verplicht voor gameplay-code)

De echo werkt alleen als de simulatie voorspelbaar is. Elke PR met gameplay-code wordt hierop gereviewd.

1. **Gameplay draait alleen in ticks van de `Sim`.** Geen eigen `_physics_process` of `_process` met gameplay-logica in actors; implementeer `sim_step(tick, delta)` en laat de Sim je aanroepen.
2. **Geen `Input.*` buiten een inputbron** (`scripts/input/`). Actors krijgen een bitmasker.
3. **Geen echte tijd** in gameplay: geen `Time`, `OS.get_ticks_*`, `Timer`-nodes of `await get_tree().create_timer()`. Tel ticks.
4. **Geen ongeseede random.** Gebruik een `RandomNumberGenerator` met een seed die de Sim beheert.
5. **Geen afhankelijkheid van de volgorde van nodes of signalen.** Als volgorde ertoe doet, regelt de Sim die.
6. **Beweging alleen via de gedeelde motor/controller**, zodat speler en echo hetzelfde codepad hebben.
7. Alles wat de echo moet kunnen herhalen, komt in de recorder (toestand per tick) of als event in de eventlijst.

## 5. Mappenstructuur `game/`

```
game/
├── project.godot
├── scenes/            # .tscn + bijbehorend script (main.tscn, later areas/, ui/)
├── scripts/
│   ├── echo/          # recorder, clip, echo-actor, motor
│   ├── input/         # inputbronnen, input-acties
│   ├── world/         # lagen, level-hulpmiddelen
│   └── sim.gd         # simulatieklok
├── assets/            # (later) art/, audio/, fonts/ – eigendom van art/audio-rollen
└── tests/
    ├── run_tests.gd   # testrunner
    ├── test_context.gd
    └── test_<systeem>.gd
```

- Een script dat bij één scène hoort, staat naast die scène. Herbruikbare code staat in `scripts/<systeem>/`.
- Bestanden met `_placeholder` in de naam zijn geen eindkwaliteit (WERKWIJZE §9).
- `.gd.uid`-bestanden (Godot 4.4+) **wel committen**; `.godot/` niet (staat in `.gitignore`).
- Godot-binaries en downloads nooit in de repo.

## 6. Testafspraken

- **Elke kerntaak heeft een automatische test.** Een PR die gameplay- of systeemcode toevoegt, voegt een test toe of legt uit waarom niet.
- Tests staan in `game/tests/test_<systeem>.gd`, met methoden `test_<wat_het_bewijst>(t)`. Nieuwe testbestanden toevoegen aan `TEST_SCRIPTS` in `run_tests.gd`.
- Draaien: `godot --headless --path game --fixed-fps 60 -s res://tests/run_tests.gd`. Moet groen zijn vóór je een PR op `status:interne-review` zet. Zet de laatste uitvoer in de PR-beschrijving.
- Tests zijn deterministisch: gescripte input (`ScriptedInput`), tellen in ticks, nooit wachten op echte tijd.
- Vergelijk posities **exact** (`==`) waar exactheid de eis is (de echo). Gebruik een tolerantie alleen met reden in de test.
- Een test die een bekende beperking vastlegt (zoals de input-echo die afwijkt), zegt dat in zijn docstring.
- Elke test ruimt zijn wereld op (de context doet dat automatisch na de test).

## 7. Review en git

- Branches, commits en PR's volgens WERKWIJZE §4.
- Kleine PR's: één systeem of één wijziging per PR.
- PR-beschrijving: wat, hoe te controleren (commando), testuitvoer, bekende beperkingen, eventuele nieuwe technische schuld.
- De Technical Director reviewt op: determinismeregels (§4), types, tests, leesbaarheid, en of de architectuur 2 spelers blijft ondersteunen.
