// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   I   N   S   P   E   C   T   O   R                                      │
// │   widget inspector · per-widget appearance                               │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell.Widgets

import "../theme"
import "../services"
import "../components"

// Per-widget settings on a card beside the widget: shape, style, ink, opacity
// and removal. The first tile of each row follows the desktop default.
//
// Fills the surface so the card can go to the right of, the left of or below
// the widget, and so clicks on the card do not reach the background.
Item {
    id: root

    required property Item board

    readonly property string key: DesktopService.selected
    readonly property var row: DesktopService.entryOf(root.key)
    readonly property string moduleId: root.row ? root.row.id : ""
    readonly property var entry: ModuleService.entry(root.moduleId)
    readonly property var box: DesktopService.geometry(
        root.row ?? ({}), root.board.width, root.board.height)

    readonly property bool onPhoto: root.moduleId === "photo"

    readonly property bool styled: !root.onPhoto

    // Only a print has a chin to write in.
    readonly property bool captioned: root.onPhoto
        && DesktopService.themeOf(root.row) === "analogue"
        && DesktopService.familyOf(root.row) !== "8x2"

    // The caption field lets go when the surface loses the keyboard.
    Connections {
        target: DesktopService

        function onTypingChanged(): void {
            if (!DesktopService.typing)
                caption.focus = false
        }
    }

    Component.onDestruction: DesktopService.typing = false

    readonly property int cardWidth: 312
    readonly property int pad: 14
    readonly property int gap: 14

    // The widget's own overrides, empty when following the desktop.
    readonly property string ownTheme: root.row && root.row.theme ? root.row.theme : ""
    readonly property string ownStyle: root.row && root.row.style ? root.row.style : ""
    readonly property bool ownOpacity: root.row && typeof root.row.opacity === "number"

    // Colours for painting each style tile.
    function inkIn(style: string): var {
        return DesktopService.inkFor({ id: root.moduleId, style: style })
    }

    Rectangle {
        id: card

        // To the right of the widget, else the left, else below; kept on the
        // board.
        readonly property bool rightFits:
            root.box.x + root.box.width + root.gap + card.width
                <= root.board.width - Theme.desktopGutter
        readonly property bool leftFits:
            root.box.x - root.gap - card.width >= Theme.desktopGutter

        readonly property bool above: false

        x: card.above ? Math.max(Theme.desktopGutter, root.box.x + Theme.desktopGutter)
            : card.rightFits ? root.box.x + root.box.width + root.gap
            : (card.leftFits ? root.box.x - root.gap - card.width
                : Math.max(Theme.desktopGutter, Math.min(
                    root.board.width - Theme.desktopGutter - card.width, root.box.x)))
        y: card.above ? root.box.y - root.gap - card.height
            : Math.max(Theme.desktopGutter, Math.min(
                root.board.height - Theme.desktopGutter - card.height,
                card.rightFits || card.leftFits
                    ? root.box.y : root.box.y + root.box.height + root.gap))

        width: root.cardWidth
        height: column.implicitHeight + 2 * root.pad
        radius: Theme.radiusLarge
        color: Theme.island
        border.color: Theme.islandBorder
        border.width: 1

        Behavior on x { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }
        Behavior on y { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }

        // Exclusive from the press; otherwise the background's tap handler also
        // fires and closes the card.
        TapHandler {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            gesturePolicy: TapHandler.ReleaseWithinBounds
        }

        Column {
            id: column

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.pad
            spacing: 12

            // ── TITLE AND REMOVE ────────────────────────────────────────────

            Item {
                width: parent.width
                height: 28

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.entry
                        ? Tr.t(root.entry.name)
                        : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    color: Theme.text
                }

                PillButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Tr.t("Remove")
                    implicitHeight: 26
                    onClicked: DesktopService.remove(root.key)
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hairline }

            // ── SHAPE ───────────────────────────────────────────────────────
            //
            // The families this module has a face for, as footprints in cells.
            // The same choice as dragging the corner handle.

            Text {
                visible: true
                text: Tr.t("Shape")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLabel
                font.weight: Font.DemiBold
                color: Theme.textMuted
            }

            Row {
                visible: true
                spacing: 8

                Repeater {
                    model: DesktopService.familiesFor(root.moduleId, DesktopService.themeOf(root.row))

                    Rectangle {
                        id: shapeTile

                        required property string modelData

                        readonly property var shape: DesktopService.family(shapeTile.modelData)
                        readonly property bool current:
                            DesktopService.familyOf(root.row) === shapeTile.modelData

                        width: shapeTile.shape.cols * 9 + 12
                        height: 48
                        radius: Theme.radiusSmall
                        color: shapeTile.current ? Theme.islandSurfaceHover : "transparent"
                        border.color: shapeTile.current ? Theme.accent : Theme.hairline
                        border.width: 1

                        Rectangle {
                            anchors.centerIn: parent
                            width: shapeTile.shape.cols * 9
                            height: shapeTile.shape.rows * 9
                            radius: 3
                            color: shapeTile.current ? Theme.accent : Theme.textMuted
                        }

                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: DesktopService.setFamily(root.key, shapeTile.modelData)
                        }
                    }
                }
            }

            // ── PICTURE ─────────────────────────────────────────────────────
            //
            // For a photo: the picture, the picker (`Picker.qml`, in this
            // card's place) and a way to empty it. The only place a picture
            // is chosen.

            Text {
                visible: root.onPhoto
                text: Tr.t("Picture")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLabel
                font.weight: Font.DemiBold
                color: Theme.textMuted
            }

            Row {
                visible: root.onPhoto
                spacing: 10

                ClippingRectangle {
                    width: 48
                    height: 48
                    radius: width * Theme.pictureCorner
                    color: Theme.islandSurface

                    Image {
                        id: thumbnail

                        anchors.fill: parent
                        source: root.onPhoto ? DesktopService.pictureOf(root.row) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 96
                        sourceSize.height: 96
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: thumbnail.status !== Image.Ready
                        text: "󰋩"
                        font.family: Theme.fontMono
                        font.pixelSize: 18
                        color: Theme.textMuted
                    }
                }

                PillButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Tr.t("Choose…")
                    implicitHeight: 26
                    onClicked: DesktopService.picking = root.key
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.onPhoto && DesktopService.pictureOf(root.row) !== ""
                    icon: "󰅖"
                    iconSize: 13
                    onClicked: DesktopService.update(root.key, { picture: null })
                }
            }

            // ── CAPTION ─────────────────────────────────────────────────────
            //
            // Written in the print's chin. Typing holds the keyboard until
            // Enter, Escape or a click anywhere else.

            Text {
                visible: root.captioned
                text: Tr.t("Caption")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLabel
                font.weight: Font.DemiBold
                color: Theme.textMuted
            }

            Rectangle {
                visible: root.captioned
                width: parent.width
                height: 34
                radius: Theme.radiusSmall
                color: Theme.islandSurface
                border.color: caption.activeFocus ? Theme.accent : Theme.islandBorder
                border.width: 1

                Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

                TextInput {
                    id: caption

                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.row && typeof root.row.caption === "string" ? root.row.caption : ""
                    maximumLength: 40
                    font.family: Theme.fontSignature
                    font.pixelSize: 19
                    color: Theme.text
                    selectByMouse: true
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentText
                    clip: true

                    onActiveFocusChanged: DesktopService.typing = caption.activeFocus
                    onTextEdited: DesktopService.update(root.key, { caption: caption.text === "" ? null : caption.text })
                    Keys.onReturnPressed: caption.focus = false
                    Keys.onEnterPressed: caption.focus = false
                    Keys.onEscapePressed: caption.focus = false

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: caption.text === "" && !caption.activeFocus
                        text: Tr.t("Written under the picture")
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textMuted
                    }
                }
            }

            // ── THEME ───────────────────────────────────────────────────────
            //
            // The default first (follows the settings), then each theme, drawn
            // as a live clock face.

            Text {
                visible: true
                text: Tr.t("Face")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLabel
                font.weight: Font.DemiBold
                color: Theme.textMuted
            }

            Row {
                visible: true
                spacing: 8

                Repeater {
                    model: [{ id: "", label: "Default" }].concat(DesktopService.themes)

                    Rectangle {
                        id: themeTile

                        required property var modelData

                        readonly property string themeId: themeTile.modelData.id
                        readonly property string shown:
                            themeTile.themeId !== "" ? themeTile.themeId : SettingsService.desktopTheme
                        readonly property bool current: root.ownTheme === themeTile.themeId

                        width: 50
                        height: 48
                        radius: Theme.radiusSmall
                        color: "transparent"
                        border.color: themeTile.current ? Theme.accent : Theme.hairline
                        border.width: 1

                        ThemeSwatch {
                            anchors.centerIn: parent
                            theme: themeTile.shown
                            factor: 0.19
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 4
                            visible: themeTile.themeId === ""
                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.textMuted
                        }

                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: DesktopService.setTheme(root.key, themeTile.themeId)
                        }
                    }
                }
            }

            // ── STYLE ───────────────────────────────────────────────────────
            //
            // The default first, then the four styles, each tile painted as the
            // widget would be.

            Text {
                visible: root.styled
                text: Tr.t("Style")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLabel
                font.weight: Font.DemiBold
                color: Theme.textMuted
            }

            Row {
                visible: root.styled
                spacing: 8

                Repeater {
                    model: [{ id: "", label: "Default" }].concat(DesktopService.styles)

                    Rectangle {
                        id: styleTile

                        required property var modelData

                        readonly property string styleId: styleTile.modelData.id
                        // The style this tile shows; for the default tile, the
                        // desktop's style.
                        readonly property string shown:
                            styleTile.styleId !== "" ? styleTile.styleId : SettingsService.desktopStyle
                        readonly property var ink: root.inkIn(styleTile.shown)
                        readonly property bool current: root.ownStyle === styleTile.styleId

                        width: 50
                        height: 48
                        radius: Theme.radiusSmall
                        color: "transparent"
                        border.color: styleTile.current ? Theme.accent : Theme.hairline
                        border.width: 1

                        StyleSwatch {
                            anchors.centerIn: parent
                            style: styleTile.shown
                            ink: styleTile.ink
                        }

                        // A dot marks the default tile as "follow" rather than
                        // a fifth style.
                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 4
                            visible: styleTile.styleId === ""
                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.textMuted
                        }

                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: DesktopService.setStyle(root.key, styleTile.styleId)
                        }
                    }
                }
            }

            Text {
                visible: root.styled
                width: parent.width
                text: {
                    const theme = DesktopService.themes.find(
                        entry => entry.id === DesktopService.themeOf(root.row))
                    const style = DesktopService.styles.find(
                        entry => entry.id === DesktopService.styleOf(root.row))
                    const parts = [theme ? Tr.t(theme.label) : "", style ? Tr.t(style.label) : ""]
                    const own = root.ownTheme !== "" || root.ownStyle !== ""
                    return parts.filter(part => part !== "").join(" · ")
                        + (own ? "" : ` · ${Tr.t("default")}`)
                }
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLabel
                color: Theme.textMuted
            }

            // ── OPACITY ─────────────────────────────────────────────────────

            Item {
                visible: root.styled
                width: parent.width
                height: 40

                SliderRow {
                    anchors.left: parent.left
                    anchors.right: reset.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    height: 40
                    icon: "󰊸"
                    value: DesktopService.opacityOf(root.row)
                    from: 20
                    to: 100
                    onMoved: value => DesktopService.setOpacity(root.key, Math.round(value))
                }

                IconButton {
                    id: reset

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "󰦛"
                    iconSize: 13
                    enabled: root.ownOpacity
                    opacity: root.ownOpacity ? 1 : 0.3
                    onClicked: DesktopService.setOpacity(root.key, null)
                }
            }

        }
    }
}
