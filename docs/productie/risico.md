# Risicoregister *Wraithstep* (werktitel, voorheen *Echoborn*)

Versie 1.2 · 2026-11-08 · Eigenaar: Producer · Issues: #9 (v1.0–1.1), #32 (v1.2) · Lead-review: Executive Producer
Exit-criterium: E7 (`docs/productie/fase-1-kader.md` §3) · Bronnen: fasekader v1.2 (§2, §3, §5 R1–R10, §6.1), `docs/productie/roadmap.md` v1.2, `docs/tech/ontwerp.md` (§6, §10, §11), `docs/design/kernloop.md` en `gdd.md` v0.2, `docs/art/stijltests.md`, `docs/business/naamcheck.md` v1.1, `docs/business/naamcheck-wraithstep.md` v1.0, `docs/business/subsidies.md` v1.1, `docs/concept/pitch.md` v0.2, de reviews op PR #11, #12, #13, #16, #17, #22, #23, #26, #27, #28, #33, #34, #41 en #42, de issues #20, #25, #29, #30, #35, #36 en #44, `studio/regie/producer-regie.md` v1.3, en de CEO-besluiten #2, #18, #24 en #47 (`docs/beslissingen.md`).

Werkaannames die dit document gebruikt: budget fase 1 € 0 extern (EP, fasekader §2) en een raming van 7–10 regie-runs voor fase 1 (EP, fasekader §7). Alle andere uitgangspunten zijn CEO-besluiten.

## 1. Samenvatting

- **24 risico's**: R1–R10 uit het fasekader, met hun actuele kans en impact, en 14 nieuwe (R11–R24) uit de spike (#5), de kernloop (#6), de stijltests (#7), de naamcheck (#8, #29), de werktitel (#24), het subsidieonderzoek (#19) en de reviews.
- **9 risico's met impact H** (R1, R2, R3, R5, R9, R10, R12, R20, R22). Elk heeft een maatregel die al loopt, in een gemergd document of in een open issue, en één eigenaar. Deze negen neemt het fase-statusrapport (#10) over (§6).
- **Nieuw in v1.2**: audio op eindkwaliteit (R22, H/H), de opbrengst van de VAF-route (c) (R23, PR #28) en de vindbaarheid naast het *Diablo II*-item *Wraithstep* (R24, PR #33).
- **Kleiner sinds v1.1**: R6 en R8 (L/M) en R21 (M/M). Zie §4.2.
- **Grootste open risico's**: R5 en R22 (art en audio op eindkwaliteit, H/H, nog niets bewezen), R12 (de echo is vaak Leeg, pillar 1) en R20 (raming fase 3).
- **Acties** staan in §5; wat nog geen issue heeft, staat in §6 *Open punten*.

## 2. Schaal en status

| | L (laag) | M (midden) | H (hoog) |
|---|---|---|---|
| **Kans** | Onwaarschijnlijk in deze of de volgende fase | Kan gebeuren; er is een concreet scenario | Gebeurt waarschijnlijk zonder maatregel, of gebeurt al |
| **Impact** | Hooguit een run extra, geen deliverable geraakt | Een deliverable of mijlpaal schuift, of een fase kost merkbaar meer werk | Raakt een pillar, de kernfantasie, een exit-criterium of de haalbaarheid van de game |

**Status**: `open` (nog geen maatregel loopt) · `lopend` (de maatregel loopt, het risico blijft) · `verkleind` (de maatregel heeft gewerkt, het risico blijft bewaakt) · `opgetreden` (het risico is gebeurd, zie de toelichting) · `gesloten` (het risico speelt niet meer).

"De maatregel loopt" betekent: hij staat in een gemergd document, of er is een open issue met een eigenaar. Een voornemen zonder issue telt niet en staat in §5.

## 3. Register

ID's R1–R10 komen uit het fasekader. De TD gebruikt in `ontwerp.md` eigen nummers (R1–R7 in §10, C1–C8 in §6); die heten hier *ontwerp-R6*, *C7* enzovoort. De BLA gebruikt in `naamcheck-wraithstep.md` de nummers G1–G5 (games) en M1–M5 (merken).

### 3.1 Uit het fasekader (R1–R10)

| ID | Risico | Kans | Impact | Maatregel (loopt al) | Eigenaar | Status |
|---|---|---|---|---|---|---|
| R1 | De echo herhaalt niet exact (physics niet deterministisch, framerate-afhankelijk), waardoor puzzels onbetrouwbaar worden | **L** (was M) | H | Spike gemergd (PR #13, fixes PR #26): toestand opnemen als bron, vaste tick van 60 Hz, één `Sim` als klok, headless tests groen, echo exact op 0,000000 px, ook met 2 spelers. Rest: input-replay is alleen bewezen op Linux x86_64 met Godot 4.6.3 (ontwerp-R1); bij elke engine-update de tests draaien, Windows-run in fase 2 (Engine & Platform Programmer). Dat de tests zelf betrouwbaar zijn, valt onder R18 (#30). De nieuwe tickvolgorde van E-07b staat apart als R11. | technical-director | verkleind |
| R2 | Co-op wordt onleesbaar: 2 spelers + echo + vijanden op één gedeelde camera | **L** (was M) | H | Stijlbesluit 2D (#18): harde laaggrens, "vol = levend, hol = echo". Er is nooit meer dan één schaduwlichaam: P2 *is* de schaduw (gdd C-01). P1 bepaalt de camera, P2 zit aan een leiband (C-07). **Visie-review van de CD op PR #17: past** op P1–P3 (#36), met drie aandachtspunten voor de art bible: lichtbronnen herkenbaar als bron, het einde van een opgeloste brug eenduidig, en speler 2 naast een echo in beweging toetsen op pc aan de tv. Loopt nog: art bible v0 (#20, fase 2) met die punten, de drie objectsoorten (gedeeld, licht, schaduw) en de amber-regel (ΔE 30/25). | art-director | lopend |
| R3 | De draai is niet in één zin uit te leggen, of voelt solo als "trucje" en in co-op als "tweede speler zonder eigen doel" | M | H | Pitch v0.2 gemergd (PR #22) met toetsbare pillars. De visie-reviews op de kernloop (PR #16) en de stijltests (PR #17, #36) staan op *past*. De 3 playtestvragen staan in gdd §5. Pitch v0.3 (PR #41, #25) heeft de logline-zin en een enkelvoudige toetsvraag voor pillar 1. Fase 1 verkleint dit risico **alleen op papier**; de echte toets is de verticale slice in fase 2. Het fasekader v1.2 (§1, gate-vraag 1) zegt dat zo tegen de CEO. | creative-director | lopend |
| R4 | De naam botst met een bestaande game of merk | M | M | **Voor *Echoborn* opgetreden** (naamcheck §2) en opgelost met de werktitel *Wraithstep* (#24). **Restrisico voor *Wraithstep***, na de korte check van de BLA (#29, PR #33, conclusie **oranje**): in de VS laag (USPTO, alle klassen: 0 merken WRAITHSTEP, M1; geen levend WRAITH-merk voor games, M2; Steam en itch.io: geen game; de domeinen .com/.net/.org/.io/.games/.nl vrij). **In de EU en de Benelux onbekend**: EUIPO, BOIP en WIPO zijn niet doorzocht (M5), en dat is het grootste gat. De YouTube-handle @wraithstep is bezet. Loopt: niets publiek vóór de formele check (besluit #24, 3A; fasekader §2), de post van € 3.750 excl. btw in gate-vraag 3 (#10, A8), en #35 (gratis tussenstap TMview/WIPO met eigenaar en moment, herhaalcheck vóór de eerste publicatie als vaste stap, klasse 28 in de scope). De vindbaarheid naast het *Diablo II*-item staat apart als R24. | business-legal-advisor | lopend (*Echoborn*: opgetreden) |
| R5 | Code-gegenereerde art haalt het niveau van een goede indie-release niet | H | H | 2D gekozen, onder meer omdat het met ons team en onze tools haalbaar is (stijltests §5, §7). De stijltests zijn placeholder en bewijzen de eindkwaliteit nog niet. De SM zag zwakke plekken: de lantaarn leest niet als lichtbron, en een 2D-look wordt sneller generiek. **Vastgelegd in fasekader v1.2 §6.1 en roadmap v1.2, fase 2 (PR #34)**: art bible v0 (#20) bevat één scène op beoogde eindkwaliteit, beoordeeld met de rubric (Kwaliteit ≥ 7), vóórdat het slice-art-werk start. Haalt die scène geen 7, dan geen slice-art op die stijl, maar een `brainstorm`-issue met de CEO (`WERKWIJZE.md` §9) en een herziene slice-raming. Nog nodig: de eis overnemen in `fase-2-kader.md`, met daarbij een visie-review op de leesbaarheid van pillar 2 (A9). | art-director | lopend |
| R6 | Het budget per fase wordt pas bij de gate gevraagd, waardoor fase 2 niet op tijd te plannen is of subsidiedeadlines gemist worden | **L** (was M) | M | Subsidieonderzoek gemergd (PR #28, `subsidies.md` v1.1): **fase 2 rekent met € 0 subsidie**, dus fase 2 hangt aan geen enkele subsidiedeadline (route c, §5). Gate-vraag 3 in fasekader v1.2 bevat de budgetaanvraag fase 2, de VAF-drempels, bevestiging V en vragen 1–3, en de merkcheck-post van € 3.750 excl. btw als reservering (A8). De budgetaanvraag zelf zit in #10. Wat overblijft: de VAF-deadlines 2027 zijn nog niet bekend, en die bepalen of we al aan het eind van fase 2 indienen (#35, punt 2). De Producer plant ze in zodra ze er zijn (A16). Het risico dat de route zelf weinig oplevert, staat apart als R23. | executive-producer | lopend |
| R7 | De reviewketen (maken → Lead → SM → merge) vertraagt de fase | M (was H) | M | Kleine deliverables, één per issue; voorrang voor blokkerend werk. **Besluit #47**: twee runs per dag (ochtend maken, avond afronden), max. 4 maak-agents per dag; SM-review alleen voor CEO- en gatewerk, code in `game/` en een steekproef van 1 op 3, anders telt Lead-akkoord als goedgekeurd; een Lead-review "niet akkoord, klein" wordt in dezelfde run hersteld (`producer-regie.md` v1.3). In fase 1 keurde de SM niets af; wel hadden PR #12, #16 en #28 een tweede Lead-ronde nodig. Volgorde volgens fasekader v1.2: #32 vóór #10, #21 ná #10. De wachttijd op CEO-besluiten bleef binnen één run (#18, #24). Zie ook R21. | producer | lopend |
| R8 | Scope-sluip: rollen beginnen aan fase-2-werk vóór de gate | **L** (was M) | M | Buiten-scope-lijst in fasekader §2; elke uitbreiding via §6. **Besluit EP** (fasekader v1.2 §6.1, PR #34): #21 mag in fase 1 als risicoverkleining (C7), ≈ 1 run, na #10; #20 gaat naar fase 2. **Bewijs dat de maatregel werkte**: #20 staat op `fase:2-preproductie` (label gezet door de regisseur, comment in #20), zonder werk eraan. De scope-tabel van fasekader v1.2 dekt alle lopende fase-1-issues (CD en SM controleerden dat in de reviews op PR #34). | executive-producer | verkleind |
| R9 | De 10 seconden zelf voelen te lang of te kort; afwijken is een CEO-besluit | M | H | De duur is parameter D in de gdd (§2.9: 360/600/840 ticks), met een debugschakelaar in het prototype (gdd §4.1). De spike ondersteunt een variabele capaciteit (`EchoRecorder`). Playtestvraag 1 meet het in fase 2 (roadmap v1.2: testen met 6, 10 en 14 s). Wijkt de beste waarde af van 10 s, dan volgt een `ceo-beslissing` (voorbereid door de CD). De werktitel *Wraithstep* legt geen duur vast. | lead-game-designer | lopend |
| R10 | Co-op maakt de puzzels triviaal, omdat een live schaduwspeler meer kan dan een opname (pillar 3) | M | H | E2b: kernloop §7 legt vast dat P2 alle beperkingen van de echo houdt. L-02 sluit co-op-only content uit. Playtestgrens: co-op niet meer dan 2× zo snel als solo (gdd §5, vraag 3). Visie-review: *past* (PR #16). In fase 2 wordt elke slice-puzzel in beide modi getest, en in fase 3 krijgt elke gebied-mijlpaal een playtest solo én co-op (roadmap v1.2). Zie R16 voor de kosten daarvan. | creative-director | lopend |

### 3.2 Nieuw (R11–R24)

| ID | Risico | Kans | Impact | Maatregel (loopt al) | Eigenaar | Status |
|---|---|---|---|---|---|---|
| R11 | **Tickvolgorde en objectdetectie.** E-07b (gdd) draait de stapvolgorde van de spike om (eerst de schaduw, dan P1). Daarnaast werkt een `Area2D` zijn overlap pas ná `_physics_process` bij, dus drukplaten en zones lopen één tick achter. Dan slagen E-06 en E-13 niet ("plaat precies 30 ticks aan"), en zijn echo-puzzels op de tick niet meer exact. | M | M | **Tickvolgorde: opgelost in PR #26** (gemergd): `sim.gd` stapt nu schaduw → P2 → P1, met twee nieuwe tests. **Open**: stap 4 (events) en 5 (objecten) zitten nog niet in de spike, dus SM-punt 2 op PR #16 (directe `intersect_shape`-queries, of één tick vertraging accepteren en de tests daarop zetten) is nog niet beslist (A2). #30 noteert al dat de test voor E-07b stap 4–5 en C-01 een DoD-regel wordt van het event-systeem-issue (Gameplay Programmer, fase 2). | technical-director | lopend |
| R12 | **De echo is te vaak Leeg.** Na elke kamerwissel, respawn of breek is de echo 600 ticks weg (E-04a). Bij 100+ kamers is het tweede lichaam tijdens gewoon verkennen vaak afwezig. Volgens de SM is dit het grootste visierisico; de CD ziet het als een directe bedreiging van pillar 1. | M | H | Vastgelegd in de gdd v0.2: grote verkenningskamers (L-07), testkamer V1, playtestgrens "≤ 40 % van de tijd Leeg" (vraag 1), en een alternatief achter de hand: de echo volgt je door de deur (O-5, LGD met TD). Een debugteller "ticks Leeg" per kamer staat in gdd §4.1. De roadmap v1.2 neemt de grens van 40 % op in elke gebied-mijlpaal van fase 3. | lead-game-designer | lopend |
| R13 | **Open ontwerpvragen die een pillar raken.** (a) De vierde vaardigheid *Ankeren* past alleen als O-3 zowel met C-01 (max. twee lichamen) als met pillar 3 klopt. Anders is er een andere vaardigheid nodig, terwijl de eindboss-poort alle vier vraagt (K-04). (b) De pitch belooft dat bosses je echo lezen, maar E-14 maakt de echo onzichtbaar voor vijanden (O-1). | M | M | Belegd als O-1 (Combat Designer) en O-3 (Systems Designer, LGD) in gdd §2.11, met de voorwaarde van de CD op PR #16. Nog nodig: de eis "bosses lezen de echo" en de Ankeren-voorwaarde staan nog niet in de gdd (EP-punt 7 en SM-punt 1 op PR #16, A3, fase 2). | lead-game-designer | lopend |
| R14 | **Positionering.** De echo-mechaniek kennen spelers al uit puzzelgames (*Me and My Shadow*, *Echo Shift*). USP 1 houdt alleen stand door de combinatie (metroidvania + tweede lichaam + lokale co-op). Voor USP 3 en 4 bestaat een voorganger (*Outland*, 2011). En pixel-metroidvania's zijn een drukke markt. Een claim als "de eerste" is makkelijk te weerleggen. | M | M | Naamcheck §3.4 geeft de tekstnuances. Pitch v0.3 (PR #41) voert ze door ("we vonden geen …", *Outland* als referentie, USP 3/4 genuanceerd). Het licht-schaduwmotief als handtekening wordt een eis in de art bible (#20). Herhaal de ideecheck vóór een Steam-pagina (naamcheck §6). | creative-director | lopend |
| R15 | **De werktitel leest duisterder dan de toon.** "Wraith" klinkt duisterder dan "duister maar niet gruwelijk, PEGI 12", en mist de tweeledigheid van licht en schaduw (nadeel genoemd in de brainstorm in #24). | M | L | De CD bewaakt de toon (besluit #24); pitch v0.3 (PR #41) heeft daarvoor een blok "Naam en toon" met een ja/nee-vraag per uiting. Raakt de naam bij een **concept voor een publieke uiting** (logo, key art, storetekst) toch de toon, dan volgt een nieuwe naamvraag aan de CEO vóór de betaalde merkcheck (vóór die check is er geen publieke uiting, besluit #24, 3A). Zelfde route als R24. | creative-director | lopend |
| R16 | **Pillar 3 verdubbelt de testlast.** Elke puzzel moet in solo én in co-op getest worden (R10, roadmap fase 2 en 3). Met max. 40 echo-puzzelkamers op de kritieke route (kernloop §5) en duo-playtests voor vraag 3 is dat de grootste QA-post in fase 2 en 3. Gemeld door de EP in de review van PR #11. | H | M | De gdd maakt de L-regels deels headless te testen via `ScriptedInput` per testkamer (§4.3), zodat alleen de beleving nog handwerk is. In de sprintplanning plant de Producer per slice-puzzel twee testmomenten (solo en co-op); het QA-testplan in fase 2 neemt dat over (roadmap v1.2). De raming komt in het concept-fasekader fase 2 (#10). | producer | lopend |
| R17 | **Prestaties op de Steam Deck** met 2D-licht (licht- en schaduwlaag, 2–4 bronnen per kamer, 2 spelers + echo) in de Compatibility-renderer zijn niet gemeten (C7). "Steam Deck verified" is een doel uit besluit #2. | L | M | #21 (lichtmeting met lichtbudget, Technical Artist met de Engine & Platform Programmer), in fase 1 na #10 (fasekader v1.2 §6.1). De echo zelf is goedkoop (±24 kB per speler, ontwerp §4). | technical-artist | lopend |
| R18 | **Geen CI en een zwakke testrunner**: de tests draaien alleen als een agent of mens ze start, dus een fout in het echo-determinisme kan onopgemerkt blijven (ontwerp-R6). Bovendien meldt `run_tests.gd` `PASS (0 checks)` als een test crasht met een scriptfout (reviews PR #26), zodat ook een handmatige run vals groen kan geven. | M | M | **#30** (TD): een test met 0 checks of een scriptfout geeft FAIL en een exitcode ≠ 0. De EP is in principe akkoord met GitHub Actions (review op PR #13); de roadmap v1.2 zet CI met headless tests in fase 2 (Engine & Platform of Tools Programmer), met een gecachete download en de SHA-512-check. Tot die tijd draait elke review op `game/` de tests zelf. | technical-director | lopend |
| R19 | **Co-op-invoer.** Twee spelers op één toetsenbord (ghosting), een joypad-index die wisselt na opnieuw aansluiten, Steam Input dat apparaten anders nummert (C5). Al gezien in de spike: linker Ctrl triggerde de echo van P2 (#14, opgelost in PR #26). Daarnaast drop-in en drop-out (C2): drop-out direct nadat P1 op P2 stond, laat de echo meteen breken, wat botst met "naadloos" (SM-punt 3 op PR #16). | M | M | Spike: een inputbron per speler en meedoen/stoppen via de InputRouter (gdd §2.5, C-03, C-05). In fase 2 (roadmap v1.2: input voor 2 controllers, drop-in/drop-out): een InputRouter op apparaat-GUID en een test met 2 joypads en op de Deck. Nog nodig: SM-punt 3 op PR #16 in C-05 en playtestvraag 3 (A3). | technical-director | lopend |
| R20 | **De productieraming van fase 3 is onzeker.** Max. 4 gebieden × 30 kamers (120), waarvan max. 40 echo-puzzelkamers, plus max. 5 bosses (besluit #2: 4–5). De roadmap schat fase 3 op 4–8 maanden, lineair geschaald, zonder raming per gebied (SM-review PR #12). Valt de raming na de slice veel hoger uit, dan raakt dat het budget per fase en de omvang (5–7 uur) uit besluit #2. | M | H | Kernloop §5 legt alle aantallen vast als **maximum**, met een rekensom van 5,1–6,6 uur. De roadmap v1.2 laat de EP na de slice een raming per gebied voorleggen, plus een releasevenster, en na de eerste gebied-mijlpaal van fase 3 de raming toetsen aan de werkelijkheid. De slice is een kwart tot een derde van de game: een goede meetbasis. Nog nodig: tellen de terugkeerpoorten (K-01–K-03) mee in 65–80 min per gebied? (SM-punt 4 op PR #16, A3.) | executive-producer | lopend |
| R21 | **Reviewpunten raken zoek na een merge.** Niet-blokkerende punten van Lead en SM komen niet altijd in het document of in een vervolgissue terecht (v1.0: de SM-punten op PR #12, #16 en #23; de visie-review voor E3 op PR #17, later #36). Zo bouwt de volgende rol op een onvolledige basis (zie R11, R13, R19, R20). | **M** (was H) | M | Vastgelegd in `producer-regie.md` v1.3 (besluit #47, PR #46, dekt A11): "klein" wordt in dezelfde PR verwerkt; een open punt staat als één regel onder *Open punten* in het document zelf, en de volgende rol die het document wijzigt neemt het mee; een vervolgissue alleen voor werk van een andere rol of iets dat de gate blokkeert. Dit register volgt die regel (§6). Tot de regel zich bewezen heeft: `lopend`. | producer | lopend |
| R22 | **Audio haalt de eindkwaliteit van de slice niet.** De roadmap eist in fase 2 "eindkwaliteit art en audio", maar R5 dekt alleen art. Er is in fase 1 geen audiorol actief en er bestaat nog geen enkel geluid. Audio wordt net als art met code gemaakt (`WERKWIJZE.md` §9), en externe samples of plug-ins mogen alleen met een licentie in `docs/licenties.md`. Muziek op het niveau van een goede indie-release is met code-gegenereerde audio moeilijk. Daarnaast hangt pillar 1 deels aan geluid: het geluid van de echo moet het tweede lichaam ook hoorbaar maken, en de pitch zegt dat leesbaarheid van de lagen vóór sfeer gaat, ook voor audio (pitch §4). Gemeld door de SM (PR #27, punt 3). | H | H | **Vastgelegd in roadmap v1.2, fase 2 (PR #34)**: eerst één referentiefragment (bv. het geluid van de echo in de slice-scène) op beoogde eindkwaliteit, rubric Kwaliteit ≥ 7, vóór het slice-audiowerk. Haalt het fragment geen 7, dan geen slice-audio op die basis, maar een `brainstorm`-issue met de CEO en een herziene slice-raming. Audiorichting, muziekthema en het geluid van de echo staan als hoofdlijn in fase 2. Nog nodig: de eis in `fase-2-kader.md` met een akkoord van de Audio Director (A10, SM-punt 5 op PR #34). Of externe audiotools of -bibliotheken nodig zijn, beslist de Audio Director in fase 2, met de BLA voor de licentie. | audio-director | lopend |
| R23 | **De VAF-route (c) levert weinig of niets op.** Fase 2 rekent met € 0 subsidie; het VAF-geld is alleen een mogelijke meevaller voor fase 3 (`subsidies.md` §5). Toch kan die meevaller om vier redenen wegvallen of klein uitvallen: (1) de **drempels**: een vennootschap met zetel in Vlaanderen of Brussel, een culturele test die een Nederlandse versie eist (botst met besluit #2) **plus een tweede criterium uit categorie I**, en een beoordeling van het (Vlaamse) kernteam, terwijl wij één mens plus AI-rollen zijn; (2) het VAF kan een aanvraag voor productiesteun **terugverwijzen naar prototype- of slicesteun** (art. 6.1), terwijl onze slice dan al af is en dus niet meer subsidiabel (art. 14.9); (3) productiesteun vraagt **tractie** (wishlists), dus een openbare Steam-pagina, en die vraagt eerst de merkcheck (R4) en een CEO-besluit; (4) de steun is een **percentage van het creatiebudget** van fase 3, en bij € 0 externe kosten is hij dus klein. Gemeld door de EP en de SM in de reviews op PR #28. | M | M | Fase 2 hangt er niet van af (€ 0 subsidie, gemergd in `subsidies.md` v1.1 en fasekader v1.2). De drempels liggen als bevestiging V en vragen 1–3 bij de CEO in gate-vraag 3 (#10), inclusief de kost van een Nederlandse versie (fasekader §6.2). De Producer gaf het tweede criterium van categorie I door aan #10 (CD-oordeel volgt daar). **#35** (BLA) neemt de terugverwijzing op in §5.1 en als intakevraag, weegt indienen aan het eind van fase 2 af, voegt de zin over het percentage toe en vraagt of fase 3-werk van vóór de indiening meetelt. | business-legal-advisor | lopend |
| R24 | **Vindbaarheid: "Wraithstep" is al een *Diablo II*-item.** In *Diablo II: Resurrected* (Blizzard, *Reign of the Warlock*, 2026) is *Wraithstep* een uniek item (laarzen). Wie de naam zoekt, vindt eerst dat item, in hetzelfde donkere fantasy-publiek (G4, `naamcheck-wraithstep.md` §2.4). Juridisch klein (geen merk WRAITHSTEP in de VS), maar het raakt de Steam-pagina, wishlists (en daarmee R23) en marketing. Kans en impact volgen de BLA (M/M, risicotabel §2.5). | M | M | De CD nam de vindbaarheid op met de toonbewaking (comment in #25: https://github.com/cesarvangerwen-glitch/echoborn/issues/25#issuecomment-6723770312). **#44** (Marketing & Community Manager, `fase:2-preproductie`, ≈ 1 run, besluit EP): vindbaarheidstoets met advies houden / houden met toevoeging / nieuwe naamvraag, klaar **vóór de betaalde merkcheck en vóór elke publieke uiting**. Werkt de naam niet, dan een nieuwe naamvraag aan de CEO vóór de betaalde check (fasekader v1.2, gate-vraag 5). Blokkeert #10 niet. | creative-director | lopend |

### 3.3 Overzicht kans × impact

| Kans \ Impact | L | M | H |
|---|---|---|---|
| **H** | | R16 | R5, R22 |
| **M** | R15 | R4, R7, R11, R13, R14, R18, R19, R21, R23, R24 | R3, R9, R10, R12, R20 |
| **L** | | R6, R8, R17 | R1, R2 |

## 4. Wijzigingen

### 4.1 Ten opzichte van fasekader §5 (uitgangsstand)

| ID | Was | Nu | Waarom |
|---|---|---|---|
| R1 | M/H | L/H | Spike gemergd (PR #13, PR #26); echo exact, ook met 2 spelers; toestand opnemen maakt de echo ongevoelig voor wereldwijzigingen. |
| R2 | M/H, lead-game-designer | L/H, art-director | 2D gekozen (#18); C-01 laat nooit drie lichamen toe; C-07 regelt de camera; visie-review PR #17: past (#36). Wat openstaat is art-werk (#20, fase 2). |
| R4 | M/M | M/M, *Echoborn* opgetreden | Naamcheck vond een botsing; de CEO koos *Wraithstep* (#24). Restrisico: in de VS laag, in de EU en de Benelux onbekend (PR #33). |
| R6 | M/M | L/M | Fase 2 rekent met € 0 subsidie (PR #28); gate-vraag 3 ligt klaar in fasekader v1.2. Het opbrengstrisico van de route staat apart (R23). |
| R7 | H/M | M/M | De SM keurde in fase 1 niets af (wel drie tweede Lead-rondes); besluit #47 maakt de keten korter. |
| R8 | M/M | L/M, verkleind | #20 staat op `fase:2-preproductie`, #21 is toegestaan (fasekader v1.2 §6.1). |
| R3, R5, R9, R10 | | ongewijzigd | Maatregelen bijgewerkt naar de stand van 2026-11-08 (o.a. de R5-eis in fasekader en roadmap v1.2). |

### 4.2 Ten opzichte van v1.1

| ID | v1.1 | v1.2 | Waarom |
|---|---|---|---|
| R6 | M/M | L/M | Zie §4.1. |
| R8 | M/M, verkleind | L/M, verkleind | De SM vond `verkleind` in v1.1 te vroeg (PR #27, punt 1). Nu staat het label van #20 echt op fase 2; dat is het bewijs. |
| R21 | H/M | M/M | Sinds PR #27 kreeg elke merge een vervolg; de regel staat nu in `producer-regie.md` v1.3 (besluit #47). |
| R22 | | H/H, nieuw | Audio op eindkwaliteit (SM-punt 3 op PR #27). |
| R23 | | M/M, nieuw | Opbrengst VAF-route (c) (EP en SM op PR #28). |
| R24 | | M/M, nieuw | *Diablo II*-item *Wraithstep* (EP-punt 3 en SM-punt 3 op PR #33); kans en impact volgens de BLA. |
| R1, R2, R3 | | kans/impact ongewijzigd | Maatregelen bijgewerkt: R1 met PR #26 en #30, R2 en R3 met de visie-review op PR #17 (#36) en pitch v0.3 (PR #41). |
| R4, R5, R7, R11, R14, R15, R18, R20, R21 | | kans/impact ongewijzigd (R21 zie boven) | Maatregelen bijgewerkt: R4 met PR #33 en #35; R5 met fasekader v1.2 §6.1; R7 en R21 met besluit #47 en regie v1.3; R11 met PR #26; R14 en R15 met pitch v0.3 (PR #41); R18 met #30; R20 "max. 5 bosses (besluit #2: 4–5)". |

## 5. Acties

Acties uit het register, met het issue of document waar ze lopen. Wie de stand wil weten, kijkt in het issue. Acties zonder issue staan ook in §6 *Open punten*.

| # | Actie | Voor rol | Raakt | Waar |
|---|---|---|---|---|
| A1 | Korte merkcheck *Wraithstep* + richtprijs specialist | business-legal-advisor | R4 | #29 (gedaan, PR #33) |
| A2 | Objectdetectie beslissen (SM-punt 2 op PR #16): `intersect_shape`-queries of één tick vertraging | technical-director (met gameplay-programmer) | R11 | Zonder issue; hoort bij het event-systeem-issue in fase 2 (zie #30) |
| A3 | Open reviewpunten PR #16 in gdd v0.3 (EP-punten 5–9, SM-punten 1, 3, 4) | lead-game-designer | R13, R19, R20 | Zonder issue; fase 2, met de prototype-issues (besluit EP) |
| A4 | Reviewpunten PR #23 (NoA, klasse 9) | business-legal-advisor | R4 | #29 (gedaan, PR #33) |
| A5 | Fasekader en roadmap v1.2 | executive-producer | R5, R21 | #31 (gedaan, PR #34) |
| A6 | Scopebesluit #20 en #21 | executive-producer | R8 | Gedaan: fasekader v1.2 §6.1 |
| A7 | (geschrapt in v1.1) | | | |
| A8 | Merkcheck-post € 3.750 excl. btw (herberekende bovenkant, reviews PR #33) in de budgetaanvraag | executive-producer | R4, R6 | #10 (gate-vraag 3) |
| A9 | R5-eis in `fase-2-kader.md`, plus visie-review op de leesbaarheid van P2 (punt 2 van CD en SM op PR #34); bij de start van fase 2 als DoD-regel in #20 | executive-producer (met art-director, creative-director) | R5 | #10, #20 |
| A10 | Audio-eis fase 2 (één fragment ≥ 7) in `fase-2-kader.md`, met akkoord van de Audio Director (SM-punt 5 op PR #34) | executive-producer (met audio-director) | R22 | #10 |
| A11 | Procesregel voor zoekgeraakte reviewpunten | workflow-lead | R21 | Gedaan: `producer-regie.md` v1.3 (#45, PR #46) |
| A12 | Vindbaarheid G4 opnemen bij de CD | creative-director | R15, R24 | Gedaan: [comment in #25](https://github.com/cesarvangerwen-glitch/echoborn/issues/25#issuecomment-6723770312) |
| A13 | Reviewpunten PR #28 en #33 (terugverwijzing VAF, timing indienen, percentage, richtprijs, klasse 28, TMview/WIPO-stap, herhaalcheck vóór publicatie) | business-legal-advisor | R4, R23 | #35 |
| A14 | Visie-review CD op de stijltests (E3) | creative-director | R2, R3 | #36 (gesloten; past, aandachtspunten naar #20) |
| A15 | Testrunner: 0 checks of scriptfout = FAIL | technical-director | R18 | #30 |
| A16 | VAF-deadlines 2027 aflezen (CEO) en inplannen (Producer) | CEO, producer | R6, R23 | Zonder open issue; als informatievraag in #10 |
| A17 | Vindbaarheidstoets *Wraithstep* naast het D2R-item (G4), met advies a/b/c; klaar vóór de betaalde merkcheck en vóór elke publieke uiting; ≈ 1 run, niet blokkerend voor #10 (besluit EP) | marketing-community-manager (met creative-director) | R24, R15, R23 | #44 (`fase:2-preproductie`) |

## 6. Beheer en open punten

- **Wie**: de Producer beheert dit register. Elke rol mag een risico melden met een comment in het issue van het register, of in zijn eigen PR met de tekst "risico voor het register".
- **Wanneer**: bij elke regie-run waarin iets gemergd wordt dat een risico raakt, en bij elke gate. Het fase-statusrapport (E8, #10) neemt de risico's met impact H over: **R1, R2, R3, R5, R9, R10, R12, R20 en R22**.
- **Regels**: elk risico heeft één eigenaar (rol-slug). Een risico met impact H heeft altijd een maatregel die al loopt (§2). Naar `verkleind` of `gesloten` alleen met een verwijzing naar het bewijs. Raakt een risico visie, scope, budget of timing en is er een keuze nodig, dan maakt de EP er een `ceo-beslissing`-issue van (fasekader §6). Dit register noemt geen stand van issues of PR's die snel veroudert; het linkt naar het issue (`producer-regie.md` v1.3).
- **Geen deadline**: besluit #2 legt geen deadline vast. "Vertraging" betekent: een mijlpaal schuift ten opzichte van de raming.

**Open punten** (de volgende versie neemt ze mee; geen eigen issue):
- A2 en A3 landen in de prototype-issues van fase 2.
- A16: de VAF-deadlines 2027 inplannen zodra de CEO ze in #10 geeft.

## 7. Definition of Done

**#9 (v1.0–1.1)**
- [x] R1–R10 uit het fasekader met actuele kans en impact (§3.1, §4).
- [x] Elk risico met impact H heeft een lopende maatregel en één eigenaar (§3).
- [x] Spike (#5), naamcheck (#8) en werktitel (#24) verwerkt.

**#32 (v1.2)**, SM-punten op PR #27:
- [x] 1. R8 `verkleind`, met het label van #20 als bewijs.
- [x] 2. R5-eis: fasekader v1.2 §6.1 en A9.
- [x] 3. Audiorisico R22, met A10.
- [x] 4. R20: "max. 5 bosses (besluit #2: 4–5)".
- [x] 5. Procesvoorstel R21: A11, gedaan in regie v1.3.
- [x] §5 verwijst naar de bestaande issues (#10, #20, #25, #29, #30, #31, #35, #36, #44).
- [x] R6 na PR #28 (en R23); R4 na PR #33 (en R24, A17).

## 8. Wijzigingen

| Versie | Datum | Wat |
|---|---|---|
| 1.0 | 2026-11-08 | Eerste versie: R1–R10 uit het fasekader bijgewerkt, R11–R21 toegevoegd, acties A1–A8. |
| 1.1 | 2026-11-08 | Lead-review EP (PR #27): scopebesluit #20/#21, R11/A2 met PR #26, R7 tweede Lead-rondes, bron R12, A7 geschrapt, VAF-notitie bij R6, EP-besluiten in §5. |
| 1.2 | 2026-11-08 | #32. SM-punten PR #27: R8 met bewijs, R5-eis (A9), audiorisico R22 (A10), R20 bosses, R21-procesregel (A11). Na PR #28: R6 naar L/M, nieuw R23. Na PR #33: R4 bijgewerkt, nieuw R24 (M/M, volgens de BLA) en A17 (#44). Bijgewerkt met PR #26, #34 en #41, de issues #30 en #36, en besluit #47 / regie v1.3 (R7, R21). §4.2 toegevoegd; §5 zonder snel verouderende stand; §6 met *Open punten*. Lead-review EP op PR #42 verwerkt. 24 risico's, 9 met impact H. |
