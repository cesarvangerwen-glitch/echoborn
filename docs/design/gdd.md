# Game Design Document *Echoborn*

Versie 0.2 · Eigenaar: Lead Game Designer · Issue #6 · Status: interne review (Executive Producer)
Bronnen: `docs/concept/pitch.md` (pillars P1–P3), `docs/tech/ontwerp.md` (echo-spike), `docs/productie/fase-1-kader.md` (E2), `docs/beslissingen.md` (stand 2026-11-08, o.a. **stijl 2D**, #18).
Kernloop, diagrammen en pillartoets: `docs/design/kernloop.md`.

Deze versie bevat alleen wat nodig is voor het echo-prototype: de echo zelf (§2), een schets van de vaardigheden (§3), de prototype-specificatie (§4) en de playtestvragen (§5). Andere systemen (combat, beweging, save, UX) krijgen een eigen sectie zodra de vakdesigners erop werken.

**Afspraken.**
- Elke regel heeft een ID: E- (echo), C- (co-op), L- (levelontwerp). **Elke E- en C-regel heeft een automatische test in §4.3.** L-regels toetsen we met een reviewchecklist of playtest; dat staat er ook in §4.3 bij.
- Tijden staan in **ticks van 60 Hz** (de vaste simulatietick, `ontwerp.md` §2). "Nu" is tick `t`.
- **px = wereldpixel**: één pixel van het 640×360-beeld (stijlbesluit 2D, #18). Een figuur is ±30 px hoog (stijltest: ±60 px op 1280×720). Afstanden worden opnieuw bekeken als de Art Director de figuurgrootte vastlegt.
- Werkaannames van deze versie: randvoorwaarden-besluit #2 (5–7 uur, 3–4 gebieden, 4–5 bosses, PEGI 12) en stijlbesluit #18 (2D). Geen andere aannames.

---

## 1. Basis: twee lichamen, twee lagen

- **Het lichtpersonage (P1)** leeft in de lichtlaag. Het is de speler, heeft levenspunten, verzamelt items en vaardigheden.
- **De schaduw** leeft in de schaduwlaag. Solo is de schaduw de **echo**: een opname van P1 van 10 s geleden. In co-op is de schaduw **speler 2 (P2)**, live bestuurd.
- Er zijn nooit meer dan **twee lichamen** tegelijk: P1 plus óf de echo, óf P2 (C-01).
- In beeld (stijltest 2D): **levend = vol, echo = hol**. P1 vol amber, P2 vol donker met cyaan contour, de echo gerasterd met de contour van P1. Uitwerking: Art Director.

Basisbeweging (lopen, springen) is voor het prototype de beweging uit de spike (`Motor.step`). Aanval en interactie staan in §2.5; de echte uitwerking komt van de Combat Designer en Gameplay Programmer.

---

## 2. Systeem: de echo

### 2.1 Doel

De echo maakt van elke actie een actie voor nu én voor straks. Hij is een volwaardig tweede lichaam (pillar 1), leeft in de schaduw en wordt gegate door licht (pillar 2), en is solo dezelfde rol die P2 in co-op live speelt (pillar 3).

### 2.2 Opnamemodel

**Besluit LGD: de echo loopt altijd 10 s achter je aan, en speelt de opgenomen *toestand* af.** Er is geen knop om op te nemen of af te spelen; de echo is er gewoon, net als je schaduw. Dit volgt de pitch ("je schaduw volgt je met 10 seconden vertraging") en de aanbeveling van de Technical Director (toestandsopname, `ontwerp.md` §4).

Waarom geen vastgezette clip op een knop: dan wordt de echo een gereedschap dat je soms pakt, in plaats van een lichaam dat altijd meedoet. Het "altijd achter je aan"-model helpt ook tijdens gewoon verkennen en vechten (pitch-risico "te weinig flow"). Een vastgezette lus komt later terug als vaardigheid *Ankeren* (§3).

| ID | Regel |
|---|---|
| **E-01** | P1 wordt elke tick opgenomen, na zijn stap: positie, snelheid, kijkrichting (E-10a), `op_vloer`, **steunsoort** (`wereld` / `licht` = licht-geometrie / `schaduwlichaam` = echo of P2, zie E-07), animatietoestand, en de events van die tick (E-10). De opname loopt altijd, ook in co-op (C-04). |
| **E-02** | De echo toont op tick `t` de opgenomen toestand van frame `p = t − D` (D = 600 ticks = 10 s). De echo wordt niet gesimuleerd: hij staat waar P1 op tick `p` stond. |
| **E-03** | Er is één waarde `geldig_vanaf`. De echo is **Actief** als `p ≥ geldig_vanaf`, anders **Leeg**: onzichtbaar, geen botsingen (ook geen schaduwplatform, E-07), geen events, geen controles (E-08). Frames van vóór `geldig_vanaf` worden nooit afgespeeld. |
| **E-04** | `geldig_vanaf = t` wordt gezet bij: (a) een **kamerwissel** van P1 (E-04e), ook terug naar de vorige kamer, (b) respawn van P1, (c) *Loslaten* (E-09), (d) breken van de echo (E-08). Dit is het enige reset-mechanisme. Gevolg: na elke reset is de echo precies 600 ticks Leeg en verschijnt hij daarna op de plek waar P1 op het reset-moment stond. |
| **E-04e** | **Wat een kamer is.** Een kamer is een `Kamer`-node in de gebiedsscène: een rechthoekige `Area2D` die tegelijk de **camerazone** en de **streameenheid** van de AreaLoader is (`ontwerp.md` §3). Kamers overlappen niet. De kamer van P1 is de kamer waarvan de rechthoek het middelpunt van P1 bevat. Verandert die waarde, dan is dat een kamerwissel. P2 en de echo veroorzaken nooit een kamerwissel. Een kamer mag meerdere schermen groot zijn; levelontwerp houdt verkenningsruimtes groot (L-07) zodat de echo tijdens verkennen niet steeds Leeg is. |

### 2.3 Lagen en physics

**Regel in één zin: de echo bestaat alleen in de schaduw; hij wordt gedragen en geblokkeerd door wereld- en schaduwgeometrie, en hij kan alleen *gedeelde* objecten en *schaduw*objecten bedienen. De lichtlaag raakt hij nooit direct; hij beïnvloedt het licht alleen via gedeelde objecten** (bv. een gedeelde hendel die een lamp verzet). **P1 kan wel op de schaduw staan, via een aparte eenrichtingscollider.**

| ID | Regel |
|---|---|
| **E-05** | **Physics-lagen.** Uitbreiding van `ontwerp.md` §8 met laag 6 en 7 (de Gameplay Programmer zet ze in `layers.gd` en `project.godot`). Tabel hieronder. Het lichaam van de schaduw (laag 3) is voor P1 onzichtbaar; P1 botst alleen met de **schaduwplank** op laag 6. |

| Laag | Naam | Wat erop staat | Wie maskeert deze laag |
|---|---|---|---|
| 1 | wereld | Geometrie die in beide werelden bestaat | P1, P2, controles van de echo (E-08) |
| 2 | licht | Lichaam van P1; aanval- en interactievlak van P1 | Objecten die P1 mogen voelen (E-06), aanvallen van vijanden (E-14) |
| 3 | schaduw | Lichaam van echo/P2; aanval- en interactievlak van echo/P2 | Objecten die de schaduw mogen voelen (E-06) |
| 4 | licht-geometrie | Muren/platforms die alleen in licht bestaan | P1 |
| 5 | schaduw-geometrie | Muren/platforms die alleen in schaduw bestaan | P2, controles van de echo (E-08) |
| 6 | schaduwplank | De eenrichtingscollider op echo en P2 (E-07) | **Alleen P1** |
| 7 | zones | `FelLicht`- en `Schaduwgevaar`-zones (E-08c/d, E-11) | Controles van de echo, P2 |

| Lichaam | `collision_layer` | `collision_mask` |
|---|---|---|
| P1 (`CharacterBody2D`) | 2 | 1 + 4 + 6 |
| P2 (`CharacterBody2D`) | 3 | 1 + 5 (dus **niet** 2: P2 staat nooit op P1, C-02) |
| Echo (`CharacterBody2D`, wordt gezet, niet bewogen) | 3 | geen; de controles van E-08 zijn aparte queries op 1 + 5 en 7 |
| Schaduwplank (`AnimatableBody2D`, kind van echo en van P2) | 6 | geen |

| ID | Regel |
|---|---|
| **E-06** | Elk interactief object heeft precies één **eigenaarslaag**. Het object luistert naar laag 2 + 3 (gedeeld), 2 (licht) of 3 (schaduw): |

| Soort object | Wie kan het bedienen of raken | Voorbeelden |
|---|---|---|
| **Gedeeld** (wereld) | P1 én echo/P2 | Hendel, drukplaat, deur, gewone vijand |
| **Licht** | Alleen P1 | Lichtschakelaar, lichtplaat, lichtwezen, items, vaardigheden |
| **Schaduw** | Alleen echo/P2 | Schaduwhendel, schaduwplaat, schaduwwezen |

Art maakt de drie soorten in één oogopslag uit elkaar te houden (pillar 2; Art Director).

| ID | Regel |
|---|---|
| **E-07** | **De schaduw als platform.** Echo en P2 hebben elk een **schaduwplank**: een `AnimatableBody2D` op laag 6 met een `CollisionShape2D` met `one_way_collision = true`, zo breed als het lichaam, op de bovenkant van het lichaam. Alleen P1 maskeert laag 6. Gevolg: P1 landt alleen van boven op de schaduw; van opzij en van onder loopt of springt P1 erdoor. Beweegt de schaduw omhoog door P1 heen, dan wordt P1 niet geduwd en landt hij niet. Is de echo Leeg of gebroken, dan is de plank uit (P1 valt). Verschijnt de echo of P2 in P1, dan gebeurt er niets tot P1 er van boven op landt. De schaduw duwt niets en wordt door niets geduwd. De schaduw activeert drukplaten (gedeeld en schaduw) zolang zijn lichaam (laag 3) erop staat. |
| **E-07a** | **P1 beweegt mee.** Stond P1 aan het eind van tick `t − 1` op een schaduwplank (`op_vloer` en de vloer is laag 6), dan krijgt P1 aan het begin van zijn stap op tick `t` de verplaatsing van de plank: `Δ = plankpositie(t) − plankpositie(t − 1)`, horizontaal én verticaal. Die verplaatsing gaat met `move_and_collide` tegen laag 1 + 4: botst P1, dan schuift hij niet verder dan de muur en blijft de plank onder hem doorgaan. Daarna volgt de gewone `Motor.step` met de input van P1. P1 krijgt **geen** snelheid van de plank mee (springt P1 eraf, dan telt alleen zijn eigen snelheid). Ingebouwde platformsnelheid van Godot staat daarvoor uit (`platform_on_leave = DO_NOTHING`, `platform_floor_layers` zonder laag 6), zodat er maar één regel is. |
| **E-07b** | **Volgorde per tick** (vult `ontwerp.md` §2.2 aan; de TD bevestigt): (1) de schaduw: de echo zet frame `p` en doet zijn controles (E-08), óf P2 stapt; (2) P1 stapt, inclusief E-07a; (3) P1 wordt opgenomen (E-01); (4) events uitvoeren, eerst van P1, dan van de schaduw (E-10); (5) objecten (drukplaten, schakelaars, zones, schild) werken hun stand bij. Daardoor beweegt P1 in dezelfde tick mee, zonder een tick achter te lopen. |
| **E-11** | **Fel licht.** Gebieden met fel licht zijn expliciete gameplay-zones (`FelLicht`, een `Area2D` op laag 7 die bij een lamp hoort), niet afgeleid van de rendering. Alleen de zone telt: staat de lamp in beeld aan maar is de zone uit, dan bestaat er geen fel licht. Zo blijft het deterministisch; de Art Director en Technical Artist zorgen dat het beeld klopt met de zone. |
| **E-12** | De echo (en P2) verzamelt niets: geen items, geen vaardigheden, geen gezondheid. Alleen P1 verzamelt (pickups luisteren naar laag 2). |

### 2.4 Geblokkeerd pad: de echo breekt

Bij toestandsopname loopt de echo het oude pad, ook als de wereld sindsdien veranderd is. **Besluit LGD: klopt het oude pad niet meer met de huidige schaduwwereld, dan *breekt* de echo:** hij lost op in schaduwdeeltjes op de plek van het probleem, en de opname begint opnieuw (E-04d). Hij loopt dus niet door muren en hij blijft niet staan.

Waarom: door de muur lopen maakt schaduwgeometrie betekenisloos (pillar 2); stoppen laat een "bevroren" lichaam achter dat puzzels ongewild oplost (bv. blijvend op een drukplaat). Breken is eerlijk en leesbaar: je ziet precies wáár het oude plan niet meer klopt, en je bent hooguit 10 s kwijt.

| ID | Regel |
|---|---|
| **E-08** | Elke tick waarin de echo Actief is, controleert het spel frame `p`: **(a) Vrij:** de vorm van de echo overlapt op de opgenomen positie niet meer dan 2 px met laag 1 of 5. **(b) Steun:** als `op_vloer` waar was, vindt een ShapeCast van 4 px recht omlaag laag 1 of 5. Steunde P1 toen op licht-geometrie, dan moet er nu schaduwgeometrie of wereld onder liggen. Steunde P1 op een schaduwlichaam (de echo of P2), dan faalt (b) altijd. **(c) Licht:** het middelpunt van de echo ligt niet in een `FelLicht`-zone. **(d) Gevaar:** de vorm van de echo overlapt geen `Schaduwgevaar`-zone (laag 7, bv. schaduwdoorns of een licht-val). Faalt (a) of (b) **G = 3 ticks achter elkaar**, of faalt (c) of (d) één tick, dan breekt de echo: breek-effect op de laatste geldige positie, events van deze tick worden niet uitgevoerd, `geldig_vanaf = t`. |

Gevolg dat we bewust accepteren: heb je op je echo gestaan, dan breekt hij 10 s later op dat punt ("je stond op jezelf; je echo heeft niemand om op te staan"). Dat is consistent met E-08b. Playtest let hierop (§5, vraag 2).

En een tweede gevolg: P1 loopt dwars door schaduwgeometrie, dus overal waar P1 dat deed, breekt de echo. Daarom regel L-06: schaduwgeometrie staat niet op normale looppaden.

De kern-puzzel die hieruit volgt (pillar 2): P1 loopt over een **lichtbrug** en verzet aan de overkant een gedeelde hendel die de lamp draait. De lichtbrug verdwijnt en zijn **schaduwbrug** verschijnt. 10 s later loopt de echo over de schaduwbrug naar een schaduwplaat. Zonder de lamp te draaien breekt de echo bij de rand.

### 2.5 Input, events en wat de echo doet

**Inputbitset voor het prototype** (vervangt `input_bits.gd` uit de spike; bouwen: Gameplay Programmer). Eén int per tick per speler, zoals in de spike.

| Bit | Waarde | Naam | Wat | Event voor de echo? |
|---|---|---|---|---|
| 0 | 1 | `LEFT` | Naar links | Nee (zit in de toestand) |
| 1 | 2 | `RIGHT` | Naar rechts | Nee (zit in de toestand) |
| 2 | 4 | `JUMP` | Springen | Nee (zit in de toestand) |
| 3 | 8 | `AANVAL` | Aanval; heet `ACTION` in de spike en wordt hernoemd | **Ja** |
| 4 | 16 | `INTERACTIE` | Hendel, deur, oppakken | **Ja** |
| 5 | 32 | `ECHO` | Echo-knop (Loslaten, E-09; later Ankeren) | Nee, nooit |

Bit 6 en 7 (`UP`, `DOWN`) zijn **gereserveerd** voor de Combat Designer (aanval omhoog/omlaag, preproductie). Het prototype gebruikt ze niet.

**Meedoen en stoppen zijn géén bits.** Ze horen bij de `InputRouter` (`ontwerp.md` §5): ze werken op apparaatniveau, voordat er een speler is, en worden niet opgenomen.

| Actie | Knop (voorstel; het rebindscherm is van de UX Designer) | Regel |
|---|---|---|
| Meedoen | **Start/Menu** op een vrije joypad, of **Enter** op de P2-helft van het toetsenbord | C-03 |
| Stoppen | **Select/View** (toetsenbord: **Backspace**) 60 ticks vasthouden op het apparaat van P2 | C-05 |
| Echo-knop | P1: **Q** of linker schouderknop | E-09 |

| ID | Regel |
|---|---|
| **E-10** | **Events.** Een event ontstaat op de tick waarop het bit van 0 naar 1 gaat (flank, `ontwerp.md` C8). `AANVAL` heeft een herhaaltijd van 20 ticks: binnen 20 ticks na een AANVAL-event ontstaat geen nieuw AANVAL-event. Events worden opgenomen ongeacht of ze bij P1 iets raakten. Bij afspelen voert de echo het event van frame `p` uit tegen de **huidige** wereld, met zijn eigen vlak op laag 3, volgens E-06. Voorbeeld: P1 drukt INTERACTIE bij een schaduwhendel (er gebeurt niets), 10 s later zet de echo hem om. |
| **E-10a** | **Kijkrichting en aanvalsrichting.** Kijkrichting is `+1` (rechts) of `−1` (links), begint op `+1`, wordt `−1` op een tick met alleen `LEFT` en `+1` met alleen `RIGHT`; anders blijft hij gelijk. De **aanvalsrichting is de kijkrichting** (horizontaal; geen UP/DOWN in het prototype). Het aanvalsvlak is een rechthoek van 20 × 16 px direct vóór het lichaam in de kijkrichting, **1 tick** actief: op de event-tick. De echo gebruikt de *opgenomen* kijkrichting van frame `p`, niet een nieuw berekende. |
| **E-10b** | **Interactie.** Een INTERACTIE-event bedient het object waarvan het interactievlak het lichaam overlapt op die tick (bij meerdere: het dichtstbijzijnde middelpunt). Voor de echo: het lichaam op de positie van frame `p`, op laag 3. |
| **E-13** | Schakelaars bestaan in drie gedragstypes: **Wissel** (elke bediening keert de stand om; de echo zet hem dus 10 s later terug), **Drukplaat** (actief zolang belast) en **Eenmalig** (eerste bediening telt, daarna vast). Levelontwerpers kiezen per object (L-05). |
| **E-14** | De echo heeft geen levenspunten en kan niet sterven. Vijandelijke aanvallen maskeren alleen laag 2 en hebben dus geen effect op de echo (of P2); alleen E-08 laat de echo breken. Een treffer van de echo doet evenveel schade als de opgenomen treffer van P1 (parameter, Combat Designer stelt bij). |

**De echo kan niet:** door schaduwgeometrie, in fel licht of een schaduwgevaar bestaan, lichtobjecten bedienen of lichtwezens raken, iets oppakken, iets duwen, P1 schade doen, afwijken van wat P1 deed.

### 2.6 Loslaten (handmatig opnieuw beginnen)

| ID | Regel |
|---|---|
| **E-09** | P1 houdt `ECHO` **30 ticks** aaneengesloten vast: op de 30e tick breekt de echo (zelfde effect als E-08) en `geldig_vanaf = t`. Eén keer per druk: blijft P1 vasthouden, dan gebeurt er niets meer tot de knop is losgelaten. Werkt ook als de echo Leeg is (dan zonder breek-effect). In co-op heeft Loslaten geen zichtbaar effect (er is geen opgenomen echo), maar het zet wel `geldig_vanaf` (relevant bij drop-out, C-05). `ECHO` van P2 doet in het prototype niets. |

Dit houdt "opnieuw proberen" goedkoop zonder de tijdsdruk weg te nemen: je wacht nog steeds 10 s op je nieuwe echo.

### 2.7 Solo vs. co-op

**Besluit LGD: in co-op *is* P2 de schaduw. Er is dan geen opgenomen echo van P1 en ook geen echo van P2.** Dit volgt de richting van de Creative Director (pitch §11.1) en houdt de wereld leesbaar: altijd precies één lichaam in het licht en één in de schaduw. Welke beperkingen P2 van de echo houdt, staat als overzicht in `kernloop.md` §7 (fasekader E2b).

| ID | Regel |
|---|---|
| **C-01** | Maximaal twee lichamen: P1 + echo (solo) of P1 + P2 (co-op). Nooit beide. Zolang P2 meedoet, wordt de echo niet afgespeeld en is hij nergens zichtbaar. |
| **C-02** | P2 is een speler met de lagen uit E-05 (laag 3, masker 1 + 5) en een eigen schaduwplank (E-07). P2 heeft dezelfde beweging (`Motor.step`), dezelfde inputbits, dezelfde events en dezelfde objectregels als de echo (E-06, E-07, E-10, E-12, E-13, E-14). P2 kan niet op P1 staan (P1 is geen platform voor de schaduw), want de echo kan dat ook niet. P2 heeft geen levenspunten. P2 botst met schaduwgeometrie (laag 5) in plaats van erop te breken; hij lost alleen op volgens C-06. |
| **C-03** | **Drop-in.** Een vrij apparaat drukt op "meedoen". Is de echo Actief: P2 neemt de huidige positie en snelheid van de echo over, het afspelen stopt, geen pauze en geen kamer-reset. Is de echo Leeg: P2 verschijnt op de positie van P1 (in de schaduw). **Plaatsingsregel:** is die plek in laag 1 of 5 bezet, dan op de dichtstbijzijnde vrije plek binnen 64 px (zoeken in stappen van 4 px), anders op de laatste vloerpositie van P1. |
| **C-04** | De opname van P1 loopt in co-op gewoon door (E-01), zonder gaten. E-04 blijft gelden (kamerwissel, respawn, Loslaten). |
| **C-05** | **Drop-out.** P2 houdt "stoppen" 60 ticks vast, of het apparaat van P2 is 180 ticks ontkoppeld. P2 lost op (breek-effect) en de echo van P1 neemt het meteen over volgens E-02/E-03: is `t − D ≥ geldig_vanaf`, dan verschijnt de echo op de plek waar P1 600 ticks geleden was; anders is hij Leeg tot dat wel zo is. **Zijn er nog geen 10 s van P1 opgenomen** (bv. vlak na een kamerwissel), dan is er dus geen echo totdat de buffer vol is, hooguit 10 s. Er wordt niets gesimuleerd of verzonnen om het gat te vullen. |
| **C-06** | **P2 lost op** bij fel licht (middelpunt in `FelLicht`), een `Schaduwgevaar`, uit de kamer vallen (middelpunt onder de onderrand van de kamer), of de leiband (C-07). P2 verschijnt 120 ticks later opnieuw naast P1 volgens de plaatsingsregel van C-03. Geen checkpoint-reset; P1 merkt alleen dat de schaduw even weg is. (Antwoord op pitch-vraag 3: de schaduwspeler faalt vergevingsgezind.) |
| **C-07** | **Leiband.** De gedeelde camera houdt beide spelers in beeld tot zijn maximale zoom. Staat het middelpunt van P2 **60 ticks aaneengesloten** buiten dat beeld, dan geldt C-06 (op de 60e tick). P1 bepaalt waar de camera heen gaat; P1 wordt nooit verplaatst of afgeremd door de camera. Waarden van de camera: UX Designer en Technical Director. |
| **C-08** | Sterft P1 in co-op, dan respawnen beiden op het checkpoint; P2 verschijnt naast P1 volgens de plaatsingsregel van C-03. E-04b zet `geldig_vanaf` (van belang bij een latere drop-out). |

**Waarom co-op hiermee niet triviaal wordt** (pitch-risico, R10): P2 houdt alle beperkingen van de echo (alleen schaduw, geen lichtobjecten, lost op in licht, moet in beeld blijven). Wat P2 extra heeft, is *timing*: live in plaats van 10 s later. Dat verandert de puzzel van plannen naar afstemmen, precies zoals pillar 3 vraagt. Extra bereik van P2 mag op de kritieke route en voor verzamelobjecten niets opleveren (L-02). Het volledige overzicht staat in `kernloop.md` §7.

### 2.8 Regels voor levelontwerp

Voor World & Level Designer en Systems Designer. De terugkeerregels (backtracking) staan in `kernloop.md` §5.

| ID | Regel |
|---|---|
| **L-01** | Een echo-kamer op de kritieke route is niet op te lossen met P1 alleen. |
| **L-02** | Elke plek of elk object dat de schaduw op de kritieke route of voor een verzamelobject moet bereiken, is ook bereikbaar voor de **solo-echo**: via een pad dat P1 kan lopen en dat bij het afspelen door wereld- of schaduwgeometrie gesteund wordt. Plekken die alleen een live P2 bereikt, bevatten niets. (Geen co-op-only content, pillar 3.) |
| **L-03** | Poorten zijn licht-, schaduw-, echo- of vaardigheidspoorten. Geen gekleurde sleutels (pillar 2). |
| **L-04** | Een echo-puzzel vraagt hooguit één volle echo-cyclus (600 ticks) voorbereiding per stap. Langere reeksen worden in stappen gehakt met Eenmalige schakelaars. |
| **L-05** | Gebruik een Wissel-schakelaar alleen als het terugzetten door de echo deel van de puzzel is; anders Eenmalig of Drukplaat (E-13). |
| **L-06** | Schaduwgeometrie (laag 5) staat niet op normale looppaden van P1, tenzij het breken van de echo daar bedoeld is (puzzel of uitleg). Anders breekt de echo overal waar P1 door een schaduwmuur liep (E-08a). |
| **L-07** | Verkenningsruimtes zonder puzzel zijn bij voorkeur één grote kamer (meerdere schermen) in plaats van een reeks kleine kamers, zodat de echo niet na elke deur 600 ticks Leeg is (E-04a). Maximum: zie `kernloop.md` §5. |

### 2.9 Parameters

| Parameter | Waarde | Testbereik | Wie stelt bij |
|---|---|---|---|
| D, echo-vertraging | 600 ticks (10 s) | 360 / 600 / 840 (6 / 10 / 14 s) | LGD na playtest; definitief afwijken van 10 s is een CEO-besluit (pitch §10) |
| G, tolerantie vrij/steun | 3 ticks | 1–6 | LGD |
| Overlap-tolerantie (E-08a) | 2 px | 0–4 | LGD + TD |
| Steuncontrole (E-08b) | 4 px omlaag | 2–8 | LGD + TD |
| Loslaten (E-09) | 30 ticks vasthouden | 15–45 | UX Designer |
| AANVAL-herhaaltijd (E-10) | 20 ticks | 10–30 | Combat Designer |
| Aanvalsvlak (E-10a) | 20 × 16 px, 1 tick actief | — | Combat Designer |
| **Venster tweeslagschild (§4.1, T5)** | **15 ticks (0,25 s)** | 6–30 | LGD + Combat Designer |
| P2 terugkeer na oplossen (C-06) | 120 ticks | 60–180 | LGD + UX |
| P2 buiten beeld voor oplossen (C-07) | 60 ticks | 30–120 | UX |
| Drop-in plaatsingsstraal (C-03) | 64 px, stappen van 4 px | — | LGD |
| Drop-out: stopknop vasthouden (C-05) | 60 ticks | 30–90 | UX Designer |
| Drop-out: apparaat weg (C-05) | 180 ticks | — | Engine & Platform |
| Echo-schade (E-14) | 100 % van P1 | 50–100 % | Combat Designer |

### 2.10 Playtestvraag van dit systeem

Zie §5: alle drie de prototypevragen gaan over de echo.

### 2.11 Open vragen bij de echo

| # | Vraag | Aan | Tegen |
|---|---|---|---|
| O-1 | Kunnen vijanden de echo als doelwit kiezen (en zo ja, wat gebeurt er bij een treffer)? | Combat Designer | Preproductie |
| O-2 | Hoe zien Leeg, Actief, Breken en "nog X s tot je echo terugkomt" eruit (HUD of in de wereld)? De stijltest toont al een 10s-ring. | UX Designer, Art Director | Voor de eerste playtest |
| O-3 | Hoe past *Ankeren* binnen C-01 (max. twee lichamen) in co-op? | Systems Designer, LGD | Bij uitwerking vaardigheden |
| O-4 | Moet de echo ook audio afspelen (voetstappen, sprong)? Voorstel: ja, gedempt, als hulp om hem buiten beeld te volgen. | Audio Director | Preproductie |
| O-5 | Is de echo tijdens gewoon verkennen te vaak Leeg door kamerwissels (E-04a)? Zo ja, is het alternatief "de echo volgt je door de deur" (geen reset bij kamerwissel, alleen bij een kamer die niet aan de vorige grenst) te bouwen met de AreaLoader? Hangt af van playtestvraag 1. | LGD, Technical Director | Na de eerste playtest |
| O-6 | UP/DOWN-aanvallen (bits 6 en 7): nodig, en zo ja, hoe herhaalt de echo ze? | Combat Designer | Preproductie |

---

## 3. Vaardigheden (schets)

Eén vaardigheid per gebied (4 gebieden, besluit #2). Elke vaardigheid is vooral iets nieuws wat de **echo** kan (pillar 1). Uitwerking (regels, parameters, tests) door de Systems Designer; dit is de richting, met de botsingen met §2 die de uitwerking moet oplossen.

| # | Vaardigheid | Wat | Pillar | Solo | Co-op | Playtestvraag |
|---|---|---|---|---|---|---|
| 1 | **Dempen** | P1 dimt een lamp tijdelijk; de `FelLicht`-zone verdwijnt zolang | 2 (licht als poort) | Dempen nu, echo loopt er 10 s later doorheen | P1 dempt terwijl P2 er live doorheen gaat | Snappen spelers dat ze moeten dempen *voordat* de echo aankomt? |
| 2 | **Dragen** | De echo draagt een lichtvoorwerp (bv. een lantaarn) dat P1 op dat moment droeg, en zet het neer waar P1 het neerzette | 1, 2 | Lantaarn naar de schaduwkant brengen via je eigen verleden | P2 draagt het live | Voelt het als "mijn verleden helpt me", of als een trucje? |
| 3 | **Ankeren** | Zet de huidige 10 s vast als lus die blijft herhalen tot Loslaten of kamerwissel (pitch-vraag 2) | 1 | Eén vastgezet lichaam + jij | Open (O-3) | Holt een lus de 10-secondenregel uit? |
| 4 | **Terugstappen** (was: Wisselen) | P1 stapt naar de plek van de schaduw. Solo is dat de plek waar P1 10 s geleden stond; in co-op wisselen P1 en P2 van plaats | 1, 3 | Terug naar waar je 10 s geleden was | Spelers wisselen live van plaats | Wordt terugstappen een vluchtknop die puzzels omzeilt? |

**Wat de Systems Designer moet oplossen** (uit de Lead-review, punt 7):
- **Dragen is een uitzondering op E-06.** De echo raakt dan een *licht*object, wat E-06 normaal verbiedt. Regel-richting: het gedragen voorwerp blijft een lichtobject; de echo houdt het alleen vast en zet het neer. Het is geen verzamelen (E-12) en geen derde lichaam (C-01). Deze uitzondering moet als eigen regel-ID in de gdd komen, met test.
- **Wisselen botst met E-02.** De echo staat altijd op een opgenomen positie, dus solo kan er niet echt "gewisseld" worden: de echo kan niet naar de plek van P1, want hij speelt alleen af. Daarom heet de vaardigheid nu *Terugstappen*: P1 gaat naar de echo-plek, de echo breekt (E-04d). Die plek kan inmiddels in lichtgeometrie liggen (de wereld is veranderd). Richting: terugstappen mag alleen als de plek voor P1 nu vrij is (controle zoals E-08a, maar op laag 1 + 4); anders gebeurt er niets, met duidelijke feedback. In co-op is het een echte wissel, met dezelfde controle voor beide spelers in hun eigen lagen.

Bewust **niet**: dubbele sprong, dash of wall-jump als losse vaardigheid zonder echo-betekenis (pitch, pillar 1 "past niet"). Komen ze er toch, dan alleen met een echo-functie (bv. de echo herhaalt de dash als aanval).

---

## 4. Prototype-specificatie

Doel: de echo-regels uit §2 speelbaar maken op de spike (`game/`), in 5 testkamers en een verkenningsgang. Na de Lead-review zet de LGD dit om in issues voor de Gameplay Programmer (via de Technical Director), met deze acceptatiecriteria.

### 4.1 Wat het prototype heeft

- P1 met de spike-beweging en de inputbitset uit §2.5 (AANVAL, INTERACTIE, ECHO). Meedoen en stoppen via een eenvoudige InputRouter.
- Physics-lagen 1–7 uit E-05, met schaduwplank op echo en P2.
- Echo volgens E-01 t/m E-14, P2 volgens C-01 t/m C-08.
- Objecten: gedeelde/licht/schaduw-drukplaat, Wissel- en Eenmalige hendel, deur, lamp met `FelLicht`-zone en lichtbrug/schaduwbrug, `Schaduwgevaar`-zone, pickup (item), één eenvoudige vijand (gedeeld, met een aanval op laag 2) en één schaduwwezen.
- **Tweeslagschild** (vijand in T5): het schild breekt alleen als het binnen **15 ticks** (0,25 s, §2.9) door twee *verschillende* lichamen geraakt wordt: één treffer van P1 (laag 2) en één van de schaduw (laag 3). Twee treffers van hetzelfde lichaam tellen niet.
- Een schakelaar in het debugmenu voor D = 360 / 600 / 840 ticks, en een teller "ticks Leeg" per kamer (voor playtestvraag 1).
- Placeholder-art in de 2D-stijl van de stijltest: drie kleuren voor gedeeld / licht / schaduw, vol voor levend, gerasterd voor de echo.

### 4.2 Testkamers

| Kamer | Wat de speler moet doen | Toetst |
|---|---|---|
| T1 Deur | Op een gedeelde drukplaat staan, doorlopen; de echo houdt de deur open | E-02, E-07 |
| T2 Opstap | Springen bij een hoge richel; 10 s later op de echo landen en meebewegen om erop te komen | E-07, E-07a, E-08b (echo breekt daarna) |
| T3 Schaduwhendel | INTERACTIE bij een schaduwhendel die P1 niet kan bedienen; de echo zet hem om | E-06, E-10, E-10b |
| T4 Lampbrug | Over de lichtbrug, aan de overkant de lamp draaien; de echo loopt over de schaduwbrug naar een schaduwplaat | E-05, E-08b, E-11 |
| T5 Dubbele slag | Een vijand met een tweeslagschild; P1 en de echo moeten binnen 15 ticks raken | E-10, E-10a, E-14, tweeslagschild |
| V1 Verkenningsgang | 4 kamers zonder puzzel tussen T2 en T3, één daarvan groot (3 schermen breed) | E-04a/E-04e, playtestvraag 1 (Leeg-tijd) |

Alle kamers moeten zowel solo als in co-op op te lossen zijn (L-02).

### 4.3 Acceptatiecriteria

Automatisch te testen, headless zoals de spike (`game/tests/`), tenzij er "checklist" of "playtest" staat. Elke regel uit §2 heeft hier minstens één regel. "Kamerwissel op `t0`" betekent: `geldig_vanaf = t0`.

**Opname en reset**

| Regel | Test |
|---|---|
| E-01 | P1 loopt over vloer, lichtbrug en de echo. Het opgenomen frame heeft steunsoort `wereld`, `licht` en `schaduwlichaam` op de juiste ticks, plus positie, snelheid, kijkrichting, `op_vloer`, animatietoestand en events. Na 900 ticks zijn er 600 aaneengesloten frames (geen gaten). |
| E-02 | Na 600 ticks staat de echo op de positie van P1 op tick `t − 600` (0 px verschil). |
| E-03 | Kamerwissel op `t0`; P1 deed op `t0 − 5` INTERACTIE bij een schaduwhendel en stond op `t0 − 10` boven een gat. Op `t0 + 595`: de hendel staat nog in zijn beginstand (geen event uitgevoerd), de echo is onzichtbaar en een P1 die op de echo-plek valt, valt erdoor (geen plank). |
| E-04a–d | Voor elk van de vier oorzaken apart (kamerwissel, respawn, Loslaten, breken) op `t0`: echo Leeg op `t0 + 599`, Actief op `t0 + 600`, op de positie van P1 op `t0`. |
| E-04e | P1-middelpunt gaat over de grens naar kamer B: kamerwissel op die tick. P1 springt terug naar A: opnieuw kamerwissel. P2 gaat in co-op naar kamer B terwijl P1 in A blijft: geen kamerwissel. |

**Lagen en platform**

| Regel | Test |
|---|---|
| E-05 | Lagen en maskers van P1, P2, echo en schaduwplank zijn exact zoals in de tabel. P1 loopt tegen een lichtmuur en door een schaduwmuur; P2 loopt tegen een schaduwmuur en door een lichtmuur. |
| E-06 | Echo op een lichtplaat: plaat blijft uit. Echo op een schaduwplaat: plaat gaat aan. P1 op een schaduwplaat: plaat blijft uit. P1 en echo elk op een gedeelde plaat: beide gaan aan. |
| E-07 | P1 die van boven op de echo landt, blijft staan. P1 die van opzij komt, loopt erdoor. P1 die van onder springt, gaat erdoor. Echo die omhoog door P1 beweegt: P1-positie verandert die tick niet door de echo. Echo loopt het opgenomen pad tegen een gedeeld duwblok: het blok blijft op zijn plek. Echo Leeg terwijl P1 erop staat: P1 valt in dezelfde tick. |
| E-07a | Echo beweegt 3 px/tick naar rechts, P1 staat erop zonder input: P1-x stijgt elke tick met 3 px, in dezelfde tick als de echo. Met een muur rechts: P1 stopt tegen de muur, de echo gaat door en P1 valt als de plank onder hem weg is. P1 springt eraf: P1 heeft na de sprong geen horizontale snelheid van de echo. |
| E-07b | Een logtest per tick bevestigt de volgorde: schaduw → P1 → opname → events P1 → events schaduw → objecten. |
| E-11 | De lamp is in beeld aan maar de `FelLicht`-zone staat uit: de echo loopt erdoor. Zone aan, lamp in beeld uit: de echo breekt. |
| E-12 | Echo en P2 lopen door een item-pickup en een vaardigheid-pickup: beide blijven liggen. P1 loopt erdoor: opgepakt. |

**Breken**

| Regel | Test |
|---|---|
| E-08a | Een schaduwmuur op het pad na opname: echo breekt op de 3e tick van overlap; `geldig_vanaf` = die tick. Overlap van 2 ticks (muur die daarna weg is): echo breekt niet. Overlap van 2 px: breekt niet; 3 px: breekt. |
| E-08b | Lichtbrug weg en geen schaduwbrug: echo breekt aan de rand. Wel een schaduwbrug: echo loopt door. P1 stond op de echo: 600 ticks later breekt de echo op dat punt. |
| E-08c | Echo die een `FelLicht`-zone binnengaat, breekt op de tick waarop zijn middelpunt erin komt. |
| E-08d | Echo die een `Schaduwgevaar`-zone raakt, breekt op de eerste tick van overlap. P1 in dezelfde zone: er gebeurt niets met P1. |
| E-08 (events) | Het opgenomen frame van de breektick bevat een INTERACTIE bij een schaduwhendel: de hendel gaat niet om. |

**Input, events en Loslaten**

| Regel | Test |
|---|---|
| E-09 | 30 ticks ECHO ingedrukt: echo breekt op de 30e tick; 29 ticks: niet. 90 ticks vasthouden: één keer Loslaten. Bij een Lege echo: `geldig_vanaf` wordt toch gezet. |
| E-10 | INTERACTIE bij een schaduwhendel op tick `x`: de hendel gaat om op tick `x + 600`. AANVAL 60 ticks vastgehouden: één event. Twee AANVAL-flanken 10 ticks na elkaar: één event; 20 ticks na elkaar: twee. |
| E-10a | P1 kijkt links en slaat op `x`, met een vijand links en een rechts: op `x + 600` raakt de echo alleen de linker. Het aanvalsvlak is op `x + 601` niet meer actief. |
| E-10b | Twee hendels overlappen de echo bij een INTERACTIE: alleen de dichtstbijzijnde gaat om. |
| E-13 | Wissel-hendel door P1 op `x`: op `x + 600` zet de echo hem terug. Eenmalige hendel: blijft om. Echo staat 30 ticks op een drukplaat: plaat precies die 30 ticks aan. |
| E-14 | Vijandelijke aanval raakt de echo-positie: de echo gaat door en breekt niet. Echo-treffer op een vijand doet dezelfde schade als de opgenomen treffer van P1. |
| Tweeslagschild | P1 raakt op `x`, de echo op `x + 15`: schild breekt. Echo op `x + 16`: niet. P1 raakt twee keer binnen 15 ticks: niet. |

**Co-op**

| Regel | Test |
|---|---|
| C-01 | Gescripte sessie van 3000 ticks met twee drop-ins en twee drop-outs: op elke tick is het aantal schaduwlichamen ≤ 1 en het totaal ≤ 2. Tijdens co-op is er geen echo-actor zichtbaar of botsend. |
| C-02 | P2 springt van boven op P1: P2 valt erdoor. P2 op een lichtplaat: uit; op een schaduwplaat: aan. P2 loopt tegen een schaduwmuur: hij botst en lost niet op. Vijandelijke aanval op P2: geen effect. P2 loopt door een pickup: blijft liggen. P1 landt op P2 en beweegt mee (zelfde test als E-07a). |
| C-03 | Drop-in met Actieve echo: P2 start op de positie en snelheid van de echo; er is daarna geen echo. Drop-in met Lege echo: P2 op de positie van P1. P1 staat met de bovenkant tegen schaduwgeometrie: P2 op de dichtstbijzijnde vrije plek binnen 64 px. Geen vrije plek binnen 64 px: P2 op de laatste vloerpositie van P1. |
| C-04 | 1200 ticks co-op: de recorder van P1 heeft 600 aaneengesloten frames. P1 houdt in co-op ECHO 30 ticks vast op `t0`, drop-out op `t0 + 200`: echo Leeg tot `t0 + 600`. |
| C-05 | Drop-out 300 ticks na kamerwissel: echo Leeg tot tick 600 na de kamerwissel. Drop-out 900 ticks na kamerwissel: echo direct Actief op de positie van P1 van 600 ticks geleden. Stopknop 59 ticks: P2 blijft; 60 ticks: P2 weg. Apparaat 179 ticks weg: P2 blijft; 180: P2 weg. |
| C-06 | P2 in `FelLicht`, in een `Schaduwgevaar` en onder de kamerrand: telkens P2 weg, 120 ticks later naast P1. Geen checkpoint-reset: P1-positie en schakelaarstanden blijven gelijk. |
| C-07 | P2 59 ticks buiten beeld: blijft. 60 ticks: lost op op de 60e tick. P1-positie wordt in de hele test nooit door de camera veranderd. |
| C-08 | P1 sterft in co-op op `t0`: beiden respawnen op het checkpoint, P2 volgens de plaatsingsregel, `geldig_vanaf = t0`. Solo: P1 sterft op `t0`, echo Leeg tot `t0 + 600`. |

**Levelregels** (geen automatische test)

| Regel | Hoe getoetst |
|---|---|
| L-01 | Checklist per kamer (World & Level Designer, review LGD): er is geen oplossing met P1 alleen. Voor T1–T5: een tester probeert 5 min zonder echo (Loslaten elke 5 s) en mag niet slagen. |
| L-02 | Headless: elke testkamer T1–T5 heeft een **solo-oplossing als `ScriptedInput`** die slaagt. Checklist per kamer: elke schaduwplek op de kritieke route ligt op zo'n pad. |
| L-03 | Checklist per poort: soort (licht/schaduw/echo/vaardigheid) staat in de kamerdocumentatie; geen sleutelobject. |
| L-04 | Headless: de `ScriptedInput`-oplossing heeft per stap ≤ 600 ticks voorbereiding. |
| L-05 | Checklist per Wissel-schakelaar: de echo-terugzet is genoemd in de puzzelbeschrijving. |
| L-06 | Headless per kamer: de `ScriptedInput`-oplossing en een rechte doorloop van ingang naar uitgang laten de echo niet breken, behalve op plekken die als "bedoeld breekpunt" gemarkeerd zijn. |
| L-07 | Playtest: teller "ticks Leeg" in V1 (playtestvraag 1). |

---

## 5. Playtestvragen voor het prototype

| # | Vraag | Hoe we het meten | Wanneer het goed is |
|---|---|---|---|
| 1 | **Is 10 s de juiste lengte, en is de echo tijdens verkennen niet te vaak Leeg?** Kunnen spelers voorspellen waar hun echo straks is, en plannen ze vooruit in plaats van te wachten? | T1–T5 en V1 met D = 360, 600 en 840 ticks (per speler één waarde). Meten: tijd per kamer, aantal keer Loslaten, wachttijd zonder input, en in V1 het aandeel ticks dat de echo Leeg is. Na afloop: "wist je waar je echo zou zijn?" (1–5) en "miste je je echo tijdens het lopen?" (1–5). | Bij 10 s: gemiddeld ≥ 4 op voorspelbaarheid, minder dan 30 % van de kamertijd stilstaand wachten, en in V1 is de echo ≤ 40 % van de tijd Leeg. Haalt V1 dat niet: O-5 oppakken. |
| 2 | **Voelt breken eerlijk?** Begrijpen spelers waarom de echo brak, en voelt 10 s opnieuw wachten als een kleine prijs of als straf? | T2 en T4 observeren. Na een breek: "waarom brak je echo?" Juiste uitleg telt als begrepen. Ook: frustratie-score (1–5). | ≥ 80 % juiste uitleg; frustratie gemiddeld ≤ 2. Zo niet: kortere hersteltijd na breken testen. |
| 3 | **Werkt dezelfde kamer in co-op als afstemmen, zonder triviaal te worden?** En voelen drop-in en drop-out naadloos? | T1–T5 door duo's (één ervaren, één minder ervaren speler), minstens één drop-in en één drop-out per sessie. Meten: tijd per kamer vs. solo, aantal gesprekken over timing, "had de schaduwspeler een echte rol?" (1–5, beide spelers). | Co-op niet meer dan 2× zo snel als solo; schaduwrol ≥ 4 bij de minder ervaren speler; drop-in/out zonder vragen of verwarring. |

---

## 6. Antwoorden op de vragen uit #6 en `ontwerp.md` §11

| Vraag | Antwoord | Regel |
|---|---|---|
| 1. Opnamemodel: vaste clip of altijd 10 s achter je aan? | Altijd 10 s achter je aan, toestandsopname, events tegen de huidige wereld. Een vaste lus wordt later de vaardigheid Ankeren. | E-01–E-04, §3 |
| 2. Wat als de opgenomen route geblokkeerd is? | De echo breekt (niet door de muur, niet stoppen); opname begint opnieuw. | E-08 |
| 3. Echo in de schaduw, maar raakt dingen in het licht? | Echo raakt alleen gedeelde en schaduwobjecten; het licht beïnvloedt hij alleen via gedeelde objecten. P1 kan wel op hem staan, via de schaduwplank op laag 6. | E-05–E-07, E-11 |
| 4. Co-op: naast P2 nog een opgenomen echo? Drop-in tijdens afspelen? Drop-out zonder 10 s buffer? | Nee, P2 *is* de schaduw. Drop-in: P2 neemt de echo over op zijn plek. Drop-out: echo neemt over vanaf de buffer van P1, die altijd doorloopt; is die nog geen 10 s gevuld, dan is de echo Leeg tot hij vol is. | C-01–C-05 |
| 5. Toets aan de pillars | `kernloop.md` §6 (per onderdeel van de loop en per groep echo-regels) en §7 (wat P2 van de echo houdt). | — |
| TD: mag de echo fysiek beïnvloeden (platform, duwen)? | Platform ja (eenrichtingsplank op laag 6, P1 beweegt mee), duwen nee. | E-07, E-07a |

---

## 7. Wijzigingen

| Versie | Wat |
|---|---|
| 0.1 | Eerste versie (PR #16). |
| 0.2 | Lead-review EP (PR #16): physics-lagen 1–7 met schaduwplank (E-05, E-07, E-07a, E-07b); volledige inputbitset, aanvalsrichting, meedoen/stoppen via InputRouter (§2.5, E-09, E-10a, E-10b); test voor elke E- en C-regel, L-regels als checklist/playtest gemarkeerd, venster tweeslagschild 15 ticks (§2.9, §4.3); kamer gedefinieerd (E-04e), L-06 en L-07, verkenningsgang V1 en Leeg-meting in playtestvraag 1; Dragen als uitzondering op E-06 en Wisselen → Terugstappen (§3); O-5, O-6. Stijlbesluit 2D verwerkt (px, beeldtaal vol/hol). |
