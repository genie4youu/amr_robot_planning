# Single AMR Mission Supervisor 시스템 컨텍스트

상태: **Draft**

이 문서는 기존 AMR 내비게이션 자산을 포트폴리오 프로젝트
`Single AMR Mission Supervisor`로 발전시키기 위한 목표 구조를 정의한다.
`amr_mission_supervisor.slx`에는 Stateflow Supervisor, scripted Plant 입력 경계와
독립 motion-permit arbiter까지의 수직 절편을 구현했다. 아래 그림 전체, 특히 실제
planner/controller/payload/Plant 폐루프가 모두 통합됐다는 의미는 아니다.

## 시스템 목적

AMR Mission Supervisor는 배송 작업을 안전하게 시작·진행·중단·복구·종료하기 위한
이산 의사결정을 담당한다. 경로 계산, 연속 제어, 센서 수치 처리와 로봇 동역학은
Stateflow 밖의 MATLAB/Simulink 구성요소가 담당한다.

```text
Operator / Fleet Command
            │
            ▼
  Scenario & Fault Injector
            │
            ▼
 Plant · Navigation · Health Status
            │
            ▼
┌──────────────────────────────────┐
│ Stateflow AMR Mission Supervisor │
│ lifecycle / mission / navigation │
│ energy / safety / health         │
└──────────────────────────────────┘
            │ intent · mode · request
            ▼
 Planner · Controller · Payload Handler
            │ candidate command
            ▼
 Independent Safety Command Arbiter
            │ final wheel command
            ▼
 Differential-Drive Plant
            │
            ▼
 Telemetry · KPI · Regression Evaluation
```

## 시스템 경계

### Supervisor 내부 책임

- power-on, boot, operational, shutdown, fault와 emergency-stop lifecycle
- 배송 작업 수락, 검증, 순서 진행, 취소와 종결
- navigation planning, tracking, replanning, recovery mode 선택
- battery low/critical/charging에 따른 임무 정책
- slowdown, protective stop과 motion authority 결정
- health degradation, stale data, fault latch와 reset guard
- reason code, terminal outcome과 상태 telemetry 출력

### Supervisor 외부 책임

| 구성요소 | 책임 |
| --- | --- |
| Global planner | occupancy grid 기반 경로 탐색과 smoothing |
| Local planner/controller | LiDAR/local costmap/DWA와 연속 속도 명령 계산 |
| Localization | pose 추정, covariance와 유효성 평가 |
| Safety monitor | safety zone, TTC, freshness와 정지 조건 계산 |
| Safety command arbiter | 후보 명령에 독립적인 최종 stop/limit 적용 |
| Payload handler | loading/unloading 장비의 실제 동작과 완료 응답 |
| Energy plant | SOC와 충전 상태의 연속 동역학 |
| Robot plant | 차동구동 기구학과 pose 적분 |
| Scenario injector | 시험 입력, 통신 손실과 고장 주입 |
| Verification logger | 상태, 전이, 명령, KPI 수집과 판정 |

## 외부 행위자

| 행위자 | Supervisor에 제공 | Supervisor로부터 수신 |
| --- | --- | --- |
| Operator/Fleet | 전원, 작업, 취소, reset, acknowledgement | 수락·거부·완료·실패와 진단 |
| Navigation stack | 계획·추종·도착·진행·경로 상태 | goal, plan, track, replan, recovery 요청 |
| Payload equipment | payload 존재, 작업 응답과 fault | loading/unloading 요청 |
| Safety system | E-stop, slowdown, stop, hazard-clear | motion authority와 현재 mode |
| Health monitors | sensor, localization, drive, 통신 건전성 | degraded/fault 진단 |
| Charger | charger 도착, 접속, charge-complete | 충전 목표와 charging 요청 |

## 상태 우선 의사결정

상충된 입력은 다음 순서로 평가한다.

```text
Emergency stop
> Latched drive or health fault
> Protective stop
> Energy survival action
> Navigation recovery
> Operator cancel or hold
> Normal mission progression
```

Safety command arbiter는 Supervisor의 결정과 별개로 최종 명령을 다시 제한할 수 있다.
Supervisor 오류가 곧바로 위험한 wheel command가 되지 않도록 이 방어선을 유지한다.

## 가정

- Supervisor는 고정 주기로 실행되고 입력 bus는 실행 주기마다 snapshot으로 제공된다.
- 비동기 요청은 `requestId`와 응답의 `responseId`로 대응한다.
- 외부 status에는 `valid`, `timestamp` 또는 `dataAge`가 포함된다.
- 모든 임계값과 timeout은 추후 data dictionary에서 명명된 파라미터로 관리한다.
- 본 프로젝트의 `asil: Unset`은 공식 안전 분석이 아직 수행되지 않았음을 뜻한다.

## 비목표

- 기능 안전 인증 또는 양산 ECU 사양 확정
- Stateflow 내부에서 A*, DWA, IK 또는 연속 제어식 구현
- 다중 AMR 배차와 교차로 중재
- 실제 무선 네트워크와 하드웨어 드라이버 구현

## 관련 기준선

- 요구사항: `../../requirements/amr_mission_supervisor_requirements.yaml`
- 인터페이스: `INTERFACES.md`
- 상태 구조: `STATE_HIERARCHY.md`
- 전이와 우선순위: `TRANSITION_TABLE.md`
- 시험 계획: `../verification/TEST_PLAN.md`
- 추적성: `../verification/TRACEABILITY.md`
