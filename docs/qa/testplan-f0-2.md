# Testplan F0-2: tweede flow-test op de herontworpen flow-kamer (T17-2)

Versie 0.1.1 · 2026-11-11 · Eigenaar: QA Lead (met Lead Game Designer) · Issue: [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80) · Lead-review: Executive Producer

Basis: gdd v0.7.3 §4.5 (MP-1–MP-7, keuzeregel), §4.7.1–§4.7.3 en **§4.7.5** (wat het herontwerp nodig heeft), §5 (playtestvragen); `docs/design/kamers/flowkamer.md` (§3 keerpunten, §9 gemeten, §12 antwoord 1 van de LGD); rapport F0 v0.3.1 (`docs/qa/rapport-f0-flowtest.md`, §5–§8, open punten 8–11); het testplan van de eerste flow-test (`docs/qa/testplan-f0.md` v0.3.1, normen §1, W1–W10); fasekader §3 F0; besluit [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124) (1B: de CEO speelt alleen solo) en #51 (staart bereik 1,5–3 s).

Kaart voor de CEO: `docs/qa/ceo-kaart-f0-2.md`. Rapport (na de sessie): `docs/qa/rapport-f0-2-flowtest.md`. Meetlogs van de sessie: `docs/qa/f0-2-meetlogs/`.

## 1. Wat F0-2 toetst

De eerste flow-test haalde norm (3) en MP-3 niet, omdat de mens op zijn echo wacht (rapport F0 §6). Het herontwerp (gdd §4.7) wil dat **wachten zo min mogelijk loont en de echo je tegemoetkomt**: keerzone in B1/B2, pompgang in K3, paren en leesbaarheid in K2. F0-2 toetst:

1. **Haalt de kamer F0 nu solo**, met dezelfde normen en keuzeregel als F0 (§3), per D = 90 / 120 / 180, met **minstens twee getelde runs per D** (rapport F0 open punt 11). Daarmee ook de **eerste geldige meting op 3 s** (open punt 9).
2. **Klopt de diagnose van het herontwerp**: de verwachtingen van de LGD (gdd §4.7.2) per kamer, en vooral **MP-3 per keerpunt** (het restgat van punt (a)).
3. **Leest de kamer**: M2 (merksprong) opnieuw, het plank-signaal (E-07d) en de doelstreep (E-02t) gezien of niet, en de *Nine Sols*-vraag zoals in F0.

Co-op blijft buiten F0 (besluit #124): de gescripte duo-run (`test_flowtest_duo.gd`) neemt QA alleen als meting op in het rapport.

## 2. Build en voorwaarden vóór de sessie

De sessie vraagt de **hele** herontworpen kamer, ook K3 (W-4). Zonder W-4 meet de sessie K3 van F0 en is punt (b) van het herontwerp niet getoetst: dan **geen sessie**.

| Wat | Waarde (in te vullen door QA vóór de sessie) |
|---|---|
| Build | `main` op commit `________`, na de merge van PR [#181](https://github.com/cesarvangerwen-glitch/echoborn/pull/181) van de World & Level Designer voor [#176](https://github.com/cesarvangerwen-glitch/echoborn/issues/176) (W-4–W-7; G-1–G-5 zitten erin via PR #178, W-1–W-3 via PR #179) |
| D-toetsen | F1 = D `___`, F2 = D `___`, F3 = D `___` (verwacht 90 / 120 / 180, zoals `DEBUG_TAIL_KEYS` in `flow_room.gd` en `flowkamer.md` §8) |
| Plek van de schoepen en de sluis in K3 (voor §4.3) | schoepen x `____ / ____ / ____ / ____`, vloer y `____`; sluisdoorgang x `____` (uit `flowkamer.md` §5 na W-7) |

Checklist van QA (alles ✅, anders meldt QA in #80 wat ontbreekt en wie aan zet is; de Producer geeft de CEO pas daarna de kaart):

- [ ] Volledige suite groen op die commit (`godot --headless --path game --fixed-fps 60 -s res://tests/run_tests.gd`), met `test_flowkamer.gd`, `test_flowkamer_na_f0.gd`, `test_flowtest_t17.gd` en `test_flowtest_duo.gd`.
- [ ] De gescripte geoefende run haalt per D MP-1, MP-2, MP-4 en MP-6 op de nieuwe K3 (W-5; `flowkamer.md` §9).
- [ ] De tabel van de wachtbot staat in `flowkamer.md` §9 (W-6): per wachtplek of de weg omhoog gehaald wordt en na hoeveel stilstand. QA gebruikt die als referentie voor het restgat (§4.2).
- [ ] De D-toetsen geven de D uit de tabel hierboven (de eerste `ECHO_LEEG_EIND` van een log ligt op tick D, rapport F0 §5.1).
- [ ] Het scorescherm noemt de D na `RUN_EIND`, en F1–F4/F6 doen niets tot er drie scores zijn (G-5).
- [ ] Het rekenscript van QA (`docs/qa/f0-2-meetlogs/rekenen.gd`, uitbreiding van het F0-script met §4.2–§4.3) geeft op de logs van de gescripte run per D 5 van 5 keerpunten "echolijn zonder stilstand" (zoals `test_flowkamer_na_f0.gd`), en op een log van de wachtbot de wachtplek die de bot koos.

## 3. Normen en keuzeregel (ongewijzigd, solo)

Zoals testplan F0 §1 en gdd §4.5; gerekend per D over de getelde runs van die D (W11–W13).

| Norm | Maat | Gehaald als (per D) |
|---|---|---|
| (1) nergens > ± 5 s stil, ook bij het gemaal | MP-1 | langste stilstand in elke getelde run ≤ 300 ticks; 301–360 grensgeval (de LGD bekijkt het log met de plek, §4.3); > 360 niet gehaald. De stilstand vóór de solo-lancering in B4 telt niet (gdd §4.7.1, W14) |
| (2) echo als springplank of merk-afmaker ≥ ± 1× per 20 s | MP-2 | in elke getelde run ≥ 3,0 echo-acties/min, ook in K1 en K2 apart; geen 40 s zonder |
| (3) "vloeiend/satisfying" ≥ 4 op 5 | MP-5 | gemiddelde over de getelde runs ≥ 4,0, en geen kamer gemiddeld < 3,0 (W11) |
| Echo ≤ 40 % Leeg | MP-4 | in elke getelde run ≤ 40 % |
| De echo telt mee bij het gemaal | MP-6 | in elke getelde run ≥ 40 % van de LP met de echo, ≥ 1 pompslag van de echo |
| R-V12: springplank vóór je | MP-3 | landingen/min rapporteren; aandeel landingen zonder stilstand ≥ 75 % over de getelde runs (W16); de landing van de solo-lancering in B4 telt niet (W14) |
| *Nine Sols* (zwak signaal) | M1 | zoals F0 (testplan F0 §1, W8) |

**Keuzeregel** (gdd §4.5): gekozen wordt de D die MP-1, MP-2, MP-4 en MP-6 haalt met de hoogste MP-5; gelijk = 120. Een D die minder dan twee getelde runs heeft, doet niet mee aan de keuze (W12).

## 4. Metingen

Alles uit de meetlogs van de CEO (`flow_report.gd` plus het rekenscript van §2), per run en per D; de oefenruns staan apart (leercurve). Het meetlog krijgt geen nieuwe events (gdd §4.7.4): alles komt uit `SPRINGPLANK`, `LANCERING`, `STIL_*`, `MERK_GEZET`, `MERKSPRONG`, `ONTPLOFFING`, `POMP`, `GEMAAL_VOL`, `SCORE` en `x, y`.

### 4.1 Per run

| Maat | Wat QA rapporteert |
|---|---|
| D | uit het log (bestandsnaam en eerste `ECHO_LEEG_EIND`), naast de D die de CEO van het scorescherm overschreef (W9) |
| MP-1 | langste stilstand, met kamer, bouwsteen en `x, y`; daarnaast de stilstand vóór de lancering in B4 apart |
| MP-2 | echo-acties/min over de run, in K1 en in K2; langste gat. **K1 naast F0** (9,8–11,4/min): kost het keren MP-2? (gdd §4.7.2) |
| MP-3 | landingen/min; aandeel zonder stilstand; **per bouwsteen** (B1, B2-0 … B2-3, B3, K2) en **per keerpunt** (§4.2) |
| MP-4, MP-6 | zoals F0 |
| MP-5 | score K1 / K2 / K3 en het gemiddelde (W10) |
| V1 | "wist je waar je echo zou zijn?" (1–5), gdd §5 vraag 1 |

### 4.2 MP-3 per keerpunt (K1: B1, B2-0, B2-1, B2-2, B2-3)

Vijf keerpunten per run, dus bij 6 getelde runs 30, 10 per D. Per keerpunt één van vier uitkomsten (W15):

| Uitkomst | Hoe herkend in het log |
|---|---|
| **A. Echolijn zonder stilstand** | een `SPRINGPLANK` op dat niveau, ≥ 60 px van de keerwand, zonder stilstand van ≥ 20 ticks in de 120 ticks ervoor (de MP-3-regel) |
| **B. Echolijn na wachten**, met de plek | idem, mét zo'n stilstand; plek = `x` van die stilstand: **onder de weg omhoog** (120–270 px van de keerwand: het restgat) of elders. Richting (**op weg naar binnen** of **na het keren**) alleen als het log dat laat zien (een eerdere stilstand of landing in de keerzone van hetzelfde niveau = na het keren); anders "richting onbekend" |
| **C. Bij de wand gewacht** | een `SPRINGPLANK` op dat niveau < 60 px van de keerwand (de bounce komt op de trede, gdd §4.3): langzame lijn na wachten |
| **D. Langzame lijn** | het volgende niveau gehaald zonder `SPRINGPLANK` op dit niveau |

**MP-3 per keerpunt = A ÷ (A + B + C + D)**, per D en over alle getelde runs. Verwachting LGD: ≥ 60 % (gdd §4.7.2). De niveaus herkent QA aan `y` (vloer van B1 en de richels van B2, `flowkamer.md` §3), de keerwand aan `x` (links x = 20, rechts x = 500).

Twee vervolgregels uit de bron:

- Kiest de speler bij een bouwsteen in meer dan de helft van de getelde runs de langzame lijn (C + D), dan zet de WLD daar de trede verder van de wand (`flowkamer.md` §12, antwoord 1 van de LGD; via [#81](https://github.com/cesarvangerwen-glitch/echoborn/issues/81)).
- Haalt MP-3 de 75 % niet en is B (onder de weg omhoog) de grootste groep, dan is dat het restgat: grond voor de CEO-vraag over hoe de echo op de speler reageert (gdd §4.7.3, *Als het niet werkt*).

### 4.3 Stilstand per kamer, met plek

| Kamer | Wat | Verwachting LGD (gdd §4.7.2) |
|---|---|---|
| K1 | langste stilstand per bouwsteen (B4 apart, W14) | ≤ 60 ticks als de speler keert |
| K2 | per merk de langste stilstand van P1 tussen `MERK_GEZET` en de `MERKSPRONG` erna (zelfde merk-id; zonder merksprong: tot het eind van het merk, D + 30); daarnaast de langste stilstand in K2 | ≤ 60 ticks |
| K3 | elke stilstand ≥ 30 ticks, met plek: **bij de schoepen** (`x` binnen 40 px van een schoep), **bij de sluis** (binnen 80 px van de sluisdoorgang) of elders | ≤ 30 ticks |

### 4.4 Na de getelde runs (vragen, kaart §4–§5)

In deze volgorde, zodat niets vooraf de antwoorden kleurt (W18):

| # | Vraag | Bron | Telt als |
|---|---|---|---|
| M1 | Waar deed het merk je aan denken? (open) | gdd §5 vraag 5 | zoals F0: *Nine Sols*, talisman of lading-en-ontploffing spontaan genoemd = terug naar afwijkpunt 2 |
| M2 | Kies één moment waarop een merk wel of niet iets deed: waarom? | gdd §5 vraag 6 | begrepen bij "de echo kwam (niet) langs" of "het merk was te ver / gedoofd" (dezelfde regel als F0; W19) |
| H | Echo: hulp of last? (1–5) | gdd §5 vraag 8 | rapporteren (F0: 3,5) |
| O1 | Hoe kwam je in K1 meestal een verdieping hoger? (open) | gdd §4.7.5 punt 5 | naast de uitkomsten van §4.2: zegt hij uit zichzelf "omdraaien / mijn echo tegemoet"? |
| O2 | Zag je iets dat liet zien waar je echo zou komen of welk merk zou knallen? Wat? (open) | gdd §4.7.5 punt 5 | noemt hij spontaan een oplichtende/tikkende plank, een streep of een cirkel? |
| S1–S2 | Pas na O2 (kaart, apart blok): "Zag je een plank oplichten of tikken als je echo naar je toe kwam?" en "Zag je vóór een knal een streep naar het merk of een cirkel om het merk?" (ja / nee / niet op gelet, en hielp het?) | E-07d, E-02t, E-14j | gezien ja/nee; hielp ja/nee |

**Keert de speler uit zichzelf?** Er kijkt niemand mee (solo, thuis). Dat antwoord komt daarom uit het log: de uitkomsten A–D per keerpunt, **ook in de twee oefenruns** (keert hij al in run 1, of leert hij het pas?), en naast O1.

## 5. Sessie met de CEO (solo)

Draaiboek: `docs/qa/ceo-kaart-f0-2.md`. ± 20–25 min, geen luistercheck (F2 is in F0 gedaan).

| Blok | Wat | Tijd |
|---|---|---|
| 0 | Nieuwe build downloaden en openen, meetlog aan | ± 3 min |
| 1 | Twee oefenruns op D = 120 (tellen niet, W7) | ± 3–4 min |
| 2 | Zes getelde runs: **D = 180, 90, 120, 90, 180, 120** (W20); na elke run drie scores in het spel en op de kaart de D van het scorescherm, de drie scores en V1 | ± 11–13 min |
| 3 | Vragen M1, M2, H, O1, O2, daarna S1–S2 | ± 3 min |
| 4 | Antwoordblok en alle CSV's van vandaag in de Claude-chat | ± 2 min |

**Data.** Bijlagen in GitHub-comments zijn voor de agents niet te downloaden. De CEO zet het antwoordblok en de CSV's daarom in de **Claude-chat** (of commit ze zelf in `docs/qa/f0-2-meetlogs/`); QA zet ze in de repo (W21).

**Een run die mislukt.** Afgebroken (F6, vast) of met een verkeerde D: de CEO speelt die D aan het eind nog één keer. QA koppelt scores alleen via het log (W9).

## 6. Oordeel en wat er dan gebeurt

| Uitkomst | QA-advies en gevolg |
|---|---|
| Een D binnen 90–180 haalt MP-1, -2, -4, -6 en MP-5 ≥ 4,0 (keuzeregel), MP-3 ≥ 75 %, en de CEO noemt *Nine Sols* niet spontaan | **Go F0** met die D (*Nine Sols*-check uitgesteld naar F4b(c)); daarna `Visie-review` van de CD op P1 en P3, dan #81 (D en de maten die ervan afhangen vastzetten, gdd §4.7.3) en T8 |
| Keuzeregel en MP-5 gehaald, maar **MP-3 < 75 %** | Geen go zonder CEO: R-V12 is een eis van T17, en "het voelt goed, maar je wacht op je echo" is een afweging over de kern. De LGD bereidt een `ceo-beslissing` voor (gdd §4.7.3: accepteren, of een regel voor hoe de echo op de speler reageert), met MP-3 per keerpunt (§4.2) erbij |
| **MP-2 niet gehaald** bij elke D | `ceo-beslissing` (R-V12), kader §3 F0 en gdd §4.5 |
| MP-2 gehaald, maar een andere solo-norm (MP-1, MP-4, MP-6 of MP-5) bij geen enkele D | Geen go. De oorzaak per kamer staat in §4.2–§4.3. Is het restgat de oorzaak (B grootste groep): de route van §4.7.3 (`ceo-beslissing`, voorbereid door de LGD). Anders: de LGD stelt een aanpassing voor; of daar een derde test bij hoort of een `ceo-beslissing` (scope, het kader regelt een tweede mislukte test alleen voor norm (2)), beslist de Executive Producer |
| De CEO noemt het merk spontaan als *Nine Sols* | Terug naar afwijkpunt 2 (gdd §2.13) |
| De beste D ligt buiten 90–180 (bv. hoogste MP-5 bij 90 en dalend met D, en de CEO zegt "nog sneller") | `ceo-beslissing`, voorbereid door de CD (F4) |
| Een D heeft < 2 getelde runs | Die D telt niet mee voor de keuze. Kan die D de keuze veranderen (de andere D's halen de normen niet, of hij is de enige die over is), dan vraagt QA een korte aanvulling van alleen die D (2 runs, ± 5 min) |
| M2 niet begrepen, of plank-signaal / doelstreep niet gezien | Geen F0-voorwaarde. Bevinding voor de LGD en de Gameplay Programmer (E-02t, E-07d, E-14j) en voor de UX Designer en Art Director in T10 |
| De verwachting van de LGD (gdd §4.7.2) per kamer niet uitgekomen, maar de normen wel gehaald | Bevinding voor [#81](https://github.com/cesarvangerwen-glitch/echoborn/issues/81) |

**V1** ("wist je waar je echo zou zijn?", grens gdd §5 vraag 1: gemiddeld ≥ 4) telt niet mee in het oordeel: de keuzeregel van gdd §4.5 en F0 noemen hem niet; QA rapporteert V1 per run en per D als bevinding.

Het rapport noemt bij elk oordeel hoeveel runs het draagt (één speler, twee runs per D) en of oefening (eerste tegenover tweede helft van de getelde runs) het beeld kan verklaren.

## 7. Werkaannames (kader §5)

W1, W2, W7, W8, W9 en W10 uit `docs/qa/testplan-f0.md` §6 blijven gelden (W3–W6 gaan over co-op). Nieuw:

| # | Aanname | Waarom |
|---|---|---|
| W11 | MP-5 per D = het gemiddelde over de getelde runs van die D van het run-gemiddelde (W10); "geen kamer < 3,0" = per kamer het gemiddelde over die runs. Per run blijft het ook in het rapport | gdd §4.5 zegt "per modus"; met twee runs per D is een gemiddelde per D nu mogelijk |
| W12 | Een **getelde run** is een solo-run vanaf de derde voltooide run, met `RUN_EIND`, drie `SCORE`-regels, echo aan en geen `DROP_IN`. Afgebroken runs (`_afgebroken`) tellen niet. Een D telt mee voor de keuze met ≥ 2 getelde runs | gdd §4.7.5 punt 1; rapport F0 open punt 11 |
| W13 | Een objectieve norm (MP-1, -2, -4, -6) is voor een D gehaald als hij in **elke** getelde run van die D gehaald is | Zelfde strengheid als F0 (één run boven de grens = niet gehaald, rapport F0 §6) |
| W14 | De **solo-lancering in B4**: de stilstand van P1 in B4 en de aanloop (K1, x ≥ 1150, op de vloer van B4) tot de `LANCERING` telt niet voor MP-1; de `SPRINGPLANK` op de tick van de `LANCERING` telt niet voor MP-3. QA rapporteert beide apart. Lanceert de CEO niet, dan valt er niets weg | gdd §4.7.1 (open punt B4 solo); `flowkamer.md` §12, antwoord 6 van de LGD |
| W15 | De uitkomst per keerpunt (§4.2) komt alleen uit events met `x, y`: het log heeft geen doorlopende positie. De richting van een wachtplek (op weg naar binnen of na het keren) is daarom niet altijd te bepalen; het rapport zegt dan "richting onbekend". De grens van 60 px voor C ligt tussen een bounce bij de wand (echo ≤ 40 px van de wand) en de vroegste keerlanding (90 px bij D = 90) | gdd §4.7.4: geen nieuwe events. Getoetst op de logs van de gescripte run en de wachtbot (§2) |
| W16 | MP-3 ≥ 75 % per D telt over alle landingen van de getelde runs van die D samen; per run staat het ook in het rapport | Per run zijn het maar ± 4–7 landingen |
| W17 | Plek in K3: "bij de schoepen" = `x` binnen 40 px van het middelpunt van een schoep; "bij de sluis" = binnen 80 px van de sluisdoorgang. De coördinaten komen uit `flowkamer.md` na W-4–W-7 (§2) | gdd §4.7.5 punt 3 noemt de plekken, geen maten |
| W18 | De kaart zegt vóór het spelen niets over keren, het plank-signaal, de doelstreep of de bereikcirkel; de gerichte vragen S1–S2 staan in een apart blok dat de CEO pas na O2 leest | gdd §4.7.5 punt 5 vraagt of hij het **uit zichzelf** doet en ziet |
| W19 | M2 heeft één antwoord: "≥ 80 % begrepen" is bij één speler ja of nee. Een uitleg via het bereik ("ze stonden allebei in de cirkel") telt niet als begrepen volgens de regel, maar staat als bevinding voor E-14j in het rapport | gdd §4.7.5 punt 4: dezelfde regel als F0 |
| W20 | Volgorde **180, 90, 120, 90, 180, 120**: elke D één keer in elke helft, nooit twee keer dezelfde D na elkaar, 3 s eerst (in F0 ontbrak die). Oefenruns op D = 120, zoals F0 | gdd §5: wisselende volgorde; oefening en verwachting zo beter te scheiden dan in F0 (rapport F0 §5.1) |
| W21 | De CEO geeft het antwoordblok en de CSV's in de Claude-chat (of commit ze); QA zet ze in `docs/qa/f0-2-meetlogs/` | Bijlagen in GitHub-comments zijn voor de agents niet te downloaden |

## 8. Open punten

| # | Wat | Wie |
|---|---|---|
| 1 | Build-commit (ook in de zip-link van de kaart), D-toetsen en de K3-coördinaten invullen (§2) zodra PR #181 van de WLD voor [#176](https://github.com/cesarvangerwen-glitch/echoborn/issues/176) gemerged is; daarna de checklist van §2 | qa-lead |
| 2 | Rekenscript `docs/qa/f0-2-meetlogs/rekenen.gd` met §4.2–§4.3, getoetst op de gescripte run en de wachtbot | qa-lead |
| 3 | Eerste knop op de pijltjeskant maakt speler 1 (rapport F0 open punt 10): de kaart werkt eromheen | ux-designer, gameplay-programmer |

## Wijzigingen

| Versie | Datum | Wijziging |
|---|---|---|
| 0.1 | 2026-11-11 | Eerste versie (#80, T17-2 deel 1): normen en keuzeregel per D, twee getelde runs per D, MP-3 per bouwsteen en per keerpunt, stilstand per kamer met plek, M2 en *Nine Sols*, observaties keren en plank-signaal/doelstreep, oordeel en gevolgen, W11–W21 |
| 0.1.1 | 2026-11-11 | Na Lead-review EP: PR #181 bij naam (§2, §8); V1 alleen bevinding, niet in het oordeel (§6) |
