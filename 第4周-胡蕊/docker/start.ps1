# ============================================================
# 一键启动脚本（Windows PowerShell）
# 用法：.\start.ps1            # 构建并启动全部服务
#       .\start.ps1 -NoBuild   # 不重新构建镜像
# ============================================================
param([switch]$NoBuild)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "[!] 已生成 .env，请先修改其中的密码与 API Key，然后重新执行本脚本。" -ForegroundColor Yellow
    Write-Host "    文件位置：$PSScriptRoot\.env"
    exit 1
}

Write-Host "[1/3] 启动服务..." -ForegroundColor Cyan
if ($NoBuild) {
    docker compose up -d
} else {
    docker compose up -d --build
}

Write-Host "[2/3] 等待健康检查（最多 180 秒）..." -ForegroundColor Cyan
$deadline = (Get-Date).AddSeconds(180)
do {
    Start-Sleep -Seconds 6
    $lines = docker compose ps --format "{{.Service}}`t{{.Status}}"
} while ($lines -notmatch "healthy" -and (Get-Date) -lt $deadline)

Write-Host "[3/3] 当前服务状态：" -ForegroundColor Cyan
docker compose ps

Write-Host ""
Write-Host "Superset        : http://localhost:8088" -ForegroundColor Green
Write-Host "Streamlit 智能问数: http://localhost:8501" -ForegroundColor Green
Write-Host "ClickHouse HTTP : http://localhost:8123" -ForegroundColor Green
