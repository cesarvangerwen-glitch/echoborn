# Pitch: *Wraithstep* (werktitel)

Versie 0.4 · Eigenaar: Creative Director · Issue: #55 (neemt #43 mee; v0.3: #25, PR #41; v0.2: #15, PR #22; v0.1: #4, PR #11) · Status: v0.3 gemergd (PR #41); **v0.4 in interne review (Executive Producer, daarna Studio Manager)**. v0.4 verwerkt de live brainstorm met de CEO (#54) en vraagt een **nieuw conceptbesluit** (#51, vraag 1); tot dat besluit geldt v0.3 als laatst goedgekeurde versie.
Werktitel ***Wraithstep*** (besluit #24, voorheen *Echoborn*). Nog niet publiek gebruiken vóór de formele merkcheck door een specialist (besluit #24, 3A). Repo- en mapnamen blijven voorlopig "echoborn".
Gebaseerd op `docs/beslissingen.md` (stand 2026-11-08: randvoorwaarden #2, stijl 2D #18, werktitel #24, gate fase 1 deel 1 #51) en het brainstormverslag #54. Waar dit document iets aanneemt dat nog geen CEO-besluit is, staat dat erbij.

---

## 1. De draai in één zin

> **Je schaduw herhaalt wat je net deed en wordt zo je springplank en je tweede slag; de stad zelf herhaalt de laatste tien seconden van haar bewoners.**

**Echo-duur (CEO-vraag 8, aanbeveling A):** in het spel loopt de echo een **korte staart** van ± 2 s achter je (bereik van de LGD: 1,5–3 s). Alleen zo is hij een springplank zonder dat je moet wachten (§5). De **10 seconden** blijven het ritme van het verhaal en van de finisher: de bevroren echo's tonen de laatste 10 s van de bewoners, de sluiswachter krijgt aan het einde zijn eigen 10 s terug, en de co-op-finisher speelt jullie laatste 10 s af (§5, §6). Kiest de CEO 8B (10 s blijft de echo-duur), dan geldt de v0.4-zin "Je schaduw herhaalt je laatste 10 seconden: wat je net deed, wordt je springplank en je tweede slag", en moeten de levels de echo veel vaker vóór je leggen (§5, R-V12).

Dat is de hele game. In v0.3 was de echo vooral een puzzelstuk ("elke kamer los je op met twee lichamen"). Vanaf v0.4 is hij een **bondgenoot in beweging**: hij draagt je verder en slaat met je mee. Er staan geen puzzels op de kritieke route (§4, pillar 1).

## 2. Logline

*Wraithstep* is een melancholische 2D-metroidvania in een gedroomde, verzonken stad, waarin je schaduw herhaalt wat je net deed en zo je springplank en je tweede slag wordt.

**Engelse variant (werkversie voor store en pitchdeck, af te stemmen met Marketing):**
*A melancholy metroidvania in a drowned dream-city, where your shadow repeats what you just did and becomes your springboard and your second strike.*

## 3. Kernfantasie

**"Ik beweeg en vecht vloeiend, met een bondgenoot die ik zelf ben."**

Dit zijn de twee zinnen die de CEO van spelers wil horen (#54): *"het was heel satisfying"* en *"vloeiend met een bondgenoot"*. Het gevoel dat we zoeken is dat van *Hollow Knight* en *Nine Sols*: precieze besturing, gewicht in elke slag, en een ritme dat je in je handen voelt. De echo maakt dat ritme dubbel. Je springt van je eigen schaduw af en houdt je vaart. Je slaat een vijand, en een tel later slaat je schaduw daar nog eens, harder. Het slimme gevoel blijft, maar het komt in beweging: je kiest je route zo dat je schaduw straks onder je staat waar je hem nodig hebt.

### Wat de speler doet (speelbaar, niet alleen verhalend)

| Moment | Solo | Co-op (aanbeveling, zie §5 en CEO-vraag 7) |
|---|---|---|
| **Bewegen** | **Echo als springplank.** De echo loopt je route van zonet. Land je op hem of zet je je van hem af, dan houd je je snelheid en krijg je je dash terug. Een goede run is een ketting: sprong, dash, afzetten van je schaduw, verder. | Beide spelers zijn live en zijn elkaars springplank. De schaduwspeler blijft binnen de gedeelde camera (leiband, `gdd.md` C-07). |
| **Vechten** | **Schaduwmerk.** Elke treffer zet een merk op de vijand. Komt de echo bij die treffer aan, dan schiet hij naar het merk en laat het ontploffen. Meer merken betekent een grotere ontploffing. Pareren en ontwijken zijn van jou; de echo maakt je combo af. | Beide spelers zetten merken. De gedeelde echo laat alle merken van allebei in één finisher ontploffen. |
| **Licht oppompen** (kernloop) | Flow vult je **lichtmeter**: treffers, ontploffingen en sprongketens zonder de grond te raken. Bij een **gemaal** pomp je dat licht de stad in. Het water zakt, een wijk gaat aan, nieuwe routes gaan open. | Eén gedeelde meter die door allebei gevuld wordt. Oppompen doe je samen. |
| **Groei** (metroidvania-vaardigheden) | Elke vaardigheid is beweging of gevecht die de echo versterkt, bijvoorbeeld een dash die de echo herhaalt als snijlijn. Uitwerking door de LGD en de Systems Designer. | Dezelfde vaardigheden voor beide spelers. |

De precieze regels zijn van de Lead Game Designer (`docs/design/gdd.md`, `kernloop.md`). Wat er in die regels moet veranderen, staat in §12. De voorbeelden hierboven zijn richting, geen specificatie.

## 4. Drie design pillars

Elke pillar heeft **één toetsvraag**. Een feature die op een pillar "nee" scoort, gaat niet in de kern van de game, of er moet een bewuste uitzondering voor worden genoemd. Een wijziging van deze pillars vraagt een CEO-besluit; v0.4 wijzigt pillar 1 en 3 en verschuift pillar 2 (§12), en hoort daarom bij #51 vraag 1.

**Wat we onder "puzzel" verstaan** (nodig voor de toets): een plek waar je pas verder komt nadat je **stilstaat om een volgorde of timing te bedenken**. Een moeilijke sprong, een gevecht of een route die je moet vinden, is geen puzzel.

### Pillar 1: De echo houdt je in beweging

De echo is een volwaardig tweede lichaam, maar hij werkt mee in je ritme en niet in een raadsel: hij is je springplank, je tweede slag en je ketting. Beweging en gevecht moeten **satisfying** voelen: strak, met gewicht, zonder stilstand. **Op de kritieke route staan geen puzzels.** Optionele uitdagingen met de echo mogen wel, maar alleen als ze ook in beweging gebeuren, zoals een springparcours of een tijdrit.

**Toetsvraag:** *Maakt de echo deze actie vloeiender of krachtiger, zonder dat de speler ervoor moet stilstaan?*

**Is de echo verplicht op de kritieke route? Ja.** De springplank is verplicht zoals een dash in *Celeste* verplicht is: sommige afgronden en schachten haal je alleen door van je echo af te zetten, vanaf gebied 1. Het merk is verplicht in gevechten waar alleen een ontploffing een pantser breekt (bosses, zware vijanden). Dit is **geen puzzel** volgens de definitie hierboven: je doet het in beweging, zonder stil te staan om een volgorde te bedenken. Het is een moeilijke sprong of een gevecht. **Toets voor de LGD:** elke verplichte springplank- of merkplek haalt norm (1) hieronder (≤ ± 5 s stilstand). Een plek die daar niet aan voldoet, gaat van de kritieke route af of wordt herontworpen. Omdat de echo verplicht is, kan hij niet wegzakken tot een passieve buff (R-V2).

**Meetbaar in de slice** (normen, waarden stelt de LGD vast): (1) op de kritieke route staat een geoefende speler nergens langer dan ± 5 s stil om iets uit te zoeken; (2) de speler gebruikt de echo als springplank of merk-afmaker minstens ± 1× per 20 s gewoon spel; (3) playtest-score "voelde het vloeiend/satisfying?" gemiddeld ≥ 4 op 5.

| Past | Past niet |
|---|---|
| Afzetten van je echo houdt je vaart en geeft je dash terug | Een kamer waarin je een reeks schakelaars in de juiste volgorde moet zetten (puzzel op de kritieke route) |
| Een treffer zet een schaduwmerk; de echo laat het ontploffen | Een vijand die je alleen raakt als jij en je echo hem binnen 15 ticks tegelijk raken (dwingt wachten; was v0.3-voorbeeld) |
| Een boss die je dwingt je route zo te kiezen dat je schaduw straks onder je staat | Een boss die je wint door stil te staan tot de echo iets doet |
| Een dash die de echo een tel later herhaalt als snijlijn | Een standaard dubbele sprong die de echo als springplank overbodig maakt |

Uitzondering die mag: basisbeweging (lopen, springen, slaan, pareren) bestaat zonder echo, maar de echo moet er iets aan toevoegen als hij haar herhaalt.

### Pillar 2: Licht terugwinnen opent de stad

De wereld heeft nog steeds twee lagen: jij leeft in het licht, de echo in de schaduw. Maar je **wint licht terug**. Flow vult je lichtmeter, en bij een gemaal pomp je dat licht de stad in. Het water zakt, wijken gaan aan, en routes, kortere wegen en nieuwe gebieden gaan open. Of je ergens komt, hangt af van **licht, schaduw en water**, via **vaardigheden en routes**, nooit via een raadsel of een gekleurde sleutel. **Verlicht is niet fel.** Een opgepompte wijk krijgt **warm, gewoon licht**. Daarin bestaan de echo en speler 2 gewoon, en licht maakt juist harde schaduwen. *FelLicht* (`gdd.md` E-11) blijft een **lokale zone** bij een bepaalde lamp, lichtval of boss, waarin de echo oplost; oppompen maakt nooit een wijk tot FelLicht. Zo verzwakt voortgang je bondgenoot niet. De spanning zit ergens anders: in het donker zijn de vijanden sterker en is de route onleesbaar, en de verlichte wijk is je beloning. De Art Director maakt warm licht en FelLicht in één oogopslag verschillend (leesbaarheidseis hieronder).

**Toetsvraag:** *Gaat deze weg open door licht dat de speler terugwon of door een vaardigheid die hij heeft, en niet door een raadsel?*

**Leesbaarheidseis (voor Art, geen tweede toetsvraag):** alles wat via pillar 2 werkt, laat in het beeld zelf zien in welke laag het hoort, zonder icoon of uitleg. Dat geldt ook voor de **waterstand**: je ziet hoe hoog het water staat en wat er zou opengaan als het zakt. De basis staat in de stijltests (`docs/art/stijltests.md`): een harde rand tussen licht en schaduw, en *vol = levend, hol = echo*. Water is een **beeldlaag en een wereldstaat** (hoogte per wijk), geen derde speellaag voor de echo. Dat houdt de regels en de scope klein. **Dit wijkt bewust af van #54** ("water als derde laag"); het is een scopekeuze die meegaat in #51 vraag 1.

| Past | Past niet |
|---|---|
| Een gemaal oppompen: het water zakt, een ondergelopen straat wordt een nieuwe route | Een gekleurde deur die opengaat met een gekleurde sleutel |
| Een donkere wijk waar je echo sterk is maar vijanden je overvallen, tot je er licht in pompt | Een licht-puzzel waarin je lampen in een vaste volgorde moet draaien om verder te komen |
| Een vaardigheid die een route opent die je eerder zag maar niet haalde | Een poort die alleen een slot-icoon toont, zonder dat licht, schaduw, water of een vaardigheid de reden is |

Gevolg voor Art en Audio: leesbaarheid van de lagen en het water gaat vóór sfeer.

### Pillar 3: Eén stad, twee manieren van samenspelen

Solo en co-op zijn dezelfde game in dezelfde kamers met dezelfde regels. Solo is samen bewegen met je verleden; co-op is samen bewegen met een vriend, met een echo die van jullie allebei is. Er is geen aparte co-op-campagne, geen co-op-only content op de kritieke route en geen solo-versie van een kamer. **De vorm van co-op is een open CEO-keuze** (§5, vraag 7); de aanbeveling is de **gedeelde echo**.

**Toetsvraag:** *Werkt dit solo met de echo én in co-op in dezelfde kamer, zonder aparte versie?*

| Past | Past niet |
|---|---|
| Een sprongketen die solo over je echo loopt en in co-op over je medespeler | Een plek die alleen met twee echte spelers te halen is (op de kritieke route) |
| Drop-in/drop-out zonder kamer-reset | Een co-op-modus met een eigen wereld, eigen levels of eigen progressie |
| Een gedeelde camera die beide spelers in beeld houdt | Split-screen (botst met gedeelde camera en lokale co-op) |
| Een boss die in co-op anders voelt (twee spelers zetten merken, één finisher) maar dezelfde regels volgt | Content achter een co-op-only gate |

## 5. Solo en co-op, uitgeschreven

**Solo.** Je speelt de jonge machinist (§6). Je schaduw, de sluiswachter, volgt je met een korte staart van ± 2 s (vraag 8A) en doet wat jij deed, in de schaduwlaag. Hij is je springplank waar jij net was, en hij maakt je merken af waar jij net sloeg. Dat er geen puzzels zijn, betekent niet dat je niet nadenkt. Je denkt in beweging: "spring ik hier hoog over de afgrond en haal ik de overkant niet, dan loopt mijn schaduw een tel later door de lucht waar ik sprong en land ik op hem."

**Waar de echo vóór of onder je uitkomt, zonder wachten.** In een rechte voorwaartse run ligt de echo achter je. Daar dient hij niet als springplank maar voor je tweede slag en de ketting van merken. Dat is een bewuste keuze, geen gat. Vóór of onder je komt hij uit:
- **omhoog** (schachten, muren, wenteltrappen van belforten): wat je net onder je liet, staat een tel later onder je;
- **keren** (arena's, gevechten): wie omdraait, rent zijn echo tegemoet en zet zich van hem af. Dit is het kernritme van gevechten;
- **vallen** (afgronden): mis je een sprong, dan vangt je echo je op op het pad dat je net door de lucht aflegde;
- **lussen en terugkeerroutes**: de stad is gebouwd in rondgangen (grachten, ringdijken, omgangen van belforten), zodat een route je over je eigen spoor terugvoert.

Met de korte staart gebeurt dit allemaal binnen een tel of twee, dus binnen norm (1) van pillar 1. Bij 10 s (vraag 8B) kan het alleen in lussen en lange schachten waar je 10 s later terug bent. De levels moeten dan om de echo heen gebouwd worden (R-V12).

Wat de flow niet mag breken (richting voor de LGD): de echo **volgt je door een deur** in plaats van na elke kamerwissel even weg te zijn (was `gdd.md` O-5), en op je echo staan laat hem **niet** breken (§12).

**Co-op (lokaal, gedeelde camera, drop-in/drop-out).** De CEO wil co-op, maar is niet overtuigd van "speler 2 = de echo" (v0.3), van "co-op als bonus" en van "speler 2 draagt het licht" (#54). De richting die hij verder uitgewerkt wil zien, is de **gedeelde echo**.

- **A. Gedeelde echo (aanbeveling).** Beide spelers spelen live. Speler 1 is de machinist in het licht. Speler 2 is de **sluiswachter die weer uit zichzelf beweegt**, in de schaduwlaag, met dezelfde besturing en de schaduwregels van de echo: hij lost op in fel licht, kan geen lichtobjecten bedienen en moet in beeld blijven (C-06, C-07). Ze zijn elkaars springplank. Er is **één gedeelde echo**, die niet de hele tijd meeloopt. Hij verzamelt de merken van beide spelers en verschijnt als **finisher**: is de gedeelde lichtmeter vol, dan roept een van beiden hem op. De echo speelt dan de samengevoegde treffers van de laatste 10 s van allebei af, in ± 2 s, en laat alle merken ontploffen. Zo hebben op elk moment hooguit drie figuren een lichaam, en de derde maar kort. **Wie is de gedeelde echo?** Geen derde persoon, maar het **gemaal dat herinnert**: een schim van machinist en sluiswachter samen, half licht en half schaduw, die jullie laatste tien seconden in één keer terugspeelt.
  *Waarom aanbevolen:* het is het enige model waarin beide spelers volledig vrij spelen én de echo, de kern van de game, in co-op blijft. Speler 2 krijgt een eigen rol in het verhaal (§6), en de finisher is een gezamenlijk hoogtepunt: "dat deden wíj".
  *Kost:* C-01 (max. twee lichamen) verandert. Er komen nieuwe regels voor de gedeelde meter en de finisher (LGD ± 1 run, Combat Designer ± 0,5, TD prestaties ± 0,5, UX camera en leesbaarheid ± 0,5): **± 2,5 run**. In de slice ± 1–2 runs extra code ten opzichte van v0.3, waar P2 de bestaande echo-positie overnam.
- **B. Ieder een eigen echo (alternatief).** Beide spelers spelen live en hebben elk een eigen echo die altijd met dezelfde staart achter hen loopt. Co-op is dan letterlijk twee keer de solo-game naast elkaar.
  *Voordeel:* volledige gelijkheid met solo, en geen nieuw finisher-systeem.
  *Kost:* tot **vier lichamen** in beeld (twee vol, twee hol), zwaar voor de leesbaarheid (pillar 2), de camera en de Steam Deck, en meer art (twee echo-varianten). LGD ± 1, TD ± 1, UX ± 0,5, Art ± 0,5: **± 3 runs**, met een groter leesbaarheidsrisico (R2).

Wat in beide varianten blijft: drop-in/drop-out zonder kamer-reset (C-03, C-05, met de nieuwe vorm aangepast), de schaduwspeler die niet doodgaat maar oplost en terugkomt (C-06), de leiband van de gedeelde camera (C-07), en geen co-op-only content (L-02).

**Waarom dit werkt voor de doelgroep:** de solo-speler krijgt een vloeiende actie-metroidvania met een eigen idee. Het bankduo krijgt een spel waarin de minder ervaren speler live meedoet, vergevingsgezind faalt, en met de gezamenlijke finisher een groot moment mee kan maken.

## 6. Toon, setting en verhaal

**Duister maar niet gruwelijk; melancholisch, niet wanhopig.** Doel: **PEGI 12** (CEO-besluit #2).

### Setting: de gedroomde verzonken stad en de poldermachine

Een stad in de **Lage Landen** die in een droom onder water is gelopen, gecombineerd met de **verlaten poldermachine** die haar droog moet houden (#54).
- **Stad:** belforten die half onder water staan, grachten, een begijnhof, dijken. Het licht verwijst naar de **Vlaamse Primitieven**: helder, warm, gedetailleerd licht dat schaars is in het donker. Het **carillon** is het ritme van de echo, en kan in de muziek de maat van de staart en van de tien seconden slaan (richting voor de Audio Director).
- **Machine:** gemalen, sluizen, schoepenraderen en pompen. Hier pomp je licht in en zakt het water (pillar 2). Bossidee van de Combat Designer: **de Gemaalmeester**, een levende poldermachine.
- **De bevroren echo's:** overal in de stad staan de laatste 10 seconden van de bewoners, stilgezet in schaduw: een bakker die een brood aanreikt, kinderen die naar het carillon kijken. Dit is **sfeer en verhaal, geen puzzel**. Hooguit dient een bevroren echo als springplank of oriëntatiepunt.
- Dit is ook het **tweede culturele criterium** voor het VAF (#51, 5A; `subsidies.md`), zonder dat het de pillars raakt.

### Verhaalpremisse V2: "Het gemaal van herinneringen"

Je bent de **jonge machinist** van de poldermachine. Je schaduw ís de **sluiswachter**: de man die ooit het water binnenliet en die nu alleen nog kan herhalen wat een ander doet. Gaandeweg ontdek je wie hij was en waarom het water kwam. Aan het einde krijgt hij zijn eigen tien seconden terug en laat hij los. De mechaniek is het thema: de echo kan alleen herhalen, en het verhaal gaat over het moment waarop dat niet meer hoeft. In co-op (variant A) is speler 2 de sluiswachter die weer uit zichzelf beweegt. Dat is de droom die het einde al even laat voelen. De uitwerking is van de Narrative Designer (T9); ik review haar.

### Toonregels

- **Water en verdrinken (PEGI 12):** de overstroming is een droom en een herinnering, geen ramp in beeld. We tonen geen lichamen, geen verdrinking en geen paniek; de bevroren echo's zijn alledaagse momenten, geen doodsmomenten. **Geen verwijzing naar een echte watersnood** (zoals 1953): de stad is gedroomd. Dat is respect voor het publiek in de Lage Landen en past bij PEGI 12.
- **Geweld:** gestileerd, geen bloed of lichamelijk detail. Vijanden lossen op in licht of schaduw; de echo "breekt" in schaduwdeeltjes. Een merk-ontploffing is een uitbarsting van licht en schaduw, geen vleeswond.
- **Gevoel:** stilte, verlaten plekken, licht als iets kostbaars. Momenten van warmte (een wijk die weer aangaat, de sluiswachter die je hand vasthoudt bij een checkpoint) wegen zwaarder omdat de rest donker is.
- **Humor:** zuinig en droog, vooral via de echo, die ook je mislukte sprong trouw herhaalt.
- **Niet:** grimdark, horror-jumpscares, ironische knipogen naar de speler, ellenlange lore-dumps.
- **Taal:** Engels bij launch, en in principe ook Nederlands (besluit #51, 5A; de EP raamt de kost). Schrijf zuinig, zodat de stad meer vertelt dan de tekst.

### Beeld: 2D (CEO-besluit #18)

Pixel art op 640×360 (op de Steam Deck 640×400), met dynamisch 2D-licht in harde banden.
- **De laaggrens is gameplay.** Een harde rand laat op de pixel zien waar licht ophoudt en de schaduw van je echo begint (pillar 2).
- **Vol = levend, hol = echo.** Speler 1, speler 2 en de echo zijn in de stijltests (placeholder) op elke achtergrond uit elkaar te houden; de art bible moet dat in de eind-art waarmaken, ook met de finisher-echo uit §5 als derde figuur.
- **Combat leesbaar:** merk, ontploffing en parade lezen in één frame, ook als er drie figuren in beeld zijn (Art Director, Combat Designer).
- **Sfeer zonder de leesbaarheid te raken:** volumetrisch licht, water en diepte alleen in de achtergrond en de parallax-lagen; het speelvlak blijft strak.

### Naam en toon

De werktitel *Wraithstep* klinkt duisterder dan de game (risico R15 in `docs/productie/risico.md`). Wij lezen *wraith* als **schim**: de sluiswachter, een spookachtige voetstap die de jouwe herhaalt, geen wraakgeest of monster. V2 maakt die lezing sterker: de wraith is letterlijk iemand die alleen nog jouw stap kan zetten.
- **De wraith is jouw schaduw, en die is je bondgenoot.** Richting voor de Narrative Designer: gebruik "wraith" in de game niet als naam voor vijanden.
- **Geen horrorbeeld bij de naam.** Logo, key art en storetekst: geen schedels, bloed, kettingen of krijsende gezichten, en geen verdronken figuren. Wel: stilte, harde lichtbanden, water, het holle silhouet van de echo.
- **Toets voor elke uiting met de naam** (Marketing, Art, Narrative): *Leest dit, met de naam erbij, als PEGI 12, duister maar niet gruwelijk?* Bij "nee" past de uiting zich aan, niet de toon van de game. Raakt de naam bij een **concept voor een publieke uiting** toch de toon, dan volgt een nieuwe naamvraag aan de CEO, vóór de betaalde merkcheck (R15). Vóór die merkcheck gaat er niets publiek (besluit #24, 3A).

## 7. Referenties

| Referentie | Wat we nemen | Wat we niet nemen |
|---|---|---|
| *Hollow Knight* (2017) | **Hoofdreferentie voor het gevoel** (#54): precieze besturing, gewicht in elke slag, bosses als hoogtepunt, melancholie, een meter die je vult door te vechten | De lengte en de straf bij doodgaan; wij zijn korter (5–7 uur) en vriendelijker |
| *Nine Sols* (2024, Red Candle Games) | **Hoofdreferentie voor combat** (#54): pareren als kern, een treffer die een lading op de vijand zet die je later laat ontploffen (dicht bij ons schaduwmerk, zie R-V9), strak tempo | Zijn moeilijkheid als drempel; bij ons is de minder ervaren co-op-speler welkom |
| *Super Metroid* (1994) | Wereldstructuur, vaardigheden als sleutels, de wereld leest zichzelf | De eenzaamheid als enige modus |
| *Ori and the Blind Forest* / *Will of the Wisps* | Licht als thema en mechaniek, vloeiende beweging, afzetten van dingen om vaart te houden | Het sentiment als hoofdmotor |
| *Celeste* (2018) | Strakke 2D-besturing in pixel art, dash-reset als ritme, toegankelijkheidsopties die de uitdaging niet verraden | Precisie-platforming als hoofdzaak en de lineaire hoofdstukken |
| *Outland* (2011) | Licht/donker-polariteit in navigatie en gevecht van een metroidvania | Polariteit als schakelaar op één lichaam; online co-op |
| *Contrast* (2013) | Schaduwen als speelbare laag naast de "echte" wereld | Een lineaire structuur zonder terugkeren |
| *Limbo* / *Inside* | Leesbaar silhouet, duistere maar ingetogen toon | Gruwelijke sterfscènes |
| *It Takes Two* / *Unravel Two* | Bank-co-op waarin beide spelers een eigen, onmisbare rol hebben | Losse minigames, co-op-only ontwerp |
| *Braid* (2008), *Chronotron*, *Super Time Force* (2014) | De mechaniek *is* het thema; een vorige versie van jezelf die meevecht (*Super Time Force*) | **Puzzelkamers** (*Braid*, *Chronotron*): vanaf v0.4 bewust niet op de kritieke route |

## 8. USP's

1. **Een metroidvania waarin je schaduw je bondgenoot in beweging is.** Je echo is je springplank en je tweede slag. Samenwerken met een opname van jezelf bestaat in puzzelgames (sinds *Chronotron* en *Braid*, 2008) en in een run-and-gun (*Super Time Force*). Het onderscheid zit in de **combinatie**: we vonden geen metroidvania die een vertraagde kopie van de speler als kern van beweging, gevecht én voortgang gebruikt (`docs/business/naamcheck.md` §3, peildatum 2026-11-08). Het dichtst bij de regel ligt *Echo Shift* (echo's van je laatste 15 s), maar dat is een first-person puzzelgame zonder gevecht. v0.4 staat daar verder van af: geen puzzels, een gevechts-metroidvania, en een korte staart (vraag 8A). We claimen daarom nergens "de eerste". De ideecheck moet opnieuw voor de nieuwe vorm (R-V9).
2. **Licht terugwinnen als motor van de wereld.** Goed spelen vult je lichtmeter; bij een gemaal pomp je licht de stad in en zie je de wereld veranderen: het water zakt, wijken gaan aan. Elke voortgang voel je in de stad zelf.
3. **Een eigen, Laag-Landse wereld.** Een gedroomde verzonken stad met belforten, polders en gemalen, en licht naar de Vlaamse Primitieven. Dat zie je zelden in het genre.
4. **Lokale bank-co-op met een gedeelde echo** (vorm onder voorbehoud van CEO-vraag 7). Beide spelers spelen live, en de echo is van allebei. *Aanname:* de doelgroep (koppels, vrienden) vraagt erom; marktonderbouwing volgt van Marketing.
5. **Behapbaar en vriendelijk:** 5–7 uur, 3–4 gebieden, 4–5 bosses, ongeveer €20 eenmalig zonder microtransacties (CEO-besluit #2). Uit te spelen in een paar avonden, toegankelijk voor een minder ervaren co-op-partner.

## 9. Doelgroep en bereik

Leeftijd 18–30, pc via Steam, Steam Deck verified als doel. Engels bij launch, Nederlands in principe ook (besluit #51, 5A). Twee kernspelers:

| Speler | Wie | Wat ze zoeken | Wat ze in *Wraithstep* vinden |
|---|---|---|---|
| **De genrefan** | Speelde *Hollow Knight*, *Nine Sols*, *Ori*; speelt vooral solo, kijkt naar gevoel, combat en sfeer | Een metroidvania met een eigen idee, strak gevoel, sterke bosses | Een eigen draai op beweging en gevecht in een kortere game dan de grote titels; solo ook op de Steam Deck |
| **Het bankduo** | Koppel of vrienden, vaak één ervaren en één minder ervaren speler | Iets dat ze samen kunnen spelen waarin allebei iets te doen hebben | Beide live, een vergevingsgezinde schaduwrol en een gezamenlijke finisher; drop-in/drop-out op **pc aan de tv** met twee controllers |

**Co-op-situatie:** de hoofdsituatie voor co-op is **pc aan de tv**. Co-op op één Steam Deck-scherm met een gedeelde camera is krap, zeker met een derde figuur in beeld; dat claimen we niet tot de UX Designer en de Technical Director het getoetst hebben. Tot dan noemt Marketing de Deck alleen voor solo.

*Aanname, nog niet onderbouwd:* het bankduo is groot genoeg om co-op als tweede verkoopargument te dragen. Marketing kan dit toetsen. Door de keuze voor combat à la *Hollow Knight*/*Nine Sols* ligt het zwaartepunt nu meer bij de genrefan; het bankduo vraagt dan een goede toegankelijkheid (vergevingsgezinde schaduwrol, assist-opties).

## 10. Risico's voor de visie

Nummering: R-V = visierisico in dit document; de R-nummers uit `docs/productie/risico.md` staan erbij waar ze overeenkomen. De Producer werkt `risico.md` bij na het conceptbesluit.

| # | Risico | Waarom het de visie raakt | Wie | Voorstel |
|---|---|---|---|---|
| R-V1 (R9) | **De echo-duur klopt niet.** Bij 10 s voelt een merk dat pas later ontploft los van je slag, en ligt de springplank te vaak achter je; bij een te korte staart lijkt de echo een nabeeld in plaats van een tweede lichaam | De draai hangt aan die ene waarde | LGD, Combat Designer | **CEO-vraag 8.** Bij 8A prototypen met 1,5, 2 en 3 s, bij 8B met 6, 10 en 14 s (zoals gepland). Het merk toont zijn aftelling in beeld en geluid (het carillon). |
| R-V2 | **Zonder puzzels wordt de echo passief**, een automatische buff waar je niet over nadenkt | Pillar 1: dan is het geen tweede lichaam meer | LGD, World & Level Designer | **Springplank en merk zijn verplicht op de kritieke route** (pillar 1), getoetst tegen de puzzeldefinitie en norm (1). Meten met norm (2) van pillar 1. Bosses en routes die het keren, klimmen en opvangen afdwingen. |
| R-V3 (R12) | **De echo is te vaak "leeg"** | Elke lege seconde is een gebroken ketting | LGD, TD | De echo volgt je door deuren (O-5 wordt de regel, §12). Op je echo staan breekt hem niet meer. |
| R-V4 (R20) | **Combat-zwaar is duurder dan puzzels.** Meer vijandtypes, animatie, hitfeedback en bosses om *Hollow Knight*-gevoel te halen | Scope binnen 5–7 uur en het budget per fase | EP, Combat Designer, Art Director | **Scopeplafond voor F6:** max. **4 nieuwe vijandtypes per gebied** (max. 14 in totaal, inclusief varianten), max. **1 minibaas per gebied**, en 4–5 bosses (besluit #2). De slice meet de kost per vijandtype en per boss (F6) tegen dit plafond. Weinig types die veel kunnen (merk, parade). Reken erop dat fase 3–4 duurder worden dan bij een puzzelgame. |
| R-V5 (R10, herzien) | **Co-op wordt chaos of te makkelijk.** Twee live spelers plus een finisher kunnen elk gevecht platslaan | Pillar 3 | LGD, Combat Designer | Co-op ≤ 2× zo snel als solo blijft de grens. Finisher alleen bij een volle gedeelde meter. Testen in beide modi vanaf het eerste prototype. |
| R-V6 (R2) | **Drie figuren plus water, merken en ontploffingen zijn niet leesbaar** | Pillar 2 valt dan om | Art Director | Art bible met de finisher-echo en het merk als eis. Prestaties op de Steam Deck (Technical Artist, Engine & Platform Programmer). |
| R-V7 | **Verdrinken raakt PEGI 12 of het publiek** | Een verzonken stad kan als ramp of dood lezen | Narrative Designer, Art Director, CD | Toonregels in §6 (droom, geen lichamen, geen echte watersnood). Elke scène met water langs de toets "duister maar niet gruwelijk". |
| R-V8 | **5–7 uur is kort voor een metroidvania** | De echo moet binnen minuten dragen | LGD, World & Level Designer | Springplank en merk zitten vanaf de proloog in de kern; elk gemaal verandert de stad zichtbaar. |
| R-V9 | **Het idee lijkt sterk op een bestaande game.** Het schaduwmerk ligt dicht bij de lading-en-ontploffing in *Nine Sols*. *Echo Shift* ("laatste 15 seconden") ligt dicht bij de regel. | USP 1 | Business/Legal (#8) | Ideecheck herhalen voor de nieuwe vorm (springplank, merk, oppompen) **vóór T3 het schaduwmerk (E-14) en de merksprong vastlegt, en vóór de flow-kamer**: dan is bijsturen nog goedkoop. Verschil met *Nine Sols*: de echo zelf brengt het merk tot ontploffing, op jouw route van zonet. Verschil met *Echo Shift* (first-person puzzel, geen gevecht): v0.4 staat er verder van af dan v0.3, want er zijn geen puzzels, het is een gevechts-metroidvania, en bij 8A geldt een korte staart in plaats van een lange opname. |
| R-V12 | **De springplank ligt achter je.** In een voorwaartse run staat de echo achter je, dus als springplank werkt hij alleen bij klimmen, keren, vallen en lussen (§5) | Pillar 1: "springplank" belooft meer dan de beweging geeft | LGD, World & Level Designer | Korte staart (vraag 8A) en de vier situaties uit §5 als levelregel. **Meetpunt in de flow-kamer:** springplank-gebruik per minuut en het aandeel daarvan dat zonder stilstand (norm 1) lukt. Haalt de flow-kamer norm (2) niet, dan volgt eerst herontwerp en daarna een nieuwe vraag aan de CEO. |
| R-V10 (R15) | **De naam leest duisterder dan de game** | Een titel met *wraith* en een verzonken stad kan horror beloven | CD, Marketing | Regels en toets in §6 "Naam en toon". Bij een **concept voor een publieke uiting** dat de toon toch raakt: nieuwe naamvraag aan de CEO vóór de betaalde merkcheck. |
| R-V11 (R24) | **De naam is slecht vindbaar.** "Wraithstep" is al een uniek item in *Diablo II: Resurrected* | Vindbaarheid | Marketing, CD | Zie §11 vraag 4. |

## 11. Open vragen

| # | Vraag | Richting CD | Eigenaar | Stand |
|---|---|---|---|---|
| 1 | Wat gebeurt er met de echo als speler 2 meedoet? | v0.3: speler 2 *wordt* de echo (C-01–C-05). v0.4: **gedeelde echo** (aanbeveling), alternatief: ieder een eigen echo (§5). | **CEO** (vraag 7), daarna LGD | **Heropend** door #54 |
| 2 | **Ankeren:** mag de speler later de herhaling vastzetten? | Alleen als het de flow helpt (bv. een vaste springplank in een lange schacht), niet als puzzelgereedschap. | LGD, Systems Designer | Open (O-3), herzien bij §3 van de gdd |
| 3 | **Falen in co-op:** kan de schaduwspeler doodgaan? | Nee, hij lost op en keert terug (C-02, C-06). Geldt in beide co-op-varianten. | LGD, UX Designer | Gesloten |
| 4 | **Titel:** is *Wraithstep* ook de definitieve naam? | Als werktitel goed, en V2 versterkt de lezing "schim". Twee zorgen blijven: de toon (§6, R15) en de vindbaarheid naast het *Diablo II*-item. Marketing toetst eerst de vindbaarheid (#44). **Daarna, en vóór de opdracht aan de specialist voor de formele merkcheck**, kies ik met Marketing tussen (a) houden, (b) houden met een onderscheidende toevoeging, of (c) een nieuwe naamvraag aan de CEO. Zo betalen we de merkcheck alleen voor de naam die we echt houden. (c) is een CEO-besluit. | CD, Marketing, Business/Legal | Werktitel besloten (#24); korte merkcheck oranje; volgorde #44 → TMview/WIPO → keuze a/b/c → offertes → betaalde merkcheck |
| 5 | **Opnamemodel:** posities of inputs? | Toestandsopname blijft (`gdd.md` §2.2). Nieuw is één uitzondering: de **merksprong**, waarbij de echo van zijn pad afwijkt naar een merk binnen een straal (§12). | LGD, TD | Gesloten voor v0.3; merksprong nieuw (§12) |
| 6 | **Drop-out zonder 10 s buffer** | Niets verzinnen: liever even een lege schaduw. | LGD | Gesloten (C-05); opnieuw toetsen bij de co-op-vorm |
| 7 | **Lichtmeter:** is het dezelfde meter voor genezen en oppompen? | Ja, dat geeft spanning (nu genezen of bewaren voor de stad). Maar een gemaal mag een zwakke speler nooit laten vastlopen: de meter vult snel in flow, er is geen grind. | LGD, Systems Designer | Nieuw |
| 8 | **Optionele echo-uitdagingen:** horen ze erin? | Ja, als ze in beweging gebeuren (springparcours, tijdrit), nooit op de kritieke route, en alleen als de scope het toelaat. | LGD, World & Level Designer | Nieuw |

Vraag 1 raakt pillar 3 en ligt daarom bij de CEO (#51, vraag 7). De echo-duur (korte staart of 10 s) is een CEO-besluit (roadmap: "echo-duur ≠ 10 s") en staat als #51 vraag 8. Vragen 2, 5, 7 en 8 beslis ik binnen de pillars met de vakrollen. Als een uitkomst een pillar zou veranderen, gaat het als `ceo-beslissing` naar de CEO.

## 12. Wat er verandert t.o.v. v0.3

Kost in **runs** (één maak-taak van een rol). "In T3" betekent: past in GDD v1, die in het fasekader van fase 2 al gepland staat (`fase-2-kader.md` T3). Code in `game/` schuift mee met T4, T5 en T8.

### Per pillar

| Pillar | v0.3 | v0.4 | Gevolg |
|---|---|---|---|
| **P1** | *De echo is je tweede lichaam*; het slimme gevoel komt uit plannen; puzzels op de kritieke route (max. 10 per gebied, `kernloop.md` §5) | *De echo houdt je in beweging*; springplank en schaduwmerk; **0 puzzels op de kritieke route**; toetsbaar met een toetsvraag en drie normen | Kernloop, testkamers en vaardigheden herzien |
| **P2** | *Licht en schaduw zijn de kaart*; gating via licht/schaduw/echo, ook als raadsel (lampbrug) | *Licht terugwinnen opent de stad*; lichtmeter, gemalen, waterstand; gating via vaardigheden en routes, geen raadsels | Nieuw systeem: lichtmeter + gemaal + waterstand |
| **P3** | Speler 2 *is* de echo; solo plannen vs. co-op afstemmen | Eén stad, twee manieren; co-op als **gedeelde echo** (aanbeveling, CEO-vraag 7) | C-01 en de co-op-regels herzien |

### Per gdd-regel (`docs/design/gdd.md` v0.2)

| Regel | Was | Wordt (richting; de LGD schrijft de regel en de test) | Kost |
|---|---|---|---|
| **E-04a** | Kamerwissel zet de echo 10 s op Leeg | **Vervalt als reset.** De echo volgt je door een deur naar een aangrenzende kamer (was O-5); een reset alleen bij een niet-aangrenzende kamer, respawn, Loslaten of breken | LGD 0,5 (in T3) + TD/GP 1 (AreaLoader, in T5) |
| **E-07a** | P1 beweegt mee op de echo maar krijgt **geen** snelheid mee | **Springplank:** P1 behoudt zijn eigen vaart bij landen of afzetten, en krijgt zijn dash (en eventuele luchtsprong) terug. Bewegen met de plank blijft | LGD 0,5 (in T3) + GP 0,5 |
| **E-08b** (steuncontrole) | Steunde P1 op een schaduwlichaam, dan breekt de echo 10 s later op dat punt | **Vervalt voor steun op een schaduwlichaam.** De echo valt of zweeft door die frames heen zonder te breken; anders breekt elke springplank-ketting zichzelf | LGD 0,25 (in T3) + GP 0,25 |
| **E-14** | Echo-treffer doet 100 % van de treffer van P1 | **Schaduwmerk:** een treffer van P1 zet een merk; de echo-treffer laat merken ontploffen (schade en stapelen: Combat Designer). De echo blijft onkwetsbaar | Combat Designer 1 (in T3) |
| **E-02** (duur, bij vraag 8A) | D = 600 ticks (10 s) | **Korte staart:** D ± 120 ticks (2 s; bereik 90–180), parameter zoals nu. De playtest test 1,5, 2 en 3 s | LGD 0,25 (in T3) + GP 0,25 |
| **E-02** (nieuwe uitzondering) | De echo staat altijd op de opgenomen positie | **Merksprong:** op het moment van een opgenomen treffer mag de echo binnen een straal naar het dichtstbijzijnde merk schieten. Dit is de enige afwijking van het pad, en daarna keert hij terug op zijn opname | LGD + Combat 0,5 (in T3) + GP 0,5 |
| **C-01** | Max. twee lichamen; P2 vervangt de echo | Variant A: P1 + P2 live, plus de gedeelde echo alleen als finisher (± 2 s, max. drie figuren). Variant B: vier lichamen | A ± 2,5 / B ± 3 (§5) |
| **C-02–C-05** | P2 neemt de echo over bij drop-in, de echo neemt over bij drop-out | Aanpassen aan de gekozen variant; C-06 en C-07 blijven | In de kost van C-01 |
| **Tweeslagschild** (testkamer T5, venster in §2.9) | Vijand met een venster van 15 ticks voor jou + echo | **Vervalt** (dwingt wachten); vervangen door merk-vijanden | In T3 |
| **L-01, L-04, L-05, L-06** | Regels voor echo-puzzelkamers | **Herzien of vervallen**; nieuwe levelregels voor sprongketens, merk-arena's en gemaal-wijken | World & Level Designer 1 (in T3) |
| **`gdd.md` §3** (Dempen, Dragen, Ankeren, Terugstappen) | Vooral puzzelgereedschap | Herzien naar beweging/gevecht die de echo versterkt; Terugstappen kan blijven als ontsnapping in combat | Systems Designer 1 (in T3) |
| **Testkamers T1–T5, V1** (§4.2) | Puzzelkamers | Herzien naar flow-kamers: sprongketen, merk-arena, één gemaal | LGD 0,5 (in T3) |
| **Nieuw: lichtmeter + gemaal + waterstand** | Bestond niet | Nieuw systeem (pillar 2) | Systems/LGD 1 (in T3) + GP 1–2 (in T8) |

### Andere documenten (alleen via issues voor de eigenaar)

| Document | Wat | Eigenaar | Kost |
|---|---|---|---|
| `docs/design/kernloop.md` | Loop in één zin, max. 0 puzzelkamers op de kritieke route, K-04 (eindboss-poort zonder echo-puzzel), toets aan de nieuwe pillars | LGD | 1 (in T3) |
| `docs/productie/fase-2-kader.md` | Alle puzzelplekken: §1 vraag 1 ("of co-op de puzzels triviaal maakt"); T3 ("echo-puzzels" → flow-kamers, lichtmeter, gemaal); T4/T8 en de volgorde in §4 ("T4 vóór de echo-puzzels van T8"); T11 en F4 ("elke slice-puzzel" → "elke slice-kamer"; flownormen van P1 in plaats van R10-puzzels); F4b(b) ("buiten verplichte puzzels" → "buiten merk-ontploffingen", bv. het aandeel springplank-sprongen); R10 in §5. Slice = polderwijk met het eerste gemaal + de Gemaalmeester; eventueel een flow-kamer als eerste mijlpaal (#51 vraag 2) | EP | 0,5 |
| `docs/productie/risico.md` | R10 herzien; nieuwe risico's R-V2, R-V4, R-V7, R-V9 | Producer/EP | 0,25 |
| Narratief (T9) | Uitwerking V2 | Narrative Designer | 0 extra (T9 staat al gepland) |
| Art bible (T1) | Setting, water, merk en finisher-echo als leesbaarheidseis | Art Director | ± 0,5 extra |
| Ideecheck (`naamcheck.md` §3) | Herhalen voor de nieuwe vorm (R-V9) | Business/Legal | 0,5 |

**Totaal (opgeteld uit de twee tabellen hierboven, co-op variant A, echo-duur variant 8A; bij 8B vervalt de post E-02 duur, maar komt er ± 0,5–1 run levelregels bij om de echo vaker vóór je te leggen):**

| Post | Runs |
|---|---|
| Documenten binnen T3 (E-04a 0,5 · E-07a 0,5 · E-08b 0,25 · E-14 1 · E-02 duur 0,25 · E-02 merksprong 0,5 · L-regels 1 · §3 1 · testkamers 0,5 · lichtmeter 1 · kernloop 1) | ± 7,5 |
| Documenten buiten de planning (C-01 2,5 · fasekader 0,5 · risico 0,25 · art bible 0,5 · ideecheck 0,5) | ± 4,25 |
| **Documenten samen** | **± 11,75** |
| Code (E-04a 1 · E-07a 0,5 · E-08b 0,25 · E-02 duur 0,25 · E-02 merksprong 0,5 · lichtmeter 1–2 · C-01 1–2) | ± 4,5–6,5 |
| **v0.4-delta in totaal** | **± 16,25–18,25 (≈ 16–18)** |

We rekenen conservatief: het ontwerpwerk voor echo-puzzels dat in T3 en T8 vervalt, is **niet** afgetrokken. Een run telt hier als één maak-taak. Bestaande code in `game/` (de echo-spike en de E- en C-tests) blijft bruikbaar; de tests voor E-04a, E-07a, E-08b, E-14 en C-01 worden herschreven.

**Open punt:** de weken in `fase-2-kader.md` gaan nog uit van het ritme van #47; de EP herraamt de doorlooptijd volgens #52 wanneer hij het kader aanpast.

## 13. Definition of Done

**#4 (v0.1), #15 (v0.2), #25 (v0.3):** afgerond; zie de gemergde PR's #11, #22 en #41.

**#55 (v0.4)**
- [x] Elk antwoord van de CEO uit #54 is terug te vinden: spelgevoel en referenties (§3, §7), geen puzzels (§4 P1), springplank (§3, §12 E-07a), schaduwmerk (§3, §12 E-14), licht oppompen (§3, §4 P2), gating zonder raadsels (§4 P2), V2 (§6), setting (§6), co-op als gedeelde echo met één alternatief (§5, CEO-vraag 7), de Gemaalmeester (§6)
- [x] Geen puzzels op de kritieke route; flow/satisfying is toetsbaar (toetsvraag en normen P1, §4)
- [x] Wijzigingen t.o.v. v0.3 met kost (§12); geen tegenspraak met `docs/beslissingen.md` (PEGI 12 §6, 5–7 uur en 3–4 gebieden §8, NL-versie in principe §6/§9)

**#43 (reviewpunten PR #41)**
- [x] 1. "Concept voor een publieke uiting" in §6 en §10 (R-V10)
- [x] 2. §11 vraag 4: keuze a/b/c vóór de opdracht aan de specialist
- [x] 3. Interne noot onder de logline naar §14; logline als lopende zin; toonwoord "melancholy" in de Engelse variant
- [x] 4. §9 "verandert het genre echt" afgezwakt tot "een eigen draai"
- [x] 5. §3: de schaduwspeler blijft binnen de gedeelde camera (C-07)
- [x] 6. Statusregel bijgewerkt

## 14. Wijzigingen

| Versie | Wat |
|---|---|
| 0.4 | Live brainstorm met de CEO (#54) verwerkt. Draai en kernfantasie in beweging ("springplank en tweede slag"); P1 *De echo houdt je in beweging* (geen puzzels op de kritieke route, toetsbare flownormen); P2 *Licht terugwinnen opent de stad* (lichtmeter, gemaal, waterstand; gating via vaardigheden en routes); P3 met co-op als gedeelde echo (CEO-vraag 7, alternatief: ieder een eigen echo). Setting (gedroomde verzonken stad + poldermachine) en verhaalpremisse V2 in §6, met toonregels voor water (PEGI 12). Referenties: *Hollow Knight* en *Nine Sols* als hoofdreferentie. USP's, doelgroep en risico's herzien; nieuwe sectie §12 "Wat er verandert t.o.v. v0.3". Reviewpunten #43 verwerkt. Lead-review EP (PR #56): totalen §12 herrekend (documenten ± 11,5, code ± 4,25–6,25, samen ± 16–18), puzzelplekken in het fasekader benoemd, ideecheck R-V9 vóór T3, kost fase 3–4 bij R-V4, water als speellaag expliciet als afwijking van #54, open punt herraming volgens #52. SM-review (PR #56): korte staart van ± 2 s met de 10 s in verhaal en finisher (CEO-vraag 8), waar de echo vóór je uitkomt (§5) en R-V12 met een meetpunt; verlicht ≠ FelLicht (P2); springplank en merk verplicht op de kritieke route en getoetst tegen de puzzeldefinitie (P1, R-V2); *Echo Shift* in USP 1 en R-V9; wie de gedeelde echo is (§5A); scopeplafond combat (R-V4). **Interne noot (was onder de logline, #43.3):** "melancholisch" in plaats van "duister" is bewust: de naam draagt het duister al, en de logline zet de schaduw neer als bondgenoot. |
| 0.3 | Werktitel *Wraithstep* (#24) doorgevoerd. Toon bij de naam: logline "melancholisch", blok "Naam en toon" in §6, twee risico's (toon R15, vindbaarheid). Reviewpunten PR #22 verwerkt. |
| 0.2 | Reviewpunten PR #11 verwerkt; randvoorwaarden #2 en stijl 2D (#18) doorgevoerd; open vragen als tabel. |
| 0.1 | Eerste versie (#4, PR #11). |
