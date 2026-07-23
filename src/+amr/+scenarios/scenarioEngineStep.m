function [x, y, heading, batteryPercent, linearVelocity, angularVelocity, ...
    obstacleDetected, batteryLow, offRoute, atCharger, recoveryComplete, ...
    goalReached, eventCode, lidarFrontRange, lidarSlowdown, lidarStop, ...
    dynamicObstacleActive, localPlannerValid, sensorFresh] = ...
    scenarioEngineStep(missionMode, scenarioId, simulationTime)
%SCENARIOENGINESTEP Sensor-driven, collision-aware AMR scenario plant.
%
% This function is called as a simulation-only extrinsic function from the
% MATLAB Function block. Global, charger, avoidance, and reroute paths are
% generated with A* on an inflated occupancy grid. A final segment check
% prevents every proposed translation into occupied space.

persistent pose batteryState activePath pathIndex previousScenario lastMode
persistent floorMap staticGrid dynamicGrid staticPlanningGrid dynamicPlanningGrid
persistent staticSensorGrid dynamicSensorGrid lidarConfig lastSensorTime lidarDetection
persistent latestLidarScan lidarPipelineState sensorStatus
persistent dwaConfig lastCommand
persistent obstacleActivated obstacleHandled
persistent chargeHandled wrongTurnHandled wrongTurnActive wrongTurnStartTime
persistent modeEntryTime recoveryStartPose

sampleTime = 0.05;
scenarioCode = round(double(scenarioId));
environmentId = floor((scenarioCode - 1) / 4) + 1;
scenarioId = mod(scenarioCode - 1, 4) + 1;
environmentNames = ["office", "hospital", "warehouse"];
assert(environmentId >= 1 && environmentId <= numel(environmentNames), ...
    "AMR:ScenarioEnvironmentCode", "Scenario code must be from 1 to 12.");
if isempty(previousScenario) || simulationTime <= 0 || scenarioCode ~= previousScenario
    floorMap = amr.ui.createEnvironmentFloorMap(environmentNames(environmentId));
    staticGrid = amr.mapping.rasterizeFloorMap(floorMap, 10, 0.30, false);
    dynamicGrid = amr.mapping.rasterizeFloorMap(floorMap, 10, 0.30, true);
    staticPlanningGrid = amr.mapping.rasterizeFloorMap(floorMap, 10, 0.40, false);
    dynamicPlanningGrid = amr.mapping.rasterizeFloorMap(floorMap, 10, 0.40, true);
    staticSensorGrid = amr.mapping.rasterizeFloorMap(floorMap, 20, 0.0, false);
    dynamicSensorGrid = amr.mapping.rasterizeFloorMap(floorMap, 20, 0.0, true);
    lidarConfig = amr.sensors.createLidarConfig();
    lastSensorTime = -inf;
    lidarDetection = struct("slowdownActive", false, ...
        "protectiveStopActive", false, "frontRange", lidarConfig.maximumRange);
    latestLidarScan = amr.sensors.simulateLidar2D( ...
        staticSensorGrid, floorMap.startPose, lidarConfig);
    lidarPipelineState = amr.sensors.initializeLidarPipeline( ...
        latestLidarScan, 0.0, lidarConfig);
    sensorStatus = struct("fresh", true, "age", 0.0, ...
        "frameDropped", false, "measurementUpdated", true, "scanIndex", 0);
    dwaConfig = amr.planning.createDwaConfig();
    lastCommand = [0.0, 0.0];
    pose = floorMap.startPose;
    if scenarioId == 3
        batteryState = 38.0;
    else
        batteryState = 100.0;
    end
    activePath = planPath(staticPlanningGrid, pose(1:2), floorMap.goalPose(1:2));
    pathIndex = initialPathIndex(activePath);
    obstacleActivated = false;
    obstacleHandled = false;
    chargeHandled = false;
    wrongTurnHandled = false;
    wrongTurnActive = false;
    wrongTurnStartTime = 0.0;
    lastMode = uint8(255);
    modeEntryTime = 0.0;
    recoveryStartPose = pose(1:2);
    previousScenario = scenarioCode;
end

linearVelocity = 0.0;
angularVelocity = 0.0;
obstacleDetected = false;
batteryLow = false;
offRoute = false;
atCharger = false;
recoveryComplete = false;
goalReached = false;
eventCode = uint8(0);
localPlannerValid = true;

modeChanged = missionMode ~= lastMode;
if modeChanged
    modeEntryTime = simulationTime;
    recoveryStartPose = pose(1:2);
end

if missionMode == uint8(5)
    batteryState = min(100.0, batteryState + 12.0 * sampleTime);
elseif missionMode ~= uint8(8)
    if scenarioId == 3 && ~chargeHandled
        drainRate = 0.70;
    else
        drainRate = 0.20;
    end
    batteryState = max(0.0, batteryState - drainRate * sampleTime);
end

if scenarioId == 2 && simulationTime >= floorMap.dynamicObstacleAppearanceTime
    obstacleActivated = true;
end
if scenarioId == 2 && obstacleActivated
    sensorGrid = dynamicSensorGrid;
else
    sensorGrid = staticSensorGrid;
end
if simulationTime - lastSensorTime >= lidarConfig.sampleTime - 1e-9
    idealLidarScan = amr.sensors.simulateLidar2D( ...
        sensorGrid, pose, lidarConfig);
    [latestLidarScan, sensorStatus, lidarPipelineState] = ...
        amr.sensors.stepLidarPipeline(idealLidarScan, simulationTime, ...
        lidarConfig, lidarPipelineState);
    lidarDetection = amr.sensors.evaluateLidarSafety( ...
        latestLidarScan, lidarConfig);
    lastSensorTime = simulationTime;
end
lidarFrontRange = lidarDetection.frontRange;
lidarSlowdown = lidarDetection.slowdownActive;
lidarStop = lidarDetection.protectiveStopActive || ~sensorStatus.fresh;
dynamicObstacleActive = scenarioId == 2 && obstacleActivated;
sensorFresh = sensorStatus.fresh;

if scenarioId == 2 && obstacleActivated
    navigationGrid = dynamicGrid;
else
    navigationGrid = staticGrid;
end

switch missionMode
    case uint8(0) % Initializing
        % Fail-safe default: zero velocity until initialization completes.

    case uint8(1) % Delivering
        if modeChanged && lastMode == uint8(5)
            activePath = planPath(staticPlanningGrid, pose(1:2), floorMap.goalPose(1:2));
            pathIndex = initialPathIndex(activePath);
        end

        if scenarioId == 2 && ~obstacleHandled && lidarStop
            obstacleDetected = true;
            eventCode = uint8(1);
        elseif scenarioId == 3 && ~chargeHandled && batteryState <= 30.0
            batteryLow = true;
            eventCode = uint8(2);
        elseif scenarioId == 4 && ~wrongTurnHandled
            if ~wrongTurnActive && simulationTime >= 8.0
                wrongTurnActive = true;
                wrongTurnStartTime = simulationTime;
                activePath = planPath(staticPlanningGrid, pose(1:2), ...
                    floorMap.wrongTurnPose);
                pathIndex = initialPathIndex(activePath);
            end
            if wrongTurnActive
                eventCode = uint8(3);
                [pose, pathIndex, linearVelocity, angularVelocity, ~, blocked] = ...
                    followPath(pose, activePath, pathIndex, staticGrid, ...
                    sampleTime, 1.0);
                deviation = distanceToPath(pose(1:2), floorMap.referenceRoute);
                if blocked || (simulationTime - wrongTurnStartTime >= 2.0 && deviation >= 0.80)
                    linearVelocity = 0.0;
                    angularVelocity = 0.0;
                    offRoute = true;
                end
            end
        else
            speedScale = 1.0;
            if scenarioId == 2 && obstacleActivated && ...
                    ~obstacleHandled && lidarSlowdown
                speedScale = 0.35;
                eventCode = uint8(6);
            end
            [pose, pathIndex, linearVelocity, angularVelocity, reached, blocked] = ...
                followPath(pose, activePath, pathIndex, navigationGrid, ...
                sampleTime, speedScale);
            if blocked
                obstacleDetected = true;
                eventCode = uint8(1);
            elseif reached
                goalReached = true;
            end
        end

    case uint8(2) % Obstacle protective stop
        obstacleActivated = true;
        obstacleDetected = true;
        eventCode = uint8(1);

    case uint8(3) % Replan and avoid obstacle
        eventCode = uint8(1);
        if modeChanged
            activePath = planPath(dynamicPlanningGrid, pose(1:2), floorMap.goalPose(1:2));
            pathIndex = initialPathIndex(activePath);
            lastCommand = [0.0, 0.0];
        end
        localCostmap = amr.planning.buildLocalCostmapFromLidar( ...
            staticGrid, staticSensorGrid, latestLidarScan, pose(1:2), ...
            [6.0, 6.0], 0.30);
        [pose, pathIndex, linearVelocity, angularVelocity, ~, blocked, ...
            localPlannerValid] = followPathDwa(pose, activePath, pathIndex, ...
            localCostmap, sampleTime, lastCommand, dwaConfig);
        obstacleCenter = [floorMap.dynamicObstacle(1) + floorMap.dynamicObstacle(3) / 2, ...
            floorMap.dynamicObstacle(2) + floorMap.dynamicObstacle(4) / 2];
        if blocked
            linearVelocity = 0.0;
            angularVelocity = 0.0;
        elseif simulationTime - modeEntryTime >= 1.0 && ...
                norm(pose(1:2) - obstacleCenter) >= 1.60
            obstacleHandled = true;
            recoveryComplete = true;
        end

    case uint8(4) % Return to charger
        eventCode = uint8(2);
        batteryLow = true;
        if modeChanged
            activePath = planPath(staticPlanningGrid, pose(1:2), floorMap.chargerPose(1:2));
            pathIndex = initialPathIndex(activePath);
        end
        [pose, pathIndex, linearVelocity, angularVelocity, reached, blocked] = ...
            followPath(pose, activePath, pathIndex, staticGrid, sampleTime, 1.0);
        if blocked
            linearVelocity = 0.0;
            angularVelocity = 0.0;
        elseif reached
            atCharger = true;
        end

    case uint8(5) % Charging
        eventCode = uint8(4);
        atCharger = true;
        if batteryState >= 90.0
            chargeHandled = true;
            recoveryComplete = true;
        end

    case uint8(6) % Off-route protective stop
        eventCode = uint8(3);
        offRoute = true;

    case uint8(7) % Replan from current pose
        eventCode = uint8(3);
        if modeChanged
            activePath = planPath(staticPlanningGrid, pose(1:2), floorMap.goalPose(1:2));
            pathIndex = initialPathIndex(activePath);
        end
        [pose, pathIndex, linearVelocity, angularVelocity, ~, blocked] = ...
            followPath(pose, activePath, pathIndex, staticGrid, sampleTime, 1.0);
        if blocked
            linearVelocity = 0.0;
            angularVelocity = 0.0;
        elseif norm(pose(1:2) - recoveryStartPose) >= 1.0
            wrongTurnHandled = true;
            wrongTurnActive = false;
            recoveryComplete = true;
        end

    otherwise % Completed
        eventCode = uint8(5);
        goalReached = true;
end

lastMode = missionMode;
lastCommand = [linearVelocity, angularVelocity];
x = pose(1);
y = pose(2);
heading = pose(3);
batteryPercent = batteryState;
end

function [pose, pathIndex, linearVelocity, angularVelocity, reachedGoal, ...
        blocked, plannerValid] = followPathDwa(pose, path, pathIndex, ...
        gridMap, sampleTime, currentCommand, config)
reachedGoal = false;
blocked = false;
while pathIndex < size(path, 1) && ...
        norm(path(pathIndex, :) - pose(1:2)) <= 0.15
    pathIndex = pathIndex + 1;
end

localPath = [pose(1:2); path(pathIndex:end, :)];
[command, diagnostics] = amr.planning.selectDwaCommand( ...
    pose, currentCommand, localPath, gridMap, config);
plannerValid = diagnostics.valid;
if ~plannerValid
    linearVelocity = 0.0;
    angularVelocity = 0.0;
    blocked = true;
    return;
end

candidatePose = amr.modeling.integrateDifferentialDrive( ...
    pose, command, sampleTime);
if ~amr.mapping.isSegmentCollisionFree( ...
        gridMap, pose(1:2), candidatePose(1:2))
    linearVelocity = 0.0;
    angularVelocity = 0.0;
    blocked = true;
    plannerValid = false;
    return;
end

pose = candidatePose;
linearVelocity = command(1);
angularVelocity = command(2);
if norm(pose(1:2) - path(end, :)) <= 0.08
    reachedGoal = true;
end
end

function path = planPath(gridMap, startPosition, goalPosition)
rawPath = amr.planning.planAStarGrid(gridMap, startPosition, goalPosition);
path = amr.planning.smoothGridPath(gridMap, rawPath);
end

function index = initialPathIndex(path)
if size(path, 1) >= 2
    index = 2;
else
    index = 1;
end
end

function [pose, pathIndex, linearVelocity, angularVelocity, reachedGoal, blocked] = ...
        followPath(pose, path, pathIndex, gridMap, sampleTime, speedScale)
reachedGoal = false;
blocked = false;
while pathIndex < size(path, 1) && ...
        norm(path(pathIndex, :) - pose(1:2)) <= 0.10
    pathIndex = pathIndex + 1;
end

oldPose = pose;
[candidatePose, linearVelocity, angularVelocity, reachedWaypoint] = ...
    driveToward(pose, path(pathIndex, :), sampleTime, speedScale);
if ~amr.mapping.isSegmentCollisionFree( ...
        gridMap, oldPose(1:2), candidatePose(1:2))
    pose = oldPose;
    linearVelocity = 0.0;
    angularVelocity = 0.0;
    blocked = true;
    return;
end

pose = candidatePose;
if reachedWaypoint
    if pathIndex < size(path, 1)
        pathIndex = pathIndex + 1;
    else
        reachedGoal = true;
    end
end
end

function [pose, linearVelocity, angularVelocity, reached] = ...
        driveToward(pose, target, sampleTime, speedScale)
deltaX = target(1) - pose(1);
deltaY = target(2) - pose(2);
distance = hypot(deltaX, deltaY);
reached = distance <= 0.08;
if reached
    linearVelocity = 0.0;
    angularVelocity = 0.0;
    return;
end

desiredHeading = atan2(deltaY, deltaX);
headingError = wrapAngleLocal(desiredHeading - pose(3));
if abs(headingError) > 0.18
    linearVelocity = 0.0;
    angularVelocity = min(max(2.2 * headingError, -1.20), 1.20);
else
    linearVelocity = speedScale * min(0.65, 1.2 * distance);
    angularVelocity = min(max(2.5 * headingError, -1.20), 1.20);
end

pose(3) = wrapAngleLocal(pose(3) + angularVelocity * sampleTime);
pose(1) = pose(1) + linearVelocity * cos(pose(3)) * sampleTime;
pose(2) = pose(2) + linearVelocity * sin(pose(3)) * sampleTime;
end

function distance = distanceToPath(point, path)
distance = inf;
for index = 1:size(path, 1) - 1
    segment = path(index + 1, :) - path(index, :);
    denominator = dot(segment, segment);
    if denominator <= eps
        projection = path(index, :);
    else
        fraction = dot(point - path(index, :), segment) / denominator;
        fraction = min(max(fraction, 0), 1);
        projection = path(index, :) + fraction * segment;
    end
    distance = min(distance, norm(point - projection));
end
end

function angle = wrapAngleLocal(angle)
angle = mod(angle + pi, 2 * pi) - pi;
end
