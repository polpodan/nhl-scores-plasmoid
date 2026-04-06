import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic
import "../components" as Components

Item {
    id: teamHubRoot
    property var controller
    
    property bool showCalendar: false

    anchors.fill: parent
    visible: !!(controller && controller.nav.teamHub)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Barre navigation ──
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.topMargin: 4
            Layout.bottomMargin: 2
            Button {
                text: teamHubRoot.showCalendar ? i18n("‹ Back") : ((controller && controller.hub.from === 'standings') ? i18n("‹ Standings") : i18n("‹ Match"))
                icon.name: "go-previous"
                flat: true
                onClicked: {
                    if (teamHubRoot.showCalendar) {
                        teamHubRoot.showCalendar = false
                    } else if (controller) {
                        controller.nav.teamHub = false
                        if (controller.hub.from === 'standings') {
                            controller.openStandings()
                        } else {
                            controller.nav.detail = true
                        }
                    }
                }
            }
            Item { Layout.fillWidth: true }
            Label {
                visible: teamHubRoot.showCalendar
                text: i18n("Season Calendar")
                font.bold: true
                Layout.rightMargin: 12
                color: Kirigami.Theme.textColor
            }
        }

        Components.StateLayer {
            loading: !!controller && controller.hub.loading
        }

        // ── CONTENU 1 : FICHE ÉQUIPE ──
        ScrollView {
            id: teamHubScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            visible: !!(controller && !controller.hub.loading && !teamHubRoot.showCalendar)

            Column {
                id: teamContentColumn
                width: teamHubScrollView.availableWidth
                spacing: 24

                // 1. En-tête (Logo + Nom)
                Column {
                    width: parent.width
                    spacing: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 20

                    Image {
                        source: controller ? controller.teamLogoUrl(controller.hub.code) : ""
                        width: 150
                        height: 150
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Label {
                        width: parent.width - 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (controller && controller.hub.fullName !== '') ? controller.hub.fullName : (controller ? controller.hub.code : "")
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        color: controller ? controller.teamColorAdapted(controller.hub.code) : Kirigami.Theme.textColor
                    }
                }

                // 2. Grille de statistiques
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20
                    Repeater {
                        model: [
                            { v: (controller ? String(controller.hub.gp) : "0"),  l: "GP"  },
                            { v: (controller ? String(controller.hub.w) : "0"),   l: "W"   },
                            { v: (controller ? String(controller.hub.l) : "0"),   l: "L"   },
                            { v: (controller ? String(controller.hub.ot) : "0"),  l: "OT"  },
                            { v: (controller ? String(controller.hub.pts) : "0"), l: "PTS" }
                        ]
                        delegate: Column {
                            spacing: 4
                            Label { 
                                text: modelData.l
                                font.pixelSize: 10
                                opacity: 0.6
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: Kirigami.Theme.textColor
                            }
                            Label { 
                                text: modelData.v
                                font.pixelSize: 20
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: Kirigami.Theme.textColor
                            }
                        }
                    }
                }

                // 3. Derniers matchs
                Column {
                    width: parent.width
                    spacing: 10
                    anchors.horizontalCenter: parent.horizontalCenter

                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: i18n("Last games")
                        font.pixelSize: 11
                        font.bold: true
                        opacity: 0.5
                        color: Kirigami.Theme.textColor
                    }

                    Repeater {
                        model: controller ? controller.hub.lastGames : []
                        delegate: Item {
                            width: teamContentColumn.width
                            height: 24
                            Row {
                                anchors.centerIn: parent
                                spacing: 12
                                Rectangle {
                                    radius: 3
                                    width: 40
                                    height: 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: modelData.win ? (modelData.ot ? "#1a6a3a" : "#1a7a2a") : (modelData.ot ? "#5a3a1a" : "#7a1a1a")
                                    Label { anchors.centerIn: parent; text: modelData.win ? (modelData.ot ? "OTW" : "W") : (modelData.ot ? "OTL" : "L"); color: "white"; font.bold: true; font.pixelSize: 10 }
                                }
                                Label { 
                                    text: modelData.home ? i18n("vs") : i18n("@")
                                    font.pixelSize: 11
                                    opacity: 0.5
                                    width: 20
                                    horizontalAlignment: Text.AlignHCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Kirigami.Theme.textColor
                                }
                                Rectangle {
                                    radius: 3
                                    color: Logic.getTeamColor(modelData.opp || "")
                                    width: 32
                                    height: 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    Label { anchors.centerIn: parent; text: modelData.opp || '?'; color: Logic.getTeamTextColor(modelData.opp || ''); font.bold: true; font.pixelSize: 10; font.family: "monospace" }
                                }
                                Label { 
                                    text: (modelData.gf || 0) + " – " + (modelData.ga || 0)
                                    font.pixelSize: 14
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Kirigami.Theme.textColor
                                }
                            }
                        }
                    }
                }

                // 4. Boutons d'actions
                Column {
                    width: Math.min(300, parent.width - 40)
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    bottomPadding: 20

                    Button {
                        width: parent.width
                        text: "📅 " + i18n("Season Calendar")
                        flat: true
                        onClicked: teamHubRoot.showCalendar = true
                    }
                    Button {
                        width: parent.width
                        text: "📜 " + i18n("Franchise Leaders")
                        flat: true
                        onClicked: { if (controller) controller.openFranchiseLeaders(controller.hub.code) }
                    }
                    Button {
                        width: parent.width
                        text: "📊 " + i18n("Stats")
                        flat: true
                        onClicked: { if (controller) controller.openSchedule(controller.hub.code, true) }
                    }
                }
            }
        }

        // ── CONTENU 2 : CALENDRIER SAISON ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: teamHubRoot.showCalendar && !controller.hub.loading
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 10
                Button { 
                    text: "‹"
                    flat: true
                    onClicked: { controller.cal.month--; if (controller.cal.month < 0) { controller.cal.month = 11; controller.cal.year-- } } 
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.bold: true
                    font.pixelSize: 15
                    text: {
                        var m = [i18n("January"),i18n("February"),i18n("March"),i18n("April"),i18n("May"),i18n("June"),i18n("July"),i18n("August"),i18n("September"),i18n("October"),i18n("November"),i18n("December")]
                        return m[controller.cal.month] + " " + controller.cal.year
                    }
                    color: Kirigami.Theme.textColor
                }
                Button { 
                    text: "›"
                    flat: true
                    onClicked: { controller.cal.month++; if (controller.cal.month > 11) { controller.cal.month = 0; controller.cal.year++ } } 
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Repeater {
                    model: [i18n("Su"),i18n("Mo"),i18n("Tu"),i18n("We"),i18n("Th"),i18n("Fr"),i18n("Sa")]
                    delegate: Label { text: modelData; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 12; font.bold: true; opacity: 0.6; color: Kirigami.Theme.textColor }
                }
            }

            ScrollView {
                id: calScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: availableWidth
                clip: true
                GridLayout {
                    width: calScroll.availableWidth
                    columns: 7
                    columnSpacing: 0
                    rowSpacing: 0
                    property int firstDow: new Date(controller.cal.year, controller.cal.month, 1).getDay()
                    property int daysInMonth: new Date(controller.cal.year, controller.cal.month + 1, 0).getDate()

                    Repeater { model: parent.firstDow; delegate: Item { Layout.fillWidth: true; implicitHeight: 65 } }
                    Repeater {
                        model: parent.daysInMonth
                        delegate: Rectangle {
                            id: dayCell
                            Layout.fillWidth: true
                            implicitHeight: 65
                            readonly property int day: index + 1
                            readonly property string iso: controller.cal.year + "-" + Logic.pad2(controller.cal.month + 1) + "-" + Logic.pad2(day)
                            readonly property var game: (controller && controller.sch.gamesMap) ? controller.sch.gamesMap[iso] : null
                            readonly property bool isHome: game ? (game.home === controller.sch.team) : false

                            // Fond adoptant le thème
                            color: Kirigami.Theme.backgroundColor

                            // Indicateur de couleur solide sur le côté (respecte la légende)
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 4
                                visible: !!game
                                color: isHome ? "#1a5fb4" : "#c01c28"
                            }

                            // Teinte légère pour la cellule
                            Rectangle {
                                anchors.fill: parent
                                visible: !!game
                                color: isHome ? "#1a5fb4" : "#c01c28"
                                opacity: 0.1
                            }

                            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                            border.width: 1

                            Label { 
                                anchors.top: parent.top; anchors.left: parent.left; anchors.leftMargin: 8; anchors.topMargin: 3
                                text: String(day)
                                font.pixelSize: 11
                                font.bold: !!game
                                opacity: game ? 1.0 : 0.3
                                color: Kirigami.Theme.textColor
                            }
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 1
                                visible: !!game

                                Image {
                                    Layout.preferredWidth: 42
                                    Layout.preferredHeight: 42
                                    Layout.alignment: Qt.AlignHCenter
                                    source: {
                                        if (!game) return ""
                                        var opp = isHome ? game.away : game.home
                                        return controller.teamLogoUrl(opp)
                                    }
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }

                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: game ? (game.isFinal ? (game.result + " " + (isHome ? (game.hg + "-" + game.ag) : (game.ag + "-" + game.hg))) : Qt.formatTime(new Date(game.startMs), "hh:mm")) : ""
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: game && game.isFinal ? (game.result.indexOf('W')!==-1 ? "#44ff44" : "#ff4444") : Kirigami.Theme.textColor
                                    style: Text.Outline
                                    styleColor: Qt.rgba(0, 0, 0, 0.5)
                                }
                            }
                            TapHandler { enabled: !!game; onTapped: controller.openDetail(game.gameId, game.away, game.home, game.ag, game.hg, game.isFinal?'FINAL':(game.isLive?'LIVE':'UPCOMING'), '', 0, '', game.startMs, false, '1551') }
                        }
                    }
                }
            }

            // Légende
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 10
                Layout.alignment: Qt.AlignHCenter
                spacing: 20
                visible: teamHubRoot.showCalendar

                Row {
                    spacing: 5
                    Rectangle { width: 12; height: 12; color: "#1a5fb4"; radius: 2; opacity: 0.5; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: i18n("Home"); font.pixelSize: 10; color: Kirigami.Theme.textColor }
                }
                Row {
                    spacing: 5
                    Rectangle { width: 12; height: 12; color: "#c01c28"; radius: 2; opacity: 0.5; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: i18n("Away"); font.pixelSize: 10; color: Kirigami.Theme.textColor }
                }
            }
        }
    }
}
