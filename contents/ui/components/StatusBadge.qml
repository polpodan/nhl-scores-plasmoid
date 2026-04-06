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
    
    // Filtrage pour l'applet : on ne considère comme PP que les vraies supériorités numériques
    readonly property bool isStandardPP: {
        if (!sit || !sit.isSpecial) return false;
        // On exclut les égalités (4v4, 3v3) et les filets déserts (le nombre de patineurs doit être différent)
        // Les paires valides sont (5,4), (4,5), (5,3), (3,5), (4,3), (3,4)
        return (sit.awaySkaters !== sit.homeSkaters) && !sit.emptyNet;
    }

    radius: (controller && controller.styles) ? controller.styles.badge.radius : 4
    color: (isStandardPP && sit.ppTeam) ? Logic.getTeamColor(sit.ppTeam) : bgColor
    opacity: 0.95
    border.color: isStandardPP ? "white" : "transparent"
    border.width: isStandardPP ? 1.5 : 0

    Column {
        id: contentCol
        anchors.centerIn: parent
        spacing: -2
        Text {
            id: t1
            anchors.horizontalCenter: parent.horizontalCenter
            text: isStandardPP ? sit.ppType : badgeRoot.line1
            color: 'white'
            font.pixelSize: isStandardPP ? badgeRoot.fontSize1 - 1 : badgeRoot.fontSize1
            font.bold: true
        }
        Text {
            id: t2
            anchors.horizontalCenter: parent.horizontalCenter
            visible: text !== ''
            text: (isStandardPP && badgeRoot.penaltyTime !== "") ? badgeRoot.penaltyTime : badgeRoot.line2
            color: 'white'
            font.pixelSize: badgeRoot.fontSize2
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
    height: (controller && controller.styles) ? controller.styles.teamBadge.height : 28 // Hauteur fixe identique aux TeamBadges
}
