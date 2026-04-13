import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic
import "../components" as Components
import "detail" as Detail

ScrollView {
    id: detailRoot
    property var controller
    
    readonly property var root: controller

    contentWidth: width
    clip: true

    Item {
        width: detailRoot.width
        implicitHeight: detailNavBar.implicitHeight + detailColumn.implicitHeight + 40

        // ── Barre de navigation ─────────────────
        RowLayout {
            id: detailNavBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 4
            anchors.leftMargin: 4
            anchors.rightMargin: 4

            Button {
                text: "✕"
                flat: true
                onClicked: {
                    if (controller && controller.closePopup) {
                        controller.closePopup()
                    } else if (controller) {
                        controller.nav.detail = false
                        controller.expanded = false
                    }
                }
            }
            Item { Layout.fillWidth: true }
            Button {
                text: i18n("Standings")
                icon.name: "view-list-symbolic"
                flat: true
                onClicked: controller.openStandings()
            }
            Item { Layout.fillWidth: true }
            Button {
                text: i18n("Leaders")
                icon.name: "view-statistics"
                flat: true
                onClicked: controller.openLeaders()
            }
            Item { Layout.fillWidth: true; visible: !controller.isPopup }
            Button {
                visible: !controller.isPopup
                text: i18n("2026 Playoffs")
                icon.name: "trophy-gold"
                flat: true
                onClicked: controller.openSimulationBracket()
            }
            Item { Layout.fillWidth: true; visible: !controller.isPopup }
            Button {
                visible: !controller.isPopup
                text: i18n("Search")
                icon.name: "search"
                flat: true
                onClicked: controller.openSearch()
            }
            Item { Layout.fillWidth: true; visible: !controller.isPopup }
            Button {
                visible: !controller.isPopup
                text: "NHL.com"
                icon.name: "internet-web-browser"
                flat: true
                onClicked: Qt.openUrlExternally(controller.gameCenterUrl(controller.det.away, controller.det.home, controller.det.start, controller.det.gameId))
            }
            Button {
                icon.name: "view-refresh"
                flat: true
                onClicked: controller.refresh()
            }
        }

        ColumnLayout {
            id: detailColumn
            width: Math.min((controller && controller.styles) ? controller.styles.hubWidth : 320, parent.width - 32)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: detailNavBar.bottom
            anchors.topMargin: 4
            spacing: 8

            // ── En-tête score ────────────────────────────────────────
            Detail.DetailHeader {
                Layout.fillWidth: true
                controller: detailRoot.controller
            }

            // ── Preview match à venir ─────────────────────────────────────────
            Detail.MatchPreview {
                Layout.fillWidth: true
                controller: detailRoot.controller
            }

            // Date du match (Matchs terminés ou en direct)
            Label {
                visible: controller && controller.det.start > 0 && controller.det.status !== 'UPCOMING'
                Layout.alignment: Qt.AlignHCenter
                text: controller && controller.det.start > 0 ? Qt.formatDateTime(new Date(controller.det.start), "hh:mm  ·  ddd d MMM yyyy") : ""
                font.pixelSize: 13
                font.bold: true
                color: Kirigami.Theme.textColor
            }

            // Gestion de l'état (Chargement / Erreur)
            Components.StateLayer {
                loading: !!controller && controller.det.loading
                error: controller ? controller.det.error : ""
                topMargin: 10
            }

            // ── Stats du match (Tirs, PP, etc.) ──────────────────────────────
            Detail.MatchStats {
                visible: controller && !controller.det.loading && controller.det.status !== 'UPCOMING'
                Layout.fillWidth: true
                controller: detailRoot.controller
            }

            // ── Onglets ────────────────────────────────────────────────────────
            RowLayout {
                visible: controller && !controller.det.loading && controller.det.status !== 'UPCOMING'
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                Label {
                    text: i18n("Goals")
                    font.bold: controller.det.view === 'goals'
                    font.pixelSize: 14
                    color: controller.det.view === 'goals' ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                    opacity: font.bold ? 1.0 : 0.45
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: controller.det.view = 'goals' }
                }
                Label { text: "·"; font.pixelSize: 14; opacity: 0.3; visible: controller && controller.det.penalties.length > 0 }
                Label {
                    visible: controller && controller.det.penalties.length > 0
                    text: i18n("Penalties")
                    font.bold: controller.det.view === 'penalties'
                    font.pixelSize: 14
                    color: controller.det.view === 'penalties' ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                    opacity: font.bold ? 1.0 : 0.45
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: controller.det.view = 'penalties' }
                }
                Label { text: "·"; font.pixelSize: 14; opacity: 0.3; visible: controller && controller.det.threeStars.length > 0 }
                Label {
                    visible: controller && controller.det.threeStars.length > 0
                    text: "⭐ " + i18n("Stars")
                    font.bold: controller.det.view === 'stars'
                    font.pixelSize: 14
                    color: controller.det.view === 'stars' ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                    opacity: font.bold ? 1.0 : 0.45
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: controller.det.view = 'stars' }
                }
            }

            // ── Listes (Buts / Pénalités / Étoiles) ───────────────────────────
            Detail.GoalsList {
                visible: controller && controller.det.view === 'goals' && !controller.det.loading
                controller: detailRoot.controller
            }

            Detail.PenaltiesList {
                visible: controller && controller.det.view === 'penalties' && !controller.det.loading
                controller: detailRoot.controller
            }

            Detail.StarsList {
                visible: controller && controller.det.view === 'stars' && !controller.det.loading
                controller: detailRoot.controller
            }
            
            Item { Layout.preferredHeight: 20 }
        }
    }
}
