classdef mibHistThresController < handle
    % @type mibHistThresController class is resposnible for showing the Morphological operations for images 
    % window, available from MIB->Menu->Tools->Semi-automatic segmentation->Automatic black-and-white thresholding
    %
    % How to use 
    % @code
    % // batch mode call, names of the fields can be seen in the alt-text of the widgets!
    % // see the class constructor for the full contents of the BatchOpt structure
    % BatchOpt.ColorChannel = {'Ch 1'};    // color channel for thresholding
    % BatchOpt.Mode = {'3D, Stack'};     // mode to use
    % BatchOpt.Method = {'Otsu'};       // thresholding algorithm
    % %BatchOpt.t = [1 1];     // time points, [t1, t2]
    % BatchOpt.z = [10 20];    // slices, [z1, z2]
    % BatchOpt.x = [10 120];    // slices, [z1, z2]
    % BatchOpt.Orientation = 2;     // dataset orientation
    % obj.startController('mibHistThresController', [], BatchOpt); // provide BatchOpt as the 3rd parameter into the startController function of mibController class
    % @endcode
    % @code
    % obj.startController('mibHistThresController');    // standard call for GUI
    % @endcode
    % or
    % @code
    % // trigger return of the possible Options using returnBatchOpt function
    % // using notify syncBatch event
    % obj.startController('mibHistThresController', [], NaN);
    % @endcode
    
	% Copyright (C) 04.02.2019, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
        BatchOpt
        % a structure compatible with batch operation, see more in the
        % constructor
        % .showWaitbar - logical, true - show, false - do not show the waitbar
        % .ColorChannel - cell string 'Ch 1' or 'Ch 2'... the color channel for thresholding
        
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
                case 'changeSlice'
                    if obj.View.handles.autoPreviewCheck.Value == 1
                        obj.previewBtn_Callback();
                    end
            end
        end
    end
    
    methods
        function obj = mibHistThresController(mibModel, varargin)
            global mibPath;
            obj.mibModel = mibModel;    % assign model
    
            % fill the BatchOpt structure with default values
            obj.BatchOpt.id = obj.mibModel.Id;  % optional
            
            obj.BatchOpt.Method = {'Concavity'};      % type of the algorithm for calculations
            obj.BatchOpt.Method{2} = {'Concavity','Entropy','InterMeans iter','InterModes',...
                'Mean','Median','MinError','MinError iter','Minimum','Moments','Otsu','Percentile'};
            obj.BatchOpt.Mode = {'2D, Slice'};     % '2D, Slice', '3D, Stack', '4D, Dataset'
            obj.BatchOpt.Mode{2} = {'2D, Slice','3D, Stack','4D, Dataset'};
            obj.BatchOpt.ColorChannel = {'Ch 1'};    % color channel for thresholding
            colChList = arrayfun(@(x) sprintf('Ch %d', x), 1:obj.mibModel.I{obj.BatchOpt.id}.colors, 'UniformOutput', false);
            % add second field to popupmenus with all possible options
            obj.BatchOpt.ColorChannel{2} = colChList;
            obj.BatchOpt.Destination = {'selection'};     % destination layer: 'selection', 'mask'
            obj.BatchOpt.Destination{2} = {'selection','mask'};
            obj.BatchOpt.ForegroundFraction = '0.5';  % fraction of foreground pixels
            obj.BatchOpt.Orientation = 4;   % yx
            obj.BatchOpt.showWaitbar = true;   % show or not the waitbar
            % the following parameters are required for the batch mode, but not needed for the gui-tool
            % @li .Orientation, 1-zx, 2-zy, 4-yx of the dataset
            % @li .z -> [@em optional], [zmin, zmax] coordinates of the dataset to take after transpose, depth
            % @li .t -> [@em optional], [tmin, tmax] coordinates of the dataset to take after transpose, time
            % @li .y -> [@em optional], [ymin, ymax] coordinates of the dataset to take after transpose for level=1, height
            % @li .x -> [@em optional], [xmin, xmax] coordinates of the dataset to take after transpose for level=1, width
            
            obj.BatchOpt.mibBatchSectionName = 'Menu -> Tools';
            obj.BatchOpt.mibBatchActionName = 'Semi-automatic segmentation --> Global thresholding';
            
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.ColorChannel = sprintf('Color channel to be used for thresholding');
            obj.BatchOpt.mibBatchTooltip.Mode = sprintf('Apply thresholding for the current slice (2D), current stack (3D) or the whole dataset(4D)');
            obj.BatchOpt.mibBatchTooltip.Method = sprintf('Selection of available methods for thresholding');
            obj.BatchOpt.mibBatchTooltip.ForegroundFraction = sprintf('[Percentile only]:\nFraction of foreground pixels');
            obj.BatchOpt.mibBatchTooltip.Destination = sprintf('Assign thresholding results to the Mask or Selection layer of MIB');
            obj.BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

            % add here a code for the batch mode, for example
            if nargin == 3
                BatchOptInput = varargin{2};
                if isstruct(BatchOptInput) == 0 
                    if isnan(BatchOptInput)
                        obj.returnBatchOpt();   % obtain Batch parameters
                    else
                        errordlg(sprintf('A structure as the 4th parameter is required!')); 
                    end
                    return
                end
                BatchOptInputFields = fieldnames(BatchOptInput);
                for i=1:numel(BatchOptInputFields)
                    obj.BatchOpt.(BatchOptInputFields{i}) = BatchOptInput.(BatchOptInputFields{i}); 
                end
            
                obj.continueBtn_Callback();
                return;
            end
            
            guiName = 'mibHistThresGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % check for the virtual stacking mode and close the controller
            if obj.mibModel.I{obj.BatchOpt.id}.Virtual.virtual == 1
                toolname = 'morphological operations are';
                warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode\nplease switch to the memory-resident mode and try again', ...
                    toolname), 'Not implemented');
                obj.closeWindow();
                notify(obj.mibModel, 'stopProtocol');
                return;
            end
            
            % update GUI widgets using the provided BatchOpt
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);
            
            % load preview image
            img = imread(fullfile(mibPath, 'Resources', 'automatic_thresholding.png'));
            obj.View.handles.previewAxes.Units = 'pixel';
            obj.View.handles.previewAxes.Position(3) = 211;
            obj.View.handles.previewAxes.Position(4) = 113;
            image(img, 'parent', obj.View.handles.previewAxes);
            obj.View.handles.previewAxes.Box = 'off';
            obj.View.handles.previewAxes.XTick = [];
            obj.View.handles.previewAxes.YTick = [];
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            Font = obj.mibModel.preferences.Font;
            if obj.View.handles.infoText.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.infoText.FontName, Font.FontName)
                mibUpdateFontSize(obj.View.gui, Font);
            end
            
            obj.updateWidgets();
			
			% add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            obj.listener{2} = addlistener(obj.mibModel, 'changeSlice', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing mibHistThresController window
            if ~isempty(obj.View)
                if isvalid(obj.View.gui)
                    delete(obj.View.gui);   % delete childController window
                end
                
                % delete listeners, otherwise they stay after deleting of the
                % controller
                for i=1:numel(obj.listener)
                    delete(obj.listener{i});
                end    
            end
            
            notify(obj, 'closeEvent');      % notify mibController that this child window is closed
        end
        
        function updateWidgets(obj)
            % function updateWidgets(obj)
            % update widgets of this window
            
            % updating color channels
            obj.BatchOpt.ColorChannel{2} = arrayfun(@(x) sprintf('Ch %d', x), 1:obj.mibModel.I{obj.BatchOpt.id}.colors, 'UniformOutput', false);
            obj.BatchOpt.ColorChannel{1} = obj.BatchOpt.ColorChannel{2}{max([1 obj.mibModel.I{obj.BatchOpt.id}.selectedColorChannel])};
            obj.BatchOpt.id = obj.mibModel.Id;
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);    % update widgets from BatchOpt
            obj.Method_Callback();
        end
        
        function Method_Callback(obj)
            % function Method_Callback(obj)
            % callback for change of obj.View.handles.Method
            
            list = obj.View.handles.Method.String;
            currOperationName = list(obj.View.handles.Method.Value);
            
            obj.View.handles.foregroundSlider.Enable = 'off';
            obj.View.handles.ForegroundFraction.Enable = 'off';
            
            obj.BatchOpt.Method(1) = currOperationName;
            switch obj.BatchOpt.Method{1}
                case 'Concavity'
                    infoText = 'Concavity: for images that do not have distinct objects and background';
                case 'Entropy'
                    infoText = 'Entropy: divides the histogram of the image into two probability distributions, one representing the objects and one representing the background';
                case 'InterMeans iter'
                    infoText = 'InterMeans iter: find a global threshold for a grayscale image using the iterative intermeans method';
                case 'InterModes'
                    infoText = 'InterModes: assumes a bimodal histogram. Unsuitable for images that have a histogram with extremely unequal peaks or a broad and flat valley';
                case 'MaxLik'
                    infoText = 'MaxLik: take an expectation maximization approach for ?tting mixtures of distributions';
                case 'Mean'
                    infoText = 'Mean: does not take into account histogram shape';
                case 'Median'
                    infoText = 'Median: assumes that the percentage of object pixels is known';
                case 'MinError'
                    infoText = 'MinError: views the histogram as an estimate of the probability density function of the mixture population';
                case 'MinError iter'
                    infoText = 'MinError iter: find a global threshold for a grayscale image using the iterative minimum error thresholding method.';
                case 'Minimum'
                    infoText = 'Minimum: assumes a bimodal histogram. Unsuitable for images that have a histogram with extremely unequal peaks or a broad and ?at valley';
                case 'Moments'
                    infoText = 'Moment-preserving thresholding';
                case 'Otsu'
                    infoText = 'Otsu: position the threshold the midway between the means of the two classes';
                case 'Percentile'
                    obj.View.handles.foregroundSlider.Enable = 'on';
                    obj.View.handles.ForegroundFraction.Enable = 'on';
                    infoText = 'Percentile: assumes that the percentage of object pixels is known';
            end
            obj.View.handles.infoText.String = infoText;
            
            % use auto preview
            if obj.View.handles.autoPreviewCheck.Value == 1
                obj.previewBtn_Callback();
            end
        end
       
       
        function previewBtn_Callback(obj)
            % function previewBtn_Callback(obj)
            % callback for press of obj.View.handles.previewBtn

            colChId = find(ismember(obj.BatchOpt.ColorChannel{2}, obj.BatchOpt.ColorChannel{1})==1);
            getDataOptions.id = obj.BatchOpt.id;
            img = cell2mat(obj.mibModel.getData2D('image', NaN, NaN, colChId, getDataOptions)); %#ok<FNDSB>
            maxInt = obj.mibModel.I{obj.BatchOpt.id}.meta('MaxInt');
            
            if maxInt > 255 && ~strcmp(obj.BatchOpt.Method{1}, 'Otsu')    % convert image to 8bit, otherwise the thresholding is too slow
                img = uint8(double(img)/double(max(img(:)))*255);
            end
            
            switch obj.BatchOpt.Method{1}
                case 'Concavity'
                    th = th_concavity(img);
                case 'Entropy'
                    th = th_entropy(img);
                case 'InterMeans iter'
                    th = th_intermeans_iter(img);
                case 'InterModes'
                    th = th_intermodes(img);
                case 'MaxLik'
                    th = th_maxlik(img);
                case 'Mean'
                    th = th_mean(img);
                case 'Median'
                    th = th_median(img);
                case 'MinError'
                    th = th_minerror(img);
                case 'MinError iter'
                    th = th_minerror_iter(img);
                case 'Minimum'
                    th = th_minimum(img);
                case 'Moments'
                    th = th_moments(img);
                case 'Otsu'
                    th = graythresh(img);
                    th = th*maxInt;
                case 'Percentile'
                    foregroundFraction = 1-str2double(obj.BatchOpt.ForegroundFraction);
                    th = th_ptile(img, foregroundFraction);
            end
            imgOut = zeros(size(img), 'uint8');
            imgOut(img>th) = 1;
            
            obj.mibModel.setData2D('selection', imgOut, NaN, NaN, colChId, getDataOptions);
            notify(obj.mibModel, 'plotImage');
            
            %eventdata = ToggleEventData(imgOut);   % send image to show in  mibView.handles.mibImageAxes as ToggleEventData class
            %notify(obj.mibModel, 'plotImage', eventdata);
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
            
            if isfield(BatchOptOut, 'id'); BatchOptOut = rmfield(BatchOptOut, 'id'); end  % remove id field
            
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
            
            if obj.View.handles.autoPreviewCheck.Value == 1
                obj.previewBtn_Callback();
            end
        end
        
        
        function continueBtn_Callback(obj)
            % perform thresholding
            if obj.BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', [obj.BatchOpt.Method{1} ' thresholding']); end
            
            BatchOptLoc = obj.BatchOpt;
            tic
            colChId = find(ismember(BatchOptLoc.ColorChannel{2}, BatchOptLoc.ColorChannel{1})==1);
            
            switch obj.BatchOpt.Mode{1}
                case '2D, Slice'
                    if ~isfield(obj.BatchOpt, 't')
                        BatchOptLoc.t(1) = obj.mibModel.I{BatchOptLoc.id}.slices{5}(1);
                        BatchOptLoc.t(2) = BatchOptLoc.t(1);
                    end
                    if ~isfield(obj.BatchOpt, 'z')
                        BatchOptLoc.z(1) = obj.mibModel.I{BatchOptLoc.id}.getCurrentSliceNumber();
                        BatchOptLoc.z(2) = BatchOptLoc.z(1);
                    end
                    obj.mibModel.mibDoBackup(BatchOptLoc.Destination{1}, 0, BatchOptLoc);   % backup current data
                case '3D, Stack'
                    if ~isfield(obj.BatchOpt, 't')
                        BatchOptLoc.t(1) = obj.mibModel.I{BatchOptLoc.id}.slices{5}(1);
                        BatchOptLoc.t(2) = BatchOptLoc.t(1);
                    end
                    if ~isfield(obj.BatchOpt, 'z')
                        BatchOptLoc.z(1) = 1;
                        BatchOptLoc.z(2) = obj.mibModel.I{BatchOptLoc.id}.dim_yxczt(BatchOptLoc.Orientation);
                    end
                    obj.mibModel.mibDoBackup(BatchOptLoc.Destination{1}, 1, BatchOptLoc);   % backup current data
                case '4D, Dataset'
                    if ~isfield(obj.BatchOpt, 't')
                        BatchOptLoc.t(1) = 1;
                        BatchOptLoc.t(2) = obj.mibModel.I{BatchOptLoc.id}.time;
                    end
                    if ~isfield(obj.BatchOpt, 'z')
                        BatchOptLoc.z(1) = 1;
                        BatchOptLoc.z(2) = obj.mibModel.I{BatchOptLoc.id}.dim_yxczt(BatchOptLoc.Orientation);
                    end
                    if BatchOptLoc.t(1)==BatchOptLoc.t(2); obj.mibModel.mibDoBackup(BatchOptLoc.Destination{1}, 1); end    % backup current data 
            end
            maxIndex = (diff(BatchOptLoc.z)+1) * (diff(BatchOptLoc.t)+1);
            maxInt = obj.mibModel.I{BatchOptLoc.id}.meta('MaxInt');
            
            if isfield(BatchOptLoc, 'x'); getDataOptions.x = BatchOptLoc.x; end
            if isfield(BatchOptLoc, 'y'); getDataOptions.y = BatchOptLoc.y; end
            
            fgFraction = str2double(BatchOptLoc.ForegroundFraction);
            index = 0;
            getDataOptions.id = BatchOptLoc.id;
            for t=BatchOptLoc.t(1):BatchOptLoc.t(2)
                getDataOptions.t = [t t];
                for sliceId = BatchOptLoc.z(1):BatchOptLoc.z(2)
                    img = cell2mat(obj.mibModel.getData2D('image', sliceId, BatchOptLoc.Orientation, colChId, getDataOptions)); %#ok<FNDSB>
                    
                    if maxInt > 255 && ~strcmp(obj.BatchOpt.Method{1}, 'Otsu')    % convert image to 8bit, otherwise the thresholding is too slow
                        img = uint8(double(img)/double(max(img(:)))*255);
                    end
                    
                    switch obj.BatchOpt.Method{1}
                        case 'Concavity'
                            th = th_concavity(img);
                        case 'Entropy'
                            th = th_entropy(img);
                        case 'InterMeans iter'
                            th = th_intermeans_iter(img);
                        case 'InterModes'
                            th = th_intermodes(img);
                        case 'MaxLik'
                            th = th_maxlik(img);
                        case 'Mean'
                            th = th_mean(img);
                        case 'Median'
                            th = th_median(img);
                        case 'MinError'
                            th = th_minerror(img);
                        case 'MinError iter'
                            th = th_minerror_iter(img);
                        case 'Minimum'
                            th = th_minimum(img);
                        case 'Moments'
                            th = th_moments(img);
                        case 'Otsu'
                            th = graythresh(img);
                            th = th*maxInt;
                        case 'Percentile'
                            foregroundFraction = 1-fgFraction;
                            th = th_ptile(img, foregroundFraction);
                    end
                    imgOut = zeros(size(img), 'uint8');
                    imgOut(img>th) = 1;
                    
                    obj.mibModel.setData2D(obj.BatchOpt.Destination{1}, imgOut, sliceId, BatchOptLoc.Orientation, NaN, getDataOptions);
                    if obj.BatchOpt.showWaitbar; waitbar(index/maxIndex,wb); end
                    index = index + 1;
                end
            end
            if obj.BatchOpt.showWaitbar
                waitbar(1,wb);
                delete(wb);
            end
            toc
            
            if strcmp(obj.BatchOpt.Destination{1}, 'mask'); obj.mibModel.mibMaskShowCheck = 1; end     % display the mask layer
            notify(obj.mibModel, 'plotImage');
            
            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            obj.returnBatchOpt(BatchOptLoc);
            
        end
    end
end