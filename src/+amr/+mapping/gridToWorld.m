function position = gridToWorld(gridMap, row, column)
%GRIDTOWORLD Return the world coordinate at a grid-cell centre.

position = [gridMap.xCenters(column), gridMap.yCenters(row)];
end
