function report = normalizeSubviewerPageMetadata(modelPath, specifications)
%NORMALIZESUBVIEWERPAGEMETADATA Shrink persisted Subchart pages to content.
%   Stateflow R2025b exposes Subchart zoom through Stateflow.Editor, but the
%   persisted local page rectangle (subviewS.pos) is read-only. Space/Fit
%   fits that page, so a stale oversized rectangle makes valid graphics
%   appear tiny. This function changes only the page rectangle in the SLX
%   Stateflow XML while the model is closed. State, Transition, Junction,
%   SSID, execution order, labels, hierarchy, and geometry are untouched.

arguments
    modelPath (1,1) string
    specifications table
end

modelPath = string(char(java.io.File(char(modelPath)).getCanonicalPath));
assert(isfile(modelPath), "AMR:Layout:ModelNotFound", ...
    "Model was not found: %s", modelPath);
[~, modelName] = fileparts(modelPath);
assert(~bdIsLoaded(modelName), "AMR:Layout:ModelMustBeClosed", ...
    "Close %s before normalizing Subchart page metadata.", modelName);
requiredVariables = ["SSID", "PageRectangle"];
assert(all(ismember(requiredVariables, ...
    string(specifications.Properties.VariableNames))), ...
    "AMR:Layout:InvalidPageSpecifications", ...
    "Specifications require SSID and PageRectangle variables.");
assert(size(specifications.PageRectangle, 2) == 4 && ...
    all(isfinite(specifications.PageRectangle), "all") && ...
    all(specifications.PageRectangle(:, 1:2) >= 0, "all") && ...
    all(specifications.PageRectangle(:, 3:4) > 0, "all"), ...
    "AMR:Layout:InvalidPageRectangle", ...
    "Every Subchart page rectangle must be finite and positive.");

modelFolder = string(fileparts(modelPath));
extractRoot = string(tempname(modelFolder));
temporaryZip = string(tempname(modelFolder)) + ".zip";
mkdir(extractRoot);
cleanup = onCleanup(@() cleanupTemporaryFiles( ...
    extractRoot, temporaryZip, modelFolder));
unzip(modelPath, extractRoot);

chartFiles = dir(fullfile(extractRoot, "simulink", "stateflow", ...
    "chart_*.xml"));
assert(~isempty(chartFiles), "AMR:Layout:StateflowXmlMissing", ...
    "The SLX contains no Stateflow chart XML.");

matched = false(height(specifications), 1);
previousRectangle = nan(height(specifications), 4);
for fileIndex = 1:numel(chartFiles)
    xmlPath = string(fullfile( ...
        chartFiles(fileIndex).folder, chartFiles(fileIndex).name));
    xml = fileread(xmlPath);
    updated = xml;
    changed = false;
    for row = 1:height(specifications)
        ssid = double(specifications.SSID(row));
        pattern = sprintf([ ...
            '(?s)(<state SSID="%d">.*?<subviewS>.*?' ...
            '<P Name="pos">)\\[([^\\]]+)\\](</P>)'], ssid);
        tokens = regexp(updated, pattern, "tokens", "once");
        if isempty(tokens)
            continue
        end
        assert(~matched(row), "AMR:Layout:DuplicateSubchartSsid", ...
            "Subchart SSID %d occurs in multiple chart XML files.", ssid);
        values = sscanf(tokens{2}, "%f").';
        assert(numel(values) == 4, ...
            "AMR:Layout:InvalidPersistedPageRectangle", ...
            "Subchart SSID %d has an invalid persisted page rectangle.", ...
            ssid);
        previousRectangle(row, :) = values;
        rectangle = specifications.PageRectangle(row, :);
        replacement = sprintf('$1[%g %g %g %g]$3', rectangle);
        updated = regexprep(updated, pattern, replacement, "once");
        matched(row) = true;
        changed = true;
    end
    if changed
        writeUtf8Text(xmlPath, updated);
    end
end
assert(all(matched), "AMR:Layout:SubchartPageNotFound", ...
    "At least one requested Subchart SSID was not found in the SLX XML.");

zip(temporaryZip, "*", extractRoot);
assert(isfile(temporaryZip), "AMR:Layout:PageArchiveBuildFailed", ...
    "Failed to rebuild the candidate SLX archive.");
movefile(temporaryZip, modelPath, "f");

report = specifications;
report.PreviousPageRectangle = previousRectangle;
report.PageWidthReduction = previousRectangle(:, 3) - ...
    specifications.PageRectangle(:, 3);
report.PageHeightReduction = previousRectangle(:, 4) - ...
    specifications.PageRectangle(:, 4);
clear cleanup
cleanupTemporaryFiles(extractRoot, temporaryZip, modelFolder);
end

function writeUtf8Text(path, value)
writer = fopen(path, "w", "n", "UTF-8");
assert(writer >= 0, "AMR:Layout:StateflowXmlWriteFailed", ...
    "Unable to write %s.", path);
cleanup = onCleanup(@() fclose(writer));
fwrite(writer, value, "char");
clear cleanup
end

function cleanupTemporaryFiles(extractRoot, temporaryZip, modelFolder)
extractRoot = string(char(java.io.File(char(extractRoot)).getCanonicalPath));
temporaryZip = string(char(java.io.File(char(temporaryZip)).getCanonicalPath));
modelFolder = string(char(java.io.File(char(modelFolder)).getCanonicalPath));
assert(startsWith(extractRoot, modelFolder + filesep) && ...
    startsWith(temporaryZip, modelFolder + filesep), ...
    "AMR:Layout:UnsafeTemporaryPath", ...
    "Refusing to clean a temporary path outside the model folder.");
if isfolder(extractRoot)
    rmdir(extractRoot, "s");
end
if isfile(temporaryZip)
    delete(temporaryZip);
end
end
