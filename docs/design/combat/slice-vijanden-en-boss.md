# Vijanden en boss van de slice (T8b)

Versie 0.1.7 · Eigenaar: **Combat Designer** · Issue [#84](https://github.com/cesarvangerwen-glitch/echoborn/issues/84) (T8b), [#289](https://github.com/cesarvangerwen-glitch/echoborn/issues/289) (wat P2 doet in de boss, G-2), [#302](https://github.com/cesarvangerwen-glitch/echoborn/issues/302) (na de meting van B-14 deel 1), [#213](https://github.com/cesarvangerwen-glitch/echoborn/issues/213) (waarden na de scripted runs van PR #209), [#245](https://github.com/cesarvangerwen-glitch/echoborn/issues/245) (§2.6 naar de stand op `main`), `docs/productie/fase-2-kader.md` §2 (T8b), §3 (F3, R-V4)
Bouwt verder op: `docs/design/gemaalmeester.md` v0.2.4 (GM-01–GM-11, ontwerp LGD, [#187](https://github.com/cesarvangerwen-glitch/echoborn/issues/187)), `docs/design/wereld.md` v0.1.4 §2 (slice Kadewijk, §2.4 vijandtypes), `docs/design/kamers/kadewijk.md` v0.4.4 (§3f, §4 encounters, §8 afwijking 2 en 19), `docs/design/gdd.md` v0.8.4 (#187; E-02, E-02m, E-02t, E-07a, E-07c, E-07d, E-14, E-14j, C-09–C-16, C-12e, L-13, LM-02, LM-05, LM-07, V-01, §2.5a, §4.3, §4.7, §4.8.5), `docs/concept/pitch.md` v0.4 §4 (P1–P3), `docs/qa/testplan-t11-slice.md` §4 (rij Boss) en §6 (G-2).
Dit document is het **detailontwerp** dat `gemaalmeester.md` §7 en `wereld.md` §2.4 aan de Combat Designer laten: schade, levens, maten, patronen, vensters, telegraphs en de bouwopdracht. Waar het afwijkt van een LGD-document, staat dat in §8 (voor de Lead-review); de LGD-documenten zelf verandert dit document niet. Voor de slice vervult het de rol van `vijanden.md` en `bosses/gemaalmeester.md` uit het rolbestand.

---

## 0. Werkaanname (kader §5)

| Bron | Wat dit document ervan gebruikt |
|---|---|
| CEO-besluit 2026-11-12 (#80) | **D = 60 ticks (1 s)** is de werkaanname; het bereik is **1–3 s (D = 60 … 180)**. Alle vensters en patronen zijn eerst voor **D = 60** gezet; waar een maat van D afhangt, staat hij als formule, met de waarden voor 60 / 90 / 120 / 180 (§7). |
| CEO-besluit 2026-11-12 (#80) | Fase 2 parallel, ook bouwen: T8b wacht niet op een geslaagde flow-test. De CEO test alleen bij mijlpalen; tot dan toetsen de bots (§6). |
| CEO-besluit #51 deel 2 | 1A: bosses zijn gebouwd om samen of met je echo te winnen, geen puzzel. 7A: één rol, solo de echo, co-op de partner; verplicht bij bosses; gedeelde echo alleen als finisher; max. twee lichamen. 8A: de finisher speelt jullie laatste 10 s af. |
| CEO-besluit #2 | PEGI 12; 8–12 min per boss inclusief pogingen. |
| Pitch v0.4 §4 P1 | Elke verplichte boss-actie: **≤ ± 5 s stilstand** (MP-1 ≤ 300 ticks), vensters **≥ 10 frames** (1 frame = 1 tick, 60 per s), feedback in geluid, schermschok en licht. |
| Fasekader v0.2, R-V4 | **Max. 4 vijandtypes** in de slice; de boss telt niet als type. |
| Flow-tests F0 en F0-2 | (1) Merk en ontploffing waren zonder hulp niet leesbaar (M2 "geen idee"); de **bereikcirkel en doelstreep** (E-14j, E-02t) zag de CEO wel en ze hielpen. (2) Paren op 28 px geven geen ketting: de eerste ontploffing doodt beide (`flowkamer.md` §4). |

**Werkaanname Combat Designer:** alle getallen hier zijn **startwaarden** voor de bouw, gekozen op D = 60 en de bewegingswaarden van gdd §2.5a. Ze worden gezet met de scripted runs (§6, B-9) en bijgesteld na de mijlpaal-test van de slice (T11). De LGD werkt de gdd parallel bij voor D = 60 (#81); verandert daar een waarde waar dit document op rust (staart, R, E, K, merk-levensduur, beweging), dan rekent de Combat Designer §7 opnieuw na.

---

## 1. Samenvatting

- **3 vijandtypes** (van max. 4): **Kadeloper**, **Schotdrager**, **Dwaallicht**. De vierde plek blijft in de slice **leeg** (§2.5).
- **De Gemaalmeester** in **2 fasen + Wankel**: fase 1 *het schot* (je tweede slag: alleen een merk-ontploffing breekt het, **4 openingen**), fase 2 *het grote rad* (je springplank: alleen met bounce, lancering of vang te raken), Wankel met de **co-op-finisher** (C-14).
- Elk verplicht moment werkt solo met de echo en in co-op met de partner, in dezelfde arena, met vensters ≥ 10 ticks; bij D = 60 is de langste verwachte wacht **39 ticks** (de optionele solo-lancering).
- **P2 in de boss** (co-op, v0.1.6): in elke fase een taak op een plek die met de maat verschuift: in fase 1 *de wissel* (merken op de doelhelft van de pompslag), in fase 2 drager en springer, in Wankel ontsteker (§3.10). De langste verwachte stilstand van P2 is ≤ ± 150 ticks (was 925; v0.1.6: ≤ ± 120; gemeten 148 in fase 2), en C-16 blijft gelden.
- Bouwopdracht voor de Gameplay Programmer in §6 (B-1–B-14), wat Animator, UI/UX en Audio nodig hebben in §9.

---

## 2. Vijandtypes

### 2.1 Gedeelde regels (alle drie)

| ID | Regel |
|---|---|
| **VJ-01** | **Merkbaar en eerlijk.** Elk type is `Merkbaar` (E-14a). Elke aanval heeft een **aanloop van ≥ 30 ticks** met een tell in beeld én geluid (§9), en daarna een actief vlak van hooguit 8 ticks. Contactschade bestaat niet: alleen een actief aanvalsvlak raakt P1. |
| **VJ-02** | **Schade aan P1.** Elke treffer van een vijand of de boss kost P1 **1 levenspunt** (P1: 5, plus 1 voor het lampglas in S5). Daarna is P1 **45 ticks onkwetsbaar** (knipperen); nieuw, de gdd heeft er nog geen waarde voor. Een treffer die P1 doodt, geeft geen onkwetsbaarheid; **na een respawn** is P1 wel **45 ticks onkwetsbaar** (zelfde knipperen, zelfde code), zodat een aanloop die al liep bij het respawnpunt hem niet raakt zonder volle tell (#190). De echo en P2 krijgen nooit iets (E-14h, C-02). |
| **VJ-03** | **Snelheid in D.** Een vijand die loopt of zweeft, beweegt met `v(D) = min(v_max; 44 / (D − 27))` px/tick. Zo geldt L-13 (c) (`36 + v × (D − 27) ≤ R = 80`) bij elke D: de merksprong haalt hem altijd. Kadeloper en Schotdrager: `v_max = 0,5`. Dwaallicht: `v_max = 0,25`. Waarden per D: §7. **Bovengrens: `v ≤ 0,70 px/tick`** voor elke vijand (`44 / (D_max − 27)` met D_max = 90, gdd v0.8 §4.8.5). Bij D = 60 lopen ze dus **0,5 px/tick**, twee keer zo snel als in de flow-kamer en onder de grens: de korte staart laat dat toe, en een snellere vijand geeft minder reden om te wachten. |
| **VJ-04** | **Stil na een treffer.** Na elke treffer (ook een merk zetten of een ontploffing die hem niet doodt) staat een vijand **30 ticks** stil en breekt zijn aanloop af (zoals gdd §4.3). |
| **VJ-05** | **Paren en afstandsregel per paar.** L-13 (d) blijft: **elke golf heeft minstens één E-paar**, twee vijanden die **≤ 32 px** (E) uit elkaar beginnen: één merk raakt ze allebei, één knal doodt het paar. Daarnaast mogen er **K-paren** bij, als extra paar: **40–44 px** uit elkaar, buiten E en binnen K = 48, zodat twee merken ketenen met de kettinglijn van E-14j in beeld (20 + 25 SE; de les van F0-2: op 28 px komt er geen ketting). **De afstandsregel geldt per paar:** elk paar heeft een startafstand `a` **in data** (`slice.csv`; E-paar 28 px, K-paar 40–44 px), en de twee vijanden van een paar komen niet dichter bij elkaar dan `a` (een vijand loopt niet verder als hij daarmee binnen `a` van zijn paargenoot komt). Vijanden die geen paar zijn, houden ≥ 40 px, zodat paren niet samensmelten. |
| **VJ-06** | **Donker en verlicht** (O-18, pitch P2). In een wijk die nog niet is opgepompt (waterstand `s < 2`, "donker") gelden de waarden hieronder. In een **verlichte** wijk (`s = 2`, in de slice alleen S9) zijn vijanden **zwakker, niet anders**: `v` × 0,5 en de aanloop +10 ticks. Geen apart type per lichtstand (kernloop §5). Beeld: in het donker gloeien hun ogen en randen feller (Art). |
| **VJ-07** | **Leesbaarheid van het merk** (F0, F0-2). E-02t (doelstreep) en E-14j (bereikcirkel, rand, kettinglijn) gelden voor **elk** merk op een vijand en op de boss; ze zijn voor T8b geen polish maar een eis. Een treffer op een **intact pantser** geeft een eigen geluid en vonk ("tink", 0 SE), anders dan een treffer met schade. |
| **VJ-08** | **Alleen aanlopen als het vlak kan raken** (#190). Een Kadeloper of Schotdrager begint zijn aanloop alleen als P1 horizontaal binnen 32 px is (middelpunten) **én de voeten van P1 tussen −20 en +20 px van zijn vloer** zijn: de slag ligt 4–20 px boven die vloer en P1 is 24 px hoog, dus daarbuiten raakt het vlak hem niet. Hangt P1 hoger (in de lucht, op de plank van je echo of partner op 30 px) of lager (op een lagere vloer, bv. 30 px eronder), dan loopt hij gewoon door naar P1 en slaat niet. Eenmaal begonnen loopt de aanloop door, ook als P1 dan springt: springen blijft een ontwijking. Het Dwaallicht heeft al zijn eigen hoogteregel ("P1 lager", §2.4). |

### 2.2 Kadeloper (basisvijand)

| Wat | Waarde |
|---|---|
| Rol | De basisvijand van de slice en de adds van de boss: merken, laten knallen, ketting in paren; bron van licht (genezen, LM-07) |
| Lichaam en hurtbox | 16 × 24 px, op de vloer; springt niet, valt niet van randen (draait om bij een rand) |
| Levens | **30 SE** (P1-treffer 10, ontploffing 20: één merk + één slag, of een merk dat de echo laat knallen + één slag) |
| Beweging | Loopt naar P1 met `v(D)` (VJ-03; 0,5 bij D = 60, 0,25 verlicht); VJ-05 |
| Aanval: **haakslag** | Als P1 binnen 16 px is (randen; middelpunten ≤ 32 px) en zijn voeten tussen −20 en +20 px van de vloer van de vijand (VJ-08): aanloop **30 ticks** (haak omhoog, schraapgeluid), actief **6 ticks** een vlak van 20 × 16 px vóór hem, 4–20 px boven de vloer; herstel 20 ticks |
| Ontwijken | Weglopen (in 30 ticks 60 px), erover springen, of op je echo/partner staan (het vlak reikt tot 20 px, de plank ligt op 30) |
| Merk | E-14a; in een E-paar (28 px) doodt één knal het paar, in een K-paar (40–44 px) ketent hij (VJ-05) |
| Licht | LM-02 (+2 per treffer, +6 per schakel) |
| Terugkeer | Ja (LM-13a, `STANDAARD`), zolang het gemaal niet vol is (zoals K2) |

### 2.3 Schotdrager (gepantserde Kadeloper)

| Wat | Waarde |
|---|---|
| Rol | Leert vóór de boss wat het schot van de Gemaalmeester vraagt: **alleen een merk-ontploffing breekt een pantser** (E-14g). Een Kadeloper met een geroest sluisschot voor zich |
| Lichaam en hurtbox | 16 × 24 px (zelfde vorm als de Kadeloper, zodat de code één soort met een vlag is); beeld 22 × 26 px met het schot |
| Pantser | Volgens E-14g voor het hele lichaam (geen "achterkant raken": de les is het merk, niet om hem heen springen). Treffer op het intacte pantser: 0 SE, 0 LP, **wel een merk**, "tink" (VJ-07). De eerste ontploffing die hem raakt (ook een schakel van een ketting of een ontploffing binnen E = 32 van een buurman), breekt het pantser en doet verder niets. Daarna: gewone Kadeloper, 30 SE |
| Beweging en aanval | Als de Kadeloper; aanval **schotstoot**: aanloop 30, actief 6, vlak 24 × 16 px vóór hem, **4–20 px boven de vloer** (zoals de haakslag); aanloop alleen volgens VJ-08 |
| Plek | Altijd in een **E-paar** met een Kadeloper (VJ-05: 28 px): de ontploffing van het merk op de Kadeloper (E = 32) breekt ook zijn pantser. **Blokkeert de route nooit** (L-13 e): een golf is op zonder hem |
| Terugkeer | Nee (zoals het pantserdoel) |

### 2.4 Dwaallicht (zwevend stuitdoel)

| Wat | Waarde |
|---|---|
| Rol | Stuitdoel voor de **Neerslag** (V-01b) vlak voor de boss: hij leert je boven iets uit te komen en daar te blijven, wat het grote rad in fase 2 beloont |
| Lichaam en hurtbox | 16 × 16 px; zweeft op een **vaste horizontale baan** van 32–96 px lang, onderkant **40–56 px** boven vloer of water (in S7: 40 px, zodat een gewone sprong + neerslag hem haalt; het neerslagvlak van 16 × 20 px onder de voeten reikt bij de top van een sprong van 30 tot 50 px) |
| Levens | **30 SE** |
| Beweging | `v(D)` met `v_max = 0,25` (VJ-03), heen en weer op zijn baan; stil na een treffer (VJ-04) |
| Aanval: **duik** | Als het middelpunt van P1 horizontaal binnen 24 px van het zijne is en P1 lager hangt: aanloop **30 ticks** (licht zwelt, toon stijgt), dan een duik van 8 ticks naar 16 px boven de vloer (zijn lichaam is het actieve vlak), daarna 40 ticks terug naar zijn baan zonder schade |
| Merk en echo | Een neerslag van P1 merkt hem en stuit (V-01b); de echo herhaalt de neerslag D + 3 ticks later als merksprong en laat het merk knallen (V-01e): **10 + 20 = 30 SE**, de echo ruimt achter je op |
| Terugkeer | Ja in het donker; **nee** zodra de wijk verlicht is (`wereld.md` §2.4) |

### 2.5 De vierde plek (OW-4)

**Niet gebruiken in de slice.** De drie types dekken de drie dingen die de boss toetst (merk-ketting, pantser, boven iets blijven). Een vierde type kost animatie en audio (F6, kost per type) en maakt de slice minder leesbaar (R-V6). Alleen als de mijlpaal-test laat zien dat spelers op één plek blijven staan in S3 of S6, stelt de Combat Designer een type op afstand voor (bv. een werper die je laat bewegen); dat is dan een nieuwe versie van dit document, geen CEO-vraag (binnen R-V4).

### 2.6 Waar ze staan (`wereld.md` §2.2; gebouwd in `kadewijk.md` §4)

De kamers en de geometrie zijn van de World & Level Designer; dit is de verdeling binnen de kamerlijst, met de paren van VJ-05. Max. 5 vijanden tegelijk in beeld (L-13 f). **Stand v0.1.4:** gecontroleerd tegen `kadewijk.md` v0.4.4 §4 en de scènes in `game/levels/kadewijk/` (`s2_kadegang.tscn` … `s9_lage_kade.tscn`); de x-waarden hieronder zijn die van de scène. Afwijkingen van de WLD staan in `kadewijk.md` §8 (2 en 19, akkoord LGD).

| Kamer | Vijanden | Hoe |
|---|---|---|
| S2 Kadegang | 2 Kadelopers | Eén **E-paar** (28 px; x 880 / 908), op het vlakke stuk na de lus (B3): één merk, één knal, twee neer |
| S3 Vismarkt | Golf 1: 3 Kadelopers. Golf 2: 2 Kadelopers + 1 Schotdrager | Golf 1: één **E-paar** (28 px) + één losse, ≥ 160 px van het paar. Golf 2 aan de kant van de ingang (je keert ernaartoe, zoals K2): de Schotdrager in een **E-paar** met een Kadeloper, de tweede Kadeloper los. Golf 2 start zodra elke Kadeloper van golf 1 een merk heeft of op is (zoals K2, gdd §4.7.1 c) **én** golf 2 erbij hooguit 5 tegelijk geeft (afwijking 2 van de WLD, akkoord LGD). Scène: golf 1 x 2140 / 2168 + 2360 (192 px), golf 2 Schotdrager 1770 + Kadeloper 1798, los 1990 |
| S4 Brugkloof | 1 Kadeloper | Aan de overkant, ≥ 80 px van de landing van de lancering (geen treffer bij aankomst); scène x 3260, landing ± 3090 (170 px) |
| S5 Sluiswachtershuis | Geen | Geen Kadeloper op richel 2: hij staat in de landingszone van de bounce en breekt het ritme (besluit 3 LGD, `kadewijk.md` §8); MT2 meet of het verveelt |
| S6 Gemaalplein | 2 Kadelopers (terugkerend) | Eén **K-paar** (40–44 px; scène 42 px, x 4340 / 4382): hier zie je de **ketting**; ≥ 80 px van elke pompschoep (FK-5: anders kiest de echo een merksprong in plaats van een pompslag; gebouwd ≥ 98 px) |
| S7 Sluiskelder | 2 Dwaallichten | Boven het kanaal van 160 px (x 4960–5120): banen van 32 px rond 1/3 en 2/3 van de breedte (x 5013 en 5067), onderkant 40 px; stuitlijn sprong → neerslag → stuit → neerslag → overkant |
| S8 Machinehal | Adds: Kadelopers uit de spuigaten | §3.4 (fase 1, max. 2 tegelijk; `adds_max` in `slice.csv`) |
| S9 Lage kade | 1 Dwaallicht (verlicht) + één E-paar: 2 Kadelopers (verlicht, VJ-06) | **Dwaallicht** op x 2310 (baan 32 px, 2294–2326, onderkant 40 px boven de kade), tussen de brugpijler en het E-paar: springen, stuiten met een neerslag (V-01b), de echo laat het merk knallen (V-01e). **E-paar** (28 px) op x 1060 / 1088, tussen het Dwaallicht en het luik; trager, de wijk is je beloning. Afwijking 19 van de WLD (`kadewijk.md` §8, #227): zonder het Dwaallicht en het E-paar op 1060 is er na het rustpunt een gat van > ± 10 s zonder echo-actie. Akkoord LGD ([Lead-review #239](https://github.com/cesarvangerwen-glitch/echoborn/pull/239#issuecomment-6840184277)), past bij de CD (#227, PR #240). Nog steeds 3 types, ≤ 5 tegelijk |

---

## 3. De Gemaalmeester

### 3.1 Wat hij toetst

| Fase | Vermogen (geleerd in) | Samenwerkingsactie (C-16 b) | Solo | Co-op |
|---|---|---|---|---|
| 1. Het schot | Merk + echo laat knallen (S2, S3), pantser (Schotdrager, S3) | Merk-combo | P1 merkt, de echo knalt (merksprong) | De een merkt, de ander slaat |
| 2. Het grote rad | Bounce, lancering (S1, S4), neerslag-stuit (S7) | Bounce, lancering, vang | Keren tegen de muur, op je echo; of de lanceerhouding | Op elkaar bouncen, lanceren, vangen |
| Wankel | Merk-combo | Finisher (C-14, C-16 a) | Merk, de echo knalt; de gedeelde echo speelt jou en je echo af | Merk, de ander knalt; de gedeelde echo speelt jullie twee af |

### 3.2 Arena, lichaam en hurtboxes (aanvulling op GM-01, GM-02)

Coördinaten in arena-px: vloer van **x = 0** (linkermuur) tot **x = 600** (rechtermuur), `y` = hoogte boven de vloer.

| ID | Regel |
|---|---|
| **GMB-01** | **Lichaam** op x 252–348 (96 px), niet massief, geen contactschade (GM-02). Hij draait niet en loopt niet. |
| **GMB-02** | **Schot en kern** (fase 1): één `Pantserdoel` (E-14g) met hurtbox 48 × 48 px op x 276–324, y 12–60, van **beide kanten** te raken (je loopt door het lichaam heen). Merkplek en merk op het middelpunt (300, 36): binnen 24–48 px (GM-06) en vanaf de vloer binnen R = 80 van elke slagpositie. Intact = het schot; gebroken = de **kern** (gewone schade, `Merkbaar`). |
| **GMB-03** | **Spuigaten** op x 236 en x 364, op de vloer (de adds komen eruit, §3.4). |
| **GMB-04** | **Het grote rad** (fase 2): hurtbox 96 × 40 px, y **100–140**, middelpunt op `x_rad = D + 34` px van de muur aan zijn kant (GM-07): bij D = 60 op **x = 94** (links) of **x = 506** (rechts), hurtbox x 46–142 of 458–554. Niet `Merkbaar`. Onder het rad een **vloerteken** (olievlek met licht) van `D` tot `D + 68` px van de muur: daar draagt je echo je na het keren omhoog (alleen beeld; schuift mee met D). **In co-op** hangt het rad op een vaste plek, **94 px** van de muur (`rad_coop_muur`, de plek van D = 60), los van D: in co-op is er geen echo, dus D mag de co-op-boss niet veranderen (v0.1.3, §3.8). |
| **GMB-05** | **Merkplek van Wankel**: zelfde plek als GMB-02 (300, 36), op de ketel, alleen bij Wankel. |
| **GMB-06** | Geen `FelLicht`, `Schaduwgevaar`, `Diepwater` of richels in de arena (GM-01): de echo breekt hier nooit, en zonder echo of partner is het rad niet te halen. |

### 3.3 Levens, fasen en drempels (vervangt de getallen van GM-03)

| ID | Regel |
|---|---|
| **GMB-10** | **1750 SE** (v0.1.5, [#247](https://github.com/cesarvangerwen-glitch/echoborn/issues/247); was 1500; in data, `slice.csv`), solo en co-op. De verhoudingen van GM-03 blijven: fase 1 van 100 % tot 60 % (700 SE, tot 1050), fase 2 van 60 % tot 20 % (700 SE, tot 350), Wankel op ≤ 20 %. **Waarom 1750** (besluit LGD in #247): fase 2 duurt **≤ 65 s** (± 10 kanten), fase 1 **≥ 24 s**, en de run duurt **95–150 s** (doel ± 100 s). Met de radtreffer van 33 SE is een kant 66 SE, dus 700 SE in fase 2 is 10 kanten. Fase 1 krijgt dezelfde 700 SE, verdeeld over 7 openingen (GMB-11). *v0.1.3: 1500 SE met ± 17 kanten (± 100 s fase 2): dat was te lang, zeventien keer dezelfde kant (CD, visie-review S8).*
| **GMB-11** | **Zeven openingen in fase 1** (v0.1.5, #247; was vier; aantal en drempels in data). Fase 1 heeft drempels op **1650, 1550, 1450, 1350, 1250, 1150 en 1050 SE** (100 SE per opening). Een opening (gebroken schot) eindigt bij de drempel van die opening of na **300 ticks** (GM-06), wat eerst komt: dan schuift het schot weer voor de kern. Schade onder de drempel van de opening valt weg (de boss klemt op de drempel). Na de laatste drempel: fasewissel. Waarom zeven en niet vier plus één (de LGD noemde "eventueel één schotcyclus langer"): de duur van fase 1 hangt aan het aantal cycli breken-openen-sluiten (± 160–240 ticks per cyclus bij D = 60), niet aan de SE. Met vijf openingen was fase 1 in de arena-test 21,9 s (< 24), met zes was de run 95,1 s (te krap op 95). Met zeven: fase 1 **28,4 s**, de run **97,9 s** (B-9, §3.9). Een geoefende speler breekt het schot zo zeven keer: leren, toepassen, en vijf keer toepassen met adds. Dat is meer herhaling dan vier. MT2 meet of het verveelt (GM-d); de knop staat in data.
| **GMB-12** | **Fasewissel** 60 ticks (GM-03): hij valt niet aan, alle merken op de boss doven, levende adds lossen op in stoom (geen LP), het schot sluit voorgoed (niet meer `Merkbaar`), het rad hijst zich uit de ketel en draait naar de kant **waar P1 níét is** (co-op: niet is P1), zodat je ernaartoe loopt en tegen de muur keert. |
| **GMB-13** | **Wankel** op ≤ 350 SE (20 %, v0.1.5; was 300; klemt op 350). Zie §3.6. |

### 3.4 Fase 1: het schot (GM-06)

**Ritme:** één aanval per maat van **120 ticks** (GM-04); de allereerste aanval heeft 60 ticks aanloop (hij aarzelt bij de sjaal).

**Aanval A: pompslag (fase 1).**

| Wat | Waarde |
|---|---|
| Doel | De helft waar P1 is op het begin van de aanloop: `x < 300` → **links**, anders **rechts**. **Co-op** (v0.1.6): om en om links en rechts, de eerste op de helft van P1 (GMB-14, §3.10) |
| Vlak | 160 × 24 px: links x **140–300**, rechts x **300–460** (de helft van het lichaam plus 112 px ernaast: wie bij de kern slaat, staat er altijd in) |
| Tijden | aanloop **40**, actief **6**, herstel 24 (de stang ligt op de vloer, doet niets), rust tot het eind van de maat |
| Tell | De drijfstang heft zich naar die kant; stoom en een stofstrook op het vlak, die feller wordt; carillon-tel op het begin van de maat, sissende zuiger die stijgt (§9) |
| Ontwijken | (1) **door de machine naar de andere helft** stappen (vanaf de kern 10–30 px, 5–15 ticks); (2) **springen**: je voeten zijn 29 ticks boven 24 px, dus het venster om af te zetten is **24 ticks**; en de sprong-aanval raakt de kern (y 12–60) gewoon; (3) op je echo of partner staan (plank op 30 px); (4) dash |

**Het schot breken (verplicht).** Elke treffer van P1 (of P2) op het intacte schot zet een merk (0 SE, "tink", bereikcirkel). Solo herhaalt de echo die slag **D + 3 ticks** later als merksprong (E-02m) en laat het merk knallen: het schot breekt. Vanaf `t − 30` vóór de knal staat de **doelstreep** (E-02t). In co-op slaat de ander op het gemerkte schot. Ook een ontploffing van een add binnen E = 32 px van het merkmiddelpunt, of een schakel van een ketting, breekt het (E-14g).

**Waarom dit leesbaar is zonder tekst (GM-a):** het schot breekt solo **vanzelf** als je erop slaat en daarna gewoon doorbeweegt: de echo komt altijd langs, want hij herhaalt je slag op dezelfde plek en het merk leeft D + 30 ticks (bij D = 60: knal op 63, merk dooft op 90, 27 ticks marge). Je hoeft het niet te snappen om het te zien gebeuren, en na de eerste keer weet je het. De "tink" bij de eerste slag zegt "dit is pantser"; de cirkel, de streep en de knal zeggen wat het wel breekt.

**Gebroken: de kern.** Breuk = scheur, stoom, schermschok 6 ticks / 2 px, de ketel licht oranje op. De kern ligt open tot de drempel van de opening (150 SE verder, bij ± 0,75 SE/tick ± 200 ticks) of 300 ticks (GMB-11) en is `Merkbaar`: P1-treffer 10 SE, gewone echo-treffer 5, merk-ontploffing 20 (ketting volgens E-14d). De echo herhaalt je slagen op de kern één staart later: met merk erop knalt hij, zonder slaat hij 5. **Dit is je tweede slag.** Elke 120 ticks komt er een pompslag op jouw helft: slaan, ontwijken, slaan.

**Adds (GM-05c).** Als het schot na opening 1, 2 en 3 dichtgaat, gloeien de spuigaten **30 ticks** en komt er uit elk één **Kadeloper** (max. 2 levend; zijn er al 2, dan geen nieuwe). Ze doen de eerste 30 ticks niets (uit de stoom stappen). Ze lopen naar P1, dus naar het schot: met hun merken ketent een knal tot het schot (K = 48), of breekt hun ontploffing het schot (E = 32). Ze zijn je **licht** om te genezen (LM-07). Vóór opening 1 geen adds: de eerste keer is schoon.

### 3.5 Fase 2: het grote rad (GM-07)

**Ritme:** één aanval per maat van **90 ticks**, om en om **pompslag** en **schoepenzwiep**: *hoog – laag*.

**Aanval A': pompslag (fase 2).**

| Wat | Waarde |
|---|---|
| Doel | Een vlak van 160 × 24 px **gecentreerd op x van P1** op het begin van de aanloop, binnen de arena (geklemd op x 0–600) |
| Tijden | aanloop **30**, actief 6, herstel 24 |
| Ontwijken | **in de lucht of op je echo/partner zijn** tijdens de 6 actieve ticks: springen (venster 24 ticks), **bouncen naar het rad** (de bounce is je ontwijking), dash + lopen (40 + 40 px in 30 ticks, net); lopen alleen haalt het niet (80 px = 40 ticks): hij vraagt een sprong |

**Aanval B: schoepenzwiep (alleen fase 2).**

| Wat | Waarde |
|---|---|
| Doel | De helft waar P1 is (`x < 300` of niet) |
| Vlak | 300 × 24 px op **y 36–60** (die helft van muur tot midden) |
| Tijden | aanloop **30**, actief **8**, herstel 20 |
| Tell | De schoepen aan die kant draaien op; een horizontale lichtstreep op 36–60 px; aanzwellend water-gesuis (§9) |
| Ontwijken | **op de vloer blijven** (lichaam 0–30 < 36: 6 px marge; gewoon doorlopen, niet springen tijdens de 8 actieve ticks) of **hoog zijn**: bij een bounce vanaf je echo zijn je voeten **36 ticks** boven 60 px, dus het venster om af te zetten is **± 28 ticks**. **Niet** op je echo staan: zijn plank ligt op 30, je lichaam op 30–60 zit in het vlak (afwijking van GM-05b, §8) |

**Het rad raken (verplicht).** Het rad (GMB-04, y 100–140) is met een sprong niet te raken: het aanvalsvlak reikt bij de top tot 73 px. Wel met:

| Actie | Solo (echo) | Co-op (partner) | Wat het haalt |
|---|---|---|---|
| **Bounce** (hoofdroute) | Loop naar de muur aan de kant van het rad, **keer** en spring meteen: je ontmoet je echo **D/2 = 30 ticks** na het keren op **D = 60 px** van de muur (gdd §4.3), het plank-signaal (E-07d) licht op. Bounce: je zweeft van 60 naar 128 px van de muur, over het rad (46–142) | Bounce op de partner, die waar ook onder het rad staat | Aanvalsvlak boven 100 px gedurende **28 ticks** (voeten ≥ 77 px, bounce-tick 10–38): **2 treffers per bounce** (v0.1.3): de herhaaltijd van AANVAL is 20 ticks, dus de eerste slag op bounce-tick 10–18 en de tweede 20 ticks later. Een derde past niet (40 > 28). Wie maar één keer raakt, krijgt de tweede treffer bij een volgende bounce aan dezelfde kant |
| **Lancering** (meesterroute) | Lanceerhouding (C-11): sla bij de muur, houd vast, je echo staat D ticks later in houding; springen op `T + D − 21 … T + D − 3` (**19 ticks**), wachten **D − 21 = 39 ticks** | Partner slaat en houdt vast (12 ticks), jij stapt erop | Voeten tot ± 142 px: je komt **boven** het rad; dan **neerslag** (V-01): het vlak onder je raakt het rad zolang je voeten op 100–160 px zijn, **stuit** (`v.y = −5`) en weer: de treffers van een kant (2) zonder te landen, en je bent vóór het rad draait al weg |
| **Vang** | Val vanuit een bounce terug op je echo (hij staat waar jij D ticks eerder liep): zwiep `v.y = −6`, nog een treffer | De partner vangt je onder het rad | Zoals de bounce |

**Schade:** treffer van P1 of P2 op het rad **33 SE** (v0.1.5, #247: fase 2 in ± 10 kanten; v0.1.3: 18, was 15, GM-07: 10; §8), gewone echo-treffer 5 (de echo herhaalt je slag in de lucht als het rad er nog hangt; na twee slagen in één bounce trilt het rad al, dan raakt de echo niets), +2 LP per treffer (LM-02). In co-op **25 SE** (`coop_schaal` = 1,32, v0.1.5; §3.8). Met 33 SE blijft één keer-run met 2 slagen één kant (`kant_treffers` = 2, niet de SE, bepaalt de kant). Wie één keer per bounce raakt, heeft twee keer-runs per kant nodig: de beginner komt zo op ± 19 kanten (gemeten 121 s, §3.9 v0.1.5), ongeveer zoveel als de geoefende run in v0.1.3. **Wegdraaien:** na **2 treffers van P1 en P2 samen** (`kant_treffers` in data, 2; GM-07 had 3; de echo telt niet mee) of na **480 ticks** (`kant_ticks`, v0.1.3; was 180): het rad **trilt en ratelt 20 ticks** (tell), en draait dan in **60 ticks** naar `x_rad` aan de andere muur. Draaien doet niets (geen contactschade); het rad is tijdens trillen en draaien niet te raken. Je loopt mee naar de andere muur, keert, en het begint opnieuw: het wegdraaien maakt van elke kant een nieuwe keer-run. Wisselt de modus in fase 2 (drop-in of drop-out, C-03/C-05) en hangt het rad daardoor op de verkeerde plek (GMB-04: solo `D + 34`, co-op 94), dan trilt en draait het meteen, zoals na `kant_ticks`, naar de andere muur, op de plek van de nieuwe modus. Bij D = 60 is dat dezelfde plek, dus dan gebeurt er niets.

**Keren op de maat (ontwijken in fase 2, v0.1.3).** Een keer-run vraagt twee dingen: de echo moet op de vloer lopen als je op hem landt, en je mag de zwiep niet in vliegen. Daarom hoort elke keer-run bij één venster in de maat, één keer per twee maten (180 ticks: pompslag, zwiep). Met `T` = de tick van het keren, `J = T + max(0; (2D − 130)/4)` = de afzet naar de echo en `L = J + 33` = de landing op zijn plank geldt:
- **Zwiep:** de voeten van P1 zitten tussen 6 en 60 px (het lichaam raakt y 36–60) van `J + 1` tot `L + 6` (opstap naar de echo, op de plank, het begin van de bounce) en van `L + 42` tot `L + 52` (de val na de bounce). Geen actieve zwiep-tick op de helft van P1 in die twee stukken.
- **Pompslag:** van `J + 6` tot `L + 43` ben je boven 24 px, dan raakt hij je niet. Valt hij daarbuiten terwijl je op de vloer bent, dan spring je eroverheen (afzet 16 ticks vóór het actieve vlak, 40 ticks in de lucht, zoals in fase 1). Die sprong mag niet vallen in `L − D − 10 … L − D + 5`: de echo speelt hem dan na op het moment dat je op hem landt. Hij mag ook niet over de afzet `J` heen lopen.
- **Wat dat bij D = 60 betekent:** keer tussen het **einde van de veeg** van de zwiep (53 ticks vóór de maat van de pompslag) en **24 ticks na het begin van de aanloop** van de pompslag: een venster van 78 ticks (1,3 s). De bounce ontwijkt dan de pompslag, en de zwiep komt pas als je weer op de vloer loopt. De tell van de zwiep (water-gesuis, lichtstreep) is je teken: **na de veeg keren**. De vensters per D staan in §7.
- Kom je te vroeg aan, dan loop je heen en weer in de aanloopstrook tot het venster opengaat. **Geen stilstand (MP-1: 30 ticks binnen 24 px):** de strook is minstens **48 px** breed (van `2D + 24` tot `2D + 72` px van de muur) en je loopt hem steeds helemaal af, met 2 px/tick; zo kom je in elke 30 ticks ≥ 24 px van je plek. Gemeten in PR #219: per kant gemiddeld 187 / 143 / 100 / 13 ticks bij D = 60 / 90 / 120 / 180 (§3.9).

Zo wordt elke kant ± 4 maten (± 360 ticks) van keer tot keer, voor een loper en voor wie dasht (§3.9). Elke aanval van fase 2 is te ontwijken zonder dat de keer-run breekt: met 5 LP versla je hem solo zonder dood (B-9b).

**Waarom zonder echo onmogelijk (C-16-test):** geen richels, geen adds in fase 2, het lichaam is niet begaanbaar, de kern en het schot hebben in fase 2 geen hurtbox, een sprong reikt tot 73 px. Er is niets om op te bouncen of van te stuiten behalve je echo of partner.

### 3.6 Wankel en de finisher (GM-08, C-14)

| Stap | Wat | Tijden |
|---|---|---|
| Wankel | Op 300 SE: hij hapert, het carillon valt stil, geen aanvallen, geen tijdslimiet. De merkplek op de ketel (GMB-05) gaat open: een gloeiende peilmerk-vorm | — |
| Merk | P1 (of P2) slaat de merkplek: merk + bereikcirkel | solo leeft het merk D + 30 = **90 ticks**; in co-op **150 ticks** (C-12e, gdd v0.8) |
| Knal | Solo: de echo herhaalt de slag als merksprong (doelstreep vanaf 30 ticks vooraf); co-op: de ander slaat het merk | solo `t_f = slag + D + 3` = **63 ticks** na de slag |
| Finisher | De gedeelde echo (de schim van machinist en sluiswachter samen) speelt jullie laatste 600 ticks af in 120 ticks (C-14 c); elke slag van P1 en het tweede lichaam vanaf `BOSS_START` = één finisherslag, +1 LP | 120 ticks; mislukt nooit |
| Einde | `BOSS_VERSLAGEN` op `t_f + 120`; hij lost op in licht, meter naar 100 LP (GM-10) | — |

Solo met D = 60 is de langste wacht in Wankel de 63 ticks tussen je slag en de knal, en je mag in die tijd gewoon lopen.

### 3.7 Vensters en stilstand (GM-09, pitch P1)

| Verplicht moment | Venster (D = 60) | Formule | Stilstand die het vraagt |
|---|---|---|---|
| Schot merken | onbeperkt (het schot staat er tot je slaat) | — | 0 |
| Echo knalt het schot (solo) | merk leeft 90; knal op 63 → 27 ticks marge | `D + 30`; knal `D + 3` | 0: je mag weglopen |
| Partner slaat het schot (co-op) | merk leeft **150 ticks** | 150, vast (C-12e) | 0 |
| Kern slaan | ≤ 300 ticks per opening | — | 0 |
| Pompslag ontwijken (springen) | 24 ticks | vast | 0 |
| Zwiep ontwijken (bounce) | ± 28 ticks; op de vloer blijven: onbeperkt | vast | 0 |
| Bounce op de echo na keren | ontmoeting 30 ticks na het keren; bounce-buffer 10 + coyote 6 = **17 ticks** voor JUMP | `D/2`; afzet `(2D − 130)/4` ticks na het keren (§7) | 0 |
| Rad raken uit een bounce | 28 ticks per bounce, 2 slagen (eerste op bounce-tick 10–18) | vast | 0 |
| Rad per kant | ≤ 480 ticks of 2 treffers | — | 0 |
| Keren op de maat (solo, §3.5) | 78 ticks per 180: van het einde van de zwiep-veeg tot 24 ticks in de aanloop van de pompslag | §7 | 0: heen en weer in een strook van ≥ 48 px; gemeten ± 187 ticks bij D = 60 (§3.9) |
| Solo-lancering | 19 ticks om af te zetten | `T + D − 21 … T + D − 3` | **39 ticks** wachten (optioneel) |
| Wankel → knal | onbeperkt; solo knal 63 ticks na je slag; co-op merk 150 ticks voor de partner | `D + 3`; co-op 150 | 0–63 |
| Merken op de doelhelft (co-op, GMB-14) | 120 ticks per maat (van tick 46 tot en met het volgende actieve vlak); wissel ± 36 ticks lopen | vast | 0: je loopt elke maat door de machine (P2 verwacht ± 70–90, §3.10) |

**Verwachte MP-1 bij D = 60** (scripted geoefende run): langste stilstand **≤ 60 ticks** in beide modi; met de optionele solo-lancering ≤ 70. De grens is 300. Alle vensters zijn ≥ 17 ticks (eis: ≥ 10).

### 3.8 Solo en co-op

| Onderwerp | Regel |
|---|---|
| Wie wordt aangevallen | Alleen **P1** (P2 en de echo zijn onkwetsbaar, E-14h, C-02). Pompslag en zwiep richten op de helft of de x van P1; **in co-op valt de pompslag van fase 1 om en om links en rechts** (GMB-14) |
| Wat P2 doet | Fase 1: merken op de doelhelft, elke maat door de machine (GMB-14). Fase 2: drager, en springer als P1 op de maat moet wachten (GMB-15). Wankel: ontsteker (GMB-16). Verwachte stilstand per fase: §3.10 |
| Schaal | **`coop_schaal` = 1,32** (v0.1.5, #247): de radtreffer in co-op is 33 / 1,32 = **25 SE**, ± 14 kanten (de LGD rekende met 1,5 en 20 SE, ± 15 kanten). Waarom 1,32 en niet 1,5: met 20 SE duurde co-op 98,1 s, langer dan solo bij D = 120 (MP-7 1,02), en co-op mag niet trager zijn dan solo (v0.1.3, besluit 1). Met 25 SE: co-op 85,0 s bij elke D, MP-7 0,87 / 0,95 / 0,95 bij D = 60 / 90 / 120. Remmen op co-op-snelheid (MP-7 ≥ ½): de drempels van fase 1 (GMB-11), de 2 treffers per kant samen in fase 2, en het rad op een vaste plek in co-op (94 px van de muur, GMB-04). *v0.1.3: 1,0 (18 SE), co-op 95 s.* **De camera** staat van `BOSS_START` tot `BOSS_VERSLAGEN` vast op de arena (GM-01, besluit LGD in #247; `kadewijk.gd` `arena_view`), solo en co-op, ook na een respawn en een nieuwe `BOSS_START` |
| Drop-in/out | Volgens C-03/C-05: de partner neemt de echo over of andersom, ook midden in een opening of in Wankel; merken van P2 knalt de echo na een drop-out (C-12 b). Geen moment vraagt twee live spelers (C-16 e) |
| Opnieuw proberen | GM-11: 0 levenspunten → respawn bij het gemaal, de boss op 1500 SE en fase 1, adds weg, meter blijft |

### 3.9 Verwachte duur (D = 60; model, getoetst aan B-9 (142,9 tegen 142,3 s); fase 1 en Wankel gemeten)

**Wat B-9 liet zien (PR #209, bot met 2 slagen per bounce, zonder ontwijken in fase 2, P1 onsterfelijk):** solo 142,3 / 141,0 / 141,8 / 161,8 s bij D = 60 / 90 / 120 / 180 (met 1 slag per bounce 172,6 s bij D = 60); co-op 80,6 / 72,6 / 64,2 / 51,8 s; MP-7 0,57 / 0,51 / 0,45 / 0,32. De raming van v0.1.2 (± 330 ticks per kant, 2 treffers plus de echo) klopte niet om twee redenen: (1) `kant_ticks` = 180 sloot het venster aan de andere kant 260 ticks na het einde van de vorige kant, terwijl P1 er ± 250 nodig heeft om de andere muur te halen en de echo te ontmoeten: de bot haalde ± elke tweede kant; (2) na twee slagen in één bounce trilt het rad al, dus de echo raakt niets en een kant is 30 SE, niet 40.

**Een kant, nagerekend** (beweging gdd §2.5a: lopen 2,0 px/tick, dash 10 ticks × 4,0 en 20 ticks herhaaltijd, gemiddeld ± 3 px/tick; bounce `v.y = −6`, zwaartekracht 0,25):

| Stuk | D = 60 | Formule |
|---|---|---|
| Tweede slag (bounce-tick 30, voeten ± 97 px) tot de vloer | ± 23 | vast |
| Oversteek van het rad (`D + 34`) naar de andere muur | 498 px: lopen 249, met dash ± 185 | `558 − D` px; de laatste `2D + 24` px lopend, zodat de echo achter je op de vloer loopt |
| Keren tot de landing op de echo | 33 | `max(0; (2D − 130)/4) + 33` |
| Twee slagen | +10 en +30 | vast |
| **Keer tot keer** | **loper ± 330, met dash ± 270** | loper bij elke D ± 330 (de oversteek wordt korter met D, de ontmoeting duurt `D/2` langer) |
| Met het keervenster in de maat (§3.5) | **± 360** (4 maten) | het venster komt één keer per 180 ticks |

**`kant_ticks` = 480.** Het rad hangt aan de andere kant tot `80 + kant_ticks` ticks na de tweede slag van de vorige kant (20 trillen + 60 draaien + `kant_ticks`), en de tweede slag ligt `L + 30` na het keren. Een kant gaat dus nooit op tijd verloren als keer tot keer ≤ `76 + kant_ticks`. Met 480: ≤ 556 ticks, genoeg voor een loper die **één keervenster mist** (360 + 180 = 540). Met 180 haalde de bot het niet; 300 haalt de geoefende bot net, maar een loper die 40 ticks aarzelt niet meer. Langer dan 480 levert niets op: het rad draait toch weg na 2 treffers. Een speler die maar één keer per bounce raakt, haalt met 480 vaak nog een tweede keer-run aan dezelfde kant (± 360 ticks later).

**`kant_treffers` = 2, rad 18 SE.** Met 2 slagen per bounce is één keer-run één kant. Fase 2 (600 SE) is dan 600 / 36 = **± 17 kanten** (was ± 20 bij 15 SE). Dat is het aantal kanten van de raming in v0.1.1 (± 15) en houdt de solo-run in het midden van 90–150 s, met de ontwijk-wachttijden erbij. 3 treffers per kant zou per kant een tweede bounce aan dezelfde muur vragen (± 180 ticks meer) en meer `kant_ticks`: langer, en meer van hetzelfde.

**Verwachte duur, D = 60** (model van de keer-run met het venster uit §3.5, gemiddeld over de stand van de maat bij de fasewissel; fase 1 en Wankel zoals gemeten in PR #209):

| Deel | Solo (ticks) | Co-op (ticks) | Hoe |
|---|---|---|---|
| Fase 1 (4 openingen) | 1051 | 672 | gemeten (PR #209); verandert niet |
| Fasewissel | 60 | 60 | vast |
| Fase 2 | ± 6000 | ± 5040 | solo: ± 17 kanten van ± 360 ticks (4 maten); co-op: ± 25 kanten van ± 194 ticks (gemeten 3873 voor ± 20 kanten), × 1,25 voor de schaal 1,5, + ± 8 ticks per kant om de zwiep te ontwijken (model; gemeten werd het 133,9 s, zie de bevinding hieronder) |
| Wankel + finisher | 305 | 231 | gemeten |
| **Totaal** | **± 7400 (± 123 s)** | **± 6000 (± 100 s)** | MP-7: 100 / 123 = **0,81** |

**Per D** (solo: model; co-op: met het rad op 94 px, dus fase 1 en 2 gelijk bij elke D):

| D | Solo (model) | Co-op (model, ×1,5) | MP-7 (model) | MP-7 zonder vaste co-op-plek (model) |
|---|---|---|---|---|
| 60 | ± 123 s | ± 100 s | 0,81 | 0,81 |
| 90 | ± 123 s | ± 100 s | 0,81 | 0,73 |
| 120 | ± 122 s | ± 100 s | 0,81 | 0,65 |
| 180 (regressie) | ± 133 s | ± 99 s | 0,75 | **0,48** |

Alle cijfers in deze tabel zijn **modelwaarden**; de meting staat hieronder.

**Bevinding B-9b (PR #219, bot met ontwijken, 5 LP; `coop_schaal` 1,5):**

| D | Solo | Co-op | MP-7 | Lopend wachten per kant, max / gem. (ticks) |
|---|---|---|---|---|
| 60 | 123,1 s | 133,9 s | 1,09 | 191 / 187 |
| 90 | 122,5 s | 133,9 s | 1,09 | 148 / 143 |
| 120 | 122,0 s | 133,9 s | 1,10 | 103 / 100 |
| 180 | 131,9 s | 133,9 s | 1,02 | 14 / 13 |

0 treffers op P1 in fase 2. Realistische speler (D = 60, geen dash, 40 ticks aarzeling) 138,1 s; beginner (1 slag per bounce) 155,9 s. Solo klopt met het model (± 123 / 123 / 122 / 133 s). Co-op niet: het model rekende ± 100 s, gemeten 133,9 s (het ontwijken in co-op kost meer dan de geraamde 8 ticks per kant).

**Besluiten na de meting:**
1. **Co-op langer dan solo mag niet**, ook al is MP-7 ≥ 0,5 gehaald. Co-op moet de sterkere vorm zijn (#51, 7A). `coop_schaal` 1,5 → **1,0**: fase 2 in co-op wordt dan ± 7070 / 1,5 ≈ 4710 ticks, co-op ± 5680 ticks = **± 95 s** bij elke D, MP-7 **± 0,77** (solo 123 s). Dat ligt in 90–150 s en onder solo. Te meten in B-13.
2. **Lopend wachten boven 100 ticks bij D ≤ 90: voor de slice geaccepteerd**, geen waarde-aanpassing. Redenen: (a) het is geen stilstand volgens MP-1, met de strook van ≥ 48 px (§3.5); (b) het is het ritme dat de boss toetst ("na de veeg keren", GM-04), en de knoppen in data (`kant_ticks`, `rad_treffer`) veranderen het wachten niet: het hangt aan de maat en de zwiep; (c) het korter maken vraagt een ander patroon, geen andere waarde. **Voorwaarde:** de mijlpaal-test (T11) meet of het stoort (MP-5, GM-d). Stoort het, dan komt in v0.1.4 de zwiep alleen op de helft **zonder** het rad, zodat het keervenster elke maat komt en het wachten onder de ± 90 ticks blijft. B-9b rapporteert er ook bij welke regel het eerdere venster sloot (zwiep, pompslag of rad), zodat die keuze op data rust.

**Hoe gevoelig** (solo, D = 60, model): bot zoals in PR #209 maar mét ontwijken ± 123 s; een loper zonder dash ± 124 s; een loper die 40 ticks aarzelt vóór elke oversteek ± 132 s, 80 ticks ± 149 s. Zonder ontwijken (zoals de bot nu) ± 100 s. Met 1 slag per bounce niet gerekend; verwacht ± 1,5× (de beginner). Het venster van 90–150 s haalt dus de geoefende run én een realistische speler met wat aarzeling.

**Doel (Lead-review #185):** scripted **90–150 s** per modus; een geoefende mens ± 1,5× zo lang, een eerste speler 8–12 min met pogingen (#2). **Knoppen, in data** (`slice.csv`): het aantal openingen en hun drempels (GMB-11), `kant_treffers`, `kant_ticks`, `rad_treffer`, `coop_schaal` en de SE van fase 2; **niet** de vensters of aanlopen. Risico: ± 17 kanten in fase 2 kan eentonig worden; de mijlpaal-test meet het (GM-d, MP-5). Dit zijn rekenwaarden: B-9 meet ze opnieuw (B-9b, B-13).

---

**Meting v0.1.5** ([#247](https://github.com/cesarvangerwen-glitch/echoborn/issues/247), B-9b opnieuw, `test_boss_runs.gd` en `test_kadewijk_boss.gd`, de bot met ontwijken en 5 LP; data van §3.3 en §3.5 v0.1.5). In ticks, met seconden waar het om de norm gaat:

| Run | Fase 1 | Fase 2 | Wankel + finisher | Totaal | Treffers / LP over |
|---|---|---|---|---|---|
| **Solo D = 60** (arena) | **1701 (28,4 s)** | **3809 (63,5 s), 10 kanten** | 305 | **5875 (97,9 s)** | 0 / 4 (adds) |
| Solo D = 90 / 120 / 180 | 1161 / 1175 / 1755 | 3807 / 3820 / 3902 | 320 / 335 / 365 | 89,1 / 89,8 / 101,4 s | 0 |
| Co-op (elke D) | 882 | 3918, 14 kanten | 241 | 5101 (85,0 s) | 0; MP-7 0,87 / 0,95 / 0,95 / 0,84 |
| Realistische speler (D = 60) | 1701 | 4528 | 267 | 6556 (109,3 s) | 0 |
| Beginner (1 slag per bounce, D = 60) | 1701 | 5233 | 276 | 7270 (121,2 s) | 0 |
| Kadewijk D = 60 / 90 / 120 / 180 (P1 komt rechts binnen) | 1680 / 1382 / 1276 / 1836 | 3808 / 3806 / 3819 / 3903 | 305–365 | 97,5 / 92,8 / 91,5 / 102,7 s | 0 |

Normen bij D = 60 (LGD, #247), getoetst: totaal 95–150 s ✓ (solo 97,9, Kadewijk 97,5, realistisch 109,3); fase 2 ≤ 65 s ✓ (63,5); fase 1 ≥ 24 s ✓ (28,4 / 28,0); 5 LP zonder dood ✓, ook de realistische run; MP-7 0,5 … 1,0 bij 60/90/120 ✓. **Co-op (besluit LGD in [PR #253](https://github.com/cesarvangerwen-glitch/echoborn/pull/253#issuecomment-6844358018)):** bij D = 60 duurt co-op **75–150 s**, met co-op ÷ solo 0,5 … 1,0 bij D = 60/90/120 (bij 180 alleen rapport). De oude ondergrens van 90 s vervalt: die paste niet samen met co-op ≤ solo bij D = 90 (89,1 s) en fase 2 ≤ 65 s solo. Gemeten: 85,0 s ✓.

**Bot (GP, #247), wat er veranderde in `boss_bot.gd`:** in fase 1 sprong P1 op zijn plek over de pompslag en landde hij op zijn echo, want die stond daar D ticks eerder. Bij D = 90 tilde de echo hem bij de volgende pompslag op, en zakte P1 met de echo het vlak in: één treffer per 2 maten, 3 in v0.1.3 en 5–7 met een langere fase 1. Nu springt hij naar een plek 20 px naar de ketel toe als hij anders op de echo zou landen, en mag hij ook vanaf de echo over de pompslag springen. Daarna 0 treffers van de boss in fase 1 bij elke D.

**Audio (§9.3):** geen andere regel nodig. De maat, de tellen en het ratelen van het rad veranderen niet; er zijn alleen minder kanten (± 10) en meer schotbreuken (7). Punt voor de Audio Director, geen blokkade: de krak bij de schotbreuk klinkt nu 7× per gevecht in plaats van 4×. Varieer hem, zodat hij niet sleets wordt.

### 3.10 Wat P2 doet in de boss (co-op, MP-7 (b); v0.1.6, [#289](https://github.com/cesarvangerwen-glitch/echoborn/issues/289))

**Werkaanname:** D = 60 (CEO-besluit 2026-11-12). De co-op-boss hangt niet van D af (het rad hangt op `rad_coop_muur`, GMB-04; de doelhelft hieronder kent geen D), dus de getallen gelden bij elke D. **De maat is de huidige MP-7 (b):** MP-1 apart voor P2, op zijn middelpunt, langste stilstand ≤ 300 ticks (gdd §4.5). AANVAL telt niet als beweging: wie op zijn plek slaat, staat stil. De Lead Game Designer werkt in [#290](https://github.com/cesarvangerwen-glitch/echoborn/issues/290) aan een algemene wachtmaat voor MP-7. Dit ontwerp rekent alleen met de huidige definitie; komt er een wachtmaat bij, dan meet B-14 die ook (zie de laatste alinea).

**Waar P2 nu stilstaat** (co-op-run van `boss_bot.gd` in de testarena, D = 60; STIL_EIND met bron `p2` uit het meetlog, nagedraaid op `main`):

| Deel | Ticks | Langste stilstand P2 | Waarom |
|---|---|---|---|
| Fase 1 + fasewissel | 0–942 | **925** (tick 30–954, x = 362) | P2 staat rechts van de ketel en slaat 10 ticks na P1 (de ontsteker). Hij wordt niet geraakt (C-02), dus hij hoeft de pompslag niet te ontwijken. In fase 1 heeft hij **geen enkele reden om te bewegen**. Pas als het rad in fase 2 hangt, loopt hij weg. |
| Fase 2 | 942–4860 | 60–116 per kant, **één keer 230** | P2 staat onder het rad als drager. Elke kant draait het rad naar de andere muur, en dan loopt P2 ± 360 px mee. 230 ticks: P1 miste een keervenster en liep heen en weer naast P2 (B-9b (3)), terwijl P2 bleef staan. |
| Wankel + finisher | 4860–5101 | ≤ 105 (tot `BOSS_VERSLAGEN`) | P2 loopt naar de ketel, knalt het merk van P1 en wacht de finisher af. |

Het probleem zit dus in **fase 1**: daar geeft het ontwerp P2 een taak (ontsteken) maar geen plek die verandert. Een sprongetje dat verder niets doet (`_fidget`, PR #287) zou de maat halen maar het gedrag niet veranderen. Daarom krijgt P2 hieronder in elke fase een **taak op een plek die met de maat verschuift**.

| ID | Regel |
|---|---|
| **GMB-14** | **Fase 1 co-op: de wissel.** (a) **Doel van de pompslag.** In co-op valt de pompslag **om en om links en rechts**. De eerste valt op de helft waar P1 aan het begin van de aanloop staat, zoals solo (§3.4), en daarna steeds op de andere helft. Solo verandert niets: de pompslag volgt de helft van P1. (b) **De doelhelft.** De doelhelft is de helft van de *volgende* pompslag. Ze springt om op de eerste tick na het actieve vlak (tick 46 van de maat van 120, §3.4) en blijft staan tot en met het actieve vlak van die volgende slag: dat is een venster van **120 ticks** per maat. In beeld gloeit de helft van het schot aan die kant (§9). Wat je leest: de stang slaat, en de gloed springt naar de andere kant, waar de volgende slag komt. **De doelhelft bestaat alleen zolang P2 meedoet** (v0.1.7, [#302](https://github.com/cesarvangerwen-glitch/echoborn/issues/302)). Bij een drop-out (C-05) gaat ze op die tick uit, ook midden in een maat: `doelhelft()` geeft *geen*, de gloed dooft en het meetlog krijgt `DOELHELFT` = geen. Zo springt de gloed niet meer om naar een helft waar de volgende slag niet hoeft te vallen. Bij een drop-in gaat ze pas aan op het begin van de volgende aanloop, op de helft van P1. (c) **Merken alleen vanaf de doelhelft.** In co-op zet een treffer op het schot of op de kern alleen een merk als het middelpunt van de slaande speler op de doelhelft staat (`x < midden` is links). Een treffer vanaf de andere helft op een schot of kern zonder merk zet geen merk. Op het intacte schot is dat een "tink" met 0 SE en 0 LP (VJ-07), op de kern een gewone treffer van 10 SE. **Knallen alleen vanaf de andere helft** (v0.1.6.1, Lead-review PR #295). Een treffer van het andere lichaam laat het merk alleen knallen (C-12 b) als het middelpunt van die speler op **de andere helft staat dan waar het merk gezet is**. Vanaf dezelfde helft knalt het niet: op het schot de tink (0 SE, 0 LP), op de kern 10 SE, en het merk blijft staan. Het merk leeft 150 ticks (C-12e). Zo dwingt de regel de wissel af. Een P2 die als ontsteker op één plek blijft staan, knalt hooguit elke tweede maat, namelijk alleen als het merk aan de andere kant gezet is. (d) **Wat dat vraagt.** De ontstekersrol verandert niet: P1 en P2 zetten en ontsteken allebei, maar het merk zet je op de gevaarlijke kant. P2 wordt niet geraakt (C-02), dus hij is de logische zetter. Hij **loopt elke maat door de machine** naar de doelhelft. Dat is ± 72 px, van ± 36 px aan de ene kant van het midden naar ± 36 px aan de andere kant, in ± 36 ticks. De ontsteker moet aan de andere kant staan, en dat is de veilige kant: de helft waar de stang net sloeg. Zo **kruisen ze elkaar elke maat** door het lichaam (GM-02: niet massief), en is de wissel meteen de ontwijking van P1. Springen over de pompslag (§3.4) blijft ook goed. (e) **Kern.** De kern is `Merkbaar` (§3.4), en voor hem geldt dezelfde regel: het merk zet je vanaf de doelhelft en je knalt het vanaf de andere helft (20 SE plus de ketting). Een gewone treffer van 10 SE kan van elke kant. (f) **Modus.** De kant van de pompslag wordt per maat gekozen op het begin van de aanloop: om en om als P2 dan meedoet. Na een drop-out (C-05) houdt een pompslag die al in de aanloop is zijn kant, want de tell is al gegeven. Vanaf de volgende aanloop volgt de pompslag P1. De doelhelft gaat op de tick van de drop-out uit (b), dus zetten en knallen kan **vanaf die tick** van beide kanten (v0.1.7; was: vanaf de volgende aanloop). Zo knalt de echo, die de slag van P1 op dezelfde helft herhaalt, het merk van P1 meteen. De echo knalt ook de merken van P2 (C-12 b). Na een drop-in geldt de wissel vanaf de volgende aanloop, met de eerste slag op de helft van P1. Tot dan geldt de solo-regel en is er geen doelhelft. (g) **Fasewissel en Wankel**: geen pompslag, dus geen doelhelft. Zetten en knallen kan van beide kanten. |
| **GMB-15** | **Fase 2 co-op: drager, en springer als P1 wacht.** (a) P2 is de drager onder het rad, zoals nu (§3.5). Na elke kant draait het rad naar de andere muur (GMB-04: de bot loopt van x 120 naar 480 en terug, ± 360 px), en die oversteek houdt P2 elke ± 270 ticks in beweging. (b) **Moet P1 op zijn keervenster wachten**, dan wisselen ze de rollen voor die bounce. Dat is het geval als bij aankomst onder het rad de vroegste afzet op P2 die B-9b (3) toelaat meer dan **60 ticks** later ligt. P1 gaat dan onder het rad op de vloer staan. Daar raakt de zwiep hem niet (lichaam 0–30 px < 36). P2 springt op P1 (C-10: de lichtplank van P1), bouncet en slaat het rad. Hij hoeft niet op de maat te letten, want de zwiep en de pompslag raken hem niet (C-02). Raakt een pompslag P1, dan springt P1 eroverheen (B-9b (2)). Staat P2 op dat moment op hem, dan gaat P2 mee (C-10). Een treffer van P2 op het rad telt als een treffer van P1: 25 SE in co-op (`coop_schaal`), en hij telt mee voor `kant_treffers`. **Alleen de afzet telt** (v0.1.7, [#302](https://github.com/cesarvangerwen-glitch/echoborn/issues/302)). De rolwissel kijkt naar de vroegste afzet, niet naar de bounce bij de landing. Mag P1 afzetten maar valt de landing nog vóór het keervenster, dan stapt P1 eraf en springt opnieuw, en zolang staat P2 als drager onder het rad. Dat is zijn taak (hij is de plank), en het blijft ruim onder MP-7 (b): gemeten 148 ticks tegen 300. Een rolwissel die ook de landing meeneemt, wint wat stilstand van P2 maar wisselt 10× per run en laat 4 kanten op tijd wegdraaien. Dan duurt co-op 124,7 s tegen solo 97,9 s, en dat is MP-7 (a) ± 1,27, boven 1,0. Die ruil maken we niet. (c) Waarom zo: GM §6 geeft P2 al de springerrol ("P2 kan zelf ook op P1 bouncen en het rad raken"), en het wachten van P1 bestaat alleen omdat P1 geraakt kan worden. Wie niet geraakt wordt, gebruikt die tijd. Zo staat P2 niet onder het rad te wachten op een springer die op de maat wacht. Hij staat er alleen als plank, terwijl P1 na een afzet opnieuw springt (b). |
| **GMB-16** | **Wankel co-op: ontsteker** (zoals nu, §3.6). P2 loopt van het rad naar de ketel (≥ 150 px) en knalt het merk van P1. Tijdens de finisher blijft P2 bestuurbaar (C-14 e), en hij hoeft niets. Dit deel is samen ≤ 241 ticks (gemeten Wankel + finisher), dus onder 300, ook als P2 de hele tijd stilstaat. |

**Verwachte stilstand van P2 per fase** (co-op, D = 60; bij elke D gelijk, zie de werkaanname). MP-1-telling: stilstand begint ± 18 ticks na het stoppen (de laatste 24 px lopen vallen in het venster van 30 ticks).

| Fase | Taak P2 | Nu (gemeten) | Verwacht | Bovengrens (waarom) |
|---|---|---|---|---|
| Fase 1 | merken op de doelhelft, elke maat ± 72 px door de machine (GMB-14) | 925 | **± 70–90** (120 − 36 lopen − ± 18) | **≤ 240**: alleen als hij in een kernopening één wissel overslaat en gewoon doorslaat. Dan staat hij 2 maten stil, en het venster van 120 per maat houdt het daaronder |
| Fasewissel (60) | naar de kant van het rad (GMB-12: de kant waar P1 níét is) | in 925 | **≤ 60** | ≤ 120: de rest van de laatste maat plus de wissel |
| Fase 2 | drager; springer als P1 > 60 ticks moet wachten (GMB-15) | 60–116, max 230; v0.1.7: 148 | **± 60–90** per kant (landing 32 + twee slagen 30 + trillen 20, dan loopt hij mee); **± 150** als P1 na de afzet opnieuw moet springen | ≤ 180: de rolwissel kijkt alleen naar de afzet (GMB-15 b). Een tweede sprong van P1 is ± 60 ticks extra bovenop een kant |
| Wankel + finisher | ontsteker (GMB-16) | ≤ 105 | **± 100** | ≤ 241 (de hele Wankel plus de finisher) |
| **Hele boss** | | **925**; v0.1.7: 148 | **± 150, fase 2 tot 180** (was ≤ ± 120) | **≤ 241**, norm 300 |

**P1** verandert mee. In fase 1 co-op wisselt hij elke maat van kant (of springt hij), en zijn langste stilstand blijft ± 90 (gemeten 89). In fase 2 staat hij bij een rolwissel ± 60–90 ticks als drager onder het rad, en dat is niet langer dan nu.

**Waarom niet pompen, adds of het rad in fase 1.** *Pompen*: de arena heeft geen `Pomprad`. Het grote rad pompt niets (GM-02), en een pomptaak in de arena zou een nieuwe mechaniek zijn zonder solo-vorm. *Adds*: ze komen alleen na opening 1–3, er zijn er hooguit 2 en ze lopen naar P1. Daarmee vullen ze geen 900 ticks, en elke maat meer adds maakt fase 1 voor P1 zwaarder. *Het rad*: dat hangt pas in fase 2. De wissel gebruikt alleen wat er al is (de pompslag, het merk, het niet-massieve lichaam), dus het is een plaatsregel op het merk en geen nieuwe actie.

**C-16 blijft gelden.** (a) De finisher start alleen met een merk-combo (Wankel, ongewijzigd). (b) Het schot breekt alleen door een merk-ontploffing. Het merk zet je nu op de doelhelft en je knalt het vanaf de andere helft. Slaat P2 nooit, dan knalt niemand het merk van P1. Ook een add knalt het niet, want het merk van P1 op een add doet 10 SE en blijft staan (C-12 b). Dus fase 1 eindigt nooit en de boss is **niet te verslaan**: de C-16-run "P2 slaat nooit" blijft rood voor de boss (B-9). (c) Elk venster ≥ 10 ticks: de doelhelft staat 120 ticks per maat vast, en het merk leeft 150 ticks. **Zonder aparte versie:** de doelhelft is een plaatsregel in dezelfde arena en op hetzelfde moment, net als de vaste co-op-plek van het rad (GMB-04). Er is geen tweede arena, geen ander patroon en geen extra aanval: alleen de kant van de pompslag en de kant van zetten en knallen hangen af van de modus. (d) Ongewijzigd. (e) Geen moment vraagt twee live spelers: na een drop-out geldt de solo-regel (GMB-14 f), en solo is de boss gelijk aan v0.1.5.

**Duur (MP-7 (a)).** *Fase 1 co-op*: het merk komt hooguit 36 ticks later, alleen als P2 net onderweg is. Verwacht ± 900–1000 ticks (was 882). *Fase 2 co-op*: bij een rolwissel is de kant eerder klaar. Fase 2 wordt iets korter, met ± 1 kant op 14 als P1 wacht. Netto verwacht co-op **± 85–88 s** bij elke D (was 85,0), MP-7 (a) **± 0,87–0,90 / 0,95–0,99 / 0,95–0,98** bij D = 60 / 90 / 120 (solo 97,9 / 89,1 / 89,8 s). De krapste is D = 90. Komt co-op boven solo uit (MP-7 > 1,0) bij D = 90 of 120, dan zet de Combat Designer `coop_schaal` lager: 1,32 → 1,25 is ± 1 kant minder, ± 4–5 s. Komt co-op bij D = 60 onder 75 s, dan zet hij `coop_schaal` hoger. Het is een knop in data, geen nieuwe regel. **Gemeten** (v0.1.7, B-14 deel 1, met de gekozen afzet-variant van GMB-15 (b)): co-op D = 60 **84,4 s** in de testarena (MP-7 (a) **0,86** tegen solo 97,9 s; PR #301), en de boss in de Kadewijk-arena 5130–5131 ticks, **± 85,5 s** (± 0,88 tegen solo 97,5 s; PR #304). De landing-variant gaf **124,7 s** (± 1,27, boven 1,0). `coop_schaal` hoeft dus niet te veranderen.

**Wachten (MP-7 (e)).** Dit ontwerp sluit aan op MP-7 (e) uit PR #293 (LGD, [#290](https://github.com/cesarvangerwen-glitch/echoborn/issues/290)). Na de merge daarvan meldt de note van B-14 (e) het wachten per fase voor P1 en P2 (per periode ≤ 300 ticks, samen ≤ 5 %). Tot dan geldt alleen MP-7 (b). Het lopend wachten van P1 in fase 2 (B-9b, §3.9 besluit 2) valt daar dan ook onder.

---

## 4. Wat de boss niet heeft (O-17, O-20)

- **Geen pareren en geen aanval omhoog** in de slice; O-17 gaat terug naar **fase 3**. Een aanval omhoog zou het rad met een sprong bereikbaar maken (73 px + bereik omhoog) en daarmee fase 2 zonder echo te doen; pareren is er niet in de slice (`wereld.md` §2.1). In fase 3 beslissen LGD en Combat Designer erover, met de regel uit E-14f.
- Geen aanval op de echo of P2, geen aanval die stilstand beloont, geen moment dat twee live spelers vraagt.

---

## 5. Toets aan de pillars

| Pillar | Toetsvraag | Antwoord |
|---|---|---|
| P1 | Maakt de echo deze actie vloeiender of krachtiger, zonder stilstand? | Ja: het schot breekt terwijl je doorbeweegt; je tweede slag op de kern; keren en bouncen is zowel de weg naar het rad als de ontwijking van de pompslag. Langste wacht 39–63 ticks bij D = 60 |
| P2 | Gaat de weg open door licht of een vaardigheid, geen raadsel? | Ja: na de boss gaat de wijk aan (GM-10); in fase 2 beloont het rad de Neerslag uit S7; vijanden zijn sterker in het donker (VJ-06) |
| P3 | Werkt het met een partner en met je echo, in dezelfde arena? | Ja, elk moment in beide vormen (§3.1); remmen op co-op-tempo (§3.8) |
| Puzzeltoets | Moet je stilstaan om een volgorde of timing te bedenken? | Nee: je slaat, ontwijkt en bouncet in het ritme van de maat |

---

## 6. Bouwopdracht voor de Gameplay Programmer

Code in `game/` (SM-review, `WERKWIJZE.md` §5). De arena S8 bouwt T8a ([#83](https://github.com/cesarvangerwen-glitch/echoborn/issues/83)); T8b levert de boss en de vijanden als scènes die T8a erin zet. Bestandsnamen zijn een voorstel; de Technical Director beslist. Bestaande basis: `game/scripts/combat/combat_target.gd` (soorten `ENEMY`, `ARMORED`, `DUMMY`) en `combat.gd`. Elke waarde uit dit document komt in **`game/data/vijanden/slice.csv`** (één regel per type en per boss-parameter), zodat de Combat Designer kan bijstellen zonder code; de code leest ze in.

| # | Wat | Klaar als |
|---|---|---|
| **B-1** | **Gedeelde vijandregels**: `v(D)` (VJ-03), stil na treffer (VJ-04), afstandsregel per paar met startafstand `a` uit data, 40 px tussen vijanden die geen paar zijn (VJ-05), donker/verlicht (VJ-06), 45 ticks onkwetsbaar na een treffer op P1 (VJ-02); `slice.csv` inlezen | Tests: `v(D)` = 0,5 / 0,5 / 0,473 / 0,287 bij D = 60 / 90 / 120 / 180; twee Kadelopers van een paar komen nooit dichter dan hun `a` (28 of 40–44 px), twee die geen paar zijn nooit binnen 40 px; `v` ≤ 0,70 bij elke D; L-13 (c) per D (het merk ligt na D + 3 ticks ≤ 80 px van de opgenomen positie); in S9 de verlichte waarden |
| **B-2** | **Kadeloper** (de basisvijand met de waarden van §2.2: haakslag 30/6/20, vlak 20 × 16 op y 4–20) | Test: aanval alleen binnen 16 px, P1 op de plank van de echo wordt niet geraakt; E-paar op 28 px: één slag merkt beide, één knal doodt beide; K-paar op 40 px: twee merken + knal = ketting 20 + 25, beide dood |
| **B-3** | **Schotdrager** (soort `ENEMY` met `armor_intact` en lopen, §2.3) | Tests: treffer op het intacte pantser = 0 SE, 0 LP, merk gezet, event voor de "tink"; in een E-paar op 28 px breekt de ontploffing van het merk op de Kadeloper het pantser en doet verder 0; daarna 30 SE; komt niet terug |
| **B-4** | **Dwaallicht** (§2.4): baan, duik 30/8/40, stuitdoel (V-01b), terugkeer alleen in het donker | Tests: neerslag op een Dwaallicht op 40 px = stuit + merk; de echo herhaalt het als merksprong (30 SE samen); in S7 haalt de scripted run de overkant via twee stuiten bij elke D |
| **B-5** | **Boss-basis** `Boss` (C-14 a): 1500 SE, fasen en drempels (GMB-10–13, met klemmen), `BOSS_START`/`BOSS_VERSLAGEN`, arena dicht/open (GM-01), reset bij respawn (GM-11); bouwt de testboss van de C-14/C-16-test mee (O-14) | De C-14-test en de C-16-test van gdd §4.6 groen, eerst op de testboss, daarna op de Gemaalmeester |
| **B-6** | **Maat en aanvallen**: een maatklok (120 / 90 ticks, eerste aanval 60), pompslag fase 1 (vaste helften) en fase 2 (op x van P1), schoepenzwiep (y 36–60, 300 px), om en om in fase 2; per aanval een vlag `aanloop`/`actief` die tests en HUD/audio lezen | Tests: elke aanloop ≥ 30 ticks; pompslag raakt P1 op de vloer in het vlak, niet P1 in de lucht of op de plank; zwiep raakt P1 op de plank van de echo en op de top van een sprong, niet op de vloer en niet boven 60 px; niets raakt de echo of P2 |
| **B-7** | **Fase 1**: schot/kern als `Pantserdoel` dat weer dichtgaat (300 ticks of drempel), merkplek op (300, 36), spuigaten met max. 2 Kadelopers (30 ticks gloeien, 30 ticks inactief), geen adds vóór opening 1 | Tests: solo-script "sla het schot één keer en loop weg" breekt het op `slag + D + 3` bij elke D; een gewone treffer op het intacte schot doet 0; precies 4 openingen in een run die elke opening tot de drempel slaat; in co-op leeft een merk 150 ticks (C-12e); echo uit: het schot breekt nooit |
| **B-8** | **Fase 2**: het rad op `x_rad = D + 34` (debugmenu zet het bij een wissel van D, SL-05), 18 SE per treffer van P1/P2 (co-op: gedeeld door `coop_schaal`), 5 van de echo, 2 treffers (P1 + P2, `kant_treffers` uit data) of `kant_ticks` (480) → 20 trillen → 60 draaien; in co-op op `rad_coop_muur` (zie B-13); vloerteken (GMB-04); fasewissel naar de kant waar P1 niet is | Tests: (1) per D: sprong + aanval op elke x van de vloer (stap 4 px) raakt het rad nooit; (2) per D: keren tegen de muur + bounce raakt het, met de late bot (bounce 4 en 8 ticks te laat) nog steeds; (3) lancering + neerslag geeft 2 treffers zonder landen; (4) co-op: bounce op P2 op elke x onder het rad raakt het |
| **B-9** | **Scripted boss-runs** (`boss_bot.gd`, naar het voorbeeld van `flow_bot.gd`): solo en co-op, per D = 60 / 90 / 120 / 180; plus de C-16-runs (echo uit; P2 slaat nooit) en een run met drop-out van P2 in fase 1 en in Wankel | Elke run haalt MP-1 ≤ 300 ticks (verwacht ≤ 60 bij D = 60), de echo breekt nooit; de C-16-runs halen in 6000 ticks geen finisher; de scripted solo-run duurt bij D = 60 **90–150 s** (§3.9); de duur per deel komt in een tabel voor de Combat Designer. Vanaf v0.1.3 met de bouwregel van B-9b (ontwijken, 5 LP) |
| **B-9b** | **Ontwijken in fase 2 en 5 LP** (v0.1.3, #213). De bot ontwijkt in fase 2 zoals §3.5 *Keren op de maat* het zegt: (1) **plannen**: `_plan` kiest de vroegste keertick `T` die (a) in een venster van het rad valt met **beide** slagen (zoals nu), (b) geen actieve zwiep-tick heeft in `J + 1 … L + 6` of `L + 42 … L + 52` (`J = T + max(0; (2D − 130)/4)`, `L = J + 33`; de bot rekent de maat vooruit, die ligt vast) en (c) elke pompslag in `T − 140 … L + 52` buiten `J + 6 … L + 43` te ontwijken heeft met een sprong `a − 16 … a + 24` (`a` = eerste actieve tick) die `L − D − 10 … L − D + 5` en `J` niet raakt; (2) **lopen**: in de oversteek en de aanloopstrook springt hij over elke pompslag die hem op de vloer raakt (afzet 16 ticks vóór het actieve vlak, `DODGE_LEAD`, met de looprichting erbij), behalve in het stuk van (1c); te vroeg = heen en weer in de aanloopstrook (zoals `hold`); (3) **co-op**: P1 springt pas op P2 als (b) geldt voor zijn opstap en val (met `J` = zijn afzet, `L` = zijn landing op P2), en springt over de pompslag op de vloer; P2 blijft onder het rad. Runs: **solo en co-op per D met `p1.health` = `p1_health` (5)**, zonder genezing van buiten het spel; plus één solo-run bij D = 60 als **realistische speler** (geen dash in fase 2, 40 ticks aarzeling vóór elke oversteek). De oude runs met P1 onsterfelijk mogen blijven als meting van de treffers, niet als bewijs van "verslagen" | Elke run met 5 LP: verslagen zonder dood (geen respawn), **0 treffers op P1 in fase 2** (doel; de assert is ≤ 4 in de hele run, zodat P1 leeft); solo D = 60 **90–150 s**, ook de realistische run; co-op D = 60 **90–150 s**; MP-7 ≥ 0,5 bij elke D (D = 180 als note als het niet haalt); MP-1 ≤ 300; `RAD_DRAAI` reden `tijd` hooguit 1 per solo-run bij D ≤ 120. **Rapporteren** (in de note, geen assert): per kant het lopend wachten vóór het keervenster (max en gemiddelde per run; verwacht ≤ ± 100 ticks), en één solo-run bij D = 60 met **1 slag per bounce** (beginner: duur, kanten op treffers/tijd). Testnaam en melding zeggen "2 slagen per bounce, met ontwijken, 5 LP" |
| **B-13** | **Waarden van v0.1.3** (#213) in `slice.csv` en de code die ze leest: `rad_treffer` 15 → **18**, `kant_ticks` 180 → **480**, `coop_schaal` blijft **1.0** (na PR #219; was 1.5 in de eerste versie van v0.1.3), `kant_treffers` blijft **2**; nieuwe sleutel `gemaalmeester,rad_coop_muur,94,px` (co-op: middelpunt van het rad 94 px van de muur, los van D; GMB-04) in `EnemyData.REQUIRED`; bij een wissel van modus in fase 2 (drop-in/out) trilt en draait het rad meteen als de plek verandert (§3.5). 2 slagen per bounce blijft toegestaan: geen treffer-cooldown op het rad. De Gameplay Programmer zet de waarden in dezelfde PR als B-9b, zodat de tests die erop rekenen (`test_boss_rad.gd`, `test_boss_runs.gd`) in één keer meegaan | Tests: radtreffer 18 solo en in co-op; wegdraaien na 480 ticks; in co-op hangt het rad bij D = 60 / 120 / 180 op 94 px (co-op-test (4) van B-8 op die plek); drop-out in fase 2 bij D = 120: het rad trilt en draait naar `D + 34` aan de andere muur; de B-9b-runs halen hun "klaar als" |
| **B-10** | **Meetlog**: nieuwe events `BOSS_FASE` (1, 2, wankel), `SCHOT_BREUK`, `KERN_DICHT` (reden: drempel/tijd), `RAD_TREFFER` (bron, actie: bounce/lancering/vang/stuit), `RAD_DRAAI`, `BOSS_AANVAL` (soort, helft, raak/mis), `DOELHELFT` (co-op fase 1, links/rechts, en *geen* bij een drop-out; v0.1.6, v0.1.7, B-14) naast de bestaande `BOSS_START`, `FINISHER_START`, `FINISHERSLAG`, `BOSS_VERSLAGEN` | De events staan in het log van B-9; GM-a (tijd tot de eerste `SCHOT_BREUK`) en GM-b (`RAD_TREFFER` per minuut per actie) zijn eruit te rekenen |
| **B-11** | **Leesbaarheid in placeholder-beeld**: E-02t en E-14j op de boss-merken; de "tink" bij 0 SE (VJ-07); tells (stofstrook pompslag, lichtstreep zwiep, gloeiende spuigaten, trillend rad); schermschok bij schotbreuk (6 ticks, 2 px), radtreffer (3 ticks, 1 px), finisherstart; elk met een vlag die een test kan lezen | Zichtbaar in de build; de vlaggen in de tests van B-6–B-8 |
| **B-12** | **Antwoorden #190** (op PR #201): hoogtegrenzen van de aanloop (VJ-08: voeten P1 tussen −20 en +20 px van de vloer van de vijand, `aanloop_hoogte_min` = −20 en `aanloop_hoogte_max` = 20 in `slice.csv`) voor Kadeloper en Schotdrager; 45 ticks onkwetsbaar na een respawn (VJ-02, `onkwetsbaar_respawn` in `slice.csv`), niet na een dodelijke treffer | Tests: P1 recht boven een Kadeloper op 30 px (plank) of in de lucht: geen aanloop; P1 30 px lager dan de vloer van de vijand, binnen 32 px: geen aanloop; P1 op de vloer binnen 32 px: aanloop; P1 springt tijdens de aanloop: de aanloop loopt door; een vijand die op het respawnpunt al in zijn aanloop zit, raakt P1 niet in de eerste 45 ticks na de respawn |
| **B-14** | **G-2: de boss in co-op in de Kadewijk-arena, met P2 in elke fase** (v0.1.6, [#289](https://github.com/cesarvangerwen-glitch/echoborn/issues/289); testplan T11 §6 G-2, §4 rij Boss). **Spel** (`gemaalmeester.gd`): (1) GMB-14: in co-op valt de pompslag van fase 1 om en om links en rechts (de eerste op de helft van P1); `doelhelft()` springt om op de eerste tick na het actieve vlak; een treffer op schot of kern zet alleen een merk als het middelpunt van de slaande speler op de doelhelft staat (anders op het schot de "tink" van VJ-07, op de kern 10 SE); knallen alleen vanaf de andere helft dan waar het merk gezet is (anders op het schot de tink, op de kern 10 SE, en het merk blijft); de kant van de pompslag wordt per maat gekozen op het begin van de aanloop (drop-in/out, GMB-14 f); bij een drop-out gaat de doelhelft op die tick uit en geldt de solo-regel voor zetten en knallen meteen (GMB-14 b, f, v0.1.7); solo ongewijzigd. (2) Vlag `doelhelft` voor beeld en audio (B-11, §9) en meetlog-event `DOELHELFT` (links/rechts) bij elke wissel, en `DOELHELFT` = geen bij een drop-out (B-10). **Bot** (`boss_bot.gd`, co-op): (3) fase 1: P2 loopt elke maat naar de doelhelft (± 36 px van het midden, kijkt naar de ketel) en zet daar het merk (op schot of kern). P1 wisselt naar de veilige helft en ontsteekt het merk. Kan P1 niet op tijd wisselen, dan springt hij over de pompslag zoals nu. Geen sprongen of stappen zonder taak (geen `_fidget`). (4) fase 2: GMB-15 (b). Ligt de vroegste afzet van P1 op P2 bij aankomst meer dan 60 ticks verder, dan wisselen de rollen voor één bounce: P1 gaat onder het midden van het rad op de vloer staan, P2 springt op hem, bouncet en slaat 2×. (5) Wankel: zoals nu (GMB-16). **Arena** (`kadewijk.gd`, S8): (6) de co-op-boss in de echte arena: binnenkomst van beide spelers (startregel GM-01), vaste arena-camera met twee spelers, de deur links open na `BOSS_VERSLAGEN`, en de lus van `kadewijk_duo.gd` loopt door naar S9 | **Tests** (`test_boss.gd` of `test_boss_rad.gd` voor de regel, `test_boss_runs.gd` en `test_kadewijk_coop.gd` voor de runs). **Regel**: (a) co-op: de pompslag valt L, R, L, R…, beginnend op de helft van P1, en `DOELHELFT` staat op tick 46 van elke maat in het log. (b) Co-op: een treffer van P2 vanaf de andere helft op het intacte schot zet geen merk (0 SE, tink); vanaf de doelhelft wel. Daarna breekt een treffer van P1 vanaf **de andere helft** het schot. Vanaf dezelfde helft als het merk geeft hij de tink, het merk blijft en het schot blijft heel. **Run** "P2 blijft als ontsteker op één plek" (`p2_fixed`: P2 zet geen merken en ontsteekt alleen van zijn plek, D = 60), met twee checks (v0.1.7, [#302](https://github.com/cesarvangerwen-glitch/echoborn/issues/302)). (b1) **Elke** `SCHOT_BREUK` komt van een merk dat gezet werd terwijl de doelhelft op de andere helft stond dan P2, en hetzelfde geldt voor elke merk-ontploffing van 20 SE op de kern. De check kijkt naar de doelhelft op de tick waarop het merk gezet werd, niet op de tick van de breuk: het merk leeft 150 ticks en het venster is 120, dus een goede breuk kan in het volgende venster vallen (Lead-review PR #303). (b2) Fase 1 duurt **≥ 1,25 ×** zo lang als in de gewone co-op-run (gemeten 1410 tegen 943 ticks, 1,50). Zonder de wissel is dat ± 1,0, en met P2 op één plek kan hooguit elke tweede maat een breuk geven (± 1,5); 1,25 ligt ertussen. Was: schotbreuken per maat ≤ ½. Dat kan niet gehaald worden, want fase 1 heeft in beide runs 7 vaste openingen (gemeten 0,58 tegen 0,88, 0,67). De breuken per maat blijven een note. (c) Solo: de B-9-runs geven **dezelfde ticks** als v0.1.5 (testarena D = 60: 5875; Kadewijk 97,5 s), want de regel geldt niet. (d) Drop-out van P2 in fase 1: vanaf de volgende aanloop volgt de pompslag P1, en vanaf de tick van de drop-out kan het merk van beide kanten (GMB-14 f); de bestaande run `test_b9_drop_out_phase1` blijft groen. Drop-out midden in een maat (vóór tick 46, v0.1.7): op die tick `DOELHELFT` = geen en `doelhelft()` = geen, op tick 46 geen omslag, de pompslag in de aanloop houdt zijn kant, en een merk van P1 knalt door de echo vanaf dezelfde helft. Drop-out ná tick 46 (de doelhelft is al omgesprongen): op die tick `DOELHELFT` = geen en `doelhelft()` = geen, de volgende pompslag valt op de helft van P1 (niet op de doelhelft van tick 46), en een merk van P1 knalt door de echo vanaf dezelfde helft. Drop-in: geen doelhelft tot de volgende aanloop, dan de wissel. **MP-7 (b) voor P2 in de boss** (de test die #287 nog niet had): (e) `test_b9_coop_d60/90/120`: **check `mp1_p2` ≤ 300**; bij D = 180 een note. De note geeft de langste stilstand van P2 en P1 per deel (fase 1, fasewissel, fase 2, Wankel + finisher; uit `STIL_EIND` met bron `p2`/`p1` en de `BOSS_FASE`-ticks), naast de verwachting van §3.10 (± 90 / ≤ 60 / ± 150, bovengrens 180 / ± 100; v0.1.7). Na de merge van PR #293 meldt de note ook het wachten (MP-7 (e)) per fase voor P1 en P2. (f) Ontwerpcheck bij D = 60: in fase 1 zet P2 merken vanaf **beide** helften (≥ 2 per helft), en P2 heeft in fase 1 **0 JUMP-flanken**: zijn beweging komt van de wissel, niet van een sprongetje. (g) `test_kadewijk_coop.gd`: S8 los en de lus bij D = 60 checken MP-7 (b) van P2 **ook in de boss** (≤ 300; de uitzondering uit #287 vervalt), bij 90/120/180 in de lus. (h) C-16: `test_b9_c16_coop_p2_never_hits` blijft: in 6000 ticks geen schotbreuk en geen finisher. (i) MP-7 (a) blijft 0,5 … 1,0 bij 60/90/120 en co-op bij D = 60 75–150 s (B-9b); haalt het dat niet, dan zet de Combat Designer `coop_schaal` (§3.10, *Duur*), niet de GP |

**Volgorde:** B-1 → B-2/B-3/B-4 (parallel aan T8a) → B-5 → B-6 → B-7 → B-8 → B-9/B-10, B-11 doorlopend. **Raming:** **4–5 maak-taken** Gameplay Programmer (B-1–B-4: 1–2; B-5–B-7: 1–2; B-8–B-11: 1–2), plus **1 maak-taak Combat Designer** om de waarden te zetten met de B-9-tabel (een nieuwe versie van dit document en `slice.csv`). Binnen de 3–5 van T8b; de Animator-taak komt erbij (§9). **v0.1.3:** B-9b en B-13 zijn **1–2 maak-taken** Gameplay Programmer; ze mogen gesplitst worden, **B-13 eerst** (waarden en de vaste co-op-plek), dan B-9b (bot: planner met het keervenster, sprong over de pompslag, 5 LP); daarna zet de Combat Designer de waarden zo nodig nog één keer bij met de nieuwe B-9-tabel. **v0.1.6:** B-14 (G-2) is **1–2 maak-taken** Gameplay Programmer. Eerst de regel en de bot in de testarena (B-14 (1)–(5), tests (a)–(f), (h), (i)), daarna de Kadewijk-arena (B-14 (6), test (g)). Daarna zet de Combat Designer `coop_schaal` zo nodig bij met de nieuwe tabel. Dit is een voorwaarde voor MT3 (testplan T11 §4).

---

## 7. Wat van D afhangt

D = 60 is de werkaanname; het debugmenu kan 60 / 90 / 120 / 180 zetten (bereik 1–3 s). Elke regel hieronder is per D getest in B-1, B-7, B-8 en B-9.

| Maat | Formule | D = 60 | 90 | 120 | 180 |
|---|---|---|---|---|---|
| Echo knalt na je slag | `D + 3` | 63 | 93 | 123 | 183 |
| Merk leeft (solo) | `D + 30` | 90 | 120 | 150 | 210 |
| Merk leeft (co-op, C-12e) | 150 | 150 | 150 | 150 | 150 |
| Doelstreep vóór de knal (E-02t; kan omdat D ≥ 30) | 30 | 30 | 30 | 30 | 30 |
| Snelheid Kadeloper/Schotdrager (px/tick) | `min(0,5; 44/(D − 27))`, grens **≤ 0,70** (gdd v0.8 §4.8.5, D_max = 90) | 0,50 | 0,50 | 0,47 | 0,29 |
| Snelheid Dwaallicht | `min(0,25; 44/(D − 27))` | 0,25 | 0,25 | 0,25 | 0,25 |
| Keren: ontmoeting na het keren | `D/2` ticks, op `D` px | 30 / 60 px | 45 / 90 | 60 / 120 | 90 / 180 |
| Keren: afzet na het keren (zonder sturen in de lucht) | `(2D − 130)/4` | −2,5 (spring op het keerpunt) | 12 | 27 | 57 |
| Vlakke vloer vóór de muur (L-13 b) | `D + 24` | 84 | 114 | 144 | 204 (lichaam op 252: ok) |
| Middelpunt rad van de muur | `D + 34` | 94 | 124 | 154 | 214 |
| Hurtbox rad van de muur | `D − 14 … D + 82` | 46–142 | 76–172 | 106–202 | 166–262 (10 px over het lichaam, mag: GM-07) |
| Middelpunt rad in **co-op** (v0.1.3) | 94, vast (`rad_coop_muur`) | 94 | 94 | 94 | 94 |
| Keren: afzet en landing op de echo (§3.5) | `J = T + max(0; (2D − 130)/4)`, `L = J + 33` | T / T + 33 | T + 12 / T + 45 | T + 27 / T + 60 | T + 57 / T + 90 |
| Keervenster solo, `T` ten opzichte van het begin van de maat van de pompslag (§3.5; één per 180 ticks) | zwiep buiten `J + 1 … L + 6` en `L + 42 … L + 52`; pompslag te ontwijken (B-9b) | −53 … +24 (78 ticks) | −65 … +11 (77) | −56 … −4 (53) | +70 … +98 (29) |
| Keer tot keer, loper zonder dash / met het venster | `(L − T) + 30 + 23 + (558 − D)/2` / ± 360 | 335 / 360 | 333 / 360 | 333 / 360 | 335 / 360 |
| Solo-lancering: wachten / venster | `D − 21` / 19 | 39 / 19 | 69 / 19 | 99 / 19 | 159 / 19 |
| Langste verwachte stilstand (MP-1) | max(lancering, `D + 3` in Wankel) | ≤ 63 | ≤ 93 | ≤ 123 | ≤ 183 |

**Niet van D afhankelijk:** de maat (120 / 90 ticks), de aanlopen (pompslag fase 1: 40), de hoogtegrenzen van de aanloop (VJ-08, `slice.csv`: `aanloop_hoogte_min` = −20 px, `aanloop_hoogte_max` = +20 px), de hoogte van haakslag en schotstoot (4–20 px), onkwetsbaar na een treffer en na een respawn (VJ-02: 45 / 45 ticks), de kern-opening (300), het rad per kant (`kant_ticks` 480, v0.1.3; was 180), de plek van het rad in co-op (94 px), de drempels, de schade (rad 18 SE, co-op 12), de finisher (600 → 120 ticks).

**Let op bij D = 180 (regressie):** het keervenster is maar 29 ticks breed (≥ 10, dus binnen P1), want de opstap naar de echo duurt dan 33 ticks en de echo-vloer ligt 90 ticks vóór de landing. Dat is te halen voor de bot, maar krap voor een mens; D = 180 valt buiten de werkaanname (D = 60) en we bouwen er niet op.

**Let op bij D = 60:** na het keren is de echo maar 120 px achter je, dus je springt **op het keerpunt** of vlak ervoor en stuurt in de lucht bij (in de lucht bepaal je `v.x` zelf, dus de ontmoeting is ruim te halen); het plank-signaal (E-07d, ≤ 130 px) staat dan al aan op het moment dat je keert. De late bot van B-8 toetst dit.

---

## 8. Afwijkingen en open punten (voor de Lead Game Designer)

Geen CEO-vraag nodig: alles ligt binnen de besluiten (#2, #51, D = 60) en is balans of detail, dus aan de LGD (rolbestand: escalatie bij balansconflicten).

| # | Punt | Voorstel | Wie |
|---|---|---|---|
| 1 | **Duur van de boss** | **Besluit LGD:** scripted 90–150 s; verlengd met een 4e opening (GMB-11) en meer kanten (2 treffers per kant, 600 SE in fase 2), alles in data. GM-acceptatie en WS-05 krijgen dezelfde waarde | LGD (#187) |
| 2 | **SE en drempels** (GM-03) | **Besluit LGD:** akkoord met SE plus drempels; door punt 1 nu **1500 SE** in plaats van 600 (zelfde verhoudingen) | LGD (#187: GM-03 op 1500) |
| 3 | **Rad-treffer 15 SE** (GM-07) | **Besluit LGD:** akkoord. Per kant nu 2 treffers in plaats van 3 (punt 1). **v0.1.3 (#213): 18 SE** (ook in co-op): met 2 slagen per bounce raakt de echo het rad niet meer, dus een kant is 2 × 15 = 30 SE in plaats van ± 40, en fase 2 werd ± 20 kanten; met 18 is het weer ± 17 kanten (§3.9). Ter review | LGD |
| 4 | **Schoepenzwiep op y 36–60**; op je echo staan is geen ontwijking (GM-05b) | **Besluit LGD:** akkoord | LGD (#187) |
| 5 | **Paren** | **Besluit LGD:** L-13 (d) blijft; elke golf een E-paar (≤ 32 px), K-paren (40–44 px) erbij als extra; afstandsregel per paar met startafstand in data (VJ-05, §2.6) | — |
| 6 | **Kadeloper 0,5 px/tick bij D = 60** | **Besluit LGD:** akkoord, binnen de grens van 0,70 px/tick (gdd v0.8 §4.8.5) | — |
| 7 | **45 ticks onkwetsbaar** na een treffer op P1 (VJ-02) | **Besluit LGD:** komt in de gdd bij LM-05 | LGD (#187) |
| 8 | **O-17 en O-18** | **Besluit LGD:** O-18 voor de slice gesloten (VJ-06); O-17 gaat terug naar fase 3 (§4) | LGD |
| 9 | **Co-op te snel** (MP-7): B-9 (PR #209) mat 0,57 / 0,51 / 0,45 / 0,32 bij D = 60 / 90 / 120 / 180 | **v0.1.3 (#213):** het rad in co-op op een vaste plek (94 px, GMB-04). Met `coop_schaal` 1,5 mat PR #219 co-op 133,9 s bij elke D, langer dan solo (MP-7 1,02–1,10); daarom **1,0**: verwacht ± 95 s, MP-7 ± 0,77 (§3.8, §3.9). B-13 meet het | LGD; T11 |
| 13 | **2 slagen per bounce** (vraag GP, PR #209) | **v0.1.3:** toegestaan, geen treffer-cooldown op het rad. Het venster boven 100 px is 28 ticks en AANVAL herhaalt na 20, dus twee slagen vragen timing (de eerste in 8 ticks): dat is vaardigheid, en één keer-run wordt één kant. Wie één keer raakt, doet een tweede bounce aan dezelfde kant (`kant_ticks` 480 laat dat meestal toe) | LGD (ter kennisname) |
| 14 | **Keren op de maat** (§3.5) en het rad **480 ticks** per kant: elke aanval in fase 2 is te ontwijken zonder dat de keer-run breekt, zodat "solo verslaan zonder dood met 5 LP" toetsbaar wordt (B-9b). Gevolg: een kant is ± 4 maten; gemeten (PR #219) wacht je per kant 187 / 143 / 100 / 13 ticks lopend bij D = 60 / 90 / 120 / 180, in een strook van ≥ 48 px (geen stilstand). **Voor de slice geaccepteerd** (§3.9); stoort het in T11, dan de zwiep alleen op de helft zonder rad (de eerste versie na T11; T11 is nog niet gedaan, v0.1.4 laat dit punt staan) | Ter review; de mijlpaal-test (T11) kijkt of het keervenster leesbaar is ("na de veeg keren") en of de wachttijd stoort (MP-5) | LGD; QA Lead (T11) |
| 10 | **Vierde vijandtype** (OW-4): niet in de slice (§2.5) | **Besluit LGD:** de plek blijft leeg; OW-4 blijft open tot de mijlpaal-test | LGD, World & Level Designer |
| 11 | **Verdeling over de kamers** (§2.6) is een voorstel binnen `wereld.md` §2.2 | **Overgenomen** in `kadewijk.md` §4 (v0.4.4), met afwijking 2 (golf 2 wacht op ≤ 5) en 19 (S9: Dwaallicht + E-paar op 1060), beide akkoord LGD; §2.6 volgt die stand (v0.1.4) | — |
| 15 | **Lege loop na golf 2 in S3**: 540 ticks (9,0 s bij D = 60) tussen de laatste ontploffing in S3 en de lancering in S4 (`kadewijk.md` §6b), binnen MP-2 en L-11 | **Besluit LGD** (Lead-review #223): geen ombouw nu; **punt voor de Combat Designer na MT2**. Kandidaat dan: de Kadeloper van S4 naar het begin van de aanloop (in plaats van aan de overkant), of samen met de WLD de aanloop van S4 korter (± 55 ticks) | Combat Designer (na MT2) |
| 12 | **Hoogtegrenzen van de aanloop** (VJ-08, −20 … +20 px), detail bij gdd §4.3, en **45 ticks onkwetsbaar na een respawn** (VJ-02), naast punt 7 | Ter kennisname; de LGD neemt ze mee bij LM-05 en §4.3 | LGD |
| 16 | **P2 in de boss** (#289, §3.10): in co-op valt de pompslag van fase 1 om en om links en rechts, en het merk op schot en kern zet je alleen vanaf de **doelhelft** (GMB-14). In fase 2 wisselen drager en springer als P1 meer dan 60 ticks moet wachten (GMB-15). Aanleiding: in de co-op-run stond P2 925 ticks stil (MP-7 (b) niet gehaald, PR #287). Afwijking van een LGD-document: GM-05a zegt alleen "de linker- of rechterhelft", dus de wissel past erin. GM-06 en C-12 a zeggen dat het schot `Merkbaar` is zonder plaatsvoorwaarde, en daar is de doelhelft een **aanvulling in co-op**, zoals het rad op een vaste plek in co-op (GMB-04). Solo verandert niets. | **Besluit LGD** (Lead-review PR #295): akkoord, met de regel dat je knalt vanaf de andere helft dan waar het merk gezet is (GMB-14 c). Solo verandert niets. Na de merge van PR #293 meldt B-14 (e) het wachten MP-7 (e) per fase | LGD |
| 17 | **Na de meting van B-14 deel 1** ([#302](https://github.com/cesarvangerwen-glitch/echoborn/issues/302), §3.10, §6). (a) De note-run "P2 op één plek" krijgt twee checks in plaats van ≤ ½ breuken per maat: elke breuk komt van een merk dat gezet werd met de doelhelft tegenover P2 (de doelhelft op de tick van het zetten), en fase 1 ≥ 1,25 × zo lang (B-14 b). (b) Fase 2: GMB-15 (b) blijft bij de afzet. De verwachte stilstand van P2 wordt ± 150 met bovengrens 180 (was ≤ 120); de landing meenemen kost MP-7 (a) ± 1,27. (c) Drop-out midden in een maat: de doelhelft (gloed) gaat meteen uit en zetten en knallen kan meteen van beide kanten (GMB-14 b, f). Geen afwijking van een LGD-document; GM-05a en GM-06 blijven gelden. | **Besluit LGD** (Lead-review PR #303): akkoord op (a)–(c), met (a) zoals hier: de check kijkt naar de doelhelft op de tick van het zetten van het merk. Geen waarde in `slice.csv` verandert. De GP verwerkt (a) en (c) in de tests en de regel van B-14, (b) alleen in de note van B-14 (e) | LGD |
| 18 | **Open: is P2 als plank in fase 2 aan het wachten?** De 148 ticks in fase 2 zijn stilstand volgens MP-1. Of P2 als plank een taak heeft (MP-7 (e)), blijkt pas uit de wachtmaat in de note van B-14 (e) na PR #293. | Wacht P2 daar langer dan 120 ticks, dan gaat GMB-15 (b) opnieuw open | LGD, CbD |

**Playtestvragen:** GM-a–GM-d uit `gemaalmeester.md` §8 blijven; meetbaar met B-10. Extra voor de mijlpaal-test (QA Lead): *ketting* (VJ-05): zag de speler in S6 een merk naar een tweede vijand overspringen? (kaartvraag naast M2).

---

## 9. Wat Animator, UI/UX en Audio nodig hebben

**Regels voor elke tell:** leesbaar in silhouet op 640 × 360 en in de grijze beginstaat (niet alleen kleur); de aanloop toont **waar** het vlak komt (helft, hoogte), niet alleen **dat** er iets komt; elk actief vlak valt samen met het frame waarin de beweging het verst is.

### 9.1 Animator (met de Gameplay Programmer; tijden in ticks = frames bij 60 fps)

| Wie | Animaties en tijden |
|---|---|
| Kadeloper | lopen (cyclus), haakslag: aanloop 30 / actief 6 / herstel 20, stil na treffer 30 (knik), dood (lost op in donker water), uit de stoom stappen 30 (adds) |
| Schotdrager | als de Kadeloper + schotstoot 30/6/20; "tink" op het schot (4); schot breekt en valt (12) |
| Dwaallicht | zweven (cyclus), aanloop 30 (licht zwelt), duik 8, terug 40, stil na treffer 30 (flakkert), dood |
| Gemaalmeester | aarzeling bij de sjaal 60; pompslag: stang heft naar links/rechts 40 (fase 1) of 30 (fase 2), slag 6, ligt 24; schoepenzwiep: schoepen draaien op 30, veeg 8, uitdraaien 20; spuigaten gloeien 30; schot dicht (20), schot breekt (12, met scheur en stoom), kern open (puls, cyclus); fasewissel 60 (stoom, rad hijst); rad trilt 20, draait 60; Wankel (hapert, cyclus), merkplek gaat open (20); oplossen in licht (GM-10) |
| Gedeelde echo | finisher 120 (half licht, half schaduw; C-14) |

### 9.2 UI en UX (T10)

- Doelstreep, bereikcirkel, rand en kettinglijn (E-02t, E-14j) ook op de boss; het **vloerteken** onder het rad (GMB-04).
- Levenspunten van P1 (5 + lampglas) en de 45 ticks onkwetsbaar (knipperen).
- **Doelhelft** (co-op, fase 1, GMB-14): de helft van het schot aan de doelhelft gloeit vanaf tick 46 van de maat, zodat je ziet waar je merkt en waar de volgende slag valt. De gloed is leesbaar in silhouet (een rand of een spleet die opengaat, niet alleen kleur). Bij een drop-out dooft hij meteen, en bij een drop-in gaat hij pas aan op het begin van de volgende aanloop (v0.1.7). Wie het merk vanaf de verkeerde kant zet of knalt, krijgt de "tink".
- **Voortgang van de boss zonder balk** (voorstel; de UX Designer beslist): de ketel dooft een stap per opening, het rad krijgt scheuren per kant, zodat je de beat ziet; geen getal in beeld.

### 9.3 Audio (T8d)

| Moment | Geluid |
|---|---|
| Maat | carillon-tel op het begin van elke maat (120 / 90 ticks): het ritme dat je leert (GM-04) |
| Pompslag | sissende zuiger die stijgt gedurende de aanloop, dreun op de slag. **Aanloop fase 1 blijft 40** (vraag PR #193): 30 is de fase-2-aanloop (het verschil is de escalatie) en 60 maakt fase 1 trager; leg de dreun als accent tussen de tellen |
| Schoepenzwiep | aanzwellend water-gesuis, veeg |
| Spuigaten | borrelen, 30 ticks |
| Schot | "tink" bij 0 SE; breuk: krak + stoom (+ schermschok); dichtschuiven |
| Kern / rad | treffer op de kern (dof, warm); op het rad (metalen klank); rad ratelt 20 ticks vóór het draait |
| Merk | carillon-voorslag van de doelstreep (E-02t), aftelling (E-14b), knal en kettingschakel (oplopende toon per schakel) |
| Wankel en finisher | carillon valt stil; finisher: jullie slagen als versnelde tellen, slot in licht |
| Vijanden | Kadeloper: schrapen bij de aanloop; Schotdrager: roestig schot; Dwaallicht: zoemen dat stijgt bij de aanloop |

---

## 10. Checklist T8b (review LGD)

- [ ] Max. 4 vijandtypes: **3** (Kadeloper, Schotdrager, Dwaallicht), de boss niet meegeteld (R-V4).
- [ ] Twee verplichte momenten met een samenwerkingsactie (schot, rad) en de finisher, elk solo én co-op in dezelfde arena (C-16).
- [ ] Elk venster ≥ 10 ticks (kleinste: 17), elke aanval ≥ 30 ticks aanloop met tell in beeld en geluid.
- [ ] Verwachte MP-1 ≤ 63 ticks bij D = 60 (≤ 183 bij D = 180); scripted run meet het (B-9).
- [ ] Scripted run 90–150 s per modus bij D = 60 (§3.9), met ontwijken en 5 LP, zonder dood (B-9b).
- [ ] MP-7 (co-op ≥ ½ × solo) bij elke D (§3.8; gemeten 1,02–1,10 met `coop_schaal` 1,5, verwacht ± 0,77 met 1,0) en co-op niet trager dan solo.
- [ ] Elke golf heeft een E-paar (L-13 d); vijand-`v` ≤ 0,70 px/tick.
- [ ] Het rad niet te raken zonder bounce, lancering of vang, per D (B-8).
- [ ] Geen contactschade; de echo en P2 krijgen nooit iets.
- [ ] P2 heeft in elke fase een taak die beweging vraagt (§3.10); verwachte langste stilstand van P2 ≤ ± 150 ticks bij D = 60 (fase 2 ≤ 180) (MP-7 (b) ≤ 300); C-16 blijft (B-14 (h)).
- [ ] Werkaanname genoemd (§0); maten in D (§7).

## 11. Wijzigingen

| Versie | Wat |
|---|---|
| 0.1.7 | **Na de meting van B-14 deel 1** ([#302](https://github.com/cesarvangerwen-glitch/echoborn/issues/302), reviews van PR #301 en PR #300). Werkaanname D = 60. (1) B-14 (b): de note-run "P2 blijft als ontsteker op één plek" krijgt twee checks: elke breuk komt van een merk dat gezet werd met de doelhelft tegenover P2 (Lead-review PR #303: de doelhelft op de tick van het zetten, want het merk leeft 150 ticks en het venster is 120), en fase 1 duurt ≥ 1,25 × zo lang (gemeten 1,50); ≤ ½ breuken per maat vervalt (niet te halen bij 7 vaste openingen). (2) GMB-15 (b): de rolwissel blijft bij de afzet (de landing meenemen gaf 124,7 s, MP-7 (a) ± 1,27); §3.10 fase 2 verwacht ± 150, bovengrens 180 (was ≤ 120); hele boss ≤ ± 150; §1, §10 en B-14 (e) mee. (3) GMB-14 (b), (f): bij een drop-out gaat de doelhelft meteen uit (`DOELHELFT` = geen) en geldt de solo-regel voor zetten en knallen meteen; de pompslag in de aanloop houdt zijn kant; B-10, B-14 (1), (2), (d), §9.2. (4) §8 punt 16: de open regel over de overname in `gemaalmeester.md` is weg (v0.2.4); §8 punt 17 nieuw (besluit LGD) en punt 18 (open). B-14 (d) en GMB-15 (c) kloppen met de nieuwe regels. `slice.csv` ongewijzigd. |
| 0.1.6 | **Wat P2 doet in de boss** ([#289](https://github.com/cesarvangerwen-glitch/echoborn/issues/289), G-2; MP-7 (b) niet gehaald in PR #287: P2 stond 925 ticks stil in fase 1). Nieuw §3.10 met **GMB-14** (fase 1 co-op: *de wissel*, de pompslag om en om, merken vanaf de doelhelft), **GMB-15** (fase 2: drager, springer als P1 wacht) en **GMB-16** (Wankel: ontsteker), plus de stilstand van P2 per fase, gemeten en verwacht bij D = 60. C-16 blijft gelden, en de duur en `coop_schaal` zijn de knop. Bouwopdracht **B-14** (G-2, met de test van MP-7 (b) voor P2 in de boss), `DOELHELFT` in B-10, §3.4, §3.7 en §3.8 bijgewerkt, §8 punt 16 en §9 (gloed op de doelhelft). Werkaanname D = 60; de maat is de huidige MP-7 (b)/MP-1, de wachtmaat van #290 volgt. **0.1.6.1** (Lead-review PR #295, klein): in GMB-14 (c) en (e), B-14 (1) en (b) knal je alleen vanaf de andere helft dan waar het merk gezet is, met de note-run "P2 blijft als ontsteker op één plek". C-16 (c): zonder aparte versie. MP-7 (e) uit PR #293 per fase in de note van B-14 (e). §8 punt 16: besluit LGD. |
| 0.1.5 | GP met de data van de CbD, [#247](https://github.com/cesarvangerwen-glitch/echoborn/issues/247) (besluiten LGD na de visie-review van S8): fase 2 korter. `rad_treffer` 18 → **33**, fase 2 ± 10 kanten (≤ 65 s); **7 openingen** van 100 SE (fase 1 ≥ 24 s); **1750 SE**, Wankel 350 (verhoudingen GM-03); `coop_schaal` 1,0 → **1,32** (25 SE in co-op, MP-7 ≤ 1). GMB-10, GMB-11, GMB-13, §3.5, §3.8 bijgewerkt; meting v0.1.5 in §3.9; de vaste arena-camera (§3.8). De oudere getallen in §3.9 en §8 zijn van v0.1.3. |
| 0.1.4 | Naar de stand op `main` (#245): §2.6 rij S9 = **1 Dwaallicht (verlicht, x 2310, baan 32 px) + één E-paar (x 1060, 28 px)**, afwijking 19 van de WLD (akkoord LGD in PR #239; CD #227/#240); de andere rijen gecontroleerd tegen `kadewijk.md` v0.4.4 §4 en de scènes: x-waarden erbij, S3 golf 2 wacht ook op ≤ 5 tegelijk (afwijking 2), rij S5 "geen" (besluit 3 LGD); §8 punt 11 overgenomen, punt 14 blijft open tot T11, nieuw punt 15: de lege loop van ± 9 s na S3 golf 2, na MT2 (besluit LGD). Bronregel: `kadewijk.md` v0.4.4, `gemaalmeester.md` v0.2.2, `gdd.md` v0.8.4 (Lead-review #246). |
| 0.1.3 | Waarden na de scripted runs van PR #209 (#213): **2 slagen per bounce** toegestaan (§3.5, §8 punt 13); `kant_ticks` 180 → **480**, `kant_treffers` blijft **2**, `rad_treffer` 15 → **18** (§3.5, §8 punt 3); `coop_schaal` blijft **1,0** (na de meting van PR #219: met 1,5 was co-op trager dan solo) en het rad in co-op op een **vaste plek** (94 px, GMB-04, §3.8, §8 punt 9); **keren op de maat** als regel om fase 2 te ontwijken (§3.5, §3.7, §7) en bouwregel **B-9b** (ontwijken, 5 LP) en **B-13** (waarden) voor de GP (§6); §3.9 opnieuw gerekend en de meting van B-9b (PR #219) als bevinding: solo 122–132 s, 0 treffers in fase 2; besluiten: co-op niet trager dan solo (± 95 s verwacht), lopend wachten (strook ≥ 48 px) voor de slice geaccepteerd; B-13 vóór B-9b. |
| 0.1.2 | Antwoorden #190 (vragen GP uit PR #201) en PR #193: hoogtegrenzen van de aanloop (VJ-08, −20 … +20 px, §2.2), hoogte schotstoot 4–20 px (§2.3); 45 ticks onkwetsbaar na een respawn, niet na een dodelijke treffer (VJ-02); bouwregel B-12 (§6); waarden in §7; §8 punt 12; pompslag-aanloop fase 1 blijft 40 (§9.3). |
| 0.1.1 | Lead-review PR #185 (klein): duur scripted 90–150 s via een 4e opening en meer kanten (1500 SE, 2 treffers per kant, §3.3, §3.5, §3.9); L-13 (d) blijft: E-paar per golf, K-paren als extra, afstandsregel per paar in data (VJ-05, §2.6), Schotdrager in een E-paar; grens `v` ≤ 0,70 (VJ-03, §7); merk in co-op 150 ticks (C-12e; §3.6, §3.7, §7); verwijzingen naar gdd v0.8 en gemaalmeester.md v0.2; O-17 terug naar fase 3; §8 met de besluiten van de LGD. |
| 0.1 | Eerste versie (T8b, #84): drie vijandtypes met gedeelde regels (VJ-01–VJ-07) en plaatsing, de Gemaalmeester in detail (GMB-01–GMB-13, fasen, aanvallen, vensters, finisher, co-op), D-tabel voor D = 60 … 180, bouwopdracht B-1–B-11, afwijkingen voor de LGD, wat Animator, UI/UX en Audio nodig hebben. |
