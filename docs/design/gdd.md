# Game Design Document *Echoborn*

Versie 0.3 (echo-regels v0.4) · Eigenaar: Lead Game Designer (met Combat Designer voor E-14 en E-02m) · Issue [#67](https://github.com/cesarvangerwen-glitch/echoborn/issues/67) (T3a, `docs/productie/fase-2-kader.md` §2) · vorige versie: #6
Bronnen: `docs/concept/pitch.md` **v0.4** (pillars P1–P3, §4 flownormen, §12 delta), `docs/beslissingen.md` (o.a. **#51 deel 2**: 1A, 7A, 8A; stijl 2D #18), `docs/business/ideecheck-v0-4.md` §2 (afwijkpunten 1–6), `docs/tech/ontwerp.md` (echo-spike).
Kernloop, diagrammen en pillartoets: `docs/design/kernloop.md` (wordt herzien in T3c).

Deze versie zet de echo om naar pitch v0.4: een **korte staart van ± 2 s** (E-02), de **merksprong** (E-02m), de **echo volgt je door de deur** (E-04a), de **springplank** met bounce (E-07a), **op je echo staan breekt hem niet** (E-08b), het **schaduwmerk** (E-14), een **minimale lichtmeter met één gemaal** (§2.12) en de **flow-kamer** als eerste mijlpaal (§4). Wat níét in deze versie zit, met de taak die het oppakt: co-op C-01–C-08 en de solo-vormen van lancering en vangen (T3b, [#75](https://github.com/cesarvangerwen-glitch/echoborn/issues/75)); vaardigheden, L-regels voor de slice, genezen met de lichtmeter, waterstand voor meer wijken en `kernloop.md` (T3c).

**Afspraken.**
- Elke regel heeft een ID: E- (echo), C- (co-op), L- (levelontwerp). **Elke E- en C-regel heeft een automatische test in §4.3.** L-regels toetsen we met een reviewchecklist of playtest; dat staat er ook in §4.3 bij.
- Tijden staan in **ticks van 60 Hz** (de vaste simulatietick, `ontwerp.md` §2). "Nu" is tick `t`.
- **px = wereldpixel**: één pixel van het 640×360-beeld (stijlbesluit 2D, #18). Een figuur is ±30 px hoog (stijltest: ±60 px op 1280×720). Afstanden worden opnieuw bekeken als de Art Director de figuurgrootte vastlegt.
- **Schade-eenheden (SE)** en **lichtpunten (LP)** zijn abstracte gehele getallen (§2.5a, E-14, §2.12).
- Elke regel heeft een **D** waar v0.2 "600 ticks" of "10 s" schreef: D is de staartlengte uit E-02. Waar een C-regel nog 600 ticks of 10 s noemt, lees D tot T3b de C-regels herziet.
- **Werkaannames van deze versie** (kader §5): CEO-besluiten #2 (5–7 uur, PEGI 12), #18 (2D) en #51 deel 2 (1A, 7A, 8A; uitgewerkt in pitch v0.4) en fasekader fase 2 v0.2. Daarnaast **werkaanname LGD**: alle getallen in §2.5a (beweging), E-02m, E-14 en §2.12 zijn **startwaarden voor de flow-kamer**. Ze zijn gekozen om de flownormen te kunnen halen en worden na de flow-test (T17) bijgesteld; de schadewaarden stelt de Combat Designer bij. Geen andere aannames.

---

## 1. Basis: twee lichamen, twee lagen

- **Het lichtpersonage (P1)** leeft in de lichtlaag. Het is de speler, heeft levenspunten, verzamelt items en vaardigheden.
- **De schaduw** leeft in de schaduwlaag. Solo is de schaduw de **echo**: een opname van P1 van D ticks (± 2 s) geleden. In co-op is de schaduw **speler 2 (P2)**, live bestuurd: de partner ís de echo (pitch P3, #51: 7A).
- Er zijn nooit meer dan **twee lichamen** tegelijk, plus in co-op de gedeelde echo als finisher (C-01, herzien in T3b).
- In beeld (stijltest 2D): **levend = vol, echo = hol**. P1 vol amber, P2 vol donker met cyaan contour, de echo gerasterd met de contour van P1. Uitwerking: Art Director.

Basisbeweging (lopen, springen, dash) voor de flow-kamer staat in §2.5a; aanval en interactie in §2.5. De echte uitwerking komt van de Combat Designer en Gameplay Programmer (T3c).

---

## 2. Systeem: de echo

### 2.1 Doel

De echo houdt je in beweging (pillar 1): hij is je **springplank** waar jij net was en hij laat je **merken knallen** waar jij net sloeg. Hij leeft in de schaduw (pillar 2) en is solo dezelfde rol die P2 in co-op live speelt (pillar 3). Toetsvraag bij elke regel hieronder: *maakt de echo deze actie vloeiender of krachtiger, zonder dat de speler ervoor moet stilstaan?*

### 2.2 Opnamemodel

**Besluit LGD: de echo loopt altijd D ticks (± 2 s) achter je aan, en speelt de opgenomen *toestand* af.** Er is geen knop om op te nemen of af te spelen; de echo is er gewoon, net als je schaduw. De korte staart volgt besluit #51 (8A: ± 2 s, bereik 1,5–3 s); de 10 s blijven in het verhaal, het einde en de co-op-finisher (T3b). Toestandsopname volgt de aanbeveling van de Technical Director (`ontwerp.md` §4).

Waarom geen vastgezette clip op een knop: dan wordt de echo een gereedschap dat je soms pakt, in plaats van een lichaam dat altijd meedoet. Waarom ± 2 s: met een korte staart komt de echo binnen een tel of twee vóór of onder je uit bij keren, klimmen en lussen (pitch §5), zonder te wachten (norm 1). De enige afwijking van het opgenomen pad is de merksprong (E-02m).

| ID | Regel |
|---|---|
| **E-01** | P1 wordt elke tick opgenomen, na zijn stap: positie, snelheid, kijkrichting (E-10a), `op_vloer`, **steunsoort** (`wereld` / `licht` = licht-geometrie / `schaduwlichaam` = echo of P2, zie E-07), animatietoestand, en de events van die tick (E-10). De opname loopt altijd, ook in co-op (C-04). |
| **E-02** | **Korte staart.** De echo toont op tick `t` de opgenomen toestand van frame `p = t − D`. **D = 120 ticks (2 s)**; testwaarden **90 / 120 / 180** (1,5 / 2 / 3 s, bereik besluit #51: 8A). D is een parameter die per sessie vastligt (debugmenu, §4.1); een wissel van D tijdens het spel telt als reset (E-04c). De echo wordt niet gesimuleerd: hij staat waar P1 op tick `p` stond, met de opgenomen kijkrichting en animatietoestand. **Enige uitzondering:** de merksprong (E-02m). De recorder bewaart minstens 600 frames, ook al gebruikt de echo er maar D: de co-op-finisher speelt de laatste 10 s af (8A, T3b). |
| **E-02m** | **Merksprong.** Bevat frame `p` een AANVAL-event (E-10), dan zoekt het spel op tick `t` het **doelmerk**: het schaduwmerk (E-14) waarvan het middelpunt het dichtst bij het middelpunt van de echo op frame `p` ligt, binnen **straal R = 80 px**, met een vrije zichtlijn (een raycast tussen beide middelpunten raakt laag 1 en 5 niet). Bij gelijke afstand wint het oudste merk. **Geen doelmerk:** een gewone echo-treffer op de opgenomen positie (E-10a, E-14e). **Wel een doelmerk:** de echo doet een merksprong van **M = 12 ticks** in plaats van de gewone treffer. *Heen* (k = 0…3, tick `t + k`): positie = `lerp(opname(t + k), merk(t + k), (k + 1) / 4)`. Op tick `t + 3` staat de echo op het merk en laat het ontploffen (E-14d). *Terug* (j = 1…8, tick `t + 3 + j`): positie = `lerp(merk(t + 3), opname(t + 3 + j), j / 8)`. Daarna staat hij weer op zijn opname (E-02). Tijdens de merksprong: de schaduwplank staat **uit** (P1 kan er niet op landen); de controles E-08a en E-08b worden **niet** gedaan (ze gaan over het opgenomen pad), E-08c en E-08d **wel**, op de werkelijke positie (breekt de echo, dan is er geen ontploffing als het vóór tick `t + 3` gebeurt). Verdwijnt het doelmerk tijdens *heen* (vijand dood, merk gedoofd), dan begint *terug* meteen vanaf de huidige positie, zonder ontploffing. INTERACTIE-events in frames tijdens de merksprong werken op de opgenomen positie (E-10b). Een tweede AANVAL-event valt nooit in een merksprong (herhaaltijd 20 ticks > M). In beeld: **een schaduw die uitrekt** naar het merk en terugveert, geen dash met een voorwerp (ideecheck punt 4). |
| **E-03** | Er is één waarde `geldig_vanaf`. De echo is **Actief** als `p ≥ geldig_vanaf`, anders **Leeg**: onzichtbaar, geen botsingen (ook geen schaduwplatform, E-07), geen events, geen controles (E-08). Frames van vóór `geldig_vanaf` worden nooit afgespeeld. |
| **E-04** | `geldig_vanaf = t` wordt gezet bij: (a) een **kamerwissel van P1 naar een kamer die geen buur is** van de vorige kamer (E-04a, E-04e), (b) respawn van P1 (ook terugzetten uit diep water, LM-06), (c) *Loslaten* (E-09) of een wissel van D (E-02), (d) breken van de echo (E-08). Dit is het enige reset-mechanisme. Gevolg: na elke reset is de echo precies D ticks Leeg en verschijnt hij daarna op de plek waar P1 op het reset-moment stond. |
| **E-04a** | **De echo volgt je door de deur** (was O-5; pitch §12, R12/R-V3). Elke `Kamer` heeft een lijst `buren`: de kamers waarmee hij een doorgang deelt (gezet door de level designer, altijd wederzijds). Een kamerwissel naar een buur zet **geen** reset: de echo speelt door, ook als frame `p` nog in de vorige kamer ligt, en loopt een tel later dezelfde doorgang door. Ligt het middelpunt van frame `p` in een kamer die op tick `t` **niet geladen** is, dan is de echo die tick **Buiten**: hetzelfde als Leeg (onzichtbaar, geen botsing, geen plank, geen events, geen controles), maar **zonder** reset; zodra frame `p` weer in een geladen kamer ligt, is hij weer Actief. Events van Buiten-frames worden niet uitgevoerd. Geladen zijn minstens de kamer van P1 en al zijn buren (AreaLoader, T5b); tot T5b is de hele flow-kamer één geladen scène, dus komt Buiten daar niet voor. Voor de meting (MP-4) telt Buiten als Leeg. |
| **E-04e** | **Wat een kamer is.** Een kamer is een `Kamer`-node in de gebiedsscène: een rechthoekige `Area2D` die tegelijk de **camerazone** en de **streameenheid** van de AreaLoader is (`ontwerp.md` §3). Kamers overlappen niet. De kamer van P1 is de kamer waarvan de rechthoek het middelpunt van P1 bevat. Verandert die waarde, dan is dat een kamerwissel. P2 en de echo veroorzaken nooit een kamerwissel. Een kamer mag meerdere schermen groot zijn. Of een kamerwissel een reset is, bepaalt E-04a (buur of niet). |

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
| **E-07a** | **Springplank** (pitch §12; ideecheck M2: beweging in vaart, geen stilstand). Vijf delen: **(1) Meebewegen.** Stond P1 aan het eind van tick `t − 1` op een schaduwplank (`op_vloer` en de vloer is laag 6), dan krijgt P1 aan het begin van zijn stap op tick `t` de verplaatsing van de plank: `Δ = plankpositie(t) − plankpositie(t − 1)`, horizontaal én verticaal. Die verplaatsing gaat met `move_and_collide` tegen laag 1 + 4: botst P1, dan schuift hij niet verder dan de muur en blijft de plank onder hem doorgaan. Daarna volgt de gewone beweging (§2.5a) met de input van P1. **(2) Landen = vaart houden + dash terug.** Op de tick waarop P1 van boven op een schaduwplank landt: `v.y = 0`, `v.x` blijft wat hij was (geen afremming), een lopende dash loopt door tot zijn 10 ticks om zijn, en P1 krijgt zijn dash terug (`dash_klaar = true`; geldt ook voor een luchtsprong als die ooit komt). Dit is een **springplank-landing** (event `SPRINGPLANK` voor lichtmeter en meting). Een nieuwe springplank-landing telt pas als P1 de plank minstens 1 tick verlaten heeft. **(3) Afzetten = bounce.** Een sprong vanaf een schaduwplank is een **bounce**: `v.y = −6,0 px/tick` in plaats van −5,0 (± 72 px in plaats van ± 50 px hoog), `v.x` blijft, dash terug. Een JUMP-flank telt als bounce als P1 op de plank staat, als hij ≤ **10 ticks vóór** het landen viel (buffer: de bounce gaat dan af op de landingstick), of ≤ **6 ticks na** het verlaten van de plank (coyote). Event `BOUNCE`. **(4) Geen plank-snelheid.** Na het verlaten krijgt P1 **geen** snelheid van de plank mee: alleen zijn eigen vaart telt. Ingebouwde platformsnelheid van Godot staat uit (`platform_on_leave = DO_NOTHING`, `platform_floor_layers` zonder laag 6), zodat er maar één regel is. **(5) Wie.** Dit geldt voor elke schaduwplank (echo en P2). Bounce op je partner, lancering en vangen in beide vormen legt T3b vast. |
| **E-07b** | **Volgorde per tick** (vult `ontwerp.md` §2.2 aan; de TD bevestigt): (1) de schaduw: de echo zet frame `p` en doet zijn controles (E-08), óf P2 stapt; (2) P1 stapt, inclusief E-07a; (3) P1 wordt opgenomen (E-01); (4) events uitvoeren, eerst van P1, dan van de schaduw (E-10); (5) objecten (drukplaten, schakelaars, zones, schild) werken hun stand bij. Daardoor beweegt P1 in dezelfde tick mee, zonder een tick achter te lopen. |
| **E-11** | **Fel licht.** Gebieden met fel licht zijn expliciete gameplay-zones (`FelLicht`, een `Area2D` op laag 7 die bij een lamp hoort), niet afgeleid van de rendering. Alleen de zone telt: staat de lamp in beeld aan maar is de zone uit, dan bestaat er geen fel licht. Zo blijft het deterministisch; de Art Director en Technical Artist zorgen dat het beeld klopt met de zone. |
| **E-12** | De echo (en P2) verzamelt niets: geen items, geen vaardigheden, geen gezondheid. Alleen P1 verzamelt (pickups luisteren naar laag 2). |

### 2.4 Geblokkeerd pad: de echo breekt

Bij toestandsopname loopt de echo het oude pad, ook als de wereld sindsdien veranderd is. **Besluit LGD: klopt het oude pad niet meer met de huidige schaduwwereld, dan *breekt* de echo:** hij lost op in schaduwdeeltjes op de plek van het probleem, en de opname begint opnieuw (E-04d). Hij loopt dus niet door muren en hij blijft niet staan.

Waarom: door de muur lopen maakt schaduwgeometrie betekenisloos (pillar 2); stoppen laat een "bevroren" lichaam achter op een plek waar het niet hoort. Breken is eerlijk en leesbaar: je ziet precies wáár het oude pad niet meer klopt, en je bent hooguit D ticks (± 2 s) kwijt.

| ID | Regel |
|---|---|
| **E-08** | Elke tick waarin de echo Actief is, controleert het spel frame `p`: **(a) Vrij:** de vorm van de echo overlapt op de opgenomen positie niet meer dan 2 px met laag 1 of 5. **(b) Steun** (herzien in v0.4, "E-08b"): als `op_vloer` waar was **en de steunsoort `wereld` of `licht` was**, vindt een ShapeCast van 4 px recht omlaag laag 1 of 5. Steunde P1 toen op licht-geometrie, dan moet er nu schaduwgeometrie of wereld onder liggen. **Steunde P1 op een schaduwlichaam** (steunsoort `schaduwlichaam`: hij stond op de echo of op P2), **dan wordt (b) overgeslagen**: de echo zweeft door die frames heen op zijn opgenomen positie en breekt niet. (a), (c) en (d) blijven gelden, en zijn plank blijft aan (P1 kan op een zwevende echo landen). **(c) Licht:** het middelpunt van de echo ligt niet in een `FelLicht`-zone. **(d) Gevaar:** de vorm van de echo overlapt geen `Schaduwgevaar`-zone (laag 7, bv. schaduwdoorns of een licht-val). Faalt (a) of (b) **G = 3 ticks achter elkaar**, of faalt (c) of (d) één tick, dan breekt de echo: breek-effect op de laatste geldige positie, events van deze tick worden niet uitgevoerd, `geldig_vanaf = t`. |

**Waarom E-08b nu anders is** (v0.2 brak de echo hier): een springplank-ketting is juist "op je echo staan". Brak de echo D ticks later op dat punt, dan brak elke ketting zichzelf en was de echo vaak Leeg (R12). Wat de speler ziet: de echo hangt even in de lucht waar jij op hem stond, met een effect van de Art Director (zwevende schaduw, geen breek-effect).

Gevolg dat blijft: P1 loopt dwars door schaduwgeometrie, dus overal waar P1 dat deed, breekt de echo. Daarom regel L-06: schaduwgeometrie staat niet op normale looppaden.

De lampbrug uit v0.2 (een licht-raadsel) vervalt: pillar 2 opent wegen via licht dat je terugwint, vaardigheden en routes, niet via raadsels.

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
| 8 | 256 | `DASH` | Dash (§2.5a); nieuw in v0.4 | Nee (zit in de toestand) |

Bit 6 en 7 (`UP`, `DOWN`) zijn **gereserveerd** voor de Combat Designer (aanval omhoog/omlaag, preproductie). De flow-kamer gebruikt ze niet. Knopvoorstel DASH: **Shift** of rechter schouderknop (rebind: UX Designer).

**Meedoen en stoppen zijn géén bits.** Ze horen bij de `InputRouter` (`ontwerp.md` §5): ze werken op apparaatniveau, voordat er een speler is, en worden niet opgenomen.

| Actie | Knop (voorstel; het rebindscherm is van de UX Designer) | Regel |
|---|---|---|
| Meedoen | **Start/Menu** op een vrije joypad, of **Enter** op de P2-helft van het toetsenbord | C-03 |
| Stoppen | **Select/View** (toetsenbord: **Backspace**) 60 ticks vasthouden op het apparaat van P2 | C-05 |
| Echo-knop | P1: **Q** of linker schouderknop | E-09 |

| ID | Regel |
|---|---|
| **E-10** | **Events.** Een event ontstaat op de tick waarop het bit van 0 naar 1 gaat (flank, `ontwerp.md` C8). `AANVAL` heeft een herhaaltijd van 20 ticks: binnen 20 ticks na een AANVAL-event ontstaat geen nieuw AANVAL-event. Events worden opgenomen ongeacht of ze bij P1 iets raakten. Bij afspelen voert de echo het event van frame `p` uit tegen de **huidige** wereld, met zijn eigen vlak op laag 3, volgens E-06. Voorbeeld: P1 drukt INTERACTIE bij een schaduwhendel (er gebeurt niets), D ticks later zet de echo hem om. Een AANVAL-event van de echo is een merksprong of een gewone treffer (E-02m). |
| **E-10a** | **Kijkrichting en aanvalsrichting.** Kijkrichting is `+1` (rechts) of `−1` (links), begint op `+1`, wordt `−1` op een tick met alleen `LEFT` en `+1` met alleen `RIGHT`; anders blijft hij gelijk. De **aanvalsrichting is de kijkrichting** (horizontaal; geen UP/DOWN in het prototype). Het aanvalsvlak is een rechthoek van 20 × 16 px direct vóór het lichaam in de kijkrichting, **1 tick** actief: op de event-tick. De echo gebruikt de *opgenomen* kijkrichting van frame `p`, niet een nieuw berekende. |
| **E-10b** | **Interactie.** Een INTERACTIE-event bedient het object waarvan het interactievlak het lichaam overlapt op die tick (bij meerdere: het dichtstbijzijnde middelpunt). Voor de echo: het lichaam op de positie van frame `p`, op laag 3. |
| **E-13** | Schakelaars bestaan in drie gedragstypes: **Wissel** (elke bediening keert de stand om; de echo zet hem dus D ticks later terug), **Drukplaat** (actief zolang belast) en **Eenmalig** (eerste bediening telt, daarna vast). Levelontwerpers kiezen per object (L-05). |
| **E-14** | **Schaduwmerk** (pitch §12; startwaarden LGD, de Combat Designer stelt de schade bij). Neemt de afwijkpunten 1–5 van de ideecheck over (§2.13). **(a) Merk zetten.** Een treffer van **P1** (zijn aanvalsvlak, E-10a, overlapt op de event-tick de hurtbox van een `Merkbaar` object: een vijand of een pantser) op een object **zonder** merk zet één merk. **Max. 1 merk per object**: een treffer op een object dat al een merk heeft, zet niets bij en verlengt niets (geen stapel, geen teller per vijand). Het merk hangt aan het object en beweegt mee. Solo zet alleen P1 merken; wie in co-op merkt, legt T3b vast. **(b) Levensduur.** Een merk leeft **D + 30 ticks** (de echo komt dus altijd op tijd langs, ook bij D = 180). De laatste 60 ticks telt het af in beeld en geluid (carillon, R-V1). Daarna dooft het zonder effect. **(c) De ontsteker is altijd een tweede lichaam.** Alleen de echo (via E-02m) en in co-op P2 (T3b) laten een merk ontploffen. P1 heeft geen ontsteekknop en geen "vasthouden om te laden"; een treffer van P1 op een gemerkt object doet gewoon 10 SE en laat het merk staan. **(d) Ontploffing.** Op tick `t_o`: elk vijand- of pantserobject binnen **E = 32 px** van het merkmiddelpunt (ook de drager) krijgt **O = 20 SE**, en het merk is weg. **Ketting:** elk ander merk met zijn middelpunt binnen **K = 48 px** van een ontploffend merk ontploft op tick `t_o + 1`, enzovoort (één schakel per tick; volgorde binnen een tick op merk-id). Schakel `k` (de eerste is k = 1) doet `O × (1 + 0,25 × (min(k, 5) − 1))`, afgerond naar beneden: 20, 25, 30, 35, 40 SE. Meer merken betekent dus een grotere ontploffing **door ketting en positie**, niet door stapelen op één vijand. Ontploffingen doen P1, P2 en de echo niets. **(e) Treffer zonder merk.** P1-treffer: **10 SE**. Gewone echo-treffer (geen doelmerk, E-02m): **5 SE**. **(f) Pareren geeft nooit een merk.** Pareren zit niet in de flow-kamer; komt het (T3c, Combat Designer), dan geeft het iets anders, bv. licht (§2.12) of de dash terug. **(g) Pantser.** Een `Pantserdoel` krijgt van treffers van P1 of de echo 0 SE (een merk zetten kan wel); één ontploffing breekt het pantser, daarna is het een gewone vijand. Dit is de bouwsteen voor "een pantser breekt alleen door een merk-ontploffing" bij bosses (pitch P1). **(h) De echo is onkwetsbaar.** Hij heeft geen levenspunten en kan niet sterven. Vijandelijke aanvallen maskeren alleen laag 2 en hebben geen effect op de echo (of P2); alleen E-08 laat de echo breken. **(i) Naam en beeld.** In code en tekst heet het `Schaduwmerk` of "merk", nooit "talisman" of "seal". Beeld: een lichtvonk in de vorm van een **peil- of sluismerk**, met een carillon-aftelling; geen zegel, talisman of taoïstische symboliek (Art Director T1, Audio Director T2). |

**De echo kan niet:** door schaduwgeometrie, in fel licht of een schaduwgevaar bestaan, lichtobjecten bedienen of lichtwezens raken, iets oppakken, iets duwen, P1 schade doen, merken zetten, afwijken van wat P1 deed (behalve de merksprong, E-02m).

### 2.5a Minimale beweging voor de flow-kamer

Werkaanname LGD, zodat de flow-kamer en de maten in §4.3 te bouwen zijn. Vervangt de spike-waarden van `Motor.step` (die zijn op een andere schaal); de Gameplay Programmer zet ze als constanten, de LGD stelt bij na T17. Het lichaam van P1, P2 en de echo is **16 × 30 px**. Er is bewust **geen** dubbele sprong (pitch P1: "past niet").

| Wat | Waarde | Gevolg |
|---|---|---|
| Lopen | 2,0 px/tick, direct (geen versnelling of afremming) | 120 px/s |
| Zwaartekracht | 0,25 px/tick², max. valsnelheid 6,0 px/tick | — |
| Sprong | `v.y = −5,0 px/tick`; sprongbuffer 6 ticks, coyote 6 ticks | ± 50 px hoog, 40 ticks in de lucht, ± 80 px ver |
| Bounce (E-07a) | `v.y = −6,0 px/tick` | ± 72 px boven de plank; vanaf een echo op de vloer ± 100 px boven de vloer |
| Dash | DASH-flank: 10 ticks lang `v.x = 4,0 px/tick` in de kijkrichting, `v.y = 0`, geen zwaartekracht; daarna weer lopen | ± 40 px; samen met een sprong ± 120 px ver |
| Dash beschikbaar | 1× per luchtfase; terug bij landen op wereld, licht-geometrie of een schaduwplank (E-07a). Op de grond: herhaaltijd 20 ticks | De springplank is de enige manier om in de lucht een tweede dash te krijgen |

### 2.6 Loslaten (handmatig opnieuw beginnen)

| ID | Regel |
|---|---|
| **E-09** | P1 houdt `ECHO` **30 ticks** aaneengesloten vast: op de 30e tick breekt de echo (zelfde effect als E-08) en `geldig_vanaf = t`. Eén keer per druk: blijft P1 vasthouden, dan gebeurt er niets meer tot de knop is losgelaten. Werkt ook als de echo Leeg is (dan zonder breek-effect). In co-op heeft Loslaten geen zichtbaar effect (er is geen opgenomen echo), maar het zet wel `geldig_vanaf` (relevant bij drop-out, C-05). `ECHO` van P2 doet in het prototype niets. |

Loslaten maakt een echo die ongelukkig loopt (bv. door een gevaar) goedkoop leeg; je nieuwe echo is er D ticks (± 2 s) later.

### 2.7 Solo vs. co-op

> **Wordt herzien in T3b ([#75](https://github.com/cesarvangerwen-glitch/echoborn/issues/75), co-op 7A).** De C-regels hieronder zijn nog die van v0.2 en blijven gelden voor de bestaande code tot T3b gemergd is; lees "600 ticks" en "10 s" als D. Wat T3a al vastlegt en T3b gebruikt: de schaduwplank en bounce van E-07a gelden ook op P2, E-14 laat open wie in co-op merkt en ontsteekt, en de lichtmeter is in co-op één gedeelde meter (LM-01).

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

> **v0.4:** L-01, L-04 en L-05 **vervallen** (pillar 1: geen puzzels op de kritieke route, de echo is op de route nooit een slot). L-07 vervalt als eis door E-04a. Nieuwe L-regels voor sprongketens, merk-arena's en gemaal-wijken komen in T3c; voor de flow-kamer gelden de regels FK-1–FK-6 in §4.4.

| ID | Regel |
|---|---|
| ~~**L-01**~~ | *Vervallen (v0.4).* Was: een echo-kamer op de kritieke route is niet op te lossen met P1 alleen. Nu omgekeerd: elke weg op de kritieke route is ook zonder echo te halen, alleen langzamer (FK-2). |
| **L-02** | Elke plek of elk object dat de schaduw op de kritieke route of voor een verzamelobject moet bereiken, is ook bereikbaar voor de **solo-echo**: via een pad dat P1 kan lopen en dat bij het afspelen door wereld- of schaduwgeometrie gesteund wordt (of door een schaduwlichaam, E-08b). Plekken die alleen een live P2 bereikt, bevatten niets. (Geen co-op-only content, pillar 3.) |
| **L-03** | Poorten gaan open door licht dat de speler terugwon (een gemaal, de waterstand, §2.12), een vaardigheid of een route (pillar 2, v0.4). Geen gekleurde sleutels, geen raadsel, en op de kritieke route nooit alleen door de echo (pillar 1). |
| ~~**L-04**~~ | *Vervallen (v0.4).* Was: een echo-puzzel vraagt hooguit één echo-cyclus voorbereiding per stap. |
| ~~**L-05**~~ | *Vervallen (v0.4).* Was: Wissel-schakelaar alleen als het terugzetten door de echo deel van de puzzel is. E-13 blijft bestaan. |
| **L-06** | Schaduwgeometrie (laag 5) staat niet op normale looppaden van P1, tenzij het breken van de echo daar bedoeld is (uitleg). Anders breekt de echo overal waar P1 door een schaduwmuur liep (E-08a). |
| ~~**L-07**~~ | *Vervallen als eis (v0.4).* De echo volgt je door de deur (E-04a), dus kleine kamers maken hem niet meer Leeg. |

### 2.9 Parameters

| Parameter | Waarde | Testbereik | Wie stelt bij |
|---|---|---|---|
| D, staartlengte (E-02) | **120 ticks (2 s)** | 90 / 120 / 180 (1,5 / 2 / 3 s) | LGD na de flow-test (T17), binnen 90–180; daarbuiten is een `ceo-beslissing` (#51: 8A, kader F4) |
| Recorder-capaciteit (E-02) | 600 frames | — | TD (co-op-finisher, T3b) |
| Merksprong: straal R / duur M (E-02m) | 80 px / 12 ticks (4 heen, 8 terug) | R 48–112; M 8–16 | LGD + Combat Designer |
| Merk: levensduur (E-14b) | D + 30 ticks; aftelling de laatste 60 | D + 15 … D + 60 | Combat Designer |
| Ontploffing: straal E / schade O / ketting K (E-14d) | 32 px / 20 SE / 48 px, +25 % per schakel tot k = 5 | E 24–48; O 15–30; K 32–64 | Combat Designer |
| Treffer P1 / gewone echo-treffer (E-14e) | 10 SE / 5 SE | echo 3–10 | Combat Designer |
| Bounce (E-07a) | −6,0 px/tick; buffer 10, coyote 6 ticks | −5,5 … −7,0; buffer ≥ 10 (pitch P1) | LGD |
| Beweging (§2.5a) | zie §2.5a | — | LGD + Gameplay Programmer |
| G, tolerantie vrij/steun | 3 ticks | 1–6 | LGD |
| Overlap-tolerantie (E-08a) | 2 px | 0–4 | LGD + TD |
| Steuncontrole (E-08b) | 4 px omlaag | 2–8 | LGD + TD |
| Loslaten (E-09) | 30 ticks vasthouden | 15–45 | UX Designer |
| AANVAL-herhaaltijd (E-10) | 20 ticks | 10–30 | Combat Designer |
| Aanvalsvlak (E-10a) | 20 × 16 px, 1 tick actief | — | Combat Designer |
| P2 terugkeer na oplossen (C-06) | 120 ticks | 60–180 | LGD + UX |
| P2 buiten beeld voor oplossen (C-07) | 60 ticks | 30–120 | UX |
| Drop-in plaatsingsstraal (C-03) | 64 px, stappen van 4 px | — | LGD |
| Drop-out: stopknop vasthouden (C-05) | 60 ticks | 30–90 | UX Designer |
| Drop-out: apparaat weg (C-05) | 180 ticks | — | Engine & Platform |
| Lichtmeter en gemaal (§2.12) | zie LM-01–LM-06 | — | LGD (T3c met Systems Designer) |

### 2.10 Playtestvraag van dit systeem

Zie §5: alle vragen van de flow-test gaan over de echo. De kernvraag: *houdt de echo je in beweging (normen 1–3), en bij welke staartlengte?*

### 2.11 Open vragen bij de echo

| # | Vraag | Aan | Tegen |
|---|---|---|---|
| O-1 | Kunnen vijanden de echo als doelwit kiezen (en zo ja, wat gebeurt er bij een treffer)? | Combat Designer | Preproductie |
| O-2 | Hoe zien Leeg, Actief, Breken, de zwevende echo (E-08b), de merksprong en de merk-aftelling eruit (HUD of in de wereld)? Voor de flow-kamer volstaat placeholder (§4.1). | UX Designer, Art Director | T10 / T1 |
| O-3 | Hoe past *Ankeren* binnen C-01 (max. twee lichamen) in co-op? | Systems Designer, LGD | Bij uitwerking vaardigheden |
| O-4 | Moet de echo ook audio afspelen (voetstappen, sprong)? Voorstel: ja, gedempt, als hulp om hem buiten beeld te volgen. | Audio Director | Preproductie |
| ~~O-5~~ | *Gesloten in v0.4:* de echo volgt je door de deur is nu de regel (E-04a). De bouw in de AreaLoader is T5b. | — | — |
| O-6 | UP/DOWN-aanvallen (bits 6 en 7): nodig, en zo ja, hoe herhaalt de echo ze? | Combat Designer | T3c |
| O-7 | Is de lichtmeter ook de meter voor genezen (pitch §11, vraag 7)? De flow-kamer heeft geen genezen (LM-05). | LGD, Systems Designer | T3c |
| O-8 | Leest het schaduwmerk als "net als *Nine Sols*"? Zo ja: terug naar afwijkpunt 2 (§2.13). | LGD, Combat Designer, QA Lead | T17 (vraag 5 in §5) |

### 2.12 Lichtmeter en één gemaal (minimaal, voor de flow-kamer)

**Doel (pillar 2, kernloop "licht oppompen"):** flow vult je lichtmeter, ook wat je echo doet; bij een gemaal pomp je dat licht de stad in, zonder stil te staan. Deze versie is bewust minimaal: één meter, één gemaal, één waterstand met twee standen. Genezen, meer gemalen en waterstanden per wijk zijn T3c.

| ID | Regel |
|---|---|
| **LM-01** | **De meter.** Eén geheel getal `L` van 0 tot **100 LP**; begint op 0 bij de start van de flow-kamer. De meter **lekt niet** en verliest niets bij respawn of breken. Solo is het de meter van P1. In co-op is het één **gedeelde** meter (pitch §3); wat P2 bijdraagt, legt T3b vast. Boven 100 gaat het teveel verloren. |
| **LM-02** | **Vullen, ook via de echo.** Bronnen (elk een event in het meetlog, §4.5): P1-treffer op een vijand of pantser **+2**; gewone echo-treffer op een vijand of pantser **+2**; elke schakel van een merk-ontploffing **+6** (dus ook die de echo ontsteekt); springplank-landing (E-07a) **+3 + 2 × (n − 1)**, met `n` het aantal springplank-landingen sinds P1 voor het laatst wereld of licht-geometrie raakte, max. n = 4 (3, 5, 7, 9); een bounce **+2** extra. Treffers op het pomprad (LM-03) vullen niets. De meter vult dus het snelst in een ketting zonder de grond te raken en met merken die de echo laat knallen (R-V2: de echo moet lonen). |
| **LM-03** | **Het gemaal.** Een `Gemaal`-object met een **pomprad**: een gedeeld object (E-06) met een hurtbox van 32 × 48 px, niet `Merkbaar`. Het gemaal heeft een vulstand `G` van 0 tot **100**. Elke treffer op het pomprad, van **P1 of de echo** (een gewone echo-treffer, E-02m), pompt `min(10, L, 100 − G)` LP van de meter naar het gemaal. `G` gaat nooit omlaag. De echo herhaalt je pompslagen D ticks later, dus hij pompt mee zolang er licht in de meter is. |
| **LM-04** | **Oppompen zonder stilstand.** Er is geen knop om vast te houden en geen animatie die P1 vastzet: een pompslag is een gewone aanval (herhaaltijd 20 ticks). Het pomprad hangt zó dat het lopend en springend te raken is (FK-5). Een volle meter maakt het gemaal in 10 slagen vol, waarvan P1 er 5 kan doen (± 100 ticks) en de echo de andere 5 herhaalt terwijl P1 al verder loopt. Een halve meter pompt half: niets gaat verloren, er is geen grind (pitch §11, vraag 7). |
| **LM-05** | **Geen genezen in de flow-kamer.** Licht wordt in deze versie alleen opgepompt; of dezelfde meter geneest, beslist T3c (O-7). P1 heeft in de flow-kamer wel levenspunten (5; een vijandelijke treffer kost 1; bij 0 respawn op het begin van de kamer, E-04b). |
| **LM-06** | **Gemaal vol: het water zakt.** Op de tick `t_v` waarop `G = 100` wordt: de waterlijn van de kamer zakt lineair van `y_hoog` naar `y_laag` in **180 ticks**, met de `Diepwater`-zone mee; op `t_v + 180` verdwijnt de **sluisdoorgang** (wereldgeometrie, laag 1) en is de route open. De kamer krijgt warm, gewoon licht (beeld), **nooit** een `FelLicht`-zone (pitch P2: verlicht is niet fel). `Diepwater` is een `Area2D` die alleen het middelpunt van P1 controleert: water is geen speellaag (#51: 1A), de echo en P2 negeren het. Komt het middelpunt van P1 in `Diepwater`, dan wordt hij na 30 ticks teruggezet op zijn laatste vloerpositie buiten het water, zonder schade; dat telt als respawn (E-04b). De stand van het gemaal blijft bewaard bij respawn. |

### 2.13 Afwijkpunten van de ideecheck (R-V9)

E-14 en de merksprong nemen de zes afwijkpunten van `docs/business/ideecheck-v0-4.md` §2 over. Er is **geen** afwijking.

| # | Afwijkpunt (ideecheck §2) | Waar het staat | Hoe |
|---|---|---|---|
| 1 | De ontsteker is altijd een tweede lichaam | E-14c, E-02m | Alleen de echo (solo) of P2 (co-op, T3b) laat een merk ontploffen; P1 heeft geen knop en geen "vasthouden om te laden" |
| 2 | Het merk is ruimtelijk, geen opgespaarde balk; de route van de echo is de lont | E-14a, E-14d, E-02m | Max. 1 merk per object, geen teller, geen voorraad schade die wordt omgezet (vaste O). De echo laat alleen merken knallen binnen 80 px van **zijn opgenomen route**; een grotere ontploffing komt uit **ketting en positie** (merken binnen 48 px van elkaar). Dit leest "meer merken = grotere ontploffing" (pitch §3) bewust als ketting, niet als stapel |
| 3 | Merken komen niet uit pareren | E-14f | Pareren geeft nooit een merk; als het komt, iets anders (licht, dash terug) |
| 4 | Merksprong kort, binnen de straal, een schaduw die uitrekt | E-02m | R = 80 px (± 1/8 van de schermbreedte), 4 ticks heen en 8 terug, geen voorwerp. 80 px is nodig om een vijand die na de treffer verder loopt bij D = 180 nog te halen (vijand 0,5 px/tick, §4.3) |
| 5 | Eigen beeld en geluid | E-14i | Lichtvonk als peil- of sluismerk, carillon-aftelling; geen zegel, talisman of taoïstische symboliek |
| 6 | Communicatie | deze tabel; geldt voor elk extern en intern document | "Geïnspireerd door het tempo van *Nine Sols*", nooit "het talisman-systeem met een echo". Eén zin: *je schaduw laat je merken knallen, op de plek waar jij net sloeg.* De springplank (M2) is beweging in vaart en claimen we nooit als nieuw |

De toets of dit werkt, staat in §5 (vraag 5): beschrijven spelers het merk spontaan als "net als *Nine Sols*", dan gaat het terug naar punt 2.

---

## 3. Vaardigheden (schets)

> **v0.4:** deze schets is van v0.2 en wordt in T3c herzien naar beweging en gevecht die de echo versterken (pitch §12). De flow-kamer gebruikt geen vaardigheden.

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

## 4. Flow-kamer-specificatie (mijlpaal 1, F0)

Doel: de echo-regels uit §2 speelbaar maken in één **grijze flow-kamer** (placeholder-art) met drie delen: **sprongketen, merk-arena, één gemaal** (#51: 2A; fasekader F0). Daarin meten we de flownormen van pillar 1 (§4.5), de staartlengte (90 / 120 / 180) en R-V12. De oude testkamers T1–T5 en V1 (puzzelkamers, v0.2) **vervallen** als speelkamer; hun regels die blijven (E-05, E-06, E-10, E-11, E-13) worden alleen nog headless getest in kale testscènes (§4.6). Bouw: Gameplay Programmer (T16a, regels) en World & Level Designer (T16b, kamer), met de LGD als reviewer van de kamer.

### 4.1 Wat de flow-kamer heeft

- P1 met de beweging uit §2.5a en de inputbitset uit §2.5 (AANVAL, INTERACTIE, ECHO, DASH). Meedoen en stoppen via de InputRouter (T5a).
- De echo volgens E-01 t/m E-14 en E-02m; physics-lagen 1–7 uit E-05 met schaduwplank.
- Co-op: P2 volgens de C-regels uit T3b ([#75](https://github.com/cesarvangerwen-glitch/echoborn/issues/75)); de kamer is in beide modi speelbaar zonder aparte versie (pillar 3). Tot T3b gemergd is, bouwt T16a alleen solo.
- Objecten: **basisvijand** (§4.3), **pantserdoel** (E-14g), **gemaal met pomprad, waterlijn, `Diepwater` en sluisdoorgang** (§2.12), eenrichtingsrichels (laag 1, `one_way_collision`), een **trefpop** (een niet-`Merkbaar` doel, alleen voor tests).
- Lichtmeter (LM-01–LM-06).
- **Debugmenu:** D = 90 / 120 / 180; **echo uit** (de echo blijft altijd Leeg; voor FK-2); meetlog aan/uit; herstart van de run.
- **Meetlog** volgens §4.5.
- **Placeholder-HUD:** de lichtmeter als balk, de vulstand `G` op het gemaal zelf, de merk-aftelling als krimpende ring op het merk, Leeg/Actief van de echo (O-2). Eindvorm: UX Designer en UI Artist (T10).
- **Placeholder-art** in de 2D-stijl van de stijltest: grijs voor de wereld, vol voor levend, gerasterd voor de echo; het merk als lichtvonk (E-14i). Na het gemaal krijgt K3 warm licht (LM-06).

### 4.2 Indeling

Drie kamers in één scène, die elkaars **buren** zijn in een **lus**: K1 → K2 → K3 → (na het gemaal) terug naar K1 (FK-3). Maten in px op het 640 × 360-beeld; de World & Level Designer werkt de geometrie uit binnen de bouwstenen (§4.3) en de regels FK-1–FK-6 (§4.4).

| Kamer | Maat | Wat de speler doet | Toetst vooral |
|---|---|---|---|
| **K1 Sprongketen** | ± 1280 × 720 (2 × 2 schermen) | Een route met drie bouwstenen: **B1 keren-opstap**, **B2 zigzag omhoog**, **B3 lus**. Elke bouwsteen heeft een **echolijn** (snel, met springplank en bounce) en een **langzame lijn** (treden, omweg) zonder echo | E-02, E-07a, E-08b, norm (1)–(2), R-V12 |
| **K2 Merk-arena** | 640 × 360 (1 scherm) | Vloer en twee eenrichtingsplatforms op 70 px. **Golf 1:** 3 basisvijanden. **Golf 2:** 3 basisvijanden + 1 pantserdoel. De volgende golf start als de vorige op is; na golf 2 start golf 2 opnieuw elke keer dat P1 de arena binnenkomt, zolang het gemaal niet vol is. De arena sluit niet af: wie wil, loopt door | E-02m, E-14, LM-02, norm (2) |
| **K3 Gemaal** | ± 960 × 360 (1,5 scherm) | Pomprad op de oever, naast de route (FK-5). Rechts een ondergelopen straat met `Diepwater` en aan het eind de sluisdoorgang. Gemaal vol → water zakt (180 ticks) → straat open → doorgang naar K1 | LM-03, LM-04, LM-06, norm (1) bij het oppompen |

**Een run** begint bij de ingang van K1 (`RUN_START`) en eindigt als P1 na `GEMAAL_VOL` via de sluisdoorgang K1 weer binnenkomt (`RUN_EIND`). Doel voor een geoefende run: **≤ 120 s**, waarvan de meter na K1 en één keer K2 (golf 1 + 2) **≥ 100 LP** heeft. De World & Level Designer stemt het aantal springplank-plekken in K1 en vijanden in K2 daarop af; haalt een geoefende run dat niet, dan eerst die aantallen bijstellen, niet de LP-waarden (die zijn van de LGD).

### 4.3 Bouwstenen en maten (voor de World & Level Designer)

De vier situaties waarin de echo vóór of onder je uitkomt (pitch §5): omhoog, keren, vallen, lussen. **Vallen** (vangen) is T3b; de andere drie zitten in K1. Rekenregels met §2.5a (D = 120; bij 90 en 180 schuift alles mee):

- **Keren:** wie `s` ticks van zijn echo wegloopt en dan omkeert, ontmoet hem **D/2 ticks** later (60 ticks bij D = 120), halverwege tussen het keerpunt en de plek waar hij D ticks eerder was. Dat is het kernritme.
- **Hoogte:** een sprong haalt ± 50 px; een **bounce vanaf een echo op de vloer** haalt ± 100 px boven die vloer (lichaam 30 px + bounce 72 px). Een richel op **70–100 px** boven het vlak waar de echo loopt, is dus alleen met de echo in één beweging te halen.
- **Breedte:** sprong + dash haalt ± 120 px; een gat tot 110 px is zonder echo te doen.

| Bouwsteen | Situatie (pitch §5) | Opzet | Echolijn | Langzame lijn |
|---|---|---|---|---|
| **B1 Keren-opstap** | keren | Een gang van ± 320 px die doodloopt tegen een muur; boven de gang over de hele lengte een eenrichtingsgalerij op 90 px | Loop naar de muur, keer om, spring op je echo als je hem tegenkomt, bounce naar de galerij | Drie treden van 45 px bij de muur |
| **B2 Zigzag omhoog** | omhoog (via keren) | Een schacht van ± 200 px breed en 360 px hoog met vier lange richels (± 160 px) om en om tegen de linker- en rechterwand, telkens 90 px hoger | Op elke richel naar het eind, omkeren, op je echo, bounce naar de volgende richel | Per richel een tussentrede van 45 px aan het eind (twee sprongen per verdieping) |
| **B3 Lus** | lussen | Een ondergang en daarboven, ± 100 px hoger, een bovengang met een gat; de route loopt eerst door de ondergang en via een trap terug over de bovengang. Na de bovengang een muur van 90 px | Val door het gat op je echo die door de ondergang loopt, bounce over de muur en dash verder (ketting zonder grond: LM-02) | Neem de trap naar boven langs de muur |

**Basisvijand** (werkaanname LGD, startwaarden voor de Combat Designer): `Merkbaar`, 30 SE, loopt op de vloer 0,5 px/tick naar P1 (springt niet, verlaat K2 niet), staat na een treffer 20 ticks stil, valt aan als P1 binnen 16 px is: 30 ticks zichtbare aanloop, dan 6 ticks een aanvalsvlak van 20 × 16 px op laag 2 (kost P1 1 levenspunt). Zo blijft een gemerkte vijand bij elke D binnen R van de plek waar je hem sloeg. **Pantserdoel:** `Merkbaar`, staat stil, valt niet aan, pantser volgens E-14g, daarna 30 SE.

### 4.4 Levelregels voor de flow-kamer

| ID | Regel | Hoe getoetst |
|---|---|---|
| **FK-1** | **Geen puzzel.** Nergens op de route hoeft de speler stil te staan om een volgorde of timing te bedenken (puzzeldefinitie, pitch §4). Elke bouwsteen scoort "ja" op de toetsvraag van pillar 1. | Checklist World & Level Designer, review LGD |
| **FK-2** | **Nooit een slot.** Elke echolijn heeft een langzame lijn zonder echo, die met de beweging uit §2.5a te halen is en hooguit **2×** zo lang duurt. Het gemaal is ook zonder echo vol te krijgen (alleen P1-treffers). | Headless: een solo-`ScriptedInput` met **echo uit** haalt `RUN_EIND` |
| **FK-3** | **Open doorgangen.** K1–K2, K2–K3 en K3–K1 zijn buren (E-04a), zonder deur die achter P1 dichtvalt. De doorgang K3–K1 is de sluisdoorgang (LM-06). | Headless: rechte doorloop K1 → K2 → K3 zonder reset (E-04a-test) |
| **FK-4** | **De echo breekt hier niet.** Geen schaduwgeometrie op looppaden (L-06), geen `FelLicht` en geen `Schaduwgevaar` in de flow-kamer. | Headless: de scripted runs laten de echo nooit breken |
| **FK-5** | **Pomprad in de route.** Het middelpunt van het pomprad hangt 15–40 px boven de vloer, raakbaar lopend en vanuit een sprong. Geen vijand komt binnen 80 px (R, E-02m), anders kiest de echo een merksprong in plaats van een pompslag. | Checklist + LM-04-test |
| **FK-6** | **Maten.** Echolijnen gebruiken richels op 70–100 px boven het vlak van de echo; treden van de langzame lijn zijn ≤ 45 px; gaten zijn ≤ 110 px. | Checklist World & Level Designer |

### 4.5 Flownormen: waarden en meetpunten

Waarden voor de normen van pillar 1 (pitch §4). T16b logt, T17 rekent en rapporteert, **solo en co-op apart**, per D. Een **geoefende speler** is een speler vanaf zijn derde run, of een scripted run.

| # | Wat | Definitie | Waarde (gehaald als) |
|---|---|---|---|
| **MP-1** | Norm (1): stilstand | Een tick is **stil** als P1 `op_vloer` is, `abs(v.x) < 0,5 px/tick`, en er in de laatste 30 ticks geen JUMP-, DASH-, AANVAL- of INTERACTIE-flank was. Een **stilstand** is een reeks aaneengesloten stille ticks. Telt niet mee: pauzemenu en de eerste 60 ticks na een respawn | Langste stilstand per run **≤ 300 ticks** (5 s), ook bij het gemaal. 301–360 ticks: grensgeval, de LGD bekijkt de opname. > 360: niet gehaald |
| **MP-2** | Norm (2): echo als springplank of merk-afmaker | Een **echo-actie** is een springplank-landing (met of zonder bounce: één contact = één actie) of een merksprong met ontploffing (een ketting telt als één actie) | **≥ 3,0 echo-acties per minuut** speeltijd over de run, én in K1 en K2 elk apart; geen venster van 40 s zonder echo-actie |
| **MP-3** | R-V12: springplank vóór je | Springplank-landingen per minuut (alleen rapporteren) en het aandeel landingen zonder stille tick in de 120 ticks ervoor | Aandeel zonder stilstand **≥ 75 %** |
| **MP-4** | R12: echo Leeg | Aandeel van de speeltijd dat de echo Leeg of Buiten is | **≤ 40 %** |
| **MP-5** | Norm (3): vloeiend | Na elke run, per kamer: *"Voelde het vloeiend/satisfying?"* (1–5) | Gemiddelde **≥ 4,0** per modus; geen kamer gemiddeld < 3,0 |
| **MP-6** | Lichtmeter: de echo telt mee | Aandeel van de gevulde LP uit bronnen met de echo (echo-treffer, ontploffing, springplank, bounce); aantal pompslagen van de echo | **≥ 40 %** van de LP in een geoefende run; **≥ 1** pompslag van de echo per run |

**Staartlengte kiezen.** Per D (90 / 120 / 180) gelden MP-1 t/m MP-6. Gekozen wordt de D die MP-1, MP-2, MP-4 en MP-6 haalt met de hoogste MP-5; bij gelijkspel 120. Haalt geen enkele D de normen: herontwerp door de LGD en een tweede flow-test (F0); haalt die MP-2 niet, dan een `ceo-beslissing` (R-V12). Een D buiten 90–180 is een `ceo-beslissing` (F4).

**Meetlog** (T16b). Eén CSV per run, `meetlog_<datum>_<solo|coop>_D<D>_<speler>.csv`, met de kolommen `tick, kamer, event, waarde, bron, x, y`. Events:

| Event | `waarde` / `bron` |
|---|---|
| `RUN_START`, `RUN_EIND`, `KAMER` | — / nieuwe kamer |
| `STIL_START`, `STIL_EIND` | lengte in ticks bij `STIL_EIND` |
| `ECHO_LEEG_START`, `ECHO_LEEG_EIND` | reden (`reset`, `buiten`) |
| `SPRINGPLANK`, `BOUNCE` | `n` uit LM-02 / `echo` of `p2` |
| `MERK_GEZET`, `MERKSPRONG`, `ONTPLOFFING` | schakel `k` / merk-id |
| `LP` | `+n` / bron uit LM-02 |
| `POMP`, `GEMAAL_VOL` | gepompte LP / `p1` of `echo` |
| `RESPAWN`, `BREEK`, `LOSLATEN` | oorzaak |

Het log is deterministisch: twee runs met dezelfde `ScriptedInput` en dezelfde D geven hetzelfde log. Voor elke D is er minstens één **scripted geoefende run** (World & Level Designer met Gameplay Programmer) die MP-1, MP-2, MP-4 en MP-6 haalt; die bewijst dat de kamer de normen kán halen voordat mensen hem spelen.

### 4.6 Acceptatiecriteria (tests per regel)

Automatisch te testen, headless zoals de spike (`game/tests/`), tenzij er "checklist" staat. **"(alle D)"** betekent: de test draait voor D = 90, 120 en 180. "Reset op `t0`" betekent: `geldig_vanaf = t0`. Waar een test een vijand nodig heeft die niet mag merken, gebruikt hij de trefpop.

**Opname en reset**

| Regel | Test |
|---|---|
| E-01 | P1 loopt over vloer, lichtbrug en de echo. Het opgenomen frame heeft steunsoort `wereld`, `licht` en `schaduwlichaam` op de juiste ticks, plus positie, snelheid, kijkrichting, `op_vloer`, animatietoestand en events. Na 900 ticks zijn er 600 aaneengesloten frames (geen gaten). |
| E-02 | (alle D) Na D ticks staat de echo op de positie van P1 op tick `t − D` (0 px verschil), met dezelfde kijkrichting. D wordt op `t0` in het debugmenu gewisseld van 120 naar 180: de echo is Leeg tot `t0 + 180` en staat dan op de positie van P1 op `t0`. Bij D = 120 houdt de recorder 600 frames. |
| E-02m | (alle D) (1) P1 slaat een stilstaande vijand op `x`; op `x + D + 3` staat de echo op het merk (0 px), de vijand krijgt 20 SE op die tick en niet eerder; op `x + D + 11` staat de echo weer op zijn opname (0 px). (2) Merk op 79 px van de opgenomen positie: merksprong; op 81 px: geen merksprong. (3) Twee merken op 40 en 60 px: doel is het merk op 40 px; twee merken op gelijke afstand: het oudste. (4) Tussen echo en merk staat een muur op laag 1: geen merksprong; op laag 5: geen merksprong; op laag 4 (licht-geometrie): wel. (5) P1 valt op `x + D + 1` van boven op de echo: P1 valt erdoor (plank uit). (6) Het merk ligt in een `FelLicht`-zone: de echo breekt op de tick waarop zijn middelpunt de zone in komt, geen ontploffing, `geldig_vanaf` = die tick. (7) De doelvijand sterft op `x + D + 1`: geen ontploffing, de echo staat op `x + D + 9` weer op zijn opname. (8) AANVAL zonder merk binnen R met de trefpop in het aanvalsvlak: gewone echo-treffer, de echo verlaat zijn opname niet. (9) Het opgenomen pad loopt tijdens de merksprong 3 ticks door een schaduwmuur: de echo breekt niet tijdens de merksprong; loopt het pad na de merksprong nog 3 ticks door de muur, dan breekt hij op de 3e. |
| E-03 | (alle D) Reset op `t0`; P1 deed op `t0 − 5` INTERACTIE bij een schaduwhendel en stond op `t0 − 10` boven een gat. Op `t0 + D − 5`: de hendel staat nog in zijn beginstand, de echo is onzichtbaar en een P1 die op de echo-plek valt, valt erdoor. |
| E-04a–d | (alle D) Voor elke oorzaak apart (kamerwissel naar een kamer die geen buur is, respawn, Loslaten, wissel van D, breken) op `t0`: echo Leeg op `t0 + D − 1`, Actief op `t0 + D`, op de positie van P1 op `t0`. |
| E-04a | (alle D) Kamers A en B zijn buren, C is geen buur van B. (1) P1 loopt op `t0` van A naar B: geen reset; op `t0 + D` gaat de echo door dezelfde doorgang (0 px van het opgenomen pad); de Leeg-teller telt 0 ticks. (2) P1 loopt van B terug naar A: geen reset. (3) P1 wordt van B naar C gezet (debug-teleport): reset op die tick. (4) A wordt op `t1` als niet geladen gemarkeerd terwijl frame `p` in A ligt: de echo is Buiten (onzichtbaar, P1 valt door de plek van de plank, een INTERACTIE-event in A wordt niet uitgevoerd), `geldig_vanaf` blijft gelijk; zodra frame `p` in B ligt, is de echo Actief op zijn opname. (5) Validatie bij het laden: is A buur van B maar B niet van A, dan een foutmelding. |
| E-04e | P1-middelpunt gaat over de grens naar kamer B: kamerwissel op die tick. P1 springt terug naar A: opnieuw kamerwissel. P2 gaat in co-op naar kamer B terwijl P1 in A blijft: geen kamerwissel. |

**Lagen en platform**

| Regel | Test |
|---|---|
| E-05 | Lagen en maskers van P1, P2, echo en schaduwplank zijn exact zoals in de tabel. P1 loopt tegen een lichtmuur en door een schaduwmuur; P2 loopt tegen een schaduwmuur en door een lichtmuur. |
| E-06 | Echo op een lichtplaat: plaat blijft uit. Echo op een schaduwplaat: plaat gaat aan. P1 op een schaduwplaat: plaat blijft uit. P1 en echo elk op een gedeelde plaat: beide gaan aan. |
| E-07 | P1 die van boven op de echo landt, blijft staan. P1 die van opzij komt, loopt erdoor. P1 die van onder springt, gaat erdoor. Echo die omhoog door P1 beweegt: P1-positie verandert die tick niet door de echo. Echo loopt het opgenomen pad tegen een gedeeld duwblok: het blok blijft op zijn plek. Echo Leeg terwijl P1 erop staat: P1 valt in dezelfde tick. |
| E-07a | **(1) Meebewegen:** echo beweegt 3 px/tick naar rechts, P1 staat erop zonder input: P1-x stijgt elke tick met 3 px, in dezelfde tick als de echo. Met een muur rechts: P1 stopt tegen de muur, de echo gaat door en P1 valt als de plank onder hem weg is. **(2) Landen:** P1 valt met `v.x = 2,0` op de echo: op de landingstick is `v.x = 2,0` en `v.y = 0`. P1 heeft zijn dash in de lucht gebruikt en landt op de echo: `dash_klaar = true`, en na het verlaten van de plank kan hij in de lucht opnieuw dashen. P1 landt in tick 4 van een dash: de dash loopt tot tick 10, daarna `dash_klaar = true`. P1 staat 60 ticks op de echo: één `SPRINGPLANK`-event. **(3) Bounce:** JUMP op de plank: `v.y = −6,0`, de top ligt 70–74 px boven de plank, `v.x` ongewijzigd, `BOUNCE`-event. JUMP 10 ticks vóór het landen: bounce op de landingstick; 11 ticks vóór: geen bounce en geen sprong. JUMP 6 ticks na het verlaten van de plank: bounce; 7 ticks na: geen sprong. Bounce vanaf een echo op de vloer: P1-onderkant komt ≥ 98 px boven de vloer. **(4) Geen plank-snelheid:** P1 springt zonder input van een echo die 3 px/tick naar rechts beweegt: na de sprong `v.x = 0`. |
| E-07b | Een logtest per tick bevestigt de volgorde: schaduw → P1 → opname → events P1 → events schaduw → objecten. |
| E-11 | De lamp is in beeld aan maar de `FelLicht`-zone staat uit: de echo loopt erdoor. Zone aan, lamp in beeld uit: de echo breekt. |
| E-12 | Echo en P2 lopen door een item-pickup en een vaardigheid-pickup: beide blijven liggen. P1 loopt erdoor: opgepakt. |
| §2.5a | Sprong vanaf de vloer: top 49–51 px, 40 ± 1 ticks in de lucht. Dash: 40 px in 10 ticks, `v.y = 0`. Tweede dash in de lucht zonder plank: gebeurt niet. Dash op de grond: 20 ticks herhaaltijd. |

**Breken**

| Regel | Test |
|---|---|
| E-08a | Een schaduwmuur op het pad na opname: echo breekt op de 3e tick van overlap; `geldig_vanaf` = die tick. Overlap van 2 ticks (muur die daarna weg is): echo breekt niet. Overlap van 2 px: breekt niet; 3 px: breekt. |
| E-08b | Lichtbrug weg en geen schaduwbrug: echo breekt aan de rand. Wel een schaduwbrug: echo loopt door. (alle D) P1 staat 60 ticks op de echo en springt eraf: D ticks later **zweeft** de echo die 60 ticks op de opgenomen posities, breekt niet, `geldig_vanaf` blijft gelijk, en een P1 die van boven op de zwevende echo valt, landt erop. Er staat op die plek een schaduwmuur: de echo breekt wel (E-08a geldt nog). |
| E-08c | Echo die een `FelLicht`-zone binnengaat, breekt op de tick waarop zijn middelpunt erin komt. |
| E-08d | Echo die een `Schaduwgevaar`-zone raakt, breekt op de eerste tick van overlap. P1 in dezelfde zone: er gebeurt niets met P1. |
| E-08 (events) | Het opgenomen frame van de breektick bevat een INTERACTIE bij een schaduwhendel: de hendel gaat niet om. |

**Input, events en Loslaten**

| Regel | Test |
|---|---|
| E-09 | 30 ticks ECHO ingedrukt: echo breekt op de 30e tick; 29 ticks: niet. 90 ticks vasthouden: één keer Loslaten. Bij een Lege echo: `geldig_vanaf` wordt toch gezet. |
| E-10 | (alle D) INTERACTIE bij een schaduwhendel op tick `x`: de hendel gaat om op tick `x + D`. AANVAL 60 ticks vastgehouden: één event. Twee AANVAL-flanken 10 ticks na elkaar: één event; 20 ticks na elkaar: twee. |
| E-10a | P1 kijkt links en slaat op `x`, met een trefpop links en een rechts: op `x + D` raakt de echo alleen de linker. Het aanvalsvlak is op `x + D + 1` niet meer actief. |
| E-10b | Twee hendels overlappen de echo bij een INTERACTIE: alleen de dichtstbijzijnde gaat om. |
| E-13 | Wissel-hendel door P1 op `x`: op `x + D` zet de echo hem terug. Eenmalige hendel: blijft om. Echo staat 30 ticks op een drukplaat: plaat precies die 30 ticks aan. |

**Schaduwmerk (E-14)**

| Deel | Test |
|---|---|
| a | P1 raakt een vijand op `x`: één merk, 10 SE. P1 raakt hem opnieuw op `x + 20`: nog steeds één merk, en met **echo uit** dooft het op `x + D + 30`, niet later. De echo raakt een vijand zonder merk: er komt geen merk. |
| b | (alle D) Reset op `x + 1` (Loslaten), zodat de echo de treffer niet herhaalt: het merk dooft op `x + D + 30` zonder schade; de aftelling start op `x + D − 30`. |
| c | P1 slaat een gemerkte vijand: geen ontploffing, 10 SE, het merk blijft. Alle inputbits apart 60 ticks vasthouden bij een gemerkte vijand: geen ontploffing. |
| d | Merk op V1, V2 op 30 px zonder merk: één ontploffing, V1 en V2 elk 20 SE. Merken op V1, V2 (40 px van V1) en V3 (40 px van V2, 80 px van V1): V1 op `t_o` (20 SE), V2 op `t_o + 1` (25), V3 op `t_o + 2` (30). Merk op 49 px van het ontploffende merk: geen ketting. Ketting van 6: de 6e schakel doet 40 SE. P1 en de echo binnen 32 px: geen schade. |
| e | Echo-AANVAL zonder merk binnen R, vijand in het aanvalsvlak: 5 SE. |
| f | Checklist (LGD, Combat Designer): geen code- of designpad zet een merk behalve E-14a; pareren bestaat niet in de flow-kamer. |
| g | P1 raakt het pantserdoel 3 keer: pantser 0 SE schade, één merk. De echo laat het merk ontploffen: pantser weg. Daarna doet een P1-treffer 10 SE. |
| h | Een vijandelijke aanval raakt de positie van de echo: de echo gaat door en breekt niet. |
| i | Checklist (LGD op code, art en audio): "talisman" en "seal" komen niet voor als naam van het merk; het merk heeft geen zegel- of taoïstische symboliek. |

**Lichtmeter en gemaal**

| Regel | Test |
|---|---|
| LM-01 | `L` begint op 0. Opgeteld 110 LP: `L = 100`. Respawn, breken en Loslaten: `L` gelijk. 3000 ticks stilstaan: `L` gelijk. |
| LM-02 | P1-treffer +2; gewone echo-treffer +2; ketting van 3 schakels +18; 4 springplank-landingen zonder grond 3 + 5 + 7 + 9 = 24, de 5e +9; na grond weer +3; bounce +2 extra; pompslag +0. |
| LM-03 | (alle D) `L = 100`, `G = 0`: P1 pompt 5 slagen op `x … x + 80` → `G = 50`, `L = 50`; de echo herhaalt ze op `x + D … x + D + 80` → `G = 100`, `L = 0`. `L = 30`: na 5 P1-slagen `G = 30`, de slagen 4 en 5 pompen 0; de echo pompt 0. `G = 95`, `L = 50`: een slag pompt 5. Respawn: `G` gelijk. |
| LM-04 | AANVAL 60 ticks vasthouden bij het pomprad: één slag. P1 slaat het pomprad vanuit een sprong (op de top): de slag pompt. De scripted geoefende run met een volle meter heeft bij het gemaal geen stilstand > 300 ticks (MP-1). |
| LM-05 | Een vijandelijke treffer kost P1 1 levenspunt; bij 0: respawn op het begin van de kamer, `L` en `G` gelijk. |
| LM-06 | `G = 100` op `t_v`: de waterlijn is op `t_v + 90` halverwege (± 1 px) en op `t_v + 180` op `y_laag`; de sluisdoorgang is er nog op `t_v + 179` en weg op `t_v + 180`. Na `t_v` is er in K3 geen `FelLicht`-zone. P1-middelpunt in `Diepwater` op `t`: op `t + 30` staat P1 op zijn laatste vloerpositie buiten het water, levenspunten gelijk, reset op `t + 30`. De echo loopt door `Diepwater`: breekt niet. Respawn na `t_v`: water blijft laag. |

**Flow-kamer en meetlog**

| Regel | Test |
|---|---|
| FK-2 | Headless: solo-`ScriptedInput` met echo uit haalt `RUN_EIND`. |
| FK-3, FK-4 | Headless: de scripted geoefende run per D heeft 0 `BREEK`-events en geen `ECHO_LEEG_START` door een kamerwissel. |
| FK-1, FK-5, FK-6 | Checklist World & Level Designer, review LGD. |
| Meetlog (§4.5) | Dezelfde `ScriptedInput` twee keer met dezelfde D: identieke logs. Het log bevat elk eventtype uit de tabel minstens één keer in de scripted geoefende run. Uit het log berekend haalt die run, per D, MP-1, MP-2, MP-4 en MP-6. |

**Co-op:** de tests voor C-01–C-08 blijven staan zoals in v0.2 tot T3b ze herschrijft ([#75](https://github.com/cesarvangerwen-glitch/echoborn/issues/75)); waar ze 600 ticks noemen, rekent de test met D. Ze staan hieronder ongewijzigd.

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

**Levelregels** (geen automatische test, behalve waar het staat)

| Regel | Hoe getoetst |
|---|---|
| L-02 | Headless: K1–K3 hebben een solo-`ScriptedInput` die `RUN_EIND` haalt (de scripted geoefende run). Checklist per kamer: elke schaduwplek op de route ligt op zo'n pad. |
| L-03 | Checklist per poort: wat hem opent (licht/gemaal, vaardigheid, route) staat in de kamerdocumentatie; geen sleutelobject, geen raadsel. |
| L-06 | Zie FK-4. |

---

## 5. Playtestvragen voor de flow-test (T17)

Spelers volgens het fasekader (T17): scripted runs en de CEO (± 20 min). Solo en co-op apart; co-op volgens T3b. Elke speler speelt alle drie de waarden van D, in wisselende volgorde.

| # | Vraag | Hoe we het meten | Wanneer het goed is |
|---|---|---|---|
| 1 | **Welke staartlengte: 1,5, 2 of 3 s?** (R9, R-V1) | MP-1 t/m MP-6 per D (§4.5); na elke D: *"Wist je waar je echo zou zijn?"* (1–5) | Er is een D die de normen haalt (keuzeregel §4.5); voorspelbaarheid gemiddeld ≥ 4 |
| 2 | **Houdt de echo je in beweging?** Normen (1)–(3) van pillar 1 | MP-1, MP-2, MP-5 | Alle drie gehaald, solo én co-op |
| 3 | **Is de echo niet te vaak Leeg?** (R12, R-V3) | MP-4; Leeg-redenen uit het log | ≤ 40 % |
| 4 | **Ligt de springplank niet steeds achter je?** (R-V12) | MP-3, en waar de landingen gebeuren (B1, B2, B3, K2) | ≥ 75 % zonder stilstand; elke bouwsteen levert landingen op |
| 5 | **Leest het merk als *Nine Sols*?** (R-V9, ideecheck §2) | Na de run, **vóór** we iets over het merk zeggen: *"Waar deed het merk je aan denken?"* (open vraag). Telt: spontaan "*Nine Sols*", "talisman" of dezelfde lading-en-ontploffing | Niemand noemt het spontaan; anders terug naar afwijkpunt 2 (§2.13) |
| 6 | **Is de merksprong leesbaar?** | Na een ontploffing of een gemiste ontploffing: *"Waarom knalde dat merk (niet)?"* Juiste uitleg (de echo kwam langs / het merk was te ver of gedoofd) telt als begrepen | ≥ 80 % juist |
| 7 | **Wacht in co-op iemand, of gaat het te snel?** (R10, R-V5) | Tijd per run co-op vs. solo; uitwerking in T3b | Co-op ≤ 2× zo snel als solo, niemand wacht |

---

## 6. Antwoorden op de vragen uit #6 en `ontwerp.md` §11

*Historisch (v0.2).* In v0.4 wijzigen: vraag 1 (staart van D ≈ 2 s, E-02; één afwijking, de merksprong, E-02m), vraag 2 (op je echo staan breekt hem niet meer, E-08b) en vraag 4 (co-op, T3b).

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
| 0.3 | Echo-regels v0.4 en flow-kamer (T3a, [#67](https://github.com/cesarvangerwen-glitch/echoborn/issues/67)), volgens pitch v0.4 en besluit #51 (1A, 8A). Nieuw of herzien: E-02 (staart D = 120 ticks, testwaarden 90 / 120 / 180, recorder 600 frames), **E-02m merksprong**, E-04 en **E-04a** (de echo volgt je door de deur, toestand Buiten; O-5 gesloten), **E-07a springplank** (vaart houden, dash terug, bounce), **E-08b** (steun op een schaduwlichaam breekt de echo niet), **E-14 schaduwmerk** met de afwijkpunten 1–6 van de ideecheck (§2.13), DASH-bit en minimale beweging (§2.5a), **lichtmeter met één gemaal** (§2.12, LM-01–LM-06). Testkamers T1–T5 en V1 → **flow-kamer** (§4: sprongketen, merk-arena, gemaal; bouwstenen, FK-regels, waarden voor de flownormen MP-1–MP-6, meetlog) met tests per regel (§4.6). Vervallen: tweeslagschild, lampbrug, L-01, L-04, L-05, L-07; L-03 herzien. Playtestvragen → flow-test (§5). C-regels ongewijzigd tot T3b (#75). |
| 0.2 | Lead-review EP (PR #16): physics-lagen 1–7 met schaduwplank (E-05, E-07, E-07a, E-07b); volledige inputbitset, aanvalsrichting, meedoen/stoppen via InputRouter (§2.5, E-09, E-10a, E-10b); test voor elke E- en C-regel, L-regels als checklist/playtest gemarkeerd, venster tweeslagschild 15 ticks (§2.9, §4.3); kamer gedefinieerd (E-04e), L-06 en L-07, verkenningsgang V1 en Leeg-meting in playtestvraag 1; Dragen als uitzondering op E-06 en Wisselen → Terugstappen (§3); O-5, O-6. Stijlbesluit 2D verwerkt (px, beeldtaal vol/hol). |
