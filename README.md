<h3 align="center"><img width="400" height="200" src="media/logo3.png"></h3>

#

<h3 align="center"><img src="media/demoJsonConsole.png"></h3>

<p align="center">
  <a href="#about">About</a> •
  <a href="#features">Features</a> •
  <a href="#quick-start--information">Quick Start & Information</a>
</p>


## About
[![Top language](https://img.shields.io/github/languages/top/SegoCode/RegImporter?style=flat-square)](https://github.com/SegoCode/RegImporter)
[![Repository size](https://img.shields.io/github/repo-size/SegoCode/RegImporter?style=flat-square&label=repo%20size)](https://github.com/SegoCode/RegImporter)
[![Commit activity per year](https://img.shields.io/github/commit-activity/y/SegoCode/RegImporter?style=flat-square&label=commits)](https://github.com/SegoCode/RegImporter/graphs/commit-activity)
[![Licencia: PolyForm Noncommercial + GNU AGPL-3.0](https://img.shields.io/badge/License-PolyForm%20Noncommercial%20%2B%20GNU%20AGPL--3.0-blue?style=flat-square)](https://github.com/SegoCode/RegImporter/blob/main/LICENSE)
[![Bitcoin BTC](https://img.shields.io/badge/buy_me_a_coffee-BTC-F7931A?style=flat-square&logo=bitcoin&logoColor=white)](https://github.com/SegoCode/SegoCode/discussions/2)


Interactive PowerShell console that imports Windows registry values from JSON profiles. Pick rows in a menu, apply a whole profile or a category, and restore the previous value from a backup.

## Features

- Keyboard console menu to apply or restore keys
- Nested JSON profiles (categories)
- Creates missing values and backs up the previous state
- String, ExpandString, Binary, DWord, MultiString, QWord


## Quick Start & Information

Run from GitHub (no install):

```shell
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/SegoCode/RegImporter/main/code/regImporter.ps1 | iex"
```

Or from a clone, in `code/`:

```shell
cd code
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\regImporter.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\regImporter.ps1 profiles\privacy_profile.json
```

Up/Down or J/K, Enter, Esc.

> [!NOTE]  
> HKLM rows need admin. HKCU does not. Use a visible console (ReadKey).

> [!TIP]
> Add new profiles under `code/profiles/` and open a pull request.

### Available Parameters

Position 0: profile path relative to the script, or absolute. Omitted loads `profile.json` next to the script, or the repo `privacy_profile.json` when run via `irm | iex`.

```shell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\regImporter.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\regImporter.ps1 profiles\privacy_profile.json
```

`profile.json` is a JSON array of keys and optional categories (`items`):

```json
[
  {
    "description": "Privacy",
    "items": [
      {
        "description": "Disable telemetry",
        "path": "HKEY_CURRENT_USER\\Software\\Example",
        "name": "AllowTelemetry",
        "type": "DWord",
        "value": "0"
      }
    ]
  },
  {
    "description": "A loose key",
    "path": "HKEY_CURRENT_USER\\Software\\Example",
    "name": "X",
    "type": "String",
    "value": "hello"
  }
]
```

| `type` | `value` |
|---|---|
| `String` | `"hello"` |
| `ExpandString` | `"%TEMP%\\x"` (stored unexpanded) |
| `Binary` | `"0A 0B FF"` or `[10,11,255]` |
| `DWord` | `"42"` |
| `MultiString` | `["one","two"]` |
| `QWord` | `"99"` |


---
<p align="center"><a href="https://github.com/SegoCode/RegImporter/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=SegoCode/RegImporter" />
</a></p>
