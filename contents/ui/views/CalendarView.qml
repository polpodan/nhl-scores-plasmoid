import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../logic.js" as Logic

Item {
    id: calendarRoot
    property var controller

    anchors.fill: parent
    visible: !!(controller && controller.nav.calendar)

    // Déclencher le chargement des données dès que le contrôleur est prêt
    onControllerChanged: {
        if (controller && controller.nav.calendar) {
            controller.fetchCalendarMonth(controller.cal.year, controller.cal.month)
        }
    }

    Connections {
        target: controller ? controller.cal : null
        enabled: !!controller
        ignoreUnknownSignals: true
        
        function onYearChanged() {
            if (controller.nav.calendar) 
                controller.fetchCalendarMonth(controller.cal.year, controller.cal.month)
        }
        function onMonthChanged() {
            if (controller.nav.calendar) 
                controller.fetchCalendarMonth(controller.cal.year, controller.cal.month)
        }
    }

    Connections {
        target: controller ? controller.nav : null
        enabled: !!controller
        ignoreUnknownSignals: true
        function onCalendarChanged() {
            if (controller.nav.calendar) 
                controller.fetchCalendarMonth(controller.cal.year, controller.cal.month)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Barre navigation
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8; Layout.topMargin: 4; Layout.bottomMargin: 4
            Button {
                text: i18n("‹ Back"); icon.name: "go-previous"; flat: true
                onClicked: { if (controller) controller.nav.calendar = false }
            }
            
            Item { Layout.fillWidth: true }
            // Mois/Année + navigation
            Button {
                text: "‹"; flat: true
                onClicked: {
                    if (!controller) return
                    controller.cal.month--
                    if (controller.cal.month < 0) { controller.cal.month = 11; controller.cal.year-- }
                }
            }
            Label {
                text: {
                    if (!controller) return ""
                    var months = [i18n("January"),i18n("February"),i18n("March"),i18n("April"),
                                  i18n("May"),i18n("June"),i18n("July"),i18n("August"),
                                  i18n("September"),i18n("October"),i18n("November"),i18n("December")]
                    return months[controller.cal.month] || ""
                }
                font.bold: true; font.pixelSize: 14
                Layout.preferredWidth: 90
                horizontalAlignment: Text.AlignHCenter
            }
            ComboBox {
                id: yearCombo
                model: {
                    var years = []
                    var currentY = new Date().getFullYear()
                    for (var y = currentY; y >= 2006; y--)
                        years.push(String(y))
                    return years
                }
                currentIndex: (controller && controller.cal.year) ? Math.max(0, new Date().getFullYear() - controller.cal.year) : 0
                onActivated: { if (controller) controller.cal.year = parseInt(currentText) }
                implicitWidth: 90
                font.pixelSize: 13
            }
            Button {
                text: "›"; flat: true
                onClicked: {
                    if (!controller) return
                    controller.cal.month++
                    if (controller.cal.month > 11) { controller.cal.month = 0; controller.cal.year++ }
                }
            }
            Item { Layout.fillWidth: true }
            Button {
                text: i18n("Today"); flat: true; font.pixelSize: 11
                onClicked: {
                    if (!controller) return
                    controller.cal.year  = new Date().getFullYear()
                    controller.cal.month = new Date().getMonth()
                    yearCombo.currentIndex = 0
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8; Layout.rightMargin: 8
            spacing: 0
            Repeater {
                model: [i18n("Su"),i18n("Mo"),i18n("Tu"),i18n("We"),i18n("Th"),i18n("Fr"),i18n("Sa")]
                delegate: Label {
                    text: modelData
                    font.pixelSize: 11; font.bold: true; opacity: 0.5
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    color: (index === 0 || index === 6)
                           ? Kirigami.Theme.highlightColor
                           : Kirigami.Theme.disabledTextColor
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; height: 1
            color: Kirigami.Theme.textColor; opacity: 0.1
        }

        ScrollView {
            id: calendarScroll
            Layout.fillWidth: true; Layout.fillHeight: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            GridLayout {
                id: calGrid
                width: parent.width
                columns: 7
                columnSpacing: 0; rowSpacing: 0

                property int firstDow: (controller && controller.cal.year !== undefined) ? new Date(controller.cal.year, controller.cal.month, 1).getDay() : 0
                property int daysInMonth: (controller && controller.cal.year !== undefined) ? new Date(controller.cal.year, controller.cal.month + 1, 0).getDate() : 30

                Repeater {
                    model: calGrid.firstDow
                    delegate: Item { Layout.fillWidth: true; implicitHeight: 38 }
                }

                Repeater {
                    model: calGrid.daysInMonth
                    delegate: Item {
                        id: dayCell
                        Layout.fillWidth: true
                        implicitHeight: 38

                        readonly property int day: index + 1
                        readonly property bool isToday: !!(controller && day === new Date().getDate() && controller.cal.month === new Date().getMonth() && controller.cal.year === new Date().getFullYear())
                        readonly property bool isFuture: {
                            if (!controller) return false
                            var d = new Date(controller.cal.year, controller.cal.month, day)
                            var now = new Date()
                            now.setHours(0,0,0,0)
                            return d > now
                        }
                        readonly property string iso: controller ? (controller.cal.year + "-" + Logic.pad2(controller.cal.month + 1) + "-" + Logic.pad2(day)) : ""
                        readonly property bool isSelected: !!(controller && iso === controller.day.date)
                        
                        readonly property int gameCount: (controller && controller.cal.counts && controller.cal.counts[iso] !== undefined) ? controller.cal.counts[iso] : 0

                        Rectangle {
                            anchors.centerIn: parent
                            width: 32; height: 32; radius: 16
                            color: dayCell.isToday    ? Logic.getTeamColor('MTL')
                                 : dayCell.isSelected ? Kirigami.Theme.highlightColor
                                 : "transparent"
                            opacity: dayCell.isToday ? 0.85 : dayCell.isSelected ? 0.7 : 1.0
                        }

                        Label {
                            anchors.centerIn: parent
                            text: String(day)
                            font.pixelSize: 13
                            font.bold: dayCell.isToday || dayCell.isSelected
                            color: (dayCell.isToday || dayCell.isSelected)
                                   ? "white"
                                   : dayCell.isFuture ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor
                            opacity: dayCell.isFuture ? 0.5 : 1.0
                        }

                        Rectangle {
                            visible: !!(!dayCell.isFuture && dayCell.gameCount > 0)
                            anchors.bottom: parent.bottom; anchors.bottomMargin: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.max(14, String(dayCell.gameCount).length * 7 + 6)
                            height: 14; radius: 7
                            color: dayCell.isSelected ? "white" : Kirigami.Theme.highlightColor
                            opacity: 0.85
                            Label {
                                anchors.centerIn: parent
                                text: String(dayCell.gameCount)
                                font.pixelSize: 9; font.bold: true
                                color: dayCell.isSelected ? Kirigami.Theme.highlightColor : "white"
                            }
                        }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: {
                                if (!controller) return
                                controller.nav.calendar = false
                                controller.openDayView(dayCell.iso)
                            }
                        }
                    }
                }
            }
        }
    }
}
