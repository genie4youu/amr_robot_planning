# 04. Occupancy-Grid Mapping

## 목적

정확한 robot pose가 주어진다는 조건에서 LiDAR 측정으로 확률 점유 격자를 작성한다. 이 단계는 SLAM이 아니라 mapping만 검증한다.

## 진입 조건

- [01_math_frames_timing](../01_math_frames_timing/01_math_frames_timing.md) 완료
- [03_sensor_simulation](../03_sensor_simulation/03_sensor_simulation.md) 완료

## 학습 및 작업 순서

1. [01_점유격자와_LogOdds_이론](01_점유격자와_LogOdds_이론.md)
2. [02_Mapping_구현_및_검증](02_Mapping_구현_및_검증.md)
3. [04_mapping_진행결과](04_mapping_진행결과.md)

## 결과물

- free/occupied/unknown map 표현
- inverse range sensor model
- log-odds 누적 업데이트
- ground-truth pose 기반 mapping prototype
- reference map과 생성 map 비교 지표

## 완료 조건

- [ ] 한 개 LiDAR ray의 free/occupied cell이 예상과 일치한다.
- [ ] 반복 관측에 따른 log-odds 누적과 포화가 정상이다.
- [ ] 미관측 영역이 unknown으로 유지된다.
- [ ] 알려진 pose 궤적으로 단순 실내 지도를 복원한다.

## 다음 단계

[05_localization](../05_localization/05_localization.md)
