function [range, hitPoint, hit] = raycastGrid( ...
        gridMap, origin, rayAngle, minimumRange, maximumRange)
%RAYCASTGRID Traverse a binary grid and return the first occupied-cell hit.
% The traversal is a two-dimensional DDA. Range is measured from origin.

arguments
    gridMap struct
    origin (1, 2) double
    rayAngle (1, 1) double
    minimumRange (1, 1) double {mustBeNonnegative} = 0.0
    maximumRange (1, 1) double {mustBePositive} = 10.0
end

assert(maximumRange >= minimumRange, "AMR:LidarRangeOrder", ...
    "maximumRange must be greater than or equal to minimumRange.");

direction = [cos(rayAngle), sin(rayAngle)];
startPoint = origin + minimumRange * direction;
[row, column, isInside] = amr.mapping.worldToGrid(gridMap, startPoint);
if ~isInside
    range = maximumRange;
    hitPoint = origin + maximumRange * direction;
    hit = false;
    return;
end

if gridMap.occupancy(row, column)
    range = minimumRange;
    hitPoint = startPoint;
    hit = true;
    return;
end

cellSize = 1 / gridMap.resolution;
[stepColumn, nextColumnDistance, columnDistanceIncrement] = ...
    axisTraversal(origin(1), direction(1), column, ...
    gridMap.bounds(1), cellSize);
[stepRow, nextRowDistance, rowDistanceIncrement] = ...
    axisTraversal(origin(2), direction(2), row, ...
    gridMap.bounds(3), cellSize);

rowCount = size(gridMap.occupancy, 1);
columnCount = size(gridMap.occupancy, 2);
while true
    if abs(nextColumnDistance - nextRowDistance) <= 1e-12
        travelledDistance = nextColumnDistance;
        column = column + stepColumn;
        row = row + stepRow;
        nextColumnDistance = nextColumnDistance + columnDistanceIncrement;
        nextRowDistance = nextRowDistance + rowDistanceIncrement;
    elseif nextColumnDistance < nextRowDistance
        travelledDistance = nextColumnDistance;
        column = column + stepColumn;
        nextColumnDistance = nextColumnDistance + columnDistanceIncrement;
    else
        travelledDistance = nextRowDistance;
        row = row + stepRow;
        nextRowDistance = nextRowDistance + rowDistanceIncrement;
    end

    if travelledDistance > maximumRange || row < 1 || row > rowCount || ...
            column < 1 || column > columnCount
        range = maximumRange;
        hitPoint = origin + maximumRange * direction;
        hit = false;
        return;
    end
    if travelledDistance + eps < minimumRange
        continue;
    end
    if gridMap.occupancy(row, column)
        range = max(minimumRange, travelledDistance);
        hitPoint = origin + range * direction;
        hit = true;
        return;
    end
end
end

function [step, nextDistance, distanceIncrement] = ...
        axisTraversal(originCoordinate, directionCoordinate, cellIndex, ...
        minimumCoordinate, cellSize)
if directionCoordinate > 1e-12
    step = 1;
    nextBoundary = minimumCoordinate + cellIndex * cellSize;
    nextDistance = (nextBoundary - originCoordinate) / directionCoordinate;
    distanceIncrement = cellSize / directionCoordinate;
elseif directionCoordinate < -1e-12
    step = -1;
    nextBoundary = minimumCoordinate + (cellIndex - 1) * cellSize;
    nextDistance = (nextBoundary - originCoordinate) / directionCoordinate;
    distanceIncrement = -cellSize / directionCoordinate;
else
    step = 0;
    nextDistance = inf;
    distanceIncrement = inf;
end
end
