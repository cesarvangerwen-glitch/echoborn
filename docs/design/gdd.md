# Game Design Document *Echoborn*

Versie 0.1 · Eigenaar: Lead Game Designer · Issue #6 · Status: interne review (Executive Producer)
Bronnen: `docs/concept/pitch.md` (pillars P1–P3), `docs/tech/ontwerp.md` (echo-spike), `docs/beslissingen.md` (stand 2026-11-08).
Kernloop en diagrammen: `docs/design/kernloop.md`.

Deze eerste versie bevat alleen wat nodig is voor het echo-prototype: de echo zelf (§2), een schets van de vaardigheden (§3), de prototype-specificatie (§4) en de playtestvragen (§5). Andere systemen (combat, beweging, save, UX) krijgen een eigen sectie zodra de vakdesigners erop werken.

**Afspraak over regels.** Elke regel heeft een ID (E- voor echo, C- voor co-op, L- voor levelontwerp). Elke regel is te testen; de test staat in §4.3. Tijden staan in ticks van 60 Hz (de vaste simulatietick uit `ontwerp.md` §2). "Nu" is tick `t`.

---

## 1. Basis: twee lichamen, twee lagen

- **Het lichtpersonage (P1)** leeft in de lichtlaag. Het is de speler, heeft levenspunten, verzamelt items en vaardigheden.
- **De schaduw** leeft in de schaduwlaag. Solo is de schaduw de **echo**: een opname van P1 van 10 s geleden. In co-op is de schaduw **speler 2 (P2)**, live bestuurd.
- Er zijn nooit meer dan **twee lichamen** tegelijk: P1 plus óf de echo, óf P2 (C-01).

Basisbeweging (lopen, springen, slaan, interacteren) wordt in een aparte sectie uitgewerkt met de Gameplay Programmer en Combat Designer. Voor het prototype geldt de beweging uit de spike (`Motor.step`).

---

## 2. Systeem: de echo

### 2.1 Doel

De echo maakt van elke actie een actie voor nu én voor straks. Hij is een volwaardig tweede lichaam (P1), leeft in de schaduw en wordt gegate door licht (P2), en is solo dezelfde rol als die P2 in co-op live speelt (P3).

### 2.2 Opnamemodel (antwoord op Producer-vraag 1)

**Besluit LGD: de echo loopt altijd 10 s achter je aan, en speelt de opgenomen *toestand* af.** Er is geen knop om op te nemen of af te spelen; de echo is er gewoon, net als je schaduw. Dit volgt de pitch ("je schaduw volgt je met 10 seconden vertraging") en de aanbeveling van de Technical Director (toestandsopname, `ontwerp.md` §4).

Waarom niet een vastgezette clip op een knop: dan wordt de echo een gereedschap dat je soms pakt, in plaats van een lichaam dat altijd meedoet. Het "altijd achter je aan"-model helpt ook tijdens gewoon verkennen en vechten (pitch-risico "te weinig flow"). Een vastgezette lus komt later terug als vaardigheid *Ankeren* (§3).

| ID | Regel |
|---|---|
| **E-01** | P1 wordt elke tick opgenomen: positie, snelheid, kijkrichting, `op_vloer`, **steunsoort** (wereld / licht-geometrie / schaduwlichaam), animatietoestand, en de events van die tick (E-10). De opname loopt altijd, ook in co-op (C-04). |
| **E-02** | De echo toont op tick `t` de opgenomen toestand van frame `p = t − D` (D = 600 ticks = 10 s). De echo wordt niet gesimuleerd: hij staat waar P1 op tick `p` stond. |
| **E-03** | Er is één waarde `geldig_vanaf`. De echo is **Actief** als `p ≥ geldig_vanaf`, anders **Leeg** (onzichtbaar, geen botsingen, geen events). Frames van vóór `geldig_vanaf` worden nooit afgespeeld. |
| **E-04** | `geldig_vanaf = t` wordt gezet bij: (a) een kamer binnengaan (ook dezelfde kamer opnieuw), (b) respawn van P1, (c) *Loslaten* (E-09), (d) breken van de echo (E-08). Dit is het enige reset-mechanisme. Gevolg: na elke reset is de echo precies 10 s Leeg en verschijnt hij daarna op de plek waar P1 op het reset-moment stond. |

### 2.3 Lagen (antwoord op Producer-vraag 3)

**Regel in één zin: de echo bestaat alleen in de schaduw; hij wordt gedragen en geblokkeerd door wereld- en schaduwgeometrie, en hij kan alleen *gedeelde* objecten en *schaduw*objecten bedienen. De lichtlaag raakt hij nooit direct; hij beïnvloedt het licht alleen via gedeelde objecten** (bv. een gedeelde hendel die een lamp verzet).

| ID | Regel |
|---|---|
| **E-05** | Physics-lagen volgens `ontwerp.md` §8: P1 op laag 2 (licht), masker 1 + 4. Echo op laag 3 (schaduw), masker 1 + 5 voor de controles van E-08. Lichtgeometrie (laag 4) bestaat voor de echo niet; schaduwgeometrie (laag 5) bestaat voor P1 niet. |
| **E-06** | Elk interactief object heeft precies één **eigenaarslaag**: |

| Soort object | Wie kan het bedienen of raken | Voorbeelden |
|---|---|---|
| **Gedeeld** (wereld) | P1 én echo/P2 | Hendel, drukplaat, deur, gewone vijand |
| **Licht** | Alleen P1 | Lichtschakelaar, lichtplaat, lichtwezen, items, vaardigheden |
| **Schaduw** | Alleen echo/P2 | Schaduwhendel, schaduwplaat, schaduwwezen |

Technisch: het object luistert naar laag 2 + 3 (gedeeld), 2 (licht) of 3 (schaduw). Art maakt de drie soorten in één oogopslag uit elkaar te houden (pillar 2; leesbaarheid is aan de Art Director, #7).

| ID | Regel |
|---|---|
| **E-07** | **De echo als lichaam.** De echo is voor P1 een **eenrichtingsplatform** (alleen van boven; van opzij en van onder loop je erdoor). Staat P1 op de echo, dan beweegt P1 mee met de echo. De echo duwt niets en wordt door niets geduwd. De echo activeert drukplaten (gedeeld en schaduw) zolang hij erop staat. |
| **E-11** | **Fel licht.** Gebieden met fel licht zijn expliciete gameplay-zones (`FelLicht`, een `Area2D` die bij een lamp hoort), niet afgeleid van de rendering. Zo blijft het deterministisch; de Art/Technical Artist zorgt dat het beeld klopt met de zone. |
| **E-12** | De echo (en P2) verzamelt niets: geen items, geen vaardigheden, geen gezondheid. Alleen P1 verzamelt. |

### 2.4 Geblokkeerd pad: de echo breekt (antwoord op Producer-vraag 2)

Bij toestandsopname loopt de echo het oude pad, ook als de wereld sindsdien veranderd is. **Besluit LGD: klopt het oude pad niet meer met de huidige schaduwwereld, dan *breekt* de echo:** hij lost op in schaduwdeeltjes op de plek van het probleem, en de opname begint opnieuw (E-04d). Hij loopt dus niet door muren en hij blijft niet staan.

Waarom: door de muur lopen maakt schaduwgeometrie betekenisloos (pillar 2); stoppen laat een "bevroren" lichaam achter dat puzzels ongewild oplost (bv. blijvend op een drukplaat). Breken is eerlijk en leesbaar: je ziet precies wáár het oude plan niet meer klopt, en je bent hooguit 10 s kwijt.

| ID | Regel |
|---|---|
| **E-08** | Elke tick waarin de echo Actief is, controleert het spel frame `p`: **(a) Vrij:** de vorm van de echo overlapt op de opgenomen positie niet meer dan 2 px met laag 1 of 5. **(b) Steun:** als `op_vloer` waar was, vindt een ShapeCast van 4 px recht omlaag laag 1 of 5. Steunde P1 toen op licht-geometrie, dan moet er nu schaduwgeometrie of wereld onder liggen. Steunde P1 op een schaduwlichaam (de echo of P2), dan faalt (b) altijd. **(c) Licht:** het middelpunt van de echo ligt niet in een `FelLicht`-zone. **(d) Gevaar:** de echo raakt geen `Schaduwgevaar`-zone. Faalt (a) of (b) **G = 3 ticks achter elkaar**, of faalt (c) of (d) één tick, dan breekt de echo: breek-effect op de laatste geldige positie, events van deze tick worden niet uitgevoerd, `geldig_vanaf = t`. |

Gevolg dat we bewust accepteren: heb je op je echo gestaan, dan breekt hij 10 s later op dat punt ("je stond op jezelf; je echo heeft niemand om op te staan"). Dat is consistent met E-08b. Playtest let hierop (§5, vraag 2).

De kern-puzzel die hieruit volgt (pillar 2): P1 loopt over een **lichtbrug**, verzet aan de overkant een gedeelde hendel die de lamp draait. De lichtbrug verdwijnt en zijn **schaduwbrug** verschijnt. 10 s later loopt de echo over de schaduwbrug naar een schaduwplaat. Zonder de lamp te draaien breekt de echo bij de rand.

### 2.5 Wat de echo doet (events) en niet doet

| ID | Regel |
|---|---|
| **E-10** | Acties worden opgenomen als **event** op hun tick, ongeacht of ze bij P1 iets raakten: `AANVAL` (met richting), `INTERACTIE`, later vaardigheid-events. Bij afspelen voert de echo het event op tick `p` uit tegen de **huidige** wereld, met een hitbox of bereik op laag 3, volgens E-06. Voorbeeld: P1 drukt INTERACTIE bij een schaduwhendel (er gebeurt niets), 10 s later zet de echo hem om. |
| **E-13** | Schakelaars bestaan in drie gedragstypes: **Wissel** (elke bediening keert de stand om; de echo zet hem dus 10 s later terug), **Drukplaat** (actief zolang belast) en **Eenmalig** (eerste bediening telt, daarna vast). Levelontwerpers kiezen per object (L-05). |
| **E-14** | De echo heeft geen levenspunten en kan niet sterven. Vijandelijke aanvallen hebben in het prototype geen effect op de echo; alleen E-08 laat hem breken. Een treffer van de echo doet evenveel schade als de opgenomen treffer van P1 (parameter, Combat Designer stelt bij). |

**De echo kan niet:** door schaduwgeometrie, in fel licht bestaan, lichtobjecten bedienen of lichtwezens raken, iets oppakken, iets duwen, P1 schade doen, afwijken van wat P1 deed.

### 2.6 Loslaten (handmatig opnieuw beginnen)

| ID | Regel |
|---|---|
| **E-09** | P1 houdt de **echo-knop** 0,5 s (30 ticks) ingedrukt: de echo breekt (zelfde effect als E-08) en `geldig_vanaf = t`. Werkt ook als de echo Leeg is. Er komt een vijfde inputbit `ECHO` bij (`input_bits.gd`). In co-op heeft Loslaten geen zichtbaar effect (er is geen opgenomen echo), maar zet het wel `geldig_vanaf` (relevant bij drop-out, C-05). |

Dit houdt "opnieuw proberen" goedkoop zonder de tijdsdruk weg te nemen: je wacht nog steeds 10 s op je nieuwe echo.

### 2.7 Solo vs. co-op (antwoord op Producer-vraag 4)

**Besluit LGD: in co-op *is* P2 de schaduw. Er is dan geen opgenomen echo van P1 en ook geen echo van P2.** Dit volgt de richting van de Creative Director (pitch §11.1) en houdt de wereld leesbaar: altijd precies één lichaam in het licht en één in de schaduw.

| ID | Regel |
|---|---|
| **C-01** | Maximaal twee lichamen: P1 + echo (solo) of P1 + P2 (co-op). Nooit beide. |
| **C-02** | P2 is een speler op laag 3 met masker 1 + 5, met dezelfde beweging (`Motor.step`), dezelfde events en dezelfde objectregels als de echo (E-06, E-07, E-10, E-12, E-13). P2 kan niet op P1 staan (P1 is geen platform voor de schaduw), want de echo kan dat ook niet. P2 heeft geen levenspunten. |
| **C-03** | **Drop-in.** Een vrij apparaat drukt op "meedoen". Is de echo Actief: P2 neemt de huidige positie en snelheid van de echo over, het afspelen stopt, geen pauze en geen kamer-reset. Is de echo Leeg: P2 verschijnt op de positie van P1 (in de schaduw). Is die plek in laag 1 of 5 bezet, dan op de dichtstbijzijnde vrije plek binnen 64 px, anders op de laatste vloerpositie van P1. |
| **C-04** | De opname van P1 loopt in co-op gewoon door (E-01). E-04 blijft gelden (kamerwissel, respawn, Loslaten). |
| **C-05** | **Drop-out.** P2 houdt "stoppen" 1 s ingedrukt, of het apparaat van P2 is 3 s ontkoppeld. P2 lost op (breek-effect) en de echo van P1 neemt het meteen over volgens E-02/E-03: is `t − D ≥ geldig_vanaf`, dan verschijnt de echo op de plek waar P1 10 s geleden was; anders is hij Leeg tot dat wel zo is. **Zijn er nog geen 10 s van P1 opgenomen** (bv. vlak na een kamerwissel), dan is er dus geen echo totdat de buffer vol is, hooguit 10 s. Er wordt niets gesimuleerd of verzonnen om het gat te vullen. |
| **C-06** | **P2 lost op** bij fel licht, een schaduwgevaar, uit de wereld vallen, of de leiband (C-07). P2 verschijnt na 2 s (120 ticks) opnieuw naast P1 volgens de plaatsingsregel van C-03. Geen checkpoint-reset; P1 merkt alleen dat de schaduw even weg is. (Antwoord op pitch-vraag 3: de schaduwspeler faalt vergevingsgezind.) |
| **C-07** | **Leiband.** De gedeelde camera houdt beide spelers in beeld tot zijn maximale zoom. Staat P2 langer dan 1 s buiten dat beeld, dan geldt C-06. P1 bepaalt waar de camera heen gaat; P1 wordt nooit verplaatst. Waarden van de camera: UX Designer en Technical Director. |
| **C-08** | Sterft P1, dan respawnen beiden; P2 verschijnt naast P1. |

**Waarom co-op hiermee niet triviaal wordt** (pitch-risico): P2 houdt alle beperkingen van de echo (alleen schaduw, geen lichtobjecten, lost op in licht, moet in beeld blijven). Wat P2 extra heeft, is *timing*: live in plaats van 10 s later. Dat verandert de puzzel van plannen naar afstemmen, precies zoals pillar 3 vraagt. Extra bereik van P2 mag op de kritieke route en voor verzamelobjecten niets opleveren (L-02).

### 2.8 Regels voor levelontwerp

Voor World & Level Designer en Systems Designer.

| ID | Regel |
|---|---|
| **L-01** | Een echo-kamer op de kritieke route is niet op te lossen met P1 alleen. |
| **L-02** | Elke plek of elk object dat de schaduw op de kritieke route of voor een verzamelobject moet bereiken, is ook bereikbaar voor de **solo-echo**: via een pad dat P1 kan lopen en dat bij het afspelen door wereld- of schaduwgeometrie gesteund wordt. Plekken die alleen een live P2 bereikt, bevatten niets. (Geen co-op-only content, pillar 3.) |
| **L-03** | Poorten zijn licht-, schaduw-, echo- of vaardigheidspoorten. Geen gekleurde sleutels (pillar 2). |
| **L-04** | Een echo-puzzel vraagt hooguit één volle echo-cyclus (10 s) voorbereiding per stap. Langere reeksen worden in stappen gehakt met Eenmalige schakelaars. |
| **L-05** | Gebruik een Wissel-schakelaar alleen als het terugzetten door de echo deel van de puzzel is; anders Eenmalig of Drukplaat (E-13). |

### 2.9 Parameters

| Parameter | Waarde | Testbereik | Wie stelt bij |
|---|---|---|---|
| D, echo-vertraging | 600 ticks (10 s) | 360 / 600 / 840 (6 / 10 / 14 s) | LGD na playtest; definitief afwijken van 10 s is een CEO-besluit (pitch §10) |
| G, tolerantie vrij/steun | 3 ticks | 1–6 | LGD |
| Overlap-tolerantie (E-08a) | 2 px | 0–4 | LGD + TD |
| Steuncontrole (E-08b) | 4 px omlaag | 2–8 | LGD + TD |
| Loslaten | 30 ticks vasthouden | 15–45 | UX Designer |
| P2 terugkeer na oplossen | 120 ticks | 60–180 | LGD + UX |
| P2 buiten beeld voor oplossen | 60 ticks | 30–120 | UX |
| Drop-in plaatsingsstraal | 64 px | — | LGD |
| Drop-out: apparaat weg | 180 ticks | — | Engine & Platform |
| Echo-schade | 100 % van P1 | 50–100 % | Combat Designer |

### 2.10 Playtestvraag van dit systeem

Zie §5: alle drie de prototypevragen gaan over de echo.

### 2.11 Open vragen bij de echo

| # | Vraag | Aan | Tegen |
|---|---|---|---|
| O-1 | Kunnen vijanden de echo als doelwit kiezen (en zo ja, wat gebeurt er bij een treffer)? | Combat Designer | Preproductie |
| O-2 | Hoe zien Leeg, Actief, Breken en "nog X s tot je echo terugkomt" eruit (HUD of in de wereld)? | UX Designer, Art Director | Voor de eerste playtest |
| O-3 | Hoe past *Ankeren* binnen C-01 (max. twee lichamen) in co-op? | Systems Designer, LGD | Bij uitwerking vaardigheden |
| O-4 | Moet de echo ook audio afspelen (voetstappen, sprong)? Voorstel: ja, gedempt, als hulp om hem buiten beeld te volgen. | Audio Director | Preproductie |

---

## 3. Vaardigheden (schets)

Eén vaardigheid per gebied (4 gebieden, besluit 2026-11-08). Elke vaardigheid is vooral iets nieuws wat de **echo** kan (pillar 1). Uitwerking (regels, parameters) door de Systems Designer; dit is de richting.

| # | Vaardigheid | Wat | Pillar | Solo | Co-op | Playtestvraag |
|---|---|---|---|---|---|---|
| 1 | **Dempen** | P1 dimt een lamp tijdelijk; de `FelLicht`-zone verdwijnt zolang | 2 (licht als poort) | Dempen nu, echo loopt er 10 s later doorheen | P1 dempt terwijl P2 er live doorheen gaat | Snappen spelers dat ze moeten dempen *voordat* de echo aankomt? |
| 2 | **Dragen** | De echo draagt een lichtvoorwerp (bv. een lantaarn) dat P1 op dat moment droeg, en zet het neer waar P1 het neerzette | 1, 2 | Lantaarn naar de schaduwkant brengen via je eigen verleden | P2 draagt het live | Voelt het als "mijn verleden helpt me", of als een trucje? |
| 3 | **Ankeren** | Zet de huidige 10 s vast als lus die blijft herhalen tot Loslaten of kamerwissel (pitch-vraag 2) | 1 | Eén vastgezet lichaam + jij | Open (O-3) | Holt een lus de 10-secondenregel uit? |
| 4 | **Wisselen** | P1 wisselt van plaats met de echo (of met P2) | 1, 3 | Bereik plekken waar je 10 s geleden was | Spelers wisselen live van plaats | Wordt wisselen een vluchtknop die puzzels omzeilt? |

Bewust **niet**: dubbele sprong, dash of wall-jump als losse vaardigheid zonder echo-betekenis (pitch, pillar 1 "past niet"). Komen ze er toch, dan alleen met een echo-functie (bv. de echo herhaalt de dash als aanval).

---

## 4. Prototype-specificatie

Doel: de echo-regels uit §2 speelbaar maken op de spike (`game/`), in 5 testkamers. Na de Lead-review zet de LGD dit om in issues voor de Gameplay Programmer (via de Technical Director), met deze acceptatiecriteria.

### 4.1 Wat het prototype heeft

- P1 met de spike-beweging, AANVAL, INTERACTIE en ECHO-knop.
- Echo volgens E-01 t/m E-14, P2 volgens C-01 t/m C-08.
- Objecten: gedeelde/licht/schaduw-drukplaat, Wissel- en Eenmalige hendel, deur, lamp met `FelLicht`-zone en lichtbrug/schaduwbrug, één eenvoudige vijand (gedeeld) en één schaduwwezen.
- Een schakelaar in het debugmenu voor D = 6 / 10 / 14 s.
- Placeholder-art: drie kleuren voor gedeeld / licht / schaduw.

### 4.2 Testkamers

| Kamer | Wat de speler moet doen | Toetst |
|---|---|---|
| T1 Deur | Op een gedeelde drukplaat staan, doorlopen; de echo houdt de deur open | E-02, E-07 |
| T2 Opstap | Springen bij een hoge richel; 10 s later op de echo staan om erop te komen | E-07, E-08b (echo breekt daarna) |
| T3 Schaduwhendel | INTERACTIE bij een schaduwhendel die P1 niet kan bedienen; de echo zet hem om | E-06, E-10 |
| T4 Lampbrug | Over de lichtbrug, aan de overkant de lamp draaien; de echo loopt over de schaduwbrug naar een schaduwplaat | E-05, E-08b, E-11 |
| T5 Dubbele slag | Een vijand met een schild dat alleen breekt als P1 en echo binnen 0,25 s raken | E-10, E-14 |

Alle vijf kamers moeten zowel solo als in co-op op te lossen zijn (L-02).

### 4.3 Acceptatiecriteria (automatisch te testen, headless zoals de spike)

| Regel | Test |
|---|---|
| E-02 | Na 600 ticks staat de echo op de positie van P1 op tick `t − 600` (0 px verschil). |
| E-03/E-04 | Na een kamerwissel op tick `t0` is de echo Leeg op `t0 + 599` en Actief op `t0 + 600`, op de positie van P1 op `t0`. |
| E-06 | Echo op een lichtplaat: plaat blijft uit. Echo op een schaduwplaat: plaat gaat aan. P1 op een schaduwplaat: plaat blijft uit. |
| E-07 | P1 die van boven op de echo landt, blijft staan; P1 die van opzij komt, loopt erdoor. |
| E-08a | Een schaduwmuur op het pad na opname: echo breekt binnen 3 ticks na de eerste overlap; `geldig_vanaf` = die tick. |
| E-08b | Lichtbrug weg en geen schaduwbrug: echo breekt aan de rand. Wel een schaduwbrug: echo loopt door. |
| E-08c | Echo die een `FelLicht`-zone binnengaat, breekt op dezelfde tick. |
| E-09 | 30 ticks ECHO ingedrukt: echo breekt; 29 ticks: niet. |
| E-10 | INTERACTIE bij een schaduwhendel op tick `x`: de hendel gaat om op tick `x + 600`. |
| E-13 | Wissel-hendel door P1 op `x`: op `x + 600` zet de echo hem terug. Eenmalige hendel: blijft om. |
| C-03 | Drop-in met Actieve echo: P2 start op de positie en snelheid van de echo; er is daarna geen echo. |
| C-05 | Drop-out 300 ticks na kamerwissel: echo Leeg tot tick 600 na de kamerwissel. Drop-out 900 ticks na kamerwissel: echo direct Actief op de positie van P1 van 600 ticks geleden. |
| C-06 | P2 in `FelLicht`: P2 weg; 120 ticks later naast P1. |

---

## 5. Playtestvragen voor het prototype

| # | Vraag | Hoe we het meten | Wanneer het goed is |
|---|---|---|---|
| 1 | **Is 10 s de juiste lengte?** Kunnen spelers voorspellen waar hun echo straks is, en plannen ze vooruit in plaats van te wachten? | T1–T5 met D = 6, 10 en 14 s (per speler één waarde). Meten: tijd per kamer, aantal keer Loslaten, wachttijd zonder input. Na afloop: "wist je waar je echo zou zijn?" (1–5). | Bij 10 s: gemiddeld ≥ 4 op voorspelbaarheid én minder dan 30 % van de kamertijd stilstaand wachten. |
| 2 | **Voelt breken eerlijk?** Begrijpen spelers waarom de echo brak, en voelt 10 s opnieuw wachten als een kleine prijs of als straf? | T2 en T4 observeren. Na een breek: "waarom brak je echo?" Juiste uitleg telt als begrepen. Ook: frustratie-score (1–5). | ≥ 80 % juiste uitleg; frustratie gemiddeld ≤ 2. Zo niet: kortere hersteltijd na breken testen. |
| 3 | **Werkt dezelfde kamer in co-op als afstemmen, zonder triviaal te worden?** En voelen drop-in en drop-out naadloos? | T1–T5 door duo's (één ervaren, één minder ervaren speler), minstens één drop-in en één drop-out per sessie. Meten: tijd per kamer vs. solo, aantal gesprekken over timing, "had de schaduwspeler een echte rol?" (1–5, beide spelers). | Co-op niet meer dan 2× zo snel als solo; schaduwrol ≥ 4 bij de minder ervaren speler; drop-in/out zonder vragen of verwarring. |

---

## 6. Antwoorden op de vragen uit #6 en `ontwerp.md` §11

| Vraag | Antwoord | Regel |
|---|---|---|
| 1. Opnamemodel: vaste clip of altijd 10 s achter je aan? | Altijd 10 s achter je aan, toestandsopname, events tegen de huidige wereld. Een vaste lus wordt later de vaardigheid Ankeren. | E-01–E-04, §3 |
| 2. Wat als de opgenomen route geblokkeerd is? | De echo breekt (niet door de muur, niet stoppen); opname begint opnieuw. | E-08 |
| 3. Echo in de schaduw, maar raakt dingen in het licht? | Echo raakt alleen gedeelde en schaduwobjecten; het licht beïnvloedt hij alleen via gedeelde objecten. | E-05, E-06, E-11 |
| 4. Co-op: naast P2 nog een opgenomen echo? Drop-in tijdens afspelen? Drop-out zonder 10 s buffer? | Nee, P2 *is* de schaduw. Drop-in: P2 neemt de echo over op zijn plek. Drop-out: echo neemt over vanaf de buffer van P1, die altijd doorloopt; is die nog geen 10 s gevuld, dan is de echo Leeg tot hij vol is. | C-01–C-05 |
| 5. Toets aan de pillars | Zie `kernloop.md` §6: alle onderdelen scoren ja op alle drie; twee bewuste uitzonderingen benoemd. | — |
| TD: mag de echo fysiek beïnvloeden (platform, duwen)? | Platform ja (eenrichting, van boven), duwen nee. | E-07 |
