# Stateflow Subchart 가독성 V5 결과

## 결론

V4에서 `MissionRegion`, `NavigationRegion`, `SafetyRegion`, `HealthRegion`,
`EnergyRegion`의 콘텐츠 중심은 바로잡았지만, 저장된 독립 Subchart 캔버스가 콘텐츠보다
커서 `fitToView` 화면의 객체가 작았다. V5는 각 Subchart의 graphical bounding box와 저장된
캔버스 비율로 추가 확대율을 계산하고, 그 화면 상태를 저장·재열기 검증한다.

- `models/mission_supervisor/versions/amr_mission_supervisor_v05a_readable_curved_2026_07_28.slx`
- `models/mission_supervisor/versions/amr_mission_supervisor_v05b_readable_low_curve_2026_07_28.slx`

State와 Transition의 좌표·크기·논리에는 V4 대비 변화가 없다. State 37개, Transition 67개,
Junction 0개, Data 42개와 SSID, LabelString, Source/Destination, ExecutionOrder, 계층 및 실행
의미를 보존했다.

## 원인과 적용 기준

`fitToView(subchart)`는 저장된 Subchart 작업면 전체를 기준으로 화면을 맞춘다. V4
`MissionRegion`의 graphical 높이는 캔버스 높이의 약 16%, `NavigationRegion`의 graphical
너비는 캔버스 너비의 약 35%뿐이었다. 따라서 객체 묶음의 중심이 맞더라도 화면에서는 작은
차트로 보였다.

`subviewS.pos`는 R2025b의 내부 읽기 전용 속성이다. 이를 직접 수정하거나 SLX 내부 XML을
편집하지 않았다. Subchart를 일반 Composite State로 전환하여 캔버스를 초기화하는 방법도
자식 Subviewer 계층이 바뀔 수 있어 후보 적용에서 제외했다.

V5는 다음과 같이 공개 `Stateflow.Editor.ZoomFactor`를 계산한다.

1. `view(subchart)`와 `fitToView(subchart)`로 편집기 기준 확대율을 얻는다.
2. graphical/canvas 가로·세로 점유율을 계산한다.
3. 가로 0.88 또는 세로 0.72를 넘지 않는 최소 배율을 선택한다.
4. 추가 배율은 최대 3배로 제한한다.
5. 모델을 저장·닫기·재열기하고 각 Subchart의 확대율이 유지되는지 확인한다.

단위검사는 최종 화면이 한 축의 0.70 이상을 사용하고, 가로 0.93 또는 세로 0.78을 넘어
잘리지 않는지 확인한다. 이 검사는 중앙 정렬 좌표 검사와 별도로 수행한다.

## 확대율 전후

두 Transition 스타일의 값은 동일하다.

| Subchart | V4 fit 확대율 | 추가 배율 | V5 저장 확대율 | 최종 가로 점유율 | 최종 세로 점유율 |
| --- | ---: | ---: | ---: | ---: | ---: |
| MissionRegion | 0.166723 | 1.3912 | 0.231939 | 0.880 | 0.220 |
| NavigationRegion | 0.153370 | 2.5440 | 0.390182 | 0.880 | 0.488 |
| SafetyRegion | 0.292650 | 1.6749 | 0.490145 | 0.459 | 0.720 |
| HealthRegion | 0.356837 | 1.6919 | 0.603722 | 0.591 | 0.720 |
| EnergyRegion | 0.268050 | 1.9646 | 0.526611 | 0.880 | 0.666 |

`MissionRegion`은 정상 흐름이 긴 단일 행이므로 세로 여백은 남지만 가로 화면을 88% 사용한다.
다른 Region은 한 축을 72~88% 사용해 State action과 Transition label을 읽을 수 있는 크기가
됐다.

## 멱등성과 검증

| 검사 | Curved | MinimumCurvature |
| --- | ---: | ---: |
| 두 번째 실행 State 최대 변화 | 0 px | 0 px |
| 두 번째 실행 Transition 최대 변화 | 0 px | 0 px |
| 저장 확대율 재열기 일치 | 5/5 | 5/5 |
| Stateflow lint | healthy | healthy |
| Update Diagram | PASS | PASS |
| 인터페이스 테스트 | 16/16 | 16/16 |
| 그래픽 테스트 | 19/19 | 19/19 |
| Supervisor 시나리오 | 9/9 | 9/9 |
| 공통 알고리즘 회귀 | 8/8 | 8/8 |

## 최종 화면 캡처

`models/mission_supervisor/comparison/screenshots/`에 저장·재열기 직후 화면을 저장했다.

- `v5_readable_curves_MissionRegion.png`
- `v5_readable_curves_NavigationRegion.png`
- `v5_readable_curves_SafetyRegion.png`
- `v5_readable_curves_HealthRegion.png`
- `v5_readable_curves_EnergyRegion.png`
- `v5_readable_minimum_curvature_MissionRegion.png`
- `v5_readable_minimum_curvature_NavigationRegion.png`
- `v5_readable_minimum_curvature_SafetyRegion.png`
- `v5_readable_minimum_curvature_HealthRegion.png`
- `v5_readable_minimum_curvature_EnergyRegion.png`
