import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic

Row {
    id: teamBadgeRoot
    spacing: showLogos ? 2 : 4

    property string code:     ''
    property string opponentCode: ''
    property int    score:    0
    property int    sz:       14
    property int    iconH:    0
    property string gameId:   ''
    property string teamSide: '' // 'away' ou 'home'
    property bool   showScore: true
    property var    blinkingGames: ({})
    property bool   blinkOn: false
    property var    controller: null

    readonly property bool showLogos: (typeof controller !== 'undefined' && controller) ? controller.showLogos : false
    readonly property int finalIconH: iconH > 0 ? iconH : sz
    
    readonly property color finalColor: (opponentCode !== '' && controller) 
                                        ? controller.teamColorAdapted(code, opponentCode, teamSide === 'away') 
                                        : Logic.getTeamColor(code)
    
    readonly property color finalTextColor: (opponentCode !== '' && controller)
                                            ? controller.teamTextColor(code, opponentCode, teamSide === 'away')
                                            : Logic.getTeamTextColor(code)

    Rectangle {
        id: teamRect
        visible: !teamBadgeRoot.showLogos
        anchors.verticalCenter: parent.verticalCenter
        radius: 3
        color: teamBadgeRoot.finalColor
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
            color: teamBadgeRoot.finalTextColor
            font.pixelSize: Math.max(9, sz * 0.78)
            font.bold: true
            font.family: "monospace"
        }
    }

    Image {
        id: teamLogo
        visible: teamBadgeRoot.showLogos
        anchors.verticalCenter: parent.verticalCenter
        source: teamBadgeRoot.showLogos ? (typeof controller !== 'undefined' && controller ? controller.teamLogoUrl(code) : "https://assets.nhle.com/logos/nhl/svg/" + code + "_light.svg") : ""
        height: finalIconH
        width: finalIconH * 1.4
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: teamRect.opacity
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
