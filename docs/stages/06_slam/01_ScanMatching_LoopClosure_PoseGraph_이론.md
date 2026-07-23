# Scan Matching, Loop Closure, Pose Graph 이론

## Correlative scan matching

odometry가 제공한 prior pose 주변에서 `dx`, `dy`, `dtheta` 후보를 탐색하고, 변환된 scan endpoint가 기존 map의 occupied 영역과 얼마나 잘 일치하는지 점수화한다.

핵심 trade-off:

- 탐색 범위가 넓으면 robust하지만 느리다.
- 해상도가 높으면 정밀하지만 후보 수가 증가한다.
- prior가 나쁘면 잘못된 local optimum을 선택할 수 있다.
- 대칭 복도에서는 여러 pose가 비슷한 점수를 얻는다.

## Key scan과 submap

모든 scan을 graph node로 만들지 않고 이동 거리, 회전량, 시간, matching 품질을 기준으로 key scan을 선택한다. 여러 key scan을 묶은 local submap은 matching의 안정성과 계산량을 조절한다.

## Loop closure

재방문 후보 생성과 최종 검증을 분리한다.

1. pose 또는 scan descriptor로 후보 생성
2. 넓은 범위 scan matching
3. 점수와 변환 크기 검사
4. 주변 제약과 일관성 검사
5. 통과한 경우 graph edge 추가

## Pose graph

- node: 각 key pose
- odometry/scan edge: 연속 pose 제약
- loop edge: 떨어진 시점 사이의 재방문 제약
- 정보행렬: 제약 신뢰도
- 첫 node 고정: gauge freedom 제거

목적함수는 각 edge의 상대 pose 예측과 측정 차이의 가중 제곱합이다. SE(2) residual과 Jacobian을 구하고 Gauss-Newton으로 반복 최적화한다.

## 공개 출처

- Edwin Olson, [Real-Time Correlative Scan Matching](https://april.eecs.umich.edu/papers/details.php?name=olson2009icra)
- Grisetti 외, [A Tutorial on Graph-Based SLAM](https://doi.org/10.1109/MITS.2010.939925)
- [SLAM Toolbox Architecture](https://docs.ros.org/en/humble/p/slam_toolbox/)
