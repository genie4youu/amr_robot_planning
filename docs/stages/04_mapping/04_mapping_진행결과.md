# 04 단계 진행 및 결과

- 상태: 진행 중
- 시작일: 2026-07-21
- 완료일:

## Map metadata

- world bounds: floor-map의 `xLim`, `yLim`
- 해상도: `10 cells/m`
- UI 벽과 장애물 사각형을 동일한 정의에서 rasterize
- 계획 지도 팽창 반경 `0.40 m`, 안전 검증 지도 `0.30 m`

## Log-odds 파라미터

- map 초기값: log-odds `0` (unknown probability 0.5)
- free/occupied evidence와 saturation limit을 map 구조체에 보관
- maximum range beam은 free cell만 갱신하고, 실제 hit beam만 endpoint를 occupied로 갱신

## 생성한 함수와 모델

- `src/+amr/+mapping/rasterizeFloorMap.m`
- `src/+amr/+mapping/worldToGrid.m`
- `src/+amr/+mapping/gridToWorld.m`
- `src/+amr/+mapping/isWorldPointOccupied.m`
- `src/+amr/+mapping/isSegmentCollisionFree.m`
- `src/+amr/+mapping/initializeLogOddsMap.m`
- `src/+amr/+mapping/updateLogOddsWithScan.m`
- `src/+amr/+mapping/logOddsToOccupancy.m`
- `tests/unit/verify_log_odds_mapping.m`

## 단일 ray 검증

- 반복 scan 뒤 sensor와 wall 사이 cell은 free
- wall hit cell은 occupied
- wall 뒤 가려진 cell은 unknown 유지
- free/occupied/unknown 판정 PASS

## 전체 지도 결과와 지표

## 실패와 제한

- log-odds 함수는 구현됐지만 현재 주행 global map은 여전히 known static map이다.
- 동적 장애물 global A* replan은 시나리오 사각형을 알고 있으며, local DWA만 LiDAR hit를 사용한다.
- map decay, rolling submap, loop-closure correction은 아직 없음.

## 다음 작업 한 가지

log-odds map을 Scenario Plant의 주행 중 local/global costmap 입력으로 연결한다.
