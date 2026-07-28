# 전이 표와 안전 우선순위

상태: **Draft**

이 문서는 목표 전이의 guard, 결과와 근거를 고정한다. v1 수직 절편은 이 표의 핵심
우선순위와 흐름을 구현했으며, 실제 모델과 목표 계약의 차이는 아래에 별도로 기록한다.

## 전역 우선순위

| 우선순위 | 조건 | 결과 |
| ---: | --- | --- |
| 1 | `emergencyStopActive` | motion revoke, `LFC_EmergencyStopLatched` |
| 2 | latched drive/health fault | motion revoke, `LFC_FaultLatched` |
| 3 | confirmed protective stop 또는 필수 데이터 stale | motion revoke, `SAF_ProtectiveStop` |
| 4 | battery critical | safe stop 또는 charger survival action |
| 5 | navigation path invalid/stuck/recovery | tracking revoke, replan/recovery |
| 6 | operator cancel/hold | controlled abort 또는 suspend |
| 7 | 정상 mission progression | 다음 작업 단계 |

낮은 우선순위 조건은 진단에서 사라지지 않는다. 최종 상태를 결정하지 못했더라도 동시에
발생한 원인을 event log에 보존한다.

## Lifecycle 전이

| ID | Source | Trigger/guard | Target | 핵심 action | 요구사항 |
| --- | --- | --- | --- | --- | --- |
| `TR_LFC_001` | PowerOff | valid power-on request | Boot.Initialize | mission context 초기화, motion revoke | 002 |
| `TR_LFC_002` | Boot.Initialize | initialization complete | Boot.SelfTest | self-test 요청 | 001 |
| `TR_LFC_003` | Boot.SelfTest | self-test passed | Boot.WaitReady | readiness 확인 | 001 |
| `TR_LFC_004` | Boot.WaitReady | all readiness guards valid | Operational | Mission Idle로 시작 | 003 |
| `TR_LFC_005` | Boot | failure 또는 `BootTimeout` | FaultLatched | failure reason latch | 004 |
| `TR_LFC_006` | Operational | accepted shutdown | ControlledShutdown | 새 작업 차단 | 005 |
| `TR_LFC_007` | ControlledShutdown | stop confirmed | PowerOff | shutdown outcome 기록 | 006, 007 |
| `TR_LFC_008` | Any | emergency stop active | EmergencyStopLatched | 즉시 motion revoke | 008, 009 |
| `TR_LFC_009` | EmergencyStopLatched | E-stop inactive AND stop confirmed AND acknowledgement valid AND reset request | Boot.Initialize | reset event 기록 | 010 |
| `TR_LFC_010` | Operational | latched drive/health fault | FaultLatched | fault reason latch | 029, 030 |
| `TR_LFC_011` | FaultLatched | fault cleared AND stop confirmed AND acknowledgement valid AND reset request | Boot.Initialize | reset event 기록 | 030 |

## Mission 전이

| ID | Source | Trigger/guard | Target | 핵심 action | 요구사항 |
| --- | --- | --- | --- | --- | --- |
| `TR_MIS_001` | Idle | new job with new request ID | ValidateJob | job snapshot 저장 | 011 |
| `TR_MIS_002` | ValidateJob | job valid and system ready | NavigatePickup | accepted outcome 1회 출력 | 011, 013 |
| `TR_MIS_003` | ValidateJob | invalid or infeasible | Idle | rejected + reason 1회 출력 | 012, 036 |
| `TR_MIS_004` | NavigatePickup | matching goal reached | Loading | Load request ID 발행 | 013, 014 |
| `TR_MIS_005` | Loading | matching payload response completed | NavigateDropoff | drop-off goal 선택 | 013, 014 |
| `TR_MIS_006` | Loading | payload timeout/failure | Aborting | timeout/failure reason 기록 | 015, 036 |
| `TR_MIS_007` | NavigateDropoff | matching goal reached | Unloading | Unload request ID 발행 | 013, 014 |
| `TR_MIS_008` | Unloading | matching payload response completed | ReturnHome | home goal 선택 | 013, 014 |
| `TR_MIS_009` | Unloading | payload timeout/failure | Aborting | timeout/failure reason 기록 | 015, 036 |
| `TR_MIS_010` | ReturnHome | matching goal reached | Idle | completed outcome 1회 출력 | 013, 036 |
| `TR_MIS_011` | Active mission | accepted cancel | Aborting | 새 goal 차단 | 016, 036 |
| `TR_MIS_012` | Active mission | energy suspend request | Suspended | job context 보존 | 032, 033 |
| `TR_MIS_013` | Suspended | charge complete AND job valid AND all resume guards valid | ResumeDecision junction을 거쳐 저장된 명시적 phase | 새 request ID 발행 | 034 |

## Navigation 전이

| ID | Source | Trigger/guard | Target | 핵심 action | 요구사항 |
| --- | --- | --- | --- | --- | --- |
| `TR_NAV_001` | Idle | active navigation goal | Planning | plan request ID 발행 | 017 |
| `TR_NAV_002` | Planning | matching valid plan response | Tracking | tracking authority 요청 | 018 |
| `TR_NAV_003` | Planning | response timeout/rejection | Recovery | planner reason 기록 | 019, 021 |
| `TR_NAV_004` | Tracking | active path invalid | Replanning | tracking revoke, 새 request ID | 020 |
| `TR_NAV_005` | Tracking | progress invalid 또는 stuck | Recovery | tracking revoke, attempt 시작 | 021 |
| `TR_NAV_006` | Replanning | matching valid plan | Tracking | 새 path 활성화 | 018, 020 |
| `TR_NAV_007` | Recovery | attempt succeeds | Planning | recovery count 보존, replan | 021, 022 |
| `TR_NAV_008` | Recovery | attempts exhausted | Failed | recovery-exhausted reason | 022, 023 |

## Energy·Safety·Health 전이

| ID | Region | Trigger/guard | Target/result | 요구사항 |
| --- | --- | --- | --- | --- |
| `TR_ENG_001` | Energy | confirmed low threshold | Low, mission 평가 | 032 |
| `TR_ENG_002` | Energy | confirmed critical threshold | Critical, survival action | 033 |
| `TR_ENG_003` | Energy | charger goal reached and connected | Charging, motion revoke | 033 |
| `TR_ENG_004` | Energy | charge complete | Normal, guarded resume 평가 | 034 |
| `TR_SAF_001` | Safety | confirmed slowdown | Slowdown, restricted authority | 024 |
| `TR_SAF_002` | Safety | confirmed protective stop | ProtectiveStop, motion revoke | 025 |
| `TR_SAF_003` | Safety | hazard clear AND resume guard valid | Clear, authority 재평가 | 026 |
| `TR_HLT_001` | Health | localization usable but degraded | Degraded, policy 선택 | 031 |
| `TR_HLT_002` | Health | required data stale | FaultRequest 또는 protective stop | 028 |
| `TR_HLT_003` | Health | drive/actuator fault | FaultRequest → lifecycle latch | 029, 030 |

## 동시 조건 판정 예

| 동시 입력 | 선택 상태 | 함께 보존할 진단 |
| --- | --- | --- |
| E-stop + battery critical | EmergencyStopLatched | E-stop, battery critical |
| protective stop + cancel | ProtectiveStop 유지 후 controlled abort | hazard, cancel |
| path invalid + stuck | Recovery 또는 Replanning 정책 결과 | 두 navigation 원인 |
| stale LiDAR + path reached | ProtectiveStop | stale LiDAR, goal feedback |
| drive fault + reset request | FaultLatched 유지 | active fault, rejected reset |

## 구현 전 확정할 guard

- `BootTimeout`, `PlannerResponseTimeout`, `PayloadOperationTimeout`
- `MaxRecoveryRetries`와 total recovery timeout
- `DataFreshnessLimit`
- battery low/critical threshold와 hysteresis
- slowdown/protective-stop debounce와 release hysteresis
- resume acknowledgement의 소유자와 유효 기간

## v1 구현 메모

- E-stop은 모든 상위 lifecycle 전이보다 높은 우선순위로
  `EmergencyStopLatched`에 진입한다.
- drive fault, recovery exhausted, communication loss, invalid localization,
  stale safety sensor는 서로 분리된 전이에서 `FaultReason`을 보존한다.
- Navigation recovery는 최대 2회로 제한되며 소진 시 `NavFailed`와
  `FaultLatched`로 승격한다.
- protective stop 해제에는 hazard clear뿐 아니라 명시적인 `resumeRequest`가 필요하다.
- loading/unloading 완료는 `loadComplete`와 `unloadComplete` handshake로 판정한다.
- timeout과 retry 값은 아직 모델 literal인 v1 기준값이다. 다음 단계에서
  `createSupervisorConfig`와 data dictionary를 단일 소스로 연결한다.
- request/response ID, 동시 fault 다중 원인 log, battery phase resume은 목표 표에는
  정의되어 있으나 v1에서는 아직 구현하지 않았다.
