import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../../logic.js" as Logic
import "../../components" as Components

ColumnLayout {
    id: penaltiesRoot
    property var controller
    Layout.fillWidth: true
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
                Components.TeamBadge {
                    code: modelData.team || ""
                    opponentCode: {
                        if (!controller || !controller.det) return ""
                        return (code === controller.det.away) ? controller.det.home : controller.det.away
                    }
                    teamSide: {
                        if (!controller || !controller.det) return ""
                        return (code === controller.det.away) ? 'away' : 'home'
                    }
                    sz: 12
                    showScore: false
                    controller: controller
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
                        color: {
                            if (!controller || !controller.det) return Kirigami.Theme.textColor
                            let op = (modelData.team === controller.det.away ? controller.det.home : controller.det.away)
                            return controller.teamColorAdapted(modelData.team || "", op, modelData.team === controller.det.away, true)
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                if (controller) controller.openPlayer(modelData.playerId, 'detail')
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
