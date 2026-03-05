import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item { id: page
    property alias cfg_favorites: favoritesField.text
    property alias cfg_showAll: showAllCheckBox.checked
    property alias cfg_todayOnly: todayOnlyCheck.checked
    property alias cfg_compactMaxGames: compactMax.value
    property alias cfg_maxTotalGames: capTotal.value
    Kirigami.FormLayout { anchors.fill: parent
        QQC2.TextField { id: favoritesField; Kirigami.FormData.label: i18n("Favorite teams:"); placeholderText: "e.g. VAN,TOR,MTL" }
        QQC2.CheckBox  { id: showAllCheckBox; text: i18n("Show all games") }
        QQC2.CheckBox  { id: todayOnlyCheck; text: i18n("Today only (for ‘All’) ") }
        QQC2.SpinBox   { id: compactMax;  Kirigami.FormData.label: i18n("Games in compact view:"); from: 1; to: 6 }
        QQC2.SpinBox   { id: capTotal;    Kirigami.FormData.label: i18n("Cap for ‘All’ view:");   from: 4; to: 64 }
    }
}