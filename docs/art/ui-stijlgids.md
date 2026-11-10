# UI-stijlgids *Polderlight*

Versie 0.1.1 · Eigenaar: UI Artist · Issue [#87](https://github.com/cesarvangerwen-glitch/echoborn/issues/87) (T10 deel 2: eind-UI-art) · Review: Art Director
Basis: UX-spec `docs/ux/hud-menus.md` v0.1.2 en `docs/ux/coop.md` (PR #129), art bible v0 (`docs/art/bible.md` §2, §3, §6, §7), assetlijst S-17.

Alles in deze gids is **eigen werk** en wordt gemaakt door één script, zonder externe assets:

```
python3 docs/art/ui/bron/genereer_ui.py      # vanaf de repo-root, ± 3 s
```

Het script schrijft de assets naar `game/art/ui/`, de previews naar `docs/art/ui/` en print de metingen van §6 en §7.

## 0. Werkaannames (kader §5)

| # | Aanname | Bron |
|---|---|---|
| W1 | Interne resolutie **640×360** (pc) en **640×400** (Deck), alleen integer schalen, nearest neighbour. Alle assets zijn 1:1 op die resolutie getekend. | besluit #18, bible §2 |
| W2 | Staart **D = 120 ticks** (bereik 90–180). De animaties hier hangen niet af van D: de klokring telt slagen, het echo-icoon telt voortgang 0–1. | besluit #51 (8A), UX W1 |
| W3 | Max. **twee lichamen**; solo P1 + echo, co-op P1 + P2. Amber = P1 en zijn echo, cyaan = P2. | besluit #51 (7A), bible §6 |
| W4 | Talen **EN en NL**, tekstvakken voor EN + 35 %. | besluit #51 deel 1 (5A), UX §6 |
| W5 | **F1 is gehaald**; F0 nog niet. Na F0 kan de UX Designer maten bijstellen (UX W7); de assets zijn dan met het script snel aan te passen. | fasekader fase 2, UX §7 punt 1 |
| W6 | De HUD hangt op een **CanvasLayer** en doet niet mee met de saturatiepass van de wijk: in grijs en kleur gelijk. | UX §2.3 |

## 1. Wat deze PR levert en wat in deel 3 volgt

**Deel 2 (deze PR):** stijlgids, lettertype *Polderletter* (normaal en groot), alle HUD-onderdelen van UX §3 en `coop.md` §3, de merk-aftelling en de peilbuis in de wereld, plaat en kaders, de meting van het meetpunt (§6) en de NL-tekst per vak (§7).

**Deel 3 (volgt, zelfde issue):**
1. **Menu-art**: titelscherm, hoofdmenu, spelbestanden, pauze, logboek, opties (5 tabs), herbinden, in normaal en *Tekstgrootte: groot*. Mock-ups per scherm als PNG.
2. **Knop-glyphs per apparaat**: Xbox-stijl, PlayStation-stijl, Steam Deck en toetsenbord (toetskap als 9-slice). Eigen tekeningen, geen logo's.
3. **Godot Theme** (`.tres`) met Polderletter, de kaders en de keuzebalk, zodat de Gameplay Programmer de menu's niet per scherm hoeft te stijlen.
4. Wat de review van deze PR en de open punten van §10 opleveren.

## 2. Beeldtaal

1. **De HUD is gereedschap van de machinist.** Glas, gloed en ijzer van het gemaal, geen fantasy-ornamenten. Het lantaarntje, de buis van de lichtmeter en de peilbuis zijn één familie: een glazen vat met een rand van gevel wit, gevuld met *gloed*.
2. **Gloed is licht dat je draagt.** Alleen wat licht ís (levens, meter, peilbuis) vult met de ramp *gloed* (bible §3), die in elke toestand haar kleur houdt. Zo is de HUD in een grijze wijk het enige warme naast de lampen, precies zoals de kernloop het wil.
3. **Kleur zegt van wie, vorm zegt wat** (bible §6). Amber en cyaan alleen voor P1/echo en P2. De boss-balk is neutraal (gevel wit) met de **rode bovenrand** van elke vijand.
4. **Vol = levend, hol = echo**, ook in de HUD. Het echo-icoon is hol: een amber rand met de diagonale arcering om de 3 px van de echo zelf; de plaat schijnt erdoor. De P2-badge is vol bijna-zwart met een cyaan rand, zoals de sluiswachter.
5. **Elk element heeft een contour van 1 px bijna-zwart** (`#06060f`). Daardoor raakt geen gekleurde pixel ooit de achtergrond, en blijft het element leesbaar op lichtgeometrie, sterren en verlichte ramen.
6. **Geen tekst in de art** (S-17). Tekst komt alleen uit het lettertype, via `strings.csv`.
7. **Strepen van 2 px voor wat een toestand draagt** (klokring, badge-ring, leibandring), 1 px alleen voor randen en details (UX §2.2).
8. **Niet doen:** verlopen, gloed of bloom rond HUD-elementen, halftransparante pixels in de elementen zelf (alleen de plaat en het kader zijn doorschijnend), afgeronde vectorvormen, schaduwen onder vensters.

## 3. Palet

Alle kleuren komen uit de ramps van bible §3 en de figuurkleuren van §6. Er is geen nieuwe kleur.

| Rol in de UI | Kleur | Bron |
|---|---|---|
| Contour, tekstschaduw | `#06060f` | lucht 0 |
| Plaat (66 %, §6) en kader (78 %) | `#0c0c1d` | lucht 1 |
| Leeg glas (meter, lantaarn, peilbuis, boss-balk) | `#181c3b`, bovenste rij `#21264c` | lucht 3, 4 |
| Randen: licht / vlak / schaduwkant | `#ece2cc` / `#cbc2b5` / `#a8a19f` | gevel wit 7, 6, 5 |
| Leeg lantaarntje, stippels, gedimde tekst | `#817c8a` | gevel wit 4 |
| Kaderrand, uitgedoofd | `#5b576e`, `#37344a` | gevel wit 3, 2 |
| Vulling: boven / midden / onder / glans | `#ffdb94` / `#fbc058` / `#cc7e22` / `#fff6d8` | gloed 6, 5, 3, 7 |
| P1 en echo | `#b45c16`, `#f29a26`, `#ffd27a`; arcering `#3a1e56` | bible §6 |
| P2 | `#1fb4cc`, `#3ee6f4`, `#e8ffff`; lijf `#08080e` | bible §6 |
| Klokring P2, licht | `#e8ffff` | ogen P2, bible §6. Niet `#bff4fc`: dat ligt op FelLicht 5/6 (ΔE 8–9), het licht waarin de echo oplost (AD-review PR #137) |
| Klemmen, kappen, tandwiel-as | `#3a3640` … `#6a6268` | ijzer 5–7 |
| Rode bovenrand boss-balk | `#ff475c` | vijandkern/-rand (UX-wireframes; akkoord AD, komt in bible v1 §6) |
| Tekst / kop / gedimd | `#ece2cc` / `#ffdb94` / `#a8a19f` | gevel wit 7, gloed 6, gevel wit 5 |

## 4. Lettertype: *Polderletter*

**Licentie: eigen werk** van de UI Artist, pixel voor pixel getekend in `docs/art/ui/bron/polderletter.py`. Geen extern font, geen afgeleide, dus geen licentie van derden. Het font hoort bij de studio, net als het 5×7-font van de Art Director.

| | Normaal | Groot (*Tekstgrootte: groot*, TG-10) |
|---|---|---|
| Hoofdletter / x-hoogte / onderstok | 7 / 5 / 2 px | 10 / 7 / 3 px |
| Regelafstand in het ontwerp | 10 px | 14 px |
| Breedte | proportioneel, 1 px tussen letters; gemiddeld 4,5 px per teken | gemiddeld 5,4 px per teken |
| Gebruik | HUD, meldingen, menu's, logkader | menu's, logkader, meldingen bij *groot* |
| Bestanden (`game/art/ui/font/`) | `polderletter_normaal.fnt` + `.png`, `.ttf` | `polderletter_groot.fnt` + `.png`, `.ttf` |

- **Groot is apart getekend**, geen schaalfilter (TG-10). Het is ± 1,4× zo hoog en ± 1,2× zo breed per teken; daardoor passen in het grote logkader (528 px binnen) **97** tekens NL tegen **77** in het normale (348 px). UX §3.7 vraagt "evenveel tekens per regel": dat haalt het ruim.
- **Titels**: normaal ×2 (hoofdletter 14 px, UX §2.2), alleen integer.
- **Tekens (177)**: ASCII 0x20–0x7E, alle letters van Latin-1 (À–ÿ, ook Æ Ø Ð Þ ß æ ø ð þ), plus ¡ ¿ « » ° · × ± ² ³ © £ € … – — ‘ ’ “ ”. Accenten worden samengesteld uit basisletter + accent; op hoofdletters staat het accent in de 2 (groot 3) rijen boven de hoofdletter. Nog niet getekend: de zeldzame Latin-1-symbolen ¢ ¤ ¥ ¦ § ¨ ª ¬ ® ¯ µ ¶ ¸ ¹ º ¼ ½ ¾ ÷ (niet nodig voor EN/NL; op aanvraag).
- **Tekst staat altijd met 1 px schaduw** rechtsonder in `#06060f` (Godot: `font_shadow_color`, `shadow_offset_x/y = 1`).
- **Godot 4 (BMFont, de bron):** `.fnt` (tekst-BMFont, 1 page) importeert als FontFile. Labels met Polderletter staan **altijd op `font_size` 11** (groot: **16**). Een BMFont heeft een vaste grootte: bij een andere maat schaalt Godot hem en krijg je mixels. Regelhoogte in het bestand is 11 (groot 16), inclusief ruimte voor accenten op hoofdletters; voor de ontwerpregel van 10 (groot 14) in het logkader: Label-constante `line_spacing = -1` (groot `-2`).
- **Filter:** in Godot 4 is "filter Nearest" geen importoptie meer. Zet de projectinstelling `rendering/textures/canvas_textures/default_texture_filter = Nearest`, of `texture_filter = Nearest` op de HUD-CanvasLayer (erft door naar alle kinderen). Geen mipmaps.
- **Godot (TTF):** 100 eenheden per pixel; gebruik op `font_size` 11 (groot 16), met *Antialiasing: None*, *Hinting: None*, *Subpixel positioning: Disabled*. Met hinting aan verschuift FreeType de accenten één rij (gezien in een test met Pillow). De TTF is er vooral voor mock-ups in andere tools.
- Specimen: `docs/art/ui/polderletter_specimen_x3.png`.

## 5. HUD-onderdelen

Alle bestanden in `game/art/ui/hud/` (HUD, CanvasLayer) en `game/art/ui/wereld/` (aan een object in de wereld). Stroken (`_<n>f`) zijn frames van gelijke maat naast elkaar (Godot: `AnimatedSprite2D` of `AtlasTexture` met `hframes`). 1 tick = 1/60 s.

| UX-ID | Element | Bestand(en) | Maat | Toestanden en timing | In Godot |
|---|---|---|---|---|---|
| HUD-01 | **Lantaarntje** (levenspunt) | `lantaarn_vol.png`, `lantaarn_leeg.png`, strook `lantaarn_7x9_vol_leeg_flits.png`, `lantaarn_glinster_13x13_3f.png` | 7×9, 2 px tussenruimte | vol (gloed met kern), leeg (rand gevel wit 4, donker glas), **flits** = treffer: 6 ticks, dan leeg; **glinster** = nieuw lampglas: 3 frames × 4 ticks, lampje in het midden van de 13×13 | `TextureRect` per lampje |
| HUD-02 | **Lichtmeter** | `meter_onder.png` (84×13, buis + lege segmenten + genees-streep), `meter_vulling.png` (84×9), `meter_vol_flits.png` | 84×9 + 3 | 10 segmenten van 7 px = 10 LP; vulling gloed 6/5/3 met een glanspixel. **Vol**: `meter_vol_flits` één keer 6 ticks. | `TextureProgressBar`: under = `meter_onder`, progress = `meter_vulling`, fill left-to-right, max 100. De scheidingen zitten in *under*; vulling binnen een segment loopt per pixel (1 px ≈ 1,4 LP). |
| HUD-03 | **Genees-streep** | in `meter_onder.png` (x 25, y 9–11) | 1×3 | vast | — |
| LM-07 | Genezen / te weinig licht | `meter_genees_kader.png`, `meter_te_weinig_kader.png` | 26×9 | genezen: kader gloed 7 rond de bovenste 30 LP (x = top − 25), loopt in 45 ticks leeg; te weinig: kader gevel wit 3 over de eerste 3 segmenten, 20 ticks | `TextureRect` boven de meter |
| LM-02 | **Vonk** | `vonk_amber_7x7_3f.png`, `vonk_cyaan_7x7_3f.png` | 7×7 | 3 frames × 3 ticks; midden op het segment dat vult. Ketting: één vonk per schakel. | `AnimatedSprite2D` |
| HUD-04 | **Echo-icoon** | `echo_actief.png`, `echo_leeg_vullen_11x17_16f.png`, `echo_breken_11x17_3f.png`, `echo_uit.png`, `echo_pijl_buiten.png` (5×9) | 11×17 | *Actief* (ook dragend, zwevend, merksprong): hol amber silhouet met arcering. *Leeg*: gestippeld; frame = `floor(voortgang × 15)` vult van onder. *Breken*: 3 frames × 4 ticks (12), dan *Leeg*. *Buiten*: *Leeg* + pijl rechts ernaast (x + 11, y + 4). *Uit*: grijs. | `TextureRect`, frame kiezen in code |
| co-op | **P2-badge** | `p2_badge_speelt.png`; stroken `p2_badge_{opgelost,stoppen,weg}_17x17_16f.png`; los: `p2_badge_kop(_weg).png`, `p2_badge_ring_{cyaan,grijs,wit,weg}.png` | 17×17 | ring van 2 px om de kop van de sluiswachter (brede hoed, vol zwart, cyaan rand). *Opgelost*: ring grijs, vult cyaan in 120 ticks. *Stoppen*: vult wit in 60 ticks. *Apparaat weg*: kop grijs, ring loopt leeg in 180 ticks + `pad_weg.png` links ernaast. Alle ringen met de klok mee vanaf boven. | Strook (frame = `floor(voortgang × 15)`) of `TextureProgressBar` radial clockwise met kop als *over* |
| CO-08 | Controller weg | `pad_weg.png` | 15×9 | generieke controller met "!" in gloed 6, geen merkvorm | — |
| C-07 | **P2 buiten beeld** | `p2_pijl_rand.png` (8×13, wijst rechts; spiegelen of draaien per rand in 90°-stappen), `p2_leiband_15x15_16f.png`, `p2_leiband_ring_{cyaan,onder}.png` | 8×13, 15×15 | ring loopt in 60 ticks leeg | idem badge |
| HUD-05 | **Merk: kern** | `merk_kern_peil_amber.png`, `merk_kern_sluis_cyaan.png`, + `_dooft` | 9×9 (kern 7 + contour) | P1 **peilmerk**: rond, met waterlijn. P2 **sluismerk**: ruit met verticale streep. *Dooft* (D + 30): halve helderheid, daarna weg. | in de wereld, op het object |
| HUD-05 | **Klokring** | `klokring_{amber,cyaan}_19x19_5f.png`, `klokring_{amber,cyaan}_groot_27x27_5f.png` | ring 17 (groot 25) + contour = 19 (27) | frame 0–4 = 4, 3, 2, 1, 0 kwarten branden. Kwart rechtsboven dooft eerst (met de klok mee vanaf boven), op de tick van de carillonslag. Kern in het midden: offset (5, 5), groot (9, 9). | `AnimatedSprite2D` of frame in code |
| HUD-05 | **Ontploffing** | `merk_boem_{amber,cyaan}_31x31_3f.png`, `_groot_39x39_3f.png` | 31×31 (39) | slag 3: 3 frames × 4 ticks; vervangt kern en ring | idem |
| HUD-06 | **Peilbuis** | `peilbuis_onder.png` (13×42), `peilbuis_vulling.png`, `peilbuis_flits.png`, `peilbuis_trapstreep.png` (13×3), `peilbuis_klem.png` (13×20) | buis 9×42, strepen 13 breed | vult van onder met gloed; streep per trap op `y = 39 − round(36 × k / trappen)` (streep op y − 1); volle trap: `peilbuis_flits` 6 ticks; klem op (0, 2) over de bovenste helft (trap 2 van een bosswijk). | `TextureProgressBar` fill bottom-to-top |
| HUD-09 | **Boss-balk** | `boss_balk_onder.png` (242×6), `boss_balk_vulling.png`, `boss_fasestreep.png`, `boss_fasestreep_wankel.png` (3×10) | 240×4 binnen | vulling gevel wit 7/6/4; rode bovenrand; fasestrepen op 60 % en 20 % (wit 6). *Wankel*: de streep van 20 % wisselt elke 8 ticks naar de wankelversie (gloed 6). Naam erboven in Polderletter (wit 7), 9 px boven de balk. | `TextureProgressBar` + 2 `TextureRect` |
| §2.3 | **Plaat** | `plaat_9slice.png` | 5×5, marge 2 | `#0c0c1d` op **66 %** (§6), hoeken 1 px afgesneden | `NinePatchRect`, patch margins 2 |
| HUD-07, HUD-08 | **Kader** (logkader, melding) | `kader_9slice.png`, `kader_9slice_cyaan.png` (P2-meldingen) | 7×7, marge 2 | plaat 78 %, rand gevel wit 3 (cyaan: `#1fb4cc`), klinknagels op de hoeken | `NinePatchRect`, patch margins 2 |
| 4.6 | **Opslaan** | `opslaan_tandwiel_13x13_4f.png` | 13×13 | 4 frames × 6 ticks, naadloze lus (8 tanden, 11,25° per frame) | `AnimatedSprite2D` |

**Plaatsing (interne pixels, gemeten vanaf de schermrand, HUD-M1):**

| Wat | Positie |
|---|---|
| Plaat P1 | (4, 4), breedte `max(n_levens × 9 − 2, 84) + 27`, hoogte 31 |
| Lantaarntjes | (8 + i × 9, 8) |
| Lichtmeter | (8, 20); genees-streep valt op y 29–31 |
| Echo-icoon | (8 + max(n × 9 − 2, 84) + 4, 8), pijl *Buiten* op (+11, +4) |
| P2-badge | (W − 25, 8), plaat (W − 29, 4) 25×25; `pad_weg` op (W − 46, 12) |
| Logkader | midden, onderkant op H − 8; 360×32 (groot 540×48); kop op (+6, +3), regels op +12 en +21 (groot +4, +18, +32) |
| Melding | rechts, onderkant op H − 8; breedte = tekst + 12, hoogte 7 + 10 per regel; tekst op (+6, +4) |
| Boss-balk | midden, onderkant op H − 8 |

Op de Deck (640×400) gelden dezelfde getallen met H = 400: de HUD staat dan in de 16:10-band (preview `hud_deck_640x400_x2.png`).

## 6. Meetpunt en contrast

**Meetpunt uit UX §2.3** (helderste pixel achter de HUD). Gemeten met het script op de R5-scène, op de echte plaatzone (111×31 vanaf (4, 4)); L\* in CIELAB:

| Achtergrond | Zonder plaat: mediaan / p95 / max | Met plaat 66 %: p95 / max | ΔL\* meterrand (L\* 78,8) − helderste pixel |
|---|---:|---:|---:|
| R5 grijs, 640×360 | 2,4 / 6,9 / 23,4 | 4,8 / 10,2 | 68,6 |
| R5 kleur, 640×360 | 3,9 / 27,2 / 89,0 | 11,1 / 35,9 | **43,0** |
| R5 kleur, Deck 640×400 | 1,8 / 16,5 / 38,9 | 7,3 / 15,6 | 63,3 |
| Co-op, zone van de P2-badge (kleur) | 1,8 / 3,9 / 3,9 | 3,9 / 3,9 | 74,9 |

| Plaat | Helderste pixel | ΔL\* meterrand |
|---|---:|---:|
| 62 % (UX-spec) | 39,4 | 39,4 (net onder 40) |
| 64 % | 37,6 | 41,2 |
| **66 % (gekozen)** | 35,9 | **43,0** |
| 70 % | 32,3 | 46,5 |

**Keuze:** de plaat gaat naar **66 %**. Dat haalt ΔL\* ≥ 40 met 3 punten marge, en de plaat blijft doorschijnend genoeg om de stad te zien. Daarbovenop heeft elk element een contour van bijna-zwart (L\* 1,8): de rand van de meter staat nooit direct tegen de achtergrond (ΔL\* rand/contour 77,0). Dit wijzigt het getal 62 % in UX §2.3: open punt 1 in §10.

**Contrastparen** (ΔE76 normaal / deuteranopie / ΔL\*; regel bible §7.1: ΔE ≥ 30 en ≥ 25 bij deuteranopie, anders ΔL\* ≥ 20 of vorm):

| Paar | ΔE | ΔE deut. | ΔL\* | Regel |
|---|---:|---:|---:|---|
| Meterrand (wit 6) / contour | 77,8 | 78,2 | 77,0 | ja |
| Vulling (gloed 5) / leeg segment | 105,9 | 108,3 | 69,7 | ja |
| Lantaarn vol / leeg (glas) | 98,2 | 100,2 | 77,4 | ja |
| Lantaarn leeg: rand (wit 4) / plaat | 49,1 | 49,3 | 49,0 | ja (ΔL\* ≥ 40, UX §2.2) |
| Echo-icoon amber / plaat | 105,5 | 105,5 | 67,1 | ja |
| Echo leeg: stippel / plaat | 49,1 | 49,3 | 49,0 | ja |
| P2-badge cyaan / plaat | 90,4 | 78,6 | 80,2 | ja |
| Merk amber / merk cyaan | 107,7 | 91,9 | 13,1 | ja; vorm verschilt ook (rond/ruit, liggende/staande streep) |
| Klokring amber (gloed 6) / rode vijandkern | 73,6 | 26,5 | 30,4 | ja |
| Merkkern amber / rode vijandkern | 60,0 | 32,4 | 12,4 | ja; plus contour |
| Merkkern cyaan / schaduwgeometrie 3 | 94,9 | 67,2 | 69,7 | ja |
| Klokring brandend / gedoofd, amber | 84,5 | 85,9 | 66,1 | ja |
| Klokring brandend / gedoofd, cyaan | 77,6 | 75,8 | 75,5 | ja |
| Klokring cyaan licht (`#e8ffff`) / cyaan kern | 36,7 | 25,9 | 14,3 | ja (zelfde eigenaar; ring en kern blijven toch uit elkaar te houden) |
| Boss-balk vol / leeg | 73,4 | 74,1 | 67,3 | ja |
| Fasestreep Wankel / normaal | 33,5 | 34,0 | 10,1 | ja |
| Tekst (wit 7) / kader | 89,2 | 89,7 | 86,2 | ja |
| Kop logkader (gloed 6) / kader | 98,7 | 100,1 | 85,1 | ja |

Previews met alleen luminantie en met gesimuleerde deuteranopie: `merk_klokring_x4.png` (rij 2 en 3).

## 7. NL-tekst per vak (UX §6, §7 punt 10)

Gemeten in Polderletter normaal met **testteksten** (EN en NL, in het script, `VAKKEN`). De echte teksten schrijven de Narrative Designer en de Gameplay Programmer in `strings.csv`; het script meet ze opnieuw zodra ze er zijn. Vakbreedte = binnenruimte uit de UX-spec en de wireframes; bij *groot* is het vak 1,5×.

| Vak (binnen) | Langste NL in de test | NL px | Past normaal | Groot (NL px / vak) |
|---|---|---:|---|---|
| Logkader, regel (348) | "De sluiswachter sloot de sluis en liep zonder lamp naar huis." (58 tekens) | 270 | ja | 321 / 528, ja |
| Melding (voorstel 184) | `HUD_PAD_JOIN_HINT` "Controller 2: druk op Start om mee te doen" | **195** | **nee** | 234 / 276, ja |
| Melding | `HUD_P2_STOP_HOLD` "Houd View vast om te stoppen" (+73 % t.o.v. EN) | 133 | ja | ja |
| Boss-naam (240) | "De Gemaalmeester" | 79 | ja | ja |
| Menuregel (138) | "Naar hoofdmenu" (+64 %) | 69 | ja | ja |
| Tabbalk (560) | 5 tabs met "Toegankelijkheid" | 262 | ja | 335 / 840, ja |
| Optienaam (348) | "Geluid op de achtergrond" | 111 | ja | ja |
| Optiewaarde met < > (188) | "< Volledig scherm >" | 84 | ja | ja |
| Pauze, rechterkolom (382) | "Lampglas 0/1   Logbladzijden 3/7" | 146 | ja | ja |
| Herbinden, kolom Actie (152) | "Meedoen (vrij apparaat)" | 104 | ja | 124 / 228, ja |
| Losse regels (300) | "Druk op een toets (Esc annuleert)" | 152 | ja | ja |

**Tekens per regel in het logkader** (lopende tekst): normaal 348 px = **± 77 tekens** NL (4,5 px per teken); groot 528 px = **± 97 tekens**. De EN-regel van **258 px** (348 / 1,35, UX §3.7) is in Polderletter **± 56 tekens EN**, ruimer dan de 43 van het wireframe-font. De Narrative Designer kan dus EN-regels tot 56 tekens schrijven.

**Bevindingen:**
1. Alles past, behalve **`HUD_PAD_JOIN_HINT`** in NL op één regel van een melding (195 px). Voorstel: twee regels, *Controller 2* / *Druk op Start om mee te doen* (zoals CO-04 al twee regels gebruikt). Open punt 2.
2. Een melding van max. 196 px rechtsonder **overlapt het logkader** (x 140–500) zodra ze breder is dan 128 px en beide tegelijk staan. Voorstel: staat het logkader er, dan schuift de melding 36 px omhoog (boven het kader). Open punt 3.
3. NL is in de test gemiddeld maar 3 % langer per teken dan EN; het verschil zit in losse woorden (*Afsluiten* +138 %, *Stoppen (vasthouden)* +100 %). De regel EN + 35 % blijft dus nodig voor korte vakken (menuregels, knoppen), niet voor lopende tekst.

## 8. Previews (in `docs/art/ui/`)

| Bestand | Wat |
|---|---|
| `hud_solo_grijs_kleur_x2.png` | HUD solo + logkader op de R5-scène, grijs boven, kleur onder |
| `hud_solo_kleur_1920x1080_x3.png` | HUD solo met 6 levens, kleur, op 1080p (×3) |
| `hud_coop_kleur_grijs_x2.png` | Co-op: P2-badge, twee merken met klokring in de wereld, melding *P2 doet mee* (cyaan kader); grijs: P2 opgelost, pijl en leibandring aan de rand, *Controller 2 kwijt* |
| `hud_deck_640x400_x2.png` | Steam Deck 640×400 (×2 = 1280×800): echo *Leeg* op 60 %, melding lampglas |
| `hud_boss_en_logkader_groot_x2.png` | Boss-balk bij Wankel (boven); logkader bij *Tekstgrootte: groot* (onder) |
| `hud_elementen_x4.png` | Alle HUD-onderdelen en hun toestanden |
| `merk_klokring_x4.png` | Merk P1 en P2 op alle momenten (gezet, slag 1–4, ontploffing, dooft), groot, ontploffing; normaal / alleen luminantie / deuteranopie |
| `polderletter_specimen_x3.png` | Het lettertype, normaal en groot |

## 9. Regels voor wie UI bouwt (Gameplay Programmer)

- **Filter Nearest** via de projectinstelling `rendering/textures/canvas_textures/default_texture_filter` of `texture_filter` op de HUD-CanvasLayer (in Godot 4 geen importoptie meer); geen mipmaps; geen schaal of rotatie op HUD-nodes (bible §2). De pijl van P2 draait alleen in stappen van 90°.
- Zet de HUD op een **CanvasLayer** op de interne resolutie (640×360 / 640×400), niet op 1280×720: een asset van 7×9 moet 7×9 interne pixels blijven.
- Plaatsing ten opzichte van de schermrand, nooit ten opzichte van het 16:9-beeld (HUD-M1).
- Tekst: Polderletter (`.fnt`) op `font_size` 11 (groot 16), nooit een andere maat; `font_color` gevel wit 7, schaduw `#06060f` op (1, 1). Kop van het logkader in gloed 6, tweede regel van een melding in gevel wit 5, P2-meldingen in cyaan met `kader_9slice_cyaan`.
- **Tekstgrootte groot**: wissel naar `polderletter_groot.fnt` en het grote logkader; de HUD (meter, levens, badge) blijft gelijk (TG-10).
- **TG-05 Merk-ring groter**: gebruik de `_groot`-stroken. **TG-03 Flitsen verminderen**: sla `meter_vol_flits`, `peilbuis_flits` en `lantaarn` *flits* over; de rand van 2 px komt van de Technical Artist.

## 10. Open punten

| # | Wat | Wie | Wanneer |
|---|---|---|---|
| 1 | **Wijziging UX §2.3**: plaat 62 % → **66 %** (meetpunt haalt dan ΔL\* 43,0). Graag overnemen in de UX-spec. | UX Designer | Volgende versie van `hud-menus.md` |
| 2 | **Wijziging UX/tekst**: `HUD_PAD_JOIN_HINT` in NL op twee regels (*Controller 2* / *Druk op Start om mee te doen*), of korter. | UX Designer, Narrative Designer | Bij `strings.csv` (T8a) |
| 3 | **Wijziging UX §2.1 / §3.7**: een melding schuift 36 px omhoog zolang het logkader staat (anders overlapt ze bij > 128 px breed). Voorstel max. breedte melding: 196 px. | UX Designer | Volgende versie van `hud-menus.md` |
| 4 | `#ff475c` vastleggen als vijandkern/-rand in bible §6 (ook de rode bovenrand van de boss-balk). | Art Director | Bible v1 |
| 5 | Vervallen: de map is `game/art/ui/` (AD-review PR #137). | — | — |
| 6 | **Viewport en filter**: `project.godot` heeft op pc 1280×720 zonder stretch-modus, en zet nog geen standaardfilter Nearest (`rendering/textures/canvas_textures/default_texture_filter`). De UI gaat uit van 640×360 met integer schalen (bible §2). | Technical Director | Bij de bouw van de HUD (T8a) |
| 7 | **Licentieregister**: Polderletter is eigen werk; geen licentie van derden. Wil de Business/Legal Advisor het toch als regel "eigen werk" in `docs/licenties.md` (rolbestand UI Artist: "lettertypes hebben een licentie in licenties.md")? | Business/Legal Advisor | Geen haast |
| 8 | Nog te testen op een echte Steam Deck: leesbaarheid van Polderletter normaal (7 px = ± 1,7 mm), de arcering van het echo-icoon (11×17) en de ring van 2 px. | Engine & Platform Programmer, met de UI Artist | Bij de Deck-build (#79) |
| 9 | Kleurprofielen TG-07 (amber/wit-blauw, geel/magenta): de assets zijn per eigenaar in aparte bestanden, zodat een profiel alleen kleuren wisselt. Varianten tekenen zodra de AD de paren kiest. | Art Director, daarna UI Artist | Bible v1 |
| 10 | **Deel 3**: menu-art, knop-glyphs per apparaat, Godot Theme (§1). | UI Artist | Na de review van deze PR |

## 11. Wijzigingen

| Versie | Datum | Wat |
|---|---|---|
| 0.1.1 | 2026-11-10 | Na de Lead-review van de AD (PR #137): klokring P2 `#e8ffff` in plaats van `#bff4fc`; map `game/art/ui/`; Godot 4-filter en `font_size` 11/16; open punten 4–6 bijgewerkt. |
| 0.1 | 2026-11-10 | Eerste versie (T10 deel 2, #87): beeldtaal, palet, Polderletter normaal en groot, alle HUD-onderdelen, merk en peilbuis, meetpunt (plaat 66 %), NL-tekst per vak. |
