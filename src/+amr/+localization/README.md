# localization

현재 prototype:

- `createPoseEkfConfig`: process/measurement covariance와 health threshold
- `predictPoseEkf`: differential-drive control 입력의 `[x,y,theta]` prediction
- `updatePoseEkf`: pose measurement correction과 covariance update
- `evaluateLocalizationHealth`: position/heading sigma 기반 정상·저하 판정

`verify_pose_ekf_uncertainty`는 measurement가 없는 장시간 prediction에서 covariance와 health가 악화되고, 반복 pose update 후 다시 정상으로 복귀하는지 검증한다. 아직 Scenario Plant의 실제 pose 대신 독립 prototype 입력을 사용한다.

예정 기능:

- wheel odometry
- odometry/IMU 측정과 현재 EKF 연결
- particle propagation
- likelihood-field measurement score
- systematic resampling
- EKF health를 Industrial Supervisor에 전달

관련 단계: [05_localization](../../../docs/stages/05_localization/05_localization.md)
