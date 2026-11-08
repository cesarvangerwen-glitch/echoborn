# Beslissingslog

Alleen CEO-beslissingen. Nieuwste bovenaan. Alleen wijzigen na een `Besluit:` van de CEO.

| Datum | Besluit | Toelichting |
|---|---|---|
| 2026-11-08 | **Ritme op basis van het weekbudget aan credits** (#52): 5 regie-runs per dag (± 07, 11, 15, 19, 23 uur), zelfsturend op een weekdoel van ± 92 % van de credits (Max-abonnement, reset dinsdag 16:00) | Gekozen optie 1A (via meerkeuze in de Claude-chat). Vervangt punt 2A van besluit #47 (2 runs, max. 4 maak-agents per dag); 1A en 3A van #47 blijven. Elke run max. 3 maak-agents met reviews en herstel in dezelfde run; voorlopen op het weekdoel of geen klaar werk = meteen stoppen; geen verspilling (geen polish-issues, geen dubbele reviews). Ijking 2026-11-08: 3 % weekverbruik ≈ 1,5–2 M tokens (1 % ≈ 0,5–0,7 M); bijsturen met het tokenlog en een `Info: credits …`-regel van de CEO. |
| 2026-11-08 | **Reviewketen en ritme van twee runs per dag** (#47) · SM-review alleen voor CEO-/gatewerk, code in `game/` en een steekproef van 1 op 3; anders telt Lead-akkoord als goedgekeurd · ochtendrun maken, avondrun afronden · kleiner model toegestaan voor SM-review en administratief werk | Gekozen opties 1A, 2A en 3A (akkoord, via meerkeuze in de Claude-chat). Bron: procesrapport week 1 (#45, PR #46): de SM keurde in week 1 0 van 13 PR's af, reviews kostten ≈ 55 % van de tokens. Ochtend (± 07:00): CEO-besluiten, mergen, max. 3 maak-agents met Lead-review en herstel in dezelfde run. Avond (± 19:00): SM-reviews, mergen, max. 1 kleine maak-agent, één dagrapport per dag; geen werk = vroeg stoppen. Max. 4 maak-agents per dag. Maakwerk, Lead-reviews en de regisseur blijven op het huidige model. De Workflow Lead verwerkt dit in `WERKWIJZE.md` §5, README en `producer-regie.md`. |
| 2026-11-08 | **Nieuwe werktitel: *Wraithstep*** (#24), vervangt Echoborn · formele merkcheck door een specialist vóór de eerste publicatie met de naam | Gekozen opties 1A en 3A; de naam koos de CEO uit een brainstorm van 10 opties (comment in #24). Reden: actieve game ECHOBORN in hetzelfde genre en een US-merkaanvraag (zie `docs/business/naamcheck.md`). Wraithstep: een spookachtige voetstap die de jouwe herhaalt. Aandachtspunt CD: de naam klinkt duisterder dan de toon (PEGI 12); de Creative Director bewaakt dat in de pitch. Repo-naam en mappen blijven voorlopig "echoborn". |
| 2026-11-08 | **Stijl: 2D** (#18): pixel art op 640×360 (Steam Deck 640×400) met dynamisch 2D-licht | Gekozen optie 1A uit de stijltests (`docs/art/stijltests.md`): scherpste grens tussen licht- en schaduwlaag, "vol = levend, hol = echo" goed leesbaar, sluit aan op de 2D-echo-spike, geen 3D-rollen nodig. Prestaties op de Steam Deck worden nog gemeten (Technical Artist, Engine & Platform Programmer). |
| 2026-11-08 | **Randvoorwaarden** (#2): budget per fase · geen deadline · omvang 5–7 uur, 3–4 gebieden, 4–5 bosses · ~€20, geen microtransacties, DLC alleen na nieuw besluit · zelf financieren + subsidies uitzoeken, geen publisher voorlopig · duister maar niet gruwelijk, PEGI 12 · alleen Engels bij launch, Steam Deck verified als doel · geen extra no-go's/must-haves | EP vraagt per fase budget aan; EP stelt na fase 2 een releasevenster voor; Business/Legal zoekt subsidies (bv. VAF Gamefonds) uit |
| 2026-11-08 | Werkwijze: GitHub + één dagelijkse regie-run (Producer) die rollen als agents inzet | Rollen als bestanden in `studio/roles/`; communicatie via issues en PR's |
| 2026-11-08 | **Concept B, *Echoborn*, is de voorlopige keuze** | Schaduw herhaalt je laatste 10 seconden; licht- en schaduwlaag; solo en co-op op dezelfde mechaniek. Definitief na de conceptfase. |
| 2026-11-08 | Engine: **Godot 4.6** | Gratis, open source, sterke 2D, geen royalties |
| 2026-11-08 | Organigram v2 goedgekeurd (26 functies) | Network Programmer geschrapt; Engine & Platform Programmer; 2D Environment Artist toegevoegd |
| 2026-11-08 | Co-op: **lokaal** (geen online) | Gedeelde camera, drop-in/drop-out |
| 2026-11-08 | Stijl: **2D of 2.5D** | Keuze na stijltests van de Art Director (besloten: 2D, zie hierboven) |
| 2026-11-07 | Pc, volledige indie-release, singleplayer + co-op, doelgroep 18–30 | Startbriefing CEO |

## Werkaannames (nog geen besluit)

Deze gelden tot de CEO ze vastlegt of wijzigt.

| Onderwerp | Aanname |
|---|---|
| Totaalbudget, releasevenster | Volgen per fase (zie besluit Randvoorwaarden) |
