# Licentieregister

Beheer: Business/Legal Advisor. Elk extern asset, font, plug-in of tool hoort hier, vóór het in de game komt. Eigen werk staat er ook in, zodat duidelijk is dat er geen licentie van derden nodig is.

## 1. Extern

| Item | Bron | Licentie | Commercieel gebruik | Verplichte vermelding |
|---|---|---|---|---|
| Godot Engine 4.6 | godotengine.org | MIT | Ja | Ja: de licentietekst met de copyrightregels in de game (credits, blok *Licenties*); zie `docs/productie/credits.md` §5.1 |
| Componenten van derden in de Godot-export (o.a. FreeType, Mbed TLS, ENet, zlib, libpng; de volledige lijst met licenties staat in `COPYRIGHT.txt` van de gebruikte Godot-versie; nagelezen 2026-11-11, credits.md §5.2) | Godot-broncode, `COPYRIGHT.txt`; in de game via `Engine.get_copyright_info()` en `Engine.get_license_info()` | Verschillende permissieve licenties (o.a. FreeType License, Apache 2.0, MIT, BSD, zlib) | Ja | Ja, voor alle componenten in de export-template (ook ENet, zonder multiplayer): (1) de FreeType-regel in de credits, onder de Godot-tekst (FreeType License); (2) het bestand `GODOT_COPYRIGHT.txt` (= `COPYRIGHT.txt` van precies de gebruikte versie) naast de game in elke build, met een verwijsregel in de credits. Zie credits.md §5.2. |

## 2. Eigen werk (geen licentie van derden)

| Item | Bron | Licentie | Commercieel gebruik | Verplichte vermelding |
|---|---|---|---|---|
| Inhoud gemaakt door de AI-rollen (code, art, audio, tekst) | Claude (Anthropic), via het abonnement van de CEO | Geen licentie van derden: Anthropic draagt zijn rechten op de output over aan de gebruiker, "if any" en mits de voorwaarden gevolgd worden (Consumer Terms §4, credits.md §5.3, B6) | Ja | Geen licentievermelding; de naam *Claude*/*Anthropic* in de credits vraagt, letterlijk gelezen, voorafgaande schriftelijke toestemming volgens de Consumer Terms §12; of een feitelijke vermelding daaronder valt, zeggen de voorwaarden niet (credits.md §5.3, CEO-vraag §5.8) |
| Lettertype *Polderletter* (normaal, groot, titel, naam; `game/art/ui/font/`) | Eigen werk van de UI Artist, getekend in `docs/art/ui/bron/polderletter.py` (stijlgids §4) | Eigen werk van de studio | Ja | Nee |
| Knop-glyphs (toetsenbord, Xbox-stijl, PlayStation-stijl, Steam Deck; `game/art/ui/glyphs/`) | Eigen tekeningen van de UI Artist (stijlgids §13) | Eigen werk van de studio; de vormen verwijzen naar merken van derden, zie `docs/business/knop-glyphs-check.md` | Ja, onder de regels van de glyph-check §3 | Ja, maar geen licentie: de merkenregel in de credits (credits.md §5.3) |

## 3. Regels

- **Nieuw component of SDK** (bv. Steamworks of GodotSteam, een addon in `game/addons/`, een eigen export-template): eerst hier een regel, vóór het in de game komt. Een SDK met een eigen licentie kan een extra vermelding vragen.
- **Eigen export-template met uitgeschakelde modules**: dan hoeven de licenties van de uitgeschakelde modules niet mee; `GODOT_COPYRIGHT.txt` mag dan uit die build komen (`Engine.get_copyright_info()`).
- **Taal**: licentie- en merkteksten blijven in het Engels, ook in de Nederlandse versie (credits.md §5.4).

## 4. Bronnen

- Godot Engine, *Complying with licenses* (Godot-docs "stable" = 4.6; gelezen 2026-11-11 via de bron op GitHub, de HTML-pagina was niet bereikbaar): de licentietekst van Godot moet in of bij de game (één vorm volstaat, ook een link naar `godotengine.org/license`); de componenten van derden vallen niet onder de MIT-licentie en veel vragen een vermelding, met `COPYRIGHT.txt` (bv. hernoemd naar `GODOT_COPYRIGHT.txt`) als goede optie. https://docs.godotengine.org/en/stable/about/complying_with_licenses.html · bron: https://github.com/godotengine/godot-docs/blob/4.6/about/complying_with_licenses.rst. De docs voor 4.0–4.2 noemden FreeType, ENet en Mbed TLS nog apart, voor alle officiële export-templates: https://github.com/godotengine/godot-docs/blob/4.2/about/complying_with_licenses.rst (credits.md §5.7, B1, B1a).
- Godot Engine, `COPYRIGHT.txt` (tak 4.6, gelezen 2026-11-11): FreeType (*FTL*: vermelding in de documentatie verplicht, creditregel aanbevolen), Mbed TLS (*Apache-2.0*), ENet (*Expat*). https://github.com/godotengine/godot/blob/4.6/COPYRIGHT.txt (credits.md B5).
- Anthropic, *Consumer Terms of Service* (effective Oct 8, 2025; gelezen 2026-11-11): §4 eigendom van Outputs, §12 *Use of our brand*. https://www.anthropic.com/legal/consumer-terms (credits.md B6; ook B7 *Trademark Guidelines*).
- Godot Engine, *License* (met link naar de lijst van componenten van derden). https://godotengine.org/license
