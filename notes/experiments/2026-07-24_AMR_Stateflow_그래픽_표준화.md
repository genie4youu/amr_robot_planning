# AMR Mission Supervisor Stateflow 그래픽 표준화

## 목적

논리 객체만 생성한 Stateflow 차트를 사람이 검토할 수 있는 그래픽 설계로 바꾸고, 이후
차트에서도 같은 품질 게이트를 재사용한다.

## 적용한 방법

1. 원본 모델과 논리·그래픽 기준선을 `work/backups/`에 저장했다.
2. 상태 액션은 실행 표현식을 유지한 채 한 줄에 한 명령이 보이도록 공백과 줄바꿈만 정리했다.
3. 모든 State 37개와 Transition 67개에 선언적 레이아웃 행을 만들었다.
4. 정상 흐름은 상단, 복구·실패 흐름은 하단으로 분리했다.
5. 공통 검사기와 MATLAB 단위 테스트를 추가했다.
6. Update Diagram과 기존 시나리오를 다시 실행했다.

## 시행착오

첫 자동 검사는 hard violation 32건을 보고했다.

- Transition label–State 13건
- Transition label–label 7건
- 관계없는 State를 지나는 근사 경로 11건
- 동일 Source endpoint 간격 부족 1건

라벨을 독립 행으로 옮기고 전이 통로를 다시 지정해 32 → 12 → 7 → 5 → 0건으로 줄였다.
텍스트 폭 근사 advisory 10건은 MissionRegion의 4열 그리드와 NavIdle/Replanning 폭을
확대해 0건으로 줄였다.

가장 중요한 API 관찰은 `SourceOClock`, `DestinationOClock`, `MidPoint`가 서로
독립적이지 않다는 점이다. 한 속성을 나중에 설정하면 Stateflow가 다른 접점 또는 경유점을
다시 계산한다.

- 기본 적용 순서: `DestinationOClock → SourceOClock → MidPoint → LabelPosition`
- 도착 포트가 중요한 예외: `SourceOClock → DestinationOClock → MidPoint`
- 요청값만 믿지 않고 저장 후 실제 endpoint와 midpoint를 다시 읽어 검사
- 실행 우선순위는 그래픽 위치가 아니라 원본 `ExecutionOrder`와 outgoing 순서 비교로 보존

## 최종 결과

- 그래픽 hard violation: 0
- exact routing violation: 0
- 보수적 approximate routing warning: 6
- 텍스트 advisory: 0
- Code Analyzer: 레이아웃 스크립트·검사기·그래픽 테스트 issue 0
- Update Diagram: PASS
- `model_check`: healthy
- 원본 논리 서명 비교: PASS
- routing-only State 위치·label 변경: 0
- 저장→닫기→재열기 geometry 비교: PASS
- 그래픽 테스트: 11/11 PASS
- 인터페이스 테스트: 16/16 PASS
- 시나리오: 9/9 PASS
- 프로젝트 공통 알고리즘 회귀: 8/8 PASS

상세 좌표와 검증표는 `docs/results/STATEFLOW_GRAPHICAL_LAYOUT_RESULT.md`에 기록했다.

## Transition routing 전용 2차 작업

추가 기준은 “정상 진행은 직선, 반대 방향은 완만한 평행 곡선, 장거리 복귀는 차트
외곽 통로”로 고정했다. 67개 전이를 `AdjacentHorizontal`, `AdjacentVertical`,
`Bidirectional`, `LongOuter`, `Default`로 전부 분류하고 방향 역할, 병렬 그룹, lane과
geometry 적용 순서를 표에 포함했다.

서브차트 좌표는 상위 Chart 좌표와 같지 않았다. 저장 과정에서 각 Stateflow
`Subviewer` scope가 공통 offset으로 재배치될 수 있어 다음 방식으로 처리했다.

1. State와 Transition을 `Subviewer`별로 그룹화한다.
2. routing-only 실행 시 현재 State 위치와 canonical 명세 사이의 scope 공통 offset을
   구한다.
3. State는 건드리지 않고 Transition의 MidPoint와 LabelPosition만 같은 offset으로
   평행이동한다.
4. scope 안에서 State 크기 또는 offset이 서로 다르면 자동 적용을 중단한다.
5. 저장 직후뿐 아니라 모델을 닫고 다시 열어 State 위치, 정확한 label, 실제 geometry와
   논리 서명을 비교한다.

최종 재실행 전 백업은
`work/backups/amr_mission_supervisor_v1_pre_layout_20260724_143020.slx`다.

## 남은 한계

정확한 위반과 State/label 관통은 모두 0이지만, 두 선분 근사 검사에는 MissionRegion의
path–path 교차 후보 6건이 남았다. 단일 MidPoint와 State 위치 고정 조건에서 격자와 수동
조정을 반복했을 때 한 교차를 없애면 다른 State 관통 또는 새 교차가 생겼다.

Junction을 넣으면 다중 굴곡 경로를 만들 수 있지만 Stateflow의 평가 의미와 우선순위에
영향을 줄 수 있어 routing-only 단계에서는 추가하지 않았다. 상세 6건은
`results/2026-07-24_transition_routing_approximate_warnings.csv`에 보존했다.
