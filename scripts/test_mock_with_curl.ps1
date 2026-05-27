$ErrorActionPreference = "Stop"

$BaseUrl = if ($env:BASE_URL) { $env:BASE_URL } else { "http://localhost:4010" }
$AuthHeader = "Authorization: Bearer test-token"

Write-Host "[Lab02 - Access Gate] Testing Prism mock server at $BaseUrl"
Write-Host ""

Write-Host "[1/5] Happy path: GET /health"
curl.exe -i "$BaseUrl/health"
Write-Host "`n---"

Write-Host "[2/5] Happy path: GET /gates/GATE-01/status (Kiem tra trang thai cong)"
curl.exe -i "$BaseUrl/gates/GATE-01/status" -H $AuthHeader
Write-Host "`n---"

Write-Host "[3/5] Happy path: GET /access/logs/recent (Lay log phan trang)"
curl.exe -i "$BaseUrl/access/logs/recent?limit=5" -H $AuthHeader
Write-Host "`n---"

Write-Host "[4/5] Error case: GET /access/logs/recent without token (Loi 401 Unauthorized)"
curl.exe -i "$BaseUrl/access/logs/recent"
Write-Host "`n---"

Write-Host "[5/5] Error case: GET /gates/gate_01/status (Loi 400 do sai Regex pattern cua gateId)"
curl.exe -i "$BaseUrl/gates/gate_01/status" -H $AuthHeader
Write-Host ""