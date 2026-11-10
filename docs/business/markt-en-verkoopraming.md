# Markt en verkoopraming: *Polderlight* (werktitel)

Versie 0.1 · eigenaar: Marketing & Community Manager · peildatum 2026-11-10 · input voor issue [#72](https://github.com/cesarvangerwen-glitch/echoborn/issues/72) (T13, VAF-dossier productiesteun fase 3)

## 1. Doel

Dit document levert de inhoud voor twee onderdelen van het VAF-dossier (`docs/business/vaf-dossier-productie.md` §3 en §6.2):

- **D6**: doelgroep, markt en vergelijkbare titels (vult §4.3 van het dossier aan met marktonderzoek).
- **D8**: verkoopraming voor 24 maanden na release, in drie scenario's, van bruto naar netto.

De Business/Legal Advisor (BLA) neemt eruit over wat het dossier nodig heeft; de Executive Producer (EP) gebruikt D8 voor het financieringsplan (D10). **D7 (tractie) en D13 (pitchvideo) vallen hier buiten**: die vragen een publieke uiting en komen pas na de slice en een CEO-besluit over een Steam-pagina (#24, 3A).

**Leesregel.** Elk cijfer heeft een bron en een datum. Schattingen van verkoop zijn schattingen (methode staat erbij), geen bevestigde cijfers. Wat ik niet kon bevestigen, staat er als *niet bevestigd*.

## 2. D6: doelgroep en markt

### 2.1 Het genre op Steam

| Cijfer | Waarde | Bron (datum) |
|---|---|---|
| Games met de tag Metroidvania, uitgebracht | 1.817 (Steam: 1.819); nog 1.565 onuitgebrachte pagina's | Steam Page Analyzer, *Steam Niche Index*, telling 2026-09-27 ([link](https://www.steampageanalyzer.com/niches/metroidvania)) |
| Releases per jaar | 2021: 186 · 2022: 173 · 2023: 219 · 2024: 263 · 2025: 291 · 2026 t/m 27-09: 223 (≈ +9 % t.o.v. dezelfde weken in 2025) | idem |
| Mediaan aantal reviews (cohort jan 2024–jun 2025, 402 games) | 22 (alle Steam-games: 11) | idem |
| Aandeel met ≥ 1.000 reviews | 6,2 % (alle Steam: 4,2 %) | idem |
| Prijsklasse $15–19,99 (56 games) | mediaan 174 reviews; 55,4 % haalt 100+; 14,3 % haalt 1.000+ | idem |
| Prijsklasse $20 en hoger (40 games) | mediaan 322 reviews; 70 % haalt 100+; 35 % haalt 1.000+ | idem |
| Mediaan lijstprijs (betaalde metroidvania's) | $9,99 | idem |

**Wat dit zegt.** Het genre doet het beter dan het Steam-gemiddelde, maar de concurrentie groeit elk jaar (≈ 290 releases in 2025). Games rond $15–20 doen het duidelijk beter dan goedkope games; dat kan ook komen doordat sterkere games een hogere prijs durven te vragen (geen oorzaak bewezen). De bron waarschuwt zelf: tags worden door spelers gezet, de reviewtelling is wat een Amerikaanse bezoeker ziet (mogelijk alleen Engels), en de prijsklassen tellen op tot 344 in plaats van 402 games.

**De top van het genre** laat zien hoe groot het publiek kan zijn, niet wat wij verwachten: *Hollow Knight* heeft ± 416.000 Steam-reviews en 5–10 miljoen eigenaren, *Ori and the Will of the Wisps* ± 137.000 reviews (SteamSpy-API, opgevraagd 2026-11-10, `https://steamspy.com/api.php?request=appdetails&appid=367520` en `…=1057090`). Dat is het publiek van de genrefan uit pitch §9.

### 2.2 Segmenten

| Segment | Wie (pitch §9) | Wat de markt zegt | Status van de onderbouwing |
|---|---|---|---|
| **De genrefan** (primair) | Speelde *Hollow Knight*, *Nine Sols*, *Ori*; vooral solo | Groot en bewezen publiek (zie 2.1); kortere indie-metroidvania's van ± € 20 met een eigen idee vinden hun publiek (*Haiku*, *Islets*, *Constance*, *MIO*: tabel §3) | Onderbouwd met vergelijkbare titels |
| **Het bankduo** (secundair) | Koppel of vrienden, één ervaren en één minder ervaren speler, pc aan de tv | Weinig metroidvania's met lokale co-op; de twee die ik vond verkochten matig (*Guacamelee! 2* goed, *Curse of the Sea Rats* zwak, §3) | **Niet onderbouwd.** Ik vond geen cijfers over hoeveel metroidvania-kopers co-op spelen. Co-op blijft een tweede argument, niet de motor van de raming |
| **Steam Deck-spelers** (kanaal, geen apart segment) | Solo-spelers onderweg/op de bank | Metroidvania's passen goed bij een handheld; Deck-verkopen daalden naar schatting 80–82 % per week na de prijsverhoging van mei 2026 (Boiling Steam, via [PC Gamer, 2026-07-22](https://www.pcgamer.com/hardware/handheld-gaming-pcs/steam-deck-sales-are-estimated-to-have-plummeted-by-around-80-percent-since-the-massive-price-hikes-earlier-this-year-back-of-the-napkin-maths-suggests/)); Linux-aandeel Steam 3,05 % in september 2026 ([Steam Deck HQ, 2026-10-05](https://steamdeckhq.com/steam-hardware-survey-results-sep-26/)) | Deck-verified is een voorwaarde (#2), geen groeimotor. We noemen de Deck alleen voor solo (pitch §9) |
| **Nederlandstalig publiek** (NL/BE) | Speelt in het Nederlands | NL-versie bij release in principe ja (#51, 5A); geen cijfers gevonden over het effect op verkoop | Niet bevestigd; waarde vooral cultureel (VAF art. 4) |

**Conclusie voor D6.** De raming steunt op de genrefan. Co-op en de Laag-Landse wereld onderscheiden ons (pitch §8), maar ik reken er niet extra op tot er bewijs is (open punt O2).

## 3. Vergelijkbare titels

**Methode.** Reviews uit de SteamSpy-API (positief + negatief), opgevraagd 2026-11-10 (`https://steamspy.com/api.php?request=appdetails&appid=<id>`); voor titels van 2025–2026 die daar nog op 0 staan: de telling van Steam Page Analyzer van 2026-09-27 (link §2.1). Prijs, jaar en team uit de Steam-API (`https://store.steampowered.com/api/appdetails?appids=<id>&cc=nl`, 2026-11-10; lijstprijs in euro, zonder korting). De Steam-winkelpagina zelf kon ik niet lezen (toegang geblokkeerd); SteamSpy telt lager dan Steam (bv. *Haiku*: 2.906 bij SteamSpy, 3,6K bij [Datahumble](https://datahumble.com/haiku-the-robot-1231880)), dus de schattingen zijn eerder te laag dan te hoog.

**Verkoopschatting = reviews × Boxleiter-ratio.** De ratio hangt af van het jaar, omdat Steam sinds oktober 2019 vaker om een review vraagt. Ik gebruik per releasejaar de bandbreedte van [Steam Page Analyzer (2026-06-16)](https://www.steampageanalyzer.com/blog/steam-review-to-sales-multiplier): **2014–2018: 40–65×**, **2019–2021: 30–50×**, **2022–2026: 20–40×**. Ter controle: GameDiscoverCo mat 36× bij games onder 100 reviews en 52,8× bij 1.000–10.000 reviews ([2023-08-28](https://newsletter.gamediscover.co/p/what-steam-review-count-tells-us)). De bandbreedte is breed omdat de ratio per game sterk wisselt (prijs, korting, speeltijd, score).

| Titel | Jaar | Team | Prijs (NL) | Waarom vergelijkbaar | Reviews | Geschatte verkoop (Steam) |
|---|---|---|---|---|---|---|
| *Haiku, the Robot* | 2022 | Mister Morris Games (solo-ontwikkelaar Jordan Morris) | € 18,99 | Indie-metroidvania, pixel art, ± € 20, publiek van *Hollow Knight* | 2.906 (Datahumble: 3,6K) | 58K–116K (20–40×). **Bevestigd datapunt:** ± 15.000 kopieën in de eerste zes weken, bij 37.000 wishlists op de launch ([GameDiscoverCo, 2022-07-05](https://newsletter.gamediscover.co/p/how-to-make-a-hit-indie-metroidvania)) |
| *Islets* | 2022 | Kyle Thompson (solo), uitgever Armor Games Studios | € 19,50 | Korte, vriendelijke indie-metroidvania, ± € 20 | 1.674 | 33K–67K (20–40×) |
| *Well Dweller* | 2026 (22-09) | Kyle Thompson, met Top Hat Studios en Doyoyo Games | € 14,25 | Recentste indie-metroidvania van een kleine maker | 1.121 (na 5 dagen, telling 27-09) | Te vroeg; ratio in de eerste weken onbetrouwbaar. *Niet geschat* |
| *Constance* | 2025 (24-11) | Blue Backpack, met ByteRockers' Games en PARCO GAMES | € 19,50 | Indie-metroidvania 2025, zelfde prijspunt | 1.223 (27-09) | 24K–49K (20–40×), na ± 10 maanden |
| *MIO: Memories in Orbit* | 2026 (20-01) | Douze Dixièmes (FR), uitgever Focus Entertainment | € 19,99 | Europese metroidvania, zelfde prijs, met uitgever | 1.950 (27-09) | 39K–78K (20–40×), na ± 8 maanden |
| *Timespinner* | 2018 | Lunar Ray Games, uitgever Chucklefish | € 20,49 | Tijd-mechaniek in een pixel-art-metroidvania | 2.906 | 116K–189K (40–65×); SteamSpy: 200K–500K eigenaren (incl. gratis acties, *niet bevestigd* als verkoop) |
| *Guacamelee! 2* | 2018 | DrinkBox Studios (CA), met Kepler Ghost | € 20,49 | Metroidvania **met lokale co-op** (Steam-categorie Shared/Split Screen Co-op) | 3.145 | 126K–204K (40–65×) |
| *Curse of the Sea Rats* | 2023 | Petoons Studio (ES) | € 9,99 | Metroidvania **met lokale co-op** van een klein team | 197 (Datahumble: 224, 59 % positief) | 4K–8K (20–40×); Datahumble schat 6,2K ([link](https://datahumble.com/curse-of-the-sea-rats-1453900)) |
| *Super Time Force Ultra* | 2014 | Capybara Games (CA) | € 12,49 | **Vorige versies van jezelf** die meevechten (pitch §7) | 950 | 38K–62K (40–65×) |
| *Koira* (Benelux) | 2025 (01-04) | Studio Tolima (Brussel), uitgever DON'T NOD | € 17,99 | Belgische 2D-indie (geen metroidvania), Belgische Game van het Jaar 2025 ([GamesMarket, 2025-12-11](https://www.gamesmarket.global/tolima-wins-three-belgium-game-awards-with-koira/)) | 168 | 3K–7K (20–40×); erg onzeker bij zo weinig reviews |

**Plafond, geen vergelijking:** *Nine Sols* (2024, Red Candle Games, € 28,99; 28.896 reviews → ± 0,6–1,2 M) en *ENDER LILIES* (2021, Live Wire/Adglobe, € 24,99; 39.533 reviews → ± 1,2–2,0 M). Beide met een groter team en een bekende naam of uitgever; ze tonen wat het genre kan, niet wat een eerste game van ons haalt.

**Wat ik niet vond.** Geen Vlaamse of Nederlandse metroidvania met openbare cijfers: de lijst van Belgische releases ([wiki.belgiangames.be](https://wiki.belgiangames.be/releasedbelgiangames), gelezen 2026-11-10) noemt geen genre en ik herkende er geen metroidvania in. *Koira* staat erin als Belgische 2D-referentie. Teamgroottes zijn nergens bevestigd behalve bij de twee solo-makers.

**Lessen voor ons.**
1. Indie-metroidvania's van ± € 20 met een eigen idee halen in hun eerste 1–2 jaar vaak 25.000–100.000 kopieën (*Haiku*, *Islets*, *Constance*, *MIO*). Dat zijn wel de *succesvolle* titels: ik koos ze omdat ze bekend zijn (overlevingsbias, §5).
2. *Haiku* had 37.000 wishlists bij de launch. Zonder publieke pagina in fase 2 (#24, 3A) begint onze wishlist-opbouw laat; dat weegt in de raming.
3. Lokale co-op alleen verkoopt niet vanzelf: *Curse of the Sea Rats* (co-op, lage score) bleef klein, *Guacamelee! 2* deed het goed met een bekende naam en een vorig deel.

## 4. D8: verkoopraming (24 maanden na release, alleen Steam)

### 4.1 Drie scenario's

| | Laag | Midden | Hoog |
|---|---|---|---|
| Verkochte kopieën (24 mnd) | 4.000 | 15.000 | 45.000 |
| Ongeveer gelijk aan (reviews, bij 25–35×) | ± 115–160 | ± 430–600 | ± 1.300–1.800 |
| Plaats t.o.v. het genre (§2.1) | Onder de mediaan van $15–20 (174 reviews) | Tussen mediaan en top | Top ± 15–35 % van de prijsklasse (1.000+ reviews) |
| Vergelijkbaar met | *Curse of the Sea Rats*, *Koira* | *Haiku* in zijn eerste zes weken | *Constance*, *MIO*, *Islets* |
| Gemiddelde betaalde prijs incl. btw (lijst € 19,99) | 60 % = € 11,99 | 65 % = € 12,99 | 70 % = € 13,99 |
| **Bruto consumentenomzet** (incl. btw) | € 47.960 | € 194.850 | € 629.550 |
| − btw/sales tax (gem. 12 %) | € 42.821 | € 173.973 | € 562.098 |
| − terugbetalingen (10 %) | € 38.539 | € 156.576 | € 505.888 |
| − Steam-aandeel (30 %) | **€ 26.978** | **€ 109.603** | **€ 354.122** |
| Netto per kopie voor de studio | € 6,74 | € 7,31 | € 7,87 |

Rekenregel: netto = kopieën × gem. prijs incl. btw (afgerond zoals in de tabel) ÷ 1,12 × 0,90 × 0,70; bedragen afgerond op de euro. Bedragen zijn vóór vennootschapsbelasting en vóór eventuele kosten van een uitgever (we hebben er geen, #2).

**Hoe te lezen voor het dossier.** *Midden* is het scenario dat ik aanraad als basis voor het financieringsplan (D10): realistisch voor een goed ontvangen eerste game zonder uitgever en zonder marketingbudget. *Laag* is wat er gebeurt als de wishlist-opbouw tegenvalt. *Hoog* vraagt een sterke launch (Next Fest, pers, ± 30.000+ wishlists) en is geen verwachting.

### 4.2 Aannames

- A1. **Prijs** € 19,99 / $19,99, eenmalig, geen microtransacties, geen DLC (#2). Andere platformen (GOG, Switch) en bundels tellen niet mee.
- A2. **Kopieën** zijn betaalde Steam-verkopen; gratis keys (pers, Kickstarter, acties) tellen niet.
- A3. **Gemiddelde betaalde prijs** 60–70 % van de lijstprijs over 24 maanden: lanceringskorting ± 10–15 %, daarna seizoensuitverkopen (± 25–50 %), en regionale prijzen (± 20–25 % lager dan de dollarprijs volgens [Steam Page Analyzer, 2026-11-02](https://www.steampageanalyzer.com/blog/steam-revenue-share-explained); geen Valve-cijfer). Het percentage is mijn aanname, niet gemeten.
- A4. **Btw.** Steam-prijzen zijn inclusief btw waar Valve die int, en Valve draagt die af; het aandeel wordt berekend op de netto-omzet ná belastingen en terugbetalingen ([Steamworks Tax FAQ](https://partner.steamgames.com/doc/finance/taxfaq), gelezen 2026-11-10). Gemiddeld 12 % is een mengaanname: EU 19–25 % zit in de prijs, Amerikaanse sales tax niet.
- A5. **Terugbetalingen** 10 % (indie-bandbreedte 10–15 %, Steam Page Analyzer; geen Valve-cijfer).
- A6. **Steam-aandeel** 30 % (25 % pas boven $10 M bruto, [Valve 2018](https://steamcommunity.com/groups/steamworks/announcements/detail/1697191267930157838)).
- A7. **Boxleiter-ratio** 20–40× voor nieuwe releases, 25–35× gebruikt voor de omrekening naar reviews (§3).
- A8. **Wishlists → verkoop.** *Haiku* verkocht in zes weken ± 40 % van zijn launch-wishlists (15K / 37K, §3). Voor *Midden* zijn bij de launch ruwweg 15.000–25.000 wishlists nodig; dat is input voor D7 (tractieplan), geen doel dat hier vastligt.
- A9. **Geen co-op-bonus en geen NL-bonus** in de aantallen (§2.2).
- A10. **Eén release, geen early access**; de 24 maanden lopen vanaf de releasedatum, welke dat ook wordt (werkaanname §6).

## 5. Risico's voor de raming

| # | Risico | Effect | Wat helpt |
|---|---|---|---|
| R1 | **Boxleiter is grof**: per game kan de ratio 2–3× afwijken | Alle schattingen in §3 kunnen een factor 2 fout zijn | Altijd bandbreedtes; waar een bevestigd cijfer bestaat (*Haiku*), dat voorrang geven |
| R2 | **Overlevingsbias**: de vergelijkbare titels zijn bekend omdat ze slaagden | *Midden* en *Hoog* te optimistisch | *Laag* is geen worst case: het ligt al onder de mediaan van $15–20 (174 reviews), en de echte bodem zit niet in de scenario's: de genremediaan over alle prijzen is 22 reviews, ≈ 450–900 kopieën (20–40×) |
| R3 | **Late wishlist-opbouw**: geen publieke pagina in fase 2 (#24, 3A) | Minder wishlists bij de launch → richting *Laag* | Steam-pagina zo vroeg als de merkcheck toelaat (CEO-besluit, D7) |
| R4 | **Geen uitgever, geen marketingbudget** (#2, fase 2 € 0) | Minder zichtbaarheid dan *MIO* of *Constance* | Next Fest, festivals, pers; budget per fase via de EP |
| R5 | **Groeiende concurrentie**: ± 290 metroidvania's in 2025, +9 % in 2026 | Moeilijker op te vallen | De eigen draai (echo, licht, Lage Landen) zichtbaar in één GIF |
| R6 | **Co-op niet bewezen** als verkoopargument | Geen extra verkoop uit het bankduo | Niet meegeteld (A9); toetsen in playtests en bij de Steam-pagina |
| R7 | **AI-gemaakte content**: Steam vraagt een melding van AI-gebruik op de winkelpagina (Valve-beleid sinds januari 2024; voor dit document niet opnieuw gecontroleerd) | Mogelijk negatieve reactie van een deel van het publiek; effect op verkoop *niet bevestigd* | Eerlijk melden; BLA en CEO bepalen de tekst |
| R8 | **Steam Deck**: Deck-verkopen dalen sinds mei 2026 | Minder groei via handhelds | Deck verified blijft een voorwaarde, geen motor |
| R9 | **Prijs en kortingen** wijken af van A3 | ± 10–15 % netto verschil | Kortingsbeleid vastleggen vóór de launch |

## 6. Werkaanname (kader §5)

Dit document gebruikt de werkaanname uit `docs/beslissingen.md`: **totaalbudget en releasevenster volgen per fase**. Daarom staat hier geen releasedatum; de raming telt 24 maanden vanaf de release, wanneer die ook komt. Verder geldt: prijs ± € 20 zonder microtransacties of DLC (#2), alleen pc/Steam met Deck verified als doel (#2), Engels en in principe Nederlands bij release (#51, 5A), fase 2 € 0 extern en geen publieke uiting vóór de formele merkcheck (#24, 3A). De werktitel is *Polderlight* (#96).

## 7. Open punten

- O1. **Steam-reviewtellingen rechtstreeks van Steam**: ik kon de winkelpagina's niet lezen en gebruikte SteamSpy en Steam Page Analyzer. Iemand met een browser kan de tellingen in §3 bevestigen (bv. de BLA bij het afwerken van het dossier). De schattingen veranderen daardoor naar verwachting omhoog, niet omlaag.
- O2. **Bewijs voor het bankduo**: geen cijfers over co-op-spelers in het genre. Toetsen via playtests (fase 2) en later via de Steam-pagina (D7).
- O3. **Vlaamse/Nederlandse referentie in het genre**: niet gevonden. Vraag voor de intake (via de BLA): kent het VAF gesteunde metroidvania's of 2D-actiegames met verkoopcijfers?
- O4. **Netto naar het financieringsplan**: de EP kiest in F6/D10 welk scenario het financieringsplan gebruikt (mijn advies: *Midden*) en hoe de verkoop zich verhoudt tot het budget van fase 3.
- O5. **Tractie (D7)** en **pitchvideo (D13)**: buiten dit document; na de slice en een CEO-besluit over een Steam-pagina. A8 geeft de orde van grootte van de wishlists die *Midden* vraagt.
- O6. **Herzien** zodra er een Steam-pagina en wishlists zijn: dan vervangt de wishlist-methode (A8) de vergelijkbare titels als hoofdbron.

## 8. Logboek wijzigingen

- 2026-11-10 · v0.1 · eerste versie (D6, D8) voor #72.
