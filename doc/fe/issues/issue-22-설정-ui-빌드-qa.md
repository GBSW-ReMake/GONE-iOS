# #22 설정 UI 및 활동 기록 QA 보고서

> **작업 번호**: #22<br>
> **GitHub 이슈**: [#22](https://github.com/GBSW-ReMake/GONE-iOS/issues/22)<br>
> **심각도**: Minor 🟡 (개발 환경)<br>
> **발견일**: 2026-08-08<br>
> **발견 브랜치**: `feat/22-settings-activity-ui`<br>
> **상태**: 개발자 검토 대기

---

## 증상 요약

설정 UI의 Xcode 빌드와 UI 테스트를 실행하려 했으나, 개발 환경에 사용 가능한 iOS Simulator 런타임이 없어 에셋 카탈로그 단계에서 빌드가 중단됩니다.

## 재현 방법

1. Xcode 개발자 도구를 지정합니다.
2. `xcodebuild build -project GONE/GONE.xcodeproj -scheme GONE -sdk iphonesimulator -destination 'generic/platform=iOS Simulator'`를 실행합니다.
3. `No available simulator runtimes` 오류를 확인합니다.

## 예상 동작

Simulator에서 설정 탭의 정상·빈·오류 상태, 최근 활동 탭 이동, 로그아웃 확인 대화상자 및 Dynamic Type·다크 모드를 검증할 수 있어야 합니다.

## 실제 동작

`Assets.xcassets: error: No available simulator runtimes for platform iphonesimulator. SimServiceContext supportedRuntimes=[]` 오류로 빌드와 자동 테스트가 중단됩니다.

## 증빙

변경 파일의 `git diff --check`는 통과했습니다. 빌드 로그에는 Settings 관련 Swift 컴파일 오류가 출력되지 않았으며, Simulator 서비스 오류로 에셋 컴파일 단계에서 실패했습니다.

## 원인 분석

변경 코드가 아닌 CoreSimulator 서비스 및 설치된 Simulator 런타임 부재가 원인입니다.

## 수정 내용

코드 수정 대상이 아닙니다. Xcode의 iOS Simulator 런타임을 복구한 뒤 아래 항목을 재검증해야 합니다.

- `SettingsViewModelTests`
- 계정 카드 및 앱 정보 메뉴 미표시
- 최근 활동 정상·빈 상태와 기능 탭 이동
- 알림 설정·문의하기 안내와 로그아웃 확인 UI
- 다크 모드, Dynamic Type, VoiceOver

## 관련 파일

- `GONE/GONE/Features/Settings/Presentation/SettingsView.swift`: 설정 화면과 상호작용 UI
- `GONE/GONE/Features/Settings/Presentation/SettingsViewModel.swift`: 데이터 상태 관리
- `GONE/GONETests/SettingsViewModelTests.swift`: ViewModel 단위 테스트
