# Setup: Godot 4.6 headless en tests draaien

Eigenaar: Technical Director · Versie 0 · Issue #5

Dit document is voor elke agent en elke mens die code in `game/` wil draaien of testen. Volg het van boven naar beneden.

## 1. Welke versie

| | |
|---|---|
| Engine-besluit | Godot 4.6 (`docs/beslissingen.md`) |
| Vastgepinde build | **Godot 4.6.3-stable, officieel, Linux x86_64, standaard (niet mono)** |
| Waarom 4.6.3 | Nieuwste 4.6.x-patch op 2026-11-08 (4.6.4 bestaat nog niet). Patches binnen 4.6 zijn compatibel; dit valt onder het CEO-besluit "Godot 4.6". |
| Getest | 4.6.3 headless: tests groen. 4.6, 4.6.1, 4.6.2 zijn ook downloadbaar, maar niet getest. |

Iedereen gebruikt dezelfde build. Determinisme van de echo (zie `ontwerp.md`) hangt mede af van de engineversie. Een upgrade naar een nieuwe patch is een TD-besluit; een upgrade naar 4.7 of hoger is een vraag aan de CEO.

## 2. Installeren (Linux, zonder root)

Godot is één binary. Installeer hem **buiten de repo**, of in een map die in `.gitignore` staat. Commit nooit Godot-binaries.

```bash
# Kies een map voor tools, buiten de repo
TOOLS="$HOME/tools/godot"          # of bv. <scratchpad>/td/godot
V=4.6.3
mkdir -p "$TOOLS" && cd "$TOOLS"

BASE="https://github.com/godotengine/godot/releases/download/${V}-stable"
curl -sSLO "$BASE/Godot_v${V}-stable_linux.x86_64.zip"
curl -sSLO "$BASE/SHA512-SUMS.txt"

# Controleer de checksum (moet "OK" geven)
grep " Godot_v${V}-stable_linux.x86_64.zip" SHA512-SUMS.txt | sha512sum -c -

unzip -o -q "Godot_v${V}-stable_linux.x86_64.zip"
ln -sf "Godot_v${V}-stable_linux.x86_64" godot
export PATH="$TOOLS:$PATH"

godot --version     # verwacht: 4.6.3.stable.official.7d41c59c4
```

SHA-512 van `Godot_v4.6.3-stable_linux.x86_64.zip` op het moment van schrijven staat in `SHA512-SUMS.txt` van dezelfde release; de check hierboven vergelijkt daartegen.

**Werkomgeving met proxy (agents):** de download loopt via de standaard HTTPS-proxy met `curl`; er is niets extra nodig. De GitHub-API voor `godotengine/godot` is vanuit de agent-sessie geblokkeerd (`gh api` geeft 403), maar de directe release-downloads werken. Gebruik dus `curl`, niet `gh release download`.

Afhankelijkheden: geen. `--headless` gebruikt geen GPU, geen X11 en geen audio.

## 3. Tests draaien

Vanuit de root van de repo:

```bash
godot --headless --path game --fixed-fps 60 -s res://tests/run_tests.gd
```

- Exitcode `0` = alle tests geslaagd, `1` = minstens één test mislukt.
- Een test is ook FAIL bij 0 checks, bij een `SCRIPT ERROR` of enginefout tijdens de test, of als hij niet binnen 7200 frames klaar is. Een testscript dat niet laadt of geen `test_*`-methoden heeft, telt als mislukt (#30). De runner vangt fouten op met een `Logger` (`tests/error_log.gd`, Godot 4.5+).
- Bekende beperkingen van de runner:
  - Een test die na 7200 frames niet klaar is, wordt als FAIL gemeld, maar zijn coroutine blijft bestaan tot de runner stopt. Geeft die vastgelopen test later nog een fout, dan kan die op naam van een volgende test komen. Los bij een time-out dus eerst de hangende test op en draai de suite dan opnieuw.
  - Waarschuwingen (`push_warning`) maken een test niet rood, alleen fouten.
  - `Logger` bestaat pas sinds Godot 4.5; binnen het besluit "Godot 4.6" geen probleem.
- `--fixed-fps 60` laat elke frame precies 1/60 s duren, los van de echte tijd. Daardoor draaien 10 s spel in minder dan een seconde, en is er per frame precies één physics-tick. Zonder deze vlag slagen de tests ook, maar duren ze ongeveer twee minuten (echte tijd).
- Een verse clone heeft geen `game/.godot/`-cache nodig: de code gebruikt `preload()` in plaats van `class_name` (zie `standaarden.md`). Wil je de cache toch opbouwen (bv. na het toevoegen van assets): `godot --headless --path game --import`.

Verwachte uitvoer (verkort):

```
Echoborn tests - Godot 4.6.3-stable (official), physics 60 Hz

res://tests/test_runner.gd
  PASS test_zero_checks_is_fail (1 checks)
  PASS test_script_error_is_fail_even_with_passing_checks (1 checks)
  PASS test_unfinished_test_is_fail (1 checks)
  PASS test_clean_test_with_checks_is_pass (1 checks)
  PASS test_failed_check_is_reported (1 checks)

res://tests/test_echo.gd
  PASS test_state_echo_reaches_same_position (5 checks)
  PASS test_input_echo_reaches_same_position (2 checks)
  PASS test_ring_buffer_keeps_last_10_seconds (5 checks)
  PASS test_two_players_each_get_exact_echo (6 checks)
  PASS test_world_change_breaks_input_echo_not_state_echo (2 checks)
  PASS test_hidden_state_breaks_input_echo_at_clip_start (3 checks)
  PASS test_recorder_snapshot_is_independent_copy (4 checks)

res://tests/test_sim.gd
  PASS test_tick_order_shadow_before_p1 (1 checks)
  PASS test_p1_sees_shadow_of_same_tick_and_is_recorded_after_step (5 checks)

res://tests/test_input.gd
  PASS test_p2_action_only_on_right_ctrl (4 checks)

Resultaat: 15 geslaagd, 0 mislukt (0.61 s)
```

## 4. De spike spelen

```bash
godot --path game                       # met venster
godot --headless --path game --quit-after 120   # rooktest: start en stopt na 120 frames
```

Besturing: P1 A/D + spatie, E = echo. P2 pijltjes + Enter, rechter Ctrl = echo. Joypad 0 en 1 werken ook (stick, A = springen, X = echo).

## 5. Problemen

| Symptoom | Oorzaak / oplossing |
|---|---|
| `sha512sum: WARNING: 1 computed checksum did NOT match` | Download onvolledig of afgebroken door de proxy (gezien in #14: eerste poging gaf een zip van 23 bytes). Zip verwijderen en opnieuw downloaden. |
| `gh api repos/godotengine/godot/...` geeft 403 | Verwacht in de agent-omgeving. Gebruik de `curl`-URL's hierboven. |
| Tests hangen | `--fixed-fps` vergeten en wachten op echte tijd (±2 min), of een test wacht op een tick die nooit komt. Draai met `--fixed-fps 60`. |
| Test FAIL met `fout tijdens de test: ...` | De test crashte of de engine gaf een fout. Het bericht noemt bestand en regel. |
| `Parse Error` op een script | Draai `godot --headless --path game --check-only -s <script>` voor het precieze bericht. |
