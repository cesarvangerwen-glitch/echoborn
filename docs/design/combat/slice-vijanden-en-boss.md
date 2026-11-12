# Vijanden en boss van de slice (T8b)

Versie 0.1.1 · Eigenaar: **Combat Designer** · Issue [#84](https://github.com/cesarvangerwen-glitch/echoborn/issues/84) (T8b), `docs/productie/fase-2-kader.md` §2 (T8b), §3 (F3, R-V4)
Bouwt verder op: `docs/design/gemaalmeester.md` v0.2 (GM-01–GM-11, ontwerp LGD, [#187](https://github.com/cesarvangerwen-glitch/echoborn/issues/187)), `docs/design/wereld.md` v0.1.4 §2 (slice Kadewijk, §2.4 vijandtypes), `docs/design/gdd.md` v0.8 (#187; E-02, E-02m, E-02t, E-07a, E-07c, E-07d, E-14, E-14j, C-09–C-16, C-12e, L-13, LM-02, LM-05, LM-07, V-01, §2.5a, §4.3, §4.7, §4.8.5), `docs/concept/pitch.md` v0.4 §4 (P1–P3).
Dit document is het **detailontwerp** dat `gemaalmeester.md` §7 en `wereld.md` §2.4 aan de Combat Designer laten: schade, levens, maten, patronen, vensters, telegraphs en de bouwopdracht. Waar het afwijkt van een LGD-document, staat dat in §8 (voor de Lead-review); de LGD-documenten zelf verandert dit document niet. Voor de slice vervult het de rol van `vijanden.md` en `bosses/gemaalmeester.md` uit het rolbestand.

---

## 0. Werkaanname (kader §5)

| Bron | Wat dit document ervan gebruikt |
|---|---|
| CEO-besluit 2026-11-12 (#80) | **D = 60 ticks (1 s)** is de werkaanname; het bereik is **1–3 s (D = 60 … 180)**. Alle vensters en patronen zijn eerst voor **D = 60** gezet; waar een maat van D afhangt, staat hij als formule, met de waarden voor 60 / 90 / 120 / 180 (§7). |
| CEO-besluit 2026-11-12 (#80) | Fase 2 parallel, ook bouwen: T8b wacht niet op een geslaagde flow-test. De CEO test alleen bij mijlpalen; tot dan toetsen de bots (§6). |
| CEO-besluit #51 deel 2 | 1A: bosses zijn gebouwd om samen of met je echo te winnen, geen puzzel. 7A: één rol, solo de echo, co-op de partner; verplicht bij bosses; gedeelde echo alleen als finisher; max. twee lichamen. 8A: de finisher speelt jullie laatste 10 s af. |
| CEO-besluit #2 | PEGI 12; 8–12 min per boss inclusief pogingen. |
| Pitch v0.4 §4 P1 | Elke verplichte boss-actie: **≤ ± 5 s stilstand** (MP-1 ≤ 300 ticks), vensters **≥ 10 frames** (1 frame = 1 tick, 60 per s), feedback in geluid, schermschok en licht. |
| Fasekader v0.2, R-V4 | **Max. 4 vijandtypes** in de slice; de boss telt niet als type. |
| Flow-tests F0 en F0-2 | (1) Merk en ontploffing waren zonder hulp niet leesbaar (M2 "geen idee"); de **bereikcirkel en doelstreep** (E-14j, E-02t) zag de CEO wel en ze hielpen. (2) Paren op 28 px geven geen ketting: de eerste ontploffing doodt beide (`flowkamer.md` §4). |

**Werkaanname Combat Designer:** alle getallen hier zijn **startwaarden** voor de bouw, gekozen op D = 60 en de bewegingswaarden van gdd §2.5a. Ze worden gezet met de scripted runs (§6, B-9) en bijgesteld na de mijlpaal-test van de slice (T11). De LGD werkt de gdd parallel bij voor D = 60 (#81); verandert daar een waarde waar dit document op rust (staart, R, E, K, merk-levensduur, beweging), dan rekent de Combat Designer §7 opnieuw na.

---

## 1. Samenvatting

- **3 vijandtypes** (van max. 4): **Kadeloper**, **Schotdrager**, **Dwaallicht**. De vierde plek blijft in de slice **leeg** (§2.5).
- **De Gemaalmeester** in **2 fasen + Wankel**: fase 1 *het schot* (je tweede slag: alleen een merk-ontploffing breekt het, **4 openingen**), fase 2 *het grote rad* (je springplank: alleen met bounce, lancering of vang te raken), Wankel met de **co-op-finisher** (C-14).
- Elk verplicht moment werkt solo met de echo en in co-op met de partner, in dezelfde arena, met vensters ≥ 10 ticks; bij D = 60 is de langste verwachte wacht **39 ticks** (de optionele solo-lancering).
- Bouwopdracht voor de Gameplay Programmer in §6 (B-1–B-11), wat Animator, UI/UX en Audio nodig hebben in §9.

---

## 2. Vijandtypes

### 2.1 Gedeelde regels (alle drie)

| ID | Regel |
|---|---|
| **VJ-01** | **Merkbaar en eerlijk.** Elk type is `Merkbaar` (E-14a). Elke aanval heeft een **aanloop van ≥ 30 ticks** met een tell in beeld én geluid (§9), en daarna een actief vlak van hooguit 8 ticks. Contactschade bestaat niet: alleen een actief aanvalsvlak raakt P1. |
| **VJ-02** | **Schade aan P1.** Elke treffer van een vijand of de boss kost P1 **1 levenspunt** (P1: 5, plus 1 voor het lampglas in S5). Daarna is P1 **45 ticks onkwetsbaar** (knipperen); nieuw, de gdd heeft er nog geen waarde voor. De echo en P2 krijgen nooit iets (E-14h, C-02). |
| **VJ-03** | **Snelheid in D.** Een vijand die loopt of zweeft, beweegt met `v(D) = min(v_max; 44 / (D − 27))` px/tick. Zo geldt L-13 (c) (`36 + v × (D − 27) ≤ R = 80`) bij elke D: de merksprong haalt hem altijd. Kadeloper en Schotdrager: `v_max = 0,5`. Dwaallicht: `v_max = 0,25`. Waarden per D: §7. **Bovengrens: `v ≤ 0,70 px/tick`** voor elke vijand (`44 / (D_max − 27)` met D_max = 90, gdd v0.8 §4.8.5). Bij D = 60 lopen ze dus **0,5 px/tick**, twee keer zo snel als in de flow-kamer en onder de grens: de korte staart laat dat toe, en een snellere vijand geeft minder reden om te wachten. |
| **VJ-04** | **Stil na een treffer.** Na elke treffer (ook een merk zetten of een ontploffing die hem niet doodt) staat een vijand **30 ticks** stil en breekt zijn aanloop af (zoals gdd §4.3). |
| **VJ-05** | **Paren en afstandsregel per paar.** L-13 (d) blijft: **elke golf heeft minstens één E-paar**, twee vijanden die **≤ 32 px** (E) uit elkaar beginnen: één merk raakt ze allebei, één knal doodt het paar. Daarnaast mogen er **K-paren** bij, als extra paar: **40–44 px** uit elkaar, buiten E en binnen K = 48, zodat twee merken ketenen met de kettinglijn van E-14j in beeld (20 + 25 SE; de les van F0-2: op 28 px komt er geen ketting). **De afstandsregel geldt per paar:** elk paar heeft een startafstand `a` **in data** (`slice.csv`; E-paar 28 px, K-paar 40–44 px), en de twee vijanden van een paar komen niet dichter bij elkaar dan `a` (een vijand loopt niet verder als hij daarmee binnen `a` van zijn paargenoot komt). Vijanden die geen paar zijn, houden ≥ 40 px, zodat paren niet samensmelten. |
| **VJ-06** | **Donker en verlicht** (O-18, pitch P2). In een wijk die nog niet is opgepompt (waterstand `s < 2`, "donker") gelden de waarden hieronder. In een **verlichte** wijk (`s = 2`, in de slice alleen S9) zijn vijanden **zwakker, niet anders**: `v` × 0,5 en de aanloop +10 ticks. Geen apart type per lichtstand (kernloop §5). Beeld: in het donker gloeien hun ogen en randen feller (Art). |
| **VJ-07** | **Leesbaarheid van het merk** (F0, F0-2). E-02t (doelstreep) en E-14j (bereikcirkel, rand, kettinglijn) gelden voor **elk** merk op een vijand en op de boss; ze zijn voor T8b geen polish maar een eis. Een treffer op een **intact pantser** geeft een eigen geluid en vonk ("tink", 0 SE), anders dan een treffer met schade. |

### 2.2 Kadeloper (basisvijand)

| Wat | Waarde |
|---|---|
| Rol | De basisvijand van de slice en de adds van de boss: merken, laten knallen, ketting in paren; bron van licht (genezen, LM-07) |
| Lichaam en hurtbox | 16 × 24 px, op de vloer; springt niet, valt niet van randen (draait om bij een rand) |
| Levens | **30 SE** (P1-treffer 10, ontploffing 20: één merk + één slag, of een merk dat de echo laat knallen + één slag) |
| Beweging | Loopt naar P1 met `v(D)` (VJ-03; 0,5 bij D = 60, 0,25 verlicht); VJ-05 |
| Aanval: **haakslag** | Als P1 binnen 16 px is (randen; middelpunten ≤ 32 px): aanloop **30 ticks** (haak omhoog, schraapgeluid), actief **6 ticks** een vlak van 20 × 16 px vóór hem, 4–20 px boven de vloer; herstel 20 ticks |
| Ontwijken | Weglopen (in 30 ticks 60 px), erover springen, of op je echo/partner staan (het vlak reikt tot 20 px, de plank ligt op 30) |
| Merk | E-14a; in een E-paar (28 px) doodt één knal het paar, in een K-paar (40–44 px) ketent hij (VJ-05) |
| Licht | LM-02 (+2 per treffer, +6 per schakel) |
| Terugkeer | Ja (LM-13a, `STANDAARD`), zolang het gemaal niet vol is (zoals K2) |

### 2.3 Schotdrager (gepantserde Kadeloper)

| Wat | Waarde |
|---|---|
| Rol | Leert vóór de boss wat het schot van de Gemaalmeester vraagt: **alleen een merk-ontploffing breekt een pantser** (E-14g). Een Kadeloper met een geroest sluisschot voor zich |
| Lichaam en hurtbox | 16 × 24 px (zelfde vorm als de Kadeloper, zodat de code één soort met een vlag is); beeld 22 × 26 px met het schot |
| Pantser | Volgens E-14g voor het hele lichaam (geen "achterkant raken": de les is het merk, niet om hem heen springen). Treffer op het intacte pantser: 0 SE, 0 LP, **wel een merk**, "tink" (VJ-07). De eerste ontploffing die hem raakt (ook een schakel van een ketting of een ontploffing binnen E = 32 van een buurman), breekt het pantser en doet verder niets. Daarna: gewone Kadeloper, 30 SE |
| Beweging en aanval | Als de Kadeloper; aanval **schotstoot**: aanloop 30, actief 6, vlak 24 × 16 px |
| Plek | Altijd in een **E-paar** met een Kadeloper (VJ-05: 28 px): de ontploffing van het merk op de Kadeloper (E = 32) breekt ook zijn pantser. **Blokkeert de route nooit** (L-13 e): een golf is op zonder hem |
| Terugkeer | Nee (zoals het pantserdoel) |

### 2.4 Dwaallicht (zwevend stuitdoel)

| Wat | Waarde |
|---|---|
| Rol | Stuitdoel voor de **Neerslag** (V-01b) vlak voor de boss: hij leert je boven iets uit te komen en daar te blijven, wat het grote rad in fase 2 beloont |
| Lichaam en hurtbox | 16 × 16 px; zweeft op een **vaste horizontale baan** van 32–96 px lang, onderkant **40–56 px** boven vloer of water (in S7: 40 px, zodat een gewone sprong + neerslag hem haalt; het neerslagvlak van 16 × 20 px onder de voeten reikt bij de top van een sprong van 30 tot 50 px) |
| Levens | **30 SE** |
| Beweging | `v(D)` met `v_max = 0,25` (VJ-03), heen en weer op zijn baan; stil na een treffer (VJ-04) |
| Aanval: **duik** | Als het middelpunt van P1 horizontaal binnen 24 px van het zijne is en P1 lager hangt: aanloop **30 ticks** (licht zwelt, toon stijgt), dan een duik van 8 ticks naar 16 px boven de vloer (zijn lichaam is het actieve vlak), daarna 40 ticks terug naar zijn baan zonder schade |
| Merk en echo | Een neerslag van P1 merkt hem en stuit (V-01b); de echo herhaalt de neerslag D + 3 ticks later als merksprong en laat het merk knallen (V-01e): **10 + 20 = 30 SE**, de echo ruimt achter je op |
| Terugkeer | Ja in het donker; **nee** zodra de wijk verlicht is (`wereld.md` §2.4) |

### 2.5 De vierde plek (OW-4)

**Niet gebruiken in de slice.** De drie types dekken de drie dingen die de boss toetst (merk-ketting, pantser, boven iets blijven). Een vierde type kost animatie en audio (F6, kost per type) en maakt de slice minder leesbaar (R-V6). Alleen als de mijlpaal-test laat zien dat spelers op één plek blijven staan in S3 of S6, stelt de Combat Designer een type op afstand voor (bv. een werper die je laat bewegen); dat is dan een nieuwe versie van dit document, geen CEO-vraag (binnen R-V4).

### 2.6 Waar ze staan (voorstel voor de World & Level Designer, `wereld.md` §2.2)

De kamers en de geometrie zijn van de World & Level Designer; dit is de verdeling binnen de kamerlijst, met de paren van VJ-05. Max. 5 vijanden tegelijk in beeld (L-13 f).

| Kamer | Vijanden | Hoe |
|---|---|---|
| S2 Kadegang | 2 Kadelopers | Eén **E-paar** (28 px), op het vlakke stuk na de lus (B3): één merk, één knal, twee neer |
| S3 Vismarkt | Golf 1: 3 Kadelopers. Golf 2: 2 Kadelopers + 1 Schotdrager | Golf 1: één **E-paar** (28 px) + één losse, ≥ 160 px van het paar. Golf 2 aan de kant van de ingang (je keert ernaartoe, zoals K2): de Schotdrager in een **E-paar** met een Kadeloper, de tweede Kadeloper los. Golf 2 start zodra elke Kadeloper van golf 1 een merk heeft of op is (zoals K2, gdd §4.7.1 c) |
| S4 Brugkloof | 1 Kadeloper | Aan de overkant, ≥ 80 px van de landing van de lancering (geen treffer bij aankomst) |
| S6 Gemaalplein | 2 Kadelopers (terugkerend) | Eén **K-paar** (40–44 px): hier zie je de **ketting**; ≥ 80 px van elke pompschoep (FK-5: anders kiest de echo een merksprong in plaats van een pompslag) |
| S7 Sluiskelder | 2 Dwaallichten | Boven het kanaal van 160 px: banen van 32 px rond 1/3 en 2/3 van de breedte, onderkant 40 px; stuitlijn sprong → neerslag → stuit → neerslag → overkant |
| S8 Machinehal | Adds: Kadelopers uit de spuigaten | §3.4 (fase 1, max. 2 tegelijk) |
| S9 Lage kade | 2 Kadelopers (verlicht, VJ-06) | Eén **E-paar** (28 px); trager, de wijk is je beloning |

---

## 3. De Gemaalmeester

### 3.1 Wat hij toetst

| Fase | Vermogen (geleerd in) | Samenwerkingsactie (C-16 b) | Solo | Co-op |
|---|---|---|---|---|
| 1. Het schot | Merk + echo laat knallen (S2, S3), pantser (Schotdrager, S3) | Merk-combo | P1 merkt, de echo knalt (merksprong) | De een merkt, de ander slaat |
| 2. Het grote rad | Bounce, lancering (S1, S4), neerslag-stuit (S7) | Bounce, lancering, vang | Keren tegen de muur, op je echo; of de lanceerhouding | Op elkaar bouncen, lanceren, vangen |
| Wankel | Merk-combo | Finisher (C-14, C-16 a) | Merk, de echo knalt; de gedeelde echo speelt jou en je echo af | Merk, de ander knalt; de gedeelde echo speelt jullie twee af |

### 3.2 Arena, lichaam en hurtboxes (aanvulling op GM-01, GM-02)

Coördinaten in arena-px: vloer van **x = 0** (linkermuur) tot **x = 600** (rechtermuur), `y` = hoogte boven de vloer.

| ID | Regel |
|---|---|
| **GMB-01** | **Lichaam** op x 252–348 (96 px), niet massief, geen contactschade (GM-02). Hij draait niet en loopt niet. |
| **GMB-02** | **Schot en kern** (fase 1): één `Pantserdoel` (E-14g) met hurtbox 48 × 48 px op x 276–324, y 12–60, van **beide kanten** te raken (je loopt door het lichaam heen). Merkplek en merk op het middelpunt (300, 36): binnen 24–48 px (GM-06) en vanaf de vloer binnen R = 80 van elke slagpositie. Intact = het schot; gebroken = de **kern** (gewone schade, `Merkbaar`). |
| **GMB-03** | **Spuigaten** op x 236 en x 364, op de vloer (de adds komen eruit, §3.4). |
| **GMB-04** | **Het grote rad** (fase 2): hurtbox 96 × 40 px, y **100–140**, middelpunt op `x_rad = D + 34` px van de muur aan zijn kant (GM-07): bij D = 60 op **x = 94** (links) of **x = 506** (rechts), hurtbox x 46–142 of 458–554. Niet `Merkbaar`. Onder het rad een **vloerteken** (olievlek met licht) van `D` tot `D + 68` px van de muur: daar draagt je echo je na het keren omhoog (alleen beeld; schuift mee met D). |
| **GMB-05** | **Merkplek van Wankel**: zelfde plek als GMB-02 (300, 36), op de ketel, alleen bij Wankel. |
| **GMB-06** | Geen `FelLicht`, `Schaduwgevaar`, `Diepwater` of richels in de arena (GM-01): de echo breekt hier nooit, en zonder echo of partner is het rad niet te halen. |

### 3.3 Levens, fasen en drempels (vervangt de getallen van GM-03)

| ID | Regel |
|---|---|
| **GMB-10** | **1500 SE** (in data, `slice.csv`), solo en co-op (co-op-schaal ×1,0 als start, §3.8). Zelfde verhoudingen als GM-03: fase 1 van 100 % tot 60 % (600 SE, tot 900), fase 2 van 60 % tot 20 % (600 SE, tot 300), Wankel op ≤ 20 %. Waarom 1500 (v0.1: 600, GM-03 v0.1.2: 400): het doel is een scripted run van **90–150 s** (Lead-review #185); dat halen we met **een 4e opening** (GMB-11) en **meer kanten** in fase 2 (§3.5), niet met langere vensters, en meer kanten vraagt meer SE in fase 2. Bij D = 60 knalt de echo eerder, dus de schade per seconde ligt hoger dan bij D = 120. |
| **GMB-11** | **Vier openingen in fase 1** (aantal en drempels in data). Fase 1 heeft drempels op **1350, 1200, 1050 en 900 SE** (150 SE per opening). Een opening (gebroken schot) eindigt bij de drempel van die opening of na **300 ticks** (GM-06), wat eerst komt: dan schuift het schot weer voor de kern. Schade onder de drempel van de opening valt weg (de boss klemt op de drempel). Na de vierde drempel: fasewissel. Zo breekt een geoefende speler het schot **precies vier keer** (leren, toepassen, twee keer toepassen met adds), en is fase 1 in co-op niet in één opening voorbij (MP-7). |
| **GMB-12** | **Fasewissel** 60 ticks (GM-03): hij valt niet aan, alle merken op de boss doven, levende adds lossen op in stoom (geen LP), het schot sluit voorgoed (niet meer `Merkbaar`), het rad hijst zich uit de ketel en draait naar de kant **waar P1 níét is** (co-op: niet is P1), zodat je ernaartoe loopt en tegen de muur keert. |
| **GMB-13** | **Wankel** op ≤ 300 SE (klemt op 300). Zie §3.6. |

### 3.4 Fase 1: het schot (GM-06)

**Ritme:** één aanval per maat van **120 ticks** (GM-04); de allereerste aanval heeft 60 ticks aanloop (hij aarzelt bij de sjaal).

**Aanval A: pompslag (fase 1).**

| Wat | Waarde |
|---|---|
| Doel | De helft waar P1 is op het begin van de aanloop: `x < 300` → **links**, anders **rechts** |
| Vlak | 160 × 24 px: links x **140–300**, rechts x **300–460** (de helft van het lichaam plus 112 px ernaast: wie bij de kern slaat, staat er altijd in) |
| Tijden | aanloop **40**, actief **6**, herstel 24 (de stang ligt op de vloer, doet niets), rust tot het eind van de maat |
| Tell | De drijfstang heft zich naar die kant; stoom en een stofstrook op het vlak, die feller wordt; carillon-tel op het begin van de maat, sissende zuiger die stijgt (§9) |
| Ontwijken | (1) **door de machine naar de andere helft** stappen (vanaf de kern 10–30 px, 5–15 ticks); (2) **springen**: je voeten zijn 29 ticks boven 24 px, dus het venster om af te zetten is **24 ticks**; en de sprong-aanval raakt de kern (y 12–60) gewoon; (3) op je echo of partner staan (plank op 30 px); (4) dash |

**Het schot breken (verplicht).** Elke treffer van P1 (of P2) op het intacte schot zet een merk (0 SE, "tink", bereikcirkel). Solo herhaalt de echo die slag **D + 3 ticks** later als merksprong (E-02m) en laat het merk knallen: het schot breekt. Vanaf `t − 30` vóór de knal staat de **doelstreep** (E-02t). In co-op slaat de ander op het gemerkte schot. Ook een ontploffing van een add binnen E = 32 px van het merkmiddelpunt, of een schakel van een ketting, breekt het (E-14g).

**Waarom dit leesbaar is zonder tekst (GM-a):** het schot breekt solo **vanzelf** als je erop slaat en daarna gewoon doorbeweegt: de echo komt altijd langs, want hij herhaalt je slag op dezelfde plek en het merk leeft D + 30 ticks (bij D = 60: knal op 63, merk dooft op 90, 27 ticks marge). Je hoeft het niet te snappen om het te zien gebeuren, en na de eerste keer weet je het. De "tink" bij de eerste slag zegt "dit is pantser"; de cirkel, de streep en de knal zeggen wat het wel breekt.

**Gebroken: de kern.** Breuk = scheur, stoom, schermschok 6 ticks / 2 px, de ketel licht oranje op. De kern ligt open tot de drempel van de opening (150 SE verder, bij ± 0,75 SE/tick ± 200 ticks) of 300 ticks (GMB-11) en is `Merkbaar`: P1-treffer 10 SE, gewone echo-treffer 5, merk-ontploffing 20 (ketting volgens E-14d). De echo herhaalt je slagen op de kern één staart later: met merk erop knalt hij, zonder slaat hij 5. **Dit is je tweede slag.** Elke 120 ticks komt er een pompslag op jouw helft: slaan, ontwijken, slaan.

**Adds (GM-05c).** Als het schot na opening 1, 2 en 3 dichtgaat, gloeien de spuigaten **30 ticks** en komt er uit elk één **Kadeloper** (max. 2 levend; zijn er al 2, dan geen nieuwe). Ze doen de eerste 30 ticks niets (uit de stoom stappen). Ze lopen naar P1, dus naar het schot: met hun merken ketent een knal tot het schot (K = 48), of breekt hun ontploffing het schot (E = 32). Ze zijn je **licht** om te genezen (LM-07). Vóór opening 1 geen adds: de eerste keer is schoon.

### 3.5 Fase 2: het grote rad (GM-07)

**Ritme:** één aanval per maat van **90 ticks**, om en om **pompslag** en **schoepenzwiep**: *hoog – laag*.

**Aanval A': pompslag (fase 2).**

| Wat | Waarde |
|---|---|
| Doel | Een vlak van 160 × 24 px **gecentreerd op x van P1** op het begin van de aanloop, binnen de arena (geklemd op x 0–600) |
| Tijden | aanloop **30**, actief 6, herstel 24 |
| Ontwijken | **in de lucht of op je echo/partner zijn** tijdens de 6 actieve ticks: springen (venster 24 ticks), **bouncen naar het rad** (de bounce is je ontwijking), dash + lopen (40 + 40 px in 30 ticks, net); lopen alleen haalt het niet (80 px = 40 ticks): hij vraagt een sprong |

**Aanval B: schoepenzwiep (alleen fase 2).**

| Wat | Waarde |
|---|---|
| Doel | De helft waar P1 is (`x < 300` of niet) |
| Vlak | 300 × 24 px op **y 36–60** (die helft van muur tot midden) |
| Tijden | aanloop **30**, actief **8**, herstel 20 |
| Tell | De schoepen aan die kant draaien op; een horizontale lichtstreep op 36–60 px; aanzwellend water-gesuis (§9) |
| Ontwijken | **op de vloer blijven** (lichaam 0–30 < 36: 6 px marge; gewoon doorlopen, niet springen tijdens de 8 actieve ticks) of **hoog zijn**: bij een bounce vanaf je echo zijn je voeten **36 ticks** boven 60 px, dus het venster om af te zetten is **± 28 ticks**. **Niet** op je echo staan: zijn plank ligt op 30, je lichaam op 30–60 zit in het vlak (afwijking van GM-05b, §8) |

**Het rad raken (verplicht).** Het rad (GMB-04, y 100–140) is met een sprong niet te raken: het aanvalsvlak reikt bij de top tot 73 px. Wel met:

| Actie | Solo (echo) | Co-op (partner) | Wat het haalt |
|---|---|---|---|
| **Bounce** (hoofdroute) | Loop naar de muur aan de kant van het rad, **keer** en spring meteen: je ontmoet je echo **D/2 = 30 ticks** na het keren op **D = 60 px** van de muur (gdd §4.3), het plank-signaal (E-07d) licht op. Bounce: je zweeft van 60 naar 128 px van de muur, over het rad (46–142) | Bounce op de partner, die waar ook onder het rad staat | Aanvalsvlak boven 100 px gedurende **28 ticks** (voeten ≥ 77 px): **1 treffer per bounce** |
| **Lancering** (meesterroute) | Lanceerhouding (C-11): sla bij de muur, houd vast, je echo staat D ticks later in houding; springen op `T + D − 21 … T + D − 3` (**19 ticks**), wachten **D − 21 = 39 ticks** | Partner slaat en houdt vast (12 ticks), jij stapt erop | Voeten tot ± 142 px: je komt **boven** het rad; dan **neerslag** (V-01): het vlak onder je raakt het rad zolang je voeten op 100–160 px zijn, **stuit** (`v.y = −5`) en weer: de treffers van een kant (2) zonder te landen, en je bent vóór het rad draait al weg |
| **Vang** | Val vanuit een bounce terug op je echo (hij staat waar jij D ticks eerder liep): zwiep `v.y = −6`, nog een treffer | De partner vangt je onder het rad | Zoals de bounce |

**Schade:** treffer van P1 of P2 op het rad **15 SE** (GM-07: 10; §8), gewone echo-treffer 5 (de echo herhaalt je slag in de lucht als het rad er nog hangt), +2 LP per treffer (LM-02). **Wegdraaien:** na **2 treffers van P1 en P2 samen** (`kant_treffers` in data, start 2; GM-07 had 3; de echo telt niet mee) of na **180 ticks**: het rad **trilt en ratelt 20 ticks** (tell), en draait dan in **60 ticks** naar `x_rad` aan de andere muur. Draaien doet niets (geen contactschade); het rad is tijdens trillen en draaien niet te raken. Je loopt mee naar de andere muur, keert, en het begint opnieuw: het wegdraaien maakt van elke kant een nieuwe keer-run.

**Waarom zonder echo onmogelijk (C-16-test):** geen richels, geen adds in fase 2, het lichaam is niet begaanbaar, de kern en het schot hebben in fase 2 geen hurtbox, een sprong reikt tot 73 px. Er is niets om op te bouncen of van te stuiten behalve je echo of partner.

### 3.6 Wankel en de finisher (GM-08, C-14)

| Stap | Wat | Tijden |
|---|---|---|
| Wankel | Op 300 SE: hij hapert, het carillon valt stil, geen aanvallen, geen tijdslimiet. De merkplek op de ketel (GMB-05) gaat open: een gloeiende peilmerk-vorm | — |
| Merk | P1 (of P2) slaat de merkplek: merk + bereikcirkel | solo leeft het merk D + 30 = **90 ticks**; in co-op **150 ticks** (C-12e, gdd v0.8) |
| Knal | Solo: de echo herhaalt de slag als merksprong (doelstreep vanaf 30 ticks vooraf); co-op: de ander slaat het merk | solo `t_f = slag + D + 3` = **63 ticks** na de slag |
| Finisher | De gedeelde echo (de schim van machinist en sluiswachter samen) speelt jullie laatste 600 ticks af in 120 ticks (C-14 c); elke slag van P1 en het tweede lichaam vanaf `BOSS_START` = één finisherslag, +1 LP | 120 ticks; mislukt nooit |
| Einde | `BOSS_VERSLAGEN` op `t_f + 120`; hij lost op in licht, meter naar 100 LP (GM-10) | — |

Solo met D = 60 is de langste wacht in Wankel de 63 ticks tussen je slag en de knal, en je mag in die tijd gewoon lopen.

### 3.7 Vensters en stilstand (GM-09, pitch P1)

| Verplicht moment | Venster (D = 60) | Formule | Stilstand die het vraagt |
|---|---|---|---|
| Schot merken | onbeperkt (het schot staat er tot je slaat) | — | 0 |
| Echo knalt het schot (solo) | merk leeft 90; knal op 63 → 27 ticks marge | `D + 30`; knal `D + 3` | 0: je mag weglopen |
| Partner slaat het schot (co-op) | merk leeft **150 ticks** | 150, vast (C-12e) | 0 |
| Kern slaan | ≤ 300 ticks per opening | — | 0 |
| Pompslag ontwijken (springen) | 24 ticks | vast | 0 |
| Zwiep ontwijken (bounce) | ± 28 ticks; op de vloer blijven: onbeperkt | vast | 0 |
| Bounce op de echo na keren | ontmoeting 30 ticks na het keren; bounce-buffer 10 + coyote 6 = **17 ticks** voor JUMP | `D/2`; afzet `(2D − 130)/4` ticks na het keren (§7) | 0 |
| Rad raken uit een bounce | 28 ticks per bounce | vast | 0 |
| Rad per kant | ≤ 180 ticks of 2 treffers | — | 0 |
| Solo-lancering | 19 ticks om af te zetten | `T + D − 21 … T + D − 3` | **39 ticks** wachten (optioneel) |
| Wankel → knal | onbeperkt; solo knal 63 ticks na je slag; co-op merk 150 ticks voor de partner | `D + 3`; co-op 150 | 0–63 |

**Verwachte MP-1 bij D = 60** (scripted geoefende run): langste stilstand **≤ 60 ticks** in beide modi; met de optionele solo-lancering ≤ 70. De grens is 300. Alle vensters zijn ≥ 17 ticks (eis: ≥ 10).

### 3.8 Solo en co-op

| Onderwerp | Regel |
|---|---|
| Wie wordt aangevallen | Alleen **P1** (P2 en de echo zijn onkwetsbaar, E-14h, C-02). Pompslag en zwiep richten op de helft of de x van P1 |
| Schaal | Start ×1,0 (GM-03). Ingebouwde remmen op co-op-snelheid (MP-7: co-op ≥ ½ × solo): de **drempels van fase 1** (GMB-11, de opening stopt op de drempel, hoeveel je ook slaat) en de **2 treffers per kant samen** in fase 2. Haalt co-op MP-7 toch niet: eerst **fase 2 ×1,25 SE** in co-op (rad 600 → 750 SE; pas na B-9), dan ×1,5 (O-13), pas daarna iets anders |
| Drop-in/out | Volgens C-03/C-05: de partner neemt de echo over of andersom, ook midden in een opening of in Wankel; merken van P2 knalt de echo na een drop-out (C-12 b). Geen moment vraagt twee live spelers (C-16 e) |
| Opnieuw proberen | GM-11: 0 levenspunten → respawn bij het gemaal, de boss op 1500 SE en fase 1, adds weg, meter blijft |

### 3.9 Verwachte duur (scripted geoefende run, D = 60; te meten in B-9)

| Deel | Solo (ticks) | Co-op (ticks) | Hoe geschat |
|---|---|---|---|
| Aarzeling + opening 1 | ± 300 | ± 250 | merk 63 tot de knal + 150 SE op de kern met ± 0,75 SE/tick (P1 + echo) |
| Opening 2–4 (met adds) | ± 3 × 370 | ± 3 × 290 | idem + adds en het schot weer breken |
| Fasewissel | 60 | 60 | vast |
| Fase 2 (600 SE) | ± 4950 | ± 5000 | solo ± 15 kanten × (2 treffers + echo ≈ 40 SE), co-op ± 20 kanten × 30 SE; per kant ± 330 (solo) / 250 (co-op) ticks, vooral lopen naar de andere muur |
| Wankel + finisher | ± 190 | ± 150 | merk + knal + 120 |
| **Totaal** | **± 6600 (± 110 s)** | **± 6300 (± 105 s)** | co-op ± 0,95 × solo: binnen MP-7 (≥ ½ × solo) |

**Doel (Lead-review #185):** scripted **90–150 s** per modus; een geoefende mens ± 1,5× zo lang, een eerste speler 8–12 min met pogingen (#2). **Knoppen, in data** (`slice.csv`): het aantal openingen en hun drempels (GMB-11), `kant_treffers` en de SE van fase 2 (meer of minder kanten); **niet** de vensters of aanlopen. Risico: ± 15 kanten in fase 2 kan eentonig worden; de mijlpaal-test meet het (GM-d, MP-5).

---

## 4. Wat de boss niet heeft (O-17, O-20)

- **Geen pareren en geen aanval omhoog** in de slice; O-17 gaat terug naar **fase 3**. Een aanval omhoog zou het rad met een sprong bereikbaar maken (73 px + bereik omhoog) en daarmee fase 2 zonder echo te doen; pareren is er niet in de slice (`wereld.md` §2.1). In fase 3 beslissen LGD en Combat Designer erover, met de regel uit E-14f.
- Geen aanval op de echo of P2, geen aanval die stilstand beloont, geen moment dat twee live spelers vraagt.

---

## 5. Toets aan de pillars

| Pillar | Toetsvraag | Antwoord |
|---|---|---|
| P1 | Maakt de echo deze actie vloeiender of krachtiger, zonder stilstand? | Ja: het schot breekt terwijl je doorbeweegt; je tweede slag op de kern; keren en bouncen is zowel de weg naar het rad als de ontwijking van de pompslag. Langste wacht 39–63 ticks bij D = 60 |
| P2 | Gaat de weg open door licht of een vaardigheid, geen raadsel? | Ja: na de boss gaat de wijk aan (GM-10); in fase 2 beloont het rad de Neerslag uit S7; vijanden zijn sterker in het donker (VJ-06) |
| P3 | Werkt het met een partner en met je echo, in dezelfde arena? | Ja, elk moment in beide vormen (§3.1); remmen op co-op-tempo (§3.8) |
| Puzzeltoets | Moet je stilstaan om een volgorde of timing te bedenken? | Nee: je slaat, ontwijkt en bouncet in het ritme van de maat |

---

## 6. Bouwopdracht voor de Gameplay Programmer

Code in `game/` (SM-review, `WERKWIJZE.md` §5). De arena S8 bouwt T8a ([#83](https://github.com/cesarvangerwen-glitch/echoborn/issues/83)); T8b levert de boss en de vijanden als scènes die T8a erin zet. Bestandsnamen zijn een voorstel; de Technical Director beslist. Bestaande basis: `game/scripts/combat/combat_target.gd` (soorten `ENEMY`, `ARMORED`, `DUMMY`) en `combat.gd`. Elke waarde uit dit document komt in **`game/data/vijanden/slice.csv`** (één regel per type en per boss-parameter), zodat de Combat Designer kan bijstellen zonder code; de code leest ze in.

| # | Wat | Klaar als |
|---|---|---|
| **B-1** | **Gedeelde vijandregels**: `v(D)` (VJ-03), stil na treffer (VJ-04), afstandsregel per paar met startafstand `a` uit data, 40 px tussen vijanden die geen paar zijn (VJ-05), donker/verlicht (VJ-06), 45 ticks onkwetsbaar na een treffer op P1 (VJ-02); `slice.csv` inlezen | Tests: `v(D)` = 0,5 / 0,5 / 0,473 / 0,287 bij D = 60 / 90 / 120 / 180; twee Kadelopers van een paar komen nooit dichter dan hun `a` (28 of 40–44 px), twee die geen paar zijn nooit binnen 40 px; `v` ≤ 0,70 bij elke D; L-13 (c) per D (het merk ligt na D + 3 ticks ≤ 80 px van de opgenomen positie); in S9 de verlichte waarden |
| **B-2** | **Kadeloper** (de basisvijand met de waarden van §2.2: haakslag 30/6/20, vlak 20 × 16 op y 4–20) | Test: aanval alleen binnen 16 px, P1 op de plank van de echo wordt niet geraakt; E-paar op 28 px: één slag merkt beide, één knal doodt beide; K-paar op 40 px: twee merken + knal = ketting 20 + 25, beide dood |
| **B-3** | **Schotdrager** (soort `ENEMY` met `armor_intact` en lopen, §2.3) | Tests: treffer op het intacte pantser = 0 SE, 0 LP, merk gezet, event voor de "tink"; in een E-paar op 28 px breekt de ontploffing van het merk op de Kadeloper het pantser en doet verder 0; daarna 30 SE; komt niet terug |
| **B-4** | **Dwaallicht** (§2.4): baan, duik 30/8/40, stuitdoel (V-01b), terugkeer alleen in het donker | Tests: neerslag op een Dwaallicht op 40 px = stuit + merk; de echo herhaalt het als merksprong (30 SE samen); in S7 haalt de scripted run de overkant via twee stuiten bij elke D |
| **B-5** | **Boss-basis** `Boss` (C-14 a): 1500 SE, fasen en drempels (GMB-10–13, met klemmen), `BOSS_START`/`BOSS_VERSLAGEN`, arena dicht/open (GM-01), reset bij respawn (GM-11); bouwt de testboss van de C-14/C-16-test mee (O-14) | De C-14-test en de C-16-test van gdd §4.6 groen, eerst op de testboss, daarna op de Gemaalmeester |
| **B-6** | **Maat en aanvallen**: een maatklok (120 / 90 ticks, eerste aanval 60), pompslag fase 1 (vaste helften) en fase 2 (op x van P1), schoepenzwiep (y 36–60, 300 px), om en om in fase 2; per aanval een vlag `aanloop`/`actief` die tests en HUD/audio lezen | Tests: elke aanloop ≥ 30 ticks; pompslag raakt P1 op de vloer in het vlak, niet P1 in de lucht of op de plank; zwiep raakt P1 op de plank van de echo en op de top van een sprong, niet op de vloer en niet boven 60 px; niets raakt de echo of P2 |
| **B-7** | **Fase 1**: schot/kern als `Pantserdoel` dat weer dichtgaat (300 ticks of drempel), merkplek op (300, 36), spuigaten met max. 2 Kadelopers (30 ticks gloeien, 30 ticks inactief), geen adds vóór opening 1 | Tests: solo-script "sla het schot één keer en loop weg" breekt het op `slag + D + 3` bij elke D; een gewone treffer op het intacte schot doet 0; precies 4 openingen in een run die elke opening tot de drempel slaat; in co-op leeft een merk 150 ticks (C-12e); echo uit: het schot breekt nooit |
| **B-8** | **Fase 2**: het rad op `x_rad = D + 34` (debugmenu zet het bij een wissel van D, SL-05), 15 SE per treffer van P1/P2, 5 van de echo, 2 treffers (P1 + P2, `kant_treffers` uit data) of 180 ticks → 20 trillen → 60 draaien; vloerteken (GMB-04); fasewissel naar de kant waar P1 niet is | Tests: (1) per D: sprong + aanval op elke x van de vloer (stap 4 px) raakt het rad nooit; (2) per D: keren tegen de muur + bounce raakt het, met de late bot (bounce 4 en 8 ticks te laat) nog steeds; (3) lancering + neerslag geeft 2 treffers zonder landen; (4) co-op: bounce op P2 op elke x onder het rad raakt het |
| **B-9** | **Scripted boss-runs** (`boss_bot.gd`, naar het voorbeeld van `flow_bot.gd`): solo en co-op, per D = 60 / 90 / 120 / 180; plus de C-16-runs (echo uit; P2 slaat nooit) en een run met drop-out van P2 in fase 1 en in Wankel | Elke run haalt MP-1 ≤ 300 ticks (verwacht ≤ 60 bij D = 60), de echo breekt nooit; de C-16-runs halen in 6000 ticks geen finisher; de scripted solo-run duurt bij D = 60 **90–150 s** (§3.9); de duur per deel komt in een tabel voor de Combat Designer |
| **B-10** | **Meetlog**: nieuwe events `BOSS_FASE` (1, 2, wankel), `SCHOT_BREUK`, `KERN_DICHT` (reden: drempel/tijd), `RAD_TREFFER` (bron, actie: bounce/lancering/vang/stuit), `RAD_DRAAI`, `BOSS_AANVAL` (soort, helft, raak/mis) naast de bestaande `BOSS_START`, `FINISHER_START`, `FINISHERSLAG`, `BOSS_VERSLAGEN` | De events staan in het log van B-9; GM-a (tijd tot de eerste `SCHOT_BREUK`) en GM-b (`RAD_TREFFER` per minuut per actie) zijn eruit te rekenen |
| **B-11** | **Leesbaarheid in placeholder-beeld**: E-02t en E-14j op de boss-merken; de "tink" bij 0 SE (VJ-07); tells (stofstrook pompslag, lichtstreep zwiep, gloeiende spuigaten, trillend rad); schermschok bij schotbreuk (6 ticks, 2 px), radtreffer (3 ticks, 1 px), finisherstart; elk met een vlag die een test kan lezen | Zichtbaar in de build; de vlaggen in de tests van B-6–B-8 |

**Volgorde:** B-1 → B-2/B-3/B-4 (parallel aan T8a) → B-5 → B-6 → B-7 → B-8 → B-9/B-10, B-11 doorlopend. **Raming:** **4–5 maak-taken** Gameplay Programmer (B-1–B-4: 1–2; B-5–B-7: 1–2; B-8–B-11: 1–2), plus **1 maak-taak Combat Designer** om de waarden te zetten met de B-9-tabel (een nieuwe versie van dit document en `slice.csv`). Binnen de 3–5 van T8b; de Animator-taak komt erbij (§9).

---

## 7. Wat van D afhangt

D = 60 is de werkaanname; het debugmenu kan 60 / 90 / 120 / 180 zetten (bereik 1–3 s). Elke regel hieronder is per D getest in B-1, B-7, B-8 en B-9.

| Maat | Formule | D = 60 | 90 | 120 | 180 |
|---|---|---|---|---|---|
| Echo knalt na je slag | `D + 3` | 63 | 93 | 123 | 183 |
| Merk leeft (solo) | `D + 30` | 90 | 120 | 150 | 210 |
| Merk leeft (co-op, C-12e) | 150 | 150 | 150 | 150 | 150 |
| Doelstreep vóór de knal (E-02t; kan omdat D ≥ 30) | 30 | 30 | 30 | 30 | 30 |
| Snelheid Kadeloper/Schotdrager (px/tick) | `min(0,5; 44/(D − 27))`, grens **≤ 0,70** (gdd v0.8 §4.8.5, D_max = 90) | 0,50 | 0,50 | 0,47 | 0,29 |
| Snelheid Dwaallicht | `min(0,25; 44/(D − 27))` | 0,25 | 0,25 | 0,25 | 0,25 |
| Keren: ontmoeting na het keren | `D/2` ticks, op `D` px | 30 / 60 px | 45 / 90 | 60 / 120 | 90 / 180 |
| Keren: afzet na het keren (zonder sturen in de lucht) | `(2D − 130)/4` | −2,5 (spring op het keerpunt) | 12 | 27 | 57 |
| Vlakke vloer vóór de muur (L-13 b) | `D + 24` | 84 | 114 | 144 | 204 (lichaam op 252: ok) |
| Middelpunt rad van de muur | `D + 34` | 94 | 124 | 154 | 214 |
| Hurtbox rad van de muur | `D − 14 … D + 82` | 46–142 | 76–172 | 106–202 | 166–262 (10 px over het lichaam, mag: GM-07) |
| Solo-lancering: wachten / venster | `D − 21` / 19 | 39 / 19 | 69 / 19 | 99 / 19 | 159 / 19 |
| Langste verwachte stilstand (MP-1) | max(lancering, `D + 3` in Wankel) | ≤ 63 | ≤ 93 | ≤ 123 | ≤ 183 |

**Niet van D afhankelijk:** de maat (120 / 90 ticks), de aanlopen, de kern-opening (300), het rad per kant (180), de drempels, de schade, de finisher (600 → 120 ticks).

**Let op bij D = 60:** na het keren is de echo maar 120 px achter je, dus je springt **op het keerpunt** of vlak ervoor en stuurt in de lucht bij (in de lucht bepaal je `v.x` zelf, dus de ontmoeting is ruim te halen); het plank-signaal (E-07d, ≤ 130 px) staat dan al aan op het moment dat je keert. De late bot van B-8 toetst dit.

---

## 8. Afwijkingen en open punten (voor de Lead Game Designer)

Geen CEO-vraag nodig: alles ligt binnen de besluiten (#2, #51, D = 60) en is balans of detail, dus aan de LGD (rolbestand: escalatie bij balansconflicten).

| # | Punt | Voorstel | Wie |
|---|---|---|---|
| 1 | **Duur van de boss** | **Besluit LGD:** scripted 90–150 s; verlengd met een 4e opening (GMB-11) en meer kanten (2 treffers per kant, 600 SE in fase 2), alles in data. GM-acceptatie en WS-05 krijgen dezelfde waarde | LGD (#187) |
| 2 | **SE en drempels** (GM-03) | **Besluit LGD:** akkoord met SE plus drempels; door punt 1 nu **1500 SE** in plaats van 600 (zelfde verhoudingen) | LGD (#187: GM-03 op 1500) |
| 3 | **Rad-treffer 15 SE** (GM-07) | **Besluit LGD:** akkoord. Per kant nu 2 treffers in plaats van 3 (punt 1) | LGD (#187) |
| 4 | **Schoepenzwiep op y 36–60**; op je echo staan is geen ontwijking (GM-05b) | **Besluit LGD:** akkoord | LGD (#187) |
| 5 | **Paren** | **Besluit LGD:** L-13 (d) blijft; elke golf een E-paar (≤ 32 px), K-paren (40–44 px) erbij als extra; afstandsregel per paar met startafstand in data (VJ-05, §2.6) | — |
| 6 | **Kadeloper 0,5 px/tick bij D = 60** | **Besluit LGD:** akkoord, binnen de grens van 0,70 px/tick (gdd v0.8 §4.8.5) | — |
| 7 | **45 ticks onkwetsbaar** na een treffer op P1 (VJ-02) | **Besluit LGD:** komt in de gdd bij LM-05 | LGD (#187) |
| 8 | **O-17 en O-18** | **Besluit LGD:** O-18 voor de slice gesloten (VJ-06); O-17 gaat terug naar fase 3 (§4) | LGD |
| 9 | **Co-op te snel** (MP-7): verwacht co-op ± 0,95 × solo, maar onzeker (P2 is onkwetsbaar, O-13) | Eerst fase 2 ×1,25 in co-op (§3.8), pas na B-9 | Combat Designer na B-9; T11 |
| 10 | **Vierde vijandtype** (OW-4): niet in de slice (§2.5) | **Besluit LGD:** de plek blijft leeg; OW-4 blijft open tot de mijlpaal-test | LGD, World & Level Designer |
| 11 | **Verdeling over de kamers** (§2.6) is een voorstel binnen `wereld.md` §2.2 | De World & Level Designer neemt het over of meldt een afwijking | World & Level Designer |

**Playtestvragen:** GM-a–GM-d uit `gemaalmeester.md` §8 blijven; meetbaar met B-10. Extra voor de mijlpaal-test (QA Lead): *ketting* (VJ-05): zag de speler in S6 een merk naar een tweede vijand overspringen? (kaartvraag naast M2).

---

## 9. Wat Animator, UI/UX en Audio nodig hebben

**Regels voor elke tell:** leesbaar in silhouet op 640 × 360 en in de grijze beginstaat (niet alleen kleur); de aanloop toont **waar** het vlak komt (helft, hoogte), niet alleen **dat** er iets komt; elk actief vlak valt samen met het frame waarin de beweging het verst is.

### 9.1 Animator (met de Gameplay Programmer; tijden in ticks = frames bij 60 fps)

| Wie | Animaties en tijden |
|---|---|
| Kadeloper | lopen (cyclus), haakslag: aanloop 30 / actief 6 / herstel 20, stil na treffer 30 (knik), dood (lost op in donker water), uit de stoom stappen 30 (adds) |
| Schotdrager | als de Kadeloper + schotstoot 30/6/20; "tink" op het schot (4); schot breekt en valt (12) |
| Dwaallicht | zweven (cyclus), aanloop 30 (licht zwelt), duik 8, terug 40, stil na treffer 30 (flakkert), dood |
| Gemaalmeester | aarzeling bij de sjaal 60; pompslag: stang heft naar links/rechts 40 (fase 1) of 30 (fase 2), slag 6, ligt 24; schoepenzwiep: schoepen draaien op 30, veeg 8, uitdraaien 20; spuigaten gloeien 30; schot dicht (20), schot breekt (12, met scheur en stoom), kern open (puls, cyclus); fasewissel 60 (stoom, rad hijst); rad trilt 20, draait 60; Wankel (hapert, cyclus), merkplek gaat open (20); oplossen in licht (GM-10) |
| Gedeelde echo | finisher 120 (half licht, half schaduw; C-14) |

### 9.2 UI en UX (T10)

- Doelstreep, bereikcirkel, rand en kettinglijn (E-02t, E-14j) ook op de boss; het **vloerteken** onder het rad (GMB-04).
- Levenspunten van P1 (5 + lampglas) en de 45 ticks onkwetsbaar (knipperen).
- **Voortgang van de boss zonder balk** (voorstel; de UX Designer beslist): de ketel dooft een stap per opening, het rad krijgt scheuren per kant, zodat je de beat ziet; geen getal in beeld.

### 9.3 Audio (T8d)

| Moment | Geluid |
|---|---|
| Maat | carillon-tel op het begin van elke maat (120 / 90 ticks): het ritme dat je leert (GM-04) |
| Pompslag | sissende zuiger die stijgt gedurende de aanloop, dreun op de slag |
| Schoepenzwiep | aanzwellend water-gesuis, veeg |
| Spuigaten | borrelen, 30 ticks |
| Schot | "tink" bij 0 SE; breuk: krak + stoom (+ schermschok); dichtschuiven |
| Kern / rad | treffer op de kern (dof, warm); op het rad (metalen klank); rad ratelt 20 ticks vóór het draait |
| Merk | carillon-voorslag van de doelstreep (E-02t), aftelling (E-14b), knal en kettingschakel (oplopende toon per schakel) |
| Wankel en finisher | carillon valt stil; finisher: jullie slagen als versnelde tellen, slot in licht |
| Vijanden | Kadeloper: schrapen bij de aanloop; Schotdrager: roestig schot; Dwaallicht: zoemen dat stijgt bij de aanloop |

---

## 10. Checklist T8b (review LGD)

- [ ] Max. 4 vijandtypes: **3** (Kadeloper, Schotdrager, Dwaallicht), de boss niet meegeteld (R-V4).
- [ ] Twee verplichte momenten met een samenwerkingsactie (schot, rad) en de finisher, elk solo én co-op in dezelfde arena (C-16).
- [ ] Elk venster ≥ 10 ticks (kleinste: 17), elke aanval ≥ 30 ticks aanloop met tell in beeld en geluid.
- [ ] Verwachte MP-1 ≤ 63 ticks bij D = 60 (≤ 183 bij D = 180); scripted run meet het (B-9).
- [ ] Scripted run 90–150 s per modus bij D = 60 (§3.9).
- [ ] Elke golf heeft een E-paar (L-13 d); vijand-`v` ≤ 0,70 px/tick.
- [ ] Het rad niet te raken zonder bounce, lancering of vang, per D (B-8).
- [ ] Geen contactschade; de echo en P2 krijgen nooit iets.
- [ ] Werkaanname genoemd (§0); maten in D (§7).

## 11. Wijzigingen

| Versie | Wat |
|---|---|
| 0.1.1 | Lead-review PR #185 (klein): duur scripted 90–150 s via een 4e opening en meer kanten (1500 SE, 2 treffers per kant, §3.3, §3.5, §3.9); L-13 (d) blijft: E-paar per golf, K-paren als extra, afstandsregel per paar in data (VJ-05, §2.6), Schotdrager in een E-paar; grens `v` ≤ 0,70 (VJ-03, §7); merk in co-op 150 ticks (C-12e; §3.6, §3.7, §7); verwijzingen naar gdd v0.8 en gemaalmeester.md v0.2; O-17 terug naar fase 3; §8 met de besluiten van de LGD. |
| 0.1 | Eerste versie (T8b, #84): drie vijandtypes met gedeelde regels (VJ-01–VJ-07) en plaatsing, de Gemaalmeester in detail (GMB-01–GMB-13, fasen, aanvallen, vensters, finisher, co-op), D-tabel voor D = 60 … 180, bouwopdracht B-1–B-11, afwijkingen voor de LGD, wat Animator, UI/UX en Audio nodig hebben. |
