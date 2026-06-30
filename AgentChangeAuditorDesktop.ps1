param(
    [string]$ScreenshotPath = ""
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$script:CurrentProject = ""

function New-Font($size, $style = [System.Drawing.FontStyle]::Regular) {
    return New-Object System.Drawing.Font("Segoe UI", $size, $style)
}

function Add-Log {
    param([string]$Text)
    $time = Get-Date -Format "HH:mm:ss"
    $logBox.AppendText("[$time] $Text`r`n")
}

function Set-Project {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    $script:CurrentProject = $Path
    $projectBox.Text = $Path
    Refresh-ProjectStatus
}

function Require-Project {
    if ([string]::IsNullOrWhiteSpace($script:CurrentProject) -or -not (Test-Path -LiteralPath $script:CurrentProject)) {
        [System.Windows.Forms.MessageBox]::Show("请先选择一个项目文件夹。", "缺少项目", "OK", "Warning") | Out-Null
        return $false
    }
    return $true
}

function Format-CliArgs {
    param(
        [string]$Program,
        [string[]]$AcaArgs
    )
    $parts = @($Program)
    foreach ($arg in $AcaArgs) {
        if ($null -eq $arg) { continue }
        if ($arg -match '[\s"]') {
            $parts += ('"' + ($arg -replace '"', '\"') + '"')
        } else {
            $parts += $arg
        }
    }
    return ($parts -join ' ')
}

function Invoke-Aca {
    param(
        [Parameter(Mandatory=$true)][string[]]$AcaArgs,
        [string]$Title = "aca"
    )
    if (-not (Require-Project)) { return $null }

    Add-Log ("> " + (Format-CliArgs "aca" $AcaArgs))
    $oldLocation = Get-Location
    try {
        Set-Location -LiteralPath $script:CurrentProject
        $output = & aca @AcaArgs 2>&1 | Out-String
        if ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) {
            Add-Log "$Title exited with code $LASTEXITCODE"
        }
        if (-not [string]::IsNullOrWhiteSpace($output)) {
            Add-Log $output.TrimEnd()
        }
        Refresh-ProjectStatus
        return $output
    }
    catch {
        Add-Log "ERROR: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "执行失败", "OK", "Error") | Out-Null
        return $null
    }
    finally {
        Set-Location $oldLocation
    }
}

function Refresh-ProjectStatus {
    if ([string]::IsNullOrWhiteSpace($script:CurrentProject) -or -not (Test-Path -LiteralPath $script:CurrentProject)) {
        $statusLabel.Text = "未选择项目"
        return
    }

    $oldLocation = Get-Location
    try {
        Set-Location -LiteralPath $script:CurrentProject
        $inside = & git rev-parse --is-inside-work-tree 2>$null
        if ($LASTEXITCODE -ne 0 -or $inside.Trim() -ne "true") {
            $statusLabel.Text = "项目状态：不是 Git 仓库，可点击 aca init 初始化"
            return
        }
        $branch = (& git branch --show-current 2>$null | Out-String).Trim()
        $head = (& git rev-parse --short HEAD 2>$null | Out-String).Trim()
        $changes = (& git status --short -uall 2>$null | Out-String).Trim()
        $count = 0
        if (-not [string]::IsNullOrWhiteSpace($changes)) {
            $count = ($changes -split "`r?`n").Count
        }
        $statusLabel.Text = "项目状态：Git 仓库 | 分支 $branch | HEAD $head | 当前变更 $count 项"
    }
    catch {
        $statusLabel.Text = "项目状态：读取失败"
    }
    finally {
        Set-Location $oldLocation
    }
}

function Load-Report {
    param([string]$FileName)
    if (-not (Require-Project)) { return }
    $file = Join-Path $script:CurrentProject $FileName
    if (-not (Test-Path -LiteralPath $file)) {
        [System.Windows.Forms.MessageBox]::Show("还没有生成 $FileName。", "报告不存在", "OK", "Information") | Out-Null
        return
    }
    $reportBox.Text = Get-Content -LiteralPath $file -Raw -Encoding UTF8
    Add-Log "Loaded $FileName"
}

function Open-Path {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        Start-Process -FilePath $Path
    }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Agent Change Auditor Desktop"
$form.Size = New-Object System.Drawing.Size(1120, 760)
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object System.Drawing.Size(980, 680)
$form.Font = New-Font 9

$title = New-Object System.Windows.Forms.Label
$title.Text = "Agent Change Auditor Desktop"
$title.Font = New-Font 16 ([System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(18, 15)
$form.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "给 AI Agent 改代码过程加一个手动记录仪：开始、记录自述、停止、生成审计报告。"
$subtitle.AutoSize = $true
$subtitle.Location = New-Object System.Drawing.Point(22, 50)
$form.Controls.Add($subtitle)

$projectLabel = New-Object System.Windows.Forms.Label
$projectLabel.Text = "项目文件夹"
$projectLabel.AutoSize = $true
$projectLabel.Location = New-Object System.Drawing.Point(22, 88)
$form.Controls.Add($projectLabel)

$projectBox = New-Object System.Windows.Forms.TextBox
$projectBox.Location = New-Object System.Drawing.Point(100, 84)
$projectBox.Size = New-Object System.Drawing.Size(780, 26)
$projectBox.Anchor = "Top,Left,Right"
$form.Controls.Add($projectBox)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "选择..."
$browseButton.Location = New-Object System.Drawing.Point(895, 82)
$browseButton.Size = New-Object System.Drawing.Size(90, 30)
$browseButton.Anchor = "Top,Right"
$browseButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "选择要审计的项目文件夹"
    if (-not [string]::IsNullOrWhiteSpace($projectBox.Text) -and (Test-Path -LiteralPath $projectBox.Text)) {
        $dialog.SelectedPath = $projectBox.Text
    }
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Set-Project $dialog.SelectedPath
    }
})
$form.Controls.Add($browseButton)

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = "刷新"
$refreshButton.Location = New-Object System.Drawing.Point(995, 82)
$refreshButton.Size = New-Object System.Drawing.Size(80, 30)
$refreshButton.Anchor = "Top,Right"
$refreshButton.Add_Click({
    Set-Project $projectBox.Text
})
$form.Controls.Add($refreshButton)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "未选择项目"
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(100, 116)
$form.Controls.Add($statusLabel)

$labelLabel = New-Object System.Windows.Forms.Label
$labelLabel.Text = "任务说明"
$labelLabel.AutoSize = $true
$labelLabel.Location = New-Object System.Drawing.Point(22, 152)
$form.Controls.Add($labelLabel)

$labelBox = New-Object System.Windows.Forms.TextBox
$labelBox.Location = New-Object System.Drawing.Point(100, 148)
$labelBox.Size = New-Object System.Drawing.Size(460, 26)
$labelBox.Text = "让 agent 修改功能"
$form.Controls.Add($labelBox)

$langLabel = New-Object System.Windows.Forms.Label
$langLabel.Text = "报告语言"
$langLabel.AutoSize = $true
$langLabel.Location = New-Object System.Drawing.Point(585, 152)
$form.Controls.Add($langLabel)

$langBox = New-Object System.Windows.Forms.ComboBox
$langBox.Location = New-Object System.Drawing.Point(650, 148)
$langBox.Size = New-Object System.Drawing.Size(120, 26)
$langBox.DropDownStyle = "DropDownList"
[void]$langBox.Items.Add("both")
[void]$langBox.Items.Add("zh-CN")
[void]$langBox.Items.Add("en")
$langBox.SelectedIndex = 0
$form.Controls.Add($langBox)

$initButton = New-Object System.Windows.Forms.Button
$initButton.Text = "1. 初始化 aca init"
$initButton.Location = New-Object System.Drawing.Point(25, 195)
$initButton.Size = New-Object System.Drawing.Size(170, 38)
$initButton.Add_Click({
    Invoke-Aca @("init") "aca init" | Out-Null
})
$form.Controls.Add($initButton)

$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "2. 开始记录"
$startButton.Location = New-Object System.Drawing.Point(210, 195)
$startButton.Size = New-Object System.Drawing.Size(150, 38)
$startButton.Add_Click({
    Invoke-Aca @("start", "--label", $labelBox.Text) "aca start" | Out-Null
})
$form.Controls.Add($startButton)

$claimButton = New-Object System.Windows.Forms.Button
$claimButton.Text = "3. 保存 Agent 自述"
$claimButton.Location = New-Object System.Drawing.Point(375, 195)
$claimButton.Size = New-Object System.Drawing.Size(170, 38)
$claimButton.Add_Click({
    $claim = $claimBox.Text
    if ([string]::IsNullOrWhiteSpace($claim)) {
        [System.Windows.Forms.MessageBox]::Show("请先在下面填写或粘贴 agent 自述。", "缺少自述", "OK", "Information") | Out-Null
        return
    }
    $tempFile = Join-Path $env:TEMP ("aca-claim-" + [Guid]::NewGuid().ToString() + ".md")
    Set-Content -LiteralPath $tempFile -Value $claim -Encoding UTF8
    Invoke-Aca @("claim", "--file", $tempFile) "aca claim" | Out-Null
    Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
})
$form.Controls.Add($claimButton)

$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = "4. 停止并生成报告"
$stopButton.Location = New-Object System.Drawing.Point(560, 195)
$stopButton.Size = New-Object System.Drawing.Size(190, 38)
$stopButton.Add_Click({
    $acaArgs = @("stop", "--lang", [string]$langBox.SelectedItem)
    if (-not [string]::IsNullOrWhiteSpace($testBox.Text)) {
        $acaArgs += @("--test", $testBox.Text)
    }
    if (-not [string]::IsNullOrWhiteSpace($buildBox.Text)) {
        $acaArgs += @("--build", $buildBox.Text)
    }
    Invoke-Aca $acaArgs "aca stop" | Out-Null
    if ($langBox.SelectedItem -eq "zh-CN") { Load-Report "AI_CHANGE_AUDIT.zh-CN.md" }
    elseif ($langBox.SelectedItem -eq "en") { Load-Report "AI_CHANGE_AUDIT.en.md" }
    else { Load-Report "AI_CHANGE_AUDIT.zh-CN.md" }
})
$form.Controls.Add($stopButton)

$openFolderButton = New-Object System.Windows.Forms.Button
$openFolderButton.Text = "打开项目文件夹"
$openFolderButton.Location = New-Object System.Drawing.Point(765, 195)
$openFolderButton.Size = New-Object System.Drawing.Size(150, 38)
$openFolderButton.Add_Click({
    if (Require-Project) { Open-Path $script:CurrentProject }
})
$form.Controls.Add($openFolderButton)

$openReportButton = New-Object System.Windows.Forms.Button
$openReportButton.Text = "打开报告"
$openReportButton.Location = New-Object System.Drawing.Point(930, 195)
$openReportButton.Size = New-Object System.Drawing.Size(140, 38)
$openReportButton.Add_Click({
    if (-not (Require-Project)) { return }
    $candidate = Join-Path $script:CurrentProject "AI_CHANGE_AUDIT.zh-CN.md"
    if (-not (Test-Path -LiteralPath $candidate)) {
        $candidate = Join-Path $script:CurrentProject "AI_CHANGE_AUDIT.md"
    }
    Open-Path $candidate
})
$form.Controls.Add($openReportButton)

$testLabel = New-Object System.Windows.Forms.Label
$testLabel.Text = "测试命令"
$testLabel.AutoSize = $true
$testLabel.Location = New-Object System.Drawing.Point(22, 252)
$form.Controls.Add($testLabel)

$testBox = New-Object System.Windows.Forms.TextBox
$testBox.Location = New-Object System.Drawing.Point(100, 248)
$testBox.Size = New-Object System.Drawing.Size(420, 26)
$testBox.Text = ""
$form.Controls.Add($testBox)

$buildLabel = New-Object System.Windows.Forms.Label
$buildLabel.Text = "构建命令"
$buildLabel.AutoSize = $true
$buildLabel.Location = New-Object System.Drawing.Point(545, 252)
$form.Controls.Add($buildLabel)

$buildBox = New-Object System.Windows.Forms.TextBox
$buildBox.Location = New-Object System.Drawing.Point(625, 248)
$buildBox.Size = New-Object System.Drawing.Size(445, 26)
$buildBox.Text = ""
$form.Controls.Add($buildBox)

$claimLabel = New-Object System.Windows.Forms.Label
$claimLabel.Text = "Agent 自述 / Claim"
$claimLabel.AutoSize = $true
$claimLabel.Location = New-Object System.Drawing.Point(22, 292)
$form.Controls.Add($claimLabel)

$claimBox = New-Object System.Windows.Forms.TextBox
$claimBox.Location = New-Object System.Drawing.Point(25, 315)
$claimBox.Size = New-Object System.Drawing.Size(510, 130)
$claimBox.Multiline = $true
$claimBox.ScrollBars = "Vertical"
$claimBox.Text = "Agent said: I changed ..."
$form.Controls.Add($claimBox)

$logLabel = New-Object System.Windows.Forms.Label
$logLabel.Text = "运行日志"
$logLabel.AutoSize = $true
$logLabel.Location = New-Object System.Drawing.Point(555, 292)
$form.Controls.Add($logLabel)

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Location = New-Object System.Drawing.Point(560, 315)
$logBox.Size = New-Object System.Drawing.Size(510, 130)
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.ReadOnly = $true
$form.Controls.Add($logBox)

$reportLabel = New-Object System.Windows.Forms.Label
$reportLabel.Text = "报告预览"
$reportLabel.AutoSize = $true
$reportLabel.Location = New-Object System.Drawing.Point(22, 465)
$form.Controls.Add($reportLabel)

$loadZhButton = New-Object System.Windows.Forms.Button
$loadZhButton.Text = "预览中文"
$loadZhButton.Location = New-Object System.Drawing.Point(100, 458)
$loadZhButton.Size = New-Object System.Drawing.Size(95, 30)
$loadZhButton.Add_Click({ Load-Report "AI_CHANGE_AUDIT.zh-CN.md" })
$form.Controls.Add($loadZhButton)

$loadEnButton = New-Object System.Windows.Forms.Button
$loadEnButton.Text = "预览英文"
$loadEnButton.Location = New-Object System.Drawing.Point(205, 458)
$loadEnButton.Size = New-Object System.Drawing.Size(95, 30)
$loadEnButton.Add_Click({ Load-Report "AI_CHANGE_AUDIT.en.md" })
$form.Controls.Add($loadEnButton)

$loadDefaultButton = New-Object System.Windows.Forms.Button
$loadDefaultButton.Text = "预览默认"
$loadDefaultButton.Location = New-Object System.Drawing.Point(310, 458)
$loadDefaultButton.Size = New-Object System.Drawing.Size(95, 30)
$loadDefaultButton.Add_Click({ Load-Report "AI_CHANGE_AUDIT.md" })
$form.Controls.Add($loadDefaultButton)

$reportBox = New-Object System.Windows.Forms.TextBox
$reportBox.Location = New-Object System.Drawing.Point(25, 495)
$reportBox.Size = New-Object System.Drawing.Size(1045, 195)
$reportBox.Anchor = "Top,Bottom,Left,Right"
$reportBox.Multiline = $true
$reportBox.ScrollBars = "Both"
$reportBox.ReadOnly = $true
$reportBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$form.Controls.Add($reportBox)

$form.Add_Shown({
    Add-Log "Ready. 先选择项目，然后按 1-4 的顺序操作。"
    Add-Log "提示：这是初版 GUI，底层仍然调用全局 aca 命令。"
})

if (-not [string]::IsNullOrWhiteSpace($ScreenshotPath)) {
    $parent = Split-Path -Parent $ScreenshotPath
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent | Out-Null
    }
    $form.ShowInTaskbar = $false
    $form.Opacity = 0
    $form.Show()
    $form.Refresh()
    Start-Sleep -Milliseconds 300
    $bitmap = New-Object System.Drawing.Bitmap($form.Width, $form.Height)
    $bounds = New-Object System.Drawing.Rectangle(0, 0, $form.Width, $form.Height)
    $form.DrawToBitmap($bitmap, $bounds)
    $bitmap.Save($ScreenshotPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
    $form.Close()
    return
}

[void][System.Windows.Forms.Application]::Run($form)
