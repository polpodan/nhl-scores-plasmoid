import QtQuick 2.15
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory { name: i18n("General"); icon: "settings-configure"; source: "configGeneral.qml" }
    ConfigCategory { name: i18n("Display"); icon: "preferences-desktop-color"; source: "configDisplay.qml" }
}
