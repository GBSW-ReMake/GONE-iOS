# 24 역할 선택 및 스플래시 화면 QA 보고서

> **작업 번호**: #23<br>
> **GitHub 이슈**: [#24](https://github.com/GBSW-ReMake/GONE-iOS/issues/24)<br>
> **심각도**: Minor 🟡<br>
> **발견일**: 2026-08-10<br>
> **발견 브랜치**: `feat/24-role-selection-splash`<br>
> **상태**: 환경 확인 필요

---

## 증상 요약

현재 개발 환경에 iOS Simulator 런타임이 없어 Xcode가 Asset Catalog를 컴파일하지 못합니다.

## 재현 방법

1. Xcode 26의 `xcodebuild`로 GONE 스킴을 빌드합니다.
2. `generic/platform=iOS Simulator`를 대상으로 지정합니다.
3. Asset Catalog 컴파일 단계에서 `No available simulator runtimes` 오류를 확인합니다.

## 예상 동작

설치된 iOS Simulator 런타임을 사용해 앱을 빌드하고, 역할 선택과 스플래시 화면을 시뮬레이터에서 확인합니다.

## 실제 동작

Swift 컴파일 명령은 실행됐지만, Simulator 런타임이 없어 `CompileAssetCatalogVariant` 단계에서 빌드가 중단됐습니다.

## 증빙

```text
Assets.xcassets: error: No available simulator runtimes for platform iphonesimulator.
SimServiceContext supportedRuntimes=[]
```

## 원인 분석

로컬 Xcode의 CoreSimulatorService가 사용할 수 있는 iOS Simulator 런타임을 찾지 못합니다. 변경한 Swift 소스에서 발생한 컴파일 오류는 빌드 출력에 포함되지 않았습니다.

## 수정 내용

코드 수정 대상이 아닙니다. Xcode에서 iOS Simulator 런타임을 설치하거나 CoreSimulatorService를 복구한 후 화면 전환과 접근성 동작을 다시 확인해야 합니다.

## 관련 파일

- `GONE/ContentView.swift`: 스플래시와 역할 선택 라우팅을 추가했습니다.
- `GONE/Features/Auth/Presentation/Splash/SplashView.swift`: 로고 축소·페이드 전환을 추가했습니다.
- `GONE/Features/Auth/Presentation/RoleSelection/RoleSelectionView.swift`: 역할 선택 UI를 추가했습니다.
