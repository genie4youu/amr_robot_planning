# 요구사항–설계–시험 추적성 초안

상태: **Draft**

이 표는 YAML 요구사항을 목표 설계 요소와 계획된 시험에 연결한다. `구현 상태` 열은
v1 구현 전의 gap 분석을 보존하며, 실제 구현·실행 증거는 아래의 v1 갱신표에서 관리한다.
아직 모델 요소에 영구 SID 링크는 만들지 않았다.

| 요구사항 | 설계 요소 | 검증 | 구현 상태 |
| --- | --- | --- | --- |
| `REQ_AMR_001` | `LFC_Boot`, `TR_LFC_002..004` | `TC_AMR_001` | 기존 Boot 개념, 상세화 계획 |
| `REQ_AMR_002` | `TR_LFC_001` | `TC_AMR_001` | 계획 |
| `REQ_AMR_003` | `TR_LFC_004` | `TC_AMR_001` | 계획 |
| `REQ_AMR_004` | `TR_LFC_005`, `BootTimeout` | `TC_AMR_002`, `TC_AMR_019` | timeout 상세화 계획 |
| `REQ_AMR_005` | `TR_LFC_006`, ControlledShutdown | `TC_AMR_018` | 기존 개념, guard 상세화 계획 |
| `REQ_AMR_006` | ControlledShutdown motion authority | `TC_AMR_018` | 계획 |
| `REQ_AMR_007` | `TR_LFC_007` | `TC_AMR_018` | 계획 |
| `REQ_AMR_008` | `TR_LFC_008`, global priority 1 | `TC_AMR_016`, `TC_AMR_017` | 기존 latch 개념, latency 계측 계획 |
| `REQ_AMR_009` | EmergencyStopLatched invariant | `TC_AMR_016` | 기존 개념, 요청 거부 상세화 계획 |
| `REQ_AMR_010` | `TR_LFC_009` | `TC_AMR_016` | Boot 경유 reset 개념 존재 |
| `REQ_AMR_011` | `TR_MIS_001..002`, JobCommandBus | `TC_AMR_003`, `TC_AMR_004` | request ID 추가 계획 |
| `REQ_AMR_012` | `TR_MIS_003`, MissionStatusBus | `TC_AMR_004` | 계획 |
| `REQ_AMR_013` | `TR_MIS_004..010`, MissionRegion | `TC_AMR_003` | 기본 순서 개념 존재 |
| `REQ_AMR_014` | PayloadRequestBus/StatusBus, `TR_MIS_004..009` | `TC_AMR_003`, `TC_AMR_005` | 고정 지연을 handshake로 교체 계획 |
| `REQ_AMR_015` | `TR_MIS_006`, `TR_MIS_009`, PayloadOperationTimeout | `TC_AMR_005`, `TC_AMR_019` | 계획 |
| `REQ_AMR_016` | `TR_MIS_011`, `MIS_Aborting` | `TC_AMR_005` | 계획 |
| `REQ_AMR_017` | NavigationRequestBus, `TR_NAV_001` | `TC_AMR_003`, `TC_AMR_006` | request ID 추가 계획 |
| `REQ_AMR_018` | `TR_NAV_002`, `TR_NAV_006` | `TC_AMR_003`, `TC_AMR_007` | matching guard 계획 |
| `REQ_AMR_019` | `TR_NAV_003`, PlannerResponseTimeout | `TC_AMR_006`, `TC_AMR_019` | 계획 |
| `REQ_AMR_020` | `TR_NAV_004` | `TC_AMR_007` | path-invalid 개념 존재 |
| `REQ_AMR_021` | `TR_NAV_005`, NAV_Recovery | `TC_AMR_008`, `TC_AMR_009` | recovery 개념 존재 |
| `REQ_AMR_022` | `TR_NAV_007..008`, MaxRecoveryRetries | `TC_AMR_008`, `TC_AMR_009` | retry counter 계획 |
| `REQ_AMR_023` | `TR_NAV_008`, NAV_Failed | `TC_AMR_009` | failure escalation 계획 |
| `REQ_AMR_024` | `TR_SAF_001`, MotionAuthorityBus | `TC_AMR_010` | Slowdown 개념, hysteresis 계획 |
| `REQ_AMR_025` | `TR_SAF_002`, global priority 3 | `TC_AMR_011`, `TC_AMR_017` | ProtectiveStop 개념 존재 |
| `REQ_AMR_026` | `TR_SAF_003`, resume guard | `TC_AMR_011` | 명시적 resume guard 계획 |
| `REQ_AMR_027` | global priority, single arbiter | `TC_AMR_017` | priority 개념, deterministic arbiter 계획 |
| `REQ_AMR_028` | `TR_HLT_002`, status bus freshness | `TC_AMR_012`, `TC_AMR_019` | LiDAR freshness 일부 존재, 범위 확장 계획 |
| `REQ_AMR_029` | `TR_HLT_003`, `TR_LFC_010` | `TC_AMR_014`, `TC_AMR_017` | actuator fault latch 개념 존재 |
| `REQ_AMR_030` | `TR_LFC_011`, FaultLatched invariant | `TC_AMR_014` | latch 개념, reset guard 상세화 계획 |
| `REQ_AMR_031` | `TR_HLT_001`, HLT_Degraded | `TC_AMR_013` | degraded mode 상세화 계획 |
| `REQ_AMR_032` | `TR_ENG_001`, BatteryLowThreshold | `TC_AMR_015`, `TC_AMR_019` | Low mode 개념 존재 |
| `REQ_AMR_033` | `TR_ENG_002..003`, global priority 4 | `TC_AMR_015`, `TC_AMR_017` | Critical/charger 개념 존재 |
| `REQ_AMR_034` | `TR_ENG_004`, `TR_MIS_013` | `TC_AMR_015` | guarded resume 계획 |
| `REQ_AMR_035` | DiagnosticBus, transition log | `TC_AMR_001..020` | mode log 존재, transition telemetry 확장 계획 |
| `REQ_AMR_036` | MissionStatusBus terminal outcome | `TC_AMR_003..006`, `TC_AMR_009`, `TC_AMR_018` | outcome contract 계획 |
| `REQ_AMR_037` | DiagnosticBus six mode fields | `TC_AMR_001..020` | 병렬 mode log 개념 존재 |

## v1 구현·실행 증거 갱신

| 증거 ID | 구현·시험 파일 | 연결된 계획 시험 | 판정 범위 |
| --- | --- | --- | --- |
| `EV_AMR_V1_001` | `models/prototypes/amr_mission_supervisor.slx` | `TC_AMR_001`, `003`, `005`, `008`, `009`, `011`, `012`, `014..016` | 단일 Supervisor와 scripted Plant 수직 절편 |
| `EV_AMR_V1_002` | `scripts/run_amr_mission_supervisor_scenarios.m` | 위 시험의 부분 또는 전체 시나리오 | 9/9 PASS |
| `EV_AMR_V1_003` | `tests/unit/SupervisorInterfacesTest.m` | L1 계약·telemetry 판정 | 16/16 PASS |
| `EV_AMR_V1_004` | `tests/unit/verify_supervisor_requirements.m` | L1 요구사항 포맷 계약 | 제한된 포맷 검사 |
| `EV_AMR_V1_005` | `docs/results/RESULT_BASELINE.md` | 실행 결과 해석 | 검증 완료와 미검증 범위 분리 |

현재 `TC_AMR_001`, `011`, `016`의 핵심 기대 동작은 v1에서 실행했다.
나머지 연결은 해당 시험의 일부 guard 또는 fault 흐름만 검증한 것이며, request/response
ID, full Plant 폐루프, 경계 timing 행렬과 동시 fault 시험까지 통과했다는 뜻은 아니다.

## 완전성 점검

- YAML 요구사항: `REQ_AMR_001..REQ_AMR_037`
- 추적표에 연결된 요구사항: `REQ_AMR_001..REQ_AMR_037`
- 계획 시험: `TC_AMR_001..TC_AMR_020`
- 현재 실행 증거: Supervisor scenario 9개, 인터페이스 단위시험 16개
- 아직 없는 항목: model element SID 링크, calibrated parameter 기준선, 전체 시험 20개의
  완전한 구현과 closed-loop 회귀 행렬

## 향후 모델 링크 규칙

Requirements Toolbox를 도입하지 않는 동안 다음 열을 추가해 텍스트 추적성을 유지한다.

| 열 | 기록 내용 |
| --- | --- |
| `model` | 모델 상대경로 |
| `element` | chart/state/transition의 안정적인 이름 |
| `sid` | 모델 저장 후 확인한 Simulink SID |
| `test_file` | MATLAB 검증 파일 상대경로 |
| `evidence` | 기준 MAT 또는 결과 Markdown |
| `review` | 검토자, 날짜, 결론 |

영구 링크를 추가할 때는 모델 요소에서 요구사항으로 향하는 `Implement` 관계를 사용하고,
primitive block 과다 링크보다 chart·subsystem 수준의 링크를 우선한다.
