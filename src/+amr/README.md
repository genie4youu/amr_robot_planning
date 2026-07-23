# `amr` MATLAB Package

프로젝트 함수 이름 충돌을 막기 위한 최상위 namespace다.

예정 호출 예:

```matlab
poseNext = amr.modeling.integrateDifferentialDrive(pose, cmd, dt);
path = amr.planning.planAStar(costmap, startCell, goalCell);
```

실제 함수는 해당 단계가 시작될 때 추가한다.

## 현재 UI package

- `amr.ui.createDemoFloorMap`: 벽·장애물·시작점·목표점으로 구성된 미터 단위 실내 맵
- `amr.ui.AmrMapPlaybackApp`: Simulink 자세 로그를 로봇 애니메이션으로 재생하는 대시보드
- `amr.ui.createScenarioFloorMap`: 12m × 8m Scenario Lab 지도
- `amr.ui.AmrScenarioPlaybackApp`: 상황 선택과 배터리·fault 상태를 포함한 대형 지도 UI
- `amr.scenarios.scenarioEngineStep`: waypoint 주행, 배터리와 deterministic fault injection
