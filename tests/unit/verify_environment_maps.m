function verify_environment_maps()
%VERIFY_ENVIRONMENT_MAPS Verify connectivity and dynamic-obstacle placement.

projectRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(projectRoot, "src"));
environmentNames = ["office", "hospital", "warehouse"];

for environmentName = environmentNames
    floorMap = amr.ui.createEnvironmentFloorMap(environmentName);
    planningGrid = amr.mapping.rasterizeFloorMap(floorMap, 10, 0.40, false);
    safetyGrid = amr.mapping.rasterizeFloorMap(floorMap, 10, 0.30, false);
    route = floorMap.referenceRoute;
    assert(~isempty(route), "AMR:EnvironmentNoRoute", ...
        "%s has no reference route.", environmentName);
    for segmentIndex = 1:size(route, 1) - 1
        assert(amr.mapping.isSegmentCollisionFree(safetyGrid, ...
            route(segmentIndex, :), route(segmentIndex + 1, :)), ...
            "AMR:EnvironmentRouteCollision", ...
            "%s reference route intersects the safety grid.", environmentName);
    end
    chargerRoute = amr.planning.planAStarGrid(planningGrid, ...
        floorMap.startPose(1:2), floorMap.chargerPose(1:2));
    assert(~isempty(chargerRoute), "AMR:EnvironmentChargerRoute", ...
        "%s charger is unreachable.", environmentName);
    obstacleCenter = floorMap.dynamicObstacle(1:2) + ...
        0.5 * floorMap.dynamicObstacle(3:4);
    routeDistance = distanceToPolyline(obstacleCenter, route);
    assert(routeDistance <= 1.0, "AMR:EnvironmentObstaclePlacement", ...
        "%s dynamic obstacle is %.2f m from its reference route.", ...
        environmentName, routeDistance);
    fprintf("Environment %-10s PASS | route points %d | obstacle offset %.2f m\n", ...
        environmentName, size(route, 1), routeDistance);
end
end

function distance = distanceToPolyline(point, path)
distance = inf;
for segmentIndex = 1:size(path, 1) - 1
    segment = path(segmentIndex + 1, :) - path(segmentIndex, :);
    denominator = dot(segment, segment);
    fraction = dot(point - path(segmentIndex, :), segment) / max(denominator, eps);
    fraction = min(max(fraction, 0), 1);
    projection = path(segmentIndex, :) + fraction * segment;
    distance = min(distance, norm(point - projection));
end
end
