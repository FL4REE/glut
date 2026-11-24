import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "fussball-ticker"

    PluginGlobalVar { id: liveMatchesVar; varName: "liveMatches"; defaultValue: ({}) }
    PluginGlobalVar { id: lastPollVar; varName: "lastPollTimestamp"; defaultValue: 0 }

    readonly property var liveMatches: liveMatchesVar.value
    readonly property var liveMatchIds: Object.keys(root.liveMatches)
    readonly property bool hasLiveMatch: root.liveMatchIds.length > 0
    readonly property var primaryMatch: root.hasLiveMatch ? root.liveMatches[root.liveMatchIds[0]] : null

    function statusLabel(shortCode) {
        switch (shortCode) {
        case "1H": return "1. HZ";
        case "2H": return "2. HZ";
        case "HT": return "Pause";
        case "FT": case "AET": case "PEN": return "Abgepfiffen";
        default: return shortCode || "";
        }
    }

    horizontalBarPill: Component {
        StyledRect {
            width: content.implicitWidth + Theme.spacingM * 2
            height: parent.widgetThickness
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Row {
                id: content
                anchors.centerIn: parent
                spacing: Theme.spacingXS

                DankIcon {
                    name: "sports_soccer"
                    size: root.iconSize
                    color: root.hasLiveMatch ? Theme.primary : Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    visible: root.hasLiveMatch
                    text: root.hasLiveMatch ? (root.primaryMatch.goalsHome + ":" + root.primaryMatch.goalsAway) : ""
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    visible: root.hasLiveMatch
                    text: root.hasLiveMatch ? (root.primaryMatch.minute + "'") : ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    verticalBarPill: Component {
        StyledRect {
            width: parent.widgetThickness
            height: content.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Column {
                id: content
                anchors.centerIn: parent
                spacing: Theme.spacingXS

                DankIcon {
                    name: "sports_soccer"
                    size: root.iconSize
                    color: root.hasLiveMatch ? Theme.primary : Theme.surfaceText
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                StyledText {
                    visible: root.hasLiveMatch
                    text: root.hasLiveMatch ? (root.primaryMatch.goalsHome + ":" + root.primaryMatch.goalsAway) : ""
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: "Fußball Ticker"
            detailsText: "Hansa Rostock · BVB · Bundesliga · Nationalmannschaft"
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingL

                Column {
                    visible: root.hasLiveMatch
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: "Live"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    Repeater {
                        model: root.liveMatchIds
                        StyledRect {
                            required property var modelData
                            readonly property var match: root.liveMatches[modelData]
                            width: parent.width
                            height: 52
                            radius: Theme.cornerRadius
                            color: Theme.surfaceContainerHigh

                            Column {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Theme.spacingM

                                StyledText {
                                    text: match ? (match.home + " " + match.goalsHome + ":" + match.goalsAway + " " + match.away) : ""
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                }
                                StyledText {
                                    text: match ? match.league : ""
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }
                            }

                            StyledText {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.rightMargin: Theme.spacingM
                                text: match ? root.statusLabel(match.statusShort) + (match.statusShort === "1H" || match.statusShort === "2H" ? " · " + match.minute + "'" : "") : ""
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }
                    }
                }

                Column {
                    visible: !root.hasLiveMatch
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: "Gerade läuft kein verfolgtes Spiel"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }
                    StyledText {
                        text: "Hinweis: API-Football's Free-Tier liefert keine Spielpläne oder aktuellen Tabellen, nur Live-Daten während ein Spiel läuft. Sobald Hansa Rostock, BVB, ein anderes Bundesliga-Team oder die Nationalmannschaft spielt, taucht es hier automatisch auf."
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }
        }
    }

    popoutWidth: 380
    popoutHeight: 320
}
