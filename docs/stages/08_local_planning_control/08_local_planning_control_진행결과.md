# 08 단계 진행 및 결과

- 상태: 진행 중
- 시작일: 2026-07-22
- 완료일:

## Local costmap 설정

- window: robot-centred `6 m × 6 m`
- static safety grid inflation: `0.30 m`
- raw static map에 없는 LiDAR hit만 novel obstacle로 marking
- hit point inflation: `0.30 m`

## Pure Pursuit baseline

- 일반 배송/충전/경로복귀는 기존 pose-feedback waypoint follower를 기준 제어기로 유지

## DWA sampling과 cost weight

- prediction horizon `1.20 s`, rollout step `0.10 s`
- linear samples 5, angular samples 11
- path 3.0, goal 0.35, heading 0.85, speed reward 0.55, smoothness 0.20
- rollout collision과 braking trajectory collision을 hard rejection

## Robot limits

- `0 <= v <= 0.65 m/s`, `|omega| <= 1.20 rad/s`
- linear acceleration `1.20 m/s^2`
- angular acceleration `4.00 rad/s^2`

## 시나리오 결과와 지표

- standalone DWA: 80 step 진행, 4400 valid candidate evaluations, collision-free
- integrated obstacle: DWA mode 227 samples
- maximum linear step `0.060 m/s`, maximum angular step `0.200 rad/s`
- 사무실 장애물 배송 완료 `34.40 s`
- 병원 장애물 `40.00 s`, 창고 장애물 `56.50 s`
- 3개 환경 × 4개 상황 모두 최종 오차 약 `0.080 m` 이하와 비충돌 PASS
- delayed/held LiDAR scan에서도 DWA와 독립 safety gate 검증 PASS

## 실패 패턴과 튜닝 기록

- 초기 구현은 truth dynamic grid 전체를 DWA에 제공했으나 센서 한계를 숨기므로 폐기
- 현재는 local static window와 novel LiDAR hit만 DWA에 전달
- global A* replan은 아직 known dynamic rectangle을 사용하므로 다음 mapping 단계에서 scan-derived global marking으로 교체 예정

## 다음 작업 한 가지

no-valid-candidate와 oscillation 상황의 recovery 및 retry limit을 추가한다.
