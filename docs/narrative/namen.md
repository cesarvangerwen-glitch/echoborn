# Namen van gebieden en wijken *Polderlight*

Versie 0.1 · Eigenaar: Narrative Designer · Lead-review: Creative Director · Taak: T10, `docs/ux/hud-menus.md` §7 punt 17 ([#87](https://github.com/cesarvangerwen-glitch/echoborn/issues/87))
Bronnen: `docs/design/wereld.md` §1.3–§1.4 en §2 (werknamen, opbouw WS-01), `docs/narrative/verhaal-v2.md` §2, §4 en §8 (Hollestede, thema's, toonregels), `docs/ux/hud-menus.md` §4.2, §4.7, §4.8 en §6, besluiten #51 (verzonken stad in de Lage Landen) en #96 (*Polderlight*).

Dit document legt de namen vast van de proloog, de 4 gebieden, hun 12 wijken en de finale van Hollestede, in EN en NL, met wat ze betekenen en hoe breed ze zijn. De teksten staan in `game/locale/strings.csv`. De opbouw (welke wijk in welk gebied ligt, de volgorde) is van de World & Level Designer (`wereld.md` WS-01, WS-04); dit document noemt alleen.

---

## 1. Regels voor een naam

| ID | Regel |
|---|---|
| **NM-1** | **Breedte: een wijknaam is ≤ 165 px** in Polderletter normaal, in EN én NL (`hud-menus.md` §4.2: de zijband van het hoofdmenu vanaf x 41). Gemeten met `text_width` uit `docs/art/ui/bron/polderletter.py`. Te lang = korter schrijven, nooit kleiner zetten of afbreken (§6 van de UX-spec). Dezelfde grens houdt `MENU_SLOT_DETAILS` op één regel (§4.7a). Een gebiedsnaam valt niet onder die grens (hij staat in een tab, niet in de zijband), maar blijft er ook onder. |
| **NM-2** | **Een plek, geen gebeurtenis.** Elke naam is een gewone stadsnaam: een gebouw, een straat, een stuk dijk. Geen naam zegt iets over het water, het vergeten of Ward; dat leest de speler af aan de plek zelf (`verhaal-v2.md` §2.2). Zo verklapt een naam niets en breekt hij niet als je een wijk in een andere volgorde of opnieuw bezoekt (§4.1). |
| **NM-3** | **Verzonnen, en geen ramp** (toonregel W-6). Alleen soortnamen van gebouwen en plekken uit de Lage Landen (begijnhof, lakenhal, waag, belfort); geen bestaande plaats, geen datum, geen monument. |
| **NM-4** | **Geen naam twee keer.** Een wijk heet niet zoals een boss, een vaardigheid of haar eigen gebied, zodat *De Waag · Licht 40* nooit kan betekenen "je staat bij de boss". |
| **NM-5** | **NL eerst, EN als eigen naam.** De NL-naam is de bron (de stad ligt in de Lage Landen). De EN-naam is geen woord-voor-woordvertaling maar de naam die een Engelstalige stad voor zo'n plek zou gebruiken (*Quayside*, *Canal Row*). Engels in Brits Engels (*dyke*, niet *dike*). Hollestede blijft in beide talen Hollestede. |
| **NM-6** | **Hoofdletters.** Gebiedsnamen zijn beschrijvend en krijgen in het NL alleen een hoofdletter vooraan (*De polderwijk*, zoals `wereld.md` §1.3); wijknamen zijn eigennamen (*De Kadewijk*), en dat geldt ook voor de proloog en de finale, want hun naam staat op de plek van een wijknaam (*De Ringdijk*, *De Grote Sluis*). In lopende tekst over het verhaal mag *de ringdijk* klein blijven. EN volgt title case. |

---

## 2. De namen

Breedte in px, Polderletter normaal / groot (TG-10). Grens NM-1: **165** normaal (bij *groot* wordt de zijband 260 px, `hud-menus.md` §4.2). Alles gemeten op 2026-11-10 met de huidige `polderletter.py`.

### 2.1 Proloog en finale

| Sleutel | NL | px | EN | px | Betekenis |
|---|---|---:|---|---:|---|
| `COMMON_DISTRICT_PROLOGUE` | De Ringdijk | 47 / 58 | The Ring Dyke | 62 / 77 | De dijk rond de polder waarover de machinist aankomt; boven het water, onder hem de grijze stad. In het logboek heet de tab *Proloog* (`MENU_LOG_PROLOGUE`); de wijkregel in het menu toont *De Ringdijk*. |
| `COMMON_DISTRICT_FINALE` | De Grote Sluis | 64 / 78 | The Great Sluice | 74 / 90 | Waar het water binnenkwam. Een gewoon woord voor een groot ding; de sluis is geen monster in haar naam, alleen in de boss (De Grendel). |

### 2.2 Gebieden (`COMMON_AREA_n`: logboektab, pauze)

| Sleutel | NL | px | EN | px | Betekenis |
|---|---|---:|---|---:|---|
| `COMMON_AREA_1` | De polderwijk | 58 / 70 | The Polder Quarter | 87 / 104 | De gewone woonwijk onder dijkniveau: kades, smalle huizen, een gemaal. Het thema "het gewone dat terugkomt" zit al in de naam. |
| `COMMON_AREA_2` | Het begijnhof | 57 / 70 | The Beguinage | 62 / 76 | Een hof van huisjes rond een tuin, voor vrouwen die voor anderen zorgden. Zorg en wachten. |
| `COMMON_AREA_3` | De markt en de waag | 92 / 113 | The Market and the Weigh House | 143 / 175 | De drukte van de markt en het gebouw waar alles gewogen werd. Wegen en vasthouden. De langste naam; past in de tabbalk (§2.4). |
| `COMMON_AREA_4` | Het belfort | 49 / 59 | The Belfry | 47 / 57 | De klokkentoren met het carillon dat de maat van tien tellen sloeg (`verhaal-v2.md` §2.3). Tijd en maat. |

### 2.3 Wijken (`COMMON_DISTRICT_n_m`: regel onder *Doorgaan*, `MENU_SLOT_DETAILS`)

| Sleutel | NL | px | EN | px | Betekenis |
|---|---|---:|---|---:|---|
| `COMMON_DISTRICT_1_1` | De Dijkvoet | 50 / 61 | Dykefoot | 38 / 47 | De huizen aan de voet van de ringdijk: de eerste wijk na de afdaling uit de proloog. |
| `COMMON_DISTRICT_1_2` | De Grachtenrij | 64 / 77 | Canal Row | 44 / 55 | Een rij smalle huizen en pakhuizen langs een gracht (de poort in een pakhuis, `wereld.md` §1.4). |
| `COMMON_DISTRICT_1_3` | De Kadewijk | 51 / 63 | The Quayside | 57 / 70 | Kades, de vismarkt, het sluiswachtershuis en het gemaal: de slice (`wereld.md` §2). |
| `COMMON_DISTRICT_2_1` | De Poort | 39 / 48 | The Gatehouse | 64 / 79 | De ingang van het hof met de poorttoren (`wereld.md` §1.4). Een begijnhof is een hof achter een poort; de Wake houdt hem dicht. EN *Gatehouse*, omdat *The Gate* alleen een deur is en geen plek. |
| `COMMON_DISTRICT_2_2` | De Omgang | 46 / 58 | The Cloister Walk | 77 / 93 | De overdekte gang rondom: lussen voor de echo, waar je steeds weer langs dezelfde deuren loopt. |
| `COMMON_DISTRICT_2_3` | De Binnentuin | 58 / 71 | The Inner Garden | 78 / 93 | De tuin en de kapel in het midden, het stilste punt van het spel; vaardigheid en boss. |
| `COMMON_DISTRICT_3_1` | De Kramen | 46 / 56 | The Stalls | 45 / 55 | Marktkramen die te vol staan om nog te dragen. |
| `COMMON_DISTRICT_3_2` | De Lakenhal | 52 / 64 | The Cloth Hall | 63 / 77 | De hal van de lakenhandel, met hoge gevels en hijsbalken (omhoog, B2). |
| `COMMON_DISTRICT_3_3` | **Het Waagplein** | 59 / 72 | **Weigh House Square** | 87 / 106 | Het plein voor het waaggebouw; in het gebouw staat de boss, De Waag. **Gewijzigd**, zie §3. |
| `COMMON_DISTRICT_4_1` | De Torenvoet | 60 / 72 | Towerfoot | 44 / 54 | De voet van het belfort, waar de wenteltrappen beginnen. Rijmt met *De Dijkvoet*: de stad begint aan een voet en eindigt aan een voet. |
| `COMMON_DISTRICT_4_2` | De Uurwerkzaal | 69 / 83 | The Clockwork Hall | 85 / 103 | De zaal met de raderen van het uurwerk en de torenbakken. |
| `COMMON_DISTRICT_4_3` | De Klokkenkamer | 74 / 89 | The Bell Chamber | 77 / 94 | Bovenin, bij het carillon dat stilstaat op de tiende tel. |

**Langste wijknaam:** *Weigh House Square*, 87 px: 78 px onder de grens. Ruimte genoeg om een naam later nog te wijzigen.

### 2.4 Past het ook elders?

- **Logboektabs** (MN-30; tabbalk als Opties, x 16–624 = 608 px): de 5 tabs van Opties nemen NL 298 px bij 198 px tekst, dus ± 20 px per tab. Alle gebieden plus *Prologue* in EN: 377 px tekst + 100 = **477 van 608**; NL 289 + 100 = 389 van 608. Groot: EN 457 + ± 110 = ± 567 van ± 840. Past, ook als je alle vier de gebieden kent.
- **Bevestiging** (MN-23, details `Gedimd` in het paneel, 368 px): wijknaam + speeltijd is ruim binnen de breedte.
- **`MENU_SLOT_DETAILS`** (max. 379 px): met de langste wijknaam (87) en de langste rest uit §4.7a (190) 277 px.

---

## 3. Wat er veranderd is tegenover `wereld.md`

De werknamen uit `wereld.md` §1.3 zijn de basis (`wereld.md` OW-2, `verhaal-v2.md` §10 punt 1). Eén naam verandert:

| Wijk | Was | Wordt | Waarom |
|---|---|---|---|
| 3.3 | *De Waag* | **Het Waagplein** | NM-4: de boss van gebied 3 heet ook *De Waag* (`verhaal-v2.md` §4.2) en het gebied heet *De markt en de waag*. Drie keer "waag" op één plek: in het slot-menu kon *De Waag · Licht 60* lezen als "staat bij de boss". *Waagplein* houdt het gebouw in beeld en is een plek, geen tegenstander. |

Alle andere namen zijn overgenomen. Bewust niet veranderd:
- *De polderwijk* (gebied) met daarin *De Kadewijk* (wijk): twee keer "wijk", maar het ene is een stadsdeel en het andere een buurt aan de kade; de spelers zien ze nooit naast elkaar (het gebied staat in de tab, de wijk in de slot-regel). *De Kadewijk* is ook al de naam van de slice in elk document.
- *De Uurwerkzaal* naast de boss *Het Uurwerk*: de zaal is naar het mechaniek genoemd, niet naar de boss, en *zaal* maakt het een plek. Komt de Combat Designer met een andere bossnaam, dan verandert dit niet.

---

## 4. Open punten

| # | Punt | Wie | Wanneer |
|---|---|---|---|
| NM-O1 | **Tabel gebied → wijk** (`hud-menus.md` §7 punt 13): welke waarde van `state.gebied` (of een wijk-id ernaast) bij welke sleutel hoort. Voorstel: proloog → `COMMON_DISTRICT_PROLOGUE`; wijk *n*.*m* → `COMMON_DISTRICT_n_m` en gebied *n* → `COMMON_AREA_n`; finale → `COMMON_DISTRICT_FINALE` (de logboektab van de finale, als die er komt, is van de UX Designer). Of `state.gebied` de wijk bevat of alleen het gebied, beslissen de World & Level Designer en de Gameplay Programmer; de sleutels hierboven werken voor beide. | World & Level Designer, Gameplay Programmer | Met T8a |
| NM-O2 | **`wereld.md` §1.3 en §1.4 bijwerken:** wijk 3.3 heet *Het Waagplein* (§3). Ik verander dat document niet zelf. | World & Level Designer | Bij de volgende versie van `wereld.md` |
| NM-O2a | Wijk 2.1 *De Poort* botst met de spelterm *terugkeerpoort* (`wereld.md` §1.4); samen met NM-O2 beslissen of de naam blijft of wordt bv. *De Poorttoren*. | World & Level Designer, met Narrative Designer | Samen met NM-O2 |
| NM-O3 | **Opnieuw meten** als Polderletter verandert (eind-font van de UI Artist, `hud-menus.md` §7 punt 1 en 10): de breedtes hier zijn van de huidige `polderletter.py`. Met 78 px marge verwacht ik geen probleem. | Narrative Designer, UI Artist | Bij een nieuw font |
| NM-O4 | De EN-namen zijn door de Narrative Designer geschreven, niet door een moedertaalspreker. *Dykefoot* en *Towerfoot* zijn verzonnen samenstellingen: laten toetsen door een EN-lezer, samen met de rest van de EN-tekst. Aangenomen door de CD (Lead-review). | Creative Director | Vóór de eerste publieke build |

---

## 5. Wijzigingen

| Versie | Wat |
|---|---|
| 0.1 | Eerste versie (T10, `hud-menus.md` §7 punt 17): namen van proloog, 4 gebieden, 12 wijken en finale in EN en NL, met betekenis en gemeten breedte; wijk 3.3 *De Waag* wordt *Het Waagplein*; sleutels `COMMON_AREA_1`–`4` en `COMMON_DISTRICT_*` in `strings.csv` |
| 0.1.1 | Na de Lead-review CD: *De Ringdijk* en *De Grote Sluis* met hoofdletters (NM-6, hermeten); open punt NM-O2a (*De Poort*); NM-O4 aangenomen door de CD |
