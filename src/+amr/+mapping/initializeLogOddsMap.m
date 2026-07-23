function map = initializeLogOddsMap(bounds, resolution)
%INITIALIZELOGODDSMAP Create an unknown occupancy map in log-odds form.

arguments
    bounds (1, 4) double
    resolution (1, 1) double {mustBePositive} = 10
end

columnCount = ceil((bounds(2) - bounds(1)) * resolution);
rowCount = ceil((bounds(4) - bounds(3)) * resolution);
map.logOdds = zeros(rowCount, columnCount);
map.resolution = resolution;
map.bounds = bounds;
map.xCenters = bounds(1) + ((0:columnCount - 1) + 0.5) / resolution;
map.yCenters = bounds(3) + ((0:rowCount - 1) + 0.5) / resolution;
map.freeIncrement = -0.40;
map.occupiedIncrement = 0.85;
map.minimumLogOdds = -4.0;
map.maximumLogOdds = 4.0;
end
