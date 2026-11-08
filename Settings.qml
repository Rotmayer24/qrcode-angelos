import QtQuick
import qs.config
import qs.services
import qs.widgets
import "."

// Page in Настройки → Плагины → QR Code.
Column {
    id: root
    property var plugin
    width: parent ? parent.width : 400
    spacing: Skin.px(10)

    PxGroup {
        title: I18n.t("QR-код", "QR Code")
        icon: "grid"
        width: parent.width

        Panel {
            width: parent.width
            plugin: root.plugin
        }
        SettingRow {
            label: I18n.t("Текст по умолчанию", "Default text")

            PxField {
                width: parent.width
                placeholder: "https://example.com"
                text: root.plugin ? String(root.plugin.get("defaultText", "https://example.com") || "https://example.com") : "https://example.com"
                onEditingFinished: if (root.plugin)
                    root.plugin.set("defaultText", text.trim() || "https://example.com")
            }

        }
        SettingRow {
            label: I18n.t("Картинка по умолчанию", "Default centre image")
            PxField {
                width: parent.width
                placeholder: I18n.t("Путь к файлу, пусто — без картинки", "File path, empty for none")
                text: root.plugin ? root.plugin.get("defaultImage", "") : ""
                onEdited: if (root.plugin)
                    root.plugin.set("defaultImage", text)
            }
        }
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            kind: "tiny"
            dim: true
            text: I18n.t("Код строится прямо в оболочке: ничего не сохраняется и не отправляется. С картинкой в центре уровень коррекции H (до 1273 байт), без неё M (до 2331).", "The code is built inside the shell: nothing is saved or sent. With a centre image the error correction is H (up to 1273 bytes), without one M (up to 2331).")
        }
    }
}
