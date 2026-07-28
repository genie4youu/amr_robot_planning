# AMR Mission Supervisor 인터페이스 계약

상태: **Draft**

현재 통합 모델의 개별 boolean/`uint8` 신호를 바로 폐기하지 않고, 다음 구현 단계에서
typed bus와 enum으로 점진적으로 치환하기 위한 목표 계약이다.

## v1 구현 경계

`models/prototypes/amr_mission_supervisor.slx`는 Plant와 Supervisor 책임을 먼저
분리해 검증하기 위해 26개 scalar 입력을 adapter 경계로 사용한다.

| 입력 묶음 | v1 신호 |
| --- | --- |
| operator | `startRequest`, `shutdownRequest`, `resetRequest`, `resumeRequest`, `cancelRequest` |
| system | `bootComplete`, `robotStopped` |
| emergency | `emergencyStop` |
| mission/payload | `jobAvailable`, `loadComplete`, `unloadComplete` |
| navigation | `planReady`, `plannerFailed`, `controllerFailed`, `goalReached`, `pathInvalid` |
| safety | `obstacleSlow`, `obstacleStop` |
| energy | `batteryLow`, `batteryCritical`, `chargerReached`, `chargeComplete` |
| health/freshness | `localizationHealthy`, `sensorFresh`, `communicationFresh`, `actuatorHealthy` |

루트 출력은
`lifecycleMode`, `missionMode`, `navigationMode`, `energyMode`, `safetyMode`,
`healthMode`, `motionPermit`, `faultReason`, `recoveryCount`, `transitionId`,
`recoveryAction`의 11개다. 여섯 mode와 fault/recovery 값은
`src/+amr/+supervision/`의 named enum을 사용한다.

v1의 scalar 입력은 최종 계약이 아니라 scripted Plant와 typed bus adapter 사이의
검증 seam이다. 다음 단계에서는 이 루트 인터페이스를 아래 목표 bus로 묶되 Stateflow
내부의 책임과 단일 `motionPermit` 소유권은 유지한다.

## 공통 규칙

1. Supervisor 입력은 현재 실행 주기의 immutable snapshot으로 취급한다.
2. 비동기 명령에는 `requestId`, 응답에는 같은 작업을 가리키는 `responseId`를 둔다.
3. 상태 입력은 `valid`와 `dataAge`를 포함해 오래된 데이터와 실제 `false`를 구분한다.
4. mode, command, outcome, reason은 named enum을 사용한다.
5. 출력은 관심사별 intent로 분리한 뒤 단일 command arbiter가 최종 authority를 결정한다.
6. 입력이 유효하지 않으면 안전 쪽으로 실패하도록 하되, 원인 코드를 함께 남긴다.
7. bus와 enum 정의는 data dictionary로 이동하기 전까지 별도 MATLAB 정의 파일에서 관리한다.

## 입력 bus

### `OperatorCommandBus`

| 필드 | 개념 형식 | 의미 |
| --- | --- | --- |
| `powerOnRequest` | logical | PowerOff에서 boot 요청 |
| `shutdownRequest` | logical | controlled shutdown 요청 |
| `cancelRequest` | logical | 현재 작업 취소 |
| `resumeRequest` | logical | 보호정지·중단 후 재개 요청 |
| `resetRequest` | logical | fault/E-stop reset 요청 |
| `acknowledgementValid` | logical | 운용자 확인 조건 |
| `commandSequence` | uint32 | 중복 명령 검출용 순번 |

`resetRequest` 하나만으로 reset을 허용하지 않는다. active fault 제거, stop 확인,
acknowledgement 등 상태별 guard를 함께 평가한다.

### `JobCommandBus`

| 필드 | 개념 형식 | 의미 |
| --- | --- | --- |
| `valid` | logical | 새 작업 데이터의 유효성 |
| `jobId` | uint32 | 작업 식별자 |
| `requestId` | uint32 | 요청 식별자 |
| `pickupPose` | pose 구조체 | 픽업 목표 |
| `dropoffPose` | pose 구조체 | 배송 목표 |
| `payloadClass` | enum | payload 종류 |
| `expiryTime` | time | 작업 유효 기한 |

### `PayloadStatusBus`

| 필드 | 개념 형식 | 의미 |
| --- | --- | --- |
| `valid` | logical | 상태 신뢰 가능 여부 |
| `dataAge` | time | freshness |
| `responseId` | uint32 | 완료 응답이 대응하는 요청 |
| `operationState` | enum | Idle, Busy, Completed, Failed |
| `payloadPresent` | logical | payload 감지 |
| `faultCode` | enum | payload 장치 원인 코드 |

### `NavigationStatusBus`

| 필드 | 개념 형식 | 의미 |
| --- | --- | --- |
| `valid` | logical | navigation 상태 유효성 |
| `dataAge` | time | freshness |
| `responseId` | uint32 | plan/recovery 응답 식별자 |
| `planState` | enum | Idle, Pending, Valid, Rejected |
| `trackingState` | enum | Idle, Active, GoalReached, Failed |
| `pathValid` | logical | 현재 경로 유효성 |
| `progressValid` | logical | progress watchdog 결과 |
| `stuckDetected` | logical | 이동 불가 판정 |
| `goalId` | uint32 | active goal 식별자 |

### `LocalizationStatusBus`

| 필드 | 개념 형식 | 의미 |
| --- | --- | --- |
| `valid` | logical | pose 사용 가능 여부 |
| `dataAge` | time | freshness |
| `quality` | enum | Nominal, Degraded, Invalid |
| `pose` | pose 구조체 | 추정 pose |
| `uncertainty` | covariance 구조체 | 추정 불확실성 |
| `reasonCode` | enum | degradation 원인 |

### `SafetyStatusBus`

| 필드 | 개념 형식 | 의미 |
| --- | --- | --- |
| `emergencyStopActive` | logical | 최상위 비상정지 입력 |
| `protectiveStopRequest` | logical | 보호정지 요청 |
| `slowdownRequest` | logical | 감속 요청 |
| `hazardClear` | logical | 해제 조건 |
| `stopConfirmed` | logical | plant 정지 확인 |
| `sourceValid` | logical | safety monitor 입력 유효성 |
| `dataAge` | time | freshness |
| `reasonCode` | enum | 정지·감속 원인 |

### `DriveHealthBus`

| 필드 | 개념 형식 | 의미 |
| --- | --- | --- |
| `valid` | logical | 상태 유효성 |
| `dataAge` | time | freshness |
| `health` | enum | Healthy, Degraded, Fault |
| `leftWheelFault` | logical | 좌측 구동 fault |
| `rightWheelFault` | logical | 우측 구동 fault |
| `motionFeedbackValid` | logical | 명령 대비 움직임 확인 |
| `reasonCode` | enum | fault 원인 |

### `EnergyStatusBus`

| 필드 | 개념 형식 | 의미 |
| --- | --- | --- |
| `valid` | logical | 상태 유효성 |
| `dataAge` | time | freshness |
| `soc` | normalized scalar | battery state of charge |
| `level` | enum | Normal, Low, Critical |
| `chargerReached` | logical | charger goal 도착 |
| `chargerConnected` | logical | 접속 확인 |
| `chargeComplete` | logical | 충전 완료 |
| `reasonCode` | enum | energy 원인 |

### `SystemStatusBus`

| 필드 | 개념 형식 | 의미 |
| --- | --- | --- |
| `initializationComplete` | logical | 초기화 완료 |
| `selfTestPassed` | logical | 자체 점검 통과 |
| `timeBaseValid` | logical | 실행 시간 기준 유효 |
| `communicationHealth` | enum | Healthy, Degraded, Lost |
| `currentTime` | time | freshness 계산 기준 |

## 출력 bus

### `NavigationRequestBus`

| 필드 | 의미 |
| --- | --- |
| `requestId` | 요청 식별자 |
| `goalId` | goal 식별자 |
| `requestType` | Plan, Track, Replan, Recover, Cancel |
| `goalPose` | 목표 pose |
| `enabled` | navigation 요청 유효 여부 |

### `PayloadRequestBus`

| 필드 | 의미 |
| --- | --- |
| `requestId` | 요청 식별자 |
| `operation` | Load, Unload, Cancel |
| `jobId` | 작업 식별자 |
| `enabled` | payload 요청 유효 여부 |

### `MotionAuthorityBus`

| 필드 | 의미 |
| --- | --- |
| `motionPermitted` | 후보 주행 명령 허용 여부 |
| `speedLimitMode` | Stop, Restricted, Nominal |
| `authoritySource` | 최종 결정을 만든 관심사 |
| `reasonCode` | 제한·정지 원인 |

이 출력은 wheel velocity 자체가 아니다. 최종 Safety Arbiter가 이 authority와 planner의
후보 명령을 결합한다.

### `EnergyRequestBus`

| 필드 | 의미 |
| --- | --- |
| `requestChargerGoal` | charger navigation 요청 |
| `requestCharging` | 충전 시작·유지 요청 |
| `suspendMission` | 현재 작업 보존 후 중단 요청 |

### `MissionStatusBus`

| 필드 | 의미 |
| --- | --- |
| `jobId` | 현재 또는 마지막 작업 |
| `acceptance` | None, Accepted, Rejected |
| `outcome` | Active, Completed, Cancelled, TimedOut, Failed |
| `phase` | Idle, Pickup, Loading, Dropoff, Unloading, ReturnHome |
| `reasonCode` | 거부·중단·완료 원인 |

### `DiagnosticBus`

| 필드 | 의미 |
| --- | --- |
| `lifecycleMode` | 상위 lifecycle enum |
| `missionMode` | MissionRegion enum |
| `navigationMode` | NavigationRegion enum |
| `energyMode` | EnergyRegion enum |
| `safetyMode` | SafetyRegion enum |
| `healthMode` | HealthRegion enum |
| `transitionId` | 마지막 전이 식별자 |
| `transitionReason` | 마지막 전이 원인 |
| `recoveryAttemptCount` | 현재 복구 시도 횟수 |
| `timestamp` | 기록 시각 |

## 미결정 항목

- 각 bus의 실제 Simulink data type과 storage class
- freshness, timeout, SOC, safety-zone 임계값
- v1 Supervisor sample time은 `0.05 s`; Plant 연결 뒤 multirate 정책은 미결정
- v1 fault/recovery enum은 정의됨; 외부 프로토콜 매핑과 확장 목록은 미결정
- reset acknowledgement가 local operator인지 fleet command인지

미결정 값은 구현 시 임의 literal로 넣지 않고 명명된 파라미터와 근거를 확정한 뒤
요구사항 YAML에 해석값을 함께 반영한다.
