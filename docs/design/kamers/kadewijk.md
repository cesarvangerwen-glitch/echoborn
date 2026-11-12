# Kamers: de Kadewijk (wijk 1.3, de slice), deel 1: S1–S4

Versie 0.2 · Eigenaar: World & Level Designer · Issues [#83](https://github.com/cesarvangerwen-glitch/echoborn/issues/83) (T8a, eigenaar Gameplay Programmer met WLD) en [#217](https://github.com/cesarvangerwen-glitch/echoborn/issues/217) (S4 herontwerp, W-12) · Review: Lead Game Designer

Bronnen: `docs/design/wereld.md` v0.2 §2 (kamerlijst §2.2, SL-regels §2.3, vijandtypes §2.4, T8a §2.5, acceptatie §2.6), `docs/design/gdd.md` v0.8.2 (§4.3 bouwstenen met D in formules, L-08–L-14, §4.5 normen, §4.8.5 vaste basis), `docs/design/combat/slice-vijanden-en-boss.md` v0.1.2 (§2.6 plaatsing, VJ-01–VJ-08), `docs/productie/fase-2-kader.md` v0.4 §4, `docs/tech/ontwerp.md` v0.3 (§3a, §7, §12 "naar T8a"), de visie-review van de CD ([comment in #212](https://github.com/cesarvangerwen-glitch/echoborn/issues/212), `docs/concept/visie-review/kadewijk/`).

**Stand.** S1–S4 staan als grijze, speelbare kamers in `game/levels/kadewijk/`, op de systemen van T5b en T8b: `Kamer` + `AreaLoader` met meestreamende inhoud, `Progress` + `Checkpoint` + `Respawn`, `LightMeter`, de `SliceEnemy`s. Een gescripte bot loopt elke kamer en de hele route bij D = 60, met 120 en 180 als regressie, en haalt de normen (§6). **S4 is herontworpen na de visie-review (#217): B4 ligt nu achter een keerpunt, de bolder op de rand (§3a).** **S5–S9, het gemaal, de waterstand en de arena van S8 zijn nog niet gebouwd** (§9).

## 1. Doel

Deel 1 van T8a voor de WLD: de eerste vier kamers van de kritieke route maatvast maken op D = 60, met alles wat van D afhangt als formule (fasekader v0.4 §4, regel 2), zodat de art (T8c) later pas op maatvaste kamers komt. Placeholder: grijze blokken, geen tegels (de tegels van de AD in `docs/art/slice/tiles/` zouden een import en `.import`-bestanden vragen; dat is voor de art-pass, als de kamers maatvast verklaard zijn).

## 2. Indeling

```
 y=0    +----------+--------------------------+------------------+------------------+
        | S1       | S2 Kadegang              | S3 Vismarkt      | S4 Brugkloof     |
 y=70   |          |  [P]==galerij B1==>---------->+             |                  |
 y=160  |          |  [P]<==gang/B3-galerij   |    |             |                  |
 y=230  | =galerij=>---kade---> kom B3 |wand  |    v  markt      |  aanloop  kloof overkant
 y=260  |          |                          |  ===============  =====b     ===== |
 y=320  | <--gang B1 (start)                  |                  |    bodem    |eind
 y=360  +----------+--------------------------+------------------+------------------+
 x=     0         640                       1600               2560               3520
```

`b` = de bolder op de rand van de kloof, het keerpunt van B4 (§3a). Elke kamer is 360 px hoog (één scherm op 640 × 360) en hangt aan de vorige; de buren staan op een rij (S1–S2–S3–S4). P1 begint in S1 bij de proloogdeur. De lus terug naar S1 (S9, L-14f) en S5 komen in deel 2; tot dan is S4 rechts dicht (`EindWand`), met de streep `EindeDeel1` op x = 3440 (`RUN_EIND`).

| Kamer | Rechthoek (x, y, b, h) | Begin (LM-08) | Wat |
|---|---|---|---|
| **S1 Kade-ingang** | 0, 0, 640, 360 | (440, 305) | Gang op 320 naar de linkerwand (de gracht); **B1**: keren en bouncen naar de galerij op 230 (90 hoog, Z → 480), die overgaat in de kade naar S2. Checkpoint en proloogdeur bij het begin; bevroren echo van de bakker (beeld, geen collision, WS-09) op de kade |
| **S2 Kadegang** | 640, 0, 960, 360 | (660, 215) | Kade op 230 naar rechts, onder de brugpijler door, naar de kom van **B3** (bij D = 60 een keerpunt); bounce + dash naar de galerij op 160 (70 hoog), terug naar links: de lus om de pijler. Op de gang het **E-paar**; dan **B1** tegen de pijler (x 700) naar de bovenroute op 70, naar rechts naar S3 |
| **S3 Vismarkt** | 1600, 0, 960, 360 | (1620, 55) | Je valt van de bovenroute (70) de markt op (260, 800 px vlak). **Merk-arena** (L-13), sluit niet af; twee kramen (eenrichting, 70 hoog) als extra springplank. Uitgang rechts op dezelfde vloer |
| **S4 Brugkloof** | 2560, 0, 960, 360 | (2580, 245) | Aanloop 332 px op 260 tot de **bolder** (8 × 8 op de rand, de keerwand), **B4 achter een keerpunt** (§3a): AANVAL slaan en vasthouden op weg naar de bolder, keren, de echo komt je in houding tegemoet, erop springen = lancering over de kloof van 160 × 90. Langzame lijn: over de bolder de kloof in (trede van 45 tegen de overkant, "via de kademuur"); aan de overkant **één Kadeloper** |

## 3. Bouwstenen en maten

Alle maten staan in `kadewijk_layout.gd`; wat van D afhangt is een formule daar, en elke kamerscène bouwt zijn blokken daaruit (`kadewijk_inhoud.gd`, met de D van de sessie). Zo verschuift een andere D de geometrie zonder nieuwe scène of art (gdd §4.8.5, *maatvast*).

| Maat (gdd §4.3) | Formule | D = 60 | 90 | 120 | 180 | Waar |
|---|---|---|---|---|---|---|
| Keerzone, begin weg omhoog | `Z = D + 30` | **90** | 120 | 150 | 210 | Galerij S1 (x 20 + Z … 500), galerij B1 in S2 (x 700 + Z … 1180) |
| Weg omhoog boven de vloer | 90 (70–100) | 90 | 90 | 90 | 90 | S1: 320 → 230; S2: 160 → 70 |
| Trede op 90 van de langzame lijn | 40 bij D ≤ 60, anders `Z − 14` (**werkaanname WLD**) | **40** | 106 | 136 | 196 | Tegen elke keerwand van B1, met treden van 40 px op 30 en 60 |
| B1-aanloop (vlak vóór de wand) | ≥ `D + 24` (en gang ≥ 320) | 84 | 114 | 144 | 204 | S1: 480 px; S2: 400 px |
| B3-blok (bovenkant) | `max(D − 60, 0)` × 45 | **geen blok** | 30 | 60 | 120 | S2, tegen x 1250; de wand schuift mee |
| B3-kom / gat tot de galerij | 190 / ≥ 150 | 190 / 150 | idem | idem | idem | S2: ingang 1060, tip 1100, wand 1250 |
| B4: kloof, diepte, aanloop, vrij erboven | 160, 90, ≥ 40, ≥ 180 | 160, 90, 332 (tot de bolder), 260 | idem | idem | idem | S4: rand 2900, overkant 3060 |
| B4-bolder (keerpunt, #217) | 8 breed, ≤ 12 hoog, op de rand | 8 × 8 | idem | idem | idem | S4: x 2892–2900; P1 keert met zijn middelpunt op 2884 (`B4_TURN_X`) |
| B4: ontmoeting met de echo na het keren | `b4_meet = D − 6` px vóór het keerpunt; op de echo springen + dash als `b4_meet + 16 ≤ 80` (`b4_hop`), anders laat je je dragen | 54: **springen + dash** | 84: dragen | 114: dragen | 174: dragen | Waar je AANVAL slaat: `b4_strike_x` (springen: 40 px vóór de ontmoeting; dragen: 28 px vóór de bolder) |
| Vlak stuk in de arena (L-13 b) | ≥ `D + 24` | 800 | 800 | 800 | 800 | S3 |

**Waarom de trede op 90 met D groeit** (gdd §4.3, §4.8.5: in de slice staan Z en de treden per D in data, en de eis bij keren geldt bij elke D). Keren duurt ± `D/2 + 34` ticks (gemeten 68 / 80 / 95 / 125); de langzame lijn moet zonder dash ≥ 30 ticks trager zijn, met dash ≥ 20 (gdd v0.8.2 §4.8.7), en ≤ 2×. Met de drie treden van de flow-kamer (30, 60, 90; elk 40 breed) blijft de langzame lijn ± 104 ticks bij elke D, en bij D = 180 is hij dan sneller dan keren (flow-kamer §9). Hier loopt de trede op 90 bij een langere D door tot 14 px vóór Z: de langzame lijn is dan drie sprongen plus het stuk lopen tot de galerij, en groeit mee (§6). Bij D = 60 is hij gelijk aan de flow-kamer (W-8). De trede ligt binnen de keerzone en is eenrichting: de bounce van de echolijn gaat er van onder doorheen.

### 3a. S4: B4 achter een keerpunt (#217, visie-review CD)

**Wat de CD zag** (D = 60, v0.1): voor de lancering moest je aan de rand remmen, 32 ticks AANVAL vasthouden, een stap terug zetten en ± 0,8 s wachten tot de echo je inhaalde; de echolijn was trager dan de langzame lijn (305 tegen 283 ticks vanaf het begin van S4). De echo lag achter je.

**Het herontwerp.** Een **bolder** van 8 × 8 px op de rand van de kloof is de keerwand, zoals de grachtwand in S1. Je slaat AANVAL op de aanloop en houdt hem vast terwijl je naar de bolder loopt; je echo loopt D ticks achter je en staat in houding (C-11a: AANVAL ≥ 12 ticks vast, gezicht naar de kloof). Tegen de bolder keer je, en de echo komt je tegemoet, zoals bij B1. Bij **D = 60** spring je meteen op hem (± 54 px vóór de bolder, 62 px van de rand), je wordt gelanceerd en je dasht na de top over de kloof (de lancering geeft je dash terug, C-11b). Geen stilstand, en de echolijn is **19 ticks sneller** dan de langzame lijn (268 tegen 287). Bij **D ≥ 90** is de ontmoeting te ver van de rand voor de lancering (`D − 6` px vóór de bolder). Dan sla je pas 28 px vóór de bolder, zodat de houding van de echo pas aan de bolder begint: je springt op de echo die je tegemoetkomt, hij draagt je naar de bolder en daar gaat de lancering in (16 px van de rand, zonder dash). Ook dan geen stilstand van 20 ticks (MP-1: 4 en 6 ticks).

![S4 op D = 60, bot-doorloop: keren tegen de bolder (tick ± 2672), de echo komt tegemoet, landing en lancering (± 2704, +7 LP), dash na de top, landing aan de overkant (± 2784). Geel = P1, paars = echo, rood = Kadeloper.](img/kadewijk_s4_b4_keerpunt_d60.png)

*Contactblad: gerenderde bot-doorloop op D = 60 (S1 → S4, Godot 4.6.3 met xvfb, zoals de beelden van PR #214), elke 8 ticks.*

**Waarom een bolder en geen wand.** De lancering vliegt over de bolder (de voeten zijn daar ± 60 px hoog); lopen niet. Een sprong + dash van de bolder af haalt de overkant niet: met de dash op elk moment 0 … 40 ticks na de afzet is het verste middelpunt op vloerhoogte x 3046 bij 8 px hoog, 3048 bij 12, 3050 bij 16, en bij 20 px kom je over (de overkant begint voor het middelpunt op 3052). Daarom 8 × 8, en in de test ≤ 12 hoog. Zonder bolder is het 3042. De kloof zelf (160 × 90, ≥ 40 px vlak vóór de rand, ≥ 180 vrij) blijft zoals gdd §4.3.

**Waarom de echo je bij D = 60 niet tot de rand draagt.** Dat kan ook (de variant van D ≥ 90), maar dan sta je op de echo tot hij bij de bolder is: gemeten 279 ticks (8 minder dan de langzame lijn) en een korte stilstand van 6 ticks (MP-1). Springen en dashen is 11 ticks sneller. Op de echo springen waar hij je tegemoetkomt en dashen is de snelle lijn; wie de dash mist, valt in de kloof en neemt de langzame lijn (geen vastlopen, test).

**Geen overhang, geen B5** (gdd §4.8.3, L-09): bij D = 60 niet. **Geen schaduwgeometrie, FelLicht of Schaduwgevaar** (L-06): de echo breekt in S1–S4 nergens (test).

## 4. Encounters (`slice-vijanden-en-boss.md` §2.6)

| Kamer | Vijanden (scène) | Hoe | Afwijking |
|---|---|---|---|
| S2 | `Paar1A`, `Paar1B`: 2 Kadelopers op de gang (y 160), x 880 / 908 | **E-paar**, 28 px (`paar_e`), op het vlakke stuk na B3 | — |
| S3 | Golf 1: `Paar1A/B` (2140 / 2168) + `Los` (2360). Golf 2: `Paar1A` = **Schotdrager** (1770) + `Paar1B` Kadeloper (1798), `Los` (1990) | Golf 1 een E-paar + een losse 192 px verder; golf 2 aan de kant van de ingang, de Schotdrager in een E-paar | Golf 2 wacht ook op ≤ 5 tegelijk (hieronder) |
| S4 | `Overkant`: 1 Kadeloper op x 3260 | ≥ 80 px van de landing van de lancering (± 3090) | — |

De **paren** (VJ-05) zet het gebiedsscript bij het laden met `SliceEnemy.make_pair` en de afstand uit `slice.csv`. Een `@export` voor de paargenoot (zodat het paar in de scène staat) volgt van de Gameplay Programmer (ontwerp.md §12).

Twee regels van het level-script (`kadewijk.gd`), keuze WLD:

1. **Wekken.** Een vijand doet pas mee als P1 in zijn kamer op zijn vloer staat (voeten ± 40 px) en binnen een half scherm (320 px); daarna tot P1 de kamer verlaat. Daarvóór doet hij niets (`hold_until`), raakbaar blijft hij. Zonder die regel loopt een `SliceEnemy` overal naar P1 toe, ook vanuit een andere kamer of verdieping: het paar van S2 stond dan onder de landing van B3 of aan de keerwand van B1, en de Kadeloper van S4 aan de rand van de kloof, op de landing van de lancering. Hetzelfde als `is_awake` in K2 van de flow-kamer.
2. **Golf 2 in S3** start op de eerste tick waarop elke Kadeloper van golf 1 een merk heeft of op is (§2.6, gdd §4.7.1 c) **én** golf 2 erbij hooguit 5 vijanden tegelijk geeft (L-13 f, strikt in de slice). Met alleen de eerste voorwaarde zouden er 6 tegelijk kunnen staan (3 gemerkt + 3 nieuw). Tot de start is golf 2 niet bij de Sim aangemeld en niet in beeld. De Schotdrager blokkeert niet: de golf is op zonder hem (L-13 e).

LM-13: de Kadelopers komen terug (`slice.csv`), de Schotdrager niet; zolang er geen gemaal is, telt de wijk als "niet vol" (`wijk_gemaal` leeg, §9).

## 5. Checkpoint, respawn, streamen en water

- **Checkpoint** (`Checkpoint` in S1, bij de proloogdeur): P1 begint erop. Tot het gemaal van S6 er is, is dat de enige respawnplek (SL-03); `Respawn` met `Progress` in de gebiedsscène (ontwerp.md §12 punt 1c). Test: P1 sterft in S3 en verschijnt op S1, één `RESPAWN`.
- **Begin van elke kamer** (LM-08): `Layout.ROOM_START`, een vaste, veilige plek bij de ingang; voor het debugmenu (F8) en zonder checkpoint.
- **Streamen**: geladen zijn de kamer van P1 en zijn buren; S3 laadt pas als P1 in S2 is. Kamerwissels naar een buur resetten de echo niet (E-04a).
- **Water**: alle vier op `s = 0` (wereld.md §2.2). De waterstand, `Diepwater` en de `Sluis`-objecten zijn er nog niet (GP, §9). In S1–S4 ligt niets onder water dat een route opent; dat begint in S6/S9 (L-14 d).

## 6. Gemeten met de gescripte geoefende run (`kadewijk_bot.gd`, `test_kadewijk.gd`)

Solo, P1 alleen. Ticks bij 60 Hz. "Keren" en "langzame lijn" vanaf de keerwand tot het volgende niveau, voorbij Z.

| | **D = 60** | D = 120 | D = 180 | Norm |
|---|---|---|---|---|
| Run S1 → einde S4, met echo | **2963 ticks (49 s)** (v0.1: 2997) | 3208 | 3592 | — |
| Per kamer S1 / S2 / S3 / S4 | 525 / 1038 / 941 / **458** | 517 / 1083 / 1077 / 530 | 517 / 1141 / 1343 / 590 | — |
| Zonder echo (C-15) | 3324 (1,12×) | 3331 | 3385 | ≤ 2×, ook per kamer: ✓ (per kamer ≤ 1,16×) |
| Echolijn genomen: S1-B1, S2-B3, S2-B1, S4-B4 | alle vier | alle vier | alle vier | L-08 |
| S1-B1 keren / langzame lijn zonder dash | **68 / 104 (+36, 1,53×)** | 95 / 145 (+50, 1,53×) | 125 / 186 (+61, 1,49×) | ≥ 30 trager, ≤ 2×: ✓ |
| S2-B1 keren / langzame lijn zonder dash | **68 / 104 (+36, 1,53×)** | 95 / 134 (+39, 1,41×) | 124 / 164 (+40, 1,32×) | idem: ✓ |
| S1-B1 / S2-B1: snelste langzame lijn met dash (W-12, tabel hieronder) | **94 / 94 (+26, 1,38×)** | 118 / 118 (+23) | 151 / 148 (+24–26) | ≥ 20 trager, ≤ 2×: ✓ (ook bij 90: 103, +23) |
| S2-B3 echolijn / langzame lijn | 85 / 124 | 115 / 124 | 145 / 124 | ≤ 2× (FK-2) |
| B1: bounce / landing van de wand | 54 / 120 | 122 / 190 | 182 / 250 | rand op Z + 8 |
| B3: landing voorbij de tip van de galerij | **26 px** | 30 px (v0.1: 2) | 30 px (v0.1: 2) | ≥ 9 (§8, besluit B3) |
| **S4-B4 vanaf het begin van S4: echolijn / langzame lijn** | **268 / 287 (19 sneller)** (v0.1: 305 / 283) | 339 / 287 | 399 / 287 | D = 60: echolijn sneller (#217); ≤ 2× |
| S4-B4: stilstand vóór de lancering | **geen** (v0.1: 15) | 4 + 6 ticks (v0.1: 15 + 42) | 4 + 6 (v0.1: 15 + 102) | D = 60 geen; anders < 20 |
| S4-B4: lancering van de rand / landing voorbij de overkant | **62 px (springen + dash) / 12 px** | 16 px (dragen) / 18 px | 16 / 18 | landen vanaf − 8 px |
| MP-1 langste stilstand (kamer) | **8 (S3)** (v0.1: 15, S4) | 7 (S3) | 7 (S3) (v0.1: 102, S4) | ≤ 300 per kamer: ✓ |
| MP-1 zonder echo | 102 (S2, slaan) | 102 | 102 | ✓ |
| MP-2 echo-acties per minuut (S1 / S2 / S3 / S4) | **12,2** (6,9 / 10,4 / 15,3 / 15,7) | 12,3 | 11,0 | ≥ 3,0, ook per kamer: ✓ |
| MP-2 / L-11 langste gat zonder echo-actie | **715 ticks (11,9 s)** | 742 | 780 | ≤ 40 s: ✓ |
| MP-3 landingen zonder stilstand | **100 % van 4** | 100 % van 4 | 100 % van 4 | ≥ 75 % (getoetst bij 60; zie de noot) |
| MP-4 echo Leeg | 2 % | 4 % | 5 % | ≤ 40 %: ✓ |
| MP-6 LP met de echo | 75 % | 76 % | 74 % | ≥ 40 %: ✓ |
| LP na S1–S4 (met / zonder echo) | **88** / 48 | 90 / 48 | 84 / 48 | SL-01: ≥ 100 bij S6 (§9) |
| Vijanden tegelijk (L-13 f) | ≤ 5 ✓ | ≤ 5 ✓ | ≤ 5 ✓ | ≤ 5 |
| Treffers op P1 | 0 | 0 | 0 | — |
| Elke kamer los vanaf zijn begin (D = 60) | 526 / 1028 / 931 / 449 | — | — | haalt de volgende kamer |

De run is deterministisch: dezelfde bits als `ScriptedInput` geven hetzelfde meetlog (test).

**Noot MP-3 bij D = 120 en 180** (SM-review PR #208). MP-3 is een norm op de gekozen D (60) en wordt alleen daar getoetst; bij 120 en 180 rapporteert de test. In v0.1 was het daar 67–75 %: bij B4 stond de bot aan de rand op de echo te wachten, dus die landing kwam na 42 of 102 ticks stilstand. Met de bolder als keerpunt (§3a) is dat weg: 100 % bij elke D. Dezelfde uitleg staat als `note` in `test_kadewijk.gd`.

**B4: late bot bij D = 60** (`test_kadewijk_b4_late_bot`). Landing voorbij de overkant in px (je landt vanaf − 8), per sprong later op de echo en dash later na de top:

| Sprong op de echo | dash op de top | + 8 ticks | + 16 ticks |
|---|---|---|---|
| op tijd | **12** | 26 | 34 |
| 4 ticks later | 20 | 34 | 42 |
| 8 ticks later | 28 | 42 | 50 |
| zonder dash | de kloof in, langzame lijn (S4 klaar op tick 475 in plaats van 449) | | |

**Langzame lijn met dash** (W-12, gdd v0.8.2 §4.8.7; `test_kadewijk_langzame_lijn_met_dash_d60` … `_d180`). Echo uit; de bot neemt de langzame lijn en dasht `n` ticks na de afzet van de trede op 60 (de sprong naar de weg omhoog; bij D ≥ 90 naar de trede op 90, die tot Z − 14 loopt). Ticks van het keren tegen de wand tot voorbij Z; "mist" = terug op de vloer. Eis: de snelste is ≥ 20 ticks trager dan keren en ≤ 2×, bij elke D.

| Dash na de afzet | D = 60: S1-B1 / S2-B1 | D = 90 | D = 120 | D = 180 |
|---|---|---|---|---|
| geen dash | 104 / 104 | 145 / 134 | 145 / 134 | 186 / 164 |
| 4 | mist | mist | mist | mist |
| 8 | **94 / 94** | 135 / 124 | 135 / 124 | 176 / 154 |
| 12 | 103 / 103 | **103 / 103** | 144 / 133 | 185 / 163 |
| 16 | 110 / 110 | 110 / 110 | 151 / 140 | **151** / 170 |
| 20 | 114 / 114 | 114 / 114 | 155 / 144 | 155 / 174 |
| 24 | 118 / 118 | 118 / 118 | **118 / 118** | 159 / **148** |
| **Keren / snelste met dash** | **68 / 94: +26 (1,38×)** | 80 / 103: +23 (1,29×) | 95 / 118: +23 (1,24×) | 125 / 151: +26; 124 / 148: +24 (1,19–1,21×) |

Dat is het beeld van v0.1.1 (toen met de hand gemeten: +27 bij 60, ± +22 bij 90 en 120), nu als test en ook bij 180. Bij een langere D is de snelste dash later (12, 24 of 16 ticks): dan haal je met de dash de galerij rechtstreeks, over de trede op 90 heen.

## 7. Checklist (wereld.md §2.6, voor S1–S4)

| Punt | Stand |
|---|---|
| Lus S1–S9, zonder echo te doen ≤ 2×, geen puzzel | S1–S4: zonder echo 1,12× (per kamer ≤ 1,16×); elke bouwsteen is lopen, keren, springen (FK-1); B4: slaan en vasthouden op weg naar de bolder, keren, springen. De lus zelf: deel 2 |
| Bouwstenen op de maten van §4.3 bij D = 60; wat van D afhangt in data | ✓ (§3; test `test_kadewijk_maten_per_d`) |
| SL-01 gemeten bij D = 60, solo en co-op | Solo tot S4: 88 LP. S5/S6 en co-op: open (§9) |
| Elke waterstand opent een route | Niet in S1–S4 (`s = 0`); deel 2 |
| ≤ 3 vijandtypes, ≤ 5 tegelijk | 2 types in S1–S4 (Kadeloper, Schotdrager); max. 4 tegelijk |
| Lampglas en logbladzijde 3 op een echolijn | S5 / S9: deel 2 |
| MP-1 in elke kamer, solo en co-op | Solo ✓ bij 60, 120, 180. Co-op: open (§9) |

## 8. Afwijkingen, besluiten en visie-review

Besluiten uit de Lead-review van PR #208 ([comment](https://github.com/cesarvangerwen-glitch/echoborn/pull/208#issuecomment-6830106858)) en gdd v0.8.2 §4.8.7 (PR #215); nieuw in #217: 7 en 8.

| # | Afwijking | Besluit LGD |
|---|---|---|
| 1 | **Trede op 90 groeit met D** (`Z − 14` bij D > 60), zodat de eis bij keren bij elke D geldt (§3). De variant met dash staat in §6 | **Akkoord**: de uitwerking van v0.8.1 (Z en treden per D in data, de eis bij elke D). Met dash: gdd v0.8.2 §4.8.7, ≥ 20 ticks; nu een test bij elke D (W-12, §6: +23 … +26) |
| 2 | **Golf 2 wacht ook op ≤ 5 tegelijk** (§4, regel 2) | **Akkoord** (L-13 f strikt in de slice; het wachten is kort, een merk knalt na D + 3) |
| 3 | **Wekken** als level-regel (§4, regel 1): 320 px, op de vloer ± 40 px | **Akkoord als werkaanname WLD**; gaat later naar `SliceEnemy` (GP, §9) |
| 4 | ~~B4 is met de echo niet sneller dan de langzame lijn (305 tegen 283)~~ | Was "mag blijven"; **vervangen door 7** (visie-review CD: past niet) |
| 5 | **S3 alleen vooruit**: van de markt niet terug naar de bovenroute; terug via de lus (S9) | **Akkoord**: geen vastlopen (L-10 gaat over missen) |
| 6 | **Geen tegels** van de AD: grijze blokken | — (opdracht) |
| 7 | **B4 achter een keerpunt** (#217, §3a): een bolder van 8 × 8 op de rand als keerwand; de echo komt je in houding tegemoet. Wijkt af van de solo-werkwijze in gdd §4.3 B4 (aan de rand slaan, `T + D − 21 … T + D − 3` springen): bij **D = 60** spring je op de echo 62 px van de rand en heb je **na de lancering een dash nodig** (gdd: drager ≤ 8 px van de rand, 14 px marge zonder dash); zonder dash de kloof in en de langzame lijn. Bij D ≥ 90 draagt de echo je naar de bolder (16 px van de rand, zonder dash), maar is de echolijn trager dan de langzame lijn (309–399 tegen 287) | **Open** (Lead-review #217) |
| 8 | **Besluit B3-galerij S2** (SM-review #208, besluit WLD): **de galerij blijft zoals ze is.** De 2 px bij D ≥ 90 kwam van de bot: hij dashte 14 ticks na de bounce, het vroegste moment waarop de dash de galerij nog haalt. Het venster loopt van 14 tot ± 38 ticks (2 … 42 px); op de top dashen, zoals bij D = 60, geeft **30 px**. De bot dasht nu op de top, en de test eist ≥ 9 px bij elke D. De randen van het venster (dash 14 en 38 ticks na de bounce) draaien bij D ≥ 90 als late bot (`test_kadewijk_b3_late_bot`, rapport), zodat de krapste marge zichtbaar blijft: dash + 14 → 2 px, + 38 → 40 px, bij 90, 120 en 180 gelijk. Verder de kom in laten steken kan niet zonder het gat onder 150 px te brengen (FK-6, test) | WLD (binnen de maten); ter info |

**Visie-review per kamer** (CD, [comment in #212](https://github.com/cesarvangerwen-glitch/echoborn/issues/212#issuecomment-6831045448) op D = 60; één regel per kamer):

- **S1 Kade-ingang: Visie-review: past** (CD, #212): keren tegen de grachtwand, de echo loopt je tegemoet, bounce naar de galerij (68 tegen 104 ticks).
- **S2 Kadegang: nog geen visie-review** (niet in de doorloop van #212).
- **S3 Vismarkt: Visie-review: past** (CD, #212): de echo is je tweede slag (46 van 88 LP). Punt van de CD, geen blokkade: na golf 2 ± 5 s leeg lopen naar de uitgang (§9).
- **S4 Brugkloof: Visie-review: past niet** (CD, #212: wachten aan de rand, trager dan de langzame lijn) → **herontworpen in #217** (B4 achter een keerpunt, §3a); **opnieuw naar de CD**.

**Maatvast per kamer** (fasekader §4 regel 3: bots groen op D = 60 + `Visie-review: past` van de CD + geen open herontwerp):

| Kamer | Stand |
|---|---|
| S1 | **Maatvast** na de merge van #217 (LGD bevestigt): bots groen, `past`, en het dash-punt dat de CD noemde is besloten (gdd v0.8.2 §4.8.7) en getest (W-12) |
| S2 | **Kandidaat**: het B3-punt is besloten (8); de visie-review van de CD ontbreekt |
| S3 | **Maatvast** na de merge van #217 (LGD bevestigt): bots groen, `past`; het lege stuk na golf 2 is een punt, geen herontwerp |
| S4 | **Niet maatvast**: herontworpen (#217). Pas **maatvast na een nieuwe `Visie-review: past` van de CD** (en de Lead-review van afwijking 7); tot dan geen eindkwaliteit-art |

## 9. Open punten

**Gameplay Programmer (T8a, systemen):**
- **Waterstand per wijk** (`s` 0/1/2, LM-10, WS-03) met `Diepwater` en `Sluis`-objecten, in `Progress`/schema v2 (ontwerp.md §12 punt 2); de Kadewijk-kamers krijgen dan `wijk_gemaal` = het gemaal van S6 (`S6/Gemaal`). Nu leeg, want `validate()` vraagt een bestaande kamer.
- **`lit` volgt de waterstand** (VJ-06): verlicht bij `s = 2`, niet per vijand met de hand (ontwerp.md §12).
- **De arena van de Gemaalmeester in S8**: de kamer zelf (maten GM-01 `D + 24` per kant, GM-07 `D + 34`) bouwt de WLD als layout-data zoals hier; de boss-code (#190, deel 2b) en `BOSS_START`/`BOSS_VERSLAGEN` zijn van de GP.
- `@export` voor de paargenoot van een `SliceEnemy` en voor de baan van het Dwaallicht (`lane_from`, `lane_to`, `floor_top`), zodat paren en banen in de scène staan; nu zet `kadewijk.gd` de paren.
- Een **weksone** per vijand in `SliceEnemy` (nu de regel in `kadewijk.gd`, §4).
- `Meetlog` en de camera van de flow-kamer (`flow_meetlog.gd`, `flow_room.gd` `camera_view`) worden hier alleen gelezen; naar `scripts/` verplaatsen mag.
- Co-op-bot (duo) voor de Kadewijk, zoals `flow_duo.gd`, voor MP-7 en SL-01 co-op (ook B4 in co-op met de bolder: de drager staat dan tegen de bolder, 16 px van de rand).

**Volgende WLD-run (deel 2):**
- **S5–S9** met de lus terug naar S1 (S9, het luik, SL-04), het lampglas (S5) en de logbladzijden, S6 met de pompgang (4 schoepen, 80 px, FK-5, L-14 b) en het checkpoint, S7 (Neerslag, kanaal van 160 met 2 Dwaallichten), de layout van S8 (arena), en de bot erdoor.
- **SL-01**: na S4 staat de meter op 88 LP (met echo) en 48 zonder. S5 heeft geen gevecht en S6 2 Kadelopers (± +12–15 LP met merk): dat haalt 100 waarschijnlijk net. Zo niet, dan een golf of een bouwsteen erbij (SL-01, review LGD).
- **S3, punt van de CD**: na golf 2 ± 5 s leeg naar de uitgang, de echo als spoor achter je. Kandidaat voor S4/S5 in deel 2 (bv. een keerpunt of richel vlak na de markt), geen herontwerp van S3.
- Co-op door alle kamers (C-15 d, MP-7).

**Lead Game Designer:**
- **Afwijking 7 (B4 achter een keerpunt)**: akkoord met de bolder en met de dash na de lancering bij D = 60? En bij D ≥ 90 een echolijn die trager is dan de langzame lijn (de echo draagt je naar de rand; de prijs van een lange staart, binnen MP-1)?
- **Bevinding B4 (geldt al zonder bolder)**: gdd §4.3 zegt "bounce + dash haalt tot op de vloer ± 145 px", dus niet over de kloof. Dat klopt met de dash op de top. Wie aan de rand op zijn echo wacht, bounct en pas laat in de val dasht (de dash zet `v.y` op 0), komt wél over: middelpunt tot x 3076 (de overkant begint op 3052), met of zonder bolder. Het blijft een echolijn (een bounce op de echo), maar geen lancering. Zonder echo kom je niet over (test, ook van de bolder af: 3046).
- **Flow-kamer B4** heeft nog de oude werkwijze (stap terug, 15 ticks stilstand bij D = 60, `flowkamer.md` §9). Geen nieuwe geometrie in de flow-kamer zolang MT1 erop speelt; de bolder kan daar na MT1, als de LGD dat wil.

**Creative Director:** nieuwe visie-review van S4 (§3a; in de bot-doorloop op D = 60 is S4 tick ± 2505–2963, de lancering ± 185 ticks na het begin van S4) en een eerste van S2.

**W-13** (`flowkamer.md` §9, K2-cijfers na de hoogtegrens) wacht op G-11 van de Gameplay Programmer (#218).

## 10. Spelen en testen

```bash
godot --path game res://levels/kadewijk/kadewijk.tscn      # spelen (F1/F2/F3/F7 D, F4 echo, F6 opnieuw, F8 volgende kamer)
godot --headless --path game --fixed-fps 60 -s res://tests/run_tests.gd   # alle tests, waaronder test_kadewijk.gd
```

Bestanden: `game/levels/kadewijk/kadewijk.tscn` (gebiedsscène, kamers S1–S4), `kadewijk.gd` (systemen en level-regels), `kadewijk_layout.gd` (maten en formules), `kadewijk_inhoud.gd` (bouwt de blokken van een kamer), `s1_kade_ingang.tscn` … `s4_brugkloof.tscn` (inhoud per kamer: vijanden, checkpoint, beeld), `kadewijk_bot.gd` (gescripte run, met `b4_jump_delay`/`b4_dash_delay` voor de late bot), `game/tests/test_kadewijk.gd` (met de B4-tests en W-12) en `game/tests/slow_dash_input.gd` (W-12: de langzame lijn van een bot met een dash `n` ticks na de afzet; ook voor de flow-kamer).

## 11. Werkaannames (kader §5)

Besluiten: D = 60 als werkaanname, bereik 1–3 s, en fase 2 parallel, ook bouwen (CEO, 2026-11-12); #51 deel 2 (1A geen puzzels op de kritieke route, 7A), #18 (2D, 640 × 360). Van de LGD: de maten van gdd v0.8.1 §4.3 en §4.8.5 als startwaarden; de kamerlijst van wereld.md §2.2. Van de Combat Designer: de plaatsing van §2.6 en de waarden in `slice.csv`. Van mij (WLD): de coördinaten van §2, de trede op 90 per D (§3), de bolder van 8 × 8 en de werkwijze van B4 per D (springen + dash als `b4_meet + 16 ≤ 80`, anders dragen; §3a), wekken en de 5-grens voor golf 2 (§4), en de bot als "scripted geoefende run". gdd v0.8.2 voor de eis met dash (§4.8.7).

## 12. Wijzigingen

| Versie | Datum | Wat |
|---|---|---|
| 0.1 | 2026-11-12 | Eerste versie: S1–S4 als grijze kamers, bot en tests bij D = 60 (120/180 regressie) |
| 0.1.1 | 2026-11-12 | Lead-review #208: langzame lijn met dash gemeten bij 60/90/120 (§6), besluiten van de LGD per afwijking en maatvast-stand per kamer (§8), open punten bijgewerkt (§9) |
| 0.2 | 2026-11-12 | [#217](https://github.com/cesarvangerwen-glitch/echoborn/issues/217): **S4 herontworpen**, B4 achter een keerpunt (bolder 8 × 8 op de rand; §2, §3, §3a); bot en tests (geen stilstand vóór de lancering, bij D = 60 sneller dan de langzame lijn, late bot, zonder lancering niet over). **W-12**: de langzame lijn met dash als test bij elke D (§6). SM-punten #208: noot MP-3 bij 120/180, besluit B3-galerij (galerij blijft, bot dasht op de top: 30 px; §8 punt 8). Visie-review per kamer en maatvast-stand (§8), open punten (§9); §6 opnieuw gemeten |
