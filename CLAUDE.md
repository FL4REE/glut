# glut – Arbeitsnotizen für Claude

glut ist Eriks täglicher Desktop: CachyOS, Hyprland 0.57 mit Lua-Config, DankMaterialShell (dux-shell). Das Repo
ist öffentlich (github.com/FL4REE/glut, MIT) und **spiegelt den Live-Desktop**. `install.sh` baut daraus einen
frischen Rechner nach. Mit Erik wird Deutsch gesprochen. README und install.sh sind auf Englisch, die Meldungen der
Tools auf Deutsch.

## Grundregeln

- **Nichts Persönliches ins öffentliche Repo**: keine private Mail-Adresse, keine Vault- oder Notiz-Pfade, keine Tokens
  oder Claude-Config, keine Fotos von Erik. Das gehört nach **FL4REE/glut-private** (`~/Projekte/glut-private`), das
  `install.sh` am Ende ausführt, wenn `gh` Zugriff hat.
- Git-Identität im Repo: `FL4REE <86767765+FL4REE@users.noreply.github.com>` (lokal gesetzt). Commit-Nachrichten auf
  Deutsch, ohne `Co-Authored-By`-Zeile. Vor dem Push `git pull --rebase --autostash`, denn der nächtliche Timer pusht auch.
- Keinen fremden Code ins Repo kopieren. Plugins und Themes holt `install.sh` aus der Quelle, festgelegt auf einen Commit.
  Von GPL-Projekten (z. B. end-4/dots-hyprland) nur Ideen übernehmen, nichts abschreiben.
- Aussagen in der README nur machen, wenn sie geprüft sind (Hotkeys, Funktionen, Beschreibungen von Plugins).

## Wie Desktop und Repo zusammenhängen

- Auf dem Desktop sind die Configs **echte Ordner**. `bin/confsync` spiegelt sie nach `config/manifest.txt` ins Repo
  (Ausnahmen in `config/exclude.txt`, Geheimnis-Check vor dem Commit). `bin/pkgsync` gleicht `packages/*.txt` ab.
  Beide laufen nachts über `pkgsync.timer` und committen und pushen dabei selbst.
- Live ändern, dann `confsync update` aufrufen. **Nie `confsync … | head`**: Das bricht den Lauf mittendrin ab.
- Auf Rechnern, die mit `install.sh` eingerichtet wurden, sind die Configs Symlinks ins Repo.
- Neuer Config-Ort: eine Zeile in `manifest.txt`. Neues Paket: in `packages/pacman.txt` (pkgsync ergänzt es sonst
  nachts unter „Neu erfasst“). Treiber, Kernel und `cachyos-*` stehen in `packages/ignore.txt`.
- Fremde DMS-Plugins stehen in `config/dms/plugins.lock.json` (`dms plugins lock`, macht der Plugin Store automatisch);
  `install.sh` stellt sie mit `dms plugins restore` wieder her. Nicht mehr von Hand in `install.sh` klonen.
- Wallpaper sind **nicht** im Repo. Sie liegen als Release-Asset `wallpapers-v1/wallpapers.tar` (136 Themes, 496 MB).

## Ein neues Tool hinzufügen

1. Skript nach `bin/<name>`, ausführbar. `install.sh` verlinkt alles in `bin/` nach `~/.local/bin`, lokal mit `ln -sf` verlinken.
2. Hotkey in `~/.config/hypr/dms/binds-user.lua` mit `description = "glut · …"`. Das Präfix ist wichtig: In der
   DMS-Übersicht (`SUPER + ß` / `SUPER + F1`) zeigt die Suche „glut“ genau diese Hotkeys. Eigene Kategorien
   kann DMS nicht, die Kategorie folgt aus der Art der Aktion.
3. Befehle ohne Pfad aufrufen, denn Hyprland hat `~/.local/bin` im PATH. Danach `hyprctl reload`, `hyprctl configerrors` und
   `dms keybinds show hyprland` prüfen.
4. README: Zeile in der Keybinds-Tabelle und in „Custom tooling“. Pakete in `pacman.txt`.
5. `confsync update`, committen, pushen.

Bisherige Tools: diktat (whisper.cpp/CUDA), app (Web-Apps per Kurzname), bereich (OCR/Lens/Übersetzen/GPU-Aufnahme),
welcher-song (songrec), plugin-store (GUI `apps/plugin-store/shell.qml`, DMS- und Omarchy-Katalog, Omarchy-Ports
in `~/Projekte/dms-ports/`), pokefetch-color, livewallpaper, confsync, pkgsync. Dazu themectl aus FL4REE/theme-switcher.

## Praktisches und Stolperfallen

- Hyprland-Lua über die Kommandozeile: `hyprctl dispatch 'hl.dsp.focus({ workspace = 7 })'`,
  `hyprctl dispatch 'hl.dsp.window.close({ window = "address:0x…" })'`.
- **`wtype` löst keine Hyprland-Hotkeys aus.** Es tippt ins fokussierte Fenster, im Zweifel in Eriks Chat. Hotkeys muss
  Erik selbst testen.
- DMS: `dms ipc show` listet alle Ziele. `dms screenshot full|region --no-notify --no-clipboard --stdout|-d DIR --json`,
  `dms screenshot -g` liefert die Geometrie einer Auswahl.
- Theme wechseln: `themectl apply <name>`, aktuelles mit `themectl current`. Erik nutzt meist `dmc`.
- Größere Pakete installiert Erik selbst (sudo). Bei 404-Fehlern von pacman ist die Sync-DB veraltet, dann `pacman -Syu`.

## Screenshots für die README

- Nur auf einem **leeren Workspace (7)**. Direkt vor jedem Foto prüfen, ob Workspace 7 aktiv und leer ist, sonst
  landen Eriks Chat oder Browser im Bild. Erik vorher bitten, Maus und Tastatur nicht anzufassen.
- Immer mit `--no-notify` fotografieren. Nach `themectl apply` kurz auf Workspace 8 und zurück wechseln, damit die Leiste nachzieht.
- Jedes Bild auf Privates ansehen. Das Profilbild im Kontrollzentrum wird ersetzt, eingeloggte Web-Apps, Zwischenablage,
  Benachrichtigungen und die Übersicht aller Workspaces werden nicht gezeigt.
- Bilder als JPG (Qualität 80–82, max. 1920–2560 px breit) nach `.github/assets/`. Am Ende das alte Theme wiederherstellen.

## Offen / Ideen

- `install.sh` wurde noch nie komplett auf einem frischen System getestet (CachyOS-VM oder der Laptop).
- Mögliche nächste Features: Blendschutz-Shader (`decoration:screen_shader`), markierten Text an das lokale Ollama,
  Touchpad-Gesten für den Laptop, Emoji-Auswahl, `install.sh --dry-run`, Warnungen bei Temperatur und Netzabbruch,
  `lookas`, vergrößerter Ausschnitt der Leiste (RunCat, Fußball-Ticker) für die README.
- Ausdrücklich nicht gewünscht: die übrige end-4-Optik (Ecken, Blur, Abstände). Die Animationen sind schon identisch.
