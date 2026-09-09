# 인증 API 연동 1차 계획서: 로그인 및 회원가입

> **상태**: 승인됨
> **작성일**: 2026-09-09
> **관련 이슈**: [#36](https://github.com/GBSW-ReMake/GONE-iOS/issues/36)
> **브랜치**: `feat/36-auth-api`

## 1. 목적 및 배경

기존에 구현된 로그인·회원가입 화면을 실제 백엔드와 연결합니다. 네트워크 구현은 Moya 기반의 공통 API 계층으로 분리하고, 화면은 MVVM을 유지하면서 ViewModel이 UseCase를 통해 인증 기능을 사용하도록 구성합니다.

이번 1차 범위는 로그인과 회원가입입니다. 로그아웃·토큰 갱신·FCM 토큰 등록은 공통 인증 기반을 재사용하는 후속 태스크로 분리합니다.

## 2. 확인된 API 명세

Notion의 `API 명세서`에서 확인한 인증 endpoint는 다음과 같습니다.

| 기능 | Method | Path | 확인 상태 |
|---|---|---|---|
| 로그인 | POST | `/api/auth/login` | endpoint 확인 |
| 로그아웃 | POST | `/api/auth/logout` | 후속 범위 |
| 토큰 갱신 | POST | `/api/auth/refresh` | 후속 범위 |
| FCM 토큰 등록 | PATCH | `/api/auth/fcm-token` | 후속 범위 |
| 회원가입 | 미확인 | 미확인 | 상세 페이지 본문 비어 있음 |

서버 포트는 `8080`으로 기재되어 있으나 IP/base URL은 `?`로 되어 있습니다. 로그인·회원가입 요청/응답 필드와 회원가입 endpoint도 현재 명세에서 확인되지 않습니다.

## 3. 작업 범위

### 포함

- Moya 의존성 추가 및 네트워크 모듈 구성
- `AuthTarget` enum을 통한 endpoint, HTTP method, headers, task 처리
- 공통 API 응답·네트워크 오류 매핑
- 로그인 요청/응답 DTO와 Domain Model 변환
- `AuthRepository` protocol 및 `RemoteAuthRepository` 구현
- `LoginUseCase`와 `LoginViewModel` 연결
- Keychain 기반 access/refresh token 저장소
- 회원가입 요청/응답 DTO 및 `SignupUseCase` 연결
- 기존 회원가입 다단계 화면의 최종 제출 상태, 로딩, 성공·실패 피드백
- API 계약에 화면이 필요한데 현재 없는 상태가 있으면 기존 디자인 시스템을 유지해 최소 UI 추가
- Repository/UseCase/ViewModel 단위 테스트와 시뮬레이터 QA

### 제외 및 후속 범위

- 로그아웃 API 연동
- 토큰 갱신 및 요청 자동 재시도 인터셉터
- FCM 토큰 등록
- 학생 프로필 이미지 업로드 API
- 전화번호 인증 발송·검증 API

위 항목은 회원가입 명세가 확정될 때 실제 endpoint가 포함되어 있으면 범위를 재검토합니다.

## 4. 아키텍처 및 파일 구조

```text
GONE/
├── Core/
│   ├── Network/
│   │   ├── APIError.swift
│   │   ├── APIClient.swift
│   │   └── AuthTarget.swift
│   └── Security/
│       └── SessionStore.swift
└── Features/Auth/
    ├── Domain/
    │   ├── Model/
    │   ├── Repository/AuthRepository.swift
    │   └── UseCase/
    ├── Data/
    │   ├── DTO/
    │   └── Repository/RemoteAuthRepository.swift
    └── Presentation/
        ├── Login/
        └── Signup/
```

- View는 UI 표시와 사용자 입력 전달만 담당합니다.
- ViewModel은 입력 상태, 로딩, 오류, 성공 이벤트를 관리합니다.
- UseCase는 인증 요청과 세션 저장이라는 비즈니스 흐름을 담당합니다.
- Repository는 API 접근을 추상화하고 DTO를 Domain Model로 변환합니다.
- Moya `TargetType` 구현과 실제 서비스 호출은 별도 파일의 Data/Core 계층에 둡니다.
- 토큰은 UserDefaults가 아닌 Keychain에 저장합니다.
- 테스트에서는 Repository protocol을 Mock으로 주입합니다.

## 5. 작은 태스크 단위

### Task 1. API 계약 및 환경 설정 확정

- base URL/IP, 회원가입 endpoint, 로그인·회원가입 Request/Response JSON, 오류 응답, 토큰 필드 확정
- Moya 추가 방식과 Debug/Release base URL 분리 방식 결정

### Task 2. Moya 공통 네트워크 기반

- Moya 의존성 추가
- `AuthTarget` enum 작성
- 공통 디코딩 및 오류 매핑 구현
- 네트워크 Mock 주입 지점 구성

### Task 3. 세션 저장 및 Domain 계약

- `SessionStore` protocol 및 Keychain 구현
- 인증 Domain Model, `AuthRepository` protocol 작성
- 로그인·회원가입 UseCase 작성

### Task 4. 로그인 API 연결

- 로그인 DTO 및 Repository 구현
- `LoginViewModel`에 UseCase 주입
- 로그인 중복 제출 방지, 로딩, 서버 오류, 네트워크 오류 상태 구현
- 성공 시 토큰 저장 및 앱 진입 전환 이벤트 연결

### Task 5. 회원가입 API 연결

- 명세에 맞는 회원가입 DTO 및 Repository 구현
- 현재 5단계 회원가입 화면의 입력값을 API 요청으로 매핑
- 최종 CTA 로딩·중복 제출 방지·성공/실패 상태 구현
- API에 필요한데 화면이 없는 필드는 기존 디자인을 해치지 않는 별도 단계 또는 보조 입력 상태로 추가

### Task 6. 테스트 및 QA

- Login/Signup UseCase 및 ViewModel 성공·실패·로딩 테스트
- DTO 디코딩 테스트
- 정상·빈 입력·인증 실패·서버 오류·네트워크 단절 QA
- 다크 모드, Dynamic Type, VoiceOver, 다양한 화면 크기 확인
- `git diff --check` 및 Debug iOS Simulator 빌드 확인

## 6. 결정 필요 및 리스크

- 개발 서버 base URL은 `https://gone-dev.gbsw.hs.kr`로 확정했습니다. 운영 서버 전환은 별도 검토합니다.
- 회원가입 상세 페이지가 비어 있어 endpoint, 필드명, 응답, 전화번호 인증 방식이 불명확합니다.
- 현재 화면은 아이디·비밀번호·전화번호·인증번호·학번·이름·프로필 이미지까지 수집하지만, 서버가 요구하는 가입 필드와 일치하는지 확인이 필요합니다.
- Moya가 프로젝트에 등록되어 있지 않아 패키지 추가 및 네트워크 환경 접근이 필요합니다.
- 토큰 응답 구조가 확인되기 전에는 자동 로그인·토큰 갱신을 구현하지 않습니다.

## 7. 완료 기준

- [ ] 승인된 API 계약으로 로그인·회원가입 요청이 실제 서버에 전달된다.
- [ ] Moya endpoint가 enum으로 관리되고 View/ViewModel에서 직접 네트워크 코드를 호출하지 않는다.
- [ ] MVVM + 경량 Clean Architecture 책임 분리가 유지된다.
- [ ] 인증 성공 시 access/refresh token이 Keychain에 저장된다.
- [ ] 로딩 중 중복 제출이 차단되고 성공·실패·네트워크 오류가 화면에 안내된다.
- [ ] 명세에 필요한 누락 화면 상태가 기존 디자인 시스템과 접근성 기준에 맞게 제공된다.
- [ ] 관련 단위 테스트와 시뮬레이터 QA 결과가 기록된다.

## 8. 승인

> **개발자 검토 의견**
>
> 승인 여부: 승인 ✅
>
> 수정 요청:

## 참고

- [Notion API 명세서](https://cautious-law-8f0.notion.site/9c098d114f94423aa0e16ae3aeddac91?v=5cd1ec54d1af43638e99f2260fba79ec&source=copy_link)
- [GONE 아키텍처](../../ARCHITECTURE.md)
- [GONE 개발 워크플로우](../../WORKFLOW.md)
