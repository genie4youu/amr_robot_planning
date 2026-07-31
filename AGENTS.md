# AGENTS.md — Indoor Delivery AMR

## 프로젝트 목표

MATLAB, Simulink, Stateflow만으로 실내 배송 AMR의 핵심 알고리즘과 상위 제어 구조를 공부하고,
이론·설계·구현·검증·결과를 재현 가능한 프로젝트로 보존한다.

## 기준 환경

- MATLAB R2025b Update 5
- Simulink
- Stateflow
- Simulink Test 없음
- MATLAB MCP Server의 실행 중인 세션 사용

## 시작점

- MATLAB Project: `AMRRobotPlanning.prj`
- 학습 문서 길잡이: `docs/README.md`
- 학습 순서: `docs/THEORY_INDEX.md`
- 실행 안내: `docs/GETTING_STARTED.md`
- 대표 통합 모델: `models/integrated_system/amr_integrated_delivery_system.slx`
- 전체 단위검사: `scripts/run_unit_verification.m`

## 작업 규칙

1. 기본적으로 이 프로젝트 루트 밖의 파일을 읽거나 쓰지 않는다. 사용자가 작업공간 공통 구조 변경을
   명시적으로 요청한 경우에만 상위 작업공간 폴더 안에서 작업한다.
2. 이 프로젝트 밖의 개인 노트 저장소와 업무 자료는 경로가 주어져도 읽거나 쓰지 않는다.
3. MATLAB 작업 전에 `AMRRobotPlanning.prj`가 열린 상태인지 확인한다.
4. 전역 `startup.m`, MATLAB 시작 폴더와 전역 path를 수정하지 않는다.
5. 프로젝트 파일 등록과 MATLAB Project path를 구분한다.
6. `slprj/`, `work/`, 실행 중 생성된 `results/`를 소스 파일로 취급하지 않는다.
7. 모델을 수정하기 전에 현재 Simulink·Stateflow 구조와 대상 ID를 읽는다.
8. 기존 State, Transition, 블록과 신호를 요청 없이 삭제하지 않는다.
9. Transition label, temporal logic와 action 문법을 추측하지 않고 현재 모델과 공식 문서로 확인한다.
10. 모델 편집은 작은 범위로 수행하고, 전체 모델 재생성이나 기존 `.slx` 덮어쓰기를 피한다.
11. 모델 수정 후 변경 구조를 다시 읽고 `model_check`를 실행한다.
12. Simulink Test가 없으므로 `model_test`를 사용하지 않는다.
13. 동작 검증은 `run_*`, `verify_*`와 MATLAB `assert`를 사용한다.
14. 기존 Git 변경은 사용자의 작업으로 간주하고 관련 없는 변경을 되돌리지 않는다.

## 문서 규칙

- 정리된 이론·설계·검증·결과는 `docs/`에 둔다.
- 단계 작업은 `docs/stages/NN_topic/`의 개요 → 이론 → 구현·검증 → 결과 순서를 유지한다.
- 실제 프롬프트는 `notes/prompts/`, 시행착오는 `notes/experiments/`에 남긴다.
- 실패한 실행과 오류 원문도 삭제하지 않고 기록한다.
- 회사 자료를 사용하지 않으며 공개 문서나 직접 만든 합성 예제만 사용한다.
- 새 이론·설계 접근법에는 `docs/references/공개_출처.md`에 출처를 추가한다.

## 완료 조건

- 변경한 MATLAB 파일에 Code Analyzer 문제가 없다.
- 수정한 모델이 오류 없이 로드되고 구조검사에서 해결하지 않은 문제가 없다.
- 관련 단위검사 또는 시나리오 검증이 통과한다.
- 이론 설명, 설계 문서와 실제 구현이 일치한다.
- 변경 파일, 실행 명령, 검증 결과와 남은 한계를 보고한다.

## Stateflow 그래픽 필수 규칙

모든 Stateflow 생성·수정 작업은 `docs/STATEFLOW_GRAPHICAL_STANDARD.md`를 따른다.

현재 승인된 v07 위치·배율은 `amr.stateflow.graphicalLayoutProfile`에 고정되어 있다. 이후
Mission Supervisor에 새 State/Subchart를 추가하거나 새 Stateflow 차트를 만들 때도 이름과
무관하게 같은 프로필을 기본값으로 적용한다.

- Subchart 직접 자식의 로컬 시작점은 기본 `[100 120]`, 상단 복귀 lane이 있으면
  `[100 200]`이고 허용 범위는 `minX=80..120`, `minY=100..200`이다.
- 부모 차트의 Subchart State `Position`과 `subviewS.pos`를 내부 State 정렬 영역으로 쓰지
  않는다.
- 배치 후 페이지 최소 여백 60 px, 목표 활용률 `[0.90 0.82]`, 실제 화면 최대 축 활용률
  0.70 이상, 가로 0.93 이하, 세로 0.82 이하를 검사한다.
- 저장된 확대율만으로 문제를 숨기지 않고, 저장·닫기·재열기 후 모든 Subchart에서
  `view`/`fitToView`, page rectangle, viewport 지속성과 논리·geometry 보존을 검증한다.

- 논리 생성과 그래픽 레이아웃을 별도 단계로 수행하고, 기존 모델은 레이아웃 작업 전에
  `work/backups/`에 백업한다.
- 검증 완료 원본은 직접 덮어쓰지 않고 별도 후보 `ModelPath`에서 작업하며, 전체 배치를
  반복할 때는 원본에서 새 후보를 만든다.
- 정상 흐름은 상단, 예외·복구·실패 흐름은 하단에 배치하며 State 사이에 수평 80 px,
  수직 110 px 이상의 여백을 둔다.
- State의 `Position`과 `FontSize`, Transition의 `SourceOClock`, `DestinationOClock`,
  `MidPoint`, `LabelPosition`을 의도적으로 설정한다.
- Transition 라우팅은 충돌 없는 최단 경로를 우선하며 `직선 → 한 번 꺾는 직각형 경로 → 외곽 통로` 순으로 선택한다. 큰 원호와 S자 경로는 허용하지 않는다.
  모든 라우팅 행에 `AdjacentHorizontal`,
  `AdjacentVertical`, `Bidirectional`, `LongOuter`, `SelfLoop`, `Default` 중 하나의
  `RoutingType`을 기록한다.
- `LongOuter` lane은 State envelope 및 다른 lane과 40 px 이상 떨어뜨리고,
  `SelfLoop`의 Source/Destination 포트는 시계 눈금 기준 최소 2시간 분리한다. Junction은
  의미 보존을 검증할 수 있을 때만 사용하는 마지막 수단이다.
- `LongOuter` 최대 이격 180 px, Subviewer State bounding-box 활용률 0.50 이상, 방향별
  canvas 확장 180 px 이하, `Bidirectional` envelope 이탈 120 px 이하와 detour ratio
  2.20 이하를 검사한다.
- routing-only 작업에서는 모든 State `Position`을 전후 비교하며 변경 허용 건수는 0건이다.
  State 이동이 필요하면 별도의 State 배치 작업으로 분리한다.
- 레이아웃 전후의 Transition Source, Destination, LabelString, outgoing 순서와
  `ExecutionOrder` 및 화면 전이 번호를 비교해 기존 평가 우선순위를 보존한다.
- `LabelString`은 공백과 줄바꿈까지 정확히 비교하고 레이아웃 작업에서 재서식하지 않는다.
- 새 차트에는 `scripts/layout_<model>.m`을 만들고
  `amr.stateflow.inspectGraphicalLayout` 및
  `tests/unit/StateflowGraphicalLayoutTest.m`에 대상 차트 검증을 등록한다. State나
  Transition을 추가할 때도 레이아웃 명세와 테스트를 같은 변경에서 갱신한다.
- 공통 검사 결과의 `HardViolationCount`는 0이어야 하며 advisory는 육안으로 검토해
  결과에 기록한다.
- `BadIntersection`, 객체·라벨 겹침과 전이 관통을 검사하고 Update Diagram,
  `model_check` 및 관련 회귀 검증을 통과해야 한다.
- 미분류 경로, 라우팅 겹침, 외곽 lane 40 px 위반, self-loop 2시간 위반, routing-only
  State 위치 변경과 의미 검증 없는 Junction 변경은 모두 0건이어야 한다.
- 두 선분 근사에서만 남는 path-path 경고는 SSID 쌍·이유·최종 화면을 테스트와 결과 노트에
  고정한 경우에만 예외 검토한다. State 관통, label 관련 경고와 hard/exact routing 위반은
  0건이어야 한다.
- 서브차트 좌표는 `Subviewer`별로 계산하고, 저장 후 모델을 닫고 다시 열어 State 위치,
  Transition geometry와 논리 서명을 재검증한다.
- `fitToView`는 모든 배치를 끝낸 뒤 최종 화면 확인 용도로만 사용한다.
