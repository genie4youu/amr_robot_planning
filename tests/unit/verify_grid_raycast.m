function verify_grid_raycast()
%VERIFY_GRID_RAYCAST Verify DDA ray hits and lidar safety-zone detection.

projectRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(projectRoot, "src"));

floorMap = struct( ...
    "bounds", [0, 4, 0, 3], ...
    "walls", [2.0, 0.0, 0.10, 3.0], ...
    "obstacles", zeros(0, 4));
gridMap = amr.mapping.rasterizeFloorMap(floorMap, 20, 0, false);

[range, hitPoint, hit] = amr.sensors.raycastGrid( ...
    gridMap, [1.0, 1.5], 0, 0.10, 3.0);
assert(hit, "AMR:RaycastExpectedHit", "Forward ray did not hit the wall.");
assert(abs(range - 1.0) <= 1e-12, ...
    "AMR:RaycastRange", "Forward-wall range was %.6f m.", range);
assert(norm(hitPoint - [2.0, 1.5]) <= 1e-12, ...
    "AMR:RaycastHitPoint", "Unexpected hit point.");

[range, ~, hit] = amr.sensors.raycastGrid( ...
    gridMap, [1.0, 1.5], pi / 2, 0.10, 1.0);
assert(~hit && abs(range - 1.0) <= 1e-12, ...
    "AMR:RaycastNoHit", "No-hit ray must return maximum range.");

safetyMap = floorMap;
safetyMap.walls = zeros(0, 4);
safetyMap.dynamicObstacle = [1.65, 1.30, 0.30, 0.40];
dynamicGrid = amr.mapping.rasterizeFloorMap(safetyMap, 20, 0, true);
config = amr.sensors.createLidarConfig();
scan = amr.sensors.simulateLidar2D(dynamicGrid, [1.0, 1.5, 0], config);
detection = amr.sensors.evaluateLidarSafety(scan, config);
assert(detection.slowdownActive && detection.protectiveStopActive, ...
    "AMR:LidarSafetyZone", "Obstacle did not activate both safety zones.");

fprintf("Grid raycast and lidar safety verification passed.\n");
fprintf("Forward wall range: %.3f m, safety front range: %.3f m\n", ...
    1.0, detection.frontRange);
end
