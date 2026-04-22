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
    property int    sz: 14

    readonly property var sit: Logic.parseSituation(situationCode, awayTeam, homeTeam)
    
    // Filtrage pour l'applet : on ne considère comme PP que les vraies supériorités numériques
    readonly property bool isStandardPP: {
        if (!sit || !sit.isSpecial) return false;
        return (sit.awaySkaters !== sit.homeSkaters) && !sit.emptyNet;
    }

    readonly property color ppColor: {
        if (!isStandardPP || !sit.ppTeam || !controller) return bgColor;
        var isAway = (sit.ppTeam === awayTeam);
        var opp = isAway ? homeTeam : awayTeam;
        return controller.teamColorAdapted(sit.ppTeam, opp, isAway, false);
    }

    radius: (controller && controller.styles) ? controller.styles.badge.radius : 4
    color: isStandardPP ? ppColor : bgColor
    opacity: 0.95
    border.color: isStandardPP ? "white" : "transparent"
    border.width: isStandardPP ? 1.5 : 0

    Column {
        id: contentCol
        anchors.centerIn: parent
        spacing: isStandardPP ? -3 : -2
        Text {
            id: t1
            anchors.horizontalCenter: parent.horizontalCenter
            // En PP: on affiche "Période TempsMatch" (ex: 1st 12:34)
            text: isStandardPP ? (badgeRoot.line1 + " " + badgeRoot.line2) : badgeRoot.line1
            color: Logic.getContrastColor(badgeRoot.color)
            font.pixelSize: isStandardPP ? Math.max(8, badgeRoot.fontSize2 - 1) : badgeRoot.fontSize1
            font.bold: true
        }
        Text {
            id: t2
            anchors.horizontalCenter: parent.horizontalCenter
            visible: text !== ''
            // En PP: on affiche "PP TempsPunition" (ex: PP 1:30)
            // Si le temps est vide (cas fréquent en entracte), on affiche juste "PP"
            text: {
                if (isStandardPP) {
                    return (badgeRoot.penaltyTime !== "") ? (sit.ppType + " " + badgeRoot.penaltyTime) : sit.ppType
                }
                return badgeRoot.line2
            }
            color: Logic.getContrastColor(badgeRoot.color)
            font.pixelSize: isStandardPP ? (badgeRoot.fontSize1 - 1) : badgeRoot.fontSize2
            font.bold: true
            opacity: 0.95
        }
    }

    // Le filet désert est maintenant masqué dans le badge (applet)
    // Il reste géré par le ppBanner dans DetailView.qml
    /*
    Rectangle {
        visible: !!sit && sit.emptyNet
        ...
    }
    */

    width:  Math.max(t1.contentWidth, t2.contentWidth) + 10
    height: Math.max(badgeRoot.sz * 1.8, 30) // Hauteur confortable pour 2 lignes de texte
}
