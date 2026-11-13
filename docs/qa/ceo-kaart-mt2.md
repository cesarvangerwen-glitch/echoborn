# CEO-kaart MT2: de Kadewijk spelen, met de Gemaalmeester

Versie 0.1.2 · 2026-11-13 · Eigenaar: QA Lead · Issue: [#250](https://github.com/cesarvangerwen-glitch/echoborn/issues/250)

**Nog niet spelen.** Deze kaart is voor ná MT1 (de flow-kamer). De Producer stuurt je de kaart als de bots op de hele Kadewijk groen zijn; dan staan de build en de links hieronder ingevuld.

**Tijd: ± 15 min.** Solo, op de staart van **1 s (D = 60)**. Je speelt de Kadewijk **één keer** van begin tot eind (± 6–8 min), beantwoordt 14 vragen met een letter (± 2 min) en luistert op koptelefoon naar één geluidsfragment (± 2 min). Geen kladje nodig.

**Lees §1–§4. Lees §6 pas nadat je alles verstuurd hebt.**

Build: commit *in te vullen*. Zip van precies die versie: *in te vullen* (speel niet met een andere zip).

## 1. Klaarzetten (Windows, ± 3 min)

1. Open de zip-link hierboven en pak uit in een **nieuwe** map.
2. **Oude meetlogs opzij:** plak `%APPDATA%\godot\app_userdata\Echoborn` in de adresbalk van de Verkenner, maak een submap `oud-mt2` en verplaats alle `meetlog_*.csv` daarheen.
3. Start `Godot_v4.6.3-stable_win64.exe`, kies **Importeren**, wijs `game\project.godot` in de **nieuwe** map aan en open het (± 1 min).
4. Dubbelklik linksonder in *FileSystem* op **`levels` → `kadewijk` → `kadewijk.tscn`**. Druk dan op **F6** (*Huidige scène afspelen*), **niet F5** (F5 start de flow-kamer van MT1). Je staat in de Kadewijk, bij een deur.
5. Druk **eerst A, D of spatie** (geen pijltje).
6. **Kijk bovenaan:** staat er **D = 60** en *echo Actief* of *echo Leeg*? Goed. Staat er iets anders: sluit het spelvenster en druk opnieuw F6.

## 2. Spelen (± 6–8 min)

| | Toets |
|---|---|
| Lopen, springen, dash, slaan | A/D, spatie, linker Shift, E |
| Slaan naar beneden (in de lucht; pas nadat je het in de kelder gevonden hebt) | E met S ingedrukt |
| Echt vastgelopen (je kunt niet meer verder) | F6 (laptop: Fn + F6): de **hele wijk begint opnieuw bij de deur**. Alleen als je echt vastzit; doodgaan is geen vastzitten |

**Het doel:** door de wijk naar het gemaal, het gemaal oppompen (sla op de schoepen), door de kelder naar de **Gemaalmeester**, hem verslaan, het gemaal nog een keer oppompen, en via de lage kade terug naar waar je begon. Het spel zegt je niet hoe; ontdek het zelf. Je bent klaar als je weer op de gang bij de deur staat (de tijd bovenaan stopt). Sluit dan het spelvenster.

- **Niet drukken**: Enter of Start (tweede speler), F1/F2/F3/F7 (andere staart), F4 (echo uit), F8 (kamer overslaan).
- **Dood?** Je begint vanzelf opnieuw bij het laatste punt. Gewoon doorspelen, **geen F6**.
- **Stoppen mag** na ± 8 min spelen, of na 3 keer dood bij de boss. Zet bij vraag 14 waar je was.
- **Altijd het spelvenster sluiten** (kruisje rechtsboven of Alt+F4), **niet de stopknop ■ van de editor**: anders wordt je meetlog niet bewaard.

## 3. Vragen (typ in de Claude-chat, ± 2 min)

Kopieer het blok en zet **achter elke vraag een letter** (bij 2 mogen er meer; bij 5 vier cijfers). **Alleen bij 12 (B of C) en 14 (D) typ je een paar woorden**; verder alleen letters. Er zijn geen goede of foute antwoorden.

```
[CEO → QA Lead]: mijlpaaltest MT2 (Kadewijk, solo, D = 60)

1  Wil je doorspelen?  A ja, graag · B ja · C maakt niet uit · D nee
   → _
2  Waar klikte het: de echo als jouw tweede lichaam?
   A kades begin · B markt · C kloof · D trappenhuis · E gemaal · F kelder · G boss · H lage kade · I nergens
   → _
3  De echo was voor jou meer…  A een bondgenoot · B soms bondgenoot, soms trucje · C een trucje · D weet niet
   → _
4  Je schaduw was…  A iemand die meedeed · B een spoor achter je aan · C allebei · D weet niet
   → _
5  Hoe vloeiend voelde het? 1 = stroef, 5 = heerlijk vloeiend
   kades (tot de kloof) _ · huis, plein en kelder _ · boss _ · lage kade terug _
6  Bij het omdraaien (de paal bij de kloof, het trappenhuis): op je echo springen…
   A ging vanzelf, ik viel erop · B even in de lucht wachten, prima · C wachten in de lucht, stoorde · D niet gemerkt
   → _
7  Het trappenhuis (vier keer omdraaien) was…  A een lekker ritme · B net goed · C te lang, saai · D weet ik niet meer
   → _
8  Over het kanaal in de kelder ging je…
   A stuitend op de lichtjes · B door de bodem van het kanaal · C geprobeerd te stuiten, lukte niet · D weet ik niet meer
   → _
9  Na het tweede groepje vijanden op de markt, tot de sprong over de kloof…  A prima, even rust · B te lang niets te doen · C niet gemerkt
   → _
10 Hoe brak je de klep van de boss?  A snapte het meteen · B na een tijdje · C per toeval · D niet gelukt
   → _
11 Bij de laatste slagen op de boss zag je vooral…  A mijn eigen slagen · B mijn echo die meesloeg · C een filmpje · D niet gehaald
   → _
12 Het merk (wat je met slaan op een vijand zet) deed je denken aan…  A nergens aan · B een ander spel: (naam) · C iets anders: (paar woorden)
   → _
13 In de verlichte markt, vóór een verlicht raam: je echo was…  A goed te zien · B even kwijt · C kwijt · D geen verlichte markt gezien
   → _
14 Ging er iets mis?  A nee · B vast · C verkeerde toets · D iets raars: (paar woorden)
   → _

Bijlage: alle meetlog-CSV's van vandaag
```

Een antwoord als `1 A, 2 C F G, 3 A, 4 A, 5 4 4 5 3, 6 B, …` is genoeg.

## 4. Luisteren (± 2 min)

Open het fragment: *link in te vullen* (± 12 s). Luister op **koptelefoon** (tv-luidsprekers niet nodig). Antwoord met **ja** of **nee**; een korte opmerking mag.

```
L1 Klinkt het als een carillon? (klokjes op 2,1 en 2,35 s, klokslag op 2,6 s; daarna 10,5–11,1 s)  ja / nee
L2 Hoor je dat de slag op 2,6 s "jij, maar hol" is? (vergelijk met de slag op 0,6 s; en 9,0 s met 11,0 s)  ja / nee
L3 Voelt het deel vanaf ± 9 s warmer dan het grijze begin (0–6 s)?  ja / nee
```

## 5. Versturen (± 1 min)

Zet de vragen van §3 en §4 in **één bericht in de Claude-chat**. Open `%APPDATA%\godot\app_userdata\Echoborn`, selecteer alle `meetlog_*.csv` die **niet** in `oud-mt2` staan (ook de `_afgebroken`) en **sleep ze in de chat**. Niet als bijlage in GitHub: die kunnen de agents niet openen. Verwijder niets.

Klaar. De agent in de chat zet alles in de repo; QA schrijft het rapport.

## 6. Wat QA ermee doet (lees pas na het versturen)

- **Vraag 1–3** zijn het hoofddoel: is de slice leuk (klikmoment, doorspelen, bondgenoot of trucje). **Vraag 5** moet gemiddeld ≥ 4 zijn, geen deel onder 3.
- **Uit de logs**, per kamer: nergens > 5 s stil, de echo ≥ 3× per minuut als plank of tweede slag, de echo ≤ 40 % van de tijd leeg, en hoe vaak je de echo buiten het bossgevecht gebruikte. Waar je verdwaalde of doodging.
- **Vraag 6–9 en 13** komen uit de reviews van het team: in de lucht hangen boven je echo (kloof, trappenhuis), het trappenhuis als herhaling, stuiten in de kelder, het lege stuk na de markt, en of je echo zichtbaar blijft vóór een verlicht raam. Wat daar niet werkt, past het team aan en test het met de bots, zonder jou.
- **Vraag 12** is het zwakke *Nine Sols*-signaal (daarom stond er geen spel in de opties). **L1–L3** zijn de luisterhelft van de audio-mijlpaal (F2); een "nee" wijst het team naar het onderdeel.
- Een vraag aan jou volgt alleen als het rapport dat nodig maakt. De volgende speelsessie is MT3: de slice op eindkwaliteit, solo én met een tweede speler.

## Wijzigingen

| Versie | Datum | Wijziging |
|---|---|---|
| 0.1.2 | 2026-11-13 | Start met `kadewijk.tscn` + F6 (niet F5) tot MT1 klaar is (PR #257); spelvenster sluiten, niet de stopknop (anders geen CSV); stopregel ± 8 min, spelen ± 6–8 min, zodat ± 15 min klopt; bovenaan §3: 12 en 14 zijn de enige open velden; doel met het tweede keer pompen na de boss (trap 2) (SM-review #251). Na Lead-review EP (#258): F6 = de wijk opnieuw bij de deur, alleen als je echt vastzit, doodgaan is geen vastzitten |
| 0.1.1 | 2026-11-13 | Na Lead-review EP (PR #251): ± 15 min; stopregel ± 10 min (§2); luisteren alleen op koptelefoon, ± 2 min (§4) |
| 0.1 | 2026-11-13 | Eerste versie (#250): na MT1; één doorloop S1 → S9 → S1 op D = 60 met stopregel; 14 meerkeuzevragen (F4b(a), R-V1, MP-5 in vier delen, de vijf meetvragen uit de reviews, GM-a, GM-c, M1, X); luistercheck F2 (bible §9.4); meetlogs via de Claude-chat. Build, zip en fragmentlink nog in te vullen |
