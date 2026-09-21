# SAS 후속 실행 안내 (S1, 2026-09-21)

집계 전용 전달본이다. 원문·행 ID·개별 점수·모형·인증 정보를 포함하지
않는다. SAS 실제 실행은 사용자가 수행하며, 실행 주장은 하지 않는다.
아래 정적 점검(Python 스키마·바이트 검사)은 SAS 실행 증명이 아니다.

## 실행 (SAS 서버에서 순서대로)

1. 연동 저장소 최신판 받기 (SAS 서버 셸에서, push는 메인이 수행):

```sh
git -C /home/student/github pull --ff-only
```

체크아웃 경로가 다르면 해당 경로로 교체한다. `followup_20260921_v1/`이
있는 폴더를 `projroot`로 지정한다.

2. SAS Studio / Enterprise Guide에서 정확히 두 줄을 제출한다.
`projroot` 기본값은 `/home/student/github`이다.

```sas
%let projroot = /home/student/github;
%include "&projroot./followup_20260921_v1/sas/00_RUN_FOLLOWUP_20260921.sas";
```

실행기는 4단계(U5 오류 진단·Jev 비교·Jev 결합·KISA OCR 진단)를 순서대로
수행한다. 매 실행마다 `outputs/run_<UUID>/` 새 폴더가 생기며, 기존 폴더를
덮어쓰지 않는다(같은 UUID가 있으면 즉시 중단). 단계 오류(SYSCC/SYSERR)나
산출물 누락이 있으면 즉시 중단하며, 파일 존재만으로 성공 처리하지 않고
기존 로그를 지우지 않는다. 결합 단계는 포함 시점에 검증을 정확히 1회만
수행한다.

## 산출물 위치

실행할 때마다 `outputs/run_<UUID>/` 새 폴더가 생긴다.

- `stage_u5.log`, `stage_cmp.log`, `stage_fus.log`, `stage_kisa.log`:
  단계별 로그. 오류 확인용으로 이 파일을 먼저 본다.
- `stage_u5/outputs/u5_error_diagnostics_report.html`,
  `stage_cmp/outputs/jev_kcbert_comparison_summary.html`,
  `stage_fus.html`, `kisa_stage.html`: 단계별 보고서(ODS).
- `kisa_verified_readback.csv`: KISA 검증 통과 집계의 SAS 재출력.
- `followup_summary.html`, `run_status.txt`: 전체 요약과 상태.

KISA 단계에는 C2 실측 집계(`data/kisa_ocr_diagnostics_20260921.csv`,
19열 계약·3코호트×5시드×7조건=105행)가 필요하다. 코드 전용 전달본에서는
해당 단계가 자료 없음으로 중단되며, 이는 정상적인 실패 닫힘이다.

## 메인에게 반환할 파일

`outputs/run_<UUID>/` 폴더 전체를 가공 없이 그대로 반환한다.

- `run_status.txt`, `followup_summary.html`
- 단계별 로그 4건(`stage_u5.log`, `stage_cmp.log`, `stage_fus.log`,
  `stage_kisa.log`)
- 단계별 보고서 HTML(`u5_error_diagnostics_report.html`,
  `jev_kcbert_comparison_summary.html`, `stage_fus.html`, `kisa_stage.html`)
- U5 재출력 CSV 3건(`sas_model_readback.csv`, `sas_arm_readback.csv`,
  `sas_transition_readback.csv`)
- `kisa_verified_readback.csv` (KISA 단계가 통과한 경우)

## 현재 상태와 한계

- 전달본은 집계 패키지 완성 상태다. C2 실측 집계
  (`data/kisa_ocr_diagnostics_20260921.csv`, 19열 계약·105행,
  코호트별 n=22/18/250)를 포함하며
  `python3 scripts/build_sas_followup_20260921.py` 풀 빌드와 `--check`
  읽기 전용 검증(매니페스트·정식 원본 바이트·스키마 재검사)을 통과했다.
- SAS 정적 점검(금지문·실패 중단 존재)과 Python 스키마 검사는 마쳤으나
  실제 SAS 실행은 미검증이며, 실행 결과 주장은 하지 않는다.
  SAS 서버 실행과 결과 검수는 메인 확인을 거쳐 진행한다.
