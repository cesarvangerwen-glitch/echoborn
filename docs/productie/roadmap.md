# Roadmap *Echoborn*

Versie 1.1 · 2026-11-08 · Opgesteld door: Executive Producer (#3) · Beheer daarna: Producer (mijlpalen en sprints)

Deze roadmap legt de vijf fases op hoofdlijnen vast: doel, kernoplevering en gate. Per fase schrijft de Executive Producer bij de start een fasekader (`docs/productie/fase-<n>-kader.md`) met de toetsbare exit-criteria; de Producer werkt de mijlpalen en sprints uit.

## Randvoorwaarden (CEO-besluit #2, 2026-11-08)

| Onderwerp | Besluit | Gevolg voor de roadmap |
|---|---|---|
| Budget | Per fase | Elke gate bevat een budgetaanvraag van de EP voor de volgende fase |
| Timing | Geen deadline, kwaliteit eerst | Duur per fase is een **raming**, geen deadline; de EP stelt na fase 2 een releasevenster voor |
| Omvang | 5–7 uur, 3–4 gebieden, 4–5 bosses | Raming fase 3 gebaseerd op 3–4 gebieden |
| Verdienmodel | ≈ €20 eenmalig, geen microtransacties; DLC alleen na nieuw besluit | Geen in-game winkel; geen DLC in de planning |
| Financiering | Zelf + subsidies (bv. VAF Gamefonds) uitzoeken; geen publisher voorlopig | Business/Legal onderzoekt subsidies vanaf fase 1; aanvragen indienen is een CEO-besluit |
| Toon en rating | Duister maar niet gruwelijk, doel PEGI 12 | Content en ratingaanvraag op PEGI 12 |
| Bereik | Alleen Engels bij launch; Steam Deck verified als doel | Geen vertaling in de planning; Deck-eisen vanaf fase 2 |

> **Alle duur in deze roadmap is een raming (aanname)**, geen deadline. Budget wordt per fase aangevraagd; er is geen totaalbudget.

## Overzicht

| Fase | Doel in één zin | Kernoplevering | Gate (wie beslist) | Duur (raming) |
|---|---|---|---|---|
| 1. Concept | Weten of *Echoborn* het concept wordt en of de echo technisch kan | Pitch, kernloop, spike echo-opname, stijltests, naam- en ideecheck | CEO: concept definitief + start fase 2 + budget fase 2 | 7–10 regie-runs (≈ 1,5–2 weken) |
| 2. Preproductie | Bewijzen dat de game leuk is en hoe we hem maken | **Verticale slice**: 1 gebied, 1 boss, solo + co-op, eindkwaliteit art en audio | CEO: productie-scope, releasevenster (voorstel EP), budget fase 3 | 6–10 weken |
| 3. Productie | Alle content bouwen | De overige 2–3 gebieden, 3–4 bosses, alle systemen; content-compleet | EP: content-compleet (alpha); CEO: budget fase 4 | 4–8 maanden |
| 4. Alpha/Beta | Van compleet naar goed | Bugvrij, gebalanceerd, Steam Deck verified-klaar, PEGI 12-rating | CEO: releasedatum + go/no-go + budget fase 5 | 2–3 maanden |
| 5. Launch | Uitbrengen en ondersteunen | Release op Steam, day-1-patch, eerste updates | CEO: einde actieve ondersteuning | 1–2 maanden na release |

De omvang (3–4 gebieden) is vastgelegd; de duur van fase 3 blijft de grootste hefboom op de totale planning. De Executive Producer legt na de verticale slice een raming per gebied voor, plus een releasevenster, zodat de CEO fase 3 kan vrijgeven met de kost erbij. De verticale slice is met 1 van de 3–4 gebieden ongeveer een kwart van de game: een goede basis voor die raming.

## Fase 1: Concept
- **Doel**: concept B bevestigen; het grootste technische risico (echo exact herhalen, ook in co-op) wegnemen.
- **Hoofdlijnen**: pitch (#4), technisch ontwerp v0 + spike (#5), kernloop en echo-mechaniek (#6), stijltests 2D/2.5D (#7), naam- en ideecheck (#8), risicoregister v1 (#9), statusrapport en gate (#10). Subsidieonderzoek (Business/Legal) start, zonder exit-criterium.
- **Exit**: zie `docs/productie/fase-1-kader.md` (E1–E8).
- **Besluiten CEO**: randvoorwaarden (#2, besloten), stijl 2D/2.5D (uit #7, anders in de gate), eventueel naam (uit #8), gate met budget fase 2 (#10).
- **Let op**: fase 1 bewijst de draai op papier en technisch. Of hij speelbaar en leuk is, blijkt pas in de slice van fase 2.

## Fase 2: Preproductie
- **Doel**: een verticale slice die de kernfantasie bewijst en waarop we de productie kunnen ramen.
- **Hoofdlijnen**:
  - Design: GDD v1 (kernsystemen, beweging, combat-basis, echo-puzzels), wereldstructuur van 3–4 gebieden en gating op licht/schaduw, 1 gebied uitgewerkt. Echo-duur testen met 6, 10 en 14 s (R9).
  - Art: art bible na de stijlkeuze; pijplijn voor sprites/omgevingen; slice op eindkwaliteit.
  - Audio: audiorichting, muziekthema, geluid van de echo.
  - Narratief: wereld, toon (PEGI 12), verhaalboog op hoofdlijnen.
  - Tech: architectuur v1, opslag/laden, input voor 2 controllers, CI met headless tests, eerste build op Steam Deck-specificaties.
  - UX: HUD, menu's, drop-in/drop-out co-op.
  - QA: testplan; elke slice-puzzel in solo én co-op getest (R10); eerste externe playtest is een CEO-besluit (publiceert buiten de repo).
  - Business/Legal: subsidieaanvraag voorbereiden als het onderzoek uit fase 1 een passende regeling oplevert (indienen is een CEO-besluit).
- **Exit (voorlopig)**: verticale slice speelbaar solo en co-op; playtestvragen uit fase 1 beantwoord; de verticale slice scoort "past" op alle 3 pillars (visie-review CD); productieraming per gebied; voorstel releasevenster; risicoregister bijgewerkt.
- **Besluiten CEO**: productie-scope binnen 3–4 gebieden, releasevenster (voorstel EP), eventueel publieke demo (bv. Steam Next Fest), budget fase 3, eventueel echo-duur ≠ 10 s.

## Fase 3: Productie
- **Doel**: alle content bouwen tot content-compleet.
- **Hoofdlijnen**: de overige gebieden en bosses (totaal 3–4 gebieden, 4–5 bosses) in vaste volgorde volgens de wereldkaart; vaardigheden en gating; volledige soundtrack; alle UI in het Engels; Steam-pagina voorbereid (publicatie is een CEO-besluit).
- **Mijlpalen (voorlopig)**: per gebied een mijlpaal met een speelbare build en SM-review.
- **Exit (voorlopig)**: alle geplande content speelbaar van begin tot eind (5–7 uur), solo en co-op; geen blokkerende bugs bekend.
- **Besluiten CEO**: budget fase 4.

## Fase 4: Alpha/Beta
- **Doel**: kwaliteit, balans en stabiliteit.
- **Hoofdlijnen**: bugfixing, balans, performance (60 fps op Steam Deck als doel), toegankelijkheid, Steam Deck verified-checklist, PEGI 12-rating, launchmateriaal.
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
| Stijl 2D of 2.5D | CEO | volgt uit #7 (anders in gate #10) | Art-pijplijn fase 2 en 3 |
| Naam definitief, USP 1 | CEO (op advies Business/Legal) | volgt uit #8 | Steam-pagina, marketing |
| Budget fase 2 | CEO (aanvraag EP) | #10 | Start fase 2 |
| Releasevenster | CEO (voorstel EP na fase 2) | gate fase 2 | Fase 3–5 |
| Subsidies | Business/Legal (onderzoek), CEO (indienen) | volgt | Budget fase 2 en verder |

## Logboek wijzigingen
| Versie | Datum | Wijziging |
|---|---|---|
| 1.0 | 2026-11-08 | Eerste versie, alle fases op hoofdlijnen |
| 1.1 | 2026-11-08 | Randvoorwaarden-besluit #2 verwerkt: omvang 3–4 gebieden/4–5 bosses/5–7 uur (fase 3 geraamd op 4–8 i.p.v. 6–12 maanden; fase 4 op 2–3 i.p.v. 2–4 maanden, geen vertaling), budget per fase in elke gate, geen deadline, alleen Engels, PEGI 12, geen microtransacties/DLC, subsidies. Lead-review CD: fase-2-exit met visie-review op de 3 pillars; echo-duur en co-op-test (R9, R10). |
