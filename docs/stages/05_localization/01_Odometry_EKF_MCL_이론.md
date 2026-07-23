# Odometry, EKF, MCL 이론

## Wheel odometry

좌우 바퀴의 회전량으로 sample 사이의 이동 거리와 회전량을 계산한다. 연속성은 좋지만 바퀴 반경 오차와 slip이 누적된다.

## EKF 역할

초기 상태 후보:

```text
x = [x, y, theta, gyroBias]
```

단계적으로 구현한다.

1. encoder prediction만 수행
2. IMU yaw-rate로 heading 변화 보정
3. process/measurement covariance 반영
4. innovation이 비정상인 측정 거부

EKF 출력은 odom frame에서 연속 pose를 제공한다. 전역 map pose 보정과 역할을 섞지 않는다.

## Monte Carlo Localization

고정 지도에서 particle filter를 사용한다.

1. 초기 particle 생성
2. odometry motion model로 전파
3. LiDAR-map 일치도로 weight 계산
4. 정규화와 effective sample size 계산
5. 필요할 때 systematic resampling
6. weighted pose와 covariance 계산

## Measurement model

첫 구현은 단순 beam endpoint occupancy score를 사용할 수 있다. 이후 obstacle distance field를 만든 likelihood-field 방식으로 개선한다.

## 실패 조건

- 모든 weight가 0에 가까움
- particle이 여러 군집으로 분리됨
- covariance 임계 초과
- 추정 pose가 occupied cell에 위치
- 장시간 유효 update 없음

## 공개 출처

- [Monte Carlo Localization Algorithm](https://www.mathworks.com/help/nav/ug/monte-carlo-localization-algorithm.html)
- [Nav2 State Estimation Concepts](https://docs.nav2.org/concepts/index.html)
