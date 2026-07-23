function floorMap = createDemoFloorMap()
%CREATEDEMOFLOORMAP Define a small indoor floor plan for AMR playback.
% Rectangle rows use [x, y, width, height] in metres.

floorMap.bounds = [-0.50, 3.50, -0.50, 3.00];
floorMap.walls = [ ...
    -0.45, -0.45, 3.90, 0.12; ... % outer bottom
    -0.45,  2.83, 3.90, 0.12; ... % outer top
    -0.45, -0.45, 0.12, 3.40; ... % outer left
     3.33, -0.45, 0.12, 3.40; ... % outer right
     0.75,  0.45, 0.12, 2.38; ... % room partition
     0.87,  1.15, 0.83, 0.12; ... % room partition
     2.55,  0.45, 0.78, 0.12; ... % upper-right room wall
     2.55,  0.57, 0.12, 0.78];    % upper-right room wall

floorMap.obstacles = [ ...
    -0.05, 1.55, 0.40, 0.75; ... % storage rack
     1.15, 1.65, 0.35, 0.70; ... % storage rack
     2.85, 1.15, 0.28, 0.75];    % cabinet

floorMap.labels = struct( ...
    "text", {"출발/충전", "보관실", "배송 구역", "목표"}, ...
    "position", {[0.02, -0.18], [0.18, 2.50], ...
    [2.25, 2.55], [2.12, 2.18]});
floorMap.startPose = [0.0, 0.0, 0.0];
floorMap.goalPose = [2.0, 2.0, pi / 2];
end
