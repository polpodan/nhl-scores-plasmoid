import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic
import "../components" as Components

Item {
    id: playerRoot
    property var controller
    property string playerId: controller ? String(controller.ply.playerId) : ""
    property string from: controller ? controller.ply.from : "leaders"
    
    anchors.fill: parent
    visible: !!(controller && controller.nav.player)

    property int activeTab: 0 // 0: Season, 1: Playoffs
    readonly property var p: controller ? controller.ply.data : null
    readonly property bool isG: p ? p.position === 'G' : false

    readonly property var currentTotals: {
        if (!p || !p.seasonTotals) return []
        var type = (activeTab === 0) ? 2 : 3
        return p.seasonTotals.filter(function(s) { return s.gameTypeId === type })
    }

    readonly property var featured: {
        if (!p || !p.featuredStats) return null
        if (activeTab === 0) return p.featuredStats.regularSeason ? p.featuredStats.regularSeason.subSeason : null
        return p.featuredStats.playoffs ? p.featuredStats.playoffs.subSeason : null
    }

    readonly property var nhlTotal: {
        if (!p || !p.careerTotals) return { gp: 0, g: 0, a: 0, pts: 0, pm: 0, w: 0, l: 0, gaa: "—", sv: "—", sa: 0, ga: 0, sho: 0 }
        var src = (activeTab === 0) ? p.careerTotals.regularSeason : p.careerTotals.playoffs
        if (!src) return { gp: 0, g: 0, a: 0, pts: 0, pm: 0, w: 0, l: 0, gaa: "—", sv: "—", sa: 0, ga: 0, sho: 0 }
        
        return {
            gp: src.gamesPlayed || 0,
            g:  src.goals || 0,
            a:  src.assists || 0,
            pts: src.points || 0,
            pm: src.plusMinus || 0,
            w:  src.wins || 0,
            l:  src.losses || 0,
            gaa: (src.goalsAgainstAvg !== undefined) ? Number(src.goalsAgainstAvg).toFixed(2) : "—",
            sv:  (src.savePctg !== undefined) ? Number(src.savePctg).toFixed(3) : "—",
            sa:  src.shotsAgainst || 0,
            ga:  src.goalsAgainst || 0,
            sho: src.shutouts || 0
        }
    }

    function calculateAge(birthStr, deathStr) {
        if (!birthStr) return "?"
        var birth = new Date(birthStr)
        var end = (deathStr && deathStr !== "" && deathStr !== "undefined") ? new Date(deathStr) : new Date()
        var age = end.getFullYear() - birth.getFullYear()
        var m = end.getMonth() - birth.getMonth()
        if (m < 0 || (m === 0 && end.getDate() < birth.getDate())) age--
        return age
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            implicitHeight: 40
            RowLayout {
                anchors.fill: parent
                spacing: 0
                Button {
                    text: {
                        if (from === 'search') return i18n("‹ Search")
                        if (from === 'teamstats') return i18n("‹ Stats")
                        if (from === 'detail') return i18n("‹ Match")
                        if (from === 'franchiseLeaders') return i18n("‹ History")
                        return i18n("‹ Leaders")
                    }
                    icon.name: "go-previous"
                    flat: true
                    onClicked: {
                        if (controller) {
                            controller.nav.player = false
                            if (from === 'leaders') controller.openLeaders()
                            else if (from === 'search') controller.openSearch()
                            else if (from === 'teamstats') controller.openSchedule(controller.sch.team, true)
                            else if (from === 'detail') controller.nav.detail = true
                            else if (from === 'franchiseLeaders') controller.nav.franchiseLeaders = true
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                Row {
                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: 12
                    spacing: 4
                    Button {
                        text: i18n("Season")
                        flat: true
                        font.bold: activeTab === 0
                        opacity: activeTab === 0 ? 1.0 : 0.5
                        onClicked: activeTab = 0
                    }
                    Rectangle { width: 1; height: 16; color: Kirigami.Theme.textColor; opacity: 0.2; anchors.verticalCenter: parent.verticalCenter }
                    Button {
                        text: i18n("Playoffs")
                        flat: true
                        font.bold: activeTab === 1
                        opacity: activeTab === 1 ? 1.0 : 0.5
                        onClicked: activeTab = 1
                    }
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
                width: parent.width
                spacing: 20
                bottomPadding: 20

                // 1. En-tête (Photo + Nom)
                Column {
                    width: parent.width
                    spacing: 10
                    topPadding: 10
                    
                    Image {
                        source: p ? p.headshot : ""
                        width: 120; height: 120
                        fillMode: Image.PreserveAspectFit
                        anchors.horizontalCenter: parent.horizontalCenter
                        Rectangle {
                            anchors.fill: parent; z: -1; color: Qt.rgba(1,1,1,0.05); radius: 60
                        }
                    }
                    
                    Column {
                        width: parent.width
                        spacing: 2
                        Label { 
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: p ? (p.firstName.default + " " + p.lastName.default) : ""
                            font.bold: true; font.pixelSize: 22
                            color: Kirigami.Theme.textColor 
                        }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10
                            Rectangle {
                                visible: !!(p && p.sweaterNumber)
                                width: 22; height: 22; radius: 11
                                color: controller ? controller.statusColor('LIVE') : "red"
                                anchors.verticalCenter: parent.verticalCenter
                                Label { 
                                    anchors.centerIn: parent
                                    text: p ? p.sweaterNumber : ""
                                    color: Logic.getContrastColor(parent.color)
                                    font.bold: true; font.family: "monospace"; font.pixelSize: 13
                                }
                            }
                            Label { 
                                text: {
                                    if (!p) return ""
                                    var pos = (p.positionCode || p.position || "?")
                                    var age = calculateAge(p.birthDate, p.deathDate)
                                    var isLikelyDeceased = (p.deathDate && p.deathDate !== "undefined") || (age > 95 && !p.isActive)
                                    var ageStr = age + " " + i18n("years")
                                    if (isLikelyDeceased) return "·  " + pos + "  ·  " + i18n("Deceased") + " (" + age + " " + i18n("years") + ")"
                                    return "·  " + pos + "  ·  " + ageStr
                                }
                                font.bold: true; font.pixelSize: 15
                                color: Kirigami.Theme.textColor 
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: p ? (i18n("Height:") + " " + (p.heightInCentimeters || "?") + " cm  /  " + i18n("Weight:") + " " + (p.weightInKilograms || "?") + " kg") : ""
                        font.pixelSize: 12; opacity: 0.8; color: Kirigami.Theme.textColor 
                    }
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        visible: !!(p && p.birthDate)
                        text: i18n("Born:") + " " + (visible ? String(p.birthDate).substring(0, 10) : "")
                        font.pixelSize: 11; opacity: 0.6; color: Kirigami.Theme.textColor
                    }
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        visible: !!(p && p.deathDate && p.deathDate !== "undefined")
                        text: i18n("Died:") + " " + (visible ? String(p.deathDate).substring(0, 10) : "")
                        font.pixelSize: 11; opacity: 0.6; color: Kirigami.Theme.textColor
                    }
                    Label {
                        width: Math.min(360, parent.width - 40)
                        anchors.horizontalCenter: parent.horizontalCenter
                        horizontalAlignment: Text.AlignHCenter
                        visible: !!(p && (p.birthCity || p.birthCountry))
                        text: {
                            if (!p) return ""
                            var city = (p.birthCity && p.birthCity.default) ? p.birthCity.default : ""
                            var state = (p.birthStateProvince && p.birthStateProvince.default) ? p.birthStateProvince.default : ""
                            var country = (p.birthCountry && p.birthCountry.default) ? p.birthCountry.default : ""
                            return i18n("Birthplace:") + " " + city + (state !== "" ? ", " + state : "") + (country !== "" ? ", " + country : "")
                        }
                        font.pixelSize: 11; opacity: 0.6; color: Kirigami.Theme.textColor; wrapMode: Text.WordWrap
                    }
                }

                // 2. Stats Globales NHL
                Column {
                    width: parent.width
                    spacing: 5
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "NHL TOTAL (" + (activeTab === 0 ? i18n("Season") : i18n("Playoffs")) + ")"
                        font.pixelSize: 10; font.bold: true; opacity: 0.4; color: Kirigami.Theme.textColor
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 15
                        Repeater {
                            model: isG ? [
                                { l: i18n("PJ"), v: nhlTotal.gp }, { l: i18n("W"), v: nhlTotal.w },
                                { l: "GAA", v: nhlTotal.gaa }, { l: "SV%", v: nhlTotal.sv }, { l: "SHO", v: nhlTotal.sho }
                            ] : [
                                { l: i18n("PJ"), v: nhlTotal.gp }, { l: i18n("Goals"), v: nhlTotal.g },
                                { l: i18n("Assists"), v: nhlTotal.a }, { l: "PTS", v: nhlTotal.pts }, { l: "+/-", v: (nhlTotal.pm > 0 ? "+" : "") + nhlTotal.pm }
                            ]
                            delegate: Column {
                                spacing: 2
                                Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.l; font.pixelSize: 10; opacity: 0.6; color: Kirigami.Theme.textColor }
                                Label { anchors.horizontalCenter: parent.horizontalCenter; text: String(modelData.v); font.bold: true; font.pixelSize: 15; color: Kirigami.Theme.textColor }
                            }
                        }
                    }
                }

                // 3. Stats Saison Actuelle / Dernier match
                Column {
                    id: statsBlock
                    width: 320
                    spacing: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !!featured
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: activeTab === 0 ? i18n("Current season") : i18n("Current playoffs")
                        font.pixelSize: 11; font.bold: true; opacity: 0.5; color: Kirigami.Theme.textColor
                    }
                    Rectangle {
                        width: parent.width; height: 60; radius: 6
                        color: Qt.rgba(1,1,1,0.05)
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 10
                            Repeater {
                                model: isG ? [
                                    { l: i18n("PJ"), v: featured ? (featured.gamesPlayed || 0) : "–" },
                                    { l: i18n("W"), v: featured ? (featured.wins || 0) : "–" },
                                    { l: i18n("GAA"), v: (featured && (featured.goalsAgainstAverage !== undefined || featured.goalsAgainstAvg !== undefined)) ? Number(featured.goalsAgainstAverage || featured.goalsAgainstAvg).toFixed(2) : "–" },
                                    { l: i18n("SV%"), v: (featured && featured.savePctg !== undefined) ? Number(featured.savePctg).toFixed(3) : "–" },
                                    { l: i18n("SHO"), v: featured ? (featured.shutouts || 0) : "–" }
                                ] : [
                                    { l: i18n("PJ"), v: featured ? (featured.gamesPlayed || 0) : "–" },
                                    { l: i18n("Goals"), v: featured ? (featured.goals || 0) : "–" },
                                    { l: i18n("Assists"), v: featured ? (featured.assists || 0) : "–" },
                                    { l: i18n("PTS"), v: featured ? (featured.points || 0) : "–" },
                                    { l: "+/-", v: (featured && featured.plusMinus !== undefined) ? (featured.plusMinus > 0 ? "+" + featured.plusMinus : featured.plusMinus) : "–" }
                                ]
                                delegate: ColumnLayout {
                                    spacing: 2
                                    Label { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: modelData.l; font.pixelSize: 10; opacity: 0.6; color: Kirigami.Theme.textColor }
                                    Label { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: String(modelData.v); font.pixelSize: 18; font.bold: true; color: Kirigami.Theme.textColor }
                                }
                            }
                        }
                    }
                }

                // 4. Historique Saisons
                Column {
                    id: historyBlock
                    width: 340
                    spacing: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: activeTab === 0 ? i18n("Season history") : i18n("Playoff history")
                        font.pixelSize: 11; font.bold: true; opacity: 0.5; color: Kirigami.Theme.textColor
                    }
                    Column {
                        width: parent.width
                        spacing: 0
                        Row {
                            width: parent.width; height: 24
                            Label { text: i18n("Season"); font.pixelSize: 10; opacity: 0.6; width: 52; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: "Lge"; font.pixelSize: 10; opacity: 0.6; width: 55; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: i18n("Team"); font.pixelSize: 10; opacity: 0.6; width: 36; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: i18n("PJ"); font.pixelSize: 10; opacity: 0.6; width: 30; horizontalAlignment: Text.AlignHCenter; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: isG ? i18n("W") : i18n("Goals"); font.pixelSize: 10; opacity: 0.6; width: 28; horizontalAlignment: Text.AlignHCenter; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: isG ? i18n("L") : i18n("Assists"); font.pixelSize: 10; opacity: 0.6; width: 28; horizontalAlignment: Text.AlignHCenter; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: isG ? i18n("GAA") : i18n("PTS"); font.pixelSize: 10; opacity: 0.6; width: 32; horizontalAlignment: Text.AlignHCenter; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: isG ? i18n("SV%") : i18n("+/-"); font.pixelSize: 10; opacity: 0.6; width: 32; horizontalAlignment: Text.AlignHCenter; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: "PIM"; font.pixelSize: 10; opacity: 0.6; width: 32; horizontalAlignment: Text.AlignHCenter; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Repeater {
                            model: playerRoot.currentTotals
                            delegate: Rectangle {
                                id: zebraRow
                                width: 340; height: 26
                                color: index % 2 === 0 ? "transparent" : Qt.rgba(1, 1, 1, 0.05)
                                readonly property bool isNHLRow: modelData.leagueAbbrev === "NHL" || modelData.leagueName === "National Hockey League"
                                
                                readonly property string rAbbrev: {
                                    if (!isNHLRow) return ""
                                    if (modelData.teamAbbrev) {
                                        var tabbr = (typeof modelData.teamAbbrev === 'string') ? modelData.teamAbbrev : (modelData.teamAbbrev.default || "")
                                        if (tabbr !== "") return tabbr
                                    }
                                    var name = ""
                                    if (modelData.teamCommonName) {
                                        name = typeof modelData.teamCommonName === 'string' ? modelData.teamCommonName : (modelData.teamCommonName.default || "")
                                    } else if (modelData.teamName) {
                                        name = typeof modelData.teamName === 'string' ? modelData.teamName : (modelData.teamName.default || "")
                                    }
                                    return Logic.resolveNHLAbbrev(name)
                                }

                                Row {
                                    anchors.fill: parent
                                    Label {
                                        text: {
                                            var s = String(modelData.season || "")
                                            if (s.length >= 8) return s.substring(0,4) + "-" + s.substring(6,8)
                                            return s
                                        }
                                        font.pixelSize: zebraRow.isNHLRow ? 12 : 11; font.bold: zebraRow.isNHLRow; width: 52; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Label { 
                                        text: modelData.leagueAbbrev || ""
                                        font.pixelSize: zebraRow.isNHLRow ? 11 : 10; font.bold: zebraRow.isNHLRow; opacity: zebraRow.isNHLRow ? 1.0 : 0.6; width: 55; elide: Text.ElideRight; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Item {
                                        width: 36; height: parent.height
                                        anchors.verticalCenter: parent.verticalCenter
                                        Rectangle {
                                            anchors.centerIn: parent
                                            radius: 2; width: 28; height: 14
                                            color: zebraRow.isNHLRow ? Logic.getTeamColorAdapted(zebraRow.rAbbrev, "", false, false, Kirigami.Theme.backgroundColor) : "transparent"
                                            Label {
                                                anchors.centerIn: parent
                                                text: zebraRow.isNHLRow ? (zebraRow.rAbbrev || "???") : (modelData.teamName ? (modelData.teamName.default || "").substring(0,3).toUpperCase() : "???")
                                                font.pixelSize: 9; font.bold: true; font.family: "monospace"
                                                color: zebraRow.isNHLRow ? Logic.getContrastColor(parent.color) : Kirigami.Theme.disabledTextColor
                                            }
                                        }
                                    }
                                    Label { text: String(modelData.gamesPlayed || 0); width: 30; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 11; opacity: 0.8; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                                    Label { text: isG ? String(modelData.wins || 0) : String(modelData.goals || 0); width: 28; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 11; opacity: 0.8; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                                    Label { text: isG ? String(modelData.losses || 0) : String(modelData.assists || 0); width: 28; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 11; opacity: 0.8; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                                    Label { text: isG ? ((modelData.goalsAgainstAverage !== undefined || modelData.goalsAgainstAvg !== undefined) ? Number(modelData.goalsAgainstAverage || modelData.goalsAgainstAvg).toFixed(2) : "—") : String(modelData.points || 0); width: 32; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 11; font.bold: !isG; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                                    Label { text: isG ? (modelData.savePctg !== undefined ? Number(modelData.savePctg).toFixed(3) : "—") : (modelData.plusMinus !== undefined ? (modelData.plusMinus > 0 ? "+" + modelData.plusMinus : modelData.plusMinus) : "—"); width: 32; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 11; opacity: 0.8; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                                    Label { text: String(modelData.pim || 0); width: 32; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 11; opacity: 0.6; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                    }
                }
            }
        }

        Components.StateLayer {
            loading: !!controller && controller.ply.loading
            error: controller ? controller.ply.error : ""
        }
    }
}
