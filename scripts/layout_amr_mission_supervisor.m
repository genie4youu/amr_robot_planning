function layoutSummary = layout_amr_mission_supervisor(options)
%LAYOUT_AMR_MISSION_SUPERVISOR Recursively lay out MissionSupervisor.
%   The validated primary model is never written unless explicitly
%   authorized. For a full layout pass, provide a separate ModelPath and
%   set RecreateCandidate=true so every run starts from SourceModelPath.

arguments
    options.CreateBackup (1,1) logical = true
    options.TransitionRoutingOnly (1,1) logical = false
    options.ModelPath (1,1) string = ""
    options.SourceModelPath (1,1) string = ""
    options.RecreateCandidate (1,1) logical = false
    options.AllowPrimaryModelWrite (1,1) logical = false
    options.EnforceGraphicalGate (1,1) logical = true
    options.ApplyFitToView (1,1) logical = true
    options.MaximumIterations (1,1) double {mustBeInteger, ...
        mustBePositive} = 3
    options.TransitionStyle (1,1) string {mustBeMember( ...
        options.TransitionStyle, ["Curved", "MinimumCurvature"])} = "Curved"
    options.TargetSubviewerWidthFraction (1,1) double = 0.90
    options.TargetSubviewerHeightFraction (1,1) double = 0.76
    options.MaximumSubviewerMagnification (1,1) double = 3.5
end

assert(~options.TransitionRoutingOnly, ...
    "AMR:Layout:RoutingOnlyRequiresLegacyTable", ...
    "The recursive layout performs a state pass followed immediately by " + ...
    "a transition pass in each container; routing-only mode is unsupported.");
assert(options.TargetSubviewerWidthFraction > 0 && ...
    options.TargetSubviewerWidthFraction <= 1 && ...
    options.TargetSubviewerHeightFraction > 0 && ...
    options.TargetSubviewerHeightFraction <= 1 && ...
    options.MaximumSubviewerMagnification >= 1, ...
    "AMR:Layout:InvalidSubviewerViewportTarget", ...
    "Subviewer viewport targets must be fractions in (0,1] and the " + ...
    "maximum magnification must be at least one.");

scriptFolder = fileparts(mfilename("fullpath"));
projectRoot = fileparts(scriptFolder);
sourceFolder = fullfile(projectRoot, "src");
addpath(sourceFolder);
primaryModelPath = string(fullfile(projectRoot, "models", ...
    "mission_supervisor", "amr_mission_supervisor.slx"));
sourceModelPath = resolveModelPath( ...
    options.SourceModelPath, primaryModelPath, projectRoot);
modelPath = resolveModelPath( ...
    options.ModelPath, sourceModelPath, projectRoot);

assert(isfile(sourceModelPath), "AMR:Layout:SourceModelNotFound", ...
    "Source model was not found: %s", sourceModelPath);
if options.RecreateCandidate
    assert(~sameFile(sourceModelPath, modelPath), ...
        "AMR:Layout:CandidateMatchesSource", ...
        "RecreateCandidate requires different source and candidate paths.");
    prepareCandidate(sourceModelPath, modelPath);
end
assert(isfile(modelPath), "AMR:Layout:ModelNotFound", ...
    "Candidate model was not found: %s", modelPath);
if sameFile(primaryModelPath, modelPath)
    assert(options.AllowPrimaryModelWrite, ...
        "AMR:Layout:PrimaryModelWriteBlocked", ...
        "The validated primary model is protected. Use a candidate ModelPath.");
end

[~, modelBaseName] = fileparts(modelPath);
modelName = string(modelBaseName);
open_system(modelPath);
assert(strcmp(get_param(modelName, "Dirty"), "off"), ...
    "AMR:Layout:UnsavedModel", ...
    "Save or discard unrelated candidate changes before applying layout.");
chart = findChart(modelName);
logicBefore = captureLogicSignature(chart);
geometryBefore = captureGeometry(chart);

backupPath = "";
if options.CreateBackup
    backupPath = createModelBackup(projectRoot, modelPath);
end
pageMetadataReport = table;

try
    recursiveSummary = amr.stateflow.layoutHierarchicalChart( ...
        chart, MaximumIterations=options.MaximumIterations, ...
        TransitionStyle=options.TransitionStyle);
    restoreExecutionOrder(chart, logicBefore);
    verifyLogicPreserved(logicBefore, captureLogicSignature(chart));
    preSaveGeometry = captureGeometry(chart);
    preSaveReport = amr.stateflow.inspectGraphicalLayout(modelName, chart);
    if options.EnforceGraphicalGate
        verifyGraphicalGate(preSaveReport);
    end

    save_system(modelName);
    logicBeforeReload = captureLogicSignature(chart);
    geometryBeforeReload = captureGeometry(chart);
    close_system(modelName, 0);
    open_system(modelPath);
    chart = findChart(modelName);
    logicAfterReload = captureLogicSignature(chart);
    geometryAfterReload = captureGeometry(chart);
    verifyLogicPreserved(logicBeforeReload, logicAfterReload);
    [geometryStable, geometryDifference] = geometryPersisted( ...
        geometryBeforeReload, geometryAfterReload);
    stabilizationPasses = 1;
    fprintf("Geometry stabilization pass %d | %s\n", ...
        stabilizationPasses, geometryDifference);
    while ~geometryStable && stabilizationPasses < ...
            options.MaximumIterations
        stabilizationPasses = stabilizationPasses + 1;
        recursiveSummary = amr.stateflow.layoutHierarchicalChart( ...
            chart, MaximumIterations=options.MaximumIterations, ...
            TransitionStyle=options.TransitionStyle);
        restoreExecutionOrder(chart, logicBefore);
        verifyLogicPreserved(logicBefore, captureLogicSignature(chart));
        geometryBeforeReload = captureGeometry(chart);
        save_system(modelName);
        close_system(modelName, 0);
        open_system(modelPath);
        chart = findChart(modelName);
        verifyLogicPreserved(logicBefore, captureLogicSignature(chart));
        geometryAfterReload = captureGeometry(chart);
        [geometryStable, geometryDifference] = geometryPersisted( ...
            geometryBeforeReload, geometryAfterReload);
        fprintf("Geometry stabilization pass %d | %s\n", ...
            stabilizationPasses, geometryDifference);
    end
    assert(geometryStable, ...
        "AMR:Layout:GeometryDidNotStabilize", ...
        "Geometry did not stabilize after %d passes. %s", ...
        stabilizationPasses, geometryDifference);
    postSaveReport = amr.stateflow.inspectGraphicalLayout(modelName, chart);
    if options.EnforceGraphicalGate
        verifyGraphicalGate(postSaveReport);
    end

    if options.ApplyFitToView
        pageSpecifications = subviewerPageSpecifications(chart);
        pageLogicBeforeReload = captureLogicSignature(chart);
        pageGeometryBeforeReload = captureGeometry(chart);
        close_system(modelName, 0);
        pageMetadataReport = ...
            amr.stateflow.normalizeSubviewerPageMetadata( ...
            modelPath, pageSpecifications);
        open_system(modelPath);
        chart = findChart(modelName);
        verifyLogicPreserved(pageLogicBeforeReload, ...
            captureLogicSignature(chart));
        [pageGeometryStable, pageGeometryDifference] = ...
            geometryPersisted(pageGeometryBeforeReload, ...
            captureGeometry(chart));
        assert(pageGeometryStable, ...
            "AMR:Layout:PageMetadataChangedGeometry", ...
            "Normalizing Subchart pages changed Stateflow geometry. %s", ...
            pageGeometryDifference);
        postSaveReport = amr.stateflow.inspectGraphicalLayout( ...
            modelName, chart);
        if options.EnforceGraphicalGate
            verifyGraphicalGate(postSaveReport);
        end
        fitReport = fitAllGraphicalScopes(chart, modelName, ...
            options.TargetSubviewerWidthFraction, ...
            options.TargetSubviewerHeightFraction, ...
            options.MaximumSubviewerMagnification);
        % Editor viewport state is stored separately from Stateflow object
        % geometry. Save and reopen once more so the readable per-subchart
        % magnification is part of the delivered model, then verify that the
        % stored value survived the reload.
        viewportLogicBeforeReload = captureLogicSignature(chart);
        viewportGeometryBeforeReload = captureGeometry(chart);
        save_system(modelName);
        close_system(modelName, 0);
        open_system(modelPath);
        chart = findChart(modelName);
        logicAfterReload = captureLogicSignature(chart);
        geometryAfterReload = captureGeometry(chart);
        verifyLogicPreserved(viewportLogicBeforeReload, logicAfterReload);
        [viewportGeometryStable, viewportGeometryDifference] = ...
            geometryPersisted(viewportGeometryBeforeReload, ...
            geometryAfterReload);
        assert(viewportGeometryStable, ...
            "AMR:Layout:ViewportSaveChangedGeometry", ...
            "Saving subviewer viewport state changed Stateflow geometry. %s", ...
            viewportGeometryDifference);
        fitReport = verifyStoredSubviewerViewports(chart, fitReport);
        verifyReadableSubviewerViewports(fitReport);
        postSaveReport = amr.stateflow.inspectGraphicalLayout( ...
            modelName, chart);
        if options.EnforceGraphicalGate
            verifyGraphicalGate(postSaveReport);
        end
    else
        fitReport = table;
    end
catch exception
    restoreModelBackup(modelName, modelPath, backupPath);
    rethrow(exception);
end

layoutSummary.ModelPath = modelPath;
layoutSummary.SourceModelPath = sourceModelPath;
layoutSummary.BackupPath = backupPath;
layoutSummary.LogicBefore = logicBefore;
layoutSummary.LogicAfter = logicAfterReload;
layoutSummary.GeometryBefore = geometryBefore;
layoutSummary.GeometryBeforeSave = preSaveGeometry;
layoutSummary.GeometryAfterReload = geometryAfterReload;
layoutSummary.RecursiveLayout = recursiveSummary;
layoutSummary.PreSaveReport = preSaveReport;
layoutSummary.PostSaveReport = postSaveReport;
layoutSummary.FitToView = fitReport;
layoutSummary.SubviewerPageMetadata = pageMetadataReport;
layoutSummary.LogicPreserved = true;
layoutSummary.GeometryPersisted = true;
layoutSummary.StabilizationPasses = stabilizationPasses;
layoutSummary.TransitionStyle = options.TransitionStyle;

fprintf( ...
    "Recursive Stateflow layout applied | containers %d | states %d | " + ...
    "transitions %d | logic preserved.\n", ...
    recursiveSummary.ContainerCount, height(geometryAfterReload.States), ...
    height(geometryAfterReload.Transitions));
end

function path = resolveModelPath(optionValue, defaultValue, projectRoot)
if strlength(optionValue) == 0
    path = string(defaultValue);
elseif java.io.File(char(optionValue)).isAbsolute()
    path = string(optionValue);
else
    path = string(fullfile(projectRoot, optionValue));
end
end

function present = sameFile(firstPath, secondPath)
if ~isfile(firstPath) || ~isfile(secondPath)
    present = string(java.io.File(char(firstPath)).getCanonicalPath()) == ...
        string(java.io.File(char(secondPath)).getCanonicalPath());
    return
end
present = string(java.io.File(char(firstPath)).getCanonicalPath()) == ...
    string(java.io.File(char(secondPath)).getCanonicalPath());
end

function prepareCandidate(sourceModelPath, modelPath)
[~, modelName] = fileparts(modelPath);
if bdIsLoaded(modelName)
    assert(strcmp(get_param(modelName, "Dirty"), "off"), ...
        "AMR:Layout:DirtyCandidate", ...
        "Cannot recreate a loaded candidate with unsaved changes.");
    close_system(modelName, 0);
end
candidateFolder = fileparts(modelPath);
if ~isfolder(candidateFolder)
    mkdir(candidateFolder);
end
[copied, message] = copyfile(sourceModelPath, modelPath, "f");
assert(copied, "AMR:Layout:CandidateCopyFailed", "%s", message);
% A copied SLX receives its new block-diagram name on first save. Complete
% that one-time Stateflow coordinate re-basing before capturing the layout
% baseline or moving any object.
open_system(modelPath);
save_system(modelName);
close_system(modelName, 0);
fprintf("Layout candidate recreated: %s\n", modelPath);
end

function chart = findChart(modelName)
root = sfroot;
chartPath = modelName + "/MissionSupervisor";
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
[~, baseName, extension] = fileparts(modelPath);
backupPath = string(fullfile(backupFolder, ...
    baseName + "_pre_recursive_layout_" + timestamp + extension));
[copied, message] = copyfile(modelPath, backupPath);
assert(copied, "AMR:Layout:BackupFailed", "%s", message);
fprintf("Layout backup: %s\n", backupPath);
end

function restoreModelBackup(modelName, modelPath, backupPath)
if strlength(backupPath) == 0 || ~isfile(backupPath)
    return
end
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
[restored, message] = copyfile(backupPath, modelPath, "f");
assert(restored, "AMR:Layout:BackupRestoreFailed", "%s", message);
open_system(modelPath);
fprintf("Layout failed; candidate backup restored: %s\n", backupPath);
end

function verifyGraphicalGate(report)
assert(report.HardViolationCount == 0, ...
    "AMR:Layout:HardGraphicalViolation", "%s", report.HardDiagnostic);
assert(report.ExactRoutingViolationCount == 0, ...
    "AMR:Layout:ExactRoutingViolation", "%s", report.RoutingDiagnostic);
if isfield(report, "LayoutQualityViolationCount")
    assert(report.LayoutQualityViolationCount == 0, ...
        "AMR:Layout:LayoutQualityViolation", ...
        "%s", report.LayoutQualityDiagnostic);
end
end

function specifications = subviewerPageSpecifications(chart)
profile = amr.stateflow.graphicalLayoutProfile;
states = chart.find("-isa", "Stateflow.State");
transitions = chart.find("-isa", "Stateflow.Transition");
subcharts = states(logical([states.IsSubchart]));
count = numel(subcharts);
ssid = zeros(count, 1);
scope = strings(count, 1);
graphicBounds = nan(count, 4);
pageRectangle = nan(count, 4);
minimumPagePadding = profile.MinimumPagePadding;
targetPageUtilization = profile.TargetPageUtilization;
for index = 1:count
    localStates = states(arrayfun(@(item) ...
        isequal(item.Subviewer, subcharts(index)), states));
    localTransitions = transitions(arrayfun(@(item) ...
        isequal(item.Subviewer, subcharts(index)), transitions));
    bounds = boundsFromGraphicObjects(localStates, localTransitions);
    assert(all(isfinite(bounds)), ...
        "AMR:Layout:EmptySubviewerGraphics", ...
        "Subchart %s has no finite graphical bounds.", ...
        subcharts(index).Name);
    contentSize = bounds(3:4) - bounds(1:2);
    pageSize = max(contentSize ./ targetPageUtilization, ...
        contentSize + 2 * minimumPagePadding);
    pageMinimum = max([0 0], floor( ...
        (bounds(1:2) + bounds(3:4) - pageSize) / 2));
    pageMaximum = pageMinimum + ceil(pageSize);
    ssid(index) = double(subcharts(index).SSIdNumber);
    scope(index) = string(subcharts(index).Name);
    graphicBounds(index, :) = bounds;
    pageRectangle(index, :) = [ ...
        pageMinimum, pageMaximum - pageMinimum];
end
specifications = table(ssid, scope, graphicBounds, pageRectangle, ...
    VariableNames=["SSID", "Scope", "GraphicBounds", ...
    "PageRectangle"]);
end

function report = fitAllGraphicalScopes(chart, modelName, ...
        targetWidthFraction, targetHeightFraction, maximumMagnification)
dirtyBefore = string(get_param(modelName, "Dirty"));
states = chart.find("-isa", "Stateflow.State");
transitions = chart.find("-isa", "Stateflow.Transition");
subcharts = states(logical([states.IsSubchart]));
compositeMask = ~logical([states.IsSubchart]);
for index = 1:numel(states)
    compositeMask(index) = compositeMask(index) && any(arrayfun( ...
        @(item) isequal(item.getParent, states(index)), states));
end
composites = states(compositeMask);
rowCount = numel(subcharts) + numel(composites) + 1;
scope = strings(rowCount, 1);
kind = strings(rowCount, 1);
zoomFactor = nan(rowCount, 1);
fitZoomFactor = nan(rowCount, 1);
magnification = nan(rowCount, 1);
estimatedWidthFraction = nan(rowCount, 1);
estimatedHeightFraction = nan(rowCount, 1);
graphicBounds = nan(rowCount, 4);
centerObject = strings(rowCount, 1);
ssid = nan(rowCount, 1);
row = 0;
for index = 1:numel(subcharts)
    row = row + 1;
    [zoomFactor(row), graphicBounds(row, :), centerObject(row), ...
        fitZoomFactor(row), magnification(row), ...
        estimatedWidthFraction(row), estimatedHeightFraction(row)] = ...
        fitSubviewerContents(chart, subcharts(index), states, transitions, ...
        targetWidthFraction, targetHeightFraction, maximumMagnification);
    scope(row) = string(subcharts(index).Name);
    kind(row) = "Subchart";
    ssid(row) = double(subcharts(index).SSIdNumber);
end
for index = 1:numel(composites)
    row = row + 1;
    view(composites(index));
    fitToView(composites(index));
    drawnow;
    scope(row) = string(composites(index).Name);
    kind(row) = "CompositeState";
    zoomFactor(row) = chart.Editor.ZoomFactor;
    fitZoomFactor(row) = zoomFactor(row);
    magnification(row) = 1;
    position = double(composites(index).Position);
    graphicBounds(row, :) = [position(1:2), ...
        position(1:2) + position(3:4)];
    centerObject(row) = string(composites(index).Name);
    ssid(row) = double(composites(index).SSIdNumber);
end
row = row + 1;
view(chart);
fitToView(chart);
drawnow;
scope(row) = string(chart.Path);
kind(row) = "Chart";
zoomFactor(row) = chart.Editor.ZoomFactor;
fitZoomFactor(row) = zoomFactor(row);
magnification(row) = 1;
graphicBounds(row, :) = boundsFromGraphicObjects( ...
    states(arrayfun(@(item) isequal(item.Subviewer, chart), states)), ...
    transitions(arrayfun(@(item) ...
    isequal(item.Subviewer, chart), transitions)));
centerObject(row) = string(chart.Name);
dirtyAfter = string(get_param(modelName, "Dirty"));
assert(dirtyAfter == dirtyBefore, "AMR:Layout:ViewChangedModel", ...
    "view/fitToView must not modify the model.");
report = table(scope, kind, true(rowCount, 1), zoomFactor, ...
    fitZoomFactor, magnification, estimatedWidthFraction, ...
    estimatedHeightFraction, graphicBounds, centerObject, ssid, ...
    VariableNames=["Scope", "Kind", "FitToViewApplied", ...
    "ZoomFactor", "FitZoomFactor", "Magnification", ...
    "EstimatedWidthFraction", "EstimatedHeightFraction", ...
    "GraphicBounds", "CenterObject", "SSID"]);
end

function [zoomFactor, bounds, centerName, fitZoomFactor, magnification, ...
        widthFraction, heightFraction] = fitSubviewerContents( ...
        chart, subviewer, states, transitions, targetWidthFraction, ...
        targetHeightFraction, maximumMagnification)
stateMask = arrayfun(@(item) isequal(item.Subviewer, subviewer), states);
transitionMask = arrayfun( ...
    @(item) isequal(item.Subviewer, subviewer), transitions);
localStates = states(stateMask);
localTransitions = transitions(transitionMask);
bounds = boundsFromGraphicObjects(localStates, localTransitions);
view(subviewer);
drawnow;
fitToView(subviewer);
drawnow;
fitZoomFactor = chart.Editor.ZoomFactor;
canvas = localSubviewCanvas(subviewer, bounds);
graphicSize = max(bounds(3:4) - bounds(1:2), eps);
canvasSize = max(canvas(3:4), graphicSize);
fitWidthFraction = graphicSize(1) / canvasSize(1);
fitHeightFraction = graphicSize(2) / canvasSize(2);
magnification = max(1, min([ ...
    targetWidthFraction / fitWidthFraction, ...
    targetHeightFraction / fitHeightFraction, ...
    maximumMagnification]));
chart.Editor.ZoomFactor = fitZoomFactor * magnification;
drawnow;
zoomFactor = chart.Editor.ZoomFactor;
widthFraction = fitWidthFraction * magnification;
heightFraction = fitHeightFraction * magnification;
centerName = string(subviewer.Name);
end

function canvas = localSubviewCanvas(subviewer, bounds)
canvas = nan(1, 4);
try
    canvas = double(sf('get', double(subviewer.Id), '.subviewS.pos'));
catch
end
valid = numel(canvas) == 4 && all(isfinite(canvas)) && ...
    all(canvas(3:4) > 0);
if ~valid
    size = max(bounds(3:4) - bounds(1:2), [1 1]);
    canvas = [bounds(1:2), size];
end
end

function report = verifyStoredSubviewerViewports(chart, report)
storedZoomFactor = nan(height(report), 1);
viewportPersisted = false(height(report), 1);
displaySpanPixels = nan(height(report), 1);
fitDisplaySpanPixels = nan(height(report), 1);
states = chart.find("-isa", "Stateflow.State");
for row = 1:height(report)
    if report.Kind(row) ~= "Subchart"
        continue
    end
    match = find(double([states.SSIdNumber]) == report.SSID(row), 1);
    assert(~isempty(match), "AMR:Layout:SubviewerMissingAfterReload", ...
        "Subviewer SSID %d was not found after viewport reload.", ...
        report.SSID(row));
    view(states(match));
    drawnow;
    storedZoomFactor(row) = chart.Editor.ZoomFactor;
    graphicSize = report.GraphicBounds(row, 3:4) - ...
        report.GraphicBounds(row, 1:2);
    displaySpanPixels(row) = max(graphicSize * storedZoomFactor(row));
    fitDisplaySpanPixels(row) = max( ...
        graphicSize * report.FitZoomFactor(row));
    tolerance = max(1e-8, abs(report.ZoomFactor(row)) * 1e-6);
    viewportPersisted(row) = abs(storedZoomFactor(row) - ...
        report.ZoomFactor(row)) <= tolerance;
end
subchartRows = report.Kind == "Subchart";
assert(all(viewportPersisted(subchartRows)), ...
    "AMR:Layout:SubviewerViewportDidNotPersist", ...
    "At least one readable subviewer viewport did not survive save/reload.");
view(chart);
drawnow;
report.StoredZoomFactor = storedZoomFactor;
report.ViewportPersisted = viewportPersisted;
report.DisplaySpanPixels = displaySpanPixels;
report.FitDisplaySpanPixels = fitDisplaySpanPixels;
end

function verifyReadableSubviewerViewports(report)
profile = amr.stateflow.graphicalLayoutProfile;
subcharts = report(report.Kind == "Subchart", :);
assert(~isempty(subcharts), "AMR:Layout:NoSubviewersVerified", ...
    "No Subchart viewport was verified after save/reload.");
largestAxisFraction = max([subcharts.EstimatedWidthFraction, ...
    subcharts.EstimatedHeightFraction], [], 2);
assert(all(largestAxisFraction >= profile.MinimumContentAxisFraction), ...
    "AMR:Layout:SubviewerContentTooSmall", ...
    "At least one saved Subchart occupies less than 70%% of both axes.");
assert(all(subcharts.EstimatedWidthFraction <= ...
    profile.MaximumContentFraction(1)) && ...
    all(subcharts.EstimatedHeightFraction <= ...
    profile.MaximumContentFraction(2)), ...
    "AMR:Layout:SubviewerContentCropped", ...
    "At least one saved Subchart viewport is too tightly cropped.");
end

function bounds = boundsFromGraphicObjects(states, transitions)
minimum = [inf inf];
maximum = [-inf -inf];
for index = 1:numel(states)
    rectangle = double(states(index).Position);
    minimum = min(minimum, rectangle(1:2));
    maximum = max(maximum, rectangle(1:2) + rectangle(3:4));
end
for index = 1:numel(transitions)
    points = [double(transitions(index).SourceEndpoint); ...
        double(transitions(index).MidPoint); ...
        double(transitions(index).DestinationEndpoint)];
    points = points(all(isfinite(points), 2), :);
    if ~isempty(points)
        minimum = min(minimum, min(points, [], 1));
        maximum = max(maximum, max(points, [], 1));
    end
    label = double(transitions(index).LabelPosition);
    if all(isfinite(label)) && all(label(3:4) >= 0)
        minimum = min(minimum, label(1:2));
        maximum = max(maximum, label(1:2) + label(3:4));
    end
end
if any(~isfinite([minimum maximum]))
    bounds = [NaN NaN NaN NaN];
else
    bounds = [minimum maximum];
end
end

function signature = captureLogicSignature(chart)
signature.Chart = [string(chart.ActionLanguage), ...
    string(chart.Decomposition)];

states = chart.find("-isa", "Stateflow.State");
stateRows = strings(numel(states), 9);
for index = 1:numel(states)
    stateRows(index, :) = [ ...
        string(states(index).SSIdNumber), ...
        string(parentSsid(states(index))), ...
        string(states(index).Name), ...
        string(states(index).LabelString), ...
        string(states(index).ExecutionOrder), ...
        string(states(index).Decomposition), ...
        string(logical(states(index).IsSubchart)), ...
        propertyText(states(index), "Type"), ...
        class(states(index))];
end
signature.States = sortrows(stateRows, 1);

transitions = chart.find("-isa", "Stateflow.Transition");
transitionRows = strings(numel(transitions), 7);
for index = 1:numel(transitions)
    transitionRows(index, :) = [ ...
        string(transitions(index).SSIdNumber), ...
        string(parentSsid(transitions(index))), ...
        endpointSsid(transitions(index).Source), ...
        endpointSsid(transitions(index).Destination), ...
        string(transitions(index).LabelString), ...
        string(transitions(index).ExecutionOrder), ...
        class(transitions(index))];
end
signature.Transitions = sortrows(transitionRows, 1);
signature.OutgoingOrder = captureOutgoingOrder(transitions);

junctions = chart.find("-isa", "Stateflow.Junction");
signature.Junctions = captureSimpleObjects( ...
    junctions, ["Type", "Position"]);
data = chart.find("-isa", "Stateflow.Data");
signature.Data = captureSimpleObjects( ...
    data, ["Name", "Scope", "DataType", "Port"]);
events = chart.find("-isa", "Stateflow.Event");
signature.Events = captureSimpleObjects( ...
    events, ["Name", "Scope", "Trigger"]);
messages = chart.find("-isa", "Stateflow.Message");
signature.Messages = captureSimpleObjects( ...
    messages, ["Name", "Scope", "DataType"]);
functions = [ ...
    chart.find("-isa", "Stateflow.Function")
    chart.find("-isa", "Stateflow.EMFunction")
    chart.find("-isa", "Stateflow.TruthTable")
    ];
signature.Functions = captureSimpleObjects( ...
    functions, ["Name", "LabelString", "Script"]);
signature.Counts = uint32([numel(states), numel(transitions), ...
    numel(junctions), numel(data), numel(events), ...
    numel(messages), numel(functions)]);
end

function rows = captureSimpleObjects(objects, properties)
rows = strings(numel(objects), 3 + numel(properties));
for index = 1:numel(objects)
    rows(index, 1:3) = [string(objectSsid(objects(index))), ...
        string(parentSsid(objects(index))), class(objects(index))];
    for propertyIndex = 1:numel(properties)
        rows(index, 3 + propertyIndex) = ...
            propertyText(objects(index), properties(propertyIndex));
    end
end
if ~isempty(rows)
    rows = sortrows(rows, 1);
end
end

function rows = captureOutgoingOrder(transitions)
sourceSsids = strings(numel(transitions), 1);
for index = 1:numel(transitions)
    sourceSsids(index) = endpointSsid(transitions(index).Source);
end
uniqueSources = unique(sourceSsids(sourceSsids ~= "0"));
rows = strings(numel(uniqueSources), 2);
for index = 1:numel(uniqueSources)
    mask = sourceSsids == uniqueSources(index);
    local = transitions(mask);
    order = arrayfun(@(item) double(item.ExecutionOrder), local);
    ssids = double([local.SSIdNumber]);
    [~, sortOrder] = sortrows([order(:), ssids(:)], [1 2]);
    rows(index, :) = [uniqueSources(index), ...
        strjoin(string(ssids(sortOrder)), ",")];
end
rows = sortrows(rows, 1);
end

function geometry = captureGeometry(chart)
states = chart.find("-isa", "Stateflow.State");
stateSsid = double([states.SSIdNumber]).';
statePosition = vertcat(states.Position);
stateFontSize = double([states.FontSize]).';
stateSubviewer = strings(numel(states), 1);
for index = 1:numel(states)
    stateSubviewer(index) = objectKey(states(index).Subviewer);
end
geometry.States = table(stateSsid, stateSubviewer, statePosition, ...
    stateFontSize, VariableNames=["SSID", "Subviewer", ...
    "Position", "FontSize"]);
geometry.States = sortrows(geometry.States, "SSID");

transitions = chart.find("-isa", "Stateflow.Transition");
transitionSsid = double([transitions.SSIdNumber]).';
sourceOClock = double([transitions.SourceOClock]).';
destinationOClock = double([transitions.DestinationOClock]).';
sourceEndpoint = vertcat(transitions.SourceEndpoint);
midPoint = vertcat(transitions.MidPoint);
destinationEndpoint = vertcat(transitions.DestinationEndpoint);
labelPosition = vertcat(transitions.LabelPosition);
transitionFontSize = double([transitions.FontSize]).';
geometry.Transitions = table(transitionSsid, sourceOClock, ...
    destinationOClock, sourceEndpoint, midPoint, destinationEndpoint, ...
    labelPosition, transitionFontSize, VariableNames=["SSID", ...
    "SourceOClock", "DestinationOClock", "SourceEndpoint", ...
    "MidPoint", "DestinationEndpoint", "LabelPosition", "FontSize"]);
geometry.Transitions = sortrows(geometry.Transitions, "SSID");
end

function verifyLogicPreserved(before, after)
fields = fieldnames(before);
for index = 1:numel(fields)
    field = fields{index};
    if isequaln(before.(field), after.(field))
        continue
    end
    detail = logicDifferenceDetail(before.(field), after.(field));
    error("AMR:Layout:LogicChanged", ...
        "Stateflow logical signature field '%s' changed. %s", ...
        field, detail);
end
end

function detail = logicDifferenceDetail(before, after)
if ~isstring(before) || ~isstring(after) || ...
        size(before, 2) ~= size(after, 2)
    detail = sprintf("Before size %s; after size %s.", ...
        mat2str(size(before)), mat2str(size(after)));
    return
end
keys = unique([before(:, 1); after(:, 1)], "stable");
parts = strings(0, 1);
for key = reshape(keys, 1, [])
    beforeRow = before(before(:, 1) == key, :);
    afterRow = after(after(:, 1) == key, :);
    if isequaln(beforeRow, afterRow)
        continue
    end
    parts(end + 1) = "key " + key + " before=" + ...
        strjoin(reshape(beforeRow, 1, []), "|") + " after=" + ...
        strjoin(reshape(afterRow, 1, []), "|"); %#ok<AGROW>
    if numel(parts) == 3
        break
    end
end
detail = strjoin(parts, "; ");
end

function [persisted, detail] = geometryPersisted(before, after)
tolerance = 0.5;
persisted = isequal(before.States.SSID, after.States.SSID) && ...
    isequal(before.Transitions.SSID, after.Transitions.SSID);
detail = "Object identities differ.";
if ~persisted
    return
end
stateDifference = max(abs( ...
    before.States.Position - after.States.Position), [], "all");
if stateDifference > tolerance
    persisted = false;
    detail = sprintf("Maximum State.Position difference %.3f pixels.", ...
        stateDifference);
    return
end
properties = ["SourceOClock", "DestinationOClock", ...
    "SourceEndpoint", "MidPoint", "DestinationEndpoint", ...
    "LabelPosition", "FontSize"];
for property = properties
    difference = max(abs(before.Transitions.(property) - ...
        after.Transitions.(property)), [], "all");
    if difference > tolerance
        persisted = false;
        detail = sprintf( ...
            "Maximum Transition.%s difference %.3f pixels.", ...
            property, difference);
        return
    end
end
persisted = true;
detail = "Geometry persisted within tolerance.";
end

function restoreExecutionOrder(chart, baseline)
stateParent = str2double(baseline.States(:, 2));
stateOrder = str2double(baseline.States(:, 5));
stateSsid = str2double(baseline.States(:, 1));
[~, orderedStateRows] = sortrows( ...
    [stateParent, stateOrder, stateSsid], [1 2 3]);
for index = reshape(orderedStateRows, 1, [])
    state = chart.find("-isa", "Stateflow.State", ...
        "SSIdNumber", str2double(baseline.States(index, 1)));
    desiredOrder = str2double(baseline.States(index, 5));
    if double(state.ExecutionOrder) ~= desiredOrder
        state.ExecutionOrder = desiredOrder;
    end
end
transitionSource = str2double(baseline.Transitions(:, 3));
transitionOrder = str2double(baseline.Transitions(:, 6));
transitionSsid = str2double(baseline.Transitions(:, 1));
[~, orderedTransitionRows] = sortrows( ...
    [transitionSource, transitionOrder, transitionSsid], [1 2 3]);
for index = reshape(orderedTransitionRows, 1, [])
    transition = chart.find("-isa", "Stateflow.Transition", ...
        "SSIdNumber", str2double(baseline.Transitions(index, 1)));
    desiredOrder = str2double(baseline.Transitions(index, 6));
    if double(transition.ExecutionOrder) ~= desiredOrder
        transition.ExecutionOrder = desiredOrder;
    end
end
end

function value = parentSsid(object)
parent = object.getParent;
if isa(parent, "Stateflow.State") || ...
        isa(parent, "Stateflow.Junction")
    value = double(parent.SSIdNumber);
else
    value = 0;
end
end

function value = objectSsid(object)
if isprop(object, "SSIdNumber")
    value = double(object.SSIdNumber);
else
    value = 0;
end
end

function value = endpointSsid(object)
if isempty(object)
    value = "0";
elseif isprop(object, "SSIdNumber")
    value = string(object.SSIdNumber);
else
    value = "0";
end
end

function value = propertyText(object, property)
if ~isprop(object, property)
    value = "";
    return
end
try
    raw = object.(property);
    if isnumeric(raw) || islogical(raw)
        value = string(mat2str(raw));
    else
        value = string(raw);
    end
catch
    value = "";
end
end

function key = objectKey(object)
if isa(object, "Stateflow.Chart")
    key = "Chart:" + string(object.Path);
elseif isprop(object, "SSIdNumber")
    key = string(class(object)) + ":" + string(object.SSIdNumber);
else
    key = string(class(object));
end
end
