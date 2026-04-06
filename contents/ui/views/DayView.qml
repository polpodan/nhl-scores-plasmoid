import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic
import "../components" as Components

Item {
    id: dayViewRoot
    property var controller

    anchors.fill: parent
    visible: !!(controller && controller.nav.dayView)

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
                text: i18n('✕')
                flat: true
                onClicked: {
                    if (controller) {
                        controller.nav.dayView = false
                        controller.expanded = false
                    }
                }
            }
            Item {
                Layout.fillWidth: true
            }
            Label {
                text: {
                    if (!controller || !controller.day.date) return ""
                    var parts = controller.day.date.split('-')
                    if (parts.length === 3) {
                        var d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
                        return controller.localeDateLong(d.getTime())
                    }
                    return controller.day.date
                }
                font.bold: true
                font.pixelSize: 15
                Layout.alignment: Qt.AlignHCenter
                color: Kirigami.Theme.textColor
            }
            Item {
                Layout.fillWidth: true
            }
            Button {
                text: "📅  " + i18n("Calendar")
                flat: true
                onClicked: {
                    if (controller) {
                        controller.nav.calendar = true
                    }
                }
            }
        }

        // Gestion de l'état (Chargement / Erreur)
        Components.StateLayer {
            loading: !!controller && controller.day.loading
            error: {
                if (!controller) return ""
                if (controller.day.error !== "") return controller.day.error
                if (!controller.day.loading && controller.day.games.length === 0) return i18n("No games")
                return ""
            }
        }

        ScrollView {
            id: dayViewScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            visible: !!(controller && !controller.day.loading && controller.day.error === "")

            Column {
                id: dayViewCol
                width: dayViewScrollView.availableWidth
                spacing: 8
                topPadding: 10
                bottomPadding: 20

                Repeater {
                    model: controller ? controller.day.games : []
                    delegate: Rectangle {
                        width: Math.min(360, parent.width - 20)
                        height: 56
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: 8
                        color: {
                            if (modelData.status === 'LIVE') return Qt.rgba(0.0, 0.55, 0.1, 0.13)
                            if (modelData.status === 'FINAL') return Qt.rgba(0.5, 0.5, 0.5, 0.08)
                            return Qt.rgba(0.3, 0.5, 0.9, 0.10)
                        }
                        border.color: {
                            if (modelData.status === 'LIVE') return Qt.rgba(0.0, 0.7, 0.1, 0.35)
                            if (modelData.status === 'FINAL') return Qt.rgba(0.5, 0.5, 0.5, 0.2)
                            return Qt.rgba(0.3, 0.5, 0.9, 0.25)
                        }
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            // Away Team
                            Item {
                                width: awayBadge.width; height: awayBadge.height; Layout.alignment: Qt.AlignVCenter
                                Rectangle {
                                    id: awayBadge
                                    visible: !controller.showLogos
                                    radius: 3
                                    color: Logic.getTeamColor(modelData.away)
                                    width: 42
                                    height: 24
                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData.away
                                        color: Logic.getTeamTextColor(modelData.away)
                                        font.bold: true
                                        font.pixelSize: 13
                                        font.family: "monospace"
                                    }
                                }
                                Image {
                                    visible: controller.showLogos
                                    anchors.fill: parent
                                    source: controller.showLogos ? controller.teamLogoUrl(modelData.away) : ""
                                    sourceSize.width: width * 2
                                    sourceSize.height: height * 2
                                    fillMode: Image.PreserveAspectFit; smooth: true
                                }
                            }

                            // Info centrale
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: {
                                        if (modelData.status === 'UPCOMING') {
                                            return controller ? controller.dayViewTimeLabel(new Date(modelData.start).getTime(), modelData.homeAbbrev || modelData.home) : ""
                                        }
                                        return modelData.ag + " – " + modelData.hg
                                    }
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: Kirigami.Theme.textColor
                                }
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: {
                                        if (modelData.status === 'UPCOMING') {
                                            return (controller && controller.dateMode === 'venue') ? "(" + i18n("arena") + ")" : "(" + i18n("local") + ")"
                                        }
                                        if (modelData.status === 'FINAL') return i18n("Final")
                                        if (modelData.inIntermission) return "INT"
                                        var per = (controller ? controller.livePeriodText(modelData.periodType, modelData.period) : "")
                                        return per + (modelData.remain ? " " + modelData.remain : "")
                                    }
                                    font.pixelSize: 10
                                    opacity: 0.7
                                    color: modelData.status === 'LIVE' ? "#44cc44" : Kirigami.Theme.textColor
                                }
                            }

                            // Home Team
                            Item {
                                width: homeBadge.width; height: homeBadge.height; Layout.alignment: Qt.AlignVCenter
                                Rectangle {
                                    id: homeBadge
                                    visible: !controller.showLogos
                                    radius: 3
                                    color: Logic.getTeamColor(modelData.home)
                                    width: 42
                                    height: 24
                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData.home
                                        color: Logic.getTeamTextColor(modelData.home)
                                        font.bold: true
                                        font.pixelSize: 13
                                        font.family: "monospace"
                                    }
                                }
                                Image {
                                    visible: controller.showLogos
                                    anchors.fill: parent
                                    source: controller.showLogos ? controller.teamLogoUrl(modelData.home) : ""
                                    sourceSize.width: width * 2
                                    sourceSize.height: height * 2
                                    fillMode: Image.PreserveAspectFit; smooth: true
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (controller) {
                                    controller.openDetail(
                                        modelData.gameId, modelData.away, modelData.home,
                                        modelData.ag, modelData.hg, modelData.status,
                                        modelData.periodType, modelData.period,
                                        modelData.remain,
                                        modelData.start ? new Date(modelData.start).getTime() : 0,
                                        modelData.inIntermission, '1551'
                                    )
                                }
                            }
                        }
                    }
                }
                
                Item { height: 10; width: 1 }
            }
        }
    }
}
