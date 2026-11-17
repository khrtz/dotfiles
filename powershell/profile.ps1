# ~/dotfiles/powershell/profile.ps1  (PowerShell 7)
# Catppuccin Mocha / PlemolJP Console NF

# --- encoding (Japanese / box drawing / emoji) --------------------------------
[Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$Dotfiles = Split-Path $PSScriptRoot -Parent
$env:STARSHIP_CONFIG = Join-Path $Dotfiles 'starship\starship.toml'
$env:BAT_THEME = 'Catppuccin Mocha'
$env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --exclude .git'
$env:FZF_DEFAULT_OPTS = @(
    '--height=45% --layout=reverse --border=rounded --info=inline --prompt="❯ " --pointer="▶" --marker="✓"'
    '--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8'
    '--color=info:#cba6f7,pointer:#f5e0dc,marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8'
    '--color=selected-bg:#45475a,border:#6c7086,label:#cdd6f4'
) -join ' '

# --- cached init scripts (keeps startup fast) ---------------------------------
$InitCache = Join-Path $HOME '.cache\pwsh'
if (-not (Test-Path $InitCache)) { New-Item -ItemType Directory -Path $InitCache -Force | Out-Null }

function Import-CachedInit {
    param([string]$Name, [string]$Exe, [scriptblock]$Generate)
    $cmd = Get-Command $Exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $cmd) { return }
    $file = Join-Path $InitCache "$Name.ps1"
    if (-not (Test-Path $file) -or (Get-Item $cmd.Source).LastWriteTime -gt (Get-Item $file).LastWriteTime) {
        & $Generate | Out-String | Set-Content -Path $file -Encoding utf8
    }
    . $file
}

# --- node (fnm) ---------------------------------------------------------------
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
}

# --- PSReadLine (before starship: it reads PredictionViewStyle at init) --------
if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsOutputRedirected) {
    function _rgb([string]$h) { $h = $h.TrimStart('#'); "`e[38;2;$([Convert]::ToInt32($h.Substring(0,2),16));$([Convert]::ToInt32($h.Substring(2,2),16));$([Convert]::ToInt32($h.Substring(4,2),16))m" }
    Set-PSReadLineOption -EditMode Windows -BellStyle None `
        -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView `
        -HistoryNoDuplicates -HistorySearchCursorMovesToEnd -MaximumHistoryCount 20000 `
        -Colors @{
            Default                = _rgb 'cdd6f4'
            Command                = _rgb '89b4fa'
            Parameter              = _rgb '94e2d5'
            String                 = _rgb 'a6e3a1'
            Operator               = _rgb '89dceb'
            Variable               = _rgb 'f5e0dc'
            Number                 = _rgb 'fab387'
            Type                   = _rgb 'f9e2af'
            Member                 = _rgb 'b4befe'
            Keyword                = _rgb 'cba6f7'
            Comment                = _rgb '6c7086'
            Error                  = _rgb 'f38ba8'
            Emphasis               = _rgb 'f38ba8'
            InlinePrediction       = _rgb '6c7086'
            ListPrediction         = _rgb 'cba6f7'
            ListPredictionSelected = "`e[48;2;49;50;68m"
            Selection              = "`e[48;2;69;71;90m"
        }

    Set-PSReadLineKeyHandler -Chord Shift+Enter -Function AddLine
    Set-PSReadLineKeyHandler -Chord Tab         -Function MenuComplete
    Set-PSReadLineKeyHandler -Chord UpArrow     -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Chord DownArrow   -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Chord Ctrl+w      -Function BackwardKillWord
    Set-PSReadLineKeyHandler -Chord F2          -Function SwitchPredictionView

    # fzf: loaded on first use only
    Set-PSReadLineKeyHandler -Chord Ctrl+r -BriefDescription 'fzf history' -ScriptBlock {
        Import-Module PSFzf -ErrorAction SilentlyContinue; Invoke-FzfPsReadlineHandlerHistory }
    Set-PSReadLineKeyHandler -Chord Ctrl+t -BriefDescription 'fzf files' -ScriptBlock {
        Import-Module PSFzf -ErrorAction SilentlyContinue; Invoke-FzfPsReadlineHandlerProvider }
}

# --- prompt + jump ------------------------------------------------------------
# starship's init spawns starship.exe once for the continuation prompt; bake it in.
Import-CachedInit starship starship {
    $init = starship init powershell --print-full-init | Out-String
    $cont = (starship prompt --continuation | Out-String).TrimEnd("`r", "`n").Replace("'", "''")
    [regex]::Replace($init, "(?s)Set-PSReadLineOption -ContinuationPrompt \(\s*Invoke-Native.*?\)\s*\)", "Set-PSReadLineOption -ContinuationPrompt '$cont'")
}
Import-CachedInit zoxide zoxide { zoxide init powershell }

# --- listing / viewing --------------------------------------------------------
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
function ls { eza --icons=auto --group-directories-first @args }
function ll { eza -l --icons=auto --group-directories-first --git --time-style=relative @args }
function la { eza -la --icons=auto --group-directories-first --git --time-style=relative @args }
function lt { eza --tree --level=2 --icons=auto --git-ignore @args }
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function which($name) { (Get-Command $name -ErrorAction SilentlyContinue).Source }

# --- AI (Claude / Codex) -----------------------------------------------------
# ai          -> new tab: Claude (left) + shell (right) in the current folder
# ai codex    -> same with Codex
function ai {
    param([ValidateSet('claude', 'codex')][string]$Tool = 'claude')
    $profileName = if ($Tool -eq 'codex') { 'Codex' } else { 'Claude' }
    $dir = $PWD.ProviderPath
    wt -w 0 new-tab -p $profileName -d "$dir" `; split-pane -V -s 0.4 -p 'PowerShell' -d "$dir"
}
function cc { claude @args }
function cx { codex @args }
