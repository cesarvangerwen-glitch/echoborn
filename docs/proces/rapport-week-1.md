# Procesrapport week 1 (regie-runs 1–6, 2026-11-08)

Versie 1.0 · Workflow & Process Optimization Lead · issue #45 · peildatum 2026-11-08 16:30 UTC

## 1. Samenvatting

- Week 1 bestond uit **één dag met 6 regie-runs**. Resultaat: **13 PR's gemerged**, 1 PR open (#42), 3 CEO-besluiten verwerkt. Fase 1 ligt op koers. Wat nog openstaat voor de gate: #32, daarna #10.
- **Reviews kosten meer dan het maakwerk.** In run 6 ging 43 % van de gemeten tokens naar reviews. Over de hele dag schat ik dat aandeel op ≈ 55 %. De Studio Manager keurde **0 van 13** PR's af. Alle 4 afkeuringen kwamen van de Lead.
- **Polish wordt opnieuw gepland als nieuw werk.** Niet-blokkerende reviewpunten worden een eigen issue, en elk zo'n issue kost weer een volledige ronde maken + Lead + SM (≈ 330k tokens). Er staan er nu 3 open of lopend (#32, #35, #43). Samen is dat ≈ 1 M tokens aan polish.
- **Kleine afkeuringen kosten een hele run.** Twee keer werd een fix binnen dezelfde run gedaan (#17, #27): dat kostte 2 minuten. Drie keer niet (#16, #28, #42): dat kostte telkens een nieuwe agent en een hele run wachttijd.
- **Grootste hefboom**: minder dubbele reviews, geen vervolgissues voor polish en herstel in dezelfde run. Mijn verwachting is **−45 tot −55 % tokens per opgeleverd werkstuk**, zonder dat er minder wordt opgeleverd (§4). Drie punten vragen een CEO-besluit (§6). De rest staat al in deze PR als wijziging van de regie-instructie (§5).

## 2. Cijfers

### 2.1 Doorlooptijd per issue (alle tijden UTC, 2026-11-08)

Runs: R1 eindigde 06:54, R2 10:18 (extra testrun), R3 13:01 (CEO-chat), R4 13:27, R5 14:31, R6 16:16.

| Issue | Deliverable | Runs | Lead-rondes | SM-score (K/V/H/V) | Opmerking |
|---|---|---|---|---|---|
| #3 | Fasekader fase 1 | R1–R2 | 2 | 8/8/7/7 | Afgekeurd door de CD (inhoud) |
| #4 | Pitch | R1 | 1 | 8/9/8/8 | Merge door de CEO zelf (permissie) |
| #5 | Ontwerp + echo-spike | R1 | 1 | 8/8/9/8 | Merge door de CEO zelf |
| #6 | Kernloop + GDD | R2–R3 | 2 | 8/8/8/8 | Afgekeurd door de EP (4 kleine punten) |
| #7 | Stijltests | R2 | 1 + fix in dezelfde run | 8/9/8/8 | Fix in 2 min ([lead](https://github.com/cesarvangerwen-glitch/echoborn/pull/17#issuecomment-6720214564) → [fix](https://github.com/cesarvangerwen-glitch/echoborn/pull/17#issuecomment-6720231564)) |
| #8 | Naamcheck | R3 | 1 | 8/8/8/7 | |
| #9 | Risicoregister v1 | R4 | 1 + fix in dezelfde run | 8/8/8/7 | Fix in 2 min ([fix](https://github.com/cesarvangerwen-glitch/echoborn/pull/27#issuecomment-6722033308)) |
| #14 | Spike-fixes | R4 | 1 | 9/8/9/8 | Vervolg op reviewpunten van #13 |
| #15 | Pitch v0.2 | R3 | 1 | 7/9/8/8 | Vervolg op reviewpunten van #11 |
| #19 | Subsidies | R4–R5 | 2 | 9/8/8/8 | Afgekeurd door de EP (format van de CEO-vragen) |
| #25 | Wraithstep doorvoeren | R6 | 1 | 8/9/9/8 | |
| #29 | Merkcheck | R5 | 1 | 8/8/9/8 | |
| #31 | Fasekader v1.2 | R5 | 1 | 8/8/8/8 | Deels vervolg op reviewpunten |
| #36 | Visie-review stijltests | R6 | – | – | Review die in de keten van #7 ontbrak |
| #32 | Risicoregister v1.2 | R6 → open | 1 (niet akkoord) | – | Vervolg op SM-punten van PR #27 |

- **Gemiddeld 1,2 runs per deliverable** (13 gemerged). 10 van de 14 PR's kregen bij de eerste Lead-review meteen akkoord (71 %).
- **Wachttijd op de CEO**: #18 41 min, #24 1 u 28 min (inclusief een brainstormronde). Dat is geen knelpunt.

### 2.2 Reviewrondes en afkeuringen

| Review | Aantal | Afgekeurd | Gem. lengte comment |
|---|---|---|---|
| Lead-review | 17 rondes op 14 PR's | 4 (24 %) | ≈ 4.000 tekens |
| SM-review | 13 | **0** | ≈ 4.200 tekens |
| Visie-review CD (buiten §5) | 3 (op #15/#16, #17 via #36) | 0 | ≈ 3.500–6.000 tekens |

De SM-scores lagen tussen 7 en 9. Het laagste cijfer was 7, vier keer, en geen enkel criterium kwam onder de grens.

Waarom er werd afgekeurd:
1. [PR #12](https://github.com/cesarvangerwen-glitch/echoborn/pull/12#issuecomment-6718424825) (CD): inhoud. De exit-criteria liepen in een kring en de toets aan de pillars ontbrak. **Terecht en zwaar.**
2. [PR #16](https://github.com/cesarvangerwen-glitch/echoborn/pull/16#issuecomment-6720219673) (EP): technische consistentie met de spike. 4 kleine punten.
3. [PR #28](https://github.com/cesarvangerwen-glitch/echoborn/pull/28#issuecomment-6722000007) (EP): de inhoud klopte (5/5 claims), maar de CEO-vragen volgden het `ceo-beslissing`-format niet.
4. [PR #42](https://github.com/cesarvangerwen-glitch/echoborn/pull/42#issuecomment-6723850758) (EP): §5 gaf de stand van issues weer die 7 minuten eerder was veranderd. De EP schreef er zelf bij: *"Het gaat om een paar regels, dus het hoeft geen extra regie-run te kosten"*. Toch werd het een extra run ([relay](https://github.com/cesarvangerwen-glitch/echoborn/issues/32#issuecomment-6723889773)).

Drie van de vier afkeuringen waren dus **klein of over de vorm**. Alleen #12 ging over de inhoud.

### 2.3 Blokkades

| Blokkade | Gevolg | Status |
|---|---|---|
| De geplande taak mocht niet mergen (R1) | Extra testrun R2. De CEO mergede #11 en #13 zelf | Opgelost |
| Branches verwijderen werd geweigerd (R2) | 4 branches handmatig verwijderd | Opgelost (auto-delete aan) |
| vaf.be/deadlines, EUIPO/BOIP niet leesbaar | Open punten in #19 en #29 | Open, niet blokkerend |

### 2.4 Tokens

**Gemeten** (run 6, door de regisseur, per sub-agent):

| Agent | Tokens | Tool-calls | Tokens/call |
|---|---|---|---|
| Producer maakt #32 | 174k | 25 | 7,0k |
| CD Visie-review #36 | 110k | 24 | 4,6k |
| CD pitch #25 | 121k | 18 | 6,7k |
| EP Lead-review PR #41 | 97k | 13 | 7,5k |
| EP Lead-review PR #42 | 118k | 17 | 6,9k |
| SM-review PR #41 | 96k | 11 | 8,7k |
| **Totaal** | **716k** | 108 | 6,6k |

Reviews: 311k (43 %). De regisseur zelf is niet gemeten.

**Geschat voor de hele dag**, met de gemiddelden van run 6 (maker ≈ 135k, Lead ≈ 105k, SM ≈ 96k):

| | Aantal | Tokens |
|---|---|---|
| Maak-agents | 18 | ≈ 2,4 M |
| Lead-reviews | 17 | ≈ 1,8 M |
| SM-reviews | 13 | ≈ 1,25 M |
| **Sub-agents samen** | 48 | **≈ 5,5 M** |

Dat komt neer op ≈ **420k tokens per gemerged werkstuk**. Reviews zijn ≈ 55 % van het totaal. De SM-reviews alleen zijn ≈ 23 %, en daar kwam geen enkele afkeuring uit.

Wat de cijfers laten zien: het aantal tokens groeit ongeveer **lineair met het aantal tool-calls** (≈ 7k per call). Het basispakket dat elke agent opnieuw leest (README, WERKWIJZE, beslissingen en het rolbestand, samen ≈ 12.000 tekens ≈ 3,5k tokens) is zelf klein. Maar dat pakket gaat bij elke volgende call opnieuw mee, net als alles wat de agent daarna leest. **Het grootste deel van de kosten zit dus in hoeveel calls een agent doet en hoeveel grote documenten hij vroeg in de run leest.** De grote documenten zijn `gdd.md` (40k tekens), `subsidies.md` (33k), `fase-1-kader.md` (26k), `naamcheck.md` (26k), `pitch.md` (24k) en `risico.md` (23k). Een voorbeeld: de Lead-review van PR #27 las 10 documenten en de reviews van 6 PR's ([lijst](https://github.com/cesarvangerwen-glitch/echoborn/pull/27#issuecomment-6722012935)).

## 3. Knelpunten, bewijs en voorstel

### K1. De SM-review doet de Lead-review grotendeels over (≈ 23 % van alle tokens, 0 afkeuringen)

**Bewijs**
- De SM keurde 0 van 13 PR's af. Elke afkeuring kwam van de Lead (§2.2).
- De SM leest dezelfde bronnen en neemt de punten van de Lead over:
  - PR #41: de [EP](https://github.com/cesarvangerwen-glitch/echoborn/pull/41#issuecomment-6723840626) noemt niet-blokkerende punten 8–10. De [SM](https://github.com/cesarvangerwen-glitch/echoborn/pull/41#issuecomment-6723872614) schrijft als eerste punt: "Neem de drie niet-blokkerende punten van de EP over".
  - PR #33: de [EP](https://github.com/cesarvangerwen-glitch/echoborn/pull/33#issuecomment-6722595378) en de [SM](https://github.com/cesarvangerwen-glitch/echoborn/pull/33#issuecomment-6722615759) noemen allebei als eerste punt "bovenkant van de richtprijs". Ze doen dezelfde Steam- en RDAP-steekproef.
- De SM-review komt 2 tot 4 minuten na de Lead-review, in dezelfde run (#11, #13, #17, #27, #33, #34, #41).

**Voorstel**: de SM-review alleen nog waar die iets toevoegt: bij werk dat naar de CEO of een gate gaat, bij code in `game/`, en als steekproef op 1 van de 3 andere PR's. Dit verandert §5, dus de CEO beslist (§6, vraag 1).

**Verwachte winst**: in week 1 waren 7 van de 14 PR's geen code en geen CEO- of gate-stuk (#11, #16, #22, #27, #33, #41, #42). Met de steekproef erbij vallen ≈ 5 SM-reviews weg, dus **≈ −480k tokens per 14 PR's (≈ −35k per PR, −9 %)**. Er verandert niets aan het aantal reviewrondes.

### K2. Niet-blokkerende punten worden nieuw werk (≈ 1 M tokens in de pijplijn)

**Bewijs**
- R21 in `docs/productie/risico.md` zegt nu: *"de regisseur maakt bij elke merge een vervolgissue voor alle open reviewpunten"*.
- Polish-issues die daaruit zijn ontstaan:
  - [#32](https://github.com/cesarvangerwen-glitch/echoborn/issues/32): risicoregister v1.2, uit de SM-punten van PR #27. Kostte al 174k + 118k en is nog niet klaar.
  - [#35](https://github.com/cesarvangerwen-glitch/echoborn/issues/35): subsidies v1.2 en merkcheck v1.1.
  - [#43](https://github.com/cesarvangerwen-glitch/echoborn/issues/43): pitch v0.4. Dat is de 4e versie van de pitch op één dag (PR #11, #22, #41).
- De regisseur en de rollen schrijven ook "input"-comments om punten door te geven: #6, #10, #15, [#32 (Producer → Producer)](https://github.com/cesarvangerwen-glitch/echoborn/issues/32#issuecomment-6722741777).
- Documenten houden de stand van issues bij, en die stand is snel achterhaald. Precies daarom werd [PR #42](https://github.com/cesarvangerwen-glitch/echoborn/pull/42#issuecomment-6723850758) afgekeurd.

**Voorstel** (staat al in deze PR, regie-instructie §3): de reviewer deelt elk punt in als
- **blokkerend**: niet akkoord;
- **klein**: de maker verwerkt het in dezelfde PR en run, zonder nieuwe review;
- **open punt**: één regel in de sectie "Open punten" van het document zelf. De volgende rol die het document toch al wijzigt, neemt het mee.

Er komt geen vervolgissue alleen voor niet-blokkerende punten. Een document houdt ook geen stand van issues bij, maar linkt naar het issue. De Producer vervangt de maatregel van R21 hierdoor. Zie het voorstel aan de Producer in het issue-comment.

**Verwachte winst**: in week 1 waren 4 van de 14 PR-cycli polish (#14 en #15 deels, #32, plus #35 en #43 die nog in de wachtrij staan). Het nieuwe beleid vermijdt **≈ 0,25 cyclus per PR × 336k ≈ −85k per PR (≈ −20 %)**. Voor wat er nu openstaat (#32-ronde 2, #35, #43): **≈ −0,8 tot −1 M tokens en 3 maakplekken**.

### K3. Een kleine afkeuring kost een volle run en een nieuwe agent

**Bewijs**
- Fix in dezelfde run: [#17](https://github.com/cesarvangerwen-glitch/echoborn/pull/17#issuecomment-6720231564) en [#27](https://github.com/cesarvangerwen-glitch/echoborn/pull/27#issuecomment-6722033308). De review kwam, 2 minuten later stond de fix klaar en daarna kwam meteen de SM-review. Nul extra runs.
- Geen fix in dezelfde run:
  - PR #16: 10:12 → 11:24, volgende run.
  - PR #28: 13:19 → 14:09, volgende run, met een nieuwe BLA-agent.
  - PR #42: wacht op R7, terwijl de EP zelf schreef dat het in dezelfde run kon.
- Een nieuwe maak-agent kost ≈ 120–175k, omdat hij alles opnieuw leest. Een fix door de agent die de context nog heeft, kost een paar calls.

**Voorstel** (staat al in deze PR, regie-instructie §3): bij "niet akkoord, klein" (alleen kleine of vormpunten, geen herziening van de inhoud) stuurt de regisseur de punten naar de maak-agent van deze run. Daarna doet dezelfde Lead-agent in dezelfde run een korte her-review van alleen de nieuwe commit. Dit telt niet als extra maak-agent in het budget. §5 blijft gelijk: het werk gaat terug naar het team en de Lead reviewt opnieuw.

**Verwachte winst**: 3 van de 4 afkeuringen in week 1 kwamen in aanmerking. Per geval gaat de kost van een nieuwe maker + Lead + SM (≈ 336k) naar een fix + her-review (≈ 60–80k), dus **≈ −260k en −1 run doorlooptijd per geval**. Over 14 PR's is dat ≈ −0,8 M, of **≈ −55k per PR (≈ −13 %)**.

### K4. Elke agent leest te breed en doet te veel calls

**Bewijs**
- Tokens ≈ 7k per tool-call (§2.4).
- Elke agent haalt zelf het issue, de comments en de PR op, terwijl de regisseur dat in stap 0 al deed.
- Reviewers lezen hele documenten. Een voorbeeld is de leeslijst van de [EP op PR #27](https://github.com/cesarvangerwen-glitch/echoborn/pull/27#issuecomment-6722012935).
- Review-comments zijn gemiddeld ≈ 4.000 tekens, waarvan het grootste deel "getoetst en in orde" is. Elke volgende agent op die PR leest dat weer.

**Voorstel** (staat al in deze PR, regie-instructie: prompts):
- De regisseur zet de tekst van het issue en de relevante comments in de prompt.
- De agent start met één bash-call (clone + basisbestanden in één keer).
- Documenten lezen per sectie (`grep -n '^#'` en daarna alleen de nodige sectie), niet in hun geheel.
- Reviewers beginnen bij de diff (`gh pr diff`) en de DoD.
- Een review-comment heeft maximaal ≈ 250 woorden: oordeel, blokkerende punten, kleine punten, open punten. Geen samenvatting van wat in orde is.
- De SM herhaalt geen punten die de Lead al gaf.
- Het taak-template vraagt bij Input om pad + sectie.

**Verwachte winst** (een schatting die gemeten moet worden): 4–6 calls minder per agent, dus **−25 tot −40k per agent**. Het doel is een review van ≤ 60k (nu ≈ 100k) en een maker van ≤ 100k (nu ≈ 135k). Per PR met maker + Lead is dat **≈ −75k (≈ −18 %)**.

### K5. Dubbele boekhouding in comments

**Bewijs**
- De maker zet in het issue een comment van 1.000–2.400 tekens die zijn PR-beschrijving herhaalt (#3, #5, #9, #19).
- De regisseur zet de uitslag van de Lead-review nog eens in het issue: [#3](https://github.com/cesarvangerwen-glitch/echoborn/issues/3#issuecomment-6718429472), [#6](https://github.com/cesarvangerwen-glitch/echoborn/issues/6#issuecomment-6720223319), [#19](https://github.com/cesarvangerwen-glitch/echoborn/issues/19#issuecomment-6722018623), [#32](https://github.com/cesarvangerwen-glitch/echoborn/issues/32#issuecomment-6723889773).
- Het dagrapport komt na elke run (6 per dag) en heeft lege kopjes ("In review: Niets", "Afgekeurd: Niets").
- Vier aparte rename-issues (#37–#40) staan als `status:todo` in de wachtrij die de regisseur elke run leest.

**Voorstel** (staat al in deze PR):
- Het issue-comment van de maker telt maximaal 3 regels: de PR-link, wat openstaat en wie aan zet is.
- De regisseur zet geen review-uitslag meer in het issue. De maker leest de PR.
- In het dagrapport vallen lege kopjes weg en komt één regel met tokens per sub-agent bij. Dat is de enige toevoeging, en die is nodig om de winst van K1–K4 te kunnen meten.
- Aan de Producer (planning, niet mijn beslissing): bundel #37–#40 in één checklist-issue zonder `status:todo`, zodat ze niet als werk worden opgepakt.

**Verwachte winst**: klein in tokens (≈ −5 tot −10k per run voor de regisseur, en minder leeswerk voor elke volgende agent op hetzelfde issue), maar het maakt de wachtrij schoner.

## 4. Totaal verwacht effect

Het model per gemerged werkstuk is gekalibreerd op run 6. Een cyclus is maker + Lead + SM ≈ 336k.

| Post | Nu | Na K1–K5 (CEO: 1A) |
|---|---|---|
| Maker | 135k | 100k |
| Lead-review | 105k | 65k |
| SM-review | 96k (elke PR) | ≈ 30k (≈ 50 % van de PR's, ≈ 60k per review) |
| Herstelronde (29 % van de PR's) | ≈ 97k | ≈ 25k (fix in dezelfde run) |
| Polish-vervolgissue (≈ 0,25–0,3 per PR) | ≈ 90k | ≈ 0 (open punt in het document) |
| **Per werkstuk** | **≈ 520k** | **≈ 220–260k (−50 %)** |

- **Per dag, bij 2 runs en ≈ 5 werkstukken**: van ≈ 2,6 M naar ≈ 1,2–1,3 M tokens.
- **Reviewrondes per gemerged werkstuk**: van 1,23 Lead + 1 SM naar ≈ 1,1 Lead + 0,5 SM.
- **Runs per werkstuk**: van 1,2 naar ≈ 1,05, omdat kleine fixes in dezelfde run vallen.

**Hoe we dit meten**: met de tokenregel in het dagrapport. Na 4 runs (2 dagen) zet ik de voor/na-cijfers in een v1.1 van dit rapport. Gaat een schatting niet op, dan draaien we die maatregel terug.

## 5. Wat deze PR al wijzigt (geen §5-wijziging)

Elke wijziging staat in een eigen commit.

1. **`studio/regie/producer-regie.md` v1.2**
   - Herstel in dezelfde run bij "niet akkoord, klein" (K3).
   - Indeling van reviewpunten en geen vervolgissue voor polish (K2).
   - Geen relay-comments meer (K5).
   - Slankere prompts voor maker en reviewer, met een reviewformat (K4).
   - Kortere dagrapporten met een tokenregel (K5).

   Eigenaar van dit bestand is de Producer. Ik vraag zijn akkoord in #45.
2. **`.github/ISSUE_TEMPLATE/taak.md`**: bij Input staan pad + sectie, zodat de agent alleen leest wat nodig is (K4).

`WERKWIJZE.md` en `docs/beslissingen.md` blijven ongewijzigd.

## 6. Voorstellen voor de CEO (ceo-beslissing)

*De regisseur maakt hiervan het `ceo-beslissing`-issue.*

**Titel:** [CEO] Reviewketen en ritme van twee runs per dag

**Van:** Workflow & Process Optimization Lead (via de Studio Manager)

### Probleem
- In week 1 ging ≈ 55 % van de tokens naar reviews. De SM-review keurde 0 van 13 PR's af, en alle afkeuringen kwamen van de Lead.
- Vanaf 2026-11-09 zijn er twee runs per dag. Met het huidige budget zijn dat tot 6 maak-agents per dag, terwijl er voor fase 1 nog maar ≈ 4 echte taken openstaan (#32, #10, #30, #21).
- Dit vraagt een besluit over §5 (wie reviewt) en over het budget per run.

### Vragen

**1. Welke PR's krijgen nog een Studio Manager-review?**
- **A. Alleen werk voor de CEO of een gate, code in `game/`, plus een steekproef van 1 op 3** ⭐ Aanbevolen: Lead "akkoord" = goedgekeurd voor de rest. Bespaart ≈ 35k tokens per PR (−9 %). Er is minder vaak een frisse tweede blik, maar die keurde in week 1 niets af.
- **B. Elke PR, maar de SM leest alleen de diff en het issue, en werkt op een kleiner model**: de huidige keten blijft. Elke SM-review wordt ≈ 40–60 % goedkoper. De Lead- en SM-punten overlappen nog steeds.
- **C. Zoals nu (elke PR, volledige review)**: geen besparing (≈ 96k per PR).

**2. Hoe verdelen we de twee runs per dag?**
- **A. Ochtend = maken, avond = afronden** ⭐ Aanbevolen:
  - Ochtend (07:00): CEO-besluiten verwerken, mergen, max. 3 maak-agents, elk met Lead-review en een fix in dezelfde run.
  - Avond (19:00): SM-reviews, mergen, max. 1 maak-agent voor klein werk, en het dagrapport (één per dag).
  - Geen werk = stop na stap 0.
  - Max. 4 maak-agents per dag. ≈ 1,2–1,5 M tokens per dag.
- **B. Twee gelijke runs (elk 3 maak-agents + reviews)**: max. 6 maak-agents per dag, ≈ 2–2,6 M tokens per dag. De wachtrij voor fase 1 is daar te klein voor, dus het extra werk wordt vooral polish.
- **C. Eén run per dag (zoals de pilot), de avondrun alleen als er een PR in review of goedgekeurd staat**: het goedkoopst (≈ 1 M per dag), maar een afgekeurd werkstuk wacht dan een dag.

**3. Mag de regisseur per taak een kleiner model kiezen?**
- **A. Ja, voor de SM-review (als die blijft) en voor administratief werk (naam doorvoeren, labels, boekhouding van issues)** ⭐ Aanbevolen: maakwerk, Lead-reviews en de regisseur blijven op het huidige model. Die taken worden goedkoper per token, zonder risico voor het vakwerk.
- **B. Nee, alles op het huidige model**: de kwaliteit is voorspelbaar en er is geen besparing.

### Waarom deze aanbeveling
- De Lead vond in week 1 elke echte fout. De SM bevestigde daarna alleen.
- Een fix in dezelfde run en geen vervolgissues voor polish (al in de regie gezet) halen de rest van de verspilling weg.
- Ochtend maken en avond afronden past bij de wachtrij en geeft de CEO één dagrapport per dag.

### Wat wacht hierop
- `WERKWIJZE.md` §5 (stap 3) en de README-zin "De Studio Manager beoordeelt elk werkstuk apart" bij 1A.
- `producer-regie.md` §Budget bij 2A/2C.

---
*CEO: antwoord met `Besluit: akkoord` of bv. `Besluit: 1A, 2C, 3B`.*

## 7. Beperkingen van deze analyse

- Tokens zijn alleen voor run 6 gemeten. De cijfers voor de dag zijn een extrapolatie. Vanaf nu staat er per run een tokenregel in het dagrapport.
- De "week" is één dag met 6 runs. Het patroon (0 SM-afkeuringen, polish-issues) kan veranderen als er in fase 2 meer code komt. Daarom houdt 1A de SM-review op code.
- De kost van de regisseur zelf is niet gemeten.
