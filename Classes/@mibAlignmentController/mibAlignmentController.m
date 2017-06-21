classdef mibAlignmentController < handle
    % classdef mibAlignmentController < handle
    % controller class for alignment of datasets
    
    % Copyright (C) 25.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        files
        % files structure from the getImageMetadata
        maskOrSelection   
        % variable to keep information about type of layer used for alignment
        meta
        % meta containers.Map from the getImageMetadata
        pathstr
        % current path
        pixSize
        % pixSize structure from the getImageMetadata
        shiftsX
        % vector with X-shifts
        shiftsY
        % vector with Y-shifts
        varname  
        % variable for import
        
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function idx = findMatchingPairs(X1, X2)
            % find matching pairs for X1 from X2
            % X1[:, (x,y)]
            % X2[:, (x,y)]
            
            % % following code is equal to pdist2 function in the statistics toolbox
            % % such as: dist = pdist2(X1,X2);
            dist = zeros([size(X1,1) size(X2,1)]);
            for i=1:size(X1,1)
                for j=1:size(X2,1)
                    dist(i,j) = sqrt((X1(i,1)-X2(j,1))^2 + (X1(i,2)-X2(j,2))^2);
                end
            end
            
            % alternative fast method
            % DD = sqrt( bsxfun(@plus,sum(X1.^2,2),sum(X2.^2,2)') - 2*(X1*X2') );
            
            % following is an adaptation of a code by Gunther Struyf
            % http://stackoverflow.com/questions/12083467/find-the-nearest-point-pairs-between-two-sets-of-of-matrix
            N = size(X1,1);
            matchAtoB=NaN(N,1);
            X1b = X1;
            X2b = X2;
            for ii=1:N
                %dist(:,matchAtoB(1:ii-1))=Inf; % make sure that already picked points of B are not eligible to be new closest point
                %[~, matchAtoB(ii)]=min(dist(ii,:));
                dist(matchAtoB(1:ii-1),:)=Inf; % make sure that already picked points of B are not eligible to be new closest point
                %         for jj=1:N
                %             [~, minVec(jj)] = min(dist(:,jj));
                %         end
                [~, matchAtoB(ii)]=min(dist(:,ii));
                
                %         X2b(matchAtoB(1:ii-1),:)=Inf;
                %         goal = X1b(ii,:);
                %         r = bsxfun(@minus,X2b,goal);
                %         [~, matchAtoB(ii)] = min(hypot(r(:,1),r(:,2)));
            end
            matchBtoA = NaN(size(X2,1),1);
            matchBtoA(matchAtoB)=1:N;
            idx =  matchBtoA;   % indeces of the matching objects, i.e. STATS1(objId) =match= STATS2(idx(objId))
        end
        
        
    end
    
    methods
        function obj = mibAlignmentController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibAlignmentGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            obj.varname = 'I';  % variable for import
			
            obj.updateWidgets();
        end
        
        function closeWindow(obj)
            % closing mibAlignmentController  window
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
            if obj.mibModel.getImageProperty('time') > 1
                msgbox(sprintf('Unfortunately the alignment tool is not compatible with 5D datasets!\nLet us know if you need it!\nhttp:\\mib.helsinki.fi'), 'Error!', 'error', 'modal');
                return;
            end
            
            [height, width, colors, depth] = obj.mibModel.getImageMethod('getDatasetDimensions');
            fn = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
            [obj.pathstr, name, ext] = fileparts(fn);
            
            % define variables to store the shifts
            obj.shiftsX = [];
            obj.shiftsY = [];
            obj.maskOrSelection = 'mask';   % variable to keep information about type of layer used for alignment
            
            obj.meta = containers.Map;   % meta containers.Map from the getImageMetadata
            obj.files = struct();      % files structure from the getImageMetadata
            obj.pixSize = struct();    % pixSize structure from the getImageMetadata
            
            obj.View.handles.existingFnText1.String = obj.pathstr;
            obj.View.handles.existingFnText1.TooltipString = fn;
            obj.View.handles.existingFnText2.String = [name '.' ext];
            obj.View.handles.existingFnText2.TooltipString = fn;
            str2 = sprintf('%d x %d x %d', width, height, depth);
            obj.View.handles.existingDimText.String = str2;
            obj.View.handles.existingPixText2.String = sprintf('Pixel size, %s:', obj.mibModel.I{obj.mibModel.Id}.pixSize.units);
            str2 = sprintf('%f x %f x %f', obj.mibModel.I{obj.mibModel.Id}.pixSize.x, obj.mibModel.I{obj.mibModel.Id}.pixSize.y, obj.mibModel.I{obj.mibModel.Id}.pixSize.z);
            obj.View.handles.existingPixText.String = str2;
            
            obj.View.handles.pathEdit.String = obj.pathstr;
            obj.View.handles.saveShiftsXYpath.String = fullfile(obj.pathstr, [name '_align.coefXY']);
            obj.View.handles.loadShiftsXYpath.String = fullfile(obj.pathstr, [name '_align.coefXY']);
            
            % fill default entries for subwindow
            obj.View.handles.searchXminEdit.String = num2str(floor(width/2)-floor(width/4));
            obj.View.handles.searchYminEdit.String = num2str(floor(height/2)-floor(height/4));
            obj.View.handles.searchXmaxEdit.String = num2str(floor(width/2)+floor(width/4));
            obj.View.handles.searchYmaxEdit.String = num2str(floor(height/2)+floor(height/4));
            
            % updating color channel popup
            colorList = cell([colors,1]);
            for i=1:colors
                colorList{i} = sprintf('Ch %d', i);
            end
            obj.View.handles.colChPopup.String = colorList;
        end
        
        
        function selectButton_Callback(obj)
            % function selectButton_Callback(obj)
            % --- Executes on button press in selectButton.    
            
            startingPath = obj.View.handles.pathEdit.String;

            if obj.View.handles.dirRadio.Value
                newValue = uigetdir(startingPath, 'Select directory...');
                if newValue == 0; return; end;
                
                [obj.meta, obj.files, obj.pixSize, dimsXYZ] = obj.getMetaInfo(newValue);
                obj.View.handles.pathEdit.String = newValue;
                obj.View.handles.pathEdit.TooltipString = newValue;
            elseif obj.View.handles.fileRadio.Value
                [FileName, PathName] = uigetfile({'*.tif; *.am','(*.tif; *.am) TIF/AM Files';
                    '*.am','(*.am) Amira Mesh Files';
                    '*.tif','(*.tif) TIF Files';
                    '*.*','All Files'}, 'Select file...', startingPath);
                if FileName == 0; return; end;
                
                newValue = fullfile(PathName, FileName);
                [obj.meta, obj.files, obj.pixSize, dimsXYZ] = obj.getMetaInfo(newValue);
                obj.View.handles.pathEdit.String = newValue;
                obj.View.handles.pathEdit.TooltipString = newValue;
            elseif obj.View.handles.importRadio.Value
                [obj.meta, obj.files, obj.pixSize, dimsXYZ] = obj.getMetaInfo('');
                if isnan(dimsXYZ); return; end;
            end
            obj.View.handles.secondDimText.String = sprintf('%d x %d x %d', dimsXYZ(1), dimsXYZ(2), dimsXYZ(3));
            obj.View.handles.searchXminEdit.String = num2str(round(dimsXYZ(1)/2)-round(dimsXYZ(1)/4));
            obj.View.handles.searchXmaxEdit.String = num2str(round(dimsXYZ(1)/2)+round(dimsXYZ(1)/4));
            obj.View.handles.searchYminEdit.String = num2str(round(dimsXYZ(2)/2)-round(dimsXYZ(2)/4));
            obj.View.handles.searchYmaxEdit.String = num2str(round(dimsXYZ(2)/2)+round(dimsXYZ(2)/4));
        end
        
        function [meta, files, pixSize, dimsXYZ] = getMetaInfo(obj, dirName)
            parameters.waitbar = 1;     % show waitbar
            
            if obj.View.handles.dirRadio.Value
                files = dir(dirName);
                clear filenames;
                index=1;
                for i=1:numel(files)
                    if ~files(i).isdir
                        filenames{index} = fullfile(dirName, files(i).name);
                        index = index + 1;
                    end
                end
                [meta, files, pixSize] = mibGetImageMetadata(filenames, parameters);
                dimsXYZ(1) = files(1).width;
                dimsXYZ(2) = files(1).height;
                dimsXYZ(3) = 0;
                for i=1:numel(files)
                    dimsXYZ(3) = dimsXYZ(3) + files(i).noLayers;
                end
            elseif obj.View.handles.fileRadio.Value
                [meta, files, pixSize] = mibGetImageMetadata(cellstr(dirName), parameters);
                dimsXYZ(1) = files(1).width;
                dimsXYZ(2) = files(1).height;
                dimsXYZ(3) = 0;
                for i=1:numel(files)
                    dimsXYZ(3) = dimsXYZ(3) + files(i).noLayers;
                end
            elseif obj.View.handles.importRadio.Value
                imgInfoVar = obj.View.handles.imageInfoEdit.String;
                pathIn = obj.View.handles.pathEdit.String;
                try %#ok<TRYNC>
                    img = evalin('base', pathIn);
                    if numel(size(img)) == 3 && size(img, 3) > 3    % reshape original dataset to w:h:color:z
                        dimsXYZ(1) = size(img, 2);
                        dimsXYZ(2) = size(img, 1);
                        dimsXYZ(3) = size(img, 3);
                    else
                        dimsXYZ(1) = size(img, 2);
                        dimsXYZ(2) = size(img, 1);
                        dimsXYZ(3) = size(img, 4);
                    end;
                    if ~isempty(imgInfoVar)
                        meta = evalin('base', imgInfoVar);
                    else
                        meta = containers.Map;
                    end
                end
                files = struct();
                pixSize = struct();
                meta = NaN;
                dimsXYZ = NaN;
            end
        end
        
        function radioButton_Callback(obj)
            % function radioButton_Callback(obj)
            % callback for selection of radio buttons:
            % obj.View.handles.dirRadio; .fileRadio; .importRadio in the Second stack panel 
            if obj.View.handles.dirRadio.Value
                obj.View.handles.pathEdit.String = obj.pathstr;
                obj.View.handles.imageInfoEdit.Enable = 'off';
                obj.View.handles.secondDatasetPath.String = 'Path:';
            elseif obj.View.handles.fileRadio.Value
                obj.View.handles.pathEdit.String = obj.pathstr;
                obj.View.handles.imageInfoEdit.Enable = 'off';
                obj.View.handles.secondDatasetPath.String = 'Filename:';
            elseif obj.View.handles.importRadio.Value
                obj.pathstr = obj.View.handles.pathEdit.String;
                obj.View.handles.pathEdit.String = obj.varname;
                obj.View.handles.secondDatasetPath.String = 'Variable in the main Matlab workspace:';
                obj.View.handles.imageInfoEdit.Enable = 'on';
            end
            obj.selectButton_Callback();
        end
        
        function getSearchWindow_Callback(obj)
            % function getSearchWindow_Callback(obj)
            % callback from getSearchWindow button to define area to be
            % used for alignment
            sel = cell2mat(obj.mibModel.getData2D('selection'));
            STATS = regionprops(sel, 'BoundingBox');
            if numel(STATS) == 0
                msgbox('No selection layer present in the current slice!','Error','err');
                return;
            end
            STATS = STATS(1);
            
            obj.View.handles.searchXminEdit.String = num2str(ceil(STATS.BoundingBox(1)));
            obj.View.handles.searchYminEdit.String = num2str(ceil(STATS.BoundingBox(2)));
            obj.View.handles.searchXmaxEdit.String = num2str(ceil(STATS.BoundingBox(1)) + STATS.BoundingBox(3) - 1);
            obj.View.handles.searchYmaxEdit.String = num2str(ceil(STATS.BoundingBox(2)) + STATS.BoundingBox(4) - 1);
        end
        
        function loadShiftsCheck_Callback(obj)
            % function loadShiftsCheck_Callback(obj)
            % --- Executes on button press in loadShiftsCheck.
            if obj.View.handles.loadShiftsCheck.Value
                startingPath = obj.View.handles.loadShiftsXYpath.String;
                [FileName, PathName] = uigetfile({'*.coefXY','*.coefXY (Matlab format)'; '*.*','All Files'}, 'Select file...', startingPath);
                if FileName == 0; obj.View.handles.loadShiftsCheck.Value = 0; return; end;
                obj.View.handles.loadShiftsXYpath.String = fullfile(PathName, FileName);
                obj.View.handles.loadShiftsXYpath.Enable = 'on';
                var = load(fullfile(PathName, FileName), '-mat');
                obj.shiftsX = var.shiftsX;
                obj.shiftsY = var.shiftsY;
            else
                obj.View.handles.loadShiftsXYpath.Enable = 'off';
            end
        end
        
        function subwindowEdit_Callback(obj)
            % function subwindowEdit_Callback(obj)
            % callback for change of subwindow edit boxes
            x1 = str2double(obj.View.handles.searchXminEdit.String);
            y1 = str2double(obj.View.handles.searchYminEdit.String);
            x2 = str2double(obj.View.handles.searchXmaxEdit.String);
            y2 = str2double(obj.View.handles.searchYmaxEdit.String);
            if x1 < 1 || x1 > obj.mibModel.I{obj.mibModel.Id}.width
                errordlg(sprintf('!!! Error !!!\n\nThe minY value should be between 1 and %d!', obj.mibModel.I{obj.mibModel.Id}.width), 'Wrong X min');
                obj.View.handles.searchXminEdit.String = '1';
                return;
            end
            if y1 < 1 || y1 > obj.mibModel.I{obj.mibModel.Id}.height
                errordlg(sprintf('!!! Error !!!\n\nThe minY value should be between 1 and %d!', obj.mibModel.I{obj.mibModel.Id}.height), 'Wrong Y min');
                obj.View.handles.searchYminEdit.String = '1';
                return;
            end
            if x2 < 1 || x2 > obj.mibModel.I{obj.mibModel.Id}.width
                errordlg(sprintf('!!! Error !!!\n\nThe maxX value should be smaller than %d!', obj.mibModel.I{obj.mibModel.Id}.width),'Wrong X max');
                obj.View.handles.searchXmaxEdit.String = num2str(obj.mibModel.I{obj.mibModel.Id}.width);
                return;
            end
            if y2 < 1 || y2 > obj.mibModel.I{obj.mibModel.Id}.height
                errordlg(sprintf('!!! Error !!!\n\nThe maxY value should be between 1 and %d!', obj.mibModel.I{obj.mibModel.Id}.height),'Wrong Y max');
                obj.View.handles.searchYmaxEdit.String = num2str(obj.mibModel.I{obj.mibModel.Id}.height);
                return;
            end
        end
        
        function maskCheck_Callback(obj)
            % function maskCheck_Callback(obj)
            % --- Executes on button press in maskCheck
            
            val = obj.View.handles.maskCheck.Value;
            if val == 1     % disable subwindow mode
                button = questdlg(sprintf('Would you like to use Mask or Selection layer for alignment?'), ...
                    'Mask or Selection', 'Selection', 'Mask', 'Cancel', 'Selection');
                if strcmp(button, 'Cancel'); obj.View.handles.maskCheck.Value = 0; end
                obj.maskOrSelection = lower(button);
            end
        end
        
        function continueBtn_Callback(obj)
            % function continueBtn_Callback(obj)
            % --- Executes on button press in continueBtn and does alignment
            global mibPath;
            
            tic
            parameters.waitbar = waitbar(0, 'Please wait...', 'Name', 'Alignment and drift correction');
            
            %handles.output = get(hObject,'String');
            pathIn = obj.View.handles.pathEdit.String;
            colorCh = obj.View.handles.colChPopup.Value;
            
            % get color to fill background
            if obj.View.handles.bgWhiteRadio.Value
                parameters.backgroundColor = 'white';
            elseif obj.View.handles.bgBlackRadio.Value
                parameters.backgroundColor = 'black';
            elseif obj.View.handles.bgMeanRadio.Value
                parameters.backgroundColor = 'mean';
            else
                parameters.backgroundColor = str2double(obj.View.handles.bgCustomEdit.String);
                obj.files(1).backgroundColor = parameters.backgroundColor;
            end
            
            parameters.refFrame = obj.View.handles.correlateWithPopup.Value - 1;
            if parameters.refFrame == 2
                parameters.refFrame = -str2double(obj.View.handles.stepEditbox.String);
            end
            
            algorithmText = obj.View.handles.methodPopup.String;
            parameters.method = algorithmText{obj.View.handles.methodPopup.Value};
            
            [Height, Width, Color, Depth, Time] = obj.mibModel.getImageMethod('getDatasetDimensions');
            
            optionsGetData.blockModeSwitch = 0;
            if obj.View.handles.singleStacksModeRadio.Value   % align the currently opened dataset
                if strcmp(parameters.method, 'Single landmark point')
                    obj.shiftsX = zeros(1, Depth);
                    obj.shiftsY = zeros(1, Depth);
                    
                    shiftX = 0;     % shift vs 1st slice in X
                    shiftY = 0;     % shift vs 1st slice in Y
                    STATS1 = struct([]);
                    for layer=2:Depth
                        if isempty(STATS1)
                            prevLayer = cell2mat(obj.mibModel.getData2D('selection', layer-1, NaN, NaN, optionsGetData));
                            STATS1 = regionprops(prevLayer, 'Centroid');
                        end
                        if ~isempty(STATS1)
                            currLayer = cell2mat(obj.mibModel.getData2D('selection', layer, NaN, NaN, optionsGetData));
                            STATS2 = regionprops(currLayer, 'Centroid');
                            if ~isempty(STATS2)  % no second landmark found
                                shiftX = shiftX + round(STATS1.Centroid(1) - STATS2.Centroid(1));
                                shiftY = shiftY + round(STATS1.Centroid(2) - STATS2.Centroid(2));
                                obj.shiftsX(layer:end) = shiftX;
                                obj.shiftsY(layer:end) = shiftY;
                                STATS1 = STATS2;
                            else
                                STATS1 = struct([]);
                            end
                        else
                            STATS1 = struct([]);
                        end
                    end
                    
                    toc
                    
                    figure(155);
                    plot(1:length(obj.shiftsX), obj.shiftsX, 1:length(obj.shiftsY), obj.shiftsY);
                    legend('Shift X', 'Shift Y');
                    grid;
                    xlabel('Frame number');
                    ylabel('Displacement');
                    title('Detected drifts');
                    
                    if ~isdeployed 
                        assignin('base', 'shiftX', obj.shiftsX);
                        assignin('base', 'shiftY', obj.shiftsY);
                        fprintf('Shifts between images were exported to the Matlab workspace (shiftX, shiftY)\nThese variables can be modified and saved to a disk using the following command:\nsave ''myfile.mat'' shiftX shiftY;\n');
                    end
                    
                    fixDrifts = questdlg('Align the stack using detected displacements?', 'Fix drifts', 'Yes', 'No', 'Yes');
                    if strcmp(fixDrifts, 'No')
                        delete(parameters.waitbar);
                        return;
                    end
                    delete(155);
                    
                    % do alignment
                    obj.mibModel.getImageMethod('clearSelection');
                    
                    img = mibCrossShiftStack(cell2mat(obj.mibModel.getData4D('image', NaN, 0, optionsGetData)), obj.shiftsX, obj.shiftsY, parameters);
                    obj.mibModel.setData4D('image', img, NaN, 0, optionsGetData);
                elseif strcmp(parameters.method, 'Three landmark points')
                    obj.shiftsX = zeros(1, Depth);
                    obj.shiftsY = zeros(1, Depth);
                    
                    layer = 1;
                    while layer <= Depth-1
                        currImg = cell2mat(obj.mibModel.getData2D('selection', layer, NaN, NaN, optionsGetData));
                        if sum(sum(currImg)) > 0   % landmark is found
                            CC1 = bwconncomp(currImg);
                            
                            if CC1.NumObjects < 3; continue; end  % require 3 points
                            CC2 = bwconncomp(cell2mat(obj.mibModel.getData2D('selection', layer+1, NaN, NaN, optionsGetData)));
                            if CC2.NumObjects < 3; layer = layer + 1; continue; end  % require 3 points
                            
                            STATS1 = regionprops(CC1, 'Centroid');
                            STATS2 = regionprops(CC2, 'Centroid');
                            
                            % find distances between centroids of material 1 and material 2
                            X1 =  reshape([STATS1.Centroid], [2 numel(STATS1)])';     % centroids matrix, c1([x,y], pointNumber)
                            X2 =  reshape([STATS2.Centroid], [2 numel(STATS1)])';
                            idx = mibAlignmentController.findMatchingPairs(X2, X1);
                            
                            output = reshape([STATS1.Centroid], [2 numel(STATS1)])';     % main dataset points, centroids matrix, c1(pointNumber, [x,y])
                            for objId = 1:numel(STATS2)
                                input(objId, :) = STATS2(idx(objId)).Centroid; % the second dataset points, centroids matrix, c1(pointNumber, [x,y])
                            end
                            
                            % define background color
                            if isnumeric(parameters.backgroundColor)
                                backgroundColor = options.backgroundColor;
                            else
                                if strcmp(parameters.backgroundColor,'black')
                                    backgroundColor = 0;
                                elseif strcmp(parameters.backgroundColor,'white')
                                    backgroundColor = intmax(class(obj.mibModel.I{obj.mibModel.Id}.img{1}));
                                else
                                    backgroundColor = mean(mean(cell2mat(obj.mibModel.getData2D('image', layer, NaN, colorCh, optionsGetData))));
                                end
                            end
                            
                            tform2 = maketform('affine', input, output);    % fitgeotrans: see below for the test
                            % define boundaries for datasets to take, note that the .x, .y, .z are numbers after transpose of the dataset
                            optionsGetData.x = [1, Width];
                            optionsGetData.y = [1, Height];
                            optionsGetData.z = [layer+1, Depth];
                            optionsGetData2.blockModeSwitch = 0;
                            optionsGetData2.x = [1, Width];
                            optionsGetData2.y = [1, Height];
                            optionsGetData2.z = [1, layer];
                            
                            [T, xdata, ydata] = imtransform(cell2mat(obj.mibModel.getData4D('image', NaN, 0, optionsGetData)), ...
                                tform2, 'bicubic', 'FillValues', double(backgroundColor));  % imwarp: see below for the test
                            if xdata(1) < 1
                                obj.shiftsX = floor(xdata(1));
                            else
                                obj.shiftsX = ceil(xdata(1));
                            end
                            if ydata(1) < 1
                                obj.shiftsY = floor(ydata(1))-1;
                            else
                                obj.shiftsY = ceil(ydata(1))-1;
                            end
                            
                            
                            %                 %tform2 = fitgeotrans(output, input, 'affine');
                            %                 tform2 = fitgeotrans(output, input, 'NonreflectiveSimilarity');
                            %
                            %                 [T, RB] = imwarp(handles.I.img(:,:,:,layer+1:end), tform2, 'bicubic', 'FillValues', backgroundColor);
                            %                 if RB.XWorldLimits(1) <  1
                            %                     obj.shiftsX = floor(RB.XWorldLimits(1));
                            %                 else
                            %                     obj.shiftsX = ceil(RB.XWorldLimits(1));
                            %                 end
                            %                 if RB.YWorldLimits(1) < 1
                            %                     obj.shiftsY = floor(RB.YWorldLimits(1))-1;
                            %                 else
                            %                     obj.shiftsY = ceil(RB.YWorldLimits(1))-1;
                            %                 end
                            
                            [img, bbShiftXY] = mibCrossShiftStacks(cell2mat(obj.mibModel.getData4D('image', NaN, 0, optionsGetData2)), T, obj.shiftsX, obj.shiftsY, parameters);
                            if isempty(img);   return; end
                            optionsSetData.blockModeSwitch = 0;
                            obj.mibModel.setData4D('image', img, NaN, 0, optionsSetData);
                            
                            layerId = layer;
                            layer = Depth;
                        end
                        layer = layer + 1;
                    end
                else        % standard alignement
                    %parameters.step = str2double(obj.View.handles.stepEditbox,'string'));
                    
                    % calculate shifts
                    if isempty(obj.shiftsX)
                        if obj.View.handles.subWindowCheck.Value == 1
                            optionsGetData.x(1) = str2double(obj.View.handles.searchXminEdit.String);
                            optionsGetData.x(2) = str2double(obj.View.handles.searchXmaxEdit.String);
                            optionsGetData.y(1) = str2double(obj.View.handles.searchYminEdit.String);
                            optionsGetData.y(2) = str2double(obj.View.handles.searchYmaxEdit.String);
                            optionsGetData.z(1) = 1;
                            optionsGetData.z(2) = Depth;
                            I = squeeze(cell2mat(obj.mibModel.getData4D('image', NaN, colorCh, optionsGetData)));
                            optionsGetData = rmfield(optionsGetData, 'x');
                            optionsGetData = rmfield(optionsGetData, 'y');
                            optionsGetData = rmfield(optionsGetData, 'z');
                            %I = squeeze(handles.I.img(y1:y2, x1:x2, colorCh, :, handles.I.slices{5}(1)));
                        else
                            %I = squeeze(handles.I.img(:, :, colorCh, :, handles.I.slices{5}(1)));
                            I = squeeze(cell2mat(obj.mibModel.getData4D('image', NaN, colorCh, optionsGetData)));
                        end
                        
                        if obj.View.handles.maskCheck.Value == 1
                            waitbar(0, parameters.waitbar, sprintf('Extracting masked areas\nPlease wait...'));
                            %intensityShift =  mean(I(:));   % needed for better correlation of images of different size
                            img = zeros(size(I), class(I));% + intensityShift;
                            bb = nan([size(I, 3), 4]);
                            
                            for slice = 1:size(I, 3)
                                mask = cell2mat(obj.mibModel.getData2D(obj.maskOrSelection, slice, NaN, NaN, optionsGetData));
                                stats = regionprops(mask, 'BoundingBox');
                                if numel(stats) == 0; continue; end
                                
                                currBB = ceil(stats.BoundingBox);
                                mask = mask(currBB(2):currBB(2)+currBB(4)-1, currBB(1):currBB(1)+currBB(3)-1);
                                currImg = I(currBB(2):currBB(2)+currBB(4)-1, currBB(1):currBB(1)+currBB(3)-1, slice);
                                intensityShift = mean(mean(currImg));  % needed for better correlation of images of different size
                                currImg(~mask) = intensityShift;
                                img(:, :, slice) = intensityShift;
                                img(1:currBB(4), 1:currBB(3), slice) = currImg;
                                
                                bb(slice, :) = currBB;
                                waitbar(slice/size(I, 3), parameters.waitbar);
                            end
                            sliceIndices = find(~isnan(bb(:,1)));   % find indices of slices that have mask
                            if isempty(sliceIndices)
                                delete(parameters.waitbar);
                                errordlg(sprintf('No %s areas were found!', obj.maskOrSelection), sprintf('Missing %s',obj.maskOrSelection));
                                return;
                            end
                            I = img(1:max(bb(:, 4)), 1:max(bb(:, 3)), sliceIndices);
                            clear img;
                        end
                        
                        if obj.View.handles.gradientCheckBox.Value
                            waitbar(0, parameters.waitbar, sprintf('Calculating intensity gradient for color channel %d ...', colorCh));
                            
                            img = zeros(size(I), class(I));
                            % generate gradient image
                            hy = fspecial('sobel');
                            hx = hy';
                            for slice = 1:size(I, 3)
                                Im = I(:,:,slice);   % get a slice
                                Iy = imfilter(double(Im), hy, 'replicate');
                                Ix = imfilter(double(Im), hx, 'replicate');
                                img(:,:,slice) = sqrt(Ix.^2 + Iy.^2);
                                waitbar(slice/size(I, 3), parameters.waitbar);
                            end
                            I = img;
                            clear img;
                        end
                        
                        % calculate drifts
                        [shiftX, shiftY] = mibCalcShifts(I, parameters);
                        if isempty(shiftX); return; end
                        
                        if obj.View.handles.maskCheck.Value == 1
                            % check for missing mask slices
                            if length(sliceIndices) ~= Depth
                                shX = zeros([Depth, 1]);
                                shY = zeros([Depth, 1]);
                                
                                index = 1;
                                breakBegin = 0;
                                for i=2:Depth
                                    if isnan(bb(i,1))
                                        if breakBegin == 0
                                            breakBegin = 1;
                                            shX(i) = shX(i-1);
                                            shY(i) = shY(i-1);
                                        else
                                            shX(i) = shX(i-1);
                                            shY(i) = shY(i-1);
                                        end
                                    else
                                        if breakBegin == 1
                                            shX(i) = shX(i-1);
                                            shY(i) = shY(i-1);
                                            breakBegin = 0;
                                        else
                                            if index > 1
                                                shX(i) = shX(i-1) + shiftX(index)-shiftX(index-1)-(bb(i,1)-bb(i-1,1));
                                                shY(i) = shY(i-1) + shiftY(index)-shiftY(index-1)-(bb(i,2)-bb(i-1,2));
                                            else
                                                shX(i) = shX(i-1) + shiftX(index)-(bb(i,1)-bb(i-1,1));
                                                shY(i) = shY(i-1) + shiftY(index)-(bb(i,2)-bb(i-1,2));
                                            end
                                        end
                                        index = index + 1;
                                    end
                                end
                                shiftX = shX;
                                shiftY = shY;
                            else
                                difX = [0; diff(bb(:,1))];
                                difX = cumsum(difX);
                                shiftX = shiftX - difX;
                                difY = [0; diff(bb(:,2))];
                                difY = cumsum(difY);
                                shiftY = shiftY - difY;
                            end
                        end
                        
                        %             % ---- start of drift problems correction
                        figure(155);
                        %subplot(2,1,1);
                        plot(1:length(shiftX), shiftX, 1:length(shiftY), shiftY);
                        %plot(1:length(shiftX), shiftX, 1:length(shiftX), windv(shiftX, 25), 1:length(shiftX), shiftX2);
                        legend('Shift X', 'Shift Y');
                        %legend('Shift X', 'Smoothed 50 pnts window', 'Final shifts');
                        grid;
                        xlabel('Frame number');
                        ylabel('Displacement');
                        title('Before drift correction');
                        %
                        %             fixDrifts = questdlg('Fix the drifts?','Fix drifts','No','Yes','No');
                        %             if strcmp(fixDrifts, 'Yes')
                        %                 diffX = abs(diff(shiftX));
                        %                 diffY = abs(diff(shiftY));
                        %                 cutX = mean(diffX)*4;
                        %                 cutY = mean(diffY)*4;
                        %
                        %                 indX = find(diffX > cutX);
                        %                 indY = find(diffY > cutY);
                        %
                        %                 windvValue = 3;
                        %                 shiftX2 = round(windv(shiftX,windvValue+2));
                        %                 shiftY2 = round(windv(shiftY,windvValue+2));
                        %
                        %                 for i=1:length(indX)
                        %                     shiftX2(indX(i)) = shiftX2(indX(i)-1);
                        %                 end
                        %                 for i=1:length(indY)
                        %                     shiftY2(indY(i)) = shiftY2(indY(i)-1);
                        %                 end
                        %
                        %                 shiftX2 = round(windv(shiftX2, windvValue));
                        %                 shiftY2 = round(windv(shiftY2, windvValue));
                        %
                        %                 subplot(2,1,2);
                        %                 plot(1:length(shiftX2),shiftX2,1:length(shiftY2),shiftY2);
                        %                 legend('Shift X', 'Shift Y');
                        %                 title('After drift correction');
                        %                 grid;
                        %                 xlabel('Frame number');
                        %                 ylabel('Displacement');
                        %
                        %                 fixDrifts = questdlg('Would you like to use the fixed drifts?','Use fixed drifts?','Use fixed','Use not fixed','Cancel','Use fixed');
                        %                 if strcmp(fixDrifts, 'Cancel');
                        %                     if isdeployed == 0
                        %                         assignin('base', 'shiftX', shiftX);
                        %                         assignin('base', 'shiftY', shiftY);
                        %                         disp('Shifts between images were exported to the Matlab workspace (shiftX, shiftY)');
                        %                     end
                        %                     return;
                        %                 end;
                        %
                        %                 if strcmp(fixDrifts, 'Use fixed');
                        %                     shiftX = shiftX2;
                        %                     shiftY = shiftY2;
                        %                 end;
                        %             end
                        %             delete(155);    % close the figure window
                        %
                        %             % ---- end of drift problems correction
                        
                        
                        fixDrifts = questdlg('Align the stack using detected displacements?','Fix drifts','Yes','Subtract running average','No','Yes');
                        if strcmp(fixDrifts, 'No')
                            if isdeployed == 0
                                assignin('base', 'shiftX', shiftX);
                                assignin('base', 'shiftY', shiftY);
                                fprintf('Shifts between images were exported to the Matlab workspace (shiftX, shiftY)\nThese variables can be modified and saved to a disk using the following command:\nsave ''myfile.mat'' shiftX shiftY;\n');
                            end
                            delete(parameters.waitbar);
                            return;
                        end
                        
                        if strcmp(fixDrifts, 'Subtract running average')
                            notOk = 1;
                            while notOk
                                answer = mibInputDlg({mibPath}, ...
                                    sprintf('Please enter half-width of the averaging window:'),...
                                    'Running average', '25');
                                if isempty(answer)
                                    delete(parameters.waitbar);
                                    return;
                                end
                                halfwidth = str2double(answer{1});
                                % testing running average
                                shiftX2 = round(shiftX-windv(shiftX, halfwidth));
                                shiftY2 = round(shiftY-windv(shiftY, halfwidth));
                                
                                figure(155);
                                subplot(2,1,1)
                                plot(1:length(shiftX), shiftX, 1:length(shiftX), windv(shiftX, halfwidth), 1:length(shiftX), shiftX2);
                                legend('Shift X', 'Smoothed', 'Final shifts');
                                grid;
                                xlabel('Frame number');
                                ylabel('Displacement');
                                title('X coordinate');
                                subplot(2,1,2)
                                plot(1:length(shiftY), shiftY, 1:length(shiftY), windv(shiftY, halfwidth), 1:length(shiftY), shiftY2);
                                legend('Shift X', 'Smoothed', 'Final shifts');
                                grid;
                                xlabel('Frame number');
                                ylabel('Displacement');
                                title('X coordinate');
                                
                                fixDrifts = questdlg('Align the stack using detected displacements?','Fix drifts','Yes','Change window size','No','Yes');
                                if strcmp(fixDrifts, 'No')
                                    if isdeployed == 0
                                        assignin('base', 'shiftX', shiftX);
                                        assignin('base', 'shiftY', shiftY);
                                        fprintf('Shifts between images were exported to the Matlab workspace (shiftX, shiftY)\nThese variables can be modified and saved to a disk using the following command:\nsave ''myfile.mat'' shiftX shiftY;\n');
                                    end
                                    delete(parameters.waitbar);
                                    return;
                                end
                                if strcmp(fixDrifts, 'Yes')
                                    shiftX = shiftX2;
                                    shiftY = shiftY2;
                                    notOk = 0;
                                end
                            end
                        end
                        delete(155);
                        
                        % exporting shifts to Matlab
                        if isdeployed == 0
                            assignin('base', 'shiftX', shiftX);
                            assignin('base', 'shiftY', shiftY);
                            fprintf('Shifts between images were exported to the Matlab workspace (shiftX, shiftY)\nThese variables can be modified and saved to a disk using the following command:\nsave ''myfile.mat'' shiftX shiftY;\n');
                        end
                        
                        obj.shiftsX = shiftX;
                        obj.shiftsY = shiftY;
                    end
                    waitbar(0, parameters.waitbar, sprintf('Aligning the images\nPlease wait...'));
                    
                    %img = mib_crossShiftStack(handles.I.img, obj.shiftsX, obj.shiftsY, parameters);
                    img = mibCrossShiftStack(cell2mat(obj.mibModel.getData4D('image', NaN, 0)), obj.shiftsX, obj.shiftsY, parameters);
                    if isempty(img); return; end
                    obj.mibModel.setData4D('image', img, NaN, 0);
                end
                
                % aligning the service layers: mask, selection, model
                % force background color to be black for the service layers
                % if the background needs to be selected, the parameters.backgroundColor = 'white'; should be used for selection layer
                parameters.backgroundColor = 0;
                parameters.modelSwitch = 1;
                
                if obj.mibModel.getImageProperty('modelType') ~= 63
                    if obj.mibModel.getImageProperty('modelExist')
                        waitbar(0, parameters.waitbar, sprintf('Aligning model\nPlease wait...'));
                        if ~strcmp(parameters.method, 'Three landmark points')
                            img = mibCrossShiftStack(cell2mat(obj.mibModel.getData4D('model', NaN, 0, optionsGetData)), obj.shiftsX, obj.shiftsY, parameters);
                            obj.mibModel.setData4D('model', img, NaN, 0, optionsGetData);
                        else
                            T = imtransform(cell2mat(obj.mibModel.getData4D('model', NaN, 0, optionsGetData)), tform2, 'nearest');
                            img = mibCrossShiftStacks(cell2mat(obj.mibModel.getData4D('model', NaN, 0, optionsGetData2)), T, obj.shiftsX, obj.shiftsY, parameters);
                            obj.mibModel.setData4D('model', img, NaN, 0, optionsSetData);
                        end
                    end
                    if obj.mibModel.getImageProperty('maskExist')
                        waitbar(0, parameters.waitbar, sprintf('Aligning mask...\nPlease wait...'));
                        if ~strcmp(parameters.method, 'Three landmark points')
                            img = mibCrossShiftStack(cell2mat(obj.mibModel.getData4D('mask', NaN, 0, optionsGetData)), obj.shiftsX, obj.shiftsY, parameters);
                            obj.mibModel.setData4D('mask', img, NaN, 0, optionsGetData);
                        else
                            T = imtransform(cell2mat(obj.mibModel.getData4D('mask', NaN, 0, optionsGetData)), tform2, 'nearest');
                            img = mibCrossShiftStacks(cell2mat(obj.mibModel.getData4D('mask', NaN, 0, optionsGetData2)), T, obj.shiftsX, obj.shiftsY, parameters);
                            obj.mibModel.setData4D('mask', img, NaN, 0, optionsSetData);
                        end
                    end
                    if  ~isnan(obj.mibModel.I{obj.mibModel.Id}.selection{1}(1))
                        waitbar(0, parameters.waitbar, sprintf('Aligning selection...\nPlease wait...'));
                        if ~strcmp(parameters.method, 'Three landmark points')
                            img = mibCrossShiftStack(cell2mat(obj.mibModel.getData4D('selection', NaN, 0, optionsGetData)), obj.shiftsX, obj.shiftsY, parameters);
                            obj.mibModel.I.setData4D('selection', img, NaN, 0, optionsGetData);
                        else
                            T = imtransform(cell2mat(obj.mibModel.getData4D('selection', NaN, 0, optionsGetData)), tform2, 'nearest');
                            img = mibCrossShiftStacks(cell2mat(obj.mibModel.getData4D('selection', NaN, 0, optionsGetData2)), T, obj.shiftsX, obj.shiftsY, parameters);
                            obj.mibModel.setData4D('selection', img, NaN, 0, optionsSetData);
                        end
                    end
                else
                    waitbar(0, parameters.waitbar, sprintf('Aligning Selection, Mask, Model...\nPlease wait...'));
                    if ~strcmp(parameters.method, 'Three landmark points')
                        img = mibCrossShiftStack(cell2mat(obj.mibModel.getData4D('everything', NaN, 0, optionsGetData)), obj.shiftsX, obj.shiftsY, parameters);
                        obj.mibModel.setData4D('everything', img, NaN, 0, optionsGetData);
                    else
                        %T = imwarp(handles.I.model(:,:,layerId+1:end), tform2, 'nearest', 'FillValues', parameters.backgroundColor);
                        %handles.I.model = mib_crossShiftStacks(handles.I.model(:,:,1:layerId), T, obj.shiftsX, obj.shiftsY, parameters);
                        
                        T = imtransform(cell2mat(obj.mibModel.getData4D('everything', NaN, 0, optionsGetData)), tform2, 'nearest');
                        img = mibCrossShiftStacks(cell2mat(obj.mibModel.getData4D('everything', NaN, 0, optionsGetData2)), T, obj.shiftsX, obj.shiftsY, parameters);
                        obj.mibModel.setData4D('everything', img, NaN, 0, optionsSetData);
                    end
                end
                
                obj.mibModel.I{obj.mibModel.Id}.height = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 1);
                obj.mibModel.I{obj.mibModel.Id}.width = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 2);
                oldSlices = obj.mibModel.I{obj.mibModel.Id}.slices;
                obj.mibModel.I{obj.mibModel.Id}.slices{1} = [1, obj.mibModel.I{obj.mibModel.Id}.height];
                obj.mibModel.I{obj.mibModel.Id}.slices{2} = [1, obj.mibModel.I{obj.mibModel.Id}.width];
                obj.mibModel.I{obj.mibModel.Id}.slices{3} = 1:size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 3);
                obj.mibModel.I{obj.mibModel.Id}.slices{4} = [1, 1];
                obj.mibModel.I{obj.mibModel.Id}.slices{5} = [1, 1];
                obj.mibModel.I{obj.mibModel.Id}.slices{obj.mibModel.I{obj.mibModel.Id}.orientation} = ...
                    [oldSlices{obj.mibModel.I{obj.mibModel.Id}.orientation}, oldSlices{obj.mibModel.I{obj.mibModel.Id}.orientation}];
                
                % calculate shift of the bounding box
                maxXshift =  min(obj.shiftsX);   % maximal X shift in pixels vs the first slice
                maxYshift = min(obj.shiftsY);   % maximal Y shift in pixels vs the first slice
                if obj.mibModel.I{obj.mibModel.Id}.orientation == 4
                    maxXshift = maxXshift*obj.mibModel.I{obj.mibModel.Id}.pixSize.x;  % X shift in units vs the first slice
                    maxYshift = maxYshift*obj.mibModel.I{obj.mibModel.Id}.pixSize.y;  % Y shift in units vs the first slice
                    maxZshift = 0;
                elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 2
                    maxYshift = maxYshift*obj.mibModel.I{obj.mibModel.Id}.pixSize.y;  % Y shift in units vs the first slice
                    maxZshift = maxXshift*obj.mibModel.I{obj.mibModel.Id}.pixSize.z;  % X shift in units vs the first slice;
                    maxXshift = 0;
                elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 1
                    maxXshift = maxXshift*obj.mibModel.I{obj.mibModel.Id}.pixSize.y;  % X shift in units vs the first slice
                    maxZshift = maxXshift*obj.mibModel.I{obj.mibModel.Id}.pixSize.z;
                    maxYshift = 0;                              % Y shift in units vs the first slice
                end
                obj.mibModel.I{obj.mibModel.Id}.updateBoundingBox(NaN, [maxXshift, maxYshift, maxZshift]);
                obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(sprintf('Aligned using %s; relative to %d', algorithmText{obj.View.handles.methodPopup.Value}, parameters.refFrame));
                
                if obj.View.handles.saveShiftsCheck.Value     % use preexisting parameters
                    fn = obj.View.handles.saveShiftsXYpath.String;
                    shiftsX = obj.shiftsX; %#ok<PROP,NASGU>
                    shiftsY = obj.shiftsY; %#ok<PROP,NASGU>
                    save(fn, 'shiftsX', 'shiftsY');
                end
            else        % align two stacks
                if obj.mibModel.I{obj.mibModel.Id}.orientation ~= 4
                    errordlg(sprintf('!!! Error !!!\n\nThe alignement of two separate datasets is only possible in the XY mode\nPlease turn your dataset into the XY mode using a dedicated button in the toolbar.'),'Wrong orientation');
                    delete(parameters.waitbar);
                    return;
                end
                
                if isempty(fields(obj.files)) && obj.View.handles.importRadio.Value == 0
                    obj.selectButton_Callback();
                end
                if obj.View.handles.dirRadio.Value
                    % loading the datasets
                    [img,  img_info] = mibGetImages(obj.files, obj.meta);
                    waitbar(0, parameters.waitbar, sprintf('Aligning stacks using color channel %d ...', colorCh));
                elseif obj.View.handles.fileRadio.Value
                    [img,  img_info] = mibGetImages(obj.files, obj.meta);
                    waitbar(0, parameters.waitbar, sprintf('Aligning stacks using color channel %d ...', colorCh));
                elseif obj.View.handles.importRadio.Value
                    waitbar(0, parameters.waitbar, sprintf('Aligning stacks using color channel %d ...', colorCh));
                    imgInfoVar = obj.View.handles.imageInfoEdit.String;
                    img = evalin('base', pathIn);
                    if numel(size(img)) == 3 && size(img,3) > 3    % reshape original dataset to w:h:color:z
                        img = reshape(img, size(img,1), size(img,2), 1, size(img,3));
                    end;
                    if ~isempty(imgInfoVar)
                        img_info = evalin('base', imgInfoVar);
                    else
                        img_info = containers.Map;
                    end
                end
                
                [height2, width2, color2, depth2, time2] = size(img);
                dummySelection = zeros(size(img,1), size(img,2), size(img,4), 'uint8');    % dummy variable for resizing mask, model and selection
                
                if obj.View.handles.twoStacksAutoSwitch.Value     % automatic mode
                    w1 = max([size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 2) size(img, 2)]);
                    h1 = max([size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 1) size(img, 1)]);
                    
                    I = zeros([h1, w1, 2], class(obj.mibModel.I{obj.mibModel.Id}.img{1})) + ...
                        mean(mean(obj.mibModel.I{obj.mibModel.Id}.img{1}(:, :, colorCh, end, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1))));
                    I(1:obj.mibModel.I{obj.mibModel.Id}.height, 1:obj.mibModel.I{obj.mibModel.Id}.width, 1) = ...
                        obj.mibModel.I{obj.mibModel.Id}.img{1}(:, :, colorCh, end, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
                    I(1:size(img, 1), 1:size(img, 2), 2) = ...
                        img(:, :, colorCh, 1, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
                    
                    if obj.View.handles.gradientCheckBox.Value
                        % generate gradient image
                        I2 = zeros(size(I), class(I));
                        % generate gradient image
                        hy = fspecial('sobel');
                        hx = hy';
                        for slice = 1:size(I, 3)
                            Im = I(:,:,slice);   % get a slice
                            Iy = imfilter(double(Im), hy, 'replicate');
                            Ix = imfilter(double(Im), hx, 'replicate');
                            I2(:,:,slice) = sqrt(Ix.^2 + Iy.^2);
                        end
                        I = I2;
                        clear I2;
                    end
                    % calculate drifts
                    [shiftX, shiftY] = mibCalcShifts(I, parameters);
                    if isempty(shiftX); return; end;
                    
                    prompt = {sprintf('Would you like to use detected shifts?\n\nX shift:'),'Y shift:'};
                    dlg_title = 'Calculated shifts';
                    defaultans = {num2str(shiftX(2)), num2str(shiftY(2))};
                    answer = inputdlg(prompt, dlg_title, 1, defaultans);
                    if isempty(answer); delete(parameters.waitbar); return; end
                    obj.shiftsX = str2double(answer{1});
                    obj.shiftsY = str2double(answer{2});
                else
                    obj.shiftsX = str2double(obj.View.handles.manualShiftX.String);
                    obj.shiftsY = str2double(obj.View.handles.manualShiftY.String);
                end
                [img, bbShiftXY] = mibCrossShiftStacks(obj.mibModel.I{obj.mibModel.Id}.img{1}, img, obj.shiftsX, obj.shiftsY, parameters);
                if isempty(img);        delete(parameters.waitbar);        return; end;
                obj.mibModel.I{obj.mibModel.Id}.img{1} = img;
                clear img;
                
                obj.mibModel.I{obj.mibModel.Id}.depth = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 4);
                obj.mibModel.I{obj.mibModel.Id}.meta('Depth') = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 4);
                
                % calculate shift of the bounding box
                maxXshift = bbShiftXY(1)*obj.mibModel.I{obj.mibModel.Id}.pixSize.x;  % X shift in units vs the first slice
                maxYshift = bbShiftXY(2)*obj.mibModel.I{obj.mibModel.Id}.pixSize.y;  % Y shift in units vs the first slice
                bb = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
                bb(1:2) = bb(1:2)-maxXshift;
                bb(3:4) = bb(3:4)-maxYshift;
                bb(6) = bb(6)+depth2*obj.mibModel.I{obj.mibModel.Id}.pixSize.z;
                obj.mibModel.I{obj.mibModel.Id}.updateBoundingBox(bb);
                
                obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(sprintf('Aligned two stacks using %s', algorithmText{obj.View.handles.methodPopup.Value}));
                
                % aligning the service layers: mask, selection, model
                % force background color to be black for the service layers
                % if the background needs to be selected, the parameters.backgroundColor = 'white'; should be used for selection layer
                parameters.backgroundColor = 0;
                parameters.modelSwitch = 1;
                
                if obj.mibModel.I{obj.mibModel.Id}.modelType ~= 63
                    if obj.mibModel.getImageProperty('modelExist')
                        waitbar(.5, parameters.waitbar,sprintf('Aligning model\nPlease wait...'));
                        obj.mibModel.I{obj.mibModel.Id}.model{1} = mibCrossShiftStacks(obj.mibModel.I{obj.mibModel.Id}.model{1}, dummySelection, obj.shiftsX, obj.shiftsY, parameters);
                    end
                    if obj.mibModel.getImageProperty('maskExist')
                        waitbar(.5, parameters.waitbar,sprintf('Aligning mask\nPlease wait...'));
                        obj.mibModel.I{obj.mibModel.Id}.maskImg{1} = mibCrossShiftStacks(obj.mibModel.I{obj.mibModel.Id}.maskImg{1}, dummySelection, obj.shiftsX, obj.shiftsY, parameters);
                    end
                    if  ~isnan(obj.mibModel.I{obj.mibModel.Id}.selection{1}(1))
                        waitbar(.5, parameters.waitbar,sprintf('Aligning selection\nPlease wait...'));
                        obj.mibModel.I{obj.mibModel.Id}.selection{1} = mibCrossShiftStacks(obj.mibModel.I{obj.mibModel.Id}.selection{1}, dummySelection, obj.shiftsX, obj.shiftsY, parameters);
                    end
                else
                    waitbar(.5, parameters.waitbar,sprintf('Aligning Selection, Mask, Model\nPlease wait...'));
                    obj.mibModel.I{obj.mibModel.Id}.model{1} = mibCrossShiftStacks(obj.mibModel.I{obj.mibModel.Id}.model{1}, dummySelection, obj.shiftsX, obj.shiftsY, parameters);
                end
                
                % combine SliceNames
                if isKey(obj.mibModel.I{obj.mibModel.Id}.meta, 'SliceName')
                    SN = cell([size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 4), 1]);
                    SN(1:numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'))) = obj.mibModel.I{obj.mibModel.Id}.meta('SliceName');
                    
                    if isKey(img_info, 'SliceName')
                        SN(numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'))+1:end) = img_info('SliceName');
                    else
                        if isKey(img_info, 'Filename')
                            [~, fn, ext] = fileparts(img_info('Filename'));
                            SN(numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'))+1:end) = [fn ext];
                        else
                            SN(numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'))+1:end) = cellstr('noname');
                        end
                    end
                    obj.mibModel.I{obj.mibModel.Id}.meta('SliceName') = SN;
                end
            end
            
            delete(parameters.waitbar);
            
            obj.mibModel.I{obj.mibModel.Id}.width = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 2);
            obj.mibModel.I{obj.mibModel.Id}.height = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 1);
            obj.mibModel.I{obj.mibModel.Id}.colors = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 3);
            obj.mibModel.I{obj.mibModel.Id}.meta('Height') = obj.mibModel.I{obj.mibModel.Id}.height;
            obj.mibModel.I{obj.mibModel.Id}.meta('Width') = obj.mibModel.I{obj.mibModel.Id}.width;
            toc;
            notify(obj.mibModel, 'newDataset');
            notify(obj.mibModel, 'plotImage');

            obj.closeWindow();
        end
    end
end