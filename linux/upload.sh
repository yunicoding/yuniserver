#!/bin/bash

echo "================================"
echo "  YuniServer 업로드 도구"
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

# yuniserver 폴더 존재 확인
if [ ! -d "yuniserver" ]; then
    log_error "yuniserver 폴더가 존재하지 않습니다."
    log_info "먼저 ./setup.sh를 실행해주세요."
    exit 1
fi

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

# 업로드 전 확인
log_info "업로드할 폴더: yuniserver"
log_info "대상: Google Drive"
echo

# 폴더 크기 확인
log_info "폴더 크기 확인 중..."
if command -v du &> /dev/null; then
    FOLDER_SIZE=$(du -sh yuniserver | cut -f1)
    log_info "폴더 크기: $FOLDER_SIZE"
else
    log_warning "du 명령어를 사용할 수 없습니다."
fi

# 파일 개수 확인
FILE_COUNT=$(find yuniserver -type f | wc -l)
log_info "파일 개수: $FILE_COUNT개"
echo

# 업로드 확인
echo "업로드를 시작하시겠습니까? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    log_info "업로드가 취소되었습니다."
    exit 0
fi

# 업로드 시작
log_info "업로드 시작..."
START_TIME=$(date +%s)
echo "시작 시간: $(date)"
echo

# rclone sync 명령 실행 (진행률 표시)
log_info "rclone sync 명령 실행 중..."
rclone sync yuniserver googledrive:yuniserver \
    --progress \
    --stats=1s \
    --transfers=4 \
    --checkers=8 \
    --stats-one-line \
    --exclude="*.tmp" \
    --exclude="*.lock" \
    --exclude="*.log"

# 결과 확인
EXIT_CODE=$?
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo
if [ $EXIT_CODE -eq 0 ]; then
    log_success "업로드 완료!"
    echo "완료 시간: $(date)"
    echo "소요 시간: ${DURATION}초"
    echo
    
    # 업로드 확인
    log_info "업로드 확인 중..."
    if rclone lsf googledrive:yuniserver | head -n 5; then
        log_success "Google Drive에 yuniserver 폴더가 업데이트되었습니다."
    else
        log_warning "업로드 확인 중 문제가 발생했습니다."
    fi
    
    # 통계 정보
    echo
    log_info "통계 정보:"
    echo "- 업로드 폴더: yuniserver"
    echo "- 소요 시간: ${DURATION}초"
    echo "- 완료 시간: $(date)"
    
else
    log_error "업로드 실패 (종료 코드: $EXIT_CODE)"
    echo "완료 시간: $(date)"
    echo "소요 시간: ${DURATION}초"
    echo
    log_info "문제 해결 방법:"
    log_info "1. 인터넷 연결 확인"
    log_info "2. Google Drive 용량 확인"
    log_info "3. rclone 설정 재확인: rclone config"
    log_info "4. 다시 시도: ./upload.sh"
    
    exit $EXIT_CODE
fi

echo 