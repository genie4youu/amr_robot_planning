function summary = run_amr_mission_supervisor_scenarios(options)
%RUN_AMR_MISSION_SUPERVISOR_SCENARIOS Run scripted-plant regressions.

arguments
    options.ModelPath (1,1) string = ""
end

scriptFolder = fileparts(mfilename("fullpath"));
projectRoot = fileparts(scriptFolder);
if strlength(options.ModelPath) == 0
    modelPath = string(fullfile(projectRoot, "models", "prototypes", ...
        "amr_mission_supervisor.slx"));
else
    modelPath = options.ModelPath;
end
[~, modelName] = fileparts(modelPath);
modelName = string(modelName);

if ~isfile(modelPath)
    error("AMR:Supervision:MissingModel", ...
        "Mission supervisor model was not found: %s", modelPath);
end

addpath(fullfile(projectRoot, "src"));
load_system(modelPath);

scenarioNames = [ ...
    "nominal"
    "protective_stop"
    "recovery_success"
    "recovery_exhausted"
    "emergency_stop"
    "drive_fault"
    "communication_loss"
    "battery_diversion"
    "operator_cancel"];

scenarioPassed = false(size(scenarioNames));
finalLifecycle = strings(size(scenarioNames));
finalMission = strings(size(scenarioNames));
finalFaultReason = strings(size(scenarioNames));
maximumStopResponse = zeros(size(scenarioNames));
recoveryAttempts = zeros(size(scenarioNames), "uint8");
telemetryMetrics = cell(size(scenarioNames));

config = amr.supervision.createSupervisorConfig( ...
    SupervisorSampleTime=0.05, ...
    MinimumDwellTime=0.15, ...
    StopResponseLimit=0.05);

for scenarioIndex = 1:numel(scenarioNames)
    scenario = amr.supervision.createSupervisorScenario( ...
        scenarioNames(scenarioIndex), SampleTime=0.05, StopTime=18.0);
    simulationInput = Simulink.SimulationInput(modelName);
    simulationInput = simulationInput.setExternalInput( ...
        scenario.externalInput);
    simulationInput = simulationInput.setModelParameter( ...
        StopTime=num2str(scenario.stopTime), ...
        ReturnWorkspaceOutputs="on");

    simulationOutput = sim(simulationInput);
    telemetry = unpackTelemetry(simulationOutput.yout);
    metrics = amr.supervision.evaluateSupervisorTelemetry( ...
        telemetry, config);

    verifyScenario(scenarioNames(scenarioIndex), telemetry, metrics);

    scenarioPassed(scenarioIndex) = true;
    finalLifecycle(scenarioIndex) = ...
        string(telemetry.lifecycleMode(end));
    finalMission(scenarioIndex) = string(telemetry.missionMode(end));
    finalFaultReason(scenarioIndex) = ...
        string(telemetry.faultReason(end));
    maximumStopResponse(scenarioIndex) = ...
        metrics.stopResponse.maximumResponseTimeSeconds;
    recoveryAttempts(scenarioIndex) = ...
        uint8(max(double(getSignalData( ...
        simulationOutput.yout, "recoveryCount"))));
    telemetryMetrics{scenarioIndex} = metrics;
end

summary = table( ...
    scenarioNames, ...
    scenarioPassed, ...
    finalLifecycle, ...
    finalMission, ...
    finalFaultReason, ...
    maximumStopResponse, ...
    recoveryAttempts, ...
    VariableNames=[ ...
    "Scenario", ...
    "Passed", ...
    "FinalLifecycle", ...
    "FinalMission", ...
    "FinalFaultReason", ...
    "MaximumStopResponse_s", ...
    "RecoveryAttempts"]);

disp(summary);

resultFolder = fullfile(projectRoot, "results");
if ~isfolder(resultFolder)
    mkdir(resultFolder);
end
resultPath = fullfile(resultFolder, ...
    "2026-07-27_" + modelName + "_verification.mat");
save(resultPath, "summary", "telemetryMetrics");
fprintf("Mission Supervisor %s scenarios: %d/%d PASS.\n%s\n", ...
    modelName, nnz(scenarioPassed), numel(scenarioPassed), resultPath);
end

function telemetry = unpackTelemetry(outputDataset)
lifecycle = getSignalValues(outputDataset, "lifecycleMode");
telemetry.timeSeconds = lifecycle.Time;
telemetry.lifecycleMode = lifecycle.Data;
telemetry.missionMode = ...
    getSignalData(outputDataset, "missionMode");
telemetry.navigationMode = ...
    getSignalData(outputDataset, "navigationMode");
telemetry.safetyMode = ...
    getSignalData(outputDataset, "safetyMode");
telemetry.energyMode = ...
    getSignalData(outputDataset, "energyMode");
telemetry.healthMode = ...
    getSignalData(outputDataset, "healthMode");
telemetry.faultReason = ...
    getSignalData(outputDataset, "faultReason");
telemetry.recoveryAction = ...
    getSignalData(outputDataset, "recoveryAction");
telemetry.motionPermit = logical( ...
    getSignalData(outputDataset, "motionPermit"));
end

function data = getSignalData(outputDataset, signalName)
values = getSignalValues(outputDataset, signalName);
data = values.Data;
end

function values = getSignalValues(outputDataset, signalName)
element = outputDataset.getElement(signalName);
values = element.Values;
end

function verifyScenario(scenarioName, telemetry, metrics)
lifecycle = int32(telemetry.lifecycleMode(:));
mission = int32(telemetry.missionMode(:));
navigation = int32(telemetry.navigationMode(:));
safety = int32(telemetry.safetyMode(:));
energy = int32(telemetry.energyMode(:));
faultReason = int32(telemetry.faultReason(:));
motionPermit = telemetry.motionPermit(:);

assert(metrics.stopResponse.missedDeadlineCount == 0, ...
    "AMR:Supervision:LateStop", ...
    "%s missed the one-tick stop response.", scenarioName);
assert(metrics.invariants.nonOperationalMotionPermitSamples == 0, ...
    "AMR:Supervision:MotionOutsideOperational", ...
    "%s permitted motion outside Operational.", scenarioName);

switch scenarioName
    case "nominal"
        assert(any(mission == int32( ...
            amr.supervision.MissionMode.Completed)), ...
            "AMR:Supervision:MissionNotCompleted", ...
            "Nominal mission did not reach Completed.");
        assert(mission(end) == int32( ...
            amr.supervision.MissionMode.Idle));

    case "protective_stop"
        stopMask = safety == int32( ...
            amr.supervision.SafetyMode.ProtectiveStop);
        assert(any(stopMask) && ~any(motionPermit(stopMask)), ...
            "AMR:Supervision:ProtectiveStopFailed", ...
            "Protective stop did not remove motion authority.");

    case "recovery_success"
        assert(any(navigation == int32( ...
            amr.supervision.NavigationMode.Recovery)));
        assert(~any(lifecycle == int32( ...
            amr.supervision.LifecycleMode.FaultLatched)));

    case "recovery_exhausted"
        assert(lifecycle(end) == int32( ...
            amr.supervision.LifecycleMode.FaultLatched));
        assert(faultReason(end) == int32( ...
            amr.supervision.FaultReason.RecoveryExhausted));

    case "emergency_stop"
        emergencyMask = lifecycle == int32( ...
            amr.supervision.LifecycleMode.EmergencyStopLatched);
        assert(any(emergencyMask) && ~any(motionPermit(emergencyMask)));
        assert(nnz(diff(lifecycle) ~= 0) >= 4, ...
            "AMR:Supervision:EmergencyResetSequence", ...
            "E-stop reset did not pass through Boot.");

    case "drive_fault"
        assert(any(faultReason == int32( ...
            amr.supervision.FaultReason.DriveFault)));
        assert(any(lifecycle == int32( ...
            amr.supervision.LifecycleMode.FaultLatched)));

    case "communication_loss"
        assert(lifecycle(end) == int32( ...
            amr.supervision.LifecycleMode.FaultLatched));
        assert(faultReason(end) == int32( ...
            amr.supervision.FaultReason.CommunicationLost));

    case "battery_diversion"
        requiredModes = int32([ ...
            amr.supervision.EnergyMode.Low
            amr.supervision.EnergyMode.Critical
            amr.supervision.EnergyMode.GoToCharger
            amr.supervision.EnergyMode.Charging]);
        assert(all(ismember(requiredModes, unique(energy))));

    case "operator_cancel"
        assert(any(mission == int32( ...
            amr.supervision.MissionMode.Aborting)));
        assert(~any(mission == int32( ...
            amr.supervision.MissionMode.Completed)));
end
end
