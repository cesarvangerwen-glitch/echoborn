# Animatie-timing

Versie 0.2 · Eigenaar: Animator · Issues [#265](https://github.com/cesarvangerwen-glitch/echoborn/issues/265) (assetlijst S-14) en [#272](https://github.com/cesarvangerwen-glitch/echoborn/issues/272) (S-13) · Hoort bij `docs/art/bible.md` v0, `docs/art/slice-kadewijk.md` v0.5 (§4, §12) en `docs/design/gemaalmeester.md` v0.2.3

Frames per animatie en per aanvalsfase. Tijden in **ticks** (60 per seconde, dus frames bij 60 fps). De bron van elke tijd is `game/data/vijanden/slice.csv`; de generator leest die, dus een nieuwe waarde in data geeft na een nieuwe run nieuwe tick-lijsten in het manifest. Dit document bevat de Gemaalmeester (§1) en de drie vijandtypes van de slice (§2). Spelers en echo volgen in eigen secties.

**Werkaanname (kader §5):** S8 is maatvast en op eindkwaliteit (slice-kadewijk §12). De maten van de boss komen uit de code (`gemaalmeester.gd`, `boss.gd`) en uit de data. Ik heb **geen `.gd` en geen scènes gewijzigd**: de koppeling doen de TA en de GP (§1.6).

---

## 1. De Gemaalmeester (S-14)

### 1.1 Bestanden

| Wat | Waar |
|---|---|
| Generator (deterministisch, ± 20 s, geen externe assets) | `docs/art/slice/bron/genereer_gemaalmeester.py`: `python3 docs/art/slice/bron/genereer_gemaalmeester.py` vanaf de repo-root. Deel 1–5 hoeven niet opnieuw. |
| Atlassen in grijs, half, kleur en index, met `.import` (TD-besluit c) | `game/art/animatie/gemaalmeester/gemaalmeester_<blad>_<staat>.png` |
| Manifest: per blad de cel, de offset, de z-index en per animatie de frames, de ticks per frame, lus/volgt en welke vlag het frame kiest | `game/art/animatie/gemaalmeester/gemaalmeester.json` |
| Overzichtsbladen ×2 | `docs/art/slice/eindkwaliteit/gemaalmeester_bladen_{grijs,kleur}_x2.png` |
| De boss in S8 (vier momenten, grijs en kleur), los op 640 × 360 | `s8_gemaalmeester_momenten_x2.png`, `s8_gemaalmeester_fase{1,2}_{grijs,kleur}_640x360.png` |
| Leesbaarheid (luminantie, deuteranopie) | `s8_gemaalmeester_leesbaarheid_x2.png` |
| P1 en de holle echo bij de ketel (punt van de CD in #247) | `s8_gemaalmeester_ketel_echo_x4.png` |
| Het gevecht als GIF (grijs, 17 s, elke 3e tick) | `s8_gemaalmeester_gevecht.gif` |

### 1.2 Opbouw: negen bladen

De boss draait niet en loopt niet (GM-02). De ketel staat dus altijd op dezelfde plek. Daarom is hij in lagen opgedeeld, zodat de staat van het schot los van de pose loopt:

In de tabel staan de cel en de offset van de **inhoud**. In de atlas heeft elk frame rondom **1 px transparante rand** (§1.4). De cel in het manifest is daarom 2 px breder en hoger, en de offset ligt (−1, −1) verder: lichaam 130 × 178 op (235, −177). Het manifest (`cel`, `offset`, `rand_px`) geeft de echte waarden.

| Blad | Cel (inhoud) | Plaatsing (`offset` = linksboven van de inhoud, node-coördinaten) | z |
|---|---|---|---:|
| `rad` | 112 × 72 | `rad.position` + (−56, −44): de hurtbox (96 × 40) valt op kolom 8–104, rij 24–64. De loopkat rijdt op de onderkant van de balk van S8 (158 px). | −3 |
| `lichaam` | 128 × 176 | boss-node + (236, −176): lichaam 252–348, 160 hoog | −2 |
| `ketel` | 64 × 64 | boss-node + (268, −68): het schot (276–324 × 12–60) op kolom 8–56 | −1 |
| `spuigat` | 24 × 32 | (`spuigat_links`/`_rechts`, 0) + (−12, −20) | −1 |
| `tell_pomp`, `tell_zwiep` | 160 × 24, 300 × 24 | `attack_box.position`: precies het vlak | 0 |
| `pompslag` | 176 × 40 | `attack_box.position` + (−8, −12) | 1 |
| `zwiep_links`, `zwiep_rechts` | 300 × 40 | `attack_box.position` + (0, −10) | 1 |

**Fase 1: het rad zit op zijn rug.** Bij `RadState.HIDDEN` hangt het rad achter het lichaam op (300, 120): `draai_s0`, frame 0, stil. Je ziet het boven de schouders (GM-02: "bovenin het grote rad"). Bij de fasewissel lerpt de code het rad van `middle()` naar zijn kant (`_rad_from_x`). Het beeld volgt dat vanzelf: het rad hijst zich van zijn rug.

**De pompslag komt uit de vloer.** In fase 2 ligt het vlak op de x van P1, overal in de arena (combat §3.5). Een stang vanaf het lichaam zou daarvoor 300 px lang moeten zijn, en in pixel art kun je niet draaien (bible §2). Daarom slaat de drijfstang naast hem op de vloer, en perst het gemaal water door de leidingen onder de vloer: op het vlak **barsten de vloerplaten open** met een waterwand van 24 px. Dat leest als een gemaal en werkt op elke x. De aanloop toont het: de platen ratelen en er sijpelt stoom uit de voegen, de "stofstrook die feller wordt" van combat §3.4.

### 1.3 Frames en tijden

Lichaam (`lichaam`):

| Animatie | Frames | Ticks per frame | Wat | Vlag (`boss.gd`/`gemaalmeester.gd`) |
|---|---:|---|---|---|
| `idle` | 6 | 10 (lus) | stoom uit de schoorsteen, de ogen knipperen, de schoepen draaien traag | `state == FIGHT`, geen aanval |
| `aarzeling_links/rechts` | 3 | 7 7 6 | **de eerste aanloop** (`eerste_aanloop` 60 = 20 aarzelen + 40 pompaanloop): de kop zakt naar P1, de ogen gaan wijd open, de stang reikt half (de sjaal; GM-04) | eerste `attack_started` |
| `pomp_aanloop_links/rechts` | 5 | 10 9 9 9 **3** (fase 1, 40) · 7 7 7 6 **3** (fase 2, 30) | **anticipation:** de stang heft zich in 4 stappen naar die helft, het lijf leunt weg, de stoom neemt toe. Frame 4 is de uithaal (veeglijnen), de laatste 3 ticks | `windup_progress` |
| `pomp_slag_links/rechts` | 2 | 3 3 | **het verste frame**: de kruiskop op de vloer, het lijf leunt mee, stof. Valt samen met de 6 actieve ticks | `attack_phase == ACTIVE` |
| `pomp_ligt_*` | 1 | 24 | de stang ligt op de vloer (herstel) | `RECOVER` |
| `pomp_terug_*` | 2 | 6 6 | terug naar idle, in de rust van de maat | daarna `idle` |
| `zwiep_aanloop_links/rechts` | 5 | 7 7 7 6 **3** | het schoepenwiel aan die kant draait op en schuift 6 px uit; de stang gaat naar achteren. Frame 4 = uithaal | `windup_progress` |
| `zwiep_veeg_*` | 2 | 4 4 | het verste frame: de stang zwaait naar buiten, het wiel draait vol | `ACTIVE` (8) |
| `zwiep_uit_*` | 2 | 10 10 | het wiel loopt uit | `RECOVER` (20) |
| `fasewissel` | 4 | 15 × 4 | stoom uit alle naden, hij richt zich op (het rad gaat van zijn rug), ogen wijd | `phase_changed("wissel")` (60) |
| `wankel_in` → `wankel` | 2 → 4 | 8 8 → **12 4 16 6** (lus) | hij zakt, één schouder lager, de stangen hangen op de vloer. Hij hapert: onregelmatige tijden, de ogen half dicht | `state == WANKEL` |
| `geraakt` | 2 | 4 4 | een schok door het bovenlijf | treffer op de kern, elke `finisher_strike` |
| `oplossen` | 10 | 6 × 10 | GM-10: warme aders in *gloed*, dan stijgt hij weg als lichtdeeltjes (het licht dat hij vasthield) | `boss_defeated` |

Ketel (`ketel`):

| Animatie | Frames | Ticks | Wat | Vlag |
|---|---:|---|---|---|
| `schot` | 2 | 30 30 (lus) | het roestschot (pantser: roest = "hier moet een merk op"); de naad eromheen gloeit | fase 1, `armor_intact` |
| `tink` | 1 | 4 | witte ster en bovenrand: dit is pantser | `ketel.tink_tick` (TINK_TICKS 4) |
| `breuk` → `kern` | 3 → 4 | 4 4 4 → 8 × 4 (lus) | barsten met gloed, het schot springt in vier stukken, stoom; de kern pulseert (vijandkern, nooit FelLicht) | `shot_broken`, `core_open` |
| `kern_geraakt` | 2 | 3 3 | de kern flitst | `damaged` op de kern |
| `schot_sluit` | 3 | 7 7 6 | een nieuw schot schuift van boven voor de kern | `core_closed` |
| `schot_dicht` | 1 | — | fase 2: voorgoed dicht, gelast met ijzeren klemmen, **niet Merkbaar** (geen gloeiende naad, geen roest) | fase 2 |
| `merkplek_open` → `merkplek` | 3 → 2 | 7 7 6 → 20 20 (lus) | de klemmen vallen weg, een rode peilmerk-ring met streep gaat open | `state == WANKEL` (GMB-05) |
| `oplossen` | 10 | 6 × 10 | gelijk met het lichaam | `boss_defeated` |

Rad (`rad`), in vier stadia van scheuren `s0`–`s3`:

| Animatie | Frames | Ticks | Wat | Vlag |
|---|---:|---|---|---|
| `draai_s<n>` | 8 | 8 (hangt) · 3 (`ticks_draaien`) | het liggende kaapstanderrad draait in zijn vlak, 7,5° per frame (spaken om de 60°, beslag om de 30°: de lus klopt). De velg vult de hurtbox | `HANGING` / `TURNING` |
| `treffer_s<n>` | 2 | 3 3 | de velg flitst, een vonk | `rad_hit` (schok 3 ticks) |
| `trilt_s<n>` | 2 | 2 2 (lus) | **de tell van het wegdraaien**: het rad ratelt 1 px heen en weer, de as gloeit fel | `SHAKING` (`rad_tril` 20) |
| `oplossen` | 8 | 7 × 8 | zoals het lichaam | `boss_defeated` |

De scheuren zijn zesvoudig, zodat ze meedraaien zonder te verspringen. Voorstel: `s = min(3, rad_turns // 3)`, het rad scheurt per ± 3 kanten. Dat is het voorstel van combat §9.2 (voortgang zonder balk). De UX Designer beslist; zonder besluit gebruik je `s0`.

Effecten:

| Blad / animatie | Frames | Ticks | Vlag |
|---|---:|---|---|
| `tell_*` `vroeg` / `laat` / `actief` | 1 elk | — | `windup_progress < 0,5` / `≥ 0,5` / `is_attack_active()` |
| `pompslag` `aanloop` / `actief` / `herstel` | 4 / 2 / 3 | kwarten van de aanloop / 3 3 / 8 8 8 | zoals de tell |
| `zwiep_<kant>` `aanloop` / `actief` / `herstel` | 2 / 2 / 2 | tweede helft van de aanloop / 4 4 / 10 10 | zoals de tell |
| `spuigat` `gloei` → `stoom` | 3 → 2 | 10 10 10 → 15 15 | `spout_glowing` (30), daarna `add_inactief` (30) |

### 1.4 Regels die elke pose haalt

- **Anticipation per aanval:** de pompslag en de zwiep hebben elk een aanloop in 4 stappen plus een uithaal van 3 ticks. Het lijf beweegt tegen de slag in. De aarzeling is een eigen anticipation van 20 ticks.
- **Het actieve vlak valt op het verste frame** (combat §9): `pomp_slag` (kruiskop op de vloer) en `zwiep_veeg` (stang naar buiten) beginnen op de eerste actieve tick. De uithaal zit in de aanloop, niet in het actieve vlak.
- **Waar, niet alleen dat** (deel 1 §4.3): het tell-vlak ligt precies op `attack_box`. De pose wijst de helft aan: de stang of het schoepenwiel aan die kant.
- **Bovenrand van 2 px** op elk lijfdeel en op de velg van het rad, in elk frame behalve het oplossen (deel 1 §4.2). In grijs en half gloeien de bovenrand en de kern een tint feller (VJ-06).
- **De boss houdt zijn kleur in elke toestand**: lijf, kern, roest, ijzer en hout zijn een figuur (bible §4.1.5, deel 1 §4.2 regel 2). **Water en stoom volgen de toestand**: in grijs zijn ze grijs. Amber en cyaan komen niet in de boss; het merk is een overlay van de UI (`game/art/ui/wereld/merk_*`). Stoom is grijs-wit, nooit FelLicht (GMB-06).
- Geen rotatie of schaal, geen transparantie, contour van 1 px bijna-zwart rond het silhouet, alleen ordered dithering (stoom, water, de tell).
- **1 px transparante rand rond elk frame** (eis van de echo-contour van de TA, [#267](https://github.com/cesarvangerwen-glitch/echoborn/issues/267)). De contour-shader tekent 1 px buiten het silhouet. Zonder rand valt die lijn buiten het frame, of pakt hij pixels van het buurframe in de atlas. Dit geldt voor **elke sprite van de Animator**: de spelers en hun echo's, de vijanden en de boss. Ook als een frame tot de rand van zijn cel loopt (de sokkel op de vloer, een tell-vlak), komt de rand er in de atlas omheen. De generator doet dat (`RAND = 1` in `Blad.export`) en controleert het: 0 van de 191 frames heeft een pixel op de rand.

### 1.5 Metingen (`genereer_gemaalmeester.py`, S8 bij D = 60)

ΔL\* tegen de directe achtergrond (ring van 2–6 px), zoals bible §7.3 en deel 1 §4.2:

| | Grijs | Kleur | Norm |
|---|---:|---:|---|
| Bovenrand van het lichaam (p90) | **82,5** | **76,9** | ≥ 50 ✓ |
| Lijf van het lichaam (mediaan) | 2,9 | 2,7 | — (een vijand leest op bovenrand en kern, deel 1 §4.2) |
| Bovenrand van het rad, op x 94 en x 506 | **74,2** | **71,9** | ≥ 50 ✓ |
| Velg van het rad (hout, mediaan) | 13,0 | 10,7 | — |
| Kern open tegen het schot, op dezelfde plek (p90) | 27,1 | 15,2 | leesbaar zonder kleur (grijs) ✓ |

Tells: ΔL\* van het vlak met en zonder tell, gemiddeld over het vlak, en die van de gezette pixels zelf (mediaan). Sinds v0.1.1 staan vroeg en laat allebei in **vijandkern 4**. Ze verschillen alleen nog in dichtheid (25 % tegen 75 %), zodat ook de vroege stap zonder kleur leest (Lead-review AD op PR #266; was vijandkern 3, 4,8 / 3,9):

| Tell | Grijs vroeg / laat / actief | Kleur vroeg / laat / actief | Gezette pixels, vroeg en laat (grijs / kleur) |
|---|---|---|---|
| Pompslag (fase 1 links, vóór de plint en de wand) | **7,4** / **20,0** / **31,8** | 6,5 / 17,4 / 28,6 | 41,7 / 40,7 |
| Schoepenzwiep (links, vóór het tegenlicht van het raam) | **9,2** / **24,7** / **37,0** | 8,4 / 22,5 / 34,1 | 41,5–41,7 / 39,4–40,6 |

De tell wordt in luminantie elke stap duidelijker. Elke gezette pixel van de vroege stap ligt nu ± 40 in L\* van de achtergrond. Gemiddeld over het vlak is hij zacht (7–9), want maar een kwart van de pixels is gezet: dat is het verschil met laat (17–25). Zo leest hij zonder kleur als een gestippeld vlak dat dichter wordt (`s8_gemaalmeester_leesbaarheid_x2.png`).

**Punt van de CD (#247): de holle echo naast P1 bij de ketel.** P1 staat bij het schot, de echo op 6 en op 3 px (half en bijna helemaal over P1), vóór het schot en vóór de open kern:

| | Rand van de echo, waar hij niet over P1 valt (p90) | Bijna-zwarte contour van de echo over P1 (mediaan) |
|---|---:|---:|
| grijs, schot | 55,0 | 66,5 (6 px) / 40,0 (3 px) |
| grijs, kern | 64,4 | 66,5 / 40,0 |
| kleur, schot | 46,3 | 66,5 / 50,2 |
| kleur, kern | 55,1–55,7 | 66,5 / 50,2 |

Alles haalt ≥ 40. Het donkere lijf en het roestschot zijn een rustige, donkere achtergrond. Daarop leest de lichte rand van de echo als tweede lichaam, en waar hij over P1 valt, scheidt zijn bijna-zwarte buitencontour hem van de crème jas. Vóór de kern schijnt het rood door de arcering: dat is de holte. Op 3 px wordt het krap in grijs (40,0, op de grens). Dat is de echo-weergave van de TA (F-07), niet de boss: zie §1.7.

### 1.6 Overdracht aan de TA en de GP

Het manifest (`koppeling`) zegt per signaal en vlag welke animatie loopt. Kort:

1. Vervang `_build_visual`/`update_visual` (de placeholder-polygons) door `Sprite2D`'s met `region_rect` uit het manifest, `centered = false`, op de offsets en z-indexen van §1.2. Kies de toestand zoals in de wijk: in het gevecht `grijs` (s = 1).
2. Tell en effect op `attack_box`. Kies het frame met `windup_progress(tick)` en `is_attack_active()`. Het lichaam kiest zijn aanloopframe ook op `windup_progress`, met de uithaal op de laatste 3 ticks van de aanloop.
3. `zwiep_rechts` is `zwiep_links` gespiegeld, al uitgerekend; de plaatsing is gelijk (`attack_box.position`).
4. Het rad tijdens `TURNING` met `ticks_draaien`; de trilframes verschuiven zelf 1 px (de code zet de jitter van de placeholder dan op 0).
5. De `.import`-bestanden zijn gecommit (Lossless, mipmaps uit, zoals de kadewijk-art).

### 1.7 Open punten

- **Koppeling** (§1.6): TA met GP, daarna een SM-review (code in `game/`).
- **De loopkat in de achtergrond van S8** (deel 5, midden boven de boss) blijft staan als het rad wegrijdt. Het rad heeft nu zijn eigen loopkat. Voorstel aan de AD: de vaste loopkat uit `s8_machinehal_midden_*` halen, of hem als "parkeerplek" laten staan.
- **Scheuren per kant op het rad** (`s0`–`s3`) en de ketel als voortgang: besluit van de UX Designer (combat §9.2).
- **Echo op 3 px over P1 in grijs:** ΔL\* 40,0, op de grens. Als de echo-shader er is (F-07/S-10), meet ik opnieuw. Voorstel voor de TA, zoals de AD in §9.7 van het slice-document: de bijna-zwarte buitencontour van de echo altijd 1 px laten staan, ook waar hij over P1 valt.
- **De gedeelde echo van de finisher** (S-15) is van de TA met de AD. De boss speelt in die 120 ticks `wankel` en bij elke finisherslag `geraakt`.
- **Audio** (T8d): de frames volgen de tels van §9.3 van combat (sissende zuiger in de aanloop, de tink, de breuk, het ratelen van het rad). De Audio Director kan de tick-lijsten uit het manifest gebruiken.
- **Ware Deck-test** van de boss en de tells (bible §10): TA bij de eerste Deck-build.

## 2. De slice-vijanden: Kadeloper, Schotdrager, Dwaallicht (S-13)

Werkaanname (kader §5): S1–S9 zijn maatvast (#83), dus eindkwaliteit mag (kader §4 regel 3). Bron van de vorm: deel 1 §4 van `slice-kadewijk.md` en de concepten `concept_vijanden_*`; bron van de tijden: combat §2 en §9.1 via `slice.csv`. Ik heb **geen `.gd` en geen scènes gewijzigd**: de koppeling doen de TA en de GP (§2.5).

### 2.1 Bestanden

| Wat | Waar |
|---|---|
| Generator (deterministisch, ± 45 s, geen externe assets) | `docs/art/slice/bron/genereer_vijanden.py`: `python3 docs/art/slice/bron/genereer_vijanden.py` vanaf de repo-root. Gebruikt de helpers van de Gemaalmeester en de kamers van deel 2–5 (die hoeven niet opnieuw). |
| Atlassen in grijs, half, kleur en index, met `.import` (formaat van de Gemaalmeester) | `game/art/animatie/<type>/<type>_{grijs,half,kleur,index}.png` en `<type>_tell_*`, `dwaallicht_duiklijn_*` |
| Manifest per type: cel, offset (rechts en links), z, per animatie de frames, ticks, lus/volgt en de vlag die het frame kiest | `game/art/animatie/<type>/<type>.json` |
| Overzichtsbladen ×2 | `docs/art/slice/eindkwaliteit/vijanden_bladen_{grijs,kleur}_x2.png` |
| Tell-momenten op hun plek (staan, aanloop vroeg/laat, actief, stil; S3 en S7) | `vijanden_tells_x3.png` |
| Elke plek uit combat §2.6 (S2, S3, S4, S6, S7, S8, S9), grijs en kleur | `vijanden_in_de_kamers_x2.png` |
| Leesbaarheid (luminantie en deuteranopie) | `vijanden_leesbaarheid_x2.png` |
| GIF (grijs, de drie types naast elkaar, 4,9 s, elke 3e tick) | `vijanden_animaties.gif` |

### 2.2 Opbouw en plaatsing

De node van een vijand staat in het midden van zijn hurtbox (`slice_enemy.gd`). Alle offsets zijn linksboven van de cel, `centered = false`, met de 1 px transparante rand van §1.4 al meegerekend.

| Blad | Cel (met rand) | Offset rechts / links | Wat valt waar |
|---|---|---|---|
| `kadeloper`, `schotdrager` | 58 × 42 | (−23, −27) / (−35, −27) | Kijkrichting rechts getekend; links = `flip_h` met `offset_links`. De hurtbox 16 × 24 valt op kolom 15–31, rij 15–39; de vloer op rij 39. Beeld ± 30 × 26 (Schotdrager 22 breed met het schot, deel 1 §4.1) |
| `kadeloper_tell_haak` | 22 × 18 | (−1, −1) op `_walker_box().position` | precies het vlak van 20 × 16 |
| `schotdrager_tell_stoot` | 26 × 18 | idem | het vlak van 24 × 16 |
| `dwaallicht` | 34 × 50 | (−17, −23), symmetrisch | hurtbox 16 × 16 op kolom 9–25, rij 15–31 |
| `dwaallicht_tell_duik` | 18 × 18 | (−1, −1) op de landingsplek (node.x − 8, vloer − `duik_hoogte` − 16) | waar zijn lichaam na de duik is: dat is het vlak |
| `dwaallicht_duiklijn` | 5 × 42 | (−2, −1) op (node.x, node.y + 8) | gestippelde lijn naar het vlak; `region_rect` = de bovenste (baan − duik − 16) px (in de slice 8) |

### 2.3 Frames en tijden

Kadeloper (`kadeloper`):

| Animatie | Frames | Ticks per frame | Wat | Vlag |
|---|---:|---|---|---|
| `staan` | 4 | 12 (lus) | ademt, de stekels wiegen, knippert | geen beweging (VJ-05 houdt hem tegen) |
| `lopen` | 6 | 8 (lus) | laag, kop vooruit, de haak bungelt; 48 ticks = 24 px bij 0,5 px/tick | v > 0 |
| `haak_aanloop` | 5 | 7 7 7 6 **3** (verlicht: 10 9 9 9 **3**) | **anticipation:** de haak gaat in 4 stappen omhoog en naar achteren boven de kop, het lijf leunt weg, de ogen gaan wijd, de kern zwelt. Frame 4 = uithaal met veeglijn | `windup_progress` |
| `haak_slag` | 2 | 3 3 | **het verste frame:** de haak op x 28 (de verste rand van het vlak), 5 px boven de vloer, lijf naar voren, veeg en stof | Phase.ACTIVE (6) |
| `haak_herstel` | 2 | 10 10 | de haak ligt, wordt teruggetrokken | Phase.RECOVER (20) |
| `stil` | 3 | 4 18 8 | schok, knik (1 px lager, ogen een streep, kern een tint zachter), terug | VJ-04 (30) |
| `dood` | 8 | 6 × 8 | lost op in donker water: hij zakt in, wordt water, de kern dooft als laatste, de plas trekt weg | levens 0 (voorstel 48 ticks) |
| `uit_stoom` | 5 | 6 × 5 | stoom, een donker silhouet, de ogen, dan rand en kern; de stoom zakt | add uit een spuigat (`add_inactief` 30) |

Schotdrager (`schotdrager`): `staan`, `lopen`, `stil`, `uit_stoom` en `dood` zoals de Kadeloper, plus:

| Animatie | Frames | Ticks | Wat | Vlag |
|---|---:|---|---|---|
| `stoot_aanloop` | 5 | 7 7 7 6 **3** | het schot gaat in 4 stappen naar achteren tegen het lijf, het lijf duikt in; uithaal met veeglijnen achter hem | `windup_progress` |
| `stoot_actief` | 2 | 3 3 | **het verste frame:** de voorkant van het schot op x 32 (de verste rand van het vlak van 24) | Phase.ACTIVE (6) |
| `stoot_herstel` | 2 | 10 10 | het schot komt terug | RECOVER (20) |
| `tink` | 1 | 4 | witte ster en witte bovenrand op het schot: dit is pantser (VJ-07) | `tink()` (TINK_TICKS 4) |
| `breuk` | 3 | 4 4 4 | barsten met rode gloed, het schot springt in drie stukken en valt | `break_armor()` (12) |
| `stuk` | 1 | — | de drie stukken op de vloer, zonder vijand: blijft liggen waar hij brak | losse Sprite2D op de node-positie bij de breuk |
| `gebroken_*` | 4/6/5/2/2/3 | als hierboven | de Kadeloper met de riem en een stuk schot in de hand; hij stoot met het stuk tot x 32 (zelfde vlak) | na `break_armor()` |

Dwaallicht (`dwaallicht`):

| Animatie | Frames | Ticks | Wat | Vlag |
|---|---:|---|---|---|
| `zweven` | 6 | 8 (lus) | dobbert 1 px, de sluier wiegt | op zijn baan |
| `aanloop` | 5 | 7 7 7 6 **3** (verlicht: 10 9 9 9 **3**) | de kern zwelt in 4 stappen, de spijlen gloeien rood mee, de sluier spreidt; frame 4: hij trekt zich 2 px op. Tegelijk `tell_duik` en de duiklijn op de landingsplek | `windup_progress` |
| `duik` | 2 | 4 4 | **het verste frame:** kern fel, sluier en snelheidsstrepen slepen omhoog; zijn lichaam is het vlak | ACTIVE (8), de code verschuift de node |
| `terug` | 4 | 10 × 4 | kern gedimd, sluier slap | RECOVER (40) |
| `stil` | 6 | 5 × 6 | flakkert: de kern gaat aan en uit, de kooi rammelt 1 px | VJ-04 (30) |
| `dood` | 8 | 6 × 8 | de kern flitst, de kooi springt in brokken uiteen en valt, alles dooft | levens 0 (voorstel 48) |

Tells (`*_tell_*`): `vroeg` (25 %), `laat` (75 %), beide vijandkern 4 met een gestippelde bovenlijn, en `actief` (vol, rand in kern 7): dezelfde tell-taal als de Gemaalmeester (§1.3). De sprite ligt boven de tell (z 0 tegen 1 mag ook: in het actieve frame moet de haak of het schot op het vlak zichtbaar zijn; in de renders staat de sprite bovenop).

### 2.4 Regels en metingen

- **Anticipation en het verste frame:** elke aanval heeft een aanloop in 4 stappen plus een uithaal van 3 ticks; het actieve frame reikt precies tot de verste rand van het vlak (haak x 28, schot x 32, duik = lichaam).
- **Waar, niet alleen dat** (deel 1 §4.3): de pose wijst de kant en de hoogte aan (haak boven de kop naar voren, schot naar achteren, kern zwelt boven de landingsplek) en de tell ligt precies op het vlak.
- **Bovenrand van 2 px** op de rug, de nek en de kop (en de kooi van het Dwaallicht), niet op elke stekel of rafel: zo is het één doorlopende lijn over de hele lengte (deel 1 §4.2 regel 4). De stekels zijn een tint lichter lijf.
- Vijandkleuren houden hun kleur in elke toestand; water en stoom volgen de toestand. Grijs en half = donkere wijk (rand en kern een tint feller, VJ-06), kleur = verlicht (S9). Geen amber of cyaan, geen rotatie, contour 1 px, 1 px rand per frame: **0 pixels op de rand van een cel** (gecontroleerd door de generator, 138 frames per toestand).

ΔL\* tegen de ring van 2–6 px rond de figuur, op elke plek uit combat §2.6 (scène-x, D = 60). Bovenrand p90; lijf mediaan; bible §6 regel 4 vraagt ≥ 40 op vulling of contour, deel 1 §4.2 ≥ 50 op de bovenrand:

| Kamer, plek | Grijs: bovenrand / lijf | Kleur: bovenrand / lijf |
|---|---|---|
| S2 E-paar 880 / 908 | **81,4 / 77,4** · 1,8 / 5,8 | 39,2 / **58,9** · **44,0** / 24,3 |
| S3 golf 1: 2140 / 2168 / 2360 | **80,2 / 79,1 / 79,1** | **69,9 / 60,1 / 62,2** |
| S3 golf 2: Schotdrager 1770, 1798, 1990 | **79,1 / 78,7 / 80,2** | **50,2 / 58,9 / 69,8** |
| S4 overkant 3260 | **78,5** | **52,1** |
| S6 K-paar 4340 / 4382 | **77,4 / 78,5** | 31,4 / 46,2 · lijf **51,8** / 37,0 |
| S7 Dwaallichten 5013 / 5067 | **86,0** | **85,7** |
| S8 adds bij de spuigaten (vóór de boss) | **82,7** | **81,7** |
| S9 E-paar 1060 / 1088 (verlicht) | **80,2** | **69,9** |
| S9 Dwaallicht 2310 (verlicht) | **80,2** | **69,9** |

In grijs, de toestand waarin S2–S8 gevochten worden, haalt de bovenrand overal ≥ 77; het donkere lijf leest daar niet (1–6), zoals deel 1 §4.2 verwacht. In kleur haalt hij ≥ 50 behalve S2 x 880 (39,2) en S6 (31,4 en 46,2): daar is de achtergrond licht en leest het lijf zelf (44,0 en 51,8 ≥ 40); alleen S6 x 4382 (46,2 / 37,0) haalt geen van beide. Die toestand komt in de slice niet voor (S2–S8 kleuren pas als het gemaal vol is, en dan keren de vijanden niet terug, combat §2.2); zie §2.6.

Tells: ΔL\* van het vlak met en zonder tell (gemiddeld) en van de gezette pixels (mediaan), vroeg / laat / actief:

| Tell, kamer | Grijs: gemiddeld | Grijs: gezette pixels | Kleur: gemiddeld |
|---|---|---|---|
| haak, S3 golf 2 | 11,3 / 28,3 / 45,5 | 42,2 / 38,1 / 38,3 | 6,0 / 15,1 / 26,8 |
| stoot, S3 golf 2 | 12,2 / 32,7 / 50,3 | 46,2 | 2,1 / 4,0 / 12,6 |
| haak, S6 | 10,8 / 28,0 / 44,4 | 41,5 / 38,1 / 42,2 | 2,7 / 3,4 / 12,2 |
| haak, S9 (verlicht) | 10,6 / 29,9 / 48,4 | 43,2 | 8,0 / 23,1 / 39,8 |
| duik, S7 | 12,2 / 32,7 / — | 45,1 | 12,0 / 32,1 |
| duik, S9 (verlicht) | 11,7 / 31,9 / — | 44,8 | 9,7 / 26,4 |

In grijs wordt elke tell per stap duidelijker en ligt elke gezette pixel 38–46 in L\* van de achtergrond: zonder kleur een gestippeld vlak dat dichter wordt (`vijanden_leesbaarheid_x2.png`, ook bij deuteranopie: rood tegen grijs blijft een verschil in licht). In kleur is het vlak in S3 (vóór de rode luifel van kraam 1) en in S6 (vóór de lichte gevel) zwak; in S9, de enige verlichte kamer met vijanden, haalt het 23–40.

### 2.5 Overdracht aan de TA en de GP

1. Vervang `_ensure_visual`/`_update_visual` (de placeholder-polygons) door een `Sprite2D` met `region_rect` uit het manifest, op `offset` (of `offset_links` met `flip_h` als `facing < 0`). Grijs in S2–S8, kleur in S9 (zoals de wijk).
2. De tell op `_walker_box()` (lopers) of op de landingsplek (Dwaallicht), frame op `windup_progress`; `actief` op `is_attack_active()`. Het lichaam kiest zijn aanloopframe op `windup_progress`, met de uithaal op de laatste 3 ticks.
3. De Schotdrager: na `break_armor()` `breuk`, dan de `gebroken_*`-rijen, en `stuk` als losse sprite op die plek.
4. `dood` (48 ticks) en `uit_stoom` (30) zijn nieuw voor de code: `dood` kan na het verwijderen spelen als los effect; `uit_stoom` valt samen met `add_inactief`.
5. De `.import`-bestanden zijn gecommit in het formaat van de Gemaalmeester (Lossless, mipmaps uit), met een vaste uid per bestand. **Nog niet in de engine geïmporteerd:** de import- en CI-controle moet nog draaien (hier geen Godot, Actions staat stil).

### 2.6 Open punten

- **Koppeling** (§2.5): TA met GP, daarna een SM-review (code in `game/`).
- **Duur van `dood`** (48 ticks) is een voorstel; combat §9.1 noemt geen tijd. De Combat Designer beslist of de vijand tijdens het oplossen nog in de weg staat (voorstel: nee, geen hurtbox).
- **Kleur in S2–S8:** S6 x 4382 haalt in kleur geen 40 op rand of lijf, en de tells in kleur zijn in S3 en S6 zwak. Alleen relevant als er vijanden in een verlichte S2–S8 komen; dan stel ik de AD voor de bovenrand in kleur op kern 6 te zetten in plaats van 4.
- **PR #270** (AD) wijzigt de generator van de kamers: na de merge meet ik opnieuw (de generator leest de kamers, dus één run).
- **Ware Deck-test** van de tells (bible §10): TA bij de eerste Deck-build.
- **Audio** (T8d): de tick-lijsten in de manifests zijn de tels voor het schraapgeluid, de tink, de breuk en de stijgende toon.

## 3. Wijzigingen

| Versie | Wat |
|---|---|
| 0.2 | §2: de slice-vijanden Kadeloper, Schotdrager en Dwaallicht op eindkwaliteit (S-13), [#272](https://github.com/cesarvangerwen-glitch/echoborn/issues/272). |
| 0.1.1 | Lead-review AD op PR #266: de vroege tell in vijandkern 4 (verschil met laat alleen in dichtheid), opnieuw gemeten (§1.5); de eis van 1 px transparante rand per frame voor de echo-contour van de TA (#267), in de generator en in §1.2 en §1.4. |
| 0.1 | Eerste versie: de Gemaalmeester (S-14), [#265](https://github.com/cesarvangerwen-glitch/echoborn/issues/265). |
