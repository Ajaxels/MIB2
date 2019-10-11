classdef mibStereologyController < handle
    % @type mibStereologyController class is resposnible for showing the stereology analysis window,
    % available from MIB->Menu->Tools->Stereology
    
	% Copyright (C) 10.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
        function obj = mibStereologyController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibStereologyGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % check for the virtual stacking mode and close the controller
            if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                toolname = 'stereology tool is';
                warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode!\nPlease switch to the memory-resident mode and try again', ...
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
                        
            obj.updateWidgets();
			
			% add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing mibStereologyController window
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
            % update pixel sizes
            pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            pixString = sprintf('%.3f x %.3f x %.3f\nUnits: %s', pixSize.x, pixSize.y, pixSize.z, pixSize.units);
            obj.View.handles.pixelSizeText.String = pixString;
        end
        
        function generateGrid_Callback(obj)
            % function generateGrid_Callback(obj)
            % generate grid over the image and put it into the Mask layer
            
            if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1
                errordlg(sprintf('!!! Error !!!\n\nSelection is disabled\nEnable it in the\nMenu->File->Preferences->Disable selection: no'), 'Error');
                return;
            end
            options.blockModeSwitch = 0;    % turn off the blockmode switch to get dimensions of the whole dataset
            [height, width, color, depth, time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, 0, options);
            
            if obj.mibModel.I{obj.mibModel.Id}.maskExist == 1
                button = questdlg(sprintf('!!! Warning !!!\n\nThe existing mask layer will be replaced with the grid!\n\nIt can be undone using the Ctrl+Z shortcut'), ...
                    'Generate grid', 'Continue', 'Cancel', 'Cancel');
                if strcmp(button, 'Cancel'); return; end
            end
            if obj.mibModel.I{obj.mibModel.Id}.time == 1
                obj.mibModel.mibDoBackup('mask', 1);
            end
            
            dX = str2double(obj.View.handles.stepXedit.String);   % step for the grid in X
            dY = str2double(obj.View.handles.stepYedit.String);   % step for the grid in Y
            oX = str2double(obj.View.handles.offsetXedit.String); % offset for the grid in X
            oY = str2double(obj.View.handles.offsetYedit.String); % offset for the grid in Y
            pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            
            if obj.View.handles.imageunitsRadio.Value    % recalculate step and offset to the image units
                dX = round(dX/pixSize.x);
                dY = round(dY/pixSize.y);
                oX = round(oX/pixSize.x);
                oY = round(oY/pixSize.y);
            end
            
            wb = waitbar(0,sprintf('Generating the grid\nPlease wait...'), 'Name', 'Stereology grid');
            for t=1:obj.mibModel.I{obj.mibModel.Id}.time
                % allocate space for the mask
                mask = zeros([height, width, depth], 'uint8');
                waitbar(0.1, wb);
                
                oX2 = ceil(dX/2);
                oY2 = ceil(dY/2);
                
                mask(:,1+oX+oX2:dX:end,:) = 1;
                waitbar(0.4, wb);
                mask(1+oY+oY2:dY:end,:,:) = 1;
                waitbar(0.8, wb);
                
                gridThickness = str2double(obj.View.handles.gridThickness.String);
                if gridThickness > 0
                    se = zeros(gridThickness*2+1);
                    se(:,round(gridThickness/2)) = 1;
                    se(round(gridThickness/2),:) = 1;
                    
                    for slice=1:size(mask,3)
                        mask(:,:,slice) = imdilate(mask(:,:,slice), se);
                    end
                end
                
                % keep mask for the ROI area only
                if obj.mibModel.I{obj.mibModel.Id}.selectedROI >= 0
                    roiMask = obj.mibModel.I{obj.mibModel.Id}.hROI.returnMask(obj.mibModel.I{obj.mibModel.Id}.selectedROI);
                    for slice=1:size(mask, 3)
                        mask(:,:,slice) = mask(:,:,slice) & roiMask;
                    end
                end
                
                obj.mibModel.setData3D('mask', mask, t, NaN, 0, options);
                waitbar(0.95, wb);
            end
            notify(obj.mibModel, 'showMask');
            waitbar(1, wb);
            delete(wb);
        end
        
        function doStereologyBtn_Callback(obj)
            % function doStereologyBtn_Callback(obj)
            % calculate stereology
            
            global mibPath;
            
            options.blockModeSwitch = 0;    % turn off the blockmode switch to get dimensions of the whole dataset
            [height, width, color, depth, time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, 0, options);
            
            if obj.mibModel.I{obj.mibModel.Id}.maskExist == 0
                errordlg(sprintf('!!! Error !!!\n\nThe mask layer with a grid is required to proceed further!\n\nUse the Generate grid button to make a new grid!'), ...
                    'Missing the mask!');
                return;
            end
            
            if obj.mibModel.I{obj.mibModel.Id}.modelExist == 1
                button = questdlg(sprintf('!!! Warning !!!\n\nThe existing model layer will be replaced with the results!\n\nIt can be undone using the Ctrl+Z shortcut'),...
                    'Do analysis', 'Continue', 'Cancel', 'Cancel');
                if strcmp(button, 'Cancel'); return; end
            else
                errordlg(sprintf('!!! Error !!!\n\nA model with labeled objects of interest has to be present to proceed further!\n\nMake a new model and segment structures of interest'),...
                    'Missing the model!');
                return;
            end
            
            if obj.View.handles.matlabExportRadio.Value == 1     % export to Matlab
                title = 'Input variable to export';
                [~, def] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
                prompt = {'A variable for the measurements structure:'};
                answer = mibInputDlg({mibPath}, prompt, title, [def '_stgy']);
                if size(answer) == 0; return; end
                fn_out = answer{1};
            else        % export to Excel
                [path, def] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
                fn_out = fullfile(path, [def '_stgy.xls']);
                if isempty(fn_out)
                    fn_out = fullfile(obj.mibModel.myPath, 'stereology.xls');
                end
                Filters = {'*.xls',   'Excel format (*.xls)'; };
                [filename, path, FilterIndex] = uiputfile(Filters, 'Save stereology...', fn_out); %...
                if isequal(filename,0); return; end % check for cancel
                fn_out = fullfile(path, filename);
            end
            
            wb = waitbar(0,sprintf('Doing stereology\nPlease wait...'), 'Name', 'Stereology analysis');
            if obj.mibModel.I{obj.mibModel.Id}.time == 1
                obj.mibModel.mibDoBackup('model', 1);
            end
            
            pointSize = str2double(obj.View.handles.pointSizeEdit.String);
            matNames = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames;    % get material names
            nMat = numel(matNames); % number of materials in the model
            
            if strcmp(matNames{end}, 'Unassigned')  % define material for unassigned points
                unassId = nMat;
                Occurrence = zeros([time, depth, nMat]);  % allocate space for results
            else
                unassId = nMat + 1;
                matNames{unassId, :} = 'Unassigned';
                Occurrence = zeros([time, depth, nMat+1]);    % allocate space for results
            end
            
            for t=1:obj.mibModel.I{obj.mibModel.Id}.time
                options.t = [t t];
                modelOut = zeros([height, width, depth], 'uint8');
                
                se = strel('disk', pointSize);
                for slice=1:depth
                    currMask = cell2mat(obj.mibModel.getData2D('mask', slice, NaN, NaN, options));
                    currMask = bwmorph(currMask, 'thin', 'Inf');     % thin lines to make them 1px wide
                    currMask = bwmorph(currMask, 'branchpoints', 1);        % find branch points, i.e. intersections
                    
                    currModel = cell2mat(obj.mibModel.getData2D('model', slice, NaN, NaN, options));
                    
                    currModelOut = zeros(size(currModel), 'uint8');
                    for mat = 1:nMat
                        BW = zeros(size(currModel), 'uint8');
                        BW(currModel==mat & currMask==1) = 1;
                        
                        STATS = regionprops(bwconncomp(BW, 8), 'Area', 'PixelIdxList');
                        Occurrence(t, slice, mat) = Occurrence(t, slice, mat)+numel(STATS);
                        
                        currModelOut(BW==1) = mat;
                    end
                    % add unassigned material
                    BW = zeros(size(currModel), 'uint8');
                    BW(currModel==0 & currMask==1) = 1;
                    STATS = regionprops(bwconncomp(BW, 8), 'Area', 'PixelIdxList');
                    Occurrence(t, slice, unassId) = Occurrence(t, slice, unassId) + numel(STATS);
                    currModelOut(BW==1) = unassId;
                    
                    if pointSize > 1
                        currModelOut = imdilate(currModelOut, se);
                    end
                    modelOut(:,:,slice) = currModelOut;
                    waitbar(slice/depth, wb);
                end
                
                % % find grid step
                STATS = regionprops(bwconncomp(currMask, 8), 'Area', 'Centroid');
                xy = cat(1, STATS.Centroid);
                
                dXp = diff(xy(:,1));     % get step in X
                dXp(dXp==0) = [];         % remove 0
                dXp = mode(dXp);          % find the most frequent step, when used with ROI the centers of the wide grids may be shifted
                dX = dXp*obj.mibModel.I{obj.mibModel.Id}.pixSize.x;   % dX in units
                
                dYp = diff(xy(:,1));     % get step in Y
                dYp(dYp==0) = [];         % remove 0
                dYp = mode(dYp);          % find the most frequent step, when used with ROI the centers of the wide grids may be shifted
                dY = dYp*obj.mibModel.I{obj.mibModel.Id}.pixSize.y;   % dY in units
                
                waitbar(0.95, wb);
                obj.mibModel.setData3D('model', modelOut, t, NaN, NaN, options);
            end
            obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames = matNames;    % update material names
            
            res.Occurrence = Occurrence;    % number of Occurrence for each material at each grid point
            res.Materials = matNames;       % names for Materials
            
            SurfaceFraction = zeros(size(Occurrence));
            Surface_in_units = zeros(size(Occurrence));
            
            for t=1:time
                for i=1:depth
                    SurfaceFraction(t,i,:) = Occurrence(t,i,:)./sum(Occurrence(t,i,:));   % surface fraction for each material
                    Surface_in_units(t,i,:) = Occurrence(t,i,:)*dX*dY;                  % surface estimation in units
                end
            end
            res.SurfaceFraction = SurfaceFraction;
            res.Surface_in_units = Surface_in_units;
            res.GridSize.pixelsX = dXp;
            res.GridSize.pixelsY = dYp;
            res.GridSize.unitsX = dX;
            res.GridSize.unitsY = dY;
            res.GridSize.unitsType = obj.mibModel.I{obj.mibModel.Id}.pixSize.units;
            res.Filename = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
            res.ModelName = obj.mibModel.I{obj.mibModel.Id}.modelFilename;
            
            % include annotations
            if obj.View.handles.annotationCheck.Value == 1
                [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels;
                labelsList = strtrim(labelsList);   % remove the blank spaces
                uniqLabels = unique(labelsList);
                res.Annotations.Labels = uniqLabels;
                res.Annotations.Occurrence = zeros([time, depth, numel(uniqLabels)]);
                for labelId=1:numel(uniqLabels)
                    for timeId=1:time
                        for sliceId = 1:depth
                            indices = ismember(labelsList, uniqLabels(labelId)) & ismember(labelPositions(:,1), sliceId) & ismember(labelPositions(:,4), timeId);
                            res.Annotations.Occurrence(timeId, sliceId, labelId) = sum(labelValues(indices));
                        end
                    end
                end
            end
            
            % exporting
            if obj.View.handles.matlabExportRadio.Value == 1     % export to Matlab
                waitbar(0.98, wb, sprintf('Exporting to Matlab\nPlease wait...'));
                assignin('base', fn_out, res);
                fprintf('MIB: export measurements ("%s") to Matlab -> done!\n', fn_out);
            else    % export to Excel
                % deleting the file
                delete(fn_out);
                
                waitbar(0.98, wb, sprintf('Exporting to Excel\nPlease wait...'));
                warning('off', 'MATLAB:xlswrite:AddSheet');
                
                for t=1:time
                    % Sheet 1
                    clear s;
                    s = {sprintf('Stereology analysis with Microscopy Image Browser')};
                    s(2,1:2) = {'Filename:' sprintf('%s', res.Filename)};
                    s(3,1:2) = {'Model:' sprintf('%s', res.ModelName)};
                    s(1,10:12) = {'Grid size','dX', 'dY'};
                    s(2,10:12) = {'in Pixels:' sprintf('%d', res.GridSize.pixelsX) sprintf('%d', res.GridSize.pixelsY)};
                    s(3,10:13) = {'in Units:' sprintf('%f', res.GridSize.unitsX) sprintf('%f', res.GridSize.unitsY) sprintf('%s', res.GridSize.unitsType)};
                    
                    s(1,15:17) = {'Pixel size','dX', 'dY'};
                    s(2,16:17) = {sprintf('%f', obj.mibModel.I{obj.mibModel.Id}.pixSize.x) sprintf('%f', obj.mibModel.I{obj.mibModel.Id}.pixSize.y)};
                    
                    s(4,1:2) = {'Time point:' sprintf('%d', t)};
                    
                    nMat = numel(res.Materials);
                    s(6,1) = {'SliceId'}; s(6,2) = {'Occurrence'}; s(6,2+nMat+2) = {'SurfaceFraction'};  s(6,2+nMat*2+2*2) = {sprintf('Surface in %s^2', res.GridSize.unitsType)};
                    if obj.View.handles.annotationCheck.Value == 1
                        s(6,2+nMat*3+3*2) = {'Annotation labels'};
                    end
                    s(7,2:nMat+1) = res.Materials(:);
                    s(7,2+nMat+2:2+nMat*2+2-1) = res.Materials(:);
                    s(7,2+nMat*2+2*2:2+nMat*3+2*2-1) = res.Materials(:);
                    
                    % add slice IDs
                    if numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName')) ~= depth
                        list = 1:depth;
                        s(8:8+depth-1,1) = cellstr(num2str(list'));
                    else
                        s(8:8+depth-1,1) = obj.mibModel.I{obj.mibModel.Id}.meta('SliceName');
                    end
                    
                    % saving results
                    s(8:8+depth-1,2:nMat+1) = num2cell(res.Occurrence(t,:,:));
                    s(8:8+depth-1,2+nMat+2:2+nMat*2+2-1) = num2cell(res.SurfaceFraction(t,:,:));
                    s(8:8+depth-1,2+nMat*2+2*2:2+nMat*3+2*2-1) = num2cell(res.Surface_in_units(t,:,:));
                    
                    if obj.View.handles.annotationCheck.Value == 1
                        nLabels = numel(res.Annotations.Labels);
                        s(7,2+nMat*3+3*2:2+nMat*3+nLabels+3*2-1) = res.Annotations.Labels(:);
                        s(8:8+depth-1, 2+nMat*3+3*2:2+nMat*3+nLabels+3*2-1) = num2cell(res.Annotations.Occurrence(t,:,:));
                    end
                    
                    s(depth+10, nMat*5) = {''};
                    sheetId = sprintf('Sheet_%d', t);
                    xlswrite2(fn_out, s, sheetId, 'A1');
                    waitbar(t/time, wb);
                end
            end
            waitbar(1, wb);
            notify(obj.mibModel, 'updateId');
            notify(obj.mibModel, 'plotImage');
            delete(wb);
        end
    end
end