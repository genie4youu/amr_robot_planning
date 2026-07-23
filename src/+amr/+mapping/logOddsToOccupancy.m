function occupancy = logOddsToOccupancy(map, freeThreshold, occupiedThreshold)
%LOGODDSTOOCCUPANCY Convert log odds to probability and ternary masks.

arguments
    map struct
    freeThreshold (1, 1) double = 0.35
    occupiedThreshold (1, 1) double = 0.65
end

probability = 1 ./ (1 + exp(-map.logOdds));
occupancy = struct( ...
    "probability", probability, ...
    "free", probability <= freeThreshold, ...
    "occupied", probability >= occupiedThreshold, ...
    "unknown", probability > freeThreshold & probability < occupiedThreshold);
end
