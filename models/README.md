# Simulink 및 Stateflow 모델

```text
prototypes/  단계별 작은 실험 모델
system/      최종 통합 모델
libraries/   실제 재사용 필요가 확인된 라이브러리
```

현재는 모델을 생성하지 않는다. 각 단계에서 MATLAB 함수가 먼저 검증된 뒤 작은 prototype 모델을 만든다.

현재 최상위 통합 모델은 `models/system/amr_integrated_delivery_system.slx`다. 단계별 prototype과 검증된 system 모델을 분리해 관리한다.
