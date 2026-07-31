function playbackData = simulate_amr_scenario(scenario, environment)
%SIMULATE_AMR_SCENARIO Run one fault-injection scenario and verify it.
%
% Supported scenarios: normal, obstacle, battery, wrong_turn.
% Supported environments: office, hospital, warehouse.

arguments
    scenario
    environment = "office"
end

[scenarioId, scenarioName, expectedModeSequence] = resolveScenario(scenario);
[environmentId, environmentName] = resolveEnvironment(environment);
scenarioCode = scenarioId + 4 * (environmentId - 1);
scriptDirectory = fileparts(mfilename("fullpath"));
projectDirectory = fileparts(scriptDirectory);
sourceDirectory = fullfile(projectDirectory, "src");
modelFile = fullfile(projectDirectory, "models", "examples", ...
    "amr_scenario_supervisor.slx");
addpath(scriptDirectory, sourceDirectory);

modelName = "amr_scenario_supervisor";
load_system(modelFile);
simulationInput = Simulink.SimulationInput(modelName);
simulationInput = setBlockParameter(simulationInput, ...
    modelName + "/ScenarioId", "Value", num2str(scenarioCode));
simulationInput = setModelParameter(simulationInput, ...
    "StopTime", num2str(environmentStopTime(environmentId)), ...
    "ReturnWorkspaceOutputs", "on");
simulationOutput = sim(simulationInput);

playbackData = struct( ...
    "time", getTime(simulationOutput, "scenarioXLog"), ...
    "x", getData(simulationOutput, "scenarioXLog"), ...
    "y", getData(simulationOutput, "scenarioYLog"), ...
    "heading", getData(simulationOutput, "scenarioThetaLog"), ...
    "battery", getData(simulationOutput, "scenarioBatteryLog"), ...
    "linearVelocity", getData(simulationOutput, "scenarioVLog"), ...
    "angularVelocity", getData(simulationOutput, "scenarioWLog"), ...
    "obstacleDetected", logical(getData(simulationOutput, "scenarioObstacleLog")), ...
    "batteryLow", logical(getData(simulationOutput, "scenarioBatteryLowLog")), ...
    "offRoute", logical(getData(simulationOutput, "scenarioOffRouteLog")), ...
    "atCharger", logical(getData(simulationOutput, "scenarioAtChargerLog")), ...
    "recoveryComplete", logical(getData(simulationOutput, "scenarioRecoveryCompleteLog")), ...
    "goalReached", logical(getData(simulationOutput, "scenarioGoalReachedLog")), ...
    "eventCode", uint8(getData(simulationOutput, "scenarioEventCodeLog")), ...
    "stateId", uint8(getData(simulationOutput, "scenarioMissionModeLog")), ...
    "scenarioId", scenarioId, ...
    "scenarioName", scenarioName, ...
    "environmentId", environmentId, ...
    "environmentName", environmentName, ...
    "stateNames", ["초기화", "배송 중", "장애물 정지", "장애물 우회", ...
    "충전소 복귀", "충전 중", "경로이탈 정지", "재경로", "배송 완료"]);

modeChanges = [true; diff(double(playbackData.stateId)) ~= 0];
actualModeSequence = playbackData.stateId(modeChanges).';
assert(isequal(actualModeSequence, expectedModeSequence), ...
    "AMR:ScenarioModeSequence", ...
    "%s mode sequence was %s; expected %s.", scenarioName, ...
    mat2str(actualModeSequence), mat2str(expectedModeSequence));
assert(playbackData.stateId(end) == uint8(8), ...
    "AMR:ScenarioNotCompleted", "%s did not reach Completed.", scenarioName);
floorMap = amr.ui.createEnvironmentFloorMap(environmentName);
finalPositionError = norm([playbackData.x(end), playbackData.y(end)] - ...
    floorMap.goalPose(1:2));
assert(finalPositionError <= 0.12, ...
    "AMR:ScenarioGoalError", ...
    "%s final position error %.3f m exceeds tolerance.", ...
    scenarioName, finalPositionError);

lidarPlayback = createLidarPlayback(playbackData, floorMap);
playbackData.lidarRanges = lidarPlayback.ranges;
playbackData.lidarAngles = lidarPlayback.angles;
playbackData.lidarFrontRange = lidarPlayback.frontRange;
playbackData.lidarSlowdown = lidarPlayback.slowdown;
playbackData.lidarStop = lidarPlayback.stop;
playbackData.lidarSensorFresh = lidarPlayback.sensorFresh;
playbackData.lidarFrameDropped = lidarPlayback.frameDropped;
playbackData.dynamicObstacleActive = lidarPlayback.dynamicObstacleActive;
playbackData.lidarConfig = lidarPlayback.config;

sensorReport = verifySensorDetection(playbackData);
localPlannerReport = verifyLocalPlanner(playbackData);
collisionReport = amr.verification.assertCollisionFreePlayback( ...
    playbackData, floorMap);

completionIndex = find(playbackData.stateId == uint8(8), 1, "first");
keepThrough = min(completionIndex + 40, numel(playbackData.time));
playbackData = trimPlayback(playbackData, keepThrough);
playbackData.modeSequence = actualModeSequence;
playbackData.finalPositionError = finalPositionError;
playbackData.collisionReport = collisionReport;
playbackData.sensorReport = sensorReport;
playbackData.localPlannerReport = localPlannerReport;

fprintf("Environment %-9s | Scenario %-12s PASS | completed %.2f s | modes %s | " + ...
    "collision-free %d | lidar %d | DWA %d\n", ...
    environmentName, scenarioName, playbackData.time(completionIndex), ...
    mat2str(actualModeSequence), collisionReport.passed, sensorReport.passed, ...
    localPlannerReport.passed);
end

function stopTime = environmentStopTime(environmentId)
stopTimes = [90, 140, 180];
stopTime = stopTimes(environmentId);
end

function time = getTime(simulationOutput, variableName)
signal = simulationOutput.get(variableName);
time = signal.Time(:);
end

function value = getData(simulationOutput, variableName)
signal = simulationOutput.get(variableName);
value = reshape(squeeze(signal.Data), [], 1);
end

function playbackData = trimPlayback(playbackData, keepThrough)
fieldNames = ["time", "x", "y", "heading", "battery", ...
    "linearVelocity", "angularVelocity", "obstacleDetected", ...
    "batteryLow", "offRoute", "atCharger", "recoveryComplete", ...
    "goalReached", "eventCode", "stateId", "lidarRanges", ...
    "lidarFrontRange", "lidarSlowdown", "lidarStop", ...
    "lidarSensorFresh", "lidarFrameDropped", ...
    "dynamicObstacleActive"];
for index = 1:numel(fieldNames)
    value = playbackData.(fieldNames(index));
    playbackData.(fieldNames(index)) = value(1:keepThrough, :);
end
end

function lidarPlayback = createLidarPlayback(playbackData, floorMap)
config = amr.sensors.createLidarConfig();
staticGrid = amr.mapping.rasterizeFloorMap(floorMap, 20, 0.0, false);
dynamicGrid = amr.mapping.rasterizeFloorMap(floorMap, 20, 0.0, true);
sampleCount = numel(playbackData.time);
beamCount = numel(config.angleOffsets);
ranges = repmat(config.maximumRange, sampleCount, beamCount);
frontRange = repmat(config.maximumRange, sampleCount, 1);
slowdown = false(sampleCount, 1);
stop = false(sampleCount, 1);
sensorFresh = true(sampleCount, 1);
frameDropped = false(sampleCount, 1);
dynamicObstacleActive = playbackData.scenarioId == 2 & ...
    playbackData.time >= floorMap.dynamicObstacleAppearanceTime;
initialPose = [playbackData.x(1), playbackData.y(1), playbackData.heading(1)];
heldScan = amr.sensors.simulateLidar2D(staticGrid, initialPose, config);
pipelineState = amr.sensors.initializeLidarPipeline(heldScan, ...
    playbackData.time(1), config);
heldStatus = struct("fresh", true, "frameDropped", false);
heldDetection = amr.sensors.evaluateLidarSafety(heldScan, config);
lastScanTime = -inf;

for sampleIndex = 1:sampleCount
    if playbackData.time(sampleIndex) - lastScanTime >= config.sampleTime - 1e-9
        if dynamicObstacleActive(sampleIndex)
            sensorGrid = dynamicGrid;
        else
            sensorGrid = staticGrid;
        end
        pose = [playbackData.x(sampleIndex), playbackData.y(sampleIndex), ...
            playbackData.heading(sampleIndex)];
        idealScan = amr.sensors.simulateLidar2D(sensorGrid, pose, config);
        [heldScan, heldStatus, pipelineState] = ...
            amr.sensors.stepLidarPipeline(idealScan, ...
            playbackData.time(sampleIndex), config, pipelineState);
        heldDetection = amr.sensors.evaluateLidarSafety(heldScan, config);
        lastScanTime = playbackData.time(sampleIndex);
    end
    ranges(sampleIndex, :) = heldScan.ranges.';
    frontRange(sampleIndex) = heldDetection.frontRange;
    slowdown(sampleIndex) = heldDetection.slowdownActive;
    stop(sampleIndex) = heldDetection.protectiveStopActive;
    sensorFresh(sampleIndex) = heldStatus.fresh;
    frameDropped(sampleIndex) = heldStatus.frameDropped;
end

lidarPlayback = struct( ...
    "ranges", ranges, ...
    "angles", config.angleOffsets.', ...
    "frontRange", frontRange, ...
    "slowdown", slowdown, ...
    "stop", stop, ...
    "sensorFresh", sensorFresh, ...
    "frameDropped", frameDropped, ...
    "dynamicObstacleActive", dynamicObstacleActive, ...
    "config", config);
end

function report = verifySensorDetection(playbackData)
dropoutEvents = playbackData.lidarFrameDropped & ...
    [true; ~playbackData.lidarFrameDropped(1:end - 1)];
report = struct("passed", true, "firstSlowdownTime", nan, ...
    "firstStopTime", nan, "stateflowEventTime", nan, ...
    "alignmentError", nan, ...
    "minimumFrontRange", min(playbackData.lidarFrontRange), ...
    "frameDropCount", nnz(dropoutEvents), ...
    "staleSampleCount", nnz(~playbackData.lidarSensorFresh));
assert(report.frameDropCount >= 1, "AMR:LidarNoFrameDropTest", ...
    "Scenario did not exercise the configured periodic frame dropout.");
if playbackData.scenarioId == 2
    slowdownIndex = find(playbackData.lidarSlowdown & ...
        playbackData.dynamicObstacleActive, 1, "first");
else
    slowdownIndex = find(playbackData.lidarSlowdown, 1, "first");
end

stopIndex = find(playbackData.lidarStop & playbackData.dynamicObstacleActive, ...
    1, "first");
if ~isempty(slowdownIndex)
    report.firstSlowdownTime = playbackData.time(slowdownIndex);
end
if ~isempty(stopIndex)
    report.firstStopTime = playbackData.time(stopIndex);
end

if playbackData.scenarioId == 2
    eventIndex = find(playbackData.obstacleDetected, 1, "first");
    assert(~isempty(stopIndex), "AMR:LidarNoDynamicStop", ...
        "Dynamic obstacle never entered the lidar protective-stop zone.");
    assert(~isempty(eventIndex), "AMR:LidarMissingStateflowEvent", ...
        "Stateflow did not receive an obstacle input.");
    eventWindow = max(1, eventIndex - 2): ...
        min(numel(playbackData.time), eventIndex + 2);
    assert(any(playbackData.lidarStop(eventWindow)), ...
        "AMR:LidarStateflowMismatch", ...
        "Stateflow obstacle input was not aligned with the lidar stop zone.");
    assert(playbackData.dynamicObstacleActive(eventIndex), ...
        "AMR:LidarObstacleInactive", ...
        "Obstacle input occurred before the dynamic obstacle appeared.");
    report.stateflowEventTime = playbackData.time(eventIndex);
    report.alignmentError = abs(report.stateflowEventTime - report.firstStopTime);
    assert(report.alignmentError <= 0.11, "AMR:LidarAlignment", ...
        "Lidar stop and Stateflow event differ by %.3f s.", ...
        report.alignmentError);
end
end

function report = verifyLocalPlanner(playbackData)
report = struct("passed", true, "sampleCount", 0, ...
    "maximumLinearStep", 0.0, "maximumAngularStep", 0.0);
if playbackData.scenarioId ~= 2
    return;
end

config = amr.planning.createDwaConfig();
dwaMask = playbackData.stateId == uint8(3);
report.sampleCount = nnz(dwaMask);
assert(report.sampleCount >= 3, "AMR:DwaMissingMode", ...
    "Obstacle scenario did not execute enough DWA samples.");
assert(any(playbackData.linearVelocity(dwaMask) > 0.02), ...
    "AMR:DwaNoMotion", "DWA mode produced no forward motion.");
consecutiveMask = dwaMask(1:end - 1) & dwaMask(2:end);
linearSteps = abs(diff(playbackData.linearVelocity));
angularSteps = abs(diff(playbackData.angularVelocity));
report.maximumLinearStep = max(linearSteps(consecutiveMask), [], "omitmissing");
report.maximumAngularStep = max(angularSteps(consecutiveMask), [], "omitmissing");
assert(report.maximumLinearStep <= ...
    config.maximumLinearAcceleration * config.controlSampleTime + 1e-9, ...
    "AMR:DwaLinearAcceleration", ...
    "DWA linear command step %.3f exceeds the acceleration limit.", ...
    report.maximumLinearStep);
assert(report.maximumAngularStep <= ...
    config.maximumAngularAcceleration * config.controlSampleTime + 1e-9, ...
    "AMR:DwaAngularAcceleration", ...
    "DWA angular command step %.3f exceeds the acceleration limit.", ...
    report.maximumAngularStep);
end

function [scenarioId, scenarioName, expectedModeSequence] = resolveScenario(scenario)
if isnumeric(scenario)
    scenarioId = double(scenario);
else
    names = ["normal", "obstacle", "battery", "wrong_turn"];
    scenarioId = find(strcmpi(string(scenario), names), 1);
    if isempty(scenarioId)
        error("AMR:UnknownScenario", ...
            "Unknown scenario '%s'. Use normal, obstacle, battery, or wrong_turn.", ...
            string(scenario));
    end
end

switch scenarioId
    case 1
        scenarioName = "normal";
        expectedModeSequence = uint8([0, 1, 8]);
    case 2
        scenarioName = "obstacle";
        expectedModeSequence = uint8([0, 1, 2, 3, 1, 8]);
    case 3
        scenarioName = "battery";
        expectedModeSequence = uint8([0, 1, 4, 5, 1, 8]);
    case 4
        scenarioName = "wrong_turn";
        expectedModeSequence = uint8([0, 1, 6, 7, 1, 8]);
    otherwise
        error("AMR:UnknownScenario", "Scenario ID must be an integer from 1 to 4.");
end
end

function [environmentId, environmentName] = resolveEnvironment(environment)
environmentNames = ["office", "hospital", "warehouse"];
if isnumeric(environment)
    environmentId = double(environment);
else
    environmentId = find(strcmpi(string(environment), environmentNames), 1);
end
if isempty(environmentId) || environmentId < 1 || environmentId > 3 || ...
        environmentId ~= floor(environmentId)
    error("AMR:UnknownEnvironment", ...
        "Environment must be office, hospital, warehouse, or ID 1 to 3.");
end
environmentName = environmentNames(environmentId);
end
