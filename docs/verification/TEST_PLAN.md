# Single AMR Mission Supervisor 시험 계획

상태: **Draft**

## 목적

요구사항, Stateflow 전이, Plant 반응과 정량 KPI를 하나의 재현 가능한 회귀 흐름으로
검증한다. 현재 환경에는 Simulink Test가 없으므로 MATLAB scenario runner와 `assert`,
Simulation Data Inspector 또는 `logsout` 기반 판정을 사용한다.

## 시험 레벨

| 레벨 | 대상 | 방법 |
| --- | --- | --- |
| L1 계약 검사 | YAML, enum, bus, parameter | parser와 정적 assertion |
| L2 Supervisor 단독 | Stateflow chart + scripted feedback | 입력 timetable/구조체와 상태 log |
| L3 인터페이스 | request/response, freshness, reason code | adapter와 fault injector |
| L4 폐루프 시스템 | Supervisor + planner/controller + Plant | deterministic scenario simulation |
| L5 회귀 행렬 | 환경, seed, fault timing 조합 | batch runner와 expected summary 비교 |

처음 구현할 때는 L2의 정상 임무 수직 절편을 완성한 뒤 fault와 Plant를 한 가지씩 추가한다.

## 공통 관측 신호

- lifecycle, mission, navigation, energy, safety, health mode
- transition timestamp, transition ID, previous/next state와 reason code
- request ID와 response ID
- motion permit, speed limit mode와 authority source
- 후보 속도 명령과 Safety Arbiter 이후 최종 명령
- pose, goal error, collision flag와 minimum clearance
- battery SOC, charging 상태
- recovery attempt count, timeout flag와 terminal outcome count
- 각 입력의 validity와 data age

## 공통 합격 기준

- 충돌과 금지 상태 조합: `0회`
- E-stop, protective stop, critical drive fault 이후 motion authority 차단:
  다음 Supervisor execution step 이내
- latched fault의 자동 해제: `0회`
- 작업당 acceptance와 terminal outcome 중복: `0회`
- timeout 전이 시각: 설정된 timeout 경계의 한 execution step 이내
- recovery attempt count: `MaxRecoveryRetries`를 초과하지 않음
- debounce 확인 구간 안의 동일 원인 반복 전이: `0회`
- deterministic scenario: 같은 seed와 parameter에서 상태 순서와 판정이 동일
- 정상 deterministic 회귀: 모든 환경에서 완료, collision-free
- goal 완료: 프로젝트의 `GoalTolerance` 이내

수치 파라미터의 실제 값은 data dictionary 확정 후 이 문서와 요구사항 YAML에 이름과
해석값을 함께 기록한다.

## 핵심 시험 시나리오

| ID | 레벨 | 입력·고장 | 기대 결과 | 주요 KPI |
| --- | --- | --- | --- | --- |
| `TC_AMR_001` | L2 | 정상 power-on, initialize, self-test | PowerOff→Boot→Operational, Mission Idle | boot time, motion-before-ready |
| `TC_AMR_002` | L2 | self-test failure 및 Boot timeout 경계 | FaultLatched, 원인 보존 | timeout error, forbidden transition |
| `TC_AMR_003` | L4 | 정상 pickup–load–drop-off–unload–home | 정의된 순서, Completed 1회 | mission time, goal error, collision |
| `TC_AMR_004` | L2 | invalid job, 중복 request ID, active 중 새 job | 거부 사유, 기존 job 문맥 유지 | duplicate acceptance |
| `TC_AMR_005` | L3 | payload response ID 불일치, 실패, timeout, cancel | 잘못된 응답 무시, bounded abort | payload wait, outcome count |
| `TC_AMR_006` | L3 | planner response ID 불일치와 timeout | Recovery, planner reason | planning latency, stale response |
| `TC_AMR_007` | L4 | Tracking 중 path invalid | tracking revoke, Replanning, 새 ID | revoke latency, replan count |
| `TC_AMR_008` | L4 | stuck 후 첫 recovery 성공 | bounded recovery 후 mission 완료 | recovery time, attempt count |
| `TC_AMR_009` | L4 | recovery 반복 실패 | retry 한도 후 NavFailed와 mission 종결 | retry bound, failure latency |
| `TC_AMR_010` | L3 | slowdown 경계 주변 noise/chattering | debounce 후 Slowdown, 반복 전이 없음 | transition count, dwell time |
| `TC_AMR_011` | L4 | 동적 장애물 protective stop 후 제거 | 정지 유지, resume guard 뒤 재개 | stop latency, min clearance |
| `TC_AMR_012` | L3 | LiDAR·pose·navigation·command data stale | stale source 식별과 motion revoke | freshness latency, reason code |
| `TC_AMR_013` | L3 | localization 순간 glitch, 지속 degraded, invalid | 정책별 무시·제한·정지 | mode dwell, false stop |
| `TC_AMR_014` | L3 | wheel jam/actuator fault, 조기 reset, 정상 reset | FaultLatched 유지, guard 충족 후 Boot | rejected reset, latch duration |
| `TC_AMR_015` | L4 | Normal→Low→Critical→charger→complete | suspend/survival/charge, guarded resume | SOC margin, suspend count |
| `TC_AMR_016` | L4 | Tracking 중 E-stop과 잘못된 reset | 즉시 latch, motion revoke, Boot 경유 reset | stop latency, reset violations |
| `TC_AMR_017` | L3 | E-stop+critical battery+planner failure 동시 | E-stop 우선, 모든 원인 보존 | arbitration result, lost reasons |
| `TC_AMR_018` | L2 | shutdown request와 stop confirmation 지연 | 새 작업 차단, 확인 후 PowerOff | shutdown time, premature power-off |
| `TC_AMR_019` | L2 | 모든 timeout 직전·정확 경계·직후 응답 | 정의된 execution-step 판정 | boundary error |
| `TC_AMR_020` | L5 | 환경×seed×noise×fault timing 행렬 | 동일 seed 재현, 불변식 위반 없음 | success rate, chattering, collision |

## 요구사항·정적 검사

### YAML 검사

- YAML parser로 문법 확인
- `REQ_AMR_NNN`의 고유성과 순차성 확인
- 모든 `status: Draft`, `keywords`의 `draft` 확인
- `asil`, `priority` enum 확인
- `derived_from`가 같은 파일의 유효 ID이거나 `null`인지 확인

### Stateflow 구조 검사

- 모든 OR 영역의 default transition
- unreachable state와 dead-end state
- 동일 source의 모호한 transition
- parallel region의 output single-writer
- temporal logic 단위와 Supervisor sample time
- latch의 reset guard
- recovery retry와 total timeout의 유한성

## 실행 순서

1. `TC_AMR_001`과 `TC_AMR_003`의 scripted-feedback 수직 절편
2. request/response ID와 payload/planner timeout
3. path invalid, stuck와 recovery bound
4. slowdown, protective stop와 freshness watchdog
5. drive fault와 E-stop latch/reset
6. energy suspend, charging과 resume
7. 동시 fault 우선순위
8. 기존 A*/DWA/LiDAR/차동구동 Plant 연결
9. 환경·noise·fault timing 회귀 행렬

현재 v1 수직 절편의 반복 실행 진입점은 다음과 같다.

```matlab
verification = run_supervisor_verification();
```

이 runner는 제한된 요구사항 포맷 검사, `matlab.unittest` 인터페이스 시험 16개,
Stateflow 그래픽·라우팅 회귀 시험 11개와 scripted-plant 시나리오 9개를 순서대로
실행한다. Simulink Test가 없는 현재 환경의 공식 대체 회귀 경로다.

## 결과 보존

- 원시 로그: Git 제외 대상 `results/logs/`
- 자동 요약: `results/tables/`
- 검토용 그림: `results/figures/`
- 기준 데이터: 검토 후 `data/expected/`
- 해석과 한계: `docs/results/`

실행하지 않은 시험은 `PASS`로 기록하지 않는다. 기존 시나리오의 성공 결과와 새
Supervisor 요구사항의 검증 완료를 구분한다.
