@echo off
chcp 65001 > nul
echo ================================
echo   YuniServer 다운로드 도구
echo ================================
echo.

REM rclone 설정 확인
echo 🔧 rclone 설정 확인 중...
rclone listremotes | findstr googledrive >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ Google Drive 연결이 설정되지 않았습니다.
    echo 먼저 setup.bat을 실행해주세요.
    pause
    exit /b 1
)

REM Google Drive 폴더 존재 확인
echo 📂 Google Drive 폴더 확인 중...
rclone lsf googledrive: | findstr yuniserver >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ Google Drive에 yuniserver 폴더가 존재하지 않습니다.
    echo 먼저 업로드를 진행해주세요.
    pause
    exit /b 1
)

REM 기존 폴더 백업 확인
if exist "yuniserver" (
    echo ⚠️  기존 yuniserver 폴더가 존재합니다.
    echo.
    echo 선택 옵션:
    echo 1. 기존 폴더 삭제 후 다운로드
    echo 2. 백업 후 다운로드
    echo 3. 취소
    echo.
    set /p choice=선택 (1-3): 
    
    if "%choice%"=="1" (
        echo 🗑️  기존 폴더 삭제 중...
        rmdir /s /q yuniserver
        echo ✓ 삭제 완료
    ) else if "%choice%"=="2" (
        echo 💾 백업 생성 중...
        set backup_name=yuniserver_backup_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%
        set backup_name=%backup_name: =0%
        move yuniserver %backup_name%
        echo ✓ 백업 완료: %backup_name%
    ) else (
        echo 취소되었습니다.
        pause
        exit /b 0
    )
)

REM 다운로드 시작
echo 📥 다운로드 시작...
echo 시작 시간: %time%
echo 소스: Google Drive
echo 대상: yuniserver
echo.

REM rclone sync 명령 실행 (진행률 표시)
rclone sync googledrive:yuniserver yuniserver --progress --stats=1s --transfers=4 --checkers=8

if %errorLevel% neq 0 (
    echo ❌ 다운로드 실패
    pause
    exit /b 1
)

echo.
echo ✓ 다운로드 완료!
echo 완료 시간: %time%
echo.
echo 📁 yuniserver 폴더가 최신 상태로 업데이트되었습니다.
echo.
pause 