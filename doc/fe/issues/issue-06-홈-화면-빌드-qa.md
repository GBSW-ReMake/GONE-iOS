# Issue #6 홈 화면 빌드 및 QA 기록

> **작성일**: 2026-08-04
> **브랜치**: `feat/6-home`
> **상태**: 빌드 환경 확인 필요

---

## 검증 결과

- `git diff --check`: 통과
- 홈 ViewModel 성공·실패 상태 전환 테스트 추가 완료
- 이미지 에셋 3종의 `Contents.json`: JSON 형식 검증 통과
- `xcodebuild`: 실행 불가

## 확인된 환경 이슈

```text
xcode-select: error: tool 'xcodebuild' requires Xcode,
but active developer directory '/Library/Developer/CommandLineTools'
is a command line tools instance
```

현재 작업 환경에는 Xcode 전체가 설치·선택되어 있지 않아 앱 빌드, XCTest 실행, 시뮬레이터 UI QA를 수행할 수 없습니다.

## 개발자 확인 요청

Xcode 설치 후 활성 개발자 디렉터리를 Xcode로 설정한 환경에서 아래 명령으로 빌드와 테스트를 재검증해야 합니다.

```bash
xcodebuild \
  -project GONE/GONE.xcodeproj \
  -scheme GONE \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

## 미확정 사항

- 홈 대시보드 API 계약 및 로그인 사용자 정보 전달 방식
- 탭 아이콘 SVG의 최종 선택·비선택 색상 처리
- 홈 이외 탭의 실제 화면 및 홈 카드 상세 이동 규칙
