# Mission Supervisor 버전 이력

이 폴더는 실제로 생성·검증한 Mission Supervisor 모델을 변경 순서대로 영구 보존한다.
버전 파일은 덮어쓰지 않는다.

| 버전 | 버전 파일 | 날짜 | 핵심 변경 | 상태 |
| ---: | --- | --- | --- | --- |
| `v01` | `amr_mission_supervisor_v01_logic_baseline_2026_07_24.slx` | 2026-07-24 | State 37, Transition 67, Data 42의 그래픽 작업 전 논리 기준선 | 기준선 |
| `v02a` | `amr_mission_supervisor_v02a_curved_attempt_2026_07_27.slx` | 2026-07-27 | 첫 전체 그래픽 재배치. 큰 곡선과 child 쏠림이 남음 | 실패 시도 보존 |
| `v02b` | `amr_mission_supervisor_v02b_graphical_redesign_2026_07_27.slx` | 2026-07-27 | 직선 우선 라우팅, Mission/Navigation 재배치, 그래픽 검사기 적용 | 이전 정식 기준 |
| `v03` | `amr_mission_supervisor_v03_recursive_layout_2026_07_28.slx` | 2026-07-28 | 모든 Subviewer를 재귀 탐색하고 깊은 계층부터 배치 | 검증 후보 |
| `v04a` | `amr_mission_supervisor_v04a_centered_curved_2026_07_28.slx` | 2026-07-28 | Subchart 로컬 캔버스 중앙 정렬, 곡선 스타일 | 중간 후보 |
| `v04b` | `amr_mission_supervisor_v04b_centered_low_curve_2026_07_28.slx` | 2026-07-28 | V04A와 같은 State 배치, 곡률 최소화 스타일 | 중간 후보 |
| `v05a` | `amr_mission_supervisor_v05a_readable_curved_2026_07_28.slx` | 2026-07-28 | V04A 중앙 정렬 유지, 저장 화면 확대율과 가독성 개선 | 이전 비교 A |
| `v05b` | `amr_mission_supervisor_v05b_readable_low_curve_2026_07_28.slx` | 2026-07-28 | V04B 중앙 정렬 유지, 저장 화면 확대율과 가독성 개선 | 이전 비교 B |
| `v06a` | `amr_mission_supervisor_v06a_centered_readable_curved_2026_07_29.slx` | 2026-07-29 | 편집 카메라 중심 정렬, 곡선 유지. Space/Fit에서 작아지는 문제 확인 | 이전 비교 A |
| `v06b` | `amr_mission_supervisor_v06b_centered_readable_minimum_curvature_2026_07_29.slx` | 2026-07-29 | 같은 State 배치, 최소 곡률 Transition. Space/Fit 페이지가 과대함 | 이전 정식본·비교 B |
| `v07a` | `amr_mission_supervisor_v07a_curved_readable_fit_2026_07_29.slx` | 2026-07-29 | 로컬 좌표와 Subchart 페이지 정상화, 실제 Space/Fit 가독성 확보, 곡선 유지 | 이전 비교 A |
| `v07b` | `amr_mission_supervisor_v07b_minimum_curvature_readable_fit_2026_07_29.slx` | 2026-07-29 | 같은 State·페이지, 최소 곡률 Transition, Space/Fit 회귀 gate | 현재 정식본 |
| `v08a` | `amr_mission_supervisor_v08a_current_layout_snapshot_2026_07_29.slx` | 2026-07-29 | 최종 선택 직전의 원래 레이아웃 고정 스냅샷 | 선택된 원본 기록·`v07b`와 동일 |
| `v08b` | `— (모델 파일 폐기)` | 2026-07-29 | 직선·직각 우선 비교 시도 | 비교 후 폐기 |

`v02a`와 `v02b`, `v04a`와 `v04b`, `v05a`와 `v05b`처럼 같은 번호에 문자가 붙으면
같은 작업 단계의 시도 또는 스타일 분기라는 뜻이다.

## 현재 파일과의 관계

- `../amr_mission_supervisor.slx`는 현재 `v07b`와 바이트 단위로 동일하다.
- `v08a`도 현재 정식 모델과 바이트 단위로 동일한 선택 시점 스냅샷이다.
- 최종본은 `v07b`이고 진행 중인 비교 후보는 없다.
- 비교 함수는 필요할 때 과거 `v07a`와 `v07b`를 연다.

## 앞으로의 버전 규칙

1. 의미 있는 새 설계 단계마다 `v07`, `v08`처럼 번호를 증가시킨다.
2. 동일 단계의 비교안은 같은 `vNN` 번호에 `a`, `b` 문자를 붙인다.
3. 파일명은 `amr_mission_supervisor_vNN<분기>_<핵심변경>_YYYY_MM_DD.slx` 형식을 쓴다.
4. `versions` 파일은 영구 기록이므로 수정하거나 덮어쓰지 않는다.
5. 비교용 별칭 복사본을 만들지 않고 `../comparison`에서 실제 버전 파일을 직접 참조한다.
6. 사용자가 선택하면 선택된 버전의 복사본을 `../amr_mission_supervisor.slx`로 승격한다.
