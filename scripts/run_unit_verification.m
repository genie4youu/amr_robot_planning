function summary = run_unit_verification()
%RUN_UNIT_VERIFICATION Run all toolbox-free AMR algorithm checks.

scriptDirectory = fileparts(mfilename("fullpath"));
projectRoot = fileparts(scriptDirectory);
addpath( ...
    fullfile(projectRoot, "src"), ...
    fullfile(projectRoot, "tests", "unit"));

testNames = [ ...
    "verify_differential_drive"
    "verify_grid_raycast"
    "verify_local_costmap"
    "verify_dwa"
    "verify_environment_maps"
    "verify_lidar_pipeline"
    "verify_log_odds_mapping"
    "verify_pose_ekf_uncertainty"];

passed = false(size(testNames));
elapsedSeconds = zeros(size(testNames));
messages = strings(size(testNames));

for testIndex = 1:numel(testNames)
    testName = testNames(testIndex);
    startedAt = tic;
    try
        feval(testName);
        passed(testIndex) = true;
        messages(testIndex) = "PASS";
    catch exception
        messages(testIndex) = string(exception.identifier) + ": " + ...
            string(exception.message);
    end
    elapsedSeconds(testIndex) = toc(startedAt);
end

summary = table(testNames, passed, elapsedSeconds, messages);
summary.Properties.VariableNames = ...
    ["Test", "Passed", "ElapsedSeconds", "Message"];
disp(summary);

assert(all(passed), "AMR:UnitVerificationFailed", ...
    "%d of %d unit checks failed.", nnz(~passed), numel(passed));
fprintf("AMR unit verification: %d/%d PASS.\n", nnz(passed), numel(passed));
end
