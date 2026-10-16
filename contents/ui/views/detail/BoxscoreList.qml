import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../../components" as Components

ColumnLayout {
    id: boxscoreRoot
    property var controller
    Layout.fillWidth: true
    spacing: 10

    function skaters(team) {
        if (!team) return []
        return (team.forwards || []).concat(team.defense || [])
    }

    function playerName(player) {
        if (!player) return ""
        if (player.name && player.name.default) return player.name.default
        if (typeof player.name === "string") return player.name
        if (player.fullName) return player.fullName
        var first = player.firstName && (player.firstName.default || player.firstName)
        var last = player.lastName && (player.lastName.default || player.lastName)
        return [first || "", last || ""].join(" ").trim()
    }

    function stat(value) {
        return value === undefined || value === null ? "—" : String(value)
    }

    Repeater {
        model: [
            { code: controller ? controller.det.away : "", opponent: controller ? controller.det.home : "", data: controller ? controller.det.boxscoreAway : ({}) },
            { code: controller ? controller.det.home : "", opponent: controller ? controller.det.away : "", data: controller ? controller.det.boxscoreHome : ({}) }
        ]

        delegate: ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                Components.TeamBadge {
                    code: modelData.code
                    opponentCode: modelData.opponent
                    teamSide: index === 0 ? "away" : "home"
                    sz: 14
                    showScore: false
                    controller: boxscoreRoot.controller
                }
                Label {
                    text: modelData.code
                    font.bold: true
                    font.pixelSize: 13
                    color: Kirigami.Theme.textColor
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.12 }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 2
                Label { text: i18n("Player"); Layout.fillWidth: true; font.pixelSize: 10; opacity: 0.55; elide: Text.ElideRight }
                Label { text: "G"; Layout.preferredWidth: 22; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 10; opacity: 0.55 }
                Label { text: "A"; Layout.preferredWidth: 22; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 10; opacity: 0.55 }
                Label { text: "PTS"; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 10; opacity: 0.55 }
                Label { text: "S"; Layout.preferredWidth: 26; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 10; opacity: 0.55 }
                Label { text: "+/−"; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 10; opacity: 0.55 }
                Label { text: "PIM"; Layout.preferredWidth: 26; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 10; opacity: 0.55 }
                Label { text: "TOI"; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 10; opacity: 0.55 }
            }

            Repeater {
                model: boxscoreRoot.skaters(modelData.data)
                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        text: (modelData.sweaterNumber ? "#" + modelData.sweaterNumber + " " : "") + boxscoreRoot.playerName(modelData)
                        Layout.fillWidth: true
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                if (boxscoreRoot.controller && modelData.playerId)
                                    boxscoreRoot.controller.openPlayer(modelData.playerId, "detail")
                            }
                        }
                    }
                    Label { text: boxscoreRoot.stat(modelData.goals); Layout.preferredWidth: 22; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 11 }
                    Label { text: boxscoreRoot.stat(modelData.assists); Layout.preferredWidth: 22; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 11 }
                    Label { text: boxscoreRoot.stat(modelData.points); Layout.preferredWidth: 28; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 11; font.bold: true }
                    Label { text: boxscoreRoot.stat(modelData.sog !== undefined ? modelData.sog : modelData.shots); Layout.preferredWidth: 26; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 11 }
                    Label {
                        text: modelData.plusMinus === undefined ? "—" : ((modelData.plusMinus > 0 ? "+" : "") + modelData.plusMinus)
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 11
                    }
                    Label { text: boxscoreRoot.stat(modelData.pim); Layout.preferredWidth: 26; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 11 }
                    Label { text: boxscoreRoot.stat(modelData.toi); Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 11 }
                }
            }

            Label {
                visible: boxscoreRoot.skaters(modelData.data).length === 0
                text: i18n("No player stats available yet.")
                Layout.fillWidth: true
                font.pixelSize: 11
                font.italic: true
                opacity: 0.55
            }

            Label {
                visible: (modelData.data.goalies || []).length > 0
                text: i18n("Goalies")
                Layout.topMargin: 3
                font.pixelSize: 11
                font.bold: true
                opacity: 0.65
            }

            Repeater {
                model: modelData.data.goalies || []
                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        text: (modelData.sweaterNumber ? "#" + modelData.sweaterNumber + " " : "") + boxscoreRoot.playerName(modelData)
                        Layout.fillWidth: true
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                if (boxscoreRoot.controller && modelData.playerId)
                                    boxscoreRoot.controller.openPlayer(modelData.playerId, "detail")
                            }
                        }
                    }
                    Label { text: "SV/SA " + boxscoreRoot.stat(modelData.saves) + "/" + boxscoreRoot.stat(modelData.shotsAgainst); Layout.preferredWidth: 68; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 10 }
                    Label { text: "GA " + boxscoreRoot.stat(modelData.goalsAgainst); Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 10 }
                    Label {
                        text: (modelData.savePctg !== undefined || modelData.savePercentage !== undefined)
                              ? "SV% " + Number(modelData.savePctg !== undefined ? modelData.savePctg : modelData.savePercentage).toFixed(3)
                              : "SV% —"
                        Layout.preferredWidth: 62
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 10
                    }
                    Label { text: boxscoreRoot.stat(modelData.toi); Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 10 }
                }
            }
        }
    }
}
