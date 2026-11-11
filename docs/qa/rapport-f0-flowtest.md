# Rapport F0: flow-test van de grijze flow-kamer (T17)

Versie 0.3 · 2026-11-11 · Eigenaar: QA Lead (met Lead Game Designer) · Issue: [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80) · Lead-review: Executive Producer

Plan: `docs/qa/testplan-f0.md`. Deel 1 (scripted runs) staat in §2–§4, deel 2 (de CEO-sessie solo, met `docs/qa/ceo-kaart-f0.md`) in §5, het QA-advies in §6. F0 slaagt op de solo-normen; de co-op-metingen zijn meting, geen F0-voorwaarde (besluit [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124): 1B; kader §3 F0 en F4b(c)). De meetlogs van de CEO staan in `docs/qa/f0-meetlogs/`.

## 1. Samenvatting

- **QA-advies: geen go F0. Herontwerp door de LGD en een tweede flow-test** (testplan §5, rij 2). Geen `ceo-beslissing` nodig: norm (2) is gehaald (§6).
- **Norm (3) niet gehaald, bij geen enkele staart.** De CEO gaf gemiddeld 1,0 / 2,0 / 1,3 per run (doel ≥ 4,0, geen kamer < 3,0). K3 (het gemaal) kreeg in elke run een 1.
- **Bij een mens wacht de springplank op je (R-V12).** Vóór 12 van de 14 springplank-landingen in de drie geldige runs stond de CEO ≥ 20 ticks stil, meestal ± D ticks (MP-3: 0–25 % zonder stilstand, norm ≥ 75 %; de bot haalde 100 %). Dat past bij "het duurde te lang" en "sneller kon bewegen met de echo".
- **Norm (1) bij het gemaal**: langste stilstand steeds in K3 aan de waterkant (175 / 366 / 212 ticks); één run (D = 90) haalt 300 niet.
- **Gehaald**: norm (2) (MP-2 12,8–13,4 echo-acties/min, K1 en K2 elk ≥ 9,8), MP-4 (2–3 % Leeg) en MP-6 (80–82 % van de LP met de echo, 7–8 pompslagen van de echo).
- **Er is geen geldige meting van 3 s.** Geen meetlog heeft D = 180; de "3 s"-scores van de CEO staan in-game bij een run op D = 90 (§5.1). 3 s volgt in de tweede flow-test; tot dan blijft dat deel van de DoD van T17 open. Het advies hierboven steunt er niet op.
- ***Nine Sols***: niet spontaan genoemd (M1). Volgens kader §3 is de check niet gehaald maar uitgesteld naar F4b(c). De merksprong was niet leesbaar (M2).
- **Staartkeuze**: nog geen. Tot de tweede flow-test blijft D = 120 de werkaanname (gdd, werkaanname LGD (3)).
- **Co-op** telt in F0 niet mee (§4; normen in F4b(c)).

## 2. Opzet (deel 1)

`game/tests/test_flowtest_t17.gd`, 10 runs in de gewone suite (171 tests groen na de merge van main met #117, Linux, Godot 4.6.3, ± 33 s; de T17-getallen zijn na die merge gelijk gebleven). Elke run eindigt met `RUN_EIND`; de schaduwpartner-run D = 120 tweemaal gedraaid gaf twee keer hetzelfde meetlog. Getallen hieronder komen uit de `T17 …`-regels van die uitvoer. 60 ticks = 1 s.

## 3. Solo, scripted runs (deel 1)

| | D = 90 (1,5 s) | D = 120 (2 s) | D = 180 (3 s) | Norm |
|---|---|---|---|---|
| Runtijd | 63,5 s | 65,4 s | 76,6 s | — |
| **MP-1** langste stilstand P1 | 107 ticks | 137 | 197 | ≤ 300 ✅ |
| **MP-2** echo-acties/min (K1 / K2) | 14,2 (8,8 / 39,9) | 12,8 (8,6 / 34,4) | 11,0 (8,1 / 22,3) | ≥ 3,0, ook per kamer ✅ |
| MP-2 langste gat zonder echo-actie | 13,5 s | 12,8 s | 14,9 s | ≤ 40 s ✅ |
| **MP-3** (R-V12) springplank-landingen/min | 4,7 | 4,6 | 3,9 | rapporteren |
| MP-3 aandeel zonder stilstand | 100 % | 100 % | 100 % | ≥ 75 % ✅ |
| **MP-4** echo Leeg | 2,4 % | 3,1 % | 3,9 % | ≤ 40 % ✅ |
| **MP-6** LP met de echo; pompslagen echo | 81 % van 108; 5 | 81 % van 108; 5 | 81 % van 108; 5 | ≥ 40 %; ≥ 1 ✅ |
| Bounce/min · merk-combo/min · lancering · vang | 4,7 · 8,5 · 0 · 1 | 4,6 · 7,3 · 0 · 1 | 3,9 · 6,3 · 0 · 1 | vraag 8: bounce en merk-combo ≥ 1/min ✅ |
| Echo breekt | 0 | 0 | 0 | 0 (FK-4) ✅ |
| Echo uit (FK-2, uit `test_flowkamer.gd`) | 1,55× · 2 terugkeren | 1,52× · 2 | 1,31× · 2 | ≤ 2× · ≤ 4 ✅ |

Wat opvalt:

- **De langste stilstand zit bij het gemaal** en groeit met D (107 → 197 ticks): P1 wacht aan de waterkant tot de echo zijn pompslagen herhaald heeft (`flowkamer.md` §9). Bij D = 180 blijft er 103 ticks marge tot de 300. Een mens die trager pompt, kan daar dichter bij de grens komen: dit is de plek om bij de CEO op te letten (kaart, observatie O1).
- **MP-2 daalt met D** (14,2 → 11,0/min), vooral in K2 (39,9 → 22,3): een langere staart maakt de merk-arena trager. Ook bij D = 180 ligt het ruim boven de 3,0.
- **Landingen per bouwsteen** (vraag 4): B3, B1 en elke verdieping van B2 geven elk 1 landing; **B4 en K2 geven er 0**. K2 is de merk-arena (de echo werkt daar als merk-afmaker, dat is bedoeld). B4 is gemeten via de langzame lijn: de bot lanceert nog niet (§8 punt 2).
- MP-3 is 100 % omdat de bot nooit op zijn echo wacht; bij mensen is dit de maat die R-V12 echt toetst.

## 4. Co-op (ondergrenzen; meting, geen F0-voorwaarde)

In co-op is er geen echo: P2 is het tweede lichaam (gdd §2.7). P2 komt erin zodra de echo er is (tick D + 1) en neemt zijn plek over (C-01).

| | Schaduwpartner D = 90 | D = 120 | D = 180 | Meeloper D = 90 | D = 120 | D = 180 | Norm |
|---|---|---|---|---|---|---|---|
| P2 raakt het spoor van P1 kwijt op tick | 825 | 885 | 1005 | — | — | — | — |
| Runtijd | 98,2 s | 98,7 s | 99,7 s | 98,8 s | 99,3 s | 100,3 s | — |
| MP-1 langste stilstand P1 | 101 | 101 | 101 | 101 | 101 | 101 | ≤ 300 ✅ |
| MP-2 echo-acties/min (K1 / K2) | 0,61 (1,5 / 0) | 0,61 (1,5 / 0) | 0,60 (1,4 / 0) | 0 | 0 | 0 | ≥ 3,0 ❌ |
| MP-3 landingen/min | 0 (1 vang in B3) | 0 | 0 | 0 | 0 | 0 | rapporteren |
| MP-4 zonder tweede lichaam (W4) | 3,6 % | 4,1 % | 5,0 % | 5,6 % | 6,1 % | 7,0 % | ≤ 40 % ✅ |
| MP-6 LP met P2/samen; pompslagen P2 | 3 % van 117; 0 | 3 %; 0 | 3 %; 0 | 0 % van 114; 0 | 0 %; 0 | 0 %; 0 | ≥ 40 %; ≥ 1 ❌ |
| MP-7 (a) runtijd co-op ÷ solo | 1,55 | 1,51 | 1,30 | 1,55 | 1,52 | 1,31 | ≥ 0,5 ✅ |
| MP-7 (b) langste stilstand P2 (W5) | 147 | 147 | 147 | 448 | 418 | 358 | ≤ 300 ✅ / ❌ |
| MP-7 (c) samenwerkingsacties/min per speler | 0,61 | 0,61 | 0,60 | 0 | 0 | 0 | ≥ 1,0 ❌ |
| MP-7 (d) P2 opgelost | 2,1 % (1×) | 2,1 % | 2,1 % | 4,1 % (2×) | 4,1 % | 4,1 % | ≤ 10 % ✅ |

Wat dit wel en niet zegt:

- **Niet**: dat co-op de normen mist. Beide partners doen bijna niets samen. De schaduwpartner werkt tot B3 (P1 vangt zich op P2), maar dan staat P1 hoger en kan P2 niet volgen: anders dan de echo, die zijn opgenomen posities afspeelt, heeft een levend lichaam zelf een plank nodig om omhoog te komen, en P1 is al verder. Daarna loopt P2 alleen mee. Een echt duo wisselt van rol (P2 bounct ook op P1, gdd §2.7); die run bestaat nog niet.
- **Wel**: (1) co-op zonder samenwerken is **trager** dan solo met echo (1,3–1,55×) en blijft binnen FK-2/C-15 (≤ 2× de run met echo uit): de route blijft open. (2) MP-7 (a) "niet meer dan 2× zo snel" kan pas mislukken met een duo dat écht samenwerkt; dat is precies de run die ontbreekt. (3) **Een P2 die niet meeklimt, staat 6–7,5 s stil zonder dat de leiband hem oplost** (meeloper, MP-7 b 358–448 ticks), want hij blijft in beeld onder P1. Bij een mens is dat een "ik wacht"-moment; observatie voor F4b(c) en een punt voor de LGD (C-07).

## 5. Deel 2: de CEO solo

Bronnen: het antwoordblok van de CEO in [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6803459340) en de zeven meetlogs die hij meestuurde (`docs/qa/f0-meetlogs/`). Build: `game/` zoals op main (ongewijzigd sinds 85e9115). Uitgerekend met `flow_report.gd` (Godot 4.6.3, headless) via `docs/qa/f0-meetlogs/rekenen.gd`:

```
godot --headless --path game -s "$PWD/docs/qa/f0-meetlogs/rekenen.gd" -- "$PWD/docs/qa/f0-meetlogs"
```

Waar het rapport méér zegt dan `flow_report.gd` uitrekent (plaats van de langste stilstand, de stilstand vóór elke landing), komt dat uit dezelfde CSV-regels (`STIL_EIND` met bron `p1`, `SPRINGPLANK`), met dezelfde MP-3-regel (≥ 20 stille ticks in de 120 ticks vóór de landing).

### 5.1 Welke run is welke staart

De D van een run staat in de bestandsnaam en is te controleren in het log zelf: de echo begint Leeg tot tick D (E-03), dus de eerste `ECHO_LEEG_EIND` ligt op tick D. Dat klopt voor elk bestand.

| Bestand (eindtijd run) | D in het log | In-game score K1/K2/K3 | Wat het is |
|---|---|---|---|
| 18:46:00 `_afgebroken` | 120 | — | afgebroken (243 s, vast in K2) |
| 18:46:01 `_afgebroken` | — (1,4 s) | — | afgebroken meteen na de herstart |
| 18:48:01 | 120 | 2/2/2 | oefenrun 1 (telt niet, W7) |
| 18:50:06 | 120 | 2/3/3 | oefenrun 2 (telt niet, W7) |
| 18:53:04 | **90** | **1/1/1** | in het antwoordblok "3 s" |
| 19:07:23 | 90 | 3/2/1 | in het antwoordblok "1,5 s" |
| 19:08:58 | 120 | 2/1/1 | in het antwoordblok "2 s" |

**Er is geen log met D = 180.** De CEO zegt dat hij de 3-s-log per ongeluk verwijderde en dat zijn scores kloppen. Maar de in-game scores van de run van 18:53 (D = 90) zijn precies zijn "3 s"-scores, en de twee andere runs passen precies op zijn "1,5 s" en "2 s". Was er een vierde, verwijderde run op 3 s geweest, dan zou die toevallig ook 1/1/1 moeten hebben gekregen. De waarschijnlijkste verklaring: **F3 kwam niet aan** (op veel laptops vraagt een F-toets Fn) en de CEO speelde zijn "3 s"-run op 1,5 s. QA behandelt de "3 s"-scores daarom als **onzeker en niet als meting van 3 s**, en koppelt scores aan een D alleen via het log.

Twee kanttekeningen bij de run van 18:53:

- De scores staan ± 46 000 ticks (± 13 min) na `RUN_EIND` in het log: ze zijn later gegeven, niet meteen na de run.
- Dezelfde D gaf twee keer heel andere scores (1,0 en 2,0 gemiddeld). Dat kan oefening zijn (run 3 tegenover run 4) of verwachting (de CEO dacht dat het 3 s was). Met deze runs zijn die twee niet te scheiden.

De tijden in de bestandsnamen komen van de klok van de laptop; de runs van 19:07 en 19:08 eindigen later dan het tijdstip van het antwoordblok in #80 (19:03 Brusselse tijd; de antwoorden zijn in de chat verzameld en door de Producer geplaatst). Of de klok gelijk liep, is niet na te gaan; QA trekt er geen conclusie uit en koppelt alleen via de in-game scores, die exact overeenkomen.

### 5.2 Objectieve normen per run

De drie geldige runs (vanaf de derde run, W7). Kolomkop = D uit het log; tussen aanhalingstekens het label van de CEO.

| | D = 90 (18:53, "3 s") | D = 90 (19:07, "1,5 s") | D = 120 (19:08, "2 s") | Norm | Bot (deel 1, D 90 / 120) |
|---|---|---|---|---|---|
| Runtijd | 75,0 s | 85,2 s | 65,4 s | — | 63,5 / 65,4 s |
| **MP-1** langste stilstand | 175 (K3, waterkant) | **366** (K3, waterkant) | 212 (K3, waterkant) | ≤ 300; > 360 niet gehaald | 107 / 137 |
| **MP-2** echo-acties/min (K1 / K2) | 12,8 (9,8 / 19,7) | 13,4 (11,4 / 21,3) | 12,9 (10,2 / 20,4) | ≥ 3,0, ook per kamer ✅ | 14,2 / 12,8 |
| MP-2 langste gat | 12,7 s | 14,3 s | 11,8 s | ≤ 40 s ✅ | 13,5 / 12,8 s |
| **MP-3** (R-V12) landingen/min | 4,0 | 3,5 | 3,7 | rapporteren | 4,7 / 4,6 |
| MP-3 zonder stilstand | **20 %** (1 van 5) | **0 %** (0 van 5) | **25 %** (1 van 4) | ≥ 75 % ❌ | 100 % |
| **MP-4** echo Leeg | 2 % | 2 % | 3 % | ≤ 40 % ✅ | 2,4 / 3,1 % |
| **MP-6** LP met de echo; pompslagen echo | 82 % van 110; 8 | 82 % van 122; 7 | 80 % van 101; 8 | ≥ 40 %; ≥ 1 ✅ | 81 %; 5 |
| Merksprongen (alle met ontploffing) | 10 | 11 | 9 | — | — |
| Echo breekt | 0 | 0 | 0 | 0 ✅ | 0 |

Wat opvalt:

- **De CEO wacht op elke springplank in K1 ± D ticks.** De stilstand vóór de eerste drie landingen is 75–106 ticks bij D = 90 en 121–139 bij D = 120: hij staat bij elk blok stil tot zijn echo er is. Bij D = 180 zou die wachttijd per blok naar verwachting ± 180 ticks worden. Dit is R-V12 ("springplank ligt achter je") bij een mens; de bot wacht nooit, dus deel 1 kon dit niet zien.
- **De langste stilstand zit altijd aan de waterkant van K3** (O1 uit de kaart, zoals voorspeld in deel 1): de CEO wacht daar tot de echo zijn pompslagen herhaalt. Bij D = 90 eenmaal 366 ticks: boven de grens van 360, dus norm (1) is in die run niet gehaald, ook niet als grensgeval.
- **In K2** staan in de runs van 19:07 en 19:08 stilstanden van 160 en 192 ticks in de merk-arena: waarschijnlijk wachten op de merksprong.
- Elke `ONTPLOFFING` in de logs is schakel 1: de CEO maakte geen ketting. "Twee mannetjes tegelijk" (M2) is dus geen ketting, maar waarschijnlijk één ontploffing die twee vijanden binnen haar bereik raakte (`explosion_radius_px`, `combat.gd`).
- De oefenruns (D = 120) laten de leercurve zien: MP-1 van 982 ticks (in K1, bij de start) naar 239.

### 5.3 Wat de CEO zei

| Vraag | Antwoord | Wat QA ermee doet |
|---|---|---|
| **MP-5** (norm 3) per kamer | D = 90: 1/1/1 (1,0) en 3/2/1 (2,0) · D = 120: 2/1/1 (1,3) · D = 180: geen geldige meting | Niet gehaald bij elke gemeten D: geen gemiddelde ≥ 4,0, en elke kamer van elke run < 3,0 behalve K1 = 3 in één run. K3 = 1 in alle drie |
| V1 "wist je waar je echo zou zijn?" (vraag 1) | "3 s" 1,5 ("ja, maar het duurde te lang") · "1,5 s" 3,5 ("al beter omdat je sneller kon bewegen met de echo") · "2 s" 2,5 ("tussen de twee") | De opmerkingen gaan over wachten, niet over voorspellen: ze passen bij MP-3. De "3 s"-waarde hoort waarschijnlijk bij een run op D = 90 (§5.1) |
| M1, *Nine Sols*-check (vraag 5) | "niet direct iets anders" | Niet spontaan genoemd: zwak signaal negatief. Check niet gehaald, uitgesteld naar F4b(c) (kader §3 F0, W8) |
| M2, merksprong leesbaar? (vraag 6) | "het merk schakelde twee mannetjes tegelijk uit, geen idee waarom" | **Niet begrepen** volgens de regel van de kaart (§5: begrepen bij "de echo kwam (niet) langs" of "te ver/gedoofd"). Zie §5.2: waarschijnlijk één ontploffing met bereik |
| Echo solo: hulp of last? (vraag 8) | 3,5 | Neutraal tot licht hulp; geen last, geen duidelijke hulp |
| Luistercheck F2 (audio bible §9.4) | carillon: ja (na uitleg dat een carillon een beiaard is) · slag 2,6 s "jij, maar hol": ja · opgepompt deel warmer: ja · "Over het algemeen vind ik de soundbites heel leuk." | Drie keer ja. Bij vraag 1 hielp het woord "beiaard": het geluid werd herkend, het woord "carillon" niet meteen. Voor de Audio Director |

## 6. QA-advies F0

Per regel van testplan §5 en de DoD van T17:

| Eis (DoD T17) | Uitkomst | Gehaald? |
|---|---|---|
| Norm (1), MP-1 | Bot: ja bij elke D. CEO: 175 en 212 ja, 366 nee (D = 90, K3) | ❌ niet in elke run; krapste plek het gemaal |
| Norm (2), MP-2 | Bot en CEO ruim boven 3,0 (CEO 12,8–13,4/min), geen gat > 15 s | ✅ |
| Norm (3), MP-5 | CEO gemiddeld 1,0–2,0; geen D ≥ 4,0 | ❌ |
| Staart 1,5 / 2 / 3 s | 1,5 en 2 s gemeten; **3 s niet** (geen D = 180-log) | onvolledig; geen keuze |
| Echo ≤ 40 % Leeg (MP-4) | 2–3 % | ✅ |
| R-V12 (MP-3): springplank per minuut, aandeel zonder stilstand | 3,5–4,0/min; 0–25 % zonder stilstand | ❌ (bot 100 %) |
| De echo bij het gemaal (MP-6) | 80–82 % van de LP, 7–8 pompslagen | ✅ |
| *Nine Sols*-check (zwak signaal) | Niet genoemd | uitgesteld naar F4b(c) |
| Werkaannames | W1–W10, §9 | genoemd |

**Advies: herontwerp door de LGD en een tweede flow-test** (testplan §5, rij "een solo-norm niet gehaald"). Geen go: norm (3) is bij geen gemeten staart gehaald, en het verschil is groot (1,0–2,0 tegenover 4,0), niet een grensgeval. Geen `ceo-beslissing` nu: norm (2) is gehaald, de beste D ligt niet buiten 90–180, en de CEO noemde *Nine Sols* niet. Een `ceo-beslissing` (R-V12) volgt pas als de tweede flow-test norm (2) niet haalt.

Eerlijk over de grond van dit advies:

- **Het steunt op twee runs op D = 90 en één op D = 120**, één speler, en scores die bij één run 13 min later gegeven zijn. Dat is weinig. Maar alle drie wijzen dezelfde kant op, met de objectieve maat MP-3 erbij die van de scores los staat.
- **3 s is nog niet gemeten.** Dat volgt in de tweede flow-test, op het herontwerp; tot dan blijft de eis "staart 1,5 / 2 / 3 s" van de DoD van T17 open. Het advies hangt er niet van af: norm (3) is bij de gemeten staarten ver onder de grens, het wachten vóór de springplank en aan de waterkant groeit met D (deel 1: MP-1 groeit met D), en de CEO vond sneller beter.
- **De bot bewijst dat de kamer de normen kán halen; de CEO laat zien dat een mens dat niet zo speelt.** De bot loopt zo dat de echo onder hem is als hij springt; een mens wacht op de echo. Het herontwerp moet dus het wachten wegnemen, niet de maten.

## 7. Wat er nu moet gebeuren

| Wie | Wat | Waarom |
|---|---|---|
| **Lead Game Designer** (met de World & Level Designer) | **Herontwerp van de flow-kamer** vóór een tweede flow-test, op drie punten: (a) **K1**: de springplank mag niet achter de speler liggen; de speler wacht nu bij elk blok ± D ticks (MP-3 0–25 %). (b) **K3**: het gemaal vraagt wachten op de pompslagen van de echo (langste stilstand elke run, 366 ticks bij D = 90; score 1 in elke run). (c) **K2**: de merksprong en de ontploffing met bereik zijn niet leesbaar (M2); stilstanden tot 192 ticks. Hoe, kiest de LGD. Dit is ook de input voor het bijstellen van de startwaarden in [#81](https://github.com/cesarvangerwen-glitch/echoborn/issues/81) (gdd, werkaanname LGD (2)–(4)): wat het herontwerp verandert aan E-02, de bouwstenen, LM-04 en D | Testplan §5; kader §6 R-V12: "herontwerp vóór een CEO-vraag (F0)", eigenaar LGD |
| **QA Lead** | Het testplan en de kaart voor de **tweede flow-test** op het herontwerp, met per D (90 / 120 / 180) opnieuw MP-1–MP-6 en MP-5, en de D-controle in de HUD in de kaart (al toegevoegd, kaart §2). Daar komt ook de eerste meting op 3 s; tot dan blijft dat deel van de DoD van T17 open | Testplan §5; DoD T17 |
| **Gameplay Programmer / UX Designer** | Overwegen: de D ook op het scorescherm tonen (`HUD_RUN_DONE`) en de scores meteen na `RUN_EIND` vragen, zodat een verkeerde D of een late score direct opvalt (§8 punt 8) | §5.1 |

## 8. Open punten

| # | Wat ontbreekt | Waarom het ertoe doet | Wie |
|---|---|---|---|
| 1 | **Gescripte geoefende co-op-run** per D (gdd §4.5): P1 en P2 als inputbron, met bounce in beide richtingen, lancering in B4, merk-combo in K2, pompslagen van P2 | Zonder die run weten we niet of de kamer in co-op MP-2, MP-6 en MP-7 (c) **kan** halen, en kan MP-7 (a) niet echt mislukken. Sinds besluit #124 een meting voor het rapport en een voorbereiding op F4b(c), geen F0-voorwaarde. Punt 1–3 staan samen in [#125](https://github.com/cesarvangerwen-glitch/echoborn/issues/125) (World & Level Designer, met de Gameplay Programmer). De proxy `_CoopView` en de MP-7-code in `test_flowtest_t17.gd` kunnen ze gebruiken | world-level-designer, gameplay-programmer |
| 2 | **De bot lanceert niet in B4** (zelfde issue als punt 1) (comment in `flow_bot.gd`: "de lancering komt in T16c"; T16c is gemerged) | Vraag 8 vraagt lancering ≥ 1× per co-op-run in B4; nu is B4 alleen via de langzame lijn gemeten (0 landingen) | world-level-designer |
| 3 | **Het meetlog meet MP-1 alleen voor P1** (`meetlog.gd`) | MP-7 (b) vraagt P2 ook. In de scripted runs rekent de testcode het uit; voor de CSV's van de CEO-sessie ontbreekt het, dus MP-7 (b) is bij mensen alleen te observeren (zelfde issue als punt 1) | gameplay-programmer |
| 4 | ~~Een tweede speler voor co-op met de CEO~~ *Vervallen voor F0* (besluit [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124): 1B) | F0 slaagt op solo; de vraag wie P2 speelt komt bij F4b(a) (kader §9) | — |
| 5 | MP-4 in co-op en MP-7 (b)/(c) hebben in de gdd geen uitgewerkte telling; QA rekent met W4–W6 (testplan §6) | **De LGD bevestigt W4–W6** vóór de co-op-metingen in F4b(c) meetellen; voor F0 (solo) niet nodig | lead-game-designer |
| 6 | **P2 krijgt geen oefenrun** vóór de getelde co-op-runs | Geen co-op in de F0-sessie (besluit #124); meenemen in de kaart voor F4b(a)/(c) (T11) | qa-lead |
| 7 | **MP-7 (a) is in de gdd de mediane runtijd**; een sessie met mensen geeft één co-op- en één solo-run per D | Geen co-op in de F0-sessie (besluit #124); in F4b(c) rapporteert QA één waarde per D als enkele meting, niet als oordeel over MP-7 (a), tenzij er meer runs zijn | qa-lead, lead-game-designer |
| 8 | **De D van een run is alleen in de HUD tijdens de run en in de bestandsnaam te zien**; het scorescherm noemt hem niet, en de scores mogen ook veel later (§5.1: ± 13 min) | Een F-toets die niet aankomt (laptop: Fn), of een late score, valt zo pas bij QA op. Voorstel: D op het scorescherm (`HUD_RUN_DONE`) | gameplay-programmer, ux-designer |
| 9 | **Geen geldige meting op 3 s** (§5.1) | De DoD van T17 vraagt 1,5 / 2 / 3 s; 3 s volgt in de tweede flow-test en blijft tot dan open (§7) | qa-lead |
| 10 | Eerste knop op de pijltjeskant maakt speler 1 | Staat als open punt in de kaart (*Open punten*) | ux-designer, gameplay-programmer |

## 9. Werkaannames

W1–W10 uit `docs/qa/testplan-f0.md` §6 (kader §5). De belangrijkste voor dit rapport: de bot is de geoefende solo-speler (W2), de co-op-partners zijn ondergrenzen (W3), MP-4, MP-7 (b) en (c) in co-op volgen W4–W6, de CEO is geoefend vanaf zijn derde run (W7), M1 is een zwak signaal (W8), de D van een CEO-run komt uit het log en niet uit het label in het antwoordblok (W9), en MP-5 is per run het gemiddelde van K1–K3 (W10). Daarnaast de werkaanname van de LGD: D = 120 tot T17 een staart kiest (gdd, werkaanname LGD (3)).

## Wijzigingen

| Versie | Datum | Wijziging |
|---|---|---|
| 0.1 | 2026-11-09 | Eerste versie (#80): scripted runs solo en co-op, open punten |
| 0.2 | 2026-11-11 | Na besluit [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124) (1B) en fasekader v0.3: alleen de verwijzingen naar co-op/P2 als F0-voorwaarde bijgewerkt (kop, §1, §4-titel en punt 3 van "Wel", §5, §6 punt 1 en 4–7); meetwaarden ongewijzigd |
| 0.3 | 2026-11-11 | Deel 2 (CEO solo) en QA-advies F0 (#80): titel en §1 nieuw; §5 (meetlogs van de CEO, welke run welke D is, normen per run, antwoorden), §6 (advies: herontwerp + tweede flow-test), §7 (wat nu; 3 s in de tweede flow-test); open punten 8–10; werkaannames W9–W10; oude §5 vervangen, §6–§7 hernummerd naar §8–§9; meetlogs in `docs/qa/f0-meetlogs/` |
| 0.3.1 | 2026-11-11 | Na Lead-review EP: geen herhaling op 3 s; 3 s volgt in de tweede flow-test en dat deel van de DoD blijft open (§1, §6, §7, open punt 9); advies zonder voorwaarde; W10 = MP-5 per run |
