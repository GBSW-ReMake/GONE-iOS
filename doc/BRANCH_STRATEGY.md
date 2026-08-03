# GONE 브랜치 전략

## 구조

```text
main
└── dev
    ├── feat/<이슈번호>-<기능명>
    ├── fix/<이슈번호>-<설명>
    └── hotfix/<설명>
```

| 브랜치 | 역할 | 직접 커밋 | 병합 방식 |
|---|---|---:|---|
| `main` | 배포 기준 | 금지 | `dev` PR만 |
| `dev` | 다음 릴리즈 통합 | 금지 | `feat`/`fix` PR |
| `feat/*` | 기능 개발 | 허용 | `dev`로 PR |
| `fix/*` | QA 버그 수정 | 허용 | `dev`로 PR |
| `hotfix/*` | 운영 긴급 수정 | 허용 | `main`, 이후 `dev` 반영 |

## 이름 규칙

```text
feat/12-lab-reservation
fix/31-outing-status-update
hotfix-login-blocked
```

- GitHub 이슈 연동 작업은 이슈 번호를 반드시 포함합니다.
- 기능명은 짧고 대상이 명확한 **영문 소문자 케밥 표기법**을 사용합니다. Unicode 문자로 인한 GitHub ref 경고를 방지하기 위해 브랜치명에는 한글·공백·특수문자를 사용하지 않습니다.
- 브랜치는 계획서 승인 후 생성합니다.

## 병합 규칙

- `feat/* → dev`: QA 및 개발자 리뷰 후 Squash merge 권장
- `fix/* → dev`: QA 재검증 및 개발자 리뷰 후 병합
- `dev → main`: 모든 기능 개발과 통합 QA가 끝난 최종 릴리즈 단위로만 Merge commit
- `hotfix/* → main`: 긴급 수정 후 동일 변경을 `dev`에도 반영

> **중요:** 기능 개발 중에는 `main` PR을 만들지 않습니다. `main` PR은 개발자가 명시적으로 최종 릴리즈를 요청했을 때만 생성합니다.
