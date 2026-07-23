# 점유 격자와 Log-Odds 이론

## Cell 상태

각 cell은 단순한 장애물 여부가 아니라 점유 확률을 가진다.

- `p ≈ 0`: free
- `p ≈ 1`: occupied
- `p = 0.5`: unknown

## Log-odds

\[
l = \log\frac{p}{1-p}
\]

독립 측정 가정 아래에서 새 측정의 log-odds를 더하는 방식으로 누적한다. 초기 prior를 반영하고 값이 무한히 커지지 않도록 최소·최대 범위를 둔다.

## Inverse sensor model

LiDAR beam마다 다음 영역을 구분한다.

- 센서부터 반사점 전까지: free evidence
- 반사점 주변: occupied evidence
- 측정 최대 거리 밖: 갱신하지 않음
- invalid beam: 갱신하지 않음

## 구현 시 주의할 점

- grid resolution과 world origin
- row/column과 x/y 순서
- map boundary clipping
- 같은 scan에서 한 cell을 여러 번 갱신하는 정책
- maximum-range beam의 free-space 처리
- 센서 noise에 맞는 occupied 두께

## 학습 항목

- Bayesian update
- probability와 log-odds 변환
- ray tracing
- confusion matrix와 map IoU

## 공개 출처

- Alberto Elfes, “Using Occupancy Grids for Mobile Robot Perception and Navigation,” [DOI](https://doi.org/10.1109/2.30720)
- [Occupancy Grids](https://www.mathworks.com/help/nav/ug/occupancy-grids.html)
