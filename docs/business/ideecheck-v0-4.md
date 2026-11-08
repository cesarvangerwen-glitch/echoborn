# Ideecheck pitch v0.4: schaduwmerk, springplank en co-op (R-V9)

Versie 1.0 · Business/Legal Advisor · peildatum 2026-11-08 · issue [#58](https://github.com/cesarvangerwen-glitch/echoborn/issues/58)
Basis: `docs/concept/pitch.md` v0.4 (§3, §4, §5, §10 R-V9, §12 E-02/E-14) en de eerdere check in `docs/business/naamcheck.md` §3.

> **Geen juridisch advies.** Ik ben geen advocaat. Een spelmechaniek als zodanig is in de regel niet auteursrechtelijk beschermd; wel de concrete uitwerking (code, art, tekst, naam, logo) en eventueel een octrooi op een technische uitvoering. Het risico hieronder is dus vooral **onderscheid en vindbaarheid**: lijkt het voor spelers en pers op een kopie? Bij twijfel over een octrooi beslist een specialist, niet dit document.

**Legenda.** Groen = gangbaar of duidelijk anders, niets doen. Oranje = herkenbaar dicht bij één titel, afwijken in de uitwerking. Rood = in de huidige vorm te dichtbij, eerst herontwerpen.

## 1. Oordeel per mechaniek

| # | Mechaniek (v0.4) | Naaste bestaande games | Juridisch | Onderscheid | Oordeel |
|---|---|---|---|---|---|
| M1 | **Schaduwmerk**: treffer = merk, meer merken = grotere ontploffing, de echo laat het knallen; **merksprong** (echo schiet naar het merk) | *Nine Sols*: pareren geeft Qi; met Qi doe je een uitval die een **talisman** op de vijand plakt; treffers stapelen **interne schade** (paars); de talisman **ontploft** als je de knop vasthoudt en zet alle interne schade om in echte schade [1][2][3][4]. *Anthem* (2019): primer + detonator, in co-op mag de een primen en de ander laten ontploffen [5] | Groen | **Oranje** | **Oranje** |
| M2 | **Echo als springplank** (± 2 s staart), bounce op je echo | *AfterImage* (2026): een "past self" dat je inputs herhaalt "and that you can stand on" [6]; *Me and My Shadow*: op het hoofd van je schaduw-opname staan (naamcheck §3.1) | Groen | Groen¹ | **Groen** |
| M3 | **Korte vertraagde kopie** van jezelf in een gevechtsgame | *Echo Shift*: tot drie opnames van je **15 s**, "no combat, no enemies", first-person puzzel, aangekondigd voor early access [7]. *Super Time Force*, *Echo Sequence* (naamcheck §3.1). Octrooi Nintendo US 9,616,342: ghost die de opgeslagen beweging van een **eerdere speelsessie** volgt in een 3D-wereld, status volgens Google actief tot ± 2035 [8] | Oranje (octrooiscan, §3) | Groen | **Oranje** |
| M4 | **Licht oppompen**: meter vullen door flow, bij een gemaal de stad in pompen, water zakt; wereld en echo eerst grijs | *Hollow Knight*: SOUL vullen door te slaan, uitgeven aan genezen en spreuken [9]; *Gris*: de wereld verliest kleur en krijgt die terug bij elke stap voortgang [10] | Groen | Groen | **Groen** |
| M5 | **Co-op "samen bewegen"**: bounce, lancering, merk-combo, vangen; solo dezelfde vier acties via de echo | Op het hoofd van je partner springen in de metroidvania's *Castlevania: Portrait of Ruin* en *Harmony of Despair* [11]; prime/detonate in co-op in *Anthem* [5]; afzetten van vijanden en projectielen (*Ori*, Bash) [12] | Groen | Groen (de solo-via-echo-spiegel vonden we nergens) | **Groen** |
| M6 | *Afterimage* als **naam** (Aurogon, 2023) | 2D-metroidvania zonder echo- of kloonmechaniek [13]; de puzzelgame *AfterImage* (2026) zie M2 | n.v.t. | Groen | **Groen**: gebruik "afterimage" niet als feature- of marketingwoord |

¹ Groen op voorwaarde dat de positionering klopt; zie §2, alinea M2.

## 2. Waarom M1 oranje is, en hoe we afwijken (voor Combat Designer en LGD, T3)

*Nine Sols* is onze **hoofdreferentie voor combat** (pitch §7) en zit in hetzelfde segment (2D-actieplatformer, Steam, genrefan). Spelers en pers leggen ons dus naast *Nine Sols*. Vier punten van v0.4 zitten er nu dicht bij: (1) een treffer zet een lading op de vijand, (2) **stapelen** maakt de ontploffing groter, (3) de **merksprong** lijkt op de uitval waarmee Yi zijn talisman plakt, en (4) als pareren ook merken oplevert, is de keten pareren → lading → ontploffing bijna dezelfde. Het verschil dat de pitch noemt (de echo laat het knallen, op jouw route van zonet) is echt, maar alleen zichtbaar als de uitwerking het benadrukt. **Voorstel, in volgorde van belang:**

1. **De ontsteker is altijd een tweede lichaam.** Geen eigen knop om te laten ontploffen, geen "vasthouden om te laden". Solo ontsteekt de echo, in co-op de partner. Dat is ook de kern van pillar 3.
2. **Maak het merk ruimtelijk, niet een opgespaarde balk.** Geen zichtbare voorraad schade die wordt "omgezet" (de paarse balk van *Nine Sols*). Het merk is een plek op de vijand of in de lucht; de **route van de echo is de lont**. Wie zo vecht dat zijn schaduw straks door de merken loopt, krijgt de ketting. Stapelen mag, maar beloon **ketting en positie** (meer merken op de lijn van de echo) in plaats van een teller per vijand.
3. **Koppel het merk niet aan pareren.** Merken komen uit gewone treffers (zoals de pitch nu zegt). Pareren levert iets anders op, bv. lichtmeter of een dash-reset. Dan is er geen keten pareren → lading → ontploffing.
4. **Merksprong (E-02): houd hem kort en lees hem als echo, niet als uitval.** Alleen binnen de bestaande straal, alleen op het moment van een opgenomen treffer, en visueel als een **schaduw die even uitrekt** naar het merk, niet als een dash met een voorwerp in de hand.
5. **Eigen beeld- en geluidstaal.** Geen papieren zegel, talisman of taoïstische symboliek. Het merk komt uit onze wereld: bv. een lichtvonk of een sluismerk, met de aftelling op het carillon (pitch R-V1). Ontploffing = licht en schaduw plus licht voor de meter (pitch §6), een effect dat *Nine Sols* niet heeft.
6. **Communicatie** (Marketing, CD): schrijf "geïnspireerd door het tempo van *Nine Sols*", nooit "het talisman-systeem van *Nine Sols* met een echo". Het onderscheid in één zin: *je schaduw laat je merken knallen, op de plek waar jij net sloeg.*

Met 1–3 gaat M1 naar **groen**; 4–6 houden het daar. Toets in de flow-kamer: beschrijven playtesters het merk spontaan als "net als *Nine Sols*"? Zo ja, terug naar punt 2.

**M2 (springplank).** Op je eigen opname staan is gemeengoed in puzzelgames (*AfterImage*, *Me and My Shadow*). Niets aan de mechaniek veranderen, wel de positionering: de springplank is een **beweging in vaart** (dash-reset, geen stilstand), geen platform dat je neerzet. Claim nooit "stand on your past self" als nieuw (sluit aan op naamcheck §3.4: "we vonden geen metroidvania die …", nooit "de eerste").

## 3. Octrooien

Het Nintendo-octrooi US 9,616,342 [8] beschrijft (claim 1) een ghost die bewegingsdata uit een **eerdere speelsessie** volgt en pas later in de sessie verschijnt, in een 3D-wereld met virtuele camera's. Onze echo is een **live vertraging van ± 2 s in dezelfde sessie, in 2D**. Dat lijkt op het eerste gezicht anders, maar een octrooi lees je op de volledige claims, en dat kan ik niet betrouwbaar. Voorstel: **neem een korte octrooiscan op "vertraagde kopie van de spelerfiguur" mee in de offerte voor de betaalde merkcheck** (besluit #51 deel 1, 3A), vóór de eerste publicatie. Geen blokkade voor T3 of de flow-kamer; met die scan gaat M3 naar groen.

**Open punt:** de octrooiscan bovenop de merkcheck kan de raming uit besluit #51 deel 1 (€ 3.750, worstcase ≈ € 4.800 excl. btw) overschrijden; de offerte prijst de scan apart, en een eventuele meerkost legt de EP voor vóór de opdracht. Voor *Nine Sols* (Red Candle Games) vond ik geen octrooi; dat is geen bewijs dat er geen is.

## 4. Conclusie

USP 1 blijft overeind en staat in v0.4 verder van *Echo Shift* en de puzzelgames af dan v0.3. Het enige echte aandachtspunt is het **schaduwmerk naast *Nine Sols***: oranje, op te lossen in de uitwerking (§2, punt 1–3) voordat T3 E-14 en de merksprong vastlegt. M3 is oranje alleen om de octrooiscan (§3), die niet blokkeert voor T3. Al het andere is groen.

## Bronnen (geraadpleegd 2026-11-08)

1. PC Gamer, *Nine Sols review* (2025-01-15): https://www.pcgamer.com/games/adventure/nine-sols-review/
2. Switchblade Gaming, *Nine Sols vs Sekiro: talisman tag system*: https://www.switchbladegaming.com/action-rpg/vs-sekiro-2/
3. *Nine Sols: how does internal damage work*: https://wittyza.pages.dev/posts/nine-sols-how-does-internal-damage-work
4. Steam, *Nine Sols* (RedCandleGames, 2024-05-28; "blow them up with the Taoist talisman"): https://store.steampowered.com/app/1809540
5. Anthem Wiki, *Detonators* ("A target primed by one lancer can be detonated by another"): https://anthem.fandom.com/wiki/Detonators
6. Steam, *AfterImage* (Wolf Studios, 2026-08-28): https://store.steampowered.com/app/5055440
7. Steam, *Echo Shift* (SnailReaper, aangekondigd voor early access: "Coming Soon To Early Access"): https://store.steampowered.com/app/4199420
8. Google Patents, US 9,616,342 B2 (Nintendo, ingediend 2014-05-23): https://patents.google.com/patent/US9616342
9. Hollow Knight Wiki, *Soul*: https://hollowknight.wiki/w/Soul
10. Thumbsticks, *Gris review*: https://www.thumbsticks.com/gris-review/
11. TV Tropes, *Goomba Springboard* (voorbeelden *Portrait of Ruin*, *Harmony of Despair*): https://www.tvtropes.org/pmwiki/pmwiki.php/Main/GoombaSpringboard
12. SDA Knowledge Base, *Ori: Skills and Abilities* (Bash): https://kb.speeddemosarchive.com/Ori/Skills_and_Abilities
13. Indie Games Devel, *Afterimage: 11 things you should know* (2023-04-25): https://indiegamesdevel.com/afterimage-11-things-you-should-know-before-playing

**Beperkingen.** Bronnen 2, 3, 11 en 13 zijn gidsen en wiki's, geen officiële bronnen; de kern over *Nine Sols* staat ook in [1] en [4]. *Devil May Cry 3* (stijl *Doppelganger*, een schaduwkopie van Dante) is mogelijk relevant voor M3, maar kon ik niet op een bron nakijken; niet meegeteld. Geen volledige octrooizoektocht (zie §3).
