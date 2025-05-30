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

classdef mibView < handle
    % classdef mibView < handle
    % the main view class of MIB
    
    properties
        gui
        % handle to the main gui
        mibModel
        % handles to the model
        mibController
        % handles to the controller
        handles
        % list of handles for the gui
        guiPositions
        % structure with default positions of some GUIs to be used for rescaling
        brushPrevXY
        % coordinates of the previous pixel for the @em Brush tool,
        % @note dimensions: [x, y] or NaN
        brushSelection
        % selection layer during the brush tool movement, @code {1:2}[1:height,1:width] or NaN @endcode
        % brushSelection{1} 
        %   .selection - contains brush selection during drawing
        %   .travelPathInPixels - distance of brush travelled during painting
        % brushSelection{2} - contains labels of the supervoxels and some additional information
        %   .slic - a label image with superpixels
        %   .selectedSlic - a bitmap image of the selected with the Brush tool superpixels 
        %   .selectedSlicIndices - indices of the selected Slic superpixels
        %   .selectedSlicIndicesNew - a list of freshly selected Slic indices when moving the brush, used for the undo with Ctrl+Z
        %   .CData - a copy of the shown in the imageAxes image, to be used for the undo
        % brushSelection{3} - a structure that contains information for
        % the adaptive mode:
        %   .meanVals - array of mean intensity values for each superpixels
        %   .mean - mean intensity value for the initial selection
        %   .std - standard deviation of intensities for the initial selection
        %   .factor - factor that defines variation of STD variation
        % @note the 'brushSelection' is modified with respect to @code magFactor @endcode and crop of the image within the viewing window
        centerSpotHandle
        % a handle to ROI point class that marks the center of the image axes
        % .handle - a handle to the spot roi class
        % .enable - a switch, 1-enable; 0-disable
        altPressed
        % set a variable to store slice number where mouse scroll action was triggered
        % obj.altPressed = 0; - indicates that Alt was not preseed
        % obj.altPressed > 0; - indicates slice number when Alt was preseed
        ctrlPressed
        % set a variable to deal with the increase of the brush size during the erasing action. Ctrl+left mouse button
        % obj.ctrlPressed:
        % obj.ctrlPressed == 0; - indicates the normal brush mode, i.e. when the control button is not pressed
        % obj.ctrlPressed > 0; - the control button is pressed and handles.ctrlPressed indicates increase of the brush radius
        % obj.ctrlPressed == -1; - a tweak to deal with Ctrl+Mouse wheel action to change size of the brush. -1 indicates that the brush size change mode was triggered
        % see in functions:
        %    mibGUI_WindowKeyPressFcn, mibGUI_WindowKeyReleaseFcn, mibGUI_ScrollWheelFcn        
        cursor
        % a handle to the cursor gui object
        imh
        % handle for the currently shown image; should be obj.imh = matlab.graphics.primitive.Image('CData', []); when no image
        Iraw
        % a property to keep the currently displayed image in RAW format,
        % used only in the virtual stacking mode to see pixel intensities
        % under the cursor
        % @note 'Iraw' dimensions: @code [1:height, 1:width, 1:colors] @endcode
        Ishown
        % a property to keep the currently displayed image in RGB format
        % @note 'Ishown' dimensions: @code [1:height, 1:width, 1:colors] @endcode
        showBrushCursor
        % a switch (0, 1) to define whether or not show the brush cursor
        trackerYXZ
        % starting point for the Membrane Click-tracer tool
    end
    
    events

    end
    
    methods
        % Convert coordinates under the mouse cursor to the coordinates of the dataset
        status = editbox_Callback(obj, hObject, chtype, default_val, variation)        % Check for entered values in an edit box and switch the focus to mib.View.handles.updatefilelistBtn
        
        [xData, yData, zData, xClick, yClick] = getClickPoint(obj, nTimes, permuteSw)        % a function that gets ginput function to pick a point within handles.mibImageAxes 
        
        roiSwitch = getRoiSwitch(obj)        % get status of the mibGUI.handles.toolbarShowROISwitch
        
        volrenModeSwitch = getVolrenModeSwitch(obj)        % get status of the mibGUI.handles.volrenToolbarSwitch

        setVolrenModeSwitch(obj, volrenModeSwitch)        % set status of the mibGUI.handles.volrenToolbarSwitch
        
        updateCursor(obj, mode)        % Update brush cursor

        
        function obj = mibView(controller)
            % obj = mibView(controller)
            % mibView class constructor
            %
            % Constructor for the mibView class. Create a new instance of
            % the class with default parameters
            %
            % Parameters:
            % controller: handle to mibController class
            
            
            obj.mibController = controller;
            obj.mibModel = controller.mibModel;
            obj.gui = mibGUI(obj.mibController);    % initialize gui
            
            % extract handles to widgets of the main GUI
            figHandles = findobj(obj.gui);
            for i=1:numel(figHandles)
                if ~isempty(figHandles(i).Tag)  % some context menu comes without Tags
                    obj.handles.(figHandles(i).Tag) = figHandles(i);
                end
            end
            
            title = ['Microscopy Image Browser ' obj.mibController.mibVersion];
            if isdeployed; title = [title ' deployed version'];  end
            title = [title '    level ' obj.mibModel.preferences.Users.tierLevelRanks{min(obj.mibModel.preferences.Users.Tiers.tierLevel, numel(obj.mibModel.preferences.Users.tierLevelRanks))}];
            obj.gui.Name = title;

            obj.brushPrevXY = NaN;
            obj.brushSelection = NaN;
            obj.trackerYXZ = [NaN;NaN;NaN];
            
            obj.imh = matlab.graphics.primitive.Image('CData', []);   
            obj.ctrlPressed = 0;   % status of the Ctrl key (unpressed)
            obj.altPressed = 0; % status ofthe Alt key (unpressed)
            
            obj.centerSpotHandle.handle = [];
            obj.centerSpotHandle.enable = 0;
            
            obj.showBrushCursor = 1;
            
%             % add listners
%             for i=1:obj.mibModel.maxId
%                addlistener(obj.mibModel.I{i}, 'slices', 'PostSet', @(src,evnt) mibView.Listner_Callback(obj,src,evnt));
%             end
        end
    end
    
    methods (Static)
        function Listner_Callback(obj, src, evnt)
%            evntobj = evnt.AffectedObject;
%            handles = guidata(obj.gui);
            switch src.Name
                case 'slices'
                    %obj.subWin.handles.meanIntensityText.String = num2str(evntobj.meanVal);
%                 case 'volume'
%                     set(handles.volume, 'String', evntobj.volume);
            end
        end
    end
    
    methods
        
        
%         function openAuxWindow(obj)
%             %obj.subWin.h = auxWindow(obj.Img);
%             obj.subWin.h = auxWindow(obj.mibController);
%             % get handles of the widgets in the auxWindow
%             figHandles = findobj(obj.subWin.h);
%             for i=1:numel(figHandles)
%                 obj.subWin.handles.(figHandles(i).Tag) = figHandles(i);
%             end
%            
%             % set callbacks to the functions
%             obj.subWin.handles.minValueEdit.Callback = {@auxWindowSlider_Callback, obj};
%             obj.subWin.handles.maxValueEdit.Callback = {@auxWindowSlider_Callback, obj};
%         end
    end
end