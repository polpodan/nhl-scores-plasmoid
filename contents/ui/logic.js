// logic.js
.pragma library

const teamColors = {
    'ANA':'#F47A38','UTA':'#6E2B62','BOS':'#FFB81C','BUF':'#003087','CAR':'#CC0000',
    'CBJ':'#002654','CGY':'#C8102E','CHI':'#CF0A2C','COL':'#6F263D','DAL':'#006847',
    'DET':'#CE1126','EDM':'#FF4C00','FLA':'#C8102E','LAK':'#111111','MIN':'#154734',
    'MTL':'#AF1E2D','NJD':'#CE1126','NSH':'#FFB81C','NYI':'#00539B','NYR':'#0038A8',
    'OTT':'#C52032','PHI':'#F74902','PIT':'#FFB81C','SEA':'#99D9D9','SJS':'#006D75',
    'STL':'#002F87','TBL':'#002868','TOR':'#00205B','VAN':'#00205B','VGK':'#B4975A',
    'WPG':'#041E42','WSH':'#C8102E'
};

function pad2(n) { return (n < 10 ? "0" : "") + n; }
function dateISO(d) { return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate()); }

function teamLogoUrl(code) {
    if (!code) return "";
    return "https://assets.nhle.com/logos/nhl/svg/" + String(code).toUpperCase() + "_light.svg";
}

function getTeamColor(code, fallback) {
    var c = teamColors[String(code || '').toUpperCase()];
    if (c) return c;
    return (fallback !== undefined && fallback !== null) ? fallback : "#888888";
}

function isSameDay(a, b) { return a.getFullYear()===b.getFullYear() && a.getMonth()===b.getMonth() && a.getDate()===b.getDate(); }

// --- Timezone & Venue helpers ---
function getTeamZone(code) {
    switch(String(code||'')){
        case 'BOS': case 'BUF': case 'CAR': case 'CBJ': case 'DET': case 'FLA': case 'MTL': case 'NJD': case 'NYI': case 'NYR': case 'OTT': case 'PHI': case 'PIT': case 'TBL': case 'TOR': case 'WSH':
            return 'ET';
        case 'CHI': case 'DAL': case 'MIN': case 'NSH': case 'STL': case 'WPG':
            return 'CT';
        case 'COL': case 'CGY': case 'EDM': case 'UTA':
            return 'MT';
        case 'ANA': case 'LAK': case 'SEA': case 'SJS': case 'VAN': case 'VGK':
            return 'PT';
        default:
            return 'ET';
    }
}

function zoneBaseOffsetHours(zone){
    if(zone==='ET') return -5;
    if(zone==='CT') return -6;
    if(zone==='MT') return -7;
    if(zone==='PT') return -8;
    return -5;
}

function nthSundayOfMonth(year, month0, n){
    var d = new Date(Date.UTC(year, month0, 1));
    var dow = d.getUTCDay();
    var firstSunday = 1 + ((7 - dow) % 7);
    return firstSunday + 7*(n-1);
}

function firstSundayNovember(year){ return nthSundayOfMonth(year, 10, 1); }
function secondSundayMarch(year){ return nthSundayOfMonth(year, 2, 2); }

function isDstDateLocalLike(year, month0, day, zone){
    var dStart = secondSundayMarch(year);
    var dEnd = firstSundayNovember(year);
    if(month0>2 && month0<10) return true;
    if(month0<2 || month0>10) return false;
    if(month0===2) return day>=dStart;
    if(month0===10) return day<dEnd;
    return false;
}

function venueTimeStr(msUTC, homeTeam) {
    var zone = getTeamZone(homeTeam);
    var dStd = new Date(msUTC + zoneBaseOffsetHours(zone)*3600*1000);
    var dst  = isDstDateLocalLike(dStd.getUTCFullYear(), dStd.getUTCMonth(), dStd.getUTCDate(), zone);
    var off  = zoneBaseOffsetHours(zone) + (dst ? 1 : 0);
    var shifted = new Date(msUTC + off*3600*1000);
    var h = shifted.getUTCHours();
    var m = shifted.getUTCMinutes();
    return pad2(h) + ':' + pad2(m);
}

function getDayViewTimeLabel(msUTC, homeTeam, dateMode) {
    if (dateMode === 'venue') return venueTimeStr(msUTC, homeTeam);
    var d = new Date(msUTC);
    return pad2(d.getHours()) + ':' + pad2(d.getMinutes());
}

// --- Logic de match ---
function isScoreSet(g) {
    return g && g.homeTeam && g.awayTeam && g.homeTeam.score !== undefined && g.awayTeam.score !== undefined;
}

function getStatusFromGame(g) {
    var s = (g && g.gameState) ? String(g.gameState).toUpperCase() : '';
    if (s==='LIVE' || s==='IN_PROGRESS') return 'LIVE';
    if (s==='FINAL' || s==='FINAL_OT' || s==='FINAL_SO') return 'FINAL';
    if (s==='PRE' || s==='FUT' || s==='SCHEDULED' || s==='PREGAME') return 'UPCOMING';
    if (s==='OFF') {
        var start = new Date(g.startTimeUTC || new Date());
        var now = new Date();
        if (isScoreSet(g) && (now.getTime() - start.getTime()) > 30*60000) return 'FINAL';
        return 'UPCOMING';
    }
    var pd = g && g.periodDescriptor ? (g.periodDescriptor.periodType || '').toUpperCase() : '';
    if (pd==='FINAL') return 'FINAL';
    var outcome = g && g.gameOutcome ? String(g.gameOutcome).toUpperCase() : '';
    if (outcome && outcome !== 'UNDEFINED') return 'FINAL';
    var st = new Date(g.startTimeUTC || new Date());
    var now2 = new Date();
    if (st.getTime() > now2.getTime() + 5*60000) return 'UPCOMING';
    if (isScoreSet(g)) return 'LIVE';
    return 'UPCOMING';
}

function getStatusSuffix(rawState, periodType, showOvertimeSuffix) {
    if (!showOvertimeSuffix) return '';
    var s = (rawState || '').toUpperCase();
    var pd = (periodType || '').toUpperCase();
    if (s.indexOf('OT') >= 0 || pd === 'OT') return ' OT';
    if (s.indexOf('SO') >= 0 || pd === 'SO') return ' SO';
    return '';
}

function getLiveClockText(periodType, period, timeRemaining) {
    if (!timeRemaining) { return ""; }
    if (periodType === "OT") { return "OT " + timeRemaining; }
    if (periodType === "SO") { return "SO"; }
    if (period === 1) { return "1st " + timeRemaining; }
    if (period === 2) { return "2nd " + timeRemaining; }
    if (period === 3) { return "3rd " + timeRemaining; }
    return "";
}

function getLivePeriodText(periodType, period, labels) {
    if (periodType === "SO") return labels.SO || "SO";
    if (periodType === "OT") return "OT";
    if (period === 1) return labels.first || "1st";
    if (period === 2) return labels.second || "2nd";
    if (period === 3) return labels.third || "3rd";
    if (period > 3)   return (period - 3) + "OT";
    return "";
}

function getTeamTextColor(code) {
    var hex = teamColors[String(code||'').toUpperCase()];
    if (!hex) return 'white';
    hex = hex.replace('#', '');
    var r = parseInt(hex.substring(0,2), 16) / 255;
    var g = parseInt(hex.substring(2,4), 16) / 255;
    var b = parseInt(hex.substring(4,6), 16) / 255;
    r = r <= 0.03928 ? r / 12.92 : Math.pow((r + 0.055) / 1.055, 2.4);
    g = g <= 0.03928 ? g / 12.92 : Math.pow((g + 0.055) / 1.055, 2.4);
    b = b <= 0.03928 ? b / 12.92 : Math.pow((b + 0.055) / 1.055, 2.4);
    var L = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    return L > 0.35 ? '#111111' : 'white';
}

function resolveNHLAbbrev(teamCommonName) {
    if (!teamCommonName) return '';
    var name = (teamCommonName.default || teamCommonName).toLowerCase();
    var table = {
        'ducks': 'ANA', 'coyotes': 'UTA', 'utah hockey club': 'UTA',
        'bruins': 'BOS', 'sabres': 'BUF', 'hurricanes': 'CAR',
        'blackhawks': 'CHI', 'avalanche': 'COL', 'blue jackets': 'CBJ',
        'stars': 'DAL', 'red wings': 'DET', 'oilers': 'EDM',
        'panthers': 'FLA', 'kings': 'LAK', 'wild': 'MIN',
        'canadiens': 'MTL', 'predators': 'NSH', 'devils': 'NJD',
        'islanders': 'NYI', 'rangers': 'NYR', 'senators': 'OTT',
        'flyers': 'PHI', 'penguins': 'PIT', 'blues': 'STL',
        'lightning': 'TBL', 'maple leafs': 'TOR', 'canucks': 'VAN',
        'golden knights': 'VGK', 'jets': 'WPG', 'capitals': 'WSH',
        'kraken': 'SEA', 'sharks': 'SJS', 'flames': 'CGY',
        'nashville predators': 'NSH',
        'thrashers': 'ATL', 'nordiques': 'QUE', 'whalers': 'HFD',
        'scouts': 'KCS', 'rockies': 'CLR', 'barons': 'CLE',
        'seals': 'CAL', 'california golden seals': 'CGS',
        'phoenix coyotes': 'PHX', 'minnesota north stars': 'MNS',
        'north stars': 'MNS', 'mighty ducks': 'ANA',
        'atlanta thrashers': 'ATL', 'winnipeg jets': 'WPG',
        'hartford whalers': 'HFD', 'quebec nordiques': 'QUE'
    };
    return table[name] || '';
}

function parseSituation(code, away, home) {
    if (!code || code.length < 4) return null;
    var ag = parseInt(code[0]);
    var as = parseInt(code[1]);
    var hs = parseInt(code[2]);
    var hg = parseInt(code[3]);
    if (isNaN(ag) || isNaN(as) || isNaN(hs) || isNaN(hg)) return null;
    if (as < 0 || as > 6 || hs < 0 || hs > 6) return null;
    var enTeam = ag === 0 ? away : (hg === 0 ? home : '');
    if (as === hs && as >= 5 && enTeam === '') return null;
    if (as === hs) {
        var isSpecial = (as < 5 || enTeam !== '');
        return { ppTeam: '', shTeam: '', ppType: as + 'v' + hs,
                 awaySkaters: as, homeSkaters: hs,
                 emptyNet: enTeam !== '', enTeam: enTeam, even: true,
                 isSpecial: isSpecial };
    }
    var ppTeam  = as > hs ? away : home;
    var shTeam  = as > hs ? home : away;
    var ppCount = Math.abs(as - hs);
    var ppType  = ppCount === 1 ? 'PP' : '5v3';
    return { ppTeam: ppTeam, shTeam: shTeam, ppType: ppType,
             awaySkaters: as, homeSkaters: hs,
             emptyNet: enTeam !== '', enTeam: enTeam, even: false,
             isSpecial: true };
}

function httpGet(url, cb) {
    let xhr = new XMLHttpRequest();
    xhr.open("GET", url);
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try { cb(null, JSON.parse(xhr.responseText)); } catch(e) { cb(e, null); }
            } else { cb(new Error("HTTP " + xhr.status + " @ " + url), null); }
        }
    };
    xhr.send();
}

const ApiService = {
    BASE_URL: "https://api-web.nhle.com/v1",
    SEARCH_URL: "https://search.d3.nhle.com/api/v1",

    getScoreboard: function(date, cb) {
        httpGet(this.BASE_URL + "/scoreboard/" + date, cb);
    },
    getScoreboardNow: function(teamCode, cb) {
        httpGet(this.BASE_URL + "/scoreboard/" + teamCode + "/now", cb);
    },
    getSchedule: function(date, cb) {
        httpGet(this.BASE_URL + "/schedule/" + date, cb);
    },
    getScore: function(date, cb) {
        httpGet(this.BASE_URL + "/score/" + date, cb);
    },
    getStandings: function(cb) {
        httpGet(this.BASE_URL + "/standings/now", cb);
    },
    getGameClock: function(gameId, cb) {
        httpGet(this.BASE_URL + "/gamecenter/" + gameId + "/play-by-play", cb);
    },
    getGameLanding: function(gameId, cb) {
        httpGet(this.BASE_URL + "/gamecenter/" + gameId + "/landing", cb);
    },
    getGameBoxscore: function(gameId, cb) {
        httpGet(this.BASE_URL + "/gamecenter/" + gameId + "/boxscore", cb);
    },
    getSkaterLeaders: function(limit, isRookie, category, cb) {
        var rookiePart = isRookie ? '&isRookie=1' : '';
        httpGet(this.BASE_URL + "/skater-stats-leaders/current?limit=" + limit + rookiePart + "&categories=" + category, cb);
    },
    getGoalieLeaders: function(limit, isRookie, categories, cb) {
        var rookiePart = isRookie ? '&isRookie=1' : '';
        httpGet(this.BASE_URL + "/goalie-stats-leaders/current?categories=" + categories + "&limit=" + limit + rookiePart, cb);
    },
    getPlayerLanding: function(playerId, cb) {
        httpGet(this.BASE_URL + "/player/" + playerId + "/landing", cb);
    },
    getPlayoffBracket: function(cb) {
        httpGet(this.BASE_URL + "/playoff-bracket/now", cb);
    },
    getTeamSchedule: function(teamCode, cb) {
        httpGet(this.BASE_URL + "/club-schedule-season/" + teamCode + "/now", cb);
    },
    getTeamStats: function(teamCode, cb) {
        httpGet(this.BASE_URL + "/club-stats/" + teamCode + "/now", cb);
    },
    searchPlayers: function(query, cb) {
        var url = this.SEARCH_URL + "/search/player?q=" + encodeURIComponent(query) + "&culture=fr-CA&limit=20";
        httpGet(url, cb);
    }
};

// --- Data Transformation Helpers (Optimization A) ---

function leagueSortVal(t, key) {
    switch(key) {
        case 'pts':    return t.points          || 0;
        case 'w':      return t.wins            || 0;
        case 'l':      return t.losses          || 0;
        case 'ot':     return t.otLosses        || 0;
        case 'gp':     return t.gamesPlayed     || 0;
        case 'gf':     return t.goalFor         || 0;
        case 'ga':     return t.goalAgainst     || 0;
        case 'so':     return (t.shootoutWins||0) + (t.shootoutLosses||0);
        case 'home':   return (t.homeWins||0)*2 - (t.homeLosses||0);
        case 'away':   return (t.roadWins||0)*2 - (t.roadLosses||0);
        case 'l10':    return (t.l10Wins||0)*2  - (t.l10Losses||0);
        case 'streak': return parseInt(t.streakCount) || 0;
        default:       return t.points          || 0;
    }
}

function parseLeagueStandings(data, sortKey, sortAsc) {
    var all = (data || []).slice();
    all.sort(function(a, b) {
        var av = leagueSortVal(a, sortKey);
        var bv = leagueSortVal(b, sortKey);
        if (av === bv) {
            if (b.points !== a.points) return b.points - a.points;
            return b.wins - a.wins;
        }
        return sortAsc ? (av < bv ? -1 : 1) : (bv < av ? -1 : 1);
    });
    
    var result = [];
    result.push({ type: "leagueHeader" });
    for (var i = 0; i < all.length; i++) {
        var t = all[i];
        result.push({
            type:   "leagueTeam",
            abbrev: t.teamAbbrev  ? (t.teamAbbrev.default  || t.teamAbbrev)  : "?",
            city:   t.teamCommonName ? (t.teamCommonName.default || t.teamCommonName) : "",
            gp: t.gamesPlayed || 0, w: t.wins || 0, l: t.losses || 0, ot: t.otLosses || 0, pts: t.points || 0,
            gf: t.goalFor || 0, ga: t.goalAgainst || 0, 
            sow: t.shootoutWins || 0, sol: t.shootoutLosses || 0,
            hw: t.homeWins || 0, hl: t.homeLosses || 0, hot: t.homeOtLosses || 0,
            rw: t.roadWins || 0, rl: t.roadLosses || 0, rot: t.roadOtLosses || 0,
            l10w: t.l10Wins || 0, l10l: t.l10Losses || 0, l10ot: t.l10OtLosses || 0,
            streak: (t.streakCode || '') + String(t.streakCount || '')
        });
    }
    return result;
}

function parseDivisionStandings(data, labels) {
    var divs = [
        { api: "Atlantic",      label: labels.atlantic || "Atlantic" },
        { api: "Metropolitan",  label: labels.metro    || "Metropolitan" },
        { api: "Central",       label: labels.central  || "Central" },
        { api: "Pacific",       label: labels.pacific  || "Pacific" }
    ];
    var result = [];
    for (var di = 0; di < divs.length; di++) {
        var div = divs[di];
        var teams = data.filter(function(t) { return t.divisionName === div.api; });
        teams.sort(function(a,b) {
            if (b.points !== a.points) return b.points - a.points;
            return b.wins - a.wins;
        });
        result.push({ type: "divHeader", label: div.label });
        result.push({ type: "colHeader" });
        for (var k = 0; k < teams.length; k++) {
            if (k === 3) result.push({ type: "wcSeparator" });
            var t = teams[k];
            result.push({
                type: "team",
                abbrev: t.teamAbbrev ? (t.teamAbbrev.default || t.teamAbbrev) : "?",
                city:   t.placeName  ? (t.placeName.default  || t.placeName)  : "",
                gp: t.gamesPlayed || 0, w: t.wins || 0, l: t.losses || 0, ot: t.otLosses || 0, pts: t.points || 0
            });
        }
    }
    return result;
}

function parseWildCardStandings(data, labels) {
    var confs = [
        { abbrev: "E", name: labels.east || "Eastern",
          divs: [ { api: "Atlantic",      label: labels.atlantic },
                  { api: "Metropolitan",  label: labels.metro } ] },
        { abbrev: "W", name: labels.west || "Western",
          divs: [ { api: "Central",       label: labels.central },
                  { api: "Pacific",       label: labels.pacific } ] }
    ];
    var result = [];
    for (var ci = 0; ci < confs.length; ci++) {
        var conf = confs[ci];
        var confTeams = data.filter(function(t) { return t.conferenceAbbrev === conf.abbrev; });
        result.push({ type: "confHeader", label: conf.name });
        result.push({ type: "colHeader" });
        for (var di = 0; di < conf.divs.length; di++) {
            var div = conf.divs[di];
            var divTeams = confTeams.filter(function(t) { return t.divisionName === div.api; });
            divTeams.sort(function(a,b){ return a.divisionSequence - b.divisionSequence; });
            result.push({ type: "divHeader", label: div.label });
            for (var k = 0; k < Math.min(3, divTeams.length); k++) {
                var dt = divTeams[k];
                result.push({
                    type: "team",
                    abbrev: dt.teamAbbrev ? (dt.teamAbbrev.default || dt.teamAbbrev) : "?",
                    city:   dt.placeName  ? (dt.placeName.default  || dt.placeName)  : "",
                    gp: dt.gamesPlayed || 0, w: dt.wins || 0, l: dt.losses || 0, ot: dt.otLosses || 0, pts: dt.points || 0
                });
            }
        }
        var wc = confTeams.filter(function(t) { 
            return t.divisionSequence > 3 || (!t.divisionSequence && t.wildcardSequence);
        });
        wc.sort(function(a,b){
            if (b.points !== a.points) return b.points - a.points;
            return b.wins - a.wins;
        });
        result.push({ type: "wcHeader", label: labels.wc || "Wild Card" });
        for (var wci = 0; wci < wc.length; wci++) {
            if (wci === 2) result.push({ type: "wcSeparator" });
            var wt = wc[wci];
            result.push({
                type: "team",
                abbrev: wt.teamAbbrev ? (wt.teamAbbrev.default || wt.teamAbbrev) : "?",
                city:   wt.placeName  ? (wt.placeName.default  || wt.placeName)  : "",
                gp: wt.gamesPlayed || 0, w: wt.wins || 0, l: wt.losses || 0, ot: wt.otLosses || 0, pts: wt.points || 0
            });
        }
    }
    return result;
}

function parseLeaders(players, category) {
    var res = [];
    for (var i = 0; i < players.length; i++) {
        var p = players[i];
        var fname = p.firstName ? (p.firstName.default || '') : '';
        var lname = p.lastName  ? (p.lastName.default  || '') : '';
        res.push({
            id:    p.id || p.playerId || 0,
            name:  fname + ' ' + lname,
            team:  p.teamAbbrev ? (p.teamAbbrev.default || p.teamAbbrev) : '',
            value: p.value || 0,
            cat:   category || '',
            position: p.positionCode || p.position || '',
            rookie: p.isRookie === true || p.rookie === true
        });
    }
    return res;
}
