# 10 단계 진행 및 결과

- 상태: 진행 중
- 시작일: 2026-07-21
- 완료일:

## Command priority

- 현재 개별 시나리오에서 장애물 정지, 저전압 복귀, 경로이탈 정지를 각각 검증
- Industrial Supervisor의 최상위 우선순위는 emergency stop, latched fault, controlled shutdown, operational condition 순이다.
- 복합 navigation/energy fault의 세부 arbitration은 다음 통합에서 명시한다.

## Stop/slowdown/TTC 설정

- LiDAR slowdown zone: 전방 `1.55 m`, 반폭 `0.55 m`
- LiDAR protective-stop zone: 전방 `0.85 m`, 반폭 `0.36 m`
- 장애물 출현 이후 slowdown → protective stop → A*/DWA 회피
- TTC는 아직 구현하지 않음

## Watchdog 설정

- scan timestamp와 현재 simulation time 차이를 freshness age로 계산
- freshness timeout `0.25 s`
- frame dropout 동안 hold-last를 사용하되 timeout을 넘으면 stale 판정
- stale scan은 planner와 독립적으로 최종 정지 조건에 포함
- 단위검사에서 stale 진입과 정상 frame 수신 후 복귀 PASS

## Progress checker 설정

- `goalReached`, `atCharger`, `recoveryComplete`로 progress를 판정
- wrong-turn 시 off-route event 이후 정지하고 reroute waypoint로 복귀

## Recovery 순서와 retry

- 장애물: 정지 → 우회 waypoint → 원 경로 재진입
- 배터리: 충전소 복귀 → 90% 충전 → 배송 재개
- 경로이탈: 정지 → 위치 확인 → 기준 경로 재진입
- retry counter와 최대 실패 횟수는 아직 없음

## Emergency latch/reset 결과

- emergency stop 입력으로 top-level `EmergencyStopLatched` 진입
- reset 조건에서 `Boot`를 다시 거쳐 `Operational` 복귀
- actuator fault는 `FaultLatched`에 남고 단순 fault 해제만으로 자동 복귀하지 않음

## 실패와 제한

- 동적 장애물의 출현은 deterministic injection이지만 검출은 실제 LiDAR scan 기반
- stop/slowdown zone과 별도로 최종 command segment collision gate 유지
- DWA rollout과 braking trajectory도 local costmap에서 비충돌 후보만 허용
- TTC와 retry counter는 아직 없음
- MATLAB Function의 시나리오 엔진은 desktop simulation-only 호출이며 코드 생성 대상이 아님

## 다음 작업 한 가지

TTC 기반 속도 제한과 recovery retry counter를 추가한다.
