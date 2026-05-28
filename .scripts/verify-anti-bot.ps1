param([string]$Base = 'https://bihorac.com')

$ErrorActionPreference = 'Stop'
$browserUA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
$results = @()

function Get-StatusCode {
    param($Url, $Ua)
    try {
        $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -UserAgent $Ua -ErrorAction Stop
        return [int]$r.StatusCode
    } catch {
        if ($_.Exception.Response) { return [int]$_.Exception.Response.StatusCode }
        return 0
    }
}

function Test-Url($name, $url, $ua, $expect) {
    $code = Get-StatusCode -Url $url -Ua $ua
    $pass = if ($expect -is [array]) { $expect -contains $code } else { $code -eq $expect }
    [PSCustomObject]@{ Test=$name; Code=$code; Expect=$expect; Result=$(if($pass){'PASS'}else{'FAIL'}) }
}

function Get-HeaderValue {
    param($Headers, $Name)
    $entry = $Headers.GetEnumerator() | Where-Object { $_.Key -ieq $Name } | Select-Object -First 1
    if ($entry) { return ($entry.Value -join ',') }
    return $null
}

$results += Test-Url 'robots.txt vorhanden'      "$Base/robots.txt" $browserUA 200
$results += Test-Url 'ai.txt vorhanden'          "$Base/ai.txt" $browserUA 200
$results += Test-Url 'security.txt vorhanden'    "$Base/.well-known/security.txt" $browserUA 200
$results += Test-Url 'Browser-UA kommt durch /'  "$Base/" $browserUA 200
$results += Test-Url 'Browser-UA kommt durch /dms/' "$Base/dms/" $browserUA 200
$results += Test-Url 'GPTBot geblockt'           "$Base/" 'Mozilla/5.0 (compatible; GPTBot/1.0; +https://openai.com/gptbot)' @(403,503)
$results += Test-Url 'ClaudeBot geblockt'        "$Base/" 'Mozilla/5.0 (compatible; ClaudeBot/1.0; +claudebot@anthropic.com)' @(403,503)
$results += Test-Url 'CCBot geblockt'            "$Base/" 'CCBot/2.0 (https://commoncrawl.org/faq/)' @(403,503)
$results += Test-Url 'SemrushBot geblockt'       "$Base/" 'Mozilla/5.0 (compatible; SemrushBot/7~bl; +http://www.semrush.com/bot.html)' @(403,503)
$results += Test-Url 'AhrefsBot geblockt'        "$Base/" 'Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)' @(403,503)

$results | Format-Table -AutoSize

$failed = @($results | Where-Object { $_.Result -eq 'FAIL' }).Count

try { $h = (Invoke-WebRequest -Uri "$Base/" -UseBasicParsing -UserAgent $browserUA).Headers } catch { $h = @{} }
$headerChecks = [ordered]@{
    'X-Robots-Tag'              = 'noindex'
    'X-Frame-Options'           = 'DENY'
    'X-Content-Type-Options'    = 'nosniff'
    'Strict-Transport-Security' = 'max-age'
    'Server'                    = 'cloudflare'
}
foreach ($k in $headerChecks.Keys) {
    $val = Get-HeaderValue -Headers $h -Name $k
    $pass = $val -and ($val -match $headerChecks[$k])
    "$k = '$val' -> $(if($pass){'PASS'}else{'FAIL'})"
    if (-not $pass) { $failed++ }
}

$pages = @('/','/dms/')
foreach ($p in $pages) {
    try {
        $body = (Invoke-WebRequest -Uri "$Base$p" -UseBasicParsing -UserAgent $browserUA).Content
        $has = $body -match 'name="robots".*noindex'
    } catch { $has = $false }
    "$p meta noindex -> $(if($has){'PASS'}else{'FAIL'})"
    if (-not $has) { $failed++ }
}

exit $failed
