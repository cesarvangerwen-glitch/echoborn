# Credits *Polderlight*: inhoud

Versie 0.1.1 · 2026-11-10 · eigenaar: Producer, met de Business/Legal Advisor (BLA) · issue [#87](https://github.com/cesarvangerwen-glitch/echoborn/issues/87) (T10, "credits-inhoud")

Dit document geeft de **inhoud** van het credits-scherm (`docs/ux/hud-menus.md` MN-37, §7 punt 18). Indeling en bediening staan in hud-menus §4.9 (MN-35, MN-36); de mock-up is `menu_credits_x2_placeholder.png` (`docs/art/ui-stijlgids.md` §12.6, script `docs/art/ui/bron/genereer_menu_placeholder.py`).

**Werkaanname (fase-2-kader §5):** hud-menus W7 (de spec is de versie vóór F0), stijlgids W7 (de credits-mock-up is een placeholder) en stijlgids §4 (het font is Polderletter, eigen werk). Verder: de namen en rollen in §3 zijn een voorstel tot de CEO beslist (§4); de licentieteksten in §5 zijn wat `docs/licenties.md` nu vraagt, tot de BLA bevestigt (§6).

## 1. Opbouw en volgorde

Blokken van een kop met de regels eronder (MN-35). Van boven naar beneden:

| # | Blok | Kop (sleutel, voorstel) | Inhoud | Bron |
|---|---|---|---|---|
| 1 | Titel | — (`GAME_TITLE`, bestaat al) | *Polderlight* | besluit #96 |
| 2 | Makers | `CREDITS_MADE_BY` | Wie het spel maakt: zie §3 en CEO-vraag §4 | — |
| 3 | Rollen | per vakgebied `CREDITS_TEAM_*` (§3; optie 1A, zie §4) | De AI-rollen, volgens de keuze in §4 | `studio/roles/` |
| 4 | Gemaakt met | `CREDITS_MADE_WITH` | *Godot Engine* | MN-37 |
| 5 | Lettertype | `CREDITS_FONT` | *Polderletter*, eigen werk van de studio (geen licentie van derden) | stijlgids §4, §10 punt 7 |
| 6 | Merken | `CREDITS_TRADEMARKS` | De merkenregel (§5.3) | `docs/business/knop-glyphs-check.md` §3 punt 4 |
| 7 | Licenties | `CREDITS_LICENSES` | De Godot-licentietekst (§5.1) en wat de BLA nog toevoegt (§5.2) | `docs/licenties.md` |
| 8 | Slot | `CREDITS_THANKS` | *Bedankt voor het spelen* | — |

Waarom deze volgorde: eerst wie het maakte (wat spelers zoeken), dan het gereedschap, en de lange juridische teksten onderaan, zodat ze de rest niet ophouden bij 20 px/s (MN-36; leesbaarheid bekijkt de UX Designer na T11, hud-menus §7 punt 20).

## 2. Taal

- **Koppen** worden vertaald (EN bron, NL). Voorstel EN/NL: *Made by / Gemaakt door*, de 7 vakgebieden (§3), *Made with / Gemaakt met*, *Font / Lettertype*, *Trademarks / Merken*, *Licenses / Licenties*, *Thank you for playing / Bedankt voor het spelen*. De Narrative Designer schrijft de definitieve tekst.
- **Namen** worden niet vertaald (MN-37), ook *Godot Engine*, *Polderletter* en de merknamen niet (glyph-check §3 punt 6).
- **Roltitels** (*Art Director*, *QA Lead*, …) gelden als **namen**: ze worden niet vertaald en komen niet in `strings.csv` (MN-37); alleen de vakgebied-koppen erboven worden vertaald. Zo blijven ze gelijk aan `studio/roles/`.
- **Licentie- en merkteksten**: werkaanname tot de BLA beslist (§6 punt 3): in beide talen de originele Engelse tekst, zonder vertaling.

## 3. Namen en rollen (voorstel)

De studio is de CEO (een mens) en 26 AI-rollen (`studio/roles/`, Claude van Anthropic). Er is nog geen studionaam; de mock-up gebruikt *Een spel van de studio* als plaatshouder. Hoe de CEO en de AI-rollen in de credits komen, is een keuze over hoe het spel zich presenteert, dus een CEO-vraag (§4). Tot dan geldt optie 1A en 2A als werkaanname.

De rollen per vakgebied (voor optie 1A), in de volgorde van het organigram:

| Vakgebied (kop) | Sleutel (voorstel) | EN / NL (voorstel) | Rollen (namen, niet vertaald) |
|---|---|---|---|
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
- **A. Per vakgebied, met de rollen en "Claude (AI, Anthropic)"** ⭐ Aanbevolen: eerlijk en compact, 7 blokken (§3), ± 25 s scrollen bij 20 px/s; € 0.
- **B. Elke rol als eigen blok met "Claude (AI)"**: volledig, maar 26 bijna gelijke blokken (± 50 s); € 0.
- **C. Eén regel "Gemaakt met AI-rollen (Claude, Anthropic)", zonder rollen**: kortst, maar de structuur van de studio verdwijnt; € 0.
- **D. Geen vermelding van AI in de credits**: niet aanbevolen; staat los van een eventuele AI-melding op de Steam-pagina (BLA, §6 punt 5); € 0.

**2. Hoe staat de CEO bovenaan?**
- **A. Met de eigen naam onder de kop *Made by* / *Gemaakt door*, zonder roltitel** (botst dan niet met de AI-rollen) ⭐ Aanbevolen: de mens achter het spel is zichtbaar; € 0.
- **B. Alleen een studionaam (later te kiezen, met naamcheck)**: anoniemer; vraagt een naamkeuze en check (± 2–3 runs, € 0 tot de formele merkcheck).
- **C. Eigen naam én een studionaam**: B en A samen; zelfde kost als B.

### Waarom deze aanbeveling
1A is eerlijk over hoe het spel gemaakt is zonder 26 keer dezelfde naam te laten zien, en houdt de credits kort genoeg om te lezen. 2A vraagt geen nieuwe naam of check en kan later altijd uitgebreid worden met een studionaam (2C).

### Wat wacht hierop
- [#87](https://github.com/cesarvangerwen-glitch/echoborn/issues/87) (credits-inhoud, hud-menus §7 punt 18)

*CEO: antwoord kort met een comment die begint met `Besluit:`, bv. `Besluit: 1A, 2A` of `Besluit: akkoord`.*

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

### 5.2 Andere componenten

`docs/licenties.md` noemt nu **alleen Godot**. Er zijn geen externe assets, fonts, plug-ins of addons (`game/` heeft geen `addons/`); Polderletter en de knop-glyphs zijn eigen werk (stijlgids §4, glyph-check). Of de componenten van derden **binnen** de Godot-export (bv. FreeType, ENet, mbedTLS; Godot geeft ze met `Engine.get_copyright_info()` en `Engine.get_license_info()`) ook in de credits moeten, staat niet in het register: dat bevestigt de BLA (§6 punt 1). Hier wordt niets bijgezet tot dan.

### 5.3 Merkenregel

Uit `docs/business/knop-glyphs-check.md` §3 punt 4 (voorbeeldtekst, Engels; ook in de mock-up):

> Xbox is a trademark of the Microsoft group of companies. PlayStation is a registered trademark or trademark of Sony Interactive Entertainment Inc. Steam and Steam Deck are trademarks and/or registered trademarks of Valve Corporation. Polderlight is not affiliated with or endorsed by Microsoft, Sony Interactive Entertainment or Valve.

De definitieve tekst stemt de Narrative Designer af met de BLA (glyph-check §4 punt 4); *Polderlight* volgt de werktitel.

## 6. Open punten

| # | Wat | Wie | Wanneer |
|---|---|---|---|
| 1 | **Bevestigen welke licentieteksten verplicht zijn**: is de Godot-tekst van §5.1 genoeg, of moeten ook de componenten van derden in de Godot-export (FreeType, ENet, mbedTLS, …) erbij, in de credits of in een apart bestand naast de game? Zo nodig `docs/licenties.md` aanvullen. | Business/Legal Advisor | Vóór de eerste publieke build |
| 2 | Polderletter (en de knop-glyphs) als regel "eigen werk" in `docs/licenties.md`, en of blok 5 (*Lettertype*) in de credits moet of mag vervallen (stijlgids §10 punt 7, glyph-check §4 punt 5). | Business/Legal Advisor | Geen haast |
| 3 | Licentie- en merkteksten alleen in het Engels, of ook een NL-vertaling? | Business/Legal Advisor | Met punt 1 |
| 4 | Merkenregel definitief (§5.3), en of de vermelding van Claude/Anthropic in §3 een eigen regel of toestemming vraagt. | Business/Legal Advisor, met de Narrative Designer | Vóór de eerste publieke build |
| 5 | Moet de AI-inzet ook op de Steam-pagina gemeld worden (los van de credits)? Raakt CEO-vraag 1D. | Business/Legal Advisor | Vóór de Steam-pagina |
| 6 | **CEO-vraag §4** bundelen en voorleggen. | Regisseur (Producer) | Volgende bundel CEO-vragen |
| 7 | De `CREDITS_*`-sleutels van §1 en §2 in `game/locale/strings.csv` zetten (EN/NL, met context); de sleutels zijn een voorstel, de tekst is van de Narrative Designer. | Narrative Designer | Na de CEO-keuze (§4) |
| 8 | hud-menus §7 punt 18 sluiten met een verwijzing naar dit document; dit document wijzigt hud-menus niet. | UX Designer | Bij zijn volgende wijziging van hud-menus |
| 9 | Placeholder in `genereer_menu_placeholder.py` (blok *Licenties*: *Tekst volgt*) vervangen door de echte inhoud, zodra punt 1 en §4 rond zijn. | UI Artist | Bij de eind-art van de credits |
| 10 | Credits bouwen uit dit document (de licentietekst bij voorkeur via `Engine.get_license_text()`, zodat hij altijd bij de gebruikte versie past). | Gameplay Programmer | Met hud-menus §7 punt 19 (T8a) |

## 7. Wijzigingen

| Versie | Datum | Wat |
|---|---|---|
| 0.1.1 | 2026-11-10 | Na de Lead-review van de EP (PR #156): werkaanname correct geciteerd; 7 kopsleutels `CREDITS_TEAM_*` met EN/NL; roltitels = namen (niet vertaald); voorbeeld bij 2A zonder roltitel; Engelse licentietekst als werkaanname. |
| 0.1 | 2026-11-10 | Eerste versie (#87): opbouw, sleutels (voorstel), rollen, CEO-vraag namen en rollen, Godot-licentie, merkenregel, open punten voor de BLA. |
