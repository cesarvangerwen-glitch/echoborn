# Animatie-timing

Versie 0.1 · Eigenaar: Animator · Issue [#265](https://github.com/cesarvangerwen-glitch/echoborn/issues/265) (assetlijst S-14) · Hoort bij `docs/art/bible.md` v0, `docs/art/slice-kadewijk.md` v0.5 (§4, §12) en `docs/design/gemaalmeester.md` v0.2.3

Frames per animatie en per aanvalsfase. Tijden in **ticks** (60 per seconde, dus frames bij 60 fps). De bron van elke tijd is `game/data/vijanden/slice.csv`; de generator leest die, dus een nieuwe waarde in data geeft na een nieuwe run nieuwe tick-lijsten in het manifest. Dit document bevat nu de Gemaalmeester. Spelers, echo en vijanden volgen in eigen secties.

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

| Blad | Cel | Plaatsing (`offset` = linksboven, node-coördinaten) | z |
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

### 1.5 Metingen (`genereer_gemaalmeester.py`, S8 bij D = 60)

ΔL\* tegen de directe achtergrond (ring van 2–6 px), zoals bible §7.3 en deel 1 §4.2:

| | Grijs | Kleur | Norm |
|---|---:|---:|---|
| Bovenrand van het lichaam (p90) | **82,5** | **76,9** | ≥ 50 ✓ |
| Lijf van het lichaam (mediaan) | 2,9 | 2,7 | — (een vijand leest op bovenrand en kern, deel 1 §4.2) |
| Bovenrand van het rad, op x 94 en x 506 | **74,2** | **71,9** | ≥ 50 ✓ |
| Velg van het rad (hout, mediaan) | 13,0 | 10,7 | — |
| Kern open tegen het schot, op dezelfde plek (p90) | 27,1 | 15,2 | leesbaar zonder kleur (grijs) ✓ |

Tells: ΔL\* van het vlak met en zonder tell (gemiddeld over het vlak):

| Tell | Grijs vroeg / laat / actief | Kleur vroeg / laat / actief |
|---|---|---|
| Pompslag (fase 1 links, vóór de plint en de wand) | 4,8 / **20,0** / **31,8** | 3,9 / 17,4 / 28,6 |
| Schoepenzwiep (links, vóór het tegenlicht van het raam) | 6,6 / **24,7** / **37,0** | 5,9 / 22,5 / 34,1 |

De tell wordt in luminantie elke stap duidelijker. De vroege stap (25 %, vijandkern 3) is bewust zacht en leest vooral op kleur: in een grijze hal is het het enige rood. De late stap en het actieve vlak zijn ook zonder kleur te lezen (`s8_gemaalmeester_leesbaarheid_x2.png`).

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
- **De vroege tell (25 %)** leest in luminantie zwak (ΔL\* 4–7). Dat volgt de tell-taal van deel 1 §4.3. Wil de AD of de Combat Designer dat ook de vroege stap zonder kleur leest, dan wordt het vijandkern 4 op 25 %. Dat is één regel in de generator.
- **De gedeelde echo van de finisher** (S-15) is van de TA met de AD. De boss speelt in die 120 ticks `wankel` en bij elke finisherslag `geraakt`.
- **Audio** (T8d): de frames volgen de tels van §9.3 van combat (sissende zuiger in de aanloop, de tink, de breuk, het ratelen van het rad). De Audio Director kan de tick-lijsten uit het manifest gebruiken.
- **Ware Deck-test** van de boss en de tells (bible §10): TA bij de eerste Deck-build.

## 2. Wijzigingen

| Versie | Wat |
|---|---|
| 0.1 | Eerste versie: de Gemaalmeester (S-14), [#265](https://github.com/cesarvangerwen-glitch/echoborn/issues/265). |
