# Fasekader fase 2: Preproductie

Versie 0.4 · 2026-11-12 · Eigenaar: Executive Producer · Issues: #57, [#161](https://github.com/cesarvangerwen-glitch/echoborn/issues/161), [#183](https://github.com/cesarvangerwen-glitch/echoborn/issues/183) · Lead-review: Creative Director

**Status: geldt sinds besluit #51** (deel 1 en 2: 1A, 2A, 7A, 8A), bijgesteld na besluit [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124) (2026-11-11, 1B: de CEO speelt F0 alleen solo) en na drie CEO-besluiten van 2026-11-12 (comments in #80, `docs/beslissingen.md`): [besluit 2026-11-12 (1)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201) **fase 2 loopt parallel, ook bouwen**: de slice wacht niet meer op F0 (wijzigt #51: 2A); [besluit 2026-11-12 (2)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201) **de CEO test alleen bij mijlpalen** (§4, mijlpaaltest); [besluit D = 60](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822384889) **echo-staart 1 s (D = 60 ticks)** als werkaanname, bereik **1–3 s** (was 1,5–3 s, #51: 8A).

**Werkaannames die dit kader gebruikt** (§5): D = 60 en het bereik 1–3 s zijn een CEO-besluit *als werkaanname* (nog niet gespeeld en niet met de bots gemeten); extern budget fase 2 € 0 (§7); totaalbudget en releasevenster volgen per fase (`beslissingen.md`). **Werkaanname EP**: de indeling in mijlpaaltests MT1–MT3 (§4), de regel tegen weggooiwerk (§4) en alle runs en ramingen (§2, §8, §9) zijn inschattingen van de EP. Basis: pitch v0.4 (`docs/concept/pitch.md`, §4, §10, §12). Werktitel *Polderlight* (besluit #96); niet publiek vóór de formele merkcheck (besluit #24, 3A).

## 1. Doel

Aan het eind van fase 2 weet de CEO **of de draai speelbaar en leuk is** en **wat de productie kost**. Fase 2 beantwoordt vier vragen. Het werk eraan loopt **parallel** ([besluit 2026-11-12 (1)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201)); de gate (F8) vraagt alle vier beantwoord:

0. **Vloeit het?** Een **grijze flow-kamer** (sprongketen, merk-arena, één gemaal; placeholder-art) haalt de drie flownormen van pillar 1 (pitch §4), **solo**, op D = 60. Dit is de eerste mijlpaal (#51: 2A), maar **geen startvoorwaarde meer voor de slice** ([besluit 2026-11-12 (1)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201)). De co-op-normen toetst de slice (F4b; besluit #124: 1B).
1. **Speelt het?** Een verticale slice (polderwijk met het eerste gemaal en de Gemaalmeester), solo en co-op, beantwoordt de playtestvragen (gdd §5, herzien in T3a): houdt de staart van 1 s (D = 60, bereik 1–3 s; R9, R-V1), hoe vaak de echo Leeg is (R12, R-V3) en of co-op de balans scheeftrekt of iemand laat wachten (R10, R-V5).
2. **Halen we eindkwaliteit?** Art en audio van de slice halen het niveau van een goede indie-release (R5, R22), eerst bewezen in één scène en één fragment.
3. **Wat kost de rest?** Een productieraming per gebied en een voorstel voor een releasevenster (besluit #2, R20).

## 2. Scope

### Binnen scope

Elke regel is **één issue** voor de Producer (T1 bestaat al: #20). "Na" = moet gemergd zijn vóór de taak start (behalve waar anders staat). Runs = maak-taken (raming EP, inclusief herstel in dezelfde run).

**A. Parallel vanaf de start**

| # | Taak | Eigenaar | DoD | Na | Runs | Raakt |
|---|---|---|---|---|---|---|
| T1 | **Art bible v0 + assetlijst** (#20) met **één scène op eindkwaliteit** | art-director (met environment-artist) | Art bible met setting (polder, gemaal, water als beeld, geen speellaag), de drie aandachtspunten uit PR #17, en als leesbaarheidseis: grijze beginstaat, schaduwmerk en finisher-echo (pitch §12, R-V6). Scène: SM-rubric Kwaliteit ≥ 7 + `Visie-review: past` op P2 | — | 4–6 | F1, R2, R5 |
| T2 | **Audiorichting + één referentiefragment** (bv. echo of merk-aftelling met het carillon) | audio-director (met composer-sound-designer) | Eerste stap: AD bevestigt de eis van F2 (A10). Fragment: Kwaliteit ≥ 7 | — | 2–3 | F2, R22 |
| T3a | **Echo-regels v0.4 + flow-kamer-spec** in `gdd.md` | lead-game-designer (met combat-designer) | E-02 (staart D = 60 ticks, bereik 60–180 = 1–3 s, [besluit D = 60](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822384889); was ± 120, bereik 90–180; merksprong), E-04a, E-07a (springplank), E-08b, E-14 (schaduwmerk), testkamers → flow-kamer (sprongketen, merk-arena, één gemaal), waarden voor de flownormen (1)–(3), een **minimale lichtmeter met één gemaal** (vullen, ook via de echo; oppompen zonder stilstand), tests per regel. E-14 en de merksprong nemen de afwijkpunten 1–6 van de ideecheck over of motiveren een afwijking (`docs/business/ideecheck-v0-4.md` §2) | ideecheck #58 | 3–4 | F0, R9, R12, R-V9 |
| T3b | **Co-op 7A**: C-01–C-05 herzien | lead-game-designer (met combat-designer) | Max. twee lichamen; bounce, lancering, merk-combo, vangen in co-op (partner) en solo (echo); optioneel op de route, verplicht bij bosses; gedeelde echo alleen als finisher (laatste 10 s, 8A); tests per regel; C-06 en C-07 blijven | T3a | 2–3 | F0, F3, R10, R-V5 |
| T4 | **Event-systeem + objectdetectie (A2)** | technical-director (met gameplay-programmer) | Keuze `intersect_shape` of één tick vertraging, met de test voor E-07b stap 4–5 en C-01 als DoD-regel (#30) | — | 1–2 | F5, R11 |
| T5a | **Input voor 2 controllers + drop-in/drop-out** | engine-platform-programmer | InputRouter op apparaat-GUID; drop-in/out met test | — | 1–2 | F0, F3, R19 |
| T6 | **CI met headless tests** + Windows-run | tools-programmer | Gecachete download, SHA-512-check, echo-tests groen op Linux en Windows | — | 1–2 | F5, R1, R18 |
| T9 | **Narratief V2** ("het gemaal van herinneringen", pitch §6) | narrative-designer | Wereld, verhaalboog op hoofdlijnen, toon duister maar niet gruwelijk, melancholisch, PEGI 12; de 10 s blijven in het verhaal (bevroren echo's, einde; #51: 8A); water langs de toonregels (R-V7) | — | 2–3 | F3, F7, R-V7 |
| T13 | **VAF-dossier productiesteun fase 3** voorbereiden, **niet indienen** (#51 deel 1: 6B), met het tweede criterium uit categorie I (verzonken stad in de Lage Landen) | business-legal-advisor (met creative-director, executive-producer, marketing-community-manager) | Dossier klaar tot indienen; VAF-deadlines 2027 ingepland (A16) door de Producer | — | 2 | R6, R23 |
| T14 | **Lokalisatie inbouwen** (NL in principe ja, #51 deel 1: 5A) | engine-platform-programmer | Vertaalbestanden, geen tekst in code | T5a | 1 | — |
| T18 | **`risico.md` bijwerken** naar pitch v0.4 | producer | R10 herzien; R-V2, R-V4, R-V7, R-V9, R-V12 opgenomen | — | 1 | — |

**B. Mijlpaal 1: grijze flow-kamer (F0)**

| # | Taak | Eigenaar | DoD | Na | Runs | Raakt |
|---|---|---|---|---|---|---|
| T16a | **Echo-regels in code** | gameplay-programmer | E-02 (staart als parameter in data, standaard D = 60, bereik 60–180 ticks), E-07a, E-08b, E-14, merksprong; tests herschreven en groen | T3a, T4 | 3–4 | F0, R1 |
| T16b | **Flow-kamer bouwen** (grijs, placeholder) | world-level-designer (met gameplay-programmer) | Sprongketen, merk-arena, één gemaal met de minimale lichtmeter uit T3a; meetpunten voor normen (1)–(3) en R-V12 gelogd; maten die van D afhangen (keerzone, richels, B4) nagelopen op D = 60 | T3a, T16a | 2–3 | F0, R-V2, R-V12 |
| T16c | **Co-op 7A in code** | gameplay-programmer | C-01–C-05 volgens T3b; bounce en lancering eerst; tests groen | T3b, T4, T5a, T16a | 1–2 | F0, R10 |
| T7 | **Build op Steam Deck-specificaties** met het lichtbudget uit #21 | engine-platform-programmer (met technical-artist) | Flow-kamer draait op Deck-specificaties; herhaald op de slice (T8a) | #21, T16b | 1–2 | F5, R17 |
| T17 | **Flow-test** | qa-lead (met lead-game-designer) | Plan + rapport: normen (1)–(3) solo; staart D = 60 (bereik 1–3 s); echo ≤ 40 % Leeg; R-V12 (springplank per minuut, aandeel zonder stilstand); de *Nine Sols*-check (ideecheck §2, slotzin) als zwak signaal (M1 van de CEO). Spelers: eerst de **bots** (scripted runs solo op D = 60: normen (1)–(2), Leeg, R-V12; de scripted co-op-runs blijven als meting, niet als slaagcriterium); de CEO speelt pas in mijlpaaltest **MT1** (§4: kaart ± 10–15 min, ± 3–4 runs, score norm 3 solo; [besluit 2026-11-12 (2)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201)). Co-op-normen: zie F4b(c) (besluit #124: 1B) | T16a–c | 2–3 | F0 |

**C. GDD v1 en slice: parallel aan de flow-test** ([besluit 2026-11-12 (1)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201); wijzigt #51: 2A). Werk volgens de regel tegen weggooiwerk (§4).

| # | Taak | Eigenaar | DoD | Na | Runs | Raakt |
|---|---|---|---|---|---|---|
| T3c | **GDD v1 (rest)** | lead-game-designer (met systems-, combat-, world-level-designer) | `gdd.md` §3 (vaardigheden voor beweging/gevecht), L-regels (sprongketens, merk-arena's, gemaal-wijken), lichtmeter + gemaal + waterstand, `kernloop.md` (0 puzzels op de kritieke route, K-04), wereldstructuur 3–4 gebieden, slice-inhoud, de Gemaalmeester, scopeplafond R-V4, de grens voor F4b(b), A3 (open punten PR #16); maten die van D afhangen op D = 60, als formule van D | T3a, T3b; wordt bijgesteld als de bots of een mijlpaaltest iets anders tonen | 4–6 | F3, F4b, R13, R19, R20 |
| T5b | **Architectuur v1**: opslag/laden, AreaLoader (E-04a: echo volgt door deuren) | technical-director (met engine-platform-programmer) | Architectuurdoc + code met tests | T4, T3a | 2–3 | F3, R12 |
| T8a | **Slice bouwen: level en systemen** (polderwijk, eerste gemaal, waterstand) | gameplay-programmer, world-level-designer | Begin tot eind speelbaar solo en co-op met drop-in/out, eerst op placeholder-art; D en de maten die ervan afhangen uit data, niet vast in code of geometrie; bots groen op D = 60 | T3c, T5b (niet meer F0) | 7–9 | F3 |
| T8b | **Boss Gemaalmeester + vijanden** | combat-designer, gameplay-programmer (met animator) | Boss met verplichte echo-/co-op-acties (pitch §4 P1: ≤ ± 5 s stilstand, vensters ≥ 10 frames), co-op-finisher; max. 4 vijandtypes (R-V4); eerst placeholder, vensters die van D afhangen uit data | T3c, T16a (niet meer F0) | 3–5 | F3, R-V4 |
| T8c | **Slice-art** | art-director (met environment-artist, concept-artist, animator, technical-artist) | Slice op eindkwaliteit: Kwaliteit ≥ 7; eindkwaliteit per kamer pas als haar layout **maatvast** is (§4) | **F1**, T8a (layout maatvast; niet meer F0) | 7–9 | F1, F3 |
| T8d | **Slice-audio** | composer-sound-designer | Kwaliteit ≥ 7; geluid dat aan D vastzit (bv. echo-aftelling) pas op maatvaste timing | **F2** (niet meer F0) | 2–4 | F2, F3 |
| T10 | **UX + UI**: HUD (lichtmeter, merk-aftelling), menu's, drop-in/out | ux-designer, ui-artist | UX-spec + UI-assets; HUD eerst placeholder, UI-art pas na F1 en op vastgestelde HUD-elementen | T3c | 2–3 | F3 |
| T11 | **QA-testplan en playtests slice** | qa-lead | Elke slice-kamer en de boss solo én co-op met de bots; F4-metingen; gedragsmaat F4b(b); kaarten van de mijlpaaltests MT2 en MT3 (§4, ± 10–15 min elk) met F4b(a) verwerkt, met de co-op-normen uit F0 (F4b(c)) en de sterke *Nine Sols*-check | T8a–d | 2–3 | F4, F4b |
| T15 | **Raming per gebied, releasevenster, statusrapport en gate-voorstel** | executive-producer | F6 en F8 | T11 | 3 | F6, F8, R20 |

**Totaal: ≈ 61–88 maak-taken** (som van de kolom Runs), € 0 extern; binnen besluit #51 (2A: ≈ 61–88 maak-taken). De v0.4-delta (pitch §12, ≈ 16–18 runs) zit in T1, T3a–c, T5b, T16a–c, T18 en de ideecheck.

Lopende issues die meegaan: #21 (lichtmeting, input voor T7), #61 (werktitel, CEO). De vindbaarheidstoets (#44) is geen taak in fase 2.

### Buiten scope (bewust niet in fase 2)
- De overige gebieden en bosses (fase 3).
- **Puzzels op de kritieke route** (pillar 1). Optionele echo-uitdagingen in beweging pas in fase 3, als de scope het toelaat (pitch §11, vraag 8).
- **Elke publieke uiting**: Steam-pagina, demo, trailer, socials, externe playtest. Elk is een apart CEO-besluit, en een uiting met de naam pas na de formele merkcheck (besluit #24, 3A) en de herhaalcheck (`naamcheck-wraithstep.md` §5.1).
- Een VAF-aanvraag **indienen**, een vennootschap oprichten of een MyVAF-account maken zonder `Besluit:` van de CEO.
- Vertaling naar het Nederlands (fase 4); in fase 2 alleen T14.
- Betaalde assets, plug-ins of diensten (§7); externe audiotools alleen met licentie in `docs/licenties.md`.

### Randvoorwaarden
Alle CEO-besluiten in `docs/beslissingen.md` gelden onveranderd (o.a. #2, #18, #24, #47, #51, #52). Ritme volgens #52: 5 regie-runs per dag, max. 3 maak-agents per run, zelfsturend op ± 92 % van de credits per week.

## 3. Exit-criteria

Fase 2 sluit pas als **alle** criteria F0–F8 (inclusief F4b) gehaald zijn; "bijna" telt niet. "Gemergd" betekent: Lead-review akkoord, bij SM-plichtig werk `status:goedgekeurd` met alle rubricscores ≥ 7, daarna gemergd.

| # | Exit-criterium | Toets | Bewijs |
|---|---|---|---|
| F0 | **Flow-kamer geslaagd** (mijlpaal 1) | In de grijze flow-kamer (T16) haalt T17, **solo** en op **D = 60** ([besluit D = 60](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822384889)), de normen van pillar 1: (1) geoefende speler nergens > ± 5 s stil; (2) echo als springplank of merk-afmaker ≥ ± 1× per 20 s; (3) score "vloeiend/satisfying" ≥ 4 op 5 (de CEO, solo, in mijlpaaltest MT1, §4). Normen (1) en (2), Leeg en R-V12 tonen eerst de **bots** op D = 60; de CEO speelt pas als die groen zijn ([besluit 2026-11-12 (2)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201)). Oppompen bij het gemaal haalt norm (1) (≤ ± 5 s stilstand), en de echo telt mee bij het vullen van de lichtmeter. Staartduur: D = 60 (1 s) per besluit, bereik 1–3 s; geen aparte staartcheck door de CEO. **Co-op hoort niet bij F0** (besluit [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124): 1B): norm (3) co-op, C1–C2, MP-7 en M1 van P2 schuiven naar F4b(c). *Nine Sols*-check: M1 van de CEO telt als zwak signaal (hij koos *Nine Sols* zelf als referentie); noemt hij het merk toch spontaan "net als *Nine Sols*", dan gaat het merk terug naar afwijkpunt 2 (gdd §2.13); noemt hij het niet, dan is de check nog niet gehaald, maar uitgesteld naar F4b(c). CD zet `Visie-review: past` op P1 en P3 (P3 op de solo-echo als partner; P3 met twee mensen in F4b(c)). F0 is een exit-criterium van de fase, **geen startvoorwaarde voor T8** meer ([besluit 2026-11-12 (1)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201)). **Mislukt**: herontwerp door de LGD, getest met de bots; de CEO speelt het pas in de volgende mijlpaaltest. Haalt het herontwerp norm (2) met de bots niet, dan een `ceo-beslissing` (pitch R-V12). Raakt het herontwerp de echo of een kernregel, dan geldt de stopregel van §4 voor het slicewerk. | testrapport QA in een gemergde PR + visie-review |
| F1 | **Art op eindkwaliteit bewezen** | De scène uit T1 scoort Kwaliteit ≥ 7 én krijgt `Visie-review: past` van de CD op pillar 2: de laag is zichtbaar zonder icoon of uitleg, "vol = levend, hol = echo" (A9), met grijze beginstaat. Beide **vóór** slice-art op eindkwaliteit (T8c; F0 is daarvoor niet meer nodig, [besluit 2026-11-12 (1)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201)). Daarna haalt de slice-art zelf ook ≥ 7. | gemergde PR + SM-score + visie-review |
| F2 | **Audio op eindkwaliteit bewezen** | Het fragment uit T2 scoort Kwaliteit ≥ 7 vóór slice-audio (T8d); daarna haalt de slice-audio ook ≥ 7. De eis is concept tot de AD hem bevestigt (A10). | gemergde PR + SM-score + akkoord AD |
| F3 | **Verticale slice speelbaar** | Polderwijk met het eerste gemaal en de Gemaalmeester, van begin tot eind speelbaar solo én in lokale co-op met drop-in/drop-out, op de inhoud uit T3c. | gemergde PR in `game/` + SM-review |
| F4 | **Playtestvragen beantwoord** | Gemeten in de slice, eerst met de bots: houdt de staart van 1 s (D = 60; R9, R-V1); echo ≤ 40 % van de tijd Leeg (R12); co-op ≤ 2× zo snel als solo en niemand wacht (R10, R-V5); normen (1)–(3) van P1 houden ook in de slice. **Elke slice-kamer en de boss** solo en co-op getest (T11). **Wie**: de QA Lead; spelers zijn de bots (scripted runs, elke kamer en de boss) en de CEO in de mijlpaaltests MT2 en MT3 (§4); een externe playtest is een apart CEO-besluit. Ligt de beste duur buiten 1–3 s: `ceo-beslissing`, voorbereid door de CD. | testrapport QA in een gemergde PR |
| F4b | **De slice is leuk** | (a) De CEO speelt de slice in de mijlpaaltests MT2 (solo) en MT3 (solo én co-op), elk met een korte kaart (± 10–15 min, ± 3–4 runs; [besluit 2026-11-12 (2)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201); was ± 1 uur), en vult in: klikmoment van de kernfantasie (ja/nee, waar), wil doorspelen (ja/nee), de echo voelt als bondgenoot of als trucje. (b) Gedragsmaat R3/R-V2: de echo wordt ook **buiten verplichte boss-acties** gebruikt (aandeel springplank-sprongen en merk-ontploffingen op de route); de grens legt de LGD vast in T3c. (c) **Co-op-normen uit F0** (besluit [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124): 1B), in de co-op-runs van MT3 met de P2 die (a) toch al vraagt (op de kamers die de kaart speelt; de rest meten de bots), met de maten en grenzen van het F0-testplan (`docs/qa/testplan-f0.md` §1): norm (3) co-op (MP-5 ≥ 4,0, geen kamer < 3,0), C1–C2 (wachten; partner als hulp of last), MP-7 (a)–(d) (co-op ≥ ½ × solo, niemand wacht). (a), (b) en (c) positief, anders geen gate maar een herzien voorstel. **Sterke *Nine Sols*-check** (R-V9), geen gate-voorwaarde: M1 van P2 telt alleen als sterke check als P2 de referenties niet kent en antwoordt vóór uitleg over het merk; leest het merk dan als *Nine Sols*, dan terug naar afwijkpunt 2 (gdd §2.13) vóór de gate. Is er geen zo'n P2, dan staat R-V9 als open risico in het gate-voorstel (F8), of volgt een externe playtest als apart CEO-besluit (F4). Komt er helemaal geen P2, dan kan F4b(c) niet slagen en legt de EP vóór F8 een `ceo-beslissing` voor. | kaart (comment CEO) + meting in het QA-rapport |
| F5 | **Techniek houdt** | Headless tests groen in CI, ook op Windows (T6); A2 beslist en getest (T4); flow-kamer en slice draaien op Deck-specificaties binnen het lichtbudget (T7). | gemergde PR's + CI-uitvoer |
| F6 | **Raming en releasevenster** | Raming per gebied (runs, rollen, externe kosten), getoetst aan wat de slice kostte, met de kost per vijandtype en boss tegen het scopeplafond (R-V4), plus een voorstel releasevenster (besluit #2). | gemergde PR (EP) |
| F7 | **Visie-review slice** | De CD zet op de slice-PR `Visie-review: past` op alle 3 pillars **en op de toon** (duister maar niet gruwelijk, melancholisch, PEGI 12). | visie-review |
| F8 | **Gate-besluit CEO** | `docs/productie/fase-2-status.md` toetst F0–F7 en F4b met bewijs; een `ceo-beslissing`-issue vraagt productie-scope, releasevenster, budget fase 3 en eventueel indienen bij het VAF. | `Besluit:` van de CEO |

## 4. Startvoorwaarden en volgorde

- **Kritiek pad** (v0.4, [besluit 2026-11-12 (1)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201)): T3a → T16a/b (+ T3b → T16c) → T3c/T5b → T8a/T8b op placeholder → layout maatvast → T8c (na F1) / T8d (na F2) → T11 → T15 → F8. **F0 (T17) loopt parallel** en moet gehaald zijn vóór F8, niet vóór T8.
- **Ideecheck vóór T3a** (R-V9): T3a legt E-14 en de merksprong pas vast met de afwijkpunten uit `docs/business/ideecheck-v0-4.md` §2 (#58); de flow-test (T17) geeft met M1 van de CEO alleen een zwak signaal of het merk als "net als *Nine Sols*" leest; de sterke check (M1 van een P2 die de referenties niet kent) gebeurt in F4b(c) als er zo'n P2 is, anders blijft R-V9 open in F8 (besluit #124: 1B). Gevolg: T8b bouwt het merk in de boss vóór de sterke check; leest het merk in F4b toch als *Nine Sols*, dan kost het herontwerp naar afwijkpunt 2 ≈ +3–5 maak-taken (gdd, code, boss-afstemming) vóór de gate; slice-art en animatie van het merk (T8c) vallen daarbuiten en komen er, als het merk er anders uit moet zien, bovenop (≈ +1–2 maak-taken).
- **Parallel, ook bouwen** ([besluit 2026-11-12 (1)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201), wijzigt #51: 2A): T8a–d en het werk dat erop volgt (T10, T11) wachten niet op F0. Wel blijven de andere afhankelijkheden in §2 (T3c, T5b, F1, F2).
- **Regel tegen weggooiwerk** (risico R29 voorgesteld, §6). Werk dat gebouwd wordt vóór de echo en de kern vastliggen, kan weg als die nog veranderen. Drie regels houden dat klein:
  1. **Eerst placeholder.** Elke slice-kamer en de boss zijn eerst grijs speelbaar en de bots zijn groen, vóór er art op komt.
  2. **Wat van D afhangt, via data.** D, en alles wat ervan afhangt (keerzone, richels, B4, boss-vensters, aftellingen), staat op één plek in data of als formule van D, niet vast in code of geometrie. Een andere D = één waarde wijzigen + bots opnieuw draaien.
  3. **Eindkwaliteit-art pas op vastgestelde maten.** T8c (en UI-art in T10) op een kamer pas als de LGD haar layout **maatvast** verklaart: bots groen op D = 60 en geen open herontwerp voor die kamer.
  **Stopregel**: verandert de echo of een kernregel (nieuw besluit, of een herontwerp na de bots of een mijlpaaltest), dan zet de Producer eindkwaliteitswerk op de geraakte kamers stil tot ze weer maatvast zijn; placeholderwerk loopt door.
- **Mijlpaaltest** ([besluit 2026-11-12 (2)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201)). De CEO speelt alleen bij een mijlpaal: (1) de **bots zijn groen** (CI-tests groen, F5; scripted runs halen de meetbare normen van die mijlpaal op D = 60) én (2) er is een **merkbare stap** (een nieuwe kamer, boss of systeem speelbaar, of art/audio die je ziet of hoort veranderen). Dan maakt de QA Lead een **korte kaart** (± 10–15 min, ± 3–4 runs). Kleine aanpassingen (tuning, bugfix, maten) test het team met de bots, zonder CEO. De QA Lead stelt voor wanneer een mijlpaal klaar is; de Producer plant hem. Verwachte mijlpaaltests in fase 2 (werkaanname EP):
  - **MT1**: flow-kamer op D = 60, solo → F0 norm (3).
  - **MT2**: slice speelbaar op placeholder, met de boss, solo → F4, F4b(a) solo.
  - **MT3**: slice op eindkwaliteit, solo én co-op met P2 → F4b(a)–(c), F7.
  Valt een mijlpaal samen met de volgende (bv. MT1 en MT2 op dezelfde build), dan is het één kaart.
- **Eindkwaliteit eerst** (R5, R22): geen slice-art op eindkwaliteit vóór F1, geen slice-audio vóór F2 (F0 is daarvoor niet meer nodig). Haalt de scène of het fragment geen 7, of twijfelt de AD of de Audio Director: geen slicewerk op die basis, maar een `brainstorm`-issue met de CEO (`WERKWIJZE.md` §9), en de EP herziet de raming (§9). T1 loopt parallel vanaf de start; de F1-eis staat als DoD-regel in #20.
- **T4 en T5a vóór de flow-kamer-code** (T16a, T16c).

## 5. Kwaliteitslat
- Reviewketen volgens `WERKWIJZE.md` §5 (besluit #47). Alle code in `game/` krijgt SM-review.
- Geen CEO-test zonder groene bots; kleine aanpassingen alleen met de bots (§4, mijlpaaltest).
- Visie-reviews van de CD: F0 (P1, P3), F1 (P2), F7 (P1–P3 en toon).
- Elke deliverable noemt de werkaanname die ze gebruikt. Geen puzzel op de kritieke route; elke kamer en boss wordt getoetst met de toetsvraag van pillar 1.

## 6. Belangrijkste risico's

Bron: `docs/productie/risico.md` (Producer, bij te werken in T18) en pitch §10. R29 is een voorstel van de EP; het ID volgt het register. De risico's met impact H en wat fase 2 eraan doet:

| ID | Risico (kort) | Wat fase 2 doet | Eigenaar |
|---|---|---|---|
| R1 | Echo niet exact | CI + Windows-run (T6); tests herschreven (T16a) | technical-director |
| R2 / R-V6 | Co-op, merk en finisher-echo onleesbaar | Leesbaarheidseisen in de art bible (T1); co-op door mensen pas in de slice (F4b(c), besluit #124: 1B), in F0 alleen scripted | art-director |
| R3 / R-V2 | Draai voelt als trucje; echo wordt passief zonder puzzels | Norm (2) in F0; gedragsmaat F4b(b); slice F3, F4, F7 | creative-director |
| R5 | Art haalt eindkwaliteit niet | F1 vóór slice-art op eindkwaliteit; anders `brainstorm` | art-director |
| R9 / R-V1 | Staartduur klopt niet | D = 60 per besluit (nog niet gespeeld of gemeten): bots op D = 60 in F0 en F4, CEO in MT1–MT3; D via data (§4); beste duur buiten 1–3 s → `ceo-beslissing` | lead-game-designer |
| R10 / R-V5 | Co-op wordt chaos, te makkelijk, of de een wacht | Co-op ≤ 2× solo; elke kamer en boss solo en co-op in de slice (F4, F4b(c)); in F0 alleen scripted co-op-runs als meting (besluit #124: 1B) | creative-director |
| R12 / R-V3 | Echo te vaak Leeg | Grens ≤ 40 % (F0, F4); echo volgt door deuren (E-04a, T5b) | lead-game-designer |
| R-V9 | Schaduwmerk lijkt op *Nine Sols* | Afwijkpunten in T3a; zwak signaal in T17 (M1 van de CEO), sterke check in F4b(c) (M1 van P2); octrooiscan in de offerte van de merkcheck (§7) | business-legal-advisor |
| R-V12 | Springplank ligt achter je | Meetpunt in de flow-test; herontwerp vóór een CEO-vraag (F0) | lead-game-designer |
| R20 / R-V4 | Raming fase 3 onzeker; combat duurder dan puzzels | Scopeplafond (T3c), kost per vijandtype en boss gemeten (F6) | executive-producer |
| R22 | Audio haalt eindkwaliteit niet | F2 vóór slice-audio; anders `brainstorm` | audio-director |
| R29 (voorstel, nieuw) | **Weggooiwerk**: slicewerk start vóór F0 ([besluit 2026-11-12 (1)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201)) en kan weg als de echo of de kern nog verandert (K M, I M; raming EP ≈ +2–4 maak-taken met de regel, tot ≈ +7–9 zonder, als slice-art opnieuw moet) | Regel tegen weggooiwerk en stopregel (§4): placeholder eerst, D via data, eindkwaliteit-art pas op maatvaste kamers | executive-producer (Producer neemt het op in `risico.md`) |

## 7. Budget en merkcheck

- **Extern budget fase 2**: **€ 0** (gratis tools en eigen werk; #51 deel 1 en 2A). Fase 2 plant geen publieke uiting (§2), dus ook geen merkcheck.
- **Formele merkcheck** (A8): **€ 3.750 excl. btw**, worstcase **≈ € 4.800 excl. btw**, in de fasebegroting van de **eerste publicatie** (#51 deel 1: 3A). De ideecheck stelt voor er een **korte octrooiscan** op "vertraagde kopie van de spelerfiguur" aan toe te voegen (`ideecheck-v0-4.md` §3, niet blokkerend). De offerte prijst de scan apart; een meerkost boven de raming legt de EP aan de CEO voor vóór de opdracht.
- **Subsidie**: fase 2 rekent met **€ 0** (`subsidies.md` §5). VAF-geld is hooguit een meevaller voor fase 3 en schuift minstens één deadline op (#51 deel 1: 6B).
- **Volgorde merkcheck**: vindbaarheidstoets (#44) → naamkeuze (#61) → zoekactie TMview/WIPO door de CEO (€ 0, ± 15 min) → 2–3 offertes voor alle vier klassen samen, met de octrooiscan apart geprijsd → betaalde merkcheck, vlak vóór een CEO-besluit over de eerste publieke uiting.
- Andere externe kosten (bv. audiotools, een boekhouder voor de vennootschap) vragen een apart besluit; de EP meldt ze met hun kost.

## 8. Planning (raming)

Indicatief; de dagelijkse planning is van de Producer. Er is geen deadline (besluit #2).

**Capaciteit volgens #52.** Ritme: 5 runs × max. 3 maak-agents = **max. 15 maak-taken per dag**. Credits: één maak-taak met reviews kost ≈ 0,25–0,42 M sub-agent-tokens (nulmeting en verwachting in `docs/proces/rapport-week-1.md` §4), met de regisseur (× 1,3) en de ijking 0,6 M per % ≈ **0,55–0,9 % van de week**. Fase 2 (61–88 maak-taken) kost dus ≈ **35–80 % van één weekbudget**, gespreid over 2–3,5 weken. De credits zijn **niet** de bottleneck; dat zijn het kritieke pad en de wachttijd op de CEO. Een stap op het kritieke pad kost ≈ 1–2 runs (maken, Lead-review en herstel in dezelfde run; SM-review en merge soms in de volgende).

| Blok | Wat | Maak-taken | Doorlooptijd |
|---|---|---|---|
| Start | Issues T1–T18 (Producer); A-taken starten | — | ≈ 1 run |
| Mijlpaal 1: flow-kamer (F0) | T3a, T3b → T16a–c → T7, T17; parallel T1, T2, T4–T6, T9, T13, T14, T18, T3c, T5b | ≈ 35–52 | ≈ 4–6 dagen (20–30 runs), incl. MT1 (± 10–15 min CEO) |
| Slice (v0.4: parallel aan F0) | T8a–d, T10, T11 (incl. MT2 en MT3: CEO ± 2 × 10–15 min) | ≈ 23–33 | ≈ 5–8 dagen, start niet meer na F0 maar zodra T3c en T5b gemergd zijn |
| Afronding | T15, gate F8 | 3 | ≈ 1–2 dagen + wachttijd CEO |

Totaal **≈ 61–88 maak-taken, ≈ 2–3,5 weken** (was 6–10 weken bij het ritme van #47). Met het parallelle bouwen (v0.4) wordt de doorlooptijd korter (de slice wacht niet meer op F0; raming EP ≈ −2–4 dagen), tegen het risico van weggooiwerk (R29, ≈ +2–4 maak-taken met de regel van §4). De grootste onzekerheden: (1) een mislukte flow-test (herontwerp met de bots ≈ +4–8 maak-taken; blokkeert de slice niet meer, maar kan slicewerk raken via de stopregel; norm (2) nog eens mislukt = CEO-vraag), (2) F1/F2 halen geen 7 (`brainstorm`, de EP herziet de raming), (3) de wachttijd op CEO-besluiten en -speeltijd (kleiner: alleen mijlpaaltests van ± 10–15 min), (4) code-taken die zwaarder uitvallen dan de nulmeting (dan stuurt de tempo-regel bij en schuift de doorlooptijd, niet de scope).

## 9. Scope-wijzigingen

Zelfde procedure als in fase 1 (`fase-1-kader.md` §6): een issue voor de EP met wat, waarom, kost in runs en rollen, en welk exit-criterium het raakt. Visie, totale scope, budget of timing gaan als `ceo-beslissing` naar de CEO.

**Nieuw ten opzichte van de roadmap v1.2 (fase 2)**, met kost:

| Wijziging | Waarom | Kost |
|---|---|---|
| Visie-review P2 op de F1-scène (A9) | Kwaliteit ≥ 7 alleen is te smal (PR #34) | ≈ 0 runs |
| Akkoord Audio Director op F2 (A10) | SM-punt 5 op PR #34 | ≈ 0 runs (eerste stap in T2) |
| A2 en A3 als expliciete taken (T4, T3c) | Open punten zonder issue | ≈ 1 run TD/GPM + ≈ 1 run LGD |
| Vindbaarheidstoets #44 | R24; vóór de betaalde merkcheck | ≈ 1 run Marketing, € 0 |
| Lokalisatie inbouwen (T14) | NL in principe ja (#51 deel 1: 5A) | ≈ 1 run; NL-versie in totaal ≈ 4–7 runs + mogelijke externe post over fase 2–4 |
| Merkcheck naar de fase van de eerste publicatie | #51 deel 1: 3A | € 0 in fase 2 |
| F4b: CEO speelt de slice + gedragsmaat R3 | Is de slice leuk (Lead-review CD op PR #50) | ± 1 uur CEO-tijd, ≈ 0 runs (v0.4: ± 2 × 10–15 min in MT2/MT3) |
| VAF-dossier (T13), voorbereiden zonder indienen | #51 deel 1: 6B | ≈ 2 runs BLA + bijdragen; € 0 |
| **v0.2: pitch v0.4** (#51: 1A, 7A, 8A): echo-regels, co-op 7A, GDD v1 zonder puzzels (T3a–c, T16a, T16c, T18) | Concept B in de vorm van pitch v0.4 | ≈ 16–18 runs (pitch §12), binnen het totaal |
| **v0.2: grijze flow-kamer als mijlpaal 1** (F0, T16b, T17) | #51: 2A, slice-art pas na een geslaagde flow-test (v0.4: die volgorde vervalt, zie hieronder) | ≈ 4–6 runs + ± 20 min CEO-tijd; doorlooptijd slice-art + ≈ 4–6 dagen later dan parallel |
| **v0.3: F0 alleen solo, co-op-normen naar F4b(c)** (§1, T17, F0, F4b, T11, §4, R2, R10, R-V9) | Besluit [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124) (2026-11-11, 1B): de CEO speelt F0 alleen solo | ≈ 0 runs voor dit kader + ≈ 1 run QA (kaart en testplan, #80); CEO-tijd F0 ± 20 → ± 15 min, F4b blijft ± 1 uur, + ± 10 min van P2 als er een P2 is; risico: Nine Sols-herontwerp na T8b ≈ +3–5 maak-taken, plus ≈ +1–2 voor T8c-art en animatie als het merk er anders uit moet zien (§4) |
| **v0.4: fase 2 parallel, ook bouwen** (§1, §2 C, T8a–d, T10, F0, F1, §4, §6 R29, §8) | [besluit 2026-11-12 (1)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201), wijzigt #51: 2A | ≈ 0 runs voor dit kader; doorlooptijd ≈ −2–4 dagen; risico weggooiwerk ≈ +2–4 maak-taken (tot ≈ +7–9 zonder de regel van §4) |
| **v0.4: CEO test alleen bij mijlpalen** (T17, T11, F0, F4, F4b, §4 MT1–MT3, §5) | [besluit 2026-11-12 (2)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201) | ≈ 1 run QA (testplan, kaarten); CEO-tijd F4b ± 1 uur → ± 2 × 10–15 min; F0 ± 15 → ± 10–15 min |
| **v0.4: staart 1 s (D = 60), bereik 1–3 s** (§1, T3a, T16a, T16b, T17, T3c, F0, F4, R9) | [besluit D = 60](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822384889) | ≈ 1 run LGD (maten op D = 60 nalopen: keerzone, richels, B4) |
| **v0.2: totaal** 45–70 → **61–88 maak-taken**; doorlooptijd 6–10 → **≈ 2–3,5 weken** | #51: 2A en ritme #52 | € 0 |

**Open punten** (één regel per punt, de volgende versie neemt ze mee):
- T1 en T9 werken de setting uit; de BLA toetst de formulering aan art. 4 in T13.
- De VAF-deadlines 2027 (A16) volgen van de CEO; de Producer plant T13 daarop.
- De co-op-balans met de korte staart (solo-echo 1 s naast een live partner, finisher van 10 s) toetst de LGD in de slice (T11, F4b(c)); in de flow-kamer (T17) alleen met de scripted co-op-runs, naast R-V12.
- De P2-vraag voor F4b (wie, en kent die de referenties?) gaat in één `ceo-beslissing` samen met de co-op-sessie van F4b(a), niet als twee aparte vragen.
- Na de co-op-balans in F4b(c) mag F4 de staart (D = 60) heroverwegen binnen 1–3 s; buiten dat bereik: `ceo-beslissing`.
- `docs/design/gdd.md` (LGD): O-8 en §5 vraag 5 leggen de *Nine Sols*-check nog in T17; bijwerken naar "zwak in T17, sterk in F4b(c)" (besluit #124: 1B).
- `docs/productie/risico.md` (Producer): R2/R-V6, R10/R-V5 en R-V9 noemen nog co-op en de *Nine Sols*-check in de flow-kamer; bijwerken naar F4b(c) volgens dit kader (besluit #124: 1B).
- T10 bouwt de HUD eerst als placeholder; UI-art pas na F1 en op vastgestelde HUD-elementen (§4).
- `docs/design/gdd.md` (LGD) rekent de maten van §4.3 voor D = 90, 120 en 180 en noemt D = 120 als werkaanname; bijwerken naar D = 60 en bereik 60–180 ticks (besluit D = 60).
- `docs/qa/testplan-f0-2.md` en de CEO-kaarten (QA): normen (1)–(2) met de bots op D = 60, norm (3) in MT1; F4b-kaart in MT2/MT3 van ± 10–15 min in plaats van ± 1 uur.
- De tokens per maak-taak in fase 2 (vooral code) zijn nog niet gemeten; de EP stelt §8 bij na F0 met het tokenlog.

### Logboek
| Versie | Datum | Wijziging | Kost |
|---|---|---|---|
| 0.1 | 2026-11-08 | Concept, bijlage bij het gate-voorstel fase 1 (#10); Lead-review CD en SM-review op PR #50 | F4b: ± 1 uur CEO-tijd; merkcheck € 0 in fase 2 |
| 0.2 | 2026-11-09 | Na besluit #51 (1A, 2A, 7A, 8A) en pitch v0.4 (#57): F0 grijze flow-kamer als mijlpaal 1; slice-art na F0 én F1; puzzels van de kritieke route (§1, T3, §4, T11/F4, F4b(b), R10); staart 1,5 / 2 / 3 s; co-op 7A; ideecheck (#58) vóór T3a; octrooiscan in de merkcheck-offerte; takenlijst per issue (T1–T18); raming volgens #52 | 61–88 maak-taken, ≈ 2–3,5 weken, € 0 |
| 0.3 | 2026-11-11 | Na besluit [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124) (1B; [#161](https://github.com/cesarvangerwen-glitch/echoborn/issues/161)): F0 slaagt op de solo-normen; norm (3) co-op, C1–C2, MP-7 en M1 van P2 naar het nieuwe F4b(c); *Nine Sols*-check in F0 alleen zwak signaal, sterke check in F4b(c) als er een P2 is die de referenties niet kent, anders R-V9 open in F8 (§1, T17, T11, F0, F4b, §4, §6 R2/R10/R-V9, §9); werktitel *Polderlight* in de kop (#96) | ≈ 0 runs; CEO-tijd F0 ± 15 min; risico ≈ +3–5 maak-taken bij een *Nine Sols*-lezing in F4b |
| 0.4 | 2026-11-12 | Na drie CEO-besluiten van 2026-11-12 (comments in #80; [#183](https://github.com/cesarvangerwen-glitch/echoborn/issues/183)): [besluit 2026-11-12 (1)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201) slice (T8a–d) en vervolg wachten niet op F0, kritiek pad en §2 C bijgewerkt, regel tegen weggooiwerk + stopregel (§4), R29 voorgesteld (§6); [besluit 2026-11-12 (2)](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822410201) mijlpaaltests MT1–MT3 met korte kaart, kleine aanpassingen met de bots (T17, T11, F0, F4, F4b, §4, §5); [besluit D = 60](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822384889) D = 60, bereik 1–3 s (§1, T3a, T16a/b, T3c, T17, F0, F4, R9); werkaannames in de kop | ≈ 0 runs; doorlooptijd ≈ −2–4 dagen; risico weggooiwerk ≈ +2–4 maak-taken; CEO-tijd F4b ± 1 uur → ± 2 × 10–15 min |
