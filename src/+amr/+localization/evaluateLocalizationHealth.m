function health = evaluateLocalizationHealth(state, config)
%EVALUATELOCALIZATIONHEALTH Convert covariance into supervisor health data.

arguments
    state struct
    config struct = amr.localization.createPoseEkfConfig()
end

positionSigma = sqrt(max(eig(state.covariance(1:2, 1:2))));
headingSigma = sqrt(max(0, state.covariance(3, 3)));
health = struct( ...
    "positionSigma", positionSigma, ...
    "headingSigma", headingSigma, ...
    "healthy", positionSigma <= config.maximumPositionSigma && ...
        headingSigma <= config.maximumHeadingSigma);
end
