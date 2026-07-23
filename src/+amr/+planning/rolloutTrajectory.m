function trajectory = rolloutTrajectory(initialPose, command, horizon, sampleTime)
%ROLLOUTTRAJECTORY Predict a constant-command differential-drive trajectory.

arguments
    initialPose (1, 3) double
    command (1, 2) double
    horizon (1, 1) double {mustBePositive}
    sampleTime (1, 1) double {mustBePositive}
end

stepCount = max(1, ceil(horizon / sampleTime));
trajectory = zeros(stepCount + 1, 3);
trajectory(1, :) = initialPose;
for stepIndex = 1:stepCount
    trajectory(stepIndex + 1, :) = ...
        amr.modeling.integrateDifferentialDrive( ...
        trajectory(stepIndex, :), command, sampleTime);
end
end
