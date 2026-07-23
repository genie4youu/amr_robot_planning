function [command, diagnostics] = selectDwaCommand( ...
        pose, currentCommand, path, gridMap, config)
%SELECTDWACOMMAND Select an admissible local command by trajectory rollout.

arguments
    pose (1, 3) double
    currentCommand (1, 2) double
    path (:, 2) double
    gridMap struct
    config struct = amr.planning.createDwaConfig()
end

assert(~isempty(path), "AMR:DwaEmptyPath", "DWA requires a nonempty path.");
window = amr.planning.computeDynamicWindow(currentCommand, config);
linearSamples = linspace(window(1), window(2), config.linearSampleCount);
angularSamples = linspace(window(3), window(4), config.angularSampleCount);
bestCost = inf;
bestCommand = [0.0, 0.0];
bestTrajectory = pose;
validCandidateCount = 0;

goal = path(end, :);
goalScale = max(1.0, norm(goal - pose(1:2)));
for linearIndex = 1:numel(linearSamples)
    for angularIndex = 1:numel(angularSamples)
        candidate = [linearSamples(linearIndex), angularSamples(angularIndex)];
        trajectory = amr.planning.rolloutTrajectory(pose, candidate, ...
            config.predictionHorizon, config.rolloutSampleTime);
        if ~amr.planning.isTrajectoryCollisionFree(gridMap, trajectory) || ...
                ~stoppingTrajectoryIsFree(trajectory(end, :), candidate, ...
                gridMap, config)
            continue;
        end
        validCandidateCount = validCandidateCount + 1;
        endpoint = trajectory(end, 1:2);
        pathDistance = distanceToPolyline(endpoint, path);
        goalDistance = norm(endpoint - goal) / goalScale;
        target = selectHeadingTarget(endpoint, path);
        desiredHeading = atan2(target(2) - endpoint(2), ...
            target(1) - endpoint(1));
        headingCost = abs(wrapAngleLocal(desiredHeading - trajectory(end, 3))) / pi;
        speedReward = candidate(1) / max(config.maximumLinearVelocity, eps);
        smoothness = norm([ ...
            (candidate(1) - currentCommand(1)) / ...
                max(config.maximumLinearVelocity, eps), ...
            (candidate(2) - currentCommand(2)) / ...
                max(config.maximumAngularVelocity, eps)]);
        cost = config.pathWeight * pathDistance + ...
            config.goalWeight * goalDistance + ...
            config.headingWeight * headingCost - ...
            config.speedWeight * speedReward + ...
            config.smoothnessWeight * smoothness;
        if cost < bestCost
            bestCost = cost;
            bestCommand = candidate;
            bestTrajectory = trajectory;
        end
    end
end

command = bestCommand;
diagnostics = struct( ...
    "valid", validCandidateCount > 0, ...
    "validCandidateCount", validCandidateCount, ...
    "bestCost", bestCost, ...
    "trajectory", bestTrajectory, ...
    "window", window);
end

function isFree = stoppingTrajectoryIsFree(pose, command, gridMap, config)
isFree = true;
linearVelocity = command(1);
angularVelocity = command(2);
currentPose = pose;
while linearVelocity > 1e-6 || abs(angularVelocity) > 1e-6
    nextPose = amr.modeling.integrateDifferentialDrive(currentPose, ...
        [linearVelocity, angularVelocity], config.rolloutSampleTime);
    if ~amr.mapping.isSegmentCollisionFree(gridMap, ...
            currentPose(1:2), nextPose(1:2))
        isFree = false;
        return;
    end
    currentPose = nextPose;
    linearVelocity = max(0, linearVelocity - ...
        config.maximumLinearAcceleration * config.rolloutSampleTime);
    angularVelocity = sign(angularVelocity) * max(0, abs(angularVelocity) - ...
        config.maximumAngularAcceleration * config.rolloutSampleTime);
end
end

function target = selectHeadingTarget(point, path)
distances = vecnorm(path - point, 2, 2);
[~, nearestIndex] = min(distances);
targetIndex = min(size(path, 1), nearestIndex + 1);
target = path(targetIndex, :);
end

function distance = distanceToPolyline(point, path)
if size(path, 1) == 1
    distance = norm(point - path);
    return;
end
distance = inf;
for segmentIndex = 1:size(path, 1) - 1
    segment = path(segmentIndex + 1, :) - path(segmentIndex, :);
    denominator = dot(segment, segment);
    if denominator <= eps
        projection = path(segmentIndex, :);
    else
        fraction = dot(point - path(segmentIndex, :), segment) / denominator;
        fraction = min(max(fraction, 0), 1);
        projection = path(segmentIndex, :) + fraction * segment;
    end
    distance = min(distance, norm(point - projection));
end
end

function angle = wrapAngleLocal(angle)
angle = mod(angle + pi, 2 * pi) - pi;
end
