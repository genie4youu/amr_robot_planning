# 프로젝트 스크립트

주요 스크립트:

- `layout_amr_mission_supervisor.m`: 최신 정식 Mission Supervisor의 State/Transition 그래픽 배치
- `run_amr_mission_supervisor_scenarios.m`: 최신 정식 Mission Supervisor의 9개 scripted-plant 시나리오 검증
- `run_supervisor_verification.m`: 요구사항·인터페이스·그래픽·시나리오를 한 번에 검증하는 대표 진입점
- `launch_amr_scenario_ui.m`: 사무실·병원·창고와 네 주행 상황을 계산하고 지도 UI에서 재생
- `run_all_amr_scenarios.m`: 네 시나리오의 완료·오차·충돌 여부 회귀검증
- `run_environment_matrix.m`: 3개 환경 × 4개 상황 주행 회귀검증과 궤적 그림 생성
- `build_amr_scenario_model_skeleton.m`: Scenario Lab 모델 생성
- `build_amr_industrial_supervisor.m`: 계층/병렬 Stateflow 모델 생성
- `run_industrial_supervisor_scenarios.m`: 감독 제어기 다섯 시나리오 회귀검증
- `build_amr_integrated_system.m`: 주행 Plant와 Industrial Supervisor 통합 모델 생성
- `run_integrated_delivery_scenarios.m`: 통합 normal/obstacle/battery/wrong-turn 검증
- `run_integrated_environment_matrix.m`: 같은 12개 조합의 lifecycle/병렬 mode 통합 검증
- `run_amr_milestone01.m`: 최소 수직 절편 재현

각 스크립트는 프로젝트 루트를 기준으로 동작하며 외부 폴더에 접근하지 않는다.

Mission Supervisor를 볼 때는 `models/prototypes/amr_mission_supervisor.slx`만 연다.
이전 `v1`, `v2_graphical` 모델은 `models/history/`의 비교·감사용 파일이다.
