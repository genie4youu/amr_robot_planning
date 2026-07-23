# 02. Robot Modeling

## 목적

차동구동 로봇의 운동학, 구동계 지연, 바퀴 속도 제한을 MATLAB과 Simulink로 구현한다.

## 진입 조건

- [01_math_frames_timing](../01_math_frames_timing/01_math_frames_timing.md) 완료

## 학습 및 작업 순서

1. [01_차동구동과_구동계_이론](01_차동구동과_구동계_이론.md)
2. [02_로봇플랜트_구현_및_검증](02_로봇플랜트_구현_및_검증.md)
3. [02_robot_modeling_진행결과](02_robot_modeling_진행결과.md)

## 결과물

- 차동구동 forward/inverse kinematics
- 자세 적분기
- 모터 1차 지연과 포화
- 좌우 바퀴 속도 제어
- ground-truth pose를 출력하는 prototype plant

## 완료 조건

- [ ] 직진, 제자리 회전, 원운동 결과가 수식과 일치한다.
- [ ] 좌우 바퀴 명령 포화가 반영된다.
- [ ] 가속도 제한과 motor lag가 관측된다.
- [ ] MATLAB 계산과 Simulink 결과가 허용 오차 안에서 일치한다.

## 다음 단계

[03_sensor_simulation](../03_sensor_simulation/03_sensor_simulation.md)
