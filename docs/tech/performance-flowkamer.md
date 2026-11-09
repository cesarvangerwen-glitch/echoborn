# Performance flow-kamer: Steam Deck-build (T7)

Eigenaar: Engine & Platform Programmer · Versie 0 · Issue: [#79](https://github.com/cesarvangerwen-glitch/echoborn/issues/79)
Gebaseerd op `docs/productie/fase-2-kader.md` §2 (T7), §3 (F5), §5; besluit #18 (2D, 640×400 op de Deck), besluit #51 (flow-kamer, co-op), randvoorwaarde "Steam Deck verified als doel" (#2); `docs/tech/lichtmeting.md` (lichtbudget, #21); `docs/tech/setup.md`.

---

## 1. Samenvatting

**Gemeten (llvmpipe, géén Deck):**
- De Deck-build bestaat: preset `Steam Deck (Linux)` in `game/export_presets.cfg`, met de feature `deck` (1280×800, schermvullend, vsync aan). Een export (`.pck`) start, zet de Deck-instellingen en speelt de flow-kamer 300 frames zonder fouten.
- De flow-kamer zoals hij nu is (grijs, geen 2D-licht) kost op llvmpipe **±3,5 ms GPU op 640×400** en **±10,8 ms op 1280×800**, met 16–22 draw calls per frame en ±32 MB geheugen.
- Met het lichtbudget van de Technical Artist erbij kost het licht in de flow-kamer **±20 ms (20 LE, "verlichte wijk") en ±26 ms (30 LE, piek) op 640×400**. Dat is **±1,3× (wijk20) en ±1,14× (piek30) meer** dan de rekenregel uit `lichtmeting.md` §5 voorspelt (15 en 22,5 ms). Op native 1280×800 is het licht nog eens **±3,3–4,6× duurder**.

**Knelpunt (gemeten):** de build rendert nu op **native 1280×800**, niet op 640×400. De camera van de flow-kamer heeft een vaste zoom 2 voor een venster van 1280×720; met de wereld op 640×400 zou je maar 320×200 wereldpixels zien (§3). Het lichtbudget van #21 gaat uit van 640×400.

**Aanname (niet gemeten):** of de Deck dit haalt, hangt af van hoeveel sneller zijn GPU is dan llvmpipe. Het licht past in de 3 ms van de TA als de Deck **≥ 6,6× (20 LE) en ≥ 8,5× (30 LE) sneller** is op 640×400; op native 1280×800 moet dat **≥ 22–30×** zijn. De TA schat de Deck op 10–30× (`lichtmeting.md` §5.3). Op 640×400 is er dus naar verwachting marge, op native niet. Alleen een meting op een echte Deck (§6) beslist dit.

## 2. De Deck-build

| Instelling | Waarde | Waar | Waarom |
|---|---|---|---|
| Platform | Linux x86_64 (SteamOS is Linux; geen Proton nodig) | `export_presets.cfg`, preset `Steam Deck (Linux)` | Native draait zonder vertaallaag |
| Feature | `deck` (custom feature) | idem | De Deck-instellingen hieronder gelden alleen in deze export; editor, tests en CI veranderen niet |
| Venster | 1280×800 (16:10), schermvullend (`mode.deck=3`) | `project.godot`, `display/window/size/*.deck` | Deck-scherm; besluit #18 |
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

## 3. Resolutie: 640×400 vraagt een camera die meeschaalt

Besluit #18 en de TA (`lichtmeting.md` §5.2: "wereld op 640×400 renderen en ×2 opschalen") gaan uit van een wereld die op 640×400 rendert. Godot doet dat met `display/window/stretch/mode = "viewport"` en een basisgrootte van 640×400. Gemeten in een testproject:

| Instelling | Render | Wereld in beeld met camerazoom 2 |
|---|---|---|
| basis 1280×800, geen stretch (de build nu) | 1280×800 | 640×400 ✔ |
| basis 640×400, stretch `viewport` | 640×400 | 320×200 ✘ (alles 2× te groot) |

De flow-kamer zet zijn camera op zoom 2 (`flow_room.gd`, "640 × 360 wereldpixels in het venster van 1280 × 720"). Daarom rendert de Deck-build nu native. Voor 640×400 moet de zoom de rendergrootte volgen (zoom 1 bij 640×400). Dat is een wijziging in de scène en dus niet van mij; de meting in §4 doet dat alleen tijdens de meting (`--res=640`). Zodra de camera meeschaalt, komen in `project.godot` erbij: `window/size/viewport_width.deck=640`, `viewport_height.deck=400`, `window_width_override.deck=1280`, `window_height_override.deck=800`, `window/stretch/mode.deck="viewport"`. Open punt 4 van `lichtmeting.md` (UI scherp houden) beslist of de UI dan in een eigen laag native blijft.

## 4. Meting

### 4.1 Opzet

Script: `game/tools/perf/deck_meting.gd` + `.tscn`. Meetscript, geen gamecode; de flow-kamer en haar scripts blijven ongewijzigd.

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
  res://tools/perf/deck_meting.tscn -- --res=native      # of --res=640; ook --frames=, --warmup=, --only=
```

De tabel komt op stdout, een CSV in `user://deck_meting_<res>.csv` (pad wordt geprint). Duur op llvmpipe: ±1 min per modus. `--headless` werkt niet: dan rendert Godot niets.

### 4.2 Resultaten (llvmpipe, géén Deck)

**Opstelling:** Godot 4.6.3-stable official, `gl_compatibility`, Mesa 25.2.8 llvmpipe (LLVM 20.1.2), 2 vCPU Intel Xeon 2,1 GHz, Xvfb 1280×800. Twee runs per modus, tabel = gemiddelde. Het eerste scenario van een run is soms traag (opwarmen); daarom geldt "grijs-eind" als basis. De machine werd gedeeld met andere processen: op native lagen de twee runs tot 35 % uit elkaar, op 640×400 < 5 %.

| Modus | Scenario | Frame gem. ms | Frame p95 ms | CPU-render ms | GPU ms | Lichtkosten GPU ms¹ | Draw calls gem. / max |
|---|---|---:|---:|---:|---:|---:|---:|
| 640×400 | grijs-eind | 7,8 | 11,8 | 2,7 | 3,5 | 0 | 20 / 22 |
| 640×400 | wijk20 | 28,7 | 37,2 | 21,9 | 23,4 | **19,9** | 16 / 19 |
| 640×400 | piek30 | 35,1 | 43,5 | 27,6 | 29,1 | **25,6** | 16 / 19 |
| native 1280×800 | grijs-eind | 15,6 | 21,0 | 5,3 | 10,8 | 0 | 17 / 22 |
| native 1280×800 | wijk20 | 98 | 160 | 82 | 89 (76 / 102) | **±66–91** | 16 / 21 |
| native 1280×800 | piek30 | 132 | 236 | 114 | 122 (105 / 139) | **±95–128** | 18 / 34 |

¹ GPU-tijd min die van grijs-eind in dezelfde modus.

| Overig (beide modi) | Waarde |
|---|---|
| Geheugen (statisch) | 32,3 MB |
| Videogeheugen | 14,9 MB (640×400) · 24,6 MB (native) |
| Laden flow-kamer | ±100 ms de eerste keer (scripts compileren), daarna 10–20 ms |
| Build via `--main-pack` | `deck`-feature actief, venster 1280×800, render 1280×800; grijs 10,5 ms GPU, gelijk aan native hierboven; de flow-kamer (hoofdscène) draait 300 frames zonder fouten |

### 4.3 Wat de cijfers zeggen

| Vraag | Antwoord |
|---|---|
| Is de flow-kamer zelf zwaar? | Nee. Zonder licht ±3,5 ms GPU op llvmpipe (640×400) en ≤ 22 draw calls. Op een GPU verwacht ik ruim onder 1 ms (aanname). |
| Klopt de rekenregel van #21 in een echte kamer? | Grofweg, maar hij schat hier te laag: ±1,3× bij wijk20 (19,9 ms gemeten, 20 × 0,75 = 15 ms verwacht) en ±1,14× bij piek30 (25,6 ms gemeten, 22,5 ms verwacht). Mogelijke oorzaken: de grote lichten bedekken in deze kamer meer schermvlak, de saturatiepass kost op llvmpipe vooral CPU, de machine was gedeeld. Niet uitgezocht. |
| Native of 640×400? | Native kost het licht **3,3–4,6×** zoveel (TA: 3,1–3,3×). 640×400 is op de Deck dus geen luxe maar nodig om het budget te halen (§3). |
| CPU-render ≈ GPU | Op llvmpipe rendert de CPU zelf; die CPU-tijd zegt niets over de Deck. Op de Deck moet `cpu_ms` klein blijven (§6). |

### 4.4 Omrekening naar de Deck (aanname)

De TA stelt 3 ms GPU per frame voor licht voor (`lichtmeting.md` §5.3; akkoord TD). Nodige versnelling Deck t.o.v. deze llvmpipe = lichtkosten / 3 ms:

| | 640×400 | native 1280×800 |
|---|---:|---:|
| wijk20 (20 LE) | **6,6×** | ±22–30× |
| piek30 (30 LE) | **8,5×** | ±32–43× |

**Aanname, niet gemeten:** de Deck-GPU is 10–30× sneller dan deze llvmpipe (TA, `lichtmeting.md` §5.3). Dan past het budget op 640×400 met een marge van 1,2–4,5×, en op native niet of nauwelijks. De marge is kleiner dan de 2–6× die #21 verwachtte.

## 5. Werkaanname (kader §5)

| Werkaanname | Bron |
|---|---|
| Drempels D1–D8 en 3 ms GPU voor licht (20/30 LE) | Besluit TD bij de review |
| Minimumspecificatie = Steam Deck (LCD, 1280×800, 60 Hz) | Randvoorwaarde "Steam Deck verified als doel" (#2); besluit #18 |
| Godot 4.6.3-stable, `gl_compatibility` | `setup.md` §1; lichtbudget #21 is met deze renderer gemeten |
| Licht ≤ 3 ms GPU per frame; normaal 20 LE, piek 30 LE | Voorstel TA, `lichtmeting.md` §5; akkoord TD |
| Deck-GPU 10–30× sneller dan llvmpipe op 2 Xeon-kernen | Schatting TA, `lichtmeting.md` §5.3; niet gemeten |
| Linux-native build (geen Windows-build via Proton) op de Deck | Deze PR; Proton is niet getest |
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
for m in native 640; do for i in 1 2 3; do
  godot --main-pack builds/deck/polderlight.pck --audio-driver Dummy \
    res://tools/perf/deck_meting.tscn -- --res=$m --frames=600 2>&1 | tee deck_${m}_$i.txt
done; done
```

5. Controleer in de kop: `adapter` is AMD/radeonsi (niet llvmpipe), `features deck: true`, venster 1280×800, render 1280×800 (native) of 640×400 (640). Is `GPU ms` overal 0 (timer niet beschikbaar), gebruik dan `frame gem ms`.
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
| D2 | Run A, wijk20 − grijs-eind (lichtkosten GPU) | ≤ 3 ms op 640×400 (budget TA). Op native: noteren; > 3 ms bevestigt dat §3 nodig is |
| D3 | Run A, wijk20 en piek30, 640×400 | frame p95 ≤ 16,7 ms |
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
| 2 | **Camera die de rendergrootte volgt** (§3), [#120](https://github.com/cesarvangerwen-glitch/echoborn/issues/120): `FlowRoom.camera_zoom` leidt de zoom af van de rendergrootte (640×400 → 1, 1280×720/800 → 2). **Volgende stap:** de Engine & Platform Programmer zet de 5 `.deck`-instellingen uit §3 en draait D1–D4 opnieuw ([#79](https://github.com/cesarvangerwen-glitch/echoborn/issues/79)). | Engine & Platform Programmer |
| 3 | Herhalen op de slice (T8a), zodra die er is: zelfde script, met `FLOW_SCENE` naar de slice-scène. | Engine & Platform Programmer |
| 4 | **Besluit TD:** akkoord op D1–D8 als definitie van "draait op Deck-specificaties", en op het lichtbudget van 3 ms GPU per frame (20 LE normaal, 30 LE piek; `lichtmeting.md` §7 punt 3). | Technical Director (besloten) |
| 5 | Waarom de rekenregel van #21 hier ±1,14–1,3× te laag schat (§4.3). | Technical Artist |
| 6 | Volledige `.x86_64`-build met export templates 4.6.3 (en later een buildscript in CI). Niet gemaakt: geen templates in deze omgeving. | Engine & Platform Programmer (met Tools Programmer voor CI) |
| 7 | Niet gemeten: Vulkan-renderers, Windows-build via Proton, Deck OLED (90 Hz), Steam Input-integratie. | Engine & Platform Programmer |
| 8 | Release-preset maken die `tools/perf/` en `prototypes/lichtmeting/` uitsluit (de Deck-preset houdt ze voor de meting). | Engine & Platform Programmer |
| 9 | Fullscreen-modus 3 (`mode.deck=3`) houden; exclusieve fullscreen (modus 4) is niet getest. | Engine & Platform Programmer |
| 10 | Geen CI-rooktest voor de export (`--export-pack`) of voor `tools/perf/deck_meting.gd` (de testrunner laadt `tools/` niet). | Engine & Platform Programmer (met Tools Programmer) |
| 11 | D5 sluit laden uit van de 33 ms-grens, maar hapers door shadercompilatie bij het eerste licht zijn reëel; apart noteren en een eigen drempel bepalen. | Engine & Platform Programmer (met Technical Artist) |
| 12 | Run B speelt de kamer zonder 2D-licht; verlicht wordt alleen via het meetscript (run A) gemeten. | Engine & Platform Programmer |
| 13 | De omrekenfactor 10–30× rust op één gedeelde 2-vCPU-machine met twee runs per modus. | Engine & Platform Programmer (met Technical Artist) |
| 14 | **16:10 (C-07), besluit TD: geen blokkade.** De leiband blijft 16:9 (`leash_view_px`) voor pc én Deck, zodat sim, echo en replays op dezelfde tick oplossen; geen aparte Deck-waarde. Op 640×400 toont de camera per rand 20–30 wereldpx extra; UX beslist alleen of die band gedimd wordt. | UX Designer |
| 15 | Zoom-uit op 640×400 geeft een niet-gehele schaal (bv. 0,667), dus ongelijke pixels; zichtbaarder dan bij een render van 1280. Vaste zoomtrappen of niet. | Technical Artist en UX Designer |
