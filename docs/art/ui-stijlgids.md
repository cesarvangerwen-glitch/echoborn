# UI-stijlgids *Polderlight*

Versie 0.3 · Eigenaar: UI Artist · Issue [#87](https://github.com/cesarvangerwen-glitch/echoborn/issues/87) (T10 deel 2: eind-UI-art; deel 3: menu's, glyphs, Theme) · Review: Art Director
Basis: UX-spec `docs/ux/hud-menus.md` v0.3 (menu's: §4 en de wireframes in `docs/ux/wireframes/`) en `docs/ux/coop.md`, art bible v0 (`docs/art/bible.md` §2, §3, §6, §7), assetlijst S-17.

Alles in deze gids is **eigen werk** en wordt gemaakt door twee scripts, zonder externe assets:

```
python3 docs/art/ui/bron/genereer_ui.py      # vanaf de repo-root, ± 3 s: font, HUD, wereld (deel 2)
python3 docs/art/ui/bron/genereer_menu.py    # daarna, ± 3 s: menu's, glyphs, Theme (deel 3)
python3 docs/art/ui/bron/genereer_menu_placeholder.py   # daarna, ± 2 s: placeholder-mock-ups (§12.6), alleen naar docs/art/ui/
```

De scripts schrijven de assets naar `game/art/ui/`, de previews naar `docs/art/ui/` en printen de metingen van §6, §7 en §12.5.

## 0. Werkaannames (kader §5)

| # | Aanname | Bron |
|---|---|---|
| W1 | Interne resolutie **640×360** (pc) en **640×400** (Deck), alleen integer schalen, nearest neighbour. Alle assets zijn 1:1 op die resolutie getekend. | besluit #18, bible §2 |
| W2 | Staart **D = 120 ticks** (bereik 90–180). De animaties hier hangen niet af van D: de klokring telt slagen, het echo-icoon telt voortgang 0–1. | besluit #51 (8A), UX W1 |
| W3 | Max. **twee lichamen**; solo P1 + echo, co-op P1 + P2. Amber = P1 en zijn echo, cyaan = P2. | besluit #51 (7A), bible §6 |
| W4 | Talen **EN en NL**, tekstvakken voor EN + 35 %. | besluit #51 deel 1 (5A), UX §6 |
| W5 | **F1 is gehaald**; F0 nog niet. Na F0 kan de UX Designer maten bijstellen (UX W7); de assets zijn dan met het script snel aan te passen. | fasekader fase 2, UX §7 punt 1 |
| W6 | De HUD hangt op een **CanvasLayer** en doet niet mee met de saturatiepass van de wijk: in grijs en kleur gelijk. | UX §2.3 |
| W7 | De mock-ups van §12.6 zijn **placeholders** (`_placeholder` in de naam): de indeling en maten van UX §4.5, §4.7a, §4.8 en §4.9 kloppen, de eind-art van die schermen volgt later. Het slot-kader is geen nieuw bestand maar een combinatie van bestaande 9-slices. | UX §7 punt 16 |
| W8 | **3 spelbestanden**, schema v1 (zonder lampglas); *Lampglas n/4* staat in de meting, nog niet in de mock-up. | UX W9 |

## 1. Wat deze gids dekt

**Deel 2:** stijlgids, lettertype *Polderletter* (normaal en groot), alle HUD-onderdelen van UX §3 en `coop.md` §3, de merk-aftelling en de peilbuis in de wereld, plaat en kaders, de meting van het meetpunt (§6) en de NL-tekst per vak (§7).

**Deel 3:**
1. **Menu-art** (§12): keuzebalk met de lamp als focus, tabs, schuif, keuzewaarde, herbind-cellen, scrollbalk, paneel en zijband. Mock-ups van hoofdmenu, pauze (co-op, ook Steam Deck), opties *Toegankelijkheid*, opties *Besturing* met herbinden, en opties bij *Tekstgrootte: groot*. Titels in Polderletter ×2, de spelnaam ×3.
2. **Knop-glyphs per apparaat** (§13): toetsenbord en muis, Xbox-stijl, PlayStation-stijl en Steam Deck, normaal (11 px) en groot (15 px). Eigen tekeningen, generieke vormen, geen logo's of merkkleuren.
3. **Godot Theme** (§14): `polderlight_menu.tres` en `polderlight_menu_groot.tres` met Polderletter, de menu-art en type-varianten, zodat de Gameplay Programmer de menu's niet per scherm hoeft te stijlen.

**Deel 3, vervolg (placeholder):** mock-ups van *Spelbestanden* met de bevestiging, het Logboek, de Credits en herbinden met de kolomkeuze, normaal en groot (§12.6). Ze gebruiken alleen bestaande onderdelen; de eind-art van deze schermen volgt later (werkaanname W7).

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
- **Titels en spelnaam** (deel 3): `polderletter_titel.fnt` (normaal ×2, `font_size` 22) en `polderletter_naam.fnt` (×3, `font_size` 33), nearest geschaald uit normaal. Een BMFont schaalt in Godot niet mee met `font_size`, dus elke maat is een eigen bestand. Schaduw ×2 en ×3 (2 en 3 px). Bij *Tekstgrootte: groot* blijven titels gelijk.
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

**Keuze:** de plaat gaat naar **66 %**. Dat haalt ΔL\* ≥ 40 met 3 punten marge, en de plaat blijft doorschijnend genoeg om de stad te zien. Daarbovenop heeft elk element een contour van bijna-zwart (L\* 1,8): de rand van de meter staat nooit direct tegen de achtergrond (ΔL\* rand/contour 77,0). Overgenomen in UX §2.3 (v0.2): de plaat is 66 % (open punt 1 gesloten).

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
1. Alles past, behalve **`HUD_PAD_JOIN_HINT`** in NL op één regel van een melding (195 px). **Overgenomen** in UX §6 (v0.2): twee regels, kop *Controller 2* in cyaan (`HUD_PAD_NAME`) en *Druk op Start om mee te doen* (`HUD_PAD_JOIN_HINT`); `HUD_PAD_LOST` gebruikt dezelfde kop. Open punt 2 gesloten.
2. Een melding van max. 196 px rechtsonder **overlapt het logkader** (x 140–500) zodra ze breder is dan 128 px en beide tegelijk staan. **Overgenomen** in UX HUD-M5/HUD-M6 (v0.2): een melding is max. **196 px** breed (binnen 184, groot 294) en schuift in 6 ticks omhoog tot 4 px boven het element onder in het midden: **36 px** boven het logkader, **52 px** boven het logkader op *groot*, **28 px** boven de boss-balk met naam. Open punt 3 gesloten.
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
| `menu_hoofdmenu_x2.png` | Hoofdmenu op de grijze stad, Xbox-stijl-glyphs (UX §4.2) |
| `menu_pauze_coop_x2.png` | Pauze in co-op, PlayStation-stijl-glyphs (UX §4.3) |
| `menu_pauze_deck_640x400_x2.png` | Pauze op de Steam Deck (640×400, ×2 = 1280×800), Deck-glyphs |
| `menu_opties_toegankelijkheid_x2.png` | Opties, tab *Toegankelijkheid*, met schuif en uitleg; toetsenbord-glyphs (UX §4.4, §5) |
| `menu_opties_besturing_herbinden_x2.png` | Opties, tab *Besturing*: herbinden, cel *Druk een knop…* en de dialoog *Bezet door Dash* (UX §4.5) |
| `menu_opties_groot_x2.png` | Opties bij *Tekstgrootte: groot*: regel 20 px, lijst scrolt (TG-10) |
| `menu_elementen_x4.png` | Alle menu-onderdelen en hun staten |
| `knop_glyphs_x4.png` | Alle knop-glyphs, per apparaat, normaal en groot (intern werkblad: de vier PS-vormen staan er naast elkaar, dus niet publiek gebruiken, `knop-glyphs-check.md` §2.1) |
| `menu_spelbestanden_x2_placeholder.png` | *Spelbestanden* normaal: plaats 1 `HERSTELD` met focus, plaats 2 `KAPOT`, plaats 3 *Leeg*, melding MN-24; eronder de bevestiging MN-23 (*Terug* gekozen), Xbox-stijl (UX §4.7a) |
| `menu_spelbestanden_groot_x2_placeholder.png` | Idem bij *Tekstgrootte: groot* (584 × 50), focus op de `KAPOT`-plaats (geen hint A); bevestiging 480 × 168 voor die plaats: *Plaats 2 overschrijven?*, details *Beschadigd: kan niet laden* in `Gedimd` (geen wijk of speeltijd), tekst `MENU_CONFIRM_SET_ASIDE_BODY`; Deck-glyphs |
| `menu_slot_kader_x2_placeholder.png` | Het slot-kader in de staten normaal, focus, hover en ingedrukt; normaal (400 × 36) en groot (584 × 50) |
| `menu_logboek_x2_placeholder.png` | Logboek normaal (logkader rechts, Xbox-stijl) en groot (kader onder de lijst, Deck) (UX §4.8) |
| `menu_credits_x2_placeholder.png` | Credits normaal (Xbox-stijl) en groot (toetsenbord), met de merkenregel; namen zijn plaatshouders (UX §4.9) |
| `menu_herbinden_kolom_x2_placeholder.png` | Besturing: cel-focus in *Controller* (de pad stuurt, MN-41) en in *Toetsenbord 1*; *Links* en *Rechts* als twee regels, *Ook: linker stick*, *Herstel alles*; hint *Kolom* met `dpad_horizontaal` (UX §4.5) |

## 9. Regels voor wie UI bouwt (Gameplay Programmer)

- **Filter Nearest** via de projectinstelling `rendering/textures/canvas_textures/default_texture_filter` of `texture_filter` op de HUD-CanvasLayer (in Godot 4 geen importoptie meer); geen mipmaps; geen schaal of rotatie op HUD-nodes (bible §2). De pijl van P2 draait alleen in stappen van 90°.
- Zet de HUD op een **CanvasLayer** op de interne resolutie (640×360 / 640×400), niet op 1280×720: een asset van 7×9 moet 7×9 interne pixels blijven.
- Plaatsing ten opzichte van de schermrand, nooit ten opzichte van het 16:9-beeld (HUD-M1).
- **Meldingen** (HUD-08): max. 196 px breed en twee regels; schuiven in 6 ticks omhoog tot 4 px boven logkader of boss-balk (36 / 52 groot / 28 px, UX HUD-M6).
- Tekst: Polderletter (`.fnt`) op `font_size` 11 (groot 16), nooit een andere maat; `font_color` gevel wit 7, schaduw `#06060f` op (1, 1). Kop van het logkader in gloed 6, tweede regel van een melding in gevel wit 5, P2-meldingen in cyaan met `kader_9slice_cyaan`.
- **Tekstgrootte groot**: wissel naar `polderletter_groot.fnt` en het grote logkader; de HUD (meter, levens, badge) blijft gelijk (TG-10).
- **Menu's** (deel 3): zet `polderlight_menu.tres` als `theme` op de wortel-Control van elk menuscherm; bij *Tekstgrootte: groot* wissel je naar `polderlight_menu_groot.tres` (§14). Menuregels zijn `Button`s met `alignment = Left`; de lamp en de keuzebalk komen uit het Theme. Laat de muis de focus nemen (`mouse_entered` → `grab_focus()`), dan is er altijd maar één lamp.
- Knop-glyphs: kies de set van het **laatst gebruikte apparaat van die speler** (UX §4.5) of de keuze *Knopiconen* in Opties; normaal naast Polderletter normaal, `_groot` naast groot (§13).
- **TG-05 Merk-ring groter**: gebruik de `_groot`-stroken. **TG-03 Flitsen verminderen**: sla `meter_vol_flits`, `peilbuis_flits` en `lantaarn` *flits* over; de rand van 2 px komt van de Technical Artist.

## 10. Open punten

| # | Wat | Wie | Wanneer |
|---|---|---|---|
| 1 | **Gesloten:** plaat 66 % staat in UX §2.3 (v0.2); §6 bijgewerkt. | — | — |
| 2 | **Gesloten:** `HUD_PAD_JOIN_HINT` op twee regels met kop `HUD_PAD_NAME` staat in UX §6 (v0.2); §7 bevinding 1. De sleutels zet de Gameplay Programmer in `strings.csv` bij de bouw (UX §7 punt 2). | — | — |
| 3 | **Gesloten:** melding max. 196 px en omhoog boven logkader (36 px, groot 52 px) én boss-balk (28 px) staat in UX HUD-M5/HUD-M6 (v0.2); §7 bevinding 2 en §9. | — | — |
| 4 | `#ff475c` vastleggen als vijandkern/-rand in bible §6 (ook de rode bovenrand van de boss-balk). | Art Director | Bible v1 |
| 5 | Vervallen: de map is `game/art/ui/` (AD-review PR #137). | — | — |
| 6 | **Viewport en filter**: `project.godot` heeft op pc 1280×720 zonder stretch-modus, en zet nog geen standaardfilter Nearest (`rendering/textures/canvas_textures/default_texture_filter`). De UI gaat uit van 640×360 met integer schalen (bible §2). | Technical Director | Bij de bouw van de HUD (T8a) |
| 7 | **Licentieregister**: Polderletter is eigen werk; geen licentie van derden. Wil de Business/Legal Advisor het toch als regel "eigen werk" in `docs/licenties.md` (rolbestand UI Artist: "lettertypes hebben een licentie in licenties.md")? | Business/Legal Advisor | Geen haast |
| 8 | Nog te testen op een echte Steam Deck: leesbaarheid van Polderletter normaal (7 px = ± 1,7 mm), de arcering van het echo-icoon (11×17) en de ring van 2 px. | Engine & Platform Programmer, met de UI Artist | Bij de Deck-build (#79) |
| 9 | Kleurprofielen TG-07 (amber/wit-blauw, geel/magenta): de assets zijn per eigenaar in aparte bestanden, zodat een profiel alleen kleuren wisselt. Varianten tekenen zodra de AD de paren kiest. | Art Director, daarna UI Artist | Bible v1 |
| 10 | **Deel 3** geleverd: menu-art, knop-glyphs per apparaat en het Godot Theme (§12–§14), plus placeholder-mock-ups van de overige menu's (§12.6). Nog open van deel 3: 16, 17 en 19–22. | UI Artist (review AD) | — |
| 11 | **Gesloten:** *Spelbestanden* (UX §4.7a) als placeholder-mock-up, normaal en groot, met de bevestiging MN-23 (§12.6). Enige nieuwe vorm is het slot-kader, gemaakt uit `kader_9slice` en `keuzebalk_9slice` (§12.2). | — | — |
| 12 | **Gesloten:** Logboek (UX §4.8) en Credits (UX §4.9) als placeholder-mock-up, normaal en groot (§12.6). | — | — |
| 13 | **Gesloten:** UX §4.5 MN-40–MN-44 bevestigt de kolomkeuze (links/rechts in de regel, geen wrap, startkolom = apparaat dat stuurt). `cel_focus` in de mock-up klopt daarmee; *Links* en *Rechts* staan als twee regels, de hint *Kolom* gebruikt `dpad_horizontaal` (§12.6). Zie ook punt 20. | — | — |
| 14 | **Besloten door de AD (Lead-review PR #142):** glyphs monochroom, zonder merkkleur (kleur blijft voor licht en spelers). Knoptekst zonder schaduw mag, met als menunorm **ΔL\* ≥ 34** (worst case), zolang een menuregel altijd op de zijband, op de verduistering (≥ 72 %) of op de keuzebalk staat. Voor de HUD blijft ΔL\* ≥ 40. | Art Director | Besloten |
| 15 | **Gesloten** met de check van de Business/Legal Advisor (`docs/business/knop-glyphs-check.md` v1.1): de getekende glyphs mogen blijven (🟢). Regels in §13 aangevuld: monochroom, de vier PS-vormen nooit samen als rij of embleem en nooit in merkkleur, geen Xbox-, PS- of Steam-knop en geen controller-silhouet (🔴). Het overzichtsblad blijft intern. Merkenregel staat in de credits-mock-up; de definitieve tekst is van de Narrative Designer met de BLA (check §4 punt 4). | — | — |
| 16 | **Theme nog niet in Godot geopend** (geen editor in de werkomgeving van de UI Artist). Graag laden bij de bouw van de menu's en fouten melden in #87; het hangt ook af van punt 6 (filter Nearest). | Gameplay Programmer | Met T8a |
| 17 | **Spelnaam als tekst**, geen logo (bible: geen naam of logo in de art), tot na de merkcheck van *Polderlight* (besluit #96). Een logo is een eigen opdracht. | Art Director | Na de merkcheck |
| 18 | **Gesloten:** overgenomen in UX §4.2 nr. 2 (twee regels; wijknaam ≤ 165 px in Polderletter normaal, in EN én NL). Het meten bij het schrijven van de namen is UX §7 punt 17 (Narrative Designer, World & Level Designer). | — | — |
| 19 | **Theme-variant `Slot`** voor het slot-kader (Button: *normal* `kader_9slice`, *focus* keuzebalk, *pressed* ingedrukt, *hover* hover; icoon = lamp; twee Labels erin) toevoegen aan `genereer_menu.py` en de twee `.tres`, **samen met `cel_focus` met vulling** (punt 20). Nu niet gedaan: de mock-ups zijn placeholders (W7). | UI Artist (review AD) | Bij de eind-art, vóór de bouw van het slot-menu (UX §7 punt 13, T8a) |
| 20 | **Besloten door de AD** (Lead-review PR #150), `cel_focus`: de placeholder blijft; bij de eind-art krijgt de cel een **vulling in gloed 1 op 70 %** (zoals de keuzebalk) binnen de open rand in gloed 6. Reden: staanders van 1 px tegen een rand die één stap verschilt (gloed 6 tegen 5) lezen te zwak op de Deck, en de gekozen cel wordt zo het lichtste punt van de regel (licht = keuze). Voorwaarden: glyph en toetstekst in de cel halen ΔL\* ≥ 34 (menunorm, punt 14); de cel blijft duidelijk anders dan *ingedrukt* (gloed 1 op 92 %); in de kolom *Controller* sluit de cel gelijk met de rechterrand van de keuzebalk (geen twee staanders naast elkaar). | Art Director | Besloten |
| 21 | **Ter info voor de UX Designer:** `MENU_CONFIRM_SET_ASIDE_BODY` (NL) past bij *groot* op **één** regel (426 van 448 px binnen het paneel van 480), niet op twee zoals UX §4.7a zegt. Geen wijziging nodig: het paneel heeft ruimte voor twee regels. | UX Designer | Volgende versie van `hud-menus.md` |
| 22 | **Credits:** de merkenregel uit de glyph-check is 6 regels in de kolom van 320 px (normaal en groot). De inhoud (namen, rollen, licentieteksten) is van de Producer en de Business/Legal Advisor (UX §7 punt 18); de mock-up gebruikt plaatshouders. | Producer, Business/Legal Advisor | Vóór de eerste publieke build |

## 11. Wijzigingen

| Versie | Datum | Wat |
|---|---|---|
| 0.3 | 2026-11-10 | UX §7 punt 16 (#87): placeholder-mock-ups *Spelbestanden* met bevestiging, slot-kader, Logboek, Credits en herbinden met kolomkeuze, normaal en groot (§12.6, §8, script `genereer_menu_placeholder.py`); slot-kader in §12.2; open punten 1–3, 11–13, 15 en 18 gesloten, 19–22 nieuw (20 besloten door de AD na de Lead-review PR #150; bevestiging groot = plaats 2 `KAPOT`); regels uit de glyph-check in §13; W7, W8. |
| 0.2.1 | 2026-11-10 | Na de Lead-review van de AD (PR #142): lamp ook bij hover (§12.3, Theme `icon_hover_color`); herbinden met glyphs en de dialoog in de set van het apparaat (§12.4); regel onder *Doorgaan* op twee regels en in de meting (§12.5, open punt 18); Menu-glyph in de P2-hint; *Pauze van P1* bovenaan (MN-11); Deck-glyphs in ijzer 5 (§13); open punt 14 besloten. |
| 0.2 | 2026-11-10 | T10 deel 3 (#87): menu-art (§12), knop-glyphs per apparaat (§13), Godot Theme normaal en groot (§14), fonts titel ×2 en spelnaam ×3 (§4), previews (§8), regels voor menu's (§9), open punten 10–17. |
| 0.1.1 | 2026-11-10 | Na de Lead-review van de AD (PR #137): klokring P2 `#e8ffff` in plaats van `#bff4fc`; map `game/art/ui/`; Godot 4-filter en `font_size` 11/16; open punten 4–6 bijgewerkt. |
| 0.1 | 2026-11-10 | Eerste versie (T10 deel 2, #87): beeldtaal, palet, Polderletter normaal en groot, alle HUD-onderdelen, merk en peilbuis, meetpunt (plaat 66 %), NL-tekst per vak. |

## 12. Menu's (deel 3)

De **indeling** (welke regels, welke volgorde, wat waar staat) is van de UX Designer (UX §4, wireframes). Deze paragraaf legt de **look** vast: onderdelen, staten en maten. Alle bestanden in `game/art/ui/menu/`, 1:1 op de interne resolutie.

### 12.1 Beeldtaal van de menu's

- **Focus = licht aan.** De gekozen regel krijgt de *keuzebalk* (rand gloed, warme vulling) en links het **lantaarntje** van de HUD. Zo zegt het menu hetzelfde als de kernloop: waar licht is, ben jij. Gloed staat in een menu alleen op de focus, de gekozen tab-tekst en wat je gaat veranderen (schuif, *Druk een knop…*).
- **Alles wat geen focus heeft, is tekst.** Geen knoppen met een eigen vlak: niet-gekozen regels zijn alleen tekst in gevel wit 5. Dat houdt de menu's licht en de stad zichtbaar.
- Panelen zijn de **ijzeren platen van het gemaal**: een rand van 2 px ijzer met klinknagels, voor dialogen. De rest staat op de doorschijnende plaat (zijband, kader), zoals de HUD.
- Dezelfde regels als de HUD (§2): contour 1 px `#06060f`, geen verlopen of gloed rond vormen, geen nieuwe kleuren.

### 12.2 Onderdelen

| Bestand | Maat, 9-slice-marge | Wat | In Godot (Theme, §14) |
|---|---|---|---|
| `keuzebalk_9slice.png` | 9×9, marge 3 | focus: rand gloed 5 (boven gloed 6, onder gloed 3), vulling gloed 0 op 70 % | `Button` *focus* |
| `keuzebalk_ingedrukt_9slice.png` | 9×9, 3 | ingedrukt: ingezakt (bovenrand gloed 3, onder gloed 5), vulling gloed 1 op 92 % | `Button` *pressed* |
| `keuzebalk_hover_9slice.png` | 9×9, 3 | muis erboven zonder focus: rand gevel wit 4, plaat 78 % | `Button` *hover* |
| `keuze_lamp.png` | 7×9 | het lantaarntje *vol* van de HUD (HUD-01), alleen te zien bij focus en ingedrukt | `Button` *icon* |
| `leeg_1x1.png` | 1×1 | transparant: icoon voor varianten zonder lamp | `HerbindCel` *icon* |
| `tab_gekozen_9slice.png` | 9×9, 3 | gekozen tab: rand gevel wit 7/6/5, onder open, plaat 78 % | `TabBar`, `TabContainer` *tab_selected* |
| `tab_paneel_9slice.png` | 5×5, 2 | de tablijn (gevel wit 3) | `TabContainer` *panel* |
| `schuif_baan_9slice.png` | 7×7, 3 | leeg glas, zoals de lichtmeter (lucht 3, bovenrij lucht 4) | `HSlider` *slider* |
| `schuif_vulling_9slice.png` | 7×7, 3 | gloed 6/5/3, zoals de vulling van de meter | `HSlider` *grabber_area* |
| `schuif_greep.png`, `_focus`, `_uit` | 5×11 | klem in gevel wit; gloed bij focus of muis; gedoofd als hij uit staat | `HSlider` *grabber*, *grabber_highlight*, *grabber_disabled* |
| `keuzepijl_{links,rechts}.png`, `_focus` | 5×7 | `<` en `>` naast een keuzewaarde (*< Vasthouden >*); gloed 6 alleen op de gekozen regel | `TextureRect` naast het waarde-Label |
| `herbind_wacht_9slice.png` | 7×7, 2 | cel die wacht op een knop (`MENU_PRESS_KEY`): vol gloed 5, tekst bijna-zwart | variant `HerbindWacht` |
| `cel_focus_9slice.png` | 7×7, 2 | gekozen kolom binnen de gekozen herbind-regel: open rand gloed 6 | variant `HerbindCel` *focus* |
| `scroll_baan_9slice.png`; `scroll_greep_9slice.png`, `_hover`, `_vast` | 5×7, 2 | leeg glas; greep gevel wit 6, bij muis 7, vastgepakt gloed | `VScrollBar` |
| `paneel_9slice.png` | 11×11, 4 | dialoog (bevestigen, *Bezet door …*): ijzer 2 px met klinknagels, plaat 85 % | `PanelContainer`, `Panel` |
| `zijband_9slice.png` | 5×5, 2 | band links achter hoofdmenu en pauze: plaat 78 %, rand gevel wit 2 rechts | variant `Zijband` |
| `../hud/kader_9slice.png` | 7×7, 2 | uitleg onder de opties, info in de pauze (zelfde kader als logkader en meldingen) | variant `Uitleg` |
| **slot-kader** (geen eigen bestand) | 400 × 36, groot 584 × 50 | een plaats in *Spelbestanden*: normaal = `kader_9slice`; focus en hover = `keuzebalk_9slice` over het hele kader + `keuze_lamp` op (x + 3, midden); ingedrukt = `keuzebalk_ingedrukt_9slice` eronder. Geen staat *uit* (UX §4.7a) | variant `Slot` (open punt 19) |

Geen asset: de **verduistering** achter Opties is een `ColorRect` in lucht 0 (`#06060f`) op **72 %**; de pauze verduistert de wereld 35 % en zet de zijband erover (de HUD blijft staan, UX §4.3).

### 12.3 Staten van een menuregel

| Staat | Achtergrond | Lamp | Tekst |
|---|---|---|---|
| normaal | geen | (ruimte blijft, onzichtbaar) | gevel wit 5 |
| focus | keuzebalk | aan | gevel wit 7 |
| ingedrukt | keuzebalk ingedrukt (+ focus erover) | aan | gloed 6 |
| hover (muis) | keuzebalk hover (met focus: keuzebalk erover) | aan | gevel wit 7 |
| uit | geen | uit | gevel wit 3 |

De muis neemt de focus (§9), dus hover zonder focus komt in de game niet voor; de lamp staat daarom ook bij hover aan (AD-review PR #142).

Hoogte van een regel: **15 px** (regel 11 + 2 + 2), groot **20 px** (16 + 2 + 2). Tekst start 13 px na de linkerkant (3 marge + lamp 7 + 3).

### 12.4 Plaatsing (interne pixels; Deck: zelfde getallen met H = 400)

| Scherm | Wat | Waar |
|---|---|---|
| Titelscherm (MN-02) | zelfde opbouw als het hoofdmenu; `MENU_PRESS_ANY` op de plaats van de eerste regel | — |
| Hoofdmenu | zijband | x 0, breedte 214, hele hoogte |
| | spelnaam (`Spelnaam`, ×3) / "werktitel" (`Gedimd`) | (28, 44) / (30, 80) |
| | *Doorgaan* (Button, 160 breed) | (28, 108) |
| | regel onder *Doorgaan* (`Gedimd`, UX §4.2 nr. 2), op twee regels: wijk / licht · speeltijd | (41, 123) en (41, 133) |
| | overige regels (Button, 160 breed) | x 28, y 148 + 16 × i |
| | "2e speler: druk op" (`P2`) + Menu-glyph van de set (PS-stijl: *options*) | glyph rechts op W − 8, y 314; tekst 3 px links ervan |
| | taal-hint (glyph + tekst) | linksonder, glyph op (8, H − 19) |
| | knophints | rechtsonder, laatste tekst eindigt op W − 8, glyph op y H − 19; 3 px tussen glyph en tekst, 10 px tussen paren |
| Pauze | titel (`Titel`, ×2) | (28, 36) |
| | regels (Button, 160 breed) | x 28, y 76 + 16 × i |
| | info rechts (`Uitleg`, 152 × 64) | (226, 74), regels om de 14 px |
| | "Pauze van P1. P2 kan niet sturen." (`Gedimd`, MN-11: bovenaan) | gecentreerd, y 6 |
| Opties | titel / tabbalk | (28, 8) / y 34: LB-glyph op x 22, tabs 4 px uit elkaar, RB-glyph erachter; tablijn op y 49 van x 16 tot 624 |
| | regels (Button, 588 breed) | x 20, vanaf y 56, om de 18 px (groot 22) |
| | waardekolom | x 400 (groot 392): pijl, 4 px, waarde, 4 px, pijl; schuif 120 × 7, percentage 8 px erachter |
| | uitleg (`Uitleg`, 588 breed) | onderaan, 8 px boven de knophints; 4 regels om de 10 px (groot 14) |
| Besturing | kolommen Actie / Toetsenbord 1 / Toetsenbord 2 / Controller | x 20 / 196 / 326 / 466 (tekst + 13), kop in gloed 6, regels om de 18 px |
| | cellen | glyphs van de kolom: `Toetskap` met de toetsnaam, pijl- en muisglyphs, in *Controller* de glyphs van de set; meerdere knoppen 3 px uit elkaar; geen knop = "–" in gevel wit 3 |
| | dialoog *Bezet door …* (`PanelContainer`) | midden, y 238; de knoppen erin (A = wisselen, B = annuleren) en de knophints in de set van het apparaat waarmee je herbindt |

Bij *groot* past de optielijst niet meer op het scherm: de lijst scrolt (`ScrollContainer` met de scrollbalk, x 612) en houdt de gekozen regel in beeld.

### 12.5 Tekstmeting menu's (script, testteksten EN/NL)

Alles past, ook groot (vak × 1,5, TG-10), op één na: de langste NL-menuregel (*Naar hoofdmenu*) is 69 px van 147; *Meedoen (vrij apparaat)* 104 van 163 in de kolom *Actie*; *Druk een knop…* 69 van 127. De tabbalk is NL 298 px (groot 349) van de 608 die er zijn.

**Regel onder *Doorgaan*** (vak 165 px: van x 41 tot 4 px voor de rand van de zijband). Op één regel past hij niet: *Wijk 1.1 De Kadewijk · Licht 40 · 12 min* is al 169 px. Daarom staat hij op twee regels. *Wijk 1.1 De Kadewijk* is 85 px (EN *District 1.1 The Quayside* 108), *Licht 100 · 12 u 59 min* 102 px. Een lange testnaam (*Wijk 3.2 De Verzonken Gemaalpolder*) is NL 160 px en past, maar in het EN is hij 176 px en past hij **niet**. Bij *groot* wordt de zijband 260 px breed. Zie open punt 18.

**Knoptekst zonder schaduw** (menunorm van de AD, open punt 14). Een Godot-`Button` tekent geen tekstschaduw (§14). Gemeten tegen de lichtste plek van de R5-scène: focus ΔL\* 44,2; normaal op de zijband 38,8; normaal op de verduistering van 72 % 34,7. Daarom staat elke menuregel op de zijband, de verduistering of de keuzebalk, nooit los op de wereld (open punt 14).

## 13. Knop-glyphs per apparaat

Alle bestanden in `game/art/ui/glyphs/<apparaat>/`, als losse PNG per knop; `<naam>.png` is normaal (**11 px** hoog, naast Polderletter normaal), `<naam>_groot.png` is groot (**15 px**, naast groot). Een glyph staat in de tekstregel, verticaal gecentreerd.

- **Eigen tekeningen, generieke vormen.** Schijf, pil, kruis en letters uit Polderletter (groot) of een eigen letter van 3×5 en 5×5 px (normaal). Geen logo's, geen merkiconen, geen merkkleuren van derden.
- **Monochroom**: lijf in ijzer 5 (`#3a3640`, licht `#6a6268`, schaduw `#1f1d26`), symbool gevel wit 7, contour bijna-zwart. Dat geldt voor alle sets, ook de Deck (AD-review PR #142: ijzer 3 viel weg op de plaat). Kleur blijft voor licht en spelers (open punt 14, akkoord AD).
- Vormen zeggen wat voor knop het is: **schijf** = gezichtsknop of stick, **platte pil** = schouder, **hoge pil** = trekker, **pil met schuine hoek** = greep achterop (Deck), **afgeronde tegel** = trackpad (Deck), **kruis** = d-pad, met de richting in gevel wit 7.

| Set | Bestanden (`<naam>.png`) |
|---|---|
| `toetsenbord/` | `toetskap_9slice.png` (7×11, marge 3) en `toetskap_groot_9slice.png` (9×16, marge 4) met de toetsnaam als Label erin (variant `Toetskap`, §14); `pijl_{op,neer,links,rechts}`, `muis_{links,rechts,wiel}` |
| `xbox/` (Xbox-stijl) | `a b x y`, `lb rb lt rt`, `menu view`, `dpad` + `dpad_{op,neer,links,rechts,verticaal,horizontaal}`, `stick_l stick_r stick_l_klik stick_r_klik` |
| `playstation/` (PlayStation-stijl) | `kruis rondje vierkant driehoek`, `l1 r1 l2 r2`, `options create touchpad`, `dpad…` (idem), `stick_l stick_r l3 r3` |
| `deck/` (Steam Deck) | `a b x y`, `l1 r1 l2 r2`, `l4 l5 r4 r5`, `menu view`, `dpad…`, `stick_l stick_r l3 r3`, `trackpad_l trackpad_r` |

- **Toetsenbord**: de toets is een 9-slice met de **echte** toetsnaam als tekst, zodat AZERTY en andere indelingen kloppen (UX §4.5, `input.md` W7). Tekst gevel wit 7 zonder schaduw.
- Welke set: *Knopiconen* in Opties (automatisch = het laatst gebruikte apparaat van die speler; Deck-glyphs op de Deck), UX §4.4–4.5. De herkenning van het apparaat is van de Engine & Platform Programmer (UX §7 punt 4).
- Niet getekend: de Steam- en de …-knop van de Deck (de game bindt ze niet) en de PS-knop/Xbox-knop (idem).
- **Grenzen uit de glyph-check** (`docs/business/knop-glyphs-check.md` §3, open punt 15): de glyphs mogen blijven zoals ze zijn (🟢). Nooit (🔴): de vier PlayStation-vormen samen als rij of embleem (ook niet als decor, loading screen of op de Steam-pagina), de PS-vormen of Xbox-letters in hun merkkleuren, de Xbox-, PS- of Steam-knop, een controller-silhouet. Het overzichtsblad `knop_glyphs_x4.png` is intern. Knophints tonen per scherm alleen de knoppen die iets doen, dus nooit alle vier de vormen tegelijk. Nieuwe glyphs (Switch, silhouet): eerst een check bij de BLA.

## 14. Godot Theme

`game/art/ui/thema/polderlight_menu.tres` (normaal) en `polderlight_menu_groot.tres` (*Tekstgrootte: groot*), gemaakt door `genereer_menu.py`; niet met de hand wijzigen, maar het script aanpassen en opnieuw draaien. Paden zijn `res://art/ui/…` (de Godot-projectmap is `game/`).

| Type | Wat het Theme zet |
|---|---|
| (standaard) | `default_font` Polderletter normaal, `default_font_size` 11 (groot: groot, 16) |
| `Label` | tekst gevel wit 7, schaduw `#06060f` op (1, 1), `line_spacing` −1 (groot −2) |
| `Button` | de menuregel van §12.3: *normal* leeg, *focus* keuzebalk, *pressed* ingedrukt, *hover* hover; icoon = lamp, onzichtbaar via `icon_normal_color`/`icon_hover_color` met alfa 0, zichtbaar bij focus en ingedrukt; `h_separation` 3; tekstkleuren per staat |
| `PanelContainer`, `Panel` | paneel (dialoog), inhoudsmarge 8/6 |
| `TabContainer`, `TabBar` | gekozen tab, tablijn als *panel*; tekst gekozen gloed 6, anders gevel wit 5; de tabs nemen geen focus (wissel met LB/RB) |
| `HSlider` | baan, vulling en greep van §12.2 |
| `VScrollBar` | baan en greep (normaal, hover, vast) |
| `HSeparator` | lijn van 1 px gevel wit 3 |
| `RichTextLabel` | als Label, voor credits en logboek |

**Type-varianten** (`theme_type_variation` op de node):

| Variant | Basis | Gebruik |
|---|---|---|
| `Kop` / `Gedimd` / `Uit` / `P2` | Label | tekst in gloed 6 / gevel wit 5 / gevel wit 3 / cyaan |
| `Titel` | Label | Polderletter ×2 (`font_size` 22), schaduw 2 px: *Pauze*, *Opties* |
| `Spelnaam` | Label | Polderletter ×3 (`font_size` 33), schaduw 3 px: de werktitel op titelscherm en hoofdmenu |
| `Toetskap` | Label | toets-glyph met tekst (toetskap als *normal*, geen schaduw) |
| `HerbindWacht` | Label | *Druk een knop…* in de wachtende cel |
| `HerbindCel` | Button | cel in een kolom van *Besturing*: geen lamp, focus = `cel_focus` |
| `Zijband`, `Uitleg` | PanelContainer | band links (hoofdmenu, pauze); kader onder de opties en rechts in de pauze |

Wat het Theme **niet** kan en de bouwer per node zet:
- `alignment = Left` op menuregels (een Button centreert standaard).
- **Tekstschaduw in een Button** bestaat in Godot niet; zie §12.5. Wie toch schaduw wil, zet een Label in de Button.
- De verduistering (`ColorRect`, §12.2), de keuzepijlen naast een waarde en de glyphs in de knophints.
- Filter Nearest: via de projectinstelling of `texture_filter` op de wortel van het menu (§9, open punt 6).

### 12.6 Placeholder-mock-ups: Spelbestanden, Logboek, Credits, kolomkeuze (UX §7 punt 16)

Gemaakt door `genereer_menu_placeholder.py` uit de onderdelen van §12.2, met de maten van UX §4.5, §4.7a, §4.8 en §4.9 (die gelden; hier alleen wat de art toevoegt). Bestanden: §8. Placeholder (W7): de indeling klopt, de eind-art volgt.

| Scherm | Wat de art doet |
|---|---|
| *Spelbestanden* | Verduistering 72 %, `Titel`, drie slot-kaders (§12.2). Regel 1 *Plaats n* in gevel wit 5, met focus 7 (ingedrukt gloed 6); *Hersteld uit back-up* rechts in `Gedimd`; regel 2 `Gedimd`, `KAPOT`/`NIEUWER` in gloed 6, *Leeg* in gevel wit 3. Melding MN-24 in `kader_9slice`, tekst gevel wit 7. Knophints volgen de stand: op een `KAPOT`-plaats geen A. |
| Bevestiging (MN-23) | Lijst nog eens 50 % verduisterd, `paneel_9slice` (ijzer met klinknagels). *Terug* met keuzebalk en lamp, *Overschrijven* als gewone regel in gevel wit 5: **geen rood en geen waarschuwingskleur** (rood is van vijanden, open punt 4); de bescherming zit in de bediening. |
| Logboek | Tabbalk zoals Opties (gekozen tab gloed 6); niet gevonden = *– – –* in de staat *uit* (gevel wit 3, geen lamp); het kader is het logkader van de HUD (kop gloed 6), groot onder de lijst. |
| Credits | Kop gloed 6, namen gevel wit 7, gecentreerd in 320 px; geen scrollbalk; tekst boven de knophints wordt afgesneden door de `ScrollContainer`. Hints: d-pad verticaal *Sneller* (toetsenbord: pijl omlaag), B/Esc *Terug*. |
| Herbinden, kolom | `cel_focus` loopt van 4 px vóór de glyphs tot 4 px vóór de volgende kolom (in *Controller* tot x 604, binnen de keuzebalk). *Ook: linker stick* in gevel wit 3 met de stick-glyph: geen cel, geen focus (MN-43). Hint *Kolom* met `dpad_horizontaal`. Bij de eind-art: vulling gloed 1 en gelijk met de keuzebalk (open punt 20, besloten door de AD). |

**Meting** (script, Polderletter): regel 2 met de langste testwijk + *· Licht 100 · 12 u 59 min · Lampglas 4/4* is 342 px van 379 (groot 417 van 563); *Gemaakt met een nieuwere versie: kan niet laden* 215 px (groot 258); alle bevestigingsteksten passen op één regel normaal (≤ 368 px) en groot (≤ 448); titel ×2 *Plaats 3 overschrijven?* 216 px; logbladzijde en `MENU_LOG_NONE` ≤ 200 px van 348; merkenregel in de credits 6 regels.

