# Testplan MT2: mijlpaaltest Kadewijk S1–S9 met de Gemaalmeester (T11, F4, F4b(a) solo)

Versie 0.1.7 · 2026-11-14 · Eigenaar: QA Lead (met Lead Game Designer) · Issue: [#250](https://github.com/cesarvangerwen-glitch/echoborn/issues/250) (deel van T11, [#88](https://github.com/cesarvangerwen-glitch/echoborn/issues/88)) · Lead-review: Executive Producer

Basis: fasekader v0.4 (`docs/productie/fase-2-kader.md`: §3 F4 en F4b, §4 mijlpaaltest MT2, regel tegen weggooiwerk, T11); besluiten van 2026-11-12 in `docs/beslissingen.md` (D = 60 als werkaanname, fase 2 parallel, **de CEO test alleen bij mijlpalen**, kaart ± 10–15 min); kamerdoc `docs/design/kamers/kadewijk.md` v0.4.4 (§3–§9); `docs/design/gemaalmeester.md` v0.2.2 §8 (GM-a–GM-d); `docs/design/combat/slice-vijanden-en-boss.md` v0.1.4 (§2.6, open punt 15); gdd §3.5 (V-01) en **§5.1** (grens F4b(b)); `docs/audio/bible.md` §9.4 (luistercheck F2); `docs/art/slice-kadewijk.md` §9.7; testplan MT1 v0.1.3 (`docs/qa/testplan-mt1.md`, W25–W30).

Kaart voor de CEO: `docs/qa/ceo-kaart-mt2.md`. Rapport (na de sessie): `docs/qa/rapport-mt2.md`. Meetlogs en scripts van QA: `docs/qa/mt2-meetlogs/` (kopie van de tooling in `docs/qa/mt1-meetlogs/`, §4.4).

## 0. Wanneer MT2 start

**MT2 start pas na MT1.** MT1 (flow-kamer, F0 norm (3)) ligt bij de CEO ([#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80)) en wacht op zijn sessie. De Producer plant MT2 pas als:

1. **MT1 is gespeeld en het rapport MT1 is gemergd** (`docs/qa/rapport-mt1.md`), met een oordeel over F0. Volgt uit MT1 een herontwerp dat de echo of een kernregel raakt, dan geldt eerst de stopregel van fasekader §4 voor de geraakte kamers; MT2 wacht tot die weer maatvast zijn.
2. **Alle voorwaarden van §2 zijn ✅** (bots groen en een merkbare stap, fasekader §4).

De samenvoegregel van fasekader §4 ("valt een mijlpaal samen met de volgende, dan is het één kaart") gebruiken we hier niet: MT1 ligt al bij de CEO op een eigen build (`d9f420c`) en een eigen kaart. Zo blijft MT1 een zuivere meting van de flow-kamer en hoeft de CEO niets opnieuw te lezen.

## 1. Wat MT2 toetst

MT2 is de tweede mijlpaaltest: de CEO speelt de **Kadewijk van begin tot eind, solo**, op D = 60, met de Gemaalmeester in S8 en de lus door S9 terug naar S1. Hij speelt hem **voor het eerst**. MT2 levert:

1. **F4b(a) solo**: klikmoment van de kernfantasie (ja/nee, waar), wil doorspelen (ja/nee), de echo als bondgenoot of trucje.
2. **F4 bij een mens, solo**: de normen (1)–(3) van P1 in de slice (MP-1, MP-2 per kamer, MP-5), echo ≤ 40 % Leeg (MP-4), MP-3, MP-6. De bots tonen dat de slice het *kán* (§2), MT2 meet of de CEO het *doet*.
3. **F4b(b) solo** (gdd §5.1): de echo ook buiten de boss-arena, uit het meetlog. Een eerste meting; het oordeel F4b(b) vraagt ook co-op (MT3).
4. **De Gemaalmeester** (gemaalmeester.md §8): GM-a (schot), GM-b (springplank in fase 2), GM-c (finisher), GM-d (stilstand); V-01 (gdd §3.5: stuit per gevecht).
5. **Zes meetvragen uit de reviews** (§1.1).
6. **Luistercheck F2** (audio bible §9.4): drie ja/nee-vragen op het F2-fragment, **alleen op koptelefoon, ± 2 min** (EP-besluit, [Lead-review PR #251](https://github.com/cesarvangerwen-glitch/echoborn/pull/251#issuecomment-6842638354); de bible volgt in #249). Afgesproken op de kaart van MT2 (EP, PR #199), geen aparte sessie; niet naar MT3, want F2 is een voorwaarde voor T8d deel 2.

Het overkoepelende plan voor T11 (alle kamers en de boss, solo en co-op, met wat de bots al dekken en wat nog ontbreekt) is `docs/qa/testplan-t11-slice.md`; dit plan is het deel MT2.

Niet in MT2: co-op en P2 (MT3, F4b(c)); eindkwaliteit van art en audio als oordeel (MT3, F7); de sterke *Nine Sols*-check (F4b(c)); een tweede D (D = 90, 120 en 180 alleen als regressie in de bots).

### 1.1 De meetvragen uit de reviews

| # | Vraag | Bron | Wat QA meet (§4.3) | Op de kaart |
|---|---|---|---|---|
| RV-1 | **Hangen in de lucht boven de echo bij keren**: leest het als "erop vallen" of als wachten? Bot: S4 ± 10 ticks, S5 ± 25 ticks (tick 3531–3561) | CD, visie-review S4 ([#212](https://github.com/cesarvangerwen-glitch/echoborn/issues/212)) en S5 ([#227](https://github.com/cesarvangerwen-glitch/echoborn/issues/227); "MT1" daar = MT2, correctie van de CD) | uitkomst A–D per keerpunt in S4 en S5 (zoals MT1 §4.2); de hangtijd bij de bot per D (botlogs) | vraag 6 |
| RV-2 | **Stuiten spelers in S7**, of nemen ze de langzame lijn door het kanaal (449 tegen 430 ticks, 1,04×)? | afwijking 12, `kadewijk.md` §8 ("MT2 meet of spelers stuiten") | `STUIT` in S7 boven het kanaal, ontploffingen door de echo, of de bodem van het kanaal | vraag 8 |
| RV-3 | **Verveelt de herhaling in S5** (vier keer keren, geen gevecht)? | besluit 3 LGD bij de visie-review (#227); slice-vijanden §2.6 rij S5 | kamertijd S5 tegen de bot (1304 ticks), A–D per verdieping, MP-1 in S5 | vraag 7 |
| RV-4 | **De lege loop na golf 2 in S3**: 540 ticks (9,0 s) van de laatste ontploffing in S3 tot de lancering in S4 | CD (#212), `kadewijk.md` §6b; slice-vijanden open punt 15 ("punt voor de Combat Designer na MT2") | het gat zonder echo-actie van de laatste `ONTPLOFFING` in S3 tot de volgende echo-actie | vraag 9 |
| RV-5 | **Leesbaarheid van de echo in kleur vóór een verlicht raam** (S3; ΔL\* 35 tegen ≥ 40) | AD, `slice-kadewijk.md` §9.7 | alleen de kaart (beeld, niet in het log); alleen als de build de kleurtoestand van S3 toont (§2.1, V-9) | vraag 13 |
| RV-6 | **De wandeling na trap 2** (de trap af en de kade naar de pijler, ± 20 s zonder echo-moment bij de bot): beloning of leeg lopen? | B-1 (§2.4), [besluit LGD in #83](https://github.com/cesarvangerwen-glitch/echoborn/issues/83#issuecomment-6845655429) | ticks van de laatste `POMP` van de echo bij trap 2 tot de eerste echo-actie in S9 (`rekenen.gd`) | vraag 9b |

## 2. Voorwaarden vóór de sessie

De Producer geeft de CEO de kaart pas als alle regels hieronder ✅ zijn. Ontbreekt er iets, dan meldt QA in #250 wat ontbreekt en wie aan zet is. **Zo niet groen: geen sessie** (fasekader §4 en §5).

### 2.1 Slice klaar voor een mens

| # | Voorwaarde | Waarom | Wie | Stand |
|---|---|---|---|---|
| V-1 | **MT1 gespeeld, rapport MT1 gemergd** (§0) | MT2 start na MT1 | QA, CEO | ☐ wacht op de CEO (#80) |
| V-2 | **S8 maatvast**: (a) `Visie-review: past` van de CD op S8 met de Gemaalmeester ([#247](https://github.com/cesarvangerwen-glitch/echoborn/issues/247), contactbladen PR #248) ✅; (b) **de lengte van de boss** volgens de norm van de LGD (#247): scripted solo-run bij D = 60 **95–150 s**, **fase 2 ≤ ± 65 s**, fase 1 ≥ 24 s ✅ via PR [#253](https://github.com/cesarvangerwen-glitch/echoborn/pull/253): 97,9 s, fase 1 28,4 s, fase 2 63,5 s (10 kanten), hard getest; (c) **een vaste arena-camera** van `BOSS_START` tot `BOSS_VERSLAGEN`, ook na een respawn ✅ via #253 (`arena_view()`, getest); (d) de LGD verklaart S8 maatvast ✅ ([comment in #83](https://github.com/cesarvangerwen-glitch/echoborn/issues/83#issuecomment-6844964137)) | Fasekader §4 regel 3. Zonder (b) en (c) speelt de CEO de oude lengte en verliest hij het rad uit beeld | CD, LGD, Combat Designer, GP | ✅ |
| V-3 | **S9 maatvast**: (a) her-review van de doorloop van S9 door de CD: `Visie-review: past` ✅ ([comment in #227](https://github.com/cesarvangerwen-glitch/echoborn/issues/227), na #239); (b) de LGD verklaart S9 maatvast ✅ ([comment in #83](https://github.com/cesarvangerwen-glitch/echoborn/issues/83#issuecomment-6844964137)) | Fasekader §4 regel 3 | CD, LGD | ✅ |
| V-4 | **Alle kamers gekoppeld**: één doorloop **S1 → S8 → S9 → S1** in één scène, zonder F8: de boss opent `DeurLinks`, trap 2 (`s = 2`) opent het `Hoogwater` van S9, de run eindigt op `SLICE_EIND` (`RUN_END_LUS`); de echo breekt 0× bij elke D | `kadewijk.md` §6d | GP (T8a, #83), WLD | ✅ via PR [#252](https://github.com/cesarvangerwen-glitch/echoborn/pull/252) (trap 2, `SLICE_EIND`, de lus als bot-test) en PR [#254](https://github.com/cesarvangerwen-glitch/echoborn/pull/254) (S6 en S9 buren: **0 echo-breuken bij D = 60, 120 en 180**, hard in `test_kadewijk_lus.gd`) |
| V-5 | **Start voor de CEO**: tot MT1 klaar is blijft F5 de flow-kamer (MT1 ligt nog bij de CEO). De Kadewijk start apart: **`res://levels/kadewijk/kadewijk.tscn` openen in *FileSystem* en F6** (*Huidige scène afspelen*), niet F5; in S1, D = 60 uit data, echo aan, HUD met kamer, D en echo-toestand (`docs/tools/kadewijk-meetlog.md` §1). Na MT1 mag de hoofdscène om (besluit TD of Producer); dan wordt het weer F5 op de kaart | MT1-start ongewijzigd (`test_mt1_start_ongewijzigd`) | Tools Programmer | ✅ via PR [#257](https://github.com/cesarvangerwen-glitch/echoborn/pull/257) (`f18dff2`) |
| V-6 | **Meetlog naar schijf**: bij `RUN_EIND` en bij afbreken (F6, F4, een D-toets, het venster dicht) een CSV `meetlog_<JJJJMMDD-uummss>_kadewijk_solo_D60_p1.csv` (afgebroken: `_afgebroken`) in `%APPDATA%\godot\app_userdata\Echoborn`, met de kolommen van de flow-kamer; standaard aan als de Kadewijk de scène van de run is. **Let op:** de stopknop van de editor (■) beëindigt het spel zonder melding en geeft **geen CSV**; de kaart laat de CEO daarom het **spelvenster** sluiten (kruisje of Alt+F4) | Zonder CSV geen meting | Tools Programmer | ✅ via PR [#257](https://github.com/cesarvangerwen-glitch/echoborn/pull/257) (`f18dff2`) |
| V-7 | **Geen valkuil-toetsen**: F8, de D-toetsen en F4 loggen eerst een regel `DEBUG` (waarde de toets, bron de kamer, de nieuwe D of `echo_uit`/`echo_aan`), zodat QA een run met een sprong herkent | De kaart verbiedt ze, maar een misdruk moet zichtbaar zijn | Tools Programmer | ✅ via PR [#257](https://github.com/cesarvangerwen-glitch/echoborn/pull/257) (`f18dff2`) |
| V-8 | **Respawn werkt in elke kamer** en kost geen vastloper: bij 0 levenspunten terug op het checkpoint (S1, na de eerste pompslag S6), `RESPAWN` in het log | GM-11, SL-03 | GP | ✅ in code en tests (`kadewijk.md` §5, §3e); controle in de doorloop van V-10 |
| V-9 | **Kleurtoestand van S3** (voor RV-5): de verlichte wijk met de verlichte ramen in kleur in de build, en de echo in zijn eindweergave (rand + buitencontour, F-07/S-10) | Zonder kleur is RV-5 niet te vragen | TA, AD | ☐ **geen harde voorwaarde**: ontbreekt het, dan schrapt QA vraag 13 en schuift RV-5 naar MT3 |
| V-10 | **Luistercheck klaar**: het luisterfragment voor MT2, `docs/audio/luistercheck-mt2/luistercheck_mt2_placeholder.ogg` (66,6 s; 0,0–15,5 s is het F2-fragment v2 sample voor sample, daarna L1–L3 per vraag naast elkaar) staat op `main` (PR [#260](https://github.com/cesarvangerwen-glitch/echoborn/pull/260)), met de link in de kaart §4 | Audio bible §9.4 | Composer/Sound Designer, Audio Director | ✅ via #260; link in de kaart, vast op `85c6650` |

### 2.2 Bots groen op de build

Gedraaid door QA op de build van §2.3, met de suite (`godot --headless --path game --fixed-fps 60 -s res://tests/run_tests.gd`) en `docs/qa/mt2-meetlogs/botlogs.gd` (§4.4). Grenzen uit `kadewijk.md` §6–§6c, gemaalmeester.md §7–§8 en gdd §5.1; de bot-waarden staan erbij voor zover ze al gemeten zijn.

| # | Wat | Grens | Bot op `main` nu (D = 60) | ✅ |
|---|---|---|---|---|
| 1 | **Gescripte lus S1 → S8 → S9 → S1** met de boss (`kadewijk_bot.gd` + `boss_bot.gd`), `RUN_EIND` op `SLICE_EIND` | loopt zonder dood en zonder F8; echo breekt 0× (besluit 1 LGD, #227; besluit 4 in #252) | 15 504 ticks (258,4 s), 0 echo-breuken bij 60/120/180, 1 treffer, 0 respawns, alles opgepakt (`kadewijk.md` §6d) | ✅ |
| 2 | MP-1 per kamer | ≤ 300 ticks | lus: langste 56 (de arena), dus elke kamer ≤ 300 | ✅ |
| 3 | MP-2 per kamer, en het langste gat | ≥ 3,0 per min in elke kamer; gat ≤ 40 s (de MT2-norm, fasekader §3) | lus D = 60: per kamer S1 6,3 · S2 10,4 · S3 15,3 · S4 14,4 · S5 9,9 · **S6 3,5** · S7 16,7 · S8 27,2 · S9 5,2; langste gat **2101 ticks (35,0 s)** | ✅ voor de MT2-norm. **B-1: bevinding** (rustpunt na de boss), **geen voorwaarde** (EP, [Lead-review #261](https://github.com/cesarvangerwen-glitch/echoborn/pull/261#issuecomment-6845616031)) |
| 4 | MP-3, MP-4, MP-6 | ≥ 75 % / ≤ 40 % / ≥ 40 % | lus D = 60: **76 %** van 29 landingen (de 7 met stilstand alle in S8 fase 1; op de route 100 %) / 0,4 % / 71 % van 643 LP, 8 pompslagen van de echo | ✅ (MP-3 krap, §2.4) |
| 5 | SL-01 en het gemaal | ≥ 100 LP vóór de eerste pompslag; gemaal vol op de eerste doorgang | 112 LP; ✓ | ✅ |
| 6 | Gemaal → arena-deur | ≤ 10 s (SL-03, GM-11) | 555 ticks (9,2 s) | ✅ |
| 7 | De Gemaalmeester solo | verslagen zonder dood in **95–150 s, fase 2 ≤ 65 s, fase 1 ≥ 24 s** (V-2); MP-1 ≤ 300; schot gebroken, rad met een bounce geraakt | 97,9 s (fase 1 28,4, fase 2 63,5 s), realistische speler 109,3 s, beginner 121,2 s; in de lus 97,6 s (PR #253) | ✅ |
| 8 | Zonder echo (C-15, FK-2) | ≤ 2×, ≤ 4 keer terug voor licht | S1 → S7 1,90×, 4×; S9 1,07× | ✅ (krap: marge 479 ticks) |
| 9 | **F4b(b) op de bot** (gdd §5.1), route-tijd zonder de arena | ≥ 2,0 echo-acties/min; springplank ≥ 1,0/min én ontploffingen door de echo ≥ 0,5/min; ≥ 30 % LP met de echo | lus D = 60, route-tijd 160,8 s: 8,2 / 4,1 en 4,9 / 78 % van 175 LP; bij 90 / 120 / 180 ook positief | ✅ |
| 10 | **Hangtijd bij keren** (RV-1), per keerpunt in S1, S2, S4, S5, S9 | geen grens (meting); bij de bot ter vergelijking voor §4.3 | D = 60: **elk keerpunt 9–10 ticks** in de lucht boven de naderende echo (S4-B4 en S5-B2a–d gelijk), keren → plank 32 ticks, alle 11 uitkomst A; regressie §2.4 | ✅ (gemeten) |
| 11 | Suite | volledig groen, ook D = 90 / 120 / 180 als regressie | **437 geslaagd, 0 mislukt** (271,7 s) op `de037be`, Godot 4.6.3 headless | ✅ |
| 12 | Start, D en meetlog (V-5, V-6) | test: de build start de Kadewijk op D = 60; het meetlog schrijft een CSV met de naam van V-6 | `test_kadewijk_meetlog.gd` (PR #257): MT1-start ongewijzigd, D = 60 met echo aan, één CSV met de juiste naam en kop, `_afgebroken`, `DEBUG` | ✅ |

**Stand op `85c6650` (2026-11-13): groen op één voorwaarde na.** ✅: V-2–V-8 en V-10; bot-punten 1–12 (punt 3 met bevinding B-1, geen voorwaarde). Open: alleen **V-1** (MT1 wacht op de CEO, #80). V-9 is geen harde voorwaarde. Vóór de sessie vult QA nog de build-commit en de zip-link in (§2.3, kaart).

### 2.4 Uitkomst van de MT2-tooling op de lus (QA, `de037be`)

Gedraaid met `docs/qa/mt2-meetlogs/botlogs.gd` (de lus zoals `test_kadewijk_lus.gd`, bij D = 60 en als regressie 90 / 120 / 180) en `rekenen.gd`. De lus-ticks zijn gelijk aan `kadewijk.md` §6d (15 504 bij D = 60). De CSV's staan niet in de repo (± 1 MB per hanglog); ze komen terug met de twee commando's van §4.4.

| | D = 60 | 90 | 120 | 180 |
|---|---|---|---|---|
| Run / boss | 258,4 s / 97,5 s | 254,1 / 93,1 | 256,5 / 91,5 | 280,6 / 107,4 |
| MP-1 / MP-3 / MP-4 / MP-6 | 56 / 76 % / 0,4 % / 71 % | 59 / 88 % / 0,6 % / 73 % | 92 / 96 % / 0,8 % / 69 % | 56 / 88 % / 1,1 % / 71 % |
| Laagste MP-2 per kamer | S6 3,5 | S6 3,5 | S6 3,5 | **S7 0,0** (alleen 3 stuits, geen ontploffing) |
| Langste gat | 2101 (35,0 s) | 2100 | 2129 | 2161 (36,0 s) |
| S9 na de trap af: rustpunt / grootste gat daarna | **932** / 597 | **943** / 590 | **958** / 591 | **988** / 597 |
| Na trap 2: laatste pompslag van de echo → eerste echo-actie in S9 (B-1, met `POMP` van de echo, LGD) | **1202 (20,0 s)** | 1183 | 1168 | 1138 |
| F4b(b) (1) / (2) / (3) | 8,2 / 4,1 · 4,9 / 78 % | 8,6 / 4,5 · 5,2 / 80 % | 8,4 / 4,4 · 5,1 / 79 % | 8,3 / 4,2 · 4,9 / 79 % |
| RV-2 S7: stuits boven het kanaal / ontploffingen | 2 / 2 | 2 / 2 | 2 / 1 | 2 / 0 |
| RV-4 lege loop S3 → S4 | 539 (9,0 s) | 535 | **638** (10,6 s) | **727** (12,1 s) |
| RV-1 hangen: S4-B4 / S5-B2 / overige keerpunten | **9–10** / **9–10** / 8–9 | 30 / 1 / 1 | 30 / 1 / 1 | 30 / 1 en 17 / 0–17 |

**Lezing.** RV-1: bij D = 60 hangt de bot op **elk** keerpunt ± 10 ticks (0,17 s) in de lucht, recht boven de echo die onder hem door komt: hij laat na de top de richting los en valt erop. Dat is de ± 10 van de CD in S4; de ± 25 in S5 komt niet terug (de CD telde op de contactbladen ook het stijgen mee, tick 3531–3561 is de hele sprong van 32 ticks). Bij D ≥ 90 hangt hij in S4 30 ticks (de variant "dragen", `kadewijk.md` §3a). Of dat bij een mens leest als "erop vallen" of als wachten, is vraag 6. S2-B3 is bij D ≥ 90 geen keerpunt (een blok), zo bedoeld. RV-4 is bij D = 60 binnen de 600 ticks; bij 120 en 180 erboven (alleen regressie).

**Bevindingen** (gemeld in [#83](https://github.com/cesarvangerwen-glitch/echoborn/issues/83)):

| # | Bevinding | Ernst | Voor |
|---|---|---|---|
| B-1 | **Na de boss in de lus geen rustpunt ≤ 12 s.** Van `BOSS_VERSLAGEN` (11 175) tot de eerste echo-actie in S9 (B2a, 13 156) zit 1981 ticks (33 s) zonder MP-2-actie: de deur uit, de trap op, trap 2 pompen, de trap af en 932 ticks over de kade naar de pijler. **Besluit LGD** ([besluit LGD in #83](https://github.com/cesarvangerwen-glitch/echoborn/issues/83#issuecomment-6845655429)): voor de gaten en het rustpunt telt een `POMP` van de echo als echo-moment (voor MP-2 niet); dan blijft **± 20 s** (1202 ticks bij D = 60) van de laatste pompslag van de echo bij trap 2 tot B2a in S9. Geen ombouw vóór MT2: de kaart vraagt het (vraag 9b, RV-6), QA meet het gat. Is het in MT2 "leeg", dan kiest de WLD de goedkoopste ingreep (een echo-moment op of onder de trap terug); S9 blijft maatvast tot er een herontwerp is. **Geen MT2-voorwaarde** (EP, Lead-review #261) | bevinding, geen blocker | LGD (besloten), WLD (na MT2, en een `note` in `test_kadewijk_lus.gd`) |
| B-2 | **MP-3 76 %, krap op 75 %**: de 7 landingen met stilstand liggen alle in S8 fase 1 (de boss-bot wacht ≥ 20 ticks op het schot); op de route 100 %. Een CEO die in fase 1 ook wacht, kan MP-3 missen door de boss | info | Combat Designer |
| B-3 | **S6 MP-2 3,5 per min**, bij elke D de krapste kamer (de pompgang telt niet in MP-2) | info | LGD |
| B-4 | Regressie D = 180: S7 MP-2 0,0 (de merken in het kanaal knallen niet meer); D = 120/180: RV-4 > 600 | info, alleen bij een andere D | Combat Designer, LGD |

### 2.3 Build

| Wat | Waarde |
|---|---|
| Build | `main` op commit *in te vullen* (na V-1–V-7) |
| Zip voor de CEO | *in te vullen* (`…/archive/<commit>.zip`, ook in de kaart) |
| Standaard-D | D = 60 uit data (`game/data/echo_v04.json`, `echo.tail_ticks`) |
| HUD | *in te vullen*: de regels van `HUD_STATUS` en `HUD_ROOM` (LP, gemaal, levens; kamer, D, echo-toestand, tijd) |
| Meetlog | `meetlog_<datum-tijd>_kadewijk_solo_D60_p1.csv` in `%APPDATA%\godot\app_userdata\Echoborn` (V-6) |
| Keerwanden (voor §4.2) | uit `kadewijk_layout.gd`, *in te vullen* in `rekenen.gd`: S1-B1 (x 20), S2-B3 (x 1250), S2-B1 (pijler x 700), S4-B4 (bolder x 2892), S5-B2a–d (x 3600 / 4080), S9-B2a/b (pijler), S9-B1 (x 20) |

## 3. Normen (solo, D = 60)

Zoals MT1 (gdd §4.5), nu over **één doorloop** van de hele slice, per kamer. De doorloop is de eerste keer dat de CEO de Kadewijk speelt: een oefenrun is er niet (W31).

| Norm | Maat | Gehaald als | Opmerking |
|---|---|---|---|
| (1) nergens > ± 5 s stil | MP-1 | langste stilstand in elke kamer ≤ 300 ticks; 301–360 grensgeval (LGD bekijkt de plek); > 360 niet gehaald | De 60 ticks na een `RESPAWN` tellen niet (meetlog) |
| (2) echo als springplank of merk-afmaker ≥ ± 1× per 20 s | MP-2 | ≥ 3,0 per min **in elke kamer**; geen gat > 40 s | In S8 telt de boss mee (de normen van P1 gelden ook in het gevecht) |
| (3) "vloeiend/satisfying" ≥ 4 op 5 | MP-5 | gemiddelde over de vier delen ≥ 4,0 en geen deel < 3,0 (W32) | Vier delen: S1–S4, S5–S7, S8, S9 |
| Echo ≤ 40 % Leeg | MP-4 | over de doorloop en per kamer ≤ 40 % | R12 |
| De echo loont | MP-6 | ≥ 40 % van de LP met de echo, ≥ 1 pompslag van de echo | — |
| Springplank vóór je | MP-3 | ≥ 75 % van de landingen zonder stilstand | — |
| F4b(b) solo | gdd §5.1 | de drie grenzen (§2.2 punt 9) | **Eerste meting**: F4b(b) is pas positief met co-op erbij (MT3) |
| *Nine Sols* (zwak signaal) | M1 | niet genoemd (vraag 12) | Zwak: de CEO kent de referenties |

**Wat MT2 niet scherp kan:** één speler, één doorloop, de eerste keer. MP-2 en MP-3 bij een eerste doorloop zijn een ondergrens van wat een geoefende speler haalt; de normen (1) en (2) zijn voor een geoefende speler bedoeld (gdd §4.5). QA rapporteert daarom per kamer naast de bot, en noemt een kamer onder de norm een **bevinding met plek**, geen no-go op zichzelf (§6).

## 4. Wat QA uit de logs rekent

Alles uit de CSV's van de CEO met `docs/qa/mt2-meetlogs/rekenen.gd` (§4.4). Geen nieuwe events nodig behalve `DEBUG` (V-7): alles uit `RUN_START`, `KAMER`, `SPRINGPLANK`, `BOUNCE`, `LANCERING`, `VANGEN`, `STUIT`, `STIL_*`, `MERK_GEZET`, `MERKSPRONG`, `ONTPLOFFING`, `LP`, `POMP`, `GEMAAL_VOL`, `LUIK`, `LAMPGLAS`, `LOGBLAD`, `RESPAWN`, `BREEK`, `ECHO_LEEG_*`, de boss-events (B-10), `SLICE_EIND`, `RUN_EIND` en `x, y`.

### 4.1 Per kamer en over de doorloop

| Maat | Wat QA rapporteert |
|---|---|
| Tijd | per kamer en totaal, naast de bot (S1–S4 2963, S5 1304, S6 503, S7 430, S8 7758, S9 3004 ticks); **verdwaalpunten**: een kamer > 3× de bot, met de plek van de langste stilstand |
| MP-1 | langste stilstand per kamer met `x, y` |
| MP-2 | per min per kamer; langste gat met begin en eind |
| MP-3, MP-4, MP-6 | zoals MT1 |
| Echo-acties per soort en per kamer | bounce, lancering, vang, stuit, merksprong, ontploffing door de echo (pitch §5: "per wijk welke echo-acties de speler gebruikt"; tabel voor de LGD) |
| Doden | `RESPAWN` per kamer met de plek (doodsoorzaken voor `playtest`-rapport, rol QA); in S8 per fase |
| F4b(b) | route-tijd = van `RUN_START` tot `RUN_EIND` zonder `BOSS_START` … `BOSS_VERSLAGEN`; de drie grenzen van gdd §5.1, en per kamer |
| Echo breekt | elke `BREEK` met plek (verwacht 0, besluit 1 LGD) |
| Debug | elke `DEBUG`-regel (V-7): de run telt dan vanaf die plek niet meer voor MP-1–MP-3 |

### 4.2 Keren per keerpunt (A–D)

Zoals MT1 §4.2 en W26, nu per keerpunt van de slice: **S1-B1, S2-B3, S2-B1, S4-B4 (bolder), S5-B2a–d, S9-B2a, S9-B2b, S9-B1** (11 keerpunten). Uitkomst A (echolijn zonder stilstand), B (echolijn na wachten, met de plek), C (bij de wand gewacht), D (langzame lijn). In S4 is de "echolijn" de **lancering** van de bolder; D is de kloof in.

### 4.3 De meetvragen uit de reviews

| # | Meting uit het log | Ter vergelijking | Leest QA als |
|---|---|---|---|
| RV-1 hangen | per keerpunt in S4 en S5 de uitkomst A–D en de stilstand vóór de landing; **de hangtijd zelf staat niet in het meetlog** (geen afzet-event): die meet QA alleen bij de bot (§2.2 punt 10). Optioneel (O-1): een event `AFZET` van P1, dan rekent QA afzet → `SPRINGPLANK`/`LANCERING` ook bij de CEO | bot: S4 ± 10, S5 ± 25 ticks | Vraag 6 = B of C **en** A in S4/S5 = "het leest als wachten": bevinding voor de LGD en CD (geometrie of timing, met de bots). A + vraag 6 = A: "erop vallen" bevestigd |
| RV-2 stuiten S7 | `STUIT` met x in 4960–5120 (het kanaal) en de `ONTPLOFFING`en door de echo daarna; of het kanaal via de bodem (een `STIL_*` of positie op y > 620 tussen x 4960 en 5120, of geen `STUIT` vóór de deur) | bot: 2 stuits boven het kanaal, 2 ontploffingen | 0 stuits = de langzame lijn; met vraag 8 = C ("geprobeerd, mislukt"): bevinding voor de Combat Designer (Dwaallicht-baan) |
| RV-3 S5 | kamertijd S5 tegen 1304; A–D voor B2a–d; MP-1 en MP-2 in S5 | bot 1304 ticks, 4 × A | vraag 7 = C ("te lang, saai"): bevinding voor de LGD en CD (besluit 3 opnieuw: variatie, niet per se een vijand) |
| RV-4 lege loop | ticks van de laatste `ONTPLOFFING` in S3 tot de volgende echo-actie (S4) | bot 540 (9,0 s) | > 600 ticks (± 10 s) **of** vraag 9 = B: punt 15 voor de Combat Designer (de Kadeloper naar het begin van de aanloop, of de aanloop korter) |
| RV-5 raam | niets uit het log; alleen vraag 13 (als V-9 ✅) | AD: ΔL\* 35 tegen ≥ 40 | vraag 13 = B of C: de buitencontour van 1 px in kleur voor de TA (F-07/S-10) |
| RV-6 na trap 2 | ticks van de laatste `POMP` van de echo bij trap 2 tot de eerste echo-actie in S9; gaten en rustpunt met `POMP` van de echo als echo-moment (LGD, B-1) | bot 1202 (20,0 s) | vraag 9b = B ("leeg lopen"): de WLD kiest een echo-moment op of onder de trap terug (LGD, #83). A = beloning: zo laten. Pompte de echo bij trap 2 niet (echo Leeg of gebroken), dan rekent QA vanaf de laatste `POMP` van P1 en zegt dat erbij (`rekenen.gd` doet dat nog niet, T11 §6 punt Q-2) |

### 4.4 Tooling (`docs/qa/mt2-meetlogs/`)

Kopieën van de MT1-scripts, die zelf ongewijzigd blijven voor het rapport MT1:

- **`rekenen.gd`** (van `mt1-meetlogs/rekenen.gd`): de rekenregels van MT1 (MP-1–MP-6, A–D met W26, stilstand met plek) blijven; anders: (a) kamers S1–S9 in plaats van K1–K3, met de keerpunten van §4.2 uit `kadewijk_layout.gd`; (b) geen `SCORE`-regels (de scores komen uit de antwoorden, W32); (c) de maten van §4.1 en §4.3 (echo-acties per soort, F4b(b) met route-tijd, RV-1–RV-4, doden, `BREEK`, `DEBUG`); (d) geen oefenrun (W31).
- **`botlogs.gd`** (van `mt1-meetlogs/botlogs.gd`): loopt de gescripte lus (`kadewijk_bot.gd` met `lus`, in S8 `boss_bot.gd`, zoals `test_kadewijk_lus.gd`) bij D = 60 en, als regressie, 90 / 120 / 180, en schrijft per D `bot_lus_D<D>.csv` (het meetlog) en `hang_lus_D<D>.csv` (per tick `tick,kamer,x,y,vx,vy,vloer,echo,ex,ey` van P1 en de echo). Uit het hanglog telt `rekenen.gd` per keerpunt de hangtijd: de ticks tussen keren en de landing op de echo waarin P1 in de lucht is met |vx| ≤ 0,5 px/tick (W33). Zo wordt RV-1 een getal per D. Een lus zonder echo zit er niet in (de route zonder echo meet `kadewijk.md` §6b/§6c).
- **Draaien** (vanuit de root, ± 20 s + ± 5 s):
  `godot --headless --path game --fixed-fps 60 -s "$PWD/docs/qa/mt2-meetlogs/botlogs.gd" -- <map>` en daarna `godot --headless --path game -s "$PWD/docs/qa/mt2-meetlogs/rekenen.gd" -- <map>`. Voor de sessie: dezelfde `rekenen.gd` op de map met de CSV's van de CEO (`meetlog_*kadewijk*.csv`; zonder hanglog alleen A–D).
- **RV-6 zonder pompslag van de echo** (T11 Q-2, `testplan-t11-slice.md` W42): pompte de echo niet bij trap 2 (in de kamer van `TRAP_VOL 2`, bij dat bezoek), dan rekent `rekenen.gd` RV-6 vanaf de laatste `POMP` van P1 en zegt dat in de regel. Dezelfde `rekenen.gd` rekent ook co-op-meetlogs (T11 Q-3); de solo-uitvoer is daardoor niet veranderd.
- Getoetst: de lus-ticks van `botlogs.gd` zijn gelijk aan `kadewijk.md` §6d (15 504 / 15 392 / 16 838 bij D = 60 / 120 / 180), en `rekenen.gd` geeft de cijfers van §2.2 en §2.4.

## 5. Sessie met de CEO (solo, ± 15 min)

Draaiboek: `docs/qa/ceo-kaart-mt2.md`.

| Blok | Wat | Tijd |
|---|---|---|
| 0 | Zip uitpakken in een nieuwe map, oude meetlogs opzij, openen; HUD-check | ± 3 min |
| 1 | **Eén doorloop** S1 → S9 → S1 (van de proloogdeur tot terug op de gang van S1), op D = 60 | ± 6–8 min, stopregel ± 8 min (bot ± 4,3 min; zie onder) |
| 2 | 15 meerkeuzevragen (1–14 en 9b) in de Claude-chat (letters) | ± 2 min |
| 3 | Luistercheck F2: drie keer ja/nee, **alleen koptelefoon** | ± 2 min |
| 4 | Antwoorden en CSV's in de Claude-chat | ± 1 min |

**Tijd van de doorloop.** De bot doet de hele lus in 258 s (± 4,3 min; `kadewijk.md` §6d, met de kortere boss van #253). Een eerste doorloop van een mens raamt QA op ± 1,5–2× (de boss: realistische speler 109 s, beginner 121 s; PR #253), dus ± 6,5–8,5 min. **Stopregel op de kaart**: na ± 8 min spelen, of na 3 keer dood bij de boss, mag de CEO stoppen; de logs tot daar tellen (W31).

**Samen ± 15 min, hooguit ± 16**: 3 klaarzetten + 6–8 spelen (stopregel ± 8) + 2 vragen + 2 luisteren + 1 versturen (EP-besluit over de duur, Lead-review PR #251; stopregel van ± 10 naar ± 8 min na de SM-review van #251, zodat de som klopt en de kaart kort blijft).

**Data** (zoals MT1, W21): de CEO zet de antwoorden en alle CSV's in de **Claude-chat**; de agent die de chat verwerkt, zet ze in `docs/qa/mt2-meetlogs/` en in een comment in #250. Bijlagen in GitHub-comments zijn voor de agents niet te downloaden.

### 5.1 De vragen (kaart §3)

Alles **meerkeuze**, met letters (W34). Volgorde: eerst wat de kernfantasie en het gevoel raakt (1–5), dan de meetvragen (6–11), dan het merk (12), het raam (13) en wat er misging (14), zodat de meetvragen het eerste oordeel niet kleuren.

| # | Vraag (kort) | Opties | Bron | Hoe QA het leest |
|---|---|---|---|---|
| 1 | Wil je doorspelen? | A ja, graag · B ja · C maakt niet uit · D nee | F4b(a) | A/B = ja |
| 2 | Waar klikte het (de echo als jouw tweede lichaam)? | A kades S1–S2 · B markt S3 · C kloof S4 · D trappenhuis S5 · E gemaal S6 · F kelder S7 · G boss S8 · H lage kade S9 · I nergens | F4b(a) | I = nee; meerdere letters mag |
| 3 | De echo was voor jou meer… | A een bondgenoot · B soms bondgenoot, soms trucje · C een trucje · D weet niet | F4b(a) | A = bondgenoot |
| 4 | Je schaduw was… | A iemand die meedeed · B een spoor achter je aan · C allebei · D weet niet | R-V1 (pitch §10), zoals MT1 vraag R | A = "tweede lichaam"; signaal, geen exit-norm |
| 5 | Hoe vloeiend voelde het? 1–5 per deel: kades (S1–S4), huis-plein-kelder (S5–S7), boss (S8), lage kade (S9) | vier cijfers | MP-5 | norm (3), W32 |
| 6 | Bij het omdraaien (de bolder in S4, het trappenhuis in S5): op je echo springen… | A ging vanzelf, ik viel erop · B even in de lucht wachten, prima · C wachten in de lucht, stoorde · D niet gemerkt | RV-1 | §4.3 |
| 7 | Het trappenhuis (S5, vier keer omdraaien) was… | A een lekker ritme · B net goed · C te lang, saai · D weet ik niet meer | RV-3 | §4.3 |
| 8 | Over het kanaal in de kelder (S7) ging je… | A stuitend op de lichtjes · B door de bodem van het kanaal · C geprobeerd te stuiten, lukte niet · D weet ik niet meer | RV-2 | §4.3, naast het log |
| 9 | Na het tweede groepje vijanden op de markt (S3), tot de sprong over de kloof… | A prima, even rust · B te lang niets te doen · C niet gemerkt | RV-4 | §4.3 |
| 9b | Na het pompen van trap 2, de trap af en over de kade: voelde dat als… | A beloning · B leeg lopen · C niet gemerkt · D daar niet gekomen | RV-6, LGD (#83) | §4.3; naast het gat uit het meetlog |
| 10 | Hoe brak je het schot (de klep) van de boss? | A snapte het meteen · B na een tijdje · C per toeval · D niet gelukt | GM-a | naast de tijd `BOSS_START` → `SCHOT_BREUK` (≤ 60 s) |
| 11 | Bij de finisher (de laatste slagen) zag je vooral… | A mijn eigen slagen · B mijn echo die meesloeg · C een filmpje · D niet gehaald | GM-c | A of B = goed |
| 12 | Het merk (wat je met slaan op een vijand zet) deed je denken aan… | A nergens aan · B een ander spel: (naam) · C iets anders: (een paar woorden) | M1, O-8 | *Nine Sols* bij B = terug naar afwijkpunt 2 (gdd §2.13); zwak signaal |
| 13 | In de verlichte markt (S3), vóór een verlicht raam: je echo… | A goed te zien · B even kwijt · C kwijt · D geen verlichte markt gezien | RV-5 | alleen als V-9 ✅, anders geschrapt |
| 14 | Ging er iets mis? | A nee · B vast · C verkeerde toets · D iets raars: (een paar woorden) | zoals MT1 X | koppelt QA aan `_afgebroken`, `DEBUG` |

**Waarom M1 nu meerkeuze is.** In MT1 is M1 open gevraagd (W27), zodat "spontaan" sterk telde. In MT2 noemt de kaart geen enkel spel in de opties; B vraagt de naam. Dat blijft een zwak signaal (de CEO kent de referenties en kreeg M1 al in MT1); de sterke check blijft F4b(c) met een P2 (fasekader §3).

## 6. Oordeel en gevolgen

Het rapport noemt bij elk oordeel hoeveel het draagt: één speler, één doorloop, de eerste keer.

| Uitkomst | QA-advies en gevolg |
|---|---|
| Vraag 1 = A/B, vraag 2 ≠ I, vraag 3 = A; MP-5 ≥ 4,0 en geen deel < 3,0; MP-1 ≤ 300 in elke kamer; MP-4 ≤ 40 %; geen `BREEK` | **F4b(a) solo positief, F4 solo bij een mens bevestigd.** Op naar T8c/T8d op de maatvaste kamers en MT3 (solo én co-op). De meetvragen RV-1–RV-6 gaan als bevindingen naar hun eigenaar (§4.3) |
| F4b(a) solo negatief (vraag 1 = C/D, of 2 = I, of 3 = C) | **Geen go voor MT3 op deze basis.** QA zet de plek en de oorzaak (§4.1–§4.3) op een rij; de CD en LGD stellen een herzien voorstel op (fasekader F4b: "anders geen gate maar een herzien voorstel"). Raakt het de echo of een kernregel: stopregel voor eindkwaliteit op de geraakte kamers (fasekader §4). Of er een extra mijlpaaltest komt, beslist de EP |
| MP-5 < 4,0 of een deel < 3,0, de rest positief | **Geen go op norm (3).** De LGD stelt per deel een aanpassing voor, getest met de bots; de CEO speelt het in MT3 |
| Een kamer met MP-1 > 300 of MP-2 < 3,0, of een verdwaalpunt (> 3× de bot) | **Bevinding met plek** voor de WLD/LGD, aanpassing met de bots, zonder CEO. Geen no-go op zichzelf (§3, eerste doorloop); wel als het de kamer van een *klikmoment* tegenspreekt of in meer dan twee kamers gebeurt |
| MP-4 > 40 %, of een `BREEK` | Bevinding voor de LGD en GP (R12, E-08); aanpassing met de bots |
| F4b(b) solo onder een grens | **Signaal**, nog geen oordeel (F4b(b) vraagt beide modi): de waarden per kamer naar de LGD; telt mee in MT3 |
| GM-a > 60 s of vraag 10 = C/D; GM-b < 2 per min; vraag 11 = C | Bevinding voor de Combat Designer en GP (T8b), met de boss-events per fase |
| RV-1–RV-6 | Zoals §4.3: naar LGD, CD, Combat Designer, WLD of TA; geen invloed op go/no-go, behalve als de CEO het zelf noemt bij vraag 14 of het klikmoment erop stuk loopt |
| *Nine Sols* bij vraag 12 | Terug naar afwijkpunt 2 (gdd §2.13); LGD en Combat Designer |
| Luistercheck: drie keer ja | F2: de luisterhelft gehaald (samen met SM-Kwaliteit ≥ 7, bible §0) |
| Luistercheck: een nee | Bible §9.3: vraag 1 → klokken, 2 → `echo_versie`, 3 → water, harmonium, galm; de Audio Director opent zo nodig een `brainstorm` |
| Gestopt vóór S8 (stopregel) | Oordeel over de gespeelde kamers; S8 en S9 met de bots; de EP beslist of S8–S9 mee gaan in MT3 |
| Voorwaarden niet groen (§2) | Geen sessie; QA meldt in #250 wat ontbreekt en wie aan zet is |

## 7. Werkaannames (kader §5)

D = 60 is een CEO-besluit **als werkaanname** (nog niet gespeeld, `beslissingen.md`); de indeling MT1–MT3 is een werkaanname van de EP (fasekader §4). Uit MT1 blijven W8, W9 (D uit het log: `_D60_` en de eerste `ECHO_LEEG_EIND` op tick 60), W13, W16, W17, W18, W21, W22, W26 en W28. **Vervallen voor MT2**: W25 (oefenrun en getelde runs), W27 (alles open), W29 (scores uit het log), W30 (B3 als zesde keerpunt van K1). Nieuw:

| # | Aanname | Waarom |
|---|---|---|
| W31 | **Eén doorloop, geen oefenrun.** De eerste voltooide doorloop van `RUN_START` (S1) tot `RUN_EIND` (`SLICE_EIND`) telt, ook met doden. Stopt de CEO eerder (stopregel) of breekt hij af, dan telt de doorloop tot daar, per kamer. Een tweede doorloop vraagt de kaart niet | Besluit 2026-11-12 (2): ± 10–15 min; een eerste doorloop is wat F4b(a) vraagt (klikmoment, doorspelen) |
| W32 | **MP-5 in vier delen** (S1–S4, S5–S7, S8, S9), gevraagd in de chat na de doorloop, niet per kamer in het spel. Norm (3): gemiddelde ≥ 4,0, geen deel < 3,0 | Negen cijfers per kamer na één doorloop zijn te veel en te onnauwkeurig; de Kadewijk heeft (nog) geen scorescherm |
| W33 | **Hangtijd** (RV-1) = de ticks tussen het keren tegen de keerwand en de landing op de echo waarin P1 in de lucht is en horizontaal ≤ 0,5 px per tick beweegt. Alleen bij de bot gemeten (`botlogs.gd`); bij de CEO via uitkomst A–D en vraag 6 | Zo meet de CD het in de contactbladen (S4 ± 10, S5 ± 25 ticks); het meetlog heeft geen afzet-event |
| W34 | **Alle vragen meerkeuze**, met letters, behalve de naam bij 12 B en een paar woorden bij 12 C en 14 D | De CEO heeft weinig tijd; MT1 gebruikte open vragen voor de spontaniteit van M1 en R, die in MT2 al gemeten zijn |
| W35 | **Luistercheck op de MT2-kaart** (bible §9.4, EP in PR #199), ingekort tot **alleen koptelefoon, ± 2 min**, dezelfde drie vragen (EP, Lead-review PR #251; de bible volgt in #249). De tv-luidsprekers vallen weg | Geen aparte CEO-sessie (besluit 2026-11-12 (2)); F2 moet vóór MT3 (T8d deel 2), en zo blijft de kaart ± 15 min |

## 8. Open punten

| # | Wat | Wie |
|---|---|---|
| 1 | ~~**Duur van de kaart** ± 15–20 min door de luistercheck~~ **besloten** (EP, [Lead-review PR #251](https://github.com/cesarvangerwen-glitch/echoborn/pull/251#issuecomment-6842638354)): luistercheck blijft in MT2, alleen koptelefoon ± 2 min; stopregel ± 8 min (v0.1.2); kaart ± 15 min (W35) | executive-producer |
| 2 | ~~Voorwaarden V-4–V-7 als taak voor de GP~~ **gedaan**: V-4 via #252 en #254, V-5–V-7 en bot-punt 12 via #257 (`f18dff2`). Na MT1: hoofdscène naar de Kadewijk en de kaart terug naar F5 (besluit TD of Producer) | qa-lead, tools-programmer |
| 3 | ~~`docs/qa/mt2-meetlogs/rekenen.gd` en `botlogs.gd` (§4.4) maken en toetsen op de lus-bot~~ **gedaan** (v0.1.3, §2.4); B-1 ligt bij WLD en LGD (#83) | qa-lead |
| 4 | Event `AFZET` van P1 in het meetlog (O-1, §4.3): optioneel, zodat RV-1 ook bij de CEO een getal wordt | gameplay-programmer |
| 5 | Build-commit, zip-link, HUD-regels, keerwanden en de bot-cijfers van §2.2 invullen als V-1–V-7 ✅ zijn | qa-lead |
| 6 | Kleurtoestand van S3 (V-9): staat die er bij MT2 niet, dan vraag 13 schrappen en RV-5 naar MT3 | technical-artist, art-director |
| 7 | Eerste knop op de pijltjeskant maakt speler 1 (rapport F0 open punt 10): de kaart werkt eromheen, zoals MT1 | ux-designer, gameplay-programmer |

## Wijzigingen

| Versie | Datum | Wijziging |
|---|---|---|
| 0.1.7 | 2026-11-14 | §4.4: RV-6 vanaf de laatste `POMP` van P1 als de echo bij trap 2 niet pompte (T11 Q-2, [#88](https://github.com/cesarvangerwen-glitch/echoborn/issues/88)); `rekenen.gd` rekent ook co-op, solo-uitvoer ongewijzigd |
| 0.1.6 | 2026-11-13 | T11 ([#88](https://github.com/cesarvangerwen-glitch/echoborn/issues/88)): besluit LGD over B-1 nagelopen (vraag 9b en de meting staan sinds 0.1.4); telling naar zes meetvragen (§1), RV-6 ook in §6; RV-6 zonder pompslag van de echo vanaf de laatste `POMP` van P1 (§4.3); verwijzing naar `testplan-t11-slice.md` |
| 0.1.5 | 2026-11-13 | V-10 ✅ (luisterfragment op `main`, #260), link in de kaart §4; stand op `85c6650`: open alleen V-1 |
| 0.1.4 | 2026-11-13 | Na Lead-review EP (#261): bot-punt 3 ✅ voor de MT2-norm, B-1 bevinding en geen voorwaarde; besluit LGD over B-1 ([besluit LGD in #83](https://github.com/cesarvangerwen-glitch/echoborn/issues/83#issuecomment-6845655429)): `POMP` van de echo telt voor gaten en rustpunt (niet voor MP-2), `rekenen.gd` aangepast (na trap 2: 1202 ticks, 20,0 s); RV-6 en vraag 9b; V-10 met het luisterfragment uit PR #260 |
| 0.1.3 | 2026-11-13 | MT2-tooling gebouwd (`docs/qa/mt2-meetlogs/botlogs.gd`, `rekenen.gd`; MT1-scripts ongewijzigd) en gedraaid op de lus bij D = 60/90/120/180; suite 437/0. Bot-punten 4, 9, 10, 11 ✅, punt 3 ☐ (S9-rustpunt in de lus 932 > 720, B-1); §2.4 met de uitkomst, de hangtijd (D = 60: 9–10 ticks op elk keerpunt) en de bevindingen B-1–B-4; open punt 3 gesloten |
| 0.1.2 | 2026-11-13 | Stand bijgewerkt: V-2 (a)–(c) ✅ (CD past, boss 97,9 s / fase 2 63,5 s en vaste arena-camera via #253), V-3 (a) ✅ (CD past), V-4 ✅ (lus, 0 echo-breuken via #252/#254), bot-punten 1, 2, 7 ✅; V-5–V-7 naar PR #257 (start: `kadewijk.tscn` + F6 tot MT1 klaar is; spelvenster sluiten, niet de stopknop, anders geen CSV); stopregel ± 8 min, spelen ± 6–8 min (SM-review #251). Na Lead-review EP (#258): open punt 1 op ± 8 min; V-2 (d) en V-3 (b) ✅ (S8 en S9 maatvast, LGD in #83). Na SM-review #258: V-5–V-7 en bot-punt 12 ✅ via #257 (`f18dff2`), stand-regel op `f18dff2`, open punt 2 gesloten |
| 0.1.1 | 2026-11-13 | Na Lead-review EP (PR #251): luistercheck alleen koptelefoon ± 2 min, stopregel ± 10 min, sessie ± 15 min (§1, §5, W35), open punt 1 gesloten; V-2 met de lengte van de boss (95–150 s, fase 2 ≤ 65 s, #247) en de vaste arena-camera, bot-punt 7 daarop aangepast |
| 0.1 | 2026-11-13 | Eerste versie (#250, deel van T11 #88): start na MT1 (§0), voorwaarden V-1–V-10 (S8 en S9 maatvast, lus gekoppeld, start en meetlog voor de CEO, kleur voor RV-5, luistercheck) en de bot-punten op de lus (§2); normen per kamer over één doorloop (§3); meetvragen RV-1–RV-5 uit de reviews (§1.1, §4.3); tooling als kopie van `mt1-meetlogs/` (§4.4); 14 meerkeuzevragen en de luistercheck (§5.1); oordeel (§6); W31–W35 |
