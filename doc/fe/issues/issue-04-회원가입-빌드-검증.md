# 회원가입 빌드 검증 이슈 보고서

> **작업 번호**: #02
> **GitHub 이슈**: [#4](https://github.com/GBSW-ReMake/GONE-iOS/issues/4)
> **심각도**: Major 🟠  
> **발견일**: 2026-08-04  
> **발견 브랜치**: `feat/4-signup`  
> **상태**: 해결 완료

---

## 증상 요약

회원가입 UI를 추가한 직후 빌드에서 공용 입력 필드의 괄호 위치, `Combine` import, 전화번호 포맷 반환 누락으로 컴파일이 실패했습니다.

## 재현 방법

1. `feat/4-signup` 브랜치에서 iPhone 16 시뮬레이터 대상으로 테스트를 실행합니다.
2. 회원가입 화면과 `SignupViewModel`을 포함해 컴파일합니다.
3. Swift 컴파일 오류를 확인합니다.

## 예상 동작

회원가입 화면·공용 입력 컴포넌트·ViewModel이 컴파일되고, 단계 전환과 전화번호 포맷 테스트가 통과합니다.

## 실제 동작

초기 구현에서 아래 컴파일 오류가 순차적으로 발생했습니다.

- `GONEUnderlinedTextField`의 여분 닫는 괄호로 인한 선언 오류
- `SignupViewModel`의 `ObservableObject`, `@Published`에 필요한 `Combine` import 누락
- 전화번호 포맷 `switch` 결과의 반환 누락

## 증빙

`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project GONE/GONE.xcodeproj -scheme GONE -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`

수정 후 위 명령이 경고 없이 종료 코드 0으로 완료되었습니다.

## 원인 분석

공용 입력 필드에 우측 액션을 추가하는 과정에서 뷰 계층의 닫는 괄호가 중복됐습니다. 신규 ViewModel은 로그인 ViewModel의 의존성 패턴을 완전히 반영하지 못했고, 포맷 함수의 다중 분기 반환도 누락됐습니다.

## 수정 내용

- 공용 입력 필드의 여분 괄호를 제거했습니다.
- `SignupViewModel`에 `Combine`을 import했습니다.
- 전화번호 포맷 함수가 모든 분기에서 문자열을 반환하도록 수정했습니다.
- `SignupViewModelTests`로 아이디 단계 전환·비밀번호 불일치·전화번호 포맷을 검증했습니다.

## 관련 파일

- `GONE/GONE/DesignSystem/Components/GONEUnderlinedTextField.swift`: 전화번호 인증번호 발송 액션 지원 및 컴파일 오류 수정
- `GONE/GONE/Features/Auth/Presentation/Signup/SignupViewModel.swift`: 단계 상태·입력 검증·전화번호 포맷 구현
- `GONE/GONETests/SignupViewModelTests.swift`: 회원가입 ViewModel 단위 테스트
