# Risicoregister *Polderlight* (werktitel)

Versie 2.1 · 2026-11-11 · Eigenaar: Producer · Issue: [#73](https://github.com/cesarvangerwen-glitch/echoborn/issues/73) (T18; eerder #9 en #32) · Lead-review: Executive Producer
Werktitel *Polderlight* (besluit #96), vervangt *Wraithstep* (#24, #61) en *Echoborn*. Niet publiek gebruiken vóór de formele merkcheck (#24, 3A). Repo en mappen heten voorlopig nog "echoborn".
Bronnen: `docs/concept/pitch.md` v0.4 (§10 R-V1–R-V12), `docs/productie/fase-2-kader.md` v0.3 (§1–§4, §6, §7, §9), `docs/business/ideecheck-v0-4.md`, `docs/beslissingen.md` (#2, #24, #47, #51, #52, #61, #96, #124), `docs/qa/ceo-kaart-f0.md` en `docs/qa/testplan-f0.md`. Versie 1.2 (fase 1, met de volledige onderbouwing per risico) staat in de git-geschiedenis.

**Werkaannames die dit document gebruikt** (kader §5): extern budget fase 2 € 0 (EP, kader §7); totaalbudget en releasevenster volgen per fase (werkaanname in `beslissingen.md`). Kans en impact zijn de inschatting van de Producer, behalve waar een bron staat. Alle andere uitgangspunten zijn CEO-besluiten, waaronder de omvang van fase 2 van ≈ 61–88 maak-taken (besluit #51: 2A; kader §8).

## 1. Samenvatting

- **28 risico's**: R1–R24 bijgewerkt naar pitch v0.4 en fase 2, plus vier nieuwe uit pitch §10: **R25 / R-V2** (echo wordt passief zonder puzzels), **R26 / R-V7** (verdrinken en PEGI 12), **R27 / R-V9** (lijkt op *Nine Sols*), **R28 / R-V12** (springplank ligt achter je).
- **R10 herzien** (= R-V5): niet meer "co-op maakt puzzels triviaal", maar "co-op wordt chaos, te makkelijk, of de een wacht", want er zijn geen puzzels op de kritieke route (#51: 1A) en co-op is "samen bewegen = sterker bewegen" (#51: 7A).
- **R-V4** zit in **R20** (combat-zwaar maakt de raming duurder), met het scopeplafond als maatregel.
- **13 risico's met impact H**: R1, R2, R3, R5, R9, R10, R12, R20, R22, R25, R26, R27, R28. Elk heeft een lopende maatregel in een gemergd document of een open issue.
- **Naam**: R24 (*Wraithstep* naast het *Diablo II*-item) en R15 (naam te duister) zijn kleiner door *Polderlight* (#96). Wat blijft: de merkcheck (R4, #97) en het bordspel *Polders* in NL/BE (R24).

**Koppeling met pitch §10**: R-V1 = R9 · R-V2 = R25 · R-V3 = R12 · R-V4 = R20 · R-V5 = R10 · R-V6 = R2 · R-V7 = R26 · R-V8 = R13 · R-V9 = R27 · R-V10 = R15 · R-V11 = R24 · R-V12 = R28.

## 2. Schaal

| | L (laag) | M (midden) | H (hoog) |
|---|---|---|---|
| **Kans** | Onwaarschijnlijk in deze of de volgende fase | Kan gebeuren; er is een concreet scenario | Gebeurt waarschijnlijk zonder maatregel, of gebeurt al |
| **Impact** | Hooguit een run extra | Een deliverable of mijlpaal schuift | Raakt een pillar, een exit-criterium (F0–F8) of de haalbaarheid |

**Status**: `open` (geen maatregel loopt) · `lopend` (maatregel loopt) · `verkleind` (maatregel werkte, wordt bewaakt) · `gesloten`. Een maatregel "loopt" als hij in een gemergd document of in een open issue met eigenaar staat. **Signaal** = wat we zien als het risico optreedt; wie het ziet, meldt het in het issue van het register.

## 3. Register

T-nummers verwijzen naar `fase-2-kader.md` §2; het issue staat erbij. Voor de stand: zie het issue.

| ID | Risico | K | I | Maatregel | Eigenaar | Signaal | Status |
|---|---|---|---|---|---|---|---|
| R1 | Echo herhaalt niet exact (determinisme) | L | H | Spike (PR #13, #26); CI met Windows-run (T6, [#70](https://github.com/cesarvangerwen-glitch/echoborn/issues/70)); tests herschreven voor de staart (T16a, [#76](https://github.com/cesarvangerwen-glitch/echoborn/issues/76)) | technical-director | Een echo-test is rood, of alleen groen op Linux | verkleind |
| R2 / R-V6 | Twee figuren, finisher-echo (drie figuren in beeld), water, merken en ontploffingen onleesbaar; grijze echo in een grijze wereld | **M** (was L) | H | Leesbaarheidseisen in de art bible (T1, [#20](https://github.com/cesarvangerwen-glitch/echoborn/issues/20)); finisher-echo onderscheidbaar (UX, Combat Designer); in de flow-test (T17, [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80)) speelt de CEO alleen solo, co-op alleen als scripted meting; co-op-leesbaarheid door mensen in de slice (T11, [#88](https://github.com/cesarvangerwen-glitch/echoborn/issues/88); F4b(c)) (besluit #124: 1B) | art-director | De CEO verliest in T17 de echo tegen de grijze beginstaat, of een tester ziet in F1, T11 of F4b(c) niet wie welke figuur is | lopend |
| R3 | De draai voelt als trucje | M | H | Norm (2) in F0; gedragsmaat F4b(b); visie-review F7. Zie ook R25 | creative-director | CEO-kaart F4b: "trucje" of "wil niet doorspelen" | lopend |
| R4 | Werktitel botst met een merk of game | M | M | *Echoborn* opgetreden, *Wraithstep* vervangen (#61, #96). Voor *Polderlight*: korte merkcheck met TMview/WIPO ([#97](https://github.com/cesarvangerwen-glitch/echoborn/issues/97)); formele merkcheck vóór de eerste publicatie (€ 3.750, kader §7) | business-legal-advisor | Treffer op POLDERLIGHT of een dicht merk in de klassen van de check | lopend |
| R5 | Art haalt eindkwaliteit niet | H | H | F1 vóór slice-art (kader §4); R5-scène in T1 ([#20](https://github.com/cesarvangerwen-glitch/echoborn/issues/20)); visie-review P2 ([#65](https://github.com/cesarvangerwen-glitch/echoborn/issues/65)); anders `brainstorm` met de CEO | art-director | R5-scène scoort < 7, of CD zet geen `past` op P2 | lopend |
| R6 | Budget per fase of subsidiedeadline te laat | L | M | Fase 2 € 0 extern en € 0 subsidie (kader §7); andere kosten alleen met een apart besluit | executive-producer | Een externe kost zonder besluit, of een VAF-deadline 2027 vóór de gate | lopend |
| R7 | Reviewketen of ritme vertraagt de fase | M | M | Besluiten #47 en #52; herstel in dezelfde run | producer | PR > 1 run zonder Lead-review, of het weekverbruik loopt achter op het weekdoel | lopend |
| R8 | Scope-sluip: slicewerk vóór F0 | L | M | "Flow eerst" (kader §4, #51: 2A); uitbreiding alleen via kader §9 | executive-producer | Werk aan T8a–d vóór F0 is gehaald | verkleind |
| R9 / R-V1 | Staartduur klopt niet (merk voelt los, of echo lijkt een nabeeld) | M | H | Staart ± 2 s, bereik 1,5–3 s (#51: 8A); test 1,5 / 2 / 3 s in F0 (T17, [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80)) en F4 (T11, [#88](https://github.com/cesarvangerwen-glitch/echoborn/issues/88)); buiten het bereik een `ceo-beslissing` | lead-game-designer | Geen duidelijke winnaar, of de beste duur ligt buiten 1,5–3 s | lopend |
| **R10 / R-V5** (herzien) | **Co-op wordt chaos, te makkelijk, of de een wacht op de ander**; solo kan scheef lopen tegenover een live partner (pillar 3) | M | H | Co-op ≤ 2× zo snel als solo; iedereen kan alles alleen, alleen langzamer; staartlengte als knop voor de solo-balans; ruime vensters (≥ 10 frames). Co-op 7A in T3b ([#75](https://github.com/cesarvangerwen-glitch/echoborn/issues/75)) en T16c ([#78](https://github.com/cesarvangerwen-glitch/echoborn/issues/78)); in de flow-test (T17, [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80)) toetst de CEO alleen solo en zijn de scripted co-op-runs alleen meting; solo én co-op door mensen in elke slice-kamer en de boss (T11, [#88](https://github.com/cesarvangerwen-glitch/echoborn/issues/88)), co-op-normen als voorwaarde in F4b(c) (besluit #124: 1B) | creative-director | Een scripted co-op-run in T17 haalt de grens niet (vroeg signaal); in T11 of F4b(c): co-op > 2× zo snel als solo; een speler staat > ± 5 s stil op de ander (norm 1); solo haalt norm (2) niet terwijl co-op die wel haalt | lopend |
| R11 | Tickvolgorde en objectdetectie (een tick achter) | M | M | A2 beslissen in T4 ([#68](https://github.com/cesarvangerwen-glitch/echoborn/issues/68)), met test voor E-07b en C-01 | technical-director | Een tick-exacte test zit één tick naast | lopend |
| R12 / R-V3 | De echo is te vaak Leeg | M | H | Echo volgt door deuren (E-04a, T5b, [#82](https://github.com/cesarvangerwen-glitch/echoborn/issues/82)); op je echo staan breekt hem niet; grens ≤ 40 % Leeg in F0 en F4 | lead-game-designer | Debugteller "ticks Leeg" > 40 % in een kamer | lopend |
| R13 / R-V8 | Open ontwerpvragen die een pillar raken; 5–7 uur is kort, de echo moet binnen minuten dragen | M | M | GDD v1 in T3a–c ([#67](https://github.com/cesarvangerwen-glitch/echoborn/issues/67), [#75](https://github.com/cesarvangerwen-glitch/echoborn/issues/75), [#81](https://github.com/cesarvangerwen-glitch/echoborn/issues/81)); springplank en merk vanaf de proloog | lead-game-designer | GDD v1 sluit met een open vraag die een pillar raakt | lopend |
| R14 | Positionering: echo-mechaniek bekend, drukke markt | M | M | Tekstnuances ("we vonden geen …", geen "de eerste"); het idee zelf: zie R27 | creative-director | Een tekst claimt "de eerste" of "uniek" | lopend |
| R15 / R-V10 | Naam leest duisterder dan de game | **L** (was M) | L | *Polderlight* is de warmste kandidaat (#96); toets "Naam en toon" (pitch §6) bij elke uiting | creative-director | Een concept voor een publieke uiting leest als horror | verkleind |
| R16 | Solo én co-op testen verdubbelt de testlast | H | M | Headless `ScriptedInput` waar het kan; twee testmomenten per kamer in het QA-plan (T11, [#88](https://github.com/cesarvangerwen-glitch/echoborn/issues/88)) | producer | QA-taken lopen boven de raming in kader §8 | lopend |
| R17 | Prestaties op de Steam Deck met 2D-licht | L | M | Lichtmeting ([#62](https://github.com/cesarvangerwen-glitch/echoborn/issues/62)); build op Deck-specificaties (T7, [#79](https://github.com/cesarvangerwen-glitch/echoborn/issues/79)) | technical-artist | Flow-kamer haalt het lichtbudget niet | lopend |
| R18 | Geen CI; testrunner geeft vals groen | M | M | CI met headless tests (T6, [#70](https://github.com/cesarvangerwen-glitch/echoborn/issues/70)); 0 checks = FAIL (#30) | technical-director | `PASS (0 checks)` of een groene run zonder tests | lopend |
| R19 | Co-op-invoer (ghosting, joypad-index, drop-in/out) | M | M | InputRouter op apparaat-GUID (T5a, [#69](https://github.com/cesarvangerwen-glitch/echoborn/issues/69)) | technical-director | Na opnieuw aansluiten reageert de verkeerde speler | lopend |
| **R20 / R-V4** | Raming fase 3 onzeker; **combat-zwaar is duurder dan puzzels** (vijandtypes, animatie, hitfeedback, bosses) | M | H | **Scopeplafond**: max. 4 nieuwe vijandtypes per gebied (max. 14 totaal, incl. varianten), max. 1 minibaas per gebied, 4–5 bosses (#2); vastgelegd in T3c ([#81](https://github.com/cesarvangerwen-glitch/echoborn/issues/81)); kost per vijandtype en boss gemeten in de slice (F6, T15, [#89](https://github.com/cesarvangerwen-glitch/echoborn/issues/89)) | executive-producer | Kost per vijandtype of boss × plafond past niet in 5–7 uur of het budget per fase | lopend |
| R21 | Reviewpunten raken zoek na een merge | M | M | Regel in `producer-regie.md` (besluit #47) | producer | Een reviewpunt staat niet in het document en niet in een vervolgissue | lopend |
| R22 | Audio haalt eindkwaliteit niet | H | H | F2 vóór slice-audio (kader §4); fragment in T2 ([#66](https://github.com/cesarvangerwen-glitch/echoborn/issues/66)); anders `brainstorm` | audio-director | Fragment scoort < 7, of de AD twijfelt | lopend |
| R23 | VAF-route levert weinig of niets op | M | M | Dossier voorbereiden, niet indienen (T13, [#72](https://github.com/cesarvangerwen-glitch/echoborn/issues/72)); NL-versie in principe ja (#51 deel 1: 5A) | business-legal-advisor | Een drempel blijkt in het dossier niet haalbaar | lopend |
| R24 / R-V11 | Werktitel slecht vindbaar | **L** (was M) | M | *Wraithstep* vervangen (#61, #96). *Polderlight*: 0 games op Steam, geen game-item in de top 10 van Google/YouTube; in NL/BE staat het bordspel *Polders* bovenaan (#96). Meenemen in [#97](https://github.com/cesarvangerwen-glitch/echoborn/issues/97); herhaalcheck vóór de eerste publicatie | marketing-community-manager | Bij de herhaalcheck staat een game-item in de top 10 | verkleind |
| **R25 / R-V2** (nieuw) | **Zonder puzzels wordt de echo passief**, een automatische buff, zeker nu samenwerken op de route optioneel is (pillar 1) | M | H | Echo verplicht bij bosses; op de route moet hij lonen: bounce- en lanceerketens vullen de lichtmeter sneller, kortere wegen en verzamelobjecten liggen hoog of ver (pitch §10). Norm (2) in de flow-test (T17, [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80)); gedragsmaat F4b(b), grens in T3c ([#81](https://github.com/cesarvangerwen-glitch/echoborn/issues/81)) | lead-game-designer | Echo < ± 1× per 20 s als springplank of afmaker, of het gebruik buiten verplichte boss-acties ligt onder de grens uit T3c | lopend |
| **R26 / R-V7** (nieuw) | **Verdrinken raakt PEGI 12 of het publiek**: een verzonken stad kan als ramp of dood lezen | L | H | Toonregels in pitch §6 (droom, geen lichamen, geen echte watersnood); narratief V2 (T9, [#71](https://github.com/cesarvangerwen-glitch/echoborn/issues/71)); elke scène met water langs de toets "duister maar niet gruwelijk"; toon in de visie-review F7 | narrative-designer | Een scène of asset toont lichamen, paniek of een echte watersnood; CD zet bij F7 geen `past` op de toon | lopend |
| **R27 / R-V9** (nieuw) | **Het idee lijkt op een bestaande game**: het schaduwmerk ligt dicht bij *Nine Sols*, de regel bij *Echo Shift* (USP 1) | M | H | Ideecheck gedaan (#58, `ideecheck-v0-4.md`: oranje voor het merk, rest groen); afwijkpunten (§2) in T3a ([#67](https://github.com/cesarvangerwen-glitch/echoborn/issues/67)); zwak signaal in de flow-test: M1 van de CEO, solo (T17, [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80); CEO-kaart en testplan F0); sterke check in F4b(c) met M1 van een P2 die de referenties niet kent; zonder zo'n P2 blijft R-V9 open in het gate-voorstel (F8) (besluit #124: 1B); herontwerp na T8b ≈ +3–5 maak-taken, plus ≈ +1–2 voor T8c als het merk er anders uit moet zien (kader §4); octrooiscan apart in de merkcheck-offerte (kader §7) | business-legal-advisor | De CEO (T17) of P2 (F4b(c)) noemt het merk spontaan "net als *Nine Sols*", een talisman of "lading die ontploft" | lopend |
| **R28 / R-V12** (nieuw) | **De springplank ligt achter je**: in een voorwaartse run werkt hij alleen bij klimmen, keren, vallen en lussen (pillar 1) | M | H | Korte staart (#51: 8A); de vier situaties als levelregel (T3a, [#67](https://github.com/cesarvangerwen-glitch/echoborn/issues/67); flow-kamer T16b, [#77](https://github.com/cesarvangerwen-glitch/echoborn/issues/77)); meetpunt in T17 ([#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80)): springplank-gebruik per minuut en het aandeel zonder stilstand. Haalt de flow-kamer norm (2) niet: eerst herontwerp en een tweede flow-test, dan een `ceo-beslissing` (F0) | lead-game-designer | Springplank-gebruik laag of vaak met stilstand; norm (2) niet gehaald | lopend |

### 3.1 Overzicht kans × impact

| Kans \ Impact | L | M | H |
|---|---|---|---|
| **H** | | R16 | R5, R22 |
| **M** | | R4, R7, R11, R13, R14, R18, R19, R21, R23 | R2, R3, R9, R10, R12, R20, R25, R27, R28 |
| **L** | R15 | R6, R8, R17, R24 | R1, R26 |

## 4. Wijzigingen ten opzichte van v1.2

| ID | v1.2 | v2.0 | Waarom |
|---|---|---|---|
| R2 | L/H | M/H | Pitch v0.4: finisher-echo met drie figuren, merken, water en een grijze beginstaat (R-V6). |
| R4 | M/M (*Wraithstep*) | M/M (*Polderlight*) | Nieuwe werktitel (#96); nog niet in merkregisters getoetst (#97). |
| R8 | scope vóór de gate | slicewerk vóór F0 | Fase 2 is gestart (#51); de nieuwe grens is "flow eerst" (2A). |
| R9 | 6 / 10 / 14 s | 1,5 / 2 / 3 s | Besluit #51: 8A. |
| R10 | puzzels triviaal in co-op | chaos, te makkelijk, wachten | Geen puzzels op de kritieke route (1A); co-op 7A; = R-V5. |
| R15 | M/L | L/L, verkleind | *Polderlight* is het warmst van de drie kandidaten (#96). |
| R20 | raming fase 3 | + R-V4, scopeplafond | Combat-zwaar (1A) is duurder; plafond uit pitch §10. |
| R24 | M/M, *Diablo II*-item | L/M, verkleind | *Wraithstep* vervangen (#61, #96); restpunt: het bordspel *Polders* in NL/BE. |
| R25–R28 | | nieuw | R-V2, R-V7, R-V9 en R-V12 uit pitch v0.4 §10. |
| Overige | | ongewijzigd | Maatregelen gekoppeld aan de fase-2-taken (T-nummers en issues). |

## 5. Open acties

| # | Actie | Voor rol | Raakt | Waar |
|---|---|---|---|---|
| A2 | Objectdetectie beslissen | technical-director | R11 | T4, [#68](https://github.com/cesarvangerwen-glitch/echoborn/issues/68) |
| A3 | Open reviewpunten gdd (Ankeren, bosses lezen de echo, terugkeerpoorten) | lead-game-designer | R13, R20 | T3c, [#81](https://github.com/cesarvangerwen-glitch/echoborn/issues/81) |
| A13 | Reviewpunten VAF en merkcheck | business-legal-advisor | R4, R23 | [#35](https://github.com/cesarvangerwen-glitch/echoborn/issues/35) |
| A16 | VAF-deadlines 2027 aflezen (CEO) en inplannen (Producer) | CEO, producer | R6, R23 | Zonder issue; zie §6 |
| A18 | Korte merkcheck *Polderlight*, met de NL/BE-ranking en *Polders* | business-legal-advisor | R4, R24 | [#97](https://github.com/cesarvangerwen-glitch/echoborn/issues/97) |

Afgeronde acties A1, A4–A12, A14, A15 en A17 staan in v1.2 (git-geschiedenis).

## 6. Beheer en open punten

- De Producer beheert dit register en werkt het bij bij elke merge die een risico raakt, en bij elke gate. Elke rol meldt een risico in het issue van het register of in de eigen PR ("risico voor het register").
- Elk risico heeft één eigenaar. Een risico met impact H heeft altijd een lopende maatregel. Naar `verkleind` of `gesloten` alleen met een verwijzing naar het bewijs.
- Het fase-statusrapport (T15, [#89](https://github.com/cesarvangerwen-glitch/echoborn/issues/89)) neemt de 13 risico's met impact H over.
- Twee afwijkingen van kader §6, met één voorstel aan de EP voor de volgende versie van het kader: (1) kader §6 noemt R26 / R-V7 niet bij de H-risico's; dit register wel (toon en PEGI 12 vallen onder F7); (2) kader §6 koppelt R-V2 aan R3; dit register geeft R-V2 een eigen nummer (R25), want "echo wordt passief zonder puzzels" is een ander risico dan "de draai voelt als trucje" (R3 verwijst naar R25).

**Open punten**: A16 (geen issue). Signaalwaarden die nog een grens nodig hebben (R25: grens uit T3c; R16: raming per QA-taak) worden ingevuld zodra die documenten gemergd zijn.

## 7. Definition of Done ([#73](https://github.com/cesarvangerwen-glitch/echoborn/issues/73))

- [x] R10 herzien (§3, §4).
- [x] R-V2 (R25), R-V4 (R20), R-V7 (R26), R-V9 (R27) en R-V12 (R28) opgenomen.
- [x] Noemt de werkaanname die het gebruikt (kop, kader §5).
- [x] Werktitel *Polderlight* (#96) in de kop en bij R4, R15 en R24.

## 8. Versies

| Versie | Datum | Wat |
|---|---|---|
| 1.0 | 2026-11-08 | Eerste versie (#9): R1–R10 uit het fasekader, R11–R21, acties A1–A8. |
| 1.1 | 2026-11-08 | Lead-review EP (PR #27). |
| 1.2 | 2026-11-08 | #32: R22–R24, A9–A17. |
| 2.0 | 2026-11-09 | #73 (T18): naar pitch v0.4 en fasekader fase 2 v0.2. R10 herzien (R-V5), R-V4 in R20, nieuw R25–R28 (R-V2, R-V7, R-V9, R-V12). Kolom Signaal; beknopter register. Werktitel *Polderlight* (#96): R4, R15, R24 bijgewerkt. |
| 2.1 | 2026-11-11 | Na besluit #124 (1B) en fasekader v0.3 (#80): R2, R10 en R27 (R-V9) naar F0 alleen solo; co-op door mensen in de slice (T11, F4b(c)), in T17 alleen scripted meting; *Nine Sols*-check zwak in T17 (M1 van de CEO), sterk in F4b(c) of open in F8. |
