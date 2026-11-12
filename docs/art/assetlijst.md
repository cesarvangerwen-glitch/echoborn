# Assetlijst v0

Versie 0.1 · Eigenaar: Art Director (prioriteit samen met de Producer) · Issue: #20 · Regels en maten: `docs/art/bible.md`

Wat de **grijze flow-kamer** en de **verticale slice** (polderwijk met het eerste gemaal en de Gemaalmeester) aan art nodig hebben. De inhoud van de slice ligt pas vast in GDD v1 (T3). Deze lijst volgt die inhoud en wordt dan bijgewerkt.

**Prioriteit**
- **P0**: flow-kamer. Placeholder mag (`_placeholder` in de bestandsnaam), maar wel met de juiste **maten, hitboxes en laag-taal** (licht/schaduw, vol/hol). Mag nu.
- **P1**: begin van de slice-art. Na F1 (gehaald, #65). Eindkwaliteit per kamer pas als die kamer **maatvast** is (fasekader v0.4 §4, regel 3; besluit 2026-11-12 (1) vervangt de eis van een geslaagde flow-test). Placeholder en wat niet van kamermaten afhangt mag nu (`docs/art/slice-kadewijk.md`).
- **P2**: maakt de slice af. Na P1.

**Eigenaars (rollen):** AD = Art Director · CA = Concept Artist · EA = 2D Environment Artist · AN = Animator · TA = Technical Artist · UI = UI Artist. De Art Director reviewt alles (interne review).

## 1. Flow-kamer (P0, placeholder)

Doel: de flownormen van pillar 1 meten (sprongketen, merk-arena, één gemaal). Grijs, maar de lagen moeten al leesbaar zijn, anders meet de test iets anders dan het spel.

| ID | Asset | Inhoud en maten | Eigenaar |
|---|---|---|---|
| F-01 | Tegelset grijs | 16×16: vloer, muur, platform, rand, hoek, schuin 45°. Alleen de grijze ramp *steen*, met voegen | EA |
| F-02 | Lichtgeometrie en schaduwgeometrie | Platform/brug in de vorm-taal van bible §4.4 (ivoor met maaswerk, paars gearceerd met ranken), plus de **opgeloste toestand** (niets, alleen een eindrand) | EA |
| F-03 | Lantaarn (verplaatsbaar) | Sprite ± 15×30 met haak en hengsel, kern, 3 halo-ringen, kruisstralen (bible §4.2); 2 frames flakkering | EA (met TA voor het licht) |
| F-04 | Gemaal (eenvoudig) | Pomp/rad als interactief punt, 2 toestanden (uit/aan); hoeft nog niet te draaien | EA |
| F-05 | Speler 1 | Idle, loop (4), sprong op/top/val (3), landing, aanval (3), dash (2), plus placeholder-poses voor samenwerken en de kernloop: **bounce** (afzet op echo/partner), **lancering** (opladen en weggeslingerd), **vangen** (gevangen en omhoog gezwiept), **merk-combo** (merk zetten, laten knallen) en **oppompen** (interactie bij het gemaal). Silhouet en kleuren uit `docs/art/r5-scene/bron/sprites.py` | AN |
| F-06 | Speler 2 | Dezelfde set als F-05, met pikhaak, inclusief de placeholder-poses voor bounce, lancering, vangen, merk-combo en oppompen (de andere kant van elke actie: dragen, slingeren, opvangen) | AN |
| F-07 | Echo-weergave | Geen eigen sprites: de sprite van de eigenaar als holle versie (rand, arcering om de 3 px aan de sprite verankerd, 2 nabeelden), grijze en kleurtoestand. Shader of gegenereerde sprites | TA |
| F-08 | Schaduwmerk en ontploffing | Merk op een vijand (1 frame + puls), ontploffing licht/schaduw (4–6 frames). Moet in één frame leesbaar zijn | AN (met AD) |
| F-09 | Testvijand | Laag, breed, donker, rode bovenrand en kern; idle, loop, geraakt, oplossen | AN |
| F-10 | Laaggrens en lichtbanden in de engine | 2D-licht in 5 banden, harde schaduw, stippel-laaggrens, saturatiepass grijs ↔ kleur | TA |

## 2. Slice: polderwijk met het eerste gemaal (P1 en P2)

| ID | Asset | Inhoud en maten | Prio | Eigenaar |
|---|---|---|---|---|
| S-01 | Palet polderwijk (grijs, half, kleur) | Ramps volgens bible §3, met de grijze afleiding | P1 | AD |
| S-02 | Concept: polderwijk en gemaal | 3 sleutelbeelden (aankomst grijs, binnen het gemaal, wijk na het oppompen), plus een kaart van de waterstanden | P1 | CA |
| S-03 | Concept: Gemaalmeester (boss) | Silhouet, 3 fasen, zwakke plekken die je met bounce/lancering haalt, pantser dat alleen een merk-combo breekt (pitch P1) | P1 | CA |
| S-04 | Tegelset polderwijk | Kades (blauwe hardsteen), baksteen, dijk, sluisdeuren, trappen, loopbruggen, duikers; elke tegel in grijs en kleur | P1 | EA |
| S-05 | Achtergrondlagen | Lucht (2 toestanden), verre daklijn met belfort, huizenrij met trapgevels (minstens 6 varianten, ramen aan/uit), middengrond (rad, kanaalwand) | P1 | EA |
| S-06 | Water | Oppervlak (animatie 4–6 frames), reflectieregel, getijdenrand, 3 waterstanden per wijk | P1 | EA (met TA) |
| S-07 | Lichtbronnen | Lantaarn (F-03 op eindkwaliteit), straatlamp met kap, raamgloed, FelLicht-zoeklicht; elk met de vijf kenmerken | P1 | EA |
| S-08 | Volumetrische bundels | Warm (opgepompt) en koud (grijs), als achtergrondsprite of shader | P1 | TA |
| S-09 | Speler 1 en 2, volledige set | F-05/F-06 op eindkwaliteit (ook bounce, lancering, vangen, merk-combo, oppompen), plus geraakt en dood/respawn | P1 | AN |
| S-10 | Echo-overgang grijs → kleur | Oplevend in ± 0,5 s na de wijk; oplossen in FelLicht (schaduwdeeltjes) | P1 | TA (met AN) |
| S-11 | Gemaal (eindkwaliteit) | Gebouw, interieur met pompmachine, rad dat draait (8 frames), oppomp-moment (licht golft de wijk in) | P1 | EA (met TA) |
| S-12 | Bevroren echo's | 3–5 stilgezette bewoners in schaduw (bakker, kinderen bij het carillon, …), hol, statisch | P2 | AN (met Narrative Designer) |
| S-13 | Vijanden polderwijk | 2–3 soorten, elk idle, loop, aanval, geraakt, oplossen | P2 | AN (concept: CA) |
| S-14 | Gemaalmeester (sprites) | Bossprites per fase, aanvallen, pantser breekt, nederlaag | P2 | AN |
| S-15 | Gedeelde echo (finisher) | Holle figuur met amber-cyaan rand, nabeelden in beide kleuren | P2 | TA (met AD) |
| S-16 | Effecten | Merk, ontploffing, parade, stof in het licht, schaduwdeeltjes, waterspetters | P2 | AN |
| S-17 | HUD en lichtmeter | In de beeldtaal van de bible (geen tekst in de art) | P2 | UI |

## 3. Al gemaakt

| Asset | Waar | Status |
|---|---|---|
| R5-scène (2 toestanden, Deck, ware grootte, grijswaarden/deuteranopie) | `docs/art/r5-scene/` | Bedoeld als eindkwaliteit; wacht op de F1-beoordeling |
| Sprites speler 1 (idle, sprong, loop), speler 2 (idle, loop) | `docs/art/r5-scene/bron/sprites.py` | Idle en sprong als basis voor F-05/F-06; de loopcyclus is placeholder |
| Palet (ramps kleur en grijs) | `docs/art/r5-scene/palet.png`, bible §3 | v0 |
| S-01 palet Kadewijk (grijs, half, kleur; nieuwe ramps roest, vijandlijf, vijandkern) | `docs/art/slice/palet_kadewijk.png`, `slice-kadewijk.md` §3 | Placeholder (deel 1 van #85) |
| Kleurscript en lichtovergang (studie) | `docs/art/slice/kleurscript_*`, `lichtovergang_*` | Placeholder (deel 1 van #85) |
| S-04 tileset Kadewijk, eerste set (46 tegels) en props (pomprad 8f, straatlamp, halo, boograam, bolder, sluisbalk), 3 toestanden + index-atlas | `docs/art/slice/tiles/` | Placeholder (deel 1 van #85) |
| S-03 / S-13 concept: 3 vijandtypes en de Gemaalmeester (stijlregels) | `docs/art/slice/concept_*` | Concept (deel 1 van #85) |
| S-04/S-05/S-06/S-07 voor **S1 Kade-ingang en S3 Vismarkt**: kamerlagen (achter, midden, speelvlak, licht, voor) in grijs, half en kleur plus index, NinePatch-stukken voor de eenrichtingsblokken per D, manifest | `game/art/wereld/kadewijk/`, renders in `docs/art/slice/eindkwaliteit/`, `slice-kadewijk.md` §9 | **Eindkwaliteit** (deel 2 van #85); de koppeling aan de scènes volgt (TA) |

## 4. Open punten

| Punt | Wie | Wanneer |
|---|---|---|
| Lijst bijwerken op de slice-inhoud van GDD v1 (aantal kamers, vijanden, bossfasen) | Art Director met Producer | Na T3 |
| Aantallen en ramingen per asset (runs) voor de productieraming | Producer met Art Director | Vóór T15 |
| Bestandsconventies en importinstellingen in Godot (atlas, filter uit, pixel snap) | Technical Artist | Vóór F-01 |
| Wie maakt de flow-kamer-placeholders als de Environment Artist en Animator nog niet zijn ingezet | Producer | Bij de start van de flow-kamer |
