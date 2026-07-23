function summary = run_environment_matrix()
%RUN_ENVIRONMENT_MATRIX Verify four scenarios in three indoor layouts.

scriptDirectory = fileparts(mfilename("fullpath"));
projectRoot = fileparts(scriptDirectory);
addpath(scriptDirectory, fullfile(projectRoot, "src"));
environmentNames = ["office", "hospital", "warehouse"];
scenarioNames = ["normal", "obstacle", "battery", "wrong_turn"];
caseCount = numel(environmentNames) * numel(scenarioNames);
environmentColumn = strings(caseCount, 1);
scenarioColumn = strings(caseCount, 1);
completionTime = zeros(caseCount, 1);
minimumBattery = zeros(caseCount, 1);
finalPositionError = zeros(caseCount, 1);
collisionFree = false(caseCount, 1);
lidarValidated = false(caseCount, 1);
dwaValidated = false(caseCount, 1);
playback = cell(numel(environmentNames), numel(scenarioNames));

row = 0;
for environmentIndex = 1:numel(environmentNames)
    for scenarioIndex = 1:numel(scenarioNames)
        row = row + 1;
        clear amr.scenarios.scenarioEngineStep;
        data = simulate_amr_scenario( ...
            scenarioNames(scenarioIndex), environmentNames(environmentIndex));
        playback{environmentIndex, scenarioIndex} = data;
        completedIndex = find(data.stateId == uint8(8), 1, "first");
        environmentColumn(row) = environmentNames(environmentIndex);
        scenarioColumn(row) = scenarioNames(scenarioIndex);
        completionTime(row) = data.time(completedIndex);
        minimumBattery(row) = min(data.battery);
        finalPositionError(row) = data.finalPositionError;
        collisionFree(row) = data.collisionReport.passed;
        lidarValidated(row) = data.sensorReport.passed;
        dwaValidated(row) = data.localPlannerReport.passed;
    end
end

summary = table(environmentColumn, scenarioColumn, completionTime, ...
    minimumBattery, finalPositionError, collisionFree, lidarValidated, ...
    dwaValidated, VariableNames=["Environment", "Scenario", ...
    "CompletionTime_s", "MinimumBattery_percent", ...
    "FinalPositionError_m", "CollisionFree", "LidarValidated", ...
    "DwaValidated"]);
assert(all(summary.CollisionFree & summary.LidarValidated & ...
    summary.DwaValidated), "AMR:EnvironmentMatrixFailure", ...
    "At least one environment/scenario verification failed.");
disp(summary);

resultDirectory = fullfile(projectRoot, "results");
if ~isfolder(resultDirectory)
    mkdir(resultDirectory);
end
resultPath = fullfile(resultDirectory, ...
    "2026-07-22_environment_matrix_verification.mat");
save(resultPath, "summary");
figurePath = fullfile(resultDirectory, ...
    "2026-07-22_environment_matrix_trajectories.png");
createTrajectoryFigure(playback, environmentNames, scenarioNames, figurePath);
fprintf("All 12 environment/scenario cases PASS.\n%s\n%s\n", ...
    resultPath, figurePath);
end

function createTrajectoryFigure(playback, environmentNames, scenarioNames, filePath)
figureHandle = figure("Visible", "off", "Color", "white", ...
    "Position", [80, 80, 1500, 520]);
cleanup = onCleanup(@() close(figureHandle));
layout = tiledlayout(figureHandle, 1, numel(environmentNames), ...
    "TileSpacing", "compact", "Padding", "compact");
colors = lines(numel(scenarioNames));
for environmentIndex = 1:numel(environmentNames)
    axesHandle = nexttile(layout);
    floorMap = amr.ui.createEnvironmentFloorMap( ...
        environmentNames(environmentIndex));
    drawFloorMap(axesHandle, floorMap);
    for scenarioIndex = 1:numel(scenarioNames)
        data = playback{environmentIndex, scenarioIndex};
        plot(axesHandle, data.x, data.y, "LineWidth", 1.8, ...
            "Color", colors(scenarioIndex, :), ...
            "DisplayName", scenarioNames(scenarioIndex));
    end
    title(axesHandle, floorMap.displayName);
    if environmentIndex == numel(environmentNames)
        legend(axesHandle, "Location", "eastoutside");
    end
end
title(layout, "Indoor AMR environment matrix: verified trajectories");
exportgraphics(figureHandle, filePath, "Resolution", 170);
end

function drawFloorMap(axesHandle, floorMap)
hold(axesHandle, "on");
axis(axesHandle, "equal");
xlim(axesHandle, floorMap.bounds(1:2));
ylim(axesHandle, floorMap.bounds(3:4));
grid(axesHandle, "on");
for index = 1:size(floorMap.walls, 1)
    rectangle(axesHandle, "Position", floorMap.walls(index, :), ...
        "FaceColor", [0.20, 0.23, 0.27], "EdgeColor", "none");
end
for index = 1:size(floorMap.obstacles, 1)
    rectangle(axesHandle, "Position", floorMap.obstacles(index, :), ...
        "FaceColor", [0.70, 0.48, 0.24], "EdgeColor", "none");
end
rectangle(axesHandle, "Position", floorMap.dynamicObstacle, ...
    "FaceColor", [0.90, 0.20, 0.16], "EdgeColor", "none");
plot(axesHandle, floorMap.startPose(1), floorMap.startPose(2), "go", ...
    "MarkerFaceColor", "g", "HandleVisibility", "off");
plot(axesHandle, floorMap.goalPose(1), floorMap.goalPose(2), "rp", ...
    "MarkerFaceColor", "r", "MarkerSize", 10, "HandleVisibility", "off");
xlabel(axesHandle, "x (m)");
ylabel(axesHandle, "y (m)");
end
