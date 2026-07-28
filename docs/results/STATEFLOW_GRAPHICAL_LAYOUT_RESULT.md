# Mission Supervisor Stateflow 그래픽 재설계 결과

## 결과 모델

- 현재 정식 모델: `models/prototypes/amr_mission_supervisor.slx`
- 논리 기준선: `models/history/amr_mission_supervisor_logic_baseline_2026-07-24.slx`
- 이전 그래픽 시도: `models/history/amr_mission_supervisor_curved_layout_2026-07-27.slx`
- 레이아웃: `scripts/layout_amr_mission_supervisor.m`
- 검사기: `src/+amr/+stateflow/inspectGraphicalLayout.m`
- 단위 테스트: `tests/unit/StateflowGraphicalLayoutTest.m`

기존 스크립트·검사기·테스트를 먼저 감사한 뒤 원본을 덮어쓰지 않고 별도 복사본에서 State
재배치와 Transition 재라우팅을 수행했다. 상세 감사 근거, Position 및 Navigation Transition
표는 `notes/experiments/2026-07-27_Stateflow_그래픽_감사와_v2_재설계.md`에 있다.

## 핵심 변경

- 정상 흐름은 상단, 예외·복구·실패 흐름은 하단으로 분리했다.
- Navigation 하단은 `NavFailed – Recovery – Replanning` 순서로 두어 Replanning을 Tracking
  아래, Recovery를 Planning 아래에 배치했다.
- Mission 정상 흐름 8개 State는 한 행의 직선 흐름으로 두고, 공통 예외 State인 Aborting은
  아래쪽 넓은 행에 배치했다. cancellation 전이가 중간 정상 State를 가로지르지 않는다.
- 과도한 Navigation 외곽 곡선을 짧은 내부 왕복 경로로 바꾸고 실제 endpoint를 분리했다.
- Simulink 루트의 26개 입력과 11개 출력을 Chart 포트 높이에 맞춰 좌→우 직선으로 정렬했다.
- State/Transition LabelString을 공백과 줄바꿈까지 정확히 보존했다.
- 외곽 lane 최대 이격, Subviewer canvas 활용률·확장, bidirectional detour 상한을 검사기와
  테스트에 추가했다.
- 원본 쓰기 차단과 명시적 후보 `ModelPath`를 레이아웃 함수 기본 계약으로 추가했다.

## 검증 결과

| 검증 | 결과 |
| --- | --- |
| State / Transition / Data 논리 서명 | 37 / 67 / 42 모두 원본과 동일 |
| Transition Source, Destination, LabelString, ExecutionOrder | 모두 동일 |
| 저장→종료→재열기 geometry | PASS |
| hard graphical violation | 0 |
| exact routing violation | 0 |
| State·라벨 겹침 / State 관통 / label-path | 0 / 0 / 0 |
| canvas balance / excessive outer / bidirectional detour | 0 / 0 / 0 |
| 보수적 path-path 두 선분 근사 경고 | 2, 최상위 예외 전이에 한정하고 테스트에 명시 |
| Mission State bounding-box 활용률 | 0.794 |
| Navigation State bounding-box 활용률 | 0.711, 원본 0.302 |
| Navigation 방향별 확장 | L 10.4 / R 20 / T 145 / B 50 px |
| MATLAB Code Analyzer | 변경한 5개 `.m` 파일 issue 0 |
| Update Diagram / `model_check` | PASS / healthy |
| 그래픽 / 인터페이스 / scripted-plant | 15/15 / 16/16 / 9/9 PASS |
| 공통 알고리즘 회귀 | 8/8 PASS |

남은 두 경고는 최상위 예외 복귀 전이 T60과 T54, T60과 T61의 조합이다. Stateflow API가
렌더링 spline을 제공하지 않아 endpoint–midpoint 두 선분으로 보수적으로 판정한 결과다.
Mission과 Navigation child scope에는 근사 경고가 남아 있지 않다. Junction 추가는 실행
의미를 바꿀 수 있어 사용하지 않았으며, 경고 쌍을 단위 테스트에서 고정해 새 경고가 조용히
늘지 않게 했다.

`sfprint(..., wholeChart=true)`는 Subchart 객체보다 큰 편집 작업면을 출력할 수 있다.
최종 화면은 `fitToView` 편집기 검토와 저장 후 좌표 기반 canvas 지표를 함께 사용해 판정했다.
