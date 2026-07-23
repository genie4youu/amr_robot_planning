# 09 단계 진행 및 결과

- 상태: 진행 중
- 시작일: 2026-07-20
- 완료일:

## Chart 구조

`Initializing → DriveStraight1 → TurnLeft → DriveStraight2 → Stopped`

Scenario Lab chart:

```text
Initializing → Delivering → Completed
                    ├→ ObstacleStop → AvoidingObstacle ─┤
                    ├→ ReturnToCharger → Charging ──────┤
                    └→ OffRouteStop → Rerouting ────────┘
```

Industrial Supervisor chart:

```text
PowerOff → Boot → Operational → ControlledShutdown
                       ├→ FaultLatched
                       └→ EmergencyStopLatched

Operational (parallel AND)
├─ Mission: Idle → AcceptJob → NavigatePickup → Loading
│           → NavigateDropoff → Unloading → ReturnHome
├─ Navigation: NavIdle → Planning → Tracking ↔ Replanning
│                                     └→ Recovery → NavFailed
├─ Energy: Normal → Low → Critical → Charging → Normal
├─ Safety: Safe → Slowdown → ProtectiveStop → Safe
└─ Health: Healthy ↔ Degraded → HealthFault
```

## 입력·출력·enum

- 입력: 없음(현재는 시간 기반 정상 임무 기준선)
- 출력: `vCmd`(double), `wCmd`(double), `stateId`(uint8)
- 상태 ID: Init=0, Straight1=1, Turn=2, Straight2=3, Stopped=4

Scenario Lab 입력:

- `obstacleDetected`, `batteryLow`, `offRoute`
- `atCharger`, `recoveryComplete`, `goalReached`

Scenario Lab 출력 `missionMode`:

- 0 Initializing, 1 Delivering, 2 ObstacleStop, 3 AvoidingObstacle
- 4 ReturnToCharger, 5 Charging, 6 OffRouteStop, 7 Rerouting, 8 Completed

## Timeout/retry 설정

- temporal logic `after(..., sec)`로 1초 초기화, 4초 직진, 2초 회전, 4초 직진을 구성
- Industrial Supervisor는 boot/작업 처리에 temporal logic을 사용한다.
- retry 횟수, debounce, fault timeout은 다음 버전에 추가한다.

## 정상 임무 결과

- 12초 시뮬레이션에서 예상 상태 순서 `[0 1 2 3 4]` 확인
- Stopped 진입 후 `vCmd=0`, `wCmd=0` 확인

## 실패·취소·preemption 결과

- 장애물: `[0 1 2 3 1 8]` PASS
- 저전압: `[0 1 4 5 1 8]` PASS
- 경로이탈: `[0 1 6 7 1 8]` PASS
- 취소와 외부 preemption은 아직 구현하지 않음

## Health와 emergency 결과

- health degrade 복귀와 actuator fault의 `FaultLatched` 전이 PASS
- emergency stop의 `EmergencyStopLatched → Boot → Operational` reset 순서 PASS
- 최상위 fault/e-stop 상태에서 safety와 health 출력이 강제 override됨

## Stateflow 점검 결과

- Stateflow edit-time lint 통과
- 모든 출력이 차동구동 플랜트와 로그 블록에 연결됨
- `amr_scenario_supervisor.slx` 전체 unconnected port/line 및 Stateflow lint 통과
- `amr_industrial_supervisor.slx` 전체 unconnected port/line 및 Stateflow lint 통과
- 다섯 stimulus scenario의 여섯 mode sequence 자동 assert 통과

## 다음 작업 한 가지

동시에 여러 fault가 활성화될 때의 명시적 우선순위, debounce와 retry 횟수 제한을 추가한다.
