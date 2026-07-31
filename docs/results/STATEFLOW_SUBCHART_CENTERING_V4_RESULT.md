# Stateflow Subchart Centering V4 결과

> 후속 V5는 중앙 정렬을 유지하면서 저장 화면의 콘텐츠 점유율을 개선했다.
> `STATEFLOW_SUBCHART_READABILITY_V5_RESULT.md`를 최신 결과로 사용한다.

## 결론

`MissionRegion`, `NavigationRegion`, `SafetyRegion`, `HealthRegion`,
`EnergyRegion`의 직접 자식 객체를 부모 Chart의 Subchart State `Position`이 아니라 각
Subchart에 저장된 독립 편집 캔버스(`subviewS.pos`) 중심에 배치했다. 모델을 저장하고 닫은
뒤 다시 열어 각 Subchart에 `view(subchart)`와 `fitToView(subchart)`를 적용하고
`sfprint(..., false)`로 캡처했으며, 다섯 Subchart 모두 중앙 배치를 확인했다. 수동
`ZoomFactor` 덮어쓰기는 사용하지 않았다.

비교 후보는 다음 두 개다.

- `work/layout_candidates/amr_mission_supervisor_layout_v4_centered_curves.slx`
- `work/layout_candidates/amr_mission_supervisor_layout_v4_centered_minimum_curvature.slx`

두 모델 모두 원본 Stateflow 객체를 삭제하거나 다시 만들지 않았고, State 37개,
Transition 67개, Junction 0개, Data 42개와 SSID·LabelString·Source·Destination·
ExecutionOrder·계층·동작 논리를 보존했다.

## 기존 검사가 놓친 원인

V3 검사는 Subchart State bounding box의 `minX/minY <= 200`과 State/Transition bounding
box 상호 중심만 검사했다. 따라서 State와 Transition이 함께 편집 캔버스 좌측 상단에 있으면
검사를 통과했다.

재현 시 `MissionRegion`은 다음과 같았다.

| 항목 | V3 값 |
| --- | --- |
| State bbox | `[197 199 2982 569]` |
| 저장된 Subchart canvas | `[191 193 4545 2975]` |
| State 중심 | `[1589.5 384]` |
| Canvas 중심 | `[2463.5 1680.5]` |
| 중심 오차 | `[-874 -1296.5]` px |

이 때문에 `fitToView` 상태에서는 잠시 중앙처럼 보여도 새 탭 또는 재개방 기본 화면에서는
객체가 좌측 상단에 나타났다.

## 레이아웃·검사기 수정

- 모든 Subchart를 이름과 무관하게 재귀 수집한다.
- 로컬 State 레이아웃을 계산한 후 State bbox 중심을 `subviewS.pos` 중심으로 평행 이동한다.
- 부모 Chart에서 보이는 Subchart State `Position`은 내부 정렬에 사용하지 않는다.
- 이동 직후 같은 Subviewer의 Transition geometry와 LabelPosition을 다시 확정한다.
- 저장·재열기 후 graphical bbox와 저장된 canvas 중심 오차를 다시 계산한다.
- 중심 오차가 canvas 너비 또는 높이의 10%를 넘거나 graphical bbox가 canvas 밖으로
  나가면 layout-quality 위반으로 처리한다.
- 라벨 후보의 동률 처리 순서를 SSID로 고정해 두 번째 실행의 LabelPosition drift를 막았다.

## State 위치 변경

두 V4 후보의 State 위치는 동일하다.

### MissionRegion

| State | V3 Position | V4 Position |
| --- | --- | --- |
| Idle | `[197 199 300 120]` | `[1071 1495.5 300 120]` |
| ValidateJob | `[532 199 320 120]` | `[1406 1495.5 320 120]` |
| NavigatePickup | `[887 199 340 120]` | `[1761 1495.5 340 120]` |
| Loading | `[1262 199 300 120]` | `[2136 1495.5 300 120]` |
| NavigateDropoff | `[1597 199 340 120]` | `[2471 1495.5 340 120]` |
| Unloading | `[1972 199 320 120]` | `[2846 1495.5 320 120]` |
| ReturnHome | `[2327 199 320 120]` | `[3201 1495.5 320 120]` |
| Completed | `[2682 199 300 120]` | `[3556 1495.5 300 120]` |
| Aborting | `[1389.5 469 400 100]` | `[2263.5 1765.5 400 100]` |

### NavigationRegion

| State | V3 Position | V4 Position |
| --- | --- | --- |
| NavIdle | `[80 165 300 130]` | `[1471 1516 300 130]` |
| Planning | `[530 165 330 150]` | `[1921 1516 330 150]` |
| Tracking | `[1040 165 380 160]` | `[2431 1516 380 160]` |
| Recovery | `[540 435 400 250]` | `[1931 1786 400 250]` |
| NavFailed | `[80 515 360 170]` | `[1471 1866 360 170]` |
| Replanning | `[1040 515 330 150]` | `[2431 1866 330 150]` |

### SafetyRegion, HealthRegion, EnergyRegion

| State | V3 Position | V4 Position |
| --- | --- | --- |
| SafetyClear | `[80 100 320 120]` | `[1187 508.5 320 120]` |
| Slowdown | `[500 100 320 120]` | `[1607 508.5 320 120]` |
| ProtectiveStop | `[290 400 400 150]` | `[1397 808.5 400 150]` |
| Healthy | `[80 100 320 120]` | `[901 515 320 120]` |
| Degraded | `[500 100 340 120]` | `[1321 515 340 120]` |
| FaultRequest | `[290 400 420 150]` | `[1111 815 420 150]` |
| EnergyNormal | `[80 100 300 120]` | `[843.5 799 300 120]` |
| EnergyLow | `[480 100 300 120]` | `[1243.5 799 300 120]` |
| EnergyCritical | `[880 100 340 130]` | `[1643.5 799 340 130]` |
| GoToCharger | `[280 400 360 140]` | `[1043.5 1099 360 140]` |
| Charging | `[860 400 340 140]` | `[1623.5 1099 340 140]` |

전체 원시 비교는 `work/layout_review/v4_state_position_comparison.csv`에 있다.

## 최종 Subchart geometry

| Subchart | State bbox | Graphics bbox | Canvas 중심 오차 px | 평균 route ratio | 최대 midpoint deviation px |
| --- | --- | --- | ---: | ---: | ---: |
| MissionRegion | `[1071 1495.5 3856 1865.5]` | `[981 1395.5 3856 1865.5]` | `[-45 -50]` | 1.0001 | 60.0 |
| NavigationRegion | `[1471 1516 2811 2036]` | `[1381 1416 2811 2036]` | `[-45.039 -50]` | 1.0992 | 95.0 |
| SafetyRegion | `[1187 508.5 1927 958.5]` | `[1127 408.5 1939 958.5]` | `[-24 -50.2]` | 1.0416 | 122.0 |
| HealthRegion | `[901 515 1661 965]` | `[901 415 1751 965]` | `[45.24 -50.2]` | 1.0061 | 60.0 |
| EnergyRegion | `[843.5 799 1983.5 1239]` | `[783.5 702.2 1983.5 1329.5]` | `[-30 -3.35]` | 1.0601 | 402.7 |

EnergyRegion의 큰 midpoint deviation은 `Charging -> EnergyNormal` 복귀 lane이며, 기존
검사 기준 내에 있고 State를 관통하지 않는다. 두 후보 모두 동일한 보존 경로를 사용한다.

## Transition 비교본의 한계

Stateflow 일반 Transition은 공개 API에서 endpoint, O'Clock, 단일 `MidPoint`만 제공하고
화면에는 spline으로 렌더링된다. 실제 다중 구간 polyline은 connective Junction과 추가
Transition이 필요하므로 State/Transition/Junction 수, SSID, Source/Destination 보존 조건과
양립하지 않는다.

따라서 두 번째 모델은 Junction을 추가하지 않은 안전한 `MinimumCurvature` 비교본이다.
직선화해도 상태 관통이 없고 포트 간격을 유지하는 전이만 조정했으며, 최종적으로 V4 곡선형과
geometry가 달라진 전이는 다음 두 개다.

| Transition | 변경 |
| --- | --- |
| T138 `Recovery -> NavFailed` | Source/Destination O'Clock과 MidPoint를 최소 곡률 방향으로 조정 |
| T146 `EnergyLow -> EnergyCritical` | Source/Destination O'Clock과 MidPoint를 최소 곡률 방향으로 조정 |

상단 복귀나 외곽 lane을 진짜 꺾인 polyline으로 바꾸려면 Junction 추가를 허용하는 별도의
논리 변경 승인이 필요하다. 이 작업에서는 실행 의미 보존을 우선해 적용하지 않았다.

## 검증

| 검사 | Curved | MinimumCurvature |
| --- | ---: | ---: |
| hard graphical violations | 0 | 0 |
| exact routing violations | 0 | 0 |
| layout-quality violations | 0 | 0 |
| 보수적 spline 근사 경고 | 1 | 1 |
| 두 번째 실행 State geometry 변화 | 0 | 0 |
| 두 번째 실행 Transition geometry 변화 | 0 | 0 |
| Stateflow lint | healthy | healthy |
| Update Diagram | PASS | PASS |
| 인터페이스 테스트 | 16/16 | 16/16 |
| 그래픽 테스트 | 18/18 | 18/18 |
| Supervisor 시나리오 | 9/9 | 9/9 |
| 공통 알고리즘 회귀 | 8/8 | 8/8 |

보수적 경고 1건은 기존에 검토된 루트 Chart의 T54/T60 두 선분 근사 교차 후보다. State
관통, 라벨 겹침 또는 exact routing 위반은 아니다.

저장·재열기 후 `fitToView`가 계산한 확대율은 두 후보에서 동일했다.

| Subchart | 최종 ZoomFactor |
| --- | ---: |
| MissionRegion | 0.166723 |
| NavigationRegion | 0.153370 |
| SafetyRegion | 0.292650 |
| HealthRegion | 0.356837 |
| EnergyRegion | 0.268050 |

## 최종 fitToView 화면 캡처

`work/layout_review/`에 두 후보 각각 다섯 Subchart의 저장·재열기·`fitToView` 화면을
저장했다.

- `v4_curves_default_MissionRegion.png`
- `v4_curves_default_NavigationRegion.png`
- `v4_curves_default_SafetyRegion.png`
- `v4_curves_default_HealthRegion.png`
- `v4_curves_default_EnergyRegion.png`
- `v4_minimum_curvature_default_MissionRegion.png`
- `v4_minimum_curvature_default_NavigationRegion.png`
- `v4_minimum_curvature_default_SafetyRegion.png`
- `v4_minimum_curvature_default_HealthRegion.png`
- `v4_minimum_curvature_default_EnergyRegion.png`
