@echo off
chcp 65001 > nul
echo ================================
echo   YuniServer 업로드 도구
echo ================================
echo.

REM yuniserver 폴더 존재 확인
if not exist "yuniserver" (
    echo ❌ yuniserver 폴더가 존재하지 않습니다.
    echo 먼저 setup.bat을 실행해주세요.
    pause
    exit /b 1
)

REM rclone 설정 확인
echo 🔧 rclone 설정 확인 중...
rclone listremotes | findstr googledrive >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ Google Drive 연결이 설정되지 않았습니다.
    echo 먼저 setup.bat을 실행해주세요.
    pause
    exit /b 1
)

REM 업로드 전 확인
echo 📁 업로드할 폴더: yuniserver
echo 📂 대상: Google Drive
echo.

REM 폴더 크기 확인
echo 📊 폴더 크기 확인 중...
for /f "tokens=3" %%a in ('dir yuniserver /s /-c ^| find "파일"') do set size=%%a
echo 폴더 크기: %size% bytes
echo.

REM 업로드 시작
echo 📤 업로드 시작...
echo 시작 시간: %time%
echo.

REM rclone sync 명령 실행 (진행률 표시)
rclone sync yuniserver googledrive:yuniserver --progress --stats=1s --transfers=4 --checkers=8

if %errorLevel% neq 0 (
    echo ❌ 업로드 실패
    pause
    exit /b 1
)

echo.
echo ✓ 업로드 완료!
echo 완료 시간: %time%
echo.
echo 📂 Google Drive에 yuniserver 폴더가 업데이트되었습니다.
echo.
pause 