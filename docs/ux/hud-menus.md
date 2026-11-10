# UX-spec HUD en menu's *Polderlight*

Versie 0.1 · Eigenaar: UX Designer (met de UI Artist voor de eind-art) · Issue [#87](https://github.com/cesarvangerwen-glitch/echoborn/issues/87) (T10, `docs/productie/fase-2-kader.md` §2) · Review: Lead Game Designer
Co-op, drop-in/drop-out en de gedeelde camera: **`docs/ux/coop.md`**. Wireframes: **`docs/ux/wireframes/`** (bron: `bron/genereer_wireframes.py`, draait vanaf de repo-root en print de metingen van §2.3).

Bronnen: `docs/design/gdd.md` v0.6.2 (§2.5–2.9, §2.12, O-2), `kernloop.md` §4, `wereld.md` §2.5 (rij T10) en WS-08, `gemaalmeester.md` GM-03/GM-08, `docs/art/bible.md` §2, §3, §5–7, `docs/audio/bible.md` §6.1, `docs/tech/input.md`, `docs/tech/ontwerp.md` §8a, `docs/tech/performance-flowkamer.md` §7 (punt 14, 15), pitch v0.4 (P2: "zichtbaar zonder icoon of uitleg").

## 0. Werkaannames (kader §5)

| # | Aanname | Bron |
|---|---|---|
| W1 | Staart **D = 120 ticks** (± 2 s), testbereik 90–180. De merk-aftelling (§3.5) en het echo-icoon (§3.4) rekenen met D en kloppen voor elke D in dat bereik. | besluit #51 (8A), gdd E-02 |
| W2 | Merk leeft **D + 30 ticks**, de laatste 60 tellen af in 4 slagen van 15 ticks; de echo valt op slag 3. | gdd E-14b, audio bible §6.1 |
| W3 | Lichtmeter **0–100 LP**, een pompslag pompt 10 LP, genezen kost 30 LP; levenspunten 5, max. 9 met lampglas. | gdd LM-01–LM-08, WS-08 |
| W4 | Max. **twee lichamen**; in co-op geen echo, de partner ís de echo; één gedeelde meter. | besluit #51 (7A), gdd C-01–C-07 |
| W5 | Interne resolutie **640×360** (pc) en **640×400** (Steam Deck), alleen integer schalen. | besluit #18, art bible §2 |
| W6 | Talen **EN** (bron) en **NL** bij release ("in principe ja"); de infrastructuur is er (T14). | besluit #51 deel 1 (5A), `ontwerp.md` §8a |
| W7 | **F0 is nog niet gehaald**: deze spec is de versie vóór F0. De HUD wordt na F0 bijgesteld (kader, open punt bij T10). Getallen van de UX Designer (§6, `coop.md` §5) zijn startwaarden. | fasekader fase 2 v0.2 |
| W8 | Tekst in de wireframes staat in het 5×7-pixelfont van de Art Director (alleen hoofdletters). Het echte lettertype kiest de UI Artist, met licentie in `docs/licenties.md`. | `docs/art/stijltests/bron/pixelfont.py` |

## 1. Principes

1. **De wereld eerst.** Wat in de wereld te zien is, krijgt geen HUD-element: de laag (pitch P2), de waterstand, de stand van het gemaal, de echo zelf en het merk. De HUD toont alleen wat je **niet** in de wereld kunt zien: je licht, je levens, wanneer je echo terugkomt en waar je partner is.
2. **Lezen zonder stilstand** (pillar 1). Niets in de HUD of in een melding pauzeert het spel, behalve het pauzemenu. Een logbladzijde lees je lopend (WS-08).
3. **Kleur zegt van wie, vorm zegt wat** (art bible §6 regel 1). Amber = speler 1 en zijn echo, cyaan = speler 2. Elk verschil dat ertoe doet, zit ook in vorm of waarde, zodat het in grijs en bij deuteranopie blijft werken (§2.3).
4. **Elk geluid heeft een beeld, en andersom.** De carillon-aftelling heeft de klokring (§3.5); de breek-klank heeft het breek-icoon. Wie zonder geluid speelt, mist niets (§5).
5. **Deck eerst.** We ontwerpen op 640×400 op een scherm van 7 inch; pc is dan vanzelf goed (§2).
6. **Klein en in de hoek.** De vaste HUD bedekt ± 1,5 % van het beeld solo en ± 1,9 % in co-op (gemeten, §2.3).

## 2. Maten en leesbaarheid

### 2.1 Plaats en veilige zone

| ID | Regel |
|---|---|
| **HUD-M1** | Alles van de HUD hangt aan een **schermrand** met een marge van **8 px** (intern), niet aan het 16:9-beeld. Op de Deck (640×400) staat de HUD dus 20 px hoger en lager dan op pc, in de **16:10-band** waar niets speelbaars staat (art bible §2). Zo bedekt de HUD op de Deck nog minder speelruimte. Wireframe: `hud_deck_640x400_placeholder.png`. |
| **HUD-M2** | **De 16:10-band wordt niet gedimd** (antwoord op `performance-flowkamer.md` §7, punt 14). Dimmen voelt als een letterbox en neemt de Deck-speler zijn extra zicht af. De leiband blijft 16:9 (besluit TD); de band is alleen extra zicht. |
| **HUD-M3** | Hoeken: **linksboven** = P1 (levens, lichtmeter, echo). **Rechtsboven** = P2 (alleen in co-op). **Onder in het midden** = logbladzijde en boss-balk. **Rechtsonder** = meldingen (lampglas, controller, opslaan). Het midden blijft vrij. |
| **HUD-M4** | Geen HUD-element mag de bovenste 8 of onderste 8 px raken (overscan op tv, ronde hoeken van sommige schermen). |

### 2.2 Minimale maten (op de interne resolutie)

Op de Deck is 1 interne pixel ± 0,24 mm (art bible §2: speler 1 is 29 px ≈ 6,8 mm).

| Wat | Minimum | Op de Deck (1280×800) | Waarom |
|---|---|---|---|
| Teksthoogte (hoofdletter) HUD en meldingen | **7 px** | 14 fysieke px, ± 1,7 mm | Boven Valves Deck-richtlijn (± 9 px op 1280×800; nog te verifiëren door de Engine & Platform Programmer bij de Deck-build). |
| Teksthoogte menu's | 7 px, titels 14 px | 14 / 28 px | idem; optie *Tekstgrootte: groot* maakt menutekst en logbladzijden 1,5× (§5). |
| Icoon (lampje, echo, badge) | **9 px** hoog, echo-icoon 17 px | ≥ 18 px | Een vorm onder 9 px leest op de Deck als een stip. |
| Lijn die een toestand draagt (ring, rand) | **2 px** | 4 px | 1 px flikkert bij beweging en scaling (art bible §7.4). |
| Contrast HUD-element tegen zijn plaat | **ΔL\* ≥ 40** | | Dezelfde regel als de figuren (art bible §6 regel 4). |

### 2.3 Grijs en kleur: wat er gemeten is

De HUD hangt op een **CanvasLayer** en doet **niet** mee met de saturatiepass van de wijk: hij is in de grijze en de gekleurde toestand gelijk. De vulling van de lichtmeter komt uit de ramp *gloed*, die volgens de art bible in elke toestand haar kleur houdt (§3): de meter is dus het warme licht dat je draagt, ook in een grijze wijk. Achter de HUD ligt een **plaat** (lucht tint 1 `#0c0c1d`, 62 % dekkend), zodat lichte achtergronden (sterren, verlichte ramen, lichtgeometrie) de HUD nooit opslokken.

Gemeten met `genereer_wireframes.py` op de R5-scène (ΔE76 in CIELAB, deuteranopie volgens Machado 2009, zoals de art bible):

| Meting | Grijs | Kleur |
|---|---:|---:|
| L\* van de achtergrond in de HUD-zone, mediaan / p95 / max | 2,4 / 6,9 / 23,4 | 1,8 / 16,5 / 89,0 |
| idem, met de plaat erachter: p95 / max | 4,9 / 11,0 | 7,8 / 39,4 |

| Paar | ΔE normaal | ΔE deuteranopie | ΔL\* | Regel (bible §7.1) |
|---|---:|---:|---:|---|
| Meter: vulling (gloed 5) / leeg segment | 105,9 | 108,3 | 69,7 | ja |
| Rand van de meter (gevel wit 6) / contour | | | 77,0 | ja |
| Echo-icoon amber / plaat | 105,5 | 105,5 | 67,1 | ja |
| P2-badge cyaan / plaat | 90,4 | 78,6 | 80,2 | ja |
| Merk amber (P1) / merk cyaan (P2) | 107,7 | 91,9 | 13,1 | ja; ook de **vorm** verschilt (§3.5) |
| Merkring amber (gloed 6) / rode vijandkern | 73,6 | 26,5 | 30,4 | ja (≥ 25 en ΔL\* ≥ 20) |
| Merkkern amber / rode vijandkern | 60,0 | 32,4 | 12,4 | ja; plus contour van 1 px bijna-zwart |
| Merkkern cyaan / schaduwgeometrie 3 | 94,9 | 67,2 | 69,7 | ja |

**Grenspunt:** het helderste pixel achter de HUD met plaat (L\* 39,4, een ster) ligt 39,4 onder de rand van de meter: net onder de 40. Het is één pixel; de p95 ligt op 7,8. Geen actie, wel een meetpunt voor de UI Artist (§7).

Wireframes: `hud_solo_grijs_kleur_640x360_placeholder.png` (beide toestanden, ware grootte), `merk_aftelling_x4_placeholder.png` (normaal, alleen luminantie, deuteranopie).

## 3. HUD solo

Wireframes: `hud_solo_annotaties_x2_placeholder.png` (nummers = kolom *Nr*), `hud_elementen_x4_placeholder.png` (alle toestanden).

| Nr | ID | Element | Waar | Toont | Zichtbaar |
|---|---|---|---|---|---|
| 1 | HUD-01 | Levenspunten | linksboven, rij 1 | 5–9 lantaarntjes (7×9 px), vol of leeg | altijd (optie *HUD: automatisch*, §5) |
| 2 | HUD-02 | Lichtmeter | linksboven, rij 2 | `L` in 10 segmenten van 10 LP | altijd |
| 3 | HUD-03 | Genees-streep | onder de meter bij 30 LP | "genoeg licht om te genezen" | altijd, samen met de meter |
| 4 | HUD-04 | Echo-icoon | naast de levens | toestand van de echo (§3.4) | solo; in co-op vervangen door de P2-badge |
| 5 | HUD-05 | Merk + klokring | **in de wereld**, op het object | aftelling van het merk (§3.5) | zolang het merk leeft |
| 6 | HUD-06 | Gemaalstand | **in de wereld**, naast het pomprad | `G` en de trappen (§3.6) | binnen 96 px van het gemaal, en 3 s na een pompslag |
| 7 | HUD-07 | Logbladzijde | onder in het midden | 2 regels lore (§3.7) | 6 s na het oppakken |
| 8 | HUD-08 | Melding | rechtsonder | lampglas, controller, opslaan | 3 s (controller: 5 s) |
| — | HUD-09 | Boss-balk | onder in het midden | levens van de boss met fasestrepen (§3.8) | van `BOSS_START` tot `BOSS_VERSLAGEN` |

### 3.1 Lichtmeter (HUD-02, HUD-03)

- **Vorm:** een buis van 84×9 px met **10 segmenten**. Eén segment = 10 LP = **één pompslag** (LM-03). Zo leest de speler "ik kan nog 7 keer pompen" zonder getal. Geen getal in de HUD; het getal staat in het pauzescherm en in de debug-HUD.
- **Vullen:** het segment vult van links naar rechts in de ramp *gloed* (tint 6 boven, 5 midden, 3 onder). Bij elke bron (LM-02) een **vonk** van 4 px op het segment dat vult, in de kleur van wie het licht verdiende (amber P1 en echo, cyaan P2). Een schakel van een merk-ketting (+6) geeft één vonk per schakel, zodat een ketting zichtbaar "ratelt".
- **Vol (100):** de meter knippert één keer wit (tint 7) en blijft vol. Teveel gaat verloren (LM-01): geen extra effect, wel een zachte "vol"-tik van audio (vraag aan de Audio Director, §7).
- **Pompen:** bij elke slag op het pomprad loopt één segment leeg naar rechts weg, en de gemaalstand (HUD-06) stijgt even veel: de speler ziet het licht van de meter in het gemaal stromen.
- **Genees-streep (HUD-03):** een streepje van 1×3 px onder de grens bij 30 LP. Boven de streep kun je genezen, eronder niet.

### 3.2 Genezen (LM-07): vasthouden zonder stilstand

- **Knop:** INTERACTIE vasthouden, 45 ticks, staand of lopend, zonder interactief object binnen bereik (LM-07). Het rebindscherm noemt hem *Interactie (genezen)*.
- **Tijdens het vasthouden** licht het deel van de meter op dat het genezen kost (30 LP vanaf de top, met een kader van tint 7) en loopt het in 45 ticks leeg van rechts naar links. Op tick 45 springt er een vonk van de meter naar het eerste lege lantaarntje, dat aangaat. Bij P1 zelf: een warme gloed rond de sjaal (art, Animator), geen stilstaande animatie.
- **Afbreken** (sprong, dash, AANVAL, treffer, loslaten): het kader verdwijnt, de meter staat weer zoals hij was. Geen straf, geen geluid behalve een korte "uit".
- **Te weinig licht** (`L < 30`) of **levens vol:** de eerste 3 segmenten krijgen 20 ticks een donker kader en de genees-klank klinkt gedempt. Niets gaat af. Zo leert de speler de streep zonder tekst.
- **Toegankelijkheid:** met *Vasthouden of tikken: tikken* (§5) start één druk het genezen; het loopt 45 ticks door en breekt af zoals hierboven, of bij een tweede druk.

### 3.3 Levenspunten en lampglas (HUD-01)

- Een rij lantaarntjes van 7×9 px, 2 px tussenruimte; 5 bij de start, tot 9 (WS-08). Vol = gloed, leeg = alleen een donkere rand.
- **Treffer:** het rechtse volle lampje dooft met een knipper van 6 ticks en een korte schermschok (instelbaar, §5).
- **Lampglas oppakken:** een nieuw lampje schuift rechts aan de rij met een glinstering, alle lampjes gaan aan (WS-08: vult aan), en rechtsonder staat 3 s de melding *Lampglas: +1 leven* (`HUD_LAMPGLAS`). Geen pauze.
- **0 levens:** respawn bij het laatste gemaal (LM-08). Geen *Game over*-scherm: een overgang naar zwart van ± 0,5 s en weer in beeld. Het licht in de meter blijft (LM-01, LM-09d), en dat ziet de speler meteen.
- **In co-op** heeft P2 geen levens (C-02): de rij blijft van P1.

### 3.4 De echo (HUD-04): antwoord op O-2

De echo leest **in de wereld** (art bible §5–6: hol, amber rand, nabeelden). De HUD voegt alleen toe wat in de wereld onzichtbaar is: **wanneer hij terugkomt**.

| Toestand (kernloop §4) | In de wereld | Echo-icoon (11×17 px) |
|---|---|---|
| **Actief** | holle figuur met amber rand, 2 nabeelden | vol amber silhouet met arcering |
| **Actief, dragend** | de bovenrand van zijn **schaduwplank** licht op (1 px, schaduwgeometrie tint 6) waar hij draagt | gelijk aan *Actief* |
| **Actief, zwevend** (E-08b) | geen plankrand: de speler ziet dat hij hier niet draagt | gelijk aan *Actief* |
| **Leeg** (na reset, loslaten, start) | niets | gestippeld silhouet dat van onder naar boven **vult** in de ticks tot hij terug is (`t − D ≥ geldig_vanaf`) |
| **Breken** (E-08) | breek-effect op de plek (Animator) + breek-klank | 12 ticks versplinterd, dan *Leeg* |
| **Buiten** (E-04a: frame `p` in een kamer die niet geladen is) | niets in deze kamer | silhouet vult zoals *Leeg*, met een pijltje: hij komt door de deur |
| **Merksprong** (E-02m) | korte streep van de echo naar het merk en terug (12 ticks), amber | gelijk aan *Actief* |
| **Uit** (debug F4) | — | grijs silhouet |

Waarom een icoon en geen balk: een silhouet herhaalt de vorm van de echo, zodat het zonder uitleg leest. Waarom het vult: zo weet de speler na een breuk of loslaten (E-09) wanneer zijn springplank er weer is, zonder te tellen.

### 3.5 Merk-aftelling (HUD-05): de klokring

Het merk zit **op het object**, niet in de HUD. Het moet in één blik zeggen: van wie het is, hoe lang nog, en wanneer de echo komt.

- **Kern** (E-14i: lichtvonk in de vorm van een peil- of sluismerk): **P1 = rond peilmerk met een horizontale waterlijn**, amber; **P2 = ruit (sluismerk) met een verticale streep**, cyaan. De vorm verschilt, zodat de zetter ook in grijs en bij kleurenblindheid te lezen is. Waarom dat telt: in co-op ontsteekt alleen het **andere** lichaam (C-12b). De kern is 7–8 px met een contour van 1 px bijna-zwart.
- **Klokring:** een ring van 2 px (doorsnede 17 px) rond de kern, in **4 kwarten**. Elke **carillonslag** (audio bible §6.1) **dooft één kwart**, met de klok mee vanaf boven. Beeld en geluid vallen op dezelfde tick.
  - gezet → 4 kwarten · slag 1 (D − 30) → 3 · slag 2 (D − 15) → 2 · **slag 3 (D): de echo komt en het merk knalt** (geen kwart meer nodig: de ontploffing neemt het over, zoals de grote klok in de audio).
  - Komt de echo niet: slag 3 → 1 kwart · slag 4 (D + 15) → 0 kwarten, de kern brandt nog (het merk kan in co-op nog knallen) · D + 30 → de kern dooft naar half licht en verdwijnt.
  - Zo leert de speler het ritme "één, twee, boem" met de ogen én de oren.
- **Vóór de aftelling** (de eerste D − 30 ticks) brandt de ring vol en stil.
- **Meerdere merken:** elk merk heeft zijn eigen ring. Het geluid telt er één af (audio bible §6.1); het beeld alle. Bij een ketting ontploffen de ringen één tick na elkaar (E-14d).
- **Toegankelijkheid:** *Merk-ring groter* (ring 25 px), *Aftelling ook trillen* (een korte puls per slag op de controller van de zetter, standaard aan), en *Geluidsbijschriften* toont geen tekst per slag (te druk) maar wel bij een ontploffing buiten beeld.
- Wireframe: `merk_aftelling_x4_placeholder.png` (alle 7 momenten, P1 en P2, normaal, alleen luminantie en deuteranopie).

### 3.6 Gemaal en waterstand (HUD-06)

- De stand van het gemaal staat **aan het gemaal**: een glazen peilbuis van 9×42 px naast het pomprad, met één streep per trap (LM-08). Hij vult met dezelfde gloed als de meter. Zo zie je ook van afstand hoe ver het gemaal is.
- De peilbuis verschijnt binnen 96 px van het gemaal en blijft 3 s na een pompslag. Een **volle trap**: de buis flitst, het water zakt (LM-06) en de wijk kleurt vanaf het gemaal (art bible §5). Geen tekst; de wereld vertelt het.
- **Trap 2 van een bosswijk** (G = 100 vóór `BOSS_VERSLAGEN`, LM-03): de bovenste helft van de buis staat achter een ijzeren klem (art). Pompen tegen een volle eerste trap geeft een doffe slag en vult niets; de meter loopt dan ook niet leeg.
- De **waterstand** heeft geen HUD: je ziet het water (pitch P2, leesbaarheidseis).

### 3.7 Logbladzijde (HUD-07)

- Oppakken = lopend erdoorheen (geen knop). Onder in het midden verschijnt een kader van 300×32 px: kop *Logbladzijde n* (`HUD_LOG_KOP`) en de tekst van max. 2 regels (`verhaal-v2.md` §4.4). Het spel loopt door.
- Het kader blijft **6 s** (bij *Tekstgrootte: groot* 8 s) en schuift weg bij een nieuwe bladzijde of in een gevecht met een boss. Alles wat je oppakte, staat in **Pauze → Logboek** (MN-15); niets is te missen.
- Een regel is max. 50 tekens in het Engels (NL ± 30 % langer, dus max. 65; §6). Langere tekst = twee bladzijden.

### 3.8 Boss-balk (HUD-09)

- **Waarom een balk:** de Gemaalmeester heeft fasen op 60 % en 20 % en een Wankel-moment op ≤ 20 % (GM-03, GM-08). Zonder balk ziet de speler niet hoe dicht de finisher is; dat kost bij een boss van 8–12 min (wereld §2.1) te veel spanning. Het is de enige plek waar we van "de wereld eerst" afwijken; de LGD mag dit terugdraaien (§7).
- **Vorm:** 240×4 px onder in het midden, met de naam erboven (`HUD_BOSS_GEMAALMEESTER`) en **fasestrepen op 60 % en 20 %**. Bij Wankel knippert de streep van 20 % in de kleur van gloed 6 en verschijnt de merkplek op de ketel (GM-08): de balk wijst, de wereld toont.
- In co-op gelijk; één balk.

### 3.9 Wat níét in de HUD komt

- Geen getal voor LP, G, schade of combo's (alleen in de debug-HUD van de flow-kamer).
- Geen minikaart in de slice. De wereldkaart (de kaart van de persbuis, WS-07, en de pauzekaart) is fase 3, samen met de World & Level Designer.
- Geen knop-prompts boven objecten, behalve bij de eerste keer (onboarding, aparte spec `docs/ux/onboarding.md`).
- Geen staartduur D in de HUD (de debug-HUD toont hem).

## 4. Menu's

Schermflow: `schermflow_placeholder.svg`. Alle menu's werken met controller, toetsenbord en muis; navigatie met d-pad/stick of pijltjes/WASD, **A/Spatie/Enter = kiezen**, **B/Esc = terug**. Een menu onthoudt de laatst gekozen regel.

### 4.1 Opstart en titelscherm

| ID | Regel |
|---|---|
| **MN-01** | **Taal bij de eerste start:** Steam-clienttaal, anders systeemtaal, anders Engels (`ontwerp.md` §8a). Geen taalscherm vooraf: één extra scherm vóór je kunt spelen, kost meer dan het oplevert. Wie wil wisselen, doet dat op het titelscherm (MN-03) of in Opties. |
| **MN-02** | **Titelscherm:** *Polderlight* op de grijze stad, met "druk op een knop" (`MENU_PRESS_ANY`). De eerste knop op welk apparaat ook maakt dat apparaat **P1** (`input.md` W3). |
| **MN-03** | Linksonder op titel- en hoofdmenu: **Y / △ / Tab = Taal: <taal>** (`MENU_LANGUAGE_HINT`), wisselt meteen tussen English en Nederlands. De taalnaam staat altijd in die taal zelf ("English", "Nederlands"). |

### 4.2 Hoofdmenu (`menu_hoofdmenu_x2_placeholder.png`)

| Nr | Regel | Gedrag |
|---|---|---|
| 1 | **Doorgaan** | Alleen als er een spelbestand is; laadt het laatst gespeelde, bij het laatste gemaal (LM-08, LM-12). Bovenaan en gekozen. |
| — | **Nieuw spel** | Naar *Spelbestand kiezen*: **3 plaatsen**, met per plaats wijk, licht, speeltijd en lampglas. Een bezette plaats overschrijven vraagt een bevestiging met **B als standaard** (`MENU_CONFIRM_OVERWRITE`). Opslag is van de TD (`ontwerp.md` §7). |
| — | **Opties** | §4.4 |
| — | **Credits** | scrollende lijst; B = terug |
| — | **Afsluiten** | Ook op de Deck (Valve staat het toe; de Steam-knop blijft werken). Geen bevestiging: er is niets om te verliezen in het hoofdmenu. |
| 2 | Regel onder *Doorgaan*: wijk, licht, speeltijd | zodat het duo weet welk spel het is |
| 3 | **Taal** (MN-03) | |
| 4 | **"2e speler: druk op Start"** | Staat er zodra er een tweede apparaat is. P2 kan al in het hoofdmenu meedoen en start dan mee (`coop.md` CO-02). Er is **geen apart co-op-menu**: co-op is geen modus (pitch §5, L-02). |

### 4.3 Pauze (`menu_pauze_x2_placeholder.png`)

| ID | Regel |
|---|---|
| **MN-10** | **Openen:** Menu/Start op het apparaat van P1 of P2, of Esc. Het spel staat stil (ook de Sim, `input.md` §2: `step()` telt niet). |
| **MN-11** | **Wie stuurt:** het apparaat dat pauzeerde. De andere speler ziet bovenaan "Pauze van P1/P2" en kan alleen zelf ook Start drukken om het menu over te nemen. Waarom: twee cursors in één menu leiden tot ruzie op de bank. |
| **MN-12** | **Regels:** *Verder* · *Logboek* · *Opties* · *Speler 2 stopt* (alleen in co-op; een tweede weg naast het vasthouden, `coop.md` CO-06) · *Naar hoofdmenu*. Rechts: wijk, trap van het gemaal, lampglas, logbladzijden, "opgeslagen bij het gemaal". |
| **MN-13** | **Naar hoofdmenu:** slaat op (LM-12: bij afsluiten) en vraagt **geen** bevestiging, want er gaat niets verloren behalve de plek (je begint bij het gemaal). De pauze toont dat al: "Opgeslagen bij het gemaal". |
| **MN-14** | **Automatisch pauzeren** bij: focusverlies (alt-tab, Steam-overlay; `input.md` §2), de Deck in slaap, en een **controller van P1 die wegvalt** (`coop.md` CO-08). |
| **MN-15** | **Logboek:** alle gelezen bladzijden, per gebied, met lege plekken voor wat je nog mist (geen plaats, geen hint; WS-08 zegt al waar ze liggen). |

### 4.4 Opties (`menu_opties_toegankelijkheid_x2_placeholder.png`, `menu_opties_besturing_x2_placeholder.png`)

Tabbladen met **LB/RB** (toetsenbord Q/E of Tab); elke regel heeft onderaan een uitleg van 1–2 regels. **X / Delete = standaard** voor de gekozen regel. Wijzigingen werken **meteen** en worden bij het sluiten van Opties bewaard (TD, `ontwerp.md` §7). Er is geen "Toepassen"-knop, behalve bij resolutie (bevestigen binnen 10 s, anders terug).

| Tab | Regels (standaard vet) |
|---|---|
| **Algemeen** | Taal (**systeem**, English, Nederlands) · Trillen (**aan** / uit, sterkte) · Knopiconen (**automatisch**, Xbox, PlayStation, Steam Deck, toetsenbord) |
| **Beeld** | Venster (**volledig scherm**, venster, randloos) · Schaal (**automatisch** = grootste integer, ×2, ×3, ×4, ×6; `bible` §2) · V-sync (**aan**) · Helderheid (schuif, met een testbeeld met de grijze stad en een schaduwplank: "de plank moet net zichtbaar zijn") |
| **Geluid** | Hoofdvolume · Muziek · Effecten · **Aftelling en merken** (eigen schuif, nooit lager dan 30 % van Effecten zolang Effecten aan staat) · Mono (**uit**) · Geluid op de achtergrond (**uit**) |
| **Besturing** | Herbinden per apparaat (§4.5) · Stickdrempel (**15 %**) · Herstel alles |
| **Toegankelijkheid** | §5 |

### 4.5 Herbinden (Besturing)

- Kolommen **Toetsenbord 1** (`kb1`), **Toetsenbord 2** (`kb2`) en **Controller** (één profiel voor elke pad); rijen = alle acties uit `input.md` §2a plus Pauze, Meedoen en Stoppen. **Elke actie is herbindbaar** (rolbestand UX Designer), ook de echo-knop.
- Kies een regel, druk A, druk de nieuwe knop (`MENU_PRESS_KEY`, 5 s, Esc/B = annuleren). Is de knop al bezet in dezelfde kolom: "Bezet door <actie>: wisselen?" met **A = wisselen**, B = annuleren. Nooit een actie zonder knop.
- **Vaste uitzonderingen:** B/Esc in menu's blijft "terug" en Menu/Start blijft "pauze" op de controller, zodat niemand zichzelf buitensluit. Toetsen zijn fysiek (W7 in `input.md`): op AZERTY toont het menu de echte toets ("A" op de plek van Q).
- Op de Deck verwijst een regel bovenaan naar Steam Input ("Ook in Steam: controllerinstellingen"); de game zelf blijft herbindbaar.
- Knopiconen volgen het **laatst gebruikte apparaat** van die speler (Deck-glyphs op de Deck).

### 4.6 Meldingen en opslaan

- **Opslaan** (checkpoint, LM-08): rechtsonder 1 s een draaiend tandwiel van het gemaal (icoon, geen tekst). Nooit afsluiten tijdens het icoon: het duurt < 1 s, dus geen waarschuwing.
- Meldingen (HUD-08) stapelen max. 2, nieuwste onderaan; ze pauzeren niets.

## 5. Toegankelijkheid

Wireframe: `menu_opties_toegankelijkheid_x2_placeholder.png`. Elke optie staat in het tabblad Toegankelijkheid; de standaard is het spel zoals ontworpen.

| ID | Optie | Standaard | Wat het doet | Afhankelijk van |
|---|---|---|---|---|
| **TG-01** | **Vasthouden of tikken** | vasthouden | Loslaten (E-09), genezen (LM-07), lanceerhouding (C-11a) en stoppen (C-05) werken met één druk: de handeling loopt dezelfde ticks door en een tweede druk, sprong of treffer breekt hem af. Lanceerhouding: één druk zet de houding aan, de volgende AANVAL is de lancering. | LGD bevestigt dat C-11a met een tik niet makkelijker wordt dan bedoeld (§7) |
| **TG-02** | Schermschok | 100 % | 0–100 %, ook voor de ontploffingen | — |
| **TG-03** | Flitsen verminderen | uit | Geen witte flits bij een volle meter, een ontploffing of een fasewissel; in plaats daarvan een rand van 2 px | Technical Artist |
| **TG-04** | Echo-rand dikker | uit | Rand van de echo en P2 2 px in plaats van 1 (art bible §6) | Art Director |
| **TG-05** | Merk-ring groter | uit | Klokring 25 px in plaats van 17 (§3.5) | — |
| **TG-06** | Aftelling ook trillen | aan | Een korte puls per carillonslag op de controller van de zetter (§3.5) | Audio Director (ritme gelijk aan de slagen) |
| **TG-07** | Kleurprofiel spelers | amber / cyaan | Alternatieve paren voor P1/P2 en hun merken, bv. **amber / wit-blauw** en **geel / magenta**; de vormen blijven gelijk. Elk paar haalt de ΔE-regel van de bible ook bij protanopie en tritanopie | Art Director (bible §10: kleurenblind-modus) |
| **TG-08** | Ondertitels | aan | Gesproken tekst en logbladzijden; achter een plaat, max. 2 regels | Narrative Designer |
| **TG-09** | Geluidsbijschriften | uit | Korte tekst bij geluiden die ertoe doen en niet in beeld zijn: "[carillon links]", "[echo breekt]", "[gemaal draait]" | Audio Director (lijst) |
| **TG-10** | Tekstgrootte | normaal | *Groot*: menu's, logbladzijden en meldingen 1,5× (eigen lettergrootte van de UI Artist, geen schaalfilter). De HUD blijft gelijk. | UI Artist |
| **TG-11** | HUD | altijd | *Automatisch*: levens en meter vervagen na 4 s zonder verandering naar 30 % en komen terug bij elke verandering, bij een gevecht en bij het gemaal. *Uit*: alleen voor opnames | — |
| **TG-12** | Mono | uit | (in Geluid) | — |

**Bewust (nog) niet:** een spelsnelheid en een moeilijkheidsgraad of hulpmodus. Beide raken de flownormen en de vensters van pillar 1 (en een trager spel raakt de vaste tick van de Sim). Dat is een ontwerpkeuze voor de LGD (§7), na F0.

## 6. Taal en tekst

- **Sleutels** (`ontwerp.md` §8a): prefix per scherm, `HUD_`, `MENU_`, `COMMON_`, plus `OPT_` voor opties en `A11Y_` voor de uitleg bij toegankelijkheid. Nieuwe sleutels uit deze spec (voorstel; de Gameplay Programmer zet ze in `strings.csv` bij de bouw): `HUD_LAMPGLAS`, `HUD_LOG_KOP`, `HUD_BOSS_GEMAALMEESTER`, `HUD_P2_JOINED`, `HUD_P2_STOP_HOLD`, `HUD_P2_LEAVING`, `HUD_PAD_JOIN_HINT`, `HUD_PAD_LOST`, `MENU_PRESS_ANY`, `MENU_LANGUAGE_HINT`, `MENU_CONTINUE`, `MENU_NEW_GAME`, `MENU_OPTIONS`, `MENU_CREDITS`, `MENU_QUIT`, `MENU_RESUME`, `MENU_LOGBOOK`, `MENU_P2_LEAVE`, `MENU_TO_TITLE`, `MENU_SAVED_AT_PUMP`, `MENU_CONFIRM_OVERWRITE`, `MENU_PRESS_KEY`, `MENU_KEY_TAKEN`, `MENU_PAUSED_BY`.
- **Lengte:** elk tekstvak is ontworpen voor de Engelse tekst **+ 35 %** (NL is gemiddeld langer, en sommige woorden veel: *Toegankelijkheid* tegenover *Accessibility*). Een tekst die niet past, wordt korter geschreven, nooit kleiner gezet.
- **Tekens:** het lettertype heeft minstens Latin-1 nodig voor NL (ë, é, ï, ö, ‘, ’, …) plus de knop-glyphs. Hoofdletters en kleine letters (het wireframe-font heeft alleen hoofdletters).
- **Taal wisselen** gebeurt meteen, zonder herstart; het spel bewaart de keuze (TD, opslag van instellingen; `ontwerp.md` §8a open punt).
- **Geen tekst in de art** (assetlijst S-17): iconen, de klokring en de peilbuis hebben geen woorden. Getallen alleen in debug.

## 7. Werk voor andere rollen en open punten

| # | Wat | Wie | Wanneer |
|---|---|---|---|
| 1 | **Eind-UI-art** (deel 2 van T10): stijlgids `docs/art/ui-stijlgids.md`, lantaarntje, meter, echo-icoon, P2-badge, klokring en kern van het merk (peilmerk/sluismerk), peilbuis, boss-balk, plaat, menu's, knop-glyphs per apparaat, een lettertype met licentie, en de variant *Tekstgrootte: groot*. Meetpunt: het helderste pixel achter de HUD (§2.3). | UI Artist (review AD) | Na F1 (gehaald); na F0 de maten nog eens langs W7 |
| 2 | HUD en menu's bouwen volgens deze spec, met de sleutels van §6 | Gameplay Programmer | Met T8a |
| 3 | Opslag van instellingen (taal, opties, bindings per apparaat) en 3 spelbestanden | Technical Director | Met T8a (`ontwerp.md` §7) |
| 4 | Knop-glyphs per apparaattype en het laatst gebruikte apparaat per speler; Steam Input op de Deck; Valves tekstmaat op de Deck bevestigen | Engine & Platform Programmer | Bij de Deck-build (#79) |
| 5 | Trillen per carillonslag (TG-06), de "vol"-tik van de meter, de genees-klank (gelukt, afgebroken, te weinig) en de lijst voor geluidsbijschriften (TG-09) | Audio Director | Met de slice-audio (T8d) |
| 6 | Kleurprofielen voor spelers en merken (TG-07), plus de dikkere rand (TG-04), gemeten met de ΔE-regel | Art Director | Bible v1 |
| 7 | **Boss-balk** (§3.8): akkoord of liever zonder balk | Lead Game Designer, Combat Designer | Vóór T8b |
| 8 | **TG-01 tikken in plaats van vasthouden** bij de lanceerhouding en het genezen: bevestigen dat het de bedoeling van C-11a en LM-07 niet breekt | Lead Game Designer | Vóór T8a |
| 9 | Spelsnelheid en hulpmodus (§5, *bewust nog niet*) | Lead Game Designer | Na F0 |
| 10 | HUD bijstellen na F0 en na de eerste playtest van de slice (T11): verstaan spelers het echo-icoon en de klokring zonder uitleg? | UX Designer, QA Lead | Na F0 en T11 |
| 11 | `docs/ux/besturing.md`, `docs/ux/onboarding.md` en `docs/ux/toegankelijkheid.md` (rolbestand) volgen in een eigen issue; deze spec dekt de opties van toegankelijkheid al | UX Designer | Fase 2, na T10 |

## 8. Wijzigingen

| Versie | Datum | Wat |
|---|---|---|
| 0.1 | 2026-11-10 | Eerste versie (T10 deel 1, #87): HUD solo, merk-aftelling, grijs/kleur en Deck, menu's, opties, toegankelijkheid, taal; wireframes in `docs/ux/wireframes/`. |
