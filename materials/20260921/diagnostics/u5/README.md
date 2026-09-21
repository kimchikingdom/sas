# ScamLens KcBERT U5 Error Diagnostics Package (2026-09-20)

## 1. 개요
본 디렉터리는 ScamLens KcBERT U5 기존 U5 시험셋(N=2,317)의 15개 모델(BASE, DUP, FLIP x 5 Seeds)에 대한
정밀 오탐(FP)·미탐(FN) 오류 진단 산출물과 독립 실행형 SAS 9.4/Viya 패키지를 담고 있습니다.

## 2. 디렉터리 구성
- `index.html`: 오프라인 완결형 반응형 웹 해설서 (차트 6종, 15개 모델 진단표, 가상 예시 카드 포함)
- `REPORT.md`: 전문 기술 연구 보고서 (한국어 마크다운)
- `charts/`: 고해상도 시각화 차트 6종 (PNG + SVG 각 6개, 총 12개 파일)
- `sas_kit/`: SAS 9.4 / Viya 호환 독립 패키지
  - `16_u5_error_diagnostics.sas`: DATA step 및 PROC SGPLOT 내장 SAS 프로그램
  - `README.md`: SAS 킷 실행 및 입력 데이터 명세 (기대값 표 및 공식 문서 링크 포함)
  - `data/`: 공개 집계 CSV 6종 (`eval_metadata_summary.csv`, `paired_transition_summary.csv` 등)
- `manifest.json`: 산출물 SHA-256 해시 및 메타데이터
- `worker_report.md`: 워커 실행 및 무결성 검증 요약

## 3. 재현 및 검증 명령
```bash
# 전체 산출물 재생성
python3 scripts/build_u5_error_diagnostics_20260920.py

# 무결성 및 읽기 전용 재계산 검증
python3 scripts/build_u5_error_diagnostics_20260920.py --check

# 단위 테스트 실행
pytest -v tests/test_u5_error_diagnostics_20260920.py
```

## 4. 보안 및 개인정보 준수
- 본 공개 디렉터리(`dist/`)에는 실제 메시지 원문(raw text), 실제 message_id, development_group_id, 내부 비공개 경로가 전혀 포함되어 있지 않습니다.
- 행 단위 실제 원문과 비공개 분석 파일은 `[비공개 격리 경로]` (0o700/0o600)에 안전하게 격리되어 있습니다.
