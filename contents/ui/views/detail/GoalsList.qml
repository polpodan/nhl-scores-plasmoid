import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../../logic.js" as Logic
import "../../components" as Components

ColumnLayout {
    id: goalsRoot
    property var controller
    Layout.fillWidth: true
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
                Label {
                    text: modelData.time || ""
                    Layout.preferredWidth: 40
                    font.pixelSize: 11
                    opacity: 0.7
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
                ColumnLayout {
                    spacing: 0
                    Label {
                        text: (modelData.goalsToDate > 0 ? (modelData.scorer || "") + " (" + modelData.goalsToDate + ")" : (modelData.scorer || "")) + (modelData.ppg ? " PP" : "") + (modelData.shg ? " SH" : "") + (modelData.en ? " EN" : "")
                        font.bold: true
                        color: {
                            if (!controller || !controller.det) return Kirigami.Theme.textColor
                            let op = (modelData.team === controller.det.away ? controller.det.home : controller.det.away)
                            return controller.teamColorAdapted(modelData.team || "", op, modelData.team === controller.det.away, true)
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                if (controller) controller.openPlayer(modelData.scorerId, 'detail')
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
                                color: {
                                    if (!controller || !controller.det) return Kirigami.Theme.textColor
                                    let op = (modelData.team === controller.det.away ? controller.det.home : controller.det.away)
                                    return controller.teamColorAdapted(modelData.team || "", op, modelData.team === controller.det.away, true)
                                }
                                opacity: 0.9
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    onTapped: {
                                        if (controller) controller.openPlayer(modelData.id, 'detail')
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
                Item { Layout.fillWidth: true }
                Button {
                    visible: !!modelData.highlightId && modelData.highlightId !== 0
                    icon.name: "media-playback-start"
                    flat: true
                    ToolTip.text: i18n("Watch goal highlight")
                    ToolTip.visible: hovered
                    onClicked: {
                        Qt.openUrlExternally("https://players.brightcove.net/6415718365001/EXtG1xJ7H_default/index.html?videoId=" + modelData.highlightId)
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
