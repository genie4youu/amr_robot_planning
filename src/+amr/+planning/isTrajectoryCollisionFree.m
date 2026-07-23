function isFree = isTrajectoryCollisionFree(gridMap, trajectory)
%ISTRAJECTORYCOLLISIONFREE Check every predicted segment on an inflated grid.

isFree = true;
for poseIndex = 1:size(trajectory, 1) - 1
    if ~amr.mapping.isSegmentCollisionFree(gridMap, ...
            trajectory(poseIndex, 1:2), trajectory(poseIndex + 1, 1:2))
        isFree = false;
        return;
    end
end
end
