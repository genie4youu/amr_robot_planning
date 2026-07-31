# 프로젝트 실행 명령

일반 사용자는 아래 대표 명령만 알면 된다.

| 목적 | 실행 명령 |
| --- | --- |
| 두 Mission Supervisor 레이아웃 비교 | `compare_mission_supervisor_layouts("MissionRegion")` |
| Mission Supervisor 전체 검증 | `run_supervisor_verification()` |
| 전체 단위검사 | `run_unit_verification()` |
| 3개 환경 × 4개 주행 검증 | `run_environment_matrix()` |
| 통합 Stateflow 환경 검증 | `run_integrated_environment_matrix()` |
| Scenario UI 실행 | `launch_amr_scenario_ui("obstacle", "hospital")` |

## 세부 실행·검증 함수

- `run_amr_mission_supervisor_scenarios.m`: Mission Supervisor 9개 시나리오
- `run_all_amr_scenarios.m`: 네 주행 시나리오 회귀검증
- `run_integrated_delivery_scenarios.m`: 통합 normal/obstacle/battery/wrong-turn 검증
- `run_industrial_supervisor_scenarios.m`: 감독 제어 예제 다섯 시나리오
- `run_amr_milestone01.m`: 첫 수직 절편 재현
- `launch_amr_map_ui.m`: 기본 지도 UI

## 생성·내부 유지보수 함수

아래 함수는 모델을 다시 만들거나 그래픽을 갱신할 때만 사용한다.

- `layout_amr_mission_supervisor.m`
- `build_amr_milestone01_skeleton.m`
- `build_amr_scenario_model_skeleton.m`
- `build_amr_industrial_supervisor.m`
- `build_amr_integrated_system.m`
- `create_default_amr_params.m`

Mission Supervisor 정식본·버전·비교 자료는 `models/mission_supervisor`, 전체 통합 모델은
`models/integrated_system`, 학습 모델은 `models/examples`에서 찾는다. `work`의 모델은 직접
열지 않는다.
