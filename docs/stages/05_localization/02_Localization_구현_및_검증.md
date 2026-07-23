# Localization 구현 및 검증

## 구현 순서

### A. Odometry

1. encoder delta에서 body displacement를 계산한다.
2. odom pose를 적분한다.
3. wheel scale error와 slip에서 drift를 측정한다.

### B. EKF

1. 상태와 covariance 초기화
2. nonlinear prediction과 Jacobian
3. IMU measurement update
4. angle innovation 정규화
5. covariance 대칭성과 양의 대각 성분 확인

### C. MCL

1. 고정 지도와 initial-pose 주변 particle 생성
2. noisy motion model
3. LiDAR endpoint score
4. log-weight 또는 underflow 방지
5. systematic resampling
6. 전역 초기화와 잘못된 초기 위치 실험

## 예정 파일

```text
src/+amr/+localization/updateWheelOdometry.m
src/+amr/+localization/predictOdometryEKF.m
src/+amr/+localization/updateYawRateEKF.m
src/+amr/+localization/propagateParticles.m
src/+amr/+localization/scoreParticleScan.m
src/+amr/+localization/systematicResample.m
src/+amr/+localization/estimateParticlePose.m
tests/unit/verify_odometry.m
tests/unit/verify_localization.m
models/prototypes/amr_localization_prototype.slx
```

## 검증 시나리오

- noise 없는 직진과 회전
- 좌우 wheel scale 불일치
- IMU bias
- 좋은 초기 pose
- 잘못된 초기 pose
- 대칭적인 복도
- LiDAR 일부 dropout
- kidnapped pose 재초기화

## 지표

- position/heading RMSE
- distance-normalized drift
- particle effective sample size
- covariance와 실제 오차의 관계
- 수렴 시간과 실패율
