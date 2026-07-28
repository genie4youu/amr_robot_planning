function layoutSummary = layout_amr_mission_supervisor(options)
%LAYOUT_AMR_MISSION_SUPERVISOR Apply the project Stateflow visual style.
%   This function changes only Stateflow presentation properties. State
%   hierarchy, exact labels, transition endpoints, data, and execution
%   order are verified before the model is saved.

arguments
    options.CreateBackup (1,1) logical = true
    options.TransitionRoutingOnly (1,1) logical = false
    options.ModelPath (1,1) string = ""
    options.AllowPrimaryModelWrite (1,1) logical = false
    options.EnforceGraphicalGate (1,1) logical = true
end

scriptFolder = fileparts(mfilename("fullpath"));
projectRoot = fileparts(scriptFolder);
primaryModelPath = string(fullfile(projectRoot, "models", "prototypes", ...
    "amr_mission_supervisor.slx"));
if strlength(options.ModelPath) == 0
    modelPath = primaryModelPath;
elseif isfile(options.ModelPath)
    modelPath = options.ModelPath;
else
    modelPath = string(fullfile(projectRoot, options.ModelPath));
end
assert(isfile(modelPath), "AMR:Layout:ModelNotFound", ...
    "Model file was not found: %s", modelPath);
if isfile(primaryModelPath) && ...
        isfile(modelPath) && ...
        string(java.io.File(char(primaryModelPath)).getCanonicalPath()) == ...
        string(java.io.File(char(modelPath)).getCanonicalPath())
    assert(options.AllowPrimaryModelWrite, ...
        "AMR:Layout:PrimaryModelWriteBlocked", ...
        "The validated primary model is protected. Pass an explicit " + ...
        "candidate ModelPath, or set AllowPrimaryModelWrite=true.");
end
[~, modelBaseName] = fileparts(modelPath);
modelName = string(modelBaseName);
chartPath = modelName + "/MissionSupervisor";

open_system(modelPath);
assert(strcmp(get_param(modelName, "Dirty"), "off"), ...
    "AMR:Layout:UnsavedModel", ...
    "Save or discard unrelated model changes before applying layout.");

chart = findChart(chartPath);
logicBefore = captureLogicSignature(chart);
statePositionsBefore = captureStatePositions(chart);
stateLabelsBefore = captureExactStateLabels(chart);

backupPath = "";
if options.CreateBackup
    backupPath = createModelBackup(projectRoot, modelPath);
end

chart.StateFont.Size = 10;
chart.TransitionFont.Size = 9;

stateLayout = createStateLayout();
if ~options.TransitionRoutingOnly
    applyStateLayout(chart, stateLayout);
    verifyStateLayoutApplied(chart, stateLayout);
    verifyExactStateLabelsPreserved( ...
        stateLabelsBefore, captureExactStateLabels(chart));
end

transitionLayout = createTransitionLayout();
transitionLayout = attachCanonicalTransitionGeometry(transitionLayout);
transitionLayout.ScopeKey = transitionScopeKeys( ...
    chart, transitionLayout.SSID);
if options.TransitionRoutingOnly
    transitionLayout = translateRoutesToLiveScopes( ...
        chart, stateLayout, transitionLayout);
end
transitionLayout = applyTransitionLayout(chart, transitionLayout);
verifyTransitionGeometryFinite(chart);
restoreExecutionOrder(chart, logicBefore);

logicAfter = captureLogicSignature(chart);
verifyLogicPreserved(logicBefore, logicAfter);
if options.TransitionRoutingOnly
    verifyStatePositionsPreserved( ...
        statePositionsBefore, captureStatePositions(chart));
    verifyExactStateLabelsPreserved( ...
        stateLabelsBefore, captureExactStateLabels(chart));
else
    verifyStateLayoutApplied(chart, stateLayout);
end
verifyEveryGraphicalObjectConfigured(chart, stateLayout, transitionLayout);

preSaveReport = amr.stateflow.inspectGraphicalLayout( ...
    modelName, chart);
if options.EnforceGraphicalGate
    verifyGraphicalGate(preSaveReport);
end

try
    save_system(modelName);

    statePositionsBeforeReload = captureStatePositions(chart);
    stateLabelsBeforeReload = captureExactStateLabels(chart);
    logicBeforeReload = captureLogicSignature(chart);
    close_system(modelName, 0);
    open_system(modelPath);
    chart = findChart(chartPath);

    statePositionsAfterReload = captureStatePositions(chart);
    verifyExactStateLabelsPreserved( ...
        stateLabelsBeforeReload, captureExactStateLabels(chart));
    verifyLogicPreserved(logicBeforeReload, captureLogicSignature(chart));
    if options.TransitionRoutingOnly
        verifyStatePositionsPreserved( ...
            statePositionsBeforeReload, statePositionsAfterReload);
        verifyTransitionGeometryPersisted(chart, transitionLayout);
        verifyStatePositionsPreserved( ...
            statePositionsBefore, captureStatePositions(chart));
        verifyExactStateLabelsPreserved( ...
            stateLabelsBefore, captureExactStateLabels(chart));
    else
        reloadOffsets = verifyScopedStateTranslation( ...
            chart, statePositionsBeforeReload, statePositionsAfterReload);
        verifyTransitionGeometryPersisted( ...
            chart, transitionLayout, reloadOffsets);
    end

    postSaveReport = amr.stateflow.inspectGraphicalLayout( ...
        modelName, chart);
    if options.EnforceGraphicalGate
        verifyGraphicalGate(postSaveReport);
    end
catch exception
    restoreModelBackup(modelName, modelPath, backupPath);
    rethrow(exception);
end

fitAllGraphicalScopes(chart, modelName);

layoutSummary.statePositions = stateLayout;
layoutSummary.transitionGeometry = transitionLayout;
layoutSummary.logicPreserved = true;
layoutSummary.statePositionsPreserved = options.TransitionRoutingOnly;
layoutSummary.graphicalReport = postSaveReport;
layoutSummary.modelPath = string(modelPath);

fprintf( ...
    "Stateflow graphical layout applied | states %d | transitions %d | logic preserved.\n", ...
    height(stateLayout), height(transitionLayout));
end

function fitAllGraphicalScopes(chart, modelName)
dirtyBeforeView = string(get_param(modelName, "Dirty"));
states = chart.find("-isa", "Stateflow.State");
for state = reshape(states, 1, [])
    if state.IsSubchart
        view(state);
        fitToView(state);
    end
end
view(chart);
fitToView(chart);
assert(string(get_param(modelName, "Dirty")) == dirtyBeforeView, ...
    "AMR:Layout:ViewChangedModel", ...
    "view/fitToView must not modify the model.");
end

function chart = findChart(chartPath)
root = sfroot;
chart = root.find("-isa", "Stateflow.Chart", "Path", char(chartPath));
assert(isscalar(chart), "AMR:Layout:ChartNotFound", ...
    "Expected one Stateflow chart at %s.", chartPath);
end

function backupPath = createModelBackup(projectRoot, modelPath)
backupFolder = fullfile(projectRoot, "work", "backups");
if ~isfolder(backupFolder)
    mkdir(backupFolder);
end
timestamp = string(datetime("now", Format="yyyyMMdd_HHmmss"));
[~, modelBaseName, modelExtension] = fileparts(modelPath);
backupPath = string(fullfile(backupFolder, ...
    modelBaseName + "_pre_layout_" + timestamp + modelExtension));
[copied, message] = copyfile(modelPath, backupPath);
assert(copied, "AMR:Layout:BackupFailed", "%s", message);
fprintf("Layout backup: %s\n", backupPath);
end

function restoreModelBackup(modelName, modelPath, backupPath)
if strlength(backupPath) == 0
    return
end

if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
[restored, message] = copyfile(backupPath, modelPath, "f");
assert(restored, "AMR:Layout:BackupRestoreFailed", ...
    "Layout verification failed and backup restoration also failed: %s", ...
    message);
open_system(modelPath);
fprintf("Layout verification failed; restored backup: %s\n", backupPath);
end

function verifyGraphicalGate(report)
assert(report.HardViolationCount == 0, ...
    "AMR:Layout:HardGraphicalViolation", ...
    "%s", report.HardDiagnostic);
assert(report.ExactRoutingViolationCount == 0, ...
    "AMR:Layout:ExactRoutingViolation", ...
    "%s", report.RoutingDiagnostic);
end

function stateLayout = createStateLayout()
% SSID, X, Y, Width, Height, FontSize
layoutValues = [ ...
    43,   80,  180,  600, 300, 10
    44,  820,  180,  600, 300, 10
    45, 1600,  180, 1900,1120, 10
    46, 3680,  180,  700, 300, 10
    48,  500, 1850,  900, 360, 10
    47, 2450, 1850, 1100, 360, 10
    62, 1660,  300,  820, 500, 10
   118, 2580,  300,  860, 500, 10
    65, 1660,  850,  520, 320, 10
    66, 2240,  850,  520, 320, 10
    64, 2820,  850,  560, 320, 10
    67,   80,  100,  300, 120, 10
    68,  470,  100,  320, 120, 10
    69,  880,  100,  340, 120, 10
    70, 1310,  100,  300, 120, 10
    71, 1700,  100,  340, 120, 10
    72, 2130,  100,  320, 120, 10
    73, 2540,  100,  320, 120, 10
    76, 2950,  100,  300, 120, 10
    75,  470,  520, 2780, 140, 10
   119,   80,  100,  300, 130, 10
   120,  530,  100,  330, 150, 10
   121, 1040,  100,  380, 160, 10
   122, 1040,  450,  330, 150, 10
   123,  540,  370,  400, 250, 10
   124,   80,  450,  360, 170, 10
   139,   80,  100,  300, 120, 10
   140,  480,  100,  300, 120, 10
   141,  880,  100,  340, 130, 10
   142,  280,  400,  360, 140, 10
   143,  860,  400,  340, 140, 10
   152,   80,  100,  320, 120, 10
   153,  500,  100,  320, 120, 10
   154,  290,  400,  400, 150, 10
   161,   80,  100,  320, 120, 10
   162,  500,  100,  340, 120, 10
   163,  290,  400,  420, 150, 10];

stateLayout = array2table(layoutValues, VariableNames=[ ...
    "SSID", "X", "Y", "Width", "Height", "FontSize"]);
end

function applyStateLayout(chart, stateLayout)
scopeKeys = stateScopeKeys(chart, stateLayout.SSID);
orderedScopeKeys = unique(scopeKeys, "stable");
for scopeKey = reshape(orderedScopeKeys, 1, [])
    scopeRows = find(scopeKeys == scopeKey);
    for rowIndex = reshape(scopeRows, 1, [])
        state = chart.find("-isa", "Stateflow.State", ...
            "SSIdNumber", stateLayout.SSID(rowIndex));
        assert(isscalar(state), "AMR:Layout:StateNotFound", ...
            "State SSID %d was not found.", stateLayout.SSID(rowIndex));
        state.Position = [ ...
            stateLayout.X(rowIndex), ...
            stateLayout.Y(rowIndex), ...
            stateLayout.Width(rowIndex), ...
            stateLayout.Height(rowIndex)];
        state.FontSize = stateLayout.FontSize(rowIndex);
    end
    verifyStateLayoutRowsApplied(chart, stateLayout(scopeRows, :));
end
end

function transitionLayout = createTransitionLayout()
% SSID, SourceOClock, DestinationOClock, MidX, MidY,
% LabelX, LabelY, LabelWidth, LabelHeight, FontSize
layoutValues = [ ...
    49, NaN,12.0,  380,   50,  379,   30,   2,16,9
    50, 6.0,10.5,  500, 1250,  260, 1350, 300,54,9
    51, 3.0, 9.0,  750,  330,  690,   80, 330,36,9
    52, 6.2,12.2, 1100, 1150,  760, 1480, 340,36,9
    53, 3.0, 9.0, 1510,  330, 1450,  110, 610,36,9
    54, 7.2, 2.5, 1600, 1500, 1420, 1480, 160,20,9
    55, 6.4,10.0, 2600, 1600, 3560, 1450, 800,54,9
    56, 6.1,10.8, 2750, 1600, 3560, 1515, 800,54,9
    57, 5.8,11.6, 2900, 1600, 3560, 1580, 800,54,9
    58, 3.0, 9.0, 3590,  330, 3510,   80, 180,20,9
    59,12.0,12.0, 2200,   20, 2150,    0, 100,20,9
    60, 9.0, 3.0, 1500, 2380, 1600, 2100, 700,100,9
    61, 1.0, 5.0, 1300, 1280,    0, 1450, 300,200,9
   170, 5.2, 1.2, 3200, 1600, 3560, 1645, 800,54,9
   171, 5.5, 0.4, 3050, 1600, 3560, 1710, 800,54,9
    77, NaN,12.0,  230,   40,  229,   20,   2,16,9
    78, 3.0, 9.0,  425,  160,  390,   50, 130,20,9
    79, 3.0, 9.0,  835,  160,  800,   75, 130,20,9
    80, 6.0,10.7,  650,  370,  500,  400, 110,20,9
    81, 3.0, 9.0, 1265,  160, 1230,   50, 130,20,9
    82, 3.0, 9.0, 1655,  160, 1620,   50, 150,20,9
    83, 6.5,11.4, 1460,  370, 1260,  420, 100,20,9
    84, 3.0, 9.0, 2085,  160, 2050,   50, 130,20,9
    85, 3.0, 9.0, 2495,  160, 2460,   75, 150,20,9
    86, 6.5, 0.6, 2290,  370, 2200,  440, 100,20,9
    87, 3.0, 9.0, 2905,  160, 2870,   50, 130,20,9
    88,12.0,12.0, 1650,   20, 1450,  -30, 500,36,9
    89, 9.0, 6.0,   20,  400,   10,  380, 100,20,9
    90, 6.0,11.0, 1050,  370,  900,  400, 130,20,9
    91, 5.5,11.6, 1440,  370, 1500,  450, 130,20,9
    92, 6.0,12.0, 1870,  370, 1750,  400, 130,20,9
    93, 5.5, 0.4, 2270,  370, 2050,  400, 130,20,9
    94, 6.0, 1.0, 2700,  370, 2600,  400, 130,20,9
   125, NaN,12.0,  230,   40,  229,   20,   2,16,9
   126, 3.0, 9.0,  455,  165,   80,  270, 400,54,9
   127, 3.0, 9.0,  950,  175,  870,  110, 160,36,9
   128, 6.5,11.5,  680,  310,  500,  330, 100,36,9
   129, 5.5, 0.5,  755,  310,  500,  300, 100,20,9
   130, 6.0,12.0, 1160,  355, 1040,  370, 130,20,9
   131, 7.5, 1.5,  980,  310,  950,  335, 160,20,9
   132,12.0,12.0,  750,   30,  600,  -45, 650,36,9
   133,12.0, 6.0, 1300,  355, 1200,  370, 240,20,9
   134, 9.0, 3.0,  990,  510,  850,  635, 140,20,9
   135, 8.0, 2.5,  990,  565, 1050,  635, 100,20,9
   136,11.0, 7.0,  607,  310,   80,  330, 360,20,9
   137, 1.0, 5.0,  792,  310,   80,  355, 360,36,9
   138, 9.0, 3.0,  490,  510,  450,  650, 100,20,9
   144, NaN,12.0,  230,   40,  229,   20,   2,16,9
   145, 3.0, 9.0,  440,  160,  385,  110,  90,36,9
   146, 3.0, 9.0,  830,  160,  780,   50, 150,20,9
   147,12.0,12.0,  440,   40,  350,   15, 130,20,9
   148, 6.0,12.0, 1030,  310,  970,  280, 140,20,9
   149, 7.0, 2.0,  760,  310,  700,  280, 120,20,9
   150, 3.0, 9.0,  750,  470,  700,  440, 140,20,9
   151, 6.0, 9.0,   20,  620,   80,  590, 150,20,9
   155, NaN,12.0,  240,   40,  239,   20,   2,16,9
   156, 6.0,10.0,  240,  300,   40,  580, 650,36,9
   157, 3.0, 9.0,  450,  160,  405,  110,  90,36,9
   158, 6.0, 2.0,  760,  300,   40,  625, 650,36,9
   159,12.0,12.0,  450,   40,  350,   15, 260,20,9
   160, 9.0, 9.0,   20,  300,   40,  670, 780,36,9
   164, NaN,12.0,  240,   40,  239,   20,   2,16,9
   165, 6.0,10.0,  240,  300,  200,  280, 150,20,9
   166, 3.0, 9.0,  450,  160,  850,  330, 170,90,9
   167, 6.0, 2.0,  760,  300,  700,  280, 150,20,9
   168,12.0,12.0,  460,   40,  850,  230, 170,90,9
   169, 7.2, 1.2,  650,  320,  700,  330, 100,20,9];

transitionLayout = array2table(layoutValues, VariableNames=[ ...
    "SSID", "SourceOClock", "DestinationOClock", "MidX", "MidY", ...
    "LabelX", "LabelY", "LabelWidth", "LabelHeight", "FontSize"]);
transitionLayout = addRoutingMetadata(transitionLayout);
end

function transitionLayout = addRoutingMetadata(transitionLayout)
% Every transition receives one and only one project-standard route type.
transitionLayout.RoutingType = ...
    repmat("", height(transitionLayout), 1);

defaultSsids = [49, 77, 125, 144, 155, 164];
horizontalSsids = [ ...
    51, 53, 58, 78, 79, 81, 84, 85, 87, ...
    126, 127, 134, 135, 138, 146, 150];
verticalSsids = [ ...
    50, 54, 55, 56, 57, 82, 86, 88, 93, 94, 131, 148, ...
    158, 165, 167, 169, 170, 171];
bidirectionalSsids = [ ...
    52, 61, 128, 129, 130, 133, 136, 137, ...
    145, 147, 156, 157, 159, 160, 166, 168];
longOuterSsids = [ ...
    59, 60, 80, 83, 89, ...
    90, 91, 92, 132, 149, 151];

transitionLayout.RoutingType( ...
    ismember(transitionLayout.SSID, defaultSsids)) = "Default";
transitionLayout.RoutingType( ...
    ismember(transitionLayout.SSID, horizontalSsids)) = ...
    "AdjacentHorizontal";
transitionLayout.RoutingType( ...
    ismember(transitionLayout.SSID, verticalSsids)) = ...
    "AdjacentVertical";
transitionLayout.RoutingType( ...
    ismember(transitionLayout.SSID, bidirectionalSsids)) = ...
    "Bidirectional";
transitionLayout.RoutingType( ...
    ismember(transitionLayout.SSID, longOuterSsids)) = "LongOuter";

allowedTypes = [ ...
    "AdjacentHorizontal", "AdjacentVertical", "Bidirectional", ...
    "LongOuter", "SelfLoop", "Default"];
assert(all(ismember(transitionLayout.RoutingType, allowedTypes)), ...
    "AMR:Layout:UnclassifiedRoutingType", ...
    "Every transition must use one of the six standard RoutingType values.");
assert(numel(unique(transitionLayout.SSID)) == height(transitionLayout), ...
    "AMR:Layout:DuplicateTransitionRow", ...
    "A transition may appear only once in the routing table.");

transitionLayout.DirectionRole = ...
    repmat("Primary", height(transitionLayout), 1);
forwardSsids = [52, 128, 129, 130, 145, 156, 157, 166];
returnSsids = [61, 133, 136, 137, 147, 159, 160, 168];
parallelSsids = [83, 91, 93, 135, 169];
transitionLayout.DirectionRole( ...
    ismember(transitionLayout.SSID, defaultSsids)) = "Default";
transitionLayout.DirectionRole( ...
    ismember(transitionLayout.SSID, forwardSsids)) = "Forward";
transitionLayout.DirectionRole( ...
    ismember(transitionLayout.SSID, returnSsids)) = "Return";
transitionLayout.DirectionRole( ...
    ismember(transitionLayout.SSID, parallelSsids)) = "Parallel";

transitionLayout.ParallelGroup = ...
    repmat("", height(transitionLayout), 1);
parallelGroupSsids = { ...
    [83, 91], [86, 93], [128, 129, 136, 137], ...
    [134, 135], [167, 169]};
parallelGroupNames = [ ...
    "LoadingToAborting", "UnloadingToAborting", ...
    "PlanningRecovery", "ReplanningToRecovery", ...
    "DegradedToFaultRequest"];
for groupIndex = 1:numel(parallelGroupSsids)
    transitionLayout.ParallelGroup( ...
        ismember(transitionLayout.SSID, ...
        parallelGroupSsids{groupIndex})) = ...
        parallelGroupNames(groupIndex);
end

transitionLayout.LaneName = repmat("Direct", height(transitionLayout), 1);
laneSsids = [ ...
    59, 60, 80, 83, 89, 90, 91, 92, ...
    132, 149, 151, 160];
laneNames = [ ...
    "MainTop1", "MainReturnGap1", ...
    "MissionLeft1", "MissionRight2", "MissionLeft2", ...
    "MissionBottom1", ...
    "MissionRight3", "MissionBottom2", "NavigationTop1", ...
    "EnergyRight1", "EnergyLeft1", "SafetyLeft1"];
for laneIndex = 1:numel(laneSsids)
    transitionLayout.LaneName( ...
        transitionLayout.SSID == laneSsids(laneIndex)) = ...
        laneNames(laneIndex);
end

transitionLayout.MidPointPolicy = ...
    repmat("Fixed", height(transitionLayout), 1);
endpointAverageSsids = [ ...
    51, 52, 53, 54, 55, 56, 57, 58, 171, ...
    78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 90, 91, 92, 93, 94, ...
    126, 127, 128, 129, 131, 134, 138, ...
    145, 146, 148, 150, ...
    157, 158, 165, 166, 167, 169, 170];
transitionLayout.MidPointPolicy( ...
    ismember(transitionLayout.SSID, endpointAverageSsids)) = ...
    "EndpointAverage";

transitionLayout.GeometryApplyOrder = ...
    repmat("DSM", height(transitionLayout), 1);
destinationPrioritySsids = [54, 55, 56, 57, 89, 130, 132, 160, 170, 171];
transitionLayout.GeometryApplyOrder( ...
    ismember(transitionLayout.SSID, destinationPrioritySsids)) = "SDM";
fixedEndpointSsids = 82;
transitionLayout.GeometryApplyOrder( ...
    ismember(transitionLayout.SSID, fixedEndpointSsids)) = "MSD";
sourcePrioritySsids = zeros(1, 0);
transitionLayout.GeometryApplyOrder( ...
    ismember(transitionLayout.SSID, sourcePrioritySsids)) = "DMS";
destinationFinalSsids = [50, 61];
transitionLayout.GeometryApplyOrder( ...
    ismember(transitionLayout.SSID, destinationFinalSsids)) = "SMD";
end

function transitionLayout = attachCanonicalTransitionGeometry( ...
        transitionLayout)
transitionLayout.CanonicalMidX = transitionLayout.MidX;
transitionLayout.CanonicalMidY = transitionLayout.MidY;
transitionLayout.CanonicalLabelX = transitionLayout.LabelX;
transitionLayout.CanonicalLabelY = transitionLayout.LabelY;
transitionLayout.ScopeOffsetX = zeros(height(transitionLayout), 1);
transitionLayout.ScopeOffsetY = zeros(height(transitionLayout), 1);
end

function transitionLayout = translateRoutesToLiveScopes( ...
        chart, stateLayout, transitionLayout)
stateScopes = stateScopeKeys(chart, stateLayout.SSID);
transitionScopes = transitionLayout.ScopeKey;
scopeKeys = unique(transitionScopes, "stable");
positionTolerance = 0.5;

for scopeKey = reshape(scopeKeys, 1, [])
    stateRows = find(stateScopes == scopeKey);
    transitionRows = find(transitionScopes == scopeKey);
    assert(~isempty(stateRows), "AMR:Layout:ScopeWithoutState", ...
        "Graphical scope %s has transitions but no configured states.", ...
        scopeKey);

    livePositions = zeros(numel(stateRows), 4);
    for localIndex = 1:numel(stateRows)
        rowIndex = stateRows(localIndex);
        state = chart.find("-isa", "Stateflow.State", ...
            "SSIdNumber", stateLayout.SSID(rowIndex));
        livePositions(localIndex, :) = double(state.Position);
    end
    canonicalPositions = [ ...
        stateLayout.X(stateRows), stateLayout.Y(stateRows), ...
        stateLayout.Width(stateRows), stateLayout.Height(stateRows)];
    sizeDifference = livePositions(:, 3:4) - ...
        canonicalPositions(:, 3:4);
    assert(all(abs(sizeDifference) <= positionTolerance, "all"), ...
        "AMR:Layout:LiveStateSizeDiffersFromStandard", ...
        "State sizes in scope %s differ from the canonical layout.", ...
        scopeKey);

    positionOffsets = livePositions(:, 1:2) - ...
        canonicalPositions(:, 1:2);
    scopeOffset = median(positionOffsets, 1);
    assert(all(abs(positionOffsets - scopeOffset) <= ...
        positionTolerance, "all"), ...
        "AMR:Layout:NonuniformScopeTranslation", ...
        "States in scope %s do not share one canonical translation.", ...
        scopeKey);

    transitionLayout.MidX(transitionRows) = ...
        transitionLayout.CanonicalMidX(transitionRows) + scopeOffset(1);
    transitionLayout.MidY(transitionRows) = ...
        transitionLayout.CanonicalMidY(transitionRows) + scopeOffset(2);
    transitionLayout.LabelX(transitionRows) = ...
        transitionLayout.CanonicalLabelX(transitionRows) + scopeOffset(1);
    transitionLayout.LabelY(transitionRows) = ...
        transitionLayout.CanonicalLabelY(transitionRows) + scopeOffset(2);
    transitionLayout.ScopeOffsetX(transitionRows) = scopeOffset(1);
    transitionLayout.ScopeOffsetY(transitionRows) = scopeOffset(2);
end
end

function transitionLayout = applyTransitionLayout(chart, transitionLayout)
transitionLayout.AppliedSourceOClock = ...
    NaN(height(transitionLayout), 1);
transitionLayout.AppliedDestinationOClock = ...
    NaN(height(transitionLayout), 1);
transitionLayout.AppliedSourceX = NaN(height(transitionLayout), 1);
transitionLayout.AppliedSourceY = NaN(height(transitionLayout), 1);
transitionLayout.AppliedMidX = NaN(height(transitionLayout), 1);
transitionLayout.AppliedMidY = NaN(height(transitionLayout), 1);
transitionLayout.AppliedDestinationX = NaN(height(transitionLayout), 1);
transitionLayout.AppliedDestinationY = NaN(height(transitionLayout), 1);
statePositionsBeforeRouting = captureStatePositions(chart);
scopeKeys = transitionScopeKeys(chart, transitionLayout.SSID);
orderedScopeKeys = unique(scopeKeys, "stable");
for scopeKey = reshape(orderedScopeKeys, 1, [])
    scopeRows = find(scopeKeys == scopeKey);
    for rowIndex = reshape(scopeRows, 1, [])
        transition = chart.find("-isa", "Stateflow.Transition", ...
            "SSIdNumber", transitionLayout.SSID(rowIndex));
        assert(isscalar(transition), "AMR:Layout:TransitionNotFound", ...
            "Transition SSID %d was not found.", ...
            transitionLayout.SSID(rowIndex));

        applyTransitionPathProperties( ...
            transition, transitionLayout, rowIndex);
        transition.LabelPosition = [ ...
            transitionLayout.LabelX(rowIndex), ...
            transitionLayout.LabelY(rowIndex), ...
            transitionLayout.LabelWidth(rowIndex), ...
            transitionLayout.LabelHeight(rowIndex)];
        transition.FontSize = transitionLayout.FontSize(rowIndex);

        sourceEndpoint = double(transition.SourceEndpoint);
        midpoint = double(transition.MidPoint);
        destinationEndpoint = double(transition.DestinationEndpoint);
        if ~isempty(transition.Source)
            transitionLayout.AppliedSourceOClock(rowIndex) = ...
                double(transition.SourceOClock);
        end
        transitionLayout.AppliedDestinationOClock(rowIndex) = ...
            double(transition.DestinationOClock);
        transitionLayout.AppliedSourceX(rowIndex) = sourceEndpoint(1);
        transitionLayout.AppliedSourceY(rowIndex) = sourceEndpoint(2);
        transitionLayout.AppliedMidX(rowIndex) = midpoint(1);
        transitionLayout.AppliedMidY(rowIndex) = midpoint(2);
        transitionLayout.AppliedDestinationX(rowIndex) = ...
            destinationEndpoint(1);
        transitionLayout.AppliedDestinationY(rowIndex) = ...
            destinationEndpoint(2);
    end
    verifyStatePositionsPreserved( ...
        statePositionsBeforeRouting, captureStatePositions(chart));
end
end

function applyTransitionPathProperties( ...
        transition, transitionLayout, rowIndex)
sourceOClock = transitionLayout.SourceOClock(rowIndex);
destinationOClock = transitionLayout.DestinationOClock(rowIndex);
applyOrder = char(transitionLayout.GeometryApplyOrder(rowIndex));
assert(numel(applyOrder) == 3 && ...
    isequal(sort(applyOrder), sort('DSM')), ...
    "AMR:Layout:InvalidGeometryApplyOrder", ...
    "Transition SSID %d must apply D, S, and M exactly once.", ...
    transitionLayout.SSID(rowIndex));

for propertyCode = applyOrder
    switch propertyCode
        case 'D'
            transition.DestinationOClock = destinationOClock;
        case 'S'
            if ~isnan(sourceOClock)
                transition.SourceOClock = sourceOClock;
            end
        case 'M'
            if transitionLayout.MidPointPolicy(rowIndex) == ...
                    "EndpointAverage"
                sourceEndpoint = double(transition.SourceEndpoint);
                destinationEndpoint = ...
                    double(transition.DestinationEndpoint);
                midpoint = ...
                    (sourceEndpoint + destinationEndpoint) / 2;
            else
                midpoint = [ ...
                    transitionLayout.MidX(rowIndex), ...
                    transitionLayout.MidY(rowIndex)];
            end
            transition.MidPoint = midpoint;
        otherwise
            error("AMR:Layout:UnknownGeometryProperty", ...
                "Unknown transition geometry property code '%s'.", ...
                propertyCode);
    end
end
end

function scopeKeys = stateScopeKeys(chart, stateSsids)
scopeKeys = strings(numel(stateSsids), 1);
for rowIndex = 1:numel(stateSsids)
    state = chart.find("-isa", "Stateflow.State", ...
        "SSIdNumber", stateSsids(rowIndex));
    assert(isscalar(state), "AMR:Layout:StateNotFound", ...
        "State SSID %d was not found.", stateSsids(rowIndex));
    scopeKeys(rowIndex) = subviewerKey(state);
end
end

function scopeKeys = transitionScopeKeys(chart, transitionSsids)
scopeKeys = strings(numel(transitionSsids), 1);
for rowIndex = 1:numel(transitionSsids)
    transition = chart.find("-isa", "Stateflow.Transition", ...
        "SSIdNumber", transitionSsids(rowIndex));
    assert(isscalar(transition), "AMR:Layout:TransitionNotFound", ...
        "Transition SSID %d was not found.", transitionSsids(rowIndex));
    scopeKeys(rowIndex) = subviewerKey(transition);
end
end

function scopeKey = subviewerKey(object)
subviewer = object.Subviewer;
if isa(subviewer, "Stateflow.Chart")
    scopeKey = "Chart";
elseif isa(subviewer, "Stateflow.State") && subviewer.IsSubchart
    scopeKey = "S" + string(subviewer.SSIdNumber);
else
    error("AMR:Layout:UnsupportedSubviewer", ...
        "Expected a Chart or subchart State in the Subviewer property.");
end
end

function verifyStateLayoutApplied(chart, stateLayout)
verifyStateLayoutRowsApplied(chart, stateLayout);
end

function verifyStateLayoutRowsApplied(chart, stateLayoutRows)
for rowIndex = 1:height(stateLayoutRows)
    state = chart.find("-isa", "Stateflow.State", ...
        "SSIdNumber", stateLayoutRows.SSID(rowIndex));
    expectedPosition = [ ...
        stateLayoutRows.X(rowIndex), ...
        stateLayoutRows.Y(rowIndex), ...
        stateLayoutRows.Width(rowIndex), ...
        stateLayoutRows.Height(rowIndex)];
    assert(isequal(double(state.Position), expectedPosition), ...
        "AMR:Layout:StateLayoutNotApplied", ...
        "State SSID %d did not retain its specified Position.", ...
        stateLayoutRows.SSID(rowIndex));
    assert(double(state.FontSize) == stateLayoutRows.FontSize(rowIndex), ...
        "AMR:Layout:StateFontNotApplied", ...
        "State SSID %d did not retain its specified FontSize.", ...
        stateLayoutRows.SSID(rowIndex));
end
end

function verifyTransitionGeometryFinite(chart)
transitions = chart.find("-isa", "Stateflow.Transition");
for transition = reshape(transitions, 1, [])
    geometry = [ ...
        transition.SourceEndpoint
        transition.MidPoint
        transition.DestinationEndpoint
        ];
    assert(all(isfinite(geometry), "all"), ...
        "AMR:Layout:NonfiniteTransitionGeometry", ...
        "Transition SSID %d has nonfinite graphical geometry.", ...
        transition.SSIdNumber);
end
end

function verifyTransitionGeometryPersisted( ...
        chart, transitionLayout, reloadOffsets)
if nargin < 3
    reloadOffsets = table( ...
        strings(0, 1), zeros(0, 1), zeros(0, 1), ...
        VariableNames=["ScopeKey", "OffsetX", "OffsetY"]);
end
geometryTolerance = 0.5;
oClockTolerance = 1e-6;
for rowIndex = 1:height(transitionLayout)
    transition = chart.find("-isa", "Stateflow.Transition", ...
        "SSIdNumber", transitionLayout.SSID(rowIndex));
    assert(isscalar(transition), "AMR:Layout:TransitionNotFound", ...
        "Transition SSID %d was not found after reload.", ...
        transitionLayout.SSID(rowIndex));

    if ~isempty(transition.Source)
        sourceDifference = cyclicOClockDifference( ...
            double(transition.SourceOClock), ...
            transitionLayout.AppliedSourceOClock(rowIndex));
        assert(sourceDifference <= oClockTolerance, ...
            "AMR:Layout:SourceOClockDidNotPersist", ...
            "Transition SSID %d SourceOClock changed after reload.", ...
            transitionLayout.SSID(rowIndex));
    end
    destinationDifference = cyclicOClockDifference( ...
        double(transition.DestinationOClock), ...
        transitionLayout.AppliedDestinationOClock(rowIndex));
    assert(destinationDifference <= oClockTolerance, ...
        "AMR:Layout:DestinationOClockDidNotPersist", ...
        "Transition SSID %d DestinationOClock changed after reload.", ...
        transitionLayout.SSID(rowIndex));

    scopeOffset = [0, 0];
    offsetRow = find(reloadOffsets.ScopeKey == ...
        transitionLayout.ScopeKey(rowIndex));
    if ~isempty(offsetRow)
        assert(isscalar(offsetRow), ...
            "AMR:Layout:DuplicateReloadScopeOffset", ...
            "Scope %s has more than one reload offset.", ...
            transitionLayout.ScopeKey(rowIndex));
        scopeOffset = [ ...
            reloadOffsets.OffsetX(offsetRow), ...
            reloadOffsets.OffsetY(offsetRow)];
    end

    expectedGeometry = [ ...
        transitionLayout.AppliedSourceX(rowIndex), ...
        transitionLayout.AppliedSourceY(rowIndex)
        transitionLayout.AppliedMidX(rowIndex), ...
        transitionLayout.AppliedMidY(rowIndex)
        transitionLayout.AppliedDestinationX(rowIndex), ...
        transitionLayout.AppliedDestinationY(rowIndex)];
    expectedGeometry = expectedGeometry + scopeOffset;
    actualGeometry = double([ ...
        transition.SourceEndpoint
        transition.MidPoint
        transition.DestinationEndpoint
        ]);
    assert(all(abs(actualGeometry - expectedGeometry) <= ...
        geometryTolerance, "all"), ...
        "AMR:Layout:TransitionPathDidNotPersist", ...
        "Transition SSID %d path geometry changed after reload.", ...
        transitionLayout.SSID(rowIndex));

    expectedLabelPosition = [ ...
        transitionLayout.LabelX(rowIndex) + scopeOffset(1), ...
        transitionLayout.LabelY(rowIndex) + scopeOffset(2), ...
        transitionLayout.LabelWidth(rowIndex), ...
        transitionLayout.LabelHeight(rowIndex)];
    assert(all(abs(double(transition.LabelPosition) - ...
        expectedLabelPosition) <= geometryTolerance), ...
        "AMR:Layout:TransitionLabelDidNotPersist", ...
        "Transition SSID %d LabelPosition changed after reload.", ...
        transitionLayout.SSID(rowIndex));
    assert(double(transition.FontSize) == ...
        transitionLayout.FontSize(rowIndex), ...
        "AMR:Layout:TransitionFontDidNotPersist", ...
        "Transition SSID %d FontSize changed after reload.", ...
        transitionLayout.SSID(rowIndex));
end
end

function reloadOffsets = verifyScopedStateTranslation( ...
        chart, before, after)
assert(isequal(before(:, 1), after(:, 1)), ...
    "AMR:Layout:StateInventoryChangedAfterReload", ...
    "State SSIDs changed after the model was reloaded.");
assert(isequal(before(:, 4:5), after(:, 4:5)), ...
    "AMR:Layout:StateSizeChangedAfterReload", ...
    "State sizes changed after the model was reloaded.");

scopeKeys = stateScopeKeys(chart, after(:, 1));
uniqueScopeKeys = unique(scopeKeys, "stable");
reloadOffsets = table( ...
    uniqueScopeKeys, zeros(numel(uniqueScopeKeys), 1), ...
    zeros(numel(uniqueScopeKeys), 1), ...
    VariableNames=["ScopeKey", "OffsetX", "OffsetY"]);
translationTolerance = 0.5;
positionOffsets = after(:, 2:3) - before(:, 2:3);
for scopeIndex = 1:numel(uniqueScopeKeys)
    scopeRows = scopeKeys == uniqueScopeKeys(scopeIndex);
    scopeDeltas = positionOffsets(scopeRows, :);
    scopeOffset = median(scopeDeltas, 1);
    assert(all(abs(scopeDeltas - scopeOffset) <= ...
        translationTolerance, "all"), ...
        "AMR:Layout:NonuniformReloadTranslation", ...
        "Objects in scope %s did not share one reload translation.", ...
        uniqueScopeKeys(scopeIndex));
    reloadOffsets.OffsetX(scopeIndex) = scopeOffset(1);
    reloadOffsets.OffsetY(scopeIndex) = scopeOffset(2);
end
end

function difference = cyclicOClockDifference(firstValue, secondValue)
rawDifference = abs(firstValue - secondValue);
difference = min(rawDifference, 12 - rawDifference);
end

function signature = captureLogicSignature(chart)
signature.chartActionLanguage = string(chart.ActionLanguage);
signature.chartDecomposition = string(chart.Decomposition);

states = chart.find("-isa", "Stateflow.State");
stateRows = strings(numel(states), 7);
for stateIndex = 1:numel(states)
    parentSsid = 0;
    parent = getParent(states(stateIndex));
    if isa(parent, "Stateflow.State")
        parentSsid = parent.SSIdNumber;
    end
    stateRows(stateIndex, :) = [ ...
        string(states(stateIndex).SSIdNumber), ...
        string(parentSsid), ...
        string(states(stateIndex).Name), ...
        string(states(stateIndex).LabelString), ...
        string(states(stateIndex).ExecutionOrder), ...
        string(states(stateIndex).Decomposition), ...
        string(logical(states(stateIndex).IsSubchart))];
end
signature.states = sortrows(stateRows, 1);

transitions = chart.find("-isa", "Stateflow.Transition");
transitionRows = strings(numel(transitions), 5);
for transitionIndex = 1:numel(transitions)
    sourceSsid = 0;
    destinationSsid = 0;
    if ~isempty(transitions(transitionIndex).Source)
        sourceSsid = transitions(transitionIndex).Source.SSIdNumber;
    end
    if ~isempty(transitions(transitionIndex).Destination)
        destinationSsid = ...
            transitions(transitionIndex).Destination.SSIdNumber;
    end
    transitionRows(transitionIndex, :) = [ ...
        string(transitions(transitionIndex).SSIdNumber), ...
        string(sourceSsid), ...
        string(destinationSsid), ...
        string(transitions(transitionIndex).LabelString), ...
        string(transitions(transitionIndex).ExecutionOrder)];
end
signature.transitions = sortrows(transitionRows, 1);

data = chart.find("-isa", "Stateflow.Data");
dataRows = strings(numel(data), 6);
for dataIndex = 1:numel(data)
    dataRows(dataIndex, :) = [ ...
        string(data(dataIndex).SSIdNumber), ...
        string(data(dataIndex).Name), ...
        string(data(dataIndex).Scope), ...
        string(data(dataIndex).DataType), ...
        string(data(dataIndex).Port), ...
        string(data(dataIndex).Props.InitialValue)];
end
dataRows(ismissing(dataRows)) = "";
signature.data = sortrows(dataRows, 1);

events = chart.find("-isa", "Stateflow.Event");
eventRows = strings(numel(events), 4);
for eventIndex = 1:numel(events)
    eventRows(eventIndex, :) = [ ...
        string(events(eventIndex).SSIdNumber), ...
        string(events(eventIndex).Name), ...
        string(events(eventIndex).Scope), ...
        string(events(eventIndex).Trigger)];
end
eventRows(ismissing(eventRows)) = "";
signature.events = sortrows(eventRows, 1);
end

function positions = captureStatePositions(chart)
states = chart.find("-isa", "Stateflow.State");
positions = zeros(numel(states), 5);
rowIndex = 0;
for state = reshape(states, 1, [])
    rowIndex = rowIndex + 1;
    positions(rowIndex, :) = [ ...
        double(state.SSIdNumber), double(state.Position)];
end
positions = sortrows(positions, 1);
end

function labels = captureExactStateLabels(chart)
states = chart.find("-isa", "Stateflow.State");
labels = strings(numel(states), 2);
rowIndex = 0;
for state = reshape(states, 1, [])
    rowIndex = rowIndex + 1;
    labels(rowIndex, :) = [ ...
        string(state.SSIdNumber), string(state.LabelString)];
end
labels = sortrows(labels, 1);
end

function verifyStatePositionsPreserved(before, after)
assert(isequal(before, after), ...
    "AMR:Layout:StatePositionChangedDuringRouting", ...
    "Transition-routing-only mode must not change State.Position.");
end

function verifyExactStateLabelsPreserved(before, after)
assert(isequal(before, after), ...
    "AMR:Layout:StateLabelChangedDuringRouting", ...
    "Transition-routing-only mode must not change State.LabelString.");
end

function verifyLogicPreserved(logicBefore, logicAfter)
assert(isequal(logicBefore.chartActionLanguage, ...
    logicAfter.chartActionLanguage), ...
    "AMR:Layout:ActionLanguageChanged", ...
    "Chart action language changed during layout.");
assert(isequal(logicBefore.chartDecomposition, ...
    logicAfter.chartDecomposition), ...
    "AMR:Layout:ChartDecompositionChanged", ...
    "Chart decomposition changed during layout.");
assert(isequal(logicBefore.states, logicAfter.states), ...
    "AMR:Layout:StateLogicChanged", ...
    "State hierarchy, action code, or execution order changed.");
assert(isequal(logicBefore.transitions, logicAfter.transitions), ...
    "AMR:Layout:TransitionLogicChanged", ...
    "Transition endpoints, labels, or execution order changed.");
assert(isequal(logicBefore.data, logicAfter.data), ...
    "AMR:Layout:DataChanged", ...
    "Stateflow data changed during layout.");
assert(isequal(logicBefore.events, logicAfter.events), ...
    "AMR:Layout:EventChanged", ...
    "Stateflow events changed during layout.");
end

function restoreExecutionOrder(chart, baseline)
for rowIndex = 1:size(baseline.states, 1)
    ssid = str2double(baseline.states(rowIndex, 1));
    executionOrder = str2double(baseline.states(rowIndex, 5));
    state = chart.find("-isa", "Stateflow.State", "SSIdNumber", ssid);
    if state.ExecutionOrder ~= executionOrder
        state.ExecutionOrder = executionOrder;
    end
end

for rowIndex = 1:size(baseline.transitions, 1)
    ssid = str2double(baseline.transitions(rowIndex, 1));
    executionOrder = str2double(baseline.transitions(rowIndex, 5));
    transition = chart.find( ...
        "-isa", "Stateflow.Transition", "SSIdNumber", ssid);
    if transition.ExecutionOrder ~= executionOrder
        transition.ExecutionOrder = executionOrder;
    end
end
end

function verifyEveryGraphicalObjectConfigured( ...
        chart, stateLayout, transitionLayout)
stateSsids = sort([chart.find("-isa", "Stateflow.State").SSIdNumber]);
configuredStateSsids = sort(stateLayout.SSID.');
assert(isequal(stateSsids, configuredStateSsids), ...
    "AMR:Layout:UnconfiguredState", ...
    "Every Stateflow state must have an explicit layout row.");

transitionSsids = sort( ...
    [chart.find("-isa", "Stateflow.Transition").SSIdNumber]);
configuredTransitionSsids = sort(transitionLayout.SSID.');
assert(isequal(transitionSsids, configuredTransitionSsids), ...
    "AMR:Layout:UnconfiguredTransition", ...
    "Every Stateflow transition must have an explicit layout row.");
end
