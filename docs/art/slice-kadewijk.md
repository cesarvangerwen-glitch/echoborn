# Slice-art Kadewijk, deel 1: kleurscript, lichtovergang, tileset, stijlregels vijanden

Versie 0.1.1 · Eigenaar: Art Director · Issue [#85](https://github.com/cesarvangerwen-glitch/echoborn/issues/85) (T8c, deel 1) · Hoort bij `docs/art/bible.md` v0 en `docs/art/assetlijst.md`
Bronnen: `docs/design/wereld.md` v0.2 §2 (slice Kadewijk), `docs/design/combat/slice-vijanden-en-boss.md` v0.1.1 (§2, §3, §9), `docs/narrative/verhaal-v2.md` §4.3 en §6, `docs/art/ui-stijlgids.md` (merk, klokring, `#ff475c`), fasekader fase 2 v0.4 §2 (T8c) en §4.

## 0. Werkaanname (kader §5)

| Bron | Wat dit deel ervan gebruikt |
|---|---|
| CEO-besluit #18 | 2D pixel art op 640×360 (Deck 640×400) met dynamisch 2D-licht |
| CEO-besluit #51 (1A) en pitch v0.4 | Wereld en echo eerst grijs, ze leven op met het licht; water is beeld, geen speellaag |
| CEO-besluit 2026-11-12 (1) | Fase 2 loopt parallel en slice-art mag starten. Volgens §4, regel 3 van het kader komt **eindkwaliteit alleen op maatvaste kamers**. Op dit moment is **geen enkele slice-kamer maatvast**. |
| CEO-besluit 2026-11-12 (D = 60) | Het vloerteken onder het rad schuift mee met D (`D` tot `D + 68` px). Verder hangt hier niets van D af. |
| F1 (#65) | Gehaald: de R5-scène is de maatstaf voor eindkwaliteit |
| **Werkaanname AD** | Alles in dit deel is **placeholder** (`_placeholder` in de bestandsnaam). Ik maak alleen wat niet van kamermaten afhangt: palet, regels, tegels die je in elke layout kunt hergebruiken, en concepten. Er staat **niets in `game/`**. De Technical Artist zet de tegels pas in `game/art/wereld/kadewijk/` als de importconventie er is (assetlijst §4) en de eerste kamer maatvast is. |

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
| Eindkwaliteit per kamer (tegels gebruiken, achtergrondlagen, interieurs S5, S7, S8) | Art Director met Environment Artist | Deel 2, per kamer zodra de LGD haar maatvast verklaart |
| Regels van §4.2 (bovenrand 2 px, tell-taal, amber/cyaan alleen als merk-overlay) en de drie nieuwe ramps opnemen in bible v1 §3 en §6, met de drempels: **bovenrand ΔL\* ≥ 50** tegen de directe achtergrond (ring van 2–6 px), in grijs én kleur (gemeten 50–75); de bestaande eis van **ΔL\* ≥ 40** op vulling of contour wordt voor vijanden "op bovenrand of kern" (het lijf haalt 2,6–37); kleurafstanden **ΔE76 ≥ 30, en ≥ 25 bij deuteranopie**, anders ΔL\* ≥ 20 of vorm (bible §7.1); en uit het kleurscript (§1) een **gemiddelde chroma ≤ ± 12 tot trap 2** (gemeten 3–12), en de beat na trap 2 minstens ± 1,5× de hoogste grijze beat (gemeten 20 tegen 12) | Art Director | Bible v1 |
| De LUT-shader en de kleurgolf in Godot 4.6, met de kost tegen het lichtbudget (≤ 20 LE) | Technical Artist | Vóór de eerste maatvaste kamer |
| Tegels naar `game/art/wereld/kadewijk/` met de importconventie (dan SM-review, code in `game/`) | Technical Artist | Met de LUT-shader |
| Is de Dwaallicht-sluier op Deck-grootte leesbaar als "zwevend"? | Art Director | Ware Deck-test (T7) |

## 7. Bestanden

Alles in `docs/art/slice/` wordt gemaakt door `bron/genereer_slice_deel1.py` (deterministisch, ± 2 s). Het script gebruikt het palet en de figuren van de R5-scène, het eigen pixelfont en de merk-sprites van de UI Artist. Het gebruikt geen externe assets (`docs/licenties.md` §2: eigen werk).

## 8. Wijzigingen

| Versie | Datum | Wat |
|---|---|---|
| 0.1.1 | 2026-11-12 | Na de SM-review (PR #195): het gemaal in S1 benoemd, S1 en "S1 terug" als één plek in twee toestanden (§1), drempels voor ΔL\* en chroma in §6. |
| 0.1 | 2026-11-12 | Deel 1 van T8c (#85): kleurscript, lichtovergang, tileset-opzet met 46 tegels en 8 props in 3 toestanden plus index-atlas, 3 nieuwe ramps, concept-sheets voor 3 vijandtypes en de Gemaalmeester, metingen. |
