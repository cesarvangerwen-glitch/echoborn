# Testplan T11: de slice per kamer en de boss, solo en co-op (F4, F4b)

Versie 0.1 · 2026-11-13 · Eigenaar: QA Lead · Issue: [#88](https://github.com/cesarvangerwen-glitch/echoborn/issues/88) (T11) · Lead-review: Executive Producer

Basis: fasekader fase 2 (`docs/productie/fase-2-kader.md`: §2 rij T11, §3 F4 en F4b, §4 mijlpaaltests en regel tegen weggooiwerk, §5 kwaliteitslat); pitch v0.4 (§4 pillar 1, §10 R-V1, R-V2, R-V5, R-V9, R-V12); `docs/beslissingen.md` (#51: 1A, 7A, 8A; #124: 1B; 2026-11-12: D = 60 als werkaanname, fase 2 parallel, de CEO test alleen bij mijlpalen); gdd §4.5 (MP-1–MP-7) en §5.1 (grens F4b(b)); `docs/design/kamers/kadewijk.md` v0.4.8 (§6–§6d, §9); `docs/design/gemaalmeester.md` §7–§8; `game/tests/test_boss_runs.gd`; besluit LGD over B-1 ([comment in #83](https://github.com/cesarvangerwen-glitch/echoborn/issues/83#issuecomment-6845655429)).

## 0. Wat dit plan is

T11 is het overkoepelende testplan van de slice (de Kadewijk S1–S9 en de Gemaalmeester in S8). Het zegt **per kamer en voor de boss, solo en co-op**: welke F4-metingen, welke F4b(b)-gedragsmaat, welke test of meetlog dat nu al dekt, en wat nog ontbreekt, met de rol die het bouwt.

Het herhaalt de mijlpaaltests niet. Die hebben elk een eigen plan en kaart:

| Mijlpaal | Plan | Kaart voor de CEO | Toetst in T11 |
|---|---|---|---|
| MT2 (placeholder, met boss, **solo**) | `docs/qa/testplan-mt2.md` | `docs/qa/ceo-kaart-mt2.md` | F4 bij een mens solo, F4b(a) solo, F4b(b) solo (eerste meting) |
| MT3 (eindkwaliteit, **solo én co-op** met P2) | `docs/qa/testplan-mt3.md` (*nog te maken*, §6 Q-4) | `docs/qa/ceo-kaart-mt3.md` (*nog te maken*) | F4b(a) solo en co-op, F4b(b) co-op, F4b(c), sterke *Nine Sols*-check |

Het rapport aan het eind (F4 en F4b, voor F8) wordt `docs/qa/rapport-t11-slice.md`, met de bots, MT2 en MT3 samen.

**Geen meting in deze versie.** In deze run is geen Godot beschikbaar en CI draait geen jobs. Er is niets opnieuw gedraaid. De bot-cijfers hieronder komen uit de bronnen die erbij staan (gemeten op Godot 4.6.3 headless); `docs/qa/mt2-meetlogs/` bevat alleen de scripts, de CSV's van de bots staan niet in de repo (`testplan-mt2.md` §2.4). Alles wat **te meten** is, staat zo gemarkeerd.

## 1. DoD van T11 en waar het staat

| DoD (kader §2 rij T11, issue #88) | Waar in dit plan | Bewijs bij afronden |
|---|---|---|
| Elke slice-kamer en de boss, **solo én co-op met de bots** | §3 (solo), §4 (co-op) | bot-runs per kamer en de lus, solo en co-op, groen op D = 60 |
| **F4-metingen** | §2.1, per kamer in §3–§4 | `rapport-t11-slice.md` |
| **Gedragsmaat F4b(b)** | §2.2, per kamer in §3–§4 | route-tijd-maten solo (MT2) en co-op (MT3), per kamer |
| **CEO-kaart F4b(a) verwerkt** | §5: MT2-kaart klaar, MT3-kaart te maken | antwoorden van de CEO in de rapporten MT2 en MT3 |
| Co-op-normen uit F0 (F4b(c)) en sterke *Nine Sols*-check | §4, §5 | MT3 |
| Noemt de werkaanname (kader §5) | §7 | — |

## 2. De maten

### 2.1 F4-metingen

Definities: gdd §4.5. Op **D = 60**; D = 90, 120 en 180 alleen als regressie in de bots.

| # | F4-vraag (kader §3) | Maat | Grens | Per |
|---|---|---|---|---|
| F4-1 | Houdt de staart van 1 s (R9, R-V1)? | normen (1)–(2) halen op D = 60; bij de CEO: "je schaduw was…" (MT2 vraag 4) | MP-1 en MP-2 zoals F4-4; R-V1 als signaal | kamer, boss |
| F4-2 | Echo ≤ 40 % Leeg (R12) | MP-4 | ≤ 40 % | kamer, doorloop |
| F4-3 | Co-op ≤ 2× zo snel als solo, niemand wacht (R10, R-V5) | MP-7 (a)–(d) | (a) co-op ≥ ½ × solo; (b) MP-1 van P1 én P2 ≤ 300; (c) ≥ 1,0 samenwerkingsactie/min per speler; (d) P2 ≤ 10 % opgelost | kamer, boss, doorloop |
| F4-4 | Normen (1)–(3) van P1 in de slice | MP-1, MP-2, MP-5 (plus MP-3, MP-6 als rapport) | MP-1 ≤ 300 per kamer; MP-2 ≥ 3,0/min per kamer en geen gat > 40 s; MP-5 ≥ 4,0, geen deel < 3,0 | kamer (MP-5 in vier delen, W32) |
| F4-5 | Ligt de beste duur buiten 1–3 s? | — | alleen als F4-1 faalt: `ceo-beslissing`, voorbereid door de CD (kader F4) | — |

**Gaten en rustpunten** (besluit LGD over B-1, #83): voor de gaten en het rustpunt telt een `POMP` van de echo als echo-moment; **MP-2 blijft zoals in gdd §4.5** (zonder `POMP`).

### 2.2 F4b(b): de echo buiten de boss

gdd §5.1, **in beide modi**: route-tijd = `RUN_START` tot `RUN_EIND` zonder `BOSS_START` … `BOSS_VERSLAGEN`. Positief als (1) ≥ 2,0 echo-acties/min, (2) springplank-landingen ≥ 1,0/min **én** ontploffingen door het tweede lichaam ≥ 0,5/min, (3) ≥ 30 % van de LP op de route met het tweede lichaam. In co-op is het tweede lichaam P2 en telt elke samenwerkingsactie van P1 en P2 (gdd §4.5 MP-2, MP-6). QA rapporteert ook **per kamer**, zodat een herontwerp weet waar de echo stilviel. In S8 telt alleen de route vóór `BOSS_START` en na `BOSS_VERSLAGEN` (W38).

## 3. Solo, per kamer en de boss

Bot = de gescripte geoefende run, D = 60. "Lus" = `test_kadewijk_lus.gd` met `docs/qa/mt2-meetlogs/botlogs.gd` (S1 → S8 → S9 → S1, `testplan-mt2.md` §2.2 en §2.4). "Los" = de kamer vanaf haar begin (`test_kadewijk.gd`, `_deel2.gd`, `_s9.gd`; `kadewijk.md` §6–§6c). MT2 = de doorloop van de CEO; alles in die kolom is **te meten** na de sessie.

| Kamer | Wat de kamer toetst | F4 bij de bot (gedekt) | F4b(b) bij de bot | Mens (MT2, te meten) | Ontbreekt (wie) |
|---|---|---|---|---|---|
| **S1** Kade-ingang | B1 keren (S1-B1), start, snelluik terug | MP-1 ≤ 8 (deel 1); MP-2 6,3/min (lus); keren 68 / langzame lijn 104 en met dash 94 | alleen over de route (lus) | MP-1, MP-2, A–D S1-B1 en S9-B1 (eind) | MP-4 en F4b(b) **per kamer** in `rekenen.gd` (QA, Q-1) |
| **S2** Kadegang | B3-galerij, B1 terug (S2-B3, S2-B1) | MP-2 10,4/min; langste gat 715 ticks (S2 → S3, deel 1); C-15 per kamer ≤ 1,16× | idem | MP-1, MP-2, A–D S2-B3 en S2-B1 | idem (Q-1) |
| **S3** Vismarkt | merk-arena, twee golven | MP-1 8 (de langste van deel 1); MP-2 15,3/min; RV-4 lege loop 539 ticks (9,0 s) | idem | MP-1, MP-2, RV-4 (vraag 9), RV-5 (vraag 13, alleen met kleur) | idem (Q-1) |
| **S4** Brugkloof | B4 lancering van de bolder | MP-2 14,4/min; geen stilstand vóór de lancering; late-bot-tabel B4 (`kadewijk.md` §6) | idem | A–D S4-B4, RV-1 (vraag 6) | hangtijd bij een mens: event `AFZET` (O-1, Gameplay Programmer; optioneel) |
| **S5** Sluiswachtershuis | B2a–d, vier keer keren, lampglas | MP-1 0; MP-2 9,9/min; B2 keren 68 / 104 / 94; zonder echo 1,14× | idem | A–D B2a–d, RV-3 (vraag 7), kamertijd tegen 1304 | idem (Q-1) |
| **S6** Gemaalplein | SL-01, het gemaal oppompen, trap 2 na de boss | MP-1 5; **MP-2 3,5/min, de krapste kamer** (B-3); SL-01 112 LP; gemaal vol op de eerste doorgang; zonder echo 1,45× (gelijk licht) | idem | MP-2 S6 (krap), pompslagen van de echo, RV-6 (vraag 9b) | — |
| **S7** Sluiskelder | luik, stuitlijn boven het kanaal, sokkel (Neerslag) | MP-2 16,7/min; 3 stuits, 2 ontploffingen (los 430 ticks); langzame lijn 1,04× | idem | RV-2 (stuiten, vraag 8), `BREEK` (verwacht 0) | — |
| **S8** Machinehal, route | gemaal → arena-deur, arena in en uit | gemaal → deur 555 ticks (≤ 10 s, SL-03) | route vóór `BOSS_START` en na `BOSS_VERSLAGEN` | tijd gemaal → deur | — |
| **Boss** Gemaalmeester | verplichte echo-acties: schot, rad, finisher | lus 97,6 s; arena-test 97,9 s (fase 1 28,4 / fase 2 63,5 s), realistische speler 109,3 s, beginner 121,2 s; MP-1 56; MP-2 27,2/min (S8); MP-3 76 % (B-2: de 7 met stilstand alle in fase 1) | telt niet (gdd §5.1) | GM-a (vraag 10, `BOSS_START` → `SCHOT_BREUK` ≤ 60 s), GM-c (vraag 11), doden per fase | — |
| **S9** Lage kade | lus terug, rustpunt, B2a/b pijler, B1 grachtwand | MP-2 5,2/min (lus); rustpunt 932 ticks in de lus, gaten daarna ≤ 597; **na trap 2: laatste pompslag van de echo → eerste echo-actie in S9 1202 ticks (20,0 s)** (B-1); zonder echo 1,07× | idem | RV-6: dezelfde meting op de CSV van de CEO; A–D S9-B2a/b, S9-B1 | RV-6 zonder pompslag van de echo (Q-2) |
| **Doorloop** | de hele lus | MP-1 56 / MP-3 76 % / MP-4 0,4 % / MP-6 71 %; langste gat 2101 ticks (35,0 s); 0 echo-breuken bij 60/120/180; F4b(b) 8,2/min · 4,1 en 4,9/min · 78 % | ✅ op de bot (route-tijd 160,8 s) | alles van §2.1 en §2.2 solo | lus **zonder echo** (C-15 over de hele slice; Gameplay Programmer, `kadewijk.md` §9) |

Bronnen per cel: `kadewijk.md` §6, §6b, §6c, §6d en de boss-tabel; `testplan-mt2.md` §2.2 en §2.4. Grenzen en wat QA met een uitkomst doet: `testplan-mt2.md` §3, §4 en §6.

## 4. Co-op, per kamer en de boss

Co-op = P1 en P2, met P2 in de rol van de echo (7A, C-01–C-05); drop-in/drop-out hoort bij F3. Voor F4 tellen eerst **de bots** (kader F4); de co-op-normen bij mensen (F4b(c)) meet MT3 op de kamers die de kaart speelt, **de rest meten de bots** (kader F4b(c)).

| Kamer | Co-op bij de bot nu | Ontbreekt | Wie |
|---|---|---|---|
| S1–S7, S9 | **niets**: alle Kadewijk-bots spelen solo. Wel: `Pickup` pakt op door P2 (test in `test_kadewijk_lus.gd`), de co-op-bestandsnaam van het meetlog (`test_kadewijk_meetlog.gd`), het luik zonder schaduwklep in co-op (`test_kadewijk_art.gd`) | een **co-op-bot (duo) voor de Kadewijk**, zoals `flow_duo.gd`: per kamer MP-1 van P1 én P2, MP-2 met samenwerkingsacties, MP-4, MP-7 (a)–(d), SL-01 co-op, B4 in co-op met de bolder, S9 (snelluik en trap in co-op), C-15 d | Gameplay Programmer (`kadewijk.md` §9 T8a), test-runs door QA |
| S8 route en arena | — | de lus in co-op tot en met de arena-deur | Gameplay Programmer |
| **Boss** | `test_boss_runs.gd` in een **testarena** (600 px, niet de Kadewijk-arena): co-op bij D = 60 85 s (grens 75–150 s), MP-7 (a) 0,87–0,95 bij 60/90/120; drop-out van P2 in fase 1; C-16 met P2 die nooit slaat | de boss in co-op **in de Kadewijk-arena** (binnenkomst, vaste arena-camera met twee spelers, deur links na `BOSS_VERSLAGEN`); MP-7 (b)–(d) in de boss | Gameplay Programmer (met Combat Designer), `kadewijk.md` §9 deel 2 |
| Drop-in/drop-out | generiek in `test_coop.gd`, `test_coop_deel2.gd`; boss: drop-out fase 1 | drop-in en drop-out midden in de Kadewijk: per kamer één keer, plus de open vraag "drop-in terwijl de schaduwklep ligt" (`kadewijk.md` §9, TD) | Gameplay Programmer; QA toetst in de duo-runs |
| Doorloop | — | de lus S1 → S8 → S9 → S1 in co-op bij D = 60 (90/120/180 regressie), met F4b(b) co-op op route-tijd | Gameplay Programmer (bot), QA (`rekenen.gd` co-op, Q-3) |

**Te meten in MT3 (CEO + P2)**, volgens kader F4b(c) en `testplan-f0.md` §1: norm (3) co-op (MP-5 ≥ 4,0, geen deel < 3,0), C1–C2 (wachten; partner als hulp of last), MP-7 (a)–(d), F4b(a) co-op, F4b(b) co-op, en M1 van P2 als **sterke** *Nine Sols*-check (alleen als P2 de referenties niet kent en antwoordt vóór uitleg over het merk).

**Voorwaarde voor MT3** (kader §4, "geen CEO-test zonder groene bots"): de co-op-duo-runs halen MP-1 (P1 en P2) en MP-7 op D = 60 in elke kamer en de boss.

## 5. De kaarten (F4b(a))

- **MT2**: kaart en plan staan (verwijzing in §0). F4b(a) solo zit in vraag 1–3, MP-5 in vraag 5, de meetvragen RV-1–RV-6 in 6–9b en 13. Het besluit van de LGD over B-1 zit erin als vraag 9b ("Na het pompen van trap 2, de trap af en over de kade: voelde dat als beloning of als leeg lopen?") en als meting RV-6 (`testplan-mt2.md` §1.1, §4.3; bot 1202 ticks, 20,0 s). MT2 start na MT1 (`testplan-mt2.md` §0).
- **MT3**: nog te maken (Q-4), pas als T8c en T8d de slice op eindkwaliteit hebben en de co-op-bots groen zijn. Inhoud: dezelfde F4b(a)-vragen solo én co-op, F4b(c) en de sterke *Nine Sols*-check; ± 10–15 min, ± 3–4 runs (besluit 2026-11-12 (2)). Komt er geen P2, dan kan F4b(c) niet slagen; dat legt de EP vóór F8 voor (kader F4b).

## 6. Wat nog ontbreekt, en wie het bouwt

| # | Wat | Voor | Wie |
|---|---|---|---|
| G-1 | **Co-op-bot (duo) voor de Kadewijk**, per kamer en als lus, D = 60 (+ 90/120/180 regressie) | F4-3, F4b(b) co-op, voorwaarde MT3 | Gameplay Programmer |
| G-2 | **Boss in co-op in de Kadewijk-arena** | F4-3 boss, F3 | Gameplay Programmer (met Combat Designer) |
| G-3 | **Lus zonder echo** (C-15 over de hele slice) | F4-1, FK-2 | Gameplay Programmer |
| G-4 | Drop-in/drop-out in de Kadewijk-runs; schaduwklep bij drop-in | F3, MP-7 (d) | Gameplay Programmer |
| G-5 | Event `AFZET` van P1 (O-1, optioneel) | RV-1 bij een mens | Gameplay Programmer |
| Q-1 | `rekenen.gd` (MT2-kopie): **MP-1, MP-4 en F4b(b) per kamer** (nu alleen MP-2 per kamer, de rest over de doorloop) | F4-2, F4-4, F4b(b) per kamer | QA Lead |
| Q-2 | `rekenen.gd`: RV-6 vanaf de laatste `POMP` van P1 als de echo bij trap 2 niet pompte | B-1, MT2 | QA Lead |
| Q-3 | `rekenen.gd` voor co-op: `bron` `p2`, samenwerkingsacties, MP-7 (a)–(d) per kamer; MP-1 van P2 en de tijd dat P2 opgelost is (staan die niet in het meetlog, dan uit de testcode, zoals `testplan-f0.md` §2) | F4-3 | QA Lead (na G-1) |
| Q-4 | `testplan-mt3.md` en `ceo-kaart-mt3.md` | F4b(a)–(c) | QA Lead (na T8c/T8d en G-1) |
| Q-5 | Bot-cijfers van §3 opnieuw draaien op de build van MT2 en de per-kamer-waarden van Q-1 invullen | F4 | QA Lead (heeft Godot of CI nodig) |
| W-1 | Na MT2, als vraag 9b "leeg lopen" is: een echo-moment op of onder de trap terug (B-1) | S9 | World & Level Designer |
| E-1 | Een P2 voor MT3 regelen, of de `ceo-beslissing` als die er niet is | F4b(c) | Executive Producer |

**Wat dit plan nu niet kan**: geen engine in deze omgeving en geen CI-jobs; Q-1–Q-3 en Q-5 zijn scripts in `docs/qa/` die QA pas kan toetsen op een machine met Godot 4.6.3 of met werkende CI.

## 7. Werkaannames (kader §5)

**D = 60** is een CEO-besluit **als werkaanname** (nog niet gespeeld, `beslissingen.md` 2026-11-12); de indeling **MT1–MT3** is een werkaanname van de EP (kader §4). Uit de MT2-plannen blijven W31–W35 (`testplan-mt2.md` §7) voor MT2. Nieuw voor T11:

| # | Aanname | Waarom |
|---|---|---|
| W36 | **F4b(b) uit de korte doorlopen** van MT2 (solo) en MT3 (co-op), niet uit sessies van ± 1 uur zoals gdd §5.1 nog schrijft | Besluit 2026-11-12 (2): kaarten van ± 10–15 min. De LGD bevestigt of past gdd §5.1 aan |
| W37 | **Co-op eerst met de bots**: de duo-runs (G-1, G-2) zijn een voorwaarde voor MT3, zoals de solo-bots voor MT2; de co-op-bot telt als meting van MP-7 per kamer, MT3 als oordeel | Kader §4 (geen CEO-test zonder groene bots) en F4 ("eerst met de bots") |
| W38 | **Per kamer** = van het event `KAMER` tot het volgende; **de boss** = `BOSS_START` … `BOSS_VERSLAGEN`, apart van de route van S8 | Zo valt de boss uit de route-tijd van F4b(b) (gdd §5.1) en blijft S8 als kamer meetbaar |
| W39 | **Gaten en rustpunt met `POMP` van de echo**, MP-2 zonder (besluit LGD over B-1, #83), voor solo en co-op (in co-op de `POMP` van P2) | Het besluit noemt alleen solo; co-op volgt de definitie van MP-6 (pompslagen van P2) |

## Wijzigingen

| Versie | Datum | Wijziging |
|---|---|---|
| 0.1 | 2026-11-13 | Eerste versie (#88): F4-metingen en F4b(b) per kamer S1–S9 en de boss, solo en co-op; wat de bestaande tests en `mt2-meetlogs/` dekken (cijfers uit `kadewijk.md` §6–§6d en `testplan-mt2.md` §2.2/§2.4, niet opnieuw gedraaid); wat ontbreekt met eigenaar (G-1–G-5, Q-1–Q-5, W-1, E-1); MT2 verwezen, MT3 te maken; W36–W39 |
