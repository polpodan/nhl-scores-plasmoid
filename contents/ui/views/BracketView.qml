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

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Barre de navigation ─────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8; Layout.topMargin: 4; Layout.bottomMargin: 2
            Button {
                text: (controller && controller.nav.detail) ? i18n("‹ Match") : i18n("‹ Back")
                icon.name: "go-previous"; flat: true
                onClicked: {
                    if (controller) {
                        controller.nav.bracket = false
                    }
                }
            }
            Item { Layout.fillWidth: true }
            Label {
                text: i18n("🏆 STANLEY CUP PLAYOFFS 2026")
                font.bold: true; font.pixelSize: 14
                rightPadding: 12
            }
        }

        // ── Chargement ──────────────────────────────────────────────
        Label {
            Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 20
            visible: !!(controller && controller.brk.loading)
            text: i18n("Loading…"); opacity: 0.6; font.italic: true
        }

        // ── Arbre du Tournoi (Vertical) ──────────────────────────────
        ScrollView {
            id: bracketScroll
            Layout.fillWidth: true; Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true
            visible: !!(controller && !controller.brk.loading && controller.brk.data !== null)

            // Fonction pour récupérer un match spécifique
            function getSeries(roundIndex, seriesIndex) {
                if (!controller || !controller.brk.data || !controller.brk.data.rounds) return null;
                var round = controller.brk.data.rounds[roundIndex];
                if (!round || !round.series) return null;
                return round.series[seriesIndex] || null;
            }

            // Composant Carte de Match
            Component {
                id: matchupCard
                Rectangle {
                    readonly property var sData: parent.seriesData
                    
                    width: 160; height: 74; radius: 6
                    color: Qt.rgba(0, 0, 0, 0.4)
                    border.color: Kirigami.Theme.textColor; border.width: 1
                    opacity: sData ? 1.0 : 0.2

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 6; spacing: 2
                        
                        // Équipe du Haut
                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Components.TeamBadge {
                                id: tbTop
                                code: (sData && sData.topSeedTeam) ? (sData.topSeedTeam.abbrev || "") : ""
                                opponentCode: (sData && sData.bottomSeedTeam) ? (sData.bottomSeedTeam.abbrev || "") : ""
                                teamSide: 'away'
                                sz: 14
                                showScore: false
                                controller: bracketRoot.controller
                                visible: code !== ""
                            }
                            Label { 
                                text: (sData && sData.topSeedTeam && sData.topSeedTeam.seed) ? sData.topSeedTeam.seed : (sData ? "" : "TBD")
                                font.pixelSize: 10; font.bold: true; opacity: 0.7; color: Kirigami.Theme.textColor 
                            }
                            Item { Layout.fillWidth: true }
                            Label { 
                                text: sData && sData.topSeedWins !== undefined ? sData.topSeedWins : "0"
                                font.bold: true; font.pixelSize: 16; color: Kirigami.Theme.textColor 
                            }

                            TapHandler {
                                onTapped: if(tbTop.code && controller) controller.openTeamHub(tbTop.code, 'bracket')
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor; enabled: !!tbTop.code }
                        }
                        
                        Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.1 }

                        // Équipe du Bas
                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Components.TeamBadge {
                                id: tbBottom
                                code: (sData && sData.bottomSeedTeam) ? (sData.bottomSeedTeam.abbrev || "") : ""
                                opponentCode: (sData && sData.topSeedTeam) ? (sData.topSeedTeam.abbrev || "") : ""
                                teamSide: 'home'
                                sz: 14
                                showScore: false
                                controller: bracketRoot.controller
                                visible: code !== ""
                            }
                            Label { 
                                text: (sData && sData.bottomSeedTeam && sData.bottomSeedTeam.seed) ? sData.bottomSeedTeam.seed : (sData ? "" : "TBD")
                                font.pixelSize: 10; font.bold: true; opacity: 0.7; color: Kirigami.Theme.textColor 
                            }
                            Item { Layout.fillWidth: true }
                            Label { 
                                text: sData && sData.bottomSeedWins !== undefined ? sData.bottomSeedWins : "0"
                                font.bold: true; font.pixelSize: 16; color: Kirigami.Theme.textColor 
                            }

                            TapHandler {
                                onTapped: if(tbBottom.code && controller) controller.openTeamHub(tbBottom.code, 'bracket')
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor; enabled: !!tbBottom.code }
                        }
                    }
                }
            }

            ColumnLayout {
                id: treeLayout
                width: parent.width
                spacing: 20
                Layout.margins: 10

                // ── CONFÉRENCE OUEST ──
                Label { text: i18n("WESTERN CONFERENCE"); font.bold: true; font.pixelSize: 12; Layout.alignment: Qt.AlignHCenter; opacity: 0.6 }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15
                    Layout.alignment: Qt.AlignHCenter

                    // R1 Ouest
                    ColumnLayout {
                        spacing: 10
                        Loader { sourceComponent: matchupCard; property var seriesData: bracketScroll.getSeries(0, 0) }
                        Loader { sourceComponent: matchupCard; property var seriesData: bracketScroll.getSeries(0, 1) }
                        Loader { sourceComponent: matchupCard; property var seriesData: bracketScroll.getSeries(0, 2) }
                        Loader { sourceComponent: matchupCard; property var seriesData: bracketScroll.getSeries(0, 3) }
                    }

                    // R2 Ouest
                    ColumnLayout {
                        spacing: 40
                        Loader { sourceComponent: matchupCard; property var seriesData: bracketScroll.getSeries(1, 0) }
                        Loader { sourceComponent: matchupCard; property var seriesData: bracketScroll.getSeries(1, 1) }
                    }

                    // CF Ouest
                    ColumnLayout {
                        Loader { sourceComponent: matchupCard; property var seriesData: bracketScroll.getSeries(2, 0) }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.1; Layout.margins: 10 }

                // ── FINALE COUPE STANLEY (CENTRE) ──
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10
                    Label { text: i18n("STANLEY CUP FINALS"); font.bold: true; font.pixelSize: 16; Layout.alignment: Qt.AlignHCenter; color: Kirigami.Theme.highlightColor }
                    Loader { sourceComponent: matchupCard; property var seriesData: bracketScroll.getSeries(3, 0); Layout.preferredWidth: 200 }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.1; Layout.margins: 10 }

                // ── CONFÉRENCE EST ──
                Label { text: i18n("EASTERN CONFERENCE"); font.bold: true; font.pixelSize: 12; Layout.alignment: Qt.AlignHCenter; opacity: 0.6 }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15
                    Layout.alignment: Qt.AlignHCenter

                    // CF Est
                    ColumnLayout {
                        Loader { sourceComponent: matchupCard; property var seriesData: bracketScroll.getSeries(2, 1) }
                    }

                    // R2 Est
                    ColumnLayout {
                        spacing: 40
                        Loader { sourceComponent: matchupCard; property var seriesData: bracketScroll.getSeries(1, 2) }
                        Loader { sourceComponent: matchupCard; property var seriesData: bracketScroll.getSeries(1, 3) }
                    }

                    // R1 Est
                    ColumnLayout {
                        spacing: 10
                        Loader { sourceComponent: matchupCard; property var seriesData: bracketScroll.getSeries(0, 4) }
                        Loader { sourceComponent: matchupCard; property var seriesData: bracketScroll.getSeries(0, 5) }
                        Loader { sourceComponent: matchupCard; property var seriesData: bracketScroll.getSeries(0, 6) }
                        Loader { sourceComponent: matchupCard; property var seriesData: bracketScroll.getSeries(0, 7) }
                    }
                }
                
                Item { height: 20 }
            }
        }
    }
}
