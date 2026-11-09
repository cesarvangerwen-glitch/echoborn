# CEO-kaart F0: de flow-kamer spelen en scoren (T17)

Versie 0.1 · 2026-11-09 · Eigenaar: QA Lead · Issue: [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80) · Plan: `docs/qa/testplan-f0.md`

**Tijd: ± 20 min spelen + ± 5 min luisteren.** Je hoeft alleen te spelen, te scoren en het antwoordblok (§4) als comment in #80 te zetten. **Lees tot en met §4; lees §5 pas na het spelen** (anders kleurt het je antwoorden).

Wie P2 speelt in de co-op-runs, beslis je vooraf in [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124).

## 1. Wat je nodig hebt

- Godot 4.6.3 (`docs/tech/setup.md` §1–2). Open de map `game/` en start het project (F5): de flow-kamer start meteen.
- Voor co-op: een tweede speler (volgens [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124)) met de pijltjeshelft van het toetsenbord of een tweede controller.
- Voor de luistercheck: een koptelefoon én de tv-luidsprekers.

## 2. Besturing

| | Toetsenbord | Controller |
|---|---|---|
| P1 | A/D lopen, spatie springen, linker Shift dash, E slaan/pompen | stick, A springen, X slaan/pompen, RB dash |
| P2 | Enter = meedoen (daarna springen); pijltjes lopen; rechter Ctrl slaan/pompen; rechter Shift dash; Backspace 1 s = stoppen | Start = meedoen, Back = stoppen; verder als P1 |
| Debug | **F1 / F2 / F3** = staart 1,5 / 2 / 3 s (nieuwe run) · F6 = herstart | — |
| Na de run | Druk **drie cijfers 1–5**: de score voor K1, K2 en K3 (in die volgorde) | — |

Het doel van een run: door K1 (sprongen), K2 (vijanden), K3 (pomp het gemaal vol), dan door de sluis. De HUD toont kamer, staart (D) en tijd.

## 3. Draaiboek

**De score per kamer** is steeds: *"Voelde het vloeiend/satisfying?"* 1 = stroef, 5 = heerlijk vloeiend.

| Blok | Wat je doet | Tijd |
|---|---|---|
| 1 | **F2**, speel 2 oefenruns solo. Druk na elke run drie willekeurige cijfers (oefenruns tellen niet). | ± 5 min |
| 2 | Solo: **F3** (3 s), dan **F1** (1,5 s), dan **F2** (2 s): elk één run. Na elke run: drie cijfers in het spel, en noteer in §4 je score per kamer en V1. | ± 7 min |
| 3 | Beantwoord M1 en M2 in §4 (meteen na blok 2). | ± 1 min |
| 4 | Co-op, met P2 volgens [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124): P2 drukt Enter zodra de run loopt. **F2**, **F3**, **F1**: elk één run. Na elke run: drie cijfers in het spel, noteer je score, en vraag P2 om de zijne. Beantwoord C1–C2 (en P2 ook). | ± 7 min |
| 5 | Luistercheck F2 (audio bible §9.4) op `docs/audio/f2-fragment/f2_merk_aftelling_carillon_placeholder.wav`, eerst op de koptelefoon, dan op de tv. | ± 5 min |

Lukt een run niet (vast, of je wilt opnieuw): F6. De afgebroken run wordt bewaard en telt niet mee.

## 4. Antwoordblok (kopieer in een comment in #80)

```
[CEO → QA Lead]: flow-test F0

Solo (score K1 / K2 / K3, 1–5)
- 3 s:   _ / _ / _   V1 wist je waar je echo zou zijn (1–5): _
- 1,5 s: _ / _ / _   V1: _
- 2 s:   _ / _ / _   V1: _

M1 Waar deed het merk (wat je met slaan op een vijand zet) je aan denken? (open, één zin): ...
M2 Kies één moment waarop een merk wel of juist niet iets deed: waarom gebeurde dat (niet)? (één zin): ...

Co-op (score K1 / K2 / K3; CEO | P2)
- 2 s:   _ / _ / _  |  _ / _ / _
- 3 s:   _ / _ / _  |  _ / _ / _
- 1,5 s: _ / _ / _  |  _ / _ / _
C1 Heb je op de ander moeten wachten? (ja/nee, en in welke kamer): CEO ... | P2 ...
C2 Voelde je partner als hulp of als last? (1–5, 5 = hulp): CEO _ | P2 _
M1 voor P2 (vóór uitleg over het merk): ...

Echo solo: hulp of last? (1–5): _
Luistercheck F2 (ja/nee, opmerking mag)
1. Klinkt het als een carillon? (klokjes 2,1 s en 2,35 s, slag 2,6 s; daarna 10,5–11,1 s): _
2. Hoor je dat de slag op 2,6 s "jij, maar hol" is? (vergelijk 0,6 s met 2,6 s, en 9,0 s met 11,0 s): _
3. Voelt het opgepompte deel (vanaf ± 9 s) warmer dan het grijze begin (0–6 s)? (één woord): _

Bijlage: de meetlog-CSV's (zie hieronder)
```

**Meetlogs meesturen, in één stap:** open de map `%APPDATA%\Godot\app_userdata\Echoborn` (Windows: plak dit pad in de adresbalk van de Verkenner; Linux: `~/.local/share/godot/app_userdata/Echoborn`), selecteer alle bestanden `meetlog_*.csv` van vandaag en sleep ze in je comment. GitHub voegt ze als bijlage toe.

## 5. Wat QA ermee doet (lees na het spelen)

- **Norm (3), MP-5**: gemiddelde score per modus ≥ 4,0 en geen kamer < 3,0, per staart; de staart met de hoogste MP-5 die ook de objectieve normen haalt, wordt gekozen (gelijk = 2 s).
- **M1 is de *Nine Sols*-check** (ideecheck §2, slotzin): noemt iemand spontaan *Nine Sols*, een talisman of "lading die ontploft", dan gaat het merk terug naar afwijkpunt 2 (gdd §2.13). Daarom beschreef de kaart het merk vooraf alleen neutraal. Omdat jij *Nine Sols* zelf als referentie koos, telt jouw antwoord als zwak signaal; dat van P2 weegt zwaarder.
- **M2** (de merksprong: ontplofte het merk wel of niet) telt als begrepen bij "de echo kwam (niet) langs" of "het merk was te ver of gedoofd".
- **Uit de CSV's** rekent QA MP-1 t/m MP-4 en MP-6 per run, MP-7 (a), (c) en (d) in co-op. Observaties: O1 de stilstand aan de waterkant in K3 bij 3 s (de krapste plek in de scripted runs); O2 landingen met wachten ervoor (R-V12); O3 hoe vaak de echo Leeg is en waarom; O4 in co-op: staat P2 lang stil onder P1 zonder op te lossen (rapport §4).
