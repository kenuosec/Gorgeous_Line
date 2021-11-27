// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtGraphicalEffects 1.12

Image {
    id: icon

    property string svgName: ""

    property bool small: false
    property int dimension:
        theme ?
        (small ? theme.icons.smallDimension : theme.icons.dimension) :
        (small ? 16 : 22)

    property color colorize: theme.icons.colorize
    property string iconPack: theme ? theme.icons.preferredPack : "thin"

    cache: true
    asynchronous: true
    fillMode: Image.PreserveAspectFit
    //visible: Boolean(svgName)
    source: svgName ? `../../resource/icons/${iconPack}/${svgName}.svg` : ""

    sourceSize.width: svgName ? dimension : 32
    sourceSize.height: svgName ? dimension : 32

    layer.enabled: ! Qt.colorEqual(colorize, "transparent")
    layer.effect: ColorOverlay {
        color: icon.colorize
        cached: icon.cache

        Behavior on color { HColorAnimation {} }
    }
}
