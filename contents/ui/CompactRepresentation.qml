import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import "logic.js" as Logic
import "components" as Components

Item {
    id: compactRoot
    property var controller

    readonly property int pad: 4
    readonly property int sz: (controller && controller.isVertical) ? 14 : Math.min(20, Math.max(8, Math.round(height * 0.38)))
    readonly property bool forceInline: controller ? (!controller.isVertical && sz < 13.5) : false

    implicitWidth: (controller && controller.isVertical) ? parent.width : Math.max(hRow.implicitWidth + pad, emptyMsg.implicitWidth + pad)
    implicitHeight: (controller && controller.isVertical) ? Math.max(vCol.implicitHeight, emptyMsg.implicitHeight + 2) : Math.max(hRow.implicitHeight + 2, emptyMsg.implicitHeight + 2)

    Layout.preferredWidth: implicitWidth
    Layout.minimumWidth: (controller && controller.isVertical) ? 0 : implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.minimumHeight: (controller && controller.isVertical) ? 0 : implicitHeight
    Layout.fillWidth: (controller && controller.isVertical)
    Layout.fillHeight: (controller && !controller.isVertical)

    function formatDate(ms) {
        var d = new Date(ms);
        var day = d.getDate();
        var month = d.getMonth() + 1;
        return (day < 10 ? "0" : "") + day + "/" + (month < 10 ? "0" : "") + month;
    }

    Label {
        id: emptyMsg
        anchors.centerIn: parent
        visible: controller && controller.todayGamesModel && controller.todayGamesModel.count === 0
        text: (controller && controller.glob.initialLoading) ? i18n("Loading…") : i18n("No games")
        font.pixelSize: Math.max(9, sz * 0.7)
        opacity: 0.5
    }

    // ── MODE HORIZONTAL ──
    Row {
        id: hRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        // Espacement ajustable via config
        spacing: controller ? controller.spacingBetweenGames : 3
        visible: controller && !controller.isVertical && controller.todayGamesModel && controller.todayGamesModel.count > 0

        Repeater {
            model: controller ? controller.todayGamesModel : null
            delegate: Row {
                id: hDelegateWrapper
                spacing: hRow.spacing
                
                readonly property bool isDateSep: model.statusRole === 'DATE_SEP'
                readonly property real csz: compactRoot.sz * 0.88
                readonly property var currentModel: model

                Item {
                    id: delegateItemH
                    width: hDelegateWrapper.isDateSep ? (dateSepContent.implicitWidth + 2) : (contentRow.implicitWidth + 8)
                    height: compactRoot.height
                    opacity: hDelegateWrapper.currentModel.statusRole === 'FINAL' ? 0.6 : 1.0
                    visible: hDelegateWrapper.currentModel.gameIndex < controller.maxGames

                    Rectangle {
                        visible: !hDelegateWrapper.isDateSep && !controller.ultraCompact
                        anchors.fill: parent; anchors.margins: 1; radius: 4
                        color: "transparent"; border.color: Kirigami.Theme.textColor; border.width: 1; opacity: 0.08
                    }

                    Row {
                        id: contentRow
                        anchors.centerIn: parent
                        spacing: 0

                        Row {
                            id: dateSepContent; visible: hDelegateWrapper.isDateSep; spacing: 0
                            Rectangle { width: 1; height: delegateItemH.height * 0.6; anchors.verticalCenter: parent.verticalCenter; color: Kirigami.Theme.textColor; opacity: 0.25 }
                            Text { anchors.verticalCenter: parent.verticalCenter; leftPadding: 3; rightPadding: 3; text: compactRoot.formatDate(hDelegateWrapper.currentModel.start); font.pixelSize: Math.max(8, compactRoot.sz * 0.65); font.bold: true; color: Kirigami.Theme.textColor; opacity: 0.5 }
                            Rectangle { width: 1; height: delegateItemH.height * 0.6; anchors.verticalCenter: parent.verticalCenter; color: Kirigami.Theme.textColor; opacity: 0.25 }
                        }

                        Loader {
                            visible: !hDelegateWrapper.isDateSep && !controller.ultraCompact
                            sourceComponent: (compactRoot.forceInline || controller.scoreLayout === 'stack') ? stackLayoutComp : inlineLayoutComp
                        }

                        Row {
                            visible: controller.ultraCompact && !hDelegateWrapper.isDateSep
                            spacing: 3
                            Rectangle {
                                width: 16; height: 16; radius: 8
                                color: Logic.getTeamColor(hDelegateWrapper.currentModel.away, Kirigami.Theme.positiveBackgroundColor)
                                border.color: 'white'; border.width: 1
                                opacity: controller.blinkOpacity(hDelegateWrapper.currentModel.gameId, 'away')
                                Text { anchors.centerIn: parent; text: hDelegateWrapper.currentModel.away.charAt(0); color: Logic.getTeamTextColor(hDelegateWrapper.currentModel.away); font.pixelSize: 9; font.bold: true }
                            }
                            Text {
                                text: (hDelegateWrapper.currentModel.statusRole === 'UPCOMING') ? "–" : (hDelegateWrapper.currentModel.ag + "–" + hDelegateWrapper.currentModel.hg)
                                font.pixelSize: 9; font.bold: true; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter
                            }
                            Rectangle {
                                width: 16; height: 16; radius: 8
                                color: Logic.getTeamColor(hDelegateWrapper.currentModel.home, Kirigami.Theme.positiveBackgroundColor)
                                border.color: 'white'; border.width: 1
                                opacity: controller.blinkOpacity(hDelegateWrapper.currentModel.gameId, 'home')
                                Text { anchors.centerIn: parent; text: hDelegateWrapper.currentModel.home.charAt(0); color: Logic.getTeamTextColor(hDelegateWrapper.currentModel.home); font.pixelSize: 9; font.bold: true }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (hDelegateWrapper.isDateSep) {
                                var d = new Date(hDelegateWrapper.currentModel.start); var iso = d.getFullYear() + "-" + Logic.pad2(d.getMonth() + 1) + "-" + Logic.pad2(d.getDate())
                                if (controller && controller.nav && controller.day && controller.nav.dayView && controller.day.date === iso) { controller.nav.dayView = false; controller.expanded = false }
                                else if (controller) { controller.openDayView(iso) }
                            } else if (controller) {
                                controller.openDetail(hDelegateWrapper.currentModel.gameId, hDelegateWrapper.currentModel.away, hDelegateWrapper.currentModel.home, hDelegateWrapper.currentModel.ag, hDelegateWrapper.currentModel.hg, hDelegateWrapper.currentModel.statusRole, hDelegateWrapper.currentModel.periodType, hDelegateWrapper.currentModel.period, hDelegateWrapper.currentModel.liveRemain, hDelegateWrapper.currentModel.start, hDelegateWrapper.currentModel.inIntermission, hDelegateWrapper.currentModel.situationCode)
                            }
                        }
                    }
                }

                // Séparateur horizontal (Moins subtil : 0.2)
                Rectangle {
                    visible: index < (controller.todayGamesModel.count - 1) && !hDelegateWrapper.isDateSep
                    width: 1; height: parent.height * 0.5; anchors.verticalCenter: parent.verticalCenter
                    color: Kirigami.Theme.textColor; opacity: 0.2
                }

                Component {
                    id: stackLayoutComp
                    Row {
                        spacing: 3
                        anchors.verticalCenter: parent.verticalCenter
                        Column {
                            spacing: 0
                            Rectangle {
                                radius: 2; color: Logic.getTeamColor(hDelegateWrapper.currentModel.away, Kirigami.Theme.positiveBackgroundColor)
                                border.color: 'white'; border.width: 1
                                width: aLbl.implicitWidth + 5; height: aLbl.implicitHeight + 2
                                opacity: controller.blinkOpacity(hDelegateWrapper.currentModel.gameId, 'away')
                                Text { id: aLbl; anchors.centerIn: parent; text: hDelegateWrapper.currentModel.away; color: Logic.getTeamTextColor(hDelegateWrapper.currentModel.away); font.pixelSize: Math.max(8, hDelegateWrapper.csz * 0.68); font.bold: true; font.family: "monospace" }
                            }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: String(hDelegateWrapper.currentModel.ag); font.pixelSize: Math.max(10, hDelegateWrapper.csz * 0.95); font.bold: true; color: Kirigami.Theme.textColor; visible: hDelegateWrapper.currentModel.statusRole !== 'UPCOMING'; opacity: controller.blinkOpacity(hDelegateWrapper.currentModel.gameId, 'away') }
                        }
                        Loader {
                            sourceComponent: controller.statusBadgeComponent
                            property string gameStatus: hDelegateWrapper.currentModel.statusRole; property string rawState: hDelegateWrapper.currentModel.rawState; property string periodType: hDelegateWrapper.currentModel.periodType; property int period: hDelegateWrapper.currentModel.period; property string liveRemain: hDelegateWrapper.currentModel.liveRemain; property var startMs: hDelegateWrapper.currentModel.start; property string awayTeam: hDelegateWrapper.currentModel.away; property string homeTeam: hDelegateWrapper.currentModel.home; property bool intermission: hDelegateWrapper.currentModel.inIntermission; property string intermissionRemain: hDelegateWrapper.currentModel.intermissionRemain || ""; property string situationCode: hDelegateWrapper.currentModel.situationCode || "1551"; property string penaltyTime: hDelegateWrapper.currentModel.penaltyTime || ""
                        }
                        Column {
                            spacing: 0
                            Rectangle {
                                radius: 2; color: Logic.getTeamColor(hDelegateWrapper.currentModel.home, Kirigami.Theme.positiveBackgroundColor)
                                border.color: 'white'; border.width: 1
                                width: hLbl.implicitWidth + 5; height: hLbl.implicitHeight + 2
                                opacity: controller.blinkOpacity(hDelegateWrapper.currentModel.gameId, 'home')
                                Text { id: hLbl; anchors.centerIn: parent; text: hDelegateWrapper.currentModel.home; color: Logic.getTeamTextColor(hDelegateWrapper.currentModel.home); font.pixelSize: Math.max(8, hDelegateWrapper.csz * 0.68); font.bold: true; font.family: "monospace" }
                            }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: String(hDelegateWrapper.currentModel.hg); font.pixelSize: Math.max(10, hDelegateWrapper.csz * 0.95); font.bold: true; color: Kirigami.Theme.textColor; visible: hDelegateWrapper.currentModel.statusRole !== 'UPCOMING'; opacity: controller.blinkOpacity(hDelegateWrapper.currentModel.gameId, 'home') }
                        }
                    }
                }

                Component {
                    id: inlineLayoutComp
                    Loader {
                        sourceComponent: controller.teamRowInlineComponent
                        anchors.verticalCenter: parent.verticalCenter
                        property string awayCode: hDelegateWrapper.currentModel.away; property string homeCode: hDelegateWrapper.currentModel.home
                        property int agScore: hDelegateWrapper.currentModel.ag; property int hgScore: hDelegateWrapper.currentModel.hg
                        property int sz: compactRoot.sz; property string gameId: String(hDelegateWrapper.currentModel.gameId || '')
                        property string line1: controller.badgeLine1(hDelegateWrapper.currentModel.statusRole, hDelegateWrapper.currentModel.rawState, hDelegateWrapper.currentModel.periodType, hDelegateWrapper.currentModel.period, hDelegateWrapper.currentModel.liveRemain, hDelegateWrapper.currentModel.start, hDelegateWrapper.currentModel.home, hDelegateWrapper.currentModel.inIntermission)
                        property string line2: controller.badgeLine2(hDelegateWrapper.currentModel.statusRole, hDelegateWrapper.currentModel.start, hDelegateWrapper.currentModel.home, hDelegateWrapper.currentModel.periodType, hDelegateWrapper.currentModel.period, hDelegateWrapper.currentModel.liveRemain, hDelegateWrapper.currentModel.inIntermission, hDelegateWrapper.currentModel.intermissionRemain)
                        property color bgColor: controller.statusColor(hDelegateWrapper.currentModel.statusRole)
                        property string gameStatus: hDelegateWrapper.currentModel.statusRole
                        property Component statusComponent: controller.statusBadgeComponent
                        property string situationCode: hDelegateWrapper.currentModel.situationCode || "1551"
                        property string penaltyTime: hDelegateWrapper.currentModel.penaltyTime || ""
                        property string awayTeam: hDelegateWrapper.currentModel.away; property string homeTeam: hDelegateWrapper.currentModel.home
                    }
                }
            }
        }
    }

    // --- MODE VERTICAL ---
    Column {
        id: vCol; width: parent.width; anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter; 
        spacing: controller ? controller.spacingBetweenGames : 4
        visible: controller && controller.isVertical && controller.todayGamesModel && controller.todayGamesModel.count > 0
        Repeater {
            model: controller ? controller.todayGamesModel : null
            delegate: Column {
                id: vDelegateWrapper
                width: vCol.width
                spacing: 2
                readonly property bool isDateSep: model.statusRole === 'DATE_SEP'
                readonly property var currentModel: model

                Item {
                    width: parent.width; height: vDelegateWrapper.isDateSep ? 20 : 88; visible: vDelegateWrapper.currentModel.gameIndex < controller.maxGames
                    Column {
                        visible: vDelegateWrapper.isDateSep; anchors.fill: parent; spacing: 0
                        Rectangle { width: parent.width * 0.6; height: 1; anchors.horizontalCenter: parent.horizontalCenter; color: Kirigami.Theme.textColor; opacity: 0.15 }
                        Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: compactRoot.formatDate(vDelegateWrapper.currentModel.start); font.pixelSize: 9; font.bold: true; color: Kirigami.Theme.textColor; opacity: 0.4 }
                        Rectangle { width: parent.width * 0.6; height: 1; anchors.horizontalCenter: parent.horizontalCenter; color: Kirigami.Theme.textColor; opacity: 0.15 }
                    }
                    Column {
                        anchors.centerIn: parent; visible: !vDelegateWrapper.isDateSep; spacing: 3
                        Loader { sourceComponent: controller.teamColumnComponent; property string code: vDelegateWrapper.currentModel.away; property int score: vDelegateWrapper.currentModel.ag; property int sz: 14; property string gameId: String(vDelegateWrapper.currentModel.gameId || ''); property string teamSide: 'away'; property string gameStatus: vDelegateWrapper.currentModel.statusRole }
                        Loader {
                            sourceComponent: controller.statusBadgeComponent
                            property string gameStatus: vDelegateWrapper.currentModel.statusRole; property string rawState: vDelegateWrapper.currentModel.rawState; property string periodType: vDelegateWrapper.currentModel.periodType; property int period: vDelegateWrapper.currentModel.period; property string liveRemain: vDelegateWrapper.currentModel.liveRemain; property var startMs: vDelegateWrapper.currentModel.start; property string awayTeam: vDelegateWrapper.currentModel.away; property string homeTeam: vDelegateWrapper.currentModel.home; property bool intermission: vDelegateWrapper.currentModel.inIntermission; property string intermissionRemain: vDelegateWrapper.currentModel.intermissionRemain || ""; property string situationCode: vDelegateWrapper.currentModel.situationCode || "1551"; property string penaltyTime: vDelegateWrapper.currentModel.penaltyTime || ""
                        }
                        Loader { sourceComponent: controller.teamColumnComponent; property string code: vDelegateWrapper.currentModel.home; property int score: vDelegateWrapper.currentModel.hg; property int sz: 14; property string gameId: String(vDelegateWrapper.currentModel.gameId || ''); property string teamSide: 'home'; property string gameStatus: vDelegateWrapper.currentModel.statusRole }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (vDelegateWrapper.isDateSep) {
                                var d = new Date(vDelegateWrapper.currentModel.start); var iso = d.getFullYear() + "-" + Logic.pad2(d.getMonth() + 1) + "-" + Logic.pad2(d.getDate())
                                if (controller && controller.nav && controller.day && controller.nav.dayView && controller.day.date === iso) { controller.nav.dayView = false; controller.expanded = false }
                                else if (controller) { controller.openDayView(iso) }
                            } else if (controller) {
                                controller.openDetail(vDelegateWrapper.currentModel.gameId, vDelegateWrapper.currentModel.away, vDelegateWrapper.currentModel.home, vDelegateWrapper.currentModel.ag, vDelegateWrapper.currentModel.hg, vDelegateWrapper.currentModel.statusRole, vDelegateWrapper.currentModel.periodType, vDelegateWrapper.currentModel.period, vDelegateWrapper.currentModel.liveRemain, vDelegateWrapper.currentModel.start, vDelegateWrapper.currentModel.inIntermission, vDelegateWrapper.currentModel.situationCode)
                            }
                        }
                    }
                }
                // Séparateur vertical
                Rectangle {
                    visible: index < (controller.todayGamesModel.count - 1) && !vDelegateWrapper.isDateSep
                    width: parent.width * 0.8; height: 1; anchors.horizontalCenter: parent.horizontalCenter
                    color: Kirigami.Theme.textColor; opacity: 0.1
                }
            }
        }
    }
}
