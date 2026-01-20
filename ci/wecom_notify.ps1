# ci\wecom_notify.ps1  (PowerShell 5.1 compatible + robust XML parse)
param(
  [Parameter(Mandatory=$true)][string]$Webhook,
  [Parameter(Mandatory=$true)][string]$BuildUrl,
  [Parameter(Mandatory=$true)][string]$OutputXml,
  [string]$JobName = "",
  [string]$BuildNumber = "",
  [int]$ExitCode = 0,
  [switch]$FailOnNotifyError
)

# ---- version banner (用来确认 Jenkins 跑的是不是新脚本) ----
Write-Host "[INFO] wecom_notify.ps1 VERSION=2026-01-19.vFinal"

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

# ---- output.xml path ----
$OutputXml = N $OutputXml
Write-Host "[INFO] OutputXml param=$OutputXml"
if (-not (Test-Path -LiteralPath $OutputXml)) {
  Write-Host "[WARN] output.xml not found at param path."
} else {
  $fi = Get-Item -LiteralPath $OutputXml
  Write-Host ("[INFO] output.xml exists size={0} lastWrite={1}" -f $fi.Length, $fi.LastWriteTime)
}

# ---- read xml (force UTF-8 bytes) + remove illegal XML chars ----
$raw = ""
$parseError = ""
if (Test-Path -LiteralPath $OutputXml) {
  try {
    $bytes = [System.IO.File]::ReadAllBytes($OutputXml)
    $raw = [System.Text.Encoding]::UTF8.GetString($bytes)

    # 去掉 XML 1.0 不允许的控制字符（常见于日志/颜色码导致 XML 解析失败）
    $raw = [regex]::Replace($raw, "[\x00-\x08\x0B\x0C\x0E-\x1F]", "")
  } catch {
    $parseError = $_.Exception.Message
  }
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
    } else {
      throw "stats node not found in xml object"
    }
  } catch {
    # regex fallback: 即使 xml 解析失败也能拿到统计
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

# ---- status prefer stats ----
if ($total -gt 0) {
  $status = if ($fail -gt 0) { "❌FAIL" } else { "✅PASS" }
  $overview = "总计 $total，✅通过 $pass，❌失败 $fail，⏭跳过 $skip（通过率 $rate%）"
} else {
  $status = if ($ExitCode -eq 0) { "✅PASS" } else { "❌FAIL" }
  $overview = if (Test-Path -LiteralPath $OutputXml) {
    "⚠️未读取到统计（output.xml 解析失败：$parseError）"
  } else {
    "⚠️未读取到统计（output.xml 不存在：$OutputXml）"
  }
}

# ---- markdown (hide full url) ----
$content = @"
### 🤖 Robot 自动化测试：$status
- Job：$JobName  #$BuildNumber
- 概览：$overview
- 构建页：[点击前往]($BuildPage)
- 📦下载入口：[点击下载]($ResultsDir)
"@.Trim()

$payload = @{
  msgtype="markdown"
  markdown=@{content=$content}
} | ConvertTo-Json -Compress

try {
  $resp = Invoke-RestMethod -Method Post -Uri $Webhook -Body $payload -ContentType "application/json; charset=utf-8"
  if ($null -ne $resp -and $null -ne $resp.errcode) {
    Write-Host ("WeCom response: errcode={0}, errmsg={1}" -f $resp.errcode, $resp.errmsg)
  } else {
    Write-Host "WeCom notified."
  }
} catch {
  Write-Host ("[WARN] WeCom notify failed: {0}" -f $_.Exception.Message)
  if ($FailOnNotifyError) { exit 3 } else { exit 0 }
}

exit 0