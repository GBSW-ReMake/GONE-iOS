# 회원가입 입력 상태 및 전환 UX QA 이슈 보고서

> **작업 번호**: #02
> **GitHub 이슈**: [#4](https://github.com/GBSW-ReMake/GONE-iOS/issues/4)
> **심각도**: Critical 🔴  
> **발견일**: 2026-08-04  
> **발견 브랜치**: `feat/4-signup`  
> **상태**: 수정 완료 · 실기기 재검토 대기

---

## 증상 요약

회원가입 화면 진입 또는 전화번호 입력 중 `Thread 1: EXC_BAD_ACCESS`가 발생했고, 단계·화면 전환이 즉시 바뀌어 흐름이 부자연스러웠습니다. 비밀번호 확인 불일치 상태에서도 다음 CTA가 활성화됐습니다.

## 재현 방법

1. 로그인 화면에서 `회원가입`을 선택합니다.
2. 전화번호 입력 단계에서 숫자를 입력합니다.
3. 비밀번호와 비밀번호 확인에 서로 다른 값을 입력합니다.
4. 화면 전환과 CTA 상태를 확인합니다.

## 예상 동작

- 회원가입 진입과 단계 이동이 자연스러운 전환 효과와 함께 동작합니다.
- 전화번호 입력이 안정적으로 포맷됩니다.
- 비밀번호와 비밀번호 확인이 모두 입력되고 일치할 때만 다음 CTA가 활성화됩니다.
- 뒤로가기는 시스템 글래스 버튼, 인증번호 받기는 테두리 버튼으로 표시됩니다.

## 실제 동작

- 실기기에서 `EXC_BAD_ACCESS`가 보고됐습니다.
- 전환 효과가 거의 보이지 않아 단계가 끊겨 보였습니다.
- 비밀번호 확인이 서로 달라도 다음 CTA가 활성화됐습니다.
- 뒤로가기와 인증번호 받기 버튼이 요청된 표현과 달랐습니다.

## 원인 분석

`SignupViewModel.phoneNumber`의 관찰 프로퍼티가 `didSet` 내부에서 동일 프로퍼티를 다시 대입했습니다. 이 패턴은 `@Published` 알림과 결합될 때 재진입·메모리 접근 문제를 유발할 수 있어 제거했습니다.

CTA 활성화 조건은 두 필드가 비어 있지 않은지만 확인하고, 일치 여부를 포함하지 않았습니다. 화면 전환에는 상태 변경 애니메이션만 있었고 각 뷰의 삽입·제거 전환 정의가 없었습니다.

## 수정 내용

- 전화번호 입력을 `updatePhoneNumber(_:)` 단방향 메서드와 `Binding`으로 처리했습니다.
- 로그인 ↔ 회원가입, 회원가입 단계 전환에 이동·투명도 전환과 `snappy` 애니메이션을 적용했습니다.
- 비밀번호 CTA 조건을 `비어 있지 않음 && 두 값 일치`로 강화했습니다.
- 뒤로가기 버튼에 시스템 글래스 스타일을 적용했습니다.
- 인증번호 받기를 테두리형 시스템 버튼으로 변경했습니다.
- 비밀번호 CTA와 전화번호 포맷 단위 테스트를 보완했습니다.

## 증빙

다음 테스트가 완료됐습니다.

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project GONE/GONE.xcodeproj \
  -scheme GONE \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:GONETests -quiet
```

## 관련 파일

- `GONE/GONE/Features/Auth/Presentation/Signup/SignupViewModel.swift`: 단방향 전화번호 포맷과 CTA 활성화 조건
- `GONE/GONE/Features/Auth/Presentation/Signup/SignupView.swift`: 단계 전환·글래스 뒤로가기 버튼
- `GONE/GONE/ContentView.swift`: 로그인·회원가입 화면 전환
- `GONE/GONE/DesignSystem/Components/GONEUnderlinedTextField.swift`: 테두리형 인증번호 버튼
- `GONE/GONETests/SignupViewModelTests.swift`: 상태 검증 테스트
