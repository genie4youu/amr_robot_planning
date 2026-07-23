# MATLAB 소스 구조

재사용 가능한 알고리즘은 `+amr` MATLAB package 아래에 둔다.

```text
+amr/
├─ +common/        공통 수학, 각도, 좌표 변환, 데이터 검사
├─ +modeling/      차동구동 및 구동계
├─ +sensors/       엔코더, IMU, LiDAR 모델
├─ +mapping/       ray casting, log-odds 점유 지도
├─ +localization/  odometry, EKF, MCL
├─ +slam/          scan matching, pose graph
├─ +planning/      costmap, A*, smoothing, DWA
├─ +control/       바퀴 제어, 속도 제한
├─ +safety/        충돌 감시, health, watchdog
└─ +verification/  지표와 비교 함수
```

## 작성 원칙

- 함수는 가능하면 Simulink와 무관한 입력·출력을 갖게 한다.
- MATLAB 단독 검증을 먼저 만든다.
- MATLAB Function 블록에서 사용할 함수는 지원 문법 범위를 확인한다.
- 전역 변수와 Base Workspace 의존성을 두지 않는다.
- 각 함수 헤더에 단위, 좌표계, 배열 크기, 출처 또는 직접 작성 여부를 기록한다.
