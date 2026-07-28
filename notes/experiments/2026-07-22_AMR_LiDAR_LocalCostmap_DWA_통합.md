# AMR LiDAR, Local Costmap, DWA, Industrial Supervisor 통합

## 구현

- 270도 FOV, 91빔, 10 Hz 2D LiDAR
- DDA 단일 ray reference와 vectorized scan
- 전방 slowdown/protective-stop zone
- 정적 지도에 없는 LiDAR hit를 표시하는 `6 m × 6 m` local costmap
- dynamic window, trajectory rollout, braking admissibility, cost scoring
- `amr_integrated_delivery_system.slx`에서 Plant와 계층/병렬 Supervisor 연결

## 검증

- raycast 기대거리 `1.000 m` 일치
- local costmap novel obstacle marking PASS
- standalone DWA 80 step, 4400 valid candidate evaluations
- 주행 4/4: collision/LiDAR/DWA PASS
- 통합 4/4: lifecycle/navigation/energy/safety sequence PASS
- Scenario와 Integrated 모델 구조 검사 healthy

## 발견하고 수정한 문제

통합 초기 버전은 배송 완료 후 Industrial Mission이 다음 leg로 진행해 Navigation이 `Recovery → NavFailed`로 떨어졌다. 완료 신호를 `ControlledShutdown → PowerOff`로 연결하고 PowerOff에서 start request를 차단해 반복 재부팅도 제거했다. 충전 완료 조건은 state 번호가 아니라 `recoveryComplete && battery >= 89`로 변경했다.

## 남은 제한

- LiDAR noise/dropout/delay 및 timestamp watchdog 없음
- global A*의 동적 장애물은 아직 known rectangle 사용
- localization uncertainty와 log-odds mapping 미구현
- adapter는 typed bus가 아닌 scalar port
