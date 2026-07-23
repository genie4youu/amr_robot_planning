function state = predictPoseEkf(state, command, sampleTime, config)
%PREDICTPOSEEKF Propagate a planar pose mean and covariance.

arguments
    state struct
    command (1, 2) double
    sampleTime (1, 1) double {mustBePositive}
    config struct = amr.localization.createPoseEkfConfig()
end

theta = state.mean(3);
linearVelocity = command(1);
state.mean = amr.modeling.integrateDifferentialDrive( ...
    state.mean, command, sampleTime);
stateTransition = [ ...
    1, 0, -linearVelocity * sin(theta) * sampleTime; ...
    0, 1, linearVelocity * cos(theta) * sampleTime; ...
    0, 0, 1];
controlJacobian = [cos(theta) * sampleTime, 0; ...
    sin(theta) * sampleTime, 0; 0, sampleTime];
controlNoise = diag([config.linearVelocityNoise^2, ...
    config.angularVelocityNoise^2]);
state.covariance = stateTransition * state.covariance * ...
    stateTransition.' + controlJacobian * controlNoise * controlJacobian.';
state.covariance = 0.5 * (state.covariance + state.covariance.');
end
