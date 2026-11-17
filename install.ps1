# Re-apply dotfiles on this PC:  pwsh -File ~/dotfiles/install.ps1
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# 1. PowerShell 7 profile -> stub that loads the dotfiles profile
$docs = [Environment]::GetFolderPath('MyDocuments')
$ps7 = Join-Path $docs 'PowerShell\Microsoft.PowerShell_profile.ps1'
New-Item -ItemType Directory -Force (Split-Path $ps7) | Out-Null
if (Test-Path $ps7) { Copy-Item $ps7 "$ps7.bak-$stamp" }
$main = Join-Path $root 'powershell\profile.ps1'
Set-Content -Path $ps7 -Encoding utf8 -Value ". '$($main.Replace("'", "''"))'"
"profile  -> $ps7"

# 2. Windows Terminal settings
$wt = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'
New-Item -ItemType Directory -Force $wt | Out-Null
$wtSettings = Join-Path $wt 'settings.json'
if (Test-Path $wtSettings) { Copy-Item $wtSettings "$wtSettings.bak-$stamp" }
Copy-Item (Join-Path $root 'windows-terminal\settings.json') $wtSettings -Force
"terminal -> $wtSettings"

# 3. git: delta as pager
git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true
git config --global delta.line-numbers true
git config --global delta.syntax-theme 'Catppuccin Mocha'
git config --global merge.conflictStyle zdiff3
"git      -> delta"

# 4. Claude Code: ring the terminal bell when a reply finishes (merge, keep other keys)
$claude = Join-Path $HOME '.claude\settings.json'
New-Item -ItemType Directory -Force (Split-Path $claude) | Out-Null
$cfg = if (Test-Path $claude) { Get-Content $claude -Raw | ConvertFrom-Json -AsHashtable } else { @{} }
if ($cfg['preferredNotifChannel'] -ne 'terminal_bell') {
    if (Test-Path $claude) { Copy-Item $claude "$claude.bak-$stamp" }
    $cfg['preferredNotifChannel'] = 'terminal_bell'
    $cfg | ConvertTo-Json -Depth 20 | Set-Content $claude -Encoding utf8NoBOM
}
"claude   -> terminal bell"

# 5. clear cached init scripts so they regenerate
Remove-Item (Join-Path $HOME '.cache\pwsh\*.ps1') -ErrorAction SilentlyContinue
'done'
