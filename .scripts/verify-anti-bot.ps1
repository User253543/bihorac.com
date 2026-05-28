$base = 'https://bihorac.com'
$browserUA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
$results = @()

function Test-Url($name, $url, $ua, $expect) {
    try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -UserAgent $ua -ErrorAction Stop
        $code = $r.StatusCode
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
    }
    $pass = if ($expect -is [array]) { $expect -contains $code } else { $code -eq $expect }
    [PSCustomObject]@{ Test=$name; Code=$code; Expect=$expect; Result=$(if($pass){'PASS'}else{'FAIL'}) }
}

$results += Test-Url 'robots.txt vorhanden'      "$base/robots.txt" $browserUA 200
$results += Test-Url 'ai.txt vorhanden'          "$base/ai.txt" $browserUA 200
$results += Test-Url 'security.txt vorhanden'    "$base/.well-known/security.txt" $browserUA 200
$results += Test-Url 'Browser-UA kommt durch'    "$base/" $browserUA 200
$results += Test-Url 'GPTBot geblockt'           "$base/" 'Mozilla/5.0 (compatible; GPTBot/1.0; +https://openai.com/gptbot)' @(403,503)
$results += Test-Url 'ClaudeBot geblockt'        "$base/" 'Mozilla/5.0 (compatible; ClaudeBot/1.0; +claudebot@anthropic.com)' @(403,503)
$results += Test-Url 'CCBot geblockt'            "$base/" 'CCBot/2.0 (https://commoncrawl.org/faq/)' @(403,503)
$results += Test-Url 'SemrushBot geblockt'       "$base/" 'Mozilla/5.0 (compatible; SemrushBot/7~bl; +http://www.semrush.com/bot.html)' @(403,503)
$results += Test-Url 'AhrefsBot geblockt'        "$base/" 'Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)' @(403,503)

$results | Format-Table -AutoSize

$h = (Invoke-WebRequest -Uri "$base/" -UseBasicParsing -UserAgent $browserUA).Headers
$headerChecks = @{
    'X-Robots-Tag'              = 'noindex'
    'X-Frame-Options'            = 'DENY'
    'X-Content-Type-Options'     = 'nosniff'
    'Strict-Transport-Security'  = 'max-age'
    'Server'                     = 'cloudflare'
}
foreach ($k in $headerChecks.Keys) {
    $val = $h[$k]
    $pass = $val -match $headerChecks[$k]
    "$k = '$val' -> $(if($pass){'PASS'}else{'FAIL'})"
}

$pages = @('/','/dms/')
foreach ($p in $pages) {
    $body = (Invoke-WebRequest -Uri "$base$p" -UseBasicParsing -UserAgent $browserUA).Content
    $has = $body -match 'name="robots".*noindex'
    "$p meta noindex -> $(if($has){'PASS'}else{'FAIL'})"
}
