# Pitch: *Echoborn* (werktitel)

Versie 0.1 · Eigenaar: Creative Director · Issue: #4 · Status: ter review (Executive Producer)
Gebaseerd op `docs/beslissingen.md` (stand 2026-11-08). Waar dit document iets aanneemt dat nog geen CEO-besluit is, staat dat erbij.

---

## 1. De draai in één zin

> **Je schaduw herhaalt je laatste 10 seconden, dus elke kamer los je op met twee lichamen: jij nu, en jij van zonet.**

Dat is de hele game. Alles hieronder is een uitwerking van die zin.

## 2. Logline

*Echoborn* is een duistere 2D/2.5D-metroidvania waarin je schaduw je laatste 10 seconden naspeelt in een wereld van licht en schaduw. Alleen speel je samen met je eigen verleden; op de bank neemt een vriend je schaduw over.

**Engelse variant (voor store en pitchdeck, nog af te stemmen met Marketing):**
*Your shadow replays your last ten seconds. Alone, you team up with your past. Together, a friend takes the shadow's place.*

## 3. Kernfantasie

**"Ik ben mijn eigen bondgenoot."**

De speler moet zich slim voelen *vooruit*: niet "ik reageerde snel", maar "ik had dit tien seconden geleden al geregeld". Je zet een hendel om, rent door, en tien seconden later houdt je schaduw die deur voor je open. Je slaat een vijand, ontwijkt, en je schaduw slaat hem op exact dezelfde plek een tweede keer. Wat je doet, komt terug. Het moment waarop het klikt, is het moment waarop je niet meer speelt voor nu, maar voor straks.

In co-op verschuift de fantasie naar **"wij zijn één wezen in twee lagen"**: de ene speler leeft in het licht, de andere in de schaduw, en geen van beiden komt verder zonder de ander.

### Wat de speler doet (speelbaar, niet alleen verhalend)

| Moment | Solo | Co-op |
|---|---|---|
| Verkennen | Je route van zonet wordt een pad: de echo staat op schaduwplatforms, activeert schaduwschakelaars, draagt licht naar plekken waar jij net was. | Speler 2 loopt als schaduw vooruit in de schaduwlaag en opent de weg; speler 1 houdt hem in leven door het licht te sturen. |
| Puzzels | Plannen: je voert een reeks uit die pas in de herhaling klopt. Opnieuw proberen is goedkoop: wacht 10 seconden en je schaduw is "leeg". | Communiceren: dezelfde kamer, maar nu live afstemmen in plaats van vooruit plannen. |
| Gevechten | Je legt aanvallen klaar voor straks: een slag nu is een tweede slag over 10 seconden. Bosses lezen ook je echo. | Twee aanvallers in twee lagen; sommige vijanden zijn alleen in de schaduw te raken. |
| Groei (metroidvania-abilities) | Nieuwe vaardigheden zijn vooral nieuwe dingen die de echo kan: dragen, vasthouden, licht absorberen, de herhaling laten "ankeren". | Dezelfde vaardigheden; de schaduwspeler krijgt ze tegelijk. |

De precieze regels (wat wordt opgenomen, wanneer start en stopt de opname, wat de echo wel en niet kan) zijn van de Lead Game Designer (#6). De voorbeelden hierboven zijn richting, geen specificatie.

## 4. Drie design pillars

Elke pillar heeft een **toetsvraag**. Een feature die op een pillar "nee" scoort, gaat niet in de kern van de game, of er moet een bewuste uitzondering voor worden genoemd. Een wijziging van deze pillars vraagt een CEO-besluit.

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

**Toetsvraag:** *Kan een speler in één oogopslag zien in welke laag dit hoort, en loopt de gating via licht, schaduw of de echo?*

| Past | Past niet |
|---|---|
| Een lichtbron verplaatsen zodat er een schaduwbrug ontstaat waar de echo over kan | Een gekleurde deur die opengaat met een gekleurde sleutel |
| Een gebied dat zo fel verlicht is dat de echo er oplost, tot je de ability hebt om licht te dempen | Een obstakel dat in beide lagen hetzelfde werkt en geen reden heeft om in een laag te staan |
| Vijanden die alleen in de schaduwlaag zichtbaar zijn | Een kaart-icoon dat moet uitleggen wat de art niet laat zien |

Gevolg voor Art en Audio: leesbaarheid van de lagen gaat vóór sfeer. De Art Director toetst de stijltests (#7) ook aan deze pillar.

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

**Solo.** Je speelt één personage. Je schaduw volgt je met 10 seconden vertraging en doet precies wat jij deed: zelfde route, zelfde aanvallen, zelfde interacties, maar in de schaduwlaag. Het spel draait om vooruitdenken: wat jij nu doet, is wat je bondgenoot straks doet. Mislukt het, dan wacht je even en begint een nieuwe herhaling. De echo is daarmee tegelijk hulpmiddel, puzzelstuk en wapen.

**Co-op (lokaal, gedeelde camera, drop-in/drop-out).** Speler 2 neemt de schaduw over en bestuurt hem live. De schaduw houdt de regels van de echo: hij leeft in de schaduwlaag, kan dingen die het lichtpersonage niet kan (en omgekeerd), en lost op in fel licht. Wat solo een geplande reeks is, wordt in co-op een gesprek op de bank: "wacht, ik sta op de brug, zet het licht nu om." Stapt speler 2 uit, dan neemt de echo het naadloos weer over.

**Waarom dit werkt voor de doelgroep:** de solo-speler krijgt een denk-metroidvania met een eigen identiteit; het koppel of de vrienden op de bank krijgen een spel waarin de minder ervaren speler een echte rol heeft (de schaduwspeler kan niet "doodgaan" op dezelfde manier als het lichtpersonage; zie open vraag 3).

## 6. Toon

**Duister maar niet gruwelijk; melancholisch, niet wanhopig.** (Werkaanname PEGI 12–16, nog geen besluit.)

- **Thema:** je verleden kun je niet terugdraaien, maar je kunt er wel mee samenwerken. De echo is letterlijk wat je net deed; de wereld is gebouwd door mensen die dat niet konden.
- **Gevoel:** stilte, verlaten plekken, licht als iets kostbaars. Momenten van warmte (een lichtbron die weer aangaat, de schaduw die je hand vasthoudt bij een checkpoint) wegen zwaarder omdat de rest donker is.
- **Geweld:** gestileerd, geen bloed of lichamelijk detail. Vijanden lossen op in licht of schaduw.
- **Humor:** zuinig en droog, vooral via de echo (je schaduw herhaalt ook je mislukte sprong, trouw en een beetje gênant).
- **Niet:** grimdark, horror-jumpscares, ironische knipogen naar de speler, ellenlange lore-dumps.

De verhaal-invulling (wie ben je, waarom heb je een echo, wat gebeurde er met de wereld) is aan de Narrative Designer; die werkt binnen dit thema en wordt door mij gereviewd.

## 7. Referenties

| Referentie | Wat we nemen | Wat we niet nemen |
|---|---|---|
| *Super Metroid* (1994) | Wereldstructuur, abilities als sleutels, de wereld leest zichzelf | De eenzaamheid als enige modus |
| *Hollow Knight* (2017) | Precieze controls, sfeer, melancholie, bosses als hoogtepunt | De lengte en de straf bij doodgaan; wij zijn korter en vriendelijker |
| *Ori and the Blind Forest* / *Will of the Wisps* | Licht als thema en mechaniek, emotionele toon, vloeiende beweging | Het sentiment als hoofdmotor |
| *Braid* (2008) | Tijd als puzzelregel; de mechaniek *is* het thema | Puzzels die alleen in het hoofd zitten, zonder beweging |
| *The Talos Principle* (opname-puzzels) en flashgames als *The Company of Myself* / *Chronotron* | Samenwerken met een opname van jezelf als puzzelbasis | Statische puzzelkamers los van een wereld |
| *Contrast* (2013) | Schaduwen als speelbare laag naast de "echte" wereld | Een lineaire, korte structuur |
| *Limbo* / *Inside* | Leesbaar silhouet, duistere maar ingetogen toon | Gruwelijke sterfscènes |
| *It Takes Two* / *Unravel Two* | Co-op op de bank waarin beide spelers een eigen, onmisbare rol hebben | Losse minigames, co-op-only ontwerp |
| *Celeste* | Strakke 2D-controls, toegankelijkheidsopties die de uitdaging niet verraden | |

## 8. USP's

1. **Een metroidvania met een tweede lichaam.** Je echo is je partner, puzzelstuk en wapen tegelijk. *Aanname, te verifiëren door Business/Legal (#8):* we kennen geen metroidvania die een tijdvertraagde kopie van de speler als kern van verkenning, gevechten én gating gebruikt; wel puzzelgames en kortere titels met opnames van jezelf.
2. **Solo en co-op op precies dezelfde mechaniek.** Geen aparte modus: solo speel je met je verleden, samen speelt een vriend dat verleden live.
3. **Licht en schaduw als kaart.** De wereld laat zelf zien waar je heen kunt; gating zonder sleutels.
4. **Bank-co-op in een genre dat vooral solo is.** *Aanname:* lokale co-op is zeldzaam in metroidvania's van dit niveau, terwijl de doelgroep (koppels, vrienden) er wel om vraagt. Marktonderbouwing volgt van Marketing.
5. **Behapbaar en vriendelijk:** 10–14 uur, ongeveer €20 (werkaannames), toegankelijk voor een minder ervaren co-op-partner.

## 9. Doelgroep

Leeftijd 18–30, pc (Steam, Steam Deck als doel). Twee kernspelers:

| Speler | Wie | Wat ze zoeken | Wat ze in *Echoborn* vinden |
|---|---|---|---|
| **De genrefan** | Speelde *Hollow Knight*, *Ori*, *Dead Cells*; speelt vooral solo, kijkt naar sfeer en controls | Een metroidvania met een eigen idee, strak gevoel, sterke bosses | Een draai die het genre echt verandert, in een kortere game dan de grote titels |
| **Het bankduo** | Koppel of vrienden, vaak één ervaren en één minder ervaren speler | Iets dat ze samen kunnen spelen waarin allebei iets te doen hebben | De schaduwrol: onmisbaar, maar vergevingsgezinder; drop-in/drop-out op Steam Deck of pc aan de tv |

*Aanname, nog niet onderbouwd:* het bankduo is groot genoeg om co-op als tweede verkoopargument te dragen. Marketing kan dit toetsen.

## 10. Risico's voor de visie

| Risico | Waarom het de visie raakt | Wie | Voorstel |
|---|---|---|---|
| 10 seconden voelt te lang of te kort | De hele draai hangt aan die ene waarde | Lead Game Designer, Technical Director (spike #5) | Prototypen met 6, 10 en 14 seconden; afwijken van 10 is een CEO-besluit |
| Co-op is te makkelijk, omdat een live speler alles kan wat de echo kan | Pillar 3 breekt als co-op de puzzels triviaal maakt | Lead Game Designer | Schaduwspeler houdt de beperkingen van de echo (laag, licht); playtesten in beide modi vanaf het eerste prototype |
| Lagen zijn niet leesbaar, zeker in 2.5D | Pillar 2 valt dan om | Art Director (#7) | Leesbaarheid als harde eis in de stijltests |
| Te veel denkwerk, te weinig flow | Een metroidvania moet ook lekker lopen | Lead Game Designer, Combat Designer | Echo moet ook "gratis" helpen tijdens normaal spel, niet alleen in puzzelkamers |
| Het idee lijkt sterk op een bestaande game | Raakt USP 1 | Business/Legal (#8) | Uitkomst naamcheck afwachten; zo nodig USP-tekst aanpassen |

## 11. Open vragen

1. **Wat gebeurt er met de echo als speler 2 meedoet?** Mijn richting: speler 2 *wordt* de echo (geen derde lichaam). Uitwerking: Lead Game Designer (#6).
2. **Ankeren:** mag de speler later in de game de herhaling vastzetten of inkorten? Past bij pillar 1, maar mag de 10-secondenregel niet uithollen. Lead Game Designer.
3. **Falen in co-op:** kan de schaduwspeler doodgaan, of "lost hij alleen op" en keert hij terug? Mijn richting: vergevingsgezinder dan het lichtpersonage. Lead Game Designer en UX Designer.
4. **Titel:** *Echoborn* blijft werktitel tot de naamcheck (#8).

Geen van deze vragen raakt de pillars of de kernfantasie; ik beslis ze binnen de pillars samen met de vakrollen. Als een uitkomst een pillar zou veranderen, gaat het als `ceo-beslissing` naar de CEO.

## 12. Definition of Done (#4)

- [x] De draai is in één zin uit te leggen (§1)
- [x] Pillars zijn toetsbaar: toetsvraag plus past/past-niet per pillar (§4)
- [x] Solo en co-op zijn allebei beschreven (§3, §5)
- [x] Logline, kernfantasie, referenties, USP's, doelgroep en toon aanwezig (§2, §3, §6–§9)
