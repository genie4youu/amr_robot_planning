# Getting Started

## 1. 요구 환경

검증 환경은 Windows 11, MATLAB/Simulink/Stateflow R2025b Update 5입니다.

ROS Toolbox, Robotics System Toolbox, Simulink Test, ROS 2와 Gazebo는 필요하지 않습니다. 자동검사는 기본 MATLAB `assert`를 사용합니다.

## 2. MATLAB Project 열기

MATLAB Current Folder를 저장소 루트로 설정하고 프로젝트를 엽니다.

```matlab
project = openProject("AMRRobotPlanning.prj");
```

프로젝트는 다음 폴더를 MATLAB path에 추가합니다.

- `scripts`
- `src`
- `tests/unit`
- `models/mission_supervisor`
- `models/mission_supervisor/versions`
- `models/mission_supervisor/comparison`
- `models/integrated_system`
- `models/examples`

캐시와 코드 생성물은 프로젝트의 `work/`에 저장됩니다. 임시로 MATLAB Project를 사용하지 않을 때만
`setup_amr_project`를 실행하십시오.

## 3. 지도 UI 실행

함수 형식:

```matlab
app = launch_amr_scenario_ui(scenario, environment);
```

환경:

- `"office"`
- `"hospital"`
- `"warehouse"`

상황:

- `"normal"`
- `"obstacle"`
- `"battery"`
- `"wrong_turn"`

예:

```matlab
amrScenarioApp = launch_amr_scenario_ui("obstacle", "hospital");
```

UI의 드롭다운에서도 환경과 상황을 변경할 수 있습니다. 선택을 바꾸고 실행 버튼을 누르면 Simulink 모델을 다시 계산한 뒤 결과를 재생합니다.

## 4. 자동검사

빠른 알고리즘 단위검사:

```matlab
unitSummary = run_unit_verification();
```

사무실·병원·창고에서 네 상황을 모두 실행:

```matlab
environmentSummary = run_environment_matrix();
```

Industrial Supervisor까지 연결한 12개 조합:

```matlab
integratedEnvironmentSummary = run_integrated_environment_matrix();
```

개별 회귀검사:

```matlab
scenarioSummary = run_all_amr_scenarios();
industrialSummary = run_industrial_supervisor_scenarios();
integratedSummary = run_integrated_delivery_scenarios();
```

## 5. 모델 열기

최신 Mission Supervisor와 정리된 Stateflow 그래픽:

```matlab
load_system("models/mission_supervisor/amr_mission_supervisor.slx");
open_system("models/mission_supervisor/amr_mission_supervisor.slx");
```

Scenario Plant와 복구 Stateflow:

```matlab
load_system("models/examples/amr_scenario_supervisor.slx");
open_system("models/examples/amr_scenario_supervisor.slx");
```

계층·병렬 Industrial Supervisor:

```matlab
load_system("models/examples/amr_industrial_supervisor.slx");
open_system("models/examples/amr_industrial_supervisor.slx");
```

Plant와 Industrial Supervisor 통합 모델:

```matlab
load_system("models/integrated_system/amr_integrated_delivery_system.slx");
open_system("models/integrated_system/amr_integrated_delivery_system.slx");
```

## 6. 결과 파일

회귀 스크립트가 만든 새 결과는 로컬 `results/`에 저장됩니다. 이 폴더는 Git에서 제외됩니다. 검증된 대표 그림은 `docs/images/`, 기준 MAT 파일은 `data/expected/`에 보관합니다.

## 7. 자주 발생하는 문제

### 함수나 package를 찾지 못함

저장소 루트에서 `setup_amr_project`를 실행했는지 확인합니다.

### `MODEL_NOT_FOUND`

검사 전에 해당 `.slx` 파일을 `load_system`으로 로드합니다.

### Stateflow 또는 Simulink 라이선스 오류

이 프로젝트는 두 제품이 필요합니다. Simulink Test는 필요하지 않습니다.

### UI는 열렸지만 재생이 느림

UI의 재생 속도를 높이거나 전체 회귀검사에서는 UI를 닫고 runner만 실행하십시오.
