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

classdef SurfaceArea3DController < handle
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
        function obj = SurfaceArea3DController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'SurfaceArea3DGUI';
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
            
            % update font and size
            global Font;
            if ~isempty(Font)
                if obj.View.handles.infoText.FontSize ~= Font.FontSize ...
                        || ~strcmp(obj.View.handles.infoText.FontName, Font.FontName)
                    mibUpdateFontSize(obj.View.gui, Font);
                end
            end
            % help text
            strText = sprintf('Calculation of surface areas in 3D\nSee details in the Help section');
            obj.View.handles.infoText.String = strText;
            strText = sprintf('Important!\nIndividual objects have to be connected in 3D\nHoles are not allowed');
            obj.View.handles.infoText2.String = strText;
            obj.matlabExportVariable = 'SurfaceArea';
            
            obj.updateWidgets();
            
            if isdeployed
                obj.View.handles.exportMatlabCheck.Enable = 'off';
            end
            
            [path, fn] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            obj.View.handles.filenameEdit.String = fullfile(path, [fn '_SurfaceArea3D.csv']);
            obj.View.handles.filenameEdit.TooltipString = fullfile(path, [fn '_SurfaceArea3D.csv']);
            
            obj.View.handles.resultImagesDirEdit.String = fullfile(path);
            obj.View.handles.resultImagesDirEdit.TooltipString = fullfile(path);
            
            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            
        end
        
        function closeWindow(obj)
            % closing SurfaceArea3DController window
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
            materialsList = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames;
            if isempty(materialsList)
                materialsList = {'Insufficient data, please check Help!'};
                obj.View.handles.material1Popup.Value = 1;
                obj.View.handles.continueBtn.Enable = 'off';
            else
                obj.View.handles.continueBtn.Enable = 'on';
                obj.View.handles.material1Popup.Value = max([1 obj.mibModel.getImageProperty('selectedMaterial') - 2]);
            end
            obj.View.handles.material1Popup.String = materialsList;
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
        
        function continueBtn_Callback(obj)
            % function continueBtn_Callback(obj)
            % callback for press of continue button
            
            material1_Index = obj.View.handles.material1Popup.Value;
            material1_Name = obj.View.handles.material1Popup.String{material1_Index};
            
            outFn = obj.View.handles.filenameEdit.String;
            % add material name to the end of the filename for exporting
            % results
            if obj.View.handles.filenameMaterialCheck.Value == 1
                [path, fn, ext] = fileparts(outFn);
                fn = [fn '_' material1_Name];
                outFn = fullfile(path, [fn ext]);
            end
            
            [~, surfFnTemplate] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            
            if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0
                errordlg('This plugin requires a model to be present!', 'Model is missing');
                return;
            end
            
            if obj.View.handles.saveResultsCheck.Value
                % check filename
                if exist(outFn, 'file') == 2
                    strText = sprintf('!!! Warning !!!\n\nThe file:\n%s \nis already exist!\n\nOverwrite?', outFn);
                    button = questdlg(strText, 'File exist!','Overwrite', 'Cancel', 'Cancel');
                    if strcmp(button, 'Cancel'); return; end
                    delete(outFn);     % delete existing file
                end
            end
            
            xySmoothValue = str2double(obj.View.handles.xySmoothEdit.String);  % in pixels
            xySamplingStep = str2double(obj.View.handles.xySamplingEdit.String);  % take each N-th pixel in XY
            zSamplingStep = str2double(obj.View.handles.zSamplingEdit.String);  % take each N-th pixel in Z
            
            tic
            % backup current annotations
            obj.mibModel.mibDoBackup('labels', 1); 
            % clear annotations
            obj.mibModel.I{obj.mibModel.Id}.hLabels.clearContents();  % remove annotations from the model
            
            exportToMatlab = obj.View.handles.exportMatlabCheck.Value;       % export to Matlab switch; handles.matlabExportVariable
            saveToFile = obj.View.handles.saveResultsCheck.Value;            % save to Matlab or Excel file
            saveImages = obj.View.handles.resultsImagesCheck.Value;          % save result as images
            outDir = obj.View.handles.resultImagesDirEdit.String;            % output directory for images
            
            surf2amiraOptions.overwrite = 1;    % overwrite surface files without prompt
            surf2amiraOptions.format = 'binary';    % saving format, binary or ascii
            
            % global bounding box of the dataset
            globalBB = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox(); % [xmin, xmax, ymin, ymax, zmin, zmax]
            
            % make folder for results
            if saveImages && isdir(outDir) == 0; mkdir(outDir); end
            
            wb = waitbar(0, sprintf('Obtaining the model\nPlease wait...'));
            
            % get model
            getDataOptions.blockModeSwitch = 0;
            Model = cell2mat(obj.mibModel.getData3D('model', NaN, 4, material1_Index, getDataOptions));
            % get pixel sizes
            pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            
            waitbar(0.1, wb, sprintf('Cropping the model\nPlease wait...'))
            % crop the model
            [Y, X, Z] = ind2sub(size(Model), find(Model == 1));
            minX = min(X);
            minY = min(Y);
            minZ = min(Z);
            
            maxX = max(X);
            maxY = max(Y);
            maxZ = max(Z);
            
            Model = Model(minY:maxY, minX:maxX, minZ:maxZ);
            globalBB(1) = globalBB(1) + (minX-1)*pixSize.x; % xmin
            globalBB(3) = globalBB(3) + (minY-1)*pixSize.y; % ymin
            globalBB(5) = globalBB(5) + (minZ-1)*pixSize.z; % zmin
            
            waitbar(0.2, wb, sprintf('Looking for connected objects\nPlease wait...'))
            % find connected components and fill holes
            for i=1:size(Model,3)
                Model(:,:,i) = imfill(Model(:,:,i));
            end
            CC = bwconncomp(Model, 26);
            
            waitbar(0.3, wb, sprintf('Calculating the bounding boxes\nPlease wait...'))
            % detect bounding boxes for cropping
            STATS = regionprops(CC, 'BoundingBox', 'Centroid');
            
            % check for small objects that belong only to a single slice
            objList = zeros([CC.NumObjects, 1]);
            for objId = 1:CC.NumObjects
                if STATS(objId).BoundingBox(6) < 2
                    fprintf('SurfaceArea3D object number: %d at slice: %d was removed from analysis\n', objId, floor(STATS(objId).BoundingBox(3))+minZ);
                    objList(objId) = 1;
                end
            end
            
            if sum(objList) > 0
                STATS(objList==1) = [];
                CC.NumObjects = sum(objList==0);
                CC.PixelIdxList(objList==1) = [];
            end
            
            % allocate space for annotations
            labelList = cell([CC.NumObjects, 1]);
            labelValues = zeros([CC.NumObjects, 1]);
            positionList = zeros([CC.NumObjects, 4]);
            
            waitbar(0.3, wb, sprintf('Generating the label matrix\nPlease wait...'))
            % generate the label matrix
            L = labelmatrix(CC);
            
            % a structure for results
            SurfaceArea = struct();
            % SurfaceArea(1).pixSize - pixelSize
            % SurfaceArea(1).MaterialName - main material name
            % SurfaceArea(1).xySmoothValue - smoothing step for the XY points
            % SurfaceArea(1).xySamplingStep - sampling step for the XY points
            % SurfaceArea(1).zSamplingStep - sampling step for the Z points
            % SurfaceArea(objId).PointsVector{z} - a cell array with coordinates of surface points for each slice (z)
            % SurfaceArea(objId).Area{z} - area between slice z and slice z+1
            % SurfaceArea(objId).SumAreaTotal - a total area of the surface
            % SurfaceArea(objId).PointCloud - cloud of all detected points
            % SurfaceArea(objId).Centroid - centroid coordinates of the surface [x,y,z,t]
            
            SurfaceArea(1).pixSize = pixSize;
            SurfaceArea(1).MaterialName = obj.View.handles.material1Popup.String{material1_Index};
            SurfaceArea(1).xySmoothValue = xySmoothValue;
            SurfaceArea(1).xySamplingStep = xySamplingStep;
            SurfaceArea(1).zSamplingStep = zSamplingStep;
            
            waitbar(0.3, wb, sprintf('Calculating the areas\nPlease wait...'))
            
            % loop across the objects
            for objId = 1:CC.NumObjects
                bb = ceil(STATS(objId).BoundingBox);    % [x,y,z,w,h,d]
                % crop L to the object's bounding box
                M2 = L(bb(2):bb(2)+bb(5)-1, bb(1):bb(1)+bb(4)-1, bb(3):bb(3)+bb(6)-1);
                
                % keep only the selected object
                M1 = zeros(size(M2), 'uint8');
                M1(M2==objId) = 1;
                depthM1 = size(M1, 3);
                
                SurfaceArea(objId).SumAreaTotal = 0;
                
                vAll = zeros(0, 3);
                fAll = zeros(0, 3);
                
                % define z-sampling vector
                zPointsVector = 1:zSamplingStep:depthM1;
                if(zPointsVector(end) ~= depthM1)   % force to add the last z-point
                    zPointsVector(end+1) = depthM1;  %#ok<AGROW>
                end
                
                % calculate points from the models
                SurfaceArea(objId).PointsVector = cell([numel(zPointsVector), 1]);
                PointsVectorIndex = 1;
                
                % matrix of connected objects between slices
                % connMatrix{z} - defines indices of objects on slice Z
                % connected to objects on slice z+1
                % for example, connMatrix{z}(1,:) == [1 3] - means that objId 1 on slice z is connected to ObjId 3 on slice Z+1
                connMatrix = cell([numel(zPointsVector), 1]);
                branchPointsDetected = 0;
                zIndex = 1;
                % the following procedure detects conflicting objects
                detectedSlices = NaN([numel(zPointsVector), 1]);
                detectedIndex = 1;
                
                for z = zPointsVector
                    % detect connectivity and match the objects
                    if z < zPointsVector(end)
                        if z > zPointsVector(1)
                            currObjCC = nextObjCC;   
                        else
                            currObjCC = bwconncomp(M1(:, :, z), 8);
%                             % remove points that are 1 pixel in size
%                             numPoints = arrayfun(@(x) numel(x{1}), currObjCC.PixelIdxList);
%                             singlePixelPointsId = find(numPoints==1);
%                             if ~isempty(singlePixelPointsId)
%                                 %M1(currObjCC.PixelIdxList{singlePixelPointsId}+(z-1)*(size(M1,1)*size(M1,2))) = 0;
%                                 M1(cellfun(@(X) X+(min([z+zSamplingStep, depthM1])-1)*(size(M1,1)*size(M1,2)), currObjCC.PixelIdxList(singlePixelPointsId))) = 0;
%                                 currObjCC.PixelIdxList(singlePixelPointsId) = [];
%                                 currObjCC.NumObjects = currObjCC.NumObjects - numel(singlePixelPointsId);
%                             end
                        end
                        nextObjCC = bwconncomp(M1(:, :, min([z+zSamplingStep, depthM1])), 8);   
%                         % remove points that are 1 pixel in size
%                         numPoints = arrayfun(@(x) numel(x{1}), nextObjCC.PixelIdxList);
%                         singlePixelPointsId = find(numPoints==1);
%                         if numel(singlePixelPointsId) == numel(numPoints)   % all points are 1pix in size
%                             fprintf('Skipping object %d because it has pixels of 1 in size\n', objId);
%                         end
%                         if ~isempty(singlePixelPointsId)
%                             try
%                                 M1(cellfun(@(X) X+(min([z+zSamplingStep, depthM1])-1)*(size(M1,1)*size(M1,2)), nextObjCC.PixelIdxList(singlePixelPointsId))) = 0;
%                             catch err
%                                 0;
%                             end
%                             nextObjCC.PixelIdxList(singlePixelPointsId) = [];
%                             nextObjCC.NumObjects = nextObjCC.NumObjects - numel(singlePixelPointsId);
%                         end
                        
                        if z > zPointsVector(1)
                            objStats = regionprops(nextObjCC, 'BoundingBox');
                        else
                            objStats = regionprops(currObjCC, 'BoundingBox');
                        end
                        minXVec = arrayfun(@(s) s.BoundingBox(1), objStats);    % get X min as vector
                        minYVec = arrayfun(@(s) s.BoundingBox(2), objStats);    % get Y min as vector
                        maxXVec = arrayfun(@(s) s.BoundingBox(1)+s.BoundingBox(3), objStats);
                        maxYVec = arrayfun(@(s) s.BoundingBox(2)+s.BoundingBox(4), objStats);
                        for vecId=1:numel(minYVec)
                            findMinY = minYVec>minYVec(vecId);      % look for condition when the object fits into a bounding box of another object completely
                            findMinX = minXVec>minXVec(vecId);
                            findMaxY = maxYVec<maxYVec(vecId);
                            findMaxX = maxXVec<maxXVec(vecId);
                            findTotal = findMinY + findMinX + findMaxY + findMaxX;
                            if ~isempty(find(findTotal==4))
                                fprintf('\nWarning!!! Potential problem is found on slice: %d for object %d\n', z+bb(3)-1+minZ, objId);
                                detectedSlices(detectedIndex) = z+bb(3)-1+minZ;
                                detectedIndex = detectedIndex + 1;
                            end
                        end
                        % end of procedure to detect conflicting objects
                        
                        if currObjCC.NumObjects == nextObjCC.NumObjects && currObjCC.NumObjects == 1
                            connMatrix{zIndex} = [1 1];  % connectivity Matrix, objIndex on slice Z (1) -> matches with the objIndex 1 on slice Z+zSamplingStep
                        else %if currObjCC.NumObjects ~= nextObjCC.NumObjects     % more than one object, have to match
                            currL = labelmatrix(currObjCC);
                            currL = imdilate(currL, ones(3));   % dilate the object, due to maximal connectivity
                            nextL = labelmatrix(nextObjCC);
                            nextL = imdilate(nextL, ones(3));   % dilate the object, due to maximal connectivity
                            for sourceIndex=1:currObjCC.NumObjects
                                overlapIndices = double(unique(nextL(currL==sourceIndex)));
                                overlapIndices(overlapIndices==0) = [];
                                
                                for i=1:numel(overlapIndices)
                                    connMatrix{zIndex} = [connMatrix{zIndex}; sourceIndex overlapIndices(i)];
                                end
                            end
                        end
                        zIndex = zIndex + 1;
                    end
                    
                    % thin the object
                    Mthin = bwmorph(M1(:, :, z), 'thin', Inf);

                    CC2 = bwconncomp(Mthin, 8);       % detect number of profiles for the current slice
                    for subObjId = 1:CC2.NumObjects
                        objImg = zeros(size(Mthin), 'uint8');
                        objImg(CC2.PixelIdxList{subObjId}) = 1;
                        
                        % find the ending points of the thinned line
                        endPoints = bwmorph(objImg, 'endpoints');    % get endpoints
                        % find coordinates of the ending points
                        [ePntsY, ePntsX] = find(endPoints);
                        if numel(ePntsY) > 2
                            if branchPointsDetected == 0
                                fprintf('Removing branch points: .'); 
                            else
                                fprintf('.'); 
                            end
                            branchPointsDetected = 1;
                            
                            objImg = logical(mibRemoveBranches(objImg));
                            Mthin = Mthin - (Mthin-objImg);
                            endPoints = bwmorph(objImg, 'endpoints');    % get endpoints
                            % find coordinates of the ending points
                            [ePntsY, ePntsX] = find(endPoints);
                        elseif numel(ePntsY) == 1   % if a signle pixel detected, duplicate it 
                            ePntsY = [ePntsY; ePntsY];
                            ePntsX = [ePntsX; ePntsX];
                        elseif isempty(ePntsY)
                            % enclosed objects
                            %[ePntsY, ePntsX] = find(objImg==1,1);
                        end
                        % convert the end point coordinates to X, Y vectors
                        %[eY, eX] = ind2sub([size(M1,1), size(M1,2)], ePnts);
                        
                        % trace the boundary starting from the 1st end point
                        noPix = sum(sum(objImg));
                        if noPix > 1
                            B = bwtraceboundary(objImg, [ePntsY(1), ePntsX(1)], 'N', 8, sum(sum(objImg)));
                        else
                            [y, x] = find(objImg);
                            B = [y, x; y, x];   % duplicate, when 1-pixel detected
                        end
                        %                     % find the stopping index, because the boundary returns back to the
                        %                     % first point
                        %                     stopIndex = find(B(:,1)==ePntsY(2) & B(:,2)==ePntsX(2));
                        %                     % crop the points
                        %                     B = B(1:stopIndex,:);
                        
                        %                     figure(3)
                        %                     clf;
                        %                     imshow(M1(:, :, z), []);
                        %                     hold on;
                        %                     plot(B(:,2), B(:,1), 'r+');
                        
                        B(:,1) = (B(:,1)+bb(2)-1)*pixSize.y + globalBB(3)-pixSize.y;  % y coordinate
                        B(:,2) = (B(:,2)+bb(1)-1)*pixSize.x + globalBB(1)-pixSize.x;  % x coordinate
                        B(:,3) = (z+bb(3)-1)*pixSize.z + globalBB(5)-pixSize.z;     % z coordinate
                        %SurfaceArea(objId).PointsVector{z} = B(1:stopIndex,:);
                        
                        % xy sampling
                        if xySmoothValue > 0
                            % % smoothing
                            % use windv instead of smooth, because smooth
                            % is only available in the curve fitting toolbox
                            %B(:,1) =  smooth(B(:,1), 3);
                            %B(:,2) =  smooth(B(:,2), 3);
                            noElements = numel(B(:,1));
                            if noElements/2 < xySmoothValue   % do smoothing with smaller factor when there are not enough points
                                B(:,1) =  windv(B(:,1), floor(noElements/2), 1);
                                B(:,2) =  windv(B(:,2), floor(noElements/2), 1);
                            else
                                B(:,1) =  windv(B(:,1), xySmoothValue, 1);
                                B(:,2) =  windv(B(:,2), xySmoothValue, 1);
                            end
                        end
                        
                        % xy sampling
                        if xySamplingStep > 1
                            Btemp = B;
                            clear B;
                            pointVector = 1:xySamplingStep:size(Btemp, 1);
                            % force to take the last point
                            if pointVector(end) ~= size(Btemp, 1); pointVector(end+1) = size(Btemp, 1); end
                            
                            B(:,1) = Btemp(pointVector, 1);
                            B(:,2) = Btemp(pointVector, 2);
                            B(:,3) = Btemp(pointVector, 3);
                        end
                        SurfaceArea(objId).PointsVector{PointsVectorIndex}{subObjId} = B;
                        
                        % % test the points
                        %imshow(M1(:, :, z), []);
                        %hold on;
                        %plot(SurfaceArea(objId).PointsVector{PointsVectorIndex}(:,2), SurfaceArea(objId).PointsVector{PointsVectorIndex}(:,1), 'r+');
                    end
                    PointsVectorIndex = PointsVectorIndex + 1;
                end
                if branchPointsDetected == 1; fprintf('\n'); end
                % report the summary for the conflicting objects
                detectedSlices(isnan(detectedSlices)) = [];
                if numel(detectedSlices)>0
                    fprintf('ObjId: %d, list of slices with possible conflicts:\n%s\n', objId, num2str(detectedSlices'));
                end
                
                cellVector = [SurfaceArea(objId).PointsVector{:}];  % convert cell matrix to vector
                SurfaceArea(objId).PointCloud = cat(1, cellVector{:});  % generate point cloud
                SurfaceArea(objId).Centroid(1) = STATS(objId).Centroid(1)+minX;
                SurfaceArea(objId).Centroid(2) = STATS(objId).Centroid(2)+minY;
                SurfaceArea(objId).Centroid(3) = STATS(objId).Centroid(3)+minZ;
                SurfaceArea(objId).Centroid(4) = obj.mibModel.I{obj.mibModel.Id}.getCurrentTimePoint;
                
                for z=1:numel(SurfaceArea(objId).PointsVector)-1
                    noBrakePointsCurr = histcounts(connMatrix{z}(:,1), 1:max(connMatrix{z}(:,1))+1)-1;
                    noBrakePointsNext = histcounts(connMatrix{z}(:,2), 1:max(connMatrix{z}(:,2))+1)-1;
                    
                    pVecZ1 = SurfaceArea(objId).PointsVector{z};    % get vector of points of the current object as (y,x,z)
                    pVecZ2 = SurfaceArea(objId).PointsVector{z+1};
                    cMatrix1 = connMatrix{z};
                    cMatrix = connMatrix{z};
                    clear vec1;
                    clear vec2;
                    objIndex = 1;
                    
                    for matrixIndex = 1:size(connMatrix{z}, 1)
                        subObjId = cMatrix(matrixIndex, 1);
                        vecZ = [pVecZ1{subObjId}(:,2), pVecZ1{subObjId}(:,1), pVecZ1{subObjId}(:,3)]; % get vector (x,y,z) of points of the current object
                        
                        if noBrakePointsCurr(subObjId) == 0     % no brakes in the vector z
                            vec1{objIndex} = vecZ;  % no brake points, keep the vector
                        else    % brake points, split the vector
                            clear nextEndpoints;
                            rowInd = find( cMatrix1(:,1) == subObjId);     % identify elements
                            % get ids of the next objects
                            for i=1:numel(rowInd)
                                nextObjId = cMatrix1(rowInd(i), 2);   % indices of objects on the next slice connected to the object on the current slice
                                nextEndpoints(i*2-1:i*2,:) = pVecZ2{nextObjId}([1 end], [2 1]);      % take (y, x) -> arrange as (x, y)
                            end
                            
                            % find closest points on vecZ to nextEndpoints
                            [distVec, minPointsIds] = minDistancePoints(nextEndpoints, vecZ(:,1:2));   % minPointsIds - indices on vecZ that are closest to nextEndpoints
                            
                            % fix the minPointsIds so that the start from index 1 and ends with the max length of vecZ
                            minPointsIds(minPointsIds==min(minPointsIds)) = 1;
                            minPointsIds(minPointsIds==max(minPointsIds)) = size(vecZ,1);
                            
                            brakePointIndex = floor(mean([minPointsIds(2), minPointsIds(3)]));
                            pntsSortedVec = sort([minPointsIds(1), brakePointIndex]);
                            
                            %vec1{objIndex} = vecZ(minPointsIds(1):brakePointIndex, :);
                            vec1{objIndex} = vecZ(pntsSortedVec(1):pntsSortedVec(2), :);
                            %pVecZ1{subObjId}(minPointsIds(1):brakePointIndex-1, :) = [];   % remove obtained fragment from vecZ
                            pVecZ1{subObjId}(pntsSortedVec(1):pntsSortedVec(2)-1, :) = [];   % remove obtained fragment from vecZ
                            noBrakePointsCurr(subObjId) = noBrakePointsCurr(subObjId) - 1;  % reduce number of break points for the object from the list
                            cMatrix1(matrixIndex, :) = NaN;
                        end
                        
                        % calculate vectors for Z+zSamplingStep
                        subObjId = cMatrix(matrixIndex, 2);
                        vecZ = [pVecZ2{subObjId}(:,2), pVecZ2{subObjId}(:,1),  pVecZ2{subObjId}(:,3)]; % get vector (x,y,z) of points of the current object
                        
                        if noBrakePointsNext(subObjId) == 0     % no brakes in the vector z
                            vec2{objIndex} = vecZ;  % no brake points, keep the vector
                        else    % brake points, split the vector
                            clear nextEndpoints;
                            rowInd = find( cMatrix(:,2) == subObjId);     % identify elements
                            % get ids of the next objects
                            for i=1:numel(rowInd)
                                nextObjId = cMatrix(rowInd(i), 1);   % indices of objects on the next slice connected to the object on the current slice
                                nextEndpoints(i*2-1:i*2,:) = pVecZ1{nextObjId}([1 end], [2 1]);      % take (y, x) -> arrange as (x, y)
                            end
                            
                            % find closest points on vecZ to nextEndpoints
                            [distVec, minPointsIds] = minDistancePoints(nextEndpoints, vecZ(:, 1:2));   % minPointsIds - indices on vecZ that are closest to nextEndpoints
                            
                            % fix the minPointsIds so that the start from index 1 and ends with the max length of vecZ
                            minPointsIds(minPointsIds==min(minPointsIds)) = 1;
                            minPointsIds(minPointsIds==max(minPointsIds)) = size(vecZ,1);
                            
                            brakePointIndex = floor(mean([minPointsIds(2), minPointsIds(3)]));
                            pntsSortedVec = sort([minPointsIds(1), brakePointIndex]);
                            %vec2{objIndex} = vecZ(minPointsIds(1):brakePointIndex, :);
                            vec2{objIndex} = vecZ(pntsSortedVec(1):pntsSortedVec(2), :);
                            %pVecZ2{subObjId}(minPointsIds(1):brakePointIndex-1, :) = [];   % remove obtained fragment from vecZ
                            pVecZ2{subObjId}(pntsSortedVec(1):pntsSortedVec(2)-1, :) = [];   % remove obtained fragment from vecZ
                            noBrakePointsNext(subObjId) = noBrakePointsNext(subObjId) - 1;  % reduce number of break points for the object from the list
                            cMatrix(rowInd(1), :) = NaN;
                        end
                        objIndex = objIndex + 1;
                    end
                    if ~isempty(vec1)
                        SurfaceArea(objId).Area{z} = 0;
                        for vecId = 1:numel(vec1)
                            try
                                [v, f] = mibTriangulateCurvePair(vec1{vecId}, vec2{vecId}, min([pixSize.x, pixSize.y, pixSize.z])/10);
                            catch err
                                fprintf('Warning!!! This case can not be handled with this plugin, see slices = %d-%d\n', z+minZ-1, z+minZ);
                                fprintf('Details: "%s"\n', err.message);
                                fprintf('Most likely one of these slices have a 2D small object next to the main object\n');
                            end
                            fAll = [fAll ; f + size(vAll, 1)]; %#ok<AGROW>
                            vAll = [vAll ; v]; %#ok<AGROW>
                            currArea = trimeshSurfaceArea(v, f);
                            SurfaceArea(objId).Area{z} = SurfaceArea(objId).Area{z} + currArea;
                            SurfaceArea(objId).SumAreaTotal = SurfaceArea(objId).SumAreaTotal + currArea;
                        end
                    end
                end
                fprintf('Surface %d; total area is %f\n', objId, SurfaceArea(objId).SumAreaTotal);
                
                % generate annotation
                labelList(objId) = {sprintf('Obj%d',  objId)};
                labelValues(objId) = SurfaceArea(objId).SumAreaTotal;
                positionList(objId,:) = [SurfaceArea(objId).Centroid(3),  SurfaceArea(objId).Centroid(1),  SurfaceArea(objId).Centroid(2), SurfaceArea(objId).Centroid(4)];
                
                if saveImages
                    % ---- generate figure with results
                    try
                        %print(fh{figId}, fullfile(outDir, sprintf('ObjId_%04i.png', objId)), '-dpng', outputResolution); % '-r200'
                        surface.vertices = vAll;
                        surface.faces = fAll;
                        surf2amiraHyperSurface(fullfile(outDir, sprintf('%s_%s_Id_%04i.surf', surfFnTemplate, material1_Name, objId)), surface, surf2amiraOptions);
                    catch err
                        disp(['An error detected in ' num2str(objId) '!']);
                    end
                end
                if obj.View.handles.exportModelsToImaris.Value
                    imarisOptions.name = sprintf('%s_Id_%04i', material1_Name, objId);
                    surface.vertices = vAll;
                    surface.faces = fAll;
                    obj.mibModel.connImaris = mibSetImarisSurface(surface, obj.mibModel.connImaris, imarisOptions);                    
                end
                
                figure(15);
                if objId==1; clf; end
                p = patch('Faces', fAll, 'Vertices', vAll, 'FaceColor', 'red');
                axis equal;
                
                waitbar(objId/CC.NumObjects, wb);
            end
            
            if obj.View.handles.showPointsCheck.Value
                waitbar(.95, wb, 'Generating selection layer...');
                selection = zeros(size(Model), 'uint8');
                getDataOptions.x = [minX, maxX];
                getDataOptions.y = [minY, maxY];
                getDataOptions.z = [minZ, maxZ];
                for objId = 1:CC.NumObjects
                    bb = ceil(STATS(objId).BoundingBox);    % [x,y,z,w,h,d]
                    
                    %yVec = round((SurfaceArea(objId).PointCloud(:,1) -(globalBB(3)-pixSize.y))/pixSize.y -bb(2)+1);
                    %xVec = round((SurfaceArea(objId).PointCloud(:,2) -(globalBB(1)-pixSize.x))/pixSize.x -bb(1)+1);
                    %zVec = round((SurfaceArea(objId).PointCloud(:,3) -(globalBB(5)-pixSize.z))/pixSize.z -bb(3)+1);
                    
                    % globalBB [xmin, xmax, ymin, ymax, zmin, zmax]
                    yVec = round((SurfaceArea(objId).PointCloud(:,1) -globalBB(3)+pixSize.y)/pixSize.y);% -bb(2)+1);
                    xVec = round((SurfaceArea(objId).PointCloud(:,2) -globalBB(1)+pixSize.x)/pixSize.x);% -bb(1)+1);
                    zVec = round((SurfaceArea(objId).PointCloud(:,3) -globalBB(5)+pixSize.z)/pixSize.z);% -bb(3)+1);
                    
                    linearInd = sub2ind(size(Model), yVec, xVec, zVec);
                    selection(linearInd) = 1;
                    obj.mibModel.setData3D('selection', selection, NaN, 4, NaN, getDataOptions);
                end
            end
            
%             figure(15)
%             p = patch('Faces', fAll, 'Vertices', vAll,'FaceColor','red');
%             axis equal;
            
            % exporting results to Matlab
            if exportToMatlab
                waitbar(1, wb, 'Exporting to Matlab...');
                fprintf('SurfaceArea3D: a structure with results "%s" was created\n', obj.matlabExportVariable);
                assignin('base', obj.matlabExportVariable, SurfaceArea);
            end
            toc

            % saving results to a file
            if saveToFile
                if strcmp(outFn(end-2:end), 'mat')
                    waitbar(1, wb, 'Saving to Matlab file...');
                    save(outFn, 'SurfaceArea');
                elseif strcmp(outFn(end-2:end), 'csv')
                    waitbar(1, wb, 'Generating CSV file...');
                    obj.saveToCSV(SurfaceArea, outFn);
                else
                    waitbar(1, wb, 'Generating Excel file...');
                    obj.saveToExcel(SurfaceArea, outFn);
                end
                fprintf('SurfaceArea3D: saving SurfaceArea structure to a file:\n%s\n', outFn);
            end
            
            % add annotations
            obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(labelList, positionList, labelValues);
            obj.mibModel.mibAnnMarkerEdit = 'label';
            obj.mibModel.mibShowAnnotationsCheck = 1;
            notify(obj.mibModel, 'plotImage');

            delete(wb);
        end
        
        function saveToCSV(obj, SurfaceArea, outFn)
            % function saveToCSV(obj, SurfaceArea, outFn)
            % generate CSV file with results
            
            % SurfaceArea(1).pixSize - pixelSize
            % SurfaceArea(1).MaterialName - main material name
            % SurfaceArea(1).xySmoothValue - smoothing step for the XY points
            % SurfaceArea(1).xySamplingStep - sampling step for the XY points
            % SurfaceArea(1).zSamplingStep - sampling step for the Z points
            % SurfaceArea(objId).PointsVector{z} - a cell array with coordinates of surface points for each slice (z)
            % SurfaceArea(objId).Area{z} - area between slice z and slice z+1
            % SurfaceArea(objId).SumAreaTotal - a total area of the surface
            % SurfaceArea(objId).PointCloud - cloud of all detected points
            % SurfaceArea(objId).Centroid - centroid coordinates of the surface [x,y,z,t]
            
            SurfaceId = 1:numel(SurfaceArea);
            SurfaceId = SurfaceId';
            centMat = cat(1, SurfaceArea.Centroid);
            Time = centMat(:,4);
            Z = centMat(:,3);
            X = centMat(:,1);
            Y = centMat(:,2);
            SurfaceArea = [SurfaceArea.SumAreaTotal]';
            T = table(SurfaceId, Time, Z, X, Y, SurfaceArea);
            % save results as CSV
            writetable(T, outFn);
        end
        
        function saveToExcel(obj, SurfaceArea, outFn)
            % function saveToExcel(obj, SurfaceArea, outFn)
            % generate Excel file with results
            
            % SurfaceArea(1).pixSize - pixelSize
            % SurfaceArea(1).MaterialName - main material name
            % SurfaceArea(1).xySmoothValue - smoothing step for the XY points
            % SurfaceArea(1).xySamplingStep - sampling step for the XY points
            % SurfaceArea(1).zSamplingStep - sampling step for the Z points
            % SurfaceArea(objId).PointsVector{z} - a cell array with coordinates of surface points for each slice (z)
            % SurfaceArea(objId).Area{z} - area between slice z and slice z+1
            % SurfaceArea(objId).SumAreaTotal - a total area of the Surface
            % SurfaceArea(objId).PointCloud - cloud of all detected points
            % SurfaceArea(objId).Centroid - centroid coordinates of the surface [x,y,z,t]

            warning('off', 'MATLAB:xlswrite:AddSheet');
            % Sheet 1, general results
            s = {'SurfaceArea3D: calculate area of surfaces in 3D'};
            s(2,1) = {['Image directory:      ' fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'))]};
            s(3,1) = {['Model filename:       ' obj.mibModel.I{obj.mibModel.Id}.modelFilename]};
            s(4,1) = {['Main object material: ' SurfaceArea(1).MaterialName]};
            s(5,1) = {sprintf('Pixel size [x,y,z]/units: %fx%fx%f %s',...
                SurfaceArea(1).pixSize.x, SurfaceArea(1).pixSize.y, SurfaceArea(1).pixSize.z, SurfaceArea(1).pixSize.units)};
            
            s(4, 8) = {sprintf('XY Smooth Value, px: %d', SurfaceArea(1).xySmoothValue)};
            s(5, 8) = {sprintf('XY Sampling Step, px: %d', SurfaceArea(1).xySamplingStep)};
            s(6, 8) = {sprintf('Z Sampling Step, px: %d', SurfaceArea(1).zSamplingStep)};
            
            s(9,1) = {'SurfaceId'}; s(8,2) = {'Time'}; s(8,3) = {'Z'}; s(8,4) = {'X'}; s(8,5) = {'Y'}; s(8,6) = {'SurfaceArea'};
            
            shiftY = 9;
            for objId=1:numel(SurfaceArea)
                s(shiftY+objId, 1) = {num2str(objId)};
                s(shiftY+objId, 2) = {num2str(SurfaceArea(objId).Centroid(4))};
                s(shiftY+objId, 3) = {num2str(SurfaceArea(objId).Centroid(3))};
                s(shiftY+objId, 4) = {num2str(SurfaceArea(objId).Centroid(1))};
                s(shiftY+objId, 5) = {num2str(SurfaceArea(objId).Centroid(2))};
                s(shiftY+objId, 6) = {num2str(SurfaceArea(objId).SumAreaTotal)};
            end
            xlswrite2(outFn, s, 'General results', 'A1');
        end
    end
end