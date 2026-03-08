import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami 2.20 as Kirigami

Item {
  id: page
  property string title

  // --- CONFIG ---
  property string cfg_favorites
  property bool   cfg_showAllTeams
  property int    cfg_maxGames
  property int    cfg_lookaheadDays
  property bool   cfg_showYesterday
  property bool   cfg_showTwoDaysAgo
  property bool   cfg_goalNotifications

  // Defaults
  property string cfg_favoritesDefault
  property bool   cfg_showAllTeamsDefault
  property int    cfg_maxGamesDefault
  property int    cfg_lookaheadDaysDefault
  property bool   cfg_showYesterdayDefault
  property bool   cfg_showTwoDaysAgoDefault
  property bool   cfg_goalNotificationsDefault

  // --- WORK VARS ---
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

  // --- TEAM CHIP ---
  Component {
    id: chipDelegate

    Item {

      implicitWidth: chipRow.implicitWidth + 16
      implicitHeight: chipRow.implicitHeight + 14

      property string abbr: ""
      property bool checked: !!selected[abbr]

      // ✅ zoom léger
      scale: checked ? 1.08 : 1.0
      Behavior on scale {
        NumberAnimation { duration: 120 }
      }

      // --- Fond principal ---
      Rectangle {
        id: bg
        anchors.fill: parent
        radius: 8
        color: teamColors[abbr]
        border.color: checked
        ? Kirigami.Theme.highlightColor
        : "#dddddd"
        border.width: checked ? 3 : 1
        opacity: cfg_showAllTeams ? 0.4 : 1.0
      }

      // ✅ overlay blanc léger si sélectionné
      Rectangle {
        anchors.fill: parent
        radius: 8
        visible: checked
        color: "white"
        opacity: 0.18
      }

      Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: 6

        // ✅ coche visible si sélectionné
        Rectangle {
          width: 14
          height: 14
          radius: 3
          visible: checked
          color: "white"

          Text {
            anchors.centerIn: parent
            text: "✓"
            color: teamColors[abbr]
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
        enabled: !cfg_showAllTeams
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

    QQC2.CheckBox {
      text: i18n("Show all teams")
      checked: cfg_showAllTeams
      onToggled: cfg_showAllTeams = checked
    }

    GridLayout {
      Kirigami.FormData.label: i18n("Favorite teams :")
      columns: 4
      enabled: !cfg_showAllTeams
      opacity: cfg_showAllTeams ? 0.4 : 1.0

      Repeater {
        model: divisions
        delegate: ColumnLayout {
          QQC2.Label {
            text: modelData.title
            font.bold: true
          }

          GridLayout {
            columns: 2
            Repeater {
              model: modelData.teams
              delegate: Loader {
                sourceComponent: chipDelegate
                onLoaded: item.abbr = modelData
              }
            }
          }
        }
      }
    }

    QQC2.SpinBox {
      Kirigami.FormData.label: i18n("Max games to display :")
      from: 1
      to: 20
      value: cfg_maxGames || 10
      onValueChanged: cfg_maxGames = value
    }

    QQC2.SpinBox {
      Kirigami.FormData.label: i18n("Days ahead :")
      from: 0
      to: 14
      value: cfg_lookaheadDays || 2
      onValueChanged: cfg_lookaheadDays = value
    }

    QQC2.CheckBox {
      text: i18n("Show yesterday's games.")
      checked: cfg_showYesterday
      onToggled: cfg_showYesterday = checked
    }

    QQC2.CheckBox {
      text: i18n("Show games from two days ago.")
      checked: cfg_showTwoDaysAgo
      onToggled: cfg_showTwoDaysAgo = checked
    }

    Kirigami.Separator {
      Kirigami.FormData.isSection: true
      Kirigami.FormData.label: i18n("Notifications")
    }

    QQC2.CheckBox {
      text: i18n("Notify on goals (requires notify-send)")
      checked: cfg_goalNotifications
      onToggled: cfg_goalNotifications = checked
    }
  }
}
