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

classdef mibStereologyController < handle
    % @type mibStereologyController class is responsible for showing the stereology analysis window,
    % available from MIB->Menu->Tools->Stereology
    
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
            Font = obj.mibModel.preferences.System.Font;
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
            
            if obj.mibModel.preferences.System.EnableSelection == 0
                errordlg(sprintf('!!! Error !!!\n\nSelection is disabled\nEnable it in the\nMenu->File->Preferences->Enable selection: yes'), 'Error');
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
            
            if obj.View.handles.centeredGrid.Value
                % compute coordinates of grid intersections that are evenly distributed, 
                % leaving equal margins on all sides of the grid
                % Stereology analysis of this grid will give overestimated
                % values relative to the image size, but it will be
                % corrected later in the analysis part
                
                % Number of steps that fit in each dimension
                nx = floor(width  / dX);
                ny = floor(height / dY);

                % Compute offsets so grid is centered inside the image
                offset_x = ceil((width  - nx * dX) / 2);
                offset_y = ceil((height - ny * dY) / 2);

                % Grid coordinates along each axis
                x_coords = offset_x : dX : width; 
                y_coords = offset_y : dY : height; 
            else % use the provided values
                % Coordinates along each axis
                oX2 = ceil(dX/2); % mid-point of the grid 
                oY2 = ceil(dY/2);

                x_coords = 1+oX+oX2:dX:width;
                y_coords = 1+oY+oY2:dY:height;
            end

            % %% Debug: preview the grid points
            % % Make full grid
            % [X, Y] = meshgrid(x_coords, y_coords);
            % 
            % % Display result (optional)
            % figure(96541);
            % plot(X, Y, 'k+');
            % axis equal;
            % xlim([0 width]);
            % ylim([0 height]);
            % title('Grid Crosses');
            % xlabel('X (px)'); ylabel('Y (px)');

            wb = waitbar(0,sprintf('Generating the grid\nPlease wait...'), 'Name', 'Stereology grid');
            for t=1:obj.mibModel.I{obj.mibModel.Id}.time
                % allocate space for the mask
                mask = zeros([height, width, depth], 'uint8');
                waitbar(0.1, wb);
                
                %oX2 = ceil(dX/2);
                %oY2 = ceil(dY/2);
                %mask(:,1+oX+oX2:dX:end,:) = 1;
                mask(:,x_coords,:) = 1;
                waitbar(0.4, wb);
                % mask(1+oY+oY2:dY:end,:,:) = 1;
                mask(y_coords,:,:) = 1;
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
                answer = mibInputDlg({mibPath}, prompt, title, sprintf('Stgy_%s', def));
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
            
            % generate round strel
            [X, Y] = meshgrid(-pointSize:pointSize, -pointSize:pointSize);
            % Logical mask: points inside circle
            strelmask = (X.^2 + Y.^2) <= pointSize^2;
            [mh, mw] = size(strelmask);
            
            for t=1:obj.mibModel.I{obj.mibModel.Id}.time
                options.t = [t t];
                modelOut = zeros([height, width, depth], 'uint8');
                
                %se = strel('disk', pointSize);
                for slice=1:depth
                    currMask = cell2mat(obj.mibModel.getData2D('mask', slice, NaN, NaN, options));
                    currMask = bwmorph(currMask, 'thin', 'Inf');     % thin lines to make them 1px wide
                    currMask = bwmorph(currMask, 'branchpoints', 1);        % find branch points, i.e. intersections
                    
                    if slice==1
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

                        % %% Debug: preview the grid points
                        % % Make full grid
                        % [X, Y] = meshgrid(xy(:,1), xy(:,2));
                        %
                        % % Display result (optional)
                        % figure(96542);
                        % plot(X, Y, 'k+');
                        % axis equal;
                        % xlim([0 width]);
                        % ylim([0 height]);
                        % xlabel('X (px)'); ylabel('Y (px)');

                        if obj.View.handles.scaleToImage.Value
                            % half width
                            halfX = ceil(dXp/2); halfY = ceil(dYp/2);
                            Xc = xy(:,1); % x-coordinates
                            Yc = xy(:,2); % y-coordinates

                            % Cell bounds for each center
                            left   = Xc - halfX;
                            right  = Xc + halfX;
                            top    = Yc - halfY;
                            bottom = Yc + halfY;

                             % Image bounds: [0, width] × [0, height]
                            interLeft   = max(left,   0);
                            interRight  = min(right,  width);
                            interTop    = max(top,    0);
                            interBottom = min(bottom, height);

                            % Overlap dimensions (clipped to >= 0)
                            overlapW = max(0, interRight  - interLeft);
                            overlapH = max(0, interBottom - interTop);
                            
                            % Fractional overlap (area fraction) in [0,1]
                            scalingFactors = (overlapW .* overlapH) / (dXp * dYp);
                        else
                            scalingFactors = ones([size(xy,1), 1]);
                        end
                    end
                    % get a slice from the model
                    currModel = cell2mat(obj.mibModel.getData2D('model', slice, NaN, NaN, options));
                    % allocate space for the output model
                    currModelOut = zeros(size(currModel), 'uint8');

                    for crossId=1:size(xy, 1)
                        x = xy(crossId, 1);
                        y = xy(crossId, 2);

                        materialIndex = currModel(y, x);
                        if materialIndex == 0; materialIndex = unassId; end
                        Occurrence(t, slice, materialIndex) = Occurrence(t, slice, materialIndex) + scalingFactors(crossId);
                        currModelOut(y, x) = materialIndex;
                        
                        % stamp circle of radius == pointSize
                        % using this instead of imdilate as it is faster
                        % for large spot sizes.
                        
                        % top/left corner for the spot on the image
                        x1 = max(1, x-pointSize);
                        x2 = min(width, x+pointSize);
                        y1 = max(1, y-pointSize);
                        y2 = min(height, y+pointSize);

                        % Corresponding region in circle mask
                        mx1 = 1 + (x1 - (x-pointSize));
                        mx2 = mx1 + (x2 - x1);
                        my1 = 1 + (y1 - (y-pointSize));
                        my2 = my1 + (y2 - y1);

                        % clamp mask indices to mask size
                        mx1 = max(mx1, 1); 
                        my1 = max(my1, 1);
                        mx2 = min(mx2, mw); 
                        my2 = min(my2, mh);

                        % Generate the spot
                        currModelOut(y1:y2, x1:x2) = uint8(strelmask(my1:my2, mx1:mx2))*materialIndex;
                    end
                    modelOut(:,:,slice) = currModelOut;
                    waitbar(slice/depth, wb);
                end
                
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
            res.ScaleToImage = logical(obj.View.handles.scaleToImage.Value);
            res.CenteredGrid = logical(obj.View.handles.centeredGrid.Value);
            
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
                if isfile(fn_out); delete(fn_out); end
                
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
                    if res.CenteredGrid
                        s(4, 10:11) = {'Centered grid:' 'true'};
                    else
                        s(4, 10:11) = {'Centered grid:' 'false'};
                    end
                    if res.ScaleToImage
                        s(5, 10:11) = {'Scale to image size:' 'true'};
                    else
                        s(5, 10:11) = {'Scale to image size:' 'false'};
                    end
                    
                    s(1,15:17) = {'Pixel size','dX', 'dY'};
                    s(2,16:17) = {sprintf('%f', obj.mibModel.I{obj.mibModel.Id}.pixSize.x) sprintf('%f', obj.mibModel.I{obj.mibModel.Id}.pixSize.y)};
                    
                    s(4,1:2) = {'Time point:' sprintf('%d', t)};
                    
                    nMat = numel(res.Materials);
                    dataRowId = 7;
                    s(dataRowId,1) = {'SliceId'}; s(dataRowId,2) = {'Occurrence'}; s(dataRowId,2+nMat+2) = {'SurfaceFraction'};  s(dataRowId,2+nMat*2+2*2) = {sprintf('Surface in %s^2', res.GridSize.unitsType)};
                    if obj.View.handles.annotationCheck.Value == 1
                        s(dataRowId,2+nMat*3+3*2) = {'Annotation labels'};
                    end
                    s(dataRowId+1,2:nMat+1) = res.Materials(:);
                    s(dataRowId+1,2+nMat+2:2+nMat*2+2-1) = res.Materials(:);
                    s(dataRowId+1,2+nMat*2+2*2:2+nMat*3+2*2-1) = res.Materials(:);
                    
                    % add slice IDs
                    currDataRowId = dataRowId+2;
                    if numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName')) ~= depth
                        list = 1:depth;
                        s(currDataRowId:currDataRowId+depth-1,1) = cellstr(num2str(list'));
                    else
                        s(currDataRowId:currDataRowId+depth-1,1) = obj.mibModel.I{obj.mibModel.Id}.meta('SliceName');
                    end
                    
                    % saving results
                    s(currDataRowId:currDataRowId+depth-1,2:nMat+1) = num2cell(res.Occurrence(t,:,:));
                    s(currDataRowId:currDataRowId+depth-1,2+nMat+2:2+nMat*2+2-1) = num2cell(res.SurfaceFraction(t,:,:));
                    s(currDataRowId:currDataRowId+depth-1,2+nMat*2+2*2:2+nMat*3+2*2-1) = num2cell(res.Surface_in_units(t,:,:));
                    
                    if obj.View.handles.annotationCheck.Value == 1
                        nLabels = numel(res.Annotations.Labels);
                        s(dataRowId+1,2+nMat*3+3*2:2+nMat*3+nLabels+3*2-1) = res.Annotations.Labels(:);
                        s(currDataRowId:currDataRowId+depth-1, 2+nMat*3+3*2:2+nMat*3+nLabels+3*2-1) = num2cell(res.Annotations.Occurrence(t,:,:));
                    end
                    
                    s(depth+11, nMat*5) = {''};
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