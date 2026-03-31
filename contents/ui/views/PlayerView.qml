import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic
import "../components" as Components

Item {
    id: playerRoot
    property var controller

    anchors.fill: parent
    visible: controller && controller.nav.player

    readonly property var p: controller ? controller.ply.data : null
    readonly property bool isG: p ? (p.positionCode === 'G' || p.position === 'G') : false
    
    // Calcul du Total NHL global
    readonly property var nhlTotal: {
        var t = { gp:0, g:0, a:0, pts:0, pm:0, pim:0, w:0, l:0, ga:0, sa:0, toi:0, nGaa:0 }
        if (p && p.seasonTotals) {
            p.seasonTotals.forEach(function(s) {
                if (s.gameTypeId === 2 && (s.leagueAbbrev === "NHL" || s.leagueName === "National Hockey League")) {
                    t.gp += (s.gamesPlayed || 0)
                    t.g += (s.goals || 0)
                    t.a += (s.assists || 0)
                    t.pts += (s.points || 0)
                    t.pm += (s.plusMinus || 0)
                    t.pim += (s.pim || 0)
                    t.w += (s.wins || 0)
                    t.l += (s.losses || 0)
                    t.ga += (s.goalsAgainst || 0)
                    t.sa += (s.shotsAgainst || 0)
                    
                    if (isG && s.timeOnIce) {
                        var parts = s.timeOnIce.split(':')
                        var sec = parseInt(parts[0])*60 + (parts[1] ? parseInt(parts[1]) : 0)
                        t.toi += sec
                    } else if (isG && (s.goalsAgainstAvg !== undefined || s.goalsAgainstAverage !== undefined)) {
                        var avg = s.goalsAgainstAvg !== undefined ? s.goalsAgainstAvg : s.goalsAgainstAverage
                        t.ga += (avg * (s.gamesPlayed || 1))
                        t.nGaa += (s.gamesPlayed || 1)
                    }
                }
            })
        }
        return t
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Navigation
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8; Layout.topMargin: 4; Layout.bottomMargin: 4
            Button {
                text: {
                    if (!controller) return ""
                    if (controller.ply.from === 'teamstats') return i18n("‹ Stats")
                    if (controller.ply.from === 'search') return i18n("‹ Search")
                    if (controller.ply.from === 'detail') return i18n("‹ Match")
                    return i18n("‹ Leaders")
                }
                icon.name: "go-previous"; flat: true
                onClicked: {
                    if (controller) {
                        var from = controller.ply.from
                        controller.nav.player = false
                        if (from === 'leaders')   controller.nav.leaders = true
                        else if (from === 'search')    controller.nav.search = true
                        else if (from === 'teamstats') controller.nav.schedule = true
                        else if (from === 'detail')    controller.nav.detail = true
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }

        Components.StateLayer {
            loading: !!controller && controller.ply.loading
            error: controller ? controller.ply.error : ""
        }

        ScrollView {
            id: playerScrollView
            Layout.fillWidth: true; Layout.fillHeight: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            visible: !!(p && !controller.ply.loading)

            ColumnLayout {
                width: Math.min(440, playerScrollView.availableWidth)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 15

                // ── Photo + Nom ──
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 200
                    Image {
                        id: playerPhoto
                        source: p ? (p.headshot || '') : ''
                        anchors.horizontalCenter: parent.horizontalCenter
                        fillMode: Image.PreserveAspectFit
                        width: parent.width; height: 200; smooth: true
                    }
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 70
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.85) }
                        }
                        Label {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 15 }
                            text: p ? ((p.firstName.default || p.firstName || '') + ' ' + (p.lastName.default || p.lastName || '')) : ''
                            font.pixelSize: 22; font.bold: true; color: "white"; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // ── Infos de base (Centrées) ──
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                        text: p ? (p.currentTeamAbbrev || '') + '  #' + (p.sweaterNumber || '?') + '  ·  ' + (p.position || '') + '  ·  ' + (p.heightInCentimeters || '?') + ' cm  ·  ' + (p.weightInKilograms || '?') + ' kg' : ''
                        font.pixelSize: 13; color: Kirigami.Theme.textColor; opacity: 0.8
                    }
                    Label {
                        Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                        text: p ? (p.birthDate + (p.birthCity ? "  ·  " + (p.birthCity.default || p.birthCity) : "") + (p.birthStateProvince ? ", " + (p.birthStateProvince.default || p.birthStateProvince) : "") + (p.birthCountry ? " (" + p.birthCountry + ")" : "")) : ""
                        font.pixelSize: 11; color: Kirigami.Theme.disabledTextColor; opacity: 0.6
                    }
                }

                // ── Historique de Carrière ──
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    
                    Label { 
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: i18n("Career Stats")
                        font.pixelSize: 12; font.bold: true; opacity: 0.5 
                    }
                    
                    // En-tête du tableau
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 0
                        Label { text: i18n("Season"); font.pixelSize: 10; font.bold: true; opacity: 0.5; Layout.preferredWidth: 52 }
                        Label { text: i18n("Team"); font.pixelSize: 10; font.bold: true; opacity: 0.5; Layout.preferredWidth: 60; horizontalAlignment: Text.AlignHCenter }
                        Label { text: "Lge"; font.pixelSize: 10; font.bold: true; opacity: 0.5; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignHCenter }
                        Label { text: "PJ"; font.pixelSize: 10; font.bold: true; opacity: 0.5; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                        Label { text: isG ? "V" : "B"; font.pixelSize: 10; font.bold: true; opacity: 0.5; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignHCenter }
                        Label { text: isG ? "D" : "A"; font.pixelSize: 10; font.bold: true; opacity: 0.5; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignHCenter }
                        Label { text: isG ? "MOY" : "P"; font.pixelSize: 10; font.bold: true; opacity: 0.5; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignHCenter }
                        Label { text: isG ? "%ARR" : "+/-"; font.pixelSize: 10; font.bold: true; opacity: 0.5; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignHCenter }
                        Label { text: isG ? "MIN" : "PIM"; font.pixelSize: 10; font.bold: true; opacity: 0.5; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignHCenter }
                    }

                    // Liste des saisons
                    Repeater {
                        model: {
                            if (!p || !p.seasonTotals) return []
                            return p.seasonTotals.filter(function(s){ return s.gameTypeId === 2 }).sort(function(a,b){ return b.season - a.season })
                        }
                        delegate: RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            implicitHeight: 24
                            spacing: 0
                            
                            Label {
                                text: { var s = String(modelData.season); return s.substring(0,4) + "-" + s.substring(6) }
                                font.pixelSize: 11; Layout.preferredWidth: 52
                            }
                            
                            Item {
                                Layout.preferredWidth: 60; height: 18
                                property string abbrev: (modelData.leagueAbbrev === "NHL" || modelData.leagueName === "National Hockey League")
                                    ? Logic.resolveNHLAbbrev(modelData.teamCommonName ? (modelData.teamCommonName.default || modelData.teamCommonName) : "") : ""
                                
                                Rectangle {
                                    visible: parent.abbrev !== ""
                                    anchors.centerIn: parent
                                    radius: 2; color: Logic.getTeamColor(parent.abbrev); width: 34; height: 14
                                    Label { 
                                        anchors.centerIn: parent; text: parent.parent.abbrev
                                        color: Logic.getTeamTextColor(parent.parent.abbrev)
                                        font.bold: true; font.pixelSize: 9; font.family: "monospace" 
                                    }
                                }
                                Label {
                                    visible: parent.abbrev === ""
                                    anchors.fill: parent
                                    text: modelData.teamName ? (modelData.teamName.default || modelData.teamName) : ""
                                    font.pixelSize: 11; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Label { 
                                text: modelData.leagueAbbrev || ""; font.pixelSize: 10; opacity: 0.6
                                Layout.preferredWidth: 36; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight 
                            }
                            
                            Label { text: modelData.gamesPlayed || 0; font.pixelSize: 11; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                            Label { text: isG ? (modelData.wins || 0) : (modelData.goals || 0); font.pixelSize: 11; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignHCenter }
                            Label { text: isG ? (modelData.losses || 0) : (modelData.assists || 0); font.pixelSize: 11; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignHCenter }
                            Label { 
                                text: {
                                    if (isG) {
                                        var gaa = modelData.goalsAgainstAvg !== undefined ? modelData.goalsAgainstAvg : (modelData.goalsAgainstAverage !== undefined ? modelData.goalsAgainstAverage : modelData.gaa)
                                        return gaa !== undefined ? Number(gaa).toFixed(3) : '—'
                                    }
                                    return (modelData.points || 0)
                                }
                                font.pixelSize: 11; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignHCenter 
                            }
                            Label { 
                                text: {
                                    if (isG) {
                                        var svp = modelData.savePctg !== undefined ? modelData.savePctg : (modelData.savePercentage !== undefined ? modelData.savePercentage : modelData.svp)
                                        return svp !== undefined ? Number(svp).toFixed(3) : '—'
                                    }
                                    return (modelData.plusMinus !== undefined ? (modelData.plusMinus > 0 ? "+" + modelData.plusMinus : modelData.plusMinus) : "0")
                                }
                                font.pixelSize: 11; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignHCenter
                                color: !isG ? (modelData.plusMinus > 0 ? "#44cc44" : (modelData.plusMinus < 0 ? "#cc4444" : Kirigami.Theme.textColor)) : Kirigami.Theme.textColor
                            }
                            Label { text: isG ? (modelData.pim || 0) : (modelData.pim || 0); font.pixelSize: 11; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignHCenter }
                        }
                    }

                    // Ligne Total NHL
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        implicitHeight: 30
                        spacing: 0
                        
                        Label { text: "NHL TOTAL"; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; Layout.preferredWidth: 52 }
                        Item { Layout.preferredWidth: 60 }
                        Item { Layout.preferredWidth: 36 }
                        
                        Label { text: playerRoot.nhlTotal.gp; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                        Label { text: isG ? playerRoot.nhlTotal.w : playerRoot.nhlTotal.g; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignHCenter }
                        Label { text: isG ? playerRoot.nhlTotal.l : playerRoot.nhlTotal.a; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignHCenter }
                        Label { 
                            text: {
                                if (!isG) return playerRoot.nhlTotal.pts
                                if (playerRoot.nhlTotal.toi > 0) return (playerRoot.nhlTotal.ga / (playerRoot.nhlTotal.toi / 3600)).toFixed(3)
                                if (playerRoot.nhlTotal.nGaa > 0) return (playerRoot.nhlTotal.ga / playerRoot.nhlTotal.nGaa).toFixed(3)
                                return "—"
                            }
                            font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignHCenter 
                        }
                        Label { 
                            text: isG ? (playerRoot.nhlTotal.sa > 0 ? (Number((playerRoot.nhlTotal.sa - playerRoot.nhlTotal.ga)/playerRoot.nhlTotal.sa)).toFixed(3) : "—") : (playerRoot.nhlTotal.pm > 0 ? "+" + playerRoot.nhlTotal.pm : playerRoot.nhlTotal.pm)
                            font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignHCenter
                        }
                        Label { text: playerRoot.nhlTotal.pim; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignHCenter }
                    }
                }

                // ── Derniers Matchs ──
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 5
                    Label { Layout.alignment: Qt.AlignHCenter; text: i18n("Last 5 games"); font.pixelSize: 12; font.bold: true; opacity: 0.5 }
                    Repeater {
                        model: p ? p.last5Games : []
                        delegate: Rectangle {
                            Layout.fillWidth: true; implicitHeight: 30; radius: 4; color: index % 2 === 0 ? "transparent" : Qt.rgba(1,1,1,0.04)
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                Label { text: modelData.gameDate; font.pixelSize: 11; opacity: 0.6; Layout.preferredWidth: 75 }
                                Rectangle {
                                    radius: 3; color: Logic.getTeamColor(modelData.opponentAbbrev)
                                    width: 36; height: 20
                                    Label { anchors.centerIn: parent; text: modelData.opponentAbbrev; color: Logic.getTeamTextColor(modelData.opponentAbbrev); font.bold: true; font.pixelSize: 10 }
                                }
                                Item { Layout.fillWidth: true }
                                Label { 
                                    text: isG ? (modelData.decision || '-') : (modelData.goals + "B " + modelData.assists + "A " + modelData.points + "PTS")
                                    font.pixelSize: 12; font.bold: true 
                                }
                            }
                        }
                    }
                }
                Item { Layout.preferredHeight: 20 }
            }
        }
    }
}
