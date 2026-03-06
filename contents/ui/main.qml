
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root
    Plasmoid.title: i18n("NHL Scores")
    preferredRepresentation: compactRepresentation

    property var favoriteTeams: (Plasmoid.configuration.favorites || "VAN,TOR").split(/\s*,\s*/).filter(function(s){ return s.length > 0 })
    property bool showAll: Plasmoid.configuration.showAll
    property bool todayOnly: Plasmoid.configuration.todayOnly
    property int lookaheadDays: Plasmoid.configuration.lookaheadDays || 2
    property int compactMaxGames: Plasmoid.configuration.compactMaxGames || 2
    property int maxTotalGames: Plasmoid.configuration.maxTotalGames || 20
    property bool showOvertimeSuffix: Plasmoid.configuration.showOvertimeSuffix
    property color liveColor: Plasmoid.configuration.liveColor || "#d90429"
    property color upcomingColor: Plasmoid.configuration.upcomingColor || "#2b6cb0"
    property color finalColor: Plasmoid.configuration.finalColor || "#6c757d"
    property string scoreLayout: Plasmoid.configuration.scoreLayout || 'stack'
    property bool showUpcomingTime: (Plasmoid.configuration.showUpcomingTime !== false)
    property string dateMode: Plasmoid.configuration.dateMode || 'local'
    property bool showYesterday: Plasmoid.configuration.showYesterday
    property bool showTwoDaysAgo: Plasmoid.configuration.showTwoDaysAgo


    ListModel { id: todayGames }
    property date lastUpdated
    property string debugMsg: ""

    Timer {
        id: pollTimer
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: refresh()
    }
    Timer {
        id: midnightKick
        interval: 60000   // vérifie chaque minute
        running: true
        repeat: true
        onTriggered: {
            let now = new Date()
            // entre 00:00 et 00:01
            if (now.getHours() === 0 && now.getMinutes() < 2) {
                // relancer le polling pour la nouvelle journée
                pollTimer.running = true
                // recharger les matchs
                refresh()
            }
        }
    }
    readonly property var teamColors: ({ 'ANA':'#F47A38','ARI':'#8C2633','UTA':'#6E2B62','BOS':'#FFB81C','BUF':'#003087','CAR':'#CC0000','CBJ':'#002654','CGY':'#C8102E','CHI':'#CF0A2C','COL':'#6F263D','DAL':'#006847','DET':'#CE1126','EDM':'#FF4C00','FLA':'#C8102E','LAK':'#111111','MIN':'#154734','MTL':'#AF1E2D','NJD':'#CE1126','NSH':'#FFB81C','NYI':'#00539B','NYR':'#0038A8','OTT':'#C52032','PHI':'#F74902','PIT':'#FFB81C','SEA':'#99D9D9','SJS':'#006D75','STL':'#002F87','TBL':'#002868','TOR':'#00205B','VAN':'#00205B','VGK':'#B4975A','WPG':'#041E42','WSH':'#C8102E' })

    function teamColor(code) {
        var c = teamColors[String(code||'').toUpperCase()]
        return c ? c : Kirigami.Theme.positiveBackgroundColor
    }

    function pad2(n) { return (n < 10 ? "0" : "") + n }
    function dateISO(d) { return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate()) }

    function isSameDay(a, b) { return a.getFullYear()===b.getFullYear() && a.getMonth()===b.getMonth() && a.getDate()===b.getDate() }
    function localTimeStr(ms) { var d = new Date(ms); return Qt.formatTime(d, Qt.DefaultLocaleShortDate) }
    function localDateStr(ms) { return Qt.formatDate(new Date(ms), "dd'/'MM") }

    // ---- Venue timezone helpers ----
    function teamZone(code) {
        switch(String(code||'')){
        case 'BOS': case 'BUF': case 'CAR': case 'CBJ': case 'DET': case 'FLA': case 'MTL': case 'NJD': case 'NYI': case 'NYR': case 'OTT': case 'PHI': case 'PIT': case 'TBL': case 'TOR': case 'WSH':
            return 'ET'
        case 'CHI': case 'DAL': case 'MIN': case 'NSH': case 'STL': case 'WPG':
            return 'CT'
        case 'COL': case 'CGY': case 'EDM': case 'UTA':
            return 'MT'
        case 'ARI':
            return 'MST'
        case 'ANA': case 'LAK': case 'SEA': case 'SJS': case 'VAN': case 'VGK':
            return 'PT'
        default:
            return 'ET'
        }
    }
    function zoneBaseOffsetHours(zone){
        if(zone==='ET') return -5
        if(zone==='CT') return -6
        if(zone==='MT') return -7
        if(zone==='MST') return -7
        if(zone==='PT') return -8
        return -5
    }
    function zoneHasDst(zone){ return zone!=='MST' }
    function nthSundayOfMonth(year, month0, n){
        var d = new Date(Date.UTC(year, month0, 1))
        var dow = d.getUTCDay()
        var firstSunday = 1 + ((7 - dow) % 7)
        return firstSunday + 7*(n-1)
    }
    function firstSundayNovember(year){ return nthSundayOfMonth(year, 10, 1) }
    function secondSundayMarch(year){ return nthSundayOfMonth(year, 2, 2) }
    function isDstDateLocalLike(year, month0, day, zone){
        if(!zoneHasDst(zone)) return false
        var dStart = secondSundayMarch(year)
        var dEnd = firstSundayNovember(year)
        if(month0>2 && month0<10) return true
        if(month0<2 || month0>10) return false
        if(month0===2) return day>=dStart
        if(month0===10) return day<dEnd
        return false
    }
    function venueDateStrUTC(msUTC, homeTeam){
        var zone = teamZone(homeTeam)
        var dStd = new Date(msUTC + zoneBaseOffsetHours(zone)*3600*1000)
        var y = dStd.getUTCFullYear()
        var m0 = dStd.getUTCMonth()
        var d = dStd.getUTCDate()
        var dst = isDstDateLocalLike(y, m0, d, zone)
        var off = zoneBaseOffsetHours(zone) + (dst ? 1 : 0)
        var shifted = new Date(msUTC + off*3600*1000)
        var dd = shifted.getUTCDate()
        var mm = shifted.getUTCMonth()+1
        function pad(n){ return (n<10?'0':'')+n }
        return pad(dd)+'/'+pad(mm)
    }

    // ---- Networking ----
    function httpGet(url, cb){
        let xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function(){
            if(xhr.readyState===XMLHttpRequest.DONE){
                if(xhr.status===200){
                    try{ cb(null, JSON.parse(xhr.responseText)) }catch(e){ cb(e,null) }
                } else {
                    cb(new Error("HTTP "+xhr.status+" @ "+url), null)
                }
            }
        }
        xhr.send()
    }

    function makeForwardDaysArray(n){
        const days=[]
        const base=new Date()
        base.setHours(0,0,0,0)
        for(let i=0;i<=Math.max(0,n);i++){
            days.push(new Date(base.getTime()+i*24*3600*1000))
        }
        return days
    }

    function fetchLeagueByDates(days, cb){
        let acc=[]
        let pending=days.length
        let errors=[]
        if(pending===0){ cb(acc, errors); return }
        days.forEach(function(d){
            const u = "https://api-web.nhle.com/v1/scoreboard/" + dateISO(d)
            httpGet(u, function(err,data){
                if(err){ errors.push(String(err)) }
                else if (data && data.games){ acc = acc.concat(data.games) }
                pending--
                if(pending===0) cb(acc, errors)
            })
        })
    }

    readonly property var allTeams: ['ANA','ARI','UTA','BOS','BUF','CAR','CBJ','CGY','CHI','COL','DAL','DET','EDM','FLA','LAK','MIN','MTL','NJD','NSH','NYI','NYR','OTT','PHI','PIT','SEA','SJS','STL','TBL','TOR','VAN','VGK','WPG','WSH']

    function fetchTeamNow(teamCodes, cb){
        let acc=[]
        let errors=[]
        let pending=teamCodes.length
        if(pending===0){ cb(acc, errors); return }
        teamCodes.forEach(function(team){
            const url = "https://api-web.nhle.com/v1/scoreboard/" + team + "/now"
            httpGet(url, function(err, data){
                if (err) { errors.push(String(err)) }
                else if (data && data.gamesByDate) {
                    for (let i=0;i<data.gamesByDate.length;i++){
                        const gbd = data.gamesByDate[i]
                        if (gbd && gbd.games) acc = acc.concat(gbd.games)
                    }
                }
                pending--
                if (pending===0) cb(acc, errors)
            })
        })
    }

    function refresh(){

        let days = []

        let base = new Date()
        base.setHours(0,0,0,0)

        // passé
        if (showTwoDaysAgo)
            days.push(new Date(base.getTime() - 2*24*3600*1000))

            if (showYesterday)
                days.push(new Date(base.getTime() - 1*24*3600*1000))

                // aujourd'hui
                days.push(new Date(base))

                // futur si todayOnly = false
                if (!todayOnly){
                    for(let i=1;i<=lookaheadDays;i++){
                        days.push(new Date(base.getTime()+i*24*3600*1000))
                    }
                }

                fetchLeagueByDates(days, function(leagueGames, leagueErrs){
                    if (leagueGames && leagueGames.length){
                        buildFromRawGames(leagueGames, leagueErrs)
                    } else {
                        const pool = showAll ? allTeams : favoriteTeams
                        fetchTeamNow(pool, function(teamGames, teamErrs){
                            buildFromRawGames(teamGames || [],
                                              (leagueErrs||[]).concat(teamErrs||[]))
                        })
                    }
                })
    }

    function isScoreSet(g){ return g && g.homeTeam && g.awayTeam && g.homeTeam.score !== undefined && g.awayTeam.score !== undefined }

    function statusFromGame(g){
        var s = (g && g.gameState) ? String(g.gameState).toUpperCase() : ''
        if (s==='LIVE' || s==='IN_PROGRESS') return 'LIVE'
        if (s==='FINAL' || s==='FINAL_OT' || s==='FINAL_SO') return 'FINAL'
        if (s==='PRE' || s==='FUT' || s==='SCHEDULED' || s==='PREGAME') return 'UPCOMING'
        if (s==='OFF'){
            var start = new Date(g.startTimeUTC || new Date())
            var now = new Date()
            if (isScoreSet(g) && (now.getTime() - start.getTime()) > 30*60000) return 'FINAL'
            return 'UPCOMING'
        }
        var pd = g && g.periodDescriptor ? (g.periodDescriptor.periodType || '').toUpperCase() : ''
        if (pd==='FINAL') return 'FINAL'
        var outcome = g && g.gameOutcome ? String(g.gameOutcome).toUpperCase() : ''
        if (outcome && outcome !== 'UNDEFINED') return 'FINAL'
        var st = new Date(g.startTimeUTC || new Date())
        var now2 = new Date()
        if (st.getTime() > now2.getTime() + 5*60000) return 'UPCOMING'
        if (isScoreSet(g)) return 'LIVE'
        return 'UPCOMING'
    }

    function statusText(st){ return st==='LIVE' ? 'LIVE' : (st==='FINAL' ? i18n('Final') : i18n('Upcoming')) }

    function statusSuffix(rawState, periodType){
        if (!showOvertimeSuffix) return ''
        var s = (rawState || '').toUpperCase()
        var pd = (periodType || '').toUpperCase()
        if (s.indexOf('OT') >= 0 || pd === 'OT') return ' OT'
        if (s.indexOf('SO') >= 0 || pd === 'SO') return ' SO'
        return ''
    }

    function statusColor(st){ return st==='LIVE' ? liveColor : (st==='FINAL' ? finalColor : upcomingColor) }

    function gameCenterUrl(away, home, start, gameId){
        var d = new Date(start)
        var y = d.getFullYear()
        var m = pad2(d.getMonth()+1)
        var da = pad2(d.getDate())
        return 'https://www.nhl.com/gamecenter/' + String(away||'').toLowerCase() + '-vs-' + String(home||'').toLowerCase() + '/' + y + '/' + m + '/' + da + '/' + String(gameId||'')
    }
    function hasActiveGames(){

        let now = new Date()
        for (let i = 0; i < todayGames.count; i++) {
            let g = todayGames.get(i)
            if (g.statusRole === 'LIVE')
                return true
                if (g.statusRole === 'UPCOMING') {
                    let d = new Date(g.start)
                    if (isSameDay(d, now))
                        return true
                }
        }
        return false
    }
    function buildFromRawGames(games, errors){
        games = games || []
        const now = new Date()
        let pastDays = 0
        if (showYesterday) pastDays = 1
            if (showTwoDaysAgo) pastDays = 2

                const startOfToday = new Date(
                    now.getFullYear(),
                                              now.getMonth(),
                                              now.getDate() - pastDays
                )
        const endWin = new Date(now.getFullYear(), now.getMonth(), now.getDate() + (todayOnly ? 0 : lookaheadDays), 23, 59, 59, 999)
        function inWindow(g){ const t = new Date(g.startTimeUTC || now); return t >= startOfToday && t <= endWin }
        let filtered = games.filter(function(g){ return inWindow(g) })

        if (!showAll && favoriteTeams.length){
            filtered = filtered.filter(function(g){
                const h = g.homeTeam && g.homeTeam.abbrev
                const a = g.awayTeam && g.awayTeam.abbrev
                return favoriteTeams.indexOf(h) >= 0 || favoriteTeams.indexOf(a) >= 0
            })
        }

        let byId = {}
        for (let i=0;i<filtered.length;i++) { const g = filtered[i]; byId[g.id] = g }
        let uniq = Object.keys(byId).map(function(k){ return byId[k] })
        uniq = uniq.map(function(g){
            const st = statusFromGame(g)
            return {
                gameId: g.id || 0,
                home: (g.homeTeam && g.homeTeam.abbrev) || '',
                away: (g.awayTeam && g.awayTeam.abbrev) || '',
                hg: (g.homeTeam && g.homeTeam.score !== undefined ? g.homeTeam.score : 0),
                ag: (g.awayTeam && g.awayTeam.score !== undefined ? g.awayTeam.score : 0),
                start: new Date(g.startTimeUTC || new Date()).getTime() || 999,
                statusRole: st,
                rawState: (g.gameState || ''),
                periodType: (g.periodDescriptor && g.periodDescriptor.periodType) ? g.periodDescriptor.periodType : ''
            }
        }).sort(function(a,b){ return a.start - b.start })

        todayGames.clear()
        for (let i=0;i<uniq.length;i++) { todayGames.append(uniq[i]) }
        lastUpdated = new Date()
        debugMsg = (errors && errors.length ? (errors.join(' | ') + ' · ') : '') + 'loaded ' + todayGames.count + ' game(s)'
        pollTimer.running = hasActiveGames()
    }

    Connections {
        target: Plasmoid.configuration
        function onFavoritesChanged(){ root.favoriteTeams = (Plasmoid.configuration.favorites||'').split(/\s*,\s*/).filter(function(s){return s.length>0}); refresh() }
        function onShowAllChanged(){ refresh() }
        function onTodayOnlyChanged(){ refresh() }
        function onShowYesterdayChanged(){ refresh() }
        function onShowTwoDaysAgoChanged(){ refresh() }
        function onLookaheadDaysChanged(){ refresh() }
        function onScoreLayoutChanged(){ root.scoreLayout = Plasmoid.configuration.scoreLayout || 'stack' }
        function onShowUpcomingTimeChanged(){ }
        function onDateModeChanged(){ }
    }

    Component { id: statusBadge
        Rectangle {
            property string gameStatus: 'UPCOMING'
            property string suffix: ''
            radius: 5
            color: statusColor(gameStatus)
            opacity: 0.95
            Text {
                id: stText
                anchors.centerIn: parent
                text: (statusText(parent.gameStatus) + parent.suffix)
                color: 'white'
                font.pixelSize: 10
                font.bold: true
            }
            width: stText.implicitWidth + 6
            height: stText.implicitHeight + 2
        }
    }

    Component { id: teamColumn
        Column {
            spacing: 0
            property string code: ''
            property int score: 0
            Rectangle {
                radius: 4
                color: teamColor(code)
                border.color: 'white'
                border.width: 1
                height: nameText.implicitHeight + 1
                width: nameText.implicitWidth + 6
                Text {
                    id: nameText
                    anchors.centerIn: parent
                    text: code
                    color: 'white'
                    font.pixelSize: 11
                    font.bold: true
                }
            }
            Text {
                text: String(score)
                font.pixelSize: 14
                font.bold: true
                color: Kirigami.Theme.textColor
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    Component { id: teamRowInline
        Row {
            spacing: 4
            property string awayCode: ''
            property string homeCode: ''
            property int agScore: 0
            property int hgScore: 0
            Rectangle {
                radius: 4
                color: teamColor(awayCode)
                border.color: 'white'
                border.width: 1
                height: aText.implicitHeight + 1
                width: aText.implicitWidth + 6
                Text { id: aText; anchors.centerIn: parent; text: awayCode; color: 'white'; font.pixelSize: 11; font.bold: true }
            }
            Label { text: String(agScore); font.bold: true; color: Kirigami.Theme.textColor }
            Label { text: "–"; color: Kirigami.Theme.textColor }
            Label { text: String(hgScore); font.bold: true; color: Kirigami.Theme.textColor }
            Rectangle {
                radius: 4
                color: teamColor(homeCode)
                border.color: 'white'
                border.width: 1
                height: hText.implicitHeight + 1
                width: hText.implicitWidth + 6
                Text { id: hText; anchors.centerIn: parent; text: homeCode; color: 'white'; font.pixelSize: 11; font.bold: true }
            }
        }
    }

    function upcomingWhenText(startMs, statusRole, homeTeam){
        if (!(statusRole==='UPCOMING' && showUpcomingTime)) return ''
        if (isSameDay(new Date(startMs), new Date())) return localTimeStr(startMs)
        if (dateMode==='venue') return venueDateStrUTC(startMs, homeTeam)
        return localDateStr(startMs)
    }

    function finalWhenText(startMs, statusRole, homeTeam){

        if (statusRole !== 'FINAL')
            return ''

            let d = new Date(startMs)

            if (dateMode === 'venue')
                return venueDateStrUTC(startMs, homeTeam)

                return localDateStr(startMs)
    }

    compactRepresentation: Item {
        id: compactRoot
        readonly property int pad: 6
        implicitWidth: Math.max(row.implicitWidth + pad, emptyMsg.implicitWidth + pad)
        implicitHeight: Math.max(row.implicitHeight + 2, emptyMsg.implicitHeight + 2)
        width: implicitWidth
        height: implicitHeight
        Layout.preferredWidth: implicitWidth
        Layout.minimumWidth: implicitWidth
        Layout.maximumWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        Layout.minimumHeight: implicitHeight
        Layout.maximumHeight: implicitHeight

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            visible: todayGames.count > 0
            Repeater {
                model: todayGames
                delegate: Row {
                    opacity: statusRole === 'FINAL' ? 0.5 : 1.0
                    visible: index < compactMaxGames
                    spacing: 6
                    Loader {
                        sourceComponent: (scoreLayout==='stack' ? teamColumn : teamRowInline)
                        onLoaded: {
                            if (scoreLayout==='stack') { item.code = away; item.score = ag }
                            else { item.awayCode = away; item.homeCode = home; item.agScore = ag; item.hgScore = hg }
                        }
                    }
                    Loader {
                        sourceComponent: (scoreLayout==='stack' ? teamColumn : null)
                        visible: (scoreLayout==='stack')
                        onLoaded: { if (scoreLayout==='stack') { item.code = home; item.score = hg } }
                    }
                    Column {
                        spacing: 2
                        Loader {
                            sourceComponent: statusBadge
                            onLoaded: { item.gameStatus = statusRole; item.suffix = statusSuffix(rawState, periodType) }
                        }
                        Label {

                            visible: (statusRole === 'UPCOMING' && showUpcomingTime)
                            || statusRole === 'FINAL'

                            text: statusRole === 'FINAL'
                            ? finalWhenText(start, statusRole, home)
                            : upcomingWhenText(start, statusRole, home)

                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: Qt.openUrlExternally(gameCenterUrl(away, home, start, gameId))
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
        Label {
            id: emptyMsg
            anchors.centerIn: parent
            visible: todayGames.count === 0
            text: i18n('No games')
            color: Kirigami.Theme.textColor
        }
    }

    fullRepresentation: ScrollView {
        implicitWidth: 420
        implicitHeight: 480
        ColumnLayout {
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                CheckBox { text: i18n('All'); checked: showAll; onToggled: Plasmoid.configuration.showAll = checked }
                CheckBox { text: i18n('Today only'); checked: todayOnly; onToggled: Plasmoid.configuration.todayOnly = checked }
                CheckBox { text: i18n('OT/SO suffix'); checked: showOvertimeSuffix; onToggled: Plasmoid.configuration.showOvertimeSuffix = checked }
                ComboBox {
                    id: layoutCombo
                    model: [ i18n('Score below (column)'), i18n('Score next to name (row)') ]
                    currentIndex: (scoreLayout==='stack'?0:1)
                    onActivated: Plasmoid.configuration.scoreLayout = (currentIndex===0?'stack':'inline')
                    Layout.alignment: Qt.AlignRight
                }
                Button { text: i18n('Configure NHL Scores…'); icon.name: 'settings-configure'; onClicked: plasmoid.action('configure').trigger() }
            }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: todayGames
                delegate: ItemDelegate {
                    opacity: statusRole === 'FINAL' ? 0.5 : 1.0
                    width: ListView.view.width
                    contentItem: RowLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12
                        Loader {
                            sourceComponent: (scoreLayout==='stack' ? teamColumn : teamRowInline)
                            onLoaded: {
                                if (scoreLayout==='stack') { item.code = away; item.score = ag }
                                else { item.awayCode = away; item.homeCode = home; item.agScore = ag; item.hgScore = hg }
                            }
                        }
                        Loader {
                            sourceComponent: (scoreLayout==='stack'? teamColumn : null)
                            visible: (scoreLayout==='stack')
                            onLoaded: { if (scoreLayout==='stack') { item.code = home; item.score = hg } }
                        }
                        ColumnLayout {
                            spacing: 2
                            Loader {
                                sourceComponent: statusBadge
                                onLoaded: { item.gameStatus = statusRole; item.suffix = statusSuffix(rawState, periodType) }
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Label {

                                visible: (statusRole === 'UPCOMING' && showUpcomingTime)
                                || statusRole === 'FINAL'

                                text: statusRole === 'FINAL'
                                ? finalWhenText(start, statusRole, home)
                                : upcomingWhenText(start, statusRole, home)

                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: 11
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                    onClicked: Qt.openUrlExternally(gameCenterUrl(away, home, start, gameId))
                }
                footer: Label {
                    text: (lastUpdated ? i18n('Updated: %1', Qt.formatDateTime(lastUpdated, 'hh:mm:ss')) : '') + (debugMsg ? '  ·  ' + debugMsg : '')
                    opacity: 0.6
                    horizontalAlignment: Text.AlignHCenter
                    width: ListView.view.width
                }
            }
        }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n('Refresh now')
            icon.name: 'view-refresh'
            onTriggered: refresh()
        }
    ]
}
