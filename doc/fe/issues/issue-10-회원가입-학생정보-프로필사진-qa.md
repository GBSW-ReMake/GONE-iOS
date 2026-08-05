# 회원가입 학생 정보·프로필 사진 QA 보고서

> **작업 번호**: #10
> **GitHub 이슈**: [#10](https://github.com/GBSW-ReMake/GONE-iOS/issues/10)
> **심각도**: 없음
> **발견일**: 2026-08-05
> **발견 브랜치**: `feat/10-signup-profile`
> **상태**: 테스트 통과 · 화면 수동 검증 대기

---

## QA 범위

1. 아이디·비밀번호·전화번호 인증 이후 학번·이름 단계로 이동합니다.
2. 학번 또는 이름이 비어 있을 때 CTA가 비활성화되고, 제출 시 해당 오류 문구가 표시되는지 확인합니다.
3. 두 입력값이 모두 있을 때 프로필 사진 단계로 이동하는지 확인합니다.
4. 프로필 사진을 선택하지 않아도 `시작하기` CTA가 활성화되는지 확인합니다.
5. 입력 폼 포커스와 오류 시 라벨 색상 우선순위를 확인합니다.

## 자동화 검증

다음 명령을 성공적으로 실행했습니다.

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project GONE/GONE.xcodeproj \
  -scheme GONE \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:GONETests -quiet
```

- 결과: 성공 (exit code 0)
- 추가 테스트: 학번·이름 동시 필수 검증, 프로필 사진 단계 이동, 프로필 이미지 데이터 저장
- 기존 경고: `HomeView.swift`의 iOS 26 `Text` 결합 deprecated 경고가 출력됐으며, 이번 변경과 무관합니다.

## 수동 확인 필요 항목

- 실제 사진 라이브러리 권한 허용·거부·취소 흐름
- 선택한 사진의 원형 크롭 표시
- Dynamic Type 및 다크 모드에서의 화면 배치·대비
- 포커스된 라벨의 메인 컬러 표현

## 관련 파일

- `GONE/GONE/Features/Auth/Presentation/Signup/SignupView.swift`: 학번·이름 폼, 사진 선택 및 미리보기 UI
- `GONE/GONE/Features/Auth/Presentation/Signup/SignupViewModel.swift`: 5단계 흐름과 입력 상태 검증
- `GONE/GONE/DesignSystem/Components/GONEUnderlinedTextField.swift`: 포커스·오류 라벨 색상
- `GONE/GONETests/SignupViewModelTests.swift`: 회원가입 단계 단위 테스트
