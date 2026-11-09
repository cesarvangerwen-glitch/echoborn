# Art bible v0

Versie 0.1 · Eigenaar: Art Director · Issue: #20 · Basis: stijlbesluit 2D (#18), pitch v0.4 (besluit #51), stijltests (`docs/art/stijltests.md`)

Deze bible legt vast hoe de game eruitziet en wat elke artist moet halen. Ze is **v0**: genoeg om de grijze flow-kamer en de slice-art op te bouwen. De paletten per gebied volgen in v1 (zie *Open punten*).

**Werkaannames:**
- Lichtbudget: voorlopig ≤ 20 lichteenheden (LE) per scherm, ± 4 schaduwlichten, licht gerenderd op 640×400 en ×2 opgeschaald (Technical Artist, #21, `docs/tech/lichtmeting.md`, PR #62, in review).
- Co-op volgens besluit #51 (7A): solo heb je een echo, in co-op is de partner (speler 2) de echo. Nooit meer dan twee lichamen, plus de gedeelde echo als finisher.
- Echo-staart ± 2 s (8A).
- Geen naam of logo in de art: de werktitel ligt opnieuw bij de CEO (#61).

---

## 1. Het beeld in één zin

**Een verdronken Vlaamse stad in harde lichtbanden: wat licht krijgt, krijgt kleur terug.** Licht is kostbaar en warm. Schaduw is een speelbare laag met een harde rand. *Vol = levend, hol = echo.*

De R5-scène laat dat zien. Het is dezelfde plek bij een gemaal, in twee toestanden. Zij is de maatstaf voor eindkwaliteit (fasekader fase 2, F1):

| Bestand (in `docs/art/r5-scene/`) | Wat |
|---|---|
| `r5_grijs_640x360.png`, `r5_kleur_640x360.png` | De scène native: grijs-donker (vóór het oppompen) en opgepompt-kleurrijk |
| `r5_grijs_x3.png`, `r5_kleur_x3.png` | Dezelfde, ×3 (1920×1080) om te beoordelen |
| `r5_vergelijking_x2.png` | Beide toestanden onder elkaar, ×2 |
| `r5_grijs_deck_1280x800.png`, `r5_kleur_deck_1280x800.png` | Steam Deck: 640×400 ×2 (40 px meer kamer in de hoogte) |
| `r5_deck_ware_grootte.png` | Beide toestanden op ware Deck-grootte (7 inch, gezien op een monitor van ± 96 ppi) |
| `r5_beweging_*_placeholder.gif`, `r5_beweging_deck_ware_grootte_strip_placeholder.png` | Speler 2 naast de echo, in schaduw en in beweging, op ware Deck-grootte en ×3 (de loopcyclus is placeholder) |
| `r5_leesbaarheid_grijs_deuteranopie.png` | Beide toestanden in grijswaarden en met gesimuleerde deuteranopie |
| `palet.png` | Alle ramps, kleur en grijs |
| `bron/genereer_r5.py`, `bron/sprites.py` | De code die alles maakt (± 10 s). Hij print ook de metingen uit §7 |

**Opnieuw maken:** `python3 docs/art/r5-scene/bron/genereer_r5.py` vanaf de repo-root. Het script gebruikt het eigen pixelfont uit `docs/art/stijltests/bron/` en geen externe assets.

**Wat in de scène staat:** een kade met een hangende lantaarn (verplaatsbare lichtbron), een zuil die een schaduwwig werpt, een lichtplatform (lichtgeometrie), een schaduwbrug over het kanaal (schaduwgeometrie) die oplost in de lichtkegel van een straatlamp, een FelLicht-zone onder het zoeklicht van het gemaal, een schoepenrad, een duiker die pas vrijkomt als het water zakt, en een getijdenrand op de oude waterstand. Speler 1 staat in het licht, de echo springt boven de brug, speler 2 staat in de schaduw op de brug.

**Let op:** met drie lichamen is dit een **leesbaarheidscompositie**, geen spelsituatie. Onder 7A zijn er nooit meer dan twee lichamen (solo: speler 1 + echo; co-op: speler 1 + speler 2). De scène toont alle figuren naast elkaar om ze te kunnen vergelijken. Ze is **niet bedoeld voor marketing**.

---

## 2. Specificaties

| Wat | Regel |
|---|---|
| Interne resolutie | **640×360** (pc, 16:9) en **640×400** (Steam Deck, 16:10). Op de Deck zie je dezelfde kamer met 20 px extra boven en onder; niets speelbaars staat alleen in die strook. |
| Schaling | Alleen integer en nearest neighbour: ×2 voor 1280×720/800, ×3 voor 1920×1080, ×6 voor 4K. Geen subpixel-camera; de camera snapt op hele pixels. |
| Tegelmaat | **16×16 px**. Kamerhoogte pc 22,5 tegels, Deck 25 tegels. |
| Speler 1 | ± 18×29 px (± 1,8 tegel hoog). Op de Deck ± 6,8 mm. |
| Speler 2 | ± 22×33 px, met pikhaak (± 2 tegels). Breder en hoger dan speler 1, zodat het silhouet al verschilt. |
| Echo | Hetzelfde silhouet als de eigenaar (hij herhaalt jouw houding van ± 2 s terug). |
| Gewone vijand | 16–40 px hoog. Boss (Gemaalmeester): tot een halve schermhoogte. |
| Lijnwerk | Figuren hebben een contour van 1 px (speler 1 donker, speler 2 en de echo in hun eigenaarskleur, met daarbuiten nog 1 px bijna-zwart). Omgeving: geen contour, vorm door tinten. |
| Anti-aliasing | Geen. Overgangen alleen met ordered dithering (Bayer 4×4), en alleen in lichtverloop, lucht en volumetrische bundels; nooit op een laaggrens. |
| Rotatie en schaal van sprites | Niet in de game (geen gedraaide pixels, geen "mixels"). Draaiende delen, zoals het schoepenrad, krijgen eigen frames. |
| Parallax | Maximaal 4 lagen: lucht, verre daklijn (met belfort), huizenrij, middengrond (rad, kanaalwand). Het speelvlak staat er altijd scherp voor. |

---

## 3. Palet

Elk materiaal heeft **een ramp van 8 tinten**, van donker naar licht, met **hue-shift**: de schaduwkant koel (paars, blauw), de lichte kant warm. Een pixel krijgt zijn tint met één regel:

> **tint = omgeving + vorm + lichtband** (afgekapt op 0–7)

- **Omgeving**: 0 voor de lucht, 1 voor de verre laag, 2 voor de rest (opgepompt); in de grijze toestand 1.
- **Vorm**: −2 tot +2 per pixel (voegen −1/−2, bovenkant van een blok +1, kant naar het licht +1).
- **Lichtband**: 0–4 uit de lichtsterkte (§4).

Zo blijft elk scherm binnen het palet: de R5-scène telt 139 kleuren (kleur) en 171 (grijs, met de lichtpoel die kleur terugbrengt).

| Materiaal | Ramp (tint 0 → 7) |
|---|---|
| lucht | `#06060f` `#0c0c1d` `#10132a` `#181c3b` `#21264c` `#2b315e` `#3a3e6d` `#4a4c7c` |
| verre laag (belfort, daklijn) | `#0a0a18` `#121326` `#171a36` `#202546` `#2b3057` `#373d6b` `#484d7e` `#5a6090` |
| gevel rood | `#120a14` `#29141b` `#431c21` `#672c26` `#8b402e` `#af5a3b` `#cd794e` `#e89a64` |
| gevel oker | `#120c14` `#291c17` `#442e1b` `#6c4f28` `#936e35` `#b78c44` `#d5ac5d` `#f0cc7a` |
| gevel wit | `#0e0e1a` `#201f30` `#37344a` `#5b576e` `#817c8a` `#a8a19f` `#cbc2b5` `#ece2cc` |
| gevel groen / luiken | `#0a1014` `#152022` `#1e3231` `#314c44` `#486a5a` `#668a74` `#8baa8a` `#b2cca0` |
| leien dak | `#0a0a16` `#131626` `#1b1f37` `#262d4a` `#343f5f` `#465476` `#5e6e8d` `#7a8aa4` |
| verlicht raam | `#2a1208` `#4d230f` `#763912` `#a75d19` `#ce8024` `#e9a236` `#f9c872` `#fff0b8` |
| donker raam | `#05050a` `#090913` `#0e0e1a` `#141523` `#191c2d` `#202437` `#282c42` `#30344c` |
| steen (blauwe hardsteen) | `#0a0a14` `#191929` `#2b2b41` `#42445b` `#636273` `#8d8787` `#b8ad9a` `#e0d0b0` |
| baksteen (gemaal) | `#0e0810` `#251216` `#441d1d` `#6a2e26` `#924532` `#b96745` `#db8e60` `#f4b884` |
| ijzer | `#050508` `#0d0d12` `#15151b` `#1f1d26` `#2b2933` `#3a3640` `#504b53` `#6a6268` |
| koper (machine) | `#060c10` `#101f23` `#1a3737` `#28574f` `#3a7c6a` `#61a88b` `#92d1ad` `#c8f0d0` |
| hout | `#0c0808` `#1c110c` `#291a11` `#3f281b` `#573926` `#734d33` `#916541` `#b08050` |
| water | `#03050c` `#091021` `#0b1d35` `#102f4b` `#184765` `#2d6883` `#5392a6` `#8cc8d0` |
| klimop / getijdenrand | `#060c08` `#0d190c` `#122411` `#1e3718` `#2c4b20` `#3c6228` `#587f33` `#78a040` |
| **schaduwgeometrie** | `#0a0414` `#170924` `#200e36` `#31164f` `#45216a` `#5c3088` `#7a4aab` `#9a68d0` |
| **lichtgeometrie** | `#3a2c18` `#5e4c30` `#84704d` `#ae9a74` `#cfbd98` `#e6d9b8` `#f4ebd4` `#fffaf0` |
| **FelLicht** | `#20303c` `#375062` `#53758b` `#77a1b8` `#9cc7dc` `#bfe4f4` `#dbf4fc` `#f4feff` |
| **gloed (warm licht)** | `#4a2a0a` `#764110` `#a45c17` `#cc7e22` `#e9a039` `#fbc058` `#ffdb94` `#fff6d8` |

**Figuurkleuren** (vast, onbelicht):

| Figuur | Kleuren |
|---|---|
| Speler 1 (machinist) | contour `#140a12`, jas `#ece2c8` / `#b4a48a`, huid `#f2d6b4`, pet `#3a2830`, **sjaal amber `#f29a26` / `#b45c16`**, randlicht `#fff2c8` |
| Speler 2 (sluiswachter) | lijf `#08080e` (vol), **rand cyaan `#3ee6f4`**, ogen `#e8ffff`, sjaal `#1fb4cc`; grijs: rand `#a8c4c8`, sjaal `#5a6a6e` |
| Echo (van speler 1) | **rand amber `#f29a26`**, binnenkant arcering `#3a1e56`, ogen `#ffd27a`; grijs: rand `#c8c4cc`, arcering `#3a3842`, ogen `#e8c888` |

**Grijze toestand:** dezelfde ramps met de chroma op 6 %, de lichtheid × 0,86 en een kleine koele zweem (b* −2,5). **Halve toestand** (in de lichtpoel van een lamp in een grijze wijk): chroma 42 %. De ramp *gloed* houdt in elke toestand zijn kleur.

---

## 4. Licht en schaduwlagen

### 4.1 Hoe licht eruitziet
1. **Licht werkt in 5 banden** (lichtband 0–4). Het verloop tussen twee banden wordt gedithered; de rand van een schaduw nooit. Een schaduw heeft **geen halfschaduw**.
2. **Geworpen schaduw is één tint donkerder dan de omgeving.** Daardoor leest de schaduwwig ook op de achtergrondgevels, niet alleen in de lucht.
3. **De laaggrens** waar licht overgaat in schaduw krijgt in de lucht een **stippellijn van 1 px** in *gloed* tint 4 (2 aan, 2 uit). Dat geldt voor de schaduw achter elke occluder en voor de rand van een lichtkegel die schaduwgeometrie raakt. De stippellijn stopt 3 px vóór een vast blok.
4. **Vaste blokken** (kade, zuil, muren): alleen de bovenste 4 px krijgen slagschaduw van andere blokken. Hun voorkant krijgt licht op afstand, zonder slagschaduw, en loopt naar onder toe donker weg.
5. **Figuren zijn onbelicht** (altijd leesbaar). Alleen speler 1 krijgt 1 px randlicht aan de kant van de dichtstbijzijnde warme lichtbron.

### 4.2 Lichtbronnen zijn herkenbaar
Elke lichtbron, en zeker een die de speler **verplaatst** (de lantaarn), heeft alle vijf:
1. een **kern** in *gloed* tint 6–7 (vlam of gloeidraad), in een donker frame van ijzer;
2. een **halo in 3 ringen** (tint 3 / 4 / 5, buiten naar binnen, gedithered 50 / 75 / 100 %);
3. **korte stralen in een kruis** (horizontaal 6 px, omlaag 4 px, omhoog 2 px), plus 4 diagonale stippen;
4. een **lichtpoel** op vloer en muur met de harde schaduw van wat ervoor staat;
5. **stof in het licht**: losse pixels in tint 6, ± 0,4 % van de verlichte lucht.

In de game komt daar een **flakkering** bij (de kern wisselt tussen tint 6 en 7, de halo ademt ± 1 px, ± 4 Hz). Een verplaatsbare bron heeft een **hengsel** en hangt aan een **haak**: je ziet dat je hem kunt pakken. In de grijze toestand is de lantaarn het enige in de **omgeving** met volle kleur; alleen speler 1 is verder ook in kleur (§5).

### 4.3 Warm licht tegenover FelLicht
"Verlicht is niet fel" (pitch, pillar 2). Ze moeten in één oogopslag verschillen:

| | Warm licht (gewone lamp, opgepompte wijk) | FelLicht (lokale zone, echo lost op) |
|---|---|---|
| Kleur | *gloed*: amber en goud | *FelLicht*: koud wit en ijsblauw |
| Vorm | rond of kegel, verloop in banden | **altijd een scherpe kegel of balk**, met een witte rand van 1 px |
| In de lucht | stof (warme pixels) | glinsteringen: witte pixel met een verticale streep van 3 px |
| Op de vloer | lichtpoel in banden | egale witte poel in tint 5–7 |
| Echo en speler 2 | bestaan gewoon | de echo lost op (schaduwdeeltjes) |

Gemeten verschil warm/FelLicht: ΔE 73–83, ook bij deuteranopie (§7).

### 4.4 Licht- en schaduwgeometrie
- **Lichtgeometrie** (bestaat alleen in licht): effen ivoor, een bovenrand in tint 7, **gegraveerd maaswerk** (gotische tracering), en daaronder een glanslijn. Rechte, strakke vormen.
- **Schaduwgeometrie** (bestaat alleen in schaduw): paars, **diagonale arcering**, een lichte bovenrand, en **hangende ranken** eronder. Organische vormen.
- **Opgeloste schaduwgeometrie houdt géén kenmerken van iets draagbaars**: geen arcering, geen ranken, geen omtrek. Waar de brug ophoudt, staat **één verticale eindrand in tint 6**, even hard als de laaggrens, plus een paar losse schaduwdeeltjes erboven (visie-review PR #17, punt 2).
- Gedeelde dingen (zuil, kade, muren) zijn gewone steen en baksteen.

### 4.5 Water
Water is een **beeldlaag en een wereldstaat**, geen speellaag. De waterstand is zichtbaar aan drie dingen: het **oppervlak** (1 px-lijn in tint 5–7 met onderbrekingen), wat **eronder verdwijnt** (vormen onder water blijven vaag zichtbaar in de water-ramp) en de **getijdenrand** (klimop in tint 1–2) op de oude stand zodra het water gezakt is. Wat opengaat als het water zakt (duiker, loopbrug, deur met stoep), is in de grijze toestand **net onder het oppervlak** te zien of te raden. Omdat in grijs alles onder het hoge water in water-tint 1 valt, krijgen die vormen daar een **vaste contour van 1 px in water-tint 3** (ΔL* ≥ 8 tegen het water, gemeten in §7.5); het lijf van de loopbrug staat in tint 2. De rest onder water blijft tint 1 ([#98](https://github.com/cesarvangerwen-glitch/echoborn/issues/98)). Reflecties zijn gespiegelde heldere pixels, om de rij onderbroken, met golfverschuiving.

### 4.6 Budget
De R5-scène telt (rekenregel uit `docs/tech/lichtmeting.md`, PR #62, in review): grijs = lantaarn 3 + echo 0,8 + saturatiepass 4 + occluders ± 0,5 = **± 8,3 LE**; opgepompt = lantaarn 3 + straatlamp met schaduw 2,5 + FelLicht-zone 3 + echo 0,8 + saturatiepass 4 + occluders ± 0,5 = **± 13,8 LE**. Beide passen in ≤ 20 LE. Ramen, belfort en halo's zijn sprites (emissief), geen lichten.

---

## 5. Van grijs naar kleur

| | Grijs-donker (nog niet opgepompt) | Opgepompt-kleurrijk |
|---|---|---|
| Wereld | Grijze ramps (§3), omgeving 1, dunne koude bundels door het wolkendek | Volle ramps, omgeving 2, stadsgloed boven de daken, warme bundels uit het belfort |
| **Licht = kleur** | In de lichtpoel van een lamp keert de kleur terug: banden 2 = half, ≥ 3 = vol. Zo voelt de speler de kernloop al vóór het eerste gemaal | Overal kleur |
| Water | Hoog: duiker, loopbrug en de stoepen van de deuren staan onder, alleen als contour te raden (§4.5). De **loopbrug** is de richel onderaan de kanaalwand (R5: rij 362–368 op 640×400, onder de duiker); de koperen perspijp met beugels op de gemaalkade is géén loopbrug en staat in beide toestanden droog | Gezakt: duiker, loopbrug en getijdenrand zichtbaar, het rad staat vrij |
| Ramen, gemaal | Donker, gemaal uit | Warm verlicht, gemaal aan (machine zichtbaar achter het boograam) |
| **Speler 1** | **Altijd in kleur.** Hij is de machinist die het licht brengt | idem |
| **Echo** | Grijs en somber: lichtgrijze rand, grijze arcering. **Alleen de ogen houden een zweem amber** (de eigenaarskleur) | Rand amber, paarse arcering, amber ogen, de sjaal flakkert amber in de arcering |
| **Speler 2** | Vol zwart lijf, grijs-cyaan rand, grijze sjaal, **ogen wit-cyaan** | Cyaan rand en sjaal |
| Gameplay-kleuren | Schaduwgeometrie en lichtgeometrie houden **minstens 40–50 % chroma** (de laag moet leesbaar blijven) | Vol |

**Overgang (in de game):** het oppompen kleurt de wijk vanaf het gemaal naar buiten in, als een golf (± 2 s), met de banden: eerst half, dan vol. Technisch is dat de saturatiepass met een straal per wijk (Technical Artist). De echo kleurt mee, met een korte vertraging van ± 0,5 s, als iemand die wakker wordt.

**Een grijze echo in een grijze wereld blijft leesbaar** door (1) de rand in een lichtheid ver boven de omgeving (ΔL* 64 tegen grijze steen), (2) de buitencontour van 1 px bijna-zwart, (3) het silhouet van de eigenaar, en (4) beweging: twee nabeelden en de echo herhaalt jouw pose. In de R5-scène: contour ΔL* 69 in grijs (§7).

---

## 6. Figuren: wie is wie

| | Vulling | Rand | Ogen | Accent | Silhouet |
|---|---|---|---|---|---|
| **Speler 1** | **vol, licht** (crème) | donker, 1 px | donker | **amber sjaal** | pet met klep, korte jas, sjaal waait mee |
| **Speler 2** | **vol, bijna zwart** | **cyaan**, 1 px, met bijna-zwart erbuiten | wit-cyaan | cyaan sjaal, **pikhaak** | brede hoed, lange jas met wijde zoom, staf |
| **Echo** (solo) | **hol**: diagonale arcering om de 3 px, de achtergrond schijnt erdoor | in eigenaarskleur (amber), 1 px, met bijna-zwart erbuiten | eigenaarskleur | 2 nabeelden (alleen rand, 22 % en 40 % gestippeld) | dat van de eigenaar |
| **Gedeelde echo** (finisher) | hol | **amber en cyaan om en om** (per 4 px) | wit | 2 nabeelden in beide kleuren | beide silhouetten, half over elkaar (v1) |
| Vijand | vol, **donker**, laag en breed | donker, met een **rode bovenrand** | wit | gloeiende rode kern | stekels, nooit rechtop zoals een speler |

**Regels:**
1. **Kleur zegt van wie, vulling zegt of het leeft.** Amber = speler 1, cyaan = speler 2; vol = levend, hol = echo.
2. De **arcering is aan de sprite verankerd**, niet aan het scherm. Zo kruipt het patroon niet als de echo beweegt (geen flikkering).
3. **Geen vijand in amber of cyaan.** De vijand verschilt van speler 1 ook in **vorm** (laag, breed, stekels) en **waarde** (donker lijf), omdat amber en rood bij deuteranopie dichter bij elkaar liggen (stijltests §4.2).
4. **Leesbaarheid in getallen:** elke gameplay-figuur haalt ΔL* ≥ 40 tegen zijn directe achtergrond op de **vulling of de contour**, in elke toestand. Hulpmiddel: het script meet het.

---

## 7. Metingen en de ΔE-regel

### 7.1 De regel
> **Sleutelkleuren die iets anders betekenen, liggen minstens ΔE76 30 uit elkaar, en minstens 25 bij gesimuleerde deuteranopie.** Lukt dat niet, dan verschillen ze ook in **waarde (ΔL* ≥ 20) of vorm**.

Dit volgt uit de stijltests: daar lag het amber van speler 1 maar ΔE 30 (25 bij deuteranopie) van de crème lichtgeometrie. Dat was op de grens. In dit palet ligt het verder uit elkaar, omdat de lichtgeometrie ivoor met grijsbruine schaduw is en geen crème-amber.

### 7.2 Gemeten op het palet van deze bible
Gemeten met `genereer_r5.py` (ΔE76 in CIELAB; deuteranopie volgens Machado et al. 2009, volle sterkte).

| Paar | ΔE normaal | ΔE deuteranopie | ΔL* | Haalt de regel? |
|---|---:|---:|---:|---|
| **Amber sjaal / lichtgeometrie (vlak, tint 4)** | **53,2** | **46,8** | 6,4 | ja (ruim); vorm verschilt ook |
| Amber sjaal / lichtgeometrie (bovenrand, tint 7) | 73,0 | 67,7 | 27,4 | ja |
| Amber sjaal schaduwkant / lichtgeometrie vlak | 51,9 | 40,8 | 28,6 | ja |
| Amber / cyaan (speler 1 / speler 2) | 107,7 | 91,9 | 13,1 | ja |
| Warm licht (gloed 5) / FelLicht (5) | 73,5 | 72,3 | 7,4 | ja |
| Warme lichtval (gloed 4) / FelLicht (3) | 83,1 | 81,0 | 7,3 | ja |
| Cyaan / schaduwgeometrie (tint 3) | 94,9 | 67,2 | 69,7 | ja |
| Grijze echo-rand / grijze steen (tint 2) | 63,8 | 63,9 | 63,8 | ja |

**Let op:** amber en het vlak van de lichtgeometrie liggen in **waarde** dicht bij elkaar (ΔL* 6,4). Het onderscheid zit in tint en verzadiging, en in de **vorm**: een sjaal waait en hoort bij een figuur, een platform is recht en draagt maaswerk. Een asset die de vorm-taal van §4.4 loslaat, moet opnieuw gemeten worden.

### 7.3 Leesbaarheid van de figuren
ΔL* tussen figuur en directe achtergrond (ring van 2–6 px), op 640×400:

| Toestand | Figuur | Vulling | Contour |
|---|---|---:|---:|
| grijs | speler 1 | 66,7 | 70,3 |
| grijs | speler 2 | 7,6 | **67,3** |
| grijs | echo | 0,0 (hol) | **68,7** |
| kleur | speler 1 | 48,1 | 51,8 |
| kleur | speler 2 | 18,6 | **63,1** |
| kleur | echo | 0,0 (hol) | **58,2** |

Een vulling van 0 bij de echo is de bedoeling: hol betekent dat de achtergrond doorschijnt. De echo en speler 2 lezen op hun contour.

**Laaggrens naast de zuil** (achtergrondgevels, 16 px aan elke kant): grijs L* 16,5 tegen 3,8; kleur 30,1 tegen 11,3. Daarbovenop komt de stippellijn in de lucht.

### 7.4 Speler 2 naast de echo, op ware Deck-grootte en in beweging
Huiswerk uit de EP-review op PR #17 (punt 5). Getest in `r5_beweging_*`: speler 2 (vol), de echo van speler 1 (hol, amber) en het **slechtste geval**, een holle echo met het silhouet én de kleur van speler 2 (cyaan). Dat geval bestaat onder 7A niet als vaste figuur, maar lijkt het meest op de finisher. Elk loopt in 4 frames, in schaduw op de brug.

- **Op ware grootte** (± 7 mm figuurhoogte): speler 2 is een egale zwarte vorm (binnenkant L* 2,3). De holle echo's tonen de achtergrond (L* 15–16 mediaan). Het verschil vol/hol blijft zichtbaar, ook bij gelijke kleur en gelijk silhouet.
- **Het raster loopt niet dicht:** de arcering om de 3 px (op de Deck 6 fysieke pixels) laat binnenin een spreiding van L* 22–31 over. Een dambordraster van 1 px vervaagt op die grootte naar verwachting tot egaal grijs (niet gemeten); dat gebruiken we dus niet.
- **Geen flikkering** in de test, omdat de arcering aan de sprite hangt en mee beweegt met de figuur. Een echte meting op een Deck volgt (*Open punten*).
- **Nabeelden:** met 3 nabeelden las de echo op Deck-grootte als meerdere figuren (stijltests). Daarom zijn het er nu 2, alleen de rand, en gestippeld.

### 7.5 Wat onder water staat, in grijs
Huiswerk uit de visie-review op P2 ([#98](https://github.com/cesarvangerwen-glitch/echoborn/issues/98)). Gemeten met `genereer_r5.py`: ΔL* van de contour (water-tint 3) tegen het water eromheen (tint 1, L* 4,3). Op ware Deck-grootte (96 ppi) is het de piek van de lijn (p90), zoals bij de contouren in §7.3.

| Vorm onder water | ΔL* op 640×400 | ΔL* op ware Deck-grootte | Diepte onder het oppervlak |
|---|---:|---:|---:|
| duiker (boog en dagkanten) | 11,6 | 10,3 | 10 px |
| loopbrug (looprand; onderrand onderbroken) | 11,6 | 9,4 | 38 px |
| deur met stoep | 11,6 | 10,8 | 0–10 px |

De loopbrug ligt 38 px diep: te raden, niet "net onder" het oppervlak, omdat hij in de opgepompte toestand niet mag verschuiven. Ook met de contouren valt 90 % van het kanaal onder water nog in tint 1: het water blijft donker en diep, de vormen zijn te raden, niet te zien. Water-tint 2 (ΔL* 4,9) is te zwak voor een contour; die gebruiken we alleen voor een vlak (het lijf van de loopbrug). De opgepompte toestand verandert niet: daar staat niets hiervan onder.

---

## 8. Tegen een generieke 2D-look (eisen)

De markt voor pixel-metroidvania's is vol. Deze eisen maken een screenshot herkenbaar als deze game; Marketing kan erop bouwen. **Elk buitenscherm van de slice-art haalt ze allemaal.** Voor **interieurs** (gemaal, duikers, kelders) gelden eis 1, 3, 5, 6 en 7. Eis 2 wordt daar licht door ramen, roosters of machinegloed als achtergrondbundel, en eis 4 komt via de materialen (baksteen, koper, sluisdeuren, raderwerk).

1. **Het licht-schaduwmotief is de handtekening.** In elk scherm staat minstens één harde schaduwwig of lichtkegel die over het speelvlak én de achtergrond loopt, met de stippel-laaggrens.
2. **Volumetrische bundels in de achtergrond**: warm uit belfort, ramen en gemalen (opgepompt), dun en koud door het wolkendek (grijs). Alleen in de parallax-lagen, nooit over het speelvlak.
3. **Licht brengt kleur terug.** In een grijze wijk is de lichtpoel van een lamp het enige gekleurde. Geen enkele andere game doet dit zo; het is ons beeld van de kernloop.
4. **Lage Landen, niet "fantasy-middeleeuws":** trapgevels, belforten met galmgaten, blauwe hardsteen, baksteen, luiken, begijnhof, gemalen, schoepenraderen, sluisdeuren. Geen burchten, geen generieke grotten.
5. **Vlaamse Primitieven in het licht**: weinig licht, maar helder, warm en gedetailleerd waar het valt (stof, randlicht, raamroeden). Het donker blijft rustig.
6. **Vol = levend, hol = echo** en **kleur = van wie**, zonder iconen.
7. **Hue-shift in elke ramp** (schaduw koel en paars, licht warm). Geen ramps die alleen donkerder worden.

**Niet doen:** neon-cyberpunkpaars over alles, bloom over het speelvlak, zachte schaduw met halfschaduw, outlines rond de omgeving, "dungeon-bruin", chromatische aberratie, vignet over gameplay, horrorbeelden (schedels, bloed, verdronken figuren; toonregels pitch §6).

---

## 9. Do's en don'ts per rol

| Doen | Niet doen |
|---|---|
| Elke kleur uit een ramp van §3; nieuwe materialen als ramp van 8 met hue-shift | Losse kleuren, of halftransparante pixels in het speelvlak |
| Lichtbronnen met de vijf kenmerken van §4.2 | Een lamp zonder halo of zonder kern ("doffe bol", stijltests) |
| Achtergrond rustiger dan het speelvlak (ruis alleen in dithering van licht) | Ruis of drukke textuur op loopvlakken |
| Elke pose van speler 1 ook als hol echo-silhouet controleren | Een pose die hol niet meer leest (armen of benen van 1 px breed) |
| Vijanden laag, breed, donker, met een rode bovenrand | Vijanden in amber of cyaan, of rechtop zoals een speler |
| Waterstand laten zien aan oppervlak, onderwatervormen en getijdenrand | Water als speellaag tekenen (zwemmen, duiken) |

---

## 10. Open punten

| Punt | Wie | Wanneer |
|---|---|---|
| Paletten per gebied (slice: polderwijk met het eerste gemaal; daarna de andere 2–3 gebieden) en hun grijs-kleur-varianten | Art Director met Concept Artist | Bible v1, na T3 (gebiedsthema's van de Narrative Designer) |
| Banden-licht in Godot 4.6: 2D-licht kwantiseren in 5 banden, harde schaduw, saturatiepass per wijk, stippel-laaggrens als shader of als lijn | Technical Artist | Vóór T7; deze bible geeft de visuele norm |
| Ware Deck-test op een echte Steam Deck: flikkering van de arcering en de nabeelden in beweging; onderwatercontouren in grijs (ΔL* 9,4–10,8 gesimuleerd, §7.5) | Technical Artist (met Engine & Platform Programmer) | Bij de eerste Deck-build (T7) |
| Animatienormen (loopcyclus, sprong, landing, merk, ontploffing), frames en timing; de loopcyclus in de bewegingstest is placeholder | Animator | Na de flow-test, vóór de slice-art |
| Hoe zichtbaar zijn vijanden die alleen in de schaduwlaag bestaan | Art Director met Combat Designer | Bible v1 |
| Combat-leesbaarheid in één frame: schaduwmerk, ontploffing, parade, met twee spelers en de finisher | Art Director met Combat Designer | Bible v1, na T3 |
| Gedeelde echo (finisher): de beeldtaal van §6 tekenen en testen | Art Director | Bible v1 |
| Draagt de echo sporen van de sluiswachter naarmate hij oplevert (V2)? Nu heeft hij het silhouet van de eigenaar | Narrative Designer met Art Director en Creative Director | Bij T9 |
| Kleurenblind-modus (alternatieve accentkleuren) | UX Designer met Art Director | Preproductie |
| HUD en lichtmeter in dezelfde beeldtaal | UI Artist met UX Designer | T10 |
| Placeholder-lichtmeter in de flow-kamer (zonder meter is "oppompen" niet te testen) | Lead Game Designer met UI Artist | Bij de start van de flow-kamer |
