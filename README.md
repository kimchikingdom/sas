# ScamLens · SAS 분석과 발표 자료

한국어 스미싱 탐지의 오탐·미탐과 입력 변화에 따른 한계를 분석한 프로젝트입니다.
Python 모델의 평가 집계를 SAS로 검산하고, 결과를 발표 자료와 설명 페이지로 정리했습니다.

## 자료 보기

**[최신 발표본·SAS 실행 준비](materials/20260921_final_v1/README.md)**에서
후속 결과를 반영한 PPTX·PDF·대본을 확인하세요.
**[SAS에서 할 일: 실행·VA 구성 순서](visualization_20260921_v1/SAS_FINAL_VISUALIZATION_20260921.md)**에는
복사해서 실행할 코드와 VA 데이터·열·필터 설정을 정리했습니다.
새 Studio/CAS/VA의 실제 실행은 사용자 진행 항목이며, 코드 준비를 실행 완료로 표시하지 않습니다.

**[발표·설명 자료 전체 안내](materials/20260921/README.md)**부터 확인하세요.
내려받은 폴더에서는 **[자료 모음 화면](materials/20260921/index.html)**을 열면 됩니다.

| 찾는 자료 | 위치 |
|---|---|
| 최신 결과를 쉽게 설명한 HTML | [결과·그림·해석](materials/20260921/explain/scamlens_results_explained_20260921.html) |
| 프로젝트 전체 설명 | [프로젝트 설명 HTML](materials/20260921/explain/PROJECT_EXPLAINED.html) |
| 발표 슬라이드와 대본·문답 | [발표 폴더](materials/20260921/presentation/) |
| 포스터와 설명 | [포스터 폴더](materials/20260921/poster/) |
| U5·JEV 후속 분석 | [진단 자료](materials/20260921/diagnostics/) |
| 실제 SAS 실행 결과·그래프 | [SAS 결과 폴더](materials/20260921/sas-results/) |
| 수치의 근거와 해석 문서 | [공개 집계·문서](materials/20260921/evidence/) |

GitHub 파일 화면은 HTML을 웹페이지처럼 실행하지 않습니다. **Code → Download ZIP**으로
저장소를 내려받아 압축을 풀고 `materials/20260921/index.html`을 여세요.
상대경로로 연결된 그림과 자료가 있으므로 폴더 구조를 유지하세요. PDF는 GitHub에서도 볼 수 있습니다.

`materials/20260921/`의 발표·포스터는 작성 당시 버전입니다.
후속 결과를 반영한 발표본은 `materials/20260921_final_v1/`에 별도로 보존합니다.

내려받은 파일의 무결성은 저장소 폴더에서 `python3 scripts/verify_materials.py`로 확인할 수 있습니다.
이는 파일 목록·해시 검사이며 새로운 모델 평가나 SAS 실행 검증을 수행하는 명령은 아닙니다.

## SAS 실행

새 발표용 시각화는 [Studio·VA 준비 패키지](visualization_20260921_v1/README.md)를 실행하세요.
보고서 HTML 한 파일을 만든 뒤, 별도 CAS 게시 파일을 실행하고 VA 보고서를 수동 구성합니다.
상세한 실행 코드·출력 위치·성공 표식은 위 안내서에 있습니다.

이전에 실행·반환한 진단은 [집계 전용 패키지](followup_20260921_v1/README.md)입니다.
U5 오류 진단 → JEV 비교 → JEV 결합 → KISA OCR·길이 진단을 실행합니다.
사용자가 반환한 실제 SAS 실행 결과는 검산을 마쳤으며 위 SAS 결과 폴더에서 볼 수 있습니다.
이는 새 모델 학습이나 CAS·Visual Analytics 게시를 완료했다는 의미는 아닙니다.

SAS 서버에서 저장소를 갱신한 뒤, 새 세션에서 실행하세요.

```sas
%let projroot = /home/student/github;
%include "&projroot./followup_20260921_v1/sas/00_RUN_FOLLOWUP_20260921.sas";
```

`projroot`는 서버의 저장소 경로입니다. 실행마다
`followup_20260921_v1/outputs/run_<UUID>/`에 결과를 생성합니다.
[실행·ZIP 반환 안내](docs/SAS_FOLLOWUP_RUN_GUIDE_20260921.md)를 참고하세요.

기존 분석 코드는 [SAS 코드 안내](sas/README.md)와 [런북](sas/RUNBOOK.md)을 따릅니다.
과거 분석의 원문·행별 입력은 공개본에서 제외했으므로 별도 승인된 로컬 입력이 필요합니다.
최신 집계 전용 패키지는 포함된 집계 CSV를 사용합니다.

## 폴더와 공개 범위

| 폴더 | 용도 |
|---|---|
| `materials/20260921_final_v1/` | 후속 결과를 반영한 최신 발표본·대본·문답 |
| `visualization_20260921_v1/` | 새 Studio 보고서 코드·CAS 게시·VA 구성 안내 |
| `materials/20260921/` | 발표·설명·검증 결과를 모은 날짜별 열람본 |
| `followup_20260921_v1/` | 최신 집계 전용 SAS 실행 코드와 입력 |
| `sas/` | 기존 SAS 분석·CAS 선택 실행 코드와 런북 |
| `docs/` | 실행 안내·설계·저장소 정리 기록 |
| `data/`, `reports/` | 공개 가능한 기존 집계와 안내 |
| `archive/` | 과거 코드·집계 결과와 전달 이력 |
| `manifests/` | 전달본 구성·검증 기록 |

공개본에는 원문 문자, 실제 URL·개인정보, 행별 예측, 모델 가중치, 인증정보를 새로 넣지 않습니다.
기존 추적 파일의 정리와 보존 범위는 [정리 기록](docs/REPOSITORY_ORGANIZATION_20260921.md)을 따릅니다.
이번 정리는 현재 파일 트리를 대상으로 하며 과거 Git 커밋을 재작성하지 않았습니다.

U5는 과거 평가 이력이 있는 자료이고, KISA 외부 스미싱만으로 정상 문자 오탐률을 계산할 수 없습니다.
기존 정상 후보의 회귀 검사와 JEV 결합 탐색도 새로운 독립 성능 검증과 구분합니다.
