# Local Costmap, Pure Pursuit, DWA 이론

## Local costmap

로봇 주변 고정 크기 window에서 센서 관측을 누적한다.

- 최신 LiDAR 장애물 marking
- ray를 따라 free-space clearing
- 오래된 동적 장애물 decay
- robot footprint clearing
- obstacle inflation
- timestamp가 오래된 scan 거부

## Pure Pursuit

global path 위의 lookahead point를 선택하고 해당 점으로 향하는 곡률을 계산한다.

이 프로젝트에서는:

- 장애물 없는 기준 제어기
- lookahead에 따른 oscillation/corner cutting 비교
- DWA 결과 비교 기준

으로 사용한다.

## Dynamic Window Approach

1. 전체 속도 한계와 현재 속도에서 도달 가능한 dynamic window 계산
2. `v`, `omega` 후보 sampling
3. 각 후보 trajectory rollout
4. footprint collision 검사
5. braking distance 또는 time-to-collision 검사
6. path, goal, heading, clearance, speed 비용 계산
7. 최저 비용의 admissible command 선택

## Cost 설계 원칙

- 각 항목을 정규화한 뒤 weight를 적용한다.
- 한 번에 모든 cost를 튜닝하지 않는다.
- obstacle cost는 hard rejection과 soft cost를 구분한다.
- oscillation 방지를 위해 이전 명령과 진행 방향을 고려한다.

## 공개 출처

- Fox 외, [Dynamic Window Approach](https://publications.ri.cmu.edu/the-dynamic-window-approach-to-collision-avoidance)
- [Pure Pursuit Controller](https://www.mathworks.com/help/robotics/ug/pure-pursuit-controller.html)
- [Nav2 Obstacle Layer](https://docs.nav2.org/configuration/packages/costmap-plugins/obstacle.html)
