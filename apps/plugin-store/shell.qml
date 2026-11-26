// Plugin Store fuer glut (Quickshell-Fenster).
// Start: plugin-store   (oder direkt: qs -p apps/plugin-store/shell.qml)
//
// Zeigt DMS-Plugins (installierbar) und Omarchy-Plugins (portierbar per Claude Code)
// in einem Katalog. Die Daten liefert `plugin-store catalog` als JSON.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    id: shell

    readonly property string cli: Quickshell.env("PLUGIN_STORE") || (Quickshell.env("HOME") + "/.local/bin/plugin-store")
    readonly property string themectl: Quickshell.env("THEMECTL") || (Quickshell.env("HOME") + "/.local/bin/themectl")

    property var items: []
    property var errors: []
    property bool loading: true
    property string status: ""
    property string busyId: ""
    property var selected: null

    // ---------- Farben vom aktiven Theme ----------
    property var theme: null
    readonly property color bg: theme ? theme.background : "#1b1e28"
    readonly property color fg: theme ? theme.foreground : "#e4f0fb"
    readonly property color accent: theme ? theme.accent : "#5de4c7"
    readonly property color surface: Qt.tint(bg, Qt.rgba(fg.r, fg.g, fg.b, 0.06))
    readonly property color surfaceHigh: Qt.tint(bg, Qt.rgba(fg.r, fg.g, fg.b, 0.12))
    readonly property color outline: Qt.tint(bg, Qt.rgba(fg.r, fg.g, fg.b, 0.22))
    readonly property color muted: Qt.tint(fg, Qt.rgba(bg.r, bg.g, bg.b, 0.4))
    readonly property color omarchyColor: "#e8a33d"
    readonly property color dmsColor: "#6aa7ff"
    readonly property color localColor: "#b48cf2"
    function srcColor(i) { return !i ? dmsColor : i.src === "omarchy" ? omarchyColor : i.src === "local" ? localColor : dmsColor }
    function srcLabel(i) { return !i ? "" : i.src === "omarchy" ? "Omarchy" : i.src === "local" ? "Lokal" : "DMS" }

    function contrastOn(c) {
        const l = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
        return l > 0.55 ? "#111111" : "#ffffff"
    }

    Process {
        command: [shell.themectl, "list", "--json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { shell.theme = JSON.parse(this.text).find(t => t.current) || null } catch (e) {}
            }
        }
    }

    // ---------- Katalog ----------
    Process {
        id: catalogProc
        stdout: StdioCollector {
            onStreamFinished: {
                shell.loading = false
                try {
                    const d = JSON.parse(this.text)
                    shell.items = d.items || []
                    shell.errors = d.errors || []
                    if (shell.selected)
                        shell.selected = shell.items.find(i => i.src === shell.selected.src && i.id === shell.selected.id) || null
                } catch (e) {
                    shell.errors = ["Katalog konnte nicht gelesen werden"]
                }
            }
        }
    }
    function load(refresh) {
        if (catalogProc.running) return
        shell.loading = true
        catalogProc.command = [shell.cli, "catalog"].concat(refresh ? ["--refresh"] : [])
        catalogProc.running = true
    }

    // ---------- Aktionen ----------
    Process {
        id: actionProc
        stdout: StdioCollector { id: actionOut }
        onExited: (code) => {
            const msg = actionOut.text.trim().split("\n").pop()
            shell.status = (code === 0 ? "✓ " : "✗ ") + (msg || (code === 0 ? "Fertig" : "Fehlgeschlagen"))
            shell.busyId = ""
            shell.load(false)
        }
    }
    function act(verb, item) {
        if (actionProc.running) return
        shell.busyId = item.src + ":" + item.id
        shell.status = { install: "Installiere ", uninstall: "Entferne ", port: "Starte Portierung für ",
                         enable: "Schalte ein: ", disable: "Schalte aus: " }[verb] + item.name + " …"
        actionProc.command = [shell.cli, verb, item.id]
        actionProc.running = true
    }

    // ---------- Filter ----------
    property int tab: 0            // 0 Alle, 1 DMS, 2 Omarchy, 3 Installiert
    property string category: ""
    property int sortMode: 0       // 0 Empfohlen, 1 Name, 2 Sterne

    readonly property var counts: ({
        all: items.length,
        dms: items.filter(i => i.src === "dms").length,
        omarchy: items.filter(i => i.src === "omarchy").length,
        installed: items.filter(i => i.installed || i.ported).length
    })
    readonly property var categories: {
        const s = {}
        for (const i of items) s[i.cat] = true
        return Object.keys(s).sort()
    }
    readonly property var filtered: {
        const q = searchField.text.trim().toLowerCase()
        const words = q.length ? q.split(/\s+/) : []
        let list = items.filter(i => {
            if (tab === 1 && i.src !== "dms") return false
            if (tab === 2 && i.src !== "omarchy") return false
            if (tab === 3 && !(i.installed || i.ported)) return false
            if (category && i.cat !== category) return false
            if (!words.length) return true
            const hay = (i.name + " " + i.id + " " + i.author + " " + i.desc + " " + i.tags.join(" ") + " " + i.kind).toLowerCase()
            return words.every(w => hay.indexOf(w) >= 0)
        })
        const rank = i => (i.installed ? 4 : 0) + (i.src === "dms" ? 2 : 0) + (i.verified ? 1 : 0)
        if (sortMode === 1) list.sort((a, b) => a.name.localeCompare(b.name))
        else if (sortMode === 2) list.sort((a, b) => b.stars - a.stars)
        else list.sort((a, b) => rank(b) - rank(a) || b.stars - a.stars || a.name.localeCompare(b.name))
        return list
    }

    Component.onCompleted: {
        load(false)
        // plugin-store [dms|omarchy|installiert] [suchbegriff]
        const t = ["alle", "dms", "omarchy", "installiert"].indexOf((Quickshell.env("PLUGIN_STORE_TAB") || "").toLowerCase())
        if (t > 0) tab = t
        const q = Quickshell.env("PLUGIN_STORE_QUERY")
        if (q) searchField.text = q
    }

    // ---------- kleine Bausteine ----------
    component Pill: Rectangle {
        id: pill
        property string label: ""
        property color tint: shell.accent
        property bool filled: false
        implicitWidth: pillText.implicitWidth + 14
        implicitHeight: 20
        radius: 10
        color: filled ? tint : Qt.rgba(tint.r, tint.g, tint.b, 0.18)
        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.label
            color: pill.filled ? shell.contrastOn(pill.tint) : pill.tint
            font.pixelSize: 11
            font.bold: true
        }
    }

    component Btn: Rectangle {
        id: btn
        property string label: ""
        property bool primary: false
        property bool enabledBtn: true
        signal clicked()
        implicitWidth: btnText.implicitWidth + 26
        implicitHeight: 32
        radius: 16
        opacity: enabledBtn ? 1 : 0.45
        color: primary ? (btnMouse.containsMouse ? Qt.lighter(shell.accent, 1.12) : shell.accent)
                       : (btnMouse.containsMouse ? shell.surfaceHigh : shell.surface)
        border.color: primary ? "transparent" : shell.outline
        Text {
            id: btnText
            anchors.centerIn: parent
            text: btn.label
            color: btn.primary ? shell.contrastOn(shell.accent) : shell.fg
            font.pixelSize: 13
            font.bold: btn.primary
        }
        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: btn.enabledBtn ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (btn.enabledBtn) btn.clicked()
        }
    }

    component ThemedCombo: ComboBox {
        id: combo
        implicitHeight: 36
        font.pixelSize: 13
        background: Rectangle {
            radius: 18
            color: combo.hovered ? shell.surfaceHigh : shell.surface
            border.color: combo.activeFocus ? shell.accent : shell.outline
        }
        contentItem: Text {
            leftPadding: 14
            rightPadding: 28
            text: combo.displayText
            color: shell.fg
            font: combo.font
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        indicator: Text {
            x: combo.width - width - 12
            anchors.verticalCenter: parent.verticalCenter
            text: "▾"
            color: shell.muted
            font.pixelSize: 13
        }
        delegate: ItemDelegate {
            required property int index
            required property var modelData
            width: combo.width
            highlighted: combo.highlightedIndex === index
            contentItem: Text { text: modelData; color: shell.fg; font.pixelSize: 13; elide: Text.ElideRight }
            background: Rectangle { color: highlighted ? shell.surfaceHigh : shell.bg }
        }
        popup: Popup {
            y: combo.height + 4
            width: combo.width
            implicitHeight: Math.min(contentItem.implicitHeight + 8, 360)
            padding: 4
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: combo.popup.visible ? combo.delegateModel : null
                currentIndex: combo.highlightedIndex
                ScrollBar.vertical: ScrollBar {}
            }
            background: Rectangle { radius: 12; color: shell.bg; border.color: shell.outline }
        }
    }

    component Preview: Rectangle {
        id: prev
        property var item: null
        property string url: ""
        color: shell.surfaceHigh
        clip: true
        Image {
            id: img
            anchors.fill: parent
            source: prev.url
            asynchronous: true
            cache: true
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 720
        }
        Text {
            anchors.centerIn: parent
            visible: img.status !== Image.Ready
            text: prev.item ? prev.item.name.split(/[\s.\-_]+/).filter(w => w).slice(0, 2).map(w => w[0].toUpperCase()).join("") : ""
            color: shell.srcColor(prev.item)
            font.pixelSize: 34
            font.bold: true
            opacity: 0.7
        }
    }

    function actionsFor(i) {
        if (!i) return []
        if (i.src === "omarchy")
            return [{ verb: "port", label: i.ported ? "Portierung fortsetzen" : "Für DMS portieren", primary: !i.ported }]
        const a = []
        if (!i.installed) a.push({ verb: "install", label: "Installieren", primary: true })
        else {
            a.push(i.enabled ? { verb: "disable", label: "Ausschalten", primary: false }
                             : { verb: "enable", label: "Einschalten", primary: true })
            if (i.src === "dms") a.push({ verb: "uninstall", label: "Entfernen", primary: false })
        }
        return a
    }

    FloatingWindow {
        id: win
        visible: true
        title: "Plugin Store"
        implicitWidth: 1320
        implicitHeight: 860
        color: shell.bg
        onVisibleChanged: if (!visible) Qt.quit()

        Shortcut { sequence: "Escape"; onActivated: shell.selected ? shell.selected = null : Qt.quit() }
        Shortcut { sequence: "Ctrl+F"; onActivated: searchField.forceActiveFocus() }
        Shortcut { sequence: "Ctrl+R"; onActivated: shell.load(true) }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // ---------- Kopfzeile ----------
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [["Alle", "all"], ["DMS", "dms"], ["Omarchy", "omarchy"], ["Installiert", "installed"]]
                    Rectangle {
                        required property int index
                        required property var modelData
                        readonly property bool active: shell.tab === index
                        implicitWidth: tabText.implicitWidth + 28
                        implicitHeight: 36
                        radius: 18
                        color: active ? shell.accent : (tabMouse.containsMouse ? shell.surfaceHigh : shell.surface)
                        Text {
                            id: tabText
                            anchors.centerIn: parent
                            text: parent.modelData[0] + "  " + (shell.counts[parent.modelData[1]] || 0)
                            color: parent.active ? shell.contrastOn(shell.accent) : shell.fg
                            font.pixelSize: 14
                            font.bold: parent.active
                        }
                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: shell.tab = parent.index
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                ThemedCombo {
                    id: catBox
                    Layout.preferredWidth: 190
                    model: ["Alle Kategorien"].concat(shell.categories)
                    onActivated: (i) => shell.category = i === 0 ? "" : shell.categories[i - 1]
                }
                ThemedCombo {
                    Layout.preferredWidth: 150
                    model: ["Empfohlen", "Name", "Beliebteste"]
                    onActivated: (i) => shell.sortMode = i
                }

                Rectangle {
                    Layout.preferredWidth: 320
                    implicitHeight: 36
                    radius: 18
                    color: shell.surface
                    border.color: searchField.activeFocus ? shell.accent : shell.outline
                    TextField {
                        id: searchField
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        background: null
                        color: shell.fg
                        placeholderText: "Plugins suchen …"
                        placeholderTextColor: shell.muted
                        font.pixelSize: 14
                        verticalAlignment: TextInput.AlignVCenter
                        Component.onCompleted: forceActiveFocus()
                        onAccepted: if (shell.filtered.length) shell.selected = shell.filtered[0]
                    }
                }
            }

            // Hinweis zu Omarchy
            Rectangle {
                Layout.fillWidth: true
                visible: shell.tab === 2
                implicitHeight: hint.implicitHeight + 16
                radius: 10
                color: Qt.rgba(shell.omarchyColor.r, shell.omarchyColor.g, shell.omarchyColor.b, 0.12)
                Text {
                    id: hint
                    anchors.fill: parent
                    anchors.margins: 8
                    anchors.leftMargin: 14
                    wrapMode: Text.Wrap
                    color: shell.fg
                    font.pixelSize: 13
                    text: "Omarchy-Plugins sind für Omarchys eigene Shell gebaut und laufen in DMS erst nach einer Portierung. "
                        + "„Für DMS portieren“ lädt den Code nach ~/Projekte/dms-ports/ und startet dort Claude Code, das eine DMS-Version baut."
                }
            }

            // ---------- Inhalt ----------
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14

                GridView {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    readonly property int cols: Math.max(1, Math.floor(width / 300))
                    cellWidth: Math.floor(width / cols)
                    cellHeight: 300
                    ScrollBar.vertical: ScrollBar {}
                    model: shell.filtered
                    cacheBuffer: 600

                    delegate: Item {
                        id: cell
                        required property var modelData
                        readonly property var it: modelData
                        readonly property bool isSel: shell.selected && shell.selected.src === it.src && shell.selected.id === it.id
                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 6
                            radius: 12
                            color: cardMouse.containsMouse ? shell.surfaceHigh : shell.surface
                            border.width: cell.isSel ? 2 : 1
                            border.color: cell.isSel ? shell.accent : shell.outline
                            clip: true

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: shell.selected = cell.it
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 0

                                Preview {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 150
                                    item: cell.it
                                    url: cell.it.thumb
                                    radius: 12
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.margins: 12
                                    spacing: 6

                                    RowLayout {
                                        spacing: 6
                                        Pill { label: shell.srcLabel(cell.it); tint: shell.srcColor(cell.it) }
                                        Pill { visible: cell.it.verified; label: "✓ geprüft"; tint: shell.accent }
                                        Pill { visible: cell.it.installed; label: cell.it.enabled ? "aktiv" : "aus"; tint: cell.it.enabled ? shell.accent : shell.muted; filled: cell.it.enabled }
                                        Pill { visible: cell.it.ported; label: "portiert"; tint: shell.omarchyColor; filled: true }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            visible: cell.it.stars > 0
                                            text: "★ " + cell.it.stars
                                            color: shell.muted
                                            font.pixelSize: 12
                                        }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: cell.it.name
                                        color: shell.fg
                                        font.pixelSize: 15
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        text: cell.it.desc
                                        color: shell.muted
                                        font.pixelSize: 12
                                        wrapMode: Text.Wrap
                                        elide: Text.ElideRight
                                        maximumLineCount: 3
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: grid.count === 0
                        text: shell.loading ? "Lade Kataloge …" : (shell.errors.length ? shell.errors.join("\n") : "Nichts gefunden.")
                        color: shell.muted
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // ---------- Details ----------
                Rectangle {
                    id: detail
                    visible: shell.selected !== null
                    Layout.preferredWidth: 420
                    Layout.fillHeight: true
                    radius: 14
                    color: shell.surface
                    border.color: shell.outline
                    clip: true
                    readonly property var it: shell.selected

                    Flickable {
                        anchors.fill: parent
                        contentHeight: detailCol.implicitHeight + 24
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {}

                        ColumnLayout {
                            id: detailCol
                            width: parent.width
                            spacing: 10

                            Preview {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 236
                                item: detail.it
                                url: detail.it ? detail.it.image : ""
                                radius: 14
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 16
                                Layout.rightMargin: 16
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        Layout.fillWidth: true
                                        text: detail.it ? detail.it.name : ""
                                        color: shell.fg
                                        font.pixelSize: 20
                                        font.bold: true
                                        wrapMode: Text.Wrap
                                    }
                                    Text {
                                        text: "✕"
                                        color: shell.muted
                                        font.pixelSize: 18
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.selected = null }
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: detail.it ? "von " + detail.it.author + "  ·  " + detail.it.cat + (detail.it.kind ? "  ·  " + detail.it.kind : "") : ""
                                    color: shell.muted
                                    font.pixelSize: 12
                                    wrapMode: Text.Wrap
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: detail.it ? detail.it.desc : ""
                                    color: shell.fg
                                    font.pixelSize: 14
                                    wrapMode: Text.Wrap
                                }
                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Repeater {
                                        model: detail.it ? detail.it.tags : []
                                        Pill { required property string modelData; label: "#" + modelData; tint: shell.muted }
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: detail.it && detail.it.deps.length > 0
                                    text: detail.it ? "Benötigt: " + detail.it.deps.join(", ") : ""
                                    color: shell.muted
                                    font.pixelSize: 12
                                    wrapMode: Text.Wrap
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: detail.it && detail.it.src === "omarchy"
                                    text: detail.it && detail.it.ported
                                          ? "Portierung liegt in ~/Projekte/dms-ports/" + detail.it.id
                                          : "Läuft nicht direkt in DMS: Omarchy-Plugin, muss portiert werden."
                                    color: shell.omarchyColor
                                    font.pixelSize: 12
                                    wrapMode: Text.Wrap
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 6
                                    spacing: 8
                                    Repeater {
                                        model: shell.actionsFor(detail.it)
                                        Btn {
                                            required property var modelData
                                            label: shell.busyId === (detail.it.src + ":" + detail.it.id) ? "…" : modelData.label
                                            primary: modelData.primary
                                            enabledBtn: shell.busyId === ""
                                            onClicked: shell.act(modelData.verb, detail.it)
                                        }
                                    }
                                    Btn {
                                        visible: detail.it && detail.it.repo !== ""
                                        label: "Repo öffnen"
                                        onClicked: Qt.openUrlExternally(detail.it.repo)
                                    }
                                    Btn {
                                        visible: detail.it && !!detail.it.path
                                        label: "Ordner öffnen"
                                        onClicked: Qt.openUrlExternally("file://" + detail.it.path)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---------- Statuszeile ----------
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: shell.status || (shell.loading ? "Lade Kataloge …" : shell.filtered.length + " Plugins")
                    color: shell.muted
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                Text {
                    text: "Strg+F suchen  ·  Strg+R Kataloge neu laden  ·  Esc schließen"
                    color: shell.muted
                    font.pixelSize: 12
                }
            }
        }
    }
}
