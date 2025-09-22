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

classdef mibImageSelectFrameController < handle
    % @type mibImageSelectFrameController class is responsible for selection of pixels at the borders of images 
    % available from MIB->Menu->Image->Tools for images->Select borders... 
    
	% Copyright (C) 19.06.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
        BatchOpt
        % a structure compatible with batch operation, see details in the contsructor
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
    end
    
    methods
        function obj = mibImageSelectFrameController(mibModel, varargin)
            global mibPath;
            
            obj.mibModel = mibModel;    % assign model
            
            obj.BatchOpt.DatasetType{1} = '3D, Stack';
            obj.BatchOpt.DatasetType{2} = {'2D, Slice', '3D, Stack', '4D, Dataset'};
            obj.BatchOpt.ColorChannel = {'ColCh 1'};         % specify the color channel
            obj.BatchOpt.ColorChannel{2} = arrayfun(@(x) sprintf('ColCh %d', x), 1:obj.mibModel.I{obj.mibModel.Id}.colors, 'UniformOutput', false);
            obj.BatchOpt.Connectivity{1} = 'connection4';
            obj.BatchOpt.Connectivity{2} = {'connection4', 'connection8'}; % Radio
            obj.BatchOpt.FrameIntensity = '0';
            obj.BatchOpt.NewFrameIntensity = '0';
            obj.BatchOpt.MinimalObjectSize = '0';
            obj.BatchOpt.Destination{1} = 'Selection';
            obj.BatchOpt.Destination{2} = {'Selection', 'Mask', 'Image'};
            obj.BatchOpt.Destination{2} = {'Selection', 'Mask', 'Image'};
            obj.BatchOpt.showWaitbar = true; % show or not the progress bar

            % add section name and action name for the batch tool
            obj.BatchOpt.mibBatchSectionName = 'Menu -> Image';
            obj.BatchOpt.mibBatchActionName = 'Tools for Images -> Select Image Frame';
            
            obj.BatchOpt.mibBatchTooltip.DatasetType = 'Define type of the dataset for detection of the frame';
            obj.BatchOpt.mibBatchTooltip.ColorChannel = 'Select a color channel to use';
            obj.BatchOpt.mibBatchTooltip.Connectivity = 'Define connectivity parameter for detection of objects';
            obj.BatchOpt.mibBatchTooltip.FrameIntensity = 'Intensity of the image frame to be detected';
            obj.BatchOpt.mibBatchTooltip.NewFrameIntensity = 'New intensity value for for the detected frame';
            obj.BatchOpt.mibBatchTooltip.MinimalObjectSize = 'Apply threshold for object detection; objects below this value will not be detected';
            obj.BatchOpt.mibBatchTooltip.Destination = 'Destination layer for results';
            obj.BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not a progress bar');

            % add here a code for the batch mode, for example
            % when the BatchOpt stucture is provided the controller will
            % use it as the parameters, and performs the function in the
            % headless mode without GUI
            if nargin == 3
                BatchOptInput = varargin{2};
                if isstruct(BatchOptInput) == 0 
                    if isnan(BatchOptInput)
                        obj.returnBatchOpt();   % obtain Batch parameters
                    else
                        errordlg(sprintf('A structure as the 3rd parameter is required!')); 
                    end
                    return;
                end
                
                % combine fields from input and default structures
                obj.BatchOpt = updateBatchOptCombineFields_Shared(obj.BatchOpt, BatchOptInput);
                useBatchMode = 1;
                obj.continueBtn_Callback(useBatchMode);
                return;
            end
            
            guiName = 'mibImageSelectFrameGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % check for the virtual stacking mode and close the controller
            if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                toolname = 'frame detection tool is';
                warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode\nplease switch to the memory-resident mode and try again', ...
                    toolname), 'Not implemented');
                obj.closeWindow();
                return;
            end
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            Font = obj.mibModel.preferences.System.Font;
            if obj.View.handles.infoText.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.infoText.FontName, Font.FontName)
                mibUpdateFontSize(obj.View.gui, Font);
            end
            
            % load demo image
            obj.View.handles.previewAxes.Color = 'none';
            [img, ~, transparency] = imread(fullfile(mibPath, 'Resources', 'image_border_detection.png'));
            obj.View.handles.previewAxes.Position(2) = 15;
            obj.View.handles.previewAxes.Position(3) = size(img, 2);
            obj.View.handles.previewAxes.Position(4) = size(img, 1);
            image(img, 'parent', obj.View.handles.previewAxes, 'AlphaData', double(transparency)/255);
            obj.View.handles.previewAxes.Box = 'off';
            obj.View.handles.previewAxes.XTick = [];
            obj.View.handles.previewAxes.YTick = [];
            obj.View.handles.previewAxes.XColor = 'none';
            obj.View.handles.previewAxes.YColor = 'none';
            obj.View.handles.previewAxes.Color = 'none';
            
            infoText = 'This tool allows selection of borders at the edge of the dataset';
            obj.View.handles.infoText.String = infoText;
            
            obj.updateWidgets();
			
			% add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function returnBatchOpt(obj, BatchOptOut)
            % return structure with Batch Options and possible configurations
            % via the notify 'syncBatch' event
            % Parameters:
            % BatchOptOut: a local structure with Batch Options generated
            % during Continue callback. It may contain more fields than
            % obj.BatchOpt structure
            % 
            if nargin < 2; BatchOptOut = obj.BatchOpt; end
            
            % trigger syncBatch event to send BatchOptOut to mibBatchController 
            eventdata = ToggleEventData(BatchOptOut);
            notify(obj.mibModel, 'syncBatch', eventdata);
        end
        
        function updateBatchOptFromGUI(obj, hObject)
            % function updateBatchOptFromGUI(obj, hObject)
            %
            % update obj.BatchOpt from widgets of GUI
            % use an external function (Tools\updateBatchOptFromGUI_Shared.m) that is common for all tools
            % compatible with the Batch mode
            %
            % Parameters:
            % hObject: a handle to a widget of GUI
            
            obj.BatchOpt = updateBatchOptFromGUI_Shared(obj.BatchOpt, hObject);
        end
        
        function closeWindow(obj)
            % closing mibImageSelectFrameController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete childController window
            end
            
            % delete listeners, otherwise they stay after deleting of the
            % controller
            for i=1:numel(obj.listener)
                delete(obj.listener{i});
            end
            
            notify(obj, 'closeEvent');      % notify mibController that this child window is closed
        end
        
        function updateWidgets(obj)
            % function updateWidgets(obj)
            % update widgets of this window
            
            % update widgets from the BatchOpt structure
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);
        end
        
        function helpBtn_Callback(obj)
            global mibPath;
            web(fullfile(mibPath, 'techdoc/html/user-interface/menu/image/image-tools-selectframe.html'), '-browser');
        end
        
        function continueBtn_Callback(obj, useBatchMode)
            % function continueBtn_Callback(obj, useBatchMode)
            % callback for press of obj.View.handles.continueBtn
            % perform the selected morph ops
            
            if obj.BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'Frame selection'); end
            datasetType = obj.BatchOpt.DatasetType{1};
            % color channel to use for detection of the frame
            colCh = find(ismember(obj.BatchOpt.ColorChannel{2}, obj.BatchOpt.ColorChannel{1}));
            % object connectivity parameter
            connectivity = str2double(obj.BatchOpt.Connectivity{1}(end));
            % get the destination: selection, mask, image
            destination = lower(obj.BatchOpt.Destination{1});
            frameIntensity = str2double(obj.BatchOpt.FrameIntensity);
            newFrameIntensity = str2double(obj.BatchOpt.NewFrameIntensity);
            objectThreshold = str2double(obj.BatchOpt.MinimalObjectSize);
            
            getDataOptions.blockModeSwitch = 0;
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, NaN, getDataOptions);
            
            % backup current data
            switch datasetType
                case '2D, Slice'
                    obj.mibModel.mibDoBackup(destination, 0);
                    t1 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
                    t2 = t1;
                    startSlice = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
                    endSlice = startSlice;
                    maxIndex = 1;
                case '3D, Stack'
                    obj.mibModel.mibDoBackup(destination, 1);
                    t1 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
                    t2 = t1;
                    startSlice = 1;
                    endSlice = depth;
                    maxIndex = obj.mibModel.I{obj.mibModel.Id}.depth;
                case '4D, Dataset'
                    t1 = 1;
                    t2 = obj.mibModel.I{obj.mibModel.Id}.time;
                    startSlice = 1;
                    endSlice = depth;
                    maxIndex = depth * obj.mibModel.I{obj.mibModel.Id}.time;
            end
            
            tic
            index = 0;
            for t=t1:t2
                getDataOptions.t = [t t];
                for z = startSlice:endSlice
                    I = cell2mat(obj.mibModel.getData2D('image', z, NaN, colCh, getDataOptions));
                    
                    M = zeros(size(I), 'uint8');
                    M(I == frameIntensity) = 1;
                    
                    CC = bwconncomp(M, connectivity);  %    detect objects
                    STATS = regionprops(CC, 'PixelList', 'Area');   % calc their properties
                    
                    % find areas larger than the threshold value
                    vec = arrayfun(@(x) x.Area > objectThreshold, STATS);
                    % keep only the areas that are larger than the threhold value
                    CC.PixelIdxList = CC.PixelIdxList(vec);
                    CC.NumObjects = sum(vec);
                    STATS = STATS(vec);
                    
                    % find border elements
                    vec1 = arrayfun(@(x) isempty(find(x.PixelList == 1, 1)), STATS);
                    vec2 = arrayfun(@(x) isempty(find(x.PixelList(:,2) == height, 1)), STATS);
                    vec3 = arrayfun(@(x) isempty(find(x.PixelList(:,1) == width, 1)), STATS);
                    vec = unique([find(vec1 == 0); find(vec2 == 0); find(vec3 == 0)]);
                    
                    % generate a new mask layer
                    if strcmp(destination, 'image')
                        I(cat(1, CC.PixelIdxList{vec})) = newFrameIntensity;
                        obj.mibModel.setData2D(destination, I, z, NaN, colCh, getDataOptions);
                    else
                        M = zeros(size(I), 'uint8');
                        M(cat(1, CC.PixelIdxList{vec})) = 1;    
                        obj.mibModel.setData2D(destination, M, z, NaN, NaN, getDataOptions);
                    end
                    if obj.BatchOpt.showWaitbar && mod(z, 10) == 0; waitbar(index/maxIndex,wb); end
                    index = index + 1;
                end
            end
            toc
            
            % update log
            if strcmp(destination, 'image')
                log_text = ['ImageFrame: ColCh=', num2str(colCh), ', orient=' num2str(obj.mibModel.I{obj.mibModel.Id}.orientation),...
                    ', NewCol=' num2str(newFrameIntensity)];
                if obj.View.handles.DatasetType.Value == 1
                    log_text = [log_text, sprintf(',2D,Z=%d,T=%d', startSlice, t1)];
                elseif obj.View.handles.DatasetType.Value == 2
                    log_text = [log_text sprintf(',3D,T=%d', t1)];
                else
                    log_text = [log_text ',4D'];
                end
                obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(log_text);
            elseif strcmp(destination, 'mask')
                obj.mibModel.mibMaskShowCheck = 1;   
            end
            if obj.BatchOpt.showWaitbar
                waitbar(1,wb);
                delete(wb);
            end
            notify(obj.mibModel, 'plotImage');
        end
    end
end