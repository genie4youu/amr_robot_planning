function [outputScan, status, state] = stepLidarPipeline( ...
        idealScan, sampleTime, config, state)
%STEPLIDARPIPELINE Apply imperfections, delay, hold-last, and watchdog.

state.scanIndex = state.scanIndex + 1;
[processedScan, frameDropped] = amr.sensors.applyLidarImperfections( ...
    idealScan, config, state.scanIndex);
if frameDropped
    newMeasurement = [];
else
    newMeasurement = processedScan;
end

if isempty(state.delayQueue)
    candidate = newMeasurement;
else
    candidate = state.delayQueue{1};
    if numel(state.delayQueue) > 1
        state.delayQueue(1:end - 1) = state.delayQueue(2:end);
    end
    state.delayQueue{end} = newMeasurement;
end

measurementUpdated = ~isempty(candidate);
if measurementUpdated
    state.lastOutput = candidate;
    state.lastValidTime = sampleTime;
end
outputScan = state.lastOutput;
age = sampleTime - state.lastValidTime;
status = struct( ...
    "fresh", age <= config.freshnessTimeout, ...
    "age", age, ...
    "frameDropped", frameDropped, ...
    "measurementUpdated", measurementUpdated, ...
    "scanIndex", state.scanIndex);
end
