classdef mibCropController  < handle
    % @type mibCropController class is resposnible for showing the dataset
    % crop window, available from MIB->Menu->Dataset->Crop 
    
	% Copyright (C) 09.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
        roiPos
        % a cell array with position of the ROI for crop
        % obj.roiPos{1} = [1, width, 1, height, 1, depth, 1, time];
        mibImageAxes
        % handle to mibView. mibImageAxes, main image axes of MIB
        currentMode
        % a string with the selected crop mode: 'Interactive','Manual','ROI'
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
                case {'updateGuiWidgets', 'updateROI'}
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibCropController(mibModel, mibImageAxes, varargin)
            obj.mibModel = mibModel;    % assign model
            
            getDataOpt.blockModeSwitch = 0;
            [height, width, ~, depth, time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, NaN, getDataOpt);
            
            % fill BatchOpt structure with default parameters
            % generate cell array of containers names for popup menus
            destBuffers = arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false);
            
            [numberOfROI, indicesOfROI] = obj.mibModel.I{obj.mibModel.Id}.hROI.getNumberOfROI(0);
            ROIlist{1} = 'All';
            i=2;
            for idx = indicesOfROI
                ROIlist(i) = obj.mibModel.I{obj.mibModel.Id}.hROI.Data(idx).label; %#ok<AGROW>
                i = i + 1;
            end
            obj.BatchOpt.Width = sprintf('%d:%d', 1, width);   % width for the crop
            obj.BatchOpt.Height = sprintf('%d:%d', 1, height);   % height for the crop
            obj.BatchOpt.Depth = sprintf('%d:%d', 1, depth);   % depth for the crop
            obj.BatchOpt.Time = sprintf('%d:%d', 1, time);   % time for the crop
            obj.BatchOpt.Interactive = false;
            obj.BatchOpt.ROI = false;
            obj.BatchOpt.Manual = true;     % enable manual mode, when the values for crop are provided
            obj.BatchOpt.Destination = {sprintf('Container %d', obj.mibModel.Id)};  % destination for the crop
            obj.BatchOpt.Destination{2} = destBuffers;
            obj.BatchOpt.SelectROI = {'All'};
            obj.BatchOpt.SelectROI{2} = ROIlist;
            
            % add section name and action name for the batch tool
            obj.BatchOpt.mibBatchSectionName = 'Menu -> Dataset';
            obj.BatchOpt.mibBatchActionName = 'Crop dataset';
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.Width = sprintf('[Manual mode only]\nRange of points for the cropping in X\nFor example, "100:200"');
            obj.BatchOpt.mibBatchTooltip.Height = sprintf('[Manual mode only]\nRange of points for the cropping in Y\nFor example, "100:200"');
            obj.BatchOpt.mibBatchTooltip.Depth = sprintf('[Manual mode only]\nRange of points for the cropping in Z\nFor example, "100:200"');
            obj.BatchOpt.mibBatchTooltip.Time = sprintf('[Manual mode only]\nRange of points for the cropping in T\nFor example, "10:20"');
            obj.BatchOpt.mibBatchTooltip.Interactive = sprintf('The batch mode is not compatible with this mode');
            obj.BatchOpt.mibBatchTooltip.ROI = sprintf('Use ROI for the cropping');
            obj.BatchOpt.mibBatchTooltip.Manual = sprintf('Width, Height, Depth, Time fields to crop the image');
            obj.BatchOpt.mibBatchTooltip.Destination = sprintf('Destination container');
            obj.BatchOpt.mibBatchTooltip.SelectROI = sprintf('[ROI mode only]\nSelected ROI for the cropping');
            
            % add here a code for the batch mode, for example
            % when the BatchOpt stucture is provided the controller will
            % use it as the parameters, and performs the function in the
            % headless mode without GUI
            if nargin == 3
                BatchOptInput = varargin{1};
                if isstruct(BatchOptInput) == 0 
                    if isnan(BatchOptInput)
                        obj.returnBatchOpt();   % obtain Batch parameters
                    else
                        errordlg(sprintf('A structure as the 4th parameter is required!')); 
                    end
                    return;
                end
                
                % combine fields from input and default structures
                obj.BatchOpt = updateBatchOptCombineFields_Shared(obj.BatchOpt, BatchOptInput);
                
                if obj.BatchOpt.Interactive == 1
                    errordlg(sprintf('!!! Error !!!\n\nCrop tool in the batch mode is not compatible with the "Interactive" option!'), 'Crop: initialization error');
                    notify(obj.mibModel, 'stopProtocol');
                end
                
                if isfield(obj.BatchOpt, 'id')
                    errordlg(sprintf('!!! Error !!!\n\nCrop tool is not compatible with the "id" field yet'), 'Crop: initialization error');
                    notify(obj.mibModel, 'stopProtocol');
                end
                
                % check the radio button names
                if obj.BatchOpt.Interactive + obj.BatchOpt.Manual + obj.BatchOpt.ROI > 1
                    errordlg(sprintf('The wrong initialization of radio buttons!\n\nOnly one of the following options should be used:\n.Manual=true (.Width, .Height, .Depth, .Time)\n.ROI=true (.SelectROI)\n.Interactive - not implemented'), 'Crop: initialization error');
                    notify(obj.mibModel, 'stopProtocol');
                    return;
                end
                obj.cropBtn_Callback();
                return;
            end
            
            obj.mibImageAxes = mibImageAxes;
            guiName = 'mibCropGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            obj.currentMode	= 'Manual';
            
			obj.updateWidgets();
			
			% add listner to obj.mibModel and call controller function as a callback
             % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
             obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes updateGuiWidgets
             obj.listener{2} = addlistener(obj.mibModel, 'updateROI', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing mibCropController  window
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
        
        function updateWidgets(obj)
            % function updateWidgets(obj)
            % update all widgets of the current window
            obj.View.handles.Width.String = ['1:' num2str(obj.mibModel.I{obj.mibModel.Id}.width)];
            obj.View.handles.Height.String = ['1:' num2str(obj.mibModel.I{obj.mibModel.Id}.height)];
            obj.View.handles.Depth.String = ['1:' num2str(obj.mibModel.I{obj.mibModel.Id}.depth)];
            obj.View.handles.Time.String = ['1:' num2str(obj.mibModel.I{obj.mibModel.Id}.time)];
            
            obj.roiPos{1} = NaN;
            
            if obj.View.handles.Interactive.Value == 1; obj.currentMode = 'Interactive'; end
            if obj.View.handles.Manual.Value == 1; obj.currentMode = 'Manual'; end
            if obj.View.handles.ROI.Value == 1; obj.currentMode = 'ROI'; end
            
            [numberOfROI, indicesOfROI] = obj.mibModel.I{obj.mibModel.Id}.hROI.getNumberOfROI(0);     % get all ROI
            if numberOfROI == 0
                 obj.View.handles.ROI.Enable = 'off';
                 if obj.BatchOpt.ROI     % disable roi mode when no roi
                    obj.currentMode = 'Manual';
                    obj.BatchOpt.ROI = false;
                    obj.BatchOpt.Manual = true;
                    obj.View.handles.Manual.Value = 1;
                 end
            end
            
            obj.radio_Callback(obj.View.handles.(obj.currentMode));
            
            list{1} = 'All';
            i=2;
            for idx = indicesOfROI
                list(i) = obj.mibModel.I{obj.mibModel.Id}.hROI.Data(idx).label; %#ok<AGROW>
                i = i + 1;
            end
            obj.View.handles.SelectROI.String = list;
            
            if numel(list) > 1
                obj.View.handles.SelectROI.Value = max([obj.mibModel.I{obj.mibModel.Id}.selectedROI+1 2]);
                obj.View.handles.ROI.Enable = 'on';
            else
                obj.View.handles.SelectROI.Value = 1;
            end
        end
        
        function radio_Callback(obj, hObject)
            % function radio_Callback(obj, hObject)
            % callback for selection of crop mode
            %
            % Parameters:
            % hObject: a handle to selected radio button to choose the crop mode
            % @li handles.Interactive - interactive
            % @li handles.Manual - manual
            % @li handles.ROI - from selected ROI
            
            mode = hObject.Tag;
            
            obj.View.handles.SelectROI.Enable = 'off';
            obj.View.handles.Width.Enable = 'off';
            obj.View.handles.Height.Enable = 'off';
            obj.View.handles.Depth.Enable = 'off';
            
            if obj.mibModel.I{obj.mibModel.Id}.time > 1
                obj.View.handles.Time.Enable = 'on';
            else
                obj.View.handles.Time.Enable = 'off';
            end
            if strcmp(mode,'Interactive')
                text = sprintf('Interactive mode allows to draw a rectangle that will be used for cropping.To start, press the Crop button and use the left mouse button to draw an area, double click over the area to crop');
                obj.editboxes_Callback();
            elseif strcmp(mode,'Manual')
                obj.View.handles.Width.Enable = 'on';
                obj.View.handles.Height.Enable = 'on';
                obj.View.handles.Depth.Enable = 'on';
                text = sprintf('In the manual mode the numbers entered in the edit boxes below will be used for cropping');
                obj.editboxes_Callback();
            elseif strcmp(mode,'ROI')
                obj.View.handles.SelectROI.Enable = 'on';
                text = sprintf('Use existing ROIs to crop the image');
                obj.SelectROI_Callback();
            end
            obj.View.handles.descriptionText.String = text;
            obj.View.handles.descriptionText.TooltipString = text;
            obj.currentMode = mode;
            
            % update obj.BatchOpt
            obj.BatchOpt.Width = obj.View.handles.Width.String;
            obj.BatchOpt.Height = obj.View.handles.Height.String;
            obj.BatchOpt.Depth = obj.View.handles.Depth.String;
            obj.BatchOpt.Time = obj.View.handles.Time.String;
            
            obj.updateBatchOptFromGUI(hObject);
        end
        
        function editboxes_Callback(obj)
            % function editboxes_Callback(obj)
            % update parameters of obj.roiPos based on provided values
            
            str2 = obj.View.handles.Width.String;
            obj.roiPos{1}(1) = min(str2num(str2)); %#ok<ST2NM>
            obj.roiPos{1}(2) = max(str2num(str2)); %#ok<ST2NM>
            str2 = obj.View.handles.Height.String;
            obj.roiPos{1}(3) = min(str2num(str2)); %#ok<ST2NM>
            obj.roiPos{1}(4) = max(str2num(str2)); %#ok<ST2NM>
            str2 = obj.View.handles.Depth.String;
            obj.roiPos{1}(5) = min(str2num(str2)); %#ok<ST2NM>
            obj.roiPos{1}(6) = max(str2num(str2)); %#ok<ST2NM>
            str2 = obj.View.handles.Time.String;
            obj.roiPos{1}(7) = min(str2num(str2)); %#ok<ST2NM>
            obj.roiPos{1}(8) = max(str2num(str2)); %#ok<ST2NM>
        end
        
        function SelectROI_Callback(obj)
            % function SelectROI_Callback(obj)
            % callback for change of obj.View.handles.SelectROI with the
            % list of ROIs
            
            val = obj.View.handles.SelectROI.Value - 1;
            
            str2 = obj.View.handles.Time.String;
            tMin = min(str2num(str2)); %#ok<ST2NM>
            tMax = max(str2num(str2)); %#ok<ST2NM>
            if val == 0
                [number, roiIndices] = obj.mibModel.I{obj.mibModel.Id}.hROI.getNumberOfROI(0);
                i = 1;
                for idx=roiIndices
                    obj.roiPos{i} = obj.mibModel.I{obj.mibModel.Id}.getROIBoundingBox(idx);
                    obj.roiPos{i}(7:8) = [tMin, tMax];
                    i = i + 1;
                end
                obj.View.handles.Width.String = 'Multi';
                obj.View.handles.Height.String = 'Multi';
                obj.View.handles.Depth.String = 'Multi';
            else
                bb{1} = obj.mibModel.I{obj.mibModel.Id}.getROIBoundingBox(val);
                obj.View.handles.Width.String = [num2str(bb{1}(1)) ':', num2str(bb{1}(2))];
                obj.View.handles.Height.String = [num2str(bb{1}(3)) ':', num2str(bb{1}(4))];
                obj.View.handles.Depth.String = [num2str(bb{1}(5)) ':', num2str(bb{1}(6))];
                obj.roiPos{1} = bb{1};
                obj.roiPos{1}(7:8) = [tMin, tMax];
            end
            % update obj.BatchOpt
            obj.BatchOpt.Width = obj.View.handles.Width.String;
            obj.BatchOpt.Height = obj.View.handles.Height.String;
            obj.BatchOpt.Depth = obj.View.handles.Depth.String;
            obj.BatchOpt.Time = obj.View.handles.Time.String;
        end
        
        function resetBtn_Callback(obj)
            % function resetBtn_Callback(obj)
            % reset widgets based on current image sizes
            obj.View.handles.Width.String = ['1:' num2str(obj.mibModel.I{obj.mibModel.Id}.width)];
            obj.View.handles.Height.String = ['1:' num2str(obj.mibModel.I{obj.mibModel.Id}.height)];
            obj.View.handles.Depth.String = ['1:' num2str(obj.mibModel.I{obj.mibModel.Id}.depth)];
            obj.View.handles.Time.String = ['1:' num2str(obj.mibModel.I{obj.mibModel.Id}.time)];
            
            obj.roiPos{1} = [1, obj.mibModel.I{obj.mibModel.Id}.width, 1, obj.mibModel.I{obj.mibModel.Id}.height,...
                1, obj.mibModel.I{obj.mibModel.Id}.depth 1, obj.mibModel.I{obj.mibModel.Id}.time];
            
            obj.radio_Callback(obj.View.handles.Manual);
        end
        
        function cropToBtn_Callback(obj)
            % function cropToBtn_Callback(obj)
            % select destination buffer for the cropping
            
            global mibPath; % path to mib installation folder

            if strcmp(obj.BatchOpt.Width, 'Multi')
                msgbox(sprintf('Oops, not implemented yet!\nPlease select a single ROI from the Select ROI combobox'),'Multiple ROI crop', 'warn');
                notify(obj.mibModel, 'stopProtocol');
                return;
            end
            
            bufferId = obj.mibModel.maxId;
            for i=1:obj.mibModel.maxId-1
                if strcmp(obj.mibModel.I{i}.meta('Filename'), 'none.tif')
                    bufferId = i;
                    break;
                end
            end
            
            prompts = {'Enter the destination buffer:'};
            defAns = {arrayfun(@(x) {num2str(x)}, 1:obj.mibModel.maxId)};
            defAns{1}(end+1) = {bufferId};
            title = 'Crop dataset to';
            
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, title);
            if isempty(answer); return; end
            bufferId = str2double(answer{1});
            
            obj.BatchOpt.Destination(1) = {sprintf('Container %d', bufferId)};
            obj.cropBtn_Callback();
        end
        
        function cropBtn_Callback(obj, hObject)
            % function cropBtn_Callback(obj, hObject)
            % make the crop
            % 
            % Parameters:
            % hObject: handle to the pressed button, handles.croptoBtn or
            % handles.cropBtn
            if nargin > 1
                if strcmp(hObject.Tag, 'cropBtn')
                    obj.BatchOpt.Destination(1) = {sprintf('Container %d', obj.mibModel.Id)};
                end
            end
            
            BatchOptLoc = obj.BatchOpt;
            
            if BatchOptLoc.Interactive    % interactive
                obj.View.gui.Visible = 'off';
                
                obj.mibModel.disableSegmentation = 1;  % disable segmentation
                
                h = imrect(obj.mibImageAxes);
                new_position = wait(h);
                delete(h);
                obj.mibModel.disableSegmentation = 0;    % re-enable selection switch 
                
                if isempty(new_position)
                    obj.View.gui.Visible = 'on';
                    return;
                end
                
                % [xmin, ymin, width, height]
                options.blockModeSwitch = 0;
                [height, width, ~, ~] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('selection', NaN, 0, options);

                % make positive x1 and y1 and convert from [x1, y1 width, height] to [x1, y1, x2, y2]
                new_position(3) = new_position(3) + new_position(1);    % xMax
                new_position(4) = new_position(4) + new_position(2);    % yMax
                if new_position(1) < 0; new_position(1) = max([new_position(1) 0.5]); end             % xMin
                if new_position(2) < 0; new_position(2) = max([new_position(2) 0.5]); end             % yMin
                
                % [xmin, ymin, xmax, ymax]
                [position(1), position(2)] = obj.mibModel.convertMouseToDataCoordinates(new_position(1), new_position(2), 'shown');  % x1, y1
                [position(3), position(4)] = obj.mibModel.convertMouseToDataCoordinates(new_position(3), new_position(4), 'shown'); % x2, y2
                position = ceil(position);
                
                % fix x2 and y2
                if position(3) > width; position(3) = width; end
                if position(4) > height; position(4) = height; end
                 
                if obj.mibModel.I{obj.mibModel.Id}.orientation == 4 % xy plane
                    crop_factor = [position(1:2) position(3)-position(1)+1 position(4)-position(2)+1 1 obj.mibModel.I{obj.mibModel.Id}.depth]; % x1, y1, dx, dy, z1, dz
                elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 1 % xz plane
                    crop_factor = [position(2) 1 position(4)-position(2)+1 obj.mibModel.I{obj.mibModel.Id}.height position(1) position(3)-position(1)+1]; % x1, y1, dx, dy, z1, dz
                elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 2 % yz plane
                    crop_factor = [1 position(2) obj.mibModel.I{obj.mibModel.Id}.width position(4)-position(2)+1 position(1) position(3)-position(1)+1]; % x1, y1, dx, dy, z1, dz
                end
                obj.View.gui.Visible = 'on';
            else
                if strcmp(BatchOptLoc.Width, 'Multi')
                    msgbox(sprintf('Oops, not implemented yet!\nPlease select a single ROI from the Select ROI combobox'),'Multiple ROI crop', 'warn');
                    notify(obj.mibModel, 'stopProtocol');
                    return;
                end
                cropDim = str2num(BatchOptLoc.Width); %#ok<ST2NM>
                x1 = min(cropDim);
                x2 = max(cropDim);
                cropDim = str2num(BatchOptLoc.Height); %#ok<ST2NM>
                y1 = min(cropDim);
                y2 = max(cropDim);
                cropDim = str2num(BatchOptLoc.Depth); %#ok<ST2NM>
                z1 = min(cropDim);
                z2 = max(cropDim);
                crop_factor = [x1, y1, x2-x1+1, y2-y1+1, z1, z2-z1+1];
            end
            
            % check for CropTo use
            if ~strcmp(BatchOptLoc.Destination{1}, sprintf('Container %d', obj.mibModel.Id))
                bufferId = str2double(BatchOptLoc.Destination{1}(end));
                % copy dataset to the destination buffer
                obj.mibModel.mibImageDeepCopy(bufferId, obj.mibModel.Id);
            else
                bufferId = obj.mibModel.Id;
            end
            
            cropDim = str2num(BatchOptLoc.Time); %#ok<ST2NM>
            tMin = min(cropDim);
            tMax = max(cropDim);
            
            crop_factor = [crop_factor tMin tMax-tMin+1];
            obj.mibModel.I{bufferId}.disableSelection = obj.mibModel.preferences.disableSelection;  % should be before cropDataset
            result = obj.mibModel.I{bufferId}.cropDataset(crop_factor);
            if result == 0; notify(obj.mibModel, 'stopProtocol'); return; end
            obj.mibModel.I{bufferId}.hROI.crop(crop_factor);
            obj.mibModel.I{bufferId}.hLabels.crop(crop_factor);
            log_text = ['ImCrop: [x1 y1 dx dy z1 dz t1 dt]: [' num2str(crop_factor) ']'];
            obj.mibModel.I{bufferId}.updateImgInfo(log_text);

            obj.listener{1}.Enabled = 0;    % disable listener to do not update widgets
            eventdata = ToggleEventData(bufferId);  
            notify(obj.mibModel, 'newDataset', eventdata);  % notify newDataset with the index of the dataset
            obj.listener{1}.Enabled = 1;    % re-enable listener to do not update widgets
            
            if strcmp(BatchOptLoc.Destination{1}, sprintf('Container %d', obj.mibModel.Id))
                eventdata = ToggleEventData(1);
                notify(obj.mibModel, 'plotImage', eventdata);
            end
            
            % do not update widgets for the batch mode
            if ~isempty(obj.View)
                if bufferId == obj.mibModel.Id; obj.updateWidgets(); end
            end
            
            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            if BatchOptLoc.Interactive
                BatchOptLoc.Interactive = false;
                BatchOptLoc.Manual = true;
                BatchOptLoc.Width = sprintf('%d:%d', crop_factor(1), crop_factor(1)+crop_factor(3)-1);
                BatchOptLoc.Height = sprintf('%d:%d', crop_factor(2), crop_factor(2)+crop_factor(4)-1);
                BatchOptLoc.Depth = sprintf('%d:%d', crop_factor(5), crop_factor(5)+crop_factor(6)-1);
                BatchOptLoc.Time = sprintf('%d:%d', crop_factor(7), crop_factor(7)+crop_factor(8)-1);
            end
            if BatchOptLoc.ROI
                BatchOptLoc.ROI = false;
                BatchOptLoc.Manual = true;
            end
            obj.returnBatchOpt(BatchOptLoc);
        end
        
    end
end