# ci\wecom_notify.ps1
param(
  [Parameter(Mandatory=$true)][string]$Webhook,
  [Parameter(Mandatory=$true)][string]$BuildUrl,
  [Parameter(Mandatory=$true)][string]$OutputXml,
  [string]$JobName = "",
  [string]$BuildNumber = "",
  [int]$ExitCode = 0
)

# =========================
# 1) 计算“对外可访问”的 BuildPage（修复 localhost）
#    方式：如果配置了环境变量 JENKINS_PUBLIC_URL（例如 http://192.168.2.229:8080）
#    就用它替换 BuildUrl 的 scheme://host:port
# =========================
$BuildPage = ($BuildUrl.TrimEnd('/') + "/")

$public = ($env:JENKINS_PUBLIC_URL ?? "").Trim()
if ($public) {
  $public = $public.TrimEnd('/')
  try {
    $u = [Uri]$BuildUrl
    # 用 public base + Jenkins 给的 path（/job/xxx/21/）
    $BuildPage = $public + $u.AbsolutePath
    if (-not $BuildPage.EndsWith('/')) { $BuildPage += '/' }
  } catch {
    # 解析失败就用原始 BuildUrl
    $BuildPage = ($BuildUrl.TrimEnd('/') + "/")
  }
}

# 你希望“下载入口”更像可下载目录：直接指向 results 目录
$ResultsDir = ($BuildPage + "artifact/results/")

# =========================
# 2) 解析 Robot output.xml 得到概览
# =========================
$pass = 0; $fail = 0; $skip = 0; $total = 0; $rate = 0.0
$duration = ""
$failedLine = ""

if (Test-Path $OutputXml) {
  try {
    [xml]$x = Get-Content -Path $OutputXml

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

    # 耗时：根 suite status 的 start/end time（尽力解析，不保证每次都有）
    $st = $x.robot.suite.status
    if ($st -and $st.starttime -and $st.endtime) {
      try {
        $fmt = 'yyyyMMdd HH:mm:ss.fff'
        $t1 = [datetime]::ParseExact($st.starttime, $fmt, $null)
        $t2 = [datetime]::ParseExact($st.endtime,   $fmt, $null)
        $duration = ([timespan]($t2 - $t1)).ToString()
      } catch { }
    }

    # 失败用例名（前 5）
    if ($fail -gt 0) {
      $fails = Select-Xml -Path $OutputXml -XPath "//test[status[@status='FAIL']]" | Select-Object -First 5
      if ($fails) {
        $names = $fails | ForEach-Object { $_.Node.name }
        $failedLine = "失败用例(前5)： " + ($names -join "，")
      }
    }
  } catch {
    # 解析失败就走兜底
  }
}

$status = if ($ExitCode -eq 0) { "PASS ✅" } else { "FAIL ❌" }
$overview = if ($total -gt 0) {
  "总计 $total，✅通过 $pass，❌失败 $fail，⏭跳过 $skip（通过率 $rate%）"
} else {
  "未读取到统计（output.xml 不存在或解析失败）"
}

$durLine = if ($duration) { "- 耗时：$duration" } else { "" }

# =========================
# 3) 发送企业微信 markdown
# =========================
$content = @"
### 🤖 Robot 自动化测试：$status
- Job：$JobName  #$BuildNumber
- 概览：$overview
$durLine
- 构建页：[$BuildPage]($BuildPage)
- 下载入口：[$ResultsDir]($ResultsDir)
"@.Trim()

if ($failedLine) {
  $content = $content + "`n- " + $failedLine
}

$payload = @{
  msgtype  = "markdown"
  markdown = @{ content = $content }
} | ConvertTo-Json -Compress

try {
  $resp = Invoke-RestMethod -Method Post -Uri $Webhook -Body $payload -ContentType "application/json; charset=utf-8"
  # 打印返回，方便排查是否真的发送成功
  if ($null -ne $resp -and $resp.errcode -ne $null) {
    Write-Host ("WeCom response: errcode={0}, errmsg={1}" -f $resp.errcode, $resp.errmsg)
  } else {
    Write-Host "WeCom notified."
  }
} catch {
  Write-Host "WeCom notify failed:" $_.Exception.Message
  exit 3
}
