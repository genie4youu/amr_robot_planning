# 05 단계 진행 및 결과

- 상태: 진행 중
- 시작일: 2026-07-22
- 완료일:

## Odometry 설정과 drift

## EKF 상태와 noise covariance

- 상태 평균: `[x, y, theta]`
- 입력: body linear/angular velocity와 prediction sample time
- covariance: Jacobian 기반 prediction, pose measurement correction
- angle innovation은 `[-pi, pi]`로 정규화

## MCL particle 및 sensor 설정

## 수렴 결과와 지표

- 600회 prediction 동안 covariance trace 증가 확인
- position sigma가 `0.08 m` threshold를 넘어 health degraded 확인
- 반복 pose update 뒤 covariance 감소와 health 정상 복귀 PASS

## 실패 시나리오

- measurement 장기 미수신을 uncertainty 증가로 표현
- 아직 실제 wheel slip, IMU bias, kidnapped robot은 미검증

## Localization health 규칙

- maximum position sigma와 maximum heading sigma를 독립 비교
- 결과 구조체에 `healthy`, `positionSigma`, `headingSigma` 제공
- 아직 Industrial Supervisor Health 영역에는 연결하지 않음

## 생성한 함수와 검증

- `src/+amr/+localization/createPoseEkfConfig.m`
- `src/+amr/+localization/predictPoseEkf.m`
- `src/+amr/+localization/updatePoseEkf.m`
- `src/+amr/+localization/evaluateLocalizationHealth.m`
- `tests/unit/verify_pose_ekf_uncertainty.m`

## 다음 작업 한 가지

차동구동 odometry와 IMU yaw-rate를 생성해 EKF와 Scenario Plant에 연결한다.
