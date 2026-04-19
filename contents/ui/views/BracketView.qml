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

    readonly property var brkScores: (controller && controller.brk.scores) ? controller.brk.scores : ({})
    readonly property int brkPulse: (controller && controller.brk.pulse) ? controller.brk.pulse : 0

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
                spacing: 20
                Layout.margins: 10

                // ── CONFÉRENCE OUEST ──
                Label { text: i18n("WESTERN CONFERENCE"); font.bold: true; opacity: 0.6; Layout.alignment: Qt.AlignHCenter }
                
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10
                    ColumnLayout {
                        spacing: 8
                        Repeater {
                            model: [
                                { t1: "COL", t2: "LAK" },
                                { t1: "DAL", t2: "MIN" },
                                { t1: "VGK", t2: "UTA" },
                                { t1: "EDM", t2: "ANA" }
                            ]
                            delegate: Rectangle {
                                width: 160; height: 64; radius: 4
                                color: Qt.rgba(0,0,0,0.4)
                                border.color: Kirigami.Theme.textColor
                                border.width: 1
                                
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 2
                                    
                                    RowLayout {
                                        Components.TeamBadge { code: modelData.t1; sz: 14; showScore: false; controller: bracketRoot.controller }
                                        Item { Layout.fillWidth: true }
                                        Label {
                                            text: {
                                                var dummy = bracketRoot.brkPulse
                                                var val = bracketRoot.brkScores[modelData.t1]
                                                return (val !== undefined) ? String(val) : "0"
                                            }
                                            font.bold: true; font.pixelSize: 15
                                        }
                                    }
                                    
                                    Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.1 }
                                    
                                    RowLayout {
                                        Components.TeamBadge { code: modelData.t2; sz: 14; showScore: false; controller: bracketRoot.controller }
                                        Item { Layout.fillWidth: true }
                                        Label {
                                            text: {
                                                var dummy = bracketRoot.brkPulse
                                                var val = bracketRoot.brkScores[modelData.t2]
                                                return (val !== undefined) ? String(val) : "0"
                                            }
                                            font.bold: true; font.pixelSize: 15
                                        }
                                    }
                                }
                                TapHandler { onTapped: controller.openTeamHub(modelData.t1, 'bracket') }
                            }
                        }
                    }
                    ColumnLayout { 
                        spacing: 40
                        Rectangle { width: 160; height: 64; radius: 4; color: "transparent"; border.color: Kirigami.Theme.textColor; border.width: 1; opacity: 0.1 }
                        Rectangle { width: 160; height: 64; radius: 4; color: "transparent"; border.color: Kirigami.Theme.textColor; border.width: 1; opacity: 0.1 }
                    }
                    ColumnLayout { 
                        Rectangle { width: 160; height: 64; radius: 4; color: "transparent"; border.color: Kirigami.Theme.textColor; border.width: 1; opacity: 0.1 }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.1; Layout.margins: 10 }
                Label { text: i18n("STANLEY CUP FINALS"); font.bold: true; font.pixelSize: 16; Layout.alignment: Qt.AlignHCenter; color: Kirigami.Theme.highlightColor }
                Rectangle { Layout.alignment: Qt.AlignHCenter; width: 160; height: 64; radius: 4; color: "transparent"; border.color: Kirigami.Theme.textColor; border.width: 1; opacity: 0.1 }
                Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.1; Layout.margins: 10 }

                // ── CONFÉRENCE EST ──
                Label { text: i18n("EASTERN CONFERENCE"); font.bold: true; opacity: 0.6; Layout.alignment: Qt.AlignHCenter }
                
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10
                    ColumnLayout { 
                        Rectangle { width: 160; height: 64; radius: 4; color: "transparent"; border.color: Kirigami.Theme.textColor; border.width: 1; opacity: 0.1 }
                    }
                    ColumnLayout { 
                        spacing: 40
                        Rectangle { width: 160; height: 64; radius: 4; color: "transparent"; border.color: Kirigami.Theme.textColor; border.width: 1; opacity: 0.1 }
                        Rectangle { width: 160; height: 64; radius: 4; color: "transparent"; border.color: Kirigami.Theme.textColor; border.width: 1; opacity: 0.1 }
                    }
                    
                    // R1 Est (Buffalo, Tampa, Carolina, Pittsburgh)
                    ColumnLayout {
                        spacing: 8
                        Repeater {
                            model: [
                                { t1: "BUF", t2: "BOS" },
                                { t1: "TBL", t2: "MTL" },
                                { t1: "CAR", t2: "OTT" },
                                { t1: "PIT", t2: "PHI" }
                            ]
                            delegate: Rectangle {
                                width: 160; height: 64; radius: 4
                                color: Qt.rgba(0,0,0,0.4)
                                border.color: Kirigami.Theme.textColor
                                border.width: 1
                                
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 2
                                    
                                    RowLayout {
                                        Components.TeamBadge { code: modelData.t1; sz: 14; showScore: false; controller: bracketRoot.controller }
                                        Item { Layout.fillWidth: true }
                                        Label {
                                            text: {
                                                var dummy = bracketRoot.brkPulse
                                                var val = bracketRoot.brkScores[modelData.t1]
                                                return (val !== undefined) ? String(val) : "0"
                                            }
                                            font.bold: true; font.pixelSize: 15
                                        }
                                    }
                                    
                                    Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.1 }
                                    
                                    RowLayout {
                                        Components.TeamBadge { code: modelData.t2; sz: 14; showScore: false; controller: bracketRoot.controller }
                                        Item { Layout.fillWidth: true }
                                        Label {
                                            text: {
                                                var dummy = bracketRoot.brkPulse
                                                var val = bracketRoot.brkScores[modelData.t2]
                                                return (val !== undefined) ? String(val) : "0"
                                            }
                                            font.bold: true; font.pixelSize: 15
                                        }
                                    }
                                }
                                TapHandler { onTapped: controller.openTeamHub(modelData.t1, 'bracket') }
                            }
                        }
                    }
                }
            }
        }
    }
}
