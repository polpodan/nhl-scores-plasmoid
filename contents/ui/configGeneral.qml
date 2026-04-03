import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.20 as Kirigami
import QtMultimedia

Item {
  id: page
  implicitWidth: 600
  implicitHeight: 400
  property string title: ""  // requis par Plasma

  MediaPlayer {
    id: previewSound
    audioOutput: AudioOutput { volume: page.cfg_soundVolume > 0 ? page.cfg_soundVolume : 1.0 }
  }

  // --- CONFIG ---
  property string cfg_favorites
  property string cfg_favoriteTeamSound
  property string cfg_soundTeams
  property real   cfg_soundVolume
  property bool   cfg_showAllTeams
  property int    cfg_maxGames
  property int    cfg_leadersLimit
  property int    cfg_franchiseLeadersLimit
  property int    cfg_spacingBetweenGames
  property int    cfg_lookaheadDays
  property bool   cfg_showToday
  property int    cfg_pastDays
  property int    cfg_pollInterval
  property int    cfg_blinkDuration
  // cfg_ Display (injectées par Plasma dans tous les fichiers de config)
  property bool   cfg_ultraCompact
  property bool   cfg_ultraCompactDefault
  property string cfg_scoreLayout
  property string cfg_liveColor
  property string cfg_upcomingColor
  property string cfg_finalColor
  property bool   cfg_showOvertimeSuffix
  property bool   cfg_showUpcomingTime
  property string cfg_dateMode

  // Defaults
  property string cfg_favoritesDefault
  property string cfg_favoriteTeamSoundDefault
  property string cfg_soundTeamsDefault
  property real   cfg_soundVolumeDefault
  property bool   cfg_showAllTeamsDefault
  property int    cfg_maxGamesDefault
  property int    cfg_leadersLimitDefault
  property int    cfg_franchiseLeadersLimitDefault
  property int    cfg_spacingBetweenGamesDefault
  property int    cfg_lookaheadDaysDefault
  property bool   cfg_showTodayDefault
  property int    cfg_pastDaysDefault
  property int    cfg_pollIntervalDefault
  property int    cfg_blinkDurationDefault
  property string cfg_scoreLayoutDefault
  property string cfg_liveColorDefault
  property string cfg_upcomingColorDefault
  property string cfg_finalColorDefault
  property bool   cfg_showOvertimeSuffixDefault
  property bool   cfg_showUpcomingTimeDefault
  property string cfg_dateModeDefault

  // --- WORK VARS ---
  property string favString: cfg_favorites || "VAN,TOR"
  property var selected: ({})
  onCfg_soundTeamsChanged: rebuildSoundSet()
  property var soundSet: ({})

  function rebuildSoundSet() {
    var s = {}
    var arr = (cfg_soundTeams||'').split(',').filter(function(x){return x.length>0})
    for (var i=0;i<arr.length;i++) s[arr[i]] = true
    soundSet = s
  }

  function toggleSound(abbrev) {
    var s = soundSet
    var enabling = !s[abbrev]
    if (s[abbrev]) delete s[abbrev]
    else s[abbrev] = true
    soundSet = s
    cfg_soundTeams = Object.keys(s).join(',')
    // Jouer le son en aperçu quand on l'active
    if (enabling) {
        previewSound.source = Qt.resolvedUrl("../sounds/" + abbrev.toLowerCase() + ".mp3")
        previewSound.play()
    } else {
        previewSound.stop()
    }
  }

  readonly property int chipW: 58
  readonly property int chipH: 32

  readonly property var teamColors: ({
    "ANA":"#F47A38","UTA":"#6E2B62","UTA":"#6E2B62","BOS":"#FFB81C","BUF":"#003087",
    "CAR":"#CC0000","CBJ":"#002654","CGY":"#C8102E","CHI":"#CF0A2C","COL":"#6F263D",
    "DAL":"#006847","DET":"#CE1126","EDM":"#FF4C00","FLA":"#C8102E","LAK":"#111111",
    "MIN":"#154734","MTL":"#AF1E2D","NJD":"#CE1126","NSH":"#FFB81C","NYI":"#00539B",
    "NYR":"#0038A8","OTT":"#C52032","PHI":"#F74902","PIT":"#FFB81C","SEA":"#99D9D9",
    "SJS":"#006D75","STL":"#002F87","TBL":"#002868","TOR":"#00205B","VAN":"#00205B",
    "VGK":"#B4975A","WPG":"#041E42","WSH":"#C8102E"
  })

  function teamTextColor(abbr) {
    var hex = teamColors[abbr]
    if (!hex) return "white"
    var h = hex.replace("#","")
    var r = parseInt(h.substring(0,2),16)/255
    var g = parseInt(h.substring(2,4),16)/255
    var b = parseInt(h.substring(4,6),16)/255
    r = r<=0.03928?r/12.92:Math.pow((r+0.055)/1.055,2.4)
    g = g<=0.03928?g/12.92:Math.pow((g+0.055)/1.055,2.4)
    b = b<=0.03928?b/12.92:Math.pow((b+0.055)/1.055,2.4)
    return (0.2126*r + 0.7152*g + 0.0722*b) > 0.35 ? "#111111" : "white"
  }

  readonly property var divisions: [
    { title: "Atlantic",     teams: ["BOS","BUF","DET","FLA","MTL","OTT","TBL","TOR"] },
    { title: "Metropolitan", teams: ["CAR","CBJ","NJD","NYI","NYR","PHI","PIT","WSH"] },
    { title: "Central",      teams: ["UTA","CHI","COL","DAL","MIN","NSH","STL","WPG"] },
    { title: "Pacific",      teams: ["ANA","CGY","EDM","LAK","SJS","SEA","VAN","VGK"] }
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

  function divisionAllSelected(teams) {
    for (var i = 0; i < teams.length; i++) {
      if (!selected[teams[i]]) return false
    }
    return teams.length > 0
  }

  function allTeamsSelected() {
    for (var i = 0; i < divisions.length; i++) {
      var list = divisions[i].teams
      for (var j = 0; j < list.length; j++) {
        if (!selected[list[j]]) return false
      }
    }
    return true
  }

  function toggleAllTeams() {
    var allOn = allTeamsSelected()
    var s = {}
    for (var i = 0; i < divisions.length; i++) {
      var list = divisions[i].teams
      for (var j = 0; j < list.length; j++) {
        s[list[j]] = !allOn
      }
    }
    selected = s
    rebuildFavString()
  }

  function toggleDivision(teams) {
    var allOn = divisionAllSelected(teams)
    var s = selected
    for (var i = 0; i < teams.length; i++) {
      s[teams[i]] = !allOn
    }
    selected = {}
    selected = s
    rebuildFavString()
  }

  Component.onCompleted: {
    selected = parseFavs(favString)
    rebuildSoundSet()
  }

  // ── Pastille d'équipe ────────────────────────────────────────────────
  Component {
    id: chipDelegate
    Item {
      width: page.chipW
      height: page.chipH
      property string abbr: ""
      property bool checked:    !!selected[abbr]
      property bool hasSnd:     !!soundSet[abbr]
      scale: checked ? 1.06 : 1.0
      Behavior on scale { NumberAnimation { duration: 120 } }

      // Fond coloré
      Rectangle {
        anchors.fill: parent; radius: 7
        color: teamColors[abbr] || "#888"
        border.color: checked ? Kirigami.Theme.highlightColor : "#55ffffff"
        border.width: checked ? 3 : 1
      }
      // Overlay clair si sélectionné
      Rectangle {
        anchors.fill: parent; radius: 7
        visible: checked; color: "white"; opacity: 0.15
      }

      // Contenu : ✓ + abréviation
      Row {
        anchors.centerIn: parent; spacing: 4
        Rectangle {
          width: 13; height: 13; radius: 3
          visible: checked; color: "white"
          anchors.verticalCenter: parent.verticalCenter
          Text {
            anchors.centerIn: parent; text: "✓"
            color: teamColors[abbr] || "#888"
            font.pixelSize: 9; font.bold: true
          }
        }
        Text {
          text: abbr
          color: teamTextColor(abbr)
          font.bold: true; font.family: "monospace"
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      // Clic principal = toggle suivi
      MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        z: 1
        onClicked: function(mouse) {
          var s = selected; s[abbr] = !s[abbr]
          if (!s[abbr] && page.soundSet[abbr]) page.toggleSound(abbr)
          selected = {}; selected = s
          rebuildFavString()
        }
      }

      // 🎵 icône son — visible seulement si équipe suivie
      Rectangle {
        visible: checked
        anchors { top: parent.top; right: parent.right }
        anchors.topMargin: -4; anchors.rightMargin: -4
        width: 18; height: 18; radius: 9
        color: hasSnd ? "#ffcc00" : Qt.rgba(0,0,0,0.55)
        border.color: "white"; border.width: 1.5
        z: 10
        Text {
          anchors.centerIn: parent
          text: "🎵"
          font.pixelSize: 9
        }
        MouseArea {
          anchors.fill: parent
          anchors.margins: -4
          cursorShape: Qt.PointingHandCursor
          z: 20
          onClicked: function(mouse) {
            mouse.accepted = true
            page.toggleSound(abbr)
          }
        }
      }
    }
  }

  // ── Composant réutilisable : titre de section centré ─────────────────
  component SectionTitle: Item {
    property string text: ""
    Layout.fillWidth: true
    implicitHeight: secRow.implicitHeight + 20

    // Ligne gauche
    Rectangle {
      anchors.left: parent.left
      anchors.right: secRow.left
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      height: 1; color: Kirigami.Theme.textColor; opacity: 0.25
    }
    // Texte centré
    Row {
      id: secRow
      anchors.centerIn: parent
      spacing: 8
      QQC2.Label {
        text: parent.parent.text
        color: Kirigami.Theme.textColor
        font.pixelSize: 12; font.bold: true
      }
    }
    // Ligne droite
    Rectangle {
      anchors.right: parent.right
      anchors.left: secRow.right
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      height: 1; color: Kirigami.Theme.textColor; opacity: 0.25
    }
  }

  // ── Mise en page principale ──────────────────────────────────────────
  QQC2.ScrollView {
    anchors.fill: parent
    contentWidth: availableWidth
    clip: true

    ColumnLayout {
      width: parent.width
      spacing: 12

      // ════════════════════════════════════════════════════
      // Section : Équipes favorites
      // ════════════════════════════════════════════════════
      SectionTitle { text: i18n("Favorite teams") }

      // Bouton "tout sélectionner / tout décocher"
      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth:  allTeamsRow.implicitWidth + 20
        implicitHeight: allTeamsRow.implicitHeight + 10
        radius: 6
        property bool allOn: { var _r = selected; return allTeamsSelected() }
        color: allOn ? Kirigami.Theme.highlightColor : Kirigami.Theme.alternateBackgroundColor
        Row {
          id: allTeamsRow
          anchors.centerIn: parent; spacing: 6
          QQC2.Label {
            text: parent.parent.allOn ? "☑" : "☐"
            color: parent.parent.allOn ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
            font.bold: true
          }
          QQC2.Label {
            text: i18n("Select / deselect all teams")
            color: parent.parent.allOn ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
            font.bold: true
          }
        }
        MouseArea {
          anchors.fill: parent; cursorShape: Qt.PointingHandCursor
          onClicked: toggleAllTeams()
        }
      }

      // Grille des 4 divisions — centrée
      GridLayout {
        Layout.alignment: Qt.AlignHCenter
        columns: 4; columnSpacing: 16; rowSpacing: 12

        Repeater {
          model: divisions
          delegate: ColumnLayout {
            spacing: 5
            Layout.alignment: Qt.AlignTop

            // Bouton titre de division
            Rectangle {
              Layout.alignment: Qt.AlignHCenter
              implicitWidth:  divRow.implicitWidth + 14
              implicitHeight: divRow.implicitHeight + 8
              radius: 5
              property bool allOn: { var _r = selected; return divisionAllSelected(modelData.teams) }
              color: allOn ? Kirigami.Theme.highlightColor : Kirigami.Theme.alternateBackgroundColor
              Row {
                id: divRow; anchors.centerIn: parent; spacing: 5
                QQC2.Label {
                  text: parent.parent.allOn ? "☑" : "☐"
                  color: parent.parent.allOn ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                  }
                QQC2.Label {
                  text: modelData.title
                  color: parent.parent.allOn ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                  font.bold: true
                }
              }
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: toggleDivision(modelData.teams)
              }
            }

            // Pastilles équipes (2 colonnes)
            GridLayout {
              columns: 2; columnSpacing: 4; rowSpacing: 4
              Layout.alignment: Qt.AlignHCenter
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

      // ════════════════════════════════════════════════════
      // Section : Affichage
      // ════════════════════════════════════════════════════
      SectionTitle { text: i18n("Display") }

      // Grille de paramètres d'affichage — 2 colonnes label/contrôle
      GridLayout {
        Layout.alignment: Qt.AlignHCenter
        columns: 2
        columnSpacing: 16
        rowSpacing: 10

        // Ligne 1 : Max parties
        QQC2.Label {
          text: i18n("Max games to display:")
          Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        }
        QQC2.SpinBox {
          from: 1; to: 20
          value: cfg_maxGames || 10
          onValueChanged: cfg_maxGames = value
          Layout.alignment: Qt.AlignLeft
        }

        // Ligne 1b : Limite meneurs
        QQC2.Label {
          text: i18n("Leaders limit:")
          Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        }
        QQC2.ComboBox {
          model: [10, 20, 50]
          property bool ready: false
          Component.onCompleted: {
            var vals = [10, 20, 50]
            var idx = vals.indexOf(cfg_leadersLimit || 10)
            currentIndex = idx >= 0 ? idx : 0
            ready = true
          }
          onCurrentIndexChanged: if (ready) cfg_leadersLimit = model[currentIndex]
          Layout.alignment: Qt.AlignLeft
          }

          // Ligne 1c : Limite meneurs historiques
          QQC2.Label {
          text: i18n("Franchise leaders limit:")
          Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
          }
          QQC2.ComboBox {
          model: [10, 20, 50]
          property bool ready: false
          Component.onCompleted: {
            var vals = [10, 20, 50]
            var idx = vals.indexOf(cfg_franchiseLeadersLimit || 10)
            currentIndex = idx >= 0 ? idx : 0
            ready = true
          }
          onCurrentIndexChanged: if (ready) cfg_franchiseLeadersLimit = model[currentIndex]
          Layout.alignment: Qt.AlignLeft
          }
        // Ligne 2 : Jours à venir
        QQC2.Label {
          text: i18n("Days ahead:")
          Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        }
        QQC2.SpinBox {
          from: 0; to: 14
          value: cfg_lookaheadDays
          onValueChanged: cfg_lookaheadDays = value
          Layout.alignment: Qt.AlignLeft
        }

        // Ligne 3 : Jours précédents
        QQC2.Label {
          text: i18n("Previous days:")
          Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        }
        RowLayout {
          spacing: 8
          Layout.alignment: Qt.AlignLeft
          QQC2.SpinBox {
            from: 0; to: 4; value: cfg_pastDays
            onValueModified: cfg_pastDays = value
          }
          QQC2.Label {
            text: i18n("(0 = disabled)")
            opacity: 0.55; font.pixelSize: 11
          }
        }

        // Ligne 4 : Intervalle de rafraîchissement
        QQC2.Label {
          text: i18n("Refresh interval:")
          Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        }
        QQC2.ComboBox {
          id: pollIntervalCombo
          model: [10, 20, 30, 45, 60]
          property bool ready: false
          Component.onCompleted: {
            var vals = [10, 20, 30, 45, 60]
            var idx = vals.indexOf(cfg_pollInterval || 20)
            currentIndex = idx >= 0 ? idx : 1
            ready = true
          }
          onCurrentIndexChanged: if (ready) cfg_pollInterval = model[currentIndex]
          Layout.alignment: Qt.AlignLeft
          displayText: currentText + i18n(" sec")
        }

        // Ligne 5 : Aujourd'hui (pleine largeur)
        Item { Layout.columnSpan: 2; implicitHeight: 2 }
        QQC2.CheckBox {
          Layout.columnSpan: 2
          Layout.alignment: Qt.AlignHCenter
          text: i18n("Show today's games")
          checked: cfg_showToday
          onToggled: cfg_showToday = checked
        }
      }

      // ════════════════════════════════════════════════════
      // Section : Notifications
      // ════════════════════════════════════════════════════
      SectionTitle { text: i18n("Notifications") }

      RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 8
        QQC2.Label { text: i18n("Goal blink duration:") }
        QQC2.SpinBox {
          from: 0; to: 30
          value: cfg_blinkDuration > 0 ? cfg_blinkDuration : 10
          onValueModified: cfg_blinkDuration = value
        }
        QQC2.Label { text: i18n("sec. (0 = disabled)"); opacity: 0.6 }
      }

      // Note : la sélection sonore se fait directement sur les pastilles d'équipes (🎵)

      // Slider volume
      RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 12
        QQC2.Label {
          text: i18n("Goal sound volume:")
          verticalAlignment: Text.AlignVCenter
        }
        QQC2.Slider {
          id: volumeSlider
          from: 0.0; to: 1.0; stepSize: 0.05
          value: cfg_soundVolume > 0 ? cfg_soundVolume : 1.0
          Layout.preferredWidth: 150
          onValueChanged: cfg_soundVolume = value
        }
        QQC2.Label {
          text: Math.round(volumeSlider.value * 100) + "%"
          Layout.preferredWidth: 36
        }
      }

      Item { implicitHeight: 8 }
    }
  }
}
