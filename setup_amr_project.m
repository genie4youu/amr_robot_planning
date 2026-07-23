function projectRoot = setup_amr_project()
%SETUP_AMR_PROJECT Add the public AMR project folders to the MATLAB path.

projectRoot = fileparts(mfilename("fullpath"));
addpath( ...
    fullfile(projectRoot, "scripts"), ...
    fullfile(projectRoot, "src"), ...
    fullfile(projectRoot, "tests", "unit"));

fprintf("AMR project ready: %s\n", projectRoot);
end
