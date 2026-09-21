# Jev × KcBERT 비교 결과

`index.html`을 브라우저에서 열면 결과와 한계를 읽을 수 있습니다. 외부 자산이나 원문 없이 동작합니다.

- `index.html`: 실제 집계 결과와 현재 조건의 자동 대체 비권장 결론
- `summary.json`: 공개 집계 정본의 사본
- `aggregate.csv`: SAS 입력용 시드·집단별 집계
- `verify_aggregates.sas`: CSV 산술 검사와 ODS 요약표 코드

질문·분류 규칙을 그대로 둔 사후 진단입니다. 원본 라벨은 바꾸지 않았고, 오류군을 과대표집했으므로 전체 탐지 성능이나 실서비스 오탐률로 일반화할 수 없습니다. 원문·개별 ID·점수·응답·가중치·자격증명은 이 폴더에 없습니다.

SAS 코드의 실제 SAS 실행은 미검증입니다. SAS 작업 폴더에 공개 CSV와 SAS 파일을 놓고 경로를 지정해 실행합니다.

```sas
%let root_dir = .;
%let agg_csv = aggregate.csv;
%include "verify_aggregates.sas";
```

저장소 정본은 `reports/generated/jev_kcbert_redacted_20260920.json`이며, 생성기는 `scripts/render_jev_kcbert_comparison_20260920.py`입니다. 원자료와 로컬 모델을 이용하는 추론 재현에는 별도의 비공개 입력이 필요합니다.
