function modelPath = build_amr_industrial_supervisor()
%BUILD_AMR_INDUSTRIAL_SUPERVISOR Create a hierarchical parallel supervisor.

projectRoot = fileparts(fileparts(mfilename("fullpath")));
modelDirectory = fullfile(projectRoot, "models", "examples");
modelName = "amr_industrial_supervisor";
modelPath = fullfile(modelDirectory, modelName + ".slx");
if isfile(modelPath)
    error("AMR:ModelAlreadyExists", ...
        "Model already exists and will not be overwritten: %s", modelPath);
end

new_system(modelName);
cleanup = onCleanup(@() closeModelIfLoaded(modelName));
add_block("sflib/Chart", modelName + "/IndustrialSupervisor", ...
    "Position", [500, 80, 760, 350]);
add_block("simulink/User-Defined Functions/MATLAB Function", ...
    modelName + "/SupervisorStimulus", ...
    "Position", [80, 60, 360, 370]);
setStimulusScript(modelName + "/SupervisorStimulus");
add_block("simulink/Sources/Digital Clock", modelName + "/SimulationTime", ...
    "SampleTime", "0.1", "Position", [20, 60, 55, 90]);
add_block("simulink/Sources/Constant", modelName + "/ScenarioId", ...
    "Value", "1", "Position", [20, 115, 55, 145]);
add_line(modelName, "SimulationTime/1", "SupervisorStimulus/1", "autorouting", "on");
add_line(modelName, "ScenarioId/1", "SupervisorStimulus/2", "autorouting", "on");

chart = find(sfroot, "-isa", "Stateflow.Chart", ...
    "Path", modelName + "/IndustrialSupervisor");
chart.ActionLanguage = "MATLAB";
chart.Decomposition = "EXCLUSIVE_OR";

inputNames = ["startRequest", "bootComplete", "shutdownRequest", ...
    "emergencyStop", "resetRequest", "jobAvailable", "planReady", ...
    "plannerFailed", "controllerFailed", "goalReached", "pathInvalid", ...
    "obstacleSlow", "obstacleStop", "batteryLow", "batteryCritical", ...
    "chargerReached", "chargeComplete", "localizationHealthy", ...
    "sensorFresh", "actuatorHealthy"];
outputNames = ["lifecycleMode", "missionMode", "navigationMode", ...
    "energyMode", "safetyMode", "healthMode"];
for index = 1:numel(inputNames)
    addChartData(chart, inputNames(index), "Input", "boolean", index);
end
for index = 1:numel(outputNames)
    addChartData(chart, outputNames(index), "Output", "uint8", index);
end

buildTopLevel(chart);

for index = 1:numel(inputNames)
    add_line(modelName, "SupervisorStimulus/" + index, ...
        "IndustrialSupervisor/" + index, "autorouting", "on");
end
for index = 1:numel(outputNames)
    blockName = "Log" + outputNames(index);
    add_block("simulink/Sinks/To Workspace", modelName + "/" + blockName, ...
        "VariableName", "industrial" + upperFirst(outputNames(index)) + "Log", ...
        "SaveFormat", "Timeseries", ...
        "Position", [860, 40 + 55 * (index - 1), 1060, 70 + 55 * (index - 1)]);
    add_line(modelName, "IndustrialSupervisor/" + index, ...
        blockName + "/1", "autorouting", "on");
end

set_param(modelName, ...
    "SolverType", "Fixed-step", "Solver", "FixedStepDiscrete", ...
    "FixedStep", "0.1", "StopTime", "22", "ReturnWorkspaceOutputs", "on");
save_system(modelName, modelPath);
clear cleanup;
close_system(modelName, 0);
fprintf("Created industrial supervisor: %s\n", modelPath);
end

function buildTopLevel(chart)
powerOff = addState(chart, "PowerOff", [20, 40, 120, 70], ...
    modeActions("PowerOff", 0, [0, 0, 0, 0, 0]));
boot = addState(chart, "Boot", [175, 40, 120, 70], ...
    modeActions("Boot", 1, [0, 0, 0, 0, 0]));
operational = addState(chart, "Operational", [330, 20, 900, 690], ...
    "Operational" + newline + "entry,during:" + newline + ...
    " lifecycleMode = uint8(2);");
operational.Decomposition = "PARALLEL_AND";
shutdown = addState(chart, "ControlledShutdown", [1270, 40, 170, 75], ...
    modeActions("ControlledShutdown", 3, [0, 0, 0, 0, 0]));
fault = addState(chart, "FaultLatched", [1270, 170, 170, 75], ...
    modeActions("FaultLatched", 4, [0, 0, 0, 3, 2]));
emergency = addState(chart, "EmergencyStopLatched", [1270, 300, 190, 80], ...
    modeActions("EmergencyStopLatched", 5, [0, 0, 0, 3, 2]));

addDefault(chart, powerOff);
addTransition(chart, powerOff, boot, "[startRequest]");
addTransition(chart, boot, operational, "[bootComplete]");
addTransition(chart, boot, emergency, "[emergencyStop]");
addTransition(chart, operational, shutdown, "[shutdownRequest]");
addTransition(chart, operational, emergency, "[emergencyStop]");
addTransition(chart, operational, fault, "[healthMode == uint8(2)]");
addTransition(chart, shutdown, powerOff, "after(1,sec)");
addTransition(chart, emergency, boot, "[resetRequest && ~emergencyStop]");
addTransition(chart, fault, boot, ...
    "[resetRequest && actuatorHealthy && sensorFresh]");

missionRegion = addState(operational, "MissionRegion", [350, 65, 190, 610], "MissionRegion");
navigationRegion = addState(operational, "NavigationRegion", [555, 65, 190, 610], "NavigationRegion");
energyRegion = addState(operational, "EnergyRegion", [760, 65, 190, 285], "EnergyRegion");
safetyRegion = addState(operational, "SafetyRegion", [970, 65, 190, 285], "SafetyRegion");
healthRegion = addState(operational, "HealthRegion", [760, 380, 190, 275], "HealthRegion");
missionRegion.Decomposition = "EXCLUSIVE_OR";
navigationRegion.Decomposition = "EXCLUSIVE_OR";
energyRegion.Decomposition = "EXCLUSIVE_OR";
safetyRegion.Decomposition = "EXCLUSIVE_OR";
healthRegion.Decomposition = "EXCLUSIVE_OR";

buildMissionRegion(missionRegion);
buildNavigationRegion(navigationRegion);
buildEnergyRegion(energyRegion);
buildSafetyRegion(safetyRegion);
buildHealthRegion(healthRegion);
end

function buildMissionRegion(parent)
names = ["Idle", "AcceptJob", "NavigatePickup", "Loading", ...
    "NavigateDropoff", "Unloading", "ReturnHome"];
modes = 0:6;
states = cell(1, numel(names));
for index = 1:numel(names)
    states{index} = addState(parent, names(index), ...
        [365, 100 + 72 * (index - 1), 160, 48], ...
        regionAction(names(index), "missionMode", modes(index)));
end
addDefault(parent, states{1});
addTransition(parent, states{1}, states{2}, "[jobAvailable]");
addTransition(parent, states{2}, states{3}, "after(0.5,sec)");
addTransition(parent, states{3}, states{4}, "[goalReached]");
addTransition(parent, states{4}, states{5}, "after(1,sec)");
addTransition(parent, states{5}, states{6}, "[goalReached]");
addTransition(parent, states{6}, states{7}, "after(1,sec)");
addTransition(parent, states{7}, states{1}, "[goalReached]");
end

function buildNavigationRegion(parent)
names = ["NavIdle", "Planning", "Tracking", "Replanning", "Recovery", "NavFailed"];
modes = 0:5;
states = cell(1, numel(names));
for index = 1:numel(names)
    states{index} = addState(parent, names(index), ...
        [570, 105 + 82 * (index - 1), 160, 50], ...
        regionAction(names(index), "navigationMode", modes(index)));
end
addDefault(parent, states{1});
addTransition(parent, states{1}, states{2}, ...
    "[missionMode == uint8(2) || missionMode == uint8(4) || missionMode == uint8(6)]");
addTransition(parent, states{2}, states{3}, "[planReady]");
addTransition(parent, states{2}, states{5}, "[plannerFailed]");
addTransition(parent, states{2}, states{5}, "after(3,sec)");
addTransition(parent, states{3}, states{4}, "[pathInvalid]");
addTransition(parent, states{3}, states{5}, "[controllerFailed]");
addTransition(parent, states{3}, states{1}, "[goalReached]");
addTransition(parent, states{4}, states{3}, "[planReady]");
addTransition(parent, states{4}, states{5}, "[plannerFailed]");
addTransition(parent, states{4}, states{5}, "after(3,sec)");
addTransition(parent, states{5}, states{2}, "[resetRequest]");
addTransition(parent, states{5}, states{6}, "after(2,sec)");
addTransition(parent, states{6}, states{2}, "[resetRequest]");
end

function buildEnergyRegion(parent)
normal = addState(parent, "EnergyNormal", [775, 105, 155, 45], ...
    regionAction("EnergyNormal", "energyMode", 0));
low = addState(parent, "EnergyLow", [775, 165, 155, 45], ...
    regionAction("EnergyLow", "energyMode", 1));
critical = addState(parent, "EnergyCritical", [775, 225, 155, 45], ...
    regionAction("EnergyCritical", "energyMode", 2));
charging = addState(parent, "Charging", [775, 285, 155, 45], ...
    regionAction("Charging", "energyMode", 3));
addDefault(parent, normal);
addTransition(parent, normal, low, "[batteryLow]");
addTransition(parent, low, normal, "[~batteryLow]");
addTransition(parent, low, critical, "[batteryCritical]");
addTransition(parent, critical, charging, "[chargerReached]");
addTransition(parent, charging, normal, "[chargeComplete]");
end

function buildSafetyRegion(parent)
safe = addState(parent, "Safe", [985, 105, 155, 45], ...
    regionAction("Safe", "safetyMode", 0));
slow = addState(parent, "Slowdown", [985, 175, 155, 45], ...
    regionAction("Slowdown", "safetyMode", 1));
stop = addState(parent, "ProtectiveStop", [985, 245, 155, 50], ...
    regionAction("ProtectiveStop", "safetyMode", 2));
addDefault(parent, safe);
addTransition(parent, safe, slow, "[obstacleSlow]");
addTransition(parent, safe, stop, "[obstacleStop]");
addTransition(parent, slow, stop, "[obstacleStop]");
addTransition(parent, slow, safe, "[~obstacleSlow && ~obstacleStop]");
addTransition(parent, stop, safe, "[~obstacleStop && resetRequest]");
end

function buildHealthRegion(parent)
healthy = addState(parent, "Healthy", [775, 420, 155, 45], ...
    regionAction("Healthy", "healthMode", 0));
degraded = addState(parent, "Degraded", [775, 490, 155, 45], ...
    regionAction("Degraded", "healthMode", 1));
fault = addState(parent, "HealthFault", [775, 560, 155, 45], ...
    regionAction("HealthFault", "healthMode", 2));
addDefault(parent, healthy);
addTransition(parent, healthy, degraded, ...
    "[~sensorFresh || ~localizationHealthy]");
addTransition(parent, healthy, fault, "[~actuatorHealthy]");
addTransition(parent, degraded, healthy, ...
    "[sensorFresh && localizationHealthy && actuatorHealthy]");
addTransition(parent, degraded, fault, "[~actuatorHealthy]");
addTransition(parent, degraded, fault, "after(5,sec)");
end

function text = modeActions(name, lifecycle, regionModes)
text = name + newline + "entry,during:" + newline + ...
    " lifecycleMode = uint8(" + lifecycle + ");" + newline + ...
    " missionMode = uint8(" + regionModes(1) + ");" + newline + ...
    " navigationMode = uint8(" + regionModes(2) + ");" + newline + ...
    " energyMode = uint8(" + regionModes(3) + ");" + newline + ...
    " safetyMode = uint8(" + regionModes(4) + ");" + newline + ...
    " healthMode = uint8(" + regionModes(5) + ");";
end

function text = regionAction(name, outputName, value)
text = name + newline + "entry,during:" + newline + ...
    " " + outputName + " = uint8(" + value + ");";
end

function state = addState(parent, name, position, label)
state = Stateflow.State(parent);
state.Name = name;
state.Position = position;
state.LabelString = label;
end

function addDefault(parent, destination)
transition = Stateflow.Transition(parent);
transition.Destination = destination;
transition.DestinationOClock = 0;
transition.SourceEndpoint = transition.DestinationEndpoint - [0, 30];
transition.MidPoint = transition.DestinationEndpoint - [0, 15];
end

function addTransition(parent, source, destination, label)
transition = Stateflow.Transition(parent);
transition.Source = source;
transition.Destination = destination;
transition.LabelString = label;
sourcePosition = source.Position;
destinationPosition = destination.Position;
sourceCenter = sourcePosition(1:2) + sourcePosition(3:4) / 2;
destinationCenter = destinationPosition(1:2) + destinationPosition(3:4) / 2;
delta = destinationCenter - sourceCenter;
if abs(delta(1)) > abs(delta(2))
    if delta(1) >= 0
        transition.SourceOClock = 3;
        transition.DestinationOClock = 9;
    else
        transition.SourceOClock = 9;
        transition.DestinationOClock = 3;
    end
else
    if delta(2) >= 0
        transition.SourceOClock = 6;
        transition.DestinationOClock = 12;
    else
        transition.SourceOClock = 12;
        transition.DestinationOClock = 6;
    end
end
transition.MidPoint = (transition.SourceEndpoint + transition.DestinationEndpoint) / 2;
end

function addChartData(chart, name, scope, dataType, port)
data = Stateflow.Data(chart);
data.Name = name;
data.Scope = scope;
data.DataType = dataType;
data.Port = port;
data.Props.Array.Size = "1";
end

function setStimulusScript(blockPath)
chart = find(sfroot, "-isa", "Stateflow.EMChart", "Path", blockPath);
chart.Script = sprintf( ...
    "function [startRequest,bootComplete,shutdownRequest,emergencyStop," + ...
    "resetRequest,jobAvailable,planReady,plannerFailed,controllerFailed," + ...
    "goalReached,pathInvalid,obstacleSlow,obstacleStop,batteryLow," + ...
    "batteryCritical,chargerReached,chargeComplete,localizationHealthy," + ...
    "sensorFresh,actuatorHealthy] = fcn(t,scenarioId)\n" + ...
    "startRequest=t>=0.2; bootComplete=t>=1.0; shutdownRequest=false; " + ...
    "emergencyStop=false; resetRequest=false;\n" + ...
    "jobAvailable=t>=2.0 && t<2.3; planReady=true; plannerFailed=false; " + ...
    "controllerFailed=false;\n" + ...
    "goalReached=(t>=8.0&&t<8.3)||(t>=13.0&&t<13.3)||(t>=19.0&&t<19.3); " + ...
    "pathInvalid=false;\n" + ...
    "obstacleSlow=false; obstacleStop=false; batteryLow=false; " + ...
    "batteryCritical=false; chargerReached=false; chargeComplete=false;\n" + ...
    "localizationHealthy=true; sensorFresh=true; actuatorHealthy=true;\n" + ...
    "if scenarioId==2, obstacleSlow=t>=5&&t<6; obstacleStop=t>=6&&t<8; " + ...
    "resetRequest=t>=8; pathInvalid=t>=8&&t<8.3; end\n" + ...
    "if scenarioId==3, batteryLow=t>=5&&t<15; batteryCritical=t>=7&&t<15; " + ...
    "chargerReached=t>=10; chargeComplete=t>=15; end\n" + ...
    "if scenarioId==4, sensorFresh=~(t>=5&&t<9); " + ...
    "localizationHealthy=~(t>=5&&t<9); actuatorHealthy=t<12; " + ...
    "resetRequest=t>=16; end\n" + ...
    "if scenarioId==5, emergencyStop=t>=6&&t<9; resetRequest=t>=9.5; end\n");
data = find(chart, "-isa", "Stateflow.Data");
for index = 1:numel(data)
    data(index).Props.Array.Size = "1";
    if data(index).Scope == "Output"
        data(index).DataType = "boolean";
    else
        data(index).DataType = "double";
    end
end
end

function value = upperFirst(value)
value = upper(extractBefore(value, 2)) + extractAfter(value, 1);
end

function closeModelIfLoaded(modelName)
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
end
