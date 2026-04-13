import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic
import "../components" as Components

Item {
    id: playerRoot
    property var controller
    property string from: controller ? controller.ply.from : 'leaders'

    anchors.fill: parent
    visible: !!(controller && controller.nav.player)

    readonly property var p: controller ? controller.ply.data : null
    readonly property bool isG: p ? (p.positionCode === 'G' || p.position === 'G') : false
    
    property int activeTab: 0 // 0: Regular, 1: Playoffs

    readonly property var featured: {
        if (!p || !p.featuredStats) return null
        if (activeTab === 0) return p.featuredStats.regularSeason ? p.featuredStats.regularSeason.subSeason : null
        return p.featuredStats.playoffs ? p.featuredStats.playoffs.subSeason : null
    }

    readonly property var regularSeasonTotals: {
        if (!p || !p.seasonTotals) return []
        var filtered = []
        for (var i = 0; i < p.seasonTotals.length; i++) {
            if (p.seasonTotals[i].gameTypeId === 2) {
                filtered.push(p.seasonTotals[i])
            }
        }
        return filtered
    }

    readonly property var playoffTotals: {
        if (!p || !p.seasonTotals) return []
        var filtered = []
        for (var i = 0; i < p.seasonTotals.length; i++) {
            if (p.seasonTotals[i].gameTypeId === 3) {
                filtered.push(p.seasonTotals[i])
            }
        }
        return filtered
    }

    readonly property var currentTotals: activeTab === 0 ? regularSeasonTotals : playoffTotals

    readonly property var nhlTotal: {
        var t = { gp:0, g:0, a:0, pts:0, pm:0, pim:0, w:0, l:0, ga:0, sa:0, toi:0, weightedGaa:0, gaaMatchCount:0 }
        if (p && p.seasonTotals) {
            var targetType = activeTab === 0 ? 2 : 3
            p.seasonTotals.forEach(function(s) {
                if (s.gameTypeId === targetType && (s.leagueAbbrev === "NHL" || s.leagueName === "National Hockey League")) {
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
                        t.toi += parseInt(parts[0]) * 60 + (parts[1] ? parseInt(parts[1]) : 0)
                    } else if (isG && (s.goalsAgainstAvg !== undefined || s.goalsAgainstAverage !== undefined)) {
                        var avg = s.goalsAgainstAvg !== undefined ? s.goalsAgainstAvg : s.goalsAgainstAverage
                        t.weightedGaa += (avg * (s.gamesPlayed || 1))
                        t.gaaMatchCount += (s.gamesPlayed || 1)
                    }
                }
            })
        }
        return t
    }

    readonly property string nhlTotalGaa: {
        if (!isG) return ""
        if (nhlTotal.toi > 0) return (nhlTotal.ga / (nhlTotal.toi / 3600)).toFixed(3)
        if (nhlTotal.gaaMatchCount > 0) return (nhlTotal.weightedGaa / nhlTotal.gaaMatchCount).toFixed(3)
        return "—"
    }

    readonly property string nhlTotalSv: {
        if (!isG) return ""
        if (nhlTotal.sa > 0) return (Number((nhlTotal.sa - nhlTotal.ga)/nhlTotal.sa)).toFixed(3)
        return "—"
    }

    function calculateAge(birthDate) {
        if (!birthDate) return ""
        var birth = new Date(birthDate)
        var now = new Date()
        var age = now.getFullYear() - birth.getFullYear()
        var m = now.getMonth() - birth.getMonth()
        if (m < 0 || (m === 0 && now.getDate() < birth.getDate())) age--
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

        Components.StateLayer {
            loading: !!controller && controller.ply.loading
            error: (controller && controller.ply.error) ? controller.ply.error : ""
        }

        ScrollView {
            id: playerScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: playerScrollView.availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            visible: !!(p && !controller.ply.loading)

            Column {
                id: columnContainer
                width: playerScrollView.availableWidth
                spacing: 24

                // 1. Photo
                Item {
                    id: photoBlock
                    width: Math.min(320, parent.width - 40)
                    height: 220
                    anchors.horizontalCenter: parent.horizontalCenter
                    Image {
                        anchors.fill: parent
                        source: (p && p.headshot) ? p.headshot : ""
                        fillMode: Image.PreserveAspectCrop
                        opacity: 0.9
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 60
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: "black" }
                        }
                    }
                    Label {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.bottomMargin: 12
                        text: (p && p.firstName && p.lastName) ? (p.firstName.default + " " + p.lastName.default) : ""
                        font.pixelSize: 18
                        font.bold: true
                        color: "white"
                    }
                    Label {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.bottomMargin: 12
                        text: p ? ("#" + (p.sweaterNumber || "?")) : ""
                        font.pixelSize: 20
                        font.bold: true
                        color: "white"
                        opacity: 0.6
                    }
                }

                // 2. Infos de base
                Column {
                    id: infoBlock
                    width: parent.width
                    spacing: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    Row {
                        spacing: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                        Rectangle {
                            radius: 3
                            color: p ? Logic.getTeamColor(p.currentTeamAbbrev, Kirigami.Theme.backgroundColor) : "gray"
                            width: teamCodeLbl.contentWidth + 16
                            height: teamCodeLbl.contentHeight + 6
                            anchors.verticalCenter: parent.verticalCenter
                            Label {
                                id: teamCodeLbl
                                anchors.centerIn: parent
                                text: p ? (p.currentTeamAbbrev || "???") : ""
                                color: Logic.getContrastColor(parent.color)
                                font.bold: true
                                font.family: "monospace"
                                font.pixelSize: 13
                            }
                        }
                        Label { 
                            text: {
                                if (!p) return ""
                                var pos = (p.positionCode || p.position || "?")
                                var age = calculateAge(p.birthDate)
                                return "·  " + pos + "  ·  " + age + " " + i18n("years")
                            }
                            font.bold: true
                            font.pixelSize: 15
                            color: Kirigami.Theme.textColor 
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: p ? (i18n("Height:") + " " + (p.heightInCentimeters || "?") + " cm  /  " + i18n("Weight:") + " " + (p.weightInKilograms || "?") + " kg") : ""
                        font.pixelSize: 12
                        opacity: 0.8
                        color: Kirigami.Theme.textColor 
                    }
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        visible: !!(p && p.birthDate)
                        text: i18n("Born:") + " " + (p ? p.birthDate.substring(0, 10) : "")
                        font.pixelSize: 11
                        opacity: 0.6
                        color: Kirigami.Theme.textColor
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
                        font.pixelSize: 11
                        opacity: 0.6
                        color: Kirigami.Theme.textColor
                        wrapMode: Text.WordWrap
                    }
                }

                // 3. Stats Saison
                Column {
                    id: statsBlock
                    width: 320
                    spacing: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    Label { 
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: activeTab === 0 ? i18n("Season stats") : i18n("Playoff stats")
                        font.pixelSize: 11
                        font.bold: true
                        opacity: 0.5
                        color: Kirigami.Theme.textColor 
                    }
                    Rectangle {
                        width: parent.width
                        height: 55
                        radius: 6
                        color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.08)
                        border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2)
                        RowLayout {
                            anchors.fill: parent
                            spacing: 0
                            Repeater {
                                model: isG ? [
                                    { l: i18n("PJ"), v: featured ? (featured.gamesPlayed || 0) : "–" },
                                    { l: i18n("W"), v: featured ? (featured.wins || 0) : "–" },
                                    { l: i18n("GAA"), v: (featured && featured.goalsAgainstAverage !== undefined) ? Number(featured.goalsAgainstAverage).toFixed(3) : "–" },
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
                                    Label { 
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData.l
                                        font.pixelSize: 10
                                        opacity: 0.6
                                        color: Kirigami.Theme.textColor 
                                    }
                                    Label { 
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: String(modelData.v)
                                        font.pixelSize: 18
                                        font.bold: true
                                        color: Kirigami.Theme.textColor 
                                    }
                                }
                            }
                        }
                    }
                }

                // 4. Historique Saisons (ALIGNEMENT ET GRAS)
                Column {
                    id: historyBlock
                    width: 340
                    spacing: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: activeTab === 0 ? i18n("Season history") : i18n("Playoff history")
                        font.pixelSize: 11
                        font.bold: true
                        opacity: 0.5
                        color: Kirigami.Theme.textColor
                    }
                    Column {
                        width: parent.width
                        spacing: 0
                        Row {
                            width: parent.width
                            height: 24
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
                                width: 340
                                height: 26
                                color: index % 2 === 0 ? "transparent" : Qt.rgba(1, 1, 1, 0.05)
                                readonly property bool isNHLRow: modelData.leagueAbbrev === "NHL" || modelData.leagueName === "National Hockey League"
                                
                                // Détermination robuste de l'abréviation
                                readonly property string rAbbrev: {
                                    if (!isNHLRow) return ""
                                    if (modelData.teamAbbrev) {
                                        if (typeof modelData.teamAbbrev === 'string') return modelData.teamAbbrev
                                        if (modelData.teamAbbrev.default) return String(modelData.teamAbbrev.default)
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
                                        font.pixelSize: zebraRow.isNHLRow ? 12 : 11
                                        font.bold: zebraRow.isNHLRow
                                        width: 52
                                        color: Kirigami.Theme.textColor
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Label { 
                                        text: modelData.leagueAbbrev || ""
                                        font.pixelSize: zebraRow.isNHLRow ? 11 : 10
                                        font.bold: zebraRow.isNHLRow
                                        opacity: zebraRow.isNHLRow ? 1.0 : 0.6
                                        width: 55
                                        elide: Text.ElideRight
                                        color: Kirigami.Theme.textColor 
                                        anchors.verticalCenter: parent.verticalCenter
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
                                    Label { text: modelData.gamesPlayed || 0; font.pixelSize: zebraRow.isNHLRow ? 12 : 11; font.bold: zebraRow.isNHLRow; width: 30; horizontalAlignment: Text.AlignHCenter; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                                    Label { text: isG ? (modelData.wins || 0) : (modelData.goals || 0); font.pixelSize: zebraRow.isNHLRow ? 12 : 11; font.bold: zebraRow.isNHLRow; width: 28; horizontalAlignment: Text.AlignHCenter; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                                    Label { text: isG ? (modelData.losses || 0) : (modelData.assists || 0); font.pixelSize: zebraRow.isNHLRow ? 12 : 11; font.bold: zebraRow.isNHLRow; width: 28; horizontalAlignment: Text.AlignHCenter; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                                    Label { 
                                        text: {
                                            if (isG) {
                                                var gaa = modelData.goalsAgainstAvg !== undefined ? modelData.goalsAgainstAvg : (modelData.goalsAgainstAverage !== undefined ? modelData.goalsAgainstAverage : modelData.gaa)
                                                return gaa !== undefined ? Number(gaa).toFixed(3) : '—'
                                            }
                                            return (modelData.points || 0)
                                        }
                                        font.pixelSize: zebraRow.isNHLRow ? 12 : 11; font.bold: zebraRow.isNHLRow; width: 32; horizontalAlignment: Text.AlignHCenter; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Label { 
                                        text: {
                                            if (isG) {
                                                var svp = modelData.savePctg !== undefined ? modelData.savePctg : (modelData.savePercentage !== undefined ? modelData.savePercentage : modelData.svp)
                                                return svp !== undefined ? Number(svp).toFixed(3) : '—'
                                            }
                                            return (modelData.plusMinus !== undefined ? (modelData.plusMinus > 0 ? "+" + modelData.plusMinus : modelData.plusMinus) : "0")
                                        }
                                        font.pixelSize: zebraRow.isNHLRow ? 12 : 11; font.bold: zebraRow.isNHLRow; width: 32; horizontalAlignment: Text.AlignHCenter; color: !isG ? (modelData.plusMinus > 0 ? "#44cc44" : (modelData.plusMinus < 0 ? "#cc4444" : Kirigami.Theme.textColor)) : Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Label { text: modelData.pim || 0; font.pixelSize: zebraRow.isNHLRow ? 12 : 11; font.bold: zebraRow.isNHLRow; width: 32; horizontalAlignment: Text.AlignHCenter; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                        Row {
                            width: parent.width
                            height: 30
                            Label { text: "NHL TOTAL"; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; width: 52; anchors.verticalCenter: parent.verticalCenter }
                            Item { width: 55; height: 1 }
                            Item { width: 36; height: 1 }
                            Label { text: playerRoot.nhlTotal.gp; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; width: 30; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: isG ? playerRoot.nhlTotal.w : playerRoot.nhlTotal.g; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; width: 28; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: isG ? playerRoot.nhlTotal.l : playerRoot.nhlTotal.a; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; width: 28; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: isG ? playerRoot.nhlTotalGaa : playerRoot.nhlTotal.pts; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; width: 32; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: isG ? playerRoot.nhlTotalSv : (playerRoot.nhlTotal.pm > 0 ? "+" + playerRoot.nhlTotal.pm : playerRoot.nhlTotal.pm); font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; width: 32; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: playerRoot.nhlTotal.pim; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; width: 32; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }

                // 5. Derniers Matchs (ZÉBRÉ ET ALIGNÉ)
                Column {
                    id: gamesBlock
                    width: 320
                    spacing: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: activeTab === 0
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: i18n("Last games")
                        font.pixelSize: 11; font.bold: true; opacity: 0.5; color: Kirigami.Theme.textColor
                    }
                    Repeater {
                        model: p ? (p.last5Games || []) : []
                        delegate: Rectangle {
                            width: 320
                            height: 32
                            radius: 4
                            color: index % 2 === 0 ? "transparent" : Qt.rgba(1, 1, 1, 0.05)
                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12
                                Label { 
                                    text: { 
                                        if (!modelData.gameDate) return ""
                                        var d = new Date(modelData.gameDate)
                                        return Logic.pad2(d.getDate()) + "/" + Logic.pad2(d.getMonth() + 1)
                                    }
                                    font.pixelSize: 11; opacity: 0.6; width: 40; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter
                                }
                                Rectangle {
                                    radius: 3; color: Logic.getTeamColor(modelData.opponentAbbrev, Kirigami.Theme.backgroundColor)
                                    width: 32; height: 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    Label { anchors.centerIn: parent; text: modelData.opponentAbbrev || "?"; color: Logic.getContrastColor(parent.color); font.bold: true; font.pixelSize: 10; font.family: "monospace" }
                                }
                                Label { 
                                    text: isG ? (modelData.decision === 'W' ? 'W' : (modelData.decision === 'L' ? 'L' : '–')) : ((modelData.goals || 0) + "G " + (modelData.assists || 0) + "A")
                                    font.pixelSize: 12; font.bold: true; width: 80; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter
                                }
                                Label { 
                                    text: {
                                        if (isG) return (modelData.savePctg !== undefined ? Number(modelData.savePctg).toFixed(3) : "–")
                                        var pm = modelData.plusMinus || 0
                                        return pm > 0 ? "+" + pm : String(pm)
                                    }
                                    font.pixelSize: 12; font.bold: true; opacity: 0.8; color: Kirigami.Theme.textColor; width: 45; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }
                Item { height: 20; width: 1 }
            }
        }
    }
}
