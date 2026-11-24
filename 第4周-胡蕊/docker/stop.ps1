# ============================================================
# 停止服务（Windows PowerShell）
# 用法：.\stop.ps1           # 停止并删除容器，保留数据卷
#       .\stop.ps1 -Clean    # 同时删除数据卷（会清空数据）
# ============================================================
param([switch]$Clean)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if ($Clean) {
    Write-Host "[!] 将删除全部数据卷，数据不可恢复，5 秒内可 Ctrl+C 取消..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    docker compose down -v
} else {
    docker compose down
}
Write-Host "[OK] 服务已停止" -ForegroundColor Green
