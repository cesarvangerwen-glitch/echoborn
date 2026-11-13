# Kadewijk starten en het meetlog (MT2)

Versie 0.1 · Tools Programmer · issue [#250](https://github.com/cesarvangerwen-glitch/echoborn/issues/250) · voorwaarden V-5, V-6 en V-7 van `docs/qa/testplan-mt2.md` §2.1

Voor QA en de Producer: hoe je de Kadewijk start zonder de MT1-start te veranderen, waar het meetlog terechtkomt en wat een `DEBUG`-regel betekent.

## 1. Starten (V-5)

MT1 wacht nog op de CEO. De hoofdscène in `game/project.godot` blijft daarom de flow-kamer: **F5 in de editor start de flow-kamer, net als bij MT1**. De test `test_mt1_start_ongewijzigd` bewaakt dat. De Kadewijk start je apart, op een van deze twee manieren.

**In de editor (voor de CEO):**
1. Open het project zoals bij MT1 (`ceo-kaart-mt1.md` stap 3).
2. Dubbelklik linksonder in *FileSystem* op `res://levels/kadewijk/kadewijk.tscn`. De scène gaat open.
3. Druk op **F6** (*Huidige scène afspelen*, Engels: *Run Current Scene*). Gebruik dus niet F5.

**Vanaf de commandline** (QA, of een snelkoppeling):
```
Godot_v4.6.3-stable_win64.exe --path game res://levels/kadewijk/kadewijk.tscn
```
Dit werkt pas als het project één keer in de editor is geïmporteerd.

In beide gevallen start de Kadewijk in S1 op D = 60 uit data (`echo.tail_ticks`), met de echo aan. De HUD toont `HUD_STATUS` en `HUD_ROOM` (kamer, D, echo-toestand, tijd).

Na MT1 mag de hoofdscène naar de Kadewijk. Dat is één regel (`run/main_scene`) en een besluit van de TD of de Producer. Pas dan ook `test_mt1_start_ongewijzigd` aan.

## 2. Het meetlog als CSV (V-6)

`kadewijk_meetlog_csv.gd` doet dit, op dezelfde manier als de flow-kamer (`flow_room.gd`, `save_log`).

| Wanneer | Bestand |
|---|---|
| `RUN_EIND` | `meetlog_<JJJJMMDD-uummss>_kadewijk_solo_D60_p1.csv` |
| afgebroken: F6, F4, een D-toets (F1/F2/F3/F7) of het venster dicht | hetzelfde met `_afgebroken` vóór `.csv` |

- De map is `user://`, dus `%APPDATA%\godot\app_userdata\Echoborn` op Windows (`custom_user_dir_name` in `project.godot`). Het volledige pad staat in de uitvoer, op de regel `Meetlog opgeslagen: …`.
- De kolommen zijn die van de flow-kamer: `tick,kamer,event,waarde,bron,x,y`. Met P2 erbij staat `coop` in de naam in plaats van `solo`. De D in de naam is die van de run.
- Het meetlog staat standaard aan, maar alleen als de Kadewijk de scène van de run is (`current_scene`), dus via F6 of de commandline. In de tests is hij dat niet, dus daar komt er geen CSV. Een test zet hem aan met `save_csv = 1` en `log_dir`.
- Een afgebroken run sluit het log eerst af met `finish()`: een open stilstand krijgt zijn `STIL_EIND` en het log eindigt op `RUN_EIND`. Na een gewone `RUN_EIND` schrijft afbreken niets meer.
- **Let op:** de stopknop van de editor (■, F8 in de editor) beëindigt het spel zonder melding. Dan komt er geen CSV. Sluit dus het spelvenster zelf, met het kruisje of Alt+F4.

## 3. De regel `DEBUG` (V-7)

Druk je in het spel op F8 (naar de volgende kamer), een D-toets (F1/F2/F3/F7) of F4 (echo aan/uit), dan komt er eerst een regel in het meetlog:

| Toets | `waarde` | `bron` |
|---|---|---|
| F8 | `F8` | de kamer waar P1 heen springt, bv. `S2` |
| F1/F2/F3/F7 | de toets | de nieuwe D, bv. `D90` |
| F4 | `F4` | `echo_uit` of `echo_aan` |

F4 en de D-toetsen herladen de scène, dus die run staat daarna als `_afgebroken` op schijf, met de `DEBUG`-regel erin. F8 herlaadt niets en de run loopt door. Testplan §4.1: vanaf een `DEBUG`-regel telt de run niet meer voor MP-1 tot en met MP-3.

## 4. Tests

`game/tests/test_kadewijk_meetlog.gd`, in de groep `kort`:
- de MT1-start is ongewijzigd, en de start gebruikt D = 60 met de echo aan;
- een korte bot-run S1 → S2 schrijft één CSV, met de juiste naam, de kop, 7 kolommen per regel, precies één `RUN_EIND` en dezelfde inhoud als het meetlog;
- het venster sluiten geeft `_afgebroken`;
- `DEBUG` voor F8 (via het debugmenu), F4 en F2, en de regel `DEBUG` staat ook in de afgebroken CSV.

## Open punten

- Op de kaart en in V-5 staat nog "F5 in de editor". Tot de hoofdscène omgaat, is het "kadewijk.tscn openen, F6" (§1). Punt voor QA, in `ceo-kaart-mt2.md`.
