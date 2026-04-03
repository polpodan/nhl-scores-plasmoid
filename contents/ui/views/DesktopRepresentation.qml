import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic

Item {
    id: desktopRoot
    property var controller
    
    readonly property var root: controller

    implicitWidth: 360
    implicitHeight: Math.max(200, desktopList.contentHeight + desktopHeader.implicitHeight + 16)

    readonly property int hubW: (controller && controller.styles) ? controller.styles.hubWidth : 320
    readonly property int cardW: (controller && controller.styles) ? controller.styles.cardWidth : 480

    // ── En-tête ─────────────────────────────────────────────────
    Item {
        id: desktopHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: headerRow.implicitHeight + 16

        RowLayout {
            id: headerRow
            anchors.centerIn: parent
            width: Math.min(480, parent.width - 16)
            spacing: 6

            Label {
                text: i18n("NHL Scores")
                font.bold: true
                font.pixelSize: 13
                color: Kirigami.Theme.textColor
            }
            Label {
                id: lastUpdatedLabel
                visible: root && root.glob.lastUpdated instanceof Date
                font.pixelSize: 10
                opacity: 0.5
                text: {
                    var p = root ? root.glob.pulse : 0 // Dépendance au pulse central
                    if (!root || !(root.glob.lastUpdated instanceof Date)) return ""
                    var diff = Math.floor((new Date() - root.glob.lastUpdated) / 60000)
                    if (diff < 1) return i18n("just now")
                    if (diff === 1) return i18n("1 min ago")
                    return diff + " " + i18n("min ago")
                }
            }
            Item {
                Layout.fillWidth: true
            }
            Button {
                text: i18n("Standings")
                icon.name: "view-list-symbolic"
                flat: true
                font.pixelSize: 10
                onClicked: {
                    if (root) {
                        root.openStandings()
                    }
                }
            }
            Button {
                text: i18n("Leaders")
                icon.name: "view-statistics"
                flat: true
                font.pixelSize: 10
                onClicked: {
                    if (root) {
                        root.openLeaders()
                    }
                }
            }
            Button {
                icon.name: "view-refresh"
                flat: true
                font.pixelSize: 10
                ToolTip.text: i18n("Refresh now")
                ToolTip.visible: hovered
                onClicked: {
                    if (root) root.refresh()
                }
            }
        }
    }

    Rectangle {
        id: desktopSep
        anchors.top: desktopHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 2
        height: 1
        color: Kirigami.Theme.textColor
        opacity: 0.1
    }

    // ── Liste des cartes de matchs ──────────────────────────────
    ListView {
        id: desktopList
        anchors.top: desktopSep.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 4
        model: root ? root.todayGamesModel : null
        spacing: root ? root.spacingBetweenGames : 8
        clip: true

        delegate: Item {
            id: desktopDelegate
            width: desktopList.width
            height: model.statusRole === 'DATE_SEP' ? 32 : 90
            visible: model.gameIndex < (root ? root.maxGames : 10)

            Rectangle {
                visible: model.statusRole === 'DATE_SEP'
                anchors.centerIn: parent
                width: dateSepLbl.implicitWidth + 24
                height: 24
                radius: 4
                color: Kirigami.Theme.alternateBackgroundColor
                border.color: Kirigami.Theme.textColor
                border.width: 1
                opacity: 0.7
                Label {
                    id: dateSepLbl
                    anchors.centerIn: parent
                    text: root ? root.localeDateLong(new Date(model.start).getTime()) : ""
                    font.pixelSize: 11
                    font.bold: true
                }
            }

            property string dAway: model.away || ""
            property string dHome: model.home || ""
            property int dAg: model.ag || 0
            property int dHg: model.hg || 0
            property string dStatus: model.statusRole || "UPCOMING"
            property string dRaw: model.rawState || ""
            property string dPType: model.periodType || ""
            property int dPeriod: model.period || 0
            property string dRemain: model.liveRemain || ""
            property var dStart: model.start || 0
            property bool dInterm: model.inIntermission || false
            property string dSit: (typeof situationCode === "string" ? situationCode : "1551")
            property string dPen: (typeof penaltyTime === "string" ? penaltyTime : "")
            property string dIntRem: (typeof intermissionRemain === "string" ? intermissionRemain : "")

            property bool dBlinkA: {
                if (!root) return false
                var b = root.glob.blinkingGames[String(model.gameId)]
                return !!(b && (b === 'away' || b === 'both'))
            }
            property bool dBlinkH: {
                if (!root) return false
                var b = root.glob.blinkingGames[String(model.gameId)]
                return !!(b && (b === 'home' || b === 'both'))
            }

            Rectangle {
                id: card
                visible: model.statusRole !== 'DATE_SEP'
                width: Math.min(480, parent.width - 16)
                height: 80
                anchors.centerIn: parent
                radius: 6
                color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.6)
                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                border.width: 1
                opacity: dStatus === 'FINAL' ? 0.7 : 1.0

                // Contenu resserré au centre
                RowLayout {
                    width: Math.min(card.width - 20, 320)
                    anchors.centerIn: parent
                    spacing: 10

                    // Équipe Visiteur + Score
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle {
                            width: 50
                            height: 32
                            radius: 4
                            color: Logic.getTeamColor(dAway)
                            opacity: (dBlinkA && root && !root.glob.blinkOn) ? 0.0 : 1.0
                            Label {
                                anchors.centerIn: parent
                                text: dAway
                                color: Logic.getTeamTextColor(dAway)
                                font.pixelSize: 15
                                font.bold: true
                                font.family: "monospace"
                            }
                        }
                        Label {
                            visible: dStatus !== 'UPCOMING'
                            text: String(dAg)
                            font.pixelSize: 26
                            font.bold: true
                            color: (dStatus === 'LIVE' && dAg > dHg) ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                            opacity: (dBlinkA && root && !root.glob.blinkOn) ? 0.0 : 1.0
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Item { Layout.fillWidth: true }
                    }

                            Loader {
                                Layout.alignment: Qt.AlignHCenter
                                sourceComponent: root ? root.statusBadgeComponent : null
                                property string gameStatus: dStatus
                                property string rawState: dRaw
                                property string periodType: dPType
                                property int period: dPeriod
                                property string liveRemain: dRemain
                                property var startMs: dStart
                                property string awayTeam: dAway
                                property string homeTeam: dHome
                                property bool intermission: dInterm
                                property string intermissionRemain: dIntRem
                                property string situationCode: dSit
                                property string penaltyTime: dPen
                                // On force des polices plus grandes pour le bureau via l'objet styles
                                property int fontSize1: (root && root.styles) ? root.styles.badge.desktopFontSize : 12
                                property int fontSize2: (root && root.styles) ? root.styles.badge.desktopSmallFontSize : 10
                            }

                    // Score + Équipe Locale
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Item { Layout.fillWidth: true }
                        Label {
                            visible: dStatus !== 'UPCOMING'
                            text: String(dHg)
                            font.pixelSize: 26
                            font.bold: true
                            color: (dStatus === 'LIVE' && dHg > dAg) ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                            opacity: (dBlinkH && root && !root.glob.blinkOn) ? 0.0 : 1.0
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Rectangle {
                            width: 50
                            height: 32
                            radius: 4
                            color: Logic.getTeamColor(dHome)
                            opacity: (dBlinkH && root && !root.glob.blinkOn) ? 0.0 : 1.0
                            Label {
                                anchors.centerIn: parent
                                text: dHome
                                color: Logic.getTeamTextColor(dHome)
                                font.pixelSize: 15
                                font.bold: true
                                font.family: "monospace"
                            }
                        }
                    }
                }

                Rectangle {
                    visible: root && root.glob.blinkingGames[String(model.gameId)] !== undefined
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 60
                    height: 16
                    color: Kirigami.Theme.positiveBackgroundColor
                    radius: 3
                    anchors.topMargin: -8
                    border.color: "white"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "🚨 BUT"
                        font.pixelSize: 9
                        font.bold: true
                        color: Kirigami.Theme.positiveTextColor
                    }
                }

                TapHandler {
                    onTapped: {
                        if (root) {
                            root.openDetail(model.gameId, dAway, dHome, dAg, dHg, dStatus, dPType, dPeriod, dRemain, dStart, dInterm, dSit)
                        }
                    }
                }
            }
        }

        Label {
            anchors.centerIn: parent
            visible: desktopList.count === 0
            text: i18n("No games today")
            opacity: 0.5
            font.italic: true
        }
    }
}
