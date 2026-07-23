function verify_differential_drive()
%VERIFY_DIFFERENTIAL_DRIVE Verify milestone-01 kinematics with assertions.

projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src'));

params = create_default_amr_params();
r = params.robot.wheelRadius;
L = params.robot.trackWidth;

straightCommand = amr.modeling.differentialDriveForward([10, 10], r, L);
assert(max(abs(straightCommand - [0.5, 0])) < 1e-12, ...
    'Straight-wheel conversion failed.');

rotationCommand = amr.modeling.differentialDriveForward([-3, 3], r, L);
assert(max(abs(rotationCommand - [0, 1])) < 1e-12, ...
    'In-place rotation conversion failed.');

requestedCommand = [0.35, -0.6];
wheelSpeeds = amr.modeling.differentialDriveInverse(requestedCommand, r, L);
roundTripCommand = amr.modeling.differentialDriveForward(wheelSpeeds, r, L);
assert(max(abs(roundTripCommand - requestedCommand)) < 1e-12, ...
    'Forward/inverse kinematics round trip failed.');

pose = [0, 0, 0];
dt = params.sampleTime.plant;
pose = integrateForDuration(pose, [params.command.forwardSpeed, 0], ...
    params.mission.firstDriveDuration, dt);
pose = integrateForDuration(pose, [0, params.command.turnRate], ...
    params.mission.turnDuration, dt);
pose = integrateForDuration(pose, [params.command.forwardSpeed, 0], ...
    params.mission.secondDriveDuration, dt);

positionError = norm(pose(1:2) - params.expected.finalPose(1:2));
headingError = abs(amr.common.wrapAngle(pose(3) - params.expected.finalPose(3)));
assert(positionError < 1e-10, 'Milestone trajectory position failed.');
assert(headingError < 1e-10, 'Milestone trajectory heading failed.');

fprintf('Differential-drive verification passed.\n');
fprintf('Expected final pose: [%.3f, %.3f, %.3f] rad\n', ...
    params.expected.finalPose);
fprintf('Computed final pose: [%.3f, %.3f, %.3f] rad\n', pose);
end

function pose = integrateForDuration(pose, command, duration, sampleTime)
stepCount = round(duration / sampleTime);
for stepIndex = 1:stepCount
    pose = amr.modeling.integrateDifferentialDrive(pose, command, sampleTime);
end
end
