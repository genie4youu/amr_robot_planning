# 실무형 Stateflow 감독 제어 구조

이 문서는 `models/examples/amr_industrial_supervisor.slx`의 역할과 경계를 설명한다. 목표는 상태를 무작정 많이 만드는 것이 아니라, 동시에 변하는 관심사를 병렬 영역으로 분리하고 위험 상태를 상위에서 래치하는 것이다.

## 계층 구조

```text
IndustrialSupervisor (OR)
├─ PowerOff
├─ Boot
├─ Operational (AND)
│  ├─ MissionRegion (OR)
│  ├─ NavigationRegion (OR)
│  ├─ EnergyRegion (OR)
│  ├─ SafetyRegion (OR)
│  └─ HealthRegion (OR)
├─ ControlledShutdown
├─ FaultLatched
└─ EmergencyStopLatched
```

상위 lifecycle은 한 번에 하나만 활성화된다. `Operational` 안에서는 임무, 내비게이션, 에너지, 안전, 건전성 영역이 동시에 활성화된다. 예를 들어 배송 경로를 추종하는 중에도 배터리는 `Low`가 되고 안전 영역은 `Slowdown`이 될 수 있다.

## 영역별 책임

| 영역 | 대표 상태 | 책임 |
| --- | --- | --- |
| Lifecycle | Off, Boot, Operational, Fault, E-Stop | 전원·초기화·래치·reset |
| Mission | Idle, AcceptJob, Pickup, Dropoff, ReturnHome | 작업 순서와 상위 목표 |
| Navigation | Planning, Tracking, Replanning, Recovery | planner/controller 실행 mode |
| Energy | Normal, Low, Critical, Charging | 저전압 대응과 충전 mode |
| Safety | Safe, Slowdown, ProtectiveStop | 속도 제한과 보호정지 요청 |
| Health | Healthy, Degraded, HealthFault | 장치 건전성과 latched fault 요청 |

## Stateflow 밖에 남기는 계산

- occupancy grid 생성과 장애물 팽창
- A* 탐색과 path smoothing
- pose feedback 및 wheel command 계산
- segment/footprint collision 수학
- 배터리 연속 동역학과 센서 신호 처리

Stateflow 출력은 이러한 구성요소를 enable하거나 mode를 선택하고, 마지막 command arbitration에서 안전 우선순위를 적용하는 데 사용한다. 수치 알고리즘을 chart action에 모두 넣지 않는다.

## 현재 우선순위와 latch

1. Emergency stop
2. Latched actuator/health fault
3. Controlled shutdown
4. Operational safety/energy/navigation 요청
5. Nominal mission progression

비상정지는 reset 후 Boot를 다시 거친다. actuator fault는 입력이 사라졌다는 이유만으로 자동 복귀하지 않는 latched 상태다. 이 구조는 교육용 1차 구현이며 기능 안전 인증 모델을 의미하지 않는다.

## 다음 실무화 항목

- 이벤트 debounce와 `duration` 기반 확인 시간
- recovery retry counter와 timeout, 실패 escalation
- operator acknowledgement와 job cancel/preemption
- uint8 대신 명명된 enum, typed bus와 data dictionary
- Scenario Lab plant와 supervisor mode interface 통합
- 요구사항 ID, transition rationale, coverage 및 경계값 시험

## 재현

```matlab
projectRoot = setup_amr_project();
load_system('models/examples/amr_industrial_supervisor.slx')
open_system('models/examples/amr_industrial_supervisor.slx')
industrialSummary = run_industrial_supervisor_scenarios();
```

Plant 신호와 함께 통합 실행하려면 다음을 사용한다.

```matlab
load_system('models/integrated_system/amr_integrated_delivery_system.slx')
open_system('models/integrated_system/amr_integrated_delivery_system.slx')
integratedSummary = run_integrated_delivery_scenarios();
```

통합 모델의 adapter는 LiDAR slowdown/stop, path invalid, battery low/critical, charger/charge-complete, localization health를 Industrial Supervisor 입력으로 전달한다. 완료 시 `ControlledShutdown → PowerOff`로 종료하며 start request를 차단해 반복 재부팅을 방지한다.
