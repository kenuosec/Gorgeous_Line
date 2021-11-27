// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

HDrawer {
    id: pane

    default property alias swipeViewData: swipeView.contentData

    property color buttonsBackgroundColor

    property int buttonWidth:
        buttonRepeater.count > 0 ? buttonRepeater.itemAt(0).implicitWidth : 0

    readonly property alias contentTranslation: contentTranslation
    readonly property alias buttonRepeater: buttonRepeater
    readonly property alias swipeView: swipeView

    defaultSize: buttonRepeater.count * buttonWidth
    minimumSize: buttonWidth

    HColumnLayout {
        anchors.fill: parent
        transform: Translate { id: contentTranslation }

        Rectangle {
            color: buttonsBackgroundColor

            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height

            HFlow {
                id: buttonFlow
                width: parent.width
                populate: null

                Repeater {
                    id: buttonRepeater
                }
            }
        }

        HSwipeView {
            id: swipeView
            clip: true
            interactive: ! pane.collapsed

            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
