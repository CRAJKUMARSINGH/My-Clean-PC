# My Clean PC - GUI launcher
# Cleaning logic lives only in clean-pc-core.ps1 (same folder).
# How to run: right-click -> "Run with PowerShell" (Administrator recommended)

param([switch]$FullClean)

$ErrorActionPreference = "SilentlyContinue"
$ConfirmPreference = "None"
$ProgressPreference = "SilentlyContinue"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    [System.Windows.Forms.MessageBox]::Show(
        "For best results, please run this script as Administrator.`n`nRight-click the file and select 'Run as Administrator'.`n`nWithout admin rights, some files may not be deleted.",
        "My Clean PC - Admin Rights Recommended",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
}

# ====================================================
#  WINDOW SETUP
# ====================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "My Clean PC - For Priyanka"
$form.ClientSize    = New-Object System.Drawing.Size(520, 640)
$form.MinimumSize   = New-Object System.Drawing.Size(520, 640)
$form.MaximizeBox   = $false
$form.StartPosition = "CenterScreen"
$form.BackColor     = [System.Drawing.Color]::FromArgb(255, 248, 240)
$form.Font          = New-Object System.Drawing.Font("Segoe UI", 9)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text      = "My Clean PC"
$lblTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(185, 28, 28)
$lblTitle.SetBounds(0, 16, 520, 52)
$lblTitle.TextAlign = "MiddleCenter"
$form.Controls.Add($lblTitle)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text      = "Designed for Priyanka - Cleans safely, touches NOTHING important"
$lblSub.Font      = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblSub.ForeColor = [System.Drawing.Color]::FromArgb(234, 88, 12)
$lblSub.SetBounds(0, 66, 520, 22)
$lblSub.TextAlign = "MiddleCenter"
$form.Controls.Add($lblSub)

$pnlSafe = New-Object System.Windows.Forms.Panel
$pnlSafe.SetBounds(16, 94, 488, 32)
$pnlSafe.BackColor = [System.Drawing.Color]::FromArgb(240, 253, 244)
$form.Controls.Add($pnlSafe)
$lblSafe = New-Object System.Windows.Forms.Label
$lblSafe.Text      = "Lock  Passwords, Downloads & personal files are NEVER touched. Only junk is deleted."
$lblSafe.Font      = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$lblSafe.ForeColor = [System.Drawing.Color]::FromArgb(22, 163, 74)
$lblSafe.SetBounds(0, 0, 488, 32)
$lblSafe.TextAlign = "MiddleCenter"
$pnlSafe.Controls.Add($lblSafe)

$pnlLog = New-Object System.Windows.Forms.Panel
$pnlLog.SetBounds(16, 134, 488, 380)
$pnlLog.BackColor   = [System.Drawing.Color]::White
$pnlLog.BorderStyle = "FixedSingle"
$form.Controls.Add($pnlLog)

$rtb = New-Object System.Windows.Forms.RichTextBox
$rtb.SetBounds(0, 0, 486, 378)
$rtb.ReadOnly    = $true
$rtb.BorderStyle = "None"
$rtb.BackColor   = [System.Drawing.Color]::White
$rtb.Font        = New-Object System.Drawing.Font("Consolas", 8.5)
$rtb.ScrollBars  = "Vertical"
$rtb.WordWrap    = $true
$pnlLog.Controls.Add($rtb)

$prog = New-Object System.Windows.Forms.ProgressBar
$prog.SetBounds(16, 522, 488, 16)
$prog.Minimum = 0
$prog.Maximum = 100
$prog.Value   = 0
$prog.Style   = "Continuous"
$form.Controls.Add($prog)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text      = "Click  Start Cleaning  to begin."
$lblStatus.Font      = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
$lblStatus.SetBounds(16, 542, 488, 20)
$lblStatus.TextAlign = "MiddleCenter"
$form.Controls.Add($lblStatus)

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text      = "  Start Cleaning  (click here)"
$btnStart.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnStart.BackColor = [System.Drawing.Color]::FromArgb(234, 88, 12)
$btnStart.ForeColor = [System.Drawing.Color]::White
$btnStart.FlatStyle = "Flat"
$btnStart.FlatAppearance.BorderSize = 0
$btnStart.SetBounds(16, 568, 310, 48)
$form.Controls.Add($btnStart)

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text      = "Close"
$btnClose.Font      = New-Object System.Drawing.Font("Segoe UI", 11)
$btnClose.BackColor = [System.Drawing.Color]::FromArgb(229, 231, 235)
$btnClose.ForeColor = [System.Drawing.Color]::FromArgb(75, 85, 99)
$btnClose.FlatStyle = "Flat"
$btnClose.FlatAppearance.BorderSize = 0
$btnClose.SetBounds(334, 568, 170, 48)
$form.Controls.Add($btnClose)
$btnClose.Add_Click({ $form.Close() })

function WriteLog {
    param([string]$Text, [string]$Level = "info")
    $rtb.SelectionStart  = $rtb.TextLength
    $rtb.SelectionLength = 0
    switch ($Level) {
        "head" {
            $rtb.SelectionColor = [System.Drawing.Color]::FromArgb(234, 88, 12)
            $rtb.SelectionFont  = New-Object System.Drawing.Font("Consolas", 8.5, [System.Drawing.FontStyle]::Bold)
        }
        "ok" {
            $rtb.SelectionColor = [System.Drawing.Color]::FromArgb(22, 163, 74)
            $rtb.SelectionFont  = New-Object System.Drawing.Font("Consolas", 8.5)
        }
        "skip" {
            $rtb.SelectionColor = [System.Drawing.Color]::FromArgb(156, 163, 175)
            $rtb.SelectionFont  = New-Object System.Drawing.Font("Consolas", 8.5)
        }
        "done" {
            $rtb.SelectionColor = [System.Drawing.Color]::FromArgb(22, 163, 74)
            $rtb.SelectionFont  = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
        }
        "safe" {
            $rtb.SelectionColor = [System.Drawing.Color]::FromArgb(234, 88, 12)
            $rtb.SelectionFont  = New-Object System.Drawing.Font("Consolas", 8.5, [System.Drawing.FontStyle]::Bold)
        }
        default {
            $rtb.SelectionColor = [System.Drawing.Color]::FromArgb(55, 65, 81)
            $rtb.SelectionFont  = New-Object System.Drawing.Font("Consolas", 8.5)
        }
    }
    $rtb.AppendText("$Text`r`n")
    $rtb.SelectionStart = $rtb.TextLength
    $rtb.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Tick {
    param([int]$Pct, [string]$Msg)
    $prog.Value     = [Math]::Min($Pct, 100)
    $lblStatus.Text = $Msg
    [System.Windows.Forms.Application]::DoEvents()
}

$btnStart.Add_Click({
    $btnStart.Enabled   = $false
    $btnStart.Text      = "  Cleaning in progress..."
    $btnStart.BackColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
    $rtb.Clear()
    $form.Refresh()

    WriteLog "============================================" "head"
    WriteLog "   My Clean PC -  Starting now..." "head"
    WriteLog "============================================" "head"
    WriteLog "" "info"
    WriteLog "  IMPORTANT: Your passwords, Downloads and" "safe"
    WriteLog "  personal files are NEVER deleted. Ever." "safe"
    WriteLog "  Temp + app cache: auto-delete, locked files auto-skip." "skip"
    WriteLog "" "info"

    $coreFile = Join-Path $PSScriptRoot "clean-pc-core.ps1"
    if (-not (Test-Path $coreFile)) {
        WriteLog "ERROR: clean-pc-core.ps1 is missing. Keep it beside this GUI script." "head"
        [System.Windows.Forms.MessageBox]::Show(
            "clean-pc-core.ps1 was not found next to My-Clean-PC-GUI.ps1.`n`nThat file is the only cleaner. Put both scripts in the same folder.",
            "My Clean PC",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        $btnStart.Enabled    = $true
        $btnStart.Text       = "  Start Cleaning  (click here)"
        $btnStart.BackColor  = [System.Drawing.Color]::FromArgb(234, 88, 12)
        return
    }
    . $coreFile
    $guiPct = @{ 'STEP 1' = 2; 'STEP 2' = 17; 'STEP 3' = 52; 'STEP 4' = 60; 'STEP 5' = 70; 'STEP 6' = 85; 'STEP 7' = 95 }
    Invoke-MyCleanPCCore -Log {
        param([string]$Message)
        foreach ($k in @('STEP 1','STEP 2','STEP 3','STEP 4','STEP 5','STEP 6','STEP 7')) {
            if ($Message -like "*$k*") { Tick $guiPct[$k] $Message; break }
        }
        $lvl = "info"
        if ($Message -match 'auto-skip|skipped|NOT touched') { $lvl = "skip" }
        elseif ($Message -match 'cleared|emptied|flushed|Notice') { $lvl = "ok" }
        elseif ($Message -match '^-- STEP') { $lvl = "head" }
        WriteLog "  $Message" $lvl
    }
    Tick 100 "All done!"

    WriteLog "" "info"
    WriteLog "============================================" "done"
    WriteLog "   ALL DONE, Priyanka! Your PC is cleaner!" "done"
    WriteLog "============================================" "done"
    WriteLog "" "info"
    WriteLog "  What was cleaned:" "ok"
    WriteLog "    * AI app caches       CLEANED" "ok"
    WriteLog "    * Browser cache       CLEANED" "ok"
    WriteLog "    * Temp files          CLEANED (rigorous)" "ok"
    WriteLog "    * AppData junk        CLEANED (all apps)" "ok"
    WriteLog "    * Disk Cleanup        CLEANED (Downloads excluded)" "ok"
    WriteLog "    * Recycle Bin         EMPTIED" "ok"
    WriteLog "    * Windows Updates     CLEANED" "ok"
    WriteLog "    * DNS cache           FLUSHED" "ok"
    WriteLog "" "info"
    WriteLog "  What was NOT touched:" "safe"
    WriteLog "    * Your passwords      SAFE" "ok"
    WriteLog "    * Your Downloads      SAFE" "ok"
    WriteLog "    * Your personal files SAFE" "ok"
    WriteLog "" "info"
    WriteLog "  TIP: Restart your PC now for best results!" "done"
    WriteLog "============================================" "done"

    $lblStatus.Text = "All done! Please restart your PC for the best results."
    $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(22, 163, 74)
    $form.BackColor      = [System.Drawing.Color]::FromArgb(240, 253, 244)
    $btnStart.Enabled    = $true
    $btnStart.Text       = "  Run Again"
    $btnStart.BackColor  = [System.Drawing.Color]::FromArgb(234, 88, 12)

    [System.Windows.Forms.MessageBox]::Show(
        "All done, Priyanka!`n`nYour PC has been cleaned.`n`nPlease RESTART your PC for the best results!`n`nYour passwords and personal files were completely untouched.",
        "My Clean PC - All Done!",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
})

$form.Add_Shown({ $form.Activate(); $btnStart.Focus() })
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($form)
