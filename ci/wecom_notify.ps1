# ci\wecom_notify.ps1  (ASCII-safe)
param(
  [Parameter(Mandatory=$true)][string]$Webhook,
  [Parameter(Mandatory=$true)][string]$BuildUrl,
  [Parameter(Mandatory=$true)][string]$OutputXml,
  [string]$JobName = "",
  [string]$BuildNumber = "",
  [int]$ExitCode = 0
)

$RobotUrl = ($BuildUrl.TrimEnd('/') + "/robot/")

$pass=0; $fail=0; $skip=0; $total=0; $rate=0.0
$failedLine = ""

if (Test-Path $OutputXml) {
  try {
    [xml]$x = Get-Content -Path $OutputXml
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

    if ($fail -gt 0) {
      $fails = Select-Xml -Path $OutputXml -XPath "//test[status[@status='FAIL']]" | Select-Object -First 5
      if ($fails) {
        $names = $fails | ForEach-Object { $_.Node.name }
        $failedLine = "Failed (top5): " + ($names -join ", ")
      }
    }
  } catch { }
}

$status = if ($ExitCode -eq 0) { "PASS" } else { "FAIL" }
$overview = if ($total -gt 0) {
  "Total $total, Pass $pass, Fail $fail, Skip $skip, PassRate $rate`%"
} else {
  "No stats (output.xml missing or parse failed)"
}

$content = @"
### Robot Test: $status
- Job: $JobName #$BuildNumber
- Summary: $overview
- Robot: [$RobotUrl]($RobotUrl)
- Build: [$BuildUrl]($BuildUrl)
"@.Trim()

if ($failedLine) { $content = $content + "`n- " + $failedLine }

$payload = @{
  msgtype  = "markdown"
  markdown = @{ content = $content }
} | ConvertTo-Json -Compress

Invoke-RestMethod -Method Post -Uri $Webhook -Body $payload -ContentType "application/json; charset=utf-8" | Out-Null
Write-Host "WeCom notified."
