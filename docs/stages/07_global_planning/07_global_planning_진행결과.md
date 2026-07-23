# 07 단계 진행 및 결과

- 상태: 진행 중
- 시작일: 2026-07-21
- 완료일:

## Costmap 설정

- binary occupancy grid, `10 cells/m`
- planning inflation `0.40 m`
- safety validation inflation `0.30 m`

## A* 설정

- 8-connected neighbor
- Euclidean heuristic
- diagonal corner cutting 금지
- 경로가 없으면 빈 배열 반환

## Path 후처리 설정

- grid line-of-sight가 유지되는 가장 먼 점을 선택해 waypoint 축약
- 후처리된 모든 선분을 occupancy grid에서 다시 검증

## 생성한 함수와 모델

- `src/+amr/+planning/planAStarGrid.m`
- `src/+amr/+planning/smoothGridPath.m`
- Scenario Lab의 정상/장애물/충전/경로이탈 재계획에 통합

## 지도별 결과와 지표

- 정상, 동적 장애물, 충전소 복귀, 잘못된 길 복귀 경로 생성 성공
- 네 회귀 시나리오의 모든 pose 및 pose 사이 선분 비충돌 확인

## 경로 없음 처리

- 현재 planner는 빈 경로를 반환하고 scenario engine은 blocked 상태로 정지한다.
- Stateflow timeout/retry 및 사용자 실패 보고로의 연결은 다음 확장이다.

## 다음 작업 한 가지

거리 기반 cost와 local costmap을 추가하고 DWA 계열 지역 계획기를 연결한다.
