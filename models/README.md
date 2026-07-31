# Simulink 및 Stateflow 모델

모델의 상태가 아니라 **모델 종류를 먼저** 기준으로 나눈다. 한 모델의 정식본, 버전 이력,
비교 자료는 같은 폴더 안에 둔다.

```text
models/
├─ mission_supervisor/  Mission Supervisor 정식본·버전·비교 자료
├─ integrated_system/   전체 AMR 통합 실행 모델
└─ examples/            단계별 학습·실험 모델
```

## 지금 열 파일

| 목적 | 파일 |
| --- | --- |
| Mission Supervisor 정식 기준 모델 | `mission_supervisor/amr_mission_supervisor.slx` |
| 전체 AMR 통합 시스템 | `integrated_system/amr_integrated_delivery_system.slx` |
| 두 Stateflow 레이아웃 비교 | `mission_supervisor/comparison/README.md` |
| Mission Supervisor 변경 순서 | `mission_supervisor/versions/README.md` |
| Scenario Supervisor 학습 | `examples/amr_scenario_supervisor.slx` |

일반 사용에서는 프로젝트 루트의 `work/`를 열지 않는다. Mission Supervisor 관련 파일은
모두 `mission_supervisor/`에서 찾는다.

## 앞으로의 업데이트 규칙

1. 모든 의미 있는 수정안은 `mission_supervisor/versions`에 다음 `vNN` 번호로 영구 보존한다.
2. 같은 단계의 비교안은 같은 `vNN` 번호에 `a`, `b` 분기 문자를 붙인다.
3. 비교 함수와 화면만 `mission_supervisor/comparison`에 두고 모델 복사본은 만들지 않는다.
4. 선택한 버전의 복사본만 `mission_supervisor/amr_mission_supervisor.slx`로 승격한다.
5. 결과 보고에서는 사용자가 실제로 열 모델과 버전 번호를 가장 먼저 제시한다.
