function wheelSpeeds = differentialDriveInverse(command, wheelRadius, trackWidth)
%DIFFERENTIALDRIVEINVERSE Convert [v, omega] to wheel speeds.
%   command is [linearVelocity, angularVelocity] in SI units. The returned
%   wheel speeds are [left, right] in rad/s.

validateattributes(command, {'numeric'}, ...
    {'real', 'finite', 'vector', 'numel', 2}, mfilename, 'command');
validateattributes(wheelRadius, {'numeric'}, ...
    {'real', 'finite', 'scalar', 'positive'}, mfilename, 'wheelRadius');
validateattributes(trackWidth, {'numeric'}, ...
    {'real', 'finite', 'scalar', 'positive'}, mfilename, 'trackWidth');

linearVelocity = command(1);
angularVelocity = command(2);

omegaLeft = (linearVelocity - angularVelocity * trackWidth / 2) / wheelRadius;
omegaRight = (linearVelocity + angularVelocity * trackWidth / 2) / wheelRadius;
wheelSpeeds = [omegaLeft, omegaRight];
end
