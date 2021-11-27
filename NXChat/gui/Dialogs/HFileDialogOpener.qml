// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import Qt.labs.platform 1.1

Item {
    id: opener

    enum FileType { All, Images, Videos, Audios }

    property bool fill: true

    property alias dialog: fileDialog
    property string selectedFile: ""
    property string file: ""
    property var selectedFiles: []
    property var files: []

    property string selectSubject:
        dialog.fileMode === FileDialog.SaveFile ? qsTr("file") : qsTr("open")

    property int fileType: HFileDialogOpener.FileType.All

    signal filePicked(string file)
    signal filesPicked(var files)
    signal cancelled()

    anchors.fill: fill ? parent : undefined

    TapHandler { enabled: opener.enabled && fill; onTapped: fileDialog.open() }

    FileDialog {
        id: fileDialog

        property var filters: ({
            all:    qsTr("All files") + " (*)",
            images: qsTr("Image files") +
                    " (*.jpg *.jpeg *.png *.gif *.bmp *.webp)",
            videos: qsTr("Video files") + " (*.mp4)",
            audios :qsTr("Audio files") + " (*.mp3)"
        })

        nameFilters:
            fileType === HFileDialogOpener.FileType.Images ?  [filters.images] :
            fileType === HFileDialogOpener.FileType.Videos ?  [filters.videos] :
            fileType === HFileDialogOpener.FileType.Audios ?  [filters.audios] :[filters.all]

            folder: StandardPaths.writableLocation(
                fileType === HFileDialogOpener.FileType.Images ?
                StandardPaths.PicturesLocation :
                StandardPaths.HomeLocation
            )

        title: fileMode === FileDialog.OpenFile ?
               qsTr("Select a file to open") :

               fileMode === FileDialog.OpenFiles ?
               qsTr("Select files to open") :

               fileMode === FileDialog.SaveFile ?
               qsTr("Save as...") :

               ""

        modality: Qt.NonModal

        onVisibleChanged: if (visible) {
            opener.selectedFile   = Qt.binding(() => Qt.resolvedUrl(currentFile))
            opener.file           = Qt.binding(() => Qt.resolvedUrl(file))
            opener.files          = Qt.binding(() => Qt.resolvedUrl(files))
            opener.selectedFiles  =
                Qt.binding(() => Qt.resolvedUrl(currentFiles))
        }

        onAccepted: {
            opener.selectedFile  = currentFile
            opener.selectedFiles = currentFiles
            opener.file          = file
            opener.files         = files

            opener.filePicked(file)
            opener.filesPicked(files)
        }

        onRejected: {
            selectedFile  = ""
            file          = ""
            selectedFiles = ""
            files         = ""
            cancelled()
        }
    }
}
