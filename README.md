# Echoborn (werktitel)

Een 2D/2.5D-metroidvania voor pc (Steam, Steam Deck als doel), singleplayer en lokale co-op, voor spelers van 18–30 jaar. Gebouwd in **Godot 4.6**.

**Kernidee:** je schaduw herhaalt je laatste 10 seconden. Solo gebruik je die echo als tweede speler; in co-op bestuurt speler 2 de schaduw live. De wereld heeft een lichtlaag en een schaduwlaag, en dat is ook de basis van de gating.

## Hoe deze studio werkt

Deze repo is tegelijk de game én de studio. Elke functie is een rolbestand in `studio/roles/`. Een dagelijkse geplande taak (de **Producer als regisseur**) zet per taak een agent in met het juiste rolbestand. Die agents communiceren via issues en pull requests. De Studio Manager beoordeelt elk werkstuk apart, met een frisse blik.

| Map | Inhoud |
|---|---|
| `studio/WERKWIJZE.md` | Werkstroom, communicatie via GitHub, labels, rubric. **Lees dit eerst.** |
| `studio/roles/` | Eén rolbestand per functie (26) |
| `studio/regie/producer-regie.md` | Instructie voor de dagelijkse regie-run |
| `docs/beslissingen.md` | Log van alle CEO-beslissingen |
| `docs/` | Ontwerpdocumenten (pitch, GDD, art bible, technisch ontwerp, …) |
| `game/` | Het Godot-project |
| `.github/ISSUE_TEMPLATE/` | Templates voor taken, CEO-beslissingen, bugs |

## Rol van de CEO

De CEO (eigenaar van deze repo) beslist alleen over visie, scope, budget en grote afwegingen. Die vragen komen als issue met het label `ceo-beslissing`: genummerde vragen met lettervoorstellen (A, B, C), de aanbeveling altijd als A. De CEO antwoordt kort, bv. `Besluit: 1A, 2B` of `Besluit: akkoord` (alle aanbevelingen). Of de CEO vraagt in een Claude-chat om de openstaande vragen als klikbare meerkeuze.
