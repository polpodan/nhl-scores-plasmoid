import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic
import "../components" as Components

ScrollView {
    id: detailRoot
    property var controller
    
    readonly property var root: controller

    contentWidth: width
    clip: true

    Item {
        width: detailRoot.width
        implicitHeight: detailNavBar.implicitHeight + detailColumn.implicitHeight + 40

        // ── Barre de navigation ─────────────────
        RowLayout {
            id: detailNavBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 4
            anchors.leftMargin: 4
            anchors.rightMargin: 4

            Button {
                text: "✕"
                flat: true
                onClicked: {
                    controller.nav.detail = false
                    controller.expanded = false
                }
            }
            Item {
                Layout.fillWidth: true
            }
            Button {
                text: i18n("Standings")
                icon.name: "view-list-symbolic"
                flat: true
                onClicked: {
                    controller.openStandings()
                }
            }
            Item {
                Layout.fillWidth: true
            }
            Button {
                text: i18n("Leaders")
                icon.name: "view-statistics"
                flat: true
                onClicked: {
                    controller.openLeaders()
                }
            }
            Item {
                Layout.fillWidth: true
            }
            Button {
                text: i18n("Search")
                icon.name: "search"
                flat: true
                onClicked: controller.openSearch()
            }
            Item {
                Layout.fillWidth: true
            }
            Button {
                text: "NHL.com"
                icon.name: "internet-web-browser"
                flat: true
                onClicked: {
                    Qt.openUrlExternally(controller.gameCenterUrl(controller.det.away, controller.det.home, controller.det.start, controller.det.gameId))
                }
            }
            Button {
                icon.name: "view-refresh"
                flat: true
                onClicked: {
                    controller.refresh()
                }
            }
        }

        ColumnLayout {
            id: detailColumn
            width: Math.min((controller && controller.styles) ? controller.styles.hubWidth : 320, parent.width - 32)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: detailNavBar.bottom
            anchors.topMargin: 4
            spacing: 8

            // ── En-tête score ────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                // Visiteur
                Column {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter
                    Item {
                        width: 150
                        height: 150
                        anchors.horizontalCenter: parent.horizontalCenter
                        Image {
                            anchors.fill: parent
                            source: controller ? controller.teamLogoUrl(controller.det.away) : ""
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            onTapped: {
                                controller.openTeamHub(controller.det.away, "detail")
                            }
                        }
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: controller && controller.det.status !== 'UPCOMING'
                        text: controller ? String(controller.det.ag) : "0"
                        font.pixelSize: 32
                        font.bold: true
                        color: Kirigami.Theme.textColor
                    }
                    ColumnLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: controller && controller.det.status === 'UPCOMING'
                        spacing: 0
                        Label {
                            text: controller ? controller.det.awayRecord : ""
                            font.pixelSize: 14; font.bold: true
                            color: controller ? controller.teamColorAdapted(controller.det.away) : "gray"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Label {
                            text: i18n("Record")
                            font.pixelSize: 9; opacity: 0.5
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // Centre
                Column {
                    spacing: 4
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    // Séparateur vertical double (pour match à venir)
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: controller && controller.det.status === 'UPCOMING'
                        spacing: 4
                        Rectangle {
                            width: 4; height: 120
                            radius: 2
                            color: controller ? Logic.getTeamColor(controller.det.away) : Kirigami.Theme.highlightColor
                        }
                        Rectangle {
                            width: 4; height: 120
                            radius: 2
                            color: controller ? Logic.getTeamColor(controller.det.home) : Kirigami.Theme.highlightColor
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: controller && controller.det.status === 'FINAL'
                        radius: 5
                        color: controller ? controller.statusColor(controller.det.status) : "gray"
                        opacity: 0.95
                        width: detailBadgeCol.implicitWidth + 10
                        height: detailBadgeCol.implicitHeight + 6
                        Column {
                            id: detailBadgeCol
                            anchors.centerIn: parent
                            spacing: 0
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: controller ? controller.badgeLine1(controller.det.status, '', controller.det.pType, controller.det.period, controller.det.remain, controller.det.start, controller.det.home, controller.det.interm) : ""
                                color: 'white'
                                font.pixelSize: 10
                                font.bold: true
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: text !== ''
                                text: controller ? controller.badgeLine2(controller.det.status, controller.det.start, controller.det.home, controller.det.pType, controller.det.period, controller.det.remain, controller.det.interm, controller.det.intermRemain) : ""
                                color: 'white'
                                font.pixelSize: 9
                                opacity: 0.85
                            }
                        }
                    }
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: controller && controller.det.status === 'LIVE'
                        spacing: 2
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: controller ? controller.badgeLine1(controller.det.status, '', controller.det.pType, controller.det.period, controller.det.remain, controller.det.start, controller.det.home, controller.det.interm) : ""
                            font.pixelSize: 13
                            font.bold: true
                            color: Kirigami.Theme.textColor
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: !!controller && !!controller.det.interm && (controller.det.intermRemain || "") !== ''
                            text: controller ? controller.det.intermRemain : ""
                            font.pixelSize: 18
                            font.bold: true
                            color: Kirigami.Theme.textColor
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: text !== ''
                            text: controller ? controller.badgeLine2(controller.det.status, controller.det.start, controller.det.home, controller.det.pType, controller.det.period, controller.det.remain, controller.det.interm, controller.det.intermRemain) : ""
                            font.pixelSize: 11
                            color: Kirigami.Theme.disabledTextColor
                        }
                    }
                }

                // Local
                Column {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter
                    Item {
                        width: 150
                        height: 150
                        anchors.horizontalCenter: parent.horizontalCenter
                        Image {
                            anchors.fill: parent
                            source: controller ? controller.teamLogoUrl(controller.det.home) : ""
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            onTapped: {
                                controller.openTeamHub(controller.det.home, 'detail')
                            }
                        }
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: controller && controller.det.status !== 'UPCOMING'
                        text: controller ? String(controller.det.hg) : "0"
                        font.pixelSize: 32
                        font.bold: true
                        color: Kirigami.Theme.textColor
                    }
                    ColumnLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: controller && controller.det.status === 'UPCOMING'
                        spacing: 0
                        Label {
                            text: controller ? controller.det.homeRecord : ""
                            font.pixelSize: 14; font.bold: true
                            color: controller ? controller.teamColorAdapted(controller.det.home) : "gray"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Label {
                            text: i18n("Record")
                            font.pixelSize: 9; opacity: 0.5
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }

            // ── Bloc Info match (Heure, Date, Aréna) ──────────────────
            ColumnLayout {
                visible: controller && !controller.det.loading && controller.det.status === 'UPCOMING'
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                spacing: 2
                Label {
                    visible: controller && controller.det.start > 0
                    Layout.alignment: Qt.AlignHCenter
                    text: controller && controller.det.start > 0
                        ? Qt.formatTime(new Date(controller.det.start), "hh:mm") + "  ·  "
                          + controller.localeDateLong(controller.det.start)
                        : ""
                    font.pixelSize: 14; font.bold: true
                    color: Kirigami.Theme.textColor
                }
                Label {
                    visible: controller && (controller.det.venue || '') !== ''
                    Layout.alignment: Qt.AlignHCenter
                    text: controller ? controller.det.venue : ''
                    font.pixelSize: 12; opacity: 0.6
                    color: Kirigami.Theme.disabledTextColor
                }
            }

            // Date du match (Matchs terminés ou en direct)
            Label {
                visible: controller && controller.det.start > 0 && controller.det.status !== 'UPCOMING'
                Layout.alignment: Qt.AlignHCenter
                text: controller && controller.det.start > 0 ? Qt.formatDateTime(new Date(controller.det.start), "hh:mm  ·  ddd d MMM yyyy") : ""
                font.pixelSize: 13
                font.bold: true
                color: Kirigami.Theme.textColor
            }

            // Gestion de l'état (Chargement / Erreur)
            Components.StateLayer {
                loading: !!controller && controller.det.loading
                error: controller ? controller.det.error : ""
                topMargin: 10
            }

            // ── Avantage numérique ───────────────────────────────────
            Rectangle {
                id: ppBanner
                Layout.alignment: Qt.AlignHCenter
                property var sit: controller ? controller.parseSituation(controller.det.sitCode, controller.det.away, controller.det.home) : null
                visible: sit !== null
                width:  ppBannerContent.implicitWidth + 20
                height: ppBannerContent.implicitHeight + 10
                radius: 6
                color: (sit && sit.ppTeam) ? Logic.getTeamColor(sit.ppTeam) : Kirigami.Theme.highlightColor
                Column {
                    id: ppBannerContent
                    anchors.centerIn: parent
                    spacing: 2
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6
                        Text {
                            text: ppBanner.sit ? ppBanner.sit.ppType : ''
                            font.pixelSize: 14
                            font.bold: true
                            color: 'white'
                        }
                        Text {
                            visible: ppBanner.sit && !ppBanner.sit.even
                            text: ppBanner.sit ? ((ppBanner.sit.ppTeam || '') + '  ' + ppBanner.sit.awaySkaters + 'v' + ppBanner.sit.homeSkaters) : ''
                            font.pixelSize: 14
                            color: 'white'
                        }
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4
                        visible: ppBanner.sit !== null && ppBanner.sit.emptyNet
                        Text {
                            text: '🥅'
                            font.pixelSize: 13
                        }
                        Text {
                            text: ppBanner.sit && ppBanner.sit.enTeam ? ppBanner.sit.enTeam : ''
                            font.pixelSize: 13
                            font.bold: true
                            color: 'white'
                        }
                    }
                }
            }

            // ── Preview match à venir (Séries / H2H) ─────────────────────────
            ColumnLayout {
                visible: controller && !controller.det.loading && controller.det.status === 'UPCOMING'
                Layout.fillWidth: true
                Layout.topMargin: 20 // Espace avec le bloc info au-dessus
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    radius: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0.0
                            color: controller ? Logic.getTeamColor(controller.det.away) : "gray"
                        }
                        GradientStop {
                            position: 1.0
                            color: controller ? Logic.getTeamColor(controller.det.home) : "gray"
                        }
                    }
                    opacity: 0.6
                }

                ColumnLayout {
                    visible: controller && controller.det.isPlayoff && (controller.det.seriesAway > 0 || controller.det.seriesHome > 0)
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: controller && controller.det.seriesRound !== '' ? controller.det.seriesRound : ""
                        font.pixelSize: 12
                        font.bold: true
                        opacity: 0.8
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8
                        Label {
                            text: controller ? (controller.det.seriesAway > controller.det.seriesHome ? controller.det.away + " mène" : controller.det.seriesHome > controller.det.seriesAway ? controller.det.home + " mène" : "Égalité") : ""
                            font.pixelSize: 13
                        }
                        Label {
                            text: controller ? controller.det.seriesAway + " – " + controller.det.seriesHome : ""
                            font.pixelSize: 22
                            font.bold: true
                        }
                        Button {
                            text: "🏆"
                            flat: true
                            onClicked: controller.openPlayoffBracket()
                            ToolTip.text: i18n("Playoffs")
                            ToolTip.visible: hovered
                        }
                    }
                }

                ColumnLayout {
                    visible: controller && controller.det.h2hGames && controller.det.h2hGames.length > 0
                    Layout.fillWidth: true
                    spacing: 3
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 24
                        color: Qt.rgba(1,1,1,0.04)
                        radius: 4
                        Label {
                            anchors.centerIn: parent
                            text: i18n("Season series")
                            font.pixelSize: 11
                            font.bold: true
                            opacity: 0.6
                        }
                    }
                    Repeater {
                        model: controller ? controller.det.h2hGames : []
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Label {
                                text: modelData.start ? Qt.formatDate(new Date(modelData.start), "d MMM") : ''
                                font.pixelSize: 11
                                opacity: 0.6
                                Layout.preferredWidth: 40
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            Rectangle {
                                radius: 3
                                color: Logic.getTeamColor(modelData.away)
                                width: 34
                                height: 18
                                Label {
                                    anchors.centerIn: parent
                                    text: modelData.away
                                    color: Logic.getTeamTextColor(modelData.away)
                                    font.bold: true
                                    font.pixelSize: 10
                                }
                            }
                            Label {
                                text: modelData.final ? modelData.awayScore + " – " + modelData.homeScore : "@"
                                font.bold: modelData.final
                                Layout.preferredWidth: 40
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Rectangle {
                                radius: 3
                                color: Logic.getTeamColor(modelData.home)
                                width: 34
                                height: 18
                                Label {
                                    anchors.centerIn: parent
                                    text: modelData.home
                                    color: Logic.getTeamTextColor(modelData.home)
                                    font.bold: true
                                    font.pixelSize: 10
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                visible: controller && (controller.det.awayLeaders || []).length > 0
                text: i18n("Points leaders (last 5 games)")
                font.pixelSize: 11
                font.bold: true
                opacity: 0.6
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: controller && (controller.det.awayLeaders || []).length > 0
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Repeater {
                        model: controller ? controller.det.awayLeaders : []
                        delegate: Label {
                            text: {
                                var val = modelData.value !== undefined ? modelData.value : '–'
                                var unit = ""
                                if (modelData.cat === 'points') unit = i18n("Points")
                                else if (modelData.cat === 'goals') unit = i18n("Goals")
                                else if (modelData.cat === 'assists') unit = i18n("Assists")
                                return modelData.name + " (" + val + " " + unit.toLowerCase() + ")"
                            }
                            font.pixelSize: 12
                            color: controller.teamColorAdapted(controller.det.away)
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
                Rectangle {
                    width: 1
                    Layout.fillHeight: true
                    color: Kirigami.Theme.textColor
                    opacity: 0.1
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Repeater {
                        model: controller ? controller.det.homeLeaders : []
                        delegate: Label {
                            text: {
                                var val = modelData.value !== undefined ? modelData.value : '–'
                                var unit = ""
                                if (modelData.cat === 'points') unit = i18n("Points")
                                else if (modelData.cat === 'goals') unit = i18n("Goals")
                                else if (modelData.cat === 'assists') unit = i18n("Assists")
                                return modelData.name + " (" + val + " " + unit.toLowerCase() + ")"
                            }
                            font.pixelSize: 12
                            color: controller.teamColorAdapted(controller.det.home)
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            Label {
                visible: controller && (controller.det.awayGoalie !== null || controller.det.homeGoalie !== null)
                Layout.alignment: Qt.AlignHCenter
                text: i18n("Probable goalies")
                font.pixelSize: 11
                font.bold: true
                opacity: 0.6
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20
                visible: controller && (controller.det.awayGoalie !== null || controller.det.homeGoalie !== null)
                ColumnLayout {
                    spacing: 0
                    Label {
                        text: controller && controller.det.awayGoalie ? controller.det.awayGoalie.name : '–'
                        font.bold: true
                        color: controller.teamColorAdapted(controller.det.away)
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Label {
                        text: controller && controller.det.awayGoalie ? controller.det.awayGoalie.record : ''
                        font.pixelSize: 10
                        opacity: 0.7
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
                ColumnLayout {
                    spacing: 0
                    Label {
                        text: controller && controller.det.homeGoalie ? controller.det.homeGoalie.name : '–'
                        font.bold: true
                        color: controller.teamColorAdapted(controller.det.home)
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Label {
                        text: controller && controller.det.homeGoalie ? controller.det.homeGoalie.record : ''
                        font.pixelSize: 10
                        opacity: 0.7
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // ── Tirs au but ───────────────────────────────────────────────────
            RowLayout {
                visible: controller && !controller.det.loading && controller.det.status !== 'UPCOMING' && controller.det.stats['sog'] !== undefined
                Layout.fillWidth: true
                spacing: 0
                Label {
                    text: (controller && controller.det.stats['sog']) ? String(controller.det.stats['sog'].away) : ''
                    font.pixelSize: 25
                    font.bold: true
                    color: controller ? controller.teamColorAdapted(controller.det.away) : "gray"
                    Layout.preferredWidth: 70
                    horizontalAlignment: Text.AlignHCenter
                }
                Label {
                    text: i18n('Shots on Goal')
                    font.pixelSize: 14
                    color: Kirigami.Theme.disabledTextColor
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
                Label {
                    text: (controller && controller.det.stats['sog']) ? String(controller.det.stats['sog'].home) : ''
                    font.pixelSize: 25
                    font.bold: true
                    color: controller ? controller.teamColorAdapted(controller.det.home) : "gray"
                    Layout.preferredWidth: 70
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Rectangle {
                visible: controller && !controller.det.loading && controller.det.status !== 'UPCOMING' && Object.keys(controller.det.stats).length > 0
                Layout.fillWidth: true
                height: 1
                radius: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: controller ? Logic.getTeamColor(controller.det.away) : "gray"
                    }
                    GradientStop {
                        position: 1.0
                        color: controller ? Logic.getTeamColor(controller.det.home) : "gray"
                    }
                }
                opacity: 0.6
            }

            ColumnLayout {
                visible: controller && !controller.det.loading && controller.det.status !== 'UPCOMING' && Object.keys(controller.det.stats).length > 0
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: {
                        if (!controller) return []
                        let order = ['faceoffWinningPctg','powerPlay','pim','hits','blockedShots','giveaways','takeaways']
                        let labels = { 'faceoffWinningPctg': i18n('Faceoffs %'), 'powerPlay': i18n('Power Play'), 'hits': i18n('Hits'), 'blockedShots': i18n('Blocks'), 'giveaways': i18n('Giveaways'), 'takeaways': i18n('Takeaways'), 'pim': i18n('PIM') }
                        let rows = []
                        for (let i = 0; i < order.length; i++) {
                            let k = order[i]; let entry = controller.det.stats[k]
                            if (entry === undefined) continue
                            let av = entry.away; let hv = entry.home; let avRaw = 0, hvRaw = 0; let avSub = '', hvSub = ''
                            if (k === 'powerPlay' && av !== null && typeof av === 'object') {
                                let ho = entry.home
                                avRaw = av.opportunities > 0 ? av.goals / av.opportunities : 0
                                hvRaw = ho.opportunities > 0 ? ho.goals / ho.opportunities : 0
                                avSub = av.opportunities > 0 ? (avRaw*100).toFixed(1) + '%' : '—'
                                hvSub = ho.opportunities > 0 ? (hvRaw*100).toFixed(1) + '%' : '—'
                                av = (av.goals||0) + '/' + (av.opportunities||0); hv = (ho.goals||0) + '/' + (ho.opportunities||0)
                            } else if (k === 'faceoffWinningPctg') {
                                avRaw = typeof av === 'number' ? av / 100 : 0; hvRaw = typeof hv === 'number' ? hv / 100 : 0
                                av = typeof av === 'number' ? av.toFixed(1) + '%' : String(av); hv = typeof hv === 'number' ? hv.toFixed(1) + '%' : String(hv)
                            } else {
                                let total = (parseFloat(av)||0) + (parseFloat(hv)||0)
                                avRaw = total > 0 ? (parseFloat(av)||0) / total : 0.5; hvRaw = total > 0 ? (parseFloat(hv)||0) / total : 0.5
                                av = String(av); hv = String(hv)
                            }
                            rows.push({ label: labels[k] || k, away: av, home: hv, awayRaw: avRaw, homeRaw: hvRaw, awaySub: avSub, homeSub: hvSub })
                        }
                        return rows
                    }
                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Label {
                                text: modelData.away
                                font.pixelSize: 16
                                font.bold: true
                                color: controller.teamColorAdapted(controller.det.away)
                                Layout.preferredWidth: 65
                                horizontalAlignment: Text.AlignLeft
                            }
                            Label {
                                text: modelData.label
                                font.pixelSize: 12
                                color: Kirigami.Theme.disabledTextColor
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }
                            Label {
                                text: modelData.home
                                font.pixelSize: 16
                                font.bold: true
                                color: controller.teamColorAdapted(controller.det.home)
                                Layout.preferredWidth: 65
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                        Item {
                            Layout.fillWidth: true
                            height: 4
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * modelData.awayRaw
                                color: Logic.getTeamColor(controller.det.away)
                                radius: 2
                            }
                            Rectangle {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * modelData.homeRaw
                                color: Logic.getTeamColor(controller.det.home)
                                radius: 2
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            visible: modelData.awaySub !== '' || modelData.homeSub !== ''
                            Label {
                                text: modelData.awaySub
                                font.pixelSize: 11
                                opacity: 0.55
                                color: Kirigami.Theme.disabledTextColor
                                Layout.preferredWidth: 65
                                horizontalAlignment: Text.AlignLeft
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            Label {
                                text: modelData.homeSub
                                font.pixelSize: 11
                                opacity: 0.55
                                color: Kirigami.Theme.disabledTextColor
                                Layout.preferredWidth: 65
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }

            // ── Onglets ────────────────────────────────────────────────────────
            RowLayout {
                visible: controller && !controller.det.loading && controller.det.status !== 'UPCOMING'
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                Label {
                    text: i18n("Goals")
                    font.bold: controller.det.view === 'goals'
                    font.pixelSize: 14
                    color: controller.det.view === 'goals' ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                    opacity: font.bold ? 1.0 : 0.45
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            controller.det.view = 'goals'
                        }
                    }
                }
                Label {
                    text: "·"
                    font.pixelSize: 14
                    opacity: 0.3
                    visible: controller && controller.det.penalties.length > 0
                }
                Label {
                    visible: controller && controller.det.penalties.length > 0
                    text: i18n("Penalties")
                    font.bold: controller.det.view === 'penalties'
                    font.pixelSize: 14
                    color: controller.det.view === 'penalties' ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                    opacity: font.bold ? 1.0 : 0.45
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            controller.det.view = 'penalties'
                        }
                    }
                }
                Label {
                    text: "·"
                    font.pixelSize: 14
                    opacity: 0.3
                    visible: controller && controller.det.threeStars.length > 0
                }
                Label {
                    visible: controller && controller.det.threeStars.length > 0
                    text: "⭐ " + i18n("Stars")
                    font.bold: controller.det.view === 'stars'
                    font.pixelSize: 14
                    color: controller.det.view === 'stars' ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                    opacity: font.bold ? 1.0 : 0.45
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            controller.det.view = 'stars'
                        }
                    }
                }
            }

            // ── Listes (Buts / Pénalités / Étoiles) ───────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                visible: controller && controller.det.view === 'goals'
                spacing: 4
                Repeater {
                    model: controller ? controller.det.goalsByPeriod : []
                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        RowLayout {
                            visible: !!modelData.isPeriodHeader
                            Rectangle {
                                height: 1
                                Layout.fillWidth: true
                                color: Kirigami.Theme.textColor
                                opacity: 0.1
                            }
                            Label {
                                text: modelData.label || ""
                                font.bold: true
                                font.pixelSize: 11
                                opacity: 0.5
                            }
                            Rectangle {
                                height: 1
                                Layout.fillWidth: true
                                color: Kirigami.Theme.textColor
                                opacity: 0.1
                            }
                        }
                        RowLayout {
                            visible: !modelData.isPeriodHeader && !modelData.isEmpty
                            spacing: 8
                            Rectangle {
                                width: 32
                                height: 18
                                radius: 3
                                color: Logic.getTeamColor(modelData.team || "")
                                Label {
                                    anchors.centerIn: parent
                                    text: modelData.team || ""
                                    color: Logic.getTeamTextColor(modelData.team || "")
                                    font.bold: true
                                    font.pixelSize: 10
                                }
                            }
                            Label {
                                text: modelData.time || ""
                                Layout.preferredWidth: 40
                                font.pixelSize: 11
                                opacity: 0.7
                            }
                            ColumnLayout {
                                spacing: 0
                                Label {
                                    text: (modelData.goalsToDate > 0 ? (modelData.scorer || "") + " (" + modelData.goalsToDate + ")" : (modelData.scorer || "")) + (modelData.ppg ? " PP" : "") + (modelData.shg ? " SH" : "") + (modelData.en ? " EN" : "")
                                    font.bold: true
                                    color: controller.teamColorAdapted(modelData.team || "")
                                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: {
                                            controller.openPlayer(modelData.scorerId, 'detail')
                                        }
                                    }
                                }
                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    visible: !!modelData.assists && modelData.assists.length > 0
                                    Label {
                                        text: i18n("Assists: ")
                                        font.pixelSize: 11
                                        opacity: 0.7
                                    }
                                    Repeater {
                                        model: modelData.assists || []
                                        delegate: Label {
                                            text: (modelData.name || "") + (modelData.assistsToDate > 0 ? " (" + modelData.assistsToDate + ")" : "") + (index < (modelData.parentModelCount - 1) ? "," : "")
                                            font.pixelSize: 11
                                            color: controller.teamColorAdapted(modelData.team || "")
                                            opacity: 0.9
                                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                                            TapHandler {
                                                onTapped: {
                                                    controller.openPlayer(modelData.id, 'detail')
                                                }
                                            }
                                        }
                                    }
                                }
                                Label {
                                    visible: !modelData.assists || modelData.assists.length === 0
                                    text: i18n("unassisted")
                                    font.pixelSize: 11
                                    font.italic: true
                                    opacity: 0.5
                                }
                            }
                        }
                        Label {
                            visible: !!modelData.isEmpty
                            text: modelData.label || ""
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            opacity: 0.4
                            font.italic: true
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: controller && controller.det.view === 'penalties'
                spacing: 4
                Repeater {
                    model: controller ? controller.det.penaltiesByPeriod : []
                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        RowLayout {
                            visible: !!modelData.isPeriodHeader
                            Rectangle {
                                height: 1
                                Layout.fillWidth: true
                                color: Kirigami.Theme.textColor
                                opacity: 0.1
                            }
                            Label {
                                text: modelData.label || ""
                                font.bold: true
                                font.pixelSize: 11
                                opacity: 0.5
                            }
                            Rectangle {
                                height: 1
                                Layout.fillWidth: true
                                color: Kirigami.Theme.textColor
                                opacity: 0.1
                            }
                        }
                        RowLayout {
                            visible: !modelData.isPeriodHeader
                            spacing: 8
                            Rectangle {
                                width: 32
                                height: 18
                                radius: 3
                                color: Logic.getTeamColor(modelData.team || "")
                                Label {
                                    anchors.centerIn: parent
                                    text: modelData.team || ""
                                    color: Logic.getTeamTextColor(modelData.team || "")
                                    font.bold: true
                                    font.pixelSize: 10
                                }
                            }
                            Label {
                                text: modelData.time || ""
                                Layout.preferredWidth: 40
                                font.pixelSize: 11
                                opacity: 0.7
                            }
                            ColumnLayout {
                                spacing: 0
                                Label {
                                    text: (modelData.player || "") + (modelData.number > 0 ? " #" + modelData.number : "")
                                    font.bold: true
                                    color: controller.teamColorAdapted(modelData.team || "")
                                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: {
                                            controller.openPlayer(modelData.playerId, 'detail')
                                        }
                                    }
                                }
                                Label {
                                    text: (controller ? controller.penaltyDesc(modelData.descKey || "") : "") + " (" + (modelData.duration || 0) + " min)"
                                    font.pixelSize: 11
                                    opacity: 0.7
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: controller && controller.det.view === 'stars'
                spacing: 8
                Repeater {
                    model: controller ? controller.det.threeStars : []
                    delegate: RowLayout {
                        spacing: 12
                        Label {
                            text: (modelData.star === 1 ? "🥇" : (modelData.star === 2 ? "🥈" : "🥉"))
                            font.pixelSize: 20
                        }
                        Rectangle {
                            width: 32
                            height: 18
                            radius: 3
                            color: Logic.getTeamColor(modelData.team || "")
                            Label {
                                anchors.centerIn: parent
                                text: modelData.team || ""
                                color: Logic.getTeamTextColor(modelData.team || "")
                                font.bold: true
                                font.pixelSize: 10
                            }
                        }
                        Label {
                            text: modelData.name || ""
                            font.bold: true
                            Layout.fillWidth: true
                            color: controller.teamColorAdapted(modelData.team || "")
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    controller.openPlayer(modelData.id, 'detail')
                                }
                            }
                        }
                        Label {
                            text: (modelData.goals >= 0 ? modelData.goals + "B " + modelData.assists + "A" : (modelData.toi || ""))
                            font.pixelSize: 12
                            opacity: 0.7
                        }
                    }
                }
            }
            
            Item {
                Layout.preferredHeight: 20
            }
        }
    }
}
