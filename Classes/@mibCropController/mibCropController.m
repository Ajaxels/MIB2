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
        function obj = mibCropController(mibModel, mibImageAxes)
            obj.mibModel = mibModel;    % assign model
            obj.mibImageAxes = mibImageAxes;
            guiName = 'mibCropGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
				
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
        
        function updateWidgets(obj)
            % function updateWidgets(obj)
            % update all widgets of the current window
            obj.View.handles.wEdit.String = ['1:' num2str(obj.mibModel.getImageProperty('width'))];
            obj.View.handles.hEdit.String = ['1:' num2str(obj.mibModel.getImageProperty('height'))];
            obj.View.handles.zEdit.String = ['1:' num2str(obj.mibModel.getImageProperty('depth'))];
            obj.View.handles.tEdit.String = ['1:' num2str(obj.mibModel.getImageProperty('time'))];
            obj.roiPos{1} = NaN;
            
            [numberOfROI, indicesOfROI] = obj.mibModel.I{obj.mibModel.Id}.hROI.getNumberOfROI(0);     % get all ROI
            if numberOfROI == 0
                 obj.View.handles.roiRadio.Enable = 'off';
            end
            obj.radio_Callback(obj.View.handles.manualRadio);
            
            if obj.mibModel.preferences.disableSelection == 1
                obj.View.handles.interactiveRadio.Enable = 'off';
                obj.View.handles.manualRadio.Value = 1;
                obj.View.handles.descriptionText.String = ...
                    'To enable the interactive crop tool please switch on the selection mode. Set the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) to "no"';
            end
            
            list{1} = 'All';
            i=2;
            for idx = indicesOfROI
                list(i) = obj.mibModel.I{obj.mibModel.Id}.hROI.Data(idx).label; %#ok<AGROW>
                i = i + 1;
            end
            obj.View.handles.roiPopup.String = list;
            
            if numel(list) > 1
                obj.View.handles.roiPopup.Value = max([obj.mibModel.I{obj.mibModel.Id}.selectedROI+1 2]);
                obj.View.handles.roiRadio.Enable = 'on';
            else
                obj.View.handles.roiPopup.Value = 1;
            end
        end
        
        function radio_Callback(obj, hObject)
            % function radio_Callback(obj, hObject)
            % callback for selection of crop mode
            %
            % Parameters:
            % hObject: a handle to selected radio button to choose the crop mode
            % @li handles.interactiveRadio - interactive
            % @li handles.manualRadio - manual
            % @li handles.roiRadio - from selected ROI
            
            mode = hObject.Tag;
            
            obj.View.handles.roiPopup.Enable = 'off';
            obj.View.handles.wEdit.Enable = 'off';
            obj.View.handles.hEdit.Enable = 'off';
            obj.View.handles.zEdit.Enable = 'off';
            
            if obj.mibModel.getImageProperty('time') > 1
                obj.View.handles.tEdit.Enable = 'on';
            else
                obj.View.handles.tEdit.Enable = 'off';
            end
            if strcmp(mode,'interactiveRadio')
                text = sprintf('Interactive mode allows to draw a rectangle that will be used for cropping\nTo start, press the Continue button and use the left mouse button to draw a rectangle area');
                obj.editboxes_Callback();
            elseif strcmp(mode,'manualRadio')
                obj.View.handles.wEdit.Enable = 'on';
                obj.View.handles.hEdit.Enable = 'on';
                obj.View.handles.zEdit.Enable = 'on';
                text = sprintf('In the manual mode the numbers entered in the edit boxes below will be used for cropping');
                obj.editboxes_Callback();
            elseif strcmp(mode,'roiRadio')
                obj.View.handles.roiPopup.Enable = 'on';
                text = sprintf('Use existing ROIs to crop the image');
                obj.roiPopup_Callback();
            end
            obj.View.handles.descriptionText.String = text;
        end
        
        function editboxes_Callback(obj)
            % function editboxes_Callback(obj)
            % update parameters of obj.roiPos based on provided values
            
            str2 = obj.View.handles.wEdit.String;
            obj.roiPos{1}(1) = min(str2num(str2)); %#ok<ST2NM>
            obj.roiPos{1}(2) = max(str2num(str2)); %#ok<ST2NM>
            str2 = obj.View.handles.hEdit.String;
            obj.roiPos{1}(3) = min(str2num(str2)); %#ok<ST2NM>
            obj.roiPos{1}(4) = max(str2num(str2)); %#ok<ST2NM>
            str2 = obj.View.handles.zEdit.String;
            obj.roiPos{1}(5) = min(str2num(str2)); %#ok<ST2NM>
            obj.roiPos{1}(6) = max(str2num(str2)); %#ok<ST2NM>
            str2 = obj.View.handles.tEdit.String;
            obj.roiPos{1}(7) = min(str2num(str2)); %#ok<ST2NM>
            obj.roiPos{1}(8) = max(str2num(str2)); %#ok<ST2NM>
        end
        
        function roiPopup_Callback(obj)
            % function roiPopup_Callback(obj)
            % callback for change of obj.View.handles.roiPopup with the
            % list of ROIs
            
            val = obj.View.handles.roiPopup.Value - 1;
            
            str2 = obj.View.handles.tEdit.String;
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
                obj.View.handles.wEdit.String = 'Multi';
                obj.View.handles.hEdit.String = 'Multi';
                obj.View.handles.zEdit.String = 'Multi';
            else
                bb{1} = obj.mibModel.I{obj.mibModel.Id}.getROIBoundingBox(val);
                obj.View.handles.wEdit.String = [num2str(bb{1}(1)) ':', num2str(bb{1}(2))];
                obj.View.handles.hEdit.String = [num2str(bb{1}(3)) ':', num2str(bb{1}(4))];
                obj.View.handles.zEdit.String = [num2str(bb{1}(5)) ':', num2str(bb{1}(6))];
                obj.roiPos{1} = bb{1};
                obj.roiPos{1}(7:8) = [tMin, tMax];
            end
        end
        
        function resetBtn_Callback(obj)
            % function resetBtn_Callback(obj)
            % reset widgets based on current image sizes
            obj.View.handles.wEdit.String = ['1:' num2str(obj.mibModel.getImageProperty('width'))];
            obj.View.handles.hEdit.String = ['1:' num2str(obj.mibModel.getImageProperty('height'))];
            obj.View.handles.zEdit.String = ['1:' num2str(obj.mibModel.getImageProperty('depth'))];
            obj.View.handles.tEdit.String = ['1:' num2str(obj.mibModel.getImageProperty('time'))];
            
            obj.roiPos{1} = [1, obj.mibModel.getImageProperty('width'), 1, obj.mibModel.getImageProperty('height'),...
                1, obj.mibModel.getImageProperty('depth') 1, obj.mibModel.getImageProperty('time')];
            
            obj.radio_Callback(obj.View.handles.manualRadio);
        end
        
        function cropBtn_Callback(obj, hObject)
            % function cropBtn_Callback(obj, hObject)
            % make the crop
            % 
            % Parameters:
            % hObject: handle to the pressed button, handles.croptoBtn or
            % handles.cropBtn
            
            global mibPath; % path to mib installation folder
            
            if obj.View.handles.interactiveRadio.Value    % interactive
                obj.View.gui.Visible = 'off';
                
                %disableSelectionSwitch = obj.mibModel.preferences.disableSelection;
                obj.mibModel.disableSegmentation = 1;  % disable segmentation
                h =  imrect(obj.mibImageAxes);
                selarea = h.createMask;
                delete(h);
                obj.mibModel.disableSegmentation = 0;    % re-enable selection switch 
                
                obj.mibModel.I{obj.mibModel.Id}.clearSelection(NaN, NaN, obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber, obj.mibModel.I{obj.mibModel.Id}.getCurrentTimePoint);
                options.blockModeSwitch = 1;
                [height, width, ~, ~] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('selection', NaN, 0, options);
                obj.mibModel.setData2D('selection', imresize(uint8(selarea), [height width], 'method', 'nearest'), NaN, NaN, NaN, options);
                notify(obj.mibModel, 'plotImage');
                
                choice2 = questdlg('Do you want to crop the image to selected area?', 'Crop options', 'Yes', 'Cancel', 'Cancel');
                if strcmp(choice2,'Cancel')
                    obj.mibModel.I{obj.mibModel.Id}.clearSelection(NaN, NaN, obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber());
                    notify(obj.mibModel, 'plotImage');
                    obj.View.gui.Visible = 'on';
                    return;
                end
                selarea = cell2mat(obj.mibModel.getData2D('selection'));
                STATS = regionprops(selarea, 'BoundingBox');
                
                if obj.mibModel.I{obj.mibModel.Id}.orientation == 4 % xy plane
                    crop_factor = [round(STATS.BoundingBox(1:2)) STATS.BoundingBox(3:4) 1 obj.mibModel.I{obj.mibModel.Id}.depth]; % x1, y1, dx, dy, z1, dz
                elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 1 % xz plane
                    crop_factor = [round(STATS.BoundingBox(2)) 1 round(STATS.BoundingBox(4)) obj.mibModel.I{obj.mibModel.Id}.height round(STATS.BoundingBox(1)) round(STATS.BoundingBox(3))]; % x1, y1, dx, dy, z1, dz
                elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 2 % yz plane
                    crop_factor = [1 round(STATS.BoundingBox(2)) obj.mibModel.I{obj.mibModel.Id}.width round(STATS.BoundingBox(4)) round(STATS.BoundingBox(1)) round(STATS.BoundingBox(3))]; % x1, y1, dx, dy, z1, dz
                end
                obj.mibModel.I{obj.mibModel.Id}.clearSelection(NaN, NaN, obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber());
                %obj.View.gui.Visible = 'on';
            elseif ~isnan(obj.roiPos{1})
                x1 = obj.roiPos{1}(1);
                x2 = obj.roiPos{1}(2);
                y1 = obj.roiPos{1}(3);
                y2 = obj.roiPos{1}(4);
                z1 = obj.roiPos{1}(5);
                z2 = obj.roiPos{1}(6);
                crop_factor = [x1,y1,x2-x1+1,y2-y1+1,z1,z2-z1+1];
            else
                msgbox('Oops, not implemented yet!','Multiple ROI crop','warn');
                return;
            end
            
            if strcmp(hObject.Tag, 'croptoBtn')
                bufferId = obj.mibModel.maxId;
                for i=1:obj.mibModel.maxId-1
                    if strcmp(obj.mibModel.I{i}.meta('Filename'), 'none.tif')
                        bufferId = i;
                        break;
                    end
                end
                
                answer = mibInputDlg({mibPath}, 'Enter destination buffer number (from 1 to 9) to duplicate the dataset:', 'Duplicate', num2str(bufferId));
                if isempty(answer); return; end
                bufferId = str2double(answer{1});
                
                % copy dataset to the destination buffer
                obj.mibModel.mibImageDeepCopy(bufferId, obj.mibModel.Id);
            else
                bufferId = obj.mibModel.Id;
                obj.mibModel.U.clearContents();  % clear undo history
            end
            crop_factor = [crop_factor obj.roiPos{1}(7) obj.roiPos{1}(8)-obj.roiPos{1}(7)+1];
            obj.mibModel.I{bufferId}.cropDataset(crop_factor);
            obj.mibModel.I{bufferId}.hROI.crop(crop_factor);
            obj.mibModel.I{bufferId}.hLabels.crop(crop_factor);
            log_text = ['ImCrop: [x1 y1 dx dy z1 dz t1 dt]: [' num2str(crop_factor) ']'];
            obj.mibModel.I{bufferId}.updateImgInfo(log_text);

%             
%             if strcmp(get(hObject, 'tag'), 'croptoBtn')
% 
%             else
%                 obj.updateWidgets();
%             end
            eventdata = ToggleEventData(bufferId);  
            notify(obj.mibModel, 'newDataset', eventdata);  % notify newDataset with the index of the dataset
            if ~strcmp(hObject.Tag, 'croptoBtn')
                eventdata = ToggleEventData(1);
                notify(obj.mibModel, 'plotImage', eventdata);
            end
            obj.closeWindow();
        end
        
        
    end
end