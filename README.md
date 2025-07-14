# YuniServer 데이터 마이그레이션 도구

VM 간 게임 서버 데이터를 쉽게 이전할 수 있는 도구입니다.

## 📋 개요

- **목적**: 게임 서버 데이터를 Google Drive를 통해 VM 간 이전
- **지원 플랫폼**: Windows, Linux (Ubuntu, CentOS)
- **클라우드 저장소**: Google Drive (rclone 사용)
- **특징**: 크로스 플랫폼 호환성, 자동 권한 설정

## 🏗️ 프로젝트 구조

```
yuniscripts/
├── install.sh              # 초기 설치 스크립트
├── rclone.conf.template     # rclone 설정 템플릿
├── windows/                 # Windows용 도구
│   ├── setup.bat           # 초기 설정
│   ├── upload.bat          # 업로드 도구
│   ├── download.bat        # 다운로드 도구
│   └── gui_tool.py         # GUI 도구
└── linux/                  # Linux용 도구
    ├── setup.sh            # 초기 설정
    ├── upload.sh           # 업로드 도구
    └── download.sh         # 다운로드 도구
```

## 🚀 빠른 시작

### 1. 초기 설치

**새로운 컴퓨터에서 한 번만 실행:**

```bash
# GitHub에서 스크립트 다운로드 및 실행
curl -s https://raw.githubusercontent.com/yunicoding/yuniserver/main/install.sh | bash
```

### 2. Windows에서 사용

```cmd
# yuniscripts/windows 폴더에서 실행
setup.bat           # 초기 설정 (한 번만)
upload.bat          # 서버 데이터 업로드
download.bat        # 서버 데이터 다운로드
python gui_tool.py  # GUI 도구 실행
```

### 3. Linux에서 사용

```bash
# yuniscripts/linux 폴더에서 실행
./setup.sh     # 초기 설정 (한 번만)
./upload.sh    # 서버 데이터 업로드
./download.sh  # 서버 데이터 다운로드
```

## 📝 사용 시나리오

### 시나리오 1: 개인 PC → VM으로 이전

1. **개인 PC (Windows)**:
   ```cmd
   cd yuniscripts/windows
   setup.bat          # 초기 설정
   upload.bat         # 서버 데이터 업로드
   ```

2. **VM (Ubuntu)**:
   ```bash
   curl -s [install-url] | bash  # 스크립트 다운로드
   cd yuniscripts/linux
   ./setup.sh         # 초기 설정
   ./download.sh      # 서버 데이터 다운로드
   ```

### 시나리오 2: VM1 → VM2로 이전

1. **VM1 (Ubuntu)**:
   ```bash
   cd yuniscripts/linux
   ./upload.sh        # 최신 서버 데이터 업로드
   ```

2. **VM2 (Ubuntu)**:
   ```bash
   curl -s [install-url] | bash  # 스크립트 다운로드
   cd yuniscripts/linux
   ./setup.sh         # 초기 설정
   ./download.sh      # 서버 데이터 다운로드
   ```

## ⚙️ 설정 가이드

### Google Service Account 설정 (한 번만)

**1단계: Google Cloud Console에서 Service Account 생성**

1. [Google Cloud Console](https://console.cloud.google.com) 접속
2. 새 프로젝트 생성 또는 기존 프로젝트 선택
3. **API 및 서비스 → 라이브러리** 이동
4. **"Google Drive API"** 검색 후 활성화
5. **API 및 서비스 → 사용자 인증 정보** 이동
6. **사용자 인증 정보 만들기 → 서비스 계정** 클릭
7. 서비스 계정 이름 입력 (예: `yuniserver-drive`)
8. **키 만들기 → JSON** 선택
9. JSON 파일 다운로드 (예: `yuniserver-service-account.json`)

**2단계: Google Drive 폴더 권한 설정**

1. [Google Drive](https://drive.google.com) 접속
2. `yuniserver` 폴더 생성 (없는 경우)
3. 폴더 우클릭 → **공유** 클릭
4. JSON 파일 안의 `client_email` 주소 입력
   ```json
   "client_email": "yuniserver-drive@your-project.iam.gserviceaccount.com"
   ```
5. **편집자** 권한 부여 후 공유

### 스크립트 설정

#### Windows에서:
```cmd
cd yuniscripts/windows
setup.bat
# → JSON 키 입력 방법 선택
# → 1. 파일 선택 또는 2. 직접 붙여넣기
```

#### Linux에서:
```bash
cd yuniscripts/linux
./setup.sh
# → JSON 키 입력 방법 선택
# → 1. 파일 선택 또는 2. 직접 붙여넣기
```

### 폴더 구조

```
yuniserver/          # 서버 데이터 (Google Drive와 동기화)
├── servers/
│   ├── minecraft/   # 마인크래프트 서버
│   ├── palworld/    # 팰월드 서버
│   └── corekeeper/  # 코어키퍼 서버
└── data/            # 공용 데이터
```

## 🔧 고급 기능

### 자동 권한 설정

Linux에서 다운로드 시 자동으로 실행 파일 권한을 설정:
- `.sh` 파일: 실행 권한 부여
- `.jar` 파일: 실행 권한 부여
- `.exe` 파일: 실행 권한 부여

### 백업 기능

기존 폴더가 있을 때 자동 백업:
- **Windows**: `yuniserver_backup_[날짜]_[시간]`
- **Linux**: `yuniserver_backup_[날짜]_[시간]`

### 진행률 표시

- 실시간 전송 속도 및 진행률 표시
- 전송 통계 정보 (소요 시간, 파일 개수)
- 오류 발생 시 상세 정보 제공

## 🛠️ 문제 해결

### 일반적인 문제

1. **rclone 설치 실패**
   - 수동 설치: https://rclone.org/downloads/
   - 관리자 권한 필요할 수 있음

2. **Google Drive 인증 실패**
   - `rclone config` 재실행
   - 브라우저에서 Google 계정 재인증

3. **업로드/다운로드 실패**
   - 인터넷 연결 확인
   - Google Drive 용량 확인
   - 방화벽 설정 확인

### 로그 확인

- **Windows**: GUI 도구의 로그 창 확인
- **Linux**: 터미널 출력 확인

## 🔒 보안 고려사항

1. **rclone 설정 파일 보안**
   - 설정 파일에 인증 토큰 포함
   - 적절한 파일 권한 설정

2. **Google Drive 접근 권한**
   - 최소 권한 원칙 적용
   - 정기적인 토큰 갱신

## 📋 시스템 요구사항

### Windows
- Windows 10 이상
- PowerShell 3.0 이상
- Python 3.7 이상 (GUI 도구 사용 시)

### Linux
- Ubuntu 18.04 이상 또는 CentOS 7 이상
- curl, unzip 패키지
- 인터넷 연결

## 🆘 지원

문제가 발생하면 다음 정보를 포함하여 문의해주세요:

1. 운영체제 및 버전
2. 오류 메시지
3. 수행한 작업 단계
4. rclone 버전 (`rclone version`)

## 📜 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.

## 🔄 업데이트

최신 버전은 GitHub에서 확인할 수 있습니다:
- 스크립트 자동 업데이트는 지원하지 않음
- 새 버전 사용 시 새로 다운로드 필요

---

**개발자**: YuniServer Team  
**버전**: 1.0.0  
**마지막 업데이트**: 2024년 