function config = createDwaConfig()
%CREATEDWACONFIG Return local-planner limits and normalized cost weights.

config.controlSampleTime = 0.05;
config.predictionHorizon = 1.20;
config.rolloutSampleTime = 0.10;
config.minimumLinearVelocity = 0.0;
config.maximumLinearVelocity = 0.65;
config.maximumAngularVelocity = 1.20;
config.maximumLinearAcceleration = 1.20;
config.maximumAngularAcceleration = 4.00;
config.linearSampleCount = 5;
config.angularSampleCount = 11;
config.pathWeight = 3.0;
config.goalWeight = 0.35;
config.headingWeight = 0.85;
config.speedWeight = 0.55;
config.smoothnessWeight = 0.20;
end
