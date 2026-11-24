import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "mediaFlyouts"

    StyledText {
        width: parent.width
        text: "Media Flyouts"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Flyouts im FluentFlyout-Stil, die auch über Vollbild-Apps erscheinen. Das Flyout lässt sich mit der linken Maustaste frei verschieben. Wenn du die eingebauten DMS-OSDs für Medien und Caps Lock abschaltest (Settings → OSD), kommt nichts doppelt."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    ToggleSetting {
        settingKey: "mediaEnabled"
        label: "Musik-Flyout"
        description: "Bei Songwechsel und Play/Pause anzeigen (auch über die Medientasten)"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "lockEnabled"
        label: "Lock-Keys-Flyout"
        description: "Bei Caps Lock, Num Lock und Scroll Lock anzeigen"
        defaultValue: true
    }

    ListSettingWithInput {
        settingKey: "excludedPlayers"
        label: "Ausgeschlossene Player"
        description: "Für diese Player erscheint kein Musik-Flyout. Ein Teil des Namens reicht, z.B. 'helium' oder 'firefox'. Helium meldet sich teils als 'chromium', deshalb stehen beide drin."
        defaultValue: [
            { name: "helium" },
            { name: "chromium" }
        ]
        fields: [
            { id: "name", label: "Player", placeholder: "z.B. helium", width: 220, required: true }
        ]
    }

    SliderSetting {
        settingKey: "durationSeconds"
        label: "Anzeigedauer"
        description: "Wie lange das Flyout sichtbar bleibt. Solange die Maus drauf ist, bleibt es offen."
        defaultValue: 4
        minimum: 2
        maximum: 10
        unit: "s"
    }

    Rectangle {
        width: resetLabel.implicitWidth + Theme.spacingL * 2
        height: 36
        radius: Theme.cornerRadius
        color: resetArea.containsMouse ? Theme.primaryHover : Theme.surfaceContainerHigh

        StyledText {
            id: resetLabel
            anchors.centerIn: parent
            text: "Position zurücksetzen"
            color: Theme.surfaceText
        }

        MouseArea {
            id: resetArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.saveValue("posX", -1);
                root.saveValue("posY", -1);
            }
        }
    }
}
