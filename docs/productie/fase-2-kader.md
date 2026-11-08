# Fasekader fase 2: Preproductie (concept)

Versie 0.1 (concept) · 2026-11-08 · Eigenaar: Executive Producer · Issue: #10 · Lead-review: Creative Director

**Status: concept.** Dit kader is de bijlage bij het gate-voorstel van fase 1 (#10, gate-issue #51, vraag 2). Het geldt pas na een `Besluit:` van de CEO; bij een andere keuze in het gate-issue past de EP het aan (nieuwe versie, logboek §9). Werktitel *Wraithstep* (besluit #24); niet publiek vóór de formele merkcheck (besluit #24, 3A).

## 1. Doel

Aan het eind van fase 2 weet de CEO **of de draai speelbaar en leuk is** en **wat de productie kost**. Fase 1 bewees de draai alleen op papier en technisch (fasekader fase 1 §1); fase 2 is de echte toets van R3. Fase 2 beantwoordt drie vragen:

1. **Speelt het?** Een verticale slice van één gebied, solo en co-op, beantwoordt de 3 playtestvragen (gdd §5): de echo-duur (R9), hoe vaak de echo Leeg is (R12) en of co-op de puzzels triviaal maakt (R10).
2. **Halen we eindkwaliteit?** Art en audio van de slice halen het niveau van een goede indie-release (R5, R22), eerst bewezen in één scène en één fragment.
3. **Wat kost de rest?** Een productieraming per gebied en een voorstel voor een releasevenster (besluit #2, R20).

## 2. Scope

### Binnen scope

Taken met een **T-nummer** zijn nieuw of expliciet gemaakt in dit kader; de Producer maakt er bij de start van fase 2 issues van. De volgorde staat in §4.

| # | Deliverable | Eigenaar | Raakt |
|---|---|---|---|
| T1 | **Art bible v0 + assetlijst** (#20), met **één scène op beoogde eindkwaliteit** (R5-eis, §4) en de drie aandachtspunten uit de visie-review op PR #17 | art-director (met environment-artist) | F1, R5, R2 |
| T2 | **Audiorichting + één referentiefragment** op eindkwaliteit (bv. het geluid van de echo in de slice-scène); eerste taak: de Audio Director bevestigt de audio-eis van F2 (A10) | audio-director (met composer-sound-designer) | F2, R22 |
| T3 | **GDD v1**: kernsystemen, beweging, combat-basis, echo-puzzels, wereldstructuur 3–4 gebieden, de inhoud van de slice. Inclusief **A3**: de open reviewpunten van PR #16 (EP-punten 5–9, SM-punten 1, 3, 4; o.a. "bosses lezen de echo", de Ankeren-voorwaarde, drop-out in C-05, terugkeerpoorten in de raming) | lead-game-designer (met systems-, combat-, world-level-designer) | F3, R12, R13, R19, R20 |
| T4 | **Event-systeem + objectdetectie (A2)**: beslissen tussen `intersect_shape`-queries of één tick vertraging, met de test voor E-07b stap 4–5 en C-01 als DoD-regel (zie #30) | technical-director (met gameplay-programmer) | F5, R11 |
| T5 | Architectuur v1, opslag/laden, input voor 2 controllers (InputRouter op apparaat-GUID), drop-in/drop-out | technical-director, engine-platform-programmer | F3, R19 |
| T6 | **CI met headless tests** (gecachete download, SHA-512-check) en een Windows-run van de echo-tests | tools-programmer of engine-platform-programmer | F5, R1, R18 |
| T7 | Eerste build op Steam Deck-specificaties; lichtbudget uit #21 toegepast | engine-platform-programmer, technical-artist | F5, R17 |
| T8 | Slice bouwen: één gebied, één boss, solo + co-op (inhoud volgens T3) | gameplay-programmer, world-level-designer, 2D-art- en audiorollen | F3 |
| T9 | Narratief: wereld (setting uit T13), toon **duister maar niet gruwelijk, melancholisch, PEGI 12**, verhaalboog op hoofdlijnen | narrative-designer | F3 |
| T10 | UX: HUD, menu's, drop-in/drop-out | ux-designer, ui-artist | F3 |
| T11 | QA-testplan; elke slice-puzzel in solo én co-op getest (R10, R16) | qa-lead | F4 |
| T12 | Vindbaarheidstoets *Wraithstep* (#44), vóór de betaalde merkcheck (volgorde §7) | marketing-community-manager (met creative-director) | R24, R15 |
| T13 | VAF-dossier voor **productiesteun fase 3** voorbereiden (route c, `subsidies.md` §5), **zonder indienen**; met het **tweede criterium uit categorie I** van de culturele test. Voorstel CD: een verzonken stad in de Lage Landen (polders, dijken, belforten, begijnhof; licht naar de Vlaamse Primitieven; het carillon als echo-ritme). Dat raakt de pillars niet en is dus geen aparte CEO-vraag. De VAF-deadlines 2027 worden ingepland (A16). Alleen als de CEO de VAF-route openhoudt (#51, vraag 4–6) | business-legal-advisor (met creative-director, executive-producer, marketing-community-manager); planning: producer | R6, R23 |
| T14 | **Lokalisatie inbouwen** (vertaalbestanden, geen tekst in code), ≈ 1 run. Alleen als de CEO de Nederlandse versie in principe toestaat (#51, vraag 5) | engine-platform-programmer | fasekader fase 1 §6.2 |
| T15 | Productieraming per gebied, voorstel releasevenster, statusrapport en gate-voorstel fase 2 | executive-producer | F6, F8, R20 |

Lopende fase-1-issues die meegaan (geen voorwaarde voor de gate van fase 1): #21 (lichtmeting; mag lopen terwijl de CEO beslist), #43 (pitch v0.4), #37–#40 (werktitel bij de volgende wijziging).

### Buiten scope (bewust niet in fase 2)
- De overige gebieden en bosses (fase 3).
- **Elke publieke uiting**: Steam-pagina, demo, trailer, socials, externe playtest. Elk is een apart CEO-besluit, en een uiting met de naam pas na de formele merkcheck (besluit #24, 3A) en de herhaalcheck (`naamcheck-wraithstep.md` §5.1).
- Een VAF-aanvraag **indienen**, een vennootschap oprichten of een MyVAF-account maken zonder `Besluit:` van de CEO.
- Vertaling naar het Nederlands (fase 4, alleen na een besluit); in fase 2 hooguit T14.
- Betaalde assets, plug-ins of diensten buiten het besloten budget (§7); externe audiotools alleen met licentie in `docs/licenties.md`.

### Randvoorwaarden
Alle CEO-besluiten in `docs/beslissingen.md` gelden onveranderd (o.a. #2, #18, #24, #47). **Werkaannames EP**: duur 6–10 weken (roadmap), ritme twee regie-runs per dag met max. 4 maak-agents per dag (besluit #47).

## 3. Exit-criteria

Fase 2 sluit pas als **alle** criteria F1–F8 (inclusief F4b) gehaald zijn; "bijna" telt niet. "Gemergd" betekent als in fase 1: Lead-review akkoord, bij SM-plichtig werk `status:goedgekeurd` met alle rubricscores ≥ 7, daarna gemergd.

| # | Exit-criterium | Toets | Bewijs |
|---|---|---|---|
| F1 | **Art op eindkwaliteit bewezen** | De scène uit T1 scoort met de SM-rubric **Kwaliteit ≥ 7** én krijgt een **`Visie-review: past` van de CD op de leesbaarheid van pillar 2**: de laag is zichtbaar zonder icoon of uitleg, "vol = levend, hol = echo" (A9). Beide **vóórdat** het slice-art-werk start. Daarna haalt de slice-art zelf ook Kwaliteit ≥ 7. | gemergde PR + SM-score + visie-review |
| F2 | **Audio op eindkwaliteit bewezen** | Het referentiefragment uit T2 scoort **Kwaliteit ≥ 7** vóór het slice-audiowerk; daarna haalt de slice-audio ook ≥ 7. De eis is concept tot de Audio Director hem bevestigt (A10); wijzigt die hem, dan past de EP dit kader aan. | gemergde PR + SM-score + akkoord AD |
| F3 | **Verticale slice speelbaar** | Eén gebied met één boss, van begin tot eind speelbaar solo én in lokale co-op met drop-in/drop-out, op de inhoud uit GDD v1 (T3). | gemergde PR in `game/` + SM-review |
| F4 | **Playtestvragen beantwoord** | De 3 playtestvragen (gdd §5) zijn gemeten, met de grenzen uit de gdd: echo-duur getest met 6, 10 en 14 s (R9); echo ≤ 40 % van de tijd Leeg (R12); co-op ≤ 2× zo snel als solo (R10). Elke slice-puzzel solo en co-op getest (T11). **Wie**: de QA Lead plant en rapporteert; spelers zijn de CEO (F4b) en scripted runs voor de meetbare grenzen; een externe playtest is een apart CEO-besluit. Wijkt de beste duur af van 10 s: `ceo-beslissing`, voorbereid door de CD. | testrapport QA in een gemergde PR |
| F5 | **Techniek houdt** | Headless tests draaien in CI en zijn groen, ook op Windows (T6); A2 is beslist en getest (T4); een build draait op Deck-specificaties binnen het lichtbudget (T7). | gemergde PR's + CI-uitvoer |
| F6 | **Raming en releasevenster** | Productieraming per gebied (regie-runs, rollen, externe kosten), getoetst aan wat de slice werkelijk kostte, plus een voorstel releasevenster (besluit #2). | gemergde PR (EP) |
| F4b | **De slice is leuk** | (a) De CEO speelt de slice solo én co-op (± 1 uur) en vult een korte kaart in: klikmoment van de kernfantasie (ja/nee, waar), wil doorspelen (ja/nee), de echo voelt als bondgenoot of als trucje. (b) Een gedragsmaat voor R3: de echo wordt ook buiten verplichte puzzels gebruikt (bv. aandeel van de boss-schade via de echo); de grens legt de LGD vast in T3. Beide positief, anders geen gate maar een herzien voorstel. | ingevulde kaart (comment CEO) + meting in het QA-testrapport |
| F7 | **Visie-review slice** | De CD zet op de slice-PR `Visie-review: past` op alle 3 pillars **en op de toon** (duister maar niet gruwelijk, melancholisch, PEGI 12). | visie-review |
| F8 | **Gate-besluit CEO** | `docs/productie/fase-2-status.md` toetst F1–F7 en F4b met bewijs; een `ceo-beslissing`-issue vraagt productie-scope, releasevenster, budget fase 3 en eventueel indienen bij het VAF. | `Besluit:` van de CEO |

## 4. Startvoorwaarden en volgorde

- **Kritiek pad**: T3 (GDD v1, slice-inhoud) → T8 (slice bouwen) → T11 (playtests) → T15 (raming en gate).
- **Eindkwaliteit eerst** (hoofdmaatregel tegen R5 en R22): geen slice-art vóór F1-scène + visie-review, geen slice-audio vóór het F2-fragment. Haalt de scène of het fragment geen 7, of twijfelt de AD of de Audio Director: geen slicewerk op die basis, maar een `brainstorm`-issue met de CEO (`WERKWIJZE.md` §9), en de EP herziet de raming en legt de kost voor (§9). Bij de start van fase 2 komt de F1-eis als DoD-regel in #20.
- **Parallel vanaf de start**: T1, T2, T3, T4–T6, T12, T13. T4 vóór de echo-puzzels van T8.

## 5. Kwaliteitslat
- Reviewketen volgens `WERKWIJZE.md` §5 (besluit #47). Alle code in `game/` krijgt SM-review.
- Visie-reviews van de CD: F1 (pillar 2) en F7 (P1–P3).
- Elke deliverable noemt de werkaanname die ze gebruikt.

## 6. Belangrijkste risico's

Bron: `docs/productie/risico.md` (Producer). De risico's met impact H en wat fase 2 eraan doet:

| ID | Risico (kort) | Wat fase 2 doet | Eigenaar |
|---|---|---|---|
| R1 | Echo niet exact | CI + Windows-run (T6) | technical-director |
| R2 | Co-op onleesbaar | Art bible met de aandachtspunten van PR #17 (T1), co-op-playtests (T11) | art-director |
| R3 | Draai voelt als trucje | De slice is de echte toets (F3, F4, F7) | creative-director |
| R5 | Art haalt eindkwaliteit niet | F1 vóór slice-art; anders `brainstorm` | art-director |
| R9 | 10 s voelt verkeerd | Test 6/10/14 s (F4) | lead-game-designer |
| R10 | Co-op maakt puzzels triviaal | Elke puzzel solo en co-op (F4) | creative-director |
| R12 | Echo te vaak Leeg | Grens ≤ 40 % (F4), alternatief O-5 achter de hand | lead-game-designer |
| R20 | Raming fase 3 onzeker | Raming per gebied op basis van de slice (F6) | executive-producer |
| R22 | Audio haalt eindkwaliteit niet | F2 vóór slice-audio; anders `brainstorm` | audio-director |

## 7. Budget en merkcheck

- **Extern budget fase 2**: € 0 voor tools en assets (gratis tools en eigen werk), **plus een reservering voor de formele merkcheck** (A8): rekenadvies **€ 3.750 excl. btw**, de herberekende bovenkant uit de reviews op PR #33 (`naamcheck-wraithstep.md` §4.2); **worstcase ≈ € 4.800 excl. btw** als een kantoor per klasse rekent (§4). Het bedrag dat geldt, besluit de CEO in #51 (vraag 3).
- **Subsidie**: fase 2 rekent met **€ 0** (`subsidies.md` §5). VAF-geld is hooguit een meevaller voor fase 3.
- **Volgorde merkcheck** (geld pas uitgeven als de naam blijft): (1) vindbaarheidstoets #44 (Marketing, € 0) → (2) zoekactie TMview/WIPO door de CEO in een gewone browser (€ 0, ± 15 min; vervalt als #44 een nieuwe naam adviseert) → (3) 2–3 offertes voor alle vier klassen samen → (4) betaalde merkcheck, pas vlak vóór een CEO-besluit over de eerste publieke uiting.
- Andere externe kosten (bv. audiotools, een boekhouder voor de vennootschap) vragen een apart besluit; de EP meldt ze met hun kost.

## 8. Planning (raming)

Indicatief; de dagelijkse planning is van de Producer. Er is geen deadline (besluit #2).

| Blok | Wat | Raming |
|---|---|---|
| Start | Issues T1–T15; T1, T2, T3, T4, T12 | ≈ 2–3 dagen |
| Bewijs eindkwaliteit | F1-scène + visie-review, F2-fragment; GDD v1; T4–T6 | ≈ 1–2 weken |
| Slice | T8–T10, playtests T11 | ≈ 3–5 weken |
| Afronding | Raming per gebied, releasevenster, gate (T15) | ≈ 1 week |

Totaal **≈ 45–70 maak-taken, 6–10 weken** (raming, past bij de roadmap). Bij max. 4 maak-agents per dag (besluit #47) is het theoretische minimum ± 3–4 weken; de rest is review, herstel, brainstorms en wachttijd op CEO-besluiten. De grootste onzekerheden: F1/F2 halen geen 7 (dan herziet de EP de raming) en de wachttijd op CEO-besluiten.

## 9. Scope-wijzigingen

Zelfde procedure als in fase 1 (`fase-1-kader.md` §6): een issue voor de EP met wat, waarom, kost in regie-runs en rollen, en welk exit-criterium het raakt. Visie, totale scope, budget of timing gaan als `ceo-beslissing` naar de CEO.

**Nieuw ten opzichte van de roadmap v1.2 (fase 2)**, met kost:

| Wijziging | Waarom | Kost |
|---|---|---|
| Visie-review P2 op de F1-scène (A9) | Kwaliteit ≥ 7 alleen is te smal (CD en SM op PR #34) | ≈ 0 runs (CD, binnen een reviewrun) |
| Akkoord Audio Director op F2 (A10) | SM-punt 5 op PR #34 | ≈ 0 runs (eerste taak in T2) |
| A2 en A3 als expliciete taken (T4, T3) | Open punten zonder issue (risico.md §6) | ≈ 1 run TD/GPM + ≈ 1 run LGD, binnen T3/T4 |
| Vindbaarheidstoets #44 (T12) | R24; vóór de betaalde merkcheck | ≈ 1 run Marketing, € 0 |
| Lokalisatie inbouwen (T14), alleen na CEO-besluit | VAF-eis Nederlandse versie | ≈ 1 run; totaal NL-versie ≈ 4–7 runs + mogelijke externe post over fase 2–4 |
| F4b: CEO speelt de slice + gedragsmaat R3 | Fase 2 toetste nergens of de slice leuk is (Lead-review CD op PR #50) | ± 1 uur CEO-tijd, ≈ 0 runs (grens binnen T3, meting binnen T11) |
| VAF-dossier (T13), alleen als de VAF-route openblijft | Route (c) | ≈ 2 runs BLA + bijdragen CD, EP, Marketing; € 0 |

**Open punten** (één regel per punt, de volgende versie neemt ze mee):
- T1 en T9 werken de setting uit; de BLA toetst de formulering aan art. 4 in T13.
- De VAF-deadlines 2027 (A16) volgen van de CEO; de Producer plant T13 daarop.

### Logboek
| Versie | Datum | Wijziging | Kost |
|---|---|---|---|
| 0.1 | 2026-11-08 | Concept, bijlage bij het gate-voorstel fase 1 (#10); Lead-review CD op PR #50: F4b (is de slice leuk), wie test (F4), toon in T9 en F7, setting-voorstel in T13 | F4b: ± 1 uur CEO-tijd, ≈ 0 runs |
