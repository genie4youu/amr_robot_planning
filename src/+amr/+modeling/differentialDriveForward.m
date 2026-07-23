function command = differentialDriveForward(wheelSpeeds, wheelRadius, trackWidth)
%DIFFERENTIALDRIVEFORWARD Convert wheel speeds to [v, omega].
%   wheelSpeeds is [left, right] in rad/s. The returned command contains
%   linear velocity in m/s and angular velocity in rad/s.

validateattributes(wheelSpeeds, {'numeric'}, ...
    {'real', 'finite', 'vector', 'numel', 2}, mfilename, 'wheelSpeeds');
validateattributes(wheelRadius, {'numeric'}, ...
    {'real', 'finite', 'scalar', 'positive'}, mfilename, 'wheelRadius');
validateattributes(trackWidth, {'numeric'}, ...
    {'real', 'finite', 'scalar', 'positive'}, mfilename, 'trackWidth');

omegaLeft = wheelSpeeds(1);
omegaRight = wheelSpeeds(2);

linearVelocity = wheelRadius * (omegaRight + omegaLeft) / 2;
angularVelocity = wheelRadius * (omegaRight - omegaLeft) / trackWidth;
command = [linearVelocity, angularVelocity];
end
