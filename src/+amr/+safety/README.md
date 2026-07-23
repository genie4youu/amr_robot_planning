# safety

현재 구현:

- `scenarioEngineStep`의 최종 command gate가 다음 pose까지의 선분 충돌을 검사하고 위험하면 속도를 0으로 제한
- `assertCollisionFreePlayback`이 기록된 모든 pose와 샘플 사이 선분을 독립 재검사
- 동적 장애물 시나리오는 장애물 출현 이후의 지도까지 포함해 검증

다음 기능:

- stop/slowdown zone
- time-to-collision
- 센서와 제어 명령 watchdog
- localization health
- progress/stuck 판정
- 안전 명령 우선순위

관련 단계: [10_safety_recovery](../../../docs/stages/10_safety_recovery/10_safety_recovery.md)
