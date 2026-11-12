# Testplan MT1: mijlpaaltest flow-kamer op D = 60 (T17, F0 norm 3)

Versie 0.1 · 2026-11-12 · Eigenaar: QA Lead (met Lead Game Designer) · Issue: [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80) · Lead-review: Executive Producer

Basis: fasekader v0.4 (`docs/productie/fase-2-kader.md`: §3 F0, §4 mijlpaaltest MT1, T17); besluiten van 2026-11-12 in `docs/beslissingen.md` (echo-staart **1 s, D = 60**, bereik 1–3 s, zonder aparte check; fase 2 parallel; **de CEO test alleen bij mijlpalen**, kaart ± 10–15 min, ± 3–4 runs); besluit [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124) (F0 solo); gdd v0.8 §4.5 (MP-1–MP-6), **§4.8** (D = 60 doorgerekend, §4.8.3 punt 6 en 11, §4.8.4 W-8–W-11) en O-23; pitch v0.5 §10 R-V1; rapport F0-2 v0.1.2 (`docs/qa/rapport-f0-2-flowtest.md`, §7, **§8.3** de negen bot-punten, §11); testplan F0-2 v0.1.4 (W11–W21).

Kaart voor de CEO: `docs/qa/ceo-kaart-mt1.md`. Rapport (na de sessie): `docs/qa/rapport-mt1.md`. Meetlogs van de sessie: `docs/qa/mt1-meetlogs/`.

## 1. Wat MT1 toetst

MT1 is de eerste mijlpaaltest volgens besluit 2026-11-12 (2): de CEO speelt de flow-kamer **pas als de bots op D = 60 groen zijn**. MT1 levert wat de bots niet kunnen leveren:

1. **F0 norm (3)**, MP-5: "vloeiend/satisfying" ≥ 4 op 5, solo, op D = 60.
2. **De normen van de bots, nu bij een mens**: MP-1, MP-2 (ook per kamer), MP-4, MP-6 en R-V12 (MP-3, ook **per keerpunt**). De bots tonen dat de kamer het *kán* (§2); MT1 meet of de CEO het *doet*. Vooral: keert hij in K1 en loopt hij zijn echo tegemoet (F0-2: 0 van 15 keerpunten zonder wachten, rapport F0-2 §4.2)?
3. **R-V1 (nabeeld)**, pitch v0.5 §10: is de echo bij 1 s een tweede lichaam of een spoor? (a) gedrag: de echo als plank op de keerpunten van K1 en MP-2 ≥ 3,0, ook per kamer; (b) lezing: één open vraag vóór H, met H ≥ 4 als signaal. **Geen exit-norm.**
4. **Leesbaarheid en *Nine Sols***: M1 (zwak signaal, W8) en M2, nu als **open** vragen (rapport F0-2 §6 en §10: in F0-2 als meerkeuze gevraagd, zwakker).

Niet in MT1: een tweede staart. D = 90 (en 120 / 180) gaat **niet** mee als tweede staart, alleen als regressie in de bots (rapport F0-2 §8.3, besloten door de EP). Geen co-op (besluit #124). Geen luistercheck.

## 2. Voorwaarden vóór de sessie (bots groen)

De Producer geeft de CEO de kaart pas als alle regels hieronder ✅ zijn. Ontbreekt er iets, dan meldt QA in #80 wat ontbreekt en wie aan zet is. Zo niet groen: **geen sessie** (fasekader §4 en §5: geen CEO-test zonder groene bots).

### 2.1 Build

| Wat | Waarde |
|---|---|
| Build | `main` op commit `_______` (in te vullen door QA: de merge van de PR van de World & Level Designer voor [#189](https://github.com/cesarvangerwen-glitch/echoborn/issues/189), T16f W-8–W-11; G-6–G-8 zitten erin via PR [#194](https://github.com/cesarvangerwen-glitch/echoborn/pull/194)) |
| Zip voor de CEO | `https://github.com/cesarvangerwen-glitch/echoborn/archive/<volledige commit>.zip` (in te vullen, ook in de kaart) |
| Standaard-D | **D = 60** bij het starten, uit data (`game/data/echo_v04.json`, `echo.tail_ticks`), geen F-toets nodig (G-6) |
| D-toetsen | F1 / F2 / F3 / F7 = D 60 / 90 / 120 / 180 (`DEBUG_TAIL_KEYS` in `flow_room.gd`); op een laptop met Fn. In MT1 alleen **F1** als herstel. Volgende run met **F6** (houdt de gekozen D; pas na drie scores, G-5) |
| HUD | regel *Kamer K1   D = 60   echo Actief   tijd …* (`HUD_ROOM`); regel met de F-toetsen eindigt op *F5 meetlog aan · F6 herstart* (`HUD_DEBUG_KEYS`); meetlog staat standaard aan (`chosen_log_on`) |
| Meetlog | `meetlog_<datum-tijd>_solo_D60_p1.csv` in `%APPDATA%\godot\app_userdata\Echoborn` |
| Keerwanden en niveaus in K1 (voor §4.2) | in te vullen uit `flowkamer.md` §3 na W-8/W-9: x van de keerwand en y van het niveau voor **B3** (nieuw keerpunt bij D = 60), B1, B2-0, B2-1, B2-2, B2-3; keerzone Z = 90 px |
| Plekken in K3 (voor §4.3) | schoepen x 1980 / 1900 / 1820 / 1740, sluis x 1440–1460, bovenste trede x 2000–2026 op y 385 (testplan F0-2 §2), tenzij W-11 de trede verplaatst: dan in te vullen |

### 2.2 De negen bot-punten (rapport F0-2 §8.3), op de build van §2.1

Draaien met `godot --headless --path game --fixed-fps 60 -s res://tests/run_tests.gd`. De cijfers vult QA in uit de uitvoer van de suite en uit `flowkamer.md` §9 (W-10, W-11).

| # | Wat (rapport F0-2 §8.3) | Grens | Uitkomst D = 60 (in te vullen) | ✅ |
|---|---|---|---|---|
| 1 | Gescripte run vanaf `RUN_START`: `RUN_EIND` | MP-1 ≤ 300; MP-2 ≥ 3,0 (K1 en K2 apart), geen gat > 40 s; MP-4 ≤ 40 %; MP-6 ≥ 40 % met ≥ 1 pompslag van de echo; LP ≥ 100 na K1 + K2 | runtijd ___ s · MP-1 ___ · MP-2 ___ (K1 ___ / K2 ___), gat ___ s · MP-4 ___ % · MP-6 ___ %, ___ pompslagen · LP na K2 ___ | [ ] |
| 2 | K1, keren bij elk keerpunt (`test_flowkamer_na_f0.gd`) | 6 van 6 via de echo zonder stilstand van 20 ticks (B3, B1, B2-0 … B2-3); per keerpunt snelste langzame lijn − keren ≥ 30 ticks, langzame lijn ≤ 2× keren; `test_keerzone_geometry` op Z = 90 | ___ van 6 · keren ___ ticks, langzame lijn ___ ticks (verschil ___, verhouding ___) | [ ] |
| 3 | Late bot (bounce +4 / +8 ticks, dash 0 / 4 / 8 na de top) | marge tot de rand van de weg omhoog > 0 px in elke variant; geoefend zonder dash ≥ 9 px; afzetvenster ≥ 10 ticks; geen overhang | kleinste marge ___ px · zonder dash ___ px · venster ___ ticks | [ ] |
| 4 | Wachtbot | tabel van `flowkamer.md` §9 voor D = 60: tegen de wand → trede; waar het restgat begint | trede tot ___ px · omhoog vanaf ___ px · stilstand ___ ticks | [ ] |
| 5 | B3 en B4 | de echolijn van B3 bestaat en de bot haalt hem; solo-lancering in B4 | B3 ___ · B4 lancering op tick ___ | [ ] |
| 6 | K3, LM-04 | elke schoep één slag; `GEMAAL_VOL` vóór P1 bij de sluis; geen stilstand > 30 in K3 | marge ___ ticks · langste stilstand K3 ___ | [ ] |
| 7 | Echo uit (FK-2) | runtijd ≤ 2× de run met echo; ≤ 4 keer terug naar K2 | ___ × · ___ keer | [ ] |
| 8 | D = 60 kiesbaar en standaard | D op HUD en scorescherm; CSV als `…_D60_….csv` | gezien in de suite / code ___ | [ ] |
| 9 | QA: `rekenen.gd` op de bot-logs van punt 1 en 4 | punt 1: 6 van 6 uitkomst A; punt 4: de wachtplek van de bot klopt met §9; W15 (§7) aangepast op de nieuwe maten | punt 1 ___ · punt 4 ___ | [ ] |

Daarnaast:

- [ ] Volledige suite groen op die commit: ___ geslaagd, 0 mislukt (in te vullen). D = 90, 120 en 180 draaien mee als **regressie**; hun uitkomst staat in het rapport, maar is geen voorwaarde voor MT1, behalve dat de suite groen is.
- [ ] `docs/qa/f0-2-meetlogs/rekenen.gd` is bijgewerkt voor D = 60 (B3 als zesde keerpunt, W15 en de banden van de wachtbot uit punt 4, geen uitzondering voor B4, W14 vervalt) en gekopieerd naar of verwezen vanuit `docs/qa/mt1-meetlogs/`.
- [~] Wat headless niet kan (HUD bij het starten, F1 en het scorescherm met de hand): controle in de sessie via de HUD-check van de kaart en via het log (eerste `ECHO_LEEG_EIND` op tick 60, W9).

## 3. Normen (solo, D = 60)

Zoals F0 en F0-2 (gdd §4.5), nu over **één D**: de getelde runs van MT1 (W25). Wat verandert bij D = 60 staat in de laatste kolom.

| Norm | Maat | Gehaald als | Bij D = 60 |
|---|---|---|---|
| (1) nergens > ± 5 s stil, ook bij het gemaal | MP-1 | langste stilstand in **elke** getelde run ≤ 300 ticks; 301–360 grensgeval (de LGD bekijkt de plek); > 360 niet gehaald (W13) | De stilstand in B4 telt **wel** mee (gdd §4.8.3 punt 6: W14 vervalt) |
| (2) echo als springplank of merk-afmaker ≥ ± 1× per 20 s | MP-2 | in elke getelde run ≥ 3,0 echo-acties/min, **ook in K1 en K2 apart**; geen gat > 40 s | — |
| (3) "vloeiend/satisfying" ≥ 4 op 5 | MP-5 | gemiddelde over de getelde runs ≥ 4,0 en geen kamer gemiddeld < 3,0 (W11) | **Levert F0 norm (3)** |
| Echo ≤ 40 % Leeg | MP-4 | in elke getelde run ≤ 40 % | — |
| De echo telt mee bij het gemaal | MP-6 | in elke getelde run ≥ 40 % van de LP met de echo en ≥ 1 pompslag van de echo | — |
| R-V12: springplank vóór je | MP-3 | landingen/min rapporteren; **≥ 75 % van de landingen zonder stilstand**, over de getelde runs samen (W16) | De landing van de lancering in B4 telt **mee** (gdd §4.8.3 punt 6) |
| *Nine Sols* (zwak signaal) | M1 | niet spontaan genoemd (W8) | Nu een **open** vraag (W27) |

**MP-3 per keerpunt** (§4.2) is geen eigen norm, maar wel de belangrijkste uitleg bij MP-3 en MP-2 in K1. Verwachting LGD: ≥ 60 % uitkomst A (gdd §4.7.2).

**R-V1 (pitch §10)** is **geen exit-norm**. Signaal "tweede lichaam" = de lezingsvraag R valt als "iemand die meedeed" (W28) **én** H ≥ 4 **én** gedrag (a): MP-2 in K1 ≥ 3,0 en de echo genomen bij ≥ de helft van de keerpunten (A + B). QA rapporteert het, de CD weegt het (§6).

## 4. Wat QA uit de logs rekent

Alles uit de CSV's van de CEO met `flow_report.gd` en `rekenen.gd` (bijgewerkt, §2.2), per run; de oefenrun apart (leercurve). Geen nieuwe events (gdd §4.7.4): alles uit `SPRINGPLANK`, `LANCERING`, `BOUNCE`, `STIL_*`, `MERK_GEZET`, `MERKSPRONG`, `ONTPLOFFING`, `LP`, `POMP`, `GEMAAL_VOL`, `KAMER`, `SCORE`, `RUN_EIND` en `x, y`.

### 4.1 Per run

| Maat | Wat QA rapporteert |
|---|---|
| D | uit het log: bestandsnaam `_D60_` en eerste `ECHO_LEEG_EIND` op tick 60 (W9). Een run met een andere D telt niet (W25) |
| Scores | K1 / K2 / K3 uit de `SCORE`-regels van dat log (W9); het antwoordblok vraagt ze niet meer (W29) |
| MP-1 | langste stilstand met kamer, bouwsteen en `x, y` (B4 nu inbegrepen) |
| MP-2 | per min over de run, in K1 en in K2; langste gat. K1 naast F0-2 (0 / 0 / 5,6) en de bot van §2.2 punt 1 |
| MP-3 | landingen/min; aandeel zonder stilstand; per bouwsteen (B4, B3, B1, B2-0 … B2-3, K2) en **per keerpunt** (§4.2) |
| MP-4, MP-6 | zoals F0-2; MP-6 met het aantal pompslagen van de echo |
| MP-5 | K1 / K2 / K3 en het run-gemiddelde (W10) |
| Overig | runtijd, tijd per kamer, kamervolgorde (K3 → K2 → K3?), LP vóór de eerste keer K3 (≥ 100, gdd §4.2) |

### 4.2 MP-3 per keerpunt (K1: B3, B1, B2-0, B2-1, B2-2, B2-3)

Bij D = 60 heeft K1 **zes** keerpunten met de echo: B3 is een keerpunt geworden (geen blok, gdd §4.8.2 en W-9). Bij 3 getelde runs zijn dat 18 keerpunten. Per keerpunt één van vier uitkomsten (W15, aangepast in W26):

| Uitkomst | Hoe herkend in het log |
|---|---|
| **A. Echolijn zonder stilstand** | een `SPRINGPLANK` op dat niveau, ≥ de grens voor C van de keerwand (W26), zonder stilstand van ≥ 20 ticks in de 120 ticks ervoor (de MP-3-regel) |
| **B. Echolijn na wachten**, met de plek | idem, mét zo'n stilstand. Plek = `x` van die stilstand als **afstand tot de keerwand in px**, ingedeeld volgens de wachtbot op D = 60 (§2.2 punt 4): **in de keerzone (< Z = 90 px)** of **onder de weg omhoog (≥ 90 px, het restgat)**. Richting alleen als het log die toont, anders "richting onbekend" |
| **C. Bij de wand gewacht** | een `SPRINGPLANK` op dat niveau dichter bij de keerwand dan de grens van W26: de bounce bracht hem op de treden (langzame lijn na wachten) |
| **D. Langzame lijn** | het volgende niveau gehaald zonder `SPRINGPLANK` op dat niveau (W22) |

**MP-3 per keerpunt = A ÷ (A + B + C + D)**, per run en over de getelde runs; ook per keerpunt over de runs (welk keerpunt valt uit?). De oefenrun apart: keert hij al in zijn eerste run?

Vervolgregels (gdd §4.8.2, §4.8.3 punt 1, 11 en 13; `flowkamer.md` §12):

- **Wachtafstand per keerpunt** in px (ook bij C). Bij D = 60 kost wachten hooguit ± 60 ticks; wie springt zodra het plank-signaal aangaat, staat < 20 ticks stil en telt als A (gdd §4.8.2). Wie blijft staan tot de echo onder hem staat, is B.
- Kiest hij bij een keerpunt in meer dan de helft van de getelde runs C + D, dan is de **langzame lijn** daar nog de gewoonte: bevinding voor de WLD en LGD (gdd §4.8.3 punt 13, het verplichte verschil ≥ 30 ticks).
- Haalt MP-3 de 75 % niet of MP-2 in K1 de 3,0 niet: **O-23** (§6). QA levert dan de tabel A–D per keerpunt en de wachtafstanden als invoer voor de LGD.

### 4.3 Stilstand per kamer, met plek

| Kamer | Wat | Verwachting (gdd §4.8.2, rapport F0-2 §8.1) |
|---|---|---|
| K1 | langste stilstand per bouwsteen, B4 inbegrepen (39 ticks wachten van slag tot sprong) | ≤ 60 ticks |
| K2 | per merk de langste stilstand tussen `MERK_GEZET` en de `MERKSPRONG` erna (merk leeft D + 30 = 90 ticks); langste stilstand in K2, met afstand tot het pantserdoel (x 1579) | ≤ 60 ticks (wachten op de knal hooguit ± 60) |
| K3 | elke stilstand ≥ 30 ticks met plek (schoepen, sluis, elders; W17); landing op de **bovenste trede** en K3 → K2 → K3 (rapport F0-2 §5.3; na de keuze van de WLD in W-11); stilstand bij de sluis (LM-04 ≤ 30) | ≤ 30 ticks |

### 4.4 Uit het antwoordblok (open vragen, kaart §4)

In deze volgorde, zodat niets vooraf de antwoorden kleurt (W18). Alles **open en kort**, getypt in de Claude-chat (W27).

| # | Vraag | Bron | Hoe QA het leest |
|---|---|---|---|
| R | Wat was je schaduw voor jou: iemand die meedeed, of een spoor achter je aan? | pitch v0.5 §10 R-V1 (CD) | "meedeed / tweede lichaam / hulp die meespeelt" of "spoor / nabeeld / schaduw die volgt" of "anders"; letterlijk citeren (W28) |
| M1 | Waar deed het merk (wat je met slaan op een vijand zet) je aan denken? | gdd §5 vraag 5 | *Nine Sols*, talisman of lading-en-ontploffing spontaan = terug naar afwijkpunt 2 (W8) |
| O1 | Hoe kwam je in K1 meestal een verdieping hoger? | gdd §4.7.5 punt 5 | naast §4.2: zegt hij uit zichzelf "omdraaien / mijn echo tegemoet"? |
| M2 | Kies één moment waarop een merk wel of juist niet knalde: waarom? | gdd §5 vraag 6 | begrepen bij "de echo kwam (niet) langs" of "het merk was te ver / gedoofd" (W19) |
| H | Echo: hulp of last? (1–5, 5 = hulp) | gdd §5 vraag 8 | getal; F0 3,5, F0-2 4–5 (band). Signaal R-V1 bij ≥ 4 |
| V1 | Wist je waar je echo zou zijn? (1–5) | gdd §5 vraag 1 | **één keer** na alle runs, niet per run (W29); bevinding, grens ≥ 4 |
| X | Ging er iets mis (vast, afgebroken, verkeerde toets, iets raars)? | rapport F0-2 open punt 5 | koppelt QA aan `_afgebroken`-logs |

## 5. Sessie met de CEO (solo, ± 12–15 min)

Draaiboek: `docs/qa/ceo-kaart-mt1.md`.

| Blok | Wat | Tijd |
|---|---|---|
| 0 | Zip uitpakken in een nieuwe map, oude meetlogs opzij, openen; HUD-check (D = 60, echo Actief/Leeg, meetlog aan); na F5 eerst A, D of spatie | ± 3 min |
| 1 | **1 oefenrun** op D = 60 (telt niet, W25) | ± 1,5–2 min |
| 2 | **3 getelde runs** op D = 60; na elke run meteen drie cijfers in het spel (K1, K2, K3) | ± 5–6 min |
| 3 | Zeven korte open antwoorden (R, M1, O1, M2, H, V1, X) | ± 2–3 min |
| 4 | Antwoordblok en de CSV's in de Claude-chat | ± 1 min |

Geraamd ± 12–15 min, binnen het besluit (± 10–15 min, ± 3–4 runs). Runtijd in F0-2: 74–120 s per run.

**Data** (W21): de CEO zet het antwoordblok en alle CSV's van de sessie in de **Claude-chat**; de agent die de chat verwerkt, zet ze in `docs/qa/mt1-meetlogs/` en in een comment in #80. Bijlagen in GitHub-comments zijn voor de agents niet te downloaden.

**Een run die mislukt** (vast, F6, verkeerde D): de CEO speelt aan het eind één run extra. Meer dan één extra run vraagt de kaart niet (tijd). QA koppelt scores alleen via het log (W9).

## 6. Oordeel en gevolgen

Het rapport noemt bij elk oordeel hoeveel het draagt: één speler, drie getelde runs, één D. Omdat alle runs op D = 60 zijn, zijn oefening en D nu niet meer vermengd (rapport F0-2 §3.2); QA rapporteert de leercurve over de vier runs.

| Uitkomst | QA-advies en gevolg |
|---|---|
| MP-1, MP-2 (ook K1 en K2), MP-4, MP-6 gehaald, **MP-5 ≥ 4,0** en geen kamer < 3,0, **MP-3 ≥ 75 %**, en geen spontane *Nine Sols* | **Go F0** (norm (3) solo geleverd; *Nine Sols*-check uitgesteld naar F4b(c)). Daarna `Visie-review` van de CD op P1 en P3; QA sluit T17 met het rapport (#80 dicht na merge). De flow-kamer en de regels van gdd §4.8.5 zijn dan bevestigd voor de slice |
| **MP-3 < 75 %, of MP-2 in K1 < 3,0** (of een gat > 40 s in K1), wat de rest ook doet | **O-23 (vaart)**, gdd §4.8 en O-23: de LGD bereidt een `ceo-beslissing` voor over hoe de echo op de speler reageert (R-V12), met MP-3 per keerpunt (§4.2) en de wachtafstanden. Geen go F0. Geen nieuwe CEO-speeltest vóór die beslissing; daarna test het team met de bots en speelt de CEO pas in de volgende mijlpaaltest (fasekader §3 F0, *Mislukt*) |
| MP-2 over de hele run < 3,0 | Valt onder de rij hierboven (O-23); dit is ook de kaderregel "norm (2) niet gehaald → `ceo-beslissing` R-V12" |
| Objectieve normen gehaald (incl. MP-3), maar **MP-5 < 4,0** of een kamer < 3,0 | **Geen go.** De LGD stelt per kamer een aanpassing voor (oorzaak uit §4.2–§4.3 en de open antwoorden), getest met de bots. De CEO speelt het pas in de volgende mijlpaaltest (MT2, of één kaart als MT1-bis en MT2 op dezelfde build vallen, fasekader §4). Raakt het de echo of een kernregel: stopregel voor slicewerk (fasekader §4). Of er een extra mijlpaaltest komt of een `ceo-beslissing` (scope), beslist de EP |
| MP-1, MP-4 of MP-6 niet gehaald | Geen go. Bevinding met plek (§4.3) voor de LGD/WLD, aanpassing met de bots; verder zoals de rij hierboven |
| De CEO noemt het merk spontaan als *Nine Sols* (M1) | Terug naar afwijkpunt 2 (gdd §2.13); LGD en Combat Designer |
| R-V1: lezing "spoor", of H < 4, of gedrag (a) niet gehaald | **Geen exit-norm, geen invloed op go/no-go.** Volgens pitch §10: eerst art (Art Director: de 2 nabeelden van de echo, bible §6; scherper hol silhouet, eigen klank bij contact), daarna een voorstel van de LGD aan de CEO voor D = 90 (binnen het bereik). QA meldt het in het rapport aan de CD en de AD |
| R-V1: "iemand die meedeed" en H ≥ 4 en gedrag (a) | Signaal positief; R-V1 (nabeeld) kleiner. CD verwerkt het in de risico's |
| M2 niet begrepen | Geen F0-voorwaarde. Bevinding voor LGD, Gameplay Programmer (E-02t, E-14j) en T10 (UX Designer, Art Director); derde keer op rij als dat zo is |
| < 3 getelde runs | 2 getelde runs: oordeel wel, met de kanttekening. 1 of 0: geen oordeel over MP-5 en MP-3; de objectieve maten uit de logs staan als bevinding in het rapport, en de EP beslist of norm (3) meegaat in MT2 |
| Bots niet groen (§2) | Geen sessie; QA meldt in #80 wat ontbreekt en wie aan zet is |

**V1** telt niet mee in het oordeel (bevinding, testplan F0-2 §6). Het rapport noteert ook de duur van de sessie (uit de tijden in de logs).

## 7. Werkaannames (kader §5)

Uit `testplan-f0.md` §6 blijven W1, W2, W7 (in de vorm van W25), W8, W9 en W10; uit `testplan-f0-2.md` §7 W11, W13, W16, W17, W18, W19 en W21; uit het rapport F0-2 W22 en W23. **Vervallen**: W12 (vervangen door W25), W14 (de uitzondering voor B4 vervalt bij D = 60, gdd §4.8.3 punt 6), W15 (aangepast in W26), W20 (één D). Verder: D = 60 is een CEO-besluit **als werkaanname** (nog niet gespeeld, `beslissingen.md`); de indeling MT1–MT3 is een werkaanname van de EP (fasekader §4). Nieuw:

| # | Aanname | Waarom |
|---|---|---|
| W25 | Een **getelde run** is een solo-run op D = 60 vanaf de **tweede** voltooide run, met `RUN_EIND`, drie `SCORE`-regels, echo aan en geen `DROP_IN`. De eerste voltooide run is de oefenrun. `_afgebroken` en runs met een andere D tellen niet. Een extra run aan het eind telt als hij aan die regels voldoet; dan gelden de eerste drie getelde | Besluit 2026-11-12 (2): ± 3–4 runs. De CEO speelde de kamer al in F0 en F0-2 (7 voltooide runs); één oefenrun voor de nieuwe K1 volstaat. W7 vroeg twee |
| W26 | De grens tussen A/B en C (W15) en de banden van B komen uit de wachtbot en de gescripte run op D = 60 (§2.2 punt 2 en 4). Startwaarde **C < 40 px** van de keerwand (de bounce van de echolijn ligt bij D = 60 op 40–62 px, gdd §4.8.2), **B-band: < 90 px (keerzone) of ≥ 90 px (restgat)**. QA zet de definitieve waarden vóór de sessie in §2.2 punt 9 en in `rekenen.gd` | Bij D = 60 komt de vroegste keerlanding dicht bij de oude grens van 60 px (rapport F0-2 §8.2) |
| W27 | Alle vragen zijn **open**: de CEO typt een korte zin in de Claude-chat. Geen meerkeuze, geen voorbeelden in de vraag. "Spontaan" (M1, O1) geldt daardoor sterker dan in F0-2 | Rapport F0-2 §6 en §10 (W18): M en O waren meerkeuze, zwakker |
| W28 | De lezing van R deelt QA in als "meedeed", "spoor" of "anders/beide", met het letterlijke citaat. De CD bevestigt de indeling in de Lead-review van het rapport. R-V1 is een signaal, geen exit-norm | Pitch v0.5 §10 R-V1 |
| W29 | De scores K1/K2/K3 komen alleen uit het log (`SCORE`), niet van een kladje; V1 wordt één keer na alle runs gevraagd. De kaart vraagt geen kladje per run | Licht houden (± 10–15 min); in F0-2 kwamen de scores 3–21 s na `RUN_EIND` in het log en klopten ze (rapport F0-2 §3.1) |
| W30 | MP-3 per keerpunt telt B3 mee als zesde keerpunt; vergelijking met F0-2 gaat over B1–B2-3 (5 per run) | gdd §4.8.2 (B3 bij D = 60 een keerpunt), W-9 |

## 8. Open punten

| # | Wat | Wie |
|---|---|---|
| 1 | Build-commit, zip-link, keerwanden/niveaus van K1 en de bot-cijfers van §2.2 invullen na de merge van de PR voor #189; in de kaart de zip-link | qa-lead (na world-level-designer) |
| 2 | `rekenen.gd` bijwerken voor D = 60 (B3, W26, B4 telt mee) en toetsen op de bot-logs (§2.2 punt 9) | qa-lead |
| 3 | Eerste knop op de pijltjeskant maakt speler 1 (rapport F0 open punt 10): de kaart werkt eromheen ("na F5 eerst A, D of spatie") | ux-designer, gameplay-programmer |
| 4 | Positie zonder events in K1 (rapport F0-2 open punt 4): uitkomst D blijft "zonder SPRINGPLANK" (W22) | lead-game-designer, gameplay-programmer |

## Wijzigingen

| Versie | Datum | Wijziging |
|---|---|---|
| 0.1 | 2026-11-12 | Eerste versie (#80, T17 MT1): voorwaarden met de negen bot-punten (in te vullen), normen op D = 60, MP-3 per keerpunt met B3, open vragen (R voor R-V1, M1, O1, M2, H, V1, X), 1 oefenrun + 3 getelde runs, oordeel met O-23, W25–W30 |
