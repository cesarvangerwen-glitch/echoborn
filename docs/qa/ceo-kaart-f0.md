# CEO-kaart F0: de flow-kamer spelen en scoren (T17)

Versie 0.2.1 · 2026-11-11 · Eigenaar: QA Lead · Issue: [#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80) · Achtergrond voor QA (lees je pas na het spelen, zoals §5): het testplan in `docs/qa/`

**Tijd: ± 15 min spelen + ± 5 min luisteren.** Je hoeft alleen te spelen, te scoren en het antwoordblok (§4) als comment in #80 te zetten. **Lees tot en met §4; lees §5 pas na het spelen** (anders kleurt het je antwoorden).

Je speelt **alleen solo**, zonder tweede speler (besluit [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124)). Co-op speel en score je later, in de verticale slice.

## 1. Wat je nodig hebt

- Godot 4.6.3, standaard (niet .NET/mono):
  - **Windows**: download `Godot_v4.6.3-stable_win64.exe.zip` van https://github.com/godotengine/godot/releases/tag/4.6.3-stable, pak uit en start `Godot_v4.6.3-stable_win64.exe`. Kies *Importeren*, wijs `game/project.godot` in je clone van de repo aan en open het project.
  - **Linux**: zie `docs/tech/setup.md` §2; daarna `godot --path game`.
- Druk in de editor op **F5** (project starten): de flow-kamer start meteen.
- Druk daarna **eerst A, D of spatie** (speel je met de controller: eerst een knop op de controller). De eerste knop bepaalt waarmee je speelt; druk je eerst een pijltje, dan speel je met de pijltjeskant en werkt spatie niet om te springen. Gebeurt het toch: sluit het spelvenster (of klik in de editor op de stopknop, F8) en druk in de editor opnieuw op F5. F6 helpt hier niet, en F5 ín het spelvenster zet de meetlog uit (F5 is daar een schakelaar; de HUD toont *meetlog aan/uit*). Gebeurd? Druk nog eens F5 tot de HUD *meetlog aan* toont, of stop het spel en start opnieuw met F5 in de editor.
- Voor de luistercheck: een koptelefoon én de tv-luidsprekers.

## 2. Besturing

| | Toetsenbord | Controller |
|---|---|---|
| Jij | A/D lopen, spatie springen, linker Shift dash, E slaan/pompen | stick, A springen, X slaan/pompen, RB dash |
| Debug | **F1 / F2 / F3** = staart 1,5 / 2 / 3 s (nieuwe run) · F6 = herstart | — |
| Na de run | Druk **drie cijfers 1–5**: de score voor K1, K2 en K3 (in die volgorde) | — |

Druk tijdens een run **niet op Enter of Start** (Start op een controller waarmee je niet speelt): dan komt er een tweede speler bij en is het geen solo-run meer. Gebeurt het toch: F6 en opnieuw.

De toetsenbordkolom geldt alleen als je na F5 eerst A, D of spatie drukte (zie §1). Elke toets van de pijltjeskant als eerste (o.a. de pijltjes, Enter, rechter Shift en rechter Ctrl) maakt die kant van jou.

Het doel van een run: door K1 (sprongen), K2 (vijanden), K3 (pomp het gemaal vol), dan door de sluis. De HUD toont kamer, staart (D) en tijd.

## 3. Draaiboek

**De score per kamer** is steeds: *"Voelde het vloeiend/satisfying?"* 1 = stroef, 5 = heerlijk vloeiend.

| Blok | Wat je doet | Tijd |
|---|---|---|
| 1 | **F2**, speel 2 oefenruns. Druk na elke run drie willekeurige cijfers (oefenruns tellen niet). | ± 5 min |
| 2 | **F3** (3 s), dan **F1** (1,5 s), dan **F2** (2 s): elk één run. Na elke run: drie cijfers in het spel, en noteer in §4 je score per kamer en V1 (wist je waar je echo zou zijn, 1–5). | ± 7 min |
| 3 | Beantwoord M1, M2 en "Echo: hulp of last?" in §4 (meteen na blok 2). | ± 1–2 min |
| 4 | Luistercheck F2 (audio bible §9.4) op `docs/audio/f2-fragment/f2_merk_aftelling_carillon_placeholder.wav`, eerst op de koptelefoon, dan op de tv. | ± 5 min |

Lukt een run niet (vast, of je wilt opnieuw): F6. De afgebroken run wordt bewaard en telt niet mee.

## 4. Antwoordblok (kopieer in een comment in #80)

```
[CEO → QA Lead]: flow-test F0 (solo)

Solo (score K1 / K2 / K3, 1–5)
- 3 s:   _ / _ / _   V1 wist je waar je echo zou zijn (1–5): _
- 1,5 s: _ / _ / _   V1: _
- 2 s:   _ / _ / _   V1: _

M1 Waar deed het merk (wat je met slaan op een vijand zet) je aan denken? (open, één zin): ...
M2 Kies één moment waarop een merk wel of juist niet iets deed: waarom gebeurde dat (niet)? (één zin): ...
Echo: hulp of last? (1–5, 5 = hulp): _

Luistercheck F2 (ja/nee, opmerking mag)
1. Klinkt het als een carillon? (klokjes 2,1 s en 2,35 s, slag 2,6 s; daarna 10,5–11,1 s): _
2. Hoor je dat de slag op 2,6 s "jij, maar hol" is? (vergelijk 0,6 s met 2,6 s, en 9,0 s met 11,0 s): _
3. Voelt het opgepompte deel (vanaf ± 9 s) warmer dan het grijze begin (0–6 s)? (één woord): _

Bijlage: de meetlog-CSV's (zie hieronder)
```

**Meetlogs meesturen, in één stap:** open de map `%APPDATA%\Godot\app_userdata\Echoborn` (Windows: plak dit pad in de adresbalk van de Verkenner; Linux: `~/.local/share/godot/app_userdata/Echoborn`), selecteer alle bestanden `meetlog_*.csv` van vandaag en sleep ze in je comment. GitHub voegt ze als bijlage toe.

## 5. Wat QA ermee doet (lees na het spelen)

- **Norm (3), MP-5**: gemiddelde score solo ≥ 4,0 en geen kamer < 3,0, per staart; de staart met de hoogste MP-5 die ook de objectieve solo-normen haalt, wordt gekozen (gelijk = 2 s).
- **M1 is de *Nine Sols*-check** (ideecheck §2, slotzin), hier alleen als **zwak signaal**: jij koos *Nine Sols* zelf als referentie. Daarom beschreef de kaart het merk vooraf alleen neutraal. Noem je spontaan *Nine Sols*, een talisman of "lading die ontploft", dan gaat het merk terug naar afwijkpunt 2 (gdd §2.13). Noem je het niet, dan is de check niet gehaald maar uitgesteld: de sterke check volgt in de slice, met een tweede speler die de referenties niet kent, als er zo'n speler is; anders blijft dit risico open bij het besluit over de fase (fasekader §3, F4b(c) en F8).
- **M2** (de merksprong: ontplofte het merk wel of niet) telt als begrepen bij "de echo kwam (niet) langs" of "het merk was te ver of gedoofd".
- **Uit de CSV's** rekent QA MP-1 t/m MP-4 en MP-6 per run. Observaties: O1 de stilstand aan de waterkant in K3 bij 3 s (de krapste plek in de scripted runs); O2 landingen met wachten ervoor (R-V12); O3 hoe vaak de echo Leeg is en waarom.
- **Co-op** (score, wachten, partner als hulp of last, MP-7) toetst QA in de slice (fasekader §3, F4b(c)), niet in deze sessie.

## Open punten

- Moet de eerste knop op de pijltjeskant van het toetsenbord speler 1 blijven maken (`input_router.gd` `_claimable_slot`: plaats 1 neemt elke knop)? Eigenaar: UX Designer + Gameplay Programmer ([#80](https://github.com/cesarvangerwen-glitch/echoborn/issues/80)).

## Wijzigingen

| Versie | Datum | Wijziging |
|---|---|---|
| 0.1 | 2026-11-09 | Eerste versie (#80): blokken 1–5 solo en co-op, antwoordblok, meetlogs |
| 0.2 | 2026-11-11 | Na besluit [#124](https://github.com/cesarvangerwen-glitch/echoborn/issues/124) (1B) en fasekader v0.3: alleen solo; blok 4 (co-op) vervallen en weggelaten, luistercheck is nu blok 4; P2 uit de besturing en de co-op/P2-velden uit het antwoordblok; waarschuwing tegen Enter; tijd ± 20 → ± 15 min spelen; "Echo: hulp of last?" bij blok 3; M1 als zwak signaal met sterke check in F4b(c) als er zo'n P2 is, anders R-V9 open in F8; MP-7 en O4 uit §5; Start als meedoe-knop in de waarschuwing |
| 0.2.1 | 2026-11-11 | Na F5 eerst A, D of spatie (§1, noot onder §2): de eerste knop claimt plaats 1, een pijltje maakt de pijltjeskant speler 1; herstel = spel stoppen en F5 in de editor (F6 houdt de plaats); F5 in het spelvenster schakelt de meetlog, met herstel via de HUD (*meetlog aan*) of een nieuwe start; vraag over dit gedrag bij *Open punten* |
