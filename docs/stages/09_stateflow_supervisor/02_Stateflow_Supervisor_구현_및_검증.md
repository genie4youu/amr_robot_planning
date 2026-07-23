# Stateflow Supervisor 구현 및 검증

## 구현 순서

1. 입력·출력 데이터와 enum 후보를 문서화한다.
2. `Idle → GoToPickup → Loading → GoToDropoff → Unloading → ReturnHome`만 구현한다.
3. planner/controller feedback 없이 scripted feedback으로 chart를 검증한다.
4. timeout과 retry를 추가한다.
5. cancel과 새 goal preemption을 추가한다.
6. Health region과 degraded mode를 추가한다.
7. emergency override를 연결한다.
8. 실제 navigation status bus와 연결한다.

## 예정 모델

```text
models/prototypes/amr_stateflow_mission_prototype.slx
models/system/amr_system.slx        통합 단계에서 생성
```

## 예정 데이터

```text
MissionCommand
MissionStatus
NavigationRequest
NavigationStatus
RobotHealth
SafetyStatus
```

## 검증 시나리오

- 정상 배송
- pickup goal planning 실패 후 재시도
- loading timeout
- delivery 중 새 목표
- navigation stuck
- localization invalid
- 센서 glitch 후 회복
- latched emergency stop

## Stateflow 검토 항목

- default transition
- unreachable state
- ambiguous transition
- parallel execution order
- temporal logic 단위
- output의 single writer
