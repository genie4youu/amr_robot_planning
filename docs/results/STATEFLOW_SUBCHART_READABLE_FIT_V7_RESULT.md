# Stateflow Subchart Space/Fit 가독성 수정 결과 — v07

## 사용자가 열 파일

- 현재 정식본·비교 B: `models/mission_supervisor/amr_mission_supervisor.slx`
- 비교 A: `models/mission_supervisor/versions/amr_mission_supervisor_v07a_curved_readable_fit_2026_07_29.slx`
- 비교 B: `models/mission_supervisor/versions/amr_mission_supervisor_v07b_minimum_curvature_readable_fit_2026_07_29.slx`
- 비교 명령: `compare_mission_supervisor_layouts("NavigationRegion")`

## 원인과 수정

v06은 직접 자식 State를 저장된 `subviewS.pos` 중심으로 옮겼다. 이 rectangle은 로컬 배치
영역이 아니라 Space/Fit이 맞추는 페이지이므로, NavigationRegion의 1420×620 그래픽이
4134×3279 페이지 안의 작은 묶음으로 남았다. 저장 ZoomFactor로는 커 보일 수 있지만
Space/Fit을 실행하면 표시 폭이 약 209 px로 줄었다.

v07은 모든 Subchart State를 로컬 `x=100`, `y=120`에서 시작하도록 정규화한다. 위쪽 복귀
lane이 저장 시 spline 보정을 일으키는 MissionRegion과 EnergyRegion은 안정적인 `y=200`을
사용한다. State/Transition 배치가 끝난 뒤 `subviewS.pos` 페이지를 전체 그래픽 bounding box,
가로 활용률 0.90, 세로 활용률 0.82, 최소 여백 60 px 기준으로 다시 계산한다.

## Subchart별 수치

| Subchart | State min | 이전 페이지 (w×h) | v07 페이지 (w×h) | 이전 Fit 표시 폭 | v07 Fit 표시 폭 |
| --- | ---: | ---: | ---: | ---: | ---: |
| MissionRegion | 100, 200 | 4642×2975 | 3184×590 | 452 | 781 |
| NavigationRegion | 100, 120 | 4134×3279 | 1578×757 | 209 | 781 |
| SafetyRegion | 100, 120 | 2966×1279 | 932×671 | 235 | 600 |
| HealthRegion | 100, 120 | 2432×1292 | 970×671 | 303 | 628 |
| EnergyRegion | 100, 200 | 2845×1850 | 1356×753 | 327 | 704 |

## 재발 방지

- 레이아웃 생성기가 모든 Subchart 페이지를 이름 하드코딩 없이 재계산한다.
- 검사기는 편집 카메라 중심 정렬을 합격 기준으로 사용하지 않는다.
- 단위검사는 실제 `fitToView(subchart)`를 실행하고, 창 크기와 무관하게 그래픽이 페이지의
  어느 한 축을 최소 70% 사용하며 가로 93%·세로 82%를 넘지 않는지 검사한다.
- 레이아웃 두 번째 실행 결과는 State Position, Transition Endpoint/MidPoint/LabelPosition,
  ZoomFactor, page rectangle 모두 변화 0이다.

## 검증

- State 37, Transition 67 및 전체 논리 서명 보존
- Model check: healthy
- Update Diagram: PASS
- 인터페이스: 16/16 PASS
- 그래픽 단위검사: 19/19 PASS
- Supervisor 시나리오: 9/9 PASS
- 공통 알고리즘 회귀: 8/8 PASS
