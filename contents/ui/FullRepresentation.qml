import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import "logic.js" as Logic
import "views" as Views

Item {
    id: fullRoot
    property var controller

    implicitWidth:  (controller && controller.isDesktop) ? 400 : 440
    implicitHeight: (controller && controller.isDesktop) ? 520 : 520
    Layout.fillWidth:  (controller && controller.isDesktop)
    Layout.fillHeight: (controller && controller.isDesktop)

    // --- Vue bureau enrichie ---
    Loader {
        anchors.fill: parent
        active: controller ? controller.isDesktop : false
        visible: active && controller.nav && !controller.nav.detail && !controller.nav.standings && !controller.nav.leaders 
                 && !controller.nav.bracket && !controller.nav.teamHub && !controller.nav.dayView 
                 && !controller.nav.schedule && !controller.nav.player && !controller.nav.search && !controller.nav.calendar
        sourceComponent: controller ? controller.desktopRepresentation : null
    }

    // --- Vue Détail ---
    Views.DetailView {
        controller: fullRoot.controller
        anchors.fill: parent
        visible: controller && controller.nav && controller.nav.detail && !controller.nav.schedule && !controller.nav.standings && !controller.nav.bracket && !controller.nav.teamHub && !controller.nav.leaders && !controller.nav.dayView && !controller.nav.search && !controller.nav.player
    }

    // --- Vue Standings ---
    Views.StandingsView {
        controller: fullRoot.controller
        anchors.fill: parent
        visible: controller && controller.nav && controller.nav.standings && !controller.nav.player && !controller.nav.schedule && !controller.nav.bracket && !controller.nav.teamHub
    }

    // --- Vue Leaders ---
    Views.LeadersView {
        controller: fullRoot.controller
        anchors.fill: parent
        visible: controller && controller.nav && controller.nav.leaders && !controller.nav.player
    }

    // --- Vue Search ---
    Views.SearchView {
        controller: fullRoot.controller
        anchors.fill: parent
        visible: controller && controller.nav && controller.nav.search && !controller.nav.player
    }

    // --- Vue Team Hub ---
    Views.TeamHubView {
        controller: fullRoot.controller
        anchors.fill: parent
        visible: controller && controller.nav && controller.nav.teamHub && !controller.nav.player && !controller.nav.schedule
    }

    // --- Vue Schedule (Équipe) ---
    Views.ScheduleView {
        controller: fullRoot.controller
        anchors.fill: parent
        visible: controller && controller.nav && controller.nav.schedule && !controller.nav.player
    }

    // --- Vue Bracket (Séries) ---
    Views.BracketView {
        controller: fullRoot.controller
        anchors.fill: parent
        visible: controller && controller.nav && controller.nav.bracket && !controller.nav.player
    }

    // --- Vue Calendar ---
    Views.CalendarView {
        controller: fullRoot.controller
        anchors.fill: parent
        visible: controller && controller.nav && controller.nav.calendar && !controller.nav.player
    }

    // --- Vue Day View ---
    Views.DayView {
        controller: fullRoot.controller
        anchors.fill: parent
        visible: controller && controller.nav && controller.nav.dayView && !controller.nav.detail && !controller.nav.calendar && !controller.nav.player
    }

    // --- Vue Player (À mettre en dernier pour être au-dessus de la pile) ---
    Views.PlayerView {
        controller: fullRoot.controller
        anchors.fill: parent
        visible: controller && controller.nav && controller.nav.player
    }
}
