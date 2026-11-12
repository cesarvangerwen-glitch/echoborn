# Pitch: *Polderlight* (werktitel)

Versie 0.5 · Eigenaar: Creative Director · Issue: #191 (v0.4: #55, PR #56; v0.3: #25, PR #41; v0.2: #15, PR #22; v0.1: #4, PR #11) · Status: **concept definitief in de vorm van v0.4 (besluit #51: 1A, 7A, 8A)**; v0.5 verwerkt de CEO-besluiten van 2026-11-12: **echo-staart 1 s (D = 60 ticks), bereik 1–3 s**, **fase 2 parallel, ook bouwen** (wijzigt 2A) en **de CEO test alleen bij mijlpalen**. Daarnaast het antwoord van de CD op O-22 (lussen en terugvallen bij D = 60, §5) en de toets van R-V1 op 1 s (§10). Pillars en kernfantasie veranderen niet.
Werktitel ***Polderlight*** (besluit #96, vervangt *Wraithstep*). Nog niet publiek gebruiken vóór de formele merkcheck door een specialist (besluit #24, 3A). Repo- en mapnamen blijven voorlopig "echoborn".
Gebaseerd op `docs/beslissingen.md` (stand 2026-11-12: randvoorwaarden #2, stijl 2D #18, gate fase 1 #51, werktitel #96, de twee besluiten van 2026-11-12) en het brainstormverslag #54. Waar dit document iets aanneemt dat nog geen CEO-besluit is, staat dat erbij.
**Werkaannames** (fasekader §5): D = 60 is een CEO-besluit *als werkaanname*, nog niet gespeeld door de CEO en niet met de bots gemeten. **Werkaanname CD** (binnen de pillars, geen CEO-besluit): in de slice zijn lussen en terugvallen geen eigen bouwsteen (§5, O-22), en MT1 toetst R-V1 met één vraag en de bestaande meting (§10). Beide worden opnieuw bekeken na MT1 en, voor de lus, als D boven 60 komt.

---

## 1. De draai in één zin

> **Je schaduw herhaalt wat je net deed en wordt zo je springplank en je tweede slag; de stad zelf herhaalt de laatste tien seconden van haar bewoners.**

**Echo-duur (besloten, #51: 8A; CEO 2026-11-12):** in het spel loopt de echo een **korte staart** van **1 s (D = 60 ticks)** achter je, als werkaanname voor de verdere bouw; het bereik is **1–3 s** (was ± 2 s, bereik 1,5–3 s). De CEO koos 1 s na de tweede flow-test: hoe korter, hoe vloeiender. Alleen zo is hij een springplank zonder dat je moet wachten (§5). De **10 seconden** blijven het ritme van het verhaal en van de finisher: de bevroren echo's tonen de laatste 10 s van de bewoners, de sluiswachter krijgt aan het einde zijn eigen 10 s terug, en de co-op-finisher speelt jullie laatste 10 s af (§5, §6). *Verworpen alternatief (8B):* 10 s als echo-duur in het spel; dan hadden de levels de echo veel vaker vóór je moeten leggen (§5, R-V12).

Dat is de hele game. In v0.3 was de echo vooral een puzzelstuk ("elke kamer los je op met twee lichamen"). Vanaf v0.4 is hij een **bondgenoot in beweging**: hij draagt je verder en slaat met je mee. Er staan geen puzzels op de kritieke route (§4, pillar 1).

## 2. Logline

*Polderlight* is een melancholische 2D-metroidvania in een gedroomde, verzonken stad, waarin je schaduw herhaalt wat je net deed en zo je springplank en je tweede slag wordt.

**Engelse variant (werkversie voor store en pitchdeck, af te stemmen met Marketing):**
*A melancholy metroidvania in a drowned dream-city, where your shadow repeats what you just did and becomes your springboard and your second strike.*

## 3. Kernfantasie

**"Ik beweeg en vecht vloeiend, met een bondgenoot die ik zelf ben."**

Dit zijn de twee zinnen die de CEO van spelers wil horen (#54): *"het was heel satisfying"* en *"vloeiend met een bondgenoot"*. Het gevoel dat we zoeken is dat van *Hollow Knight* en *Nine Sols*: precieze besturing, gewicht in elke slag, en een ritme dat je in je handen voelt. De echo maakt dat ritme dubbel. Je springt van je eigen schaduw af en houdt je vaart. Je slaat een vijand, en een tel later slaat je schaduw daar nog eens, harder. Het slimme gevoel blijft, maar het komt in beweging: je kiest je route zo dat je schaduw straks onder je staat waar je hem nodig hebt.

### Wat de speler doet (speelbaar, niet alleen verhalend)

| Moment | Solo | Co-op (besloten, #51: 7A; zie §5) |
|---|---|---|
| **Bewegen** | **Echo als springplank.** De echo loopt je route van zonet. Land je op hem of zet je je van hem af, dan houd je je snelheid en krijg je je dash terug (**bounce**). Mis je een sprong, dan kan hij je **vangen** op het pad dat je een tel geleden aflegde. Een goede run is een ketting: sprong, dash, afzetten van je schaduw, verder. | **Samen bewegen = sterker bewegen.** **Bounce** op het hoofd van je partner geeft een hoge sprong en een dash-reset. Bij een **lancering** houdt de een een aanval vast, en de ander stapt erop en wordt weggeslingerd. Bij **vangen** val je bij de ander, die je opvangt en omhoog zwiept. |
| **Vechten** | **Schaduwmerk.** Elke treffer zet een merk op de vijand. Komt de echo bij die treffer aan, dan schiet hij naar het merk en laat het ontploffen. Meer merken betekent een grotere ontploffing. Pareren en ontwijken zijn van jou; de echo maakt je combo af. Een **opgeladen slag** van je echo werkt als lancering. | **Merk-combo:** de een zet het merk, de ander laat het knallen (extra schade en licht). De gedeelde echo verschijnt alleen als **finisher**. |
| **Licht oppompen** (kernloop) | Flow vult je **lichtmeter**: treffers, ontploffingen en sprongketens zonder de grond te raken. Bij een **gemaal** pomp je dat licht de stad in. Het water zakt, een wijk gaat aan, nieuwe routes gaan open. | Eén gedeelde meter die door allebei gevuld wordt. Oppompen doe je samen. |
| **Groei** (metroidvania-vaardigheden) | Elke vaardigheid is beweging of gevecht die de echo versterkt, bijvoorbeeld een dash die de echo herhaalt als snijlijn. Uitwerking door de LGD en de Systems Designer. | Dezelfde vaardigheden voor beide spelers. |

De precieze regels zijn van de Lead Game Designer (`docs/design/gdd.md`, `kernloop.md`). Wat er in die regels moet veranderen, staat in §12. De voorbeelden hierboven zijn richting, geen specificatie.

## 4. Drie design pillars

Elke pillar heeft **één toetsvraag**. Een feature die op een pillar "nee" scoort, gaat niet in de kern van de game, of er moet een bewuste uitzondering voor worden genoemd. Een wijziging van deze pillars vraagt een CEO-besluit; v0.4 wijzigt pillar 1 en 3 en verschuift pillar 2 (§12), en hoort daarom bij #51 vraag 1.

**Wat we onder "puzzel" verstaan** (nodig voor de toets): een plek waar je pas verder komt nadat je **stilstaat om een volgorde of timing te bedenken**. Een moeilijke sprong, een gevecht of een route die je moet vinden, is geen puzzel.

### Pillar 1: De echo houdt je in beweging

De echo is een volwaardig tweede lichaam, maar hij werkt mee in je ritme en niet in een raadsel: hij is je springplank, je tweede slag en je ketting. Beweging en gevecht moeten **satisfying** voelen: strak, met gewicht, zonder stilstand. **Op de kritieke route staan geen puzzels.** Optionele uitdagingen met de echo mogen wel, maar alleen als ze ook in beweging gebeuren, zoals een springparcours of een tijdrit.

**Toetsvraag:** *Maakt de echo deze actie vloeiender of krachtiger, zonder dat de speler ervoor moet stilstaan?*

**Is de echo verplicht? Op de route niet, bij bosses wel** (keuze van de CEO, #54). Op de route maken springplank, lancering, vangen en merk je **sneller, hoger en sterker**, maar ze zijn **nooit een slot**: elke weg op de kritieke route is ook zonder te halen, alleen langzamer. **Bosses** zijn gebouwd om samen, of met je echo, te winnen: een pantser breekt alleen door een merk-ontploffing, en een hoge zwakke plek haal je alleen met een bounce of een lancering. Ook dat is **geen puzzel** volgens de definitie hierboven, want je doet het in beweging tijdens het gevecht. **Toets voor de LGD:** elke verplichte boss-actie haalt norm (1) (≤ ± 5 s stilstand), met ruime timingvensters (≥ 10 frames) en duidelijke feedback (geluid, schermschok, licht). **Tegenmaatregel tegen een passieve echo op de route (R-V2):** de echo moet lonen. Bounce- en lanceerketens vullen de lichtmeter sneller (dus eerder oppompen), kortere wegen en verzamelobjecten liggen hoog of ver (te halen met een bounce of lancering), en norm (2) wordt gemeten.

**Meetbaar in de slice** (normen, waarden stelt de LGD vast): (1) op de kritieke route staat een geoefende speler nergens langer dan ± 5 s stil om iets uit te zoeken; (2) de speler gebruikt de echo als springplank of merk-afmaker minstens ± 1× per 20 s gewoon spel; (3) playtest-score "voelde het vloeiend/satisfying?" gemiddeld ≥ 4 op 5.

| Past | Past niet |
|---|---|
| Afzetten van je echo (of je partner) houdt je vaart en geeft je dash terug | Een kamer waarin je een reeks schakelaars in de juiste volgorde moet zetten (puzzel op de kritieke route) |
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

### Pillar 3: Samen bewegen = sterker bewegen

Solo en co-op zijn dezelfde game in dezelfde kamers met dezelfde regels. Er is **één rol**, en die speelt in co-op je **partner** en solo je **echo** (staart van 1 s). Elke samenwerkingsactie bestaat dus in beide vormen:

| Actie | Co-op (partner) | Solo (echo) |
|---|---|---|
| **Bounce** | Spring op het hoofd van de ander: een hoge sprong + dash-reset | Spring op je echo |
| **Lancering** | De een houdt een aanval vast, de ander stapt erop en wordt weggeslingerd (lichtgat, kloof) | Een opgeladen slag van je echo slingert je weg |
| **Merk-combo** | De een zet het merk, de ander laat het knallen (extra schade + licht) | Je echo laat je merk knallen |
| **Vangen** | Val bij de ander, die vangt je en zwiept je omhoog (afgronden, boss-slagen ontwijken) | Je echo vangt je op je pad van 1 s geleden |

Samenwerken is **optioneel op de route** (sneller, hoger, sterker; nooit een slot) en **verplicht bij bosses**. In co-op heeft **niemand een eigen echo**: de partner ís de echo. Er zijn dus nooit meer dan twee lichamen, plus de **gedeelde echo als finisher** (§5). Er is geen aparte co-op-campagne, geen co-op-only content op de kritieke route en geen solo-versie van een kamer. Deze vorm is besloten (#51: 7A).

**Toetsvraag:** *Werkt deze actie zowel met een partner (co-op) als met je echo (solo), in dezelfde kamer zonder aparte versie?*

| Past | Past niet |
|---|---|
| Een hoge richel die je haalt met een bounce, op je partner of op je echo | Een plek die alleen met twee echte spelers te halen is (op de kritieke route) |
| Drop-in/drop-out zonder kamer-reset | Een co-op-modus met een eigen wereld, eigen levels of eigen progressie |
| Een gedeelde camera die beide spelers in beeld houdt | Split-screen (botst met gedeelde camera en lokale co-op) |
| Een boss met een pantser dat alleen een merk-combo breekt, solo én samen | Een co-op-actie zonder solo-vorm, of content achter een co-op-only gate |

## 5. Solo en co-op, uitgeschreven

**Solo.** Je speelt de jonge machinist (§6). Je schaduw, de sluiswachter, volgt je met een korte staart van 1 s (#51: 8A; CEO 2026-11-12) en doet wat jij deed, in de schaduwlaag. Hij is je springplank waar jij net was, en hij maakt je merken af waar jij net sloeg. Dat er geen puzzels zijn, betekent niet dat je niet nadenkt. Je denkt in beweging: "spring ik hier hoog over de afgrond en haal ik de overkant niet, dan loopt mijn schaduw een tel later door de lucht waar ik sprong en land ik op hem."

**Waar de echo vóór of onder je uitkomt, zonder wachten.** In een rechte voorwaartse run ligt de echo achter je. Daar dient hij niet als springplank maar voor je tweede slag en de ketting van merken. Dat is een bewuste keuze, geen gat. Vóór of onder je komt hij uit:
- **omhoog** (schachten, muren, wenteltrappen van belforten): wat je net onder je liet, staat een tel later onder je;
- **keren** (arena's, gevechten): wie omdraait, rent zijn echo tegemoet en zet zich van hem af. Dit is het kernritme van gevechten;
- **vallen** (afgronden): mis je een sprong, dan kan je echo je opvangen op het pad dat je net door de lucht aflegde;
- **lussen en terugkeerroutes**: de stad is gebouwd in rondgangen (grachten, ringdijken, omgangen van belforten), zodat een route je over je eigen spoor terugvoert.

Met de korte staart gebeurt dit binnen een tel, dus ruim binnen norm (1) van pillar 1. Bij 10 s (het verworpen alternatief 8B) kon het alleen in lussen en lange schachten waar je 10 s later terug bent, en moesten de levels om de echo heen gebouwd worden (R-V12).

**Bij 1 s: omhoog en keren dragen, vallen en lussen niet als bouwsteen (O-22, beslist door de CD).** In 1 s loop je ± 120 px. Een lus met een gat dat je zonder echo niet haalt (B3) en een terugvalbocht (B5) passen daar niet in (`gdd.md` §4.8.2). Wat dat betekent:
- **Voor de pillars en de kernfantasie is het niet erg.** De toetsvraag van pillar 1 gaat over vloeiender zonder stilstand, niet over het aantal routevormen. Omhoog en keren blijven, en bij 1 s zijn ze meteen raak: je wacht hooguit een tel. Keren is het kernritme van gevechten. De vier **acties** (bounce, lancering, merk, vangen) blijven allemaal; de variatie komt uit de acties en de merk-arena's, niet uit de vorm van de route. "Een bondgenoot die ik zelf ben" hangt niet aan lussen.
- **Wat er verandert is de belofte van §5.** Bij 1 s *is* een lus een keerpunt in de hoogte: wie over zijn eigen spoor terugkomt, doet dat binnen een tel alleen door om te draaien. Dat is wat B3 bij D = 60 al wordt (keren naar de galerij). Er komt **geen nieuwe lusvorm** bij: een korte lus zonder gat zou keren of omhoog met een andere naam zijn, en kost layoutwerk zonder nieuw gevoel. De LGD mag in S2 wel een B3-keerpunt met galerij gebruiken, als echo-kans.
- **Rondgangen blijven in de wereld**, als metroidvania-structuur (kortere wegen terug, een wijk die je na het oppompen opnieuw doorloopt) en als decor voor de bevroren echo's. Ze zijn alleen geen echo-moment meer.
- **Vallen** blijft een vangnet dat gewoon gebeurt en geteld wordt (O-11), geen bouwsteen.
- **Omkeerbaar.** B3 en B5 staan als formule van D in data (`max(D − 60, 0)`, L-09). Komt D later op 90 of hoger, dan komen de lus en de terugvalbocht terug zonder nieuw ontwerp.
- **Wat ik wil zien (geen norm):** in MT2 laat de LGD per wijk zien welke echo-acties de speler gebruikt. Bestaat de slice bijna alleen uit "keren en bouncen", dan zoek ik met de LGD meer variatie in de acties (lancering, merk in beweging), niet in lussen.

Wat de flow niet mag breken (richting voor de LGD): de echo **volgt je door een deur** in plaats van na elke kamerwissel even weg te zijn (was `gdd.md` O-5), en op je echo staan laat hem **niet** breken (§12).

**Co-op (lokaal, gedeelde camera, drop-in/drop-out).** De CEO wil co-op, maar is niet overtuigd van "speler 2 = de echo" (v0.3), van "co-op als bonus" en van "speler 2 draagt het licht". Zijn voorkeur, uitgewerkt door de LGD (#54, ronde 3), is **"samen bewegen = sterker bewegen"** (pillar 3).

- **A. Samen bewegen = sterker bewegen (besloten, #51: 7A).** Beide spelers spelen live. Speler 1 is de machinist; speler 2 is de **sluiswachter die weer uit zichzelf beweegt**. Ze doen elkaar wat solo de echo doet: bounce, lancering, merk-combo en vangen (pillar 3). **Niemand heeft een eigen echo**: de partner ís de echo. Er zijn dus max. **twee lichamen**, plus de **gedeelde echo als finisher**: een echo van jullie samen speelt **jullie laatste 10 s samen** af als finisher (8A). **Wie is de gedeelde echo?** Geen derde persoon, maar het **gemaal dat herinnert**: een schim van machinist en sluiswachter samen, half licht en half schaduw. Iedereen kan alles ook alleen, alleen langzamer. Zo hoeft de een niet op de ander te wachten.
  *Waarom gekozen:* het is de voorkeur van de CEO. Solo en co-op delen letterlijk dezelfde vier acties. Het blijft bij twee lichamen (het best leesbaar en het lichtst voor de Steam Deck). De minder ervaren speler heeft altijd iets te doen: opvangen, lanceren, merken.
  *Kost:* C-01 blijft in de kern (twee lichamen), maar P2 neemt niet meer de rol van de echo over. Nieuwe regels voor de vier acties in beide vormen, de finisher en de feedback: LGD ± 1 (vier acties, solo-vormen, vensters ≥ 10 frames), Combat Designer ± 0,5 (merk-combo, bosses), UX ± 0,5 (feedback, camera), TD ± 0,5 (finisher, drop-in/out): **± 2,5 run**; code in de slice ± 1–2 runs. Volgens de LGD eerst bounce en lancering prototypen.
- **B. Gedeelde echo als kern (verworpen alternatief, 7B).** Beide spelers spelen live en zijn elkaars springplank. Eén gedeelde echo verzamelt de merken van allebei en laat ze bij een volle gedeelde lichtmeter in een finisher van ± 2 s ontploffen, met de samengevoegde treffers van jullie laatste 10 s. Er zijn geen aparte samenwerkingsacties.
  *Kost:* ± 2,5 run regels + ± 1–2 runs code, dus vergelijkbaar. Maar er zijn kort drie figuren in beeld (leesbaarheid, R-V6). Solo en co-op delen minder: de finisher is het enige gezamenlijke moment, en de route kent geen echte samenwerking.

Wat uit v0.3 blijft: drop-in/drop-out zonder kamer-reset (C-03, C-05, aangepast aan de vorm), de schaduwspeler die niet doodgaat maar oplost en terugkomt (C-06), een gedeelde camera, en geen co-op-only content (L-02). Of de leiband van C-07 blijft, beslissen de LGD en de UX Designer in T3. Omdat iedereen alles alleen kan, is die minder nodig.

**Waarom dit werkt voor de doelgroep:** de solo-speler krijgt een vloeiende actie-metroidvania met een eigen idee. Het bankduo krijgt een spel waarin de minder ervaren speler live meedoet, vergevingsgezind faalt, zijn partner opvangt en lanceert, en met de gezamenlijke finisher een groot moment mee kan maken.

## 6. Toon, setting en verhaal

**Duister maar niet gruwelijk; melancholisch, niet wanhopig.** Doel: **PEGI 12** (CEO-besluit #2).

### Setting: de gedroomde verzonken stad en de poldermachine

Een stad in de **Lage Landen** die in een droom onder water is gelopen, gecombineerd met de **verlaten poldermachine** die haar droog moet houden (#54).
- **Stad:** belforten die half onder water staan, grachten, een begijnhof, dijken. Het licht verwijst naar de **Vlaamse Primitieven**: helder, warm, gedetailleerd licht dat schaars is in het donker. Het **carillon** is het ritme van de echo, en kan in de muziek de maat van de staart en van de tien seconden slaan (richting voor de Audio Director).
- **Machine:** gemalen, sluizen, schoepenraderen en pompen. Hier pomp je licht in en zakt het water (pillar 2). Bossidee van de Combat Designer: **de Gemaalmeester**, een levende poldermachine.
- **Van grijs naar kleur** (idee van de CEO, #54): in het begin is de wereld donker en zijn alle kamers grijs. Pomp je licht terug, dan komt er een kleurrijke, levende stad terug, wijk voor wijk. **Ook je echo is eerst grijs en somber** en leeft mee op naarmate het licht terugkomt. Dat is de sluiswachter die weer tot leven komt (V2). Eis voor de Art Director: een grijze echo in een grijze wereld blijft scherp leesbaar door silhouet, contour en beweging, ook op de Steam Deck (R-V6).
- **De bevroren echo's:** overal in de stad staan de laatste 10 seconden van de bewoners, stilgezet in schaduw: een bakker die een brood aanreikt, kinderen die naar het carillon kijken. Dit is **sfeer en verhaal, geen puzzel**. Hooguit dient een bevroren echo als springplank of oriëntatiepunt.
- Dit is ook het **tweede culturele criterium** voor het VAF (#51, 5A; `subsidies.md`), zonder dat het de pillars raakt.

### Verhaalpremisse V2: "Het gemaal van herinneringen"

Je bent de **jonge machinist** van de poldermachine. Je schaduw ís de **sluiswachter**: de man die ooit het water binnenliet en die nu alleen nog kan herhalen wat een ander doet. Gaandeweg ontdek je wie hij was en waarom het water kwam. Aan het einde krijgt hij zijn eigen tien seconden terug en laat hij los. De mechaniek is het thema: de echo kan alleen herhalen, en het verhaal gaat over het moment waarop dat niet meer hoeft. In co-op (variant A) is speler 2 de sluiswachter die weer uit zichzelf beweegt en de machinist opvangt en lanceert. Dat is de droom die het einde al even laat voelen. De uitwerking is van de Narrative Designer (T9); ik review haar.

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
- **Combat leesbaar:** merk, ontploffing en parade lezen in één frame, ook met twee spelers en de finisher in beeld (Art Director, Combat Designer).
- **Sfeer zonder de leesbaarheid te raken:** volumetrisch licht, water en diepte alleen in de achtergrond en de parallax-lagen; het speelvlak blijft strak.

### Naam en toon

De werktitel *Polderlight* (besluit #96) betekent het licht dat in de polder terugkomt, wijk voor wijk van grijs naar kleur. Hij draagt pillar 2 en de Lage Landen, en is warmer dan *Wraithstep*. Het risico draait daarmee om: de naam kan **lichter** lezen dan de game (een gezellige polder- of bouwgame), terwijl de game melancholisch begint, in het donker.
- **Het donker eerst, het licht als beloning.** Logo, key art en storetekst tonen de grijze, verzonken stad en het eerste licht dat terugkomt, niet een zonnige polder. Geen horrorbeeld: geen schedels, bloed of verdronken figuren. Wel: stilte, harde lichtbanden, water, het holle silhouet van de echo.
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

1. **Een metroidvania waarin je schaduw je bondgenoot in beweging is.** Je echo is je springplank en je tweede slag. Samenwerken met een opname van jezelf bestaat in puzzelgames (sinds *Chronotron* en *Braid*, 2008) en in een run-and-gun (*Super Time Force*). Het onderscheid zit in de **combinatie**: we vonden geen metroidvania die een vertraagde kopie van de speler als kern van beweging, gevecht én voortgang gebruikt (`docs/business/naamcheck.md` §3, peildatum 2026-11-08). Het dichtst bij de regel ligt *Echo Shift* (echo's van je laatste 15 s), maar dat is een first-person puzzelgame zonder gevecht. v0.4 staat daar verder van af: geen puzzels, een gevechts-metroidvania, en een korte staart (#51: 8A). We claimen daarom nergens "de eerste". De ideecheck moet opnieuw voor de nieuwe vorm (R-V9).
2. **Licht terugwinnen als motor van de wereld.** Goed spelen vult je lichtmeter; bij een gemaal pomp je licht de stad in en zie je de wereld veranderen: het water zakt, wijken gaan aan. Elke voortgang voel je in de stad zelf.
3. **Een eigen, Laag-Landse wereld.** Een gedroomde verzonken stad met belforten, polders en gemalen, en licht naar de Vlaamse Primitieven. Dat zie je zelden in het genre.
4. **Lokale bank-co-op: samen bewegen = sterker bewegen** (besloten, #51: 7A). Beide spelers spelen live en doen elkaar wat solo de echo doet: bounce, lancering, merk-combo, vangen. *Aanname:* de doelgroep (koppels, vrienden) vraagt erom; marktonderbouwing volgt van Marketing.
5. **Behapbaar en vriendelijk:** 5–7 uur, 3–4 gebieden, 4–5 bosses, ongeveer €20 eenmalig zonder microtransacties (CEO-besluit #2). Uit te spelen in een paar avonden, toegankelijk voor een minder ervaren co-op-partner.

## 9. Doelgroep en bereik

Leeftijd 18–30, pc via Steam, Steam Deck verified als doel. Engels bij launch, Nederlands in principe ook (besluit #51, 5A). Twee kernspelers:

| Speler | Wie | Wat ze zoeken | Wat ze in *Polderlight* vinden |
|---|---|---|---|
| **De genrefan** | Speelde *Hollow Knight*, *Nine Sols*, *Ori*; speelt vooral solo, kijkt naar gevoel, combat en sfeer | Een metroidvania met een eigen idee, strak gevoel, sterke bosses | Een eigen draai op beweging en gevecht in een kortere game dan de grote titels; solo ook op de Steam Deck |
| **Het bankduo** | Koppel of vrienden, vaak één ervaren en één minder ervaren speler | Iets dat ze samen kunnen spelen waarin allebei iets te doen hebben | Beide live, een vergevingsgezinde schaduwrol en een gezamenlijke finisher; drop-in/drop-out op **pc aan de tv** met twee controllers |

**Co-op-situatie:** de hoofdsituatie voor co-op is **pc aan de tv**. Co-op op één Steam Deck-scherm met een gedeelde camera is krap, zeker met een derde figuur in beeld; dat claimen we niet tot de UX Designer en de Technical Director het getoetst hebben. Tot dan noemt Marketing de Deck alleen voor solo.

*Aanname, nog niet onderbouwd:* het bankduo is groot genoeg om co-op als tweede verkoopargument te dragen. Marketing kan dit toetsen. Door de keuze voor combat à la *Hollow Knight*/*Nine Sols* ligt het zwaartepunt nu meer bij de genrefan; het bankduo vraagt dan een goede toegankelijkheid (vergevingsgezinde schaduwrol, assist-opties).

## 10. Risico's voor de visie

Nummering: R-V = visierisico in dit document; de R-nummers uit `docs/productie/risico.md` staan erbij waar ze overeenkomen. De Producer werkt `risico.md` bij na het conceptbesluit.

| # | Risico | Waarom het de visie raakt | Wie | Voorstel |
|---|---|---|---|---|
| R-V1 (R9) | **De echo-duur klopt niet.** Bij 10 s voelt een merk dat pas later ontploft los van je slag, en ligt de springplank te vaak achter je; bij een te korte staart lijkt de echo een nabeeld in plaats van een tweede lichaam | De draai hangt aan die ene waarde | LGD, Combat Designer, QA Lead | **Besloten:** korte staart (#51: 8A), **1 s** als werkaanname (CEO 2026-11-12, bereik 1–3 s). Het merk-deel van het risico is kleiner geworden (de echo knalt het merk ± 1 s na je slag). Het **nabeeld**-deel is nu het grootste: bij 1 s loopt de echo hooguit ± 120 px achter je en staat hij een tel na je stilstaan op je. **MT1 moet laten zien dat hij een tweede lichaam is:** (a) *gedrag:* de CEO gebruikt de echo als plank op de keerpunten van K1 (in F0-2 run 1 en 2: 0 keer), en MP-2 haalt ≥ 3 per minuut, ook per kamer; (b) *lezing:* één open vraag op de kaart, vóór H: "Wat was je schaduw voor jou: iemand die meedeed, of een spoor achter je aan?", met H ≥ 4. Geen tweede staart in MT1 (geen aparte check, besluit 2026-11-12). **Leest hij als spoor**, dan eerst art (Art Director: de 2 nabeelden van de echo, bible §6, maken hem bij 1 s eerder een spoor; een scherper hol silhouet en een eigen klank bij contact), daarna een voorstel van de LGD aan de CEO voor D = 90 (binnen het bereik; 1,5 s scoorde in F0-2 het hoogst). Het merk toont zijn aftelling in beeld en geluid (het carillon). |
| R-V2 | **Zonder puzzels wordt de echo passief**, een automatische buff waar je niet over nadenkt, zeker nu samenwerken op de route optioneel is | Pillar 1: dan is het geen tweede lichaam meer | LGD, World & Level Designer | Verplicht bij bosses, getoetst tegen de puzzeldefinitie en norm (1). Op de route moet de echo lonen: bounce- en lanceerketens vullen de lichtmeter sneller, en kortere wegen en verzamelobjecten liggen hoog of ver. Meten met norm (2) van pillar 1 in de flow-kamer. |
| R-V3 (R12) | **De echo is te vaak "leeg"** | Elke lege seconde is een gebroken ketting | LGD, TD | De echo volgt je door deuren (O-5 wordt de regel, §12). Op je echo staan breekt hem niet meer. |
| R-V4 (R20) | **Combat-zwaar is duurder dan puzzels.** Meer vijandtypes, animatie, hitfeedback en bosses om *Hollow Knight*-gevoel te halen | Scope binnen 5–7 uur en het budget per fase | EP, Combat Designer, Art Director | **Scopeplafond voor F6:** max. **4 nieuwe vijandtypes per gebied** (max. 14 in totaal, inclusief varianten), max. **1 minibaas per gebied**, en 4–5 bosses (besluit #2). De slice meet de kost per vijandtype en per boss (F6) tegen dit plafond. Weinig types die veel kunnen (merk, parade). Reken erop dat fase 3–4 duurder worden dan bij een puzzelgame. |
| R-V5 (R10, herzien) | **Co-op wordt chaos, te makkelijk, of de een wacht op de ander.** Solo kan de balans scheef lopen tegenover een live partner | Pillar 3 | LGD, Combat Designer | Co-op ≤ 2× zo snel als solo blijft de grens. Iedereen kan alles alleen, alleen langzamer, dus niemand wacht. De staartlengte (bereik 1–3 s, nu 1 s) is de knop voor de solo-balans. Ruime vensters (≥ 10 frames). Testen in beide modi vanaf het eerste prototype, bounce en lancering eerst. |
| R-V6 (R2) | **Twee figuren plus finisher, water, merken en ontploffingen zijn niet leesbaar**, zeker een grijze echo in een grijze wereld (§6) | Pillar 2 valt dan om | Art Director | Art bible met de finisher-echo, het merk en de grijze beginstaat als eis. De finisher-echo speelt jullie laatste 10 s samen af (8A): tijdens die finisher staan er drie figuren in beeld, dus de finisher-echo moet in één oogopslag te onderscheiden zijn van beide spelers (UX, Combat Designer). Prestaties op de Steam Deck (Technical Artist, Engine & Platform Programmer). |
| R-V7 | **Verdrinken raakt PEGI 12 of het publiek** | Een verzonken stad kan als ramp of dood lezen | Narrative Designer, Art Director, CD | Toonregels in §6 (droom, geen lichamen, geen echte watersnood). Elke scène met water langs de toets "duister maar niet gruwelijk". |
| R-V8 | **5–7 uur is kort voor een metroidvania** | De echo moet binnen minuten dragen | LGD, World & Level Designer | Springplank en merk zitten vanaf de proloog in de kern; elk gemaal verandert de stad zichtbaar. |
| R-V9 | **Het idee lijkt sterk op een bestaande game.** Het schaduwmerk ligt dicht bij de lading-en-ontploffing in *Nine Sols*. *Echo Shift* ("laatste 15 seconden") ligt dicht bij de regel. | USP 1 | Business/Legal (#8) | Ideecheck herhalen voor de nieuwe vorm (springplank, merk, oppompen) **vóór T3 het schaduwmerk (E-14) en de merksprong vastlegt, en vóór de flow-kamer**: dan is bijsturen nog goedkoop. Verschil met *Nine Sols*: de echo zelf brengt het merk tot ontploffing, op jouw route van zonet. Verschil met *Echo Shift* (first-person puzzel, geen gevecht): v0.4 staat er verder van af dan v0.3, want er zijn geen puzzels, het is een gevechts-metroidvania, en er geldt een korte staart (#51: 8A) in plaats van een lange opname. |
| R-V12 | **De springplank ligt achter je.** In een voorwaartse run staat de echo achter je, dus als springplank werkt hij alleen bij klimmen, keren, vallen en lussen (§5) | Pillar 1: "springplank" belooft meer dan de beweging geeft | LGD, World & Level Designer | Korte staart (1 s) en de situaties uit §5 als levelregel; bij 1 s dragen omhoog en keren, lussen en vallen zijn geen bouwsteen (O-22, §5). **Meetpunt in de flow-kamer:** springplank-gebruik per minuut en het aandeel daarvan dat zonder stilstand (norm 1) lukt. Haalt de flow-kamer norm (2) niet, dan volgt eerst herontwerp en daarna een nieuwe vraag aan de CEO. |
| R-V10 (R15) | **De naam leest anders dan de game.** Met *Polderlight* niet meer te duister, eerder te licht (gezellige poldergame) | Verwachting van de genrefan | CD, Marketing | Regels en toets in §6 "Naam en toon": het donker eerst, het licht als beloning. Bij een **concept voor een publieke uiting** dat de toon toch raakt: nieuwe naamvraag aan de CEO vóór de betaalde merkcheck. |
| R-V11 (R24) | **De naam is slecht vindbaar.** Op 2026-11-09: 0 games op Steam, maar in NL/BE staat het bordspel *Polders* bovenaan bij "polder… game" (besluit #96) | Vindbaarheid | Marketing, Business/Legal | Zie §11 vraag 4. |

## 11. Open vragen

| # | Vraag | Richting CD | Eigenaar | Stand |
|---|---|---|---|---|
| 1 | Wat gebeurt er met de echo als speler 2 meedoet? | v0.3: speler 2 *wordt* de echo. v0.4: **samen bewegen = sterker bewegen**; niemand heeft een eigen echo, de gedeelde echo is alleen de finisher en speelt jullie laatste 10 s samen af. Verworpen alternatief (7B): gedeelde echo als kern (§5). | CEO, uitwerking LGD | **Besloten (#51: 7A)**; uitwerking in C-01 (§12) |
| 2 | **Ankeren:** mag de speler later de herhaling vastzetten? | Alleen als het de flow helpt (bv. een vaste springplank in een lange schacht), niet als puzzelgereedschap. | LGD, Systems Designer | Open (O-3), herzien bij §3 van de gdd |
| 3 | **Falen in co-op:** kan de schaduwspeler doodgaan? | Nee, hij lost op en keert terug (C-02, C-06). Geldt in de gekozen co-op-vorm (7A). | LGD, UX Designer | Gesloten |
| 4 | **Titel:** wordt *Polderlight* de definitieve naam? | Als werktitel goed (pillar 2, Lage Landen, toon). Eerst TMview/WIPO en de korte merkcheck met de NL/BE-ranking en *Polders*; dan de formele merkcheck door een specialist vóór de eerste publicatie. Een andere naam is een CEO-besluit. | Business/Legal, Marketing, CD | Werktitel besloten (#96, vervangt *Wraithstep*); merkcheck volgens #96 en #24 (3A) |
| 5 | **Opnamemodel:** posities of inputs? | Toestandsopname blijft (`gdd.md` §2.2). Nieuw is één uitzondering: de **merksprong**, waarbij de echo van zijn pad afwijkt naar een merk binnen een straal (§12). | LGD, TD | Gesloten voor v0.3; merksprong nieuw (§12) |
| 6 | **Drop-out zonder staart** | Niets verzinnen: liever even een lege schaduw. | LGD | Gesloten (C-05); toetsen bij de uitwerking van 7A (C-01–C-05) |
| 7 | **Lichtmeter:** is het dezelfde meter voor genezen en oppompen? | Ja, dat geeft spanning (nu genezen of bewaren voor de stad). Maar een gemaal mag een zwakke speler nooit laten vastlopen: de meter vult snel in flow, er is geen grind. | LGD, Systems Designer | Nieuw |
| 8 | **Optionele echo-uitdagingen:** horen ze erin? | Ja, als ze in beweging gebeuren (springparcours, tijdrit), nooit op de kritieke route, en alleen als de scope het toelaat. | LGD, World & Level Designer | Nieuw |
| 9 | **Lussen en terugvallen bij D = 60** (`gdd.md` O-22) | Geen eigen bouwsteen in de slice; geen nieuwe lusvorm; B3 als keerpunt met galerij mag als echo-kans; komt terug via data als D ≥ 90 (§5) | CD, LGD | **Beslist door de CD (v0.5)**; opnieuw na MT2 of bij een andere D |

Vraag 1 raakt pillar 3 en is door de CEO besloten (#51: 7A). De echo-duur is eveneens door de CEO besloten: korte staart (#51: 8A), sinds 2026-11-12 **1 s, bereik 1–3 s**; de 10 s blijven in verhaal, einde en co-op-finisher. Vragen 2, 5, 7 en 8 beslis ik binnen de pillars met de vakrollen. Als een uitkomst een pillar zou veranderen, gaat het als `ceo-beslissing` naar de CEO.

## 12. Wat er verandert t.o.v. v0.3

Kost in **runs** (één maak-taak van een rol). "In T3" betekent: past in GDD v1, die in het fasekader van fase 2 al gepland staat (`fase-2-kader.md` T3). Code in `game/` schuift mee met T4, T5 en T8.

### Per pillar

| Pillar | v0.3 | v0.4 | Gevolg |
|---|---|---|---|
| **P1** | *De echo is je tweede lichaam*; het slimme gevoel komt uit plannen; puzzels op de kritieke route (max. 10 per gebied, `kernloop.md` §5) | *De echo houdt je in beweging*; springplank en schaduwmerk; **0 puzzels op de kritieke route**; toetsbaar met een toetsvraag en drie normen | Kernloop, testkamers en vaardigheden herzien |
| **P2** | *Licht en schaduw zijn de kaart*; gating via licht/schaduw/echo, ook als raadsel (lampbrug) | *Licht terugwinnen opent de stad*; lichtmeter, gemalen, waterstand; gating via vaardigheden en routes, geen raadsels | Nieuw systeem: lichtmeter + gemaal + waterstand |
| **P3** | Speler 2 *is* de echo; solo plannen vs. co-op afstemmen | *Samen bewegen = sterker bewegen*: één rol (partner in co-op, echo solo), vier acties (bounce, lancering, merk-combo, vangen); optioneel op de route, verplicht bij bosses; gedeelde echo alleen als finisher (besloten, #51: 7A) | C-01 en de co-op-regels herzien |

### Per gdd-regel (`docs/design/gdd.md` v0.2)

| Regel | Was | Wordt (richting; de LGD schrijft de regel en de test) | Kost |
|---|---|---|---|
| **E-04a** | Kamerwissel zet de echo 10 s op Leeg | **Vervalt als reset.** De echo volgt je door een deur naar een aangrenzende kamer (was O-5); een reset alleen bij een niet-aangrenzende kamer, respawn, Loslaten of breken | LGD 0,5 (in T3) + TD/GP 1 (AreaLoader, in T5) |
| **E-07a** | P1 beweegt mee op de echo maar krijgt **geen** snelheid mee | **Springplank:** P1 behoudt zijn eigen vaart bij landen of afzetten, en krijgt zijn dash (en eventuele luchtsprong) terug. Bewegen met de plank blijft | LGD 0,5 (in T3) + GP 0,5 |
| **E-08b** (steuncontrole) | Steunde P1 op een schaduwlichaam, dan breekt de echo 10 s later op dat punt | **Vervalt voor steun op een schaduwlichaam.** De echo valt of zweeft door die frames heen zonder te breken; anders breekt elke springplank-ketting zichzelf | LGD 0,25 (in T3) + GP 0,25 |
| **E-14** | Echo-treffer doet 100 % van de treffer van P1 | **Schaduwmerk:** een treffer van P1 zet een merk; de echo-treffer laat merken ontploffen (schade en stapelen: Combat Designer). De echo blijft onkwetsbaar | Combat Designer 1 (in T3) |
| **E-02** (duur) | D = 600 ticks (10 s) | **Korte staart:** D = 60 ticks (1 s; bereik 60–180), als één waarde in data (CEO 2026-11-12; was in v0.4 ± 120, bereik 90–180, met een test van 1,5, 2 en 3 s) | LGD 0,25 (in T3) + GP 0,25 |
| **E-02** (nieuwe uitzondering) | De echo staat altijd op de opgenomen positie | **Merksprong:** op het moment van een opgenomen treffer mag de echo binnen een straal naar het dichtstbijzijnde merk schieten. Dit is de enige afwijking van het pad, en daarna keert hij terug op zijn opname | LGD + Combat 0,5 (in T3) + GP 0,5 |
| **C-01** | Max. twee lichamen; P2 vervangt de echo | Max. twee lichamen (P1 + P2, geen eigen echo), plus de gedeelde echo alleen als finisher, die jullie laatste 10 s samen afspeelt (8A); nieuwe regels voor bounce, lancering, merk-combo en vangen in beide vormen (besloten, #51: 7A; 7B verworpen) | ± 2,5 (§5) |
| **C-02–C-05** | P2 neemt de echo over bij drop-in, de echo neemt over bij drop-out | Aanpassen aan 7A; C-06 en C-07 blijven | In de kost van C-01 |
| **Tweeslagschild** (testkamer T5, venster in §2.9) | Vijand met een venster van 15 ticks voor jou + echo | **Vervalt** (dwingt wachten); vervangen door merk-vijanden | In T3 |
| **L-01, L-04, L-05, L-06** | Regels voor echo-puzzelkamers | **Herzien of vervallen**; nieuwe levelregels voor sprongketens, merk-arena's en gemaal-wijken | World & Level Designer 1 (in T3) |
| **`gdd.md` §3** (Dempen, Dragen, Ankeren, Terugstappen) | Vooral puzzelgereedschap | Herzien naar beweging/gevecht die de echo versterkt; Terugstappen kan blijven als ontsnapping in combat | Systems Designer 1 (in T3) |
| **Testkamers T1–T5, V1** (§4.2) | Puzzelkamers | Herzien naar flow-kamers: sprongketen, merk-arena, één gemaal | LGD 0,5 (in T3) |
| **Nieuw: lichtmeter + gemaal + waterstand** | Bestond niet | Nieuw systeem (pillar 2) | Systems/LGD 1 (in T3) + GP 1–2 (in T8) |

### Andere documenten (alleen via issues voor de eigenaar)

| Document | Wat | Eigenaar | Kost |
|---|---|---|---|
| `docs/design/kernloop.md` | Loop in één zin, max. 0 puzzelkamers op de kritieke route, K-04 (eindboss-poort zonder echo-puzzel), toets aan de nieuwe pillars | LGD | 1 (in T3) |
| `docs/productie/fase-2-kader.md` | Alle puzzelplekken: §1 vraag 1 ("of co-op de puzzels triviaal maakt"); T3 ("echo-puzzels" → flow-kamers, lichtmeter, gemaal); T4/T8 en de volgorde in §4 ("T4 vóór de echo-puzzels van T8"); T11 en F4 ("elke slice-puzzel" → "elke slice-kamer"; flownormen van P1 in plaats van R10-puzzels); F4b(b) ("buiten verplichte puzzels" → "buiten merk-ontploffingen", bv. het aandeel springplank-sprongen); R10 in §5. Slice = polderwijk met het eerste gemaal + de Gemaalmeester; **eerste mijlpaal is een grijze flow-kamer** (#51: 2A; "slice-art pas na een geslaagde flow-test" is vervangen door fase 2 parallel, besluit 2026-11-12) | EP | 0,5 |
| `docs/productie/risico.md` | R10 herzien; nieuwe risico's R-V2, R-V4, R-V7, R-V9 | Producer/EP | 0,25 |
| Narratief (T9) | Uitwerking V2 | Narrative Designer | 0 extra (T9 staat al gepland) |
| Art bible (T1) | Setting, water, merk en finisher-echo als leesbaarheidseis | Art Director | ± 0,5 extra |
| Ideecheck (`naamcheck.md` §3) | Herhalen voor de nieuwe vorm (R-V9) | Business/Legal | 0,5 |

**Totaal (opgeteld uit de twee tabellen hierboven, volgens besluit #51: co-op 7A, echo-duur 8A):**

| Post | Runs |
|---|---|
| Documenten binnen T3 (E-04a 0,5 · E-07a 0,5, incl. bounce · E-08b 0,25 · E-14 1 · E-02 duur 0,25 · E-02 merksprong 0,5 · L-regels 1 · §3 1 · testkamers 0,5 · lichtmeter 1 · kernloop 1) | ± 7,5 |
| Documenten buiten de planning (C-01 2,5 · fasekader 0,5 · risico 0,25 · art bible 0,5 · ideecheck 0,5) | ± 4,25 |
| **Documenten samen** | **± 11,75** |
| Code (E-04a 1 · E-07a 0,5 · E-08b 0,25 · E-02 duur 0,25 · E-02 merksprong 0,5 · lichtmeter 1–2 · C-01 1–2) | ± 4,5–6,5 |
| **v0.4-delta in totaal** | **± 16,25–18,25 (≈ 16–18)** |

We rekenen conservatief: het ontwerpwerk voor echo-puzzels dat in T3 en T8 vervalt, is **niet** afgetrokken. Een run telt hier als één maak-taak. Bestaande code in `game/` (de echo-spike en de E- en C-tests) blijft bruikbaar; de tests voor E-04a, E-07a, E-08b, E-14 en C-01 worden herschreven.

### Fase 2 volgens besluit #51 (1A, 2A) en de besluiten van 2026-11-12

- **Volgorde:** fase 2 startte met een **grijze flow-kamer** (2A). Sinds 2026-11-12 loopt fase 2 **parallel, ook bouwen**: de slice (polderwijk, eerste gemaal, Gemaalmeester) en slice-art wachten niet meer op een geslaagde flow-test. F0 (flow-kamer geslaagd) blijft een exit-criterium van de fase. Om weggooiwerk klein te houden: eerst placeholder, wat van D afhangt via data, eindkwaliteit-art pas op maatvaste kamers, met mijn `Visie-review: past` op pillar 1 per kamer (fasekader §4). Risico (benoemd door de CEO): werk kan weg als de echo of de kern nog verandert.
- **De CEO test alleen bij mijlpalen** (MT1 flow-kamer op D = 60, MT2 slice op placeholder, MT3 slice op eindkwaliteit; korte kaart van ± 10–15 min) als de bots groen zijn. Kleine aanpassingen test het team met de bots. Mijn visie-reviews (F0, F1, F7) kosten geen CEO-tijd.
- **Kost fase 2 (2A):** ≈ 61–88 maak-taken, € 0 extern. De v0.4-delta hierboven (≈ 16–18 runs, € 0; 1A) valt daarbinnen; de herraming staat in het fasekader (EP).

**Open punten:**
- De co-op-balans met de korte staart (solo-echo van 1 s naast een live partner, finisher van 10 s) meet de LGD in de slice; co-op hoort niet bij F0 (besluit #124) en komt in F4b(c) (MT3).
- R-V1 (nabeeld) en O-23 (vaart) hangen aan MT1 (§10).

## 13. Definition of Done

**#4 (v0.1), #15 (v0.2), #25 (v0.3):** afgerond; zie de gemergde PR's #11, #22 en #41.

**#191 (v0.5)**
- [x] Klopt met de besluiten van 2026-11-12: staart 1 s (D = 60), bereik 1–3 s (kop, §1, §3, §4 P3, §5, §10 R-V1 en R-V5, §11, §12 E-02); fase 2 parallel in plaats van "slice-art na een geslaagde flow-test" (§12); de CEO test alleen bij mijlpalen (§12, R-V1). Geen "± 2 s" of "1,5–3 s" meer als geldende waarde
- [x] O-22 beantwoord, binnen de pillars (§5, §11 vraag 9): geen eigen bouwsteen voor lussen en terugvallen in de slice, geen nieuwe lusvorm, omkeerbaar via data
- [x] R-V1 getoetst op 1 s, met wat MT1 moet laten zien (§10)
- [x] Werkaannames genoemd (kop, fasekader §5); werktitel *Polderlight* (#96) doorgevoerd
- [x] Geen CEO-vraag nodig: pillars en kernfantasie veranderen niet

**#55 (v0.4)**
- [x] Elk antwoord van de CEO uit #54 is terug te vinden: spelgevoel en referenties (§3, §7), geen puzzels (§4 P1), springplank (§3, §12 E-07a), schaduwmerk (§3, §12 E-14), licht oppompen (§3, §4 P2), gating zonder raadsels (§4 P2), V2 (§6), setting (§6), co-op "samen bewegen = sterker bewegen" (§5, besloten #51: 7A), de Gemaalmeester (§6)
- [x] Geen puzzels op de kritieke route; flow/satisfying is toetsbaar (toetsvraag en normen P1, §4)
- [x] Besluit #51 getrouw weergegeven: 1A concept definitief (statusregel), 2A grijze flow-kamer eerst, slice-art na een geslaagde flow-test, ≈ 61–88 maak-taken, € 0 (§12), 7A co-op (§3, §4 P3, §5, §8, §11, §12 C-01), 8A korte staart met de 10 s in verhaal, einde en co-op-finisher (§1, §5A, §10 R-V1, §12 E-02); 7B en 8B alleen als verworpen alternatief
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
| 0.5 | CEO-besluiten van 2026-11-12 verwerkt (#191): staart 1 s (D = 60) als werkaanname, bereik 1–3 s; fase 2 parallel, ook bouwen (wijzigt 2A); de CEO test alleen bij mijlpalen. O-22 beslist (§5, §11 vraag 9): bij 1 s dragen omhoog en keren, lussen en vallen zijn geen bouwsteen; rondgangen blijven als wereldstructuur. R-V1 herzien: het nabeeld-risico met de toets voor MT1 (§10). Werktitel *Polderlight* (#96) in kop, logline, §6 "Naam en toon", §9, R-V10, R-V11 en §11 vraag 4. Pillars en kernfantasie ongewijzigd. |
| 0.4 | Live brainstorm met de CEO (#54) verwerkt. Draai en kernfantasie in beweging ("springplank en tweede slag"); P1 *De echo houdt je in beweging* (geen puzzels op de kritieke route, toetsbare flownormen); P2 *Licht terugwinnen opent de stad* (lichtmeter, gemaal, waterstand; gating via vaardigheden en routes); P3 met co-op (later 7A, zie hieronder). Setting (gedroomde verzonken stad + poldermachine) en verhaalpremisse V2 in §6, met toonregels voor water (PEGI 12). Referenties: *Hollow Knight* en *Nine Sols* als hoofdreferentie. USP's, doelgroep en risico's herzien; nieuwe sectie §12 "Wat er verandert t.o.v. v0.3". Reviewpunten #43 verwerkt. Lead-review EP (PR #56): totalen §12 herrekend (documenten ± 11,5, code ± 4,25–6,25, samen ± 16–18), puzzelplekken in het fasekader benoemd, ideecheck R-V9 vóór T3, kost fase 3–4 bij R-V4, water als speellaag expliciet als afwijking van #54, open punt herraming volgens #52. Co-op ronde 3 (#54): P3 en §5 op "samen bewegen = sterker bewegen" (vraag 7A; de gedeelde echo als kern wordt 7B), samenwerken optioneel op de route en verplicht bij bosses (P1, R-V2), van grijs naar kleur voor wereld en echo (§6); kost §12 onveranderd. SM-review (PR #56): korte staart van ± 2 s met de 10 s in verhaal en finisher (later besloten als 8A), waar de echo vóór je uitkomt (§5) en R-V12 met een meetpunt; verlicht ≠ FelLicht (P2); springplank en merk verplicht op de kritieke route en getoetst tegen de puzzeldefinitie (P1, R-V2); *Echo Shift* in USP 1 en R-V9; wie de gedeelde echo is (§5A); scopeplafond combat (R-V4). **Definitief na besluit #51 (1A, 2A, 7A, 8A):** statusregel; besloten keuzes niet meer als open of aanbeveling (§1, §3, §4 P3, §5, §8 USP 4, §10, §11, §12); 7B en 8B alleen als verworpen alternatief; co-op-finisher speelt jullie laatste 10 s samen af (§5A, §12 C-01, R-V6); fase 2 met grijze flow-kamer eerst, slice-art na een geslaagde flow-test, ≈ 61–88 maak-taken, € 0 (§12); open punt co-op-balans met de korte staart. **Interne noot (was onder de logline, #43.3):** "melancholisch" in plaats van "duister" is bewust: de naam draagt het duister al, en de logline zet de schaduw neer als bondgenoot. |
| 0.3 | Werktitel *Wraithstep* (#24) doorgevoerd. Toon bij de naam: logline "melancholisch", blok "Naam en toon" in §6, twee risico's (toon R15, vindbaarheid). Reviewpunten PR #22 verwerkt. |
| 0.2 | Reviewpunten PR #11 verwerkt; randvoorwaarden #2 en stijl 2D (#18) doorgevoerd; open vragen als tabel. |
| 0.1 | Eerste versie (#4, PR #11). |
