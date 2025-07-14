#!/bin/bash

echo "================================"
echo "  YuniServer 다운로드 도구"
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

# rclone 설정 확인
log_info "rclone 설정 확인 중..."
if ! command -v rclone &> /dev/null; then
    log_error "rclone이 설치되지 않았습니다."
    log_info "먼저 ./setup.sh를 실행해주세요."
    exit 1
fi

if ! rclone listremotes | grep -q "googledrive:"; then
    log_error "Google Drive 연결이 설정되지 않았습니다."
    log_info "먼저 ./setup.sh를 실행해주세요."
    exit 1
fi

# Google Drive 폴더 존재 확인
log_info "Google Drive 폴더 확인 중..."
if ! rclone lsf googledrive: | grep -q "yuniserver/"; then
    log_error "Google Drive에 yuniserver 폴더가 존재하지 않습니다."
    log_info "먼저 업로드를 진행해주세요."
    exit 1
fi

# 기존 폴더 백업 확인
if [ -d "yuniserver" ]; then
    log_warning "기존 yuniserver 폴더가 존재합니다."
    echo
    echo "선택 옵션:"
    echo "1. 기존 폴더 삭제 후 다운로드"
    echo "2. 백업 후 다운로드"
    echo "3. 취소"
    echo
    read -p "선택 (1-3): " choice
    
    case $choice in
        1)
            log_info "기존 폴더 삭제 중..."
            rm -rf yuniserver
            log_success "삭제 완료"
            ;;
        2)
            log_info "백업 생성 중..."
            backup_name="yuniserver_backup_$(date +%Y%m%d_%H%M%S)"
            mv yuniserver "$backup_name"
            log_success "백업 완료: $backup_name"
            ;;
        3)
            log_info "취소되었습니다."
            exit 0
            ;;
        *)
            log_error "잘못된 선택입니다."
            exit 1
            ;;
    esac
fi

# 다운로드 전 정보 확인
log_info "다운로드 준비 중..."
log_info "소스: Google Drive"
log_info "대상: yuniserver"
echo

# Google Drive 폴더 크기 확인 (근사치)
log_info "Google Drive 폴더 확인 중..."
FILE_LIST=$(rclone lsf googledrive:yuniserver -R | head -n 10)
FILE_COUNT=$(rclone lsf googledrive:yuniserver -R | wc -l)

if [ $FILE_COUNT -gt 0 ]; then
    log_info "파일 개수: $FILE_COUNT개"
    echo
    log_info "최근 파일 목록 (최대 10개):"
    echo "$FILE_LIST" | while read -r file; do
        echo "  - $file"
    done
else
    log_warning "Google Drive 폴더가 비어있습니다."
fi

echo

# 다운로드 확인
echo "다운로드를 시작하시겠습니까? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    log_info "다운로드가 취소되었습니다."
    exit 0
fi

# 다운로드 시작
log_info "다운로드 시작..."
START_TIME=$(date +%s)
echo "시작 시간: $(date)"
echo

# rclone sync 명령 실행 (진행률 표시)
log_info "rclone sync 명령 실행 중..."
rclone sync googledrive:yuniserver yuniserver \
    --progress \
    --stats=1s \
    --transfers=4 \
    --checkers=8 \
    --stats-one-line

# 결과 확인
EXIT_CODE=$?
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo
if [ $EXIT_CODE -eq 0 ]; then
    log_success "다운로드 완료!"
    echo "완료 시간: $(date)"
    echo "소요 시간: ${DURATION}초"
    echo
    
    # 다운로드 확인
    log_info "다운로드 확인 중..."
    if [ -d "yuniserver" ]; then
        LOCAL_FILE_COUNT=$(find yuniserver -type f | wc -l)
        log_success "yuniserver 폴더가 최신 상태로 업데이트되었습니다."
        log_info "로컬 파일 개수: $LOCAL_FILE_COUNT개"
        
        # 폴더 크기 확인
        if command -v du &> /dev/null; then
            FOLDER_SIZE=$(du -sh yuniserver | cut -f1)
            log_info "폴더 크기: $FOLDER_SIZE"
        fi
    else
        log_error "yuniserver 폴더가 생성되지 않았습니다."
    fi
    
    # 통계 정보
    echo
    log_info "통계 정보:"
    echo "- 다운로드 폴더: yuniserver"
    echo "- 소요 시간: ${DURATION}초"
    echo "- 완료 시간: $(date)"
    
    # 권한 설정
    log_info "권한 설정 중..."
    find yuniserver -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    find yuniserver -name "*.jar" -exec chmod +x {} \; 2>/dev/null || true
    find yuniserver -name "*.exe" -exec chmod +x {} \; 2>/dev/null || true
    log_success "권한 설정 완료"
    
else
    log_error "다운로드 실패 (종료 코드: $EXIT_CODE)"
    echo "완료 시간: $(date)"
    echo "소요 시간: ${DURATION}초"
    echo
    log_info "문제 해결 방법:"
    log_info "1. 인터넷 연결 확인"
    log_info "2. Google Drive 접근 권한 확인"
    log_info "3. rclone 설정 재확인: rclone config"
    log_info "4. 다시 시도: ./download.sh"
    
    exit $EXIT_CODE
fi

echo 