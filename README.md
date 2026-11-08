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


