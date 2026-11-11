# Testplan F0: flow-test van de grijze flow-kamer (T17)

Versie 0.3.1 · 2026-11-11 · Eigenaar: QA Lead (met Lead Game Designer) · Issue: [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80) · Lead-review: Executive Producer

Basis: fasekader fase 2 v0.3 (`docs/productie/fase-2-kader.md` §1, §2 rij T17, §3 F0 en F4b, §4, §5, §9), pitch v0.4 §4 (pillar 1), gdd §4.5 (MP-1–MP-7) en §5 (playtestvragen), ideecheck §2 (slotzin), audio bible §9.4, besluit #51 (1A, 7A: staart ± 2 s, bereik 1,5–3 s), besluit [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124) (1B: de CEO speelt F0 alleen solo).

Rapport van deel 1: `docs/qa/rapport-f0-flowtest.md`. Kaart voor de CEO: `docs/qa/ceo-kaart-f0.md`.

## 1. Wat F0 vraagt

F0 is gehaald als de flow-kamer **solo** de drie normen van pillar 1 haalt, met een staart gekozen binnen 1,5–3 s op de solo-normen (kader §3 F0). **Co-op hoort niet bij F0** (besluit #124: 1B): de co-op-maten hieronder meet QA in F0 alleen met de scripted runs; als slaagcriterium gelden ze in de slice (kader §3, F4b(c)), met dezelfde maten en grenzen.

| Norm (pitch §4) | Maat (gdd §4.5) | Gehaald als (solo) |
|---|---|---|
| (1) geoefende speler nergens > ± 5 s stil, ook bij het gemaal | MP-1 | langste stilstand ≤ 300 ticks (301–360: LGD bekijkt de opname) |
| (2) echo als springplank of merk-afmaker ≥ ± 1× per 20 s | MP-2 | ≥ 3,0 echo-acties/min over de run en in K1 en K2 apart; geen 40 s zonder |
| (3) "vloeiend/satisfying" ≥ 4 op 5 | MP-5 | gemiddeld ≥ 4,0 solo (de CEO), geen kamer < 3,0 |

Plus de andere eisen uit de DoD van T17 (solo):

| Eis | Maat | Gehaald als |
|---|---|---|
| Staart 1,5 / 2 / 3 s | alles per D = 90 / 120 / 180 ticks | keuzeregel gdd §4.5, solo: de D die MP-1, -2, -4, -6 haalt met de hoogste MP-5; gelijk = 120 |
| Echo ≤ 40 % Leeg | MP-4 | ≤ 40 % |
| R-V12: springplank per minuut, aandeel zonder stilstand | MP-3 | rapporteren; ≥ 75 % zonder stilstand van ≥ 20 ticks |
| De echo telt mee bij het gemaal | MP-6 | ≥ 40 % van de LP met de echo; ≥ 1 pompslag van de echo |
| *Nine Sols*-check (ideecheck §2, slotzin; R-V9) | gdd §5 vraag 5, M1 van de CEO | **zwak signaal** (de CEO koos *Nine Sols* zelf als referentie): noemt hij het merk spontaan "net als *Nine Sols*" (of talisman, of lading-en-ontploffing), dan terug naar afwijkpunt 2 (gdd §2.13); noemt hij het niet, dan is de check uitgesteld naar F4b(c), niet gehaald |

**Co-op-maten: in F0 alleen meting** (kader §3 F4b(c)). De kolom "In F4b(c)" zegt of de maat daar een voorwaarde is.

| Eis | Maat | Grens | In F4b(c) |
|---|---|---|---|
| Norm (3) co-op | MP-5 | gemiddeld ≥ 4,0 co-op, geen kamer < 3,0 | voorwaarde |
| Wachten; partner als hulp of last | C1–C2 (gdd §5 vraag 7–8) | niemand wacht; partner als hulp | voorwaarde |
| Co-op ≤ 2× zo snel als solo, niemand wacht | MP-7 (a)–(d) | runtijd co-op ≥ ½ × solo; MP-1 van P1 én P2 ≤ 300; ≥ 1,0 samenwerkingsactie/min per speler; P2 ≤ 10 % opgelost | voorwaarde |
| Echo Leeg / echo bij het gemaal, in co-op | MP-4 (W4), MP-6 | ≤ 40 % zonder tweede lichaam; ≥ 40 % van de LP met P2/samen, ≥ 1 pompslag van P2 | meting |
| Sterke *Nine Sols*-check | M1 van P2 | alleen als P2 de referenties niet kent en antwoordt vóór uitleg over het merk; leest het merk als *Nine Sols*: terug naar afwijkpunt 2 vóór de gate | meting, geen gate-voorwaarde; is er zo'n P2 niet, dan blijft R-V9 open in F8 |

## 2. Spelers en wat ze bewijzen

| Speler | Wat het bewijst | Wat het **niet** bewijst |
|---|---|---|
| **Scripted runs** (headless, deel 1) | Dat de kamer solo de objectieve normen MP-1–MP-4 en MP-6 **kan** halen, per D; herhaalbaar en deterministisch. De co-op-runs geven MP-7 en de co-op-maten als **meting** (geen slaagcriterium) | MP-5 (norm 3), de *Nine Sols*-check en voorspelbaarheid: die vragen een mens |
| **De CEO** solo (± 15 min spelen + ± 5 min luisteren, deel 2) | MP-5 solo per D, de open vragen solo (gdd §5 vraag 1, 5, 6 en 8 (solo)), het zwakke *Nine Sols*-signaal, en de objectieve normen bij een mens vanaf zijn derde run | Co-op bij mensen (norm 3 co-op, C1–C2, MP-7) en de sterke *Nine Sols*-check: F4b(c) |

Een externe playtest valt buiten fase 2 zonder apart CEO-besluit (kader F4).

## 3. Scripted runs (deel 1)

Bestand: `game/tests/test_flowtest_t17.gd`, in de gewone suite (`docs/tech/setup.md` §3), dus ook in CI op Linux en Windows. De tests **meten**; een norm die niet gehaald wordt, staat als bevinding in het rapport en maakt CI niet rood. Ze toetsen alleen dat elke run eindigt, dat de meting compleet is en dat een co-op-run herhaalbaar is.

| Run | P1 | P2 | Per D | Telt voor F0 |
|---|---|---|---|---|
| Solo | geoefende bot van de WLD (`flow_bot.gd`) | — (echo aan) | 90, 120, 180 | ja |
| Co-op **schaduwpartner** | dezelfde bot; ziet P2 als "de echo" (proxy, geen spelcode gewijzigd) | doet de knoppen van P1 van D ticks eerder, zolang hij op dat spoor blijft (≤ 24 px); daarna meeloper | 90, 120, 180 (+ herhaling D = 120) | meting (F4b(c)) |
| Co-op **meeloper** | dezelfde bot | loopt 40 px achter P1, springt en slaat nooit (C-15 (2)) | 90, 120, 180 | meting (F4b(c)) |

Uitlezen: elke run geeft een regel `T17 …` in de testuitvoer met alle maten. Draaien: `godot --headless --path game --fixed-fps 60 -s res://tests/run_tests.gd` en zoek op `T17`.

**Wat de testcode zelf meet** (staat niet in het meetlog): MP-1 voor P2 (MP-7 b), tijd dat P2 opgelost is (MP-7 d), landingen per bouwsteen (gdd §5 vraag 4), merk-combo's per minuut (vraag 8).

## 4. Sessie met de CEO (deel 2, solo)

Draaiboek en scorekaart: `docs/qa/ceo-kaart-f0.md`. Opbouw (± 15 min spelen + ± 5 min luisteren):

| Blok | Wat | Tijd |
|---|---|---|
| 1 | Twee oefenruns solo, D = 120 (tellen niet mee: geoefend = vanaf de derde run, gdd §4.5) | ± 5 min |
| 2 | Solo D = 180, D = 90, D = 120 (wisselende volgorde, gdd §5); na elke run score per kamer (toetsen 1–5) en "wist je waar je echo zou zijn?" | ± 7 min |
| 3 | Open vraag over het merk, **vóór** we iets over het merk zeggen (zwak *Nine Sols*-signaal), de merksprong-vraag en "echo: hulp of last?" | ± 1–2 min |
| 4 | Luistercheck F2 (audio bible §9.4): drie ja/nee-vragen | ± 5 min |

De CEO stuurt de meetlog-CSV's mee (de kamer schrijft ze zelf, `docs/design/kamers/flowkamer.md` §7). De QA Lead rekent ze uit met `flow_report.gd`.

## 5. Oordeel en wat er dan gebeurt

| Uitkomst | Gevolg (kader §3 F0) |
|---|---|
| Solo haalt MP-1, -2, -4, -6 en MP-5 ≥ 4,0 bij minstens één D binnen 90–180, en de CEO noemt *Nine Sols* niet spontaan | QA-advies **go F0** (*Nine Sols*-check uitgesteld naar F4b(c)); daarna `Visie-review` van de CD op P1 en P3 (P3 op de solo-echo als partner), dan start T8 |
| Een solo-norm niet gehaald | Herontwerp door de LGD en een tweede flow-test; haalt die norm (2) niet: `ceo-beslissing` (R-V12) |
| De CEO noemt het merk spontaan als *Nine Sols* | Terug naar afwijkpunt 2 (gdd §2.13) |
| Beste D buiten 90–180 | `ceo-beslissing`, voorbereid door de CD (F4) |
| Een co-op-meting uit de scripted runs haalt de grens niet | Geen invloed op F0; staat als bevinding in het rapport voor de LGD en voor F4b(c) |

## 6. Werkaannames (kader §5)

| # | Aanname | Waarom |
|---|---|---|
| W1 | Godot 4.6.3-stable, headless, `--fixed-fps 60` | Vastgepind door de TD (`setup.md` §1) onder besluit "Godot 4.6" |
| W2 | De "geoefende speler" van de scripted solo-run is de bot `flow_bot.gd` | Werkaanname van de WLD (T16b); de gdd laat een scripted run toe |
| W3 | De twee co-op-partners zijn **ondergrenzen**, geen geoefend duo | De gescripte co-op-run uit gdd §4.5 was er bij deel 1 nog niet (rapport §6) |
| W4 | MP-4 in co-op = tijd **zonder tweede lichaam**: de echo Leeg vóór de drop-in plus de tijd dat P2 opgelost is | In co-op is er geen echo (gdd §2.7); P2 speelt die rol |
| W5 | MP-1 voor P2: zelfde definitie als P1; opgeloste ticks tellen niet en na `P2_TERUG` gelden 60 ticks niet (zoals na een respawn) | gdd §4.5 MP-7 (b) noemt de opgeloste ticks; de 60 ticks zijn een QA-keuze |
| W6 | MP-7 (c): een springplank, lancering of vang telt voor de drager én de springer; een merk-combo voor beide spelers | Elke samenwerkingsactie heeft twee lichamen (gdd §2.7) |
| W7 | De CEO is "geoefend" vanaf zijn derde run; de eerste twee tellen niet mee | gdd §4.5 |
| W8 | De *Nine Sols*-check bij de CEO is een zwak signaal: de CEO koos *Nine Sols* zelf als referentie (#51) | Een speler die de referentie niet kent, is een sterkere toets; die volgt in F4b(c) als er zo'n P2 is; anders blijft R-V9 open in F8 (kader §3, §4) |
| W9 | De D van een run van de CEO komt uit het meetlog (bestandsnaam, en de eerste `ECHO_LEEG_EIND` op tick D); de koppeling van zijn antwoorden aan een run gaat via de in-game scores (`SCORE`) | In de sessie van 2026-11-11 kwam een F-toets niet aan (rapport §5.1); het label in het antwoordblok is dan niet betrouwbaar |
| W10 | MP-5 wordt **per run** gerapporteerd: het gemiddelde van K1–K3 van die run; "geen kamer < 3,0" geldt per kamer van die run | gdd §4.5 MP-5 zegt "per modus"; de sessie geeft per D maar één of twee geldige runs (D = 90 twee, D = 120 één) |

W3–W6 gelden in F0 alleen voor de co-op-metingen.

## Wijzigingen

| Versie | Datum | Wijziging |
|---|---|---|
| 0.1 | 2026-11-09 | Eerste versie (#80): normen solo én co-op, scripted runs, CEO-sessie met co-op-blok, W1–W8 |
| 0.2 | 2026-11-11 | Na besluit [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124) (1B) en fasekader v0.3: slaagcriterium F0 alleen solo (§1, §5); co-op-maten apart als meting met grenzen voor F4b(c) (§1, §3); *Nine Sols*-check in F0 als zwak signaal (§1, §5, W8); CEO-sessie ± 15 min, co-op-blok vervallen en de luistercheck hernummerd naar blok 4 (§2, §4); vraag over P2 eruit (die hoort bij F4b(a), kader §9); na Lead-review EP: in de co-op-tabel alleen norm (3) co-op, C1–C2 en MP-7 als voorwaarde voor F4b(c), MP-4/MP-6 co-op en de sterke check als meting; R-V9 open in F8 zonder geschikte P2 |
| 0.3 | 2026-11-11 | W9–W10 na de CEO-sessie (§6); het oordeel staat in het rapport §6 |
| 0.3.1 | 2026-11-11 | W10: MP-5 per run (na Lead-review EP) |
