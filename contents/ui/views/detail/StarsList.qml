import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../../logic.js" as Logic
import "../../components" as Components

ColumnLayout {
    id: starsRoot
    property var controller
    Layout.fillWidth: true
    spacing: 8

    Repeater {
        model: controller ? controller.det.threeStars : []
        delegate: RowLayout {
            spacing: 12
            Label {
                text: (modelData.star === 1 ? "🥇" : (modelData.star === 2 ? "🥈" : "🥉"))
                font.pixelSize: 20
            }
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
                text: modelData.name || ""
                font.bold: true
                Layout.fillWidth: true
                color: {
                    if (!controller || !controller.det) return Kirigami.Theme.textColor
                    let op = (modelData.team === controller.det.away ? controller.det.home : controller.det.away)
                    return controller.teamColorAdapted(modelData.team || "", op, modelData.team === controller.det.away, true)
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        if (controller && modelData.id) controller.openPlayer(modelData.id, 'detail')
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
