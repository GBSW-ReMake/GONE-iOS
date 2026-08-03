# GONE 개발 워크플로우

기능 하나는 계획서부터 개발자 머지까지 아래 11단계를 순서대로 진행합니다.

```text
계획서 작성 → 계획서 검토 → GitHub 이슈 → 브랜치 분기 → 기능 개발
→ QA 및 이슈 보고 → 수정 → 최종 보고 및 검토 → 최종 커밋·Push → PR → 개발자 머지
```

## 1. 계획서 작성

- 위치: `doc/fe/plans/`
- 기능 목적, 사용자 시나리오, 화면·상태, 데이터/API, 작업 분리, 완료 기준을 작성합니다.
- 백엔드 API가 미확정이면 추정하지 않고 의존성 및 결정 필요 항목으로 기록합니다.

## 2. 계획서 검토

- 개발자가 계획서를 검토하고 승인합니다.
- 승인 전에는 이슈, 브랜치, 구현을 시작하지 않습니다.

## 3. GitHub 이슈 작성

- 제목: `[feat] 기능명` 또는 `[fix] 버그 설명`
- 본문: 계획서 요약과 Acceptance Criteria
- 라벨: `feature`, `bug`, `enhancement` 중 선택

## 4. 브랜치 분기

```bash
git checkout dev
git pull origin dev
git checkout -b feat/<이슈번호>-<기능명>
```

## 5. 기능 개발

- View / ViewModel / UseCase / Repository / Model 책임을 분리합니다.
- 커밋 하나에는 하나의 논리적 변경만 포함합니다.
- 계획과 구현이 달라지면 먼저 계획서를 갱신하고 재검토합니다.

## 6. QA 및 이슈 보고

- 정상·로딩·빈 상태·오류·권한 거부 상태를 확인합니다.
- 발견 이슈는 `doc/issues/_TEMPLATE-report.md`를 기준으로 `doc/fe/issues/`에 기록합니다.
- Major 이슈 이상은 개발자 검토 후 수정 방향을 확정합니다.

## 7. 수정

- Minor 이슈: 현재 `feat` 브랜치에서 수정합니다.
- Major 이슈: 개발자 결정에 따라 `fix/<이슈번호>-<설명>` 브랜치를 생성합니다.
- 수정 후 관련 QA를 다시 진행합니다.

## 8. 최종 개발 보고 및 검토

- 위치: `doc/fe/reports/` (`doc/reports/_TEMPLATE-final-report.md` 기준)
- 구현 내용, 계획 대비 변경점, QA 결과, 제한사항을 기록합니다.
- 개발자 최종 검토를 받습니다.

## 9. 최종 커밋 및 Push

```bash
git add .
git commit -m "feat: 실습실 신청 구현 완료 (#12)"
git push origin feat/12-실습실-신청
```

## 10. PR 생성

- Base: `dev`
- Compare: `feat/*` 또는 `fix/*`
- 제목: `[feat] 기능명 (#이슈번호)`
- 본문: [PULL_REQUEST_TEMPLATE.md](PULL_REQUEST_TEMPLATE.md) 사용
- **기능 개발 PR은 예외 없이 `dev`를 대상으로 합니다.**
- PR은 Draft가 아닌 **Ready for review** 상태로 생성합니다.
- `main` 대상 PR은 모든 개발과 통합 QA가 끝난 최종 릴리즈에만 사용하며, 개발자가 명시적으로 요청하기 전에는 생성하지 않습니다.

## 11. 개발자 머지

- 개발자가 코드 리뷰, CI, QA 결과를 확인한 뒤 직접 머지합니다.
- 에이전트는 머지를 수행하지 않습니다.
