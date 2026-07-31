# Mission Supervisor 레이아웃 비교 이력

현재 진행 중인 비교 후보는 없다. 사용자는 원래 최소 곡률 레이아웃을 최종본으로 선택했고,
직선·직각 우선 `v08b` 모델은 폐기했다.

필요하면 선택 전의 v07 비교 이력을 다음 두 모델로 다시 확인할 수 있다.

| 구분 | 버전 | 차이 |
| --- | --- | --- |
| A | `v07a_curved_readable_fit` | 읽기 좋은 페이지에서 완만한 곡선을 유지한 이전 비교안 |
| B | `v07b_minimum_curvature_readable_fit` | 곡률과 외곽 우회를 줄인 현재 최종본 |

MATLAB Project를 연 뒤 다음 명령을 실행한다.

```matlab
compare_mission_supervisor_layouts("MissionRegion")
```

`MissionRegion` 대신 `NavigationRegion`, `SafetyRegion`, `HealthRegion`, `EnergyRegion`을
입력할 수 있다. 함수는 다음 실제 버전 파일을 함께 연다.

- `../versions/amr_mission_supervisor_v07a_curved_readable_fit_2026_07_29.slx`
- `../versions/amr_mission_supervisor_v07b_minimum_curvature_readable_fit_2026_07_29.slx`

`v08a`는 최종 선택 시점의 원본 스냅샷으로 버전 이력에 남아 있으며 `v07b` 및 현재 정식
모델과 바이트 단위로 동일하다. 폐기된 `v08b` 모델과 전용 검증 산출물은 남기지 않는다.
