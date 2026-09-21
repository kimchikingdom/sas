# sas

최신 후속 실행은 [집계 전용 패키지](followup_20260921_v1/README.md)로 진행한다.
U5 오류 진단 → Jev 비교 → Jev 결합 → KISA OCR·길이 진단을 실행한다.
[자세한 실행·반환 안내](docs/SAS_FOLLOWUP_RUN_GUIDE_20260921.md)를 따른다.

SAS 서버에서 이 저장소를 최신 main으로 갱신한 후 새 SAS 세션에서 실행한다.
projroot은 followup_20260921_v1 폴더가 있는 서버 경로로 맞춘다.

```sas
%let projroot = /home/student/github;
%include "&projroot./followup_20260921_v1/sas/00_RUN_FOLLOWUP_20260921.sas";
```

실행 결과는 followup_20260921_v1/outputs/run_<UUID>/에 생긴다.
해당 폴더의 로그·HTML·PNG·CSV와 run_status.txt를 함께 보관한다.
코드·집계 검사는 완료했으며 실제 SAS 실행은 사용자 로그를 받아 확인한다.
새 모델 학습이나 CAS/VA 게시를 수행하는 실행기는 아니다.

기존 A/B 검수 분석은 sas/00_RUN_AB.sas에서 11 → 12 순서로 재현한다.
기존 실행 범위와 검수 기준은 sas/README.md와 sas/RUNBOOK.md를 따른다.

루트 `MANIFEST.json`과 `CHECKSUMS_SHA256.txt`는 2026-09-14 개인 전달본의 고정
스냅샷이다. 이후 추가된 11~13 및 저장소 정리를 반영한 현재 트리 manifest가 아니므로
파일을 덮어쓰지 않는다. 최신 CAS 전달 계보는 `manifests/ab_cas_20260915_v1.json`에 있다.
