import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins

DesktopPluginComponent {
    id: root

    // Hinweis: "defaultWidth"/"defaultHeight" existieren in manchen DMS-Versionen
    // nicht als Property von DesktopPluginComponent und würden den Component-Load
    // zum Absturz bringen. Das Widget startet daher mit Mindestgröße - zieh es beim
    // ersten Mal per Rechtsklick+Ziehen (bzw. Linksklick, falls "useLeftClick" aktiv
    // ist) an der unteren rechten Ecke auf Bildschirmgröße.
    minWidth: 100
    minHeight: 100

    // Rechtsklick ist in DMS fest für die eingebaute Verschieben/Skalieren-Funktion
    // von Desktop-Widgets reserviert (sitzt oberhalb unseres eigenen Inhalts) -
    // daher standardmäßig Linksklick fürs Menü verwenden.
    property bool useLeftClick: pluginData.useLeftClick ?? true
    property string terminalCmd: pluginData.terminalCmd ?? "ghostty"

    // "Alle Fenster floaten": setzt zur Laufzeit eine Wildcard-Fensterregel
    // (fängt auch neu geöffnete Fenster ab) und schaltet alle aktuell offenen
    // Fenster einmalig um. Zum Zurückschalten wird die Hyprland-Config neu
    // geladen, das entfernt die Laufzeit-Regel wieder sauber (die Lua-Config
    // selbst enthält sie ja nicht), und alle Fenster werden zurück auf tiled
    // gesetzt.
    //
    // Diese Hyprland-Version nutzt den neuen Lua-Config-Parser - klassisches
    // "hyprctl keyword"/"hyprctl dispatch <name> <args>" funktioniert damit
    // NICHT mehr ("keyword can't work with non-legacy parsers"). Alles läuft
    // über "hyprctl eval '<lua code>'". Wichtig: hl.dsp.window.float(...)
    // baut nur ein Dispatcher-Objekt, ausgeführt wird es erst mit
    // hl.dispatch(...) drumherum - ohne das passiert schlicht nichts (aber
    // auch kein Fehler, "ok" kommt trotzdem zurück).
    property bool allFloating: pluginData.allFloating ?? false

    function toggleAllFloating() {
        const newState = !root.allFloating;
        root.setData("allFloating", newState);
        if (newState) {
            Quickshell.execDetached(["hyprctl", "eval",
                'hl.window_rule({ match = { class = "^(.*)$" }, float = true })']);
            Quickshell.execDetached(["hyprctl", "eval",
                'for _, w in ipairs(hl.get_windows()) do hl.dispatch(hl.dsp.window.float({ action = "on", window = "address:" .. w.address })) end']);
        } else {
            Quickshell.execDetached(["hyprctl", "reload"]);
            Quickshell.execDetached(["hyprctl", "eval",
                'for _, w in ipairs(hl.get_windows()) do hl.dispatch(hl.dsp.window.float({ action = "off", window = "address:" .. w.address })) end']);
        }
    }

    // pokefetch: Pokémon-Auswahl an Theme-Farben anpassen (fish_greeting prüft
    // die universelle Variable pokefetch_theme_aus, themectl setzt die Farben)
    property bool pokeThemeMatch: pluginData.pokeThemeMatch ?? true

    function togglePokeThemeMatch() {
        const newState = !root.pokeThemeMatch;
        root.setData("pokeThemeMatch", newState);
        Quickshell.execDetached(["fish", "-c",
            newState ? "set -Ue pokefetch_theme_aus" : "set -U pokefetch_theme_aus 1"]);
    }

    // Der DesktopPluginWrapper von DMS wertet diese Property aus und setzt dann
    // WlrKeyboardFocus.OnDemand - damit bekommt das Menü beim Klick Tastaturfokus
    // und Esc kann das Popup schließen.
    //
    // WICHTIG: nur binden solange das Popup tatsächlich offen ist (contextMenu.visible).
    // Mit "true" fest verdrahtet würde diese fast bildschirmfüllende Fläche dauerhaft
    // Keyboard-Fokus beanspruchen und neu geöffneten Fenstern (z.B. Terminal per
    // Super+Enter) den automatischen Tastaturfokus wegschnappen - man musste dann
    // immer erst manuell reinklicken. Gefunden und gefixt am 2026-09-05.
    property bool acceptsKeyboardFocus: contextMenu.visible

    // --- themectl (theme-switcher) -------------------------------------
    // Gespeicherte Themes kommen aus "themectl list --json" und werden bei
    // jedem Öffnen des Menüs neu eingelesen.
    readonly property string themectl: Quickshell.env("HOME") + "/.local/bin/themectl"
    property var savedThemes: []

    Process {
        id: themeListProc
        property string lastText: ""
        command: [root.themectl, "list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Nur bei Änderung neu zuweisen: sonst baut menuItems (hängt an savedThemes)
                // bei jedem Öffnen ~100 ms später das komplette Menü neu auf -> Ruckler.
                if (this.text === themeListProc.lastText) return
                themeListProc.lastText = this.text
                try { root.savedThemes = JSON.parse(this.text) } catch (e) { root.savedThemes = [] }
            }
        }
    }

    function refreshThemes() {
        if (!themeListProc.running)
            themeListProc.running = true
    }

    property var themeMenuChildren: {
        // Einzelne Themes stehen nicht mehr im Menü (zu lang) - Auswahl über den Launcher
        const current = root.savedThemes.find(t => t.current)
        return [
            { icon: "style", text: current ? "Theme wählen… (" + current.name + ")" : "Theme wählen…",
              action: dmsIpc(["spotlight", "openQuery", "~"]) },
            { icon: "skip_next", text: "Nächstes Theme",
              action: () => Quickshell.execDetached([root.themectl, "next"]) },
            { icon: "grid_view", text: "Theme Galerie…",
              action: () => Quickshell.execDetached([root.themectl, "gallery"]) },
            { icon: "travel_explore", text: "Online suchen…",
              action: () => Quickshell.execDetached([root.themectl, "gallery", "--online"]) },
            { icon: "save", text: "Aktuelles speichern…",
              action: () => Quickshell.execDetached([root.terminalCmd, "-e", "bash", "-c",
                  "read -p 'Name für das neue Theme: ' n && [ -n \"$n\" ] && " + root.themectl + " save \"$n\"; " +
                  "echo; read -p 'Enter zum Schließen'"]) },
            { separator: true },
            { icon: "light_mode", text: "Hell",
              action: dmsIpc(["theme", "light"]) },
            { icon: "dark_mode", text: "Dunkel",
              action: dmsIpc(["theme", "dark"]) },
            { icon: "contrast", text: "Hell/Dunkel umschalten",
              action: dmsIpc(["theme", "toggle"]) },
            { icon: "style", text: "DMS-Themes…",
              action: dmsIpc(["settings", "openWith", "theme"]) }
        ]
    }

    function dmsIpc(args) {
        return () => Quickshell.execDetached(["dms", "ipc", "call"].concat(args))
    }
    function run(args) {
        return () => Quickshell.execDetached(args)
    }
    // glut-Tools in ~/.local/bin (DMS als Dienst hat das nicht zwingend im PATH)
    function glut(name, args) {
        return run([Quickshell.env("HOME") + "/.local/bin/" + name].concat(args || []))
    }

    property var menuItems: [
        {
            icon: "apps", text: "Apps",
            action: dmsIpc(["spotlight", "openWith", "apps"])
        },
        {
            icon: "terminal", text: "Terminal",
            action: () => Quickshell.execDetached([root.terminalCmd])
        },
        {
            icon: "folder", text: "Dateimanager",
            action: dmsIpc(["defaultApp", "fileManager"])
        },
        {
            icon: "public", text: "Browser",
            action: dmsIpc(["defaultApp", "browser"])
        },
        { separator: true },
        {
            icon: "build", text: "Tools",
            children: [
                { icon: "colorize", text: "Color Picker",
                  action: dmsIpc(["color-picker", "open"]) },
                { icon: "content_paste", text: "Zwischenablage",
                  action: dmsIpc(["clipboard", "toggle"]) },
                { icon: "sticky_note_2", text: "Notizen",
                  action: dmsIpc(["notepad", "toggle"]) },
                { icon: "monitor_heart", text: "Prozessliste",
                  action: dmsIpc(["processlist", "toggle"]) },
                { icon: "terminal", text: "Taskmanager (btop)",
                  action: () => Quickshell.execDetached([root.terminalCmd, "-e", "btop"]) },
                { icon: "nightlight", text: "Night Light umschalten",
                  action: dmsIpc(["night", "toggle"]) },
                { icon: "notifications_off", text: "Nicht stören umschalten",
                  action: dmsIpc(["notifications", "toggleDoNotDisturb"]) },
                { icon: "schedule", text: "Nicht stören: 1 Stunde",
                  action: dmsIpc(["notifications", "enableDoNotDisturbFor", "60"]) },
                { icon: "bedtime", text: "Nicht stören: bis morgen früh",
                  action: dmsIpc(["notifications", "enableDoNotDisturbUntilTomorrowMorning"]) },
                { icon: "local_cafe", text: "Koffein (Sperre verhindern)",
                  action: dmsIpc(["inhibit", "toggle"]) },
                { icon: "bolt", text: "Energieprofil wechseln",
                  action: dmsIpc(["powerprofile", "cycle"]) },
                { icon: "speaker", text: "Audio-Ausgang wechseln",
                  action: dmsIpc(["audio", "cycleoutput"]) },
                { icon: "dock_to_bottom", text: "Dock ein-/ausblenden",
                  action: dmsIpc(["dock", "toggle"]) },
                { icon: "swap_horiz", text: "App-Leiste ↔ Dock unten",
                  action: glut("dockmodus") },
                { icon: "mic", text: "Diktat starten/stoppen",
                  action: glut("diktat") },
                { icon: "music_note", text: "Welcher Song läuft?",
                  action: glut("welcher-song") },
                { icon: "extension", text: "Plugin Store",
                  action: glut("plugin-store") }
            ]
        },
        {
            icon: "photo_camera", text: "Screenshot",
            children: [
                { icon: "crop", text: "Bereich auswählen",
                  action: run(["dms", "screenshot"]) },
                { icon: "fullscreen", text: "Ganzer Bildschirm",
                  action: run(["dms", "screenshot", "full"]) },
                { icon: "picture_in_picture", text: "Aktives Fenster",
                  action: run(["dms", "screenshot", "window"]) },
                { icon: "select_all", text: "Alle Bildschirme",
                  action: run(["dms", "screenshot", "all"]) }
            ]
        },
        {
            icon: "highlight_alt", text: "Bereich",
            children: [
                { icon: "text_fields", text: "Text erkennen (OCR)",
                  action: glut("bereich", ["text"]) },
                { icon: "image_search", text: "Mit Google Lens suchen",
                  action: glut("bereich", ["lens"]) },
                { icon: "translate", text: "Text übersetzen",
                  action: glut("bereich", ["uebersetzen"]) },
                { icon: "videocam", text: "Aufnehmen (Start/Stop)",
                  action: glut("bereich", ["aufnahme"]) },
                { icon: "video_call", text: "Mit Ton aufnehmen",
                  action: glut("bereich", ["aufnahme", "--ton"]) }
            ]
        },
        {
            icon: "wallpaper", text: "Wallpaper",
            children: [
                { icon: "skip_next", text: "Nächstes Wallpaper",
                  action: dmsIpc(["wallpaper", "next"]) },
                { icon: "skip_previous", text: "Vorheriges Wallpaper",
                  action: dmsIpc(["wallpaper", "prev"]) },
                { icon: "shuffle", text: "Zufälliges Wallpaper",
                  action: () => Quickshell.execDetached(["sh", "-c",
                      "cur=$(dms ipc call wallpaper get); dir=$(dirname \"$cur\"); " +
                      "new=$(find -L \"$dir\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.bmp' -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.jxl' -o -iname '*.avif' -o -iname '*.heif' \\) 2>/dev/null | grep -vFx \"$cur\" | shuf -n1); " +
                      "[ -n \"$new\" ] && dms ipc call wallpaper set \"$new\""]) },
                { icon: "folder_open", text: "Datei wählen…",
                  action: dmsIpc(["file", "browse", "wallpaper"]) },
                { icon: "view_carousel", text: "Carousel",
                  action: dmsIpc(["wallpaperCarousel", "toggle"]) },
                { separator: true },
                // Live-Hintergründe über Wallpaper Engine, siehe ~/.local/bin/livewallpaper
                { icon: "video_library", text: "Live: auswählen…",
                  action: run([Quickshell.env("HOME") + "/.local/bin/livewallpaper", "pick"]) },
                { icon: "auto_awesome", text: "Live: zufällig",
                  action: run([Quickshell.env("HOME") + "/.local/bin/livewallpaper", "random"]) },
                { icon: "play_circle", text: "Live: letzten starten",
                  action: run([Quickshell.env("HOME") + "/.local/bin/livewallpaper"]) },
                { icon: "stop_circle", text: "Live: beenden",
                  action: run([Quickshell.env("HOME") + "/.local/bin/livewallpaper", "stop"]) }
            ]
        },
        {
            icon: "palette", text: "Theme",
            children: root.themeMenuChildren
        },
        {
            icon: "settings_applications", text: "System",
            children: [
                { icon: "system_update", text: "Nach Updates suchen",
                  action: () => Quickshell.execDetached([root.terminalCmd, "-e", "bash", "-c",
                      "sudo pacman -Syu && paru -Sua; echo; read -p 'Fertig - Enter zum Schließen'"]) },
                { icon: "keyboard", text: "Tastenkürzel",
                  action: dmsIpc(["hypr", "openBinds"]) },
                { icon: "grid_view", text: "Fenster-Übersicht",
                  action: dmsIpc(["hypr", "toggleOverview"]) },
                { icon: "rule", text: "Fensterregeln",
                  action: dmsIpc(["window-rules", "open"]) },
                { icon: "drive_file_rename_outline", text: "Workspace umbenennen",
                  action: dmsIpc(["workspace-rename", "open"]) },
                { icon: root.allFloating ? "check_box" : "check_box_outline_blank",
                  text: "Alle Fenster floaten",
                  action: () => root.toggleAllFloating() },
                { icon: root.pokeThemeMatch ? "check_box" : "check_box_outline_blank",
                  text: "Pokémon an Theme anpassen",
                  action: () => root.togglePokeThemeMatch() },
                { icon: (SettingsData.barConfigs.find(b => b.id === "default") || {}).autoHide ? "check_box" : "check_box_outline_blank",
                  text: "Leiste automatisch ausblenden",
                  action: dmsIpc(["bar", "toggleAutoHide", "id", "default"]) },
                { icon: (SettingsData.barConfigs.find(b => b.id === "leftDock") || {}).autoHide ? "check_box" : "check_box_outline_blank",
                  text: "Linke Leiste automatisch ausblenden",
                  action: dmsIpc(["bar", "toggleAutoHide", "id", "leftDock"]) }
            ]
        },
        { separator: true },
        {
            icon: "settings", text: "Einstellungen",
            action: dmsIpc(["settings", "open"])
        },
        {
            icon: "lock", text: "Sperren",
            action: dmsIpc(["lock", "lock"])
        },
        {
            icon: "power_settings_new", text: "Power",
            action: dmsIpc(["powermenu", "toggle"])
        }
    ]

    // Fast unsichtbar - nur ein dünner Rahmen, damit man die Fläche beim
    // Einrichten überhaupt findet und auf Bildschirmgröße ziehen kann.
    // Das Wallpaper bleibt darunter normal sichtbar.
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: Theme.outlineStrong
        border.width: 1
        opacity: 0.35
    }

    property point pressPos: Qt.point(0, 0)

    MouseArea {
        anchors.fill: parent
        acceptedButtons: root.useLeftClick ? Qt.LeftButton : Qt.RightButton
        onPressed: (mouse) => {
            root.pressPos = Qt.point(mouse.x, mouse.y)
            // Event hier "schlucken", damit die eingebaute Verschieben-Funktion
            // des Desktop-Widgets nicht gleichzeitig anspringt.
            mouse.accepted = true
        }
        onClicked: (mouse) => {
            var dx = mouse.x - root.pressPos.x
            var dy = mouse.y - root.pressPos.y
            if (Math.sqrt(dx * dx + dy * dy) < 6) {
                root.refreshThemes()
                contextMenu.openAt(mouse.x, mouse.y)
            }
        }
    }

    DesktopMenuPopup {
        id: contextMenu
        items: root.menuItems
    }
}
