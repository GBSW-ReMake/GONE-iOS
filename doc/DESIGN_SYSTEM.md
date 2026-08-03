# GONE 디자인 시스템 v1

> 상태: 기획 초안 · 피그마/SwiftUI 적용 전 검토 필요

GONE은 iOS 기본 동작과 접근성을 우선으로 하는 학교 생활 서비스 디자인 시스템입니다. 피그마의 기존 색상 가이드를 보존하고, 재사용 가능한 의미 토큰과 컴포넌트로 확장합니다.

## 원칙

- iOS Human Interface Guidelines와 SwiftUI 시스템 컴포넌트를 우선합니다.
- 색상은 값보다 의미(`text/primary`, `status/success`)로 사용합니다.
- 최소 터치 영역은 44pt, 상태 변화는 색상 외 텍스트·아이콘으로도 전달합니다.
- Light/Dark 모드를 기본 지원 대상으로 설계합니다.

## 현재 브랜드·상태 색상

| 토큰 | 값 | 용도 |
|---|---|---|
| `brand/primary` | `#5B8DEF` | 주요 CTA, 선택 상태 |
| `brand/deep-navy` | `#1F2937` | 브랜드 강조, 제목 |
| `brand/soft-blue` | `#EAF1FF` | 선택 배경, 정보 틴트 |
| `status/success` | `#34C77B` | 완료, 승인 |
| `status/warning` | `#FFB547` | 대기, 주의 |
| `status/error` | `#FF5A5F` | 반려, 실패 |

## v1 토큰 구조

```text
Primitives
├── color/blue/*
├── color/gray/*
└── color/status/*

Semantic Color (Light / Dark)
├── color/background/{primary,secondary,tertiary}
├── color/surface/{default,selected}
├── color/text/{primary,secondary,tertiary,on-brand}
├── color/border/{default,subtle}
├── color/action/{primary,disabled}
└── color/status/{success,warning,error}

Layout
├── spacing/{4,8,12,16,20,24,32}
└── radius/{sm,md,lg,full}

Typography
├── display
├── title/{large,medium,small}
└── body/{large,medium,small}
```

## v1 컴포넌트 범위

| 컴포넌트 | 필수 상태·변형 |
|---|---|
| `Button` | Primary / Secondary / Destructive, Enabled / Disabled / Loading |
| `TextField` | Default / Focused / Error / Disabled |
| `Card` | Default / Selected / Status |
| `StatusBadge` | Pending / Approved / Rejected / Completed |
| `BottomTabBar` | 5개 탭, Selected / Default |
| `EmptyState` | 아이콘, 제목, 설명, 선택적 CTA |
| `LoadingState` | Skeleton 및 Progress |
| `ErrorState` | 설명, 재시도 CTA |

## 피그마 적용 순서

1. 기존 `GONE Colors`를 Primitive와 Semantic 컬렉션으로 정리
2. Light/Dark 모드와 iOS 코드 문법 연결
3. Typography, Spacing, Radius, Effect 스타일 정의
4. 컴포넌트를 의존성 순서로 제작·검증
5. SwiftUI `DesignSystem`과 동일한 이름으로 매핑

## SwiftUI 매핑 원칙

```swift
Color.goneBackgroundPrimary
Color.goneTextPrimary
Color.goneActionPrimary
Color.goneStatusSuccess
```

- 실제 구현 시 `Color(hex:)` 의존을 최소화하고, 시스템 동적 색상 또는 Asset Catalog를 우선합니다.
- 앱의 다크 모드 값은 디자인 시스템 승인 후 확정합니다.
