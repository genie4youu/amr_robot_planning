function verify_pose_ekf_uncertainty()
%VERIFY_POSE_EKF_UNCERTAINTY Verify covariance growth and correction.

projectRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(projectRoot, "src"));
config = amr.localization.createPoseEkfConfig();
config.maximumPositionSigma = 0.08;
state = struct("mean", [0, 0, 0], ...
    "covariance", diag([0.02^2, 0.02^2, deg2rad(1)^2]));
initialTrace = trace(state.covariance);
for index = 1:600
    state = amr.localization.predictPoseEkf(state, [0.6, 0.25], 0.05, config);
end
predictedTrace = trace(state.covariance);
degradedHealth = amr.localization.evaluateLocalizationHealth(state, config);
assert(predictedTrace > initialTrace && ~degradedHealth.healthy, ...
    "AMR:EkfUncertaintyGrowth", ...
    "Prediction did not increase uncertainty beyond the health limit.");

measurement = state.mean + [0.03, -0.02, deg2rad(1.0)];
for index = 1:8
    state = amr.localization.updatePoseEkf(state, measurement, config);
end
correctedTrace = trace(state.covariance);
recoveredHealth = amr.localization.evaluateLocalizationHealth(state, config);
assert(correctedTrace < predictedTrace && recoveredHealth.healthy, ...
    "AMR:EkfUncertaintyCorrection", ...
    "Repeated map measurements did not restore localization health.");
fprintf("Pose EKF uncertainty/health verification passed.\n");
end
