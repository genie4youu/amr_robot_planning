function scenario = createSupervisorScenario(scenarioName, options)
%CREATESUPERVISORSCENARIO Create deterministic inputs for the v1 model.
%   SCENARIO contains a Simulink Dataset for the root Inport blocks of
%   amr_mission_supervisor.slx. All status signals are scripted plant
%   responses; the Stateflow chart remains the only supervisory controller.

arguments
    scenarioName (1,1) string {mustBeMember(scenarioName, [ ...
        "nominal", ...
        "protective_stop", ...
        "recovery_success", ...
        "recovery_exhausted", ...
        "emergency_stop", ...
        "drive_fault", ...
        "communication_loss", ...
        "battery_diversion", ...
        "operator_cancel"])}
    options.SampleTime (1,1) double ...
        {mustBeReal, mustBeFinite, mustBePositive} = 0.05
    options.StopTime (1,1) double ...
        {mustBeReal, mustBeFinite, mustBePositive} = 18.0
end

if options.StopTime < 12.0
    error("AMR:Supervision:ScenarioTooShort", ...
        "StopTime must be at least 12 seconds.");
end

inputNames = [ ...
    "startRequest"
    "bootComplete"
    "shutdownRequest"
    "emergencyStop"
    "resetRequest"
    "resumeRequest"
    "jobAvailable"
    "planReady"
    "plannerFailed"
    "controllerFailed"
    "goalReached"
    "pathInvalid"
    "obstacleSlow"
    "obstacleStop"
    "batteryLow"
    "batteryCritical"
    "chargerReached"
    "chargeComplete"
    "localizationHealthy"
    "sensorFresh"
    "communicationFresh"
    "actuatorHealthy"
    "loadComplete"
    "unloadComplete"
    "cancelRequest"
    "robotStopped"];

timeSeconds = (0:options.SampleTime:options.StopTime).';
signalData = false(numel(timeSeconds), numel(inputNames));

signalData(:, columnOf(inputNames, "startRequest")) = timeSeconds >= 0.20;
signalData(:, columnOf(inputNames, "bootComplete")) = timeSeconds >= 1.00;
signalData(:, columnOf(inputNames, "jobAvailable")) = ...
    inWindow(timeSeconds, 2.00, 2.50);
signalData(:, columnOf(inputNames, "planReady")) = true;
signalData(:, columnOf(inputNames, "localizationHealthy")) = true;
signalData(:, columnOf(inputNames, "sensorFresh")) = true;
signalData(:, columnOf(inputNames, "communicationFresh")) = true;
signalData(:, columnOf(inputNames, "actuatorHealthy")) = true;
signalData(:, columnOf(inputNames, "robotStopped")) = true;

signalData(:, columnOf(inputNames, "goalReached")) = ...
    inWindow(timeSeconds, 5.00, 5.20) | ...
    inWindow(timeSeconds, 10.00, 10.20) | ...
    inWindow(timeSeconds, 15.00, 15.20);
signalData(:, columnOf(inputNames, "loadComplete")) = ...
    inWindow(timeSeconds, 6.00, 6.30);
signalData(:, columnOf(inputNames, "unloadComplete")) = ...
    inWindow(timeSeconds, 11.00, 11.30);

switch scenarioName
    case "protective_stop"
        signalData(:, columnOf(inputNames, "obstacleSlow")) = ...
            inWindow(timeSeconds, 3.00, 3.50);
        signalData(:, columnOf(inputNames, "obstacleStop")) = ...
            inWindow(timeSeconds, 3.50, 4.50);
        signalData(:, columnOf(inputNames, "resumeRequest")) = ...
            inWindow(timeSeconds, 4.60, 4.90);

    case "recovery_success"
        signalData(:, columnOf(inputNames, "controllerFailed")) = ...
            inWindow(timeSeconds, 3.30, 3.55);
        signalData(:, columnOf(inputNames, "resumeRequest")) = ...
            inWindow(timeSeconds, 3.90, 4.20);

    case "recovery_exhausted"
        signalData(:, columnOf(inputNames, "controllerFailed")) = ...
            timeSeconds >= 3.30;

    case "emergency_stop"
        signalData(:, columnOf(inputNames, "emergencyStop")) = ...
            inWindow(timeSeconds, 6.00, 8.00);
        signalData(:, columnOf(inputNames, "resetRequest")) = ...
            inWindow(timeSeconds, 8.40, 8.80);

    case "drive_fault"
        signalData(:, columnOf(inputNames, "actuatorHealthy")) = ...
            ~inWindow(timeSeconds, 6.00, 9.00);
        signalData(:, columnOf(inputNames, "resetRequest")) = ...
            inWindow(timeSeconds, 8.00, 8.30) | ...
            inWindow(timeSeconds, 9.40, 9.80);

    case "communication_loss"
        signalData(:, columnOf(inputNames, "communicationFresh")) = ...
            ~inWindow(timeSeconds, 3.20, 7.50);

    case "battery_diversion"
        signalData(:, columnOf(inputNames, "batteryLow")) = ...
            inWindow(timeSeconds, 3.00, 8.00);
        signalData(:, columnOf(inputNames, "batteryCritical")) = ...
            inWindow(timeSeconds, 4.00, 8.00);
        signalData(:, columnOf(inputNames, "chargerReached")) = ...
            inWindow(timeSeconds, 6.00, 8.00);
        signalData(:, columnOf(inputNames, "chargeComplete")) = ...
            inWindow(timeSeconds, 8.00, 8.30);

    case "operator_cancel"
        signalData(:, columnOf(inputNames, "cancelRequest")) = ...
            inWindow(timeSeconds, 3.50, 3.80);
end

externalInput = Simulink.SimulationData.Dataset;
for inputIndex = 1:numel(inputNames)
    values = timeseries( ...
        signalData(:, inputIndex), timeSeconds, ...
        Name=inputNames(inputIndex));
    externalInput = externalInput.addElement(values, inputNames(inputIndex));
end

scenario.name = scenarioName;
scenario.sampleTime = options.SampleTime;
scenario.stopTime = options.StopTime;
scenario.timeSeconds = timeSeconds;
scenario.inputNames = inputNames;
scenario.externalInput = externalInput;
end

function index = columnOf(inputNames, inputName)
index = find(inputNames == inputName, 1);
end

function mask = inWindow(timeSeconds, startTime, endTime)
mask = timeSeconds >= startTime & timeSeconds < endTime;
end
