import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic
import "../components" as Components

Item {
    id: searchRoot
    property var controller

    anchors.fill: parent
    visible: controller && controller.nav.search && !controller.nav.player

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── En-tête (Style 8.png) ──
        Item {
            Layout.fillWidth: true
            implicitHeight: 50

            Button {
                id: backBtn
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: i18n("‹ Match")
                flat: true
                onClicked: {
                    if (controller) controller.nav.search = false
                }
            }

            Label {
                anchors.centerIn: parent
                text: i18n("Search")
                font.bold: true
                font.pixelSize: 18
                color: Kirigami.Theme.textColor
            }
        }

        // ── Boîte de recherche (Sous le titre) ──
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 12
            spacing: 10

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: i18n("Player name…")
                text: controller ? controller.srch.query : ""
                onTextChanged: { if (controller) controller.srch.query = text }
                Keys.onReturnPressed: if (controller) controller.fetchSearch(text)
                Keys.onEnterPressed: if (controller) controller.fetchSearch(text)
                
                // Style épuré
                background: Rectangle {
                    implicitHeight: 36
                    color: Qt.rgba(0, 0, 0, 0.2)
                    radius: 6
                    border.color: searchField.activeFocus ? Kirigami.Theme.highlightColor : Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1
                }
            }

            Button {
                implicitWidth: 40
                implicitHeight: 36
                icon.name: "search"
                display: AbstractButton.IconOnly
                ToolTip.text: i18n("Search")
                ToolTip.visible: hovered
                onClicked: if (controller) controller.fetchSearch(searchField.text)
                enabled: searchField.text.length >= 2
            }
        }

        // ── Séparateur subtil ──
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Kirigami.Theme.textColor
            opacity: 0.05
        }

        // Gestion de l'état (Chargement / Erreur)
        Components.StateLayer {
            loading: !!controller && controller.srch.loading
            error: controller ? controller.srch.error : ""
            loadingText: i18n("Searching players…")
            topMargin: 40
        }

        // ── Résultats ──
        ScrollView {
            id: searchScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            visible: controller && !controller.srch.loading

            ColumnLayout {
                width: Math.min(400, parent.width)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2

                Repeater {
                    model: controller ? controller.srch.results : []
                    delegate: ItemDelegate {
                        Layout.fillWidth: true
                        topPadding: 8; bottomPadding: 8
                        leftPadding: 16; rightPadding: 16
                        
                        background: Rectangle {
                            color: hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                            radius: 4
                        }

                        onClicked: if (controller) controller.openPlayer(modelData.id, 'search')

                        contentItem: RowLayout {
                            spacing: 12

                            Rectangle {
                                visible: modelData.team !== ''
                                radius: 4
                                color: Logic.getTeamColor(modelData.team)
                                width: 38; height: 22
                                Label {
                                    anchors.centerIn: parent
                                    text: modelData.team
                                    color: Logic.getTeamTextColor(modelData.team)
                                    font.pixelSize: 11; font.bold: true; font.family: "monospace"
                                }
                            }

                            Label {
                                visible: modelData.team === ''
                                text: "🏒"
                                font.pixelSize: 16; opacity: 0.4
                            }

                            ColumnLayout {
                                spacing: 0; Layout.fillWidth: true
                                Label {
                                    text: modelData.name
                                    font.pixelSize: 14; font.bold: true
                                    color: Kirigami.Theme.textColor
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: (modelData.position || '')
                                          + (modelData.active ? '' : '  ·  ' + i18n("Retired"))
                                    font.pixelSize: 11; opacity: 0.6
                                    color: Kirigami.Theme.disabledTextColor
                                }
                            }
                            
                            Label {
                                text: "›"
                                font.pixelSize: 18
                                opacity: 0.3
                                color: Kirigami.Theme.textColor
                            }
                        }
                    }
                }
                Item { implicitHeight: 20 }
            }
        }
    }
}
