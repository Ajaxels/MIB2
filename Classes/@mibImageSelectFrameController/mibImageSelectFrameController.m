classdef mibImageSelectFrameController < handle
    % @type mibImageSelectFrameController class is resposnible for selection of pixels at the borders of images 
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
        mode
        % morphops mode: mode2d_Slice, mode2d_Stack, mode2d_Dataset, mode3d_Stack, mode3d_Dataset
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
        function obj = mibImageSelectFrameController(mibModel, parameter)
            global mibPath;
            
            obj.mibModel = mibModel;    % assign model
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
            Font = obj.mibModel.preferences.Font;
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
            
            % updating color channels
            colorsNo = obj.mibModel.getImageProperty('colors');
            colCh = cell([colorsNo, 1]);
            for i=1:colorsNo
                colCh{i} = sprintf('Ch %d', i);
            end
            if colorsNo < obj.View.handles.colorChannelPopoup.Value
                obj.View.handles.colorChannelPopoup.Value = 1;
            end
            obj.View.handles.colorChannelPopoup.String = colCh;
        end
        
        function continueBtn_Callback(obj)
            % function continueBtn_Callback(obj)
            % callback for press of obj.View.handles.continueBtn
            % perform the selected morph ops
            
            wb = waitbar(0, 'Please wait...', 'Name', 'Frame selection');
            % color channel to use for detection of the frame
            colCh = obj.View.handles.colorChannelPopoup.Value;
            % object connectivity parameter
            connectivity = str2double(obj.View.handles.connectivityPanel.SelectedObject.String);
            % get the destination: selection, mask, image
            destination = lower(obj.View.handles.destinationRadioGroup.SelectedObject.String);
            frameIntensity = str2double(obj.View.handles.intensityInEdit.String);
            newFrameIntensity = str2double(obj.View.handles.intensityOutEdit.String);
            objectThreshold = str2double(obj.View.handles.minSizeEdit.String);
            
            getDataOptions.blockModeSwitch = 0;
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, NaN, getDataOptions);
            
            % backup current data
            if obj.View.handles.datasetPopup.Value == 1
                obj.mibModel.mibDoBackup(destination, 0);
                t1 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
                t2 = t1;
                startSlice = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
                endSlice = startSlice;
                maxIndex = 1;
            elseif obj.View.handles.datasetPopup.Value == 2
                obj.mibModel.mibDoBackup(destination, 1);
                t1 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
                t2 = t1;
                startSlice = 1;
                endSlice = depth;
                maxIndex = obj.mibModel.I{obj.mibModel.Id}.depth;
            else
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
                    if mod(z, 10) == 0; waitbar(index/maxIndex,wb); end
                    index = index + 1;
                end
            end
            toc
            
            % update log
            if strcmp(destination, 'image')
                log_text = ['ImageFrame: ColCh=', num2str(colCh), ', orient=' num2str(obj.mibModel.I{obj.mibModel.Id}.orientation),...
                    ', NewCol=' num2str(newFrameIntensity)];
                if obj.View.handles.datasetPopup.Value == 1
                    log_text = [log_text, sprintf(',2D,Z=%d,T=%d', startSlice, t1)];
                elseif obj.View.handles.datasetPopup.Value == 2
                    log_text = [log_text sprintf(',3D,T=%d', t1)];
                else
                    log_text = [log_text ',4D'];
                end
                obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(log_text);
            elseif strcmp(destination, 'mask')
                obj.mibModel.mibMaskShowCheck = 1;   
            end
            waitbar(1,wb);
            notify(obj.mibModel, 'plotImage');
            delete(wb);
        end
    end
end