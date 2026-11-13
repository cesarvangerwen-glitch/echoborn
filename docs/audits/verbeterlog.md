# Verbeterlog

Dit log houdt alle verbeteracties uit de wekelijkse audits bij. Het externe consultancyteam (`consultancy/lead.md`) werkt dit log bij tijdens elke audit. De CEO keurt acties goed, de studio voert ze uit.

**Statussen:** Voorgesteld → Goedgekeurd → In uitvoering → ✅ Werkt / 🟡 Gedeeltelijk / 🔄 Geen effect / ❌ Niet doorgevoerd / Geschrapt

## Acties

| ID | Datum | Gebied | Actie | Eigenaar | Status | Hoe meten we het? | Resultaat |
|---|---|---|---|---|---|---|---|
| A1-01 | 2026-11-13 | Kennis / Processen | Besluiten laten doorwerken: blok "Geldend nu" en statuskolom in `docs/beslissingen.md` (vervangen rijen naar archief), plus een stap "na elk `Besluit:`" in `producer-regie.md` (grep op de oude waarde, checklist per geraakt document) | Producer (vorm van het log: CEO) | Voorgesteld | 0 ongemarkeerde vervallen besluiten; ≤ 2/10 "niet akkoord" wegens achterhaalde tekst (nulmeting 5/10); `beslissingen.md` ≤ 8k tekens (nulmeting 14,3k) | |
| A2-01 | 2026-11-13 | Organisatie / Kennis | De skillvoorstelronde van gate 1 alsnog uitvoeren: 26 rolbestanden actualiseren (Polderlight, SM conform #47, AD 2D, ritme), #40 sluiten, een sectie "Projectkennis en bekende valkuilen" voor de 6 Leads en de 3 meest actieve makers, en een vast skillrapport-issue per gate | Studio Manager | Voorgesteld | ≥ 1 gemergede `skillvoorstel`-PR; 0/26 rolbestanden noemen *Echoborn* (nulmeting 26/26); ≥ 9 rolbestanden > v1.0 met een sectie Projectkennis (nulmeting 0) | |
| A3-01 | 2026-11-13 | Kwaliteit | De CEO speelt MT1 en beslist expliciet over de kernfantasie (echo van 1 s tegenover "laatste 10 seconden"); de CD verwerkt dat in pitch, README en GDD | CEO (+ Creative Director) | Voorgesteld | MT1-kaart ingevuld in `docs/qa/`; `README.md` en `echo_v04.json` beschrijven dezelfde echo | |

## Maturiteit over de tijd

| Audit | Datum | Organisatie | Processen | Kwaliteit | Kennis |
|---|---|---|---|---|---|
| #01 | 2026-11-13 | 2 | 3 | 3 | 2 |

## Lessen geleerd

Elke les wordt pas afgevinkt als ze aantoonbaar verwerkt is in `studio/WERKWIJZE.md`, een rolbestand in `studio/roles/` of de docs.

- [ ] (2026-11-13) Een besluit is pas af als elk document dat het oude besluit noemt, is bijgewerkt → te verwerken in `studio/WERKWIJZE.md` §10 (Grenzen) en als vaste stap in `studio/regie/producer-regie.md`
