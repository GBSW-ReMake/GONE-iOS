# 실습실 예약 UI 및 신청 플로우 1차 최종 개발 보고서

> **완료일**: 2026-08-04
> **작업 번호**: #04
> **관련 이슈**: [#8](https://github.com/GBSW-ReMake/GONE-iOS/issues/8)
> **PR**: 생성 전
> **브랜치**: `feat/8-lab-reservation`

---

## 구현 요약

하단 실습실 탭의 플레이스홀더를 실제 예약 플로우로 교체했습니다. 층별 실습실을 선택하고 신청 폼을 작성하면, 완료 카드와 상태 타임라인을 확인할 수 있습니다. 생성된 신청 상태는 홈의 신청현황 카드에도 반영되며, 해당 카드를 누르면 실습실 탭으로 이동합니다.

## 구현된 기능

- [x] 4층 Figma 기준 실습실 5개 및 3·2층 Mock 실습실 목록
- [x] 층 세그먼트 전환, 선택 테두리, 재탭 선택 해제, 예약하기 CTA 상태
- [x] 대표자·사용 인원 명단·사용 목적의 필수 입력 검증
- [x] 폼 외부 탭 시 키보드 내리기
- [x] 신청 완료 카드의 신청 번호·이용 시간·신청 상세·상태 타임라인
- [x] 홈 실습실 신청 카드의 최신 상태·시간 갱신 및 탭 이동
- [x] Figma 피드백에 따른 카드·입력 영역·레이블·CTA 크기와 간격 보정
- [x] 상태 타임라인을 선·원형 마커·하단 레이블 구조로 변경

## 아키텍처

- `LabRoom`, `LabReservationDraft`, `LabReservation` 도메인 모델을 추가했습니다.
- `LabReservationRepository`로 목록 조회·현재 신청 조회·신청 저장을 추상화했습니다.
- API 계약 전에는 `MockLabReservationRepository`가 메모리 기반 예약 상태를 제공합니다.
- `AppTabView`가 하나의 `LabReservationViewModel`을 소유해 실습실 화면과 홈 신청현황에 동일한 예약 상태를 전달합니다.

## QA 결과

| 확인 항목 | 결과 |
|---|---|
| Swift 문법 검증 | ✅ 전체 Swift 소스 `swiftc -parse` 통과 |
| 공백 오류 | ✅ `git diff --check` 통과 |
| 4·3·2층 전환 및 선택 상태 | ✅ 구현·정적 검토 완료 |
| 필수 입력 전 CTA 비활성화 | ✅ 구현·정적 검토 완료 |
| 신청 후 완료 카드·홈 상태 반영 | ✅ 동일 ViewModel 상태 전달 구현 |
| iOS Debug 빌드·시뮬레이터 UI QA | ⚠️ 현재 환경에 사용 가능한 Simulator runtime이 없어 미완료 |
| 실기기 VoiceOver·Dynamic Type QA | ⚠️ 개발자 확인 필요 |

## 알려진 제한사항

- 실제 API 명세가 없어 예약 목록·신청 상태는 Mock 데이터이며 앱을 재실행하면 초기화됩니다.
- 교사 승인·반려, 시간 중복·정원 검증, 대여 취소 확인 및 API 연결은 후속 계약이 필요합니다.
- iOS Debug 빌드는 CoreSimulatorService에 사용 가능한 Simulator runtime이 없어 Asset Catalog 단계에서 검증하지 못했습니다.
- 작업 트리에 남아 있던 AccentColor·탭 아이콘 설정·`HomeViewModel.swift`·원본 이미지 폴더 변경은 이 기능 커밋과 PR에 포함하지 않습니다.

## 문서

- 계획서: `doc/fe/plans/feat #04 실습실 예약.md`
- QA 이슈: `doc/fe/issues/issue-08-실습실-예약-빌드-qa.md`
- 최종 보고서: `doc/fe/reports/feat #04 실습실 예약 UI 및 신청 플로우 1차 최종 보고서.md`

---

> **개발자 검토 의견**
> 최종 승인: 승인 ✅ / 재작업 🔄
