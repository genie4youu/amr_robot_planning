function summary = run_integrated_environment_matrix()
%RUN_INTEGRATED_ENVIRONMENT_MATRIX Verify Stateflow modes in all 12 cases.

scriptDirectory = fileparts(mfilename("fullpath"));
projectRoot = fileparts(scriptDirectory);
addpath(scriptDirectory, fullfile(projectRoot, "src"));
modelPath = fullfile(projectRoot, "models", "system", ...
    "amr_integrated_delivery_system.slx");
modelName = "amr_integrated_delivery_system";
load_system(modelPath);
environmentNames = ["office", "hospital", "warehouse"];
scenarioNames = ["normal", "obstacle", "battery", "wrong_turn"];
expectedScenarioModes = {uint8([0, 1, 8]), uint8([0, 1, 2, 3, 1, 8]), ...
    uint8([0, 1, 4, 5, 1, 8]), uint8([0, 1, 6, 7, 1, 8])};
stopTimes = [90, 140, 180];
caseCount = 12;
environmentColumn = strings(caseCount, 1);
scenarioColumn = strings(caseCount, 1);
finalPositionError = zeros(caseCount, 1);
lifecycleMode = strings(caseCount, 1);
navigationMode = strings(caseCount, 1);
energyMode = strings(caseCount, 1);
safetyMode = strings(caseCount, 1);
row = 0;

for environmentIndex = 1:3
    floorMap = amr.ui.createEnvironmentFloorMap( ...
        environmentNames(environmentIndex));
    for scenarioIndex = 1:4
        row = row + 1;
        scenarioCode = scenarioIndex + 4 * (environmentIndex - 1);
        clear amr.scenarios.scenarioEngineStep;
        simulationInput = Simulink.SimulationInput(modelName);
        simulationInput = setBlockParameter(simulationInput, ...
            modelName + "/ScenarioId", "Value", num2str(scenarioCode));
        simulationInput = setModelParameter(simulationInput, ...
            "StopTime", num2str(stopTimes(environmentIndex)), ...
            "ReturnWorkspaceOutputs", "on");
        output = sim(simulationInput);
        scenarioSequence = compressMode(output.get("integratedScenarioMissionLog"));
        lifecycleSequence = compressMode(output.get("integratedLifecycleLog"));
        navigationSequence = compressMode(output.get("integratedNavigationLog"));
        energySequence = compressMode(output.get("integratedEnergyLog"));
        safetySequence = compressMode(output.get("integratedSafetyLog"));
        x = squeeze(output.get("integratedXLog").Data);
        y = squeeze(output.get("integratedYLog").Data);
        error = norm([x(end), y(end)] - floorMap.goalPose(1:2));

        assert(isequal(uint8(scenarioSequence), ...
            expectedScenarioModes{scenarioIndex}), ...
            "AMR:IntegratedEnvironmentMission", ...
            "%s/%s scenario mode was %s.", ...
            environmentNames(environmentIndex), scenarioNames(scenarioIndex), ...
            mat2str(scenarioSequence));
        assert(isequal(lifecycleSequence, [0, 1, 2, 3, 0]), ...
            "AMR:IntegratedEnvironmentLifecycle", ...
            "%s/%s lifecycle mode was %s.", ...
            environmentNames(environmentIndex), scenarioNames(scenarioIndex), ...
            mat2str(lifecycleSequence));
        assert(~any(navigationSequence == 5) && error <= 0.12, ...
            "AMR:IntegratedEnvironmentNavigation", ...
            "%s/%s reached NavFailed or missed its goal.", ...
            environmentNames(environmentIndex), scenarioNames(scenarioIndex));
        if scenarioIndex == 2
            assert(any(navigationSequence == 3) && any(safetySequence == 2), ...
                "AMR:IntegratedEnvironmentObstacle", ...
                "%s obstacle recovery modes were incomplete.", ...
                environmentNames(environmentIndex));
        elseif scenarioIndex == 3
            assert(all(ismember([1, 2, 3], energySequence)) && ...
                energySequence(end) == 0, ...
                "AMR:IntegratedEnvironmentEnergy", ...
                "%s energy modes were incomplete.", ...
                environmentNames(environmentIndex));
        end

        environmentColumn(row) = environmentNames(environmentIndex);
        scenarioColumn(row) = scenarioNames(scenarioIndex);
        finalPositionError(row) = error;
        lifecycleMode(row) = mat2str(lifecycleSequence);
        navigationMode(row) = mat2str(navigationSequence);
        energyMode(row) = mat2str(energySequence);
        safetyMode(row) = mat2str(safetySequence);
    end
end

summary = table(environmentColumn, scenarioColumn, finalPositionError, ...
    lifecycleMode, navigationMode, energyMode, safetyMode, ...
    VariableNames=["Environment", "Scenario", "FinalPositionError_m", ...
    "LifecycleMode", "NavigationMode", "EnergyMode", "SafetyMode"]);
disp(summary);
resultPath = fullfile(projectRoot, "results", ...
    "2026-07-22_integrated_environment_matrix.mat");
save(resultPath, "summary");
fprintf("Integrated Stateflow environment matrix 12/12 PASS.\n%s\n", ...
    resultPath);
end

function sequence = compressMode(timeSeries)
values = double(squeeze(timeSeries.Data));
values = values(:).';
sequence = values([true, diff(values) ~= 0]);
end
