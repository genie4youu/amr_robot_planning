function isFree = isSegmentCollisionFree(gridMap, startPosition, endPosition)
%ISSEGMENTCOLLISIONFREE Sample an inflated grid along a line segment.

distance = norm(endPosition - startPosition);
sampleSpacing = 0.45 / gridMap.resolution;
sampleCount = max(2, ceil(distance / sampleSpacing) + 1);
fractions = linspace(0, 1, sampleCount).';
samples = startPosition + fractions .* (endPosition - startPosition);
isFree = true;
for index = 1:sampleCount
    if amr.mapping.isWorldPointOccupied(gridMap, samples(index, :))
        isFree = false;
        return;
    end
end
end
