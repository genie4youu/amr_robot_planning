function summary = run_all_amr_scenarios()
%RUN_ALL_AMR_SCENARIOS Execute and summarize all supervisor scenarios.

scriptDirectory = fileparts(mfilename("fullpath"));
projectDirectory = fileparts(scriptDirectory);
resultDirectory = fullfile(projectDirectory, "results");
sourceDirectory = fullfile(projectDirectory, "src");
addpath(scriptDirectory, sourceDirectory);

scenarioNames = ["normal", "obstacle", "battery", "wrong_turn"];
completionTime = zeros(numel(scenarioNames), 1);
minimumBattery = zeros(numel(scenarioNames), 1);
finalPositionError = zeros(numel(scenarioNames), 1);
modeSequence = strings(numel(scenarioNames), 1);
collisionFree = false(numel(scenarioNames), 1);
lidarValidated = false(numel(scenarioNames), 1);
dwaValidated = false(numel(scenarioNames), 1);

for index = 1:numel(scenarioNames)
    data = simulate_amr_scenario(scenarioNames(index));
    completedIndex = find(data.stateId == uint8(8), 1, "first");
    completionTime(index) = data.time(completedIndex);
    minimumBattery(index) = min(data.battery);
    finalPositionError(index) = data.finalPositionError;
    modeSequence(index) = mat2str(data.modeSequence);
    collisionFree(index) = data.collisionReport.passed;
    lidarValidated(index) = data.sensorReport.passed;
    dwaValidated(index) = data.localPlannerReport.passed;
end

summary = table(scenarioNames.', completionTime, minimumBattery, ...
    finalPositionError, collisionFree, lidarValidated, dwaValidated, ...
    modeSequence, ...
    VariableNames=["Scenario", "CompletionTime_s", ...
    "MinimumBattery_percent", "FinalPositionError_m", ...
    "CollisionFree", "LidarValidated", "DwaValidated", "ModeSequence"]);
disp(summary);

if ~isfolder(resultDirectory)
    mkdir(resultDirectory);
end
resultPath = fullfile(resultDirectory, ...
    "2026-07-22_scenario_verification.mat");
save(resultPath, "summary");
fprintf("All four AMR scenarios passed. Summary saved to:\n%s\n", resultPath);
end
