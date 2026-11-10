# UX-spec co-op: drop-in, drop-out en gedeelde camera *Polderlight*

Versie 0.1 · Eigenaar: UX Designer · Issue [#87](https://github.com/cesarvangerwen-glitch/echoborn/issues/87) (T10) · Review: Lead Game Designer
Hoort bij **`docs/ux/hud-menus.md`** (HUD, menu's, opties). Wireframes: `docs/ux/wireframes/coop_dropin_dropout_storyboard_placeholder.png`, `hud_coop_640x360_placeholder.png`, `hud_elementen_x4_placeholder.png` (P2-badge).

Bronnen: `docs/design/gdd.md` §2.7 (C-01–C-09), §2.9; `kernloop.md` §4 en §7; `docs/tech/input.md` (W1–W7, §2, §2a); `docs/tech/performance-flowkamer.md` §7 punt 14 en 15; pitch v0.4 §5 en P3.

## 0. Werkaannames (kader §5)

Dezelfde als `hud-menus.md` §0, vooral **W4** (max. twee lichamen, de partner ís de echo; besluit #51, 7A) en **W7** (vóór F0; waarden zijn startwaarden). Daarnaast:

| # | Aanname | Bron |
|---|---|---|
| WC1 | De `InputRouter` doet meedoen en stoppen op apparaatniveau; deze spec voegt alleen toe wat de spelers zien en horen. | `input.md` §2, W2–W5 |
| WC2 | `leash_view_px` = 1,5 × 640×360 = **960×540** is een werkaanname van de Gameplay Programmer; deze spec neemt hem over als startwaarde van UX en TD (C-07). | `game/data/echo_v04.json` (`_uitleg` bij co-op) |

## 1. Doel

Een tweede speler doet **binnen 10 seconden** mee, zonder menu, zonder dat de eerste speler stopt, en weet meteen wie hij is (rolbestand UX Designer). Stoppen is net zo makkelijk en kost niemand iets. Co-op is geen modus: hetzelfde spel, met een tweede lichaam dat live speelt (pitch §5, L-02).

**Tijdbudget voor de 10 s:** controller aanzetten en koppelen (± 2–5 s, buiten ons spel) → de melding staat er op de tick van verbinden → één druk op Start → P2 staat op die tick in het spel (C-03). Ons deel is **≤ 1 s**.

## 2. Meedoen (drop-in)

| ID | Regel |
|---|---|
| **CO-01** | **Waar:** overal waar P1 kan spelen of kiezen: in het spel, in het pauzemenu en in het hoofdmenu. **Hoe:** Start/Menu op een vrije controller, of Enter op de P2-helft van het toetsenbord (`input.md` §2a). Er is geen bevestiging en geen keuzescherm. |
| **CO-02** | **In het hoofdmenu** krijgt P2 de badge rechtsboven (`hud-menus.md` §4.2, nr. 4) en start bij *Doorgaan* of *Nieuw spel* mee, op de plek van P1 (C-03: de echo is dan Leeg). **In de pauze** krijgt P2 de badge meteen en verschijnt hij bij *Verder* volgens C-03. |
| **CO-03** | **Hint:** zodra een vrije controller verbindt, staat rechtsonder 5 s *Controller 2: druk op Start om mee te doen* (`HUD_PAD_JOIN_HINT`, in cyaan). Dezelfde regel staat in het pauzemenu en in het hoofdmenu zolang er een vrij apparaat is. Op het toetsenbord alleen in het pauzemenu (anders bij elke solospeler met een toetsenbord). |
| **CO-04** | **Het moment zelf** (storyboard paneel 2): de echo **wordt wakker**: op zijn plek een cyaan ring die in 12 ticks uitdijt, het amber van de echo slaat om naar het volle zwart met cyaan rand van de sluiswachter (art bible §6, Animator), een eigen klank (Audio Director). Rechtsboven verschijnt de P2-badge, en 3 s de melding *P2 doet mee* met daaronder *Houd View vast om te stoppen* (`HUD_P2_JOINED`, `HUD_P2_STOP_HOLD`). Het echo-icoon van P1 verdwijnt (er is geen echo in co-op, C-01). |
| **CO-05** | **De knop die liet meedoen** doet in het spel niets tot hij is losgelaten (`input.md` W5): Enter is op `kb2` ook springen. |

## 3. Wie is wie

- **Kleur en vorm** (art bible §6): P1 vol en licht met amber sjaal; P2 vol bijna zwart met cyaan rand, brede hoed en pikhaak. De HUD volgt dat: links (amber gloed) is van P1, rechts (cyaan badge) van P2. Merken van P2 zijn een cyaan **ruit** (sluismerk), die van P1 een amber **peilmerk** (`hud-menus.md` §3.5), zodat elke speler ziet welk merk de ander moet laten knallen (C-12b).
- **De lichtmeter is gedeeld** (LM-01): één meter, linksboven. Vonken bij het vullen hebben de kleur van wie het licht verdiende, zodat beide spelers zien dat hun werk telt (pitch P3).
- **P2-badge** (17×17 px, rechtsboven, `hud_elementen_x4_placeholder.png`):

| Toestand | Badge | In de wereld |
|---|---|---|
| **Speelt** | volle cyaan ring | P2 |
| **Opgelost** (C-06: fel licht, schaduwgevaar, vallen, leiband) | ring grijs, vult in **120 ticks** weer cyaan | breek-effect op de plek; na 120 ticks een cyaan ring naast P1, waar P2 verschijnt |
| **Stoppen** (vasthouden) | ring vult wit in 60 ticks | dezelfde ring rond P2 |
| **Apparaat weg** | grijze ring + controller-icoon met "!", ring loopt leeg in 180 ticks | P2 blijft staan en doet niets (bits 0, `input.md` §2) |

- **P2 buiten beeld** (C-07): aan de rand van het beeld waar P2 is, een cyaan **pijl** met een ring die in **60 ticks** leegloopt (storyboard paneel 3). Op 0 lost P2 op (C-06). Zo is de leiband geen verrassing.

## 4. Stoppen (drop-out)

| ID | Regel |
|---|---|
| **CO-06** | **Twee wegen:** (a) View/Select (toetsenbord Backspace) **60 ticks** vasthouden (C-05); de ring op de badge en rond P2 vult, **loslaten vóór 60 = blijven**. (b) Pauze → *Speler 2 stopt* (`MENU_P2_LEAVE`), meteen. Met *Vasthouden of tikken: tikken* (TG-01) start één druk de 60 ticks en breekt een tweede druk af. |
| **CO-07** | **Wat P1 ziet:** P2 lost op (breek-effect), de badge schuift weg, het **echo-icoon komt terug** (`hud-menus.md` §3.4): actief als `t − D ≥ geldig_vanaf`, anders vullend tot hij er is (C-05). Stond P1 op de plank van P2, dan valt hij (C-05); daar waarschuwt de ring rond P2 al voor. Melding 3 s: *P2 is gestopt* (`HUD_P2_LEAVING`). |
| **CO-08** | **Controller van P2 weg:** 180 ticks wachten (C-05, `input.md` W4) met de badge in *Apparaat weg* en de melding *Controller 2 kwijt* (`HUD_PAD_LOST`). Komt dezelfde controller terug: P2 speelt verder zonder knop. Na 180 ticks: drop-out zoals CO-07; daarna is het weer meedoen met Start. **Geen pauze**: P1 speelt door. |
| **CO-09** | **Controller van P1 weg:** het spel **pauzeert** (MN-14) met *Controller van speler 1 kwijt. Druk op een knop om verder te spelen.* Komt dezelfde controller terug, dan speelt P1 verder; een knop op een **apparaat zonder plaats** neemt plaats 1 over (`input.md` W4). De controller van P2 kan dat niet (hij heeft plaats 2): wil het duo met één controller verder, dan kiest P2 in deze pauze *Speler 2 stopt* en drukt daarna een knop. |

## 5. Gedeelde camera

| ID | Regel | Startwaarde |
|---|---|---|
| **CA-01** | **P1 leidt** (C-07): de camera volgt P1 en verplaatst of remt hem nooit. P2 houdt de camera niet tegen. | — |
| **CA-02** | **Ingezoomd waar het kan.** De camera blijft op het kleinste beeld (640×360 wereld-px) en zoomt pas uit als P1 en P2 met hun marge (`leash_margin_px`) er niet meer in passen. Zo doet de flow-kamer het al (`flow_room.gd`, `camera_view`); UX bevestigt dat gedrag. Waarom: elke zoom-uit maakt de figuren kleiner en geeft ongelijke pixels (punt 15); die prijs betalen we alleen als het moet. | marge zoals `echo_v04.json` |
| **CA-03** | **Maximale zoom-uit:** **960×540** wereld-px (1,5×, WC2). Verder uitzoomen maakt P1 op de Deck kleiner dan ± 4,5 mm; dat leest niet meer. | 960×540 |
| **CA-04** | **Ongelijke pixels bij zoom-uit** (antwoord van UX op `performance-flowkamer.md` §7, punt 15): **geen vaste zoomtrappen**. Een sprong in zoom kost meer leesbaarheid dan ongelijke pixels die alleen tijdens het uitzoomen in co-op voorkomen. Uitzoomen gaat meteen, inzoomen met de bestaande ease. De Technical Artist toetst op de Deck of het flikkert; is dat zo, dan is de eerste stap renderen op 1280×800 op de Deck (dan halveert het effect), niet trappen. | — |
| **CA-05** | **16:10-band** (punt 14): niet gedimd (`hud-menus.md` HUD-M2). | — |
| **CA-06** | **Kamerwissel in co-op:** de camera volgt P1 door de deur; P2 komt mee volgens de AreaLoader en C-07. Staat P2 nog in de oude kamer, dan geldt de pijl van §3; geen eigen regel. | — |

## 6. Parameters van de UX Designer (gdd §2.9)

Alle waarden blijven de startwaarden van de gdd; ze worden gemeten in T17 en T11.

| Parameter | Waarde | Waarom deze waarde |
|---|---|---|
| Loslaten (E-09) | **30 ticks** (0,5 s) | Lang genoeg om niet per ongeluk te gebeuren, kort genoeg om in een sprong te doen. |
| Drop-out: stopknop vasthouden (C-05) | **60 ticks** (1 s) | Niet per ongeluk, maar ook geen wachten; de ring maakt het zichtbaar. |
| P2 buiten beeld voor oplossen (C-07) | **60 ticks** | Met de pijl en de ring is 1 s genoeg om terug te keren; langer laat P1 wachten. |
| P2 terugkeer na oplossen (C-06) | **120 ticks** (2 s) | Gelijk aan D: het voelt als "je schaduw komt terug", net als de echo. |
| Lanceerhouding (C-11a, met LGD) | **12 ticks** | Ongewijzigd; met TG-01 ook als tik (`hud-menus.md` §7 punt 8). |
| Camera: maximale zoom-uit | **960×540** | CA-03 |

## 7. Open punten

| # | Wat | Wie | Wanneer |
|---|---|---|---|
| 1 | Drop-in, drop-out en camera bouwen volgens CO-01–CO-09 en CA-01–CA-06 (de router en C-03/C-05 zijn er) | Gameplay Programmer | T8a |
| 2 | Klank en beeld van het wakker worden en oplossen (CO-04, CO-07) | Audio Director, Animator | Slice-art en -audio |
| 3 | Meten: doet een nieuwe speler binnen 10 s mee, en begrijpt hij de pijl van de leiband zonder uitleg? | QA Lead | T11 |
| 4 | Flikkert de zoom-uit op de Deck (CA-04)? | Technical Artist | Bij de Deck-build (#79) |
| 5 | Van rol wisselen (wie is de machinist) zonder drop-out: nu alleen via stoppen en opnieuw meedoen in een andere volgorde; een eigen knop pas als playtests erom vragen | UX Designer | Na T11 |

## 8. Wijzigingen

| Versie | Datum | Wat |
|---|---|---|
| 0.1 | 2026-11-10 | Eerste versie (T10 deel 1, #87). |
