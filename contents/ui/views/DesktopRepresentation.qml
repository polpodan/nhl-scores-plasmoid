import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic
import "../components" as Components

Item {
    id: desktopRoot
    property var controller
    
    readonly property var root: controller

    // On utilise la propriété exposée par root pour éviter ReferenceError: Plasmoid
    readonly property bool compactMode: (root && root.showCompactDesktop === true) && (root.favoriteTeams && root.favoriteTeams.length > 0)
    property var compactTeamMatch: null

    function findCompactMatch() {
        if (!root || !root.todayGamesModel || root.todayGamesModel.count === 0) return null
        
        for (var i = 0; i < root.todayGamesModel.count; i++) {
            var m = root.todayGamesModel.get(i)
            if (m.statusRole === 'DATE_SEP') continue
            if (root.favoriteTeams.indexOf(m.away) >= 0 || root.favoriteTeams.indexOf(m.home) >= 0) {
                return {
                    gameId: m.gameId, away: m.away, home: m.home,
                    awayScore: m.ag, homeScore: m.hg, status: m.statusRole,
                    pType: m.periodType, period: m.period, remain: m.liveRemain,
                    start: m.start, interm: m.inIntermission, sitCode: m.situationCode, intermRemain: m.intermissionRemain
                }
            }
        }
        return null
    }

    function compactStatusText(m) {
        if (!m || !root) return ""
        if (m.status === 'UPCOMING') return root.localTimeStr(m.start)
        if (m.status === 'FINAL' || m.status === 'OFF' || m.status === 'OFFICIAL') {
            return i18n("Final") + (root.statusSuffix(m.status, m.pType) || "")
        }
        // LIVE
        if (m.interm) {
            return "INT" + (m.intermRemain ? " " + m.intermRemain : "")
        }
        return root.liveClockText(m.pType, m.period, m.remain)
    }

    // Déclencher la recherche quand les favoris ou l'option changent
    Connections {
        target: root ? root : null
        function onFavoriteTeamsChanged() { compactTeamMatch = findCompactMatch() }
        function onShowCompactDesktopChanged() { compactTeamMatch = findCompactMatch() }
    }

    Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var m = findCompactMatch()
            if (!m) {
                compactTeamMatch = null
                return
            }
            if (!compactTeamMatch || m.gameId !== compactTeamMatch.gameId || m.awayScore !== compactTeamMatch.awayScore || m.homeScore !== compactTeamMatch.homeScore || m.status !== compactTeamMatch.status || m.remain !== compactTeamMatch.remain) {
                compactTeamMatch = m
            }
        }
    }

    implicitWidth: compactMode ? 240 : 440
    implicitHeight: compactMode ? 120 : 520

    readonly property int hubW: (controller && controller.styles) ? controller.styles.hubWidth : 320
    readonly property int cardW: (controller && controller.styles) ? controller.styles.cardWidth : 480

    // ── En-tête ─────────────────────────────────────────────────
    Item {
        id: desktopHeader
        visible: !compactMode
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: visible ? (headerRow.implicitHeight + 16) : 0

        RowLayout {
            id: headerRow
            anchors.centerIn: parent
            width: Math.min(480, parent.width)
            spacing: 6

            Label {
                text: i18n("NHL Scores")
                font.bold: true
                font.pixelSize: 13
                color: Kirigami.Theme.textColor
            }
            Label {
                id: lastUpdatedLabel
                visible: root && root.glob.lastUpdated instanceof Date
                font.pixelSize: 10
                opacity: 0.5
                color: root && root.glob.isOffline ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                text: {
                    var p = root ? root.glob.pulse : 0 
                    if (!root || !(root.glob.lastUpdated instanceof Date)) return ""
                    var offStr = root.glob.isOffline ? ("[" + i18n("Offline") + "] ") : ""
                    var diff = Math.floor((new Date() - root.glob.lastUpdated) / 60000)
                    if (diff < 1) return offStr + i18n("just now")
                    if (diff === 1) return offStr + i18n("1 min ago")
                    return offStr + diff + " " + i18n("min ago")
                }
            }
            Item { Layout.fillWidth: true }
            Button {
                text: i18n("Standings")
                icon.name: "view-list-symbolic"
                flat: true; font.pixelSize: 10
                onClicked: { if (root) root.openStandings() }
            }
            Button {
                text: i18n("Leaders")
                icon.name: "view-statistics"
                flat: true; font.pixelSize: 10
                onClicked: { if (root) root.openLeaders() }
            }
            Button {
                icon.name: "view-refresh"
                flat: true; font.pixelSize: 10
                onClicked: { if (root) root.refresh() }
            }
        }
    }

    Rectangle {
        id: desktopSep
        visible: !compactMode
        anchors.top: desktopHeader.bottom
        width: parent.width
        height: 1
        color: Kirigami.Theme.textColor
        opacity: 0.1
    }

    // ── Liste des cartes de matchs ──────────────────────────────
    ListView {
        id: desktopList
        visible: !compactMode
        anchors.top: desktopSep.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 4
        model: root ? root.todayGamesModel : null
        spacing: root ? root.spacingBetweenGames : 8
        clip: true

        delegate: Item {
            id: desktopDelegate
            width: desktopList.width
            height: model.statusRole === 'DATE_SEP' ? 32 : 90
            visible: model.gameIndex < (root ? root.maxGames : 10)

            Rectangle {
                id: dateSepRect
                visible: model.statusRole === 'DATE_SEP'
                anchors.centerIn: parent
                width: dateSepLbl.implicitWidth + 24
                height: 24
                radius: 4
                color: Kirigami.Theme.alternateBackgroundColor
                border.color: Kirigami.Theme.textColor
                border.width: 1
                opacity: 0.7
                Label {
                    id: dateSepLbl
                    anchors.centerIn: parent
                    text: root ? root.localeDateLong(new Date(model.start).getTime()) : ""
                    font.pixelSize: 11
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var d = new Date(model.start)
                        var iso = d.getFullYear() + "-" + Logic.pad2(d.getMonth() + 1) + "-" + Logic.pad2(d.getDate())
                        if (root) root.openDayView(iso)
                    }
                }
            }

            property string dAway: model.away || ""
            property string dHome: model.home || ""
            property int dAg: model.ag || 0
            property int dHg: model.hg || 0
            property string dStatus: model.statusRole || ""
            property string dPType: model.pType || ""
            property int dPeriod: model.period || 0
            property string dRemain: model.remain || ""
            property var dStart: model.start || 0
            property bool dInterm: model.interm || false
            property string dIntermRemain: model.intermissionRemain || ""
            property string dSit: model.sitCode || "1551"

            Rectangle {
                anchors.fill: parent
                visible: model.statusRole !== 'DATE_SEP'
                color: Kirigami.Theme.backgroundColor
                radius: 6
                border.color: Kirigami.Theme.textColor
                border.width: 1
                opacity: 0.05
            }

            RowLayout {
                anchors.fill: parent
                visible: model.statusRole !== 'DATE_SEP'
                anchors.margins: 10
                spacing: 0

                Item { Layout.fillWidth: true }

                // Équipe Visiteur
                Components.TeamBadge {
                    code: dAway
                    score: dAg
                    sz: root.showLogos ? 48 : 18
                    gameId: String(model.gameId)
                    teamSide: 'away'
                    showScore: false
                    controller: root
                    blinkingGames: root.glob.blinkingGames
                    blinkOn: root.glob.blinkOn
                    Layout.alignment: Qt.AlignVCenter
                }

                // Info Match
                ColumnLayout {
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: dAg + " – " + dHg
                        font.pixelSize: 22
                        font.bold: true
                        color: Kirigami.Theme.textColor
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: compactStatusText({ status: dStatus, pType: model.periodType, period: model.period, remain: model.liveRemain, start: dStart, interm: dInterm, intermRemain: dIntermRemain })
                        font.pixelSize: 10
                        font.bold: true
                        opacity: 0.7
                        color: dStatus === 'LIVE' ? root.liveColor : Kirigami.Theme.textColor
                    }
                }

                // Équipe Locale
                Components.TeamBadge {
                    code: dHome
                    score: dHg
                    sz: root.showLogos ? 48 : 18
                    gameId: String(model.gameId)
                    teamSide: 'home'
                    showScore: false
                    controller: root
                    blinkingGames: root.glob.blinkingGames
                    blinkOn: root.glob.blinkOn
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }
            }

            Rectangle {
                visible: root && root.glob.blinkingGames[String(model.gameId)] !== undefined
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: 60
                height: 16
                color: Kirigami.Theme.positiveBackgroundColor
                radius: 3
                anchors.topMargin: -8
                border.color: "white"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "🚨 BUT"
                    font.pixelSize: 9
                    font.bold: true
                    color: Kirigami.Theme.positiveTextColor
                }
            }

            TapHandler {
                onTapped: {
                    if (root) {
                        root.openDetail(model.gameId, dAway, dHome, dAg, dHg, dStatus, dPType, dPeriod, dRemain, dStart, dInterm, dSit)
                    }
                }
            }
        }

        Label {
            anchors.centerIn: parent
            visible: !compactMode && desktopList.count === 0
            text: i18n("No games today")
            opacity: 0.5
            font.italic: true
        }
    }

    // ── Interface Mode Compact ──────────────────────────────────
    Item {
        id: compactView
        visible: compactMode
        anchors.fill: parent
        clip: true

        // Facteurs d'échelle plus conservateurs
        readonly property real scaleFactor: Math.min(parent.width / 240, parent.height / 100)
        
        // On s'assure que le logo ne dépasse pas 75% de la hauteur de l'applet
        readonly property int dynamicLogoSize: Math.min(parent.height * 0.75, Math.max(32, Math.min(128, 64 * scaleFactor)))
        
        // Le score suit l'échelle mais avec un plafond strict
        readonly property int dynamicScoreSize: Math.min(parent.height * 0.4, Math.max(14, Math.min(48, 28 * scaleFactor)))
        readonly property int dynamicStatusSize: Math.min(parent.height * 0.2, Math.max(8, Math.min(16, 10 * scaleFactor)))

        Label {
            anchors.centerIn: parent
            visible: !compactTeamMatch
            text: (root && root.favoriteTeams && root.favoriteTeams.length > 0) ? i18n("No games for your team") : i18n("No favorite team set")
            opacity: 0.5; font.italic: true; font.pixelSize: 11
            color: Kirigami.Theme.textColor
        }

        RowLayout {
            anchors.centerIn: parent
            visible: !!compactTeamMatch
            spacing: Math.floor(10 * compactView.scaleFactor)
            width: Math.min(parent.width - 16, 280 * compactView.scaleFactor)
            height: parent.height

            Components.TeamBadge {
                code: compactTeamMatch ? compactTeamMatch.away : ""
                sz: compactView.dynamicLogoSize
                showScore: false; controller: root
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: compactTeamMatch ? (compactTeamMatch.awayScore + " – " + compactTeamMatch.homeScore) : ""
                    font.pixelSize: compactView.dynamicScoreSize; font.bold: true
                    color: Kirigami.Theme.textColor
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: compactStatusText(compactTeamMatch)
                    font.pixelSize: compactView.dynamicStatusSize; font.bold: true; opacity: 0.8
                    color: (compactTeamMatch && compactTeamMatch.status === 'LIVE') ? root.liveColor : Kirigami.Theme.textColor
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 8
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }

            Components.TeamBadge {
                code: compactTeamMatch ? compactTeamMatch.home : ""
                sz: compactView.dynamicLogoSize
                showScore: false; controller: root
                Layout.alignment: Qt.AlignVCenter
            }
        }

        TapHandler {
            enabled: !!compactTeamMatch
            onTapped: {
                var m = compactTeamMatch
                root.openDetail(m.gameId, m.away, m.home, m.awayScore, m.homeScore, m.status, m.pType, m.period, m.remain, m.start, m.interm, m.sitCode, m.intermRemain)
            }
        }
    }
}
