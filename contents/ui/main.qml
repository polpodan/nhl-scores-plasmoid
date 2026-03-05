import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
  id: root
  Plasmoid.title: i18n("NHL Scores")
  preferredRepresentation: compactRepresentation

  // Config (string for scoreLayout)
  property string scoreLayout: (Plasmoid.configuration.scoreLayout || 'stack') // 'stack' or 'inline'
  property var favoriteTeams: (Plasmoid.configuration.favorites || 'VAN,TOR').split(/\s*,\s*/).filter(s => s.length>0)
  property bool showAll: Plasmoid.configuration.showAll
  property bool todayOnly: Plasmoid.configuration.todayOnly
  property int compactMaxGames: Plasmoid.configuration.compactMaxGames || 2
  property int maxTotalGames: Plasmoid.configuration.maxTotalGames || 20
  property bool showOvertimeSuffix: Plasmoid.configuration.showOvertimeSuffix
  property color liveColor: Plasmoid.configuration.liveColor || '#d90429'
  property color upcomingColor: Plasmoid.configuration.upcomingColor || '#2b6cb0'
  property color finalColor: Plasmoid.configuration.finalColor || '#6c757d'

  // Model & state
  ListModel { id: todayGames }
  property date lastUpdated
  property string debugMsg: ''

  Timer { id: pollTimer; interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: refresh() }

  readonly property var teamColors: ({ 'ANA':'#F47A38','ARI':'#8C2633','UTA':'#6E2B62','BOS':'#FFB81C','BUF':'#003087','CAR':'#CC0000','CBJ':'#002654','CGY':'#C8102E','CHI':'#CF0A2C','COL':'#6F263D','DAL':'#006847','DET':'#CE1126','EDM':'#FF4C00','FLA':'#C8102E','LAK':'#111111','MIN':'#154734','MTL':'#AF1E2D','NJD':'#CE1126','NSH':'#FFB81C','NYI':'#00539B','NYR':'#0038A8','OTT':'#C52032','PHI':'#F74902','PIT':'#FFB81C','SEA':'#99D9D9','SJS':'#006D75','STL':'#002F87','TBL':'#002868','TOR':'#00205B','VAN':'#00205B','VGK':'#B4975A','WPG':'#041E42','WSH':'#C8102E' })
  function teamColor(code) { return teamColors[code] || Kirigami.Theme.positiveBackgroundColor }

  function pad2(n){ return (n<10?'0':'')+n }
  function dateISO(d){ return d.getFullYear()+'-'+pad2(d.getMonth()+1)+'-'+pad2(d.getDate()) }

  function httpGet(url, cb){ let xhr=new XMLHttpRequest(); xhr.open('GET', url); xhr.onreadystatechange=function(){ if(xhr.readyState===XMLHttpRequest.DONE){ if(xhr.status===200){ try{ cb(null, JSON.parse(xhr.responseText)) }catch(e){ cb(e,null) } } else cb(new Error('HTTP '+xhr.status+' @ '+url), null) } }; xhr.send() }

  function refresh(){ if (showAll) fetchLeagueScoreboards(); else fetchTeamScoreboards(favoriteTeams) }

  function fetchTeamScoreboards(teamCodes){ if(!teamCodes||!teamCodes.length){ todayGames.clear(); debugMsg='no favorites'; return } let acc=[]; let pending=teamCodes.length; let errors=[]; teamCodes.forEach(function(team){ const url='https://api-web.nhle.com/v1/scoreboard/'+team+'/now'; httpGet(url, function(err,data){ if(err){ errors.push(String(err)) } else if (data&&data.gamesByDate){ for(let i=0;i<data.gamesByDate.length;i++){ const gbd=data.gamesByDate[i]; if(gbd&&gbd.games){ acc=acc.concat(gbd.games) } } } pending--; if(pending===0){ buildFromRawGames(acc, errors) } }) }) }

  function fetchLeagueScoreboards(){ const now=new Date(); const days = (todayOnly ? [ now ] : [ new Date(now.getTime()-24*3600*1000), now, new Date(now.getTime()+24*3600*1000) ]); let acc=[]; let pending=days.length; let errors=[]; days.forEach(function(d){ const u='https://api-web.nhle.com/v1/scoreboard/'+dateISO(d); httpGet(u, function(err,data){ if(err){ errors.push(String(err)) } else if (data&&data.games){ acc=acc.concat(gamesFromDate(data)) } pending--; if(pending===0){ if(acc.length>0){ buildFromRawGames(acc, errors) } else { debugMsg=(errors.length? (errors.join(' | ')+' · ') : '')+'empty league endpoint → team scan'; fetchTeamScoreboards(allTeams) } } }) }) }

  function gamesFromDate(obj){ return (obj && obj.games) ? obj.games : [] }

  readonly property var allTeams: ['ANA','ARI','UTA','BOS','BUF','CAR','CBJ','CGY','CHI','COL','DAL','DET','EDM','FLA','LAK','MIN','MTL','NJD','NSH','NYI','NYR','OTT','PHI','PIT','SEA','SJS','STL','TBL','TOR','VAN','VGK','WPG','WSH']

  function isScoreSet(g){ return g && g.homeTeam && g.awayTeam && g.homeTeam.score !== undefined && g.awayTeam.score !== undefined }
  function statusFromGame(g){ var s=(g&&g.gameState)?String(g.gameState).toUpperCase():''; if(s==='LIVE'||s==='IN_PROGRESS') return 'LIVE'; if(s==='FINAL'||s==='FINAL_OT'||s==='FINAL_SO') return 'FINAL'; if(s==='PRE'||s==='FUT'||s==='SCHEDULED'||s==='PREGAME') return 'UPCOMING'; if(s==='OFF'){ var start=new Date(g.startTimeUTC||new Date()); var now=new Date(); if(isScoreSet(g)&&(now.getTime()-start.getTime())>30*60000) return 'FINAL'; return 'UPCOMING'; } var pd=g&&g.periodDescriptor?(g.periodDescriptor.periodType||'').toUpperCase():''; if(pd==='FINAL') return 'FINAL'; var outcome=g&&g.gameOutcome?String(g.gameOutcome).toUpperCase():''; if(outcome&&outcome!=='UNDEFINED') return 'FINAL'; var st=new Date(g.startTimeUTC||new Date()); var now2=new Date(); if(st.getTime()>now2.getTime()+5*60000) return 'UPCOMING'; if(isScoreSet(g)) return 'LIVE'; return 'UPCOMING'; }
  function statusText(st){ return st==='LIVE' ? 'LIVE' : (st==='FINAL' ? i18n('Final') : i18n('Upcoming')) }
  function statusSuffix(rawState, periodType){ if (!showOvertimeSuffix) return ''; var s=(rawState||'').toUpperCase(); var pd=(periodType||'').toUpperCase(); if(s.indexOf('OT')>=0 || pd==='OT') return ' OT'; if(s.indexOf('SO')>=0 || pd==='SO') return ' SO'; return ''; }
  function statusColor(st){ return st==='LIVE' ? liveColor : (st==='FINAL' ? finalColor : upcomingColor) }
  function gameCenterUrl(away, home, start, gameId){ var d=new Date(start); var y=d.getFullYear(); var m=pad2(d.getMonth()+1); var da=pad2(d.getDate()); return 'https://www.nhl.com/gamecenter/'+String(away||'').toLowerCase()+'-vs-'+String(home||'').toLowerCase()+'/'+y+'/'+m+'/'+da+'/'+String(gameId||''); }

  function buildFromRawGames(games, errors){ games=games||[]; const now=new Date(); const startWin=new Date(now.getTime()-24*3600*1000); const endWin=new Date(now.getTime()+24*3600*1000); function inWindow(g){ const t=new Date(g.startTimeUTC||now); return t>=startWin && t<=endWin } let filtered=games.filter(g=>inWindow(g)); if(!showAll && favoriteTeams.length){ filtered=filtered.filter(function(g){ const h=g.homeTeam&&g.homeTeam.abbrev; const a=g.awayTeam&&g.awayTeam.abbrev; return favoriteTeams.indexOf(h)>=0 || favoriteTeams.indexOf(a)>=0 }) } let byId={}; for(let i=0;i<filtered.length;i++){ const g=filtered[i]; byId[g.id]=g } let uniq=Object.keys(byId).map(k=>byId[k]); uniq = uniq.map(function(g){ const st = statusFromGame(g); return { gameId: g.id||0, home: (g.homeTeam&&g.homeTeam.abbrev)||'', away: (g.awayTeam&&g.awayTeam.abbrev)||'', hg: (g.homeTeam&&g.homeTeam.score!==undefined? g.homeTeam.score:0), ag: (g.awayTeam&&g.awayTeam.score!==undefined? g.awayTeam.score:0), start: new Date(g.startTimeUTC||new Date()).getTime()||999, statusRole: st, rawState: (g.gameState||''), periodType: (g.periodDescriptor && g.periodDescriptor.periodType) ? g.periodDescriptor.periodType : '' } }).sort(function(a,b){ return a.start-b.start }); todayGames.clear(); for(let i=0;i<uniq.length;i++){ todayGames.append(uniq[i]) } lastUpdated=new Date(); debugMsg=(errors&&errors.length? (errors.join(' | ')+' · ') : '')+'loaded '+todayGames.count+' game(s)'; }

  // Compact visuals (from Compact V1)
  Component { id: statusBadge
    Rectangle { property string gameStatus: 'UPCOMING'; property string suffix: ''; radius: 5; color: statusColor(gameStatus); opacity: 0.95
      Text { id: stText; anchors.centerIn: parent; text: (statusText(parent.gameStatus) + parent.suffix); color: 'white'; font.pixelSize: 10; font.bold: true }
      width: stText.implicitWidth + 6; height: stText.implicitHeight + 2 }
  }
  Component { id: teamColumn
    Column { spacing: 0; property string code: ''; property int score: 0; property color bg: teamColor(code)
      Rectangle { radius: 4; color: bg; border.color: 'white'; border.width: 1; height: nameText.implicitHeight + 1; width: nameText.implicitWidth + 6
        Text { id: nameText; anchors.centerIn: parent; text: code; color: 'white'; font.pixelSize: 11; font.bold: true } }
      Text { text: String(score); font.pixelSize: 14; font.bold: true; color: Kirigami.Theme.textColor; anchors.horizontalCenter: parent.horizontalCenter } }
  }
  Component { id: teamRowInline
    Row { spacing: 4; property string awayCode: ''; property string homeCode: ''; property int agScore: 0; property int hgScore: 0
      Rectangle { radius: 4; color: teamColor(awayCode); border.color: 'white'; border.width: 1; height: aText.implicitHeight + 1; width: aText.implicitWidth + 6
        Text { id: aText; anchors.centerIn: parent; text: awayCode; color: 'white'; font.pixelSize: 11; font.bold: true } }
      Label { text: String(agScore); font.bold: true; color: Kirigami.Theme.textColor }
      Label { text: "–"; color: Kirigami.Theme.textColor }
      Label { text: String(hgScore); font.bold: true; color: Kirigami.Theme.textColor }
      Rectangle { radius: 4; color: teamColor(homeCode); border.color: 'white'; border.width: 1; height: hText.implicitHeight + 1; width: hText.implicitWidth + 6
        Text { id: hText; anchors.centerIn: parent; text: homeCode; color: 'white'; font.pixelSize: 11; font.bold: true } } }
  }

  // Compact (panel)
  compactRepresentation: Item {
    id: compactRoot
    readonly property int pad: 6
    implicitWidth: Math.max(row.implicitWidth + pad, emptyMsg.implicitWidth + pad)
    implicitHeight: Math.max(row.implicitHeight + 2, emptyMsg.implicitHeight + 2)
    width: implicitWidth; height: implicitHeight
    Layout.preferredWidth: implicitWidth; Layout.minimumWidth: implicitWidth; Layout.maximumWidth: implicitWidth
    Layout.preferredHeight: implicitHeight; Layout.minimumHeight: implicitHeight; Layout.maximumHeight: implicitHeight

    Row { id: row; anchors.verticalCenter: parent.verticalCenter; spacing: 6; visible: todayGames.count > 0
      Repeater { model: todayGames
        delegate: Row { visible: index < compactMaxGames; spacing: 6
          Loader { sourceComponent: (scoreLayout==='stack' ? teamColumn : teamRowInline)
            onLoaded: { if (scoreLayout==='stack') { item.code = away; item.score = ag } else { item.awayCode = away; item.homeCode = home; item.agScore = ag; item.hgScore = hg } } }
          Loader { sourceComponent: (scoreLayout==='stack' ? teamColumn : null); visible: (scoreLayout==='stack'); onLoaded: { if (scoreLayout==='stack') { item.code = home; item.score = hg } } }
          Loader { sourceComponent: statusBadge; onLoaded: { item.gameStatus = statusRole; item.suffix = statusSuffix(rawState, periodType) } }
          TapHandler { acceptedButtons: Qt.LeftButton; gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: Qt.openUrlExternally(gameCenterUrl(away, home, start, gameId)); cursorShape: Qt.PointingHandCursor }
        } }
    }
    Label { id: emptyMsg; anchors.centerIn: parent; visible: todayGames.count === 0; text: i18n('No games'); color: Kirigami.Theme.textColor }
  }

  // Full (desktop) — centered content inside delegate (as per center3)
  fullRepresentation: ScrollView {
    implicitWidth: 420; implicitHeight: 480
    ColumnLayout { spacing: 8
      RowLayout { Layout.fillWidth: true
        CheckBox { text: i18n('All'); checked: showAll; onToggled: Plasmoid.configuration.showAll = checked }
        CheckBox { text: i18n('Today only'); checked: todayOnly; onToggled: Plasmoid.configuration.todayOnly = checked }
        CheckBox { text: i18n('OT/SO suffix'); checked: showOvertimeSuffix; onToggled: Plasmoid.configuration.showOvertimeSuffix = checked }
        ComboBox { id: layoutCombo; model: [ i18n('Score below (column)'), i18n('Score next to name (row)') ]
          currentIndex: (scoreLayout==='stack'?0:1)
          onActivated: Plasmoid.configuration.scoreLayout = (currentIndex===0?'stack':'inline')
          Layout.alignment: Qt.AlignRight }
        Button { text: i18n('Configure NHL Scores…'); icon.name: 'settings-configure'; onClicked: plasmoid.action('configure').trigger() }
      }
      ListView { Layout.fillWidth: true; Layout.fillHeight: true; model: todayGames
        delegate: ItemDelegate { width: ListView.view.width
          contentItem: RowLayout { anchors.horizontalCenter: parent.horizontalCenter; spacing: 12
            Loader { sourceComponent: (scoreLayout==='stack' ? teamColumn : teamRowInline)
              onLoaded: { if (scoreLayout==='stack') { item.code = away; item.score = ag } else { item.awayCode = away; item.homeCode = home; item.agScore = ag; item.hgScore = hg } } }
            Loader { sourceComponent: (scoreLayout==='stack'? teamColumn : null); visible: (scoreLayout==='stack'); onLoaded: { if (scoreLayout==='stack') { item.code = home; item.score = hg } } }
            Loader { sourceComponent: statusBadge; onLoaded: { item.gameStatus = statusRole; item.suffix = statusSuffix(rawState, periodType) } }
          }
          onClicked: Qt.openUrlExternally(gameCenterUrl(away, home, start, gameId)) }
        footer: Label { text: (lastUpdated ? i18n('Updated: %1', Qt.formatDateTime(lastUpdated, 'hh:mm:ss')) : '') + (debugMsg ? '  ·  ' + debugMsg : ''); opacity: 0.6; horizontalAlignment: Text.AlignHCenter; width: ListView.view.width }
      }
    }
  }

  // Keep scoreLayout reactive to config changes
  Connections { target: Plasmoid.configuration; function onScoreLayoutChanged(){ root.scoreLayout = Plasmoid.configuration.scoreLayout || 'stack' } }

  Plasmoid.contextualActions: [ PlasmaCore.Action { text: i18n('Refresh now'); icon.name: 'view-refresh'; onTriggered: refresh() } ]
}
