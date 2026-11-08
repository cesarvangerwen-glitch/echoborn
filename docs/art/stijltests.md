# Stijltests: 2D vs 2.5D

Eigenaar: Art Director · Versie 0.1 · Issue: #7 · Status: ter review (Executive Producer)
Gebaseerd op `docs/beslissingen.md` (stand 2026-11-08: "Stijl: 2D of 2.5D, keuze na stijltests van de Art Director"), `docs/concept/pitch.md` v0.1 en `docs/tech/ontwerp.md` v0.

---

## 1. Samenvatting

- Ik heb **dezelfde scène twee keer** gemaakt: in 2D (pixel art) en in 2.5D (3D-look). Beide tonen speler 1, speler 2, de echo, een vijand, en de overgang tussen licht- en schaduwlaag.
- **Aanbeveling: 2D**, pixel art op 640×360 (op de Steam Deck 640×400), met dynamisch 2D-licht in drie banden.
- Waarom: de grens tussen licht en schaduw is in 2D ±45% scherper (ΔL* 40,5 tegen 27,7). Speler 2 en een echo zijn in 2D duidelijk uit elkaar te houden. De stijl past bij de 2D-physics van de echo-spike, bij de Compatibility-renderer en bij een team dat in 2D is samengesteld (2D Environment Artist, Animator, Concept Artist; geen 3D-modelleur of rigger).
- De keuze is een CEO-besluit. De vraag staat in §8, in het format van `ceo-beslissing`, zodat de Producer er na de interne review een issue van kan maken.

Alle beelden zijn **placeholder**: ze testen leesbaarheid en richting, niet eindkwaliteit. Ze zijn volledig met code gemaakt (Python, numpy, scipy, Pillow), zonder externe assets of fonts. De labels gebruiken een eigen pixelfont, zie §9.

## 2. De testscène

Eén kamer, beide stijlen exact dezelfde compositie (1280×720):

| Element | Waar | Laag | Wat het test |
|---|---|---|---|
| Hangende lantaarn | links | licht (amber) | Bron van de lichtlaag; lichtval op muur en vloer |
| Zuil | midden | gedeeld | Werpt een schaduw naar rechts: daar begint de schaduwlaag |
| Lichtplatform | boven de zuilschaduw | alleen licht | Lichtgeometrie: vast in het licht |
| Schaduwbrug over een kloof | in de zuilschaduw | alleen schaduw | Pillar 2: "een lichtbron verplaatsen zodat er een schaduwbrug ontstaat" |
| Lichtschacht uit het plafond | rechts | licht (bleek) | Waar de schacht de brug raakt, **lost de brug op**: de overgang zelf |
| Schaduwrichel | rechtsboven | alleen schaduw | Plek voor de schaduwspeler |
| **Speler 1** | op de vloer links | licht | Levend personage, amber |
| **Echo van speler 1** | midden in een sprong boven de brug | schaduw | Herhaling, amber omlijnd, met spoor en 10s-ring |
| **Speler 2** | op de schaduwrichel | schaduw | Live schaduw in co-op, cyaan |
| **Vijand** | rechts in de lichtschacht | licht | Laag, breed, stekelig; rode kern |

Het verschil tussen speler 2 (live schaduw) en een echo laat ik in beide stijlen zien, omdat de regel nog open is (Lead Game Designer, #6; ontwerp.md risico C1). De beeldtaal werkt voor beide uitkomsten.

### Beeldtaal van de figuren (voorstel voor de art bible)

| | Vulling | Rand | Ogen | Accent |
|---|---|---|---|---|
| Speler 1 | licht (crème), twee tinten | donkere contour | donker | amber sjaal |
| Speler 2 | bijna zwart, vol | **cyaan** contour/rim | wit-cyaan | cyaan sjaal |
| Echo van speler N | donkerpaars, **half doorzichtig/gerasterd** | in de kleur van de **eigenaar** | in eigenaarskleur | spoor van 3 nabeelden + ring met resterende tijd |
| Vijand | donkerrood, laag en breed, stekels | donker, rode bovenrand | wit | gloeiende rode kern |

Regel: **levend = vol, echo = hol.** De kleur zegt van wie iets is (amber = speler 1, cyaan = speler 2); de vulling zegt of het levend is of een herhaling. Amber en cyaan liggen op de blauw-geel-as en blijven dus ook bij rood-groenkleurenblindheid uit elkaar.

## 3. De beelden

Alle bestanden staan in `docs/art/stijltests/`.

| Bestand | Wat |
|---|---|
| `stijltest_2d_placeholder.png` | Scène in 2D, 1280×720 (640×360 ×2) |
| `stijltest_25d_placeholder.png` | Scène in 2.5D, 1280×720 |
| `vergelijking_2d_25d_placeholder.png` | Beide onder elkaar, op volle resolutie |
| `lagen_2d_placeholder.png`, `lagen_25d_placeholder.png` | De licht- en schaduwlaag uit elkaar: laagkaart, alleen licht, alleen schaduw, samengesteld |
| `personagekaart_placeholder.png` | Speler 1, echo s1, speler 2, echo s2 en vijand op licht, op de grens en in schaduw, in beide stijlen |
| `leesbaarheid_grijs_kleurenblind_placeholder.png` | Grijswaarden (waardetest) en deuteranopie-simulatie |
| `steamdeck_2d_1280x800_placeholder.png`, `steamdeck_25d_1280x800_placeholder.png` | Native 16:10-beeld voor de Steam Deck |
| `steamdeck_ware_grootte_placeholder.png` | Beide op ware Deck-grootte (bij een monitor van ±96 ppi), plus een uitsnede |
| `bron/genereer_stijltests.py`, `bron/pixelfont.py` | De code die alles maakt; draait in ±15 s |

**Opnieuw maken:** `python3 docs/art/stijltests/bron/genereer_stijltests.py` vanaf de repo-root. Het script print ook de metingen uit §4.

### Hoe de twee stijlen gemaakt zijn

| | 2D | 2.5D |
|---|---|---|
| Resolutie | 640×360, ×2 (nearest neighbour); Deck 640×400 ×2 | 1280×720 / 1280×800 native, anti-aliased |
| Licht | Lantaarn met harde schaduw van de zuil, in **3 banden** met ordered dithering; schacht met harde rand | Zachte schaduw (5 lichtpunten, halfschaduw), volumetrisch licht, bloom, vignet |
| Vormen | Platte tinten + 1 px contour, figuren onbelicht (altijd leesbaar) | Normalen uit het silhouet (bol), Lambert-licht, fresnel-rim, doorschijnende echo |
| Diepte | Parallax-silhouetten achter de bogen | Mist op de achtergrond, onscherpe voorgrond, perspectief op het vloeroppervlak |
| Laaggrens | Gestippelde lichtrand in de lucht | Zachte gloed langs de grens |

**Beperking:** de 2.5D-test is een *gesimuleerde* 3D-look (een benadering van wat een Godot-3D-scène of een 2D-scène met normal maps oplevert), geen render uit Godot. De conclusies over leesbaarheid gelden voor beide 2.5D-routes; de haalbaarheid behandel ik apart in §5.

## 4. Leesbaarheid

### 4.1 Metingen

Gemeten op 1280×720 met het script: het verschil in lichtheid (CIELAB ΔL*, 0–100) tussen een figuur en de achtergrond direct eromheen (3–12 px). *Vulling* is de binnenkant van het silhouet, *contour* de buitenrand inclusief outline (2D) of rim (2.5D). Een figuur leest goed als minstens één van beide hoog is. Als vuistregel houd ik ≥ 40 aan voor gameplay-figuren.

| Figuur | 2D vulling | 2D contour | 2.5D vulling | 2.5D contour |
|---|---|---|---|---|
| Speler 1 | 70,1 | 70,1 | 54,4 | 49,2 |
| Echo | 21,4 | **72,8** | 8,5 | **62,0** |
| Speler 2 | 2,5 | **70,6** | 9,5 | **64,9** |
| Vijand | 36,8 | 47,1 | 33,5 | **32,6** |

| Laaggrens (muur vlak bij de grens, 16 px aan beide kanten) | 2D | 2.5D |
|---|---|---|
| Mediaan L* lichtkant | 45,5 | 32,9 |
| Mediaan L* schaduwkant | 5,0 | 5,2 |
| **ΔL* over de grens** | **40,5** | **27,7** |

Kleurverschil (ΔE76) tussen sleutelkleuren, normaal → bij deuteranopie:

| Paar | Normaal | Deuteranopie |
|---|---|---|
| Amber (speler 1) / cyaan (speler 2) | 118 | 107 |
| Amber (speler 1) / rood (vijandkern) | 62 | 38 |
| Cyaan (speler 2) / paars (schaduwgeometrie) | 100 | 53 |

### 4.2 Wat ik zie

1. **De laaggrens (pillar 2) is in 2D duidelijk beter.** Harde banden plus een stippellijn laten op de pixel zien waar de schaduw ophoudt. Dat is gameplay-informatie: waar stopt de schaduwbrug? In 2.5D is de halfschaduw 10–20 px breed. Dat is mooi, maar dan moet de speler gokken. Je kunt dat in 2.5D oplossen met een randshader, maar dan maak je de 3D-look juist weer grafisch.
2. **Speler 1 is in beide stijlen sterk.** In 2D blijft hij ook in schaduw licht (de figuren zijn bewust onbelicht). In 2.5D wordt hij in schaduw grauw (zie de personagekaart).
3. **Echo en speler 2 lezen in beide stijlen vooral op hun contour.** Dat is zo bedoeld: het zijn schaduwwezens in een donkere laag. In 2D is het verschil tussen speler 2 (vol zwart) en een echo (gerasterd) direct te zien. In 2.5D hangt dat verschil alleen af van doorschijnendheid. Op de personagekaart lijken "speler 2" en "echo s2" in 2.5D op elkaar. **Dit is het zwaarste leesbaarheidsprobleem van 2.5D**, omdat het de rolregel raakt: "beide spelers en hun echo's zijn direct van elkaar te onderscheiden".
4. **Het spoor van de echo** is in 2D een stippel-nabeeld en leest als beweging. In 2.5D lezen de nabeelden op Deck-formaat als *vier* figuren. Dat is op te lossen (minder nabeelden, vervagen), maar het is een extra risico.
5. **De vijand** leest in 2D op elke achtergrond door de rode bovenrand en de stekels. In 2.5D verdwijnt het lijf in schaduw bijna; alleen de kern blijft zichtbaar (personagekaart, onderste rij). Ook dat vraagt in 2.5D een extra rimshader.
6. **Kleurenblindheid:** amber en cyaan blijven ruim uit elkaar. Amber tegen het rood van de vijand zakt naar ΔE 38. Dat is nog te onderscheiden, maar de vijand moet daarom altijd ook op **vorm** (laag, breed, stekels) en **waarde** (donker lijf) verschillen van speler 1 (rechtop, licht lijf). In beide stijlen is dat in orde; het gaat als harde regel in de art bible.
7. **Grijswaarden:** in 2D blijven alle vier de figuren en de laaggrens zichtbaar. In 2.5D vallen de echo-nabeelden en het vijandlijf weg in de donkere laag.

## 5. Haalbaarheid in Godot 4.6

Dit is mijn inschatting als Art Director. De technische bevestiging en de prestatiemeting horen bij de Technical Artist en de Technical Director (ontwerp.md, risico C7).

| | 2D | 2.5D, route 1: echte 3D-scène | 2.5D, route 2: 2D met normal maps |
|---|---|---|---|
| Physics en echo | Sluit direct aan op de spike (2D-physics, `StaticBody2D`, physics-lagen 1–5) | Ofwel 3D-physics met vergrendelde as (spike herschrijven), ofwel 2D-sim met een 3D-weergave ernaast (twee werelden synchroon houden) | Sluit direct aan op de spike |
| Licht- en schaduwlaag | `PointLight2D` + `LightOccluder2D`, `light_mask` per CanvasItem, schaduwlaag als eigen CanvasLayer of shader; past bij ontwerp.md §8 | Schaduwlaag via een tweede camera/viewport of stencil-materialen; meer werk en meer GPU | Als 2D, plus normal maps per sprite |
| Renderer | Werkt in de huidige **Compatibility**-renderer (`gl_compatibility` in `project.godot`) | Volumetrisch licht en zachte schaduwen vragen Forward+ of Mobile; Compatibility heeft beperktere 3D-effecten (te verifiëren door de Technical Artist) | Werkt in Compatibility |
| Pixel-perfect | Viewport-stretch met integer-schaling: 640×360 → 1280×720, 640×400 → 1280×800 (Deck) | n.v.t. | n.v.t. (hogere resolutie nodig voor normal maps) |
| Assetproductie | Sprites en tiles per frame; past bij de rollen die we hebben | Modelleren, riggen en 3D-animatie (bv. Blender, eerst in `docs/licenties.md`); **geen 3D-rol in het organigram** | Elke sprite ook een normal map: ±1,5–2× tekenwerk |
| Risico voor scope (5–7 uur, 3–4 gebieden) | Laag | Hoog | Midden |

## 6. Steam Deck

- **Scherm:** 1280×800 (16:10), 7 inch, ±216 ppi. Dat is ruim twee keer zo dicht als een gewone monitor: alles oogt kleiner.
- **2D past exact:** 640×400 ×2 = 1280×800. Er is geen letterbox nodig en het beeld blijft scherp (integer-schaling). Op de Deck zie je 40 px meer kamer in de hoogte (`steamdeck_2d_1280x800_placeholder.png`).
- **Ware grootte** (`steamdeck_ware_grootte_placeholder.png`): een figuur is ±60 px hoog, op de Deck ±7 mm. In 2D blijven speler 1, de cyaan contour van speler 2, de amber rand van de echo en de vijand herkenbaar. In 2.5D verliezen de echo-nabeelden en de vijand in schaduw als eerste hun vorm. Fijne details zoals de zachte rim worden op die grootte grijze ruis.
- **Prestaties:** niet gemeten in deze test. 2D-licht met een handvol lichtbronnen per kamer is naar verwachting licht genoeg; volumetrisch licht, zachte schaduwen en bloom in 3D zijn de duurste onderdelen. Meten op een echte Deck: Technical Artist en Engine & Platform Programmer (risico C7).

## 7. Vergelijking en aanbeveling

| Criterium | 2D | 2.5D |
|---|---|---|
| Laaggrens leesbaar (pillar 2) | **Sterk** (ΔL* 40,5, harde rand) | Matig (ΔL* 27,7, zachte rand) |
| Speler / echo / speler 2 / vijand uit elkaar houden | **Sterk** (vol tegen gerasterd, contourkleuren) | Matig (speler 2 en echo lijken op elkaar; vijand verdwijnt in schaduw) |
| Sfeer, "duister maar niet gruwelijk", melancholie | Goed (dithering, warm tegen koud) | **Sterk** (volumetrisch licht, diepte) |
| Herkenbaar in één screenshot | Goed; pixel-metroidvania's zijn een drukke markt, dus het licht-schaduw-motief moet het onderscheid maken | Goed; valt meer op tussen pixel-art-titels |
| Haalbaar in Godot 4.6 met de huidige spike | **Sterk** | Route 1 zwak, route 2 matig |
| Steam Deck | **Sterk** (integer 1280×800) | Matig (duurdere effecten, details vervagen) |
| Productie met dit team en deze scope | **Sterk** | Zwak (route 1) tot matig (route 2) |

**Aanbeveling: 2D**, pixel art op 640×360 (Deck 640×400), met dynamisch 2D-licht in banden. De sterke kanten van 2.5D (zachte lichtval, diepte) nemen we gericht mee waar ze de leesbaarheid niet raken: volumetrische lichtbundels alleen in de achtergrond, en parallax-lagen voor diepte. Speelvlak en figuren blijven strak en hard belicht.

Resolutie, palet en lijnwerk binnen 2D bepaal ik zelf in de art bible. Daar is geen CEO-besluit voor nodig.

## 8. Vraag aan de CEO (concept voor het `ceo-beslissing`-issue)

> Concept. Na goedkeuring in de interne review maakt de Producer hier een issue van met label `ceo-beslissing`. Titel: **[CEO] Stijl van Echoborn: 2D of 2.5D**. De kopjes hieronder worden in het issue `##`.

**Van:** Art Director

### Probleem
Het beslissingslog laat de stijl open ("2D of 2.5D, keuze na stijltests"). De stijltests zijn klaar (`docs/art/stijltests.md`, PR bij #7). De art bible, de assetlijst en alle art- en animatiewerk in fase 2 hangen van deze keuze af.

### Vragen

**1. In welke stijl maken we Echoborn?**
- **A. 2D: pixel art (640×360, Deck 640×400) met dynamisch 2D-licht** ⭐ Aanbevolen: scherpste licht-schaduwgrens en figuren, past op de spike en de Deck; geen extra rollen of tools nodig.
- **B. 2.5D: 3D-look (3D-scène of 2D met normal maps)**: meer sfeer en diepte, maar zwakkere laaggrens en echo-leesbaarheid; 3D-rol en extra tools of ±1,5–2× tekenwerk nodig, en mogelijk een andere renderer.

### Waarom deze aanbeveling
Licht en schaduw zijn de kaart (pillar 2), dus de grens tussen de lagen en het verschil tussen speler, echo en vijand moeten in één oogopslag te lezen zijn. Dat lukt in 2D op elke achtergrond en op Deck-formaat het best (ΔL* over de laaggrens 40,5 tegen 27,7). 2D sluit ook aan op de bestaande 2D-echo-spike en op een team zonder 3D-rollen, en past dus binnen scope en budget per fase.

### Wat wacht hierop
- `docs/art/bible.md` (Art Director)
- `docs/art/assetlijst.md` (Art Director en Producer)
- Technische art-pipeline en lichtmeting op de Steam Deck (Technical Artist)
- Werk van Concept Artist, 2D Environment Artist en Animator in fase 2

---
*CEO: antwoord kort met een comment die begint met `Besluit:`, bijvoorbeeld:*
- *`Besluit: 1A`*
- *`Besluit: akkoord` (alle aanbevelingen)*
- *Een eigen antwoord mag ook: `Besluit: 1 = <tekst>`*

## 9. Licenties en bronnen

- Geen externe assets, fonts of plug-ins gebruikt. Python, numpy, scipy en Pillow zijn alleen gereedschap om de beelden te maken. Ze zitten niet in de game en worden niet meegeleverd.
- De labels in de beelden gebruiken een eigen 5×7-pixelfont (`bron/pixelfont.py`), getekend voor deze test.
- Als we in fase 2 tools als Aseprite of Blender gebruiken, vraag ik eerst opname in `docs/licenties.md` aan bij de Business/Legal Advisor.

## 10. Open punten

| Punt | Wie | Wanneer |
|---|---|---|
| Lichtkosten meten op een Steam Deck (2D-licht met schaduw, 2–4 bronnen per kamer, 2 spelers + echo's) | Technical Artist (+ Engine & Platform Programmer) | Na het CEO-besluit; volgt uit ontwerp.md C7 |
| Echo-regel in co-op (live schaduw, opgenomen echo, of allebei) bepaalt of "echo s2" nodig is | Lead Game Designer (#6) | Lopend |
| Art bible v1 (paletten per gebied, schaal, lijnwerk, belichting, spelers en echo, do's en don'ts) | Art Director | Na het CEO-besluit |
| Hoe zichtbaar mogen vijanden zijn die alleen in de schaduwlaag bestaan (pitch, pillar 2)? | Art Director met Combat Designer | Art bible |
| Kleurenblind-modus (alternatieve accentkleuren) | UX Designer met Art Director | Preproductie |
