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

classdef GranularityController < handle
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        matlabExportVariable
        % name of variable for export results to Matlab
        mode
        % a string with mode to use: 
        % - 'image2D', currently shown image in 2D
        % - 'timelapse2D', current time-lapse movie
        % - 'volume3D', for the current 3D dataset
        se
        % strel element
        subarea
        % a structure with the selected subarea for the analysis
        % .x - [min, max]
        % .y - [min, max]
        % .z - [min, max]
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
%         function ViewListner_Callback(obj, src, evnt)
%             switch src.Name
%                 case {'Id', 'newDatasetSwitch'}     % added in mibChildView
%                     obj.updateWidgets();
%                     %                 case 'slices'     % replaced with
%                     %                 'changeSlice', 'changeTime' events because slice is changed too often
%                     %                     if obj.listener{3}.Enabled
%                     %                         disp(toc)
%                     %                         obj.updateHist();
%                     %                     end
%             end
%         end
        
        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case {'updateGuiWidgets'}
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = GranularityController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'GranularityGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % check for the virtual stacking mode and close the controller
            if isprop(obj.mibModel.I{obj.mibModel.Id}, 'Virtual') && obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                obj.closeWindow();
                return;
            end
            
            % move the window, the function was moved to GranularityGUI.m
            %obj.View.gui = moveWindowOutside(obj.View.gui, 'left');
            
            % change strel types
            if verLessThan('matlab', '9') % obj.matlabVersion < 9
                obj.View.handles.strelTypePopup.String = {'disk', 'rectangle'};
            end
            
            % resize all elements of the GUI
            mibRescaleWidgets(obj.View.gui);
            
            % % update font and size
            % % you may need to replace "obj.View.handles.text1" with tag of any text field of your own GUI
            global Font;
            if ~isempty(Font)
              if obj.View.handles.text1.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.text1.FontName, Font.FontName)
                  mibUpdateFontSize(obj.View.gui, Font);
              end
            end
            obj.subarea = struct();
            obj.mode = 'image2D';
            obj.matlabExportVariable = 'Granularity';
            
            if isdeployed; obj.View.handles.exportMatlabCheck.Enable = 'off'; end
            
            obj.updateWidgets();
            obj.updateStrel_Callback();
            
            % add images to buttons
            obj.View.handles.previewStrelBtn.CData = obj.mibModel.sessionSettings.guiImages.eye;
            
            [path, fn] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            obj.View.handles.filenameEdit.String = fullfile(path, [fn '_Granularity.xlsx']);
            obj.View.handles.filenameEdit.TooltipString = fullfile(path, [fn '_Granularity.xlsx']);
            
            % obj.View.gui.WindowStyle = 'modal';     % make window modal
			
			% add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
             
            % option 2: in some situations
            % obj.listener{1} = addlistener(obj.mibModel, 'Id', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
            % obj.listener{2} = addlistener(obj.mibModel, 'newDatasetSwitch', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
        end
        
        function closeWindow(obj)
            % closing GranularityController window
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
            if obj.mibModel.getImageProperty('depth') < 2
                obj.View.handles.timelapse2D.Enable = 'off';
                obj.View.handles.volume3D.Enable = 'off';
                obj.View.handles.image2D.Value = 1;
            else
                obj.View.handles.timelapse2D.Enable = 'on';
                obj.View.handles.volume3D.Enable = 'on';
            end
            
            if obj.mibModel.I{obj.mibModel.Id}.hROI.getNumberOfROI() > 1
                obj.View.handles.useROICheck.Enable = 'on';
            else
                obj.View.handles.useROICheck.Enable = 'off';
                obj.View.handles.useROICheck.Value = 0;
            end
            
            % populating lists of materials
            obj.updateMaterialsBtn_Callback();
            
            % populate subarea edit boxes
            if ~isfield(obj.subarea, 'x'); obj.resetSubarea(); end
        end
        
        % ------------------------------------------------------------------
        % % Additional functions and callbacks
        function modeRadio_Callback(obj, hObject)
            % function mode2dRadio_Callback(obj, hObject)
            % callback for selection of the mode
            %
            % Parameters:
            % hObject: a handle to the selected radio button
            % @li 'image2D', currently shown image in 2D
            % @li 'timelapse2D', current time-lapse movie
            % @li 'volume3D', current 3D volume

            obj.mode = hObject.Tag;
            hObject.Value = 1;
            if strcmp(obj.mode, 'volume3D')
                obj.View.handles.strelSizeZEdit.Enable = 'on';
                obj.View.handles.strelRotationsEdit.Enable = 'on';
                obj.View.handles.strelTypePopup.Value = 3;  % select sphere
                obj.View.handles.useROICheck.Value = 0;
                obj.View.handles.useROICheck.Enable = 'off';
            else
                obj.View.handles.strelSizeZEdit.Enable = 'off';
                obj.View.handles.strelRotationsEdit.Enable = 'off';
                obj.View.handles.useROICheck.Enable = 'on';
            end
            obj.updateStrel_Callback();
        end
        
        function resetSubarea(obj)
            % function resetSubarea(obj)
            % reset subarea for the granularity analysis
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('selection', 4);
            obj.subarea.x = [1, width];
            obj.subarea.y = [1, height];
            obj.subarea.z = [1, depth];  
            obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', obj.subarea.x(1), obj.subarea.x(2));
            obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', obj.subarea.y(1), obj.subarea.y(2));
            obj.View.handles.zSubareaEdit.String = sprintf('%d:%d', obj.subarea.z(1), obj.subarea.z(2));
        end
        
        function updateSubarea(obj, hObject)
            % function updateSubarea(parameter)
            % check entered dimensions for the dataset to process and
            % update obj.subarea structure
            %
            % Parameters:
            % hObject: handle on the selected object
            
            text = hObject.String;
            typedValue = str2num(text); %#ok<ST2NM>

            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('selection', 4);
            switch hObject.Tag
                case 'xSubareaEdit'
                    maxVal = width;
                    fieldName = 'x';
                case 'ySubareaEdit'
                    maxVal = height;
                    fieldName = 'y';
                case 'zSubareaEdit'
                    maxVal = depth;
                    fieldName = 'z';
            end
            if min(typedValue) < 1 || max(typedValue) > maxVal
                hObject.String = sprintf('%d:%d', obj.subarea.(fieldName)(1), obj.subarea.(fieldName)(2));
                hObject.BackgroundColor = 'r';
                errordlg('Please check the values!', 'Wrong dimensions!');
                return;
            end
            obj.subarea.(fieldName)(1) = min(typedValue);
            obj.subarea.(fieldName)(2) = max(typedValue);
            hObject.BackgroundColor = 'w';
        end
        
        function currentViewBtn_Callback(obj)
            % function currentViewBtn_Callback(obj)
            % callback for press of currentViewBtn; defines dataset from
            % the current view
            [yMin, yMax, xMin, xMax] = obj.mibModel.I{obj.mibModel.Id}.getCoordinatesOfShownImage();
            obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', xMin, xMax);
            obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', yMin, yMax);
            obj.subarea.x = [xMin, xMax];
            obj.subarea.y = [yMin, yMax];
        end
        
        function subAreaFromSelectionBtn_Callback(obj)
            % function subAreaFromSelectionBtn_Callback(obj)
            % callback for press of subAreaFromSelectionBtn; select subArea
            % from the current selection layer
            
            bgColor = obj.View.handles.subAreaFromSelectionBtn.BackgroundColor;
            obj.View.handles.subAreaFromSelectionBtn.BackgroundColor = 'r';
            drawnow;
            if strcmp(obj.mode, 'image2D')
                img = cell2mat(obj.mibModel.getData2D('selection'));
                STATS = regionprops(img, 'BoundingBox');
                if numel(STATS) == 0
                    errordlg(sprintf('!!! Error !!!\n\nSelection layer was not found!\nPlease make sure that the Selection layer\nis shown in the Image View panel'), ...
                        'Missing Selection');
                    obj.resetSubarea();
                    obj.View.handles.subAreaFromSelectionBtn.BackgroundColor = bgColor;
                    return;
                end
                obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', ceil(STATS(1).BoundingBox(1)), ceil(STATS(1).BoundingBox(1))+STATS(1).BoundingBox(3)-1);
                obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', ceil(STATS(1).BoundingBox(2)), ceil(STATS(1).BoundingBox(2))+STATS(1).BoundingBox(4)-1);
                obj.subarea.x = [ceil(STATS(1).BoundingBox(1)), ceil(STATS(1).BoundingBox(1))+STATS(1).BoundingBox(3)-1];
                obj.subarea.y = [ceil(STATS(1).BoundingBox(2)), ceil(STATS(1).BoundingBox(2))+STATS(1).BoundingBox(4)-1];
            else
                img = cell2mat(obj.mibModel.getData3D('selection', NaN, 4));
                STATS = regionprops(img, 'BoundingBox');
                if numel(STATS) == 0
                    errordlg(sprintf('!!! Error !!!\n\nSelection layer was not found!\nPlease make sure that the Selection layer\n is shown in the Image View panel'),...
                        'Missing Selection');
                    obj.resetSubarea();
                    obj.View.handles.subAreaFromSelectionBtn.BackgroundColor = bgColor;
                    return;
                end
                obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', ceil(STATS(1).BoundingBox(1)), ceil(STATS(1).BoundingBox(1))+STATS(1).BoundingBox(4)-1);
                obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', ceil(STATS(1).BoundingBox(2)), ceil(STATS(1).BoundingBox(2))+STATS(1).BoundingBox(5)-1);
                obj.View.handles.zSubareaEdit.String = sprintf('%d:%d', ceil(STATS(1).BoundingBox(3)), ceil(STATS(1).BoundingBox(3))+STATS(1).BoundingBox(6)-1);
                obj.subarea.x = [ceil(STATS(1).BoundingBox(1)), ceil(STATS(1).BoundingBox(1))+STATS(1).BoundingBox(4)-1];
                obj.subarea.y = [ceil(STATS(1).BoundingBox(2)), ceil(STATS(1).BoundingBox(2))+STATS(1).BoundingBox(5)-1];
                obj.subarea.z = [ceil(STATS(1).BoundingBox(3)), ceil(STATS(1).BoundingBox(3))+STATS(1).BoundingBox(6)-1];
            end
            obj.View.handles.subAreaFromSelectionBtn.BackgroundColor = bgColor;
        end
        
        function updateMaterialsBtn_Callback(obj)
            % function updateMaterialsBtn_Callback(obj)
            % callback for the update Materials button
            
            % populating lists of materials
            list = obj.mibModel.getImageProperty('modelMaterialNames');
            if obj.mibModel.getImageProperty('maskExist')
                list = [cellstr('Mask'); list];
            end
            if isempty(list)
                obj.View.handles.sourceMaterialPopup.Value = 1;
                obj.View.handles.sourceMaterialPopup.String = 'Please create a model or a mask';
                obj.View.handles.sourceMaterialPopup.BackgroundColor = 'r';
            else
                obj.View.handles.sourceMaterialPopup.Value = 1;
                obj.View.handles.sourceMaterialPopup.String = list;
                obj.View.handles.sourceMaterialPopup.BackgroundColor = 'w';
            end
        end
        
        function updateStrel_Callback(obj)
            % function updateStrel_Callback(obj)
            % update strel element
            strelType = obj.View.handles.strelTypePopup.String{obj.View.handles.strelTypePopup.Value};
            strelSize = str2double(obj.View.handles.strelSizeEdit.String);
            
            if strcmp(obj.mode, 'volume3D')
                strelSizeZ = str2double(obj.View.handles.strelSizeZEdit.String);
                se_size_xyz = [strelSize strelSize strelSizeZ];
                obj.se = zeros(se_size_xyz(1)*2+1,se_size_xyz(2)*2+1,se_size_xyz(3)*2+1);    % do strel ball type in volume
                if se_size_xyz(3) > 0
                    [x,y,z] = meshgrid(-se_size_xyz(1):se_size_xyz(1),-se_size_xyz(2):se_size_xyz(2),-se_size_xyz(3):se_size_xyz(3));
                    ball = sqrt((x/se_size_xyz(1)).^2+(y/se_size_xyz(2)).^2+(z/se_size_xyz(3)).^2);
                    obj.se(ball<=1) = 1; 
                else
                    se1 = strel('sphere', strelSize);
                    se1 = se1.Neighborhood(:,:,strelSize+1); 
                    obj.se = zeros([size(se1, 1), size(se1, 2), 3], 'uint8');
                    obj.se(:,:,2) = se1;
                end
                
                % option 2 by using sphere
%                 se2 = strel('sphere', strelSize).Neighborhood;
%                 zFactor = strelSizeZ/strelSize;
%                 options.method = 'nearest';
%                 obj.se = logical(mibResize3d(uint8(se2), [1 1 zFactor], options));
            else
                switch strelType
                    case 'disk'
                        obj.se = strel(strelType, strelSize).Neighborhood;
                    case 'rectangle'
                        obj.se = strel(strelType, [strelSize, strelSize]).Neighborhood;
                    case 'sphere'
                        obj.se = strel(strelType, strelSize).Neighborhood(:,:,strelSize+1);                    
                end
            end
        
        end
        
        function previewStrelBtn_Callback(obj)
            % function previewStrelBtn_Callback(obj)
            % preview shape of the strel element
            
            if strcmp(obj.mode, 'volume3D')
                rotationSteps = str2double(obj.View.handles.strelRotationsEdit.String);
                angleStep = pi/rotationSteps;
                
                index = 0;
                for yAngle = 0:angleStep:pi
                    my = makehgtform('yrotate', yAngle);
                    for xAngle = 0:angleStep:pi
                        mx = makehgtform('xrotate', xAngle);
                        m = mx*my;
                        tform = affine3d(m);
                        se3Rotated = imwarp(obj.se, tform, 'nearest');
                        
%                         if index == 10
%                             assignin('base', 'se', se3Rotated);
%                         end
                        
                        if index < 16
                            figure(141);
                            subplot(4,4,index+1);
                            cla;
                            [faces, verts] = isosurface(se3Rotated, 0.5);
                            p = patch('Faces',faces,'Vertices',verts,'FaceColor',[1 0 0], 'EdgeColor','none');
                            p.AmbientStrength = .3;
                            set(gca,'projection','perspective');
                            lighting gouraud;
                            camlight('headlight');
                            axis tight;
                            axis equal;
                            title(sprintf('X: %d, Y: %d', xAngle/pi*180, yAngle/pi*180));
                            grid;
                        elseif index < 32
                            figure(142);
                            subplot(4,4,index+1-16);
                            cla;
                            [faces, verts] = isosurface(se3Rotated, 0.5);
                            p = patch('Faces',faces,'Vertices',verts,'FaceColor',[1 0 0], 'EdgeColor','none');
                            p.AmbientStrength = .3;
                            set(gca,'projection','perspective');
                            lighting gouraud;
                            camlight('headlight');
                            axis tight;
                            axis equal;
                            title(sprintf('X: %d, Y: %d', xAngle/pi*180, yAngle/pi*180));
                            grid;
                        elseif index < 48
                            figure(143);
                            subplot(4,4,index+1-32);
                            cla;
                            [faces, verts] = isosurface(se3Rotated, 0.5);
                            p = patch('Faces',faces,'Vertices',verts,'FaceColor',[1 0 0], 'EdgeColor','none');
                            p.AmbientStrength = .3;
                            set(gca,'projection','perspective');
                            lighting gouraud;
                            camlight('headlight');
                            axis tight;
                            axis equal;
                            title(sprintf('X: %d, Y: %d', xAngle/pi*180, yAngle/pi*180));
                            grid;
                        end
                        index = index + 1;
                    end
                end
                
%                 figure(148);
%                 cla;
%                 [faces, verts] = isosurface(se3Rotated, 0.5);
%                 p = patch('Faces', faces, 'Vertices', verts, 'FaceColor', [1 0 0], 'EdgeColor', 'none');
%                 p.AmbientStrength = .3;
%                 set(gca,'projection','perspective');
%                 lighting gouraud;
%                 camlight('headlight');
%                 axis tight;
%                 axis equal;
%                 grid;
            else
                imtool(obj.se, []);
            end
        end
        
        function exportMatlabCheck_Callback(obj)
            % function exportMatlabCheck_Callback(obj)
            % callback for selection of export to Matlab check box
            
            if obj.View.handles.exportMatlabCheck.Value
                answer = mibInputDlg({[]}, sprintf('Please define output variable:'),...
                    'Export variable', obj.matlabExportVariable);
                if ~isempty(answer)
                    obj.matlabExportVariable = answer{1};
                else
                    return;
                end
            end
        
        end
        
        function calculateBtn_Callback(obj)
            % start main calculation of the plugin
            if obj.mibModel.I{obj.mibModel.Id}.orientation ~= 4
                msgbox('Please rotate the dataset to the XY orientation!', 'Error!', 'error', 'modal');
                return;
            end
            
            outFn = obj.View.handles.filenameEdit.String;
            if obj.View.handles.exportFileCheck.Value
                % check filename
                if exist(outFn, 'file') == 2
                    strText = sprintf('!!! Warning !!!\n\nThe file:\n%s \nis already exist!\n\nOverwrite?', outFn);
                    button = questdlg(strText, 'File exist!','Overwrite', 'Cancel', 'Cancel');
                    if strcmp(button, 'Cancel'); return; end
                    delete(outFn);     % delete existing file
                end
            end
            
            % a structure for results
            Granularity = struct();
            % Granularity(1).pixSize - pixelSize
            % get pixel sizes
            pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            Granularity(1).pixSize = pixSize;   % pixel size of the dataset
            Granularity(1).DatasetFilename = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');  % filename of the dataset
            Granularity(1).MaskFilename = [];   % to be populated later, filename for the mask or model
            Granularity(1).MaskMaterialIndex = 1;   % index of the model material, or 1 for the mask layer
            Granularity(1).MaskMaterialName = 'Mask';   % name of material of the model or Mask
            Granularity(1).StrelType = obj.View.handles.strelTypePopup.String{obj.View.handles.strelTypePopup.Value};  % type of the strel element
            Granularity(1).StrelSize = str2double(obj.View.handles.strelSizeEdit.String);  % size of the strel element
            Granularity(1).StrelElement = obj.se;   % strel element that was used, not for Excel
            if isKey(obj.mibModel.I{obj.mibModel.Id}.meta, 'SliceName')
                Granularity(1).SliceName = obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'); % a cell array with names of slices
            else
                [~, fn, ext] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
                Granularity(1).SliceName = {[fn ext]};
            end
            
            Granularity(1).subarea = struct();  % area for the analysis, a structure with .x, .y, .z fields
            Granularity(1).Granularity = [];     % a vector with ratio of tubules to total
            if obj.View.handles.useROICheck.Value
                Granularity(1).useROI = obj.mibModel.I{obj.mibModel.Id}.selectedROI;     % use of not the ROI 
            else
                Granularity(1).useROI = 0;
            end
            
            if strcmp(obj.mode, 'volume3D')
                Granularity(1).totalVolumePixels = [];
                Granularity(1).totalVolumeUnits = [];
                Granularity(1).sheetsVolumePixels = [];
                Granularity(1).sheetsVolumeUnits = [];
                Granularity(1).tubulesVolumePixels = [];
                Granularity(1).tubulesVolumeUnits = [];
            else
                Granularity(1).sheetsAreaUnits = [];    % a vector with area of sheets in units
                Granularity(1).tubulesAreaUnits = [];    % a vector with area of tubules in units
                Granularity(1).totalAreaUnits = [];    % a vector with total area in units
                Granularity(1).sheetsAreaPixels = [];    % a vector with area of sheets in pixels
                Granularity(1).tubulesAreaPixels = [];    % a vector with area of tubules in pixels
                Granularity(1).totalAreaPixels = [];    % a vector with total area in pixels
            end
            
            dataSource = obj.View.handles.sourceMaterialPopup.String{obj.View.handles.sourceMaterialPopup.Value};
            if strcmp(dataSource, 'Mask')
                layerIn = 'mask';
                materialIndex = NaN;
                layerOut = 'selection';     % layer for results
                Granularity(1).MaskFilename = obj.mibModel.I{obj.mibModel.Id}.maskImgFilename;
            else
                layerIn = 'model';
                materialIndex = obj.View.handles.sourceMaterialPopup.Value;     % get index of material for analysis
                if strcmp(obj.View.handles.sourceMaterialPopup.String{1}, 'Mask')
                    materialIndex = materialIndex - 1;                          % if Mask present, decrease the index by 1
                end
                layerOut = 'selection';     % layer for results
                Granularity(1).MaskFilename = obj.mibModel.I{obj.mibModel.Id}.modelFilename;
                Granularity(1).MaskMaterialIndex = materialIndex;
                Granularity(1).MaskMaterialName = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{materialIndex};
            end
            
            if Granularity(1).useROI > 0
                if numel(obj.mibModel.I{obj.mibModel.Id}.selectedROI) > 1
                    errordlg('Please select a single ROI in the ROI panel and try again', 'Missing ROIs');
                    return;
                end
                getDataOptions.roiId = [];  % use currently selected ROI
                getDataOptions.fillBg = 0;
            else
                getDataOptions.roiId = -1;  % do not use ROI
            end
            getDataOptions.blockModeSwitch = 0;
            getDataOptions.x = obj.subarea.x;
            getDataOptions.y = obj.subarea.y;
            getDataOptions.z = obj.subarea.z;
           
            % do a backup
            obj.mibModel.mibDoBackup(layerOut, 1, getDataOptions); 
            
            % clear existing layers
            if strcmp(layerOut, 'selection')
                obj.mibModel.I{obj.mibModel.Id}.clearSelection();     % clear Selection layer
            elseif strcmp(layerOut, 'model')
                if obj.mibModel.I{obj.mibModel.Id}.modelExist
                    button = questdlg(sprintf('!!! Warning !!!\n\nThe existing model will be removed!\n\nContinue?'), ...
                        'Overwrite the model', 'Continue', 'Cancel', 'Cancel');
                    if strcmp(button, 'Cancel'); return; end
                end
                obj.mibModel.I{obj.mibModel.Id}.createModel(63);    % create a new model model
            end
            
            if strcmp(obj.mode, 'image2D')
                currentSlice = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
                getDataOptions.z = [currentSlice, currentSlice];
            end
            
            Granularity(1).subarea.x = getDataOptions.x;
            Granularity(1).subarea.y = getDataOptions.y;
            Granularity(1).subarea.z = getDataOptions.z;
            
            mask = cell2mat(obj.mibModel.getData3D(layerIn, NaN, 4, materialIndex, getDataOptions));
            sheetsOut = zeros(size(mask), 'uint8');
            
            wb = waitbar(0, sprintf('Calculating granularity: 0%%\nPlease wait...'), 'Name', 'Granularity');
            if strcmp(obj.mode, 'volume3D')
                rotationSteps = str2double(obj.View.handles.strelRotationsEdit.String);
                angleStep = pi/rotationSteps;
                iterNo = numel(0:angleStep:pi)*numel(0:angleStep:pi);
                index = 0;
                sheetsOut = zeros(size(mask), 'uint8');
                
                for yAngle = 0:angleStep:pi
                    my = makehgtform('yrotate', yAngle);
                    for xAngle = 0:angleStep:pi
                        mx = makehgtform('xrotate', xAngle);
                        m = mx*my;
                        tform = affine3d(m);
                        se3Rotated = imwarp(obj.se, tform, 'nearest');
                        
                        M2 = imerode(mask, se3Rotated);
                        M2 = imdilate(M2, se3Rotated);
                        sheetsOut = sheetsOut | M2;
                        index = index + 1;
                        waitbar(index/iterNo, wb, sprintf('Calculating granularity: %d%%\nPlease wait...', round(index/iterNo*100)));
                    end
                end
                Granularity(1).totalVolumePixels = sum(sum(sum(mask)));
                Granularity(1).totalVolumeUnits = Granularity(1).totalVolumePixels*pixSize.x*pixSize.y*pixSize.z;
                Granularity(1).sheetsVolumePixels = sum(sum(sum(sheetsOut)));
                Granularity(1).sheetsVolumeUnits = Granularity(1).sheetsVolumePixels*pixSize.x*pixSize.y*pixSize.z;
                Granularity(1).tubulesVolumePixels = Granularity(1).totalVolumePixels - Granularity(1).sheetsVolumePixels;
                Granularity(1).tubulesVolumeUnits = Granularity(1).tubulesVolumePixels * pixSize.x*pixSize.y*pixSize.z;
                Granularity(1).Granularity = Granularity(1).tubulesVolumePixels / Granularity(1).totalVolumePixels;
            else
                noSlices = size(mask, 3);
                Granularity(1).sheetsAreaUnits = zeros([noSlices, 1]);    % a vector with area of sheets in units
                Granularity(1).tubulesAreaUnits = zeros([noSlices, 1]);    % a vector with area of tubules in units
                Granularity(1).totalAreaUnits = zeros([noSlices, 1]);    % a vector with total area in units
                Granularity(1).sheetsAreaPixels = zeros([noSlices, 1]);    % a vector with area of sheets in pixels
                Granularity(1).tubulesAreaPixels = zeros([noSlices, 1]);    % a vector with area of tubules in pixels
                Granularity(1).totalAreaPixels = zeros([noSlices, 1]);    % a vector with total area in pixels
                Granularity(1).Granularity = zeros([noSlices, 1]);     % a vector with ratio of tubules to total
                
                for z=1:noSlices
                    Granularity(1).totalAreaPixels(z) = sum(sum(mask(:,:,z)));
                    Granularity(1).totalAreaUnits(z) = Granularity(1).totalAreaPixels(z)*pixSize.x*pixSize.y;
                    
                    sheetsOut(:,:,z) = imdilate(imerode(mask(:,:,z), obj.se), obj.se);
                    Granularity(1).sheetsAreaPixels(z) = sum(sum(sheetsOut(:,:,z)));
                    Granularity(1).sheetsAreaUnits(z) = Granularity(1).sheetsAreaPixels(z)*pixSize.x*pixSize.y;
                    Granularity(1).tubulesAreaPixels(z) = Granularity(1).totalAreaPixels(z)-Granularity(1).sheetsAreaPixels(z);
                    Granularity(1).tubulesAreaUnits(z) = Granularity(1).totalAreaUnits(z)-Granularity(1).sheetsAreaUnits(z);
                    Granularity(1).Granularity(z) = Granularity(1).tubulesAreaPixels(z) / Granularity(1).totalAreaPixels(z);
                    
                    proc = z/size(mask, 3);
                    waitbar(proc, wb, sprintf('Calculating granularity: %d%%\nPlease wait...', round(proc*100)));
                end
            end
            getDataOptions.fillBg = NaN;
            obj.mibModel.setData3D(layerOut, sheetsOut, NaN, 4, NaN, getDataOptions);
            
%             if selected_roi == -1    % do the whole image analysis
%                 img_mask = zeros([obj.mibModel.I{obj.mibModel.Id}.height, obj.mibModel.I{obj.mibModel.Id}.width], 'uint8') + 1;  % make image mask as a whole single image
%             end
            
            % export to matlab
            if obj.View.handles.exportMatlabCheck.Value
                waitbar(.99, wb, sprintf('Exporting to Matlab\nPlease wait...'));
                assignin('base', obj.matlabExportVariable, Granularity);
                fprintf('Granularity: structure ''%s'' with results has been created in the Matlab workspace\n', obj.matlabExportVariable);
            end
            
            % export to a file
            if obj.View.handles.exportFileCheck.Value
                if strcmp(outFn(end-2:end), 'mat')
                    save(outFn, 'Granularity');
                    fprintf('Granularity: exporting results to a file: done\n%s\n', outFn);
                else
                    waitbar(1, wb, sprintf('Generating Excel file...\nPlease wait...'));
                    % excel export
                    obj.saveToExcel(Granularity, outFn);
                end    
            end
            
            %obj.mibModel.mibAnnMarkerEdit = 'label'
            %obj.mibModel.mibShowAnnotationsCheck = 1;
            notify(obj.mibModel, 'plotImage');
            delete(wb);

            if strcmp(obj.mode, 'timelapse2D')
                figure(717)
                plot(Granularity(1).subarea.z(1):Granularity(1).subarea.z(2), Granularity(1).Granularity, 'o-');
                xlabel('Slice number');
                ylabel('Granularity, tubules/total');
                title('Granularity value')
            elseif strcmp(obj.mode, 'image2D')
                fprintf('Granularity of slice %d (0-1): %f\n', getDataOptions.z(1), Granularity(1).Granularity);
            elseif strcmp(obj.mode, 'volume3D')
                fprintf('Granularity of 3D dataset (0-1): %f\n', Granularity(1).Granularity);
            end
        end
        
        function saveToExcel(obj, Granularity, outFn)
            % function saveToExcel(obj, Granularity, outFn)
            % save results to Excel
%             
%             Granularity(1).pixSize = pixSize;   % pixel size of the dataset
%             Granularity(1).DatasetFilename = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');  % filename of the dataset
%             Granularity(1).MaskFilename = [];   % to be populated later, filename for the mask or model
%             Granularity(1).MaskMaterialIndex = 1;   % index of the model material, or 1 for the mask layer
%             Granularity(1).MaskMaterialName = 'Mask';   % name of material of the model or Mask
%             Granularity(1).StrelType = obj.View.handles.strelTypePopup.String{obj.View.handles.strelTypePopup.Value};  % type of the strel element
%             Granularity(1).StrelSize = str2double(obj.View.handles.strelSizeEdit.String);  % size of the strel element
%             Granularity(1).StrelElement = obj.se;   % strel element that was used, not for Excel
%             Granularity(1).SliceName = obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'); % a cell array with names of slices
%             Granularity(1).subarea = struct();  % area for the analysis, a structure with .x, .y, .z fields
%             Granularity(1).sheetsAreaUnits = [];    % a vector with area of sheets in units
%             Granularity(1).tubulesAreaUnits = [];    % a vector with area of tubules in units
%             Granularity(1).totalAreaUnits = [];    % a vector with total area in units
%             Granularity(1).sheetsAreaPixels = [];    % a vector with area of sheets in pixels
%             Granularity(1).tubulesAreaPixels = [];    % a vector with area of tubules in pixels
%             Granularity(1).totalAreaPixels = [];    % a vector with total area in pixels
%             Granularity(1).Granularity = [];     % a vector with ratio of tubules to total 
%             Granularity(1).useROI                % a number use of not the ROI area, 0 - do not use, number - index of the ROI

%             for 3D dataset
%             Granularity(1).totalVolumePixels 
%             Granularity(1).totalVolumeUnits 
%             Granularity(1).sheetsVolumePixels 
%             Granularity(1).sheetsVolumeUnits 
%             Granularity(1).tubulesVolumePixels 
%             Granularity(1).tubulesVolumeUnits
%             Granularity(1).Granularity


            warning('off', 'MATLAB:xlswrite:AddSheet');
            % Sheet 1, general results
            s = {'Granularity: calculate ratio of tubular areas to total area of the object'};
            s(2,2) = {'Image filename:'};  s(2,4) = {Granularity(1).DatasetFilename};
            s(3,2) = {'Mask filename:'};   s(3,4) = {Granularity(1).MaskFilename};
            s(4,2) = {sprintf('Material index: %d', Granularity(1).MaskMaterialIndex)};   s(4,4) = {sprintf('Material name: %s', Granularity(1).MaskMaterialName)};
            s(5,2) = {sprintf('Strel type: %s', Granularity(1).StrelType)}; s(5,4) = {sprintf('Strel size: %d', Granularity(1).StrelSize)}; 
            s(6,2) = {sprintf('Pixel size [x,y,z]/units: %fx%fx%f %s',...
                Granularity(1).pixSize.x, Granularity(1).pixSize.y, Granularity(1).pixSize.z, Granularity(1).pixSize.units)};
            s(7,2) = {sprintf('Analyzed area [x1:x2, y1:y2, z1:z2]/pixels: %d:%d, %d:%d, %d:%d',...
                Granularity(1).subarea.x(1), Granularity(1).subarea.x(2), ...
                Granularity(1).subarea.y(1), Granularity(1).subarea.y(2), ...
                Granularity(1).subarea.z(1), Granularity(1).subarea.z(2))};
            if Granularity(1).useROI > 0
                s(7, 9) = {sprintf('Used ROI index: %d', Granularity(1).useROI)};
            end
            
            if ~isfield(Granularity, 'totalVolumePixels')
                text1 = 'area';     % for table headers
                text2 = 'Area';     % for field names in Granularity structure
            else
                text1 = 'volume';   
                text2 = 'Volume';
            end
            
            dR1 = 9;    % row position for the column names
            if numel(Granularity(1).SliceName) > 1; s(dR1,1) = {'Filename'}; end
            s(dR1, 2) = {'SliceNo'}; 
            s(dR1, 3) = {'Granularity,'}; s(dR1+1, 3) = {'tubules/total'};
            
            s(dR1, 5) = {'Tubules,'}; s(dR1+1, 5) ={sprintf('%s, px', text1)};
            s(dR1, 6) = {'Sheets,'}; s(dR1+1, 6) ={sprintf('%s, px', text1)};
            s(dR1, 7) = {'Total,'}; s(dR1+1, 7) ={sprintf('%s, px', text1)};
            
            s(dR1, 9) = {'Tubules,'}; s(dR1+1, 9) ={sprintf('%s, %s', text1, Granularity(1).pixSize.units)};
            s(dR1, 10) = {'Sheets,'}; s(dR1+1, 10) ={sprintf('%s, %s', text1, Granularity(1).pixSize.units)};
            s(dR1, 11) = {'Total,'}; s(dR1+1, 11) ={sprintf('%s, %s', text1, Granularity(1).pixSize.units)};
            
            dR2 = 11;    % row position for the column names
            maxVal = size(Granularity(1).Granularity, 1);
            if numel(Granularity(1).SliceName) > 1
                if maxVal > 1
                    s(dR2:dR2+maxVal-1, 1) = Granularity(1).SliceName(Granularity(1).subarea.z(1):Granularity(1).subarea.z(2));
                else
                    s(dR2, 1) = Granularity(1).SliceName(Granularity(1).subarea.z(1));
                end
            end
            vecTemp = 1:maxVal;
            vecTemp = vecTemp + Granularity(1).subarea.z(1) - 1;
            s(dR2:dR2+maxVal-1, 2) = num2cell(vecTemp');
            s(dR2:dR2+maxVal-1, 3) = num2cell(Granularity(1).Granularity);
            s(dR2:dR2+maxVal-1, 5) = num2cell(Granularity(1).(sprintf('tubules%sPixels', text2)));
            s(dR2:dR2+maxVal-1, 6) = num2cell(Granularity(1).(sprintf('sheets%sPixels', text2)));
            s(dR2:dR2+maxVal-1, 7) = num2cell(Granularity(1).(sprintf('total%sPixels', text2))); 
            s(dR2:dR2+maxVal-1, 9) = num2cell(Granularity(1).(sprintf('tubules%sUnits', text2))); 
            s(dR2:dR2+maxVal-1, 10) = num2cell(Granularity(1).(sprintf('sheets%sUnits', text2))); 
            s(dR2:dR2+maxVal-1, 11) = num2cell(Granularity(1).(sprintf('total%sUnits', text2))); 

            xlswrite2(outFn, s, 'Results', 'A1');
            fprintf('Granularity: exporting results to a file: done\n%s\n', outFn);
            
        end
    end
end