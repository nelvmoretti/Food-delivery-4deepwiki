
$baseUrl = "http://localhost:3000/api"

function Show-Result($title, $response) {
    Write-Host "`n=== $title ===" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 5
}

try {
    # 1. Get Restaurants
    $nhaHang = Invoke-RestMethod -Uri "$baseUrl/nha-hang"
    Show-Result "LIST RESTAURANTS" $nhaHang

    # 2. Insert new food (POST)
    $newMon = @{
        id_nha_hang = 1
        ten = "TEST FOOD ITEM"
        gia = 65000
    } | ConvertTo-Json
    $resPost = Invoke-RestMethod -Uri "$baseUrl/mon-an" -Method Post -Body $newMon -ContentType "application/json"
    Show-Result "INSERT NEW FOOD" $resPost

    # Get ID of the new item
    $allMon = Invoke-RestMethod -Uri "$baseUrl/mon-an"
    $targetId = ($allMon.data | Sort-Object ID -Descending | Select-Object -First 1).ID
    Write-Host "Created Food ID: $targetId" -ForegroundColor Yellow

    # 3. Update food (PUT)
    $updateData = @{
        ten = "TEST FOOD UPDATED"
        gia = 75000
    } | ConvertTo-Json
    $resPut = Invoke-RestMethod -Uri "$baseUrl/mon-an/$targetId" -Method Put -Body $updateData -ContentType "application/json"
    Show-Result "UPDATE FOOD" $resPut

    # 4. Check Revenue (Function) - Escape & using backtick or single quotes
    $urlRev = "$baseUrl/fn/doanh-thu?id_nha_hang=1`&tu_ngay=2024-01-01`&den_ngay=2026-12-31"
    $doanhThu = Invoke-RestMethod -Uri $urlRev
    Show-Result "REVENUE FOR RESTAURANT 1" $doanhThu

    # 5. Customer Rank (Function)
    $urlRank = "$baseUrl/fn/xep-hang?id_khach_hang=1"
    $xepHang = Invoke-RestMethod -Uri $urlRank
    Show-Result "CUSTOMER RANK FOR ID 1" $xepHang

    # 6. Delete food (DELETE)
    $resDel = Invoke-RestMethod -Uri "$baseUrl/mon-an/$targetId" -Method Delete
    Show-Result "DELETE TEST FOOD" $resDel

    Write-Host "`n✅ ALL TESTS PASSED SUCCESSFULLY!" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
