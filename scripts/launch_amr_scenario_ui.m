function app = launch_amr_scenario_ui(scenario, environment)
%LAUNCH_AMR_SCENARIO_UI Open the large-map AMR scenario laboratory.
%
% Examples:
%   app = launch_amr_scenario_ui("obstacle");
%   app = launch_amr_scenario_ui("battery");

arguments
    scenario = "obstacle"
    environment = "office"
end

scriptDirectory = fileparts(mfilename("fullpath"));
projectDirectory = fileparts(scriptDirectory);
sourceDirectory = fullfile(projectDirectory, "src");
addpath(scriptDirectory, sourceDirectory);

fprintf("Preparing AMR scenario UI...\n");
playbackData = simulate_amr_scenario(scenario, environment);
floorMap = amr.ui.createEnvironmentFloorMap(environment);
app = amr.ui.AmrScenarioPlaybackApp(playbackData, floorMap);
assignin("base", "amrScenarioApp", app);

fprintf("Scenario UI ready. Select another case from the dropdown when needed.\n");
end
