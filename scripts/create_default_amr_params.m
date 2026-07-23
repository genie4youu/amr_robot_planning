function params = create_default_amr_params()
%CREATE_DEFAULT_AMR_PARAMS Return parameters for AMR milestone 01.
%   The first milestone drives straight, turns left in place, drives
%   straight again, and stops. All quantities use SI units.

params.sampleTime.plant = 0.01;          % s
params.simulation.stopTime = 12.0;       % s

params.robot.wheelRadius = 0.05;         % m
params.robot.trackWidth = 0.30;          % m

params.command.forwardSpeed = 0.50;      % m/s
params.command.turnRate = pi / 4;        % rad/s

params.mission.initializeDuration = 1.0; % s
params.mission.firstDriveDuration = 4.0; % s
params.mission.turnDuration = 2.0;       % s
params.mission.secondDriveDuration = 4.0;% s

params.expected.finalPose = [2.0, 2.0, pi / 2];
params.tolerance.position = 0.03;        % m
params.tolerance.heading = 0.02;         % rad
params.tolerance.stoppedSpeed = 1e-12;
end
