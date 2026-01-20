# ci\wecom_notify.ps1  (PowerShell 5.1 compatible)
param(
  [Parameter(Mandatory=$true)][string]$Webhook,
  [Parameter(Mandatory=$true)][string]$BuildUrl,

  [ValidateSet("start","finish")][string]$Event = "finish",

  # finish 时需要
  [string]$OutputXml = "",
  [string]$JobName = "",
  [string]$BuildNumber = "",
  [int]$ExitCode = 0,

  # start 时可选（用于展示）
  [string]$DeviceId = "",
  [string]$ApkJob = "",
  [string]$ApkBuild = "",
  [string]$ApkPath = "",
  [string]$TestFilesPath = "",
  [int]$MaxFiles = 30,

  [switch]$FailOnNotifyError
)

Write-Host "[INFO] wecom_notify.ps1 VERSION=2026-01-20.vStartFinish"

function N([string]$s){ if($null -eq $s){""} else {$s.Trim().Trim('"').Trim("'")} }

# ---- webhook normalize ----
$Webhook = N $Webhook
if ([string]::IsNullOrWhiteSpace($Webhook)) { Write-Host "[WARN] webhook empty"; exit 0 }
if ($Webhook -notmatch '^https?://') { $Webhook = "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=$Webhook" }

# ---- build url rewrite (public) ----
$BuildUrl = N $BuildUrl
$public = N $env:JENKINS_PUBLIC_URL
if ([string]::IsNullOrWhiteSpace($public)) { $public = N $env:JENKINS_URL }
$BuildPage = ($BuildUrl.TrimEnd('/') + "/")
try {
  if (-not [string]::IsNullOrWhiteSpace($public)) {
    $public = $public.TrimEnd('/')
    $u = [Uri]$BuildUrl
    $BuildPage = ($public + $u.AbsolutePath).TrimEnd('/') + "/"
  }
} catch { }

$ResultsDir = ($BuildPage.TrimEnd('/') + "/artifact/results/")
$TestPlanUrl = ($ResultsDir.TrimEnd('/') + "/selected_test_files.txt")

function Send-WecomMarkdown([string]$md){
  $payload = @{
    msgtype="markdown"
    markdown=@{content=$md}
  } | ConvertTo-Json -Compress

  try {
    $resp = Invoke-RestMethod -Method Post -Uri $Webhook -Body $payload -ContentType "application/json; charset=utf-8"
    if ($null -ne $resp -and $null -ne $resp.errcode) {
      Write-Host ("WeCom response: errcode={0}, errmsg={1}" -f $resp.errcode, $resp.errmsg)
    } else {
      Write-Host "WeCom notified."
    }
    return $true
  } catch {
    Write-Host ("[WARN] WeCom notify failed: {0}" -f $_.Exception.Message)
    if ($FailOnNotifyError) { exit 3 } else { return $false }
  }
}

# =========================
# Event: start
# =========================
if ($Event -eq "start") {
  $TestFilesPath = N $TestFilesPath

  $lines = @()
  $count = 0

  if (-not [string]::IsNullOrWhiteSpace($TestFilesPath) -and (Test-Path -LiteralPath $TestFilesPath)) {
    $all = Get-Content -LiteralPath $TestFilesPath -ErrorAction SilentlyContinue
    if ($null -ne $all) {
      # 只保留 .robot
      $all = $all | Where-Object { $_ -match '\.robot$' }

      $count = $all.Count
      $head = $all | Select-Object -First $MaxFiles
      $lines = $head | ForEach-Object { "🧩 " + $_ }

      if ($count -gt $MaxFiles) {
        $lines += ("✨ 还有 {0} 个未展示（共 {1} 个，仅展示前 {2} 个）" -f ($count-$MaxFiles), $count, $MaxFiles)
      }
    }
  }

  if ($count -eq 0) {
    $lines = @("⚠️ 未找到本次将执行的 .robot 文件（或清单文件不存在）")
  }

  $md = @"
🌟🌟🌟 **自动化测试已启动** 🌟🌟🌟
📌 Job：**$JobName**  #$BuildNumber
🔗 构建页：[点击查看]($BuildPage)
📄 测试清单：[selected_test_files.txt]($TestPlanUrl)

🚀 **本次将执行的 .robot 文件（$count）**
$($lines -join "`n")
"@.Trim()

  [void](Send-WecomMarkdown $md)
  exit 0
}

# =========================
# Event: finish  (你原来的逻辑保留 + 小幅整理)
# =========================
$OutputXml = N $OutputXml
Write-Host "[INFO] OutputXml param=$OutputXml"
if (-not [string]::IsNullOrWhiteSpace($OutputXml) -and (Test-Path -LiteralPath $OutputXml)) {
  $fi = Get-Item -LiteralPath $OutputXml
  Write-Host ("[INFO] output.xml exists size={0} lastWrite={1}" -f $fi.Length, $fi.LastWriteTime)
} else {
  Write-Host "[WARN] output.xml not found at param path."
}

# ---- read xml (force UTF-8 bytes) + remove illegal XML chars ----
$raw = ""
$parseError = ""
if (-not [string]::IsNullOrWhiteSpace($OutputXml) -and (Test-Path -LiteralPath $OutputXml)) {
  try {
    $bytes = [System.IO.File]::ReadAllBytes($OutputXml)
    $raw = [System.Text.Encoding]::UTF8.GetString($bytes)
    $raw = [regex]::Replace($raw, "[\x00-\x08\x0B\x0C\x0E-\x1F]", "")
  } catch { $parseError = $_.Exception.Message }
}

# ---- parse stats (3-layer fallback) ----
$pass=0; $fail=0; $skip=0; $total=0; $rate=0.0
function SetStats([int]$p,[int]$f,[int]$s){
  $script:pass=$p; $script:fail=$f; $script:skip=$s
  $script:total=$p+$f+$s
  if ($script:total -gt 0) { $script:rate=[math]::Round($p*100.0/$script:total,1) }
}

if (-not [string]::IsNullOrWhiteSpace($raw)) {
  try {
    [xml]$x = $raw
    $s = $null
    try { $s = $x.robot.statistics.total.stat | Select-Object -First 1 } catch { $s = $null }
    if ($s -and $s.pass -ne $null -and $s.fail -ne $null) {
      $sv = $s.skip; if (-not $sv) { $sv = $s.skipped }
      $sk = 0; if ($sv) { $sk = [int]$sv }
      SetStats ([int]$s.pass) ([int]$s.fail) $sk
    } else { throw "stats node not found" }
  } catch {
    $m = [regex]::Match($raw, '<total>\s*<stat[^>]*pass="(\d+)"[^>]*fail="(\d+)"[^>]*(?:skip|skipped)="(\d+)"', 'Singleline')
    if (-not $m.Success) {
      $m = [regex]::Match($raw, '<stat[^>]*pass="(\d+)"[^>]*fail="(\d+)"[^>]*(?:skip|skipped)="(\d+)"', 'Singleline')
    }
    if ($m.Success) {
      SetStats ([int]$m.Groups[1].Value) ([int]$m.Groups[2].Value) ([int]$m.Groups[3].Value)
    } else {
      $parseError = "stats not found (xml parse failed or structure changed)"
    }
  }
}

Write-Host ("[INFO] Stats: total={0} pass={1} fail={2} skip={3}" -f $total,$pass,$fail,$skip)

if ($total -gt 0) {
  $status = if ($fail -gt 0) { "❌FAIL" } else { "✅PASS" }
  $overview = "总计 $total，✅通过 $pass，❌失败 $fail，⏭跳过 $skip（通过率 $rate%）"
} else {
  $status = if ($ExitCode -eq 0) { "✅PASS" } else { "❌FAIL" }
  $overview = if (-not [string]::IsNullOrWhiteSpace($OutputXml) -and (Test-Path -LiteralPath $OutputXml)) {
    "⚠️未读取到统计（output.xml 解析失败：$parseError）"
  } else {
    "⚠️未读取到统计（output.xml 不存在：$OutputXml）"
  }
}

$md2 = @"
### 🏳️‍🌈 Robot 自动化测试：$status
- Job：$JobName  #$BuildNumber
- 概览：$overview
- 构建页：[点击前往]($BuildPage)
- 📦下载入口：[点击下载]($ResultsDir)
- 测试文件清单：[selected_test_files.txt]($TestPlanUrl)
"@.Trim()

[void](Send-WecomMarkdown $md2)
exit 0