# 실패 지도

> **자동 생성** — `scripts/build_failure_map.py`. 손으로 고치지 않는다.
> 모든 칸은 `reports/generated/` 산출물에서 왔고, 출처 열이 그것을 가리킨다.

탐지기 하나에 대해 **어디서 틀리는가**를 조건별로 모은 표다. 단일 F1이 무엇을 감추는지가 이 표의 존재 이유다.

## 한눈에

- 테스트셋 전체 재현율 **94.33%**
- 내부 테스트에서 가장 낮은 조건 **신규 (<0.50) 73.68%** · 전체와의 기술적 차이 20.64%p (유의성 검정 아님)
- 내부 그룹 홀드아웃 전체 오탐률 **0.24%**
- 측정된 칸 26개 · 미측정/검수 대기 1개
- 표본 30건 미만이라 값을 그대로 읽으면 안 되는 칸 **2개**

이 표는 조건별 기술통계다. 전체와 부분집합은 관측치를 공유하므로 독립 표본처럼 비교하지 않는다. 신뢰구간의 겹침 여부로 차이의 유의성을 판정하지 않는다.

## 전체

| 조건 | 지표 | 평가 n | 값 | 95% 신뢰구간 | 평가 상태 | 표집 | 출처 |
|---|---|---:|---:|---|---|---|---|
| 테스트셋 전체 | 재현율 | 652 | 94.33% | [92.28%, 95.86%] | evaluated | 내부 그룹 홀드아웃 | `generalization_evaluation.json` |
| 테스트셋 전체 | 오탐률 | 1665 | 0.24% | [0.09%, 0.62%] | evaluated | 내부 그룹 홀드아웃 | `generalization_evaluation.json` |

## 신규성

| 조건 | 지표 | 평가 n | 값 | 95% 신뢰구간 | 평가 상태 | 표집 | 출처 |
|---|---|---:|---:|---|---|---|---|
| 사실상 중복 (>=0.90) | 재현율 | 49 | 100.00% | [92.73%, 100.00%] | evaluated | 내부 그룹 홀드아웃 | `generalization_evaluation.json` |
| 높은 유사 (0.70~0.90) | 재현율 | 416 | 98.80% | [97.22%, 99.49%] | evaluated | 내부 그룹 홀드아웃 | `generalization_evaluation.json` |
| 중간 유사 (0.50~0.70) | 재현율 | 73 | 97.26% | [90.55%, 99.25%] | evaluated | 내부 그룹 홀드아웃 | `generalization_evaluation.json` |
| 신규 (<0.50) | 재현율 | 114 | 73.68% | [64.92%, 80.90%] | evaluated | 내부 그룹 홀드아웃 | `generalization_evaluation.json` |

## 정상 안내문자 (모델 점수 선별)

| 조건 | 지표 | 평가 n | 값 | 95% 신뢰구간 | 평가 상태 | 표집 | 출처 |
|---|---|---:|---:|---|---|---|---|
| 검수 정상 전체 · 기존 split 중복 포함 | 오탐률 | 310 | 6.77% | [4.47%, 10.13%] | evaluated | 모델 점수 선별 | `hard_negative_evaluation.json` |
| 검수 정상 · account_security | 오탐률 | 38 | 5.26% | [1.46%, 17.29%] | evaluated | 모델 점수 선별 | `hard_negative_evaluation.json` |
| 검수 정상 · banking_auth | 오탐률 | 26 | 0.00% ⚠︎표본부족 | [0.00%, 12.87%] | evaluated | 모델 점수 선별 | `hard_negative_evaluation.json` |
| 검수 정상 · card_payment | 오탐률 | 28 | 3.57% ⚠︎표본부족 | [0.63%, 17.71%] | evaluated | 모델 점수 선별 | `hard_negative_evaluation.json` |
| 검수 정상 · delivery | 오탐률 | 46 | 8.70% | [3.43%, 20.32%] | evaluated | 모델 점수 선별 | `hard_negative_evaluation.json` |
| 검수 정상 · public_service | 오탐률 | 172 | 8.14% | [4.91%, 13.20%] | evaluated | 모델 점수 선별 | `hard_negative_evaluation.json` |

## 정상 안내문자 (중복 분리)

| 조건 | 지표 | 평가 n | 값 | 95% 신뢰구간 | 평가 상태 | 표집 | 출처 |
|---|---|---:|---:|---|---|---|---|
| 기존 split 완전 중복 · 내부 진단 | 오탐률 | 171 | 4.09% | [2.00%, 8.21%] | evaluated | 모델 점수 선별 | `hard_negative_evaluation.json` |
| 완전 비중복 · 선별 스트레스 표본 | 오탐률 | 139 | 10.07% | [6.09%, 16.20%] | evaluated | 모델 점수 선별 | `hard_negative_evaluation.json` |

## 기관사칭

| 조건 | 지표 | 평가 n | 값 | 95% 신뢰구간 | 평가 상태 | 표집 | 출처 |
|---|---|---:|---:|---|---|---|---|
| KISA 기관사칭 후보 300건 · 검수 대기 | 재현율 | 0 | — | — | review_pending | 선별 데이터셋 내 평가 | `agency_impersonation_evaluation.json` |

## 유형 × 신규성

| 조건 | 지표 | 평가 n | 값 | 95% 신뢰구간 | 평가 상태 | 표집 | 출처 |
|---|---|---:|---:|---|---|---|---|
| delivery · 유사도 [0.0, 0.3] | 탐지율 | 576 | 98.78% | [97.51%, 99.41%] | evaluated | 선별 데이터셋 내 평가 | `failure_decomposition.json` |
| public_agency · 유사도 [0.0, 0.3] | 탐지율 | 97 | 81.44% | [72.56%, 87.93%] | evaluated | 선별 데이터셋 내 평가 | `failure_decomposition.json` |
| delivery · 유사도 (0.3, 0.5] | 탐지율 | 1251 | 99.76% | [99.30%, 99.92%] | evaluated | 선별 데이터셋 내 평가 | `failure_decomposition.json` |
| public_agency · 유사도 (0.3, 0.5] | 탐지율 | 462 | 97.62% | [95.79%, 98.67%] | evaluated | 선별 데이터셋 내 평가 | `failure_decomposition.json` |
| delivery · 유사도 (0.5, 0.7] | 탐지율 | 626 | 99.52% | [98.60%, 99.84%] | evaluated | 선별 데이터셋 내 평가 | `failure_decomposition.json` |
| public_agency · 유사도 (0.5, 0.7] | 탐지율 | 678 | 99.85% | [99.17%, 99.97%] | evaluated | 선별 데이터셋 내 평가 | `failure_decomposition.json` |
| delivery · 유사도 (0.7, 1.0] | 탐지율 | 560 | 99.46% | [98.44%, 99.82%] | evaluated | 선별 데이터셋 내 평가 | `failure_decomposition.json` |
| public_agency · 유사도 (0.7, 1.0] | 탐지율 | 989 | 100.00% | [99.61%, 100.00%] | evaluated | 선별 데이터셋 내 평가 | `failure_decomposition.json` |

## 편향 제거 비용

| 조건 | 지표 | 평가 n | 값 | 95% 신뢰구간 | 평가 상태 | 표집 | 출처 |
|---|---|---:|---:|---|---|---|---|
| 반사실 증강 전 · 악성 URL 있음 | 미탐률 | 598 | 1.84% | [1.03%, 3.26%] | evaluated | 내부 그룹 홀드아웃 | `models/text/kcbert/test_probabilities.csv` |
| 반사실 증강 후 · 악성 URL 있음 | 미탐률 | 598 | 6.69% | [4.95%, 8.98%] | evaluated | 내부 그룹 홀드아웃 | `models/text/kcbert_cf/test_probabilities.csv` |
| 반사실 증강 전 · 악성 URL 없음 | 미탐률 | 54 | 5.56% | [1.91%, 15.11%] | evaluated | 내부 그룹 홀드아웃 | `models/text/kcbert/test_probabilities.csv` |
| 반사실 증강 후 · 악성 URL 없음 | 미탐률 | 54 | 3.70% | [1.02%, 12.54%] | evaluated | 내부 그룹 홀드아웃 | `models/text/kcbert_cf/test_probabilities.csv` |

## 이 표를 읽는 법

1. **평가 범위와 분모를 먼저 읽는다.** 내부 테스트, 선별 스트레스 표본, 외부 공개 데이터는 모집 과정이 다르다.
2. **신뢰구간은 차이 검정을 대신하지 않는다.** 비교하려면 같은 관측치의 대응 관계와 유사 문구 군집을 반영한 직접 대비가 필요하다.
3. **오탐률과 재현율을 같은 축에서 비교하지 않는다.** 방향이 반대다.
4. **모델 점수 선별 표본의 FPR은 모집단 추정치나 통계적 상한이 아니다.** 기존 split 중복분은 내부 진단이고, 완전 비중복분에도 유사 문구·출처 의존성·선별 편향이 남는다.
5. **`편향 제거 비용` 축은 다른 축과 성격이 다르다.** 나머지는 현재 모델이 어디서 틀리는지이고, 이 축은 고쳤을 때 무엇을 잃는지다.
6. **검수 대기는 성능 0%가 아니다.** 평가 적격 행이 없으면 예측·재현율을 만들지 않고 미측정 상태로 남긴다.
7. **Wilson 구간은 각 행을 독립 관측으로 취급한 표본 내 구간이다.** 유사 문구 군집 의존성이나 표본 선택 편향을 보정한 구간은 아니다.
