import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic
import "../components" as Components

Item {
    id: leadersRoot
    property var controller

    readonly property var s: (controller && controller.styles) ? controller.styles : { "fonts": { "main": 14, "small": 11, "header": 13, "tiny": 9 }, "badge": { "radius": 4 } }

    anchors.fill: parent
    visible: controller && controller.nav.leaders && !controller.nav.player

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8; Layout.topMargin: 4; Layout.bottomMargin: 2
            Button {
                text: i18n("‹ Match")
                icon.name: "go-previous"; flat: true
                onClicked: { if (controller) controller.nav.leaders = false }
            }
            Item { Layout.fillWidth: true }
            Label {
                text: i18n("Leaders")
                font.bold: true; font.pixelSize: s.fonts.header + 3
                Layout.alignment: Qt.AlignHCenter
            }
            Item { Layout.fillWidth: true }
        }

        // ── Filtres position ─────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 4
            spacing: 6

            Repeater {
                model: [
                    { lbl: i18n("Fwd"),     prop: 'F' },
                    { lbl: i18n("Def"),     prop: 'D' },
                    { lbl: i18n("Goal"),    prop: 'G' }
                ]
                delegate: Rectangle {
                    radius: s.badge.radius
                    implicitWidth: fLbl.implicitWidth + 12
                    implicitHeight: fLbl.implicitHeight + 6
                    readonly property bool active: {
                        if (!controller) return false
                        if (modelData.prop === 'F') return controller.lead.filterF
                        if (modelData.prop === 'D') return controller.lead.filterD
                        if (modelData.prop === 'G') return controller.lead.filterG
                        return false
                    }
                    color: active ? Kirigami.Theme.highlightColor : Qt.rgba(1,1,1,0.07)
                    border.color: active ? Kirigami.Theme.highlightColor : Qt.rgba(1,1,1,0.15)
                    border.width: 1
                    Label {
                        id: fLbl; anchors.centerIn: parent
                        text: modelData.lbl
                        font.pixelSize: s.fonts.small; font.bold: parent.active
                        color: parent.active ? "white" : Kirigami.Theme.textColor
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            if (!controller) return
                            var newF = controller.lead.filterF
                            var newD = controller.lead.filterD
                            var newG = controller.lead.filterG
                            var newR = controller.lead.filterR
                            if (modelData.prop === 'F') {
                                newF = !newF; newD = false; newG = false
                            } else if (modelData.prop === 'D') {
                                newD = !newD; newF = false; newG = false
                            } else if (modelData.prop === 'G') {
                                newG = !newG; newF = false; newD = false
                            }
                            controller.lead.filterF = newF
                            controller.lead.filterD = newD
                            controller.lead.filterG = newG
                            controller.lead.filterR = newR
                            controller.fetchLeadersFiltered(newF, newD, newG, newR)
                        }
                    }
                }
            }
        }

        // ── Filtres Saison et Type ───────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 8
            spacing: 10

            // Choix de la saison
            ComboBox {
                id: seasonCombo
                implicitWidth: 100
                font.pixelSize: s.fonts.small
                model: {
                    var list = []
                    var now = new Date()
                    var endYear = now.getFullYear()
                    // La saison N-N+1 commence généralement en octobre. 
                    // Si on est avant septembre (8), la saison "courante" a démarré l'année d'avant.
                    if (now.getMonth() < 8) endYear-- 
                    
                    for (var y = endYear; y >= 1917; y--) {
                        var sStart = y
                        var sEnd = y + 1
                        list.push({
                            label: sStart + "-" + String(sEnd).substring(2),
                            value: sStart + String(sEnd)
                        })
                    }
                    return list
                }
                textRole: "label"
                currentIndex: {
                    if (!controller) return 0
                    for (var i=0; i<model.length; i++) {
                        if (model[i].value === controller.lead.season) return i
                    }
                    return 0
                }
                onActivated: (index) => {
                    if (controller) {
                        controller.lead.season = model[index].value
                        controller.fetchLeaders()
                    }
                }
            }

            // Type de saison (Régulière / Séries)
            Row {
                spacing: 2
                Repeater {
                    model: [
                        { lbl: i18n("Reg"), val: 2 },
                        { lbl: i18n("Post"), val: 3 }
                    ]
                    delegate: Rectangle {
                        radius: s.badge.radius
                        implicitWidth: typeLbl.implicitWidth + 12
                        implicitHeight: seasonCombo.height
                        readonly property bool active: controller && controller.lead.seasonType === modelData.val
                        color: active ? Kirigami.Theme.highlightColor : Qt.rgba(1,1,1,0.07)
                        border.color: active ? Kirigami.Theme.highlightColor : Qt.rgba(1,1,1,0.15)
                        border.width: 1
                        Label {
                            id: typeLbl; anchors.centerIn: parent
                            text: modelData.lbl
                            font.pixelSize: s.fonts.small; font.bold: parent.active
                            color: parent.active ? "white" : Kirigami.Theme.textColor
                        }
                        TapHandler {
                            onTapped: {
                                if (controller) {
                                    controller.lead.seasonType = modelData.val
                                    controller.fetchLeaders()
                                }
                            }
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
        }

        Components.StateLayer {
            loading: !!controller && controller.lead.loading
            error: controller ? controller.lead.error : ""
        }

        ScrollView {
            id: leadersScrollView
            Layout.fillWidth: true; Layout.fillHeight: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            visible: controller && !controller.lead.loading && controller.lead.error === ''

            ColumnLayout {
                width: Math.min(360, leadersScrollView.availableWidth)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2

                Component {
                    id: leaderRowComp
                    Button {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        flat: true
                        
                        onClicked: {
                            if (controller && modelData.id) {
                                controller.openPlayer(modelData.id, 'leaders')
                            }
                        }

                        background: Rectangle {
                            color: parent.pressed ? Qt.rgba(1,1,1,0.12) : (parent.hovered ? Qt.rgba(1,1,1,0.06) : "transparent")
                            radius: 4
                        }

                        contentItem: RowLayout {
                            spacing: 8
                            Label { 
                                text: (index + 1) + "."
                                font.pixelSize: s.fonts.small
                                opacity: 0.4; Layout.preferredWidth: 20 
                            }
                            Item {
                                width: ldrBadge.width; height: ldrBadge.height; Layout.alignment: Qt.AlignVCenter
                                Rectangle {
                                    id: ldrBadge
                                    visible: !controller.showLogos
                                    radius: 2
                                    color: Logic.getTeamColorAdapted(modelData.team || '', "", false, false, Kirigami.Theme.backgroundColor)
                                    width: 38; height: 18
                                    Label { 
                                        anchors.centerIn: parent; text: modelData.team || ''
                                        color: Logic.getContrastColor(ldrBadge.color)
                                        font.pixelSize: s.fonts.tiny + 1; font.bold: true; font.family: "monospace" 
                                    }
                                }
                                Image {
                                    visible: controller.showLogos
                                    anchors.fill: parent
                                    source: controller.showLogos ? controller.teamLogoUrl(modelData.team) : ""
                                    sourceSize.width: width * 2
                                    sourceSize.height: height * 2
                                    fillMode: Image.PreserveAspectFit; smooth: true
                                }
                            }
                            Label { 
                                text: modelData.name || ''
                                font.pixelSize: s.fonts.main - 1; font.bold: true
                                color: Kirigami.Theme.textColor; Layout.fillWidth: true; elide: Text.ElideRight 
                            }
                            Label { 
                                text: {
                                    var val = modelData.value || 0
                                    if (modelData.cat === 'gaa' || modelData.cat === 'savePctg') return Number(val).toFixed(3)
                                    return String(val)
                                }
                                font.pixelSize: s.fonts.main - 1; font.bold: true
                                color: index === 0 ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                Layout.preferredWidth: 45; horizontalAlignment: Text.AlignRight 
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0; visible: controller && controller.lead.points.length > 0
                    Label { Layout.leftMargin: 12; Layout.topMargin: 6; Layout.bottomMargin: 4; text: "🏒 " + i18n("Points"); font.pixelSize: s.fonts.header; font.bold: true; color: Kirigami.Theme.textColor }
                    Repeater { model: controller ? controller.lead.points : []; delegate: leaderRowComp }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0; visible: controller && controller.lead.goals.length > 0
                    Label { Layout.leftMargin: 12; Layout.topMargin: 6; Layout.bottomMargin: 4; text: "🎯 " + i18n("Goals"); font.pixelSize: s.fonts.header; font.bold: true; color: Kirigami.Theme.textColor }
                    Repeater { model: controller ? controller.lead.goals : []; delegate: leaderRowComp }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0; visible: controller && controller.lead.assists.length > 0
                    Label { Layout.leftMargin: 12; Layout.topMargin: 6; Layout.bottomMargin: 4; text: "🍎 " + i18n("Assists"); font.pixelSize: s.fonts.header; font.bold: true; color: Kirigami.Theme.textColor }
                    Repeater { model: controller ? controller.lead.assists : []; delegate: leaderRowComp }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0; visible: controller && controller.lead.pim.length > 0
                    Label { Layout.leftMargin: 12; Layout.topMargin: 6; Layout.bottomMargin: 4; text: "👊 " + i18n("PIM"); font.pixelSize: s.fonts.header; font.bold: true; color: Kirigami.Theme.textColor }
                    Repeater { model: controller ? controller.lead.pim : []; delegate: leaderRowComp }
                }

                Rectangle { Layout.fillWidth: true; Layout.leftMargin: 8; Layout.rightMargin: 8; Layout.topMargin: 12; height: 1; color: Kirigami.Theme.textColor; opacity: 0.15; visible: controller && controller.lead.wins.length > 0 }
                Label { Layout.leftMargin: 12; Layout.topMargin: 6; text: i18n("Goalies"); font.pixelSize: s.fonts.small + 1; font.bold: true; color: Kirigami.Theme.disabledTextColor; visible: controller && controller.lead.wins.length > 0 }
                
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0; visible: controller && controller.lead.wins.length > 0
                    Label { Layout.leftMargin: 12; Layout.topMargin: 6; Layout.bottomMargin: 4; text: "🏆 " + i18n("Wins"); font.pixelSize: s.fonts.header; font.bold: true; color: Kirigami.Theme.textColor }
                    Repeater { model: controller ? controller.lead.wins : []; delegate: leaderRowComp }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0; visible: controller && controller.lead.sho.length > 0
                    Label { Layout.leftMargin: 12; Layout.topMargin: 6; Layout.bottomMargin: 4; text: "🥅 " + i18n("Shutouts"); font.pixelSize: s.fonts.header; font.bold: true; color: Kirigami.Theme.textColor }
                    Repeater { model: controller ? controller.lead.sho : []; delegate: leaderRowComp }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0; visible: controller && controller.lead.gaa.length > 0
                    Label { Layout.leftMargin: 12; Layout.topMargin: 6; Layout.bottomMargin: 4; text: "📉 " + i18n("GAA"); font.pixelSize: s.fonts.header; font.bold: true; color: Kirigami.Theme.textColor }
                    Repeater { model: controller ? controller.lead.gaa : []; delegate: leaderRowComp }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0; visible: controller && controller.lead.svp.length > 0
                    Label { Layout.leftMargin: 12; Layout.topMargin: 6; Layout.bottomMargin: 4; text: "🛡️ " + i18n("SV%"); font.pixelSize: s.fonts.header; font.bold: true; color: Kirigami.Theme.textColor }
                    Repeater { model: controller ? controller.lead.svp : []; delegate: leaderRowComp }
                }

                Item { implicitHeight: 12 }
            }
        }
    }
}
