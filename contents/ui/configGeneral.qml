import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.20 as Kirigami

Item {
  id: page

  // Alias holder for Apply button
  Item { id: favHolder; property string value: plasmoid.configuration.favorites }
  property alias cfg_favorites: favHolder.value

  // Working copy
  property string favString: plasmoid.configuration.favorites || 'VAN,TOR'

  // Other config
  property alias cfg_showAll: showAllCheckBox.checked
  property alias cfg_todayOnly: todayOnlyCheck.checked
  property alias cfg_compactMaxGames: compactMax.value
  property alias cfg_maxTotalGames: capTotal.value

  // Colors & divisions
  readonly property var teamColors: ({ 'ANA':'#F47A38','ARI':'#8C2633','UTA':'#6E2B62','BOS':'#FFB81C','BUF':'#003087','CAR':'#CC0000','CBJ':'#002654','CGY':'#C8102E','CHI':'#CF0A2C','COL':'#6F263D','DAL':'#006847','DET':'#CE1126','EDM':'#FF4C00','FLA':'#C8102E','LAK':'#111111','MIN':'#154734','MTL':'#AF1E2D','NJD':'#CE1126','NSH':'#FFB81C','NYI':'#00539B','NYR':'#0038A8','OTT':'#C52032','PHI':'#F74902','PIT':'#FFB81C','SEA':'#99D9D9','SJS':'#006D75','STL':'#002F87','TBL':'#002868','TOR':'#00205B','VAN':'#00205B','VGK':'#B4975A','WPG':'#041E42','WSH':'#C8102E' })

  readonly property var divisions: [
    { title: '── Atlantic ──', teams: ['BOS','BUF','DET','FLA','MTL','OTT','TBL','TOR'] },
    { title: '── Metropolitan ──', teams: ['CAR','CBJ','NJD','NYI','NYR','PHI','PIT','WSH'] },
    { title: '── Central ──', teams: ['ARI','CHI','COL','DAL','MIN','NSH','STL','WPG'] },
    { title: '── Pacific ──', teams: ['ANA','CGY','EDM','LAK','SJS','SEA','VAN','VGK'] }
  ]

  property var selected: ({})

  function parseFavs(str){
    var arr = String(str||'').split(/\s*,\s*/).filter(s=>s.length>0);
    var map = {}; for (var i=0;i<arr.length;i++) map[arr[i]] = true; return map;
  }

  function rebuildFavString(){
    var out=[];
    for (var i=0;i<divisions.length;i++){
      var list = divisions[i].teams
      for (var j=0;j<list.length;j++){
        var a = list[j]; if (selected[a]) out.push(a);
      }
    }
    favString = out.join(',');
    favHolder.value = favString;                 // enable Apply
    plasmoid.configuration.favorites = favString // persist now
  }

  Component.onCompleted: selected = parseFavs(favString)

  // Chip
  Component { id: chipDelegate
    Item {
      implicitWidth: chipRow.implicitWidth + 12
      implicitHeight: chipRow.implicitHeight + 10
      property string abbr: ''
      property bool checked: !!selected[abbr]
      Rectangle { anchors.fill: parent; radius: 6; color: teamColors[abbr] || Kirigami.Theme.positiveBackgroundColor; border.color: checked ? '#ffffff' : '#dddddd'; border.width: checked ? 2 : 1 }
      Row { id: chipRow; anchors.centerIn: parent; spacing: 6
        Rectangle { width: 14; height: 14; radius: 3; color: checked ? '#ffffff' : 'transparent'; border.color: '#ffffff'; border.width: 1
          QQC2.Label { anchors.centerIn: parent; text: checked ? '✓' : ''; color: teamColors[abbr] || '#222'; font.pixelSize: 10; font.bold: true }
        }
        QQC2.Label { text: abbr; color: 'white'; font.pixelSize: 12; font.bold: true }
      }
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        onClicked: { checked = !checked; selected[abbr] = checked; rebuildFavString(); }
      }
    }
  }

  Kirigami.FormLayout {
    anchors.fill: parent

    GridLayout {
      Kirigami.FormData.label: i18n('Favorite teams by division:')
      columns: 4
      columnSpacing: 0           // micro-patch: tighter columns
      rowSpacing: 0
      Layout.fillWidth: true

      Repeater { model: divisions
        delegate: ColumnLayout {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignTop
          Layout.minimumWidth: Math.max(220, implicitWidth)

          // Division header: align left (micro-patch)
          QQC2.Label { text: modelData.title; font.bold: true; opacity: 0.85; horizontalAlignment: Text.AlignLeft; Layout.fillWidth: true }

          GridLayout {
            columns: 2
            columnSpacing: 6
            rowSpacing: 6
            Repeater { model: modelData.teams
              delegate: Loader { sourceComponent: chipDelegate; onLoaded: { item.abbr = modelData } }
            }
          }
        }
      }
    }

    QQC2.CheckBox  { id: showAllCheckBox; text: i18n('Show all games') }
    QQC2.CheckBox  { id: todayOnlyCheck;  text: i18n('Today only (for “All”)') }
    QQC2.SpinBox   { id: compactMax;      Kirigami.FormData.label: i18n('Games in compact view:'); from: 1; to: 6 }
    QQC2.SpinBox   { id: capTotal;        Kirigami.FormData.label: i18n('Cap for “All” view:');   from: 4; to: 64 }
  }
}
