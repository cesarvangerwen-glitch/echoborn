# Kamers: de Kadewijk (wijk 1.3, de slice), deel 1: S1–S4

Versie 0.1.1 · Eigenaar: World & Level Designer · Issue [#83](https://github.com/cesarvangerwen-glitch/echoborn/issues/83) (T8a, eigenaar Gameplay Programmer met WLD) · Review: Lead Game Designer

Bronnen: `docs/design/wereld.md` v0.2 §2 (kamerlijst §2.2, SL-regels §2.3, vijandtypes §2.4, T8a §2.5, acceptatie §2.6), `docs/design/gdd.md` v0.8.1 (§4.3 bouwstenen met D in formules, L-08–L-14, §4.5 normen, §4.8.5 vaste basis), `docs/design/combat/slice-vijanden-en-boss.md` v0.1.2 (§2.6 plaatsing, VJ-01–VJ-08), `docs/productie/fase-2-kader.md` v0.4 §4, `docs/tech/ontwerp.md` v0.3 (§3a, §7, §12 "naar T8a").

**Stand.** S1–S4 staan als grijze, speelbare kamers in `game/levels/kadewijk/`, op de systemen van T5b en T8b: `Kamer` + `AreaLoader` met meestreamende inhoud, `Progress` + `Checkpoint` + `Respawn`, `LightMeter`, de `SliceEnemy`s. Een gescripte bot loopt elke kamer en de hele route bij D = 60, met 120 en 180 als regressie, en haalt de normen (§6). **S5–S9, het gemaal, de waterstand en de arena van S8 zijn nog niet gebouwd** (§9).

## 1. Doel

Deel 1 van T8a voor de WLD: de eerste vier kamers van de kritieke route maatvast maken op D = 60, met alles wat van D afhangt als formule (fasekader v0.4 §4, regel 2), zodat de art (T8c) later pas op maatvaste kamers komt. Placeholder: grijze blokken, geen tegels (de tegels van de AD in `docs/art/slice/tiles/` zouden een import en `.import`-bestanden vragen; dat is voor de art-pass, als de kamers maatvast verklaard zijn).

## 2. Indeling

```
 y=0    +----------+--------------------------+------------------+------------------+
        | S1       | S2 Kadegang              | S3 Vismarkt      | S4 Brugkloof     |
 y=70   |          |  [P]==galerij B1==>---------->+             |                  |
 y=160  |          |  [P]<==gang/B3-galerij   |    |             |                  |
 y=230  | =galerij=>---kade---> kom B3 |wand  |    v  markt      |  aanloop kloof overkant
 y=260  |          |                          |  ===============  =====      ===== |
 y=320  | <--gang B1 (start)                  |                  |    bodem    |eind
 y=360  +----------+--------------------------+------------------+------------------+
 x=     0         640                       1600               2560               3520
```

Elke kamer is 360 px hoog (één scherm op 640 × 360) en hangt aan de vorige; de buren staan op een rij (S1–S2–S3–S4). P1 begint in S1 bij de proloogdeur. De lus terug naar S1 (S9, L-14f) en S5 komen in deel 2; tot dan is S4 rechts dicht (`EindWand`), met de streep `EindeDeel1` op x = 3440 (`RUN_EIND`).

| Kamer | Rechthoek (x, y, b, h) | Begin (LM-08) | Wat |
|---|---|---|---|
| **S1 Kade-ingang** | 0, 0, 640, 360 | (440, 305) | Gang op 320 naar de linkerwand (de gracht); **B1**: keren en bouncen naar de galerij op 230 (90 hoog, Z → 480), die overgaat in de kade naar S2. Checkpoint en proloogdeur bij het begin; bevroren echo van de bakker (beeld, geen collision, WS-09) op de kade |
| **S2 Kadegang** | 640, 0, 960, 360 | (660, 215) | Kade op 230 naar rechts, onder de brugpijler door, naar de kom van **B3** (bij D = 60 een keerpunt); bounce + dash naar de galerij op 160 (70 hoog), terug naar links: de lus om de pijler. Op de gang het **E-paar**; dan **B1** tegen de pijler (x 700) naar de bovenroute op 70, naar rechts naar S3 |
| **S3 Vismarkt** | 1600, 0, 960, 360 | (1620, 55) | Je valt van de bovenroute (70) de markt op (260, 800 px vlak). **Merk-arena** (L-13), sluit niet af; twee kramen (eenrichting, 70 hoog) als extra springplank. Uitgang rechts op dezelfde vloer |
| **S4 Brugkloof** | 2560, 0, 960, 360 | (2580, 245) | Aanloop 340 px op 260, **B4**: kloof van 160 × 90 met de langzame lijn door de kloof (trede van 45 tegen de overkant, "via de kademuur"); aan de overkant **één Kadeloper** |

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
| B4: kloof, diepte, aanloop, vrij erboven | 160, 90, ≥ 40, ≥ 180 | 160, 90, 340, 260 | idem | idem | idem | S4: rand 2900, overkant 3060 |
| Vlak stuk in de arena (L-13 b) | ≥ `D + 24` | 800 | 800 | 800 | 800 | S3 |

**Waarom de trede op 90 met D groeit** (gdd §4.3, §4.8.5: in de slice staan Z en de treden per D in data, en de eis bij keren geldt bij elke D). Keren duurt ± `D/2 + 34` ticks (gemeten 68 / 80 / 95 / 125); de langzame lijn moet ≥ 30 ticks trager en ≤ 2× zijn. Met de drie treden van de flow-kamer (30, 60, 90; elk 40 breed) blijft de langzame lijn ± 104 ticks bij elke D, en bij D = 180 is hij dan sneller dan keren (flow-kamer §9). Hier loopt de trede op 90 bij een langere D door tot 14 px vóór Z: de langzame lijn is dan drie sprongen plus het stuk lopen tot de galerij, en groeit mee (§6). Bij D = 60 is hij gelijk aan de flow-kamer (W-8). De trede ligt binnen de keerzone en is eenrichting: de bounce van de echolijn gaat er van onder doorheen.

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
| Run S1 → einde S4, met echo | **2997 ticks (50 s)** | 3230 | 3614 | — |
| Per kamer S1 / S2 / S3 / S4 | 525 / 1038 / 941 / 492 | 517 / 1083 / 1077 / 552 | 517 / 1141 / 1343 / 612 | — |
| Zonder echo (C-15) | 3320 (1,11×) | 3327 | 3381 | ≤ 2×, ook per kamer: ✓ |
| Echolijn genomen: S1-B1, S2-B3, S2-B1, S4-B4 | alle vier | alle vier | alle vier | L-08 |
| S1-B1 keren / langzame lijn | **68 / 104 (+36, 1,53×)** | 95 / 145 (+50, 1,53×) | 125 / 186 (+61, 1,49×) | ≥ 30 trager, ≤ 2×: ✓ |
| S2-B1 keren / langzame lijn | **68 / 104 (+36, 1,53×)** | 95 / 134 (+39, 1,41×) | 124 / 164 (+40, 1,32×) | idem: ✓ |
| S2-B3 echolijn / langzame lijn | 85 / 124 | 101 / 124 | 131 / 124 | ≤ 2× (FK-2) |
| B1: bounce / landing van de wand | 54 / 120 | 122 / 190 | 182 / 250 | rand op Z + 8 |
| B3: landing voorbij de tip van de galerij | **26 px** | 2 px | 2 px | zie §9 |
| MP-1 langste stilstand (kamer) | **15 (S4)** | 42 (S4) | 102 (S4, B4 wachten) | ≤ 300 per kamer: ✓ |
| MP-1 zonder echo | 102 (S2, slaan) | 102 | 102 | ✓ |
| MP-2 echo-acties per minuut (S1 / S2 / S3 / S4) | **13,2** (6,9 / 10,4 / 15,3 / 22,0) | 11,1 | 11,0 | ≥ 3,0, ook per kamer: ✓ |
| MP-2 / L-11 langste gat zonder echo-actie | **715 ticks (11,9 s)** | 742 | 829 | ≤ 40 s: ✓ |
| MP-3 landingen zonder stilstand | **100 % van 4** | 67 % van 3 | 67 % van 3 | ≥ 75 % (getoetst bij 60) |
| MP-4 echo Leeg | 2 % | 4 % | 5 % | ≤ 40 %: ✓ |
| MP-6 LP met de echo | 75 % | 74 % | 74 % | ≥ 40 %: ✓ |
| LP na S1–S4 (met / zonder echo) | **88** / 48 | 84 / 48 | 84 / 48 | SL-01: ≥ 100 bij S6 (§9) |
| Vijanden tegelijk (L-13 f) | 4 | 4 | 4 | ≤ 5: ✓ |
| Treffers op P1 | 0 | 0 | 0 | — |
| Elke kamer los vanaf zijn begin (D = 60) | 526 / 1028 / 931 / 482 | — | — | haalt de volgende kamer |

De run is deterministisch: dezelfde bits als `ScriptedInput` geven hetzelfde meetlog (test).

**Langzame lijn met dash** (Lead-review #208, klein punt 1; afwijking §8 punt 1). Gemeten in S1-B1 zonder echo: P1 klimt als de bot naar de trede op 60, loopt naar de buitenrand (x wand + 31) en springt van de wand af, met een dash `n` ticks na de afzet. In ticks vanaf het keren tegen de wand; "weg omhoog" = voorbij Z (op de galerij, of over de trede op 90 doorlopen tot Z, 2 px/tick). S2-B1 heeft dezelfde maten.

| Dash na de afzet | Landing (px van de wand, hoogte 90) | D = 60 (Z 90) | D = 90 (Z 120) | D = 120 (Z 150) |
|---|---|---|---|---|
| geen | 106 op 105 | **105** (galerij) | 112 (trede, +7 lopen) | 127 (trede, +22 lopen) |
| 4 | mist (valt terug op de vloer) | — | — | — |
| 8 | 106 op 95 | **95** (galerij) | **± 102** (trede, +7 lopen) | ± 117 (trede, +22 lopen) |
| 12 | 124 op 104 | 104 | **104** (galerij) | ± 117 (trede, +13 lopen) |
| 16 | 138 op 111 | 111 | 111 | ± 117 (trede, +6) |
| 20 | 146 op 115 | 115 | 115 | ± 117 (rand van de trede, +2) |
| 24 | 154 op 119 | 119 | 119 | 119 (galerij) |
| **Snelste met dash / keren** | | **95 / 68: +27 (1,40×)** | **± 102 / 80: ± +22 (1,28×)** | **± 117 / 95: ± +22 (1,23×)** |

**Uitkomst:** met een dash ± 8 ticks na de afzet is de langzame lijn bij elke gemeten D **minder dan 30 ticks** trager dan keren (+27 bij 60, ± +22 bij 90 en 120). Dat geldt dus ook bij D = 60, met de maten van de flow-kamer (W-8); de flow-kamer en de tests hier meten de langzame lijn zonder dash (104–105 bij D = 60). ≤ 2× haalt de dash-variant wel. De dash geeft geen hoogte, maar wel snelheid op de korte sprong naar de weg omhoog. Open punt voor de LGD (§9): of de eis "≥ 30 ticks trager" voor de snelste langzame lijn *met* dash geldt; zo ja, dan moet de trede op 60 verder van de weg omhoog (of de trede op 90 korter), in de flow-kamer en hier.

## 7. Checklist (wereld.md §2.6, voor S1–S4)

| Punt | Stand |
|---|---|
| Lus S1–S9, zonder echo te doen ≤ 2×, geen puzzel | S1–S4: zonder echo 1,11× (per kamer ≤ 1,16×); elke bouwsteen is lopen, keren, springen (FK-1). De lus zelf: deel 2 |
| Bouwstenen op de maten van §4.3 bij D = 60; wat van D afhangt in data | ✓ (§3; test `test_kadewijk_maten_per_d`) |
| SL-01 gemeten bij D = 60, solo en co-op | Solo tot S4: 88 LP. S5/S6 en co-op: open (§9) |
| Elke waterstand opent een route | Niet in S1–S4 (`s = 0`); deel 2 |
| ≤ 3 vijandtypes, ≤ 5 tegelijk | 2 types in S1–S4 (Kadeloper, Schotdrager); max. 4 tegelijk |
| Lampglas en logbladzijde 3 op een echolijn | S5 / S9: deel 2 |
| MP-1 in elke kamer, solo en co-op | Solo ✓ bij 60, 120, 180. Co-op: open (§9) |

## 8. Afwijkingen en besluiten van de LGD

Besluiten uit de Lead-review van PR #208 ([comment](https://github.com/cesarvangerwen-glitch/echoborn/pull/208#issuecomment-6830106858)).

| # | Afwijking | Besluit LGD |
|---|---|---|
| 1 | **Trede op 90 groeit met D** (`Z − 14` bij D > 60), zodat de eis bij keren bij elke D geldt (§3). De variant met dash staat in §6 | **Akkoord**: de uitwerking van v0.8.1 (Z en treden per D in data, de eis bij elke D). De dash-meting (§6) is nieuw na de review: open punt §9 |
| 2 | **Golf 2 wacht ook op ≤ 5 tegelijk** (§4, regel 2) | **Akkoord** (L-13 f strikt in de slice; het wachten is kort, een merk knalt na D + 3) |
| 3 | **Wekken** als level-regel (§4, regel 1): 320 px, op de vloer ± 40 px | **Akkoord als werkaanname WLD**; gaat later naar `SliceEnemy` (GP, §9) |
| 4 | **B4 is met de echo niet sneller dan de langzame lijn** (S4: 305 tegen 283 ticks tot de overkant), zoals in de flow-kamer | **Mag blijven**: FK-2 is alleen een bovengrens; de lancering loont in licht en is optioneel op de route (7A); MT2 meet de keuze |
| 5 | **S3 alleen vooruit**: van de markt niet terug naar de bovenroute; terug via de lus (S9) | **Akkoord**: geen vastlopen (L-10 gaat over missen) |
| 6 | **Geen tegels** van de AD: grijze blokken | — (opdracht) |

Verder van de LGD: de echo is genoeg nodig (FK-2 vraagt geen tijdwinst; licht 88 tegen 48 LP, MP-2 13,2/min, keren 36 ticks sneller); geen eis voor tijdwinst over de run. **SL-01:** wat tot 100 LP ontbreekt, komt in S5/S6, niet in S1–S4.

**Maatvast per kamer** (fasekader §4 regel 3: bots groen op D = 60 + `Visie-review: past` van de CD + geen open herontwerp). Nog geen kamer is maatvast: de visie-review van de CD ontbreekt.

| Kamer | Stand |
|---|---|
| S1 | **Kandidaat**: maatvast zodra de CD `past` geeft |
| S2 | **Niet maatvast**: de B3-landing heeft bij D ≥ 90 2 px marge; de galerij verder laten uitsteken is een open herontwerp (§9). Eerst beslissen (of bij D = 60 de marge geven en de galerij laten), dan kandidaat |
| S3 | **Kandidaat** (na de CD) |
| S4 | **Kandidaat** (na de CD) |

## 9. Open punten

**Gameplay Programmer (T8a, systemen):**
- **Waterstand per wijk** (`s` 0/1/2, LM-10, WS-03) met `Diepwater` en `Sluis`-objecten, in `Progress`/schema v2 (ontwerp.md §12 punt 2); de Kadewijk-kamers krijgen dan `wijk_gemaal` = het gemaal van S6 (`S6/Gemaal`). Nu leeg, want `validate()` vraagt een bestaande kamer.
- **`lit` volgt de waterstand** (VJ-06): verlicht bij `s = 2`, niet per vijand met de hand (ontwerp.md §12).
- **De arena van de Gemaalmeester in S8**: de kamer zelf (maten GM-01 `D + 24` per kant, GM-07 `D + 34`) bouwt de WLD als layout-data zoals hier; de boss-code (#190, deel 2b) en `BOSS_START`/`BOSS_VERSLAGEN` zijn van de GP.
- `@export` voor de paargenoot van een `SliceEnemy` en voor de baan van het Dwaallicht (`lane_from`, `lane_to`, `floor_top`), zodat paren en banen in de scène staan; nu zet `kadewijk.gd` de paren.
- Een **weksone** per vijand in `SliceEnemy` (nu de regel in `kadewijk.gd`, §4).
- `Meetlog` en de camera van de flow-kamer (`flow_meetlog.gd`, `flow_room.gd` `camera_view`) worden hier alleen gelezen; naar `scripts/` verplaatsen mag.
- Co-op-bot (duo) voor de Kadewijk, zoals `flow_duo.gd`, voor MP-7 en SL-01 co-op.

**Volgende WLD-run (deel 2):**
- **S5–S9** met de lus terug naar S1 (S9, het luik, SL-04), het lampglas (S5) en de logbladzijden, S6 met de pompgang (4 schoepen, 80 px, FK-5, L-14 b) en het checkpoint, S7 (Neerslag, kanaal van 160 met 2 Dwaallichten), de layout van S8 (arena), en de bot erdoor.
- **SL-01**: na S4 staat de meter op 88 LP (met echo) en 48 zonder. S5 heeft geen gevecht en S6 2 Kadelopers (± +12–15 LP met merk): dat haalt 100 waarschijnlijk net. Zo niet, dan een golf of een bouwsteen erbij (SL-01, review LGD).
- **B3-landing bij D ≥ 90** (houdt S2 uit maatvast, §8): 2 px voorbij de tip van de galerij (bij 60: 26). Beslissen: de galerij 10–20 px verder de kom in laten steken (als dat de langzame lijn niet raakt), of bij D = 60 de marge geven en de galerij laten.
- Co-op door alle kamers (C-15 d, MP-7).

**Lead Game Designer:** of de eis "keren ≥ 30 ticks sneller" ook geldt voor de langzame lijn met dash (§6: +27 bij D = 60, ± +22 bij 90 en 120; ook de flow-kamer).

**Creative Director:** visie-review van S1, S3 en S4 (maatvast, §8).

## 10. Spelen en testen

```bash
godot --path game res://levels/kadewijk/kadewijk.tscn      # spelen (F1/F2/F3/F7 D, F4 echo, F6 opnieuw, F8 volgende kamer)
godot --headless --path game --fixed-fps 60 -s res://tests/run_tests.gd   # alle tests, waaronder test_kadewijk.gd
```

Bestanden: `game/levels/kadewijk/kadewijk.tscn` (gebiedsscène, kamers S1–S4), `kadewijk.gd` (systemen en level-regels), `kadewijk_layout.gd` (maten en formules), `kadewijk_inhoud.gd` (bouwt de blokken van een kamer), `s1_kade_ingang.tscn` … `s4_brugkloof.tscn` (inhoud per kamer: vijanden, checkpoint, beeld), `kadewijk_bot.gd` (gescripte run), `game/tests/test_kadewijk.gd`.

## 11. Werkaannames (kader §5)

Besluiten: D = 60 als werkaanname, bereik 1–3 s, en fase 2 parallel, ook bouwen (CEO, 2026-11-12); #51 deel 2 (1A geen puzzels op de kritieke route, 7A), #18 (2D, 640 × 360). Van de LGD: de maten van gdd v0.8.1 §4.3 en §4.8.5 als startwaarden; de kamerlijst van wereld.md §2.2. Van de Combat Designer: de plaatsing van §2.6 en de waarden in `slice.csv`. Van mij (WLD): de coördinaten van §2, de trede op 90 per D (§3), wekken en de 5-grens voor golf 2 (§4), en de bot als "scripted geoefende run".

## 12. Wijzigingen

| Versie | Datum | Wat |
|---|---|---|
| 0.1 | 2026-11-12 | Eerste versie: S1–S4 als grijze kamers, bot en tests bij D = 60 (120/180 regressie) |
| 0.1.1 | 2026-11-12 | Lead-review #208: langzame lijn met dash gemeten bij 60/90/120 (§6), besluiten van de LGD per afwijking en maatvast-stand per kamer (§8), open punten bijgewerkt (§9) |
