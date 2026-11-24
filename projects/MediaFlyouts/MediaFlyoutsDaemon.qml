import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

// Flyouts im FluentFlyout-Stil auf dem Overlay-Layer, damit sie auch über
// Vollbild-Apps liegen. Zwei Arten:
//   - "media": bei Trackwechsel und Play/Pause (auch über die Medientasten)
//   - "lock":  bei Änderung von Caps, Num oder Scroll Lock
//
// Verschieben: Flyout mit der linken Maustaste ziehen. Layer-Shell-Fenster kann
// der Compositor nicht selbst bewegen, deshalb wird das Fenster oben links
// verankert und die Position über die Margins gesetzt (wie bei den
// DMS-Desktop-Widgets). Die Position wird in den Plugin-Daten gespeichert.
PluginComponent {
    id: root

    // Player, die ignoriert werden (Teilstring von Name, Desktop-Eintrag oder
    // D-Bus-Name, ohne Groß/Kleinschreibung). Standard: Helium-Browser. Helium
    // basiert auf Chromium und meldet sich bei MPRIS evtl. als "chromium".
    property var excludedPlayers: ["helium", "chromium"]

    function isExcluded(p) {
        const ids = [p.identity, p.desktopEntry, p.dbusName].map(x => (x || "").toLowerCase());
        return root.excludedPlayers.some(e => e && ids.some(i => i.includes(e)));
    }

    // Bevorzugt den aktiven Player von DMS. Ist der ausgeschlossen, nimm einen
    // anderen, der gerade spielt, sonst irgendeinen nicht ausgeschlossenen.
    readonly property var player: {
        const active = MprisController.activePlayer;
        if (active && !root.isExcluded(active))
            return active;
        const players = Mpris.players.values.filter(p => !root.isExcluded(p));
        return players.find(p => p.isPlaying) ?? players[0] ?? null;
    }
    property bool flyoutVisible: false
    property string mode: "media"
    property bool pointerInside: false

    readonly property int flyoutWidth: 520
    readonly property int flyoutHeight: 112

    // -1 = noch nie verschoben, dann unten mittig
    property real posX: -1
    property real posY: -1
    property bool mediaEnabled: true
    property bool lockEnabled: true
    property int durationSeconds: 4

    function loadSettings() {
        root.posX = PluginService.loadPluginData(root.pluginId, "posX", -1);
        root.posY = PluginService.loadPluginData(root.pluginId, "posY", -1);
        root.mediaEnabled = PluginService.loadPluginData(root.pluginId, "mediaEnabled", true);
        root.lockEnabled = PluginService.loadPluginData(root.pluginId, "lockEnabled", true);
        root.durationSeconds = PluginService.loadPluginData(root.pluginId, "durationSeconds", 4);
        const excluded = PluginService.loadPluginData(root.pluginId, "excludedPlayers", [{ name: "helium" }, { name: "chromium" }]);
        root.excludedPlayers = excluded.map(e => (e.name || "").trim().toLowerCase()).filter(n => n.length > 0);
    }

    // Änderungen in den Settings sofort übernehmen, ohne Plugin-Reload
    Connections {
        target: PluginService
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === root.pluginId)
                root.loadSettings();
        }
    }

    readonly property bool hasProgress: (root.player?.positionSupported ?? false) && (root.player?.lengthSupported ?? false) && (root.player?.length ?? 0) > 0
    readonly property real progress: root.hasProgress ? Math.min(1, root.player.position / root.player.length) : 0

    function formatTime(seconds) {
        const total = Math.max(0, Math.floor(seconds));
        const s = total % 60;
        return Math.floor(total / 60) + ":" + (s < 10 ? "0" : "") + s;
    }

    // MPRIS schickt keine laufenden Positions-Updates, Quickshell muss aktiv
    // nachfragen. Nur solange das Flyout zu sehen ist.
    Timer {
        interval: 500
        repeat: true
        running: root.flyoutVisible && root.mode === "media" && (root.player?.isPlaying ?? false)
        onTriggered: root.player?.positionChanged()
    }

    // Runder Icon-Button für die Mediensteuerung. Liegt über der
    // Zieh-MouseArea, Klicks hier verschieben das Flyout also nicht.
    // Inline-Components sehen die ids der Datei nicht, deshalb Signale statt
    // direktem Zugriff auf root.
    component MediaButton: Rectangle {
        id: button
        property string icon
        property int iconSize: 24
        property bool shown: true
        // Für Umschalter wie Shuffle und Wiederholen: an = Akzentfarbe
        property bool active: false
        signal activated
        signal hovered

        width: 36
        height: 36
        radius: 18
        color: buttonArea.containsMouse ? Theme.primaryHover : "transparent"
        opacity: shown ? 1 : 0.35

        DankIcon {
            anchors.centerIn: parent
            name: button.icon
            size: button.iconSize
            color: button.active ? Theme.primary : Theme.surfaceText
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: button.shown
            cursorShape: Qt.PointingHandCursor
            onEntered: button.hovered()
            onClicked: button.activated()
        }
    }

    function toggleShuffle() {
        if (root.player?.canControl && root.player.shuffleSupported)
            root.player.shuffle = !root.player.shuffle;
    }

    // Aus → ganze Playlist → nur dieser Song → aus (wie in Spotify)
    function cycleLoop() {
        if (!root.player?.canControl || !root.player.loopSupported)
            return;
        switch (root.player.loopState) {
        case MprisLoopState.None:
            root.player.loopState = MprisLoopState.Playlist;
            break;
        case MprisLoopState.Playlist:
            root.player.loopState = MprisLoopState.Track;
            break;
        default:
            root.player.loopState = MprisLoopState.None;
        }
    }

    function showFlyout(kind) {
        if ((kind === "media" && !root.mediaEnabled) || (kind === "lock" && !root.lockEnabled))
            return;
        root.mode = kind;
        root.flyoutVisible = true;
        hideTimer.restart();
    }

    function savePosition() {
        PluginService.savePluginData(root.pluginId, "posX", root.posX);
        PluginService.savePluginData(root.pluginId, "posY", root.posY);
    }

    Timer {
        id: hideTimer
        interval: root.durationSeconds * 1000
        // Nicht ausblenden, solange die Maus drauf ist oder gezogen wird
        onTriggered: {
            if (root.pointerInside)
                restart();
            else
                root.flyoutVisible = false;
        }
    }

    Connections {
        target: root.player
        ignoreUnknownSignals: true
        function onTrackTitleChanged() {
            root.showFlyout("media");
        }
        // Deckt auch Play/Pause über die Medientasten ab, da die nur den
        // Wiedergabestatus des Players ändern
        function onIsPlayingChanged() {
            root.showFlyout("media");
        }
    }

    // Lock Keys: Hyprland setzt die Tastatur-LEDs, deren Zustand steht in
    // /sys/class/leds/<input>::capslock usw. Sysfs meldet Änderungen nicht per
    // inotify, deshalb wird alle 200 ms neu gelesen (nur Dateizugriffe, kein
    // Prozessstart).
    readonly property var lockKinds: [
        { key: "capslock", label: "Caps Lock", icon: "keyboard_capslock" },
        { key: "numlock", label: "Num Lock", icon: "dialpad" },
        { key: "scrolllock", label: "Scroll Lock", icon: "swap_vert" }
    ]
    property var ledPaths: ({})
    property var lockStates: ({})
    property string lockLabel: ""
    property string lockIcon: ""
    property bool lockOn: false

    function readLockStates() {
        const views = { capslock: capsLed, numlock: numLed, scrolllock: scrollLed };
        const next = {};
        for (const kind of root.lockKinds) {
            const view = views[kind.key];
            if (!view.path)
                continue;
            view.reload();
            next[kind.key] = parseInt(view.text()) > 0;
            const previous = root.lockStates[kind.key];
            // Erster Lesevorgang zählt nicht als Änderung
            if (previous !== undefined && previous !== next[kind.key]) {
                root.lockLabel = kind.label;
                root.lockIcon = kind.icon;
                root.lockOn = next[kind.key];
                root.showFlyout("lock");
            }
        }
        root.lockStates = next;
    }

    FileView { id: capsLed; path: root.ledPaths.capslock ?? ""; blockLoading: true }
    FileView { id: numLed; path: root.ledPaths.numlock ?? ""; blockLoading: true }
    FileView { id: scrollLed; path: root.ledPaths.scrolllock ?? ""; blockLoading: true }

    Timer {
        interval: 200
        repeat: true
        running: Object.keys(root.ledPaths).length > 0
        onTriggered: root.readLockStates()
    }

    Component.onCompleted: {
        root.loadSettings();
        Proc.runCommand("mediaFlyouts.leds", ["sh", "-c", "for k in capslock numlock scrolllock; do p=$(ls -d /sys/class/leds/*::$k 2>/dev/null | head -1); [ -n \"$p\" ] && echo \"$k $p/brightness\"; done"], (stdout, exitCode) => {
            const paths = {};
            for (const line of stdout.trim().split("\n")) {
                const parts = line.split(" ");
                if (parts.length === 2)
                    paths[parts[0]] = parts[1];
            }
            if (Object.keys(paths).length === 0)
                console.warn("MediaFlyouts: keine Tastatur-LEDs unter /sys/class/leds gefunden, Lock-Keys-Flyout bleibt aus");
            root.ledPaths = paths;
        }, 0);
        console.info("MediaFlyouts: geladen");
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: flyoutWindow
            required property var modelData
            screen: modelData

            readonly property real maxX: screen.width - root.flyoutWidth
            readonly property real maxY: screen.height - root.flyoutHeight
            readonly property real currentX: root.posX < 0 ? maxX / 2 : Math.min(root.posX, maxX)
            readonly property real currentY: root.posY < 0 ? maxY - 80 : Math.min(root.posY, maxY)

            // Sichtbar bleiben, bis die Ausblend-Animation durch ist
            visible: root.flyoutVisible || card.opacity > 0
            color: "transparent"

            WlrLayershell.namespace: "dms:plugin:mediaFlyouts"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // Ziehen: Würde man das kleine Fenster bei jedem Mausevent über die
            // Margins verschieben, hinkt der Compositor hinterher und es ruckelt.
            // Deshalb wird das Fenster beim Ziehen bildschirmfüllend (durchsichtig)
            // und nur die Karte darin bewegt. Beim Loslassen schrumpft es wieder
            // auf Kartengröße an der neuen Position.
            property bool dragging: false
            // Erst wenn der Compositor die neue Größe wirklich übernommen hat,
            // liegt die Karte bei currentX/currentY statt bei 0/0
            readonly property bool expanded: width > root.flyoutWidth

            anchors {
                left: true
                top: true
                right: dragging
                bottom: dragging
            }

            WlrLayershell.margins {
                left: dragging ? 0 : flyoutWindow.currentX
                top: dragging ? 0 : flyoutWindow.currentY
            }

            implicitWidth: root.flyoutWidth
            implicitHeight: root.flyoutHeight

            Rectangle {
                id: card
                x: flyoutWindow.expanded ? flyoutWindow.currentX : 0
                y: flyoutWindow.expanded ? flyoutWindow.currentY : 0
                width: root.flyoutWidth
                height: root.flyoutHeight
                radius: Theme.cornerRadius
                color: Theme.surfaceContainer
                border.color: Theme.outline
                border.width: 1

                opacity: root.flyoutVisible ? 1 : 0
                scale: root.flyoutVisible ? 1 : 0.92
                Behavior on opacity {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: 220; easing.type: Easing.OutBack }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                    property real pressX: 0
                    property real pressY: 0

                    onEntered: root.pointerInside = true
                    onExited: root.pointerInside = pressed
                    onPressed: mouse => {
                        pressX = mouse.x;
                        pressY = mouse.y;
                        flyoutWindow.dragging = true;
                    }
                    // Die Karte bewegt sich synchron mit, mouse.x ist also immer
                    // relativ zur aktuellen Kartenposition
                    onPositionChanged: mouse => {
                        if (!pressed || !flyoutWindow.expanded)
                            return;
                        root.posX = Math.max(0, Math.min(card.x + mouse.x - pressX, flyoutWindow.maxX));
                        root.posY = Math.max(0, Math.min(card.y + mouse.y - pressY, flyoutWindow.maxY));
                    }
                    onReleased: {
                        flyoutWindow.dragging = false;
                        root.savePosition();
                        root.pointerInside = containsMouse;
                        hideTimer.restart();
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    visible: root.mode === "media"

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 80
                        height: 80
                        source: root.player?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        visible: source != ""
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 80 - controls.width - 24
                        spacing: 4

                        Text {
                            width: parent.width
                            text: root.player?.trackTitle || "Nichts läuft"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: root.player?.trackArtist || ""
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeMedium
                            elide: Text.ElideRight
                        }

                        // Fortschrittsbalken, nur wenn der Player Position und Länge liefert
                        Item {
                            width: parent.width
                            height: 14
                            visible: root.hasProgress

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 4
                                radius: 2
                                color: Theme.surfaceContainerHigh

                                Rectangle {
                                    width: parent.width * root.progress
                                    height: parent.height
                                    radius: 2
                                    color: Theme.primary
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            visible: root.hasProgress

                            Text {
                                width: parent.width / 2
                                text: root.formatTime(root.player?.position ?? 0)
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            Text {
                                width: parent.width / 2
                                horizontalAlignment: Text.AlignRight
                                text: root.formatTime(root.player?.length ?? 0)
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall
                            }
                        }
                    }

                    Row {
                        id: controls
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        MediaButton {
                            icon: "shuffle"
                            iconSize: 20
                            active: root.player?.shuffle ?? false
                            shown: (root.player?.canControl ?? false) && (root.player?.shuffleSupported ?? false)
                            onActivated: root.toggleShuffle()
                            // callLater, damit das onExited der Zieh-Fläche nicht danach drüberschreibt
                            onHovered: Qt.callLater(() => root.pointerInside = true)
                        }

                        MediaButton {
                            icon: "skip_previous"
                            shown: root.player?.canGoPrevious ?? false
                            onActivated: root.player?.previous()
                            // callLater, damit das onExited der Zieh-Fläche nicht danach drüberschreibt
                            onHovered: Qt.callLater(() => root.pointerInside = true)
                        }

                        MediaButton {
                            icon: root.player?.isPlaying ? "pause" : "play_arrow"
                            iconSize: 30
                            shown: root.player?.canTogglePlaying ?? false
                            onActivated: root.player?.togglePlaying()
                            // callLater, damit das onExited der Zieh-Fläche nicht danach drüberschreibt
                            onHovered: Qt.callLater(() => root.pointerInside = true)
                        }

                        MediaButton {
                            icon: "skip_next"
                            shown: root.player?.canGoNext ?? false
                            onActivated: root.player?.next()
                            // callLater, damit das onExited der Zieh-Fläche nicht danach drüberschreibt
                            onHovered: Qt.callLater(() => root.pointerInside = true)
                        }

                        MediaButton {
                            icon: root.player?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                            iconSize: 20
                            active: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                            shown: (root.player?.canControl ?? false) && (root.player?.loopSupported ?? false)
                            onActivated: root.cycleLoop()
                            // callLater, damit das onExited der Zieh-Fläche nicht danach drüberschreibt
                            onHovered: Qt.callLater(() => root.pointerInside = true)
                        }
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 16
                    visible: root.mode === "lock"

                    DankIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: root.lockIcon
                        size: 36
                        color: root.lockOn ? Theme.primary : Theme.surfaceVariantText
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.lockLabel + (root.lockOn ? " an" : " aus")
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }

}
