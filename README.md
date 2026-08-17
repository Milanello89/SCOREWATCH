# ScoreWatch – vodenje rezultata za Apple Watch

Samostojna aplikacija za Apple Watch za štetje rezultata pri **tenisu** in **badmintonu**.
Deluje neodvisno od iPhona.

---

## Upravljanje

| Poteza | Učinek |
|---|---|
| Klik na **zgornjo** polovico zaslona | točka zame |
| Klik na **spodnjo** polovico zaslona | točka za nasprotnika |
| **Dolg pritisk** (0,4 s) kjer koli | razveljavi zadnjo točko |
| Klik na **zgornjo vrstico** | možnosti (zaklep zaslona, zaključi dvoboj) |

Klik se odzove takoj – med kratkim klikom in dolgim pritiskom ni zakasnitve.
Vsak dogodek ima svoj otip: točka = kratek klik, gem = uspeh, set = obvestilo,
konec dvoboja = trojni otip.

---

## Kaj aplikacija zna

**Zaslon ostane prižgan.** Ob začetku dvoboja se zažene vadbena seja (HealthKit),
zato aplikacija ostane v ospredju ves čas igre in rezultat je viden tudi v načinu
Always-On. Brez tega bi se aplikacija po nekaj sekundah umaknila v ozadje.
Stranska korist: dvoboj se zapiše med vadbe, skupaj s srčnim utripom in porabo energije.

**Pravo štetje, ne le števec.**

- *Tenis:* 0 / 15 / 30 / 40, prednost, gemi, seti (6 z razliko 2, 7:5, 7:6),
  podaljšana igra do 7, možnost igre brez prednosti in odločilnega seta do 10 točk.
- *Badminton:* do 21 točk, potrebna razlika 2, absolutna zgornja meja 30, na 2 dobljena seta.
- *Prosto štetje:* samo dva števca, brez pravil – za trening ali poljubno igro.

**Indikator servisa.** Pika ob rezultatu pove, kdo servira. V tenisu se servis menja
po vsakem gemu in na vsaki dve točki v podaljšani igri, v badmintonu ga dobi
zmagovalec zadnje izmenjave. To je podatek, ki se med igro najlažje izgubi.

**Opozorila med igro.** Aplikacija sama zazna in prikaže „Neodločeno“, „Žogica za set“
in „Žogica za dvoboj“.

**Zanesljiva razveljavitev.** Vsaka točka shrani celotno prejšnje stanje, zato undo
pravilno deluje tudi čez mejo gema, seta ali konca dvoboja.

**Zaklep zaslona (Water Lock)** proti dežju in potu, da med brisanjem roke ne pride
do lažnih klikov. Odkleneš ga z zavrtljajem digitalne krone.

**Zgodovina zadnjih 50 dvobojev** z deležem zmag.

---

## Namestitev

Aplikacijo za Apple Watch je mogoče zgraditi izključno z Xcode na macOS.
Na voljo so tri poti.

### A) Imaš dostop do Maca (najhitreje – 5 minut)

1. Namesti **Xcode** iz App Store (brezplačno).
2. Odpri `ScoreWatch.xcodeproj`.
3. Xcode → Settings → Accounts → dodaj svoj Apple ID (zadošča brezplačen).
4. Izberi tarčo **ScoreWatch** → zavihek *Signing & Capabilities* →
   *Team* nastavi na svoje ime.
5. V `PRODUCT_BUNDLE_IDENTIFIER` zamenjaj `si.inoxcenter.scorewatch.watchkitapp`
   z nečim svojim, če pride do napake o zasedenem identifikatorju.
6. Uro poveži z Macom prek iPhona (uro mora Xcode videti pod *Devices and Simulators*),
   izberi jo kot cilj in pritisni ▶.

Z brezplačnim Apple ID aplikacija deluje 7 dni, nato jo z istim postopkom osvežiš.
S plačanim računom (99 USD/leto) velja eno leto.

### B) Nimaš Maca – gradnja prek GitHub Actions

GitHub brezplačno ponuja gradnjo na Applovih računalnikih.

1. Ustvari nov repozitorij na GitHubu in vanj naloži to mapo.
2. Potek **„Preveri, ali se aplikacija zgradi“** (`.github/workflows/build.yml`)
   se zažene samodejno in pokaže, ali se koda prevede brez napak.
3. Za namestitev na uro potrebuješ plačan Apple Developer Program.
   Nato v GitHubu nastavi skrivnosti (Settings → Secrets and variables → Actions):
   `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `APPLE_TEAM_ID`
   in ročno poženi potek **„Objavi na TestFlight“**.
4. Aplikacija se pojavi v TestFlightu na iPhonu; od tam se namesti na uro.

Poštena opomba: korak 3 pri prvem zagonu praviloma zahteva manjšo prilagoditev
(najpogosteje registracijo identifikatorja aplikacije v App Store Connect).
Dnevnik GitHub Actions natančno pove, kaj manjka.

### C) Predaš programerju

Mapa je popoln, samostojen Xcode projekt. Programerju zadošča ta stavek:
*„Odpri `ScoreWatch.xcodeproj`, nastavi svoj Team in bundle identifier ter namesti na uro.“*

---

## Struktura projekta

```
ScoreWatch.xcodeproj              Xcode projekt
ScoreWatch Watch App/
  ScoreWatchApp.swift             vstopna točka
  Models/
    MatchModels.swift             podatkovni tipi (igralec, šport, nastavitve, stanje)
    MatchEngine.swift             celotna logika štetja  ← tu so pravila
  Views/
    ContentView.swift             usmerjevalnik med zasloni
    SetupView.swift               nastavitve pred dvobojem
    MatchView.swift               glavni zaslon z dvema tap conama
    SummaryView.swift             povzetek po dvoboju
    HistoryView.swift             zgodovina
  Services/
    WorkoutManager.swift          vadbena seja – zaslon ostane prižgan
    Haptics.swift                 otipi
    MatchStore.swift              shramba dvobojev
  Assets.xcassets                 ikona in barva poudarka
.github/workflows/                gradnja brez lastnega Maca
```

---

## Kaj je najlažje prilagoditi

| Kaj | Kje |
|---|---|
| Barvi obeh polovic | `MatchView.swift`, vrstica `let base: Color = isMe ? .green : .orange` |
| Napisa „JAZ“ / „NASPROTNIK“ | `MatchView.swift`, funkcija `zone(for:)` |
| Trajanje dolgega pritiska | `MatchView.swift`, `minimumDuration: 0.4` |
| Pravila štetja | `MatchEngine.swift` – funkcije `resolveBadmintonSet`, `resolveTennisPoint`, `resolveTiebreak` |
| Otipi | `Haptics.swift` |
| Ikona | `Assets.xcassets/AppIcon.appiconset/AppIcon1024.png` |

---

## Različica za telefon (deluje takoj, brez Maca)

V korenu repozitorija je ista aplikacija za telefon – ista logika štetja,
isto upravljanje. Brez razvijalskega računa in brez stroškov.

### Objava v treh korakih

1. V repozitoriju odpri **Settings → Pages**.
2. Pod *Source* izberi **Deploy from a branch**, veja `main`, mapa `/ (root)`, shrani.
3. Po nekaj minutah je aplikacija na naslovu
   `https://tvoje-ime.github.io/ime-repozitorija/`

Naslov odpri v Safariju → gumb za deljenje → **Dodaj na začetni zaslon**.

### Kaj dobiš

Aplikacija se zažene čez cel zaslon, brez naslovne vrstice, s svojo ikono.
Ob prvem obisku se prek `sw.js` shrani na napravo, zato **deluje tudi brez
internetne povezave** – v dvorani ali na igrišču brez signala. Na dnu
začetnega zaslona piše, ali je shranjevanje uspelo.

Med dvobojem prek Wake Lock API prepreči, da bi se zaslon ugasnil.

### Datoteke različice za telefon

```
index.html              aplikacija (vmesnik in logika štetja)
manifest.webmanifest    ime, ikone in način prikaza na začetnem zaslonu
sw.js                   shranjevanje za delovanje brez povezave
icon-180.png            ikona za iPhone
icon-192.png            ikona za Android
icon-512.png            ikona v visoki ločljivosti
icon-maskable-512.png   ikona za obrezovanje v krog
.nojekyll               GitHub Pages naj datoteke servira nespremenjene
```

Ob spremembi `index.html` povečaj številko različice v prvi vrstici `sw.js`
(`rezultat-v1` → `rezultat-v2`), sicer bodo telefoni še naprej prikazovali
shranjeno staro različico.

---

## Preverjenost logike

Logika štetja je preverjena s 63 avtomatskimi testi, ki pokrivajo med drugim:
neodločen izid in prednost, igro brez prednosti, set 7:5 in 7:6, podaljšano igro
z razliko dveh točk, odločilni set do 10, badminton pri 20:20 in 29:29,
šestdeset zaporednih razveljavitev ter razveljavitev čez mejo gema, seta in konca dvoboja.
