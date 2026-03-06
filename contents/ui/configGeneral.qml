import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.20 as Kirigami

Item {
  id: page
  property string title

  // KConfig properties fournis par l'engine
  property string cfg_favorites
  property bool   cfg_showAll
  property bool   cfg_todayOnly
  property int    cfg_compactMaxGames
  property int    cfg_maxTotalGames
  property int    cfg_lookaheadDays
  property string cfg_liveColor
  property string cfg_upcomingColor
  property string cfg_finalColor
  property bool   cfg_showOvertimeSuffix
  property string cfg_scoreLayout
  property bool   cfg_showUpcomingTime

  // Defaults (déclarés pour éviter les warnings)
  property string cfg_favoritesDefault
  property bool   cfg_showAllDefault
  property bool   cfg_todayOnlyDefault
  property int    cfg_compactMaxGamesDefault
  property int    cfg_maxTotalGamesDefault
  property int    cfg_lookaheadDaysDefault
  property string cfg_liveColorDefault
  property string cfg_upcomingColorDefault
  property string cfg_finalColorDefault
  property bool   cfg_showOvertimeSuffixDefault
  property string cfg_scoreLayoutDefault
  property bool   cfg_showUpcomingTimeDefault
  property bool cfg_showYesterday
  property bool cfg_showTwoDaysAgo
  property bool cfg_showYesterdayDefault
  property bool cfg_showTwoDaysAgoDefault


  // Variables de travail
  property string favString: cfg_favorites || "VAN,TOR"
  property var selected: ({})

  readonly property var teamColors: ({
    "ANA":"#F47A38","ARI":"#8C2633","UTA":"#6E2B62","BOS":"#FFB81C","BUF":"#003087",
    "CAR":"#CC0000","CBJ":"#002654","CGY":"#C8102E","CHI":"#CF0A2C","COL":"#6F263D",
    "DAL":"#006847","DET":"#CE1126","EDM":"#FF4C00","FLA":"#C8102E","LAK":"#111111",
    "MIN":"#154734","MTL":"#AF1E2D","NJD":"#CE1126","NSH":"#FFB81C","NYI":"#00539B",
    "NYR":"#0038A8","OTT":"#C52032","PHI":"#F74902","PIT":"#FFB81C","SEA":"#99D9D9",
    "SJS":"#006D75","STL":"#002F87","TBL":"#002868","TOR":"#00205B","VAN":"#00205B",
    "VGK":"#B4975A","WPG":"#041E42","WSH":"#C8102E"
  })

  readonly property var divisions: [
    { title: i18n("── Atlantic ──"),     teams: ["BOS","BUF","DET","FLA","MTL","OTT","TBL","TOR"] },
    { title: i18n("── Metropolitan ──"), teams: ["CAR","CBJ","NJD","NYI","NYR","PHI","PIT","WSH"] },
    { title: i18n("── Central ──"),      teams: ["ARI","CHI","COL","DAL","MIN","NSH","STL","WPG"] },
    { title: i18n("── Pacific ──"),      teams: ["ANA","CGY","EDM","LAK","SJS","SEA","VAN","VGK"] }
  ]

  function trim(s) { return String(s).replace(/^\s+|\s+$/g, "") }

  function parseFavs(str) {
    var arr = String(str || "").split(",")
    var out = {}
    for (var i = 0; i < arr.length; i++) {
      var t = trim(arr[i])
      if (t.length > 0) out[t] = true
    }
    return out
  }

  function rebuildFavString() {
    var out = []
    for (var i = 0; i < divisions.length; i++) {
      var list = divisions[i].teams
      for (var j = 0; j < list.length; j++) {
        var a = list[j]
        if (selected[a]) out.push(a)
      }
    }
    favString = out.join(",")
    cfg_favorites = favString
  }

  Component.onCompleted: selected = parseFavs(favString)

  // Pastille d'équipe (sélectionnable)
  Component {
    id: chipDelegate
    Item {
      implicitWidth: chipRow.implicitWidth + 12
      implicitHeight: chipRow.implicitHeight + 10
      property string abbr: ""
      property bool checked: !!selected[abbr]

      Rectangle {
        anchors.fill: parent
        radius: 6
        color: teamColors[abbr] || Kirigami.Theme.positiveBackgroundColor
        border.color: checked ? "#ffffff" : "#dddddd"
        border.width: checked ? 2 : 1
      }

      Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
          width: 14
          height: 14
          radius: 3
          color: checked ? "#ffffff" : "transparent"
          border.color: "#ffffff"
          border.width: 1
          QQC2.Label {
            anchors.centerIn: parent
            text: checked ? "✓" : ""
            color: teamColors[abbr] || "#222"
            font.pixelSize: 10
            font.bold: true
          }
        }

        QQC2.Label {
          text: abbr
          color: "white"
          font.pixelSize: 12
          font.bold: true
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          checked = !checked
          selected[abbr] = checked
          rebuildFavString()
        }
      }
    }
  }

  Kirigami.FormLayout {
    anchors.fill: parent

    GridLayout {
      id: divGrid
      Kirigami.FormData.label: i18n("Favorite teams by division:")
      columns: 4
      columnSpacing: 10
      rowSpacing: 0
      Layout.fillWidth: false
      Layout.preferredWidth: divGrid.implicitWidth

      Repeater {
        model: divisions
        delegate: ColumnLayout {
          Layout.fillWidth: false
          Layout.alignment: Qt.AlignTop | Qt.AlignLeft
          Layout.preferredWidth: Math.max(170, implicitWidth)

          QQC2.Label {
            text: modelData.title
            font.bold: true
            opacity: 0.85
            horizontalAlignment: Text.AlignLeft
          }

          GridLayout {
            columns: 2
            columnSpacing: 6
            rowSpacing: 6
            Repeater {
              model: modelData.teams
              delegate: Loader {
                sourceComponent: chipDelegate
                onLoaded: { item.abbr = modelData }
              }
            }
          }
        }
      }
    }

    // Options additionnelles (inchangées)
    QQC2.CheckBox {
      text: i18n("Show all games")
      checked: cfg_showAll
      onToggled: cfg_showAll = checked
    }

    QQC2.CheckBox {
      text: i18n("Today only (for All)")
      checked: cfg_todayOnly
      onToggled: cfg_todayOnly = checked
    }

    QQC2.CheckBox {
      text: i18n("Show games from yesterday.")
      checked: cfg_showYesterday
      onToggled: cfg_showYesterday = checked
    }

    QQC2.CheckBox {
      text: i18n("Show games from the day before yesterday.")
      checked: cfg_showTwoDaysAgo
      onToggled: cfg_showTwoDaysAgo = checked
    }

    QQC2.SpinBox {
      Kirigami.FormData.label: i18n("Days ahead:")
      from: 0
      to: 14
      value: cfg_lookaheadDays || 2
      onValueChanged: cfg_lookaheadDays = value
    }

    QQC2.SpinBox {
      Kirigami.FormData.label: i18n("Games in compact view:")
      from: 1
      to: 6
      value: cfg_compactMaxGames || 2
      onValueChanged: cfg_compactMaxGames = value
    }

    QQC2.SpinBox {
      Kirigami.FormData.label: i18n("Cap for All view:")
      from: 4
      to: 64
      value: cfg_maxTotalGames || 20
      onValueChanged: cfg_maxTotalGames = value
    }
  }
}
