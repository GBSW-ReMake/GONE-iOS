# GONE iOS 아키텍처

> 상태: 적용 중  
> 기준: Feature 중심 MVVM + 경량 Clean Architecture

## 권장 구조

GONE은 초기 iOS 앱 규모에 맞춰 **MVVM을 기본**으로 사용합니다. 화면 단위 상태와 UI 로직은 ViewModel에 두고, 서버·저장소·복잡한 비즈니스 규칙이 생기는 기능에만 UseCase와 Repository를 추가합니다.

```text
GONE/
├── App/                         # 앱 시작점, 의존성 조립, 전역 화면 전환
├── Core/                        # APIClient, Keychain, 공통 오류·유틸리티
├── DesignSystem/                # 색상 토큰, 타이포그래피, 공용 UI 컴포넌트
└── Features/
    └── Auth/
        ├── Presentation/
        │   └── Login/
        │       ├── LoginView.swift
        │       └── LoginViewModel.swift
        ├── Domain/
        │   ├── Model/
        │   ├── UseCase/
        │   └── Repository/
        └── Data/
            ├── DTO/
            └── Repository/
```

## 책임

| 계층 | 책임 | 예시 |
|---|---|---|
| View | UI 표시와 사용자 이벤트 전달 | `LoginView` |
| ViewModel | 화면 상태, 입력 검증, View 전용 로직 | `LoginViewModel` |
| UseCase | 여러 화면에 공통인 비즈니스 규칙 | `LoginUseCase` |
| Repository | 데이터 접근의 추상화 | `AuthRepository` |
| Data | API DTO 변환, Keychain·네트워크 실제 구현 | `RemoteAuthRepository` |
| Model | 앱 내부에서 사용하는 의미 있는 데이터 | `LoginCredentials` |

## 적용 기준

- 단순 화면 상태와 입력 검증은 ViewModel에 둡니다.
- API, Keychain, DB 등 외부 I/O가 시작되면 Repository protocol을 Domain에 두고 실제 구현은 Data에 둡니다.
- 여러 ViewModel에서 재사용하거나 독립적으로 테스트할 비즈니스 규칙은 UseCase로 분리합니다.
- 한 화면에서만 쓰는 단순 표시 변환을 위해 UseCase·Repository를 만들지 않습니다.
- View는 APIClient, Keychain, DTO에 직접 의존하지 않습니다.

## 로그인 적용 현황

- 완료: `LoginView`와 `LoginViewModel` 분리, `LoginCredentials` 모델 분리
- API 명세 확인 후: `LoginUseCase`, `AuthRepository`, `RemoteAuthRepository`, Keychain `SessionStore`를 추가
- 인증 성공 후 화면 전환은 `App` 조립 계층에서 연결
