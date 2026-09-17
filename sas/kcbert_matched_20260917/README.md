# SAS Git 동기화용 KcBERT 코드 묶음 (v3)

이 폴더는 **코드와 집계 확인서만** 담는다. SAS/Python 코드는
`/home/student/github/sas/kcbert_matched_20260917/`에 Git 동기화할 수 있다.
`PRIVATE_DATA_NOT_IN_GIT.json`에는 로컬 사전 점검의 건수·해시·미실행 상태만 있다.

`model_rows.csv`, `edits.csv`, `checkpoint/`, 개별 예측과 결과 폴더는 GitHub·
CAS·VA에 올리지 않는다. 이들은 별도의 승인된 비공개 경로로
`/home/student/scamlens_private/` 아래에 전달해야 한다. 이 경로와 권한이
확인되지 않았다면 학습을 시작하지 않는다.

서버에서 같은 Compute context로 `00` → `01` → `01B`를 실행해 환경·입력·
짧은 학습 시간을 확인한다. `02_KCBERT_RUN.sas`와
`02_KCBERT_RUN_OPERATIONAL_COPY.sas`는 모두 기본적으로 승인 차단(`NO`)·
CPU 전체 학습 차단 상태다. 실제 실행 때는 **버전 폴더 밖**에 후자의 사본을
만들어 확인값과 CPU 허용을 필요에 따라 바꾼다. 수정본은 Git에 커밋하지 않고,
SHA-256과 실행 로그를 보관한다. 15개 arm 완료 후 `03`으로 저장 예측을 재계산한다.

SAS Studio 업로드 제한으로 checkpoint를 조각으로 올릴 때는 먼저
`00_KCBERT_REASSEMBLE.sas`의 `part_dir`를 실제 업로드 폴더로 바꾸고 실행한다.
`model.safetensors.part.*` 파일을 이름순으로 바이너리 병합하며, 최종 파일이 이미
있으면 덮어쓰지 않고 중단한다. 로그에 출력된 SHA-256을 분할 전 원본 해시와
대조한 뒤에만 `00_KCBERT_ENV_CHECK.sas`를 실행한다. 조각은 Git·CAS·VA에 올리지
않고 서버의 비공개 경로에 둔다.

경로는 현재 SAS Git checkout `/home/student/github`와 비공개 루트
`/home/student/scamlens_private`를 전제로 고정했다. 실제 경로가 다르면
v3 파일을 직접 수정·푸시하지 말고 새 버전으로 경로와 해시를 다시 고정한다.
`MANIFEST.json`은 수정 전 코드의 해시다. SAS 런타임·원격 라이브러리·
학습·CAS/VA 성공은 아직 확인되지 않았다.
