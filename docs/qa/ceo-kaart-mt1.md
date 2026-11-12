# CEO-kaart MT1: de flow-kamer op 1 s spelen en scoren

Versie 0.1.3 · 2026-11-12 · Eigenaar: QA Lead · Issue: [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80) · Achtergrond voor QA: `docs/qa/testplan-mt1.md` (lees je pas na het spelen)

**Tijd: ± 12–15 min.** Solo. Je speelt **4 korte runs** (1 oefenrun + 3 die tellen), allemaal op de staart van **1 s (D = 60)**. Na elke run geef je in het spel drie cijfers. Daarna typ je zeven korte antwoorden in de Claude-chat en sleep je de meetlogs erbij. Geen kladje nodig.

Je speelt dit pas nu omdat de bots op 1 s groen zijn.

**Lees §1–§3. Lees §5 pas nadat je het antwoordblok verstuurd hebt.**

Build: commit `d9f420c`. Zip van precies die versie: https://github.com/cesarvangerwen-glitch/echoborn/archive/d9f420ce8d68e1227e2703fbd41a9ca7d73d9dee.zip (speel niet met een andere zip).

## 1. Klaarzetten (Windows, ± 3 min)

1. Open de zip-link hierboven en pak uit in een **nieuwe** map (niet over een oude heen).
2. **Oude meetlogs opzij:** plak `%APPDATA%\godot\app_userdata\Echoborn` in de adresbalk van de Verkenner, maak een submap `oud` en verplaats alle `meetlog_*.csv` daarheen. Lukt dat niet: noteer hoe laat je begint (tijd: ____).
3. Start `Godot_v4.6.3-stable_win64.exe` (dezelfde als vorige keer), kies **Importeren**, wijs `game\project.godot` in de **nieuwe** map aan en open het. Het eerste importeren duurt ± 1 min.
4. Druk in de editor op **F5**. De flow-kamer start.
5. Druk daarna **eerst A, D of spatie** (geen pijltje: dan werkt spatie niet om te springen). Mis? Sluit het spelvenster en druk in de editor opnieuw F5.
6. **HUD-check** (bovenaan het scherm):
   - op de regel *Kamer K1   D = 60   echo Actief   tijd …* staat **D = 60**. Je hoeft geen F-toets te drukken: 60 is nu de standaard. Staat er iets anders: druk **F1** (laptop: **Fn + F1**);
   - op dezelfde regel staat *echo Actief* of *echo Leeg* (allebei goed), niet *echo uit*. Staat er *echo uit*: druk één keer F4;
   - op de regel met de F-toetsen staat **F5 meetlog aan** (Engelse Windows: *measurement log on*). Staat er *uit*: druk één keer F5 in het spelvenster.

## 2. Spelen

| | Toets |
|---|---|
| Lopen, springen, dash, slaan/pompen | A/D, spatie, linker Shift, E |
| Volgende run, of opnieuw als je vastzit | F6 (laptop: Fn + F6) |
| Na de run | drie cijfers **1–5**: K1, K2, K3, in die volgorde |

Het doel: door K1 (sprongen), K2 (vijanden), K3 (sla op de pompschoepen tot het gemaal vol is), dan door de sluis.

**Na elke run** vraagt het scorescherm per kamer: *"Voelde het vloeiend/satisfying?"* 1 = stroef, 5 = heerlijk vloeiend. Geef de cijfers **meteen**. Daarna staat er *Bedankt. Meetlog: …*. Druk **F6** (laptop: Fn + F6) voor de volgende run; F6 houdt D = 60. Kijk dan even of de HUD nog **D = 60** en **meetlog aan** zegt.

| Run | Telt? |
|---|---|
| 1 | oefenrun: speel gewoon, geef wel drie cijfers |
| 2, 3, 4 | tellen |

- **Niet drukken**: Enter of Start (dan doet er een tweede speler mee), F2/F3/F7 (andere staart), F4 (echo uit), F5 in het spelvenster (meetlog uit).
- Vast of iets mis tijdens een run? F6 start de run opnieuw; speel aan het eind **één** run extra. Afgebroken runs worden bewaard en tellen niet. Staat het scorescherm er al (*Run klaar …*), dan doet F6 niets tot je de drie cijfers gaf: geef ze eerst, ook als de run misging, en zet dat bij X.

## 3. Antwoordblok (typ in de Claude-chat)

Kopieer het blok, vul van boven naar beneden in, **in je eigen woorden, kort** (een paar woorden of één zin is genoeg). Er zijn geen goede of foute antwoorden.

```
[CEO → QA Lead]: mijlpaaltest MT1 (solo, D = 60)

R  Wat was je schaduw voor jou: iemand die meedeed, of een spoor achter je aan? ...
M1 Waar deed het merk (wat je met slaan op een vijand zet) je aan denken? ...
O1 Hoe kwam je in K1 meestal een verdieping hoger? ...
M2 Kies één moment waarop een merk wel of juist niet knalde: waarom gebeurde dat? ...
H  Echo: hulp of last? (1–5, 5 = hulp): _
V1 Wist je waar je echo zou zijn? (1–5, 5 = altijd): _
X  Ging er iets mis (vast, afgebroken, verkeerde toets, iets raars)? ...

Bijlage: alle meetlog-CSV's van vandaag
```

**Meetlogs meegeven:** open `%APPDATA%\godot\app_userdata\Echoborn` en selecteer alle `meetlog_*.csv` die niet in de submap `oud` staan (zonder submap: alle bestanden vanaf je starttijd; de naam begint met datum en tijd), ook de `_afgebroken`. **Sleep ze in de Claude-chat** bij het antwoordblok. Niet als bijlage in een GitHub-comment: die kunnen de agents niet openen. Verwijder niets.

## 4. Klaar

Dat was het. De agent in de chat zet je antwoorden en de logs in de repo; QA schrijft het rapport.

## 5. Wat QA ermee doet (lees pas nadat je het antwoordblok verstuurd hebt)

- **Je cijfers** komen uit het meetlog. Norm (3) is gehaald als het gemiddelde over run 2–4 **≥ 4,0** is en geen kamer gemiddeld onder 3,0 zit. Dat is het laatste stuk van de eerste mijlpaal (F0).
- **Uit de logs**: nergens > 5 s stil, de echo als plank of merk-afmaker ≥ 3× per minuut (ook in K1 en K2 apart), echo Leeg ≤ 40 %, de echo bij het gemaal. En per keerpunt in K1 of je **omdraaide en op je echo sprong zonder te wachten**, eerst op hem wachtte (en waar), of de treden nam. Daarom zei de kaart vooraf niets over hoe je omhoog moest: O1 en het log laten zien wat je uit jezelf deed.
- **Haal je dat springen zonder wachten niet** (≥ 75 % van de landingen), of gebruik je de echo in K1 te weinig, dan past de Lead Game Designer eerst de kamer aan en test het team dat met de bots, zonder jou. Alleen als de regel voor hoe de echo op je reageert moet veranderen, krijg je daar één vraag over (open punt O-23). Een nieuwe speelsessie volgt pas bij de volgende mijlpaal.
- **R** is de vraag van de Creative Director: voelt de echo bij 1 s als een tweede lichaam of als een nabeeld? Samen met H (≥ 4) is dat een signaal, geen slaag-of-zakvraag. Leest hij als een spoor, dan kijkt eerst de Art Director naar hoe de echo eruitziet.
- **M1** is het zwakke *Nine Sols*-signaal; **M2** telt als begrepen bij "de echo kwam (niet) langs" of "het merk was te ver / gedoofd". Deze keer allemaal open vragen, zonder keuzes.
- Een vraag aan jou volgt alleen als het rapport dat nodig maakt.

## Wijzigingen

| Versie | Datum | Wijziging |
|---|---|---|
| 0.1 | 2026-11-12 | Eerste versie (#80, T17 MT1): D = 60 standaard bij het starten, F1 alleen als herstel (F1/F2/F3/F7 = 60/90/120/180); 1 oefenrun + 3 getelde runs, alle op D = 60, volgende run met F6; scores alleen in het spel; zeven korte open antwoorden (R van de CD vóór H) en de meetlogs via de Claude-chat; HUD-check en "na F5 eerst A, D of spatie" behouden |
| 0.1.1 | 2026-11-12 | Na Lead-review EP: §5, bij springen met wachten eerst een herontwerp met de bots, een vraag aan de CEO alleen als de echo-regel moet veranderen (O-23) |
| 0.1.2 | 2026-11-12 | Build `d9f420c` en zip-link ingevuld (na de merge van #202) |
| 0.1.3 | 2026-11-12 | Na SM-review: geen verwijzing naar het testplan in de kop; bij "Vast of iets mis?" dat F6 op het scorescherm pas na de drie cijfers werkt (G-5) |
