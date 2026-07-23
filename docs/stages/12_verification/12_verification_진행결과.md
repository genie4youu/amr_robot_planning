# 12 단계 진행 및 결과

- 상태: 상시
- 시작일: 2026-07-20
- 마지막 갱신일: 2026-07-22

## 현재 unit verification 목록

- differential-drive forward/inverse consistency
- grid/world 좌표 변환과 occupancy query
- A* 경로의 시작/끝 및 collision-free 선분
- playback pose와 샘플 사이 선분 collision assertion
- DDA ray 거리, no-hit maximum range, stop/slowdown zone
- novel LiDAR hit local-costmap marking/inflation
- DWA dynamic window, rollout collision, goal progress와 acceleration step
- 세 floor-map의 start-goal/charger A* 연결성과 동적 장애물 route 배치
- LiDAR noise/dropout/delay/freshness watchdog의 stale 및 recovery
- log-odds free/occupied/unknown inverse sensor update
- pose EKF covariance 증가, measurement correction과 health recovery

## 현재 scenario 목록

- Scenario Lab: normal, obstacle, battery, wrong_turn
- Industrial Supervisor: nominal, obstacle, battery, health_fault, e_stop
- Integrated Plant/Supervisor: normal, obstacle, battery, wrong_turn
- Environment matrix: office, hospital, warehouse × 위 네 주행 상황

## Pass/fail 기준

- 배송 목표 위치 오차 `< 0.12 m`
- 예상 Stateflow mode sequence 포함
- 완료 시간 내 목표 도달
- 모든 pose 및 샘플 사이 선분이 `0.30 m` 팽창 지도와 비충돌
- Stateflow supervisor의 lifecycle/parallel region 상태 순서 assert
- obstacle Stateflow event와 LiDAR stop event `<= 0.11 s` 정렬
- DWA 연속 명령의 linear/angular acceleration limit

## Baseline 결과

- 주행 환경 행렬 12/12 PASS, `CollisionFree/LidarValidated/DwaValidated=true`
- Industrial Supervisor 5/5 PASS
- Integrated Plant/Supervisor 환경 행렬 12/12 PASS
- Scenario/Industrial/Integrated Simulink 구조 검사 healthy
- 신규 알고리즘 단위검사 4/4 PASS

## Monte Carlo 결과

## Regression 실패

## 미검증 영역

- 실제 encoder/IMU bias와 localization 오차가 폐루프 주행에 미치는 영향
- log-odds map을 사용한 online global replan과 stale costmap
- 복합 fault 동시 발생과 우선순위 경계
- Monte Carlo, coverage, HIL 및 실시간 deadline
- Simulink Test 미설치로 기본 `assert` 기반 runner 사용

## 다음 작업 한 가지

EKF health와 online log-odds costmap을 Plant/Supervisor에 연결한 복합 fault 회귀검사를 추가한다.
