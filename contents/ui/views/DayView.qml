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
    visible: !!(controller && controller.nav.dayView && !controller.nav.detail && !controller.nav.calendar)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Barre navigation ─────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8; Layout.topMargin: 4; Layout.bottomMargin: 2
            Button {
                text: i18n('✕'); flat: true
                onClicked: { if (controller) { controller.nav.dayView = false; controller.expanded = false } }
            }
            Item { Layout.fillWidth: true }
            Label {
                text: {
                    if (!controller) return ""
                    var parts = controller.day.date.split('-')
                    if (parts.length === 3) {
                        var d = new Date(parseInt(parts[0]), parseInt(parts[1])-1, parseInt(parts[2]))
                        return controller.localeDateLong(d.getTime())
                    }
                    return controller.day.date
                }
                font.bold: true; font.pixelSize: 15
                Layout.alignment: Qt.AlignHCenter
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "📅  " + i18n("Calendar")
                flat: true
                onClicked: { if (controller) controller.nav.calendar = true }
            }
        }

        // Gestion de l'état (Chargement / Erreur)
        Components.StateLayer {
            loading: !!controller && controller.day.loading
            error: controller ? (controller.day.error !== "" ? controller.day.error : (controller.day.games.length === 0 ? i18n("No games") : "")) : ""
        }

        ScrollView {
            id: dayViewScrollView
            Layout.fillWidth: true; Layout.fillHeight: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            visible: !!(controller && !controller.day.loading && controller.day.error === '')

            ColumnLayout {
                id: dayViewCol
                width: Math.min(340, parent.width)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                Repeater {
                    model: controller ? controller.day.games : []
                    delegate: ItemDelegate {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4; Layout.rightMargin: 4
                        topPadding: 6; bottomPadding: 6
                        leftPadding: 10; rightPadding: 10
                        implicitHeight: 52

                        background: Rectangle {
                            radius: 6
                            color: modelData.status === 'LIVE'  ? Qt.rgba(0.0, 0.55, 0.1, 0.13)
                                 : modelData.status === 'FINAL' ? Qt.rgba(0.5, 0.5, 0.5, 0.08)
                                 : Qt.rgba(0.3, 0.5, 0.9, 0.10)
                            border.color: modelData.status === 'LIVE'  ? Qt.rgba(0.0, 0.7, 0.1, 0.35)
                                        : modelData.status === 'FINAL' ? Qt.rgba(0.5, 0.5, 0.5, 0.2)
                                        : Qt.rgba(0.3, 0.5, 0.9, 0.25)
                            border.width: 1
                        }

                        contentItem: Item {
                            implicitHeight: 52
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 12

                                Rectangle {
                                    radius: 3; color: Logic.getTeamColor(modelData.away)
                                    width: awDayLbl.implicitWidth + 10; height: awDayLbl.implicitHeight + 6
                                    Label {
                                        id: awDayLbl; anchors.centerIn: parent
                                        text: modelData.away
                                        color: Logic.getTeamTextColor(modelData.away)
                                        font.bold: true; font.pixelSize: 13; font.family: "monospace"
                                    }
                                }

                                ColumnLayout {
                                    spacing: 1
                                    Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.status === 'UPCOMING'
                                              ? (controller ? controller.dayViewTimeLabel(new Date(modelData.start).getTime(), modelData.homeAbbrev || modelData.home) : "")
                                              : modelData.ag + " – " + modelData.hg
                                        font.pixelSize: 15; font.bold: true
                                        color: Kirigami.Theme.textColor
                                    }
                                    Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        visible: modelData.status === 'UPCOMING'
                                        text: (controller && controller.dateMode === 'venue')
                                              ? "(" + i18n("arena") + ")"
                                              : "(" + i18n("local") + ")"
                                        font.pixelSize: 10; opacity: 0.5
                                        color: Kirigami.Theme.disabledTextColor
                                    }
                                    Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        visible: modelData.status !== 'UPCOMING'
                                        text: {
                                            if (modelData.status === 'FINAL') return i18n("Final")
                                            if (modelData.inIntermission)     return "INT"
                                            return (controller ? controller.livePeriodText(modelData.periodType, modelData.period) : "")
                                                   + (modelData.remain ? "  " + modelData.remain : "")
                                        }
                                        font.pixelSize: 11; opacity: 0.7
                                        color: modelData.status === 'LIVE' ? "#44cc44" : Kirigami.Theme.disabledTextColor
                                    }
                                }

                                Rectangle {
                                    radius: 3; color: Logic.getTeamColor(modelData.home)
                                    width: hmDayLbl.implicitWidth + 10; height: hmDayLbl.implicitHeight + 6
                                    Label {
                                        id: hmDayLbl; anchors.centerIn: parent
                                        text: modelData.home
                                        color: Logic.getTeamTextColor(modelData.home)
                                        font.bold: true; font.pixelSize: 13; font.family: "monospace"
                                    }
                                }
                            }
                        }

                        onClicked: {
                            if (controller) controller.openDetail(
                                modelData.gameId, modelData.away, modelData.home,
                                modelData.ag, modelData.hg, modelData.status,
                                modelData.periodType, modelData.period,
                                modelData.remain,
                                modelData.start ? new Date(modelData.start).getTime() : 0,
                                modelData.inIntermission, '1551')
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }
                Item { implicitHeight: 8 }
            }
        }
    }
}
