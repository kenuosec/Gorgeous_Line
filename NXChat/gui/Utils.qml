// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import CppUtils 0.1

QtObject {
    enum Media { Page, File, Image, Video, Audio }

    property QtObject theme: null
    property bool keyboardFlicking: false

    readonly property var imageExtensions: [
		"bmp", "gif", "jpg", "jpeg", "png", "pbm", "pgm", "ppm", "xbm", "xpm",
		"tiff", "webp", "svg",
    ]

    readonly property var videoExtensions: [
        "3gp", "avi", "flv", "m4p", "m4v", "mkv", "mov", "mp4",
		"mpeg", "mpg", "ogv", "qt", "vob", "webm", "wmv", "yuv",
    ]

    readonly property var audioExtensions: [
        "pcm", "wav", "raw", "aiff", "flac", "m4a", "tta", "aac", "mp3",
        "ogg", "oga", "opus",
    ]

    function makeObject(urlComponent, parent=null, properties={},
                        callback=null) {
        let comp = urlComponent

        if (! Qt.isQtObject(urlComponent)) {
            // It's an url or path string to a component
            comp = Qt.createComponent(urlComponent, Component.Asynchronous)
        }

        let ready = false

        comp.statusChanged.connect(status => {
            if ([Component.Null, Component.Error].includes(status)) {
               console.error("Failed creating component: ", comp.errorString())

            } else if (! ready && status === Component.Ready) {
                const incu = comp.incubateObject(
                    parent, properties, Qt.Asynchronous,
                )

                if (incu.status === Component.Ready) {
                    if (callback) callback(incu.object)
                    ready = true
                    return
                }

                incu.onStatusChanged = (istatus) => {
                    if (incu.status === Component.Error) {
                        console.error("Failed incubating object: ",
                                      incu.errorString())

                    } else if (istatus === Component.Ready &&
                               callback && ! ready) {
                        if (callback) callback(incu.object)
                        ready = true
                    }
                }
            }
        })

        if (comp.status === Component.Ready) comp.statusChanged(comp.status)
    }


    function makePopup(urlComponent, parent, properties={}, callback=null,
                       autoDestruct=true) {
        makeObject(urlComponent, parent, properties, (popup) => {
            popup.open()
            if (autoDestruct) popup.closed.connect(() => { popup.destroy() })
            if (callback)     callback(popup)
        })
    }


    function sum(array) {
        if (array.length < 1) return 0
        return array.reduce((a, b) => (isNaN(a) ? 0 : a) + (isNaN(b) ? 0 : b))
    }


    function range(startOrEnd, end=null, ) {
        // range(3) → [0, 1, 2, 3]
        // range(3, 6) → [3, 4, 5, 6]
        // range(3, -1) → [3, 2, 1, 0, -1]

        const numbers = []
        let realStart = end ? startOrEnd : 0
        let realEnd   = end ? end : startOrEnd

        if (realEnd < realStart)
            for (let i = realStart;  i >= realEnd; i--)
                numbers.push(i)
        else
            for (let i = realStart;  i <= realEnd; i++)
                numbers.push(i)

        return numbers
    }


    function chunk(array, chunkSize) {
        const chunks = []

        for (let i = 0; i < array.length; i += chunkSize) {
            chunks.push(array.slice(i, i + chunkSize))
        }

        return chunks
    }


    function isEmptyObject(obj) {
        return Object.entries(obj).length === 0 && obj.constructor === Object
    }


    function objectUpdate(current, update) {
        return Object.assign({}, current, update)
    }


    function objectUpdateRecursive(current, update) {
        for (const key of Object.keys(update)) {
            if ((key in current) && typeof(current[key]) === "object" &&
                    typeof(update[key]) === "object") {
                objectUpdateRecursive(current[key], update[key])
            } else {
                current[key] = update[key]
            }
        }
    }


    function numberWrapAt(num, max) {
        return num < 0 ? max + (num % max) : (num % max)
    }


    function hsluv(hue, saturation, lightness, alpha=1.0) {
        return CppUtils.hsluv(hue, saturation, lightness, alpha)
    }


    function hueFrom(string) {
        // Calculate and return a unique hue between 0 and 360 for the string
        let hue = 0
        for (let i = 0; i < string.length; i++) {
            hue += string.charCodeAt(i) * 99
        }
        return hue % 360
    }


    function nameColor(name, dim=false) {
        return hsluv(
            hueFrom(name),

            dim ?
            theme.controls.displayName.dimSaturation :
            theme.controls.displayName.saturation,

            dim ?
            theme.controls.displayName.dimLightness :
            theme.controls.displayName.lightness,
        )
    }


    function coloredNameHtml(name, userId, displayText=null, dim=false) {
        // substring: remove leading @
        return `<font color="${nameColor(name || userId.substring(1), dim)}">`+
               escapeHtml(displayText || name || userId) +
               "</font>"
    }


    function escapeHtml(text) {
        // Replace special HTML characters by encoded alternatives
        return text.replace(/&/g, "&amp;")
                    .replace(/</g, "&lt;")
                    .replace(/>/g, "&gt;")
                    .replace(/"/g, "&quot;")
                    .replace(/'/g, "&#039;")
    }


    function stripHtmlTags(text) {
        // XXX: Potentially unsafe!
        return text.replace(/<\/?[^>]+(>|$)/g, "")
    }


    function plain2Html(text) {
        // Escape html, convert `\n` into `<br>` tags and `\t` into four spaces
        return escapeHtml(text).replace(/\n/g, "<br>")
                               .replace(/\t/g, "&nbsp;" * 4)
    }


    function htmlColorize(text, color) {
        return `<font color="${color}">${text}</font>`
    }


    function processedEventText(ev) {
        const type       = ev.event_type
        const unknownMsg = type === "RoomMessageUnknown"
        const sender     = coloredNameHtml(ev.sender_name, ev.sender_id)

        return ev.content
    }

    function filterMatches(filter, text) {
        if (! filter) return true

        const filter_lower = filter.toLowerCase()

        if (filter_lower === filter) {
            // Consider case only if filter isn't all lowercase (smart case)
            filter = filter_lower
            text   = text.toLowerCase()
        }

        for (const word of filter.split(" ")) {
            if (word && ! text.includes(word)) {
                return false
            }
        }
        return true
    }


    function filterMatchesAny(filter, ...texts) {
        for (const text of texts) {
            if (filterMatches(filter, text)) return true
        }
        return false
    }


    function fitSize(minWidth, minHeight, width, height, maxWidth, maxHeight) {
        if (width >= height) {
            const new_width = Math.min(Math.max(width, minWidth), maxWidth)
            return Qt.size(new_width, height / (width / new_width))
        }

        const new_height = Math.min(Math.max(height, minHeight), maxHeight)
        return Qt.size(width / (height / new_height), new_height)
    }


    function minutesBetween(date1, date2) {
        return ((date2 - date1) / 1000) / 60
    }


    function dateIsDay(date, dayDate) {
        return date.getDate() === dayDate.getDate() &&
               date.getMonth() === dayDate.getMonth() &&
               date.getFullYear() === dayDate.getFullYear()
    }


    function dateIsToday(date) {
        return dateIsDay(date, new Date())
    }


    function dateIsYesterday(date) {
        const yesterday = new Date()
        yesterday.setDate(yesterday.getDate() - 1)
        return dateIsDay(date, yesterday)
    }


    function formatTime(time, seconds=true) {
        return Qt.formatTime(
            time,

            Qt.locale().timeFormat(
                seconds ? Locale.LongFormat : Locale.NarrowFormat
            ).replace(/\./g, ":").replace(/ t$/, "")
            // en_DK.UTF-8 locale wrongfully gives "." separators;
            // also remove the timezone at the end
        )
    }


    function smartFormatDate(date) {
        return (
            date < new Date(1) ?
            "" :

            // e.g. "03:24"
            dateIsToday(date) ?
            formatTime(date, false) :

            // e.g. "5 Dec"
            date.getFullYear() === new Date().getFullYear() ?
            Qt.formatDate(date, "d MMM") :

            // e.g. "Jan 2020"
            Qt.formatDate(date, "MMM yyyy")
        )
    }


    function formatRelativeTime(milliseconds, shortForm=true) {
        const seconds = Math.floor(milliseconds / 1000)

        if (shortForm) {
            return (
                seconds < 60 ?
                qsTr("%1s").arg(seconds) :

                seconds < 60 * 60 ?
                qsTr("%1mn").arg(Math.floor(seconds / 60)) :

                seconds < 60 * 60 * 24 ?
                qsTr("%1h").arg(Math.floor(seconds / 60 / 60)) :

                seconds < 60 * 60 * 24 * 30 ?
                qsTr("%1d").arg(Math.floor(seconds / 60 / 60 / 24)) :

                seconds < 60 * 60 * 24 * 30 * 12 ?
                qsTr("%1mo").arg(Math.floor(seconds / 60 / 60 / 24 / 30)) :

                qsTr("%1y").arg(Math.floor(seconds / 60 / 60 / 24 / 30 / 12))
            )
        }

        return (
            seconds < 60 ?
            qsTr("%1 seconds").arg(seconds) :

            seconds < 60 * 60 ?
            qsTr("%1 minutes").arg(Math.floor(seconds / 60)) :

            seconds < 60 * 60 * 24 ?
            qsTr("%1 hours").arg(Math.floor(seconds / 60 / 60)) :

            seconds < 60 * 60 * 24 * 30 ?
            qsTr("%1 days").arg(Math.floor(seconds / 60 / 60 / 24)) :

            seconds < 60 * 60 * 24 * 30 * 12 ?
            qsTr("%1 months").arg(Math.floor(seconds / 60 / 60 / 24 / 30)) :

            qsTr("%1 years").arg(Math.floor(seconds / 60 / 60 / 24 / 30 / 12))
        )
    }


    function formatDuration(milliseconds) {
        const totalSeconds = milliseconds / 1000

        const hours = Math.floor(totalSeconds / 3600)
        let minutes = Math.floor((totalSeconds % 3600) / 60)
        let seconds = Math.floor(totalSeconds % 60)

        if (seconds < 10) seconds = `0${seconds}`
        if (hours < 1)    return `${minutes}:${seconds}`

        if (minutes < 10) minutes = `0${minutes}`
        return `${hours}:${minutes}:${seconds}`
    }


    function round(floatNumber, decimalDigits=2) {
        return parseFloat(floatNumber.toFixed(decimalDigits))
    }


    function commaAndJoin(array) {
        if (array.length === 0) return ""
        if (array.length === 1) return array[0]

        return qsTr("%1 and %2")
               .arg(array.slice(0, -1).join(qsTr(", ")))
               .arg(array.slice(-1)[0])
    }


    function flickPages(flickable, pages, horizontal=false, multiplier=8) {
        // Adapt velocity and deceleration for the number of pages to flick.
        // If this is a repeated flicking, flick faster than a single flick.
        if (! flickable.interactive) return

        keyboardFlicking = true

        const futureVelocity  =
            (horizontal ? -flickable.width : -flickable.height) * pages

        const currentVelocity =
            horizontal ?
            -flickable.horizontalVelocity :
            -flickable.verticalVelocity

        const goFaster        =
            (futureVelocity < 0 && currentVelocity < futureVelocity / 2) ||
            (futureVelocity > 0 && currentVelocity > futureVelocity / 2)

        const magicNumber    = 2.5
        const normalDecel    = flickable.flickDeceleration
        const normalMaxSpeed = flickable.maximumFlickVelocity
        const fastMultiply   =
            pages && multiplier / (1 - Math.log10(Math.abs(pages)))

        flickable.maximumFlickVelocity = 5000


        flickable.flickDeceleration = Math.max(
            goFaster ? normalDecel : -Infinity,
            Math.abs(normalDecel * magicNumber * pages),
        )

        const flick =
            futureVelocity * magicNumber * (goFaster ? fastMultiply : 1)

        horizontal ? flickable.flick(flick, 0) : flickable.flick(0, flick)

        flickable.maximumFlickVelocity = normalMaxSpeed
        flickable.flickDeceleration    = normalDecel

        keyboardFlicking = false
    }


    function flickToTop(flickable) {
        if (! flickable.interactive) return
        if (flickable.visibleArea.yPosition < 0) return

        flickable.contentY = flickable.originY
        flickable.flick(0, 1000)  // Force the delegates to load and bounce
    }


    function flickToBottom(flickable) {
        if (! flickable.interactive) return
        if (flickable.visibleArea.yPosition < 0) return

        flickable.contentY =
            flickable.originY + flickable.contentHeight - flickable.height

        flickable.flick(0, -1000)
    }


    function urlFileName(url) {
        return url.toString().split("/").slice(-1)[0].split("?")[0]
    }


    function urlExtension(url) {
        return urlFileName(url).split(".").slice(-1)[0]
    }


    function getLinkType(url) {
        const ext = urlExtension(url).toLowerCase()

        return (
            imageExtensions.includes(ext) ? Utils.Media.Image :
            videoExtensions.includes(ext) ? Utils.Media.Video :
            audioExtensions.includes(ext) ? Utils.Media.Audio :
            Utils.Media.Page
        )
    }


    function sumChildrenImplicitWidths(visibleChildren, spacing=0) {
        let sum = 0

        for (let i = 0; i < visibleChildren.length; i++) {
            const item = visibleChildren[i]

            if (item)
                sum += (item.width > 0 ? item.implicitWidth : 0) + spacing
        }

        return sum
    }


    function getWordAtPosition(text, position) {
        // getWordAtPosition("foo bar", 1) → {word: "foo", start: 0, end: 2}
        let seen = -1

        for (var word of text.split(/(\s+)/)) {
            var start = seen + 1
            seen += word.length
            if (seen >= position) return {word, start, end: seen}
        }

        return {word, start, end: seen}
    }


    function getClassPathRegex(obj) {
        const regexParts = []
        let parent       = obj

        while (parent) {
            if (! parent.ntheme || ! parent.ntheme.classes.length) {
                parent = parent.parent
                continue
            }

            const names = []
            const end   = regexParts.length ? "\\.)?" : ")"

            for (let i = 0; i < parent.ntheme.classes.length; i++)
                names.push(parent.ntheme.classes[i].name)

            regexParts.push("(" + names.join("|") + end)
            parent = parent.parent
        }

        return new RegExp("^" + regexParts.reverse().join("") + "$")
    }

    function makeRgb(r, g, b) {
        var ret = (r << 16 | g << 8 | b)
        return ("#" + ret.toString(16)).toUpperCase()
    }

    function formatPushRuleName(userId, rule) {
        // rule: item from ModelStore.get(<userId>, "pushrules")

        const roomColor = theme.colors.accentText
        const room      = ModelStore.get(userId, "rooms").find(rule.rule_id)

        const text =
            rule.rule_id === ".m.rule.master" ?
            qsTr("Any message") :

            rule.rule_id === ".m.rule.suppress_notices" ?
            qsTr("Messages sent by bots") :

            rule.rule_id === ".m.rule.invite_for_me" ?
            qsTr("Received room invites") :

            rule.rule_id === ".m.rule.member_event" ?
            qsTr("Membership, name & avatar changes") :

            rule.rule_id === ".m.rule.contains_display_name" ?
            qsTr("Messages containing my display name") :

            rule.rule_id === ".m.rule.tombstone" ?
            qsTr("Room migration alerts") :

            rule.rule_id === ".m.rule.reaction" ?
            qsTr("Emoji reactions") :

            rule.rule_id === ".m.rule.roomnotif" ?
            qsTr("Messages containing %1").arg(
                htmlColorize("@room", roomColor),
            ) :

            rule.rule_id === ".m.rule.contains_user_name" ?
            qsTr("Contains %1").arg(coloredNameHtml(
                "", userId, userId.split(":")[0].substring(1),
            )):

            rule.rule_id === ".m.rule.call" ?
            qsTr("Incoming audio calls") :

            rule.rule_id === ".m.rule.encrypted_room_one_to_one" ?
            qsTr("Encrypted 1-to-1 messages") :

            rule.rule_id === ".m.rule.room_one_to_one" ?
            qsTr("Unencrypted 1-to-1 messages") :

            rule.rule_id === ".m.rule.message" ?
            qsTr("Unencrypted group messages") :

            rule.rule_id === ".m.rule.encrypted" ?
            qsTr("Encrypted group messages") :

            rule.rule_id === ".im.vector.jitsi" ?
            qsTr("Incoming Jitsi calls") :

            rule.kind === "content" ?
            qsTr('Contains "%1"').arg(rule.pattern) :

            rule.kind === "sender" ?
            coloredNameHtml("", rule.rule_id) :

            room && room.display_name && rule.kind !== "room" ?
            qsTr("Messages in room %1").arg(
                htmlColorize(escapeHtml(room.display_name), roomColor)
            ) :

            room && room.display_name ?
            escapeHtml(room.display_name) :

            escapeHtml(rule.rule_id)

        return rule.enabled ? text : qsTr("%1 (disabled rule)").arg(text)
    }
}
