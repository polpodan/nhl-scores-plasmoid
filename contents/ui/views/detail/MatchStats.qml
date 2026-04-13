import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import "../../logic.js" as Logic
import "../../components" as Components

ColumnLayout {
    id: statsRoot
    property var controller
    spacing: 8

    Rectangle {
        id: ppBanner
        Layout.alignment: Qt.AlignHCenter
        property var sit: controller ? controller.parseSituation(controller.det.sitCode, controller.det.away, controller.det.home) : null
        visible: !!sit && (sit.isSpecial || sit.emptyNet)
        width:  ppBannerContent.implicitWidth + 20
        height: ppBannerContent.implicitHeight + 10
        radius: 6
        color: {
            if (sit && sit.ppTeam && controller) {
                var isAw = (sit.ppTeam === controller.det.away);
                var op = isAw ? controller.det.home : controller.det.away;
                return controller.teamColorAdapted(sit.ppTeam, op, isAw, false);
            }
            return (sit && (sit.emptyNet || sit.isSpecial) ? "#444" : Kirigami.Theme.highlightColor);
        }
        border.color: "white"
        border.width: (sit && sit.isSpecial) ? 1 : 0
        Column {
            id: ppBannerContent
            anchors.centerIn: parent
            spacing: 2
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                Text {
                    text: ppBanner.sit ? ppBanner.sit.ppType : ''
                    font.pixelSize: 14
                    font.bold: true
                    color: 'white'
                }
                Text {
                    visible: ppBanner.sit && !ppBanner.sit.even
                    text: ppBanner.sit ? ((ppBanner.sit.ppTeam || '') + '  ' + ppBanner.sit.awaySkaters + 'v' + ppBanner.sit.homeSkaters) : ''
                    font.pixelSize: 14
                    color: 'white'
                }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4
                visible: ppBanner.sit !== null && ppBanner.sit.emptyNet
                Text {
                    text: '🥅'
                    font.pixelSize: 13
                }
                Text {
                    text: ppBanner.sit && ppBanner.sit.enTeam ? ppBanner.sit.enTeam : ''
                    font.pixelSize: 13
                    font.bold: true
                    color: 'white'
                }
            }
        }
    }

    // ── Tirs au but ───────────────────────────────────────────────────
    Components.StatComparisonBar {
        visible: controller && !controller.det.loading && controller.det.status !== 'UPCOMING' && controller.det.stats['sog'] !== undefined
        Layout.fillWidth: true
        label: i18n('Shots on Goal')
        awayValue: (controller && controller.det.stats['sog']) ? controller.det.stats['sog'].away : 0
        homeValue: (controller && controller.det.stats['sog']) ? controller.det.stats['sog'].home : 0
        awayRaw: (controller && controller.det.stats['sog']) ? controller.det.stats['sog'].away : 0
        homeRaw: (controller && controller.det.stats['sog']) ? controller.det.stats['sog'].home : 0
        awayColor: controller ? controller.teamColorAdapted(controller.det.away, controller.det.home, true, false) : "gray"
        homeColor: controller ? controller.teamColorAdapted(controller.det.home, controller.det.away, false, false) : "gray"
    }

    Rectangle {
        visible: controller && !controller.det.loading && controller.det.status !== 'UPCOMING' && Object.keys(controller.det.stats).length > 0
        Layout.fillWidth: true
        height: 1
        radius: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: controller ? Logic.getTeamColor(controller.det.away) : "gray"
            }
            GradientStop {
                position: 1.0
                color: controller ? Logic.getTeamColor(controller.det.home) : "gray"
            }
        }
        opacity: 0.6
    }

    ColumnLayout {
        visible: controller && !controller.det.loading && controller.det.status !== 'UPCOMING' && Object.keys(controller.det.stats).length > 0
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            model: {
                if (!controller) return []
                let order = ['faceoffWinningPctg','powerPlay','pim','hits','blockedShots','giveaways','takeaways']
                let labels = { 'faceoffWinningPctg': i18n('Faceoffs %'), 'powerPlay': i18n('Power Play'), 'hits': i18n('Hits'), 'blockedShots': i18n('Blocks'), 'giveaways': i18n('Giveaways'), 'takeaways': i18n('Takeaways'), 'pim': i18n('PIM') }
                let rows = []
                for (let i = 0; i < order.length; i++) {
                    let k = order[i]; let entry = controller.det.stats[k]
                    if (entry === undefined) continue
                    let av = entry.away; let hv = entry.home; let avRaw = 0, hvRaw = 0; let avSub = '', hvSub = ''
                    if (k === 'powerPlay' && av !== null && typeof av === 'object') {
                        let ho = entry.home
                        avRaw = av.opportunities > 0 ? av.goals / av.opportunities : 0
                        hvRaw = ho.opportunities > 0 ? ho.goals / ho.opportunities : 0
                        avSub = av.opportunities > 0 ? (avRaw*100).toFixed(1) + '%' : '—'
                        hvSub = ho.opportunities > 0 ? (hvRaw*100).toFixed(1) + '%' : '—'
                        av = (av.goals||0) + '/' + (av.opportunities||0); hv = (ho.goals||0) + '/' + (ho.opportunities||0)
                    } else if (k === 'faceoffWinningPctg') {
                        avRaw = typeof av === 'number' ? av / 100 : 0; hvRaw = typeof hv === 'number' ? hv / 100 : 0
                        av = typeof av === 'number' ? av.toFixed(1) + '%' : String(av); hv = typeof hv === 'number' ? hv.toFixed(1) + '%' : String(hv)
                    } else {
                        let total = (parseFloat(av)||0) + (parseFloat(hv)||0)
                        avRaw = total > 0 ? (parseFloat(av)||0) / total : 0.5; hvRaw = total > 0 ? (parseFloat(hv)||0) / total : 0.5
                        av = String(av); hv = String(hv)
                    }
                    rows.push({ label: labels[k] || k, away: av, home: hv, awayRaw: avRaw, homeRaw: hvRaw, awaySub: avSub, homeSub: hvSub })
                }
                return rows
            }
            delegate: Components.StatComparisonBar {
                Layout.fillWidth: true
                label: modelData.label
                awayValue: modelData.away
                homeValue: modelData.home
                awaySub: modelData.awaySub
                homeSub: modelData.homeSub
                awayRaw: modelData.awayRaw
                homeRaw: modelData.homeRaw
                awayColor: controller ? controller.teamColorAdapted(controller.det.away, controller.det.home, true, false) : "gray"
                homeColor: controller ? controller.teamColorAdapted(controller.det.home, controller.det.away, false, false) : "gray"
            }
        }
    }
}
