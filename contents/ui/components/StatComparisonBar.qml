import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic

Item {
    id: statBarRoot
    Layout.fillWidth: true
    implicitWidth: 200
    implicitHeight: (awaySub !== "" || homeSub !== "") ? 48 : 36

    property string label: ""
    property var awayValue: 0
    property var homeValue: 0
    property string awaySub: ""
    property string homeSub: ""
    property real awayRaw: -1
    property real homeRaw: -1
    property color awayColor: "#888888"
    property color homeColor: "#888888"

    function parseValue(v) {
        if (typeof v === 'number') return v;
        if (typeof v !== 'string') return 0;
        
        if (v.indexOf('/') !== -1) {
            var parts = v.split('/');
            if (parts.length === 2) {
                var num = parseFloat(parts[0]);
                var den = parseFloat(parts[1]);
                if (den === 0) return 0;
                return (num / den) * 100;
            }
        }

        if (v.indexOf('%') !== -1) {
            return parseFloat(v.replace('%', ''));
        }
        
        var n = parseFloat(v);
        return isNaN(n) ? 0 : n;
    }

    readonly property real valA: awayRaw >= 0 ? awayRaw : parseValue(awayValue)
    readonly property real valH: homeRaw >= 0 ? homeRaw : parseValue(homeValue)
    
    // Logic for the bars: if both are 0, we show 50/50 empty or just a neutral state
    // But usually in NHL stats, if both are 0 (like 0 hits), we show 50/50 bars
    readonly property bool bothZero: (valA <= 0 && valH <= 0)
    readonly property real total: bothZero ? 2 : (valA + valH)
    readonly property real displayA: bothZero ? 1 : valA
    readonly property real displayH: bothZero ? 1 : valH

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        Label {
            text: statBarRoot.label
            font.pixelSize: 11
            font.bold: true
            opacity: 0.7
            Layout.alignment: Qt.AlignHCenter
            color: Kirigami.Theme.textColor
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                spacing: 0
                Layout.preferredWidth: 60
                Label {
                    text: String(awayValue)
                    font.pixelSize: 14
                    font.bold: valA > valH
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    color: Kirigami.Theme.textColor
                }
                Label {
                    visible: awaySub !== ""
                    text: awaySub
                    font.pixelSize: 10
                    opacity: 0.5
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    color: Kirigami.Theme.textColor
                }
            }

            // Container des barres
            Item {
                id: barContainer
                Layout.fillWidth: true
                Layout.preferredWidth: 100
                height: 10

                // Fond
                Rectangle {
                    anchors.fill: parent
                    radius: 5
                    color: Kirigami.Theme.textColor
                    opacity: 0.1
                }

                // Barre Visiteur (alignée à gauche)
                Rectangle {
                    id: awayBar
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.floor(barContainer.width * (statBarRoot.displayA / statBarRoot.total))
                    color: statBarRoot.awayColor
                    radius: 5
                    visible: width > 0
                    
                    // Pour éviter que les coins arrondis ne se voient au milieu
                    Rectangle {
                        visible: awayBar.width > 5 && homeBar.width > 5
                        anchors.right: parent.right
                        width: 5
                        height: parent.height
                        color: parent.color
                    }
                }

                // Barre Locale (alignée à droite)
                Rectangle {
                    id: homeBar
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.floor(barContainer.width * (statBarRoot.displayH / statBarRoot.total))
                    color: statBarRoot.homeColor
                    radius: 5
                    visible: width > 0

                    // Pour éviter que les coins arrondis ne se voient au milieu
                    Rectangle {
                        visible: awayBar.width > 5 && homeBar.width > 5
                        anchors.left: parent.left
                        width: 5
                        height: parent.height
                        color: parent.color
                    }
                }
            }

            ColumnLayout {
                spacing: 0
                Layout.preferredWidth: 60
                Label {
                    text: String(homeValue)
                    font.pixelSize: 14
                    font.bold: valH > valA
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    color: Kirigami.Theme.textColor
                }
                Label {
                    visible: homeSub !== ""
                    text: homeSub
                    font.pixelSize: 10
                    opacity: 0.5
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    color: Kirigami.Theme.textColor
                }
            }
        }
    }
}
