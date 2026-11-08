import QtQuick
import qs.config
import qs.services

// A QR code drawn from a module matrix (QrCode.js) with an optional image over its centre.
// Dark modules go on a light plate: a QR code has to be dark-on-light to scan, in every theme.
Item {
    id: root

    property var modules: []          // flat 0/1 array, row by row
    property int count: 0             // modules per side
    property string logo: ""          // file:// URL of the centre image, "" for none
    readonly property int logoStatus: img.status
    readonly property bool logoReady: logo !== "" && img.status === Image.Ready

    readonly property color ink: "black"
    readonly property color paper: "white"
    readonly property int quiet: 4    // the quiet zone, in modules
    readonly property real dpr: Window.window ? Window.window.devicePixelRatio : 1
    // an exact whole number of device pixels per module: crisp edges, no seams, and it scans
    // better than a blurred resample; the code is drawn that big, centred in the item
    readonly property int k: count > 0 ? Math.max(1, Math.floor(Math.min(width, height) * dpr / (count + quiet * 2))) : 1
    readonly property real drawn: count > 0 ? k * (count + quiet * 2) / dpr : 0
    readonly property real cell: count > 0 ? drawn / (count + quiet * 2) : 0

    implicitWidth: Skin.px(200)
    implicitHeight: implicitWidth

    // strong: first appearance (grows in with a scan line); otherwise a small pulse on every update
    function reveal(strong) {
        anim.strong = strong;
        anim.restart();
        if (strong)
            sweep.restart();
    }

    onModulesChanged: canvas.requestPaint()
    onCountChanged: canvas.requestPaint()

    Rectangle {
        id: plate
        anchors.centerIn: parent
        width: root.drawn
        height: root.drawn
        color: root.paper
        radius: Math.min(Skin.radius, root.cell * root.quiet)
        transformOrigin: Item.Center

        Canvas {
            id: canvas
            anchors.fill: parent
            smooth: false
            canvasSize: Qt.size((root.count + root.quiet * 2) * root.k, (root.count + root.quiet * 2) * root.k)
            // show the whole canvas, scaled into the item (otherwise only its top-left corner shows)
            canvasWindow: Qt.rect(0, 0, canvasSize.width, canvasSize.height)
            onCanvasSizeChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, canvasSize.width, canvasSize.height);
                const n = root.count;
                const k = root.k;
                if (n <= 0)
                    return;
                ctx.fillStyle = root.ink;
                for (let r = 0; r < n; r++) {
                    let c = 0;
                    while (c < n) {
                        if (!root.modules[r * n + c]) {
                            c++;
                            continue;
                        }
                        let end = c;
                        while (end < n && root.modules[r * n + end])
                            end++;
                        ctx.fillRect((c + root.quiet) * k, (r + root.quiet) * k, (end - c) * k, k);
                        c = end;
                    }
                }
            }
        }

        // the centre image, on its own light plate
        Rectangle {
            id: logoPlate
            visible: root.logoReady
            readonly property real side: Math.round(root.cell * root.count * 0.2)
            readonly property real pad: Math.max(2, root.cell * 1.5)
            anchors.centerIn: parent
            width: side + pad * 2
            height: width
            color: root.paper
            radius: Math.min(Skin.radius, pad)
            Image {
                id: img
                anchors.centerIn: parent
                width: logoPlate.side
                height: logoPlate.side
                source: root.logo
                sourceSize.width: Math.ceil(logoPlate.side * 2)
                sourceSize.height: Math.ceil(logoPlate.side * 2)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                smooth: true
            }
        }

        // a thin accent line sweeping over a new code, once
        Rectangle {
            id: scan
            width: parent.width
            height: Math.max(2, Skin.px(2))
            y: 0
            opacity: 0
            color: Skin.accent
        }
    }

    ParallelAnimation {
        id: anim
        property bool strong: true
        NumberAnimation {
            target: plate
            property: "scale"
            from: anim.strong ? 0.8 : 0.97
            to: 1
            duration: Skin.ms(anim.strong ? 420 : 140)
            easing.type: anim.strong ? Easing.OutBack : Easing.OutQuad
        }
        NumberAnimation {
            target: plate
            property: "opacity"
            from: anim.strong ? 0 : 1
            to: 1
            duration: Skin.ms(260)
        }
    }

    SequentialAnimation {
        id: sweep
        PropertyAction { target: scan; property: "opacity"; value: 0.9 }
        NumberAnimation { target: scan; property: "y"; from: 0; to: plate.height - scan.height; duration: Skin.ms(520); easing.type: Easing.InOutQuad }
        NumberAnimation { target: scan; property: "opacity"; to: 0; duration: Skin.ms(200) }
    }

}
