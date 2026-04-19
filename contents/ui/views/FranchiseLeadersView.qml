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
                        controller.nav.teamHub = true
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

                // Logo
                Image {
                    source: controller ? controller.teamLogoUrl(controller.flead.team) : ""
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 120
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    Layout.alignment: Qt.AlignHCenter
                }

                // ── FILTRES ──
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    // 1. Positions (Fwd, Def, Goal)
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 2
                        spacing: 6
                        Repeater {
                            model: [
                                { lbl: i18n("Fwd"),     prop: "filterF" },
                                { lbl: i18n("Def"),     prop: "filterD" },
                                { lbl: i18n("Goal"),    prop: "filterG" }
                            ]
                            delegate: Rectangle {
                                radius: 4
                                implicitWidth: fLbl.implicitWidth + 12
                                implicitHeight: fLbl.implicitHeight + 6
                                readonly property bool active: controller && controller.flead[modelData.prop]
                                color: active ? Kirigami.Theme.highlightColor : Qt.rgba(1,1,1,0.07)
                                border.color: active ? Kirigami.Theme.highlightColor : Qt.rgba(1,1,1,0.15)
                                border.width: 1
                                Label {
                                    id: fLbl; anchors.centerIn: parent
                                    text: modelData.lbl
                                    font.pixelSize: 11; font.bold: parent.active
                                    color: parent.active ? "white" : Kirigami.Theme.textColor
                                }
                                TapHandler {
                                    onTapped: {
                                        if (modelData.prop === "filterG") {
                                            var old = controller.flead.filterG
                                            controller.flead.filterG = !old
                                            controller.flead.filterF = false; controller.flead.filterD = false
                                        } else if (modelData.prop === "filterF") {
                                            var oldF = controller.flead.filterF
                                            controller.flead.filterF = !oldF
                                            controller.flead.filterG = false; controller.flead.filterD = false
                                        } else if (modelData.prop === "filterD") {
                                            var oldD = controller.flead.filterD
                                            controller.flead.filterD = !oldD
                                            controller.flead.filterF = false; controller.flead.filterG = false
                                        }
                                        controller.fetchFranchiseLeaders(controller.flead.team)
                                    }
                                }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }

                    // 2. Saison Type (Reg/Post)
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 8
                        spacing: 8
                        Repeater {
                            model: [
                                { lbl: i18n("Reg"), val: 2 },
                                { lbl: i18n("Post"), val: 3 }
                            ]
                            delegate: Rectangle {
                                radius: 4
                                implicitWidth: typeLbl.implicitWidth + 16
                                implicitHeight: typeLbl.implicitHeight + 8
                                readonly property bool active: !!(controller && controller.flead.seasonType === modelData.val)
                                color: active ? Kirigami.Theme.highlightColor : Qt.rgba(1,1,1,0.07)
                                border.color: active ? Kirigami.Theme.highlightColor : Qt.rgba(1,1,1,0.15)
                                border.width: 1
                                Label {
                                    id: typeLbl; anchors.centerIn: parent
                                    text: modelData.lbl
                                    font.pixelSize: 11; font.bold: parent.active
                                    color: parent.active ? "white" : Kirigami.Theme.textColor
                                }
                                TapHandler {
                                    onTapped: {
                                        controller.flead.seasonType = modelData.val
                                        controller.fetchFranchiseLeaders(controller.flead.team)
                                    }
                                }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                }

                // ── CONTENU (SKATERS) ──
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 16
                    visible: !controller.flead.filterG

                    // Points
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Label { Layout.leftMargin: 16; text: "🏆 " + i18n("Points"); font.bold: true; font.pixelSize: 14; color: Kirigami.Theme.textColor }
                        Repeater { model: controller ? controller.flead.points : []; delegate: leaderRowComp }
                    }
                    // Goals
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Label { Layout.leftMargin: 16; text: "🎯 " + i18n("Goals"); font.bold: true; font.pixelSize: 14; color: Kirigami.Theme.textColor }
                        Repeater { model: controller ? controller.flead.goals : []; delegate: leaderRowComp }
                    }
                    // Assists
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Label { Layout.leftMargin: 16; text: "🍎 " + i18n("Assists"); font.bold: true; font.pixelSize: 14; color: Kirigami.Theme.textColor }
                        Repeater { model: controller ? controller.flead.assists : []; delegate: leaderRowComp }
                    }
                }

                // ── CONTENU (GOALIES) ──
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 16
                    visible: controller.flead.filterG

                    // Wins
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Label { Layout.leftMargin: 16; text: "🥅 " + i18n("Wins"); font.bold: true; font.pixelSize: 14; color: Kirigami.Theme.textColor }
                        Repeater { model: controller ? controller.flead.wins : []; delegate: leaderRowComp }
                    }
                    // Shutouts
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Label { Layout.leftMargin: 16; text: "🚫 " + i18n("Shutouts"); font.bold: true; font.pixelSize: 14; color: Kirigami.Theme.textColor }
                        Repeater { model: controller ? controller.flead.sho : []; delegate: leaderRowComp }
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter; text: "* " + i18n("Active player"); font.pixelSize: 10; opacity: 0.5; color: Kirigami.Theme.textColor; Layout.topMargin: 10
                }
            }
        }
    }

    Component {
        id: leaderRowComp
        Rectangle {
            Layout.fillWidth: true; height: 32; color: index % 2 === 0 ? "transparent" : Qt.rgba(1, 1, 1, 0.05)
            TapHandler { onTapped: if (controller && modelData.id) controller.openPlayer(modelData.id, 'franchiseLeaders') }
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 8
                Label { text: (index + 1) + "."; font.pixelSize: 12; opacity: 0.6; Layout.preferredWidth: 20; color: Kirigami.Theme.textColor }
                Label { text: (modelData.name || "") + (modelData.active ? " *" : ""); font.bold: true; font.pixelSize: 13; Layout.fillWidth: true; color: modelData.active ? "#33ff33" : Kirigami.Theme.textColor; elide: Text.ElideRight }
                Label { text: String(modelData.value || 0); font.bold: true; font.pixelSize: 15; color: Kirigami.Theme.textColor; style: Text.Outline; styleColor: Qt.rgba(0, 0, 0, 0.5) }
            }
        }
    }
}
