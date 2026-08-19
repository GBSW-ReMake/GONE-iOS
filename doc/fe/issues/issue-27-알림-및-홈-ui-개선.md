# [27] 알림 및 홈 UI 개선 이슈 보고서

> **작업 번호**: #27
> **GitHub 이슈**: GitHub 연결 실패로 미생성 (저장소 `GBSW-ReMake/GONE-iOS` 접근 404)
> **심각도**: Feature 🟢
> **발견일**: 2026-08-19
> **발견 브랜치**: `feat/27-notifications-home-ui`
> **상태**: 개발 진행 중

---

## 요청 요약

학생·선생님 역할별 알림 화면을 추가하고, 홈 헤더에 GONE 로고와 알림 버튼을 배치한다. 시간표·급식·학사일정·신청현황 섹션에는 제공된 3D 에셋을 적용한다.

## 참고 화면

- 학생 알림 UI: 사용자 제공 이미지 #9
- 선생님 알림 UI: 사용자 제공 이미지 #10
- 홈 UI: 사용자 제공 이미지 #1

## 기술 범위

- `Notification` Model / Repository / UseCase / ViewModel
- 역할별 Mock 알림 데이터
- 알림 화면 NavigationStack 진입
- 홈 헤더 및 섹션 일러스트 에셋 적용

## 외부 이슈

- GitHub Connector와 로컬 `gh` 모두 인증/접근 오류로 실제 이슈 생성이 완료되지 않았다.
- 실제 GitHub 이슈 생성 후 이 문서의 링크와 계획서의 관련 이슈를 갱신해야 한다.
