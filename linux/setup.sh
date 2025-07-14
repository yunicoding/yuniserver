#!/bin/bash

echo "================================"
echo "  YuniServer Linux 설정"
echo "================================"
echo

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 함수 정의
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 운영체제 확인
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    log_info "운영체제: Linux"
    
    # 배포판 확인
    if command -v apt-get &> /dev/null; then
        PACKAGE_MANAGER="apt-get"
        UPDATE_CMD="sudo apt-get update"
        INSTALL_CMD="sudo apt-get install -y"
    elif command -v yum &> /dev/null; then
        PACKAGE_MANAGER="yum"
        UPDATE_CMD="sudo yum update"
        INSTALL_CMD="sudo yum install -y"
    else
        log_error "지원하지 않는 패키지 관리자입니다."
        exit 1
    fi
else
    log_error "Linux 운영체제에서만 실행 가능합니다."
    exit 1
fi

# 필수 패키지 확인 및 설치
log_info "필수 패키지 확인 중..."

# curl 확인
if ! command -v curl &> /dev/null; then
    log_warning "curl이 설치되지 않았습니다. 설치 중..."
    $UPDATE_CMD
    $INSTALL_CMD curl
    
    if ! command -v curl &> /dev/null; then
        log_error "curl 설치 실패"
        exit 1
    fi
    log_success "curl 설치 완료"
else
    log_success "curl이 이미 설치되어 있습니다."
fi

# unzip 확인
if ! command -v unzip &> /dev/null; then
    log_warning "unzip이 설치되지 않았습니다. 설치 중..."
    $INSTALL_CMD unzip
    
    if ! command -v unzip &> /dev/null; then
        log_error "unzip 설치 실패"
        exit 1
    fi
    log_success "unzip 설치 완료"
else
    log_success "unzip이 이미 설치되어 있습니다."
fi

# rclone 설치 확인
log_info "rclone 설치 확인 중..."
if ! command -v rclone &> /dev/null; then
    log_warning "rclone이 설치되지 않았습니다."
    log_info "rclone 자동 설치 중..."
    
    # rclone 설치
    curl https://rclone.org/install.sh | sudo bash
    
    if ! command -v rclone &> /dev/null; then
        log_error "rclone 자동 설치 실패"
        log_info "수동 설치 방법:"
        log_info "1. https://rclone.org/downloads/ 방문"
        log_info "2. Linux 버전 다운로드 및 설치"
        exit 1
    fi
    
    log_success "rclone 설치 완료"
else
    log_success "rclone이 이미 설치되어 있습니다."
fi

# rclone 버전 확인
RCLONE_VERSION=$(rclone version | head -n 1)
log_info "rclone 버전: $RCLONE_VERSION"

# rclone 설정 확인
log_info "rclone 설정 확인 중..."
if rclone listremotes | grep -q "googledrive:"; then
    log_success "Google Drive가 이미 설정되어 있습니다."
else
    log_warning "Google Drive 연결이 설정되지 않았습니다."
    echo
    log_info "Google Service Account JSON 키로 자동 설정합니다."
    log_info "Google Cloud Console에서 생성한 Service Account JSON 키가 필요합니다."
    echo
    
    # JSON 키 입력 방법 선택
    echo "JSON 키 입력 방법을 선택하세요:"
    echo "1. 파일에서 읽기 (service-account.json)"
    echo "2. 직접 붙여넣기"
    read -p "선택 (1-2): " input_method
    
    case $input_method in
        1)
            # 파일에서 읽기
            if [ -f "service-account.json" ]; then
                log_success "service-account.json 파일을 찾았습니다."
                SERVICE_ACCOUNT_FILE="$(pwd)/service-account.json"
            else
                log_error "service-account.json 파일이 없습니다."
                log_info "Google Cloud Console에서 Service Account JSON 키를 다운로드하고"
                log_info "파일명을 'service-account.json'으로 변경한 후 이 폴더에 복사하세요."
                exit 1
            fi
            ;;
        2)
            # 직접 입력
            log_info "Google Service Account JSON 키를 붙여넣으세요:"
            log_info "(JSON 전체 내용을 복사해서 Enter를 누른 후 Ctrl+D로 완료)"
            echo
            
            # 여러 줄 입력 받기
            JSON_CONTENT=$(cat)
            
            # JSON 유효성 간단 확인
            if echo "$JSON_CONTENT" | grep -q '"type": "service_account"'; then
                # 임시 파일에 저장
                echo "$JSON_CONTENT" > "temp-service-account.json"
                SERVICE_ACCOUNT_FILE="$(pwd)/temp-service-account.json"
                log_success "JSON 키가 임시 파일에 저장되었습니다."
            else
                log_error "올바른 Service Account JSON 형식이 아닙니다."
                log_info "JSON에 \"type\": \"service_account\"가 포함되어야 합니다."
                exit 1
            fi
            ;;
        *)
            log_error "잘못된 선택입니다."
            exit 1
            ;;
    esac
    
    # rclone 설정 디렉토리 생성
    mkdir -p ~/.config/rclone
    
    # rclone 설정 파일 생성
    log_info "rclone 설정 파일 생성 중..."
    cat > ~/.config/rclone/rclone.conf << EOF
[googledrive]
type = drive
service_account_file = $SERVICE_ACCOUNT_FILE
EOF
    
    # 설정 완료 확인
    log_info "Google Drive 연결 테스트 중..."
    if rclone listremotes | grep -q "googledrive:"; then
        log_success "Google Drive 연결 완료"
        
        # 테스트 접속
        if rclone lsf googledrive: > /dev/null 2>&1; then
            log_success "Google Drive 접근 권한 확인 완료"
        else
            log_warning "Google Drive 접근 권한을 확인하세요."
            log_info "Service Account 이메일을 Google Drive 폴더에 편집자로 추가했는지 확인하세요."
        fi
    else
        log_error "Google Drive 설정이 완료되지 않았습니다."
        exit 1
    fi
fi

# yuniserver 폴더 생성
log_info "yuniserver 폴더 생성 중..."
if [ ! -d "yuniserver" ]; then
    mkdir yuniserver
    log_success "yuniserver 폴더 생성 완료"
else
    log_success "yuniserver 폴더가 이미 존재합니다."
fi

# Google Drive에 yuniserver 폴더 생성
log_info "Google Drive에 yuniserver 폴더 생성 중..."
rclone mkdir googledrive:yuniserver 2>/dev/null || true
log_success "Google Drive 폴더 확인 완료"

# 권한 설정
log_info "스크립트 권한 설정 중..."
chmod +x upload.sh
chmod +x download.sh
log_success "권한 설정 완료"

echo
log_success "설정 완료!"
echo
echo "사용 가능한 명령어:"
echo "  ./upload.sh    - yuniserver 폴더를 Google Drive에 업로드"
echo "  ./download.sh  - Google Drive에서 yuniserver 폴더 다운로드"
echo
echo "테스트 명령어:"
echo "  rclone ls googledrive:    - Google Drive 내용 확인"
echo "  rclone lsf googledrive:   - Google Drive 폴더 목록 확인"
echo 