# Audio bible v0: audiorichting

Versie 0.1 · Eigenaar: Audio Director · Issue: #66 (T2 uit `docs/productie/fase-2-kader.md` §2) · Met: Composer/Sound Designer · Basis: pitch v0.4 (besluit #51), art bible v0 (`docs/art/bible.md`), `docs/design/gdd.md` (E-02, E-14, C-14)

Deze bible legt vast hoe *Polderlight* (werktitel, besluit #96) klinkt en wat elke audiorol moet halen. Ze is **v0**: genoeg voor de grijze flow-kamer en voor het F2-fragment. Muziek per gebied en de assetlijst volgen in v1 (§13).

**Werkaannames** (fasekader §5):
- **Staart D = 120 ticks** (± 2 s, besluit #51: 8A; bereik 90–180) op de vaste simulatietick van **60 Hz** (`docs/tech/ontwerp.md` §2).
- **Merk leeft D + 30 ticks en telt de laatste 60 ticks af** in beeld en geluid (E-14b, startwaarden van de LGD). Het ritme van de aftelling in §6 hangt hieraan.
- **Co-op 7A** (#51): solo speler 1 + echo, co-op speler 1 + speler 2, nooit meer dan twee lichamen, plus de gedeelde echo als finisher (C-14).
- **€ 0 extern** (fasekader §7): alle audio is eigen synthese met code. Geen externe samples, bibliotheken of plug-ins zonder licentie in `docs/licenties.md`.
- **Speler 1 is altijd "in kleur"** (art bible §5): zijn geluid blijft vol, ook in een grijze wijk.

---

## 0. Akkoord op de F2-eis (A10)

**Ik bevestig de eis van F2:** één referentiefragment haalt rubric-Kwaliteit ≥ 7 **vóór** slice-audio (T8d) start, en daarna haalt de slice-audio zelf ook ≥ 7. Haalt het fragment geen 7, of twijfel ik als Audio Director, dan geen slice-audio op die basis maar een `brainstorm`-issue met de CEO (fasekader §4).

Twee preciseringen, zodat de eis toetsbaar is:

1. **Wat het fragment moet dragen.** Niet "mooi geluid" in het algemeen, maar de drie dingen waar de pillars van afhangen: (a) de **merk-aftelling met het carillon** (R-V1, E-14b), (b) een **echo die je hoort als jezelf, maar hol** (pillar 1, gdd O-4), en (c) **grijs → leven** (pillar 2). Het fragment in §9 bevat alle drie.
2. **Hoe het beoordeeld wordt.** Geen rol in de studio kan luisteren; we beoordelen met metingen. Daarom haalt het fragment eerst de **harde drempels** uit §8 (loudness, piek, hoorbaarheid boven het bed). Daarnaast stel ik voor dat de Kwaliteit-score pas telt **met één luistercheck door een mens** (de CEO, ± 5 minuten, op koptelefoon en op tv-luidsprekers, drie vragen: klinkt het als een carillon, hoor je dat de tweede slag "jij maar hol" is, voelt het opgepompte deel warmer). Dat is een voorstel aan de EP, eigenaar van het kader; het kost ± 5 min CEO-tijd en 0 runs.

---

## 1. Het geluid in één zin

**De stad is stil en hol tot jij het licht terugbrengt; het carillon telt de echo af, en wat leeft heeft een lijf.**

Melancholisch, niet wanhopig (pitch §6). Stilte en water dragen het grijze deel; warmte komt terug met het licht. Niets klinkt als horror: geen gekrijs, geen jumpscare-stingers, geen vleeswonden (PEGI 12).

## 2. Pijlers voor audio

Elke audiopijler hangt aan een design pillar. **Toetsvraag voor elk geluid:** *Vertelt dit geluid de speler iets wat hij in beweging nodig heeft, en zou hij het missen als het weg was?*

| # | Pijler | Hangt aan | Wat het betekent |
|---|---|---|---|
| A1 | **De echo klinkt als jij, maar hol** | P1 | De echo speelt hetzelfde geluid als zijn eigenaar, met hetzelfde ritme en dezelfde toonhoogte, maar zonder lijf en door een holle buis (§4). Je herkent je eigen slag een tel later terug. Antwoord op gdd **O-4**: ja, de echo speelt audio af, gedempt (−7 tot −8 dB), ook om hem buiten beeld te volgen. |
| A2 | **Het carillon is de klok van de echo** | P1, R-V1 | Het merk telt af met vier carillonslagen. De echo komt altijd op slag 3: "één, twee, **boem**" (§6). |
| A3 | **De terts komt terug met het licht** | P2 | Grijs klinkt in lege kwinten en klokken zonder terts. Pomp je licht in, dan keert de terts terug: in de klokken, in de muziek, in de galm (§5). |
| A4 | **Leesbaarheid vóór sfeer** | P2 (pitch: "Gevolg voor Art en Audio") | Spelinformatie (merk, aftelling, tells, echo) heeft altijd voorrang in de mix; sfeer wijkt (§8). |
| A5 | **Twee spelers, twee materialen** | P3 | Speler 1 (amber) = warm koper en hout; speler 2 (cyaan) = ijzer en glas (zijn pikhaak). De gedeelde echo (finisher) = beide materialen om en om, met het volle carillon (§6). Zo volgt audio de kleurregel van de art bible §6. |

## 3. Palet van klanken

We kiezen bewust instrumenten die **met code op eindkwaliteit te maken zijn** (R22). Klokken, rietorgels, getokkelde snaren en machines zijn in essentie sommen van trillende modi; die laten zich goed synthetiseren. Strijkers, koor en stemmen niet: die vragen opnames of samplebibliotheken (licentie, kost).

| Familie | Klank | Waar | Hoe gemaakt | Haalbaar met code? |
|---|---|---|---|---|
| **Carillon** | Klokken met de partialen van een minor-terts-klok: hum 0,5, prime 1, terts 1,2, kwint 1,5, nominaal 2, deciem 2,5, … | Merk, aftelling, ontploffing, oppompen, muziekmotief | Modale synthese met doubletten (het trage zweven van brons) en een klepelaanslag | **Ja**: de meting bevestigt de partialen (§9) |
| **Rietorgel / harmonium** | Kerk- en huiskamerorgel uit de Lage Landen, met balgadem | Muziek: grondlaag en akkoorden | Additief (riettoon) met trage ademmodulatie | Ja, met werk aan de aanzet en het riet-geruis |
| **Bourdon** | Lege kwint, laag, onveranderlijk | Muziek in grijs | Twee rietstemmen, dof gefilterd | Ja |
| **Hakkebord / luit** | Getokkelde snaar | Muziek: melodie in opgepompte wijken (v1) | Karplus-Strong | Ja |
| **Machine** | Pompslag, schoepenrad, koppeling, 50 Hz-brom | Gemaal, Gemaalmeester | Modaal metaal + gefilterde ruis + lage sinusplof | Ja |
| **Water en wind** | Kabbelen tegen kademuren, leeglopen, druppels | Omgeving | Gefilterde roze ruis, korrels | **Twijfel**: het zwakste deel van de synthese (§9) |
| **Stilte** | Bijna niets | Na een gevecht, bij bevroren echo's | — | — |

**Niet in het palet:** orkeststrijkers, koor, zang, elektronische bas-drops, epische trailer-percussie. Ze passen niet bij de toon, of we halen ze niet op eindkwaliteit zonder externe samples.

**Toonsoort:** het carillon en de muziek van het eerste gebied staan in **D**. Grijs: D en A (lege kwint). Opgepompt: D-groot met de None (D, F♯, A, E). Elk gebied krijgt in v1 een eigen grondtoon en motief.

## 4. Echo-klank tegenover levende klank

| Eigenschap | Levend (speler 1, speler 2) | Echo (en schaduwlaag) | Gemeten in het fragment (§9) |
|---|---|---|---|
| Lijf | Laag in de aanslag (plof < 250 Hz) | Geen lijf: hoogdoorlaat op 260 Hz | Aandeel 60–250 Hz: P1 46 %, echo 19 % |
| Kleur | Vol spectrum, lucht boven 8 kHz | Holle buis: terugkoppelende kam van 4,6 ms (resonanties om de ± 217 Hz), band 0,7–4,2 kHz | > 8 kHz: P1 4,2 %, echo 0,7 % |
| Aanzet | Direct, met transiënt | **Omgekeerde aanloop**: de galm van de slag, achterstevoren, eindigt op de slag. Het geluid komt uit het verleden terug | — |
| Plaats | In het midden van zijn lichaam | Breder (Haas 11 ms) en iets achter het beeld | Stereocorrelatie van de mix 0,62 |
| Niveau | Referentie | −7 dB (slag), −8 dB (beweging) | — |
| Timing | Op de event-tick | Op de event-tick van de afspeling (D ticks later), **framexact**, nooit gequantiseerd | — |

**Regel voor de Composer:** maak geen apart echo-geluid. Maak het levende geluid en leid de echo-versie ervan af met dezelfde keten (functie `echo_versie` in het script van §9). Zo klopt "dat ben jij" altijd.

## 5. Van grijs naar leven

| | Grijs (nog niet opgepompt) | Overgang (oppompen, ± 2 s) | Opgepompt |
|---|---|---|---|
| **Klokken** | Zonder terts, licht valser (partialen uitgerekt), dof (laagdoorlaat ± 2,6 kHz) | — | Volle klok, met terts en heldere bovenpartialen |
| **Muziek** | Bourdon: lege kwint D–A, ver weg | De terts (F♯) zwelt aan met een grote klok op D4 | Harmonium D-groot add9; later melodie (hakkebord) |
| **Omgeving** | Water dof en dichtbij, wind, druppels, een verre verzonken klok | Water loopt gorgelend weg, de machine slaat aan | Water helderder en verder, het gemaal draait (pompslag elke 0,8 s, 50 Hz-brom) |
| **Galm** | "Verzonken": RT60 ± 2,1 s, donker (1,5 kHz), smal | Kruisfade over ± 2 s, met de kleurgolf mee | "Belfort": RT60 ± 2,9 s, warm (5,2 kHz), breed |
| **Echo** | Hol, grijs | Kleurt mee met ± 0,5 s vertraging (art bible §5) | Hol, maar met meer lucht |
| **Speler 1** | Vol (altijd in kleur) | — | Vol |

Gemeten op de **wereld zonder spelers** (bed, muziek, galm): opgepompt heeft 4× zoveel energie in 2–8 kHz (4,6 % tegen 1,1 %), maar ook veel meer laag door het gemaal (20–60 Hz: 25 % tegen 0,1 %). Het verschil zit dus vooral in de terts, de galm en het gemaal, niet in de spectrale zwaartepunt (585 Hz grijs, 497 Hz opgepompt).

## 6. Carillon en gemaal

### 6.1 Merk-aftelling (E-14b)

- Een merk leeft D + 30 ticks; de laatste **60 ticks** telt het af met **vier carillonslagen, één per 15 ticks**.
- Omdat de echo de treffer precies D ticks later herhaalt, valt de **echo altijd op slag 3** (30 ticks voor het einde), voor elke D van 90 tot 180. Dat geeft een vast, leerbaar ritme: **"één, twee, boem"**. Vraag aan de LGD: houd de levensduur op **D + 30**; dan blijft deze regel vanzelf kloppen.
- **Tonen:** A5, B5, C♯6, D6. De aftelling stijgt naar de grondtoon. Slag 3 (C♯6, de leidtoon) hoor je alleen als de echo niet komt; komt hij wel, dan neemt de **ontploffing** de plaats van slag 3 in en lost op naar D (de grote klok D5, hum D4).
- **Dooft het merk zonder ontploffing** (de echo is Leeg of gebroken): je hoort slag 3 (C♯6), en op slag 4 klinkt geen D6 maar sterft de leidtoon gedempt weg (`merk_dooft`). Onopgelost, met opzet. De D6 (`aftelling_4_*` in de losse SFX) is een reserve, bv. voor een merk dat de LGD later langer laat leven.
- **Merk zetten:** een klein klokje (A6) met een korte glinstering: de lichtvonk in de vorm van een peil- of sluismerk (E-14i). Geen gong, zegel of tempelklok (ideecheck §2, afwijkpunt 5).
- **Meerdere merken tegelijk:** **één aftelling tegelijk is hoorbaar**: die van het merk dat het eerst afloopt. Andere merken zoemen alleen zacht.

### 6.2 Ontploffing en ketting

- Een ontploffing is **licht en schaduw**: een korte diepe plof (schaduw, 48–110 Hz), een donkere ruisgolf, en de grote klok D5 met lichtdeeltjes (kleine klokjes in de pentatoniek van D). Geen vleesgeluid, geen glasscherven.
- **Ketting (E-14d):** schakel `k` laat een klok een stap hoger klinken in D5, F♯5, A5, B5, D6. In de simulatie ontploft elke schakel één tick later (17 ms); dat is te kort om te horen. Het geluid **rolt** de schakels daarom op **45 ms** uit elkaar, zoals een carillonist een rol speelt. De eerste schakel klinkt framexact; de rol loopt na.

### 6.3 Het gemaal en de Gemaalmeester

- Een draaiend gemaal is het **hartslagritme** van een opgepompte wijk: pompslag elke 0,8 s (75 per minuut), om de slag een metalen tik, een waterstoot uit het schoepenrad, en 50 Hz-brom.
- Bij het aanslaan versnelt het van 1,9 s naar 0,8 s per slag.
- **Richting voor de Gemaalmeester (T8b):** hij draagt het gemaalritme in zijn aanvallen (tell = de pompslag die inhoudt), en de laagste klok van het gebied is zijn stem. Uitwerking met de Combat Designer.

### 6.4 De gedeelde echo (finisher, C-14)

De finisher speelt jullie laatste 10 s versneld ×5 af in 120 ticks. Elke finisherslag is een carillonslag, afwisselend in het materiaal van speler 1 en speler 2, oplopend door de toonladder van het gebied; de laatste slag is de volle klokkenrol. Dit is het grootste geluid van een gevecht en het enige moment waarop het hele carillon tegelijk klinkt.

## 7. Muziek (richting)

- **Adaptief in lagen**, niet in losse nummers: per gebied een **grijze laag** (bourdon, verre klokken) en een **opgepompte laag** (harmonium, melodie), synchroon en loopbaar, plus een **gevechtslaag** (ritme uit het gemaal en de klokken). Het spel mengt ze per wijk.
- **Tempo** per gebied, vast binnen een gebied, zodat lagen naadloos kruisfaden. Het eerste gebied: 75 BPM (het gemaalritme).
- **Motief** van het eerste gebied: de aftelling A–B–(C♯)–D als vier noten. Wie het motief hoort, denkt aan het merk.
- **Stilte mag.** Na een gevecht en bij een bevroren echo zwijgt de muziek; alleen water en wind blijven.

## 8. Mixregels

**Doelwaarden** (gemeten volgens ITU-R BS.1770, K-gewogen, met gating):

| Wat | Doel |
|---|---|
| Geïntegreerde loudness van het spel (gewoon spel, 1 min) | **−18 LUFS** ± 2 |
| True peak | **≤ −1 dBTP** na decoderen (master op −1,5 dBTP, Vorbis tikt er ± 0,5 dB bij) |
| Clipping | **0 samples** |
| Hoorbaarheid van spelinformatie (merk, aftelling, tells) boven het bed | **≥ 8 LU** in het venster van 400 ms |
| Ontploffing, finisher boven het bed | ≥ 10 LU |
| Bed (omgeving + muziek) | ± 5–6 LU onder het spel; dukt 3–6 dB onder gevechten |

**Voorrang** (hoog naar laag): (1) tells van gevaarlijke aanvallen, (2) merk-aftelling en ontploffing, (3) speler 1 en speler 2, (4) echo, (5) vijanden (niet-gevaarlijk), (6) muziek, (7) omgeving.

**Regels:**
1. **Elke gevaarlijke aanval is hoorbaar aangekondigd**, minstens even vroeg als in beeld en minstens 10 frames vóór de treffer (pitch P1: vensters ≥ 10 frames).
2. **Frequentievakken.** Lijf van de spelers: 60–250 Hz. Carillon en aftelling: 0,9–2,4 kHz. Echo: 0,7–4 kHz, zonder lijf. Omgeving: gedempt boven 1,5 kHz in grijs. Geen spelinformatie alleen onder 250 Hz: op de luidsprekers van de Steam Deck en veel tv's hoor je dat niet.
3. **Stemmen beperken.** Eén hoorbare aftelling tegelijk (§6.1); max. 4 klokken tegelijk; max. 2 echo-geluiden tegelijk; vijandgeluiden max. 3 per type.
4. **Geen laag in de galm** (send met hoogdoorlaat op 180 Hz): de mix blijft helder in een druk gevecht.
5. **Toonhoogte is informatie.** Willekeurige variatie (± 3 % toonhoogte, ± 1,5 dB) wel op voetstappen, slagen en water, **nooit** op klokken.
6. **Mono-compatibel.** De echo is breed, maar alle spelinformatie blijft hoorbaar in mono (Deck-luidsprekers dicht bij elkaar, tv-modus).
7. **Mixpass per mijlpaal** door de Audio Director op koptelefoon, Deck-luidsprekers (gesimuleerd met een band 250 Hz–12 kHz) en tv.

## 9. Referentiefragment F2

**Bestanden** in `docs/audio/f2-fragment/`:

| Bestand | Wat |
|---|---|
| `f2_merk_aftelling_carillon_placeholder.wav` | Het fragment, 15,5 s, 48 kHz, 16 bit, stereo |
| `f2_merk_aftelling_carillon_placeholder.ogg` | Hetzelfde in Vorbis (q6), zoals Godot het zou laden |
| `f2_spectrogram_placeholder.png` | Golfvorm en spectrogram met de momenten erop |
| `losse-sfx/*_placeholder.wav` | De bouwstenen los: slag P1, echo-slag, merk zetten (grijs/kleur), aftelling 1–4 (grijs/kleur), merksprong, ontploffing k1 (grijs/kleur) en k3, merk dooft |
| `bron/genereer_f2.py` | Het script dat alles maakt (± 8 s), met vaste seed; het print de metingen hieronder |

**Opnieuw maken:** `python3 docs/audio/f2-fragment/bron/genereer_f2.py` vanaf de repo-root. Nodig: numpy, scipy; optioneel ffmpeg (OGG) en matplotlib (spectrogram). Geen externe samples.

**Waarom `_placeholder`:** het fragment is bedoeld als kandidaat voor eindkwaliteit, maar niemand heeft het beluisterd (§0). Het verliest het achtervoegsel pas na een score ≥ 7 met luistercheck.

### 9.1 Wat je hoort (tijdlijn, D = 120 ticks)

| Tijd | Wat | Pillar |
|---|---|---|
| 0,0–6,2 s | **Grijze wijk**: dof water, wind, druppels, een verre verzonken klok, de bourdon D–A | P2 |
| 0,60 | Speler 1 slaat een vijand: zwaai + koperen tik met lijf; het merk zet (lichtvonk, grijs) | P1 |
| 1,20 / 1,78 | Speler 1 springt en landt op natte steen | — |
| 2,10 / 2,35 | Aftelling, slag 1 en 2 (A5, B5), klokken zonder terts | A2 |
| 2,60 | **Slag 3 = de echo**: holle echo-slag met omgekeerde aanloop, merksprong-zip, ontploffing (grijs) | P1, A1, A2 |
| 3,20 / 3,78 | De echo herhaalt de sprong en de landing, hol en zacht | A1 |
| 6,2–8,6 s | **Oppompen**: de machine slaat aan, het water loopt gorgelend weg, een grote klok op D4, de terts F♯ zwelt aan, het gemaal versnelt | P2, A3 |
| 9,00 / 9,30 | **Opgepompte wijk**: twee slagen, twee merken (volle klokjes) | P1 |
| 10,50 / 10,75 | Aftelling van het eerste merk (één aftelling tegelijk), klokken met terts | A2, A3 |
| 11,00 | Echo op slag 3: ontploffing en **ketting** (k = 1 op D5, k = 2 op F♯5, gerold op 45 ms) | P1 |
| 11,30 | De tweede echo-slag vindt geen merk meer: alleen de holle slag (gewone echo-treffer) | A1 |
| 11–15,5 s | Galm van het belfort, gemaal, harmonium D-groot add9; uitfaden | P2 |

### 9.2 Metingen

| Meting | Waarde | Doel (§8) | |
|---|---|---|---|
| Duur | 15,50 s | — | |
| Geïntegreerde loudness | **−18,1 LUFS** | −18 ± 2 | ✓ |
| Max. korte termijn (3 s) / momentaan (400 ms) | −15,3 / −10,9 LUFS | — | |
| True peak WAV / OGG na decoderen | **−1,8 / −1,4 dBTP** | ≤ −1 | ✓ |
| Sample-piek | −1,81 dBFS | — | |
| Clipping | 0 samples | 0 | ✓ |
| DC-offset | < 0,0001 | — | ✓ |
| Crestfactor | 19,2 dB | — (veel dynamiek, geen platgeslagen mix) | |
| Stereocorrelatie | 0,62 | > 0 (mono-compatibel) | ✓ |
| Aftelslag 1 (grijs) boven het bed | **10,1 LU** | ≥ 8 | ✓ |
| Ontploffing grijs / ketting boven het bed | 11,2 / 13,8 LU | ≥ 10 | ✓ |
| Partialen klok D5, opgepompt (gemeten / slagtoon) | 0,500 · 1,001 · **1,199** · 1,496 · 2,001 · 2,510 | carillon: 0,5 · 1 · 1,2 · 1,5 · 2 · 2,5 | ✓ |
| Partialen klok D5, grijs | 0,499 · 1,001 · 1,500 · 2,007 · 2,526 (**geen terts**) | zonder terts (A3) | ✓ |
| P1-slag tegenover echo-slag: aandeel 60–250 Hz | 46 % tegenover 19 % | echo zonder lijf | ✓ |
| Spectrum hele mix, grijs 0–6 s | 20–60 Hz 2 %, 60–250 Hz 27 %, 0,25–2 kHz 62 %, 2–8 kHz 8 %, > 8 kHz 1 %; zwaartepunt 986 Hz | — | |
| Spectrum hele mix, opgepompt 9–15 s | 12 %, 27 %, 49 %, 11 %, 1 %; zwaartepunt 1008 Hz | — | |
| Aftelling: eerste slag na de treffer / echo op slag | 1,50 s / slag 3 | slag 3 (§6.1) | ✓ |

### 9.3 Eerlijke beoordeling

**Hoe het zou moeten klinken** (volgens opzet en metingen, niet beluisterd): een stille, natte, grijze kade; een slag met lijf; twee heldere klokjes die oplopen; dan op de derde tel een holle herhaling van je eigen slag en een klokslag die openbreekt, gedempt en dof in grijs. Daarna slaat een machine aan, loopt het water weg en zwelt een akkoord aan dat warmer is dan alles ervoor. In het opgepompte deel klinkt hetzelfde patroon voller, met galm van een belfort en een kettingrol.

**Waar het tekortschiet:**
1. **Niet beluisterd.** Alle oordelen komen uit metingen. Een synthese die op papier klopt, kan toch "synthetisch" klinken. Dit is het grootste risico.
2. **Water en wind** zijn gefilterde ruis. Dat leest vaak als "ruis" en niet als water. Waarschijnlijk het zwakste onderdeel.
3. **De P1-slag** (ruiszwaai + modale tik) is functioneel maar generiek; er zit geen opgenomen foley in.
4. **Het harmonium** is statisch: geen riet-geruis, geen toetsklik, geen kleine ontstemming tussen stemmen.
5. **De galm** is een synthetische impulsrespons (ruis met verval), zonder de echte vroege reflecties van een belfort.
6. **Grijs → leven** is in de metingen kleiner dan bedoeld: het zwaartepunt van de wereld daalt zelfs (585 → 497 Hz) door het gemaal; het verschil zit in terts, galm en de 2–8 kHz-band (×4). Een v2 mag het grijze deel droger en kaler maken.
7. **Het laag in het opgepompte deel** (12 % onder 60 Hz, vooral het gemaal) is op een tv met subwoofer misschien te veel; op de Deck valt het weg zonder informatieverlies (regel §8.2).

**Zelfscore van de Audio Director:** de **carillon-onderdelen** (aftelling, merk, ontploffingsklok, ketting) schat ik op **± 7**: het klokspectrum klopt gemeten en de klokken zijn het best te synthetiseren. Het **fragment als geheel** schat ik op **± 5–6**, door water, slag en harmonium. **Kwaliteit ≥ 7 is dus nog niet bewezen.**

**Wat nu (binnen de raming van 2–3 maak-taken):**
- **Maak-taak 2** (Composer/Sound Designer, met mij): v2 van het fragment op de punten 2–6, op basis van de SM-review en, als de EP het voorstel uit §0 overneemt, de luistercheck van de CEO.
- **Haalt v2 geen 7**, dan open ik een `brainstorm`-issue met de CEO (fasekader §4), met als opties: (a) **eigen veldopnames** (water, steen, metaal) door een mens, als eigen werk vastgelegd in `docs/licenties.md`; (b) een **CC0-bibliotheek** voor alleen omgeving, na een licentiecheck door de BLA; (c) het palet nog smaller maken (minder omgeving, meer carillon en stilte).

## 10. Techniek in Godot 4.6

**Bussen** (`default_bus_layout.tres`, later door de Audio Director in `game/` via een PR):

```
Master  (HardLimiter, plafond −1 dB)
├── Muziek        (sidechain-compressor op Combat: dukt 3–6 dB)
├── Omgeving      (idem)
├── SFX
│   ├── Speler    (P1 en P2)
│   ├── Echo      (−7 dB; varianten zijn al hol voorgerenderd)
│   ├── Combat    (merk, aftelling, ontploffing, tells)
│   └── UI
├── Galm-Belfort  (Reverb, send vanuit SFX/Muziek, hoogdoorlaat 180 Hz)
└── Galm-Verzonken
```

- **Afspelen op de simulatietick.** Geluiden starten op het event van de Sim (`_physics_process`, `docs/tech/ontwerp.md` §2, event-systeem §4a), nooit vanuit `_process` of een animatie-callback. Zo klopt een SFX framexact met de gameplay, ook voor de echo.
- **De echo gebruikt dezelfde events.** Speelt de echo een opgenomen event af (E-02), dan roept de code dezelfde geluidsfunctie aan met `bron = ECHO`; die kiest de holle variant en de bus Echo. Geen tweede systeem.
- **Holle varianten voorrenderen** in plaats van de kam live op de bus te zetten: goedkoper op de Steam Deck en precies wat in het fragment klinkt.
- **Merk-aftelling:** een kleine `MerkAudio`-node per merk die op ticks `D − 30`, `D − 15` en `D` na het zetten een slag speelt en op `D + 15` het merk laat doven, tenzij een ander merk al hoorbaar aftelt (§6.1). Ontploffing en dooft stoppen de aftelling.
- **Ruimtelijk:** `AudioStreamPlayer2D` voor wereldgeluid (vijanden, gemaal, merk), gewone `AudioStreamPlayer` voor de spelers en de UI (de gedeelde camera houdt ze in beeld). `max_polyphony` per speler volgens §8.3.
- **Variatie:** `AudioStreamRandomizer` voor voetstappen, slagen en water; niet voor klokken (§8.5).
- **Muziek:** `AudioStreamSynchronized` voor de grijze en de opgepompte laag (zelfde tempo en lengte), met het volume per laag gestuurd door de lichtstand van de wijk; `AudioStreamInteractive` voor de overgang naar de gevechtslaag.
- **Formaten:** SFX als WAV 48 kHz 16 bit; muziek en lange omgeving als OGG Vorbis, loopbaar met loop-punten in de import. De import-instellingen komen in de assetlijst.
- **Latentie:** standaard uitvoerlatentie (± 15 ms) is genoeg; meten op de Deck in T7.

## 11. Naamgeving en mappen

- Speelbare audio: `game/audio/sfx/<familie>/<naam>_<variant>.wav` en `game/audio/muziek/<gebied>/<laag>.ogg` (rolbestand Composer/Sound Designer). Familie: `speler`, `echo`, `combat`, `omgeving`, `ui`.
- Varianten: `_grijs` / `_kleur`, `_k1` … `_k5`, `_p1` / `_p2`.
- Niet-eindkwaliteit krijgt `_placeholder` (`WERKWIJZE.md` §9).
- Bron (scripts) staat naast het geluid in een map `bron/` of in `audio-bron/`, zodat elk geluid opnieuw te maken is. Referentiewerk voor een gate (zoals het F2-fragment) staat in `docs/audio/`.

## 12. Do's en don'ts per rol

| Rol | Doe | Doe niet |
|---|---|---|
| Composer/Sound Designer | Leid de echo-variant af van het levende geluid (§4); houd klokken op toonhoogte; lever het script mee | Geen apart "spookgeluid" voor de echo; geen samples zonder licentie |
| Combat Designer | Geef per gevaarlijke aanval het tell-moment in ticks door | Geen tell korter dan 10 frames |
| Gameplay Programmer | Start geluid op het Sim-event, ook voor de echo (§10) | Geen geluid vanuit `_process` of een animatie-callback |
| Lead Game Designer | Houd de merk-levensduur op D + 30 (§6.1) | — |
| Art Director | Laat de kleurgolf en de kruisfade van de galm samen lopen (± 2 s) | — |

## 13. Open punten

- **Luistercheck** door een mens als deel van de F2-score (§0): voorstel aan de EP.
- **v2 van het fragment** (§9.3), daarna SM-review; bij < 7 een `brainstorm`-issue.
- **Assetlijst** (`docs/audio/assetlijst.md`) en muziek per gebied: v1, na T3a (welke events en vaardigheden er komen).
- **gdd O-4** (speelt de echo audio af?) is met §2 A1 beantwoord: ja, gedempt. De LGD kan O-4 sluiten.
- **Geluid van speler 2** (ijzer en glas, A5) en de **finisher** (§6.4) zitten nog niet in het fragment.
- **Hulpmiddelen** (numpy, scipy, ffmpeg met libvorbis) worden alleen gebruikt om audio te maken en gaan niet mee in de game. De BLA beslist of ze in `docs/licenties.md` horen.

### Logboek

| Versie | Datum | Wijziging |
|---|---|---|
| 0.1 | 2026-11-09 | Eerste versie (#66, T2): akkoord op de F2-eis (A10) met twee preciseringen, pijlers, palet, echo tegenover levend, grijs → leven, carillon en gemaal, mixregels, F2-fragment met metingen en eerlijke beoordeling, techniek in Godot 4.6. |
