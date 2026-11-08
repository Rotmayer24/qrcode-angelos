import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar
import "."

// The panel button. Pixel: a flat PxButton with the grid icon. Mac (Skin.mac, the Golden Gate
// menu bar): a monochrome line icon in the bar's ink, like a menu bar extra. Clicking opens the
// panel as a mini window by the button: a layer-shell window of its own (like the note editor,
// the start menu and every other shell overlay that owns the keyboard) — not a desktop window
// in the window list, so it looks like a little widget of the panel, not like a terminal.
// The keyboard comes with WlrKeyboardFocus.Exclusive while it is open (a bar popup is an
// xdg_popup, and typed text never reaches one), with the launcher's focus-kick in case niri
// did not hand the keys over at once (issue #22 there). The panel keeps the window chrome of
// the look in use: the pixel frame (PxWindow, a little "qrcode.exe") or, on Golden Gate, glass
// with a close dot — placed where BarPopup put both, with the same arithmetic.
Item {
    id: root

    property var plugin
    property string screenName
    property var barWindow
    // the pixel bar's hooks (BarItem): its padding and the hell bar's ink go to the button
    property int hpad: -1
    property bool barInk: false
    readonly property string icon: btn.icon
    readonly property string text: btn.text
    readonly property bool barOpen: !!win && win.visible
    readonly property bool mac: Skin.mac
    readonly property int goldenPad: GoldenGate.px(12)

    implicitWidth: mac ? macIcon.implicitWidth + Skin.px(4) : btn.implicitWidth
    implicitHeight: mac ? Skin.px(18) : btn.implicitHeight

    PxButton {
        id: btn
        visible: !root.mac
        anchors.fill: parent
        compact: true
        flat: true
        hpad: root.hpad
        barInk: root.barInk
        icon: "grid"
        checked: root.barOpen
        onClicked: root.toggle()
    }

    MacIcon {
        id: macIcon
        visible: root.mac
        anchors.centerIn: parent
        name: "scan"
        size: Skin.px(16)
        stroke: 2
        color: Skin.ink(root.screenName)
    }

    MouseArea {
        id: hot
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // in pixel the button itself takes the click
        enabled: root.mac
        onClicked: root.toggle()
    }

    function toggle() {
        // built at the first click (sync), shown/hidden from then on
        if (!loader.item)
            loader.active = true;
        if (!loader.item)
            return;
        if (loader.item.visible)
            loader.item.visible = false;
        else
            root.show();
    }
    // the window is made once per screen's button; two screens keep two windows,
    // each bound to its own screen
    function show() {
        if (!loader.item)
            loader.active = true;
        if (!!loader.item) {
            loader.item.screen = Quickshell.screens.find(s => s.name === root.screenName) || null;
            loader.item.visible = true;
        }
    }

    LazyLoader {
        id: loader
        active: false
        component: panelWindow
    }
    readonly property var win: loader.item

    // `qs ipc call qrcode open` — for the terminal and the runner
    IpcHandler {
        target: "qrcode"

        function open() {
            root.show();
        }
    }

    Component {
        id: panelWindow

        PanelWindow {
            id: win
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            screen: Quickshell.screens.find(s => s.name === root.screenName) || Quickshell.screens[0]
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "angelos-plugin-qrcode"
            // owns the keyboard while it is open; None the moment it hides. The launcher's
            // kick: opened while a popup's grab was ending, niri sometimes skips to hand the
            // keys over — re-ask once (Launcher.qml, issue #22)
            WlrLayershell.keyboardFocus: win.visible && !win.focusKick ? (Shell.dev ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None
            property bool focusKick: false
            Timer {
                id: focusCheck
                interval: 200
                onTriggered: {
                    if (win.visible && !win.active && !win.focusKick) {
                        win.focusKick = true;
                        Qt.callLater(() => {
                            win.focusKick = false;
                            win.queryFocus();
                        });
                    }
                }
            }

            // ---- where the button is on its screen: the bar window lies at the screen edge
            // with no margins, so bar-window coordinates become screen ones by the edge.
            // Computed in locate() at every opening — plain values, no bindings to chase.
            readonly property Item anchorItem: root.mac ? macIcon : btn

            // the content box (the panel inside the look's chrome) and the chrome around it
            readonly property int contentW: Skin.px(300)
            readonly property int contentH: Skin.px(396)
            readonly property int pad: root.mac ? GoldenGate.px(12) : 0
            readonly property int shadow: root.mac ? GoldenGate.px(12) : 0
            readonly property int titleH: root.mac ? GoldenGate.px(26) : 0
            // the footprint the look's chrome asks the surface for (BarPopup's arithmetic)
            readonly property int surfW: root.mac ? contentW + pad * 2 + GoldenGate.px(24) : contentW + Theme.u * 3
            readonly property int surfH: root.mac ? titleH + contentH + pad * 2 + GoldenGate.px(24) : titleH + contentH + Theme.pad * 2 + Theme.u * 8

            // places the box where BarPopup would put it (anchor edges Bottom|Right, gravity
            // Bottom|Left): pixel — the window's left edge at the button's right, glass — from
            // the icon's right; a bar on the bottom edge puts it over the button; kept on screen
            function locate() {
                const b = root.barWindow;
                if (!b || !win.screen || !anchorItem)
                    return;
                const p = anchorItem.mapToItem(null, 0, 0);
                const e = b.edge === undefined ? "top" : String(b.edge);
                let bx = p.x, by = p.y;
                if (e === "bottom")
                    by += win.screen.height - b.height;
                if (e === "right")
                    bx += win.screen.width - b.width;
                const right = bx + anchorItem.width, left = bx, bottom = by + anchorItem.height;
                let x, y;
                if (root.mac)
                    x = Math.max(Theme.u, Math.min(right + GoldenGate.px(4), win.screen.width - surfW - Theme.u));
                else if (e === "left")
                    x = Math.max(Theme.u, Math.min(right + Theme.u * 2, win.screen.width - surfW - Theme.u));
                else if (e === "right")
                    x = Math.max(Theme.u, Math.min(left - surfW - Theme.u * 2, win.screen.width - surfW - Theme.u));
                else
                    x = Math.max(Theme.u, Math.min(right, win.screen.width - surfW - Theme.u));
                if (e === "bottom")
                    y = Math.max(Theme.u, by - surfH - Theme.u * 2);
                else
                    y = Math.max(Theme.u, Math.min(bottom + (root.mac ? GoldenGate.px(4) : Theme.u * 2), win.screen.height - surfH - Theme.u));
                box.x = x;
                box.y = y;
            }

            onVisibleChanged: {
                if (visible) {
                    locate();
                    // the panel is built with the window still invisible: put the field in focus
                    // when the window itself shows (and again whenever it reappears)
                    Qt.callLater(win.queryFocus);
                    focusCheck.restart();
                    // the panel fades in as the mini window opens
                    panel.opacity = 0;
                    fade.restart();
                }
            }
            function queryFocus() {
                panel.queryFocus();
            }
            function hide() {
                visible = false;
            }

            // a click anywhere beyond the window closes it (a bar one included)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                z: -1
                onPressed: win.hide()
            }

            Item {
                id: box
                width: win.surfW
                height: win.surfH
                focus: true
                Keys.onEscapePressed: win.hide()

                // the pixel look: the little NGO window frame is the window itself
                PxWindow {
                    id: px
                    visible: !root.mac
                    width: win.contentW
                    height: win.surfH - Theme.u * 3
                    title: Skin.title("qrcode")
                    icon: "grid"
                    compact: true
                    active: win.visible
                    onCloseClicked: win.hide()

                    PxScroll {
                        anchors.fill: parent
                        contentHeight: panel.implicitHeight

                        Panel {
                            id: panel
                            width: parent.width
                            plugin: root.plugin
                        }
                    }
                }

                // the Golden Gate look: a glass card with a title and a close dot
                MacGlass {
                    visible: root.mac
                    x: win.shadow
                    y: win.shadow
                    width: win.contentW + win.pad * 2
                    height: win.titleH + win.contentH + win.pad * 2
                    radius: GoldenGate.px(14)
                    shadowSize: GoldenGate.px(20)
                    shadowY: GoldenGate.px(5)

                    MacText {
                        x: root.goldenPad
                        y: GoldenGate.px(8)
                        width: parent.width - root.goldenPad * 3
                        text: I18n.t("QR-код", "QR Code")
                        semibold: true
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        id: close
                        // the macOS close dot: a soft red circle, hollow while idle
                        x: parent.width - root.goldenPad - height
                        y: GoldenGate.px(6)
                        width: GoldenGate.px(14)
                        height: width
                        radius: width / 2
                        color: closeHot.containsMouse ? Theme.danger : "transparent"
                        border.width: 1.5
                        border.color: Theme.danger

                        MouseArea {
                            id: closeHot
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.hide()
                        }
                    }

                    Item {
                        id: macBody
                        x: root.goldenPad
                        y: root.goldenPad + win.titleH
                        width: parent.width - root.goldenPad * 2
                        height: win.contentH

                        Panel {
                            id: macPanel
                            anchors.fill: parent
                            plugin: root.plugin
                        }
                    }
                }
            }

            // the panel fades in as the mini window opens
            NumberAnimation {
                id: fade
                targets: [panel, macPanel]
                properties: "opacity"
                to: 1
                duration: Skin.ms(220)
            }
        }
    }
}
