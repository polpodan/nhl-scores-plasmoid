import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../../logic.js" as Logic
import "../../components" as Components

ColumnLayout {
    id: previewRoot
    property var controller

    visible: controller && controller.det && !controller.det.loading && controller.det.status === 'UPCOMING'
    Layout.fillWidth: true
    Layout.topMargin: 15
    spacing: 15

    // 1. Comparison de saison
    ColumnLayout {
        visible: controller && controller.det && !!controller.det.teamComparison && controller.det.teamComparison.length > 0
        Layout.fillWidth: true
        spacing: 8
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 24; color: Qt.rgba(1,1,1,0.04); radius: 4
            Label { anchors.centerIn: parent; text: i18n("Season Comparison"); font.pixelSize: 11; font.bold: true; opacity: 0.6 }
        }
        Repeater {
            model: (controller && controller.det) ? controller.det.teamComparison : []
            delegate: Components.StatComparisonBar {
                Layout.fillWidth: true
                label: {
                    if (modelData.label === "ppPctg") return i18n("Power Play %")
                    if (modelData.label === "pkPctg") return i18n("Penalty Kill %")
                    if (modelData.label === "faceoffWinPctg") return i18n("Faceoffs %")
                    if (modelData.label === "goalsForPerGame") return i18n("GF/G")
                    if (modelData.label === "goalsAgainstPerGame") return i18n("GA/G")
                    return modelData.label
                }
                awayValue: {
                    var val = modelData.away
                    if (modelData.label.indexOf('Pct') !== -1) return (val <= 1.0 ? (val * 100).toFixed(1) : Number(val).toFixed(1)) + "%"
                    return Number(val).toFixed(2)
                }
                homeValue: {
                    var val = modelData.home
                    if (modelData.label.indexOf('Pct') !== -1) return (val <= 1.0 ? (val * 100).toFixed(1) : Number(val).toFixed(1)) + "%"
                    return Number(val).toFixed(2)
                }
                awayRaw: parseFloat(modelData.away)
                homeRaw: parseFloat(modelData.home)
                awayColor: (controller && controller.det) ? controller.teamColorAdapted(controller.det.away, controller.det.home, true, false) : "gray"
                homeColor: (controller && controller.det) ? controller.teamColorAdapted(controller.det.home, controller.det.away, false, false) : "gray"
            }
        }
    }

    // 2. Face-à-face (H2H)
    ColumnLayout {
        visible: controller && controller.det && (controller.det.h2hGames && controller.det.h2hGames.length > 0)
        Layout.fillWidth: true
        spacing: 12

        // ── SECTION SÉRIES ÉLIMINATOIRES ──
        ColumnLayout {
            visible: controller && controller.det && controller.det.isPlayoff
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 24; color: Kirigami.Theme.highlightColor; radius: 4; opacity: 0.2
                Label { anchors.centerIn: parent; text: i18n("Playoff series"); font.pixelSize: 11; font.bold: true }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: 4
                Label { Layout.alignment: Qt.AlignHCenter; text: controller.det.seriesRound; font.pixelSize: 12; font.bold: true; opacity: 0.8 }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter; spacing: 8
                    Label { 
                        text: {
                            if (!controller || !controller.det) return ""
                            if (controller.det.seriesAwayPlayoffs > controller.det.seriesHomePlayoffs) return controller.det.away + " mène"
                            if (controller.det.seriesHomePlayoffs > controller.det.seriesAwayPlayoffs) return controller.det.home + " mène"
                            return "Égalité"
                        }
                        font.pixelSize: 13 
                    }
                    Label { text: controller.det.seriesAwayPlayoffs + " – " + controller.det.seriesHomePlayoffs; font.pixelSize: 22; font.bold: true }
                    Button { text: "🏆"; flat: true; onClicked: if (controller) controller.openPlayoffBracket() }
                }
            }

            // Liste des matchs de séries uniquement
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Repeater {
                    model: controller.det.h2hGames.filter(function(g){ return g.isPlayoff })
                    delegate: h2hDelegate
                }
            }
        }

        // ── SECTION SAISON RÉGULIÈRE ──
        ColumnLayout {
            visible: controller && controller.det && (controller.det.h2hSeason && controller.det.h2hSeason.length > 0)
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 24; color: Qt.rgba(1,1,1,0.04); radius: 4
                Label { anchors.centerIn: parent; text: i18n("Regular season series"); font.pixelSize: 11; font.bold: true; opacity: 0.6 }
            }

            // Résumé victoires saison régulière
            Components.StatComparisonBar {
                Layout.fillWidth: true
                label: i18n("Wins")
                awayValue: controller.det.seriesAwaySeason
                homeValue: controller.det.seriesHomeSeason
                awayColor: controller.teamColorAdapted(controller.det.away, controller.det.home, true, false)
                homeColor: controller.teamColorAdapted(controller.det.home, controller.det.away, false, false)
            }

            // Liste des matchs de saison régulière uniquement
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Repeater {
                    model: controller.det.h2hSeason
                    delegate: h2hDelegate
                }
            }
        }
    }

    // Delegate pour les lignes de match H2H
    Component {
        id: h2hDelegate
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 30
            radius: 4
            color: h2hMouse.hovered ? Qt.rgba(1,1,1,0.05) : "transparent"
            HoverHandler { id: h2hMouse }
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                Label { text: modelData.date ? Qt.formatDate(new Date(modelData.date), "dd/MM") : ""; font.pixelSize: 10; opacity: 0.5; Layout.preferredWidth: 35 }
                Item { width: 24; height: 16; Image { anchors.fill: parent; source: controller.teamLogoUrl(modelData.away); fillMode: Image.PreserveAspectFit; smooth: true } }
                Label { text: modelData.final ? (modelData.awayScore + " – " + modelData.homeScore) : i18n("vs"); font.pixelSize: 12; font.bold: modelData.final; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                Item { width: 24; height: 16; Image { anchors.fill: parent; source: controller.teamLogoUrl(modelData.home); fillMode: Image.PreserveAspectFit; smooth: true } }
                Label { visible: modelData.final; text: (modelData.awayScore > modelData.homeScore) ? modelData.away : modelData.home; font.pixelSize: 10; font.bold: true; color: Logic.getTeamColor((modelData.awayScore > modelData.homeScore) ? modelData.away : modelData.home, Kirigami.Theme.backgroundColor); Layout.preferredWidth: 35; horizontalAlignment: Text.AlignRight }
                Item { visible: !modelData.final; Layout.preferredWidth: 35 }
            }
        }
    }

    // 3. Meneurs de points
    ColumnLayout {
        visible: controller && controller.det && (controller.det.awayLeaders || []).length > 0
        Layout.fillWidth: true
        spacing: 6
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 24; color: Qt.rgba(1,1,1,0.04); radius: 4
            Label { anchors.centerIn: parent; text: i18n("Points leaders (last 5 games)"); font.pixelSize: 11; font.bold: true; opacity: 0.6 }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Repeater {
                    model: (controller && controller.det) ? (controller.det.awayLeaders || []) : []
                    delegate: Label {
                        text: {
                            var suffix = ""
                            if (modelData.cat === 'goals') suffix = " " + i18n("G")
                            else if (modelData.cat === 'assists') suffix = " " + i18n("A")
                            else suffix = " " + i18n("PTS")
                            return modelData.name + " (" + modelData.value + suffix + ")"
                        }
                        font.pixelSize: 12; 
                        color: (controller && controller.det) ? controller.teamColorAdapted(controller.det.away, controller.det.home, true, true) : Kirigami.Theme.textColor
                        elide: Text.ElideRight; Layout.fillWidth: true
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: if (controller && modelData.id) controller.openPlayer(modelData.id, 'detail')
                        }
                    }
                }
            }
            Rectangle { width: 1; Layout.fillHeight: true; color: Kirigami.Theme.textColor; opacity: 0.1 }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Repeater {
                    model: (controller && controller.det) ? (controller.det.homeLeaders || []) : []
                    delegate: Label {
                        text: {
                            var suffix = ""
                            if (modelData.cat === 'goals') suffix = " " + i18n("G")
                            else if (modelData.cat === 'assists') suffix = " " + i18n("A")
                            else suffix = " " + i18n("PTS")
                            return modelData.name + " (" + modelData.value + suffix + ")"
                        }
                        font.pixelSize: 12; 
                        color: (controller && controller.det) ? controller.teamColorAdapted(controller.det.home, controller.det.away, false, true) : Kirigami.Theme.textColor
                        elide: Text.ElideRight; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: if (controller && modelData.id) controller.openPlayer(modelData.id, 'detail')
                        }
                    }
                }
            }
        }
    }

    // 4. Gardiens probables
    ColumnLayout {
        visible: controller && controller.det && (controller.det.awayGoalie !== null || controller.det.homeGoalie !== null)
        Layout.fillWidth: true
        spacing: 6
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 24; color: Qt.rgba(1,1,1,0.04); radius: 4
            Label { anchors.centerIn: parent; text: i18n("Probable goalies"); font.pixelSize: 11; font.bold: true; opacity: 0.6 }
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter; spacing: 40
            ColumnLayout {
                spacing: 0; Layout.alignment: Qt.AlignHCenter
                Label {
                    text: (controller && controller.det && controller.det.awayGoalie) ? controller.det.awayGoalie.name : '–'
                    font.bold: true; 
                    color: (controller && controller.det) ? controller.teamColorAdapted(controller.det.away, controller.det.home, true, true) : Kirigami.Theme.textColor
                    Layout.alignment: Qt.AlignHCenter
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: if (controller && controller.det && controller.det.awayGoalie && controller.det.awayGoalie.id) controller.openPlayer(controller.det.awayGoalie.id, 'detail')
                    }
                }
                Label { text: (controller && controller.det && controller.det.awayGoalie) ? controller.det.awayGoalie.record : ''; font.pixelSize: 10; opacity: 0.7; Layout.alignment: Qt.AlignHCenter }
            }
            ColumnLayout {
                spacing: 0; Layout.alignment: Qt.AlignHCenter
                Label {
                    text: (controller && controller.det && controller.det.homeGoalie) ? controller.det.homeGoalie.name : '–'
                    font.bold: true; 
                    color: (controller && controller.det) ? controller.teamColorAdapted(controller.det.home, controller.det.away, false, true) : Kirigami.Theme.textColor
                    Layout.alignment: Qt.AlignHCenter
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: if (controller && controller.det && controller.det.homeGoalie && controller.det.homeGoalie.id) controller.openPlayer(controller.det.homeGoalie.id, 'detail')
                    }
                }
                Label { text: (controller && controller.det && controller.det.homeGoalie) ? controller.det.homeGoalie.record : ''; font.pixelSize: 10; opacity: 0.7; Layout.alignment: Qt.AlignHCenter }
            }
        }
    }
}
