# 03 단계 진행 및 결과

- 상태: 진행 중
- 시작일: 2026-07-22
- 완료일:

## 센서 파라미터

- FOV: `-135 deg` ~ `+135 deg`
- 각해상도: `3 deg`, 91 beams
- range: `0.10 ~ 5.00 m`
- sample time: `0.10 s`
- mounting offset: base 중심에서 전방 `0.18 m`

## 지도와 좌표계

- world pose `[x,y,theta]`에서 lidar origin과 beam heading 계산
- raw occupancy grid `20 cells/m`, inflation 없이 물리 표면 raycast
- UI와 sensor가 동일한 floor-map rectangle 정의 사용

## 생성한 함수와 모델

- `src/+amr/+sensors/createLidarConfig.m`
- `src/+amr/+sensors/raycastGrid.m`: DDA 단일 ray reference
- `src/+amr/+sensors/simulateLidar2D.m`: vectorized multi-beam scan
- `src/+amr/+sensors/evaluateLidarSafety.m`
- `src/+amr/+sensors/applyLidarImperfections.m`
- `src/+amr/+sensors/initializeLidarPipeline.m`
- `src/+amr/+sensors/stepLidarPipeline.m`
- `tests/unit/verify_grid_raycast.m`
- `tests/unit/verify_lidar_pipeline.m`

## ideal 측정 결과

- 수직 벽 기대거리 `1.000 m`, 계산거리 `1.000 m`
- 최대거리 내 미검출은 hit=false와 maximum range 반환
- 전방 장애물 safety range `0.651 m`, slowdown/stop 동시 검출 PASS
- Stateflow obstacle event와 LiDAR stop event time 정렬 PASS

## noise/bias/dropout 결과

- range noise standard deviation `0.005 m`
- beam dropout probability `0.015`
- 29 scan마다 deterministic frame dropout
- 1-sample delay queue와 hold-last 처리
- timestamp freshness timeout `0.25 s`; stale이면 독립 safety stop
- 단위검사에서 정상 scan → dropout 연속 → stale → 정상 frame 복귀 순서 PASS

## 성능과 제한

- 단일 ray는 정확한 grid DDA, 다중 scan은 cell 누락을 막는 `0.45 cell` 간격 vectorized traversal 사용
- noise/dropout은 재현 가능한 deterministic pattern이라 회귀검사 결과가 반복 가능
- encoder/IMU, clock drift, out-of-order timestamp는 아직 없음

## 다음 작업 한 가지

wheel encoder 양자화와 IMU bias/random-walk 모델을 추가한다.
