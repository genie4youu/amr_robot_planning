# 11 단계 진행 및 결과

- 상태: 진행 중
- 시작일: 2026-07-20
- 완료일:

## 통합 모델 구조

- `amr_milestone01.slx`: Stateflow supervisor + 차동구동 플랜트 + 로그
- `simulate_amr_milestone01.m`: 모델 실행 결과를 공통 playback data 구조체로 변환
- `AmrMapPlaybackApp`: playback data를 실내 지도에서 애니메이션
- `amr_scenario_supervisor.slx`: Stateflow fault recovery와 동적 scenario engine 통합
- `AmrScenarioPlaybackApp`: 네 상황 선택, 배터리·경고·동적 장애물 표시
- `amr_industrial_supervisor.slx`: lifecycle과 5개 병렬 operational 영역의 감독 제어
- `amr_integrated_delivery_system.slx`: Scenario Plant와 Industrial Supervisor adapter 통합

## Parameter와 Bus

## Sample-time 표

## 초기화와 mode 전환

## 통합 순서별 결과

1. Stateflow가 `vCmd`, `wCmd`, `stateId` 생성
2. Simulink 차동구동 플랜트가 `x`, `y`, `theta`, 바퀴 속도 계산
3. UI가 30 fps 수준으로 pose를 보간해 로봇 차체와 상태 패널 갱신
4. Play/Pause/Reset, 시간 탐색, 0.25~4배속 제어 확인
5. floor-map을 occupancy grid로 변환하고 A* 및 독립 collision gate와 공유
6. LiDAR → local costmap → DWA → safety gate를 장애물 recovery에 연결
7. Plant event를 20개 Supervisor condition으로 변환하고 6개 병렬 mode 기록
8. scenario code `1..12`를 environment/scenario ID로 분리해 동일 모델로 사무실·병원·창고 실행

## 정상 배송 결과

- UI가 자동 재생되고 `초기화 → 직진 → 좌회전 → 직진 → 정지` 표시
- 6초 회전 구간에서 `(2.0, 0.0, 45 deg)` 시각화 확인
- 최종 목표 `(2.0, 2.0, 90 deg)` 도달

## 안전·복구 결과

- 정상 배송 26.35초 완료
- 돌발 장애물 34.40초 완료
- 배터리 부족 74.45초 완료, 최소 15.71%, 90% 충전 후 재개
- 잘못된 길 35.05초 완료
- 네 시나리오 모두 최종 위치 오차 0.077m 이하, `CollisionFree=true`
- Industrial Supervisor 다섯 시나리오 상태 순서 PASS
- 통합 4종 lifecycle `[0 1 2 3 0]`, NavFailed 없이 PASS
- 세 환경 전체 주행 12/12, 통합 Plant/Supervisor 12/12 PASS
- 결과: `results/2026-07-22_integrated_environment_matrix.mat`

## 알려진 제한

- UI는 online animation이 아니라 완료 로그 playback
- 장애물 출현 시각은 deterministic injection, 검출은 LiDAR 기반
- global replan은 아직 known dynamic rectangle을 사용
- typed bus/data dictionary 대신 scalar port adapter를 사용
- localization uncertainty는 독립 EKF prototype만 있고 adapter에는 아직 미연결
- log-odds map과 다중 sample-rate rate transition은 아직 Plant에 미연결

## 다음 작업 한 가지

Supervisor adapter를 typed bus로 바꾸고 sensor/control sample-time 경계에 Rate Transition을 추가한다.
