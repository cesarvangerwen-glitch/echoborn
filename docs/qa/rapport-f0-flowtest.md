# Rapport F0, deel 1: scripted runs in de grijze flow-kamer (T17)

Versie 0.1 · 2026-11-09 · Eigenaar: QA Lead (met Lead Game Designer) · Issue: [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80) · Lead-review: Executive Producer

Plan: `docs/qa/testplan-f0.md`. Deel 2 (de CEO-sessie, het eindoordeel F0) volgt in #80 met `docs/qa/ceo-kaart-f0.md`.

## 1. Samenvatting

- **Solo haalt alle objectieve normen bij elke staart** (D = 90 / 120 / 180): MP-1, MP-2, MP-3, MP-4 en MP-6 met ruime marge. Norm (3) (MP-5) en de *Nine Sols*-check kunnen alleen mensen geven: die wachten op de CEO.
- **Co-op is met scripted runs nog niet te beoordelen.** Er is geen gescripte geoefende co-op-run (gdd §4.5 vraagt die van de WLD met de Gameplay Programmer). De twee partners die QA zelf schreef zijn ondergrenzen: ze halen MP-2 en MP-6 niet, wat iets zegt over die partners, niet over de kamer (§4, §6 punt 1).
- **Staartkeuze**: solo laat alle drie de D toe; de keuze valt op MP-5 van de CEO en op co-op. Zonder verschil in MP-5 wordt het D = 120 (keuzeregel gdd §4.5), wat past bij besluit #51 (± 2 s).
- **Advies nu: nog geen go of no-go voor F0.** Solo is klaar voor de CEO, co-op heeft eerst een tweede speler nodig ([#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124)) en de co-op-run van de WLD (§6).

## 2. Opzet

`game/tests/test_flowtest_t17.gd`, 10 runs in de gewone suite (171 tests groen na de merge van main met #117, Linux, Godot 4.6.3, ± 33 s; de T17-getallen zijn na die merge gelijk gebleven). Elke run eindigt met `RUN_EIND`; de schaduwpartner-run D = 120 tweemaal gedraaid gaf twee keer hetzelfde meetlog. Getallen hieronder komen uit de `T17 …`-regels van die uitvoer. 60 ticks = 1 s.

## 3. Solo

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
- **Landingen per bouwsteen** (vraag 4): B3, B1 en elke verdieping van B2 geven elk 1 landing; **B4 en K2 geven er 0**. K2 is de merk-arena (de echo werkt daar als merk-afmaker, dat is bedoeld). B4 is gemeten via de langzame lijn: de bot lanceert nog niet (§6 punt 2).
- MP-3 is 100 % omdat de bot nooit op zijn echo wacht; bij mensen is dit de maat die R-V12 echt toetst.

## 4. Co-op (ondergrenzen)

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
- **Wel**: (1) co-op zonder samenwerken is **trager** dan solo met echo (1,3–1,55×) en blijft binnen FK-2/C-15 (≤ 2× de run met echo uit): de route blijft open. (2) MP-7 (a) "niet meer dan 2× zo snel" kan pas mislukken met een duo dat écht samenwerkt; dat is precies de run die ontbreekt. (3) **Een P2 die niet meeklimt, staat 6–7,5 s stil zonder dat de leiband hem oplost** (meeloper, MP-7 b 358–448 ticks), want hij blijft in beeld onder P1. Bij een mens is dat een "ik wacht"-moment; observatie O4 op de kaart en een punt voor de LGD (C-07).

## 5. Wat alleen de CEO kan geven

| Vraag (gdd §5) | Waarom niet scripted |
|---|---|
| MP-5, norm (3): vloeiend/satisfying per kamer, solo en co-op | Een gevoelsscore |
| Vraag 1: "Wist je waar je echo zou zijn?" per D | Idem |
| Vraag 5: *Nine Sols*-check (ideecheck §2, slotzin) | Moet spontaan komen, vóór we iets zeggen |
| Vraag 6: is de merksprong leesbaar? | Uitleg van een speler |
| Vraag 7 en 8: wachten (ja/nee), echo/partner als hulp of last | Idem |
| MP-1 en MP-3 bij een mens | De bot wacht nooit; een mens wel |

## 6. Open punten

| # | Wat ontbreekt | Waarom het ertoe doet | Wie |
|---|---|---|---|
| 1 | **Gescripte geoefende co-op-run** per D (gdd §4.5): P1 en P2 als inputbron, met bounce in beide richtingen, lancering in B4, merk-combo in K2, pompslagen van P2 | Zonder die run weten we niet of de kamer in co-op MP-2, MP-6 en MP-7 (c) **kan** halen, en kan MP-7 (a) niet echt mislukken. Punt 1–3 komen samen in één issue voor de World & Level Designer (met de Gameplay Programmer): issue volgt (Producer). De proxy `_CoopView` en de MP-7-code in `test_flowtest_t17.gd` kunnen ze gebruiken | world-level-designer, gameplay-programmer |
| 2 | **De bot lanceert niet in B4** (zelfde issue als punt 1) (comment in `flow_bot.gd`: "de lancering komt in T16c"; T16c is gemerged) | Vraag 8 vraagt lancering ≥ 1× per co-op-run in B4; nu is B4 alleen via de langzame lijn gemeten (0 landingen) | world-level-designer |
| 3 | **Het meetlog meet MP-1 alleen voor P1** (`meetlog.gd`) | MP-7 (b) vraagt P2 ook. In de scripted runs rekent de testcode het uit; voor de CSV's van de CEO-sessie ontbreekt het, dus MP-7 (b) is bij mensen alleen te observeren (zelfde issue als punt 1) | gameplay-programmer |
| 4 | **Een tweede speler voor co-op** met de CEO | Zonder P2 geen co-op-score voor norm (3), en F0 vraagt solo én co-op. Vraag aan de CEO: [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124) | CEO |
| 5 | MP-4 in co-op en MP-7 (b)/(c) hebben in de gdd geen uitgewerkte telling; QA rekent met W4–W6 (testplan §6) | **De LGD bevestigt W4–W6 vóór deel 2** | lead-game-designer |

## 7. Werkaannames

W1–W8 uit `docs/qa/testplan-f0.md` §6. De belangrijkste voor dit rapport: de bot is de geoefende solo-speler (W2), de co-op-partners zijn ondergrenzen (W3), en MP-4, MP-7 (b) en (c) in co-op volgen W4–W6.
