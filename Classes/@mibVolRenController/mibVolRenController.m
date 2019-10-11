classdef mibVolRenController < handle
    % @type mibVolRenController class is resposnible for 3D rendering
    % of volumes or models
    
    % Copyright (C) 26.09.2018, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    %
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    %
    % Updates
    %
    
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        childControllers
        % list of opened subcontrollers
        childControllersIds
        % a cell array with names of initialized child controllers
        defaultView
        % a structure with the default camera position
        alphaPlotHandle
        % handle to the alpha plot
        animationFilename
        % template for the animation filename
        animationPath
        % a structure with animation path
        % .CameraPosition - a matrix of camera positions [keyFrame, x,y,z]
        % .CameraUpVector - a matrix of camera up vectors [keyFrame, x,y,z]
        % .CameraTarget - a matrix of camera target positions [keyFrame, x,y,z]
        colorChannel
        % index of the color channel or material to show
        dataType
        % a string with data type that is visualized, 'image', 'model','selection', 'mask'
        figPosStored
        %  a structure with stored positions of the widgets for making snapshots
        %   .mibVolRenGUI = [];
        %   .volViewPanel = [];
        %   .optionsPanel = [];
        maxIntValue
        % max integer value of the dataset
        renderingMode
        % a string with the rendering mode to use, 'VolumeRendering', 'MaximumIntensityProjection','Isosurface'
        Settings
        % a structure with settings
        % .MarkerSize -  marker size for the alpha plot
        % .IsoColor -  color for the isosurface
        % .BackgroundColor - color for the background
        % .ColormapName - a string with default colormap, or 'custom' (not yet implemented)
        % .ColormapInvert - true/false, invert or not the colormap
        % .animationPath - a structure with animation path
        % .noFramesPreview - number of frames for the preview
        
        volume
        % loaded volume
        volumeAlphaCurve
        % a structure with alpha curve details
        % .x - vector of intensity points [0 - 1]
        % .y - value of alpha for each intensity point [0 - 1]
        % .alphamap - calculated alpha map used in volshow
        % .activePoint -  selected point
        volumeColormap
        % vector with the colormap
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case {'updateGuiWidgets'}
                    obj.updateWidgets();
            end
        end
        
        %         function purgeControllers(obj, src, evnt)
        %             % find index of the child controller
        %             id = obj.findChildId(class(src));
        %
        %             % delete the child controller
        %             delete(obj.childControllers{id});
        %
        %             % clear the handle
        %             obj.childControllers(id) = [];
        %             obj.childControllersIds(id) = [];
        %         end
    end
    
    methods
        function obj = mibVolRenController(mibModel, options)
            % function obj = mibVolRenController(mibModel, parameter)
            % class constructor
            %
            % Parameters:
            % mibModel: a handle to mibModel class
            % options: a structure with optional initialization parameters
            %   .mode - a string 'VolumeRendering', 'MaximumIntensityProjection','Isosurface'
            %   .dataType - a string with data type to display 'image', 'model', 'selection', 'mask'
            %   .materialIndex - an index of material to visualize
            %   .Settings - settings for initialization of the volviewer
            
            if nargin < 2; options = struct(); end
            if ~isfield(options, 'mode'); options.mode = 'VolumeRendering'; end
            if ~isfield(options, 'dataType'); options.dataType = 'image'; end  % other types: 'model','selection','mask'
            if ~isfield(options, 'colorChannel'); options.colorChannel = 1; end   % index of the color channel or material to show; end
            if ~isfield(options, 'Settings')
                options.Settings.ColormapName = 'gray';
                options.Settings.ColormapInvert = true;
                options.Settings.MarkerSize = 15;
                options.Settings.IsoColor = [1 0 0];        %  color for the isosurface
                options.Settings.BackgroundColor = [0.3 0.75 0.93]; % color for the background
                options.Settings.volumeAlphaCurve.x = [0 .3 .7 1];
                options.Settings.volumeAlphaCurve.y = [1 1 0 0];
                options.Settings.animationPath = struct();
                options.Settings.noFramesPreview = 120;     % number of frames for the animation preview mode
            else
                if ~isfield(options.Settings, 'ColormapName'); options.Settings.ColormapName = 'gray'; end
                if ~isfield(options.Settings, 'ColormapInvert'); options.Settings.ColormapInvert = true; end
                if ~isfield(options.Settings, 'MarkerSize'); options.Settings.MarkerSize = 15; end
                if ~isfield(options.Settings, 'IsoColor'); options.Settings.IsoColor = [1 0 0]; end
                if ~isfield(options.Settings, 'BackgroundColor'); options.Settings.BackgroundColor = [0.3 0.75 0.93]; end
                if ~isfield(options.Settings, 'volumeAlphaCurve'); options.Settings.volumeAlphaCurve.x = [0 .3 .7 1]; options.Settings.volumeAlphaCurve.y = [1 1 0 0]; end
                if ~isfield(options.Settings, 'animationPath'); options.Settings.animationPath = struct(); end
                if ~isfield(options.Settings, 'noFramesPreview'); options.Settings.noFramesPreview = 120; end
            end
            obj.renderingMode = options.mode;
            obj.dataType = options.dataType;
            obj.colorChannel = options.colorChannel;
            obj.animationPath = options.Settings.animationPath;
            
            obj.Settings = options.Settings;
            obj.volumeAlphaCurve.x = options.Settings.volumeAlphaCurve.x;
            obj.volumeAlphaCurve.y = options.Settings.volumeAlphaCurve.y;
            
%             % TESTS!!!
%             obj.colorChannel = NaN;
%             obj.renderingMode = 'VolumeRendering'
%             obj.volumeAlphaCurve.x = [0, 1/254, 1]; 
%             obj.volumeAlphaCurve.y = [0, 1, 1];
%             obj.Settings.ColormapName = 'custom';
%             obj.volumeColormap = zeros([256, 3]);
%             obj.volumeColormap(1:size( mibModel.I{mibModel.Id}.modelMaterialColors,1), :) = mibModel.I{mibModel.Id}.modelMaterialColors;
% %             for i=1:3
% %                 obj.volumeColormap(i*50:i*50+49,:) = repmat(mibModel.I{mibModel.Id}.modelMaterialColors(i,:), [50,1]);
% %             end
%             obj.Settings.ColormapInvert = 0;
            
            obj.childControllers = {};    % initialize child controllers
            obj.childControllersIds = {};
            
            obj.figPosStored.mibVolRenGUI = [];
            obj.figPosStored.volViewPanel = [];
            obj.figPosStored.optionsPanel = [];
            
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibVolRenGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            [pathstr, name] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            fn_out = fullfile(pathstr, [name '.animation']);
            if isempty(strfind(fn_out, '/')) && isempty(strfind(fn_out, '\')) %#ok<STREMP>
                fn_out = fullfile(obj.mibModel.myPath, fn_out);
            end
            if isempty(fn_out); fn_out = obj.mibModel.myPath; end
            obj.animationFilename = fn_out;
            
            % check for the virtual stacking mode and close the controller
            if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                toolname = 'volume rendering';
                warndlg(sprintf('!!! Warning !!!\n\nThe %s not available in the virtual stacking mode\nplease switch to the memory-resident mode and try again', ...
                    toolname), 'Not implemented');
                obj.closeWindow();
                return;
            end
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            Font = obj.mibModel.preferences.Font;
            if obj.View.handles.modeText.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.modeText.FontName, Font.FontName)
                mibUpdateFontSize(obj.View.gui, Font);
            end
            
            obj.volume = [];
            obj.maxIntValue = 255;
            obj.volumeAlphaCurve.activePoint = [];
            obj.alphaPlotHandle = [];
            status = obj.grabVolume();
            if status == 0; return; end     % action cancelled from grabVolume
            
            obj.generateColorMap();     % generate colormap vector from the selected colormap
            obj.updateWidgets();
            
            % add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing mibVolRenController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete childController window
            end
            
            % delete listeners, otherwise they stay after deleting of the
            % controller
            for i=1:numel(obj.listener)
                delete(obj.listener{i});
            end
            
            % close child controllers
            for i=numel(obj.childControllers):-1:1
                if isvalid(obj.childControllers{i})
                    obj.childControllers{i}.closeWindow();
                end
            end
            obj.Settings.volumeAlphaCurve = obj.volumeAlphaCurve;
            obj.Settings.animationPath = obj.animationPath;
            obj.mibModel.sessionSettings.VolumeRendering = obj.Settings;
            notify(obj, 'closeEvent');      % notify mibController that this child window is closed
        end
        
        function updateWidgets(obj)
            % function updateWidgets(obj)
            % update widgets of this window
            if obj.View.handles.isovalSlider.Value > obj.maxIntValue
                obj.View.handles.isovalSlider.Value = obj.maxIntValue;
            end
            obj.View.handles.isovalSlider.Max = obj.maxIntValue;
            obj.plotAlphaPlot();
            
            % update child controllers
            for i=1:numel(obj.childControllers)
                obj.childControllers{i}.updateWidgets()
            end
            
            % update current camera status
            obj.View.handles.statusText.String = sprintf('Position: %.3f x %.3f x %.3f --- CameraUpVector: %.3f x %.3f x %.3f --- CameraTarget: %.3f x %.3f x %.3f', ...
                obj.volume.CameraPosition(1), obj.volume.CameraPosition(2), obj.volume.CameraPosition(3), ...
                obj.volume.CameraUpVector(1), obj.volume.CameraUpVector(2), obj.volume.CameraUpVector(3), ...
                obj.volume.CameraTarget(1), obj.volume.CameraTarget(2), obj.volume.CameraTarget(3));
        end
        
        function mibVolRenGUI_SizeChangedFcn(obj)
            % function mibVolRenGUI_SizeChangedFcn(obj)
            % figure resizing
            if isempty(obj.View); return; end
            
            mainFigPos = obj.View.handles.mibVolRenGUI.Position;
            optPanPos = obj.View.handles.optionsPanel.Position;
            volViewPos = obj.View.handles.volViewPanel.Position;
            
            obj.View.handles.volViewPanel.Position(3) = mainFigPos(3);    % width
            obj.View.handles.volViewPanel.Position(2) = optPanPos(2)+optPanPos(4)+5;    % y1
            obj.View.handles.volViewPanel.Position(4) = mainFigPos(4) - volViewPos(2); % height
            obj.View.handles.optionsPanel.Position(3) = mainFigPos(3)-10;
            
            %if ismember(obj.childControllersIds, 'mibSnapshotController')
            %    obj.childControllers{1}.updateWidthHeight();
            %end
            
        end
        
        function visualizationModePopup_Callback(obj)
            % function visualizationModePopup_Callback(obj)
            % callback for change of the visualization mode
            
            popupText = obj.View.handles.visualizationModePopup.String;
            popupValue = obj.View.handles.visualizationModePopup.Value;
            obj.View.handles.volRenPanel.Visible = 'off';
            obj.View.handles.isosurfacePanel.Visible = 'off';
            modeStr = popupText{popupValue};
            
            switch modeStr
                case {'VolumeRendering', 'MaximumIntensityProjection'}
                    obj.View.handles.volRenPanel.Visible = 'on';
                case 'Isosurface'
                    obj.View.handles.isosurfacePanel.Visible = 'on';
            end
            
            if ~strcmp(obj.volume.Renderer, modeStr)
                obj.volume.Renderer = popupText{popupValue};
            end
            
        end
        
        function mibVolRenGUI_WindowButtonDownFcn(obj, eventdata)
            % function mibVolRenGUI_WindowButtonDownFcn(obj, eventdata)
            % callback for mouse press over the 3d rendering window
            xy = obj.View.handles.alphaAxes.CurrentPoint;
            xyWindow = obj.View.gui.CurrentPoint;
            seltype = obj.View.gui.SelectionType;
            modifier = obj.View.gui.CurrentModifier;
            
            xy = [xy(1,1) xy(1,2)];
            if xy(1) < -obj.maxIntValue/15 || xy(1) > obj.maxIntValue+obj.maxIntValue/15 || xy(2) < -0.3 || xy(2) > 1.3  % check for a click outsize the alphaAxes
                if xyWindow(1) > obj.View.handles.volViewPanel.Position(1) && xyWindow(1) < obj.View.handles.volViewPanel.Position(1)+obj.View.handles.volViewPanel.Position(3) && ...
                        xyWindow(2) > obj.View.handles.volViewPanel.Position(2) && xyWindow(2) < obj.View.handles.volViewPanel.Position(2)+obj.View.handles.volViewPanel.Position(4)
                    % interact with the 3d viewer
                    switch seltype
                        case 'normal'
                            cursorIcon=[NaN NaN NaN NaN NaN NaN NaN NaN NaN 1 1 NaN NaN NaN NaN NaN; NaN NaN NaN NaN NaN NaN NaN NaN 1 1 1 NaN NaN NaN NaN NaN;
                                NaN NaN NaN NaN NaN NaN NaN 1 1 1 1 NaN NaN NaN NaN NaN; NaN NaN NaN NaN NaN NaN NaN 1 1 NaN NaN NaN NaN NaN NaN NaN;
                                NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN NaN NaN NaN NaN NaN NaN; NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN NaN NaN NaN NaN NaN NaN;
                                NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN NaN NaN NaN NaN NaN NaN; NaN NaN 1 NaN NaN NaN 1 1 1 1 NaN NaN NaN NaN NaN NaN;
                                NaN 1 1 1 1 1 NaN 1 NaN NaN 1 1 1 1 1 1; 1 1 1 1 NaN NaN NaN 1 NaN NaN NaN NaN NaN NaN 1 1;
                                1 1 1 1 NaN NaN NaN 1 NaN NaN NaN NaN NaN 1 1 1; 1 NaN NaN NaN NaN NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 1;
                                NaN NaN NaN NaN NaN NaN NaN NaN 1 1 1 NaN NaN NaN NaN 1; NaN NaN NaN NaN NaN NaN NaN 1 1 1 1 NaN NaN NaN NaN NaN;
                                NaN NaN NaN NaN NaN NaN NaN NaN 1 1 1 NaN NaN NaN NaN NaN; NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN NaN NaN NaN];
                            obj.View.gui.Pointer = 'custom';
                            obj.View.gui.PointerShapeCData = cursorIcon;
                            obj.View.gui.PointerShapeHotSpot = round(size(cursorIcon)/2);
                        case 'alt'
                            obj.View.gui.Pointer = 'top';
                    end
                    % update callback for the button up function
                    obj.View.gui.WindowButtonUpFcn = (@(hObject, eventdata, handles) obj.mibVolRenGUI_WindowButtonUpFcn());
                    obj.View.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.mibVolRenGUI_VolumeMotionFcn());
                else
                    obj.volumeAlphaCurve.activePoint = [];    % clear the active point
                    obj.plotAlphaPlot();
                end
            else
                if strcmp(obj.View.handles.volRenPanel.Visible, 'on') % modify the alphamap
                    % fix x,y when they are outside the axes
                    xy(1) = max([xy(1) 0]);
                    xy(1) = min([xy(1) obj.maxIntValue]);
                    xy(2) = max([xy(2) 0]);
                    xy(2) = min([xy(2) 1]);
                    
                    obj.interactWithAlphamap(xy, seltype, modifier);
                end
            end
        end
        
        function mibVolRenGUI_VolumeMotionFcn(obj, eventdata)
            if nargin < 2; eventdata = []; end
            obj.View.handles.statusText.String = sprintf('Position: %.3f x %.3f x %.3f --- CameraUpVector: %.3f x %.3f x %.3f --- CameraTarget: %.3f x %.3f x %.3f', ...
                obj.volume.CameraPosition(1), obj.volume.CameraPosition(2), obj.volume.CameraPosition(3), ...
                obj.volume.CameraUpVector(1), obj.volume.CameraUpVector(2), obj.volume.CameraUpVector(3), ...
                obj.volume.CameraTarget(1), obj.volume.CameraTarget(2), obj.volume.CameraTarget(3));
        end
        
        function mibVolRenGUI_WindowScrollWheelFcn(obj, eventdata)
            % function mibVolRenGUI_WindowScrollWheelFcn(obj, eventdata)
            % callback for mouse wheel action
            obj.mibVolRenGUI_VolumeMotionFcn(eventdata)
        end
        
        function mibVolRenGUI_WindowButtonUpFcn(obj, eventdata)
            % function mibVolRenGUI_WindowButtonUpFcn(obj, eventdata)
            % callback from mouse up button
            
            obj.View.gui.Pointer = 'arrow';
            obj.View.gui.WindowButtonUpFcn = [];
            %obj.View.handles.statusText.String = sprintf('Position: %d %d %d', ...
            %    obj.volume.CameraPosition(1), obj.volume.CameraPosition(2), obj.volume.CameraPosition(3));
        end
        
        
        function interactWithAlphamap(obj, xy, seltype, modifier)
            % function interactWithAlphamap(obj, xy, seltype, modifier)
            % interaction with alphamap plot
            %
            % Parameters:
            % xy: coordinate of the clicked point
            % seltype: selection type - 'normal', 'extend', 'open', 'alt'
            % modifier: key modifier - [], 'shift', 'control'
            
            if nargin < 4; modifier = []; end
            if nargin < 3; seltype = 'normal'; end
            
            if isempty(modifier)
                switch seltype
                    case {'normal', 'extend'}    % left click
                        if isempty(obj.volumeAlphaCurve.activePoint)
                            warndlg(sprintf('!!! Warning !!!\n\nPlease select a point for modification!\n\nThe right mouse click: selects a point that should be modified\nShift + left mouse click: adds a new point\nCtrl + left mouse click: removes the closest point'), ...
                                'No active point');
                            return;
                        end
                        if xy(1) > 0 && xy(1) < obj.maxIntValue
                            if obj.volumeAlphaCurve.activePoint > 1 && obj.volumeAlphaCurve.x(obj.volumeAlphaCurve.activePoint) < 1
                                if xy(1) >= obj.volumeAlphaCurve.x(obj.volumeAlphaCurve.activePoint+1)*obj.maxIntValue
                                    xy(1) = obj.volumeAlphaCurve.x(obj.volumeAlphaCurve.activePoint+1)*obj.maxIntValue - obj.maxIntValue/256;
                                end
                                if xy(1) <= obj.volumeAlphaCurve.x(obj.volumeAlphaCurve.activePoint-1)*obj.maxIntValue
                                    xy(1) = obj.volumeAlphaCurve.x(obj.volumeAlphaCurve.activePoint-1)*obj.maxIntValue + obj.maxIntValue/256;
                                end
                                obj.volumeAlphaCurve.x(obj.volumeAlphaCurve.activePoint) = xy(1)/obj.maxIntValue;
                            end
                            
                        end
                        obj.volumeAlphaCurve.y(obj.volumeAlphaCurve.activePoint) = xy(2);
                        obj.plotAlphaPlot();
                        obj.recalculateAlphamap();
                        
                    case 'open'      % double click, select an active point
                        
                    case 'alt'       % right click, modify the closest point
                        [~, pointIndex] = min(abs(obj.volumeAlphaCurve.x-xy(1)/obj.maxIntValue)); % find the closest point
                        obj.volumeAlphaCurve.activePoint = pointIndex;
                        obj.plotAlphaPlot();
                end
            else
                switch modifier{1}
                    case 'shift'    % add a point
                        xy(1) = xy(1)/obj.maxIntValue;
                        obj.volumeAlphaCurve.x(end+1) = xy(1);
                        obj.volumeAlphaCurve.y(end+1) = xy(2);
                        [obj.volumeAlphaCurve.x, sortIndices] = sort(obj.volumeAlphaCurve.x);
                        obj.volumeAlphaCurve.y = obj.volumeAlphaCurve.y(sortIndices);
                        obj.volumeAlphaCurve.activePoint = find(obj.volumeAlphaCurve.x == xy(1));
                        obj.plotAlphaPlot();
                        obj.recalculateAlphamap();
                    case 'control'  % remove the point
                        if numel(obj.volumeAlphaCurve.x) < 3; return; end     % the border points can't be deleted
                        [~, pointIndex] = min(abs(obj.volumeAlphaCurve.x(2:end-1)-xy(1)/obj.maxIntValue)); % find the closest point
                        pointIndex = pointIndex + 1;
                        obj.volumeAlphaCurve.x(pointIndex) = [];
                        obj.volumeAlphaCurve.y(pointIndex) = [];
                        obj.volumeAlphaCurve.activePoint = [];
                end
                obj.plotAlphaPlot();
                obj.recalculateAlphamap();
            end
        end
        
        function isoColor_Callback(obj)
            % function isoColor_Callback(obj)
            % set color for the isosurface
            obj.Settings.IsoColor = uisetcolor(obj.Settings.IsoColor, 'Select isosurface color');
            if isempty(obj.volume); return; end
            obj.volume.IsosurfaceColor = obj.Settings.IsoColor;
        end
        
        function menuSettingsSelectColormap_Callback(obj)
            % function menuSettingsSelectColormap_Callback(obj)
            % select new default colormap and update the volren view
            global mibPath;
            colormaplist = sort({'jet', 'hsv', 'hot','cool','gray', 'bone', 'copper', 'green', 'red','blue'});
            colormaplist{end+1} = find(ismember(colormaplist,obj.Settings.ColormapName)==1);
            
            prompts = {'Select colormap'; 'Invert'};
            defAns = { colormaplist; logical(obj.Settings.ColormapInvert)};
            title = 'Update the colormap';
            options.WindowStyle = 'normal';
            options.PromptLines = [1, 1];
            options.Title = 'Update the colormap';
            [output, selIndices] = mibInputMultiDlg({mibPath}, prompts, defAns, title, options);
            if isempty(output); return; end
            
            obj.Settings.ColormapName = output{1};
            obj.Settings.ColormapInvert = output{2};
            obj.generateColorMap();
        end
        
        function generateColorMap(obj)
            % function generateColorMap(obj)
            % generate obj.volumeColormap from the selected
            % obj.Settings.ColormapName and obj.Settigns.ColormapInvert
            
            switch obj.Settings.ColormapName
                case 'green'
                    color = zeros([64, 3]);
                    color(:,2) = linspace(0, 1, 64)';
                case 'red'
                    color = zeros([64, 3]);
                    color(:,1) = linspace(0, 1, 64)';
                case 'blue'
                    color = zeros([64, 3]);
                    color(:,3) = linspace(0, 1, 64)';
                case 'custom'
                    color = obj.volumeColormap;
                otherwise
                    cmdString = sprintf('color = %s(64);', obj.Settings.ColormapName);
                    eval(cmdString);
            end
            
            if obj.Settings.ColormapInvert; color = flip(color); end
            colorPoints = linspace(0, 1, size(color,1));
            queryPoints = linspace(0, 1, 256);
            obj.volumeColormap = interp1(colorPoints, color, queryPoints);
            
            if ~isempty(obj.volume)
                obj.volume.Colormap = obj.volumeColormap;
                obj.View.handles.alphaAxes.Colormap = obj.volumeColormap;
            end
        end
        
        function menuSettingsBackgroundColor_Callback(obj)
            % function menuSettingsBackgroundColor_Callback(obj)
            % set background color
            
            obj.Settings.BackgroundColor = uisetcolor(obj.Settings.BackgroundColor, 'Select backgrouns color');
            if isempty(obj.volume); return; end
            obj.volume.BackgroundColor = obj.Settings.BackgroundColor;
            
        end
        
        function isovalEdit_Callback(obj)
            % function isovalEdit_Callback(obj)
            % change isovalue for the isosurface
            
            val = obj.View.handles.isovalSlider.Value;
            if isempty(obj.volume); return; end
            obj.volume.Isovalue = val/obj.maxIntValue;
            
        end
        
        function positions = generatePositionsForSpinAnimation(obj, noFrames, options)
            % function generatePositionsForSpinAnimation(obj)
            % generate camera positions for the spin animation
            %
            % Parameters:
            % noFrames: number of frames
            % options: a structure with optional parameters
            %   .back_and_forth - a switch to make animations in both forward and reverse orientation
            %   .clockwise - a switch 1 - clockwise, 0 - anticlockwise rotation
            %   .rotAxis - a number with rotation axis, 3-'z', 1-'x', 2-'y'
            % Return values:
            % positions: a structure with camera positions for each frame
            %  .CameraUpVector - an array of camera-up vectors for each time point or a single vector
            %  .CameraTarget - an array of camera-target vectors for each time point or a single vector
            %  .CameraPosition - a vector for each time point
            
            if nargin < 3; options = struct(); end
            if nargin < 2; noFrames = 120; end
            if ~isfield(options, 'back_and_forth'); options.back_and_forth = 0; end
            if ~isfield(options, 'clockwise'); options.clockwise = 0; end
            if ~isfield(options, 'rotAxis'); options.rotAxis = obj.View.handles.spinAxisCombo.Value; end
            
            positions.CameraTarget = obj.volume.CameraTarget;
            
            % obtain current position
            currX = obj.volume.CameraPosition(1) - obj.volume.CameraTarget(1);
            currY = obj.volume.CameraPosition(2) - obj.volume.CameraTarget(2);
            currZ = obj.volume.CameraPosition(3) - obj.volume.CameraTarget(3);
            
            switch obj.View.handles.spinAxisCombo.Value
                case 1  % around x-axis
                    positions.CameraUpVector = [-1 0 0];
                    
                    if currZ>=0 && currY>=0
                        currAngle = atan(currZ/currY);  % calculate the angle
                    else
                        currAngle = atan(currZ/currY)+pi();  % calculate the angle
                    end
                    
                    radius = sqrt(currY^2+currZ^2); % calculate distance from the target point
                    % calculate new positions for the camera for the spin
                    if options.back_and_forth == 0
                        if options.clockwise == 1
                            vec = linspace(currAngle, currAngle+2*pi(), noFrames)';
                        else
                            vec = linspace(currAngle+2*pi(), currAngle, noFrames)';
                        end
                    else
                        if options.clockwise == 1
                            vec = [linspace(currAngle, currAngle+2*pi(), noFrames)'; ...
                                linspace(currAngle+2*pi(), currAngle, noFrames)'];
                        else
                            vec = [linspace(currAngle+2*pi(), currAngle, noFrames)';...
                                linspace(currAngle, currAngle+2*pi(), noFrames)'];
                        end
                    end
                    positions.CameraPosition = [zeros(size(vec))+currX+obj.volume.CameraTarget(1) ...
                        cos(vec)*radius+obj.volume.CameraTarget(2) ...
                        sin(vec)*radius+obj.volume.CameraTarget(3)];
                    
                case 2  % around y-axis
                    positions.CameraUpVector = [0 1 0];
                    
                    if currZ>=0 && currX>=0
                        currAngle = atan(currZ/currX);  % calculate the angle
                    else
                        currAngle = atan(currZ/currX)+pi();  % calculate the angle
                    end
                    
                    radius = sqrt(currX^2+currZ^2); % calculate distance from the target point
                    % calculate new positions for the camera for the spin
                    if options.back_and_forth == 0
                        if options.clockwise == 1
                            vec = linspace(currAngle, currAngle+2*pi(), noFrames)';
                        else
                            vec = linspace(currAngle+2*pi(), currAngle, noFrames)';
                        end
                    else
                        if options.clockwise == 1
                            vec = [linspace(currAngle, currAngle+2*pi(), noFrames)'; ...
                                linspace(currAngle+2*pi(), currAngle, noFrames)'];
                        else
                            vec = [linspace(currAngle+2*pi(), currAngle, noFrames)';...
                                linspace(currAngle, currAngle+2*pi(), noFrames)'];
                        end
                    end
                    positions.CameraPosition = [cos(vec)*radius+obj.volume.CameraTarget(1) ...
                        zeros(size(vec))+currY+obj.volume.CameraTarget(2) ...
                        sin(vec)*radius+obj.volume.CameraTarget(3)];
                case 3  % around z-axis
                    positions.CameraUpVector = [0 0 1];
                    
                    if currY>=0 && currX>=0
                        currAngle = atan(currY/currX)+pi();  % calculate the angle
                    else
                        currAngle = atan(currY/currX);  % calculate the angle
                    end
                    radius = sqrt(currX^2+currY^2); % calculate distance from the target point
                    % calculate new positions for the camera for the spin
                    if options.back_and_forth == 0
                        if options.clockwise == 1
                            vec = linspace(currAngle, currAngle+2*pi(), noFrames)';
                        else
                            vec = linspace(currAngle+2*pi(), currAngle, noFrames)';
                        end
                    else
                        if options.clockwise == 1
                            vec = [linspace(currAngle, currAngle+2*pi(), noFrames)'; ...
                                linspace(currAngle+2*pi(), currAngle, noFrames)'];
                        else
                            vec = [linspace(currAngle+2*pi(), currAngle, noFrames)';...
                                linspace(currAngle, currAngle+2*pi(), noFrames)'];
                        end
                    end
                    
                    positions.CameraPosition = [ cos(vec)*radius+obj.volume.CameraTarget(1) ...
                        sin(vec)*radius+obj.volume.CameraTarget(2) ...
                        zeros(size(vec))+currZ+obj.volume.CameraTarget(3)];
            end
            
        end
        
        function spinBtn_Callback(obj)
            % function spinBtn_Callback(obj)
            % test of the spinning
            
            % CameraPosition:   the position of the camera itself
            % CameraTarget:     the camera's look-at point
            % CameraUpVector:   the roll angle (rotation) of the camera
            %                   around it's view axis, defines which axis is up: [0, 0, 1] indicates Z-axis is up
            
            options.clockwise = 1;
            options.back_and_forth = 0;
            
            positions = obj.generatePositionsForSpinAnimation(120, options);
            framerate = 24;
            
            obj.volume.CameraUpVector = positions.CameraUpVector;
            obj.volume.CameraTarget = positions.CameraTarget;
            
            for idx = 1:size(positions.CameraPosition,1)
                obj.volume.CameraPosition = positions.CameraPosition(idx, :);
                %obj.volume.CameraUpVector = myUpVector(idx, :);
                obj.mibVolRenGUI_VolumeMotionFcn();
                pause(1/framerate);
            end
        end
        
        function plotAlphaPlot(obj)
            % function plotAlphaPlot(obj)
            % draw alpha plot
            cla(obj.View.handles.alphaAxes);
            obj.alphaPlotHandle{1} = plot(obj.View.handles.alphaAxes, obj.volumeAlphaCurve.x*obj.maxIntValue, obj.volumeAlphaCurve.y, '.-');
            obj.alphaPlotHandle{1}.MarkerSize = obj.Settings.MarkerSize;
            if ~isempty(obj.volumeAlphaCurve.activePoint)
                hold(obj.View.handles.alphaAxes, 'on');
                obj.alphaPlotHandle{2} = plot(obj.View.handles.alphaAxes, obj.volumeAlphaCurve.x(obj.volumeAlphaCurve.activePoint)*obj.maxIntValue, obj.volumeAlphaCurve.y(obj.volumeAlphaCurve.activePoint), 'r.');
                obj.alphaPlotHandle{2}.MarkerSize = obj.Settings.MarkerSize+2;
            end
            obj.View.handles.alphaAxes.XLim = [0, obj.maxIntValue];
            obj.View.handles.alphaAxes.YLim = [0, 1];
            obj.View.handles.alphaAxes.YLabel.String = 'Opacity';
        end
        
        
        function recalculateAlphamap(obj)
            % function recalculateAlphamap(obj)
            % recalculata obj.alpha.alphamap
            %obj.volumeAlphaCurve.x(end) = obj.maxIntValue;
            queryPoints = linspace(0, obj.maxIntValue, 256);
            obj.volumeAlphaCurve.alphamap = interp1(obj.volumeAlphaCurve.x*obj.maxIntValue, obj.volumeAlphaCurve.y, queryPoints)';
            if ~isempty(obj.volume)
                obj.volume.Alphamap = obj.volumeAlphaCurve.alphamap;
            end
        end
        
        function status = grabVolume(obj)
            % function status = grabVolume(obj)
            % grab the currently displayed volume to the 3D volume viewer
            %
            % Parameters:
            %
            % Return values:
            % status: 1 - success, 0 - cancel
            
            global mibPath;
            status = 0;
            
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions(obj.dataType, 4);
            
            prompts = {'Downsample factor XY:'; 'Downsample factor Z:'; sprintf('or\nWidth:'); 'Height:'; 'Depth:'};
            defAns = {'1'; '1'; num2str(width); num2str(height); num2str(depth)};
            dlgTitle = 'Volume downsample';
            options.PromptLines = [1, 1, 2, 1, 1];   
            options.Title = sprintf('Would you like to downsample the volume?\nVolume dimensions: %d x %d x %d', width, height, depth);  
            options.TitleLines = 2; 
            options.WindowWidth = 1.2;    
            options.Columns = 1;   
            options.Focus = 1;   
            options.LastItemColumns = 1;
            options.okBtnText = 'Continue';
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); obj.closeWindow(); return; end
            
            options = struct;
            if str2double(answer{1}) ~= 1
                options.width = round(width/str2double(answer{1}));
                options.height = round(height/str2double(answer{1}));
            end
            if str2double(answer{2}) ~= 1; options.depth = round(depth/str2double(answer{2})); end
            if str2double(answer{3}) ~= width; options.width = str2double(answer{3}); end
            if str2double(answer{4}) ~= height; options.height = str2double(answer{4}); end
            if str2double(answer{5}) ~= depth; options.depth = str2double(answer{5}); end
            
            wb = waitbar(0, 'Please wait...', 'Name', 'Import volume');
            timePnt = obj.mibModel.I{obj.mibModel.Id}.getCurrentTimePoint();
            pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            
            obj.View.handles.visualizationModePopup.Value = find(ismember(obj.View.handles.visualizationModePopup.String, obj.renderingMode));
            
            img = obj.mibModel.getData3D(obj.dataType, timePnt, 4, obj.colorChannel);
            
            if numel(img) > 1
                msgbox(sprintf('Error!\nPlease select a ROI to render!'),'Error!','error');
                return;
            end
            img = cell2mat(img);
            
            % resize the volume
            if isfield(options, 'width') || isfield(options, 'height') ||  isfield(options, 'depth')
                if ~isfield(options, 'width'); options.width = width; end
                if ~isfield(options, 'height'); options.height = height; end
                if ~isfield(options, 'depth'); options.depth = depth; end
                img = mibResize3d(img, [], options);
                
                pixSize.x = pixSize.x*width/options.width;
                pixSize.y = pixSize.y*height/options.height;
                pixSize.z = pixSize.z*depth/options.depth;
                
            end
            
            % make panel square shape, othewise the volume is scaled wrongly
            volViewPanelPos = obj.View.handles.volViewPanel.Position;
            obj.View.handles.volViewPanel.Position(3) = obj.View.handles.volViewPanel.Position(4);
            if isempty(obj.volume)
                obj.volume = volshow(squeeze(img), 'parent', obj.View.handles.volViewPanel);
            else
                obj.volume.setVolume(squeeze(img));
            end
            obj.View.handles.volViewPanel.Position(3) = volViewPanelPos(3);
            
            obj.volume.Renderer = obj.renderingMode;
            obj.volume.InteractionsEnabled = true;
            obj.volume.IsosurfaceColor = obj.Settings.IsoColor;        %  color for the isosurface
            obj.volume.BackgroundColor = obj.Settings.BackgroundColor;
            
            % scale units around 1
            %minPixSize = min([pixSize.x, pixSize.y, pixSize.z]);
            %obj.volume.ScaleFactors = [pixSize.x/minPixSize, pixSize.y/minPixSize, pixSize.z/minPixSize];
            
            % use um
            obj.volume.ScaleFactors = [pixSize.x, pixSize.y, pixSize.z];
            % store default camera position
            obj.defaultView.CameraPosition = obj.volume.CameraPosition;
            obj.defaultView.CameraTarget = obj.volume.CameraTarget;
            obj.defaultView.CameraUpVector = obj.volume.CameraUpVector;
            
            % update the scaling factor
            obj.volume.CameraPosition = obj.volume.CameraPosition.*obj.volume.ScaleFactors;
            
            obj.maxIntValue = double(intmax(class(img)));
            obj.recalculateAlphamap();
            
            obj.visualizationModePopup_Callback();
            status = 1;
            delete(wb);
        end
        
        function menuInvertAlphaCurve_Callback(obj)
            % function menuInvertAlphaCurve_Callback(obj)
            % invert the alpha curve
            
            %obj.volumeAlphaCurve.x = fliplr(obj.volumeAlphaCurve.x);
            obj.volumeAlphaCurve.x = 1 - obj.volumeAlphaCurve.x;
            [obj.volumeAlphaCurve.x, indices] = sort(obj.volumeAlphaCurve.x);
            obj.volumeAlphaCurve.y = obj.volumeAlphaCurve.y(indices);
            
            obj.volumeAlphaCurve.activePoint = [];
            obj.recalculateAlphamap();
            obj.plotAlphaPlot();
            
        end
        
        function menuToolsAnimation_Callback(obj)
            % function menuToolsAnimation_Callback(obj)
            % start animation editor
            obj.startController('volrenAnimationController', obj);
        end
        
        function menuFileMakesnapshot_Callback(obj)
            % function menuFileMakesnapshot_Callback(obj)
            % make snapshot
            obj.startController('mibSnapshotController', obj);
        end
        
        function menuFileMovie_Callback(obj, mode)
            % function menuFileMovie_Callback(obj, mode)
            % start making movie window
            %
            % Parameters
            % mode: a string with the desired animation type,
            %   'spin' - to spin around selected axis
            %   'animation' - to animate the scene using key frames
            
            options.mode = mode;    % mode for movie make
            obj.startController('mibMakeMovieController', obj, options);
        end
        
        function changeView(obj, orientation)
            % function changeView(obj, orientation)
            % change the view angle
            %
            % Parameters:
            % orientation: a string with desired orientation, 'xy', 'xz', 'yz'
            
            %cameraPos = obj.volume.CameraPosition
            %cameraTarget = obj.volume.CameraTarget
            %cameraDirection = (cameraPos - cameraTarget) / norm(cameraPos - cameraTarget)    % cameraDirection = glm::normalize(cameraPos - cameraTarget);
            
            switch orientation
                case 'xy'
                    obj.volume.CameraPosition(1) = 0;
                    obj.volume.CameraPosition(2) = 0;
                    obj.volume.CameraPosition(3) = 1;
                    obj.volume.CameraUpVector(1) = -1;
                    obj.volume.CameraUpVector(2) = 0;
                    obj.volume.CameraUpVector(3) = 0.5;
                case 'xz'
                    obj.volume.CameraPosition(1) = 1;
                    obj.volume.CameraPosition(2) = 0;
                    obj.volume.CameraPosition(3) = 0;
                    obj.volume.CameraUpVector(1) = 0.5;
                    obj.volume.CameraUpVector(2) = 0;
                    obj.volume.CameraUpVector(3) = 1;
                case 'yz'
                    obj.volume.CameraPosition(1) = 0;
                    obj.volume.CameraPosition(2) = 1;
                    obj.volume.CameraPosition(3) = 0;
                    obj.volume.CameraUpVector(1) = 0;
                    obj.volume.CameraUpVector(2) = 0.5;
                    obj.volume.CameraUpVector(3) = 1;
                case 'default'
                    obj.volume.CameraPosition = obj.defaultView.CameraPosition;
                    obj.volume.CameraTarget = obj.defaultView.CameraTarget;
                    obj.volume.CameraUpVector = obj.defaultView.CameraUpVector;
            end
            obj.volume.CameraPosition = obj.volume.CameraPosition.*obj.volume.ScaleFactors;
        end
        
        function prepareWindowForGrabFrame(obj, width, height)
            % function prepareWindowForGrabFrame(obj, width, height)
            % prepare window to grab a frame
            %
            
            %|
            % @b Examples:
            % @code
            % // as taken from mibSnapshotController
            % obj.extraController.prepareWindowForGrabFrame(width, height);
            % imgOut = obj.extraController.grabFrame(width, height);
            % obj.extraController.restoreWindowAfterGrabFrame();
            % @endcode
            
            obj.View.gui.Units = 'pixels';
            obj.View.handles.volViewPanel.Units = 'pixels';
            
            % store current positions
            obj.figPosStored.mibVolRenGUI = obj.View.gui.Position;
            obj.figPosStored.optionsPanel = obj.View.handles.optionsPanel.Position;
            obj.figPosStored.volViewPanel = obj.View.handles.volViewPanel.Position;
            
            obj.View.gui.Position(1) = 1;
            obj.View.gui.Position(2) = 1;
            obj.View.gui.Position(3) = width+4;
            obj.View.gui.Position(4) = height+4;
            obj.View.handles.optionsPanel.Visible = 'off';
            obj.View.handles.statusText.Visible = 'off';
            
            obj.View.handles.volViewPanel.Position = [1, 1, obj.View.gui.Position(3), obj.View.gui.Position(4)];
        end
        
        function restoreWindowAfterGrabFrame(obj)
            % function restoreWindowAfterGrabFrame(obj)
            % restore widget sizes after the snapshot
            
            % restore positions of the widgets
            obj.View.gui.Position = obj.figPosStored.mibVolRenGUI;
            obj.View.handles.optionsPanel.Position = obj.figPosStored.optionsPanel;
            obj.View.handles.volViewPanel.Position = obj.figPosStored.volViewPanel;
            obj.figPosStored.mibVolRenGUI = [];
            obj.figPosStored.volViewPanel = [];
            obj.figPosStored.optionsPanel = [];
            
            obj.View.handles.optionsPanel.Visible = 'on';
            obj.View.handles.statusText.Visible = 'on';
            obj.View.handles.volViewPanel.Units = 'points';
            obj.View.gui.Units = 'points';
        end
        
        function imgOut = grabFrame(obj, width, height, options)
            % function grabFrame(obj, width, height, options)
            % grab a frame from the volume viewer
            %
            % Parameters
            % width: width of the snapshot, can be empty
            % height: height of the snapshot, can be empty
            % options: [@em optional] structure with extra parameters
            % .resizeWindow - a switch, 1-resize window, 0-do not resize window, used for animations
            % .showWaitbar - show or not waitbar
            % .hWaitbar - a handle to existing waitbar
            % .waitbarProgress - a fraction for the waitbar position
            
            %|
            % @b Examples:
            % @code
            % // for animations
            % obj.prepareWindowForGrabFrame(width, height);     // resize widgets
            % options.resizeWindow = 0; // do not resize the window during the animation
            % for i=1:100
            %   // change view
            %   imgOut = obj.extraController.grabFrame(width, height, options);
            % end
            % obj.extraController.restoreWindowAfterGrabFrame();    // restore widget size
            % @endcode
            % @code
            % // as taken from mibSnapshotController, used for snapshots
            % imgOut = obj.extraController.grabFrame(width, height);
            % @endcode
            
            deleteWaitbar = 0;  % delete or not waitbar after in the end
            
            if nargin < 4; options = struct; end
            if ~isfield(options, 'resizeWindow'); options.resizeWindow = 1; end
            if ~isfield(options, 'showWaitbar'); options.showWaitbar = 1; end
            if ~isfield(options, 'hWaitbar')
                if options.showWaitbar
                    options.hWaitbar = waitbar(0, sprintf('Grabbing the frame\nPlease wait...'));
                    deleteWaitbar = 1;
                end
            end
            if ~isfield(options, 'waitbarProgress'); options.waitbarProgress = 0.5; end
            
            if options.showWaitbar; waitbar(options.waitbarProgress, options.hWaitbar); end
            
            if isempty(width)
                obj.View.handles.volViewPanel.Units = 'pixels';
                width = obj.View.handles.volViewPanel.Position(3);
            end
            if isempty(height)
                obj.View.handles.volViewPanel.Units = 'pixels';
                height = obj.View.handles.volViewPanel.Position(4);
            end
            
            if options.resizeWindow == 1; obj.prepareWindowForGrabFrame(width, height); end
            
            panelPosition = obj.View.handles.volViewPanel.Position;
            panelPosition(1) = panelPosition(1)+1;
            panelPosition(2) = panelPosition(2)+1;
            panelPosition(3) = width;
            panelPosition(4) = height;
            I = getframe(obj.View.gui, panelPosition);
            
            imgOut = I.cdata;
            % imclipboard('copy', I.cdata);
            
            %obj.volume.CameraPosition
            %obj.volume.CameraTarget
            
            % restore the widget sizes
            if options.resizeWindow == 1; obj.restoreWindowAfterGrabFrame(); end
            
            if deleteWaitbar; delete(options.hWaitbar); end
        end
        
        function animationAddFrame(obj, posIndex)
            % function animationAddFrame(obj, posIndex)
            % add/insert a key frame
            %
            % Parameters:
            % posIndex: [@em optional] position of the key frame, when 1 -
            % in the beginning of the animation sequence
            %
            if nargin < 2
                if ~isfield(obj.animationPath, 'CameraPosition')
                    posIndex = 1;
                    obj.animationPath.CameraPosition = [];
                    obj.animationPath.CameraUpVector = [];
                    obj.animationPath.CameraTarget = [];
                else
                    posIndex = size(obj.animationPath.CameraPosition,1)+1;
                end
            end
            
            if posIndex == 1
                obj.animationPath.CameraPosition = [obj.volume.CameraPosition; obj.animationPath.CameraPosition];
                obj.animationPath.CameraUpVector = [obj.volume.CameraUpVector; obj.animationPath.CameraUpVector];
                obj.animationPath.CameraTarget = [obj.volume.CameraTarget; obj.animationPath.CameraTarget];
            elseif posIndex <= size(obj.animationPath.CameraPosition,1)
                obj.animationPath.CameraPosition = [obj.animationPath.CameraPosition(1:posIndex-1, :); obj.volume.CameraPosition; obj.animationPath.CameraPosition(posIndex:end, :)];
                obj.animationPath.CameraUpVector = [obj.animationPath.CameraUpVector(1:posIndex-1, :); obj.volume.CameraUpVector; obj.animationPath.CameraUpVector(posIndex:end, :)];
                obj.animationPath.CameraTarget = [obj.animationPath.CameraTarget(1:posIndex-1, :); obj.volume.CameraTarget; obj.animationPath.CameraTarget(posIndex:end, :)];
            else
                obj.animationPath.CameraPosition(posIndex, :) = obj.volume.CameraPosition;
                obj.animationPath.CameraUpVector(posIndex, :) = obj.volume.CameraUpVector;
                obj.animationPath.CameraTarget(posIndex, :) = obj.volume.CameraTarget;
            end
        end
        
        function positions = generatePositionsForKeyFramesAnimation(obj, noFrames, options)
            % function positions = generatePositionsForKeyFramesAnimation(obj, noFrames, options)
            % generate camera positions from the key frames
            %
            % Parameters:
            % noFrames: number of frames
            % options - an optional structure with additional parameters
            %   .back_and_forth - a switch to make animations in both forward and reverse orientation
            %
            % Return values:
            % positions: a structure with camera positions for each frame of the resulting movie
            %  .CameraUpVector - an array of camera-up vectors for each time point or a single vector
            %  .CameraTarget - an array of camera-target vectors for each time point or a single vector
            %  .CameraPosition - a vector for each time point
            
            if nargin < 3; options = struct(); end
            if nargin < 2; noFrames = obj.Settings.noFramesPreview; end
            if ~isfield(obj.animationPath, 'CameraPosition')
                errordlg(sprintf('!!! Error !!!\n\nThe key frames are required for the animation\nUse the Animation editor to place the key frames\n\n3D Visualization->Menu->Tools->Animation editor'), 'Missing key frames')
                return;
            end
            
            if ~isfield(options, 'back_and_forth'); options.back_and_forth = 0; end
            
            % cumulative sum of distances
            distVec = [0; cumsum(sqrt(sum(diff(obj.animationPath.CameraPosition).^2,2)))];
            notOk = 1;
            while notOk
                [~, ids] = unique(distVec);     % shift duplicates slightly
                if numel(ids) < numel(distVec)
                    distVec(~ismember(1:numel(distVec), ids)) = distVec(~ismember(1:numel(distVec), ids))+.000001;
                else
                    notOk = 0;
                end
            end
            
            % interpolate points for camera path
            warning_state = warning('off');
            flyCameraPath = interp1(distVec, obj.animationPath.CameraPosition, unique([distVec(:)' linspace(0, distVec(end), noFrames)]), 'v5cubic');
            warning(warning_state); % Switch warning back to initial settings
            
            % preview the camera path
%             figure(322);
%             plot3(obj.animationPath.CameraPosition(:,1), obj.animationPath.CameraPosition(:,2), obj.animationPath.CameraPosition(:,3));
%             hold on;
%             plot3(flyCameraPath(:,1), flyCameraPath(:,2), flyCameraPath(:,3));
            
            %                     distVec = [0; cumsum(sqrt(sum(diff(obj.animationPath.CameraUpVector).^2,2)))];
            %                     notOk = 1;
            %                     while notOk
            %                         [~, ids] = unique(distVec);     % shift duplicates slightly
            %                         if numel(ids) < numel(distVec)
            %                             distVec(~ismember(1:5, ids)) = distVec(~ismember(1:5, ids))+.000001;
            %                         else
            %                             notOk = 0;
            %                         end
            %                     end
            flyCameraUpVectorPath = interp1(distVec, obj.animationPath.CameraUpVector, unique([distVec(:)' linspace(0, distVec(end), noFrames)]), 'pchip');
            
            if options.back_and_forth == 1
                flyCameraPath = [flyCameraPath; flip(flyCameraPath, 1)];
                flyCameraUpVectorPath = [flyCameraUpVectorPath; flip(flyCameraUpVectorPath, 1)];
            end
            
            positions.CameraPosition = flyCameraPath;
            positions.CameraUpVector = flyCameraUpVectorPath;
            positions.CameraTarget = [];
            %obj.volume.CameraUpVector = positions.CameraUpVector;
            %obj.volume.CameraTarget = positions.CameraTarget;
            
        end
        
        function menuFileLoadAnimation_Callback(obj)
            % function menuFileLoadAnimation_Callback(obj)
            % load animation path from a file
            
            mypath = fileparts(obj.animationFilename);
            [filename, path] = uigetfile(...
                {'*.animation;',  'Matlab format (*.animation)'; ...
                '*.*', 'All Files (*.*)'}, ...
                'Load animation...', mypath);
            if isequal(filename, 0); return; end % check for cancel
            obj.animationFilename = fullfile(path, filename);
            
            res = load(obj.animationFilename, '-mat');
            if ~isfield(res, 'animPath')
                errordlg('Missing the animPath field!', 'Error');
                return;
            end
            obj.animationPath = res.animPath;
            fprintf('The animation was loaded:\n%s\n', obj.animationFilename);
            obj.updateWidgets();
        end
        
        function menuFileSaveAnimation_Callback(obj)
            % function menuFileSaveAnimation_Callback(obj)
            % save animation path to a file
            if ~isfield(obj.animationPath, 'CameraPosition')
                errordlg(sprintf('!!! Error !!!\n\nThe animation path is not present!\nPlease use the Animation editor to create it\n(Menu->Tools->Animation editor)'), 'Missing the path');
                return;
            end
            
            [filename, path, FilterIndex] = uiputfile(...
                {'*.animation',  'Matlab format (*.animation)'; ...
                '*.*',  'All Files (*.*)'}, ...
                'Save animation...', obj.animationFilename);
            if isequal(filename, 0); return; end % check for cancel
            obj.animationFilename = [path filename];
            
            animPath = obj.animationPath;
            save(obj.animationFilename, 'animPath', '-v7.3');
            fprintf('The animation was saved to\n%s\n', obj.animationFilename);
        end
        
        function previewAnimation(obj, noFrames)
            % function previewAnimation(obj, noFrames)
            % preview animation
                
            if nargin < 2; noFrames = obj.Settings.noFramesPreview; end 
            if ~isfield(obj.animationPath, 'CameraPosition'); return; end
            
            positions = obj.generatePositionsForKeyFramesAnimation(noFrames);
            
            framerate = 24;
            for idx = 1:size(positions.CameraPosition, 1)
                obj.volume.CameraPosition = positions.CameraPosition(idx, :);
                obj.volume.CameraUpVector = positions.CameraUpVector(idx, :);
                if ~isempty(positions.CameraTarget)
                    obj.volume.CameraUpVector = positions.CameraTarget(idx, :);
                end
                %obj.volume.CameraUpVector = myUpVector(idx, :);
                obj.mibVolRenGUI_VolumeMotionFcn();
                pause(1/framerate);
            end
        end
        
        function devTest(obj, mode)
            % function devTest(obj, mode)
            % for development
            
            % animationPath
            % a structure with animation path
            % .CameraPosition - a matrix of camera positions [keyFrame, x,y,z]
            % .CameraUpVector - a matrix of camera up vectors [keyFrame, x,y,z]
            % .CameraTarget - a matrix of camera target positions [keyFrame, x,y,z]
            
            switch mode
                case 'add'
                    if ~isfield(obj.animationPath, 'CameraPosition')
                        posIndex = 1;
                    else
                        posIndex = size(obj.animationPath.CameraPosition,1)+1;
                    end
                    
                    obj.animationPath.CameraPosition(posIndex, :) = obj.volume.CameraPosition';
                    obj.animationPath.CameraUpVector(posIndex, :) = obj.volume.CameraUpVector';
                    obj.animationPath.CameraTarget(posIndex, :) = obj.volume.CameraTarget';
                case 'clear'
                    obj.animationPath = struct();
                case 'fly'
                    if ~isfield(obj.animationPath, 'CameraPosition'); return; end
                    noFrames = 120;     % number of frames
                    
                    % cumulative sum of distances
                    distVec = [0; cumsum(sqrt(sum(diff(obj.animationPath.CameraPosition).^2,2)))];
                    notOk = 1;
                    while notOk
                        [~, ids] = unique(distVec);     % shift duplicates slightly
                        if numel(ids) < numel(distVec)
                            distVec(~ismember(1:numel(distVec), ids)) = distVec(~ismember(1:numel(distVec), ids))+.000001;
                        else
                            notOk = 0;
                        end
                    end
                    
                    % interpolate points for camera path
                    flyCameraPath = interp1(distVec, obj.animationPath.CameraPosition, unique([distVec(:)' linspace(0, distVec(end), noFrames)]), 'pchip');
                    
                    % preview the camera path
                    %figure(321);
                    %plot3(obj.animationPath.CameraPosition(:,1), obj.animationPath.CameraPosition(:,2), obj.animationPath.CameraPosition(:,3));
                    %hold on;
                    %plot3(flyCameraPath(:,1), flyCameraPath(:,2), flyCameraPath(:,3));
                    
                    %                     distVec = [0; cumsum(sqrt(sum(diff(obj.animationPath.CameraUpVector).^2,2)))];
                    %                     notOk = 1;
                    %                     while notOk
                    %                         [~, ids] = unique(distVec);     % shift duplicates slightly
                    %                         if numel(ids) < numel(distVec)
                    %                             distVec(~ismember(1:5, ids)) = distVec(~ismember(1:5, ids))+.000001;
                    %                         else
                    %                             notOk = 0;
                    %                         end
                    %                     end
                    flyCameraUpVectorPath = interp1(distVec, obj.animationPath.CameraUpVector, unique([distVec(:)' linspace(0, distVec(end), noFrames)]), 'pchip');
                    framerate = 24;
                    
                    %obj.volume.CameraUpVector = positions.CameraUpVector;
                    %obj.volume.CameraTarget = positions.CameraTarget;
                    
                    for idx = 1:noFrames
                        obj.volume.CameraPosition = flyCameraPath(idx, :);
                        obj.volume.CameraUpVector = flyCameraUpVectorPath(idx, :);
                        %obj.volume.CameraUpVector = myUpVector(idx, :);
                        obj.mibVolRenGUI_VolumeMotionFcn();
                        pause(1/framerate);
                    end
                    
            end
        end
    end
end