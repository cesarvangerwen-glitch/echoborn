# Testplan F0: flow-test van de grijze flow-kamer (T17)

Versie 0.1 · 2026-11-09 · Eigenaar: QA Lead (met Lead Game Designer) · Issue: [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80) · Lead-review: Executive Producer

Basis: fasekader fase 2 v0.2 (`docs/productie/fase-2-kader.md` §2 rij T17, §3 F0, §4, §5), pitch v0.4 §4 (pillar 1), gdd §4.5 (MP-1–MP-7) en §5 (playtestvragen), ideecheck §2 (slotzin), audio bible §9.4, besluit #51 (1A, 7A: staart ± 2 s, bereik 1,5–3 s).

Rapport van deel 1: `docs/qa/rapport-f0-flowtest.md`. Kaart voor de CEO: `docs/qa/ceo-kaart-f0.md`.

## 1. Wat F0 vraagt

F0 is gehaald als de flow-kamer, **solo én co-op**, de drie normen van pillar 1 haalt, met een staart gekozen binnen 1,5–3 s (kader §3):

| Norm (pitch §4) | Maat (gdd §4.5) | Gehaald als |
|---|---|---|
| (1) geoefende speler nergens > ± 5 s stil, ook bij het gemaal | MP-1 | langste stilstand ≤ 300 ticks (301–360: LGD bekijkt de opname) |
| (2) echo als springplank of merk-afmaker ≥ ± 1× per 20 s | MP-2 | ≥ 3,0 echo-acties/min over de run en in K1 en K2 apart; geen 40 s zonder |
| (3) "vloeiend/satisfying" ≥ 4 op 5 | MP-5 | gemiddeld ≥ 4,0 per modus, geen kamer < 3,0 |

Plus de andere eisen uit de DoD van T17:

| Eis | Maat | Gehaald als |
|---|---|---|
| Staart 1,5 / 2 / 3 s | alles per D = 90 / 120 / 180 ticks | keuzeregel gdd §4.5: de D die MP-1, -2, -4, -6 (co-op ook MP-7) haalt met de hoogste MP-5; gelijk = 120 |
| Echo ≤ 40 % Leeg | MP-4 | ≤ 40 % |
| R-V12: springplank per minuut, aandeel zonder stilstand | MP-3 | rapporteren; ≥ 75 % zonder stilstand van ≥ 20 ticks |
| De echo telt mee bij het gemaal | MP-6 | ≥ 40 % van de LP met de echo (co-op: P2/samen); ≥ 1 pompslag van de echo (co-op: P2) |
| Co-op ≤ 2× zo snel als solo, niemand wacht | MP-7 (a)–(d) | runtijd co-op ≥ ½ × solo; MP-1 van P1 én P2 ≤ 300; ≥ 1,0 samenwerkingsactie/min per speler; P2 ≤ 10 % opgelost |
| *Nine Sols*-check (ideecheck §2, slotzin; R-V9) | gdd §5 vraag 5 | niemand noemt het merk spontaan "net als *Nine Sols*" (of talisman, of lading-en-ontploffing) |

## 2. Spelers en wat ze bewijzen

| Speler | Wat het bewijst | Wat het **niet** bewijst |
|---|---|---|
| **Scripted runs** (headless, deel 1) | Dat de kamer de objectieve normen MP-1–MP-4, MP-6, MP-7 **kan** halen, per D; herhaalbaar en deterministisch | MP-5 (norm 3), de *Nine Sols*-check, voorspelbaarheid en wachten in co-op: die vragen een mens |
| **De CEO** (± 20 min, deel 2) | MP-5 per modus en per D, de open vragen (gdd §5 vraag 1, 5–8), en de objectieve normen bij een mens vanaf zijn derde run | Een tweede mens als P2 vraagt een besluit ([#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124)) |

Een externe playtest valt buiten fase 2 zonder apart CEO-besluit (kader F4).

## 3. Scripted runs (deel 1)

Bestand: `game/tests/test_flowtest_t17.gd`, in de gewone suite (`docs/tech/setup.md` §3), dus ook in CI op Linux en Windows. De tests **meten**; een norm die niet gehaald wordt, staat als bevinding in het rapport en maakt CI niet rood. Ze toetsen alleen dat elke run eindigt, dat de meting compleet is en dat een co-op-run herhaalbaar is.

| Run | P1 | P2 | Per D |
|---|---|---|---|
| Solo | geoefende bot van de WLD (`flow_bot.gd`) | — (echo aan) | 90, 120, 180 |
| Co-op **schaduwpartner** | dezelfde bot; ziet P2 als "de echo" (proxy, geen spelcode gewijzigd) | doet de knoppen van P1 van D ticks eerder, zolang hij op dat spoor blijft (≤ 24 px); daarna meeloper | 90, 120, 180 (+ herhaling D = 120) |
| Co-op **meeloper** | dezelfde bot | loopt 40 px achter P1, springt en slaat nooit (C-15 (2)) | 90, 120, 180 |

Uitlezen: elke run geeft een regel `T17 …` in de testuitvoer met alle maten. Draaien: `godot --headless --path game --fixed-fps 60 -s res://tests/run_tests.gd` en zoek op `T17`.

**Wat de testcode zelf meet** (staat niet in het meetlog): MP-1 voor P2 (MP-7 b), tijd dat P2 opgelost is (MP-7 d), landingen per bouwsteen (gdd §5 vraag 4), merk-combo's per minuut (vraag 8).

## 4. Sessie met de CEO (deel 2)

Draaiboek en scorekaart: `docs/qa/ceo-kaart-f0.md`. Opbouw (± 20 min spelen + ± 5 min luisteren):

| Blok | Wat | Tijd |
|---|---|---|
| 1 | Twee oefenruns solo, D = 120 (tellen niet mee: geoefend = vanaf de derde run, gdd §4.5) | ± 5 min |
| 2 | Solo D = 180, D = 90, D = 120 (wisselende volgorde, gdd §5); na elke run score per kamer (toetsen 1–5) en "wist je waar je echo zou zijn?" | ± 7 min |
| 3 | Open vraag over het merk, **vóór** we iets over het merk zeggen (*Nine Sols*-check) en de merksprong-vraag | ± 1 min |
| 4 | Co-op D = 120, D = 180, D = 90, met P2 volgens het besluit in [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124); na elke run score per kamer, wachten ja/nee, hulp of last | ± 7 min |
| 5 | Luistercheck F2 (audio bible §9.4): drie ja/nee-vragen | ± 5 min |

De CEO stuurt de meetlog-CSV's mee (de kamer schrijft ze zelf, `docs/design/kamers/flowkamer.md` §7). De QA Lead rekent ze uit met `flow_report.gd` en de MP-7-code uit `test_flowtest_t17.gd`.

## 5. Oordeel en wat er dan gebeurt

| Uitkomst | Gevolg (kader §3 F0) |
|---|---|
| Solo én co-op halen MP-1, -2, -4, -6, MP-5 ≥ 4,0 (co-op ook MP-7) bij minstens één D binnen 90–180, en niemand noemt *Nine Sols* | QA-advies **go F0**; daarna `Visie-review` van de CD op P1 en P3, dan start T8 |
| Een norm niet gehaald | Herontwerp door de LGD en een tweede flow-test; haalt die norm (2) niet: `ceo-beslissing` (R-V12) |
| Het merk leest als *Nine Sols* | Terug naar afwijkpunt 2 (gdd §2.13) |
| Beste D buiten 90–180 | `ceo-beslissing`, voorbereid door de CD (F4) |

## 6. Werkaannames (kader §5)

| # | Aanname | Waarom |
|---|---|---|
| W1 | Godot 4.6.3-stable, headless, `--fixed-fps 60` | Vastgepind door de TD (`setup.md` §1) onder besluit "Godot 4.6" |
| W2 | De "geoefende speler" van de scripted solo-run is de bot `flow_bot.gd` | Werkaanname van de WLD (T16b); de gdd laat een scripted run toe |
| W3 | De twee co-op-partners zijn **ondergrenzen**, geen geoefend duo | De gescripte co-op-run uit gdd §4.5 bestaat nog niet (rapport §6) |
| W4 | MP-4 in co-op = tijd **zonder tweede lichaam**: de echo Leeg vóór de drop-in plus de tijd dat P2 opgelost is | In co-op is er geen echo (gdd §2.7); P2 speelt die rol |
| W5 | MP-1 voor P2: zelfde definitie als P1; opgeloste ticks tellen niet en na `P2_TERUG` gelden 60 ticks niet (zoals na een respawn) | gdd §4.5 MP-7 (b) noemt de opgeloste ticks; de 60 ticks zijn een QA-keuze |
| W6 | MP-7 (c): een springplank, lancering of vang telt voor de drager én de springer; een merk-combo voor beide spelers | Elke samenwerkingsactie heeft twee lichamen (gdd §2.7) |
| W7 | De CEO is "geoefend" vanaf zijn derde run; de eerste twee tellen niet mee | gdd §4.5 |
| W8 | De *Nine Sols*-check bij de CEO is een zwak signaal: de CEO koos *Nine Sols* zelf als referentie (#51) | Een speler die de referentie niet kent, is een sterkere toets ([#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124)) |
