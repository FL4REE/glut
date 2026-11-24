import QtQuick
import qs.Common
import qs.Widgets

// Einfaches zweistufiges Kontextmenü (Hauptmenü + optionales Untermenü),
// im DMS-Farbschema (Theme-Singleton) gehalten.
Item {
    id: root
    anchors.fill: parent
    visible: false
    z: 1000

    property var items: []
    property real menuX: 0
    property real menuY: 0
    property var subItems: []
    property real subMenuX: 0
    property real subMenuY: 0
    property bool subMenuOpen: false
    // Eintrag im Hauptmenü, dessen Untermenü gerade offen ist
    property var activeSub: null
    // Theme-Vorschau (themectl): Daten des Eintrags, über dem die Maus gerade ist
    property var hoverPreview: null
    property real hoverY: 0

    // Untermenü-Einträge mit "Zurück" oben
    readonly property var displaySubItems: [
        { "text": "Zurück", "icon": "arrow_back", "back": true },
        { "separator": true }
    ].concat(subItems)

    function openAt(x, y) {
        menuX = x
        menuY = y
        subMenuOpen = false
        activeSub = null
        visible = true
        forceActiveFocus()
    }

    function closeMenu() {
        visible = false
        subMenuOpen = false
        activeSub = null
        hoverPreview = null
    }

    function openSub(entryData, entryYInColumn) {
        root.subItems = entryData.children
        root.activeSub = entryData
        root.subMenuX = mainPanel.x + mainPanel.width + 4
        root.subMenuY = mainPanel.y + mainColumn.y + entryYInColumn
        root.subMenuOpen = true
        root.hoverPreview = null
    }

    // Esc schließt (funktioniert nur, wenn das Widget Tastaturfokus hat -
    // siehe "acceptsKeyboardFocus" in DesktopContextMenu.qml)
    focus: visible
    Keys.onEscapePressed: (event) => { root.closeMenu(); event.accepted = true }

    // Klick außerhalb der Panels schließt das Menü wieder
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.closeMenu()
    }

    // Hauptmenü
    Rectangle {
        id: mainPanel
        x: Math.max(0, Math.min(root.menuX, root.width - width - 8))
        y: Math.max(0, Math.min(root.menuY, root.height - height - 8))
        width: 240
        radius: Theme.cornerRadius
        color: Theme.surfaceContainer
        border.color: Theme.outlineStrong
        border.width: 1
        height: mainColumn.implicitHeight + Theme.spacingS * 2

        Column {
            id: mainColumn
            width: parent.width
            y: Theme.spacingS
            spacing: 2

            Repeater {
                model: root.items

                Item {
                    id: mainEntry
                    required property var modelData
                    width: mainColumn.width
                    height: modelData.separator ? 9 : 40

                    // Trennlinie zwischen Gruppen
                    Rectangle {
                        visible: mainEntry.modelData.separator === true
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM
                        height: 1
                        color: Theme.outlineStrong
                        opacity: 0.5
                    }

                    Rectangle {
                        id: mainRow
                        visible: !mainEntry.modelData.separator
                        anchors.fill: parent
                        color: (rowMouse.containsMouse || (root.subMenuOpen && root.activeSub === mainEntry.modelData)) ? Theme.surfaceContainerHigh : "transparent"
                        radius: Theme.cornerRadius / 2

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            DankIcon {
                                name: mainEntry.modelData.icon || ""
                                size: 20
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: mainEntry.modelData.text || ""
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                                width: 150
                            }
                        }

                        DankIcon {
                            name: "chevron_right"
                            size: 16
                            color: Theme.surfaceVariantText
                            visible: !!mainEntry.modelData.children
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingM
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (mainEntry.modelData.children) {
                                    root.openSub(mainEntry.modelData, mainEntry.y)
                                } else if (mainEntry.modelData.action) {
                                    mainEntry.modelData.action()
                                    root.closeMenu()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Untermenü rechts neben dem Hauptmenü, per Klick geöffnet
    Rectangle {
        id: subPanel
        visible: root.subMenuOpen
        x: Math.max(0, Math.min(root.subMenuX, root.width - width - 8))
        y: Math.max(0, Math.min(root.subMenuY, root.height - height - 8))
        width: 220
        radius: Theme.cornerRadius
        color: Theme.surfaceContainer
        border.color: Theme.outlineStrong
        border.width: 1
        height: subColumn.implicitHeight + Theme.spacingS * 2

        Column {
            id: subColumn
            width: parent.width
            y: Theme.spacingS
            spacing: 2

            Repeater {
                model: root.displaySubItems

                Item {
                    id: subEntry
                    required property var modelData
                    width: subColumn.width
                    height: modelData.separator ? 9 : 36

                    Rectangle {
                        visible: subEntry.modelData.separator === true
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM
                        height: 1
                        color: Theme.outlineStrong
                        opacity: 0.5
                    }

                    Rectangle {
                        visible: !subEntry.modelData.separator
                        anchors.fill: parent
                        color: subRowMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                        radius: Theme.cornerRadius / 2

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            DankIcon {
                                name: subEntry.modelData.icon || ""
                                size: 18
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: subEntry.modelData.text || ""
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: subRowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onContainsMouseChanged: {
                                if (containsMouse && subEntry.modelData.preview) {
                                    root.hoverPreview = subEntry.modelData.preview
                                    root.hoverY = subColumn.y + subEntry.y
                                } else if (!containsMouse && root.hoverPreview === subEntry.modelData.preview) {
                                    root.hoverPreview = null
                                }
                            }
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (subEntry.modelData.back) {
                                    root.subMenuOpen = false
                                    root.activeSub = null
                                    root.hoverPreview = null
                                } else if (subEntry.modelData.action) {
                                    subEntry.modelData.action()
                                    root.closeMenu()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Theme-Vorschau neben dem Untermenü: Wallpaper, Mini-Fenster in den
    // Theme-Farben und die 16 Terminalfarben
    Rectangle {
        id: previewPanel
        readonly property var p: root.hoverPreview
        visible: root.subMenuOpen && p !== null
        readonly property bool fitsRight: subPanel.x + subPanel.width + 8 + width <= root.width
        x: fitsRight ? subPanel.x + subPanel.width + 8 : subPanel.x - width - 8
        y: Math.max(0, Math.min(subPanel.y + root.hoverY - 40, root.height - height - 8))
        width: 280
        height: previewColumn.implicitHeight + Theme.spacingS * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainer
        border.color: Theme.outlineStrong
        border.width: 1
        clip: true

        Column {
            id: previewColumn
            x: Theme.spacingS
            y: Theme.spacingS
            width: parent.width - Theme.spacingS * 2
            spacing: Theme.spacingS

            // Wallpaper mit kleinem "Fenster" in den Theme-Farben darüber
            Rectangle {
                width: parent.width
                height: 150
                radius: Theme.cornerRadius / 2
                clip: true
                color: previewPanel.p ? previewPanel.p.background : "transparent"

                Image {
                    anchors.fill: parent
                    visible: !!(previewPanel.p && previewPanel.p.wallpaper)
                    source: previewPanel.p && previewPanel.p.wallpaper ? "file://" + previewPanel.p.wallpaper : ""
                    sourceSize.width: 560
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.62
                    height: parent.height * 0.55
                    radius: 6
                    color: previewPanel.p ? previewPanel.p.background : "black"
                    border.color: previewPanel.p ? previewPanel.p.accent : "white"
                    border.width: 2

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 5
                        Repeater {
                            model: [[1, 0.55], [4, 0.75], [2, 0.4], [5, 0.65]]
                            Rectangle {
                                required property var modelData
                                height: 5
                                radius: 2
                                width: parent.width * modelData[1]
                                color: previewPanel.p && previewPanel.p.colors ? previewPanel.p.colors[modelData[0]] : "gray"
                            }
                        }
                    }
                }
            }

            StyledText {
                text: previewPanel.p ? previewPanel.p.name + "  ·  " + previewPanel.p.mode : ""
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
            }

            // 16 Terminalfarben in zwei Reihen
            Grid {
                columns: 8
                spacing: 3
                Repeater {
                    model: previewPanel.p && previewPanel.p.colors ? previewPanel.p.colors : []
                    Rectangle {
                        required property var modelData
                        width: (previewColumn.width - 7 * 3) / 8
                        height: 14
                        radius: 3
                        color: modelData
                    }
                }
            }
        }
    }
}
