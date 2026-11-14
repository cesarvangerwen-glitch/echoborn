# Slice-audio (T8d): SFX-set, signalen, muziekplan (deel 1) en de timing op D = 60 (deel 2)

Versie 0.2.1 · 2026-11-14 · Eigenaar: **Composer/Sound Designer** · Lead-review: Audio Director · Issue [#86](https://github.com/cesarvangerwen-glitch/echoborn/issues/86) (T8d, `docs/productie/fase-2-kader.md` v0.4 §2 en §4)
Bouwt op: `docs/audio/bible.md` v0.5 (§2–§8, §4, §4.1, §6.1, §9.4, §10, §11), issue [#243](https://github.com/cesarvangerwen-glitch/echoborn/issues/243) (pompslag van de echo), `docs/design/combat/slice-vijanden-en-boss.md` v0.1.1 (§2, §3, §7, §9), `docs/design/gdd.md` v0.8 (E-02t, E-07d, E-14b, C-12e, C-14), `docs/design/wereld.md` §2.2 (kamerlijst S1–S9), `game/scripts/echo/echo_hints.gd` (signalen `plank_signal_on`, `doelstreep_on`).

Deel 1 (§1–§4) is alles wat **niet** van de staart D afhangt; **deel 2** (§7) is wat op D = 60 vastzit: de merk-aftelling, de echo-varianten, de boss-stems en de speler (geraakt, slag van P2). Het F2-fragment (`docs/audio/f2-fragment/`) is de klankbron: dezelfde klokken, hetzelfde water en dezelfde `echo_versie`, want de CEO vond de F0-geluiden "heel leuk" en het fragment klonk als een beiaard en "jij, maar hol". Wat nog openstaat, staat in §5 en §6.

---

## 0. Werkaanname (kader §5)

| Bron | Wat dit deel ervan gebruikt |
|---|---|
| CEO-besluit 2026-11-12 (#80) | **D = 60 ticks (1 s)** is de werkaanname, bereik 1–3 s. Geen enkel bestand in deze set hangt van D af: de set blijft geldig als D verandert. Wat wel van D afhangt (aftelling, echo-timing), wacht op deel 2 (§5). |
| CEO-besluit 2026-11-12 (#80) | Fase 2 parallel: T8d deel 1 wacht niet op een geslaagde flow-test. De CEO test alleen bij mijlpalen (MT2/MT3); tot dan meten we en beoordeelt de Audio Director. |
| Fasekader v0.4 §4, regel tegen weggooiwerk | Eerst placeholder: alles hier heet `_placeholder` (`WERKWIJZE.md` §9) en staat in `docs/audio/`, niet in `game/`. Alle tijden komen uit één bron (het script, met tickwaarden uit `slice-vijanden-en-boss.md`), zodat een andere aanloop één getal is. |
| `slice-vijanden-en-boss.md` §0 | Alle tick-tijden zijn **startwaarden** van de Combat Designer (gezet met B-9). Verandert een aanloop, dan render ik het bestand opnieuw met het nieuwe getal (± 10 s). |
| Bible v0.5, kop | 60 Hz-tick, € 0 extern, eigen synthese; speler 1 altijd "in kleur"; D = 60, merk solo D + 30 = 90 ticks, co-op 150, knal op D + 3 = 63. |
| Deel 2 (§7) | Rekent met **D = 60** en de maat **120 / 90 ticks** (`slice-vijanden-en-boss.md` §7: niet van D afhankelijk). Verandert D, dan is het één getal in het script (`D`, `VOOR_TICKS`) en ± 25 s rekenen. |

---

## 1. Wat er is en waar

| Pad | Wat |
|---|---|
| `docs/audio/t8d-slice/sfx/vijanden/` | 11 bestanden: Kadeloper, Schotdrager, Dwaallicht, pantser-"tink" |
| `docs/audio/t8d-slice/sfx/gemaalmeester/` | 22 bestanden: maat-tel, pompslag, zwiep, spuigaten, schot, kern, rad, fasewissel, Wankel, merkplek |
| `docs/audio/t8d-slice/sfx/finisher/` | 26 bestanden: start, 8 slagen × 3 materialen (p1, p2, echo), slot |
| `docs/audio/t8d-slice/sfx/merk/` | 10 bestanden: ontploffing per kettingschakel k1–k5, grijs en kleur |
| `docs/audio/t8d-slice/sfx/signalen/` | 3 bestanden: plank-signaal, doelstreep-voorslag (grijs, kleur) |
| `docs/audio/t8d-slice/luisterreeks_slice_sfx_placeholder.ogg` | **Om te beluisteren** (53 s): alle tells op hun echte ticks, in volgorde Kadeloper → Schotdrager → Dwaallicht → ketting → GM fase 1 → fasewissel + fase 2 → Wankel → finisher → signalen. De momenten staan in `meting_placeholder.json` (`_luisterreeks.momenten_s`) |
| `docs/audio/t8d-slice/luisterreeks_spectrogram_placeholder.png` | Golfvorm en spectrogram van de reeks, met de delen erop |
| `docs/audio/t8d-slice/meting_placeholder.json` | Per bestand: duur (s en ticks), max. momentane loudness, true peak, aandeel boven 250 Hz, zwaartepunt, piekmoment, stijging |
| `docs/audio/t8d-slice/bron/genereer_slice_sfx.py` | Het script dat alles maakt (± 10 s), vaste seed |

**Formaat:** WAV, 48 kHz, 16 bit, **mono** (voor `AudioStreamPlayer2D`, bible §10); alleen `finisher_slot` is stereo (galm van het belfort). **72 bestanden, ± 12 MB** (de luisterreeks als OGG).

**Opnieuw maken:** `python3 docs/audio/t8d-slice/bron/genereer_slice_sfx.py` vanaf de repo-root. Nodig: numpy, scipy (en het F2-script, dat het importeert); optioneel ffmpeg met libvorbis (OGG) en matplotlib (PNG). De WAV-bestanden zijn **byte-gelijk** opnieuw te maken (twee runs gaven dezelfde hashes, bv. `pantser_tink_placeholder.wav` = `a1692a6d…49df8b`).

**Niveaus:** elk bestand staat op een **vast niveau per soort** (max. momentane loudness, 400 ms), zodat ze op één schaal tegenover elkaar staan, met 0 dB gain in de speler: tells −15, aanvallen −14, tink en treffers −17, knallen −13, finisherslag −19 (echo −23), lussen −30 (Wankel −26), signalen −29 / −27 LUFS. True peak ≤ −1,5 dBTP voor alle bestanden. De mix zelf (bussen, duk, voorrang) is van de Audio Director (bible §8, §10).

### 1.1 Luisterfragment voor de luistercheck in MT2 (V-10, bible §9.4)

**Bestand:** `docs/audio/luistercheck-mt2/luistercheck_mt2_placeholder.ogg` (66,6 s, Vorbis q6, 48 kHz, stereo, ± 1 MB). Script: `docs/audio/luistercheck-mt2/bron/genereer_luistercheck_mt2.py`; tijden en metingen in `meting_placeholder.json` ernaast.

**Wat het is.** Het fragment dat F2 claimt (v2, 15,5 s) is kort voor drie vragen. Deze reeks rendert **niets nieuws**: alles komt uit v2 of uit zijn eigen bouwstenen (`f2-fragment/losse-sfx/`). **Deel A begint op 0,0 s en is sample voor sample v2** (het script controleert de sha256 van v2 en de gelijkheid), dus de tijden van bible §9.4 en de kaart (L1–L3) kloppen zonder aanpassing. Daarna per vraag de stukken nog een keer naast elkaar, en tot slot v2 nog een keer heel. Tussen de delen 2 s stilte; geen stem en geen signaaltoon (die zou je met een klok verwarren).

| Tijd (s) | Deel | Wat | Vraag |
|---|---|---|---|
| 0,0–15,5 | A | v2 heel (bible §9.1) | L1–L3 |
| 17,5–25,6 | L1 | 2×: carillon grijs (v2 1,9–3,3 s: aftelslag 1 en 2, de klokslag met de echo) → opgepompt (v2 10,3–11,9 s: aftelling en ketting) | L1 |
| 27,6–30,3 | L2 | in de mix: slag van P1 (v2 0,35–1,35 s) → de echo (v2 2,15–3,15 s) | L2 |
| 31,0–35,8 | L2 | 2× los: `p1_slag` → `echo_slag` (= `echo_versie` van die slag, 7 dB zachter, bible §4) | L2 |
| 37,8–49,1 | L3 | 2×: grijs (v2 3,9–6,2 s, wereld zonder spelers) → opgepompt (v2 12,0–14,3 s) | L3 |
| 51,1–66,6 | B | v2 nog een keer heel | — |

**Niveau.** Stukken uit v2 op 0 dB (alleen 15 ms in- en uitfaden). De losse P1-slag op het niveau van de P1-slag in v2 en de echo 7 dB lager, daarna beide 1,4 dB zachter zodat hun true peak onder die van v2 blijft.

**Metingen** (script, pyloudnorm en ffmpeg ebur128, onafhankelijk):

| Meting | WAV (opnieuw te maken) | OGG na decoderen | Doel (bible §8) |
|---|---|---|---|
| Geïntegreerde loudness | −17,9 (script) / −18,0 (pyloudnorm) / −18,0 (ebur128) LUFS | −18,0 (ebur128 en pyloudnorm) | −18 ± 2 ✓ |
| True peak | −1,8 dBTP (script en ebur128) | −1,5 dBTP | ≤ −1 ✓ |
| Clipping | 0 samples | — | 0 ✓ |
| Deel A en B gelijk aan v2 | ja (sample voor sample) | — | — |

**Opnieuw maken:** `python3 docs/audio/luistercheck-mt2/bron/genereer_luistercheck_mt2.py` vanaf de repo-root (`--wav` houdt de WAV). De WAV is byte-gelijk opnieuw te maken (sha256 `b5524e39…e69fff`, twee runs gelijk); in de repo staat alleen de OGG (de WAV is 12,8 MB). De OGG kan per ffmpeg-build verschillen.

**Voor de kaart (QA Lead).** Antwoorden op L1–L3 kunnen na deel A; de rest is herhaling naast elkaar. Luisteren ± 1 min 10 s, met antwoorden ± 2 min. Het pad komt in V-10 en op de kaart via de QA Lead (#250); ik wijzig het testplan en de kaart niet.

### 1.2 Pompslag op een schoep (#243, bible §4.1)

**Bestand:** `game/audio/sfx/omgeving/pompslag_schoep_placeholder.wav` (+ `.import` van Godot 4.6.3, standaardinstellingen; TD-besluit (c)). Eén bestand voor P1, P2 en de echo, **geen echo-variant** (bible §4.1, §11). Script: `audio-bron/sfx/omgeving/genereer_pompslag_schoep.py` (vaste seed, byte-gelijk opnieuw te maken; bouwt op het F2-script).

**Klank:** machinefamilie (bible §3), zoals de pompslag in het gemaal van F2: een korte klik van hout op ijzer, de plof van de schoep in het water (98 → 52 Hz), vijf houtmodi (176–1690 Hz), het ijzer van de as (310, 742, 1214, 1987 Hz), een waterstoot (300–2400 Hz) en spatbelletjes (Minnaert, 420–1900 Hz). Een zachte true-peak-limiter op de eerste milliseconden van de klap.

| Meting | Waarde | Eis #243 | |
|---|---|---|---|
| Duur | **28 ticks** (0,467 s); de echo-versie (`pitch_scale` 0,944) duurt 29,7 ticks | ≤ 30 ticks | ✓ |
| Max. momentane loudness (400 ms) | **−17,0 LUFS** (script, pyloudnorm en ffmpeg ebur128 gelijk) | −17 | ✓ |
| True peak | **−1,8 dBTP** (script en ebur128) | ≤ −1,5 | ✓ |
| Aandeel boven 250 Hz | **44,8 %** (60–250 Hz: 42,6 %; zwaartepunt 373 Hz) | ≥ 35 % | ✓ |
| Clipping | 0 samples | — | ✓ |

**Controle (eis van de Audio Director in #243)** in `docs/audio/pompslag-schoep/`: `pompslag_controle_zelfde_tick_placeholder.wav` (P1 en de echo met `pitch_scale` 2^(−1/12) op dezelfde tick) en `pompslag_controle_s6_reeks_placeholder.wav` (S6 bij D = 60: P1 op tick 0, 20, 40, 60, de echo op 60, 80, 100, 120). Gemeten: de twee slagen houden **elk hun eigen partialen** (P1 176 / 310 / 404 / 739 Hz, de echo 166 / 293 / 381 / 697 Hz; in de som staan ze allebei los), en de echo klinkt 1,7 ticks langer. **Of dat als twee slagen leest, kan ik niet meten**: op dezelfde tick vallen de aanslagen samen, dus het verschil zit alleen in de toonhoogte en de staart. De som is ± +3,7 dB luider en ± +5,5 dB hoger in piek (true peak +3,7 dBTP zonder gain; de controles staan daarom 5,1–5,2 dB lager). Dat vangen de limiter op de Master en de 3 stemmen van bible §8.3 op; dat is de mix van de Audio Director.


### 1.3 Luik breekt en de levende rad-treffer in het spel (#243, bible §4.1)

Na de koppeling van de Gameplay Programmer (PR #282) staan de drie geluiden die nog stil waren in `game/audio/` (+ `.import` van Godot 4.6.3 `--import`, standaardinstellingen, `compress/mode=2`). Metingen: `docs/audio/luik-rad/meting_placeholder.json`.

| Bestand | Wat | Duur | Max. momentaan | True peak | > 250 Hz |
|---|---|---|---|---|---|
| `sfx/omgeving/luik_breekt_placeholder.wav` | Het luik breekt (V-01d/e), **één** bestand voor P1, P2 en de echo, ook als de echo de schaduwklep wegslaat | 42 t | −15,0 LUFS | −1,8 dBTP | 41,3 % |
| `sfx/gemaalmeester/gm_rad_treffer_1_placeholder.wav` | Rad-treffer van P1/P2; de bron van de holle `echo/echo_gm_rad_treffer_1` (§7.2) | 66 t | −17,0 | −6,0 | 98,3 % |
| `sfx/gemaalmeester/gm_rad_treffer_2_placeholder.wav` | De treffer die `kant_treffers` haalt: een kwart hoger, "deze kant is klaar"; nooit voor de echo | 66 t | −17,0 | −6,6 | 98,3 % |

**Luik breekt.** Script `audio-bron/sfx/omgeving/genereer_luik_breekt.py` (seed 2431, byte-gelijk opnieuw te maken; bouwt op de pompslag en F2). Een eiken luik met een scheur (L-03) dat onder een neerslag **doorbreekt**: de klap op het hout (plof 120 → 60 Hz, het lijf), negen krakende breuken in 90 ms met per plank andere houtmodi (230–2400 Hz), scheurende vezels, splinters tot ± 11 kHz, het ijzeren beslag dat losschiet (inharmonisch, geen klok: bible §8.5) en twee planken die beneden neerkomen (260 en 330 ms). Droog, zonder water: zo verschilt het van de pompslag (zwaartepunt 701 tegenover 373 Hz). De aanslag ligt op sample 0 (de tick van `opened` / `schaduwklep_weg`, geen aanloop). Niveau −15 LUFS, tussen treffers (−17) en knallen (−13): een poort die opengaat. Geen holle laag, geen toonverschil voor de echo (`pitch_scale` 1,0, `luik_audio.gd`), dus de schaduwklep die de echo wegslaat klinkt **als breken**; "tijd" is stil (V-01d).

**Rad-treffer.** `audio-bron/sfx/gemaalmeester/zet_gm_rad_treffer.py` kopieert **precies** de bestanden van deel 1 (`docs/audio/t8d-slice/sfx/gemaalmeester/`, `genereer_slice_sfx.py`, sha256 gelijk), zonder opnieuw te renderen: de holle echo-versie is uit deze `_1` afgeleid, dus "dat ben jij, maar hol" klopt (bible §4). Paden zoals in `game/data/audio.json` (`rad_treffer.stream_1` / `stream_2`).

**Pad van het luik in `audio.json`.** `luik_breekt.stream` blijft **leeg**: zet je het pad, dan faalt `test_luik_zelfde_breekgeluid` (het "stille" luik verwacht 0 starts zonder bestand; lokaal nagemeten met Godot 4.6.3). Het pad staat in de `_toelichting`; de Gameplay Programmer zet het samen met de test (§6).

---

## 2. De SFX-set: event → bestand → duur → leesbaarheid

**Regel voor elk aanloop-bestand:** het duurt **precies** zijn aanloop en eindigt op de tick waarop het actieve vlak begint. De code start het op het begin van de aanloop (de vlag `aanloop` van B-6); dan valt het hoogtepunt vanzelf framexact op de slag. Elke aanloop **stijgt** (gemeten: laatste 100 ms tegenover de eerste 100 ms, kolom "↑"), dus je hoort *wanneer*; de klankvorm verschilt per aanval, dus je hoort *wat* en *waar* (§9 van het combat-document: "de aanloop toont waar het vlak komt, niet alleen dat er iets komt"). Alle aanlopen en tells van aanvallen liggen voor ≥ 97 % boven 250 Hz, de maat-tel `gm_maat_tel_grijs` voor 77 % (de grijze klok D4 heeft zijn hum op D3); allemaal hoorbaar op de Deck en een tv (bible §8.2).

Paden: `docs/audio/t8d-slice/sfx/<map>/<naam>_placeholder.wav`. Duur in ticks (60/s).

### 2.1 Vijanden

| Event (code) | Bestand (`vijanden/`) | Duur | Hoe het de tell leesbaar maakt |
|---|---|---|---|
| Kadeloper: haakslag, aanloop (B-2, `aanloop`) | `kadeloper_aanloop` | **30** t (0,5 s), ↑ 14 dB | IJzer schraapt over steen: schokjes die **versnellen** (22 → 82 per s) en een toon die met de haak **meestijgt**; eindigt met één droge tik = de haak op zijn top. Ruisachtig en hoog (zwaartepunt ± 2,9 kHz): "dichtbij, op de grond, ga weg of spring" |
| Kadeloper: haakslag, actief 6 t | `kadeloper_haakslag` | 24 t (0,4 s) | Veeg die in 6 ticks **daalt** (3,4 → 0,7 kHz) + korte ijzerklank: de slag zelf, ook als hij mist |
| Kadeloper/Schotdrager: dood | `kadeloper_dood` | 54 t | Slok + dalende bellen: lost op in donker water (§9.1), zacht, geen vleesgeluid (PEGI 12) |
| Schotdrager: schotstoot, aanloop | `schotdrager_aanloop` | **30** t, ↑ 11 dB | **Piepend roestig scharnier** (een toon met ruwheid, 330 → 560 Hz) + rammelende plaat die aanzwelt; het schot slaat in zijn stand met de **piek in de laatste 3 ticks** (gemeten 0,461 s = t 27,7). Tonaal en lager dan de Kadeloper: je hoort aan de klank dat het de gepantserde is, vóór je hem ziet |
| Schotdrager: schotstoot, actief 6 t | `schotdrager_schotstoot` | 30 t | Plaat-dreun + luchtstoot |
| **Treffer op intact pantser, 0 SE** (VJ-07, B-3 event) | `pantser_tink` | 17 t (0,28 s) | **Klein, droog, hoog en meteen gedempt**: geen lijf, geen hout, geen naklank (> 1,2 kHz, gedempt na 45 ms). Elke treffer *mét* schade heeft lijf en koper (`p1_slag` van F2); de tink mist dat juist. Zegt: "dit is pantser, slaan helpt niet" |
| Pantser breekt (eerste ontploffing op de Schotdrager) | `schotdrager_pantser_breekt` | 60 t | Roest knispert, plaat scheurt (12 t, = de animatie), valt twee keer op de steen. Alles **boven 1,2 kHz**, zodat de klok D5 van de ontploffing eronder hoorbaar blijft |
| Dwaallicht: zweven (zolang hij leeft) | `dwaallicht_zweef_lus` | 120 t, **lus** | Zacht zoemen (620 Hz) dat ademt; naadloos te lussen. Zacht (−30): je volgt hem zonder dat hij zeurt |
| Dwaallicht: duik, aanloop | `dwaallicht_aanloop` | **30** t, ↑ 11 dB | Het zoemen **stijgt een kwint** (620 → 930 Hz) en wordt helderder: "licht zwelt, toon stijgt" (§9.3). Zelfde toon als het zweven: je herkent wie het is |
| Dwaallicht: duik, actief 8 t | `dwaallicht_duik` | 21 t | De toon **valt een octaaf** in 8 ticks: hij komt naar beneden |
| Dwaallicht: dood | `dwaallicht_dood` | 54 t | Glazen tikjes die opstijgen: het licht dooft, geen knal |

### 2.2 De Gemaalmeester

| Event (code) | Bestand (`gemaalmeester/`) | Duur | Hoe het de tell leesbaar maakt |
|---|---|---|---|
| **Begin van elke maat** (B-6 maatklok: 120 t fase 1, 90 t fase 2) | `gm_maat_tel_grijs` (`_kleur` reserve) | 84 t (0,5 s hoorbaar, dan gedempt) | De **laagste klok van de wijk, D4**, is zijn stem (bible §6.3). Kort gedempt, zodat ± 55 tellen per gevecht niet zeuren. Het ritme dat je leert (GM-04): na twee maten weet je wanneer de volgende komt |
| Pompslag, aanloop **fase 1** (40 t) | `gm_pompslag_aanloop_f1` | **40** t, ↑ 17 dB | **Sissende zuiger die stijgt**: stoom die opbouwt, de piepende as (GM-04) die van 640 naar 1080 Hz trekt, krakende stang. Een **doorlopende** stijging = "laag, op de vloer, aan die kant: stap door de machine of spring". De kant hoor je via de 2D-positie van de stang (pan) |
| Pompslag, aanloop **fase 2** (30 t) | `gm_pompslag_aanloop_f2` | **30** t, ↑ 15 dB | Dezelfde klank, korter: je herkent de pompslag uit fase 1 |
| Allereerste aanval (60 t, aarzeling bij de sjaal) | `gm_pompslag_aanloop_eerste` | **60** t | Een stoomzucht, een stilte, dan pas de stijging (36 t): hij houdt in. Verhaal zonder tekst |
| Pompslag, actief 6 t | `gm_pompslag_slag` | 60 t | Dreun + **ijzeren klank** erop (38 % boven 250 Hz, zodat je hem ook op de Deck hoort) + stof |
| Schoepenzwiep, aanloop (30 t) | `gm_zwiep_aanloop` | **30** t, ↑ 11 dB | Schoepen die **opdraaien**: losse schoeppassages die **versnellen** (6 → 18 per s) op aanzwellend water-gesuis. Pulsen in plaats van een doorlopende stijging: dat is het verschil met de pompslag, ook met je ogen dicht. Betekenis: "hoog, over de helft: blijf op de vloer" |
| Schoepenzwiep, actief 8 t | `gm_zwiep_veeg` | 42 t | Een brede waterzwiep die **op dezelfde hoogte** blijft (geen dalende toon: het vlak is horizontaal) + spatten |
| Spuigaten gloeien (30 t, adds) | `gm_spuigat_borrel` | 51 t (30 + stoot) | Borrelen dat **dichter** wordt, dan een stoot stoom op tick 30: de add stapt eruit |
| Treffer op het intacte schot (0 SE) | `gm_schot_tink` | 24 t | **Dezelfde tink** als de Schotdrager, een grotere plaat (lager, iets langer): je herkent de les van S3 |
| `SCHOT_BREUK` | `gm_schot_breuk` | 96 t | Krak, scheur (12 t), stoom, en een warme klok (D4) die oplicht met de ketel: de kern ligt open |
| Kern ligt open (tot `KERN_DICHT`) | `gm_kern_puls_lus` | 120 t, **lus** | Warm borrelen + lage gloed (D3) die ademt: zolang je dit hoort, mag je slaan |
| Treffer op de kern | `gm_kern_treffer` | 36 t | **Dof en warm** (koperen ketel), geen metaalklank: anders dan de tink, dus "dit doet schade" |
| `KERN_DICHT` (schot schuift dicht, 20 t) | `gm_schot_dicht` | 47 t | IJzer raspt 20 ticks, sluit met een klap op tick 20 |
| `RAD_TREFFER` 1 en 2 van een kant | `gm_rad_treffer_1`, `gm_rad_treffer_2` | 66 t | IJzer dat zingt (C5 met inharmonische boventonen). De **2e treffer klinkt een kwart hoger**: "deze kant is klaar" (`kant_treffers` = 2) |
| Rad trilt (20 t, tell vóór het draaien) | `gm_rad_ratel` | **20** t, ↑ 8 dB | Pal-klikken die **versnellen**: het rad gaat weg, loop mee |
| `RAD_DRAAI` (60 t) | `gm_rad_draai` | 90 t | Zwaar malen, krakende as, een klak **op tick 60** als het rad aankomt: dan pas kun je weer bouncen |
| `BOSS_FASE` 2 (fasewissel 60 t) | `gm_fasewissel` | 108 t | Alle stoom ontsnapt, kettingen hijsen het rad met **12 klikken die een octaaf stijgen**, en het rad slaat vast op tick 60 |
| `BOSS_FASE` wankel | `gm_wankel_start` | 120 t | De klok D4 wordt aangeslagen en **na 0,12 s afgeklemd**; de machine zakt weg. Daarna speelt de maat-tel niet meer: **het carillon valt stil** (§9.3). De stilte is de tell: geen aanvallen meer |
| Wankel (zolang hij hapert) | `gm_wankel_hapert_lus` | 180 t, **lus** | Een zuiger die niet meer pakt, onregelmatig, een kreunende as. Geen ritme: de maat is weg |
| Merkplek gaat open (20 t, GMB-05) | `gm_merkplek_open` | 80 t | Licht zwelt 20 ticks, dan een klein klokje **A5**: de familie van het merk (`merk_zet`), dus "hier zet je een merk" |

### 2.3 Finisher (C-14, bible §6.4)

| Event (code) | Bestand (`finisher/`) | Duur | Hoe het leest |
|---|---|---|---|
| `FINISHER_START` | `finisher_start` | 30 t | Omgekeerde klok D5 die aanzwelt naar de eerste slag: de gedeelde echo komt "uit het verleden" |
| `FINISHERSLAG` (elke slag van P1 en het tweede lichaam in de laatste 600 t, ×5 versneld in 120 t) | `finisher_slag_p1_1` … `_8`, `finisher_slag_p2_1` … `_8`, `finisher_slag_echo_1` … `_8` | 66 t elk | **Jullie slagen als versnelde tellen**: elke slag een carillonslag, **oplopend** door de D-groot-pentatoniek (D5 → F♯6), om en om in het materiaal van wie hem sloeg: **p1** koper en hout, **p2** ijzer en glas, **echo** = p1 maar hol (zonder lijf, holle kam, −4 dB; zonder omgekeerde aanloop, want er vallen tot 5 slagen per s). De code kiest toon `min(i, 8)` per slag; meer dan 8 slagen blijven op de hoogste toon |
| `BOSS_VERSLAGEN` (tick 120 van de finisher) | `finisher_slot` (stereo) | 300 t | **Slot in licht**: de volle klokkenrol van D6 omlaag naar de grote klok D4 (op 45 ms, zoals een beiaardier), in de galm van het belfort. Het enige moment met het hele carillon tegelijk |

### 2.4 Merk en ketting (bible §6.2)

| Event (code) | Bestand (`merk/`) | Duur | Hoe het leest |
|---|---|---|---|
| Ontploffing van schakel k (E-14d) | `ontploffing_k1_grijs` … `ontploffing_k5_grijs`, idem `_kleur` | 204 t | De ontploffing van het F2-fragment (licht en schaduw, grote klok D5), per schakel groter, met de **kettingklok een stap hoger** (D5, F♯5, A5, B5, D6). De **rol van 45 ms** tussen schakels doet de code (bible §6.2): de eerste schakel framexact, de rest gerold. In de slice is bijna alles grijs (`s < 2`); `_kleur` is voor S9 |

*De ontploffing zelf hangt niet van D af, alleen het moment (de echo op `D + 3`); daarom zit hij in deel 1. De aftelling ervoor zit in deel 2 (§5).*

---

## 3. Signalen voor plank en doelstreep (`echo_hints.gd`)

Beide zijn **steun voor wat je al ziet** (de CEO zag de doelstreep en de cirkel in F0-2 en ze hielpen), dus kort, zacht en zonder nieuwe betekenis.

| Signaal | Bestand (`signalen/`) | Duur | Niveau | Klank | Hoe aansluiten (voor de Audio Director / Gameplay Programmer) |
|---|---|---|---|---|---|
| `plank_signal_on(tick)` (E-07d) | `plank_signaal` | **5 t** (90 ms) | −29 LUFS (14 LU onder een tell) | Eén **zachte houten tok, hol** (de klankfamilie van de echo: hout van speler 1, door een korte holle kam), zonder lijf, 1,6 kHz | Eén keer op de flank (het signaal geeft alleen de flank). **Niet vaker dan 1× per 30 ticks** (één tok per nadering, ook als het signaal flakkert). Speelt op de positie van de echo (2D) |
| `doelstreep_on(tick, mark_id)` (E-02t) | `doelstreep_voorslag_grijs` (`_kleur` in S9) | **30 t** (0,5 s) | −27 LUFS, ↑ 37 dB | **Carillon-voorslag**: een omgekeerd klokje (E6) dat aanzwelt en **precies op de slag van de echo ophoudt**; de knal neemt het over. Geen aanslag, dus het lijkt niet op een aftelslag | De streep gaat aan op **t 30** na de slag van P1 (`x + D − 30`, E-02t); de merksprong begint op t 60, de **knal valt op t 63** (D + 3). Het bestand (30 t) moet op de knal eindigen. Met `ahead = 1 + (1 − doelstreep_strength) × 30` (ticks tot het AANVAL-frame) op de tick van `doelstreep_on`: **wacht** `max(0, ahead + 3 − 30)` ticks en speel vanaf **beginpunt** `max(0, 30 − (ahead + 3))` ticks in het bestand. Gewoon geval: de streep gaat aan met `ahead = 30` → 3 t wachten, start op **t 33**, einde op **t 63**; komt de streep later aan, dan begint het bestand verderop en valt het eind toch op de knal. **Eén voorslag per `mark_id`**: springt de streep naar een ander merk, dan loopt de lopende voorslag door (geen tweede); verdwijnt de streep (`doelstreep = false`), dan 30 ms uitfaden. Max. 1 tegelijk |

### 3.1 Aftelling naast de doelstreep (besluit Audio Director, Lead-review PR #193)

Alleen audio; de aftelling in beeld blijft zoals ze is. Solo, D = 60, merk gezet op t 0 (leeft 90 t, aftelling op t 30, 45, 60, 75; bible §6.1):

| Situatie | Wat je hoort |
|---|---|
| De doelstreep staat op **dit** merk | **Slag 1 op t 30 blijft**; **slag 2 (t 45) en slag 3 (t 60) vallen weg**; de voorslag loopt van t 33 en **eindigt op de knal (t 63)**. Klinkt als: "één, … *zwel* … boem" |
| De streep **verdwijnt vóór t 60** (doel dood, merk gedoofd, ander merk dichter) | **Slag 3 komt terug** op t 60, daarna volgens §6.1 van de bible (zachte slag 4 op t 75, doven op t 90). De lopende voorslag faden in 30 ms uit |
| Geen doelstreep op dit merk (echo Leeg, gebroken of op een ander merk) | Aftelling volgens bible §6.1, ongewijzigd |
| **Co-op** (merk 150 t, C-12e) | **Ongewijzigd**: aftelling op t 90, 105, 120, 135; er is geen echo, dus geen voorslag op dit merk |

De Audio Director meldt dit aan de LGD en neemt het op in bible v0.4 (§2 A2, §6.1, §10 `MerkAudio`).

**Haakje in de code:** de signalen bestaan al (`echo_hints.gd`, regel `signal plank_signal_on`, `signal doelstreep_on`); het commentaar daar zegt dat het geluid van de Audio Director komt (T10). Ik verander niets in `game/`: aansluiten is implementatie, en dat is van de Audio Director (rolbestand: "Wat je níét doet").

---

## 4. Muziekplan voor de slice-wijk (Kadewijk, S1–S9)

### 4.1 Vorm

Zoals bible §7: **adaptief in lagen**, per wijk een grijze, een lichte en een gevechtslaag, synchroon en loopbaar (`AudioStreamSynchronized`), plus een eigen set voor de boss (`AudioStreamInteractive`). Alleen instrumenten die met code op eindkwaliteit te maken zijn (bible §3): **carillon, harmonium, bourdon, hakkebord, machine**. Toonsoort **D**.

### 4.2 Motieven

| Motief | Noten | Waar het klinkt | Wat het zegt |
|---|---|---|---|
| **M1 Het merk** (aftelling) | **A – B – C♯ – D** (stijgend naar de grondtoon, bible §7) | Overal; het is het motief van de wijk | Wie het hoort, denkt aan het merk. In **grijs blijft het hangen op C♯** (de leidtoon, net als `merk_dooft`: onopgelost); in **licht lost het op naar D en stijgt door naar F♯** (de terts die terugkomt, A3) |
| **M2 De Gemaalmeester** | **D – C♯ – B – A**, laag (M1 omgekeerd en dalend), op zijn klok D4 en in het laag van het harmonium | De gevechtslaag van S6/S8 en de boss | Hij trekt het licht omlaag: hetzelfde motief, de verkeerde kant op. In de **finisher** keert het om: jullie slagen stijgen (§2.3) en het slot zet M1 opgelost neer. Wie goed luistert, hoort dat je hem niet verslaat maar *terugzet* (verhaal V2: de machine die levend werd) |
| **Kleur: de terts** | F♯ | Alleen in licht | Bible A3: grijs = lege kwint D–A, licht = D-groot add9 |

Het **gemaalritme** (pompslag 0,8 s, 75 BPM, bible §6.3) is de hartslag van een opgepompte wijk en het tempo van de verkenmuziek.

### 4.3 Van grijs naar licht, kamer per kamer

| Kamer (waterstand) | Muziek | Omgeving |
|---|---|---|
| **S1–S5** (`s = 0`, grijs) | **Grijze laag**: bourdon D–A ver weg, één verre verzonken klok, M1 in fragmenten (A–B … en dan stilte; nooit C♯–D). Weinig muziek, veel water. In S5 (het huis van Ward, geen gevecht) alleen het harmonium, zacht, M1 traag en onopgelost | Verzonken galm, kabbelen, wind, druppels (F2 grijs) |
| **S2, S3, S4 gevecht** | **Gevechtslaag grijs**: ritme uit klokjes op lege kwinten en houtklop op 75 BPM, geen laag dat de tells maskeert (bible §8: tells eerst) | Bed dukt 3–6 dB |
| **S6** (`s = 0 → 1`) | Het gemaal slaat aan (F2 `machine_aan`): het ritme van 0,8 s komt erbij en blijft. Bij **trap 1** zwelt het harmonium op D–A in (nog **zonder terts**): het licht is half terug | Water zakt (F2 `leeglopen`) |
| **S7** (`s = 1`) | Schemer: bourdon + harmonium D–A + gemaal ver weg. Bij de sokkel (Neerslag) één keer M1 tot en met C♯ | Kelder: droger, druppels |
| **S8 boss** | Eigen set (§4.4) | Machinehal |
| **S9** (`s = 1 → 2`) | **Het lichtmoment**: een grote klok D4, de **terts F♯ zwelt aan** (zoals F2 6,2–8,6 s), harmonium D-groot add9, en voor het eerst het **hakkebord met M1 opgelost** (A–B–C♯–D–F♯). De **bevroren echo's** die hun 10 s uitspelen, krijgen elk één noot van M1 (een klokje, hol), zodat de wijk het motief samen afmaakt | Belfort-galm, helder water, het gemaal draait |
| **S9 → S1 terug** | De lichte laag blijft; S1 klinkt nu anders dan bij aankomst: dezelfde plek, met terts | — |

### 4.4 De boss (S8)

| Deel | Muziek |
|---|---|
| Arena dicht (`BOSS_START`) | Bed weg, alleen de machine; de eerste tel is de aarzeling (60 t) |
| Fase 1 | **Maat = muziekmaat.** Voorstel: **120 BPM, 30 ticks per tel**, fase 1 in **4/4** (maat 120 t), fase 2 in **3/4** (maat 90 t): dezelfde puls, een kortere maat. De maat-tel (`gm_maat_tel`) is de eerste tel van elke maat; de muziek is M2 in het harmonium-laag + gemaalritme, zonder terts |
| Fase 2 | Zelfde tempo, 3/4, de schoepen als ritme (water op tel 2 en 3), M2 een octaaf hoger |
| Wankel | **Het carillon valt stil**: muziek weg, alleen `gm_wankel_hapert_lus` en de bourdon |
| Finisher → slot | De finisher-slagen zijn de muziek (§2.3); het slot gaat over in de stilte |
| Na de boss | Stilte (bible §7: "stilte mag"), water; dan S9 |

Waarom 120 BPM: een **aanloop van 30 ticks is precies één tel**. De zwiep en de pompslag van fase 2 vallen dan op tel 2 van hun maat: de muziek *telt mee* met wat je moet ontwijken. De pompslag van fase 1 (aanloop 40 t) valt 10 ticks na tel 2; dat is geen probleem voor de leesbaarheid (de tell is het SFX, niet de muziek), maar wel een vraag aan de Combat Designer (§6).

### 4.5 Formaat en omvang (voor deel 2/3)

- Stems als OGG Vorbis met loop-punten, lengte een veelvoud van de maat: verkennen 75 BPM 4/4, 16 maten = **51,2 s**; boss fase 1 16 × 2 s = **32 s**; fase 2 16 × 1,5 s = **24 s**.
- Raming: **2 maak-taken** (verkenlagen grijs/licht/gevecht; boss-set), plus 1 voor de mix met de Audio Director. Past binnen de 2–4 van T8d (deel 1 = 1).

---

## 5. Wat pas na de vaste timing kan (deel 2)

| # | Wat | Waarom het wacht | Wanneer |
|---|---|---|---|
| 1 | **Merk-aftelling op D = 60** (E-14b): solo leeft een merk 90 t, de aftelslagen vallen op t 30, 45, 60, 75 na het zetten | Hangt aan D. Bij D = 60: (a) de echo knalt op **D + 3 = 63**, niet op 60; (b) de **doelstreep gaat aan op t 30**, tegelijk met aftelslag 1, en de voorslag loopt van t 33 tot de knal op t 63. **Besluit Audio Director** (Lead-review PR #193): zie §3.1 (slag 2 en 3 vallen weg zolang de streep op dat merk staat, slag 1 blijft, co-op ongewijzigd). Wat in deel 2 nog moet: de bible naar D = 60 (Audio Director, v0.4), de aftelslagen opnieuw renderen/zetten op t 30/45/60/75 en de regel in de bots/het log nalopen | **Gedaan in deel 2** (§7.1): gerenderd en gezet, met een controle van de vier situaties. Open: de regel in de bots/het log nalopen (GP/QA, bij de koppeling) |
| 2 | **Echo-varianten** van de slice-geluiden (bible §4: afgeleid met `echo_versie`) | De omgekeerde aanloop (0,35 s) is een derde van een staart van 1 s; of dat bij D = 60 nog prettig klinkt, hoort bij de vaste D | **Gedaan in deel 2** (§7.2): aanloop 12 ticks |
| 3 | **Muziek-stems van de boss** | De maat (120/90 t) en de aanlopen zijn startwaarden die B-9 zet | **Gedaan in deel 2** (§7.3): 4 stems (harmonium en ritme per fase); de overgangen (`AudioStreamInteractive`) zijn koppeling |
| 4 | **Framexact op de animaties** (Animator §9.1) | Er zijn nog geen animaties | Met de Animator, op de slice-build |
| 5 | **Hoe vaak het plank-signaal klinkt** | Bij D = 60 staat het al aan op het moment dat je keert (combat §7, "Let op"); het meetlog van de bots laat zien of 1× per 30 t genoeg rust geeft | Open: met het meetlog van de bots, bij de koppeling |
| 6 | **Speler geraakt** (VJ-02, 45 t onkwetsbaar) en **slag van speler 2** (ijzer en glas, bible §13) | Niet in §9.3 gevraagd; ze horen bij de speler, niet bij de vijand | **Gedaan in deel 2** (§7.4) |
| 7 | **Eindkwaliteit en `_placeholder` weg** | Kwaliteit ≥ 7 (F2-eis voor de slice), de mixpass van de Audio Director, de luistertest bij MT2/MT3 | Na MT2 |

---

## 6. Open punten en vragen

| Aan | Vraag of punt |
|---|---|
| **Audio Director** | (1) Lead-review van deze set en van het muziekplan. (2) Bible naar D = 60 (kop, §6.1, §9 en §10 staan nog op D = 120) en een besluit over voorstel §5 punt 1. (3) Wanneer gaat de set naar `game/audio/sfx/` (bible §11)? Dan ook de import-instellingen en de lus-punten van de drie `_lus`-bestanden. |
| **Combat Designer** | Beantwoord in `slice-vijanden-en-boss.md` §9.3: de aanloop van de pompslag in fase 1 **blijft 40**; de dreun is een accent tussen de tellen. De stems (§7.3) volgen dat: in fase 1 valt de dreun 10 ticks na tel 2, en daar staat in het ritme niets (tel 2 is een ijzertik, de volgende achtste pas op tick 45). |
| **Audio Director** (deel 2) | Beantwoord in de [Lead-review van PR #274](https://github.com/cesarvangerwen-glitch/echoborn/pull/274#issuecomment-6849135352): (6) akkoord op deel 2. (7) Het echo-niveau blijft zo (dezelfde keten als F2, "jij, maar hol"); geen gain per geluid; in de mixpass kijkt de Audio Director of de echo-slag hoorbaar blijft in een druk gevecht. (8) Lichaamsgeluiden starten op event-tick − 12 uit de opname, de rad-treffer met `play(0.2)` op de treffer-tick (§7.2). (9) −27 per stem is het startpunt; in de mix zet `volume_db` per laag het niveau, de bestanden blijven op −27. Open bij de Audio Director: bible §10 naar v0.6 (bus Echo 0 dB, de voorstartregel). |
| **Gameplay Programmer** (deel 2) | Bij de koppeling: `MerkAudio` met de bestanden van §7.1 (de controle in `deel2/` is het doel om tegen te luisteren en te meten), de bots/het log laten de ticks van de aftelslagen en de voorslag zien (§5 punt 1), en de import van de nieuwe bestanden in Godot draaien (§7.5). |
| **Gameplay Programmer** | Voor de aansluiting later: B-6 levert per aanval een vlag `aanloop`/`actief` en B-10 de events; het geluid hoort op de eerste tick van de aanloop te starten (niet op het actieve vlak), zie §2. Voor de doelstreep: `doelstreep_strength` op de tick van `doelstreep_on` bepaalt wachttijd en beginpunt in het bestand (§3), en de aftelling volgt §3.1. |
| **Audio Director** (#243) | (4) en (5) beantwoord in de [Lead-review van PR #260](https://github.com/cesarvangerwen-glitch/echoborn/pull/260#issuecomment-6845641252): (4) op dezelfde tick waarschijnlijk één vollere slag, vanaf 1 tick verschil twee slagen; akkoord, MT2 en de opname van S6 bevestigen het; terugvaloptie is een tweede variant uit dezelfde set. +3,7 dB samen blijft (HardLimiter op de Master; nameten in de mixpass). (5) `compress/mode` 2 (QOA) is goed voor de placeholder; instellingen bij eindkwaliteit in de assetlijst. |
| **Gameplay Programmer** (#243, koppeling deel 1) | **Staat:** bussen (`game/default_bus_layout.tres`, bible §10 minimaal: Master met HardLimiter −1 dB; Muziek, Omgeving, SFX; onder SFX Speler, Echo (0 dB, §7.2), Combat, UI), `game/scripts/audio/sim_sfx.gd` (SFX starten op een Sim-tick, vaste stemmen, log van de starts), waarden in `game/data/audio.json`; gekoppeld: de pompslag (§1.2, `pumped`), het breekgeluid van het luik en de rad-treffer (P1/P2 `_1`/`_2`, de echo altijd de holle `_1` op Echo met `play(0.2)`). Test: `game/tests/test_audio_pompslag.gd`. **Open, volgende PR:** de rest van de koppeling: `MerkAudio` (§7.1), lichaamsgeluiden en de echo-varianten op event-tick − 12 (§7.2), de Gemaalmeester-set (§2.2), de boss-stems (§7.3), speler geraakt en de slag van P2 (§7.4), de galmbussen en de sidechain (bible §10; tot dan heeft geen enkele SFX een galm-send, dus P1 en de echo ook dezelfde). **Composer/Sound Designer:** geleverd, zie §1.3; het pad van het luik zet de GP (rij hieronder). De `uid` in 18 `.import`-bestanden van PR #274 heeft tekens die Godot niet gebruikt; `--import` herschrijft ze (laden op pad werkt wel). **Audio Director:** klinkt het wegslaan van de schaduwklep door de echo (V-01d) als breken? Nu ja (zelfde geluid als P1); "tijd" is stil. |
| **Audio Director** (#243, Lead-review TD PR #282) | Bible §10 noemt bus Echo **−7 dB**; `game/default_bus_layout.tres` zet hem op **0 dB**, omdat de −7/−8 dB al in de varianten zit (§7.2, Lead-review PR #274). Zet bible v0.6 gelijk met de layout. |
| **Gameplay Programmer** (#243, Lead-review TD PR #282) | Zodra de galmbussen er zijn (bible §10, volgende koppeling): de pompslag van de echo krijgt **dezelfde galm-send** als die van P1, met een controle in `game/tests/test_audio_pompslag.gd` (nu heeft geen enkele SFX een galm-send). |
| **Gameplay Programmer** (#243, §1.3) | Zet `luik_breekt.stream` in `game/data/audio.json` op `res://audio/sfx/omgeving/luik_breekt_placeholder.wav` en geef het stille luik in `test_luik_zelfde_breekgeluid` zelf `audio.sfx = null`; dan klinkt het luik. De rad-treffers van P1/P2 klinken al (paden stonden klaar). |
| **Audio Director** (#243, §1.3) | **Gesloten** ([Lead-review PR #283](https://github.com/cesarvangerwen-glitch/echoborn/pull/283#issuecomment-6868765559)): (a) ja, het wegslaan van de schaduwklep door de echo klinkt als breken, met hetzelfde bestand op volle sterkte. Er komt geen holle variant, ook al staat "schaduwlaag" in de echo-kolom van bible §4: de neerslag van de echo doet in de regels wat die van P1 deed (de klep gaat weg, de echo valt erdoor), dus geldt §4.1. "Tijd" blijft stil. (b) −15 LUFS: akkoord. |
| **Audio Director** (mixpass MT2) | In S7 staan de luiken vlak bij de Dwaallichten, waarvan de tells ook op −15 staan. Maskeert het luik een tell, dan gaat `luik_breekt.volume_db` naar −1 dB; het bestand verandert niet. |
| **Audio Director** (bible v0.6) | Bus Echo op 0 dB, zoals in `default_bus_layout.tres`, en de schaduwklep als regel in de tabel van §4.1. |
| **Iedereen** | Niemand in de studio kan luisteren. De metingen (niveaus, stijging, aandeel boven 250 Hz, tickduur) bewijzen de vorm, niet dat het goed klinkt. Het eerste echte oordeel is de luisterreeks bij de Audio Director en het spel bij MT2. |

**Beperkingen:** de geluiden zijn placeholder (eerste versie, niet beluisterd); de grootste risico's zijn dat de stoom van de pompslag en de schraap van de Kadeloper te veel op ruis lijken, en dat de maat-tel (± 55 keer per gevecht) gaat vervelen ondanks de demping. Twee bestanden liggen vooral onder 250 Hz (`gm_wankel_start` en de Wankel-lus, 20–27 % erboven): dat mag, omdat hun informatie de **stilte** van het carillon is, niet het geluid zelf.

## 7. Deel 2: wat op D = 60 vastzit

**Script:** `docs/audio/t8d-slice/bron/genereer_slice_deel2.py` (± 25 s, vaste seeds, importeert het script van deel 1 en het F2-script). De WAV-bestanden zijn **byte-gelijk** opnieuw te maken (twee runs, zelfde md5 voor alle 23 WAV's); de OGG-bestanden hangen van de ffmpeg-versie af. Metingen in `docs/audio/t8d-slice/deel2/meting_placeholder.json` (zelfde velden als deel 1, plus aanzet in ticks, clipping en de lusnaad). Alles is placeholder (`_placeholder`); speelbare bestanden staan in `game/audio/` (bible §11), elk met een `.import` (§7.5).

**Hoe te controleren:** `python3 docs/audio/t8d-slice/bron/genereer_slice_deel2.py` vanaf de repo-root; luisteren naar `deel2/aftelling_d60_controle_placeholder.wav` en `deel2/boss_stems_samen_placeholder.ogg`.

### 7.1 Merk-aftelling op D = 60 (§3.1, bible §6.1, §10 `MerkAudio`)

`game/audio/sfx/combat/`, mono, 48 kHz, 16 bit. De klokken zijn die van F2 (A5, B5, C♯6; grijs zonder terts), maar **1,0 s** in plaats van 1,6 s: bij D = 60 valt de knal 33 ticks na slag 1, en een korte staart laat de knal schoner staan.

| Bestand | Wanneer (solo, D = 60) | Duur | Niveau (max. momentaan) | True peak |
|---|---|---|---|---|
| `merk_zet_grijs` / `_kleur` | t 0 | 54 t | −22 LUFS | ≤ −7,7 dBTP |
| `aftelling_1_grijs` / `_kleur` (A5) | t 30 (`L − 60`) | 60 t | −19 | ≤ −6,1 |
| `aftelling_2_*` (B5) | t 45 | 60 t | −17,5 | ≤ −4,5 |
| `aftelling_3_*` (C♯6) | t 60 (= D) | 60 t | −16 | ≤ −3,0 |
| `aftelling_4_zacht_*` (C♯6, 6 dB zachter) | t 75 | 60 t | −22 | ≤ −9,9 |
| `merk_dooft` | t 90 (einde levensduur) | 60 t | −19 | −5,3 |
| `doelstreep_voorslag_*` (byte-gelijk uit deel 1) | t 33 → eindigt op t 63 | 30 t | −27 | ≤ −13,3 |

De niveaus volgen de verhoudingen van de levensduurreeks in F2 (−6 / −4,5 / −3 / −9 dB, zetten −9, doven −6) rond slag 3 = −16: onder de tells (−15) en onder de knal (−13), zoals de voorrang van bible §8. Alle bestanden: 100 % boven 250 Hz, aanzet op tick 0,0, 0 clipping. Co-op gebruikt dezelfde bestanden op t 90/105/120/135/150.

**Controle** (`docs/audio/t8d-slice/deel2/aftelling_d60_controle_placeholder.wav`, 18,6 s, grijs): de vier situaties van §3.1 achter elkaar. Teruggemeten aanzet (−20 dB van de piek) in ticks na het zetten:

| Situatie (start in het bestand) | Gezet op | Gemeten |
|---|---|---|
| A geen doelstreep (0,0 s) | 30 / 45 / 60 / 75, doven 90 | 29,99 / 44,99 / 60,00 / 74,99, doven 90,00 |
| B doelstreep op dit merk (4,5 s) | slag 1 op 30, voorslag 33 → knal 63 | 29,99; voorslag eindigt op **63,00**; knal (ontploffing k1) **62,97** |
| C streep weg op t 50 (8,55 s) | slag 1 op 30, voorslag uit op 50 (30 ms), slag 3 op 60, slag 4 op 75, doven 90 | 29,99; voorslag stil op 51,78; 60,00 / 74,99 / 90,00 |
| D co-op (13,05 s) | 90 / 105 / 120 / 135, doven 150 | 89,99 / 104,99 / 120,00 / 134,99 / 150,00 |

### 7.2 Echo-varianten (bible §4, `echo_versie`)

`game/audio/sfx/echo/`. Afgeleid van het levende geluid met de keten van F2 (hoogdoorlaat 260 Hz, holle kam 4,6 ms, band 0,7–4,2 kHz, Haas 11 ms, −7 dB voor een slag en −8 dB voor beweging), met één verschil: de **omgekeerde aanloop is 12 ticks** (0,2 s) in plaats van 0,35 s (21 ticks).

**Waarom 12.** P1 kan om de 20 ticks slaan (LM-04). Met 21 ticks begint de aanloop van elke echo-slag **vóór de vorige echo-slag** (3 van 3 in een reeks op 20 ticks): je hoort de echo dan "voorlopen" op een slag die nog moet komen. Met 12 ticks gebeurt dat 0 keer, en de aanloop is 20 % van de staart (was 35 %). De omgekeerde galm blijft hoorbaar als "het komt uit het verleden terug".

| Bestand | Van | Duur | Niveau | Onder levend | Boven 250 Hz |
|---|---|---|---|---|---|
| `echo_slag` (stereo) | `speler/p1_slag` | 42 t (12 + 30) | −28,3 LUFS | −10,7 LU | 93,7 % |
| `echo_sprong` (stereo) | `speler/p1_sprong` | 30 t | −36,6 | −12,6 LU | 96,3 % |
| `echo_landing` (stereo) | `speler/p1_landing` | 33 t | −37,3 | −15,3 LU | 92,2 % |
| `echo_gm_rad_treffer_1` (mono, `AudioStreamPlayer2D` op het rad) | `gm_rad_treffer_1` uit deel 1 | 78 t | −25,4 | −8,4 LU | 99,5 % |

**Niveau:** de −7 dB (slag) en −8 dB (beweging) van bible §4 **zitten al in het bestand**. Zet er geen −7 dB van de bus Echo (bible §10) bovenop, anders komt de echo −17,7 tot −22,3 LU onder het levende geluid (Lead-review PR #274; bible §10 gaat naar bus Echo 0 dB in v0.6).

**Aansluiten:** de treffer zit in het echo-bestand **12 ticks later** dan in het levende bestand.
- **Lichaamsgeluiden** (`echo_slag`, `echo_sprong`, `echo_landing`): die liggen vast in de opname, dus de code weet ze D ticks vooruit. Start het echo-geluid op **event-tick − 12** van de afspeling.
- **`echo_gm_rad_treffer_1`: altijd `play(0.2)` op de treffer-tick** (zonder aanloop). Of de echo het rad raakt, weet de code pas op die tick (de boss beweegt); een aanloop vooraf zou een treffer beloven die misschien niet komt (bible §4.1).
- **Breekt de echo of raakt hij Leeg** tijdens een lopende aanloop: in 30 ms uitfaden, net als bij de voorslag (§3). Geen echo-variant voor de pompslag, de luiken en de ontploffing (bible §4.1), en nooit voor `gm_rad_treffer_2`. P2 heeft geen echo-variant: in co-op is er geen echo.

De levende bronnen staan in `game/audio/sfx/speler/`: `p1_slag` (30 t, −17,6 LUFS, door de true-peak-grens van −1,5 dBTP 1,6 dB onder het doel van −16), `p1_sprong` (18 t, −24), `p1_landing` (21 t, −22; 7,4 % boven 250 Hz, zoals in F2: het lijf is de landing, de spatbelletjes geven het hoge deel).

### 7.3 Boss-stems (§4.4, §4.5)

`game/audio/muziek/kadewijk/`, OGG Vorbis (q5), stereo, 48 kHz. Elke stem is precies 16 maten en loopt over het hele bestand (`loop=true`, `loop_offset=0`; `bpm`, `beat_count` en `bar_beats` in de `.import`, voor `AudioStreamInteractive`). De galm en de staarten van het eind zijn over het begin gevouwen, zodat de lus geen gat en geen stap heeft.

| Bestand | Maat | Duur | Wat | LUFS (geïntegreerd) | True peak na decoderen | Boven 250 Hz |
|---|---|---|---|---|---|---|
| `boss_fase1_harmonium` | 4/4, 120 t | 32,0 s = 1920 t | Bourdon D2–A2 (lege kwint, geen terts) + **M2** (D–C♯–B–A) in het laag (D3…A2), één noot per maat; maat 9–16 met een herhaling op tel 4 | −27,0 | −15,7 dBTP | 39,9 % |
| `boss_fase1_ritme` | 4/4 | 32,0 s | Gemaal: plof + ijzertik op tel 1, ijzertik op tel 2 en 4, houtklop op tel 3, zachte houtklop op de achtsten, 50 Hz-brom | −27,0 | −12,3 | 47,0 % |
| `boss_fase2_harmonium` | 3/4, 90 t | 24,0 s = 1440 t | Bourdon + **M2 een octaaf hoger** (D4…A3) | −27,0 | −16,4 | 80,4 % |
| `boss_fase2_ritme` | 3/4 | 24,0 s | Plof + ijzertik op tel 1, **water van de schoepen op tel 2 en 3**, achtsten | −27,1 | −12,5 | 34,5 % |
| Samen fase 1 / fase 2 | | | | −24,0 / −24,0 | −9,4 / −11,1 | |

- **Tells eerst** (bible §8): op tel 1 speelt de muziek geen klok; de carillon-tel van het SFX (`gm_maat_tel`, D4) blijft vrij. De dreun van de pompslag in fase 1 (40 ticks, 10 ticks na tel 2) valt op een plek zonder slag in het ritme.
- **Lengte na decoderen:** precies 1 536 000 en 1 152 000 samples (gelijk aan de bron).
- **Lusnaad** (na decoderen): de 250 ms rond de naad tegenover de 250 ms rond de maatgrens halverwege (zelfde muzikale plek) verschillen **−0,5 tot +1,2 dB**; de sprong van het laatste naar het eerste sample is kleiner dan de gewone sprong tussen twee samples (99e percentiel), in alle stems. Geen klik te meten.
- **Luisterbestand:** `docs/audio/t8d-slice/deel2/boss_stems_samen_placeholder.ogg` (112 s): fase 1 twee keer rond, dan fase 2 twee keer rond; naden op 32, 64 (wissel) en 88 s.
- **Niet gemaakt:** de overgangen (fasewissel, Wankel = muziek weg, na de boss stilte, §4.4) zijn regels voor `AudioStreamInteractive`, dus koppeling; de verkenlagen (75 BPM, 51,2 s) zijn de tweede muziektaak van §4.5.

### 7.4 Speler geraakt en de slag van P2 (§5 punt 6)

`game/audio/sfx/speler/`, mono.

| Bestand | Klank | Duur | Niveau | Boven 250 Hz |
|---|---|---|---|---|
| `p2_slag` | Ijzer en glas (bible A5, de pikhaak): zwaai, klik van 1 ms, een ijzeren staaf (412 Hz, modi 1 : 2,76 : 5,40 : 8,93), glazen naklank (2,9–6,7 kHz), kort lijf. Zelfde opbouw en treffer-moment (0,06 s) als `p1_slag` | 30 t | −17,5 LUFS (TP-grens) | 88,1 % |
| `p1_geraakt` / `p2_geraakt` | Doffe stoot, het eigen materiaal met een kleine secunde erbij ("iets klopt niet"), adem eruit | **40 t**: korter dan de 45 ticks onkwetsbaarheid (VJ-02), dus nooit twee tegelijk | −15,0 / −15,4 | 75 % |

### 7.5 Import in Godot

Godot draait niet in deze omgeving en CI start nu geen jobs. De `.import`-bestanden zijn door het script geschreven in het formaat van `pompslag_schoep_placeholder.wav.import` (Godot 4.6.3, standaardinstellingen, `compress/mode=2`); het pad in `.godot/imported/` gebruikt dezelfde md5 van het `res://`-pad als Godot (nagerekend op de pompslag), en de `uid` is vast per pad. Voor de OGG-stems is het formaat dat van de importer `oggvorbisstr` (`loop`, `loop_offset`, `bpm`, `beat_count`, `bar_beats`). **Nog te doen:** `godot --headless --path game --import` en de CI-controle draaien; past Godot een `.import` aan, dan zijn die wijzigingen leidend.

---

## 8. Wijzigingen

| Versie | Wat |
|---|---|
| 0.2.1 | #243 (§1.3): `luik_breekt_placeholder.wav` (42 t, −15,0 LUFS, −1,8 dBTP, 41,3 % boven 250 Hz) en de levende `gm_rad_treffer_1`/`_2` (byte-gelijk aan deel 1) in `game/audio/sfx/`, met `.import` van Godot 4.6.3; open punten voor GP (pad van het luik + test) en Audio Director in §6. Na de Lead-review (PR #283): GP-rij verwijst naar §1.3, de AD-vraag gesloten (schaduwklep = breken, −15 LUFS akkoord), open punten mixpass MT2 en bible v0.6. |
| 0.2 | **Deel 2** (§7): merk-aftelling op D = 60 gerenderd en gezet (§7.1) met een controle van de vier situaties van §3.1 (aanzet binnen 0,03 tick, voorslag eindigt op t 63, knal 62,97); echo-varianten met een aanloop van 12 ticks (§7.2); vier boss-stems als lus (§7.3); speler geraakt en de slag van P2 (§7.4); 23 WAV's en 4 OGG's in `game/audio/` met `.import` (§7.5). §0 en §5 bijgewerkt; open punt van de Combat Designer gesloten (aanloop fase 1 blijft 40); nieuwe open punten (6)–(9) voor de Audio Director. Na de Lead-review (PR #274): rad-treffer van de echo met `play(0.2)` op de treffer-tick en 30 ms uitfaden (§7.2), de −7/−8 dB zit in het bestand (§7.2), §0 verwijst naar §7, true peaks en aandeel boven 250 Hz in §7.3 gelijk aan de JSON, antwoorden (6)–(9) in §6. |
| 0.1.2 | Luisterfragment voor de luistercheck in MT2 (§1.1, V-10 van `docs/qa/testplan-mt2.md`): v2 ongewijzigd op 0,0 s plus de stukken per vraag naast elkaar, 66,6 s, −18,0 LUFS, −1,5 dBTP na decoderen. Sample `pompslag_schoep_placeholder.wav` in `game/audio/sfx/omgeving/` (§1.2, #243): 28 ticks, −17,0 LUFS momentaan, −1,8 dBTP, 44,8 % boven 250 Hz, met de controle P1 + echo (−1 halve toon) op dezelfde tick. Na de Lead-review (PR #260): kop naar bible v0.5 en #243, open punten (4) en (5) verwijzen naar die review. |
| 0.1.1 | Lead-review Audio Director (PR #193, klein): timing van de doelstreep-voorslag gecorrigeerd (streep aan op t 30, voorslag t 33 → knal t 63; wachttijd en beginpunt in §3); besluit over de aftelling naast de doelstreep opgenomen (§3.1, §5 punt 1); zin over het aandeel boven 250 Hz klopt nu voor de maat-tel (§2); `schotdrager_aanloop` met de piek in de laatste 3 ticks (§2.1). |
| 0.1 | Eerste versie (T8d deel 1, #86): 72 placeholder-SFX (vijanden, Gemaalmeester, finisher, ketting, signalen) met tabel en metingen, luisterreeks, signalen voor plank en doelstreep, muziekplan grijs → licht met de motieven M1/M2, en wat pas na de vaste timing kan. |
