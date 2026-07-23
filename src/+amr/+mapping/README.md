# mapping

현재 구현:

- `rasterizeFloorMap`: UI floor-map의 벽/장애물을 occupancy grid로 변환하고 footprint 여유 반경만큼 팽창
- `worldToGrid`, `gridToWorld`: world/grid 좌표 변환
- `isWorldPointOccupied`: world point 점유 확인
- `isSegmentCollisionFree`: 샘플 사이 연속 선분의 점유 교차 확인
- `initializeLogOddsMap`: unknown 상태에서 시작하는 log-odds map 생성
- `updateLogOddsWithScan`: inverse range sensor model로 ray의 free cell과 hit cell 누적
- `logOddsToOccupancy`: free/occupied/unknown 3상태 grid 변환

`verify_log_odds_mapping`은 반복 scan 뒤 ray 전방은 free, 벽 hit cell은 occupied, 벽 뒤 미관측 영역은 unknown으로 남는지 검증한다.

다음 기능:

- 지도 저장과 시각화
- Scenario Plant의 online local/global costmap과 연결

관련 단계: [04_mapping](../../../docs/stages/04_mapping/04_mapping.md)
