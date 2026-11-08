# Roadmap *Echoborn*

Versie 1.0 · 2026-11-08 · Opgesteld door: Executive Producer (#3) · Beheer daarna: Producer (mijlpalen en sprints)

Deze roadmap legt de vijf fases op hoofdlijnen vast: doel, kernoplevering en gate. Per fase schrijft de Executive Producer bij de start een fasekader (`docs/productie/fase-<n>-kader.md`) met de toetsbare exit-criteria; de Producer werkt de mijlpalen en sprints uit.

> **Alle duur en budget in deze roadmap zijn aannames.** Budget, releasevenster en financiering liggen open bij de CEO in #2. Na een besluit daar werkt de Executive Producer deze roadmap bij (nieuwe versie).

## Overzicht

| Fase | Doel in één zin | Kernoplevering | Gate (wie beslist) | Duur (aanname) |
|---|---|---|---|---|
| 1. Concept | Weten of *Echoborn* het concept wordt en of de echo technisch kan | Pitch, kernloop, spike echo-opname, stijltests, naamcheck | CEO: concept definitief + start fase 2 | 7–10 regie-runs (≈ 1,5–2 weken) |
| 2. Preproductie | Bewijzen dat de game leuk is en hoe we hem maken | **Verticale slice**: 1 gebied, 1 boss, solo + co-op, eindkwaliteit art en audio | CEO: productie-scope + releasevenster | 6–10 weken |
| 3. Productie | Alle content bouwen | Alle gebieden, bosses, systemen; content-compleet | EP: content-compleet (alpha) | 6–12 maanden |
| 4. Alpha/Beta | Van compleet naar goed | Bugvrij, gebalanceerd, Steam Deck verified-klaar, vertalingen | CEO: releasedatum + go/no-go | 2–4 maanden |
| 5. Launch | Uitbrengen en ondersteunen | Release op Steam, day-1-patch, eerste updates | CEO: einde actieve ondersteuning | 1–2 maanden na release |

De duur van fase 3 hangt sterk af van de omvang (aanname: 10–14 uur, 6–8 gebieden, 8–10 bosses). Dit is de grootste hefboom op de totale planning; de Executive Producer legt na de verticale slice een raming per gebied voor, zodat de CEO de omvang kan kiezen met de kost erbij.

## Fase 1: Concept
- **Doel**: concept B bevestigen; het grootste technische risico (echo exact herhalen, ook in co-op) wegnemen.
- **Hoofdlijnen**: pitch (#4), technisch ontwerp v0 + spike (#5), kernloop en echo-mechaniek (#6), stijltests 2D/2.5D (#7), naamcheck (#8), risicoregister v1 (#9), statusrapport en gate (#10).
- **Exit**: zie `docs/productie/fase-1-kader.md` (E1–E8).
- **Besluiten CEO**: randvoorwaarden (#2), stijl 2D/2.5D (uit #7), eventueel naam (uit #8), gate (#10).

## Fase 2: Preproductie
- **Doel**: een verticale slice die de kernfantasie bewijst en waarop we de productie kunnen ramen.
- **Hoofdlijnen**:
  - Design: GDD v1 (kernsystemen, beweging, combat-basis, echo-puzzels), wereldstructuur en gating op licht/schaduw, 1 gebied uitgewerkt.
  - Art: art bible na de stijlkeuze; pijplijn voor sprites/omgevingen; slice op eindkwaliteit.
  - Audio: audiorichting, muziekthema, geluid van de echo.
  - Narratief: wereld, toon, verhaalboog op hoofdlijnen.
  - Tech: architectuur v1, opslag/laden, input voor 2 controllers, CI met headless tests, eerste build op Steam Deck-specificaties.
  - UX: HUD, menu's, drop-in/drop-out co-op.
  - QA: testplan; eerste externe playtest is een CEO-besluit (publiceert buiten de repo).
- **Exit (voorlopig)**: verticale slice speelbaar solo en co-op; playtestvragen uit fase 1 beantwoord; productieraming per gebied; risicoregister bijgewerkt.
- **Besluiten CEO**: productie-scope (omvang), releasevenster, eventueel publieke demo (bv. Steam Next Fest), budget voor fase 3.

## Fase 3: Productie
- **Doel**: alle content bouwen tot content-compleet.
- **Hoofdlijnen**: gebieden en bosses in vaste volgorde volgens de wereldkaart; vaardigheden en gating; volledige soundtrack; alle UI; Engels als basistaal, Nederlands in parallel; Steam-pagina voorbereid (publicatie is een CEO-besluit).
- **Mijlpalen (voorlopig)**: per gebied een mijlpaal met een speelbare build en SM-review.
- **Exit (voorlopig)**: alle geplande content speelbaar van begin tot eind, solo en co-op; geen blokkerende bugs bekend.

## Fase 4: Alpha/Beta
- **Doel**: kwaliteit, balans en stabiliteit.
- **Hoofdlijnen**: bugfixing, balans, performance (60 fps op Steam Deck als doel), toegankelijkheid, vertaling NL compleet, Steam Deck verified-checklist, rating (PEGI 12–16 als aanname), launchmateriaal.
- **Exit (voorlopig)**: geen bugs met prioriteit hoog; Deck-checklist gehaald; releasekandidaat goedgekeurd door QA Lead en Studio Manager.
- **Besluiten CEO**: releasedatum, prijs (aanname ≈ €20), go/no-go.

## Fase 5: Launch
- **Doel**: uitbrengen en de eerste weken ondersteunen.
- **Hoofdlijnen**: release, monitoring van reviews en bugs, day-1- en eerste patches, communitysupport.
- **Exit (voorlopig)**: geen kritieke bugs open; post-mortem en skillrapport geschreven.
- **Besluiten CEO**: DLC of vervolg, einde actieve ondersteuning.

## Wat openstaat
| Vraag | Bij wie | Issue | Raakt |
|---|---|---|---|
| Budget, releasevenster, financiering | CEO | #2 | Duur en scope van fase 2–5 |
| Omvang (uren, gebieden, bosses) | CEO | #2 | Duur fase 3 |
| Stijl 2D of 2.5D | CEO | volgt uit #7 | Art-pijplijn fase 2 en 3 |
| Naam definitief | CEO (op advies Business/Legal) | volgt uit #8 | Steam-pagina, marketing |

## Logboek wijzigingen
| Versie | Datum | Wijziging |
|---|---|---|
| 1.0 | 2026-11-08 | Eerste versie, alle fases op hoofdlijnen |
