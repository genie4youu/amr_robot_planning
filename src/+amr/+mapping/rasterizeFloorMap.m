function gridMap = rasterizeFloorMap(floorMap, resolution, inflationRadius, includeDynamicObstacle)
%RASTERIZEFLOORMAP Convert axis-aligned floor-map rectangles to occupancy.
%
% resolution is cells per metre. Rectangle inflation is conservative and
% uses the robot circumscribed radius on every rectangle side.

arguments
    floorMap struct
    resolution (1, 1) double {mustBePositive} = 10
    inflationRadius (1, 1) double {mustBeNonnegative} = 0.30
    includeDynamicObstacle (1, 1) logical = false
end

bounds = floorMap.bounds;
columnCount = ceil((bounds(2) - bounds(1)) * resolution);
rowCount = ceil((bounds(4) - bounds(3)) * resolution);
xCenters = bounds(1) + ((0:columnCount - 1) + 0.5) / resolution;
yCenters = bounds(3) + ((0:rowCount - 1) + 0.5) / resolution;
[xGrid, yGrid] = meshgrid(xCenters, yCenters);
occupancy = false(rowCount, columnCount);

rectangles = [floorMap.walls; floorMap.obstacles];
if includeDynamicObstacle && isfield(floorMap, "dynamicObstacle")
    rectangles = [rectangles; floorMap.dynamicObstacle];
end

for index = 1:size(rectangles, 1)
    rectangle = rectangles(index, :);
    xMinimum = rectangle(1) - inflationRadius;
    xMaximum = rectangle(1) + rectangle(3) + inflationRadius;
    yMinimum = rectangle(2) - inflationRadius;
    yMaximum = rectangle(2) + rectangle(4) + inflationRadius;
    occupancy = occupancy | ...
        (xGrid >= xMinimum & xGrid <= xMaximum & ...
        yGrid >= yMinimum & yGrid <= yMaximum);
end

gridMap = struct( ...
    "occupancy", occupancy, ...
    "resolution", resolution, ...
    "inflationRadius", inflationRadius, ...
    "bounds", bounds, ...
    "xCenters", xCenters, ...
    "yCenters", yCenters);
end
