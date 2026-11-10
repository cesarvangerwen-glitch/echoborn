# Performance flow-kamer: Steam Deck-build (T7)

Eigenaar: Engine & Platform Programmer · Versie 1 · Issue: [#79](https://github.com/cesarvangerwen-glitch/echoborn/issues/79)
Gebaseerd op `docs/productie/fase-2-kader.md` §2 (T7), §3 (F5), §5; besluit #18 (2D, 640×400 op de Deck), besluit #51 (flow-kamer, co-op), randvoorwaarde "Steam Deck verified als doel" (#2); `docs/tech/lichtmeting.md` (lichtbudget, #21); `docs/tech/setup.md`.

---

## 1. Samenvatting

**Gemeten (llvmpipe, géén Deck):**
- De Deck-build rendert nu de wereld op **640×400** en schaalt die ×2 op naar het scherm van 1280×800 (§3). De camera kiest zelf zoom 1 (640×400) of 2 (1280×800); gemeten in de build: feature `deck` actief, venster 1280×800, render 640×400, zoom 1. Een export (`.pck`) start en speelt de flow-kamer 300 frames zonder fouten.
- De flow-kamer zelf (grijs, geen 2D-licht) kost op llvmpipe **±3,7–7 ms GPU op 640×400** (mediaan 4,7) en **±11,2 ms op 1280×800**, met 16–22 draw calls per frame en ±32,5 MB geheugen.
- Met het lichtbudget van de Technical Artist erbij kost het licht op 640×400 **mediaan ±24 ms (20 LE, "verlichte wijk"; 20–40 ms) en ±40 ms (30 LE, piek; 30–57 ms)**. De laagste runs (20,5 en 29,8 ms) liggen dicht bij de vorige meting (19,9 en 25,6 ms); de spreiding komt van de gedeelde machine (§4.3). Op native 1280×800 is het licht **±3× duurder**.

**Aanname (niet gemeten):** of de Deck dit haalt, hangt af van hoeveel sneller zijn GPU is dan llvmpipe. Het licht past in de 3 ms van de TA als de Deck op 640×400 **≥ ±8× (20 LE) en ≥ ±13× (30 LE) sneller** is (beste runs: 6,8× en 9,9×); op native moet dat **≥ 25–39×** zijn. De TA schat de Deck op 10–30× (`lichtmeting.md` §5.3). Het normale budget past dus naar verwachting; het piekbudget zit aan de onderkant van die schatting krap. Alleen een meting op een echte Deck (§6) beslist dit.

## 2. De Deck-build

| Instelling | Waarde | Waar | Waarom |
|---|---|---|---|
| Platform | Linux x86_64 (SteamOS is Linux; geen Proton nodig) | `export_presets.cfg`, preset `Steam Deck (Linux)` | Native draait zonder vertaallaag |
| Feature | `deck` (custom feature) | idem | De Deck-instellingen hieronder gelden alleen in deze export; editor, tests en CI veranderen niet |
| Venster | 1280×800 (16:10), schermvullend (`mode.deck=3`) | `project.godot`, `display/window/size/window_*_override.deck`, `mode.deck` | Deck-scherm; besluit #18 |
| Render | wereld op 640×400, ×2 opgeschaald (`viewport_*.deck=640/400`, `stretch/mode.deck="viewport"`) | `project.godot`, `display/window/size/viewport_*.deck`, `display/window/stretch/mode.deck` | Lichtbudget van #21 gaat uit van 640×400; besluit #18 (§3) |
| Vsync | aan (`vsync_mode.deck=1`) | `project.godot` | Deck-scherm is 60 Hz; geen tearing |
| Renderer | `gl_compatibility` (OpenGL 3.3) | `project.godot` (al zo) | Het lichtbudget van #21 is met deze renderer gemeten. Vulkan (Forward+/Mobile) is niet gemeten |
| Texturen | S3TC/BPTC (desktop) | preset | Deck-GPU is desktop-RDNA 2 |
| Inhoud | alles behalve `tests/*`; `tools/perf/` en `prototypes/lichtmeting/` zitten erin | preset | Zodat de meting van §6 in de build zelf draait |
| Uitvoer | `builds/deck/polderlight.x86_64` (+ `.pck`) | preset; `/builds/` staat in `.gitignore` | Nooit builds committen |

**Exporteren** (vanuit de repo-root, Godot 4.6.3 uit `setup.md` §2):

```bash
# Alleen de pck (geen export templates nodig); draait met de officiële 4.6.3-binary
godot --headless --path game --export-pack "Steam Deck (Linux)" ../builds/deck/polderlight.pck

# Volledige build (export templates 4.6.3 nodig: Editor → Export templates, of de .tpz uit de release)
godot --headless --path game --export-release "Steam Deck (Linux)" ../builds/deck/polderlight.x86_64
```

De pck start met `godot --main-pack builds/deck/polderlight.pck`. Dat is dezelfde runtime als de volledige build (de templates zijn dezelfde 4.6.3-engine zonder editor). Een volledige `.x86_64`-build is in deze werkomgeving niet gemaakt (geen templates; §7).

## 3. Resolutie: 640×400 met een camera die meeschaalt

Besluit #18 en de TA (`lichtmeting.md` §5.2: "wereld op 640×400 renderen en ×2 opschalen") gaan uit van een wereld die op 640×400 rendert. De Deck-build doet dat nu met deze instellingen in `game/project.godot`, sectie `[display]`; ze gelden alleen met de feature `deck`:

| Instelling | Waarde | Doel |
|---|---|---|
| `window/size/viewport_width.deck` / `viewport_height.deck` | 640 / 400 | Basisgrootte: de wereld rendert op 640×400 |
| `window/stretch/mode.deck` | `"viewport"` | Render op de basisgrootte, daarna opschalen naar het venster |
| `window/size/window_width_override.deck` / `window_height_override.deck` | 1280 / 800 | Venster blijft 1280×800 (Deck-scherm), niet 640×400 |
| `window/size/mode.deck` | 3 (schermvullend) | Ongewijzigd |
| `window/vsync/vsync_mode.deck` | 1 (aan) | Ongewijzigd |

`game/tests/test_deck_settings.gd` controleert deze waarden; zet iemand ze terug, dan wordt CI rood. Stretch-aspect blijft de standaard `keep`; 1280×800 is precies 2× 640×400, dus geen zwarte randen en gelijke pixels.

De camera van de flow-kamer leidt zijn zoom af van de rendergrootte (`FlowRoom.camera_zoom`, [#120](https://github.com/cesarvangerwen-glitch/echoborn/issues/120)): 640×400 → zoom 1, 1280×720 en 1280×800 → zoom 2. Het beeld is in beide gevallen hetzelfde (640×360 wereldpixels plus 20 px boven en onder op 16:10). Gemeten:

| Opstelling | Venster | Render | Camerazoom |
|---|---|---|---|
| Deck-build (`--main-pack`, `--res=project`) | 1280×800 | 640×400 | 1,000 |
| Editorproject, `--res=640` | 1280×800 | 640×400 | 1,000 |
| Editorproject, `--res=native` | 1280×800 | 1280×800 | 2,000 |

Editor, pc-build, tests en CI veranderen niet: zonder feature `deck` blijft het 1280×720 zonder stretch.

**Gevolg:** ook de HUD rendert nu op 640×400 en wordt ×2 opgeschaald. Of de UI in een eigen laag native moet blijven, is open punt 4 van `lichtmeting.md` (UI scherp houden); zie §7.

## 4. Meting

### 4.1 Opzet

Script: `game/tools/perf/deck_meting.gd` + `.tscn`. Meetscript, geen gamecode; de flow-kamer en haar scripts blijven ongewijzigd. Het script zet de camerazoom niet meer zelf: de kamer kiest hem uit de rendergrootte (§3). Per scenario print het de render en de zoom bij start en eind; ze staan ook in de CSV (`zoom_start`, `zoom_eind`).

- Per scenario laadt het `levels/flowkamer/flowkamer.tscn` opnieuw en laat de gescripte run (`flow_bot.gd`) spelen, met echo en HUD. 120 opwarmframes, 300 meetframes, vsync uit, geen fps-limiet.
- Het meet de frametijd (gem., p50, p95, max), de render-tijd van Godot op CPU en GPU (`viewport_get_measured_render_time_*`), draw calls en objecten per frame (`Performance`), geheugen en laadtijd.
- Het lichtbudget komt tijdens de meting bovenop de kamer, volgens `lichtmeting.md` §5: `CanvasModulate` grijs-donker, een lichtset die de camera volgt (dus altijd op het scherm), een `LightOccluder2D` op elk blok van de kamer (41) en een saturatiepass over het hele scherm.

| Scenario | Wat | LE (§5.1 van #21) |
|---|---|---:|
| grijs | flow-kamer zoals hij is: geen 2D-licht | 0 |
| wijk20 | "verlichte wijk": 3 schaduwlichten 384 px, 1 licht 192 px, 41 occluders, saturatiepass | ±20 (normaal budget) |
| piek30 | 8 schaduwlichten 192 px, 41 occluders, saturatiepass | ±30 (piekbudget) |
| grijs-eind | gelijk aan grijs, controle op drift | 0 |

Draaien:

```bash
xvfb-run -a -s "-screen 0 1280x800x24" godot --path game --resolution 1280x800 --audio-driver Dummy \
  res://tools/perf/deck_meting.tscn -- --res=native      # of --res=640 / --res=project; ook --frames=, --warmup=, --only=
```

| `--res=` | Render | Gebruik |
|---|---|---|
| `native` (standaard) | venstergrootte, stretch uit; ook in de Deck-build | D1, en native ter vergelijking |
| `640` | 640×400, stretch `viewport` | D2–D4 in het editorproject |
| `project` | wat `project.godot` zegt; in de Deck-build 640×400 | Controle dat de Deck-build zelf 640×400 rendert |

De tabel komt op stdout, een CSV in `user://deck_meting_<res>.csv` (pad wordt geprint). Duur op llvmpipe: ±1 min per modus. `--headless` werkt niet: dan rendert Godot niets.

### 4.2 Resultaten (llvmpipe, géén Deck)

**Opstelling:** Godot 4.6.3-stable official, `gl_compatibility`, Mesa 25.2.8 llvmpipe (LLVM 20.1.2), 2 vCPU, Xvfb 1280×800, camera met zoom uit de rendergrootte (§3). Op 640×400 zes runs (vijf in het editorproject met `--res=640`, één in de Deck-build met `--res=project`), native drie runs. Tabel = **mediaan (laagste–hoogste)**. Lichtkosten = GPU van het scenario min GPU van grijs-eind **in dezelfde run**, daarna de mediaan. De machine werd gedeeld met andere processen; de spreiding is daarom groot (§4.3).

| Modus | Scenario | Frame p95 ms | CPU-render ms | GPU ms | Lichtkosten GPU ms | Draw calls max |
|---|---|---:|---:|---:|---:|---:|
| 640×400 | grijs-eind | 16,4 (10,2–24,0) | 2,7 (2,3–2,9) | 4,7 (3,7–7,0) | 0 | 22 |
| 640×400 | wijk20 | 47 (38–65) | 26,2 (25,0–39,6) | 27,8 (26,5–43,5) | **23,9 (20,5–39,5)** | 19 |
| 640×400 | piek30 | 82 (47–113) | 42,0 (32,2–58,8) | 44,6 (33,7–63,7) | **39,6 (29,8–56,7)** | 19 |
| native 1280×800 | grijs-eind | 18,6 (18,2–22,3) | 5,3 (5,1–5,5) | 11,2 (11,2–11,4) | 0 | 22 |
| native 1280×800 | wijk20 | 112 (108–193) | 80,7 (80,2–117,1) | 86,9 (86,1–126,8) | **75,8 (74,7–115,6)** | 36 |
| native 1280×800 | piek30 | 236 (149–252) | 121,8 (106,8–154,6) | 128,9 (112,8–164,3) | **117,7 (101,6–152,9)** | 36 |

| Overig | Waarde |
|---|---|
| Geheugen (statisch) | 32,5 MB (640×400) · 32,6 MB (native) |
| Videogeheugen | 14,9 MB (640×400) · 24,6 MB (native) |
| Laden flow-kamer | 100–175 ms de eerste keer (scripts compileren), daarna 10–30 ms |
| Deck-build via `--main-pack` | feature `deck` actief, venster 1280×800, render 640×400, zoom 1; als hoofdscène 300 frames zonder fouten (exitcode 0) |

**Vergelijking met versie 0** (camera met vaste zoom 2; de meting zette de zoom zelf op 1): de laagste runs nu (wijk20 20,5 ms, piek30 29,8 ms, grijs 3,7 ms) liggen dicht bij de toen gemeten 19,9, 25,6 en 3,5 ms. De camerazoom uit de rendergrootte geeft hetzelfde beeld en dus dezelfde kosten; het hogere mediaan komt van de drukkere machine.

### 4.3 Wat de cijfers zeggen

| Vraag | Antwoord |
|---|---|
| Rendert de Deck-build op 640×400? | Ja, gemeten in de build zelf (§3). Daarmee geldt het lichtbudget van #21 voor wat de speler ziet. |
| Is de flow-kamer zelf zwaar? | Nee. Zonder licht 3,7–7 ms GPU op llvmpipe (640×400) en ≤ 22 draw calls. Op een GPU verwacht ik ruim onder 1 ms (aanname). |
| Waarom zo'n spreiding? | Twee oorzaken. (1) De machine was gedeeld: in dezelfde run wisselen grijs en grijs-eind tot ×1,7. (2) De bot speelt per scenario een iets andere stuk kamer (eindtick verschilt per run, draw calls 17 of 20–21), dus een ander deel van het scherm is verlicht. De laagste run is de beste schatting van een rustige machine; de mediaan is de voorzichtige. |
| Klopt de rekenregel van #21 in een echte kamer? | De laagste runs geven ±1,3–1,4× de voorspelling (15 en 22,5 ms), de mediaan ±1,6–1,8×. Hij schat in deze kamer dus te laag. Niet uitgezocht (§7 punt 5). |
| Native of 640×400? | Native kost het licht **±3,0–3,2×** zoveel (TA: 3,1–3,3×). 640×400 is op de Deck nodig om het budget te halen; de build doet dat nu. |
| CPU-render ≈ GPU | Op llvmpipe rendert de CPU zelf; die CPU-tijd zegt niets over de Deck. Op de Deck moet `cpu_ms` klein blijven (D4). |

### 4.4 D1–D4 op llvmpipe en omrekening naar de Deck (aanname)

De drempels D1–D4 (§6.3) gelden voor een echte Deck. Op llvmpipe zeggen ze alleen iets via de omrekening; ik noteer de waarden zodat de Deck-meting ze direct kan naast elkaar leggen.

| # | Drempel (Deck) | llvmpipe, mediaan (laagste) | Nodige versnelling Deck t.o.v. llvmpipe |
|---|---|---|---:|
| D1 | grijs-eind native: p95 ≤ 16,7 ms en GPU ≤ 4 ms | p95 18,6 (18,2) ms, GPU 11,2 ms | GPU ±2,8× |
| D2 | lichtkosten wijk20 op 640×400 ≤ 3 ms | 23,9 (20,5) ms | **±8,0× (6,8×)** |
| D3 | wijk20 en piek30 op 640×400: p95 ≤ 16,7 ms | 47 / 82 (38 / 47) ms | ±2,8× / ±4,9× (2,3× / 2,8×) op de hele frame |
| D4 | CPU-render ≤ 4 ms, alle scenario's | 2,7 (grijs) tot 42 (piek30) ms | n.v.t.: op llvmpipe rendert de CPU zelf |

Piekbudget (30 LE, geen eigen drempel, wel het budget van de TA): 39,6 (29,8) ms → **±13× (9,9×)** nodig.

**Aanname, niet gemeten:** de Deck-GPU is 10–30× sneller dan deze llvmpipe (TA, `lichtmeting.md` §5.3). Dan haalt de Deck D1–D3 op 640×400 voor het normale budget (20 LE) met een marge van ±1,3–3,8× (laagste runs: 1,5–4,4×). Het piekbudget (30 LE) past bij 10× niet volgens de mediaan (±4 ms) en net wel volgens de laagste run. Op native zou ook het normale budget niet passen. D4 is op llvmpipe niet te beoordelen. Alleen de meting op een echte Deck (§6) beslist dit.

## 5. Werkaanname (kader §5)

| Werkaanname | Bron |
|---|---|
| Drempels D1–D8 en 3 ms GPU voor licht (20/30 LE) | Besluit TD bij de review |
| Minimumspecificatie = Steam Deck (LCD, 1280×800, 60 Hz) | Randvoorwaarde "Steam Deck verified als doel" (#2); besluit #18 |
| Godot 4.6.3-stable, `gl_compatibility` | `setup.md` §1; lichtbudget #21 is met deze renderer gemeten |
| Licht ≤ 3 ms GPU per frame; normaal 20 LE, piek 30 LE | Voorstel TA, `lichtmeting.md` §5; akkoord TD |
| Deck-GPU 10–30× sneller dan llvmpipe op 2 Xeon-kernen | Schatting TA, `lichtmeting.md` §5.3; niet gemeten |
| Linux-native build (geen Windows-build via Proton) op de Deck | Engine & Platform Programmer; Proton is niet getest |
| Deck-build rendert de wereld op 640×400 en schaalt ×2 op; de HUD schaalt mee | §3; besluit #18, `lichtmeting.md` §5.2 |
| "Draait op Deck-specificaties" = de drempels van §6.3 | Akkoord TD |

## 6. Meetprotocol voor een echte Steam Deck

Voor de CEO of een tester met een Deck. Duur ±30 min.

### 6.1 Voorbereiden

1. Deck volledig geladen en **aan de lader**, SteamOS bijgewerkt. Noteer model (LCD/OLED) en SteamOS-versie (Instellingen → Systeem).
2. Desktopmodus, Konsole. Installeer Godot **4.6.3** zoals `setup.md` §2 (checksum moet OK geven) en `git clone` de repo. Noteer de commit-hash (`git rev-parse HEAD`).
3. Maak de build: `godot --headless --path game --export-pack "Steam Deck (Linux)" ../builds/deck/polderlight.pck`.
4. Sluit andere programma's; laat de Deck 5 min rusten.

### 6.2 Meten

**Run A: meetscript (Desktopmodus), 3×:**

```bash
cd echoborn
for m in native project; do for i in 1 2 3; do
  godot --main-pack builds/deck/polderlight.pck --audio-driver Dummy \
    res://tools/perf/deck_meting.tscn -- --res=$m --frames=600 2>&1 | tee deck_${m}_$i.txt
done; done
```

Run A gebruikt hier 600 meetframes, de meting op llvmpipe (§4.2) 300. Op de Deck kost dat weinig tijd en geeft het een stabielere p95; vergelijk met §4.2 op gemiddelde en p95, niet op max (meer frames geeft eerder een hogere max).

5. Controleer in de kop: `adapter` is AMD/radeonsi (niet llvmpipe), `features deck: true`, venster 1280×800, render 1280×800 (native) of 640×400 (project). Controleer per scenario de zoom: 2,000 (native) of 1,000 (project). Is `GPU ms` overal 0 (timer niet beschikbaar), gebruik dan `frame gem ms`.
6. Lichtmeting van de TA erbij: `lichtmeting.md` §6.2 (zelfde Deck, zelfde sessie).

**Run B: spelen (Gamemodus):**

7. Voeg `godot` toe als niet-Steam-game met startopties `--main-pack /home/deck/echoborn/builds/deck/polderlight.pck`. Start in Gamemodus.
8. Snelmenu (…) → Prestaties: overlay niveau 4, framelimiet 60. Speel de flow-kamer 10 min (K1 → K2 → K3 → gemaal), solo met de ingebouwde knoppen, en 2 min met een tweede controller (P2 erbij via Start).
9. Noteer: fps, frametijd (grafiek vlak of pieken), GPU-klok, verbruik (W), temperatuur. Foto of screenshot van de overlay in K2 tijdens een golf.
10. **Co-op oplossen en terugkomen:** laat P2 in K2 meedoen (Start), houd Select 1 s vast zodat P2 oplost, en laat P2 meteen weer meedoen. Doe dat 3×. Noteer per keer de hoogste frametijd in de overlay rond het oplossen en terugkomen (verwacht: een piek door ± 800 shape-queries van `Sim.placement`).
11. Herhaal stap 8 kort (2 min) met **TDP-limiet 8 W** (batterijsituatie).

### 6.3 Drempels: wanneer geslaagd

| # | Meting | Geslaagd als |
|---|---|---|
| D1 | Run A, grijs-eind, native | frame p95 ≤ 16,7 ms en GPU ≤ 4 ms |
| D2 | Run A, wijk20 − grijs-eind (lichtkosten GPU) | ≤ 3 ms op 640×400 (`project`; budget TA). Op native: noteren; > 3 ms bevestigt dat §3 nodig is |
| D3 | Run A, wijk20 en piek30, 640×400 (`project`) | frame p95 ≤ 16,7 ms |
| D4 | Run A, `CPU-render ms` (alle scenario's) | ≤ 4 ms (anders is de saturatiepass of het licht een CPU-probleem, zie `lichtmeting.md` §7 punt 5) |
| D5 | Run B, 10 min spelen, en de co-opstap (stap 10) | 60 fps gehouden; geen frametijd > 33 ms behalve bij het laden, ook niet bij P2 oplossen of terugkomen; geen crash |
| D6 | Run B, TDP 8 W | 60 fps gehouden in de grijze kamer |
| D7 | Run B, input | ingebouwde knoppen werken als P1 zonder configuratie; een tweede controller kan meedoen |
| D8 | Run A, laadtijd en geheugen | laden ≤ 1 s, geheugen ≤ 1 GB |

**Omrekenen als D2 faalt:** Deck-ms per LE = (GPU wijk20 − GPU grijs-eind) / 20. Het lichtbudget in LE wordt dan 3 ms / Deck-ms per LE (rekenwijze van `lichtmeting.md` §6.3).

### 6.4 Opleveren

12. Zet in issue #79 (of een vervolgissue): de 6 uitvoerbestanden `deck_*.txt`, de CSV's (`~/.local/share/godot/app_userdata/Echoborn/deck_meting_*.csv`), de overlayfoto's, Deck-model, SteamOS-versie, commit-hash, en per drempel D1–D8 geslaagd/niet.

## 7. Open punten

| # | Punt | Wie |
|---|---|---|
| 1 | **Echte Deck-meting** volgens §6. Geen Deck in de agent-omgeving. | CEO of tester met een Deck; Engine & Platform Programmer verwerkt |
| 3 | Herhalen op de slice (T8a), zodra die er is: zelfde script, met `FLOW_SCENE` naar de slice-scène. | Engine & Platform Programmer |
| 5 | Waarom de rekenregel van #21 hier te laag schat: ±1,3–1,4× (laagste runs) en ±1,6–1,8× (mediaan) (§4.3). | Technical Artist |
| 6 | Volledige `.x86_64`-build met export templates 4.6.3 (en later een buildscript in CI). Niet gemaakt: geen templates in deze omgeving. | Engine & Platform Programmer (met Tools Programmer voor CI) |
| 7 | Niet gemeten: Vulkan-renderers, Windows-build via Proton, Deck OLED (90 Hz), Steam Input-integratie. | Engine & Platform Programmer |
| 8 | Release-preset maken die `tools/perf/` en `prototypes/lichtmeting/` uitsluit (de Deck-preset houdt ze voor de meting). | Engine & Platform Programmer |
| 9 | Fullscreen-modus 3 (`mode.deck=3`) houden; exclusieve fullscreen (modus 4) is niet getest. | Engine & Platform Programmer |
| 10 | Geen CI-rooktest voor de export (`--export-pack`) of voor `tools/perf/deck_meting.gd` (de testrunner laadt `tools/` niet). `test_deck_settings.gd` leest alleen `project.godot`: verdwijnt `custom_features="deck"` uit de exportpreset, dan blijft CI groen; een CI-rooktest op de export vangt dat. | Engine & Platform Programmer (met Tools Programmer) |
| 11 | D5 sluit laden uit van de 33 ms-grens, maar hapers door shadercompilatie bij het eerste licht zijn reëel; apart noteren en een eigen drempel bepalen. | Engine & Platform Programmer (met Technical Artist) |
| 12 | Run B speelt de kamer zonder 2D-licht; verlicht wordt alleen via het meetscript (run A) gemeten. | Engine & Platform Programmer |
| 13 | De omrekenfactor 10–30× en de metingen hier rusten op één gedeelde 2-vCPU-machine, met spreiding tot ×1,7 tussen runs (§4.3). Een rustige machine of meer runs per modus geeft een scherpere factor; de Deck-meting maakt dit overbodig. | Engine & Platform Programmer (met Technical Artist) |
| 14 | **16:10 (C-07), besluit TD: geen blokkade.** De leiband blijft 16:9 (`leash_view_px`) voor pc én Deck, zodat sim, echo en replays op dezelfde tick oplossen; geen aparte Deck-waarde. Op 640×400 toont de camera per rand 20–30 wereldpx extra; UX beslist alleen of die band gedimd wordt. | UX Designer |
| 15 | Zoom-uit op 640×400 geeft een niet-gehele schaal (bv. 0,667), dus ongelijke pixels; zichtbaarder dan bij een render van 1280. Vaste zoomtrappen of niet. Ook een venster kleiner dan 640×360 geeft ongelijke pixels (zoom < 1). | Technical Artist en UX Designer |
| 16 | De HUD rendert op de Deck nu ook op 640×400 (×2 opgeschaald). Tekst kan grof ogen; of de UI in een eigen native laag moet, beslist open punt 4 van `lichtmeting.md`. | Technical Artist en UI Artist |
| 17 | Piekbudget 30 LE vraagt een Deck die ±13× sneller is dan llvmpipe (§4.4); haalt de Deck dat niet, dan beslist de Technical Artist over verlagen. | Technical Artist |

Punten 2 (camera en `.deck`-instellingen, §3) en 4 (besluit TD over D1–D8 en 3 ms, §5) zijn afgehandeld en vervallen; de nummers van de andere punten blijven gelijk, zodat verwijzingen kloppen.
