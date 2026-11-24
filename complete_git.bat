@echo off
title Git Init Runner
cd /d D:\xmsx

echo ==================================================
echo  Git init + commit (feat/fix/docs convention)
echo ==================================================
echo.

where git >nul 2>&1
if errorlevel 1 (
    echo ERROR: git not found in PATH. Install Git for Windows first.
    pause
    exit /b 1
)

git init
git config user.name "hurui"
git config user.email "2786247380@qq.com"

echo Staging files (gitignored data/tools are excluded)...
git add .

echo Committing...
git commit -m "feat: init week1 project (docker env, ods tables, dq evaluation, cleaning)"

echo.
echo ---- Commit history ----
git log --oneline
echo -------------------------
echo.
echo Done. Repo: D:\xmsx\.git
pause
