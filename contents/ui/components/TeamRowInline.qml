import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic

Row {
    id: teamRowRoot
    spacing: Math.max(4, sz * 0.22) 

    property string awayCode: ''
    property string homeCode: ''
    property int    agScore:  0
    property int    hgScore:  0
    property int    sz:       14
    property string gameId:   ''
    property var    blinkingGames: ({})
    property bool   blinkOn: false
    
    // Nouvelles propriétés passées par le Loader
    property string gameStatus: 'UPCOMING'
    property string line1: ""
    property string line2: ""
    property color  bgColor: "gray"
    
    property string situationCode: "1551"
    property string penaltyTime: ""
    property string awayTeam: ""
    property string homeTeam: ""
    
    property Component statusComponent: null

    // Visiteur
    Rectangle {
        radius: 3
        color: Logic.getTeamColor(awayCode, Kirigami.Theme.positiveBackgroundColor)
        border.color: 'white'; border.width: 1
        height: aText.implicitHeight + Math.max(3, sz * 0.12)
        width:  aText.implicitWidth  + Math.max(4, sz * 0.22)
        opacity: {
            var b = blinkingGames[String(gameId)]
            return (b && (b === 'away' || b === 'both') && !blinkOn) ? 0.0 : 1.0
        }
        Text {
            id: aText; anchors.centerIn: parent; text: awayCode
            color: Logic.getTeamTextColor(awayCode)
            font.pixelSize: Math.max(8, sz * 0.72); font.bold: true; font.family: "monospace"
        }
    }

    Label {
        text: String(agScore)
        font.pixelSize: Math.max(10, sz * 0.95); font.bold: true; color: Kirigami.Theme.textColor
        visible: gameStatus !== 'UPCOMING'
        opacity: {
            var b = blinkingGames[String(gameId)]
            return (b && (b === 'away' || b === 'both') && !blinkOn) ? 0.0 : 1.0
        }
    }

    // Badge de statut au milieu
    Loader {
        id: statusLoader
        sourceComponent: statusComponent
        visible: statusComponent !== null
        
        onLoaded: {
            if (item) {
                // Initialisation et création de liens (bindings)
                item.line1 = Qt.binding(function() { return teamRowRoot.line1 })
                item.line2 = Qt.binding(function() { return teamRowRoot.line2 })
                item.bgColor = Qt.binding(function() { return teamRowRoot.bgColor })
                if ("situationCode" in item) 
                    item.situationCode = Qt.binding(function() { return teamRowRoot.situationCode })
                if ("penaltyTime" in item) 
                    item.penaltyTime = Qt.binding(function() { return teamRowRoot.penaltyTime })
                if ("awayTeam" in item) 
                    item.awayTeam = Qt.binding(function() { return teamRowRoot.awayTeam })
                if ("homeTeam" in item) 
                    item.homeTeam = Qt.binding(function() { return teamRowRoot.homeTeam })
            }
        }
    }

    // Tiret de secours
    Label {
        text: "–"
        font.pixelSize: Math.max(10, sz * 0.95); color: Kirigami.Theme.disabledTextColor
        visible: statusComponent === null || gameStatus === 'UPCOMING'
    }

    Label {
        text: String(hgScore)
        font.pixelSize: Math.max(10, sz * 0.95); font.bold: true; color: Kirigami.Theme.textColor
        visible: gameStatus !== 'UPCOMING'
        opacity: {
            var b = blinkingGames[String(gameId)]
            return (b && (b === 'home' || b === 'both') && !blinkOn) ? 0.0 : 1.0
        }
    }

    // Local
    Rectangle {
        radius: 3
        color: Logic.getTeamColor(homeCode, Kirigami.Theme.positiveBackgroundColor)
        border.color: 'white'; border.width: 1
        height: hText.implicitHeight + Math.max(3, sz * 0.12)
        width:  hText.implicitWidth  + Math.max(4, sz * 0.22)
        opacity: {
            var b = blinkingGames[String(gameId)]
            return (b && (b === 'home' || b === 'both') && !blinkOn) ? 0.0 : 1.0
        }
        Text {
            id: hText; anchors.centerIn: parent; text: homeCode
            color: Logic.getTeamTextColor(homeCode)
            font.pixelSize: Math.max(8, sz * 0.72); font.bold: true; font.family: "monospace"
        }
    }
}
