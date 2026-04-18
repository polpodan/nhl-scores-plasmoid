import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../../logic.js" as Logic

ColumnLayout {
    id: headerRoot
    property var controller
    spacing: 8

    function formatRecord(r) {
        if (!r) return "0-0-0"
        if (typeof r === 'string') return r
        return (r.wins||0) + "-" + (r.losses||0) + "-" + (r.ot||r.otLosses||0)
    }

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
                    source: (controller && controller.det) ? controller.teamLogoUrl(controller.det.away) : ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    onTapped: {
                        if (controller && controller.det) controller.openTeamHub(controller.det.away, "detail")
                    }
                }
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: controller && controller.det && controller.det.status !== 'UPCOMING'
                text: (controller && controller.det) ? String(controller.det.ag) : "0"
                font.pixelSize: 32
                font.bold: true
                color: Kirigami.Theme.textColor
            }
            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: controller && controller.det && controller.det.status === 'UPCOMING'
                spacing: 0
                Label {
                    text: (controller && controller.det) ? headerRoot.formatRecord(controller.det.awayRecord) : ""
                    font.pixelSize: 14; font.bold: true
                    color: (controller && controller.det) ? controller.teamColorAdapted(controller.det.away, controller.det.home, true, true) : Kirigami.Theme.textColor
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
                visible: controller && controller.det && controller.det.status === 'UPCOMING'
                spacing: 4
                Rectangle {
                    width: 4; height: 120
                    radius: 2
                    color: (controller && controller.det) ? Logic.getTeamColor(controller.det.away) : Kirigami.Theme.highlightColor
                }
                Rectangle {
                    width: 4; height: 120
                    radius: 2
                    color: (controller && controller.det) ? Logic.getTeamColor(controller.det.home) : Kirigami.Theme.highlightColor
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: controller && controller.det && controller.det.status === 'FINAL'
                radius: 5
                color: (controller && controller.det) ? controller.statusColor(controller.det.status) : "gray"
                opacity: 0.95
                width: detailBadgeCol.implicitWidth + 10
                height: detailBadgeCol.implicitHeight + 6
                Column {
                    id: detailBadgeCol
                    anchors.centerIn: parent
                    spacing: 0
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (controller && controller.det) ? controller.badgeLine1(controller.det.status, '', controller.det.pType, controller.det.period, controller.det.remain, controller.det.start, controller.det.home, controller.det.interm) : ""
                        color: 'white'
                        font.pixelSize: 10
                        font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: text !== ''
                        text: (controller && controller.det) ? controller.badgeLine2(controller.det.status, controller.det.start, controller.det.home, controller.det.pType, controller.det.period, controller.det.remain, controller.det.interm, controller.det.intermRemain) : ""
                        color: 'white'
                        font.pixelSize: 9
                        opacity: 0.85
                    }
                }
            }
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: controller && controller.det && controller.det.status === 'LIVE'
                spacing: 2
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: (controller && controller.det) ? controller.badgeLine1(controller.det.status, '', controller.det.pType, controller.det.period, controller.det.remain, controller.det.start, controller.det.home, controller.det.interm, controller.det.intermRemain) : ""
                    font.pixelSize: 13
                    font.bold: true
                    color: Kirigami.Theme.textColor
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !!controller && !!controller.det && !!controller.det.interm
                    text: (controller && controller.det && (controller.det.intermRemain || "") !== "") ? controller.det.intermRemain : i18n("Intermission")
                    font.pixelSize: 18
                    font.bold: true
                    color: Kirigami.Theme.textColor
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: text !== '' && !(controller && controller.det && controller.det.interm)
                    text: (controller && controller.det) ? controller.badgeLine2(controller.det.status, controller.det.start, controller.det.home, controller.det.pType, controller.det.period, controller.det.remain, controller.det.interm, controller.det.intermRemain) : ""
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
                    source: (controller && controller.det) ? controller.teamLogoUrl(controller.det.home) : ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    onTapped: {
                        if (controller && controller.det) controller.openTeamHub(controller.det.home, 'detail')
                    }
                }
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: controller && controller.det && controller.det.status !== 'UPCOMING'
                text: (controller && controller.det) ? String(controller.det.hg) : "0"
                font.pixelSize: 32
                font.bold: true
                color: Kirigami.Theme.textColor
            }
            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: controller && controller.det && controller.det.status === 'UPCOMING'
                spacing: 0
                Label {
                    text: (controller && controller.det) ? headerRoot.formatRecord(controller.det.homeRecord) : ""
                    font.pixelSize: 14; font.bold: true
                    color: (controller && controller.det) ? controller.teamColorAdapted(controller.det.home, controller.det.away, false, true) : Kirigami.Theme.textColor
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
        visible: controller && controller.det && !controller.det.loading && controller.det.status === 'UPCOMING'
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10
        spacing: 2
        Label {
            visible: controller && controller.det && controller.det.start > 0
            Layout.alignment: Qt.AlignHCenter
            text: (controller && controller.det && controller.det.start > 0)
                ? Qt.formatTime(new Date(controller.det.start), "hh:mm") + "  ·  "
                    + controller.localeDateLong(controller.det.start)
                : ""
            font.pixelSize: 14; font.bold: true
            color: Kirigami.Theme.textColor
        }
        Label {
            visible: controller && controller.det && (controller.det.venue || '') !== ''
            Layout.alignment: Qt.AlignHCenter
            text: (controller && controller.det) ? controller.det.venue : ''
            font.pixelSize: 12; opacity: 0.6
            color: Kirigami.Theme.disabledTextColor
        }
    }
}
