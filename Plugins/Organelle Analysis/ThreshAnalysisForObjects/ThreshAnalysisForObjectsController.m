classdef ThreshAnalysisForObjectsController < handle
    % classdef ThreshAnalysisForObjectsController < handle
    % this plugin thresholds objects of the selected material and
    % calculates intensities and area ratios of the thresholded objects to
    % the area of the original object
    %
    % Copyright (C) 10.03.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    
    % Updates
    % 14.09.2020 added Eccentricity
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        Results
        % a structure with results
        saveGraphFormats
        % a cell array with formats for saving the triangulation graphs
        % 'lines3d' - MIB lines3d format
        % 'amira-ascii' - amira ascii
        % 'amira-binary' - amira binary
        % 'excel' - Microsoft Excel format
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
        function obj = ThreshAnalysisForObjectsController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'ThreshAnalysisForObjectsGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % check for the virtual stacking mode and close the controller
            if isprop(obj.mibModel.I{obj.mibModel.Id}, 'Virtual') && obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                obj.closeWindow();
                return;
            end
            
            % resize all elements of the GUI
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            % you may need to replace "obj.View.handles.text1" with tag of any text field of your own GUI
            global Font;
            if ~isempty(Font)
                if obj.View.handles.text1.FontSize ~= Font.FontSize ...
                        || ~strcmp(obj.View.handles.text1.FontName, Font.FontName)
                    mibUpdateFontSize(obj.View.gui, Font);
                end
            end
            materialsList = obj.mibModel.getImageProperty('modelMaterialNames');
            if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0 || numel(materialsList) < 1
                errordlg(sprintf('!!! Error !!!\n\nA model with at least one material is needed to proceed further!\n\nPlease create a new model, add material containing the objects that should be analysed. After that try again!'),'Missing the model','modal');
            end
            
			obj.updateWidgets();
            
            obj.Results = struct();
            
            % define filename for the output
            obj.generateOutputFilename();
            
			% add listner to obj.mibModel and call controller function as a callback
             % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
             obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
             
        end
        
        function closeWindow(obj)
            % closing ThreshAnalysisForObjectsController window
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
            
            % updating list of materials
            list = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames;   % list of materials
            if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0 || numel(list) < 1
                %errordlg(sprintf('!!! Error !!!\n\nA model with at least one material is needed to proceed further!\n\nPlease create a new model, add material containing the objects that should be analysed. After that try again!'),'Missing the model','modal');
                obj.View.handles.startBtn.Enable = 'off';
            else
                obj.View.handles.startBtn.Enable = 'on';
                obj.View.handles.objectPopup.String = list;
                obj.View.handles.objectPopup.Value = 1;
            end
            
            % updating color channels
            colors = obj.mibModel.I{obj.mibModel.Id}.colors;
            colList = cell([colors, 1]);
            for i=1:colors
                colList{i} = sprintf('Ch %d', i);
            end
            obj.View.handles.imageColChPopup.String = colList;
            obj.View.handles.imageColChPopup.Value = max([obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel, 1]);
        end
        
        function generateOutputFilename(obj)
            %function generateOutputFilename(obj)
            % generate a filename for the results
            
            % define filename for the output
            [path, fn] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            obj.View.handles.filenameEdit.String = fullfile(path, [fn '_ThresAnalysis.xls']);
            obj.View.handles.filenameEdit.TooltipString = fullfile(path, [fn '_ThresAnalysis.xls']);
        end
        
        function defineTriangulationOutputFormat(obj)
            % function defineTriangulationOutputFormat(obj)
            % define output format for saving the triangulation results
            
            global mibPath;
            prompts = {'MIB format (recommended)'; 'Amira binary'; 'Excel sheet'};
            defAns = {true, false, false};
            dlgTitle = 'Save triangulation';
            options.WindowStyle = 'modal';
            options.Title = 'Specify the output formats to save triangulation results';
            options.TitleLines = 2;               
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end
            obj.saveGraphFormats = [];
            if answer{1} == 1; obj.saveGraphFormats = [obj.saveGraphFormats, {'lines3d'}]; end
            if answer{2} == 1; obj.saveGraphFormats = [obj.saveGraphFormats, {'amira-binary'}]; end
            if answer{3} == 1; obj.saveGraphFormats = [obj.saveGraphFormats, {'excel'}]; end
        end
        
        function startBtn_Callback(obj)
            % function startBtn_Callback(obj)
            % do calculations
            minDiameterPositionsToSelection = obj.View.handles.highlightMinDiamterCheck.Value; % preview positions detected for the min diameter calculations, the selection layer will be used for that
            triangulatePointsCheck = obj.View.handles.triangulateCentroidsCheck.Value; % triangulate centroids of object to get their distribution
            removeFreeBoundaryCheck = obj.View.handles.removeFreeBoundaryCheck.Value;  % keep or remove edges at the boundaries
            getDataOptions.blockModeSwitch = 0;
            [height, width, colors, depth, time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, 0, getDataOptions);
            
            % obtain indices of materials
            materialId = str2num(obj.View.handles.objectIndices.String); %#ok<ST2NM>
            materialList = obj.View.handles.objectPopup.String;  % get material Id
            % when indices are not provided use material selected in the combobox
            if isempty(materialId)
                materialId = obj.View.handles.objectPopup.Value;  % get material Id
            end
            materialNames = materialList(materialId);
            colCh = obj.View.handles.imageColChPopup.Value;  % get color channel
            
            exportMatlab = obj.View.handles.exportMatlabCheck.Value;   % export results to Matlab workspace
            exportExcel = obj.View.handles.exportExcelCheck.Value;   % export results to Excel file
            exportMatlabFile = obj.View.handles.exportMatlabFileCheck.Value;   % export results as Matlab file
            thresholdPolicy = obj.View.handles.thresholdPolicyPopup.String{obj.View.handles.thresholdPolicyPopup.Value};    % threshold policy for the objects: Absolute or Relative
            relativeThresholdMethod = obj.View.handles.relativeThresholdMethodPopup.String{obj.View.handles.relativeThresholdMethodPopup.Value};    % method for the relative thresholding
            absoluteThresholdValue = str2double(obj.View.handles.thresholdEdit.String);    % threshold value
            if isempty(absoluteThresholdValue); absoluteThresholdValue = 0; end
            thresholdOffsetValue = str2double(obj.View.handles.thresholdOffsetEdit.String);    % threshold value
            if isempty(thresholdOffsetValue); thresholdOffsetValue = 0; end
            pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            erodeDilateCheck = obj.View.handles.erodeDilateCheck.Value;  % do additional thresholding by erosion and dilation to remove small noise
            if obj.View.handles.connectivityPopup.Value == 1
                objConnectivity = 4;
            else
                objConnectivity = 8;
            end
            
            if strcmp(thresholdPolicy, 'Absolute')
                relativeThresholdMethod = ''; 
                thresholdOffsetValue = []; 
            else
                absoluteThresholdValue = [];
            end
            
            % generate parameters for the Results structure
            obj.Results = struct();
            obj.Results(1).colCh = colCh;
            obj.Results(1).materialId = materialId;
            obj.Results(1).materialNames = materialNames;
            obj.Results(1).absoluteThresholdValue = absoluteThresholdValue;
            obj.Results(1).relativeThresholdMethod = relativeThresholdMethod;
            obj.Results(1).thresholdOffsetValue = thresholdOffsetValue;
            obj.Results(1).thresholdPolicy = thresholdPolicy;
            obj.Results(1).ErodeDilate = erodeDilateCheck;
            obj.Results(1).pixSize = pixSize;
            obj.Results(1).datasetName = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
            obj.Results(1).modelName = obj.mibModel.I{obj.mibModel.Id}.modelFilename;
            obj.Results(1).triangulatePoints = logical(triangulatePointsCheck);     % whether the points were triangulated
            obj.Results(1).triangulateRemoveFreeBoundary = logical(removeFreeBoundaryCheck);     % whether the points were triangulated
            obj.Results(1).objConnectivity = objConnectivity;     % connectivity for the object detection
            
            if isKey(obj.mibModel.I{obj.mibModel.Id}.meta, 'SliceName')
                SliceName = obj.mibModel.I{obj.mibModel.Id}.meta('SliceName');
                if numel(SliceName) ~= depth
                    SliceName = repmat(SliceName, [depth, 1]);
                end
            else
                [~, datasetFn, datasetExt] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
                SliceName = repmat({[datasetFn, datasetExt]}, [depth, 1]);
            end
            
            % generate output filenames
            [pathStr, fileStr, ExtStr] = fileparts(obj.View.handles.filenameEdit.String);
            exportExcelFn = fullfile(pathStr, [fileStr '.xls']);    % filename for Excel export
            exportMatlabFn = fullfile(pathStr, [fileStr '.mat']);   % filename for Matlab export
            
            if exportExcel || exportMatlabFile
                % check filename
                if exist(exportExcelFn, 'file') == 2 || exist(exportMatlabFn, 'file') == 2 
                    strText = sprintf('!!! Warning !!!\n\nThe file:\n%s \nis already exist!\n\nOverwrite?', exportExcelFn);
                    button = questdlg(strText, 'File exist!', 'Overwrite', 'Cancel','Cancel');
                    if strcmp(button, 'Cancel'); return; end
                    if exist(exportExcelFn, 'file') == 2; delete(exportExcelFn);  end   % delete existing file
                    if exist(exportMatlabFn, 'file') == 2; delete(exportMatlabFn);  end   % delete existing file
                end
            end
            
            wb = waitbar(0, sprintf('Calculating areas\nPlease wait...'), 'Name', 'Threshold Analysis for Objects...', 'WindowStyle', 'modal');
            % do backup
            obj.mibModel.mibDoBackup('mask', 1);
            
            %model = cell2mat(obj.mibModel.getData3D('model', NaN, 4));  % get model
            %img = cell2mat(obj.mibModel.getData3D('image', NaN, 4, colCh));         % get image
            mask = zeros([height, width, depth, time], 'uint8');     % allocate space for the mask
            obj.mibModel.I{obj.mibModel.Id}.hLabels.clearContents();  % clear annotations
            if minDiameterPositionsToSelection; obj.mibModel.I{obj.mibModel.Id}.clearSelection(); end
            if obj.View.handles.minDiameterCheck.Value == 0; minDiameterPositionsToSelection = 0; end
            
            annId = 1;
            getDataOptions.t = [1 1];
            
            for sliceId = 1:depth
                currImg = cell2mat(obj.mibModel.getData2D('image', sliceId, 4, colCh, getDataOptions));         % get image
                currModel = cell2mat(obj.mibModel.getData2D('model', sliceId, 4, NaN, getDataOptions));         % get model
                maxIntValue = double(intmax(class(currImg)));
                
                for matId = 1:numel(materialId)
                    BW = zeros([height, width], 'uint8');
                    BW(currModel == materialId(matId)) = true;
                    if matId == 1
                        CC = bwconncomp(BW, objConnectivity);
                        CC.objMaterialName = repmat(materialNames(matId), [CC.NumObjects, 1]);  % add material name
                    else
                        CC1 = bwconncomp(BW, objConnectivity);
                        % combine connected components
                        CC.NumObjects = CC.NumObjects + CC1.NumObjects;
                        CC.PixelIdxList = [CC.PixelIdxList CC1.PixelIdxList];
                        CC.objMaterialName = [CC.objMaterialName; repmat(materialNames(matId), [CC1.NumObjects, 1])]; % add material name
                    end
                end
                if CC.NumObjects == 0; continue; end   % skip slice when no objects
                
                currMask = mask(:,:,sliceId);
                
                STATS = regionprops(CC, currImg, 'Centroid', 'Area', 'BoundingBox', 'Eccentricity');   % get centroids for annotations
                STATS2 = regionprops3mib(CC, 'FirstAxisLength', 'SecondAxisLength');
                % combine results
                [STATS.FirstAxisLength] = STATS2.FirstAxisLength;
                [STATS.SecondAxisLength] = STATS2.SecondAxisLength;
                
                % generate a vector for the threshold values
                if strcmp(thresholdPolicy, 'Absolute')
                    objThresholdValues = zeros([CC.NumObjects, 1])+absoluteThresholdValue;
                else
                    objThresholdValues = zeros([CC.NumObjects, 1]);
                end
                
                for objId = 1:CC.NumObjects
                    % add material name to STATS structure
                    STATS(objId).objMaterialName = CC.objMaterialName(objId);

                    if strcmp(thresholdPolicy, 'Absolute')
                        indices = currImg(CC.PixelIdxList{objId}) > absoluteThresholdValue;
                    else
                        switch relativeThresholdMethod
                            case 'Otsu'
                                thresholdValue = graythresh(currImg(CC.PixelIdxList{objId})) * maxIntValue + thresholdOffsetValue;
                                indices = currImg(CC.PixelIdxList{objId}) > thresholdValue;
                            case 'Median'
                                % get indices of points that have intensity higher than MedianValue+ThresholdValue
                                thresholdValue = median(currImg(CC.PixelIdxList{objId})) + thresholdOffsetValue;
                                indices = currImg(CC.PixelIdxList{objId}) > thresholdValue;
                        end
                        objThresholdValues(objId) = thresholdValue;
                    end
                    % add those pixels to the new mask layer
                    currMask(CC.PixelIdxList{objId}(indices)) = 1;
                end
                
                if erodeDilateCheck
                    se = ones(3);
                    currMask = imerode(currMask, se);
                    currMask = imdilate(currMask, se);
                end
                
                if obj.View.handles.minDiameterCheck.Value == 1
                    L = labelmatrix(CC);    % generate label matrix
                    if minDiameterPositionsToSelection; selection = zeros([height width], 'uint8'); end
                end
                
                for objId = 1:CC.NumObjects
                    obj.Results(annId).objId = objId;
                    obj.Results(annId).sliceNo = sliceId;
                    obj.Results(annId).objMaterialName = STATS(objId).objMaterialName;
                    obj.Results(annId).CentroidX = STATS(objId).Centroid(1);
                    obj.Results(annId).CentroidY = STATS(objId).Centroid(2);
                    obj.Results(annId).FirstAxisLength = STATS(objId).FirstAxisLength*pixSize.x;
                    obj.Results(annId).SecondAxisLength = STATS(objId).SecondAxisLength*pixSize.x;
                    obj.Results(annId).Eccentricity = STATS(objId).Eccentricity;
                    
                    obj.Results(annId).Median = median(currImg(CC.PixelIdxList{objId}));
                    obj.Results(annId).TotalArea = numel(CC.PixelIdxList{objId})*pixSize.x*pixSize.y;
                    obj.Results(annId).SliceName = SliceName(sliceId);
                    indices = currMask(CC.PixelIdxList{objId})>0;
                    obj.Results(annId).ThresholdedArea = sum(indices)*pixSize.x*pixSize.y;
                    obj.Results(annId).objThresholdValues = objThresholdValues(objId);
                    obj.Results(annId).RatioOfAreas = obj.Results(annId).ThresholdedArea/obj.Results(annId).TotalArea;
                    
                    % calculate min diameter if needed
                    if obj.View.handles.minDiameterCheck.Value == 1     
                        xMin = ceil(STATS(objId).BoundingBox(1));
                        yMin = ceil(STATS(objId).BoundingBox(2));
                        xMax = xMin + STATS(objId).BoundingBox(3)-1;
                        yMax = yMin + STATS(objId).BoundingBox(4)-1;
                        
                        pixelInObject = CC.PixelIdxList{objId}(1);
                        [objPixY, objPixX] = ind2sub([height, width], pixelInObject);
                        objMask = L(yMin:yMax, xMin:xMax);  % make a crop of the area around the object
                        objMask(objMask~=objMask(objPixY-yMin+1, objPixX-xMin+1)) = 0;  % remove all other objects except the current
                        D = bwdist(~objMask);    % calculate distance transformation
                        UltErosionCrop = imregionalmax(D, 8);  % find ultimate erosion points
                        
                        obj.Results(annId).minDiameter = D(UltErosionCrop>0)*2*pixSize.x;     % obtain min radii values and convert them to min diameter in units
                        obj.Results(annId).minDiameterAverage = mean(obj.Results(annId).minDiameter);     % obtain average min diameter value
                        
                        if minDiameterPositionsToSelection
                            [y, x] = find(UltErosionCrop>0);
                            y = y+yMin-1;
                            x = x+xMin-1;
                            selection(sub2ind([height, width], y, x)) = 1;
                        end
                    end

                    annId = annId + 1;
                end
                mask(:,:,sliceId) = currMask;
                
                % send positions of the min-diameter points to the selection layer
                if minDiameterPositionsToSelection
                    obj.mibModel.setData2D('selection', selection, sliceId, 4, NaN, getDataOptions);
                end
                waitbar(sliceId/depth, wb);
            end
            
            if triangulatePointsCheck == 1
                waitbar(0, wb, sprintf('Computing triangulation\nPlease wait...'));
                obj.mibModel.I{obj.mibModel.Id}.hLines3D.clearContents();
                
                sliceNoVector = [obj.Results.sliceNo];
                CentroidXVec = [obj.Results.CentroidX]';
                CentroidYVec = [obj.Results.CentroidY]';
                Points = [];
                TreeName = [];
                Edges = [];
                for sliceNo = 1:depth
                    currInd = find(sliceNoVector==sliceNo);
                    CentroidsX = CentroidXVec(currInd);     % get centroid X for sliceNo
                    CentroidsY = CentroidYVec(currInd);     % get centroid Y for sliceNo
                    
                    % triangulate the centroids
                    DT = delaunayTriangulation(CentroidsX, CentroidsY);
                    % preview triangulation results
                    %figure(127);
                    %triplot(DT);
                    
                    edges = DT.edges;   % get indices of edges
                    
                    if removeFreeBoundaryCheck && ~isempty(edges)
                        F = DT.freeBoundary;    % get edges of boundaries, those are tending to be extra long
                        for i=1:size(F,1)   % sort them by first node id
                            F(i, :) = [min(F(i, :)), max(F(i, :))];
                        end
                        % plot(CentroidsX(F),CentroidsY(F),'k','LineWidth',1.5);
                        %edges(find(sum(ismember(edges, F),2)==2),:) = [];   %#ok<FNDSB> % remove edges at boundaries
                        edges(ismember(edges, F, 'rows'), :) = [];   %#ok<FNDSB> % remove edges at boundaries
                        
                        if isempty(edges); edges = DT.edges; end
                    end
                    edges = edges + size(Points, 1);    % shift edges by the index
                    
                    % combine points
                    PointsTemp = [CentroidsX, CentroidsY, repmat(sliceNo, [numel(CentroidsY), 1])];
                    Points = [Points; PointsTemp]; %#ok<AGROW>
                    TreeName = [TreeName; repmat({sprintf('Slice_%d', sliceNo)}, [numel(CentroidsY), 1])]; %#ok<AGROW>
                    
                    Edges = [Edges; edges]; %#ok<AGROW>
                    waitbar(sliceNo/depth, wb);
                end
                waitbar(1, wb, 'Generating the graph');
                NodeTable = table(Points, TreeName, 'VariableNames',{'PointsXYZ','TreeName'});
                EdgeTable = table(Edges, 'VariableNames', {'EndNodes'});
                G = graph(EdgeTable, NodeTable);  % generate the graph
                G.Nodes.Properties.VariableUnits = {'pixel','string'}; % it is important to indicate "pixel" unit for the PointsXYZ field, when using pixels
                G.Nodes.Properties.UserData.BoundingBox = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox(); % a vector with the bounding box information [xmin, width, ymin, height, zmin, depth]
                G.Nodes.Properties.UserData.pixSize = pixSize;  % add pixel size
                
                obj.mibModel.I{obj.mibModel.Id}.hLines3D.replaceGraph(G); 
                obj.mibModel.I{obj.mibModel.Id}.hLines3D.clipExtraThickness = 0;    % make it 0 to show the edges for the current slice only
            end
            
            labelList = num2str([obj.Results.objId]');
            labelListPositions = [ [obj.Results.sliceNo]' [obj.Results.CentroidX]' [obj.Results.CentroidY]' ];
            labelListValues = [obj.Results.RatioOfAreas]';
            
            if exist('labelList', 'var')
                obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(labelList, labelListPositions, labelListValues);
            end
            obj.mibModel.setData3D('mask', mask, NaN, 4);
            
            % export results to the main matlab workspace
            if exportMatlab
                waitbar(0.8, wb, sprintf('Exporting to Matlab\nPlease wait...'));
                assignin('base', 'ThreshAnalysis', obj.Results);
                textStr = '"ThreshAnalysis"';
                if triangulatePointsCheck == 1  
                    assignin('base', 'ThreshAnalysisGraph', G);
                    textStr = '"ThreshAnalysis" and "ThreshAnalysisGraph"';
                end
                fprintf('Results were exported to the main matlab workspace as %s\n', textStr);
            end
            
            % export results to matlab file
            if exportMatlabFile 
                waitbar(0.85, wb, sprintf('Exporting to Matlab\nPlease wait...'));
                Results = obj.Results; %#ok<PROP>
                save(exportMatlabFn, 'Results', '-v7');
                
                % save annotations
                outputFn = fullfile(pathStr, [fileStr '.ann']);
                annotationExportSetttings.format = 'ann';
                annotationExportSetttings.showWaitbar = 0;
                % the following options are required for export in psi format
                %annotationExportSetttings.boundingBox = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
                %annotationExportSetttings.pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
                %annotationExportSetttings.convertToUnits = true;    % convert positions from pixels to physical units for export in psi/landmarks formats
                obj.mibModel.I{obj.mibModel.Id}.hLabels.saveToFile(outputFn, annotationExportSetttings);
            end
            
            % export triangulation results
            if obj.View.handles.saveTriangulation.Value
                waitbar(0.88, wb, sprintf('Saving triangulation\nPlease wait...'));
                saveGraphOptions.showWaitbar = false;
                for i=1:numel(obj.saveGraphFormats)
                    switch obj.saveGraphFormats{i}
                        case 'lines3d'
                            outputFn = fullfile(pathStr, [fileStr '_Graph.lines3d']);
                        case 'amira-binary'
                            saveGraphOptions.EdgeFieldName = 'Length';
                            outputFn = fullfile(pathStr, [fileStr '_Graph.am']);
                        case 'excel'
                            outputFn = fullfile(pathStr, [fileStr '_Graph.xls']);
                    end
                    saveGraphOptions.format = obj.saveGraphFormats{i};
                    obj.mibModel.I{obj.mibModel.Id}.hLines3D.saveToFile(outputFn, saveGraphOptions)
                end
            end
            
            % export results to the main matlab workspace
            if exportExcel
                waitbar(0.9, wb, sprintf('Exporting to Excel\nPlease wait...'));
                warning('off', 'MATLAB:xlswrite:AddSheet');   % switch off excel warnings
                
                s = {'ThreshAnalysis: each object of the specified material(s) is intensity based thresholded compared with the original area'}; 
                if strcmp(obj.Results(1).thresholdPolicy, 'Absolute')
                    s(2,1) = {sprintf('Method: absolute thresholding, i.e. the objects were thresholded using %d value', obj.Results(1).absoluteThresholdValue)};
                else
                    s(2,1) = {sprintf('Method: relative thresholding, i.e. the objects were thresholded using %s intensity + %d value)', obj.Results(1).relativeThresholdMethod, obj.Results(1).thresholdOffsetValue)};
                end
                if obj.Results(1).ErodeDilate == 1; erode_dilate = 'YES'; else; erode_dilate = 'No'; end
                s(3,1) = {sprintf('Use of additional thresholding by erosion+dilation with strel size [3x3]: %s', erode_dilate)};
                
                s(5,1) = {sprintf('Dataset filename: %s', obj.Results(1).datasetName)};
                s(6,1) = {sprintf('Model filename: %s', obj.Results(1).modelName)};
                materialNamesString = sprintf('%s (id: %d)', obj.Results(1).materialNames{1}, obj.Results(1).materialId(1));
                for i=2:numel(obj.Results(1).materialNames); materialNamesString = sprintf('%s, %s (id: %d)', materialNamesString, obj.Results(1).materialNames{i}, obj.Results(1).materialId(i)); end
                s(7,1) = {'Material name(s):'};  s(7,2) = {materialNamesString}; 
                s(8,1) = {sprintf('Connectivity of the object detection: %d', objConnectivity)};
                s(9,1) = {sprintf('Color channel: %d', obj.Results(1).colCh)}; 
                s(10,1) = {sprintf('Pixel size [x, y, z]: %f x %f x %f %s', obj.Results(1).pixSize.x, obj.Results(1).pixSize.y, obj.Results(1).pixSize.z, obj.Results(1).pixSize.units)};
                s(10,5) = {'Thresholded Area - is the area where pixel intensity is higher than the provided threshold value'};
                if obj.Results(1).triangulatePoints
                    extraStr = '(edges at boundaries were kept)';
                    if obj.Results(1).triangulateRemoveFreeBoundary
                        extraStr = '(edges at boundaries were removed)';
                    end
                    s(11,1) = {sprintf('The centroids were triangulated (%s); see more in corresponding files: %s', extraStr, fullfile(pathStr, [fileStr '_TRI.*']))};
                end
                
                rowId = 13;
                s(rowId,1) = {'ObjId'}; s(rowId,2) = {'SliceNo'}; s(rowId,3) = {'SliceName'}; s(rowId,4) = {'ObjMaterial'}; 
                
                s(rowId,5) = {'CentroidX, px'}; s(rowId,6) = {'CentroidY, px'};
                s(rowId,7) = {'FirstAxisLength, units'}; s(rowId,8) = {'SecondAxisLength, units'}; s(rowId,9) = {'Eccentricity'};
                s(rowId,10) = {'MedianIntensity'}; s(rowId,11) = {'Total Area, units'}; s(rowId,12) = {'Thresholded Area, units'}; 
                s(rowId,13) = {'Ratio, Thresholded/Total'}; s(rowId,14) = {'Threshold value'};
                
                if isfield(obj.Results, 'minDiameterAverage'); s(rowId,15) = {'Average min diameter, um'}; end
                
                noElements = numel(obj.Results);
                s(rowId+1:rowId+noElements, 1) = num2cell([obj.Results(:).objId]);
                s(rowId+1:rowId+noElements, 2) = num2cell([obj.Results(:).sliceNo]);
                s(rowId+1:rowId+noElements, 3) = [obj.Results(:).SliceName];
                s(rowId+1:rowId+noElements, 4) = [obj.Results(:).objMaterialName]';
                s(rowId+1:rowId+noElements, 5) = num2cell([obj.Results(:).CentroidX]);
                s(rowId+1:rowId+noElements, 6) = num2cell([obj.Results(:).CentroidY]);
                s(rowId+1:rowId+noElements, 7) = num2cell([obj.Results(:).FirstAxisLength]);
                s(rowId+1:rowId+noElements, 8) = num2cell([obj.Results(:).SecondAxisLength]);
                s(rowId+1:rowId+noElements, 9) = num2cell([obj.Results(:).Eccentricity]);
                s(rowId+1:rowId+noElements, 10) = num2cell([obj.Results(:).Median]);
                s(rowId+1:rowId+noElements, 11) = num2cell([obj.Results(:).TotalArea]);
                s(rowId+1:rowId+noElements, 12) = num2cell([obj.Results(:).ThresholdedArea]);
                s(rowId+1:rowId+noElements, 13) = num2cell([obj.Results(:).RatioOfAreas]);
                s(rowId+1:rowId+noElements, 14) = num2cell([obj.Results(:).objThresholdValues]);
                if isfield(obj.Results, 'minDiameterAverage');s(rowId+1:rowId+noElements, 15) = num2cell([obj.Results(:).minDiameterAverage]); end
                
                xlswrite2(exportExcelFn, s, 'Results', 'A1');
            end

            % print results to a figure
            if obj.View.handles.makePlotCheck.Value == 1
                obj.printResults();
            end
            
            obj.mibModel.mibShowAnnotationsCheck = 1;
            notify(obj.mibModel, 'showMask');
            
            delete(wb);
        end
        
        function printResults(obj)
            if isempty(obj.Results); return; end
            
            warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
            
            % define figure settings
            hFig = figure(str2double(obj.View.handles.figureId.String));
            clf;
            hFig.PaperOrientation = 'landscape';
            hFig.PaperUnits = 'centimeters';
            paperX1 = 0.634517;
            paperY1 = 0.634517;
            paperW = 28.4084;
            paperH = 19.715;
            
            hFig.PaperPosition = [paperX1 paperY1 paperW paperH];
            hFig.PaperType = 'A4';
            
            % define fields to plot
            noPanels = 3;
            %listOfFields = {'TotalArea', 'ThresholdedArea', 'RatioOfAreas', 'FirstAxisLength', 'SecondAxisLength'};
            listOfFields = {'TotalArea', 'RatioOfAreas', 'FirstAxisLength'};
            if isfield(obj.Results, 'minDiameterAverage')
                noPanels = noPanels + 1; 
                listOfFields{end+1} = 'minDiameterAverage';
            end
            if obj.View.handles.triangulateCentroidsCheck.Value
                noPanels = noPanels + 1; 
                listOfFields{end+1} = 'Triangulation';
            end
            
            % define axes parameters
            axesPosX = .02;
            axesPosY = .35;
            dX = .05;
            axesWidth = 1/noPanels-dX;
            axesHeight = .5;
            
            % make plots
            clear aa;
            clear hPlot;
            clear hText;
            aa = cell([noPanels, 1]);
            hPlot = cell([noPanels, 1]);
            for i=1:noPanels
                aa{i} = axes('Units', 'normalized', 'Position', [axesPosX axesPosY axesWidth axesHeight]);
                axesPosX = axesPosX + axesWidth + dX;
                switch listOfFields{i}
                    case 'TotalArea'
                        hPlot{i} = violin([{[obj.Results.TotalArea]'},{[obj.Results.ThresholdedArea]'}], 'xlabel', {'Total', 'Thresholded'});
                        title(sprintf('Area, total and thresholded, %s^2', obj.Results(1).pixSize.units));
                    case 'RatioOfAreas'
                        hPlot{i} = violin([obj.Results.RatioOfAreas]');
                        aa{i}.YLim(2) = 1; 
                        title('Ratio total/thresholded');
                    case 'FirstAxisLength'
                        hPlot{i} = violin([{[obj.Results.FirstAxisLength]'},{[obj.Results.SecondAxisLength]'}], 'xlabel', {'First', 'Second'});
                        title(sprintf('First and second axis length, %s', obj.Results(1).pixSize.units)); 
                    case 'minDiameterAverage'
                        combinedMinAverageVec = [obj.Results.minDiameterAverage]';
                        combinedMinAverageVec(isinf(combinedMinAverageVec)) = [];
                        hPlot{i} = violin(combinedMinAverageVec);
                        title(sprintf('Min average diameter, %s', obj.Results(1).pixSize.units)); 
                    case 'Triangulation'
                        try
                            hPlot{i} = violin(obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Edges.Length);
                        end
                        title(sprintf('Triangulation distances, %s', obj.Results(1).pixSize.units)); 
                end
                aa{i}.YLim(1) = 0;
            end
            
            % add texts
            aaText = axes('Units', 'normalized', 'Visible', 'off');
            hText(1)=text(.001, 1, 'ThreshAnalysis: each object of the specified material(s) is intensity based thresholded compared with the original area');
            if strcmp(obj.Results(1).thresholdPolicy, 'Absolute')
                hText(2) = text(.001, .97, sprintf('Method: absolute thresholding, i.e. the objects were thresholded using %d value', obj.Results(1).absoluteThresholdValue));
            else
                hText(2) = text(.001, .97, sprintf('Method: relative thresholding, i.e. the objects were thresholded using %s intensity + %d value)', obj.Results(1).relativeThresholdMethod, obj.Results(1).thresholdOffsetValue));
            end
            if obj.Results(1).ErodeDilate == 1; erode_dilate = 'YES'; else; erode_dilate = 'No'; end
            
            dY = 0.18;
            dYstep = 0.03;
            hText(3) = text(.001, dY, sprintf('Use of additional thresholding by erosion+dilation with strel size [3x3]: %s', erode_dilate));
            hText(4) = text(.001, dY-dYstep, sprintf('Dataset filename: %s', obj.Results(1).datasetName),'Interpreter', 'none');
            hText(5) = text(.001, dY-dYstep*2, sprintf('Model filename: %s', obj.Results(1).modelName),'Interpreter', 'none');
            materialNamesString = sprintf('%s (id: %d)', obj.Results(1).materialNames{1}, obj.Results(1).materialId(1));
            for i=2:numel(obj.Results(1).materialNames); materialNamesString = sprintf('%s, %s (id: %d)', materialNamesString, obj.Results(1).materialNames{i}, obj.Results(1).materialId(i)); end
            hText(6) = text(.001, dY-dYstep*3, sprintf('Material name(s): %s', materialNamesString),'Interpreter', 'none');
            hText(7) = text(.001, dY-dYstep*4, sprintf('Color channel: %d', obj.Results(1).colCh));
            hText(8) = text(.001, dY-dYstep*5, sprintf('Pixel size [x, y, z]: %f x %f x %f %s', obj.Results(1).pixSize.x, obj.Results(1).pixSize.y, obj.Results(1).pixSize.z, obj.Results(1).pixSize.units));
            
            hText(9) = text(.001, .22, sprintf('BLACK line - Mean; RED line - Median'));
            
            
            if obj.View.handles.autoPrintCheck.Value
                printdlg(hFig);
            end
        end
        
    end
end