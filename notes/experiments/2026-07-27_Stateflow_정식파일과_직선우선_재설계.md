# Stateflow 정식 파일과 직선 우선 재설계

## 목적

- 여러 `v1`, `v2`, `graphical` 파일 중 최신본을 추측하지 않게 한다.
- Simulink 루트 다이어그램을 좌→우 신호 흐름으로 읽을 수 있게 한다.
- Mission child State가 한쪽에 쏠리고 Transition이 큰 곡선으로 돌아가는 현상을 줄인다.
- 이후 새 차트에도 같은 파일명과 그래픽 규칙을 적용한다.

## 파일 정리

현재 정식 Mission Supervisor는 다음 한 파일이다.

- `models/prototypes/amr_mission_supervisor.slx`

교체된 모델은 삭제하지 않고 `models/history/`로 이동했다.

- `amr_mission_supervisor_logic_baseline_2026-07-24.slx`: 그래픽 작업 전 논리 기준선
- `amr_mission_supervisor_curved_layout_2026-07-27.slx`: 과도한 곡선과 child 쏠림이 남았던 비교본

활성 모델은 버전 없는 정식 이름을 사용하고, 이전본에만 날짜와 역할을 붙이는 규칙으로
통일했다.

## Simulink 루트 재배치

- 26개 Inport를 MissionSupervisor 입력 포트의 높이에 맞춰 왼쪽에 정렬했다.
- MissionSupervisor를 중앙, 출력과 SafetyCommandArbiter를 오른쪽에 배치했다.
- 연결선이 대부분 좌→우 수평으로 흐르도록 블록 위치를 조정했다.
- 신호 인터페이스를 바꾸는 Bus 리팩터링은 이번 작업에서 제외해 기존 동작을 보존했다.

## Stateflow 재배치와 라우팅

- Mission 정상 흐름 8개 State를 상단 한 행에 배치했다.
- 공통 취소 흐름인 Aborting을 하단의 별도 행에 배치했다.
- child Subviewer별 canvas를 따로 계산해 좌상단 쏠림을 검사한다.
- Transition 경로의 우선순위를 `직선 → 한 번 꺾는 최단 경로 → 필요한 외곽 통로`로 바꿨다.
- 큰 원호, S자 경로, State를 돌아가는 불필요한 장거리 경로를 금지했다.
- Stateflow 일반 Transition은 endpoint와 MidPoint 하나만 제공하므로 여러 번 꺾이는 완전한
  직각 polyline은 표현할 수 없다. 시각적 꺾임만을 위한 Junction은 실행 의미를 바꿀 수 있어
  추가하지 않았다.

## 검증

- State / Transition / Data 논리 서명: 37 / 67 / 42 보존
- Source / Destination / LabelString / ExecutionOrder: 보존
- hard graphical violation: 0
- exact routing violation: 0
- child scope의 보수적 path-path 경고: 0
- 최상위 예외 복귀 전이의 보수적 path-path 경고: 2개, 단위 테스트에 명시
- 그래픽 / 인터페이스 / scripted-plant: 15/15 / 16/16 / 9/9 PASS
- Update Diagram 및 구조 검사: PASS

세부 수치와 남은 경고 쌍은
`docs/results/STATEFLOW_GRAPHICAL_LAYOUT_RESULT.md`에서 확인한다.
