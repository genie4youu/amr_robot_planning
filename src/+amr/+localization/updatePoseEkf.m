function state = updatePoseEkf(state, measurement, config)
%UPDATEPOSEEKF Correct pose with a direct map/scan-matching measurement.

arguments
    state struct
    measurement (1, 3) double
    config struct = amr.localization.createPoseEkfConfig()
end

measurementNoise = diag([config.positionMeasurementNoise^2, ...
    config.positionMeasurementNoise^2, config.headingMeasurementNoise^2]);
innovation = measurement - state.mean;
innovation(3) = amr.common.wrapAngle(innovation(3));
innovationCovariance = state.covariance + measurementNoise;
kalmanGain = state.covariance / innovationCovariance;
state.mean = state.mean + (kalmanGain * innovation.').';
state.mean(3) = amr.common.wrapAngle(state.mean(3));
identity = eye(3);
state.covariance = (identity - kalmanGain) * state.covariance * ...
    (identity - kalmanGain).' + kalmanGain * measurementNoise * kalmanGain.';
state.covariance = 0.5 * (state.covariance + state.covariance.');
end
