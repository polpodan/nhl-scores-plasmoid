import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic
import "../components" as Components

Item {
    id: standingsRoot
    property var controller

    readonly property var s: (controller && controller.styles) ? controller.styles : { "fonts": { "main": 14, "small": 11, "header": 13, "tiny": 9 } }

    anchors.fill: parent
    visible: controller && controller.nav.standings && !controller.nav.schedule && !controller.nav.bracket

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Barre de navigation
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            // Ligne 1 : retour + titre
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 8; Layout.topMargin: 4; Layout.rightMargin: 8
                Button {
                    text: controller && controller.nav.teamHub ? i18n("‹ Team")
                          : controller && controller.nav.detail ? i18n("‹ Match")
                          : i18n("‹ Back")
                    icon.name: "go-previous"
                    flat: true
                    onClicked: {
                        if (controller) controller.nav.standings = false
                    }
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: i18n("Standings")
                    font.bold: true; font.pixelSize: s.fonts.header + 3
                }
                Item { Layout.fillWidth: true }
            }

            // Ligne 2 : boutons toggle Wild Card | Divisions | League
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 8; Layout.rightMargin: 8; Layout.bottomMargin: 2
                spacing: 4

                Button {
                    text: i18n("Wild Card")
                    flat: controller && controller.std.mode !== 'wildcard'
                    highlighted: controller && controller.std.mode === 'wildcard'
                    Layout.fillWidth: true
                    font.pixelSize: s.fonts.small
                    onClicked: {
                        if (controller) {
                            controller.std.mode = 'wildcard'
                            controller.buildStandingsModel()
                        }
                    }
                }
                Button {
                    text: i18n("Divisions")
                    flat: controller && controller.std.mode !== 'division'
                    highlighted: controller && controller.std.mode === 'division'
                    Layout.fillWidth: true
                    font.pixelSize: s.fonts.small
                    onClicked: {
                        if (controller) {
                            controller.std.mode = 'division'
                            controller.buildStandingsModel()
                        }
                    }
                }
                Button {
                    text: i18n("League")
                    flat: controller && controller.std.mode !== 'league'
                    highlighted: controller && controller.std.mode === 'league'
                    Layout.fillWidth: true
                    font.pixelSize: s.fonts.small
                    onClicked: {
                        if (controller) {
                            controller.std.mode = 'league'
                            controller.buildStandingsModel()
                        }
                    }
                }
            }
        }

        // Gestion de l'état (Chargement / Erreur)
        Components.StateLayer {
            loading: !!controller && controller.std.loading
            error: controller ? controller.std.error : ""
        }

        // Tableau
        ScrollView {
            id: standingsScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: controller && !controller.std.loading && controller.std.error === ""
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: (controller && controller.std.mode === 'league') ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            clip: true

            Item {
                width: standingsScroll.availableWidth
                height: standingsScroll.availableHeight

                ListView {
                    id: standingsListView
                    width: (controller && controller.std.mode === 'league')
                           ? Math.max(580, parent.width)
                           : Math.min(340, parent.width)
                    height: parent.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    model: controller ? controller.standingsFlatModelAlias : null
                    interactive: true
                    spacing: 0
                    delegate: Item {
                        property string rType:   model.type   || ""
                        property string rLabel:  model.label  || ""
                        property string rAbbrev: model.abbrev || ""
                        property string rCity:   model.city   || ""
                        property int    rGp:     model.gp     || 0
                        property int    rW:      model.w      || 0
                        property int    rL:      model.l      || 0
                        property int    rOt:     model.ot     || 0
                        property int    rPts:    model.pts    || 0
                        property int    rGf:     model.gf     || 0
                        property int    rGa:     model.ga     || 0
                        property int    rSow:    model.sow    || 0
                        property int    rSol:    model.sol    || 0
                        property int    rHw:     model.hw     || 0
                        property int    rHl:     model.hl     || 0
                        property int    rHot:    model.hot    || 0
                        property int    rRw:     model.rw     || 0
                        property int    rRl:     model.rl     || 0
                        property int    rRot:    model.rot    || 0
                        property int    rL10w:   model.l10w   || 0
                        property int    rL10l:   model.l10l   || 0
                        property int    rL10ot:  model.l10ot  || 0
                        property string rStreak: model.streak || ""
                        property string rClinch: model.clinch || ""

                        width: standingsListView.width
                        height: rType === "confHeader"   ? hdrLabel.implicitHeight + 8
                              : rType === "colHeader"    ? 18
                              : rType === "leagueHeader" ? 20
                              : rType === "leagueTeam"   ? leagueRow.implicitHeight + 4
                              : rType === "team"         ? teamRow.implicitHeight + 6
                              : rType === "wcSeparator"  ? 12
                              : hdrLabel.implicitHeight + 4

                        Rectangle {
                            anchors.fill: parent
                            visible: rType !== "wcSeparator"
                            color: {
                                if (rType === "confHeader") return Kirigami.Theme.alternateBackgroundColor
                                if (rType === "divHeader")  return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)
                                if (rType === "wcHeader")   return Qt.rgba(Kirigami.Theme.positiveBackgroundColor.r, Kirigami.Theme.positiveBackgroundColor.g, Kirigami.Theme.positiveBackgroundColor.b, 0.25)
                                if (rType === "leagueTeam" || rType === "team") {
                                    return (index % 2 === 0) ? "#000000" : "#1a1a1a"
                                }
                                return "transparent"
                            }
                            opacity: (rType === "leagueTeam" || rType === "team") ? 0.4 : 1.0
                        }
                        Rectangle {
                            visible: rType === "wcSeparator"
                            anchors.centerIn: parent
                            width: parent.width * 0.85; height: 1
                            color: Kirigami.Theme.textColor; opacity: 0.35
                        }
                        Label {
                            id: hdrLabel; anchors.centerIn: parent
                            visible: rType === "confHeader" || rType === "divHeader" || rType === "wcHeader"
                            text: rLabel; font.bold: true; font.pixelSize: rType === "confHeader" ? s.fonts.small + 1 : s.fonts.tiny + 1; opacity: rType === "confHeader" ? 1.0 : 0.85
                        }
                        RowLayout {
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 6; rightMargin: 6 }
                            visible: rType === "colHeader"
                            spacing: 0
                            Item { width: 38 + 12 } // Décalage pour l'indicateur
                            Label { text: i18n("Team"); font.pixelSize: s.fonts.small + 1; font.bold: true; opacity: 0.6; Layout.preferredWidth: 44 }
                            Label { Layout.fillWidth: true }
                            Label { text: "GP"; font.pixelSize: s.fonts.small + 1; font.bold: true; opacity: 0.6; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignHCenter }
                            Label { text: "W"; font.pixelSize: s.fonts.small + 1; font.bold: true; opacity: 0.6; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
                            Label { text: "L"; font.pixelSize: s.fonts.small + 1; font.bold: true; opacity: 0.6; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
                            Label { text: "OT"; font.pixelSize: s.fonts.small + 1; font.bold: true; opacity: 0.6; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
                            Label { text: "PTS"; font.pixelSize: s.fonts.small + 1; font.bold: true; opacity: 0.6; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                        }
                        RowLayout {
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 4; rightMargin: 4 }
                            visible: rType === "leagueHeader"
                            spacing: 0
                            
                            // Alignement avec l'abréviation et la ville
                            Item { width: 38 + 12 + 70 + 4 } 
                            Item { Layout.fillWidth: true } 

                            Repeater {
                                model: [
                                    {k:"gp", t:"GP", w:26}, {k:"w", t:"W", w:24}, {k:"l", t:"L", w:24},
                                    {k:"ot", t:"OT", w:24}, {k:"pts", t:"PTS", w:28}, {k:"gf", t:"GF", w:28},
                                    {k:"ga", t:"GA", w:28}
                                ]
                                delegate: Label {
                                    text: modelData.t + (controller.std.sortKey === modelData.k ? (controller.std.sortAsc ? " ↑" : " ↓") : "")
                                    font.pixelSize: s.fonts.tiny + 1; font.bold: true
                                    opacity: controller.std.sortKey === modelData.k ? 1.0 : 0.55
                                    color: controller.std.sortKey === modelData.k ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                    horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: modelData.w
                                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        acceptedButtons: Qt.LeftButton
                                        onTapped: {
                                            if (controller.std.sortKey === modelData.k)
                                                controller.std.sortAsc = !controller.std.sortAsc
                                            else { controller.std.sortKey = modelData.k; controller.std.sortAsc = false }
                                            controller.buildStandingsModel()
                                        }
                                    }
                                }
                            }
                            Label { text: "S/O";  font.pixelSize: s.fonts.tiny + 1; font.bold: true; opacity: 0.55; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                            Label { text: "HOME"; font.pixelSize: s.fonts.tiny + 1; font.bold: true; opacity: 0.55; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignHCenter; Layout.leftMargin: 6 }
                            Label { text: "AWAY"; font.pixelSize: s.fonts.tiny + 1; font.bold: true; opacity: 0.55; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignHCenter; Layout.leftMargin: 6 }
                            Label { text: "L10";  font.pixelSize: s.fonts.tiny + 1; font.bold: true; opacity: 0.55; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignHCenter; Layout.leftMargin: 6 }
                            Label { text: "STRK"; font.pixelSize: s.fonts.tiny + 1; font.bold: true; opacity: 0.55; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignHCenter }
                        }
                        RowLayout {
                            id: leagueRow; anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 4; rightMargin: 4 }
                            visible: rType === "leagueTeam"; spacing: 0
                            
                            Label {
                                text: {
                                    var c = String(rClinch).toLowerCase()
                                    if (c === "e") return "E"
                                    return c.toUpperCase()
                                }
                                visible: text !== ""
                                font.pixelSize: s.fonts.tiny; font.bold: true
                                color: text === "E" ? "#ff4444" : Kirigami.Theme.positiveTextColor
                                Layout.preferredWidth: 12
                            }
                            Item { visible: rClinch === ""; Layout.preferredWidth: 12 }

                            Item {
                                width: lgBadge.width; height: lgBadge.height; Layout.alignment: Qt.AlignVCenter
                                Rectangle {
                                    id: lgBadge
                                    visible: !controller.showLogos
                                    width: lgLbl.implicitWidth + 6; height: lgLbl.implicitHeight + 3; radius: 3
                                    color: Logic.getTeamColor(rAbbrev)
                                    Label { id: lgLbl; anchors.centerIn: parent; text: rAbbrev; color: Logic.getTeamTextColor(rAbbrev); font.pixelSize: s.fonts.tiny + 1; font.bold: true; font.family: "monospace" }
                                }
                                Image {
                                    visible: controller.showLogos
                                    anchors.fill: parent
                                    source: controller.showLogos ? controller.teamLogoUrl(rAbbrev) : ""
                                    sourceSize.width: 68; sourceSize.height: 36
                                    fillMode: Image.PreserveAspectFit; smooth: true
                                }
                            }
                            Label { text: rCity; font.pixelSize: s.fonts.small + 1; Layout.leftMargin: 4; elide: Text.ElideRight; Layout.preferredWidth: 70 }
                            Item { Layout.fillWidth: true }
                            Label { text: rGp; font.pixelSize: s.fonts.small + 1; Layout.preferredWidth: 26; horizontalAlignment: Text.AlignHCenter }
                            Label { text: rW; font.pixelSize: s.fonts.small + 1; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
                            Label { text: rL; font.pixelSize: s.fonts.small + 1; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
                            Label { text: rOt; font.pixelSize: s.fonts.small + 1; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
                            Label { text: rPts; font.pixelSize: s.fonts.small + 1; font.bold: true; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignHCenter; color: controller.std.sortKey === 'pts' ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor }
                            Label { text: rGf; font.pixelSize: s.fonts.small + 1; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignHCenter }
                            Label { text: rGa; font.pixelSize: s.fonts.small + 1; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignHCenter }
                            Label { text: rSow + "-" + rSol; font.pixelSize: s.fonts.small + 1; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                            Label { text: rHw + "-" + rHl + "-" + rHot; font.pixelSize: s.fonts.small + 1; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignHCenter; Layout.leftMargin: 6 }
                            Label { text: rRw + "-" + rRl + "-" + rRot; font.pixelSize: s.fonts.small + 1; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignHCenter; Layout.leftMargin: 6 }
                            Label { text: rL10w + "-" + rL10l + "-" + rL10ot; font.pixelSize: s.fonts.small + 1; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignHCenter; Layout.leftMargin: 6 }
                            Label { text: rStreak; font.pixelSize: s.fonts.small + 1; font.bold: true; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignHCenter; color: rStreak.startsWith("W") ? "#44cc44" : (rStreak.startsWith("L") ? "#cc4444" : Kirigami.Theme.textColor) }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: controller.openTeamHub(rAbbrev, 'standings') }
                        }
                        RowLayout {
                            id: teamRow; anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 6; rightMargin: 6 }
                            visible: rType === "team"; spacing: 0
                            
                            Label {
                                text: {
                                    var c = String(rClinch).toLowerCase()
                                    if (c === "e") return "E"
                                    return c.toUpperCase()
                                }
                                visible: text !== ""
                                font.pixelSize: s.fonts.tiny; font.bold: true
                                color: text === "E" ? "#ff4444" : Kirigami.Theme.positiveTextColor
                                Layout.preferredWidth: 12
                            }
                            Item { visible: rClinch === ""; Layout.preferredWidth: 12 }

                            Item {
                                width: 34; height: 18; Layout.alignment: Qt.AlignVCenter
                                Rectangle {
                                    id: abbrBadge
                                    visible: !controller.showLogos
                                    width: abbrLbl.implicitWidth + 8; height: abbrLbl.implicitHeight + 4; radius: 4; color: Logic.getTeamColor(rAbbrev)
                                    Label { id: abbrLbl; anchors.centerIn: parent; text: rAbbrev !== "" ? rAbbrev : "?"; color: Logic.getTeamTextColor(rAbbrev); font.pixelSize: s.fonts.small + 1; font.bold: true; font.family: "monospace" }
                                }
                                Image {
                                    visible: controller.showLogos
                                    anchors.fill: parent
                                    source: controller.showLogos ? controller.teamLogoUrl(rAbbrev) : ""
                                    sourceSize.width: 68; sourceSize.height: 36
                                    fillMode: Image.PreserveAspectFit; smooth: true
                                }
                            }
                            Label { Layout.leftMargin: 6; text: rCity; font.pixelSize: s.fonts.main; Layout.fillWidth: true; elide: Text.ElideRight }
                            Label { text: rGp; font.pixelSize: s.fonts.main; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignHCenter }
                            Label { text: rW; font.pixelSize: s.fonts.main; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
                            Label { text: rL; font.pixelSize: s.fonts.main; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
                            Label { text: rOt; font.pixelSize: s.fonts.main; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
                            Label { text: rPts; font.pixelSize: s.fonts.main; font.bold: true; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: controller.openTeamHub(rAbbrev, 'standings') }
                        }
                    }
                }
            }
        }

        // --- Légende FIXE et CENTRÉE au bas du Hub ---
        Rectangle {
            Layout.fillWidth: true
            height: legendCol.implicitHeight + 16
            color: "transparent"
            visible: controller && !controller.std.loading && controller.std.error === ""
            
            ColumnLayout {
                id: legendCol
                anchors.centerIn: parent
                spacing: 2
                Label {
                    text: "x - " + i18n("Place en séries assurée") + " | y - " + i18n("Titre de division assuré") + " | z - " + i18n("Titre d'association assuré")
                    font.pixelSize: 10; font.italic: true; opacity: 0.7
                    Layout.alignment: Qt.AlignHCenter
                }
                Label {
                    text: "E - " + i18n("Éliminé des séries")
                    font.pixelSize: 10; font.bold: true; font.italic: true; color: "#ff4444"; opacity: 0.8
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
        Item { height: 4 }
    }
}
