import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic

Column {
    id: teamBadgeRoot
    spacing: 1

    property string code:     ''
    property int    score:    0
    property int    sz:       14
    property string gameId:   ''
    property string teamSide: '' // 'away' ou 'home'
    property var    blinkingGames: ({})
    property bool   blinkOn: false

    Rectangle {
        radius: 3
        color: Logic.getTeamColor(code, Kirigami.Theme.positiveBackgroundColor)
        border.color: 'white'
        border.width: 1
        height: nameText.implicitHeight + Math.max(3, sz * 0.15) // Augmenté 10%
        width:  nameText.implicitWidth  + Math.max(4, sz * 0.28) // Augmenté 10%
        opacity: {
            var b = blinkingGames[String(gameId)]
            return (b && (b === teamSide || b === 'both') && !blinkOn) ? 0.0 : 1.0
        }
        Text {
            id: nameText
            anchors.centerIn: parent
            text: code
            color: Logic.getTeamTextColor(code)
            font.pixelSize: Math.max(9, sz * 0.78) // Augmenté 10%
            font.bold: true
            font.family: "monospace"
        }
    }
    Text {
        text: String(score)
        font.pixelSize: Math.max(11, sz * 1.05) // Augmenté 10%
        font.bold: true
        color: Kirigami.Theme.textColor
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: {
            var b = blinkingGames[String(gameId)]
            return (b && (b === teamSide || b === 'both') && !blinkOn) ? 0.0 : 1.0
        }
    }
}
