# Pitch: *Echoborn* (werktitel)

Versie 0.2 · Eigenaar: Creative Director · Issue: #15 (v0.1: #4, PR #11) · Status: v0.1 goedgekeurd (fase 1), bevestiging door de CEO in het gate-besluit (#10); v0.2 ter review (Executive Producer)
Gebaseerd op `docs/beslissingen.md` (stand 2026-11-08: randvoorwaarden #2, stijl 2D #18). Waar dit document iets aanneemt dat nog geen CEO-besluit is, staat dat erbij.

---

## 1. De draai in één zin

> **Je schaduw herhaalt je laatste 10 seconden, dus elke kamer los je op met twee lichamen: jij nu, en jij van zonet.**

Dat is de hele game. Alles hieronder is een uitwerking van die zin.

## 2. Logline

*Echoborn* is een duistere 2D-metroidvania waarin je schaduw je laatste 10 seconden naspeelt, zodat je alleen samenwerkt met je eigen verleden en samen op de bank een vriend die schaduw live bestuurt.

**Engelse variant (voor store en pitchdeck, nog af te stemmen met Marketing; de game verschijnt bij launch alleen in het Engels):**
*Your shadow replays your last ten seconds: alone, you team up with your past; together, a friend becomes the shadow.*

## 3. Kernfantasie

**"Ik ben mijn eigen bondgenoot."**

De speler moet zich slim voelen *vooruit*: niet "ik reageerde snel", maar "ik had dit tien seconden geleden al geregeld". Je zet een hendel om, rent door, en tien seconden later houdt je schaduw die deur voor je open. Je slaat een vijand, ontwijkt, en je schaduw slaat hem op exact dezelfde plek een tweede keer. Wat je doet, komt terug. Het moment waarop het klikt, is het moment waarop je niet meer speelt voor nu, maar voor straks.

In co-op verschuift de fantasie naar **"wij zijn één wezen in twee lagen"**: de ene speler leeft in het licht, de andere in de schaduw, en geen van beiden komt verder zonder de ander.

### Wat de speler doet (speelbaar, niet alleen verhalend)

| Moment | Solo | Co-op |
|---|---|---|
| Verkennen | Je route van zonet wordt een pad: de echo loopt over schaduwbruggen, activeert schaduwschakelaars, draagt licht naar plekken waar jij net was. | Speler 2 loopt als schaduw vooruit in de schaduwlaag en opent de weg; speler 1 houdt hem in leven door het licht te sturen. |
| Puzzels | Plannen: je voert een reeks uit die pas in de herhaling klopt. Opnieuw proberen is goedkoop: laat de echo los of wacht 10 seconden en je schaduw is "leeg". | Afstemmen: dezelfde kamer, maar nu live overleggen in plaats van vooruit plannen. |
| Gevechten | Je legt aanvallen klaar voor straks: een slag nu is een tweede slag over 10 seconden. Bosses lezen ook je echo. | Twee aanvallers in twee lagen; sommige vijanden zijn alleen in de schaduw te raken. |
| Groei (metroidvania-abilities) | Nieuwe vaardigheden zijn vooral nieuwe dingen die de echo kan: dragen, licht dempen, de herhaling "ankeren". | Dezelfde vaardigheden; de schaduwspeler krijgt ze tegelijk. |

De precieze regels (wat wordt opgenomen, wanneer de opname start en stopt, wat de echo wel en niet kan) zijn van de Lead Game Designer: `docs/design/gdd.md` en `docs/design/kernloop.md` (#6, PR #16). De voorbeelden hierboven zijn richting, geen specificatie.

## 4. Drie design pillars

Elke pillar heeft **één toetsvraag**. Een feature die op een pillar "nee" scoort, gaat niet in de kern van de game, of er moet een bewuste uitzondering voor worden genoemd. Een wijziging van deze pillars vraagt een CEO-besluit.

### Pillar 1: De echo is je tweede lichaam

De echo is geen effect, geen herinnering en geen spoor, maar een volwaardig tweede lichaam met gewicht in de wereld. De kritieke route (gates, bosses, verplichte puzzels) leunt op de echo.

**Toetsvraag:** *Gebruikt of versterkt deze feature wat de echo kan, of maakt hij de echo overbodig?*

| Past | Past niet |
|---|---|
| Een ability waarmee de echo een voorwerp draagt dat jij hebt opgepakt | Een standaard dubbele sprong die echo-platforms overbodig maakt |
| Een boss die zijn aanval richt op waar je 10 seconden geleden stond | Een boss die je met pure reflexen kunt verslaan zonder de echo ooit te gebruiken |
| Een vijand die je alleen raakt als jij en je echo hem tegelijk raken | Een sleutel-en-deur-systeem los van de echo |
| Een kamer waarin je moet kiezen wat je echo straks gaat herhalen | Een "slow motion"-power die de tijdsdruk van de herhaling weghaalt |

Uitzondering die mag: basisbeweging (lopen, springen, slaan) bestaat zonder echo, maar elke basisactie moet ook iets betekenen *als de echo hem herhaalt*.

### Pillar 2: Licht en schaduw zijn de kaart

De wereld heeft twee lagen. Jij leeft in het licht, de echo in de schaduw. Waar je kunt komen, lees je af aan hoe het licht valt. Gating, navigatie en gevaar lopen via die twee lagen, niet via gekleurde deuren of sleutels.

**Toetsvraag:** *Loopt de gating of het gevaar van deze feature via licht, schaduw of de echo?*

**Leesbaarheidseis (voor Art, geen tweede toetsvraag):** alles wat via pillar 2 werkt, laat in het beeld zelf zien in welke laag het hoort, zonder icoon of uitleg. De Art Director legt vast hoe (art bible); de basis staat al in de stijltests (`docs/art/stijltests.md`): een harde rand tussen licht en schaduw, en *vol = levend, hol = echo*.

| Past | Past niet |
|---|---|
| Een lichtbron verplaatsen zodat er een schaduwbrug ontstaat waar de echo over kan | Een gekleurde deur die opengaat met een gekleurde sleutel |
| Een gebied dat zo fel verlicht is dat de echo er oplost, tot je de ability hebt om licht te dempen | Een obstakel dat in beide lagen hetzelfde werkt en geen reden heeft om in een laag te staan |
| Vijanden die alleen in de schaduwlaag zichtbaar zijn | Een vaardigheidspoort die alleen een slot-icoon toont, zonder dat licht, schaduw of echo de reden is |

Gevolg voor Art en Audio: leesbaarheid van de lagen gaat vóór sfeer.

### Pillar 3: Eén mechaniek, twee manieren van samenspelen

Solo en co-op zijn dezelfde game in dezelfde kamers met dezelfde regels. Solo is samenwerken met je verleden (plannen); co-op is samenwerken met een ander (afstemmen). Er is geen aparte co-op-campagne en geen solo-versie van een kamer.

**Toetsvraag:** *Werkt dit zowel met de 10-secondenecho (solo) als met een live gespeelde schaduw (co-op), zonder aparte versie?*

| Past | Past niet |
|---|---|
| Een puzzel die solo een geplande reeks vraagt en in co-op live afstemmen | Een puzzel die alleen met twee echte spelers op te lossen is (op de kritieke route) |
| Drop-in/drop-out: speler 2 neemt de echo over of geeft hem terug, zonder kamer-reset | Een co-op-modus met een eigen wereld, eigen levels of eigen progressie |
| Een gedeelde camera die beide lagen in beeld houdt | Split-screen (botst met gedeelde camera en lokale co-op) |
| Een boss die in co-op anders voelt maar dezelfde regels volgt | Content achter een co-op-only gate |

## 5. Solo en co-op, uitgeschreven

**Solo.** Je speelt één personage. Je schaduw volgt je met 10 seconden vertraging en doet precies wat jij deed: zelfde route, zelfde aanvallen, zelfde interacties, maar in de schaduwlaag. Het spel draait om vooruitdenken: wat jij nu doet, is wat je bondgenoot straks doet. Mislukt het, dan laat je de echo los of wacht je even, en begint een nieuwe herhaling. De echo is daarmee tegelijk hulpmiddel, puzzelstuk en wapen.

**Co-op (lokaal, gedeelde camera, drop-in/drop-out).** Speler 2 neemt de schaduw over en bestuurt hem live. Er is dan geen opgenomen echo meer: speler 2 *is* de echo. De schaduw houdt de regels van de echo: hij leeft in de schaduwlaag, kan dingen die het lichtpersonage niet kan (en omgekeerd), en lost op in fel licht. Wat solo een geplande reeks is, wordt in co-op een gesprek op de bank: "wacht, ik sta op de brug, zet het licht nu om." Stapt speler 2 uit, dan neemt de echo het weer over zonder kamer-reset, zodra er 10 seconden van speler 1 zijn opgenomen. Tot dan is de schaduw even leeg; er wordt niets verzonnen om dat gat te vullen (randgeval, uitgewerkt door de LGD in `gdd.md` C-05).

**Waarom dit werkt voor de doelgroep:** de solo-speler krijgt een denk-metroidvania met een eigen identiteit; het koppel of de vrienden op de bank krijgen een spel waarin de minder ervaren speler een echte rol heeft (de schaduwspeler gaat niet dood, maar lost op en komt na een paar tellen terug naast speler 1).

## 6. Toon en beeld

**Duister maar niet gruwelijk; melancholisch, niet wanhopig.** Doel: **PEGI 12** (CEO-besluit #2).

- **Thema:** je verleden kun je niet terugdraaien, maar je kunt er wel mee samenwerken. De echo is letterlijk wat je net deed; de wereld is gebouwd door mensen die dat niet konden.
- **Gevoel:** stilte, verlaten plekken, licht als iets kostbaars. Momenten van warmte (een lichtbron die weer aangaat, de schaduw die je hand vasthoudt bij een checkpoint) wegen zwaarder omdat de rest donker is.
- **Geweld (PEGI 12):** gestileerd, geen bloed of lichamelijk detail. Vijanden lossen op in licht of schaduw; ook de echo "breekt" in schaduwdeeltjes, niet in een sterfscène.
- **Humor:** zuinig en droog, vooral via de echo (je schaduw herhaalt ook je mislukte sprong, trouw en een beetje gênant).
- **Niet:** grimdark, horror-jumpscares, ironische knipogen naar de speler, ellenlange lore-dumps.

**Beeld: 2D** (CEO-besluit #18). Pixel art op 640×360 (op de Steam Deck 640×400), met dynamisch 2D-licht in harde banden. Waarom dat bij de visie past:
- **De laaggrens is gameplay.** Een harde rand laat op de pixel zien waar de schaduwbrug ophoudt (pillar 2).
- **Vol = levend, hol = echo.** Speler 1, speler 2 en de echo zijn op elke achtergrond uit elkaar te houden (pillar 1 en 3).
- **Sfeer zonder de leesbaarheid te raken:** volumetrisch licht en diepte alleen in de achtergrond en de parallax-lagen; het speelvlak blijft strak.

De verhaal-invulling (wie ben je, waarom heb je een echo, wat gebeurde er met de wereld) is aan de Narrative Designer; die werkt binnen dit thema en wordt door mij gereviewd. Alle tekst in de game is bij launch Engels (besluit #2); schrijf zuinig, zodat de wereld meer vertelt dan de tekst.

## 7. Referenties

| Referentie | Wat we nemen | Wat we niet nemen |
|---|---|---|
| *Super Metroid* (1994) | Wereldstructuur, abilities als sleutels, de wereld leest zichzelf | De eenzaamheid als enige modus |
| *Hollow Knight* (2017) | Precieze controls, sfeer, melancholie, bosses als hoogtepunt | De lengte en de straf bij doodgaan; wij zijn korter (5–7 uur) en vriendelijker |
| *Ori and the Blind Forest* / *Will of the Wisps* | Licht als thema en mechaniek, emotionele toon, vloeiende beweging | Het sentiment als hoofdmotor |
| *Braid* (2008) | Tijd als puzzelregel; de mechaniek *is* het thema | Puzzels die alleen in het hoofd zitten, zonder beweging |
| *The Talos Principle* (opname-puzzels) en flashgames als *The Company of Myself* / *Chronotron* | Samenwerken met een opname van jezelf als puzzelbasis | Statische puzzelkamers los van een wereld |
| *Contrast* (2013) | Schaduwen als speelbare laag naast de "echte" wereld | Een lineaire structuur zonder terugkeren |
| *Limbo* / *Inside* | Leesbaar silhouet, duistere maar ingetogen toon | Gruwelijke sterfscènes |
| *It Takes Two* / *Unravel Two* | Co-op op de bank waarin beide spelers een eigen, onmisbare rol hebben | Losse minigames, co-op-only ontwerp |
| *Celeste* (2018) | Strakke 2D-controls in pixel art, toegankelijkheidsopties die de uitdaging niet verraden, snel opnieuw proberen | De lineaire hoofdstukstructuur en precisie-platforming als hoofdzaak; bij ons draagt het plannen met de echo, niet de millimetersprong |

## 8. USP's

1. **Een metroidvania met een tweede lichaam.** Je echo is je partner, puzzelstuk en wapen tegelijk. *Aanname, te verifiëren door Business/Legal (#8):* we kennen geen metroidvania die een tijdvertraagde kopie van de speler als kern van verkenning, gevechten én gating gebruikt; wel puzzelgames en kortere titels met opnames van jezelf.
2. **Solo en co-op op precies dezelfde mechaniek.** Geen aparte modus: solo speel je met je verleden, samen speelt een vriend dat verleden live.
3. **Licht en schaduw als kaart.** De wereld laat zelf zien waar je heen kunt; gating zonder sleutels.
4. **Bank-co-op in een genre dat vooral solo is.** *Aanname:* lokale co-op is zeldzaam in metroidvania's van dit niveau, terwijl de doelgroep (koppels, vrienden) er wel om vraagt. Marktonderbouwing volgt van Marketing.
5. **Behapbaar en vriendelijk:** 5–7 uur, 3–4 gebieden, 4–5 bosses, ongeveer €20 eenmalig zonder microtransacties (CEO-besluit #2). Uit te spelen in een paar avonden met z'n tweeën, toegankelijk voor een minder ervaren co-op-partner.

## 9. Doelgroep en bereik

Leeftijd 18–30, pc via Steam, Steam Deck verified als doel. Alleen Engels bij launch (CEO-besluit #2). Twee kernspelers:

| Speler | Wie | Wat ze zoeken | Wat ze in *Echoborn* vinden |
|---|---|---|---|
| **De genrefan** | Speelde *Hollow Knight*, *Ori*, *Dead Cells*; speelt vooral solo, kijkt naar sfeer en controls | Een metroidvania met een eigen idee, strak gevoel, sterke bosses | Een draai die het genre echt verandert, in een kortere game dan de grote titels; solo ook op de Steam Deck |
| **Het bankduo** | Koppel of vrienden, vaak één ervaren en één minder ervaren speler | Iets dat ze samen kunnen spelen waarin allebei iets te doen hebben | De schaduwrol: onmisbaar, maar vergevingsgezinder; drop-in/drop-out op **pc aan de tv** met twee controllers |

**Co-op-situatie:** de hoofdsituatie voor co-op is **pc aan de tv**. Co-op op één Steam Deck-scherm met een gedeelde camera is krap; dat claimen we niet tot de UX Designer en de Technical Director het getoetst hebben. Tot dan noemt Marketing de Deck alleen voor solo.

*Aanname, nog niet onderbouwd:* het bankduo is groot genoeg om co-op als tweede verkoopargument te dragen. Marketing kan dit toetsen.

## 10. Risico's voor de visie

| Risico | Waarom het de visie raakt | Wie | Voorstel |
|---|---|---|---|
| 10 seconden voelt te lang of te kort | De hele draai hangt aan die ene waarde | Lead Game Designer, Technical Director | Prototypen met 6, 10 en 14 seconden (gdd §5, vraag 1); afwijken van 10 is een CEO-besluit |
| De echo is te vaak "leeg" | Na elke reset (bv. kamerwissel) is de echo 10 s weg; bij veel korte kamers is het tweede lichaam dan vaak afwezig (pillar 1, en het risico "te weinig flow") | Lead Game Designer | Meten in de playtest hoeveel tijd de echo leeg is tijdens gewoon verkennen; zo nodig de reset bij een kamerwissel beperken |
| Co-op is te makkelijk, omdat een live speler alles kan wat de echo kan | Pillar 3 breekt als co-op de puzzels triviaal maakt | Lead Game Designer | Schaduwspeler houdt de beperkingen van de echo (laag, licht, in beeld blijven); playtesten in beide modi vanaf het eerste prototype |
| Lagen en objectsoorten zijn niet leesbaar | Pillar 2 valt dan om | Art Director | 2D is gekozen vanwege de harde laaggrens (#18). Nog open: hoe gedeelde, licht- en schaduwobjecten in één oogopslag te onderscheiden zijn (art bible), en de prestaties op de Steam Deck (Technical Artist, Engine & Platform Programmer) |
| Te veel denkwerk, te weinig flow | Een metroidvania moet ook lekker lopen | Lead Game Designer, Combat Designer | Echo moet ook "gratis" helpen tijdens normaal spel, niet alleen in puzzelkamers |
| 5–7 uur is kort voor een metroidvania | De echo moet binnen minuten dragen; er is geen ruimte voor een lange opbouw | Lead Game Designer, World & Level Designer | De echo zit vanaf de proloog in de kern; elke vaardigheid voegt iets toe aan wat de echo kan |
| Het idee lijkt sterk op een bestaande game | Raakt USP 1 | Business/Legal (#8) | Uitkomst naam- en ideecheck afwachten; zo nodig USP-tekst aanpassen |

## 11. Open vragen

| # | Vraag | Richting CD | Eigenaar | Stand |
|---|---|---|---|---|
| 1 | Wat gebeurt er met de echo als speler 2 meedoet? | Speler 2 *wordt* de echo (geen derde lichaam). | Lead Game Designer (#6) | Uitgewerkt in `gdd.md` C-01–C-05 (PR #16, nog niet gemergd); past binnen de pillars |
| 2 | **Ankeren:** mag de speler later de herhaling vastzetten? | Ja, als vaardigheid, maar het mag de 10-secondenregel niet uithollen en moet ook in co-op werken (pillar 3). | Lead Game Designer, Systems Designer | Richting in `gdd.md` §3; co-op nog open (O-3) |
| 3 | **Falen in co-op:** kan de schaduwspeler doodgaan? | Nee, hij lost op en keert terug; vergevingsgezinder dan het lichtpersonage. | Lead Game Designer, UX Designer | Uitgewerkt in `gdd.md` C-06 |
| 4 | **Titel:** blijft *Echoborn*? | Werktitel tot de naamcheck. | Business/Legal (#8) | Open |
| 5 | **Opnamemodel en de echo tussen de lagen:** herhaalt de echo je posities of je inputs? En hoe raakt een echo die in de schaduw leeft hendels en vijanden die jij in het licht raakte? | De echo is er altijd (geen opnameknop) en blijft in de schaduwlaag; wat hij in de wereld raakt, moet leesbaar per laag zijn. | Lead Game Designer (#6), Technical Director (#5) | Voorstel in `gdd.md` §2.2–2.5 (toestand opnemen, acties als events tegen de huidige wereld, objecten gedeeld/licht/schaduw), PR #16, nog niet gemergd |
| 6 | **Drop-out zonder 10 s buffer:** wat doet de echo als speler 2 stopt en er nog geen 10 s van speler 1 is opgenomen? | Niets verzinnen: liever even een lege schaduw dan een echo die iets doet wat jij niet deed. | Lead Game Designer (#6) | Voorstel in `gdd.md` C-05 |

Geen van deze vragen raakt de pillars of de kernfantasie; ik beslis ze binnen de pillars samen met de vakrollen. Als een uitkomst een pillar zou veranderen, gaat het als `ceo-beslissing` naar de CEO. Vragen 1, 3, 5 en 6 sluit ik zodra PR #16 gemergd is.

## 12. Definition of Done

**#4 (v0.1)**
- [x] De draai is in één zin uit te leggen (§1)
- [x] Pillars zijn toetsbaar: toetsvraag plus past/past-niet per pillar (§4)
- [x] Solo en co-op zijn allebei beschreven (§3, §5)
- [x] Logline, kernfantasie, referenties, USP's, doelgroep en toon aanwezig (§2, §3, §6–§9)

**#15 (v0.2)**
- [x] Logline is één zin (§2; exit-criterium E1)
- [x] Toetsvraag van pillar 2 is enkelvoudig; leesbaarheid is een aparte eis voor Art (§4)
- [x] Opnamemodel en de echo tussen de lagen staan als open vraag, met #6 en #5 als eigenaar (§11, vraag 5); drop-out zonder buffer als randgeval (§5, §11 vraag 6)
- [x] Steam Deck is niet de primaire co-op-situatie; pc aan de tv wel (§9)
- [x] Celeste-rij ingevuld; statusregel bijgewerkt (§7, kop)
- [x] In lijn met CEO-besluit #2: 5–7 uur, 3–4 gebieden, 4–5 bosses, PEGI 12, alleen Engels (§6, §8, §9)
- [x] In lijn met CEO-besluit #18: 2D (§2, §6, §10)

## 13. Wijzigingen

| Versie | Wat |
|---|---|
| 0.2 | Reviewpunten PR #11 verwerkt (logline één zin, pillar 2 enkelvoudig, open vragen 5–6, co-op op pc aan de tv, Celeste, status). Randvoorwaarden #2 doorgevoerd (5–7 uur, 3–4 gebieden, 4–5 bosses, PEGI 12, alleen Engels). Stijl 2D (#18) doorgevoerd, met "beeld" in §6. Open vragen als tabel met de stand van de uitwerking door de LGD (PR #16). Twee nieuwe visierisico's: echo te vaak leeg, korte speelduur. In pillar 2 is de past-niet-cel over het kaart-icoon vervangen door een gating-voorbeeld (het icoon valt nu onder de leesbaarheidseis). Pillars en kernfantasie zijn inhoudelijk ongewijzigd. |
| 0.1 | Eerste versie (#4, PR #11). |
