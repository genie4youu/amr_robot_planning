# AMR 학습 문서 안내

이 프로젝트는 실행 코드만 제공하지 않는다. 이론을 공부한 순서, 설계 판단, 구현 방법, 검증 결과를
코드와 같은 프로젝트 안에서 추적할 수 있게 구성한다.

## 무엇을 찾을 때 어디를 읽는가

| 알고 싶은 내용 | 시작 문서 |
| --- | --- |
| 프로젝트 목표와 범위 | [프로젝트 계획](PROJECT_PLAN.md) |
| 전체 학습·구현 순서 | [이론 및 단계별 학습 색인](THEORY_INDEX.md) |
| 핵심 이론과 개념 | `stages/<단계>/01_*_이론.md` |
| 단계별 설계·구현 방법 | `stages/<단계>/02_*_구현_및_검증.md` |
| 단계별 실행 결과 | `stages/<단계>/*_진행결과.md` |
| 시스템 구조와 인터페이스 | [아키텍처](ARCHITECTURE.md) |
| Stateflow 설계 방식 | [Industrial Stateflow 구조](INDUSTRIAL_STATEFLOW_ARCHITECTURE.md) |
| Stateflow 그래픽 배치·검증 규칙 | [Stateflow 그래픽 설계 표준](STATEFLOW_GRAPHICAL_STANDARD.md) |
| Mission Supervisor 그래픽 재설계 결과 | [그래픽 재설계 결과](results/STATEFLOW_GRAPHICAL_LAYOUT_RESULT.md) |
| Single Supervisor 요구사항 기준선 | [요구사항 안내](../requirements/README.md) |
| Single Supervisor 시스템 경계 | [시스템 컨텍스트](architecture/SYSTEM_CONTEXT.md) |
| 상태·전이·인터페이스 상세 | [상태 계층](architecture/STATE_HIERARCHY.md), [전이 표](architecture/TRANSITION_TABLE.md), [인터페이스](architecture/INTERFACES.md) |
| 요구사항–설계–시험 연결 | [추적성](verification/TRACEABILITY.md) |
| Supervisor 시험과 실제 결과 | [시험 계획](verification/TEST_PLAN.md), [v1 결과 기준선](results/RESULT_BASELINE.md) |
| 선택한 방법과 이유 | [설계 결정 기록](DECISIONS.md) |
| 현재 완성도와 남은 작업 | [진행 상태](PROGRESS.md) |
| 최종 검증 결과와 그림 | [결과](RESULTS.md) |
| 실행 방법 | [Getting Started](GETTING_STARTED.md) |
| 공개 참고 자료 | [공개 출처](references/공개_출처.md) |
| 실제 프롬프트와 시행착오 | `../notes/prompts/`, `../notes/experiments/` |

## 단계 문서의 공통 순서

각 `docs/stages/NN_topic/`은 다음 흐름을 따른다.

1. 단계 개요와 완료 조건
2. 이론·수식·핵심 개념
3. 설계 선택과 구현·검증 방법
4. 실제 결과, 실패와 다음 단계

따라서 코드를 먼저 읽기보다 `THEORY_INDEX.md`에서 관심 단계를 고른 뒤 해당 단계 문서를 순서대로
읽는 것이 좋다. 구현 파일은 각 문서에서 `src/`, `scripts/`, `models/`, `tests/`의 실제 경로로 연결한다.
