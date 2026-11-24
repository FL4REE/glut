# Media Flyouts – DMS Plugin

Flyouts im FluentFlyout-Stil für Musik und Lock Keys. Sie liegen auf dem Overlay-Layer und erscheinen damit auch über Vollbild-Apps.

## Features

- **Musik-Flyout:** Cover, Titel, Artist, Fortschrittsbalken sowie Shuffle, Zurück, Play/Pause, Weiter und Wiederholen (aus, Playlist, ein Song). Smart Shuffle geht nicht, Spotify bietet das über MPRIS nicht an. Erscheint bei Songwechsel und bei Play/Pause, auch über die Medientasten. Daten kommen per MPRIS (getestet mit Spotify und YouTube im Helium-Browser).
- **Player ausschließen:** In den Settings eine Liste von Playern, die ignoriert werden (Standard: Helium-Browser).
- **Lock-Keys-Flyout:** Caps Lock, Num Lock und Scroll Lock an/aus. Liest die Tastatur-LEDs unter `/sys/class/leds`.
- **Frei verschiebbar:** Mit der linken Maustaste ziehen, die Position wird gespeichert. Solange die Maus drauf ist, blendet es sich nicht aus.

## Installation

```bash
ln -s ~/Projekte/MediaFlyouts ~/.config/DankMaterialShell/plugins/MediaFlyouts
```

Dann DMS Settings → Plugins → **Media Flyouts** einschalten. Die eingebauten DMS-OSDs für Medien und Caps Lock unter Settings → OSD abschalten, sonst kommt beides doppelt.

## Einstellungen

Musik- und Lock-Keys-Flyout einzeln an/aus, Anzeigedauer (2 bis 10 s), Position zurücksetzen. Änderungen wirken sofort.

## Technische Notizen

- Layer-Shell-Fenster kann der Compositor nicht selbst verschieben. Das Fenster ist oben links verankert und wird über die Margins positioniert. Beim Ziehen wird es kurz bildschirmfüllend und nur die Karte darin bewegt sich, sonst ruckelt es, weil Hyprland den Margins hinterherhinkt.
- Sysfs meldet LED-Änderungen nicht per inotify, deshalb werden die LEDs alle 200 ms per FileView gelesen (kein Prozessstart).
- "Up Next" wurde bewusst weggelassen: Spotify und YouTube liefern den nächsten Song nicht über MPRIS.

## Entwicklung

```bash
dms ipc call plugins reload mediaFlyouts
```
