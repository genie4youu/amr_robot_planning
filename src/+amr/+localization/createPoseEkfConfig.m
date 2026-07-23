function config = createPoseEkfConfig()
%CREATEPOSEEKFCONFIG Return process, measurement, and health thresholds.

config.linearVelocityNoise = 0.035;
config.angularVelocityNoise = 0.025;
config.positionMeasurementNoise = 0.08;
config.headingMeasurementNoise = deg2rad(3.0);
config.maximumPositionSigma = 0.35;
config.maximumHeadingSigma = deg2rad(12.0);
end
