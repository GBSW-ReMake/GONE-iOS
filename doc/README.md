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
├── ARCHITECTURE.md
├── DESIGN_SYSTEM.md
├── issues/
│   └── _TEMPLATE-report.md
├── reports/
│   └── _TEMPLATE-final-report.md
└── fe/
    ├── plans/
    │   ├── _TEMPLATE-plan.md
    │   └── feat #작업번호 기능명.md
    ├── issues/
    │   └── issue-작업번호-기능명-qa.md
    └── reports/
        └── feat #작업번호 기능명 최종 보고서.md
```

## 문서 작성 순서

기능 개발은 반드시 다음 순서를 지킵니다.

1. `doc/fe/plans`에 계획서 작성
2. 개발자 검토 및 승인
3. GitHub 이슈 작성
4. 이슈 번호를 포함한 브랜치 생성
5. 개발·QA·최종 보고·PR 진행

승인 전에는 이슈 생성, 브랜치 생성, 구현을 시작하지 않습니다.

## 작업 번호 규칙

- 계획서, QA 이슈 보고서, 최종 개발 보고서에는 동일한 `작업 번호`를 `#01`부터 순서대로 기록합니다.
- `작업 번호`는 개발 순서를 나타내며 GitHub 이슈 번호와 별개입니다.
- GitHub 이슈가 생성되기 전에는 관련 이슈를 `#이슈번호 (승인 후 기입)`으로 남기고, 생성 후 실제 번호로 바꿉니다.

## 파일명 규칙

```text
doc/fe/plans/feat #12 실습실 신청.md
doc/fe/issues/issue-12-실습실-신청-qa.md
doc/fe/reports/feat #12 실습실 신청 최종 보고서.md
```

## 참고 문서

| 문서 | 설명 |
|---|---|
| [WORKFLOW.md](WORKFLOW.md) | 기능 개발 11단계 절차 |
| [BRANCH_STRATEGY.md](BRANCH_STRATEGY.md) | 브랜치 역할과 이름 규칙 |
| [COMMIT_CONVENTION.md](COMMIT_CONVENTION.md) | 커밋 메시지 규칙 |
| [PULL_REQUEST_TEMPLATE.md](PULL_REQUEST_TEMPLATE.md) | PR 본문 템플릿 |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Feature 중심 MVVM 구조와 계층 책임 |
| [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) | GONE 디자인 시스템 v1 초안 |
