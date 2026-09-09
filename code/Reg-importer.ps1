param(
    [Parameter(Position = 0)]
    [string]$ProfilePath
)

# FUNCTIONS SECTION

function DrawMenu {
    param ($menuItems, $menuPosition)
    Clear-Host
    $l = $menuItems.length

    $box = 78
    $rule = '    +' + ('-' * $box) + '+'
    function Fit-BoxLine([string]$s) {
        if ($null -eq $s) { $s = '' }
        if ($s.Length -gt $box) { return $s.Substring(0, $box - 1) + '~' }
        return $s + (' ' * ($box - $s.Length))
    }
    $left = ' REG IMPORTER'
    $right = 'profile runner'
    $gap = [Math]::Max(1, $box - $left.Length - $right.Length - 1)
    $title = $left + (' ' * $gap) + $right + ' '
    $crumb = ''
    if ($script:crumbs -and $script:crumbs.Count -gt 0) {
        $crumb = ' / ' + ($script:crumbs -join ' / ')
    }
    $metaL = ' [X] applied  [ ] not applied'
    $metaR = 'Up/Down J/K   Enter   Esc '
    $metaGap = [Math]::Max(1, $box - $metaL.Length - $metaR.Length)
    $meta = $metaL + (' ' * $metaGap) + $metaR
    Write-Host ''
    Write-Host $rule
    Write-Host ('    |' + (Fit-BoxLine $title) + '|')
    Write-Host ('    |' + (Fit-BoxLine $crumb) + '|')
    Write-Host $rule
    Write-Host ('    |' + (Fit-BoxLine $meta) + '|')
    Write-Host $rule
    Write-Host ''

    $width = [console]::WindowWidth
    if ($width -lt 20) { $width = 20 }
    $maxItem = $width - 6
    $rows = [Math]::Max(1, [console]::WindowHeight - [console]::CursorTop - 1)
    $start = 0
    if ($null -ne $menuPosition) {
        if ($menuPosition -ge ($start + $rows)) { $start = $menuPosition - $rows + 1 }
        if ($menuPosition -lt $start) { $start = $menuPosition }
    }
    $end = [Math]::Min($l, $start + $rows)
    for ($i = $start; $i -lt $end; $i++) {
        if ($menuItems[$i] -ne $null) {
            $item = [string]$menuItems[$i]
            if ($i -gt 0 -and $item.StartsWith('[?]  - Apply all')) { Write-Host '' }
            if ($item.Length -gt $maxItem) { $item = $item.Substring(0, $maxItem - 1) + '~' }
            if ($i -eq $menuPosition) {
                Write-Host "  > $($item)" -ForegroundColor Green
            }
            else {
                Write-Host "    $($item)"
            }
        }
    }
}

function Get-BakDir {
    $d = Join-Path $scriptDir 'reg_bak'
    if (!(Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
    return $d
}

function Get-BakPath {
    param ($entry)
    $n = "$($entry.description)" -replace '[\\/:*?"<>|]', '_'
    $n = $n.Trim()
    if ([string]::IsNullOrWhiteSpace($n)) { $n = 'entry' }
    return (Join-Path (Get-BakDir) ($n + '_bak.reg'))
}

function Get-Utf16Hex {
    param ([string]$s, [int]$extraNulls)
    $bytes = [Text.Encoding]::Unicode.GetBytes($s)
    if ($extraNulls -gt 0) { $bytes = $bytes + (New-Object byte[] ($extraNulls * 2)) }
    return (($bytes | ForEach-Object { $_.ToString('x2') }) -join ',')
}

function Format-RegName {
    param ([string]$name)
    return ('"' + ($name -replace '\\', '\\' -replace '"', '\"') + '"')
}

function Format-RegData {
    param ($kind, $value)
    switch ("$kind") {
        'String' { return ('"' + (("$value") -replace '\\', '\\' -replace '"', '\"') + '"') }
        'DWord' {
            $u = [BitConverter]::ToUInt32([BitConverter]::GetBytes([int32]$value), 0)
            return ('dword:' + $u.ToString('x8'))
        }
        'QWord' {
            $bytes = [BitConverter]::GetBytes([uint64]$value)
            return ('hex(b):' + (($bytes | ForEach-Object { $_.ToString('x2') }) -join ','))
        }
        'Binary' {
            $bytes = [byte[]]@()
            if ($null -ne $value) { $bytes = [byte[]]$value }
            if ($bytes.Length -eq 0) { return 'hex:' }
            return ('hex:' + (($bytes | ForEach-Object { $_.ToString('x2') }) -join ','))
        }
        'ExpandString' { return ('hex(2):' + (Get-Utf16Hex "$value" 1)) }
        'MultiString' {
            $parts = @()
            foreach ($s in @($value)) { $parts += Get-Utf16Hex "$s" 1 }
            if ($parts.Count -eq 0) { return 'hex(7):00,00' }
            return ('hex(7):' + ($parts -join ',') + ',00,00')
        }
        default { throw "Unsupported registry kind '$kind'." }
    }
}

function Write-RegBackup {
    param ($entry)
    $file = Get-BakPath $entry
    if (Test-Path $file) { return }
    $path = $entry.path
    $name = $entry.name
    $regPath = "Registry::$path"
    $lines = @('Windows Registry Editor Version 5.00', '', "[$path]")
    $exists = (Test-Path $regPath) -and ((Get-Item -Path $regPath).Property -contains $name)
    if (!$exists) {
        $lines += (Format-RegName $name) + '=-'
    } else {
        $item = Get-Item -Path $regPath
        $lines += (Format-RegName $name) + '=' + (Format-RegData "$($item.GetValueKind($name))" (Get-RegCurrent $path $name))
    }
    [IO.File]::WriteAllText($file, (($lines -join "`r`n") + "`r`n"), [Text.Encoding]::Unicode)
}

function Restore-RegEntry {
    param ($entry)
    $file = Get-BakPath $entry
    if (!(Test-Path $file)) { throw 'No backup to restore' }
    & reg.exe import $file | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Could not restore backup '$file'." }
}

function Fail-Init {
    param ($msg)
    Clear-Host
    Write-Host " "
    Write-Host "    [!]  - $msg "
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    Exit
}

function Get-RegCurrent {
    param ($path, $name)
    return (Get-Item -Path Registry::$path).GetValue($name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
}

function Get-RegWriteValue {
    param ($type, $value)
    if ("$type" -notmatch 'Binary') { return $value }
    if ($value -is [byte[]]) { return $value }
    if ($value -is [System.Array] -and -not ($value -is [string])) {
        return [byte[]]@($value | ForEach-Object { [byte]$_ })
    }
    $hex = ("$value" -replace '[\s,;:-]', '')
    if ($hex.Length -eq 0) { return [byte[]]@() }
    if ($hex -notmatch '^(?:[0-9A-Fa-f]{2})+$') {
        throw "Invalid Binary value '$value'. Use byte pairs such as 0A 0B FF."
    }
    $n = $hex.Length / 2
    $bytes = New-Object byte[] $n
    for ($i = 0; $i -lt $n; $i++) {
        $bytes[$i] = [Convert]::ToByte($hex.Substring($i * 2, 2), 16)
    }
    return $bytes
}

function Test-RegSame {
    param ($a, $b)
    if ($a -is [byte[]] -or $b -is [byte[]]) {
        $x = [byte[]]@()
        $y = [byte[]]@()
        if ($null -ne $a) { $x = [byte[]]$a }
        if ($null -ne $b) { $y = [byte[]]$b }
        if ($x.Length -ne $y.Length) { return $false }
        for ($i = 0; $i -lt $x.Length; $i++) {
            if ($x[$i] -ne $y[$i]) { return $false }
        }
        return $true
    }
    if ($a -is [System.Array] -or $b -is [System.Array]) {
        $x = @($a)
        $y = @($b)
        if ($x.Count -ne $y.Count) { return $false }
        for ($i = 0; $i -lt $x.Count; $i++) {
            if ("$($x[$i])" -ne "$($y[$i])") { return $false }
        }
        return $true
    }
    return ("$a" -eq "$b")
}

function Test-RegPresent {
    param ($entry)
    if ([string]::IsNullOrWhiteSpace($entry.path) -or [string]::IsNullOrWhiteSpace($entry.name)) { return $false }
    $regPath = "Registry::$($entry.path)"
    if (!(Test-Path $regPath)) { return $false }
    return ((Get-Item -Path $regPath).Property -contains $entry.name)
}

function Test-RegEntry {
    param ($entry)
    $path = $entry.path
    $type = $entry.type
    if ([string]::IsNullOrWhiteSpace($type)) { $type = 'String' }
    if (!(Test-RegPresent $entry)) { return $false }
    $item = Get-Item -Path Registry::$path
    if ("$($item.GetValueKind($entry.name))" -ne "$type") { return $false }
    try {
        return (Test-RegSame (Get-RegCurrent $path $entry.name) (Get-RegWriteValue $type $entry.value))
    } catch {
        return $false
    }
}

function Set-RegEntry {
    param ($entry)
    $path = $entry.path
    $regPath = "Registry::$path"
    $type = $entry.type
    if ([string]::IsNullOrWhiteSpace($type)) { $type = 'String' }
    $value = Get-RegWriteValue $type $entry.value
    if (Test-RegEntry $entry) { return }
    Write-RegBackup $entry
    $exists = Test-RegPresent $entry
    if ($exists) {
        Set-ItemProperty -Path $regPath -Name $entry.name -Type $type -Value $value
        return
    }
    if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    New-ItemProperty -Path $regPath -Name $entry.name -PropertyType $type -Value $value | Out-Null
}

function Test-RegGroup {
    param ($entry)
    return ($null -ne $entry -and $null -ne $entry.PSObject.Properties['items'])
}

function Get-RegEntries {
    param ($nodes)
    $out = New-Object System.Collections.Generic.List[object]
    foreach ($n in @($nodes)) {
        if (Test-RegGroup $n) {
            foreach ($e in (Get-RegEntries @($n.items))) { $out.Add($e) }
        } elseif ($null -ne $n) {
            $out.Add($n)
        }
    }
    return $out
}

function Menu {
    param ($menuItems)
    $menuItems = @($menuItems)
    if ($menuItems.Count -eq 0) { return $null }
    $pos = 0
    [console]::CursorVisible = $false
    try {
        while ($true) {
            DrawMenu $menuItems $pos
            $press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
            if ($press.virtualkeycode -eq 13) { return $pos }
            if ($press.virtualkeycode -eq 27) { return $null }
            if ($press.virtualkeycode -eq 38 -or $press.Character -eq 'k') {
                $pos = [Math]::Max(0, $pos - 1)
            }
            if ($press.virtualkeycode -eq 40 -or $press.Character -eq 'j') {
                $pos = [Math]::Min($menuItems.Count - 1, $pos + 1)
            }
        }
    } finally {
        [console]::CursorVisible = $true
    }
}

function Create-Menu-json {
    param ($nodes)
    $script:menuMap = New-Object System.Collections.Generic.List[object]
    $selection = New-Object System.Collections.Generic.List[string]
    $groups = New-Object System.Collections.Generic.List[object]
    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($n in @($nodes)) {
        if (Test-RegGroup $n) { $groups.Add($n) } else { $entries.Add($n) }
    }
    foreach ($g in $groups) {
        $script:menuMap.Add(@{ kind = 'group'; node = $g })
        $selection.Add("[>]  - " + $g.description)
    }
    $script:menuMap.Add(@{ kind = 'apply' })
    $selection.Add('[?]  - Apply all')
    foreach ($e in $entries) {
        $script:menuMap.Add(@{ kind = 'entry'; node = $e })
        if (Test-RegEntry $e) {
            $selection.Add("[X]  - " + $e.description)
        } else {
            $selection.Add("[ ]  - " + $e.description)
        }
    }
    return Menu $selection.ToArray()
}

# END FUNCTIONS SECTION

# INIT

$host.ui.RawUI.WindowTitle = 'github.com/SegoCode'
try { [console]::WindowWidth = 90 } catch { }
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
if ([string]::IsNullOrWhiteSpace($ProfilePath)) {
    $jsonLocation = $scriptDir + "\profile.json"
} elseif ([System.IO.Path]::IsPathRooted($ProfilePath)) {
    $jsonLocation = $ProfilePath
} else {
    $jsonLocation = Join-Path $scriptDir $ProfilePath
}
if (!(Test-Path $jsonLocation -PathType Leaf)) {
    Fail-Init 'Not found profile.json'
}

try {
    $raw = Get-Content -Raw -Path $jsonLocation
    if ([string]::IsNullOrWhiteSpace($raw)) { throw 'empty' }
    $jsonConfig = ConvertFrom-Json $raw
} catch {
    Fail-Init 'Invalid profile.json'
}
if ($null -eq $jsonConfig) {
    Fail-Init 'Invalid profile.json'
}
$jsonConfig = @($jsonConfig)
$script:navStack = New-Object System.Collections.Generic.List[object]
$script:crumbs = New-Object System.Collections.Generic.List[string]
$script:currentNodes = $jsonConfig

Get-BakDir | Out-Null

# LOOP MENU

While ($TRUE) {
    $selectionValue = Create-Menu-json $script:currentNodes
    if ($null -eq $selectionValue) {
        if ($script:navStack.Count -gt 0) {
            $i = $script:navStack.Count - 1
            $script:currentNodes = $script:navStack[$i]
            $script:navStack.RemoveAt($i)
            $script:crumbs.RemoveAt($script:crumbs.Count - 1)
            continue
        }
        Exit
    }

    $sel = $script:menuMap[$selectionValue]
    if ($sel.kind -eq 'apply') {
        Write-Host " "
        Write-Host "    [?]  - Apply all values? [Y/N] > " -NoNewline
        $option = Read-Host
        if ($option -eq 'Y' -or $option -eq 'y') {
            foreach ($entry in (Get-RegEntries $script:currentNodes)) {
                if ([string]::IsNullOrWhiteSpace($entry.path) -or [string]::IsNullOrWhiteSpace($entry.name)) { continue }
                try {
                    Set-RegEntry $entry
                } catch {
                    Write-Host "    [!]  - $($entry.description): $($_.Exception.Message)"
                    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
                }
            }
        }
    } elseif ($sel.kind -eq 'group') {
        $entry = $sel.node
        $script:navStack.Add($script:currentNodes)
        $script:crumbs.Add("$($entry.description)")
        if ($null -eq $entry.items) { $script:currentNodes = @() } else { $script:currentNodes = @($entry.items) }
    } else {
        $entry = $sel.node
        if ([string]::IsNullOrWhiteSpace($entry.path) -or [string]::IsNullOrWhiteSpace($entry.name)) {
            Write-Host " "
            Write-Host "    [!]  - Missing path or name in profile "
            $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        } else {
            try {
                if (Test-RegEntry $entry) {
                    Restore-RegEntry $entry
                } else {
                    Set-RegEntry $entry
                }
            } catch {
                Write-Host " "
                Write-Host "    [!]  - $($_.Exception.Message) "
                $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
            }
        }
    }
}

# EOF
