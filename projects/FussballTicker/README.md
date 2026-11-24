# Fußball Ticker – DMS Plugin

Live-Ticker für Hansa Rostock, BVB, die Bundesliga und die deutsche Nationalmannschaft.
Zeigt den Spielstand als Bar-Widget, sobald eines dieser Teams tatsächlich spielt, und
schickt eine Desktop-Benachrichtigung bei Toren.

## Setup

1. Kostenlosen API-Key holen: https://dashboard.api-football.com/register
2. Plugin aktivieren: DMS Settings → Plugins → **Fußball Ticker** einschalten
3. In den Plugin-Settings den API-Key eintragen
4. Optional: Verfolgte Teams anpassen (Standard: Hansa Rostock, Borussia Dortmund,
   Germany). Team-Namen so eintragen, wie sie bei API-Football hinterlegt sind –
   meist die englische Schreibweise (z.B. "Germany" statt "Deutschland")
5. Plugin zur Bar hinzufügen: Settings → Appearance → DankBar Layout → Widget
   `fussballTicker` hinzufügen

## Free-Tier-Realität (wichtig!)

Beim Bau mit echtem Key getestet (28.08.2026) – der Free-Tier von API-Football ist
deutlich restriktiver als die allgemeine Doku vermuten lässt:

- `/fixtures?team=X&next=1` → **gesperrt** ("Free plans do not have access to the
  Next parameter")
- `/fixtures?team=X&season=2025` → **gesperrt** ("Free plans do not have access to
  this season, try from 2022 to 2024")
- `/standings?...&season=2025` → **gesperrt**, gleiche Einschränkung
- `/fixtures?live=all` → **funktioniert uneingeschränkt**, unabhängig vom Plan

Das heißt: es gibt im Free-Tier **keinen Weg**, Spielpläne, kommende Kickoff-Zeiten
oder aktuelle Tabellenstände abzurufen. Ursprünglich geplante Features ("Nächstes
Spiel", "Bundesliga-Tabelle") mussten deshalb rausgeworfen werden. Das Plugin
beschränkt sich auf das, was tatsächlich geht: reines Live-Tracking über
`/fixtures?live=all`, client-seitig gefiltert auf die konfigurierten Teams und die
gesamte Bundesliga.

## Wie das Polling funktioniert

Wegen des 100-Requests/Tag-Limits wird adaptiv gepollt:

- **Idle** (kein verfolgtes Spiel live): alle 15 Minuten (einstellbar), nur zwischen
  07:00 und 24:00 Uhr – nachts läuft ohnehin kaum Fußball
- **Live** (ein verfolgtes Spiel läuft gerade): alle 90 Sekunden (einstellbar)

An spielfreien Tagen liegt der Verbrauch bei ca. 60-70 Requests. An Spieltagen kommen
pro laufendem Spiel nochmal ca. 70-90 Requests dazu. Bei mehreren Spielen am selben
Tag (z.B. Rostock + BVB + Nationalmannschaft alle am Wochenende) kann das
Tageslimit knapp werden – im Zweifel die Intervalle in den Settings großzügiger
einstellen. Verbrauch lässt sich jederzeit über `GET /status` gegen die eigene
API prüfen.

## Bekannte Einschränkungen

- Keine Spielplan-Vorschau, keine Tabellen (siehe oben, Free-Tier-Limitierung)
- Torschützen werden nicht angezeigt, nur der neue Spielstand – ein Name würde
  einen zusätzlichen Request pro Tor an `/fixtures/events` brauchen
- Noch nicht im laufenden DMS getestet (nur die Kern-API-Calls per curl verifiziert),
  erster echter Testlauf steht noch aus

## Struktur

- `plugin.json` – Composite-Plugin-Manifest (Daemon + Bar-Widget)
- `FussballTickerDaemon.qml` – Polling-Logik gegen `/fixtures?live=all`, Filterung,
  Toast-Benachrichtigungen bei Toren
- `FussballTickerWidget.qml` – Bar-Pill (Live-Score) + Popout (laufende Spiele)
- `FussballTickerSettings.qml` – API-Key, Poll-Intervalle, verfolgte Teams

## Entwicklung / Live-Reload

```bash
dms ipc call plugins reload fussballTicker
```
