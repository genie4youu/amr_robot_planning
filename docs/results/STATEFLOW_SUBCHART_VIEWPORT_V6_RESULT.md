# Stateflow Subchart 중앙 정렬 및 가독성 V6 결과

## 바로 열 파일

- 현재 정식 모델: `models/mission_supervisor/amr_mission_supervisor.slx`
- 비교 A: `models/mission_supervisor/versions/amr_mission_supervisor_v06a_centered_readable_curved_2026_07_29.slx`
- 비교 B·현재 정식본: `models/mission_supervisor/versions/amr_mission_supervisor_v06b_centered_readable_minimum_curvature_2026_07_29.slx`

```matlab
compare_mission_supervisor_layouts("NavigationRegion")
```

## 원인과 재발 방지

기존 정식 모델은 다섯 Subchart의 graphical bounding box가 저장된 독립 편집 화면 중심에서
35.9%~43.2% 벗어나 있었다. 부모 Chart에 보이는 Subchart State의 `Position`과 내부
Subviewer 좌표를 분리하지 못한 것이 아니라, 정식 모델에는 개선 후보가 승격되지 않았고
그래픽 단위검사가 `layout_v`가 포함된 일부 후보 파일명에만 엄격하게 적용된 것이 직접
원인이었다.

R2025b의 `subviewS.pos`, pan과 내부 zoom metadata는 읽기 전용이다. 따라서 V6는 부모 State의
Position을 사용하지 않고 각 Subchart의 저장된 독립 Subviewer 범위를 읽어 child graphics를
그 중심에 배치한 뒤, 공개 `Stateflow.Editor.ZoomFactor`로 읽기 좋은 저장 화면을 만든다.

재발 방지는 다음 세 단계로 고정했다.

1. 현재 정식 모델과 모든 후보에 동일한 중심·크기 검사를 적용한다.
2. 저장·닫기·재열기 후 저장 확대율이 유지되는지 검사한다.
3. `max(graphicWidth, graphicHeight) × ZoomFactor`가 400 px 미만이면 생성과 테스트를 실패시킨다.

## Subchart 수정 전후

| Subchart | State bbox 전 | State bbox 후 | 중심 오차 전→후 | 표시 span 전→후 |
| --- | --- | --- | ---: | ---: |
| MissionRegion | `[147 226 3170 560]` | `[1071 1495.5 2785 370]` | 0.423 → 0.017 | 739 → 682 px |
| NavigationRegion | `[80 165 1340 520]` | `[1471 1516 1340 520]` | 0.432 → 0.015 | 411 → 571 px |
| SafetyRegion | `[80 100 740 450]` | `[1187 508.5 740 450]` | 0.383 → 0.039 | 1000 → 420 px |
| HealthRegion | `[80 100 760 450]` | `[901 515 760 450]` | 0.359 → 0.039 | 350 → 542 px |
| EnergyRegion | `[80 100 1140 440]` | `[843.5 799 1140 440]` | 0.382 → 0.011 | 428 → 646 px |

중심 오차는 graphical bbox 중심과 저장된 Subviewer 중심의 x/y 차이 중 큰 값을 해당
Subviewer 폭/높이로 정규화한 값이다. SafetyRegion은 기존 과대 확대를 줄였지만 400 px
가독성 하한은 유지한다. 전체 State별 좌표는
`models/mission_supervisor/comparison/v06_before_after_state_positions.csv`, 전체 수치는
`models/mission_supervisor/comparison/v06_subviewer_metrics.csv`에 있다.

MissionRegion의 Aborting은 `[537 646 2780 140]`에서 `[2263.5 1765.5 400 140]`으로 바뀌어
너비가 2380 px 감소했다. T80, T83, T86, T90~T94의 Aborting 진입선은 모두 endpoint 평균과
midpoint 차이가 0 px인 직접 대각선 또는 직선이다. MissionRegion의 최대 route deviation은
271.4 px에서 60 px로 감소했다.

## 두 Transition 비교안

- V06A는 기존 완만한 곡선 표현을 유지한다.
- V06B는 같은 State 배치에서 midpoint 이탈과 외곽 곡률을 최소화한 안이며 현재 정식본이다.
- 두 안의 State 위치 차이는 0 px이며 67개 Transition 중 T138 `after(2,sec)`와 T146
  `[batteryCritical]` 두 개만 geometry가 다르다. V06B에서는 둘 다 source, midpoint,
  destination의 y가 같은 수평 직선이다.
- Stateflow의 기존 Transition 객체만 보존하는 조건에서는 렌더러가 spline을 사용하므로,
  Junction을 새로 만들지 않고 완전한 직각 다중 선분으로 바꾸는 것은 불가능하다. V06B는
  논리 객체를 추가하지 않는 범위의 최소 곡률안이다.
- 보수적 두 선분 근사 검사에는 루트의 T60/T54 교차 후보 1건만 남았고, hard violation과
  exact routing violation은 0건이다.

## 검증 결과

| 검사 | 결과 |
| --- | --- |
| Stateflow 구조 | State 37, Transition 67 보존 |
| 논리 서명 | Label, Source/Destination, ExecutionOrder, 계층, Data/Event 보존 |
| 저장·재열기 | geometry와 저장 확대율 유지 |
| 2회 연속 실행 | State 0 px, Transition 0 px, ZoomFactor 0 차이 |
| Model check | healthy |
| Update Diagram | PASS |
| 인터페이스 테스트 | 16/16 PASS |
| 그래픽 테스트 | 19/19 PASS |
| Supervisor 시나리오 | 9/9 PASS |

현재 정식 모델과 V06B의 SHA-256은
`53E69AC54F951E8C4220B776C5902F14D64D5273C3626F682BEF0A4E4D54EA22`로 동일하다. 교체 전
정식 모델은 `work/backups/amr_mission_supervisor_current_before_v06_2026_07_29.slx`에
보존했다.

저장·재열기 직후의 다섯 Subchart 화면은
`models/mission_supervisor/comparison/screenshots/v06a_centered_curved`와
`models/mission_supervisor/comparison/screenshots/v06b_centered_minimum_curvature`에 있다.
