# 설계 결정 기록

프로젝트의 중요한 구조 변경을 날짜순으로 기록한다. 단순 파라미터 튜닝은 각 단계의 결과 문서에 기록한다.

## ADR-001: 유료 로봇 툴박스 없이 직접 구현

- 날짜: 2026-07-20
- 상태: 채택
- 결정: MATLAB, Simulink, Stateflow만 사용한다.
- 이유: 현재 환경에 ROS Toolbox와 Robotics System Toolbox가 없고 Windows 전용으로 운용한다.
- 결과: Nav2와 SLAM Toolbox는 구조와 알고리즘의 공개 참고자료로만 사용한다.

## ADR-002: 학습 단계와 실제 소스 분리

- 날짜: 2026-07-20
- 상태: 채택
- 결정: `stages/`에는 학습 문서, `src/·models/·tests/`에는 실제 구현물을 둔다.
- 이유: 단계별 폴더에 코드를 흩어 놓으면 최종 통합과 재사용이 어려워진다.

## ADR-003: mapping, localization, SLAM 분리

- 날짜: 2026-07-20
- 상태: 채택
- 결정: 알려진 자세 mapping, 고정 지도 localization, 동시 추정·지도 작성 SLAM을 별도 단계로 둔다.
- 이유: 세 문제의 입력, 출력, 실패 원인이 다르며 한꺼번에 구현하면 디버깅하기 어렵다.

## ADR-004: Pure Pursuit는 기준, DWA는 최종 지역 계획기

- 날짜: 2026-07-20
- 상태: 채택
- 결정: 장애물이 없는 기준 실험에는 Pure Pursuit를 사용하고, 최종 지역 주행은 DWA 계열 알고리즘을 사용한다.
- 이유: 두 알고리즘을 동시에 주 제어기로 사용하면 역할이 겹친다.

## ADR-005: 안전 명령은 마지막 독립 게이트에서 적용

- 날짜: 2026-07-20
- 상태: 채택
- 결정: 지역 플래너 출력 뒤에 별도의 safety monitor를 두고 최종 속도 명령을 제한하거나 0으로 만든다.
- 이유: 플래너 실패나 오래된 센서 데이터에도 정지할 수 있어야 한다.

## ADR-006: 복구 로직은 센서 구현 전에 deterministic scenario로 검증

- 날짜: 2026-07-21
- 상태: 채택
- 결정: 장애물, 저전압, 경로이탈 신호를 재현 가능한 시점과 위치에서 주입하고 Stateflow 복구 순서를 먼저 검증한다.
- 이유: 센서·mapping·planner를 동시에 도입하면 fault 원인과 복구 상태기계 오류를 분리하기 어렵다.
- 결과: Scenario Lab의 fault 신호는 현재 실제 센서 검출이 아니며, 다음 단계에서 하나씩 실제 알고리즘 출력으로 교체한다.

## ADR-007: Scenario Lab UI는 완료된 Simulink 로그를 재생

- 날짜: 2026-07-21
- 상태: 채택
- 결정: solver 실행을 먼저 완료하고 검증된 로그를 UI에서 독립적인 속도로 재생한다.
- 이유: 결과 재현, 시간 탐색, 고속/저속 관찰이 쉽고 UI rendering이 solver timing에 영향을 주지 않는다.
- 결과: online co-simulation 화면이 아니라 model execution 결과의 interactive playback이다.

## ADR-008: 시각 지도와 충돌 지도를 하나의 floor-map 정의에서 생성

- 날짜: 2026-07-21
- 상태: 채택
- 결정: UI가 그리는 벽/장애물 사각형을 occupancy grid로 rasterize하고 로봇 footprint와 여유 거리를 반영해 팽창한다.
- 이유: 시각화 전용 벽과 별도의 주행 waypoint를 사용하면 화면에서 벽을 통과해도 계산이 성공하는 심각한 불일치가 생긴다.
- 결과: 계획은 `0.40 m` 팽창 지도, 독립 안전 검사는 `0.30 m` 팽창 지도를 사용한다. 모든 기록 pose와 샘플 사이 선분도 다시 검증한다.

## ADR-009: 감독 제어는 계층 OR 상태와 병렬 AND 영역으로 분리

- 날짜: 2026-07-21
- 상태: 채택
- 결정: 상위 lifecycle은 배타적 OR 상태로, Operational 내부의 Mission/Navigation/Energy/Safety/Health는 병렬 AND 영역으로 구현한다.
- 이유: 임무 단계와 배터리·안전·건전성은 동시에 변할 수 있으므로 하나의 거대한 평면 상태기계로 표현하면 조합 상태와 전이 수가 폭증한다.
- 결과: Stateflow는 mode orchestration과 latch/reset을 담당하며 A*, 연속 제어, 충돌 수학은 MATLAB/Simulink 구성요소에 남긴다.

## ADR-010: 동적 장애물 이벤트와 검출을 분리

- 날짜: 2026-07-22
- 상태: 채택
- 결정: 장애물의 출현 시각만 scenario가 결정하고 `obstacleDetected`는 2D LiDAR scan과 protective-stop zone이 생성한다.
- 이유: 장애물 중심과 로봇 거리로 직접 fault를 만들면 센서 FOV, 가림, sample time과 검출 한계를 시험할 수 없다.
- 결과: Stateflow 장애물 전이 시각과 LiDAR stop 시각의 차이를 `0.11 s` 이하로 자동 검증한다.

## ADR-011: DWA는 센서 기반 local costmap에서만 명령을 선택

- 날짜: 2026-07-22
- 상태: 채택
- 결정: 정적 안전 지도에서 로봇 중심 창을 자르고, 정적 지도에 없는 LiDAR hit를 팽창해 local costmap을 만든다. DWA는 이 지도에서 rollout과 정지 궤적이 모두 안전한 후보만 선택한다.
- 이유: 전체 truth map을 DWA에 직접 주면 실제 센서 기반 지역 계획기의 관측 한계를 숨기게 된다.
- 결과: 장애물 회피 227개 샘플에서 선속도 step `0.06 m/s`, 각속도 step `0.20 rad/s` 제한과 비충돌을 확인했다.

## ADR-012: 주행 제어기와 실무형 Supervisor는 adapter 계약으로 통합

- 날짜: 2026-07-22
- 상태: 채택
- 결정: `amr_integrated_delivery_system.slx`에서 플랜트 신호를 Industrial Supervisor의 20개 조건 입력으로 변환한다.
- 이유: 수치 알고리즘과 상위 상태기계를 한 Chart에 합치지 않고 독립 검증 및 교체 가능성을 유지한다.
- 결과: 주행 4종에서 lifecycle, navigation, energy, safety 병렬 상태가 실제 플랜트 이벤트와 함께 검증된다.

## ADR-013: 하나의 엔진에서 세 가지 합성 실내환경을 교체

- 날짜: 2026-07-22
- 상태: 채택
- 결정: 사무실, 병원, 창고를 공통 floor-map 계약으로 정의하고 동일한 센서·계획·제어·Stateflow 체인으로 실행한다.
- 이유: 한 지도에 맞춘 waypoint나 회피 튜닝이 다른 복도 폭과 장애물 배치에서도 유효한지 확인해야 한다.
- 대안: 실제 시설 도면을 가져오는 방식은 출처·기밀·측량 정확도 문제가 있어 현재 범위에서 제외한다.
- 결과: 공개 가능한 자체 합성 지도 3개와 상황 4개 조합 12/12, 통합 모델 12/12를 검증했다.

## ADR-014: 센서 결함은 재현 가능한 pipeline에서 주입

- 날짜: 2026-07-22
- 상태: 채택
- 결정: 이상적 raycast 뒤에 deterministic range noise, beam dropout, periodic frame dropout, delay queue, freshness watchdog을 순서대로 적용한다.
- 이유: 회귀실험은 매번 같아야 하며, scan 생성과 통신/처리 지연을 분리해야 원인을 추적할 수 있다.
- 결과: frame dropout을 포함한 12개 주행 조합이 완료됐고, 연속 dropout으로 stale이 된 뒤 정상 frame에서 복귀하는 단위검사가 통과했다.

## ADR-015: Mapping과 Localization은 작은 검증 가능한 prototype부터 통합

- 날짜: 2026-07-22
- 상태: 채택
- 결정: log-odds inverse sensor update와 pose EKF covariance/health를 독립 함수로 먼저 검증하고, 다음 단계에서 주행 Plant와 Supervisor에 연결한다.
- 이유: mapping 오차, localization 오차, 제어 오차를 동시에 도입하면 실패 원인을 분리하기 어렵다.
- 결과: free/occupied/unknown map cell과 EKF uncertainty 증가·측정 복구가 각각 단위검사를 통과했다.

## 새 결정 작성 양식

```markdown
## ADR-NNN: 제목

- 날짜:
- 상태: 제안 / 채택 / 폐기
- 결정:
- 이유:
- 대안:
- 결과:
```
