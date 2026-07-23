function angleWrapped = wrapAngle(angle)
%WRAPANGLE Wrap angles in radians to the interval [-pi, pi].

validateattributes(angle, {'numeric'}, {'real'}, mfilename, 'angle');
angleWrapped = atan2(sin(angle), cos(angle));
end
