# AMR 요구사항 기준선

이 폴더는 `Single AMR Mission Supervisor` 포트폴리오 프로젝트의 요구사항 초안을
보관한다. 현재 환경에는 Requirements Toolbox가 없으므로 구조화된 YAML을 기준
아티팩트로 사용한다.

## 기준 파일

- `amr_mission_supervisor_requirements.yaml`
  - 시스템 동작 요구사항의 유일한 초안 기준선
  - EARS 패턴을 적용한 `REQ_AMR_NNN` 형식
  - 모든 요구사항은 `status: Draft`, `keywords`의 `draft`로 명시
- `../docs/verification/TRACEABILITY.md`
  - 요구사항과 설계 요소, 시험 시나리오의 추적성 초안
- `../docs/verification/TEST_PLAN.md`
  - `TC_AMR_001..020`의 시험 수준, 입력, 기대 결과와 KPI
- `../docs/results/RESULT_BASELINE.md`
  - 실행한 검증과 아직 검증하지 않은 범위를 분리한 결과 기준선

## 변경 규칙

1. 기존 ID는 의미가 바뀌어도 재사용하거나 다시 번호를 매기지 않는다.
2. 새 요구사항은 마지막 번호 뒤에 추가한다.
3. 승인 전에는 `Draft` 상태를 유지한다.
4. 정량값을 넣을 때는 MATLAB workspace 또는 data dictionary의 파라미터 이름과
   해석된 값을 함께 기록한다.
5. 구현 구조가 아니라 시스템이 보여야 하는 동작을 `summary`에 쓴다.
6. 설계 근거와 출처는 각각 `rationale`, `description`에 남긴다.
7. YAML 변경 후 파싱, enum, ID, 상위 요구사항 참조를 검사한다.

현재 로컬 환경에는 범용 YAML parser가 없으므로 프로젝트의 제한된 YAML 포맷은
`tests/unit/verify_supervisor_requirements.m`으로 정적 검사한다. 이 검사는 범용 YAML
문법 검사를 대신하지 않으며, parser를 도입하면 두 검사를 함께 실행한다.

v1 요구사항 포맷, 인터페이스 단위시험과 scripted-plant 시나리오는 MATLAB Project를
연 뒤 다음 한 줄로 다시 실행할 수 있다.

```matlab
verification = run_supervisor_verification();
```

## 현재 범위

이 기준선은 다음 관심사를 포함한다.

- lifecycle과 reset
- mission sequence와 payload handshake
- navigation request, timeout, replanning과 recovery
- safety priority와 protective stop
- health, freshness watchdog과 fault latch
- battery energy mode와 충전
- deterministic arbitration과 diagnostics

이 문서는 기능 안전 인증이나 양산 사양이 아니다. `asil: Unset`은 안전 중요도가
없다는 뜻이 아니라, 이 개인 학습 프로젝트에서 공식 안전 등급을 할당하지 않았다는 뜻이다.
