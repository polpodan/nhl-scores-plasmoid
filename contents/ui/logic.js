// logic.js - Version 5.4.8 (COMPLETE RECOVERY - 2026-04-12)
.pragma library

const teamColors = {
    'ANA': { p: '#F47A38', s: '#B9975B' },
    'UTA': { p: '#6E2B62', s: '#000000' },
    'BOS': { p: '#FFB81C', s: '#000000' },
    'BUF': { p: '#003087', s: '#FFB81C' },
    'CAR': { p: '#CC0000', s: '#000000' },
    'CBJ': { p: '#002654', s: '#CE1126' },
    'CGY': { p: '#C8102E', s: '#F1BE48' },
    'CHI': { p: '#CF0A2C', s: '#FFD100' },
    'COL': { p: '#6F263D', s: '#236192' },
    'DAL': { p: '#006847', s: '#8F8F8C' },
    'DET': { p: '#CE1126', s: '#FFFFFF' },
    'EDM': { p: '#FF4C00', s: '#041E42' },
    'FLA': { p: '#C8102E', s: '#041E42' },
    'LAK': { p: '#111111', s: '#A2AAAD' },
    'MIN': { p: '#154734', s: '#A6192E' },
    'MTL': { p: '#AF1E2D', s: '#192168' },
    'NJD': { p: '#CE1126', s: '#111111' },
    'NSH': { p: '#FFB81C', s: '#041E42' },
    'NYI': { p: '#00539B', s: '#F47D30' },
    'NYR': { p: '#0038A8', s: '#CE1126' },
    'OTT': { p: '#C52032', s: '#C69214' },
    'PHI': { p: '#F74902', s: '#000000' },
    'PIT': { p: '#FFB81C', s: '#000000' },
    'SEA': { p: '#99D9D9', s: '#001628' },
    'SJS': { p: '#006D75', s: '#EA7208' },
    'STL': { p: '#002F87', s: '#FCB514' },
    'TBL': { p: '#002868', s: '#F0F0F0' },
    'TOR': { p: '#00205B', s: '#F0F0F0' },
    'VAN': { p: '#00205B', s: '#00843D' },
    'VGK': { p: '#B4975A', s: '#333F42' },
    'WPG': { p: '#041E42', s: '#AC162C' },
    'WSH': { p: '#C8102E', s: '#041E42' },
    'ARI': { p: '#8C2633', s: '#E2D6B5' },
    // Franchises Historiques
    'HFD': { p: '#00A651', s: '#0055A4' }, // Hartford Whalers (Vert/Bleu)
    'QUE': { p: '#005DAA', s: '#FFFFFF' }, // Nordiques de Québec (Bleu/Blanc)
    'WIN': { p: '#002E62', s: '#C8102E' }, // Winnipeg Jets 1.0 (Bleu/Rouge)
    'MNS': { p: '#008A4B', s: '#FFCC00' }, // Minnesota North Stars (Vert/Jaune)
    'ATL': { p: '#041E42', s: '#5C88B1' }, // Atlanta Thrashers (Bleu/Bleu ciel)
    'CLR': { p: '#002868', s: '#C8102E' }, // Colorado Rockies (Bleu/Rouge)
    'KCS': { p: '#0046AD', s: '#CE1126' }, // Kansas City Scouts (Bleu/Rouge)
    'AFM': { p: '#D2001C', s: '#FFCC00' }, // Atlanta Flames (Rouge/Jaune)
    'OAK': { p: '#006241', s: '#FFB81C' }, // Oakland Seals (Vert/Jaune)
    'CGS': { p: '#006241', s: '#FFB81C' }, // California Golden Seals
    'CLE': { p: '#C8102E', s: '#000000' }, // Cleveland Barons (Rouge/Noir)
    'MMR': { p: '#632432', s: '#FFFFFF' }, // Montreal Maroons (Marron/Blanc)
    'NYA': { p: '#002868', s: '#C8102E' }, // NY Americans (Bleu/Rouge)
    'BRK': { p: '#002868', s: '#C8102E' }, // Brooklyn Americans
    'SEN': { p: '#C8102E', s: '#000000' }, // Ottawa Senators (Old)
    'SLE': { p: '#C8102E', s: '#000000' }, // St. Louis Eagles
    'HAM': { p: '#000000', s: '#FFB81C' }, // Hamilton Tigers (Noir/Jaune)
    'PTP': { p: '#000000', s: '#FFB81C' }, // Pittsburgh Pirates
    'PHQ': { p: '#C8102E', s: '#000000' }, // Philadelphia Quakers
    'TSP': { p: '#006241', s: '#FFFFFF' }, // Toronto St. Patricks
    'TAN': { p: '#00205B', s: '#FFFFFF' }  // Toronto Arenas
};

const TEAM_STANLEY_CUPS = {
    'MTL': 24, 'TOR': 13, 'DET': 11, 'BOS': 6, 'CHI': 6, 
    'PIT': 5, 'EDM': 5, 'NYI': 4, 'NYR': 4, 'TBL': 3, 
    'NJD': 3, 'COL': 3, 'LAK': 2, 'PHI': 2, 'DAL': 1, 
    'CGY': 1, 'ANA': 1, 'CAR': 1, 'STL': 1, 'WSH': 1, 
    'VGK': 1, 'FLA': 1
};

const TEAM_FOUNDING_YEARS = {
    'ANA': 1993, 'ARI': 1979, 'BOS': 1924, 'BUF': 1970, 'CAR': 1979, 'CBJ': 2000,
    'CGY': 1972, 'CHI': 1926, 'COL': 1979, 'DAL': 1967, 'DET': 1926, 'EDM': 1979,
    'FLA': 1993, 'LAK': 1967, 'MIN': 2000, 'MTL': 1917, 'NJD': 1974, 'NSH': 1998,
    'NYI': 1972, 'NYR': 1926, 'OTT': 1992, 'PHI': 1967, 'PIT': 1967, 'SEA': 2021,
    'SJS': 1991, 'STL': 1967, 'TBL': 1992, 'TOR': 1917, 'UTA': 2024, 'VAN': 1970,
    'VGK': 2017, 'WPG': 1999, 'WSH': 1974
};

const TEAM_HISTORY = {
    'CAR': [ { year: 1997, logo: 'HFD' } ],
    'COL': [ { year: 1995, logo: 'QUE' } ],
    'ARI': [ { year: 1996, logo: 'WIN' } ],
    'DAL': [ { year: 1993, logo: 'MNS' } ],
    'WPG': [ { year: 2011, logo: 'ATL' } ],
    'CGY': [ { year: 1980, logo: 'AFM' } ],
    'NJD': [ { year: 1982, logo: 'CLR' }, { year: 1976, logo: 'KCS' } ]
};

let _cache = {};

function getTeamFoundingYear(code) {
    return TEAM_FOUNDING_YEARS[String(code).toUpperCase()] || 1917;
}

function getHistoricalLogo(code, seasonStr) {
    if (!seasonStr || seasonStr === 'now') return code;
    var year = parseInt(String(seasonStr).substring(0, 4));
    var history = TEAM_HISTORY[code.toUpperCase()];
    if (!history) return code;
    // On trie par année descendante pour trouver la période correcte
    for (var i = 0; i < history.length; i++) {
        if (year < history[i].year) return history[i].logo;
    }
    return code;
}

function getStanleyCupsCount(code) {
    return TEAM_STANLEY_CUPS[String(code).toUpperCase()] || 0;
}
let _configRef = null;

function initializeCache(configObject) {
    _configRef = configObject;
    try { _cache = JSON.parse(_configRef.cacheData || "{}"); } catch(e) { _cache = {}; }
}

function saveToCache(key, data) {
    let now = new Date().getTime();

    // Nettoyage avant insertion
    pruneCache(now);

    _cache[key] = {
        timestamp: now,
        content: data
    };

    if (_configRef) {
        _configRef.cacheData = JSON.stringify(_cache);
    }
}

function pruneCache(now) {
    let keys = Object.keys(_cache);

    // 1. Suppression par expiration
    for (let i = 0; i < keys.length; i++) {
        let k = keys[i];
        let entry = _cache[k];
        let age = now - entry.timestamp;

        // Scores : expirent après 48h (172 800 000 ms)
        if (k.indexOf("scoreboard") === 0 && age > 172800000) {
            delete _cache[k];
            continue;
        }
        // Joueurs : expirent après 7 jours (604 800 000 ms)
        if (k.indexOf("player") === 0 && age > 604800000) {
            delete _cache[k];
            continue;
        }
        // Sécurité globale : rien ne reste plus de 15 jours
        if (age > 1296000000) {
            delete _cache[k];
        }
    }

    // 2. Limitation du nombre total (Max 100 entrées)
    keys = Object.keys(_cache);
    if (keys.length > 100) {
        // On trie par timestamp pour supprimer les plus vieux
        keys.sort(function(a, b) {
            return _cache[a].timestamp - _cache[b].timestamp;
        });
        let toRemove = keys.length - 100;
        for (let j = 0; j < toRemove; j++) {
            delete _cache[keys[j]];
        }
    }
}


function getFromCache(key, maxAgeMs) {
    let entry = _cache[key]; if (!entry) return null;
    if (maxAgeMs !== undefined) { let now = new Date().getTime(); if (now - entry.timestamp > maxAgeMs) return null; }
    return entry.content;
}

function pad2(n) { return (n < 10 ? "0" : "") + n; }
function dateISO(d) { return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate()); }
function teamLogoUrl(code) { return "https://assets.nhle.com/logos/nhl/svg/" + String(code).toUpperCase() + "_light.svg"; }

function getLuminance(hex) {
    if (!hex) return 0;
    var s = String(hex).toLowerCase();
    if (s === "white" || s === "#ffffff" || s === "#ffffffff") return 1.0;
    if (s === "black" || s === "#000000" || s === "#000000ff") return 0.0;

    s = s.replace('#', '');
    if (s.length === 3 || s.length === 4) s = s[0]+s[0]+s[1]+s[1]+s[2]+s[2];

    var r = parseInt(s.substring(0, 2), 16) / 255;
    var g = parseInt(s.substring(2, 4), 16) / 255;
    var b = parseInt(s.substring(4, 6), 16) / 255;

    if (isNaN(r) || isNaN(g) || isNaN(b)) return 0.5;

    r = (r <= 0.03928) ? r / 12.92 : Math.pow((r + 0.055) / 1.055, 2.4);
    g = (g <= 0.03928) ? g / 12.92 : Math.pow((g + 0.055) / 1.055, 2.4);
    b = (b <= 0.03928) ? b / 12.92 : Math.pow((b + 0.055) / 1.055, 2.4);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function getContrastColor(colorAttr) { 
    if (!colorAttr) return "#ffffff";
    var hex = colorAttr.toString();
    return getLuminance(hex) > 0.35 ? "#000000" : "#ffffff"; 
}

function getContrast(L1, L2) {
    var b = Math.max(L1, L2); var d = Math.min(L1, L2);
    return (b + 0.05) / (d + 0.05);
}

function shadeColor(hex, percent) {
    var s = String(hex).replace('#', '');
    var r = parseInt(s.substring(0, 2), 16);
    var g = parseInt(s.substring(2, 4), 16);
    var b = parseInt(s.substring(4, 6), 16);
    r = Math.min(255, Math.max(0, parseInt(r * (100 + percent) / 100)));
    g = Math.min(255, Math.max(0, parseInt(g * (100 + percent) / 100)));
    b = Math.min(255, Math.max(0, parseInt(b * (100 + percent) / 100)));
    return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
}

function getTeamColor(code, variant) {
    var entry = teamColors[String(code || '').toUpperCase()];
    if (!entry) return "#888888";
    return (variant === 's') ? (entry.s || entry.p) : entry.p;
}

function getTeamBadgeTextColor(teamCode) { return getContrastColor(getTeamColor(teamCode)); }

function getTeamColorAdapted(teamCode, opponentCode, isAway, forText, bgColor) {
    var t = String(teamCode || '').toUpperCase();
    var o = String(opponentCode || '').toUpperCase();
    var entry = teamColors[t]; if (!entry) return "#888888";
    var bgHex = bgColor ? bgColor.toString() : "#ffffff"; var Lbg = getLuminance(bgHex);
    var primary = entry.p; var secondary = entry.s || entry.p;
    var targetContrast = forText ? 4.5 : 2.0;
    var finalColor = primary;

    // PROTECTION : Sur fond clair, on interdit le blanc pour ces équipes (trop risqué pour la lisibilité)
    if (Lbg > 0.4 && (t === 'TBL' || t === 'TOR' || t === 'DET')) {
        return primary; 
    }

    if ((t === 'TOR' && o === 'TBL') || (t === 'TBL' && o === 'TOR')) {
        if (Lbg < 0.5) { if (isAway) return "#00AFFF"; return "#FFFFFF"; }
        else { if (isAway) return "#00205B"; return "#005FFF"; }
    }

    if (getContrast(getLuminance(primary), Lbg) < targetContrast) {
        if (getContrast(getLuminance(secondary), Lbg) > getContrast(getLuminance(primary), Lbg)) {
            finalColor = secondary;
        }
    }

    if (opponentCode) {
        var oppEntry = teamColors[o];
        if (oppEntry) {
            var oppFinal = (getContrast(getLuminance(oppEntry.p), Lbg) < targetContrast && oppEntry.s) ? oppEntry.s : oppEntry.p;
            if (getContrast(getLuminance(finalColor), getLuminance(oppFinal)) < 1.35) {
                if (isAway) {
                    var alt = (finalColor === primary) ? secondary : primary;
                    if (getContrast(getLuminance(alt), getLuminance(oppFinal)) > 1.35) finalColor = alt;
                }
            }
        }
    }

    if (getContrast(getLuminance(finalColor), Lbg) < 1.4) {
        finalColor = (Lbg > 0.5) ? shadeColor(finalColor, -40) : shadeColor(finalColor, 40);
    }
    return finalColor;
}

function getTeamTextColor(teamCode, opponentCode, isAway, bgColor) { 
    return getTeamColorAdapted(teamCode, opponentCode, isAway, true, bgColor); 
}

function isScoreSet(g) { if (!g) return false; var st = getStatusFromGame(g); return st === 'LIVE' || st === 'FINAL'; }
function getStatusFromGame(g) { if (!g) return 'UPCOMING'; var state = g.gameState || ''; if (state === 'LIVE' || state === 'CRIT') return 'LIVE'; if (state === 'FINAL' || state === 'OFF' || state === 'OFFICIAL') return 'FINAL'; return 'UPCOMING'; }
function getStatusSuffix(rawState, periodType, showOT, labels) { 
    if (!showOT) return ""; 
    if (periodType === 'SO') return " " + (labels.SO || "SO"); 
    if (periodType === 'OT') return " " + (labels.OT || "OT"); 
    return ""; 
}
function getLiveClockText(periodType, period, timeRemaining, labels) { if (periodType === 'SO') return labels.SO || "SO"; var pText = getLivePeriodText(periodType, period, labels); return pText + (timeRemaining ? " " + timeRemaining : ""); }
function getLivePeriodText(periodType, period, labels) { if (periodType === 'SO') return labels.SO || "SO"; if (period === 1) return labels.first || "1st"; if (period === 2) return labels.second || "2nd"; if (period === 3) return labels.third || "3rd"; if (period > 3) return (period - 3) + (labels.OT || "OT"); return ""; }
function parseSituation(code, away, home) { if (!code || code === "1551" || code.length !== 4) return null; var aG = code[0] === '1', aS = parseInt(code[1]), hS = parseInt(code[2]), hG = code[3] === '1'; var res = { even: (aS === hS), empty_Net: (!aG || !hG), enTeam: (!aG ? away : (!hG ? home : '')), ppTeam: (aS > hS ? away : (hS > aS ? home : '')), awaySkaters: aS, homeSkaters: hS, isSpecial: (aS !== hS || !aG || !hG) }; if (aS > hS) res.ppType = (aS - hS > 1) ? "5v3 PP" : "PP"; else if (hS > aS) res.ppType = (hS - aS > 1) ? "5v3 PP" : "PP"; else res.ppType = ""; return res; }
function resolveNHLAbbrev(commonName) {
    if (!commonName) return "";
    var name = String(commonName).normalize("NFD").replace(/[\u0300-\u036f]/g, ""); 
    var pairs = [
        ["Leafs", "TOR"], ["Toronto", "TOR"], ["Canadiens", "MTL"], ["Montreal", "MTL"],
        ["Canucks", "VAN"], ["Vancouver", "VAN"], ["Senators", "OTT"], ["Ottawa", "OTT"],
        ["Jets", "WPG"], ["Winnipeg", "WPG"], ["Oilers", "EDM"], ["Edmonton", "EDM"],
        ["Flames", "CGY"], ["Calgary", "CGY"], ["Bruins", "BOS"], ["Boston", "BOS"],
        ["Sabres", "BUF"], ["Buffalo", "BUF"], ["Red Wings", "DET"], ["Detroit", "DET"],
        ["Panthers", "FLA"], ["Florida", "FLA"], ["Lightning", "TBL"], ["Tampa", "TBL"],
        ["Hurricanes", "CAR"], ["Carolina", "CAR"], ["Blue Jackets", "CBJ"], ["Columbus", "CBJ"],
        ["Devils", "NJD"], ["Jersey", "NJD"], ["Islanders", "NYI"], ["Rangers", "NYR"],
        ["Flyers", "PHI"], ["Philadelphia", "PHI"], ["Penguins", "PIT"], ["Pittsburgh", "PIT"],
        ["Capitals", "WSH"], ["Washington", "WSH"], ["Blackhawks", "CHI"], ["Chicago", "CHI"],
        ["Avalanche", "COL"], ["Colorado Rockies", "CLR"], ["Rockies", "CLR"], ["Colorado", "COL"],
        ["Stars", "DAL"], ["Dallas", "DAL"], ["Wild", "MIN"], ["Minnesota", "MIN"],
        ["Predators", "NSH"], ["Nashville", "NSH"], ["Blues", "STL"], ["Louis", "STL"],
        ["Ducks", "ANA"], ["Anaheim", "ANA"], ["Kings", "LAK"], ["Angeles", "LAK"],
        ["Sharks", "SJS"], ["Jose", "SJS"], ["Kraken", "SEA"], ["Seattle", "SEA"],
        ["Golden Knights", "VGK"], ["Vegas", "VGK"], ["Coyotes", "ARI"], ["Arizona", "ARI"],
        ["Whalers", "HFD"], ["Hartford", "HFD"], ["Nordiques", "QUE"], ["Quebec", "QUE"],
        ["North Stars", "MNS"], ["Minnesota North Stars", "MNS"],
        ["Thrashers", "ATL"], ["Atlanta", "ATL"], ["Scouts", "KCS"], ["Kansas City", "KCS"],
        ["California Golden Seals", "CGS"], ["Golden Seals", "CGS"], ["Oakland Seals", "OAK"], ["California Seals", "OAK"], ["Seals", "OAK"],
        ["Cleveland Barons", "CLE"], ["Barons", "CLE"], ["Montreal Maroons", "MMR"],
        ["Maroons", "MMR"], ["New York Americans", "NYA"], ["Brooklyn Americans", "BRK"],
        ["Americans", "NYA"], ["Hamilton", "HAM"], ["Pittsburgh Pirates", "PTP"],
        ["Philadelphia Quakers", "PHQ"], ["Quakers", "PHQ"], ["St. Louis Eagles", "SLE"], ["Eagles", "SLE"],
        ["Senators (1917)", "SEN"], ["Toronto St. Patricks", "TSP"], ["Toronto Arenas", "TAN"]
        ];
    for (var i = 0; i < pairs.length; i++) {
        if (name.indexOf(pairs[i][0]) !== -1) {
            // console.log("NHL Scores Debug - Resolved '" + name + "' to '" + pairs[i][1] + "'");
            return pairs[i][1];
        }
    }
    return "";
}

function getDayViewTimeLabel(msUTC, homeTeam, mode) {
    if (mode === 'venue') return venueTimeStr(msUTC, homeTeam);
    return localTimeStr(msUTC);
}

function getTeamZone(code) { switch(String(code||'')){ case 'BOS': case 'BUF': case 'CAR': case 'CBJ': case 'DET': case 'FLA': case 'MTL': case 'NJD': case 'NYI': case 'NYR': case 'OTT': case 'PHI': case 'PIT': case 'TBL': case 'TOR': case 'WSH': return 'ET'; case 'CHI': case 'DAL': case 'MIN': case 'NSH': case 'STL': case 'WPG': return 'CT'; case 'COL': case 'CGY': case 'EDM': case 'UTA': return 'MT'; case 'ANA': case 'LAK': case 'SEA': case 'SJS': case 'VAN': case 'VGK': return 'PT'; default: return 'ET'; } }
function zoneBaseOffsetHours(zone){ if(zone==='ET') return -5; if(zone==='CT') return -6; if(zone==='MT') return -7; if(zone==='PT') return -8; return -5; }
function nthSundayOfMonth(year, month0, n){ var d = new Date(Date.UTC(year, month0, 1)); var dow = d.getUTCDay(); var firstSunday = 1 + ((7 - dow) % 7); return firstSunday + 7*(n-1); }
function firstSundayNovember(year){ return nthSundayOfMonth(year, 10, 1); }
function secondSundayMarch(year){ return nthSundayOfMonth(year, 2, 2); }
function isDstDateLocalLike(year, month0, day, zone){ var dStart = secondSundayMarch(year); var dEnd = firstSundayNovember(year); if(month0>2 && month0<10) return true; if(month0<2 || month0>10) return false; if(month0===2) return day>=dStart; if(month0===10) return day<dEnd; return false; }
function venueTimeStr(msUTC, homeTeam) { if(!msUTC || !homeTeam) return ""; var d = new Date(msUTC); var zone = getTeamZone(homeTeam); var baseOff = zoneBaseOffsetHours(zone); var isDst = isDstDateLocalLike(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), zone); var totalOff = baseOff + (isDst ? 1 : 0); var local = new Date(d.getTime() + totalOff * 3600000); var h = local.getUTCHours(); var m = local.getUTCMinutes(); return (h<10?'0':'')+h+':'+(m<10?'0':'')+m; }
function localTimeStr(msUTC) { if(!msUTC) return ""; var d = new Date(msUTC); var h = d.getHours(); var m = d.getMinutes(); return (h<10?'0':'')+h+':'+(m<10?'0':'')+m; }

function httpGet(url, cb) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) { try { var res = JSON.parse(xhr.responseText); cb(null, res); } catch(e) { cb(e, null); } }
            else { cb(new Error("HTTP " + xhr.status), null); }
        }
    };
    xhr.open("GET", url); xhr.send();
}

const ApiService = {
    BASE_URL: "https://api-web.nhle.com/v1",
    STATS_BASE_URL: "https://api.nhle.com/stats/rest/en",
    SEARCH_URL: "https://search.d3.nhle.com/api/v1",
    getScoreboard: function(date, cb) { httpGet(this.BASE_URL + "/scoreboard/" + date, function(err, data) { if (err) { let cached = getFromCache("scoreboard_" + date); if (cached) cb(null, cached, true); else cb(err, null); } else { saveToCache("scoreboard_" + date, data); cb(null, data, false); } }); },
    getScoreboardNow: function(teamCode, cb) { httpGet(this.BASE_URL + "/scoreboard/" + teamCode + "/now", function(err, data) { if (err) { let cached = getFromCache("scoreboard_now_" + teamCode); if (cached) cb(null, cached, true); else cb(err, null); } else { saveToCache("scoreboard_now_" + teamCode, data); cb(null, data, false); } }); },
    getSchedule: function(date, cb) { httpGet(this.BASE_URL + "/schedule/" + date, cb); },
    getScore: function(date, cb) { httpGet(this.BASE_URL + "/score/" + date, cb); },
    getStandings: function(cb) { httpGet(this.BASE_URL + "/standings/now", function(err, data) { if (err) { let cached = getFromCache("standings"); if (cached) cb(null, cached, true); else cb(err, null); } else { saveToCache("standings", data); cb(null, data, false); } }); },
    getGameClock: function(gameId, cb) { httpGet(this.BASE_URL + "/gamecenter/" + gameId + "/play-by-play", cb); },
    getGameLanding: function(gameId, cb) { httpGet(this.BASE_URL + "/gamecenter/" + gameId + "/landing", function(err, data) { if (err) { let cached = getFromCache("game_" + gameId); if (cached) cb(null, cached, true); else cb(err, null); } else { saveToCache("game_" + gameId, data); cb(null, data, false); } }); },
    getGameRightRail: function(gameId, cb) { httpGet(this.BASE_URL + "/gamecenter/" + gameId + "/right-rail", cb); },
    getGameBoxscore: function(gameId, cb) { httpGet(this.BASE_URL + "/gamecenter/" + gameId + "/boxscore", cb); },
    getSkaterLeaders: function(limit, isRookie, category, season, seasonType, cb) { 
        var path = (season && seasonType) ? (season + "/" + seasonType) : "current";
        var r = isRookie ? '&isRookie=1' : ''; 
        httpGet(this.BASE_URL + "/skater-stats-leaders/" + path + "?limit=" + limit + r + "&categories=" + category, cb); 
    },
    getGoalieLeaders: function(limit, isRookie, categories, season, seasonType, cb) { 
        var path = (season && seasonType) ? (season + "/" + seasonType) : "current";
        var r = isRookie ? '&isRookie=1' : ''; 
        httpGet(this.BASE_URL + "/goalie-stats-leaders/" + path + "?categories=" + categories + "&limit=" + limit + r, cb); 
    },
    getPlayerLanding: function(playerId, cb) { httpGet(this.BASE_URL + "/player/" + playerId + "/landing", function(err, data) { if (err) { let cached = getFromCache("player_" + playerId); if (cached) cb(null, cached, true); else cb(err, null); } else { saveToCache("player_" + playerId, data); cb(null, data, false); } }); },
    getPlayoffBracket: function(cb) { 
        var year = new Date().getFullYear();
        if (new Date().getMonth() > 8) year++;
        var cacheKey = "playoff_bracket_" + year;
        
        httpGet(this.BASE_URL + "/playoff-bracket/" + year + "?_=" + new Date().getTime(), function(err, data) {
            if (err) {
                var cached = getFromCache(cacheKey);
                if (cached) cb(null, cached, true);
                else cb(err, null);
            } else {
                saveToCache(cacheKey, data);
                cb(null, data, false);
            }
        });
    },
    getTeamSchedule: function(teamCode, cb) { httpGet(this.BASE_URL + "/club-schedule-season/" + teamCode + "/now", cb); },
    getTeamStats: function(teamCode, season, seasonType, cb) { 
        var path = (season && seasonType) ? (season + "/" + seasonType) : "now";
        httpGet(this.BASE_URL + "/club-stats/" + teamCode + "/" + path, cb); 
    },
    getFranchiseLeaders: function(teamCode, category, limit, activeOnly, seasonType, isGoalie, pos, cb) {
        var fid = getFranchiseId(teamCode); if (fid === 0) { cb(new Error("Unknown franchise ID"), null); return; }
        var cayenne = "franchiseId=" + fid; 
        if (activeOnly) cayenne += " and active=1";
        if (seasonType) cayenne += " and gameTypeId=" + seasonType;
        
        if (pos === 'D') cayenne += " and positionCode='D'";
        else if (pos === 'F') cayenne += " and positionCode in ('C','L','R')";
        
        var endpoint = isGoalie ? "/goalie/summary" : "/skater/summary";
        var url = this.STATS_BASE_URL + endpoint + "?isAggregate=true&isGame=false" + "&sort=[{\"property\":\"" + category + "\",\"direction\":\"DESC\"}]" + "&start=0&limit=" + limit + "&cayenneExp=" + encodeURIComponent(cayenne);
        httpGet(url, cb);
    },
    searchPlayers: function(query, cb) {
        var self = this; var url = this.SEARCH_URL + "/search/player?q=" + encodeURIComponent(query) + "&culture=en-US&limit=20";
        httpGet(url, function(err, data) {
            if (!err && data && data.length > 0) { cb(null, data); return; }
            var results = []; var pending = 2;
            function done() { pending--; if (pending <= 0) { if (results.length > 0) cb(null, results); else cb(new Error("No results"), null); } }
            var skaterUrl = self.STATS_BASE_URL + "/skater/summary?isAggregate=true&isGame=false&limit=20&cayenneExp=skaterFullName%20like%20%27%25" + encodeURIComponent(query) + "%25%27";
            httpGet(skaterUrl, function(e1, d1) { if (!e1 && d1 && d1.data) { d1.data.forEach(function(p) { results.push({ playerId: p.playerId, name: p.skaterFullName, lastName: p.lastName, teamAbbrev: p.teamAbbrevs || "", positionCode: p.positionCode }); }); } done(); });
            var goalieUrl = self.STATS_BASE_URL + "/goalie/summary?isAggregate=true&isGame=false&limit=10&cayenneExp=goalieFullName%20like%20%27%25" + encodeURIComponent(query) + "%25%27";
            httpGet(goalieUrl, function(e2, d2) { if (!e2 && d2 && d2.data) { d2.data.forEach(function(p) { results.push({ playerId: p.playerId, name: p.goalieFullName, lastName: p.lastName, teamAbbrev: p.teamAbbrevs || "", positionCode: "G" }); }); } done(); });
        });
    }
};

function getFranchiseId(code) {
    var official = {
        'MTL': 1,  'TOR': 5,  'BOS': 6,  'NYR': 10, 'CHI': 11, 'DET': 12,
        'LAK': 14, 'DAL': 15, 'PHI': 16, 'PIT': 17, 'STL': 18, 'BUF': 19,
        'VAN': 20, 'CGY': 21, 'NYI': 22, 'NJD': 23, 'WSH': 24, 'EDM': 25,
        'CAR': 26, 'COL': 27, 'ARI': 28, 'SJS': 29, 'OTT': 30, 'TBL': 31,
        'ANA': 32, 'FLA': 33, 'NSH': 34, 'WPG': 35, 'CBJ': 36, 'MIN': 37,
        'VGK': 38, 'SEA': 39, 'UTA': 40
    };
    return official[String(code || '').toUpperCase()] || 0;
}

function compareTeams(a, b) {
    if (b.points !== a.points) return b.points - a.points;
    if (a.gamesPlayed !== b.gamesPlayed) return a.gamesPlayed - b.gamesPlayed;
    var arw = a.regulationWins || 0; var brw = b.regulationWins || 0; if (brw !== arw) return brw - arw;
    var arow = a.regulationPlusOtWins || 0; var brow = b.regulationPlusOtWins || 0; if (brow !== arow) return brow - arow;
    if (b.wins !== a.wins) return b.wins - a.wins;
    var adiff = (a.goalFor || 0) - (a.goalAgainst || 0); var bdiff = (b.goalFor || 0) - (b.goalAgainst || 0); if (bdiff !== adiff) return bdiff - adiff;
    return 0;
}

function leagueSortVal(t, key) {
    switch(key) {
        case 'pts': return t.points || 0; case 'w': return t.wins || 0; case 'l': return t.losses || 0;
        case 'ot': return t.otLosses || 0; case 'gp': return t.gamesPlayed || 0; case 'gf': return t.goalFor || 0;
        case 'ga': return t.goalAgainst || 0; case 'so': return (t.shootoutWins||0) + (t.shootoutLosses||0);
        case 'home': return (t.homeWins||0)*2 - (t.homeLosses||0); case 'away': return (t.roadWins||0)*2 - (t.roadLosses||0);
        case 'l10': return (t.l10Wins||0)*2 - (t.l10Losses||0); case 'streak': return parseInt(t.streakCount) || 0;
        default: return t.points || 0;
    }
}

function parseLeagueStandings(data, sortKey, sortAsc) {
    var all = (data || []).slice();
    all.sort(function(a, b) { var av = leagueSortVal(a, sortKey); var bv = leagueSortVal(b, sortKey); if (av === bv) { return compareTeams(a, b); } return sortAsc ? (av < bv ? -1 : 1) : (bv < av ? -1 : 1); });
    var result = []; result.push({ type: "leagueHeader" });
    for (var i = 0; i < all.length; i++) {
        var t = all[i]; result.push({ type: "leagueTeam", abbrev: t.teamAbbrev ? (t.teamAbbrev.default || t.teamAbbrev) : "?", city: t.teamCommonName ? (t.teamCommonName.default || t.teamCommonName) : "", clinch: t.clinchIndicator || "", gp: t.gamesPlayed || 0, w: t.wins || 0, l: t.losses || 0, ot: t.otLosses || 0, pts: t.points || 0, gf: t.goalFor || 0, ga: t.goalAgainst || 0, sow: t.shootoutWins || 0, sol: t.shootoutLosses || 0, hw: t.homeWins || 0, hl: t.homeLosses || 0, hot: t.homeOtLosses || 0, rw: t.roadWins || 0, rl: t.roadLosses || 0, rot: t.roadOtLosses || 0, l10w: t.l10Wins || 0, l10l: t.l10Losses || 0, l10ot: t.l10OtLosses || 0, streak: (t.streakCode || '') + String(t.streakCount || '') });
    }
    return result;
}

function parseDivisionStandings(data, labels) {
    var divs = [ { api: "Atlantic", label: labels.atlantic || "Atlantic" }, { api: "Metropolitan", label: labels.metro || "Metropolitan" }, { api: "Central", label: labels.central || "Central" }, { api: "Pacific", label: labels.pacific || "Pacific" } ];
    var result = [];
    for (var di = 0; di < divs.length; di++) {
        var div = divs[di]; var divTeams = data.filter(function(t) { return t.divisionName === div.api; }); divTeams.sort(compareTeams);
        result.push({ type: "divHeader", label: div.label }); result.push({ type: "colHeader" });
        for (var k = 0; k < divTeams.length; k++) { if (k === 3) result.push({ type: "wcSeparator" }); var t = divTeams[k]; result.push({ type: "team", abbrev: t.teamAbbrev ? (t.teamAbbrev.default || t.teamAbbrev) : "?", city: t.placeName ? (t.placeName.default || t.placeName) : "", clinch: t.clinchIndicator || "", gp: t.gamesPlayed || 0, w: t.wins || 0, l: t.losses || 0, ot: t.otLosses || 0, pts: t.points || 0 }); }
    }
    return result;
}

function parseWildCardStandings(data, labels) {
    var confs = [ { abbrev: "E", name: labels.east || "Eastern", divs: [ { api: "Atlantic", label: labels.atlantic }, { api: "Metropolitan", label: labels.metro } ] }, { abbrev: "W", name: labels.west || "Western", divs: [ { api: "Central", label: labels.central }, { api: "Pacific", label: labels.pacific } ] } ];
    var result = [];
    for (var ci = 0; ci < confs.length; ci++) {
        var conf = confs[ci]; var confTeams = data.filter(function(t) { return t.conferenceAbbrev === conf.abbrev; });
        result.push({ type: "confHeader", label: conf.name }); result.push({ type: "colHeader" });
        for (var di = 0; di < conf.divs.length; di++) { var div = conf.divs[di]; var divTeams = confTeams.filter(function(t) { return t.divisionName === div.api; }); divTeams.sort(compareTeams); result.push({ type: "divHeader", label: div.label }); for (var k = 0; k < Math.min(3, divTeams.length); k++) { var dt = divTeams[k]; result.push({ type: "team", abbrev: dt.teamAbbrev ? (dt.teamAbbrev.default || dt.teamAbbrev) : "?", city: dt.placeName ? (dt.placeName.default || dt.placeName) : "", clinch: dt.clinchIndicator || "", gp: dt.gamesPlayed || 0, w: dt.wins || 0, l: dt.losses || 0, ot: dt.otLosses || 0, pts: dt.points || 0 }); } }
        var wc = confTeams.filter(function(t) { return t.divisionSequence > 3 || (!t.divisionSequence && t.wildcardSequence); }); wc.sort(compareTeams);
        result.push({ type: "wcHeader", label: labels.wc || "Wild Card" });
        for (var wci = 0; wci < wc.length; wci++) { if (wci === 2) result.push({ type: "wcSeparator" }); var wt = wc[wci]; result.push({ type: "team", abbrev: wt.teamAbbrev ? (wt.teamAbbrev.default || wt.teamAbbrev) : "?", city: wt.placeName ? (wt.placeName.default || wt.placeName) : "", clinch: wt.clinchIndicator || "", gp: wt.gamesPlayed || 0, w: wt.wins || 0, l: wt.losses || 0, ot: wt.otLosses || 0, pts: wt.points || 0 }); }
    }
    return result;
}

function simulatePlayoffs(data) {
    if (!data || data.length === 0) return null;
    function getAbbr(t) { if (!t) return ""; return (t.teamAbbrev && t.teamAbbrev.default) ? t.teamAbbrev.default : (t.teamAbbrev || ""); }
    var conferences = ["W", "E"]; var divisions = { "E": ["Atlantic", "Metropolitan"], "W": ["Central", "Pacific"] }; var bracket = { rounds: [] }; var r1Series = [];
    for (var ci = 0; ci < conferences.length; ci++) {
        var conf = conferences[ci]; var confTeams = data.filter(function(t) { return t.conferenceAbbrev === conf; }); var divWinners = []; var qualifiedTop3 = []; var confDivs = divisions[conf];
        for (var di = 0; di < confDivs.length; di++) { var divName = confDivs[di]; var divTeams = confTeams.filter(function(t) { return t.divisionName === divName; }); divTeams.sort(compareTeams); if (divTeams.length >= 3) { var top3 = divTeams.slice(0, 3); divWinners.push({team: top3[0], divName: divName}); qualifiedTop3.push({teams: top3, divName: divName}); } }
        var top3Ids = []; for (var i = 0; i < qualifiedTop3.length; i++) { var group = qualifiedTop3[i]; for (var j = 0; j < group.teams.length; j++) { var teamObj = group.teams[j]; if (teamObj) top3Ids.push(getAbbr(teamObj)); } }
        var wcTeams = confTeams.filter(function(t) { return top3Ids.indexOf(getAbbr(t)) === -1; }); wcTeams.sort(compareTeams);
        var wc1 = wcTeams.length > 0 ? wcTeams[0] : null; var wc2 = wcTeams.length > 1 ? wcTeams[1] : null;
        divWinners.sort(function(a, b) { return compareTeams(a.team, b.team); }); var bestDivWinner = divWinners[0]; var otherDivWinner = divWinners[1];
        if (bestDivWinner && wc2) { r1Series.push({ conference: conf, topSeedTeam: { abbrev: getAbbr(bestDivWinner.team), seed: "D1" }, bottomSeedTeam: { abbrev: getAbbr(wc2), seed: "WC2" }, topSeedWins: 0, bottomSeedWins: 0, seriesAbbrev: "R1" }); }
        if (bestDivWinner) { var bestGroup = null; for (var k=0; k<qualifiedTop3.length; k++) { if (qualifiedTop3[k].divName === bestDivWinner.divName) { bestGroup = qualifiedTop3[k]; break; } } if (bestGroup && bestGroup.teams.length >= 3) { r1Series.push({ conference: conf, topSeedTeam: { abbrev: getAbbr(bestGroup.teams[1]), seed: "D2" }, bottomSeedTeam: { abbrev: getAbbr(bestGroup.teams[2]), seed: "D3" }, topSeedWins: 0, bottomSeedWins: 0, seriesAbbrev: "R1" }); } }
        if (otherDivWinner && wc1) { r1Series.push({ conference: conf, topSeedTeam: { abbrev: getAbbr(otherDivWinner.team), seed: "D1" }, bottomSeedTeam: { abbrev: getAbbr(wc1), seed: "WC1" }, topSeedWins: 0, bottomSeedWins: 0, seriesAbbrev: "R1" }); }
        if (otherDivWinner) { var otherGroup = null; for (var m=0; m<qualifiedTop3.length; m++) { if (qualifiedTop3[m].divName === otherDivWinner.divName) { otherGroup = qualifiedTop3[m]; break; } } if (otherGroup && otherGroup.teams.length >= 3) { r1Series.push({ conference: conf, topSeedTeam: { abbrev: getAbbr(otherGroup.teams[1]), seed: "D2" }, bottomSeedTeam: { abbrev: getAbbr(otherGroup.teams[2]), seed: "D3" }, topSeedWins: 0, bottomSeedWins: 0, seriesAbbrev: "R1" }); } }
    }
    bracket.rounds.push({ roundNumber: 1, series: r1Series });
    var r2Series = []; for(var n=0; n<4; n++) r2Series.push({ conference: n<2 ? "W" : "E", seriesAbbrev: "R2" }); bracket.rounds.push({ roundNumber: 2, series: r2Series });
    bracket.rounds.push({ roundNumber: 3, series: [{ conference: "W" }, { conference: "E" }] }); bracket.rounds.push({ roundNumber: 4, series: [{ conference: "SC" }] });
    return bracket;
}

function parseLeaders(players, category) {
    var res = []; for (var i = 0; i < players.length; i++) { var p = players[i]; var fname = p.firstName ? (p.firstName.default || '') : ''; var lname = p.lastName ? (p.lastName.default || '') : ''; res.push({ id: p.id || p.playerId || 0, name: fname + ' ' + lname, team: p.teamAbbrev ? (p.teamAbbrev.default || p.teamAbbrev) : '', value: p.value || 0, cat: category || '', position: p.positionCode || p.position || '', rookie: p.isRookie === true || p.rookie === true }); } return res;
}
