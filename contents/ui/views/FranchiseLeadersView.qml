import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic
import "../components" as Components

Item {
    id: franchiseLeadersRoot
    property var controller

    anchors.fill: parent
    visible: !!(controller && controller.nav.franchiseLeaders)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Barre de retour ──
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.topMargin: 4
            Layout.bottomMargin: 2
            Button {
                text: i18n("‹ Team")
                icon.name: "go-previous"
                flat: true
                onClicked: {
                    if (controller) {
                        controller.nav.franchiseLeaders = false
                    }
                }
            }
            Item { Layout.fillWidth: true }
            Label {
                text: i18n("Franchise Leaders")
                font.bold: true
                Layout.rightMargin: 12
                color: Kirigami.Theme.textColor
            }
        }

        Components.StateLayer {
            loading: !!controller && controller.flead.loading
            error: (controller && controller.flead.error) ? controller.flead.error : ""
        }

        ScrollView {
            id: leadersScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            visible: !!(controller && !controller.flead.loading)

            ColumnLayout {
                width: leadersScroll.availableWidth
                spacing: 16
                Layout.topMargin: 10
                Layout.bottomMargin: 20

                // Logo et Nom de l'équipe
                Image {
                    source: controller ? controller.teamLogoUrl(controller.flead.team) : ""
                    Layout.preferredWidth: 240
                    Layout.preferredHeight: 240
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    Layout.alignment: Qt.AlignHCenter
                }

                // Points
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Label {
                        Layout.leftMargin: 16
                        text: "🏆 " + i18n("Points")
                        font.bold: true
                        font.pixelSize: 14
                        color: Kirigami.Theme.textColor
                    }
                    Repeater {
                        model: controller ? controller.flead.points : []
                        delegate: leaderRowComp
                    }
                }

                // Goals
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Label {
                        Layout.leftMargin: 16
                        text: "🎯 " + i18n("Goals")
                        font.bold: true
                        font.pixelSize: 14
                        color: Kirigami.Theme.textColor
                    }
                    Repeater {
                        model: controller ? controller.flead.goals : []
                        delegate: leaderRowComp
                    }
                }

                // Assists
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Label {
                        Layout.leftMargin: 16
                        text: "🍎 " + i18n("Assists")
                        font.bold: true
                        font.pixelSize: 14
                        color: Kirigami.Theme.textColor
                    }
                    Repeater {
                        model: controller ? controller.flead.assists : []
                        delegate: leaderRowComp
                    }
                }

                // Note de bas de page
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "* " + i18n("Active player")
                    font.pixelSize: 10
                    opacity: 0.5
                    color: Kirigami.Theme.textColor
                    Layout.topMargin: 10
                }
            }
        }
    }

    // Composant pour une ligne de leader
    Component {
        id: leaderRowComp
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: index % 2 === 0 ? "transparent" : Qt.rgba(1, 1, 1, 0.05)
            
            HoverHandler {
                id: hh
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: {
                    if (controller && modelData.id) {
                        controller.openPlayer(modelData.id, 'franchiseLeaders')
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 8

                Label {
                    text: (index + 1) + "."
                    font.pixelSize: 12
                    opacity: 0.6
                    Layout.preferredWidth: 20
                    color: Kirigami.Theme.textColor
                }

                Label {
                    text: (modelData.name || "") + (modelData.active ? " *" : "")
                    font.bold: true
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    color: modelData.active ? "#33ff33" : Kirigami.Theme.textColor
                    elide: Text.ElideRight
                }

                Item { Layout.preferredWidth: 4 }

                Label {
                    text: String(modelData.value || 0)
                    font.bold: true
                    font.pixelSize: 15
                    color: Kirigami.Theme.textColor
                    style: Text.Outline
                    styleColor: Qt.rgba(0, 0, 0, 0.5)
                }
            }
        }
    }
}
