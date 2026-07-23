function [row, column, isInside] = worldToGrid(gridMap, position)
%WORLDTOGRID Convert [x,y] world coordinates to one-based grid indices.

column = floor((position(1) - gridMap.bounds(1)) * gridMap.resolution) + 1;
row = floor((position(2) - gridMap.bounds(3)) * gridMap.resolution) + 1;
isInside = row >= 1 && row <= size(gridMap.occupancy, 1) && ...
    column >= 1 && column <= size(gridMap.occupancy, 2);
end
