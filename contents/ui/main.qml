
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami
import org.kde.notification

PlasmoidItem {
    id: root
    Plasmoid.title: i18n("NHL Scores")
    preferredRepresentation: compactRepresentation
    property var favoriteTeams: []
    property bool showAllTeams: Plasmoid.configuration.showAllTeams || false
    property int maxGames: Plasmoid.configuration.maxGames || 10
    property int lookaheadDays: Plasmoid.configuration.lookaheadDays || 2
    function updateFavoriteTeams() {
        let f = Plasmoid.configuration.favorites || ""
        favoriteTeams = f.split(/\s*,\s*/).filter(function(s){
            return s.length > 0
        })
    }
    property bool showOvertimeSuffix: Plasmoid.configuration.showOvertimeSuffix
    property color liveColor: Plasmoid.configuration.liveColor || "#d90429"
    property color upcomingColor: Plasmoid.configuration.upcomingColor || "#2b6cb0"
    property color finalColor: Plasmoid.configuration.finalColor || "#6c757d"
    property string scoreLayout: Plasmoid.configuration.scoreLayout || 'stack'
    property bool showUpcomingTime: (Plasmoid.configuration.showUpcomingTime !== false)
    property string dateMode: Plasmoid.configuration.dateMode || 'local'
    property bool showYesterday: Plasmoid.configuration.showYesterday
    property bool showTwoDaysAgo: Plasmoid.configuration.showTwoDaysAgo

    Component.onCompleted: {
        updateFavoriteTeams()
        Plasmoid.setAction("refreshNow", i18n("Refresh now"), "view-refresh")
        refresh()
    }

    function action_refreshNow() {
        refresh()
    }

    ListModel {
        id: todayGames
    }
    property date lastUpdated
    property string debugMsg: ""
    property bool initialLoading: true

    // ── Notifications de buts ────────────────────────────────────────────
    property bool goalNotificationsEnabled: Plasmoid.configuration.goalNotifications !== false
    // Snapshot des scores avant chaque refresh : { gameId -> { ag, hg } }
    property var prevScores: ({})

    // Composant réutilisable — une instance par notification (autoDelete: true)
    Component {
        id: goalNotifComponent
        Notification {
            componentName: "nhlscores"
            eventId:       "goal"
            iconName:      "org.dany.nhlscores"
            urgency:       Notification.NormalUrgency
            autoDelete:    true
        }
    }

    function sendGoalNotification(away, home, ag, hg, prevAg, prevHg) {
        if (!goalNotificationsEnabled) return
        let lines = []
        if (ag > prevAg) lines.push(away + "  " + ag + "–" + hg)
        if (hg > prevHg) lines.push(home + "  " + hg + "–" + ag)
        if (lines.length === 0) return
        let notif = goalNotifComponent.createObject(root)
        notif.title = i18n("NHL Goal!")
        notif.text  = lines.join("\n")
        notif.sendEvent()
    }

    // Retourne true s'il y a des matchs LIVE ou à venir aujourd'hui
    function hasActiveGames() {
        let now = new Date()
        for (let i = 0; i < todayGames.count; i++) {
            let g = todayGames.get(i)
            if (g.statusRole === 'LIVE') return true
            if (g.statusRole === 'UPCOMING' && isSameDay(new Date(g.start), now)) return true
        }
        return false
    }

    Timer {
        id: pollTimer
        interval: hasActiveGames() ? 30000 : 300000  // 30s si actif, 5min sinon
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
            // Minuit (nouvelle journée) ou 4h AM (tous les matchs NHL sont terminés)
            if ((now.getHours() === 0 || now.getHours() === 4) && now.getMinutes() < 2) {
                pollTimer.running = true
                refresh()
            }
        }
    }
    readonly property var teamColors: ({ 'ANA':'#F47A38','UTA':'#6E2B62','BOS':'#FFB81C','BUF':'#003087','CAR':'#CC0000','CBJ':'#002654','CGY':'#C8102E','CHI':'#CF0A2C','COL':'#6F263D','DAL':'#006847','DET':'#CE1126','EDM':'#FF4C00','FLA':'#C8102E','LAK':'#111111','MIN':'#154734','MTL':'#AF1E2D','NJD':'#CE1126','NSH':'#FFB81C','NYI':'#00539B','NYR':'#0038A8','OTT':'#C52032','PHI':'#F74902','PIT':'#FFB81C','SEA':'#99D9D9','SJS':'#006D75','STL':'#002F87','TBL':'#002868','TOR':'#00205B','VAN':'#00205B','VGK':'#B4975A','WPG':'#041E42','WSH':'#C8102E' })

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
        if(zone==='PT') return -8
        return -5
    }
    function zoneHasDst(zone){ return true }
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

    function liveClockText(periodType, period, timeRemaining) {
        if (!timeRemaining) { return "" }
        if (periodType === "OT") { return "OT " + timeRemaining }
        if (periodType === "SO") { return "SO" }
        if (period === 1) { return "1st " + timeRemaining }
        if (period === 2) { return "2nd " + timeRemaining }
        if (period === 3) { return "3rd " + timeRemaining }
        return ""
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

    readonly property var allTeams: ['ANA','UTA','BOS','BUF','CAR','CBJ','CGY','CHI','COL','DAL','DET','EDM','FLA','LAK','MIN','MTL','NJD','NSH','NYI','NYR','OTT','PHI','PIT','SEA','SJS','STL','TBL','TOR','VAN','VGK','WPG','WSH']

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

    // Génération de rafraîchissement — permet d'ignorer les callbacks obsolètes
    property int refreshGen: 0

    function refresh() {
        refreshGen++
        const myGen = refreshGen

        let days = []
        let base = new Date()
        base.setHours(0, 0, 0, 0)

        // passé
        if (showTwoDaysAgo) {
            days.push(new Date(base.getTime() - 2*24*3600*1000))
        }
        if (showYesterday) {
            days.push(new Date(base.getTime() - 1*24*3600*1000))
        }

        // aujourd'hui
        days.push(new Date(base))

        // futur
        for (let i = 1; i <= lookaheadDays; i++) {
            days.push(new Date(base.getTime() + i*24*3600*1000))
        }

        fetchLeagueByDates(days, function(leagueGames, leagueErrs) {
            if (myGen !== refreshGen) return  // requête obsolète, on abandonne
            if (leagueGames && leagueGames.length) {
                buildFromRawGames(leagueGames, leagueErrs)
            } else {
                const pool = showAllTeams ? allTeams : favoriteTeams
                fetchTeamNow(pool, function(teamGames, teamErrs) {
                    if (myGen !== refreshGen) return
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

    function fetchClock(gameId, modelIndex) {
        let xhr = new XMLHttpRequest()
        xhr.open("GET", "https://api-web.nhle.com/v1/gamecenter/" + gameId + "/play-by-play")
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || xhr.status !== 200) return
            try {
                let data = JSON.parse(xhr.responseText)
                if (data && data.clock) {
                    todayGames.setProperty(modelIndex, "liveRemain", data.clock.timeRemaining || "")
                }
                if (data && data.displayPeriod) {
                    todayGames.setProperty(modelIndex, "period", data.displayPeriod)
                }
            } catch(e) {
                console.warn("fetchClock parse error for game", gameId, e)
            }
        }
        xhr.send()
    }

    function gameCenterUrl(away, home, start, gameId){
        var d = new Date(start)
        var y = d.getFullYear()
        var m = pad2(d.getMonth()+1)
        var da = pad2(d.getDate())
        return 'https://www.nhl.com/gamecenter/' + String(away||'').toLowerCase() + '-vs-' + String(home||'').toLowerCase() + '/' + y + '/' + m + '/' + da + '/' + String(gameId||'')
    }
    function buildFromRawGames(games, errors){
        games = games || []
        const now = new Date()
        let pastDays = 0
        if (showTwoDaysAgo) {
            pastDays = 2
        } else if (showYesterday) {
            pastDays = 1
        }

        const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate() - pastDays)
        const endWin = new Date(now.getFullYear(), now.getMonth(), now.getDate() + lookaheadDays, 23, 59, 59, 999)
        function inWindow(g){ const t = new Date(g.startTimeUTC || now); return t >= startOfToday && t <= endWin }
        let filtered = games.filter(function(g){ return inWindow(g) })

        if (!showAllTeams && favoriteTeams.length){

            filtered = filtered.filter(function(g){

                const h = g.homeTeam && g.homeTeam.abbrev
                const a = g.awayTeam && g.awayTeam.abbrev

                return favoriteTeams.indexOf(h) >= 0 ||
                favoriteTeams.indexOf(a) >= 0
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
                        periodType: g.periodDescriptor?.periodType || "",
                        period: g.periodDescriptor?.number || 0,
                        pbpClock: "",
                        pbpPeriod: 0,
                        clockStartRemain: "",
                        clockStartWall: "",
                        clockRunning: false,
                        rawClock: g.clock || null
            }
        })
        .sort(function(a,b){ return a.start - b.start })

        uniq = uniq.slice(0, maxGames)
        // Sauvegarder les scores précédents avant de vider le modèle
        let snapshot = {}
        for (let si = 0; si < todayGames.count; si++) {
            let sg = todayGames.get(si)
            snapshot[sg.gameId] = { ag: sg.ag, hg: sg.hg, status: sg.statusRole }
        }
        prevScores = snapshot

        todayGames.clear()
        for (let i=0;i<uniq.length;i++) {

            let liveRemain = ""
            let livePeriod = uniq[i].period

            if (uniq[i].statusRole === "LIVE") {

                let g = uniq[i]

                // scoreboard contient déjà le clock
                if (g.rawClock) {
                    liveRemain = g.rawClock.timeRemaining
                }
            }

            todayGames.append({

                gameId: uniq[i].gameId,
                home: uniq[i].home,
                away: uniq[i].away,
                hg: uniq[i].hg,
                ag: uniq[i].ag,
                start: uniq[i].start,
                statusRole: uniq[i].statusRole,
                rawState: uniq[i].rawState,
                periodType: uniq[i].periodType,
                period: livePeriod,
                liveRemain: liveRemain
            })
        }

        // Détecter les nouveaux buts et envoyer les notifications
        if (!initialLoading) {
            for (let ni = 0; ni < todayGames.count; ni++) {
                let ng = todayGames.get(ni)
                let prev = prevScores[ng.gameId]
                if (prev && ng.statusRole === 'LIVE') {
                    if (ng.ag > prev.ag || ng.hg > prev.hg) {
                        sendGoalNotification(ng.away, ng.home, ng.ag, ng.hg, prev.ag, prev.hg)
                    }
                }
            }
        }

        initialLoading = false
        lastUpdated = new Date()
        debugMsg = (errors && errors.length ? errors.join(' | ') : '')
        pollTimer.running = true

        // Récupérer l'horloge play-by-play pour les matchs en direct
        for (let ci = 0; ci < todayGames.count; ci++) {
            if (todayGames.get(ci).statusRole === "LIVE") {
                fetchClock(todayGames.get(ci).gameId, ci)
            }
        }
    }

    Connections {
        target: Plasmoid.configuration
        function onFavoritesChanged(){ root.favoriteTeams = (Plasmoid.configuration.favorites||'').split(/\s*,\s*/).filter(function(s){return s.length>0}); refresh() }
        function onShowAllTeamsChanged(){ refresh() }
        function onMaxGamesChanged(){ refresh() }
        function onLookaheadDaysChanged(){ refresh() }
        function onShowYesterdayChanged(){ refresh() }
        function onShowTwoDaysAgoChanged(){ refresh() }
        function onScoreLayoutChanged(){ root.scoreLayout = Plasmoid.configuration.scoreLayout || 'stack' }
        function onShowUpcomingTimeChanged(){ }
        function onDateModeChanged(){ }
        function onGoalNotificationsChanged(){ root.goalNotificationsEnabled = Plasmoid.configuration.goalNotifications !== false }
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

    function finalWhenText(startMs, statusRole, homeTeam) {
        if (statusRole !== 'FINAL') { return '' }
        if (dateMode === 'venue') { return venueDateStrUTC(startMs, homeTeam) }
        return localDateStr(startMs)
    }

    compactRepresentation: Item {
        id: compactRoot
        readonly property int pad: 6
        ToolTip.visible: compactHover.containsMouse
        ToolTip.text: {
            if (todayGames.count === 0) return i18n("NHL Scores – No games")
            let live = 0, upcoming = 0, ended = 0
            for (let i = 0; i < todayGames.count; i++) {
                let s = todayGames.get(i).statusRole
                if (s === 'LIVE') live++
                else if (s === 'UPCOMING') upcoming++
                else ended++
            }
            let parts = []
            if (live > 0)     parts.push(live + " " + i18n("live"))
            if (upcoming > 0) parts.push(upcoming + " " + i18n("upcoming"))
            if (ended > 0)    parts.push(ended + " " + i18n("final"))
            return i18n("NHL Scores") + " – " + parts.join(", ")
        }
        ToolTip.delay: 800
        HoverHandler { id: compactHover }
        implicitWidth: Math.max(row.implicitWidth + pad, emptyMsg.implicitWidth + pad)
        implicitHeight: Math.max(row.implicitHeight + 2, emptyMsg.implicitHeight + 2)
        Layout.preferredWidth: implicitWidth
        Layout.minimumWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        Layout.minimumHeight: implicitHeight

        Row {
            id: row
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            visible: todayGames.count > 0

            Repeater {
                model: todayGames

                delegate: Row {

                    opacity: statusRole === 'FINAL' ? 0.5 : 1.0
                    visible: index < maxGames

                    spacing: 6

                    Loader {
                        sourceComponent: (scoreLayout==='stack' ? teamColumn : teamRowInline)
                        onLoaded: {
                            if (scoreLayout==='stack') {
                                item.code = away
                                item.score = ag
                            } else {
                                item.awayCode = away
                                item.homeCode = home
                                item.agScore = ag
                                item.hgScore = hg
                            }
                        }
                    }

                    Loader {
                        sourceComponent: (scoreLayout==='stack' ? teamColumn : null)
                        visible: (scoreLayout==='stack')
                        onLoaded: {
                            if (scoreLayout==='stack') {
                                item.code = home
                                item.score = hg
                            }
                        }
                    }

                    Column {
                        spacing: 2

                        Loader {
                            sourceComponent: statusBadge
                            onLoaded: {
                                item.gameStatus = statusRole
                                item.suffix = statusSuffix(rawState, periodType)
                            }
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
                        }
                        Label {

                            visible: statusRole === "LIVE" &&
                            liveRemain !== ""

                            text: liveClockText(
                                periodType,
                                period,
                                liveRemain
                            )

                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: {
                            root.openDetail(gameId, away, home, ag, hg, statusRole, periodType, period, liveRemain, start)
                        }
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
        Label {
            id: emptyMsg
            anchors.centerIn: parent
            visible: todayGames.count === 0
            text: root.initialLoading ? i18n('Loading…') : i18n('No games')
            color: root.initialLoading ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor
            font.italic: root.initialLoading
        }
    }


    // ── État du détail de match (au niveau root) ─────────────────────────
    property int  detailGameId:   0
    property string detailAway:   ''
    property string detailHome:   ''
    property int  detailAg:       0
    property int  detailHg:       0
    property string detailStatus: ''
    property string detailPType:  ''
    property int  detailPeriod:   0
    property string detailRemain: ''
    property var  detailStart:    0
    property var  detailGoals:    []
    property var  detailStats:    ({})
    property bool detailLoading:  false
    property string detailError:  ''
    property bool detailOpen:     false

    function openDetail(gid, away, home, ag, hg, status, ptype, period, remain, start) {
        detailGameId  = gid
        detailAway    = away
        detailHome    = home
        detailAg      = ag
        detailHg      = hg
        detailStatus  = status
        detailPType   = ptype
        detailPeriod  = period
        detailRemain  = remain
        detailStart   = start
        detailGoals   = []
        detailStats   = ({})
        detailError   = ''
        detailOpen    = true
        fetchDetail(gid)
        // Ouvrir le fullRepresentation (popup natif Plasma)
        expanded = true
    }

    function fetchDetail(gid) {
        detailLoading = true
        let done = 0
        function tryDone() { done++; if (done >= 2) detailLoading = false }

        // landing → buts
        let xhrL = new XMLHttpRequest()
        xhrL.open("GET", "https://api-web.nhle.com/v1/gamecenter/" + gid + "/landing")
        xhrL.onreadystatechange = function() {
            if (xhrL.readyState !== XMLHttpRequest.DONE) return
            if (xhrL.status === 200) {
                try {
                    let d = JSON.parse(xhrL.responseText)
                    let g = []
                    let periods = (d.summary && d.summary.scoring) ? d.summary.scoring : []
                    for (let p = 0; p < periods.length; p++) {
                        let ps = periods[p]
                        let pname = ps.periodDescriptor
                            ? (ps.periodDescriptor.periodType === 'OT' ? 'OT'
                               : ps.periodDescriptor.periodType === 'SO' ? 'SO'
                               : ps.periodDescriptor.number + '')
                            : (p+1) + ''
                        let gs = ps.goals || []
                        for (let gi = 0; gi < gs.length; gi++) {
                            let gl = gs[gi]
                            let scorer = gl.firstName
                                ? (gl.firstName.default || '') + ' ' + (gl.lastName.default || '')
                                : (gl.name && gl.name.default ? gl.name.default : '?')
                            let assists = []
                            if (gl.assists) {
                                for (let ai = 0; ai < gl.assists.length; ai++) {
                                    let a = gl.assists[ai]
                                    assists.push(a.firstName
                                        ? (a.firstName.default || '') + ' ' + (a.lastName.default || '')
                                        : (a.name && a.name.default ? a.name.default : '?'))
                                }
                            }
                            g.push({
                                period:  pname,
                                time:    gl.timeInPeriod || '',
                                team:    gl.teamAbbrev ? (gl.teamAbbrev.default || gl.teamAbbrev) : '',
                                scorer:  scorer,
                                assists: assists,
                                ppg:     gl.strength === 'pp',
                                shg:     gl.strength === 'sh',
                                en:      gl.goalModifier === 'empty-net' || gl.emptyNet === true
                            })
                        }
                    }
                    detailGoals = g
                } catch(e) { detailError = 'landing: ' + e }
            } else {
                detailError = 'HTTP ' + xhrL.status + ' (landing)'
            }
            tryDone()
        }
        xhrL.send()

        // boxscore → stats d'équipe
        let xhrB = new XMLHttpRequest()
        xhrB.open("GET", "https://api-web.nhle.com/v1/gamecenter/" + gid + "/boxscore")
        xhrB.onreadystatechange = function() {
            if (xhrB.readyState !== XMLHttpRequest.DONE) return
            if (xhrB.status === 200) {
                try {
                    let d = JSON.parse(xhrB.responseText)
                    let st = {}
                    // Tirs au but : directement dans awayTeam/homeTeam
                    let awSog = d.awayTeam && d.awayTeam.sog !== undefined ? d.awayTeam.sog : null
                    let hmSog = d.homeTeam && d.homeTeam.sog !== undefined ? d.homeTeam.sog : null
                    if (awSog !== null && hmSog !== null) {
                        st['sog'] = { away: awSog, home: hmSog }
                    }
                    // Autres stats dans teamGameStats
                    let ts = d.teamGameStats || []
                    for (let i = 0; i < ts.length; i++) {
                        let row = ts[i]
                        let av = row.awayValue !== undefined ? row.awayValue : '—'
                        let hv = row.homeValue !== undefined ? row.homeValue : '—'
                        st[row.category || ''] = { away: av, home: hv }
                    }
                    detailStats = st
                } catch(e) { detailError = 'boxscore: ' + e }
            } else {
                if (!detailError) detailError = 'HTTP ' + xhrB.status + ' (boxscore)'
            }
            tryDone()
        }
        xhrB.send()
    }

    // Timer rafraîchissement automatique du popup détail
    Timer {
        id: detailRefreshTimer
        interval: 30000
        running: root.detailOpen && root.detailStatus === 'LIVE'
        repeat: true
        onTriggered: {
            if (root.detailOpen) {
                // Mettre à jour le score depuis le modèle si le match est toujours là
                for (let i = 0; i < todayGames.count; i++) {
                    let g = todayGames.get(i)
                    if (g.gameId === root.detailGameId) {
                        root.detailAg      = g.ag
                        root.detailHg      = g.hg
                        root.detailPeriod  = g.period
                        root.detailRemain  = g.liveRemain
                        root.detailStatus  = g.statusRole
                        root.detailPType   = g.periodType
                        break
                    }
                }
                // Recharger les buts et stats
                fetchDetail(root.detailGameId)
            }
        }
    }

    // ── fullRepresentation : popup natif Plasma, bien positionné ─────────
    fullRepresentation: Item {
        implicitWidth:  440
        implicitHeight: 520

        // Vue liste des matchs
        ScrollView {
            anchors.fill: parent
            visible: !root.detailOpen

            ColumnLayout {
                width: parent.width
                spacing: 8

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: contentHeight
                    model: todayGames
                    interactive: false

                    delegate: ItemDelegate {
                        opacity: statusRole === 'FINAL' ? 0.55 : 1.0
                        width: ListView.view.width
                        contentItem: Item {
                            implicitHeight: delegateRow.implicitHeight + 8

                            // Rangée centrée horizontalement
                            RowLayout {
                                id: delegateRow
                                anchors.centerIn: parent
                                spacing: 10

                                // Équipe visiteur
                                Loader {
                                    sourceComponent: (scoreLayout==='stack' ? teamColumn : teamRowInline)
                                    onLoaded: {
                                        if (scoreLayout==='stack') { item.code = away; item.score = ag }
                                        else { item.awayCode = away; item.homeCode = home; item.agScore = ag; item.hgScore = hg }
                                    }
                                }

                                // Équipe locale (mode stack seulement)
                                Loader {
                                    sourceComponent: (scoreLayout==='stack' ? teamColumn : null)
                                    visible: (scoreLayout==='stack')
                                    onLoaded: { if (scoreLayout==='stack') { item.code = home; item.score = hg } }
                                }

                                // Pastille statut + chrono + heure
                                Column {
                                    spacing: 2

                                    // Pastille inline avec binding direct
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        radius: 5
                                        color: statusColor(statusRole)
                                        opacity: 0.95
                                        width: listBadgeText.implicitWidth + 6
                                        height: listBadgeText.implicitHeight + 2
                                        Text {
                                            id: listBadgeText
                                            anchors.centerIn: parent
                                            text: statusText(statusRole) + statusSuffix(rawState, periodType)
                                            color: 'white'; font.pixelSize: 10; font.bold: true
                                        }
                                    }

                                    // Chronomètre LIVE
                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        visible: statusRole === 'LIVE' && liveRemain !== ''
                                        text: liveClockText(periodType, period, liveRemain)
                                        color: Kirigami.Theme.disabledTextColor
                                        font.pixelSize: 10
                                    }

                                    // Heure (upcoming) ou date (final)
                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        visible: (statusRole === 'UPCOMING' && showUpcomingTime) || statusRole === 'FINAL'
                                        text: statusRole === 'FINAL'
                                            ? finalWhenText(start, statusRole, home)
                                            : upcomingWhenText(start, statusRole, home)
                                        color: Kirigami.Theme.disabledTextColor
                                        font.pixelSize: 10
                                    }
                                }

                                // Flèche indicatrice
                                Label {
                                    text: '›'
                                    font.pixelSize: 18
                                    color: Kirigami.Theme.disabledTextColor
                                }
                            }
                        }
                        onClicked: root.openDetail(gameId, away, home, ag, hg, statusRole, periodType, period, liveRemain, start)
                    }

                    footer: Label {
                        text: lastUpdated
                            ? i18n('Updated: %1', Qt.formatTime(lastUpdated, 'hh:mm'))
                              + (debugMsg ? '  ⚠  ' + debugMsg : '')
                            : ''
                        opacity: 0.45
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                        width: ListView.view.width
                        topPadding: 4; bottomPadding: 6
                    }
                }
            }
        }

        // Vue détail d'un match
        ScrollView {
            id: detailScrollView
            anchors.fill: parent
            visible: root.detailOpen
            contentWidth: availableWidth

            Item {
                width: detailScrollView.availableWidth
                implicitHeight: detailColumn.implicitHeight

                ColumnLayout {
                    id: detailColumn
                    width: Math.min(320, detailScrollView.availableWidth - 32)
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                // ── Barre de retour ──────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4

                    Button {
                        text: i18n('‹ Back')
                        icon.name: 'go-previous'
                        flat: true
                        onClicked: root.detailOpen = false
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: i18n('NHL.com')
                        icon.name: 'internet-web-browser'
                        flat: true
                        onClicked: Qt.openUrlExternally(
                            gameCenterUrl(root.detailAway, root.detailHome, root.detailStart, root.detailGameId)
                        )
                    }
                }

                // ── En-tête score ────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    // Visiteur
                    Column {
                        spacing: 4
                        Layout.alignment: Qt.AlignVCenter
                        Rectangle {
                            radius: 5; width: awLbl.implicitWidth + 14; height: awLbl.implicitHeight + 8
                            color: teamColor(root.detailAway)
                            border.color: 'white'; border.width: 1
                            Label { id: awLbl; anchors.centerIn: parent; text: root.detailAway; color: 'white'; font.bold: true; font.pixelSize: 15 }
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: String(root.detailAg)
                            font.pixelSize: 32; font.bold: true
                            color: Kirigami.Theme.textColor
                        }
                    }

                    // Centre
                    Column {
                        spacing: 4
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        // Pastille statut inline avec binding direct (pas de Loader/onLoaded)
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            radius: 5
                            color: statusColor(root.detailStatus)
                            opacity: 0.95
                            width: badgeDetailText.implicitWidth + 6
                            height: badgeDetailText.implicitHeight + 2
                            Text {
                                id: badgeDetailText
                                anchors.centerIn: parent
                                text: statusText(root.detailStatus) + statusSuffix('', root.detailPType)
                                color: 'white'
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.detailStatus === 'LIVE' && root.detailRemain !== ''
                            text: liveClockText(root.detailPType, root.detailPeriod, root.detailRemain)
                            color: Kirigami.Theme.disabledTextColor; font.pixelSize: 12
                        }
                    }

                    // Local
                    Column {
                        spacing: 4
                        Layout.alignment: Qt.AlignVCenter
                        Rectangle {
                            radius: 5; width: hmLbl.implicitWidth + 14; height: hmLbl.implicitHeight + 8
                            color: teamColor(root.detailHome)
                            border.color: 'white'; border.width: 1
                            Label { id: hmLbl; anchors.centerIn: parent; text: root.detailHome; color: 'white'; font.bold: true; font.pixelSize: 15 }
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: String(root.detailHg)
                            font.pixelSize: 32; font.bold: true
                            color: Kirigami.Theme.textColor
                        }
                    }
                }

                // Chargement / erreur
                Label {
                    visible: root.detailLoading
                    text: i18n('Loading…')
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                }
                Label {
                    visible: !root.detailLoading && root.detailError !== ''
                    text: root.detailError
                    color: 'tomato'; font.pixelSize: 11
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                // ── Tirs au but (mise en évidence) ───────────────────────
                RowLayout {
                    visible: !root.detailLoading && root.detailStats['sog'] !== undefined
                    Layout.fillWidth: true
                    spacing: 0
                    Label {
                        text: root.detailStats['sog'] ? String(root.detailStats['sog'].away) : ''
                        font.pixelSize: 20; font.bold: true
                        color: teamColor(root.detailAway)
                        Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter
                    }
                    Label {
                        text: i18n('Shots on Goal')
                        font.pixelSize: 11
                        color: Kirigami.Theme.disabledTextColor
                        Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                    }
                    Label {
                        text: root.detailStats['sog'] ? String(root.detailStats['sog'].home) : ''
                        font.pixelSize: 20; font.bold: true
                        color: teamColor(root.detailHome)
                        Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter
                    }
                }

                // ── Séparateur ───────────────────────────────────────────
                Rectangle {
                    visible: !root.detailLoading && Object.keys(root.detailStats).length > 0
                    Layout.fillWidth: true; height: 1
                    color: Kirigami.Theme.separatorColor
                }

                // ── Stats d'équipe (sans SOG, déjà affiché ci-dessus) ─────
                ColumnLayout {
                    visible: !root.detailLoading && Object.keys(root.detailStats).length > 0
                    Layout.fillWidth: true
                    spacing: 2

                    // En-têtes colonnes
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: root.detailAway; font.bold: true; font.pixelSize: 12; color: teamColor(root.detailAway); Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter }
                        Label { text: ''; Layout.fillWidth: true }
                        Label { text: root.detailHome; font.bold: true; font.pixelSize: 12; color: teamColor(root.detailHome); Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter }
                    }

                    Repeater {
                        model: {
                            let order = ['faceoffWinningPctg','powerPlay','hits','blockedShots','giveaways','takeaways','pim']
                            let labels = {
                                'sog':                 i18n('Shots'),
                                'faceoffWinningPctg':   i18n('Faceoffs %'),
                                'powerPlay':            i18n('Power Play'),
                                'hits':                 i18n('Hits'),
                                'blockedShots':         i18n('Blocks'),
                                'giveaways':            i18n('Giveaways'),
                                'takeaways':            i18n('Takeaways'),
                                'pim':                  i18n('PIM')
                            }
                            let rows = []
                            for (let i = 0; i < order.length; i++) {
                                let k = order[i]
                                let entry = root.detailStats[k]
                                if (entry === undefined) continue
                                let av = entry.away
                                let hv = entry.home
                                if (k === 'powerPlay' && av !== null && typeof av === 'object') {
                                    let ho = entry.home
                                    av = (av.goals||0) + '/' + (av.opportunities||0)
                                    hv = (ho.goals||0) + '/' + (ho.opportunities||0)
                                }
                                if (k === 'faceoffWinningPctg') {
                                    av = typeof av === 'number' ? av.toFixed(1) + '%' : String(av)
                                    hv = typeof hv === 'number' ? hv.toFixed(1) + '%' : String(hv)
                                }
                                rows.push({ label: labels[k] || k, away: String(av), home: String(hv) })
                            }
                            return rows
                        }
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Label { text: modelData.away; font.pixelSize: 12; font.bold: true; color: Kirigami.Theme.textColor; Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter }
                            Label { text: modelData.label; font.pixelSize: 11; color: Kirigami.Theme.disabledTextColor; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                            Label { text: modelData.home; font.pixelSize: 12; font.bold: true; color: Kirigami.Theme.textColor; Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter }
                        }
                    }
                }

                // ── Buts ─────────────────────────────────────────────────
                Rectangle {
                    visible: !root.detailLoading
                    Layout.fillWidth: true; height: 1
                    color: Kirigami.Theme.separatorColor
                }

                Label {
                    visible: !root.detailLoading
                    text: i18n('Goals')
                    font.bold: true; font.pixelSize: 12
                    color: Kirigami.Theme.textColor
                    Layout.alignment: Qt.AlignHCenter
                }

                Repeater {
                    model: root.detailGoals
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            radius: 3
                            width: tBadge.implicitWidth + 8; height: tBadge.implicitHeight + 4
                            color: teamColor(modelData.team)
                            Label { id: tBadge; anchors.centerIn: parent; text: modelData.team; color: 'white'; font.pixelSize: 10; font.bold: true }
                        }
                        Label {
                            text: 'P' + modelData.period + ' ' + modelData.time
                            font.pixelSize: 10; color: Kirigami.Theme.disabledTextColor
                            Layout.preferredWidth: 62
                        }
                        Column {
                            spacing: 1
                            Layout.fillWidth: true
                            Label {
                                text: modelData.scorer
                                    + (modelData.ppg ? '  🔵 PP' : '')
                                    + (modelData.shg ? '  🔴 SH' : '')
                                    + (modelData.en  ? '  🥅 EN' : '')
                                font.pixelSize: 12; font.bold: true
                                color: Kirigami.Theme.textColor; wrapMode: Text.Wrap
                            }
                            Label {
                                visible: modelData.assists.length > 0
                                text: i18n('Assists: ') + modelData.assists.join(', ')
                                font.pixelSize: 10; color: Kirigami.Theme.disabledTextColor
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }

                Label {
                    visible: !root.detailLoading && root.detailGoals.length === 0 && root.detailStatus === 'UPCOMING'
                    text: i18n('Game not started yet.')
                    color: Kirigami.Theme.disabledTextColor; font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
                Label {
                    visible: !root.detailLoading && root.detailGoals.length === 0
                        && root.detailStatus !== 'UPCOMING' && root.detailError === ''
                    text: i18n('No goals recorded.')
                    color: Kirigami.Theme.disabledTextColor; font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Item { height: 8 }
                } // ColumnLayout
            } // Item wrapper
        }
    }

}
