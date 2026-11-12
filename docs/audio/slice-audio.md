# Slice-audio (T8d), deel 1: SFX-set, signalen en muziekplan

Versie 0.1 · 2026-11-12 · Eigenaar: **Composer/Sound Designer** · Lead-review: Audio Director · Issue [#86](https://github.com/cesarvangerwen-glitch/echoborn/issues/86) (T8d, `docs/productie/fase-2-kader.md` v0.4 §2 en §4)
Bouwt op: `docs/audio/bible.md` v0.3 (§2–§8, §10, §11), `docs/design/combat/slice-vijanden-en-boss.md` v0.1.1 (§2, §3, §7, §9), `docs/design/gdd.md` v0.8 (E-02t, E-07d, E-14b, C-12e, C-14), `docs/design/wereld.md` §2.2 (kamerlijst S1–S9), `game/scripts/echo/echo_hints.gd` (signalen `plank_signal_on`, `doelstreep_on`).

Dit is **deel 1** van T8d: alles wat **niet** van de staart D afhangt. Het F2-fragment (`docs/audio/f2-fragment/`) is de klankbron: dezelfde klokken, hetzelfde water en dezelfde `echo_versie`, want de CEO vond de F0-geluiden "heel leuk" en het fragment klonk als een beiaard en "jij, maar hol". Deel 2 (na de vaste timing) staat in §5.

---

## 0. Werkaanname (kader §5)

| Bron | Wat dit deel ervan gebruikt |
|---|---|
| CEO-besluit 2026-11-12 (#80) | **D = 60 ticks (1 s)** is de werkaanname, bereik 1–3 s. Geen enkel bestand in deze set hangt van D af: de set blijft geldig als D verandert. Wat wel van D afhangt (aftelling, echo-timing), wacht op deel 2 (§5). |
| CEO-besluit 2026-11-12 (#80) | Fase 2 parallel: T8d deel 1 wacht niet op een geslaagde flow-test. De CEO test alleen bij mijlpalen (MT2/MT3); tot dan meten we en beoordeelt de Audio Director. |
| Fasekader v0.4 §4, regel tegen weggooiwerk | Eerst placeholder: alles hier heet `_placeholder` (`WERKWIJZE.md` §9) en staat in `docs/audio/`, niet in `game/`. Alle tijden komen uit één bron (het script, met tickwaarden uit `slice-vijanden-en-boss.md`), zodat een andere aanloop één getal is. |
| `slice-vijanden-en-boss.md` §0 | Alle tick-tijden zijn **startwaarden** van de Combat Designer (gezet met B-9). Verandert een aanloop, dan render ik het bestand opnieuw met het nieuwe getal (± 10 s). |
| Bible v0.3, kop | 60 Hz-tick, € 0 extern, eigen synthese; speler 1 altijd "in kleur". De bible staat nog op D = 120; dat verandert de Audio Director (§6). |

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

---

## 2. De SFX-set: event → bestand → duur → leesbaarheid

**Regel voor elk aanloop-bestand:** het duurt **precies** zijn aanloop en eindigt op de tick waarop het actieve vlak begint. De code start het op het begin van de aanloop (de vlag `aanloop` van B-6); dan valt het hoogtepunt vanzelf framexact op de slag. Elke aanloop **stijgt** (gemeten: laatste 100 ms tegenover de eerste 100 ms, kolom "↑"), dus je hoort *wanneer*; de klankvorm verschilt per aanval, dus je hoort *wat* en *waar* (§9 van het combat-document: "de aanloop toont waar het vlak komt, niet alleen dat er iets komt"). Alle tells liggen voor ≥ 97 % boven 250 Hz: hoorbaar op de Deck en een tv (bible §8.2).

Paden: `docs/audio/t8d-slice/sfx/<map>/<naam>_placeholder.wav`. Duur in ticks (60/s).

### 2.1 Vijanden

| Event (code) | Bestand (`vijanden/`) | Duur | Hoe het de tell leesbaar maakt |
|---|---|---|---|
| Kadeloper: haakslag, aanloop (B-2, `aanloop`) | `kadeloper_aanloop` | **30** t (0,5 s), ↑ 14 dB | IJzer schraapt over steen: schokjes die **versnellen** (22 → 82 per s) en een toon die met de haak **meestijgt**; eindigt met één droge tik = de haak op zijn top. Ruisachtig en hoog (zwaartepunt ± 2,9 kHz): "dichtbij, op de grond, ga weg of spring" |
| Kadeloper: haakslag, actief 6 t | `kadeloper_haakslag` | 24 t (0,4 s) | Veeg die in 6 ticks **daalt** (3,4 → 0,7 kHz) + korte ijzerklank: de slag zelf, ook als hij mist |
| Kadeloper/Schotdrager: dood | `kadeloper_dood` | 54 t | Slok + dalende bellen: lost op in donker water (§9.1), zacht, geen vleesgeluid (PEGI 12) |
| Schotdrager: schotstoot, aanloop | `schotdrager_aanloop` | **30** t, ↑ 9 dB | **Piepend roestig scharnier** (een toon met ruwheid, 330 → 560 Hz) + rammelende plaat. Tonaal en lager dan de Kadeloper: je hoort aan de klank dat het de gepantserde is, vóór je hem ziet |
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
| `doelstreep_on(tick, mark_id)` (E-02t) | `doelstreep_voorslag_grijs` (`_kleur` in S9) | **30 t** (0,5 s) | −27 LUFS, ↑ 37 dB | **Carillon-voorslag**: een omgekeerd klokje (E6) dat aanzwelt en **precies op de slag van de echo ophoudt**; de knal neemt het over. Geen aanslag, dus het lijkt niet op een aftelslag | Start bij `doelstreep_on`, **met beginpunt** `(1 − doelstreep_strength) × 0,5 s` in het bestand: komt de streep later dan 30 t vóór de slag aan, dan valt het eind toch op de slag. **Eén voorslag per `mark_id`**: springt de streep naar een ander merk, dan loopt de lopende voorslag door (geen tweede); verdwijnt de streep (`doelstreep = false`), dan 30 ms uitfaden. Max. 1 tegelijk |

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
| 1 | **Merk-aftelling op D = 60** (E-14b): solo leeft een merk 90 t, de aftelslagen vallen op t 30, 45, 60, 75 na het zetten | Hangt aan D. Twee nieuwe dingen bij D = 60: (a) de echo knalt op **D + 3 = 63**, niet op 60 (bible §6.1 "boem op slag 3" klopt dus op 3 ticks na); (b) de **doelstreep start op t 33**, vlak na aftelslag 1 (t 30): de voorslag en de aftelling lopen over elkaar. **Voorstel:** slag 3 vervalt als de doelstreep op dat merk aanstaat (de streep voorspelt de knal), en de voorslag vervangt bij D = 60 slag 2. In co-op (150 t, C-12e) blijft de aftelling zoals ze is (t 90–135). Beslissing: Audio Director, met de LGD | Na een groene bot-run op D = 60 |
| 2 | **Echo-varianten** van de slice-geluiden (bible §4: afgeleid met `echo_versie`) | De omgekeerde aanloop (0,35 s) is een derde van een staart van 1 s; of dat bij D = 60 nog prettig klinkt, hoort bij de vaste D | Deel 2 |
| 3 | **Muziek-stems van de boss** | De maat (120/90 t) en de aanlopen zijn startwaarden die B-9 zet | Na B-9/B-10 en de waarden van de Combat Designer |
| 4 | **Framexact op de animaties** (Animator §9.1) | Er zijn nog geen animaties | Met de Animator, op de slice-build |
| 5 | **Hoe vaak het plank-signaal klinkt** | Bij D = 60 staat het al aan op het moment dat je keert (combat §7, "Let op"); het meetlog van de bots laat zien of 1× per 30 t genoeg rust geeft | Deel 2, met het log van B-9 |
| 6 | **Speler geraakt** (VJ-02, 45 t onkwetsbaar) en **slag van speler 2** (ijzer en glas, bible §13) | Niet in §9.3 gevraagd; ze horen bij de speler, niet bij de vijand | Deel 2 (voorstel) |
| 7 | **Eindkwaliteit en `_placeholder` weg** | Kwaliteit ≥ 7 (F2-eis voor de slice), de mixpass van de Audio Director, de luistertest bij MT2/MT3 | Na MT2 |

---

## 6. Open punten en vragen

| Aan | Vraag of punt |
|---|---|
| **Audio Director** | (1) Lead-review van deze set en van het muziekplan. (2) Bible naar D = 60 (kop, §6.1, §9 en §10 staan nog op D = 120) en een besluit over voorstel §5 punt 1. (3) Wanneer gaat de set naar `game/audio/sfx/` (bible §11)? Dan ook de import-instellingen en de lus-punten van de drie `_lus`-bestanden. |
| **Combat Designer** | Mag de aanloop van de pompslag in fase 1 van **40 naar 30 of 60 ticks** (één of twee tellen bij 120 BPM)? Niet nodig voor de leesbaarheid, wel voor muziek die met de maat meetelt (§4.4). Blijft het 40, dan valt de slag gewoon tussen de tellen. |
| **Gameplay Programmer** | Voor de aansluiting later: B-6 levert per aanval een vlag `aanloop`/`actief` en B-10 de events; het geluid hoort op de eerste tick van de aanloop te starten (niet op het actieve vlak), zie §2. Voor de doelstreep: `doelstreep_strength` op de tick van `doelstreep_on` bepaalt het beginpunt in het bestand (§3). |
| **Iedereen** | Niemand in de studio kan luisteren. De metingen (niveaus, stijging, aandeel boven 250 Hz, tickduur) bewijzen de vorm, niet dat het goed klinkt. Het eerste echte oordeel is de luisterreeks bij de Audio Director en het spel bij MT2. |

**Beperkingen:** de geluiden zijn placeholder (eerste versie, niet beluisterd); de grootste risico's zijn dat de stoom van de pompslag en de schraap van de Kadeloper te veel op ruis lijken, en dat de maat-tel (± 55 keer per gevecht) gaat vervelen ondanks de demping. Twee bestanden liggen vooral onder 250 Hz (`gm_wankel_start` en de Wankel-lus, 20–27 % erboven): dat mag, omdat hun informatie de **stilte** van het carillon is, niet het geluid zelf.

## 7. Wijzigingen

| Versie | Wat |
|---|---|
| 0.1 | Eerste versie (T8d deel 1, #86): 72 placeholder-SFX (vijanden, Gemaalmeester, finisher, ketting, signalen) met tabel en metingen, luisterreeks, signalen voor plank en doelstreep, muziekplan grijs → licht met de motieven M1/M2, en wat pas na de vaste timing kan. |
