# 홈 대시보드 API 및 아이콘 연동 계획서

## 상태

작업 중

- 관련 이슈: [#38](https://github.com/GBSW-ReMake/GONE-iOS/issues/38)
- 브랜치: `feat/38-home-dashboard-api`
- 선행 브랜치: `feat/36-auth-api` (PR #37)

## 목표

홈 화면의 목업 데이터를 실제 개발 서버 API와 연결하고, 제공된 급식·시간표·학사일정·신청현황 아이콘을 현재 디자인에 적용합니다.

## 작업 범위

### 1. 홈 데이터 계약 확인

- 개발 서버 `https://gone-dev.gbsw.hs.kr` 기준 API 경로·인증 헤더·응답 모델 확인
- 현재 백엔드에서 제공되는 상벌점, 시간표, 급식, 학사일정, 외출/실습실/스쿨캠핑 신청현황 API를 구분
- 서버에 아직 없는 항목은 임의 API를 만들지 않고 이슈에 명세 보완 필요 사항으로 기록

### 2. 네트워크 및 데이터 계층

- Moya `TargetType` enum으로 홈 API 요청 정의
- 공통 응답 envelope와 서버 오류 메시지 처리 재사용
- Access Token이 필요한 API는 Keychain 세션과 연동
- DTO → Domain Model 변환을 Repository에서 담당
- 기존 Mock Repository는 Preview/오프라인 테스트용으로 유지

### 3. 홈 화면 연결

- 상벌점 요약 조회
- 오늘 시간표 조회
- 오늘 급식 조회
- 학사일정 월별/날짜별 조회
- 신청현황 조회 및 기존 카드 상태 매핑
- 로딩·빈 데이터·서버 오류 상태를 카드 단위 UX에 반영
- 한 API 실패가 홈 전체를 막지 않도록 섹션별 독립 상태 고려

### 4. 아이콘 및 UI

- 제공된 이미지 에셋을 Assets.xcassets에 등록
- 오늘 시간표: `image 36-1.png`
- 오늘 급식: `image 5.png`
- 학사일정: `image 36.png`
- 신청현황: `image 37.png`
- 첨부된 홈 화면 기준으로 섹션 헤더와 카드 간격·배경·상태 표현을 현재 디자인 토큰 안에서 보정
- Dynamic Type, 다크모드, 작은 화면에서 잘림 여부 확인

## 예상 변경 대상

- `Features/Home/Presentation/HomeView.swift`
- `Features/Home/Presentation/HomeViewModel.swift`
- `Features/Home/Domain/*`
- `Features/Home/Data/*`
- `Core/Network/*`
- `Assets.xcassets/*`

## 검증 계획

- API Target별 요청 경로·메서드·쿼리·Authorization 확인
- DTO 디코딩 테스트 및 Mock 기반 ViewModel 테스트
- Debug Simulator 빌드
- `git diff --check`
- 인증된 학생 계정으로 실데이터 확인
- 급식/시간표/학사일정 빈 데이터와 서버 오류 확인

## 리스크 및 보류 사항

- 백엔드 저장소 기준 급식과 시간표, 상벌점, 외출·스쿨캠핑 API는 확인되지만 학사일정 및 실습실 신청현황 API는 별도 명세 확인이 필요합니다.
- 명세가 없는 항목은 현재 Mock을 유지하거나 백엔드 계약 확정 후 연결합니다.
- 실데이터 검증은 유효한 Access Token과 학교 학적 데이터가 필요합니다.
