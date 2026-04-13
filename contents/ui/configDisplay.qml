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
    implicitHeight: 450
    property string title: ""

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool isDesktop: Plasmoid.formFactor === PlasmaCore.Types.Planar

    // --- CONFIG ---
    property int cfg_pastHours
    property int cfg_upcomingHours
    property int cfg_pastHoursDefault
    property int cfg_upcomingHoursDefault

    property int cfg_lookaheadDays
    property int cfg_pastDays
    property bool cfg_showToday
    property int cfg_lookaheadDaysDefault
    property int cfg_pastDaysDefault
    property bool cfg_showTodayDefault

    property string cfg_scoreLayout
    property string cfg_scoreLayoutDefault
    property string cfg_favoriteTeamSound
    property string cfg_favoriteTeamSoundDefault
    property string cfg_soundTeams
    property string cfg_soundTeamsDefault
    property real cfg_soundVolume
    property real cfg_soundVolumeDefault
    property string cfg_liveColor
    property string cfg_liveColorDefault
    property string cfg_upcomingColor
    property string cfg_upcomingColorDefault
    property string cfg_finalColor
    property string cfg_finalColorDefault
    property string cfg_dateMode
    property string cfg_dateModeDefault
    property string cfg_favorites
    property string cfg_favoritesDefault
    property bool cfg_showAllTeams
    property bool cfg_showAllTeamsDefault
    property bool cfg_ultraCompact
    property bool cfg_ultraCompactDefault
    property bool cfg_showOvertimeSuffix
    property bool cfg_showOvertimeSuffixDefault
    property bool cfg_showLogos
    property bool cfg_showLogosDefault
    property bool cfg_showUpcomingTime
    property bool cfg_showUpcomingTimeDefault
    property int cfg_maxGames
    property int cfg_maxGamesDefault
    property int cfg_pollInterval
    property int cfg_pollIntervalDefault
    property int cfg_blinkDuration
    property int cfg_blinkDurationDefault
    property bool cfg_enableNotifications
    property bool cfg_enableNotificationsDefault
    property bool cfg_notificationsAllTeams
    property bool cfg_notificationsAllTeamsDefault
    property bool cfg_showCompactDesktop
    property bool cfg_showCompactDesktopDefault
    property int cfg_leadersLimit
    property int cfg_leadersLimitDefault
    property int cfg_franchiseLeadersLimit
    property int cfg_franchiseLeadersLimitDefault
    property int cfg_spacingBetweenGames
    property int cfg_spacingBetweenGamesDefault

    function indexFromValue(v) { return (String(v) === 'inline') ? 1 : 0 }
    function valueFromIndex(i) { return (i === 1) ? 'inline' : 'stack' }

    Kirigami.FormLayout {
        anchors.fill: parent

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Status badge colors")
        }

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
            }
        }

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
            }
        }

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
            }
        }

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

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Team display")
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Icon style:")
            spacing: 20
            QQC2.RadioButton {
                text: i18n("Pastilles")
                checked: !page.cfg_showLogos
                onToggled: if (checked) page.cfg_showLogos = false
            }
            QQC2.RadioButton {
                text: i18n("Logos")
                checked: page.cfg_showLogos
                onToggled: if (checked) page.cfg_showLogos = true
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Layout")
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Desktop:")
            text: i18n("Compact desktop mode (favorite team only)")
            checked: page.cfg_showCompactDesktop
            onToggled: page.cfg_showCompactDesktop = checked
            visible: page.isDesktop
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Score layout:")
            model: [i18n("Score below (column)"), i18n("Score next to name (row)"), i18n("Ultra-compact (dots + score)")]
            currentIndex: page.cfg_ultraCompact ? 2 : indexFromValue(page.cfg_scoreLayout)
            onActivated: {
                if (currentIndex === 2) {
                    page.cfg_ultraCompact = true
                } else {
                    page.cfg_ultraCompact = false
                    page.cfg_scoreLayout = valueFromIndex(currentIndex)
                }
            }
            enabled: !page.isVertical && !page.isDesktop
            opacity: (page.isVertical || page.isDesktop) ? 0.4 : 1.0
        }
        QQC2.Label {
            visible: page.isVertical || page.isDesktop
            Kirigami.FormData.label: ""
            text: page.isDesktop ? i18n("N/A (desktop widget)") : i18n("Fixed (vertical panel)")
            opacity: 0.5
            font.italic: true
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Spacing between games:")
            model: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            property bool ready: false
            Component.onCompleted: {
                var vals = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
                var idx = vals.indexOf(page.cfg_spacingBetweenGames !== undefined ? page.cfg_spacingBetweenGames : 2)
                currentIndex = idx >= 0 ? idx : 2
                ready = true
            }
            onCurrentIndexChanged: if (ready) page.cfg_spacingBetweenGames = model[currentIndex]
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Date mode:")
            model: [i18n("Local timezone (computer)"), i18n("Venue timezone (arena)")]
            currentIndex: page.cfg_dateMode === 'venue' ? 1 : 0
            onActivated: page.cfg_dateMode = (currentIndex === 1 ? 'venue' : 'local')
        }
    }
}
