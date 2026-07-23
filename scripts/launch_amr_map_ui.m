function app = launch_amr_map_ui()
%LAUNCH_AMR_MAP_UI Simulate milestone 01 and animate the robot on a map.
%
% The returned handle can also be found in the base workspace as
% `amrMapApp`. The UI starts playing automatically.

scriptDirectory = fileparts(mfilename("fullpath"));
projectDirectory = fileparts(scriptDirectory);
sourceDirectory = fullfile(projectDirectory, "src");
addpath(scriptDirectory, sourceDirectory);

fprintf("Running amr_milestone01.slx for map playback...\n");
playbackData = simulate_amr_milestone01();
floorMap = amr.ui.createDemoFloorMap();
app = amr.ui.AmrMapPlaybackApp(playbackData, floorMap);
assignin("base", "amrMapApp", app);

fprintf("AMR map UI is ready and playback has started.\n");
fprintf("Use Play, Pause, Reset, the time slider, and playback speed controls.\n");
end
