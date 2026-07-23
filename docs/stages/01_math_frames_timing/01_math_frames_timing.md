# 01. Math, Frames, and Timing

## 목적

로봇의 모든 subsystem이 같은 좌표·각도·시간 규칙을 사용하도록 공통 수학 계층을 만든다.

## 진입 조건

- [00_project_setup](../00_project_setup/00_project_setup.md) 완료

## 학습 및 작업 순서

1. [01_SE2_좌표변환과_시간이론](01_SE2_좌표변환과_시간이론.md)
2. [02_공통수학_구현_및_검증](02_공통수학_구현_및_검증.md)
3. [01_math_frames_timing_진행결과](01_math_frames_timing_진행결과.md)

## 결과물

- 각도 정규화 함수
- SE(2) pose 합성·역변환
- map/odom/base/lidar frame 규칙
- world/grid 좌표 변환 기준
- subsystem sample-time 표
- 오래된 데이터 판정 규칙

## 완료 조건

- [ ] pose와 변환의 순서를 손으로 계산해 설명할 수 있다.
- [ ] 변환 후 역변환하면 원래 pose가 복원된다.
- [ ] `pi` 경계에서 각도 비교가 실패하지 않는다.
- [ ] multirate 데이터 전달 규칙을 문서화했다.

## 다음 단계

[02_robot_modeling](../02_robot_modeling/02_robot_modeling.md)
