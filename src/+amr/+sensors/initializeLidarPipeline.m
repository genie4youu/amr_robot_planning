function state = initializeLidarPipeline(initialScan, initialTime, config)
%INITIALIZELIDARPIPELINE Initialize scan delay and freshness state.

arguments
    initialScan struct
    initialTime (1, 1) double
    config struct = amr.sensors.createLidarConfig()
end

delayCount = max(0, round(config.delaySamples));
state.delayQueue = cell(1, delayCount);
for index = 1:delayCount
    state.delayQueue{index} = initialScan;
end
state.lastOutput = initialScan;
state.lastValidTime = initialTime;
state.scanIndex = 0;
end
