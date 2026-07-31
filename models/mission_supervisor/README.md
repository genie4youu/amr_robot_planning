# Mission Supervisor

Mission Supervisor와 관련된 정식 모델, 변경 이력, 비교 자료를 한곳에 모은다.

## 무엇을 열면 되는가

| 목적 | 열 파일 |
| --- | --- |
| 현재 정식 모델 사용 | `amr_mission_supervisor.slx` |
| 지금 검토 중인 두 레이아웃 비교 | `comparison/README.md` |
| 과거 변경 순서 확인 | `versions/README.md` |

현재 정식 모델은 `versions`의 `v07b` 및 선택 시점 스냅샷 `v08a`와 바이트 단위로 동일하다.
직선·직각 우선 `v08b`는 비교 후 폐기했고, 진행 중인 비교 후보는 없다.

NavigationRegion을 바로 확인하려면 `amr_mission_supervisor.slx`를 열고
`MissionSupervisor > Operational > NavigationRegion` 순서로 들어간다. 두 안을 동시에
보려면 MATLAB Command Window에서 다음 명령만 실행한다.

```matlab
compare_mission_supervisor_layouts("NavigationRegion")
```

## 폴더 구조

```text
mission_supervisor/
├─ amr_mission_supervisor.slx   현재 정식 모델
├─ versions/                    v01부터 보존한 실제 변경본
└─ comparison/                  현재 비교 방법과 화면 캡처
```

새 작업은 다음 번호의 버전 파일로 `versions`에 먼저 저장한다. 같은 단계에서 두 안을 만들면
분기 문자를 붙이고, 검증한 선택본만 `amr_mission_supervisor.slx`로 승격한다.
