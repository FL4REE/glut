import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "desktopContextMenu"

    StyledText {
        width: parent.width
        text: "Desktop-Kontextmenü"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Klick auf eine freie Stelle des Desktops öffnet das Menü."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    ToggleSetting {
        settingKey: "useLeftClick"
        label: "Linksklick statt Rechtsklick"
        description: "Standard: an. Rechtsklick ist in DMS fest fürs Verschieben/Skalieren von Desktop-Widgets belegt"
        defaultValue: true
    }

    StringSetting {
        settingKey: "terminalCmd"
        label: "Terminal-Befehl"
        description: "Programm, das beim Klick auf 'Terminal' gestartet wird"
        placeholder: "ghostty"
        defaultValue: "ghostty"
    }
}
