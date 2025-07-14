#!/bin/bash

echo "================================"
echo "  YuniServer 초기 설치 스크립트"
echo "================================"
echo

# 운영체제 확인
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    echo "✓ 운영체제: Linux"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS="windows"
    echo "✓ 운영체제: Windows"
else
    echo "❌ 지원하지 않는 운영체제입니다."
    exit 1
fi

# yuniscripts 폴더 생성
echo "📁 yuniscripts 폴더 생성 중..."
mkdir -p yuniscripts

# GitHub에서 스크립트 다운로드
echo "📥 GitHub에서 스크립트 다운로드 중..."
GITHUB_BASE="https://raw.githubusercontent.com/yunicoding/yuniserver/main"

# 공통 파일 다운로드
curl -s "$GITHUB_BASE/rclone.conf.template" -o "yuniscripts/rclone.conf.template"

if [[ "$OS" == "linux" ]]; then
    # Linux 스크립트 다운로드
    mkdir -p yuniscripts/linux
    curl -s "$GITHUB_BASE/linux/setup.sh" -o "yuniscripts/linux/setup.sh"
    curl -s "$GITHUB_BASE/linux/upload.sh" -o "yuniscripts/linux/upload.sh"
    curl -s "$GITHUB_BASE/linux/download.sh" -o "yuniscripts/linux/download.sh"
    
    # 실행 권한 부여
    chmod +x yuniscripts/linux/*.sh
    
    echo "✓ Linux 스크립트 다운로드 완료"
    echo ""
    echo "다음 단계:"
    echo "1. cd yuniscripts/linux"
    echo "2. ./setup.sh"
    
elif [[ "$OS" == "windows" ]]; then
    # Windows 스크립트 다운로드
    mkdir -p yuniscripts/windows
    curl -s "$GITHUB_BASE/windows/setup.bat" -o "yuniscripts/windows/setup.bat"
    curl -s "$GITHUB_BASE/windows/upload.bat" -o "yuniscripts/windows/upload.bat"
    curl -s "$GITHUB_BASE/windows/download.bat" -o "yuniscripts/windows/download.bat"
    curl -s "$GITHUB_BASE/windows/gui_tool.py" -o "yuniscripts/windows/gui_tool.py"
    
    echo "✓ Windows 스크립트 다운로드 완료"
    echo ""
    echo "다음 단계:"
    echo "1. cd yuniscripts\\windows"
    echo "2. setup.bat 실행"
fi

echo ""
echo "🎉 초기 설치 완료!"
echo "yuniscripts 폴더에 모든 도구가 준비되었습니다." 