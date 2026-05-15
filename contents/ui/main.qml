
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import QtMultimedia
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.notification 1.0 as KNotification

import "logic.js" as Logic
import "components" as Components

PlasmoidItem {
    id: root
    Plasmoid.title: i18n("NHL Scores")

    // Détection panneau vertical (largeur contrainte, hauteur libre)
    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    // Détection mode desktop : formFactor Planar (0) = posé sur le bureau
    readonly property bool isDesktop: Plasmoid.formFactor === PlasmaCore.Types.Planar
    
    // ── Système de Styles Unifié ─────────────────────────────────────
    readonly property var styles: {
        "hubWidth": 400,
        "cardWidth": 480,
        "badge": {
            "radius": 4,
            "fontSize": 10,
            "smallFontSize": 9,
            "desktopFontSize": 12,
            "desktopSmallFontSize": 10
        },
        "teamBadge": {
            "width": 45,
            "height": 28,
            "desktopWidth": 50,
            "desktopHeight": 32,
            "fontSize": 13,
            "desktopFontSize": 15
        },
        "fonts": {
            "main": 14,
            "small": 11,
            "tiny": 9,
            "score": 26,
            "header": 13
        }
    }
    // En mode desktop, on affiche directement le fullRepresentation
    preferredRepresentation: isDesktop ? fullRepresentation : compactRepresentation
    property var favoriteTeams: []
    property string favoriteTeamSound: Plasmoid.configuration.favoriteTeamSound || ''  // legacy
    property var    soundTeams: (Plasmoid.configuration.soundTeams || '').split(',').filter(function(s){return s.length>0})
    property real   soundVolume: Plasmoid.configuration.soundVolume !== undefined ? Plasmoid.configuration.soundVolume : 1.0

    // ── Son + bannière custom pour un but de l'équipe favorite ─────
    MediaPlayer {
        id: sirenSound
        source: Qt.resolvedUrl("../sounds/siren.wav")
        audioOutput: AudioOutput { volume: root.soundVolume }
        onErrorOccurred: {
            // Si le fichier d'équipe est introuvable → fallback sirène
            var fallback = Qt.resolvedUrl("../sounds/siren.wav")
            if (sirenSound.source !== fallback) {
                sirenSound.source = fallback
                sirenSound.play()
            }
        }
    }
    property bool showAllTeams: Plasmoid.configuration.showAllTeams || false
    property int  maxGames:     Plasmoid.configuration.maxGames || 10
    property int  leadersLimit: Plasmoid.configuration.leadersLimit || 10
    property int  franchiseLeadersLimit: Plasmoid.configuration.franchiseLeadersLimit || 10
    onFranchiseLeadersLimitChanged: {
        if (nav.franchiseLeaders && flead.team !== "") {
            fetchFranchiseLeaders(flead.team)
        }
    }
    property int  spacingBetweenGames: Plasmoid.configuration.spacingBetweenGames !== undefined ? Plasmoid.configuration.spacingBetweenGames : 2
    property bool ultraCompact: Plasmoid.configuration.ultraCompact || false
    property int  pastHours:     Plasmoid.configuration.pastHours !== undefined ? Plasmoid.configuration.pastHours : 12
    property int  upcomingHours: Plasmoid.configuration.upcomingHours !== undefined ? Plasmoid.configuration.upcomingHours : 12

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
    property bool showLogos: Plasmoid.configuration.showLogos || false
    property bool showUpcomingTime: (Plasmoid.configuration.showUpcomingTime !== false)
    property string dateMode: Plasmoid.configuration.dateMode || 'local'
    property int  pollInterval:  Plasmoid.configuration.pollInterval || 20
    // ── GESTION DE L'ÉTAT (Groupée) ──────────────────────────────────
    
    readonly property QtObject nav: QtObject {
        property bool standings: false
        property bool leaders:   false
        property bool player:    false
        property bool search:    false
        property bool teamHub:   false
        property bool calendar:  false
        property bool dayView:   false
        property bool bracket:   false
        property bool detail:    false
        property bool schedule:  false
        property bool scheduleShowStats: false
        property bool franchiseLeaders: false
    }

    readonly property QtObject flead: QtObject {
        property bool loading: false
        property string error: ""
        property string team: ""
        property var points: []
        property var goals: []
        property var assists: []
        property var wins: []
        property var sho: []
        property bool filterF: false
        property bool filterD: false
        property bool filterG: false
        property int seasonType: 2
    }

    readonly property QtObject glob: QtObject {
        property bool initialLoading: true
        property date lastUpdated
        property string debugMsg: ""
        property bool   loading: false
        property string error: ""
        property bool   isOffline: false
        property int    pulse: 0
        property int    refreshGen: 0
        property var    penaltiesMap: ({})
        property var prevScores: ({})
        property var    blinkingGames: ({})
        property bool   blinkOn: false
    }

    readonly property QtObject banner: QtObject {
        property string team:   ''
        property string title:  ''
        property string score:  ''
        property string scorer: ''
        property bool   visible: false
    }

    readonly property QtObject std: QtObject {
        property string mode:    'wildcard'
        property string sortKey: 'points'
        property bool   sortAsc: false
        property var    data:    []
        property bool   loading: false
        property string error:   ""
    }

    readonly property QtObject lead: QtObject {
        property bool   loading: false
        property string error:   ""
        property var    points:  []
        property var    goals:   []
        property var    assists: []
        property var    pim:     []
        property var    wins:    []
        property var    sho:     []
        property var    gaa:     []
        property var    svp:     []
        property bool   filterF: false
        property bool   filterD: false
        property bool   filterG: false
        property bool   filterR: false
        property string season: {
            var now = new Date()
            var y = now.getFullYear()
            if (now.getMonth() < 8) y--
            return y + String(y+1)
        }
        property int    seasonType: 2
    }

    readonly property QtObject ply: QtObject {
        property int    playerId: 0
        property string from:    'leaders'
        property bool   loading: false
        property string error:   ""
        property var    data:    null
    }

    readonly property QtObject brk: QtObject {
        property bool loading: false
        property string error: ""
        property var data: null
        property var scores: ({})
        property var series: ({})
        property int pulse: 0
    }

    readonly property QtObject srch: QtObject {
        property bool   loading: false
        property string error:   ""
        property string query:   ""
        property var    results: []
    }

    readonly property QtObject hub: QtObject {
        property string code:      ''
        property string from:      ''
        property bool   loading:   false
        property string error:     ''
        property string record:    ''
        property string coach:     ''
        property string standing:  ''
        property string fullName:  ''
        property int    w:         0
        property int    l:         0
        property int    ot:        0
        property int    pts:       0
        property int    gp:        0
        readonly property int stanleyCups: Logic.getStanleyCupsCount(code)
        property var    lastGames: []
        property var    nextGame:  null
    }

    readonly property QtObject day: QtObject {
        property string date:    ''
        property bool   loading: false
        property string error:   ''
        property var    games:   []
    }

    readonly property QtObject cal: QtObject {
        property int    year:    new Date().getFullYear()
        property int    month:   new Date().getMonth()
        property var    counts:  ({})
        property bool   loading: false
    }

    readonly property QtObject det: QtObject {
        property int    gameId:   0
        property string away:     ''
        property string home:     ''
        property int    ag:       0
        property int    hg:       0
        property string status:   ''
        property string pType:    ''
        property int    period:   0
        property string remain:   ''
        property var    start:    0
        property bool   interm:   false
        property string intermRemain: ''
        property string penaltyBoxAway: '[]'
        property string penaltyBoxHome: '[]'
        property var    goals:    []
        property var    stats:    ({})
        property var    threeStars: []
        property var    penalties:  []
        property var    teamComparison: []
        property string view:     'goals'
        property string sitCode:  '1551'
        property bool   isPlayoff: false
        property string seriesRound: ''
        property int    seriesGameNum: 0
        property bool   loading:  false
        property string error:    ''
        property string venue:    ''
        property int    seriesAway: 0
        property int    seriesHome: 0
        property int    seriesAwaySeason: 0
        property int    seriesHomeSeason: 0
        property int    seriesAwayPlayoffs: 0
        property int    seriesHomePlayoffs: 0
        property bool   seriesTotal: false
        property var    h2hGames: []
        property var    h2hSeason: []
        property var    awayRecord: ({})
        property var    homeRecord: ({})
        property var    awayLeaders: []
        property var    homeLeaders: []
        property var    awayGoalie: null
        property var    homeGoalie: null
        property var    playerMap:  ({})

        readonly property var goalsByPeriod: {
            var result = []
            var seenPeriods = []
            var maxPeriod = (status === 'LIVE' || status === 'FINAL') ? (period || 0) : 0
            for (var i = 0; i < goals.length; i++) {
                var p = goals[i].period
                if (seenPeriods.indexOf(p) === -1) seenPeriods.push(p)
            }
            for (var pn = 1; pn <= Math.min(maxPeriod, 3); pn++) {
                var pStr = String(pn)
                if (seenPeriods.indexOf(pStr) === -1) seenPeriods.push(pStr)
            }
            seenPeriods.sort(function(a, b) {
                var order = { '1':1, '2':2, '3':3, 'OT':4, 'SO':99 }
                function rank(p) {
                    if (order[p] !== undefined) return order[p]
                    var m = p.match(/^(\d+)OT$/)
                    return m ? 3 + parseInt(m[1]) : 98
                }
                return rank(a) - rank(b)
            })
            for (var pi = 0; pi < seenPeriods.length; pi++) {
                var per = seenPeriods[pi]
                var label = per === 'SO' ? i18n('Shootout')
                          : per === 'OT' ? i18n('Overtime')
                          : /^\d+OT$/.test(per) ? (per.replace('OT','') + 'e ' + i18n('Overtime'))
                          : per === '1'  ? i18n('1st period')
                          : per === '2'  ? i18n('2nd period')
                          : per === '3'  ? i18n('3rd period')
                          : i18n('Period') + ' ' + per
                result.push({ isPeriodHeader: true, label: label, period: per, isEmpty: false })
                var count = 0
                for (var gi = 0; gi < goals.length; gi++) {
                    if (goals[gi].period === per) {
                        var gobj = goals[gi]
                        result.push({ isPeriodHeader: false, label: '',
                                      period: gobj.period, time: gobj.time,
                                      team: gobj.team, scorer: gobj.scorer,
                                      scorerId: gobj.scorerId || 0,
                                      goalsToDate: gobj.goalsToDate,
                                      assists: gobj.assists,
                                      ppg: gobj.ppg, shg: gobj.shg, en: gobj.en,
                                      highlightId: gobj.highlightId || 0,
                                      isEmpty: false })
                        count++
                    }
                }
                if (count === 0) {
                    result.push({ isPeriodHeader: false, label: i18n('No goals recorded.'),
                                  period: per, isEmpty: true })
                }
            }
            return result
        }

        readonly property var penaltiesByPeriod: {
            var result = []
            var seenPeriods = []
            for (var i = 0; i < penalties.length; i++) {
                var p = penalties[i].period
                if (seenPeriods.indexOf(p) === -1) seenPeriods.push(p)
            }
            seenPeriods.sort(function(a, b) {
                var order = { '1':1, '2':2, '3':3, 'OT':4, 'SO':99 }
                function rank(p) {
                    if (order[p] !== undefined) return order[p]
                    var m = p.match(/^(\d+)OT$/)
                    return m ? 3 + parseInt(m[1]) : 98
                }
                return rank(a) - rank(b)
            })
            for (var pi = 0; pi < seenPeriods.length; pi++) {
                var per = seenPeriods[pi]
                var label = per === 'SO' ? i18n('Shootout')
                          : per === 'OT' ? i18n('Overtime')
                          : /^\d+OT$/.test(per) ? (per.replace('OT','') + 'e ' + i18n('Overtime'))
                          : per === '1'  ? i18n('1st period')
                          : per === '2'  ? i18n('2nd period')
                          : per === '3'  ? i18n('3rd period')
                          : i18n('Period') + ' ' + per
                result.push({ isPeriodHeader: true, label: label })
                for (var gi = 0; gi < penalties.length; gi++) {
                    if (penalties[gi].period === per) {
                        var pen = penalties[gi]
                        result.push({
                            isPeriodHeader: false,
                            time:     pen.time,
                            team:     pen.team,
                            player:   pen.player,
                            number:   pen.number,
                            duration: pen.duration,
                            descKey:  pen.descKey,
                            playerId: pen.playerId || 0
                        })
                    }
                }
            }
            return result
        }
    }

    readonly property QtObject sch: QtObject {
        property string team:      ''
        property var    games:     []
        property var    gamesMap:  ({})
        property bool   loading:   false
        property string error:     ''
        property var    skaters:   []
        property var    goalies:   []
        property bool   statsLoading: false
        property string statsError:   ''
        property string season: {
            var now = new Date()
            var y = now.getFullYear()
            if (now.getMonth() < 8) y--
            return y + String(y+1)
        }
        property int    seasonType: 2
    }

    Timer {
        id: pulseTimer
        interval: 60000
        repeat: true
        running: true
        onTriggered: glob.pulse++
    }

    // Action contextuelle (menu clic-droit)
    function action_refreshNow() { refresh() }

    Component.onCompleted: {
        Logic.initializeCache(Plasmoid.configuration)
        
        // 1. Restaurer le bracket depuis le cache immédiatement
        try {
            var cached = JSON.parse(Plasmoid.configuration.cacheData || "{}")
            if (cached && cached.bracket) {
                processBracketData(cached.bracket)
            }
        } catch(e) { }

        try {
            Plasmoid.setAction("refreshNow", i18n("Refresh now"), "view-refresh")
        } catch(e) {
            // setAction non disponible sur cette version de Plasma — ignoré
        }
        updateFavoriteTeams()
        refresh()

        // 2. Mettre à jour le bracket via le réseau en arrière-plan
        fetchPlayoffBracket()
    }

    property alias todayGamesModel: todayGames
    property alias statusBadgeComponent: statusBadge
    property alias teamColumnComponent: teamColumn
    property alias teamRowInlineComponent: teamRowInline
    property alias standingsFlatModelAlias: standingsFlatModel

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

    function fetchStandings() {
        if (std.loading) return
        std.loading = true
        std.error   = ""
        Logic.ApiService.getStandings(function(err, d) {
            std.loading = false
            if (err) {
                std.error = String(err)
            } else {
                std.data = d.standings || []
            }
        })
    }

    function openStandings() {
        nav.standings = true
        nav.leaders   = false
        nav.search    = false
        nav.bracket   = false
        nav.schedule  = false
        nav.calendar  = false
        nav.dayView   = false
        nav.franchiseLeaders = false
        fetchStandings()
    }

    function openLeaders() {
        nav.leaders   = true
        nav.standings = false
        nav.search    = false
        nav.bracket   = false
        nav.schedule  = false
        nav.calendar  = false
        nav.dayView   = false
        nav.franchiseLeaders = false
        fetchLeaders()
    }

    // ── Clignotement de score sur but ────────────────────────────────────
    // Snapshot des scores avant chaque refresh : { gameId -> { ag, hg } }
    // Heure de début d'intermission par gameId : { gameId: wallClockMs }

    // Durée de clignotement en secondes (config)
    property int blinkDuration: Plasmoid.configuration.blinkDuration || 10

    // État ON/OFF du clignotement (bascule à 500ms)
    // Timer de bascule visuelle
    Timer {
        id: blinkToggleTimer
        interval: 500
        repeat: true
        running: Object.keys(glob.blinkingGames).length > 0
        onTriggered: glob.blinkOn = !glob.blinkOn
    }

    // Démarre le clignotement pour un match pendant blinkDuration secondes
    function startBlink(gameId, scorer) {
        let b = Object.assign({}, glob.blinkingGames)
        // scorer : 'away', 'home', ou 'both' — pour flasher la bonne pastille
        b[gameId] = scorer || 'both'
        glob.blinkingGames = b

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
                let b = Object.assign({}, glob.blinkingGames)
                delete b[targetGameId]
                glob.blinkingGames = b
                destroy()
            }
        }
    }

    property bool showCompactDesktop: Plasmoid.configuration.showCompactDesktop
    property var popupRef: null
    property bool notificationsAllTeams: Plasmoid.configuration.notificationsAllTeams || false
    property bool enableNotifications: (Plasmoid.configuration.enableNotifications !== false)

    KNotification.Notification {
        id: systemGoalNotification
        componentName: "plasma_applet_org.dany.nhlscores"
        eventId: "goal"
        iconName: "org.dany.nhlscores"
    }

    function triggerGoalBlink(away, home, ag, hg, prevAg, prevHg, gameId) {
        if (ag > prevAg || hg > prevHg) {
            let scorer = (ag > prevAg && hg > prevHg) ? 'both'
                       : (ag > prevAg) ? 'away' : 'home'
            startBlink(gameId, scorer)

            // ── Notifications Système (KNotification) ──────────────────
            if (root.enableNotifications) {
                let showNotify = root.notificationsAllTeams
                if (!showNotify) {
                    // Vérifier si une des équipes est favorite
                    if (root.favoriteTeams.indexOf(away) >= 0 || root.favoriteTeams.indexOf(home) >= 0) {
                        showNotify = true
                    }
                }

                if (showNotify) {
                    let teamWhoScored = (scorer === 'away') ? away : (scorer === 'home' ? home : "")
                    let title = i18n("GOAL!")
                    if (teamWhoScored !== "") title = i18n("GOAL: %1", teamWhoScored)
                    
                    systemGoalNotification.title = title
                    systemGoalNotification.text = away + " " + ag + " - " + hg + " " + home

                    // Utiliser le logo de l'équipe si disponible
                    if (teamWhoScored !== "") {
                        let logoPath = Qt.resolvedUrl("../logos/" + teamWhoScored + ".svg").toString()
                        // KNotification accepte les chemins locaux (sans file://)
                        systemGoalNotification.iconName = logoPath.replace("file://", "")
                    } else {
                        systemGoalNotification.iconName = "org.dany.nhlscores"
                    }
                    
                    systemGoalNotification.sendEvent()
                }
            }

            // Vérifier toutes les équipes avec son activé
            let teams = root.soundTeams
            // Compatibilité legacy
            if (teams.length === 0 && root.favoriteTeamSound) teams = [root.favoriteTeamSound]
            for (let ti = 0; ti < teams.length; ti++) {
                let favTeam = teams[ti]
                // Seulement si l'équipe est aussi dans les favoris suivis
                if (root.favoriteTeams.length > 0 && root.favoriteTeams.indexOf(favTeam) < 0) continue
                let favScored = (scorer === 'away' && away === favTeam)
                             || (scorer === 'home' && home === favTeam)
                             || (scorer === 'both' && (away === favTeam || home === favTeam))
                if (favScored) {
                    let scorerName = ''
                    if (nav.detail && det.gameId === gameId && det.goals.length > 0) {
                        let lastGoal = det.goals[det.goals.length - 1]
                        if (lastGoal && lastGoal.scorer) scorerName = lastGoal.scorer
                    }
                    root.sendGoalNotification(favTeam, away, home, ag, hg, scorerName)
                }
            }
        }
    }

    // Son + bannière custom pour un but de l'équipe favorite
    function sendGoalNotification(favTeam, away, home, ag, hg, scorerName) {
        // Jouer le son de l'équipe (contents/sounds/{team}.mp3) ou sirène par défaut
        var teamSound = Qt.resolvedUrl("../sounds/" + favTeam.toLowerCase() + ".mp3")
        sirenSound.source = teamSound
        sirenSound.stop()
        sirenSound.play()

        // Mettre à jour les propriétés root pour la bannière
        let isAway   = (away === favTeam)
        let opponent = isAway ? home : away
        let favScore = isAway ? ag : hg
        let oppScore = isAway ? hg : ag
        let isFr     = Qt.locale().name.startsWith("fr")

        banner.team   = favTeam
        banner.title  = "🚨 " + (isFr ? "BUT!!" : "GOAL!!")
        banner.score  = favTeam + "  " + favScore + " – " + oppScore + "  " + opponent
        banner.scorer = scorerName || ''
        banner.visible = true
        bannerAutoHide.restart()
    }

    Timer {
        id: bannerAutoHide
        interval: 6000; repeat: false
        onTriggered: banner.visible = false
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
        interval: (hasActiveGames() || glob.isOffline) ? root.pollInterval * 1000 : 300000
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
        property int lastDay: new Date().getDate()
        onTriggered: {
            let now = new Date()
            let dayChanged = (now.getDate() !== lastDay)
            let isUpdateHour = (now.getHours() === 0 || now.getHours() === 4) && now.getMinutes() < 2

            if (dayChanged || isUpdateHour) {
                lastDay = now.getDate()
                cal.year = now.getFullYear()
                cal.month = now.getMonth()
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

    function teamColorAdapted(code, opponentCode, isAway, forText) {
        let bg = (typeof Kirigami !== 'undefined' && Kirigami.Theme) ? Kirigami.Theme.backgroundColor : "#ffffff"
        return Logic.getTeamColorAdapted(code, opponentCode, isAway, forText, bg)
    }

    function teamTextColor(teamCode, opponentCode, isAway) {
        let bg = (typeof Kirigami !== 'undefined' && Kirigami.Theme) ? Kirigami.Theme.backgroundColor : "#ffffff"
        return Logic.getTeamTextColor(teamCode, opponentCode, isAway, bg)
    }

    function teamBadgeTextColor(teamCode) {
        return Logic.getTeamBadgeTextColor(teamCode)
    }

    // Retourne 'white' ou 'black' selon la luminance de la couleur d'équipe
    // Formule WCAG relative luminance : L = 0.2126R + 0.7152G + 0.0722B
    function blinkOpacity(gameId, side) {
        var b = glob.blinkingGames[String(gameId)]
        return (b && (b === side || b === 'both') && !glob.blinkOn) ? 0.0 : 1.0
    }

    // Retourne les deux couleurs optimales pour le dégradé away→home
    function bestGradientColors(away, home) {
        var ap = Logic.getTeamColor(away, '#888888')
        var hp = Logic.getTeamColor(home, '#888888')
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

    function pad2(n) {
        return (n < 10 ? "0" : "") + n
    }

    function dateISO(d) {
        return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate())
    }

    function isSameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
    }

    function localTimeStr(ms) {
        var d = new Date(ms)
        return Qt.formatTime(d, Qt.DefaultLocaleShortDate)
    }
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
    // (Logique parseSituation déplacée vers logic.js)

    // ── Vue journée complète ─────────────────────────────────────────

    // ── Leaders de la ligue ─────────────────────────────────────────

    // URL du logo NHL selon thème clair/foncé
    function teamLogoUrl(abbrev) {
        if (!abbrev) return ''
        var bg = Kirigami.Theme.backgroundColor
        var L  = 0.2126*bg.r + 0.7152*bg.g + 0.0722*bg.b
        var variant = L < 0.5 ? 'dark' : 'light'
        return Qt.resolvedUrl("../logos/" + abbrev + "_" + variant + ".svg")
    }

    function historicalTeamLogoUrl(abbrev, season) {
        if (!abbrev) return ''
        var displayCode = Logic.getHistoricalLogo(abbrev, season)
        return teamLogoUrl(displayCode)
    }

    function getHistoricalTeamName(abbrev, season) {
        if (!abbrev) return ''
        var displayCode = Logic.getHistoricalLogo(abbrev, season)
        if (displayCode === abbrev) return ''
        var names = {
            'HFD': 'Hartford Whalers', 'QUE': 'Nordiques de Québec', 'WIN': 'Winnipeg Jets',
            'MNS': 'Minnesota North Stars', 'ATL': 'Atlanta Thrashers', 'CLR': 'Colorado Rockies',
            'KCS': 'Kansas City Scouts', 'AFM': 'Atlanta Flames'
        }
        return names[displayCode] || ''
    }
    function resolveNHLAbbrev(teamCommonName) {
        return Logic.resolveNHLAbbrev(teamCommonName)
    }

    function parseSituation(code, away, home) {
        return Logic.parseSituation(code, away, home)
    }

    function dayViewTimeLabel(msUTC, homeTeam) {
        return Logic.getDayViewTimeLabel(msUTC, homeTeam, root.dateMode)
    }

    function venueTimeStr(msUTC, homeTeam) {
        return Logic.venueTimeStr(msUTC, homeTeam)
    }

    function fetchLeagueByDates(days, cb){
        let acc=[]
        let pending=days.length
        let errors=[]
        let offlineCount = 0
        if(pending===0){ cb(acc, errors); return }
        days.forEach(function(d){
            Logic.ApiService.getScoreboard(dateISO(d), function(err, data, isOffline){
                if (isOffline) offlineCount++
                if(err){ errors.push(String(err)) }
                else if (data && data.games){ acc = acc.concat(data.games) }
                pending--
                if(pending===0) {
                    glob.isOffline = (offlineCount > 0 || errors.length > 0)
                    cb(acc, errors)
                }
            })
        })
    }

    readonly property var allTeams: ['ANA','UTA','BOS','BUF','CAR','CBJ','CGY','CHI','COL','DAL','DET','EDM','FLA','LAK','MIN','MTL','NJD','NSH','NYI','NYR','OTT','PHI','PIT','SEA','SJS','STL','TBL','TOR','VAN','VGK','WPG','WSH']

    function fetchTeamNow(teamCodes, cb){
        let acc=[]
        let errors=[]
        let pending=teamCodes.length
        let offlineCount = 0
        if(pending===0){ cb(acc, errors); return }
        teamCodes.forEach(function(team){
            Logic.ApiService.getScoreboardNow(team, function(err, data, isOffline){
                if (isOffline) offlineCount++
                if (err) { errors.push(String(err)) }
                else if (data && data.gamesByDate) {
                    for (let i=0;i<data.gamesByDate.length;i++){
                        const gbd = data.gamesByDate[i]
                        if (gbd && gbd.games) acc = acc.concat(gbd.games)
                    }
                }
                pending--
                if (pending===0) {
                    glob.isOffline = (offlineCount > 0 || errors.length > 0)
                    cb(acc, errors)
                }
            })
        })
    }

    function refresh() {
        glob.refreshGen++
        const myGen = glob.refreshGen

        // Rafraîchir les détails du match actif si ouvert
        if (nav.detail && det.gameId !== 0) {
            fetchDetail(det.gameId)
        }

        // Rafraîchir le tableau des séries si ouvert
        if (nav.bracket) {
            fetchPlayoffBracket()
        }

        // Rafraîchir les classements si ouverts
        if (nav.standings) {
            fetchStandings()
        }

        let now = new Date()
        let startTime = new Date(now.getTime() - (root.pastHours * 3600000))
        let endTime = new Date(now.getTime() + (root.upcomingHours * 3600000))


        // On récupère les dates ISO uniques couvrant l'intervalle [startTime, endTime]
        let days = []
        let iter = new Date(startTime.getTime())
        iter.setHours(0,0,0,0)
        let lastDate = new Date(endTime.getTime())
        lastDate.setHours(0,0,0,0)

        while (iter <= lastDate) {
            days.push(new Date(iter.getTime()))
            iter.setDate(iter.getDate() + 1)
        }

        if (days.length === 0) {
            return
        }

        fetchLeagueByDates(days, function(leagueGames, leagueErrs) {
            if (myGen !== glob.refreshGen) return
            
            // On envoie tout à buildFromRawGames qui fera le tri final
            if (leagueGames && leagueGames.length) {
                buildFromRawGames(leagueGames, leagueErrs)
            } else {
                const pool = showAllTeams ? allTeams : favoriteTeams
                fetchTeamNow(pool, function(teamGames, teamErrs) {
                    if (myGen !== glob.refreshGen) return
                    buildFromRawGames(teamGames || [], (leagueErrs||[]).concat(teamErrs||[]))
                })
            }
        })
    }

    function isScoreSet(g) { return Logic.isScoreSet(g) }

    function statusFromGame(g) { return Logic.getStatusFromGame(g) }

    function statusSuffix(rawState, periodType) {
        var labels = { OT: i18n("OT"), SO: i18n("SO") }
        return Logic.getStatusSuffix(rawState, periodType, Plasmoid.configuration.showOvertimeSuffix, labels)
    }

    function liveClockText(periodType, period, timeRemaining) {
        var labels = { first: i18n("1st"), second: i18n("2nd"), third: i18n("3rd"), SO: i18n("SO") }
        return Logic.getLiveClockText(periodType, period, timeRemaining, labels)
    }

    function livePeriodText(periodType, period) {
        return Logic.getLivePeriodText(periodType, period, {
            "SO": i18n("SO"),
            "first": i18n("1st"),
            "second": i18n("2nd"),
            "third": i18n("3rd")
        })
    }

    function liveTimeText(periodType, period, timeRemaining) {
        if (periodType === "SO" || !timeRemaining) return ""
        return timeRemaining
    }



    function statusColor(st){
 return st==='LIVE' ? liveColor : (st==='FINAL' ? finalColor : upcomingColor) }

    // Ligne 1 de la pastille : Période (ou Final/Heure)
    function badgeLine1(st, rawState, periodType, period, liveRemain, startMs, homeTeam, intermission, intermissionRemain) {
        var suffix = statusSuffix(rawState, periodType)
        if (st === 'LIVE') {
            if (intermission) return 'INT'
            var pText = livePeriodText(periodType, period)
            return pText !== '' ? pText + suffix : 'LIVE' + suffix
        }
        if (st === 'FINAL') return i18n('Final')
        var t = upcomingWhenText(startMs, st, homeTeam)
        return t !== '' ? t : i18n('Upcoming')
    }

    // Ligne 2 de la pastille : Temps restant (ou OT/SO)
    function badgeLine2(st, startMs, homeTeam, periodType, period, liveRemain, intermission, intermissionRemain) {
        if (st === 'LIVE') {
            if (intermission) return intermissionRemain || ""
            return liveTimeText(periodType, period, liveRemain)
        }
        if (st === 'FINAL') {
            if (periodType === 'OT') return 'OT'
            if (periodType === 'SO') return i18n('SO')
        }
        return ''
    }

    function fetchClock(gameId, modelIndex) {
        Logic.ApiService.getGameClock(gameId, function(err, data) {
            if (err) return
            try {
                if (data && data.clock) {
                    todayGames.setProperty(modelIndex, "liveRemain", data.clock.timeRemaining || "")
                    todayGames.setProperty(modelIndex, "inIntermission", data.clock.inIntermission ? true : false)
                    
                    // Mise à jour de la vue détail si ouverte
                    if (nav.detail && det.gameId === gameId) {
                        det.remain = data.clock.timeRemaining || ""
                        det.interm = data.clock.inIntermission ? true : false
                        det.intermRemain = data.clock.inIntermission ? (data.clock.timeRemaining || "") : ""
                    }

                    if (data.clock.inIntermission)
                        todayGames.setProperty(modelIndex, "intermissionRemain", data.clock.timeRemaining || "")
                    else
                        todayGames.setProperty(modelIndex, "intermissionRemain", "")
                    if (data.situationCode) {
                        todayGames.setProperty(modelIndex, "situationCode", data.situationCode)
                        if (nav.detail && det.gameId === gameId) det.sitCode = data.situationCode
                    } else if (data.clock && data.clock.inIntermission) {
                        // En entracte, on ne vide pas la situation si elle est manquante dans l'API clock
                    } else {
                        todayGames.setProperty(modelIndex, "situationCode", "1551")
                        if (nav.detail && det.gameId === gameId) det.sitCode = "1551"
                    }
                }
                if (data && data.displayPeriod) {
                    todayGames.setProperty(modelIndex, "period", data.displayPeriod)
                    if (nav.detail && det.gameId === gameId) {
                        det.period = data.displayPeriod
                    }
                }
            } catch(e) {
                console.warn("fetchClock parse error for game", gameId, e)
            }
        })
    }


    // Calcule situationCode depuis summary.iceSurface du landing
    // Format : [awayGoalie][awaySkaters][homeSkaters][homeGoalie]
    function fetchSituationFromLanding(gameId) {
        Logic.ApiService.getGameLanding(gameId, function(err, data) {
            if (err) return
            try {
                // PROTECTION ENTRACTE : Si le match est en entracte, on ne vide PAS la situation
                // car iceSurface est souvent vide dans l'API pendant la pause.
                if (data.clock && data.clock.inIntermission) return

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
                // Valeurs hors limites = changement de ligne transitoire → ignorer
                if (as > 6 || hs > 6 || as < 0 || hs < 0) return
                // 6 patineurs avec gardien en jeu = transitoire
                if (as === 6 && ag === 1) return
                if (hs === 6 && hg === 1) return
                // Seulement si situation spéciale (pas 5v5 normal ni données vides)
                if ((as === hs && as >= 5 && ag === 1 && hg === 1)
                    || (as === 0 || hs === 0)) {
                    // Situation normale — reset
                    var pm0 = glob.penaltiesMap
                    pm0[String(gameId)] = { away: [], home: [] }
                    glob.penaltiesMap = pm0
                    for (let j = 0; j < todayGames.count; j++) {
                        if (todayGames.get(j).gameId == gameId) {
                            todayGames.setProperty(j, "situationCode", "1551")
                            todayGames.setProperty(j, "penaltyTime", "")
                            if (nav.detail && det.gameId == gameId) {
                                det.sitCode = "1551"
                                det.penaltyBoxAway = "[]"
                                det.penaltyBoxHome = "[]"
                            }
                            break
                        }
                    }
                    return
                }
                let code = String(ag) + String(as) + String(hs) + String(hg)
                let pba = at.penaltyBox || []
                let pbh = ht.penaltyBox || []
                
                // Calcul du temps restant de la punition qui se termine le plus tôt
                let minTime = ""
                let allPens = pba.concat(pbh)
                if (allPens.length > 0) {
                    let minSecs = 9999
                    for (let pi = 0; pi < allPens.length; pi++) {
                        let pen = allPens[pi]
                        let s = -1
                        let t = pen.timeRemaining || pen.timeLeft || pen.timeRemainingInPeriod
                        
                        if (t && typeof t === 'string' && t.indexOf(':') > 0) {
                            let parts = t.split(':')
                            s = parseInt(parts[0]) * 60 + parseInt(parts[1])
                        } else if (pen.secondsRemaining !== undefined) {
                            s = parseInt(pen.secondsRemaining)
                        }

                        if (s >= 0 && s < minSecs) {
                            minSecs = s
                            // Convertir en M:SS
                            let mins = Math.floor(s / 60)
                            let secs = s % 60
                            minTime = mins + ":" + (secs < 10 ? "0" : "") + secs
                        }
                    }
                }

                // Stocker dans glob.penaltiesMap (évite String vs List dans ListModel)
                var pm = glob.penaltiesMap
                pm[String(gameId)] = { away: pba, home: pbh }
                glob.penaltiesMap = pm
                for (let j = 0; j < todayGames.count; j++) {
                    if (todayGames.get(j).gameId == gameId) {
                        todayGames.setProperty(j, "situationCode", code)
                        todayGames.setProperty(j, "penaltyTime", minTime)
                        if (nav.detail && det.gameId == gameId) {
                            det.sitCode = code
                            var entry = glob.penaltiesMap[String(gameId)] || {away:[],home:[]}
                            det.penaltyBoxAway = JSON.stringify(entry.away)
                            det.penaltyBoxHome = JSON.stringify(entry.home)
                        }
                        break
                    }
                }
            } catch(e) { console.warn("landing error:", e) }
        })
    }

    // ── Vue journée complète ─────────────────────────────────────────
    function openDayView(dateISO) {
        nav.dayView    = true
        expanded       = true
        day.date       = dateISO
        day.loading    = true
        day.error      = ''
        day.games      = []
        // Fermer les autres vues
        nav.standings  = false
        nav.leaders    = false
        nav.bracket    = false
        nav.teamHub    = false
        nav.detail     = false
        nav.schedule   = false
        nav.player     = false
        nav.search     = false
        nav.calendar   = false
        nav.franchiseLeaders = false
        fetchDayView(dateISO)
    }

    function openSimulationBracket() {
        nav.bracket = true
        brk.loading = true
        brk.error = ""
        
        // Fermer les autres vues pour éviter les conflits de visibilité
        nav.standings = false
        nav.leaders   = false
        nav.search    = false
        nav.teamHub   = false
        nav.player    = false
        nav.calendar  = false
        nav.dayView   = false
        nav.schedule  = false
        nav.franchiseLeaders = false

        // S'assurer que le classement est chargé
        if (!std.data || std.data.length === 0) {
            Logic.ApiService.getStandings(function(err, data) {
                if (err) {
                    brk.loading = false
                    brk.error = i18n("Standings not available for simulation")
                } else {
                    std.data = data.standings
                    brk.data = Logic.simulatePlayoffs(std.data)
                    brk.loading = false
                }
            })
        } else {
            brk.data = Logic.simulatePlayoffs(std.data)
            brk.loading = false
        }
    }

    function fetchDayView(dateISO) {
        // Choisir l'endpoint selon la date
        var todayISO = root.dateISO(new Date())
        var isFuture = dateISO > todayISO
        var apiCall = isFuture
            ? function(d, cb) { Logic.ApiService.getSchedule(d, cb) }
            : function(d, cb) { Logic.ApiService.getScore(d, cb) }

        apiCall(dateISO, function(err, data) {
                day.loading = false
                if (err) { day.error = String(err); return }

                // /v1/schedule/{date} → data.gameWeek[0].games
                // /v1/score/{date}    → data.games
                var games = []
                if (isFuture) {
                    var week = data.gameWeek || []
                    for (var wi = 0; wi < week.length; wi++) {
                        if (week[wi].date === dateISO) {
                            games = week[wi].games || []
                            break
                        }
                    }
                    // Fallback si la date exacte n'est pas trouvée
                    if (games.length === 0 && week.length > 0)
                        games = week[0].games || []
                } else {
                    games = data.games || []
                }

                if (games.length === 0) { day.error = "No data"; return }

                day.games = games.map(function(g) {
                    var st = statusFromGame(g)
                    var per = g.periodDescriptor || {}
                    var clk = g.clock || {}
                    return {
                        gameId:    g.id || 0,
                        away:      g.awayTeam && g.awayTeam.abbrev || '',
                        home:      g.homeTeam && g.homeTeam.abbrev || '',
                        ag:        g.awayTeam && g.awayTeam.score  || 0,
                        hg:        g.homeTeam && g.homeTeam.score  || 0,
                        start:     g.startTimeUTC || '',
                        status:    st,
                        period:    per.number || 0,
                        periodType: per.periodType || '',
                        remain:    clk.timeRemaining || '',
                        inIntermission: clk.inIntermission || false,
                        intermissionRemain: clk.inIntermission ? (clk.timeRemaining || "") : "",
                        awayLogo:  g.awayTeam && g.awayTeam.logo || '',
                        homeLogo:  g.homeTeam && g.homeTeam.logo || '',
                        homeAbbrev: g.homeTeam && g.homeTeam.abbrev || ''
                    }
                }).sort(function(a, b) {
                    return new Date(a.start) - new Date(b.start)
                })
            })
    }

    // ── Affrontements saison entre 2 équipes ─────────────────────────
    function fetchH2H(away, home) {
        det.h2hGames = []
        Logic.ApiService.getTeamSchedule(away, function(err, data) {
                if (err || !data) return
                var games = data.games || []
                var h2h = []
                for (var i = 0; i < games.length; i++) {
                    var g = games[i]
                    var aw = g.awayTeam ? (g.awayTeam.abbrev || '') : ''
                    var hm = g.homeTeam ? (g.homeTeam.abbrev || '') : ''
                    // Garder seulement les matchs entre ces 2 équipes
                    if ((aw === away && hm === home) || (aw === home && hm === away)) {
                        var st = (g.gameState || '').toUpperCase()
                        var isFinal   = st === 'FINAL' || st === 'OFF' || st === 'OFFICIAL'
                        var isUpcoming = st === 'FUT' || st === 'PRE'
                        var awS = g.awayTeam ? (g.awayTeam.score || 0) : 0
                        var hmS = g.homeTeam ? (g.homeTeam.score || 0) : 0
                        h2h.push({
                            away:      aw,
                            home:      hm,
                            awayScore: awS,
                            homeScore: hmS,
                            start:     g.startTimeUTC || '',
                            final:     isFinal,
                            upcoming:  isUpcoming
                        })
                    }
                }
                // Trier par date
                h2h.sort(function(a, b) { return new Date(a.start) - new Date(b.start) })
                det.h2hGames = h2h
                // Recalculer le bilan
                var awW = 0, hmW = 0
                for (var j = 0; j < h2h.length; j++) {
                    if (!h2h[j].final) continue
                    if (h2h[j].away === away) {
                        if (h2h[j].awayScore > h2h[j].homeScore) awW++; else hmW++
                    } else {
                        if (h2h[j].homeScore > h2h[j].awayScore) awW++; else hmW++
                    }
                }
                det.seriesAway  = awW
                det.seriesHome  = hmW
                det.seriesTotal = h2h.length > 0
            })
    }

    // ── Résolution des playerIds pour les pénalités ─────────────────
    function resolvePenaltyIds(pmap) {
        if (!pmap || Object.keys(pmap).length === 0) return
        if (!det.penalties || det.penalties.length === 0) return
        var updated = []
        for (var i = 0; i < det.penalties.length; i++) {
            var pen = det.penalties[i]
            var key = pen.team + '-' + pen.number
            updated.push({
                period:   pen.period,
                time:     pen.time,
                team:     pen.team,
                player:   pen.player,
                playerId: pmap[key] || pen.playerId || 0,
                number:   pen.number,
                duration: pen.duration,
                type:     pen.type,
                descKey:  pen.descKey,
                drawnBy:  pen.drawnBy
            })
        }
        det.penalties = updated
    }

    // ── Traduction des infractions ───────────────────────────────────
    function penaltyDesc(key) {
        var map = {
            'slashing':               i18n('Slashing'),
            'hooking':                i18n('Hooking'),
            'roughing':               i18n('Roughing'),
            'high-sticking':          i18n('High sticking'),
            'tripping':               i18n('Tripping'),
            'interference':           i18n('Interference'),
            'holding':                i18n('Holding'),
            'holding-the-stick':      i18n('Holding the stick'),
            'elbowing':               i18n('Elbowing'),
            'charging':               i18n('Charging'),
            'boarding':               i18n('Boarding'),
            'cross-checking':         i18n('Cross-checking'),
            'delay-of-game':          i18n('Delay of game'),
            'unsportsmanlike-conduct':i18n('Unsportsmanlike conduct'),
            'too-many-men':           i18n('Too many men'),
            'goalie-interference':    i18n('Goalie interference'),
            'misconduct':             i18n('Misconduct'),
            'game-misconduct':        i18n('Game misconduct'),
            'fighting':               i18n('Fighting'),
            'instigating':            i18n('Instigating'),
            'diving':                 i18n('Diving'),
            'embellishment':          i18n('Embellishment'),
            'kneeing':                i18n('Kneeing'),
            'spearing':               i18n('Spearing'),
            'butt-ending':            i18n('Butt-ending'),
            'checking-from-behind':   i18n('Checking from behind'),
            'head-contact':           i18n('Head contact'),
            'match-penalty':          i18n('Match penalty'),
        }
        return map[key] || key.replace(/-/g, ' ')
    }

    // ── Calendrier — nombre de matchs par jour ───────────────────────
    function fetchCalendarMonth(year, month) {
        cal.loading = true
        var counts = {}
        var pending = 0
        var daysInMonth = new Date(year, month + 1, 0).getDate()

        // Calculer les dates de début de chaque semaine du mois
        var fetchDates = []
        for (var d = 1; d <= daysInMonth; d += 7) {
            fetchDates.push(year + "-" + root.pad2(month + 1) + "-" + root.pad2(d))
        }

        pending = fetchDates.length
        function done() {
            pending--
            if (pending <= 0) {
                cal.loading = false
                cal.counts = counts
            }
        }

        for (var fi = 0; fi < fetchDates.length; fi++) {
            (function(isoDate) {
                Logic.ApiService.getSchedule(isoDate, function(err, data) {
                        if (!err && data) {
                            var week = data.gameWeek || []
                            for (var wi = 0; wi < week.length; wi++) {
                                var day = week[wi]
                                if (day.date) {
                                    var parts = day.date.split('-')
                                    if (parseInt(parts[1]) - 1 === month
                                            && parseInt(parts[0]) === year) {
                                        counts[day.date] = day.numberOfGames
                                            || (day.games ? day.games.length : 0)
                                    }
                                }
                            }
                        }
                        done()
                    })
            })(fetchDates[fi])
        }
    }

    // ── Recherche de joueurs ─────────────────────────────────────────
    function openSearch() {
        nav.search    = true
        srch.results = []
        srch.error   = ''
        srch.query   = ''
        // Fermer les autres overlays
        nav.standings = false
        nav.leaders   = false
        nav.bracket   = false
        nav.schedule  = false
        nav.calendar  = false
        nav.dayView   = false
    }

    function fetchSearch(query) {
        if (!query || query.length < 2) return
        srch.loading = true
        srch.error   = ''
        srch.results = []
        Logic.ApiService.searchPlayers(query, function(err, data) {
            srch.loading = false
            if (err) { srch.error = String(err); return }
            
            // data peut être soit le format search (players:[]) soit le format fallback (liste directe)
            var players = data.players || (Array.isArray(data) ? data : (data.data || []))
            if (!Array.isArray(players) || players.length === 0) { srch.error = i18n("No results"); return }
            
            srch.results = players.map(function(p) {
                return {
                    id:       p.playerId || p.id || 0,
                    name:     p.skaterFullName || p.goalieFullName || p.name || p.fullName || (p.firstName ? p.firstName.default + ' ' + p.lastName.default : ''),
                    team:     p.teamAbbrev || p.currentTeamAbbrev || p.teamAbbrevs || '',
                    position: p.positionCode || p.position || '',
                    active:   p.active === 1 || p.isActive !== false,
                    headshot: p.headshot || ''
                }
            })
            if (srch.results.length === 0) srch.error = i18n("No results")
        })
    }

    // ── Leaders de la ligue ─────────────────────────────────────────
    function fetchLeaders() {
        fetchLeadersFiltered(lead.filterF, lead.filterD, lead.filterG, lead.filterR)
    }

    function fetchLeadersFiltered(fF, fD, fG, fR) {
        lead.loading = true
        lead.error   = ''
        let pending = 2
        function done() { pending--; if (pending <= 0) lead.loading = false }

        var anyPos = fF || fD || fG  // filtre de position actif
        // Recrues : endpoint séparé ci-dessous
        var limit = fD ? 250 : (anyPos ? 100 : root.leadersLimit)

        // Fonction de filtrage local
        function applyFilter(arr, isGoalie) {
            if (!arr) return []
            var result = arr
            // Filtre recrue
            if (fR) result = result.filter(function(p) { return p.rookie === true })
            // Filtre position (patineurs seulement)
            if (!isGoalie) {
                if (fF && !fD) result = result.filter(function(p) {
                    var pos = (p.position || '').toUpperCase()
                    return pos === 'C' || pos === 'L' || pos === 'R'
                })
                else if (fD && !fF) result = result.filter(function(p) {
                    return (p.position || '').toUpperCase() === 'D'
                })
            }
            // Gardiens : masqués si F ou D actif (sans G)
            if (isGoalie && (fF || fD) && !fG) return []
            // Patineurs : masqués si G seul
            if (!isGoalie && fG && !fF && !fD) return []
            return result.slice(0, root.leadersLimit)
        }

        var noPos = !fF && !fD  // aucun filtre de position = tous
        var loadSkaters = !fG || fF || fD  // charger patineurs sauf si G seul
        var loadGoalies = !fF && !fD || fG  // charger gardiens sauf si F ou D seul

        let skaterPending = loadSkaters ? 4 : 0
        function skaterDone() { skaterPending--; if (skaterPending <= 0) done() }

        if (loadSkaters) {
            Logic.ApiService.getSkaterLeaders(limit, fR, "points", lead.season, lead.seasonType, function(err, data) {
                if (err) { lead.error = String(err) }
                var pts = Logic.parseLeaders(data.points || [], "points")
                lead.points = applyFilter(pts, false)
                skaterDone()
            })
            Logic.ApiService.getSkaterLeaders(limit, fR, "goals", lead.season, lead.seasonType, function(err, data) {
                if (!err) lead.goals = applyFilter(Logic.parseLeaders(data.goals || [], "goals"), false)
                skaterDone()
            })
            Logic.ApiService.getSkaterLeaders(limit, fR, "assists", lead.season, lead.seasonType, function(err, data) {
                if (!err) lead.assists = applyFilter(Logic.parseLeaders(data.assists || [], "assists"), false)
                skaterDone()
            })
            Logic.ApiService.getSkaterLeaders(limit, fR, "penaltyMins", lead.season, lead.seasonType, function(err, data) {
                if (!err) lead.pim = applyFilter(Logic.parseLeaders(data.penaltyMins || [], "penaltyMins"), false)
                skaterDone()
            })
        } else {
            lead.points = []; lead.goals = []
            lead.assists = []; lead.pim = []
            done()
        }

        if (loadGoalies) {
            Logic.ApiService.getGoalieLeaders(limit, fR, "wins,shutouts,goalsAgainstAverage,savePctg", lead.season, lead.seasonType, function(err, data) {
                if (err) { done(); return }
                lead.wins = applyFilter(Logic.parseLeaders(data.wins || [], "wins"), true)
                lead.sho  = applyFilter(Logic.parseLeaders(data.shutouts || [], "shutouts"), true)
                lead.gaa = applyFilter(Logic.parseLeaders(data.goalsAgainstAverage || [], "gaa"), true)
                lead.svp = applyFilter(Logic.parseLeaders(data.savePctg || [], "savePctg"), true)
                done()
            })
        } else {
            lead.wins = []; lead.sho = []
            lead.gaa = []; lead.svp = []
            done()
        }
    }

    // ── Fiche joueur ─────────────────────────────────────────────────
    function fetchPlayer(playerId) {
        if (!playerId) return
        ply.loading = true
        ply.error   = ''
        ply.data    = null
        Logic.ApiService.getPlayerLanding(playerId, function(err, data) {
            ply.loading = false
            if (err) { ply.error = String(err); return }
            ply.data = data
        })
    }

    function openPlayer(playerId, from) {
        if (!playerId) return
        nav.player    = true
        ply.from    = from || 'leaders'
        ply.loading = true
        ply.error   = ''
        ply.data    = null

        // Fermer les autres vues pour éviter les conflits de visibilité
        nav.standings = false
        nav.leaders   = false
        nav.search    = false
        nav.teamHub   = false
        nav.bracket   = false
        nav.calendar  = false
        nav.dayView   = false
        Logic.ApiService.getPlayerLanding(playerId, function(err, data) {
                ply.loading = false
                if (err) { ply.error = String(err); return }
                ply.data = data
            })
    }

    // ── Séries éliminatoires ────────────────────────────────────────
    function processBracketData(data) {
        if (!data || !data.series) return
        var sMap = {}
        var seriesMap = {}
        data.series.forEach(function(s) {
            var letter = s.seriesLetter
            var info = {
                top: s.topSeedTeam ? s.topSeedTeam.abbrev : "",
                bottom: s.bottomSeedTeam ? s.bottomSeedTeam.abbrev : "",
                topWins: s.topSeedWins || 0,
                bottomWins: s.bottomSeedWins || 0,
                round: s.playoffRound
            }
            seriesMap[letter] = info
            if (info.top) sMap[info.top] = info.topWins
            if (info.bottom) sMap[info.bottom] = info.bottomWins
        })
        brk.series = seriesMap
        brk.scores = sMap
        brk.data = data
        brk.pulse++
    }

    function fetchPlayoffBracket() {
        // 1. CHARGEMENT DU CACHE : On commence par lire ce qu'on a en mémoire locale
        if (!brk.data && Plasmoid.configuration.cacheData) {
            try {
                var cached = JSON.parse(Plasmoid.configuration.cacheData)
                if (cached && cached.bracket) {
                    processBracketData(cached.bracket)
                }
            } catch(e) { }
        }

        brk.loading = !brk.data // On ne montre le loader que si on n'a rien du tout
        brk.error   = ''

        Logic.ApiService.getPlayoffBracket(function(err, data, isOffline) {
            if (!err && data) {
                brk.loading = false
                processBracketData(data)

                // 2. SAUVEGARDE DANS LE CACHE PERSISTANT
                var cacheObj = {}
                try { cacheObj = JSON.parse(Plasmoid.configuration.cacheData || "{}") } catch(e){}
                cacheObj.bracket = data
                Plasmoid.configuration.cacheData = JSON.stringify(cacheObj)
            } else if (err && !brk.data) {
                brk.error = String(err)
                brk.loading = false
            }
        })
    }
    // ── Ouvrir le hub d'équipe ──────────────────────────────────────
    function fetchTeamHub(teamCode, from) {
        hub.code    = teamCode
        hub.stanleyCups = Logic.getStanleyCupsCount(teamCode)
        sch.team    = teamCode // Important pour le calendrier
        hub.from    = from || 'detail'
        hub.loading = true
        hub.error   = ''
        hub.record  = ''
        hub.coach   = ''
        hub.fullName = ''
        hub.w       = 0
        hub.l       = 0
        hub.ot      = 0
        hub.pts     = 0
        hub.gp      = 0
        hub.standing = ''
        hub.lastGames = []
        hub.nextGame  = null

        let pending = 3   // schedule, standings, entraîneur(direct)
        function done() { pending--; if (pending <= 0) hub.loading = false }

        // 1. Calendrier → derniers matchs + prochain
        fetchSchedule(teamCode) // Pour peupler sch.gamesMap
        Logic.ApiService.getTeamSchedule(teamCode, function(err, data) {
                if (!err && data && data.games) {
                    let past = data.games.filter(function(g) {
                        return g.gameState === 'OFF' || g.gameState === 'FINAL'
                    }).slice(-5)
                    let next = data.games.find(function(g) {
                        return g.gameState === 'FUT' || g.gameState === 'PRE'
                    })
                    hub.lastGames = past.map(function(g) {
                        let isHome = g.homeTeam && g.homeTeam.abbrev === teamCode
                        let opp    = isHome ? (g.awayTeam && g.awayTeam.abbrev) : (g.homeTeam && g.homeTeam.abbrev)
                        let gf     = isHome ? (g.homeTeam && g.homeTeam.score) : (g.awayTeam && g.awayTeam.score)
                        let ga     = isHome ? (g.awayTeam && g.awayTeam.score) : (g.homeTeam && g.homeTeam.score)
                        let win    = gf > ga
                        let ot     = g.periodDescriptor && (g.periodDescriptor.periodType === 'OT' || g.periodDescriptor.periodType === 'SO')
                        return { opp: opp, gf: gf, ga: ga, win: win, ot: ot,
                                 home: isHome, start: g.startTimeUTC }
                    })
                    if (next) {
                        let isHome = next.homeTeam && next.homeTeam.abbrev === teamCode
                        let opp = isHome ? (next.awayTeam && next.awayTeam.abbrev)
                                         : (next.homeTeam && next.homeTeam.abbrev)
                        hub.nextGame = { opp: opp, home: isHome, start: next.startTimeUTC }
                    }
                }
                done()
            })

        // 2. Standings → fiche + position
        Logic.ApiService.getStandings(function(err, data) {
                if (!err && data && data.standings) {
                    let team = data.standings.find(function(s) {
                        return s.teamAbbrev && s.teamAbbrev.default === teamCode
                    })
                    if (team) {
                        hub.record   = (team.wins || 0) + "-" + (team.losses || 0) + "-" + (team.otLosses || 0)
                        var cn = team.teamCommonName ? (team.teamCommonName.default || team.teamCommonName) : ''
                        var pn = team.teamPlaceNameWithPreposition ? (team.teamPlaceNameWithPreposition.fr || team.teamPlaceNameWithPreposition.default || '') : ''
                        hub.fullName = cn + (pn ? ' ' + pn : '')
                        hub.w        = team.wins        || 0
                        hub.l        = team.losses      || 0
                        hub.ot       = team.otLosses    || 0
                        hub.pts      = team.points      || 0
                        hub.gp       = team.gamesPlayed || 0
                        let div   = team.divisionName || ''
                        let rank  = team.divisionSequence || team.wildcardSequence || ''
                        hub.standing = rank + (rank ? " · " : "") + div
                    }
                }
                done()
            })

        // 4. Entraîneur
        var coaches = {
            'ANA': 'Greg Cronin',       'UTA': 'André Tourigny',
            'BOS': 'Joe Sacco',         'BUF': 'Lindy Ruff',
            'CAR': "Rod Brind'Amour",   'CBJ': 'Dean Evason',
            'CGY': 'Ryan Huska',        'CHI': 'Anders Sorensen',
            'COL': 'Jared Bednar',      'DAL': 'Peter DeBoer',
            'DET': 'Derek Lalonde',     'EDM': 'Kris Knoblauch',
            'FLA': 'Paul Maurice',      'LAK': 'Jim Hiller',
            'MIN': 'John Hynes',        'MTL': 'Martin St-Louis',
            'NJD': 'Sheldon Keefe',     'NSH': 'Andrew Brunette',
            'NYI': 'Patrick Roy',        NYR: 'Peter Laviolette',
            'OTT': 'Travis Green',      'PHI': 'John Tortorella',
            'PIT': 'Mike Sullivan',     'SEA': 'Dan Bylsma',
            'SJS': 'Ryan Warsofsky',    'STL': 'Drew Bannister',
            'TBL': 'Jon Cooper',        'TOR': 'Craig Berube',
            'VAN': 'Rick Tocchet',      'VGK': 'Bruce Cassidy',
            'WPG': 'Scott Arniel',      'WSH': 'Spencer Carbery'
        }
        hub.coach = coaches[teamCode] || ''
        done()
    }

    function openTeamHub(teamCode, from) {
        nav.teamHub    = true
        hub.code    = teamCode
        sch.team    = teamCode // Important pour le calendrier
        hub.from    = from || 'detail'
        hub.loading = true
        hub.error   = ''
        hub.record  = ''
        hub.coach   = ''
        hub.fullName = ''
        hub.w       = 0
        hub.l       = 0
        hub.ot      = 0
        hub.pts     = 0
        hub.gp      = 0
        hub.standing = ''
        hub.lastGames = []
        hub.nextGame  = null

        // Fermer les autres vues pour éviter les conflits
        nav.standings    = false
        nav.leaders      = false
        nav.bracket      = false
        nav.schedule     = false
        nav.detail       = false
        nav.player       = false
        nav.search       = false
        nav.calendar     = false
        nav.dayView      = false
        nav.franchiseLeaders = false

        let pending = 3   // schedule, standings, entraîneur(direct)
        function done() { pending--; if (pending <= 0) hub.loading = false }

        // 1. Calendrier → derniers matchs + prochain
        fetchSchedule(teamCode) // Pour peupler sch.gamesMap
        Logic.ApiService.getTeamSchedule(teamCode, function(err, data) {
                if (!err && data && data.games) {
                    let now = Date.now()
                    let past = data.games.filter(function(g) {
                        return g.gameState === 'OFF' || g.gameState === 'FINAL'
                    }).slice(-5)
                    let next = data.games.find(function(g) {
                        return g.gameState === 'FUT' || g.gameState === 'PRE'
                    })
                    hub.lastGames = past.map(function(g) {
                        let isHome = g.homeTeam && g.homeTeam.abbrev === teamCode
                        let opp    = isHome ? (g.awayTeam && g.awayTeam.abbrev) : (g.homeTeam && g.homeTeam.abbrev)
                        let gf     = isHome ? (g.homeTeam && g.homeTeam.score) : (g.awayTeam && g.awayTeam.score)
                        let ga     = isHome ? (g.awayTeam && g.awayTeam.score) : (g.homeTeam && g.homeTeam.score)
                        let win    = gf > ga
                        let ot     = g.periodDescriptor && (g.periodDescriptor.periodType === 'OT' || g.periodDescriptor.periodType === 'SO')
                        return { opp: opp, gf: gf, ga: ga, win: win, ot: ot,
                                 home: isHome, start: g.startTimeUTC }
                    })
                    if (next) {
                        let isHome = next.homeTeam && next.homeTeam.abbrev === teamCode
                        let opp = isHome ? (next.awayTeam && next.awayTeam.abbrev)
                                         : (next.homeTeam && next.homeTeam.abbrev)
                        hub.nextGame = { opp: opp, home: isHome, start: next.startTimeUTC }
                    }
                }
                done()
            })

        // 2. Standings → fiche + position
        Logic.ApiService.getStandings(function(err, data) {
                if (!err && data && data.standings) {
                    let team = data.standings.find(function(s) {
                        return s.teamAbbrev && s.teamAbbrev.default === teamCode
                    })
                    if (team) {
                        hub.record   = (team.wins || 0) + "-" + (team.losses || 0) + "-" + (team.otLosses || 0)
                        var cn = team.teamCommonName ? (team.teamCommonName.default || team.teamCommonName) : ''
                        var pn = team.teamPlaceNameWithPreposition ? (team.teamPlaceNameWithPreposition.fr || team.teamPlaceNameWithPreposition.default || '') : ''
                        hub.fullName = cn + (pn ? ' ' + pn : '')
                        hub.w        = team.wins        || 0
                        hub.l        = team.losses      || 0
                        hub.ot       = team.otLosses    || 0
                        hub.pts      = team.points      || 0
                        hub.gp       = team.gamesPlayed || 0
                        let div   = team.divisionName || ''
                        let rank  = team.divisionSequence || team.wildcardSequence || ''
                        hub.standing = rank + (rank ? " · " : "") + div
                    }
                }
                done()
            })

        // 4. Entraîneur — table statique saison 2024-25
        var coaches = {
            'ANA': 'Greg Cronin',       'UTA': 'André Tourigny',
            'BOS': 'Joe Sacco',         'BUF': 'Lindy Ruff',
            'CAR': "Rod Brind'Amour",   'CBJ': 'Dean Evason',
            'CGY': 'Ryan Huska',        'CHI': 'Anders Sorensen',
            'COL': 'Jared Bednar',      'DAL': 'Pete DeBoer',
            'DET': 'Derek Lalonde',     'EDM': 'Kris Knoblauch',
            'FLA': 'Paul Maurice',      'LAK': 'Jim Hiller',
            'MIN': 'John Hynes',        'MTL': 'Martin St-Louis',
            'NJD': 'Sheldon Keefe',     'NSH': 'Andrew Brunette',
            'NYI': 'Patrick Roy',       'NYR': 'Peter Laviolette',
            'OTT': 'Travis Green',      'PHI': 'John Tortorella',
            'PIT': 'Mike Sullivan',     'SEA': 'Dan Bylsma',
            'SJS': 'Ryan Warsofsky',    'STL': 'Jim Montgomery',
            'TBL': 'Jon Cooper',        'TOR': 'Craig Berube',
            'VAN': 'Rick Tocchet',      'VGK': 'Bruce Cassidy',
            'WPG': 'Scott Arniel',      'WSH': 'Spencer Carbery'
        }
        hub.coach = coaches[teamCode] || ''
        done()
    }

    // Retourne le label de la ronde (1er tour, demi-finales, etc.)
    function playoffRoundLabel(round) {
        if (round === 1) return i18n("First Round")
        if (round === 2) return i18n("Second Round")
        if (round === 3) return i18n("Conference Finals")
        if (round === 4) return i18n("Stanley Cup Final")
        return i18n("Playoffs")
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
        const startTime = now.getTime() - (root.pastHours * 3600000)
        const endTime = now.getTime() + (root.upcomingHours * 3600000)


        // Filtrage temporel précis
        let filtered = games.filter(function(g){
            if (!g.startTimeUTC) return false
            const t = new Date(g.startTimeUTC).getTime()
            return t >= startTime && t <= endTime
        })


        if (!showAllTeams && favoriteTeams.length){
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
                        periodType: g.periodDescriptor?.periodType || "",
                        period: g.periodDescriptor?.number || 0,
                        inIntermission: g.clock?.inIntermission || false,
                        intermissionRemain: g.clock?.inIntermission ? (g.clock?.timeRemaining || "") : "",
                        liveRemain: g.clock?.timeRemaining || "",

                        pbpClock: "",
                        pbpPeriod: 0,
                        clockStartRemain: "",
                        clockStartWall: "",
                        clockRunning: false,
                        rawClock: g.clock || null,
                        inIntermission: (g.clock && g.clock.inIntermission) ? true : false,
                        situationCode: (function() {
                            var sc = g.situationCode || '1551'
                            // Valider — ignorer les codes transitoires
                            var as = parseInt(sc[1]), hs = parseInt(sc[2])
                            if (isNaN(as) || isNaN(hs) || as === 0 || hs === 0
                                || as > 6 || hs > 6) return '1551'
                            // 6 patineurs avec gardien en jeu = transitoire
                            var ag2 = parseInt(sc[0]), hg2 = parseInt(sc[3])
                            if (as === 6 && ag2 === 1) return '1551'
                            if (hs === 6 && hg2 === 1) return '1551'
                            return sc
                        })(),
                        gameType: g.gameType || 2
            }
        })
        .sort(function(a,b){ return a.start - b.start })

        uniq = uniq.slice(0, maxGames)
        
        // Sauvegarder les scores précédents pour la détection des buts
        let snapshot = {}
        for (let si = 0; si < todayGames.count; si++) {
            let sg = todayGames.get(si)
            if (sg.gameId > 0) {
                snapshot[sg.gameId] = { ag: sg.ag, hg: sg.hg, status: sg.statusRole }
            }
        }
        glob.prevScores = snapshot

        // Construire la liste cible (Matchs + Séparateurs)
        let targetData = []
        let lastDateKey = ''
        let gameIdx = 0
        let todayKey = dateISO(new Date())
        
        for (let i = 0; i < uniq.length; i++) {
            let gameDate = uniq[i].start ? dateISO(new Date(uniq[i].start)) : todayKey
            if (gameDate !== lastDateKey) {
                lastDateKey = gameDate
                targetData.push({
                    gameId: -1, home: '', away: '', hg: 0, ag: 0,
                    start: uniq[i].start, statusRole: 'DATE_SEP',
                    rawState: '', periodType: '', period: 0,
                    liveRemain: '', inIntermission: false,
                    situationCode: '1551', penaltyTime: '', intermissionRemain: '',
                    gameType: 2, gameIndex: gameIdx
                })
            }

            let liveRemain = ""
            if (uniq[i].statusRole === "LIVE" && uniq[i].rawClock) {
                liveRemain = uniq[i].rawClock.timeRemaining
            }

            targetData.push({
                gameId: uniq[i].gameId,
                home: uniq[i].home,
                away: uniq[i].away,
                hg: uniq[i].hg,
                ag: uniq[i].ag,
                start: uniq[i].start,
                statusRole: uniq[i].statusRole,
                rawState: uniq[i].rawState,
                periodType: uniq[i].periodType,
                period: uniq[i].period || 0,
                liveRemain: liveRemain,
                inIntermission: uniq[i].inIntermission || false,
                situationCode: uniq[i].situationCode || '1551',
                penaltyTime: uniq[i].penaltyTime || '',
                intermissionRemain: uniq[i].intermissionRemain || '',
                gameType: uniq[i].gameType || 2,
                gameIndex: gameIdx++
            })
        }

        // --- Synchronisation granulaire du ListModel ---
        // 1. Ajuster la taille du modèle
        while (todayGames.count > targetData.length) {
            todayGames.remove(todayGames.count - 1)
        }
        while (todayGames.count < targetData.length) {
            todayGames.append(targetData[todayGames.count])
        }

        // 2. Mettre à jour uniquement les propriétés modifiées
        for (let j = 0; j < targetData.length; j++) {
            let current = todayGames.get(j)
            let target = targetData[j]

            // PROTECTION ENTRACTE : Conserver l'avantage numérique si on entre en entracte
            if (target.inIntermission && current && current.gameId === target.gameId) {
                if (target.situationCode === "1551" && current.situationCode !== "1551") {
                    target.situationCode = current.situationCode
                    target.penaltyTime = current.penaltyTime
                }
            }
            
            // On compare les clés essentielles pour décider s'il faut mettre à jour
            if (current.gameId !== target.gameId || 
                current.ag !== target.ag || current.hg !== target.hg ||
                current.statusRole !== target.statusRole ||
                current.liveRemain !== target.liveRemain ||
                current.situationCode !== target.situationCode ||
                current.inIntermission !== target.inIntermission) 
            {
                todayGames.set(j, target)
            }
        }

        // Détecter les nouveaux buts et envoyer les notifications
        if (!glob.initialLoading) {
            for (let ni = 0; ni < todayGames.count; ni++) {
                let ng = todayGames.get(ni)
                let prev = glob.prevScores[ng.gameId]
                if (prev && ng.statusRole === 'LIVE') {
                    if (ng.ag > prev.ag || ng.hg > prev.hg) {
                        triggerGoalBlink(ng.away, ng.home, ng.ag, ng.hg, prev.ag, prev.hg, ng.gameId)
                    }
                }
            }
        }

        glob.initialLoading = false
        glob.lastUpdated = new Date()
        glob.debugMsg = (errors && errors.length ? errors.join(' | ') : '')
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

        // Mise à jour de la vue détail si ouverte
        if (nav.detail && det.gameId !== 0) {
            for (let dj = 0; dj < todayGames.count; dj++) {
                let g = todayGames.get(dj)
                if (g.gameId === det.gameId) {
                    det.ag      = g.ag
                    det.hg      = g.hg
                    det.status  = g.statusRole
                    det.pType   = g.periodType
                    det.period  = g.period
                    det.remain  = g.liveRemain
                    det.interm  = g.inIntermission
                    det.intermRemain = g.intermissionRemain
                    break
                }
            }
        }
    }

    Connections {
        target: Plasmoid.configuration
        function onFavoritesChanged(){ root.favoriteTeams = (Plasmoid.configuration.favorites||'').split(/\s*,\s*/).filter(function(s){return s.length>0}); refresh() }
        function onFavoriteTeamSoundChanged(){ root.favoriteTeamSound = Plasmoid.configuration.favoriteTeamSound || '' }
        function onSoundTeamsChanged(){ root.soundTeams = (Plasmoid.configuration.soundTeams||'').split(',').filter(function(s){return s.length>0}) }
        function onSoundVolumeChanged(){ root.soundVolume = Plasmoid.configuration.soundVolume !== undefined ? Plasmoid.configuration.soundVolume : 1.0 }
        function onShowAllTeamsChanged(){ refresh() }
        function onMaxGamesChanged(){ refresh() }
        function onPastHoursChanged(){ root.pastHours = Plasmoid.configuration.pastHours; refresh() }
        function onUpcomingHoursChanged(){ root.upcomingHours = Plasmoid.configuration.upcomingHours; refresh() }
        function onPollIntervalChanged(){ root.pollInterval = Plasmoid.configuration.pollInterval || 20 }

        function onScoreLayoutChanged(){ root.scoreLayout = Plasmoid.configuration.scoreLayout || 'stack' }
        function onUltraCompactChanged(){
            root.ultraCompact = Plasmoid.configuration.ultraCompact || false
            // Forcer reconstruction du Repeater si défini
            if (typeof hRepeater !== 'undefined' && hRepeater) {
                hRepeater.model = null
                hRepeater.model = todayGames
            }
        }
        function onShowUpcomingTimeChanged(){ }
        function onDateModeChanged(){ }

    }

    Component { id: statusBadge
        Components.StatusBadge {
            controller: root
            line1: root.badgeLine1(parent.gameStatus, parent.rawState,
                                   parent.periodType, parent.period,
                                   parent.liveRemain, parent.startMs,
                                   parent.homeTeam, parent.intermission,
                                   parent.intermissionRemain)
            line2: root.badgeLine2(parent.gameStatus, parent.startMs,
                                   parent.homeTeam, parent.periodType,
                                   parent.period, parent.liveRemain,
                                   parent.intermission, parent.intermissionRemain)
            bgColor: root.statusColor(parent.gameStatus)
            situationCode: parent.situationCode || "1551"
            penaltyTime: parent.penaltyTime || ""
            awayTeam: parent.awayTeam || ""
            homeTeam: parent.homeTeam || ""
        }
    }

    Component { id: teamColumn
        Components.TeamBadge {
            anchors.horizontalCenter: parent.horizontalCenter
            code: parent.code; score: parent.score; sz: parent.sz
            gameId: parent.gameId; teamSide: parent.teamSide
            showScore: parent.gameStatus !== 'UPCOMING'
            blinkingGames: glob.blinkingGames; blinkOn: glob.blinkOn
            controller: root
        }
    }

    Component { id: teamRowInline
        Components.TeamRowInline {
            awayCode: parent.awayCode; homeCode: parent.homeCode
            agScore: parent.agScore; hgScore: parent.hgScore
            sz: parent.sz; gameId: parent.gameId
            blinkingGames: glob.blinkingGames; blinkOn: glob.blinkOn
            statusComponent: parent.statusComponent
            gameStatus: parent.gameStatus || 'UPCOMING'
            line1: parent.line1 || ""
            line2: parent.line2 || ""
            bgColor: parent.bgColor || "gray"
            controller: parent.controller
            situationCode: parent.situationCode || "1551"
            awayTeam: parent.awayTeam || ""
            homeTeam: parent.homeTeam || ""
            penaltyTime: parent.penaltyTime || ""
        }
    }

    function upcomingWhenText(startMs, statusRole, homeTeam){
        if (!(statusRole==='UPCOMING' && showUpcomingTime)) return ''
        // Toujours afficher l'heure — la date est dans le séparateur DATE_SEP
        return localTimeStr(startMs)
    }


    compactRepresentation: CompactRepresentation { controller: root }

    function openSchedule(team, showStats) {
        nav.schedule      = true
        nav.scheduleShowStats = showStats === true
        // Fermer les autres overlays
        nav.standings     = false
        nav.leaders       = false
        nav.bracket       = false
        nav.search        = false
        nav.calendar      = false
        nav.dayView       = false

        sch.skaters      = []
        sch.goalies      = []
        sch.statsError   = ''
        sch.statsLoading = false
        sch.team    = team
        sch.games   = []
        sch.error   = ''
        sch.loading = true
        fetchSchedule(team)
        if (showStats === true) fetchTeamStats(team)
    }

    function openPlayoffBracket() {
        nav.bracket   = true
        // Fermer les autres overlays
        nav.standings = false
        nav.leaders   = false
        nav.search    = false
        nav.schedule  = false
        nav.calendar  = false
        nav.dayView   = false
        fetchPlayoffBracket()
    }

    function openFranchiseLeaders(teamCode) {
        nav.franchiseLeaders = true
        // Fermer les autres overlays si nécessaire
        nav.standings = false
        nav.leaders   = false
        nav.search    = false
        nav.bracket   = false
        nav.schedule  = false
        nav.calendar  = false
        nav.dayView   = false
        
        flead.team = teamCode
        fetchFranchiseLeaders(teamCode)
    }

    function fetchFranchiseLeaders(teamCode) {
        if (!teamCode) return
        flead.team = teamCode
        flead.loading = true
        flead.error = ""
        
        // Reset
        flead.points = []; flead.goals = []; flead.assists = [];
        flead.wins = []; flead.sho = [];
        
        var activeIds = {}
        var limit = (root.franchiseLeadersLimit > 0) ? root.franchiseLeadersLimit : 10
        var st = flead.seasonType
        
        var loadSkaters = !flead.filterG
        var loadGoalies = flead.filterG
        
        var pos = ""
        if (flead.filterF) pos = "F"
        else if (flead.filterD) pos = "D"

        var pending = (loadSkaters ? 4 : 0) + (loadGoalies ? 3 : 0)
        
        function done() { 
            pending--
            if (pending <= 0) {
                var applyActive = function(list) {
                    return list.map(function(p) { p.active = !!activeIds[p.id]; return p })
                }
                flead.points = applyActive(flead.points)
                flead.goals  = applyActive(flead.goals)
                flead.assists = applyActive(flead.assists)
                flead.wins   = applyActive(flead.wins)
                flead.sho    = applyActive(flead.sho)
                flead.loading = false 
            }
        }

        if (loadSkaters) {
            // 0. Active IDs (Skaters)
            Logic.ApiService.getFranchiseLeaders(teamCode, "points", 100, true, st, false, pos, function(err, data) {
                if (!err && data && data.data) data.data.forEach(function(l) { activeIds[l.playerId] = true })
                done()
            })
            // 1. Points
            Logic.ApiService.getFranchiseLeaders(teamCode, "points", limit, false, st, false, pos, function(err, data) {
                if (!err && data && data.data) flead.points = data.data.map(function(l) { return { id: l.playerId, name: l.skaterFullName, value: l.points, pos: l.positionCode } })
                done()
            })
            // 2. Goals
            Logic.ApiService.getFranchiseLeaders(teamCode, "goals", limit, false, st, false, pos, function(err, data) {
                if (!err && data && data.data) flead.goals = data.data.map(function(l) { return { id: l.playerId, name: l.skaterFullName, value: l.goals, pos: l.positionCode } })
                done()
            })
            // 3. Assists
            Logic.ApiService.getFranchiseLeaders(teamCode, "assists", limit, false, st, false, pos, function(err, data) {
                if (!err && data && data.data) flead.assists = data.data.map(function(l) { return { id: l.playerId, name: l.skaterFullName, value: l.assists, pos: l.positionCode } })
                done()
            })
        }
        
        if (loadGoalies) {
            // 0. Active IDs (Goalies)
            Logic.ApiService.getFranchiseLeaders(teamCode, "wins", 100, true, st, true, "", function(err, data) {
                if (!err && data && data.data) data.data.forEach(function(l) { activeIds[l.playerId] = true })
                done()
            })
            // 1. Wins
            Logic.ApiService.getFranchiseLeaders(teamCode, "wins", limit, false, st, true, "", function(err, data) {
                if (!err && data && data.data) flead.wins = data.data.map(function(l) { return { id: l.playerId, name: l.goalieFullName, value: l.wins } })
                done()
            })
            // 2. Blanchissages
            Logic.ApiService.getFranchiseLeaders(teamCode, "shutouts", limit, false, st, true, "", function(err, data) {
                if (!err && data && data.data) flead.sho = data.data.map(function(l) { return { id: l.playerId, name: l.goalieFullName, value: l.shutouts } })
                done()
            })
        }
    }

    function fetchSchedule(team) {
        Logic.ApiService.getTeamSchedule(team, function(err, data) {
            sch.loading = false
            if (err) { sch.error = String(err); return }
            try {
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
                
                var gmap = {}
                var allGames = games.map(function(g) {
                    var st = (g.gameState || '').toUpperCase()
                    var isFinal = (st === 'FINAL' || st === 'OFF' || st === 'OFFICIAL')
                    var isLive  = (st === 'LIVE' || st === 'IN_PROGRESS')
                    var away  = g.awayTeam  ? (g.awayTeam.abbrev  || '?') : '?'
                    var home  = g.homeTeam  ? (g.homeTeam.abbrev  || '?') : '?'
                    var ag    = g.awayTeam  ? (g.awayTeam.score   !== undefined ? g.awayTeam.score  : -1) : -1
                    var hg    = g.homeTeam  ? (g.homeTeam.score   !== undefined ? g.homeTeam.score  : -1) : -1
                    var startMs = new Date(g.startTimeUTC || '').getTime() || 0

                    // Calculer la date ISO locale (ou aréna) pour le dictionnaire du calendrier
                    var dObj = new Date(startMs)
                    var iso = dObj.getFullYear() + "-" + Logic.pad2(dObj.getMonth() + 1) + "-" + Logic.pad2(dObj.getDate())
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
                    
                    var obj = {
                        away: away, home: home,
                        ag: ag, hg: hg,
                        startMs: startMs,
                        dateISO: iso,
                        isFinal: isFinal,
                        isLive:  isLive,
                        result:  matchResult,
                        gameId:  g.id || 0
                    }
                    if (iso) gmap[iso] = obj
                    return obj
                })

                sch.gamesMap = gmap
                // Filtrer pour la liste simplifiée (5 derniers + futurs)
                var simplified = []
                for (var j=0; j<result.length; j++) {
                    var gid = result[j].id
                    var found = allGames.find(function(x){ return x.gameId === gid })
                    if (found) simplified.push(found)
                }
                sch.games = simplified
            } catch(e) { sch.error = String(e) }
        })
    }

    function fetchTeamStats(team) {
        sch.statsLoading = true
        sch.statsError   = ''
        
        // Utiliser le code historique (ex: HFD au lieu de CAR) pour l'API
        var apiCode = Logic.getHistoricalLogo(team, sch.season)
        
        // Endpoint stats équipe saison/type choisis
        Logic.ApiService.getTeamStats(apiCode, sch.season, sch.seasonType, function(err, data) {
            sch.statsLoading = false
            if (err) { sch.statsError = String(err); return }
            try {
                // Patineurs
                var sk = []
                var skaters = data.skaters || []
                for (var i = 0; i < skaters.length; i++) {
                    var s = skaters[i]
                    var fname = s.firstName  ? (s.firstName.default  || '') : ''
                    var lname = s.lastName   ? (s.lastName.default   || '') : ''
                    sk.push({
                        id:        s.playerId     || 0,
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
                sch.skaters = sk
                // Gardiens
                var gl = []
                var goalies = data.goalies || []
                for (var gi = 0; gi < goalies.length; gi++) {
                    var g = goalies[gi]
                    var gfname = g.firstName ? (g.firstName.default || '') : ''
                    var glname = g.lastName  ? (g.lastName.default  || '') : ''
                    gl.push({
                        id:     g.playerId      || 0,
                        name:   gfname + ' ' + glname,
                        gp:     g.gamesPlayed   || 0,
                        wins:   g.wins          || 0,
                        losses: g.losses        || 0,
                        ot:     g.otLosses      || 0,
                        gaa:    g.goalsAgainstAverage !== undefined
                                    ? Number(g.goalsAgainstAverage).toFixed(3) : "0.000",
                        svPct:  (function(goalie) {
                                    if (goalie.savePercentage !== undefined && goalie.savePercentage > 0) return goalie.savePercentage
                                    if (goalie.savePctg !== undefined && goalie.savePctg > 0) return goalie.savePctg
                                    if (goalie.shotsAgainst > 0) return (goalie.shotsAgainst - goalie.goalsAgainst) / goalie.shotsAgainst
                                    return 0
                                })(g)
                    })
                }
                // Trier par wins desc
                gl.sort(function(a, b) { return b.wins - a.wins })
                sch.goalies = gl
            } catch(e) { sch.statsError = String(e) }
        })
    }

    function openDetail(gid, away, home, ag, hg, status, ptype, period, remain, start, interm, sitCode, intermRemain) {
        // En mode compact bureau, on ouvre le popup séparé au lieu de changer la vue interne
        // detailPopup est maintenant défini dans fullRepresentation
        if (root.isDesktop && root.showCompactDesktop && root.popupRef) {
            // TOGGLE : si le popup est déjà ouvert pour le même match, on le ferme
            if (root.popupRef.visible && String(det.gameId) === String(gid)) {
                root.popupRef.visible = false
                return
            }

            det.gameId  = gid
            det.away    = away
            det.home    = home
            det.ag      = ag
            det.hg      = hg
            det.status  = status
            det.pType   = ptype
            det.period  = period
            det.remain  = remain
            det.start   = start
            det.interm  = interm || false
            det.intermRemain = intermRemain || ""
            det.sitCode = sitCode || '1551'
            det.view    = 'goals'
            fetchH2H(away, home)
            
            root.popupRef.visible = true
            return
        }

        // Toggle : fermer si le même match est déjà ouvert
        if (nav.detail && det.gameId === gid) {
            nav.detail = false
            expanded   = false
            return
        }
        // Fermer le calendrier/stats et le classement si ouverts
        nav.schedule      = false
        nav.scheduleShowStats = false
        nav.bracket       = false
        nav.standings     = false
        nav.teamHub       = false
        nav.leaders       = false
        nav.dayView       = false
        nav.player        = false
        det.threeStars    = []
        det.penalties     = []
        det.playerMap    = {}
        det.view          = 'goals'
        fetchH2H(away, home)
        det.gameId  = gid
        det.away    = away
        det.home    = home
        det.ag      = ag
        det.hg      = hg
        det.status  = status
        det.pType   = ptype
        det.period  = period
        det.remain  = remain
        det.start   = start
        det.interm  = interm || false
        det.intermRemain = intermRemain || ""
        det.goals   = []
        det.stats   = ({})
        det.venue = ''; det.seriesAway = 0; det.seriesHome = 0; det.seriesTotal = false; det.h2hGames = []
        det.awayRecord = ({}); det.homeRecord = ({})
        det.awayLeaders = []; det.homeLeaders = []
        det.awayGoalie = null; det.homeGoalie = null
        det.sitCode  = sitCode || '1551'
        det.intermRemain   = ''
        // Détecter les séries éliminatoires
        det.isPlayoff = false
        det.seriesRound = ''
        det.seriesGameNum = 0
        for (let pi = 0; pi < todayGames.count; pi++) {
            let pg = todayGames.get(pi)
            if (pg.gameId === gid) {
                det.isPlayoff = (pg.gameType === 3)
                break
            }
        }
        var pmEntry = glob.penaltiesMap[String(gid)] || {away:[],home:[]}
        det.penaltyBoxAway = JSON.stringify(pmEntry.away)
        det.penaltyBoxHome = JSON.stringify(pmEntry.home)
        det.error   = ''
        // Fermer les overlays pour voir le détail
        nav.standings = false
        nav.leaders   = false
        nav.search    = false
        nav.bracket   = false
        nav.schedule  = false
        nav.calendar  = false
        nav.dayView   = false
        nav.teamHub   = false
        nav.player    = false
        nav.franchiseLeaders = false

        nav.detail    = true
        fetchDetail(gid)
        // Ouvrir le fullRepresentation (popup natif Plasma)
        expanded = true
    }

    function fetchDetail(gid) {
        // Optimisation : si le match est déjà FINAL et qu'on a déjà chargé les données, on peut ignorer le rafraîchissement
        if (det.gameId === gid && det.status === 'FINAL' && det.goals.length > 0 && !det.loading) {
            return
        }
        det.loading = true
        var done = 0
        function tryDone() { done++; if (done >= 3) det.loading = false }

        // right-rail → stats de comparaison (preview)
        Logic.ApiService.getGameRightRail(gid, function(err, d) {
            if (!err && d) {
                // 1. Stats de saison
                if (d.teamSeasonStats) {
                    var ts = d.teamSeasonStats
                    var tcList = []
                    var a = ts.awayTeam || {}
                    var h = ts.homeTeam || {}
                    
                    tcList.push({ label: "ppPctg", away: a.ppPctg || 0, home: h.ppPctg || 0 })
                    tcList.push({ label: "pkPctg", away: a.pkPctg || 0, home: h.pkPctg || 0 })
                    tcList.push({ label: "faceoffWinPctg", away: a.faceoffWinningPctg || 0, home: h.faceoffWinningPctg || 0 })
                    tcList.push({ label: "goalsForPerGame", away: a.goalsForPerGamePlayed || 0, home: h.goalsForPerGamePlayed || 0 })
                    tcList.push({ label: "goalsAgainstPerGame", away: a.goalsAgainstPerGamePlayed || 0, home: h.goalsAgainstPerGamePlayed || 0 })
                    
                    det.teamComparison = tcList
                }

                // 2. Série de saison / Séries éliminatoires
                if (d.seasonSeriesWins) {
                    det.seriesAway = d.seasonSeriesWins.awayTeamWins || 0
                    det.seriesHome = d.seasonSeriesWins.homeTeamWins || 0
                    det.seriesTotal = true
                }
                
                // 3. Matchs H2H (Séparation Saison / Séries)
                if (d.seasonSeries) {
                    var h2hAll = []
                    var h2hSeason = []
                    var winsAwaySeason = 0
                    var winsHomeSeason = 0
                    var winsAwayPlayoffs = 0
                    var winsHomePlayoffs = 0
                    
                    for (var i=0; i<d.seasonSeries.length; i++) {
                        var g = d.seasonSeries[i]
                        var isFinal = (g.gameState === 'OFF' || g.gameState === 'FINAL')
                        var isPlayoff = (g.gameType === 3)
                        
                        var item = {
                            date: g.gameDate,
                            away: g.awayTeam.abbrev,
                            home: g.homeTeam.abbrev,
                            awayScore: g.awayTeam.score,
                            homeScore: g.homeTeam.score,
                            final: isFinal,
                            isPlayoff: isPlayoff
                        }
                        
                        if (isFinal) {
                            let awayWin = g.awayTeam.score > g.homeTeam.score
                            let winnerAbbrev = awayWin ? g.awayTeam.abbrev : g.homeTeam.abbrev

                            if (!isPlayoff) {
                                h2hSeason.push(item)
                                if (winnerAbbrev === det.away) winsAwaySeason++
                                else if (winnerAbbrev === det.home) winsHomeSeason++
                            } else {
                                if (winnerAbbrev === det.away) winsAwayPlayoffs++
                                else if (winnerAbbrev === det.home) winsHomePlayoffs++
                            }
                            h2hAll.push(item)
                        }
                    }
                    det.h2hGames = h2hAll
                    det.h2hSeason = h2hSeason
                    
                    // Stockage étanche des scores calculés manuellement
                    det.seriesAwaySeason = winsAwaySeason
                    det.seriesHomeSeason = winsHomeSeason
                    det.seriesAwayPlayoffs = winsAwayPlayoffs
                    det.seriesHomePlayoffs = winsHomePlayoffs
                    
                    // Mise à jour des variables globales pour compatibilité
                    det.seriesAway = winsAwayPlayoffs
                    det.seriesHome = winsHomePlayoffs
                }
            }
            tryDone()
        })

        // landing → buts
        Logic.ApiService.getGameLanding(gid, function(err, d) {
            if (!err) {
                try {
                    // Mise à jour du score et statut si disponible
                    if (d.awayTeam && d.awayTeam.score !== undefined) det.ag = d.awayTeam.score
                    if (d.homeTeam && d.homeTeam.score !== undefined) det.hg = d.homeTeam.score
                    if (d.gameState) det.status = Logic.getStatusFromGame(d)
                    if (d.periodDescriptor) {
                        det.period = d.periodDescriptor.number || 0
                        det.pType = d.periodDescriptor.periodType || ''
                    }
                    if (d.clock) {
                        det.interm = d.clock.inIntermission || false
                        det.remain = d.clock.timeRemaining || ""
                        det.intermRemain = d.clock.inIntermission ? (d.clock.timeRemaining || "") : ""
                    }

                    // ── Preview pour les matchs à venir ─────────────────
                    if (det.status === 'UPCOMING') {
                        var pv = {}
                        pv.startMs = det.start || 0
                        var venue = d.venue
                        pv.venue = venue ? (venue.default || venue) : ''
                        pv.seriesAway  = 0
                        pv.seriesHome  = 0
                        pv.seriesTotal = false

                        function parseRecord(team) {
                            if (!team || !team.record) return { wins:'–', losses:'–', ot:'–' }
                            var rec = team.record
                            if (typeof rec === 'string') {
                                var p = rec.split('-')
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

                        function parseLeaders(scLeaders, side) {
                            if (!scLeaders || !scLeaders.length) return []
                            var catOrder = ['points', 'goals', 'assists']
                            var result = []
                            for (var oi = 0; oi < catOrder.length; oi++) {
                                var cat = catOrder[oi]
                                for (var ci = 0; ci < scLeaders.length; ci++) {
                                    var row = scLeaders[ci]
                                    if ((row.category || '').toLowerCase() !== cat) continue
                                    var p = side === 'away' ? row.awayLeader : row.homeLeader
                                    if (!p) continue
                                    var name = p.name ? (p.name.default || '') : ''
                                    result.push({
                                        id:    p.playerId || 0,
                                        cat:   cat,
                                        name:  name,
                                        value: p.value !== undefined ? p.value : '–'
                                    })
                                    break
                                }
                            }
                            return result
                        }
                        var scLeaders = (d.matchup && d.matchup.skaterComparison && d.matchup.skaterComparison.leaders) || []
                        pv.awayLeaders = parseLeaders(scLeaders, 'away')
                        pv.homeLeaders = parseLeaders(scLeaders, 'home')

                        function parseGoalie(teamData) {
                            if (!teamData) return null
                            var leaders = teamData.leaders || []
                            var g = leaders.length > 0 ? leaders[0] : null
                            if (!g) return null
                            var name = g.name ? (g.name.default || '') : ''
                            if (!name) return null
                            var recStr = '–'
                            if (g.record !== undefined) {
                                if (typeof g.record === 'string') {
                                    recStr = g.record
                                } else if (typeof g.record === 'object') {
                                    var r = g.record
                                    recStr = (r.wins||0) + '-' + (r.losses||0) + (r.otLosses !== undefined ? '-' + r.otLosses : '')
                                }
                            }
                            var gaa = g.gaa !== undefined ? parseFloat(g.gaa).toFixed(3)
                                    : g.goalsAgainstAverage !== undefined ? parseFloat(g.goalsAgainstAverage).toFixed(3) : '–'
                            var svp = g.savePctg !== undefined ? g.savePctg : (g.savePercentage !== undefined ? g.savePercentage : null)
                            return {
                                id:     g.playerId || 0,
                                name:   name,
                                record: recStr,
                                gaa:    gaa,
                                svPct:  svp !== null ? Number(svp).toFixed(3) : '–'
                            }
                        }
                        var glComp = (d.matchup && d.matchup.goalieComparison) || null
                        pv.awayGoalie = parseGoalie(glComp ? glComp.awayTeam : null)
                        pv.homeGoalie = parseGoalie(glComp ? glComp.homeTeam : null)

                        det.venue       = pv.venue || ''
                        // Ne pas écraser si déjà rempli par fetchH2H (évite le clignotement)
                        if (det.seriesAway === 0 && det.seriesHome === 0) {
                            det.seriesAway  = pv.seriesAway  || 0
                            det.seriesHome  = pv.seriesHome  || 0
                        }
                        det.seriesTotal = pv.seriesTotal || det.seriesTotal || false
                        if (pv.h2hGames && pv.h2hGames.length > 0) {
                            det.h2hGames = pv.h2hGames
                        }
                        if (pv.awayRecord && pv.awayRecord.wins !== '–') {
                            det.awayRecord  = (pv.awayRecord.wins||'–')+'-'+(pv.awayRecord.losses||'–')+'-'+(pv.awayRecord.ot||'–')
                        }
                        if (pv.homeRecord && pv.homeRecord.wins !== '–') {
                            det.homeRecord  = (pv.homeRecord.wins||'–')+'-'+(pv.homeRecord.losses||'–')+'-'+(pv.homeRecord.ot||'–')
                        }
                        det.awayLeaders = pv.awayLeaders || []
                        det.homeLeaders = pv.homeLeaders || []
                        det.awayGoalie  = pv.awayGoalie  || null
                        det.homeGoalie  = pv.homeGoalie  || null

                        // ── Comparaison d'équipe (Saison) ──────────────────
                        var tcRaw = (d.matchup && d.matchup.teamComparison) || []
                        if (tcRaw.length > 0) {
                            var tcList = []
                            for (var tci = 0; tci < tcRaw.length; tci++) {
                                var item = tcRaw[tci]
                                var label = item.label || ""
                                if (label === "ppPctg" || label === "pkPctg" || label === "faceoffWinPctg" || 
                                    label === "goalsForPerGame" || label === "goalsAgainstPerGame") {
                                    tcList.push({ label: label, away: item.awayValue, home: item.homeValue })
                                }
                            }
                            det.teamComparison = tcList
                        }
                    }

                    // ── Buts pour les matchs commencés / terminés ────────
                    var goalsList = []
                    var periods = (d.summary && d.summary.scoring) ? d.summary.scoring : []
                    for (var p = 0; p < periods.length; p++) {
                        var ps = periods[p]
                        var pnum  = ps.periodDescriptor ? (ps.periodDescriptor.number || (p+1)) : (p+1)
                        var ptype = ps.periodDescriptor ? (ps.periodDescriptor.periodType || '') : ''
                        var pname = ptype === 'SO' ? 'SO' : ptype === 'OT' ? (pnum === 4 ? 'OT' : (pnum - 3) + 'OT') : String(pnum)
                        var gs = ps.goals || []
                        for (var gi = 0; gi < gs.length; gi++) {
                            var gl = gs[gi]
                            var scorer = gl.firstName ? (gl.firstName.default || '') + ' ' + (gl.lastName.default || '') : (gl.name && gl.name.default ? gl.name.default : '?')
                            var assists = []
                            if (gl.assists) {
                                for (var ai = 0; ai < gl.assists.length; ai++) {
                                    var a = gl.assists[ai]
                                    var aName = a.firstName ? (a.firstName.default || '') + ' ' + (a.lastName.default || '') : (a.name && a.name.default ? a.name.default : '?')
                                    assists.push({ id: a.playerId || 0, name: aName, assistsToDate: a.assistsToDate !== undefined ? a.assistsToDate : -1 })
                                }
                            }
                            goalsList.push({
                                period: pname, time: gl.timeInPeriod || '',
                                team: gl.teamAbbrev ? (gl.teamAbbrev.default || gl.teamAbbrev) : '',
                                scorerId: gl.playerId || 0, scorer: scorer,
                                goalsToDate: gl.goalsToDate !== undefined ? gl.goalsToDate : -1,
                                assists: assists, ppg: gl.strength === 'pp', shg: gl.strength === 'sh',
                                en: gl.goalModifier === 'empty-net' || gl.emptyNet === true,
                                highlightId: gl.highlightClip || 0
                            })
                        }
                    }
                    det.goals = goalsList

                    // ── Pénalités ──────────────────────────────────
                    var penData = d.summary && d.summary.penalties
                    if (penData && Array.isArray(penData)) {
                        var penList = []
                        for (var pi = 0; pi < penData.length; pi++) {
                            var pperiod = penData[pi]
                            var pd2 = pperiod.periodDescriptor || {}
                            var pnum2 = pd2.number || 1
                            var ptype2 = (pd2.periodType || '').toUpperCase()
                            var pname2 = ptype2 === 'SO' ? 'SO' : ptype2 === 'OT' ? (pnum2 === 4 ? 'OT' : (pnum2 - 3) + 'OT') : String(pnum2)
                            var ppens = pperiod.penalties || []
                            for (var pj = 0; pj < ppens.length; pj++) {
                                var pen = ppens[pj]
                                var cb = pen.committedByPlayer || {}
                                var pfn = cb.firstName ? (cb.firstName.default || '') : ''
                                var pln = cb.lastName  ? (cb.lastName.default  || '') : ''
                                var db = pen.drawnBy || {}
                                var dfn = db.firstName ? (db.firstName.default || '') : ''
                                var dln = db.lastName  ? (db.lastName.default  || '') : ''
                                penList.push({
                                    period: pname2, time: pen.timeInPeriod || '',
                                    team: pen.teamAbbrev ? (pen.teamAbbrev.default || pen.teamAbbrev) : '',
                                    player: pfn + ' ' + pln, playerId: cb.playerId || 0,
                                    number: cb.sweaterNumber || 0, duration: pen.duration || 2,
                                    type: pen.type || '', descKey: pen.descKey || '',
                                    drawnBy: dfn ? dfn + ' ' + dln : ''
                                })
                            }
                        }
                        det.penalties = penList
                        if (Object.keys(det.playerMap).length > 0) root.resolvePenaltyIds(det.playerMap)
                    }

                    // ── 3 étoiles ────────────────────────────────
                    var stars = d.summary && d.summary.threeStars
                    if (stars && Array.isArray(stars)) {
                        det.threeStars = stars.map(function(s) {
                            var name = s.name ? (s.name.default || s.name) : ''
                            return {
                                star: s.star || 0, id: s.playerId || 0, name: name,
                                team: s.teamAbbrev ? (s.teamAbbrev.default || s.teamAbbrev) : '',
                                position: s.position || '',
                                goals: s.goals !== undefined ? s.goals : -1,
                                assists: s.assists !== undefined ? s.assists : -1,
                                toi: s.toi || ''
                            }
                        })
                    }
                } catch(e) { det.error = 'landing: ' + e }
            } else {
                det.error = 'HTTP (landing): ' + String(err)
            }
            tryDone()
        })

        // boxscore → stats d'équipe
        Logic.ApiService.getGameBoxscore(gid, function(err, d) {
            if (!err) {
                try {
                    var st = {}
                    var awSog = d.awayTeam && d.awayTeam.sog !== undefined ? d.awayTeam.sog : null
                    var hmSog = d.homeTeam && d.homeTeam.sog !== undefined ? d.homeTeam.sog : null
                    if (awSog !== null && hmSog !== null) st['sog'] = { away: awSog, home: hmSog }
                    var ts = d.teamGameStats || []
                    for (var i = 0; i < ts.length; i++) {
                        var row = ts[i]
                        st[row.category || ''] = { away: row.awayValue !== undefined ? row.awayValue : '—', home: row.homeValue !== undefined ? row.homeValue : '—' }
                    }
                    var pg = d.playerByGameStats || {}
                    var pmap = {}
                    function indexTeamPlayers(team, abbrev) {
                        var all = (team.forwards||[]).concat(team.defense||[]).concat(team.goalies||[])
                        for (var pi3 = 0; pi3 < all.length; pi3++) {
                            var pl = all[pi3]
                            if (pl.playerId && pl.sweaterNumber) pmap[abbrev + '-' + pl.sweaterNumber] = pl.playerId
                        }
                    }
                    indexTeamPlayers(pg.awayTeam || {}, det.away)
                    indexTeamPlayers(pg.homeTeam || {}, det.home)
                    det.playerMap = pmap
                    root.resolvePenaltyIds(pmap)
                    function sumTeam(team) {
                        var all = (team.forwards||[]).concat(team.defense||[])
                        var r = {hits:0, pim:0, blockedShots:0, giveaways:0, takeaways:0}
                        for (var i=0; i<all.length; i++) {
                            var p = all[i]
                            r.hits += p.hits || 0; r.pim += p.pim || 0; r.blockedShots += p.blockedShots || 0
                            r.giveaways += p.giveaways || 0; r.takeaways += p.takeaways || 0
                        }
                        var goalies = team.goalies || []
                        for (var gi=0; gi<goalies.length; gi++) r.pim += goalies[gi].pim || 0
                        return r
                    }
                    var awStats = sumTeam(pg.awayTeam || {})
                    var hmStats = sumTeam(pg.homeTeam || {})
                    st['hits']         = { away: awStats.hits,         home: hmStats.hits }
                    st['pim']          = { away: awStats.pim,          home: hmStats.pim }
                    st['blockedShots'] = { away: awStats.blockedShots, home: hmStats.blockedShots }
                    st['giveaways']    = { away: awStats.giveaways,    home: hmStats.giveaways }
                    st['takeaways']    = { away: awStats.takeaways,    home: hmStats.takeaways }
                    det.stats = st
                } catch(e) { det.error = 'boxscore: ' + e }
            } else {
                det.error = 'HTTP (boxscore): ' + String(err)
            }
            tryDone()
        })
    }

    // Timer rafraîchissement automatique du popup détail
    Timer {
        id: detailRefreshTimer
        interval: 20000
        running: nav.detail && det.status === 'LIVE'
        repeat: true
        onTriggered: {
            if (nav.detail) {
                // Mettre à jour le score depuis le modèle si le match est toujours là
                for (let i = 0; i < todayGames.count; i++) {
                    let g = todayGames.get(i)
                    if (g.gameId === det.gameId) {
                        det.ag      = g.ag
                        det.hg      = g.hg
                        det.period  = g.period
                        det.remain  = g.liveRemain
                        det.status  = g.statusRole
                        det.pType   = g.periodType
                        if (g.statusRole === 'LIVE')
                            det.sitCode = g.situationCode || '1551'
                        break
                    }
                }
                // Recharger les buts et stats
                fetchDetail(det.gameId)
            }
        }
    }

    // ── fullRepresentation : popup natif Plasma, bien positionné ─────────
    // ── Modèle plat pour la vue standings ───────────────────────────────
    // Reconstruit quand std.data change
    ListModel { id: standingsFlatModel }

    // standingsFlatModel stocke des primitives seulement (limitation ListModel).
    // Pour les lignes d'équipe, on stocke les champs directement à plat.
    function buildStandingsModel() {
        standingsFlatModel.clear()
        // Amorce avec tous les champs pour initialiser les rôles QML
        standingsFlatModel.append({ 
            type:"_init_", label:"", abbrev:"", city:"", gp:0, w:0, l:0, ot:0, pts:0, gf:0, ga:0,
            sow:0, sol:0, hw:0, hl:0, hot:0, rw:0, rl:0, rot:0, l10w:0, l10l:0, l10ot:0, streak:""
        })
        standingsFlatModel.remove(0)

        var rows = []
        var labels = { atlantic: i18n("Atlantic"), metro: i18n("Metropolitan"), central: i18n("Central"), pacific: i18n("Pacific"), 
                       east: i18n("Eastern Conference"), west: i18n("Western Conference"), wc: i18n("Wild Card") }

        if (std.mode === 'league') {
            rows = Logic.parseLeagueStandings(std.data, std.sortKey, std.sortAsc)
        } else if (std.mode === 'division') {
            rows = Logic.parseDivisionStandings(std.data, labels)
        } else {
            rows = Logic.parseWildCardStandings(std.data, labels)
        }

        for (var i = 0; i < rows.length; i++) {
            standingsFlatModel.append(rows[i])
        }
    }

    Connections {
        target: std
        function onDataChanged() { buildStandingsModel() }
    }


    readonly property string activeView: {
        if (nav.player)    return "player"
        if (nav.franchiseLeaders) return "franchiseLeaders"
        if (nav.leaders)   return "leaders"
        if (nav.standings) return "standings"
        if (nav.search)    return "search"
        if (nav.bracket)   return "bracket"
        if (nav.calendar)  return "calendar"
        if (nav.dayView)   return "dayView"
        if (nav.schedule)  return "schedule"
        if (nav.teamHub)   return "teamHub"
        if (nav.detail)    return "detail"
        return "desktop"
    }

    fullRepresentation: Item {
        id: fullRoot
        implicitWidth:  root.isDesktop ? 440 : 440
        implicitHeight: root.isDesktop ? 520 : 520
        Layout.minimumWidth: root.showCompactDesktop ? 160 : 400
        Layout.minimumHeight: root.showCompactDesktop ? 60 : 300
        Layout.fillWidth:  root.isDesktop
        Layout.fillHeight: root.isDesktop

        // ── Objets de contrôle pour le popup ──────────────────────────
        QtObject {
            id: popupNav
            property bool standings: false; property bool leaders: false; property bool search: false
            property bool teamHub: false; property bool player: false; property bool schedule: false
            property bool franchiseLeaders: false; property bool bracket: false; property bool calendar: false
            property bool dayView: false; property bool detail: true

            // Synchronisation avec StackView : si une vue secondaire est fermée via nav, on pop
            onStandingsChanged: if (!standings && popupStack.depth > 1) popupStack.pop()
            onLeadersChanged: if (!leaders && popupStack.depth > 1) popupStack.pop()
            onSearchChanged: if (!search && popupStack.depth > 1) popupStack.pop()
            onTeamHubChanged: if (!teamHub && popupStack.depth > 1) popupStack.pop()
            onPlayerChanged: if (!player && popupStack.depth > 1) popupStack.pop()
            onScheduleChanged: if (!schedule && popupStack.depth > 1) popupStack.pop()
            onFranchiseLeadersChanged: if (!franchiseLeaders && popupStack.depth > 1) popupStack.pop()
            onBracketChanged: if (!bracket && popupStack.depth > 1) popupStack.pop()
            onCalendarChanged: if (!calendar && popupStack.depth > 1) popupStack.pop()
            onDayViewChanged: if (!dayView && popupStack.depth > 1) popupStack.pop()
        }

        QtObject {
            id: popupProxy
            property var det: root.det; property var glob: root.glob; property var std: root.std
            property var lead: root.lead; property var srch: root.srch; property var hub: root.hub
            property var flead: root.flead; property var sch: root.sch; property var cal: root.cal
            property var brk: root.brk; property var ply: root.ply; property var day: root.day
            property var standingsFlatModelAlias: root.standingsFlatModelAlias
            property var styles: root.styles
            property color liveColor: root.liveColor; property bool showLogos: root.showLogos
            property bool showAllTeams: root.showAllTeams; property var favoriteTeams: root.favoriteTeams
            property var nav: popupNav; property bool isPopup: true; property var popupRef: detailPopup

            function teamLogoUrl(c) { return root.teamLogoUrl(c) }
            function teamColorAdapted(c,o,a,t) { return root.teamColorAdapted(c,o,a,t) }            function teamTextColor(c,o,a) { return root.teamTextColor(c,o,a) }
            function parseSituation(s,a,h) { return root.parseSituation(s,a,h) }
            function statusSuffix(s,p) { return root.statusSuffix(s,p) }
            function liveClockText(p,n,r) { return root.liveClockText(p,n,r) }
            function livePeriodText(p,n) { return root.livePeriodText(p,n) }
            function localTimeStr(m) { return root.localTimeStr(m) }
            function localeDateLong(m) { return root.localeDateLong(m) }
            function statusColor(s) { return root.statusColor(s) }
            function badgeLine1(st, rs, pt, p, lr, sm, ht, i) { return root.badgeLine1(st, rs, pt, p, lr, sm, ht, i) }
            function badgeLine2(st, sm, ht, pt, p, lr, i, ir) { return root.badgeLine2(st, sm, ht, pt, p, lr, i, ir) }
            function penaltyDesc(p) { return root.penaltyDesc(p) }
            function blinkOpacity(g,s) { return root.blinkOpacity(g,s) }
            function gameCenterUrl(a,h,s,g) { return root.gameCenterUrl(a,h,s,g) }
            function buildStandingsModel() { root.buildStandingsModel() }
            function refresh() { root.fetchDetail(root.det.gameId) }
            function closePopup() { detailPopup.visible = false }
            function goBack() { if (popupStack.depth > 1) popupStack.pop(); else detailPopup.visible = false }

            function openStandings() { popupNav.standings=true; root.fetchStandings(); popupStack.push(standingsViewComp, {"ctrl": popupProxy}) }
            function openLeaders() { popupNav.leaders=true; root.fetchLeaders(); popupStack.push(leadersViewComp, {"ctrl": popupProxy}) }
            function openSearch() { popupNav.search=true; popupStack.push(searchViewComp, {"ctrl": popupProxy}) }
            function openTeamHub(c,f) { popupNav.teamHub=true; root.fetchTeamHub(c,f); popupStack.push(teamHubViewComp, {"ctrl": popupProxy}) }
            function openPlayer(id,f) { popupNav.player=true; root.fetchPlayer(id); popupStack.push(playerViewComp, {"ctrl": popupProxy}) }
            function openSchedule(c,s) { popupNav.schedule=true; if(s)root.fetchTeamStats(c); else root.fetchSchedule(c); popupStack.push(scheduleViewComp, {"ctrl": popupProxy}) }
            function openFranchiseLeaders(c) { popupNav.franchiseLeaders=true; root.fetchFranchiseLeaders(c); popupStack.push(franchiseLeadersViewComp, {"ctrl": popupProxy}) }
            function openPlayoffBracket() { popupNav.bracket=true; root.fetchPlayoffBracket(); popupStack.push(bracketViewComp, {"ctrl": popupProxy}) }
            function openSimulationBracket() { popupNav.bracket=true; root.fetchPlayoffBracket(); popupStack.push(bracketViewComp, {"ctrl": popupProxy}) }
            function openCalendar() { popupNav.calendar=true; popupStack.push(calendarViewComp, {"ctrl": popupProxy}) }
            function openDayView(d) { popupNav.dayView=true; root.fetchDayView(d); popupStack.push(dayViewComp, {"ctrl": popupProxy}) }
            function openDetail(gid,a,h,as,hs,st,pt,p,r,s,i,sc,ir) {
                root.det.gameId = gid; root.det.away = a; root.det.home = h;
                root.det.ag = as; root.det.hg = hs; root.det.status = st;
                root.det.pType = pt; root.det.period = p; root.det.remain = r;
                root.det.start = s; root.det.interm = i; root.det.sitCode = sc;
                root.det.intermRemain = ir || "";
                root.fetchDetail(gid);
                popupStack.push(detailViewComp, {"ctrl": popupProxy})
            }
        }

        PlasmaCore.Dialog {
            id: detailPopup; visualParent: fullRoot; location: Plasmoid.location; type: PlasmaCore.Dialog.AppletPopup
            visible: false; flags: Qt.WindowStaysOnTopHint
            mainItem: Item {
                width: 440; height: 540
                StackView {
                    id: popupStack; anchors.fill: parent; initialItem: detailViewComp
                    Component.onCompleted: if (currentItem) currentItem.ctrl = popupProxy
                }
            }
            onVisibleChanged: { if (visible) { while(popupStack.depth > 1) popupStack.pop(); root.fetchDetail(root.det.gameId) } }
            Component.onCompleted: root.popupRef = detailPopup
        }

        StackView { id: mainStack; anchors.fill: parent; initialItem: desktopViewComp }

        Connections {
            target: root
            function onActiveViewChanged() {
                if (root.activeView === "desktop") { while (mainStack.depth > 1) mainStack.pop() }
                else {
                    var comp = null
                    if (root.activeView === "detail") comp = detailViewComp
                    else if (root.activeView === "standings") comp = standingsViewComp
                    else if (root.activeView === "leaders") comp = leadersViewComp
                    else if (root.activeView === "search") comp = searchViewComp
                    else if (root.activeView === "teamHub") comp = teamHubViewComp
                    else if (root.activeView === "player") comp = playerViewComp
                    else if (root.activeView === "schedule") comp = scheduleViewComp
                    else if (root.activeView === "franchiseLeaders") comp = franchiseLeadersViewComp
                    else if (root.activeView === "bracket") comp = bracketViewComp
                    else if (root.activeView === "calendar") comp = calendarViewComp
                    else if (root.activeView === "dayView") comp = dayViewComp
                    if (comp) { if (mainStack.depth > 1) mainStack.replace(comp); else mainStack.push(comp) }
                }
            }
        }

        Component { id: desktopViewComp; Loader { id: ldDesktop; property var ctrl: root; width: parent ? parent.width : 0; height: parent ? parent.height : 0; source: "views/DesktopRepresentation.qml"; Binding { target: ldDesktop.item; property: "controller"; value: ldDesktop.ctrl; when: ldDesktop.status === Loader.Ready } } }
        Component { id: detailViewComp; Loader { id: ldDetail; property var ctrl: root; width: parent ? parent.width : 0; height: parent ? parent.height : 0; source: "views/DetailView.qml"; Binding { target: ldDetail.item; property: "controller"; value: ldDetail.ctrl; when: ldDetail.status === Loader.Ready } } }
        Component { id: standingsViewComp; Loader { id: ldStand; property var ctrl: root; width: parent ? parent.width : 0; height: parent ? parent.height : 0; source: "views/StandingsView.qml"; Binding { target: ldStand.item; property: "controller"; value: ldStand.ctrl; when: ldStand.status === Loader.Ready } } }
        Component { id: franchiseLeadersViewComp; Loader { id: ldFlead; property var ctrl: root; width: parent ? parent.width : 0; height: parent ? parent.height : 0; source: "views/FranchiseLeadersView.qml"; Binding { target: ldFlead.item; property: "controller"; value: ldFlead.ctrl; when: ldFlead.status === Loader.Ready } } }
        Component { id: leadersViewComp; Loader { id: ldLead; property var ctrl: root; width: parent ? parent.width : 0; height: parent ? parent.height : 0; source: "views/LeadersView.qml"; Binding { target: ldLead.item; property: "controller"; value: ldLead.ctrl; when: ldLead.status === Loader.Ready } } }
        Component { id: searchViewComp; Loader { id: ldSrch; property var ctrl: root; width: parent ? parent.width : 0; height: parent ? parent.height : 0; source: "views/SearchView.qml"; Binding { target: ldSrch.item; property: "controller"; value: ldSrch.ctrl; when: ldSrch.status === Loader.Ready } } }
        Component { id: teamHubViewComp; Loader { id: ldHub; property var ctrl: root; width: parent ? parent.width : 0; height: parent ? parent.height : 0; source: "views/TeamHubView.qml"; Binding { target: ldHub.item; property: "controller"; value: ldHub.ctrl; when: ldHub.status === Loader.Ready } } }
        Component { id: playerViewComp; Loader { id: ldPly; property var ctrl: root; width: parent ? parent.width : 0; height: parent ? parent.height : 0; source: "views/PlayerView.qml"; Binding { target: ldPly.item; property: "controller"; value: ldPly.ctrl; when: ldPly.status === Loader.Ready } } }
        Component { id: scheduleViewComp; Loader { id: ldSch; property var ctrl: root; width: parent ? parent.width : 0; height: parent ? parent.height : 0; source: "views/ScheduleView.qml"; Binding { target: ldSch.item; property: "controller"; value: ldSch.ctrl; when: ldSch.status === Loader.Ready } } }
        Component { id: bracketViewComp;  Loader { id: ldBrk; property var ctrl: root; width: parent ? parent.width : 0; height: parent ? parent.height : 0; source: "views/BracketView.qml";  Binding { target: ldBrk.item; property: "controller"; value: ldBrk.ctrl; when: ldBrk.status === Loader.Ready } } }
        Component { id: calendarViewComp; Loader { id: ldCal; property var ctrl: root; width: parent ? parent.width : 0; height: parent ? parent.height : 0; source: "views/CalendarView.qml"; Binding { target: ldCal.item; property: "controller"; value: ldCal.ctrl; when: ldCal.status === Loader.Ready } } }
        Component { id: dayViewComp;      Loader { id: ldDay; property var ctrl: root; width: parent ? parent.width : 0; height: parent ? parent.height : 0; source: "views/DayView.qml";      Binding { target: ldDay.item; property: "controller"; value: ldDay.ctrl; when: ldDay.status === Loader.Ready } } }
    }
}
