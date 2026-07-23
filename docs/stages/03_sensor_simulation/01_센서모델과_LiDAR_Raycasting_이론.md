# 센서 모델과 LiDAR Ray Casting 이론

## 엔코더

- 실제 바퀴 각도에서 pulse 또는 양자화된 각도를 생성한다.
- 좌우 scale error와 slip은 ground truth motion과 odometry를 다르게 만든다.
- 샘플 사이 wrap 또는 overflow 정책을 정의한다.

## IMU

초기에는 yaw-rate만 모델링한다.

```text
measuredYawRate = trueYawRate + bias + whiteNoise
```

bias를 고정값으로 시작하고 이후 random walk로 확장한다.

## 2D LiDAR

각 빔에 대해 다음을 계산한다.

1. lidar frame의 빔 각도 생성
2. base와 map frame으로 변환
3. 최대 거리까지 grid cell 순회
4. 첫 occupied cell까지 거리 반환
5. 미검출, 최대 거리, invalid 값을 구분

## Grid traversal 후보

- Bresenham 계열
- Digital Differential Analyzer
- Amanatides-Woo 방식의 cell traversal

첫 구현은 이해하기 쉬운 정수 grid traversal을 사용하고 성능은 이후 최적화한다.

## 반드시 모델링할 비이상성

- range noise
- angular resolution
- limited field of view
- minimum/maximum range
- measurement dropout
- update delay
- lidar mounting offset
