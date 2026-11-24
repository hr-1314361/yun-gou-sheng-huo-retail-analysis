@echo off
title Week1 Fix Runner
cd /d D:\xmsx

echo ==================================================
echo  Re-run cleaning (step8 + step9) then repack
echo  Make sure Docker Desktop is RUNNING first!
echo ==================================================
echo.

docker ps >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not running. Start Docker Desktop, then run this again.
    pause
    exit /b 1
)

echo [1/4] Copying fixed SQL scripts into hive-server2...
docker cp "D:\xmsx\sql\clean\step8_missing_values.sql" hive-server2:/tmp/step8.sql
docker cp "D:\xmsx\sql\clean\step9_dedup.sql" hive-server2:/tmp/step9.sql
echo     done.

echo [2/4] Re-run missing value cleaning (dwd_user/dwd_product)...
docker exec hive-server2 beeline -u "jdbc:hive2://localhost:10000/ydsh_ods" --outputformat=csv2 --silent=true -f /tmp/step8.sql > step8_result.txt 2>&1

echo [3/4] Re-run dedup (dwd_order/dwd_order_item)...
docker exec hive-server2 beeline -u "jdbc:hive2://localhost:10000/ydsh_ods" --outputformat=csv2 --silent=true -f /tmp/step9.sql > step9_result.txt 2>&1

echo [4/4] Regenerate xlsx and zip...
python gen_xlsx.py
python create_zip.py

echo.
echo ================ ALL DONE ================
echo Zip package : D:\xmsx\  (week1 zip file)
echo Result logs : D:\xmsx\step8_result.txt / step9_result.txt
echo ===========================================
echo If any step above shows an error, send the
echo matching *_result.txt content to the AI.
echo ===========================================
pause
