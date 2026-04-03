import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic

Row {
    id: teamBadgeRoot
    spacing: 4
    anchors.horizontalCenter: parent.horizontalCenter

    property string code:     ''
    property int    score:    0
    property int    sz:       14
    property string gameId:   ''
    property string teamSide: '' // 'away' ou 'home'
    property bool   showScore: true
    property var    blinkingGames: ({})
    property bool   blinkOn: false

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        radius: 3
        color: Logic.getTeamColor(code, Kirigami.Theme.positiveBackgroundColor)
        border.color: 'white'
        border.width: 1
        height: nameText.implicitHeight + Math.max(3, sz * 0.15)
        width:  nameText.implicitWidth  + Math.max(4, sz * 0.28)
        opacity: {
            var b = blinkingGames[String(gameId)]
            return (b && (b === teamSide || b === 'both') && !blinkOn) ? 0.0 : 1.0
        }
        Text {
            id: nameText
            anchors.centerIn: parent
            text: code
            color: Logic.getTeamTextColor(code)
            font.pixelSize: Math.max(9, sz * 0.78)
            font.bold: true
            font.family: "monospace"
        }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: showScore
        text: String(score)
        font.pixelSize: Math.max(11, sz * 1.05)
        font.bold: true
        color: Kirigami.Theme.textColor
        opacity: {
            var b = blinkingGames[String(gameId)]
            return (b && (b === teamSide || b === 'both') && !blinkOn) ? 0.0 : 1.0
        }
    }
}
