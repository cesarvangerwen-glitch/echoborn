# Risicoregister *Wraithstep* (werktitel, voorheen *Echoborn*)

Versie 1.0 · 2026-11-08 · Eigenaar: Producer · Issue: #9 · Lead-review: Executive Producer
Exit-criterium: E7 (`docs/productie/fase-1-kader.md` §3) · Bronnen: fasekader §5 (R1–R10), `docs/productie/roadmap.md`, `docs/tech/ontwerp.md` (§6, §10, §11), `docs/design/kernloop.md` en `gdd.md` v0.2, `docs/art/stijltests.md`, `docs/business/naamcheck.md`, `docs/concept/pitch.md` v0.2, de reviews op PR #11, #12, #13, #16, #17, #22, #23, en de CEO-besluiten #2, #18 en #24 (`docs/beslissingen.md`).

Werkaannames die dit document gebruikt: budget fase 1 € 0 extern (EP, fasekader §2) en een raming van 7–10 regie-runs voor fase 1 (EP, fasekader §7). Alle andere uitgangspunten zijn CEO-besluiten.

## 1. Samenvatting

- **21 risico's**: R1–R10 uit het fasekader, met hun actuele kans en impact, en 11 nieuwe (R11–R21) uit de spike (#5), de kernloop (#6), de stijltests (#7), de naamcheck (#8), de werktitel (#24) en de reviews.
- **8 risico's met impact H** (R1, R2, R3, R5, R9, R10, R12, R20). Elk heeft een maatregel die al loopt, in een gemergd document of in een open issue, en één eigenaar.
- **Wat sinds het fasekader veranderd is**: de spike heeft R1 verkleind (de echo herhaalt exact, op 0 px). Het stijlbesluit 2D (#18) en de regel "één schaduwlichaam" (C-01) verkleinen R2. R4 is voor *Echoborn* **opgetreden** (een actieve game met dezelfde naam) en opgelost met de nieuwe werktitel *Wraithstep* (#24). Daarvoor komt een kleiner restrisico terug: op *Wraithstep* is nog geen merkcheck gedaan.
- **Grootste open risico's**: R5 (art op eindkwaliteit, H/H, nog niets bewezen), R12 (de echo is na elke kamerwissel 10 s Leeg, raakt pillar 1) en R21 (niet-blokkerende reviewpunten raken na een merge zoek).
- **Acties zonder issue** staan in §5. Daar wacht iemand op, zonder dat er een taak voor is.

## 2. Schaal en status

| | L (laag) | M (midden) | H (hoog) |
|---|---|---|---|
| **Kans** | Onwaarschijnlijk in deze of de volgende fase | Kan gebeuren; er is een concreet scenario | Gebeurt waarschijnlijk zonder maatregel, of gebeurt al |
| **Impact** | Hooguit een run extra, geen deliverable geraakt | Een deliverable of mijlpaal schuift, of een fase kost merkbaar meer werk | Raakt een pillar, de kernfantasie, een exit-criterium of de haalbaarheid van de game |

**Status**: `open` (nog geen maatregel loopt) · `lopend` (de maatregel loopt, het risico blijft) · `verkleind` (de maatregel heeft gewerkt, het risico blijft bewaakt) · `opgetreden` (het risico is gebeurd, zie de toelichting) · `gesloten` (het risico speelt niet meer).

"De maatregel loopt" betekent: hij staat in een gemergd document, of er is een open issue met een eigenaar. Een voornemen zonder issue telt niet en staat in §5.

## 3. Register

ID's R1–R10 komen uit het fasekader. De TD gebruikt in `ontwerp.md` eigen nummers (R1–R7 in §10, C1–C8 in §6); die heten hier *ontwerp-R6*, *C7* enzovoort.

### 3.1 Uit het fasekader (R1–R10)

| ID | Risico | Kans | Impact | Maatregel (loopt al) | Eigenaar | Status |
|---|---|---|---|---|---|---|
| R1 | De echo herhaalt niet exact (physics niet deterministisch, framerate-afhankelijk), waardoor puzzels onbetrouwbaar worden | **L** (was M) | H | Spike gemergd (PR #13): toestand opnemen als bron, vaste tick van 60 Hz, één `Sim` als klok, 7 headless tests groen, echo exact op 0,000000 px, ook met 2 spelers. Rest: input-replay is alleen bewezen op Linux x86_64 met Godot 4.6.3 (ontwerp-R1); bij elke engine-update de tests draaien, Windows-run in fase 2 (Engine & Platform Programmer). De nieuwe tickvolgorde van E-07b is apart gezet als R11. | technical-director | verkleind |
| R2 | Co-op wordt onleesbaar: 2 spelers + echo + vijanden op één gedeelde camera | **L** (was M) | H | Stijlbesluit 2D (#18): harde laaggrens, "vol = levend, hol = echo". Er is nooit meer dan één schaduwlichaam: P2 *is* de schaduw (gdd C-01), dus het lastigste geval uit de stijltests (P2 naast echo s2) komt in het spel niet voor. P1 bepaalt de camera, P2 zit aan een leiband (C-07). Loopt nog: art bible v0 (#20) met de drie objectsoorten (gedeeld, licht, schaduw), herkenbare lichtbronnen en de amber-regel (ΔE 30/25). **Eigenaar gewijzigd** van lead-game-designer naar art-director, omdat het werk dat openstaat in de art bible zit. | art-director | lopend |
| R3 | De draai is niet in één zin uit te leggen, of voelt solo als "trucje" en in co-op als "tweede speler zonder eigen doel" | M | H | Pitch v0.2 gemergd (PR #22) met toetsbare pillars. De Visie-review op de kernloop staat op *past* (PR #16). De 3 playtestvragen staan in gdd §5. Loopt nog: #25 (logline-zin, enkelvoudige toetsvraag voor pillar 1). Fase 1 verkleint dit risico **alleen op papier**; de echte toets is de verticale slice in fase 2, en het gate-voorstel (#10) zegt dat zo. | creative-director | lopend |
| R4 | De naam botst met een bestaande game of merk | M | M | **Voor *Echoborn* opgetreden**: een actieve game met dezelfde naam in hetzelfde genre, een US-merkaanvraag in klasse 41 en bezette domeinen (naamcheck §2). Opgelost met de nieuwe werktitel *Wraithstep* (#24). **Restrisico voor *Wraithstep***: alleen de korte check van de CD in #24 (Steam 0, itch.io geen titel, websearch geen exacte game, .com vrij, peildatum 2026-11-08). Er is nog geen USPTO-, EUIPO- of BOIP-check en ook geen check door de Business/Legal Advisor. Loopt: #25 (naam doorvoeren), besluit 3A (formele merkcheck door een specialist vóór de eerste publicatie met de naam). Er wordt niets gepubliceerd of geregistreerd. Nog nodig: korte check op *Wraithstep* door de BLA (§5, actie A1) en budget voor de specialist (§5, A8). | business-legal-advisor | lopend (*Echoborn*: opgetreden) |
| R5 | Code-gegenereerde art haalt het niveau van een goede indie-release niet | H | H | 2D gekozen, onder meer omdat het met ons team en onze tools haalbaar is (stijltests §5, §7). De stijltests zijn placeholder en bewijzen de eindkwaliteit nog niet. De SM zag zwakke plekken: de lantaarn leest niet als lichtbron, en een 2D-look wordt sneller generiek. Loopt: #20 (art bible v0, met een tegenmaatregel tegen een generieke look als eis). Bij twijfel volgt een `brainstorm`-issue met de CEO (`WERKWIJZE.md` §9). Nog nodig: de roadmap koppelt "eindkwaliteit art en audio" in de slice nog niet aan dit risico (SM-punt 5 op PR #12, §5 actie A5). Voorstel: art bible v0 bevat één scène op beoogde eindkwaliteit, beoordeeld met de rubric (Kwaliteit ≥ 7), vóórdat het slice-art-werk start. | art-director | lopend |
| R6 | Het budget per fase wordt pas bij de gate gevraagd, waardoor fase 2 niet op tijd te plannen is of subsidiedeadlines gemist worden | M | M | Budgetaanvraag fase 2 is een vaste vraag in het gate-voorstel (#10). Subsidieonderzoek loopt (#19, BLA). Nieuw: de formele merkcheck (besluit 3A in #24) is een betaalde dienst en moet in een fasebegroting (A8). Let op: #19 vraagt `docs/zakelijk/subsidies.md`, maar de EP koos in de review van PR #23 voor `docs/business/` (A7). | executive-producer | lopend |
| R7 | De reviewketen (maken → Lead → SM → merge, ≥ 3 runs per deliverable, max. 3 maak-agents per run) vertraagt de fase | **M** (was H) | M | Kleine deliverables, één per issue; voorrang voor blokkerend werk. Stand na 3 runs: #4, #5, #6, #7 en #8 zijn gemergd, zonder afgekeurd werk. Alleen #9 en #10 resten nog, dus fase 1 ligt binnen de raming van 7–10 runs. De wachttijd op CEO-besluiten bleef binnen één run (#18, #24). Zie ook R21. | producer | lopend |
| R8 | Scope-sluip: rollen beginnen aan fase-2-werk vóór de gate | **H** (was M) | M | Buiten-scope-lijst in fasekader §2; elke uitbreiding via §6. **Signaal**: #20 (art bible v0 en assetlijst) staat op `fase:1-concept`, terwijl het fasekader de art bible expliciet buiten scope zet ("fase 2, na de stijlkeuze"). Er is geen scope-wijziging via §6 voor gedaan. #21 (lichtmeting Deck) is te verdedigen als risicoverkleining (C7), maar valt ook niet onder E1–E8. Maatregel: de EP beslist via §6 of #20 en #21 in fase 1 mogen, met de kost erbij, of zet ze op `fase:2-preproductie` (A6). | executive-producer | lopend |
| R9 | De 10 seconden zelf voelen te lang of te kort; afwijken is een CEO-besluit | M | H | De duur is parameter D in de gdd (§2.9: 360/600/840 ticks), met een debugschakelaar in het prototype (gdd §4.1). De spike ondersteunt een variabele capaciteit (`EchoRecorder`). Playtestvraag 1 meet het in fase 2. Wijkt de beste waarde af van 10 s, dan volgt een `ceo-beslissing` (voorbereid door de CD). De werktitel *Wraithstep* legt geen duur vast (*Tenshade* viel daarom af). | lead-game-designer | lopend |
| R10 | Co-op maakt de puzzels triviaal, omdat een live schaduwspeler meer kan dan een opname (pillar 3) | M | H | E2b: kernloop §7 legt vast dat P2 alle beperkingen van de echo houdt. L-02 sluit co-op-only content uit. Playtestgrens: co-op niet meer dan 2× zo snel als solo (gdd §5, vraag 3). Visie-review: *past* (PR #16). In fase 2 wordt elke slice-puzzel in beide modi getest (zie R16 voor de kosten daarvan). | creative-director | lopend |

### 3.2 Nieuw (R11–R21)

| ID | Risico | Kans | Impact | Maatregel (loopt al) | Eigenaar | Status |
|---|---|---|---|---|---|---|
| R11 | **Tickvolgorde en objectdetectie.** E-07b (gdd) draait de stapvolgorde van de spike om (eerst de schaduw, dan P1). Daarnaast werkt een `Area2D` zijn overlap pas ná `_physics_process` bij, dus drukplaten en zones lopen één tick achter. Dan slagen E-06 en E-13 niet ("plaat precies 30 ticks aan"), en zijn echo-puzzels op de tick niet meer exact. | M | M | De TD bevestigt E-07b in #14 (zie het dagrapport in #1). Nog nodig: SM-punt 2 op PR #16 ("objecten lezen de schaduw met directe `intersect_shape`-queries, of accepteer één tick vertraging en zet de tests daarop") staat niet in #14 (A2). | technical-director | lopend |
| R12 | **De echo is te vaak Leeg.** Na elke kamerwissel, respawn of breek is de echo 600 ticks weg (E-04a). Bij 100+ kamers is het tweede lichaam tijdens gewoon verkennen vaak afwezig. Volgens de CD en de SM is dit het grootste visierisico voor pillar 1. | M | H | Vastgelegd in de gdd v0.2: grote verkenningskamers (L-07), testkamer V1, playtestgrens "≤ 40 % van de tijd Leeg" (vraag 1), en een alternatief achter de hand: de echo volgt je door de deur (O-5, LGD met TD). Een debugteller "ticks Leeg" per kamer staat in gdd §4.1. | lead-game-designer | lopend |
| R13 | **Open ontwerpvragen die een pillar raken.** (a) De vierde vaardigheid *Ankeren* past alleen als O-3 zowel met C-01 (max. twee lichamen) als met pillar 3 klopt. Anders is er een andere vaardigheid nodig, terwijl de eindboss-poort alle vier vraagt (K-04). (b) De pitch belooft dat bosses je echo lezen, maar E-14 maakt de echo onzichtbaar voor vijanden (O-1). | M | M | Belegd als O-1 (Combat Designer) en O-3 (Systems Designer, LGD) in gdd §2.11, met de voorwaarde van de CD op PR #16. Nog nodig: de eis "bosses lezen de echo" en de Ankeren-voorwaarde staan nog niet in de gdd (EP-punt 7 en SM-punt 1 op PR #16, A3). | lead-game-designer | lopend |
| R14 | **Positionering.** De echo-mechaniek kennen spelers al uit puzzelgames (*Me and My Shadow*, *Echo Shift*). USP 1 houdt alleen stand door de combinatie (metroidvania + tweede lichaam + lokale co-op). Voor USP 3 en 4 bestaat een voorganger (*Outland*, 2011). En pixel-metroidvania's zijn een drukke markt. Een claim als "de eerste" is makkelijk te weerleggen. | M | M | Naamcheck §3.4 geeft de tekstnuances. #25 voert ze door in de pitch ("we vonden geen …", *Outland* als referentie, USP 3/4 nuanceren). Het licht-schaduwmotief als handtekening wordt een eis in de art bible (#20). Herhaal de ideecheck vóór een Steam-pagina (naamcheck §6). | creative-director | lopend |
| R15 | **De werktitel leest duisterder dan de toon.** "Wraith" klinkt duisterder dan "duister maar niet gruwelijk, PEGI 12", en mist de tweeledigheid van licht en schaduw (nadeel genoemd in de brainstorm in #24). | M | L | De CD bewaakt de toon in de pitch (besluit #24, opdracht in #25). Raakt de naam bij een publieke uiting toch de toon, dan volgt een nieuwe naamvraag aan de CEO vóór de formele merkcheck. | creative-director | lopend |
| R16 | **Pillar 3 verdubbelt de testlast.** Elke puzzel moet in solo én in co-op getest worden (R10, roadmap fase 2). Met max. 40 echo-puzzelkamers op de kritieke route (kernloop §5) en duo-playtests voor vraag 3 is dat de grootste QA-post in fase 2 en 3. Gemeld door de EP in de review van PR #11. | H | M | De gdd maakt de L-regels deels headless te testen via `ScriptedInput` per testkamer (§4.3), zodat alleen de beleving nog handwerk is. In de sprintplanning plant de Producer per slice-puzzel twee testmomenten (solo en co-op); het QA-testplan in fase 2 neemt dat over. De raming staat in het gate-voorstel (#10). | producer | lopend |
| R17 | **Prestaties op de Steam Deck** met 2D-licht (licht- en schaduwlaag, 2–4 bronnen per kamer, 2 spelers + echo) in de Compatibility-renderer zijn niet gemeten (C7). "Steam Deck verified" is een doel uit besluit #2. | L | M | #21 (lichtmeting met lichtbudget, Technical Artist met de Engine & Platform Programmer). De echo zelf is goedkoop (±24 kB per speler, ontwerp §4). | technical-artist | lopend |
| R18 | **Geen CI**: de tests draaien alleen als een agent of mens ze start, dus een fout in het echo-determinisme kan onopgemerkt blijven (ontwerp-R6). | M | M | De EP is in principe akkoord met GitHub Actions (review op PR #13). Het issue komt in fase 2 (Engine & Platform of Tools Programmer), met een gecachete download en de SHA-512-check. Tot die tijd draait elke review op `game/` de tests zelf (zoals op PR #13). | technical-director | lopend |
| R19 | **Co-op-invoer.** Twee spelers op één toetsenbord (ghosting), een joypad-index die wisselt na opnieuw aansluiten, Steam Input dat apparaten anders nummert (C5). Al gezien in de spike: linker Ctrl triggert de echo van P2 (#14). Daarnaast drop-in en drop-out (C2): drop-out direct nadat P1 op P2 stond, laat de echo meteen breken, wat botst met "naadloos" (SM-punt 3 op PR #16). | M | M | Spike: een inputbron per speler en meedoen/stoppen via de InputRouter (gdd §2.5, C-03, C-05). #14 lost de Ctrl-fout op. In fase 2: een InputRouter op apparaat-GUID en een test met 2 joypads en op de Deck. Nog nodig: SM-punt 3 op PR #16 in C-05 en playtestvraag 3 (A3). | technical-director | lopend |
| R20 | **De productieraming van fase 3 is onzeker.** Max. 4 gebieden × 30 kamers (120), waarvan max. 40 echo-puzzelkamers, plus 5 bosses. De roadmap schat fase 3 op 4–8 maanden, lineair geschaald, zonder raming per gebied (SM-review PR #12). Valt de raming na de slice veel hoger uit, dan raakt dat het budget per fase en de omvang (5–7 uur) uit besluit #2. | M | H | Kernloop §5 legt alle aantallen vast als **maximum**, met een rekensom van 5,1–6,6 uur. De roadmap laat de EP na de slice een raming per gebied voorleggen, plus een releasevenster. De slice is 1 van de 3–4 gebieden: een goede meetbasis. Nog nodig: tellen de terugkeerpoorten (K-01–K-03) mee in 65–80 min per gebied? (SM-punt 4 op PR #16, A3.) | executive-producer | lopend |
| R21 | **Reviewpunten raken zoek na een merge.** Niet-blokkerende punten van Lead en SM komen niet altijd in het document of in een vervolgissue terecht. Voorbeelden: de SM-punten 1–4 op PR #23 (Sundershade/*Sundered*, USPTO voor de alternatieven, Notice of Allowance, vraag 3A) zouden "vóór de merge" verwerkt worden en staan niet in `naamcheck.md`. SM-punten 1–4 en EP-punten 5–9 op PR #16 staan niet in gdd v0.2 en hebben geen issue. SM-punten 3–6 op PR #12 zitten niet in de roadmap. Zo bouwt de volgende rol op een onvolledige basis (zie R11, R13, R19, R20). | H | M | Werkt al waar het gedaan is: #14 (spike) en #25 (pitch) bundelen de open punten van hun PR. Maatregel vanaf nu: de regisseur maakt **bij elke merge** een vervolgissue voor alle open reviewpunten, of noteert in de PR dat ze verwerkt zijn. Voor de punten van nu: zie §5 (A2–A5). Een procesvoorstel voor de werkstroom gaat via de Workflow Lead. | producer | lopend |

### 3.3 Overzicht kans × impact

| Kans \ Impact | L | M | H |
|---|---|---|---|
| **H** | | R8, R16, R21 | R5 |
| **M** | R15 | R4, R6, R7, R11, R13, R14, R18, R19 | R3, R9, R10, R12, R20 |
| **L** | | R17 | R1, R2 |

## 4. Wijzigingen ten opzichte van fasekader §5

| ID | Was | Nu | Waarom |
|---|---|---|---|
| R1 | M/H | L/H | Spike gemergd (PR #13); echo exact, ook met 2 spelers; toestand opnemen maakt de echo ongevoelig voor wereldwijzigingen. |
| R2 | M/H, lead-game-designer | L/H, art-director | 2D gekozen (#18); C-01 laat nooit drie lichamen toe; C-07 regelt de camera. Wat openstaat is art-werk (#20). |
| R4 | M/M | M/M, *Echoborn* opgetreden | Naamcheck vond een botsing; CEO koos *Wraithstep* (#24). Restrisico: geen merkcheck op de nieuwe naam. |
| R7 | H/M | M/M | 5 deliverables in 3 runs gemergd, niets afgekeurd; de fase ligt op de raming. |
| R8 | M/M | H/M | #20 (art bible) loopt als fase-1-werk, terwijl het fasekader de art bible buiten scope zet. |
| R3, R5, R6, R9, R10 | | ongewijzigd | Maatregelen bijgewerkt naar de stand van 2026-11-08. |

## 5. Acties zonder issue

Deze acties volgen uit het register. Er is nog geen issue voor, dus niemand zou er zonder deze lijst op wachten. De regisseur maakt de issues aan (of de EP besluit dat het niet nodig is).

| # | Actie | Voor rol | Raakt | Voorstel |
|---|---|---|---|---|
| A1 | Korte check op *Wraithstep*: Steam, itch.io, consoles, USPTO (alle klassen, ook 9 en 41) en, waar bereikbaar, TMview/WIPO; socials. Werk `naamcheck.md` bij met een paragraaf over de nieuwe werktitel. | business-legal-advisor | R4 | Nieuw issue, fase 1, vóór de gate (#10, vraag "Naam") |
| A2 | Neem SM-punt 2 op PR #16 (objectdetectie via queries of één tick vertraging) mee in de bevestiging van E-07b. | technical-director | R11 | Comment in #14 |
| A3 | Vervolgissue voor de open reviewpunten op PR #16: EP-punten 5–9 (o.a. "binnen N ticks", laag 7, C-04-test, L-03, O-1, Ankeren-voorwaarde) en SM-punten 1, 3 en 4 (drop-out na staan op P2, terugkeertijd in de rekensom). | lead-game-designer | R13, R19, R20 | Nieuw issue, gdd v0.3; kan in fase 2 met de prototype-issues |
| A4 | De SM-punten op PR #23 zijn deels achterhaald door #24 (Hindshade/Sundershade zijn niet gekozen). Wat blijft: de Notice of Allowance markeren als "niet onafhankelijk bevestigd" en klasse 9 bij M1 vermelden. | business-legal-advisor | R4, R21 | Meenemen in A1 |
| A5 | Fasekader v1.2 / roadmap v1.2: de SM-punten 3–6 op PR #12 (de raming fase 2 als raming markeren, visie-review en playtest solo + co-op per gebied-mijlpaal in fase 3, eindkwaliteit in de slice koppelen aan R5, de stand-kolom) en de oude toetsvraag van pillar 2 in E3 (EP-punt 17 op PR #22). | executive-producer | R5, R21 | Meenemen in #10 of een kort eigen issue |
| A6 | Scope-besluit (fasekader §6): mogen #20 (art bible v0) en #21 (lichtmeting) in fase 1, met de kost in runs, of verschuiven ze naar `fase:2-preproductie`? | executive-producer | R8 | Comment in #20 en #21, logboek fasekader |
| A7 | Pad van het subsidieonderzoek gelijktrekken: #19 vraagt `docs/zakelijk/`, de EP koos `docs/business/` (review PR #23). | business-legal-advisor | R6 | Comment in #19 |
| A8 | Budget voor de formele merkcheck door een specialist (besluit 3A in #24) opnemen in de fasebegroting waarin de eerste publicatie met de naam valt. | executive-producer | R4, R6 | Meenemen in de budgetaanvraag (#10) |

## 6. Beheer

- **Wie**: de Producer beheert dit register. Elke rol mag een risico melden met een comment in het issue van het register, of in zijn eigen PR met de tekst "risico voor het register". De Producer neemt het op in de volgende versie.
- **Wanneer**: de Producer loopt het register na bij elke regie-run waarin iets gemergd wordt dat een risico raakt, en in elk geval bij elke gate. Het fase-statusrapport (E8, #10) neemt de risico's met impact H over.
- **Regels**: elk risico heeft één eigenaar (rol-slug). Een risico met impact H heeft altijd een maatregel die al loopt (§2). Een risico gaat pas naar `gesloten` met een verwijzing naar het bewijs. Raakt een risico visie, scope, budget of timing en is er een keuze nodig, dan maakt de EP er een `ceo-beslissing`-issue van (fasekader §6).
- **Geen deadline**: besluit #2 legt geen deadline vast. "Vertraging" betekent hier: een mijlpaal schuift ten opzichte van de raming.

## 7. Definition of Done (#9)

- [x] R1–R8 uit het fasekader staan erin, met actuele kans en impact (§3.1, §4). R9 en R10, die E7 ook vraagt, staan er ook in.
- [x] Elk risico met impact H (R1, R2, R3, R5, R9, R10, R12, R20) heeft een maatregel die al loopt, en één eigenaar (§3).
- [x] De risico's uit de spike (#5) zijn verwerkt: R1, R11, R17, R18, R19. Die uit de naamcheck (#8) ook: R4, R14. De nieuwe werktitel (#24) is verwerkt in R4 en R15.

## 8. Wijzigingen

| Versie | Datum | Wat |
|---|---|---|
| 1.0 | 2026-11-08 | Eerste versie: R1–R10 uit het fasekader bijgewerkt, R11–R21 toegevoegd, acties zonder issue A1–A8. |
