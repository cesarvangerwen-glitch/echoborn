# Credits *Polderlight*: inhoud

Versie 0.1.4 · 2026-11-10 · eigenaar: Producer, met de Business/Legal Advisor (BLA) · issue [#87](https://github.com/cesarvangerwen-glitch/echoborn/issues/87) (T10, "credits-inhoud")

Dit document geeft de **inhoud** van het credits-scherm (`docs/ux/hud-menus.md` MN-37, §7 punt 18). Indeling en bediening staan in hud-menus §4.9 (MN-35, MN-36); de mock-up is `menu_credits_x2_placeholder.png` (`docs/art/ui-stijlgids.md` §12.6, script `docs/art/ui/bron/genereer_menu_placeholder.py`).

**Werkaanname (fase-2-kader §5):** hud-menus W7 (de spec is de versie vóór F0), stijlgids W7 (de credits-mock-up is een placeholder) en stijlgids §4 (het font is Polderletter, eigen werk). Verder: de namen en rollen in §3 zijn een voorstel tot de CEO beslist (§4); de licentie- en merkteksten in §5 zijn bevestigd door de BLA, onder voorbehoud van het nalezen van B1 (§6 punt 1); de Anthropic-zin in §5.3 hangt af van [#157](https://github.com/cesarvangerwen-glitch/echoborn/issues/157).

## 1. Opbouw en volgorde

Blokken van een kop met de regels eronder (MN-35). Van boven naar beneden:

| # | Blok | Kop (sleutel, voorstel) | Inhoud | Bron |
|---|---|---|---|---|
| 1 | Titel | — (`GAME_TITLE`, bestaat al) | *Polderlight* | besluit #96 |
| 2 | Makers | `CREDITS_MADE_BY` | Wie het spel maakt: zie §3 en CEO-vraag §4 | — |
| 3 | Rollen | eerst de regel `CREDITS_TEAM_AI`, dan per vakgebied `CREDITS_TEAM_*` (§3; optie 1A, zie §4) | De AI-rollen, volgens de keuze in §4 | `studio/roles/` |
| 4 | Gemaakt met | `CREDITS_MADE_WITH` | *Godot Engine* | MN-37 |
| 5 | Lettertype | `CREDITS_FONT` | *Polderletter*, eigen werk van de studio (geen licentie van derden) | stijlgids §4, §10 punt 7 |
| 6 | Merken | `CREDITS_TRADEMARKS` | De merkenregel (§5.3) | `docs/business/knop-glyphs-check.md` §3 punt 4 |
| 7 | Licenties | `CREDITS_LICENSES` | De Godot-licentietekst (§5.1), de FreeType-regel en de verwijsregel naar `GODOT_COPYRIGHT.txt` (§5.2) | `docs/licenties.md` |
| 8 | Slot | `CREDITS_THANKS` | *Bedankt voor het spelen* | — |

Waarom deze volgorde: eerst wie het maakte (wat spelers zoeken), dan het gereedschap, en de lange juridische teksten onderaan, zodat ze de rest niet ophouden bij 20 px/s (MN-36; leesbaarheid bekijkt de UX Designer na T11, hud-menus §7 punt 20).

## 2. Taal

- **Koppen** worden vertaald (EN bron, NL). Voorstel EN/NL: *Made by / Gemaakt door*, de 7 vakgebieden (§3), *Made with / Gemaakt met*, *Font / Lettertype*, *Trademarks / Merken*, *Licenses / Licenties*, *Thank you for playing / Bedankt voor het spelen*. De Narrative Designer schrijft de definitieve tekst.
- **Namen** worden niet vertaald (MN-37), ook *Godot Engine*, *Polderletter* en de merknamen niet (glyph-check §3 punt 6).
- **Roltitels** (*Art Director*, *QA Lead*, …) gelden als **namen**: ze worden niet vertaald en komen niet in `strings.csv` (MN-37); alleen de vakgebied-koppen erboven worden vertaald. Zo blijven ze gelijk aan `studio/roles/`.
- **Licentie- en merkteksten**: in beide talen de originele Engelse tekst, zonder vertaling (§5.4).

## 3. Namen en rollen (voorstel)

De studio is de CEO (een mens) en 26 AI-rollen (`studio/roles/`, Claude van Anthropic). Er is nog geen studionaam; de mock-up gebruikt *Een spel van de studio* als plaatshouder. Hoe de CEO en de AI-rollen in de credits komen, is een keuze over hoe het spel zich presenteert, dus een CEO-vraag (§4). Tot dan geldt optie 1A en 2A als werkaanname.

De rollen per vakgebied (voor optie 1A), in de volgorde van het organigram:

| Vakgebied (kop) | Sleutel (voorstel) | EN / NL (voorstel) | Rollen (namen, niet vertaald) |
|---|---|---|---|
| (bovenaan, één regel) | `CREDITS_TEAM_AI` | All roles: Claude (AI, Anthropic) / Alle rollen: Claude (AI, Anthropic) | — |
| Leiding en productie | `CREDITS_TEAM_PRODUCTION` | Leadership & production / Leiding en productie | Executive Producer, Producer, Studio Manager, Workflow & Process Optimization Lead |
| Ontwerp | `CREDITS_TEAM_DESIGN` | Design / Ontwerp | Creative Director, Lead Game Designer, Systems Designer, Combat Designer, World & Level Designer, UX Designer, Narrative Designer |
| Art | `CREDITS_TEAM_ART` | Art / Art | Art Director, Concept Artist, 2D Environment Artist, Animator, Technical Artist, UI Artist |
| Audio | `CREDITS_TEAM_AUDIO` | Audio / Audio | Audio Director, Composer/Sound Designer |
| Code | `CREDITS_TEAM_CODE` | Programming / Code | Technical Director, Gameplay Programmer, Engine & Platform Programmer, Tools Programmer |
| Kwaliteit | `CREDITS_TEAM_QA` | Quality / Kwaliteit | QA Lead |
| Business | `CREDITS_TEAM_BUSINESS` | Business / Business | Business/Legal Advisor, Marketing & Community Manager |

## 4. CEO-vraag: namen en rollen in de credits

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

De Godot-tekst van §5.1 is **niet genoeg**. Godot bevat code van derden (± 70 componenten, o.a. FreeType, Mbed TLS, ENet, zlib, libpng) met eigen licenties; de Godot-docs vragen daar een vermelding voor (B1). Wat de credits en de build daarom moeten bevatten:

1. **In de credits (blok 7), direct onder de Godot-tekst**, de regel die FreeType letterlijk vraagt (Polderlight toont tekst, dus FreeType zit erin):
   ```
   Portions of this software are copyright © <year> The FreeType Project (www.freetype.org). All rights reserved.
   ```
   `<year>` is het jaar van de FreeType-versie in de gebruikte Godot-build (editor: *Help > About > Third-party Licenses*, of uit `Engine.get_copyright_info()`); niet zelf invullen of gokken.
2. **Een bestand naast de game**: `GODOT_COPYRIGHT.txt`, een kopie van `COPYRIGHT.txt` van **precies** de gebruikte Godot-versie (4.6.x), in elke build en elk Steam-depot (Windows, Linux/Steam Deck), naast het uitvoerbare bestand. Daarin staan alle componenten met hun licentietekst, ook Mbed TLS (Apache 2.0, moet mee) en ENet. Het bestand mag ook gemaakt worden met een Godot-script van dezelfde versie dat `Engine.get_copyright_info()` en `Engine.get_license_info()` uitschrijft (dat zijn runtime-calls).
3. **In de credits, na de FreeType-regel**, één verwijsregel (EN, voorstel):
   ```
   Godot Engine includes third-party components, such as Mbed TLS and ENet. Their copyright notices and license texts are in GODOT_COPYRIGHT.txt, next to the game.
   ```

Waarom niet alles in de credits: ± 70 copyrightregels en licentieteksten zijn bij 20 px/s minuten scrollen en onleesbaar; een bestand naast de game is een van de vormen die de Godot-docs zelf noemen (B1). Een apart scherm *Licenties* uit `Engine.get_copyright_info()` mag ook, maar is niet nodig.

- **ENet** is volgens de Godot-docs alleen verplicht bij multiplayer via ENet; Polderlight is lokale co-op en heeft het niet nodig. Het zit wel in de standaard-export en staat via het bestand toch vermeld: geen extra werk.
- **Eigen export-template** met uitgeschakelde modules: dan mag wat er niet in zit weg (`docs/licenties.md` §3).
- Er zijn geen externe assets, fonts, plug-ins of addons (`game/` heeft geen `addons/`). Komt er een SDK bij (bv. Steamworks), dan eerst een regel in `docs/licenties.md`.

### 5.3 Merkenregel (definitief)

Uit `docs/business/knop-glyphs-check.md` §3 punt 4, aangevuld met de formulering die Valve zelf gebruikt (*in the U.S. and/or other countries*) en een slotzin. Eén alinea, Engels, in twee varianten.

**Variant 1A–1C** (de credits noemen Claude):

> Xbox is a trademark of the Microsoft group of companies. PlayStation is a registered trademark or trademark of Sony Interactive Entertainment Inc. Steam and Steam Deck are trademarks and/or registered trademarks of Valve Corporation in the U.S. and/or other countries. Claude and Anthropic are trademarks of Anthropic, PBC. Polderlight is not affiliated with or endorsed by Microsoft, Sony Interactive Entertainment, Valve or Anthropic. All other trademarks are the property of their respective owners.

**Variant 1D** (geen AI in de credits):

> Xbox is a trademark of the Microsoft group of companies. PlayStation is a registered trademark or trademark of Sony Interactive Entertainment Inc. Steam and Steam Deck are trademarks and/or registered trademarks of Valve Corporation in the U.S. and/or other countries. Polderlight is not affiliated with or endorsed by Microsoft, Sony Interactive Entertainment or Valve. All other trademarks are the property of their respective owners.

- **Welke variant** volgt CEO-vraag [#157](https://github.com/cesarvangerwen-glitch/echoborn/issues/157) vraag 1: bij A–C de eerste, bij D de tweede.
- **Toestemming van Anthropic is niet nodig**: *Claude (AI, Anthropic)* is een feitelijke vermelding van het gereedschap waarmee het spel is gemaakt, alleen de naam, geen logo, zonder steun of samenwerking te suggereren (zelfde grond als bij de knopnamen, glyph-check S7: art. 14 lid 1 UMV). Een eigen regel in de merkenregel is juridisch niet verplicht, maar wel netjes en kost niets. Geen Anthropic- of Claude-logo gebruiken, ook niet op de Steam-pagina.
- *Godot Engine* hoeft niet in de merkenregel: *Made with Godot Engine* (blok 4) is gewone, toegestane vermelding (B2). Geen Godot-logo zonder het na te lezen in de logo-regels van Godot.
- *Polderlight* volgt de werktitel en gaat mee na de formele merkcheck (glyph-check §4 punt 6). De vraag aan de specialist (glyph-check §4 punt 1) blijft staan; die verandert de tekst naar verwachting niet.

### 5.4 Taal van de licentie- en merkteksten

**Alleen Engels, ook in de Nederlandse versie.** De Godot-licentie, de FreeType-regel en `GODOT_COPYRIGHT.txt` zijn juridische teksten waarvan alleen de originele versie geldt; een vertaling voegt niets toe en kan afwijken. Voor de merkenregel is een vertaling toegestaan, maar niet nodig; één Engelse tekst houdt het onderhoud klein en blijft gelijk aan hoe de merkhouders hun merken noemen. Alleen de **koppen** (*Trademarks / Merken*, *Licenses / Licenties*) worden vertaald (§2). In `strings.csv` komen de teksten dus met dezelfde EN-tekst in beide kolommen, of als één niet-vertaalde tekst; dat kiest de Narrative Designer.

### 5.5 Eigen werk: Polderletter en de knop-glyphs

Beide staan nu als regel "eigen werk" in `docs/licenties.md` §2. Voor eigen werk is **geen vermelding verplicht**: blok 5 (*Lettertype*) **mag vervallen**. Laten staan mag ook (als dank aan het eigen font), dan zonder licentietekst. Dat is een keuze over de presentatie, niet juridisch (§6 punt 2).

### 5.6 AI-melding op de Steam-pagina (advies, geen besluit)

**Advies: ja, melden.** Valve vraagt in de *Content Survey* (bij het indienen van de game) of er generatieve AI is gebruikt, in twee soorten: *pre-generated* (vóór de release gemaakt) en *live-generated* (tijdens het spelen gemaakt) (B3). Bij *pre-generated* belooft de ontwikkelaar dat de inhoud niet illegaal of inbreukmakend is, en Valve toont een melding op de Steam-pagina (B4). Sinds januari 2026 gaat het alleen om AI-inhoud die **spelers zelf zien of horen** (art, geluid, tekst, verhaal); AI als efficiëntie-hulpmiddel (bv. code-assistenten) hoeft niet (B4).

Voor Polderlight: de art, audio en teksten worden door AI-rollen (Claude) gemaakt, ook als dat via scripts gebeurt. Dat is *pre-generated* inhoud die spelers zien; melden is dus nodig. *Live-generated* is er niet (geen AI tijdens het spelen).

- Dit staat **los van CEO-vraag [#157](https://github.com/cesarvangerwen-glitch/echoborn/issues/157)**: ook bij 1D (geen AI in de credits) blijft de Steam-melding nodig. 1D zou dan betekenen dat de Steam-pagina AI meldt en de credits niet; dat is een punt om mee te wegen, de keuze blijft bij de CEO.
- De meldtekst (kort, eerlijk, in de lijn van §3) schrijft de Marketing & Community Manager met de BLA, bij het maken van de Steam-pagina (§6 punt 5). De officiële Steamworks-tekst van de survey leest de BLA dan na (deze run niet bereikbaar).

### 5.7 Bronnen (BLA, geraadpleegd 2026-11-10)

- **B1** Godot Engine, *Complying with licenses* (docs "stable"). https://docs.godotengine.org/en/stable/about/complying_with_licenses.html — deze run alleen de inhoudsopgave bereikt (koppen *Credits screen, Licenses screen, Output log, Accompanying file, Printed manual*; *Third-party licenses: FreeType, ENet, mbed TLS*); de inhoud uit kennis van de pagina. Nalezen bij de build (§6 punt 1).
- **B2** Godot Engine, *License*. https://godotengine.org/license
- **B3** PC Gamer, *Valve updates its Steam policy on AI…* (10-01-2024, citeert Valve). https://www.pcgamer.com/valve-updates-its-steam-policy-on-ai-so-it-can-release-the-vast-majority-of-games-that-use-it
- **B4** Outlook Respawn, *Valve clarifies Steam AI policy: focus shifts to content consumed* (18-01-2026, citeert het nieuwe formulier: *"efficiency gains through the use of these tools are not the focus of this section"*). https://respawn.outlookindia.com/amp/story/gaming/gaming-news/valve-clarifies-steam-ai-policy-focus-shifts-to-content-consumed

## 6. Open punten

| # | Wat | Wie | Wanneer |
|---|---|---|---|
| 1 | `GODOT_COPYRIGHT.txt` (§5.2 punt 2) in elke export en elk depot zetten, het FreeType-jaar invullen, en B1 nog eens nalezen tegen de Godot-docs, ook of Mbed TLS (net als FreeType) een vaste regel in de credits vraagt. (BLA-deel afgerond in v0.1.3.) | Engine & Platform Programmer (export), BLA (nalezen) | Vóór de eerste publieke build |
| 2 | Blok 5 (*Lettertype*) behouden of schrappen: juridisch vrij (§5.5). (BLA-deel afgerond: eigen werk staat in `docs/licenties.md` §2.) | Producer | Bij de volgende versie van dit document |
| 3 | ~~Taal van de licentie- en merkteksten~~ **Afgerond (v0.1.3):** alleen Engels, ook in NL (§5.4). | — | — |
| 4 | Merkenregel is definitief (§5.3); open is alleen welke variant (met of zonder Anthropic); die volgt [#157](https://github.com/cesarvangerwen-glitch/echoborn/issues/157) vraag 1. De tekst gaat mee met punt 7. | Narrative Designer | Na #157 |
| 5 | AI-melding op Steam (advies §5.6: ja, *pre-generated*): meldtekst schrijven en de Steamworks-tekst van de survey nalezen. | Marketing & Community Manager, met de BLA | Bij het maken van de Steam-pagina |
| 6 | **CEO-vraag §4** bundelen en voorleggen. | Regisseur (Producer) | Volgende bundel CEO-vragen |
| 7 | De `CREDITS_*`-sleutels van §1 en §2 in `game/locale/strings.csv` zetten (EN/NL, met context); de sleutels zijn een voorstel, de tekst is van de Narrative Designer. | Narrative Designer | Na de CEO-keuze (§4) |
| 8 | hud-menus §7 punt 18 sluiten met een verwijzing naar dit document; dit document wijzigt hud-menus niet. | UX Designer | Bij zijn volgende wijziging van hud-menus |
| 9 | Placeholder in `genereer_menu_placeholder.py` (blok *Licenties*: *Tekst volgt*) vervangen door de echte inhoud, zodra punt 1 en §4 rond zijn. | UI Artist | Bij de eind-art van de credits |
| 10 | Credits bouwen uit dit document (de licentietekst bij voorkeur via `Engine.get_license_text()`, zodat hij altijd bij de gebruikte versie past). De bouw herbreekt de licentie-alinea's op de kolom van 320 px (± 71 tekens per regel), niet op de regels van `LICENSE.txt`. Onder de Godot-tekst de FreeType-regel en de verwijsregel van §5.2. | Gameplay Programmer | Met hud-menus §7 punt 19 (T8a) |

## 7. Wijzigingen

| Versie | Datum | Wat |
|---|---|---|
| 0.1.4 | 2026-11-10 | Na de Lead-review van de EP (PR #159): merkenregel in twee volledige varianten (1A–1C en 1D); werkaanname onder voorbehoud van B1; `get_copyright_info()`/`get_license_info()` als runtime-calls (Godot-script van dezelfde versie); §6 punt 1 ook Mbed TLS-regel nagaan. |
| 0.1.3 | 2026-11-10 | BLA (#87, open punten 1–5): §5.2 componenten van derden (FreeType-regel, `GODOT_COPYRIGHT.txt`, verwijsregel); §5.3 merkenregel definitief, Anthropic-zin afhankelijk van #157; nieuw §5.4 taal (alleen Engels), §5.5 eigen werk (blok 5 mag vervallen), §5.6 advies AI-melding Steam, §5.7 bronnen; §6 punt 3 afgerond, 1, 2, 4 en 5 tot één restregel; `docs/licenties.md` aangevuld. |
| 0.1.2 | 2026-11-10 | Na de SM-review (PR #156): 2A met naam in het besluit (`2A = <naam>`); plaats van de regel *Claude (AI, Anthropic)* (`CREDITS_TEAM_AI`, bovenaan blok 3) met duurschatting; herbreken van de licentietekst (open punt 10). |
| 0.1.1 | 2026-11-10 | Na de Lead-review van de EP (PR #156): werkaanname correct geciteerd; 7 kopsleutels `CREDITS_TEAM_*` met EN/NL; roltitels = namen (niet vertaald); voorbeeld bij 2A zonder roltitel; Engelse licentietekst als werkaanname. |
| 0.1 | 2026-11-10 | Eerste versie (#87): opbouw, sleutels (voorstel), rollen, CEO-vraag namen en rollen, Godot-licentie, merkenregel, open punten voor de BLA. |
