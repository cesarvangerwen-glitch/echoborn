# Testplan MT3: mijlpaaltest slice op eindkwaliteit, solo én co-op (T11, F4b(a)–(c))

Versie 0.1 (concept) · 2026-11-14 · Eigenaar: QA Lead (met Lead Game Designer) · Issue: [#88](https://github.com/cesarvangerwen-glitch/echoborn/issues/88) (T11, Q-4) · Lead-review: Executive Producer

Basis: fasekader fase 2 (`docs/productie/fase-2-kader.md`: §3 F4b (a)–(c), §4 mijlpaaltest MT3 en "geen CEO-test zonder groene bots", §5 kwaliteitslat); `docs/qa/testplan-t11-slice.md` v0.4 (§4, §4.1, §4.2, §6, §7); `docs/qa/testplan-f0.md` §1 (co-op-normen); gdd §4.5 (MP-1–MP-7) en §4.8.8 (keerpunten in co-op); `docs/design/gemaalmeester.md` §8 (GM-a–GM-d); `docs/design/combat/slice-vijanden-en-boss.md` v0.1.7 (§3.10, GMB-14, GMB-15, B-14).

Dit is een **concept**: het legt vast wanneer MT3 start, welke bot-checks eerst groen moeten zijn en wat MT3 meet en observeert. De kaart voor de CEO (`docs/qa/ceo-kaart-mt3.md`) en de tijdsindeling komen pas als T8c en T8d de slice op eindkwaliteit hebben en er een P2 is (E-1). MT2 (solo, placeholder) gaat voor: `docs/qa/testplan-mt2.md`.

## 0. Wanneer MT3 start

De Producer plant MT3 pas als alle drie de regels gelden (kader §4):

1. **MT2 is gespeeld en verwerkt** (`docs/qa/rapport-mt2.md`), en wat daaruit volgt voor de slice is gebouwd of bewust uitgesteld.
2. **De slice staat op eindkwaliteit** (T8c art, T8d audio): de merkbare stap van MT3.
3. **De bots zijn groen** op de build van MT3: alle regels van §2 ✅. Zo niet groen: geen sessie.

En er is een **P2** (E-1, Executive Producer). Zonder P2 speelt de CEO alleen solo, kan F4b(c) niet slagen, en legt de EP vóór F8 een `ceo-beslissing` voor (kader F4b).

## 1. Wat MT3 toetst

1. **F4b(a) solo én co-op**: klikmoment van de kernfantasie (ja/nee, waar), wil doorspelen (ja/nee), de echo (solo) of de partner (co-op) als bondgenoot of trucje.
2. **F4b(b) co-op** (gdd §5.1): de echo-acties buiten de boss op de route, met P2 in de rol van de echo (W41 in het T11-plan); samen met F4b(b) solo uit MT2 het oordeel.
3. **F4b(c) co-op-normen uit F0** (`testplan-f0.md` §1): norm (3) co-op (MP-5 ≥ 4,0, geen kamer < 3,0), C1–C2 (wachten; partner als hulp of last), MP-7 (a)–(e) bij mensen.
4. **De boss in co-op**: GM-a en GM-b in beide modi, GM-c, GM-d voor P1 én P2 (MP-7 (b)) per fase (`gemaalmeester.md` §8).
5. **Sterke *Nine Sols*-check** (R-V9): M1 van P2, alleen geldig als P2 de referenties niet kent en antwoordt vóór uitleg over het merk. Geen gate-voorwaarde.

Niet in MT3: F7 (visie-review van de CD op de slice-PR, geen kaart); een tweede D (D = 90/120/180 alleen als regressie in de bots).

## 2. Voorwaarden: bots groen op de build

Elke regel geldt op D = 60 in `test_kadewijk_coop.gd` (duo) en, voor solo, de lus van MT2. **Gebouwd** = de check staat in de test en is groen; **gehaald** = groen in de eerste nachtrun op `main` die het script draait (W43 in het T11-plan). Waarden: T11 §4.1 (`bc678b7`) en §4.2 (`a400888`).

| # | Check | Grens | Bij de bot nu | Status | Wie |
|---|---|---|---|---|---|
| V-1 | Solo: alle voorwaarden van MT2 (`testplan-mt2.md` §2.2) | idem | zie MT2 | via MT2 | QA Lead |
| V-2 | Co-op per kamer S1–S7, S8-route, S9: MP-1 P1 en P2, MP-7 (a)–(d) | MP-1 ≤ 300; (a) ≥ 0,5×; (c) ≥ 1,0/min; (d) ≤ 10 % | gehaald (§4.1) | ✅ (opnieuw op de build) | Gameplay Programmer |
| V-3 | De boss in de Kadewijk-arena (G-2): MP-7 (b) van P2, MP-1 P1, vaste camera met beide spelers in beeld | ≤ 300 | P2 108–146, P1 95 | gebouwd; gehaald na de nachtrun | Gameplay Programmer, Combat Designer |
| V-4 | B-14 v0.1.7: note-run "P2 op één plek" met b1 en b2; P2 in fase 2 | b1: elke breuk van een merk gezet met de doelhelft tegenover P2; b2: fase 1 ≥ 1,25×; fase 2 ≤ 180 | nog niet in de test | open | Gameplay Programmer, Combat Designer ([#302](https://github.com/cesarvangerwen-glitch/echoborn/issues/302)) |
| V-5 | MP-7 (e) wachten per speler, buiten de boss en in de boss per fase | langste ≤ 300 en ≤ 5 % | trap 2: 0 %; buiten de boss P1 12,2 %, P2 11,0 % | **niet gehaald** | Gameplay Programmer (G-6, [#298](https://github.com/cesarvangerwen-glitch/echoborn/issues/298), [#299](https://github.com/cesarvangerwen-glitch/echoborn/issues/299)) |
| V-6 | Drop-in/drop-out: per kamer één keer; in de boss een drop-out midden in een maat (doelhelft meteen uit, `DOELHELFT` = geen) en een drop-in (gloed op de volgende aanloop) | geen softlock, geen vastloper, solo-regel na de drop-out | boss: drop-out fase 1 in de testarena | open | Gameplay Programmer (G-4) |
| V-7 | Hele suite groen op Linux en Windows (F5) | 0 mislukt | — | op de build | Tools Programmer |

## 3. Wat QA uit de logs rekent

Met `docs/qa/mt2-meetlogs/rekenen.gd` (één rekenregel voor solo en co-op, T11 Q-3) op de CSV's van de sessie:

- **Per kamer en de boss** (W38): MP-1 P1 en P2, MP-2, MP-6, MP-7 (a)–(d), F4b(b) (1)–(3) op de route-tijd; de boss apart.
- **MP-7 (e) per speler**: nog niet in `rekenen.gd` (T11 Q-6). Tot Q-6 klaar is, kan MT3 het wachten bij mensen niet uit het log halen; Q-6 is dus een voorwaarde voor de sessie.
- **Boss per fase**: GM-a (tijd tot de eerste `SCHOT_BREUK`), GM-b (`RAD_TREFFER` per minuut per actie), GM-d en MP-7 (b) per fase; in fase 1 het aandeel merken vanaf de doelhelft (GMB-14).
- **(a) bij een mens**: co-op tegenover de solo-runs van de CEO in MT2 en MT3.

## 4. Wat MT3 observeert (bij mensen, niet in de bot)

| # | Vraag | Bron | Wat QA kijkt |
|---|---|---|---|
| OB-1 | **Doen spelers vanzelf "wie achteraan komt, draagt"**, of draagt de voorste en wacht hij? Het spel geeft geen signaal | open punt LGD, gdd §4.8.8 | MP-7 (e) per keerpunt (S2-B3, S2-B1, S5-B2b–d, S9-B2b); wie draagt |
| OB-2 | **Leest de doelhelft** (de gloed in fase 1 co-op)? Merken spelers vanaf de goede kant, of krijgen ze vaak de "tink"? | GMB-14, §9 van `slice-vijanden-en-boss.md` | aandeel merken vanaf de doelhelft; aantal "tink" per maat |
| OB-3 | **De rolwissel in fase 2** (GMB-15 b): springt P2 op P1 als P1 moet wachten, of wacht P1? Voelt P2 als plank "aan het wachten"? | open punt 18, `slice-vijanden-en-boss.md` | MP-7 (e) van P2 in fase 2; vraag C1 |
| OB-4 | **Trap 2 in co-op**: pompen beiden, of staat er een te kijken? | T11 §4.1 en §4.2, W-1 | `POMP` per speler bij trap 2 |

## 5. Sessie en kaart

Volgt bij v0.2, na T8c/T8d en E-1: ± 10–15 min, ± 3–4 runs (besluit 2026-11-12 (2)), solo en co-op; dezelfde F4b(a)-vragen als MT2, plus C1–C2, MP-5 co-op per kamer en M1 van P2 vóór uitleg over het merk.

## 6. Werkaannames (kader §5)

**D = 60** is een CEO-besluit **als werkaanname** (`beslissingen.md` 2026-11-12); de indeling **MT1–MT3** is een werkaanname van de EP (kader §4). Verder gelden W36–W43 uit `testplan-t11-slice.md` §7, in het bijzonder W37 (co-op eerst met de bots), W41 (MP-7 (c) en MP-6 in co-op, wacht op de LGD) en W43 (gebouwd ≠ gehaald).

## Wijzigingen

| Versie | Datum | Wat |
|---|---|---|
| 0.1 | 2026-11-14 | Concept (T11 Q-4): wanneer MT3 start, voorwaarden V-1–V-7 met de stand van de bot, wat QA rekent, observaties OB-1–OB-4; kaart en sessie volgen |
