# Diagram fonts

[build_demo_diagram.py](../build_demo_diagram.py) measures, wraps and draws all text with these files, never with fonts
installed in the OS, so every machine produces the same PNGs.

| File | Font |
|---|---|
| `selawk.ttf` | Selawik Regular |
| `selawkb.ttf` | Selawik Bold |

Selawik 1.01 by Microsoft, an open-source fallback with the metrics of Segoe UI: text set in it wraps like the
draw.io document, which names Segoe UI (draw.io falls back to its own fonts where Segoe UI is missing).
Source: `Selawik_Release.zip` of the [1.01 release](https://github.com/microsoft/Selawik/releases/tag/1.01)
(sha256 `3f62c51e05e3b5a1e6241cf92a371f0be2ea1183aa87b30718bbd40832a8d423`), files unmodified.
Licence: SIL Open Font License 1.1, [LICENSE.txt](LICENSE.txt) (Reserved Font Name: Selawik).

sha256 of the files:

```text
e9d98518d8ac2817782a9a382430463a2e0793ea68350b695bb727d9a830ee1c  selawk.ttf
f0db5e174a90e0956ad7d2844bdca1d5e6da92ec65b2c04e57ba9b180668c904  selawkb.ttf
```
