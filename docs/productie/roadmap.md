# Roadmap *Wraithstep* (werktitel)

Versie 1.2 · 2026-11-08 · Opgesteld door: Executive Producer (#3, v1.2: #31) · Beheer daarna: Producer (mijlpalen en sprints)

Werktitel *Wraithstep* (besluit #24, voorheen *Echoborn*); niet publiek vóór de formele merkcheck door een specialist (besluit #24, 3A). Deze roadmap legt de vijf fases op hoofdlijnen vast: doel, kernoplevering en gate. Per fase schrijft de Executive Producer bij de start een fasekader (`docs/productie/fase-<n>-kader.md`) met de toetsbare exit-criteria; de Producer werkt de mijlpalen en sprints uit. Risico's staan in `docs/productie/risico.md` (Producer).

## Randvoorwaarden (CEO-besluiten #2, #18, #24)

| Onderwerp | Besluit | Gevolg voor de roadmap |
|---|---|---|
| Budget | Per fase | Elke gate bevat een budgetaanvraag van de EP voor de volgende fase |
| Timing | Geen deadline, kwaliteit eerst | Duur per fase is een **raming**, geen deadline; de EP stelt na fase 2 een releasevenster voor |
| Omvang | 5–7 uur, 3–4 gebieden, 4–5 bosses | Raming fase 3 gebaseerd op 3–4 gebieden |
| Verdienmodel | ≈ €20 eenmalig, geen microtransacties; DLC alleen na nieuw besluit | Geen in-game winkel; geen DLC in de planning |
| Financiering | Zelf + subsidies uitzoeken; geen publisher voorlopig | Subsidieonderzoek gedaan (`docs/business/subsidies.md`): fase 2 rekent met **€ 0 subsidie**; mogelijk VAF-productiesteun voor fase 3 (zie fase 2 en 3). Indienen is een CEO-besluit |
| Toon en rating | Duister maar niet gruwelijk, doel PEGI 12 | Content en ratingaanvraag op PEGI 12 |
| Bereik | Alleen Engels bij launch; Steam Deck verified als doel | Geen vertaling in de planning; Deck-eisen vanaf fase 2. Een Nederlandse versie (voorwaarde VAF) ligt als voorgestelde scope-wijziging bij de CEO (gate fase 1, zie "Wat openstaat") |
| Stijl (#18) | 2D pixel art, 640×360, dynamisch 2D-licht | Art-pijplijn fase 2–3 in 2D; lichtmeting op de Deck in fase 1 (#21) |
| Werktitel (#24) | *Wraithstep*; formele merkcheck vóór de eerste publicatie | Geen publieke uiting met de naam vóór de specialist; budgetpost € 3.750 excl. btw in de fase van de eerste publicatie |

> **Alle duur in deze roadmap is een raming (aanname)**, in regie-runs of in maanden, geen deadline. Budget wordt per fase aangevraagd; er is geen totaalbudget.

## Overzicht

| Fase | Doel in één zin | Kernoplevering | Gate (wie beslist) | Duur (raming) |
|---|---|---|---|---|
| 1. Concept | Weten of *Wraithstep* (concept B) het concept wordt en of de echo technisch kan | Pitch, kernloop, spike echo-opname, stijltests, naam- en ideecheck | CEO: concept definitief + start fase 2 + budget fase 2 | 7–10 regie-runs (raming) |
| 2. Preproductie | Bewijzen dat de game leuk is en hoe we hem maken | **Verticale slice**: 1 gebied, 1 boss, solo + co-op, eindkwaliteit art en audio (eerst bewezen in één scène, zie fase 2) | CEO: productie-scope, releasevenster (voorstel EP), budget fase 3 | 6–10 weken (raming) |
| 3. Productie | Alle content bouwen | De overige 2–3 gebieden, 3–4 bosses, alle systemen; content-compleet | EP: content-compleet (alpha); CEO: budget fase 4 | 4–8 maanden (raming) |
| 4. Alpha/Beta | Van compleet naar goed | Bugvrij, gebalanceerd, Steam Deck verified-klaar, PEGI 12-rating | CEO: releasedatum + go/no-go + budget fase 5 | 2–3 maanden (raming) |
| 5. Launch | Uitbrengen en ondersteunen | Release op Steam, day-1-patch, eerste updates | CEO: einde actieve ondersteuning | 1–2 maanden na release (raming) |

De omvang (3–4 gebieden) is vastgelegd; de duur van fase 3 blijft de grootste hefboom op de totale planning (R20). De fase-3-raming is nu lineair geschaald, zonder onderbouwing per gebied. De Executive Producer legt daarom na de verticale slice een raming per gebied voor, plus een releasevenster, zodat de CEO fase 3 kan vrijgeven met de kost erbij. De verticale slice is 1 van de 3–4 gebieden, dus **een kwart tot een derde** van de game: een goede basis voor die raming.

## Fase 1: Concept
- **Doel**: concept B bevestigen; het grootste technische risico (echo exact herhalen, ook in co-op) wegnemen.
- **Hoofdlijnen**: pitch (#4, #15, #25), technisch ontwerp v0 + spike (#5, #14, #30), kernloop en echo-mechaniek (#6), stijltests 2D/2.5D (#7), naam- en ideecheck (#8) en korte merkcheck *Wraithstep* (#29), risicoregister (#9, #32), subsidieonderzoek (#19, zonder exit-criterium), lichtmeting op de Deck (#21, na #10), statusrapport, concept-fasekader fase 2 en gate (#10).
- **Exit**: zie `docs/productie/fase-1-kader.md` (E1–E8).
- **Besluiten CEO**: randvoorwaarden (#2), stijl 2D (#18) en werktitel (#24) zijn genomen. Open: de gate met budget fase 2 (#10), met daarin de subsidievragen (vestiging, vennootschap, Nederlandse versie, VAF-intake).
- **Let op**: fase 1 bewijst de draai op papier en technisch. Of hij speelbaar en leuk is, blijkt pas in de slice van fase 2.

## Fase 2: Preproductie
- **Doel**: een verticale slice die de kernfantasie bewijst en waarop we de productie kunnen ramen.
- **Duur**: 6–10 weken, **een raming** (aanname EP), geen deadline. Het fasekader fase 2 (#10) ramt het opnieuw in regie-runs.
- **Hoofdlijnen**:
  - Design: GDD v1 (kernsystemen, beweging, combat-basis, echo-puzzels), wereldstructuur van 3–4 gebieden en gating op licht/schaduw, 1 gebied uitgewerkt. Echo-duur testen met 6, 10 en 14 s (R9). Open reviewpunten gdd (A3 in `risico.md`) samen met de prototype-issues.
  - Art: **eerst art bible v0 (#20)** met **één scène op beoogde eindkwaliteit**, beoordeeld met de SM-rubric (Kwaliteit ≥ 7), **vóórdat het slice-art-werk start** (R5). Daarna de pijplijn voor sprites/omgevingen en de slice op eindkwaliteit.
  - Audio: audiorichting, muziekthema, geluid van de echo. Zelfde regel als bij art: eerst één referentiefragment (bv. het geluid van de echo in de slice-scène) op beoogde eindkwaliteit, rubric Kwaliteit ≥ 7, vóór het slice-audiowerk. Het audiorisico neemt de Producer op in `risico.md` v1.2 (#32).
  - Narratief: wereld, toon (PEGI 12), verhaalboog op hoofdlijnen.
  - Tech: architectuur v1, opslag/laden, input voor 2 controllers, CI met headless tests (R18), eerste build op Steam Deck-specificaties.
  - UX: HUD, menu's, drop-in/drop-out co-op.
  - QA: testplan; elke slice-puzzel in solo én co-op getest (R10, R16); eerste externe playtest is een CEO-besluit (publiceert buiten de repo).
  - Business/Legal: VAF-dossier voor **productiesteun voor fase 3** voorbereiden (route c, `subsidies.md` §5), zonder in te dienen; de intake en een vennootschap alleen na een CEO-besluit. De Producer plant de VAF-deadlines 2027 in zodra ze bekend zijn (R6).
- **Als de eindkwaliteit niet haalbaar blijkt** (de scène of het fragment scoort onder de 7, of de AD/Audio Director twijfelt): geen slicewerk op die basis. De betrokken Lead opent een `brainstorm`-issue met de CEO (`WERKWIJZE.md` §9), en de EP herziet de slice-raming en legt de kost voor (fasekader §6). Dit is de hoofdmaatregel tegen R5.
- **Exit (voorlopig)**: verticale slice speelbaar solo en co-op; playtestvragen uit fase 1 beantwoord; de verticale slice scoort "past" op alle 3 pillars (visie-review CD); art en audio van de slice op eindkwaliteit (rubric ≥ 7); productieraming per gebied; voorstel releasevenster; risicoregister bijgewerkt.
- **Besluiten CEO**: productie-scope binnen 3–4 gebieden, releasevenster (voorstel EP), eventueel publieke demo of Steam-pagina (bv. Steam Next Fest; eerst de merkcheck door de specialist), budget fase 3, eventueel indienen bij het VAF, eventueel echo-duur ≠ 10 s.

## Fase 3: Productie
- **Doel**: alle content bouwen tot content-compleet.
- **Hoofdlijnen**: de overige gebieden en bosses (totaal 3–4 gebieden, 4–5 bosses) in vaste volgorde volgens de wereldkaart; vaardigheden en gating; volledige soundtrack; alle UI in het Engels (en lokalisatie-klaar, als de CEO een Nederlandse versie besluit); Steam-pagina voorbereid (publicatie is een CEO-besluit, na de merkcheck). Mogelijk VAF-productiesteun: fase 3 mag gestart zijn, maar niet af bij de ondertekening van het contract (`subsidies.md`, art. 14.9).
- **Mijlpalen (voorlopig)**: per gebied een mijlpaal met een speelbare build. Elke gebied-mijlpaal heeft:
  - een **visie-review van de Creative Director** op P1–P3 (`Visie-review: past` per pillar, zoals in fase 1);
  - een **playtest solo én co-op** van de puzzels van dat gebied (R10, R16), met de playtestgrenzen uit de gdd (o.a. echo ≤ 40 % van de tijd Leeg, co-op ≤ 2× zo snel als solo);
  - de gewone **SM-review** met de rubric.
  - Na de eerste gebied-mijlpaal toetst de EP de raming per gebied tegen de werkelijkheid en meldt een afwijking aan de CEO (R20).
- **Exit (voorlopig)**: alle geplande content speelbaar van begin tot eind (5–7 uur), solo en co-op; elke gebied-mijlpaal met visie-review "past" en playtest solo + co-op; geen blokkerende bugs bekend.
- **Besluiten CEO**: budget fase 4.

## Fase 4: Alpha/Beta
- **Doel**: kwaliteit, balans en stabiliteit.
- **Hoofdlijnen**: bugfixing, balans, performance (60 fps op Steam Deck als doel), toegankelijkheid, Steam Deck verified-checklist, PEGI 12-rating, launchmateriaal. Een Nederlandse vertaling en lokalisatietest alleen als de CEO daartoe besluit.
- **Exit (voorlopig)**: geen bugs met prioriteit hoog; Deck-checklist gehaald; rating PEGI 12 binnen; releasekandidaat goedgekeurd door QA Lead en Studio Manager.
- **Besluiten CEO**: releasedatum, definitieve prijs (≈ €20 volgens besluit #2), go/no-go, budget fase 5.

## Fase 5: Launch
- **Doel**: uitbrengen en de eerste weken ondersteunen.
- **Hoofdlijnen**: release, monitoring van reviews en bugs, day-1- en eerste patches, communitysupport.
- **Exit (voorlopig)**: geen kritieke bugs open; post-mortem en skillrapport geschreven.
- **Besluiten CEO**: einde actieve ondersteuning; DLC, vertalingen of vervolg alleen via een nieuw besluit.

## Wat openstaat
| Vraag | Bij wie | Issue | Raakt |
|---|---|---|---|
| ~~Stijl 2D of 2.5D~~ | CEO | **Besloten** (#18: 2D) | Art-pijplijn fase 2 en 3 |
| ~~Naam~~ | CEO | **Besloten** (#24: werktitel *Wraithstep*); korte check oranje (#29, PR #33); formele check vóór de eerste publicatie | Steam-pagina, marketing |
| Werktitel en USP-teksten in pitch en README | Creative Director | #25 | Pitch, marketing |
| Diablo II-item *Wraithstep* (vindbaarheid) | Creative Director, Marketing | via #10 (R15-route) | Definitieve naam, Steam-pagina |
| Budget fase 2, incl. merkcheck-post € 3.750 excl. btw | CEO (aanvraag EP) | #10 | Start fase 2 |
| Subsidies: vestiging (V), vennootschap (1), Nederlandse versie (2, scope-wijziging ≈ 4–7 runs + mogelijke externe post), VAF-intake (3) | CEO (op advies Business/Legal) | #10 (uit #19, `subsidies.md` §6) | Budget fase 3, scope (taal), fase 2–4 |
| VAF-deadlines 2027 | CEO (aflezen), Producer (inplannen) | #19 / R6 | Timing aanvraag productiesteun |
| Releasevenster | CEO (voorstel EP na fase 2) | gate fase 2 | Fase 3–5 |

## Logboek wijzigingen
| Versie | Datum | Wijziging |
|---|---|---|
| 1.0 | 2026-11-08 | Eerste versie, alle fases op hoofdlijnen |
| 1.1 | 2026-11-08 | Randvoorwaarden-besluit #2 verwerkt: omvang 3–4 gebieden/4–5 bosses/5–7 uur (fase 3 geraamd op 4–8 i.p.v. 6–12 maanden; fase 4 op 2–3 i.p.v. 2–4 maanden, geen vertaling), budget per fase in elke gate, geen deadline, alleen Engels, PEGI 12, geen microtransacties/DLC, subsidies. Lead-review CD: fase-2-exit met visie-review op de 3 pillars; echo-duur en co-op-test (R9, R10). |
| 1.2 | 2026-11-08 | #31. Werktitel *Wraithstep* (#24) en stijl 2D (#18) in titel, randvoorwaarden en "Wat openstaat". SM-punten PR #12: (3) "een kwart tot een derde van de game", "≈ 1,5–2 weken" geschrapt, alle duur gemarkeerd als raming (ook fase 2); (4) fase 3: per gebied-mijlpaal visie-review CD (P1–P3) en playtest solo + co-op naast de SM-review, plus een rameringstoets na het eerste gebied; (5) eindkwaliteit art en audio in de slice gekoppeld aan R5: eerst één scène/fragment op eindkwaliteit (rubric ≥ 7, art bible #20 naar fase 2), anders `brainstorm`-issue en herziene slice-raming. Subsidieonderzoek (PR #28): € 0 subsidie in fase 2, VAF-productiesteun fase 3 voorbereiden (route c), Nederlandse versie als voorgestelde scope-wijziging met kost. Merkcheck (PR #33): geen publicatie vóór de specialist, post € 3.750 excl. btw. |
