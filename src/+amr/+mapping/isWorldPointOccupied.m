function occupied = isWorldPointOccupied(gridMap, position)
%ISWORLDPOINTOCCUPIED Check inflated occupancy at a world coordinate.

[row, column, isInside] = amr.mapping.worldToGrid(gridMap, position);
if ~isInside
    occupied = true;
else
    occupied = gridMap.occupancy(row, column);
end
end
