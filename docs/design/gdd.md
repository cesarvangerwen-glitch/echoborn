# Game Design Document *Polderlight*

Versie 0.4 (echo-regels v0.4, co-op 7A) · Eigenaar: Lead Game Designer (met Combat Designer voor E-14, E-02m en C-12) · Issues [#67](https://github.com/cesarvangerwen-glitch/echoborn/issues/67) (T3a) en [#75](https://github.com/cesarvangerwen-glitch/echoborn/issues/75) (T3b), `docs/productie/fase-2-kader.md` §2 · vorige versie: #6
Werktitel *Polderlight* (besluit #96); repo en mappen heten nog "echoborn", de mechaniek heet "echo".
Bronnen: `docs/concept/pitch.md` **v0.4** (pillars P1–P3, §4 flownormen, §12 delta), `docs/beslissingen.md` (o.a. **#51 deel 2**: 1A, 7A, 8A; stijl 2D #18), `docs/business/ideecheck-v0-4.md` §2 (afwijkpunten 1–6), `docs/tech/ontwerp.md` (echo-spike).
Kernloop, diagrammen en pillartoets: `docs/design/kernloop.md` (wordt herzien in T3c).

Deze versie zet de echo om naar pitch v0.4: een **korte staart van ± 2 s** (E-02), de **merksprong** (E-02m), de **echo volgt je door de deur** (E-04a), de **springplank** met bounce (E-07a), **op je echo staan breekt hem niet** (E-08b), het **schaduwmerk** (E-14), een **minimale lichtmeter met één gemaal** (§2.12) en de **flow-kamer** als eerste mijlpaal (§4). Sinds v0.4 staat ook **co-op 7A** erin (T3b, [#75](https://github.com/cesarvangerwen-glitch/echoborn/issues/75)): één rol voor het tweede lichaam, in co-op de partner en solo de echo, met vier samenwerkingsacties in beide vormen (bounce, lancering, merk-combo, vangen) en de gedeelde echo als finisher (§2.7, C-01–C-16). Wat níét in deze versie zit, met de taak die het oppakt: vaardigheden, L-regels voor de slice, genezen met de lichtmeter, waterstand voor meer wijken en `kernloop.md` (T3c).

**Afspraken.**
- Elke regel heeft een ID: E- (echo), C- (co-op), L- (levelontwerp). **Elke E- en C-regel heeft een automatische test in §4.6.** L-regels toetsen we met een reviewchecklist of playtest; dat staat er ook in §4.6 bij.
- Tijden staan in **ticks van 60 Hz** (de vaste simulatietick, `ontwerp.md` §2). "Nu" is tick `t`.
- **px = wereldpixel**: één pixel van het 640×360-beeld (stijlbesluit 2D, #18). Een figuur is ±30 px hoog (stijltest: ±60 px op 1280×720). Afstanden worden opnieuw bekeken als de Art Director de figuurgrootte vastlegt.
- **Schade-eenheden (SE)** en **lichtpunten (LP)** zijn abstracte gehele getallen (§2.5a, E-14, §2.12).
- Elke regel heeft een **D** waar v0.2 "600 ticks" of "10 s" schreef: D is de staartlengte uit E-02. Alleen de finisher (C-14) en de recorder (E-02, C-04) rekenen nog met 600 ticks (10 s, besluit #51: 8A).
- **Werkaannames van deze versie** (kader §5): CEO-besluiten #2 (5–7 uur, PEGI 12), #18 (2D) en #51 deel 2 (1A, 7A, 8A; uitgewerkt in pitch v0.4) en fasekader fase 2 v0.2. Daarnaast **werkaanname LGD**: alle getallen in §2.5a (beweging), E-02m, E-14, §2.12, de bouwstenen en de basisvijand (§4.3) en de stilstandmaat (MP-1, §4.5) zijn **startwaarden voor de flow-kamer**. Ze zijn gekozen om de flownormen te kunnen halen en worden na de flow-test (T17) bijgesteld; de schadewaarden stelt de Combat Designer bij. **Werkaanname LGD voor co-op (T3b):** alle getallen in C-09–C-14 en MP-7 (lanceerhouding, lancering, vangzone, finisher, LP voor lancering en vangen, P2-treffer 10 SE) en de maten van bouwsteen B4 zijn startwaarden voor de flow-kamer, op dezelfde manier bij te stellen na T17; de finisherdrempel en de schaal van bosses in co-op stelt de Combat Designer vast in T8b. Geen andere aannames.

---

## 1. Basis: twee lichamen, twee lagen

- **Het lichtpersonage (P1)** leeft in de lichtlaag. Het is de speler, heeft levenspunten, verzamelt items en vaardigheden.
- **De schaduw** leeft in de schaduwlaag. Solo is de schaduw de **echo**: een opname van P1 van D ticks (± 2 s) geleden. In co-op is de schaduw **speler 2 (P2)**, live bestuurd: de partner ís de echo (pitch P3, #51: 7A).
- Er zijn nooit meer dan **twee lichamen** tegelijk. De gedeelde echo van de finisher is geen lichaam en bestaat alleen tijdens de finisher van een boss (C-01, C-14).
- In beeld (stijltest 2D): **levend = vol, echo = hol**. P1 vol amber, P2 vol donker met cyaan contour, de echo gerasterd met de contour van P1. Uitwerking: Art Director.

Basisbeweging (lopen, springen, dash) voor de flow-kamer staat in §2.5a; aanval en interactie in §2.5. De echte uitwerking komt van de Combat Designer en Gameplay Programmer (T3c).

---

## 2. Systeem: de echo

### 2.1 Doel

De echo houdt je in beweging (pillar 1): hij is je **springplank** waar jij net was en hij laat je **merken knallen** waar jij net sloeg. Hij leeft in de schaduw (pillar 2) en is solo dezelfde rol die P2 in co-op live speelt (pillar 3). Toetsvraag bij elke regel hieronder: *maakt de echo deze actie vloeiender of krachtiger, zonder dat de speler ervoor moet stilstaan?*

### 2.2 Opnamemodel

**Besluit LGD: de echo loopt altijd D ticks (± 2 s) achter je aan, en speelt de opgenomen *toestand* af.** Er is geen knop om op te nemen of af te spelen; de echo is er gewoon, net als je schaduw. De korte staart volgt besluit #51 (8A: ± 2 s, bereik 1,5–3 s); de 10 s blijven in het verhaal, het einde en de finisher bij bosses (C-14). Toestandsopname volgt de aanbeveling van de Technical Director (`ontwerp.md` §4).

Waarom geen vastgezette clip op een knop: dan wordt de echo een gereedschap dat je soms pakt, in plaats van een lichaam dat altijd meedoet. Waarom ± 2 s: met een korte staart komt de echo binnen een tel of twee vóór of onder je uit bij keren, klimmen en lussen (pitch §5), zonder te wachten (norm 1). De enige afwijking van het opgenomen pad is de merksprong (E-02m).

| ID | Regel |
|---|---|
| **E-01** | P1 wordt elke tick opgenomen, na zijn stap: positie, snelheid, kijkrichting (E-10a), `op_vloer`, **steunsoort** (`wereld` / `licht` = licht-geometrie / `schaduwlichaam` = echo of P2, zie E-07), animatietoestand, de events van die tick (E-10) en of `AANVAL` ingedrukt is (`aanval_vast`, voor de lanceerhouding, C-11). De opname loopt altijd, ook in co-op (C-04). |
| **E-02** | **Korte staart.** De echo toont op tick `t` de opgenomen toestand van frame `p = t − D`. **D = 120 ticks (2 s)**; testwaarden **90 / 120 / 180** (1,5 / 2 / 3 s, bereik besluit #51: 8A). D is een parameter die per sessie vastligt (debugmenu, §4.1); een wissel van D tijdens het spel telt als reset (E-04c). De echo wordt niet gesimuleerd: hij staat waar P1 op tick `p` stond, met de opgenomen kijkrichting en animatietoestand. **Enige uitzondering:** de merksprong (E-02m). De recorder bewaart minstens 600 frames, ook al gebruikt de echo er maar D: de finisher speelt de laatste 10 s af (8A, C-14). |
| **E-02m** | **Merksprong.** Bevat frame `p` een AANVAL-event (E-10), dan zoekt het spel op tick `t` het **doelmerk**: het schaduwmerk (E-14) waarvan het middelpunt het dichtst bij het middelpunt van de echo op frame `p` ligt, binnen **straal R = 80 px**, met een vrije zichtlijn (een raycast tussen beide middelpunten raakt laag 1 en 5 niet). Bij gelijke afstand wint het oudste merk. **Geen doelmerk:** een gewone echo-treffer op de opgenomen positie (E-10a, E-14e). **Wel een doelmerk:** de echo doet een merksprong van **M = 12 ticks** in plaats van de gewone treffer. *Heen* (k = 0…3, tick `t + k`): positie = `lerp(opname(t + k), merk(t + k), (k + 1) / 4)`. Op tick `t + 3` staat de echo op het merk en laat het ontploffen (E-14d). *Terug* (j = 1…8, tick `t + 3 + j`): positie = `lerp(merk(t + 3), opname(t + 3 + j), j / 8)`. Daarna staat hij weer op zijn opname (E-02). Tijdens de merksprong: de schaduwplank staat **uit** (P1 kan er niet op landen); de controles E-08a en E-08b worden **niet** gedaan (ze gaan over het opgenomen pad), E-08c en E-08d **wel**, op de werkelijke positie (breekt de echo, dan is er geen ontploffing als het vóór tick `t + 3` gebeurt). Verdwijnt het doelmerk tijdens *heen* (vijand dood, merk gedoofd), dan begint *terug* meteen vanaf de huidige positie, zonder ontploffing. INTERACTIE-events in frames tijdens de merksprong werken op de opgenomen positie (E-10b). Een tweede AANVAL-event valt nooit in een merksprong (herhaaltijd 20 ticks > M). In beeld: **een schaduw die uitrekt** naar het merk en terugveert, geen dash met een voorwerp (ideecheck punt 4). |
| **E-03** | Er is één waarde `geldig_vanaf`. De echo is **Actief** als `p ≥ geldig_vanaf`, anders **Leeg**: onzichtbaar, geen botsingen (ook geen schaduwplatform, E-07), geen events, geen controles (E-08). Frames van vóór `geldig_vanaf` worden nooit afgespeeld. |
| **E-04** | `geldig_vanaf = t` wordt gezet bij: (a) een **kamerwissel van P1 naar een kamer die geen buur is** van de vorige kamer (E-04a, E-04e), (b) respawn van P1 (ook terugzetten uit diep water, LM-06), (c) *Loslaten* (E-09) of een wissel van D (E-02), (d) breken van de echo (E-08). Dit is het enige reset-mechanisme. Gevolg: na elke reset is de echo precies D ticks Leeg en verschijnt hij daarna op de plek waar P1 op het reset-moment stond. |
| **E-04a** | **De echo volgt je door de deur** (was O-5; pitch §12, R12/R-V3). Elke `Kamer` heeft een lijst `buren`: de kamers waarmee hij een doorgang deelt (gezet door de level designer, altijd wederzijds). Een kamerwissel naar een buur zet **geen** reset: de echo speelt door, ook als frame `p` nog in de vorige kamer ligt, en loopt een tel later dezelfde doorgang door. Ligt het middelpunt van frame `p` in een kamer die op tick `t` **niet geladen** is, dan is de echo die tick **Buiten**: hetzelfde als Leeg (onzichtbaar, geen botsing, geen plank, geen events, geen controles), maar **zonder** reset; zodra frame `p` weer in een geladen kamer ligt, is hij weer Actief. Events van Buiten-frames worden niet uitgevoerd. Geladen zijn minstens de kamer van P1 en al zijn buren (AreaLoader, T5b); tot T5b is de hele flow-kamer één geladen scène, dus komt Buiten daar niet voor. Voor de meting (MP-4) telt Buiten als Leeg. |
| **E-04e** | **Wat een kamer is.** Een kamer is een `Kamer`-node in de gebiedsscène: een rechthoekige `Area2D` die tegelijk de **camerazone** en de **streameenheid** van de AreaLoader is (`ontwerp.md` §3). Kamers overlappen niet. De kamer van P1 is de kamer waarvan de rechthoek het middelpunt van P1 bevat. Verandert die waarde, dan is dat een kamerwissel. P2 en de echo veroorzaken nooit een kamerwissel. Een kamer mag meerdere schermen groot zijn. Of een kamerwissel een reset is, bepaalt E-04a (buur of niet). |

### 2.3 Lagen en physics

**Regel in één zin: de echo bestaat alleen in de schaduw; hij wordt gedragen en geblokkeerd door wereld- en schaduwgeometrie, en hij kan alleen *gedeelde* objecten en *schaduw*objecten bedienen. De lichtlaag raakt hij nooit direct; hij beïnvloedt het licht alleen via gedeelde objecten** (bv. een gedeelde hendel die een lamp verzet). **P1 kan wel op de schaduw staan, via een aparte eenrichtingscollider.**

| ID | Regel |
|---|---|
| **E-05** | **Physics-lagen.** Uitbreiding van `ontwerp.md` §8 met laag 6, 7 en 8 (de Gameplay Programmer zet ze in `layers.gd` en `project.godot`). Tabel hieronder. Het lichaam van de schaduw (laag 3) is voor P1 onzichtbaar; P1 botst alleen met de **schaduwplank** op laag 6. Omgekeerd botst P2 alleen met de **lichtplank** van P1 op laag 8 (co-op, C-09). |

| Laag | Naam | Wat erop staat | Wie maskeert deze laag |
|---|---|---|---|
| 1 | wereld | Geometrie die in beide werelden bestaat | P1, P2, controles van de echo (E-08) |
| 2 | licht | Lichaam van P1; aanval- en interactievlak van P1 | Objecten die P1 mogen voelen (E-06), aanvallen van vijanden (E-14) |
| 3 | schaduw | Lichaam van echo/P2; aanval- en interactievlak van echo/P2 | Objecten die de schaduw mogen voelen (E-06) |
| 4 | licht-geometrie | Muren/platforms die alleen in licht bestaan | P1 |
| 5 | schaduw-geometrie | Muren/platforms die alleen in schaduw bestaan | P2, controles van de echo (E-08) |
| 6 | schaduwplank | De eenrichtingscollider op echo en P2 (E-07) | **Alleen P1** |
| 7 | zones | `FelLicht`- en `Schaduwgevaar`-zones (E-08c/d, E-11) | Controles van de echo, P2 |
| 8 | lichtplank | De eenrichtingscollider op P1, alleen aan in co-op (C-09) | **Alleen P2** |

| Lichaam | `collision_layer` | `collision_mask` |
|---|---|---|
| P1 (`CharacterBody2D`) | 2 | 1 + 4 + 6 |
| P2 (`CharacterBody2D`) | 3 | 1 + 5 + 8 (niet 2: P2 staat alleen op P1 via de lichtplank, C-09) |
| Echo (`CharacterBody2D`, wordt gezet, niet bewogen) | 3 | geen; de controles van E-08 zijn aparte queries op 1 + 5 en 7 |
| Schaduwplank (`AnimatableBody2D`, kind van echo en van P2) | 6 | geen |
| Lichtplank (`AnimatableBody2D`, kind van P1; alleen aan zolang P2 meedoet) | 8 | geen |

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
| **E-07a** | **Springplank** (pitch §12; ideecheck M2: beweging in vaart, geen stilstand). Vijf delen: **(1) Meebewegen.** Stond P1 aan het eind van tick `t − 1` op een schaduwplank (`op_vloer` en de vloer is laag 6), dan krijgt P1 aan het begin van zijn stap op tick `t` de verplaatsing van de plank: `Δ = plankpositie(t) − plankpositie(t − 1)`, horizontaal én verticaal. Die verplaatsing gaat met `move_and_collide` tegen laag 1 + 4: botst P1, dan schuift hij niet verder dan de muur en blijft de plank onder hem doorgaan. Daarna volgt de gewone beweging (§2.5a) met de input van P1. **(2) Landen = vaart houden + dash terug.** Op de tick waarop P1 van boven op een schaduwplank landt: `v.y = 0`, `v.x` blijft wat hij was (geen afremming), een lopende dash loopt door tot zijn 10 ticks om zijn, en P1 krijgt zijn dash terug (`dash_klaar = true`; geldt ook voor een luchtsprong als die ooit komt). Dit is een **springplank-landing** (event `SPRINGPLANK` voor lichtmeter en meting). Een nieuwe springplank-landing telt pas als P1 de plank minstens 1 tick verlaten heeft. **(3) Afzetten = bounce.** Een sprong vanaf een schaduwplank is een **bounce**: `v.y = −6,0 px/tick` in plaats van −5,0 (± 72 px in plaats van ± 50 px hoog), `v.x` blijft, dash terug. Een JUMP-flank telt als bounce als P1 op de plank staat, als hij ≤ **10 ticks vóór** het landen viel (buffer: de bounce gaat dan af op de landingstick), of ≤ **6 ticks na** het verlaten van de plank (coyote). Event `BOUNCE`. **(4) Geen plank-snelheid.** Na het verlaten krijgt P1 **geen** snelheid van de plank mee: alleen zijn eigen vaart telt. Ingebouwde platformsnelheid van Godot staat uit (`platform_on_leave = DO_NOTHING`, `platform_floor_layers` zonder laag 6), zodat er maar één regel is. **(5) Wie.** Dit geldt voor elke schaduwplank (echo en P2) en in co-op ook voor de lichtplank van P1, met P2 als springer (C-09, C-10). Lancering en vangen in beide vormen: C-11 en C-13. |
| **E-07b** | **Volgorde per tick** (vult `ontwerp.md` §2.2 aan; de TD bevestigt): (1) de schaduw: de echo zet frame `p` en doet zijn controles (E-08), óf P2 stapt; (2) P1 stapt, inclusief E-07a; (3) P1 wordt opgenomen (E-01); (4) events uitvoeren, eerst van P1, dan van de schaduw (E-10); (5) objecten (drukplaten, schakelaars, zones, schild) werken hun stand bij. Daardoor beweegt P1 in dezelfde tick mee, zonder een tick achter te lopen. In co-op stapt P1 eerst als P2 aan het eind van `t − 1` op de lichtplank van P1 stond (C-09); dan zijn (1) en (2) omgewisseld. |
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
| **E-14** | **Schaduwmerk** (pitch §12; startwaarden LGD, de Combat Designer stelt de schade bij). Neemt de afwijkpunten 1–5 van de ideecheck over (§2.13). **(a) Merk zetten.** Een treffer van **P1** (zijn aanvalsvlak, E-10a, overlapt op de event-tick de hurtbox van een `Merkbaar` object: een vijand of een pantser) op een object **zonder** merk zet één merk. **Max. 1 merk per object**: een treffer op een object dat al een merk heeft, zet niets bij en verlengt niets (geen stapel, geen teller per vijand). Het merk hangt aan het object en beweegt mee. Solo zet alleen P1 merken; in co-op zetten P1 en P2 allebei merken, met deze regel (C-12). Elk merk onthoudt zijn **zetter**. **(b) Levensduur.** Een merk leeft **D + 30 ticks** (de echo komt dus altijd op tijd langs, ook bij D = 180). De laatste 60 ticks telt het af in beeld en geluid (carillon, R-V1). Daarna dooft het zonder effect. **(c) De ontsteker is altijd het andere lichaam.** Solo laat alleen de echo (via E-02m) een merk ontploffen; in co-op laat een treffer van het lichaam dat het merk níét zette het ontploffen (C-12). Niemand heeft een ontsteekknop of "vasthouden om te laden"; een treffer van de zetter op zijn eigen merk doet gewoon 10 SE en laat het merk staan. **(d) Ontploffing.** Op tick `t_o`: elk vijand- of pantserobject binnen **E = 32 px** van het merkmiddelpunt (ook de drager) krijgt **O = 20 SE** (een intact pantser: zie g), en het merk is weg. **Ketting:** elk ander merk met zijn middelpunt binnen **K = 48 px** van een ontploffend merk ontploft op tick `t_o + 1`, enzovoort (één schakel per tick; volgorde binnen een tick op merk-id). Schakel `k` (de eerste is k = 1) doet `O × (1 + 0,25 × (min(k, 5) − 1))`, afgerond naar beneden: 20, 25, 30, 35, 40 SE. Meer merken betekent dus een grotere ontploffing **door ketting en positie**, niet door stapelen op één vijand. Ontploffingen doen P1, P2 en de echo niets. **(e) Treffer zonder merk.** P1-treffer: **10 SE**. Gewone echo-treffer (geen doelmerk, E-02m): **5 SE**. **(f) Pareren geeft nooit een merk.** Pareren zit niet in de flow-kamer; komt het (T3c, Combat Designer), dan geeft het iets anders, bv. licht (§2.12) of de dash terug. **(g) Pantser.** Een `Pantserdoel` met een **intact** pantser krijgt van treffers van P1 of de echo 0 SE en geeft er **0 LP** voor (LM-02); een merk zetten kan wel. De eerste ontploffing die het raakt (elke schakel telt), **breekt het pantser en doet verder niets**: de schade van die schakel gaat op aan het pantser, de 30 SE erachter blijven heel. Een schakel op een latere tick raakt het al als gewone vijand. Daarna is het een gewone vijand (P1-treffer 10 SE en +2 LP). Waarom geen doorslag: na de knal blijft er iets af te maken voor P1, en de regel blijft per schakel één zin. Dit is de bouwsteen voor "een pantser breekt alleen door een merk-ontploffing" bij bosses (pitch P1). **(h) De echo is onkwetsbaar.** Hij heeft geen levenspunten en kan niet sterven. Vijandelijke aanvallen maskeren alleen laag 2 en hebben geen effect op de echo (of P2); alleen E-08 laat de echo breken. **(i) Naam en beeld.** In code en tekst heet het `Schaduwmerk` of "merk", nooit "talisman" of "seal". Beeld: een lichtvonk in de vorm van een **peil- of sluismerk**, met een carillon-aftelling; geen zegel, talisman of taoïstische symboliek (Art Director T1, Audio Director T2). |

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

### 2.7 Solo vs. co-op: één rol, twee vormen (co-op 7A)

**Besluit #51 (7A, 8A), uitgewerkt door de LGD (T3b, [#75](https://github.com/cesarvangerwen-glitch/echoborn/issues/75)).** Er is **één rol: het tweede lichaam**. Solo speelt de **echo** die rol, in co-op de **partner (P2)**, live (pitch P3, §5). In co-op is er **geen opgenomen echo**, niet van P1 en niet van P2: de partner ís de echo. P2 is de sluiswachter die weer uit zichzelf beweegt. Hij houdt de lagen en de kwetsbaarheden van de schaduw (alleen schaduw, lost op in licht, moet in beeld blijven, C-06 en C-07), maar hij is geen kopie van de echo meer: hij slaat, merkt en draagt live, en P1 is ook voor hem een plank. Samenwerken is **optioneel op de route** (C-15) en **verplicht bij bosses** (C-16). De 10 s komen alleen terug in de **gedeelde echo als finisher** (C-14, 8A).

**Termen.** Een **lichaam** is P1, de echo of P2: een `CharacterBody2D` op laag 2 of 3. Het **tweede lichaam** is de echo (solo) of P2 (co-op). Bij elke samenwerkingsactie is één lichaam de **drager** (waarop of waarmee de ander beweegt) en het andere de **springer**. Een **samenwerkingsactie** is een springplank-landing (met of zonder bounce), een lancering, een vang of een merk-combo (een ontploffing die het andere lichaam dan de zetter laat gebeuren; een ketting telt als één actie).

**De vier acties in beide vormen** (pitch P3):

| Actie | Co-op (partner) | Solo (echo) | Regel |
|---|---|---|---|
| **Bounce** | Spring op de ander: P1 op P2 of P2 op P1. Hoge sprong + dash terug | Spring op je echo (P1 op de echo) | C-10, E-07a |
| **Lancering** | De drager houdt na een slag AANVAL vast (houding); de springer die op hem staat, wordt weggeslingerd | Hield je AANVAL vast, dan staat je echo D ticks later in houding: spring op hem en je wordt weggeslingerd | C-11 |
| **Merk-combo** | De een zet het merk, de ander laat het knallen met een gewone treffer | Je echo laat je merk knallen met de merksprong | C-12, E-14, E-02m |
| **Vangen** | Val snel op of vlak naast de ander: hij vangt je en zwiept je omhoog | Val snel op of vlak naast je echo, op je plek van D ticks geleden: hij vangt je | C-13 |

| ID | Regel |
|---|---|
| **C-01** | **Max. twee lichamen.** Solo: P1 + echo. Co-op: P1 + P2. Zolang P2 meedoet, bestaat de echo niet: hij wordt niet afgespeeld, is nergens zichtbaar, heeft geen plank, voert geen events uit en doet geen controles (E-08). Ook in de 120 ticks dat P2 opgelost is (C-06) is er geen echo. De **gedeelde echo** van de finisher (C-14) is **geen lichaam**: geen collision-laag, geen masker, geen plank, geen events behalve zijn finisherslagen; hij bestaat alleen tijdens een finisher. Er zijn dus nooit meer dan twee lichamen en nooit meer dan drie figuren in beeld. |
| **C-02** | **P2, de sluiswachter.** P2 is een speler met de lagen uit E-05 (laag 3, masker 1 + 5 + 8), een eigen schaduwplank (E-07), dezelfde beweging (§2.5a), dezelfde inputbits (§2.5) en hetzelfde aanvalsvlak (E-10a) als P1. P2 bedient gedeelde en schaduwobjecten en raakt gedeelde vijanden (E-06). Een **P2-treffer** doet **10 SE** (als een P1-treffer), zet een merk (C-12) en is op het pomprad een pompslag (LM-03). P2 kan **niet**: lichtobjecten bedienen of lichtwezens raken, iets verzamelen (E-12), iets duwen, door schaduwgeometrie (laag 5): hij botst ertegen in plaats van te breken. P2 heeft geen levenspunten; vijandelijke aanvallen hebben op hem geen effect (E-14h). P2 doet **geen merksprong** (die is er voor de echo, die niet kan richten). P2 veroorzaakt geen kamerwissel (E-04e). `ECHO` van P2 doet niets. P2 lost alleen op volgens C-06. |
| **C-03** | **Drop-in.** Een vrij apparaat drukt op "meedoen". Is de echo **Actief**: P2 neemt op die tick de positie, snelheid en kijkrichting van de echo over (de sluiswachter wordt wakker), het afspelen stopt, geen pauze en geen kamer-reset. Was de echo in een merksprong, dan staat P2 op de huidige positie en stopt de merksprong zonder ontploffing. Stond P1 op de plank van de echo, dan staat hij nu op die van P2 en valt hij niet. Is de echo **Leeg of Buiten**: P2 verschijnt op de positie van P1 (in de schaduw). **Plaatsingsregel:** is die plek in laag 1 of 5 bezet, dan op de dichtstbijzijnde vrije plek binnen 64 px (zoeken in stappen van 4 px), anders op de laatste vloerpositie van P1. Bij de drop-in gaat de lichtplank van P1 aan (C-09). Merken die er al zijn, houden hun zetter (P1). |
| **C-04** | **Opname in co-op.** De opname van P1 loopt in co-op gewoon door (E-01), zonder gaten. E-04 blijft gelden: een kamerwissel naar een kamer die geen buur is, respawn, Loslaten en een wissel van D zetten `geldig_vanaf` (van belang bij een latere drop-out, C-05); breken (E-04d) komt in co-op niet voor. Daarnaast houdt het spel voor de finisher (C-14) per lichaam een **finisherlog** bij: de ticks van de laatste 600 ticks waarop dat lichaam een AANVAL-event **uitvoerde** (P1; de echo alleen als hij Actief was; P2). P2 wordt verder niet opgenomen: hij wordt nooit afgespeeld. |
| **C-05** | **Drop-out.** P2 houdt "stoppen" 60 ticks vast, of het apparaat van P2 is 180 ticks ontkoppeld. P2 lost op (breek-effect), de lichtplank van P1 gaat uit en de echo van P1 neemt op dezelfde tick over volgens E-02/E-03: is `t − D ≥ geldig_vanaf`, dan staat de echo op frame `p` (waar P1 D ticks geleden was); anders is hij Leeg tot dat wel zo is, hooguit D ticks. Er wordt niets gesimuleerd of verzonnen om het gat te vullen. Stond P1 op de plank van P2, dan valt hij (E-07). Merken die P2 zette, blijven staan tot hun levensduur om is (E-14b); de echo kan ze laten knallen (C-12). De regels van P2 in het finisherlog blijven staan tot ze ouder zijn dan 600 ticks. |
| **C-06** | **P2 lost op** bij fel licht (middelpunt in `FelLicht`), een `Schaduwgevaar`, uit de kamer vallen (middelpunt onder de onderrand van de kamer), of de leiband (C-07). P2 verschijnt 120 ticks later opnieuw naast P1 volgens de plaatsingsregel van C-03. Geen checkpoint-reset; P1 merkt alleen dat de schaduw even weg is. (Antwoord op pitch-vraag 3: de schaduwspeler faalt vergevingsgezind.) |
| **C-07** | **Leiband.** De gedeelde camera houdt beide spelers in beeld tot zijn maximale zoom. Staat het middelpunt van P2 **60 ticks aaneengesloten** buiten dat beeld, dan geldt C-06 (op de 60e tick). P1 bepaalt waar de camera heen gaat; P1 wordt nooit verplaatst of afgeremd door de camera. Waarden van de camera: UX Designer en Technical Director. |
| **C-08** | Sterft P1 in co-op, dan respawnen beiden op het checkpoint; P2 verschijnt naast P1 volgens de plaatsingsregel van C-03. E-04b zet `geldig_vanaf` (van belang bij een latere drop-out). |
| **C-09** | **Drager, springer en plank.** Solo is de drager altijd de echo en de springer altijd P1: de echo speelt alleen af en springt nooit op P1. In co-op werkt het in **beide richtingen**: P1 springt op de **schaduwplank** van P2 (laag 6, E-07) en P2 op de **lichtplank** van P1 (laag 8): een `AnimatableBody2D` met dezelfde vorm en regels als de schaduwplank (E-07), die alleen bestaat zolang P2 meedoet. **Volgorde per tick** (vult E-07b aan): stond P2 aan het eind van `t − 1` op de lichtplank van P1, dan stapt P1 eerst en daarna P2; anders eerst P2. Ze kunnen niet allebei op elkaar staan. Een plank **draagt alleen** (botst, geeft landing, bounce, lancering en vang) als zijn drager **geldig** is: de echo is Actief en niet in een merksprong (E-02m); P2 doet mee en is niet opgelost. **Geen ladder (co-op):** een plank draagt bovendien alleen als zijn drager sinds zijn laatste **grondcontact** (staan op laag 1, 4 of 5, dus niet op een plank) zelf niet op een plank stond of gevangen werd. Zo kunnen P1 en P2 niet om en om op elkaar blijven klimmen. Voor de solo-echo blijft E-08b gelden (de echo-toren is open vraag O-10). |
| **C-10** | **Bounce.** E-07a (1)–(4) geldt voor elke springer op de plank van een geldige drager, met dezelfde waarden: meebewegen, landen met vaart en dash terug (`SPRINGPLANK`), bounce `v.y = −6,0 px/tick` met buffer 10 en coyote 6 ticks (`BOUNCE`), geen plank-snelheid. De teller `n` van LM-02 hoort bij de springer. Solo: P1 op de echo (ongewijzigd). Co-op: P1 op P2 en P2 op P1. |
| **C-11** | **Lancering.** **(a) Houding.** Een drager is in **lanceerhouding** op elke tick waarop `AANVAL` sinds zijn laatste AANVAL-event aaneengesloten ingedrukt is en dat event minstens **12 ticks** geleden was, tot hij `AANVAL` loslaat. De echo is in houding als frame `p` dat was (opgenomen `aanval_vast`, E-01). In houding loopt, springt en dasht de drager gewoon; de houding doet geen schade, zet geen merk en laat niets ontploffen (afwijkpunt 1, §2.13). **(b) Lanceren.** Staat de springer aan het eind van zijn stap op tick `t` op de plank van een geldige drager in houding (ook op de landingstick), dan wordt hij gelanceerd. Vanaf `t + 1` is hij **30 ticks in lanceerstaat**: `v.x = 4,0 × r`, met `r` de kijkrichting van de drager op tick `t` (LEFT en RIGHT veranderen `v.x` niet; de kijkrichting van de springer wordt `r`); op `t + 1` is `v.y = −7,5`, daarna gewone zwaartekracht (§2.5a). De springer krijgt zijn dash terug. Event `LANCERING`, bron = de drager. **Voorrang** op dezelfde tick: vang (C-13) > lancering > bounce (E-07a). Valt de springer snel (`v.y ≥ 4,0`), dan is het een vang; anders gaat een lancering vóór een bounce. **(c) Einde.** De lanceerstaat stopt na 30 ticks, bij een landing, als de springer tegen een muur botst (`v.x = 0`) of bij een DASH (de dash neemt het over). Daarna gewone beweging. **(d)** De houding van de drager eindigt op de lanceertick: voor een nieuwe lancering moet hij opnieuw slaan. **(e) Echo.** Staat P1 op de plank van de echo op de tick van een AANVAL-event van de echo, dan doet de echo een **gewone echo-treffer** en geen merksprong (de plank blijft aan). Tijdens een merksprong is de plank uit, dus geen lancering. **Gevolg** (afstanden van afzet tot dezelfde hoogte): de lancering haalt ± 115 px hoog en **± 180 px op plankhoogte** (± 61 ticks in de lucht), met de dash erbij ± 220 px. Ter vergelijking: een bounce + dash haalt **± 136 px op plankhoogte** (48 ticks × 2,0 + 40), een sprong + dash **± 120 px van vloer tot vloer**. |
| **C-12** | **Merk-combo.** **(a) Zetten.** Solo zet alleen P1 merken (E-14a; de echo nooit). In co-op zetten P1 en P2 merken met dezelfde regel (E-14a): een treffer op een `Merkbaar` object zonder merk zet één merk, max. 1 merk per object, wie het ook zette. **(b) De ontsteker is altijd het andere lichaam.** Solo: de echo, via de merksprong (E-02m), op elk merk. Co-op: een treffer van het lichaam dat het merk **níét** zette, op het gemerkte object, laat het merk op die tick ontploffen (E-14d), **in plaats van** zijn gewone 10 SE. Een treffer van de zetter op zijn eigen merk doet 10 SE en laat het merk staan (E-14c). Na een drop-out laat de echo ook de merken van P2 knallen. **(c)** Schade, ketting en pantser volgens E-14d en E-14g, wie de andere merken in de ketting ook zette. **(d)** Elke schakel geeft **+6 LP** in de gedeelde meter (LM-02). **(e)** Een merk leeft ook in co-op **D + 30 ticks** (E-14b; D blijft de sessieparameter). |
| **C-13** | **Vangen.** Een **vang** gebeurt op de tick waarop alle vier gelden: (1) de springer valt met `v.y ≥ 4,0 px/tick` (na ± 32 px vallen) en is niet in lanceerstaat; (2) zijn onderkant gaat in deze tick van boven door de hoogte van de bovenkant van een geldige drager (C-09); (3) zijn middelpunt ligt horizontaal binnen **24 px** van het middelpunt van de drager (een **vangvlak** van 48 px breed, ruimer dan de plank van 16 px); (4) hij werd in deze luchtfase nog niet gevangen (een luchtfase eindigt bij grondcontact, C-09, niet op een plank). **Effect** op die tick: de onderkant van de springer staat op de bovenkant van de drager (x blijft), `v.y = −6,0` (de **zwiep**, zonder JUMP), `v.x` blijft, dash terug, **12 ticks onkwetsbaar** voor vijandelijke aanvallen, event `VANGEN`, bron = de drager. Een vang telt voor `n` (LM-02) en voor de ladderregel (C-09) als springplank-landing, niet als bounce; JUMP op de vangtick doet niets extra. Bij snel vallen is het altijd een vang, ook als de drager in houding is. Solo vangt de echo je waar je D ticks eerder was (schachten, keren, over je eigen spoor); in co-op vangt de drager je door onder je te gaan staan. |
| **C-14** | **Gedeelde echo: de finisher** (8A). **(a) Alleen bij een boss** (`Boss`, T8b). Een boss heeft een **finisherdrempel** (startwaarde 20 % van zijn SE; de Combat Designer zet hem per boss). Zakt de boss op of onder de drempel, dan is hij **Wankel**: hij valt niet meer aan, treffers en ontploffingen doen hem 0 SE, en hij blijft Wankel tot de finisher start (geen tijdslimiet). **(b) Start.** De eerste merk-ontploffing (C-12; elke schakel telt) die een Wankele boss raakt, start de finisher op die tick `t_f`. **(c) Wat hij afspeelt.** De gedeelde echo verschijnt bij de boss en speelt **jullie laatste 600 ticks (10 s)** af, versneld ×5, in **120 ticks**: elk AANVAL-event uit het finisherlog (C-04) van P1 en van het tweede lichaam (solo de echo, co-op P2) op tick `t_f − 600 + i` (`i` = 0…599) wordt op finishertick `⌊i / 5⌋` een **finisherslag** op de boss: **+1 LP** in de meter, beeld en geluid (Art Director, Audio Director). Alleen events vanaf `BOSS_START` tellen. **(d) Einde.** Op `t_f + 120` is de boss verslagen (`BOSS_VERSLAGEN`), hoeveel slagen er ook waren: de finisher mislukt nooit. **(e) Tijdens de finisher** vallen vijanden niet aan, worden er geen merken gezet, en blijven P1 en het tweede lichaam bestuurbaar (de echo speelt door). **(f) Solo en co-op** hebben dezelfde regel: solo zijn "jullie" jij en je echo (pillar 3: geen co-op-actie zonder solo-vorm). **Bedoeld:** solo telt een slag van P1 twee keer mee, één keer van P1 en één keer als de Actieve echo hem herhaalt, net zoals co-op twee lichamen telt; zo krijgt solo even veel finisherslagen als co-op bij hetzelfde tempo. Meten in T17 en T11 (aantal slagen solo tegenover co-op). De gedeelde echo is het gemaal dat herinnert, een schim van machinist en sluiswachter samen, half licht en half schaduw (pitch §5); beeld: Art Director. |
| **C-15** | **Optioneel op de route.** (a) Elke plek op de kritieke route en elk verzamelobject is te bereiken **zonder** samenwerkingsactie: solo met de echo uit, en in co-op als P2 alleen meeloopt. Dat duurt hooguit 2× zo lang (FK-2). (b) Samenwerken levert op de route alleen tempo, hoogte en licht op (sneller, hoger, sterker), **nooit** een slot, sleutel of content (L-02, L-03). (c) Plekken die alleen met twee live spelers te halen zijn, bevatten niets (L-02). (d) Geen kamer heeft een solo- en een co-op-versie. |
| **C-16** | **Verplicht bij bosses.** (a) Een boss is alleen te verslaan met de finisher (C-14), en die start alleen met een merk-combo: samenwerken is bij elke boss verplicht, solo met de echo en in co-op met de partner. (b) Elke boss heeft daarnaast minstens één ander verplicht moment met een samenwerkingsactie, bv. een pantser dat alleen een merk-ontploffing breekt (E-14g); welke actie, kiest de Combat Designer (T8b). (c) Elk verplicht moment is solo én co-op te doen in dezelfde arena, zonder aparte versie, met vensters van ≥ 10 ticks (pitch P1); de scripted geoefende run haalt MP-1 (≤ 300 ticks stilstand) in beide modi. (d) Een boss is `Merkbaar`; waar het merk op een grote boss hangt, legt de Combat Designer vast, zo dat de merksprong (R = 80 px) het haalt. (e) Geen boss-mechaniek vraagt twee live spelers. Valt P2 in co-op uit, dan neemt de echo het over (C-05). |

**Waarom zo.**
- **Twee richtingen in co-op.** Pitch P3 zegt "spring op de ander", en de minder ervaren speler moet ook zelf hoog komen, niet alleen plank zijn. Solo kan dat niet (de echo speelt af), maar daar is geen tweede speler die iets mist. De ladderregel (C-09) houdt het eerlijk.
- **Lancering met houding, niet met timing.** "De een houdt een aanval vast" (pitch P3) geeft een venster zo lang als je wilt (≥ 10 ticks): vergevingsgezind voor de drager. De houding laadt niets op en doet geen schade, zodat het merk het enige is dat ontploft en de ontsteker het andere lichaam blijft (ideecheck punt 1). Solo zet je de houding vooruit klaar: je echo staat er D ticks later in.
- **Vangen zonder knop.** De springer valt, de drager staat eronder: de minder ervaren speler vangt door te bewegen, niet door een extra knop op het goede moment. De ondergrens van 4,0 px/tick houdt de gewone landingen van B1 en B2 (± 3,2 px/tick) buiten de vang; wie in B3 van het blok springt in plaats van stapt, krijgt een vang, en die zwiept even hoog als een bounce. Eén vang per luchtfase voorkomt jongleren voor onkwetsbaarheid.
- **P2 slaat als P1, maar wordt niet geraakt.** Live meedoen vraagt een eigen slag (merken, pompen); de echo is ook onkwetsbaar, dus de rol blijft gelijk. Of co-op daardoor te makkelijk wordt (R10), meet MP-7.
- **De finisher mislukt nooit.** Het grote moment hoort bij het einde (8A), niet bij een tweede kans om te falen. Wat telt, is hoeveel jullie in die 10 s samen deden: dat zie je en dat geeft licht.

**Waarom co-op hiermee niet triviaal wordt** (R10, R-V5): P2 houdt de beperkingen van de schaduw (alleen schaduw, geen lichtobjecten, lost op in licht, moet in beeld blijven). Samenwerken levert op de route alleen tempo op, nooit een plek (C-15), en bij bosses is het verplicht in beide vormen (C-16). Of co-op niet meer dan 2× zo snel gaat en of niemand wacht, meet MP-7 vanaf de flow-kamer.

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
| Recorder (E-02) en finisherlog (C-04) | 600 frames (P1); finisherlog 600 ticks per lichaam | — | TD |
| Merksprong: straal R / duur M (E-02m) | 80 px / 12 ticks (4 heen, 8 terug) | R 48–112; M 8–16 | LGD + Combat Designer |
| Basisvijand: snelheid / stil na treffer (§4.3) | 0,25 px/tick / 30 ticks | voorwaarde `36 + v × (D_max − 27) ≤ R`; bij R = 80 en D_max = 180 is v ≤ 0,28 px/tick | Combat Designer (sneller: eerst O-9) |
| Stilstand (MP-1) | binnen 24 px in 30 ticks | 16–32 px; 20–45 ticks | LGD |
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
| P2-treffer (C-02) | 10 SE, +2 LP | 5–10 SE | Combat Designer |
| Lanceerhouding (C-11a) | na 12 ticks AANVAL vasthouden, zolang vastgehouden | 10–20 ticks | LGD + UX |
| Lancering (C-11b) | `v.x = 4,0 × r` 30 ticks, `v.y = −7,5`; +4 LP | v.x 3,5–5,0; v.y −6,5 … −8,5; 20–40 ticks | LGD |
| Vang (C-13) | `v.y ≥ 4,0` vallen; vangvlak 48 px; zwiep −6,0; 12 ticks onkwetsbaar; +3 LP | drempel 3,5–5,0; vangvlak 32–64 px; zwiep −6,0 … −7,0 | LGD |
| Finisher (C-14) | drempel 20 % van de boss-SE; 600 ticks ×5 = 120 ticks; +1 LP per finisherslag | drempel 10–30 %; 90–180 ticks | Combat Designer (drempel), LGD |
| Boss-SE in co-op | ×1,0 (geen schaal) | 1,0–1,5 | Combat Designer (T8b, na MP-7) |
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
| O-9 | Wordt R groter dan 80 px (bv. voor een snellere basisvijand, §4.3), dan toetsen we afwijkpunt 4 (merksprong kort, §2.13) opnieuw in §5 vraag 6. | LGD, Combat Designer | Bij elke wijziging van R |
| O-10 | **Echo-toren:** omdat P1 op een zwevende echo kan landen (E-08b), kan hij misschien eindeloos stijgen door op zijn echo te blijven bouncen (bij D = 90 elke ± 45 ticks, telkens ± 15 px hoger). Bestaat dat in de flow-kamer, en is het een gewenste vaardigheid of een lek? | LGD, Gameplay Programmer | T16a (meld het), regel in T3c |
| O-11 | **Solo vangen bij afgronden.** De echo vangt je alleen waar je D ticks eerder was (C-13). Bij een gemiste sprong over een afgrond ben je dan meestal al gevallen. Heeft solo vangen een bouwsteen nodig (schacht, terugval over je eigen spoor), en vangt de echo genoeg om de moeite te zijn? | LGD, World & Level Designer | T3c (L-regels), meten in T17 (MP-7, §5 vraag 8) |
| O-12 | **Leest de lanceerhouding als "opladen"?** De houding laadt niets op (C-11a), maar vasthouden kan lijken op het opladen uit *Nine Sols* (ideecheck punt 1). | LGD, Combat Designer, QA Lead | T17 (§5 vraag 5) |
| O-13 | **Maakt een onkwetsbare P2 co-op te makkelijk?** P2 wordt niet geraakt (C-02), net als de echo. Haalt co-op MP-7 niet, dan eerst de boss-SE in co-op bijstellen (§2.9), daarna pas P2 kwetsbaar maken. | LGD, Combat Designer | T17 (MP-7), T8b |
| O-14 | **Testboss voor C-14 en C-16:** bouwt de Gameplay Programmer met de Combat Designer in T8b, niet in T16c (§4.6) | Gameplay Programmer, Combat Designer | T8b |
| O-15 | **Dubbele slag solo in de finisher:** bedoeld, staat in C-14 (f); toetsen of solo en co-op even groot voelen | LGD, QA Lead | T17, T11 |
| O-16 | **Fasekader T16c** noemt nog "C-01–C-05"; wordt C-01–C-13 en C-15, zoals §4.1 (werk voor de EP) | Executive Producer | Volgende versie fasekader |

### 2.12 Lichtmeter en één gemaal (minimaal, voor de flow-kamer)

**Doel (pillar 2, kernloop "licht oppompen"):** flow vult je lichtmeter, ook wat je echo doet; bij een gemaal pomp je dat licht de stad in, zonder stil te staan. Deze versie is bewust minimaal: één meter, één gemaal, één waterstand met twee standen. Genezen, meer gemalen en waterstanden per wijk zijn T3c.

| ID | Regel |
|---|---|
| **LM-01** | **De meter.** Eén geheel getal `L` van 0 tot **100 LP**; begint op 0 bij de start van de flow-kamer. De meter **lekt niet** en verliest niets bij respawn of breken. Solo is het de meter van P1. In co-op is het één **gedeelde** meter (pitch §3); P2 vult hem met dezelfde bronnen als P1 (LM-02, C-12). Boven 100 gaat het teveel verloren. |
| **LM-02** | **Vullen, ook via de echo.** Bronnen (elk een event in het meetlog, §4.5): P1-treffer op een vijand **+2**; gewone echo-treffer op een vijand **+2** (een pantserdoel met een gebroken pantser telt als vijand); een treffer op een **intact pantser** geeft **0 LP**, van P1 en van de echo, anders kun je stilstaand en zonder echo eindeloos licht slaan; elke schakel van een merk-ontploffing **+6** (dus ook die de echo ontsteekt); springplank-landing (E-07a) **+3 + 2 × (n − 1)**, met `n` het aantal springplank-landingen sinds P1 voor het laatst wereld of licht-geometrie raakte, max. n = 4 (3, 5, 7, 9); een bounce **+2** extra; een **lancering +4** en een **vang +3** (C-11, C-13; voor de springer, ook solo). **Co-op:** een P2-treffer telt als een P1-treffer (+2, op een intact pantser 0), een merk-combo geeft +6 per schakel, en springplank-landingen, bounces, lanceringen en vangen tellen voor P1 én P2, elk met zijn eigen `n`. Treffers op het pomprad (LM-03) en op de trefpop vullen niets. De meter vult dus het snelst in een ketting zonder de grond te raken en met merken die de echo laat knallen (R-V2: de echo moet lonen). |
| **LM-03** | **Het gemaal.** Een `Gemaal`-object met een **pomprad**: een gedeeld object (E-06) met een hurtbox van 32 × 48 px, niet `Merkbaar`. Het gemaal heeft een vulstand `G` van 0 tot **100**. Elke treffer op het pomprad, van **P1, de echo** (een gewone echo-treffer, E-02m) **of P2**, pompt `min(10, L, 100 − G)` LP van de meter naar het gemaal. `G` gaat nooit omlaag. De echo herhaalt je pompslagen D ticks later, dus hij pompt mee zolang er licht in de meter is. |
| **LM-04** | **Oppompen zonder stilstand.** Er is geen knop om vast te houden en geen animatie die P1 vastzet: een pompslag is een gewone aanval (herhaaltijd 20 ticks). Het pomprad hangt zó dat het lopend en springend te raken is (FK-5). Een volle meter maakt het gemaal in 10 slagen vol, waarvan P1 er 5 kan doen (± 100 ticks) en de echo de andere 5 herhaalt terwijl P1 al verder loopt. Wie stilstaand pompt, staat voor MP-1 stil (een AANVAL-flank is geen beweging); 5 slagen blijven ruim onder de 300 ticks. Een halve meter pompt half: niets gaat verloren, er is geen grind (pitch §11, vraag 7). |
| **LM-05** | **Geen genezen in de flow-kamer.** Licht wordt in deze versie alleen opgepompt; of dezelfde meter geneest, beslist T3c (O-7). P1 heeft in de flow-kamer wel levenspunten (5; een vijandelijke treffer kost 1; bij 0 respawn op het begin van de kamer, E-04b). |
| **LM-06** | **Gemaal vol: het water zakt.** Op de tick `t_v` waarop `G = 100` wordt: de waterlijn van de kamer zakt lineair van `y_hoog` naar `y_laag` in **180 ticks**, met de `Diepwater`-zone mee; op `t_v + 180` verdwijnt de **sluisdoorgang** (wereldgeometrie, laag 1) en is de route open. De kamer krijgt warm, gewoon licht (beeld), **nooit** een `FelLicht`-zone (pitch P2: verlicht is niet fel). `Diepwater` is een `Area2D` die alleen het middelpunt van P1 controleert: water is geen speellaag (#51: 1A), de echo en P2 negeren het. Komt het middelpunt van P1 in `Diepwater`, dan wordt hij na 30 ticks teruggezet op zijn laatste vloerpositie buiten het water, zonder schade; dat telt als respawn (E-04b). De stand van het gemaal blijft bewaard bij respawn. |

### 2.13 Afwijkpunten van de ideecheck (R-V9)

E-14 en de merksprong nemen de zes afwijkpunten van `docs/business/ideecheck-v0-4.md` §2 over. Er is **geen** afwijking.

| # | Afwijkpunt (ideecheck §2) | Waar het staat | Hoe |
|---|---|---|---|
| 1 | De ontsteker is altijd een tweede lichaam | E-14c, E-02m, C-12 | Solo laat alleen de echo een merk ontploffen; in co-op het lichaam dat het merk níét zette. Niemand heeft een ontsteekknop of "vasthouden om te laden". De lanceerhouding (C-11a) is wel vasthouden, maar laadt niets: geen schade, geen merk, geen ontploffing; alleen de plank lanceert (toets: O-12) |
| 2 | Het merk is ruimtelijk, geen opgespaarde balk; de route van de echo is de lont | E-14a, E-14d, E-02m | Max. 1 merk per object, geen teller, geen voorraad schade die wordt omgezet (vaste O). De echo laat alleen merken knallen binnen 80 px van **zijn opgenomen route**; een grotere ontploffing komt uit **ketting en positie** (merken binnen 48 px van elkaar). Dit leest "meer merken = grotere ontploffing" (pitch §3) bewust als ketting, niet als stapel |
| 3 | Merken komen niet uit pareren | E-14f | Pareren geeft nooit een merk; als het komt, iets anders (licht, dash terug) |
| 4 | Merksprong kort, binnen de straal, een schaduw die uitrekt | E-02m | R = 80 px (± 1/8 van de schermbreedte), 4 ticks heen en 8 terug, geen voorwerp. Met R = 80 px haalt de echo een lopende basisvijand bij elke D: in het slechtste geval ligt het merk bij D = 180 op 74 px van de opgenomen positie (vijand 0,25 px/tick, 30 ticks stil na een treffer, §4.3; test E-02m (10)) |
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
- Co-op: P2 volgens C-01–C-13 (§2.7; de finisher C-14 en C-16 horen bij bosses en zitten niet in de flow-kamer); de kamer is in beide modi speelbaar zonder aparte versie (pillar 3, C-15). Bouw: T16c, eerst bounce en lancering.
- Objecten: **basisvijand** (§4.3), **pantserdoel** (E-14g), **gemaal met pomprad, waterlijn, `Diepwater` en sluisdoorgang** (§2.12), eenrichtingsrichels (laag 1, `one_way_collision`), een **trefpop** (een niet-`Merkbaar` doel, alleen voor tests).
- Lichtmeter (LM-01–LM-06).
- **Debugmenu:** D = 90 / 120 / 180 (zet ook de blokbreedte van B3, §4.3); **echo uit** (de echo blijft altijd Leeg; voor FK-2); meetlog aan/uit; herstart van de run.
- **Meetlog** volgens §4.5.
- **Placeholder-HUD:** de lichtmeter als balk, de vulstand `G` op het gemaal zelf, de merk-aftelling als krimpende ring op het merk, Leeg/Actief van de echo (O-2). Eindvorm: UX Designer en UI Artist (T10).
- **Placeholder-art** in de 2D-stijl van de stijltest: grijs voor de wereld, vol voor levend, gerasterd voor de echo; het merk als lichtvonk (E-14i). Na het gemaal krijgt K3 warm licht (LM-06).

### 4.2 Indeling

Drie kamers in één scène, die elkaars **buren** zijn in een **lus**: K1 → K2 → K3 → (na het gemaal) terug naar K1 (FK-3). Maten in px op het 640 × 360-beeld; de World & Level Designer werkt de geometrie uit binnen de bouwstenen (§4.3) en de regels FK-1–FK-6 (§4.4).

| Kamer | Maat | Wat de speler doet | Toetst vooral |
|---|---|---|---|
| **K1 Sprongketen** | ± 1280 × 720 (2 × 2 schermen) | Een route met vier bouwstenen: **B1 keren-opstap**, **B2 zigzag omhoog**, **B3 lus**, **B4 lanceerkloof**. Elke bouwsteen heeft een **echolijn** (snel, met springplank en bounce) en een **langzame lijn** (treden, omweg) zonder echo | E-02, E-07a, E-08b, C-10, C-11, norm (1)–(2), R-V12 |
| **K2 Merk-arena** | 640 × 360 (1 scherm) | Vloer en twee eenrichtingsplatforms op 70 px. **Golf 1:** 3 basisvijanden. **Golf 2:** 3 basisvijanden + 1 pantserdoel. Een golf is op als zijn basisvijanden op zijn (het pantserdoel telt niet mee); dan start de volgende. Na golf 2 komen de 3 basisvijanden van golf 2 terug elke keer dat P1 de arena binnenkomt, zolang het gemaal niet vol is; een pantserdoel dat nog staat, blijft staan (er is er nooit meer dan één). De arena sluit niet af: wie wil, loopt door | E-02m, E-14, C-12, C-13, LM-02, norm (2) |
| **K3 Gemaal** | ± 960 × 360 (1,5 scherm) | Pomprad op de oever, naast de route (FK-5). Rechts een ondergelopen straat met `Diepwater` en aan het eind de sluisdoorgang. Gemaal vol → water zakt (180 ticks) → straat open → doorgang naar K1 | LM-03, LM-04, LM-06, norm (1) bij het oppompen |

**Een run** begint bij de ingang van K1 (`RUN_START`) en eindigt als P1 na `GEMAAL_VOL` via de sluisdoorgang K1 weer binnenkomt (`RUN_EIND`). Doel voor een geoefende run: **≤ 120 s**, waarvan de meter na K1 en één keer K2 (golf 1 + 2) **≥ 100 LP** heeft. De World & Level Designer stemt het aantal springplank-plekken in K1 en vijanden in K2 daarop af; haalt een geoefende run dat niet, dan eerst die aantallen bijstellen, niet de LP-waarden (die zijn van de LGD).

### 4.3 Bouwstenen en maten (voor de World & Level Designer)

De vier situaties waarin de echo vóór of onder je uitkomt (pitch §5): omhoog, keren, vallen, lussen. **Vallen** (vangen, C-13) heeft in de flow-kamer geen eigen bouwsteen: het mag overal gebeuren en wordt geteld (§4.5), de bouwsteen komt in T3c (O-11). De andere drie zitten in K1, met daarbij **B4** voor de lancering (C-11). **Elke maat hieronder werkt voor D = 90, 120 en 180**, nagerekend met de waarden uit §2.5a. Waar één maat niet voor alle D kan werken (B3), ligt de maat per D vast; dan krijgt elke D hetzelfde venster en kiest F0 de staart niet op de geometrie.

Rekenregels:

- **Keren.** Wie van zijn echo wegloopt en omkeert, ontmoet hem **D/2 ticks** na het keren, op **D px** van het keerpunt (2 px/tick × D/2): 90 / 120 / 180 px. Dat lukt alleen als hij de laatste **D + 24 px** vóór het keerpunt rechtdoor over vlakke vloer liep (204 px bij D = 180). Het ontmoetingspunt schuift dus 90 px tussen D = 90 en D = 180. Het doel erboven moet dat hele stuk afdekken, plus 16 px marge voor de afzet en 68 px voor de drift van de bounce.
- **Op je echo springen.** Een sprong vanaf de vloer landt na ± 33 ticks op de bovenkant van de echo (30 px). Bij keren (sluitsnelheid 4 px/tick) zet je dus af als de echo ± 130 px vóór je is: 12 / 27 / 57 ticks na het keren.
- **Hoogte.** Een sprong haalt ± 50 px. Een **bounce vanaf een echo op de vloer** haalt ± 100 px boven die vloer (lichaam 30 px + bounce 72 px). Een richel op **70–100 px** boven het vlak waar de echo loopt, is dus alleen met de echo in één beweging te halen. Opzij haalt de bounce tot de richel 68 px (richel op 90) of 80 px (richel op 70); met de teruggekregen dash (E-07a) 20 px meer.
- **Breedte.** Sprong + dash haalt ± 120 px; een gat tot 110 px is zonder echo te doen.

| Bouwsteen | Situatie (pitch §5) | Opzet en maten | Echolijn | Langzame lijn |
|---|---|---|---|---|
| **B1 Keren-opstap** | keren | Een gang van **320 px** die doodloopt tegen een muur, waarvan de laatste **220 px** vlakke vloer. Boven de gang over de hele lengte een eenrichtingsgalerij op 90 px | Loop naar de muur, keer om, spring op je echo als hij ± 130 px vóór je is (je ontmoet hem op 90 / 120 / 180 px van de muur, altijd onder de galerij) en bounce naar de galerij | Twee treden van 45 px bij de muur |
| **B2 Zigzag omhoog** | omhoog (via keren) | Een schacht van **480 px** breed met vier eenrichtingsrichels van **416 px** op 90, 180, 270 en 360 px, om en om tegen de linker- en de rechterwand; aan de open kant van elke richel een gat van 64 px. Elke verdieping is een B1: je loopt naar de wand van je richel, keert, en ontmoet je echo op D px van die wand, onder de volgende richel | Op elke richel naar zijn wand, omkeren, op je echo, bounce naar de volgende richel en doorlopen naar de andere wand. Je landt altijd ≥ 216 px van die wand, genoeg voor de volgende keer (D + 24 ≤ 204 px) | Per richel een trede van 45 px hoog en 40 px breed tegen de wand; vanaf de trede haal je de volgende richel (twee sprongen per verdieping) |
| **B3 Lus** | lussen | Een kom met **190 px** vlakke vloer. Links de ingang op vloerhoogte, met erboven de uitgang: een eenrichtingsgalerij op **70 px** die 40 px de kom in steekt. Rechts een blok van **45 px** hoog tegen de rechterwand, met een bovenkant van **B = D − 60 px** (30 / 60 / 120 px; de rechterwand vangt je op, dus 30 px is genoeg om op te landen). Tussen blok en galerij ligt **150 px**: zonder echo niet over te springen (aan de rand springen, coyote en laat in de val dashen haalt ± 124 px, met het lichaam erbij ± 140 px) | Loop door de kom, spring op het blok, keer tegen de wand en stap of spring terug de kom in: je landt op je echo, die net door de ingang de kom in loopt, en bounce naar de galerij (met de teruggekregen dash altijd te halen, in het eerste deel van het venster ook zonder) | Val in de kom, neem een trede van 35 px bij de ingang en dan de galerij |
| **B4 Lanceerkloof** | lanceren (C-11) | Twee vloeren op gelijke hoogte met een kloof van **160 px**; de kloofbodem ligt 90 px lager. Vóór de rand ≥ 40 px vlakke vloer; boven de kloof en de laatste 100 px ervoor ≥ 180 px vrije hoogte. Zonder lancering niet over te steken: sprong + dash haalt van vloer tot vloer met het lichaam erbij ± 140 px; bounce + dash haalt op plankhoogte ± 136 px en tot op de vloer ± 145 px. Een lancering vanaf een drager die ≤ 8 px van de rand staat, haalt op plankhoogte ± 180 px en tot op de vloer aan de overkant ± 190 px: 14 px marge zonder dash | **Co-op:** de drager gaat aan de rand staan, slaat en houdt AANVAL vast met zijn gezicht naar de kloof; na 12 ticks springt de springer op hem en vliegt over. De drager neemt daarna de langzame lijn. **Solo:** loop naar de rand, sla op `T` en houd AANVAL ≥ 30 ticks vast met je gezicht naar de kloof; je echo loopt D ticks later onder je in en staat van `T + D + 12` tot `T + D + 30` in houding. Spring op `T + D − 21 … T + D − 3` (landing ± 33 ticks later) en je vliegt over. Je wacht dus 69 / 99 / 159 ticks (onder de 300 van MP-1, wel zichtbaar in MP-3) | In de kloof vallen, 160 px lopen, twee treden van 45 px tegen de overkant |

**Waarom B3 per D.** In een lus moet je ongeveer D ticks na je eigen doorgang boven je echo zijn. Met één vaste kom komt de echo bij D = 90 te laat en bij D = 180 te vroeg; geen enkele vaste maat werkt voor alle drie (nagerekend). Daarom groeit alleen de bovenkant van het blok met D: je loopt er bij D = 180 90 px langer over dan bij D = 90. Dat is de echte prijs van een lange staart in een lus (pitch §5), en elke D krijgt hetzelfde venster. Het blok is één object met drie breedtes; het debugmenu zet de breedte bij een wissel van D (§4.1).

**Nagerekend per D** (sprong- en landingstijden uit §2.5a; ± 16 px speling bij de afzet; τ = de tijd van afzet op het blok tot de rand, ± 6 ticks speling):

| | D = 90 | D = 120 | D = 180 |
|---|---|---|---|
| Keren: ontmoeting na het keren | 45 ticks, 90 px | 60 ticks, 120 px | 90 ticks, 180 px |
| B1, B2: afzet naar de echo, na het keren | 12 ticks | 27 ticks | 57 ticks |
| B2: kleinste afstand van de landing tot de volgende wand (nodig: D + 24) | 306 px (114) | 276 px (144) | 216 px (204) |
| B3: bovenkant blok | 30 px | 60 px | 120 px |
| B3: landen op de echo kan, na het verlaten van de blokrand | 29–49 ticks (26–52 met de τ-speling); echo 99–146 px van de ingang; zonder dash tot ± 40 ticks | gelijk | gelijk |

**Basisvijand** (werkaanname LGD, startwaarden voor de Combat Designer): `Merkbaar`, lichaam en hurtbox 16 × 24 px, 30 SE, loopt op de vloer **0,25 px/tick** naar P1 (springt niet, verlaat K2 niet), staat na elke treffer **30 ticks** stil, valt aan als P1 binnen 16 px is: 30 ticks zichtbare aanloop, dan 6 ticks een aanvalsvlak van 20 × 16 px op laag 2 (kost P1 1 levenspunt). **Waarom zo traag:** bij de merksprong ligt het merk in het slechtste geval 36 px (verste slagafstand: aanvalsvlak 8–28 px vóór P1, plus de halve vijand) + 0,25 × (D + 3 − 30) px van de opgenomen positie: **52 / 59 / 74 px** bij D = 90 / 120 / 180, dus altijd binnen R = 80. Met de vorige waarden (0,5 px/tick, 20 ticks stil) was dat 118 px bij D = 180. Een snellere vijand mag zolang `36 + v × (D_max − 27) ≤ R`; een grotere R vraagt eerst O-9. **Pantserdoel:** `Merkbaar`, 16 × 24 px, staat stil, valt niet aan, pantser volgens E-14g, daarna 30 SE.

### 4.4 Levelregels voor de flow-kamer

| ID | Regel | Hoe getoetst |
|---|---|---|
| **FK-1** | **Geen puzzel.** Nergens op de route hoeft de speler stil te staan om een volgorde of timing te bedenken (puzzeldefinitie, pitch §4). Elke bouwsteen scoort "ja" op de toetsvraag van pillar 1. | Checklist World & Level Designer, review LGD |
| **FK-2** | **Nooit een slot.** Elke echolijn heeft een langzame lijn zonder echo, die met de beweging uit §2.5a te halen is en hooguit **2×** zo lang duurt. Het gemaal is ook zonder echo vol te krijgen, **met een bovengrens**. Zonder echo komt licht alleen uit P1-treffers op basisvijanden (3 treffers × 2 LP = 6 LP per vijand; het pantser breekt zonder echo niet en geeft 0 LP). Eén keer K2 (golf 1 + 2) geeft 36 LP, elke terugkeer in K2 daarna 18 LP. Zonder echo is het gemaal dus vol na **hooguit 4 terugkeren** in K2 (36 + 4 × 18 = 108 LP), en de run zonder echo duurt **hooguit 2×** zo lang als de scripted geoefende run met echo bij dezelfde D. Haalt de kamer dat niet, dan stelt de World & Level Designer eerst het aantal vijanden bij, niet de LP-waarden. | Headless: een solo-`ScriptedInput` met **echo uit** haalt per D `GEMAAL_VOL` met ≤ 4 terugkeren in K2 en `RUN_EIND` binnen 2× de tijd van de scripted geoefende run met echo |
| **FK-3** | **Open doorgangen.** K1–K2, K2–K3 en K3–K1 zijn buren (E-04a), zonder deur die achter P1 dichtvalt. De doorgang K3–K1 is de sluisdoorgang (LM-06). | Headless: rechte doorloop K1 → K2 → K3 zonder reset (E-04a-test) |
| **FK-4** | **De echo breekt hier niet.** Geen schaduwgeometrie op looppaden (L-06), geen `FelLicht` en geen `Schaduwgevaar` in de flow-kamer. | Headless: de scripted runs laten de echo nooit breken |
| **FK-5** | **Pomprad in de route.** Het middelpunt van het pomprad hangt 15–40 px boven de vloer, raakbaar lopend en vanuit een sprong. Geen vijand komt binnen 80 px (R, E-02m), anders kiest de echo een merksprong in plaats van een pompslag. | Checklist + LM-04-test |
| **FK-6** | **Maten.** Echolijnen gebruiken richels op 70–100 px boven het vlak van de echo; treden van de langzame lijn zijn ≤ 45 px; gaten die je moet overspringen zijn ≤ 110 px. Een gat dat je níet hoeft over te springen, mag breder zijn als de langzame lijn eromheen gaat (de 150 px van B3: daar ga je door de kom, en het gat is ruim breder dan sprong + dash + coyote met het lichaam erbij haalt). | Checklist World & Level Designer |

### 4.5 Flownormen: waarden en meetpunten

Waarden voor de normen van pillar 1 (pitch §4). T16b logt, T17 rekent en rapporteert, **solo en co-op apart**, per D. Een **geoefende speler** is een speler vanaf zijn derde run, of een scripted run.

| # | Wat | Definitie | Waarde (gehaald als) |
|---|---|---|---|
| **MP-1** | Norm (1): stilstand | Een tick `t` is **stil** als het middelpunt van P1 in de ticks `t − 30 … t` steeds **binnen 24 px** (rechte afstand) van zijn middelpunt op `t − 30` bleef, **en** er in `t − 29 … t` geen JUMP-flank was die een sprong of bounce startte en geen DASH-flank die een dash startte. AANVAL, INTERACTIE en ECHO tellen **niet** als beweging: wie stilstaand slaat of pompt, staat stil, en heen en weer wiebelen binnen 24 px ook. Een **stilstand** is een reeks aaneengesloten stille ticks. Telt niet mee: pauzemenu, de eerste 30 ticks van een run en de eerste 60 ticks na een respawn. (Gewoon keren tegen een muur geeft hooguit 2 stille ticks.) | Langste stilstand per run **≤ 300 ticks** (5 s), ook bij het gemaal. 301–360 ticks: grensgeval, de LGD bekijkt de opname. > 360: niet gehaald |
| **MP-2** | Norm (2): echo als springplank of merk-afmaker | Een **echo-actie** is een springplank-landing (met of zonder bounce: één contact = één actie), een lancering, een vang of een merksprong met ontploffing (een ketting telt als één actie). In co-op telt elke samenwerkingsactie (§2.7), van P1 en van P2 | **≥ 3,0 echo-acties per minuut** speeltijd over de run, én in K1 en K2 elk apart; geen venster van 40 s zonder echo-actie |
| **MP-3** | R-V12: springplank vóór je | Springplank-landingen per minuut (alleen rapporteren) en het aandeel landingen zonder stilstand (MP-1) van **20 ticks of langer** in de 120 ticks ervoor. Wie op zijn echo wacht met tikken of wiebelen, telt dus als wachten | Aandeel zonder stilstand **≥ 75 %** |
| **MP-4** | R12: echo Leeg | Aandeel van de speeltijd dat de echo Leeg of Buiten is | **≤ 40 %** |
| **MP-5** | Norm (3): vloeiend | Na elke run, per kamer: *"Voelde het vloeiend/satisfying?"* (1–5) | Gemiddelde **≥ 4,0** per modus; geen kamer gemiddeld < 3,0 |
| **MP-6** | Lichtmeter: de echo telt mee | Aandeel van de gevulde LP uit bronnen met de echo (echo-treffer, ontploffing, springplank, bounce, lancering, vang); aantal pompslagen van de echo. Co-op: bronnen met P2 of met een samenwerkingsactie; pompslagen van P2 | **≥ 40 %** van de LP in een geoefende run; **≥ 1** pompslag van de echo (co-op: van P2) per run |
| **MP-7** | R10, R-V5: co-op niet te snel, niemand wacht | Alleen co-op, per D: (a) mediane runtijd co-op tegenover solo; (b) MP-1 apart voor P1 én P2 (voor P2 op zijn middelpunt; ticks dat P2 opgelost is, tellen niet mee); (c) per speler het aantal samenwerkingsacties waarin hij drager of springer was; (d) aandeel speeltijd dat P2 opgelost is (C-06, C-07) | (a) runtijd co-op **≥ ½ ×** solo (co-op ≤ 2× zo snel); (b) langste stilstand van elke speler **≤ 300 ticks**; (c) elke speler **≥ 1,0** per minuut; (d) **≤ 10 %** |

**Staartlengte kiezen.** Per D (90 / 120 / 180) gelden MP-1 t/m MP-6, in co-op ook MP-7. Gekozen wordt de D die MP-1, MP-2, MP-4 en MP-6 (co-op ook MP-7) haalt met de hoogste MP-5; bij gelijkspel 120. Haalt geen enkele D de normen: herontwerp door de LGD en een tweede flow-test (F0); haalt die MP-2 niet, dan een `ceo-beslissing` (R-V12). Een D buiten 90–180 is een `ceo-beslissing` (F4).

**Meetlog** (T16b). Eén CSV per run, `meetlog_<datum>_<solo|coop>_D<D>_<speler>.csv`, met de kolommen `tick, kamer, event, waarde, bron, x, y`. Events:

| Event | `waarde` / `bron` |
|---|---|
| `RUN_START`, `RUN_EIND`, `KAMER` | — / nieuwe kamer |
| `STIL_START`, `STIL_EIND` | lengte in ticks bij `STIL_EIND` / `p1` of `p2` |
| `ECHO_LEEG_START`, `ECHO_LEEG_EIND` | reden (`reset`, `buiten`) |
| `SPRINGPLANK`, `BOUNCE`, `LANCERING`, `VANGEN` | `n` uit LM-02 / drager: `echo`, `p1` of `p2` (in co-op is de springer de ander) |
| `DROP_IN`, `DROP_OUT`, `P2_OPGELOST`, `P2_TERUG` | — / oorzaak (`stoppen`, `apparaat`, `fellicht`, `gevaar`, `val`, `leiband`) |
| `MERK_GEZET`, `MERKSPRONG`, `ONTPLOFFING` | schakel `k` / merk-id |
| `LP` | `+n` / bron uit LM-02 (met `p1`, `p2` of `echo`) |
| `POMP`, `GEMAAL_VOL` | gepompte LP / `p1`, `p2` of `echo` |
| `RESPAWN`, `BREEK`, `LOSLATEN` | oorzaak |
| `BOSS_START`, `FINISHER_START`, `FINISHERSLAG`, `BOSS_VERSLAGEN` | aantal slagen bij `BOSS_VERSLAGEN` (alleen bij bosses, C-14; niet in de flow-kamer) |

Het log is deterministisch: twee runs met dezelfde `ScriptedInput` en dezelfde D geven hetzelfde log. Voor elke D is er minstens één **scripted geoefende run** (World & Level Designer met Gameplay Programmer) die MP-1, MP-2, MP-4 en MP-6 haalt, solo en (met twee `ScriptedInput`s) co-op, de co-op-run ook MP-7 (b)–(d); die bewijst dat de kamer de normen kán halen voordat mensen hem spelen.

### 4.6 Acceptatiecriteria (tests per regel)

Automatisch te testen, headless zoals de spike (`game/tests/`), tenzij er "checklist" staat. **"(alle D)"** betekent: de test draait voor D = 90, 120 en 180. "Reset op `t0`" betekent: `geldig_vanaf = t0`. Waar een test een vijand nodig heeft die niet mag merken, gebruikt hij de trefpop.

**Opname en reset**

| Regel | Test |
|---|---|
| E-01 | P1 loopt over vloer, lichtbrug en de echo. Het opgenomen frame heeft steunsoort `wereld`, `licht` en `schaduwlichaam` op de juiste ticks, plus positie, snelheid, kijkrichting, `op_vloer`, animatietoestand, events en `aanval_vast`. Na 900 ticks zijn er 600 aaneengesloten frames (geen gaten). |
| E-02 | (alle D) Na D ticks staat de echo op de positie van P1 op tick `t − D` (0 px verschil), met dezelfde kijkrichting. D wordt op `t0` in het debugmenu gewisseld van 120 naar 180: de echo is Leeg tot `t0 + 180` en staat dan op de positie van P1 op `t0`. Bij D = 120 houdt de recorder 600 frames. |
| E-02m | (alle D) (1) P1 slaat een stilstaande vijand op `x`; op `x + D + 3` staat de echo op het merk (0 px), de vijand krijgt 20 SE op die tick en niet eerder; op `x + D + 11` staat de echo weer op zijn opname (0 px). (2) Merk op 79 px van de opgenomen positie: merksprong; op 81 px: geen merksprong. (3) Twee merken op 40 en 60 px: doel is het merk op 40 px; twee merken op gelijke afstand: het oudste. (4) Tussen echo en merk staat een muur op laag 1: geen merksprong; op laag 5: geen merksprong; op laag 4 (licht-geometrie): wel. (5) P1 valt op `x + D + 1` van boven op de echo: P1 valt erdoor (plank uit). (6) Het merk ligt in een `FelLicht`-zone: de echo breekt op de tick waarop zijn middelpunt de zone in komt, geen ontploffing, `geldig_vanaf` = die tick. (7) De doelvijand sterft op `x + D + 1`: geen ontploffing, de echo staat op `x + D + 9` weer op zijn opname. (8) AANVAL zonder merk binnen R met de trefpop in het aanvalsvlak: gewone echo-treffer, de echo verlaat zijn opname niet. (9) Het opgenomen pad loopt tijdens de merksprong 3 ticks door een schaduwmuur: de echo breekt niet tijdens de merksprong; loopt het pad na de merksprong nog 3 ticks door de muur, dan breekt hij op de 3e. (10) **Lopende basisvijand:** P1 slaat op `x` een basisvijand met het verste deel van zijn aanvalsvlak (vijandmiddelpunt 36 px vóór P1), springt over hem heen en loopt van de opgenomen positie weg, zodat de vijand na zijn 30 ticks stil die kant op loopt. Op `x + D` ligt het merk op ≤ 36 + 0,25 × (D − 30) px van de echo (≤ 74 px bij D = 180): merksprong, en op `x + D + 3` krijgt de vijand 20 SE. Bij D = 180 verplicht; de test draait ook voor 90 en 120. |
| E-03 | (alle D) Reset op `t0`; P1 deed op `t0 − 5` INTERACTIE bij een schaduwhendel en stond op `t0 − 10` boven een gat. Op `t0 + D − 5`: de hendel staat nog in zijn beginstand, de echo is onzichtbaar en een P1 die op de echo-plek valt, valt erdoor. |
| E-04a–d | (alle D) Voor elke oorzaak apart (kamerwissel naar een kamer die geen buur is, respawn, Loslaten, wissel van D, breken) op `t0`: echo Leeg op `t0 + D − 1`, Actief op `t0 + D`, op de positie van P1 op `t0`. |
| E-04a | (alle D) Kamers A en B zijn buren, C is geen buur van B. (1) P1 loopt op `t0` van A naar B: geen reset; op `t0 + D` gaat de echo door dezelfde doorgang (0 px van het opgenomen pad); de Leeg-teller telt 0 ticks. (2) P1 loopt van B terug naar A: geen reset. (3) P1 wordt van B naar C gezet (debug-teleport): reset op die tick. (4) A wordt op `t1` als niet geladen gemarkeerd terwijl frame `p` in A ligt: de echo is Buiten (onzichtbaar, P1 valt door de plek van de plank, een INTERACTIE-event in A wordt niet uitgevoerd), `geldig_vanaf` blijft gelijk; zodra frame `p` in B ligt, is de echo Actief op zijn opname. (5) Validatie bij het laden: is A buur van B maar B niet van A, dan een foutmelding. |
| E-04e | P1-middelpunt gaat over de grens naar kamer B: kamerwissel op die tick. P1 springt terug naar A: opnieuw kamerwissel. P2 gaat in co-op naar kamer B terwijl P1 in A blijft: geen kamerwissel. |

**Lagen en platform**

| Regel | Test |
|---|---|
| E-05 | Lagen en maskers van P1, P2, echo, schaduwplank en lichtplank zijn exact zoals in de tabel. P1 loopt tegen een lichtmuur en door een schaduwmuur; P2 loopt tegen een schaduwmuur en door een lichtmuur. Solo is de lichtplank er niet; na een drop-in wel, na een drop-out niet meer. |
| E-06 | Echo op een lichtplaat: plaat blijft uit. Echo op een schaduwplaat: plaat gaat aan. P1 op een schaduwplaat: plaat blijft uit. P1 en echo elk op een gedeelde plaat: beide gaan aan. |
| E-07 | P1 die van boven op de echo landt, blijft staan. P1 die van opzij komt, loopt erdoor. P1 die van onder springt, gaat erdoor. Echo die omhoog door P1 beweegt: P1-positie verandert die tick niet door de echo. Echo loopt het opgenomen pad tegen een gedeeld duwblok: het blok blijft op zijn plek. Echo Leeg terwijl P1 erop staat: P1 valt in dezelfde tick. |
| E-07a | **(1) Meebewegen:** echo beweegt 2,0 px/tick naar rechts (P1 liep daar), P1 staat erop zonder input: P1-x stijgt elke tick met 2,0 px, in dezelfde tick als de echo. Met een muur rechts: P1 stopt tegen de muur, de echo gaat door en P1 valt als de plank onder hem weg is. **(2) Landen:** P1 valt met `v.x = 2,0` op de echo: op de landingstick is `v.x = 2,0` en `v.y = 0`. P1 heeft zijn dash in de lucht gebruikt en landt op de echo: `dash_klaar = true`, en na het verlaten van de plank kan hij in de lucht opnieuw dashen. P1 landt in tick 4 van een dash: de dash loopt tot tick 10, daarna `dash_klaar = true`. P1 staat 60 ticks op de echo: één `SPRINGPLANK`-event. **(3) Bounce:** JUMP op de plank: `v.y = −6,0`, de top ligt 70–74 px boven de plank, `v.x` ongewijzigd, `BOUNCE`-event. JUMP 10 ticks vóór het landen: bounce op de landingstick; 11 ticks vóór: geen bounce en geen sprong. JUMP 6 ticks na het verlaten van de plank: bounce; 7 ticks na: geen sprong. Bounce vanaf een echo op de vloer: P1-onderkant komt ≥ 98 px boven de vloer. **(4) Geen plank-snelheid:** P1 springt zonder input van een echo die 2,0 px/tick naar rechts beweegt: na de sprong `v.x = 0`. |
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
| g | Met **echo uit**: P1 raakt het pantserdoel op `x`, `x + 20` en `x + 40`: 0 SE, één merk, `L` gelijk. Zelfde input met echo: op `x + D + 3` ontploft het merk, het pantser is weg, het lichaam heeft nog **30 SE** (de ontploffing doet 0 SE op het lichaam) en `L` +6; op `x + D + 20` en `x + D + 40` zijn het gewone echo-treffers (geen merk meer): elk 5 SE en +2 LP, er blijft 20 SE. Daarna doet een P1-treffer 10 SE en +2 LP. **Ketting:** merk op het pantserdoel en op V2 op 30 px; de echo laat V2 knallen op `t_o`: het pantser breekt (0 SE op het lichaam), op `t_o + 1` doet de schakel van het pantsermerk 25 SE op het lichaam. |
| h | Een vijandelijke aanval raakt de positie van de echo: de echo gaat door en breekt niet. |
| i | Checklist (LGD op code, art en audio): "talisman" en "seal" komen niet voor als naam van het merk; het merk heeft geen zegel- of taoïstische symboliek. |

**Lichtmeter en gemaal**

| Regel | Test |
|---|---|
| LM-01 | `L` begint op 0. Opgeteld 110 LP: `L = 100`. Respawn, breken en Loslaten: `L` gelijk. 3000 ticks stilstaan: `L` gelijk. |
| LM-02 | P1-treffer op een basisvijand +2; gewone echo-treffer +2; P1- en echo-treffer op een intact pantser 0, op een gebroken pantser +2; treffer op de trefpop 0; ketting van 3 schakels +18; 4 springplank-landingen zonder grond 3 + 5 + 7 + 9 = 24, de 5e +9; na grond weer +3; bounce +2 extra; pompslag +0. |
| LM-03 | (alle D) `L = 100`, `G = 0`: P1 pompt 5 slagen op `x … x + 80` → `G = 50`, `L = 50`; de echo herhaalt ze op `x + D … x + D + 80` → `G = 100`, `L = 0`. `L = 30`: na 5 P1-slagen `G = 30`, de slagen 4 en 5 pompen 0; de echo pompt 0. `G = 95`, `L = 50`: een slag pompt 5. Respawn: `G` gelijk. |
| LM-04 | AANVAL 60 ticks vasthouden bij het pomprad: één slag. P1 slaat het pomprad vanuit een sprong (op de top): de slag pompt. De scripted geoefende run met een volle meter heeft bij het gemaal geen stilstand > 300 ticks (MP-1). |
| LM-05 | Een vijandelijke treffer kost P1 1 levenspunt; bij 0: respawn op het begin van de kamer, `L` en `G` gelijk. |
| LM-06 | `G = 100` op `t_v`: de waterlijn is op `t_v + 90` halverwege (± 1 px) en op `t_v + 180` op `y_laag`; de sluisdoorgang is er nog op `t_v + 179` en weg op `t_v + 180`. Na `t_v` is er in K3 geen `FelLicht`-zone. P1-middelpunt in `Diepwater` op `t`: op `t + 30` staat P1 op zijn laatste vloerpositie buiten het water, levenspunten gelijk, reset op `t + 30`. De echo loopt door `Diepwater`: breekt niet. Respawn na `t_v`: water blijft laag. |

**Flow-kamer en meetlog**

| Regel | Test |
|---|---|
| FK-2 | Headless, per D: solo-`ScriptedInput` met echo uit haalt `GEMAAL_VOL` met ≤ 4 terugkeren in K2 en `RUN_EIND` binnen 2× de tijd van de scripted geoefende run met echo. |
| MP-1 | Uit het log, met echo uit: (1) P1 loopt, staat vanaf `t0` stil bij het intacte pantserdoel en tikt 600 ticks lang (`t0 … t0 + 599`) elke 20 ticks AANVAL: één stilstand van `t0 + 19` tot `t0 + 599` (581 ticks, MP-1 niet gehaald) en `L` blijft 0. (2) Zelfde met elke 10 ticks INTERACTIE: zelfde stilstand. (3) P1 wisselt 300 ticks lang elke 6 ticks LEFT en RIGHT: stil vanaf de 30e tick. (4) P1 springt 300 ticks lang ter plaatse (elke 40 ticks JUMP): geen stille tick. (5) P1 loopt 100 ticks naar een muur en keert (B1): hooguit 2 stille ticks, geen stilstand van 20 ticks. (6) P1 dasht vanuit stilstand: de stilstand eindigt op de DASH-tick. |
| MP-3 | Uit het log: (1) P1 keert in B1 en landt op de echo: telt als landing zonder stilstand. (2) P1 staat 60 ticks vóór de landing stil en tikt elke 20 ticks AANVAL: telt als landing **met** stilstand. |
| FK-3, FK-4 | Headless: de scripted geoefende run per D heeft 0 `BREEK`-events en geen `ECHO_LEEG_START` door een kamerwissel. |
| FK-1, FK-5, FK-6 | Checklist World & Level Designer, review LGD. |
| Meetlog (§4.5) | Dezelfde `ScriptedInput` twee keer met dezelfde D: identieke logs. Het log bevat elk eventtype uit de tabel minstens één keer in de scripted geoefende run. Uit het log berekend haalt die run, per D, MP-1, MP-2, MP-4 en MP-6. |

**Co-op (C-01–C-16)**

Headless met twee `ScriptedInput`s (P1 en P2). Waar "solo" staat, is er geen P2 en draait de test **(alle D)**.

| Regel | Test |
|---|---|
| C-01 | Gescripte sessie van 3000 ticks met twee drop-ins en twee drop-outs: op elke tick is het aantal lichamen ≤ 2 en het aantal schaduwlichamen ≤ 1. Tijdens co-op is er geen echo-actor zichtbaar, botsend of met een plank, ook niet in de 120 ticks dat P2 opgelost is. Tijdens een finisher (C-14) is er één extra node, de gedeelde echo, met `collision_layer = 0`, `collision_mask = 0` en geen plank. |
| C-02 | P2 op een lichtplaat: uit; op een schaduwplaat: aan. P2 loopt tegen een schaduwmuur: hij botst en lost niet op; door een lichtmuur: loopt erdoor. Vijandelijke aanval op P2: geen effect. P2 loopt door een pickup: blijft liggen. P2 raakt een basisvijand zonder merk: 10 SE, één merk met zetter P2, +2 LP. P2 slaat een vijand met een merk van P1 binnen 80 px, maar niet in zijn aanvalsvlak: er gebeurt niets (geen merksprong). P2 slaat het pomprad bij `L = 50`, `G = 0`: `G = 10`, `L = 40`. P2 drukt `ECHO` 60 ticks: er gebeurt niets. P2 gaat naar een andere kamer terwijl P1 blijft: geen kamerwissel. |
| C-03 | Drop-in met Actieve echo: P2 start op de positie, snelheid en kijkrichting van de echo; er is daarna geen echo. Drop-in tijdens een merksprong (tick `t + 2`): P2 op de huidige positie, geen ontploffing. P1 staat op de echo bij de drop-in: P1 staat op de tick erna op P2 (`op_vloer`, geen val). Drop-in met Lege echo: P2 op de positie van P1. P1 staat met de bovenkant tegen schaduwgeometrie: P2 op de dichtstbijzijnde vrije plek binnen 64 px. Geen vrije plek binnen 64 px: P2 op de laatste vloerpositie van P1. Een merk dat P1 vóór de drop-in zette, heeft zetter P1. |
| C-04 | (alle D) 1200 ticks co-op: de recorder van P1 heeft 600 aaneengesloten frames, met `aanval_vast`. P1 laat in co-op los op `t0` (de 30e tick van ECHO, E-09), drop-out op `t0 + 20`: echo Leeg tot `t0 + D`, Actief op `t0 + D`. P1 en P2 slaan elk elke 20 ticks gedurende 900 ticks: het finisherlog heeft voor elk precies de events van de laatste 600 ticks (30 per lichaam). Solo: een echo-treffer van een Lege echo staat niet in het log. |
| C-05 | (alle D) Drop-out `D/2` ticks na een kamerwissel naar een kamer die geen buur is: echo Leeg tot tick `D` na die kamerwissel. Drop-out `D + 300` ticks na zo'n kamerwissel: de echo staat op dezelfde tick Actief op de positie van P1 van D ticks geleden. P1 staat op P2 bij de drop-out: P1 valt op die tick, de lichtplank is uit. Stopknop 59 ticks: P2 blijft; 60 ticks: P2 weg. Apparaat 179 ticks weg: P2 blijft; 180: P2 weg. P2 zette op `x` een merk, drop-out op `x + 10`: het merk leeft tot `x + D + 30`; komt de echo er binnen R langs met een AANVAL-event, dan laat hij het knallen. |
| C-06 | P2 in `FelLicht`, in een `Schaduwgevaar` en onder de kamerrand: telkens P2 weg, 120 ticks later naast P1. Geen checkpoint-reset: P1-positie en schakelaarstanden blijven gelijk. |
| C-07 | P2 59 ticks buiten beeld: blijft. 60 ticks: lost op op de 60e tick. P1-positie wordt in de hele test nooit door de camera veranderd. |
| C-08 | P1 sterft in co-op op `t0`: beiden respawnen op het checkpoint, P2 volgens de plaatsingsregel, `geldig_vanaf = t0`. Solo (alle D): P1 sterft op `t0`, echo Leeg tot `t0 + D`. |
| C-09 | P2 valt van boven op P1: P2 landt en staat (lichtplank). P2 komt van opzij of van onder: loopt of springt erdoor. P1 loopt 2,0 px/tick met P2 zonder input op hem: P2-x stijgt elke tick 2,0 px, in dezelfde tick als P1 (volgorde: P1, dan P2). Een logtest per tick bevestigt de volgorde in beide gevallen. Solo: de lichtplank bestaat niet; de echo landt nooit op P1. **Ladder:** P2 springt vanaf de vloer, P1 landt in de lucht op P2: P1 staat. P1 bouncet, P2 valt daarna van boven op P1 terwijl P1 nog in de lucht is: P2 valt erdoor (P1 stond sinds zijn grondcontact op een plank). Zodra P1 de vloer raakt, landt P2 weer op hem. P2 lost op terwijl P1 op hem staat: P1 valt op die tick. |
| C-10 | De tests van E-07a (2)–(4) opnieuw met P1 op P2 en met P2 op P1: zelfde uitkomsten (`v.x` blijft, `v.y = 0`, dash terug, bounce `−6,0`, top 70–74 px boven de plank, buffer 10 / 11 ticks, coyote 6 / 7 ticks, geen plank-snelheid). Vier landingen om en om op P1 en P2 zonder grond met de ladderregel: niet mogelijk na de tweede; P1 en P2 houden elk een eigen `n`. |
| C-11 | **(a)** Co-op: P2 slaat op `x` en houdt AANVAL vast; P1 staat op P2: geen lancering op `x … x + 11`, wel op `x + 12` (event `LANCERING`, `L` +4 voor de springer, LM-02). P2 laat los op `x + 11`: geen lancering. P2 houdt 200 ticks vast en P1 landt op `x + 150`: lancering op de landingstick. De houding doet geen schade: een vijand die P2 op `x + 12 … x + 60` overlapt, krijgt alleen de 10 SE van `x`. **(b)** Lancering op `t` met P2 naar rechts: op `t + 1` `v.x = 4,0`, `v.y = −7,5`; LEFT op `t + 5`: `v.x` blijft 4,0 tot `t + 30`, op `t + 31` gewone beweging; top 112–117 px boven de plank; zonder dash en met RIGHT ingedrukt landt P1 op plankhoogte 176–188 px verder; `dash_klaar = true` op `t + 1`. JUMP op `t`: lancering, geen bounce. P2 op P1 met P1 in houding: zelfde. **(c)** Muur op 40 px: `v.x = 0` bij de botsing, lanceerstaat uit. DASH op `t + 10`: dash van 10 ticks, daarna lanceerstaat uit. **(d)** Na een lancering staat P1 opnieuw op P2, die nog vasthoudt: geen tweede lancering tot P2 opnieuw slaat en 12 ticks vasthoudt. **(e)** Solo (alle D): P1 slaat op `T` aan de rand van B4 en houdt 30 ticks vast, springt op `T + D − 12`: landt op de echo, lancering op de landingstick, richting de kloof, P1 haalt de overkant. Zelfde zonder vasthouden (tik): geen lancering. P1 staat op de echo op de tick van een AANVAL-event van de echo met een merk op 40 px: gewone echo-treffer, geen merksprong, P1 valt niet. Tijdens een merksprong landt P1 op de plek van de echo: P1 valt erdoor. |
| C-12 | Co-op: P1 merkt V1 op `x`; P2 raakt V1 op `x + 30`: ontploffing op `x + 30`, V1 20 SE (geen 10 SE erbij), +6 LP. P1 raakt V1 opnieuw vóór dat: 10 SE, merk blijft. P2 merkt V2; P1 raakt V2: ontploffing. P2 merkt V2 en raakt hem zelf opnieuw: 10 SE, geen ontploffing. Ketting: merken van P1 op V1 en van P2 op V2 (40 px); P2 laat V1 knallen: V1 op `t_o`, V2 op `t_o + 1` (25 SE). Pantserdoel met een merk van P2; P1 raakt het: het pantser breekt (0 SE op het lichaam). Een merk dat geen van beiden laat knallen, dooft op `x + D + 30` (alle D). Solo: de echo laat merken knallen (E-02m-tests) en zet er nooit een. |
| C-13 | **Co-op:** P1 valt van 64 px boven de bovenkant van P2 recht op P2: vang op de tick waarop zijn onderkant de bovenkant passeert, `v.y = −6,0`, `v.x` gelijk, dash terug, `VANGEN`, +3 LP. Zelfde met P1 20 px opzij van het middelpunt van P2: vang; 25 px opzij: geen vang (P1 valt erlangs). P1 valt van 20 px boven P2 (`v.y` < 4,0): gewone landing, geen vang. P1 valt na de vang opnieuw op P2 zonder grond: gewone landing, geen tweede vang; na grondcontact weer wel. Een vijandelijk aanvalsvlak raakt P1 op vangtick + 11: geen schade; op + 12: 1 levenspunt. P1 in lanceerstaat valt op P2: geen vang. P2 in houding en P1 valt snel op hem: vang, geen lancering. Zelfde test met P2 als springer en P1 als drager: zelfde uitkomsten (zonder levenspunten). **Solo (alle D):** P1 staat tot `x` stil op de vloer, wordt op `x` op een richel recht erboven gezet, met zijn onderkant 80 px boven de vloer (debug-teleport, zelfde kamer), en de richel verdwijnt op `x + D − 25`: P1 valt ± 50 px recht op zijn echo (die staat waar P1 tot `x` stond) en wordt gevangen. Met de echo Leeg op dat moment (Loslaten op `x + 1`): P1 valt op de vloer. |
| C-14 | Testboss (`Boss`, 100 SE, `Merkbaar`, drempel 20 SE; **bouwen in T8b** door de Gameplay Programmer met de Combat Designer, niet in T16c: bosses zitten niet in de flow-kamer, §4.1). **Solo (alle D):** de boss wordt met een debugcommando op 20 SE gezet, zonder merk: hij is Wankel, valt niet aan, verdere treffers en een ontploffing van een merk op een vijand ernaast doen hem 0 SE, maar die ontploffing start wel de finisher (aparte run). P1 merkt de boss op `x`; de echo laat het merk knallen op `x + D + 3` = `t_f`: `FINISHER_START`, de boss blijft 0 SE krijgen. Op `t_f + 120` is hij verslagen, op `t_f + 119` nog niet. Het aantal `FINISHERSLAG`-events is precies het aantal AANVAL-events van P1 en van de Actieve echo in `t_f − 600 … t_f − 1` vanaf `BOSS_START`, elk op finishertick `⌊i / 5⌋`, elk +1 LP. Tijdens de finisher: geen vijandelijke aanval, een treffer op een vijand zet geen merk, P1 kan lopen en springen. **Co-op:** zelfde met P1 en P2; slagen van P2 tellen mee, ook van vóór een drop-out binnen de 600 ticks. Een boss die nooit onder de drempel komt, start geen finisher; een ontploffing op een niet-Wankele boss doet gewone schade. De gedeelde echo heeft geen botsing: P1 valt door zijn plek. Na 0 slagen (alleen het merk): de boss is toch verslagen op `t_f + 120`. |
| C-15 | Headless, per D: (1) solo met **echo uit** haalt `RUN_EIND` (FK-2-test); (2) co-op waarin P2 alleen P1 volgt (geen AANVAL, nooit op P1) haalt `RUN_EIND` binnen 2× de tijd van de scripted geoefende co-op-run; (3) in beide runs komt geen enkel samenwerkings-event voor. Checklist (World & Level Designer, review LGD): geen object, sleutel of poort is alleen met een samenwerkingsactie te halen; geen kamer heeft twee versies. |
| C-16 | Testboss uit de C-14-test: (1) solo met **echo uit** is hij in 6000 ticks niet te verslaan (Wankel, geen finisher); (2) co-op waarin P2 nooit slaat: niet te verslaan; (3) solo met echo en co-op met P2: verslagen. Checklist per boss (Combat Designer, review LGD, T8b): minstens één ander verplicht moment met een samenwerkingsactie, elk in beide vormen, elk venster ≥ 10 ticks; de scripted geoefende run per modus haalt MP-1; geen mechaniek vraagt twee live spelers; het merk is voor de merksprong bereikbaar. |

**Levelregels** (geen automatische test, behalve waar het staat)

| Regel | Hoe getoetst |
|---|---|
| L-02 | Headless: K1–K3 hebben een solo-`ScriptedInput` die `RUN_EIND` haalt (de scripted geoefende run). Checklist per kamer: elke schaduwplek op de route ligt op zo'n pad. |
| L-03 | Checklist per poort: wat hem opent (licht/gemaal, vaardigheid, route) staat in de kamerdocumentatie; geen sleutelobject, geen raadsel. |
| L-06 | Zie FK-4. |

---

## 5. Playtestvragen voor de flow-test (T17)

Spelers volgens het fasekader (T17): scripted runs en de CEO (± 20 min). Solo en co-op apart; co-op volgens §2.7 (C-01–C-13). Elke speler speelt alle drie de waarden van D, in wisselende volgorde.

| # | Vraag | Hoe we het meten | Wanneer het goed is |
|---|---|---|---|
| 1 | **Welke staartlengte: 1,5, 2 of 3 s?** (R9, R-V1) | MP-1 t/m MP-6 per D (§4.5); na elke D: *"Wist je waar je echo zou zijn?"* (1–5) | Er is een D die de normen haalt (keuzeregel §4.5); voorspelbaarheid gemiddeld ≥ 4 |
| 2 | **Houdt de echo je in beweging?** Normen (1)–(3) van pillar 1 | MP-1, MP-2, MP-5 | Alle drie gehaald, solo én co-op |
| 3 | **Is de echo niet te vaak Leeg?** (R12, R-V3) | MP-4; Leeg-redenen uit het log | ≤ 40 % |
| 4 | **Ligt de springplank niet steeds achter je?** (R-V12) | MP-3, en waar de landingen gebeuren (B1, B2, B3, K2) | ≥ 75 % zonder stilstand; elke bouwsteen levert landingen op |
| 5 | **Leest het merk als *Nine Sols*?** (R-V9, ideecheck §2) | Na de run, **vóór** we iets over het merk zeggen: *"Waar deed het merk je aan denken?"* (open vraag). Telt: spontaan "*Nine Sols*", "talisman" of dezelfde lading-en-ontploffing | Niemand noemt het spontaan; anders terug naar afwijkpunt 2 (§2.13) |
| 6 | **Is de merksprong leesbaar?** | Na een ontploffing of een gemiste ontploffing: *"Waarom knalde dat merk (niet)?"* Juiste uitleg (de echo kwam langs / het merk was te ver of gedoofd) telt als begrepen | ≥ 80 % juist |
| 7 | **Wacht in co-op iemand, of gaat het te snel?** (R10, R-V5) | MP-7 (runtijd co-op tegenover solo, stilstand per speler, samenwerkingsacties per speler, tijd dat P2 opgelost is); na de co-op-run aan elke speler: *"Heb je op de ander moeten wachten?"* (ja/nee) | MP-7 gehaald; niemand antwoordt "ja" over meer dan één kamer |
| 8 | **Worden de vier acties gebruikt, solo en co-op?** (pillar 3) | Aantal bounces, lanceringen, vangen en merk-combo's per run en per modus (meetlog); na de run: *"Voelde je echo / je partner als hulp of als last?"* (1–5) | Bounce en merk-combo elk ≥ 1× per minuut in beide modi; lancering ≥ 1× per co-op-run in B4; vangen alleen rapporteren (O-11); hulp gemiddeld ≥ 4 |

---

## 6. Antwoorden op de vragen uit #6 en `ontwerp.md` §11

*Historisch (v0.2).* In v0.4 wijzigen: vraag 1 (staart van D ≈ 2 s, E-02; één afwijking, de merksprong, E-02m), vraag 2 (op je echo staan breekt hem niet meer, E-08b) en vraag 4 (co-op: sinds v0.4 is P2 de partner in dezelfde rol als de echo, niet meer een overname van de echo; drop-in en drop-out blijven zoals hieronder, met D in plaats van 10 s, §2.7).

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
| 0.3 | Echo-regels v0.4 en flow-kamer (T3a, [#67](https://github.com/cesarvangerwen-glitch/echoborn/issues/67)), volgens pitch v0.4 en besluit #51 (1A, 8A). Nieuw of herzien: E-02 (staart D = 120 ticks, testwaarden 90 / 120 / 180, recorder 600 frames), **E-02m merksprong**, E-04 en **E-04a** (de echo volgt je door de deur, toestand Buiten; O-5 gesloten), **E-07a springplank** (vaart houden, dash terug, bounce), **E-08b** (steun op een schaduwlichaam breekt de echo niet), **E-14 schaduwmerk** met de afwijkpunten 1–6 van de ideecheck (§2.13), DASH-bit en minimale beweging (§2.5a), **lichtmeter met één gemaal** (§2.12, LM-01–LM-06). Testkamers T1–T5 en V1 → **flow-kamer** (§4: sprongketen, merk-arena, gemaal; bouwstenen, FK-regels, waarden voor de flownormen MP-1–MP-6, meetlog) met tests per regel (§4.6). Vervallen: tweeslagschild, lampbrug, L-01, L-04, L-05, L-07; L-03 herzien. Playtestvragen → flow-test (§5). C-regels ongewijzigd tot T3b (#75). Herzien na de Lead-review van de EP: geen LP voor treffers op een intact pantser (LM-02) en stilstand gemeten op verplaatsing (MP-1, MP-3); bouwstenen B1–B3 nagerekend en per D werkend (B3 per D), basisvijand 0,25 px/tick en 30 ticks stil (§4.3); ontploffing op een intact pantser doet 0 SE op het lichaam (E-14g); bovengrens gemaal zonder echo (FK-2); O-9 en O-10. |
| 0.4 | Co-op 7A (T3b, [#75](https://github.com/cesarvangerwen-glitch/echoborn/issues/75)), volgens besluit #51 (7A, 8A) en pitch v0.4 (P3, §5). §2.7 herschreven: één rol voor het tweede lichaam (solo de echo, co-op de partner); C-01 (max. twee lichamen, de gedeelde echo is geen lichaam), C-02 (P2 slaat, merkt en pompt, 10 SE; geen merksprong), C-03 (drop-in neemt de echo over, ook tijdens een merksprong en met P1 op de plank), C-04 (opname in co-op met D, finisherlog), C-05 (drop-out met D, merken van P2 blijven) herzien; C-06 en C-07 ongewijzigd, C-08 met D. Nieuw: **C-09** drager, springer, lichtplank (laag 8) en ladderregel, **C-10** bounce in beide richtingen, **C-11** lancering met houding, **C-12** merk-combo (de ontsteker is het andere lichaam), **C-13** vangen, **C-14** gedeelde echo als finisher (laatste 600 ticks, ×5), **C-15** optioneel op de route, **C-16** verplicht bij bosses. Aangepast: E-01 (`aanval_vast`), E-05 (laag 8), E-07a (5), E-07b, E-14a/c, LM-01–LM-03, §2.9, §2.13 punt 1, bouwsteen **B4 lanceerkloof** (§4.3), MP-2, MP-6, **MP-7** en meetlog (§4.5), tests C-01–C-16 (§4.6), §5 vragen 7 en 8, O-11–O-13. Werktitel *Polderlight* (besluit #96, [#37](https://github.com/cesarvangerwen-glitch/echoborn/issues/37)). |
