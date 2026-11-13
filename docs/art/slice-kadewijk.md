# Slice-art Kadewijk: kleurscript, lichtovergang, tileset, stijlregels vijanden (deel 1) en eindkwaliteit S1–S9 (deel 2–5)

Versie 0.5.2 · Eigenaar: Art Director · Issue [#85](https://github.com/cesarvangerwen-glitch/echoborn/issues/85) (T8c, deel 1–5) · Hoort bij `docs/art/bible.md` v0 en `docs/art/assetlijst.md`
Bronnen: `docs/design/wereld.md` v0.2 §2 (slice Kadewijk), `docs/design/combat/slice-vijanden-en-boss.md` v0.1.1 (§2, §3, §9), `docs/narrative/verhaal-v2.md` §4.3 en §6, `docs/art/ui-stijlgids.md` (merk, klokring, `#ff475c`), fasekader fase 2 v0.4 §2 (T8c) en §4.

## 0. Werkaanname (kader §5)

| Bron | Wat dit deel ervan gebruikt |
|---|---|
| CEO-besluit #18 | 2D pixel art op 640×360 (Deck 640×400) met dynamisch 2D-licht |
| CEO-besluit #51 (1A) en pitch v0.4 | Wereld en echo eerst grijs, ze leven op met het licht; water is beeld, geen speellaag |
| CEO-besluit 2026-11-12 (1) | Fase 2 loopt parallel en slice-art mag starten. Volgens §4, regel 3 van het kader komt **eindkwaliteit alleen op maatvaste kamers**. Op dit moment is **geen enkele slice-kamer maatvast**. |
| CEO-besluit 2026-11-12 (D = 60) | Het vloerteken onder het rad schuift mee met D (`D` tot `D + 68` px). Verder hangt hier niets van D af. |
| F1 (#65) | Gehaald: de R5-scène is de maatstaf voor eindkwaliteit |
| Maatvast (kamerdoc v0.2 §8, #212, PR #220) | **S1 en S3 zijn maatvast** (bots groen op D = 60, `Visie-review: past` van de CD, LGD bevestigd). S2 en S4 zijn maatvast (CD `past` in #212, PR #221 gemerged; LGD bevestigd in #223); hun eindkwaliteit volgt in deel 3. Deel 2 (§9) maakt S1 en S3 op eindkwaliteit. |
| **Werkaanname AD (deel 1)** | Alles in deel 1 is **placeholder** (`_placeholder` in de bestandsnaam). Ik maak alleen wat niet van kamermaten afhangt: palet, regels, tegels die je in elke layout kunt hergebruiken, en concepten. Er staat **niets in `game/`**. De Technical Artist zet de tegels pas in `game/art/wereld/kadewijk/` als de importconventie er is (assetlijst §4) en de eerste kamer maatvast is. |

**Weggooirisico:** klein. Het palet, de overgang en de stijlregels hangen niet af van de layout. De tegels zijn generiek (16×16 en tegelbaar). De concepten volgen de maten van combat §3.2 alleen als schets. Verandert de echo of de boss, dan gaan alleen de twee concept-sheets opnieuw. Opnieuw maken kost ± 2 s: `python3 docs/art/slice/bron/genereer_slice_deel1.py`.

---

## 1. Kleurscript

`docs/art/slice/kleurscript_kadewijk_placeholder.png` toont de route S1 → S9 en terug naar S1, met per beat de waterstand, de toestand, de hoofdlichtbron en de **gemeten** gemiddelde chroma (CIELAB).

| Beat | Toestand | Wat kleur heeft | Chroma |
|---|---|---|---:|
| S1 Kade-ingang | grijs, `s = 0` | alleen de lichtpoel van de lantaarn (licht = kleur), de amber sjaal van P1. Het grote donkere vlak rechts met de zwarte cirkel is **het gemaal in de verte, nog uit**: een donker boograam in baksteen. Het is het doel van de wijk, en het is hier bewust de donkerste vorm in beeld. | 6 |
| S2 Kadegang | grijs | niets in de omgeving; de bovenranden en kernen van de vijanden zijn het enige rood | 3 |
| S3 Vismarkt | grijs | één kraamlamp, de rode vijanden in de arena | 7 |
| S4 Brugkloof | grijs | koude bundels door de kloof | 3 |
| S5 Sluiswachtershuis | grijs | een kleine warme lamp bij de twee koppen. Het is het enige warme interieur vóór het gemaal (verhaal §4.3) | 5 |
| **S6 Gemaalplein, trap 1** | grijs, `s = 0 → 1` | **het gemaal gaat aan**: boograam en ramen van het gemaal warm, de lichtpoel brengt half en vol kleur terug rond het gemaal. Dit is de eerste keer dat kleur terugkomt zonder lantaarn. | 12 |
| S7 Sluiskelder | grijs, `s = 1` | warme gloed van de sokkel (Neerslag), de rode Dwaallichten boven het water | 4 |
| S8 Machinehal | grijs, `s = 1` | **alleen rood** (kern, bovenranden, de ketel als het schot breekt) en de merkkleuren. Er staat geen warm licht in de arena: dat is de spanning vóór de beloning. | 3 |
| **S9 Lage kade, trap 2** | `s = 1 → 2`, **kleur** | de kleurgolf (§2), de wijk warm, de getijdenrand zichtbaar | 20 |
| S1 terug | kleur | stadsgloed, het sluiswachtershuis verlicht | 20 |

**S1 en "S1 terug" zijn hetzelfde beeld in twee toestanden**: dezelfde plek, dezelfde lantaarn en hetzelfde gemaal, eerst grijs met hoog water (`s = 0`), dan in kleur met laag water (`s = 2`) en het gemaal aan. Zo zie je wat het oppompen met één plek doet, net als in de R5-scène.

**Regels die het kleurscript vastlegt:**
1. **Tot trap 2 blijft de wijk grijs** (gemiddelde chroma ≤ ± 12). Kleur komt alleen uit lichtbronnen. Zo blijft S9 de grote stap (± ×2 tegenover S6, ± ×6 tegenover S2).
2. **Trap 1 is "eerste licht", geen kleur voor de wijk**: het gemaal wordt een lichtbron en zijn poel krijgt kleur terug, de rest blijft grijs. Zo voelt de speler de kernloop één keer klein voordat de golf komt.
3. **De boss-arena is de koudste beat.** Daar staat geen warm licht, alleen rood. Warm licht hoort na de boss (L-14e: warm, nooit `FelLicht`).
4. In het grijs is **rood alleen van vijanden**, amber/cyaan alleen van spelers en merken, en warm alleen van lichtbronnen. Drie families die elkaar niet raken (§4.2).

---

## 2. Lichtovergang grijs → kleur

**Studie** (geen kamer, geen kamermaten): `lichtovergang_kadewijk_x2_placeholder.gif` (beweging), `lichtovergang_kadewijk_strip_placeholder.png` (6 momenten met het aandeel grijs, half en kleur), `lichtovergang_voor_640x360_placeholder.png` en `lichtovergang_na_640x360_placeholder.png` (ware maat). De studie gebruikt de tegels en props van §3: kade, gracht met loopbrug onder water, gemaal met pomprad en boograam, twee straatlampen, P1 en de echo.

**Specificatie voor de Technical Artist** (bible §5 uitgewerkt; startwaarden):

| Wat | Waarde | Waarom |
|---|---|---|
| Startpunt | Het gemaal (in de studie het middelpunt van het pomprad), in **wereldcoördinaten van de wijk** | Een kamer buiten beeld rekent dezelfde functie uit als ze laadt. Je komt ze dus al gekleurd tegen. |
| Voorkant *half* | straal `r_h(t) = v · t`, **v = 300 px/s** | Een scherm (± 550 px van het gemaal) is in ± 2 s gekleurd (bible: ± 2 s) |
| Voorkant *vol* | `r_v(t) = v · (t − 0,4 s)` | De banden van bible §5: eerst half (chroma 42 %), dan vol |
| Rand van elke voorkant | **10 px, Bayer 4×4 gedithered** (geen alfa, geen zachte rand) | Bible §2: overgangen alleen met ordered dithering |
| Echo | kleurt **0,5 s** nadat de vol-voorkant hem raakt | Bible §5: "als iemand die wakker wordt" |
| Ramen en straatlampen | gaan aan als de half-voorkant ze raakt, **per raam** met een vertraging van 0–40 px afstand (willekeurig, vast per raam) | De wijk gaat aan, niet een masker dat over het beeld schuift |
| Water | zakt in **180 ticks** van stand 1 naar 2, tegelijk met de golf (gdd LM-06, K3) | De getijdenrand komt vrij terwijl de kleur komt |
| Wat zijn kleur altijd houdt | *gloed*, verlichte ramen (emissief), vijanden (lijf, kern, bovenrand), P1 | Bible §4.1.5 en §4.2 |
| Lichtpoel van een lamp | band 2 → half, band ≥ 3 → vol, **in elke toestand** | Bible §5: licht = kleur |
| Stilstand | geen: geen camera-overname en geen invoerblokkade (WS-09a) | De golf speelt in het speelveld |

**Hoe het technisch kan (voorstel, de TA beslist):** de tegels bestaan ook als **index-atlas** (§3.2). De shader kiest per pixel de ramp (grijs, half of kleur) uit `materialen.csv` met de afstand tot het gemaal en de tijd sinds `GEMAAL_VOL` (trap 2), plus de lichtband van het 2D-licht. Dan is er één atlas en geen drie, en blijven grijs en kleur altijd gelijk aan het palet. De drie RGB-atlassen zijn er voor previews, en als terugvaloptie als de LUT op de Deck te duur is.

---

## 3. Tileset-opzet en eerste herbruikbare set

### 3.1 Opzet

| Regel | Waarde |
|---|---|
| Tegelmaat | 16×16 (bible §2), atlas van 16 kolommen, één naam per tegel in `tiles/tiles_kadewijk.csv` (naam, atlas, x, y, w, h, frames) |
| Toestanden | elke tegel en prop in **kleur**, **half** en **grijs**, met dezelfde layout (`tiles_kadewijk_16_{kleur,half,grijs}_placeholder.png`, `props_kadewijk_{…}_placeholder.png`) |
| Index-atlas | `…_index_placeholder.png`: R = materiaal-id, G = tint × 32 + 16, A = 255 (leeg = 0). Het palet staat in `tiles/materialen.csv` (id, materiaal, staat, t0–t7). |
| Basistint | Een tegel slaat de tint op bij **omgeving 2, lichtband 0**. De engine telt de lichtband erbij (0–4) en trekt in de grijze toestand 1 af (bible §3). |
| Varianten | m1/m2 per vlak tegen herhaling; hoog/laag voor een wand die naar onder donker wegloopt (bible §4.1.4) |
| Geen omgevingscontour | vorm alleen door tinten (bible §2) |
| Animatie | per frame getekend, niet gedraaid (bible §2): water 4 frames, pomprad 8 frames |
| Naamgeving | `<materiaal>_<deel>_<variant>`; frames als `_f0…`; props met maat erbij als die afwijkt (`pomprad_64x64_8f`) |

### 3.2 Wat er nu is (`docs/art/slice/tiles/`, overzicht ×3 in `tileset_kadewijk_overzicht_placeholder.png`)

| Groep | Tegels / props |
|---|---|
| **Kade** (blauwe hardsteen) | dekplaat links/midden ×2/rechts, wand hoog ×2, wand laag ×2, wand met **meerring**, **getijdenrand** ×2 (klimop op de oude waterstand), voet bij het water ×2, kelderbodem ×2, rooster (spuigaten, kelder) |
| **Gemaal en huizen** (baksteen) | baksteen ×2, donker ×2, dekrand, **Vlaamse speklaag**, **duikerboog** links/rechts, duiker binnen, stenen trap op/neer/vulling |
| **Luik (V-01, poort van de lus)** | 32×16 dicht **met zichtbare scheur** (L-03), en gebroken |
| **Water** | oppervlak 4 frames, diep water ×2, **loopbrug onder water** (lijf water-tint 2, contour tint 3, bible §4.5 en §7.5) |
| **Hout en sluis** | loopbrug links/midden/rechts met ijzeren beugels, paal, **sluisdeur** boven/midden/onder (planken, geroeste band, klinknagels) |
| **Props** | **pomprad** 64×64, 8 frames (`pomprad_8f_x3_placeholder.gif`), straatlamp uit/aan en halo (3 ringen, kruisstralen; bible §4.2), **boograam** van het gemaal uit/aan (aan: koperen machine erachter), bolder, sluisbalk |

**Nog niet gemaakt:** de achtergrondlagen (S-05), lantaarn en FelLicht op eindkwaliteit (S-07), volumetrische bundels als asset (S-08) en het interieur van de machinehal. Die volgen in deel 2, op maatvaste kamers.

**Nieuwe ramps** (bible §3, 8 tinten met hue-shift; `palet_kadewijk.png`, gemarkeerd met *):

| Ramp | Tint 0 → 7 | Waarvoor |
|---|---|---|
| roest | `#0e080e` `#24141c` `#3e2024` `#5a2e2c` `#744238` `#8c5a4c` `#a47668` `#bc9688` | sluisschotten, banden, het schot van de Schotdrager en de Gemaalmeester. Bewust bruinrood en grijzig, ver van amber |
| vijandlijf | `#05040a` … `#4e3f58` | lijf van vijanden en de boss (vol, donker, koel) |
| vijandkern | `#2a0610` `#4e0c1a` `#7a1424` `#a81e30` `#d42e42` **`#ff475c`** `#ff8a90` `#ffd4d0` | kern, bovenrand en tells. Tint 5 is de vijandkleur uit de UI-stijlgids (open punt 4) |

---

## 4. Stijlregels voor de vijanden en de Gemaalmeester (concepten)

Bladen: `concept_vijanden_x4_placeholder.png` (per type: silhouet, idle, aanloop 0–15 en 15–30, actief, stil na een treffer, merk P1, merk P2; telkens in grijs/donker en kleur/verlicht), `concept_vijanden_luminantie_deuteranopie_x2_placeholder.png`, `concept_gemaalmeester_x2_placeholder.png` (fase 1 met pompslag, opening, fase 2 met rad en zwiep, Wankel), `concept_gemaalmeester_luminantie_deuteranopie_placeholder.png`.

### 4.1 Silhouet

| | Silhouet (beeld; de hurtbox van combat blijft) | Lezen in één oogopslag |
|---|---|---|
| **Kadeloper** | laag, gebogen rug met stekels (slib en riet), kop vooruit, **bootshaak**; ± 30×26 (hurtbox 16×24) | horizontaal, nooit rechtop zoals een speler (bible §6) |
| **Schotdrager** | het silhouet van de Kadeloper met een **staand roestschot** vóór zich (± 22×26); gebroken: de Kadeloper met een stuk schot op de grond | dezelfde soort (code: één type met een vlag), maar een harde verticale plaat. Roest is het teken van **pantser**, net als op de boss |
| **Dwaallicht** | een gedoofde lantaarn op drift: ijzeren kooi om een **rode** kern, rafelige sluier van stekels eronder (± 20×24, hurtbox 16×16) | het enige zwevende type. Het licht is **rood, nooit warm**: warm licht is van de speler (§1 regel 4) |
| **Gemaalmeester** | een gebogen werkman van machine: ketel als romp, stoomkap als kop met twee doffe ogen, schoorsteen, drijfstang als arm; lichaam x 252–348 | **geen gezicht met tanden** (verhaal §6: droevig, niet boosaardig). Rode bovenrand zoals elke vijand |

### 4.2 Kleur en leesbaarheid

1. **Elke vijand en de boss:** vol donker lijf (*vijandlijf*), contour van 1 px bijna-zwart, en een **bovenrand van 2 px**: een gloeiende lijn in vijandkern 7 met rood eronder (5 in het donker, 4 verlicht), plus een **rode kern** en witte ogen. In het donker (`s < 2`) gloeien kern en rand feller (VJ-06).
2. **Vijandkleuren houden hun kleur in elke toestand** (het zijn figuren, bible §4.1.5). In een grijze wijk zijn ze dus het enige rood.
3. **Amber en cyaan komen nooit in de art van een vijand of de boss.** Ze verschijnen erop alleen als **merk-overlay**: merkkern (UI-sprites `merk_kern_*`), **bereikcirkel** met straal E = 32 px, gestippeld 2 aan / 2 uit, in de eigenaarskleur (E-14j), en een gestippelde rand in de eigenaarskleur zolang de vijand binnen E ligt. Zo zegt kleur altijd **van wie het merk is**, ook op de boss.
4. **Leesbaarheid gemeten** (bible §6 regel 4: ΔL\* ≥ 40 op vulling of contour; ring van 2–6 px rond de figuur in het concept-blad):

| Type | Toestand | ΔL\* lijf | ΔL\* contour | ΔL\* bovenrand |
|---|---|---:|---:|---:|
| Kadeloper | grijs | 14,5 | 18,5 | **68,7** |
| Kadeloper | kleur | 33,0 | 37,0 | **50,2** |
| Schotdrager | grijs / kleur | 8,7 / 21,0 | 12,6 / 24,9 | **74,6 / 62,2** |
| Dwaallicht | grijs / kleur | 9,7 / 2,6 | 12,6 / 24,9 | **74,6 / 62,2** |

   Op de achtergrond van het concept-blad (gevels tint 3) haalt het donkere lijf de 40 niet, maar **de bovenrand haalt hem overal (≥ 50)**. Daarom heeft de bovenrand nu 2 px met een gloeiende lijn (eerst was hij 1 px rood, ΔL\* 20 in kleur). **Nieuwe regel voor bible v1:** een vijand leest op zijn bovenrand en zijn kern, niet op zijn lijf. De bovenrand is daarom nooit korter dan de helft van de breedte van het silhouet, en ook een animatieframe verbergt hem niet.

5. **Kleurafstanden** (ΔE76 normaal / deuteranopie / ΔL\*; regel bible §7.1: ≥ 30 / ≥ 25, anders ΔL\* ≥ 20 of vorm):

| Paar | ΔE | ΔE deut. | ΔL\* | Haalt |
|---|---:|---:|---:|---|
| vijandkern 5 / amber sjaal | 60,0 | 32,4 | 12,4 | ja |
| vijandkern 6 (rand) / amber | 55,1 | 46,8 | 0,5 | ja |
| tell-rood (kern 4) / warm licht (gloed 4) | 60,0 | 33,2 | 24,0 | ja |
| tell-rood / amber | 59,4 | 38,4 | 23,5 | ja |
| roest 5 / amber schaduwkant | 37,8 | 35,1 | 5,4 | ja |
| merk amber / roestschot (roest 3) | 74,4 | 73,6 | 46,3 | ja: het merk leest op het schot |
| merk cyaan / vijandlijf | 90,0 | 77,8 | 78,9 | ja |
| vijandkern 5 / FelLicht 5 | 93,9 | 55,9 | 30,1 | ja |

### 4.3 Tells (combat §9: "toont **waar** het vlak komt, niet alleen **dat**")

- **Eén tell-taal voor alle vijanden en de boss:** het **vlak waar de aanval komt** krijgt een rode dither (vijandkern 3 → 4) die van 25 % (tick 0–15 van de aanloop) naar 75 % (tick 15–30) loopt, met een gestippelde bovenlijn. **Actief** = vol vlak in vijandkern 4 met een rand in tint 7, precies op het frame waarop de beweging het verst is.
- **Pose én vlak:** de haak gaat omhoog (Kadeloper), het schot gaat naar achteren (Schotdrager), de kern zwelt en een gestippelde lijn wijst naar de landingsplek (Dwaallicht). Op de boss heft de drijfstang zich naar de helft van de pompslag, en de schoepenzwiep toont een horizontale band op y 36–60. Zo is een tell ook **zonder kleur** leesbaar: in het luminantieblad zie je hem als een helder vlak.
- Tells zijn **rood, nooit warm en nooit wit-blauw**: warm is licht en beloning, wit-blauw is FelLicht.
- **Stil na een treffer (30 ticks):** het lijf zakt 1 px, de ogen gaan dicht tot een streep en de kern dooft een tint.

### 4.4 Gemaalmeester

- **Schot** = roest met klinknagels en banden, op x 276–324, y 12–60 (GMB-02). Roest betekent dus overal "pantser: hier moet een merk op".
- **Opening** = de kern gaat open in vijandkern 4/6/7 met een scheur en grijze stoom (nooit FelLicht, GMB-06).
- **Rad** = ijzer en hout aan een balk, met een rode as. Onder het rad ligt een **vloerteken** van koperen olie met lichtstippels, van `D` tot `D + 68` px van de muur (GMB-04; het schuift mee met D, dus komt de positie uit data).
- **Wankel** = de merkplek op de ketel als rode peilmerk-ring, tot het merk van de speler erop staat.
- **De machinehal heeft tegenlicht achter de boss** (een koude wand, 2 tinten lichter rond het silhouet), anders verdwijnt het donkere lijf in de donkere hal. Dit is een eis voor de kamer S8 als die maatvast is.

---

## 5. Wat de andere rollen nodig hebben (één regel per rol)

| Rol | Wat |
|---|---|
| **Animator** | De poses en tijden uit combat §9.1 op deze silhouetten (idle, aanloop 30 met het tell-vlak in twee stappen, actief 6 op het verste frame, stil 30, dood), met de bovenrand van 2 px zichtbaar in elk frame en een uitgerekend tell-vlak per aanval; eerst als placeholder, eindkwaliteit pas op maatvaste kamers. |
| **Technical Artist** | Een palet-LUT-shader op de index-atlas (`materialen.csv`; grijs/half/kleur plus lichtband), de kleurgolf uit §2 (v = 300 px/s, vol 0,4 s later, echo +0,5 s, dithered rand van 10 px, in wereldcoördinaten van de wijk), de importconventie (filter uit, geen mipmaps) en de meting op de Deck. |
| **UI Artist** | De bereikcirkel (E = 32, gestippeld 2/2, eigenaarskleur), de merkrand op een vijand binnen E en het vloerteken onder het rad als sprites bij de bestaande merk-set in `game/art/ui/wereld/`, nooit in rood (rood = vijand), en de boss-voortgang zonder balk (ketel dooft, rad scheurt; combat §9.2). |

---

## 6. Open punten

| Punt | Wie | Wanneer |
|---|---|---|
| Eindkwaliteit S1 en S3 | Art Director | **Gedaan in deel 2 (§9)** |
| Eindkwaliteit S2 en S4, snelluik S1, schaduwklep | Art Director | **Gedaan in deel 3 (§10)** |
| Eindkwaliteit S5, S6, S7 en de luiken | Art Director | **Gedaan in deel 4 (§11)** |
| Eindkwaliteit S8 en S9 | Art Director | **Gedaan in deel 5 (§12)**; daarmee staat de hele Kadewijk op eindkwaliteit |
| Koppeling van S5–S7 en de objecten | Technical Artist met GP | **Gedaan in #244** |
| Koppeling van S8/S9, de deuren en het hoogwater als vaste stukken, `fps_vol` van het rad (§12.4) | Technical Artist met GP | Volgende stap; SM-review (code in `game/`) |
| Koppeling van S1/S3 aan de kamerscènes | Technical Artist | **Gedaan in #230** |
| Koppeling van S2/S4, de vaste stukken van S2 en de schaduwklep (§10.4) | Technical Artist (schaduwklep met de GP) | Volgende stap; SM-review (code in `game/`) |
| Regels van §4.2 (bovenrand 2 px, tell-taal, amber/cyaan alleen als merk-overlay) en de drie nieuwe ramps opnemen in bible v1 §3 en §6, met de drempels: **bovenrand ΔL\* ≥ 50** tegen de directe achtergrond (ring van 2–6 px), in grijs én kleur (gemeten 50–75); de bestaande eis van **ΔL\* ≥ 40** op vulling of contour wordt voor vijanden "op bovenrand of kern" (het lijf haalt 2,6–37); kleurafstanden **ΔE76 ≥ 30, en ≥ 25 bij deuteranopie**, anders ΔL\* ≥ 20 of vorm (bible §7.1); en uit het kleurscript (§1) een **gemiddelde chroma ≤ ± 12 tot trap 2** (gemeten 3–12), en de beat na trap 2 minstens ± 1,5× de hoogste grijze beat (gemeten 20 tegen 12) | Art Director | Bible v1 |
| De LUT-shader en de kleurgolf in Godot 4.6, met de kost tegen het lichtbudget (≤ 20 LE) | Technical Artist | Vóór de eerste maatvaste kamer |
| Tegels naar `game/art/wereld/kadewijk/` met de importconventie (dan SM-review, code in `game/`) | Technical Artist | Met de LUT-shader |
| Is de Dwaallicht-sluier op Deck-grootte leesbaar als "zwevend"? | Art Director | Ware Deck-test (T7) |

## 7. Bestanden

Deel 1: alles in `docs/art/slice/` (behalve `eindkwaliteit/`) wordt gemaakt door `bron/genereer_slice_deel1.py` (deterministisch, ± 2 s). Deel 2: `bron/genereer_slice_deel2.py` maakt `game/art/wereld/kadewijk/` en `docs/art/slice/eindkwaliteit/` (deterministisch, ± 40 s; §9.6). Het script gebruikt het palet en de figuren van de R5-scène, het eigen pixelfont en de merk-sprites van de UI Artist. Het gebruikt geen externe assets (`docs/licenties.md` §2: eigen werk).

## 8. Wijzigingen

| Versie | Datum | Wat |
|---|---|---|
| 0.5.2 | 2026-11-13 | S8: de vaste loopkat en ketting zijn uit `midden`, want het rad van de Animator heeft een eigen loopkat (besluit AD, #266); de balk blijft. `controleer_stukbreedte.py` is nu de laatste stap van `genereer_slice_deel5.py`, en de run faalt bij een uitstekend loopvlak (EP/SM, #268). De norm voor de holle echo staat in bible v0.2 §6 regel 4a (besluit CD, #226). |
| 0.5.1 | 2026-11-13 | Stukbreedte (#85, na Lead-review #262): `ninepatch` laat bij een blok smaller dan 32 px de middelste kolommen vallen (de fix van de TA in 962105a, nu voor alle generatoren). Daarmee zijn de treden van de trap van S9 in S5 30 px breed in plaats van 32: alleen `s5_sluiswachtershuis_speelvlak_*` wijzigt, S9 blijft bit voor bit gelijk. Nieuw: `bron/controleer_stukbreedte.py` zoekt in alle kamers naar loopvlakken die buiten hun blok steken (op main 4 pixels in S5, nu 0). |
| 0.5 | 2026-11-13 | Deel 5 van T8c (#85): **S8 Machinehal en S9 Lage kade op eindkwaliteit** (maatvast, LGD in #83), de deuren van S8 en het hoogwater van S9 als vaste stukken, `fps_vol` = 6 voor het rad (besluit #244), `godot_controle.gd` generiek voor vaste stukken (§12). |
| 0.4 | 2026-11-13 | Deel 4 van T8c (#85): **S5, S6 en S7 op eindkwaliteit** (S5 met variatie per verdieping, LGD #227), de laag `gemaal_aan` voor trap 1 in S6, de objecten (breekbaar luik voor S7 en S9, **holle** schaduwklep, pompschoep en pompslag gelijk voor P1 en de echo, sluisklep, sokkel, rad), de geometrie uit `kadewijk_blokken.json`, het gemaal voor de kleurgolf op `S6/Gemaal` (§11). |
| 0.3 | 2026-11-13 | Deel 3 van T8c (#85): **S2 en S4 op eindkwaliteit**, het **snelluik** in S1 (PR #231) als eenrichtingsstuk, de vaste stukken per D van S2 (B3-wand, B3-blok), de **schaduwklep** zichtbaar (PR #232), renders, metingen en Godot-controle (§10). |
| 0.2 | 2026-11-12 | Deel 2 van T8c (#85): **S1 en S3 op eindkwaliteit** (§9): lagen per kamer in grijs, half, kleur en index in `game/art/wereld/kadewijk/`, eenrichtingsstukken per D als NinePatch, manifest, importconventie en overdracht aan de TA, renders en metingen in `docs/art/slice/eindkwaliteit/`, controle in Godot 4.6.3. |
| 0.1.1 | 2026-11-12 | Na de SM-review (PR #195): het gemaal in S1 benoemd, S1 en "S1 terug" als één plek in twee toestanden (§1), drempels voor ΔL\* en chroma in §6. |
| 0.1 | 2026-11-12 | Deel 1 van T8c (#85): kleurscript, lichtovergang, tileset-opzet met 46 tegels en 8 props in 3 toestanden plus index-atlas, 3 nieuwe ramps, concept-sheets voor 3 vijandtypes en de Gemaalmeester, metingen. |

---

## 9. Deel 2: eindkwaliteit S1 Kade-ingang en S3 Vismarkt

**Werkaanname (kader §5):** S1 en S3 zijn maatvast (kamerdoc v0.2 §8: bots groen op D = 60, `Visie-review: past` van de CD in #212, LGD bevestigd bij de merge van #220). De art volgt `kadewijk_layout.gd` op D = 60. **Wat van D afhangt zit niet in de kamerlagen** (zie §9.3), dus bij een andere D blijft de art kloppen. S2 en S4 zijn maatvast (CD `past` in #212, PR #221 gemerged; LGD bevestigd in #223); hun eindkwaliteit volgt in deel 3. Het gemaal van S6 bestaat nog niet. Voor de kleurgolf neem ik aan dat het rechts van S5 staat, op **wereld (4960, 150)** (`GEMAAL_WERELD`). De TA neemt de echte plek uit `wijk_gemaal` zodra die er is. Geen nieuwe CEO-besluiten nodig.

**Weggooirisico:** klein. De kamerlagen hangen af van de vaste maten van S1 en S3, en die zijn maatvast. Verandert er toch een maat, dan pas je de constante in de generator aan en draai je hem opnieuw (± 40 s).

### 9.1 Wat de kamers laten zien

| Kamer | Beeld | Grijs (`s = 0`) | Kleur (`s = 2`, "S1 terug" / na trap 2) |
|---|---|---|---|
| **S1 Kade-ingang** | Een **werf** onder de straat. De gang op 320 is de werfvloer, met werfkelders in de wand. Daar is de proloogdeur (x 460–480) en daarboven hangt de lantaarn. De galerij op 230 is een eiken loopbrug op ijzeren consoles. De keerwand links is de hardstenen grachtmuur met klimijzers. De kademuur rechts heeft een meerring en de getijdenrand. Boven de straat staat een gevelrij met trap-, klok- en tuitgevels, met het belfort erachter. Rechts in de verte staat **het gemaal**, met het rad in een ronde sleuf. | Alleen de **lichtpoel van de wandlantaarn** boven het checkpoint heeft kleur (licht = kleur). De rest is grijs en het gemaal is de donkerste vorm. Koude bundels in de lucht. | Alle ramen en lampen zijn aan, met een tweede lantaarn bij de keerwand. De gevels hebben hun kleur. Het gemaal is aan: boograam warm, het rad als silhouet tegen het licht van de machinekamer. Sterren en een warme bundel uit het belfort. |
| **S3 Vismarkt** | Een marktplein op 260 met kasseien. Daaronder zijn twee duikers met water te zien (beeld, geen speellaag). Links staat de **Waag**, een bakstenen toren waarvan de bovenkant op 70 de bovenroute is, met een hijsbalk. Op het plein staan twee **viskramen**: de luifel is het eenrichtingsplatform op 190 en eronder zitten een toonbank met ijs en vis, manden en kisten. Achter de arena staan de vishal (zuilengang met visbanken), de gevelrij, het belfort en de kerk. Over de markt hangt een vlaggenlijn (voorgrond, boven het speelveld). | **Eén kraamlamp** is aan (kleurscript S3). Haar poel kleurt de kraam, en de luifel houdt het licht naar boven tegen. De rest is grijs. De rode vijanden zijn het enige rood. | De markt leeft: ramen, straatlampen, de lamp aan de Waag, gekleurde luifels en vlaggen. |

Regels uit deel 1 die hier gelden: geen omgevingscontour (vorm alleen door tinten), overgangen alleen met Bayer-dithering, rood alleen voor vijanden, warm alleen uit lichtbronnen, wit-blauw (FelLicht) nergens in het decor (het ijs in de kraam is *steen*, niet de FelLicht-ramp), de wand naar onder een tint donkerder, en een verlicht raam is emissief.

### 9.2 Renders (`docs/art/slice/eindkwaliteit/`)

| Bestand | Wat |
|---|---|
| `s1_kade_ingang_{grijs,kleur}_640x360.png`, `s1_kade_ingang_vergelijking_x2.png` | S1 op ware maat en ×2, met P1 en de echo bij B1 (P1 net op de echo gebounced). De figuren zitten alleen in de render, niet in de assets. |
| `s3_vismarkt_{grijs,kleur}_960x360.png`, `s3_vismarkt_vergelijking_x2.png`, `s3_vismarkt_{grijs,kleur}_camera_640x360.png` | S3, de hele kamer en een camera-uitsnede, met golf 1 (3 Kadelopers, één met merk en bereikcirkel), P1 en de echo |
| `s1_kade_ingang_lichtovergang_strip.png`, `s1_kade_ingang_lichtovergang_x2.gif`, `s3_vismarkt_lichtovergang_strip.png` | **De lichtovergang op de echte kamers**: de half- en vol-voorkant van §2 (300 px/s, vol 0,4 s later, dithered rand van 10 px) vanaf het gemaal. Ramen en lampen gaan aan als de half-voorkant ze raakt. |
| `s1_kade_ingang_geometrie_controle_x2.png`, `…_d120_x2.png`, `s3_vismarkt_geometrie_controle_x2.png` | De collision-rechthoeken van `Layout.blocks()` over de art (cyaan = vast, geel = eenrichting). Bij D = 120 schuiven de galerij en de trede op 90 mee. |
| `godot_controle_s1_s3.png` | **In Godot 4.6.3**: de lagen als `Sprite2D` en de eenrichtingsstukken als `NinePatchRect` op `Layout.blocks()`, met de collision-randen erover (`bron/godot_controle.gd`) |
| `s3_vismarkt_leesbaarheid_x2.png` | Luminantie en deuteranopie van de arena in grijs |
| `kadewijk_eenrichting_x4.png` | De twee NinePatch-stukken (galerij, trede) in de drie toestanden |

### 9.3 Assets (`game/art/wereld/kadewijk/`)

| Bestand | Inhoud |
|---|---|
| `<kamer>_<laag>_<staat>.png` | Per kamer (`s1_kade_ingang`, `s3_vismarkt`) en per laag een PNG zo groot als de kamer (640×360 en 960×360), in `grijs`, `half` en `kleur`. De lampen van die toestand zijn erin gebakken. |
| `<kamer>_<laag>_index.png` | Dezelfde laag als index voor de palet-LUT (§2): R = materiaal-id (`docs/art/slice/tiles/materialen.csv`), G = tint × 32 + 16 (zonder lichtband en zonder grijze verschuiving), **B = 255 voor een raam** (kan aan), A = 255 |
| Lagen | `achter` (lucht, verte, gevels; opaak) · `midden` (decor achter de figuren, geen collision) · `speelvlak` (alles waar je op staat of tegen loopt, precies op de blokken) · `licht` (halo's, RGBA, alleen `grijs`/`half`/`kleur`) · `voor` (boven de figuren: in S1 een meerpaalkop onderaan, in S3 de vlaggenlijn boven y 45) |
| `kadewijk_eenrichting_{grijs,half,kleur,index}.png` | Atlas 48×32 met twee **NinePatch-stukken** van 48×16: `galerij` (0, 0) en `trede` (0, 16). Links 16 en rechts 16 zijn de koppen, het midden is herhaalbaar. Het loopvlak is rij 0. |
| `kadewijk_kamers.json` | Manifest: per kamer de wereldrechthoek, de lagen met z-index en bestanden, de lampen (wereldpositie, straal van band 1, in welke toestand aan; voor een `PointLight2D` als de TA het licht dynamisch wil), de NinePatch-stukken met de bloknamen en de importconventie |

**Waarom de galerij en de treden apart:** in S1 hangen de galerij (`x = 20 + Z`) en de trede op 90 (`tread_90_width`) van D af. Ze zijn daarom geen deel van de kamerlaag, maar NinePatch-stukken op de rechthoeken van `Layout.blocks(&"S1", tail)`. De kraamluifels in S3 hangen niet van D af en zitten in `speelvlak`.

### 9.4 Importconventie en overdracht aan de Technical Artist

Ik koppel de art in deze run **niet** aan de kamerscènes. Een `ExtResource` naar een PNG vraagt de importcache, en die staat niet in git. Een verse clone faalt dan headless tot iemand `--import` draait (`standaarden.md`, ontwerp R4: "zodra `game/` importeerbare assets krijgt, komt er een `--import`-stap in CI"). Dat is een besluit van de TD en werk voor de TA. Code in `game/` krijgt een SM-review. De PNG's zelf breken niets: de suite is groen met de assets erin (356 geslaagd, 0 mislukt, Godot 4.6.3 headless).

**Conventie (voorstel AD, de TA/TD beslist):**

1. **Map en namen:** `res://art/wereld/<wijk>/<kamer-id>_<naam>_<laag>_<staat>.png`, kleine letters. Er staat geen `_placeholder` in de naam, want dit is eindkwaliteit. Placeholder blijft `_placeholder` (WERKWIJZE §9).
2. **Import:** `Texture2D`, compressie *Lossless*, mipmaps uit, `process/fix_alpha_border` aan, geen *repeat*. **Filter Nearest** op het CanvasItem (`texture_filter = TEXTURE_FILTER_NEAREST` op de wortel van de kamer-art), of één keer in het project `rendering/textures/canvas_textures/default_texture_filter = Nearest` (dat staat er nu niet).
3. **Plaatsing:** een node `Art` (Node2D) in elke kamerscène met per laag een `Sprite2D` (`centered = false`, positie = linksboven van de kamer in wereldcoördinaten, dus `Layout.ROOMS[id].position`). Het manifest geeft de z-index: achter −30, midden −20, speelvlak −10, licht −5, figuren 0, voor 20.
4. **Eenrichting per D (S1):** voor elk blok `Galerij` en `B1Trede30/60/90` uit `Layout.blocks(&"S1", tail)` komt er een `NinePatchRect` met de atlas en `region_rect` uit het manifest, `patch_margin_left/right = 16`, `axis_stretch_horizontal = TILE`, `position = rect.position`, `size = (rect.size.x, 16)`. Dat kan in `kadewijk_inhoud.gd`, naast de blokken die het al bouwt (ook het werk van de TA met de GP). `bron/godot_controle.gd` doet precies dit, als voorbeeld.
5. **Toestand:** zolang de LUT-shader er niet is, wisselt de kamer van texture op de waterstand (`grijs` bij `s < 2`, `kleur` bij `s = 2`). `half` en de index zijn voor de kleurgolf (§2): óf een shader die per pixel grijs/half/kleur kiest uit drie textures met de afstand tot het gemaal, óf de LUT op de index. De grijze placeholder-blokken (`Polygon2D` van `kadewijk_inhoud.gd`) en de `Proloogdeur`-polygon in `s1_kade_ingang.tscn` gaan uit als de art er is (de deur zit in `midden`). Het checkpoint en de bevroren echo van de bakker blijven (Animator, S-12).
6. **CI:** een stap `godot --headless --path game --import` vóór de tests (TD, R4), en de `.import`-bestanden committen of laten genereren (TD-besluit).

### 9.5 Metingen (`bron/genereer_slice_deel2.py`)

| | S1 grijs | S1 kleur | S3 grijs | S3 kleur | Norm |
|---|---:|---:|---:|---:|---|
| Gemiddelde chroma (CIELAB, hele kamer zonder figuren) | 3,4 | 16,5 | 3,0 | 15,1 | grijs ≤ ± 12 ✓ |
| Kleur tegenover grijs, zelfde kamer | | **× 4,9** | | **× 5,0** | ≥ 1,5× ✓ |
| ΔL\* loopvlak (bovenste 2 px tegen 2–6 px erboven), per blok | 20–41 | 31–63 | 28–41 | 41–50 | ≥ 20 (werkaanname AD, nieuw) ✓ |
| ΔL\* contour P1 / echo (p90 tegen de ring van 2–6 px) | 81 / 73 | 64 / 55 | 88 / 62 | 79 / **35** | ≥ 40: ✓, behalve de echo in S3-kleur vóór een verlicht winkelraam (§9.7) |
| ΔL\* **bovenrand** van de Kadelopers (3 stuks) | | | 80–85 | 68–70 | ≥ 50 (deel 1, §6) ✓ |

**Kanttekening chroma:** het kleurscript (§1) mat op thumbnails van 160×90 zonder detail, met S1-kleur ± 20 en de hoogste grijze beat 12. Op volle art met voegen, schaduw en donkere ondergrond liggen alle waarden lager. Grijs gaat van 6–7 naar 3, kleur van 20 naar 15–16,5. De verhouding wordt juist groter (× 5 in plaats van × 3). De regel "≥ 1,5× de hoogste grijze beat" toets ik daarom op volle art zodra S6 er is. Voor bible v1 stel ik voor de chroma op volle art te meten, niet op thumbnails.

**Kanttekening eenrichting:** de galerij in grijs haalt net ΔL\* 20. Bij een donkerdere achtergrond (S2) leest hij beter.

### 9.6 Opnieuw maken en controleren

```bash
python3 docs/art/slice/bron/genereer_slice_deel2.py          # assets, manifest, renders, metingen (± 40 s)
xvfb-run -a godot --path game --rendering-driver opengl3 --audio-driver Dummy \
  -s "$PWD/docs/art/slice/bron/godot_controle.gd" -- S1 grijs 60 /tmp/s1.png   # controle in de engine
```

De generator gebruikt deel 1 (palet, tegels, props, vijanden) en de R5-figuren. Hij gebruikt geen externe assets (`docs/licenties.md` §2: eigen werk).

### 9.7 Wat openstaat

- **Koppeling in de scènes en de `--import`-stap** (§9.4): TA met TD; SM-review.
- **LUT-shader en kleurgolf in de engine** (§2), met de kost op de Deck: TA.
- **S2 en S4** zijn maatvast (CD `past` in #212, PR #221 gemerged; LGD bevestigd in #223): eindkwaliteit volgt in deel 3, daarna S5–S9.
- **Bevroren echo van de bakker** (S-12) op de kade van S1: Animator.
- **Echo in kleur vóór een verlicht raam** (S3, ΔL\* 35 tegen ≥ 40): de amberen rand valt weg tegen warm raamlicht. Dat los je niet op in de achtergrond, want verlichte ramen horen bij de kleurtoestand. Voorstel voor de TA (echo-weergave F-07/S-10): een donkere buitencontour van 1 px die blijft staan, ook in kleur. Ik meet opnieuw als de echo-shader er is.
- **Bible v1:** de drempel voor het loopvlak (ΔL\* ≥ 20) en de chroma op volle art (§9.5).

---

## 10. Deel 3: S2 Kadegang, S4 Brugkloof, het snelluik en de schaduwklep

**Werkaanname (kader §5):** S2 en S4 zijn maatvast. De CD gaf `past` in #212, PR #221 is gemerged en de LGD bevestigde in #223. De art volgt `kadewijk_layout.gd` op `origin/main` (met S9 en het snelluik uit #231, en de schaduwklep uit #232) bij D = 60. S5/S6 maatvast (#228 gemerged); eindkwaliteit S5/S6 volgt na de regel van de WLD in kadewijk.md §8. Het gemaal voor de kleurgolf staat nog steeds op de werkaanname (4960, 150) uit §9.

### 10.1 Wat de kamers laten zien

| Kamer | Beeld | Grijs / kleur |
|---|---|---|
| **S2 Kadegang** | De kade op 230 met twee duikers waarin het water van de gracht staat. Linksboven komt een stenen brugboog uit de kamer en rust op de **pijler** (20 × 90, hardsteen met ijzeren banden en een lichte dekplaat). Langs de pijler loopt de **gang op 160**, een houten gang op consoles met een touwleuning. In de kom staat de **B3-trede**, een stenen console. Rechts staat het **pakhuis**: een bakstenen muur met speklagen, hijsdeuren en een hijsbalk. Zijn lijst op 70 is de **bovenroute** naar S3, op kraagstenen boven de kom. Aan de overkant van de gracht staat een gevelrij, een tint donkerder want verder weg, met het belfort. | Grijs: geen enkele lamp aan (kleurscript S2: niets in de omgeving). Kleur: de straatlamp op de kade, de wandlamp aan het pakhuis, ramen en hijsdeur-ramen. |
| **S4 Brugkloof** | De aanloop en de overkant op 260 (kasseien). Daartussen ligt de **kloof**: de oude sluiskolk met een kademuur, puin, resten van de sluisdeur en een plas. Op de bodem op 350 ligt slik met een lichte rand. Tegen de overkant staat de **trede van 45**. De **bolder** staat op de rand en is precies 8 × 8, met een versleten lichte kop zodat je de keerwand ziet. Boven de kloof staat **de brug, met een ingestort midden**: een boog met zwikken, een dek met leuning, een ketting en een losse balk bij de breuk. Die staat ver boven de vrije ruimte van B4 en is donker, dus hij leest niet als plafond. | Grijs: koude bundels door de kloof (kleurscript S4). Kleur: straatlampen, ramen en het belfort. |
| **S1, snelluik** (x 460–500) | De gang stopt op 460 met een kopse kant van hardsteen. Het **snelluik** is een eiken luik in een hardstenen sponning, met scharnieren en een ringgreep, en het is een eenrichtingsstuk. Eronder zit de **schacht naar S9**: baksteen met klimijzers, in `midden`. De proloogdeur blijft in de wand erachter. | Zoals S1. |
| **Schaduwklep** (V-01d) | **Besluit AD: zichtbaar.** Een echo die op niets staat, leest als een fout. De schaduwklep is de schaduw van het gebroken luik in de vormtaal van schaduwgeometrie (bible §4.4): een gearceerd vlak in *schaduwgeo* met een lichte bovenrand (daar staat de echo), plankennaden en ranken eronder. Ze heeft drie frames: vol, en oplossen 1 en 2 (Bayer 50 % en 25 %) voor `schaduwklep_weg`. | Paars in kleur, grijs in grijs, zoals de echo. |

### 10.2 Assets (`game/art/wereld/kadewijk/`, met `.import`, TD-besluit (c))

| Bestand | Inhoud |
|---|---|
| `s2_kadegang_<laag>_<staat>.png`, `s4_brugkloof_<laag>_<staat>.png` | Zoals §9.3 (960 × 360; achter, midden, speelvlak, licht, voor; grijs, half, kleur en index). In S2 en S4 is `voor` leeg en wordt niet geëxporteerd. |
| `s1_kade_ingang_speelvlak_*`, `…_midden_*` | Bijgewerkt: de gang stopt op 460 en de schacht staat in `midden`. Het snelluik zit níét in de laag. |
| `kadewijk_eenrichting_*.png` | Nu 48 × 48: `galerij` (0, 0), `trede` (0, 16), **`snelluik` (0, 32)**. Het manifest heeft `S1/Snelluik` en de stukken van S2 (`S2/Galerij70`, `S2/B1Trede30/60/90`). `kadewijk_art.gd` (#230) zet ze zonder codewijziging. |
| `s2_kadegang_b3_wand_*.png` (136 × 284) en `s2_kadegang_b3_blok_*.png` (120 × 45) | **Vaste stukken per D** (manifest `vaste_stukken`). De kopse kant van het pakhuis is de B3-keerwand en schuift mee met `b3_width(D)`: `Sprite2D` linksboven op (1250 + b, 76). Het B3-blok bestaat pas bij D > 60: `Sprite2D` met `region = (0, 0, b, 45)` op (1250, 185). Beide op z −10, na `Speelvlak` in de boom. `speelvlak` heeft in x 1250–1386 boven 230 alleen de bovenroute. Daardoor blijft de kolomtest van #230 bij elke D gelijk. |
| `kadewijk_objecten_*.png` (120 × 16) | De schaduwklep in 3 frames van 40 × 16. Manifest `objecten.schaduwklep`: frames, 12 fps, z −9, plaatsing op de rechthoek van het luik. |

### 10.3 Metingen (`bron/genereer_slice_deel3.py`)

| | S2 grijs | S2 kleur | S4 grijs | S4 kleur | Norm |
|---|---:|---:|---:|---:|---|
| Gemiddelde chroma | 2,9 | 15,6 | 2,9 | 15,6 | grijs ≤ 12 ✓, kleur × 5,4 ✓ |
| ΔL\* loopvlakken (per blok, bovenste 2 px tegen 2–6 px erboven) | 20–46 | 27–67 | 26–40 | 33–55 | ≥ 20 ✓ |
| ΔL\* snelluik (S1) | 23 | 28 | | | ≥ 20 ✓ |

De loopvlakken zijn alle blokken waar je op kunt staan, ook de pijlerkop, de bolder en de kloofbodem. De wand van B3 onder de bovenroute telt niet mee: die heeft geen loopvlak.

**Controle in Godot 4.6.3:** `godot_controle_s1_s3.png` (nu met het snelluik) en `godot_controle_s2_s4.png` (S2 bij D = 60, 120 en 180: het B3-blok en de wand schuiven mee). Na `--import` is de hele suite groen: **413 geslaagd, 0 mislukt**. `test_kadewijk_art` (592 checks) zit erbij, met het snelluik als stuk.

**Renders:** `s2_kadegang_*`, `s4_brugkloof_*` (grijs en kleur met figuren, vergelijking ×2, lichtovergang, geometriecontrole; voor S2 ook bij D = 120 en 180), `s1_kade_ingang_snelluik_x4.png`, `kadewijk_schaduwklep_x4.png`, `kadewijk_eenrichting_x4.png`.

### 10.4 Overdracht aan de Technical Artist (en de GP voor de schaduwklep)

1. **S1, snelluik:** gebeurt vanzelf via het manifest (`S1/Snelluik` → NinePatch). Alleen de scène opnieuw laden: er verandert geen code.
2. **S2 en S4:** een node `Art` zoals in S1/S3 (#230), met `kamer_id`/`naam` `s2_kadegang` en `s4_brugkloof`. In S2 komen daarbij de twee vaste stukken op de plek uit het manifest (`vaste_stukken`), en de kolomtest moet S2 en S4 meenemen. De placeholders van de blokken gaan uit.
3. **Schaduwklep:** een `Sprite2D` (frame 0) op `Luik` zolang de schaduwklep op laag 5 staat. Bij `schaduwklep_weg(tick, by)` spelen frame 1 en 2 af (12 fps), daarna is hij weg. Dat is code in `scripts/objects/luik.gd` of in de art-koppeling: TA met GP.

### 10.5 Wat openstaat

- Koppeling S2/S4, de vaste stukken en de schaduwklep (§10.4): TA (met GP), daarna een SM-review.
- **S5/S6 maatvast (#228 gemerged); eindkwaliteit S5/S6 volgt na de regel van de WLD in kadewijk.md §8.** S7–S9 na hun visie-review.
- De breekbare luiken (V-01) in S7/S9 op eindkwaliteit, 40 × 16 met scheur en gebroken toestand. Dat gebeurt met hun kamers, want de luiktegels van deel 1 zijn nog 32 × 16 placeholder.
- Bij D ≥ 90 overlapt het wand-stuk een deel van de pakhuismuur. De hijsdeuren staan daarom rechts van x 1506 (wereld). Dit geldt alleen voor de regressie, het spel draait op D = 60.

---

## 11. Deel 4: S5 Sluiswachtershuis, S6 Gemaalplein, S7 Sluiskelder en de objecten

**Werkaanname (kader §5):** S5 en S6 zijn maatvast door #228 (LGD-besluiten 2 en 3 in #227). S7 is maatvast sinds de Lead-review in #239: de schaduwklep is er (#232) en de CD gaf `past` na de her-review. De geometrie komt nu rechtstreeks uit het spel. `bron/dump_blokken.gd` schrijft `Layout.blocks()` van alle kamers bij D = 60/90/120/180 naar `bron/kadewijk_blokken.json`, en `genereer_slice_deel4.py` leest dat bestand. **Het gemaal voor de kleurgolf** staat nu op `S6/Gemaal` (4600, 140) in plaats van de werkaanname (4960, 150). Daardoor veranderen de lichtovergangsrenders van S1–S4 een beetje; hun assets niet, behalve één bestand: `s1_kade_ingang_achter_half.png`, omdat een verlicht boograam nu ook in `half` emissief is (bible: een verlicht raam houdt zijn kleur). S8 en S9 zijn nog niet maatvast (§8 van het kamerdoc) en krijgen nog niets.

### 11.1 Wat de kamers laten zien

| Kamer | Beeld | Grijs / kleur |
|---|---|---|
| **S5 Sluiswachtershuis** | Het trappenhuis van binnen. **Elke verdieping heeft een eigen kamer**: dat is de variatie die volgens het LGD-besluit 3 (#227) uit de art moet komen.<br>• Beneden de keuken: wit pleister, blauwe tegeltjes, het fornuis met vuur en de tafel met het logboek.<br>• Verdieping 1, de wasruimte: groen, met een waslijn met lakens en een tobbe.<br>• Verdieping 2, de werkplaats: oker, met de **peilschaal** van de sluiswachter (het peil op hoog water) en tandwielen op een plank.<br>• Verdieping 3, de kaartenkamer: rood, met de kaart van de wijk (gracht en gemaal) en een bed.<br>• De zolder: sporen, panlatten, een hanenbalk en een dakraam met sterren.<br>Elke verdieping heeft een raam met de nacht erachter. Daarnaast een lambrisering met een donkere lijst (geen valse richel), de buitenmuren in doorsnede, de doorgang uit S4 en in de hoek de trap van S9.<br>De richels zijn een **nieuw stuk `richel`**: grenen delen met een lichte neus, op een balk. | Grijs: alleen het fornuis gloeit (kleurscript S5: het enige warme interieur vóór het gemaal). Kleur: een wandlamp per verdieping en verre ramen in de vensters. |
| **S6 Gemaalplein** | Het plein met kasseien. Het **gemaal** is een bakstenen hal met trapgevel, speklagen, schoorsteen en twee boogramen met de machine erachter. Het **rad** hangt op `S6/Gemaal`, met de drijfstang naar de **pompgang**: een ijzeren as op lagers langs de vier schoepen en een goot met water. Daarachter staan de kerk, het belfort en de daklijn, zodat de hoge lucht niet leeg is. Links de loopbrug van de zolder en de trap als hardstenen treden aan een ijzeren steiger. Rechts de sluistoren met een peilschaal, en de schacht onder de sluis met het water van de kelderingang. | Grijs: geen lamp. **Trap 1** (extra laag `gemaal_aan`): de boogramen warm, en de poel rond het gemaal en de pompgang in kleur, terwijl de wijk nog grijs is (kleurscript §1, regel 2). Kleur: alles. |
| **S7 Sluiskelder** | Tongewelven op pijlers, een koperen en een ijzeren buis naar de machinehal, en links de rondboog naar S8. De **kelder** (de zak bovenin) heeft een eigen gewelf, kisten en de schacht van de kelderingang, met licht dat erin valt. De opening van het luik blijft leeg in `speelvlak`, want het luik is een object. In het **kanaal** staat water (beeld), met de trede van 45 en de kademuren. | Grijs: alleen de warme gloed van de sokkel (kleurscript S7). Kleur: wandlampen aan de pijlers. De Dwaallichten zijn het enige rood. |

### 11.2 Objecten (`kadewijk_objecten_*.png`, frames in het manifest `objecten`)

| Object | Frames | Waarvoor |
|---|---|---|
| `luik` (40 × 16) | 0 dicht met scheur (L-03), 1–2 breuk, 3 open | `scripts/objects/luik.gd` in **S7 en S9**. De sponning bovenaan is licht, zodat het loopvlak leest (ΔL\* zoals het snelluik) |
| `schaduwklep` (40 × 16) | 0 vol, 1–2 oplossen | **Nu hol** (punt van de CD in #227): alleen een rand en een arcering om de 3 px, zoals de echo. "Vol = levend, hol = echo": je leest dat de echo op zijn eigen klep staat. De bovenrand is een rechte, doorlopende rij (rij 1). Daar staat de echo, en de test van #241 eist hem |
| `pompschoep` (32 × 48) | 0 rust, 1–4 slag | De vier `Pomprad`-objecten in S6 |
| `pompslag` (48 × 48) | 5 frames, een warme ring die in de as stroomt | Bij elke pompslag. **P1 en de echo gebruiken dezelfde schoep-frames, hetzelfde effect en dezelfde timing, 100 % dekkend.** Geen transparantie en geen kleinere versie voor de echo: zijn slag moet even zwaar ogen als die van P1 (CD, #227), anders leest hij als nagalm |
| `sluisklep` (60 × 10, in een cel van 64 × 16) | dicht, open | `S6/Sluis` |
| `sokkel` (32 × 32) | uit, aan (warme gloed) | De sokkel van V-01 in S7 |
| `gemaal_rad` (96 × 96) | 8 frames | Het rad aan de gevel van het gemaal (S6). Staat stil tot de eerste pompslag en draait als het gemaal pompt |

**Audio (voor de Audio Director, T8d):** het andere deel van het punt van de CD. De pompslag van de echo moet **even zwaar klinken** als die van P1: hetzelfde sample en hetzelfde volume, zonder galm of low-pass die hem tot nagalm maakt. Hooguit een kleine toonhoogte-variatie, zodat twee slagen vlak na elkaar niet als één klinken. Mijn voorstel is een kort issue voor de AuD. Ik zet dit punt in het comment in #85.

### 11.3 Assets en metingen

- `s5_sluiswachtershuis_*` (640 × 560), `s6_gemaalplein_*` (960 × 560) en `s7_sluiskelder_*` (960 × 360). Elk heeft de lagen achter, midden, speelvlak en licht in grijs, half, kleur en index (`voor` is in alle drie leeg). Daarbij komt `s6_gemaalplein_gemaal_aan_grijs.png`, de extra laag voor trap 1 (manifest `kamers.s6_gemaalplein.extra`). De `.import`-bestanden zijn gecommit (TD-besluit c).
- De eenrichtingsatlas heeft nu 5 stukken (48 × 80): `galerij`, `trede`, `snelluik`, `trede_r` (de trede tegen een wand rechts, gespiegeld) en `richel`. In het manifest staan de 16 blokken van S5 (`S5/Richel1–3`, `S5/Zolder`, `S5/B2a–dTrede30/60/90`).
- De vaste eenrichtingsblokken van S6 (de loopbrug, de trap) en van S5 (de treden van de trap van S9) zitten in `speelvlak`. Dat volgt de kolomregel van de test van #230.

| | S5 grijs | S5 kleur | S6 grijs | S6 trap 1 | S6 kleur | S7 grijs | S7 kleur | Norm |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| Gemiddelde chroma | 2,6 | 15,3 | 3,0 | 3,7 | 18,6 | 3,0 | 11,3 | grijs ≤ 12 ✓ |
| ΔL\* loopvlakken (alle blokken met een bovenkant in de kamer) | 25–44 | 20–73 | 20–31 | — | 32–50 | 22–42 | 33–63 | ≥ 20 ✓ |

S7 blijft in kleur rustiger (11,3): het is een kelder zonder lucht en zonder gevels. Het kleurscript legt de grote stap bij S9, niet hier.

**Controle in Godot 4.6.3:** `godot_controle_s5_s7.png` (S5 ook bij D = 120: de richels en de treden volgen de layout). De hele suite is groen: **413 geslaagd, 0 mislukt**.

**Renders:** `s5_*`, `s6_*` (met `s6_gemaalplein_trap1_960x560.png`) en `s7_*`, telkens grijs en kleur met figuren, een vergelijking ×2, de lichtovergang en een geometriecontrole. Verder `kadewijk_objecten_x3.png`.

### 11.4 Overdracht aan de TA (met de GP)

1. **S5–S7:** een node `Art` zoals in #230, met `kamer_id`/`naam` uit het manifest. Let op: `wereld_rect` heeft nu ook een y (S5/S6 −200, S7 360). De richels en treden van S5 zet `kadewijk_art.gd` al via het manifest (soort `richel`, `trede`, `trede_r`).
2. **S6 trap 1:** de laag `gemaal_aan` (z −15) is zichtbaar bij `GEMAAL_VOL` zolang `s < 2`.
3. **Objecten:** het luik (S7, S9), de schaduwklep, de pompschoep en de pompslag (gelijk voor P1 en de echo), de sluisklep, de sokkel en het rad. Plaatsing en frames staan per object in het manifest (`objecten`). Dat is code in de objecten (GP) of in de art-koppeling (TA).

### 11.5 Wat openstaat

- Koppeling van S5–S7, de laag `gemaal_aan` en de objecten (§11.4): TA met GP, daarna een SM-review.
- Audio van de pompslag van de echo: Audio Director (§11.2).
- S8 (als de boss erin zit) en S9 (na de her-review). Het punt van de CD over S9 (het lege scherm tussen het Dwaallicht en het E-paar: daar moet het beeld de beloning zijn) neem ik mee als S9 maatvast is.
- Bevroren echo's (kinderen in S6, de koppen in S5) en de logbladzijden: Animator en GP.

---

## 12. Deel 5: S8 Machinehal en S9 Lage kade

**Werkaanname (kader §5):** S8 en S9 zijn maatvast (LGD, [comment in #83](https://github.com/cesarvangerwen-glitch/echoborn/issues/83#issuecomment-6844964137)). Daarmee zijn **S1–S9 alle negen maatvast en op eindkwaliteit**. `kadewijk_blokken.json` is opnieuw gedumpt; alleen S8 is veranderd (de drempel onder `DeurLinks`, afwijking 20). De assets van S1–S7 blijven daardoor bit voor bit gelijk. Er is één uitzondering: het manifest, met `fps_vol` en de nieuwe stukken.

### 12.1 Wat de kamers laten zien

| Kamer | Beeld | Grijs / kleur |
|---|---|---|
| **S8 Machinehal** (één scherm, vaste camera) | De achterwand van de hal met een **groot boograam achter de ketel**. Het koude licht en een gedithered tegenlicht van 2 tinten rond het silhouet (deel 1 §4.4) laten het donkere lijf van de Gemaalmeester lezen. Verder:<br>• de **balk** waaraan het rad hangt (fase 2: 100–140 boven de vloer), met een loopkat en een ketting; het rad zelf is van de boss (Animator, S-14);<br>• buizen, manometers en een vliegwiel-stomp;<br>• een gietijzeren vloer met de twee **spuigaten** (GMB-03);<br>• de deuropeningen, met de **deuren als vaste stukken**. | Grijs (`s = 1`, het gevecht): **geen warm licht in de arena**, alleen koud tegenlicht. Rood is van de boss (kleurscript S8: de koudste beat). Kleur (na de boss): twee wandlampen. Warm licht hoort na de boss (L-14e). |
| **S9 Lage kade** (4160 px) | **De verlichte wijk boven je**: een gevelrij op de hoge kade, het belfort en een stenen **brug** over de gracht tussen het Dwaallicht en het E-paar (x 1480–1940), met lantaarns. Daaronder de **oude kademuur met de getijdenrand** (de oude waterstand, nat en groen eronder), duikers, meerringen, en het **gezakte water** ervoor met weerspiegelde lichten. Bij het **rustpunt** liggen twee bootjes met lantaarns aan de kade. Links de **kelder onder S1**: een tongewelf, de galerij van B1, de schacht met licht uit het snelluik, de platen rond het luik en de benedenkade. Verder de brugpijler met zijn bogen. Onder de brug ligt de wijk in de slagschaduw; daar blijven de ramen donker, zodat de richels lezen. Ten slotte het hoogwater als vast stuk en de trap naar het plein. | Grijs: geen lamp, het water is donker. **Kleur (na trap 2, de hoofdtoestand van S9)**: alle ramen en lantaarns aan, en de lichten weerspiegeld in het water. |

**De punten van de CD:**
- **S8, de holle echo naast P1 bij de ketel in fase 1** (`s8_machinehal_ketel_echo_x4.png`, met de concept-boss uit deel 1): de contour van de echo haalt ΔL\* **74 in grijs en 64 in kleur**, P1 haalt 84 en 83 (norm ≥ 40). De echo staat vóór het donkere lijf. Zijn lichte holle rand en de donkere arcering lezen daar als tweede lichaam, niet als een vlek op de ketel.
- **S9, het beeld als beloning bij het rustpunt en tussen het Dwaallicht en het E-paar:** `s9_lage_kade_rustpunt_x2.png` (x 3060–3700) en `s9_lage_kade_tussenstuk_x2.png` (x 1440–2080). In beide zijn de verlichte wijk en het gezakte water met de getijdenrand in beeld. Het tussenstuk heeft de brug, het rustpunt de bootjes.

### 12.2 Assets

- `s8_machinehal_*` (640 × 360) en `s9_lage_kade_*` (4160 × 360), met de lagen achter, midden, speelvlak en licht in grijs, half, kleur en index. De `.import`-bestanden zijn gecommit.
- **Vaste stukken** (manifest `vaste_stukken`), elk zichtbaar zolang het blok collision heeft (`Kadewijk.set_door`):
  - `kadewijk_s8_deurlinks_*` (20 × 320, dicht tot `BOSS_VERSLAGEN`);
  - `kadewijk_s8_deurrechts_*` (20 × 260, open tot `BOSS_START`);
  - `kadewijk_s9_hoogwater_*` (60 × 275, een sluisdeur met sijpelend water, weg bij `s = 2`).
- **Eenrichting per D in S9**: `Galerij` en `B1Trede*` (galerij, trede), `PijlerRichel1/2` (galerij), `B2aTrede*` (trede) en `B2bTrede*` (trede_r). De vaste eenrichtingsblokken (de schacht, de trap naar het plein) zitten in `speelvlak`.
- **`objecten.gemaal_rad.fps_vol = 6`** (besluit #244): het rad draait op `fps` (10) zolang het gemaal vult, en blijft daarna draaien op 6.

### 12.3 Metingen

| | S8 grijs | S8 kleur | S9 grijs | S9 kleur | Norm |
|---|---:|---:|---:|---:|---|
| Gemiddelde chroma | 2,8 | 16,8 | 2,9 | 14,1 | grijs ≤ 12 ✓ |
| ΔL\* loopvlakken (alle blokken met een bovenkant, zonder vaste stukken) | 31–36 | 45–55 | 20–47 | 27–63 | ≥ 20 ✓ |
| ΔL\* contour echo / P1 bij de ketel | 74 / 84 | 64 / 83 | | | ≥ 40 ✓ |

**Controle in Godot 4.6.3:** `godot_controle_s8_s9.png` laat S8 zien, en S9 in uitsneden: de kelder, de pijler bij D = 60 en 120, en het hoogwater met de trap. De vaste stukken worden nu generiek geplaatst, zoals `kadewijk_art.gd` dat doet. De hele suite is groen: **437 geslaagd, 0 mislukt**.

### 12.4 Overdracht aan de TA (met de GP)

1. **S8 en S9:** een node `Art` zoals in #230/#244. S9 is 4160 breed: één `Sprite2D` per laag werkt. Bij een probleem met de grootte van textures op de Deck kan ik de lagen in stroken van 1024 leveren; zeg het dan.
2. **Deuren en hoogwater:** de vaste stukken op hun blok, zichtbaar zolang het blok collision heeft. `DeurRechts` begint open (`START_OPEN`): dan niet tekenen.
3. **Rad:** lees `fps_vol` als het gemaal vol is.
4. **Boss:** de sprites van de Gemaalmeester (S-14) zijn van de Animator. De concept-boss in de renders van deze PR komt uit deel 1 en dient alleen ter beoordeling.

### 12.5 Wat openstaat

- Koppeling van S8/S9, de deuren, het hoogwater en `fps_vol` (§12.4): TA met GP, daarna een SM-review.
- De sprites van de boss (S-14) en de bevroren echo's (S-12): Animator.
- De LUT-shader en de kleurgolf in de engine (§2): TA. Met S1–S9 kan de golf nu over de hele wijk.
- Bible v1: de regels uit §6 en de chroma op volle art (§9.5).
