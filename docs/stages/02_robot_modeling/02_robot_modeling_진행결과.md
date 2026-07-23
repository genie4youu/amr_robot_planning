# 02 단계 진행 및 결과

- 상태: 진행 중
- 시작일: 2026-07-20
- 완료일:

## 로봇 파라미터

- 바퀴 반지름: `0.05 m`
- 윤거(track width): `0.30 m`
- 플랜트 sample time: `0.01 s`

## 모델 가정

- 평면 강체, 비홀로노믹 차동구동 로봇
- 바퀴 미끄럼, 모터 동특성, 구동 지연은 아직 없음
- Stateflow가 내보낸 차체 속도 `v`, `omega`를 이상적으로 추종

## 생성한 함수와 모델

- `amr.modeling.differentialDriveForward`
- `amr.modeling.differentialDriveInverse`
- `amr.modeling.integrateDifferentialDrive`
- `models/prototypes/amr_milestone01.slx/DifferentialDrivePlant`

## 직진·회전·원운동 결과

- MATLAB 단위 검증에서 순·역변환과 자세 적분 PASS
- Simulink에서 4초 직진, 2초 제자리 좌회전, 4초 직진 수행
- 시작 `[0, 0, 0]`, 종료 `[2, 2, pi/2]`

## 포화와 지연 결과

- 아직 구현하지 않음

## 알려진 제한

- open-loop 속도 명령이므로 위치 오차에 대한 피드백이 없음
- 모터/센서 오차가 없어 수치상 최종 오차가 0임
- 다음 모델부터 가속도·속도 포화와 자세 피드백을 추가해야 함

## 다음 작업 한 가지

목표 pose와 현재 pose의 오차로 `v`, `omega`를 계산하는 waypoint 추종기를 구현한다.
