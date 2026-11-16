param(
    [string]$ApiKey,
    [switch]$TestMode
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

$BASE  = 'https://api.deepseek.com/anthropic'
$MODEL = 'deepseek-flash'
$TOKEN_PLACEHOLDER = 'sk-REPLACE_WITH_YOUR_OWN_KEYXXXXXXX'

function Stop-Setup([string]$msg) {
    Write-Host ""
    Write-Host "  [失败] $msg" -ForegroundColor Red
    Write-Host ""
    if (-not $TestMode) { Read-Host "  按回车关闭窗口" }
    exit 1
}

function New-DesktopShortcut([string]$name, [string]$target, [string]$workdir) {
    if ($TestMode) { return }
    try {
        $desktop = [Environment]::GetFolderPath('Desktop')
        $wsh = New-Object -ComObject WScript.Shell
        $lnk = $wsh.CreateShortcut((Join-Path $desktop $name))
        $lnk.TargetPath = $target
        $lnk.WorkingDirectory = $workdir
        $lnk.Save()
    } catch {}
}

function Set-DbToken([string]$path, [string]$oldToken, [string]$newToken) {
    if ($oldToken.Length -ne $newToken.Length) { return $false }
    $bytes = [IO.File]::ReadAllBytes($path)
    $text  = [Text.Encoding]::ASCII.GetString($bytes)
    $pos   = $text.IndexOf($oldToken)
    if ($pos -lt 0) { return $false }
    $newB = [Text.Encoding]::ASCII.GetBytes($newToken)
    [Array]::Copy($newB, 0, $bytes, $pos, $newB.Length)
    [IO.File]::WriteAllBytes($path, $bytes)
    return $true
}

Clear-Host
Write-Host ""
Write-Host "  ===================================" -ForegroundColor Cyan
Write-Host "         Claude Code 一键安装" -ForegroundColor Cyan
Write-Host "  ===================================" -ForegroundColor Cyan
Write-Host ""

# [1/4] Claude Code
Write-Host "  [1/4] 安装 Claude Code ..." -ForegroundColor Yellow

$destDir = Join-Path $env:USERPROFILE '.local\bin'
$destExe = Join-Path $destDir 'claude.exe'
$bundle  = Join-Path $PSScriptRoot 'claude.exe'
$claudePath = $null

if (Test-Path $destExe) {
    $claudePath = $destExe
} elseif (Test-Path $bundle) {
    Write-Host "        正在复制，约需 10 秒，请勿关闭窗口..." -ForegroundColor Gray
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    Copy-Item -LiteralPath $bundle -Destination $destExe -Force
    $claudePath = $destExe
} else {
    $cmd = Get-Command claude -ErrorAction SilentlyContinue
    if ($cmd) {
        $claudePath = $cmd.Source
    } else {
        Write-Host "        正在从官方下载（1-3 分钟）..." -ForegroundColor Gray
        try { irm https://claude.ai/install.ps1 | iex } catch {
            Stop-Setup "下载失败。请检查网络后重新运行。错误：$($_.Exception.Message)"
        }
        $env:Path = "$destDir;$env:Path"
        $cmd = Get-Command claude -ErrorAction SilentlyContinue
        if ($cmd) { $claudePath = $cmd.Source }
        if (-not $claudePath -and (Test-Path $destExe)) { $claudePath = $destExe }
    }
}

if (-not $claudePath -or -not (Test-Path $claudePath)) {
    Stop-Setup "Claude Code 安装失败，请把此窗口截图发给男朋友。"
}
Write-Host "        已就绪" -ForegroundColor Green

if (-not $TestMode) {
    try {
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        $hasDir = $false
        foreach ($p in ($userPath -split ';')) {
            if ($p.TrimEnd('\') -ieq $destDir.TrimEnd('\')) { $hasDir = $true }
        }
        if (-not $hasDir) {
            $newPath = if ([string]::IsNullOrEmpty($userPath)) { $destDir } else { $userPath.TrimEnd(';') + ';' + $destDir }
            [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        }
    } catch {}
}

# [2/4] API Key
Write-Host ""
Write-Host "  [2/4] 输入你的 DeepSeek API Key" -ForegroundColor Yellow
Write-Host "        获取地址：https://platform.deepseek.com/api_keys" -ForegroundColor Gray
Write-Host "        复制以 sk- 开头的 Key，在此处右键粘贴，然后回车：" -ForegroundColor Gray
Write-Host ""

if ($ApiKey) {
    $key = $ApiKey.Trim()
} else {
    try {
        $secure = Read-Host -Prompt "  Key" -AsSecureString
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try { $key = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    } catch {
        $key = Read-Host -Prompt "  Key"
    }
    $key = "$key".Trim()
}

if (-not $key.StartsWith('sk-') -or $key.Length -lt 20) {
    Stop-Setup "Key 格式不对，应该是以 sk- 开头的一长串。请重新运行本程序。"
}

# [3/4] Claude Code 配置
Write-Host ""
Write-Host "  [3/4] 写入配置 ..." -ForegroundColor Yellow

$claudeDir = Join-Path $env:USERPROFILE '.claude'
New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
$settingsPath = Join-Path $claudeDir 'settings.json'

$settings = $null
if (Test-Path $settingsPath) {
    try { $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $settings = $null }
}
if ($null -eq $settings) { $settings = New-Object PSObject }

if (-not ($settings.PSObject.Properties.Name -contains 'env')) {
    $settings | Add-Member -NotePropertyName 'env' -NotePropertyValue (New-Object PSObject)
}

$values = [ordered]@{
    ANTHROPIC_BASE_URL             = $BASE
    ANTHROPIC_AUTH_TOKEN           = $key
    ANTHROPIC_MODEL                = $MODEL
    ANTHROPIC_DEFAULT_SONNET_MODEL = $MODEL
    ANTHROPIC_DEFAULT_OPUS_MODEL   = $MODEL
    ANTHROPIC_DEFAULT_HAIKU_MODEL  = $MODEL
}
foreach ($k in $values.Keys) {
    if ($settings.env.PSObject.Properties.Name -contains $k) {
        $settings.env.$k = $values[$k]
    } else {
        $settings.env | Add-Member -NotePropertyName $k -NotePropertyValue $values[$k]
    }
}
if (-not ($settings.PSObject.Properties.Name -contains 'includeCoAuthoredBy')) {
    $settings | Add-Member -NotePropertyName 'includeCoAuthoredBy' -NotePropertyValue $false
}
if (-not ($settings.PSObject.Properties.Name -contains 'model')) {
    $settings | Add-Member -NotePropertyName 'model' -NotePropertyValue 'haiku'
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json -Depth 10), $utf8NoBom)

$claudeJson = Join-Path $env:USERPROFILE '.claude.json'
if (-not (Test-Path $claudeJson)) {
    [IO.File]::WriteAllText($claudeJson, '{"hasCompletedOnboarding":true,"installMethod":"native"}', $utf8NoBom)
}
Write-Host "        已写入 ~/.claude/settings.json" -ForegroundColor Green

# [4/4] CC Switch
Write-Host ""
Write-Host "  [4/4] 安装 CC Switch ..." -ForegroundColor Yellow

$ccDir   = Join-Path $env:LOCALAPPDATA 'Programs\CC Switch'
$ccExe   = Join-Path $ccDir 'cc-switch.exe'
$ccBundle = Join-Path $PSScriptRoot 'cc-switch.exe'

try {
    if ((Test-Path $ccBundle) -and -not (Test-Path $ccExe)) {
        New-Item -ItemType Directory -Force -Path $ccDir | Out-Null
        Copy-Item -LiteralPath $ccBundle -Destination $ccExe -Force
    }
} catch {}

if (Test-Path $ccExe) {
    $seedDir = Join-Path $PSScriptRoot 'seed'
    $cfgDir  = Join-Path $env:USERPROFILE '.cc-switch'
    $seeded  = $false
    $tokenOk = $false

    if ((Test-Path $seedDir) -and -not (Test-Path $cfgDir)) {
        try {
            New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
            Copy-Item (Join-Path $seedDir 'cc-switch.db') (Join-Path $cfgDir 'cc-switch.db') -Force
            Copy-Item (Join-Path $seedDir 'settings.json') (Join-Path $cfgDir 'settings.json') -Force
            $tokenOk = Set-DbToken (Join-Path $cfgDir 'cc-switch.db') $TOKEN_PLACEHOLDER $key
            $seeded = $true
        } catch { $seeded = $false }
    }

    if ($seeded -and -not $tokenOk) {
        Remove-Item (Join-Path $cfgDir 'cc-switch.db') -Force -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $cfgDir 'settings.json') -Force -ErrorAction SilentlyContinue
        Write-Host "        CC Switch 已安装；Key 需在界面里手动填一次。" -ForegroundColor Yellow
    } elseif ($seeded) {
        Write-Host "        已安装，并预置好 DeepSeek 供应商" -ForegroundColor Green
    } else {
        Write-Host "        已安装（已有配置，未覆盖）" -ForegroundColor Green
    }

    New-DesktopShortcut 'CC Switch.lnk' $ccExe $ccDir
} else {
    Write-Host "        CC Switch 安装包缺失，已跳过" -ForegroundColor Yellow
}

if ($claudePath -like '*.exe') {
    New-DesktopShortcut 'Claude.lnk' $claudePath $env:USERPROFILE
}

Write-Host ""
Write-Host "  全部完成！" -ForegroundColor Green
Write-Host ""
Write-Host "  桌面上会有两个图标："
Write-Host "    Claude     - 日常使用（双击直接对话）" -ForegroundColor White
Write-Host "    CC Switch  - 换 Key / 换供应商（可视化）" -ForegroundColor White
Write-Host ""
Write-Host "  第一次启动 Claude 如果问是否信任文件夹，选 Yes 即可。" -ForegroundColor Gray
Write-Host "  想换 Key：运行 CC Switch，点 DeepSeek → 编辑 → 填新 Key → 启用。" -ForegroundColor Gray
Write-Host ""
if (-not $TestMode) { Read-Host "  按回车关闭窗口" }
