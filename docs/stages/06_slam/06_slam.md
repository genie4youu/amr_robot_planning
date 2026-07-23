# 06. Incremental and Graph-Based SLAM

## 목적

odometry와 LiDAR로 pose를 보정하며 지도를 동시에 작성하고, 재방문 제약으로 누적 오차를 줄이는 SLAM을 단계적으로 구현한다.

## 진입 조건

- [04_mapping](../04_mapping/04_mapping.md) 완료
- [05_localization](../05_localization/05_localization.md)의 odometry와 measurement score 검증 완료

## 학습 및 작업 순서

1. [01_ScanMatching_LoopClosure_PoseGraph_이론](01_ScanMatching_LoopClosure_PoseGraph_이론.md)
2. [02_SLAM_단계별_구현_및_검증](02_SLAM_단계별_구현_및_검증.md)
3. [06_slam_진행결과](06_slam_진행결과.md)

## 세부 milestone

1. scan-to-map correlative matching
2. incremental pose correction과 mapping
3. key scan과 submap
4. loop closure 후보 및 검증
5. SE(2) pose graph 최적화
6. 최적 pose로 지도 재생성

## 완료 조건

- [ ] 작은 탐색 범위에서 scan matching의 최적 pose를 찾는다.
- [ ] odometry-only보다 incremental SLAM drift가 작다.
- [ ] 잘못된 loop closure를 제한하는 검증 규칙이 있다.
- [ ] 작은 pose graph의 residual이 최적화 후 감소한다.
- [ ] loop closure 전후의 trajectory와 map을 비교한다.

## 다음 단계

[07_global_planning](../07_global_planning/07_global_planning.md)
