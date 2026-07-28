# Simulink 및 Stateflow 모델

```text
prototypes/  단계별 작은 실험 모델
system/      최종 통합 모델
libraries/   실제 재사용 필요가 확인된 라이브러리
history/     이전 버전 비교용, 일반 실행에서는 열지 않음
```

현재는 모델을 생성하지 않는다. 각 단계에서 MATLAB 함수가 먼저 검증된 뒤 작은 prototype 모델을 만든다.

현재 최상위 통합 모델은 `models/system/amr_integrated_delivery_system.slx`다. 단계별 prototype과 검증된 system 모델을 분리해 관리한다.

## 지금 열 파일

| 목적 | 정식 파일 |
| --- | --- |
| 최신 Mission Supervisor와 Stateflow 그래픽 확인 | `prototypes/amr_mission_supervisor.slx` |
| 전체 AMR 시스템 실행 | `system/amr_integrated_delivery_system.slx` |
| Scenario Lab 학습 | `prototypes/amr_scenario_supervisor.slx` |

활성 모델 파일명에는 `v1`, `v2`, `final`, `latest`를 붙이지 않는다. 최신본은 버전 없는
정식 이름을 사용하고, 교체된 모델만 `history/`에서 날짜와 용도를 파일명에 기록한다.
