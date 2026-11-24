# RunCat – DMS Plugin

Laufende Katze in der Bar, deren Lauftempo sich nach der CPU-Last richtet.
Nativer Port des Konzepts von [bzglve/runcat-text](https://github.com/bzglve/runcat-text)
(Python-Skript für Waybar/Polybar, seit August 2026 archiviert und nur noch
lesbar) für DankMaterialShell, da Erik DMS statt Waybar nutzt.

## Was übernommen wurde

- `runcat.ttf`: die Original-Sprite-Font mit 5 Lauf-Frames im Private-Use-
  Bereich (`U+E900`–`U+E904`), 1:1 aus dem archivierten Repo übernommen.
- Die FPS-Kurve: Bildwechsel linear zwischen `fps_l = 6` (0% CPU) und
  `fps_h = 90` (100% CPU), exakt dieselbe Formel wie im Original-Skript.

## Was anders ist

Das Original ist ein eigenständiges Python-Skript, das per `stdout` JSON an
Waybar/Polybar liefert. Da DMS kein Waybar-Modul-Protokoll spricht, ist
RunCat hier ein natives QML-Plugin:

- `/proc/stat` wird direkt im Plugin per `Proc.runCommand("cat /proc/stat")`
  im Sekundentakt gelesen (kein externer Python-Prozess nötig).
- Die CPU-Prozentberechnung nutzt Idle-vs-Total-Delta (wie `top`/`htop`)
  statt der vereinfachten 3-Feld-Summe aus dem Original – etwas genauer,
  gleiches Endergebnis (Katze läuft schneller unter Last).
- Popout mit Klick auf das Widget zeigt die Auslastung pro Kern.

## Struktur

- `plugin.json` – Plugin-Manifest (einzelnes Bar-Widget)
- `RunCatWidget.qml` – Bar-Pill (Katze + optional %) + Popout (Pro-Kern-Last)
- `RunCatSettings.qml` – Ein-/Ausschalten der Prozentanzeige
- `runcat.ttf` – Sprite-Font mit den 5 Animations-Frames

## Setup

1. Plugin aktivieren: DMS Settings → Plugins → **RunCat** einschalten
2. Widget zur Bar hinzufügen: Settings → Appearance → DankBar Layout →
   Widget `runCat` hinzufügen

## Entwicklung / Live-Reload

```bash
dms ipc call plugins reload runCat
```
