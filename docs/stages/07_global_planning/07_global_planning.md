# 07. Global Costmap and Path Planning

## 목적

정적 지도와 로봇 크기를 반영한 global costmap을 만들고 A*로 충돌 없는 전역 경로를 생성·후처리한다.

## 진입 조건

- [01_math_frames_timing](../01_math_frames_timing/01_math_frames_timing.md) 완료
- [04_mapping](../04_mapping/04_mapping.md) 완료 또는 검증된 고정 지도 준비

## 학습 및 작업 순서

1. [01_Costmap_AStar_PathSmoothing_이론](01_Costmap_AStar_PathSmoothing_이론.md)
2. [02_전역계획_구현_및_검증](02_전역계획_구현_및_검증.md)
3. [07_global_planning_진행결과](07_global_planning_진행결과.md)

## 결과물

- static global costmap
- robot footprint 기반 inflation
- A* path planner
- path shortcut/smoothing
- path validity와 goal tolerance 검사

## 완료 조건

- [ ] 로봇 중심 경로가 장애물에 닿지 않는다.
- [ ] 대각선 corner cutting을 방지한다.
- [ ] 경로 없음과 잘못된 goal을 명확히 반환한다.
- [ ] 후처리한 경로도 collision-free다.

## 다음 단계

[08_local_planning_control](../08_local_planning_control/08_local_planning_control.md)
