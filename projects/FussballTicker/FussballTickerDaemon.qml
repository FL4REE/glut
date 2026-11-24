import QtQuick
import qs.Common
import qs.Services
import qs.Modules.Plugins

// Hintergrund-Daemon des Fußball-Tickers.
//
// Datenquelle: API-Football (api-sports.io / dashboard.api-football.com).
//
// WICHTIG: Der kostenlose Free-Tier ist deutlich restriktiver als die Doku
// zunächst vermuten lässt. Live getestet (28.08.2026) mit echtem Key:
//   - /fixtures?team=X&next=1        -> "Free plans do not have access to
//                                        the Next parameter."
//   - /fixtures?team=X&season=2025   -> "Free plans do not have access to
//                                        this season, try from 2022 to 2024."
//   - /standings?...&season=2025     -> gleiche Sperre, nur 2021-2023 erlaubt
//   - /fixtures?live=all             -> funktioniert uneingeschränkt, egal
//                                        welcher Plan
//
// Das bedeutet: es gibt im Free-Tier KEINEN Weg, an Spielpläne, kommende
// Kickoff-Zeiten oder aktuelle Tabellen zu kommen. Einzig verlässliche Quelle
// ist der Live-Endpunkt. Der Daemon pollt daher schlicht /fixtures?live=all
// und filtert client-seitig auf die konfigurierten Teams/Ligen. Das ist auch
// funktional genau das, was ursprünglich gewünscht war ("Live-Ticker"), nur
// eben ohne Vorschau kommender Spiele oder Tabellenstand.
//
// Quota-Konsequenz (Free-Tier = 100 Requests/Tag):
//   - Außerhalb von Live-Fenstern wird selten gepollt (idleIntervalSeconds,
//     Standard 15 Minuten, nur zwischen 07:00 und 23:59 Uhr - nachts läuft
//     ohnehin kaum Fußball)
//   - Sobald ein verfolgtes Spiel im Live-Status auftaucht, wird auf ein
//     kurzes Intervall umgeschaltet (liveIntervalSeconds, Standard 90s)
//     bis das Spiel aus /live verschwindet (Abpfiff)
//   - An normalen Tagen ohne Spiel: grob 60-70 Requests. An Spieltagen kommt
//     pro Spiel nochmal ca. 70-90 Requests dazu - bei mehreren Spielen am
//     selben Tag kann das Tageslimit knapp werden. Intervalle sind daher in
//     den Settings einstellbar.
PluginComponent {
    id: root

    // Bundesliga = 78. 2. Bundesliga läuft nicht extra mit, weil Hansa
    // Rostock schon über den Team-Namen gefiltert wird.
    readonly property var followedLeagueIds: [78]

    property string apiKey: PluginService.loadPluginData(root.pluginId, "apiKey", "")
    property var teams: PluginService.loadPluginData(root.pluginId, "teams", [
        { name: "Hansa Rostock" },
        { name: "Borussia Dortmund" },
        { name: "Germany" }
    ])
    property int liveIntervalSeconds: parseInt(PluginService.loadPluginData(root.pluginId, "liveIntervalSeconds", "90"))
    property int idleIntervalSeconds: parseInt(PluginService.loadPluginData(root.pluginId, "idleIntervalSeconds", "900"))

    property bool currentlyTrackingLive: false
    readonly property int effectiveIntervalMs: (root.currentlyTrackingLive ? root.liveIntervalSeconds : root.idleIntervalSeconds) * 1000

    readonly property var curlBase: ["curl", "-sS", "--fail", "--connect-timeout", "5", "--max-time", "12"]
    readonly property string apiBaseUrl: "https://v3.football.api-sports.io"

    function isWakingHours() {
        const hour = new Date().getHours();
        return hour >= 7 && hour <= 23;
    }

    function matchesFollowed(fixture) {
        if (root.followedLeagueIds.includes(fixture.league.id))
            return true;
        const home = fixture.teams.home.name.toLowerCase();
        const away = fixture.teams.away.name.toLowerCase();
        return root.teams.some(t => {
            const name = t.name.toLowerCase();
            return home.includes(name) || away.includes(name) || home === name || away === name;
        });
    }

    function pollLive() {
        if (!root.apiKey) {
            console.warn("FussballTicker: kein API-Key gesetzt, Daemon bleibt inaktiv.");
            return;
        }
        if (!root.isWakingHours() && !root.currentlyTrackingLive) {
            // Nachts nicht pollen, außer wir verfolgen bereits ein laufendes Spiel
            return;
        }

        const cmd = root.curlBase.concat(["-H", "x-apisports-key: " + root.apiKey]).concat([root.apiUrl("/fixtures?live=all")]);
        Proc.runCommand("fussballTicker.live", cmd, (stdout, exitCode) => {
            if (exitCode !== 0) {
                console.warn("FussballTicker: live=all Request fehlgeschlagen, exitCode", exitCode);
                return;
            }
            try {
                const data = JSON.parse(stdout);
                if (data.errors && Object.keys(data.errors).length > 0) {
                    console.warn("FussballTicker: API-Fehler:", JSON.stringify(data.errors));
                    return;
                }

                const previous = PluginService.getGlobalVar(root.pluginId, "liveMatches", {});
                const current = {};

                for (const fixture of (data.response || [])) {
                    if (!root.matchesFollowed(fixture))
                        continue;

                    const fixtureId = fixture.fixture.id;
                    const goalsHome = fixture.goals.home ?? 0;
                    const goalsAway = fixture.goals.away ?? 0;
                    const prevEntry = previous[fixtureId];

                    if (prevEntry && (prevEntry.goalsHome !== goalsHome || prevEntry.goalsAway !== goalsAway)) {
                        ToastService.showInfo("Tor!", fixture.teams.home.name + " " + goalsHome + ":" + goalsAway + " " + fixture.teams.away.name);
                    }

                    current[fixtureId] = {
                        home: fixture.teams.home.name,
                        away: fixture.teams.away.name,
                        goalsHome: goalsHome,
                        goalsAway: goalsAway,
                        minute: fixture.fixture.status.elapsed || 0,
                        statusShort: fixture.fixture.status.short,
                        league: fixture.league.name
                    };
                }

                PluginService.setGlobalVar(root.pluginId, "liveMatches", current);
                PluginService.setGlobalVar(root.pluginId, "lastPollTimestamp", Date.now());
                root.currentlyTrackingLive = Object.keys(current).length > 0;
            } catch (e) {
                console.warn("FussballTicker: Live-Antwort nicht lesbar:", e);
            }
        }, 200);
    }

    function apiUrl(path) {
        return root.apiBaseUrl + path;
    }

    Timer {
        interval: root.effectiveIntervalMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pollLive()
    }

    Component.onCompleted: {
        console.info("FussballTicker: Daemon gestartet, verfolge Teams:", root.teams.map(t => t.name).join(", "), "+ Bundesliga gesamt");
        if (!root.apiKey) {
            console.warn("FussballTicker: kein API-Key in den Plugin-Settings hinterlegt - Daemon bleibt inaktiv.");
        }
    }
}
