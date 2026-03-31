import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic

Rectangle {
    id: badgeRoot

    property var    controller: null
    property string line1: ""
    property string line2: ""
    property color  bgColor: "gray"
    property int    fontSize1: (controller && controller.styles) ? controller.styles.badge.fontSize : 10
    property int    fontSize2: (controller && controller.styles) ? controller.styles.badge.smallFontSize : 9

    property string situationCode: "1551"
    property string penaltyTime: ""
    property string awayTeam: ""
    property string homeTeam: ""

    readonly property var sit: Logic.parseSituation(situationCode, awayTeam, homeTeam)

    radius: (controller && controller.styles) ? controller.styles.badge.radius : 4
    color: bgColor
    opacity: 0.95

    Column {
        id: contentCol
        anchors.centerIn: parent
        spacing: -2
        Text {
            id: t1
            anchors.horizontalCenter: parent.horizontalCenter
            text: badgeRoot.line1
            color: 'white'
            font.pixelSize: badgeRoot.fontSize1
            font.bold: true
        }
        Text {
            id: t2
            anchors.horizontalCenter: parent.horizontalCenter
            visible: text !== ''
            text: badgeRoot.line2
            color: 'white'
            font.pixelSize: badgeRoot.fontSize2
            font.bold: true
            opacity: 0.95
        }
    }

    // Indicateur de situation (PP ou EN)
    Rectangle {
        visible: !!sit && (sit.isSpecial || sit.emptyNet)
        anchors.top: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 2
        width: sitText.implicitWidth + 4
        height: Math.max(10, badgeRoot.fontSize2 + 1)
        radius: 2
        color: (sit && sit.ppTeam) ? Logic.getTeamColor(sit.ppTeam) : (sit && (sit.emptyNet || sit.isSpecial) ? "#444" : "gray")
        border.color: "white"
        border.width: 0.5
        Text {
            id: sitText
            anchors.centerIn: parent
            text: {
                if (!sit) return ""
                if (sit.emptyNet) return "🥅"
                var type = sit.ppType || ""
                var time = badgeRoot.penaltyTime || ""
                return type + (time !== "" ? " " + time : "")
            }
            color: "white"
            font.pixelSize: Math.max(7, badgeRoot.fontSize2 - 1)
            font.bold: true
        }
    }

    width:  Math.max(t1.contentWidth, t2.contentWidth) + 10
    height: (line2 !== '' ? (badgeRoot.fontSize1 + badgeRoot.fontSize2 + 6) : (badgeRoot.fontSize1 + 8))
}
