classdef AmrMapPlaybackApp < handle
    %AMRMAPPLAYBACKAPP Interactive playback UI for an indoor AMR run.

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
        StatusLamp
        StatusLabel
        TimeValueLabel
        StateValueLabel
        XValueLabel
        YValueLabel
        HeadingValueLabel
        LinearVelocityValueLabel
        AngularVelocityValueLabel
        TimeSlider
        SpeedSlider
    end

    properties (Constant, Access = private)
        StateNames = ["초기화", "첫 번째 직진", "좌회전", "두 번째 직진", "정지"]
    end

    methods
        function app = AmrMapPlaybackApp(playbackData, floorMap)
            app.validatePlaybackData(playbackData);
            app.Data = playbackData;
            app.FloorMap = floorMap;
            app.CurrentTime = playbackData.time(1);

            app.createUserInterface();
            app.drawFloorMap();
            app.createPlaybackTimer();
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
            app.StatusLamp.Color = [0.20, 0.75, 0.30];
            app.StatusLabel.Text = "재생 중";
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
            if ~isempty(app.Figure) && isvalid(app.Figure)
                app.StatusLamp.Color = [0.95, 0.65, 0.10];
                app.StatusLabel.Text = "일시 정지";
            end
        end

        function reset(app)
            app.pause();
            app.CurrentTime = app.Data.time(1);
            app.renderCurrentFrame();
            app.StatusLamp.Color = [0.30, 0.55, 0.95];
            app.StatusLabel.Text = "시작 위치";
        end

        function seek(app, requestedTime)
            app.CurrentTime = min(max(requestedTime, app.Data.time(1)), ...
                app.Data.time(end));
            app.renderCurrentFrame();
        end

        function snapshot(app, filePath)
            drawnow;
            exportapp(app.Figure, filePath);
        end
    end

    methods (Access = private)
        function createUserInterface(app)
            app.Figure = uifigure( ...
                "Name", "Indoor Delivery AMR - Map Playback", ...
                "Color", [0.96, 0.97, 0.98], ...
                "Position", [80, 80, 1280, 760]);
            app.Figure.CloseRequestFcn = @(~, ~) app.closeRequested();

            rootLayout = uigridlayout(app.Figure, [1, 2]);
            rootLayout.ColumnWidth = {"3x", 330};
            rootLayout.Padding = [12, 12, 12, 12];
            rootLayout.ColumnSpacing = 12;

            mapPanel = uipanel(rootLayout, ...
                "Title", "실내 지도와 로봇 위치", ...
                "FontWeight", "bold");
            app.MapAxes = uiaxes(mapPanel, "Position", [15, 15, 890, 685]);

            controlPanel = uipanel(rootLayout, ...
                "Title", "Mission Monitor", ...
                "FontWeight", "bold");
            controlLayout = uigridlayout(controlPanel, [16, 2]);
            controlLayout.ColumnWidth = {125, "1x"};
            controlLayout.RowHeight = {36, 30, 30, 30, 30, 30, 30, 30, ...
                12, 42, 24, 42, 24, 42, "1x", 48};
            controlLayout.Padding = [12, 12, 12, 12];

            app.StatusLamp = uilamp(controlLayout, ...
                "Color", [0.30, 0.55, 0.95]);
            app.StatusLamp.Layout.Row = 1;
            app.StatusLamp.Layout.Column = 1;
            app.StatusLabel = uilabel(controlLayout, ...
                "Text", "준비", "FontSize", 16, "FontWeight", "bold");
            app.StatusLabel.Layout.Row = 1;
            app.StatusLabel.Layout.Column = 2;

            app.TimeValueLabel = app.addReadout(controlLayout, 2, ...
                "시뮬레이션 시간", "0.00 s");
            app.StateValueLabel = app.addReadout(controlLayout, 3, ...
                "Stateflow 상태", "초기화");
            app.XValueLabel = app.addReadout(controlLayout, 4, "x 위치", "0.00 m");
            app.YValueLabel = app.addReadout(controlLayout, 5, "y 위치", "0.00 m");
            app.HeadingValueLabel = app.addReadout(controlLayout, 6, ...
                "방향", "0.0 deg");
            app.LinearVelocityValueLabel = app.addReadout(controlLayout, 7, ...
                "선속도 v", "0.00 m/s");
            app.AngularVelocityValueLabel = app.addReadout(controlLayout, 8, ...
                "각속도 omega", "0.00 rad/s");

            buttonLayout = uigridlayout(controlLayout, [1, 3]);
            buttonLayout.Layout.Row = 10;
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
            timeTitle.Layout.Row = 11;
            timeTitle.Layout.Column = [1, 2];
            app.TimeSlider = uislider(controlLayout, ...
                "Limits", [app.Data.time(1), app.Data.time(end)], ...
                "Value", app.Data.time(1), ...
                "MajorTicks", 0:2:app.Data.time(end), ...
                "ValueChangingFcn", @(~, event) app.timeSliderChanging(event), ...
                "ValueChangedFcn", @(~, event) app.timeSliderChanged(event));
            app.TimeSlider.Layout.Row = 12;
            app.TimeSlider.Layout.Column = [1, 2];

            speedTitle = uilabel(controlLayout, "Text", "재생 속도");
            speedTitle.Layout.Row = 13;
            speedTitle.Layout.Column = [1, 2];
            app.SpeedSlider = uislider(controlLayout, ...
                "Limits", [0.25, 4.0], ...
                "Value", 1.0, ...
                "MajorTicks", [0.25, 1, 2, 3, 4], ...
                "MajorTickLabels", ["0.25x", "1x", "2x", "3x", "4x"], ...
                "ValueChangedFcn", @(~, event) app.speedChanged(event));
            app.SpeedSlider.Layout.Row = 14;
            app.SpeedSlider.Layout.Column = [1, 2];

            tipLabel = uilabel(controlLayout, ...
                "Text", "Simulink 로그를 재생합니다. 슬라이더로 원하는 시간의 자세를 확인할 수 있습니다.", ...
                "WordWrap", "on", "FontColor", [0.30, 0.33, 0.38]);
            tipLabel.Layout.Row = 16;
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
            title(axesHandle, "Stateflow-supervised differential-drive robot");

            for index = 1:size(app.FloorMap.walls, 1)
                rectangle(axesHandle, ...
                    "Position", app.FloorMap.walls(index, :), ...
                    "FaceColor", [0.20, 0.23, 0.27], ...
                    "EdgeColor", [0.12, 0.14, 0.16]);
            end
            for index = 1:size(app.FloorMap.obstacles, 1)
                rectangle(axesHandle, ...
                    "Position", app.FloorMap.obstacles(index, :), ...
                    "FaceColor", [0.78, 0.53, 0.25], ...
                    "EdgeColor", [0.45, 0.30, 0.12], ...
                    "Curvature", 0.05);
            end
            for index = 1:numel(app.FloorMap.labels)
                position = app.FloorMap.labels(index).position;
                text(axesHandle, position(1), position(2), ...
                    app.FloorMap.labels(index).text, ...
                    "Color", [0.28, 0.30, 0.34], ...
                    "FontWeight", "bold", ...
                    "HorizontalAlignment", "center");
            end

            plot(axesHandle, app.FloorMap.startPose(1), ...
                app.FloorMap.startPose(2), "o", ...
                "MarkerSize", 10, "MarkerFaceColor", [0.20, 0.75, 0.30], ...
                "MarkerEdgeColor", "white", "LineWidth", 1.5);
            plot(axesHandle, app.FloorMap.goalPose(1), ...
                app.FloorMap.goalPose(2), "p", ...
                "MarkerSize", 15, "MarkerFaceColor", [0.90, 0.25, 0.20], ...
                "MarkerEdgeColor", "white", "LineWidth", 1.5);

            app.TrailLine = plot(axesHandle, nan, nan, ...
                "Color", [0.10, 0.55, 0.95], "LineWidth", 2.5);
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
                "ExecutionMode", "fixedSpacing", ...
                "Period", 0.033, ...
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
                app.StatusLamp.Color = [0.25, 0.70, 0.85];
                app.StatusLabel.Text = "임무 완료";
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
            stateIndex = min(double(app.Data.stateId(index)) + 1, ...
                numel(app.StateNames));

            bodyLocal = [0.20, 0.14; 0.20, -0.14; -0.20, -0.14; -0.20, 0.14];
            leftWheelLocal = [0.13, 0.18; -0.13, 0.18; -0.13, 0.13; 0.13, 0.13];
            rightWheelLocal = [0.13, -0.13; -0.13, -0.13; -0.13, -0.18; 0.13, -0.18];
            bodyWorld = app.transformPolygon(bodyLocal, x, y, heading);
            leftWheelWorld = app.transformPolygon(leftWheelLocal, x, y, heading);
            rightWheelWorld = app.transformPolygon(rightWheelLocal, x, y, heading);

            set(app.RobotBody, "XData", bodyWorld(:, 1), "YData", bodyWorld(:, 2));
            set(app.LeftWheel, "XData", leftWheelWorld(:, 1), ...
                "YData", leftWheelWorld(:, 2));
            set(app.RightWheel, "XData", rightWheelWorld(:, 1), ...
                "YData", rightWheelWorld(:, 2));
            set(app.HeadingLine, ...
                "XData", [x, x + 0.32 * cos(heading)], ...
                "YData", [y, y + 0.32 * sin(heading)]);
            set(app.TrailLine, "XData", app.Data.x(1:index), ...
                "YData", app.Data.y(1:index));

            app.TimeSlider.Value = app.CurrentTime;
            app.TimeValueLabel.Text = sprintf("%.2f / %.2f s", ...
                app.CurrentTime, time(end));
            app.StateValueLabel.Text = app.StateNames(stateIndex);
            app.XValueLabel.Text = sprintf("%.3f m", x);
            app.YValueLabel.Text = sprintf("%.3f m", y);
            app.HeadingValueLabel.Text = sprintf("%.1f deg", rad2deg(heading));
            app.LinearVelocityValueLabel.Text = sprintf("%.3f m/s", linearVelocity);
            app.AngularVelocityValueLabel.Text = sprintf("%.3f rad/s", angularVelocity);
            drawnow limitrate;
        end

        function timeSliderChanging(app, event)
            app.pause();
            app.seek(event.Value);
        end

        function timeSliderChanged(app, event)
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
            warning("AMR:PlaybackTimer", "Playback timer failed: %s", ...
                event.Data.Message);
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
        function validatePlaybackData(playbackData)
            requiredFields = ["time", "x", "y", "heading", "stateId", ...
                "linearVelocity", "angularVelocity"];
            assert(all(isfield(playbackData, requiredFields)), ...
                "AMR:InvalidPlaybackData", ...
                "Playback data is missing one or more required fields.");
            assert(numel(playbackData.time) >= 2, ...
                "AMR:InvalidPlaybackTime", ...
                "Playback data must contain at least two samples.");
        end

        function worldPolygon = transformPolygon(localPolygon, x, y, heading)
            rotation = [cos(heading), -sin(heading); ...
                sin(heading), cos(heading)];
            worldPolygon = localPolygon * rotation.' + [x, y];
        end
    end
end
