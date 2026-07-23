# planning

현재 구현:

- `planAStarGrid`: 8-connected A*, Euclidean heuristic, diagonal corner cutting 금지
- `smoothGridPath`: occupancy grid line-of-sight 기반 경로 단축
- 계획용 장애물 팽창 `0.40 m`, 안전 검사용 팽창 `0.30 m`
- `extractLocalCostmap`: robot-centred grid window
- `buildLocalCostmapFromLidar`: 정적 지도에 없는 scan hit marking/inflation
- `computeDynamicWindow`, `rolloutTrajectory`, `selectDwaCommand`: 가속도 제한 DWA 계열 지역 계획
- rollout과 braking trajectory의 collision hard rejection

다음 기능:

- 장애물 팽창과 distance cost
- distance-field clearance soft cost
- oscillation/stuck detector와 no-valid-candidate recovery

관련 단계: [07_global_planning](../../../docs/stages/07_global_planning/07_global_planning.md) · [08_local_planning_control](../../../docs/stages/08_local_planning_control/08_local_planning_control.md)
