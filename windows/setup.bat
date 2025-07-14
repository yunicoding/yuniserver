@echo off
chcp 65001 > nul
echo ================================
echo   YuniServer Windows 설정
echo ================================
echo.

REM 관리자 권한 확인
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 경고: 관리자 권한이 필요할 수 있습니다.
    echo.
)

REM rclone 설치 확인
echo 📦 rclone 설치 확인 중...
rclone version >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ rclone이 설치되지 않았습니다.
    echo 📥 rclone 자동 설치 중...
    
    REM rclone 다운로드 및 설치
    powershell -Command "& {Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser; iex ((New-Object System.Net.WebClient).DownloadString('https://rclone.org/install.ps1'))}"
    
    if %errorLevel% neq 0 (
        echo ❌ rclone 자동 설치 실패
        echo 수동 설치: https://rclone.org/downloads/
        pause
        exit /b 1
    )
    
    echo ✓ rclone 설치 완료
) else (
    echo ✓ rclone이 이미 설치되어 있습니다.
)

REM rclone 설정 확인
echo 🔧 rclone 설정 확인 중...
rclone listremotes | findstr googledrive >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ Google Drive 연결이 설정되지 않았습니다.
    echo.
    echo 📋 Google Service Account JSON 키로 자동 설정합니다.
    echo Google Cloud Console에서 생성한 Service Account JSON 키가 필요합니다.
    echo.
    
    REM JSON 키 입력 방법 선택
    echo JSON 키 입력 방법을 선택하세요:
    echo 1. 파일에서 읽기 (service-account.json)
    echo 2. 직접 붙여넣기 (PowerShell 사용)
    set /p input_method=선택 (1-2): 
    
    if "%input_method%"=="1" (
        REM 파일에서 읽기
        if exist "service-account.json" (
            echo ✓ service-account.json 파일을 찾았습니다.
            set SERVICE_ACCOUNT_FILE=%cd%\service-account.json
        ) else (
            echo ❌ service-account.json 파일이 없습니다.
            echo Google Cloud Console에서 Service Account JSON 키를 다운로드하고
            echo 파일명을 'service-account.json'으로 변경한 후 이 폴더에 복사하세요.
            pause
            exit /b 1
        )
    ) else if "%input_method%"=="2" (
        REM PowerShell로 JSON 입력 받기
        echo JSON 키를 클립보드에서 읽어옵니다...
        echo JSON 전체 내용을 복사한 후 계속하세요.
        pause
        
        REM PowerShell로 클립보드에서 JSON 읽기
        powershell -Command "Get-Clipboard | Out-File -FilePath temp-service-account.json -Encoding UTF8"
        
        REM JSON 유효성 간단 확인
        findstr "service_account" temp-service-account.json >nul 2>&1
        if %errorLevel% neq 0 (
            echo ❌ 올바른 Service Account JSON 형식이 아닙니다.
            echo JSON에 "type": "service_account"가 포함되어야 합니다.
            del temp-service-account.json 2>nul
            pause
            exit /b 1
        )
        
        set SERVICE_ACCOUNT_FILE=%cd%\temp-service-account.json
        echo ✓ JSON 키가 임시 파일에 저장되었습니다.
    ) else (
        echo ❌ 잘못된 선택입니다.
        pause
        exit /b 1
    )
    
    REM rclone 설정 디렉토리 생성
    if not exist "%USERPROFILE%\.config\rclone" mkdir "%USERPROFILE%\.config\rclone"
    
    REM rclone 설정 파일 생성
    echo 📋 rclone 설정 파일 생성 중...
    (
        echo [googledrive]
        echo type = drive
        echo service_account_file = %SERVICE_ACCOUNT_FILE%
    ) > "%USERPROFILE%\.config\rclone\rclone.conf"
    
    REM 설정 완료 확인
    echo 🔧 Google Drive 연결 테스트 중...
    rclone listremotes | findstr googledrive >nul 2>&1
    if %errorLevel% neq 0 (
        echo ❌ Google Drive 설정이 완료되지 않았습니다.
        pause
        exit /b 1
    )
    
    REM 테스트 접속
    rclone lsf googledrive: >nul 2>&1
    if %errorLevel% neq 0 (
        echo ⚠️  Google Drive 접근 권한을 확인하세요.
        echo Service Account 이메일을 Google Drive 폴더에 편집자로 추가했는지 확인하세요.
    ) else (
        echo ✓ Google Drive 접근 권한 확인 완료
    )
    
    echo ✓ Google Drive 연결 완료
) else (
    echo ✓ Google Drive가 이미 설정되어 있습니다.
)

REM yuniserver 폴더 생성
echo 📁 yuniserver 폴더 생성 중...
if not exist "yuniserver" (
    mkdir yuniserver
    echo ✓ yuniserver 폴더 생성 완료
) else (
    echo ✓ yuniserver 폴더가 이미 존재합니다.
)

REM Google Drive에 yuniserver 폴더 생성
echo 📂 Google Drive에 yuniserver 폴더 생성 중...
rclone mkdir googledrive:yuniserver 2>nul
echo ✓ Google Drive 폴더 확인 완료

echo.
echo 🎉 설정 완료!
echo.
echo 사용 가능한 명령어:
echo   upload.bat    - yuniserver 폴더를 Google Drive에 업로드
echo   download.bat  - Google Drive에서 yuniserver 폴더 다운로드
echo   gui_tool.py   - GUI 도구 실행
echo.
pause 