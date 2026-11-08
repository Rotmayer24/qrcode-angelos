import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets
import "QrCode.js" as QrCode
import "."

// The generator: text or a link, an optional image for the centre, a live QR code.
// Everything is computed here in QML/JS (QrCode.js); no processes, no network, nothing is saved.
Column {
    id: root

    property var plugin
    property alias queryText: textField.text
    property alias imageText: imageField.text
    readonly property alias view: view

    // the image field starts with the plugin's default image until the user touches it
    readonly property string defaultImage: plugin ? plugin.get("defaultImage", "") : ""
    // the text field starts with the plugin's default text (the stored one or a plain example
    // url), so a code is on screen the moment the popup opens (issue with the empty panel)
    readonly property string defaultText: plugin ? String(plugin.get("defaultText", "https://example.com") || "https://example.com") : "https://example.com"
    // the default text is remembered like v1 did: saved after every successful generation,
    // skipped while it is unchanged
    property string savedText: plugin ? String(plugin.get("defaultText", "")) : ""
    property bool imageTouched: false
    onDefaultImageChanged: if (!imageTouched && imageField.text !== defaultImage)
        imageField.text = defaultImage

    property var code: ({
            "ok": false,
            "size": 0,
            "modules": [],
            "error": ""
        })
    property string failure: ""
    property bool shown: false
    readonly property string imagePath: cleanPath(imageField.text)
    readonly property string level: imagePath !== "" ? "H" : "M"
    readonly property string warning: imagePath !== "" && view.logoStatus === Image.Error ? I18n.t("Не удалось открыть картинку — QR без неё", "Cannot open the image; showing the code without it") : ""

    spacing: Skin.px(8)

    // "~/a.png", file:// URLs and quoted paths pasted from a file manager
    function cleanPath(raw) {
        let p = String(raw).trim();
        if (p.length > 1 && (p[0] === "\"" || p[0] === "'") && p[p.length - 1] === p[0])
            p = p.slice(1, -1);
        if (p.indexOf("file://") === 0) {
            try {
                p = decodeURIComponent(p.slice(7));
            } catch (e) {
                p = p.slice(7);
            }
        }
        if (p === "~" || p.indexOf("~/") === 0)
            p = (Quickshell.env("HOME") || "") + p.slice(1);
        return p;
    }
    function fileUrl(path) {
        return path === "" ? "" : "file://" + path.split("/").map(encodeURIComponent).join("/");
    }

    function refresh() {
        const t = textField.text;
        if (t.length === 0) {
            code = {
                "ok": false,
                "size": 0,
                "modules": [],
                "error": ""
            };
            failure = "";
            shown = false;
            return;
        }
        const r = QrCode.encode(t, level, imagePath !== "" ? 5 : 1);
        if (!r.ok) {
            const max = imagePath !== "" ? 1273 : 2331;
            failure = /overflow/i.test(r.error) ? I18n.t("Слишком длинный текст: " + QrCode.byteLength(t) + " байт, максимум " + max, "Text too long: " + QrCode.byteLength(t) + " bytes, the maximum is " + max) + (imagePath === "" ? "" : I18n.t(" (без картинки больше)", " (more without an image)")) : r.error;
            code = r;
            shown = false;
            return;
        }
        failure = "";
        const first = !shown;
        shown = true;
        code = r;
        view.reveal(first);
        if (plugin && t !== savedText) {
            savedText = t;
            plugin.set("defaultText", t);
        }
    }

    // the field takes the keyboard focus as soon as the window shows (and the text sits
    // selected, so the first keystroke replaces it)
    function queryFocus() {
        try {
            textField.focusField();
            textField.input.selectAll();
        } catch (e) {
            try {
                textField.forceActiveFocus();
            } catch (e2) {}
        }
    }

    Component.onCompleted: {
        // built before the field exists yet is fine; the text stands ready when shown
        if (textField.text === "" && defaultText !== "")
            textField.text = defaultText;
    }

    Timer {
        id: debounce
        interval: 180
        onTriggered: root.refresh()
    }
    Connections {
        target: textField.input
        function onTextChanged() {
            debounce.restart();
        }
    }
    Connections {
        target: imageField.input
        function onTextChanged() {
            debounce.restart();
        }
        function onTextEdited() {
            root.imageTouched = true;
        }
    }

    PxField {
        id: textField
        width: parent.width
        placeholder: I18n.t("Текст или ссылка", "Text or link")
        keepFocus: true
        onAccepted: {
            debounce.stop();
            root.refresh();
        }
    }

    Row {
        width: parent.width
        spacing: Skin.px(6)
        PxField {
            id: imageField
            width: parent.width - logoButton.width - parent.spacing
            placeholder: I18n.t("Картинка в центре (путь, необязательно)", "Centre image (path, optional)")
            keepFocus: true
        }
        PxButton {
            id: logoButton
            anchors.verticalCenter: parent.verticalCenter
            compact: true
            icon: imageField.text.length > 0 ? "close" : "image"
            text: imageField.text.length > 0 ? I18n.t("Убрать", "Clear") : I18n.t("Лого", "Logo")
            onClicked: {
                root.imageTouched = true;
                imageField.text = imageField.text.length > 0 ? "" : (root.plugin ? root.plugin.dir + "/assets/logo.png" : "");
            }
        }
    }

    SkinCard {
        id: card
        sunken: true
        width: parent.width
        readonly property real side: Math.max(Skin.px(120), Math.min(width - padding * 2, Skin.px(232)))
        height: side + padding * 2

        QrView {
            id: view
            anchors.centerIn: parent
            width: card.side
            height: card.side
            visible: root.code.ok
            modules: root.code.modules
            count: root.code.size
            logo: root.fileUrl(root.imagePath)
        }

        // nothing to show yet: a quiet placeholder in the look in use
        Column {
            anchors.centerIn: parent
            visible: !root.code.ok
            spacing: Skin.px(6)
            PxIcon {
                visible: !Skin.mac
                anchors.horizontalCenter: parent.horizontalCenter
                name: "grid"
                pixel: Theme.u * 6
            }
            Loader {
                active: Skin.mac
                anchors.horizontalCenter: parent.horizontalCenter
                sourceComponent: MacIcon {
                    name: "scan"
                    size: Skin.px(56)
                    stroke: 1.5
                    color: Skin.textFaint
                }
            }
        }
    }

    PxText {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        kind: "tiny"
        dim: root.failure === "" && root.warning === ""
        color: root.failure !== "" ? Skin.danger : root.warning !== "" ? Skin.warn : Skin.textDim
        text: root.failure !== "" ? root.failure : root.warning !== "" ? root.warning : root.code.ok ? root.code.size + "×" + root.code.size + " · " + root.level + " · " + QrCode.byteLength(textField.text) + " " + I18n.t("байт", "bytes") : I18n.t("Введите текст — код появится сразу", "Type something — the code appears instantly")
    }
}
