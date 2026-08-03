# 로그인 다크 모드 placeholder 색상 이슈 보고서

> **작업 번호**: #01
> **GitHub 이슈**: [#1](https://github.com/GBSW-ReMake/GONE-iOS/issues/1)
> **심각도**: Minor 🟡  
> **발견일**: 2026-08-03  
> **발견 브랜치**: `feat/1-로그인`  
> **상태**: 해결 완료

---

## 증상 요약

다크 모드에서 아이디·비밀번호 입력 필드의 placeholder가 흰색으로 표시되어 배경과 대비가 부족했습니다.

## 재현 방법

1. 기기 또는 시뮬레이터를 다크 모드로 전환합니다.
2. 로그인 화면에 진입합니다.
3. 비어 있는 아이디 또는 비밀번호 입력 필드를 확인합니다.

## 예상 동작

라이트·다크 모드와 관계없이 placeholder가 GONE의 보조 회색으로 명확하게 표시됩니다.

## 실제 동작

다크 모드에서 시스템 기본 placeholder 색상이 흰색 계열로 적용되었습니다.

## 원인 분석

문자열 기반 `TextField`·`SecureField` initializer를 사용해 시스템 placeholder 색상에 의존하고 있었습니다.

## 수정 내용

`Text` 기반 `prompt`를 사용하고 `Color.goneTextTertiary`를 직접 적용했습니다. 두 입력 필드 모두 동일한 토큰을 사용합니다.

## 관련 파일

- `GONE/GONE/DesignSystem/Components/GONEUnderlinedTextField.swift`: placeholder 색상 토큰 직접 적용
