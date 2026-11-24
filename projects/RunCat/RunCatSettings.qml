import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "runCat"

    StyledText {
        width: parent.width
        text: "RunCat"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Laufende Katze in der Bar. Je hoeher die CPU-Last, desto schneller laeuft sie. Ein Klick auf das Widget zeigt die Auslastung pro Kern."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    ToggleSetting {
        settingKey: "showPercent"
        label: "Prozentzahl anzeigen"
        description: "Zeigt neben der Katze die aktuelle Gesamt-CPU-Last in Prozent an."
        defaultValue: true
    }

    StyledText {
        width: parent.width
        text: "Aenderungen werden beim naechsten Plugin-Reload wirksam (Settings -> Plugins -> RunCat -> aus-/einschalten, oder 'dms ipc call plugins reload runCat')."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }
}
