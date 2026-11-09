# De Gemaalmeester (boss van de slice)

Versie 0.1.1 (GDD v1, deel 2) · Eigenaar: Lead Game Designer (ontwerp); detailuitwerking met vijanden, schade en timing: Combat Designer in **T8b** · Issue [#81](https://github.com/cesarvangerwen-glitch/echoborn/issues/81) (T3c), `docs/productie/fase-2-kader.md` §2 (T8b, F3, R-V4)
Hoort bij `docs/design/gdd.md` v0.6.1 (C-14 finisher, C-16 verplicht bij bosses, E-14 merk, V-01 Neerslag, O-1) en `docs/design/wereld.md` §2 (slice, kamer S8). Verhaal en toon: `docs/narrative/verhaal-v2.md` §6.

**Werkaanname** (kader §5): CEO-besluiten #2 (PEGI 12, 4–5 bosses van 8–12 min), #51 deel 2 (1A: bosses gebouwd om samen of met je echo te winnen, geen puzzel; 7A: samenwerken verplicht bij bosses, gedeelde echo alleen als finisher; 8A: de finisher speelt jullie laatste 10 s af), pitch v0.4 §4 P1 (**≤ ± 5 s stilstand**, vensters **≥ 10 frames**, duidelijke feedback), fasekader v0.2 (T8b: max. 4 vijandtypes, R-V4). **Werkaanname LGD:** alle getallen hier zijn **startwaarden van vóór F0**; de Combat Designer zet ze in T8b en stelt ze bij met de scripted run en T11. D = 120 tot F0; waar een maat van D afhangt, moet hij voor D = 90, 120 en 180 werken.

---

## 1. Doel

De eerste boss laat de speler voelen wat de echo in een gevecht is: **je tweede slag** (fase 1: alleen een merk-ontploffing breekt zijn schot) en **je springplank** (fase 2: zijn zwakke plek, het grote rad, haal je alleen met een bounce, lancering of vang), en sluit af met de finisher die **jullie laatste 10 s** afspeelt. Alles in beweging (pillar 1), solo en co-op in dezelfde arena (pillar 3), en na de boss gaat de wijk aan (pillar 2). Verhaal: een gemaal dat alleen nog herhaalt, en dat zich herinnert hoe samenwerken was (`verhaal-v2.md` §6).

**Toetsvraag pillar 1:** maakt elk verplicht moment het gevecht vloeiender of krachtiger, zonder stilstand? **Puzzeltoets** (pitch §4): je doet elk moment in beweging tijdens het gevecht, je hoeft niet stil te staan om een oplossing te bedenken.

## 2. Arena en lichaam

| ID | Regel |
|---|---|
| **GM-01** | **Arena (S8, de machinehal).** Eén scherm (640 × 360 px) met een **vlakke vloer van ± 600 px** tussen twee muren; geen richels of galerijen (anders is de zwakke plek zonder echo te halen, GM-06). Sluit bij `BOSS_START`, opent bij `BOSS_VERSLAGEN` (L-13a). Aan elke kant van de Gemaalmeester ligt **≥ D + 24 px** vlakke vloer (204 px bij D = 180), zodat keren je echo tegemoet brengt (gdd §4.3, L-13b). Gedeelde camera in co-op (C-07). Geen `Diepwater`, `FelLicht` of `Schaduwgevaar` in de arena. |
| **GM-02** | **Het lichaam.** Een grote poldermachine in het midden van de arena, ± 96 px breed en ± 160 px hoog, die **niet loopt** (hij staat op zijn fundament); hij draait zich niet om. Delen: **drijfstang** (arm voor de pompslag), **schoepen**, **ketel** met een **schot** (pantser) ervoor, en bovenin het **grote rad** (zwakke plek; in het verhaal het pomprad waar Ward en de leerling samen aan draaiden). Het grote rad is een deel van de boss, **geen** `Pomprad` uit LM-03: een treffer erop doet schade en geeft licht als een treffer op een vijand (LM-02), en pompt niets. Het lichaam doet **geen contactschade**: alleen zijn aanvalsvlakken raken P1 (zo kun je bij hem bouncen). Hij doet de echo en P2 nooit iets (E-14h, O-1). |
| **GM-03** | **Levens en fasen** (startwaarden). **400 SE** solo; co-op startwaarde **600 SE** (×1,5), bij te stellen met MP-7 (O-13). **Fase 1** van 100 % tot 60 %, **fase 2** van 60 % tot 20 %, **Wankel** op ≤ 20 % (de finisherdrempel van C-14a). Een fasewissel duurt 60 ticks (stoom, geluid; hij valt dan niet aan, P1 blijft bestuurbaar). |

## 3. Aanvallen

| ID | Regel |
|---|---|
| **GM-04** | **Het ritme.** Hij slaat op een vaste maat, die van het carillon: in fase 1 elke **120 ticks** een aanval, in fase 2 elke **90 ticks**. Elke aanval heeft een **aanloop van ≥ 30 ticks** met beeld en geluid (stoom, licht in de ketel, een piepende as); de **allereerste** aanval heeft 60 ticks: hij aarzelt als hij de sjaal van de machinist ziet (`verhaal-v2.md` §6). De maat laat de speler het ritme leren en erin bewegen (geen stilstand nodig om te ontwijken). Audio: T8d. |
| **GM-05** | **Aanvallen** (ontwerp; patronen en schade: Combat Designer). (a) **Pompslag** (fase 1 en 2): de drijfstang slaat op de linker- of rechterhelft van de vloer, een vlak van ± 160 × 24 px, 6 ticks; ontwijk door weg te lopen of erover te springen. (b) **Schoepenzwiep** (alleen fase 2): de schoepen vegen over één helft op 40–64 px hoogte, 8 ticks; ontwijk door op de vloer te blijven of erboven te zijn (op je echo of partner). (c) **Spuigaten** (alleen fase 1): als het schot weer dichtgaat (GM-06), komen er max. **2 Kadelopers** uit; nooit meer dan 2 tegelijk. Ze geven licht (genezen, LM-07) en zijn materiaal voor een ketting naar het schot (E-14d, binnen 48 px). Elke treffer van de boss kost P1 **1 levenspunt** (startwaarde). |

## 4. De verplichte momenten

| ID | Regel |
|---|---|
| **GM-06** | **Fase 1: het schot (je tweede slag; C-16b).** De ketel zit achter een **schot**: een pantser volgens E-14g, `Merkbaar`, met zijn merkplek op **24–48 px** boven de vloer (met een gewone aanval te raken, en binnen R = 80 px van de looproute op de vloer, zodat de merksprong het haalt; C-16d). Alleen een **merk-ontploffing** breekt het: solo zet P1 het merk en laat de echo het knallen (merksprong, E-02m); co-op zet de een het merk en laat de ander het knallen (C-12). Een gewone treffer op het intacte schot doet 0 SE en geeft 0 LP (LM-02). **Gebroken schot:** de **kern** ligt **300 ticks** open en neemt gewone schade; dan schuift er een nieuw schot voor (en komen er adds, GM-05c). Zo vaak als nodig tot 60 %. |
| **GM-07** | **Fase 2: het grote rad (je springplank; C-16b, O-1).** Het schot gaat dicht en blijft dicht; de kern is niet meer te raken en het lichaam heeft geen hurtbox behalve het **grote rad**. Het grote rad (hurtbox ± 96 × 40 px) hangt aan een arm **boven één helft van de vloer**, met de onderkant op **100 px** en de bovenkant op **140 px** boven de vloer: met een sprong (aanvalsvlak tot ± 73 px) niet te raken, met een **bounce** (lichaam tot ± 130 px), **lancering** of **vang** wel. Zo rekent deze fase op **waar je echo straks is** (O-1). **Plek in D:** na keren tegen een muur ontmoet je je echo op **D px** van die muur, en de bounce drijft tot **68 px** verder (gdd §4.3): je bent boven de vloer op `D … D + 68` px van de muur. Daarom hangt het middelpunt van het rad op **`x_rad = D + 34` px van de muur** aan zijn kant, met de hurtbox op `D − 14 … D + 82` px (14 px marge aan elke kant): **124 / 154 / 214 px** bij D = 90 / 120 / 180. Het debugmenu zet de plek bij een wissel van D (zoals B3 in §4.3, SL-05). Bij D = 180 loopt de hurtbox tot 262 px en hangt hij dus 10 px boven de rand van het lichaam van de boss (± 252–348 px in een arena van 600 px); dat mag, want het lichaam heeft in fase 2 geen hurtbox en geen contactschade (GM-02). De Combat Designer rekent het na met de scripted run per D (T8b). **Wegdraaien:** na **3 treffers** of **180 ticks** draait de arm het rad in 60 ticks naar de andere helft, op `x_rad = D + 34` px van de **andere** muur. Elke treffer **10 SE**. Een **neerslag** op het rad is een stuit (V-01b: het rad is een deel van een vijand): wie er eenmaal is, kan tot 3 slagen achter elkaar maken zonder te landen, de beloning van de vaardigheid van dit gebied. |
| **GM-08** | **Wankel en de finisher (C-14, C-16a).** Op ≤ 20 % is hij **Wankel**: hij hapert en staat stil, voor het eerst sinds de laatste avond, valt niet aan, geen tijdslimiet. Een merkplek op de ketel (24–48 px, zoals GM-06) laat zich merken; de eerste merk-ontploffing (solo de echo, co-op de ander) start de finisher (C-14b): de gedeelde echo speelt jullie laatste 600 ticks af in 120 ticks, en op `t_f + 120` is hij verslagen. Mislukt nooit (C-14d). |
| **GM-09** | **Vensters en stilstand** (pitch §4 P1, C-16c). Elk verplicht moment heeft een venster **≥ 10 ticks**, en ruim meer: een merk leeft D + 30 ticks (E-14), dus ≥ 120 ticks om het schot te laten knallen, kern 300 ticks, grote rad 180 ticks per kant, de lanceersprong 19 ticks (gdd §4.3, B4), Wankel zonder limiet. Elke verplichte actie geeft feedback in **geluid, schermschok en licht** (UX, Art, Audio). De scripted geoefende run haalt **MP-1 ≤ 300 ticks** stilstand per D in beide modi; de langste verwachte wacht is de solo-lancering bij D = 180 (159 ticks, B4), en een bounce vraagt geen wachten. |

## 5. Na de boss

| ID | Regel |
|---|---|
| **GM-10** | **Wat hij vasthield.** Op `BOSS_VERSLAGEN` lost de Gemaalmeester op in licht (toonregel G-1) en staat het gewone gemaal er, stil, met de deur open. De lichtmeter gaat naar **100 LP**: het licht dat hij vasthield. Zo is trap 2 meteen te pompen (`wereld.md` SL-02, LM-09b) en loopt de slice nooit vast. De echo neemt de rand van Wards hoed over (beeld, `verhaal-v2.md` §3.2). |
| **GM-11** | **Opnieuw proberen.** Bij 0 levenspunten respawnt P1 bij het gemaal (LM-08); de boss begint opnieuw op 100 % in fase 1, adds weg, meter blijft (LM-01). Van het gemaal tot de arena-deur is ≤ 10 s lopen (`wereld.md` SL-03). |

## 6. Solo en co-op

| Moment | Solo (echo) | Co-op (partner) |
|---|---|---|
| Schot breken (GM-06) | P1 merkt, de echo knalt het met de merksprong D ticks later | De een merkt, de ander knalt het met een gewone treffer (C-12) |
| Grote rad halen (GM-07) | Keren tegen de muur, op je echo springen (bounce); of de lanceerhouding (C-11, B4); of een vang | Bounce op elkaar, lancering, vang; P2 kan zelf ook op P1 bouncen en het rad raken (C-02: 10 SE) |
| Finisher (GM-08) | Merk, de echo knalt; de gedeelde echo speelt jou en je echo af | Merk, de ander knalt; de gedeelde echo speelt jullie twee af |
| Drop-in/drop-out | P2 neemt de echo over (C-03) | Valt P2 uit, dan neemt de echo het over (C-05); geen moment vraagt twee live spelers (C-16e) |

Eén arena, geen aparte versie (C-16c). Co-op mag hooguit 2× zo snel zijn als solo (MP-7); haalt het dat niet, dan eerst de co-op-SE bijstellen (O-13).

## 7. Wat de Combat Designer in T8b uitwerkt

- Schade, levens en de co-op-schaal (GM-03, GM-05), het precieze patroon van de aanvallen binnen het ritme van GM-04, en wat donker met de adds doet (O-18).
- De baan van het grote rad tussen de twee plekken van GM-07 (`x_rad = D + 34` px van elke muur), nagerekend per D; de merkplekken (GM-06, GM-08, C-16d).
- Of pareren of een aanval omhoog erbij komt (O-17); zo ja, nooit een merk (E-14f).
- O-20 (snijlijn en onraakbaarheid) speelt hier nog niet: V-02 zit niet in de slice.
- De tests volgens de C-16-test (gdd §4.6): solo met de echo uit en co-op met een P2 die nooit slaat is hij **niet** te verslaan; solo met echo en co-op wel. Met de animator: aanloop en feedback van elke aanval.

**Acceptatie (checklist T8b, review LGD):**
- [ ] Twee verplichte momenten met een samenwerkingsactie (schot, grote rad) en de finisher, elk solo én co-op in dezelfde arena.
- [ ] Elk venster ≥ 10 ticks, elke aanval ≥ 30 ticks aanloop; scripted geoefende run: MP-1 ≤ 300 ticks per D, solo en co-op.
- [ ] Het grote rad is niet te raken zonder bounce, lancering of vang (test: sprong + aanval op elke plek van de vloer raakt het niet); met bounce wel, voor D = 90, 120 en 180.
- [ ] Geen contactschade; de echo en P2 krijgen nooit iets.
- [ ] Adds alleen Kadelopers, max. 2 tegelijk; samen met de slice max. 4 vijandtypes (R-V4).
- [ ] Geoefende run 150–240 s; eerste speler 8–12 min inclusief pogingen (T11).

## 8. Playtestvragen (T11)

| # | Vraag | Hoe we het meten | Goed als |
|---|---|---|---|
| GM-a | Snappen spelers zonder tekst dat het schot een merk-ontploffing vraagt? | Tijd van `BOSS_START` tot de eerste gebroken schot; open vraag na de run | ≤ 60 s bij de CEO, in beide modi |
| GM-b | Gebruiken spelers hun echo of partner als springplank in het gevecht? | Bounces, lanceringen en vangen per minuut in fase 2 | ≥ 2 per minuut, in beide modi |
| GM-c | Voelt de finisher als "onze laatste 10 s", of als een tussenfilm? | Open vraag op de kaart van F4b(a): *"Wat zag je bij de finisher?"* | De CEO noemt zijn eigen beweging of die van de echo/partner |
| GM-d | Staat iemand stil? | MP-1 en MP-7(b) per fase | Langste stilstand ≤ 300 ticks per speler |

## 9. Wijzigingen

| Versie | Wat |
|---|---|
| 0.1.1 | Herstel na de Lead-review van de EP (PR #123): plek van het grote rad als formule in D (GM-07, `x_rad = D + 34` px van de muur). |
| 0.1 | Eerste versie (GDD v1, deel 2; T3c, [#81](https://github.com/cesarvangerwen-glitch/echoborn/issues/81)): arena, lichaam en fasen (GM-01–GM-03), ritme en aanvallen (GM-04, GM-05), verplichte momenten schot en grote rad, Wankel en finisher (GM-06–GM-09), na de boss (GM-10, GM-11), solo en co-op, werk voor T8b, playtestvragen. |
