import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic
import "../components" as Components

Item {
    id: bracketRoot
    property var controller
    anchors.fill: parent
    visible: !!(controller && controller.nav.bracket)

    // Accès direct aux données du contrôleur
    readonly property var brkSeries: (controller && controller.brk.series) ? controller.brk.series : ({})
    readonly property int brkPulse: (controller && controller.brk.pulse) ? controller.brk.pulse : 0

    // Composant interne pour une boîte de série (Style Plasma 6)
    // On définit une fonction pour plus de réactivité
    function getSeriesData(l) {
        var dummy = brkPulse // Force la réévaluation quand pulse change
        return brkSeries[l] || { top: "", bottom: "", topWins: 0, bottomWins: 0 }
    }

    component SeriesDelegate : Rectangle {
        property string letter: ""
        width: 160; height: 66; radius: 4
        color: Qt.rgba(0,0,0,0.4)
        border.color: Kirigami.Theme.textColor
        border.width: 1
        opacity: (getSeriesData(letter).top === "" && getSeriesData(letter).bottom === "") ? 0.2 : 1.0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2
            
            // Équipe du haut
            RowLayout {
                Components.TeamBadge { 
                    code: getSeriesData(letter).top
                    sz: 14; showScore: false; controller: bracketRoot.controller 
                    visible: code !== ""
                }
                Label { text: "???"; visible: getSeriesData(letter).top === ""; font.pixelSize: 10; opacity: 0.5 }
                Item { Layout.fillWidth: true }
                Label {
                    text: String(getSeriesData(letter).topWins)
                    font.bold: true; font.pixelSize: 16
                    color: getSeriesData(letter).topWins === 4 ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                }
            }
            
            Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.1 }
            
            // Équipe du bas
            RowLayout {
                Components.TeamBadge { 
                    code: getSeriesData(letter).bottom
                    sz: 14; showScore: false; controller: bracketRoot.controller 
                    visible: code !== ""
                }
                Label { text: "???"; visible: getSeriesData(letter).bottom === ""; font.pixelSize: 10; opacity: 0.5 }
                Item { Layout.fillWidth: true }
                Label {
                    text: String(getSeriesData(letter).bottomWins)
                    font.bold: true; font.pixelSize: 16
                    color: getSeriesData(letter).bottomWins === 4 ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Navigation ──
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 8
            Button {
                text: i18n("‹ Back")
                icon.name: "go-previous"
                flat: true
                onClicked: controller.nav.bracket = false
            }
            Item { Layout.fillWidth: true }
            Label {
                text: i18n("🏆 STANLEY CUP PLAYOFFS 2026")
                font.bold: true
                font.pixelSize: 14
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 25
                Layout.margins: 15

                // ── CONFÉRENCE EST (A, B, C, D) ──
                Label { text: i18n("EASTERN CONFERENCE"); font.bold: true; opacity: 0.7; Layout.alignment: Qt.AlignHCenter }
                
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20
                    
                    ColumnLayout {
                        spacing: 12
                        SeriesDelegate { letter: "A" }
                        SeriesDelegate { letter: "B" }
                        SeriesDelegate { letter: "C" }
                        SeriesDelegate { letter: "D" }
                    }
                    
                    ColumnLayout {
                        spacing: 60
                        SeriesDelegate { letter: "I" }
                        SeriesDelegate { letter: "J" }
                    }
                    
                    ColumnLayout {
                        SeriesDelegate { letter: "M" }
                    }
                }

                // ── FINALE STANLEY CUP ──
                Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.1 }
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    Label { text: i18n("STANLEY CUP FINALS"); font.bold: true; font.pixelSize: 16; color: Kirigami.Theme.highlightColor; Layout.alignment: Qt.AlignHCenter }
                    SeriesDelegate { letter: "O"; Layout.alignment: Qt.AlignHCenter }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.1 }

                // ── CONFÉRENCE OUEST (E, F, G, H) ──
                Label { text: i18n("WESTERN CONFERENCE"); font.bold: true; opacity: 0.7; Layout.alignment: Qt.AlignHCenter }
                
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20
                    
                    ColumnLayout {
                        SeriesDelegate { letter: "N" }
                    }

                    ColumnLayout {
                        spacing: 60
                        SeriesDelegate { letter: "K" }
                        SeriesDelegate { letter: "L" }
                    }
                    
                    ColumnLayout {
                        spacing: 12
                        SeriesDelegate { letter: "E" }
                        SeriesDelegate { letter: "F" }
                        SeriesDelegate { letter: "G" }
                        SeriesDelegate { letter: "H" }
                    }
                }
                
                Item { Layout.preferredHeight: 20 }
            }
        }
    }
}
