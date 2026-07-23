function config = createLidarConfig()
%CREATELIDARCONFIG Return the deterministic 2-D lidar and safety-zone setup.

config.angleOffsets = deg2rad((-135:3:135).');
config.minimumRange = 0.10;
config.maximumRange = 5.00;
config.mountingOffset = [0.18, 0.0];
config.sampleTime = 0.10;
config.stopDistance = 0.85;
config.stopHalfWidth = 0.36;
config.slowdownDistance = 1.55;
config.slowdownHalfWidth = 0.55;
config.rangeNoiseStandardDeviation = 0.005;
config.beamDropoutProbability = 0.015;
config.frameDropoutPeriod = 29;
config.delaySamples = 1;
config.freshnessTimeout = 0.25;
end
