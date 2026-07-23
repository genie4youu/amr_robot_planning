function [scan, frameDropped] = applyLidarImperfections(idealScan, config, scanIndex)
%APPLYLIDARIMPERFECTIONS Add deterministic noise and reproducible dropouts.

arguments
    idealScan struct
    config struct
    scanIndex (1, 1) double {mustBePositive, mustBeInteger}
end

scan = idealScan;
beamIndices = (1:numel(scan.ranges)).';
noisePattern = sin(12.9898 * beamIndices + 78.233 * scanIndex);
scan.ranges = scan.ranges + ...
    config.rangeNoiseStandardDeviation * noisePattern;
scan.ranges = min(max(scan.ranges, config.minimumRange), config.maximumRange);

dropoutHash = mod(37 * beamIndices + 101 * scanIndex, 1000) / 1000;
beamDropped = dropoutHash < config.beamDropoutProbability;
scan.hitMask(beamDropped) = false;
scan.ranges(beamDropped) = config.maximumRange;
scan.hitPoints = scan.origin + scan.ranges .* ...
    [cos(scan.worldAngles), sin(scan.worldAngles)];
frameDropped = config.frameDropoutPeriod > 0 && ...
    mod(scanIndex, config.frameDropoutPeriod) == 0;
end
