function results = run_amr_milestone01()
%RUN_AMR_MILESTONE01 Simulate and verify the first indoor AMR milestone.
%
% The Stateflow supervisor commands a differential-drive plant through the
% sequence Initialize -> Straight -> Left turn -> Straight -> Stop. The
% expected final pose is [2 m, 2 m, pi/2 rad].

scriptDirectory = fileparts(mfilename("fullpath"));
projectDirectory = fileparts(scriptDirectory);
sourceDirectory = fullfile(projectDirectory, "src");
modelFile = fullfile(projectDirectory, "models", "prototypes", ...
    "amr_milestone01.slx");
resultDirectory = fullfile(projectDirectory, "results");

addpath(scriptDirectory, sourceDirectory);
if ~isfolder(resultDirectory)
    mkdir(resultDirectory);
end

parameters = create_default_amr_params();
modelName = "amr_milestone01";
load_system(modelFile);
set_param(modelName, ...
    "SolverType", "Fixed-step", ...
    "Solver", "FixedStepDiscrete", ...
    "FixedStep", num2str(parameters.sampleTime.plant), ...
    "StopTime", num2str(parameters.simulation.stopTime));

simulationOutput = sim(modelName, "ReturnWorkspaceOutputs", "on");

stateLog = simulationOutput.get("stateIdLog");
linearVelocityLog = simulationOutput.get("vCmdLog");
angularVelocityLog = simulationOutput.get("wCmdLog");
xLog = simulationOutput.get("xLog");
yLog = simulationOutput.get("yLog");
headingLog = simulationOutput.get("thetaLog");
leftWheelLog = simulationOutput.get("wheelLeftLog");
rightWheelLog = simulationOutput.get("wheelRightLog");

time = xLog.Time(:);
x = squeeze(xLog.Data);
y = squeeze(yLog.Data);
heading = squeeze(headingLog.Data);
stateId = uint8(squeeze(stateLog.Data));
linearVelocity = squeeze(linearVelocityLog.Data);
angularVelocity = squeeze(angularVelocityLog.Data);
leftWheelSpeed = squeeze(leftWheelLog.Data);
rightWheelSpeed = squeeze(rightWheelLog.Data);

finalPose = [x(end), y(end), amr.common.wrapAngle(heading(end))];
expectedPose = parameters.expected.finalPose;
positionError = norm(finalPose(1:2) - expectedPose(1:2));
headingError = abs(amr.common.wrapAngle(finalPose(3) - expectedPose(3)));
visitedStates = unique(stateId, "stable").';
expectedStates = uint8(0:4);
stoppedCommandNorm = norm([linearVelocity(end), angularVelocity(end)]);

assert(positionError <= parameters.tolerance.position, ...
    "AMR:PositionError", ...
    "Final position error %.6f m exceeds tolerance %.6f m.", ...
    positionError, parameters.tolerance.position);
assert(headingError <= parameters.tolerance.heading, ...
    "AMR:HeadingError", ...
    "Final heading error %.6f rad exceeds tolerance %.6f rad.", ...
    headingError, parameters.tolerance.heading);
assert(isequal(visitedStates, expectedStates), ...
    "AMR:StateSequence", ...
    "Unexpected Stateflow state sequence: %s", mat2str(visitedStates));
assert(stoppedCommandNorm <= parameters.tolerance.stoppedSpeed, ...
    "AMR:StoppedCommand", ...
    "The final velocity command is not zero.");

figureHandle = figure("Name", "AMR Milestone 01", "Color", "white");
layout = tiledlayout(figureHandle, 2, 2, ...
    "TileSpacing", "compact", "Padding", "compact");

nexttile(layout);
plot(x, y, "LineWidth", 1.8);
hold on;
plot(x(1), y(1), "go", "MarkerFaceColor", "g");
plot(x(end), y(end), "rs", "MarkerFaceColor", "r");
axis equal;
grid on;
xlabel("x (m)");
ylabel("y (m)");
title("Robot trajectory");
legend("trajectory", "start", "finish", "Location", "best");

nexttile(layout);
stairs(time, double(stateId), "LineWidth", 1.5);
grid on;
ylim([-0.5, 4.5]);
yticks(0:4);
yticklabels({"Init", "Straight 1", "Turn", "Straight 2", "Stopped"});
xlabel("time (s)");
ylabel("Stateflow state");
title("Mission supervisor");

nexttile(layout);
plot(time, linearVelocity, "LineWidth", 1.5);
hold on;
plot(time, angularVelocity, "LineWidth", 1.5);
grid on;
xlabel("time (s)");
ylabel("command");
title("Body velocity commands");
legend("v (m/s)", "omega (rad/s)", "Location", "best");

nexttile(layout);
plot(time, leftWheelSpeed, "LineWidth", 1.5);
hold on;
plot(time, rightWheelSpeed, "LineWidth", 1.5);
grid on;
xlabel("time (s)");
ylabel("wheel speed (rad/s)");
title("Differential-drive wheel speeds");
legend("left", "right", "Location", "best");

title(layout, "Indoor Delivery AMR - Milestone 01");
resultFigurePath = fullfile(resultDirectory, ...
    "2026-07-20_milestone01_simulation.png");
exportgraphics(figureHandle, resultFigurePath, "Resolution", 160);

results = struct( ...
    "passed", true, ...
    "finalPose", finalPose, ...
    "expectedPose", expectedPose, ...
    "positionError", positionError, ...
    "headingError", headingError, ...
    "visitedStates", visitedStates, ...
    "stoppedCommandNorm", stoppedCommandNorm, ...
    "resultFigure", resultFigurePath);
resultDataPath = fullfile(resultDirectory, ...
    "2026-07-20_milestone01_results.mat");
save(resultDataPath, "results");

fprintf("\nAMR Milestone 01: PASS\n");
fprintf("  State sequence : %s\n", mat2str(visitedStates));
fprintf("  Expected pose  : [%.3f, %.3f, %.3f] (m, m, rad)\n", expectedPose);
fprintf("  Final pose     : [%.3f, %.3f, %.3f] (m, m, rad)\n", finalPose);
fprintf("  Position error : %.6f m\n", positionError);
fprintf("  Heading error  : %.6f rad\n", headingError);
fprintf("  Figure         : %s\n\n", resultFigurePath);
end
