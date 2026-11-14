# Testplan T11: de slice per kamer en de boss, solo en co-op (F4, F4b)

Versie 0.4 · 2026-11-14 · Eigenaar: QA Lead · Issue: [#88](https://github.com/cesarvangerwen-glitch/echoborn/issues/88) (T11) · Lead-review: Executive Producer

Basis: fasekader fase 2 (`docs/productie/fase-2-kader.md`: §2 rij T11, §3 F4 en F4b, §4 mijlpaaltests en regel tegen weggooiwerk, §5 kwaliteitslat); pitch v0.4 (§4 pillar 1, §10 R-V1, R-V2, R-V5, R-V9, R-V12); `docs/beslissingen.md` (#51: 1A, 7A, 8A; #124: 1B; 2026-11-12: D = 60 als werkaanname, fase 2 parallel, de CEO test alleen bij mijlpalen); gdd §4.5 (MP-1–MP-7) en §5.1 (grens F4b(b)); `docs/design/kamers/kadewijk.md` v0.4.8 (§6–§6d, §9); `docs/design/gemaalmeester.md` §7–§8; `game/tests/test_boss_runs.gd`; besluit LGD over B-1 ([comment in #83](https://github.com/cesarvangerwen-glitch/echoborn/issues/83#issuecomment-6845655429)).

## 0. Wat dit plan is

T11 is het overkoepelende testplan van de slice (de Kadewijk S1–S9 en de Gemaalmeester in S8). Het zegt **per kamer en voor de boss, solo en co-op**: welke F4-metingen, welke F4b(b)-gedragsmaat, welke test of meetlog dat nu al dekt, en wat nog ontbreekt, met de rol die het bouwt.

Het herhaalt de mijlpaaltests niet. Die hebben elk een eigen plan en kaart:

| Mijlpaal | Plan | Kaart voor de CEO | Toetst in T11 |
|---|---|---|---|
| MT2 (placeholder, met boss, **solo**) | `docs/qa/testplan-mt2.md` | `docs/qa/ceo-kaart-mt2.md` | F4 bij een mens solo, F4b(a) solo, F4b(b) solo (eerste meting) |
| MT3 (eindkwaliteit, **solo én co-op** met P2) | `docs/qa/testplan-mt3.md` (concept, §6 Q-4) | `docs/qa/ceo-kaart-mt3.md` (*nog te maken*, na T8c/T8d) | F4b(a) solo en co-op, F4b(b) co-op, F4b(c), sterke *Nine Sols*-check |

Het rapport aan het eind (F4 en F4b, voor F8) wordt `docs/qa/rapport-t11-slice.md`, met de bots, MT2 en MT3 samen.

**Wat in v0.2 gemeten is.** QA draaide op `main` `91d5143` (Godot 4.6.3 headless) `docs/qa/mt2-meetlogs/botlogs.gd` en de uitgebreide `rekenen.gd` (Q-1) op de lus bij D = 60, 90, 120 en 180: de per-kamer-waarden staan in **§3.1**. De build-commit van MT2 is nog niet vastgelegd (`testplan-mt2.md` §2.3); `91d5143` is dus de build *tot dan*, en QA draait dezelfde twee commando's opnieuw op de MT2-commit. De overige bot-cijfers in §3 (de losse kamer-runs) komen uit de bronnen die erbij staan en zijn niet één voor één opnieuw afgeleid (§6, Q-5). De CSV's staan niet in de repo (± 1 MB per hanglog, `testplan-mt2.md` §2.4). Alles wat **te meten** is, staat zo gemarkeerd.

**Wat in v0.3 gemeten is (co-op, Q-3).** QA draaide op `main` `bc678b7` (Godot 4.6.3 headless) `game/tests/test_kadewijk_coop.gd` met `POLDERLIGHT_BOTLOGS=<map>` (10 geslaagd, 0 mislukt) en daarna `docs/qa/mt2-meetlogs/rekenen.gd`, nu ook voor co-op, op de co-op-meetlogs: de lus bij D = 60, 90, 120 en 180, elke kamer los bij D = 60, en de solo-referentie van dezelfde test. De waarden staan in **§3.1** (F4 en F4b(b) per kamer, co-op naast solo) en **§4.1** (MP-7 (a)–(d) per kamer). Ook hier staan de CSV's niet in de repo.

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

gdd §5.1, **in beide modi**: route-tijd = `RUN_START` tot `RUN_EIND` zonder de ticks in een boss- of minibaas-arena (`BOSS_START` … `BOSS_VERSLAGEN`), het pauzemenu en tussenscènes. Positief als (1) ≥ 2,0 echo-acties/min, (2) springplank-landingen ≥ 1,0/min **én** ontploffingen door het tweede lichaam ≥ 0,5/min, (3) ≥ 30 % van de LP op de route met het tweede lichaam. In co-op is het tweede lichaam P2 en telt elke samenwerkingsactie van P1 en P2 (gdd §4.5 MP-2, MP-6). QA rapporteert ook **per kamer**, zodat een herontwerp weet waar de echo stilviel. In S8 telt alleen de route vóór `BOSS_START` en na `BOSS_VERSLAGEN` (W38).

## 3. Solo, per kamer en de boss

Bot = de gescripte geoefende run, D = 60. "Lus" = `test_kadewijk_lus.gd` met `docs/qa/mt2-meetlogs/botlogs.gd` (S1 → S8 → S9 → S1, `testplan-mt2.md` §2.2 en §2.4). "Los" = de kamer vanaf haar begin (`test_kadewijk.gd`, `_deel2.gd`, `_s9.gd`; `kadewijk.md` §6–§6c). MT2 = de doorloop van de CEO; alles in die kolom is **te meten** na de sessie.

| Kamer | Wat de kamer toetst | F4 bij de bot (gedekt) | F4b(b) bij de bot | Mens (MT2, te meten) | Ontbreekt (wie) |
|---|---|---|---|---|---|
| **S1** Kade-ingang | B1 keren (S1-B1), start, snelluik terug | MP-1 ≤ 8 (deel 1); MP-2 6,3/min (lus); keren 68 / langzame lijn 104 en met dash 94 | per kamer: §3.1 | MP-1, MP-2, A–D S1-B1 en S9-B1 (eind) | — (per kamer: §3.1) |
| **S2** Kadegang | B3-galerij, B1 terug (S2-B3, S2-B1) | MP-2 10,4/min; langste gat 715 ticks (S2 → S3, deel 1); C-15 per kamer ≤ 1,16× | idem | MP-1, MP-2, A–D S2-B3 en S2-B1 | — (§3.1) |
| **S3** Vismarkt | merk-arena, twee golven | MP-1 8 (de langste van deel 1); MP-2 15,3/min; RV-4 lege loop 539 ticks (9,0 s) | idem | MP-1, MP-2, RV-4 (vraag 9), RV-5 (vraag 13, alleen met kleur) | — (§3.1) |
| **S4** Brugkloof | B4 lancering van de bolder | MP-2 14,4/min; geen stilstand vóór de lancering; late-bot-tabel B4 (`kadewijk.md` §6) | idem | A–D S4-B4, RV-1 (vraag 6) | hangtijd bij een mens: event `AFZET` (O-1, Gameplay Programmer; optioneel) |
| **S5** Sluiswachtershuis | B2a–d, vier keer keren, lampglas | MP-1 0; MP-2 9,9/min; B2 keren 68 / 104 / 94; zonder echo 1,14× | idem | A–D B2a–d, RV-3 (vraag 7), kamertijd tegen 1304 | — (§3.1) |
| **S6** Gemaalplein | SL-01, het gemaal oppompen, trap 2 na de boss | MP-1 5; **MP-2 3,5/min, de krapste kamer** (B-3); SL-01 112 LP; gemaal vol op de eerste doorgang; zonder echo 1,45× (gelijk licht) | idem | MP-2 S6 (krap), pompslagen van de echo, RV-6 (vraag 9b) | — |
| **S7** Sluiskelder | luik, stuitlijn boven het kanaal, sokkel (Neerslag) | MP-2 16,7/min; 3 stuits, 2 ontploffingen (los 430 ticks); langzame lijn 1,04× | idem | RV-2 (stuiten, vraag 8), `BREEK` (verwacht 0) | — |
| **S8** Machinehal, route | gemaal → arena-deur, arena in en uit | gemaal → deur 555 ticks (≤ 10 s, SL-03) | route vóór `BOSS_START` en na `BOSS_VERSLAGEN` | tijd gemaal → deur | — |
| **Boss** Gemaalmeester | verplichte echo-acties: schot, rad, finisher | lus 97,6 s; arena-test 97,9 s (fase 1 28,4 / fase 2 63,5 s), realistische speler 109,3 s, beginner 121,2 s; MP-1 56; MP-2 27,2/min (S8); MP-3 76 % (B-2: de 7 met stilstand alle in fase 1) | telt niet (gdd §5.1) | GM-a (vraag 10, `BOSS_START` → `SCHOT_BREUK` ≤ 60 s), GM-b (springplank in fase 2 ≥ 2/min), GM-c (vraag 11), GM-d (MP-1 per fase ≤ 300), doden per fase (`gemaalmeester.md` §8; `testplan-mt2.md` §1 punt 4) | — |
| **S9** Lage kade | lus terug, rustpunt, B2a/b pijler, B1 grachtwand | MP-2 5,2/min (lus); rustpunt 932 ticks in de lus, gaten daarna ≤ 597; **na trap 2: laatste pompslag van de echo → eerste echo-actie in S9 1202 ticks (20,0 s)** (B-1); zonder echo 1,07× | idem | RV-6: dezelfde meting op de CSV van de CEO (pompte de echo niet bij trap 2, dan vanaf de laatste `POMP` van P1, Q-2); A–D S9-B2a/b, S9-B1 | — |
| **Doorloop** | de hele lus | MP-1 56 / MP-3 76 % / MP-4 0,4 % / MP-6 71 %; langste gat 2101 ticks (35,0 s); 0 echo-breuken bij 60/120/180; F4b(b) 8,2/min · 4,1 en 4,9/min · 78 % | ✅ op de bot (route-tijd 160,8 s) | alles van §2.1 en §2.2 solo | lus **zonder echo** (C-15 over de hele slice; Gameplay Programmer, `kadewijk.md` §9) |

Bronnen per cel: `kadewijk.md` §6, §6b, §6c, §6d en de boss-tabel; `testplan-mt2.md` §2.2 en §2.4. Grenzen en wat QA met een uitkomst doet: `testplan-mt2.md` §3, §4 en §6.

### 3.1 Per kamer gemeten (Q-1, de lus)

Gemeten 2026-11-14 op `main` `91d5143`, Godot 4.6.3 headless: `botlogs.gd` en daarna `rekenen.gd` (commando's in `testplan-mt2.md` §4.4). De lus-ticks zijn gelijk aan `kadewijk.md` §6d (15 504 / 15 245 / 15 392 / 16 838 bij D = 60 / 90 / 120 / 180) en de cijfers over de doorloop zijn gelijk aan `testplan-mt2.md` §2.4 (`de037be`); MP-2 per kamer is gelijk aan de MP-2-regel van FlowReport (S8 daar mét de boss). Een kamer = alle stukken van `KAMER` tot het volgende `KAMER` (W38), ook het tweede bezoek aan S5 en S6 bij trap 2. **Voor F4 (MP-1, MP-2, MP-4) telt S8 mét de boss**, zoals `testplan-mt2.md` §3 ("de normen van P1 gelden ook in het gevecht"); de grenzen per kamer komen uit die §3. De rij **S8 route** (zonder `BOSS_START` … `BOSS_VERSLAGEN`) is er alleen voor F4b(b) (gdd §5.1, W38); de rij **Boss** is informatie. Een stilstand over een kamergrens telt per kamer voor het deel dat erin valt.

**De boss-tijd** in de lus is 5853 ticks (`BOSS_START` 5322 → `BOSS_VERSLAGEN` 11 175) = 97,55 s: **97,6 s** afgerond, zoals in §3 (`rekenen.gd` drukt 97,5 af, `testplan-mt2.md` §2.4 ook; zelfde ticks, andere afronding). De 97,9 s in §3 en Q-5 is een andere meting: de boss in de **testarena** van `test_boss_runs.gd` (5875 ticks), niet in de lus.

**D = 60** (werkaanname):

| Kamer | Tijd (s) | MP-1 (≤ 300) | MP-2 /min (≥ 3,0) | MP-4 Leeg (≤ 40 %) | F4b(b) (1) acties/min (≥ 2,0) | (2) plank · ontploffing /min (≥ 1,0 · ≥ 0,5) | (3) LP met de echo (≥ 30 %) |
|---|---|---|---|---|---|---|---|
| S1 | 9,6 | 0 | 6,3 | 10,4 % | 6,3 | 6,3 · **0,0** | 100 % van 5 |
| S2 | 17,3 | 0 | 10,4 | 0 % | 10,4 | 6,9 · 3,5 | 73 % van 22 |
| S3 | 15,7 | 8 | 15,3 | 0 % | 15,3 | **0,0** · 19,1 | 70 % van 46 |
| S4 | 8,3 | 0 | 14,4 | 0 % | 14,4 | 7,2 · 7,2 | 87 % van 15 |
| S5 | 24,1 | 0 | 9,9 | 0 % | 9,9 | 9,9 · **0,0** | 100 % van 20 |
| S6 | 17,2 | 5 | 3,5 | 0 % | 3,5 | **0,0** · 7,0 | 75 % van 16 |
| S7 | 7,2 | 0 | 16,7 | 0 % | 16,7 | **0,0** · 16,7 | 75 % van 16 |
| S8 (mét de boss, F4) | 101,4 | 56 | 27,2 | 0 % | — | — | — |
| S8 route (alleen F4b(b)) | 3,8 | — | — | — | 0,0 | 0,0 · 0,0 | geen LP |
| Boss (informatie) | 97,6 | (56) | (28,3) | (0 %) | — | — | — (telt niet, gdd §5.1) |
| S9 | 57,6 | 2 | 5,2 | 0 % | 5,2 | 3,1 · 2,1 | 77 % van 35 |
| Doorloop / route | 258,4 / 160,8 | 56 | 15,8 | 0,4 % | 8,2 | 4,1 · 4,9 | 78 % van 175 → **positief** |

**Regressie D = 90 / 120 / 180** (alleen wat afwijkt van D = 60): MP-1 per kamer buiten S8 ≤ 8; S8 (mét de boss) MP-1 59 / 92 / 56 en MP-2 28,4 / 24,9 / 26,0. MP-4 alleen in S1 boven 0 % (15,9 / 21,2 / 31,7 %: de echo is Leeg tot tick D na `RUN_START`, E-03), elders 0 %. Laagste MP-2 per kamer gelijk aan `testplan-mt2.md` §2.4: S6 3,5, en **S7 0,0 bij D = 180** (B-4, bekend). F4b(b) per kamer heeft bij D = 90 en 120 hetzelfde patroon als bij D = 60; bij D = 180 haalt S4 geen ontploffing (11,4 · 0,0) en S5 wel (9,9 · 2,5), en mist S7 alle vier.

**Co-op, D = 60 (Q-3)**: dezelfde tabel uit `bot_lus_coop_D60.csv` (`test_kadewijk_coop.gd`, het duo van `kadewijk_duo.gd`). MP-1 is hier van P1; MP-1 van P2 en MP-7 staan in §4.1. MP-4 vervalt in co-op (geen echo; P2 opgelost is MP-7 (d)). F4b(b) (3) = LP van P2 of uit een samenwerkingsactie (W41).

| Kamer | Tijd (s) | MP-1 P1 (≤ 300) | MP-2 /min (≥ 3,0) | F4b(b) (1) acties/min (≥ 2,0) | (2) plank · ontploffing /min | (3) LP met P2 of samen (≥ 30 %) |
|---|---|---|---|---|---|---|
| S1 | 8,8 | 7 | 6,8 | 6,8 | 6,8 · **0,0** | 100 % van 5 |
| S2 | 19,8 | 59 | 9,1 | 9,1 | 6,1 · 3,0 | 100 % van 22 |
| S3 | 16,3 | 7 | 14,7 | 14,7 | **0,0** · 18,4 | 70 % van 46 |
| S4 | 9,5 | 39 | 12,6 | 12,6 | 6,3 · 6,3 | 100 % van 15 |
| S5 | 29,2 | 59 | 8,2 | 8,2 | 8,2 · **0,0** | 100 % van 20 |
| S6 | 17,3 | 4 | 6,9 | 6,9 | 3,5 · 6,9 | 100 % van 21 |
| S7 | 10,8 | 7 | 27,9 | 27,9 | 16,7 · 11,1 | 63 % van 27 |
| S8 (mét de boss, F4) | 89,9 | 108 | 32,7 | — | — | — |
| S8 route (alleen F4b(b)) | 3,0 | — | — | 0,0 | 0,0 · 0,0 | geen LP |
| Boss (informatie) | 86,9 | (108) | (33,8) | — | — | — |
| S9 | 63,1 | 35 | 4,8 | 4,8 | 2,9 · 1,9 | 82 % van 33 |
| Doorloop / route | 264,7 / 177,8 | 108 | 17,0 | 8,8 | 5,1 · 4,4 | 84 % van 189 → **positief** |

Regressie co-op D = 90 / 120 / 180: MP-1 van P1 per kamer buiten S8 ≤ 61, in S8 108; MP-2 per kamer ≥ 3,6 (S9 3,8 / 3,6 / 3,6 is de krapste, niet S6 zoals solo); F4b(b) over de route 8,4 / 8,1 / 7,8 acties/min, (2) ≥ 3,6 · ≥ 3,6, (3) 86 / 85 / 81 % → positief. Per kamer hetzelfde patroon als bij D = 60; bij D = 120 en 180 zakt (2) ontploffing in S9 naar 0,9/min.

**Lezing.**
- **Co-op tegen solo per kamer**: hetzelfde patroon van F4b(b) (2) (keerkamers S1, S5 alleen planken; merkkamer S3 alleen ontploffingen), maar S6 en S7 halen in co-op ook planken (P2 als plank bij het gemaal en het kanaal). S6 is in co-op niet meer de krapste kamer voor MP-2 (6,9 tegen 3,5 solo); dat is nu **S9** (4,8 bij D = 60, 3,6 bij D = 120/180), de kamer waar P2 op P1 wacht (§4, punt SM).
- **F4-4 per kamer (MP-1, MP-2): groen bij de bot, in elke kamer.** MP-1 ≤ 8 ticks buiten S8, in S8 (mét de boss) 56 (grens 300); MP-2 ≥ 3,0 in elke kamer, S8 27,2. S6 blijft de krapste (3,5, B-3).
- **F4-2 per kamer (MP-4): groen.** De bot laat de echo nergens Leeg vallen; de enige Leeg-tijd is de start in S1 (60 ticks). Bij een mens is MP-4 per kamer pas informatief na een `RESPAWN` of `BREEK` (de echo begint dan opnieuw Leeg); daarom staat het per kamer in de rekenregel.
- **F4b(b) per kamer is een rapportwaarde, geen norm per kamer** (W40). Criterium (2) splitst per kamer in wat de kamer toetst: de keerkamers S1 en S5 geven alleen springplank-landingen, de merkkamers S3, S6 en S7 alleen ontploffingen; samen over de route is (2) ruim gehaald. (1) en (3) zijn in elke kamer met echo-werk gehaald. Zonder echo-actie zijn alleen de S8-route (3,8 s: arena in en uit) en, als regressie, S7 bij D = 180.
- **Bij de CEO (MT2)** geeft dezelfde `rekenen.gd` deze tabel uit zijn CSV; dan zijn de kamertijden langer en is een kamer met (1) < 2,0 of MP-1 > 300 een verdwaal- of stilvalpunt voor het rapport (`testplan-mt2.md` §4.1).

## 4. Co-op, per kamer en de boss

Co-op = P1 en P2, met P2 in de rol van de echo (7A, C-01–C-05); drop-in/drop-out hoort bij F3. Voor F4 tellen eerst **de bots** (kader F4); de co-op-normen bij mensen (F4b(c)) meet MT3 op de kamers die de kaart speelt, **de rest meten de bots** (kader F4b(c)).

| Kamer | Co-op bij de bot nu | Ontbreekt | Wie |
|---|---|---|---|
| S1–S7, S9 | `test_kadewijk_coop.gd` (G-1, het duo van `kadewijk_duo.gd`): elke kamer los en als lus bij D = 60 (90/120/180 regressie); checks MP-1 van P1 én P2, MP-2, MP-4 (alleen in de test; in `rekenen.gd` vervalt MP-4 in co-op, §3.1), MP-6, SL-01, MP-7 (b)–(d) per kamer en over de lus; B4 met de bolder, S9 met trap 2 en het snelluik. Per kamer gemeten door QA: §3.1 (F4, F4b(b)) en §4.1 (MP-7). Alles gehaald op D = 60 | **een wachtmaat** (punt SM hieronder); C-15 d | Lead Game Designer ([#290](https://github.com/cesarvangerwen-glitch/echoborn/issues/290)); Gameplay Programmer |
| S8 route en arena | lus en S8 los in co-op tot en met de arena-deur (`test_kadewijk_coop.gd`) | — | — |
| **Boss** | **Testarena** (600 px): `test_boss_runs.gd`, co-op bij D = 60 85 s (grens 75–150 s), MP-7 (a) 0,87–0,95 bij 60/90/120; drop-out van P2 in fase 1; C-16 met P2 die nooit slaat. **Kadewijk-arena** (G-2, B-14 deel 2): `test_kadewijk_coop.gd` speelt de boss in de lus en in S8 los, met binnenkomst, vaste arena-camera met beide spelers in beeld en P2 in elke fase (GMB-14, GMB-15); check MP-7 (b) van P2 in de boss ≤ 300: **108–146 ticks** (§4.2). Status: **gebouwd**; gehaald pas na de eerste groene nachtrun van `test_kadewijk_coop.gd` op `main` (W43) | B-14 v0.1.7 in de bot: note-run "P2 op één plek" met de checks b1/b2, P2 in fase 2 ± 150 (grens 180), de doelhelft uit bij een drop-out (`DOELHELFT` = geen); MP-7 (e) per fase (punt SM) | Gameplay Programmer, met de Combat Designer ([#302](https://github.com/cesarvangerwen-glitch/echoborn/issues/302)) |
| Drop-in/drop-out | generiek in `test_coop.gd`, `test_coop_deel2.gd`; boss: drop-out fase 1 | drop-in en drop-out midden in de Kadewijk: per kamer één keer, plus de open vraag "drop-in terwijl de schaduwklep ligt" (`kadewijk.md` §9, TD); in de boss: drop-out midden in een maat (doelhelft meteen uit, zetten en knallen van beide kanten) en drop-in (gloed pas op de volgende aanloop), GMB-14 (b), (f) | Gameplay Programmer; QA toetst in de duo-runs |
| Doorloop | de lus S1 → S8 → S9 → S1 in co-op bij D = 60 (90/120/180 regressie), `test_kadewijk_coop.gd`; F4b(b) co-op op route-tijd met `rekenen.gd` (Q-3, §3.1) | — | — |

**Open punten uit de review van G-1** (vóór MT3):
- **TD (rij Boss)**: op `bc678b7` liet de boss-bot P2 ± 925–947 ticks stilstaan (§4.1). Met G-2 (B-14 deel 2) is MP-7 (b) van P2 in de boss een check van `test_kadewijk_coop.gd`, en de uitvoer geeft 108–146 ticks (§4.2). **Gebouwd, nog niet gehaald** (W43).
- **SM (wachten)**: op `bc678b7` wachtte P2 in S9 1556 ticks (± 41 % van de kamer). De wachtmaat bestaat nu: MP-7 (e) (gdd §4.5, [#290](https://github.com/cesarvangerwen-glitch/echoborn/issues/290)), met de merk-combo als eigen actie van de ontsteker en de keerpunt-taak "wie achteraan komt, draagt" (gdd §4.8.8, [#299](https://github.com/cesarvangerwen-glitch/echoborn/issues/299)). De test meet MP-7 (e) per speler; **buiten de boss niet gehaald** (§4.2). `rekenen.gd` rekent MP-7 (e) nog niet (§6 Q-6).

### 4.1 Co-op per kamer gemeten (Q-3, MP-7)

Gemeten 2026-11-14 op `main` `bc678b7`, Godot 4.6.3 headless: `test_kadewijk_coop.gd` met `POLDERLIGHT_BOTLOGS=<map>`, daarna `rekenen.gd` op die map (§6 Q-3). Per kamer en de boss zoals W38 (S8 mét de boss, S8 route en de boss apart). (a) = tijd co-op / tijd van de solo-lus in dezelfde run (`bot_lus_solo_D60.csv`, 15 504 ticks); (b) = MP-1 van P2 (`STIL_EIND` met bron `p2`); (c) = samenwerkingsacties per minuut (W41); (d) = de tijd tussen `P2_OPGELOST` en `P2_TERUG` of `DROP_OUT`. De S8-route (3 s, arena in en uit) zonder (c), zoals de test.

**Lus, D = 60** (264,7 s, 1,02× de solo-lus; gelijk aan de uitvoer van de test, behalve MP-1 per kamer: `rekenen.gd` telt het deel van een stilstand dat in de kamer valt, de test de stilstand die in de kamer eindigt, bv. MP-1 van P2 in de S8-route 13 hier tegen 117 in de test):

| Kamer | Tijd co-op (s) | (a) co-op / solo (≥ 0,5) | MP-1 P1 (≤ 300) | (b) MP-1 P2 (≤ 300) | (c) samen /min (≥ 1,0) | (d) P2 opgelost (≤ 10 %) | MP-6 LP met P2 of samen | Wachten P1 / P2 (ticks, test) |
|---|---|---|---|---|---|---|---|---|
| S1 | 8,8 | 0,92× | 7 | 45 | 6,8 | 0 % | 100 % van 5 | 0 / 0 |
| S2 | 19,8 | 1,14× | 59 | 28 | 9,1 | 0 % | 100 % van 22 | 0 / 0 |
| S3 | 16,3 | 1,04× | 7 | 7 | 14,7 | 0 % | 70 % van 46 | 0 / 0 |
| S4 | 9,5 | 1,14× | 39 | 0 | 12,6 | 0 % | 100 % van 15 | 0 / 0 |
| S5 | 29,2 | 1,21× | 59 | 38 | 8,2 | 0 % | 100 % van 20 | 0 / 0 |
| S6 | 17,3 | 1,01× | 4 | 16 | 6,9 | 0 % | 100 % van 21 | 0 / 124 |
| S7 | 10,8 | 1,50× | 7 | 9 | 27,9 | 0 % | 63 % van 27 | 208 / 166 |
| S8 route | 3,0 | 0,79× | 8 | 13 | — | 0 % | geen LP | 0 / 0 |
| **Boss** | 86,9 | 0,89× | 108 | **931** | 33,8 | 0 % | 77 % van 471 | — |
| S9 | 63,1 | 1,10× | 35 | 58 | 4,8 | 0 % | 82 % van 33 | 21 / **1556** |
| Route (zonder boss) | 177,8 | — | 59 | 58 | 8,8 | 0 % | 84 % van 189 | 229 / 1846 (lus) |
| Doorloop | 264,7 | 1,02× | 108 | **931** | 17,0 | 0 % | 79 % van 660 | |

Over de lus verder: MP-3 93 % van 41 landingen, SL-01 126 LP vóór de eerste pompslag, 11 pompslagen van P1 en 3 van P2 (alle bij het gemaal; **bij trap 2 pompt alleen P1**), RV-6 (na trap 2, vanaf de laatste `POMP` van P1, Q-2) 1150 ticks (19,2 s), langste gat 2076 ticks (34,6 s). S9 vanaf de binnenkomst via trap 2: gaten 868, 324, 616, 590, 832, 382 ticks (met de `POMP` van P2, W39): het rustpunt (≤ 720) en twee gaten daarna (616 en 832, grens ≤ 600) worden niet gehaald. Dat is slechter dan solo: solo mist alleen het rustpunt (932, B-1).

**Elke kamer los, D = 60**: MP-7 (b)–(d) gehaald in S1–S7 en S9 (MP-1 van P2 ≤ 51, (c) ≥ 5,4/min, (d) 0 %); S8 los: de boss 87,1 s, MP-1 van P2 **947**. S6 los duurt 83,9 s (het duo begint met 0 LP en haalt licht in S5, LM-13; zegt niets over de lus).

**Regressie D = 90 / 120 / 180**: 264,5 / 272,6 / 272,0 s; MP-1 van P2 in de boss 931 bij elke D, buiten de boss ≤ 107 (S4 bij D = 120); (c) per kamer ≥ 3,6/min (S9); (d) 0 %; MP-6 80 / 80 / 78 %; SL-01 128 / 130 / 128 LP; RV-6 1145 / 1130 / 1095 ticks; P2 wacht in S9 1275 / 1465 / 1425 ticks. (a) alleen bij D = 60 (de solo-referentie van de test).

**Lezing.**
- **MP-7 per kamer: gehaald in S1–S7, de S8-route en S9**; (b)–(d) bij elke D, (a) alleen bij D = 60 gemeten (open punt in §6 Q-5). (a) ligt bij D = 60 tussen 0,79× en 1,50×: co-op is nergens sneller dan 2× solo; (c) ruim boven 1,0; P2 lost nergens op (d), want het duo valt niet.
- **De boss: MP-7 (b) niet gehaald op `bc678b7`** (931 / 947 ticks, de testarena-bot). Na G-2 zie §4.2.
- **S9: (b) gehaald, toch wacht P2 41 % van de kamer** (punt SM in §4, [#290](https://github.com/cesarvangerwen-glitch/echoborn/issues/290)). MP-1 ziet het niet, omdat P2 heen en weer loopt. Ook MP-2 toont het: S9 is in co-op de kamer met de laagste MP-2 (4,8; 3,6 bij D = 120/180, waar ook (2) ontploffing in S9 naar 0,9/min zakt; §3.1).
- **Trap 2 in co-op was op `bc678b7` werk voor P1 alleen** (geen `POMP` van P2). Na de duo-bot van [#292](https://github.com/cesarvangerwen-glitch/echoborn/issues/292) pompt P2 mee (§4.2); bij een mens blijft het een vraag voor MT3 en W-1.

### 4.2 Na G-2: de boss in de Kadewijk-arena (uitvoer van de test)

Bron: de uitvoer van `test_kadewijk_coop.gd` op `main` `a400888` (B-14 deel 2; Linux, Godot 4.6.3 headless, alle tests geslaagd). `rekenen.gd` is daar nog niet op gedraaid: de tabel in §4.1 blijft de meting op `bc678b7`, tot de herhaling in Q-4 (stap 1). De test telt MP-1 per kamer anders dan `rekenen.gd` (§4.1), dus de getallen kunnen een paar ticks verschillen.

| Wat | Lus D = 60 | D = 90 / 120 / 180 | S8 los D = 60 | Grens | Gehaald? |
|---|---|---|---|---|---|
| MP-7 (b) P2 in de boss | 110 | 110 / 110 / 146 | 108 | ≤ 300 | ja, in de test (W43) |
| MP-1 P1 in de boss | 95 | 95 / 95 / 95 | 95 | ≤ 300 | ja |
| Camera in de arena | vast 5131/5131 ticks, beide spelers in beeld | idem (D = 180: 5231/5231) | idem | GM-01 | ja |
| MP-7 (e) wachten, trap 2 (P1 / P2) | 0 / 0 %, P2 pompt 3× | idem | — | langste ≤ 300, ≤ 5 % | ja |
| MP-7 (e) wachten buiten de boss (P1 / P2) | 12,2 / 11,0 %, langste 294 / 238 | P1 tot 15,8 %, P2 langste tot 367 | — | norm ≤ 300 en ≤ 5 %; check van de test nu 400 / 16 % | **nee** (keerpunten en smalle plekken, [#298](https://github.com/cesarvangerwen-glitch/echoborn/issues/298), [#299](https://github.com/cesarvangerwen-glitch/echoborn/issues/299)) |
| P2 wacht op P1 in S9 (`wait_ticks`) | 587 | 525 / 489 / 460 | — | rapportwaarde | (was 1556) |

**Lezing.** MP-7 (b) in de boss ligt nu ruim onder 300, ook bij D = 180; dat is wat G-2 vroeg. Het wachten verschuift naar buiten de boss: MP-7 (e) haalt daar de norm van gdd §4.5 niet, en de test laat dat met een ruimere regressiegrens door. Dat staat niet in de weg van G-2, wel van de voorwaarde voor MT3.

**Nog niet in de bot** (B-14 v0.1.7, `combat/slice-vijanden-en-boss.md`, [#302](https://github.com/cesarvangerwen-glitch/echoborn/issues/302)): de note-run "P2 blijft als ontsteker op één plek" met b1 (elke breuk van een merk gezet met de doelhelft tegenover P2, op de tick van het zetten) en b2 (fase 1 ≥ 1,25 × zo lang); P2 in fase 2 ± 150 met bovengrens 180; de doelhelft uit bij een drop-out. QA toetst die checks in de uitvoer zodra ze in de test staan, en neemt ze op in de voorwaarde voor MT3.

**Te meten in MT3 (CEO + P2)**, volgens kader F4b(c) en `testplan-f0.md` §1: norm (3) co-op (MP-5 ≥ 4,0, geen deel < 3,0), C1–C2 (wachten; partner als hulp of last), MP-7 (a)–(d), F4b(a) co-op, F4b(b) co-op, **de boss in co-op: GM-a en GM-b in beide modi, GM-c, GM-d voor P1 én P2 (MP-7 (b)) per fase** (`gemaalmeester.md` §8), en M1 van P2 als **sterke** *Nine Sols*-check (alleen als P2 de referenties niet kent en antwoordt vóór uitleg over het merk).

**Voorwaarde voor MT3** (kader §4, "geen CEO-test zonder groene bots"): de co-op-duo-runs halen MP-1 (P1 en P2) en MP-7 (a)–(e) op D = 60 in elke kamer en de boss. **Bij de bot nu**: elke kamer (§4.1) en de boss (§4.2, gebouwd; gehaald na de nachtrun, W43) halen (a)–(d); **MP-7 (e) buiten de boss niet**. De lijst per check staat in `testplan-mt3.md` §2.

## 5. De kaarten (F4b(a))

- **MT2**: kaart en plan staan (verwijzing in §0). F4b(a) solo zit in vraag 1–3, MP-5 in vraag 5, de meetvragen RV-1–RV-6 in 6–9b en 13. Het besluit van de LGD over B-1 zit erin als vraag 9b ("Na het pompen van trap 2, de trap af en over de kade: voelde dat als beloning of als leeg lopen?") en als meting RV-6 (`testplan-mt2.md` §1.1, §4.3; bot 1202 ticks, 20,0 s). MT2 start na MT1 (`testplan-mt2.md` §0).
- **MT3**: plan als concept in `docs/qa/testplan-mt3.md` (Q-4): wanneer MT3 start, de voorwaarden per check, wat MT3 meet en wat het observeert. De kaart volgt als T8c en T8d de slice op eindkwaliteit hebben en E-1 een P2 heeft. Inhoud: dezelfde F4b(a)-vragen solo én co-op, F4b(c) en de sterke *Nine Sols*-check; ± 10–15 min, ± 3–4 runs (besluit 2026-11-12 (2)). Komt er geen P2, dan kan F4b(c) niet slagen; dat legt de EP vóór F8 voor (kader F4b).

## 6. Wat nog ontbreekt, en wie het bouwt

| # | Wat | Voor | Wie |
|---|---|---|---|
| G-1 | **Co-op-bot (duo) voor de Kadewijk**, per kamer en als lus, D = 60 (+ 90/120/180 regressie). **Gedaan**: `game/tests/test_kadewijk_coop.gd` met `kadewijk_duo.gd`; de meetlogs met `POLDERLIGHT_BOTLOGS` | F4-3, F4b(b) co-op, voorwaarde MT3 | Gameplay Programmer |
| G-2 | **Boss in co-op in de Kadewijk-arena**, met MP-7 (b) van P2 ≤ 300. **Gebouwd** (B-14 deel 2): 108–146 ticks in de test (§4.2); **gehaald** pas na de eerste groene nachtrun van `test_kadewijk_coop.gd` op `main` (W43). Rest van B-14 v0.1.7 (b1/b2, fase 2 ≤ 180, doelhelft bij drop-out): §4.2 | F4-3 boss, F3, voorwaarde MT3 | Combat Designer ([#289](https://github.com/cesarvangerwen-glitch/echoborn/issues/289), [#302](https://github.com/cesarvangerwen-glitch/echoborn/issues/302)), met de Gameplay Programmer |
| L-1 | **Wachtmaat voor MP-7**. **Gedaan**: MP-7 (e) in gdd §4.5, met de merk-combo als eigen actie en de keerpunt-taak in §4.8.8 | F4-3, voorwaarde MT3 | Lead Game Designer ([#290](https://github.com/cesarvangerwen-glitch/echoborn/issues/290), [#299](https://github.com/cesarvangerwen-glitch/echoborn/issues/299)) |
| G-6 | **MP-7 (e) buiten de boss ≤ 5 % en langste ≤ 300** bij D = 60 (nu 12,2 / 11,0 %, §4.2): de keerpunten (KP-1–KP-3, gdd §4.8.8) en de smalle plekken in de duo-bot; daarna de check van de test naar de norm | F4-3, voorwaarde MT3 | Gameplay Programmer ([#298](https://github.com/cesarvangerwen-glitch/echoborn/issues/298), [#299](https://github.com/cesarvangerwen-glitch/echoborn/issues/299)) |
| G-3 | **Lus zonder echo** (C-15 over de hele slice) | F4-1, FK-2 | Gameplay Programmer |
| G-4 | Drop-in/drop-out in de Kadewijk-runs; schaduwklep bij drop-in | F3, MP-7 (d) | Gameplay Programmer |
| G-5 | Event `AFZET` van P1 (O-1, optioneel) | RV-1 bij een mens | Gameplay Programmer |
| Q-1 | `rekenen.gd` (MT2-kopie): **MP-1, MP-4 en F4b(b) per kamer**, de boss apart. **Gedaan in v0.2**: de tabel "per kamer (Q-1)" in de uitvoer; waarden van de bot in §3.1 | F4-2, F4-4, F4b(b) per kamer | QA Lead |
| Q-2 | `rekenen.gd`: RV-6 vanaf de laatste `POMP` van P1 als de echo bij trap 2 niet pompte. **Gedaan in v0.3** (W42); solo ongewijzigd (de echo pompt daar), in co-op nodig (P2 pompt niet bij trap 2) | B-1, MT2 | QA Lead |
| Q-3 | `rekenen.gd` voor co-op: `bron` `p2`, samenwerkingsacties, MP-7 (a)–(d) per kamer; MP-1 van P2 en de tijd dat P2 opgelost is. **Gedaan in v0.3**: de MT2-kopie `docs/qa/mt2-meetlogs/rekenen.gd` is uitgebreid, geen aparte T11-kopie (één rekenregel voor solo en co-op, ook voor de CSV's van MT3); een meetlog met bron `p2` is co-op en krijgt de tabel "co-op per kamer (Q-3)". De solo-uitvoer op de vier solo-lussen is regel voor regel gelijk aan v0.2, op het label "(RV-6)" na. MP-1 van P2 en `P2_OPGELOST`/`P2_TERUG` staan in het meetlog; alleen de wachttijd niet (§4, punt SM). Waarden: §3.1 en §4.1 | F4-3 | QA Lead |
| Q-4 | `testplan-mt3.md` en `ceo-kaart-mt3.md`. **Plan als concept** (voorwaarden per check, metingen, observaties); de kaart en de definitieve versie na T8c/T8d, G-6 en E-1 | F4b(a)–(c) | QA Lead |
| Q-6 | `rekenen.gd`: MP-7 (e) per speler en per kamer uit het meetlog (zelfde definitie als gdd §4.5), zodat MT3 het wachten bij mensen meet en niet alleen de test | F4-3, MT3 | QA Lead |
| Q-5 | Bot-cijfers van §3 opnieuw draaien op de build van MT2 en de per-kamer-waarden van Q-1 invullen. **Deels gedaan in v0.2**, op `main` `91d5143` (de MT2-commit is nog niet vastgelegd): de lus bij 60/90/120/180 opnieuw gemeten en Q-1 ingevuld (§3.1); de hele suite groen (456 geslaagd, 0 mislukt); steekproef van de losse kamer-cijfers in §3 uit de uitvoer van de suite, alle gelijk (keren 68 / 104 / 94, S5 1304 en 1,14×, S7 430 en 1,04×, S9 1,07×, SL-01 112 LP, gemaal → deur 555, langste gat S1–S4 715, boss in de testarena 97,9 / 109,3 / 121,2 s). **Open**: dezelfde run op de MT2-commit zodra `testplan-mt2.md` §2.3 die noemt; daarin ook MP-7 (a) bij D = 90/120/180, met de solo-lussen van `botlogs.gd` in dezelfde map als de co-op-meetlogs | F4 | QA Lead |
| W-1 | Na MT2, als vraag 9b "leeg lopen" is: een echo-moment op of onder de trap terug (B-1) | S9 | World & Level Designer |
| E-1 | Een P2 voor MT3 regelen, of de `ceo-beslissing` als die er niet is; de EP neemt het op als Q-4 start | F4b(c) | Executive Producer |

**Wat dit plan nu niet kan**: per kamer bij een mens meten (dat komt uit de CSV van MT2 en MT3, met dezelfde `rekenen.gd`); MP-7 (e) uit een meetlog halen (Q-6); MP-7 (b) in de boss gehaald melden vóór de nachtrun (W43).

## 7. Werkaannames (kader §5)

**D = 60** is een CEO-besluit **als werkaanname** (nog niet gespeeld, `beslissingen.md` 2026-11-12); de indeling **MT1–MT3** is een werkaanname van de EP (kader §4). Uit de MT2-plannen blijven W31–W35 (`testplan-mt2.md` §7) voor MT2. Nieuw voor T11:

| # | Aanname | Waarom |
|---|---|---|
| W36 | **F4b(b) uit de korte doorlopen** van MT2 (solo) en MT3 (co-op), niet uit sessies van ± 1 uur zoals gdd §5.1 nog schrijft | Besluit 2026-11-12 (2): kaarten van ± 10–15 min. De LGD bevestigt of past gdd §5.1 aan |
| W37 | **Co-op eerst met de bots**: de duo-runs (G-1, G-2) zijn een voorwaarde voor MT3, zoals de solo-bots voor MT2; de co-op-bot telt als meting van MP-7 per kamer, MT3 als oordeel | Kader §4 (geen CEO-test zonder groene bots) en F4 ("eerst met de bots") |
| W38 | **Per kamer** = van het event `KAMER` tot het volgende; **de boss** = `BOSS_START` … `BOSS_VERSLAGEN`, apart van de route van S8; uit de route-tijd vallen ook minibaas-arena's, het pauzemenu en tussenscènes (in de slice nu geen van drieën) | Zo valt de boss uit de route-tijd van F4b(b) (gdd §5.1) en blijft S8 als kamer meetbaar |
| W39 | **Gaten en rustpunt met `POMP` van de echo**, MP-2 zonder (besluit LGD over B-1, #83), voor solo en co-op (in co-op de `POMP` van P2) | Het besluit noemt alleen solo; co-op volgt de definitie van MP-6 (pompslagen van P2) |
| W40 | **F4b(b) per kamer is een rapportwaarde**: de drie grenzen van gdd §5.1 gelden over de route-tijd; per kamer laat QA zien waar de echo stilvalt. Een kamer met (1) < 2,0 bij een mens is een bevinding voor de LGD; (2) per kamer niet, want elke kamer toetst één soort echo-actie (keren of merken). W40 wijzigt geen norm; de grenzen van MP-1, MP-2 en MP-4 per kamer komen uit `testplan-mt2.md` §3 | gdd §5.1: "De QA Lead rapporteert ook de waarden per wijk, zodat het herontwerp weet waar de echo stilviel." De grens legt §5.1 over de route |
| W41 | **Co-op: MP-7 (c) en MP-6 zoals `test_kadewijk_coop.gd`**. (c) "per speler" = alle samenwerkingsacties per minuut (dezelfde acties als MP-2: één contact per drager en tick, een ketting als één), want elke actie vraagt beide spelers; MP-6 en F4b(b) (3) = LP met bron `_p2` of uit een samenwerkingsactie (`springplank`, `bounce`, `lancering`, `vangen`, `ontploffing`) | Zelfde getal als de check van de GP; gdd §4.5 zegt niet hoe "per speler" telt. De LGD bevestigt bij #290 |
| W42 | **RV-6 "bij trap 2"** = een `POMP` in de kamer van `TRAP_VOL 2`, vanaf de laatste binnenkomst daar tot 120 ticks na `TRAP_VOL 2`; zonder `POMP` van het tweede lichaam (de echo, in co-op P2) daar telt de laatste `POMP` van P1 (Q-2) | Zonder die grens pakt RV-6 in co-op de pompslag bij het gemaal (± 6900 ticks eerder) |
| W43 | **Gebouwd ≠ gehaald.** Een nieuwe check in een lang testscript (`LANG_SCRIPTS`) telt als **gebouwd** als hij in de PR en na de merge groen is, en als **gehaald** pas na de eerste groene nachtrun op `main` die dat script draait | Afspraak van de Producer bij G-2; de nachtrun draait de volledige matrix (besluit 2026-11-13, CI zuiniger) |

**Open punt bij W41:** MP-7 (c) is onder W41 hetzelfde getal als MP-2, terwijl gdd §4.5 "per speler" vraagt; tot de LGD W41 bevestigt ([#290](https://github.com/cesarvangerwen-glitch/echoborn/issues/290)) is "(c) gehaald" geen onafhankelijk bewijs.

**Open punt bij W40:** de LGD bevestigt W40 (F4b(b) per kamer als rapportwaarde, met (1) < 2,0 bij een mens als bevinding) bij de volgende wijziging van gdd §5.1.

**Open punt bij W36:** `gemaalmeester.md` §7 noemt voor T11 "eerste speler 8–12 min inclusief pogingen"; dat past niet in een MT2-kaart van ± 10–15 min voor de hele slice. De LGD beslist of het een rapportwaarde uit MT2 wordt of vervalt.

## Wijzigingen

| Versie | Datum | Wijziging |
|---|---|---|
| 0.4 | 2026-11-14 | Na G-2 (B-14 deel 2), slice-vijanden-en-boss v0.1.7 en gdd v0.8.7 (keerpunten, merk-combo in MP-7 (e)): §4 rij Boss naar de Kadewijk-arena (gebouwd, gehaald na de nachtrun, W43) en drop-in/drop-out in de boss; punten TD en SM bijgewerkt; nieuw §4.2 (uitvoer van de test op `a400888`); voorwaarde MT3 met MP-7 (e); §6: G-2 gebouwd, L-1 gedaan, nieuw G-6 en Q-6, Q-4 als concept in `testplan-mt3.md`; W43 |
| 0.3 | 2026-11-14 | Q-3: `rekenen.gd` (MT2-kopie, uitgebreid) rekent co-op (bron `p2`): MP-7 (a)–(d) per kamer, MP-1 van P2, P2 opgelost, MP-6 en F4b(b) met P2; gemeten op de co-op-meetlogs van `test_kadewijk_coop.gd` (`main` `bc678b7`, D = 60/90/120/180 en elke kamer los): co-op in §3.1, nieuw §4.1. Q-2: RV-6 vanaf de laatste `POMP` van P1 (W42). §4: G-1 ingevuld, punten TD (boss, G-2, [#289](https://github.com/cesarvangerwen-glitch/echoborn/issues/289)) en SM (wachten, [#290](https://github.com/cesarvangerwen-glitch/echoborn/issues/290)); voorwaarde MT3 met de stand bij de bot. §6: G-1, Q-2, Q-3 gedaan, G-2 naar de Combat Designer, L-1 nieuw. W41, W42 |
| 0.2.1 | 2026-11-14 | Na Lead-review EP (#284): S8 mét de boss voor F4 in §3.1 en in `rekenen.gd` (de S8-route alleen voor F4b(b)), geen vrijstelling van MP-2; W40 met de zin "waarden per wijk" uit gdd §5.1 als grond, grenzen per kamer uit `testplan-mt2.md` §3; boss-tijd 97,6 s (lus) tegen 97,9 s (testarena) toegelicht; open punt bij W40 |
| 0.2 | 2026-11-14 | Q-1: `rekenen.gd` rekent MP-1, MP-2, MP-4 en F4b(b) per kamer, de boss apart; gemeten op de lus (`main` `91d5143`, Godot 4.6.3 headless, D = 60/90/120/180) en ingevuld in nieuw §3.1; §3 verwijst ernaar. Q-5 deels: lus en suite opnieuw gedraaid, steekproef §3 gelijk; open: de MT2-commit. W40 (F4b(b) per kamer als rapportwaarde). §0 en de slotregel van §6 bijgewerkt |
| 0.1.1 | 2026-11-13 | Na Lead-review EP (#273): GM-a–GM-d in de rij Boss (§3) en in co-op in MT3 (§4); route-tijd zonder pauzemenu, tussenscènes en minibaas-arena's (§2.2, W38); open punt 8–12 min naast W36; E-1 bij de start van Q-4 |
| 0.1 | 2026-11-13 | Eerste versie (#88): F4-metingen en F4b(b) per kamer S1–S9 en de boss, solo en co-op; wat de bestaande tests en `mt2-meetlogs/` dekken (cijfers uit `kadewijk.md` §6–§6d en `testplan-mt2.md` §2.2/§2.4, niet opnieuw gedraaid); wat ontbreekt met eigenaar (G-1–G-5, Q-1–Q-5, W-1, E-1); MT2 verwezen, MT3 te maken; W36–W39 |
