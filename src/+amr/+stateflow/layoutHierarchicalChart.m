function summary = layoutHierarchicalChart(chart, options)
%LAYOUTHIERARCHICALCHART Recursively lay out every Stateflow container.
%   The algorithm discovers containers from Stateflow parent relationships,
%   processes the deepest container first, and changes presentation
%   properties only. Subcharts use independent local coordinates. Ordinary
%   composite states use their finite parent-state interior.

arguments
    chart (1,1) Stateflow.Chart
    options.MaximumIterations (1,1) double {mustBeInteger, ...
        mustBePositive} = 3
    options.TransitionStyle (1,1) string {mustBeMember( ...
        options.TransitionStyle, ["Curved", "MinimumCurvature"])} = "Curved"
end

profile = amr.stateflow.graphicalLayoutProfile;
chart.StateFont.Size = profile.StateFontSize;
chart.TransitionFont.Size = profile.TransitionFontSize;
allStates = chart.find("-isa", "Stateflow.State");
allTransitions = chart.find("-isa", "Stateflow.Transition");
containers = collectAllContainers(chart, allStates);
depths = cellfun(@containerDepth, containers);
[~, order] = sort(depths, "descend");

records = repmat(emptyContainerRecord(), numel(containers), 1);
for orderIndex = 1:numel(order)
    containerIndex = order(orderIndex);
    container = containers{containerIndex};
    directStates = directChildren(allStates, container);
    directTransitions = directChildren(allTransitions, container);
    beforePositions = positionMatrix(directStates);

    iterationCount = 0;
    for iteration = 1:options.MaximumIterations
        iterationCount = iteration;
        previousPositions = positionMatrix(directStates);
        previousTransitions = transitionGeometrySnapshot( ...
            directTransitions);
        if isa(container, "Stateflow.Chart") || ...
                (isa(container, "Stateflow.State") && ...
                logical(container.IsSubchart))
            graph = classifyLocalGraph(directStates, directTransitions);
            layoutLocalStates(container, directStates, graph, allStates, ...
                [0 0]);
        else
            graph = classifyLocalGraph(directStates, directTransitions);
            centerChildrenInCompositeState( ...
                container, directStates, allStates);
        end

        % The transition pass immediately follows the state pass for this
        % container. A later container never batches or reroutes these
        % transitions on behalf of this one.
        stateChanged = ~isequal( ...
            previousPositions, positionMatrix(directStates));
        [uniformTranslation, translation] = uniformStateTranslation( ...
            previousPositions, positionMatrix(directStates));
        freshRouting = false;
        if ~isa(container, "Stateflow.Chart") && ...
                uniformTranslation
            if stateChanged
                translateExistingTransitionGeometry( ...
                    directTransitions, previousTransitions, translation);
            end
            routing = captureExistingRoutes( ...
                directStates, directTransitions, graph);
        else
            routing = routeLocalTransitions( ...
                container, directStates, directTransitions, graph);
            freshRouting = true;
        end
        if freshRouting
            routing = spreadSharedTransitionEndpoints( ...
                directStates, directTransitions, graph, routing);
        end
        if ~isa(container, "Stateflow.Chart")
            if options.TransitionStyle == "MinimumCurvature"
                routing = minimizeSplineCurvature( ...
                    directStates, directTransitions, graph, routing);
            end
        end
        placeLocalTransitionLabels( ...
            directStates, directTransitions, routing);
        if isequal(previousPositions, positionMatrix(directStates))
            break
        end
    end

    records(containerIndex) = buildContainerRecord( ...
        container, directStates, directTransitions, depths(containerIndex), ...
        beforePositions, iterationCount, routing);
end

summary.Containers = struct2table(records);
summary.StateGeometry = collectStateTable(allStates);
summary.TransitionGeometry = collectTransitionTable(allTransitions);
summary.ContainerCount = uint32(numel(containers));
end

function containers = collectAllContainers(chart, allStates)
containers = {chart};
allJunctions = chart.find("-isa", "Stateflow.Junction");
allFunctions = [ ...
    chart.find("-isa", "Stateflow.Function")
    chart.find("-isa", "Stateflow.EMFunction")
    chart.find("-isa", "Stateflow.TruthTable")
    ];
for state = reshape(allStates, 1, [])
    hasState = any(arrayfun(@(item) ...
        isequal(item.getParent, state), allStates));
    hasJunction = any(arrayfun(@(item) ...
        isequal(item.getParent, state), allJunctions));
    hasFunction = any(arrayfun(@(item) ...
        isequal(item.getParent, state), allFunctions));
    if hasState || hasJunction || hasFunction
        containers{end + 1} = state; %#ok<AGROW>
    end
end
end

function depth = containerDepth(container)
depth = 0;
if isa(container, "Stateflow.Chart")
    return
end
parent = container.getParent;
while isa(parent, "Stateflow.State")
    depth = depth + 1;
    parent = parent.getParent;
end
depth = depth + 1;
end

function children = directChildren(objects, container)
if isempty(objects)
    children = objects;
    return
end
mask = arrayfun(@(item) isequal(item.getParent, container), objects);
children = objects(mask);
if numel(children) > 1 && isprop(children(1), "SSIdNumber")
    [~, order] = sort(double([children.SSIdNumber]));
    children = children(order);
end
end

function graph = classifyLocalGraph(states, transitions)
stateCount = numel(states);
graph = struct;
graph.StateCount = stateCount;
graph.StateSsids = zeros(stateCount, 1);
graph.InitialIndex = 0;
graph.MainPath = zeros(1, 0);
graph.HubMask = false(stateCount, 1);
graph.InDegree = zeros(stateCount, 1);
graph.Outgoing = cell(stateCount, 1);
graph.TransitionSourceIndex = zeros(numel(transitions), 1);
graph.TransitionDestinationIndex = zeros(numel(transitions), 1);
if stateCount == 0
    return
end

graph.StateSsids = double([states.SSIdNumber]).';
for transitionIndex = 1:numel(transitions)
    transition = transitions(transitionIndex);
    sourceIndex = stateIndexForObject(states, transition.Source);
    destinationIndex = stateIndexForObject(states, transition.Destination);
    graph.TransitionSourceIndex(transitionIndex) = sourceIndex;
    graph.TransitionDestinationIndex(transitionIndex) = destinationIndex;
    if sourceIndex == 0 && destinationIndex > 0 && ...
            graph.InitialIndex == 0
        graph.InitialIndex = destinationIndex;
    elseif sourceIndex > 0 && destinationIndex > 0
        graph.Outgoing{sourceIndex}(end + 1) = transitionIndex;
    end
end

for destinationIndex = 1:stateCount
    sourceIndices = graph.TransitionSourceIndex( ...
        graph.TransitionDestinationIndex == destinationIndex);
    sourceIndices = unique(sourceIndices(sourceIndices > 0));
    graph.InDegree(destinationIndex) = numel(sourceIndices);
end
graph.HubMask = graph.InDegree >= 2;
if graph.InitialIndex == 0
    [~, graph.InitialIndex] = min( ...
        graph.InDegree + (1:stateCount).' / (stateCount + 1));
end
graph.HubMask(graph.InitialIndex) = false;
graph.MainPath = findMainPath(states, transitions, graph);
end

function mainPath = findMainPath(states, transitions, graph)
if graph.StateCount == 0
    mainPath = zeros(1, 0);
    return
end
mainPath = graph.InitialIndex;
visited = false(graph.StateCount, 1);
visited(graph.InitialIndex) = true;
current = graph.InitialIndex;
for pathStep = 2:graph.StateCount
    outgoing = graph.Outgoing{current};
    if isempty(outgoing)
        break
    end
    executionOrder = arrayfun(@(index) ...
        double(transitions(index).ExecutionOrder), outgoing);
    [~, transitionOrder] = sortrows([executionOrder(:), outgoing(:)], [1 2]);
    outgoing = outgoing(transitionOrder);
    destinations = graph.TransitionDestinationIndex(outgoing);
    keep = destinations > 0 & ~visited(destinations);
    destinations = destinations(keep);
    if isempty(destinations)
        break
    end
    nonHub = ~graph.HubMask(destinations);
    if any(nonHub)
        destinations = destinations(nonHub);
    else
        break
    end

    next = 0;
    for candidate = reshape(destinations, 1, [])
        if ~isLoopbackBranch(candidate, visited, transitions, graph)
            next = candidate;
            break
        end
    end
    if next == 0
        break
    end
    mainPath(end + 1) = next; %#ok<AGROW>
    visited(next) = true;
    current = next;
end

% A chart without a default transition still receives a deterministic
% graph-derived ordering rather than a name-derived ordering.
if isempty(mainPath)
    [~, order] = sort(double([states.SSIdNumber]));
    mainPath = order;
end
end

function loopback = isLoopbackBranch(candidate, visited, transitions, graph)
outgoing = graph.Outgoing{candidate};
if isempty(outgoing)
    loopback = false;
    return
end
executionOrder = arrayfun(@(index) ...
    double(transitions(index).ExecutionOrder), outgoing);
[~, order] = sortrows([executionOrder(:), outgoing(:)], [1 2]);
destinations = graph.TransitionDestinationIndex(outgoing(order));
destinations = destinations(destinations > 0);
if ~isempty(destinations) && ...
        all(destinations == graph.InitialIndex)
    % A terminal state that only closes the cycle back to the initial
    % state belongs at the end of the normal row (for example, a completed
    % phase). A recovery state usually returns to a noninitial predecessor.
    loopback = false;
    return
end
hasUnvisitedNonHub = any(~visited(destinations) & ...
    ~graph.HubMask(destinations));
preferredReturnsToVisited = ~isempty(destinations) && ...
    visited(destinations(1));
onlyFeedsHubOrVisited = ~isempty(destinations) && ...
    all(visited(destinations) | graph.HubMask(destinations));
loopback = preferredReturnsToVisited || ...
    (~hasUnvisitedNonHub && onlyFeedsHubOrVisited);
end

function index = stateIndexForObject(states, object)
index = 0;
if isempty(object) || ~isa(object, "Stateflow.State")
    return
end
matches = find(double([states.SSIdNumber]) == ...
    double(object.SSIdNumber), 1);
if ~isempty(matches)
    index = matches;
end
end

function layoutLocalStates(container, states, graph, allStates, originOffset)
if isempty(states)
    return
end
profile = amr.stateflow.graphicalLayoutProfile;
positions = vertcat(states.Position);
required = zeros(numel(states), 2);
for stateIndex = 1:numel(states)
    required(stateIndex, :) = requiredStateSize(states(stateIndex));
end
if isa(container, "Stateflow.Chart")
    % A Chart has no finite parent canvas. Keep root State positions stable:
    % moving a composite root State can make Stateflow reparent its visible
    % children depending on the active editor state. The ordinary composite
    % pass already centers those children inside their finite parent.
    for stateIndex = 1:numel(states)
        states(stateIndex).FontSize = profile.StateFontSize;
    end
    return
end
oversized = positions(:, 3) > 3 * required(:, 1) + 2;
largeHub = graph.HubMask & positions(:, 3) > 550;
needsReflow = any(oversized | largeHub);

if ~needsReflow
    normalizeSubchartCoordinates(container, states, allStates, graph);
    return
end

main = graph.MainPath;
if isempty(main)
    main = 1:numel(states);
end
remaining = setdiff(1:numel(states), main, "stable");
[~, remainingOrder] = sort(positions(remaining, 1));
remaining = remaining(remainingOrder);

startX = profile.LocalStart(1) - originOffset(1);
startY = profile.LocalStart(2) - originOffset(2);
assert(all([startX startY] >= 0), ...
    "AMR:Layout:NegativeSaveCompensation", ...
    "A learned Stateflow save offset would require negative coordinates.");
if numel(main) >= 6
    horizontalGap = 35;
else
    horizontalGap = 120;
end
normalHeight = max([120; required(main, 2); positions(main, 4)]);
x = startX;
normalPositions = zeros(numel(main), 4);
for pathIndex = 1:numel(main)
    stateIndex = main(pathIndex);
    hasChildren = hasDirectStateChildren(states(stateIndex), allStates);
    if hasChildren
        width = max(positions(stateIndex, 3), required(stateIndex, 1));
        height = max(positions(stateIndex, 4), required(stateIndex, 2));
    else
        width = max(required(stateIndex, 1), min( ...
            positions(stateIndex, 3), 3 * required(stateIndex, 1)));
        if isa(container, "Stateflow.Chart")
            height = max(positions(stateIndex, 4), ...
                required(stateIndex, 2));
        else
            height = normalHeight;
        end
    end
    width = ceil(width / 10) * 10;
    height = ceil(height / 10) * 10;
    newPosition = [x, startY, width, height];
    setStatePosition(states(stateIndex), newPosition, allStates);
    normalPositions(pathIndex, :) = newPosition;
    x = x + width + horizontalGap;
end

if isempty(remaining)
    normalizeSubchartCoordinates(container, states, allStates, graph);
    return
end
normalBounds = rectangleBounds(normalPositions);
exceptionY = normalBounds(4) + 150;
exceptionWidths = zeros(numel(remaining), 1);
exceptionHeights = zeros(numel(remaining), 1);
for remainingIndex = 1:numel(remaining)
    stateIndex = remaining(remainingIndex);
    if graph.HubMask(stateIndex) && graph.InDegree(stateIndex) >= 4
        exceptionWidths(remainingIndex) = min(max( ...
            required(stateIndex, 1) + 80, 400), 550);
    else
        exceptionWidths(remainingIndex) = max(required(stateIndex, 1), ...
            min(positions(stateIndex, 3), 3 * required(stateIndex, 1)));
    end
    exceptionHeights(remainingIndex) = max(100, required(stateIndex, 2));
end
exceptionWidths = ceil(exceptionWidths / 10) * 10;
exceptionHeights = ceil(exceptionHeights / 10) * 10;
exceptionGap = 120;
exceptionSpan = sum(exceptionWidths) + ...
    exceptionGap * max(numel(remaining) - 1, 0);
exceptionX = (normalBounds(1) + normalBounds(3)) / 2 - ...
    exceptionSpan / 2;
exceptionX = max(80, exceptionX);
for remainingIndex = 1:numel(remaining)
    stateIndex = remaining(remainingIndex);
    newPosition = [exceptionX, exceptionY, ...
        exceptionWidths(remainingIndex), exceptionHeights(remainingIndex)];
    setStatePosition(states(stateIndex), newPosition, allStates);
    exceptionX = exceptionX + exceptionWidths(remainingIndex) + ...
        exceptionGap;
end
normalizeSubchartCoordinates(container, states, allStates, graph);
end

function normalizeSubchartCoordinates(container, states, allStates, graph)
% A subchart owns an unbounded local coordinate system. Its persisted
% subview rectangle describes the editor camera, not a finite layout area.
% Using that camera as the centering target makes coordinates depend on the
% window and saved zoom; pressing Space/Fit then includes the large offset
% from the local origin and shrinks otherwise readable graphics. Anchor the
% direct child-state envelope to a deterministic local margin instead.
if isempty(states) || isa(container, "Stateflow.Chart") || ...
        ~logical(container.IsSubchart)
    return
end
positions = vertcat(states.Position);
bounds = rectangleBounds(positions);
profile = amr.stateflow.graphicalLayoutProfile;
localMargin = profile.LocalStart;
if hasMainPathReturn(graph)
    % A long Stateflow spline can render above its single API midpoint and
    % Stateflow then shifts the whole subviewer during save. Reserve a
    % stable 80 px top band for that return lane so save/reopen is
    % idempotent. This is based on graph role, never on a State name.
    localMargin(2) = profile.LocalStartWithTopReturnLane(2);
end
delta = localMargin - bounds(1:2);
translateStates(states, delta, allStates);
end

function present = hasMainPathReturn(graph)
present = false;
if isempty(graph.MainPath)
    return
end
mainOrder = zeros(graph.StateCount, 1);
mainOrder(graph.MainPath) = 1:numel(graph.MainPath);
sourceOrder = zeros(size(graph.TransitionSourceIndex));
destinationOrder = zeros(size(graph.TransitionDestinationIndex));
sourceMask = graph.TransitionSourceIndex > 0;
destinationMask = graph.TransitionDestinationIndex > 0;
sourceOrder(sourceMask) = mainOrder( ...
    graph.TransitionSourceIndex(sourceMask));
destinationOrder(destinationMask) = mainOrder( ...
    graph.TransitionDestinationIndex(destinationMask));
present = any(sourceOrder > 0 & destinationOrder > 0 & ...
    destinationOrder < sourceOrder);
end

function centerChildrenInCompositeState(container, states, allStates)
if isempty(states)
    return
end
parentPosition = double(container.Position);
positions = vertcat(states.Position);
childBounds = rectangleBounds(positions);
titleHeight = 70;
horizontalPadding = 60;
bottomPadding = 60;
requiredWidth = childBounds(3) - childBounds(1) + 2 * horizontalPadding;
requiredHeight = childBounds(4) - childBounds(2) + ...
    titleHeight + bottomPadding;
if parentPosition(3) < requiredWidth || parentPosition(4) < requiredHeight
    parentPosition(3) = max(parentPosition(3), requiredWidth);
    parentPosition(4) = max(parentPosition(4), requiredHeight);
    setStatePosition(container, parentPosition, allStates);
end
usableCenter = [ ...
    parentPosition(1) + parentPosition(3) / 2, ...
    parentPosition(2) + titleHeight + ...
    (parentPosition(4) - titleHeight - bottomPadding) / 2];
childCenter = [(childBounds(1) + childBounds(3)) / 2, ...
    (childBounds(2) + childBounds(4)) / 2];
delta = usableCenter - childCenter;
imbalance = abs(delta) ./ max(parentPosition(3:4), 1);
if any(imbalance > 0.20)
    translateStates(states, delta, allStates);
end
end

function routing = routeLocalTransitions(container, states, transitions, graph)
transitionCount = numel(transitions);
routing = repmat(emptyRoutingRecord(), transitionCount, 1);
if transitionCount == 0
    return
end
positions = vertcat(states.Position);
stateBounds = rectangleBounds(positions);
mainOrder = zeros(numel(states), 1);
mainOrder(graph.MainPath) = 1:numel(graph.MainPath);

hubTransition = false(transitionCount, 1);
for transitionIndex = 1:transitionCount
    destinationIndex = graph.TransitionDestinationIndex(transitionIndex);
    sourceIndex = graph.TransitionSourceIndex(transitionIndex);
    hubTransition(transitionIndex) = sourceIndex > 0 && ...
        destinationIndex > 0 && graph.HubMask(destinationIndex) && ...
        mainOrder(destinationIndex) == 0;
end
sourceClock = nan(transitionCount, 1);
destinationClock = nan(transitionCount, 1);
hubDestinationEndpoint = nan(transitionCount, 2);

% Spread every multi-source error/fault fan-in while preserving the source
% left-to-right order at the destination boundary.
hubIndices = find(graph.HubMask & mainOrder == 0).';
for destinationIndex = hubIndices
    group = find(hubTransition & ...
        graph.TransitionDestinationIndex == destinationIndex);
    if isempty(group)
        continue
    end
    sourceX = zeros(numel(group), 1);
    sourceSsid = zeros(numel(group), 1);
    executionOrder = zeros(numel(group), 1);
    for groupIndex = 1:numel(group)
        sourceIndex = graph.TransitionSourceIndex(group(groupIndex));
        sourceX(groupIndex) = positions(sourceIndex, 1) + ...
            positions(sourceIndex, 3) / 2;
        sourceSsid(groupIndex) = graph.StateSsids(sourceIndex);
        executionOrder(groupIndex) = ...
            double(transitions(group(groupIndex)).ExecutionOrder);
    end
    [~, groupOrder] = sortrows( ...
        [sourceX, sourceSsid, executionOrder, group], [1 2 3 4]);
    group = group(groupOrder);
    destinationClock(group) = mod(linspace(10.5, 13.5, ...
        numel(group)), 12);
    destinationPosition = positions(destinationIndex, :);
    horizontalInset = min(max(30, 0.075 * destinationPosition(3)), ...
        destinationPosition(3) / 4);
    destinationX = linspace( ...
        destinationPosition(1) + horizontalInset, ...
        destinationPosition(1) + destinationPosition(3) - ...
        horizontalInset, numel(group));
    hubDestinationEndpoint(group, :) = [destinationX(:), ...
        repmat(destinationPosition(2), numel(group), 1)];
end

% Spread all downward exits from each source together. This prevents two
% different hub groups from accidentally reusing one source port.
for sourceIndex = 1:numel(states)
    group = find(hubTransition & ...
        graph.TransitionSourceIndex == sourceIndex);
    if isempty(group)
        continue
    end
    destinationX = zeros(numel(group), 1);
    executionOrder = zeros(numel(group), 1);
    for groupIndex = 1:numel(group)
        destinationIndex = ...
            graph.TransitionDestinationIndex(group(groupIndex));
        destinationX(groupIndex) = positions(destinationIndex, 1) + ...
            positions(destinationIndex, 3) / 2;
        executionOrder(groupIndex) = ...
            double(transitions(group(groupIndex)).ExecutionOrder);
    end
    [~, groupOrder] = sortrows( ...
        [destinationX, executionOrder, group], [1 2 3]);
    group = group(groupOrder);
    if isscalar(group)
        sourceClock(group) = 6;
    else
        % Along the bottom face Stateflow's clock direction runs from
        % right (5 o'clock) to left (7 o'clock).  Descending values keep
        % the logical group order left-to-right at both endpoints.
        sourceClock(group) = linspace(7, 5, numel(group));
    end
end

for transitionIndex = 1:transitionCount
    transition = transitions(transitionIndex);
    sourceIndex = graph.TransitionSourceIndex(transitionIndex);
    destinationIndex = graph.TransitionDestinationIndex(transitionIndex);
    record = emptyRoutingRecord();
    record.SSID = double(transition.SSIdNumber);
    sameRowInitialReturn = false;
    if sourceIndex > 0 && destinationIndex == graph.InitialIndex
        sourceCenterY = positions(sourceIndex, 2) + ...
            positions(sourceIndex, 4) / 2;
        destinationCenterY = positions(destinationIndex, 2) + ...
            positions(destinationIndex, 4) / 2;
        sameRowInitialReturn = abs(sourceCenterY - destinationCenterY) <= ...
            max(positions([sourceIndex destinationIndex], 4));
    end
    isMainReturn = sourceIndex > 0 && destinationIndex > 0 && ...
        ((mainOrder(sourceIndex) > 0 && mainOrder(destinationIndex) > 0 && ...
        mainOrder(destinationIndex) < mainOrder(sourceIndex)) || ...
        sameRowInitialReturn);
    isLowerRecovery = false;
    isLeftDownwardBarrier = false;
    if isa(container, "Stateflow.Chart") && sourceIndex > 0 && ...
            destinationIndex > 0
        sourceCenter = positions(sourceIndex, 1:2) + ...
            positions(sourceIndex, 3:4) / 2;
        destinationCenter = positions(destinationIndex, 1:2) + ...
            positions(destinationIndex, 3:4) / 2;
        verticalSeparation = sourceCenter(2) - destinationCenter(2);
        isLowerRecovery = verticalSeparation > ...
            max(positions([sourceIndex destinationIndex], 4)) && ...
            sourceCenter(1) > destinationCenter(1);
        chartCenterX = mean([stateBounds(1), stateBounds(3)]);
        downwardSeparation = destinationCenter(2) - sourceCenter(2);
        isLeftDownwardBarrier = downwardSeparation > ...
            max(positions([sourceIndex destinationIndex], 4)) && ...
            sourceCenter(1) < destinationCenter(1) && ...
            sourceCenter(1) < chartCenterX && ...
            destinationCenter(1) < chartCenterX;
    end
    if isLowerRecovery
        routeLowerRecovery(transition, positions, ...
            sourceIndex, destinationIndex);
        record.RoutingType = "LongOuter";
        record.Reason = "A sibling-state barrier required one short " + ...
            "bend around its lower-left corner.";
        transition.FontSize = 9;
        record.SourceOClock = double(transition.SourceOClock);
        record.DestinationOClock = double(transition.DestinationOClock);
        record.SourceEndpoint = double(transition.SourceEndpoint);
        record.MidPoint = double(transition.MidPoint);
        record.DestinationEndpoint = double(transition.DestinationEndpoint);
        routing(transitionIndex) = record;
        continue
    elseif isLeftDownwardBarrier
        routeLeftDownward(transition, positions, destinationIndex);
        record.RoutingType = "AdjacentVertical";
        record.Reason = "A direct downward diagonal to the upper-left " + ...
            "destination port preserves the neighboring recovery corridor.";
        transition.FontSize = 9;
        record.SourceOClock = double(transition.SourceOClock);
        record.DestinationOClock = double(transition.DestinationOClock);
        record.SourceEndpoint = double(transition.SourceEndpoint);
        record.MidPoint = double(transition.MidPoint);
        record.DestinationEndpoint = double(transition.DestinationEndpoint);
        routing(transitionIndex) = record;
        continue
    elseif isa(container, "Stateflow.Chart") && ~isMainReturn
        if sourceIndex == 0 && destinationIndex > 0
            transition.DestinationOClock = 12;
            destinationEndpoint = double(transition.DestinationEndpoint);
            transition.MidPoint = destinationEndpoint + [0 -45];
            transition.LabelPosition = [destinationEndpoint(1) - 1, ...
                destinationEndpoint(2) - 65, 2, 16];
        elseif sourceIndex > 0 && destinationIndex > 0
            midpoint = double(transition.MidPoint);
            midpoint(1) = min(max(midpoint(1), ...
                stateBounds(1) - 80), stateBounds(3) + 80);
            midpoint(2) = min(max(midpoint(2), ...
                stateBounds(2) - 80), stateBounds(4) + 80);
            transition.MidPoint = midpoint;
        end
        record.RoutingType = classifyExistingRoute( ...
            transition, positions, sourceIndex, destinationIndex);
        record.Reason = ...
            "Existing validated root route retained; no local reflow required.";
        record.PreserveLabel = false;
        record.SourceOClock = double(transition.SourceOClock);
        record.DestinationOClock = double(transition.DestinationOClock);
        record.SourceEndpoint = double(transition.SourceEndpoint);
        record.MidPoint = double(transition.MidPoint);
        record.DestinationEndpoint = double(transition.DestinationEndpoint);
        transition.FontSize = 9;
        routing(transitionIndex) = record;
        continue
    end
    if sourceIndex == 0 && destinationIndex > 0
        transition.DestinationOClock = 12;
        destinationEndpoint = double(transition.DestinationEndpoint);
        midpoint = destinationEndpoint + [0 -45];
        transition.MidPoint = midpoint;
        record.RoutingType = "Default";
        record.Reason = "Default transition kept close to its destination.";
    elseif sourceIndex > 0 && destinationIndex > 0
        isForwardAdjacent = mainOrder(sourceIndex) > 0 && ...
            mainOrder(destinationIndex) == mainOrder(sourceIndex) + 1;
        if isForwardAdjacent
            setTransitionPath(transition, 3, 9, "average", [NaN NaN]);
            record.RoutingType = "AdjacentHorizontal";
            record.Reason = "Consecutive states on the main path.";
        elseif hubTransition(transitionIndex)
            setTransitionPath(transition, sourceClock(transitionIndex), ...
                destinationClock(transitionIndex), "average", [NaN NaN]);
            sourceEndpoint = double(transition.SourceEndpoint);
            destinationEndpoint = ...
                hubDestinationEndpoint(transitionIndex, :);
            transition.MidPoint = ...
                (sourceEndpoint + destinationEndpoint) / 2;
            % Stateflow lets a normal transition destination endpoint be
            % assigned directly.  Applying it last preserves both the
            % bottom source port and the evenly ordered top fan-in port
            % across save/reload; setting only OClock values couples the
            % two endpoints and can move one of them to a rounded corner.
            transition.DestinationEndpoint = destinationEndpoint;
            record.RoutingType = "AdjacentVertical";
            record.Reason = ...
                "Ordered direct diagonal fan-in to a common lower state.";
        elseif isMainReturn
            transition.DestinationOClock = 12;
            transition.SourceOClock = 12;
            sourceEndpoint = double(transition.SourceEndpoint);
            destinationEndpoint = double(transition.DestinationEndpoint);
            laneY = min(positions(graph.MainPath, 2)) - 60;
            midpoint = [ ...
                mean([sourceEndpoint(1), destinationEndpoint(1)]), laneY];
            setTransitionPath(transition, 12, 12, "fixed", midpoint);
            record.RoutingType = "LongOuter";
            record.Reason = "Single short lane above the main row.";
        else
            [sourceOClock, destinationOClock] = nearestClocks( ...
                positions(sourceIndex, :), positions(destinationIndex, :));
            setTransitionPath(transition, sourceOClock, ...
                destinationOClock, "average", [NaN NaN]);
            sourceEndpoint = double(transition.SourceEndpoint);
            destinationEndpoint = double(transition.DestinationEndpoint);
            if segmentCrossesUnrelatedState(sourceEndpoint, ...
                    destinationEndpoint, positions, sourceIndex, ...
                    destinationIndex)
                [midpoint, sourceOClock, destinationOClock, side] = ...
                    shortOuterLane(positions, stateBounds, sourceIndex, ...
                    destinationIndex);
                setTransitionPath(transition, sourceOClock, ...
                    destinationOClock, "fixed", midpoint);
                record.RoutingType = "LongOuter";
                record.Reason = "Direct segment crossed a sibling; short " + ...
                    side + " lane selected.";
            else
                record.RoutingType = directRoutingType( ...
                    positions(sourceIndex, :), positions(destinationIndex, :));
                record.Reason = "Unobstructed shortest direct route.";
                if hasReciprocalOrParallel(transitions, transitionIndex)
                    applySmallSeparation(transition, transitionIndex);
                    record.Reason = record.Reason + ...
                        " Small separation retained for a reciprocal/parallel path.";
                end
            end
        end
    end
    transition.FontSize = 9;
    record.SourceOClock = double(transition.SourceOClock);
    record.DestinationOClock = double(transition.DestinationOClock);
    record.SourceEndpoint = double(transition.SourceEndpoint);
    record.MidPoint = double(transition.MidPoint);
    record.DestinationEndpoint = double(transition.DestinationEndpoint);
    routing(transitionIndex) = record;
end
end

function routing = minimizeSplineCurvature( ...
        states, transitions, graph, routing)
% Build the lowest-curvature geometry available without changing the
% Stateflow graph.  A normal Stateflow transition exposes exactly one
% MidPoint and is rendered as a spline.  Consequently a true polyline
% requires connective junctions and additional transitions, which would
% change SSIDs, object counts, endpoints, and execution semantics.  This
% comparison style straightens every unobstructed path and otherwise picks
% one collision-free elbow control point.
if isempty(states) || isempty(transitions)
    return
end
positions = vertcat(states.Position);
for transitionIndex = 1:numel(transitions)
    sourceIndex = graph.TransitionSourceIndex(transitionIndex);
    destinationIndex = graph.TransitionDestinationIndex(transitionIndex);
    if sourceIndex == 0 || destinationIndex == 0 || ...
            sourceIndex == destinationIndex
        continue
    end
    transition = transitions(transitionIndex);
    sourcePoint = double(transition.SourceEndpoint);
    destinationPoint = double(transition.DestinationEndpoint);
    directPoint = (sourcePoint + destinationPoint) / 2;
    if routing(transitionIndex).RoutingType == "LongOuter"
        routing(transitionIndex).Reason = ...
            routing(transitionIndex).Reason + ...
            " Single-bend comparison: long return retained because one " + ...
            "Stateflow midpoint cannot form a nonpenetrating polyline.";
        continue
    end
    if hasReciprocalOrParallel(transitions, transitionIndex)
        routing(transitionIndex).Reason = ...
            routing(transitionIndex).Reason + ...
            " Single-bend comparison: reciprocal separation retained.";
        continue
    end
    directClear = ~segmentCrossesUnrelatedState( ...
        sourcePoint, destinationPoint, positions, sourceIndex, ...
        destinationIndex);
    directMidPointClear = ~pointInside(directPoint, ...
        positions(sourceIndex, :)) && ~pointInside(directPoint, ...
        positions(destinationIndex, :));
    if directClear && directMidPointClear
        isHubFanIn = graph.HubMask(destinationIndex) && ...
            graph.InDegree(destinationIndex) >= 2;
        if ~isHubFanIn
            [sourceClock, destinationClock] = nearestClocks( ...
                positions(sourceIndex, :), ...
                positions(destinationIndex, :));
            setTransitionPath(transition, sourceClock, ...
                destinationClock, "average", [NaN NaN]);
        else
            transition.MidPoint = ...
                (double(transition.SourceEndpoint) + ...
                double(transition.DestinationEndpoint)) / 2;
        end
        routing(transitionIndex).Reason = ...
            routing(transitionIndex).Reason + ...
            " Single-bend comparison: unobstructed spline removed.";
    else
        candidates = [ ...
            sourcePoint(1), destinationPoint(2)
            destinationPoint(1), sourcePoint(2)];
        valid = false(2, 1);
        lengthPixels = inf(2, 1);
        for candidateIndex = 1:2
            candidate = candidates(candidateIndex, :);
            nondegenerate = norm(candidate - sourcePoint) > 5 && ...
                norm(candidate - destinationPoint) > 5;
            outsideEndpoints = ~pointInside(candidate, ...
                positions(sourceIndex, :)) && ...
                ~pointInside(candidate, positions(destinationIndex, :));
            firstClear = ~segmentCrossesUnrelatedState( ...
                sourcePoint, candidate, positions, sourceIndex, ...
                destinationIndex);
            secondClear = ~segmentCrossesUnrelatedState( ...
                candidate, destinationPoint, positions, sourceIndex, ...
                destinationIndex);
            valid(candidateIndex) = nondegenerate && outsideEndpoints && ...
                firstClear && secondClear;
            if valid(candidateIndex)
                lengthPixels(candidateIndex) = ...
                    norm(candidate - sourcePoint) + ...
                    norm(destinationPoint - candidate);
            end
        end
        if any(valid)
            [~, selected] = min(lengthPixels);
            transition.MidPoint = candidates(selected, :);
            routing(transitionIndex).Reason = ...
                routing(transitionIndex).Reason + ...
                " Single-bend comparison: one clear elbow control point.";
        else
            routing(transitionIndex).Reason = ...
                routing(transitionIndex).Reason + ...
                " Single-bend comparison: existing single control point " + ...
                "retained because both elbow candidates cross a state.";
        end
    end
    sourcePoint = double(transition.SourceEndpoint);
    destinationPoint = double(transition.DestinationEndpoint);
    routing(transitionIndex).SourceOClock = ...
        double(transition.SourceOClock);
    routing(transitionIndex).DestinationOClock = ...
        double(transition.DestinationOClock);
    routing(transitionIndex).SourceEndpoint = sourcePoint;
    routing(transitionIndex).MidPoint = double(transition.MidPoint);
    routing(transitionIndex).DestinationEndpoint = destinationPoint;
end
end

function routing = spreadSharedTransitionEndpoints( ...
        states, transitions, graph, routing)
% Separate transitions that leave the same face of a state.  Routing each
% transition independently can otherwise place a normal branch and a
% fault branch only a few pixels apart even though both selected the bottom
% face.
if isempty(states) || isempty(transitions)
    return
end
positions = vertcat(states.Position);
for sourceIndex = 1:numel(states)
    outgoing = find(graph.TransitionSourceIndex == sourceIndex & ...
        graph.TransitionDestinationIndex > 0);
    if numel(outgoing) < 2
        continue
    end
    face = strings(numel(outgoing), 1);
    for item = 1:numel(outgoing)
        face(item) = clockFace( ...
            double(transitions(outgoing(item)).SourceOClock));
    end
    for faceName = ["Top", "Right", "Bottom", "Left"]
        group = outgoing(face == faceName);
        if numel(group) < 2
            continue
        end
        destinationCenter = zeros(numel(group), 2);
        for item = 1:numel(group)
            destinationIndex = ...
                graph.TransitionDestinationIndex(group(item));
            destinationCenter(item, :) = ...
                positions(destinationIndex, 1:2) + ...
                positions(destinationIndex, 3:4) / 2;
        end
        if ismember(faceName, ["Top", "Bottom"])
            [~, order] = sortrows(destinationCenter, [1 2]);
        else
            [~, order] = sortrows(destinationCenter, [2 1]);
        end
        group = group(order);
        switch faceName
            case "Top"
                clocks = mod(linspace(10.5, 13.5, numel(group)), 12);
            case "Right"
                clocks = linspace(2, 4, numel(group));
            case "Bottom"
                clocks = linspace(7, 5, numel(group));
            otherwise
                clocks = linspace(10, 8, numel(group));
        end
        for item = 1:numel(group)
            transitionIndex = group(item);
            transition = transitions(transitionIndex);
            oldMidPoint = double(transition.MidPoint);
            oldDestinationPoint = ...
                routing(transitionIndex).DestinationEndpoint;
            transition.SourceOClock = clocks(item);
            % Setting SourceOClock can move the destination of a normal
            % spline.  Restore the validated destination last so fan-in
            % ports remain on the intended state face.
            if all(isfinite(oldDestinationPoint))
                transition.DestinationEndpoint = oldDestinationPoint;
            end
            sourcePoint = double(transition.SourceEndpoint);
            destinationPoint = double(transition.DestinationEndpoint);
            if routing(transitionIndex).RoutingType ~= "LongOuter"
                transition.MidPoint = ...
                    (sourcePoint + destinationPoint) / 2;
                if hasReciprocalOrParallel(transitions, transitionIndex)
                    applySmallSeparation(transition, transitionIndex);
                end
            else
                midpoint = oldMidPoint;
                if abs(oldMidPoint(1) - mean([ ...
                        routing(transitionIndex).SourceEndpoint(1), ...
                        routing(transitionIndex).DestinationEndpoint(1)])) < 5
                    midpoint(1) = mean([sourcePoint(1), ...
                        destinationPoint(1)]);
                end
                transition.MidPoint = midpoint;
            end
            routing(transitionIndex).SourceOClock = ...
                double(transition.SourceOClock);
            routing(transitionIndex).DestinationOClock = ...
                double(transition.DestinationOClock);
            routing(transitionIndex).SourceEndpoint = sourcePoint;
            routing(transitionIndex).MidPoint = ...
                double(transition.MidPoint);
            routing(transitionIndex).DestinationEndpoint = ...
                destinationPoint;
            routing(transitionIndex).Reason = ...
                routing(transitionIndex).Reason + ...
                " Shared source-face endpoints distributed.";
        end
    end
end
end

function face = clockFace(clock)
clock = mod(clock, 12);
if clock >= 10.5 || clock <= 1.5
    face = "Top";
elseif clock < 4.5
    face = "Right";
elseif clock <= 7.5
    face = "Bottom";
else
    face = "Left";
end
end

function setTransitionPath(transition, sourceOClock, ...
        destinationOClock, midpointPolicy, midpoint)
transition.DestinationOClock = destinationOClock;
if ~isempty(transition.Source) && isfinite(sourceOClock)
    transition.SourceOClock = sourceOClock;
end
if midpointPolicy == "average"
    midpoint = (double(transition.SourceEndpoint) + ...
        double(transition.DestinationEndpoint)) / 2;
end
transition.MidPoint = midpoint;
end

function [sourceOClock, destinationOClock] = nearestClocks( ...
        sourcePosition, destinationPosition)
sourceCenter = sourcePosition(1:2) + sourcePosition(3:4) / 2;
destinationCenter = destinationPosition(1:2) + ...
    destinationPosition(3:4) / 2;
delta = destinationCenter - sourceCenter;
sourceOClock = mod(atan2(delta(1), -delta(2)) * 6 / pi, 12);
destinationOClock = mod(sourceOClock + 6, 12);
end

function type = directRoutingType(sourcePosition, destinationPosition)
sourceCenter = sourcePosition(1:2) + sourcePosition(3:4) / 2;
destinationCenter = destinationPosition(1:2) + ...
    destinationPosition(3:4) / 2;
delta = abs(destinationCenter - sourceCenter);
if delta(1) >= delta(2)
    type = "AdjacentHorizontal";
else
    type = "AdjacentVertical";
end
end

function separated = hasReciprocalOrParallel(transitions, index)
separated = false;
transition = transitions(index);
if isempty(transition.Source) || isempty(transition.Destination)
    return
end
sourceSsid = double(transition.Source.SSIdNumber);
destinationSsid = double(transition.Destination.SSIdNumber);
for otherIndex = 1:numel(transitions)
    if otherIndex == index || isempty(transitions(otherIndex).Source) || ...
            isempty(transitions(otherIndex).Destination)
        continue
    end
    otherSource = double(transitions(otherIndex).Source.SSIdNumber);
    otherDestination = ...
        double(transitions(otherIndex).Destination.SSIdNumber);
    if (otherSource == sourceSsid && ...
            otherDestination == destinationSsid) || ...
            (otherSource == destinationSsid && ...
            otherDestination == sourceSsid)
        separated = true;
        return
    end
end
end

function applySmallSeparation(transition, transitionIndex)
sourceEndpoint = double(transition.SourceEndpoint);
destinationEndpoint = double(transition.DestinationEndpoint);
delta = destinationEndpoint - sourceEndpoint;
lengthPixels = norm(delta);
if lengthPixels < eps
    return
end
normal = [-delta(2), delta(1)] / lengthPixels;
direction = 1;
if mod(transitionIndex, 2) == 0
    direction = -1;
end
midpoint = (sourceEndpoint + destinationEndpoint) / 2 + ...
    direction * 28 * normal;
transition.MidPoint = midpoint;
end

function [midpoint, sourceClock, destinationClock, side] = ...
        shortOuterLane(positions, bounds, sourceIndex, destinationIndex)
sourceCenter = positions(sourceIndex, 1:2) + ...
    positions(sourceIndex, 3:4) / 2;
destinationCenter = positions(destinationIndex, 1:2) + ...
    positions(destinationIndex, 3:4) / 2;
meanX = mean([sourceCenter(1), destinationCenter(1)]);
if meanX <= (bounds(1) + bounds(3)) / 2
    laneX = bounds(1) - 60;
    sourceClock = 9;
    destinationClock = 9;
    side = "left";
else
    laneX = bounds(3) + 60;
    sourceClock = 3;
    destinationClock = 3;
    side = "right";
end
midpoint = [laneX, mean([sourceCenter(2), destinationCenter(2)])];
end

function routeLowerRecovery(transition, positions, ...
        sourceIndex, destinationIndex)
sourcePosition = positions(sourceIndex, :);
destinationPosition = positions(destinationIndex, :);
sourceCenter = sourcePosition(1:2) + sourcePosition(3:4) / 2;
destinationCenter = destinationPosition(1:2) + ...
    destinationPosition(3:4) / 2;
candidate = true(size(positions, 1), 1);
candidate([sourceIndex destinationIndex]) = false;
candidate = candidate & positions(:, 1) < sourceCenter(1) & ...
    positions(:, 1) + positions(:, 3) > destinationCenter(1) & ...
    positions(:, 2) < sourceCenter(2) & ...
    positions(:, 2) + positions(:, 4) / 2 < sourcePosition(2) & ...
    positions(:, 2) + positions(:, 4) > destinationCenter(2);
if any(candidate)
    laneX = min(positions(candidate, 1)) - 100;
    laneY = max(positions(candidate, 2) + ...
        positions(candidate, 4)) + 74;
else
    laneX = mean([sourceCenter(1), destinationCenter(1)]);
    laneY = mean([sourceCenter(2), destinationCenter(2)]);
end
destinationInset = min(30, destinationPosition(3) / 5);
destinationEndpoint = [ ...
    destinationPosition(1) + destinationPosition(3) - ...
    destinationInset, ...
    destinationPosition(2) + destinationPosition(4)];
transition.DestinationOClock = 6;
transition.SourceOClock = 9;
transition.MidPoint = [laneX laneY];
transition.DestinationEndpoint = destinationEndpoint;
end

function routeLeftDownward(transition, positions, destinationIndex)
destinationPosition = positions(destinationIndex, :);
destinationInset = min(30, destinationPosition(3) / 5);
destinationEndpoint = [destinationPosition(1) + destinationInset, ...
    destinationPosition(2)];
transition.DestinationOClock = 12;
transition.SourceOClock = 6;
sourceEndpoint = double(transition.SourceEndpoint);
transition.MidPoint = (sourceEndpoint + destinationEndpoint) / 2;
transition.DestinationEndpoint = destinationEndpoint;
end

function crosses = segmentCrossesUnrelatedState( ...
        firstPoint, secondPoint, positions, sourceIndex, destinationIndex)
crosses = false;
for stateIndex = 1:size(positions, 1)
    if stateIndex == sourceIndex || stateIndex == destinationIndex
        continue
    end
    rectangle = positions(stateIndex, :);
    rectangle = rectangle + [2 2 -4 -4];
    if segmentIntersectsRectangle(firstPoint, secondPoint, rectangle)
        crosses = true;
        return
    end
end
end

function intersects = segmentIntersectsRectangle(firstPoint, secondPoint, rectangle)
left = rectangle(1);
top = rectangle(2);
right = left + rectangle(3);
bottom = top + rectangle(4);
if pointInside(firstPoint, rectangle) || pointInside(secondPoint, rectangle)
    intersects = true;
    return
end
edges = [ ...
    left top right top
    right top right bottom
    right bottom left bottom
    left bottom left top];
intersects = false;
for edgeIndex = 1:4
    if segmentsIntersect(firstPoint, secondPoint, ...
            edges(edgeIndex, 1:2), edges(edgeIndex, 3:4))
        intersects = true;
        return
    end
end
end

function inside = pointInside(point, rectangle)
inside = point(1) > rectangle(1) && ...
    point(1) < rectangle(1) + rectangle(3) && ...
    point(2) > rectangle(2) && ...
    point(2) < rectangle(2) + rectangle(4);
end

function intersects = segmentsIntersect(a, b, c, d)
tolerance = 1e-9;
ab = b - a;
cd = d - c;
denominator = cross2d(ab, cd);
if abs(denominator) <= tolerance
    intersects = false;
    return
end
ac = c - a;
t = cross2d(ac, cd) / denominator;
u = cross2d(ac, ab) / denominator;
intersects = t > tolerance && t < 1 - tolerance && ...
    u > tolerance && u < 1 - tolerance;
end

function value = cross2d(first, second)
value = first(1) * second(2) - first(2) * second(1);
end

function placeLocalTransitionLabels(states, transitions, routing)
if isempty(transitions)
    return
end
positions = vertcat(states.Position);
bounds = rectangleBounds(positions);
labelSizes = zeros(numel(transitions), 2);
for index = 1:numel(transitions)
    labelSizes(index, :) = requiredTransitionLabelSize(transitions(index));
end
labelArea = prod(labelSizes, 2);
labelSsid = double([transitions.SSIdNumber]).';
[~, order] = sortrows([-labelArea, labelSsid], [1 2]);
placed = zeros(0, 4);
for index = reshape(order, 1, [])
    transition = transitions(index);
    if routing(index).PreserveLabel
        placed(end + 1, :) = double(transition.LabelPosition); %#ok<AGROW>
        continue
    end
    labelSize = labelSizes(index, :);
    if strlength(strtrim(string(transition.LabelString))) == 0
        destination = double(transition.DestinationEndpoint);
        transition.LabelPosition = [destination(1) - 1, ...
            destination(2) - 65, 2, 16];
        continue
    end
    anchor = double(transition.MidPoint);
    candidates = labelCandidates(anchor, labelSize, bounds);
    selected = candidates(1, :);
    bestScore = inf;
    for candidateIndex = 1:size(candidates, 1)
        candidate = candidates(candidateIndex, :);
        overlap = rectangleListOverlap(candidate, positions) + ...
            rectangleListOverlap(candidate, placed);
        pathIntersections = labelPathIntersectionCount( ...
            candidate, transitions, index);
        expansion = rectangleExpansion(candidate, bounds);
        score = 1e7 * pathIntersections + 1e6 * overlap + ...
            1e3 * max(expansion - 100, 0) + ...
            norm(candidate(1:2) + candidate(3:4) / 2 - anchor);
        if score < bestScore
            selected = candidate;
            bestScore = score;
        end
        if overlap == 0 && pathIntersections == 0 && expansion <= 100
            selected = candidate;
            break
        end
    end
    transition.LabelPosition = selected;
    placed(end + 1, :) = selected; %#ok<AGROW>
end

% Keep the routing table synchronized with the final API values.
for index = 1:numel(routing)
    if routing(index).SSID ~= 0
        routing(index).MidPoint = double(transitions(index).MidPoint);
    end
end
end

function candidates = labelCandidates(anchor, labelSize, bounds)
width = labelSize(1);
height = labelSize(2);
base = [ ...
    anchor(1) - width / 2, anchor(2) - height - 14
    anchor(1) - width / 2, anchor(2) + 14
    anchor(1) - width - 18, anchor(2) - height / 2
    anchor(1) + 18, anchor(2) - height / 2
    ];
candidates = [base, repmat(labelSize, size(base, 1), 1)];
bandY = unique([ ...
    max(20, bounds(2) - height - 20), ...
    bounds(2) + 20, ...
    (bounds(2) + bounds(4) - height) / 2, ...
    bounds(4) - height - 20, ...
    bounds(4) + 20]);
yMinimum = max(20, bounds(2) - 100);
yMaximum = max(yMinimum, bounds(4) + 100 - height);
bandY = unique([bandY, linspace(yMinimum, yMaximum, 17)]);
xMinimum = max(20, bounds(1) - 90);
xMaximum = max(xMinimum, bounds(3) + 90 - width);
xValues = unique([anchor(1) - width / 2, ...
    linspace(xMinimum, xMaximum, 31)]);
for y = reshape(bandY, 1, [])
    for x = reshape(xValues, 1, [])
        candidates(end + 1, :) = [x y width height]; %#ok<AGROW>
    end
end
candidates(:, 1:2) = max(candidates(:, 1:2), 20);
end

function count = labelPathIntersectionCount( ...
        rectangle, transitions, excludedIndex)
inset = 3;
rectangle = rectangle + [inset inset -2 * inset -2 * inset];
if rectangle(3) <= 0 || rectangle(4) <= 0
    count = 0;
    return
end
count = 0;
for index = 1:numel(transitions)
    if index == excludedIndex
        continue
    end
    points = [double(transitions(index).SourceEndpoint); ...
        double(transitions(index).MidPoint); ...
        double(transitions(index).DestinationEndpoint)];
    if segmentIntersectsRectangle(points(1, :), points(2, :), ...
            rectangle) || segmentIntersectsRectangle( ...
            points(2, :), points(3, :), rectangle)
        count = count + 1;
    end
end
end

function overlapArea = rectangleListOverlap(rectangle, rectangles)
overlapArea = 0;
for index = 1:size(rectangles, 1)
    overlapWidth = max(0, min( ...
        rectangle(1) + rectangle(3), ...
        rectangles(index, 1) + rectangles(index, 3)) - ...
        max(rectangle(1), rectangles(index, 1)));
    overlapHeight = max(0, min( ...
        rectangle(2) + rectangle(4), ...
        rectangles(index, 2) + rectangles(index, 4)) - ...
        max(rectangle(2), rectangles(index, 2)));
    overlapArea = overlapArea + overlapWidth * overlapHeight;
end
end

function expansion = rectangleExpansion(rectangle, bounds)
expansion = max([ ...
    bounds(1) - rectangle(1), ...
    rectangle(1) + rectangle(3) - bounds(3), ...
    bounds(2) - rectangle(2), ...
    rectangle(2) + rectangle(4) - bounds(4), 0]);
end

function sizePixels = requiredStateSize(state)
label = replace(string(state.LabelString), sprintf("\t"), "    ");
lines = splitlines(label);
maximumCharacters = max(strlength(lines));
width = double(maximumCharacters) * 0.47 * 10 + 18;
height = numel(lines) * 1.35 * 10 + 24;
sizePixels = [max(180, width), max(100, height)];
end

function sizePixels = requiredTransitionLabelSize(transition)
label = replace(string(transition.LabelString), sprintf("\t"), "    ");
if strlength(strtrim(label)) == 0
    sizePixels = [2 16];
    return
end
lines = splitlines(label);
maximumCharacters = max(strlength(lines));
width = min(820, max(90, double(maximumCharacters) * 0.47 * 9 + 18));
height = max(20, numel(lines) * 1.35 * 9 + 8);
sizePixels = [ceil(width), ceil(height)];
end

function setStatePosition(state, newPosition, allStates)
oldPosition = double(state.Position);
delta = newPosition(1:2) - oldPosition(1:2);
descendants = sameSubviewerDescendants(state, allStates);
if isempty(descendants)
    state.Position = newPosition;
    state.FontSize = 10;
    return
end
parentSsids = zeros(numel(descendants), 1);
for index = 1:numel(descendants)
    parent = descendants(index).getParent;
    assert(isa(parent, "Stateflow.State"), ...
        "AMR:Layout:UnexpectedDescendantParent", ...
        "Composite descendants must have a Stateflow.State parent.");
    parentSsids(index) = double(parent.SSIdNumber);
end
oldRightBottom = oldPosition(1:2) + oldPosition(3:4);
newRightBottom = newPosition(1:2) + newPosition(3:4);
envelopeTopLeft = min(oldPosition(1:2), newPosition(1:2));
envelopeRightBottom = max(oldRightBottom, newRightBottom);
state.Position = [envelopeTopLeft, ...
    envelopeRightBottom - envelopeTopLeft];
for index = 1:numel(descendants)
    position = double(descendants(index).Position);
    descendants(index).Position = [position(1:2) + delta, position(3:4)];
end
state.Position = newPosition;
state.FontSize = 10;
for index = 1:numel(descendants)
    parent = descendants(index).getParent;
    assert(isa(parent, "Stateflow.State") && ...
        double(parent.SSIdNumber) == parentSsids(index), ...
        "AMR:Layout:DescendantReparented", ...
        "Moving composite SSID %d reparented descendant SSID %d.", ...
        state.SSIdNumber, descendants(index).SSIdNumber);
end
end

function descendants = sameSubviewerDescendants(state, allStates)
mask = false(size(allStates));
for index = 1:numel(allStates)
    if isequal(allStates(index), state) || ...
            ~isequal(allStates(index).Subviewer, state.Subviewer)
        continue
    end
    parent = allStates(index).getParent;
    while isa(parent, "Stateflow.State")
        if isequal(parent, state)
            mask(index) = true;
            break
        end
        parent = parent.getParent;
    end
end
descendants = allStates(mask);
end

function present = hasDirectStateChildren(state, allStates)
present = any(arrayfun(@(item) ...
    isequal(item.getParent, state), allStates));
end

function translateStates(states, delta, allStates)
if all(abs(delta) < eps)
    for state = reshape(states, 1, [])
        state.FontSize = 10;
    end
    return
end
for state = reshape(states, 1, [])
    position = double(state.Position);
    setStatePosition(state, [position(1:2) + delta, position(3:4)], ...
        allStates);
end
end

function matrix = positionMatrix(states)
matrix = zeros(numel(states), 5);
for index = 1:numel(states)
    matrix(index, :) = [double(states(index).SSIdNumber), ...
        double(states(index).Position)];
end
matrix = sortrows(matrix, 1);
end

function [uniform, delta] = uniformStateTranslation(before, after)
uniform = false;
delta = [0 0];
if ~isequal(size(before), size(after)) || isempty(before) || ...
        any(before(:, 1) ~= after(:, 1)) || ...
        any(abs(before(:, 4:5) - after(:, 4:5)) > 1e-6, "all")
    return
end
deltas = after(:, 2:3) - before(:, 2:3);
delta = deltas(1, :);
uniform = all(abs(deltas - delta) <= 1e-6, "all");
end

function snapshot = transitionGeometrySnapshot(transitions)
snapshot = repmat(struct( ...
    SourceOClock=NaN, DestinationOClock=NaN, ...
    SourceEndpoint=[NaN NaN], DestinationEndpoint=[NaN NaN], ...
    MidPoint=[NaN NaN], LabelPosition=[NaN NaN NaN NaN]), ...
    numel(transitions), 1);
for index = 1:numel(transitions)
    snapshot(index).SourceOClock = ...
        double(transitions(index).SourceOClock);
    snapshot(index).DestinationOClock = ...
        double(transitions(index).DestinationOClock);
    snapshot(index).SourceEndpoint = ...
        double(transitions(index).SourceEndpoint);
    snapshot(index).DestinationEndpoint = ...
        double(transitions(index).DestinationEndpoint);
    snapshot(index).MidPoint = double(transitions(index).MidPoint);
    snapshot(index).LabelPosition = ...
        double(transitions(index).LabelPosition);
end
end

function translateExistingTransitionGeometry( ...
        transitions, snapshot, delta)
for index = 1:numel(transitions)
    transition = transitions(index);
    transition.DestinationOClock = ...
        snapshot(index).DestinationOClock;
    if isempty(transition.Source)
        transition.SourceEndpoint = ...
            snapshot(index).SourceEndpoint + delta;
    else
        transition.SourceOClock = snapshot(index).SourceOClock;
    end
    transition.MidPoint = snapshot(index).MidPoint + delta;
    transition.DestinationEndpoint = ...
        snapshot(index).DestinationEndpoint + delta;
    label = snapshot(index).LabelPosition;
    label(1:2) = label(1:2) + delta;
    transition.LabelPosition = label;
    transition.FontSize = 9;
end
end

function bounds = rectangleBounds(positions)
if isempty(positions)
    bounds = [NaN NaN NaN NaN];
    return
end
bounds = [min(positions(:, 1)), min(positions(:, 2)), ...
    max(positions(:, 1) + positions(:, 3)), ...
    max(positions(:, 2) + positions(:, 4))];
end

function record = buildContainerRecord(container, states, transitions, ...
        depth, beforePositions, iterationCount, routing)
record = emptyContainerRecord();
record.Path = containerDisplay(container);
record.Name = containerName(container);
record.Kind = containerKind(container);
record.Depth = depth;
record.DirectStateCount = numel(states);
record.DirectTransitionCount = numel(transitions);
record.BeforePositions = {beforePositions};
record.AfterPositions = {positionMatrix(states)};
record.IterationCount = iterationCount;
record.Routing = {struct2table(routing)};
end

function record = emptyContainerRecord()
record = struct( ...
    Path="", Name="", Kind="", Depth=0, ...
    DirectStateCount=0, DirectTransitionCount=0, ...
    BeforePositions={{zeros(0, 5)}}, ...
    AfterPositions={{zeros(0, 5)}}, ...
    IterationCount=0, Routing={{table}});
end

function record = emptyRoutingRecord()
record = struct(SSID=0, RoutingType="", Reason="", ...
    PreserveLabel=false, SourceOClock=NaN, DestinationOClock=NaN, ...
    SourceEndpoint=[NaN NaN], MidPoint=[NaN NaN], ...
    DestinationEndpoint=[NaN NaN]);
end

function routing = captureExistingRoutes(states, transitions, graph)
routing = repmat(emptyRoutingRecord(), numel(transitions), 1);
positions = vertcat(states.Position);
mainOrder = zeros(numel(states), 1);
mainOrder(graph.MainPath) = 1:numel(graph.MainPath);
for index = 1:numel(transitions)
    transition = transitions(index);
    record = emptyRoutingRecord();
    record.SSID = double(transition.SSIdNumber);
    sourceIndex = graph.TransitionSourceIndex(index);
    destinationIndex = graph.TransitionDestinationIndex(index);
    if isempty(transition.Source)
        record.RoutingType = "Default";
    elseif isequal(transition.Source, transition.Destination)
        record.RoutingType = "SelfLoop";
    elseif hasReciprocalOrParallel(transitions, index)
        record.RoutingType = "Bidirectional";
    elseif sourceIndex > 0 && destinationIndex > 0
        isMainReturn = mainOrder(sourceIndex) > 0 && ...
            mainOrder(destinationIndex) > 0 && ...
            mainOrder(destinationIndex) < mainOrder(sourceIndex);
        if isMainReturn
            record.RoutingType = "LongOuter";
        else
            record.RoutingType = directRoutingType( ...
                positions(sourceIndex, :), positions(destinationIndex, :));
        end
    else
        record.RoutingType = "LongOuter";
    end
    record.Reason = ...
        "Subviewer state geometry already met local quality thresholds.";
    record.PreserveLabel = false;
    if sourceIndex > 0 && destinationIndex > 0 && ...
            sourceIndex ~= destinationIndex && ...
            ~hasReciprocalOrParallel(transitions, index)
        sourceEndpoint = double(transition.SourceEndpoint);
        destinationEndpoint = double(transition.DestinationEndpoint);
        deviation = pointToSegmentDistanceLocal( ...
            double(transition.MidPoint), sourceEndpoint, ...
            destinationEndpoint);
        if deviation > 5
            previousSourceOClock = double(transition.SourceOClock);
            previousDestinationOClock = ...
                double(transition.DestinationOClock);
            previousMidPoint = double(transition.MidPoint);
            previousDestinationEndpoint = ...
                double(transition.DestinationEndpoint);
            [sourceOClock, destinationOClock] = nearestClocks( ...
                positions(sourceIndex, :), positions(destinationIndex, :));
            setTransitionPath(transition, sourceOClock, ...
                destinationOClock, "average", [NaN NaN]);
            directIsClear = directSegmentIsClear( ...
                double(transition.SourceEndpoint), ...
                double(transition.DestinationEndpoint), positions, ...
                sourceIndex, destinationIndex) && ...
                ~segmentCrossesOtherTransition( ...
                double(transition.SourceEndpoint), ...
                double(transition.DestinationEndpoint), ...
                transitions, index);
            if directIsClear
                record.RoutingType = directRoutingType( ...
                    positions(sourceIndex, :), ...
                    positions(destinationIndex, :));
                record.Reason = "Clear direct-route opportunity with " + ...
                    "nearest boundary ports straightened.";
            else
                transition.DestinationOClock = ...
                    previousDestinationOClock;
                transition.SourceOClock = previousSourceOClock;
                transition.MidPoint = previousMidPoint;
                transition.DestinationEndpoint = ...
                    previousDestinationEndpoint;
                if record.RoutingType ~= "Bidirectional"
                    record.RoutingType = "LongOuter";
                end
            end
        end
    end
    record.SourceOClock = double(transition.SourceOClock);
    record.DestinationOClock = double(transition.DestinationOClock);
    record.SourceEndpoint = double(transition.SourceEndpoint);
    record.MidPoint = double(transition.MidPoint);
    record.DestinationEndpoint = double(transition.DestinationEndpoint);
    transition.FontSize = 9;
    routing(index) = record;
end
end

function crosses = segmentCrossesOtherTransition( ...
        firstPoint, secondPoint, transitions, excludedIndex)
crosses = false;
for index = 1:numel(transitions)
    if index == excludedIndex
        continue
    end
    points = [double(transitions(index).SourceEndpoint); ...
        double(transitions(index).MidPoint); ...
        double(transitions(index).DestinationEndpoint)];
    if segmentsIntersect(firstPoint, secondPoint, ...
            points(1, :), points(2, :)) || ...
            segmentsIntersect(firstPoint, secondPoint, ...
            points(2, :), points(3, :))
        crosses = true;
        return
    end
end
end

function clear = directSegmentIsClear(firstPoint, secondPoint, ...
        positions, sourceIndex, destinationIndex)
clear = ~segmentCrossesUnrelatedState(firstPoint, secondPoint, ...
    positions, sourceIndex, destinationIndex);
if ~clear || abs(firstPoint(2) - secondPoint(2)) > 2
    return
end
for stateIndex = 1:size(positions, 1)
    if stateIndex == sourceIndex || stateIndex == destinationIndex
        continue
    end
    sameRow = firstPoint(2) >= positions(stateIndex, 2) - 2 && ...
        firstPoint(2) <= positions(stateIndex, 2) + ...
        positions(stateIndex, 4) + 2;
    between = positions(stateIndex, 1) < ...
        max(firstPoint(1), secondPoint(1)) && ...
        positions(stateIndex, 1) + positions(stateIndex, 3) > ...
        min(firstPoint(1), secondPoint(1));
    if sameRow && between
        clear = false;
        return
    end
end
end

function distance = pointToSegmentDistanceLocal(point, first, second)
segment = second - first;
denominator = dot(segment, segment);
if denominator <= eps
    distance = norm(point - first);
    return
end
parameter = dot(point - first, segment) / denominator;
parameter = min(max(parameter, 0), 1);
projection = first + parameter * segment;
distance = norm(point - projection);
end

function type = classifyExistingRoute( ...
        transition, positions, sourceIndex, destinationIndex)
if isempty(transition.Source)
    type = "Default";
elseif sourceIndex == destinationIndex
    type = "SelfLoop";
elseif hasExistingReciprocal(transition)
    type = "Bidirectional";
elseif sourceIndex > 0 && destinationIndex > 0
    type = directRoutingType( ...
        positions(sourceIndex, :), positions(destinationIndex, :));
else
    type = "LongOuter";
end
end

function present = hasExistingReciprocal(transition)
present = false;
if isempty(transition.Source) || isempty(transition.Destination)
    return
end
siblings = transition.getParent.find("-isa", "Stateflow.Transition");
for index = 1:numel(siblings)
    if isequal(siblings(index), transition) || ...
            isempty(siblings(index).Source) || ...
            isempty(siblings(index).Destination)
        continue
    end
    if isequal(siblings(index).Source, transition.Destination) && ...
            isequal(siblings(index).Destination, transition.Source)
        present = true;
        return
    end
end
end

function name = containerName(container)
name = string(container.Name);
end

function kind = containerKind(container)
if isa(container, "Stateflow.Chart")
    kind = "Chart";
elseif logical(container.IsSubchart)
    kind = "Subchart";
else
    kind = "CompositeState";
end
end

function displayName = containerDisplay(container)
if isa(container, "Stateflow.Chart")
    displayName = string(container.Path);
else
    displayName = string(container.Path) + "/" + string(container.Name);
end
end

function tableValue = collectStateTable(states)
count = numel(states);
ssid = zeros(count, 1);
name = strings(count, 1);
parent = strings(count, 1);
subviewer = strings(count, 1);
position = zeros(count, 4);
for index = 1:count
    ssid(index) = double(states(index).SSIdNumber);
    name(index) = string(states(index).Name);
    parent(index) = containerDisplay(states(index).getParent);
    subviewer(index) = containerDisplay(states(index).Subviewer);
    position(index, :) = double(states(index).Position);
end
tableValue = table(ssid, name, parent, subviewer, position, ...
    VariableNames=["SSID", "State", "Parent", "Subviewer", "Position"]);
tableValue = sortrows(tableValue, "SSID");
end

function tableValue = collectTransitionTable(transitions)
count = numel(transitions);
ssid = zeros(count, 1);
source = strings(count, 1);
destination = strings(count, 1);
midpoint = zeros(count, 2);
labelPosition = zeros(count, 4);
for index = 1:count
    ssid(index) = double(transitions(index).SSIdNumber);
    if isempty(transitions(index).Source)
        source(index) = "<default>";
    else
        source(index) = string(transitions(index).Source.Name);
    end
    destination(index) = string(transitions(index).Destination.Name);
    midpoint(index, :) = double(transitions(index).MidPoint);
    labelPosition(index, :) = double(transitions(index).LabelPosition);
end
tableValue = table(ssid, source, destination, midpoint, labelPosition, ...
    VariableNames=["SSID", "Source", "Destination", ...
    "MidPoint", "LabelPosition"]);
tableValue = sortrows(tableValue, "SSID");
end
