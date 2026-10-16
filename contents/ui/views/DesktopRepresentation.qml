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
    readonly property bool horizontalLayout: !compactMode && root && root.desktopOrientation === "horizontal"
    readonly property real fontScale: root ? (Number(root.desktopFontSize || 12) / 12) : 1.0
    readonly property real cardScale: !compactMode && root ? (Number(root.desktopCardScale || 100) / 100) : 1.0
    readonly property real badgeScale: !compactMode && root ? (Number(root.desktopBadgeScale || 100) / 100) : 1.0
    readonly property string activeFontFamily: root ? (root.desktopFontFamily || "") : ""
    property var compactTeamMatch: null
    property var horizontalDayGroups: []

    function scaledFont(baseSize) { return Math.max(8, Math.round(baseSize * fontScale)) }
    function scaledCardFont(baseSize) { return Math.max(8, Math.round(baseSize * fontScale * cardScale)) }
    function scaledTeamBadgeSize(baseSize) { return Math.max(8, Math.round(baseSize * fontScale * cardScale * badgeScale)) }
    function scaledLogoSize(baseSize) { return Math.round(baseSize * cardScale * badgeScale) }

    function rebuildHorizontalDayGroups() {
        if (!root || !root.todayGamesModel) {
            horizontalDayGroups = []
            return
        }

        var previousContentX = horizontalGroupList.contentX
        var groups = []
        var currentGroup = null

        for (var i = 0; i < root.todayGamesModel.count; i++) {
            var entry = root.todayGamesModel.get(i)
            if (entry.statusRole === "DATE_SEP") {
                currentGroup = { start: entry.start, games: [] }
                groups.push(currentGroup)
                continue
            }
            if (!currentGroup) continue

            currentGroup.games.push({
                gameId: entry.gameId,
                away: entry.away,
                home: entry.home,
                ag: entry.ag,
                hg: entry.hg,
                statusRole: entry.statusRole,
                rawState: entry.rawState,
                periodType: entry.periodType,
                period: entry.period,
                liveRemain: entry.liveRemain,
                start: entry.start,
                inIntermission: entry.inIntermission,
                intermissionRemain: entry.intermissionRemain,
                situationCode: entry.situationCode,
                penaltyTime: entry.penaltyTime
            })
        }

        horizontalDayGroups = groups.filter(function(group) { return group.games.length > 0 })
        Qt.callLater(function() {
            if (horizontalGroupList && horizontalGroupList.visible) {
                horizontalGroupList.contentX = Math.min(previousContentX, Math.max(0, horizontalGroupList.contentWidth - horizontalGroupList.width))
            }
        })
    }

    Component.onCompleted: rebuildHorizontalDayGroups()

    Connections {
        target: root ? root.todayGamesModel : null
        function onCountChanged() { desktopRoot.rebuildHorizontalDayGroups() }
        function onDataChanged() { desktopRoot.rebuildHorizontalDayGroups() }
    }

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
                    start: m.start, interm: m.inIntermission, sitCode: m.situationCode, 
                    intermRemain: m.intermissionRemain, penaltyTime: m.penaltyTime || ""
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

    implicitWidth: compactMode ? 240 : (horizontalLayout ? 700 : 440)
    implicitHeight: compactMode ? 120 : (horizontalLayout ? 380 : 520)

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
                font.pixelSize: desktopRoot.scaledFont(13)
                font.family: desktopRoot.activeFontFamily
                color: Kirigami.Theme.textColor
            }
            Label {
                id: lastUpdatedLabel
                visible: root && root.glob.lastUpdated instanceof Date
                font.pixelSize: desktopRoot.scaledFont(10)
                font.family: desktopRoot.activeFontFamily
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
                flat: true; font.pixelSize: desktopRoot.scaledFont(10); font.family: desktopRoot.activeFontFamily
                onClicked: { if (root) root.openStandings() }
            }
            Button {
                text: i18n("Leaders")
                icon.name: "view-statistics"
                flat: true; font.pixelSize: desktopRoot.scaledFont(10); font.family: desktopRoot.activeFontFamily
                onClicked: { if (root) root.openLeaders() }
            }
            Button {
                icon.name: "view-refresh"
                flat: true; font.pixelSize: desktopRoot.scaledFont(10); font.family: desktopRoot.activeFontFamily
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
        visible: !compactMode && !desktopRoot.horizontalLayout
        anchors.top: desktopSep.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 4
        orientation: ListView.Vertical
        model: root ? root.todayGamesModel : null
        spacing: root ? root.spacingBetweenGames : 8
        clip: true

        delegate: Item {
            id: desktopDelegate
            width: desktopList.width
            height: model.statusRole === 'DATE_SEP' ? 32 : Math.round(90 * desktopRoot.cardScale)
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
                    width: implicitWidth
                    text: root ? root.localeDateLong(new Date(model.start).getTime()) : ""
                    font.pixelSize: desktopRoot.scaledFont(11)
                    font.family: desktopRoot.activeFontFamily
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
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
            property string dPType: model.periodType || ""
            property int dPeriod: model.period || 0
            property string dRemain: model.liveRemain || ""
            property var dStart: model.start || 0
            property bool dInterm: model.inIntermission || false
            property string dIntermRemain: model.intermissionRemain || ""
            property string dSit: model.situationCode || "1551"

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
                    opponentCode: dHome
                    score: dAg
                    sz: root.showLogos ? desktopRoot.scaledLogoSize(48) : desktopRoot.scaledTeamBadgeSize(18)
                    fontFamily: desktopRoot.activeFontFamily || "monospace"
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
                        font.pixelSize: desktopRoot.scaledCardFont(22)
                        font.family: desktopRoot.activeFontFamily
                        font.bold: true
                        color: Kirigami.Theme.textColor
                    }

                    Loader {
                        Layout.alignment: Qt.AlignHCenter
                        sourceComponent: root.statusBadgeComponent
                        property string gameStatus: dStatus
                        property string rawState: model.rawState
                        property string periodType: dPType
                        property int period: dPeriod
                        property string liveRemain: dRemain
                        property var startMs: dStart
                        property string awayTeam: dAway
                        property string homeTeam: dHome
                        property bool intermission: dInterm
                        property string intermissionRemain: dIntermRemain
                        property string situationCode: dSit
                        property string penaltyTime: model.penaltyTime || ""
                        property int sz: desktopRoot.scaledCardFont(14)
                        property int fontSize1: desktopRoot.scaledCardFont(12)
                        property int fontSize2: desktopRoot.scaledCardFont(10)
                        property string fontFamily: desktopRoot.activeFontFamily
                    }
                    }

                // Équipe Locale
                Components.TeamBadge {
                    code: dHome
                    opponentCode: dAway
                    score: dHg
                    sz: root.showLogos ? desktopRoot.scaledLogoSize(48) : desktopRoot.scaledTeamBadgeSize(18)
                    fontFamily: desktopRoot.activeFontFamily || "monospace"
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
                    font.pixelSize: desktopRoot.scaledFont(9)
                    font.family: desktopRoot.activeFontFamily
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

    // ── Matchs horizontaux regroupés par date ────────────────────
    ListView {
        id: horizontalGroupList
        visible: !compactMode && desktopRoot.horizontalLayout
        anchors.top: desktopSep.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 4
        orientation: ListView.Horizontal
        model: desktopRoot.horizontalDayGroups
        spacing: root ? root.spacingBetweenGames : 8
        clip: true

        delegate: Item {
            id: dayGroup
            property var groupData: modelData
            readonly property int cardWidth: Math.round(190 * desktopRoot.cardScale)
            readonly property int cardSpacing: root ? root.spacingBetweenGames : 8
            width: groupData.games.length * cardWidth + Math.max(0, groupData.games.length - 1) * cardSpacing
            height: horizontalGroupList.height

            Rectangle {
                id: dayHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 36
                radius: 4
                color: Kirigami.Theme.alternateBackgroundColor
                border.color: Kirigami.Theme.textColor
                border.width: 1
                opacity: 0.7

                Label {
                    anchors.fill: parent
                    anchors.margins: 4
                    text: root ? root.localeDateLong(new Date(dayGroup.groupData.start).getTime()) : ""
                    font.pixelSize: desktopRoot.scaledFont(11)
                    font.family: desktopRoot.activeFontFamily
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var d = new Date(dayGroup.groupData.start)
                        var iso = d.getFullYear() + "-" + Logic.pad2(d.getMonth() + 1) + "-" + Logic.pad2(d.getDate())
                        if (root) root.openDayView(iso)
                    }
                }
            }

            Row {
                id: dayGamesRow
                anchors.top: dayHeader.bottom
                anchors.topMargin: 4
                anchors.left: parent.left
                spacing: dayGroup.cardSpacing

                Repeater {
                    model: dayGroup.groupData.games

                    delegate: Item {
                        id: horizontalGameCard
                        property var game: modelData
                        width: dayGroup.cardWidth
                        height: Math.max(0, horizontalGroupList.height - dayHeader.height - 4)

                        Rectangle {
                            anchors.fill: parent
                            color: Kirigami.Theme.backgroundColor
                            radius: 6
                            border.color: Kirigami.Theme.textColor
                            border.width: 1
                            opacity: 0.05
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 9
                            spacing: 8

                            Components.TeamBadge {
                                code: horizontalGameCard.game.away
                                opponentCode: horizontalGameCard.game.home
                                score: horizontalGameCard.game.ag
                                sz: root.showLogos ? desktopRoot.scaledLogoSize(36) : desktopRoot.scaledTeamBadgeSize(22)
                                scoreFontSize: Math.max(11, Math.round(desktopRoot.scaledCardFont(22) * 1.05))
                                fontFamily: desktopRoot.activeFontFamily || "monospace"
                                gameId: String(horizontalGameCard.game.gameId)
                                teamSide: "away"
                                showScore: true
                                controller: root
                                blinkingGames: root.glob.blinkingGames
                                blinkOn: root.glob.blinkOn
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Loader {
                                Layout.alignment: Qt.AlignHCenter
                                sourceComponent: root.statusBadgeComponent
                                property string gameStatus: horizontalGameCard.game.statusRole
                                property string rawState: horizontalGameCard.game.rawState
                                property string periodType: horizontalGameCard.game.periodType
                                property int period: horizontalGameCard.game.period
                                property string liveRemain: horizontalGameCard.game.liveRemain
                                property var startMs: horizontalGameCard.game.start
                                property string awayTeam: horizontalGameCard.game.away
                                property string homeTeam: horizontalGameCard.game.home
                                property bool intermission: horizontalGameCard.game.inIntermission
                                property string intermissionRemain: horizontalGameCard.game.intermissionRemain
                                property string situationCode: horizontalGameCard.game.situationCode
                                property string penaltyTime: horizontalGameCard.game.penaltyTime || ""
                                property int sz: desktopRoot.scaledCardFont(14)
                                property int fontSize1: desktopRoot.scaledCardFont(12)
                                property int fontSize2: desktopRoot.scaledCardFont(10)
                                property string fontFamily: desktopRoot.activeFontFamily
                            }

                            Components.TeamBadge {
                                code: horizontalGameCard.game.home
                                opponentCode: horizontalGameCard.game.away
                                score: horizontalGameCard.game.hg
                                sz: root.showLogos ? desktopRoot.scaledLogoSize(36) : desktopRoot.scaledTeamBadgeSize(22)
                                scoreFontSize: Math.max(11, Math.round(desktopRoot.scaledCardFont(22) * 1.05))
                                fontFamily: desktopRoot.activeFontFamily || "monospace"
                                gameId: String(horizontalGameCard.game.gameId)
                                teamSide: "home"
                                showScore: true
                                controller: root
                                blinkingGames: root.glob.blinkingGames
                                blinkOn: root.glob.blinkOn
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        Rectangle {
                            visible: root && root.glob.blinkingGames[String(horizontalGameCard.game.gameId)] !== undefined
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
                                font.pixelSize: desktopRoot.scaledFont(9)
                                font.family: desktopRoot.activeFontFamily
                                font.bold: true
                                color: Kirigami.Theme.positiveTextColor
                            }
                        }

                        TapHandler {
                            onTapped: {
                                var g = horizontalGameCard.game
                                if (root) root.openDetail(g.gameId, g.away, g.home, g.ag, g.hg, g.statusRole, g.periodType, g.period, g.liveRemain, g.start, g.inIntermission, g.situationCode, g.intermissionRemain)
                            }
                        }
                    }
                }
            }
        }

        Label {
            anchors.centerIn: parent
                visible: desktopRoot.horizontalDayGroups.length === 0
                text: i18n("No games today")
            opacity: 0.5
            font.italic: true
            font.pixelSize: desktopRoot.scaledFont(11)
            font.family: desktopRoot.activeFontFamily
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
        readonly property int dynamicScoreSize: Math.min(parent.height * 0.4, Math.max(14, Math.min(48, 28 * scaleFactor * desktopRoot.fontScale)))
        readonly property int dynamicStatusSize: Math.min(parent.height * 0.2, Math.max(8, Math.min(16, 10 * scaleFactor)))

        Label {
            anchors.centerIn: parent
            visible: !compactTeamMatch
            text: (root && root.favoriteTeams && root.favoriteTeams.length > 0) ? i18n("No games for your team") : i18n("No favorite team set")
            opacity: 0.5; font.italic: true; font.pixelSize: desktopRoot.scaledFont(11); font.family: desktopRoot.activeFontFamily
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
                opponentCode: compactTeamMatch ? compactTeamMatch.home : ""
                teamSide: 'away'
                sz: Math.round(desktopRoot.scaledFont(compactView.dynamicLogoSize) * desktopRoot.badgeScale)
                iconH: compactView.dynamicLogoSize
                fontFamily: desktopRoot.activeFontFamily || "monospace"
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
                    font.pixelSize: compactView.dynamicScoreSize; font.bold: true; font.family: desktopRoot.activeFontFamily
                    color: Kirigami.Theme.textColor
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
                Loader {
                    Layout.alignment: Qt.AlignHCenter
                    sourceComponent: root.statusBadgeComponent
                    property string gameStatus: compactTeamMatch ? compactTeamMatch.status : ""
                    property string rawState: compactTeamMatch ? compactTeamMatch.pType : ""
                    property string periodType: compactTeamMatch ? compactTeamMatch.pType : ""
                    property int period: compactTeamMatch ? compactTeamMatch.period : 0
                    property string liveRemain: compactTeamMatch ? compactTeamMatch.remain : ""
                    property var startMs: compactTeamMatch ? compactTeamMatch.start : 0
                    property string awayTeam: compactTeamMatch ? compactTeamMatch.away : ""
                    property string homeTeam: compactTeamMatch ? compactTeamMatch.home : ""
                    property bool intermission: compactTeamMatch ? compactTeamMatch.interm : false
                    property string intermissionRemain: compactTeamMatch ? compactTeamMatch.intermRemain : ""
                    property string situationCode: compactTeamMatch ? compactTeamMatch.sitCode : "1551"
                    property string penaltyTime: compactTeamMatch ? (compactTeamMatch.penaltyTime || "") : ""
                    property int sz: desktopRoot.scaledFont(12)
                    property int fontSize1: desktopRoot.scaledFont(10)
                    property int fontSize2: desktopRoot.scaledFont(9)
                    property string fontFamily: desktopRoot.activeFontFamily
                }
            }

            Components.TeamBadge {
                code: compactTeamMatch ? compactTeamMatch.home : ""
                opponentCode: compactTeamMatch ? compactTeamMatch.away : ""
                teamSide: 'home'
                sz: Math.round(desktopRoot.scaledFont(compactView.dynamicLogoSize) * desktopRoot.badgeScale)
                iconH: compactView.dynamicLogoSize
                fontFamily: desktopRoot.activeFontFamily || "monospace"
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
