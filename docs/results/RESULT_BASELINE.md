# Single AMR Mission Supervisor 결과 기준선

상태: **Draft — v1 Supervisor 수직 절편 검증 완료, 전체 요구사항 회귀는 진행 중**

이 문서는 기존 AMR 결과 중 재사용 가능한 증거와 새 Supervisor 기준선에서 아직
검증하지 않은 항목을 구분한다. 설계 문서 작성만으로 새 요구사항이 통과했다고 간주하지 않는다.

## 2026-07-24 실행 결과

대상은 `models/prototypes/amr_mission_supervisor.slx`이며, 기존 시스템 모델은
변경하지 않았다. 실행 환경은 MATLAB R2025b Update 5, fixed-step discrete
solver, Supervisor sample time `0.05 s`다.

| 검증 | 결과 | 증거 |
| --- | --- | --- |
| 새 MATLAB 아티팩트 Code Analyzer | 15개 파일, issue 0 | MATLAB `checkcode` |
| enum/config/telemetry 단위시험 | 16/16 PASS | `tests/unit/SupervisorInterfacesTest.m` |
| Supervisor scripted-plant 회귀 | 9/9 PASS | `scripts/run_amr_mission_supervisor_scenarios.m` |
| 모델 구조 검사 | healthy | unconnected port/line, Stateflow lint |
| 기존 알고리즘 회귀 | 8/8 PASS | `scripts/run_unit_verification.m` |
| 요구사항 ID·추적성 집합 | 37/37, 시험 ID 20/20 일치 | 제한된 포맷 정적 검사 |
| Stateflow 그래픽·라우팅 회귀 | 11/11 PASS | hard 0, exact 0, approximate warning 6 |

원시 결과는 Git에서 제외되는
`results/2026-07-24_mission_supervisor_v1_verification.mat`에 저장된다.

| 시나리오 | 판정 | 최종 lifecycle | 최종 fault | 최대 정지 응답 | recovery |
| --- | --- | --- | --- | ---: | ---: |
| nominal | PASS | Operational | None | `0 s` | 0 |
| protective_stop | PASS | Operational | None | `0 s` | 0 |
| recovery_success | PASS | Operational | None | `0 s` | 1 |
| recovery_exhausted | PASS | FaultLatched | RecoveryExhausted | `0 s` | 2 |
| emergency_stop | PASS | Operational | None | `0 s` | 0 |
| drive_fault | PASS | Operational | None | `0 s` | 0 |
| communication_loss | PASS | FaultLatched | CommunicationLost | `0 s` | 0 |
| battery_diversion | PASS | Operational | None | `0 s` | 0 |
| operator_cancel | PASS | Operational | None | `0 s` | 0 |

`drive_fault`와 `emergency_stop`은 시험 중 latch 상태와 원인 코드를 확인한 뒤
정상 reset guard를 거쳐 최종적으로 Operational에 복귀했기 때문에 최종 fault가
`None`이다.

## 재사용 가능한 기존 증거

기존 `docs/RESULTS.md`와 `data/expected/`에는 다음 결과가 기록되어 있다.

| 기존 자산 | 기록된 결과 | 새 기준선에서의 용도 |
| --- | --- | --- |
| 다중환경 Scenario Lab | 환경 3종×상황 4종 조합 완료 | Plant와 navigation 회귀 기준 |
| collision/LiDAR/DWA 검증 | 기존 12개 조합 PASS | safety invariant의 기초 비교 |
| goal error | 기존 결과 약 `0.080 m` 이하 | `GoalTolerance` 확정 전 참고 |
| Industrial Supervisor | nominal, obstacle, battery, health fault, E-stop 독립검사 PASS | lifecycle/병렬 영역의 시작점 |
| lifecycle 로그 | 기존 통합 조합에서 `[0 1 2 3 0]` | named enum 전환 전 비교 |

이 증거는 기존 모델과 시나리오에 대한 결과다. request/response ID, bounded retry,
typed bus, transition telemetry, 동시 fault 우선순위 등 새 요구사항을 검증하지는 않는다.

## 새 기준선 검증 상태

| 범주 | 상태 | 필요한 증거 |
| --- | --- | --- |
| YAML 요구사항 문법·ID | 제한된 포맷 검사 PASS, 범용 parser 미실행 | 로컬 YAML parser 부재 |
| lifecycle 상세 guard | 부분 PASS | `TC_AMR_001`, `016` 수직 절편 |
| mission handshake/outcome | 부분 PASS | 정상 handshake와 cancel, ID 계약은 미구현 |
| navigation timeout/recovery bound | 부분 PASS | recovery 성공·한도 초과 |
| slowdown debounce/chattering | 미실행 | `TC_AMR_010` |
| protective stop/resume | PASS | scripted-plant `protective_stop` |
| freshness watchdog | 부분 PASS | communication stale, 다른 source는 미실행 |
| degraded localization | 미실행 | `TC_AMR_013` |
| drive fault latch/reset | 부분 PASS | actuator fault와 guarded reset |
| battery suspend/charge/resume | 부분 PASS | energy mode sequence |
| E-stop latency/reset | PASS | latch, motion revoke, Boot 경유 reset |
| simultaneous fault arbitration | 미실행 | `TC_AMR_017` |
| 환경·seed·fault timing 행렬 | 미실행 | `TC_AMR_020` |

## 결과 표준 형식

각 실행은 다음 필드를 요약 구조체와 Markdown 표에 남긴다.

| 필드 | 의미 |
| --- | --- |
| `scenarioId` | `TC_AMR_NNN` |
| `modelRevision` | 대상 모델 식별 정보 |
| `parameterRevision` | data dictionary/parameter 기준 |
| `randomSeed` | 재현 seed |
| `pass` | 최종 판정 |
| `failedInvariant` | 위반한 불변식 |
| `missionOutcome` | Completed/Rejected/Cancelled/TimedOut/Failed |
| `missionTime` | 작업 종결 시간 |
| `minimumClearance` | 최소 장애물 여유 |
| `finalGoalError` | 최종 목표 오차 |
| `safetyReactionTime` | 위험 감지에서 motion revoke까지 |
| `transitionCount` | 전체 및 영역별 전이 횟수 |
| `stateDwellTimes` | 상태별 체류시간 |
| `recoveryAttempts` | 복구 시도 횟수 |
| `timeoutEvents` | timeout ID와 시각 |
| `reasonCodes` | 발생 원인 목록 |

## 기준선 승격 조건

1. 요구사항과 parameter 값이 검토되어 `Draft`에서 승격 후보가 된다.
2. 해당 요구사항의 시험이 구현되고 단독 실행에서 통과한다.
3. 기존 12개 navigation/Plant 회귀를 깨지 않는다.
4. 동시 fault와 boundary timing 시험이 통과한다.
5. 결과 MAT, 요약 표와 설계 해석이 서로 일치한다.
6. 알려진 한계와 미검증 범위를 결과 문서에 남긴다.

현재 v1 수직 절편은 통과했지만, 전체 기준선 승격 조건을 만족했다고 표시하지 않는다.
