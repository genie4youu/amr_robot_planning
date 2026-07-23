# Mapping 구현 및 검증

## 구현 순서

1. map metadata 구조를 정의한다.
2. world 좌표와 grid index 변환을 작성한다.
3. 단일 ray의 cell 목록을 생성한다.
4. inverse sensor model을 작성한다.
5. log-odds update와 saturation을 작성한다.
6. scan 전체를 map에 누적한다.
7. 알려진 ground-truth 궤적으로 reference environment를 주행한다.
8. 생성 map을 확률, binary, unknown mask로 시각화한다.
9. reference map과 정량 비교한다.

## 예정 파일

```text
src/+amr/+mapping/worldToGrid.m
src/+amr/+mapping/gridToWorld.m
src/+amr/+mapping/probabilityToLogOdds.m
src/+amr/+mapping/logOddsToProbability.m
src/+amr/+mapping/updateOccupancyGrid.m
src/+amr/+verification/compareOccupancyMaps.m
tests/unit/verify_mapping_update.m
models/prototypes/amr_mapping_prototype.slx
```

## 검증 시나리오

- 한 개 수평 벽
- 사각형 방
- 내부 장애물
- 중복 관측
- map 경계 밖 beam
- 최대거리 beam
- 일부 scan dropout

## 통과 기준

- noise가 없는 작은 맵에서 모든 갱신 cell을 설명할 수 있다.
- log-odds가 설정 범위 밖으로 나가지 않는다.
- unknown을 free로 잘못 계산하지 않는다.
