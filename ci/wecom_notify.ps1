# ci\wecom_notify.ps1  (PowerShell 5.1 compatible + emoji)
param(
  [Parameter(Mandatory=$true)][string]$Webhook,
  [Parameter(Mandatory=$true)][string]$BuildUrl,
  [Parameter(Mandatory=$true)][string]$OutputXml,
  [string]$JobName = "",
  [string]$BuildNumber = "",
  [int]$ExitCode = 0,

  # 默认“通知失败不让流水线失败”
  [switch]$FailOnNotifyError
)

# --- normalize webhook ---
if ($null -eq $Webhook) { $Webhook = "" }
$Webhook = $Webhook.Trim().Trim('"').Trim("'")

if ([string]::IsNullOrWhiteSpace($Webhook)) {
  Write-Host "[WARN] WECHAT_WEBHOOK is empty."
  if ($FailOnNotifyError) { exit 2 } else { exit 0 }
}

# allow passing only key
if ($Webhook -notmatch '^https?://') {
  $Webhook = "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=$Webhook"
}

try { [void][Uri]$Webhook } catch {
  Write-Host ("[WARN] Invalid webhook URI. length={0}" -f $Webhook.Length)
  if ($FailOnNotifyError) { exit 2 } else { exit 0 }
}

# --- Build page: replace localhost using env:JENKINS_PUBLIC_URL if present ---
$BuildPage = ($BuildUrl.TrimEnd('/') + "/")

$public = $env:JENKINS_PUBLIC_URL
if ($null -eq $public) { $public = "" }
$public = $public.Trim()

if (-not [string]::IsNullOrWhiteSpace($public)) {
  $public = $public.TrimEnd('/')
  try {
    $u = [Uri]$BuildUrl
    $BuildPage = $public + $u.AbsolutePath
    if (-not $BuildPage.EndsWith('/')) { $BuildPage += '/' }
  } catch {
    $BuildPage = ($BuildUrl.TrimEnd('/') + "/")
  }
}

# Downloadable entry (recommended)
$ResultsDir = ($BuildPage + "artifact/results/")

# --- Parse robot output.xml stats ---
$pass=0; $fail=0; $skip=0; $total=0; $rate=0.0
$duration = ""
$failedLine=""

if (Test-Path $OutputXml) {
  try {
    # 关键：-Raw，避免只读到第一行导致 XML 解析失败
    [xml]$x = Get-Content -Raw -Path $OutputXml

    # /robot/statistics/total/stat
    $s = $x.robot.statistics.total.stat | Select-Object -First 1
    if ($s) {
      $pass = [int]$s.pass
      $fail = [int]$s.fail
      $skipVal = $s.skip
      if (-not $skipVal) { $skipVal = $s.skipped }
      if ($skipVal) { $skip = [int]$skipVal }

      $total = $pass + $fail + $skip
      if ($total -gt 0) { $rate = [math]::Round($pass * 100.0 / $total, 1) }
    }

    # duration: root suite status start/end (best effort)
    $st = $x.robot.suite.status
    if ($st -and $st.starttime -and $st.endtime) {
      try {
        $fmt = 'yyyyMMdd HH:mm:ss.fff'
        $t1 = [datetime]::ParseExact($st.starttime, $fmt, $null)
        $t2 = [datetime]::ParseExact($st.endtime,   $fmt, $null)
        $duration = ([timespan]($t2 - $t1)).ToString()
      } catch { }
    }

    # failed tests (top 5)
    if ($fail -gt 0) {
      $fails = Select-Xml -Path $OutputXml -XPath "//test[status[@status='FAIL']]" | Select-Object -First 5
      if ($fails) {
        $names = $fails | ForEach-Object { $_.Node.name }
        $failedLine = "❌失败用例(前5)： " + ($names -join "，")
      }
    }
  } catch {
    # keep default zeros
  }
}

if ($total -gt 0) {
  $status = if ($fail -gt 0) { "❌FAIL" } else { "✅PASS" }
} else {
  $status = if ($ExitCode -eq 0) { "✅PASS" } else { "❌FAIL" }
}

$overview = if ($total -gt 0) {
  "总计 $total，✅通过 $pass，❌失败 $fail，⏭跳过 $skip（通过率 $rate%）"
} else {
  "⚠️未读取到统计（output.xml 不存在或解析失败）"
}

$durLine = if ($duration) { "- ⏱耗时：$duration" } else { "" }

$content = @"
### 🤖 Robot 自动化测试：$status
- Job：$JobName  #$BuildNumber
- 概览：$overview
$durLine
- 构建页：[点击前往]($BuildPage)
- 📦下载入口：[点击下载]($ResultsDir)
"@.Trim()

if ($failedLine) { $content = $content + "`n- " + $failedLine }

$payload = @{
  msgtype  = "markdown"
  markdown = @{ content = $content }
} | ConvertTo-Json -Compress

try {
  $resp = Invoke-RestMethod -Method Post -Uri $Webhook -Body $payload -ContentType "application/json; charset=utf-8"

  # 关键：$null 放左边（消除 PSScriptAnalyzer 提示）
  if ($null -ne $resp -and $null -ne $resp.errcode) {
    Write-Host ("WeCom response: errcode={0}, errmsg={1}" -f $resp.errcode, $resp.errmsg)
    if ($resp.errcode -ne 0) {
      if ($FailOnNotifyError) { exit 3 } else { exit 0 }
    }
  } else {
    Write-Host "WeCom notified."
  }
} catch {
  Write-Host ("[WARN] WeCom notify failed: {0}" -f $_.Exception.Message)
  if ($FailOnNotifyError) { exit 3 } else { exit 0 }
}

exit 0
