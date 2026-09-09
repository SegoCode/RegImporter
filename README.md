<h3 align="center"><img width="400" height="200" src="media/logo3.png"></h3>

#

<h3 align="center"><img src="media/demoJsonConsole.png"></h3>

<p align="center">
  <a href="#about">About</a> •
  <a href="#features">Features</a> •
  <a href="#quick-start--information">Quick Start & Information</a> •
  <a href="#download">Download</a> 
</p>

## About
[![Top language](https://img.shields.io/github/languages/top/SegoCode/RegImporter?style=flat-square)](https://github.com/SegoCode/RegImporter)
[![Repository size](https://img.shields.io/github/repo-size/SegoCode/RegImporter?style=flat-square&label=repo%20size)](https://github.com/SegoCode/RegImporter)
[![Commit activity per year](https://img.shields.io/github/commit-activity/y/SegoCode/RegImporter?style=flat-square&label=commits)](https://github.com/SegoCode/RegImporter/graphs/commit-activity)
[![Licencia: PolyForm Noncommercial + GNU AGPL-3.0](https://img.shields.io/badge/License-PolyForm%20Noncommercial%20%2B%20GNU%20AGPL--3.0-blue?style=flat-square)](https://github.com/SegoCode/RegImporter/blob/main/LICENSE)
[![Bitcoin BTC](https://img.shields.io/badge/buy_me_a_coffee-BTC-F7931A?style=flat-square&logo=bitcoin&logoColor=white)](https://github.com/SegoCode/SegoCode/discussions/2)


Interactive PowerShell console that imports Windows registry values from JSON profiles. Pick rows in a menu, apply a whole profile or a category, and restore the previous value from a backup.

## Features

- Menu: categories (`[>]`) first, then Apply all and keys (`[X]` applied, `[ ]` not). Missing keys are created on apply, same as a wrong value.

- Categories: a JSON object with `items` is a folder. Enter opens it. Apply all applies only the current subtree, not siblings. Esc goes back (quit at root).

- Backup and restore: the first change writes `reg_bak\<description>_bak.reg` next to the script. Enter on `[X]` restores that backup. If the value did not exist, restore deletes it. Later applies do not overwrite the first backup.

- Types: `String`, `ExpandString` (stored unexpanded), `Binary` (`"0A 0B FF"` or `[10,11,255]`), `DWord`, `MultiString`, `QWord`.

## Quick Start & Information

The script lives in `code/`. Copy a file from `code/profiles/` next to it as `profile.json`, or pass a path relative to the script.

```shell
cd code
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Reg-importer.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Reg-importer.ps1 profiles\privacy_profile.json
```

Up/Down or J/K, Enter, Esc.

> [!NOTE]  
> HKLM rows need admin. HKCU does not.

> [!TIP]
> Add new profiles under `code/profiles/` and open a pull request.

### Available Parameters

Default `profile.json` next to the script:
```shell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Reg-importer.ps1
```

Path relative to the script directory:
```shell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Reg-importer.ps1 profiles\privacy_profile.json
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

## Download

https://github.com/SegoCode/RegImporter

---
<p align="center"><a href="https://github.com/SegoCode/RegImporter/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=SegoCode/RegImporter" />
</a></p>
