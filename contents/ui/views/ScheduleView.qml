import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic
import "../components" as Components

Item {
    id: scheduleRoot
    property var controller

    // Fonction de comparaison de jour (portée locale)
    function isSameDay(d1, d2) {
        return d1.getFullYear() === d2.getFullYear() &&
               d1.getMonth() === d2.getMonth() &&
               d1.getDate() === d2.getDate()
    }

    anchors.fill: parent
    visible: !!(controller && controller.nav.schedule && !controller.nav.player)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Barre navigation : [‹ Back]  [🏒 TEAM Titre]  [Stats / Calendrier]
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            Layout.topMargin: 4
            Layout.bottomMargin: 2
            spacing: 4

            Button {
                text: (controller && controller.nav.teamHub) ? i18n("‹ Team") : i18n("‹ Back")
                icon.name: "go-previous"
                flat: true
                onClicked: {
                    if (controller) {
                        controller.nav.schedule = false
                        controller.nav.scheduleShowStats = false
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 6
                Layout.alignment: Qt.AlignHCenter
                Image {
                    id: teamLogoImg
                    source: (controller && controller.sch.team) ? controller.historicalTeamLogoUrl(controller.sch.team, controller.sch.season) : ""
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 96
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    
                    onStatusChanged: {
                        if (status === Image.Error && controller && controller.sch.team) {
                            // Si le logo historique échoue (404), on affiche le logo de l'équipe actuelle
                            source = controller.teamLogoUrl(controller.sch.team)
                        }
                    }
                }
                Column {
                    Layout.alignment: Qt.AlignVCenter
                    Label {
                        text: {
                            var hist = (controller && controller.sch.team) ? controller.getHistoricalTeamName(controller.sch.team, controller.sch.season) : ""
                            if (hist !== "") return hist
                            return i18n("Stats")
                        }
                        font.bold: true
                        font.pixelSize: 15
                    }
                    Label {
                        visible: (controller && controller.sch.team && controller.getHistoricalTeamName(controller.sch.team, controller.sch.season) !== "")
                        text: i18n("Stats")
                        font.pixelSize: 10
                        opacity: 0.6
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Le bouton de bascule a été supprimé ici pour éviter les doublons avec le Hub d'équipe.
        }

        // Gestion de l'état (Chargement / Erreur du calendrier)
        Components.StateLayer {
            loading: !!controller && controller.sch.loading
            error: controller ? controller.sch.error : ""
        }

        // ── Liste des matchs (mode calendrier) ──────────────────────
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !!(controller && !controller.nav.scheduleShowStats && !controller.sch.loading && controller.sch.error === "")
            contentWidth: availableWidth
            clip: true

            ListView {
                id: schedListView
                anchors.fill: parent
                model: controller ? controller.sch.games : []
                spacing: 0

                delegate: Item {
                    width: schedListView.width
                    height: schedRow.implicitHeight + 10

                    readonly property bool isToday: modelData.startMs > 0 && scheduleRoot.isSameDay(new Date(modelData.startMs), new Date())
                    readonly property bool isPast: modelData.isFinal

                    Rectangle {
                        anchors.fill: parent
                        color: isToday ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.12) : "transparent"
                        radius: 4
                    }

                    RowLayout {
                        id: schedRow
                        width: Math.min(340, parent.width - 16)
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        opacity: isPast ? 0.65 : 1.0

                        Label {
                            text: modelData.startMs > 0 ? Qt.formatDate(new Date(modelData.startMs), "dd MMM") : "–"
                            font.pixelSize: 14
                            color: Kirigami.Theme.disabledTextColor
                            Layout.preferredWidth: 42
                        }

                        RowLayout {
                            spacing: 4
                            Label {
                                text: (controller && modelData.home === controller.sch.team) ? i18n("vs") : i18n("@")
                                font.pixelSize: 12
                                opacity: 0.6
                                color: Kirigami.Theme.textColor
                            }
                            Rectangle {
                                radius: 3
                                width: oppLbl.implicitWidth + 8
                                height: oppLbl.implicitHeight + 4
                                color: (controller && modelData.home === controller.sch.team) ? Logic.getTeamColor(modelData.away) : Logic.getTeamColor(modelData.home)
                                Label {
                                    id: oppLbl
                                    anchors.centerIn: parent
                                    text: (controller && modelData.home === controller.sch.team) ? modelData.away : modelData.home
                                    color: (controller && modelData.home === controller.sch.team) ? Logic.getTeamTextColor(modelData.away) : Logic.getTeamTextColor(modelData.home)
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.family: "monospace"
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Label {
                            visible: modelData.isFinal && modelData.ag >= 0
                            text: modelData.away + "  " + modelData.ag + " – " + modelData.hg + "  " + modelData.home
                            font.pixelSize: 14
                            font.bold: true
                            color: Kirigami.Theme.textColor
                        }
                        Label {
                            visible: modelData.isLive
                            text: i18n("LIVE")
                            font.pixelSize: 14
                            font.bold: true
                            color: controller ? controller.liveColor : "red"
                        }
                        Label {
                            visible: !modelData.isFinal && !modelData.isLive
                            text: modelData.startMs > 0 ? Qt.formatTime(new Date(modelData.startMs), "hh:mm") : "–"
                            font.pixelSize: 14
                            color: Kirigami.Theme.disabledTextColor
                        }

                        Rectangle {
                            visible: modelData.result !== ''
                            radius: 3
                            width: resultLbl.implicitWidth + 8
                            height: resultLbl.implicitHeight + 4
                            color: (modelData.result === 'W' || modelData.result === 'OTW') ? Kirigami.Theme.positiveBackgroundColor : Qt.rgba(Kirigami.Theme.negativeTextColor.r, Kirigami.Theme.negativeTextColor.g, Kirigami.Theme.negativeTextColor.b, 0.25)
                            Label {
                                id: resultLbl
                                anchors.centerIn: parent
                                text: modelData.result
                                font.pixelSize: 12
                                font.bold: true
                                color: (modelData.result === 'W' || modelData.result === 'OTW') ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                            }
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: Kirigami.Theme.textColor
                        opacity: 0.08
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: !!(controller && !controller.sch.loading && controller.sch.games.length === 0)
                    text: i18n("No games")
                    opacity: 0.5
                    font.italic: true
                }
            }
        }

        // ── Vue stats joueurs (mode stats) ─────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !!(controller && controller.nav.scheduleShowStats)
            spacing: 0

            // ── Filtres Saison et Type ──
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                Layout.bottomMargin: 8
                spacing: 10
                visible: !!(controller && !controller.sch.statsLoading)

                ComboBox {
                    id: teamSeasonCombo
                    implicitWidth: 100
                    font.pixelSize: 11
                    model: {
                        if (!controller || !controller.sch.team) return []
                        var list = []
                        var now = new Date()
                        var endYear = now.getFullYear()
                        if (now.getMonth() < 8) endYear-- 
                        
                        var foundingYear = Logic.getTeamFoundingYear(controller.sch.team)

                        for (var y = endYear; y >= foundingYear; y--) {
                            var sStart = y
                            var sEnd = y + 1
                            list.push({
                                label: sStart + "-" + String(sEnd).substring(2),
                                value: sStart + String(sEnd)
                            })
                        }
                        return list
                    }
                    textRole: "label"
                    currentIndex: {
                        if (!controller) return 0
                        for (var i=0; i<model.length; i++) {
                            if (model[i].value === controller.sch.season) return i
                        }
                        return 0
                    }
                    onActivated: (index) => {
                        if (controller) {
                            controller.sch.season = model[index].value
                            controller.fetchTeamStats(controller.sch.team)
                        }
                    }
                }

                Row {
                    spacing: 2
                    Repeater {
                        model: [
                            { lbl: i18n("Reg"), val: 2 },
                            { lbl: i18n("Post"), val: 3 }
                        ]
                        delegate: Rectangle {
                            radius: 4
                            implicitWidth: typeLbl.implicitWidth + 12
                            implicitHeight: teamSeasonCombo.height
                            readonly property bool active: !!(controller && controller.sch.seasonType === modelData.val)
                            color: active ? Kirigami.Theme.highlightColor : Qt.rgba(1,1,1,0.07)
                            border.color: active ? Kirigami.Theme.highlightColor : Qt.rgba(1,1,1,0.15)
                            border.width: 1
                            Label {
                                id: typeLbl; anchors.centerIn: parent
                                text: modelData.lbl
                                font.pixelSize: 11; font.bold: parent.active
                                color: parent.active ? "white" : Kirigami.Theme.textColor
                            }
                            TapHandler {
                                onTapped: {
                                    if (controller) {
                                        controller.sch.seasonType = modelData.val
                                        controller.fetchTeamStats(controller.sch.team)
                                    }
                                }
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }

            // Gestion de l'état (Chargement / Erreur des stats)
            Components.StateLayer {
                Layout.fillWidth: true
                Layout.fillHeight: true
                loading: !!controller && controller.sch.statsLoading
                error: controller ? controller.sch.statsError : ""
                topMargin: 0
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !!(controller && !controller.sch.statsLoading && controller.sch.statsError === "")
                contentWidth: availableWidth
                clip: true

                ListView {
                    id: statsListView
                    anchors.fill: parent
                    model: controller ? (controller.sch.skaters.length + controller.sch.goalies.length + (controller.sch.goalies.length > 0 ? 1 : 0)) : 0
                    spacing: 0

                    header: Item {
                        width: statsListView.width
                        height: statsHeaderRow.implicitHeight + 6
                        RowLayout {
                            id: statsHeaderRow
                            width: Math.min(360, statsListView.width - 16)
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0
                            Item { Layout.preferredWidth: 16 }
                            Item { Layout.preferredWidth: 4 }
                            Label { text: i18n("Player"); font.pixelSize: 12; font.bold: true; opacity: 0.6; Layout.fillWidth: true }
                            Label { text: i18n("PJ"); font.pixelSize: 12; font.bold: true; opacity: 0.6; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                            Label { text: i18n("B"); font.pixelSize: 12; font.bold: true; opacity: 0.6; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                            Label { text: i18n("A"); font.pixelSize: 12; font.bold: true; opacity: 0.6; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                            Label { text: i18n("PTS"); font.pixelSize: 12; font.bold: true; opacity: 0.6; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignHCenter }
                            Label { text: i18n("+/-"); font.pixelSize: 12; font.bold: true; opacity: 0.6; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignHCenter }
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Kirigami.Theme.textColor
                            opacity: 0.2
                        }
                    }

                    delegate: Item {
                        id: statsDelegate
                        width: statsListView.width
                        readonly property int nSkaters: controller ? controller.sch.skaters.length : 0
                        readonly property int nGoalies: controller ? controller.sch.goalies.length : 0
                        readonly property bool isSep: index === nSkaters
                        readonly property bool isGoalie: !isSep && index > nSkaters
                        readonly property int skaterIdx: index
                        readonly property int goalieIdx: index - nSkaters - 1
                        readonly property var skater: (!isSep && !isGoalie && index < nSkaters && controller) ? controller.sch.skaters[skaterIdx] : null
                        readonly property var goalie: (isGoalie && goalieIdx >= 0 && goalieIdx < nGoalies && controller) ? controller.sch.goalies[goalieIdx] : null

                        height: isSep ? sepRow.implicitHeight + 10 : (isGoalie ? goalieRow.implicitHeight + 8 : skaterRow.implicitHeight + 8)

                        ColumnLayout {
                            id: sepRow
                            visible: isSep
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 8
                                Layout.rightMargin: 8
                                spacing: 8
                                Rectangle { height: 1; Layout.fillWidth: true; color: Kirigami.Theme.textColor; opacity: 0.2 }
                                Label { text: i18n("Goalies"); font.pixelSize: 12; font.bold: true; opacity: 0.6; color: Kirigami.Theme.disabledTextColor }
                                Rectangle { height: 1; Layout.fillWidth: true; color: Kirigami.Theme.textColor; opacity: 0.2 }
                            }
                            Item {
                                Layout.fillWidth: true
                                height: goalieSubHeaderRow.implicitHeight + 4
                                RowLayout {
                                    id: goalieSubHeaderRow
                                    width: Math.min(360, statsListView.width - 16)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    spacing: 0
                                    Item { Layout.preferredWidth: 16 }
                                    Item { Layout.preferredWidth: 4 }
                                    Label { text: i18n("Player"); font.pixelSize: 12; font.bold: true; opacity: 0.6; color: Kirigami.Theme.disabledTextColor; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                                    Label { text: i18n("PJ"); font.pixelSize: 12; font.bold: true; opacity: 0.6; color: Kirigami.Theme.disabledTextColor; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                                    Label { text: i18n("W"); font.pixelSize: 12; font.bold: true; opacity: 0.6; color: Kirigami.Theme.disabledTextColor; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                                    Label { text: i18n("L"); font.pixelSize: 12; font.bold: true; opacity: 0.6; color: Kirigami.Theme.disabledTextColor; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                                    Label { text: i18n("GAA"); font.pixelSize: 12; font.bold: true; opacity: 0.6; color: Kirigami.Theme.disabledTextColor; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignHCenter }
                                    Label { text: i18n("SV%"); font.pixelSize: 12; font.bold: true; opacity: 0.6; color: Kirigami.Theme.disabledTextColor; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignHCenter }
                                }
                            }
                        }

                        RowLayout {
                            id: skaterRow
                            visible: !isSep && !isGoalie && skater !== null
                            width: Math.min(360, statsListView.width - 16)
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0
                            Label { text: skater ? skater.pos : ''; font.pixelSize: 11; font.bold: true; opacity: 0.5; color: Kirigami.Theme.disabledTextColor; Layout.preferredWidth: 16; horizontalAlignment: Text.AlignHCenter }
                            Item { Layout.preferredWidth: 4 }
                            Label { text: skater ? skater.name : ''; font.pixelSize: 14; color: Kirigami.Theme.textColor; elide: Text.ElideRight; Layout.fillWidth: true }
                            Label { text: skater ? skater.gp : ''; font.pixelSize: 14; opacity: 0.35; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                            Label { text: skater ? skater.g : ''; font.pixelSize: 14; color: Kirigami.Theme.textColor; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                            Label { text: skater ? skater.a : ''; font.pixelSize: 14; color: Kirigami.Theme.textColor; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                            Label { text: skater ? skater.pts : ''; font.pixelSize: 15; font.bold: true; color: Kirigami.Theme.textColor; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignHCenter }
                            Label { text: skater ? (skater.plusMinus >= 0 ? '+' + skater.plusMinus : skater.plusMinus) : ''; font.pixelSize: 14; color: skater ? (skater.plusMinus > 0 ? Kirigami.Theme.positiveTextColor : (skater.plusMinus < 0 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.disabledTextColor)) : "transparent"; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignHCenter }
                            
                            TapHandler { 
                                enabled: skater !== null && (skater.id || 0) > 0
                                onTapped: controller.openPlayer(skater.id, 'teamstats') 
                            }
                            HoverHandler {
                                enabled: skater !== null && (skater.id || 0) > 0
                                cursorShape: Qt.PointingHandCursor
                            }
                        }

                        RowLayout {
                            id: goalieRow
                            visible: isGoalie && goalie !== null
                            width: Math.min(360, statsListView.width - 16)
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0
                            Label { text: 'G'; font.pixelSize: 11; font.bold: true; opacity: 0.5; color: Kirigami.Theme.disabledTextColor; Layout.preferredWidth: 16; horizontalAlignment: Text.AlignHCenter }
                            Item { Layout.preferredWidth: 4 }
                            Label { text: goalie ? goalie.name : ''; font.pixelSize: 14; color: Kirigami.Theme.textColor; elide: Text.ElideRight; Layout.fillWidth: true }
                            Label { text: goalie ? goalie.gp : ''; font.pixelSize: 14; opacity: 0.35; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                            Label { text: goalie ? goalie.wins : ''; font.pixelSize: 14; color: Kirigami.Theme.positiveTextColor; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                            Label { text: goalie ? goalie.losses : ''; font.pixelSize: 14; color: Kirigami.Theme.negativeTextColor; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                            Label { text: goalie ? goalie.gaa : ''; font.pixelSize: 14; color: Kirigami.Theme.textColor; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignHCenter }
                            Label { text: goalie ? Number(goalie.svPct).toFixed(3) : ''; font.pixelSize: 14; font.bold: true; color: Kirigami.Theme.textColor; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignHCenter }
                            
                            TapHandler { 
                                enabled: goalie !== null && (goalie.id || 0) > 0
                                onTapped: controller.openPlayer(goalie.id, 'teamstats') 
                            }
                            HoverHandler {
                                enabled: goalie !== null && (goalie.id || 0) > 0
                                cursorShape: Qt.PointingHandCursor
                            }
                        }

                        Rectangle {
                            visible: !isSep
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Kirigami.Theme.textColor
                            opacity: 0.06
                        }
                    }
                }
            }
        }
    }
}
