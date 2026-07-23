classdef AmrScenarioPlaybackApp < handle
    %AMRSCENARIOPLAYBACKAPP Select, simulate, and replay AMR fault scenarios.

    properties (SetAccess = private)
        Figure
        CurrentTime = 0
        IsPlaying = false
    end

    properties (Access = private)
        Data
        FloorMap
        PlaybackTimer
        LastTickReference
        PlaybackSpeed = 1

        MapAxes
        RobotBody
        LeftWheel
        RightWheel
        HeadingLine
        TrailLine
        LidarBeamLine
        DynamicObstacle
        EnvironmentDropDown
        ScenarioDropDown
        StatusLamp
        StatusLabel
        AlertLabel
        TimeValueLabel
        StateValueLabel
        XValueLabel
        YValueLabel
        HeadingValueLabel
        LinearVelocityValueLabel
        AngularVelocityValueLabel
        BatteryValueLabel
        BatteryGauge
        TimeSlider
        SpeedSlider
    end

    methods
        function app = AmrScenarioPlaybackApp(playbackData, floorMap)
            app.Data = playbackData;
            app.FloorMap = floorMap;
            app.CurrentTime = playbackData.time(1);
            app.createUserInterface();
            app.drawFloorMap();
            app.createPlaybackTimer();
            app.updateScenarioAppearance();
            app.renderCurrentFrame();
            app.play();
        end

        function play(app)
            if isempty(app.Figure) || ~isvalid(app.Figure)
                return;
            end
            if app.CurrentTime >= app.Data.time(end)
                app.reset();
            end
            app.IsPlaying = true;
            app.LastTickReference = tic;
            if strcmp(app.PlaybackTimer.Running, "off")
                start(app.PlaybackTimer);
            end
        end

        function pause(app)
            app.IsPlaying = false;
            if ~isempty(app.PlaybackTimer) && isvalid(app.PlaybackTimer) && ...
                    strcmp(app.PlaybackTimer.Running, "on")
                stop(app.PlaybackTimer);
            end
        end

        function reset(app)
            app.pause();
            app.CurrentTime = app.Data.time(1);
            app.renderCurrentFrame();
        end

        function seek(app, requestedTime)
            app.CurrentTime = min(max(requestedTime, app.Data.time(1)), ...
                app.Data.time(end));
            app.renderCurrentFrame();
        end

        function snapshot(app, filePath)
            drawnow;
            capturedFrame = getframe(app.Figure);
            imwrite(capturedFrame.cdata, filePath);
        end

        function loadScenario(app, scenario, environment)
            if nargin < 3
                environment = app.Data.environmentId;
            end
            if isnumeric(scenario)
                scenarioId = double(scenario);
            else
                scenarioNames = ["normal", "obstacle", "battery", "wrong_turn"];
                scenarioId = find(strcmpi(string(scenario), scenarioNames), 1);
            end
            assert(~isempty(scenarioId) && any(scenarioId == 1:4), ...
                "AMR:UnknownScenario", ...
                "Use normal, obstacle, battery, or wrong_turn.");
            app.ScenarioDropDown.Value = scenarioId;
            if isnumeric(environment)
                environmentId = double(environment);
            else
                environmentNames = ["office", "hospital", "warehouse"];
                environmentId = find(strcmpi(string(environment), ...
                    environmentNames), 1);
            end
            assert(~isempty(environmentId) && any(environmentId == 1:3), ...
                "AMR:UnknownEnvironment", ...
                "Use office, hospital, or warehouse.");
            app.EnvironmentDropDown.Value = environmentId;
            app.loadSelectedScenario();
        end
    end

    methods (Access = private)
        function createUserInterface(app)
            app.Figure = uifigure( ...
                "Name", "Indoor Delivery AMR - Scenario Lab", ...
                "Color", [0.96, 0.97, 0.98], ...
                "Position", [35, 45, 1420, 820]);
            app.Figure.CloseRequestFcn = @(~, ~) app.closeRequested();

            rootLayout = uigridlayout(app.Figure, [1, 2]);
            rootLayout.ColumnWidth = {"4x", 370};
            rootLayout.Padding = [12, 12, 12, 12];
            rootLayout.ColumnSpacing = 12;

            mapPanel = uipanel(rootLayout, ...
                "Title", "대형 실내 지도 / 로봇 주행", "FontWeight", "bold");
            mapLayout = uigridlayout(mapPanel, [1, 1]);
            mapLayout.Padding = [8, 8, 8, 8];
            app.MapAxes = uiaxes(mapLayout);

            controlPanel = uipanel(rootLayout, ...
                "Title", "Scenario & Mission Monitor", "FontWeight", "bold");
            controlLayout = uigridlayout(controlPanel, [23, 2]);
            controlLayout.ColumnWidth = {135, "1x"};
            controlLayout.RowHeight = {24, 40, 24, 40, 38, 8, 34, 46, ...
                28, 28, 28, 28, 28, 28, 28, 28, 48, 42, 22, 42, 22, 42, 45};
            controlLayout.Padding = [12, 10, 12, 10];

            environmentTitle = uilabel(controlLayout, ...
                "Text", "실내 환경", "FontWeight", "bold");
            environmentTitle.Layout.Row = 1;
            environmentTitle.Layout.Column = [1, 2];
            app.EnvironmentDropDown = uidropdown(controlLayout, ...
                "Items", ["사무실/배송 구역", "병원 중앙 복도", ...
                "물류 창고 랙 구역"], "ItemsData", [1, 2, 3], ...
                "Value", app.Data.environmentId);
            app.EnvironmentDropDown.Layout.Row = 2;
            app.EnvironmentDropDown.Layout.Column = [1, 2];

            scenarioTitle = uilabel(controlLayout, ...
                "Text", "실행할 상황", "FontWeight", "bold");
            scenarioTitle.Layout.Row = 3;
            scenarioTitle.Layout.Column = [1, 2];
            app.ScenarioDropDown = uidropdown(controlLayout, ...
                "Items", ["정상 배송", "돌발 장애물", "배터리 부족", "잘못된 길"], ...
                "ItemsData", [1, 2, 3, 4], ...
                "Value", app.Data.scenarioId);
            app.ScenarioDropDown.Layout.Row = 4;
            app.ScenarioDropDown.Layout.Column = [1, 2];
            runButton = uibutton(controlLayout, "push", ...
                "Text", "선택한 시나리오 계산 및 실행", ...
                "FontWeight", "bold", ...
                "ButtonPushedFcn", @(~, ~) app.loadSelectedScenario());
            runButton.Layout.Row = 5;
            runButton.Layout.Column = [1, 2];

            app.StatusLamp = uilamp(controlLayout, ...
                "Color", [0.30, 0.55, 0.95]);
            app.StatusLamp.Layout.Row = 7;
            app.StatusLamp.Layout.Column = 1;
            app.StatusLabel = uilabel(controlLayout, ...
                "Text", "초기화", "FontSize", 15, "FontWeight", "bold");
            app.StatusLabel.Layout.Row = 7;
            app.StatusLabel.Layout.Column = 2;
            app.AlertLabel = uilabel(controlLayout, ...
                "Text", "시스템 정상", "WordWrap", "on", ...
                "FontWeight", "bold", "HorizontalAlignment", "center", ...
                "BackgroundColor", [0.88, 0.94, 1.00]);
            app.AlertLabel.Layout.Row = 8;
            app.AlertLabel.Layout.Column = [1, 2];

            app.TimeValueLabel = app.addReadout(controlLayout, 9, ...
                "시뮬레이션 시간", "0.00 s");
            app.StateValueLabel = app.addReadout(controlLayout, 10, ...
                "Stateflow 상태", "초기화");
            app.XValueLabel = app.addReadout(controlLayout, 11, "x 위치", "0.00 m");
            app.YValueLabel = app.addReadout(controlLayout, 12, "y 위치", "0.00 m");
            app.HeadingValueLabel = app.addReadout(controlLayout, 13, ...
                "방향", "0.0 deg");
            app.LinearVelocityValueLabel = app.addReadout(controlLayout, 14, ...
                "선속도 v", "0.00 m/s");
            app.AngularVelocityValueLabel = app.addReadout(controlLayout, 15, ...
                "각속도 omega", "0.00 rad/s");
            app.BatteryValueLabel = app.addReadout(controlLayout, 16, ...
                "배터리", "100.0 %");
            app.BatteryGauge = uigauge(controlLayout, "linear", ...
                "Limits", [0, 100], "Value", 100, ...
                "MajorTicks", [0, 20, 40, 60, 80, 100]);
            app.BatteryGauge.Layout.Row = 17;
            app.BatteryGauge.Layout.Column = [1, 2];

            buttonLayout = uigridlayout(controlLayout, [1, 3]);
            buttonLayout.Layout.Row = 18;
            buttonLayout.Layout.Column = [1, 2];
            buttonLayout.ColumnWidth = {"1x", "1x", "1x"};
            buttonLayout.Padding = [0, 0, 0, 0];
            uibutton(buttonLayout, "push", "Text", "재생", ...
                "ButtonPushedFcn", @(~, ~) app.play());
            uibutton(buttonLayout, "push", "Text", "일시정지", ...
                "ButtonPushedFcn", @(~, ~) app.pause());
            uibutton(buttonLayout, "push", "Text", "처음으로", ...
                "ButtonPushedFcn", @(~, ~) app.reset());

            timeTitle = uilabel(controlLayout, "Text", "재생 위치");
            timeTitle.Layout.Row = 19;
            timeTitle.Layout.Column = [1, 2];
            app.TimeSlider = uislider(controlLayout, ...
                "Limits", [app.Data.time(1), app.Data.time(end)], ...
                "Value", app.Data.time(1), ...
                "MajorTicks", linspace(app.Data.time(1), app.Data.time(end), 6), ...
                "ValueChangingFcn", @(~, event) app.timeSliderChanging(event), ...
                "ValueChangedFcn", @(~, event) app.seek(event.Value));
            app.TimeSlider.Layout.Row = 20;
            app.TimeSlider.Layout.Column = [1, 2];

            speedTitle = uilabel(controlLayout, "Text", "재생 속도");
            speedTitle.Layout.Row = 21;
            speedTitle.Layout.Column = [1, 2];
            app.SpeedSlider = uislider(controlLayout, ...
                "Limits", [0.25, 4.0], "Value", 1.0, ...
                "MajorTicks", [0.25, 1, 2, 3, 4], ...
                "MajorTickLabels", ["0.25x", "1x", "2x", "3x", "4x"], ...
                "ValueChangedFcn", @(~, event) app.speedChanged(event));
            app.SpeedSlider.Layout.Row = 22;
            app.SpeedSlider.Layout.Column = [1, 2];

            tipLabel = uilabel(controlLayout, ...
                "Text", "드롭다운에서 상황을 고른 뒤 실행 버튼을 누르세요. 새 Simulink 계산 후 자동 재생됩니다.", ...
                "WordWrap", "on", "FontColor", [0.30, 0.33, 0.38]);
            tipLabel.Layout.Row = 23;
            tipLabel.Layout.Column = [1, 2];
        end

        function valueLabel = addReadout(~, parent, row, titleText, valueText)
            titleLabel = uilabel(parent, "Text", titleText, ...
                "FontColor", [0.35, 0.38, 0.42]);
            titleLabel.Layout.Row = row;
            titleLabel.Layout.Column = 1;
            valueLabel = uilabel(parent, "Text", valueText, ...
                "FontWeight", "bold", "HorizontalAlignment", "right");
            valueLabel.Layout.Row = row;
            valueLabel.Layout.Column = 2;
        end

        function drawFloorMap(app)
            axesHandle = app.MapAxes;
            hold(axesHandle, "on");
            axesHandle.Color = [0.93, 0.94, 0.95];
            axesHandle.XLim = app.FloorMap.bounds(1:2);
            axesHandle.YLim = app.FloorMap.bounds(3:4);
            axesHandle.DataAspectRatio = [1, 1, 1];
            axesHandle.XGrid = "on";
            axesHandle.YGrid = "on";
            axesHandle.GridAlpha = 0.12;
            xlabel(axesHandle, "world x (m)");
            ylabel(axesHandle, "world y (m)");
            title(axesHandle, app.FloorMap.displayName + ...
                " / LiDAR-driven Stateflow scenarios");

            for index = 1:size(app.FloorMap.walls, 1)
                rectangle(axesHandle, "Position", app.FloorMap.walls(index, :), ...
                    "FaceColor", [0.20, 0.23, 0.27], ...
                    "EdgeColor", [0.12, 0.14, 0.16]);
            end
            for index = 1:size(app.FloorMap.obstacles, 1)
                rectangle(axesHandle, ...
                    "Position", app.FloorMap.obstacles(index, :), ...
                    "FaceColor", [0.72, 0.48, 0.23], ...
                    "EdgeColor", [0.42, 0.27, 0.11]);
            end
            for index = 1:numel(app.FloorMap.labels)
                position = app.FloorMap.labels(index).position;
                text(axesHandle, position(1), position(2), ...
                    app.FloorMap.labels(index).text, ...
                    "Color", [0.28, 0.30, 0.34], ...
                    "FontWeight", "bold", "HorizontalAlignment", "center");
            end

            plot(axesHandle, app.FloorMap.referenceRoute(:, 1), ...
                app.FloorMap.referenceRoute(:, 2), "--", ...
                "Color", [0.55, 0.60, 0.66], "LineWidth", 1.2);
            plot(axesHandle, app.FloorMap.startPose(1), ...
                app.FloorMap.startPose(2), "o", "MarkerSize", 10, ...
                "MarkerFaceColor", [0.20, 0.75, 0.30], ...
                "MarkerEdgeColor", "white", "LineWidth", 1.5);
            plot(axesHandle, app.FloorMap.goalPose(1), ...
                app.FloorMap.goalPose(2), "p", "MarkerSize", 15, ...
                "MarkerFaceColor", [0.90, 0.25, 0.20], ...
                "MarkerEdgeColor", "white", "LineWidth", 1.5);
            plot(axesHandle, app.FloorMap.chargerPose(1), ...
                app.FloorMap.chargerPose(2), "s", "MarkerSize", 13, ...
                "MarkerFaceColor", [0.20, 0.75, 0.85], ...
                "MarkerEdgeColor", "white", "LineWidth", 1.5);

            app.DynamicObstacle = rectangle(axesHandle, ...
                "Position", app.FloorMap.dynamicObstacle, ...
                "FaceColor", [0.92, 0.18, 0.16], ...
                "EdgeColor", [0.55, 0.05, 0.04], ...
                "LineWidth", 2, "Visible", "off");
            app.LidarBeamLine = plot(axesHandle, nan, nan, ...
                "Color", [0.20, 0.78, 0.88], "LineWidth", 0.6);
            app.TrailLine = plot(axesHandle, nan, nan, ...
                "Color", [0.10, 0.55, 0.95], "LineWidth", 2.8);
            app.RobotBody = patch(axesHandle, nan, nan, [0.10, 0.55, 0.95], ...
                "EdgeColor", "white", "LineWidth", 1.5);
            app.LeftWheel = patch(axesHandle, nan, nan, [0.08, 0.09, 0.11], ...
                "EdgeColor", "none");
            app.RightWheel = patch(axesHandle, nan, nan, [0.08, 0.09, 0.11], ...
                "EdgeColor", "none");
            app.HeadingLine = plot(axesHandle, nan, nan, ...
                "Color", [0.95, 0.85, 0.20], "LineWidth", 3);
        end

        function createPlaybackTimer(app)
            app.PlaybackTimer = timer( ...
                "ExecutionMode", "fixedSpacing", "Period", 0.033, ...
                "BusyMode", "drop", ...
                "TimerFcn", @(~, ~) app.advanceFrame(), ...
                "ErrorFcn", @(~, event) app.timerFailed(event));
        end

        function advanceFrame(app)
            if ~app.IsPlaying || isempty(app.Figure) || ~isvalid(app.Figure)
                return;
            end
            elapsedTime = toc(app.LastTickReference);
            app.LastTickReference = tic;
            app.CurrentTime = min(app.CurrentTime + ...
                elapsedTime * app.PlaybackSpeed, app.Data.time(end));
            app.renderCurrentFrame();
            if app.CurrentTime >= app.Data.time(end)
                app.pause();
            end
        end

        function renderCurrentFrame(app)
            time = app.Data.time;
            index = find(time <= app.CurrentTime, 1, "last");
            if isempty(index)
                index = 1;
            end

            x = interp1(time, app.Data.x, app.CurrentTime, "linear");
            y = interp1(time, app.Data.y, app.CurrentTime, "linear");
            heading = interp1(time, app.Data.heading, app.CurrentTime, "linear");
            linearVelocity = interp1(time, app.Data.linearVelocity, ...
                app.CurrentTime, "previous");
            angularVelocity = interp1(time, app.Data.angularVelocity, ...
                app.CurrentTime, "previous");
            battery = interp1(time, app.Data.battery, app.CurrentTime, "linear");
            missionMode = double(app.Data.stateId(index));
            eventCode = double(app.Data.eventCode(index));

            bodyLocal = [0.24, 0.17; 0.24, -0.17; -0.24, -0.17; -0.24, 0.17];
            leftWheelLocal = [0.16, 0.21; -0.16, 0.21; -0.16, 0.16; 0.16, 0.16];
            rightWheelLocal = [0.16, -0.16; -0.16, -0.16; -0.16, -0.21; 0.16, -0.21];
            bodyWorld = app.transformPolygon(bodyLocal, x, y, heading);
            leftWheelWorld = app.transformPolygon(leftWheelLocal, x, y, heading);
            rightWheelWorld = app.transformPolygon(rightWheelLocal, x, y, heading);

            set(app.RobotBody, "XData", bodyWorld(:, 1), "YData", bodyWorld(:, 2));
            set(app.LeftWheel, "XData", leftWheelWorld(:, 1), ...
                "YData", leftWheelWorld(:, 2));
            set(app.RightWheel, "XData", rightWheelWorld(:, 1), ...
                "YData", rightWheelWorld(:, 2));
            set(app.HeadingLine, ...
                "XData", [x, x + 0.38 * cos(heading)], ...
                "YData", [y, y + 0.38 * sin(heading)]);
            set(app.TrailLine, "XData", app.Data.x(1:index), ...
                "YData", app.Data.y(1:index));
            app.updateLidarDisplay(index, x, y, heading);
            if app.Data.dynamicObstacleActive(index)
                app.DynamicObstacle.Visible = "on";
            else
                app.DynamicObstacle.Visible = "off";
            end

            stateIndex = min(missionMode + 1, numel(app.Data.stateNames));
            app.TimeSlider.Value = app.CurrentTime;
            app.TimeValueLabel.Text = sprintf("%.2f / %.2f s", ...
                app.CurrentTime, time(end));
            app.StateValueLabel.Text = app.Data.stateNames(stateIndex);
            app.XValueLabel.Text = sprintf("%.3f m", x);
            app.YValueLabel.Text = sprintf("%.3f m", y);
            app.HeadingValueLabel.Text = sprintf("%.1f deg", rad2deg(heading));
            app.LinearVelocityValueLabel.Text = sprintf("%.3f m/s", linearVelocity);
            app.AngularVelocityValueLabel.Text = sprintf("%.3f rad/s", angularVelocity);
            app.BatteryValueLabel.Text = sprintf("%.1f %%", battery);
            app.BatteryGauge.Value = battery;
            app.updateMissionMessage(missionMode, eventCode);
            drawnow limitrate;
        end

        function updateMissionMessage(app, missionMode, eventCode)
            switch missionMode
                case 0
                    app.setMessage("초기화", "센서와 제어기 초기화", [0.30, 0.55, 0.95]);
                case 1
                    if eventCode == 3
                        app.setMessage("배송 중", "잘못된 방향으로 진입 중", [0.95, 0.55, 0.12]);
                    elseif eventCode == 2
                        app.setMessage("배송 중", "배터리 임계값 도달", [0.95, 0.55, 0.12]);
                    elseif eventCode == 1
                        app.setMessage("배송 중", "전방 돌발 장애물 감지", [0.90, 0.20, 0.16]);
                    elseif eventCode == 6
                        app.setMessage("LiDAR 감속", "전방 slowdown zone 진입", [0.95, 0.70, 0.12]);
                    else
                        app.setMessage("배송 중", "경로 추종 정상", [0.20, 0.75, 0.30]);
                    end
                case 2
                    app.setMessage("비상 정지", "장애물 앞 정지 및 안전 확인", [0.90, 0.20, 0.16]);
                case 3
                    app.setMessage("장애물 우회", "우회 waypoint 추종", [0.95, 0.55, 0.12]);
                case 4
                    app.setMessage("충전소 복귀", "저전압 보호 경로 실행", [0.95, 0.55, 0.12]);
                case 5
                    app.setMessage("충전 중", "90%까지 충전 후 임무 재개", [0.20, 0.70, 0.85]);
                case 6
                    app.setMessage("경로이탈 정지", "현재 위치 확인", [0.90, 0.20, 0.16]);
                case 7
                    app.setMessage("재경로", "기준 경로로 복귀 중", [0.95, 0.55, 0.12]);
                otherwise
                    app.setMessage("배송 완료", "목표 지점 도착", [0.20, 0.75, 0.30]);
            end
        end

        function setMessage(app, statusText, alertText, color)
            app.StatusLabel.Text = statusText;
            app.AlertLabel.Text = alertText;
            app.StatusLamp.Color = color;
            app.AlertLabel.BackgroundColor = 0.80 * [1, 1, 1] + 0.20 * color;
        end

        function loadSelectedScenario(app)
            app.pause();
            app.setMessage("계산 중", "Simulink 시나리오를 실행하고 있습니다...", ...
                [0.30, 0.55, 0.95]);
            drawnow;
            try
                environmentId = app.EnvironmentDropDown.Value;
                app.Data = simulate_amr_scenario( ...
                    app.ScenarioDropDown.Value, environmentId);
                app.FloorMap = amr.ui.createEnvironmentFloorMap(environmentId);
                cla(app.MapAxes);
                app.drawFloorMap();
                app.CurrentTime = app.Data.time(1);
                app.TimeSlider.Limits = [app.Data.time(1), app.Data.time(end)];
                app.TimeSlider.MajorTicks = linspace(app.Data.time(1), ...
                    app.Data.time(end), 6);
                app.updateScenarioAppearance();
                app.renderCurrentFrame();
                app.play();
            catch exception
                app.setMessage("실행 실패", exception.message, [0.90, 0.20, 0.16]);
                uialert(app.Figure, exception.message, "시나리오 실행 오류");
            end
        end

        function updateScenarioAppearance(app)
            app.DynamicObstacle.Visible = "off";
            app.Figure.Name = "Indoor Delivery AMR - " + ...
                app.Data.environmentName + " / " + app.Data.scenarioName;
            app.ScenarioDropDown.Value = app.Data.scenarioId;
            app.EnvironmentDropDown.Value = app.Data.environmentId;
        end

        function updateLidarDisplay(app, index, x, y, heading)
            config = app.Data.lidarConfig;
            rotation = [cos(heading), -sin(heading); ...
                sin(heading), cos(heading)];
            sensorOrigin = [x, y] + config.mountingOffset * rotation.';
            ranges = app.Data.lidarRanges(index, :).';
            angles = heading + app.Data.lidarAngles(:);
            selected = (1:2:numel(ranges)).';
            selected = selected(ranges(selected) < config.maximumRange);
            if isempty(selected)
                set(app.LidarBeamLine, "XData", nan, "YData", nan);
                return;
            end
            visibleRanges = min(ranges(selected), 3.0);
            endX = sensorOrigin(1) + visibleRanges .* cos(angles(selected));
            endY = sensorOrigin(2) + visibleRanges .* sin(angles(selected));
            beamCount = numel(selected);
            xTriplets = [repmat(sensorOrigin(1), beamCount, 1), ...
                endX, nan(beamCount, 1)].';
            yTriplets = [repmat(sensorOrigin(2), beamCount, 1), ...
                endY, nan(beamCount, 1)].';
            set(app.LidarBeamLine, "XData", xTriplets(:), ...
                "YData", yTriplets(:));
        end

        function timeSliderChanging(app, event)
            app.pause();
            app.seek(event.Value);
        end

        function speedChanged(app, event)
            app.PlaybackSpeed = event.Value;
            if app.IsPlaying
                app.LastTickReference = tic;
            end
        end

        function timerFailed(app, event)
            app.pause();
            warning("AMR:ScenarioPlaybackTimer", ...
                "Scenario playback timer failed: %s", event.Data.Message);
        end

        function closeRequested(app)
            app.IsPlaying = false;
            if ~isempty(app.PlaybackTimer) && isvalid(app.PlaybackTimer)
                if strcmp(app.PlaybackTimer.Running, "on")
                    stop(app.PlaybackTimer);
                end
                delete(app.PlaybackTimer);
            end
            figureHandle = app.Figure;
            app.Figure = [];
            figureHandle.CloseRequestFcn = [];
            delete(figureHandle);
        end
    end

    methods (Static, Access = private)
        function worldPolygon = transformPolygon(localPolygon, x, y, heading)
            rotation = [cos(heading), -sin(heading); ...
                sin(heading), cos(heading)];
            worldPolygon = localPolygon * rotation.' + [x, y];
        end
    end
end
