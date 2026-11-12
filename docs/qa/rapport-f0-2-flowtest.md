# Rapport F0-2: tweede flow-test op de herontworpen flow-kamer (T17-2)

Versie 0.1 · 2026-11-12 · Eigenaar: QA Lead (met Lead Game Designer) · Issue: [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80) · Lead-review: Executive Producer

Plan: `docs/qa/testplan-f0-2.md` (v0.1.3). Kaart: `docs/qa/ceo-kaart-f0-2.md`. Antwoorden van de CEO: [comment in #80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80#issuecomment-6822384564). Meetlogs: `docs/qa/f0-2-meetlogs/` (commit 16a3582). Besluit na de sessie: echo-staart **1 s (D = 60)**, bereik 1–3 s, zonder aparte check (`docs/beslissingen.md`, 2026-11-12). Build van de sessie: `8be9910`.

## 1. Samenvatting

- **Sessie korter dan gepland**: 2 oefenruns en **3 van de 6** getelde runs (D = 180, 90, 120: één run per D in plaats van twee). Eén run brak af (12:11). Volgens de keuzeregel (W12) doet daardoor **geen enkele D mee aan de keuze**. Die keuze heeft de CEO daarna zelf gemaakt: D = 60.
- **Norm (3), MP-5: bij geen enkele D ≥ 4,0, maar wel hoger dan in F0.** Run-gemiddelde D = 180: 2,3 (3/2/2) · D = 90: **3,3** (4/3/3) · D = 120: 2,3 (3/2/2). In F0 was dat 1,0–2,0. Per kamer over de drie runs: K1 3,3 (F0 2,0), K2 2,3 (1,3), K3 2,3 (1,0). Alleen D = 90 heeft geen kamer onder 3,0.
- **Norm (2), MP-2: alleen gehaald bij D = 120.** In de runs op D = 180 en D = 90 staat in K1 **geen enkele echo-actie**: 0 springplank-landingen, langste gat 48 en 46 s (norm ≤ 40 s). De CEO nam bij alle 5 keerpunten de langzame lijn zonder te wachten (§4.2). De echo werkt daar wel (de bot doet 9,9–10,7 per minuut in K1); de CEO gebruikte hem in die runs gewoon niet.
- **R-V12, MP-3: 0 %.** Alleen de run op D = 120 heeft springplank-landingen in K1 (4). Vóór alle vier stond de CEO 83–113 ticks stil, op **182–249 px van de keerwand**: onder de weg omhoog (restgat), niet bij de wand. Per keerpunt over de 15 getelde keerpunten: **A 0 · B 4 · C 0 · D 11**. Hij liep zijn echo dus nooit tegemoet (A).
- **Gehaald bij elke D**: MP-1 (250 / 76 / 113 ticks; F0: tot 366), MP-4 (2–4 % Leeg) en MP-6 (49–63 % van de LP met de echo, 5–6 pompslagen van de echo).
- **K3 werkt beter**: de langste stilstand in K3 is 34–53 ticks bij de laatste schoep (in F0 175–366 aan de waterkant). Bij de sluis geen stilstand (LM-04). De LGD verwachtte ≤ 30.
- **Opvallend 1: geen SPRINGPLANK in K1 bij D = 180 en D = 90.** Dat is de langzame lijn (de treden), zonder één stilstand. Een andere weg omhoog is uit het log niet uit te sluiten, maar ook niet waarschijnlijk (§4.3).
- **Opvallend 2: K3 → K2 → K3.** Bij D = 180 en D = 90 landde de CEO na de val door het gat op de **bovenste trede van de trap** (x 2000–2026) en sprong hij binnen 21–31 ticks terug naar K2. Daar kwamen de vijanden van golf 2 terug en vocht hij nog 220 en 954 ticks verder. Dit is het risico dat de WLD al noemde (`flowkamer.md` §12). Bij D = 90 leverde dat juist de LP op die hij nodig had: 74 → 110 (§5.3).
- ***Nine Sols***: M1 "nergens aan", dus niet genoemd: uitgesteld naar F4b(c). M2 "geen idee": niet begrepen. O2 "een gele cirkel" en S1/S2 "ja, hielp": de nieuwe tekens zijn gezien. M en O zijn **als meerkeuze** gevraagd en niet open, dus "spontaan" is zwakker dan de kaart bedoelde (§6).
- **D = 60 is niet gespeeld en in de suite niet gemeten.** Een eerste bot-indicatie van QA (§8.1): bij D = 60 komt de gescripte run in K1 **bij geen enkel keerpunt via de echo omhoog**. De bounce valt op 54 px van de wand, tegen de overhang (40–70 px). Het B3-blok (B = D − 60) is 0 px breed, en de bot komt daar niet voorbij. B4, K2 en K3 werken bij D = 60.
- **QA-advies**: geen go F0 op deze sessie. Geen `ceo-beslissing` nu: de CEO heeft de staart gekozen, en het nalopen van de maten op D = 60 valt binnen dat besluit. Eerst moeten de maten die van D afhangen op D = 60 worden nagelopen (keerzone, overhang, richels, B3, B4, LM-04, FK-2) en moeten de bots op D = 60 groen zijn (§8.3). Daarna meet de volgende mijlpaal-sessie F0 opnieuw, nu op D = 60. **T17 kan dicht** zodra dit rapport gemergd is en de open DoD-punten bij hun eigenaar liggen (§9).

## 2. Hoe uitgerekend

Rekenscript `docs/qa/f0-2-meetlogs/rekenen.gd` (nieuw; uitbreiding van het F0-script met testplan §4.1–§4.3), op `flow_report.gd`, Godot 4.6.3 headless op Linux:

```
godot --headless --path game -s "$PWD/docs/qa/f0-2-meetlogs/rekenen.gd" -- "$PWD/docs/qa/f0-2-meetlogs"
```

Per run komen daaruit `flow_report.gd` (MP-1–MP-4, MP-6) en uit dezelfde CSV-regels (geen nieuwe events, gdd §4.7.4): MP-1 met plek, MP-3 per landing, per bouwsteen en per keerpunt (A–D, W15), stilstand per kamer met plek (K2 per merk; K3 bij de schoepen, de sluis of de bovenste trede), de kamervolgorde en de LP vóór de eerste keer K3. Afstanden tot de keerwand gaan van het middelpunt van P1 tot het wandvlak. Tegen de wand staat P1 op ± 8 px.

**Toets van het rekenscript** (testplan §2, laatste regel). `docs/qa/f0-2-meetlogs/botlogs.gd` schrijft logs van de bots (§8.1). Op die logs geeft het script:

| Log | Verwacht | Uitkomst |
|---|---|---|
| Gescripte run D = 90 / 120 / 180 | 5 van 5 keerpunten A (`test_flowkamer_na_f0.gd`) | 5 van 5 A, landing 92 / 122 / 166–182 px van de wand (= `flowkamer.md` §9) ✅ |
| Run met echo uit (D = 120) | 5 × D | 5 × D ✅ |
| Wachtbot B1, op weg naar binnen, x = 160 (D = 120 en 60) | B, wachtplek 160 px, restgat | B op 160 px, band 120–240 ✅ |
| Wachtbot B1, x = 40 | trede (langzame lijn) | D met stilstand op 40 px ✅ |

Een kanttekening bij alle stilstanden hieronder: een stilstand telt pas als P1 30 ticks binnen 24 px bleef (definitie T16a, `meetlog.gd`). De waarde in het log is daardoor ± 20–30 ticks korter dan de werkelijke wachttijd. De wachtbot wacht D = 120 ticks, en het log zegt 100. Elke sprong of dash begint de telling opnieuw.

## 3. De sessie

### 3.1 Welke run is welke D

De D in de bestandsnaam klopt met de eerste `ECHO_LEEG_EIND` (tick D) in elk log, en met de D die de CEO opgaf. De volgorde 180 → 90 → 120 is de eerste helft van de kaart (W20).

| Bestand (tijd laptop) | D (log) | Scores K1/K2/K3 | Wat het is |
|---|---|---|---|
| 12:11:17 `_afgebroken` | 120 | — | afgebroken: 103,5 s, waarvan 84,5 s stil in de startgang (x 702), daarvoor 11,6 s stil bij de start. Oorzaak niet uit het log te halen (pauze of de bekende eerste-knop-kwestie, testplan open punt 3). Geen slot in de geometrie: de runs daarna komen er voorbij |
| 12:13:17 | 120 | 3/3/3 | oefenrun 1 (W7) |
| 12:15:35 | 120 | 3/3/3 | oefenrun 2 (W7) |
| 12:18:09 | **180** | **3/2/2** | getelde run 1 · V1 1–2 |
| 12:20:05 | **90** | **4/3/3** | getelde run 2 · V1 4–5 |
| 12:21:32 | **120** | **3/2/2** | getelde run 3 · V1 3 |

Run 4–6 (90, 180, 120) zijn niet gespeeld. **Duur**: de logs lopen van ± 12:09:30 tot ± 12:22 op de klok van de laptop, dus ± 13 min spelen voor zes logs, plus de vragen. Geraamd was ± 20–25 min voor de hele kaart. De scores staan 3–21 s na `RUN_EIND` in elk log: meteen gegeven, zoals de kaart vroeg.

### 3.2 Leercurve (oefenruns)

| | Oefen 1 | Oefen 2 | D 180 | D 90 | D 120 |
|---|---|---|---|---|---|
| Runtijd | 119,7 s | 107,6 s | 82,3 s | 90,6 s | 74,4 s |
| Echo-acties in K1 | 0 | 2 (op de bovenroute, niet bij een keerpunt) | 0 | 0 | 4 |
| Keerpunten via de echo (A + B) | 0 / 5 | 0 / 5 | 0 / 5 | 0 / 5 | 4 / 5 |

Pas in zijn vijfde run (D = 120) gebruikte de CEO de echo in K1 om omhoog te komen. De runtijd daalt van run tot run, behalve bij D = 90, waar hij nog eens 16 s in K2 doorbracht (§5.3). Met één run per D zijn **oefening en D niet te scheiden**: de laatste run is ook de enige met de echo in K1.

## 4. Objectieve normen per D

Eén getelde run per D, dus "per D" is hier steeds die ene run (W13).

| | D = 180 (3 s) | D = 90 (1,5 s) | D = 120 (2 s) | Norm | Bot D 180 / 90 / 120 (`flowkamer.md` §9) |
|---|---|---|---|---|---|
| Runtijd | 82,3 s | 90,6 s | 74,4 s | — | 70,3 / 63,5 / 65,5 s |
| Tijd in K1 | 44,2 s | 43,8 s | 43,2 s | — | 48,4 / 44,8 / 45,8 s (echo uit, D 120: 48,8 s) |
| **MP-1** langste stilstand (plek) | 250 (K2, bij het pantserdoel, x 1603) | 76 (K2, x 1787) | 113 (K1, B1, x 269) | ≤ 300 ✅ | 150 / 60 / 90 (B4) |
| **MP-2** echo-acties/min (K1 / K2) | 5,8 (**0** / 13,6) | 6,6 (**0** / 14,9) | 8,9 (5,6 / 16,8) | ≥ 3,0, ook per kamer | 11,9 / 14,2 / 12,8 |
| MP-2 langste gat | **48,2 s** | **46,2 s** | 15,1 s | ≤ 40 s | 14,4 / 13,6 / 13,9 s |
| MP-2 gehaald? | ❌ | ❌ | ✅ | | |
| **MP-3** landingen/min | 0 | 0 | 3,2 | rapporteren | 5,1 / 5,7 / 5,5 |
| MP-3 zonder stilstand | — (geen landing) | — (geen landing) | **0 %** (0 van 4) | ≥ 75 % ❌ | 83 % (alleen B4 met stilstand) |
| **MP-4** echo Leeg | 4 % | 2 % | 3 % | ≤ 40 % ✅ | 4 / 2 / 3 % |
| **MP-6** LP met de echo; pompslagen echo | 49 % van 106; 5 | 58 % van 110; 5 | 63 % van 102; 6 | ≥ 40 %; ≥ 1 ✅ | 66–69 %; 3–4 |
| LP vóór de eerste keer K3 | 94 | 74 | 102 | (gdd §4.2: ≥ 100) | 111 / 121 / 121 |
| Merksprongen (alle met ontploffing, schakel 1) | 8 | 10 | 8 | — | — |
| Echo breekt · lancering in B4 | 0 · nee | 0 · nee | 0 · nee | 0 (FK-4) | 0 · ja |
| **MP-5** K1 / K2 / K3 (gemiddeld) | 3 / 2 / 2 (2,3) | 4 / 3 / 3 (**3,3**) | 3 / 2 / 2 (2,3) | ≥ 4,0, geen kamer < 3,0 ❌ | — |
| V1 (band) | 1–2 | 4–5 | 3 | gdd §5: ≥ 4 (bevinding) | — |

De CEO lanceerde in B4 in geen enkele run, dus volgens W14 valt er niets weg voor MP-1 of MP-3. De stilstand in B4 is steeds de start van de run (43–55 ticks bij x 1420, voordat hij begint te lopen).

### 4.1 Wat opvalt

- **MP-2 faalt niet doordat de echo het niet kan.** In K2 halen alle drie de runs 13,6–16,8 echo-acties per minuut. In K1 gebruikte de CEO de echo in twee van de drie runs niet. Dat is gedrag, geen meetfout: de langzame lijn is er (FK-2) en is bij D = 180 maar 9–17 ticks trager dan keren (`flowkamer.md` §3). Bij D = 90 kost hij 62 ticks per keerpunt.
- **Zonder echo in K1 blijft de lichtmeter onder 100** (74 en 94 LP vóór K3; bot 111–121). Dan is het gemaal in één doorgang niet vol te krijgen. Bij D = 90 haalde de terugkeer naar K2 (§5.3) de ontbrekende LP.
- **De K1-score 4 bij D = 90 komt uit een run zonder één echo-actie in K1.** Die score zegt dus niets over hoe de echo in K1 voelt bij een korte staart. Hij kan gaan over het tempo (K1 duurt bij alle drie ± 44 s) of over de volgorde.

### 4.2 MP-3 per keerpunt (testplan §4.2)

| Keerpunt | Oefen 1 | Oefen 2 | D = 180 | D = 90 | D = 120 |
|---|---|---|---|---|---|
| B1 (wand x 20) | D | D | D | D | **B**: 113 ticks stil op 249 px (> 240; B1 gaat omhoog tot 300) |
| B2-0 (wand x 500) | D | D | D | D | D |
| B2-1 (wand x 20) | D | D | D | D | **B**: 107 op 194 px (restgat 120–240) |
| B2-2 (wand x 500) | D | D | D | D | **B**: 104 op 209 px (restgat) |
| B2-3 (wand x 20) | D | D (60 ticks stil bij de wand, 8 px, en daarna de treden) | D | D | **B**: 25 + 83 op 204 → 182 px (restgat) |

De richting is bij alle B's "onbekend" (W15): er staat geen eerdere stilstand of landing in de keerzone van hetzelfde niveau.

**MP-3 per keerpunt = 0 van 15** getelde keerpunten (0 / 5 per D). De LGD verwachtte ≥ 60 % (gdd §4.7.2). Wat dat zegt:

- **De grootste groep is D (langzame lijn, 11 van 15)**, niet B. De regel "B grootste groep = restgat, grond voor de CEO-vraag" (testplan §4.2) gaat dus niet af.
- **De regel voor de langzame lijn gaat wel af.** Bij elk keerpunt koos de CEO in meer dan de helft van de getelde runs C + D: B1, B2-1, B2-2 en B2-3 in 2 van de 3, B2-0 in 3 van de 3. Volgens `flowkamer.md` §12 (antwoord 1 van de LGD) zet de WLD daar de trede verder van de wand ([#81](https://github.com/cesarvangerwen-glitch/echoborn/issues/81)). Bij D = 60 moet de geometrie van de keerpunten toch opnieuw (§8), dus deze regel gaat daarin op.
- **Wachtafstand voor #81**: 182, 194, 209 en 249 px. Geen enkele in 80–119 px. Een bredere overhang (tot 120 px) of een keerzone van 160 px had geen van deze vier wachtmomenten weggenomen.
- **Hij wachtte ± D**: 83–113 ticks in het log, dus ± 105–140 ticks echt bij D = 120. Dat is het patroon van F0 (wachten tot de echo onder je staat), alleen nu niet tegen de wand maar onder de weg omhoog.
- **O1** ("wisselend, via de echo en zonder") klopt met het log: 4 van de 15 keerpunten via de echo, allemaal na wachten. Hij zegt niet uit zichzelf "omdraaien / mijn echo tegemoet", en het log laat dat ook nergens zien.

### 4.3 Waarom geen SPRINGPLANK in K1 bij D = 180 en D = 90

Gecontroleerd in de CSV's. In beide runs staat in K1 na de start **geen enkel event** tot `KAMER K2`: geen `SPRINGPLANK`, geen `BOUNCE`, geen `LP` en (behalve één in B4) geen stilstand. Dat geldt over 2.400–2.600 ticks. Hetzelfde zie je in oefenrun 1.

- **Wat het wel is**: de CEO bleef bewegen (een sprong of dash begint de stilstand-telling opnieuw, §2) en landde nooit op zijn echo. Hij kwam K2 binnen op x 1442, y 75: de bovenroute, de gewone uitgang van K1. Bij elk keerpunt is dat uitkomst D: de langzame lijn via de treden (op 45 en 90 px), de richel op 135 en zakken naar het volgende niveau.
- **Een andere weg omhoog?** Uit het log niet uit te sluiten. Zonder event staat er geen positie in het log (W15), dus de route tussen de start en de bovenroute is onbekend. Waarschijnlijk is het niet. De tijd in K1 (43,8 en 44,2 s) is korter dan bij de bot met echo uit (48,8 s), maar de bot dasht niet in de startgang en op de bovenroute (1.420 px lopen: ± 614 ticks bij de bot). Een mens die daar dasht, wint dat verschil (± 5 s) daar al terug. De keerzone, de overhang en het dichte stuk van 215 px zijn gemaakt om het overslaan van een verdieping te voorkomen, en de test controleert dat per D (`test_keerzone_geometry`, `test_ledge_above_ledge135_is_solid`).
- **Voor zekerheid**: een event per nieuw niveau of een grove positie-steekproef in het meetlog. Dat is een nieuw event (gdd §4.7.4 zegt: geen nieuwe events), dus een keuze van de LGD met de Gameplay Programmer (open punt 4).

## 5. Stilstand per kamer, met plek (testplan §4.3)

### 5.1 K1

| Bouwsteen | D = 180 | D = 90 | D = 120 | Verwachting LGD |
|---|---|---|---|---|
| B4 (start) | 43 | 55 | 43 | apart (W14); geen lancering |
| B1 | — | — | 113 | ≤ 60 bij keren |
| B2-0 · B2-1 · B2-2 · B2-3 | — | — | — · 107 · 104 · 83 | ≤ 60 |

Bij D = 180 en D = 90 is er na B4 geen stilstand in K1 (§4.3). Bij D = 120 staat er bij elk keerpunt met de echo ± D stilstand.

### 5.2 K2

| | D = 180 | D = 90 | D = 120 | Verwachting LGD |
|---|---|---|---|---|
| Merken · met merksprong | 16 · 8 | 20 · 10 | 14 · 8 | — |
| Langste stilstand tussen `MERK_GEZET` en de `MERKSPRONG` erna (merk) | **210** (merk 10, bij het pantserdoel) | 63 (merk 6) | 94 (merk 9, pantserdoel) | ≤ 60 |
| Langste stilstand in K2 (plek) | 250 (x 1603, pantserdoel op x 1579) | 76 (x 1787) | 113 (x 1596, pantserdoel) | ≤ 60 |

De langste wachttijd in K2 zit **bij het pantserdoel** (x 1579). Het pantser breekt alleen met een ontploffing (`flowkamer.md` §4), dus de CEO staat ernaast tot zijn echo het merk laat knallen. Bij D = 120 eindigt de stilstand van 113 ticks 19 ticks na de merksprong van merk 9. Bij D = 180 zijn het er 250, met vier merken op en rond het pantserdoel. Ook dat wachten is ± D, en het wordt korter bij een kortere staart (D = 90: 63–76). De verwachting van ≤ 60 komt bij geen D uit. D = 90 komt het dichtst bij.

### 5.3 K3: de pompgang, de trede en K3 → K2 → K3

| | D = 180 | D = 90 | D = 120 | Verwachting / regel |
|---|---|---|---|---|
| Stilstand ≥ 30 ticks, plek | 44 bij de laatste schoep (x 1752) | 34 bij de laatste schoep (x 1738) | 53 bij de laatste schoep (x 1750) | LGD ≤ 30 (net niet gehaald) |
| Stilstand bij de sluis (x 1440–1540) | 0 | 0 | 0 | LM-04 ≤ 30 ✅ |
| `GEMAAL_VOL` → `RUN_EIND` | 176 ticks | 169 | 177 | sluis open als P1 er is ✅ |
| **Landing op de bovenste trede** (regel 1 van de LGD) | ja: x 2009, y 370, ± 30 ticks staan, dan omhoog | ja: x 2008, ≤ 21 ticks, dan omhoog | nee (op de vloer, x 2040) | `flowkamer.md` §12 |
| Kamervolgorde | K1 → K2 → **K3 → K2 → K3** → K1 | K1 → K2 → **K3 → K2 → K3** → K1 | K1 → K2 → K3 → K1 | — |
| Tweede keer in K2 | 220 ticks, 2 merken, +6 LP | **954 ticks**, 6 merken, **+36 LP** | — | — |

**Verklaring van K3 → K2 → K3** (gecontroleerd):

1. Bij D = 180 en D = 90 valt de CEO door het gat van K2 zonder de knop naar rechts. Hij landt op de **bovenste trede** van de trap terug naar K2 (x 2000–2026, op 385; zijn middelpunt staat op y 370). Een middelpunt onder y = 360 telt als K3, dus het log schrijft `KAMER K3`.
2. Vanaf die trede kom je met één sprong recht omhoog terug in K2 (zo is de trap gebouwd). Dat deed hij binnen 21–31 ticks: `KAMER K2` op x 2008, y 356.
3. Wie na golf 2 opnieuw K2 binnenkomt, krijgt de basisvijanden die op zijn terug (`flowkamer.md` §4, *Terugkeer*). Die bevocht hij, bij D = 90 nog 16 s lang.
4. Daarna viel hij rechts door het gat (x 2042) op de vloer en pompte hij de schoepen.

De WLD noemde dit al als **bekend risico** in `flowkamer.md` §12 ("wie in het gat meteen loslaat of naar links drukt, landt op de bovenste trede"). Het kwam uit in 2 van de 3 getelde runs, en ook in oefenrun 2. Het is geen slot. Het kost wel tijd: bij D = 90 ± 16 s, en een deel van de K2-score kan daar vandaan komen. Bij D = 90 leverde het juist de LP op voor één doorgang door de pompgang (74 → 110). Met 74 LP was het gemaal pas na een tweede ronde vol geweest.

In de oefenruns ging het anders. Oefenrun 1: met 80 LP en een lege meter terug de trap op naar K2 voor licht, zoals FK-2 bedoelt (1.046 ticks in K2). Oefenrun 2: eerst zonder te pompen de trap op, de tweede keer op de bovenste trede geland (6 ticks stil). Bij **regel 2 van de LGD** (stilstand bij de sluis per D) is er geen enkele stilstand bij de sluis, ook niet bij D = 180. De vrees dat de sluis bij een dash over de kade nog dicht zou zijn, komt bij de CEO niet uit (169–177 ticks marge).

**Bij de laatste schoep wachten** (34–53 ticks) is de nieuwe, kleine restwachttijd van K3: P1 slaat de schoep op x 1740 en wacht tot de echo het gemaal vol pompt. Dat is veel minder dan in F0 (175–366 ticks), en K3 steeg van 1,0 naar 2,3.

## 6. Wat de CEO zei

| Vraag | Antwoord | Wat QA ermee doet |
|---|---|---|
| **MP-5** (norm 3) | 180: 3/2/2 · 90: 4/3/3 · 120: 3/2/2 · oefen: 3/3/3, 3/3/3 | Niet gehaald bij elke D. Wel duidelijk hoger dan F0 (gemiddeld 2,7 tegen 1,4) |
| V1 "wist je waar je echo zou zijn?" | 180: 1–2 · 90: 4–5 · 120: 3 (banden, meerkeuze) | Bevinding (testplan §6). Alleen D = 90 haalt in de bovenste band 4. Dezelfde volgorde als de scores |
| H Echo: hulp of last? | 4–5 (band) | Hulp. In F0 3,5 |
| M1 Waar deed het merk je aan denken? | "nergens aan" | *Nine Sols* niet genoemd: zwak signaal negatief. Check uitgesteld naar F4b(c) (kader §3 F0, W8). **Kanttekening**: als meerkeuze gevraagd, niet open (W18). Of *Nine Sols* een keuze was, staat niet in het antwoord |
| M2 Waarom knalde een merk (niet)? | "geen idee" | **Niet begrepen** (W19). De merksprong is nog steeds niet leesbaar, ook met de paren (K2) en de doelstreep. Bevinding voor de LGD en de Gameplay Programmer (E-02t, E-14j) en voor T10 |
| O1 Hoe kwam je in K1 een verdieping hoger? | "wisselend (via de echo en zonder)" | Klopt met het log (§4.2). Geen "omdraaien / echo tegemoet" |
| O2 Zag je iets dat liet zien waar je echo zou komen of welk merk zou knallen? | "ja, een gele cirkel" | De bereikcirkel (E-14j) is als enige uit zichzelf genoemd (binnen meerkeuze). Plank en streep niet |
| S1 Plank die oplicht als de echo komt (E-07d) | ja, en het hielp | Gezien, na het aanwijzen |
| S2 Streep of cirkel vóór een knal (E-02t, E-14j) | ja, en het hielp | Gezien, na het aanwijzen. Toch M2 "geen idee": de cirkel laat zien *dat* er iets knalt, niet *waarom* |

**Conclusie van de CEO**: "hoe korter de echo, hoe vloeiender en leuker". De scores en V1 wijzen die kant op: D = 90 is het hoogst op beide. Drie kanttekeningen:

- Het steunt op **één run per D**, in de volgorde 180 → 90 → 120.
- De hoogste K1-score viel in een run **zonder echo in K1** (§4.1).
- De enige run met de echo in K1 (D = 120) kwam als laatste en scoorde lager. Daar wachtte hij bij elk keerpunt ± 2 s, en dat wachten wordt korter met een kortere staart. Ook dat past bij de conclusie van de CEO.

## 7. Oordeel per testplan §6

| Eis (DoD T17 / testplan §3) | Uitkomst F0-2 | Gehaald? |
|---|---|---|
| Norm (1), MP-1 | 250 / 76 / 113 ticks; K3 niet meer de krapste plek | ✅ bij elke D |
| Norm (2), MP-2 | D = 120 ✅ (8,9/min, K1 5,6); D = 180 en 90 ❌ (K1 0, gat 46–48 s) | alleen D = 120 |
| Norm (3), MP-5 | 2,3 / 3,3 / 2,3 | ❌ bij elke D |
| MP-4 | 2–4 % | ✅ |
| MP-6 | 49–63 %, 5–6 pompslagen | ✅ |
| R-V12, MP-3 | 0 % (0 van 4 landingen; per keerpunt 0 van 15) | ❌ |
| Staart 1,5 / 2 / 3 s | alle drie gemeten, **3 s voor het eerst geldig** (rapport F0, open punt 9), maar één run per D | gemeten; keuzeregel niet van toepassing (W12) |
| *Nine Sols*-check | niet genoemd (meerkeuze) | uitgesteld naar F4b(c) |
| Werkaannames | W1–W21 (testplan) en W22–W24 (§11) | genoemd |

Welke rij van testplan §6 geldt:

- "MP-2 gehaald, maar een andere solo-norm bij geen enkele D" (MP-5) → **geen go**. De oorzaak is niet het restgat: B is niet de grootste groep, D (langzame lijn) wel. Volgens de rij "stelt de LGD een aanpassing voor, en de EP beslist over een derde test of een `ceo-beslissing`".
- "MP-2 niet gehaald bij elke D" geldt **niet**: bij D = 120 is MP-2 gehaald. De kaderregel "haalt de tweede test norm (2) niet → `ceo-beslissing` R-V12" gaat dus volgens de letter niet af. Wel is het een signaal: in twee van de drie runs liet de CEO de echo in K1 links liggen.
- "De beste D ligt buiten 90–180" → `ceo-beslissing`: die is er al. De CEO koos D = 60 (besluit 2026-11-12).

**Advies na het besluit van de CEO.** De vraag "welke D" is beantwoord. De vraag "haalt de kamer F0" staat nog open, en kan op deze data niet meer op 90–180 beantwoord worden: niemand speelt die staarten nog. Geen go F0 en geen `ceo-beslissing` nu. Zoals het besluit zelf zegt, lopen we eerst de maten op D = 60 na, en moeten de bots op D = 60 groen zijn (§8). Daarna meet de volgende mijlpaal-sessie F0 op D = 60, met dezelfde normen (MP-1–MP-6, MP-5 ≥ 4,0, MP-3 ≥ 75 %). Halen MP-2 of MP-3 het dan nog niet, dan bereidt de LGD de `ceo-beslissing` R-V12 voor (gdd §4.7.3). Dat is ook geen extra speeltest voor de CEO: het past in "de CEO test alleen bij mijlpalen".

**Hoeveel dit rapport draagt.** Eén speler, één run per D, drie getelde runs. Oefening en D vallen samen (de laatste run is de enige met de echo in K1). De objectieve maten (MP-2 in K1, MP-3, de stilstand bij het pantserdoel en de laatste schoep) staan los van de scores en zijn het stevigste deel. MP-5 is gestegen, maar het verschil tussen de D's rust op één run per D.

## 8. Wat dit betekent voor D = 60

### 8.1 Eerste bot-indicatie op D = 60 (QA, niet in de suite)

Met `docs/qa/f0-2-meetlogs/botlogs.gd`: de gescripte run (`flow_bot.gd`) en de wachtbot op `8be9910` met D = 60. Dit is een indicatie, geen test: de bot is voor D ≥ 90 geschreven.

| Wat | D = 60 | Ter vergelijking D = 90 |
|---|---|---|
| Gescripte run vanaf `RUN_START` | **komt niet voorbij B3**. Na 7.000 ticks staat P1 op de opstap (x 28), met echo aan én uit. Het B3-blok heeft breedte **B = D − 60 = 0 px**, dus de stap "op het blok" van de bot bestaat niet | `RUN_EIND` op 3.810 |
| B4, lancering | ✅ op tick 113, 30 ticks stilstand ervoor | ✅ |
| B1, B2-0 … B2-3 (run vanaf B1) | **0 van 5 via de echo** (allemaal C): de bot bounct op **54 px** van de wand, in de band van de overhang (40–70 px, 85–129 px hoog), en valt terug op de langzame lijn. Keren tot het volgende niveau: 241 ticks (langzame lijn 142) | 5 van 5 A, bounce op 92 px, 80 ticks |
| Landing na keren (berekend, `flowkamer.md` §3: D + 68) | **128 px = precies de rand van de weg omhoog (120 + 8): 0 px marge**, ook zonder overhang | 158 px, 30 px marge |
| Wachtbot B1 | op 40 px: trede (keerzone werkt); op 160 px: omhoog na 60 ticks wachten (restgat) | idem, na 90 ticks |
| K2 (run vanaf B1) | 34,3 echo-acties/min; langste stilstand 47 (≤ 60 ✅) | 32,4; 45 |
| K3 / LM-04 | elke schoep één slag, `GEMAAL_VOL` 146 ticks vóór `RUN_EIND`, geen stilstand in K3 ✅ | 116 ticks ✅ |
| MP-1 / MP-2 / MP-4 / MP-6 (run vanaf B1) | 47 · 12,0/min (K1 7,1, alleen de springplanks) · 2 % · 63 %, 4 pompslagen ✅ | ✅ |

**Kortom: op de huidige geometrie heeft K1 bij D = 60 geen echolijn.** In B1 en B2 botst de bounce tegen de overhang, en B3 heeft geen blok. K2 en K3 worden bij D = 60 eerder beter: minder wachten bij het pantserdoel en de laatste schoep.

### 8.2 Welke maten van D afhangen en moeten worden nagelopen

Eigenaar: WLD (bouw) en LGD (maten in gdd §4.3), in [#81](https://github.com/cesarvangerwen-glitch/echoborn/issues/81) of een eigen issue van de EP. QA levert de meting.

| Maat (bron) | Nu | Bij D = 60 | Status |
|---|---|---|---|
| **Keerzone** 120 px, rand weg omhoog op 120 (gdd §4.3, W-1/W-2) | landing na keren D + 68: ≥ 158 px | 128 px: 0 marge | ❌ opnieuw maken |
| **Overhang** 40–70 px van de wand, 85–129 px hoog (`flowkamer.md` §3) | de vroegste bounce op 76 px (late bot) | bounce op ± 54 px = in de overhang | ❌ |
| Vlakke vloer vóór de keerwand (nodig D + 24) | B1 320, B2 480 | nodig 84 | ✅ |
| **Richels B2**: landing tot de volgende wand (D + 24); marge tot het dichte stuk van 215 px (bounce passeert de richel op ± D + 76) | D 180 krap (± 9 px) | ± 129 px marge | ✅ (narekenen zodra de keerzone verandert) |
| **B3-blok** B = D − 60 (gdd §4.3) | 30 / 60 / 120 px | **0 px**: geen blok, geen echolijn in B3 | ❌ nieuwe formule of minimum |
| **B4** solo-lancering (afzet T + D − 21 … T + D − 3, `flowkamer.md` §11 punt 7) | werkt | bot lanceert op D = 60 | ✅ (in de suite zetten) |
| **LM-04** `GEMAAL_VOL` op t₄ − 40 + D; ≥ 140 ticks kade (`flowkamer.md` §5) | 13–103 ticks vóór de sluis | eerder vol, 146 ticks marge | ✅ |
| **FK-2** langzame lijn ≤ 2× keren (`flowkamer.md` §10) | 142 / 80 = 1,8× bij D = 90 | keren kan nu niet. Als het weer kan, ligt het lineair doorgetrokken (80 / 95 / 125–133) rond ± 65 ticks: 142 > 2 × 65 | ⚠️ opnieuw meten; de langzame lijn of keren aanpassen |
| Merk-levensduur D + 30 (K2) | 120–210 ticks | 90 ticks | bot ✅. Bij mensen: M2 en de stilstand bij het pantserdoel opnieuw meten |
| LP ≥ 100 na K1 + K2 (gdd §4.2) | 111–121 | 107 vanaf B1 (zonder B4/B3); met de hele run onbekend | meten |
| Grens C in W15 (60 px: tussen bounce bij de wand en de vroegste keerlanding, 90 px bij D = 90) en de banden van de wachtbot (80–119 / 120–240) | voor D ≥ 90 | de vroegste keerlanding komt dicht bij 60 px | QA past W15 aan op de nieuwe maten |
| Debugmenu F1/F2/F3 = 90/120/180 (`DEBUG_TAIL_KEYS`), het scorescherm, de tests per D | 90/120/180 | D = 60 ontbreekt overal | ❌ toevoegen (Gameplay Programmer) |

### 8.3 Wat de bots op D = 60 moeten aantonen vóór de volgende mijlpaal-sessie

Dezelfde lat als vóór F0-2 (testplan F0-2 §2), nu op D = 60, in de gewone suite (`run_tests.gd`), na de aanpassing van §8.2:

1. **Gescripte run D = 60 vanaf `RUN_START`**: `RUN_EIND`. MP-1 ≤ 300, MP-2 ≥ 3,0 (ook K1 en K2 apart, geen gat > 40 s), MP-4 ≤ 40 %, MP-6 ≥ 40 % met ≥ 1 pompslag van de echo. LP ≥ 100 na K1 + K2.
2. **K1, keren bij elk keerpunt** (`test_flowkamer_na_f0.gd`): 5 van 5 via de echo zonder stilstand van 20 ticks (MP-3 per keerpunt). Keren sneller dan de langzame lijn, en de langzame lijn ≤ 2× keren (FK-2). `test_keerzone_geometry` voor D = 60.
3. **Late bot D = 60**: de weg omhoog met de bounce 4 en 8 ticks te laat, met marge tot de rand. De overhang wordt in geen variant geraakt.
4. **Wachtbot D = 60**: de tabel in `flowkamer.md` §9 voor D = 60 (tegen de wand → trede; waar het restgat begint).
5. **B3 en B4 op D = 60**: de echolijn van B3 bestaat en de bot haalt hem; de solo-lancering in B4.
6. **K3, LM-04 op D = 60**: elke schoep één slag, `GEMAAL_VOL` vóór P1 bij de sluis is, geen stilstand > 30 in K3.
7. **Echo uit (FK-2)** op D = 60: ≤ 2× de run met echo, ≤ 4 keer terug naar K2.
8. **D = 60 kiesbaar** in het debugmenu, met de D op de HUD en het scorescherm, en het meetlog als `…_D60_….csv`.
9. QA draait `rekenen.gd` op de logs van punt 1 en 4 (5 van 5 A, en de wachtplek). Daarna komen testplan en kaart voor de mijlpaal-sessie op D = 60.

Of 1,5 s (D = 90) als tweede staart in die sessie mee moet als vergelijking, is een keuze voor de LGD en de EP binnen het besluit (bereik 1–3 s). Het helpt om "korter = beter" te toetsen met meer dan één run.

## 9. T17 (DoD) en wat er openstaat

DoD van #80: "Plan + rapport: normen (1)–(3) solo; staart 1,5 / 2 / 3 s; echo ≤ 40 % Leeg; R-V12; de *Nine Sols*-check. Spelers: scripted runs + de CEO" en "noemt de werkaanname".

- **Wat er nu is**: plan en rapport voor beide flow-tests, scripted runs, twee CEO-sessies, alle drie de staarten gemeten (3 s nu ook), MP-4, R-V12 gemeten en de *Nine Sols*-check uitgesteld zoals het kader zegt. De werkaannames staan erin. Als taak ("de flow-test uitvoeren en rapporteren") is T17 daarmee **gedaan**.
- **Wat niet gehaald is**: F0 zelf (norm (3) en R-V12). De staart is gekozen door een CEO-besluit (D = 60) en niet door de keuzeregel op de solo-normen (kader F0: "staartduur gekozen binnen 1,5–3 s op de solo-normen"; het besluit maakt het bereik 1–3 s).
- **Advies**: de EP sluit #80 na de merge van dit rapport, met deze open punten **expliciet overgedragen** (zie §10):
  - de maten op D = 60 nalopen: LGD/WLD, #81;
  - het bot-bewijs op D = 60 (§8.3): WLD/Gameplay Programmer, met QA;
  - F0 op D = 60 in de volgende mijlpaal-sessie: QA, een nieuw testplan en een nieuwe kaart;
  - de tekst van F0 in het fasekader: EP.

  Wil de EP F0 als criterium liever aan T17 laten hangen, dan blijft #80 open tot die sessie. Dat is een keuze voor de EP. Door het besluit van 2026-11-12 (fase 2 parallel) wacht er geen ander werk meer op.
- **Geen CEO-vraag nodig**: het besluit van 2026-11-12 dekt de staart, het nalopen op D = 60 en "de CEO test bij mijlpalen".

## 10. Wat er nu moet gebeuren

| Wie | Wat | Waarom |
|---|---|---|
| **Lead Game Designer** (met de WLD), [#81](https://github.com/cesarvangerwen-glitch/echoborn/issues/81) | De maten van §8.2 voor D = 60: keerzone en overhang (bounce op ± 54 px, landing 128 px = 0 marge), het B3-blok (D − 60 = 0), FK-2. Daarbij de input van F0-2: de langzame lijn bij elk keerpunt in > 50 % van de runs (trede verder van de wand), de wachtafstanden van 182–249 px (geen 80–119), de bovenste trede in K3, het wachten bij het pantserdoel en bij de laatste schoep | Besluit 2026-11-12; §4.2, §5, §8 |
| **World & Level Designer / Gameplay Programmer** | Na de nieuwe maten: de bots en tests per D uitbreiden met D = 60 (§8.3 punt 1–8), D = 60 in het debugmenu | §8.3 |
| **QA Lead** | Op de groene suite met D = 60: `rekenen.gd` op de bot-logs (W15 aangepast), daarna testplan en kaart voor de mijlpaal-sessie op D = 60 (± 3–4 runs, besluit "CEO test bij mijlpalen"). M1, M2, O1 en O2 **open** vragen, niet als meerkeuze (W18) | §6, §8.3 |
| **Executive Producer** | #80 sluiten met de overdracht van §9; F0 in het fasekader bijwerken (staart door besluit, bereik 1–3 s) | §9 |
| **LGD, Gameplay Programmer** (E-02t, E-14j) | M2 is twee keer "niet begrepen", ook met de cirkel (gezien, hielp). Overwegen hoe de merksprong laat zien *waarom* hij knalt; ook voor T10 (UX Designer, Art Director) | §6 |

## 11. Open punten en werkaannames

| # | Wat | Wie |
|---|---|---|
| 1 | Bot-bewijs op D = 60 (§8.3) en de maten van §8.2 | lead-game-designer, world-level-designer, gameplay-programmer |
| 2 | Testplan en kaart voor de mijlpaal-sessie op D = 60; W15 en de banden van de wachtbot op de nieuwe maten | qa-lead |
| 3 | Bovenste trede in K3: in 2 van de 3 getelde runs geland en terug naar K2 gesprongen (§5.3). Kiezen of dat zo blijft | world-level-designer (review LGD) |
| 4 | Het meetlog weet in K1 niets van de route zonder events (§4.3). Een event per nieuw niveau of een grove positie-steekproef? Wijzigt gdd §4.7.4 | lead-game-designer, gameplay-programmer |
| 5 | Afgebroken run 12:11 (84,5 s stil in de startgang): bij de volgende sessie in de kaart vragen wat er gebeurde. Testplan open punt 3 (eerste knop op de pijltjeskant) staat nog open | qa-lead, ux-designer |

**Werkaannames.** W1, W2, W7–W10 uit `testplan-f0.md` §6 en W11–W21 uit `testplan-f0-2.md` §7. Nieuw in dit rapport:

| # | Aanname | Waarom |
|---|---|---|
| W22 | Uitkomst D ("langzame lijn") betekent: het volgende niveau gehaald zonder `SPRINGPLANK` op dit niveau. Ook een andere weg zonder echo telt als D | W15: zonder events geen positie (§4.3) |
| W23 | De banden van V1 en H rapporteert QA als band ("4–5"), niet als getal, en ze tellen niet mee in een gemiddelde | Het antwoordblok gaf banden uit meerkeuze |
| W24 | De bot-runs op D = 60 (§8.1) zijn een indicatie: de bot is geschreven voor D ≥ 90 en start bij B1 met een andere route-stap. Geen oordeel over D = 60 | Er is nog geen bot of test voor D = 60 |

## Wijzigingen

| Versie | Datum | Wijziging |
|---|---|---|
| 0.1 | 2026-11-12 | Eerste versie (#80, T17-2 deel 2): 3 van de 6 getelde runs, normen per D, MP-3 per keerpunt, stilstand per kamer met plek, de regels uit `flowkamer.md` §12, verklaring van geen SPRINGPLANK in K1 en van K3 → K2 → K3, advies na het besluit D = 60 (maten, bot-bewijs, T17). Rekenscript `rekenen.gd` en `botlogs.gd` in `docs/qa/f0-2-meetlogs/` |
