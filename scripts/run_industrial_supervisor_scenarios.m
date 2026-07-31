function summary = run_industrial_supervisor_scenarios()
%RUN_INDUSTRIAL_SUPERVISOR_SCENARIOS Verify hierarchical parallel modes.

scriptDirectory = fileparts(mfilename("fullpath"));
projectDirectory = fileparts(scriptDirectory);
modelFile = fullfile(projectDirectory, "models", "examples", ...
    "amr_industrial_supervisor.slx");
resultDirectory = fullfile(projectDirectory, "results");
modelName = "amr_industrial_supervisor";
load_system(modelFile);

scenarioNames = ["nominal", "obstacle", "battery", "health_fault", "e_stop"];
modeVariableNames = ["industrialLifecycleModeLog", "industrialMissionModeLog", ...
    "industrialNavigationModeLog", "industrialEnergyModeLog", ...
    "industrialSafetyModeLog", "industrialHealthModeLog"];
sequenceText = strings(numel(scenarioNames), numel(modeVariableNames));
figureHandle = figure("Name", "Industrial Supervisor Modes", "Color", "white");
layout = tiledlayout(figureHandle, numel(scenarioNames), 1, ...
    "TileSpacing", "compact", "Padding", "compact");

for scenarioId = 1:numel(scenarioNames)
    simulationInput = Simulink.SimulationInput(modelName);
    simulationInput = setBlockParameter(simulationInput, ...
        modelName + "/ScenarioId", "Value", num2str(scenarioId));
    simulationOutput = sim(simulationInput);
    sequences = cell(1, numel(modeVariableNames));

    nexttile(layout);
    hold on;
    for modeIndex = 1:numel(modeVariableNames)
        signal = simulationOutput.get(modeVariableNames(modeIndex));
        data = uint8(squeeze(signal.Data));
        sequences{modeIndex} = compressModes(data);
        sequenceText(scenarioId, modeIndex) = mat2str(sequences{modeIndex});
        stairs(signal.Time, double(data) + 10 * (modeIndex - 1), ...
            "LineWidth", 1.1);
    end
    grid on;
    ylabel(scenarioNames(scenarioId), "Interpreter", "none");
    if scenarioId == numel(scenarioNames)
        xlabel("simulation time (s)");
    end
    verifyScenario(scenarioId, sequences);
end

title(layout, "Hierarchical/Parallel Stateflow Supervisor");
legend(layout.Children(end), ...
    ["Lifecycle", "Mission", "Navigation", "Energy", "Safety", "Health"], ...
    "Location", "eastoutside");

summary = array2table(sequenceText, ...
    VariableNames=["Lifecycle", "Mission", "Navigation", ...
    "Energy", "Safety", "Health"]);
summary = addvars(summary, scenarioNames.', Before=1, ...
    NewVariableNames="Scenario");
disp(summary);

if ~isfolder(resultDirectory)
    mkdir(resultDirectory);
end
figurePath = fullfile(resultDirectory, ...
    "2026-07-21_industrial_supervisor_modes.png");
dataPath = fullfile(resultDirectory, ...
    "2026-07-21_industrial_supervisor_verification.mat");
exportgraphics(figureHandle, figurePath, "Resolution", 160);
save(dataPath, "summary");
fprintf("Industrial supervisor scenarios PASS.\n%s\n%s\n", ...
    figurePath, dataPath);
end

function sequence = compressModes(data)
modeChanges = [true; diff(double(data(:))) ~= 0];
sequence = data(modeChanges).';
end

function verifyScenario(scenarioId, sequences)
lifecycle = sequences{1};
mission = sequences{2};
navigation = sequences{3};
energy = sequences{4};
safety = sequences{5};
health = sequences{6};

switch scenarioId
    case 1
        assert(isequal(lifecycle, uint8([0, 1, 2])));
        assert(isequal(mission, uint8([0, 1, 2, 3, 4, 5, 6, 0])));
    case 2
        assert(isequal(safety, uint8([0, 1, 2, 0])));
        assert(any(navigation == uint8(3)), ...
            "AMR:IndustrialReplanMissing", "Obstacle scenario did not replan.");
    case 3
        assert(isequal(energy, uint8([0, 1, 2, 3, 0])));
    case 4
        assert(isequal(lifecycle, uint8([0, 1, 2, 4])));
        assert(isequal(health, uint8([0, 1, 0, 2])));
    case 5
        assert(isequal(lifecycle, uint8([0, 1, 2, 5, 1, 2])));
        assert(isequal(safety, uint8([0, 3, 0])));
end
end
