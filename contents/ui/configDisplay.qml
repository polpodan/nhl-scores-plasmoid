import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
  id: page
  // Bind KConfig STRING directly
  property string cfg_scoreLayout: plasmoid.configuration.scoreLayout // 'stack' or 'inline'
  property alias  cfg_liveColor: liveColorField.text
  property alias  cfg_upcomingColor: upcomingColorField.text
  property alias  cfg_finalColor: finalColorField.text
  property alias  cfg_showOvertimeSuffix: otSuffixCheck.checked

  function indexFromValue(v){ return (String(v)==='inline') ? 1 : 0 }
  function valueFromIndex(i){ return (i===1) ? 'inline' : 'stack' }

  Kirigami.FormLayout {
    anchors.fill: parent
    QQC2.TextField { id: liveColorField;     Kirigami.FormData.label: i18n('LIVE color:');     placeholderText: '#d90429' }
    QQC2.TextField { id: upcomingColorField; Kirigami.FormData.label: i18n('Upcoming color:'); placeholderText: '#2b6cb0' }
    QQC2.TextField { id: finalColorField;    Kirigami.FormData.label: i18n('Final color:');    placeholderText: '#6c757d' }
    QQC2.CheckBox  { id: otSuffixCheck;      text: i18n('Show OT/SO suffix in badge') }

    RowLayout { Kirigami.FormData.label: i18n('Score layout:')
      QQC2.ComboBox {
        id: layoutCombo
        model: [ i18n('Score below (column)'), i18n('Score next to name (row)') ]
        currentIndex: indexFromValue(page.cfg_scoreLayout)
        onActivated: page.cfg_scoreLayout = valueFromIndex(currentIndex)
      }
      // Small helper label to show stored value
      QQC2.Label { text: page.cfg_scoreLayout; opacity: 0.5 }
    }
  }
}
