import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic

Item {
    id: bracketRoot
    property var controller

    anchors.fill: parent
    visible: !!(controller && controller.nav.bracket)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Barre de navigation
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8; Layout.topMargin: 4; Layout.bottomMargin: 2
            Button {
                text: (controller && controller.nav.detail) ? i18n("‹ Match") : i18n("‹ Back")
                icon.name: "go-previous"; flat: true
                onClicked: {
                    if (controller) {
                        controller.nav.bracket = false
                        if (controller.nav.detail) {
                            // Déjà ouvert en arrière-plan ou via DetailView
                        }
                    }
                }
            }
            Item { Layout.fillWidth: true }
            Label {
                text: "🏆 " + i18n("Playoffs")
                font.bold: true; font.pixelSize: 16
                rightPadding: 12
            }
        }

        // Chargement / erreur
        Label {
            Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 20
            visible: !!(controller && controller.brk.loading)
            text: i18n("Loading…"); opacity: 0.6; font.italic: true
        }
        Label {
            Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 20
            visible: !!(controller && !controller.brk.loading && controller.brk.error !== '')
            text: controller ? controller.brk.error : ""
            color: Kirigami.Theme.negativeTextColor
        }

        // Bracket
        ScrollView {
            id: bracketScroll
            Layout.fillWidth: true; Layout.fillHeight: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            visible: !!(controller && !controller.brk.loading && controller.brk.error === '' && controller.brk.data !== null)

            ColumnLayout {
                width: Math.min(360, bracketScroll.availableWidth)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Repeater {
                    model: (controller && controller.brk.data) ? (controller.brk.data.rounds || []) : []
                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        // En-tête de ronde
                        Label {
                            Layout.leftMargin: 12; Layout.topMargin: 4
                            text: controller ? controller.playoffRoundLabel(modelData.roundNumber || 0) : ""
                            font.bold: true; font.pixelSize: 14
                            color: Kirigami.Theme.disabledTextColor
                        }

                        // Séries de la ronde
                        Repeater {
                            model: modelData.series || []
                            delegate: ItemDelegate {
                                Layout.fillWidth: true
                                Layout.leftMargin: 8; Layout.rightMargin: 8
                                contentItem: RowLayout {
                                    spacing: 8

                                    // Équipe visiteur
                                    Rectangle {
                                        radius: 3
                                        color: Logic.getTeamColor(modelData.topSeedTeam ? modelData.topSeedTeam.abbrev : '')
                                        width: awBracketLbl.implicitWidth + 10
                                        height: awBracketLbl.implicitHeight + 6
                                        Label {
                                            id: awBracketLbl
                                            anchors.centerIn: parent
                                            text: modelData.topSeedTeam ? modelData.topSeedTeam.abbrev : '?'
                                            color: Logic.getTeamTextColor(modelData.topSeedTeam ? modelData.topSeedTeam.abbrev : '')
                                            font.bold: true; font.pixelSize: 13
                                            font.family: "monospace"
                                        }
                                    }

                                    // Score de série
                                    Label {
                                        text: (modelData.topSeedWins || 0) + " – " + (modelData.bottomSeedWins || 0)
                                        font.bold: true; font.pixelSize: 16
                                        color: Kirigami.Theme.textColor
                                    }

                                    // Équipe locale
                                    Rectangle {
                                        radius: 3
                                        color: Logic.getTeamColor(modelData.bottomSeedTeam ? modelData.bottomSeedTeam.abbrev : '')
                                        width: hmBracketLbl.implicitWidth + 10
                                        height: hmBracketLbl.implicitHeight + 6
                                        Label {
                                            id: hmBracketLbl
                                            anchors.centerIn: parent
                                            text: modelData.bottomSeedTeam ? modelData.bottomSeedTeam.abbrev : '?'
                                            color: Logic.getTeamTextColor(modelData.bottomSeedTeam ? modelData.bottomSeedTeam.abbrev : '')
                                            font.bold: true; font.pixelSize: 13
                                            font.family: "monospace"
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Statut de la série
                                    Label {
                                        text: modelData.seriesAbbrev || ''
                                        font.pixelSize: 12
                                        opacity: 0.7
                                        color: Kirigami.Theme.disabledTextColor
                                    }
                                }
                            }
                        }

                        // Séparateur entre rondes
                        Rectangle {
                            Layout.fillWidth: true; height: 1
                            color: Kirigami.Theme.textColor; opacity: 0.1
                        }
                    }
                }
                Item { implicitHeight: 8 }
            }
        }
    }
}
