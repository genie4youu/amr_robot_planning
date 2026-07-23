# sensors

현재 구현:

- `createLidarConfig`: FOV/range/sample time/safety zone 설정
- `raycastGrid`: 정확한 DDA 단일 ray reference
- `simulateLidar2D`: 91빔 vectorized grid scan
- `evaluateLidarSafety`: rectangular slowdown/protective-stop zone
- `applyLidarImperfections`: 재현 가능한 range noise, beam dropout, frame dropout 적용
- `initializeLidarPipeline`, `stepLidarPipeline`: 1-sample delay, hold-last와 timestamp freshness watchdog

현재 Scenario Lab의 LiDAR는 `0.005 m` 표준편차 range noise, beam dropout probability `0.015`, 29 scan마다 frame dropout, 1 scan delay를 사용한다. 연속 frame 손실로 freshness timeout을 넘기면 safety stop 조건이 된다.

다음 기능:

- wheel encoder 양자화
- IMU yaw-rate와 bias
- 센서 extrinsic 적용
- 서로 다른 clock drift와 out-of-order timestamp

관련 단계: [03_sensor_simulation](../../../docs/stages/03_sensor_simulation/03_sensor_simulation.md)
