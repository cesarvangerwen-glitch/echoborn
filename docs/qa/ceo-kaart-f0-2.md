# CEO-kaart F0-2: de nieuwe flow-kamer spelen en scoren (tweede flow-test)

Versie 0.1.1 · 2026-11-11 · Eigenaar: QA Lead · Issue: [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80) · Achtergrond voor QA: `docs/qa/testplan-f0-2.md` (lees je pas na het spelen)

**Tijd: ± 20–25 min.** Je speelt alleen solo (besluit [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124)). Geen luistercheck deze keer. Je speelt 8 korte runs, geeft na elke run drie cijfers, beantwoordt een paar vragen en geeft alles in de Claude-chat.

**Lees §1–§4. Lees §5 pas als je §4 tot en met O2 ingevuld hebt, en §6 pas nadat je het antwoordblok verstuurd hebt.**

Build: commit `________` (QA vult in). Zip van precies die versie: `https://github.com/cesarvangerwen-glitch/echoborn/archive/________.zip` (QA vult in; speel niet met een andere zip).

## 1. Klaarzetten (Windows, ± 3 min)

1. Open de zip-link bovenaan deze kaart (niet "Download ZIP" van de hoofdpagina: daar kan intussen iets nieuws bij zijn gekomen). Pak uit in een **nieuwe** map (niet over de oude van F0 heen).
2. **Oude meetlogs opzij:** open `%APPDATA%\godot\app_userdata\Echoborn` (plak in de adresbalk van de Verkenner), maak er een submap `F0` en verplaats alle bestanden `meetlog_*.csv` daarheen. Lukt dat niet: noteer hoe laat je begint (tijd: ____).
3. Start `Godot_v4.6.3-stable_win64.exe` (dezelfde als bij F0). Kies **Importeren**, wijs `game\project.godot` in de **nieuwe** map aan en open het project. Staat de oude F0-versie ook in de lijst: kies de nieuwe.
4. Druk in de editor op **F5**. De flow-kamer start.
5. Druk daarna **eerst A, D of spatie** (niet een pijltje: dan werkt spatie niet om te springen). Mis? Sluit het spelvenster, druk in de editor opnieuw F5.
6. Kijk in de HUD: er moet **meetlog aan** staan (Engelse Windows: *measurement log on*). Staat er *meetlog uit*: druk één keer F5 in het spelvenster.

## 2. Besturing

| | Toets |
|---|---|
| Lopen, springen, dash, slaan/pompen | A/D, spatie, linker Shift, E |
| Staart kiezen (start een nieuwe run) | **F1** = 1,5 s · **F2** = 2 s · **F3** = 3 s. Op een laptop: **Fn + F1/F2/F3** |
| Run opnieuw | F6 (Fn + F6) |
| Na de run | drie cijfers **1–5**: K1, K2, K3 (in die volgorde) |

- **Na elke F-toets: kijk in de HUD naar drie dingen.** (1) De goede D: 1,5 s = **D 90**, 2 s = **D 120**, 3 s = **D 180**; zo niet, druk de toets opnieuw (met Fn). (2) **meetlog aan** (*measurement log on*); zo niet, druk één keer F5 in het spelvenster. (3) De echo is **niet uit**; staat er echo uit, druk één keer F4. F4 en F5 blijven ook na een nieuwe run staan: een per ongeluk ingedrukte F4 of F5 maakt alle runs erna ongeldig, tot je dezelfde toets nog een keer drukt.
- **Na de run** staat op het scorescherm *Run klaar … bij D = …*. De F-toetsen doen pas weer iets als je drie cijfers gaf.
- **Niet drukken**: Enter of Start (dan doet er een tweede speler mee), F4 (zet de echo uit), F5 in het spelvenster (zet de meetlog uit, ook tijdens het scoren).

Het doel van een run: door K1 (sprongen), K2 (vijanden), K3 (sla op de pompschoepen tot het gemaal vol is), dan door de sluis.

## 3. Draaiboek

**De score per kamer** is steeds: *"Voelde het vloeiend/satisfying?"* 1 = stroef, 5 = heerlijk vloeiend. **V1** is: *"Wist je waar je echo zou zijn?"* 1–5.

| Stap | Druk | Run | Daarna |
|---|---|---|---|
| Oefenen 1 | F2 (D 120) | oefenrun | drie willekeurige cijfers in het spel |
| Oefenen 2 | F2 (D 120) | oefenrun | drie willekeurige cijfers |
| Run 1 | **F3** (D 180) | telt | drie cijfers in het spel **en** in §4: D van het scorescherm, K1/K2/K3, V1 |
| Run 2 | **F1** (D 90) | telt | idem |
| Run 3 | **F2** (D 120) | telt | idem |
| Run 4 | **F1** (D 90) | telt | idem |
| Run 5 | **F3** (D 180) | telt | idem |
| Run 6 | **F2** (D 120) | telt | idem |

- Geef de cijfers **meteen** na de run (niet later).
- Vast, of iets misgegaan (verkeerde D, toets niet aangekomen)? **F6** en speel die run opnieuw; lukt hij niet, speel hem aan het eind nog één keer. Afgebroken runs worden bewaard en tellen niet; schrijf er gerust "run 3 opnieuw" bij.

## 4. Antwoordblok (kopieer in de Claude-chat)

Vul de vragen in van boven naar beneden, meteen na run 6.

```
[CEO → QA Lead]: flow-test F0-2 (solo)

Runs (D van het scorescherm · K1 / K2 / K3 · V1)
- Run 1: D ___ · _ / _ / _ · V1 _
- Run 2: D ___ · _ / _ / _ · V1 _
- Run 3: D ___ · _ / _ / _ · V1 _
- Run 4: D ___ · _ / _ / _ · V1 _
- Run 5: D ___ · _ / _ / _ · V1 _
- Run 6: D ___ · _ / _ / _ · V1 _
Opmerking bij een run (mag leeg): ...

M1 Waar deed het merk (wat je met slaan op een vijand zet) je aan denken? (open, één zin): ...
M2 Kies één moment waarop een merk wel of juist niet iets deed: waarom gebeurde dat (niet)? (één zin): ...
H  Echo: hulp of last? (1–5, 5 = hulp): _
O1 Hoe kwam je in K1 meestal een verdieping hoger? (één zin): ...
O2 Zag je iets dat liet zien waar je echo zou komen, of welk merk zou knallen? Wat? (één zin): ...

S1 (pas na §5): _
S2 (pas na §5): _

Bijlage: alle meetlog-CSV's van vandaag
```

**Meetlogs meegeven:** open `%APPDATA%\godot\app_userdata\Echoborn` (plak dit in de adresbalk van de Verkenner). Selecteer alle bestanden `meetlog_*.csv` die nu niet in de submap `F0` staan (of, zonder submap: alle bestanden vanaf je starttijd; de naam begint met datum en tijd, bv. `meetlog_20261112-1930…`), ook de `_afgebroken`, en **sleep ze in de Claude-chat** bij het antwoordblok. Niet als bijlage in een GitHub-comment: die kunnen de agents niet openen. (Commit je liever zelf: zet ze in `docs/qa/f0-2-meetlogs/`.) Verwijder niets.

## 5. Twee korte vragen (lees pas als O2 ingevuld is)

- **S1** Zag je een plank oplichten of tikken als je echo naar je toe kwam? *ja / nee / niet op gelet*, en zo ja: hielp het?
- **S2** Zag je vóór een knal een streep naar het merk, of een cirkel om het merk? *ja / nee / niet op gelet*, en zo ja: hielp het?

## 6. Wat QA ermee doet (lees pas nadat je het antwoordblok verstuurd hebt)

- **Norm (3), MP-5**: per staart het gemiddelde van je scores over de twee runs; ≥ 4,0 en geen kamer < 3,0. De staart met de hoogste score die ook de objectieve normen haalt, wordt gekozen (gelijk = 2 s). Dit is de eerste geldige meting op 3 s.
- **Uit de CSV's**: stilstand (nergens > 5 s), echo-acties per minuut, echo Leeg, de echo bij het gemaal; en per keerpunt in K1 of je **omdraaide en je echo tegemoet liep**, op hem wachtte (en waar), of de treden nam. Daarom vroeg de kaart vooraf niets over hoe je omhoog moest: O1 en het log laten zien wat je uit jezelf deed.
- **S1–S2** gaan over twee nieuwe tekens: de plank van je echo licht op als hij naar je toe komt, en vóór een knal zie je een streep en een cirkel met het bereik. QA kijkt of je ze opmerkte zonder dat iemand ze aanwees.
- **M1** is opnieuw het zwakke *Nine Sols*-signaal, zoals in F0; **M2** telt als begrepen bij "de echo kwam (niet) langs" of "het merk was te ver / gedoofd".
- QA schrijft het rapport (`docs/qa/rapport-f0-2-flowtest.md`) en het advies: go F0 met een staart, of wat er dan moet gebeuren. Een vraag aan jou volgt alleen als het rapport dat nodig maakt.

## Wijzigingen

| Versie | Datum | Wijziging |
|---|---|---|
| 0.1 | 2026-11-11 | Eerste versie (#80, T17-2 deel 1): nieuwe build als zip, 2 oefenruns + 6 getelde runs (180, 90, 120, 90, 180, 120), D van het scorescherm per run, M1/M2/H, O1/O2 en daarna S1/S2, CSV's in de Claude-chat; geen luistercheck |
| 0.1.1 | 2026-11-11 | Na Lead-review EP: HUD-check na elke F-toets op D, meetlog aan en echo aan (F4/F5 blijven staan); oude meetlogs eerst naar een submap of starttijd noteren; zip-link van de ingevulde commit; §6 pas na het versturen van het antwoordblok |
