# 03. Sensor Simulation

## 목적

ground truth로부터 엔코더, IMU, 2D LiDAR 측정을 만들고 noise, bias, dropout, delay를 모델링한다.

## 진입 조건

- [01_math_frames_timing](../01_math_frames_timing/01_math_frames_timing.md) 완료
- [02_robot_modeling](../02_robot_modeling/02_robot_modeling.md) 완료

## 학습 및 작업 순서

1. [01_센서모델과_LiDAR_Raycasting_이론](01_센서모델과_LiDAR_Raycasting_이론.md)
2. [02_가상센서_구현_및_검증](02_가상센서_구현_및_검증.md)
3. [03_sensor_simulation_진행결과](03_sensor_simulation_진행결과.md)

## 결과물

- wheel encoder measurement
- IMU yaw-rate measurement
- 2D LiDAR scan
- noise, bias, quantization, dropout 설정
- 센서별 timestamp와 valid 신호

## 완료 조건

- [ ] noise가 0일 때 기대값과 정확히 일치한다.
- [ ] encoder 양자화와 IMU bias가 관찰된다.
- [ ] LiDAR의 벽 거리와 장착 offset이 수동 계산과 일치한다.
- [ ] dropout과 stale-data 시나리오를 재현할 수 있다.

## 다음 단계

[04_mapping](../04_mapping/04_mapping.md)
