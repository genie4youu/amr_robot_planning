function compare_mission_supervisor_layouts(regionName)
%COMPARE_MISSION_SUPERVISOR_LAYOUTS Open the historical v07a/v07b pair.
%
%   compare_mission_supervisor_layouts("MissionRegion")

arguments
    regionName (1, 1) string = "MissionRegion"
end

comparisonFolder = string(fileparts(mfilename("fullpath")));
versionsFolder = fullfile(comparisonFolder, "..", "versions");
modelFiles = [ ...
    "amr_mission_supervisor_v07a_curved_readable_fit_2026_07_29.slx"; ...
    "amr_mission_supervisor_v07b_minimum_curvature_readable_fit_2026_07_29.slx"];

for index = 1:numel(modelFiles)
    modelPath = fullfile(versionsFolder, modelFiles(index));
    open_system(modelPath);

    [~, modelName] = fileparts(modelFiles(index));
    chartPath = modelName + "/MissionSupervisor";
    root = sfroot;
    chart = root.find("-isa", "Stateflow.Chart", ...
        "Path", char(chartPath));
    assert(isscalar(chart), "AMR:LayoutComparison:ChartNotFound", ...
        "Expected one Stateflow chart at %s.", chartPath);

    regions = chart.find("-isa", "Stateflow.State", ...
        "Name", char(regionName));
    regions = regions([regions.IsSubchart]);
    assert(isscalar(regions), "AMR:LayoutComparison:RegionNotFound", ...
        "Expected one Subchart named %s in %s.", regionName, modelName);

    view(regions);
    drawnow;
    fitToView(regions);
    drawnow;
    fprintf("Opened %s -> %s\n", modelName, regionName);
end

fprintf("Historical versions v07a and v07b are open. Switch Stateflow tabs to compare them.\n");
end
