function summary = run_integrated_delivery_scenarios()
%RUN_INTEGRATED_DELIVERY_SCENARIOS Verify plant-to-supervisor interfaces.

scriptDirectory = fileparts(mfilename("fullpath"));
projectRoot = fileparts(scriptDirectory);
addpath(scriptDirectory, fullfile(projectRoot, "src"));
modelPath = fullfile(projectRoot, "models", "system", ...
    "amr_integrated_delivery_system.slx");
modelName = "amr_integrated_delivery_system";
load_system(modelPath);

scenarioNames = ["normal", "obstacle", "battery", "wrong_turn"];
scenarioMode = strings(4, 1);
lifecycleMode = strings(4, 1);
navigationMode = strings(4, 1);
energyMode = strings(4, 1);
safetyMode = strings(4, 1);
finalPositionError = zeros(4, 1);

for scenarioIndex = 1:4
    simulationInput = Simulink.SimulationInput(modelName);
    simulationInput = setBlockParameter(simulationInput, ...
        modelName + "/ScenarioId", "Value", num2str(scenarioIndex));
    simulationInput = setModelParameter(simulationInput, ...
        "StopTime", "90", "ReturnWorkspaceOutputs", "on");
    output = sim(simulationInput);
    scenarioSequence = compressMode(output.get("integratedScenarioMissionLog"));
    lifecycleSequence = compressMode(output.get("integratedLifecycleLog"));
    navigationSequence = compressMode(output.get("integratedNavigationLog"));
    energySequence = compressMode(output.get("integratedEnergyLog"));
    safetySequence = compressMode(output.get("integratedSafetyLog"));
    scenarioMode(scenarioIndex) = mat2str(scenarioSequence);
    lifecycleMode(scenarioIndex) = mat2str(lifecycleSequence);
    navigationMode(scenarioIndex) = mat2str(navigationSequence);
    energyMode(scenarioIndex) = mat2str(energySequence);
    safetyMode(scenarioIndex) = mat2str(safetySequence);
    x = squeeze(output.get("integratedXLog").Data);
    y = squeeze(output.get("integratedYLog").Data);
    finalPositionError(scenarioIndex) = norm([x(end), y(end)] - [10.5, 6.5]);
    assert(scenarioSequence(end) == 8 && finalPositionError(scenarioIndex) <= 0.12, ...
        "AMR:IntegratedMission", "%s integrated mission failed.", ...
        scenarioNames(scenarioIndex));
    assert(isequal(lifecycleSequence, [0, 1, 2, 3, 0]), ...
        "AMR:IntegratedLifecycle", "%s lifecycle sequence was %s.", ...
        scenarioNames(scenarioIndex), mat2str(lifecycleSequence));
    assert(~any(navigationSequence == 5), "AMR:IntegratedNavFailed", ...
        "%s reached NavFailed after mission completion.", ...
        scenarioNames(scenarioIndex));
    if scenarioIndex == 2
        assert(any(navigationSequence == 3) && any(safetySequence == 2), ...
            "AMR:IntegratedObstacle", ...
            "Obstacle did not reach Replanning and ProtectiveStop.");
    elseif scenarioIndex == 3
        assert(all(ismember([1, 2, 3], energySequence)) && ...
            energySequence(end) == 0, ...
            "AMR:IntegratedEnergy", ...
            "Battery scenario missed Low/Critical/Charging modes.");
    end
end

summary = table(scenarioNames.', finalPositionError, scenarioMode, ...
    lifecycleMode, navigationMode, energyMode, safetyMode, ...
    VariableNames=["Scenario", "FinalPositionError_m", "ScenarioMode", ...
    "LifecycleMode", "NavigationMode", "EnergyMode", "SafetyMode"]);
disp(summary);
resultPath = fullfile(projectRoot, "results", ...
    "2026-07-22_integrated_system_verification.mat");
save(resultPath, "summary");
fprintf("Integrated plant/supervisor scenarios PASS.\n%s\n", resultPath);
end

function sequence = compressMode(timeSeries)
values = double(squeeze(timeSeries.Data));
values = values(:).';
sequence = values([true, diff(values) ~= 0]);
end
