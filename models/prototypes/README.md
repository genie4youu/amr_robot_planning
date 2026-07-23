# Prototype Models

단일 이론 또는 subsystem만 확인하는 작은 모델을 둔다.

예정 예:

- `amr_diff_drive_prototype.slx`
- `amr_lidar_prototype.slx`
- `amr_mapping_prototype.slx`
- `amr_stateflow_mission_prototype.slx`

## 현재 모델

- `amr_milestone01.slx`: Stateflow 정상 임무 시퀀스와 차동구동 플랜트를 연결한 첫 실행 기준선
- `amr_scenario_supervisor.slx`: 장애물·저전압·경로이탈 입력과 복구 모드를 가진 Stateflow Scenario Lab
- `scripts/run_amr_milestone01.m`: 시뮬레이션, 자동 검증, 결과 그림 생성을 담당
- `scripts/build_amr_milestone01_skeleton.m`: 플랜트와 로깅 블록의 초기 골격 생성용이며 기존 모델을 덮어쓰지 않음

prototype을 통합 모델에서 직접 참조하지 않는다. 검증된 로직만 정리해 옮긴다.
