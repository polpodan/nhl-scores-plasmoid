
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: page
    // KConfig bindings (cfg_*)
    property alias cfg_liveColor: liveColorField.text
    property alias cfg_upcomingColor: upcomingColorField.text
    property alias cfg_finalColor: finalColorField.text
    property alias cfg_showOvertimeSuffix: otSuffixCheck.checked
    property alias cfg_scoreLayout: layoutCombo.currentIndex

    Kirigami.FormLayout {
        anchors.fill: parent
        QQC2.TextField { id: liveColorField;     Kirigami.FormData.label: i18n("LIVE color:");        placeholderText: "#d90429" }
        QQC2.TextField { id: upcomingColorField; Kirigami.FormData.label: i18n("Upcoming color:");    placeholderText: "#2b6cb0" }
        QQC2.TextField { id: finalColorField;    Kirigami.FormData.label: i18n("Final color:");       placeholderText: "#6c757d" }
        QQC2.CheckBox  { id: otSuffixCheck;      text: i18n("Show OT/SO suffix in badge") }
        QQC2.ComboBox  { id: layoutCombo;        Kirigami.FormData.label: i18n("Score layout:")
            model: [ i18n('Score below (column)'), i18n('Score next to name (row)') ] }
    }
}
