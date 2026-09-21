# KISA 진단·개선 후보·SAS 전달 완료 기록

요청한 원인 분리 진단과 개선 후보 회귀 검사는 완료했다. 개선 후보는 사전 기준을 충족하지 못했으므로 기본 모델과 임계값을 유지한다. SAS 집계 실행 코드는 검토·검산 후 기존 연동 저장소에 푸시했다. 최종 ZIP의 실행 완료 표식·반환 CSV·전체 그래프 검수를 완료했다. 받은 SAS 집계 실행은 네 단계 모두 통과했으며, U5 이미지 절대경로 문제는 열람본에서 수정했다.

## 결과와 검사 근거

- 실측 집계, [해석 문서](KISA_DIAGNOSTIC_INTERPRETATION_20260921.md), [오프라인 웹페이지](../explain/kisa_diagnostic_interpretation_20260921.html)
- 고정 계획과 Orca 작업 기록
- [메인 검증·전달 정본](kisa_followup_completion_20260921.json)
- SAS 실행·반환 안내
- [GitHub 커밋](https://github.com/kimchikingdom/sas/commit/5621b300eee0e493be04892b84d372da2be21a04): 원격 HEAD 일치와 작업 트리 청결 확인.

Antigravity가 준비·추론·보고서 구현을, Muse Spark 1.3 Free가 SAS 전달본 구현을 맡았다. Luna의 읽기 전용 SAS 사전 검토도 활용했다. 메인은 입력 전수 토큰 재구성, 원본 보존, 행별 키·집계 재계산, 독립 표본 재추론, 실제 코드·파일·화면 검사를 수행했다.

검사 중 OCR 삭제 범위, 출력 검증 누락, SAS 변수 범위·파일 열기·열 자료형 검사와 무결성 manifest, 보고서의 근거 없는 기전 설명·고정 숫자·온라인 스크립트 의존을 수정하고 재검증했다. 같은 자료에서 조건이나 임계값을 반복 조정하지 않았다.

## 다시 확인할 명령

```sh
python3 scripts/run_kisa_ocr_diagnostics_20260921.py --check
python3 scripts/build_kisa_diagnostic_interpretation_20260921.py --check
python3 scripts/build_sas_followup_20260921.py --check
python3 scripts/build_u5_error_diagnostics_20260920.py --check
python3 scripts/fit_jev_kcbert_fusion_20260920.py check
python3 scripts/run_jev_kcbert_comparison_20260920.py --check
```

준비 단계 테스트와 SAS 패키지 변형·보존 테스트도 통과했다. SAS 패키지 테스트는 생성물을 재생성하는 검사이며 실제 SAS 실행 시험은 아니다. 실행 코드·원문·점수·입력 해시는 비공개 실험 폴더에 보존한다.

## 남은 경계

최종 반환 ZIP의 검수를 완료했다. 받은 집계 실행의 확인을 위한 추가 SAS 재실행은 필요하지 않다. SAS 학습·CAS/VA 게시를 자동 수행하는 패키지는 아니다.

이번 진단은 기존 평가 자료의 사후 재사용이다. 정상 후보 지표를 실서비스 독립 오탐률로 주장할 수 없다. 이후 개선 효과·일반화 주장은 새 독립 정상·스미싱 자료가 필요하다. 현재의 개선 실패 결과는 발표에 반영할 수 있으며 기존 PPT·포스터는 이번 작업에서 바꾸지 않았다.

## SAS 첫 실행 반환 후 수정

U5 단계의 검증·그래프·CSV 생성은 로그에서 확인했다. 종료 안내문의 세미콜론 뒤
문장이 실행 코드로 처리되어 ERROR 180-322가 발생했고, 실행기의 오류 안내문도
같은 문법 오류를 일으켰다. 두 경로를 고치고 생성기의 재발 검사와 회귀 사례를
추가했다. SAS 서버 전체 재실행 완료·반환 CSV 값 대조·그래프 실물 검수는 대기다.

수정본 [a30f63d](https://github.com/kimchikingdom/sas/commit/a30f63d4d1b32daabd1ab57ab101057dd4be2e45)를 같은 SAS 연동 저장소 main에 푸시했고 원격 HEAD 일치를 확인했다. 집계 CSV는 이전 커밋과 바이트 단위로 동일하다. 수정 후 생성기·SAS 전달본 검사 및 U5 원본 집계 재검산을 통과했다. 전체 SAS 성공 여부는 새 서버 실행 결과로 확인한다.

## 수정 후 새 실행 반환 검사

메인이 반환 파일을 직접 검사했다. 아래 수치는 [검사 정본](kisa_followup_completion_20260921.json)의 `sas_return_audit`에서 생성했다. 기존 실패 실행과 다른 새 실행이며, U5 종료 안내문의 수정도 확인했다.

- 받은 단계 로그: 4개. 실제 ERROR 0건, WARNING 0건. 출력된 SAS 소스의 오류 안내 문자열은 발생한 오류로 세지 않았다.
- U5: 검증 완료 및 재출력 CSV 15, 3, 6행 저장 기록 확인.
- 비교: Aggregate guard checks passed 확인.
- 결합: 산술·조건 간 일관성 검사 통과. 반환 HTML 15행의 건수·혼동행렬 75개 값이 원본과 정확히 일치하며 임계값 15개는 소수점 표시 반올림과 일치한다.
- KISA: 조합·임계값·분모·산술 검사 통과, CSV 105행 저장과 그래프 실행 기록 확인.

`SASUSER.PARMS` 쓰기 불가 메시지는 WORK 임시 저장 안내이며 CSV 생성은 성공했다. 결합 로그와 HTML에는 실행 UUID가 없어 동일 실행 소속을 파일 자체로 확정하지 않았다. 나머지 세 로그의 UUID는 일치한다.

남은 반환물은 `run_status.txt`, `followup_summary.html`, `kisa_verified_readback.csv`, U5의 세 재출력 CSV와 그래프 보고서·이미지다. 최종 상태 파일과 결과값 대조 없이 전체 실행 검수를 완료로 표시하지 않는다. 반환 원본·SHA-256·재현 가능한 검사 스크립트는 비공개 `sas_followup_return_20260921_v1/`에 보관했다. 이번에는 코드 변경·새 모델 실행·GitHub 푸시를 하지 않았다.

## 최종 ZIP 반환 검수 완료

이 절이 위의 부분 반환 대기 상태를 대체한다. [검사 정본](kisa_followup_completion_20260921.json)에서 아래 수치를 생성했다.

- ZIP 55개 파일 CRC·추출 바이트 대조 통과. 최종 상태와 요약표는 4단계 모두 ok.
- 단계 로그 ERROR·WARNING 없음. KISA 105행, U5 모델 15행, 조건별 평균·모표준편차 3행, 전이 6행 검산 통과.
- Jev 비교 HTML 15행 검산, 결합 HTML은 앞서 전수 대조한 반환본과 동일. 최대 CSV 수치 차이는 4.97e-11로 출력 반올림 허용범위 이내.
- 그래프 35개를 직접 확인. U5 HTML의 서버 절대경로는 원본을 보존하고 열람본에서 상대경로로 수정했다. 막대가 없는 일부 그래프는 실제 집계값이 모두 0인 경우다.

[검수 완료 열람본](../sas-results/index.html)에서 각 보고서를 열 수 있다. Antigravity가 숫자 대조 스크립트를 작성했고, 메인이 코드·출력 검토, 재실행, 열 구성 확인, 변조 거부 검사, HTML 수치 검산과 실제 그래프 검수를 수행했다. Orca task: `task_6b61def9ec86`.

향후 생성본의 경로 문제 재발을 막기 위해 U5 `GPATH`에도 `(url=none)`을 추가했다. 이 한 줄을 바꾼 SAS 소스는 서버 재실행 전이며, 검증 완료 주장은 반환된 실행과 수정된 로컬 열람본에 한정한다. CAS·VA 실행과 독립 평가 여부는 별도다.
