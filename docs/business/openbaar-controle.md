# Controle vóór het openbaar maken van de repo

Versie 1.0 · 2026-11-13 · Eigenaar: Business/Legal Advisor · Issue: [#276](https://github.com/cesarvangerwen-glitch/echoborn/issues/276) · Lead-review: Executive Producer
Hoort bij: CEO-besluit 2026-11-13 in `docs/beslissingen.md` (*Repo openbaar maken, eerst een controle*)

> **Geen juridisch advies.** Dit is een controle door de studio met zoekpatronen en steekproeven. Er staat bewust **geen enkele gevonden waarde** in dit document (geen adressen, geen namen): alleen het type, de plek en het aantal. De BLA heeft niets aan de zichtbaarheid of de instellingen van de repo veranderd en geen geschiedenis herschreven. De CEO zet de zichtbaarheid zelf om.

## 1. Samenvatting

- **Geheimen: niets gevonden** (geen tokens, sleutels, wachtwoorden of `.env`-bestanden), niet in de huidige bestanden, niet in de geschiedenis, niet in issues of comments.
- **Eén punt om vóór het omzetten bewust te kiezen** (🔴, §3 P1): het privé-mailadres en de echte naam van de CEO staan in de commit-gegevens en in de GitHub-loginnaam. Na het omzetten is dat niet meer terug te draaien (klonen en forks). Aanbeveling: **accepteren** en de GitHub-instellingen voor de toekomst aanzetten (§4); alleen als de schuilnaam *CesarTheLittle* echt anoniem moet blijven, is een nieuwe repo onder een ander account nodig (CEO-besluit).
- **Commercieel/juridisch** (🟠, §3 C1): de geplande naam *Polderlight* en de open merkcheck worden openbaar. Bestanden aanpassen helpt niet (geschiedenis); wel de formele merkcheck niet lang laten liggen.
- De rest is 🟢: niets doen.
- In deze PR: een `LICENSE` "All rights reserved" (§5).

🔴 beslissen vóór het omzetten (onomkeerbaar) · 🟠 aandachtspunt, geen blokkade · 🟢 niets doen

## 2. Wat is gecontroleerd en hoe

| Bron | Omvang (peildatum 2026-11-13) | Methode |
|---|---|---|
| Git-geschiedenis | Alle 5 branches op origin, 214 commits, 1.773 paden ooit, `git log --all -p` (± 10,7 MB tekst) | Regex op tokens en sleutels (`ghp_`, `gho_`, `ghs_`, `github_pat_`, `sk-`, `sk-ant-`, `AKIA`/`ASIA`, `xox?-`, `-----BEGIN … PRIVATE KEY`, `AIza…`, `glpat-`, `npm_`, `SG.`, JWT's, Slack-/Discord-webhooks, wachtwoorden in URL's), trefwoorden (*password, wachtwoord, api key, secret, bearer, token*), lange base64-strings; bestandsnamen (`.env`, `.pem`, `.key`, `id_rsa`, `credentials`, `.keystore`, `.p12`); verwijderde bestanden |
| Commit-metadata | Auteur, committer en `Co-Authored-By` van alle commits | Uniek tellen van namen en adressen |
| Huidige bestanden | `origin/main`, 1.640 bestanden | Zelfde patronen; `game/export_presets.cfg` (geen signeer- of keystore-gegevens), `.github/workflows/tests.yml` (geen `secrets.*`, `permissions: contents: read`, geen `pull_request_target`, geen self-hosted runners); afbeeldingen op EXIF/GPS/lokale paden |
| Persoonsgegevens | Geschiedenis + issues/comments | Regex op e-mailadressen, NL/BE-telefoonnummers, IBAN, BSN/rijksregister/ondernemingsnummer; trefwoorden (woonplaats, adres, huisgenoot, gezin, ziek, gezondheid, salaris, inkomen, lening, privé, laptop, …); lokale paden (`C:\Users\…`, `/home/…`); de 14 meetlogs (CSV) |
| Issues en comments | ± 275 issues/PR's, 958 comments (geen review-comments op regels) | Zelfde patronen; de 88 comments die niet met `[Rol → …]` beginnen (van de CEO of namens hem) apart gelezen |
| Tags, releases, wiki, pages | Geen tags, geen releases, wiki/discussions/pages uit | – |

**Beperking:** `gitleaks` en `trufflehog` waren in deze omgeving niet te installeren; dit is een grondige regex-scan, geen garantie. Binaire bestanden (PNG, OGG, GIF) zijn alleen op metadata bekeken. Na het omzetten draait GitHub zelf *secret scanning* op openbare repo's; zie §4.

## 3. Bevindingen en advies

### Geheimen

| # | Bevinding | Ernst | Advies |
|---|---|---|---|
| G1 | Geen tokens, sleutels, wachtwoorden of `.env`-bestanden gevonden, in geen enkele bron uit §2. De workflow gebruikt geen secrets. | 🟢 | **Niets doen.** Wel secret scanning en push protection aanzetten na het omzetten (§4). |

### Persoonsgegevens

| # | Bevinding | Ernst | Advies |
|---|---|---|---|
| P1 | **Privé-mailadres van de CEO** (gratis mailbox) als commit-auteur in **136 van de 214 commits** (131 via de GitHub-webinterface, met GitHub als committer; 5 lokaal). De **voornaam** van de CEO staat als auteursnaam in 142 commits. De **GitHub-loginnaam** bevat voor- en achternaam; die staat in 381 links in 49 huidige bestanden en in ± 1.100 regels van de geschiedenis. Gevolg: na het omzetten is het adres voor iedereen uit te lezen (spam, phishing), en de schuilnaam *CesarTheLittle* (besluit #157, 2A) is aan de echte naam te koppelen. | 🔴 | **CEO kiest vóór het omzetten.** (a) ⭐ **Accepteren**, en vanaf nu het mailadres afschermen (§4). De echte naam is via de loginnaam al zichtbaar voor wie de repo ziet; een schuilnaam in de credits is een artiestennaam, geen anonimiteit. (b) **Geschiedenis herschrijven** (bv. `git filter-repo --mailmap`) + force-push: verbergt het adres, niet de loginnaam; alle commit-hashes veranderen, dus de verwijzingen in docs en issues (bv. "commit 16a3582") en open PR-branches breken. (c) **Nieuwe repo** onder een ander account of een organisatie, met één begincommit: het enige dat adres én naam echt weghaalt; verlies van de geschiedenis in die repo. (b) en (c) zijn CEO-besluiten en vallen buiten deze PR. |
| P2 | Woonland van de CEO: `subsidies.md` (A1) en `vaf-dossier-productie.md` noemen dat de CEO "in België, vermoedelijk Vlaanderen" woont of werkt (onbevestigd) en bespreken een Brussel-scenario. Geen gemeente, adres of ondernemingsnummer. | 🟢 | **Niets doen.** Voor de toekomst: geen adres, gemeente, ondernemingsnummer, bank- of belastinggegevens (W-8, TIN) in de repo of in issues zetten; die horen in het dossier dat de CEO zelf indient. |
| P3 | 14 meetlogs (`docs/qa/f0-meetlogs/`, `docs/qa/f0-2-meetlogs/`) en de flow-testrapporten: alleen spelgegevens (tick, kamer, positie) plus datum en uur van de speelsessies, en een beschrijving van hoe de CEO speelde. Geen lokale paden of gebruikersnamen. | 🟢 | **Niets doen.** |
| P4 | Issues en comments worden ook openbaar (niet alleen de git-geschiedenis). Gevonden: geen persoonsgegevens; één openbaar mailadres van een bedrijf (marketing-adres van Anthropic, geciteerd uit hun voorwaarden; ook in `credits.md`); de CEO-comments zijn alleen `Besluit:`/`Info: credits`-regels. Zichtbaar wordt wel hoe de studio werkt (AI-rollen, abonnement, creditsverbruik). Let op: bij een bewerkte comment toont GitHub de bewerkingsgeschiedenis aan iedereen die de comment ziet. | 🟢 | **Niets doen.** Eventueel nog iets weghalen kan per comment (verwijderen, niet bewerken), los van git. |
| P5 | Geen andere echte personen: de "huisgenoot of vriend" (#124) is een optie zonder naam; overige namen zijn verzonnen personages, auteurs van bronnen of bedrijven. | 🟢 | **Niets doen.** |

### Commercieel en juridisch

| # | Bevinding | Ernst | Advies |
|---|---|---|---|
| C1 | **Naam vóór de merkcheck**: de werktitel *Polderlight*, de korte merkcheck ("voorlopig groen, registers niet bevraagd", `merkcheck-polderlight.md`) en de nog niet gedane formele check worden openbaar. Iemand kan de naam (merk, domein, handles, Steam-naam) eerder vastleggen. Dat staat in de geschiedenis, dus een bestand aanpassen helpt niet. Daarnaast heet de repo nog `echoborn`, de naam van een bestaande game in hetzelfde genre met een Amerikaanse merkaanvraag (`naamcheck.md` §1). | 🟠 | **Bestanden: niets doen.** De formele merkcheck (besluit #24, 3A; raming #51 deel 1) niet lang laten liggen; of en wanneer de studio domein of handles vastlegt, is een apart CEO-besluit (kost). De repo hernoemen (bv. naar `polderlight`) kan de CEO als instelling doen; GitHub stuurt oude links door. Laag risico, geen blokkade. |
| C2 | **Interne cijfers en strategie**: prijs ± € 20, verkoopraming (`markt-en-verkoopraming.md`), raming merkcheck € 3.750 (worstcase ± € 4.800), fase 2 € 0 extern, financiering eigen middelen + VAF, en de VAF-argumentatie (één mens + AI-rollen, keuze criteria, open vraag over de woonplaats). | 🟢 | **Niets doen.** Weinig nut voor concurrenten. Het VAF kan de repo lezen: zorg dat het ingediende dossier eerlijk overeenkomt met wat hier staat (dat doet het nu: AI-rollen staan er open in). |
| C3 | **IP van derden**: geen assets van derden in de repo behalve Godot (MIT, in het licentieregister); knop-glyphs zijn eigen tekeningen (`knop-glyphs-check.md`); geen logo's van platformen. | 🟢 | **Niets doen.** |
| C4 | **Geen licentiebestand.** Zonder licentie geldt al "alle rechten voorbehouden", maar dat is voor bezoekers niet duidelijk. GitHub-gebruikers mogen een openbare repo wel bekijken en forken op GitHub (GitHub Terms of Service, §D.5). | 🟢 | **Opgelost in deze PR**: `LICENSE` (§5). |
| C5 | **Actions op een openbare repo**: PR's uit forks starten de workflow `tests` met een leestoken en zonder secrets (`pull_request`, `contents: read`). | 🟢 | **Niets aan bestanden doen.** Instelling voor de CEO in §4. |

## 4. Wat de CEO zelf instelt (geen werk van de studio)

Allemaal instellingen op GitHub; de BLA heeft er niets aan veranderd.

1. **Vóór het omzetten**: de keuze bij P1 (a, b of c).
2. **Mailadres afschermen** (GitHub → Settings → Emails): *Keep my email addresses private* en *Block command line pushes that expose my email*. Dan gebruiken commits via de webinterface en merges vanaf nu het `noreply`-adres van GitHub. Lokaal: `git config --global user.email` op dat `noreply`-adres zetten.
3. **Na het omzetten** (repo → Settings → Code security): *Secret scanning* en *Push protection* aan (gratis voor openbare repo's).
4. **Actions** (repo → Settings → Actions → General): bij *Fork pull request workflows* "Require approval for all external contributors", zodat een vreemde PR geen minuten verbruikt zonder jouw klik.
5. Eventueel: repo hernoemen (C1).

## 5. LICENSE

`LICENSE` in de root: Engelse tekst "Copyright (c) 2026 CesarTheLittle. All rights reserved." met een korte Nederlandse uitleg. Inhoud: geen licentie, niets kopiëren, wijzigen of gebruiken zonder schriftelijke toestemming; bekijken en forken alleen voor zover de GitHub-voorwaarden dat vereisen; onderdelen van derden (Godot, MIT) houden hun eigen licentie en vallen er niet onder.

Kanttekeningen:
- De eigenaar staat er onder de schuilnaam; er is bewust geen echte naam toegevoegd. Wordt later een vennootschap opgericht (besluit #51 deel 1, 4A), dan moet de houder in `LICENSE` en in het licentieregister naar die vennootschap, na advies van de boekhouder of een jurist.
- Of er auteursrecht rust op AI-output, bepaalt het recht, niet deze tekst (`credits.md` §5, B6: Anthropic draagt zijn rechten over "if any"). De LICENSE beschermt wat beschermd kan worden; meer kan geen licentietekst.
- Een licentietekst is geen vervanging van advies van een advocaat; voor de commerciële release hoort dit mee in de check door een specialist.

## 6. Open punten

- P1: keuze van de CEO (a ⭐ / b / c) vóór het omzetten; vraag staat in [#276](https://github.com/cesarvangerwen-glitch/echoborn/issues/276).

## 7. Logboek wijzigingen

| Versie | Datum | Wijziging |
|---|---|---|
| 1.0 | 2026-11-13 | Eerste versie: controle geschiedenis, bestanden, issues en comments; LICENSE |
