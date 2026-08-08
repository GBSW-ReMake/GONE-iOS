# #20 홈 화면 신청 현황 및 학사일정 개선 QA 보고서

> **작업 번호**: #20<br>
> **GitHub 이슈**: [#20](https://github.com/GBSW-ReMake/GONE-iOS/issues/20)<br>
> **심각도**: Minor 🟡 (개발 환경)<br>
> **발견일**: 2026-08-08<br>
> **발견 브랜치**: `feat/20-home-dashboard-improvement`<br>
> **상태**: 개발자 검토 대기

---

## 증상 요약

현재 개발 환경에 iOS Simulator 런타임이 없어 앱 빌드와 UI 테스트를 완료할 수 없습니다.

## 재현 방법

1. Xcode 26 개발자 도구를 지정합니다.
2. `xcodebuild build -project GONE/GONE.xcodeproj -scheme GONE -sdk iphonesimulator -destination 'generic/platform=iOS Simulator'`를 실행합니다.
3. 에셋 카탈로그 컴파일 단계에서 Simulator 런타임 없음 오류를 확인합니다.

## 예상 동작

설치된 iOS Simulator 런타임을 대상으로 앱을 빌드하고 `GONETests` 및 화면 QA를 실행할 수 있어야 합니다.

## 실제 동작

`Assets.xcassets: error: No available simulator runtimes for platform iphonesimulator. SimServiceContext supportedRuntimes=[]` 오류로 에셋 카탈로그 컴파일이 중단됩니다.

## 증빙

다음 명령에서 동일하게 재현했습니다.

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild build -project GONE/GONE.xcodeproj -scheme GONE \
-sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
-derivedDataPath /private/tmp/gone-home-dashboard-derived \
CODE_SIGNING_ALLOWED=NO
```

기기용 빌드도 Swift 컴파일 시작 후, 동일한 Simulator 서비스 오류를 원인으로 에셋 카탈로그 단계에서 실패했습니다. 이번 변경 파일에서 Swift 컴파일 오류는 출력되지 않았습니다.

## 원인 분석

프로젝트 코드나 변경한 에셋의 문제가 아니라, 실행 환경의 CoreSimulator 서비스가 연결되지 않고 지원 런타임 목록이 비어 있는 상태입니다.

## 수정 내용

코드 수정 대상이 아닙니다. Xcode Settings의 Platforms에서 iOS Simulator 런타임을 설치하거나 CoreSimulator 서비스를 정상화한 뒤 아래 항목을 재검증해야 합니다.

- `GONETests/HomeViewModelTests`
- 홈 탭의 상점 미표시
- 학사일정 월 이동 및 빈 상태
- 실습실·외출·스쿨캠핑 신청 카드 탭 이동
- 다크 모드, Dynamic Type, VoiceOver

## 관련 파일

- `GONE/GONE/Features/Home/Presentation/HomeView.swift`: 학사일정 UI와 신청 현황 상태·탭 동작
- `GONE/GONE/Features/AppTab/Presentation/AppTabView.swift`: 세 기능 상태 전달과 탭 이동
- `GONE/GONETests/HomeViewModelTests.swift`: 학사일정 월 이동 단위 테스트
