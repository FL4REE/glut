import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// RunCat - laufende Katze in der Bar, Lauftempo folgt der CPU-Last.
//
// Ports das Konzept von https://github.com/bzglve/runcat-text (Python-Skript
// fuer Waybar/Polybar, seit 08/2026 archiviert) als natives DMS-Widget, weil
// Erik DankMaterialShell statt Waybar nutzt. Nutzt dieselbe runcat.ttf-Font
// (5 Lauf-Frames im Private-Use-Bereich U+E900-U+E904) und dieselbe
// FPS-Kurve (linear zwischen fps_l und fps_h nach CPU-Prozent), aber liest
// /proc/stat selbst aus statt sich auf das Skript zu verlassen.
PluginComponent {
    id: root

    layerNamespacePlugin: "runcat"

    FontLoader {
        id: runcatFont
        source: Qt.resolvedUrl("runcat.ttf")
    }

    readonly property var frames: ["", "", "", "", ""]
    property int frameIndex: 0

    property int cpuPercent: 0
    property var perCoreUsage: []

    property bool showPercent: PluginService.loadPluginData(root.pluginId, "showPercent", true)

    // Rohwerte aus /proc/stat fuer die Delta-Berechnung zwischen zwei Samples
    property real prevTotal: 0
    property real prevIdle: 0
    property var prevCoreTotal: ({})
    property var prevCoreIdle: ({})

    readonly property int fpsLow: 6
    readonly property int fpsHigh: 90
    readonly property real sampleRate: 100

    function frameIntervalMs(percent) {
        const fpsDelta = (1 / root.fpsLow - 1 / root.fpsHigh) / root.sampleRate;
        const seconds = Math.max(1 / root.fpsHigh, 1 / root.fpsLow - fpsDelta * percent);
        return seconds * 1000;
    }

    function sampleCpu() {
        Proc.runCommand("runCat.stat", ["cat", "/proc/stat"], function (stdout, exitCode) {
            if (exitCode !== 0 || !stdout)
                return;

            const lines = stdout.split("\n");
            const perCore = [];

            for (const line of lines) {
                if (!line.startsWith("cpu"))
                    continue;

                const parts = line.trim().split(/\s+/);
                const label = parts[0];
                const nums = parts.slice(1).map(Number);
                if (nums.length < 4)
                    continue;

                const idle = nums[3] + (nums[4] || 0);
                const total = nums.reduce((a, b) => a + b, 0);

                if (label === "cpu") {
                    const totalDiff = total - root.prevTotal;
                    const idleDiff = idle - root.prevIdle;
                    if (root.prevTotal > 0 && totalDiff > 0)
                        root.cpuPercent = Math.round((1 - idleDiff / totalDiff) * 100);
                    root.prevTotal = total;
                    root.prevIdle = idle;
                } else {
                    const prevT = root.prevCoreTotal[label] || 0;
                    const prevI = root.prevCoreIdle[label] || 0;
                    const totalDiff = total - prevT;
                    const idleDiff = idle - prevI;
                    perCore.push(prevT > 0 && totalDiff > 0 ? Math.round((1 - idleDiff / totalDiff) * 100) : 0);
                    root.prevCoreTotal[label] = total;
                    root.prevCoreIdle[label] = idle;
                }
            }

            root.perCoreUsage = perCore;
        }, 0);
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sampleCpu()
    }

    Timer {
        id: animTimer
        running: true
        repeat: true
        interval: root.frameIntervalMs(0)
        onTriggered: {
            root.frameIndex = (root.frameIndex + 1) % root.frames.length;
            interval = root.frameIntervalMs(root.cpuPercent);
        }
    }

    // Kein eigener Hintergrund/Rectangle hier: die Bar (BasePill) misst die
    // Pill-Groesse ueber implicitWidth/implicitHeight des geladenen Items und
    // zeichnet Hintergrund + Standard-Padding selbst. Row/Column liefern
    // implicitWidth/Height automatisch aus ihren Kindern; ein Rectangle
    // wuerde das nicht tun (implicitWidth waere 0), egal was man an width:
    // dran schreibt - deshalb bewusst kein StyledRect-Wrapper mehr.
    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            Item {
                width: Theme.spacingM
                height: 1
            }

            Text {
                text: root.frames[root.frameIndex]
                font.family: runcatFont.name
                font.pixelSize: root.iconSize
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                width: Theme.spacingM
                height: 1
            }

            StyledText {
                visible: root.showPercent
                text: root.cpuPercent + "%"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingS

            Item {
                width: 1
                height: Theme.spacingM
            }

            Text {
                text: root.frames[root.frameIndex]
                font.family: runcatFont.name
                font.pixelSize: root.iconSize
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Item {
                width: 1
                height: Theme.spacingM
            }

            StyledText {
                visible: root.showPercent
                text: root.cpuPercent + "%"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: "RunCat"
            detailsText: "Gesamtlast: " + root.cpuPercent + "%"
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: root.perCoreUsage
                    StyledRect {
                        required property int index
                        required property var modelData
                        width: parent.width
                        height: 28
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh

                        StyledRect {
                            width: parent.width * Math.min(100, modelData) / 100
                            height: parent.height
                            radius: Theme.cornerRadius
                            color: Theme.primary
                            opacity: 0.35
                        }

                        StyledText {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Theme.spacingM
                            text: "Core " + index
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        StyledText {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: Theme.spacingM
                            text: modelData + "%"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 320
    popoutHeight: Math.min(400, 80 + root.perCoreUsage.length * 34)
}
