# Desktop Context Menu – DMS Plugin

Windows-artiges Kontextmenü per Klick auf eine freie Stelle des Desktops.

## Enthaltene Menüpunkte

- **Apps** – öffnet den DMS-Launcher gefiltert auf installierte Programme
- **Terminal** – startet dein Terminal (Standard: `ghostty`, änderbar in den Einstellungen)
- **Dateimanager** – startet deinen unter DMS-Settings hinterlegten Standard-Dateimanager
- **Browser** – startet deinen Standard-Browser
- **Tools** › Color Picker · Zwischenablage · Notizen · Prozessliste · Taskmanager (btop) ·
  Night Light · Nicht stören (umschalten / 1 h / bis morgen früh) · Koffein (Idle-Inhibitor) ·
  Energieprofil wechseln · Audio-Ausgang wechseln · Dock ein-/ausblenden
- **Screenshot** › Bereich / Ganzer Bildschirm / Aktives Fenster / Alle Bildschirme
- **Wallpaper** › Nächstes / Vorheriges / Datei wählen… / Carousel
- **Theme** › Hell / Dunkel / Umschalten / Theme wählen…
- **System** › Nach Updates suchen (`pacman -Syu` + `paru -Sua` im Terminal) ·
  Tastenkürzel · Fenster-Übersicht · Fensterregeln · Workspace umbenennen
- **Einstellungen** – öffnet die DMS-Settings
- **Sperren** – sperrt den Bildschirm
- **Power** – öffnet das DMS-Powermenü (Shutdown/Reboot/Logout/Suspend)

## Installation

```bash
mkdir -p ~/.config/DankMaterialShell/plugins
unzip DesktopContextMenu.zip -d ~/.config/DankMaterialShell/plugins/
```

Danach in DMS:

1. Settings → Plugins → **Scan for Plugins**
2. **Desktop Context Menu** aktivieren

## Ersteinrichtung – Widget auf Bildschirmgröße ziehen

Das Widget startet mit einer kleinen Mindestgröße (100×100px), da `defaultWidth`/
`defaultHeight` in manchen DMS-Versionen (u.a. 1.5.3) nicht existieren und den
Plugin-Load zum Absturz bringen würden. Du musst es daher **einmalig** auf
Bildschirmgröße ziehen:

1. Öffne Settings → Plugins → **Desktop Context Menu** → Einstellungen und
   aktiviere kurzzeitig **"Linksklick statt Rechtsklick"**. Das gibt den
   Rechtsklick für die eingebaute Verschieben/Skalieren-Funktion von DMS frei
   (unser Plugin fängt sonst jeden Rechtsklick ab).
2. Auf dem Desktop: Rechtsklick + Ziehen verschiebt das Widget an die
   obere linke Bildschirmecke; Rechtsklick + Ziehen an der unteren rechten
   Ecke vergrößert es, bis es den ganzen Bildschirm abdeckt.
3. Schalte **"Linksklick statt Rechtsklick"** wieder aus (oder lass sie an,
   falls dir Linksklick fürs Menü lieber ist) – ab jetzt öffnet der normale
   Rechtsklick auf dem Desktop unser Kontextmenü.

Bei mehreren Monitoren ggf. pro Bildschirm wiederholen.

## Wichtige Hinweise

- **Rechtsklick-Konflikt:** DMS nutzt Rechtsklick+Ziehen standardmäßig zum
  Verschieben/Skalieren von Desktop-Widgets. Das Plugin fängt den Rechtsklick
  ab und unterscheidet Klick von Ziehen – bei der Ersteinrichtung brauchst du
  trotzdem kurz den Linksklick-Modus (siehe oben).
- **Terminal:** Falls du nicht `ghostty` nutzt, trage in den
  Plugin-Einstellungen deinen Terminal-Befehl ein (z.B. `kitty`, `foot`).

## Entwicklung / Live-Reload

```bash
dms ipc call plugins reload desktopContextMenu
```
