# QR Code — angelOS plugin

**EN.** A panel button opens the QR panel in a mini window under the button — a layer-shell
window of its own, like the shell's other mini windows: not a desktop window, so it does not
look like a terminal, and while it is open it owns the keyboard (typed text always reaches the
field; a click outside, Esc or the frame's close button dismisses it). It opens with a live QR
code for the stored default text (a plain `https://example.com` the first time); type text or a
link and the code rebuilds instantly; optionally put an image in its centre. Everything is
computed inside the shell (QML/JS, `QrCode.js`): no processes, no network, no Python. The text
is kept only across openings of the panel (as the default for the next time); nothing is sent
anywhere.

**RU.** Кнопка на панели открывает QR-панель в мини-окне под кнопкой — собственное layer-shell
окно, как другие мини-окна оболочки: это не отдельное окно рабочего стола (не похоже на
терминал) и, пока открыто, оно владеет клавиатурой (ввод всегда попадает в поле; клик рядом,
Esc или кнопка закрытия рамки закрывают его). Оно сразу открывается с живым QR-кодом для
сохранённого текста по умолчанию (в первый раз — обычный `https://example.com`); введите текст
или ссылку — код перестроится сразу; в центр можно поставить картинку. Работает в обеих темах
(пиксель и macOS). Всё считается внутри оболочки (QML/JS, `QrCode.js`): без процессов, сети и
Python. Текст запоминается только как значение по умолчанию к следующему открытию, ничего
никуда не отправляется.

## Use / Использование
- Click the grid icon (pixel) or the scan icon (macOS menu bar). / Нажмите значок на панели.
- Type text or a link (the mini window takes the keyboard itself; Esc closes it). / Введите текст
  или ссылку (мини-окно получает клавиатуру само; Esc закрывает).
- Image in the centre: paste a file path (`/home/me/pic.png`, `~/pic.png`, `file://…`), or press
  **Logo** for the bundled one. **Clear** removes it. / Картинка: путь к файлу или кнопка **Лого**.
- With an image the error correction is **H** (up to 1273 bytes), without it **M** (up to 2331).
  Always scan a code with an image before relying on it. / Код с картинкой стоит проверить сканером.
- From a terminal: `qs ipc call qrcode open`. / Из терминала можно открыть командой.

## Dependencies / Зависимости

**EN.** The plugin itself has **no additional dependencies** — everything (the QR encoder,
`QrCode.js`) is inside the shell as QML/JS: no processes, no network, no extra packages, no
Python. What it needs is the environment it was made for: the **AngelOS shell** (Quickshell on
niri). On a clean Arch with AngelOS not yet installed, only the system parts it runs on are:

```bash
sudo pacman -S --needed quickshell niri
```

(`quickshell` is Quickshell 0.3+ from the repos, `niri` is the scrollable-tiling Wayland
compositor; AngelOS itself is installed from the AngelOS-Dotfiles project and the plugin is
then dropped into `~/.config/angelos/plugins/`.) Nothing else to install: the plugin ships its
own MIT-licensed encoder and no scripts.

**RU.** Сам плагин **не требует дополнительных зависимостей** — весь генератор QR («QrCode.js»)
считается внутри оболочки на QML/JS: без процессов, сети и Python. Нужна лишь среда, для которой
он сделан: **оболочка AngelOS** (Quickshell на niri). На чистой Arch, где AngelOS ещё не стоит,
ставятся только системные части, на которых всё работает:

```bash
sudo pacman -S --needed quickshell niri
```

(`quickshell` — Quickshell 0.3+ из репозиториев, `niri` — тайловый Wayland-композитор; сама
AngelOS ставится из проекта AngelOS-Dotfiles, затем плагин кладётся в
`~/.config/angelos/plugins/`.) Больше ничего ставить не нужно: энкодер и все скрипты в комплекте.

## Settings / Настройки
Settings → Plugins → QR Code: a copy of the generator, **Default text** (what the field starts
with, saved from the window too) and **Default centre image** (a file path used when the image
field is untouched). /
Настройки → Плагины → QR Code: копия генератора, «Текст по умолчанию» (с него начинается поле,
запоминается и из окна) и «Картинка по умолчанию».

## Files
`manifest.json`, `BarWidget.qml` (button + the mini layer window it opens), `Panel.qml`
(UI and logic), `QrView.qml` (the code on a Canvas), `Settings.qml`, `QrCode.js`
(encoder), `assets/logo.png`.

## Install / Uninstall
Copy the folder to `~/.config/angelos/plugins/qrcode/` (the shell reloads by itself), or install
the ZIP from Community Store. Uninstall: delete the folder. No dependencies, no permissions.

## Third-party
`QrCode.js` embeds qrcode-generator 1.4.4 (MIT, © Kazuhiko Arase). See `THIRD-PARTY.md`.
"QR Code" is a registered trademark of DENSO WAVE INCORPORATED.
