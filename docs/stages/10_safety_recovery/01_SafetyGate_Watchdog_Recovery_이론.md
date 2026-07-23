# Safety Gate, Watchdog, Recovery 이론

## 안전 계층의 위치

```text
Local Planner cmd
      ↓
Velocity shaping
      ↓
Safety gate
      ↓
Final wheel command
```

안전 gate는 planner가 안전하다고 가정하지 않는다.

## 감시 항목

- stop zone 안의 obstacle point
- slowdown zone
- 현재 속도 기준 time-to-collision
- LiDAR, pose, command의 data age
- localization valid와 covariance
- wheel command와 measured motion의 불일치
- emergency request

## Progress checker

정해진 시간 창에서 다음을 평가한다.

- 이동 거리
- goal distance 감소량
- heading만 반복 변화하는지
- 같은 recovery가 반복되는지
- controller가 계속 유효 후보를 찾지 못하는지

## Recovery ladder

상황에 따라 순서를 조정하지만 기본 후보는 다음과 같다.

```text
Replan
→ Wait
→ RotateInPlace
→ BackUp
→ ClearLocalCostmap
→ Relocalize
→ MissionAbort
```

각 recovery는 진입 조건, timeout, 성공 조건, 최대 retry를 가져야 한다.

## 한계

이 프로젝트의 safety logic은 교육용 시뮬레이션이다. 실제 안전 인증, 안전 PLC, 물리적 E-stop을 대체하지 않는다.

## 공개 출처

- [Nav2 Collision Monitor](https://docs.nav2.org/configuration/packages/collision_monitor/configuring-collision-monitor-node.html)
- [Nav2 Replanning and Recovery](https://docs.nav2.org/behavior_trees/overview/detailed_behavior_tree_walkthrough)
