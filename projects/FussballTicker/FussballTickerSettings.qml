import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "fussballTicker"

    StyledText {
        width: parent.width
        text: "Fußball Ticker"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Datenquelle ist API-Football (dashboard.api-football.com). Der Free-Tier (100 Requests/Tag) erlaubt nur den Live-Endpunkt, keine Spielpläne oder aktuellen Tabellen - das Plugin zeigt daher nur an, wenn ein verfolgtes Team gerade wirklich spielt."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "apiKey"
        label: "API-Key"
        description: "Dein persönlicher API-Football Key"
        placeholder: "z.B. abcdef0123456789..."
        defaultValue: ""
    }

    SelectionSetting {
        settingKey: "idleIntervalSeconds"
        label: "Prüf-Intervall (ohne laufendes Spiel)"
        description: "Wie oft geprüft wird, ob eines der verfolgten Teams gerade spielt. Läuft nur zwischen 07:00 und 24:00 Uhr."
        options: [
            { label: "10 Minuten", value: "600" },
            { label: "15 Minuten (empfohlen)", value: "900" },
            { label: "20 Minuten", value: "1200" },
            { label: "30 Minuten (sparsamer)", value: "1800" }
        ]
        defaultValue: "900"
    }

    SelectionSetting {
        settingKey: "liveIntervalSeconds"
        label: "Poll-Intervall (während eines Live-Spiels)"
        description: "Wie oft der Spielstand aktualisiert wird, sobald ein verfolgtes Spiel läuft. Kürzer = aktueller, verbraucht aber mehr vom Tageskontingent."
        options: [
            { label: "60 Sekunden", value: "60" },
            { label: "90 Sekunden (empfohlen)", value: "90" },
            { label: "120 Sekunden", value: "120" },
            { label: "180 Sekunden (sparsamer)", value: "180" }
        ]
        defaultValue: "90"
    }

    ListSettingWithInput {
        settingKey: "teams"
        label: "Verfolgte Teams"
        description: "Namen wie sie bei API-Football hinterlegt sind (meist englisch, z.B. 'Germany' statt 'Deutschland'). Alle Bundesliga-Spiele werden zusätzlich immer angezeigt, unabhängig von dieser Liste."
        defaultValue: [
            { name: "Hansa Rostock" },
            { name: "Borussia Dortmund" },
            { name: "Germany" }
        ]
        fields: [
            { id: "name", label: "Team", placeholder: "z.B. Borussia Dortmund", width: 220, required: true }
        ]
    }

    StyledText {
        width: parent.width
        text: "Änderungen werden beim nächsten Plugin-Reload wirksam (Settings → Plugins → Fußball Ticker → aus-/einschalten, oder 'dms ipc call plugins reload fussballTicker')."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }
}
