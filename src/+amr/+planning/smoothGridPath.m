function smoothedPath = smoothGridPath(gridMap, path)
%SMOOTHGRIDPATH Remove intermediate A* points with free line of sight.

if size(path, 1) <= 2
    smoothedPath = path;
    return;
end

smoothedPath = path(1, :);
anchorIndex = 1;
while anchorIndex < size(path, 1)
    candidateIndex = size(path, 1);
    while candidateIndex > anchorIndex + 1 && ...
            ~amr.mapping.isSegmentCollisionFree( ...
            gridMap, path(anchorIndex, :), path(candidateIndex, :))
        candidateIndex = candidateIndex - 1;
    end
    smoothedPath(end + 1, :) = path(candidateIndex, :); %#ok<AGROW>
    anchorIndex = candidateIndex;
end
end
