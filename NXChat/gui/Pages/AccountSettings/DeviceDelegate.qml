// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/Buttons"
import "../../Base/HTile"

HTile {
    id: deviceTile

    property HListView view
    property string userId
    property bool offline: false

    signal verified()
    signal blacklisted()
    signal renameRequest(string name)
    signal deleteRequest()

    backgroundColor: "transparent"
    compact: false

    leftPadding: theme.spacing * 2
    rightPadding: 0

    contentItem: ContentRow {
        tile: deviceTile
        spacing: 0

        HCheckBox {
            id: checkBox
            activeFocusOnTab: false
            checked: view.checked[model.id] || false
            onClicked: view.toggleCheck(model.index)
        }

        HColumnLayout {
            Layout.leftMargin: theme.spacing

            HRowLayout {
                spacing: theme.spacing

                TitleLabel {
                    text: model.display_name || qsTr("Unnamed")
                }

                TitleRightInfoLabel {
                    tile: deviceTile
                    text: utils.smartFormatDate(model.last_seen_date)
                }
            }

            SubtitleLabel {
                tile: deviceTile
                font.family: theme.fontFamily.mono
                text:
                    model.last_seen_ip ?
                    model.id + " " + model.last_seen_ip :
                    model.id
            }
        }

        HButton {
            icon.name: "device-action-menu"
            toolTip.text: qsTr("Rename, verify or sign out")
            backgroundColor: "transparent"
            activeFocusOnTab: false
            onClicked: deviceTile.openMenu()

            Layout.fillHeight: true
        }
    }

    contextMenu: HMenu {
        id: actionMenu
        implicitWidth: Math.min(360 * theme.uiScale, window.width)
        onOpened: nameField.forceActiveFocus()

        HLabeledItem {
            width: parent.width
            label.topPadding: theme.spacing / 2
            label.text: qsTr("Public display name:")
            label.horizontalAlignment: Qt.AlignHCenter

            HRowLayout {
                enabled: ! deviceTile.offline
                width: parent.width

                HTextField {
                    id: nameField
                    defaultText: model.display_name
                    maximumLength: 255
                    horizontalAlignment: Qt.AlignHCenter
                    onAccepted: deviceTile.renameRequest(text)

                    Layout.fillWidth: true
                }

                HButton {
                    icon.name: "apply"
                    icon.color: theme.colors.positiveBackground
                    onClicked: deviceTile.renameRequest(nameField.text)

                    Layout.fillHeight: true
                }
            }
        }

        HMenuSeparator {}

        HLabel {
            id: noKeysLabel
            visible: model.type === "no_keys"
            width: parent.width
            height: visible ? implicitHeight : 0  // avoid empty space

            wrapMode: HLabel.Wrap
            horizontalAlignment: Qt.AlignHCenter
            textFormat: HLabel.RichText
            color: theme.colors.warningText
            text: qsTr(
                "This session doesn't support encryption or " +
                "failed to upload a verification key"
            )
        }

        HMenuSeparator {
            visible: noKeysLabel.visible
            height: visible ? implicitHeight : 0
        }

        HLabeledItem {
            width: parent.width
            label.text: qsTr("Actions:")
            label.horizontalAlignment: Qt.AlignHCenter

            AutoDirectionLayout {
                width: parent.width

                PositiveButton {
                    enabled: model.type !== "no_keys"
                    icon.name: "device-verify"
                    text:
                        model.type === "current" ? qsTr("Get verified") :
                        model.type === "verified" ? qsTr("Reverify") :
                        qsTr("Verify")

                    onClicked: {
                        actionMenu.focusOnClosed = null

                        window.makePopup(
                            "Popups/KeyVerificationPopup.qml",
                            {
                                focusOnClosed: nameField,
                                deviceOwner: deviceTile.userId,
                                deviceId: model.id,
                                deviceName: model.display_name,
                                ed25519Key: model.ed25519_key,
                                deviceIsCurrent: model.type === "current",
                                verifiedCallback: deviceTile.verified,
                                blacklistedCallback: deviceTile.blacklisted,
                            },
                        )
                    }
                }

                NegativeButton {
                    text: qsTr("Sign out")
                    enabled: ! deviceTile.offline
                    icon.name: "device-delete"
                    onClicked: deviceTile.deleteRequest()
                }
            }
        }
    }

    onLeftClicked: checkBox.clicked()

    DelegateTransitionFixer {}
}
