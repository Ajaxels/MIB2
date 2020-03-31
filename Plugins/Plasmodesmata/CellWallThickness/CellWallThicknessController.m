classdef CellWallThicknessController < handle
    % demo https://youtu.be/dIl1dt_cSqE
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        matlabExportVariable
        % name of variable for export results to Matlab
        outputFormat
        % a string with one of the options:
        % 'Comma-separated values format (*.csv)'
        % 'Matlab format (*.mat)  
        % 'Microscoft Excel (*.xlsx)'
        % 'Both Matlab and CSV formats (*.mat, *.csv)'
        % 'Both Matlab and Excel formats (*.mat, *.xlsx)'};
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
        function obj = CellWallThicknessController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'CellWallThicknessGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % check for the virtual stacking mode and close the controller
            if isprop(obj.mibModel.I{obj.mibModel.Id}, 'Virtual') && obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                obj.closeWindow();
                return;
            end
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            obj.View.gui = moveWindowOutside(obj.View.gui, 'left');
            
            % update font and size
            global Font;
            if ~isempty(Font)
                if obj.View.handles.infoText.FontSize ~= Font.FontSize ...
                        || ~strcmp(obj.View.handles.infoText.FontName, Font.FontName)
                    mibUpdateFontSize(obj.View.gui, Font);
                end
            end
            % help text
            strText = sprintf('Cell wall thickness calculation\n\nPlease make sure that the material is smoothed!!!');
            obj.View.handles.infoText.String = strText;
            obj.matlabExportVariable = 'CellWallThickness';
            
            obj.updateWidgets();
            
            if isdeployed; obj.View.handles.exportMatlabCheck.Enable = 'off'; end
            
            [path, fn] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            obj.View.handles.filenameEdit.String = fullfile(path, [fn '_CellWallThickness.csv']);
            obj.View.handles.filenameEdit.TooltipString = fullfile(path, [fn '_CellWallThickness.csv']);
            
            obj.outputFormat = 'Comma-separated values format (*.csv)';
            
            obj.View.handles.resultImagesDirEdit.String = fullfile(path);
            obj.View.handles.resultImagesDirEdit.TooltipString = fullfile(path);
            
            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing CellWallThicknessController window
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
            
            % populate widgets
            obj.View.handles.material1Popup.Value = 1;
            if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0
                materialsList = {'missing the model'};
                obj.View.handles.material1Popup.Value = 1;
                obj.View.handles.continueBtn.Enable = 'off';
                obj.View.handles.thinBtn.Enable = 'off';
            else
                obj.View.handles.continueBtn.Enable = 'on';
                obj.View.handles.material1Popup.Value = 1;
                materialsList = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames;
                if isempty(materialsList)
                    materialsList = {'please add material to the model'};
                    obj.View.handles.material1Popup.Value = 1;
                    obj.View.handles.continueBtn.Enable = 'off';
                    obj.View.handles.thinBtn.Enable = 'off';
                else
                    obj.View.handles.continueBtn.Enable = 'on';
                    obj.View.handles.thinBtn.Enable = 'on';
                end
            end
            obj.View.handles.material1Popup.String = materialsList;
            
            % update number of annotations
            noLabels = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber();
            obj.View.handles.numAnnotationsText.String = sprintf('Total number of annotations: %d', noLabels);
        end
        
        function exportResultsFilename_Callback(obj)
            formatText = {'*.csv', 'Comma-separated values format (*.csv)';...
                          '*.mat', 'Matlab format (*.mat)';...              
                          '*.xlsx', 'Microscoft Excel (*.xlsx)';...
                          '*.mat; *.csv', 'Both Matlab and CSV formats (*.mat, *.csv)'
                          '*.mat; *.xlsx', 'Both Matlab and Excel formats (*.mat, *.xlsx)'};
            fn_out = obj.View.handles.filenameEdit.String;
            [FileName, PathName, FilterIndex] = ...
                uiputfile(formatText, 'Select filename', fn_out);
            if isequal(FileName, 0) || isequal(PathName, 0); return; end
            
            if FilterIndex == 4 && FilterIndex == 5
                % when saving in both matlab and excel or matlab and csv formats
                % remove file extension
                
                fn_out = fullfile(PathName, FileName);
                [path, fn] = fileparts(fn_out);
                fn_out = fullfile(path, fn);
            else
                fn_out = fullfile(PathName, FileName);
            end
            obj.View.handles.filenameEdit.String = fn_out;
            obj.View.handles.filenameEdit.TooltipString = fn_out;
            obj.outputFormat = formatText{FilterIndex,2};
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
        
        function thinBtn_Callback(obj)
            % preprocess material of the model to thin it and remove small profiles 
            
            % check for existance of mask
            if obj.mibModel.I{obj.mibModel.Id}.maskExist == 1
                answer = questdlg(sprintf('!!! Warning !!!\n\nThe existing mask will be removed\nContinue?'), ...
                    'Current mask will be removed', ...
                    'Continue','Cancel','Cancel');
                if strcmp(answer, 'Cancel'); return; end
            end
            
            wb = waitbar(0, sprintf('Thinning the material and removing short profiles\nThe results will be moved to the mask layer...'));
            materialIndex = obj.View.handles.material1Popup.Value;  % get index of the material for thinning
            
            sliceCounter = 1;   % counter for slices
            maxSlice = obj.mibModel.I{obj.mibModel.Id}.time*obj.mibModel.I{obj.mibModel.Id}.depth;
            getDataOptions.blockModeSwitch = 0;
            obj.mibModel.I{obj.mibModel.Id}.clearMask();
            
            for t=1:obj.mibModel.I{obj.mibModel.Id}.time
                getDataOptions.t = [t, t];
                for z=1:obj.mibModel.I{obj.mibModel.Id}.depth
                    Mask = cell2mat(obj.mibModel.getData2D('model', z, 4, materialIndex, getDataOptions));    % get the mask
                    
                    % thin the objects
                    Mask = bwmorph(Mask, 'thin', Inf);
                    
                    Mask = mibRemoveBranches(Mask);
                    
%                     % remove short profiles
%                     if threshold > 0
%                         Mb = bwmorph(Mask, 'branchpoints', 1);
%                         D = bwdistgeodesic(Mask, Mb, 'quasi-euclidean');
%                         M1 = Mask;
%                         ShortProfiles = zeros(size(Mask), 'uint8');
%                         for endPnt = 1:threshold
%                             Me = bwmorph(M1, 'endpoints', 1);
%                             EndPoints = find(Me);
%                             ShortProfiles(EndPoints(D(EndPoints)<=threshold)) = 1;
%                             M1(EndPoints(D(EndPoints)<=threshold)) = 0;
%                         end
%                         Mask = uint8(Mask) - ShortProfiles;
%                         Mask = bwmorph(Mask, 'thin', 1);    % one additional thinning is needed to eliminate 3 pixel clusters
%                     end
                    obj.mibModel.setData2D('mask', Mask, z, 4, NaN, getDataOptions);    % set the mask
                    sliceCounter = sliceCounter + 1;
                    waitbar(sliceCounter/maxSlice, wb);
                end
            end
            delete(wb);
            notify(obj.mibModel, 'showMask');
            notify(obj.mibModel, 'plotImage');
        end
        
        function useAnnotationsCheck_Callback(obj)
            % function useAnnotationsCheck_Callback(obj)
            % check for presence of annotations
            
            if obj.View.handles.useAnnotationsCheck.Value == 1
                noLabels = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber();
                if noLabels < 1
                    warndlg(sprintf('!!! Warning !!!\n\nThere is no annotations present!\nPlease use the Annotation tool to label the positions of the pores and try again'), ...
                        'Missing annotations');
                    obj.View.handles.useRandomPoresCheck.Value = 0;
                    obj.View.handles.useAnnotationsCheck.Value = 0;
                    obj.View.handles.markDistCheck.Enable = 'off';
                end
                obj.View.handles.removeDataPointsCheck.Enable = 'on';
                obj.View.handles.useRandomPoresCheck.Enable = 'on';
                obj.View.handles.markDistCheck.Enable = 'on';
            else
                obj.View.handles.useRandomPoresCheck.Enable = 'off';
                obj.View.handles.useRandomPoresCheck.Value = 0;
                obj.View.handles.removeDataPointsCheck.Enable = 'off';
                obj.View.handles.markDistCheck.Enable = 'off';
            end
            obj.useRandomPoresCheck_Callback();
        end
        
        function useRandomPoresCheck_Callback(obj)
            % function useRandomPoresCheck_Callback(obj)
            % callback for analysis of the randomly placed pores
            if obj.View.handles.useRandomPoresCheck.Value == 1
                obj.View.handles.randomGeneratorEdit.Enable = 'on';
                obj.View.handles.randomGeneratorText.Enable = 'on';
                %obj.View.handles.markDistCheck.Enable = 'on';
                obj.View.handles.removeSimulatedPointsCheck.Enable = 'on';
            else
                obj.View.handles.randomGeneratorEdit.Enable = 'off';
                obj.View.handles.randomGeneratorText.Enable = 'off';
                %obj.View.handles.markDistCheck.Enable = 'off';
                obj.View.handles.removeSimulatedPointsCheck.Enable = 'off';
                obj.View.handles.removeSimulatedPointsCheck.Value = 0;
            end
        end
        
        function continueBtn_Callback(obj)
            % function continueBtn_Callback(obj)
            % callback for press of continue button
            
            % a structure for results
            CellWallThickness = struct();
            % CellWallThickness.pixSize - pixelSize
            % CellWallThickness.BoundingBox - bounding box of the dataset as [xmin, xmax, ymin, ymax, zmin, zmax]
            % CellWallThickness.maskThinningThreshold  - mask thinning threshold
            % CellWallThickness.filename  - filename of the dataset
            % CellWallThickness.modelFilename - filename of the model
            % CellWallThickness.materialName - name of the analysed material
            % CellWallThickness.maskFilename - mask filename
            % CellWallThickness.RendomGenSeed - index of a seed that was used for the random generator
            % CellWallThickness.allPoints   % get distribution of all points of the cell wall
            % CellWallThickness.allPointsMinusRandomInfo   % switch, whether the random points were removed (=1) from all points or not (=0)
            % CellWallThickness.allPointsMinusDataInfo   % switch, whether the data points were removed (=1) from all points or not (=0)
            % CellWallThickness.closestPoints  % distribution of distances to the pores
            % CellWallThickness.closestPointsPos % positions of the annotations, [index; z,x,y]
            % CellWallThickness.closestPointsLabel % labels for the annotations, cell array
            % CellWallThickness.simulatedClosestPoints  % distribution of the randomly placed points
            % CellWallThickness.simulatedClosestPointsPos % positions of the annotations, [index; z,x,y]
            % CellWallThickness.G % graph with connected points
            
            outFn = obj.View.handles.filenameEdit.String;
            [~, CellWallThickness.filename] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            CellWallThickness.modelFilename = obj.mibModel.I{obj.mibModel.Id}.modelFilename;
            CellWallThickness.maskFilename = obj.mibModel.I{obj.mibModel.Id}.maskImgFilename;
            
            [path, fn, ext] = fileparts(outFn);
                        
            switch obj.outputFormat
                case 'Both Matlab and CSV formats (*.mat, *.csv)'
                    clear outFn;
                    outFn{1} = fullfile(path, [fn '.mat']);
                    outFn{2} = fullfile(path, [fn '.csv']);    
                case 'Both Matlab and Excel formats (*.mat, *.xlsx)'
                    clear outFn;
                    outFn{1} = fullfile(path, [fn '.mat']);
                    outFn{2} = fullfile(path, [fn '.xlsx']);    
                otherwise
                    outFn = {outFn};
            end
            
            % save or not the centerline distance map
            saveCenterLine = obj.View.handles.saveCenterlineCheck.Value;
            
            if obj.View.handles.saveResultsCheck.Value
                % check filename
                for i=1:numel(outFn)
                    if exist(outFn{i}, 'file') == 2
                        strText = sprintf('!!! Warning !!!\n\nThe file:\n%s \nis already exist!\n\nOverwrite?', outFn{i});
                        button = questdlg(strText, 'File exist!','Overwrite', 'Cancel', 'Cancel');
                        if strcmp(button, 'Cancel'); return; end
                        delete(outFn{i});     % delete existing file
                    end
                end
            end
            
            tic
            wb = waitbar(0, sprintf('Calculating\nPlease wait...'), 'Name', 'Cell wall thickness');
            
            materialIndex = obj.View.handles.material1Popup.Value;  % get index of the material for thinning
            materiaName = obj.View.handles.material1Popup.String{materialIndex};
            exportToMatlab = obj.View.handles.exportMatlabCheck.Value;       % export to Matlab switch; handles.matlabExportVariable
            saveToFile = obj.View.handles.saveResultsCheck.Value;            % save to Matlab or Excel file
            analysePores = obj.View.handles.useAnnotationsCheck.Value;       % include or not analysis of pores
            generateRandomPoints = obj.View.handles.useRandomPoresCheck.Value; % generate random points
            randomGenerator = str2double(obj.View.handles.randomGeneratorEdit.String);  % random number generator
            if randomGenerator == 0; randomGenerator = 'shuffle'; end
            plotThickness = obj.View.handles.markDistCheck.Value;   % define calculate (1) or not (0) the closest half-thickness lines
            if analysePores == 0; plotThickness = 0; end
            
            % get pixel sizes
            pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            CellWallThickness.pixSize = pixSize;
            CellWallThickness.BoundingBox = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
            CellWallThickness.allPointsMinusDataInfo = 0;
            CellWallThickness.allPointsMinusRandomInfo = 0;
            CellWallThickness.materialName = materiaName;
            
            % ---- INITIALIZATION -----
            if plotThickness
                % clear 3D lines
                obj.mibModel.I{obj.mibModel.Id}.hLines3D.clearContents();
                sizeAllocCoef = 1; % a coefficient for memory allocation for plotThickness == 1
                if generateRandomPoints == 1; sizeAllocCoef = 2; end
            end
            
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image');
            skel = cell2mat(obj.mibModel.getData3D('mask'));
            distMap = zeros(size(skel));
            if plotThickness
                perimMap = zeros(size(skel), 'uint8');
            end
            
            waitbar(0.03, wb, sprintf('Calculating the distance map\nPlease wait...'));
            for z=1:depth
                if sum(sum(skel(:,:,z))) == 0; continue; end
                model = cell2mat(obj.mibModel.getData2D('model', z, 4, materialIndex));
                
                [distMap(:,:,z), idx] = bwdist(1-model, 'euclidean');
                
                if plotThickness
                    % Warning:
                    % bwperim results in pixels that belong to the object,
                    % while bwdist results in distances that are 1-pixel
                    % outside of the object. To match those to each other
                    % we use here imdilate method
                    
                    % perimMap(:,:,z) = bwperim(model);   % calculate perimeter
                    perimMap(:,:,z) = imdilate(model, ones(3))-model;   % generate perimeter
                end
            end
            
            distMap(skel~=1) = 0;
            % use to see the images:
            % >> imtool(distMap(:,:,100),[]);
            
            allPointsIndices = find(distMap >= 1);    % get indices of the skeleton
            if isempty(allPointsIndices)
                warndlg(sprintf('!!! Warning !!!\n\nNo centerline points were found!\nPlease make sure that the cell wall is thinned and assigned to the mask layer!'), 'Missing the centerline');
                delete(wb);
                return;
            end
            noOfAllPointsIndices = numel(allPointsIndices);
            
            if analysePores
                waitbar(0.4, wb, sprintf('Calculating the closest points\nPlease wait...'));
                % get labels for the pores
                [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels;
                % labelPositions:   a matrix with coordinates of the labels [labelIndex, z x y t]
                
                if plotThickness
                    graphPointsVec = zeros([numel(labelsList)*2*sizeAllocCoef, 3]);   % allocate space for coordinates of nodes
                    s = zeros([numel(labelsList)*sizeAllocCoef, 1]);  % allocate space for input node indices
                    t = zeros([numel(labelsList)*sizeAllocCoef, 1]);  % allocate space for output node indices
                    treeNames = cell([numel(labelsList)*2*sizeAllocCoef, 1]);   % allocate space for tree names, one for each node
                end
                
                % find the closest to a pore pixel of the skeleton
                closestPoints = zeros(size(labelPositions,1), 1);
                closestPointsCenterLinePositions = zeros(size(labelPositions,1), 3);  % [index, yxz] - matrix to keep positions of points on the centerline that correlate to the closest annotation point
                for i=1:size(labelPositions,1)
                    zxy = labelPositions(i, 1:3);
                    I = distMap(:,:,round(zxy(1)));
                    [r,c] = find(I>=1);
                    dist = zeros([numel(r), 1]);
                    for j=1:numel(r)
                        dist(j) = sqrt((r(j)-zxy(3))^2 + (c(j)-zxy(2))^2);
                    end
                    [minVal, minIndex] = min(dist);
                    xC = c(minIndex);
                    yC = r(minIndex);
                    closestPointsCenterLinePositions(i, :) = [yC, xC, zxy(1)];  % [index, yxz]
                    
                    closestPoints(i) = I(yC, xC);
                    if plotThickness    % find points to generate lines that connect pore with the edge
                        perimImg = perimMap(:,:,round(zxy(1)));
                        [r,c] = find(perimImg>=1);
                        dist = zeros([numel(r), 1]);
                        for j=1:numel(r)
                            dist(j) = sqrt((r(j)-yC)^2 + (c(j)-xC)^2);
                        end
                        [minVal, minIndex] = min(dist);
                        xC2 = c(minIndex);
                        yC2 = r(minIndex);
                        
                        % add a very small shift, otherwise there is a problem with edges
                        if xC2 == xC && yC2 == yC
                            xC2 = xC2+0.000001;
                            yC2 = yC2+0.000001;
                        end
                        
                        graphPointsVec(i*2-1, :) = [xC-.5, yC-.5, zxy(1)];  % start point, shift by 0.5 pixel to put the node to the center of the pixel
                        graphPointsVec(i*2, :) = [xC2-.5, yC2-.5, zxy(1)];  % target point
                        s(i) = i*2-1;   % start node id
                        t(i) = i*2;     % target node id
                        treeNames(i*2-1:i*2) = {sprintf('ClosestPoints_%.6d', i)};
                    end
                end
                %  convert pixels to physical units, um
                CellWallThickness.closestPoints = double(closestPoints)*2*pixSize.x;
                CellWallThickness.closestPointsPos = labelPositions;
                CellWallThickness.closestPointsLabel = labelsList;
                labelValues = double(closestPoints)*2*pixSize.x;
                % update values for the labels
                obj.mibModel.I{obj.mibModel.Id}.hLabels.replaceLabels(labelsList, labelPositions, labelValues);

                if generateRandomPoints     % generate random points
                    waitbar(0.5, wb, sprintf('Calculating the random points\nPlease wait...'));
                    rng(randomGenerator);   % initialize random number generator
                    randgensettings = rng();   % obtain used generator settings
                    CellWallThickness.RendomGenSeed = randgensettings.Seed;
                    
                    %randomPointIndices = zeros([size(labelPositions,1), 1]);    % allocate space for random points
                    
                    % generate array of random point indices of the skeleton points, Uniformly distributed pseudorandom integers
                    randomPointIndices = randi(noOfAllPointsIndices, [size(labelPositions,1) 1]);   % linear indices of the random points
                    randomPointIndices = allPointsIndices(randomPointIndices);  % indices of the random points inside 3D dataset
                    % convert skeleton points that are closest to the
                    % provided labels to indices
                    closestPointsCenterLinePositionsIndices = sub2ind([height, width, depth], closestPointsCenterLinePositions(:,1), closestPointsCenterLinePositions(:,2), closestPointsCenterLinePositions(:,3));
                    
                    % debug test
                    %randomPointIndices(5) = closestPointsCenterLinePositionsIndices(5);
                    %randomPointIndices(15) = closestPointsCenterLinePositionsIndices(15);
                    
                    % remove randomPointIndices that are matching closestPointsCenterLinePositionsIndices
                    notOk = 1;
                    while notOk
                        overlappingIndices = find(ismember(randomPointIndices, closestPointsCenterLinePositionsIndices)>0); %#ok<EFIND>
                        if isempty(overlappingIndices)
                            notOk = 0; 
                        else
                            randomPointIndices(overlappingIndices) = allPointsIndices(randi(noOfAllPointsIndices, [numel(overlappingIndices) 1]));
                        end
                    end
                    
                    simulatedClosestPoints = zeros(size(labelPositions,1), 1);
                    simulatedClosestPointsPos = ones(size(labelPositions));
                    dShift = numel(randomPointIndices);
                    for i=1:numel(randomPointIndices)
                        [y, x, z] = ind2sub([height, width, depth], randomPointIndices(i));     % convert from linear indices to x,y,z coordinates
                        zxy = [z, x-.5, y-.5];  % shift to put the point to the center
                        simulatedClosestPointsPos(i, 1:3) = zxy;
                        
                        I = distMap(:,:,zxy(1));     % get image with the dist-map skeleton for the current random point
                        simulatedClosestPoints(i) = I(y, x);
                        
                        if plotThickness && generateRandomPoints
                            xC = x;
                            yC = y;
                            perimImg = perimMap(:,:,z);
                            [r,c] = find(perimImg>=1);
                            dist = zeros([numel(r), 1]);
                            for j=1:numel(r)
                                dist(j) = sqrt((r(j)-yC)^2 + (c(j)-xC)^2);
                            end
                            [minVal,  minIndex] = min(dist);
                            xC2 = c(minIndex);
                            yC2 = r(minIndex);
                            % add a very small shift, otherwise there is a problem with edges
                            if xC2 == xC && yC2 == yC
                                xC2 = xC2+0.000001;
                                yC2 = yC2+0.000001;
                            end
                            
                            graphPointsVec(i*2-1+dShift*2, :) = [xC-.5, yC-.5, z];  % start point, shift by 0.5 pixel to put the node to the center of the pixel
                            graphPointsVec(i*2++dShift*2, :) = [xC2-.5, yC2-.5, z];  % target point
                            s(i+dShift) = i*2-1+dShift*2;   % start node id
                            t(i+dShift) = i*2+dShift*2;     % target node id
                            treeNames(i*2-1+dShift*2:i*2+dShift*2) = {sprintf('RandomPoints_%.6d', i)};
                        end
                    end
                   
                    simulatedClosestPoints = double(simulatedClosestPoints)*2*pixSize.x;
                    CellWallThickness.simulatedClosestPoints = simulatedClosestPoints;
                    CellWallThickness.simulatedClosestPointsPos = simulatedClosestPointsPos;
                    
                    % test code to export random points to annotations
                    randomPointsList = repmat({'RandomPoint'}, [numel(randomPointIndices), 1]);
                    for i=1:numel(randomPointIndices)
                        randomPointsList{i} = sprintf('%s_%.6d', randomPointsList{i}, i);
                    end
                    
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(randomPointsList, simulatedClosestPointsPos, simulatedClosestPoints);
                    
                    %labelsList2 = [labelsList; randomPointsList];
                    %labelValues2 = [labelValues; simulatedClosestPoints];
                    %labelPositions2 = [labelPositions; simulatedClosestPointsPos];
                    %obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(labelsList2, labelPositions2, labelValues2);

                end
                
                % generate the graph with closest lines and assign it to Lines3D structure
                if plotThickness
                    waitbar(0.7, wb, sprintf('Generating the graph\nPlease wait...'));
                    NodeName = repmat({'closestPoints'}, [size(labelPositions,1)*2, 1]);
                    if generateRandomPoints
                        NodeName = [NodeName; repmat({'randomPoints'}, [size(labelPositions,1)*2, 1])];
                    end
                    NodeTable = table(graphPointsVec, NodeName, treeNames, 'VariableNames',{'PointsXYZ','NodeName','TreeName'});
                    WeightVec = labelValues;    % get cell wall thickness in um and assign to Weight for pores
                    if generateRandomPoints     % assign cell wall thickness at random points to Weight
                        WeightVec = [WeightVec; simulatedClosestPoints];
                    end
                    EdgeTable = table([s t], WeightVec, 'VariableNames', {'EndNodes', 'Weight'});
                    G = graph(EdgeTable, NodeTable);  % generate the graph
                    G.Nodes.Properties.VariableUnits = {'pixel','string','string'};  % it is important to indicate "pixel" unit for the PointsXYZ field, when using pixels
                    G.Nodes.Properties.UserData.pixSize = pixSize;  
                    G.Nodes.Properties.UserData.BoundingBox = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox(); % add bounding box information

                    % add graph
                    obj.mibModel.I{obj.mibModel.Id}.hLines3D.replaceGraph(G);
                    
                    CellWallThickness.G = G;
                end
            end
            
            % ---------------------------------------------------------
            % get distribution of all points of the cell wall
            % ---------------------------------------------------------
            % remove data points from all points
            if obj.View.handles.removeDataPointsCheck.Value == 1
                closestPointsCenterLinePositions(i, :) = [yC, xC, zxy(1)];  % [index, yxz]
                closestPointsCenterLineIndices = sub2ind(size(distMap), ...
                    closestPointsCenterLinePositions(:,1), closestPointsCenterLinePositions(:,2), closestPointsCenterLinePositions(:,3));
                allPointsIndices(ismember(allPointsIndices, closestPointsCenterLineIndices)) = [];
                CellWallThickness.allPointsMinusDataInfo = 1;
            end
            
            % remove simulated points from all points
            if obj.View.handles.removeSimulatedPointsCheck.Value == 1
                allPointsIndices(ismember(allPointsIndices, randomPointIndices)) = [];
                CellWallThickness.allPointsMinusRandomInfo = 1;
            end
            
            % allocate the all points to the results
            CellWallThickness.allPoints = distMap(allPointsIndices);
            CellWallThickness.allPoints = double(CellWallThickness.allPoints)*pixSize.x*2;  % convert to physical unit, um
            toc
            
            % exporting results to Matlab
            if exportToMatlab
                fprintf('CellWallThickness: a structure with results "%s" was created\n', obj.matlabExportVariable);
                assignin('base', obj.matlabExportVariable, CellWallThickness);
                if saveCenterLine
                    fprintf('CellWallThickness: a centerline image "distMap" was created\n');
                    assignin('base', 'distMap', distMap);
                end
            end
            
            % saving results to a file
            if saveToFile
                for fnId = 1:numel(outFn)
                    if strcmp(outFn{fnId}(end-2:end), 'mat')
                        save(outFn{fnId}, 'CellWallThickness');
                    else
                        waitbar(.8, wb, 'Generating Excel/CSV file...');
                        % excel export
                        obj.saveToExcelCSV(CellWallThickness, outFn{fnId});
                        
                        % export all points to CSV file
                        csvFile = fullfile(path, [fn '_allPoints.csv']);
                        waitbar(.85, wb, 'Generating CSV file...');
                        CommentText = sprintf('Matrix of cell wall thickness values in micrometers for each point of the masked centreline\n');
                        fid = fopen(csvFile, 'w');
                        fprintf(fid, CommentText);
                        fclose(fid);
                        dlmwrite(csvFile, CellWallThickness.allPoints, '-append');
                        fprintf('CellWallThickness: saving CellWallThickness all thickness points to a file:\n%s\n', csvFile);
                    end
                    fprintf('CellWallThickness: saving CellWallThickness structure to a file:\n%s\n', outFn{fnId});
                end
            end
            
            % save the distance map
            if saveCenterLine
                waitbar(.9, wb, 'Generating Thickness map file...');
                [outPath, outFile] = fileparts(outFn{1});
                thicknessMapFilename = fullfile(outPath, ['ThicknessMap_' outFile '_' materiaName '.tif']);
                distMap = distMap * 2; % convert to thickness
                maxValue = max(distMap(:));
                if maxValue < 256
                    distMap = uint8(distMap);
                else
                    distMap = uint16(distMap);
                end
                ImageDescription = obj.mibModel.I{obj.mibModel.Id}.meta('ImageDescription');  % initialize ImageDescription
                
                imwrite(distMap(:,:,1), thicknessMapFilename, 'Compression', 'lzw', 'Description', ImageDescription);
                for i=2:size(distMap, 3)
                    imwrite(distMap(:,:,i), thicknessMapFilename, 'Compression', 'lzw', 'WriteMode','append');
                end
                waitbar(1, wb, 'Generating Thickness map file...');
            end
            
            % plot results in 10 bins
            figIndex = str2double(obj.View.handles.figIdEdit.String);
            figure(figIndex);
            clf;
            subplot(1,3,1);
            if isfield(CellWallThickness, 'closestPoints')
                violin(CellWallThickness.closestPoints, 'facecolor', [0.588    0.663    0.835]);
                boxplot(CellWallThickness.closestPoints);
                title(sprintf('closest points\nN=%d', numel(CellWallThickness.closestPoints)));
                %ylim([0 .17]);
            end
            subplot(1,3,2);
            if isfield(CellWallThickness, 'simulatedClosestPoints')
                violin(CellWallThickness.simulatedClosestPoints, 'facecolor', [0.588    0.663    0.835]);
                boxplot(CellWallThickness.simulatedClosestPoints);
                title(sprintf('simulated points\nN=%d', numel(CellWallThickness.simulatedClosestPoints)));
                %ylim([0 .242]);
            end
            subplot(1,3,3);
            violin(CellWallThickness.allPoints, 'facecolor', [0.588    0.663    0.835]);
            boxplot(CellWallThickness.allPoints);
            titleString = 'All';
            if obj.View.handles.removeDataPointsCheck.Value == 1
                titleString = [titleString ' - Data'];
            end
            if obj.View.handles.removeSimulatedPointsCheck.Value == 1
                titleString = [titleString ' - Random'];
            end
            title(sprintf('%s N=%d\n(black - mean, red - median)', titleString, numel(CellWallThickness.allPoints)));
            %ylim([0 .32]);
            
            notify(obj.mibModel, 'plotImage');
            delete(wb);
        end
        
        function saveToExcelCSV(obj, CellWallThickness, outFn)
            % function saveToExcelCSV(obj, ContactArea, outFn)
            % generate Excel or CSV file with results
            
            % CellWallThickness.pixSize - pixelSize
            % CellWallThickness.BoundingBox - bounding box of the dataset in units [xmin, xmax, ymin, ymax, zmin, zmax]
            % CellWallThickness.filename  - filename of the dataset
            % CellWallThickness.modelFilename - filename of the model
            % CellWallThickness.maskFilename - mask filename
            % CellWallThickness.allPoints   % get distribution of all points of the cell wall
            % CellWallThickness.allPointsMinusRandomInfo   % switch, whether the random points were removed (=1) from all points or not (=0)
            % CellWallThickness.allPointsMinusDataInfo   % switch, whether the data points were removed (=1) from all points or not (=0)
            % CellWallThickness.closestPoints  % distribution of distances to the pores
            % CellWallThickness.closestPointsPos % positions of the annotations, [index; z,x,y]
            % CellWallThickness.closestPointsLabel % labels for the annotations, cell array
            % CellWallThickness.simulatedClosestPoints  % distribution of the randomly placed points
            % CellWallThickness.simulatedClosestPointsPos % positions of the annotations, [index; z,x,y]
            % CellWallThickness.G % graph with connected points
            
            saveToCSV = 0; 
            if strcmp(outFn(end-2:end), 'csv')
                saveToCSV = 1;
            end
            
            warning('off', 'MATLAB:xlswrite:AddSheet');
            % Sheet 1, general results
            s = {'Cell Wall Plugin: calculate HALF-thickness of cell wall'};
            s(3,1) = {'the calculated thickess in the physical units, while coordinates of the annotations in pixels'};
            s(3,1) = {['Image filename:      ' CellWallThickness.filename]};
            s(4,1) = {['Mask filename:       ' CellWallThickness.maskFilename]};
            s(5,1) = {['Model filename:       ' CellWallThickness.modelFilename]};
            s(6,1) = {['Material name:       ' CellWallThickness.materialName]};
            s(7,1) = {sprintf('Pixel size [x,y,z]/units: %f x %f x %f %s',...
                CellWallThickness.pixSize.x, CellWallThickness.pixSize.y, CellWallThickness.pixSize.z, CellWallThickness.pixSize.units)};
            s(8,1) = {sprintf('Bounding Box (Xmin:Xmax, Ymin:Ymax, Zmin:Zmax): %.3f:%.3f, %.3f:%.3f, %.3f:%.3f %s', ...
                CellWallThickness.BoundingBox(1), CellWallThickness.BoundingBox(2), ...
                CellWallThickness.BoundingBox(3), CellWallThickness.BoundingBox(4),...
                CellWallThickness.BoundingBox(5), CellWallThickness.BoundingBox(6),...
                CellWallThickness.pixSize.units)};
            if isfield(CellWallThickness, 'RendomGenSeed')
                s(9,1) = {['Random point generator:       ' num2str(CellWallThickness.RendomGenSeed)]};
            end
            
            if saveToCSV
                % generate info text file
                [path, fn] = fileparts(outFn);
                infoFilePath = fullfile(path, [fn '_info.txt']);
                fid = fopen(infoFilePath, 'w');
                for i=1:numel(s)
                    fwrite(fid, sprintf('%s\n', s{i}));
                end
                fclose(fid);
                
                if isfield(CellWallThickness, 'closestPointsLabel')
                    numLabels = numel(CellWallThickness.closestPointsLabel);

                    Pore_id = 1:numLabels; Pore_id = Pore_id';
                    Pore_name = CellWallThickness.closestPointsLabel;
                    PoreX_px = CellWallThickness.closestPointsPos(:,2);
                    PoreY_px = CellWallThickness.closestPointsPos(:,3);
                    PoreZ_px = CellWallThickness.closestPointsPos(:,1);
                    WallThicknessRealPores_um = CellWallThickness.closestPoints;
                    if isfield(CellWallThickness, 'simulatedClosestPoints')
                        RandPoreX_px = CellWallThickness.simulatedClosestPointsPos(:,2);
                        RandPoreY_px = CellWallThickness.simulatedClosestPointsPos(:,3);
                        RandPoreZ_px = CellWallThickness.simulatedClosestPointsPos(:,1);
                        WallThicknessRandomPores_um = CellWallThickness.simulatedClosestPoints;
                        T = table(Pore_id, Pore_name, PoreX_px, PoreY_px, PoreZ_px, WallThicknessRealPores_um, RandPoreX_px, RandPoreY_px, RandPoreZ_px, WallThicknessRandomPores_um);
                    else
                        T = table(Pore_id, Pore_name, PoreX_px, PoreY_px, PoreZ_px, WallThicknessRealPores_um);
                    end
                    % save results as CSV
                    writetable(T, outFn);
                end
            else
                s(12,1) = {'Pore, id'}; s(12,2) = {'Pore, name'}; 
                s(12,3) = {'Pore, X px'}; s(12,4) = {'Pore, Y px'}; s(12,5) = {'Pore, Z px'}; s(12,6) = {'Closest to the point thickness, um'}; 
                s(12,8) = {'RandPore, X px'}; s(12,9) = {'RandPore, Y px'}; s(12,10) = {'RandPore, Z px'}; 
                s(12,11) = {'Random point thickness, um'}; %s(9,9) = {'All points thickness'}; 

                if isfield(CellWallThickness, 'closestPointsLabel')
                    numLabels = numel(CellWallThickness.closestPointsLabel);

                    dSh = 12;
                    s(dSh+1:dSh+numLabels, 1) = num2cell(1:numLabels)';
                    s(dSh+1:dSh+numLabels, 2) = CellWallThickness.closestPointsLabel;
                    s(dSh+1:dSh+numLabels, 3) = num2cell(CellWallThickness.closestPointsPos(:,2));   % [labelIndex, z x y]
                    s(dSh+1:dSh+numLabels, 4) = num2cell(CellWallThickness.closestPointsPos(:,3));   % [labelIndex, z x y]
                    s(dSh+1:dSh+numLabels, 5) = num2cell(CellWallThickness.closestPointsPos(:,1));   % [labelIndex, z x y]
                    s(dSh+1:dSh+numLabels, 6) = num2cell(CellWallThickness.closestPoints);  

                    if isfield(CellWallThickness, 'simulatedClosestPoints')
                        s(dSh+1:dSh+numLabels, 8) = num2cell(CellWallThickness.simulatedClosestPointsPos(:,2));   % [labelIndex, z x y]
                        s(dSh+1:dSh+numLabels, 9) = num2cell(CellWallThickness.simulatedClosestPointsPos(:,3));   % [labelIndex, z x y]
                        s(dSh+1:dSh+numLabels, 10) = num2cell(CellWallThickness.simulatedClosestPointsPos(:,1));   % [labelIndex, z x y]
                        s(dSh+1:dSh+numLabels, 11) = num2cell(CellWallThickness.simulatedClosestPoints);  
                        %s(dSh+1:dSh+numel(allPoints), 9) = num2cell(CellWallThickness.allPoints);  
                    end
                end
                xlswrite2(outFn, s, 'CellWallThickness', 'A1');     % generate excel file
            end
        end
    end
end