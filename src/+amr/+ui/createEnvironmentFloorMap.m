function floorMap = createEnvironmentFloorMap(environment)
%CREATEENVIRONMENTFLOORMAP Return a synthetic office, hospital, or warehouse.
% The layouts are original training maps based on common indoor patterns;
% they do not reproduce a specific real facility.

arguments
    environment = "office"
end

environment = lower(string(environment));
switch environment
    case {"office", "1"}
        floorMap = amr.ui.createScenarioFloorMap();
        floorMap.environmentId = 1;
        floorMap.environmentName = "office";
        floorMap.displayName = "사무실/배송 구역";
        floorMap.wrongTurnPose = [5.40, 1.10];
        return;
    case {"hospital", "2"}
        floorMap = createHospitalMap();
    case {"warehouse", "3"}
        floorMap = createWarehouseMap();
    otherwise
        error("AMR:UnknownEnvironment", ...
            "Unknown environment '%s'. Use office, hospital, or warehouse.", ...
            environment);
end

floorMap = finalizeMap(floorMap);
end

function floorMap = createHospitalMap()
floorMap.environmentId = 2;
floorMap.environmentName = "hospital";
floorMap.displayName = "병원 중앙 복도";
floorMap.bounds = [0.0, 18.0, 0.0, 10.0];
floorMap.walls = [ ...
    0.10, 0.10, 17.80, 0.16; 0.10, 9.74, 17.80, 0.16; ...
    0.10, 0.10, 0.16, 9.80; 17.74, 0.10, 0.16, 9.80; ...
    4.00, 0.26, 0.16, 2.45; 4.00, 7.29, 0.16, 2.45; ...
    8.00, 0.26, 0.16, 2.45; 8.00, 7.29, 0.16, 2.45; ...
    12.00, 0.26, 0.16, 2.45; 12.00, 7.29, 0.16, 2.45; ...
    16.00, 0.26, 0.16, 2.45; 16.00, 7.29, 0.16, 2.45];
floorMap.obstacles = [ ...
    1.10, 0.80, 1.90, 0.75; 5.00, 0.80, 1.90, 0.75; ...
    9.00, 0.80, 1.90, 0.75; 13.00, 0.80, 1.90, 0.75; ...
    1.10, 8.30, 1.90, 0.75; 5.00, 8.30, 1.90, 0.75; ...
    9.00, 8.30, 1.90, 0.75; 13.00, 8.30, 1.90, 0.75; ...
    5.70, 3.35, 0.55, 0.90; 14.20, 5.80, 0.70, 0.55];
floorMap.dynamicObstacle = [8.70, 4.55, 0.70, 0.90];
floorMap.dynamicObstacleAppearanceTime = 9.00;
floorMap.startPose = [1.0, 5.0, 0.0];
floorMap.goalPose = [17.0, 5.0, 0.0];
floorMap.chargerPose = [1.0, 7.8, pi / 2];
floorMap.wrongTurnPose = [5.50, 6.50];
floorMap.labels = struct( ...
    "text", {"출발", "충전", "진료실 A", "진료실 B", "간호 스테이션", "약품 배송"}, ...
    "position", {[1.0, 4.55], [1.0, 7.45], [2.0, 2.10], ...
    [10.0, 2.10], [9.0, 6.30], [17.0, 5.55]});
end

function floorMap = createWarehouseMap()
floorMap.environmentId = 3;
floorMap.environmentName = "warehouse";
floorMap.displayName = "물류 창고 랙 구역";
floorMap.bounds = [0.0, 20.0, 0.0, 12.0];
floorMap.walls = [ ...
    0.10, 0.10, 19.80, 0.18; 0.10, 11.72, 19.80, 0.18; ...
    0.10, 0.10, 0.18, 11.80; 19.72, 0.10, 0.18, 11.80];
floorMap.obstacles = [ ...
    3.00, 2.00, 5.00, 0.90; 10.00, 2.00, 6.00, 0.90; ...
    3.00, 5.00, 5.00, 0.90; 10.00, 5.00, 6.00, 0.90; ...
    3.00, 8.00, 5.00, 0.90; 10.00, 8.00, 6.00, 0.90; ...
    17.40, 2.00, 0.90, 0.90; 8.55, 9.60, 0.70, 0.80];
floorMap.dynamicObstacle = [5.60, 3.65, 0.80, 0.80];
floorMap.dynamicObstacleAppearanceTime = 10.00;
floorMap.startPose = [1.0, 1.0, 0.0];
floorMap.goalPose = [18.8, 10.8, pi / 2];
floorMap.chargerPose = [1.0, 10.8, pi / 2];
floorMap.wrongTurnPose = [2.00, 6.50];
floorMap.labels = struct( ...
    "text", {"입고", "충전", "랙 A", "랙 B", "교차 통로", "출고"}, ...
    "position", {[1.0, 0.65], [1.0, 10.35], [5.5, 3.45], ...
    [13.0, 6.45], [9.0, 4.35], [18.8, 11.25]});
end

function floorMap = finalizeMap(floorMap)
planningGrid = amr.mapping.rasterizeFloorMap(floorMap, 10, 0.40, false);
rawRoute = amr.planning.planAStarGrid(planningGrid, ...
    floorMap.startPose(1:2), floorMap.goalPose(1:2));
floorMap.referenceRoute = amr.planning.smoothGridPath(planningGrid, rawRoute);
end
