function verify_log_odds_mapping()
%VERIFY_LOG_ODDS_MAPPING Verify free, occupied, and unknown updates.

projectRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(projectRoot, "src"));
floorMap = struct("bounds", [0, 6, 0, 4], ...
    "walls", [3, 0, 0.10, 4], "obstacles", zeros(0, 4));
truthMap = amr.mapping.rasterizeFloorMap(floorMap, 20, 0, false);
config = amr.sensors.createLidarConfig();
config.rangeNoiseStandardDeviation = 0;
config.beamDropoutProbability = 0;
config.frameDropoutPeriod = 0;
scan = amr.sensors.simulateLidar2D(truthMap, [1, 2, 0], config);
map = amr.mapping.initializeLogOddsMap(floorMap.bounds, 20);
for updateIndex = 1:8
    map = amr.mapping.updateLogOddsWithScan(map, scan);
end
occupancy = amr.mapping.logOddsToOccupancy(map);

[freeRow, freeColumn] = worldToMap(map, [2.0, 2.0]);
[wallRow, wallColumn] = worldToMap(map, [3.0, 2.0]);
[unknownRow, unknownColumn] = worldToMap(map, [4.5, 2.0]);
assert(occupancy.free(freeRow, freeColumn), ...
    "AMR:MappingFree", "Observed free space was not marked free.");
assert(occupancy.occupied(wallRow, wallColumn), ...
    "AMR:MappingOccupied", "Observed wall was not marked occupied.");
assert(occupancy.unknown(unknownRow, unknownColumn), ...
    "AMR:MappingUnknown", "Unobserved space behind the wall changed state.");
fprintf("Log-odds occupancy mapping verification passed.\n");
end

function [row, column] = worldToMap(map, point)
column = floor((point(1) - map.bounds(1)) * map.resolution) + 1;
row = floor((point(2) - map.bounds(3)) * map.resolution) + 1;
end
