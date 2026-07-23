function localMap = buildLocalCostmapFromLidar( ...
        staticSafetyMap, staticSensorMap, scan, robotPosition, ...
        windowSize, markingInflationRadius)
%BUILDLOCALCOSTMAPFROMLIDAR Fuse novel lidar hits into a static local map.

arguments
    staticSafetyMap struct
    staticSensorMap struct
    scan struct
    robotPosition (1, 2) double
    windowSize (1, 2) double {mustBePositive} = [6, 6]
    markingInflationRadius (1, 1) double {mustBeNonnegative} = 0.30
end

localMap = amr.planning.extractLocalCostmap( ...
    staticSafetyMap, robotPosition, windowSize);
[xGrid, yGrid] = meshgrid(localMap.xCenters, localMap.yCenters);
hitIndices = find(scan.hitMask);
for hitNumber = 1:numel(hitIndices)
    hitPoint = scan.hitPoints(hitIndices(hitNumber), :);
    if hitPoint(1) < localMap.bounds(1) || hitPoint(1) > localMap.bounds(2) || ...
            hitPoint(2) < localMap.bounds(3) || hitPoint(2) > localMap.bounds(4)
        continue;
    end
    if amr.mapping.isWorldPointOccupied(staticSensorMap, hitPoint)
        continue;
    end
    localMap.occupancy = localMap.occupancy | ...
        hypot(xGrid - hitPoint(1), yGrid - hitPoint(2)) <= ...
        markingInflationRadius;
end
end
