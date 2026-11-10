# Licentieregister

Beheer: Business/Legal Advisor. Elk extern asset, font, plug-in of tool hoort hier, vóór het in de game komt. Eigen werk staat er ook in, zodat duidelijk is dat er geen licentie van derden nodig is.

## 1. Extern

| Item | Bron | Licentie | Commercieel gebruik | Verplichte vermelding |
|---|---|---|---|---|
| Godot Engine 4.6 | godotengine.org | MIT | Ja | Ja: de licentietekst met de copyrightregels in de game (credits, blok *Licenties*); zie `docs/productie/credits.md` §5.1 |
| Componenten van derden in de Godot-export (o.a. FreeType, Mbed TLS, ENet, zlib, libpng; de volledige lijst staat in `COPYRIGHT.txt` van de gebruikte Godot-versie) | Godot-broncode, `COPYRIGHT.txt`; in de game via `Engine.get_copyright_info()` en `Engine.get_license_info()` | Verschillende permissieve licenties (o.a. FreeType License, Apache 2.0, MIT, BSD, zlib) | Ja | Ja: (1) de FreeType-regel in de credits, onder de Godot-tekst; (2) het bestand `GODOT_COPYRIGHT.txt` (= `COPYRIGHT.txt` van precies de gebruikte versie) naast de game in elke build, met een verwijsregel in de credits. Zie credits.md §5.2. |

## 2. Eigen werk (geen licentie van derden)

| Item | Bron | Licentie | Commercieel gebruik | Verplichte vermelding |
|---|---|---|---|---|
| Lettertype *Polderletter* (normaal, groot, titel, naam; `game/art/ui/font/`) | Eigen werk van de UI Artist, getekend in `docs/art/ui/bron/polderletter.py` (stijlgids §4) | Eigen werk van de studio | Ja | Nee |
| Knop-glyphs (toetsenbord, Xbox-stijl, PlayStation-stijl, Steam Deck; `game/art/ui/glyphs/`) | Eigen tekeningen van de UI Artist (stijlgids §13) | Eigen werk van de studio; de vormen verwijzen naar merken van derden, zie `docs/business/knop-glyphs-check.md` | Ja, onder de regels van de glyph-check §3 | Ja, maar geen licentie: de merkenregel in de credits (credits.md §5.3) |

## 3. Regels

- **Nieuw component of SDK** (bv. Steamworks of GodotSteam, een addon in `game/addons/`, een eigen export-template): eerst hier een regel, vóór het in de game komt. Een SDK met een eigen licentie kan een extra vermelding vragen.
- **Eigen export-template met uitgeschakelde modules**: dan hoeven de licenties van de uitgeschakelde modules niet mee; `GODOT_COPYRIGHT.txt` mag dan uit die build komen (`Engine.get_copyright_info()`).
- **Taal**: licentie- en merkteksten blijven in het Engels, ook in de Nederlandse versie (credits.md §5.4).

## 4. Bronnen

- Godot Engine, *Complying with licenses* (Godot-docs, "stable"): de licentietekst moet in de game of bij de game (credits, licentiescherm, bestand naast de game, …); de componenten van derden vragen een vermelding, met `COPYRIGHT.txt` (bv. hernoemd naar `GODOT_COPYRIGHT.txt`) als goede optie; FreeType vraagt een vaste regel; ENet alleen bij multiplayer via ENet; Mbed TLS moet mee. https://docs.godotengine.org/en/stable/about/complying_with_licenses.html (deze run alleen de inhoudsopgave bereikt, de rest uit kennis van de pagina; nalezen vóór de eerste publieke build, credits.md §6 punt 1).
- Godot Engine, *License* (met link naar de lijst van componenten van derden). https://godotengine.org/license
