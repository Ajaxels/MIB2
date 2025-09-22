% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

classdef mibVolRenAppController < handle
    % @type mibVolRenAppController class is a template class for using with
    % GUI developed using appdesigner of Matlab
    %
    % @code
    % obj.startController('mibVolRenAppController'); // as GUI tool
    % @endcode
    % or
    % @code
    % // a code below was used for mibImageArithmeticController
    % BatchOpt.Parameter = 'test';  // fill edit boxes as strings
    % BatchOpt.Checkbox = true;     // fill checkboxes with logicals: true/false
    % BatchOpt.Popup = {'value'};        // value for the popups as a cell
    % BatchOpt.Radio = {'Radio1'};          // selection of radio buttons, as cell with the handle of the target radio button
    % BatchOpt.showWaitbar = true;  // show or not the waitbar
    % obj.startController('mibVolRenAppController', [], BatchOpt); // start mibVolRenAppController in the batch mode
    % @endcode
    % or
    % @code
    % // trigger return of the possible Options using returnBatchOpt function
    % // using notify syncBatch event
    % obj.startController('mibVolRenAppController', [], NaN);
    % @endcode

    % Updates
    %

    properties
        mibModel
        % handles to mibModel
        View
        % handle to the view / mibVolRenAppGUI
        listener
        % a cell array with handles to listeners
        BatchOpt
        % a structure compatible with batch operation
        % name of each field should be displayed in a tooltip of GUI
        % it is recommended that the Tags of widgets match the name of the
        % fields in this structure
        % .Parameter - [editbox], char/string
        % .Checkbox - [checkbox], logical value true or false
        % .Dropdown{1} - [dropdown],  cell string for the dropdown
        % .Dropdown{2} - [optional], an array with possible options
        % .Radio - [radiobuttons], cell string 'Radio1' or 'Radio2'...
        % .ParameterNumeric{1} - [numeric editbox], cell with a number
        % .ParameterNumeric{2} - [optional], vector with limits [min, max]
        % .ParameterNumeric{3} - [optional], string 'on' - to round the value, 'off' to do not round the value
        childControllers
        % list of opened subcontrollers
        childControllersIds
        % a cell array with names of initialized child controllers
        alphaPlotHandle
        % handle to the alpha plot
        animationFilename
        % template for the animation filename
        animationPath
        % a structure with animation path
        % .CameraPosition - a matrix of camera positions [keyFrame, x,y,z]
        % .CameraUpVector - a matrix of camera up vectors [keyFrame, x,y,z]
        % .CameraTarget - a matrix of camera target positions [keyFrame, x,y,z]
        animationPreviewRunning
        % logical switch defining whether the animation is previewed
        defaultView
        % a structure with the default camera position
        figPosStored
        %  a structure with stored positions of the widgets for making snapshots
        % .mibVolRenAppFigure -> position of the main figure
        % .mainGridLayoutRowHeights -> heights of rows in obj.View.handles.mainGridLayout
        keyFrameTableIndex
        % index of the selected key frame
        matlabVersion
        % current version of MATLAB
        maxIntValue
        % max integer value of the loaded volume
        noOverlayMaterials
        % number of materials shown in the overlay
        overlayShownMaterials
        % a vector of shown (true) or hidden (false) materials in the model overlay
        overlayAlpha
        % a vector with alpha values for overlay materials
        modelTableIndex
        % index of the selected material in the modelTable
        scalingTransform
        % tform to scale the dataset upon loading to have its units in um
        Settings
        % a structure with settings, initialized from obj.mibModel.preferences.VolRen;
        % .volumeAlphaCurve.x = [0 .3 .7 1];
        % .volumeAlphaCurve.y = [1 1 0 0];
        % .markerSize -  marker size for the alpha plot
        % .BackgroundColor - color for the background
        % .colormapName - a string with default colormap, or 'custom' (not yet implemented)
        % .colormapInvert - true/false, invert or not the colormap
        % .animationPath - a structure with animation path
        % .noFramesPreview - number of frames for the preview
        surfList
        % a cell array of generated surfaces
        surfListAlpha
        % an array of alpha values for the generated surfaces
        surfaceTableIndex
        % index of the selected row in the surfaceTable
        viewer
        % handle to the main viewer widget
        volume
        % main image volume
        volumeAlphaCurve
        % a structure with alpha curve details
        % .x - vector of intensity points [0 - 1]
        % .y - value of alpha for each intensity point [0 - 1]
        % .alphamap - calculated alpha map used in volshow
        % .activePoint -  selected point
        volumeColormap
        % vector with the colormap
        volumeScaleFactor
        % scale factor to downsample the datasets, below 1
    end

    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end

    methods (Static)
        function ViewListner_Callback(obj, src, evnt)
            switch evnt.EventName
                case {'updateGuiWidgets'}
                    obj.updateWidgets();
                case 'SlicePlanesChanged'
                    % update slice sliders and editboxes
                    obj.View.handles.xSlider.Value = max([1, floor(double(obj.volume.SlicePlaneValues(1,4)))]);      % x-plane
                    obj.View.handles.ySlider.Value = max([1, floor(double(obj.volume.SlicePlaneValues(2,4)))]);      % y-plane
                    obj.View.handles.zSlider.Value = max([1, floor(double(obj.volume.SlicePlaneValues(3,4)))]);      % z-plane
                    obj.View.handles.xSliderEdit.Value = obj.View.handles.xSlider.Value;
                    obj.View.handles.ySliderEdit.Value = obj.View.handles.ySlider.Value;
                    obj.View.handles.zSliderEdit.Value = obj.View.handles.zSlider.Value;
            end
        end

        function cameraListner_Callback(obj, src, evnt)
            % listener callback for camera moving

            if ~isfield(obj.defaultView, 'CameraPosition')
                % for some reason, the camera settings can not be
                % obtained in grabVolume function unless a
                % breakpoint is used. To fix that somehow, init the
                % values after first user interaction with the volume
                obj.defaultView.CameraPosition = obj.viewer.CameraPosition;
                obj.defaultView.CameraTarget = obj.viewer.CameraTarget;
                obj.defaultView.CameraUpVector = [0 0 1];%obj.viewer.CameraUpVector;
                obj.defaultView.CameraZoom = 1; % obj.viewer.CameraZoom;
            end

            % update current camera status
            if strcmp(obj.View.handles.topTabGroup.SelectedTab.Tag, 'viewerTab')
                obj.updateCameraWidgets();
            end
        end
    end

    methods
        function obj = mibVolRenAppController(mibModel, varargin)
            % function obj = mibVolRenAppController(mibModel, options)
            % class constructor
            %
            % Parameters:
            % mibModel: a handle to mibModel class
            % options: a structure with optional initialization parameters
            %   .Settings - settings for initialization of the volviewer

            if nargin < 2
                options = struct();
            else
                options = varargin{1};
            end

            % detault parameters
            obj.Settings = mibModel.preferences.VolRen;
            %           Prefs.VolRen.Viewer.backgroundColor = [0 0.329 0.529];
            %           Prefs.VolRen.Viewer.gradientColor = [0 0.561 1];
            %           Prefs.VolRen.Viewer.backgroundGradient = 'on';
            %           Prefs.VolRen.Viewer.lighting = 'on';
            %           Prefs.VolRen.Viewer.lightColor = [1 1 1];
            %           Prefs.VolRen.Viewer.showScaleBar = 'on';
            %           Prefs.VolRen.Viewer.scaleBarUnits = 'um';
            %           Prefs.VolRen.Viewer.showOrientationAxes = 'on';
            %           Prefs.VolRen.Viewer.showBox = 'off';
            %
            %           Prefs.VolRen.Volume.volumeAlphaCurve.x = [0 .3 .7 1];
            %           Prefs.VolRen.Volume.volumeAlphaCurve.y = [1 1 0 0];
            %           Prefs.VolRen.Volume.isosurfaceValue = 0.5;
            %           Prefs.VolRen.Volume.colormapName = 'gray';
            %           Prefs.VolRen.Volume.colormapInvert = true;
            %           Prefs.VolRen.Volume.markerSize = 15;

            obj.Settings.animationPath = struct();
            obj.Settings.noFramesPreview = 120;     % number of frames for the animation preview mode

            obj.childControllers = {};    % initialize child controllers
            obj.childControllersIds = {};

            % update class variables
            % combine provided and default structures
            % obj.Settings = mibConcatenateStructures(obj.Settings, options);
            obj.mibModel = mibModel;    % assign model
            obj.volume = [];
            obj.volumeScaleFactor = 1;
            obj.keyFrameTableIndex = [];
            obj.modelTableIndex = [];
            obj.surfaceTableIndex = [];
            obj.animationPath = obj.Settings.Animation.animationPath;
            obj.animationPreviewRunning = false;
            obj.noOverlayMaterials = 0;     % number of the model overlay materials
            obj.overlayShownMaterials = [];          % vertor of shown/hidden materials of the overlay
            obj.overlayAlpha = [];        % a vector with alpha values for overlay materials
            obj.surfList = {};  % cell array with the generated surface
            obj.surfListAlpha = []; % array of alpha values for the generated surfaces

            % check for the virtual stacking mode and close the controller
            if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                toolname = 'volume rendering';
                warndlg(sprintf('!!! Warning !!!\n\nThe %s not available in the virtual stacking mode\nplease switch to the memory-resident mode and try again', ...
                    toolname), 'Not implemented');
                obj.closeWindow();
                return;
            end

            guiName = 'mibVolRenAppGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view

            % update font and size
            % you may need to replace "obj.View.handles.text1" with tag of any text field of your own GUI
            % % this function is not yet
            global Font;
            if ~isempty(Font)
              if obj.View.handles.cameraZoomEdit.FontSize ~= Font.FontSize + 4 ...  % guide font size is 4 points smaller than in appdesigner
                    || ~strcmp(obj.View.handles.cameraZoomEdit.FontName, Font.FontName)
                  mibUpdateFontSize(obj.View.gui, Font);
              end
            end

            % Add new renderers
            % get matlab version
            if obj.mibModel.matlabVersion >= 23.2 % R2023b
                obj.View.handles.rendererDropDown.Items = [obj.View.handles.rendererDropDown.Items, 'CinematicRendering', 'LightScattering'];
            end

            % start 3D viewer in a separate window
            obj.startController('mibVolRenAppViewerController', obj);
            drawnow;
            
            % init the viewer
            obj.viewer = viewer3d(obj.childControllers{1}.View.handles.volumeViewerPanel, ...
                'BackgroundColor', obj.Settings.Viewer.backgroundColor, ...
                'backgroundGradient', obj.Settings.Viewer.backgroundGradient, ...
                'GradientColor', obj.Settings.Viewer.gradientColor);

            % show scale bar
            obj.viewer.ScaleBar =  obj.Settings.Viewer.showScaleBar;
            obj.viewer.ScaleBarUnits = obj.Settings.Viewer.scaleBarUnits;
            obj.volumeAlphaCurve.x = obj.Settings.Volume.volumeAlphaCurve.x;
            obj.volumeAlphaCurve.y = obj.Settings.Volume.volumeAlphaCurve.y;
            obj.volumeAlphaCurve.activePoint = [];
            obj.alphaPlotHandle = [];
            obj.defaultView = struct();

            % generate output filename for animations
            [pathstr, name] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            fn_out = fullfile(pathstr, [name '.animation']);
            if isempty(strfind(fn_out, '/')) && isempty(strfind(fn_out, '\')) %#ok<STREMP>
                fn_out = fullfile(obj.mibModel.myPath, fn_out);
            end
            if isempty(fn_out); fn_out = obj.mibModel.myPath; end
            obj.animationFilename = fn_out;

            % move the window to the left hand side of the main window
            obj.View.gui = moveWindowOutside(obj.View.gui, 'left');
            
            if numel(fieldnames(options)) == 0  % grab volume
                status = obj.grabVolume();
            else
                status = obj.grabVolume(options.dataType, options.colorChannel);
            end
            if status == 0; return; end     % action cancelled from grabVolume

            obj.updateWidgets();
            obj.generateColorMap();     % generate colormap vector from the selected colormap

            % add listner to
            % obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));    % listen changes in number of ROIs
            obj.listener{2} = addlistener(obj.viewer, 'CameraMoving', @(src,evnt) obj.cameraListner_Callback(obj, src, evnt));    % listen changes in number of ROIs
            obj.listener{3} = addlistener(obj.volume, 'SlicePlanesChanged', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));    % listen changes in number of ROIs
        end

        function updateVolumeRenderingStyle(obj)
            % function updateVolumeRenderingStyle(obj)
            % update Volume Rendering Style
            %
            % Parameters:
            % style: string with new rendering style: VolumeRendering,
            % MaximumIntensityProjection, MinimumIntensityProjection,
            % GradientOpacity, Isosurface, SlicePlanes

            obj.View.handles.slicesGridLayout.Visible = 'off';

            switch obj.View.handles.rendererDropDown.Value
                case 'Isosurface'
                    obj.View.handles.isovalueSlider.Enable = 'on';
                    obj.View.handles.isovalueEdit.Enable = 'on';
                    obj.View.handles.isovalueLabel.Text = 'Iso-value';
                    obj.View.handles.isovalueEdit.Value = obj.Settings.Volume.isosurfaceValue;
                    obj.View.handles.isovalueSlider.Value = obj.Settings.Volume.isosurfaceValue;
                case  'GradientOpacity'
                    obj.View.handles.isovalueSlider.Enable = 'on';
                    obj.View.handles.isovalueEdit.Enable = 'on';
                    obj.View.handles.isovalueLabel.Text = 'Opacity';
                    obj.View.handles.isovalueEdit.Value = obj.Settings.Volume.gradientOpacityValue;
                    obj.View.handles.isovalueSlider.Value = obj.Settings.Volume.gradientOpacityValue;
                case 'SlicePlanes'
                    obj.View.handles.slicesGridLayout.Visible = 'on';
                    obj.View.handles.isovalueSlider.Enable = 'off';
                    obj.View.handles.isovalueEdit.Enable = 'off';
                otherwise
                    obj.View.handles.isovalueSlider.Enable = 'off';
                    obj.View.handles.isovalueEdit.Enable = 'off';
            end
            obj.volume.RenderingStyle = obj.View.handles.rendererDropDown.Value;
            %obj.volume.RenderingStyle = 'CinematicRendering';
            %obj.volume.RenderingStyle = 'LightScattering';
            
        end

        function updateIsovalue(obj, newIsovalue)
            % function updateIsovalue(obj, newIsovalue)
            % update IsosurfaceValue of the volume

            switch obj.View.handles.rendererDropDown.Value
                case 'Isosurface'
                    obj.Settings.Volume.isosurfaceValue = newIsovalue;
                    obj.volume.IsosurfaceValue = obj.Settings.Volume.isosurfaceValue;
                case 'GradientOpacity'
                    obj.Settings.Volume.gradientOpacityValue = newIsovalue;
                    obj.volume.GradientOpacityValue = obj.Settings.Volume.gradientOpacityValue;
            end
        end

        function alphaAxesButtonDown(obj, event)
            % function alphaAxesButtonDown(obj, event)
            % buttom down event above obj.View.handles.alphaAxes

            xy = obj.View.handles.alphaAxes.CurrentPoint;
            seltype = obj.View.gui.SelectionType;
            modifier = obj.View.gui.CurrentModifier;

            xy = [xy(1,1); xy(1,2)];    % get x,y coordinates
            % correct y-coordinate
            xy(2) = min([xy(2), 1]);
            xy(2) = max([xy(2), 0]);

            if isempty(modifier)
                switch seltype
                    case {'normal', 'extend'}    % left click
                        if isempty(obj.volumeAlphaCurve.activePoint)
                            %warndlg(sprintf('!!! Warning !!!\n\nPlease select a point for modification!\n\nThe right mouse click: selects a point that should be modified\nShift + left mouse click: adds a new point\nCtrl + left mouse click: removes the closest point'), ...
                            %    'No active point');
                            uialert(obj.View.gui, ...
                                sprintf('!!! Warning !!!\n\nPlease select a point for modification!\n\nThe right mouse click: selects a point that should be modified\nShift + left mouse click: adds a new point\nCtrl + left mouse click: removes the closest point'), ...
                                'No active point', 'Icon', 'info');
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

        function updateBackgroundColor(obj, event)
            % function updateBackgroundColor(obj, event)
            % update background color settings
            %
            % Parameters:
            % event: a structure event generated upon selection of the
            % operation to perform

            switch event.Source.Tag
                case 'menuBackgroundColor'
                    obj.Settings.Viewer.backgroundColor = uisetcolor(obj.Settings.Viewer.backgroundColor, 'Select main background color');
                    obj.viewer.BackgroundColor = obj.Settings.Viewer.backgroundColor;
                case 'menuBackgroundGradientColor'
                    obj.Settings.Viewer.gradientColor = uisetcolor(obj.Settings.Viewer.gradientColor, 'Select secondary background color');
                    obj.Settings.Viewer.gradientColor = obj.Settings.Viewer.gradientColor;
                case 'menuBackgroundGradient'
                    if event.Source.Checked
                        event.Source.Checked = "off";
                        obj.viewer.BackgroundGradient = 'off';
                        obj.Settings.Viewer.backgroundGradient = 'off';
                    else
                        event.Source.Checked = "on";
                        obj.viewer.BackgroundGradient = 'on';
                        obj.Settings.Viewer.backgroundGradient = 'on';
                    end

            end
        end

        function updateColormap(obj, event)
            % function updateColormap(obj, event)
            % select and update colormap
            %
            % Parameter:
            % event: a handle to the selected widget
            % event.Source.Tag == colormapName -> string with the name of the selected colormap
            % event.Source.Tag == invertColormap -> logical, indicating inversion of the color map

            switch event.Source.Tag
                case 'colormapName'
                    obj.Settings.Volume.colormapName = event.Source.Value;
                case 'colormapInvert'
                    obj.Settings.Volume.colormapInvert = event.Source.Value;
                case 'colormapBlackPoint'
                    obj.Settings.Volume.colormapBlackPoint = event.Source.Value;
                case 'colormapWhitePoint'
                    obj.Settings.Volume.colormapWhitePoint = event.Source.Value;
            end
            obj.generateColorMap();
        end


        function generateColorMap(obj)
            % function generateColorMap(obj)
            % generate obj.volumeColormap from the selected
            % obj.Settings.Volume.colormapName and obj.Settings.Volume.colormapInvert

            % find points to stretch the colormap
            pnt1 = ceil(obj.View.handles.colormapBlackPoint.Value/4)+1;
            pnt2 = floor(obj.View.handles.colormapWhitePoint.Value/4);
            
            switch obj.Settings.Volume.colormapName
                case 'green'
                    color = zeros([64, 3]);
                    color(pnt1:pnt2, 2) = linspace(0, 1, pnt2-pnt1+1)';
                    if pnt2 < 64; color(pnt2+1:end,2) = 1; end
                case 'red' 
                    color = zeros([64, 3]);
                    color(pnt1:pnt2, 1) = linspace(0, 1, pnt2-pnt1+1)';
                    if pnt2 < 64; color(pnt2+1:end,1) = 1; end
                case 'blue'
                    color = zeros([64, 3]);
                    color(pnt1:pnt2, 3) = linspace(0, 1, pnt2-pnt1+1)';
                    if pnt2 < 64; color(pnt2+1:end, 3) = 1; end
                case 'custom'
                    color = obj.volumeColormap;
                otherwise
                    %cmdString = sprintf('color = %s(64);', obj.Settings.Volume.colormapName);
                    %eval(cmdString);
                    
                    cmdString = sprintf('color_temp = %s;', obj.Settings.Volume.colormapName);
                    eval(cmdString);
                    color = repmat(color_temp(1,:), [64, 1]); %#ok<USENS> 
                    queryPoints = linspace(1, 256, (pnt2-pnt1+1));
                    for colCh = 1:size(color_temp,2)
                        color(pnt1:pnt2, colCh) = interp1(1:256, color_temp(:,colCh), queryPoints);
                    end
                    if pnt2 < 64; color(pnt2+1:end, :) = repmat(color_temp(end,:), [64-pnt2, 1]); end

            end

            if obj.Settings.Volume.colormapInvert; color = flip(color); end
            colorPoints = linspace(0, 1, size(color,1));
            queryPoints = linspace(0, 1, 256);
            obj.volumeColormap = interp1(colorPoints, color, queryPoints);

            colormap(obj.View.handles.colormapAxes, color);
            colorbar(obj.View.handles.colormapAxes, 'Location', 'north', ...
                'Ticks', [0 0.25 0.5 0.75 1], 'TickLabels', {'0','64','128', '192', '255'}, ...
                'FontSize', 9);
            
            if ~isempty(obj.volume)
                obj.volume.Colormap = obj.volumeColormap;
                obj.View.handles.alphaAxes.Colormap = obj.volumeColormap;
            end
        end

        function updateCameraWidgets(obj)
            % update widgets that describe position of the camera
            if ~isvalid(obj.viewer); return; end % skip when the viewer is closed

            obj.View.handles.cameraZoomEdit.Value = double(obj.viewer.CameraZoom);
            obj.View.handles.cameraPositionX.Value = double(obj.viewer.CameraPosition(1));
            obj.View.handles.cameraPositionY.Value = double(obj.viewer.CameraPosition(2));
            obj.View.handles.cameraPositionZ.Value = double(obj.viewer.CameraPosition(3));
            obj.View.handles.cameraTargetX.Value = double(obj.viewer.CameraTarget(1));
            obj.View.handles.cameraTargetY.Value = double(obj.viewer.CameraTarget(2));
            obj.View.handles.cameraTargetZ.Value = double(obj.viewer.CameraTarget(3));
            obj.View.handles.cameraUpVectorX.Value = double(obj.viewer.CameraUpVector(1));
            obj.View.handles.cameraUpVectorY.Value = double(obj.viewer.CameraUpVector(2));
            obj.View.handles.cameraUpVectorZ.Value = double(obj.viewer.CameraUpVector(3));
            obj.View.handles.cameraDistanceEdit.Value = double(sqrt(sum((obj.viewer.CameraPosition - obj.viewer.CameraTarget).^2)));
        end

        function menuChangeView(obj, event)
            % function menuChangeView(obj, event)
            % callback for selection of views
            %
            % Parameters:
            % event: a handle to the selected widget
            % event.Source.Tag = menuDefaultView -> show the default view
            % event.Source.Tag = menuXYview -> show the XY view
            % event.Source.Tag = menuXZview -> show the XZ view
            % event.Source.Tag = menuYZview -> show the YZ view

            %cameraPos = obj.volume.CameraPosition
            %cameraTarget = obj.volume.CameraTarget
            %cameraDirection = (cameraPos - cameraTarget) / norm(cameraPos - cameraTarget)    % cameraDirection = glm::normalize(cameraPos - cameraTarget);

            switch event.Source.Tag
                case 'menuDefaultView'
                    obj.viewer.CameraPosition = obj.defaultView.CameraPosition;
                    obj.viewer.CameraTarget = obj.defaultView.CameraTarget;
                    obj.viewer.CameraUpVector = obj.defaultView.CameraUpVector;
                    obj.viewer.CameraZoom = obj.defaultView.CameraZoom;
                case 'menuXYview'
                    obj.viewer.CameraPosition = [obj.defaultView.CameraTarget(1) obj.defaultView.CameraTarget(2) obj.defaultView.CameraTarget(3)*5];
                    obj.viewer.CameraTarget = obj.defaultView.CameraTarget;
                    obj.viewer.CameraUpVector = [1 0 0];
                case 'menuXZview'
                    obj.viewer.CameraPosition = [obj.defaultView.CameraTarget(1) obj.defaultView.CameraTarget(2)*5 obj.defaultView.CameraTarget(3)];
                    obj.viewer.CameraTarget = obj.defaultView.CameraTarget;
                    obj.viewer.CameraUpVector = [0 0 1];
                case 'menuYZview'
                    obj.viewer.CameraPosition = [obj.defaultView.CameraTarget(1)*5 obj.defaultView.CameraTarget(2) obj.defaultView.CameraTarget(3)];
                    obj.viewer.CameraTarget = obj.defaultView.CameraTarget;
                    obj.viewer.CameraUpVector = [0 0 1];
            end
            obj.viewer.CameraZoom = 1;
            %obj.viewer.CameraPosition = obj.viewer.CameraPosition.*obj.volumeScaleFactor;
        end

        function closeWindow(obj)
            % closing mibVolRenAppController window
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
            obj.mibModel.preferences.VolRen = obj.Settings;

            notify(obj, 'closeEvent');      % notify mibController that this child window is closed
        end

        function updateWidgets(obj)
            % function updateWidgets(obj)
            % update widgets of this window

            obj.View.handles.showScaleBar.Value = obj.Settings.Viewer.showScaleBar;
            obj.View.handles.showOrientationAxes.Value = obj.Settings.Viewer.showOrientationAxes;
            obj.View.handles.showBox.Value = obj.Settings.Viewer.showBox;
            obj.View.handles.AmbientLight.Value = obj.Settings.Viewer.AmbientLight;
            obj.View.handles.DiffuseLight.Value = obj.Settings.Viewer.DiffuseLight;
            obj.View.handles.rendererDropDown.Value = obj.Settings.Volume.renderer;
            obj.View.handles.isovalueSlider.Value = obj.Settings.Volume.isosurfaceValue;
            obj.View.handles.isovalueEdit.Value = obj.Settings.Volume.isosurfaceValue;
            obj.View.handles.colormapName.Value = obj.Settings.Volume.colormapName;
            obj.View.handles.colormapInvert.Value = obj.Settings.Volume.colormapInvert;
            obj.View.handles.noFramesEditField.Value = obj.Settings.Animation.noFrames;
            obj.View.handles.colormapBlackPoint.Value = obj.Settings.Volume.colormapBlackPoint;
            obj.View.handles.colormapWhitePoint.Value = obj.Settings.Volume.colormapWhitePoint;
            
            % update lights
            obj.viewer.AmbientLight = obj.Settings.Viewer.AmbientLight;
            obj.viewer.DiffuseLight = obj.Settings.Viewer.DiffuseLight;

            % define rotation mode, in try as it is not documented 
            try
                % 'orbit' - rotation is done around the center of the volume
                % 'cursor' - rotation around the clicked object
                obj.viewer.Mode.Rotate.Style = obj.Settings.Viewer.rotationMode;
            catch err
                obj.View.handles.rotationMode.Items = {'orbit'};
                obj.Settings.Viewer.rotationMode = 'orbit';
            end
            obj.View.handles.rotationMode.Value = obj.Settings.Viewer.rotationMode;

            obj.plotAlphaPlot();
            obj.updateKeyFrameTable();
            obj.View.handles.menuBackgroundGradient.Checked = obj.Settings.Viewer.backgroundGradient;

            obj.childControllers{1}.View.handles.statusText.Text = sprintf('CameraPosition: %.3f x %.3f x %.3f --- CameraUpVector: %.3f x %.3f x %.3f --- CameraTarget: %.3f x %.3f x %.3f --- CameraZoom: %f', ...
                obj.viewer.CameraPosition(1), obj.viewer.CameraPosition(2), obj.viewer.CameraPosition(3), ...
                obj.viewer.CameraUpVector(1), obj.viewer.CameraUpVector(2), obj.viewer.CameraUpVector(3), ...
                obj.viewer.CameraTarget(1), obj.viewer.CameraTarget(2), obj.viewer.CameraTarget(3), ...
                obj.viewer.CameraZoom);

            % update child controllers
            for i=1:numel(obj.childControllers)
                obj.childControllers{i}.updateWidgets()
            end
        end

        function updateKeyFrameTable(obj)
            % function updateKeyFrameTable(obj)
            % update obj.View.handles.keyFrameTable

            if ~isfield(obj.animationPath, 'CameraPosition')
                obj.View.handles.keyFrameTable.Data = [];
                return;
            end
            noFrames = size(obj.animationPath.CameraPosition, 1);
            Data = 1:noFrames;
            obj.View.handles.keyFrameTable.Data = Data;
            obj.View.handles.keyFrameTable.ColumnWidth = repmat({23}, [1, size(Data, 2)]);
            obj.View.handles.keyFrameTable.RowName = 'KeyFrames';
        end

        function addAnimationKeyFrame(obj, posIndex)
            % function addAnimationKeyFrame(obj, posIndex)
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
                obj.animationPath.CameraPosition = [obj.viewer.CameraPosition; obj.animationPath.CameraPosition];
                obj.animationPath.CameraUpVector = [obj.viewer.CameraUpVector; obj.animationPath.CameraUpVector];
                obj.animationPath.CameraTarget = [obj.viewer.CameraTarget; obj.animationPath.CameraTarget];
            elseif posIndex <= size(obj.animationPath.CameraPosition,1)
                obj.animationPath.CameraPosition = [obj.animationPath.CameraPosition(1:posIndex-1, :); obj.viewer.CameraPosition; obj.animationPath.CameraPosition(posIndex:end, :)];
                obj.animationPath.CameraUpVector = [obj.animationPath.CameraUpVector(1:posIndex-1, :); obj.viewer.CameraUpVector; obj.animationPath.CameraUpVector(posIndex:end, :)];
                obj.animationPath.CameraTarget = [obj.animationPath.CameraTarget(1:posIndex-1, :); obj.viewer.CameraTarget; obj.animationPath.CameraTarget(posIndex:end, :)];
            else
                obj.animationPath.CameraPosition(posIndex, :) = obj.viewer.CameraPosition;
                obj.animationPath.CameraUpVector(posIndex, :) = obj.viewer.CameraUpVector;
                obj.animationPath.CameraTarget(posIndex, :) = obj.viewer.CameraTarget;
            end
            obj.updateKeyFrameTable();
        end

        function keyFrameTable_CellSelection(obj, indices)
            % function keyFrameTable_CellSelection(obj, indices)
            % callback for selection of a cell in obj.View.handles.keyFrameTable

            if nargin < 2; indices = obj.keyFrameTableIndex; end

            obj.keyFrameTableIndex = indices;
            if obj.View.handles.autoJumpCheckBox.Value == 1 && ~isempty(indices)
                % update the view
                obj.viewer.CameraPosition = obj.animationPath.CameraPosition(obj.keyFrameTableIndex, :);
                obj.viewer.CameraUpVector = obj.animationPath.CameraUpVector(obj.keyFrameTableIndex, :);
                obj.viewer.CameraTarget = obj.animationPath.CameraTarget(obj.keyFrameTableIndex, :);
            end
        end

        function surfaceTable_CellSelection(obj, indices)
            % function surfaceTable_CellSelection(obj, indices)
            % callback for selection of a cell in obj.View.handles.surfaceTable
            
            if nargin < 2; indices = obj.surfaceTableIndex; end
            try
                obj.surfaceTableIndex = unique(indices(:,1));
            catch err
                err
                return
            end
            
            if numel(obj.surfaceTableIndex) == 1 && indices(2) == 1  % change color
                newColor = uisetcolor(obj.surfList{obj.surfaceTableIndex}.Color, 'Set color');
                obj.surfList{obj.surfaceTableIndex}.Color = newColor;
                obj.updateSurfaceTable();
            end
        end

        
        function modelTable_CellSelection(obj, indices)
            % function modelTable_CellSelection(obj, indices)
            % callback for selection of a cell in obj.View.handles.modelTable
            if nargin < 2; indices = obj.modelTableIndex; end

            obj.modelTableIndex = indices;
        end

        function loadAnimationPath(obj)
            % function loadAnimationPath(obj)
            % load animation path from a file

            mypath = fileparts(obj.animationFilename);
            [filename, path] = mib_uigetfile(...
                {'*.animation;',  'Matlab format (*.animation)'; ...
                '*.*', 'All Files (*.*)'}, ...
                'Load animation...', mypath);
            if isequal(filename, 0); return; end % check for cancel
            obj.animationFilename = fullfile(path, filename{1});

            res = load(obj.animationFilename, '-mat');
            if ~isfield(res, 'animPath')
                uialert(obj.View.gui, ...
                    'Missing the animPath field!', 'Error');
                return;
            end
            obj.animationPath = res.animPath;
            fprintf('The animation was loaded:\n%s\n', obj.animationFilename);
            obj.updateWidgets();
        end

        function saveAnimationPath(obj)
            % function saveAnimationPath(obj)
            % save animation path to a file
            if ~isfield(obj.animationPath, 'CameraPosition')
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nThe animation path is not present!\nPlease use the Animation tab to make it!'), ...
                    'Missing animation');
                return;
            end

            [filename, path, FilterIndex] = uiputfile(...
                {'*.animation',  'Matlab format (*.animation)'; ...
                '*.*',  'All Files (*.*)'}, ...
                'Save animation...', obj.animationFilename);
            if isequal(filename, 0); return; end % check for cancel
            obj.animationFilename = fullfile(path, filename);

            animPath = obj.animationPath;
            save(obj.animationFilename, 'animPath', '-v7.3');
            fprintf('The animation was saved to\n%s\n', obj.animationFilename);
        end


        function deleteAllAnimationKeyFrames(obj)
            % function deleteAllBtn_Callback(obj)
            % delete all key frames

            answer = uiconfirm(obj.View.gui, ...
                sprintf('!!! Warning !!!\nYou are going to remove all key frames!\nContinue?'), ...
                'Delete key frames', 'Options', {'Continue','Cancel'}, ...
                'Icon','warning', 'DefaultOption', 'Cancel');
            if strcmp(answer, 'Cancel'); return; end

            obj.animationPath = struct();
            obj.updateKeyFrameTable();
        end

        function previewAnimation(obj, noFrames)
            % function previewAnimation(obj, noFrames)
            % preview animation

            if nargin < 2; noFrames = obj.Settings.Animation.noFrames; end
            if ~isfield(obj.animationPath, 'CameraPosition'); return; end

            if obj.animationPreviewRunning
                % cancel animation
                obj.animationPreviewRunning = false;
                return;
            end
            obj.animationPreviewRunning = true;
            obj.View.handles.previewAnimationButton.Text = 'Stop animation';
            obj.View.handles.previewAnimationButton.BackgroundColor = 'r';

            positions = obj.generatePositionsForKeyFramesAnimation(noFrames);

            framerate = 24;
            for idx = 1:size(positions.CameraPosition, 1)
                if ~obj.animationPreviewRunning
                    % stop animation
                    obj.View.handles.previewAnimationButton.Text = 'Preview';
                    obj.View.handles.previewAnimationButton.BackgroundColor = [0 1 0];
                    return
                end
                obj.viewer.CameraPosition = positions.CameraPosition(idx, :);
                obj.viewer.CameraUpVector = positions.CameraUpVector(idx, :);
                if ~isempty(positions.CameraTarget)
                    obj.viewer.CameraUpVector = positions.CameraTarget(idx, :);
                end
                %obj.volume.CameraUpVector = myUpVector(idx, :);
                % obj.mibVolRenGUI_VolumeMotionFcn();
                pause(1/framerate);
            end
            obj.View.handles.previewAnimationButton.Text = 'Preview';
            obj.View.handles.previewAnimationButton.BackgroundColor = [0 1 0];
            obj.animationPreviewRunning = false;
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
            if nargin < 2; noFrames = obj.Settings.Animation.noFrames; end
            if ~isfield(obj.animationPath, 'CameraPosition')
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nThe key frames are required for the animation\nAdd key frames by pressing the Add button and repeat!'), ...
                    'Missing key frames');
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
            %obj.viewer.CameraUpVector = positions.CameraUpVector;
            %obj.viewer.CameraTarget = positions.CameraTarget;
        end

        function updateAnimationNumberOfFrames(obj, noFrames)
            % function updateAnimationNumberOfFrames(obj, noFrames)
            % update number of frames in the animation

            obj.Settings.Animation.noFrames = noFrames;
        end

        function modelTable_cm_Callback(obj, event)
            % callback for modelTable context menu
            %
            % Parameters:
            % event: a handle of the pressed button
            % .event.Source.Tag -> 'modelTable_cm_generateSurface', generate surface from the selected material
            switch event.Source.Tag
                case 'modelTable_cm_generateSurface'
                    materialId = obj.modelTableIndex;     % get index of the selected material
                    wb = waitbar(0, sprintf('Generating surfaces\nPlease wait...'));
            
                    for matID = 1:numel(materialId)
                        waitbar(matID/numel(materialId), wb); 
                        matIndex = materialId(matID);
                        mask = (obj.volume.OverlayData == matIndex);  % generate mask from the material
                        surfId = numel(obj.surfList) + 1;
                        obj.surfList{surfId} = images.ui.graphics3d.Surface(obj.viewer, ...
                            'Color', obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(matIndex,:), ...
                            'Data', mask, ...
                            'Transformation', obj.scalingTransform, ...
                            'Visible', true);
                        obj.surfList{surfId}.UserData.Name = cell2mat(obj.View.handles.modelTable.Data(matIndex,2));
                        obj.surfListAlpha(surfId) = 1;
                        obj.surfList{surfId}.Alpha = 1;
                    end
                    obj.updateSurfaceTable();
                    delete(wb);
            end
        end

        function surfaceTable_cm_Callback(obj, event)
            % callback for surfaceTable context menu
            %
            % Parameters:
            % event: a handle of the pressed button
            % .event.Source.Tag -> 'surfaceTable_cm_saveSurface', save surface to a file in STL format
            % .event.Source.Tag -> 'surfaceTable_cm_removeSurface', delete surface from the viewer
            switch event.Source.Tag
                case 'surfaceTable_cm_saveSurface'
                    if isempty(obj.surfaceTableIndex); return; end

                    [path, fnTemplate] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
                    outputFilename = fullfile(path, ...
                        sprintf('Surf_%s.stl', fnTemplate));
                    [filename, path] = uiputfile(...
                        {'*.stl',  'STL format (*.stl)'; ...
                        '*.*',  'All Files (*.*)'}, ...
                        'Set template filename for saving...', outputFilename);
                    if isequal(filename, 0); return; end % check for cancel
                    [~, filenameTemplate, ext] = fileparts(filename);
                    
                    wb = waitbar(0, sprintf('Exporting surface(s)\nPlease wait...'));
                    for surfIndex = 1:numel(obj.surfaceTableIndex)
                        surfId = obj.surfaceTableIndex(surfIndex);
                        waitbar(surfIndex/numel(obj.surfaceTableIndex), wb, sprintf('Exporting %s surface\nPlease wait...', obj.View.handles.surfaceTable.Data{surfId,2}));
                        
                        [fv.faces, fv.vertices] = extractIsosurface(obj.surfList{surfId}.Data, 0.5);
                        outputFilename = fullfile(path, ...
                            sprintf('%s_%s%s', filenameTemplate, obj.View.handles.surfaceTable.Data{surfId,2}, ext));
                        stlwrite(outputFilename, fv, ...
                            'FaceColor',obj.surfList{surfId}.Color*255);
                    end
                    delete(wb);
                case 'surfaceTable_cm_removeSurface'
                    selection = uiconfirm(obj.View.gui, ...
                        sprintf('!!! Warning !!!\n\nYou are going to remove selected surfaces!\nContinue?'), ...
                        'Remove surface(s)',...
                        'Icon','warning');
                    if strcmp(selection, 'Cancel'); return; end
                    wb = waitbar(0, sprintf('Removing surface(s)\nPlease wait...'));
                    obj.viewer.Children(obj.surfaceTableIndex+1).delete();
                    obj.surfList(obj.surfaceTableIndex) = [];
                    obj.surfListAlpha(obj.surfaceTableIndex) = [];
                    obj.surfaceTableIndex = [];
                    if isempty(obj.surfList)
                        obj.View.handles.surfaceTable.Data = [];
                    else
                        obj.updateSurfaceTable();
                    end
                    delete(wb);
            end
        end
        
        
        function keyFrameTable_cm_Callback(obj, event)
            % function keyFrameTable_cm_Callback(obj, event)
            % callback for keyFrameTable context menu
            %
            % Parameters:
            % event: a handle of the pressed button
            % .event.Source.Tag -> 'keyFrameTable_cm_jumpToKeyFrame', jump to the selected key frame and update the view
            % .event.Source.Tag -> 'keyFrameTable_cm_insertKeyFrame', insert a key frame to the current position
            % .event.Source.Tag -> 'keyFrameTable_cm_replaceKeyFrame', replace the selected key frame
            % .event.Source.Tag -> 'keyFrameTable_cm_removeKeyFrame', remove the key frame from the current position;

            switch event.Source.Tag
                case 'keyFrameTable_cm_jumpToKeyFrame'
                    obj.viewer.CameraPosition = obj.animationPath.CameraPosition(obj.keyFrameTableIndex, :);
                    obj.viewer.CameraUpVector = obj.animationPath.CameraUpVector(obj.keyFrameTableIndex, :);
                    obj.viewer.CameraTarget = obj.animationPath.CameraTarget(obj.keyFrameTableIndex, :);
                    return;
                case 'keyFrameTable_cm_insertKeyFrame'
                    if obj.keyFrameTableIndex == 1
                        answer = questdlg(sprintf('Would you like to insert a frame before or after the selected frame index?'), 'Insert frame', 'Before', 'After', 'Cancel', 'Before');
                        if strcmp(answer, 'Cancel'); return; end
                        if strcmp(answer, 'Before'); obj.keyFrameTableIndex = 0; end
                    end
                    obj.addAnimationKeyFrame(obj.keyFrameTableIndex+1);
                    obj.keyFrameTableIndex = [];
                case 'keyFrameTable_cm_replaceKeyFrame'
                    obj.animationPath.CameraPosition(obj.keyFrameTableIndex, :) = obj.viewer.CameraPosition;
                    obj.animationPath.CameraUpVector(obj.keyFrameTableIndex, :) = obj.viewer.CameraUpVector;
                    obj.animationPath.CameraTarget(obj.keyFrameTableIndex, :) = obj.viewer.CameraTarget;
                case 'keyFrameTable_cm_removeKeyFrame'
                    obj.animationPath.CameraPosition(obj.keyFrameTableIndex, :) = [];
                    obj.animationPath.CameraUpVector(obj.keyFrameTableIndex, :) = [];
                    obj.animationPath.CameraTarget(obj.keyFrameTableIndex, :) = [];
                    obj.keyFrameTableIndex = [];
            end
            obj.updateKeyFrameTable();
        end

        function alphaCurveOperations(obj, event)
            % function alphaCurveOperations(obj, event)
            % callback for press of buttons in the alpha curve tab
            %
            % Parameters:
            % event: a handle of the pressed button
            % .event.Source.Tag -> 'resetAlphaCurve'
            % .event.Source.Tag -> 'invertAlphaCurve'

            switch event.Source.Tag
                case 'resetAlphaCurve'      % reset the alpha curve
                    obj.volumeAlphaCurve.x = obj.Settings.Volume.volumeAlphaCurve.x;
                    obj.volumeAlphaCurve.y = obj.Settings.Volume.volumeAlphaCurve.y;
                    %Prefs.VolRen.Volume.volumeAlphaCurve.x = [0 .3 .7 1];
                    %Prefs.VolRen.Volume.volumeAlphaCurve.y = [1 1 0 0];
                case 'invertAlphaCurve'   % invert the alpha curve
                    obj.volumeAlphaCurve.x = 1 - obj.volumeAlphaCurve.x;
                    [obj.volumeAlphaCurve.x, indices] = sort(obj.volumeAlphaCurve.x);
                    obj.volumeAlphaCurve.y = obj.volumeAlphaCurve.y(indices);
            end
            obj.volumeAlphaCurve.activePoint = [];
            obj.recalculateAlphamap();
            obj.plotAlphaPlot();
        end

        function plotAlphaPlot(obj)
            % function plotAlphaPlot(obj)
            % draw alpha plot

            cla(obj.View.handles.alphaAxes);
            hold(obj.View.handles.alphaAxes, 'on');
            obj.alphaPlotHandle{1} = plot(obj.View.handles.alphaAxes, [0 obj.maxIntValue], [0 0], 'Color', [0.5 0.5 0.5]);
            obj.alphaPlotHandle{2} = plot(obj.View.handles.alphaAxes, [0 obj.maxIntValue], [1 1], 'Color', [0.5 0.5 0.5]);

            obj.alphaPlotHandle{3} = plot(obj.View.handles.alphaAxes, obj.volumeAlphaCurve.x*obj.maxIntValue, obj.volumeAlphaCurve.y, '.-', 'Color', [0    0.4470    0.7410]);
            obj.alphaPlotHandle{3}.MarkerSize = obj.Settings.Volume.markerSize;

            if ~isempty(obj.volumeAlphaCurve.activePoint)
                obj.alphaPlotHandle{4} = plot(obj.View.handles.alphaAxes, obj.volumeAlphaCurve.x(obj.volumeAlphaCurve.activePoint)*obj.maxIntValue, obj.volumeAlphaCurve.y(obj.volumeAlphaCurve.activePoint), 'r.');
                obj.alphaPlotHandle{4}.MarkerSize = obj.Settings.Volume.markerSize+2;
            end

            obj.View.handles.alphaAxes.XLim = [0, obj.maxIntValue];
            obj.View.handles.alphaAxes.YLim = [-0.1, 1.1];
            obj.View.handles.alphaAxes.YLabel.String = 'Opacity';
        end

        function toggleViewerSettings(obj, event)
            % function showScaleBar(obj, event)
            % toggle switch on/off for some of the viewer parameters
            %
            % Paramters:
            % event: handle to the pressed widget
            switch event.Source.Tag
                case 'showScaleBar'
                    obj.viewer.ScaleBar = event.Value;
                    obj.Settings.Viewer.showScaleBar = event.Value;
                    obj.viewer.ScaleBarUnits = obj.Settings.Viewer.scaleBarUnits;
                case 'showOrientationAxes'
                    obj.viewer.OrientationAxes = event.Value;
                    obj.Settings.Viewer.showOrientationAxes = event.Value;
                case 'showBox'
                    obj.viewer.Box  = event.Value;
                    obj.Settings.Viewer.showBox = event.Value;
                case 'rotationMode'
                    % update the rotation mode
                    % 'orbit' - rotation is done around the center of the volume
                    % 'cursor' - rotation around the clicked object
                    obj.viewer.Mode.Rotate.Style = event.Value;
                    obj.Settings.Viewer.rotationMode = event.Value;
                case 'AmbientLight'
                    obj.viewer.AmbientLight  = event.Value;
                    obj.Settings.Viewer.AmbientLight = event.Value;
                case 'DiffuseLight'
                    obj.viewer.DiffuseLight  = event.Value;
                    obj.Settings.Viewer.DiffuseLight = event.Value;
            end
        end


        function updateScalingTransform(obj, pixSize)
            % function updateScalingTransform(obj, pixSize)
            % generate tform (obj.scalingTransform) to scale the dataset upon loading to have its
            % units in um

            % Parameters:
            % pixSize: a standard MIB structure with pixels size
            % .x - pixel size in X after rescaling of the imported volume
            % .y - pixel size in Y after rescaling of the imported volume
            % .z - pixel size in Z after rescaling of the imported volume

            Sx = pixSize.x;   % scaling pixels to um ratio, x-axis
            Sy = pixSize.y;   % scaling pixels to um ratio, y-axis
            Sz = pixSize.z;   % scaling pixels to um ratio, z-axis

            % Create the transformation matrix
            T = [Sx 0 0 0; 0 Sy 0 0; 0 0 Sz 0; 0 0 0 1];

            % Create an affine transform
            % use this transform later during initialization of volumes as:
            % vol = volshow(V, 'Transformation', obj.scalingTransform, parent=obj.viewer);
            obj.scalingTransform = affinetform3d(T);
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
                width = obj.childControllers{1}.View.handles.volumeViewerPanel.Position(3);
            end
            if isempty(height)
                height = obj.childControllers{1}.View.handles.volumeViewerPanel.Position(4);
            end
            if options.resizeWindow == 1; obj.prepareWindowForGrabFrame(width, height); end

            panelPosition = obj.childControllers{1}.View.handles.volumeViewerPanel.Position;
            panelPosition(1) = panelPosition(1)-1;
            panelPosition(2) = panelPosition(2)-1;
            panelPosition(3) = width;
            panelPosition(4) = height;
            I = getframe(obj.childControllers{1}.View.gui, panelPosition);

            imgOut = I.cdata;
            % imclipboard('copy', I.cdata);

            % restore the widget sizes
            if options.resizeWindow == 1; obj.restoreWindowAfterGrabFrame(); end

            if deleteWaitbar; delete(options.hWaitbar); end
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

            % store current positions
            obj.figPosStored.mibVolRenAppFigure = obj.childControllers{1}.View.gui.Position;
            obj.figPosStored.mainGridLayoutRowHeights = obj.childControllers{1}.View.handles.mainGridLayout.RowHeight;

            % collapse elements of the grid
            obj.childControllers{1}.View.handles.mainGridLayout.RowHeight = [{'1x'}, {0}];

            obj.childControllers{1}.View.gui.Position(1) = 1;
            obj.childControllers{1}.View.gui.Position(2) = 1;
            obj.childControllers{1}.View.gui.Position(3) = width+obj.childControllers{1}.View.handles.mainGridLayout.Padding(1)+obj.childControllers{1}.View.handles.mainGridLayout.Padding(3)+1;
            obj.childControllers{1}.View.gui.Position(4) = height+obj.childControllers{1}.View.handles.mainGridLayout.Padding(2)+obj.childControllers{1}.View.handles.mainGridLayout.Padding(4)+1;
            % hide menu
            %obj.childControllers{1}.View.handles.FileMenu.Visible = 'off';
            % hide toolbar
            obj.viewer.Toolbar = 'off';

            drawnow;
            pause(.5);
        end

        function restoreWindowAfterGrabFrame(obj)
            % function restoreWindowAfterGrabFrame(obj)
            % restore widget sizes after the snapshot

            % restore positions of the widgets
            obj.childControllers{1}.View.gui.Position = obj.figPosStored.mibVolRenAppFigure;
            obj.childControllers{1}.View.handles.mainGridLayout.RowHeight = obj.figPosStored.mainGridLayoutRowHeights;

            % show menu
            %obj.View.handles.FileMenu.Visible = 'on';
            % restore toolbar
            obj.viewer.Toolbar = 'on';
            
            obj.figPosStored.mibVolRenAppFigure = [];
            obj.figPosStored.mainGridLayoutRowHeights = [];
        end

        function makeAnimation(obj, mode)
            % function makeAnimation(obj, mode)
            % start making movie window
            %
            % Parameters
            % mode: a string with the desired animation type,
            %   'spin' - to spin around selected axis
            %   'animation' - to animate the scene using key frames

            options.mode = mode;    % mode for movie make
            obj.startController('mibMakeMovieController', obj, options);
        end


        function status = grabVolume(obj, volumeType, colorChannel)
            % function status = grabVolume(obj, volumeType, colorChannel)
            % grab the currently displayed volume to the 3D volume viewer
            %
            % Parameters:
            % volumeType: [@em default: 'image'] string with type of the volume to grab: 'image','model', 'selection', 'mask'
            % colorChannel: [@em default: 1] index of the color channel or material to grab
            % Return values:
            % status: 1 - success, 0 - cancel

            global mibPath;
            status = 0;

            if nargin < 3; colorChannel = 0; end
            if nargin < 2; volumeType = 'image'; end

            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('model', 4);

            if strcmp(volumeType, 'image')
                colorChannelList = arrayfun(@(x) sprintf('ColCh %d', x), 1:obj.mibModel.I{obj.mibModel.Id}.colors, 'UniformOutput', false);
                colorChannelList = [{'Selected'}, {'All'}, colorChannelList];
            elseif strcmp(volumeType, 'model')
                colorChannelList = [{'All materials'}, obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames'];
            else
                colorChannelList = {'Selected'};
                colorChannel = 0;
            end
            
            prompts = {sprintf('Would you like to downsample the volume?\nVolume dimensions: %d x %d x %d\n\nDownsample factor (times):', width, height, depth); sprintf('or\nnew width in pixels:'); 'Select color channel:'};
            defAns = {num2str(obj.volumeScaleFactor); num2str(width); [colorChannelList, colorChannel+1]};
            dlgTitle = 'Color channel and downsample';
            options.PromptLines = [5, 2, 1];
            options.Title = 'Select color channel (or material) to render and possibly downsample the dataset to improve performance';
            options.TitleLines = 2;
            options.WindowWidth = 1.2;
            options.Columns = 1;
            options.Focus = 1;
            options.LastItemColumns = 1;
            options.okBtnText = 'Continue';
            [answer, selIndices] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); obj.closeWindow(); return; end

            if strcmp(volumeType, 'image')
                colorChannel = selIndices(3) - 2; % Selected, All, ColCh1, ColCh2...
            else
                colorChannel = selIndices(3) - 1; % All materials, mat1, mat2...
            end
              
            if str2double(answer{1}) == 1
                obj.volumeScaleFactor = round(str2double(answer{2})/width, 3);
            else
                obj.volumeScaleFactor = round(1/str2double(answer{1}), 3);
            end

            wb = waitbar(0, 'Please wait...', 'Name', 'Import volume');
            timePnt = obj.mibModel.I{obj.mibModel.Id}.getCurrentTimePoint();
            pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;

            img = obj.mibModel.getData3D(volumeType, timePnt, 4, max([0, colorChannel]));

            if numel(img) > 1
                msgbox(sprintf('Error!\nPlease select a ROI to render!'),'Error!','error');
                return;
            end
            img = cell2mat(img);

            % keep only selected color channels
            if colorChannel == -1 % selected
                img = img(:,:,obj.mibModel.I{obj.mibModel.Id}.slices{3},:);
            end

            % resize the volume
            if obj.volumeScaleFactor ~= 1
                img = mibResize3d(img,  obj.volumeScaleFactor);

                pixSize.x = pixSize.x/obj.volumeScaleFactor;
                pixSize.y = pixSize.y/obj.volumeScaleFactor;
                pixSize.z = pixSize.z/obj.volumeScaleFactor;
            end

            if strcmp(volumeType, 'image')
                % permute image to show it as RGB
                % requires [h,w,d,c] format
                [imgH, imgW, imgC, imgD] = size(img);
                % add one extra slice for single images
                if imgD < 2; img = repmat(img, [1 1 1 2]); imgD = 2; end
    
                if colorChannel == 0 && size(img,3) == 2    % add extra channel
                    img = permute(img, [1 2 4 3]);
                    img(:,:,:,3) = zeros([imgH, imgW, imgD, 1], class(img(1)));
                    imgC = 3;
                elseif colorChannel <= 0 && size(img,3) > 1
                    img = permute(img, [1 2 4 3]);
                end
            else    % mask/model
                % permute image to show it as RGB
                % requires [h,w,d,c] format
                [imgH, imgW, imgD] = size(img);
                % add one extra slice for single images
                if imgD < 2; img = repmat(img, [1 1 2]); imgD = 2; end
    
                img = permute(img, [1 2 4 3]);
                obj.View.handles.rendererDropDown.Value = 'Isosurface';
            end

            % generate tform to scale the dataset upon loading to have its units in um
            % to update obj.scalingTransform variable
            obj.updateScalingTransform(pixSize);

            % set the volume to obj.viewer
            if isempty(obj.volume)
                obj.volume = volshow(squeeze(img), ...
                   'Transformation', obj.scalingTransform, ...
                   'RenderingStyle', obj.View.handles.rendererDropDown.Value, ...
                   'Parent', obj.viewer);
            else
                obj.volume.Data = squeeze(img);
            end

            obj.volume.IsosurfaceValue = obj.Settings.Volume.isosurfaceValue;
            obj.volume.GradientOpacityValue = obj.Settings.Volume.gradientOpacityValue;

            % store default camera position
            %obj.defaultView.CameraPosition = [pixSize.x*imgW pixSize.y*imgH, pixSize.z*imgD]; %obj.viewer.CameraPosition = [pixSize.x*imgW pixSize.y*imgH, pixSize.z*imgD];
            %obj.defaultView.CameraPosition = obj.viewer.CameraPosition;
            %obj.defaultView.CameraTarget = [pixSize.x*imgW/2 pixSize.y*imgH/2, pixSize.z*imgD/2]; % obj.viewer.CameraTarget;
            %obj.defaultView.CameraUpVector = [0 0 1];%obj.viewer.CameraUpVector;
            %obj.defaultView.CameraZoom = 1; % obj.viewer.CameraZoom;

            % update the scaling factor
            %obj.viewer.CameraPosition = obj.viewer.CameraPosition.*obj.volumeScaleFactor;

            obj.maxIntValue = obj.mibModel.I{obj.mibModel.Id}.meta('MaxInt');
            obj.View.handles.isovalueSlider.Value = obj.Settings.Volume.isosurfaceValue;
            obj.View.handles.isovalueEdit.Value = obj.Settings.Volume.isosurfaceValue;
            obj.recalculateAlphamap();
            
            % update settings for the slice sliders and editboxes
            % the sliders needs to be visible, i.e. if Isosurface is on,
            % the sliders are hidden and cannot be set
            obj.View.handles.xSlider.Limits = [1 imgW];
            obj.View.handles.xSlider.Value = double(obj.volume.SlicePlaneValues(1,4));
            obj.View.handles.xSlider.MinorTicks = linspace(1,imgW, 9);
            obj.View.handles.xSliderEdit.Limits = [1 imgW];
            obj.View.handles.xSliderEdit.Value = double(obj.volume.SlicePlaneValues(1,4));
            
            obj.View.handles.ySlider.Limits = [1 imgH];
            obj.View.handles.ySlider.Value = double(obj.volume.SlicePlaneValues(2,4));
            obj.View.handles.ySlider.MinorTicks = linspace(1,imgH, 9);
            obj.View.handles.ySliderEdit.Limits = [1 imgH];
            obj.View.handles.ySliderEdit.Value = double(obj.volume.SlicePlaneValues(2,4));
            
            obj.View.handles.zSlider.Limits = [1 imgD];
            obj.View.handles.zSlider.Value = double(obj.volume.SlicePlaneValues(3,4));
            obj.View.handles.zSlider.MinorTicks = linspace(1,imgD, 9);
            obj.View.handles.zSliderEdit.Limits = [1 imgD];
            obj.View.handles.zSliderEdit.Value = double(obj.volume.SlicePlaneValues(3,4));
            
            % update widgets to take care about Isosurface mode
            if strcmp(obj.View.handles.rendererDropDown.Value, 'Isosurface')
                obj.updateVolumeRenderingStyle();
            end

            %             % check overlay
            %             noMaterials = numel(obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames);
            %             img = obj.mibModel.getData3D('model', timePnt, 4);
            %             % resize the volume
            %             if obj.volumeScaleFactor ~= 1
            %                 rescaleOpt.imgType = '3D';
            %                 rescaleOpt.method = 'nearest';
            %                 img{1} = mibResize3d(img{1},  obj.volumeScaleFactor, rescaleOpt);
            %             end
            %             obj.volume.OverlayData = img{1};
            %
            %             obj.volume.OverlayAlphamap = [0 1 1 1 1];
            %             %obj.volume.OverlayAlphamap = 0;
            %             obj.volume.OverlayColormap = [0, 0, 0; obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(1:noMaterials,:)];
            %             obj.volume.OverlayThreshold = .001;
            %
            %             mask1 = (img{1} == 1);
            %             surf1 = images.ui.graphics3d.Surface(obj.viewer, 'Color', obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(1,:), 'Data', mask1, ...
            %                 'Transformation', obj.scalingTransform);
            %             surf1.Alpha = 1;

            %obj.visualizationModePopup_Callback();
            status = 1;
            delete(wb);
        end

        function recalculateAlphamap(obj, transparentVolume)
            % function recalculateAlphamap(obj, transparentVolume)
            % recalculate obj.volume.Alphamap
            %
            % Parameters:
            % transparentVolume: [@em default false] when true, make the volume transparent

            if nargin < 2; transparentVolume = false; end
            if transparentVolume
                obj.volume.Alphamap = 0;
            else
                queryPoints = linspace(0, obj.maxIntValue, 256);
                obj.volumeAlphaCurve.alphamap = interp1(obj.volumeAlphaCurve.x*obj.maxIntValue, ...
                    obj.volumeAlphaCurve.y, queryPoints)';
                if ~isempty(obj.volume)
                    obj.volume.Alphamap = obj.volumeAlphaCurve.alphamap;
                end
                obj.View.handles.showVolumeCheckBox.Value = true;   % check 'show volume'
            end
        end

        function spinDataset(obj)
            % function spinDataset(obj)
            % spin dataset (rotate camera around the dataset)

            % CameraPosition:   the position of the camera itself
            % CameraTarget:     the camera's look-at point
            % CameraUpVector:   the roll angle (rotation) of the camera
            %                   around it's view axis, defines which axis is up: [0, 0, 1] indicates Z-axis is up
            
            if obj.animationPreviewRunning
                % cancel animation
                obj.animationPreviewRunning = false;
                return;
            end

            options.clockwise = 1;
            options.back_and_forth = 0;

            positions = obj.generatePositionsForSpinAnimation(120, options);
            framerate = 24;

            obj.animationPreviewRunning = true;
            obj.View.handles.spinTestButton.Text = 'Stop spin';
            obj.View.handles.spinTestButton.BackgroundColor = [1 0 0];

            obj.viewer.CameraUpVector = positions.CameraUpVector;
            obj.viewer.CameraTarget = positions.CameraTarget;

            for idx = 1:size(positions.CameraPosition,1)
                if ~obj.animationPreviewRunning
                    % stop spin
                    obj.View.handles.spinTestButton.Text = 'Spin test';
                    obj.View.handles.spinTestButton.BackgroundColor = [0 1 0];
                    return;
                end
                obj.viewer.CameraPosition = positions.CameraPosition(idx, :);
                %obj.volume.CameraUpVector = myUpVector(idx, :);
                %obj.mibVolRenGUI_VolumeMotionFcn();
                pause(1/framerate);
            end
            obj.View.handles.spinTestButton.Text = 'Spin test';
            obj.View.handles.spinTestButton.BackgroundColor = [0 1 0];
            obj.animationPreviewRunning = false;
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
            if ~isfield(options, 'rotAxis'); options.rotAxis = obj.View.handles.spinAxis.Value; end

            positions.CameraTarget = obj.viewer.CameraTarget;

            % obtain current position
            currX = obj.viewer.CameraPosition(1) - obj.viewer.CameraTarget(1);
            currY = obj.viewer.CameraPosition(2) - obj.viewer.CameraTarget(2);
            currZ = obj.viewer.CameraPosition(3) - obj.viewer.CameraTarget(3);

            switch obj.View.handles.spinAxis.Value
                case 'X-axis'  % around x-axis
                    positions.CameraUpVector = [-1 0 0];
                    %positions.CameraUpVector = obj.viewer.CameraUpVector;

                    if currZ>=0 && currY>=0
                        currAngle = atan(currZ/currY)+pi();  % calculate the angle
                    else
                        currAngle = atan(currZ/currY);  % calculate the angle
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
                    positions.CameraPosition = [zeros(size(vec))+currX+obj.viewer.CameraTarget(1) ...
                        cos(vec)*radius+obj.viewer.CameraTarget(2) ...
                        sin(vec)*radius+obj.viewer.CameraTarget(3)];

                case 'Y-axis'  % around y-axis
                    positions.CameraUpVector = [0 1 0];

                    if currZ>=0 && currX>=0
                        currAngle = atan(currZ/currX)+pi();  % calculate the angle
                    else
                        currAngle = atan(currZ/currX);  % calculate the angle
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
                    positions.CameraPosition = [cos(vec)*radius+obj.viewer.CameraTarget(1) ...
                        zeros(size(vec))+currY+obj.viewer.CameraTarget(2) ...
                        sin(vec)*radius+obj.viewer.CameraTarget(3)];
                case 'Z-axis'  % around z-axis
                    positions.CameraUpVector = [0 0 1];

                    if currY>=0 && currX>=0
                        currAngle = atan(currY/currX);  % calculate the angle
                    else
                        currAngle = atan(currY/currX)+pi();  % calculate the angle
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

                    positions.CameraPosition = [ cos(vec)*radius+obj.viewer.CameraTarget(1) ...
                        sin(vec)*radius+obj.viewer.CameraTarget(2) ...
                        zeros(size(vec))+currZ+obj.viewer.CameraTarget(3)];
            end
        end

        function makeSnapshop(obj)
            % function makeSnapshop(obj)
            % make snapshot
            obj.startController('mibSnapshotController', obj);
        end

        function modelUpdateOverlay(obj, overlayType, materialId)
            % grab the model from MIB and assign it as an overlay for the
            % volume
            %
            % Parameters:
            % overlayType: string, type of the overlay to show,
            %    @li 'model' - the model layer
            %    @li 'mask' - the mask layer
            %    @li 'selection' - the selection layer
            % materialId: index of material of the model, use NaN to get all materials

            if nargin < 3; materialId = NaN; end    % get all materials
            if nargin < 2; overlayType = obj.View.handles.overlaySourceDropDown.Value; end    % get all materials

            existStatus = obj.mibModel.I{obj.mibModel.Id}.enableSelection;
            obj.noOverlayMaterials = 1;
            switch overlayType
                case 'model'
                    % get number of materials
                    obj.noOverlayMaterials = numel(obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames);
                    existStatus = obj.mibModel.I{obj.mibModel.Id}.modelExist;
                    overlayColormap = [0, 0, 0; obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(1:obj.noOverlayMaterials,:)];
                case 'mask'
                    existStatus = obj.mibModel.I{obj.mibModel.Id}.maskExist;
                    overlayColormap = [0, 0, 0; obj.mibModel.preferences.Colors.MaskColor];
                case 'selection'
                    overlayColormap = [0, 0, 0; obj.mibModel.preferences.Colors.SelectionColor];
            end
            if existStatus == 0
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nThe %s is not present in MIB!', overlayType), 'Missing model');
                return;
            end

            overlay = cell2mat(obj.mibModel.getData3D(overlayType, NaN, 4, materialId));
            % resize the volume
            if obj.volumeScaleFactor ~= 1
                rescaleOpt.imgType = '3D';
                rescaleOpt.method = 'nearest';
                overlay = mibResize3d(overlay,  obj.volumeScaleFactor, rescaleOpt);
            end
            [imgH, imgW, imgD] = size(overlay);
            % add one extra slice for single images
            if imgD < 2; overlay = repmat(overlay, [1 1 2]); end

            % update volume
            obj.volume.OverlayData = overlay;
            
            % https://se.mathworks.com/help/releases/R2024b/images/ref/images.ui.graphics.image-properties.html?searchHighlight=OverlayDisplayRange&s_tid=doc_srchtitle#mw_1bf93e21-15d7-4716-93b7-d0b98195db15
            % a new property at least in R2024b which should be set to
            % 'data-range' or 'manual' with obj.volume.OverlayDisplayRange = [0 numberOfmaterials]
            if isprop(obj.volume, 'OverlayDisplayRangeMode') 
                if obj.mibModel.matlabVersion <= 24.1
                    obj.volume.OverlayDisplayRangeMode = 'manual';
                    obj.volume.OverlayDisplayRange = [0 obj.noOverlayMaterials];
                else
                    obj.volume.OverlayDisplayRangeMode = 'data-range'; 
                end
            end
            
            obj.volume.OverlayAlphamap = [0 ones([1, obj.noOverlayMaterials])];
            obj.volume.OverlayColormap = overlayColormap;
            obj.volume.OverlayThreshold = 0.0001;
            
            % update rendering style
            if obj.matlabVersion >= 23.2 % R2023b
                obj.volume.OverlayRenderingStyle = obj.View.handles.overlayRenderingStyle.Value; % LabelOverlay, VolumeOverlay, GradientOverlay
            end

            obj.overlayShownMaterials = logical(ones([obj.noOverlayMaterials, 1]));
            obj.updateModelTable(); % update table with materials
        end

        function updateOverlayRenderingStyle(obj)
            % function updateOverlayRenderingStyle()
            % update rendering style for overlays

            if obj.matlabVersion >= 23.2 % R2023b
                obj.volume.OverlayRenderingStyle = obj.View.handles.overlayRenderingStyle.Value; % LabelOverlay, VolumeOverlay, GradientOverlay
            end
        end

        function updateSurfaceTable(obj)
            % update obj.View.handles.surfaceTable
            noSurfaces = numel(obj.surfList);
            data = cell([noSurfaces, 5]);
            materialNames = cellfun(@(x) x.UserData.Name, obj.surfList, 'UniformOutput', false)';
            surfaceShown = cellfun(@(x) strcmp(x.Visible, 'on'), obj.surfList)';
            surfaceColors = cellfun(@(x) x.Color, obj.surfList, 'UniformOutput', false)';
            wireframeShown = cellfun(@(x) strcmp(x.Wireframe, 'on'), obj.surfList)';
            data(:,2) = materialNames;
            data(:,3) = num2cell(obj.surfListAlpha');
            data(:,4) = num2cell(surfaceShown);
            data(:,5) = num2cell(wireframeShown);
            
            obj.View.handles.surfaceTable.Data = data;

            % Update colors for the table
            % define color styles
            origColors = [1 1 1; 0.94 0.94 0.94];
            bgColorsList = cell2mat(surfaceColors);
            obj.View.handles.surfaceTable.BackgroundColor = bgColorsList;
            removeStyle(obj.View.handles.surfaceTable);    % remove current styles
            s1 = uistyle;
            s1.BackgroundColor = origColors(1, :);
            addStyle(obj.View.handles.surfaceTable, s1, 'column', 2:5);
            
            % set current object to volume to make sure that orthoslices
            % are interactive
            obj.viewer.CurrentObject = obj.viewer.Children(1);
        end
        
        function modelHideAllMaterials(obj, hideMaterialsSwitch)
            % function modelHideAllMaterials(obj, hideMaterialsSwitch)
            % hide all materials of the shown model
            %
            % Parameters:
            % value: [logical, optional], switch to hide (true) or show materials (false)
            if nargin < 2; hideMaterialsSwitch = obj.View.handles.modelHideAllCheckBox.Value; end

            if hideMaterialsSwitch
                obj.volume.OverlayAlphamap = zeros([1, obj.noOverlayMaterials+1])';
            else
                overlapAlphaMap = obj.overlayAlpha;
                overlapAlphaMap(~obj.overlayShownMaterials) = 0;
                obj.volume.OverlayAlphamap = [0; overlapAlphaMap];
            end
            %obj.overlayShownMaterials = logical(ones([obj.noOverlayMaterials, 1]));
            %obj.updateModelTable(); % update table with materials
            
        end


        function updateModelTable(obj)
            % update obj.View.handles.modelTable
            % after loading of the model
            data = cell([obj.noOverlayMaterials, 4]);
            switch obj.View.handles.overlaySourceDropDown.Value
                case 'model'
                    data(:,2) = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames;
                    bgColorsList = obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(1:obj.noOverlayMaterials, :);
                case 'selection'
                    data(1,2) = {'selection'};
                    bgColorsList = obj.mibModel.preferences.Colors.SelectionColor;
                case 'mask'
                    data(1,2) = {'mask'};
                    bgColorsList = obj.mibModel.preferences.Colors.MaskColor;
            end
            % alpha values for the overlay
            obj.overlayAlpha = ones([obj.noOverlayMaterials, 1]);
            data(:,3) = num2cell(obj.overlayAlpha);
            data(:,4) = num2cell(obj.overlayShownMaterials);
            obj.View.handles.modelTable.Data = data;

            % Update colors for the table
            % define color styles
            origColors = [1 1 1; 0.94 0.94 0.94];
            obj.View.handles.modelTable.BackgroundColor = bgColorsList;
            removeStyle(obj.View.handles.modelTable);    % remove current styles
            s1 = uistyle;
            s1.BackgroundColor = origColors(1, :);
            addStyle(obj.View.handles.modelTable, s1, 'column', 2:4);
        end

        function surfaceTableCellEdit(obj, event)
            % callback for update of values in obj.View.handles.modelTable
            indices = event.Indices;
            newData = event.NewData;
            surfaceId = indices(1);
            if indices(2) == 3  % update transparency
                if ~isnumeric(newData) || newData<0 || newData > 1
                    obj.View.handles.surfaceTable.Data(surfaceId, 3) = {event.PreviousData};
                    uialert(obj.View.gui, ...
                        sprintf('!!! Error !!!\n\nAlpha value describes transparency\n(0-transparent, 1-opaque) for the surface!\n\nPlease make sure the Alpha value between 0 and 1'), 'Wrong Alpha');
                    return;
                end
                obj.surfList{surfaceId}.Alpha = newData;
            elseif indices(2) == 4  % show / hide surface
                if newData == 0     % hide surface
                    obj.surfList{surfaceId}.Visible = false;
                else                % show surface
                    obj.surfList{surfaceId}.Visible = true;
                end
            elseif indices(2) == 5  % show / hide wireframe
                if newData == 0     % hide wireframe
                    obj.surfList{surfaceId}.Wireframe = false;
                else                % show wireframe
                    obj.surfList{surfaceId}.Wireframe = true;
                end
            elseif indices(2) == 2  % change name
                obj.surfList{surfaceId}.UserData.Name = newData;
            end
        end

        function modelTableCellEdit(obj, event)
            % callback for update of values in obj.View.handles.modelTable
            indices = event.Indices;
            newData = event.NewData;
            materialId = indices(1);

            if indices(2) == 3  % update transparency
                if ~isnumeric(newData) || newData<0 || newData > 1
                    obj.View.handles.modelTable.Data(materialId, 3) = {event.PreviousData};
                    uialert(obj.View.gui, ...
                        sprintf('!!! Error !!!\n\nAlpha value describes transparency\n(0-transparent, 1-opaque) for the material!\n\nPlease make sure the Alpha value between 0 and 1'), 'Wrong Alpha');
                    return;
                end
                obj.overlayAlpha(materialId) = newData;
                obj.volume.OverlayAlphamap(materialId+1) = newData;     % obj.volume.OverlayAlphamap(1) -> background
            elseif indices(2) == 4  % show / hide material
                if obj.View.handles.modelHideAllCheckBox.Value % deal with the Hide All button
                    obj.View.handles.modelHideAllCheckBox.Value = false;
                    obj.modelHideAllMaterials(false);
                end
                if newData == 0     % hide material
                    obj.volume.OverlayAlphamap(materialId+1) = 0;
                    obj.overlayShownMaterials(materialId) = false;
                else                % show material

                    obj.volume.OverlayAlphamap(materialId+1) = obj.overlayAlpha(materialId);
                    obj.overlayShownMaterials(materialId) = true;
                end
            end
        end

        function updateCameraPosition(obj, event)
            if ~isvalid(obj.viewer); return; end % skip when the viewer is closed
            
            switch event.Source.Tag
                case 'cameraDistanceEdit'
                    % change camera distance
                    newDistance = event.Source.Value;
                    prevDistance = event.PreviousValue;
                    ratio = newDistance/prevDistance;
                    obj.viewer.CameraPosition = obj.viewer.CameraTarget + (obj.viewer.CameraPosition-obj.viewer.CameraTarget)*ratio;
                case 'cameraZoomEdit'
                    obj.viewer.CameraZoom = event.Source.Value;
                case 'cameraPositionX'
                    obj.viewer.CameraPosition(1) = event.Source.Value;
                case 'cameraPositionY'
                    obj.viewer.CameraPosition(2) = event.Source.Value;
                case 'cameraPositionZ'
                    obj.viewer.CameraPosition(3) = event.Source.Value;
                case 'cameraTargetX'
                    obj.viewer.CameraTarget(1) = event.Source.Value;
                case 'cameraTargetY'
                    obj.viewer.CameraTarget(2) = event.Source.Value;
                case 'cameraTargetZ'
                    obj.viewer.CameraTarget(3) = event.Source.Value;
                case 'cameraUpVectorX'
                    obj.viewer.CameraUpVector(1) = event.Source.Value;
                case 'cameraUpVectorY'
                    obj.viewer.CameraUpVector(2) = event.Source.Value;
                case 'cameraUpVectorZ'
                    obj.viewer.CameraUpVector(3) = event.Source.Value;
            end
        end

        function changeSlice(obj, sourceWidget, value)
            % callback for change of the slice value on
            % obj.View.handles.xSliderEdit / ySliderEdit / zSliderEdit
            %
            % Parameters:
            % sourceWidget: tag (str) of the widgets that was modified,
            % 'xSliderEdit', 'ySliderEdit', 'zSliderEdit'
            % value: new value

            if nargin == 3; obj.View.handles.(sourceWidget).Value = value;  end

            switch sourceWidget
                case 'xSliderEdit'
                    obj.View.handles.xSlider.Value = obj.View.handles.(sourceWidget).Value;
                    obj.volume.SlicePlaneValues(1,4) = obj.View.handles.(sourceWidget).Value;
                case 'ySliderEdit'
                    obj.View.handles.ySlider.Value = obj.View.handles.(sourceWidget).Value;
                    obj.volume.SlicePlaneValues(2,4) = obj.View.handles.(sourceWidget).Value;
                case 'zSliderEdit'
                    obj.View.handles.zSlider.Value = obj.View.handles.(sourceWidget).Value;
                    obj.volume.SlicePlaneValues(3,4) = obj.View.handles.(sourceWidget).Value;
            end
        end

        function showVolume(obj, showSwitch)
            % toggle showing of the volume
            if nargin < 2; showSwitch = obj.View.handles.showVolumeCheckBox.Value; end

            if showSwitch
                obj.volume.Visible = 'on';
            else
                obj.volume.Visible = 'off';
            end
        end

        function transparentVolume(obj, transparentSwitch)
            % make volume transparent, which still shows the overlay model
            if nargin < 2; transparentSwitch = obj.View.handles.transparentVolumeCheckBox.Value; end

            if transparentSwitch
                transparentVolume = true;
                obj.recalculateAlphamap(transparentVolume);
            else
                transparentVolume = false;
                obj.recalculateAlphamap(transparentVolume);
            end
        end

        function showHelp(obj)
            % show help

            global mibPath;
            web(fullfile(mibPath, 'techdoc/html/user-interface/menu/file/file-mib3Dviewer.html'), '-browser');
        end

    end
end