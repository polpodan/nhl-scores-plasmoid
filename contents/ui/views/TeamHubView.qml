import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic
import "../components" as Components

Item {
    id: teamHubRoot
    property var controller

    anchors.fill: parent
    visible: !!(controller && controller.nav.teamHub && !controller.nav.schedule)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Barre navigation ─────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8; Layout.topMargin: 4; Layout.bottomMargin: 2
            Button {
                text: (controller && controller.hub.from === 'standings')
                      ? i18n("‹ Standings") : i18n("‹ Match")
                icon.name: "go-previous"; flat: true
                onClicked: {
                    if (controller) {
                        controller.nav.teamHub = false
                        if (controller.hub.from === 'standings')
                            controller.nav.standings = true
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }

        // Gestion de l'état (Chargement)
        Components.StateLayer {
            loading: !!controller && controller.hub.loading
        }

        ScrollView {
            id: teamHubScrollView
            Layout.fillWidth: true; Layout.fillHeight: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            visible: !!(controller && !controller.hub.loading)

            ColumnLayout {
                width: Math.min(340, teamHubScrollView.availableWidth)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                // ── En-tête : logo + nom + entraîneur ────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    spacing: 4

                    Image {
                        Layout.alignment: Qt.AlignHCenter
                        source: controller ? controller.teamLogoUrl(controller.hub.code) : ""
                        width: 72; height: 72
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        sourceSize.width: 144
                        sourceSize.height: 144
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        text: (controller && controller.hub.fullName !== '')
                              ? controller.hub.fullName
                              : (controller ? controller.hub.code : "")
                        font.bold: true; font.pixelSize: 17
                        color: controller ? controller.teamColorAdapted(controller.hub.code) : Kirigami.Theme.textColor
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        visible: !!(controller && controller.hub.coach !== '')
                        text: "🧑‍💼 " + (controller ? controller.hub.coach : "")
                        font.pixelSize: 11; opacity: 0.7
                        color: Kirigami.Theme.disabledTextColor
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // ── Grille stats centrée ──────────────────────
                Rectangle {
                    Layout.fillWidth: true; Layout.leftMargin: 8; Layout.rightMargin: 8
                    height: 1; color: controller ? Logic.getTeamColor(controller.hub.code) : Kirigami.Theme.highlightColor; opacity: 0.4
                }

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20

                    Repeater {
                        model: [
                            { v: (controller ? String(controller.hub.gp) : "0"),  l: "GP"  },
                            { v: (controller ? String(controller.hub.w) : "0"),   l: "W"   },
                            { v: (controller ? String(controller.hub.l) : "0"),   l: "L"   },
                            { v: (controller ? String(controller.hub.ot) : "0"),  l: "OT"  },
                            { v: (controller ? String(controller.hub.pts) : "0"), l: "PTS" }
                        ]
                        delegate: Column {
                            spacing: 2; width: 40
                            Label {
                                width: parent.width
                                text: modelData.l
                                font.pixelSize: 10; opacity: 0.55
                                color: Kirigami.Theme.disabledTextColor
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Label {
                                width: parent.width
                                text: modelData.v
                                font.pixelSize: 18; font.bold: true
                                color: Kirigami.Theme.textColor
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    visible: !!(controller && controller.hub.standing !== '')
                    text: controller ? controller.hub.standing : ""
                    font.pixelSize: 11; opacity: 0.6
                    color: Kirigami.Theme.disabledTextColor
                }

                // ── Derniers matchs ───────────────────────────
                Rectangle {
                    Layout.fillWidth: true; Layout.leftMargin: 8; Layout.rightMargin: 8
                    height: 1; color: Kirigami.Theme.textColor; opacity: 0.12
                }
                Label {
                    Layout.leftMargin: 12
                    text: i18n("Last games")
                    font.pixelSize: 11; font.bold: true; opacity: 0.55
                    color: Kirigami.Theme.disabledTextColor
                }

                Repeater {
                    model: controller ? controller.hub.lastGames : []
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12; Layout.rightMargin: 12
                        spacing: 6

                        Rectangle {
                            radius: 3
                            color: modelData.win
                                   ? (modelData.ot ? "#1a6a3a" : "#1a7a2a")
                                   : (modelData.ot ? "#5a3a1a" : "#7a1a1a")
                            width: 38; height: wlLbl.implicitHeight + 4
                            Label {
                                id: wlLbl; anchors.centerIn: parent
                                text: modelData.win
                                      ? (modelData.ot ? "OTW" : "W")
                                      : (modelData.ot ? "OTL" : "L")
                                color: "white"; font.bold: true; font.pixelSize: 11
                            }
                        }

                        Label {
                            text: modelData.home ? i18n("vs") : i18n("@")
                            font.pixelSize: 11; opacity: 0.55
                            Layout.preferredWidth: 18
                            horizontalAlignment: Text.AlignHCenter
                            color: Kirigami.Theme.textColor
                        }

                        Rectangle {
                            radius: 3
                            color: Logic.getTeamColor(modelData.opp || '')
                            width: oppHubLbl.implicitWidth + 8
                            height: oppHubLbl.implicitHeight + 4
                            Label {
                                id: oppHubLbl; anchors.centerIn: parent
                                text: modelData.opp || '?'
                                color: Logic.getTeamTextColor(modelData.opp || '')
                                font.bold: true; font.pixelSize: 11
                                font.family: "monospace"
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: (modelData.gf || 0) + " – " + (modelData.ga || 0)
                            font.pixelSize: 13; font.bold: true
                            color: modelData.win ? "#44bb44" : Kirigami.Theme.textColor
                        }
                    }
                }

                // ── Prochain match ────────────────────────────
                Rectangle {
                    Layout.fillWidth: true; Layout.leftMargin: 8; Layout.rightMargin: 8
                    height: 1; color: Kirigami.Theme.textColor; opacity: 0.12
                }

                RowLayout {
                    visible: !!(controller && controller.hub.nextGame !== null)
                    Layout.fillWidth: true
                    Layout.leftMargin: 12; Layout.rightMargin: 12
                    spacing: 6

                    Label {
                        text: i18n("Next:")
                        font.pixelSize: 11; font.bold: true; opacity: 0.55
                        color: Kirigami.Theme.disabledTextColor
                    }

                    Label {
                        text: (controller && controller.hub.nextGame)
                              ? (controller.hub.nextGame.home ? i18n("vs") : i18n("@"))
                              : ''
                        font.pixelSize: 12; opacity: 0.7
                        color: Kirigami.Theme.textColor
                    }

                    Rectangle {
                        radius: 3
                        visible: !!(controller && controller.hub.nextGame !== null)
                        color: (controller && controller.hub.nextGame) ? Logic.getTeamColor(controller.hub.nextGame.opp || '') : "gray"
                        width: nextOppLbl.implicitWidth + 8
                        height: nextOppLbl.implicitHeight + 4
                        Label {
                            id: nextOppLbl; anchors.centerIn: parent
                            text: (controller && controller.hub.nextGame) ? (controller.hub.nextGame.opp || '?') : ''
                            color: (controller && controller.hub.nextGame) ? Logic.getTeamTextColor(controller.hub.nextGame.opp || '') : "white"
                            font.bold: true; font.pixelSize: 11; font.family: "monospace"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: (controller && controller.hub.nextGame && controller.hub.nextGame.start)
                              ? Qt.formatDateTime(new Date(controller.hub.nextGame.start), "ddd d MMM · hh:mm")
                              : ''
                        font.pixelSize: 11; opacity: 0.7
                        color: Kirigami.Theme.disabledTextColor
                    }
                }

                // ── Boutons ───────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true; Layout.leftMargin: 8; Layout.rightMargin: 8
                    height: 1; color: Kirigami.Theme.textColor; opacity: 0.12
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12; Layout.rightMargin: 12
                    Layout.bottomMargin: 8
                    spacing: 8
                    Button {
                        text: i18n("📅 Schedule"); flat: true; Layout.fillWidth: true
                        onClicked: { if (controller) controller.openSchedule(controller.hub.code, false) }
                    }
                    Button {
                        text: i18n("📊 Stats"); flat: true; Layout.fillWidth: true
                        onClicked: { if (controller) controller.openSchedule(controller.hub.code, true) }
                    }
                }
                Item { implicitHeight: 4 }
            }
        }
    }
}
