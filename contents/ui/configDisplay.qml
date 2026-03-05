
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.20 as Kirigami

Item {
  id: page
  property string title

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
  property string cfg_favorites
  property string cfg_favoritesDefault
  property bool   cfg_showAll
  property bool   cfg_showAllDefault
  property bool   cfg_todayOnly
  property bool   cfg_todayOnlyDefault
  property int    cfg_compactMaxGames
  property int    cfg_compactMaxGamesDefault
  property int    cfg_maxTotalGames
  property int    cfg_maxTotalGamesDefault
  property int    cfg_lookaheadDays
  property int    cfg_lookaheadDaysDefault
  property string cfg_dateMode
  property string cfg_dateModeDefault

  function indexFromValue(v) { return (String(v)==='inline') ? 1 : 0 }
  function valueFromIndex(i) { return (i===1) ? 'inline' : 'stack' }

  Kirigami.FormLayout {
    anchors.fill: parent

    QQC2.TextField {
      Kirigami.FormData.label: i18n("LIVE color:")
      placeholderText: "#d90429"
      text: page.cfg_liveColor
      onTextChanged: page.cfg_liveColor = text
    }

    QQC2.TextField {
      Kirigami.FormData.label: i18n("Upcoming color:")
      placeholderText: "#2b6cb0"
      text: page.cfg_upcomingColor
      onTextChanged: page.cfg_upcomingColor = text
    }

    QQC2.TextField {
      Kirigami.FormData.label: i18n("Final color:")
      placeholderText: "#6c757d"
      text: page.cfg_finalColor
      onTextChanged: page.cfg_finalColor = text
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

    RowLayout {
      Kirigami.FormData.label: i18n("Score layout:")
      QQC2.ComboBox {
        model: [ i18n("Score below (column)"), i18n("Score next to name (row)") ]
        currentIndex: indexFromValue(page.cfg_scoreLayout)
        onActivated: page.cfg_scoreLayout = valueFromIndex(currentIndex)
      }
      QQC2.Label {
        text: page.cfg_scoreLayout
        opacity: 0.5
      }
    }

    RowLayout {
      Kirigami.FormData.label: i18n("Date mode:")
      QQC2.ComboBox {
        id: dateModeCombo
        model: [ i18n("Local timezone (computer)"), i18n("Venue timezone (arena)") ]
        currentIndex: page.cfg_dateMode === 'venue' ? 1 : 0
        onActivated: page.cfg_dateMode = (currentIndex===1 ? 'venue' : 'local')
      }
      QQC2.Label {
        text: page.cfg_dateMode
        opacity: 0.5
      }
    }
  }
}
