# 실내 배송 AMR 전체 프로젝트 계획

작성일: 2026-07-20

관련 문서: [프로젝트 홈](../README.md) · [현재 상태](PROGRESS.md) · [설계 결정](DECISIONS.md) · [공개 출처](references/공개_출처.md)

## 1. 프로젝트 목표

MATLAB, Simulink, Stateflow만 사용해 다음 능력을 갖는 2D 실내 배송 로봇 시뮬레이션을 구축한다.

1. 차동구동 로봇과 구동계의 운동을 시뮬레이션한다.
2. 엔코더, IMU, 2D LiDAR를 가상 센서로 생성한다.
3. 알려진 지도에서 로봇 위치를 추정한다.
4. 미지의 환경에서 점유 격자 지도를 작성한다.
5. scan matching, loop closure, pose graph를 단계적으로 구현한다.
6. 전역 경로와 지역 속도 명령을 계산한다.
7. 장애물과 고장 조건에서 감속, 정지, 재계획, 복구를 수행한다.
8. Stateflow가 배송 임무, 충전 복귀, 고장 대응을 최상위에서 관리한다.
9. MATLAB 스크립트로 시나리오를 반복 실행하고 정량적으로 검증한다.

완성 목표는 상용 Nav2나 SLAM 패키지를 복제하는 것이 아니다. 공개된 구조와 핵심 알고리즘을 이해 가능한 크기로 직접 구현하고, 각 단계를 설명하고 검증할 수 있는 학습용 AMR 스택을 만드는 것이다.

## 2. 성공 기준

최종 통합 시나리오에서 다음 조건을 만족해야 한다.

- 로봇은 픽업 지점, 배송 지점, 대기 또는 충전 지점을 순서대로 방문한다.
- 제어기는 `groundTruthPose`를 사용하지 않고 `estimatedPose`만 사용한다.
- 정적 지도와 동적 장애물 정보가 전역·지역 costmap으로 분리된다.
- 경로가 막히면 재계획 또는 복구 상태로 전환한다.
- 센서 데이터가 오래되거나 위치 추정이 무효이면 안전 정지한다.
- 비상정지 명령은 다른 모든 이동 명령보다 우선한다.
- 정상, 장애물, 위치 추정 실패, 경로 없음, 배터리 부족 시나리오를 MATLAB `assert`로 판정한다.
- 지도, 경로, 추정 자세, Stateflow 상태, 안전 명령을 사후 분석할 수 있도록 기록한다.

## 3. 시스템 경계

### 포함

- 2D 차동구동 로봇
- 평면 실내 환경
- 2D 점유 격자
- 가상 엔코더, IMU, LiDAR
- A* 전역 계획
- DWA 계열 지역 계획
- Pure Pursuit 비교 기준
- Stateflow 임무·복구·고장 제어
- MATLAB 기반 자동 실행과 검증

### 초기 범위에서 제외

- 실제 하드웨어 연결
- ROS 메시지 및 네트워크
- 3D SLAM
- 카메라 기반 인식
- 사람 분류 또는 딥러닝
- 다중 로봇 스케줄링
- 안전 인증 또는 실제 비상정지 하드웨어

## 4. 논리 아키텍처

```text
Mission Command
      ↓
Stateflow Mission Supervisor
      ├─ mission mode
      ├─ navigation goal
      ├─ recovery request
      └─ emergency override
                     ↓
Map / Pose Estimation / Health Status
                     ↓
Global Costmap → A* → Path Smoothing
                     ↓
Local Costmap  → DWA Local Planner
                     ↓
Safety Monitor → Velocity Limiter
                     ↓
Inverse Kinematics → Wheel Controller
                     ↓
Robot Plant → Encoder / IMU / LiDAR
```

### 중요한 데이터 경계

| 데이터 | 의미 |
| --- | --- |
| `groundTruthPose` | 플랜트 실제 자세. 평가에만 사용 |
| `odometryPose` | 엔코더·IMU 기반 연속 자세 |
| `estimatedPose` | 지도 기준 위치 추정 결과. 제어 입력으로 사용 |
| `globalMap` | 저장된 정적 점유 지도 |
| `localCostmap` | 센서 기반 동적 장애물과 팽창 비용 |
| `globalPath` | 전역 플래너가 생성한 경로 |
| `velocityCommand` | 지역 플래너가 요청한 `v`, `omega` |
| `safeVelocityCommand` | 안전 감시 후 플랜트에 전달되는 명령 |
| `navigationStatus` | 계획, 추종, 목표 도달, stuck, failure 상태 |
| `robotHealth` | 센서 유효성, 추정 신뢰도, 배터리, 고장 상태 |

모든 주요 데이터에는 가능한 범위에서 `timestamp`, `valid`, `age`, `frame`, `covariance` 개념을 포함한다.

## 5. 단계별 로드맵

| 단계 | 폴더 | 핵심 결과물 | 선행 단계 |
| --- | --- | --- | --- |
| 00 | [00_project_setup](stages/00_project_setup/00_project_setup.md) | 환경 기준, 단위, 데이터 계약, 기록 방식 | 없음 |
| 01 | [01_math_frames_timing](stages/01_math_frames_timing/01_math_frames_timing.md) | SE(2), 좌표 변환, 각도, 멀티레이트 규칙 | 00 |
| 02 | [02_robot_modeling](stages/02_robot_modeling/02_robot_modeling.md) | 차동구동 플랜트와 바퀴 제어 | 01 |
| 03 | [03_sensor_simulation](stages/03_sensor_simulation/03_sensor_simulation.md) | 엔코더, IMU, 2D LiDAR 시뮬레이터 | 01, 02 |
| 04 | [04_mapping](stages/04_mapping/04_mapping.md) | 알려진 자세 기반 log-odds 점유 지도 | 01, 03 |
| 05 | [05_localization](stages/05_localization/05_localization.md) | 오도메트리, EKF, 고정 지도 MCL | 01~04 |
| 06 | [06_slam](stages/06_slam/06_slam.md) | scan matching, incremental SLAM, loop closure 기초 | 04, 05 |
| 07 | [07_global_planning](stages/07_global_planning/07_global_planning.md) | global costmap, A*, 경로 후처리 | 01, 04 |
| 08 | [08_local_planning_control](stages/08_local_planning_control/08_local_planning_control.md) | local costmap, DWA, 속도·바퀴 제어 | 02, 03, 07 |
| 09 | [09_stateflow_supervisor](stages/09_stateflow_supervisor/09_stateflow_supervisor.md) | 임무, 내비게이션, health 상위 상태 제어 | 07, 08 |
| 10 | [10_safety_recovery](stages/10_safety_recovery/10_safety_recovery.md) | 독립 안전 게이트, progress checker, 복구 | 03, 08, 09 |
| 11 | [11_system_integration](stages/11_system_integration/11_system_integration.md) | 통합 Simulink/Stateflow 모델 | 02~10 |
| 12 | [12_verification](stages/12_verification/12_verification.md) | 반복 시나리오, 지표, 회귀 검증 | 각 단계 |
| 13 | [13_delivery_extensions](stages/13_delivery_extensions/13_delivery_extensions.md) | 배터리, 충전 복귀, 도킹, 배송 확장 | 11, 12 |

단계 번호는 학습 순서를 나타낸다. 04~08은 필요하면 일부 병행할 수 있지만, 각 폴더의 진입 조건을 만족하지 않으면 통합 모델에 연결하지 않는다.

## 6. 단계 공통 작업 방식

각 단계는 다음 순서를 따른다.

```text
이론 읽기
→ 입력·출력과 가정 작성
→ MATLAB 단독 프로토타입
→ 작은 수치 예제로 검증
→ Simulink subsystem으로 이식
→ 정상·경계·실패 시나리오 실행
→ 결과와 설정 기록
→ 다음 단계 진입 여부 결정
```

각 단계 폴더의 파일 역할은 동일하다.

- 단계명과 같은 대표 문서: 목표, 선행 조건, 결과물, 완료 조건
- `01_기본개념과_이론.md`: 공식, 용어, 공부 항목, 공개 출처
- `02_구현_및_검증_절차.md`: 구현 순서, 예정 파일, 검증 시나리오
- `03_진행_및_결과.md`: 실제 설정, 성공·실패, 산출물 링크, 다음 작업

## 7. 실제 소스 배치 원칙

학습 문서와 실제 코드를 분리한다.

```text
docs/stages/             학습 순서와 작업 안내
src/+amr/                재사용 MATLAB 함수
models/prototypes/       단계별 Simulink 실험 모델
models/system/           통합 모델
data/maps/               지도
data/scenarios/          시나리오 입력
tests/unit/              작은 함수 검증
tests/scenarios/         통합 시나리오 검증
docs/images/             검토한 대표 결과 그림
data/expected/           기준 검증 데이터
```

예를 들어 SLAM 단계 문서는 `docs/stages/06_slam/`에 있지만, 재사용되는 scan matching 코드는 `src/+amr/+slam/`에 둔다.

## 8. 모델 구성 전략

### 초기

- 알고리즘은 MATLAB 함수로 먼저 확인한다.
- 단계별 작은 모델은 `models/prototypes/`에 둔다.
- Base Workspace에 남아 있는 변수에 의존하지 않는다.

### 통합

- 현재 통합 모델은 `amr_integrated_delivery_system.slx`로 관리한다.
- 처음에는 하나의 모델 안에 명확한 atomic subsystem으로 구성한다.
- 모델이 실제로 커지고 인터페이스가 안정되면 Model Reference 분리를 검토한다.
- Stateflow chart는 임무 로직을 담당하고 연속 계산 알고리즘을 내부에 과도하게 넣지 않는다.

## 9. 검증 전략

Simulink Test를 사용할 수 없으므로 다음 계층으로 검증한다.

1. MATLAB 함수 수준: 작은 입력과 예상 출력에 `assert`
2. subsystem 수준: 고정 시나리오와 허용 오차 비교
3. 통합 모델 수준: `Simulink.SimulationInput`과 `sim`
4. 반복 실험: 고정 random seed와 여러 seed를 분리
5. 회귀 확인: 이전에 통과한 시나리오가 계속 통과하는지 검사

핵심 지표:

- 자세 추정 RMSE와 drift
- 지도 점유 정확도와 미관측 영역
- 경로 길이, clearance, 계산 시간
- 최소 장애물 거리와 충돌 횟수
- 임무 성공률과 완료 시간
- 복구 횟수와 실패 원인
- 센서 timeout 후 안전 정지까지의 시간

## 10. 결과 및 의사결정 기록

- 단계별 최종 설정과 요약: 각 단계의 `03_진행_및_결과.md`
- 중요한 구조 변경: [DECISIONS](DECISIONS.md)
- 현재 진행률: [PROGRESS](PROGRESS.md)
- 대표 그림과 표: `docs/images/`, `docs/RESULTS.md`
- 기준 데이터: `data/expected/`
- 재생성 가능한 대용량 로그는 Git 관리 대상으로 가정하지 않는다.

설정값을 바꿀 때는 이전 값, 새 값, 변경 이유, 비교 결과를 함께 기록한다.

## 11. 위험과 대응

| 위험 | 대응 |
| --- | --- |
| SLAM이 프로젝트 전체를 지연 | 알려진 자세 mapping → localization → incremental SLAM → loop closure 순서 유지 |
| 알고리즘 코드가 모델에 종속 | MATLAB 함수 단독 검증 후 MATLAB Function 블록에서 호출 가능한 형태로 제한 |
| ground truth가 제어기에 누출 | 신호 이름과 bus를 분리하고 검증 스크립트에서 연결 검사 |
| DWA 튜닝이 불안정 | Pure Pursuit 기준 모델과 비교하고 cost 항목을 하나씩 추가 |
| Stateflow가 지나치게 복잡 | Mission, Navigation, Health 역할 분리와 계층·병렬 상태 사용 |
| 결과를 재현할 수 없음 | random seed, 파라미터, 모델 버전, 실행 명령 기록 |
| 처리 시간이 지나치게 큼 | 지도 해상도, LiDAR 빔 수, 후보 속도 수를 단계적으로 증가 |

## 12. 바로 다음 작업

현재 수직 절편 다음에는 다음 순서로 확장한다.

1. log-odds map을 online local/global costmap에 연결
2. wheel odometry와 IMU 모델을 pose EKF에 연결
3. localization health를 Industrial Supervisor 입력에 연결
4. no-valid-candidate, oscillation, 복합 fault recovery 검증
5. scan matching → loop closure → pose graph 순서로 SLAM 구현
6. typed bus와 rate transition으로 통합 인터페이스 고정
