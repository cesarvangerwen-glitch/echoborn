# Audio bible v0: audiorichting

Versie 0.3 · Eigenaar: Audio Director · Issue: #66 (T2 uit `docs/productie/fase-2-kader.md` §2) · Met: Composer/Sound Designer · Basis: pitch v0.4 (besluit #51), art bible v0 (`docs/art/bible.md`), `docs/design/gdd.md` (E-02, E-14, C-14)

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
2. **Hoe het beoordeeld wordt.** Geen rol in de studio kan luisteren; we beoordelen met metingen. Daarom haalt het fragment eerst de **harde drempels** uit §8 (loudness, piek, hoorbaarheid boven het bed). Daarnaast telt **één luistercheck door een mens** (besluit van de EP, eigenaar van het kader): **F2 = SM-score Kwaliteit ≥ 7 én drie keer "ja" van de CEO**, zonder eigen cijfer, op drie vragen: (1) klinkt het als een carillon, (2) hoor je dat de tweede slag "jij maar hol" is, (3) voelt het opgepompte deel warmer. Op koptelefoon en op tv-luidsprekers, ± 5 minuten, 0 runs. Er komt **één check, alleen op de versie die F2 claimt** (v2), in de CEO-sessie van T17; geen aparte CEO-vraag, want T8d wacht toch op F0.

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
| **Rietorgel / harmonium** | Kerk- en huiskamerorgel uit de Lage Landen, met balgadem | Muziek: grondlaag en akkoorden | Additief: twee rieten per toon (celeste), riet-geruis, toetsklik, balgdruk die ook de klankkleur stuurt (v2) | Ja |
| **Bourdon** | Lege kwint, laag, onveranderlijk | Muziek in grijs | Twee rietstemmen, dof gefilterd | Ja |
| **Hakkebord / luit** | Getokkelde snaar | Muziek: melodie in opgepompte wijken (v1) | Karplus-Strong | Ja |
| **Machine** | Pompslag, schoepenrad, koppeling, 50 Hz-brom | Gemaal, Gemaalmeester | Modaal metaal + gefilterde ruis + lage sinusplof | Ja |
| **Water en wind** | Kabbelen tegen kademuren, leeglopen, druppels | Omgeving | Bellenmodel: Minnaert-bellen met stijgende toon op golfslagen (v2); wind als gefilterde ruis met vlagen | **Waarschijnlijk**: v2 is gemeten korreliger en tonaler dan ruis (§9.2), maar blijft het grootste luisterrisico |
| **Stilte** | Bijna niets | Na een gevecht, bij bevroren echo's | — | — |

**Niet in het palet:** orkeststrijkers, koor, zang, elektronische bas-drops, epische trailer-percussie. Ze passen niet bij de toon, of we halen ze niet op eindkwaliteit zonder externe samples.

**Toonsoort:** het carillon en de muziek van het eerste gebied staan in **D**. Grijs: D en A (lege kwint). Opgepompt: D-groot met de None (D, F♯, A, E). Elk gebied krijgt in v1 een eigen grondtoon en motief.

## 4. Echo-klank tegenover levende klank

| Eigenschap | Levend (speler 1, speler 2) | Echo (en schaduwlaag) | Gemeten in het fragment (§9) |
|---|---|---|---|
| Lijf | Laag in de aanslag (plof < 250 Hz) | Geen lijf: hoogdoorlaat op 260 Hz (4e orde) | Aandeel 60–250 Hz: P1 47 %, echo 6 % |
| Kleur | Vol spectrum, lucht boven 8 kHz | Holle buis: terugkoppelende kam van 4,6 ms (resonanties om de ± 217 Hz), band 0,7–4,2 kHz | > 8 kHz: P1 4,7 %, echo 0,8 % |
| Aanzet | Direct, met transiënt | **Omgekeerde aanloop**: de galm van de slag, achterstevoren, eindigt op de slag. Het geluid komt uit het verleden terug | — |
| Plaats | In het midden van zijn lichaam | Breder (Haas 11 ms) en iets achter het beeld | Stereocorrelatie van de mix 0,69 |
| Niveau | Referentie | −7 dB (slag), −8 dB (beweging) | — |
| Timing | Op de event-tick | Op de event-tick van de afspeling (D ticks later), **framexact**, nooit gequantiseerd | — |

**Regel voor de Composer:** maak geen apart echo-geluid. Maak het levende geluid en leid de echo-versie ervan af met dezelfde keten (functie `echo_versie` in het script van §9). Zo klopt "dat ben jij" altijd.

## 5. Van grijs naar leven

| | Grijs (nog niet opgepompt) | Overgang (oppompen, ± 2 s) | Opgepompt |
|---|---|---|---|
| **Klokken** | Zonder terts, licht valser (partialen uitgerekt), dof (laagdoorlaat ± 2,6 kHz) | — | Volle klok, met terts en heldere bovenpartialen |
| **Muziek** | Bourdon: lege kwint D–A, ver weg | De terts (F♯) zwelt aan met een grote klok op D4 | Harmonium D-groot add9; later melodie (hakkebord) |
| **Omgeving** | Water dof en dichtbij, wind, druppels, een verre verzonken klok | Water loopt gorgelend weg, de machine slaat aan | Water helderder en verder, het gemaal draait (pompslag elke 0,8 s, 50 Hz-brom) |
| **Galm** | "Verzonken": laag nat gewelf (5 × 9 × 3,2 m), RT60 ± 1,8 s, donker (1,3 kHz), smal, weinig galm (droog) | Kruisfade over ± 2 s, met de kleurgolf mee | "Belfort": stenen toren (7,5 × 7,5 × 19 m), RT60 ± 2,9 s, warm (6 kHz), breed |
| **Echo** | Hol, grijs | Kleurt mee met ± 0,5 s vertraging (art bible §5) | Hol, maar met meer lucht |
| **Speler 1** | Vol (altijd in kleur) | — | Vol |

Gemeten op de **wereld zonder spelers** (bed, muziek, galm), fragment v2: het spectrale zwaartepunt stijgt van **455 Hz (grijs) naar 795 Hz (opgepompt)**, en de energie in 2–8 kHz van 0,5 % naar 4,5 % (× 9). In v1 daalde het zwaartepunt nog (585 → 497 Hz) door het laag van het gemaal. Het verschil zit nu in drie dingen tegelijk: de terts, een helderdere galm en helderder water, en een droger, donkerder grijs.

## 6. Carillon en gemaal

### 6.1 Merk-aftelling (E-14b)

- Een merk leeft D + 30 ticks; de laatste **60 ticks** telt het af met **vier carillonslagen, één per 15 ticks**.
- Omdat de echo de treffer precies D ticks later herhaalt, valt de **echo altijd op slag 3** (30 ticks voor het einde), voor elke D van 90 tot 180. Dat geeft een vast, leerbaar ritme: **"één, twee, boem"**. Vraag aan de LGD: houd de levensduur op **D + 30**; dan blijft deze regel vanzelf kloppen.
- **Tonen:** A5, B5, C♯6, D6. De aftelling stijgt naar de grondtoon. Slag 3 (C♯6, de leidtoon) hoor je alleen als de echo niet komt; komt hij wel, dan neemt de **ontploffing** de plaats van slag 3 in en lost op naar D (de grote klok D5, hum D4).
- **Ontploft het merk niet op slag 3** (de echo is Leeg of gebroken): je hoort slag 3 (C♯6), en op slag 4 (D + 15) nog eens de leidtoon C♯6, 6 dB zachter: het merk leeft nog en kan in co-op nog ontploffen. Pas op **D + 30**, het einde van de levensduur (E-14b), dooft het: de leidtoon sterft gedempt weg (`merk_dooft`). Onopgelost, met opzet. Het geluid meldt "weg" dus nooit vóór het merk echt weg is. De D6 (`aftelling_4_*` in de losse SFX) is een reserve, bv. voor een merk dat de LGD later langer laat leven.
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

**Versie v2: dit is de versie die F2 claimt** (§0). v1 staat in de geschiedenis van de repo; het script en de bestanden hieronder zijn v2.

**Werkaannames** (fasekader §5): D = 120 ticks op 60 Hz, merk leeft D + 30 ticks, aftelling in de laatste 60 ticks (één slag per 15 ticks), solo (speler 1 + echo), € 0 extern (alles eigen synthese). Zie de kop van deze bible.

**Bestanden** in `docs/audio/f2-fragment/`:

| Bestand | Wat |
|---|---|
| `f2_merk_aftelling_carillon_placeholder.wav` | Het fragment, 15,5 s, 48 kHz, 16 bit, stereo |
| `f2_merk_aftelling_carillon_placeholder.ogg` | Hetzelfde in Vorbis (q6), zoals Godot het zou laden |
| `f2_spectrogram_placeholder.png` | Golfvorm en spectrogram met de momenten erop |
| `losse-sfx/*_placeholder.wav` | De bouwstenen los: slag P1, echo-slag, merk zetten (grijs/kleur), aftelling 1–4 (grijs/kleur), merksprong, ontploffing k1 (grijs/kleur) en k3, merk dooft |
| `losse-sfx/merk_levensduur_zonder_echo_grijs_placeholder.wav` | **Nieuw in v2:** één merk zonder echo, van zetten tot doven: slagen op tick 90, 105, 120, de zachte slag 4 op 135 (D + 15) en **doven op 150 (D + 30)** (§6.1, E-14b). **Tick 0 = 0,1 s in het bestand**: het doven valt in het bestand dus op 2,6 s |
| `bron/genereer_f2.py` | Het script dat alles maakt (± 10 s), met vaste seed; het print de metingen hieronder, ook die van ffmpeg ebur128 |

**Opnieuw maken:** `python3 docs/audio/f2-fragment/bron/genereer_f2.py` vanaf de repo-root. Nodig: numpy, scipy; optioneel ffmpeg met libvorbis (OGG en de ebur128-meting) en matplotlib (spectrogram). Geen externe samples. De **WAV-bestanden zijn byte-gelijk** opnieuw te maken (vaste seed; twee runs gaven dezelfde hashes). De **OGG** en de PNG kunnen per ffmpeg- of matplotlib-build verschillen. Controle: `sha256sum` van de fragment-WAV = `b09aa64310188f997e46dcddf7fea1c8af0e8ced74dccd34fc4606d0c9609057` (numpy 2.5, scipy 1.18).

**Waarom nog `_placeholder`:** niemand heeft het fragment beluisterd. Het verliest het achtervoegsel pas wanneer deze versie SM-Kwaliteit ≥ 7 én drie keer "ja" van de CEO haalt (§0). Dan hernoemt de Audio Director de bestanden; de inhoud verandert niet.

### 9.1 Wat je hoort (tijdlijn, D = 120 ticks)

| Tijd (s) | Tick | Wat | Pillar |
|---|---|---|---|
| 0,0–6,2 | 0–372 | **Grijze wijk**, droog en dichtbij: golfjes tegen de kade met bellen, vlagen wind, druppels, een verre verzonken klok, de bourdon D–A | P2 |
| 0,60 | 36 | Speler 1 slaat een vijand: zwaai met fladderend stof, harde tik, hout met lijf, koperen naklank, gruis; het merk zet (lichtvonk, grijs) | P1 |
| 1,20 / 1,78 | 72 / 107 | Speler 1 springt en landt op natte steen (spatbelletjes) | — |
| 2,10 / 2,35 | 126 / 141 | Aftelling, slag 1 en 2 (A5, B5), klokken zonder terts; bed en muziek dukken 5 dB | A2 |
| 2,60 | 156 | **Slag 3 = de echo**: holle echo-slag met omgekeerde aanloop, merksprong-zip, ontploffing (grijs) | P1, A1, A2 |
| 3,20 / 3,78 | 192 / 227 | De echo herhaalt de sprong en de landing, hol en zacht | A1 |
| 6,2–8,6 | 372–516 | **Oppompen**: de machine slaat aan, het water klokt weg door de duiker, een grote klok op D4, de stemmen van het harmonium zetten één voor één in (D, A, F♯, E, E5), het gemaal versnelt | P2, A3 |
| 9,00 / 9,30 | 540 / 558 | **Opgepompte wijk**: twee slagen, twee merken (volle klokjes) | P1 |
| 10,50 / 10,75 | 630 / 645 | Aftelling van het eerste merk (één aftelling tegelijk), klokken met terts | A2, A3 |
| 11,00 | 660 | Echo op slag 3: ontploffing en **ketting** (k = 1 op D5, k = 2 op F♯5, gerold op 45 ms) | P1 |
| 11,30 | 678 | De tweede echo-slag vindt geen merk meer: alleen de holle slag | A1 |
| 11–15,5 | — | Galm van het belfort, gemaal met spattend schoepenrad, harmonium D-groot add9; uitfaden | P2 |

### 9.2 Metingen (v2)

Alle waarden komen uit het script; de loudness ook onafhankelijk uit **ffmpeg ebur128** (`-af ebur128=peak=true+sample`).

**Loudness, piek, mix:**

| Meting | v2 | Doel (§8) | | v1 |
|---|---|---|---|---|
| Duur | 15,50 s | — | | 15,50 s |
| Geïntegreerde loudness (script / ffmpeg ebur128) | **−18,0 / −18,0 LUFS** | −18 ± 2 | ✓ | −18,1 |
| Loudness range (ebur128) | 10,6 LU | — (veel dynamiek) | | — |
| Max. korte termijn (3 s) / momentaan (400 ms) | −14,9 / −9,7 LUFS | — | | −15,3 / −10,9 |
| True peak WAV (script / ebur128) | **−1,8 / −1,8 dBTP** | ≤ −1 | ✓ | −1,8 |
| True peak OGG na decoderen (ebur128) | **−1,5 dBTP** (I = −18,1 LUFS) | ≤ −1 | ✓ | −1,4 |
| Clipping | **0 samples** | 0 | ✓ | 0 |
| DC-offset | < 0,0001 | — | ✓ | < 0,0001 |
| Crestfactor | 19,5 dB | — | | 19,2 |
| Stereocorrelatie | 0,69 | > 0 (mono-compatibel) | ✓ | 0,62 |
| Duk van bed en muziek onder het gevecht | max. −5,0 dB (−5,0 op 2,7 s; −0,7 op 4,5 s) | 3–6 dB | ✓ | geen |

**Hoorbaarheid boven het bed** (400 ms vanaf het moment, bed = omgeving + muziek na de duk):

| Moment | v2 | Doel | | v1 |
|---|---|---|---|---|
| Aftelslag 1 grijs / opgepompt | **17,6 / 15,1 LU** | ≥ 8 | ✓ | 10,1 / — |
| Ontploffing grijs / ketting | **12,5 / 23,7 LU** | ≥ 10 | ✓ | 11,2 / 13,8 |

**Timing op de gdd-ticks.** Elke gebeurtenis wordt sample-exact op `tick / 60` s gezet; de meting zoekt daarna in de gerenderde stem de aanzet terug (eerste ms waarin de energie boven 1 kHz 6 dB stijgt).

| Wat | Afwijking | |
|---|---|---|
| Alle klokslagen (merk zetten, aftelslag 1–2 grijs en opgepompt, ontploffing grijs en k1, bloei D4) en de machine | **0,0–1,3 ms** (< 1/12 tick) | ✓ |
| Levensduur zonder echo: zet 0, slagen 90 / 105 / 120 / 135, **doven 150 = D + 30** | **0,8–1,3 ms** per tick | ✓ |
| P1-slag | −7,8 ms: de zwaai komt vóór de treffer, met opzet (de klap zelf valt op de tick) | ✓ |
| Echo-slag | −3 tot −10 ms: de omgekeerde aanloop zwelt aan naar de treffer, met opzet (§4) | ✓ |
| Ketting k = 2 | −10 ms: de meting vindt de ontploffing van schakel 2 op de sim-tick (+16,7 ms); de rol-klok volgt op +45 ms (§6.2) | ✓ |
| Aftelling | eerste slag 1,50 s (90 ticks) na de treffer; de echo valt op **slag 3** | ✓ |

**Klank: v1 tegenover v2** (punten uit §9.3 van v1):

| Punt | Meting | v1 | v2 | Wat het zegt |
|---|---|---|---|---|
| 2. Water | kurtosis van de omhullende (5 ms) van het grijze bed | 1,4 | **7,0** | ruis is egaal (± 0–1); water bestaat uit losse gebeurtenissen (bellen, golfslagen) |
| 2. Water | spectrale vlakheid (0,1–8 kHz; 1 = witte ruis) | 0,020 | **0,005** | v2 is tonaler: elke bel is een korte stijgende toon (Minnaert), zoals echt water |
| 3. P1-slag | kurtosis van de omhullende | 0,6 | **4,5** | eerst een zwaai, dan één harde aanslag en een snelle val, in plaats van één brij |
| 3. P1-slag | aandeel 60–250 Hz (lijf) / > 8 kHz (lucht) | 48 % / 4,3 % | 47 % / 4,7 % | het lijf blijft, de lagen komen erbij |
| 3. Echo-slag | aandeel 60–250 Hz | 19 % | **6 %** | de echo heeft nu echt geen lijf (hoogdoorlaat 4e orde) |
| 4. Harmonium | rieten per toon / zweving / riet-geruis / toetsklik / inzet | 1 / geen / geen / geen / alle stemmen tegelijk | 2 (± 1,5 cent, ongelijk) / ± 0,25 Hz op D3 / ja, synchroon met de periode / ja / 0,14 s na elkaar | de bouwstenen van een echt rietorgel; balgdruk stuurt ook de klankkleur |
| 5. Galm belfort | nagalm < 0,5 / 0,5–3 / > 3 kHz | één RT60 (2,9 s) | **2,92 / 2,45 / 1,74 s** | hoog sterft sneller dan laag, zoals in steen |
| 5. Galm verzonken | idem | één RT60 (2,1 s) | **1,75 / 1,32 / 0,91 s** | korter en doffer dan v1: grijs is droger |
| 5. Galm | vroege reflecties in de eerste 80 ms (> −20 dB) | 9 willekeurige | **29** (belfort), **20** (verzonken), uit een spiegelbronmodel van de ruimte | de ruimte heeft nu een vorm |
| 6. Grijs → leven | zwaartepunt wereld zonder spelers, grijs → opgepompt | 585 → 497 Hz (daalt) | **455 → 795 Hz (stijgt)** | opgepompt is nu helderder dan grijs |
| 6. Grijs → leven | aandeel 2–8 kHz, wereld | 1,1 → 4,6 % | 0,5 → 4,5 % | |
| 7. Laag gemaal | aandeel 20–60 Hz, wereld opgepompt | 25 % | **8 %** | gemaal met hoogdoorlaat op 45 Hz; de pompslag blijft (46–98 Hz) |
| — | partialen klok D5 opgepompt / grijs (t.o.v. slagtoon) | — | 0,500 · 1,000 · **1,199** · 1,496 · 2,000 · 2,510 · 2,667 / 0,499 · 0,999 · 1,500 · 2,009 (**geen terts**) | carillon-spectrum en A3 kloppen (ongewijzigd) |

### 9.3 Wat veranderde en waarom het nu de 7 kan halen

**Wat veranderde (§9.3 van v1, punten 2–6, plus 7):**
2. **Water** is geen gefilterde ruis meer maar een **bellenmodel**: golven slaan op onregelmatige afstand (1,4–3,1 s) tegen de kade, met een zwiep langs de steen en een wolk bellen (Minnaert-resonantie, demping en stijgende toon volgens van den Doel). Grijs: grotere bellen (220–1100 Hz), dof. Opgepompt: kleinere, helderdere bellen (380–3600 Hz). Leeglopen is nu klokken van grote bellen door een duiker, dalend van ± 520 naar 190 Hz; druppels zijn een "plink". Ook de landing en het schoepenrad spatten met bellen.
3. **De P1-slag** heeft vijf lagen: zwaai met fladderend stof (38 Hz), een klik van 1,5 ms, zeven houtmodi met kleine spreiding, drie koperen boventonen die langer naklinken (speler 1 = koper en hout, A5), het lijf (plof 72–142 Hz) en wat gruis na de klap.
4. **Het harmonium** heeft per toon twee rieten die licht ontstemd zijn (celeste), riet-geruis dat met elke periode meeblaast, een toetsklik, een balgdruk die ook de helderheid stuurt (meer druk = meer boventonen), een riet dat heel even te laag aanspreekt, en stemmen die na elkaar inzetten.
5. **De galm** heeft vroege reflecties uit een spiegelbronmodel van een echte ruimte (belfort 7,5 × 7,5 × 19 m; verzonken gewelf 5 × 9 × 3,2 m) en een staart die aansluit op de mengtijd, met een eigen nagalmtijd per band.
6. **Grijs → leven:** grijs is droger (galm 0,20 in plaats van 0,30), donkerder (water tot 1,1 kHz, bourdon tot 750 Hz) en dichterbij; opgepompt is helderder (belfort tot 6 kHz, harmonium tot 5 kHz met E5 erbij, helder water). Het gemaal verloor zijn subsonisch laag.
- **Mix:** bed en muziek dukken nu 5 dB onder gevecht en speler (§8, voorheen niet), zodat aftelling en ontploffing ruim boven de 8 en 10 LU staan.

**Waarom dit de 7 kan halen (onderbouwing, geen oordeel):**
- **Alle harde drempels uit §8 gehaald**, met een tweede, onafhankelijke meting (ffmpeg ebur128): −18,0 LUFS, −1,8 dBTP (OGG −1,5), 0 clipping, spelinformatie 12,5–23,7 LU boven het bed.
- **Timing klopt op de tick:** alle klokken binnen 1,3 ms van hun gdd-tick, ook het doven op D + 30 (E-14b).
- **De drie zwakste punten van v1 zijn gemeten anders geworden in de richting van echt geluid:** water is korrelig en tonaal in plaats van egaal (kurtosis × 5, vlakheid ÷ 4), de slag heeft een duidelijke aanslag (kurtosis 0,6 → 4,5), de galm heeft vorm (29 vroege reflecties) en een nagalm per band zoals in steen.
- **Grijs → leven is nu meetbaar in de goede richting:** het zwaartepunt van de wereld stijgt (455 → 795 Hz) in plaats van te dalen, en de terts komt terug (partialen 1,199).
- **Het palet speelt op de sterke kant van synthese** (§3): klokken, riet, machine. De klokken waren in v1 al ± 7.

**Wat ik niet kan uitsluiten:** ik kan niet luisteren. Metingen zeggen dat de bouwstenen kloppen, niet dat het geheel natuurlijk klinkt. De grootste risico's blijven: (a) het water kan nog "synthetisch" bellen (te regelmatige chirps); (b) de P1-slag kan als "geluidseffect" lezen in plaats van als een klap op een vijand; (c) het harmonium kan te stil of te zweverig zijn. Het geheel opgepompt heeft een lager zwaartepunt dan grijs (851 tegen 941 Hz in de volle mix), omdat het harmonium en het gemaal er body bij geven; dat is de bedoelde warmte, maar het is een keuze die de luistervraag 3 moet bevestigen.

**Zelfscore van de Audio Director:** carillon-onderdelen **± 7**, fragment als geheel **± 6,5–7**. Ik claim F2 op deze versie, maar het oordeel ligt bij de **SM-score Kwaliteit** en de **luistercheck van de CEO** (§0). Haalt v2 geen 7 of geen drie keer "ja", dan open ik een `brainstorm`-issue met de CEO, met als opties: (a) **eigen veldopnames** (water, steen, metaal) door een mens, als eigen werk vastgelegd in `docs/licenties.md`; (b) een **CC0-bibliotheek** voor alleen omgeving, na een licentiecheck door de BLA; (c) het palet nog smaller maken (minder omgeving, meer carillon en stilte). Een "nee" op één vraag wijst de bouwsteen aan: vraag 1 → klokken, vraag 2 → `echo_versie`, vraag 3 → water, harmonium en galm.

### 9.4 Luistercheck voor de CEO (T17)

Eén keer, op dit fragment (`f2_merk_aftelling_carillon_placeholder.wav`), op koptelefoon én op tv-luidsprekers, ± 5 minuten. Antwoord per vraag met **ja** of **nee**, zonder cijfer; een korte opmerking mag.

1. **Klinkt het als een carillon?** Luister naar de klokjes op 2,1 s en 2,35 s en de klokslag op 2,6 s; daarna 10,5–11,1 s.
2. **Hoor je dat de slag op 2,6 s "jij, maar hol" is?** Vergelijk de slag van speler 1 op 0,6 s met de echo op 2,6 s (en 9,0 s met 11,0 s).
3. **Voelt het opgepompte deel (vanaf ± 9 s) warmer en levendiger dan het grijze begin (0–6 s)?**

F2 = SM-Kwaliteit ≥ 7 **én** drie keer "ja" (§0).

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
- **Merk-aftelling:** een kleine `MerkAudio`-node per merk die op ticks `D − 30`, `D − 15` en `D` na het zetten een slag speelt, op `D + 15` de zachte slag 4 en op `D + 30` (einde levensduur, E-14b) het doven, tenzij een ander merk al hoorbaar aftelt (§6.1). Ontploffing en dooft stoppen de aftelling.
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

- **QA Lead:** zet de drie luistervragen uit §9.4 op de CEO-kaart van T17 (fragment v2, koptelefoon en tv, ± 5 min, ja/nee zonder cijfer).
- **Fragment v2** (§9) claimt F2: SM-score Kwaliteit en de luistercheck van de CEO op die versie. Haalt het geen 7 of geen drie keer "ja", dan een `brainstorm`-issue met de opties uit §9.3.
- **Assetlijst** (`docs/audio/assetlijst.md`) en muziek per gebied: v1, na T3a (welke events en vaardigheden er komen).
- **gdd O-4** (speelt de echo audio af?) is met §2 A1 beantwoord: ja, gedempt. De LGD kan O-4 sluiten.
- **Geluid van speler 2** (ijzer en glas, A5) en de **finisher** (§6.4) zitten nog niet in het fragment.
- **Hulpmiddelen** (numpy, scipy, ffmpeg met libvorbis) worden alleen gebruikt om audio te maken en gaan niet mee in de game. De BLA beslist of ze in `docs/licenties.md` horen.

### Logboek

| Versie | Datum | Wijziging |
|---|---|---|
| 0.3 | 2026-11-09 | Fragment v2 dat F2 claimt (§9): water als bellenmodel, gelaagde P1-slag, harmonium met celeste, riet-geruis en toetsklik, galm met spiegelbronnen en nagalm per band, droger grijs, gemaal zonder subsonisch laag, dukken van bed en muziek, levensduur zonder echo (doven op D + 30) als losse reeks; metingen met ffmpeg ebur128 en timing op ticks; luistervragen klaar voor T17 (§9.4). §3, §4, §5 bijgewerkt met de v2-metingen. |
| 0.2 | 2026-11-09 | Lead-review EP (PR #106): doven op D + 30 met een zachte slag 4 op D + 15 (§6.1, §10); EP-besluit over de luistercheck (§0, §9, §13); WAV byte-gelijk, OGG per build (§9). |
| 0.1 | 2026-11-09 | Eerste versie (#66, T2): akkoord op de F2-eis (A10) met twee preciseringen, pijlers, palet, echo tegenover levend, grijs → leven, carillon en gemaal, mixregels, F2-fragment met metingen en eerlijke beoordeling, techniek in Godot 4.6. |
