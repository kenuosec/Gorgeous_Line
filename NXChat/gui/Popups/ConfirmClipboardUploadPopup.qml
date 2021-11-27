// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../Base/Buttons"
//
// Make sure to initialize the image provider by
// importing this first:
import Clipboard 0.1

HColumnPopup {
    id: popup
    property var doneCallback: null
    property string display_name

    contentWidthLimit: theme.controls.popup.defaultWidth * 1.25

    page.footer: AutoDirectionLayout {
        ApplyButton {
            id: uploadButton
            text: qsTr("Send")
            icon.name: "confirm-uploading-file"
            onClicked: {               
                if(doneCallback) {
                    doneCallback(Clipboard.image)
                }
                popup.close()
            }
        }

        CancelButton {
            id: cancelButton
            onClicked: popup.close()
        }
    }

    onOpened: uploadButton.forceActiveFocus()

    SummaryLabel {
        text:
            qsTr("Send copied image to %1 ?")
            .arg(utils.htmlColorize(display_name, theme.colors.accentText))

        textFormat: Text.StyledText
    }

    HImage {
        id: image

        property int updateCounter: 0

        source: "image://clipboard/" + updateCounter
        sourceSize.width: popup.contentWidthLimit

        onUpdateCounterChanged: {
            source = "Need an invalid value to update properly, don't know why"
            source = "image://clipboard/" + updateCounter
        }

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight:
            status === Image.Ready ?
            width / (implicitWidth / implicitHeight) :
            96 * theme.uiScale  // for spinner

        Behavior on Layout.preferredHeight { HNumberAnimation {} }

        Connections {
            target: Clipboard
            function  onContentChanged() {
                Clipboard.hasImage ? image.updateCounter += 1 : popup.close()
            }

        }
    }
}
