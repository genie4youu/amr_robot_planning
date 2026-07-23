function scan = simulateLidar2D(gridMap, basePose, config)
%SIMULATELIDAR2D Generate an ideal deterministic scan from a binary grid.

arguments
    gridMap struct
    basePose (1, 3) double
    config struct = amr.sensors.createLidarConfig()
end

rotation = [cos(basePose(3)), -sin(basePose(3)); ...
    sin(basePose(3)), cos(basePose(3))];
sensorOrigin = basePose(1:2) + config.mountingOffset * rotation.';
beamCount = numel(config.angleOffsets);
worldAngles = basePose(3) + config.angleOffsets;
sampleSpacing = 0.45 / gridMap.resolution;
sampleDistances = config.minimumRange:sampleSpacing:config.maximumRange;
if sampleDistances(end) < config.maximumRange
    sampleDistances(end + 1) = config.maximumRange;
end

xSamples = sensorOrigin(1) + cos(worldAngles) .* sampleDistances;
ySamples = sensorOrigin(2) + sin(worldAngles) .* sampleDistances;
columns = floor((xSamples - gridMap.bounds(1)) * gridMap.resolution) + 1;
rows = floor((ySamples - gridMap.bounds(3)) * gridMap.resolution) + 1;
inside = rows >= 1 & rows <= size(gridMap.occupancy, 1) & ...
    columns >= 1 & columns <= size(gridMap.occupancy, 2);
occupiedSamples = false(size(inside));
insideIndices = find(inside);
linearIndices = sub2ind(size(gridMap.occupancy), ...
    rows(insideIndices), columns(insideIndices));
occupiedSamples(insideIndices) = gridMap.occupancy(linearIndices);

[hitMask, firstHitIndex] = max(occupiedSamples, [], 2);
hitMask = logical(hitMask);
ranges = repmat(config.maximumRange, beamCount, 1);
ranges(hitMask) = sampleDistances(firstHitIndex(hitMask));
hitPoints = sensorOrigin + ...
    ranges .* [cos(worldAngles), sin(worldAngles)];

scan = struct( ...
    "ranges", ranges, ...
    "angleOffsets", config.angleOffsets, ...
    "hitPoints", hitPoints, ...
    "hitMask", hitMask, ...
    "origin", sensorOrigin, ...
    "worldAngles", worldAngles);
end
