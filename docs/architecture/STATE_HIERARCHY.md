# AMR Mission Supervisor 상태 계층

상태: **Draft**

## 목표 계층

```text
AMRMissionSupervisor (OR)
├─ LFC_PowerOff
├─ LFC_Boot (OR)
│  ├─ BOOT_Initialize
│  ├─ BOOT_SelfTest
│  └─ BOOT_WaitReady
├─ LFC_Operational (AND)
│  ├─ MissionRegion (OR)
│  │  ├─ MIS_Idle
│  │  ├─ MIS_ValidateJob
│  │  ├─ MIS_NavigatePickup
│  │  ├─ MIS_Loading
│  │  ├─ MIS_NavigateDropoff
│  │  ├─ MIS_Unloading
│  │  ├─ MIS_ReturnHome
│  │  ├─ MIS_Suspended
│  │  └─ MIS_Aborting
│  ├─ NavigationRegion (OR)
│  │  ├─ NAV_Idle
│  │  ├─ NAV_Planning
│  │  ├─ NAV_Tracking
│  │  ├─ NAV_Replanning
│  │  ├─ NAV_Recovery
│  │  └─ NAV_Failed
│  ├─ EnergyRegion (OR)
│  │  ├─ ENG_Normal
│  │  ├─ ENG_Low
│  │  ├─ ENG_Critical
│  │  ├─ ENG_GoToCharger
│  │  └─ ENG_Charging
│  ├─ SafetyRegion (OR)
│  │  ├─ SAF_Clear
│  │  ├─ SAF_Slowdown
│  │  └─ SAF_ProtectiveStop
│  └─ HealthRegion (OR)
│     ├─ HLT_Healthy
│     ├─ HLT_Degraded
│     └─ HLT_FaultRequest
├─ LFC_ControlledShutdown
├─ LFC_FaultLatched
└─ LFC_EmergencyStopLatched
```

## 영역별 상태 책임

### Lifecycle

| 상태 | 책임 | 금지 동작 |
| --- | --- | --- |
| `LFC_PowerOff` | 모든 운용 mode 비활성화 | 주행·작업 수락 |
| `LFC_Boot` | initialize, self-test, readiness 확인 | motion authority 허용 |
| `LFC_Operational` | 다섯 병렬 영역 실행 | 상위 latch 무시 |
| `LFC_ControlledShutdown` | 새 작업 차단, 정지 확인 | 새 navigation goal |
| `LFC_FaultLatched` | fault 원인 보존, reset guard 평가 | 자동 Operational 복귀 |
| `LFC_EmergencyStopLatched` | E-stop 최우선 latch | motion, 작업 시작 |

### MissionRegion

MissionRegion은 작업의 비즈니스 순서와 terminal outcome만 소유한다. planner 성공 여부,
속도 명령, sensor 수치 계산은 소유하지 않는다.

```text
Idle → ValidateJob → NavigatePickup → Loading
     → NavigateDropoff → Unloading → ReturnHome → Idle
```

- `Suspended`: battery 또는 운용 hold로 작업 문맥을 보존한다.
- `Aborting`: cancel, payload timeout 또는 navigation failure를 안전하게 종결한다.
- 완료·거부·취소·timeout·실패는 한 작업당 한 번만 출력한다.
- `Suspended`에서 나갈 때는 저장한 `resumePhase`를 평가하는 명시적 junction을 거쳐
  pickup, drop-off 또는 return-home의 새 navigation request를 발행한다. history junction에
  암묵적으로 의존하지 않는다.

### NavigationRegion

NavigationRegion은 goal별 요청과 응답을 관리한다.

- `Planning`: 새 goal에 대한 경로 응답을 기다린다.
- `Tracking`: 유효한 경로 추종을 허용한다.
- `Replanning`: 현재 경로 무효화 뒤 새 request ID를 발행한다.
- `Recovery`: progress loss나 stuck에 대해 제한된 절차를 실행한다.
- `Failed`: retry 소진 결과를 MissionRegion에 전달한다.

### EnergyRegion

EnergyRegion은 SOC와 충전 상태를 mission policy로 변환한다. SOC 연속 동역학이나
소비량 계산은 Plant가 수행한다.

- `Low`: 알림과 임무 지속 가능성 재평가
- `Critical`: 정상 임무보다 survival action 우선
- `GoToCharger`: charger goal 요청
- `Charging`: motion 금지와 charge-complete 확인

### SafetyRegion

SafetyRegion은 debounce·hysteresis가 적용된 safety status를 motion intent로 변환한다.
E-stop은 이 영역이 아니라 더 높은 lifecycle latch로 승격한다.

### HealthRegion

HealthRegion은 Healthy, usable-but-degraded, latched-fault request를 구분한다.
stale data와 통신 손실은 해당 입력을 단순 `false`로 해석하지 않는다.

## 병렬 영역 상호작용 규칙

1. 각 영역은 자신의 mode와 intent만 쓴다.
2. 서로 다른 영역이 같은 출력 데이터를 직접 쓰지 않는다.
3. 영역 간 전이는 shared event 남발 대신 명시적인 status/intent 데이터로 조정한다.
4. 최종 motion authority는 모든 영역의 intent를 입력으로 받는 단일 arbitration 단계가 쓴다.
5. 동일 execution step에서 상충 조건이 생기면 `TRANSITION_TABLE.md`의 우선순위를 따른다.
6. 상태 entry에서 요청을 만들고, during에서 같은 요청을 반복 발행하지 않도록 request ID를 고정한다.
7. 상태 exit에서 fault·terminal outcome·request history를 임의로 지우지 않는다.

## Stateflow 검토 체크

- 모든 OR 영역에 default transition이 있는가
- unreachable state와 dead-end state가 없는가
- 같은 source에서 동시에 참인 transition의 우선순위가 명시적인가
- temporal logic의 시간 단위가 sample time과 일치하는가
- output마다 single writer가 있는가
- latch가 입력 해제만으로 풀리지 않는가
- recovery가 retry 또는 total timeout으로 bounded되어 있는가
- history junction이 필요하지 않은 곳에 암묵적으로 사용되지 않았는가

## 현재 모델과의 관계

`models/prototypes/amr_mission_supervisor.slx`에 lifecycle과 다섯 병렬 영역을 가진
단일 Supervisor 수직 절편을 구현했다. 모델 구조 검사에서 각 병렬 영역은
`Operational` 아래에 존재하며 unconnected port/line과 Stateflow lint 오류가 없다.

목표 계층과 v1의 의도적인 차이는 다음과 같다.

- v1의 `Boot`는 `bootComplete` guard를 가진 단일 상태다. Initialize/SelfTest/WaitReady
  하위 상태와 개별 timeout은 후속 단계다.
- v1 MissionRegion은 terminal telemetry를 명확히 하기 위해 `Completed` 상태를 포함한다.
- `Suspended`와 phase별 resume은 아직 구현하지 않았다. 현재 battery critical과 charging은
  EnergyRegion 및 최종 Safety Arbiter에서 motion authority를 차단한다.
- payload load/unload는 고정 시간이 아니라 `loadComplete`, `unloadComplete` handshake를
  사용하지만 request/response ID bus는 후속 단계다.
- enum mode, fault reason, recovery action과 transition ID는 v1 출력에 포함했다.
- 최종 `motionPermit`은 lifecycle/navigation/safety/health/energy permit을 받는 루트의
  단일 arbitration 블록이 소유한다.

기존 `models/system/amr_industrial_supervisor.slx`와
`models/system/amr_integrated_delivery_system.slx`는 비교 기준선으로 유지했으며 변경하지 않았다.
