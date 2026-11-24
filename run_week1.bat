@echo off
title Week1 Homework Runner
cd /d D:\xmsx

echo ==================================================
echo  Week1 Homework - Clean + Evaluate + Pack
echo  Make sure Docker Desktop is RUNNING first!
echo ==================================================
echo.

echo [1/7] Checking Docker...
docker ps >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not running. Start Docker Desktop, then run this again.
    pause
    exit /b 1
)

echo [2/7] Copying SQL scripts into hive-server2...
docker cp "D:\xmsx\sql\clean\dq_1_1.sql" hive-server2:/tmp/dq_1_1.sql
docker cp "D:\xmsx\sql\clean\dq_2_split.sql" hive-server2:/tmp/dq_2a.sql
docker cp "D:\xmsx\sql\clean\dq_2_split2.sql" hive-server2:/tmp/dq_2b.sql
docker cp "D:\xmsx\sql\clean\dq_4_1.sql" hive-server2:/tmp/dq_4a.sql
docker cp "D:\xmsx\sql\clean\dq_4_2.sql" hive-server2:/tmp/dq_4b.sql
docker cp "D:\xmsx\sql\clean\dq_6_accuracy.sql" hive-server2:/tmp/dq_6.sql
docker cp "D:\xmsx\sql\clean\step8_missing_values.sql" hive-server2:/tmp/step8.sql
docker cp "D:\xmsx\sql\clean\step9_dedup.sql" hive-server2:/tmp/step9.sql
echo     done.

echo [3/7] Completeness check ^(ods_user nulls^)...
docker exec hive-server2 beeline -u "jdbc:hive2://localhost:10000/ydsh_ods" --outputformat=csv2 --silent=true -f /tmp/dq_1_1.sql > dq_1_1_result.txt 2>&1

echo [4/7] Uniqueness check ^(primary key duplicates^)...
docker exec hive-server2 beeline -u "jdbc:hive2://localhost:10000/ydsh_ods" --outputformat=csv2 --silent=true -f /tmp/dq_2a.sql > dq_2a_result.txt 2>&1
docker exec hive-server2 beeline -u "jdbc:hive2://localhost:10000/ydsh_ods" --outputformat=csv2 --silent=true -f /tmp/dq_2b.sql > dq_2b_result.txt 2>&1

echo [5/7] Validity check ^(abnormal values^)...
docker exec hive-server2 beeline -u "jdbc:hive2://localhost:10000/ydsh_ods" --outputformat=csv2 --silent=true -f /tmp/dq_4a.sql > dq_4a_result.txt 2>&1
docker exec hive-server2 beeline -u "jdbc:hive2://localhost:10000/ydsh_ods" --outputformat=csv2 --silent=true -f /tmp/dq_4b.sql > dq_4b_result.txt 2>&1

echo [6/7] Cleaning: missing values + dedup ^(dwd_user/dwd_product/dwd_order/dwd_order_item^)...
docker exec hive-server2 beeline -u "jdbc:hive2://localhost:10000/ydsh_ods" --outputformat=csv2 --silent=true -f /tmp/step8.sql > step8_result.txt 2>&1
docker exec hive-server2 beeline -u "jdbc:hive2://localhost:10000/ydsh_ods" --outputformat=csv2 --silent=true -f /tmp/step9.sql > step9_result.txt 2>&1

echo [7/7] Accuracy check ^(business logic^)...
docker exec hive-server2 beeline -u "jdbc:hive2://localhost:10000/ydsh_ods" --outputformat=csv2 --silent=true -f /tmp/dq_6.sql > dq_6_result.txt 2>&1

echo Generating xlsx report...
python gen_xlsx.py
echo Packing zip...
python create_zip.py

echo.
echo ================ ALL DONE ================
echo Zip package : D:\xmsx\  (week1 zip file)
echo Result logs : D:\xmsx\*_result.txt
echo ===========================================
echo If any step above shows an error, send the
echo matching *_result.txt content to the AI.
echo ===========================================
pause
