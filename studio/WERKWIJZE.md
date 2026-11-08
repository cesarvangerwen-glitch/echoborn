# Werkwijze van de studio

Dit bestand geldt voor **elke rol**. Je rolbestand in `studio/roles/` zegt wat jij doet; dit bestand zegt hoe we samenwerken.

## 1. Wie is wie

- **CEO**: eigenaar van de repo, een mens. Beslist over visie, scope, budget en grote afwegingen. Verder niets.
- **Rollen**: 26 functies, elk met een eigen rolbestand. Je bent op elk moment precies één rol.
- **Regisseur**: de dagelijkse run van de Producer (`studio/regie/producer-regie.md`) die bepaalt welke rollen vandaag werken.

## 2. Je run, stap voor stap

1. Lees `README.md`, dit bestand, je eigen rolbestand en `docs/beslissingen.md`.
2. Lees het issue dat je kreeg, inclusief alle comments, en de documenten waarnaar het verwijst.
3. Doe het werk, binnen je vakgebied. Werk buiten je vak? Open een issue voor de rol die er eigenaar van is.
4. Lever op via een **pull request** (zie 4). Documenten in `docs/`, game-bestanden in `game/`.
5. Zet een comment in het issue met wat je deed, waar het staat, en wat nog openstaat.
6. Kun je niet verder? Zet het label `status:geblokkeerd` en schrijf precies wat je nodig hebt en van wie.

Je onthoudt niets tussen runs. **Alles wat de volgende run moet weten, staat in de repo**: in een document, een issue-comment of het beslissingslog.

## 3. Communicatie

- Elke comment begint met: `[Jouw rol → Ontvanger]: bericht`
- Ontvanger is een rol, `Team`, of `CEO`.
- Kort en concreet: wat, waarom, wat heb je nodig, tegen wanneer.
- Kleine knopen hakt de verantwoordelijke Lead zelf door. Alleen visie, scope, budget en grote afwegingen gaan naar de CEO.

## 4. Branches, commits en pull requests

- Branch: `rol/<rol-slug>/<issue-nr>-<kort-onderwerp>`, bv. `rol/gameplay-programmer/12-echo-opname`
- Commitbericht: `[<rol-slug>] korte omschrijving (#issue)`
- PR-titel: `[<rol>] <deliverable> (#issue)`. In de PR-beschrijving: wat, hoe te controleren, bekende beperkingen.
- **Niemand merget zijn eigen PR.** Mergen gebeurt pas na goedkeuring door de Studio Manager.

## 5. Werkstroom van een deliverable

1. **Team** maakt het werk → PR met label `status:interne-review`
2. **Team Lead** reviewt (zie tabel) → comment `Lead-review: akkoord` of concrete feedback
3. **Studio Manager** beoordeelt met de rubric → label `status:goedgekeurd` of `status:afgekeurd`
4. Bij goedkeuring merget de regisseur de PR. Bij afkeuring gaat het terug naar het team.
5. **CEO** komt alleen in beeld via `ceo-beslissing` of het fase-statusrapport.

| Rol | Team Lead voor interne review |
|---|---|
| Workflow & Process Optimization Lead | Studio Manager |
| Producer, QA Lead, Marketing & Community Manager, Business/Legal Advisor | Executive Producer |
| Narrative Designer | Creative Director |
| Systems, Combat, World & Level, UX Designer | Lead Game Designer |
| Gameplay, Engine & Platform, Tools Programmer | Technical Director |
| Concept Artist, 2D Environment Artist, Animator, Technical Artist, UI Artist | Art Director |
| Composer/Sound Designer | Audio Director |
| Leads zelf (Creative Director, Lead Game Designer, Technical Director, Art Director, Audio Director, Executive Producer) | Executive Producer (de EP zelf: Creative Director) |

## 6. Rubric van de Studio Manager

Elk criterium krijgt een score van 1–10:

| Criterium | Vraag |
|---|---|
| Kwaliteit | Is het vakmanschap op het niveau van een goede indie-release? |
| Aansluiting bij de visie | Versterkt het de kernfantasie en de echo-mechaniek? |
| Haalbaarheid | Kan dit gebouwd worden binnen scope, tijd en Godot 4.6? |
| Volledigheid | Is alles aanwezig wat de volgende rol nodig heeft? |

**Eén criterium onder de 7 = afgekeurd**, met minstens drie concrete verbeterpunten.

## 7. Labels

| Label | Betekenis |
|---|---|
| `rol:<rol-slug>` | Wie eigenaar is van het issue |
| `fase:1-concept` … `fase:5-launch` | Fase |
| `status:todo` | Klaar om op te pakken |
| `status:bezig` | Wordt aan gewerkt |
| `status:interne-review` | Wacht op Team Lead |
| `status:sm-review` | Wacht op Studio Manager |
| `status:afgekeurd` | Terug naar het team |
| `status:goedgekeurd` | Klaar om te mergen |
| `status:geblokkeerd` | Kan niet verder, zie laatste comment |
| `ceo-beslissing` | Wacht op de CEO. Werk dat ervan afhangt stopt. |
| `skillvoorstel` | Voorstel om een rolbestand te wijzigen |

## 8. Rolbestanden verbeteren

Na elke mijlpaal stelt de Studio Manager wijzigingen aan rolbestanden voor als PR met label `skillvoorstel` en `ceo-beslissing`. De CEO beslist. Elke goedgekeurde wijziging verhoogt het versienummer bovenaan het rolbestand.

## 9. Assets maken

Art-, animatie- en audiorollen maken **echte assets**, niet alleen briefings. Gebruik de tools in je werkomgeving (bv. Python met Pillow/numpy, SVG, code-gegenereerde audio). Markeer werk dat nog niet eindkwaliteit is met `_placeholder` in de bestandsnaam. Loop je vast op kwaliteit? Open een issue met het label `brainstorm` en vraag om een sessie met de CEO.

## 10. Grenzen

- Raak geen bestanden van een andere rol aan zonder een issue.
- Verander nooit `docs/beslissingen.md` zonder een `Besluit:` van de CEO.
- Externe assets, fonts of plug-ins alleen met een licentie die in `docs/licenties.md` staat (beheer: Business/Legal Advisor).
