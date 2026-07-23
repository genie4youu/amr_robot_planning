# 05. Odometry and Localization

## 목적

엔코더·IMU로 연속 odometry를 만들고, 저장된 지도와 LiDAR를 사용해 전역 pose를 추정한다.

## 진입 조건

- [02_robot_modeling](../02_robot_modeling/02_robot_modeling.md) 완료
- [03_sensor_simulation](../03_sensor_simulation/03_sensor_simulation.md) 완료
- [04_mapping](../04_mapping/04_mapping.md) 완료

## 학습 및 작업 순서

1. [01_Odometry_EKF_MCL_이론](01_Odometry_EKF_MCL_이론.md)
2. [02_Localization_구현_및_검증](02_Localization_구현_및_검증.md)
3. [05_localization_진행결과](05_localization_진행결과.md)

## 결과물

- wheel odometry
- encoder/IMU EKF 또는 단계적 sensor fusion
- map 기반 particle localization
- estimated pose와 covariance
- localization health 판정

## 완료 조건

- [ ] ideal encoder에서 odometry가 ground truth와 일치한다.
- [ ] noise와 slip에서 drift가 재현된다.
- [ ] 저장된 지도에서 particle cloud가 실제 pose 부근으로 수렴한다.
- [ ] 위치 추정 실패와 불확실성 증가를 감지한다.
- [ ] 제어 입력은 ground truth가 아닌 estimated pose를 사용한다.

## 다음 단계

[06_slam](../06_slam/06_slam.md) 또는 [07_global_planning](../07_global_planning/07_global_planning.md)
