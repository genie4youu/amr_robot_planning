# Costmap, A*, Path Smoothing 이론

## Occupancy map과 costmap 차이

occupancy map은 환경 관측 확률을 표현하고 costmap은 주행 비용을 표현한다.

초기 global costmap 계층:

- static obstacle
- inflation cost
- unknown-space policy
- keepout region
- 선택적 speed zone

## Inflation

로봇을 점으로 계획하려면 장애물을 로봇 반경과 안전 여유만큼 팽창한다. 단순 binary 팽창 이후, 장애물 거리 증가에 따라 비용이 감소하는 cost를 추가한다.

## A*

\[
f(n) = g(n) + h(n)
\]

- `g`: 시작점부터 누적 비용
- `h`: goal까지 heuristic
- open set와 closed set
- parent pointer로 path 복원

주의 항목:

- Manhattan, Euclidean, octile heuristic 선택
- 대각 이동 비용
- 동일 비용 tie breaking
- unknown cell 허용 여부
- occupied start/goal 처리
- 대각선 사이 corner cutting

## Path 후처리

격자 A* 경로는 불필요하게 꺾일 수 있다.

1. collinear point 제거
2. line-of-sight shortcut
3. resampling
4. curvature와 clearance 검사

최적화 Toolbox가 없으므로 첫 버전은 충돌 검사가 명확한 shortcut을 사용한다.

## 공개 출처

- [Nav2 Costmap 2D](https://docs.nav2.org/configuration/packages/configuring-costmaps.html)
- [Nav2 Inflation Layer](https://docs.nav2.org/configuration/packages/costmap-plugins/inflation.html)
