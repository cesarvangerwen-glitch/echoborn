# Credits *Polderlight*: inhoud

Versie 0.1.7 · 2026-11-11 · eigenaar: Producer, met de Business/Legal Advisor (BLA) · issue [#87](https://github.com/cesarvangerwen-glitch/echoborn/issues/87) (T10, "credits-inhoud")

Dit document geeft de **inhoud** van het credits-scherm (`docs/ux/hud-menus.md` MN-37, §7 punt 18). Indeling en bediening staan in hud-menus §4.9 (MN-35, MN-36); de mock-up is `menu_credits_x2_placeholder.png` (`docs/art/ui-stijlgids.md` §12.6, script `docs/art/ui/bron/genereer_menu_placeholder.py`).

**Werkaanname (fase-2-kader §5):** hud-menus W7 (de spec is de versie vóór F0), stijlgids W7 (de credits-mock-up is een placeholder) en stijlgids §4 (het font is Polderletter, eigen werk). Verder: de namen en rollen in §3 volgen besluit #157 (1A, 2A); de licentie- en merkteksten in §5 zijn bevestigd door de BLA en nagelezen tegen B1, B5 en B6 (v0.1.7); de merkenregel is variant 1A–1C (§5.3, besluit #157), onder voorbehoud van de CEO-vraag in §5.8 (naam Claude/Anthropic zonder toestemming).

## 1. Opbouw en volgorde

Blokken van een kop met de regels eronder (MN-35). Van boven naar beneden:

| # | Blok | Sleutels (`strings.csv`) | Inhoud | Bron |
|---|---|---|---|---|
| 1 | Titel | — (`GAME_TITLE`, bestaat al) | *Polderlight* | besluit #96 |
| 2 | Makers | `CREDITS_MADE_BY` | **CesarTheLittle**, zonder roltitel (§3) | besluit #157 (2A) |
| 3 | Rollen | eerst de regel `CREDITS_TEAM_AI`, dan per vakgebied `CREDITS_TEAM_*` (§3) | De 26 AI-rollen per vakgebied | besluit #157 (1A), `studio/roles/` |
| 4 | Gemaakt met | `CREDITS_MADE_WITH` | *Godot Engine* | MN-37 |
| 5 | Lettertype | `CREDITS_FONT` | *Polderletter*, eigen werk van de studio (geen licentie van derden) | stijlgids §4, §10 punt 7 |
| 6 | Merken | `CREDITS_TRADEMARKS`, tekst `CREDITS_TRADEMARKS_TEXT` | De merkenregel, variant 1A–1C (§5.3) | `docs/business/knop-glyphs-check.md` §3 punt 4 |
| 7 | Licenties | `CREDITS_LICENSES`, dan `CREDITS_LICENSE_FREETYPE` en `CREDITS_LICENSE_GODOT_FILE` | De Godot-licentietekst (§5.1, via `Engine.get_license_text()`, niet in `strings.csv`), de FreeType-regel en de verwijsregel naar `GODOT_COPYRIGHT.txt` (§5.2) | `docs/licenties.md` |
| 8 | Slot | `CREDITS_THANKS` | *Bedankt voor het spelen* | — |

Waarom deze volgorde: eerst wie het maakte (wat spelers zoeken), dan het gereedschap, en de lange juridische teksten onderaan, zodat ze de rest niet ophouden bij 20 px/s (MN-36; leesbaarheid bekijkt de UX Designer na T11, hud-menus §7 punt 20).

## 2. Taal

- **Koppen** worden vertaald (EN bron, NL). EN/NL: *Made by / Gemaakt door*, de 7 vakgebieden (§3), *Made with / Gemaakt met*, *Font / Lettertype*, *Trademarks / Merken*, *Licenses / Licenties*, *Thank you for playing / Bedankt voor het spelen*. De definitieve tekst staat in `game/locale/strings.csv` (Narrative Designer); bij verschil geldt `strings.csv`.
- **Namen** worden niet vertaald (MN-37), ook *Godot Engine*, *Polderletter* en de merknamen niet (glyph-check §3 punt 6).
- **Roltitels** (*Art Director*, *QA Lead*, …) gelden als **namen**: ze worden niet vertaald en komen niet in `strings.csv` (MN-37); alleen de vakgebied-koppen erboven worden vertaald. Zo blijven ze gelijk aan `studio/roles/`.
- **Licentie- en merkteksten**: in beide talen de originele Engelse tekst, zonder vertaling (§5.4).

## 3. Namen en rollen

De studio is de CEO (een mens) en 26 AI-rollen (`studio/roles/`, Claude van Anthropic). Er is nog geen studionaam; de mock-up gebruikt *Een spel van de studio* als plaatshouder. De CEO koos in besluit #157 (CEO-vraag §4) optie **1A** (AI-rollen per vakgebied, met één regel *Claude (AI, Anthropic)* bovenaan blok 3) en **2A** (onder *Made by* / *Gemaakt door* alleen **CesarTheLittle**, zonder roltitel). Een studionaam (2C) kan later via een nieuw besluit.

De rollen per vakgebied, in de volgorde van het organigram (koppen zoals in `strings.csv`):

| Vakgebied (kop) | Sleutel | EN / NL | Rollen (namen, niet vertaald) |
|---|---|---|---|
| (bovenaan, één regel) | `CREDITS_TEAM_AI` | All roles: Claude (AI, Anthropic) / Alle rollen: Claude (AI, Anthropic) | — |
| Leiding en productie | `CREDITS_TEAM_PRODUCTION` | Leadership & production / Leiding en productie | Executive Producer, Producer, Studio Manager, Workflow & Process Optimization Lead |
| Ontwerp | `CREDITS_TEAM_DESIGN` | Design / Ontwerp | Creative Director, Lead Game Designer, Systems Designer, Combat Designer, World & Level Designer, UX Designer, Narrative Designer |
| Art | `CREDITS_TEAM_ART` | Art / Art | Art Director, Concept Artist, 2D Environment Artist, Animator, Technical Artist, UI Artist |
| Audio | `CREDITS_TEAM_AUDIO` | Audio / Audio | Audio Director, Composer/Sound Designer |
| Programmeren | `CREDITS_TEAM_CODE` | Programming / Programmeren | Technical Director, Gameplay Programmer, Engine & Platform Programmer, Tools Programmer |
| Kwaliteitscontrole | `CREDITS_TEAM_QA` | Quality assurance / Kwaliteitscontrole | QA Lead |
| Business | `CREDITS_TEAM_BUSINESS` | Business / Business | Business/Legal Advisor, Marketing & Community Manager |

## 4. CEO-vraag: namen en rollen in de credits

**Beslist in #157: 1A, 2A = CesarTheLittle (2026-11-11).**

*In het format van `.github/ISSUE_TEMPLATE/ceo-beslissing.md`; geen apart issue, de regisseur bundelt.*

**Van:** Producer

### Probleem
De credits moeten vóór de eerste publieke build zeggen wie het spel maakte (hud-menus §7 punt 18). De studio is één mens en 26 AI-rollen; hoe we dat vermelden bepaalt hoe spelers en pers het spel zien. Er is ook nog geen studionaam.

### Vragen

**1. Hoe vermelden we de AI-rollen?**
- **A. Per vakgebied, met de rollen; één regel "Claude (AI, Anthropic)" bovenaan blok 3** ⭐ Aanbevolen: eerlijk en compact; 1 regel + 7 koppen + 26 rollen ≈ 520 px, ± 25 s scrollen bij 20 px/s; € 0.
- **B. Elke rol als eigen blok met "Claude (AI)"**: volledig, maar 26 bijna gelijke blokken (± 50 s); € 0.
- **C. Eén regel "Gemaakt met AI-rollen (Claude, Anthropic)", zonder rollen**: kortst, maar de structuur van de studio verdwijnt; € 0.
- **D. Geen vermelding van AI in de credits**: niet aanbevolen; staat los van een eventuele AI-melding op de Steam-pagina (BLA, §6 punt 5); € 0.

**2. Hoe staat de CEO bovenaan?**
- **A. Met de eigen naam (of een schuilnaam) onder de kop *Made by* / *Gemaakt door*, zonder roltitel** (botst dan niet met de AI-rollen) ⭐ Aanbevolen: de mens achter het spel is zichtbaar; geef de naam mee in het besluit; € 0.
- **B. Alleen een studionaam (later te kiezen, met naamcheck)**: anoniemer; vraagt een naamkeuze en check (± 2–3 runs, € 0 tot de formele merkcheck).
- **C. Eigen naam én een studionaam**: B en A samen; zelfde kost als B.

### Waarom deze aanbeveling
1A is eerlijk over hoe het spel gemaakt is zonder 26 keer dezelfde naam te laten zien, en houdt de credits kort genoeg om te lezen. 2A vraagt geen nieuwe naam of check en kan later altijd uitgebreid worden met een studionaam (2C).

### Wat wacht hierop
- [#87](https://github.com/cesarvangerwen-glitch/echoborn/issues/87) (credits-inhoud, hud-menus §7 punt 18)

*CEO: antwoord kort met een comment die begint met `Besluit:`, bij 2A of 2C met de naam: bv. `Besluit: 1A, 2A = <naam>` (schuilnaam mag) of `Besluit: akkoord, 2A = <naam>`.*

## 5. Verplichte teksten

### 5.1 Godot Engine (MIT)

`docs/licenties.md`: Godot Engine 4.6, MIT, "Ja, licentietekst meeleveren". In de credits: de regel *Gemaakt met Godot Engine* (blok 4) en onder *Licenties* de licentietekst met de copyrightregel. Tekst zoals in `LICENSE.txt` van Godot 4.x (bij de bouw letterlijk overnemen uit de gebruikte versie; Godot geeft hem ook terug met `Engine.get_license_text()`):

```
Godot Engine
Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### 5.2 Componenten van derden in de Godot-export

De Godot-tekst van §5.1 is **niet genoeg**. Godot bevat code van derden (± 70 componenten, o.a. FreeType, Mbed TLS, ENet, zlib, libpng) met eigen licenties, die niet onder de MIT-licentie van Godot vallen. De Godot-docs zeggen dat veel daarvan een vermelding van copyright en licentietekst vragen, en noemen `COPYRIGHT.txt` (hernoemd tot `GODOT_COPYRIGHT.txt`) als goede optie (B1). Een lijst per component staat sinds de docs voor Godot 4.3 niet meer op de pagina (B1a); de licenties zelf staan in `COPYRIGHT.txt` (B5). Wat de credits en de build daarom moeten bevatten:

1. **In de credits (blok 7), direct onder de Godot-tekst**, de FreeType-regel (Polderlight toont tekst, dus FreeType zit erin; staat in `CREDITS_LICENSE_FREETYPE`, met `%s` = jaar). **Nagelezen (B5):** de FreeType License eist bij verspreiding in binaire vorm een vermelding in de documentatie dat de software deels op het werk van het FreeType Team steunt, en *raadt* deze tekst aan (letterlijk is dus niet verplicht, de vermelding wel). De docs voor Godot 4.0–4.2 vroegen deze regel "together with the Godot license" (B1a):
   ```
   Portions of this software are copyright © <year> The FreeType Project (www.freetype.org). All rights reserved.
   ```
   `<year>` is het jaar van de FreeType-versie in de gebruikte Godot-build (editor: *Help > About > Third-party Licenses*, of uit `Engine.get_copyright_info()`); niet zelf invullen of gokken.
2. **Een bestand naast de game**: `GODOT_COPYRIGHT.txt`, een kopie van `COPYRIGHT.txt` van **precies** de gebruikte Godot-versie (4.6.x), in elke build en elk Steam-depot (Windows, Linux/Steam Deck), naast het uitvoerbare bestand. Daarin staan alle componenten met hun licentietekst, ook Mbed TLS en ENet. **Nagelezen:** Mbed TLS staat in `COPYRIGHT.txt` van 4.6 met *Apache-2.0* (B5); Apache 2.0 §4(a) eist dat ontvangers een kopie van de licentie krijgen, en die volledige tekst staat in hetzelfde bestand. Met het bestand is dat gedekt; een eigen regel in de credits vragen de huidige Godot-docs niet (B1). De docs voor 4.0–4.2 gaven wel een korte Apache-tekst om mee te leveren (B1a); die staat in het bestand. Het bestand mag ook gemaakt worden met een Godot-script van dezelfde versie dat `Engine.get_copyright_info()` en `Engine.get_license_info()` uitschrijft (dat zijn runtime-calls).
3. **In de credits, na de FreeType-regel**, één verwijsregel (staat in `CREDITS_LICENSE_GODOT_FILE`):
   ```
   Godot Engine includes third-party components, such as Mbed TLS and ENet. Their copyright notices and license texts are in GODOT_COPYRIGHT.txt, next to the game.
   ```

Waarom niet alles in de credits: ± 70 copyrightregels en licentieteksten zijn bij 20 px/s minuten scrollen en onleesbaar; een bestand naast de game is een van de vormen die de Godot-docs zelf noemen (B1). Een apart scherm *Licenties* uit `Engine.get_copyright_info()` mag ook, maar is niet nodig.

- **ENet: gecorrigeerd (v0.1.7).** Het klopte niet dat ENet alleen bij multiplayer via ENet verplicht is. De docs voor 4.0–4.2 zeggen dat de officiële export-templates alle bibliotheken bevatten, "so you need to provide attribution for all the libraries listed", ENet inbegrepen (B1a); ENet staat in `COPYRIGHT.txt` van 4.6 onder *Expat* (MIT), dat de vermelding in alle kopieën vraagt (B5). Dus: verplicht zolang ENet in de export-template zit, ook al gebruikt Polderlight het niet (lokale co-op). Het staat in het bestand: geen extra werk.
- **Godot zelf (nagelezen, B1):** één vorm volstaat (credits, licentiescherm, output log, bestand naast de game, handleiding); ook een link naar `godotengine.org/license` in de credits of documentatie vinden de Godot-ontwikkelaars aanvaardbaar. §5.1 (volledige tekst in de credits) gaat verder dan nodig en blijft zo.
- **Eigen export-template** met uitgeschakelde modules: dan mag wat er niet in zit weg (`docs/licenties.md` §3).
- Er zijn geen externe assets, fonts, plug-ins of addons (`game/` heeft geen `addons/`). Komt er een SDK bij (bv. Steamworks), dan eerst een regel in `docs/licenties.md`.

### 5.3 Merkenregel (definitief)

Uit `docs/business/knop-glyphs-check.md` §3 punt 4, aangevuld met de formulering die Valve zelf gebruikt (*in the U.S. and/or other countries*) en een slotzin. Eén alinea, Engels, in twee varianten.

**Variant 1A–1C** (de credits noemen Claude):

> Xbox is a trademark of the Microsoft group of companies. PlayStation is a registered trademark or trademark of Sony Interactive Entertainment Inc. Steam and Steam Deck are trademarks and/or registered trademarks of Valve Corporation in the U.S. and/or other countries. Claude and Anthropic are trademarks of Anthropic, PBC. Polderlight is not affiliated with or endorsed by Microsoft, Sony Interactive Entertainment, Valve or Anthropic. All other trademarks are the property of their respective owners.

**Variant 1D** (geen AI in de credits):

> Xbox is a trademark of the Microsoft group of companies. PlayStation is a registered trademark or trademark of Sony Interactive Entertainment Inc. Steam and Steam Deck are trademarks and/or registered trademarks of Valve Corporation in the U.S. and/or other countries. Polderlight is not affiliated with or endorsed by Microsoft, Sony Interactive Entertainment or Valve. All other trademarks are the property of their respective owners.

- **Besluit #157 (1A):** variant 1A–1C geldt, letterlijk in `CREDITS_TRADEMARKS_TEXT`; 1D vervalt.
- **Merkenrecht:** *Claude (AI, Anthropic)* is een feitelijke vermelding van het gereedschap waarmee het spel is gemaakt, alleen de naam, geen logo, zonder steun of samenwerking te suggereren (zelfde grond als bij de knopnamen, glyph-check S7: art. 14 lid 1 UMV). Daarvoor is volgens het merkenrecht geen toestemming nodig.
- **Voorwaarden van Anthropic (nagelezen v0.1.7): die gaan verder dan het merkenrecht.** De Consumer Terms (gelden voor het Max-abonnement) zeggen: "You may not, without our prior written permission, use our name, logos, or other trademarks in connection with products or services other than the Services, or in any other way that implies our affiliation, endorsement, or sponsorship. To seek permission, please email us at marketing@anthropic.com." (B6). De Trademark Guidelines: "You may only use our trademarks as specifically permitted by us and only in materials we approve beforehand." (B7). Letterlijk gelezen vraagt de regel *Claude (AI, Anthropic)* in de credits van een commercieel spel dus **voorafgaande schriftelijke toestemming**. Een uitzondering voor een feitelijke vermelding ("gemaakt met") noemen de voorwaarden niet; of zo'n vermelding eronder valt, zeggen ze ook niet. Dit is een contractuele regel tussen de CEO (als gebruiker) en Anthropic, los van het merkenrecht. Daarom de CEO-vraag in §5.8.
- **De zin in `CREDITS_TRADEMARKS_TEXT` past wel bij de richtlijnen:** een merkvermelding ("Claude and Anthropic are trademarks of Anthropic, PBC.") wordt niet gevraagd, maar ook niet verboden; de richtlijnen verbieden alleen een merksymbool ("Do not use a trademark symbol with the trademarks", B7), en de tekst gebruikt er geen. De zin "not affiliated with or endorsed by … Anthropic" sluit aan bij het verbod om steun of samenwerking te suggereren (B6, B7). Geen wijziging nodig, tenzij de CEO bij §5.8 voor C kiest.
- **Geen Anthropic- of Claude-logo** gebruiken, ook niet op de Steam-pagina: logo's alleen met beeld en eisen die Anthropic zelf levert (B7).
- **Eigendom van de output (B6):** "Subject to your compliance with our Terms, we assign to you all of our right, title, and interest—if any—in Outputs." Anthropic claimt de output dus niet en draagt wat het eventueel heeft over aan de gebruiker (de CEO), zolang die zich aan de voorwaarden houdt; of er auteursrecht op AI-output rust, regelen de voorwaarden niet ("if any"), dat bepaalt het recht. Voor `docs/licenties.md`: de AI-output is werk van de studio, zonder licentie van derden.
- *Godot Engine* hoeft niet in de merkenregel: *Made with Godot Engine* (blok 4) is gewone, toegestane vermelding (B2). Geen Godot-logo zonder het na te lezen in de logo-regels van Godot.
- *Polderlight* volgt de werktitel en gaat mee na de formele merkcheck (glyph-check §4 punt 6). De vraag aan de specialist (glyph-check §4 punt 1) blijft staan; die verandert de tekst naar verwachting niet.

### 5.4 Taal van de licentie- en merkteksten

**Alleen Engels, ook in de Nederlandse versie.** De Godot-licentie, de FreeType-regel en `GODOT_COPYRIGHT.txt` zijn juridische teksten waarvan alleen de originele versie geldt; een vertaling voegt niets toe en kan afwijken. Voor de merkenregel is een vertaling toegestaan, maar niet nodig; één Engelse tekst houdt het onderhoud klein en blijft gelijk aan hoe de merkhouders hun merken noemen. Alleen de **koppen** (*Trademarks / Merken*, *Licenses / Licenties*) worden vertaald (§2). In `strings.csv` komen de teksten dus met dezelfde EN-tekst in beide kolommen, of als één niet-vertaalde tekst; dat kiest de Narrative Designer.

### 5.5 Eigen werk: Polderletter en de knop-glyphs

Beide staan nu als regel "eigen werk" in `docs/licenties.md` §2. Voor eigen werk is **geen vermelding verplicht**: blok 5 (*Lettertype*) **mag vervallen**. Laten staan mag ook (als dank aan het eigen font), dan zonder licentietekst. Dat is een keuze over de presentatie, niet juridisch (§6 punt 2). Gekozen: behouden (v0.1.6, §6 punt 2).

### 5.6 AI-melding op de Steam-pagina (advies, geen besluit)

**Advies: ja, melden.** Valve vraagt in de *Content Survey* (bij het indienen van de game) of er generatieve AI is gebruikt, in twee soorten: *pre-generated* (vóór de release gemaakt) en *live-generated* (tijdens het spelen gemaakt) (B3). Bij *pre-generated* belooft de ontwikkelaar dat de inhoud niet illegaal of inbreukmakend is, en Valve toont een melding op de Steam-pagina (B4). Sinds januari 2026 gaat het alleen om AI-inhoud die **spelers zelf zien of horen** (art, geluid, tekst, verhaal); AI als efficiëntie-hulpmiddel (bv. code-assistenten) hoeft niet (B4).

Voor Polderlight: de art, audio en teksten worden door AI-rollen (Claude) gemaakt, ook als dat via scripts gebeurt. Dat is *pre-generated* inhoud die spelers zien; melden is dus nodig. *Live-generated* is er niet (geen AI tijdens het spelen).

- Dit staat **los van CEO-vraag [#157](https://github.com/cesarvangerwen-glitch/echoborn/issues/157)**: ook bij 1D (geen AI in de credits) blijft de Steam-melding nodig. 1D zou dan betekenen dat de Steam-pagina AI meldt en de credits niet; dat is een punt om mee te wegen, de keuze blijft bij de CEO.
- De meldtekst (kort, eerlijk, in de lijn van §3) schrijft de Marketing & Community Manager met de BLA, bij het maken van de Steam-pagina (§6 punt 5). De officiële Steamworks-tekst van de survey leest de BLA dan na (deze run niet bereikbaar).

### 5.7 Bronnen (BLA, geraadpleegd 2026-11-10; B1, B1a en B5–B9 nagelezen 2026-11-11)

- **B1** Godot Engine, *Complying with licenses* (docs "stable" = 4.6). https://docs.godotengine.org/en/stable/about/complying_with_licenses.html — gelezen op 2026-11-11 via de bron op GitHub (`godotengine/godot-docs`, `about/complying_with_licenses.rst`, takken `stable` en `4.6`, inhoudelijk gelijk aan `master`): https://github.com/godotengine/godot-docs/blob/4.6/about/complying_with_licenses.rst. De HTML-pagina zelf was deze run niet bereikbaar. Koppen: *Requirements, Inclusion* (credits, licentiescherm, output log, bestand, handleiding, link), *Third-party licenses*; FreeType, ENet en Mbed TLS worden niet meer apart genoemd.
- **B1a** Zelfde pagina, docs voor Godot 4.2 (tak `4.2`, gelijk voor 4.0 en 4.1), met de vroegere secties *FreeType*, *ENet* en *mbed TLS*: https://github.com/godotengine/godot-docs/blob/4.2/about/complying_with_licenses.rst (gelezen 2026-11-11). Ouder dan de gebruikte versie: alleen als toelichting.
- **B2** Godot Engine, *License*. https://godotengine.org/license
- **B3** PC Gamer, *Valve updates its Steam policy on AI…* (10-01-2024, citeert Valve). https://www.pcgamer.com/valve-updates-its-steam-policy-on-ai-so-it-can-release-the-vast-majority-of-games-that-use-it
- **B4** Outlook Respawn, *Valve clarifies Steam AI policy: focus shifts to content consumed* (18-01-2026, citeert het nieuwe formulier: *"efficiency gains through the use of these tools are not the focus of this section"*). https://respawn.outlookindia.com/amp/story/gaming/gaming-news/valve-clarifies-steam-ai-policy-focus-shifts-to-content-consumed
- **B5** Godot Engine, `COPYRIGHT.txt` op de tak `4.6` (gelezen 2026-11-11): FreeType (*FTL*, met de aanbevolen creditregel), Mbed TLS (*Apache-2.0*), ENet (*Expat*), met de volledige licentieteksten. https://github.com/godotengine/godot/blob/4.6/COPYRIGHT.txt. Let op: de tak volgt de laatste 4.6.x; voor de build telt het bestand van precies de gebruikte versie (§5.2 punt 2).
- **B6** Anthropic, *Consumer Terms of Service* (effective Oct 8, 2025; gelezen 2026-11-11): *Use of our brand* (§12 *General terms*) en eigendom van Outputs (§4 *Inputs, Outputs, Actions, and Materials*). https://www.anthropic.com/legal/consumer-terms. Volgens de inleiding gelden de Commercial Terms alleen voor API-sleutels en de Console, niet voor Claude.ai/Claude Pro van personen of bedrijven.
- **B7** Anthropic, *Trademark Guidelines* (effective Aug 1, 2024; gelezen 2026-11-11). https://www.anthropic.com/legal/trademark-guidelines
- **B8** Anthropic, *Commercial Terms of Service* (effective Jun 17, 2025; gelezen 2026-11-11), ter vergelijking: de klant "owns its Outputs"; gezocht op *trademark*, *logo* en *brand*: geen merkclausule voor de klant, alleen *Publicity* (Anthropic mag de klantnaam noemen). https://www.anthropic.com/legal/commercial-terms
- **B9** Anthropic, *Usage Policy*, twee versies gelezen op 2026-11-11: de vandaag geldende (effective Sep 15, 2025; https://www.anthropic.com/legal/archive/22742366-2ef0-4c7a-a833-6523f10d3944) en de nieuwe op https://www.anthropic.com/legal/aup (effective Nov 12, 2026). Over dit punt zeggen ze hetzelfde: niets over het noemen van Claude in credits of over merken (gezocht op *credits* en *trademark*); in beide het verbod op "Plagiarize or submit AI-assisted work without proper permission or attribution" en op misleiden over de herkomst van inhoud (2025: "mislead others about its origin"; 2026: "mislead audiences about its origin"). De regel *Claude (AI, Anthropic)* en de Steam-melding (§5.6) passen daarbij.

### 5.8 CEO-vraag: de naam Claude/Anthropic in de credits

*In het format van `.github/ISSUE_TEMPLATE/ceo-beslissing.md`; geen apart issue, de regisseur bundelt (zoals §4).*

**Van:** Business/Legal Advisor

#### Probleem
Besluit #157 (1A) zet *Claude (AI, Anthropic)* bovenaan blok 3 en Anthropic in de merkenregel. De Consumer Terms van Anthropic (§12, B6) verbieden het gebruik van hun naam "in connection with products or services other than the Services" zonder voorafgaande schriftelijke toestemming; een uitzondering voor een feitelijke vermelding staat er niet in (§5.3). Dit moet rond zijn vóór de eerste publieke build.

#### Vragen

**1. Hoe gaan we om met de naam Claude/Anthropic in de credits?**
- **A. Schriftelijke toestemming vragen via marketing@anthropic.com** voor precies de twee teksten (`CREDITS_TEAM_AI` en de Anthropic-zin in `CREDITS_TRADEMARKS_TEXT`), zonder logo ⭐ Aanbevolen: de credits blijven zoals #157; de BLA schrijft het concept, de CEO verstuurt het; € 0, wachttijd onbekend; geen ja vóór de eerste publieke build = C.
- **B. Zonder toestemming houden**, op grond van het merkenrecht (feitelijke vermelding, §5.3): € 0, geen wachttijd; letterlijk gelezen in strijd met de Consumer Terms, die Anthropic bij een vermoede schending toestaan het account (met abonnement) zonder aankondiging te schorsen of te beëindigen (§12, *Termination*, B6); de hele studio draait op dat account.
- **C. Merkloos: `CREDITS_TEAM_AI` = *All roles: AI* / *Alle rollen: AI*; merkenregel = variant 1D (§5.3)**: € 0, geen toestemming nodig; de CEO levert uit #157 de naamvermelding van het gereedschap in (spelers lezen niet meer dat het spel met Claude van Anthropic is gemaakt); wijzigt 1A van #157 deels; de AI-melding op Steam (§5.6) blijft.

#### Waarom deze aanbeveling
A houdt de eerlijke vermelding uit #157 en volgt de weg die de voorwaarden zelf noemen; het kost één mail. Zekerheid dat een feitelijke vermelding toegestaan is zonder toestemming, geven de bronnen niet; de specialist van de formele merkcheck (#24, 3A) kan dit meenemen.

#### Wat wacht hierop
- [#171](https://github.com/cesarvangerwen-glitch/echoborn/issues/171) (§6 punt 4); bij A legt de BLA het concept van de toestemmingsmail klaar (met de Steam-meldtekst, §6 punt 12)
- [#87](https://github.com/cesarvangerwen-glitch/echoborn/issues/87) (credits-inhoud; bij C: `CREDITS_TEAM_AI` en `CREDITS_TRADEMARKS_TEXT` in `strings.csv`)

*CEO: antwoord kort met een comment die begint met `Besluit:`, bv. `Besluit: 1A` of `Besluit: akkoord`.*

## 6. Open punten

| # | Wat | Wie | Wanneer |
|---|---|---|---|
| 1 | `GODOT_COPYRIGHT.txt` (§5.2 punt 2) in elke export en elk depot zetten en het FreeType-jaar invullen. **BLA-deel afgerond (v0.1.7):** B1 nagelezen (B1, B1a, B5): FreeType-regel bevestigd; Mbed TLS vraagt geen eigen regel in de credits (het bestand dekt Apache 2.0 §4(a)); ENet gecorrigeerd: verplicht zolang het in de export-template zit, ook zonder multiplayer. **Rest:** B5 is gelezen op de tak `4.6`; bij de build `GODOT_COPYRIGHT.txt` en het FreeType-jaar nalezen tegen `COPYRIGHT.txt` van de gebruikte tag (4.6.x). | Engine & Platform Programmer (export, nalezen tegen de tag) | Vóór de eerste publieke build |
| 2 | ~~Blok 5 (*Lettertype*) behouden of schrappen~~ **Afgerond (v0.1.6): behouden**, zonder licentietekst (§5.5): het eigen font is werk van de studio, het kost twee regels (± 2 s scrollen) en `CREDITS_FONT` staat al in `strings.csv`. De context van `CREDITS_FONT` in `strings.csv` zegt nog *Blok mag vervallen*; de Narrative Designer past die aan naar *behouden (credits.md §6 punt 2)* bij de volgende wijziging van `strings.csv`. | Narrative Designer (context) | Bij de volgende wijziging van `strings.csv` |
| 3 | ~~Taal van de licentie- en merkteksten~~ **Afgerond (v0.1.3):** alleen Engels, ook in NL (§5.4). | — | — |
| 4 | ~~Variant van de merkenregel~~ **Afgerond (v0.1.6):** variant 1A–1C (besluit #157), letterlijk in `CREDITS_TRADEMARKS_TEXT`. Die tekst noemt *Polderlight* letterlijk: verandert de naam na de merkcheck, dan wijzigen `GAME_TITLE` én `CREDITS_TRADEMARKS_TEXT` (EN en NL) samen. Voorwaarden van Anthropic **nagelezen (v0.1.7, §5.3, B6–B9)**: de merkzin past; de naam in de credits vraagt letterlijk schriftelijke toestemming. **Nog open:** CEO-vraag §5.8; bij A stuurt de CEO de mail (concept: BLA), bij C past de Narrative Designer `CREDITS_TEAM_AI` en `CREDITS_TRADEMARKS_TEXT` aan. | CEO (§5.8); BLA (concept mail bij A); Narrative Designer (tekst bij C of bij naamwijziging) | Vóór de eerste publieke build; tekst bij een naamwijziging |
| 5 | AI-melding op Steam (advies §5.6: ja, *pre-generated*): meldtekst schrijven en de Steamworks-tekst van de survey nalezen. | Marketing & Community Manager, met de BLA | Bij het maken van de Steam-pagina |
| 6 | ~~CEO-vraag §4~~ **Afgerond (v0.1.6):** besluit #157 (1A, 2A). | — | — |
| 7 | ~~`CREDITS_*`-sleutels in `strings.csv`~~ **Afgerond (v0.1.6):** 17 sleutels in `game/locale/strings.csv` (EN/NL, met context); §1 en §3 volgen ze. | — | — |
| 8 | hud-menus §7 punt 18 sluiten met een verwijzing naar dit document; dit document wijzigt hud-menus niet. | UX Designer | Bij zijn volgende wijziging van hud-menus |
| 9 | Placeholder in `genereer_menu_placeholder.py` (blok *Licenties*: *Tekst volgt*) vervangen door de echte inhoud, zodra punt 1 rond is. | UI Artist | Bij de eind-art van de credits |
| 10 | Credits bouwen uit dit document (de licentietekst bij voorkeur via `Engine.get_license_text()`, zodat hij altijd bij de gebruikte versie past). De bouw herbreekt de licentie-alinea's op de kolom van 320 px (± 71 tekens per regel), niet op de regels van `LICENSE.txt`. Onder de Godot-tekst de FreeType-regel en de verwijsregel van §5.2. De namen die niet in `strings.csv` staan (*CesarTheLittle*, de 26 roltitels, *Godot Engine*, *Polderletter*) krijgen een eigen bron (bv. een databestand) die `test_no_hard_text_in_code` niet als harde tekst ziet. | Gameplay Programmer | Met hud-menus §7 punt 19 (T8a) |
| 11 | Context van `CREDITS_LICENSE_FREETYPE` in `strings.csv` zegt *Letterlijk zoals FreeType het vraagt*; dat is de **aanbevolen** tekst van de FreeType License, niet een letterlijke eis (§5.2 punt 1). Context aanpassen naar *aanbevolen creditregel van de FreeType License (credits.md §5.2 punt 1)*. De tekst zelf hoeft niet te wijzigen; de FTL in Godot 4.6 schrijft de URL als *https://freetype.org* (B5), overnemen mag. | Narrative Designer | Bij de volgende wijziging van `strings.csv` |
| 12 | Bij §5.8 A: de toestemmingsmail dekt ook de AI-meldtekst op de Steam-pagina (§5.6) als die *Claude*/*Anthropic* noemt (zelfde clausule, B6); anders noemt de meldtekst de naam niet. | BLA (concept mail), Marketing & Community Manager (meldtekst) | Bij het concept van de mail (§5.8 A) |

## 7. Wijzigingen

| Versie | Datum | Wat |
|---|---|---|
| 0.1.7 | 2026-11-11 | BLA (#171): B1 nagelezen via de bron op GitHub (B1, B1a, nieuw B5): FreeType-regel bevestigd (aanbevolen tekst van de FTL), Mbed TLS zonder eigen regel (bestand volstaat), ENet gecorrigeerd (niet alleen bij multiplayer); markeringen "uit B1, nog na te lezen" weg. Voorwaarden van Anthropic nagelezen (nieuw B6–B9): merkzin past, naam in de credits vraagt letterlijk schriftelijke toestemming; eigendom output in §5.3; nieuwe CEO-vraag §5.8; §6 punt 1 (BLA-deel) en 4 bijgewerkt, nieuw punt 11 (context FreeType-sleutel). Na de EP-review (PR #172): §5.8 B met het risico van schorsing/beëindiging van het account, C eenduidig (variant 1D), punt 12 (Steam-meldtekst in de toestemmingsmail); licenties.md §2 voorzichtiger. Na de SM-review (PR #172): B9 met de geldende versie (Sep 15, 2025), §5.8 C met wat de CEO inlevert, concept mail bij A in *Wat wacht hierop*, §6 punt 1 nalezen tegen de gebruikte tag. |
| 0.1.6 | 2026-11-11 | Na besluit #157 (1A, 2A) en de reviews op de `CREDITS_*`-sleutels (#87): §1 en §3 naar de sleutels en koppen in `strings.csv` (*Programming / Programmeren*, *Quality assurance / Kwaliteitscontrole*; nieuw `CREDITS_TRADEMARKS_TEXT`, `CREDITS_LICENSE_FREETYPE`, `CREDITS_LICENSE_GODOT_FILE`); CesarTheLittle in blok 2; §6 punt 2 (blok 5 behouden), 4 (variant), 6 en 7 afgerond; §4 en §5.3 met besluit #157; §5.2 punt 1 en 3 naar `CREDITS_LICENSE_FREETYPE` en `CREDITS_LICENSE_GODOT_FILE`; punt 9 hangt alleen nog aan punt 1; punt 4: naamwijziging raakt `GAME_TITLE` én `CREDITS_TRADEMARKS_TEXT`; punt 10: eigen bron voor namen buiten `strings.csv`. |
| 0.1.5 | 2026-11-10 | Na de SM-review (PR #159): toestemming Anthropic alleen op merkenrecht gegrond, voorwaarden nalezen in §6 punt 4; ENet- en Mbed TLS-beweringen gemarkeerd als "uit B1, nog na te lezen"; §6 punt 2 geen blokkade voor de bouw. |
| 0.1.4 | 2026-11-10 | Na de Lead-review van de EP (PR #159): merkenregel in twee volledige varianten (1A–1C en 1D); werkaanname onder voorbehoud van B1; `get_copyright_info()`/`get_license_info()` als runtime-calls (Godot-script van dezelfde versie); §6 punt 1 ook Mbed TLS-regel nagaan. |
| 0.1.3 | 2026-11-10 | BLA (#87, open punten 1–5): §5.2 componenten van derden (FreeType-regel, `GODOT_COPYRIGHT.txt`, verwijsregel); §5.3 merkenregel definitief, Anthropic-zin afhankelijk van #157; nieuw §5.4 taal (alleen Engels), §5.5 eigen werk (blok 5 mag vervallen), §5.6 advies AI-melding Steam, §5.7 bronnen; §6 punt 3 afgerond, 1, 2, 4 en 5 tot één restregel; `docs/licenties.md` aangevuld. |
| 0.1.2 | 2026-11-10 | Na de SM-review (PR #156): 2A met naam in het besluit (`2A = <naam>`); plaats van de regel *Claude (AI, Anthropic)* (`CREDITS_TEAM_AI`, bovenaan blok 3) met duurschatting; herbreken van de licentietekst (open punt 10). |
| 0.1.1 | 2026-11-10 | Na de Lead-review van de EP (PR #156): werkaanname correct geciteerd; 7 kopsleutels `CREDITS_TEAM_*` met EN/NL; roltitels = namen (niet vertaald); voorbeeld bij 2A zonder roltitel; Engelse licentietekst als werkaanname. |
| 0.1 | 2026-11-10 | Eerste versie (#87): opbouw, sleutels (voorstel), rollen, CEO-vraag namen en rollen, Godot-licentie, merkenregel, open punten voor de BLA. |
