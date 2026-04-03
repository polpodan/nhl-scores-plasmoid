import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami

ColumnLayout {
    id: stateLayerRoot
    
    property bool   loading: false
    property string error: ""
    property string loadingText: i18n("Loading…")
    property int    topMargin: 20

    visible: loading || error !== ""
    width: parent.width
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: visible ? topMargin : 0
    spacing: visible ? 10 : 0

    // Indicateur de chargement
    Label {
        Layout.alignment: Qt.AlignHCenter
        visible: stateLayerRoot.loading
        text: stateLayerRoot.loadingText
        font.italic: true
        opacity: 0.6
        color: Kirigami.Theme.textColor
    }

    // Message d'erreur
    Label {
        Layout.alignment: Qt.AlignHCenter
        visible: !stateLayerRoot.loading && stateLayerRoot.error !== ""
        text: stateLayerRoot.error
        color: Kirigami.Theme.negativeTextColor
        font.bold: true
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        Layout.preferredWidth: parent.width * 0.8
    }
}
