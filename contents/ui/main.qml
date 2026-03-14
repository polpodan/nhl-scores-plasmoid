
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root
    Plasmoid.title: i18n("NHL Scores")

    // Détection panneau vertical (largeur contrainte, hauteur libre)
    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    // Détection mode desktop : formFactor Planar (0) = posé sur le bureau
    readonly property bool isDesktop: Plasmoid.formFactor === PlasmaCore.Types.Planar
    // En mode desktop, on affiche directement le fullRepresentation
    preferredRepresentation: isDesktop ? fullRepresentation : compactRepresentation
    property var favoriteTeams: []
    property bool showAllTeams: Plasmoid.configuration.showAllTeams || false
    property int  maxGames:     Plasmoid.configuration.maxGames || 10
    property bool ultraCompact: Plasmoid.configuration.ultraCompact || false
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

    // Action contextuelle (menu clic-droit)
    function action_refreshNow() { refresh() }

    Component.onCompleted: {
        try {
            Plasmoid.setAction("refreshNow", i18n("Refresh now"), "view-refresh")
        } catch(e) {
            // setAction non disponible sur cette version de Plasma — ignoré
        }
        updateFavoriteTeams()
        refresh()
    }

    ListModel {
        id: todayGames
    }

    // Tooltip natif Plasma — après todayGames pour éviter référence prématurée
    toolTipMainText: i18n("NHL Scores")
    readonly property string _tooltipSub: {
        if (todayGames.count === 0) return i18n("No games")
        var lines = []
        for (var i = 0; i < todayGames.count; i++) {
            var g = todayGames.get(i)
            var st = g.statusRole
            if (st === 'DATE_SEP') continue
            if (st === 'LIVE') {
                // Ex : "MTL 3 – 2 TOR  |  2e période 14:32"
                var clock = badgeLine1(st, g.rawState, g.periodType, g.period,
                                       g.liveRemain, g.start, g.home, g.inIntermission)
                lines.push(g.away + "  " + g.ag + " – " + g.hg + "  " + g.home
                           + "   ·  " + clock)
            } else if (st === 'UPCOMING') {
                // Ex : "MTL – TOR  à 19:00"
                var when = upcomingWhenText(g.start, st, g.home)
                lines.push(g.away + "  –  " + g.home
                           + (when !== '' ? "   ·  " + when : ""))
            } else {
                // FINAL — Ex : "MTL 3 – 2 TOR  |  Final"
                lines.push(g.away + "  " + g.ag + " – " + g.hg + "  " + g.home
                           + "   ·  " + i18n("Final"))
            }
        }
        return lines.join("
")
    }
    toolTipSubText: _tooltipSub

    property date lastUpdated
    property string debugMsg: ""
    property bool initialLoading:   true
    property bool standingsOpen:    false
    property var  standingsData:    []
    property bool standingsLoading: false
    property string standingsError: ""

    function fetchStandings() {
        if (standingsLoading) return
        standingsLoading = true
        standingsError   = ""
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "https://api-web.nhle.com/v1/standings/now")
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== 4) return
            standingsLoading = false
            if (xhr.status === 200) {
                try {
                    var d = JSON.parse(xhr.responseText)
                    standingsData = d.standings || []
                } catch(e) { standingsError = "Parse error" }
            } else { standingsError = "HTTP " + xhr.status }
        }
        xhr.send()
    }

    // ── Clignotement de score sur but ────────────────────────────────────
    // Snapshot des scores avant chaque refresh : { gameId -> { ag, hg } }
    property var prevScores: ({})
    // Heure de début d'intermission par gameId : { gameId: wallClockMs }

    // Durée de clignotement en secondes (config)
    property int blinkDuration: Plasmoid.configuration.blinkDuration || 10

    // Dictionnaire des matchs en cours de clignotement : { gameId: true }
    property var blinkingGames: ({})

    // État ON/OFF du clignotement (bascule à 500ms)
    property bool blinkOn: false

    // Timer de bascule visuelle
    Timer {
        id: blinkToggleTimer
        interval: 500
        repeat: true
        running: Object.keys(root.blinkingGames).length > 0
        onTriggered: root.blinkOn = !root.blinkOn
    }

    // Démarre le clignotement pour un match pendant blinkDuration secondes
    function startBlink(gameId, scorer) {
        let b = Object.assign({}, blinkingGames)
        // scorer : 'away', 'home', ou 'both' — pour flasher la bonne pastille
        b[gameId] = scorer || 'both'
        blinkingGames = b

        // Timer one-shot pour arrêter ce match
        let stop = stopBlinkTimerComp.createObject(root, { targetGameId: String(gameId) })
        stop.start()
    }

    Component {
        id: stopBlinkTimerComp
        Timer {
            property string targetGameId: ""
            interval: root.blinkDuration * 1000
            repeat: false
            onTriggered: {
                let b = Object.assign({}, root.blinkingGames)
                delete b[targetGameId]
                root.blinkingGames = b
                destroy()
            }
        }
    }

    function triggerGoalBlink(away, home, ag, hg, prevAg, prevHg, gameId) {
        if (ag > prevAg || hg > prevHg) {
            let scorer = (ag > prevAg && hg > prevHg) ? 'both'
                       : (ag > prevAg) ? 'away' : 'home'
            startBlink(gameId, scorer)
        }
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
        interval: hasActiveGames() ? 20000 : 300000  // 20s si actif, 5min sinon
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
    readonly property var teamSecondaryColors: ({
        'ANA':'#B9975B','UTA':'#FFFFFF','BOS':'#000000','BUF':'#FCB514',
        'CAR':'#000000','CBJ':'#CE1126','CGY':'#F1BE48','CHI':'#000000',
        'COL':'#236192','DAL':'#EAAA00','DET':'#FFFFFF','EDM':'#003DA5',
        'FLA':'#B9975B','LAK':'#A2AAAD','MIN':'#EAAA00','MTL':'#003DA5',
        'NJD':'#000000','NSH':'#041E42','NYI':'#F47D30','NYR':'#CE1126',
        'OTT':'#000000','PHI':'#000000','PIT':'#000000','SEA':'#001628',
        'SJS':'#EA7200','STL':'#FCB514','TBL':'#FFFFFF','TOR':'#FFFFFF',
        'VAN':'#008852','VGK':'#333F42','WPG':'#AC162C','WSH':'#041E42'
    })

    readonly property var teamColors: ({ 'ANA':'#F47A38','UTA':'#6E2B62','BOS':'#FFB81C','BUF':'#003087','CAR':'#CC0000','CBJ':'#002654','CGY':'#C8102E','CHI':'#CF0A2C','COL':'#6F263D','DAL':'#006847','DET':'#CE1126','EDM':'#FF4C00','FLA':'#C8102E','LAK':'#111111','MIN':'#154734','MTL':'#AF1E2D','NJD':'#CE1126','NSH':'#FFB81C','NYI':'#00539B','NYR':'#0038A8','OTT':'#C52032','PHI':'#F74902','PIT':'#FFB81C','SEA':'#99D9D9','SJS':'#006D75','STL':'#002F87','TBL':'#002868','TOR':'#00205B','VAN':'#00205B','VGK':'#B4975A','WPG':'#041E42','WSH':'#C8102E' })

    function teamColor(code) {
        var c = teamColors[String(code||'').toUpperCase()]
        return c ? c : Kirigami.Theme.positiveBackgroundColor
    }

    // Retourne une version de la couleur d'équipe lisible sur le fond du thème.
    // Sur thème foncé  : les couleurs trop sombres sont éclaircies.
    // Sur thème clair  : les couleurs trop claires sont assombries.
    function teamColorAdapted(code) {
        var hex = teamColors[String(code||'').toUpperCase()]
        if (!hex) return Kirigami.Theme.textColor

        // Luminance de la couleur d'équipe
        var h = hex.replace('#','')
        var r = parseInt(h.substring(0,2),16)/255
        var g = parseInt(h.substring(2,4),16)/255
        var b = parseInt(h.substring(4,6),16)/255
        var rl = r<=0.03928?r/12.92:Math.pow((r+0.055)/1.055,2.4)
        var gl = g<=0.03928?g/12.92:Math.pow((g+0.055)/1.055,2.4)
        var bl = b<=0.03928?b/12.92:Math.pow((b+0.055)/1.055,2.4)
        var L = 0.2126*rl + 0.7152*gl + 0.0722*bl

        // Luminance du fond du thème
        var bg = Kirigami.Theme.backgroundColor
        var br = bg.r <= 0.03928 ? bg.r/12.92 : Math.pow((bg.r+0.055)/1.055,2.4)
        var bgg = bg.g <= 0.03928 ? bg.g/12.92 : Math.pow((bg.g+0.055)/1.055,2.4)
        var bb = bg.b <= 0.03928 ? bg.b/12.92 : Math.pow((bg.b+0.055)/1.055,2.4)
        var Lbg = 0.2126*br + 0.7152*bgg + 0.0722*bb

        // Ratio de contraste minimum acceptable : 2.5
        var contrast = (Math.max(L, Lbg) + 0.05) / (Math.min(L, Lbg) + 0.05)
        if (contrast >= 2.5) return hex  // déjà assez contrasté, on garde

        // Thème foncé : éclaircir la couleur d'équipe
        if (Lbg < 0.25) {
            // Mélange avec blanc jusqu'à obtenir assez de contraste
            var ri = parseInt(h.substring(0,2),16)
            var gi = parseInt(h.substring(2,4),16)
            var bi2 = parseInt(h.substring(4,6),16)
            var t = 0.55  // facteur d'éclaircissement
            ri = Math.round(ri + (255 - ri) * t)
            gi = Math.round(gi + (255 - gi) * t)
            bi2 = Math.round(bi2 + (255 - bi2) * t)
            return '#' + ('0'+ri.toString(16)).slice(-2)
                       + ('0'+gi.toString(16)).slice(-2)
                       + ('0'+bi2.toString(16)).slice(-2)
        }

        // Thème clair : assombrir la couleur d'équipe
        var ri2 = Math.round(parseInt(h.substring(0,2),16) * 0.55)
        var gi2 = Math.round(parseInt(h.substring(2,4),16) * 0.55)
        var bi3 = Math.round(parseInt(h.substring(4,6),16) * 0.55)
        return '#' + ('0'+ri2.toString(16)).slice(-2)
                   + ('0'+gi2.toString(16)).slice(-2)
                   + ('0'+bi3.toString(16)).slice(-2)
    }

    // Retourne 'white' ou 'black' selon la luminance de la couleur d'équipe
    // Formule WCAG relative luminance : L = 0.2126R + 0.7152G + 0.0722B
    function blinkOpacity(gameId, side) {
        var b = root.blinkingGames[String(gameId)]
        return (b && (b === side || b === 'both') && !root.blinkOn) ? 0.0 : 1.0
    }

    // Retourne les deux couleurs optimales pour le dégradé away→home
    function bestGradientColors(away, home) {
        var ap = teamColors[away]  || '#888888'
        var hp = teamColors[home]  || '#888888'
        var as = teamSecondaryColors[away]  || ap
        var hs = teamSecondaryColors[home]  || hp
        // Distance euclidienne RGB
        function dist(c1, c2) {
            function hex(h, i) { return parseInt(h.slice(1+i*2, 3+i*2), 16) }
            var dr = hex(c1,0)-hex(c2,0), dg = hex(c1,1)-hex(c2,1), db = hex(c1,2)-hex(c2,2)
            return Math.sqrt(dr*dr + dg*dg + db*db)
        }
        // Tester les 4 combinaisons, garder la plus distante
        var combos = [
            { ac: ap, hc: hp, d: dist(ap, hp) },
            { ac: as, hc: hp, d: dist(as, hp) },
            { ac: ap, hc: hs, d: dist(ap, hs) },
            { ac: as, hc: hs, d: dist(as, hs) },
        ]
        var best = combos[0]
        for (var i = 1; i < combos.length; i++)
            if (combos[i].d > best.d) best = combos[i]
        return best
    }

    function teamTextColor(code) {
        var hex = teamColors[String(code||'').toUpperCase()]
        if (!hex) return 'white'
        hex = hex.replace('#', '')
        var r = parseInt(hex.substring(0,2), 16) / 255
        var g = parseInt(hex.substring(2,4), 16) / 255
        var b = parseInt(hex.substring(4,6), 16) / 255
        // Correction gamma sRGB
        r = r <= 0.03928 ? r / 12.92 : Math.pow((r + 0.055) / 1.055, 2.4)
        g = g <= 0.03928 ? g / 12.92 : Math.pow((g + 0.055) / 1.055, 2.4)
        b = b <= 0.03928 ? b / 12.92 : Math.pow((b + 0.055) / 1.055, 2.4)
        var L = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return L > 0.35 ? '#111111' : 'white'
    }
    function pad2(n) { return (n < 10 ? "0" : "") + n }
    function dateISO(d) { return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate()) }

    function isSameDay(a, b) { return a.getFullYear()===b.getFullYear() && a.getMonth()===b.getMonth() && a.getDate()===b.getDate() }
    function localTimeStr(ms) { var d = new Date(ms); return Qt.formatTime(d, Qt.DefaultLocaleShortDate) }
    function localDateStr(ms) { return Qt.formatDate(new Date(ms), "dd'/'MM") }
    function localeDateLong(ms) {
        var d = new Date(ms)
        var days   = [i18n('Sunday'),i18n('Monday'),i18n('Tuesday'),i18n('Wednesday'),
                      i18n('Thursday'),i18n('Friday'),i18n('Saturday')]
        var months = [i18n('January'),i18n('February'),i18n('March'),i18n('April'),
                      i18n('May'),i18n('June'),i18n('July'),i18n('August'),
                      i18n('September'),i18n('October'),i18n('November'),i18n('December')]
        return days[d.getDay()] + ' ' + d.getDate() + ' ' + months[d.getMonth()]
    }
    // ── Avantage numérique ──────────────────────────────────────────────
    // situationCode : 4 chiffres  [awayGoalie][awaySkaters][homeSkaters][homeGoalie]
    // ex: 1451 = away 4 skaters, home 5 skaters → home PP
    //     1441 = away 4, home 4  → double pénalité (égal)
    //     1351 = away 3, home 5  → home double avantage
    function parseSituation(code, away, home) {
        if (!code || code.length < 4) return null
        var ag = parseInt(code[0])   // goalie visiteur (0=vide, 1=en jeu)
        var as = parseInt(code[1])   // patineurs visiteur
        var hs = parseInt(code[2])   // patineurs local
        var hg = parseInt(code[3])   // goalie local
        var enTeam = ag === 0 ? away : (hg === 0 ? home : '')  // équipe au filet vide
        // Données invalides (début de période / intermission — joueurs pas encore sur la glace)
        if (as === 0 && hs === 0) return null
        // 5v5 normal sans filet vide → rien à afficher
        if (as === 5 && hs === 5 && enTeam === '') return null
        // Filet vide sans AN (ex: 0651 = 6v5 égal après retrait gardien)
        if (as === hs) {
            return { ppTeam: '', shTeam: '', ppType: as + 'v' + hs,
                     awaySkaters: as, homeSkaters: hs,
                     emptyNet: enTeam !== '', enTeam: enTeam, even: true }
        }
        // Avantage numérique
        var ppTeam  = as > hs ? away : home
        var shTeam  = as > hs ? home : away
        var ppCount = Math.abs(as - hs)
        var ppType  = ppCount === 1 ? 'PP' : '5v3'
        var emptyNet = enTeam !== ''
        return { ppTeam: ppTeam, shTeam: shTeam, ppType: ppType,
                 awaySkaters: as, homeSkaters: hs,
                 emptyNet: emptyNet, enTeam: enTeam, even: false }
    }

    property string detailSituationCode: '1551'

    // URL du logo NHL selon thème clair/foncé
    function teamLogoUrl(abbrev) {
        if (!abbrev) return ''
        var bg = Kirigami.Theme.backgroundColor
        var L  = 0.2126*bg.r + 0.7152*bg.g + 0.0722*bg.b
        var variant = L < 0.5 ? 'dark' : 'light'
        return 'https://assets.nhle.com/logos/nhl/svg/' + abbrev + '_' + variant + '.svg'
    }

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


    function statusSuffix(rawState, periodType){
        if (!showOvertimeSuffix) return ''
        var s = (rawState || '').toUpperCase()
        var pd = (periodType || '').toUpperCase()
        if (s.indexOf('OT') >= 0 || pd === 'OT') return ' OT'
        if (s.indexOf('SO') >= 0 || pd === 'SO') return ' SO'
        return ''
    }

    function statusColor(st){ return st==='LIVE' ? liveColor : (st==='FINAL' ? finalColor : upcomingColor) }

    // Ligne 1 de la pastille : statut / chrono / heure
    function badgeLine1(st, rawState, periodType, period, liveRemain, startMs, homeTeam, intermission) {
        var suffix = statusSuffix(rawState, periodType)
        if (st === 'LIVE') {
            if (intermission) return 'INT'
            var clock = liveClockText(periodType, period, liveRemain)
            return clock !== '' ? clock + suffix : 'LIVE' + suffix
        }
        if (st === 'FINAL') {
            return i18n('Final') + suffix
        }
        // UPCOMING : heure ou label
        var t = upcomingWhenText(startMs, st, homeTeam)
        return t !== '' ? t : i18n('Upcoming')
    }

    // Ligne 2 de la pastille : date pour FINAL uniquement ('' sinon)
    function badgeLine2(st, startMs, homeTeam) {
        if (st !== 'FINAL') return ''
        return finalWhenText(startMs, st, homeTeam)
    }

    function fetchClock(gameId, modelIndex) {
        let xhr = new XMLHttpRequest()
        xhr.open("GET", "https://api-web.nhle.com/v1/gamecenter/" + gameId + "/play-by-play")
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || xhr.status !== 200) return
            try {
                let data = JSON.parse(xhr.responseText)
                if (data && data.clock) {
                    todayGames.setProperty(modelIndex, "liveRemain", data.clock.timeRemaining || "")
                    todayGames.setProperty(modelIndex, "inIntermission", data.clock.inIntermission ? true : false)
                    // Pendant l'intermission, timeRemaining = temps avant la prochaine mise en jeu
                    if (data.clock.inIntermission)
                        todayGames.setProperty(modelIndex, "intermissionRemain", data.clock.timeRemaining || "")
                    else
                        todayGames.setProperty(modelIndex, "intermissionRemain", "")
                    if (data.situationCode) {
                        todayGames.setProperty(modelIndex, "situationCode", data.situationCode)
                        // Mise à jour immédiate du popup si ce match est ouvert
                        if (root.detailOpen && root.detailGameId === todayGames.get(modelIndex).gameId) {
                            root.detailSituationCode = data.situationCode
                            root.detailIntermRemain  = data.clock.inIntermission
                                                       ? (data.clock.timeRemaining || '')
                                                       : ''
                        }
                    }
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


    // Calcule situationCode depuis summary.iceSurface du landing
    // Format : [awayGoalie][awaySkaters][homeSkaters][homeGoalie]
    function fetchSituationFromLanding(gameId) {
        let xhr = new XMLHttpRequest()
        xhr.open("GET", "https://api-web.nhle.com/v1/gamecenter/" + gameId + "/landing")
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || xhr.status !== 200) return
            try {
                let data = JSON.parse(xhr.responseText)
                let ice = data.summary && data.summary.iceSurface
                if (!ice) return
                let at = ice.awayTeam || {}
                let ht = ice.homeTeam || {}
                let ag = (at.goalies && at.goalies.length > 0) ? 1 : 0
                let as = (at.forwards ? at.forwards.length : 0)
                       + (at.defensemen ? at.defensemen.length : 0)
                let hs = (ht.forwards ? ht.forwards.length : 0)
                       + (ht.defensemen ? ht.defensemen.length : 0)
                let hg = (ht.goalies && ht.goalies.length > 0) ? 1 : 0
                // Seulement si situation spéciale (pas 5v5 normal ni données vides)
                if ((as === 5 && hs === 5 && ag === 1 && hg === 1)
                    || (as === 0 && hs === 0)) {
                    // Situation normale — reset
                    var pm0 = root.penaltiesMap
                    pm0[String(gameId)] = { away: [], home: [] }
                    root.penaltiesMap = pm0
                    for (let j = 0; j < todayGames.count; j++) {
                        if (todayGames.get(j).gameId == gameId) {
                            todayGames.setProperty(j, "situationCode", "1551")
                            if (root.detailOpen && root.detailGameId == gameId) {
                                root.detailSituationCode = "1551"
                                root.detailPenaltyBoxAway = "[]"
                                root.detailPenaltyBoxHome = "[]"
                            }
                            break
                        }
                    }
                    return
                }
                let code = String(ag) + String(as) + String(hs) + String(hg)
                let pba = at.penaltyBox || []
                let pbh = ht.penaltyBox || []
                // Stocker dans penaltiesMap (évite String vs List dans ListModel)
                var pm = root.penaltiesMap
                pm[String(gameId)] = { away: pba, home: pbh }
                root.penaltiesMap = pm
                for (let j = 0; j < todayGames.count; j++) {
                    if (todayGames.get(j).gameId == gameId) {
                        todayGames.setProperty(j, "situationCode", code)
                        if (root.detailOpen && root.detailGameId == gameId) {
                            root.detailSituationCode = code
                            var entry = root.penaltiesMap[String(gameId)] || {away:[],home:[]}
                            root.detailPenaltyBoxAway = JSON.stringify(entry.away)
                            root.detailPenaltyBoxHome = JSON.stringify(entry.home)
                        }
                        break
                    }
                }
            } catch(e) { console.warn("landing error:", e) }
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
                        rawClock: g.clock || null,
                        inIntermission: (g.clock && g.clock.inIntermission) ? true : false,
                        situationCode: g.situationCode || '1551'
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
        let lastDateKey = ''
        let gameIdx = 0
        let todayKey = dateISO(new Date())
        for (let i=0;i<uniq.length;i++) {

            let liveRemain = ""
            let livePeriod = uniq[i].period

            if (uniq[i].statusRole === "LIVE") {
                let g = uniq[i]
                if (g.rawClock) liveRemain = g.rawClock.timeRemaining
            }

            // Insérer séparateur de date pour les UPCOMING d'un nouveau jour
            let gameDate = uniq[i].start ? dateISO(new Date(uniq[i].start)) : todayKey
            if (uniq[i].statusRole === 'UPCOMING' && gameDate !== lastDateKey) {
                lastDateKey = gameDate
                todayGames.append({
                    gameId: -1,
                    home: '', away: '', hg: 0, ag: 0,
                    start: uniq[i].start,
                    statusRole: 'DATE_SEP',
                    rawState: '', periodType: '', period: 0,
                    liveRemain: '', inIntermission: false,
                    situationCode: '1551', intermissionRemain: '',
                    gameIndex: gameIdx  // gameIdx = index du prochain vrai match
                })
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
                liveRemain: liveRemain,
                inIntermission: uniq[i].inIntermission || false,
                situationCode: uniq[i].situationCode || '1551',
                intermissionRemain: '',
                gameIndex: gameIdx++
            })
        }

        // Détecter les nouveaux buts et envoyer les notifications
        if (!initialLoading) {
            for (let ni = 0; ni < todayGames.count; ni++) {
                let ng = todayGames.get(ni)
                let prev = prevScores[ng.gameId]
                if (prev && ng.statusRole === 'LIVE') {
                    if (ng.ag > prev.ag || ng.hg > prev.hg) {
                        triggerGoalBlink(ng.away, ng.home, ng.ag, ng.hg, prev.ag, prev.hg, ng.gameId)
                    }
                }
            }
        }

        initialLoading = false
        lastUpdated = new Date()
        debugMsg = (errors && errors.length ? errors.join(' | ') : '')
        pollTimer.running = true

        // Récupérer l'horloge play-by-play pour les matchs en direct
        let hasLive = false
        for (let ci = 0; ci < todayGames.count; ci++) {
            if (todayGames.get(ci).statusRole === "LIVE" && todayGames.get(ci).gameId > 0) {
                fetchClock(todayGames.get(ci).gameId, ci)
                hasLive = true
            }
        }
        // Calculer situationCode depuis iceSurface du landing pour les AN
        if (hasLive) {
            for (let di = 0; di < todayGames.count; di++) {
                if (todayGames.get(di).statusRole === "LIVE")
                    fetchSituationFromLanding(todayGames.get(di).gameId)
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
        function onUltraCompactChanged(){
            root.ultraCompact = Plasmoid.configuration.ultraCompact || false
            // Forcer reconstruction du Repeater
            if (hRepeater) { hRepeater.model = null; hRepeater.model = todayGames }
        }
        function onShowUpcomingTimeChanged(){ }
        function onDateModeChanged(){ }

    }

    Component { id: statusBadge
        Rectangle {
            property string gameStatus:  'UPCOMING'
            property string suffix:      ''
            property string rawState:    ''
            property string periodType:  ''
            property int    period:      0
            property string liveRemain:  ''
            property var    startMs:     0
            property string homeTeam:    ''
            property bool   intermission: false
            radius: 5
            color: statusColor(gameStatus)
            opacity: 0.95
            Column {
                anchors.centerIn: parent
                spacing: 0
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: badgeLine1(parent.parent.gameStatus, parent.parent.rawState,
                                     parent.parent.periodType, parent.parent.period,
                                     parent.parent.liveRemain, parent.parent.startMs,
                                     parent.parent.homeTeam, parent.parent.intermission)
                    color: 'white'; font.pixelSize: 10; font.bold: true
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: text !== ''
                    text: badgeLine2(parent.parent.gameStatus, parent.parent.startMs, parent.parent.homeTeam)
                    color: 'white'; font.pixelSize: 9; opacity: 0.85
                }
            }
            width:  Math.max(
                        badgeLine1(gameStatus, rawState, periodType, period, liveRemain, startMs, homeTeam).length,
                        badgeLine2(gameStatus, startMs, homeTeam).length
                    ) * 6 + 10
            height: (badgeLine2(gameStatus, startMs, homeTeam) !== '' ? 28 : 16)
        }
    }

    Component { id: teamColumn
        Column {
            spacing: 1
            property string code:     ''
            property int    score:    0
            property int    sz:       14
            property string gameId:   ''
            property string teamSide: ''
            Rectangle {
                radius: 3
                color: teamColor(code)
                border.color: 'white'
                border.width: 1
                height: nameText.implicitHeight + Math.max(2, sz * 0.12)
                width:  nameText.implicitWidth  + Math.max(3, sz * 0.25)
                opacity: {
                    var b = root.blinkingGames[parent.gameId]
                    return (b && (b === parent.teamSide || b === 'both') && !root.blinkOn) ? 0.0 : 1.0
                }
                Text {
                    id: nameText
                    anchors.centerIn: parent
                    text: code
                    color: teamTextColor(code)
                    font.pixelSize: Math.max(8, sz * 0.72)
                    font.bold: true
                    font.family: "monospace"
                }
            }
            Text {
                text: String(score)
                font.pixelSize: Math.max(10, sz * 0.95)
                font.bold: true
                color: Kirigami.Theme.textColor
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: {
                    var b = root.blinkingGames[parent.gameId]
                    return (b && (b === parent.teamSide || b === 'both') && !root.blinkOn) ? 0.0 : 1.0
                }
            }
        }
    }

    Component { id: teamRowInline
        Row {
            spacing: Math.max(3, sz * 0.22)
            property string awayCode: ''
            property string homeCode: ''
            property int    agScore:  0
            property int    hgScore:  0
            property int    sz:       14
            property string gameId:   ''
            Rectangle {
                radius: 3
                color: teamColor(awayCode)
                border.color: 'white'; border.width: 1
                height: aText.implicitHeight + Math.max(2, sz * 0.12)
                width:  aText.implicitWidth  + Math.max(3, sz * 0.25)
                opacity: {
                    var b = root.blinkingGames[parent.gameId]
                    return (b && (b === 'away' || b === 'both') && !root.blinkOn) ? 0.0 : 1.0
                }
                Text { id: aText; anchors.centerIn: parent; text: awayCode
                    color: teamTextColor(awayCode)
                    font.pixelSize: Math.max(8, sz * 0.72); font.bold: true; font.family: "monospace" }
            }
            Label { text: String(agScore); font.pixelSize: Math.max(10, sz * 0.9); font.bold: true; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter
                    opacity: { var b = root.blinkingGames[gameId]; return (b && (b==='away'||b==='both') && !root.blinkOn) ? 0.0 : 1.0 } }
            Label { text: "–"; font.pixelSize: Math.max(10, sz * 0.9); color: Kirigami.Theme.disabledTextColor; anchors.verticalCenter: parent.verticalCenter }
            Label { text: String(hgScore); font.pixelSize: Math.max(10, sz * 0.9); font.bold: true; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter
                    opacity: { var b = root.blinkingGames[gameId]; return (b && (b==='home'||b==='both') && !root.blinkOn) ? 0.0 : 1.0 } }
            Rectangle {
                radius: 3
                color: teamColor(homeCode)
                border.color: 'white'; border.width: 1
                height: hText.implicitHeight + Math.max(2, sz * 0.12)
                width:  hText.implicitWidth  + Math.max(3, sz * 0.25)
                opacity: {
                    var b = root.blinkingGames[parent.gameId]
                    return (b && (b === 'home' || b === 'both') && !root.blinkOn) ? 0.0 : 1.0
                }
                Text { id: hText; anchors.centerIn: parent; text: homeCode
                    color: teamTextColor(homeCode)
                    font.pixelSize: Math.max(8, sz * 0.72); font.bold: true; font.family: "monospace" }
            }
        }
    }

    function upcomingWhenText(startMs, statusRole, homeTeam){
        if (!(statusRole==='UPCOMING' && showUpcomingTime)) return ''
        // Toujours afficher l'heure — la date est dans le séparateur DATE_SEP
        return localTimeStr(startMs)
    }

    function finalWhenText(startMs, statusRole, homeTeam) {
        if (statusRole !== 'FINAL') { return '' }
        if (dateMode === 'venue') { return venueDateStrUTC(startMs, homeTeam) }
        return localDateStr(startMs)
    }

    compactRepresentation: Item {
        id: compactRoot
        readonly property int pad: 6
        // sz : taille de base dérivée de la hauteur du panneau (mode horizontal)

        readonly property int sz: root.isVertical ? 14
            : Math.min(20, Math.max(8, Math.round(height * 0.38)))
        // Bascule automatique inline quand le panneau est trop mince (< ~40px)
        readonly property bool forceInline: !root.isVertical && sz < 13.5

        // ── Taille selon l'orientation ────────────────────────────────
        // Vertical : largeur = panneau (~48px), hauteur = somme des tuiles
        // Horizontal / Desktop : largeur = somme des matchs, hauteur = panneau
        implicitWidth:  root.isVertical
            ? parent.width
            : Math.max(hRow.implicitWidth + pad, emptyMsg.implicitWidth + pad)
        implicitHeight: root.isVertical
            ? Math.max(vCol.implicitHeight, emptyMsg.implicitHeight + 2)
            : Math.max(hRow.implicitHeight + 2, emptyMsg.implicitHeight + 2)

        Layout.preferredWidth:  implicitWidth
        Layout.minimumWidth:    root.isVertical ? 0 : implicitWidth
        Layout.preferredHeight: implicitHeight
        Layout.minimumHeight:   root.isVertical ? 0 : implicitHeight
        Layout.fillWidth:       root.isVertical
        Layout.fillHeight:      !root.isVertical

        // ══════════════════════════════════════════════════════════════
        // MODE HORIZONTAL (panneau horizontal ou bureau)
        // ══════════════════════════════════════════════════════════════
        Row {
            id: hRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.ultraCompact ? 1 : 2
            visible: !root.isVertical && todayGames.count > 0

            Repeater {
                id: hRepeater
                model: todayGames
                delegate: Item {
                    // Largeur fixe = cartes uniformes
                    clip: true
                    readonly property bool isDateSep: statusRole === 'DATE_SEP'
                    readonly property int cardW: Math.max(compactRoot.sz * 6.0, 80)
                    readonly property int cardWeff: {
                        if (root.ultraCompact) return ucRow.implicitWidth + 2
                        if (statusRole === 'UPCOMING' && scoreLayout !== 'stack') return Math.max(compactRoot.sz * 6.5, 88)
                        if (statusRole === 'UPCOMING') return Math.max(compactRoot.sz * 5.5, 76)
                        if (scoreLayout !== 'stack') return Math.max(compactRoot.sz * 7.0, 96)
                        return cardW
                    }
                    readonly property var cmpSit: root.parseSituation(situationCode, away, home)
                    readonly property real csz: compactRoot.sz * 0.88  // sz réduit pour tenir dans la carte
                    width:  isDateSep ? (dateSepContent.implicitWidth + 4) : (root.ultraCompact ? cardWeff + 2 : cardWeff + 4)
                    height: compactRoot.height
                    opacity: statusRole === 'FINAL' ? 0.5 : 1.0
                    visible: gameIndex < maxGames

                    // Séparateur de date : | 14/03 |
                    Row {
                        id: dateSepContent
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        visible: isDateSep
                        spacing: 0
                        // Ligne verticale gauche
                        Rectangle {
                            width: 1; height: parent.parent.height * 0.7
                            anchors.verticalCenter: parent.verticalCenter
                            color: Kirigami.Theme.textColor; opacity: 0.35
                        }
                        // Date DD/MM
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 5; rightPadding: 5
                            text: {
                                var d = new Date(start)
                                return String(d.getDate()).padStart(2,'0') + '/' + String(d.getMonth()+1).padStart(2,'0')
                            }
                            font.pixelSize: Math.max(10, compactRoot.sz * 0.75)
                            font.bold: true
                            color: Kirigami.Theme.textColor
                            opacity: 0.75
                        }
                        // Ligne verticale droite
                        Rectangle {
                            width: 1; height: parent.parent.height * 0.7
                            anchors.verticalCenter: parent.verticalCenter
                            color: Kirigami.Theme.textColor; opacity: 0.35
                        }
                    }

                    // Carte avec coins arrondis + fond selon statut
                    Rectangle {
                        id: cardBg
                        visible: !isDateSep && !root.ultraCompact
                        clip: true
                        anchors.centerIn: parent
                        width: cardWeff
                        height: parent.height - 4
                        radius: 5
                        color: {
                            if (statusRole === 'LIVE')
                                return Qt.rgba(0.0, 0.55, 0.1, 0.13)
                            if (statusRole === 'FINAL')
                                return Qt.rgba(0.5, 0.5, 0.5, 0.08)
                            return Qt.rgba(0.3, 0.5, 0.9, 0.10)
                        }
                        border.color: {
                            if (statusRole === 'LIVE')   return Qt.rgba(0.0, 0.7, 0.1, 0.35)
                            if (statusRole === 'FINAL')  return Qt.rgba(0.5, 0.5, 0.5, 0.2)
                            return Qt.rgba(0.3, 0.5, 0.9, 0.25)
                        }
                        border.width: 1

                        // MODE NORMAL (stack) — disposition verticale centrée
                        Column {
                            anchors.centerIn: parent
                            spacing: 1
                            visible: !root.ultraCompact && !isDateSep
                            enabled: !root.ultraCompact && !isDateSep

                            // Mode stack : [AWAY score] [statut] [HOME score]
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 3
                                visible: compactRoot.forceInline || scoreLayout === 'stack'

                                // Visiteur : pastille + score
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    Rectangle {
                                        radius: 3; color: root.teamColor(away)
                                        border.color: 'white'; border.width: 1
                                        width: awayLbl.implicitWidth + 6
                                        height: awayLbl.implicitHeight + 3
                                        opacity: root.blinkOpacity(gameId, 'away')
                                        Text { id: awayLbl; anchors.centerIn: parent; text: away
                                            color: root.teamTextColor(away)
                                            font.pixelSize: Math.max(7, csz * 0.68)
                                            font.bold: true; font.family: "monospace" }
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: String(ag)
                                        font.pixelSize: Math.max(9, csz * 0.88)
                                        font.bold: true; color: Kirigami.Theme.textColor
                                        visible: statusRole === 'LIVE' || statusRole === 'FINAL'
                                        opacity: root.blinkOpacity(gameId, 'away')
                                    }

                                }

                                // Pastille statut
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: Math.max(2, csz * 0.15)
                                    color: statusColor(statusRole); opacity: 0.95
                                    width:  statusCol.implicitWidth  + 6
                                    height: statusCol.implicitHeight + 3
                                    Column {
                                        id: statusCol; anchors.centerIn: parent; spacing: 0
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: badgeLine1(statusRole, rawState, periodType, period, liveRemain, start, home, inIntermission)
                                            color: 'white'
                                            font.pixelSize: Math.max(7, csz * 0.60)
                                            font.bold: true
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            visible: inIntermission && intermissionRemain !== ''
                                            text: intermissionRemain; color: 'white'
                                            font.pixelSize: Math.max(6, csz * 0.48)
                                            font.bold: true
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            visible: !inIntermission && statusRole !== 'UPCOMING' && text !== ''
                                            text: badgeLine2(statusRole, start, home)
                                            color: 'white'
                                            font.pixelSize: Math.max(5, csz * 0.38)
                                            opacity: 0.85
                                        }
                                        // PP collé sous le temps
                                        Rectangle {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            visible: statusRole === 'LIVE' && !inIntermission && cmpSit !== null
                                            radius: 2
                                            color: cmpSit ? (cmpSit.ppTeam ? root.teamColor(cmpSit.ppTeam) : Kirigami.Theme.highlightColor) : "transparent"
                                            width: ppRowInner.implicitWidth + 4; height: ppRowInner.implicitHeight + 1
                                            Row {
                                                id: ppRowInner; anchors.centerIn: parent; spacing: 2
                                                Text {
                                                    text: cmpSit ? (cmpSit.ppType + ' ' + cmpSit.awaySkaters + 'v' + cmpSit.homeSkaters) : ''
                                                    color: (cmpSit && cmpSit.ppTeam) ? root.teamTextColor(cmpSit.ppTeam) : 'white'
                                                    font.pixelSize: Math.max(5, csz * 0.40); font.bold: true
                                                }
                                                Text {
                                                    visible: cmpSit && cmpSit.emptyNet; text: '🥅'
                                                    font.pixelSize: Math.max(5, csz * 0.40)
                                                }
                                            }
                                        }
                                    }
                                }

                                // Local : pastille + score
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    Rectangle {
                                        radius: 3; color: root.teamColor(home)
                                        border.color: 'white'; border.width: 1
                                        width: homeLbl.implicitWidth + 6
                                        height: homeLbl.implicitHeight + 3
                                        opacity: root.blinkOpacity(gameId, 'home')
                                        Text { id: homeLbl; anchors.centerIn: parent; text: home
                                            color: root.teamTextColor(home)
                                            font.pixelSize: Math.max(7, csz * 0.68)
                                            font.bold: true; font.family: "monospace" }
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: String(hg)
                                        font.pixelSize: Math.max(9, csz * 0.88)
                                        font.bold: true; color: Kirigami.Theme.textColor
                                        visible: statusRole === 'LIVE' || statusRole === 'FINAL'
                                        opacity: root.blinkOpacity(gameId, 'home')
                                    }

                                }
                            }


                        }

                            // Mode inline : [AWAY ag statut hg HOME] sur une ligne
                            Row {
                                anchors.centerIn: parent
                                spacing: 3
                                visible: !compactRoot.forceInline && scoreLayout !== 'stack'
                                Rectangle {
                                    radius: 3; color: root.teamColor(away)
                                    border.color: 'white'; border.width: 1
                                    width: awayLblI.implicitWidth + 6; height: awayLblI.implicitHeight + 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    opacity: root.blinkOpacity(gameId, 'away')
                                    Text { id: awayLblI; anchors.centerIn: parent; text: away
                                        color: root.teamTextColor(away)
                                        font.pixelSize: Math.max(7, csz * 0.68); font.bold: true; font.family: "monospace" }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: String(ag); visible: statusRole === 'LIVE' || statusRole === 'FINAL'
                                    font.pixelSize: Math.max(9, csz * 0.88); font.bold: true; color: Kirigami.Theme.textColor
                                    opacity: root.blinkOpacity(gameId, 'away')
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: Math.max(2, csz * 0.15); color: statusColor(statusRole); opacity: 0.95
                                    width: statusColI.implicitWidth + 6; height: statusColI.implicitHeight + 3
                                    Column {
                                        id: statusColI; anchors.centerIn: parent; spacing: 0
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: badgeLine1(statusRole, rawState, periodType, period, liveRemain, start, home, inIntermission)
                                            color: 'white'; font.pixelSize: Math.max(7, csz * 0.60); font.bold: true
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            visible: inIntermission && intermissionRemain !== ''
                                            text: intermissionRemain; color: 'white'
                                            font.pixelSize: Math.max(6, csz * 0.48); font.bold: true
                                        }
                                        Rectangle {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            visible: statusRole === 'LIVE' && !inIntermission && cmpSit !== null
                                            radius: 2
                                            color: cmpSit ? (cmpSit.ppTeam ? root.teamColor(cmpSit.ppTeam) : Kirigami.Theme.highlightColor) : "transparent"
                                            width: ppRowI.implicitWidth + 4; height: ppRowI.implicitHeight + 1
                                            Row {
                                                id: ppRowI; anchors.centerIn: parent; spacing: 2
                                                Text {
                                                    text: cmpSit ? (cmpSit.ppType + ' ' + cmpSit.awaySkaters + 'v' + cmpSit.homeSkaters) : ''
                                                    color: (cmpSit && cmpSit.ppTeam) ? root.teamTextColor(cmpSit.ppTeam) : 'white'
                                                    font.pixelSize: Math.max(5, csz * 0.40); font.bold: true
                                                }
                                                Text { visible: cmpSit && cmpSit.emptyNet; text: '🥅'; font.pixelSize: Math.max(5, csz * 0.40) }
                                            }
                                        }
                                    }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: String(hg); visible: statusRole === 'LIVE' || statusRole === 'FINAL'
                                    font.pixelSize: Math.max(9, csz * 0.88); font.bold: true; color: Kirigami.Theme.textColor
                                    opacity: root.blinkOpacity(gameId, 'home')
                                }
                                Rectangle {
                                    radius: 3; color: root.teamColor(home)
                                    border.color: 'white'; border.width: 1
                                    width: homeLblI.implicitWidth + 6; height: homeLblI.implicitHeight + 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    opacity: root.blinkOpacity(gameId, 'home')
                                    Text { id: homeLblI; anchors.centerIn: parent; text: home
                                        color: root.teamTextColor(home)
                                        font.pixelSize: Math.max(7, csz * 0.68); font.bold: true; font.family: "monospace" }
                                }
                            }

                    }

                    // MODE ULTRA-COMPACT — hors cardBg pour éviter superposition
                    Row {
                        id: ucRow
                        anchors.centerIn: parent
                        visible: root.ultraCompact && !isDateSep
                        spacing: 2
                        Rectangle {
                            id: ucAwayDot
                            width: Math.max(14, compactRoot.sz * 0.95)
                            height: width; radius: width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.teamColor(away)
                            border.color: 'white'; border.width: 1
                            opacity: root.blinkOpacity(gameId, 'away')
                            Text { anchors.centerIn: parent; text: away.charAt(0); color: root.teamTextColor(away); font.pixelSize: Math.max(7, ucAwayDot.width * 0.60); font.bold: true }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: statusRole === 'LIVE' || statusRole === 'FINAL'
                            text: ag + '–' + hg
                            color: Kirigami.Theme.textColor
                            font.pixelSize: Math.max(10, compactRoot.sz * 0.80)
                            font.bold: true
                        }
                        Rectangle {
                            id: ucHomeDot
                            width: Math.max(14, compactRoot.sz * 0.95)
                            height: width; radius: width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.teamColor(home)
                            border.color: 'white'; border.width: 1
                            opacity: root.blinkOpacity(gameId, 'home')
                            Text { anchors.centerIn: parent; text: home.charAt(0); color: root.teamTextColor(home); font.pixelSize: Math.max(7, ucHomeDot.width * 0.60); font.bold: true }
                        }
                    }

                    // Séparateur entre les cartes
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !isDateSep && gameIndex >= 0 && gameIndex < maxGames - 1
                        width: 1; height: parent.height * 0.6
                        color: Kirigami.Theme.textColor; opacity: 0.2
                    }

                    TapHandler {
                        enabled: !isDateSep
                        acceptedButtons: Qt.LeftButton; gesturePolicy: TapHandler.ReleaseWithinBounds
                        cursorShape: isDateSep ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onTapped: if (!isDateSep) root.openDetail(gameId, away, home, ag, hg, statusRole, periodType, period, liveRemain, start, inIntermission, situationCode)
                    }
                }
            }
        }

        // ══════════════════════════════════════════════════════════════
        // MODE VERTICAL — tuiles empilées
        // Chaque tuile : [pastille couleur équipe visitor] [pastille statut]
        //                [pastille couleur équipe locale ]
        // ══════════════════════════════════════════════════════════════
        Column {
            id: vCol
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 3
            visible: root.isVertical && todayGames.count > 0

            Repeater {
                id: vRepeater
                model: todayGames
                delegate: Item {
                    // Tuile unique par match — largeur = panneau, hauteur auto
                    property string rAway:   away   || ""
                    property string rHome:   home   || ""
                    property int    rAg:     ag     || 0
                    property int    rHg:     hg     || 0
                    property string rStatus: statusRole || ""
                    property string rRaw:    rawState   || ""
                    property string rPType:  periodType || ""
                    property int    rPeriod: period     || 0
                    property string rRemain: liveRemain || ""
                    property var    rStart:  start
                    property bool   rInterm: inIntermission || false

                    visible: gameIndex < maxGames
                    width: compactRoot.width
                    height: tileCol.implicitHeight + 6

                    // Dégradé équipes LIVE
                    Rectangle {
                        anchors.fill: parent; radius: 4
                        visible: statusRole === 'LIVE'
                        opacity: 0.55
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.bestGradientColors(away, home).ac }
                            GradientStop { position: 1.0; color: root.bestGradientColors(away, home).hc }
                        }
                    }
                    // Fond subtil au survol
                    Rectangle {
                        anchors.fill: parent; radius: 4
                        color: tileArea.containsMouse ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                            Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)
                            : "transparent"
                    }

                    Column {
                        id: tileCol
                        anchors.centerIn: parent
                        spacing: 2

                        // ── Pastille fusionnée ───────────────────────
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            radius: 3
                            color: root.statusColor(rStatus)
                            opacity: rStatus === 'FINAL' ? 0.6 : 0.95
                            width: vtBadgeCol.implicitWidth + 8
                            height: vtBadgeCol.implicitHeight + 4
                            Column {
                                id: vtBadgeCol
                                anchors.centerIn: parent
                                spacing: 0
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.badgeLine1(rStatus, rRaw, rPType, rPeriod, rRemain, rStart, rHome, rInterm)
                                    color: "white"; font.pixelSize: 9; font.bold: true
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: text !== ''
                                    text: root.badgeLine2(rStatus, rStart, rHome)
                                    color: "white"; font.pixelSize: 8; opacity: 0.85
                                }
                            }
                        }

                        // ── Équipe visiteur ───────────────────────────
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: awayLbl.implicitWidth + 8; height: awayLbl.implicitHeight + 4; radius: 3
                            color: root.teamColor(rAway)
                            opacity: {
                                var b = root.blinkingGames[String(gameId)]
                                return (b && (b === 'away' || b === 'both') && !root.blinkOn) ? 0.0 : 1.0
                            }
                            Label {
                                id: awayLbl; anchors.centerIn: parent
                                text: rAway; font.pixelSize: 10; font.bold: true; font.family: "monospace"
                                color: root.teamTextColor(rAway)
                            }
                        }

                        // ── Score visiteur ────────────────────────────
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: rAg
                            font.pixelSize: 13; font.bold: true
                            color: (rStatus === 'LIVE' && rAg > rHg)
                                ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                            opacity: {
                                var b = root.blinkingGames[String(gameId)]
                                if (b && (b === 'away' || b === 'both') && !root.blinkOn) return 0.0
                                return rStatus === 'FINAL' ? 0.7 : 1.0
                            }
                        }

                        // ── Score local ───────────────────────────────
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: rHg
                            font.pixelSize: 13; font.bold: true
                            color: (rStatus === 'LIVE' && rHg > rAg)
                                ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                            opacity: {
                                var b = root.blinkingGames[String(gameId)]
                                if (b && (b === 'home' || b === 'both') && !root.blinkOn) return 0.0
                                return rStatus === 'FINAL' ? 0.7 : 1.0
                            }
                        }

                        // ── Équipe locale ─────────────────────────────
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: homeLbl.implicitWidth + 8; height: homeLbl.implicitHeight + 4; radius: 3
                            color: root.teamColor(rHome)
                            opacity: {
                                var b = root.blinkingGames[String(gameId)]
                                return (b && (b === 'home' || b === 'both') && !root.blinkOn) ? 0.0 : 1.0
                            }
                            Label {
                                id: homeLbl; anchors.centerIn: parent
                                text: rHome; font.pixelSize: 10; font.bold: true; font.family: "monospace"
                                color: root.teamTextColor(rHome)
                            }
                        }


                    }

                    // Séparateur entre tuiles
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.leftMargin: 4; anchors.rightMargin: 4
                        height: 1
                        color: Kirigami.Theme.textColor; opacity: 0.1
                        visible: index < Math.min(todayGames.count, maxGames) - 1
                    }

                    HoverHandler { id: tileArea }
                    TapHandler {
                        acceptedButtons: Qt.LeftButton; gesturePolicy: TapHandler.ReleaseWithinBounds
                        cursorShape: Qt.PointingHandCursor
                        onTapped: root.openDetail(gameId, rAway, rHome, rAg, rHg, rStatus, rPType, rPeriod, rRemain, rStart, rInterm, situationCode)
                    }
                }
            }
        }

        // Message vide (commun aux deux modes)
        Label {
            id: emptyMsg
            anchors.centerIn: parent
            visible: todayGames.count === 0
            text: root.initialLoading ? i18n('Loading…') : i18n('No games')
            color: root.initialLoading ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor
            font.italic: root.initialLoading
        }
    }


    // ── État du calendrier d'équipe ─────────────────────────────────────
    property bool   scheduleOpen:      false
    property bool   scheduleShowStats: false   // false=calendrier  true=stats joueurs
    property string scheduleTeam:      ''
    property var    scheduleGames:     []
    property bool   scheduleLoading:   false
    property string scheduleError:     ''
    property var    scheduleSkaters:   []   // [{name, pos, gp, g, a, pts, plusMinus, pim}]
    property var    scheduleGoalies:   []   // [{name, gp, wins, losses, gaa, svPct}]
    property bool   scheduleStatsLoading: false
    property string scheduleStatsError:   ''

    function openSchedule(team) {
        scheduleShowStats    = false
        scheduleSkaters      = []
        scheduleGoalies      = []
        scheduleStatsError   = ''
        scheduleStatsLoading = false
        scheduleTeam    = team
        scheduleGames   = []
        scheduleError   = ''
        scheduleLoading = true
        scheduleOpen    = true
        fetchSchedule(team)
    }

    function fetchSchedule(team) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "https://api-web.nhle.com/v1/club-schedule-season/" + team + "/now")
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            scheduleLoading = false
            if (xhr.status !== 200) { scheduleError = "HTTP " + xhr.status; return }
            try {
                var data = JSON.parse(xhr.responseText)
                var games = data.games || []
                var past = [], future = []
                for (var i = 0; i < games.length; i++) {
                    var g = games[i]
                    var st = (g.gameState || '').toUpperCase()
                    var isFinal = (st === 'FINAL' || st === 'OFF' || st === 'OFFICIAL')
                    if (isFinal) past.push(g)
                    else future.push(g)
                }
                // Garder les N derniers matchs joués + tous les futurs
                var recent = past.slice(-5)  // 5 derniers matchs joués
                var result = recent.concat(future)
                scheduleGames = result.map(function(g) {
                    var st = (g.gameState || '').toUpperCase()
                    var isFinal = (st === 'FINAL' || st === 'OFF' || st === 'OFFICIAL')
                    var isLive  = (st === 'LIVE' || st === 'IN_PROGRESS')
                    var away  = g.awayTeam  ? (g.awayTeam.abbrev  || '?') : '?'
                    var home  = g.homeTeam  ? (g.homeTeam.abbrev  || '?') : '?'
                    var ag    = g.awayTeam  ? (g.awayTeam.score   !== undefined ? g.awayTeam.score  : -1) : -1
                    var hg    = g.homeTeam  ? (g.homeTeam.score   !== undefined ? g.homeTeam.score  : -1) : -1
                    var startMs = new Date(g.startTimeUTC || '').getTime() || 0
                    // Résultat W/L/OTW/OTL pour l'équipe sélectionnée
                    var matchResult = ''
                    if (isFinal && ag >= 0 && hg >= 0) {
                        var teamIsHome = (home === team)
                        var teamScore = teamIsHome ? hg : ag
                        var oppScore  = teamIsHome ? ag : hg
                        var pd = g.periodDescriptor
                        var wasOT = pd && (pd.periodType === 'OT' || pd.periodType === 'SO' || pd.number > 3)
                        if (teamScore > oppScore) matchResult = wasOT ? 'OTW' : 'W'
                        else                      matchResult = wasOT ? 'OTL' : 'L'
                    }
                    return {
                        away: away, home: home,
                        ag: ag, hg: hg,
                        startMs: startMs,
                        isFinal: isFinal,
                        isLive:  isLive,
                        result:  matchResult,
                        gameId:  g.id || 0
                    }
                })
            } catch(e) { scheduleError = String(e) }
        }
        xhr.send()
    }

    function fetchTeamStats(team) {
        scheduleStatsLoading = true
        scheduleStatsError   = ''
        var xhr = new XMLHttpRequest()
        // Endpoint stats équipe saison courante
        xhr.open("GET", "https://api-web.nhle.com/v1/club-stats/" + team + "/now")
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            scheduleStatsLoading = false
            if (xhr.status !== 200) { scheduleStatsError = "HTTP " + xhr.status; return }
            try {
                var data = JSON.parse(xhr.responseText)
                // Patineurs
                var sk = []
                var skaters = data.skaters || []
                for (var i = 0; i < skaters.length; i++) {
                    var s = skaters[i]
                    var fname = s.firstName  ? (s.firstName.default  || '') : ''
                    var lname = s.lastName   ? (s.lastName.default   || '') : ''
                    sk.push({
                        name:      fname + ' ' + lname,
                        pos:       s.positionCode || '?',
                        gp:        s.gamesPlayed  || 0,
                        g:         s.goals        || 0,
                        a:         s.assists      || 0,
                        pts:       s.points       || 0,
                        plusMinus: s.plusMinus    !== undefined ? s.plusMinus : 0,
                        pim:       s.penaltyMinutes || 0
                    })
                }
                // Trier par pts desc, puis goals desc
                sk.sort(function(a, b) {
                    return b.pts !== a.pts ? b.pts - a.pts : b.g - a.g
                })
                scheduleSkaters = sk
                // Gardiens
                var gl = []
                var goalies = data.goalies || []
                for (var gi = 0; gi < goalies.length; gi++) {
                    var g = goalies[gi]
                    var gfname = g.firstName ? (g.firstName.default || '') : ''
                    var glname = g.lastName  ? (g.lastName.default  || '') : ''
                    gl.push({
                        name:   gfname + ' ' + glname,
                        gp:     g.gamesPlayed   || 0,
                        wins:   g.wins          || 0,
                        losses: g.losses        || 0,
                        ot:     g.otLosses      || 0,
                        gaa:    g.goalsAgainstAverage !== undefined
                                    ? Math.round(g.goalsAgainstAverage * 100) / 100 : 0,
                        svPct:  g.savePctg !== undefined
                                    ? Math.round(g.savePctg * 1000) / 1000 : 0
                    })
                }
                // Trier par wins desc
                gl.sort(function(a, b) { return b.wins - a.wins })
                scheduleGoalies = gl
            } catch(e) { scheduleStatsError = String(e) }
        }
        xhr.send()
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
    property bool detailInterm:   false
    property string detailIntermRemain: ''
    property string detailPenaltyBoxAway: '[]'
    property string detailPenaltyBoxHome: '[]'
    // Stockage pénalités hors ListModel (évite le problème de type String vs List)
    property var penaltiesMap: ({})
    property var  detailGoals:    []

    // Liste plate pour affichage par période :
    // éléments de type { isPeriodHeader: true, label: "1re période" }
    // ou               { isPeriodHeader: false, ...données but... }
    readonly property var detailGoalsByPeriod: {
        var result = []
        var seenPeriods = []
        var maxPeriod = 0
        // Déterminer la période courante pour les matchs en cours
        if (detailStatus === 'LIVE' || detailStatus === 'FINAL') {
            maxPeriod = detailPeriod || 0
        }
        // Collecter les périodes qui ont des buts
        for (var i = 0; i < detailGoals.length; i++) {
            var p = detailGoals[i].period
            if (seenPeriods.indexOf(p) === -1) seenPeriods.push(p)
        }
        // Assurer que les périodes réglementaires jouées apparaissent (max 3)
        // Les périodes OT/SO sont ajoutées seulement si elles ont des buts (déjà dans seenPeriods)
        for (var pn = 1; pn <= Math.min(maxPeriod, 3); pn++) {
            var pStr = String(pn)
            if (seenPeriods.indexOf(pStr) === -1) seenPeriods.push(pStr)
        }
        // Trier : 1, 2, 3, OT, SO
        seenPeriods.sort(function(a, b) {
            var order = { '1':1, '2':2, '3':3, 'OT':4, 'SO':99 }
            // 2OT=5, 3OT=6, etc.
            function rank(p) {
                if (order[p] !== undefined) return order[p]
                var m = p.match(/^(\d+)OT$/)
                if (m) return 3 + parseInt(m[1])  // 2OT→5, 3OT→6...
                return 98
            }
            return rank(a) - rank(b)
        })
        // Construire la liste plate
        for (var pi = 0; pi < seenPeriods.length; pi++) {
            var period = seenPeriods[pi]
            var label = period === 'SO' ? i18n('Shootout')
                      : period === 'OT' ? i18n('Overtime')
                      : /^\d+OT$/.test(period) ? (period.replace('OT','') + 'e ' + i18n('Overtime'))
                      : period === '1'  ? i18n('1st period')
                      : period === '2'  ? i18n('2nd period')
                      : period === '3'  ? i18n('3rd period')
                      : i18n('Period') + ' ' + period
            result.push({ isPeriodHeader: true, label: label, period: period,
                          team:'', scorer:'', assists:[], time:'', goalsToDate:-1,
                          ppg:false, shg:false, en:false })
            var count = 0
            for (var gi = 0; gi < detailGoals.length; gi++) {
                if (detailGoals[gi].period === period) {
                    var gobj = detailGoals[gi]
                    result.push({ isPeriodHeader: false, label: '',
                                  period: gobj.period, time: gobj.time,
                                  team: gobj.team, scorer: gobj.scorer,
                                  goalsToDate: gobj.goalsToDate,
                                  assists: gobj.assists,
                                  ppg: gobj.ppg, shg: gobj.shg, en: gobj.en })
                    count++
                }
            }
            if (count === 0) {
                result.push({ isPeriodHeader: false, label: i18n('No goals recorded.'),
                              period: period, time:'', team:'', scorer:'',
                              assists:[], goalsToDate:-1,
                              ppg:false, shg:false, en:false,
                              isEmpty: true })
            }
        }
        return result
    }
    property var  detailStats:    ({})
    // Propriétés scalaires pour le preview UPCOMING (évite les bugs de binding QML avec var)
    property string pvVenue:       ''
    property int    pvSeriesAway:  0
    property int    pvSeriesHome:  0
    property bool   pvSeriesTotal: false
    property string pvAwayRecord:  ''
    property string pvHomeRecord:  ''
    property var    pvAwayLeaders: []
    property var    pvHomeLeaders: []
    property var    pvAwayGoalie:  null
    property var    pvHomeGoalie:  null
    property bool detailLoading:  false
    property string detailError:  ''
    property bool detailOpen:     false

    function openDetail(gid, away, home, ag, hg, status, ptype, period, remain, start, interm, sitCode) {
        // Toggle : fermer si le même match est déjà ouvert
        if (detailOpen && detailGameId === gid) {
            detailOpen = false
            expanded   = false
            return
        }
        // Fermer le calendrier/stats si ouvert
        scheduleOpen      = false
        scheduleShowStats = false
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
        detailInterm  = interm || false
        detailGoals   = []
        detailStats   = ({})
        pvVenue = ''; pvSeriesAway = 0; pvSeriesHome = 0; pvSeriesTotal = false
        pvAwayRecord = ''; pvHomeRecord = ''
        pvAwayLeaders = []; pvHomeLeaders = []
        pvAwayGoalie = null; pvHomeGoalie = null
        detailSituationCode  = sitCode || '1551'
        detailIntermRemain   = ''
        var pmEntry = root.penaltiesMap[String(gid)] || {away:[],home:[]}
        detailPenaltyBoxAway = JSON.stringify(pmEntry.away)
        detailPenaltyBoxHome = JSON.stringify(pmEntry.home)
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


                    // ── Preview pour les matchs à venir ─────────────────
                    // Structure confirmée :
                    //   d.awayTeam.record          → string "W-L-OT"
                    //   d.matchup.skaterComparison.leaders → [{category,awayLeader,homeLeader}]
                    //     leader.name.default, leader.goals, leader.points
                    //   d.matchup.goalieComparison.{awayTeam|homeTeam}.leaders[0] → gardien
                    //   d.seasonSeries              → matchs de la série saison
                    if (detailStatus === 'UPCOMING') {
                        let pv = {}

                        // Heure locale du match
                        pv.startMs = detailStart || 0


                        // Aréna
                        let venue = d.venue
                        pv.venue = venue ? (venue.default || venue) : ''

                        // Série saison
                        let ss = d.seasonSeries || []
                        let awWins = 0, hmWins = 0
                        for (let si = 0; si < ss.length; si++) {
                            let sg = ss[si]
                            let sgState = (sg.gameState || '').toUpperCase()
                            if (sgState === 'FINAL' || sgState === 'OFF' || sgState === 'OFFICIAL') {
                                let aw = sg.awayTeam ? (sg.awayTeam.abbrev || '') : ''
                                let awS = sg.awayTeam ? (sg.awayTeam.score || 0) : 0
                                let hmS = sg.homeTeam ? (sg.homeTeam.score || 0) : 0
                                if (aw === detailAway) { if (awS > hmS) awWins++; else hmWins++ }
                                else                   { if (hmS > awS) awWins++; else hmWins++ }
                            }
                        }
                        pv.seriesAway  = awWins
                        pv.seriesHome  = hmWins
                        pv.seriesTotal = ss.length > 0

                        // Fiche : d.awayTeam.record est une string "W-L-OT"
                        function parseRecord(team) {
                            if (!team || !team.record) return { wins:'–', losses:'–', ot:'–' }
                            let rec = team.record
                            if (typeof rec === 'string') {
                                let p = rec.split('-')
                                return { wins: p[0]||'–', losses: p[1]||'–', ot: p[2]||'–' }
                            }
                            return {
                                wins:   rec.wins     !== undefined ? rec.wins     : '–',
                                losses: rec.losses   !== undefined ? rec.losses   : '–',
                                ot:     rec.otLosses !== undefined ? rec.otLosses : '–'
                            }
                        }
                        pv.awayRecord = parseRecord(d.awayTeam)
                        pv.homeRecord = parseRecord(d.homeTeam)

                        // Leaders : d.matchup.skaterComparison.leaders
                        // = [{category:"points"|"goals"|"assists", awayLeader:{name,value}, homeLeader:{name,value}}]
                        // Chaque row = UN meneur par catégorie — afficher points/goals/assists séparément
                        function parseLeaders(scLeaders, side) {
                            if (!scLeaders || !scLeaders.length) return []
                            let catOrder = ['points', 'goals', 'assists']
                            let result = []
                            // D'abord dans l'ordre souhaité
                            for (let oi = 0; oi < catOrder.length; oi++) {
                                let cat = catOrder[oi]
                                for (let ci = 0; ci < scLeaders.length; ci++) {
                                    let row = scLeaders[ci]
                                    if ((row.category || '').toLowerCase() !== cat) continue
                                    let p = side === 'away' ? row.awayLeader : row.homeLeader
                                    if (!p) continue
                                    let name = p.name ? (p.name.default || '') : ''
                                    result.push({
                                        cat:   cat,
                                        name:  name,
                                        value: p.value !== undefined ? p.value : '–'
                                    })
                                    break
                                }
                            }
                            return result
                        }
                        let scLeaders = (d.matchup && d.matchup.skaterComparison
                                         && d.matchup.skaterComparison.leaders) || []
                        pv.awayLeaders = parseLeaders(scLeaders, 'away')
                        pv.homeLeaders = parseLeaders(scLeaders, 'home')

                        // Gardiens : d.matchup.goalieComparison.{awayTeam|homeTeam}.leaders[0]
                        // Champs confirmés : playerId, name, gamesPlayed, seasonPoints,
                        //                   record (string ou objet), gaa (float), savePctg (float), shutouts
                        function parseGoalie(teamData) {
                            if (!teamData) return null
                            let leaders = teamData.leaders || []
                            let g = leaders.length > 0 ? leaders[0] : null
                            if (!g) return null
                            let name = g.name ? (g.name.default || '') : ''
                            if (!name) return null
                            // record : peut être string "W-L-OT" ou objet
                            let recStr = '–'
                            if (g.record !== undefined) {
                                if (typeof g.record === 'string') {
                                    recStr = g.record
                                } else if (typeof g.record === 'object') {
                                    let r = g.record
                                    recStr = (r.wins||0) + '-' + (r.losses||0)
                                           + (r.otLosses !== undefined ? '-' + r.otLosses : '')
                                }
                            }
                            // gaa : float direct
                            let gaa = g.gaa !== undefined    ? parseFloat(g.gaa).toFixed(2)
                                    : g.goalsAgainstAverage !== undefined
                                        ? parseFloat(g.goalsAgainstAverage).toFixed(2) : '–'
                            // savePctg : float ex 0.912
                            let svp = g.savePctg !== undefined ? g.savePctg : null
                            return {
                                name:   name,
                                record: recStr,
                                gaa:    gaa,
                                svPct:  svp !== null
                                    ? ('.' + String(Math.round(svp*1000)).padStart(3,'0')) : '–'
                            }
                        }
                        let glComp = (d.matchup && d.matchup.goalieComparison) || null
                        pv.awayGoalie = parseGoalie(glComp ? glComp.awayTeam : null)
                        pv.homeGoalie = parseGoalie(glComp ? glComp.homeTeam : null)

                        // Assigner chaque propriété scalaire séparément → bindings QML fiables
                        pvVenue       = pv.venue || ''
                        pvSeriesAway  = pv.seriesAway  || 0
                        pvSeriesHome  = pv.seriesHome  || 0
                        pvSeriesTotal = pv.seriesTotal || false
                        pvAwayRecord  = (pv.awayRecord
                            ? (pv.awayRecord.wins||'–')+'-'+(pv.awayRecord.losses||'–')+'-'+(pv.awayRecord.ot||'–')
                            : '')
                        pvHomeRecord  = (pv.homeRecord
                            ? (pv.homeRecord.wins||'–')+'-'+(pv.homeRecord.losses||'–')+'-'+(pv.homeRecord.ot||'–')
                            : '')
                        pvAwayLeaders = pv.awayLeaders || []
                        pvHomeLeaders = pv.homeLeaders || []
                        pvAwayGoalie  = pv.awayGoalie  || null
                        pvHomeGoalie  = pv.homeGoalie  || null
                    }

                    // ── Buts pour les matchs commencés / terminés ────────
                    let g = []
                    let periods = (d.summary && d.summary.scoring) ? d.summary.scoring : []
                    for (let p = 0; p < periods.length; p++) {
                        let ps = periods[p]
                        let pnum  = ps.periodDescriptor ? (ps.periodDescriptor.number || (p+1)) : (p+1)
                        let ptype = ps.periodDescriptor ? (ps.periodDescriptor.periodType || '') : ''
                        let pname = ptype === 'SO' ? 'SO'
                                  : ptype === 'OT' ? (pnum === 4 ? 'OT' : (pnum - 3) + 'OT')
                                  : String(pnum)
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
                                    let aName = a.firstName
                                        ? (a.firstName.default || '') + ' ' + (a.lastName.default || '')
                                        : (a.name && a.name.default ? a.name.default : '?')
                                    assists.push({
                                        name:          aName,
                                        assistsToDate: a.assistsToDate !== undefined ? a.assistsToDate : -1
                                    })
                                }
                            }
                            g.push({
                                period:       pname,
                                time:         gl.timeInPeriod || '',
                                team:         gl.teamAbbrev ? (gl.teamAbbrev.default || gl.teamAbbrev) : '',
                                scorer:       scorer,
                                goalsToDate:  gl.goalsToDate !== undefined ? gl.goalsToDate : -1,
                                assists:      assists,
                                ppg:          gl.strength === 'pp',
                                shg:          gl.strength === 'sh',
                                en:           gl.goalModifier === 'empty-net' || gl.emptyNet === true
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
        interval: 20000
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
                        if (g.statusRole === 'LIVE')
                            root.detailSituationCode = g.situationCode || '1551'
                        break
                    }
                }
                // Recharger les buts et stats
                fetchDetail(root.detailGameId)
            }
        }
    }

    // ── fullRepresentation : popup natif Plasma, bien positionné ─────────
    // ── Modèle plat pour la vue standings ───────────────────────────────
    // Reconstruit quand standingsData change
    ListModel { id: standingsFlatModel }

    // standingsFlatModel stocke des primitives seulement (limitation ListModel).
    // Pour les lignes d'équipe, on stocke les champs directement à plat.
    function buildStandingsModel() {
        standingsFlatModel.clear()
        var confs = [
            { abbrev: "E", name: i18n("Eastern Conference"),
              divs: [ { api: "Atlantic",      label: "Atlantique"      },
                      { api: "Metropolitan",  label: "Métropolitaine"  } ] },
            { abbrev: "W", name: i18n("Western Conference"),
              divs: [ { api: "Central",       label: "Centrale"        },
                      { api: "Pacific",       label: "Pacifique"       } ] }
        ]
        for (var ci = 0; ci < confs.length; ci++) {
            var conf = confs[ci]
            var confTeams = []
            for (var i = 0; i < root.standingsData.length; i++) {
                var t = root.standingsData[i]
                if (t.conferenceAbbrev === conf.abbrev) confTeams.push(t)
            }
            standingsFlatModel.append({ type: "confHeader", label: conf.name,
                abbrev:"", city:"", gp:0, w:0, l:0, ot:0, pts:0 })
            standingsFlatModel.append({ type: "colHeader",  label: "",
                abbrev:"", city:"", gp:0, w:0, l:0, ot:0, pts:0 })
            for (var di = 0; di < conf.divs.length; di++) {
                var div = conf.divs[di]
                var divTeams = []
                for (var j = 0; j < confTeams.length; j++) {
                    if (confTeams[j].divisionName === div.api) divTeams.push(confTeams[j])
                }
                divTeams.sort(function(a,b){ return a.divisionSequence - b.divisionSequence })
                standingsFlatModel.append({ type: "divHeader", label: div.label,
                    abbrev:"", city:"", gp:0, w:0, l:0, ot:0, pts:0 })
                for (var k = 0; k < Math.min(3, divTeams.length); k++) {
                    var dt = divTeams[k]
                    standingsFlatModel.append({
                        type:   "team",
                        label:  "",
                        abbrev: dt.teamAbbrev   ? (dt.teamAbbrev.default   || dt.teamAbbrev)   : "?",
                        city:   dt.placeName    ? (dt.placeName.default    || dt.placeName)     : "",
                        gp:     dt.gamesPlayed  || 0,
                        w:      dt.wins         || 0,
                        l:      dt.losses       || 0,
                        ot:     dt.otLosses     || 0,
                        pts:    dt.points       || 0
                    })
                }
            }
            var wc = []
            for (var w = 0; w < confTeams.length; w++) {
                if (confTeams[w].divisionSequence > 3) wc.push(confTeams[w])
                // fallback : si divisionSequence absent, prendre wildcardSequence
                else if (!confTeams[w].divisionSequence && confTeams[w].wildcardSequence) wc.push(confTeams[w])
            }
            wc.sort(function(a,b){
                if (b.points !== a.points) return b.points - a.points
                return b.wins - a.wins
            })
            standingsFlatModel.append({ type: "wcHeader", label: i18n("Wild Card"),
                abbrev:"", city:"", gp:0, w:0, l:0, ot:0, pts:0 })
            for (var wci = 0; wci < wc.length; wci++) {
                // Séparateur après les 2 spots Wild Card (positions 7 et 8)
                if (wci === 2) {
                    standingsFlatModel.append({ type: "wcSeparator", label: "",
                        abbrev:"", city:"", gp:0, w:0, l:0, ot:0, pts:0 })
                }
                var wt = wc[wci]
                standingsFlatModel.append({
                    type:   "team",
                    label:  "",
                    abbrev: wt.teamAbbrev  ? (wt.teamAbbrev.default  || wt.teamAbbrev)  : "?",
                    city:   wt.placeName   ? (wt.placeName.default   || wt.placeName)   : "",
                    gp:     wt.gamesPlayed || 0,
                    w:      wt.wins        || 0,
                    l:      wt.losses      || 0,
                    ot:     wt.otLosses    || 0,
                    pts:    wt.points      || 0
                })
            }
        }
    }

    onStandingsDataChanged: buildStandingsModel()


    fullRepresentation: Item {
        implicitWidth:  root.isDesktop ? 400 : 440
        implicitHeight: root.isDesktop ? 520 : 520
        // En mode desktop, le widget est redimensionnable — pas de contrainte max
        Layout.fillWidth:  root.isDesktop
        Layout.fillHeight: root.isDesktop

        // ── Vue desktop enrichie (cartes de matchs) ──────────────────────
        Loader {
            anchors.fill: parent
            active: root.isDesktop
            visible: root.isDesktop && !root.detailOpen && !root.standingsOpen
            sourceComponent: desktopRepresentation
        }


        // Vue détail d'un match
        ScrollView {
            id: detailScrollView
            anchors.fill: parent
            visible: root.detailOpen && !root.scheduleOpen && !root.standingsOpen
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
                        text: i18n('✕')
                        flat: true
                        onClicked: {
                            root.detailOpen = false
                            root.expanded = false
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: i18n('Standings')
                        icon.name: 'view-list-symbolic'
                        flat: true
                        onClicked: {
                            root.standingsOpen = true
                            fetchStandings()
                        }
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
                        Item {
                            width: 100; height: 100
                            anchors.horizontalCenter: parent.horizontalCenter
                            Image {
                                anchors.fill: parent
                                source: root.teamLogoUrl(root.detailAway)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                gesturePolicy: TapHandler.ReleaseWithinBounds
                                onTapped: root.openSchedule(root.detailAway)
                            }
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
                        // Pastille : seulement pour les matchs terminés (FINAL)
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.detailStatus === 'FINAL'
                            radius: 5
                            color: statusColor(root.detailStatus)
                            opacity: 0.95
                            width: detailBadgeCol.implicitWidth + 10
                            height: detailBadgeCol.implicitHeight + 6
                            Column {
                                id: detailBadgeCol
                                anchors.centerIn: parent
                                spacing: 0
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: badgeLine1(root.detailStatus, '', root.detailPType,
                                                     root.detailPeriod, root.detailRemain,
                                                     root.detailStart, root.detailHome, root.detailInterm)
                                    color: 'white'; font.pixelSize: 10; font.bold: true
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: text !== ''
                                    text: badgeLine2(root.detailStatus, root.detailStart, root.detailHome)
                                    color: 'white'; font.pixelSize: 9; opacity: 0.85
                                }
                            }
                        }
                        // LIVE : période et temps restant en texte simple
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.detailStatus === 'LIVE'
                            spacing: 2
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: badgeLine1(root.detailStatus, '', root.detailPType,
                                                 root.detailPeriod, root.detailRemain,
                                                 root.detailStart, root.detailHome, root.detailInterm)
                                font.pixelSize: 13; font.bold: true
                                color: Kirigami.Theme.textColor
                            }
                            // Compte à rebours intermission depuis API
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: root.detailInterm && root.detailIntermRemain !== ''
                                text: root.detailIntermRemain
                                font.pixelSize: 18; font.bold: true
                                color: Kirigami.Theme.textColor
                            }
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: text !== ''
                                text: badgeLine2(root.detailStatus, root.detailStart, root.detailHome)
                                font.pixelSize: 11
                                color: Kirigami.Theme.disabledTextColor
                            }
                        }
                    }

                    // Local
                    Column {
                        spacing: 4
                        Layout.alignment: Qt.AlignVCenter
                        Item {
                            width: 100; height: 100
                            anchors.horizontalCenter: parent.horizontalCenter
                            Image {
                                anchors.fill: parent
                                source: root.teamLogoUrl(root.detailHome)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                gesturePolicy: TapHandler.ReleaseWithinBounds
                                onTapped: root.openSchedule(root.detailHome)
                            }
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
                    font.pixelSize: 15
                    Layout.alignment: Qt.AlignHCenter
                }
                Label {
                    visible: !root.detailLoading && root.detailError !== ''
                    text: root.detailError
                    color: 'tomato'; font.pixelSize: 14
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                // ── Avantage numérique ───────────────────────────────────
                Rectangle {
                    id: ppBanner
                    Layout.alignment: Qt.AlignHCenter
                    property var sit: root.parseSituation(
                                          root.detailSituationCode,
                                          root.detailAway,
                                          root.detailHome)
                    visible: sit !== null
                    width:  ppBannerContent.implicitWidth + 20
                    height: ppBannerContent.implicitHeight + 10
                    radius: 6
                    color: (sit && sit.ppTeam)
                           ? root.teamColor(sit.ppTeam)
                           : Kirigami.Theme.highlightColor
                    Column {
                        id: ppBannerContent
                        anchors.centerIn: parent
                        spacing: 2
                        // Ligne AN / 4v4 / 3v3
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6
                            Text {
                                text: ppBanner.sit ? ppBanner.sit.ppType : ''
                                font.pixelSize: 14; font.bold: true
                                color: 'white'
                            }
                            Text {
                                visible: ppBanner.sit && !ppBanner.sit.even
                                text: ppBanner.sit
                                      ? ((ppBanner.sit.ppTeam || '') + '  '
                                         + ppBanner.sit.awaySkaters + 'v'
                                         + ppBanner.sit.homeSkaters)
                                      : ''
                                font.pixelSize: 14
                                color: 'white'
                            }
                        }
                        // Filet vide
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 4
                            visible: ppBanner.sit !== null && ppBanner.sit.emptyNet
                            Text { text: '🥅'; font.pixelSize: 13 }
                            Text {
                                text: ppBanner.sit && ppBanner.sit.enTeam
                                      ? ppBanner.sit.enTeam : ''
                                font.pixelSize: 13; font.bold: true
                                color: 'white'
                            }
                        }
                    }
                }

                // ── Punitions actives ────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 3
                    visible: root.detailStatus === 'LIVE' && !root.detailInterm
                             && (root.detailPenaltyBoxAway !== '[]'
                                 || root.detailPenaltyBoxHome !== '[]')

                    // Fonction locale : formater secondes en M:SS
                    function fmtPen(secs) {
                        var m = Math.floor(secs / 60)
                        var s = secs % 60
                        return m + ':' + (s < 10 ? '0' : '') + s
                    }

                    Repeater {
                        model: {
                            var rows = []
                            var pa = []
                            var ph = []
                            try { pa = JSON.parse(root.detailPenaltyBoxAway) } catch(e) {}
                            try { ph = JSON.parse(root.detailPenaltyBoxHome) } catch(e) {}
                            var maxLen = Math.max(pa.length, ph.length)
                            for (var i = 0; i < maxLen; i++) {
                                rows.push({
                                    away: pa[i] || null,
                                    home: ph[i] || null
                                })
                            }
                            return rows
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            // Colonne visiteur
                            Rectangle {
                                Layout.preferredWidth: 120
                                height: penAwayCol.implicitHeight + 6
                                radius: 4
                                visible: modelData.away !== null
                                color: root.teamColor(root.detailAway)
                                opacity: 0.85
                                Column {
                                    id: penAwayCol
                                    anchors.centerIn: parent
                                    spacing: 0
                                    Text {
                                        text: modelData.away
                                              ? '#' + modelData.away.sweaterNumber
                                                + ' ' + modelData.away.name.default
                                              : ''
                                        color: root.teamTextColor(root.detailAway)
                                        font.pixelSize: 12; font.bold: true
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: modelData.away
                                              ? parent.parent.parent.parent.fmtPen(modelData.away.secondsRemaining)
                                              : ''
                                        color: root.teamTextColor(root.detailAway)
                                        font.pixelSize: 11
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }
                            // Icône centre
                            Label {
                                text: '🚫'
                                font.pixelSize: 14
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                            // Colonne local
                            Rectangle {
                                Layout.preferredWidth: 120
                                height: penHomeCol.implicitHeight + 6
                                radius: 4
                                visible: modelData.home !== null
                                color: root.teamColor(root.detailHome)
                                opacity: 0.85
                                Column {
                                    id: penHomeCol
                                    anchors.centerIn: parent
                                    spacing: 0
                                    Text {
                                        text: modelData.home
                                              ? '#' + modelData.home.sweaterNumber
                                                + ' ' + modelData.home.name.default
                                              : ''
                                        color: root.teamTextColor(root.detailHome)
                                        font.pixelSize: 12; font.bold: true
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: modelData.home
                                              ? parent.parent.parent.parent.fmtPen(modelData.home.secondsRemaining)
                                              : ''
                                        color: root.teamTextColor(root.detailHome)
                                        font.pixelSize: 11
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Tirs au but (mise en évidence) ───────────────────────
                RowLayout {
                    visible: !root.detailLoading && root.detailStats['sog'] !== undefined
                    Layout.fillWidth: true
                    spacing: 0
                    Label {
                        text: root.detailStats['sog'] ? String(root.detailStats['sog'].away) : ''
                        font.pixelSize: 25; font.bold: true
                        color: teamColorAdapted(root.detailAway)
                        Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter
                    }
                    Label {
                        text: i18n('Shots on Goal')
                        font.pixelSize: 14
                        color: Kirigami.Theme.disabledTextColor
                        Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                    }
                    Label {
                        text: root.detailStats['sog'] ? String(root.detailStats['sog'].home) : ''
                        font.pixelSize: 25; font.bold: true
                        color: teamColorAdapted(root.detailHome)
                        Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter
                    }
                }

                // ── Séparateur ───────────────────────────────────────────
                Rectangle {
                    visible: !root.detailLoading && Object.keys(root.detailStats).length > 0
                    Layout.fillWidth: true; height: 1; radius: 1
                    gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.teamColor(root.detailAway) }
                            GradientStop { position: 1.0; color: root.teamColor(root.detailHome) }
                        }
                        opacity: 0.6
                }

                // ── Stats d'équipe (sans SOG, déjà affiché ci-dessus) ─────
                ColumnLayout {
                    visible: !root.detailLoading && Object.keys(root.detailStats).length > 0
                    Layout.fillWidth: true
                    spacing: 2

                    // En-têtes colonnes
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: root.detailAway; font.bold: true; font.pixelSize: 15; color: teamColorAdapted(root.detailAway); Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter }
                        Label { text: ''; Layout.fillWidth: true }
                        Label { text: root.detailHome; font.bold: true; font.pixelSize: 15; color: teamColorAdapted(root.detailHome); Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter }
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
                            Label { text: modelData.away; font.pixelSize: 15; font.bold: true; color: Kirigami.Theme.textColor; Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter }
                            Label { text: modelData.label; font.pixelSize: 14; color: Kirigami.Theme.disabledTextColor; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                            Label { text: modelData.home; font.pixelSize: 15; font.bold: true; color: Kirigami.Theme.textColor; Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter }
                        }
                    }
                }

                // ── Buts ─────────────────────────────────────────────────
                Rectangle {
                    visible: !root.detailLoading
                    Layout.fillWidth: true; height: 1; radius: 1
                    gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.teamColor(root.detailAway) }
                            GradientStop { position: 1.0; color: root.teamColor(root.detailHome) }
                        }
                        opacity: 0.6
                }

                Label {
                    visible: !root.detailLoading && root.detailStatus !== 'UPCOMING'
                    text: i18n('Goals')
                    font.bold: true; font.pixelSize: 15
                    color: Kirigami.Theme.textColor
                    Layout.alignment: Qt.AlignHCenter
                }

                // ── Preview match à venir ────────────────────────────
                ColumnLayout {
                    visible: !root.detailLoading && root.detailStatus === 'UPCOMING'
                    Layout.fillWidth: true
                    spacing: 6

                    // Heure du match
                    Label {
                        visible: root.detailStart > 0
                        Layout.alignment: Qt.AlignHCenter
                        text: root.detailStart > 0
                            ? Qt.formatTime(new Date(root.detailStart), "hh:mm") + "  ·  "
                              + root.localeDateLong(root.detailStart)
                            : ""
                        font.pixelSize: 15; font.bold: true
                        color: Kirigami.Theme.textColor
                    }

                    // Aréna
                    Label {
                        visible: (root.pvVenue || '') !== ''
                        Layout.alignment: Qt.AlignHCenter
                        text: root.pvVenue || ''
                        font.pixelSize: 14; opacity: 0.6
                        color: Kirigami.Theme.disabledTextColor
                    }

                    // Séparateur
                    Rectangle {
                        Layout.fillWidth: true; height: 1; radius: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.teamColor(root.detailAway) }
                            GradientStop { position: 1.0; color: root.teamColor(root.detailHome) }
                        }
                        opacity: 0.6
                    }

                    // Série saison
                    Label {
                        visible: root.pvSeriesTotal || false
                        Layout.alignment: Qt.AlignHCenter
                        text: i18n("Season series") + " :  "
                              + root.detailAway + "  "
                              + (root.pvSeriesAway || 0)
                              + " – "
                              + (root.pvSeriesHome || 0)
                              + "  " + root.detailHome
                        font.pixelSize: 14; font.bold: true
                        color: Kirigami.Theme.textColor
                    }

                    // Séparateur
                    Rectangle {
                        Layout.fillWidth: true; height: 1; radius: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.teamColor(root.detailAway) }
                            GradientStop { position: 1.0; color: root.teamColor(root.detailHome) }
                        }
                        opacity: 0.6
                    }

                    // Fiches saison
                    Item {
                        Layout.fillWidth: true
                        height: fichesRow.implicitHeight
                        RowLayout {
                            id: fichesRow
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 32
                            // Visiteur
                            ColumnLayout {
                                spacing: 2
                                Label { Layout.alignment: Qt.AlignHCenter
                                        text: root.pvAwayRecord || '–'
                                        font.pixelSize: 18; font.bold: true
                                        color: root.teamColorAdapted(root.detailAway) }
                                Label { Layout.alignment: Qt.AlignHCenter
                                        text: i18n("Record")
                                        font.pixelSize: 11; opacity: 0.35
                                        color: Kirigami.Theme.disabledTextColor }
                            }
                            // Local
                            ColumnLayout {
                                spacing: 2
                                Label { Layout.alignment: Qt.AlignHCenter
                                        text: root.pvHomeRecord || '–'
                                        font.pixelSize: 18; font.bold: true
                                        color: root.teamColorAdapted(root.detailHome) }
                                Label { Layout.alignment: Qt.AlignHCenter
                                        text: i18n("Record")
                                        font.pixelSize: 11; opacity: 0.35
                                        color: Kirigami.Theme.disabledTextColor }
                            }
                        }
                    }

                    // Séparateur
                    Rectangle {
                        Layout.fillWidth: true; height: 1; radius: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.teamColor(root.detailAway) }
                            GradientStop { position: 1.0; color: root.teamColor(root.detailHome) }
                        }
                        opacity: 0.6
                    }

                    // Leaders points — titre
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        visible: (root.pvAwayLeaders || []).length > 0
                                 || (root.pvHomeLeaders || []).length > 0
                        text: i18n("Points leaders (last 5 games)")
                        font.pixelSize: 12; font.bold: true; opacity: 0.6
                        color: Kirigami.Theme.disabledTextColor
                    }

                    // Leaders côte à côte
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: (root.pvAwayLeaders || []).length > 0
                                 || (root.pvHomeLeaders || []).length > 0

                        // Leaders visiteur
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 3
                            Repeater {
                                model: root.pvAwayLeaders || []
                                delegate: ColumnLayout {
                                    Layout.fillWidth: true; spacing: 0
                                    Label {
                                        Layout.fillWidth: true
                                        text: {
                                            var lbl = modelData.cat === 'points' ? i18n('PTS')
                                                    : modelData.cat === 'goals'   ? i18n('Goals')
                                                    : i18n('Assists')
                                            return lbl + ' : ' + modelData.value
                                        }
                                        font.pixelSize: 11; font.bold: true; opacity: 0.35
                                        color: Kirigami.Theme.disabledTextColor
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        font.pixelSize: 14
                                        color: root.teamColorAdapted(root.detailAway)
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        // Séparateur vertical
                        Rectangle {
                            width: 1; Layout.fillHeight: true
                            color: Kirigami.Theme.textColor; opacity: 0.15
                        }

                        // Leaders local
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 3
                            Repeater {
                                model: root.pvHomeLeaders || []
                                delegate: ColumnLayout {
                                    Layout.fillWidth: true; spacing: 0
                                    Label {
                                        Layout.fillWidth: true
                                        text: {
                                            var lbl = modelData.cat === 'points' ? i18n('PTS')
                                                    : modelData.cat === 'goals'   ? i18n('Goals')
                                                    : i18n('Assists')
                                            return lbl + ' : ' + modelData.value
                                        }
                                        font.pixelSize: 11; font.bold: true; opacity: 0.35
                                        color: Kirigami.Theme.disabledTextColor
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        font.pixelSize: 14
                                        color: root.teamColorAdapted(root.detailHome)
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    // Séparateur
                    Rectangle {
                        visible: root.pvAwayGoalie !== null
                                 || root.pvHomeGoalie !== null
                        Layout.fillWidth: true; height: 1; radius: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.teamColor(root.detailAway) }
                            GradientStop { position: 1.0; color: root.teamColor(root.detailHome) }
                        }
                        opacity: 0.6
                    }

                    // Gardiens probables
                    Label {
                        visible: root.pvAwayGoalie !== null
                                 || root.pvHomeGoalie !== null
                        Layout.alignment: Qt.AlignHCenter
                        text: i18n("Probable goalies")
                        font.pixelSize: 12; font.bold: true; opacity: 0.6
                        color: Kirigami.Theme.disabledTextColor
                    }

                    Item {
                        Layout.fillWidth: true
                        visible: root.pvAwayGoalie !== null || root.pvHomeGoalie !== null
                        height: goaliesRow.implicitHeight
                        RowLayout {
                            id: goaliesRow
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 24
                            // Gardien visiteur
                            ColumnLayout {
                                spacing: 1
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.pvAwayGoalie ? root.pvAwayGoalie.name : '–'
                                    font.pixelSize: 14; font.bold: true
                                    color: root.teamColorAdapted(root.detailAway)
                                }
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.pvAwayGoalie ? root.pvAwayGoalie.record : ''
                                    font.pixelSize: 12; opacity: 0.7
                                    color: Kirigami.Theme.disabledTextColor
                                }
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.pvAwayGoalie
                                        ? (root.pvAwayGoalie.gaa + " MOY  " + root.pvAwayGoalie.svPct + " %SV") : ''
                                    font.pixelSize: 12; opacity: 0.7
                                    color: Kirigami.Theme.disabledTextColor
                                }
                            }
                            Rectangle {
                                width: 1; height: 40
                                color: Kirigami.Theme.textColor; opacity: 0.15
                            }
                            // Gardien local
                            ColumnLayout {
                                spacing: 1
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.pvHomeGoalie ? root.pvHomeGoalie.name : '–'
                                    font.pixelSize: 14; font.bold: true
                                    color: root.teamColorAdapted(root.detailHome)
                                }
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.pvHomeGoalie ? root.pvHomeGoalie.record : ''
                                    font.pixelSize: 12; opacity: 0.7
                                    color: Kirigami.Theme.disabledTextColor
                                }
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.pvHomeGoalie
                                        ? (root.pvHomeGoalie.gaa + " MOY  " + root.pvHomeGoalie.svPct + " %SV") : ''
                                    font.pixelSize: 12; opacity: 0.7
                                    color: Kirigami.Theme.disabledTextColor
                                }
                            }
                        }
                    }

                    Item { height: 4 }
                }

                // Liste des buts groupés par période
                Repeater {
                    model: root.detailStatus !== 'UPCOMING' ? root.detailGoalsByPeriod : []
                    delegate: Item {
                        Layout.fillWidth: true
                        implicitHeight: modelData.isPeriodHeader ? periodRow.implicitHeight + 10
                                      : goalRow.implicitHeight + 4

                        // ── En-tête de période ──────────────────────────
                        RowLayout {
                            id: periodRow
                            visible: modelData.isPeriodHeader
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                            spacing: 8

                            Rectangle {
                                height: 1; Layout.fillWidth: true
                                color: Kirigami.Theme.textColor; opacity: 0.2
                            }
                            Label {
                                text: modelData.label
                                font.pixelSize: 12; font.bold: true
                                color: Kirigami.Theme.disabledTextColor
                                opacity: 0.8
                            }
                            Rectangle {
                                height: 1; Layout.fillWidth: true
                                color: Kirigami.Theme.textColor; opacity: 0.2
                            }
                        }

                        // ── Ligne de but ────────────────────────────────
                        RowLayout {
                            id: goalRow
                            visible: !modelData.isPeriodHeader
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                            spacing: 6

                            // Aucun but dans cette période
                            Label {
                                visible: modelData.isEmpty || false
                                Layout.fillWidth: true
                                text: i18n('No goals recorded.')
                                font.pixelSize: 14; font.italic: true
                                color: Kirigami.Theme.disabledTextColor
                                horizontalAlignment: Text.AlignHCenter
                            }

                            // But normal
                            Rectangle {
                                visible: !(modelData.isEmpty || false) && modelData.team !== ''
                                radius: 3
                                width: tBadge.implicitWidth + 8; height: tBadge.implicitHeight + 4
                                color: teamColor(modelData.team)
                                Label {
                                    id: tBadge; anchors.centerIn: parent
                                    text: modelData.team
                                    color: teamTextColor(modelData.team)
                                    font.pixelSize: 12; font.bold: true
                                }
                            }
                            Label {
                                visible: !(modelData.isEmpty || false)
                                text: modelData.time || ''
                                font.pixelSize: 12; color: Kirigami.Theme.disabledTextColor
                                Layout.preferredWidth: 48
                            }
                            Column {
                                visible: !(modelData.isEmpty || false)
                                spacing: 1
                                Layout.fillWidth: true
                                Label {
                                    text: (modelData.goalsToDate > 0
                                              ? modelData.scorer + ' (' + modelData.goalsToDate + ')'
                                              : modelData.scorer)
                                        + (modelData.ppg ? '  🔵 PP' : '')
                                        + (modelData.shg ? '  🔴 SH' : '')
                                        + (modelData.en  ? '  🥅 EN' : '')
                                    font.pixelSize: 15; font.bold: true
                                    color: Kirigami.Theme.textColor; wrapMode: Text.Wrap
                                }
                                Label {
                                    visible: modelData.assists && modelData.assists.length > 0
                                    text: {
                                        if (!modelData.assists || modelData.assists.length === 0) return ''
                                        var parts = []
                                        for (var ai = 0; ai < modelData.assists.length; ai++) {
                                            var a = modelData.assists[ai]
                                            parts.push(a.assistsToDate > 0
                                                ? a.name + ' (' + a.assistsToDate + ')'
                                                : a.name)
                                        }
                                        return i18n('Assists: ') + parts.join(', ')
                                    }
                                    font.pixelSize: 12; color: Kirigami.Theme.disabledTextColor
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }
                }

                Item { height: 8 }
                } // ColumnLayout
            } // Item wrapper
        }


        // ── Vue calendrier d'équipe ──────────────────────────────────────
        Item {
            anchors.fill: parent
            visible: root.scheduleOpen

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // ── Barre navigation : [‹ Back]  [🏒 TEAM Titre]  [Stats / Calendrier]
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4; Layout.rightMargin: 4
                    Layout.topMargin: 4; Layout.bottomMargin: 2
                    spacing: 4

                    // Bouton retour
                    Button {
                        text: i18n("‹ Back")
                        icon.name: "go-previous"
                        flat: true
                        onClicked: root.scheduleOpen = false
                    }

                    Item { Layout.fillWidth: true }

                    // Logo équipe + titre centré
                    RowLayout {
                        spacing: 6
                        Layout.alignment: Qt.AlignHCenter
                        Image {
                            source: root.teamLogoUrl(root.scheduleTeam)
                            Layout.preferredWidth: 96
                            Layout.preferredHeight: 96
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                        Label {
                            text: root.scheduleShowStats ? i18n("Stats") : i18n("Schedule")
                            font.bold: true; font.pixelSize: 16
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Bouton bascule Calendrier ↔ Stats
                    Button {
                        text: root.scheduleShowStats ? i18n("Schedule") : i18n("Stats")
                        icon.name: root.scheduleShowStats
                            ? "view-calendar"
                            : "view-statistics"
                        flat: true
                        onClicked: {
                            root.scheduleShowStats = !root.scheduleShowStats
                            // Charger les stats si pas encore fait
                            if (root.scheduleShowStats
                                    && root.scheduleSkaters.length === 0
                                    && !root.scheduleStatsLoading
                                    && root.scheduleStatsError === '') {
                                root.fetchTeamStats(root.scheduleTeam)
                            }
                        }
                    }
                }

                // Chargement / erreur
                Label {
                    Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 20
                    visible: root.scheduleLoading
                    text: i18n("Loading…"); opacity: 0.6; font.italic: true
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 20
                    visible: !root.scheduleLoading && root.scheduleError !== ""
                    text: root.scheduleError
                    color: Kirigami.Theme.negativeTextColor
                }

                // Liste des matchs (mode calendrier)
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !root.scheduleShowStats && !root.scheduleLoading && root.scheduleError === ""
                    contentWidth: availableWidth
                    clip: true

                    ListView {
                        id: schedListView
                        anchors.fill: parent
                        model: root.scheduleGames
                        spacing: 0

                        delegate: Item {
                            width: schedListView.width
                            height: schedRow.implicitHeight + 10

                            // Highlight aujourd'hui
                            readonly property bool isToday: modelData.startMs > 0 &&
                                isSameDay(new Date(modelData.startMs), new Date())
                            readonly property bool isPast: modelData.isFinal

                            Rectangle {
                                anchors.fill: parent
                                color: isToday
                                    ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                                              Kirigami.Theme.highlightColor.g,
                                              Kirigami.Theme.highlightColor.b, 0.12)
                                    : "transparent"
                                radius: 4
                            }

                            RowLayout {
                                id: schedRow
                                width: Math.min(340, parent.width - 16)
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                opacity: isPast ? 0.65 : 1.0

                                // Date
                                Label {
                                    text: modelData.startMs > 0
                                        ? Qt.formatDate(new Date(modelData.startMs), "dd MMM")
                                        : "–"
                                    font.pixelSize: 14
                                    color: Kirigami.Theme.disabledTextColor
                                    Layout.preferredWidth: 42
                                }

                                // Équipe adversaire
                                RowLayout {
                                    spacing: 4
                                    // @ ou vs
                                    Label {
                                        text: modelData.home === root.scheduleTeam ? i18n("vs") : i18n("@")
                                        font.pixelSize: 12; opacity: 0.6
                                        color: Kirigami.Theme.textColor
                                    }
                                    Rectangle {
                                        radius: 3
                                        width: oppLbl.implicitWidth + 8; height: oppLbl.implicitHeight + 4
                                        color: root.teamColor(modelData.home === root.scheduleTeam
                                                              ? modelData.away : modelData.home)
                                        Label {
                                            id: oppLbl
                                            anchors.centerIn: parent
                                            text: modelData.home === root.scheduleTeam
                                                  ? modelData.away : modelData.home
                                            color: root.teamTextColor(modelData.home === root.scheduleTeam
                                                                      ? modelData.away : modelData.home)
                                            font.pixelSize: 12; font.bold: true; font.family: "monospace"
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                // Score ou heure
                                Label {
                                    visible: modelData.isFinal && modelData.ag >= 0
                                    text: modelData.away + "  " + modelData.ag + " – " + modelData.hg + "  " + modelData.home
                                    font.pixelSize: 14; font.bold: true
                                    color: Kirigami.Theme.textColor
                                }
                                Label {
                                    visible: modelData.isLive
                                    text: i18n("LIVE")
                                    font.pixelSize: 14; font.bold: true
                                    color: root.liveColor
                                }
                                Label {
                                    visible: !modelData.isFinal && !modelData.isLive
                                    text: modelData.startMs > 0
                                        ? Qt.formatTime(new Date(modelData.startMs), "hh:mm")
                                        : "–"
                                    font.pixelSize: 14
                                    color: Kirigami.Theme.disabledTextColor
                                }

                                // Résultat W/L
                                Rectangle {
                                    visible: modelData.result !== ''
                                    radius: 3
                                    width: resultLbl.implicitWidth + 8; height: resultLbl.implicitHeight + 4
                                    color: (modelData.result === 'W' || modelData.result === 'OTW')
                                        ? Kirigami.Theme.positiveBackgroundColor
                                        : Qt.rgba(Kirigami.Theme.negativeTextColor.r,
                                                  Kirigami.Theme.negativeTextColor.g,
                                                  Kirigami.Theme.negativeTextColor.b, 0.25)
                                    Label {
                                        id: resultLbl
                                        anchors.centerIn: parent
                                        text: modelData.result
                                        font.pixelSize: 12; font.bold: true
                                        color: (modelData.result === 'W' || modelData.result === 'OTW')
                                            ? Kirigami.Theme.positiveTextColor
                                            : Kirigami.Theme.negativeTextColor
                                    }
                                }
                            }

                            // Séparateur
                            Rectangle {
                                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                height: 1; color: Kirigami.Theme.textColor; opacity: 0.08
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            visible: !root.scheduleLoading && root.scheduleGames.length === 0
                            text: i18n("No games")
                            opacity: 0.5; font.italic: true
                        }
                    }
                }

                // ── Vue stats joueurs (mode stats) ─────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.scheduleShowStats

                    // Chargement / erreur stats
                    Label {
                        anchors.centerIn: parent
                        visible: root.scheduleStatsLoading
                        text: i18n("Loading…"); opacity: 0.6; font.italic: true
                    }
                    Label {
                        anchors.centerIn: parent
                        visible: !root.scheduleStatsLoading && root.scheduleStatsError !== ""
                        text: root.scheduleStatsError
                        color: Kirigami.Theme.negativeTextColor
                        wrapMode: Text.Wrap; width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Liste stats
                    ScrollView {
                        anchors.fill: parent
                        visible: !root.scheduleStatsLoading && root.scheduleStatsError === ""
                        contentWidth: availableWidth
                        clip: true

                        ListView {
                            id: statsListView
                            anchors.fill: parent
                            // Patineurs + séparateur + gardiens
                            model: root.scheduleSkaters.length + root.scheduleGoalies.length
                                   + (root.scheduleGoalies.length > 0 ? 1 : 0)
                            spacing: 0

                            header: Item {
                                width: statsListView.width
                                height: statsHeaderRow.implicitHeight + 6

                                RowLayout {
                                    id: statsHeaderRow
                                    width: Math.min(360, parent.width - 16)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 0

                                    Label { text: i18n("Player"); font.pixelSize: 12; font.bold: true;
                                            opacity: 0.6; Layout.fillWidth: true }
                                    Label { text: i18n("PJ");  font.pixelSize: 12; font.bold: true; opacity: 0.6
                                            Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
                                    Label { text: i18n("B");   font.pixelSize: 12; font.bold: true; opacity: 0.6
                                            Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
                                    Label { text: i18n("A");   font.pixelSize: 12; font.bold: true; opacity: 0.6
                                            Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
                                    Label { text: i18n("PTS"); font.pixelSize: 12; font.bold: true; opacity: 0.6
                                            Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
                                    Label { text: i18n("+/-"); font.pixelSize: 12; font.bold: true; opacity: 0.6
                                            Layout.preferredWidth: 30; horizontalAlignment: Text.AlignRight }
                                }
                                Rectangle {
                                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                    height: 1; color: Kirigami.Theme.textColor; opacity: 0.2
                                }
                            }

                            delegate: Item {
                                id: statsDelegate
                                width: statsListView.width

                                // Index réel dans skaters ou goalies
                                readonly property int nSkaters:  root.scheduleSkaters.length
                                readonly property int nGoalies:  root.scheduleGoalies.length
                                readonly property bool isSep:    index === nSkaters
                                readonly property bool isGoalie: !isSep && index > nSkaters
                                readonly property int  skaterIdx: index
                                readonly property int  goalieIdx: index - nSkaters - 1
                                readonly property var  skater: (!isSep && !isGoalie && index < nSkaters)
                                                               ? root.scheduleSkaters[skaterIdx] : null
                                readonly property var  goalie: (isGoalie && goalieIdx >= 0 && goalieIdx < nGoalies)
                                                               ? root.scheduleGoalies[goalieIdx] : null

                                height: isSep ? sepRow.implicitHeight + 10
                                      : isGoalie ? goalieRow.implicitHeight + 8
                                      : skaterRow.implicitHeight + 8

                                // ── Séparateur gardiens ─────────────────
                                RowLayout {
                                    id: sepRow
                                    visible: isSep
                                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                    anchors.leftMargin: 8; anchors.rightMargin: 8
                                    spacing: 8
                                    Rectangle { height: 1; Layout.fillWidth: true; color: Kirigami.Theme.textColor; opacity: 0.2 }
                                    Label { text: i18n("Goalies"); font.pixelSize: 12; font.bold: true; opacity: 0.6
                                            color: Kirigami.Theme.disabledTextColor }
                                    Rectangle { height: 1; Layout.fillWidth: true; color: Kirigami.Theme.textColor; opacity: 0.2 }
                                }

                                // ── Ligne patineur ──────────────────────
                                RowLayout {
                                    id: skaterRow
                                    visible: !isSep && !isGoalie && skater !== null
                                    width: Math.min(360, statsDelegate.width - 16)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 0

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        Label {
                                            text: skater ? skater.pos : ''
                                            font.pixelSize: 11; font.bold: true
                                            opacity: 0.5
                                            color: Kirigami.Theme.disabledTextColor
                                            Layout.preferredWidth: 16
                                        }
                                        Label {
                                            text: skater ? skater.name : ''
                                            font.pixelSize: 14
                                            color: Kirigami.Theme.textColor
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                    Label { text: skater ? skater.gp : ''; font.pixelSize: 14; opacity: 0.35
                                            Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
                                    Label { text: skater ? skater.g  : ''; font.pixelSize: 14
                                            color: Kirigami.Theme.textColor
                                            Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
                                    Label { text: skater ? skater.a  : ''; font.pixelSize: 14
                                            color: Kirigami.Theme.textColor
                                            Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
                                    Label { text: skater ? skater.pts : ''; font.pixelSize: 15; font.bold: true
                                            color: Kirigami.Theme.textColor
                                            Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
                                    Label {
                                        text: skater ? (skater.plusMinus >= 0 ? '+' + skater.plusMinus : skater.plusMinus) : ''
                                        font.pixelSize: 14
                                        color: skater ? (skater.plusMinus > 0 ? Kirigami.Theme.positiveTextColor
                                                       : skater.plusMinus < 0 ? Kirigami.Theme.negativeTextColor
                                                       : Kirigami.Theme.disabledTextColor) : "transparent"
                                        Layout.preferredWidth: 30; horizontalAlignment: Text.AlignRight
                                    }
                                }

                                // ── Ligne gardien ───────────────────────
                                RowLayout {
                                    id: goalieRow
                                    visible: isGoalie && goalie !== null
                                    width: Math.min(360, statsDelegate.width - 16)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 0

                                    Label {
                                        text: goalie ? goalie.name : ''
                                        font.pixelSize: 14; color: Kirigami.Theme.textColor
                                        elide: Text.ElideRight; Layout.fillWidth: true
                                    }
                                    // PJ
                                    Label { text: goalie ? goalie.gp : ''; font.pixelSize: 14; opacity: 0.35
                                            Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
                                    // V (wins)
                                    Label { text: goalie ? goalie.wins : ''; font.pixelSize: 14
                                            color: Kirigami.Theme.positiveTextColor
                                            Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
                                    // D (losses)
                                    Label { text: goalie ? goalie.losses : ''; font.pixelSize: 14
                                            color: Kirigami.Theme.negativeTextColor
                                            Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
                                    // MOY
                                    Label { text: goalie ? goalie.gaa.toFixed(2) : ''; font.pixelSize: 14
                                            color: Kirigami.Theme.textColor
                                            Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
                                    // %SV
                                    Label { text: goalie ? ('.' + String(Math.round(goalie.svPct * 1000)).padStart(3,'0')) : ''
                                            font.pixelSize: 14; font.bold: true
                                            color: Kirigami.Theme.textColor
                                            Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
                                }

                                // Séparateur ligne
                                Rectangle {
                                    visible: !isSep
                                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                    height: 1; color: Kirigami.Theme.textColor; opacity: 0.06
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Vue classement Wild Card ─────────────────────────────────
        Item {
            anchors.fill: parent
            visible: root.standingsOpen && !root.scheduleOpen

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Barre de retour
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8; Layout.topMargin: 4; Layout.bottomMargin: 2
                    Button {
                        text: root.detailOpen ? i18n("‹ Match") : i18n("‹ Back")
                        icon.name: "go-previous"
                        flat: true
                        onClicked: root.standingsOpen = false
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: i18n("Standings")
                        font.bold: true; font.pixelSize: 16
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Item { Layout.fillWidth: true }
                }

                // Chargement / erreur
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                    visible: root.standingsLoading
                    text: i18n("Loading…")
                    opacity: 0.6; font.italic: true
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                    visible: !root.standingsLoading && root.standingsError !== ""
                    text: root.standingsError
                    color: Kirigami.Theme.negativeTextColor
                }

                // Tableau — les deux conférences générées via JS pur
                // pour éviter les chaînes parent.parent fragiles dans Repeater imbriqués
                ScrollView {
                    id: standingsScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !root.standingsLoading && root.standingsError === ""
                    contentWidth: availableWidth
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    clip: true

                    Item {
                        width: standingsScroll.availableWidth
                        height: standingsScroll.availableHeight

                        ListView {
                        id: standingsListView
                        width: Math.min(340, parent.width)
                        height: parent.height
                        anchors.horizontalCenter: parent.horizontalCenter
                        model: standingsFlatModel
                        interactive: true
                        spacing: 0
                        delegate: Item {
                            // ── Capturer model.* ici — seul endroit où model est accessible
                            property string rType:   model.type   || ""
                            property string rLabel:  model.label  || ""
                            property string rAbbrev: model.abbrev || ""
                            property string rCity:   model.city   || ""
                            property int    rGp:     model.gp     || 0
                            property int    rW:      model.w      || 0
                            property int    rL:      model.l      || 0
                            property int    rOt:     model.ot     || 0
                            property int    rPts:    model.pts    || 0

                            width: standingsListView.width
                            x: 0
                            height: rType === "confHeader"  ? hdrLabel.implicitHeight + 8
                                  : rType === "colHeader"   ? 18
                                  : rType === "team"        ? teamRow.implicitHeight + 6
                                  : rType === "wcSeparator" ? 12
                                  : hdrLabel.implicitHeight + 4   // divHeader / wcHeader

                            // Fond coloré selon le type
                            Rectangle {
                                anchors.fill: parent
                                visible: rType !== "wcSeparator"
                                color: rType === "confHeader" ? Kirigami.Theme.alternateBackgroundColor
                                     : rType === "divHeader"  ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                                                                        Kirigami.Theme.highlightColor.g,
                                                                        Kirigami.Theme.highlightColor.b, 0.15)
                                     : rType === "wcHeader"   ? Qt.rgba(Kirigami.Theme.positiveBackgroundColor.r,
                                                                        Kirigami.Theme.positiveBackgroundColor.g,
                                                                        Kirigami.Theme.positiveBackgroundColor.b, 0.25)
                                     : "transparent"
                            }
                            // Ligne séparatrice Wild Card (entre les pos. 8 et 9)
                            Rectangle {
                                visible: rType === "wcSeparator"
                                anchors.centerIn: parent
                                width: parent.width * 0.85
                                height: 1
                                color: Kirigami.Theme.textColor
                                opacity: 0.35
                            }

                            // Label centré : confHeader / divHeader / wcHeader
                            Label {
                                id: hdrLabel
                                anchors.centerIn: parent
                                visible: rType === "confHeader" || rType === "divHeader" || rType === "wcHeader"
                                text: rLabel
                                font.bold: true
                                font.pixelSize: rType === "confHeader" ? 12 : 10
                                opacity: rType === "confHeader" ? 1.0 : 0.85
                            }

                            // En-tête colonnes
                            RowLayout {
                                anchors { left: parent.left; right: parent.right
                                          verticalCenter: parent.verticalCenter
                                          leftMargin: 6; rightMargin: 6 }
                                visible: rType === "colHeader"
                                spacing: 0
                                Item { width: 38 }  // largeur pastille équipe
                                Label { text: i18n("Team"); font.pixelSize: 12; font.bold: true; opacity: 0.6; Layout.preferredWidth: 44 }
                                Label { Layout.fillWidth: true }
                                Label { text: "GP";  font.pixelSize: 12; font.bold: true; opacity: 0.6; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignHCenter }
                                Label { text: "W";   font.pixelSize: 12; font.bold: true; opacity: 0.6; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
                                Label { text: "L";   font.pixelSize: 12; font.bold: true; opacity: 0.6; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
                                Label { text: "OT";  font.pixelSize: 12; font.bold: true; opacity: 0.6; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
                                Label { text: "PTS"; font.pixelSize: 12; font.bold: true; opacity: 0.6; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                            }

                            // Ligne équipe cliquable → calendrier
                            HoverHandler {
                                enabled: rType === "team"
                                cursorShape: Qt.PointingHandCursor
                            }
                            TapHandler {
                                enabled: rType === "team"
                                acceptedButtons: Qt.LeftButton
                                gesturePolicy: TapHandler.ReleaseWithinBounds
                                onTapped: root.openSchedule(rAbbrev)
                            }
                            RowLayout {
                                id: teamRow
                                anchors { left: parent.left; right: parent.right
                                          verticalCenter: parent.verticalCenter
                                          leftMargin: 6; rightMargin: 6 }
                                visible: rType === "team"
                                spacing: 0
                                Rectangle {
                                    width: abbrLbl.implicitWidth + 8
                                    height: abbrLbl.implicitHeight + 4
                                    radius: 4
                                    color: root.teamColor(rAbbrev)
                                    Label {
                                        id: abbrLbl
                                        anchors.centerIn: parent
                                        text: rAbbrev !== "" ? rAbbrev : "?"
                                        color: root.teamTextColor(rAbbrev)
                                        font.pixelSize: 12; font.bold: true; font.family: "monospace"
                                    }
                                }
                                Label { Layout.leftMargin: 6; text: rCity; font.pixelSize: 14; Layout.fillWidth: true; elide: Text.ElideRight }
                                Label { text: rGp;  font.pixelSize: 14; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignHCenter }
                                Label { text: rW;   font.pixelSize: 14; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
                                Label { text: rL;   font.pixelSize: 14; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
                                Label { text: rOt;  font.pixelSize: 14; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
                                Label { text: rPts; font.pixelSize: 14; font.bold: true; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                            }
                        }
                    } // fin ListView
                    } // fin Item wrapper
                } // fin ScrollView
            }
        }
    }


    // ══════════════════════════════════════════════════════════════════════
    // DESKTOP REPRESENTATION — liste de cartes enrichies, redimensionnable
    // ══════════════════════════════════════════════════════════════════════
    Component {
        id: desktopRepresentation
        Item {
            id: desktopRoot
            implicitWidth:  360
            implicitHeight: Math.max(200, desktopList.contentHeight + desktopHeader.implicitHeight + 16)

            // ── En-tête ─────────────────────────────────────────────────
            Item {
                id: desktopHeader
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: headerRow.implicitHeight + 16

                RowLayout {
                    id: headerRow
                    anchors.centerIn: parent
                    width: Math.min(480, parent.width - 16)
                    spacing: 6

                    Label {
                        text: i18n("NHL Scores")
                        font.bold: true; font.pixelSize: 13
                        color: Kirigami.Theme.textColor
                    }
                    Label {
                        visible: root.lastUpdated instanceof Date
                        text: root.lastUpdated instanceof Date
                            ? Qt.formatTime(root.lastUpdated, "hh:mm") : ""
                        font.pixelSize: 10; opacity: 0.5
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: i18n("Standings")
                        icon.name: "view-list-symbolic"
                        flat: true; font.pixelSize: 10
                        onClicked: { root.standingsOpen = true; fetchStandings() }
                    }
                }
            }

            // Séparateur sous l'en-tête
            Rectangle {
                id: desktopSep
                anchors { top: desktopHeader.bottom; left: parent.left; right: parent.right }
                anchors.topMargin: 2
                height: 1; color: Kirigami.Theme.textColor; opacity: 0.1
            }

            // ── Liste des cartes de matchs ──────────────────────────────
            ListView {
                id: desktopList
                anchors {
                    top: desktopSep.bottom; left: parent.left
                    right: parent.right; bottom: parent.bottom
                }
                anchors.topMargin: 4
                model: todayGames
                spacing: 6
                clip: true

                delegate: Item {
                    width: desktopList.width
                    height: card.implicitHeight + 8

                    // ── Propriétés locales ──────────────────────────────
                    property string dAway:   away       || ""
                    property string dHome:   home       || ""
                    property int    dAg:     ag         || 0
                    property int    dHg:     hg         || 0
                    property string dStatus: statusRole || "UPCOMING"
                    property string dRaw:    rawState   || ""
                    property string dPType:  periodType || ""
                    property int    dPeriod: period     || 0
                    property string dRemain: liveRemain || ""
                    property var    dStart:  start      || 0
                    property string dHome2:  home       || ""
                    property bool   dInterm: inIntermission || false
                    property bool   dBlinkA: { var b = root.blinkingGames[String(gameId)]; return !!(b && (b==='away'||b==='both')) }
                    property bool   dBlinkH: { var b = root.blinkingGames[String(gameId)]; return !!(b && (b==='home'||b==='both')) }

                    // ── Carte ───────────────────────────────────────────
                    Rectangle {
                        id: card
                        readonly property int maxW: 480
                        width: Math.min(maxW, parent.width - 12)
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        implicitHeight: cardCol.implicitHeight + 12
                        radius: 6
                        color: Qt.rgba(Kirigami.Theme.backgroundColor.r,
                                       Kirigami.Theme.backgroundColor.g,
                                       Kirigami.Theme.backgroundColor.b, 0.6)
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                                              Kirigami.Theme.textColor.g,
                                              Kirigami.Theme.textColor.b, 0.1)
                        border.width: 1
                        opacity: dStatus === 'FINAL' ? 0.6 : 1.0

                        // Bandeau BUT récent (flash discret en haut de la carte)
                        Rectangle {
                            id: goalBanner
                            visible: root.blinkingGames[String(gameId)] !== undefined
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: visible ? goalBannerLabel.implicitHeight + 4 : 0
                            radius: 6
                            // Coins bas carrés pour rejoindre le contenu
                            Rectangle {
                                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                height: parent.radius
                                color: parent.color
                            }
                            color: Qt.rgba(Kirigami.Theme.positiveBackgroundColor.r,
                                           Kirigami.Theme.positiveBackgroundColor.g,
                                           Kirigami.Theme.positiveBackgroundColor.b, 0.85)
                            opacity: root.blinkOn ? 1.0 : 0.4
                            Label {
                                id: goalBannerLabel
                                anchors.centerIn: parent
                                text: {
                                    var b = root.blinkingGames[String(gameId)]
                                    if (!b) return ""
                                    var scorer = (b === 'away') ? dAway : (b === 'home') ? dHome : dAway + " / " + dHome
                                    return "🚨  " + i18n("GOAL") + "  —  " + scorer
                                }
                                font.bold: true; font.pixelSize: 11
                                color: Kirigami.Theme.positiveTextColor
                            }
                        }

                        // Contenu principal de la carte
                        ColumnLayout {
                            id: cardCol
                            anchors {
                                top: goalBanner.bottom; left: parent.left
                                right: parent.right; margins: 10
                            }
                            anchors.topMargin: goalBanner.visible ? 6 : 10
                            spacing: 4

                            // ── Ligne principale : équipes + scores ─────
                            // Layout fixe centré : [pastille+score away] [badge statut] [score+pastille home]
                            Item {
                                Layout.fillWidth: true
                                implicitHeight: scoreRow.implicitHeight

                                RowLayout {
                                    id: scoreRow
                                    anchors.centerIn: parent
                                    spacing: 8

                                    // Équipe visiteur : pastille + score
                                    RowLayout {
                                        spacing: 6
                                        Rectangle {
                                            width: awayNameD.implicitWidth + 10
                                            height: awayNameD.implicitHeight + 6
                                            radius: 4
                                            color: root.teamColor(dAway)
                                            opacity: (dBlinkA && !root.blinkOn) ? 0.0 : 1.0
                                            Label {
                                                id: awayNameD
                                                anchors.centerIn: parent
                                                text: dAway
                                                color: root.teamTextColor(dAway)
                                                font.pixelSize: 13; font.bold: true; font.family: "monospace"
                                            }
                                        }
                                        Label {
                                            visible: dStatus !== 'UPCOMING'
                                            text: dStatus !== 'UPCOMING' ? String(dAg) : ""
                                            font.pixelSize: 26; font.bold: true
                                            color: (dStatus === 'LIVE' && dAg > dHg)
                                                ? Kirigami.Theme.positiveTextColor
                                                : Kirigami.Theme.textColor
                                            opacity: (dBlinkA && !root.blinkOn) ? 0.0 : 1.0
                                        }
                                    }

                                    // Pastille statut centrale
                                    Rectangle {
                                        Layout.alignment: Qt.AlignVCenter
                                        radius: 4
                                        color: root.statusColor(dStatus)
                                        opacity: 0.95
                                        width: statusColD.implicitWidth + 10
                                        height: statusColD.implicitHeight + 6
                                        Column {
                                            id: statusColD
                                            anchors.centerIn: parent
                                            spacing: 0
                                            Label {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: root.badgeLine1(dStatus, dRaw, dPType, dPeriod,
                                                                       dRemain, dStart, dHome2, dInterm)
                                                color: "white"; font.pixelSize: 11; font.bold: true
                                            }
                                            Label {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                visible: text !== ''
                                                text: root.badgeLine2(dStatus, dStart, dHome2)
                                                color: "white"; font.pixelSize: 9; opacity: 0.85
                                            }
                                        }
                                    }

                                    // Équipe locale : score + pastille
                                    RowLayout {
                                        spacing: 6
                                        Label {
                                            visible: dStatus !== 'UPCOMING'
                                            text: dStatus !== 'UPCOMING' ? String(dHg) : ""
                                            font.pixelSize: 26; font.bold: true
                                            color: (dStatus === 'LIVE' && dHg > dAg)
                                                ? Kirigami.Theme.positiveTextColor
                                                : Kirigami.Theme.textColor
                                            opacity: (dBlinkH && !root.blinkOn) ? 0.0 : 1.0
                                        }
                                        Rectangle {
                                            width: homeNameD.implicitWidth + 10
                                            height: homeNameD.implicitHeight + 6
                                            radius: 4
                                            color: root.teamColor(dHome)
                                            opacity: (dBlinkH && !root.blinkOn) ? 0.0 : 1.0
                                            Label {
                                                id: homeNameD
                                                anchors.centerIn: parent
                                                text: dHome
                                                color: root.teamTextColor(dHome)
                                                font.pixelSize: 13; font.bold: true; font.family: "monospace"
                                            }
                                        }
                                    }
                                } // RowLayout scoreRow
                            } // Item centrant

                            // ── Ligne secondaire : infos contextuelles ──
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                visible: dStatus === 'LIVE' || dStatus === 'UPCOMING'
                                spacing: 0

                                // Période + temps restant (LIVE)
                                Label {
                                    visible: dStatus === 'LIVE' && !dInterm
                                    Layout.fillWidth: true
                                    text: {
                                        if (dPType === 'OT') return i18n("Overtime")
                                        if (dPType === 'SO') return i18n("Shootout")
                                        var p = dPeriod
                                        var names = [i18n("1st period"), i18n("2nd period"), i18n("3rd period")]
                                        return p >= 1 && p <= 3 ? names[p-1] : i18n("Period") + " " + p
                                    }
                                    font.pixelSize: 10; opacity: 0.7
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Label {
                                    visible: dStatus === 'LIVE' && dInterm
                                    Layout.fillWidth: true
                                    text: {
                                        var p = dPeriod
                                        var names = [i18n("1st intermission"), i18n("2nd intermission"), i18n("3rd intermission")]
                                        return p >= 1 && p <= 3 ? names[p-1] : i18n("Intermission")
                                    }
                                    font.pixelSize: 10; opacity: 0.7
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                // Heure de début (UPCOMING)
                                Label {
                                    visible: dStatus === 'UPCOMING'
                                    Layout.fillWidth: true
                                    text: {
                                        var t = root.upcomingWhenText(dStart, dStatus, dHome2)
                                        return t !== '' ? i18n("Starts at") + " " + t : ""
                                    }
                                    font.pixelSize: 10; opacity: 0.7
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        } // ColumnLayout cardCol
                    } // Rectangle card

                    // Clic sur la carte → vue détail
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        cursorShape: Qt.PointingHandCursor
                        onTapped: root.openDetail(gameId, dAway, dHome, dAg, dHg,
                                                  dStatus, dPType, dPeriod, dRemain, dStart, dInterm, situationCode)
                    }
                } // delegate Item

                // Message si aucun match
                Label {
                    anchors.centerIn: parent
                    visible: desktopList.count === 0
                    text: i18n("No games today")
                    opacity: 0.5; font.italic: true
                }
            } // ListView desktopList

            // ── Vue classement (réutilise le même standingsOpen) ────────
            // Le détail et le classement s'affichent par-dessus via le fullRepresentation
        } // Item desktopRoot
    } // Component desktopRepresentation


}
