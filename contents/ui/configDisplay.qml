import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kquickcontrols 2.0 as KQControls
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
  id: page
  implicitWidth: 600
  implicitHeight: 400

  // Panneau vertical → disposition scoreLayout imposée, option masquée
  readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

  // ── Propriétés liées à main.xml ──────────────────────────────────────
  property string cfg_scoreLayout
  property string cfg_scoreLayoutDefault
  property string cfg_liveColor
  property string cfg_liveColorDefault
  property string cfg_upcomingColor
  property string cfg_upcomingColorDefault
  property string cfg_finalColor
  property string cfg_finalColorDefault
  property bool   cfg_showOvertimeSuffix
  property bool   cfg_showOvertimeSuffixDefault
  property bool   cfg_showUpcomingTime
  property bool   cfg_showUpcomingTimeDefault
  property string cfg_dateMode
  property string cfg_dateModeDefault
  // cfg_ General (injectées par Plasma dans tous les fichiers de config)
  property string cfg_favorites
  property bool   cfg_showAllTeams
  property int    cfg_maxGames
  property int    cfg_lookaheadDays
  property bool   cfg_showYesterday
  property bool   cfg_showTwoDaysAgo
  property int    cfg_blinkDuration
  property string cfg_favoritesDefault
  property bool   cfg_showAllTeamsDefault
  property int    cfg_maxGamesDefault
  property int    cfg_lookaheadDaysDefault
  property bool   cfg_showYesterdayDefault
  property bool   cfg_showTwoDaysAgoDefault
  property int    cfg_blinkDurationDefault

  function indexFromValue(v) { return (String(v)==='inline') ? 1 : 0 }
  function valueFromIndex(i) { return (i===1) ? 'inline' : 'stack' }

  Kirigami.FormLayout {
    anchors.fill: parent

    // ── Section : Couleurs des statuts ───────────────────────────────
    Kirigami.Separator {
      Kirigami.FormData.isSection: true
      Kirigami.FormData.label: i18n("Status badge colors")
    }

    // Rangée LIVE
    RowLayout {
      Kirigami.FormData.label: i18n("LIVE:")
      spacing: 10

      KQControls.ColorButton {
        id: liveColorBtn
        color: page.cfg_liveColor || "#d90429"
        dialogTitle: i18n("Choose LIVE color")
        showAlphaChannel: false
        onColorChanged: page.cfg_liveColor = color.toString()
      }

      // Pastille de prévisualisation
      Rectangle {
        width: previewLiveText.implicitWidth + 14
        height: previewLiveText.implicitHeight + 6
        radius: 5
        color: liveColorBtn.color
        QQC2.Label {
          id: previewLiveText
          anchors.centerIn: parent
          text: "LIVE"
          color: "white"
          font.pixelSize: 11
          font.bold: true
        }
      }

      // Bouton reset valeur par défaut
      QQC2.Button {
        icon.name: "edit-undo"
        flat: true
        implicitWidth: implicitHeight
        onClicked: {
          page.cfg_liveColor = "#d90429"
          liveColorBtn.color = "#d90429"
        }
        QQC2.ToolTip.text: i18n("Reset to default")
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.delay: 600
      }
    }

    // Rangée Upcoming
    RowLayout {
      Kirigami.FormData.label: i18n("Upcoming:")
      spacing: 10

      KQControls.ColorButton {
        id: upcomingColorBtn
        color: page.cfg_upcomingColor || "#2b6cb0"
        dialogTitle: i18n("Choose Upcoming color")
        showAlphaChannel: false
        onColorChanged: page.cfg_upcomingColor = color.toString()
      }

      Rectangle {
        width: previewUpText.implicitWidth + 14
        height: previewUpText.implicitHeight + 6
        radius: 5
        color: upcomingColorBtn.color
        QQC2.Label {
          id: previewUpText
          anchors.centerIn: parent
          text: i18n("Upcoming")
          color: "white"
          font.pixelSize: 11
          font.bold: true
        }
      }

      QQC2.Button {
        icon.name: "edit-undo"
        flat: true
        implicitWidth: implicitHeight
        onClicked: {
          page.cfg_upcomingColor = "#2b6cb0"
          upcomingColorBtn.color = "#2b6cb0"
        }
        QQC2.ToolTip.text: i18n("Reset to default")
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.delay: 600
      }
    }

    // Rangée Final
    RowLayout {
      Kirigami.FormData.label: i18n("Final:")
      spacing: 10

      KQControls.ColorButton {
        id: finalColorBtn
        color: page.cfg_finalColor || "#6c757d"
        dialogTitle: i18n("Choose Final color")
        showAlphaChannel: false
        onColorChanged: page.cfg_finalColor = color.toString()
      }

      Rectangle {
        width: previewFinalText.implicitWidth + 14
        height: previewFinalText.implicitHeight + 6
        radius: 5
        color: finalColorBtn.color
        QQC2.Label {
          id: previewFinalText
          anchors.centerIn: parent
          text: i18n("Final")
          color: "white"
          font.pixelSize: 11
          font.bold: true
        }
      }

      QQC2.Button {
        icon.name: "edit-undo"
        flat: true
        implicitWidth: implicitHeight
        onClicked: {
          page.cfg_finalColor = "#6c757d"
          finalColorBtn.color = "#6c757d"
        }
        QQC2.ToolTip.text: i18n("Reset to default")
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.delay: 600
      }
    }

    // ── Section : Badges ─────────────────────────────────────────────
    Kirigami.Separator {
      Kirigami.FormData.isSection: true
      Kirigami.FormData.label: i18n("Badge options")
    }

    QQC2.CheckBox {
      text: i18n("Show OT/SO suffix in badge")
      checked: page.cfg_showOvertimeSuffix
      onToggled: page.cfg_showOvertimeSuffix = checked
    }

    QQC2.CheckBox {
      text: i18n("Show upcoming game time under badge")
      checked: page.cfg_showUpcomingTime
      onToggled: page.cfg_showUpcomingTime = checked
    }

    // ── Section : Mise en page ───────────────────────────────────────
    Kirigami.Separator {
      Kirigami.FormData.isSection: true
      Kirigami.FormData.label: i18n("Layout")
    }

    // Score layout — masqué en panneau vertical (disposition fixe colonne)
    QQC2.ComboBox {
      Kirigami.FormData.label: i18n("Score layout:")
      model: [ i18n("Score below (column)"), i18n("Score next to name (row)") ]
      currentIndex: indexFromValue(page.cfg_scoreLayout)
      onActivated: page.cfg_scoreLayout = valueFromIndex(currentIndex)
      enabled: !page.isVertical
      opacity: page.isVertical ? 0.4 : 1.0
      visible: !page.isVertical
    }
    QQC2.Label {
      visible: page.isVertical
      Kirigami.FormData.label: i18n("Score layout:")
      text: i18n("Fixed (vertical panel)")
      opacity: 0.5
      font.italic: true
    }

    QQC2.ComboBox {
      Kirigami.FormData.label: i18n("Date mode:")
      model: [ i18n("Local timezone (computer)"), i18n("Venue timezone (arena)") ]
      currentIndex: page.cfg_dateMode === 'venue' ? 1 : 0
      onActivated: page.cfg_dateMode = (currentIndex===1 ? 'venue' : 'local')
    }
  }
}
