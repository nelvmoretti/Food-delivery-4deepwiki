# =============================================
# BTL2 - Setup Database Script
# Chay tat ca 6 file SQL theo thu tu
# =============================================

$serverName = "localhost\SQLEXPRESS"

# Tim sqlcmd trong cac duong dan thuong gap
$sqlcmdPaths = @(
    "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\*\Tools\Binn\sqlcmd.exe",
    "C:\Program Files\Microsoft SQL Server\*\Tools\Binn\sqlcmd.exe",
    "C:\Program Files\Microsoft SQL Server\170\Tools\Binn\sqlcmd.exe",
    "C:\Program Files\Microsoft SQL Server\160\Tools\Binn\sqlcmd.exe",
    "C:\Program Files\Microsoft SQL Server\150\Tools\Binn\sqlcmd.exe"
)

$sqlcmd = $null
foreach ($path in $sqlcmdPaths) {
    $found = Get-ChildItem $path -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $sqlcmd = $found.FullName; break }
}

if (-not $sqlcmd) {
    # Fallback: try PATH
    $sqlcmd = (Get-Command sqlcmd -ErrorAction SilentlyContinue).Source
}

if (-not $sqlcmd) {
    Write-Host "❌ Khong tim thay sqlcmd.exe!" -ForegroundColor Red
    Write-Host "Hay cai SQL Server Management Tools hoac them sqlcmd vao PATH" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Hoac chay thu voi Invoke-Sqlcmd (PowerShell module)..." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Tim thay sqlcmd: $sqlcmd" -ForegroundColor Green
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$files = @(
    "01_create_tables.sql",
    "02_sample_data.sql", 
    "03_procedures_crud.sql",
    "04_triggers.sql",
    "05_procedures_query.sql",
    "06_functions.sql"
)

foreach ($f in $files) {
    $fullPath = Join-Path $scriptDir $f
    if (-not (Test-Path $fullPath)) {
        Write-Host "❌ Khong tim thay file: $f" -ForegroundColor Red
        continue
    }
    Write-Host "▶ Dang chay: $f ..." -ForegroundColor Cyan -NoNewline
    & $sqlcmd -S $serverName -E -i $fullPath -b 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✅ OK" -ForegroundColor Green
    } else {
        Write-Host " ❌ LOI!" -ForegroundColor Red
        & $sqlcmd -S $serverName -E -i $fullPath 2>&1 | Select-Object -Last 5
    }
}

Write-Host ""
Write-Host "🎉 Hoan tat setup database!" -ForegroundColor Green
