function poseNext = integrateDifferentialDrive(pose, command, sampleTime)
%INTEGRATEDIFFERENTIALDRIVE Integrate a constant body command over one step.
%   pose and poseNext are [x, y, theta]. command is [v, omega]. Exact arc
%   integration is used for nonzero angular velocity.

validateattributes(pose, {'numeric'}, ...
    {'real', 'finite', 'vector', 'numel', 3}, mfilename, 'pose');
validateattributes(command, {'numeric'}, ...
    {'real', 'finite', 'vector', 'numel', 2}, mfilename, 'command');
validateattributes(sampleTime, {'numeric'}, ...
    {'real', 'finite', 'scalar', 'positive'}, mfilename, 'sampleTime');

x = pose(1);
y = pose(2);
theta = pose(3);
linearVelocity = command(1);
angularVelocity = command(2);

if abs(angularVelocity) < 1e-10
    xNext = x + linearVelocity * sampleTime * cos(theta);
    yNext = y + linearVelocity * sampleTime * sin(theta);
else
    thetaUnwrapped = theta + angularVelocity * sampleTime;
    radius = linearVelocity / angularVelocity;
    xNext = x + radius * (sin(thetaUnwrapped) - sin(theta));
    yNext = y - radius * (cos(thetaUnwrapped) - cos(theta));
end

thetaNext = amr.common.wrapAngle(theta + angularVelocity * sampleTime);
poseNext = [xNext, yNext, thetaNext];
end
