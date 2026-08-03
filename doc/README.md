# GONE 문서 디렉터리

GONE iOS 프로젝트의 기획, 개발, QA, 릴리즈 기록을 관리합니다.

## 구조

```text
doc/
├── README.md
├── WORKFLOW.md
├── BRANCH_STRATEGY.md
├── COMMIT_CONVENTION.md
├── PULL_REQUEST_TEMPLATE.md
├── DESIGN_SYSTEM.md
├── fe/
│   ├── plans/
│   ├── issues/
│   └── reports/
```

## 문서 작성 순서

기능 개발은 반드시 다음 순서를 지킵니다.

1. `fe/plans`에 계획서 작성
2. 개발자 검토 및 승인
3. GitHub 이슈 작성
4. 이슈 번호를 포함한 브랜치 생성
5. 개발·QA·최종 보고·PR 진행

승인 전에는 이슈 생성, 브랜치 생성, 구현을 시작하지 않습니다.

## 파일명 규칙

```text
fe/plans/feat-12-실습실-신청.md
fe/issues/issue-12-실습실-신청-qa.md
fe/reports/feat-12-실습실-신청-최종-보고서.md
```

## 참고 문서

| 문서 | 설명 |
|---|---|
| [WORKFLOW.md](WORKFLOW.md) | 기능 개발 11단계 절차 |
| [BRANCH_STRATEGY.md](BRANCH_STRATEGY.md) | 브랜치 역할과 이름 규칙 |
| [COMMIT_CONVENTION.md](COMMIT_CONVENTION.md) | 커밋 메시지 규칙 |
| [PULL_REQUEST_TEMPLATE.md](PULL_REQUEST_TEMPLATE.md) | PR 본문 템플릿 |
| [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) | GONE 디자인 시스템 v1 초안 |
