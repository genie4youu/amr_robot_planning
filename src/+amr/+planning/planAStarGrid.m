function path = planAStarGrid(gridMap, startPosition, goalPosition)
%PLANASTARGRID Plan an eight-connected collision-free path on a grid.

[startRow, startColumn, startInside] = ...
    amr.mapping.worldToGrid(gridMap, startPosition);
[goalRow, goalColumn, goalInside] = ...
    amr.mapping.worldToGrid(gridMap, goalPosition);
assert(startInside && goalInside, "AMR:PlannerOutsideMap", ...
    "Start and goal must lie inside the map.");
assert(~gridMap.occupancy(startRow, startColumn), "AMR:PlannerStartOccupied", ...
    "The inflated start cell is occupied.");
assert(~gridMap.occupancy(goalRow, goalColumn), "AMR:PlannerGoalOccupied", ...
    "The inflated goal cell is occupied.");

[rowCount, columnCount] = size(gridMap.occupancy);
cellCount = rowCount * columnCount;
startIndex = sub2ind([rowCount, columnCount], startRow, startColumn);
goalIndex = sub2ind([rowCount, columnCount], goalRow, goalColumn);
gScore = inf(cellCount, 1);
fScore = inf(cellCount, 1);
cameFrom = zeros(cellCount, 1, "uint32");
openSet = false(cellCount, 1);
closedSet = false(cellCount, 1);
gScore(startIndex) = 0;
fScore(startIndex) = hypot(goalRow - startRow, goalColumn - startColumn);
openSet(startIndex) = true;

neighborOffsets = [-1, -1; -1, 0; -1, 1; 0, -1; ...
    0, 1; 1, -1; 1, 0; 1, 1];

while any(openSet)
    candidates = find(openSet);
    [~, candidateOffset] = min(fScore(candidates));
    currentIndex = candidates(candidateOffset);
    if currentIndex == goalIndex
        path = reconstructPath(gridMap, cameFrom, currentIndex, startPosition, goalPosition);
        return;
    end

    openSet(currentIndex) = false;
    closedSet(currentIndex) = true;
    [currentRow, currentColumn] = ind2sub([rowCount, columnCount], currentIndex);

    for neighborNumber = 1:size(neighborOffsets, 1)
        rowOffset = neighborOffsets(neighborNumber, 1);
        columnOffset = neighborOffsets(neighborNumber, 2);
        neighborRow = currentRow + rowOffset;
        neighborColumn = currentColumn + columnOffset;
        if neighborRow < 1 || neighborRow > rowCount || ...
                neighborColumn < 1 || neighborColumn > columnCount
            continue;
        end
        if gridMap.occupancy(neighborRow, neighborColumn)
            continue;
        end
        if rowOffset ~= 0 && columnOffset ~= 0 && ...
                (gridMap.occupancy(currentRow + rowOffset, currentColumn) || ...
                gridMap.occupancy(currentRow, currentColumn + columnOffset))
            continue;
        end

        neighborIndex = sub2ind([rowCount, columnCount], neighborRow, neighborColumn);
        if closedSet(neighborIndex)
            continue;
        end
        stepCost = hypot(rowOffset, columnOffset);
        tentativeScore = gScore(currentIndex) + stepCost;
        if tentativeScore < gScore(neighborIndex)
            cameFrom(neighborIndex) = uint32(currentIndex);
            gScore(neighborIndex) = tentativeScore;
            heuristic = hypot(goalRow - neighborRow, goalColumn - neighborColumn);
            fScore(neighborIndex) = tentativeScore + heuristic;
            openSet(neighborIndex) = true;
        end
    end
end

error("AMR:PlannerNoPath", "A* could not find a collision-free path.");
end

function path = reconstructPath(gridMap, cameFrom, currentIndex, startPosition, goalPosition)
indices = currentIndex;
while cameFrom(currentIndex) ~= 0
    currentIndex = double(cameFrom(currentIndex));
    indices(end + 1) = currentIndex; %#ok<AGROW>
end
indices = fliplr(indices);
path = zeros(numel(indices), 2);
for index = 1:numel(indices)
    [row, column] = ind2sub(size(gridMap.occupancy), indices(index));
    path(index, :) = amr.mapping.gridToWorld(gridMap, row, column);
end
path(1, :) = startPosition;
path(end, :) = goalPosition;
end
