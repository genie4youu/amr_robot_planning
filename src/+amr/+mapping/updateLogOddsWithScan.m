function map = updateLogOddsWithScan(map, scan)
%UPDATELOGODDSWITHSCAN Apply a binary inverse sensor model to one scan.

freeObserved = false(size(map.logOdds));
occupiedObserved = false(size(map.logOdds));
sampleSpacing = 0.45 / map.resolution;
for beamIndex = 1:numel(scan.ranges)
    range = scan.ranges(beamIndex);
    direction = [cos(scan.worldAngles(beamIndex)), ...
        sin(scan.worldAngles(beamIndex))];
    if scan.hitMask(beamIndex)
        freeLimit = max(0, range - sampleSpacing);
    else
        freeLimit = range;
    end
    distances = 0:sampleSpacing:freeLimit;
    points = scan.origin + distances.' .* direction;
    columns = floor((points(:, 1) - map.bounds(1)) * map.resolution) + 1;
    rows = floor((points(:, 2) - map.bounds(3)) * map.resolution) + 1;
    inside = rows >= 1 & rows <= size(map.logOdds, 1) & ...
        columns >= 1 & columns <= size(map.logOdds, 2);
    if any(inside)
        freeIndices = sub2ind(size(map.logOdds), rows(inside), columns(inside));
        freeObserved(unique(freeIndices)) = true;
    end
    if scan.hitMask(beamIndex)
        hitPoint = scan.hitPoints(beamIndex, :);
        column = floor((hitPoint(1) - map.bounds(1)) * map.resolution) + 1;
        row = floor((hitPoint(2) - map.bounds(3)) * map.resolution) + 1;
        if row >= 1 && row <= size(map.logOdds, 1) && ...
                column >= 1 && column <= size(map.logOdds, 2)
            occupiedObserved(row, column) = true;
        end
    end
end

freeObserved(occupiedObserved) = false;
map.logOdds(freeObserved) = map.logOdds(freeObserved) + map.freeIncrement;
map.logOdds(occupiedObserved) = map.logOdds(occupiedObserved) + ...
    map.occupiedIncrement;
map.logOdds = min(max(map.logOdds, map.minimumLogOdds), map.maximumLogOdds);
end
