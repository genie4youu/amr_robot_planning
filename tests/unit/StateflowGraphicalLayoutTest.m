classdef StateflowGraphicalLayoutTest < matlab.unittest.TestCase
    %STATEFLOWGRAPHICALLAYOUTTEST Graphical quality gate for the supervisor.

    properties (SetAccess = private)
        LayoutReport
        ModelFile
    end

    methods (TestClassSetup)
        function inspectSupervisorChart(testCase)
            projectRoot = fileparts(fileparts( ...
                fileparts(mfilename("fullpath"))));
            sourceFolder = fullfile(projectRoot, "src");
            modelFile = string(getenv( ...
                "AMR_SUPERVISOR_LAYOUT_MODEL"));
            if strlength(modelFile) == 0
                modelFile = fullfile(projectRoot, "models", ...
                    "mission_supervisor", "amr_mission_supervisor.slx");
            end
            testCase.assertTrue(isfile(modelFile), ...
                "Layout model does not exist: " + modelFile);
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture(sourceFolder));
            testCase.ModelFile = modelFile;
            testCase.LayoutReport = ...
                amr.stateflow.inspectGraphicalLayout( ...
                modelFile, "MissionSupervisor");
        end
    end

    methods (Test)
        function hardGraphicalViolationsAreAbsent(testCase)
            testCase.verifyEqual( ...
                testCase.LayoutReport.HardViolationCount, uint32(0), ...
                testCase.LayoutReport.HardDiagnostic);
        end

        function stateTextFitAdvisoriesAreAbsent(testCase)
            testCase.verifyEqual( ...
                testCase.LayoutReport.AdvisoryCount, uint32(0), ...
                testCase.LayoutReport.AdvisoryDiagnostic);
        end

        function pathApproximationIsReported(testCase)
            testCase.verifyEqual( ...
                testCase.LayoutReport.PathApproximation, ...
                "SourceEndpoint-to-MidPoint-to-" + ...
                "DestinationEndpoint line segments");
        end

        function routingInventoryCoversEveryTransition(testCase)
            expectedCount = double( ...
                testCase.LayoutReport.TransitionCount);

            actualCount = height( ...
                testCase.LayoutReport.RoutingInventory);

            testCase.verifyEqual(actualCount, expectedCount);
        end

        function routingCompletenessViolationsAreAbsent(testCase)
            expectedCount = uint32(0);

            actualCount = testCase.LayoutReport. ...
                RoutingCompletenessViolationCount;

            testCase.verifyEqual(expectedCount, actualCount, ...
                testCase.LayoutReport.RoutingDiagnostic);
        end

        function exactRoutingGeometryChecksAreClear(testCase)
            expectedCounts = zeros(1, 6, "uint32");

            actualCounts = [
                testCase.LayoutReport. ...
                RoutingCompletenessViolationCount
                testCase.LayoutReport. ...
                MidPointStateIntersectionCount
                testCase.LayoutReport. ...
                SelfLoopOClockViolationCount
                testCase.LayoutReport. ...
                ExcessiveOuterLaneClearanceViolationCount
                testCase.LayoutReport. ...
                ScopeCanvasBalanceViolationCount
                testCase.LayoutReport. ...
                BidirectionalOuterDetourViolationCount
                ].';

            testCase.verifyEqual(actualCounts, expectedCounts, ...
                testCase.LayoutReport.RoutingDiagnostic);
        end

        function routingCountMatchesDiagnosticTables(testCase)
            expectedCount = uint32(sum([
                height(testCase.LayoutReport. ...
                RoutingCompletenessViolations)
                height(testCase.LayoutReport.CompletePathOverlaps)
                height(testCase.LayoutReport. ...
                MidPointStateIntersections)
                height(testCase.LayoutReport. ...
                SelfLoopOClockViolations)
                height(testCase.LayoutReport. ...
                OuterLaneSpacingViolations)
                height(testCase.LayoutReport. ...
                OuterLaneEnvelopeClearanceViolations)
                height(testCase.LayoutReport. ...
                ExcessiveOuterLaneClearanceViolations)
                height(testCase.LayoutReport. ...
                ScopeCanvasBalanceViolations)
                height(testCase.LayoutReport. ...
                BidirectionalOuterDetourViolations)
                height(testCase.LayoutReport. ...
                ShortTransitionStraightnessViolations)
                height(testCase.LayoutReport. ...
                BidirectionalTransitionViolations)
                height(testCase.LayoutReport.PathShapeViolations)
                height(testCase.LayoutReport.LabelPathOverlaps)
                height(testCase.LayoutReport. ...
                PathPathCrossingOrPartialOverlaps)
                ]));

            actualCount = testCase.LayoutReport.RoutingViolationCount;

            testCase.verifyEqual(actualCount, expectedCount);
        end

        function outerLaneEnvelopeCountMatchesTable(testCase)
            expectedCount = uint32(height( ...
                testCase.LayoutReport. ...
                OuterLaneEnvelopeClearanceViolations));

            actualCount = testCase.LayoutReport. ...
                OuterLaneEnvelopeClearanceViolationCount;

            testCase.verifyEqual(actualCount, expectedCount);
        end

        function outerLaneEnvelopeClearanceIsSatisfied(testCase)
            expectedCount = uint32(0);

            actualCount = testCase.LayoutReport. ...
                OuterLaneEnvelopeClearanceViolationCount;

            testCase.verifyEqual(actualCount, expectedCount, ...
                testCase.LayoutReport.RoutingDiagnostic);
            testCase.verifyEqual( ...
                testCase.LayoutReport.Rules. ...
                MinimumOuterLaneEnvelopeClearancePixels, 40);
        end

        function excessiveOuterLanesAreAbsent(testCase)
            testCase.verifyEqual( ...
                testCase.LayoutReport. ...
                ExcessiveOuterLaneClearanceViolationCount, uint32(0), ...
                testCase.LayoutReport.RoutingDiagnostic);
            testCase.verifyEqual( ...
                testCase.LayoutReport.Rules. ...
                MaximumOuterLaneEnvelopeClearancePixels, 180);
        end

        function subviewerCanvasBalanceIsSatisfied(testCase)
            inventory = testCase.LayoutReport.ScopeCanvasInventory;

            testCase.verifyEqual( ...
                testCase.LayoutReport.ScopeCanvasBalanceViolationCount, ...
                uint32(0), testCase.LayoutReport.RoutingDiagnostic);
            testCase.verifyGreaterThanOrEqual( ...
                inventory.StateBBoxUtilization, ...
                testCase.LayoutReport.Rules. ...
                MinimumScopeStateBBoxUtilization);
            testCase.verifyLessThanOrEqual( ...
                [inventory.LeftExpansion; inventory.RightExpansion; ...
                inventory.TopExpansion; inventory.BottomExpansion], ...
                testCase.LayoutReport.Rules. ...
                MaximumScopeCanvasExpansionPixels);
        end

        function bidirectionalOuterDetoursAreAbsent(testCase)
            testCase.verifyEqual( ...
                testCase.LayoutReport. ...
                BidirectionalOuterDetourViolationCount, uint32(0), ...
                testCase.LayoutReport.RoutingDiagnostic);
            testCase.verifyEqual( ...
                testCase.LayoutReport.Rules. ...
                MaximumBidirectionalEnvelopeExcursionPixels, 120);
            testCase.verifyEqual( ...
                testCase.LayoutReport.Rules. ...
                MaximumBidirectionalDetourRatio, 2.20);
        end

        function additionalApproximateCountsMatchTables(testCase)
            expectedCounts = uint32([
                height(testCase.LayoutReport.LabelPathOverlaps)
                height(testCase.LayoutReport. ...
                PathPathCrossingOrPartialOverlaps)
                ]).';

            actualCounts = [
                testCase.LayoutReport.LabelPathOverlapCount
                testCase.LayoutReport. ...
                PathPathCrossingOrPartialOverlapCount
                ].';

            testCase.verifyEqual(actualCounts, expectedCounts);
        end

        function recursiveHierarchyInventoryIsComplete(testCase)
            inventory = testCase.LayoutReport.HierarchyInventory;

            testCase.verifyFalse(isempty(inventory));
            testCase.verifyEqual(sum(inventory.DirectStateCount), ...
                double(testCase.LayoutReport.StateCount));
            testCase.verifyEqual(sum(inventory.DirectTransitionCount), ...
                double(testCase.LayoutReport.TransitionCount));
            testCase.verifyTrue(any(inventory.Kind == "Chart"));
            testCase.verifyTrue(any(inventory.Kind == "CompositeState"));
            testCase.verifyTrue(any(inventory.Kind == "Subchart"));
            testCase.verifyTrue(all(isfinite( ...
                inventory.StateWidth(inventory.DirectStateCount > 0))));
            testCase.verifyTrue(all(isfinite( ...
                inventory.GraphicWidth(inventory.DirectStateCount > 0))));
        end

        function hierarchyLayoutQualityChecksAreClear(testCase)
            componentCounts = [
                testCase.LayoutReport.OversizedStateViolationCount
                testCase.LayoutReport.LocalCoordinateOffsetViolationCount
                testCase.LayoutReport. ...
                TransitionCanvasExpansionWarningCount
                testCase.LayoutReport.DirectRouteOpportunityViolationCount
                testCase.LayoutReport.SubviewerCornerBiasViolationCount
                ];
            testCase.verifyEqual( ...
                testCase.LayoutReport.LayoutQualityViolationCount, ...
                uint32(sum(componentCounts)));
            % The user-facing primary model is the most important artifact.
            % Do not relax this gate based on a candidate filename: that
            % allowed the primary model to keep five upper-left-biased
            % subcharts while only specially named work files were checked.
            testCase.verifyEqual( ...
                testCase.LayoutReport.LayoutQualityViolationCount, ...
                uint32(0), ...
                testCase.LayoutReport.LayoutQualityDiagnostic);
            testCase.verifyEqual( ...
                componentCounts, zeros(5, 1, "uint32"));
        end

        function subchartContentsUseNormalizedLocalCoordinates(testCase)
            inventory = testCase.LayoutReport.HierarchyInventory;
            subcharts = inventory(inventory.Kind == "Subchart", :);

            testCase.verifyFalse(isempty(subcharts));
            rules = testCase.LayoutReport.Rules;
            testCase.verifyGreaterThanOrEqual(subcharts.StateMinX, ...
                rules.MinimumSubviewerStateMinX);
            testCase.verifyLessThanOrEqual(subcharts.StateMinX, ...
                rules.MaximumSubviewerStateMinX);
            testCase.verifyGreaterThanOrEqual(subcharts.StateMinY, ...
                rules.MinimumSubviewerStateMinY);
            testCase.verifyLessThanOrEqual(subcharts.StateMinY, ...
                rules.MaximumSubviewerStateMinY);
        end

        function subchartSavedViewportsRemainReadable(testCase)
            [~, modelName] = fileparts(testCase.ModelFile);
            wasLoaded = bdIsLoaded(modelName);
            if ~wasLoaded
                open_system(testCase.ModelFile);
            end
            cleanup = onCleanup(@() closeIfOriginallyClosed( ...
                modelName, wasLoaded));
            dirtyBefore = string(get_param(modelName, "Dirty"));
            chart = find(sfroot, "-isa", "Stateflow.Chart", ...
                "Path", modelName + "/MissionSupervisor");
            testCase.assertNotEmpty(chart);
            states = chart.find("-isa", "Stateflow.State");
            subcharts = states(logical([states.IsSubchart]));
            inventory = testCase.LayoutReport.HierarchyInventory;
            inventory = inventory(inventory.Kind == "Subchart", :);
            savedZoomFactors = nan(numel(subcharts), 1);
            fitZoomFactors = nan(numel(subcharts), 1);
            for index = 1:numel(subcharts)
                row = inventory(inventory.Name == ...
                    string(subcharts(index).Name), :);
                testCase.assertEqual(height(row), 1, ...
                    "Subviewer inventory must uniquely identify each subchart.");
                view(subcharts(index));
                drawnow;
                savedZoom = chart.Editor.ZoomFactor;
                savedZoomFactors(index) = savedZoom;
                fitToView(subcharts(index));
                drawnow;
                fitZoom = chart.Editor.ZoomFactor;
                fitZoomFactors(index) = fitZoom;
                chart.Editor.ZoomFactor = savedZoom;
            end
            view(chart);
            drawnow;
            widthUtilization = inventory.GraphicWidth ./ ...
                inventory.CanvasWidth;
            heightUtilization = inventory.GraphicHeight ./ ...
                inventory.CanvasHeight;
            maximumUtilization = max([widthUtilization, ...
                heightUtilization], [], 2);
            rules = testCase.LayoutReport.Rules;
            testCase.verifyTrue(all(isfinite(savedZoomFactors) & ...
                savedZoomFactors > 0));
            testCase.verifyTrue(all(isfinite(fitZoomFactors) & ...
                fitZoomFactors > 0));
            testCase.verifyGreaterThanOrEqual(maximumUtilization, ...
                rules.MinimumSubviewerPageAxisUtilization, ...
                "Space/Fit page leaves excessive empty space.");
            testCase.verifyLessThanOrEqual(widthUtilization, ...
                rules.MaximumSubviewerPageWidthUtilization);
            testCase.verifyLessThanOrEqual(heightUtilization, ...
                rules.MaximumSubviewerPageHeightUtilization);
            testCase.verifyEqual(string(get_param(modelName, "Dirty")), ...
                dirtyBefore, "Viewport verification must not dirty the model.");
        end

        function conservativePathWarningsMatchReviewedPairs(testCase)
            warnings = testCase.LayoutReport. ...
                ApproximateRoutingViolations;
            pairs = warnings.ObjectA + " | " + warnings.ObjectB;

            testCase.verifyEqual( ...
                testCase.LayoutReport.LabelPathOverlapCount, uint32(0));
            testCase.verifyTrue(all( ...
                warnings.Category == ...
                "PathPathCrossingOrPartialOverlap"));
            testCase.verifyLessThanOrEqual( ...
                testCase.LayoutReport. ...
                ApproximateRoutingViolationCount, uint32(2));
            if ~isempty(warnings)
                testCase.verifyTrue(any(contains(pairs, "T54 ") & ...
                    contains(pairs, "T60 ")));
            end
        end

        function routingApiLimitationsAreReported(testCase)
            expectedMinimumCount = 3;

            actualLimitations = ...
                testCase.LayoutReport.RoutingLimitations;

            testCase.verifyGreaterThanOrEqual( ...
                numel(actualLimitations), expectedMinimumCount);
            testCase.verifyTrue(all(strlength(actualLimitations) > 0));
        end
    end
end

function closeIfOriginallyClosed(modelName, wasLoaded)
if ~wasLoaded && bdIsLoaded(modelName)
    close_system(modelName, 0);
end
end
