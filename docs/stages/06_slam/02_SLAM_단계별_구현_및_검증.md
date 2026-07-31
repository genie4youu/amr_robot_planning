# SLAM 단계별 구현 및 검증

## A. Scan matching

1. reference map에서 distance 또는 occupancy score를 준비한다.
2. known pose scan으로 score 최대점이 참 pose인지 확인한다.
3. odometry prior에 offset을 주고 후보 탐색으로 복구한다.
4. coarse-to-fine 탐색을 추가한다.
5. 최고점과 차선점의 score 차이로 품질을 계산한다.

## B. Incremental SLAM

1. odometry pose 예측
2. scan matching 보정
3. 보정 pose로 occupancy update
4. matching 실패 시 map update 중지
5. trajectory와 map 기록

## C. Loop closure와 graph

1. key scan 선택
2. 연속 pose edge 작성
3. 작은 synthetic graph에서 residual/Jacobian 검증
4. loop edge 추가 전후 최적화 비교
5. 실제 simulated scan에 후보 검색 적용
6. 최적화된 모든 pose로 map 재생성

## 예정 파일

```text
src/+amr/+slam/correlativeScanMatch.m
src/+amr/+slam/selectKeyScan.m
src/+amr/+slam/findLoopCandidates.m
src/+amr/+slam/verifyLoopClosure.m
src/+amr/+slam/poseGraphResidualSE2.m
src/+amr/+slam/optimizePoseGraph.m
src/+amr/+slam/rebuildMapFromScans.m
tests/unit/verify_scan_matching.m
tests/unit/verify_pose_graph.m
models/examples/amr_slam_prototype.slx
```

## 검증 시나리오

- L자 벽에서 작은 pose offset
- 긴 직선 복도
- 사각형 loop
- 잘못된 loop 후보
- 한 개 outlier edge
- 다양한 map resolution

## 단계 분리 원칙

scan matching이 통과하지 않으면 loop closure를 구현하지 않는다. synthetic pose graph가 통과하지 않으면 실제 scan graph에 적용하지 않는다.
