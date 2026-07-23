function verify_lidar_pipeline()
%VERIFY_LIDAR_PIPELINE Verify noise, delay, dropout, and freshness behavior.

projectRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(projectRoot, "src"));
floorMap = struct("bounds", [0, 5, 0, 4], ...
    "walls", [3, 0, 0.10, 4], "obstacles", zeros(0, 4));
gridMap = amr.mapping.rasterizeFloorMap(floorMap, 20, 0, false);
config = amr.sensors.createLidarConfig();
config.frameDropoutPeriod = 3;
config.delaySamples = 1;
config.freshnessTimeout = 0.05;
idealScan = amr.sensors.simulateLidar2D(gridMap, [1, 2, 0], config);
state = amr.sensors.initializeLidarPipeline(idealScan, 0, config);

freshHistory = false(5, 1);
dropHistory = false(5, 1);
for index = 1:5
    [scan, status, state] = amr.sensors.stepLidarPipeline( ...
        idealScan, index * config.sampleTime, config, state);
    freshHistory(index) = status.fresh;
    dropHistory(index) = status.frameDropped;
    assert(all(scan.ranges >= config.minimumRange & ...
        scan.ranges <= config.maximumRange), ...
        "AMR:LidarPipelineRange", "Pipeline produced an invalid range.");
end
assert(dropHistory(3), "AMR:LidarFrameDrop", ...
    "Configured periodic frame dropout did not occur.");
assert(~freshHistory(4) && freshHistory(5), "AMR:LidarFreshness", ...
    "Watchdog did not become stale and recover after a delayed dropout.");
fprintf("LiDAR imperfection/delay/watchdog verification passed.\n");
end
