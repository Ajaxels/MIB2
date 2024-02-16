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

classdef MCcalcController < handle
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
        function obj = MCcalcController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'MCcalcGUI';
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
            strText = sprintf('Detection of contacts between organelles of interest and calculation of distance distributions between them\nSee details in the Help section');
            obj.View.handles.infoText.String = strText;
            obj.matlabExportVariable = 'MCcalc';
            
            obj.updateWidgets();
            
            if isdeployed
                obj.View.handles.exportMatlabCheck.Enable = 'off';
            end
            
            [path, fn] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            obj.View.handles.filenameEdit.String = fullfile(path, [fn '_MCcalc.xlsx']);
            obj.View.handles.filenameEdit.TooltipString = fullfile(path, [fn '_MCcalc.xlsx']);
            
            obj.View.handles.resultImagesDirEdit.String = fullfile(path);
            obj.View.handles.resultImagesDirEdit.TooltipString = fullfile(path);
            
            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            
        end
        
        function closeWindow(obj)
            % closing MCcalcController window
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
                obj.View.handles.material2Popup.Value = 1;
                obj.View.handles.continueBtn.Enable = 'off';
            else
                obj.View.handles.continueBtn.Enable = 'on';
                if numel(materialsList) > 1
                    obj.View.handles.material2Popup.Value = 2;
                else
                    obj.View.handles.material2Popup.Value = 1;
                end
            end
            obj.View.handles.material1Popup.String = materialsList;
            obj.View.handles.material2Popup.String = materialsList;
        end
        
        function calcPixelsCheck_Callback(obj)
            % function calcPixelsCheck_Callback(obj)
            % convert the probe distance to pixels or image units
            
            rangeUnits = str2double(obj.View.handles.probeDistanceEdit.String);   % probe distance
            rangeCutoffUnits = str2double(obj.View.handles.contactCutOffEdit.String);   % probe distance
            if obj.View.handles.calcPixelsCheck.Value
                range = max([1 ceil(rangeUnits/obj.mibModel.I{obj.mibModel.Id}.pixSize.x)]);
                obj.View.handles.probeDistanceEdit.String = num2str(range);
                obj.View.handles.unitsText.String = 'pixels';
                
                cutoff = max([1 ceil(rangeCutoffUnits/obj.mibModel.I{obj.mibModel.Id}.pixSize.x)]);
                obj.View.handles.contactCutOffEdit.String = num2str(cutoff);
            else
                range = rangeUnits*obj.mibModel.I{obj.mibModel.Id}.pixSize.x;
                obj.View.handles.probeDistanceEdit.String = num2str(range);
                obj.View.handles.unitsText.String = obj.mibModel.I{obj.mibModel.Id}.pixSize.units;
                
                cutoff = rangeCutoffUnits*obj.mibModel.I{obj.mibModel.Id}.pixSize.x;
                obj.View.handles.contactCutOffEdit.String = num2str(cutoff);
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
        
        function continueBtn_Callback(obj)
            % function continueBtn_Callback(obj)
            % callback for press of continue button
            
            outFn = obj.View.handles.filenameEdit.String;
            if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0
                errordlg('This plugin requires a model to be present!', 'Model is missing');
                return;
            end
            
            if obj.View.handles.saveResultsCheck.Value
                if exist(outFn, 'file') == 2
                    strText = sprintf('!!! Warning !!!\n\nThe file:\n%s \nis already exist!\n\nOverwrite?', outFn);
                    button = questdlg(strText, 'File exist!','Overwrite', 'Cancel', 'Cancel');
                    if strcmp(button, 'Cancel'); return; end
                    delete(outFn);     % delete existing file
                end
            end
            material1_Index = obj.View.handles.material1Popup.Value;
            material2_Index = obj.View.handles.material2Popup.Value;
            
            tic
            % clear annotations
            obj.mibModel.I{obj.mibModel.Id}.hLabels.clearContents();  % remove annotations from the model
            
            probingRangeInUnits = str2double(obj.View.handles.probeDistanceEdit.String);   % probe distance
            if obj.View.handles.calcPixelsCheck.Value
                pixSize = 1;
                units = 'pixels';
                range = ceil(probingRangeInUnits);
            else
                pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize.x;
                units = obj.mibModel.I{obj.mibModel.Id}.pixSize.units;
                range = ceil(probingRangeInUnits/pixSize);     % convert units to pixels
            end
            
            generateSelectionSw = obj.View.handles.highlightCheck.Value;      % highlight or not contacts using the Selection layer
            smoothing = str2double(obj.View.handles.smoothEdit.String);      % smoothing factor for boundaries
            showObj = str2double(obj.View.handles.showObjectEdit.String);    % index of object to show
            exportToMatlab = obj.View.handles.exportMatlabCheck.Value;       % export to Matlab switch; handles.matlabExportVariable
            saveToFile = obj.View.handles.saveResultsCheck.Value;            % save to Matlab or Excel file
            saveImages = obj.View.handles.resultsImagesCheck.Value;          % save result as images
            outDir = obj.View.handles.resultImagesDirEdit.String;            % output directory for images
            histBinningEdit = ceil(str2double(obj.View.handles.histBinningEdit.String));        % histogram binning factor
            outputResolution = obj.View.handles.outputResolutionEdit.String;
            outputResolution = ['-r' outputResolution];     % generate a string of -r200
            extendRays = logical(obj.View.handles.extendRays.Value);   % extend rays with additional vector rays
            extendRaysFactor = str2double(obj.View.handles.extendRaysFactor.String);  % precision at the end of the ray
            
            if obj.View.handles.detectContactsCheck.Value
                contactCutOff = str2double(obj.View.handles.contactCutOffEdit.String);
                contactGapWidth = str2double(obj.View.handles.contactGapWidthEdit.String);
                if contactGapWidth <= sqrt(2)   % otherwise neighbouring pixels of the same contact won't be connected
                    contactGapWidth = sqrt(2)+.05; 
                    obj.View.handles.contactGapWidthEdit.String = num2str(contactGapWidth);
                end   
            else
                contactCutOff = 0;
                contactGapWidth = 0;
            end
            
            
            if saveImages && isdir(outDir) == 0
                mkdir(outDir);    % make folder for results
            end
            
            [height, width] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions();     % get height/width of the dataset
            % a structure for results
            MCcalcExport = struct();
            MCcalcExport(1).smoothing = smoothing;
            MCcalcExport(1).probingRangeInUnits = probingRangeInUnits;
            MCcalcExport(1).units = units;
            MCcalcExport(1).pixSize = pixSize;
            MCcalcExport(1).mainMaterial = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames(material1_Index);
            MCcalcExport(1).secondaryMaterial = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames(material2_Index);
            MCcalcExport(1).histBinningEdit = histBinningEdit;
            MCcalcExport(1).contactCutOff = contactCutOff;   % cut off distance for contacts
            MCcalcExport(1).contactGapWidth = contactGapWidth;   % fuse contacts having brakes smaller than this number
            MCcalcExport(1).extendRays = extendRays;      % extend rays with additional vector rays
            MCcalcExport(1).extendRaysFactor = extendRaysFactor; % precision at the end of the ray
            
            wb = waitbar(0, sprintf('Calculating\nPlease wait...'), 'Name', 'MCcalc progress');
            
            %             % create figures for results, fh{2} - to generate images for
            %             output, and fh{1} to generate an figure to show
            fh{1} = figure('Visible', 'off');     %
            fh{1}.Position = [969   141   909   934];
            fh{2} = figure('Visible', 'off');
            fh{2}.Position = [969   141   909   934];
            %             ax1 = axes(fh);
            %             ax1.Position = [.1 .4 .8 .55];
            %             ax2 = axes(fh);
            %             ax2.Position = [.1, .1, .8, .2];
            
            
            % for development to calculate the distances using distmap
            useDistanceMap = false;

            objId = 1;  % counter for objects
            sliceCounter = 1;   % counter for slices
            maxSlice = obj.mibModel.I{obj.mibModel.Id}.time*obj.mibModel.I{obj.mibModel.Id}.depth;
            getDataOptions.blockModeSwitch = 0;
            for t=1:obj.mibModel.I{obj.mibModel.Id}.time
                getDataOptions.t = [t, t];
                for z=1:obj.mibModel.I{obj.mibModel.Id}.depth
                    M1 = cell2mat(obj.mibModel.getData2D('model', z, 4, material1_Index, getDataOptions));    % get main material
                    M2 = cell2mat(obj.mibModel.getData2D('model', z, 4, material2_Index, getDataOptions));    % get secondary material
                    
                    % get number of main objects
                    CC = bwconncomp(M1, 8);
                    noPixels = cellfun(@numel, CC.PixelIdxList);    % get number of pixels for each region
                    smallObjIndices = find(noPixels < 20);  % indices of small objects for removal
                    if ~isempty(smallObjIndices)
                        CC.PixelIdxList(smallObjIndices) = [];
                        CC.NumObjects = numel(CC.PixelIdxList);
                        fprintf('Removing %d small objects (smaller than 20 pixels), time point: %d, slice number: %d', numel(smallObjIndices), t, z);
                    end
                    STATS = regionprops(CC, 'BoundingBox', 'Centroid', 'Area', 'Eccentricity');     % get bounding box for objects for cropping [x1, y1, width, height]
                    
                    if generateSelectionSw
                        selection = zeros(size(M1), 'uint8');    % allocate space for selection layer
                    end
                    
                    if useDistanceMap
                        % calculate distrance map
                        M2dist = bwdist(M2, 'euclidean');
                    end

                    % loop via main objects
                    for objIndex=1:CC.NumObjects
                        % get min and max values for the bounding box
                        x1 = ceil(STATS(objIndex).BoundingBox(1));
                        y1 = ceil(STATS(objIndex).BoundingBox(2));
                        x2 = x1 + STATS(objIndex).BoundingBox(3);
                        y2 = y1 + STATS(objIndex).BoundingBox(4);
                        
                        % extend bounding box by the "range + 10" value
                        range2 = range + 10;
                        x1 = max([1 x1-range2]);
                        x2 = min([width x2+range2]);
                        y1 = max([1 y1-range2]);
                        y2 = min([height y2+range2]);
                        
                        % copy current mitochondria to a new image
                        M1c = zeros(size(M1), 'uint8');
                        M1c(CC.PixelIdxList{objIndex}) = 1;
                        
                        M1c = M1c(y1:y2, x1:x2);         % crop image around the current main object
                        D2 = bwdist(M1c, 'euclidean');   % calculate the distance map
                        M2c = M2(y1:y2, x1:x2);          % crop the secondary material
                        if material1_Index == material2_Index % remove main object when detecting of contacts between objects of the same material
                            M2c(M1c==1) = 0;
                        end
                        D2(~M2c) = Inf;                  % replace all pixels of the distance map that do not belong to the secondary objects with Infinity value
                        
                        % calculate mean average thickness
                        Dn = bwdist(~M1c);    % calculate distance transformation
                        UltErosionCrop = imregionalmax(Dn, 8);  % find ultimate erosion points
                        mainMinThicknessUnits = mean(Dn(UltErosionCrop>0)*2*pixSize); % obtain average min thickness value
                        mainAreaUnits = STATS(objIndex).Area*pixSize*pixSize; % obtain area of the main object
                        mainEccentricity = STATS(objIndex).Eccentricity; % obtain Eccentricity value for the objects

                        cWidth = size(M1c, 2);    % width of the cropped image
                        cHeight = size(M1c, 1);   % height of the cropped image
                        
                        Boundary = bwboundaries(M1c, 8);   % trace the boundary of the current main object
                        
                        %                         % %         % test of boundaries tracing, plot the traced boundary
%                         figure(101);
%                         clf
%                         imshow(M1c,[]);
%                         hold on;
%                         for k = 1:length(Boundary)
%                             boundary = Boundary{k};
%                             hPl = plot(boundary(:,2), boundary(:,1), 'r.', 'LineWidth', 1);
%                             hPl.MarkerSize = 20;
%                         end
%                         ax = gca;
%                         ax.XTick = [];
%                         ax.YTick = [];
                        
                        Boundary = cell2mat(Boundary);
                        
                        % smooth boundaries
                        if smoothing > 0
                            % use windv instead of smooth, because smooth
                            % is only available in the curve fitting toolbox
                            %Boundary(:,1) =  smooth(Boundary(:,1), smoothing);
                            %Boundary(:,2) =  smooth(Boundary(:,2), smoothing);

                            % fix smoothing
                            extBoundary = repmat(Boundary, [3,1]);
                            extBoundary(:,1) =  windv(extBoundary(:,1), floor(smoothing/2), 1);
                            extBoundary(:,2) =  windv(extBoundary(:,2), floor(smoothing/2), 1);
                            Boundary = extBoundary(size(Boundary,1)+1:size(Boundary,1)*2, :);

                            %Boundary(:,1) =  windv(Boundary(:,1), floor(smoothing/2), 1);
                            %Boundary(:,2) =  windv(Boundary(:,2), floor(smoothing/2), 1);
                            
                            %                             figure(101);
                            %                             clf
                            %                             %imshow(M1c,[]);
                            %                             D3 = D2; D3(~M2c) = 0; D3(M1c == 1) = 0;
                            %                             imshow(D3,[0, 200]);
                            %                             hold on;
                            %                             %for k = 1:length(Boundary)
                            %                             %    boundary = Boundary{k};
                            %                                 hPl = plot(Boundary(:,2), Boundary(:,1), 'r.', 'LineWidth', 1);
                            %                                 hPl.MarkerSize = 20;
                            %                             %end
                            %                             ax = gca;
                            %                             ax.XTick = [];
                            %                             ax.YTick = [];
                        end
                        
                        % calculate total perimeter of the main object
                        d = diff([Boundary(:, 2) Boundary(:, 1)]);
                        mainTotalPerimeter = sum(sqrt(sum(d.*d, 2)))*pixSize;
                        
                        % remove pixels that touch boundaries of the image
                        indicesX1 = find(Boundary(:,2)==1);       % x==1
                        indicesX2 = find(Boundary(:,2)==cWidth);   % x==width
                        indicesY1 = find(Boundary(:,1)==1);       % y==1
                        indicesY2 = find(Boundary(:,1)==cHeight);  % y==height
                        indices = unique([indicesX1; indicesX2; indicesY1; indicesY2]);  % find unique indices
                        
                        mainPerimeterBorder = 0;   % length of the perimeter that is touching border of the image
                        if ~isempty(indices)
                            % calculate length of the profiles that are touching the image borders
                            for brakePnt=1:numel(indices)-1
                                if indices(brakePnt+1) - indices(brakePnt) == 1
                                    mainPerimeterBorder = sqrt((Boundary(indices(brakePnt),2) - Boundary(indices(brakePnt+1),2))^2 + ...
                                        (Boundary(indices(brakePnt),1) - Boundary(indices(brakePnt+1),1))^2 ) + mainPerimeterBorder;
                                end
                            end
                        end
                        mainPerimeterBorder = mainPerimeterBorder*pixSize;
                        
                        B = Boundary;
                        B(indices, :) = [];     % remove boundaries that are touching the image borders
                        
%                         figure(101);
%                         clf
%                         imshow(M1c,[]);
%                         hold on;
%                         %for k = 1:length(Boundary)
%                         %    boundary = Boundary{k};
%                         hPl = plot(B(:,2), B(:,1), 'r.', 'LineWidth', 1);
%                         hPl.MarkerSize = 20;
%                         %end
%                         ax = gca;
%                         ax.XTick = [];
%                         ax.YTick = [];
%                         
                        if useDistanceMap
                        else
                            [results, B, rayDestinationPosX, rayDestinationPosY, Bx1, Bx2, By1, By2] = obj.raytraceObject(B, D2, range, pixSize);
                        end
                        
                        if MCcalcExport(1).contactCutOff > 0
                            try
                                contactIds = find(results < contactCutOff);   % find indices of contacts
                                contactLength = [];     % length of detected contacts
                                contactMeanDistance = [];   % mean distance of the detected contact
                                contactIndex = 1;
                               
                                if ~isempty(contactIds) && numel(contactIds) > 1
                                    %contactBrkPoints = find(diff(contactIds) > MCcalcExport(1).contactGapWidth);
                                    contactDistVector = sqrt(sum(diff(B(contactIds,:)).^2, 2)); % distance between each contact point > MCcalcExport(1).contactGapWidth
                                    contactBrkPoints = find(contactDistVector > MCcalcExport(1).contactGapWidth);
                                    
                                    if isempty(contactBrkPoints)   % only one single contact
                                        % replace for loop with sqrt with a single line expression
                                        contactLength = sum(sqrt(sum(diff(B(contactIds(1):contactIds(end),:)).^2,2)));
                                        
                                        %BB = B(contactIds(1):contactIds(end),:);
                                        %BB(:,1) = windv(BB(:,1), 1, 1);
                                        %BB(:,2) = windv(BB(:,2), 1, 1);
                                        %contactLength = sum(sqrt(sum(diff(BB).^2,2)));
                                        %                                         contactLength = 0;
                                        %                                         for Bidx = contactIds(1):contactIds(end)-1
                                        %                                             contactLength(1) = contactLength(1) + sqrt( (B(Bidx+1, 1)-B(Bidx, 1))^2 + (B(Bidx+1, 2)-B(Bidx, 2))^2 );
                                        %                                         end
                                        
                                        distVector = results(contactIds);
                                        distVector(distVector==Inf) = [];
                                        contactMeanDistance(1) = mean(distVector);
                                    else
                                        contactLength = zeros([numel(contactBrkPoints)+1, 1]);
                                        contactMeanDistance = zeros([numel(contactBrkPoints)+1, 1]);
                                        
                                        % calculate the first contact
                                        %for Bidx = contactIds(1):contactIds(contactBrkPoints(1))
                                        %    contactLength(contactIndex) = contactLength(contactIndex) + sqrt( (B(Bidx+1, 1)-B(Bidx, 1))^2 + (B(Bidx+1, 2)-B(Bidx, 2))^2 );
                                        %end
                                        contactLength(contactIndex) = sum(sqrt(sum(diff(B(contactIds(1):contactIds(contactBrkPoints(1)),:), 1, 1).^2, 2))) + 1;    % +1 because we count length of pixels, but not the distance between their centers
                                        
                                        distVector = results(contactIds(1):contactIds(contactBrkPoints(1)));
                                        contactIds1 = contactIds(1):contactIds(contactBrkPoints(1));    % to use later in the contact was cut away
                                        contactIds1(distVector==Inf) = [];
                                        distVector(distVector==Inf) = [];
                                        contactMeanDistance(contactIndex) = mean(distVector);
                                        
                                        for brkPnt = 1:numel(contactBrkPoints)-1
                                            contactIndex = contactIndex + 1;
                                            %for Bidx = contactIds(contactBrkPoints(brkPnt)+1):contactIds(contactBrkPoints(brkPnt+1))
                                            %    contactLength(contactIndex) = contactLength(contactIndex) + sqrt( (B(Bidx+1, 1)-B(Bidx, 1))^2 + (B(Bidx+1, 2)-B(Bidx, 2))^2 );
                                            %end
                                            localIndices = contactIds(contactBrkPoints(brkPnt)+1):contactIds(contactBrkPoints(brkPnt+1));
                                            if numel(localIndices) > 1
                                                contactLength(contactIndex) = sum(sqrt(sum(diff(B(contactIds(contactBrkPoints(brkPnt)+1):contactIds(contactBrkPoints(brkPnt+1)),:), 1, 1).^2,2))) + 1;    % +1 because we count length of pixels, but not the distance between their centers
                                            else    % when the contact is one pixel long
                                                contactLength(contactIndex) = 1;    
                                            end
                                            
                                            distVector = results(contactIds(contactBrkPoints(brkPnt)+1):contactIds(contactBrkPoints(brkPnt+1)));
                                            distVector(distVector==Inf) = [];
                                            contactMeanDistance(contactIndex) = mean(distVector);
                                        end
                                        
                                        % calculate the last contact
                                        contactIndex = contactIndex + 1;
                                        %for Bidx = contactIds(contactBrkPoints(end)+1)-1:contactIds(end)-1
                                        %    contactLength(contactIndex) = contactLength(contactIndex) + sqrt( (B(Bidx+1, 1)-B(Bidx, 1))^2 + (B(Bidx+1, 2)-B(Bidx, 2))^2 );
                                        %end
                                        contactLength(contactIndex) = sum(sqrt(sum(diff(B(contactIds(contactBrkPoints(end)+1)-1:contactIds(end)-1,:), 1, 1).^2, 2))) + 1;    % +1 because we count length of pixels, but not the distance between their centers
                                        %contactGapsIndices = [contactGapsIndices, ]
                                        
                                        distVector = results(contactIds(contactBrkPoints(end)+1):contactIds(end));
                                        contactIds2 = contactIds(contactBrkPoints(end)+1):contactIds(end);    % to use later in the contact was cut away
                                        contactIds2(distVector==Inf) = [];
                                        distVector(distVector==Inf) = [];
                                        contactMeanDistance(contactIndex) = mean(distVector);
                                    end
                                    
                                    % a situation when one contact was cut away because
                                    % tracing of the contour started somewhere within the contact
                                    if contactIds(1) == 1 && contactIds(end) == numel(results)
                                        if contactIndex > 1
                                            contactLength(1) = contactLength(1)+contactLength(end);
                                            contactLength(end) = [];
                                            contactMeanDistance(1) = mean([results(contactIds1); results(contactIds2)]);
                                            contactMeanDistance(end) = [];
                                        end
                                    end
                                    
                                    contactLength = contactLength*pixSize;  % convert to units
                                    contactMeanDistance = contactMeanDistance-pixSize;
                                    
                                    % finding the missing points (within
                                    % the gap areas) that should be
                                    % assigned to contacts
                                    
                                    %GapsPositionIndices = find(diff(contactIds) <= MCcalcExport(1).contactGapWidth & diff(contactIds) > sqrt(2));
                                    %GapsPositionIndices = find(contactDistVector==0);
                                    GapsPositionIndices = find(contactDistVector > sqrt(2) & contactDistVector < MCcalcExport(1).contactGapWidth);
                                    for i=1:numel(GapsPositionIndices)
                                        contactIds = [contactIds; (contactIds(GapsPositionIndices(i))+1:contactIds(GapsPositionIndices(i)+1)-1)'];
                                    end
                                    contactIds = sort(contactIds);
                                end
                                %cutOffContactX = rayDestinationPosX(contactIds);
                                %cutOffContactY = rayDestinationPosY(contactIds);
                                
                                cutOffContactY = round(B(contactIds, 1));
                                cutOffContactX = round(B(contactIds, 2));
                                if generateSelectionSw
                                    for ind=1:numel(cutOffContactY)
                                        selection(cutOffContactY(ind)+y1-1, cutOffContactX(ind)+x1-1) = 1;    % add contacts to selection
                                    end
                                end
                                
                            catch err
                                err
                            end
                            
%                             figure(102)
%                             clf;
%                             D3 = D2;
%                             D3(M1c == 1) = 0;
%                             D3(~M2c) = 0;
%                             imshow(D3,[0, 200]);
%                             hold on;
%                             hPl = plot(B(:, 2), B(:, 1), 'r.', 'LineWidth', 1);
%                             hPl.MarkerSize = 10;
%                             hPl2 = plot(cutOffContactX, cutOffContactY, 'g.', 'LineWidth', 1);
%                             hPl2.MarkerSize = 10;
%                             ax = gca;
%                             ax.XTick = [];
%                             ax.YTick = [];
                            
                        end
                        
                        % remove positions on the perimeter without hits
                        InfIndices = find(results==Inf);
                        rayDestinationPosY(InfIndices) = [];   % obtain positions of the secondary objects with hits
                        rayDestinationPosX(InfIndices) = [];
                        results(InfIndices) = [];
                        
                        % obtain positions of the perimeter points with hits
                        raySourcePosX = B(:,2);
                        raySourcePosX(InfIndices) = [];
                        raySourcePosY = B(:,1);
                        raySourcePosY(InfIndices) = [];
                        
%                         figure(103)
%                         clf;
%                         D3 = D2;
%                         D3(M1c == 1) = 0;
%                         D3(~M2c) = 0;
%                         imshow(D3,[0, 200]);
%                         hold on;
%                         hPl = plot(rayDestinationPosX, rayDestinationPosY, 'g.', 'LineWidth', 1);
%                         hPl.MarkerSize = 10;
%                         hPl2 = plot(raySourcePosX, raySourcePosY, 'r.', 'LineWidth', 1);
%                         hPl2.MarkerSize = 10;
%                         ax = gca;
%                         ax.XTick = [];
%                         ax.YTick = [];
                        
                        MCcalcExport(objId).Centroid = STATS(objIndex).Centroid;
                        MCcalcExport(objId).time = t;
                        MCcalcExport(objId).slice = z;
                        MCcalcExport(objId).MinDist = results;
                        MCcalcExport(objId).rayDestinationPosX = rayDestinationPosX;
                        MCcalcExport(objId).rayDestinationPosY = rayDestinationPosY;
                        MCcalcExport(objId).raySourcePosX = raySourcePosX;
                        MCcalcExport(objId).raySourcePosY = raySourcePosY;
                        MCcalcExport(objId).mainPerimeterWithoutBorder = mainTotalPerimeter-mainPerimeterBorder;
                        MCcalcExport(objId).mainPerimeterBorder = mainPerimeterBorder;
                        MCcalcExport(objId).mainPerimeterNoPixels = size(B,1);   % Total number of points from where the rays were generated, excluding clipped areas at edges of the image
                        MCcalcExport(objId).mainMinThicknessUnits = mainMinThicknessUnits;   % average min thickness of the main object
                        MCcalcExport(objId).mainAreaUnits = mainAreaUnits; % Area of the main object in units
                        MCcalcExport(objId).mainEccentricity = mainEccentricity; % Eccentricity of the main object
                        MCcalcExport(objId).secondaryHitsNoPixels = size(rayDestinationPosX,1);   % number of pixels found on the secondary object
                        if MCcalcExport(1).contactCutOff > 0
                            MCcalcExport(objId).cutOffContactX = cutOffContactX;     % X coordinate of a contact
                            MCcalcExport(objId).cutOffContactY = cutOffContactY;     % Y coordinate of a contact
                            MCcalcExport(objId).contactLength = contactLength;       % length of contacts
                            MCcalcExport(objId).contactMeanDistance = contactMeanDistance;       % mean distance of contacts
                        end
                        
                        % calculate distribution of distances
                        edges = pixSize*histBinningEdit:pixSize*histBinningEdit:probingRangeInUnits;
                        DistributionMinDist = histcounts(MCcalcExport(objId).MinDist, edges);
                        MCcalcExport(objId).DistributionMinDist = DistributionMinDist;
                        MCcalcExport(objId).DistributionCenters = edges(1:end-1);
                        % normalize distribution of distances to the number of pixels
                        % that form main object perimeter
                        DistributionMinDistNorm = DistributionMinDist / MCcalcExport(objId).mainPerimeterNoPixels;
                        MCcalcExport(objId).DistributionMinDistNorm = DistributionMinDistNorm;
                        
                        % collect data for calculation of average numbers for complete
                        % data collection
                        if objId==1
                            MCcalcExport(1).DistributionMinDistNormAv = zeros([numel(MCcalcExport(1).DistributionCenters), 1]);
                        end
                        % sum the numbers, see below for calculation of the average
                        % numbers: search for 'calculation of average numbers'
                        MCcalcExport(1).DistributionMinDistNormAv = MCcalcExport(1).DistributionMinDistNormAv + MCcalcExport(objId).DistributionMinDistNorm';
                        
                        % add annotation with object Id
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(num2str(objId), [z, STATS(objIndex).Centroid, t]);
                        
                        %msgbox('Operation Completed','Success')
                        
                        if saveImages || objId == showObj
                            % ---- generate figure with results
                            %fh = figure(105);
                            %fh = figure('Visible', 'off');
                            %fh{}.Visible = 'off';
                            %                           fh.Position = [969   141   909   934];
                            if objId == showObj
                                figId = 1;
                            else
                                figId = 2;
                            end
                            clf(fh{figId});
                            
                            D3 = D2;
                            D3(D3==Inf) = 0;    % make all distances except for the second material as Inf
                            B2 = bwboundaries(M1c, 8); % generate boundaries for the second material
                            
                            %cla(ax1);
                            ax1 = axes(fh{figId});
                            ax1.Position = [.1 .4 .8 .55];
                            %imh = image(ax1, repmat(uint8(D3*255/range), [1,1,3]));   % plot scaled image with distance map
                            imh = image(ax1, repmat(uint8(D3*255), [1,1,3]));   % plot scaled image without distance map
                            ax1.DataAspectRatioMode = 'manual';
                            ax1.PlotBoxAspectRatioMode = 'manual';
                            ax1.DataAspectRatio = [1 1 1];
                            
                            hold(ax1,'on');
                            plot(ax1, Boundary(:, 2), Boundary(:, 1), 'y', 'LineWidth', 1);  % plot boundaries of the main object
                            plot(ax1, [Bx1 Bx2]', [By1 By2]'); % plot ray vectors, x-vector, y-vector
                            for k = 1:length(B2)
                                boundary = B2{k};
                                plot(ax1, boundary(:,2), boundary(:,1), 'r', 'LineWidth', 1);
                            end
                            
                            h=plot(ax1, B(1,2), B(1,1), 'rx'); % mark position, where the trancing on the main object started
                            set(h, 'MarkerSize', 10);
                            
                            % plot detected minimal points
                            plot(ax1, MCcalcExport(objId).rayDestinationPosX, MCcalcExport(objId).rayDestinationPosY,'g.');
                            if MCcalcExport(1).contactCutOff > 0
                                h = plot(ax1, MCcalcExport(objId).cutOffContactX, MCcalcExport(objId).cutOffContactY,'y.');
                                set(h, 'MarkerSize', 6);
                            end
                            
                            if strcmp(units, 'pixels')
                                titleStr = sprintf('Perimeter without edge: %.0f %s\nBorder length: %.0f %s', MCcalcExport(objId).mainPerimeterWithoutBorder, units, mainPerimeterBorder, units);
                            else
                                titleStr = sprintf('Perimeter without edge: %.3f %s\nBorder length: %.3f %s', MCcalcExport(objId).mainPerimeterWithoutBorder, units, mainPerimeterBorder, units);
                            end
                            ax1.Title.String = titleStr;
                            
                            % calculate distribution of distances
                            %[histDistMinDist, edges] = histcounts(MCcalcExport(objId).MinDist, range);
                            % scale distribution of distances to the perimeter of the main object
                            %DistToMitoRatio = histDistMinDist / (mitoTotalLength-borderMitoLength);
                            
                            ax2 = axes(fh{figId});
                            ax2.Position = [.1, .1, .8, .2];
                            %cla(ax2);
                            
                            bar(ax2, MCcalcExport(objId).DistributionCenters, MCcalcExport(objId).DistributionMinDistNorm);
                            title(ax2, sprintf('Minimal distances (norm. to number of generated rays, %d)', MCcalcExport(objId).mainPerimeterNoPixels));
                            xlabel(ax2, sprintf('Distance from %s, in %s, step=%f', cell2mat(MCcalcExport(1).mainMaterial), units, pixSize*histBinningEdit));
                            ylabel(ax2, 'Occurrence / number rays');
                            if saveImages
                                try
                                    print(fh{figId}, fullfile(outDir, sprintf('ObjId_%04i.png', objId)), '-dpng', outputResolution); % '-r200'
                                catch err
                                    disp(['An error detected in ' num2str(objId) '!']);
                                end
                            end
                            if objId == showObj
                                fh{figId}.Visible = 'on';
                            end
                            
                        end
                        objId = objId + 1;
                    end
                    waitbar(sliceCounter/maxSlice, wb);
                    sliceCounter = sliceCounter + 1;
                    
                    % store selection
                    if generateSelectionSw
                        obj.mibModel.setData2D('selection', selection, z, 4, material1_Index, getDataOptions);
                    end
                end
            end
            % delete a temp figure
            delete(fh{2});
            
            % calculation of average numbers
            MCcalcExport(1).DistributionMinDistNormAv = MCcalcExport(1).DistributionMinDistNormAv/numel(MCcalcExport);
            
            % exporting results to Matlab
            if exportToMatlab
                waitbar(1, wb, 'Exporting to Matlab...');
                fprintf('MCcalc: a structure with results "%s" was created\n', obj.matlabExportVariable);
                assignin('base', obj.matlabExportVariable, MCcalcExport);
            end
            
            toc
            
            % saving results to a file
            if saveToFile
                if strcmp(outFn(end-2:end), 'mat') || exportToMatlab
                    [outMatPath, outMatFname]  = fileparts(outFn);
                    outMatFname = fullfile(outMatPath, [outMatFname, '.mat']);
                    waitbar(1, wb, 'Saving to Matlab file...');
                    fprintf('MCcalc: saving MCcalcExport structure to a file:\n%s\n', outMatFname);
                    save(outMatFname, 'MCcalcExport');
                end
                if strcmp(outFn(end-3:end), 'xlsx') 
                    waitbar(1, wb, 'Generating Excel file...');
                    % excel export
                    obj.saveToExcel(MCcalcExport, outFn);
                end
            end
            
            figure(1024)
            plot(MCcalcExport(1).DistributionCenters, MCcalcExport(1).DistributionMinDistNormAv);
            xlabel(sprintf('Distance from %s, in %s, step=%f', cell2mat(MCcalcExport(1).mainMaterial), units, pixSize*histBinningEdit));
            ylabel(sprintf('Occurrence/number of rays, averaged for all %s', cell2mat(MCcalcExport(1).mainMaterial)));
            title(sprintf('Averaged results for all points (N=%d)', numel(MCcalcExport)));
            grid;
            
            obj.mibModel.mibAnnMarkerEdit = 'label';
            obj.mibModel.mibShowAnnotationsCheck = 1;
            notify(obj.mibModel, 'plotImage');
            
            delete(wb);
        end

        function [results, B, rayDestinationPosX, rayDestinationPosY, Bx1, Bx2, By1, By2] = raytraceObject(obj, B, D2, range, pixSize)
            % function [results, B, rayDestinationPosX, rayDestinationPosY, Bx1, Bx2, By1, By2] = raytraceObject(obj, B, D2, range, pixSize)
            % use raytracing to find hits

            % Parameters:
            % B: matrix [N](x,y) with coordinates of the main object boundary
            % D2: distance map from mainObj to secObj, where only distances
            % that for secObj is specified, all other positions have Inf
            % value
            % range: number of pixels to generate the ray
            % pixSize: value of the pixel size
            %
            % Return values:
            % results: matrix with detected distances for each point of the mainObj
            % B: updated B-matrix with 
            % rayDestinationPosX: x-coordinates of the destination of the rays
            % rayDestinationPosY: y-coordinates of the destination of the rays
            % Bx1, Bx2, By1, By2: vectors with x and y coordinates of begining and the destination of all generated rays

            extendRays = logical(obj.View.handles.extendRays.Value);   % extend rays with additional vector rays
            extendRaysFactor = str2double(obj.View.handles.extendRaysFactor.String);  % precision at the end of the ray
            
            cWidth = size(D2, 2);    % width of the cropped image
            cHeight = size(D2, 1);   % height of the cropped image

            N = LineNormals2D(B);   % calculate normal vectors for each point of the main object perimeter
            % remove normals that are NaNs, quite rare when pixel is sticking
            % out as below, so it is better to smooth surfaces before the
            % calculation
            % 0 0 1
            % 1 1 1
            % 0 0 1

            nanVecY = find(isnan(N(:,1)));
            nanVecX = find(isnan(N(:,2)));
            nanVec = unique([nanVecY; nanVecX]);
            N(nanVec, :) = [];
            B(nanVec, :) = [];

            %                         % test of boundaries tracing
            %                         figure(102);
            %                         clf;
            %                         imshow(M1c,[]);
            %                         hold on;
            %                         plot(B(:, 2), B(:, 1), 'r', 'LineWidth', 1);
            %                         plot(Boundary(:, 2), Boundary(:, 1), '.r', Boundary([1 end], 2), Boundary([1 end], 1), '.g');
            
            % convert B matrix to Bx1, Bx2, By1, By2 vectors
            Bx1 = B(:, 2);
            Bx2 = B(:, 2) + range*N(:, 2);
            By1 = B(:, 1);
            By2 = B(:, 1) + range*N(:, 1);

            if extendRays == 1
                Bx1 = [Bx1; Bx1(1)]; %#ok<AGROW> % loop the coordinates, otherwise there will be a gap at the point when the main object tracing has started
                Bx2 = [Bx2; Bx2(1)]; %#ok<AGROW>
                By1 = [By1; By1(1)]; %#ok<AGROW>
                By2 = [By2; By2(1)]; %#ok<AGROW>

                % find difs
                pntDiff = sqrt(diff(Bx2).^2 + diff(By2).^2);    % distance between the points on at the ray destination
                pntDiffN_Orgn = sqrt(diff(Bx1).^2 + diff(By1).^2);   % distance between the points on at the ray origin, needed to find removed borders at the image edges

                dN_ind = find(pntDiff > extendRaysFactor);
                Border_ind = find(pntDiffN_Orgn >= 2);  % indices of the contour with brakes when the object touches the image edge

                noExtraPoints = sum(abs(floor(pntDiff(dN_ind)/extendRaysFactor))) + numel(dN_ind)*2;     % number of points to be added
                B2x1 = nan([numel(Bx1)+noExtraPoints, 1]);
                B2x2 = nan([numel(Bx1)+noExtraPoints, 1]);
                B2y1 = nan([numel(Bx1)+noExtraPoints, 1]);
                B2y2 = nan([numel(Bx1)+noExtraPoints, 1]);

                newIndex = 1;
                diffVecIndex = 1;
                for i=1:numel(Bx1)
                    if isempty(find(dN_ind==i, 1)) || sum(ismember(Border_ind, [i, i+1])) > 0
                        B2x1(newIndex) = Bx1(i);
                        B2x2(newIndex) = Bx2(i);
                        B2y1(newIndex) = By1(i);
                        B2y2(newIndex) = By2(i);
                        newIndex = newIndex + 1;
                        %if sum(ismember(Border_ind, [i, i+1])) > 0
                        %if ismember(Border_ind, i+1) == 1
                        if ismember(i+1, Border_ind) == 1
                            diffVecIndex = diffVecIndex + 1;
                        end
                    else
                        extraNsX = linspace(Bx2(dN_ind(diffVecIndex)), Bx2(dN_ind(diffVecIndex)+1), floor(abs(pntDiff(dN_ind(diffVecIndex)))/extendRaysFactor)+2);
                        extraNsY = linspace(By2(dN_ind(diffVecIndex)), By2(dN_ind(diffVecIndex)+1), floor(abs(pntDiff(dN_ind(diffVecIndex)))/extendRaysFactor)+2);

                        noExtraNs = numel(extraNsX);
                        B2x1(newIndex:newIndex+noExtraNs-1) = Bx1(i);    % duplicate the points
                        B2y1(newIndex:newIndex+noExtraNs-1) = By1(i);
                        B2x2(newIndex:newIndex+noExtraNs-1) = extraNsX';    % duplicate the points
                        B2y2(newIndex:newIndex+noExtraNs-1) = extraNsY';

                        newIndex = newIndex + noExtraNs;
                        diffVecIndex = diffVecIndex + 1;
                    end
                end

                NaN_index = find(isnan(B2x1(:,1)) == 1,1);    % remove NaNs
                Bx1 = B2x1(1:NaN_index-1);
                Bx2 = B2x2(1:NaN_index-1);
                By1 = B2y1(1:NaN_index-1);
                By2 = B2y2(1:NaN_index-1);
                B = By1;
                B(:, 2) = Bx1;
            end

            % % test ray vectors, D2, M1c needs to be taken into the function
            % from the parent one
            % figure(102)
            % clf;
            % D3 = D2;
            % D3(M1c == 1) = 0;
            % D3(~M2c) = 0;
            % imshow(D3,[0, 200]);
            % hold on;
            % %%imshow(255-D2,[]);
            % hPl = plot(B(:, 2), B(:, 1), 'r.', 'LineWidth', 1);
            % hPl.MarkerSize = 10;
            % plot([Bx1 Bx2]', [By1 By2]'); % x-vector, y-vector
            % ax = gca;
            % ax.XTick = [];
            % ax.YTick = [];

            % loop via each point of the mitochondria boundary
            % to detect the closest point where the ray hits ER
            results = Inf(size(B,1), 1);    % allocate space for results
            rayDestinationPosX = zeros(size(B,1), 1);    % allocate space for X-coordinate of the min points
            rayDestinationPosY = zeros(size(B,1), 1);    % allocate space for Y-coordinate of the min points

            %                         % This is a test code below that is using
            %                         % intersectPolylines or intersectLinePolyline
            %                         % functions from https://github.com/mattools/matGeom/
            %                         % performance is about 3-10 time slower
            %                         BoundarySec = bwboundaries(M2c, 8);     % trace boundary of the secondary objects on the image, result is cell array
            %                         tic
            %                         for point=1:size(B,1)
            %                             combinedPnts = [];
            %                             for secObjId = 1:numel(BoundarySec)
            %                                 %point = 3;
            %                                 rayPolyline = [Bx1(point), By1(point); Bx2(point), By2(point)];  % xy,
            %                                 pnts = intersectPolylines(BoundarySec{secObjId}, rayPolyline);
            %                                 combinedPnts = [combinedPnts; pnts];
            %
            %                                 %rayLine = [B(point,2), B(point,1), N(point, 2), N(point, 1)];  % [x0,y0,dx,dy]
            %                                 %pnts = intersectLinePolyline(rayLine, BoundarySec{secObjId});
            %                                 %combinedPnts = [combinedPnts; pnts];
            %                             end
            %                             if isempty(combinedPnts); continue; end
            %                             % have to add sorting of points here, to pickup
            %                             % only the closest one
            %                         end
            %                         t1=toc;

            for point=1:size(B,1)
                % calculate ray pixels
                dx = Bx2(point) - Bx1(point);
                dy = By2(point) - By1(point);
                nPnts = max([abs(dx) abs(dy)])+1;
                linSpacing = linspace(0, 1, nPnts);

                xVal = round(Bx1(point) + linSpacing*dx);
                yVal = round(By1(point) + linSpacing*dy);

                % remove coordinates that are out of the image
                indicesX1 = find(xVal < 1);        % x < 1
                indicesX2 = find(xVal > cWidth);   % x > width
                indicesY1 = find(yVal < 1);        % y < 1
                indicesY2 = find(yVal > cHeight);  % y > height
                indices = unique([indicesX1, indicesX2, indicesY1, indicesY2]);  % find unique indices
                xVal(indices) = [];
                yVal(indices) = [];

                % calculate the closest distance between main and secondary objects
                linIndices = sub2ind([cHeight, cWidth], yVal, xVal);    % convert coordinates of ray vector to linear indices
                minVal = min(min(D2(linIndices)));  % find minimal value for the distance
                if minVal ~= Inf    % do nothing if no hit
                    results(point) = minVal*pixSize;    % calculate minimal distance in desired units
                    pointIndex = find(D2(linIndices) == minVal);    % find a point that has minimal distance
                    if numel(pointIndex) == 1
                        rayDestinationPosY(point) = yVal(pointIndex);  % find it's coordinates
                        rayDestinationPosX(point) = xVal(pointIndex);
                    else    % sometimes there are more than one hit, if so find the closest hit to the starting point of the ray vector
                        point2 = 1;
                        dist1 = sqrt( (By1(point)-yVal(pointIndex(point2)))^2 + (Bx1(point)-xVal(pointIndex(point2)))^2 );
                        for ind2=2:numel(pointIndex)
                            dist2 = sqrt( (By1(point)-yVal(pointIndex(ind2)))^2 + (Bx1(point)-xVal(pointIndex(ind2)))^2 );
                            if dist2 < dist1
                                dist1=dist2;
                                point2 = ind2;
                            end
                        end
                        rayDestinationPosY(point) = yVal(pointIndex(point2));  % find it's coordinates
                        rayDestinationPosX(point) = xVal(pointIndex(point2));
                    end
                end
            end
        end
        
        function saveToExcel(obj, MCcalcExport, outFn)
            % function saveToExcel(obj, MCcalcExport, outFn)
            % generate Excel file with results
            
            % MCcalcExport(1).mainMaterial - main material name
            % MCcalcExport(1).secondaryMaterial - secondary material name
            % MCcalcExport(1).probingRangeInUnits - probing range in units
            % MCcalcExport(1).units - units
            % MCcalcExport(1).smoothing - smoothing factor
            % MCcalcExport(1).extendRays - extend rays with additional vector rays
            % MCcalcExport(1).extendRaysFactor - precision at the end of the ray
            % MCcalcExport(1).contactCutOff = contactCutOff;   % cut off distance for contacts
            % MCcalcExport(1).contactGapWidth = contactGapWidth;   % fuse contacts having brakes smaller than this number
            % MCcalcExport(1).pixSize - pixelSize
            % MCcalcExport(1).histBinningEdit - step used for generation of the histograms, defines positions of MCcalc(1).DistributionCenters
            
            % MCcalcExport(objId).Centroid - centroid of each main object, pixels
            % MCcalcExport(objId).slice - slice number of the object
            % MCcalcExport(objId).time - time point of the object
            % MCcalcExport(objId).MinDist - a vector with minimal distance for each hit from a point on a perimeter of the main obj. to the sec. obj
            % MCcalcExport(objId).rayDestinationPosX - a vector with X-coordinates of the hit point at the edge of the secondary object
            % MCcalcExport(objId).rayDestinationPosY - a vector with Y-coordinates of the hit point at the edge of the secondary object
            % MCcalcExport(objId).raySourcePosX - a vector with X-coordinates of rays the hit ray source point at the perimeter of the main object
            % MCcalcExport(objId).raySourcePosY - a vector with Y-coordinates of the hit ray source point at the perimeter of the main object
            % MCcalcExport(objId).mainPerimeterWithoutBorder - length of the detected main object perimeter, excluding clipped areas at edges of the image
            % MCcalcExport(objId).mainPerimeterBorder - length of the object that is touching the border of the image
            % MCcalcExport(objId).mainPerimeterNoPixels - total number of points from where the rays were generated, excluding clipped areas at edges of the image
            % MCcalcExport(objId).mainMinThicknessUnits - average min thickness of the main object
            % MCcalcExport(objId).mainAreaUnits - area of the main object in units
            % MCcalcExport(objId).mainEccentricity - eccentricity of the main object
            % MCcalcExport(objId).secondaryHitsNoPixels - Total number of points where the rays hit the secondary objects
            % MCcalcExport(objId).DistributionMinDist - distribution of minimal distances
            % MCcalcExport(objId).DistributionMinDistNorm - distribution normalized to MCcalcExport(objId).mainPerimeterNoPixels
            % MCcalcExport(objId).cutOffContactX - an array with X-coordinates of the detected contacts
            % MCcalcExport(objId).cutOffContactY - an array with Y-coordinates of the detected contacts
            % MCcalcExport(objId).contactLength - an array with X-coordinates of the detected contacts
            % MCcalcExport(objId).contactMeanDistance - an array with average distance at the contact between the organelles of interest
            
            % MCcalcExport(1).DistributionCenters - position of the X centers for the distribution
            % MCcalcExport(1).DistributionMinDistNormAv - averaged normalized distribution for each MCcalcExport(1).DistributionCenters
  
            
            warning('off', 'MATLAB:xlswrite:AddSheet');
            % Sheet 1, general results
            s = {'MCcalc: calculate distribution of minimal distances from main object to secondary objects'};
            s(2,1) = {['Image directory: ' fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'))]};
            s(3,1) = {['Main object material: ' cell2mat(MCcalcExport(1).mainMaterial)]};
            s(3,5) = {['Pixel size/units: ' num2str(MCcalcExport(1).pixSize) ' ' MCcalcExport(1).units]};
            s(3,9) = {['Smoothing of rays, px: ' num2str(MCcalcExport(1).smoothing)]};
            s(3,13) = {['Extended rays, logical: ' num2str(MCcalcExport(1).extendRays)]};
            s(4,1) = {['Secondary object material: ' cell2mat(MCcalcExport(1).secondaryMaterial)]};
            s(4,5) = {['Probing range: ' num2str(MCcalcExport(1).probingRangeInUnits) ' ' MCcalcExport(1).units]};
            s(4,9) = {['Histogram bin factor: ' num2str(MCcalcExport(1).histBinningEdit)]};
            s(4,13) = {['Extend rays precision, px: ' num2str(MCcalcExport(1).extendRaysFactor)]};
            
            s(5,1) = {['Model filename: ' obj.mibModel.I{obj.mibModel.Id}.modelFilename]};
            s(8,1) = {'ObjId'}; s(8,2) = {'Time'}; s(8,3) = {'Z, index'}; s(8,4) = {'X, px'}; s(8,5) = {'Y, px'}; s(8,6) = {sprintf('PerimeterWithoutBorder, %s', MCcalcExport(1).units)};
            s(8,7) = {sprintf('BorderPerimeter, %s', MCcalcExport(1).units)}; s(8,8) = {'NoPixelsOfPerimeterWithoutBorder'}; s(8,9) = {'NoOfHitPixels'};
            s(8,10) = {sprintf('MinThickness, %s', MCcalcExport(1).units)}; s(8,11) = {sprintf('Area, %s', MCcalcExport(1).units)};   s(8,12) = {'Eccentricity, 0-circle'}; 
            
            shiftY = 8;
            shiftX = 10;
            for objId=1:numel(MCcalcExport)
                s(shiftY+objId, 1) = num2cell(objId);
                s(shiftY+objId, 2) = num2cell(MCcalcExport(objId).time);
                s(shiftY+objId, 3) = num2cell(MCcalcExport(objId).slice);
                s(shiftY+objId, 4) = num2cell(MCcalcExport(objId).Centroid(1));
                s(shiftY+objId, 5) = num2cell(MCcalcExport(objId).Centroid(2));
                s(shiftY+objId, 6) = num2cell(MCcalcExport(objId).mainPerimeterWithoutBorder);
                s(shiftY+objId, 7) = num2cell(MCcalcExport(objId).mainPerimeterBorder);
                s(shiftY+objId, 8) = num2cell(MCcalcExport(objId).mainPerimeterNoPixels);
                s(shiftY+objId, 9) = num2cell(MCcalcExport(objId).secondaryHitsNoPixels);
                s(shiftY+objId, 10) = num2cell(MCcalcExport(objId).mainMinThicknessUnits);
                s(shiftY+objId, 11) = num2cell(MCcalcExport(objId).mainAreaUnits);
                s(shiftY+objId, 12) = num2cell(MCcalcExport(objId).mainEccentricity);
                
                %     shiftX = shiftX + 1;
                %     if objId==1     % plot DistributionCenters only once, because they are the same for all objects
                %         s(shiftY, shiftX) = {'Distribution of minimal distances for objects'};
                %         s(shiftY, shiftX+numel(MCcalcExport)+2) = {'Normalized distribution to number of points of the main object perimeter'};
                %         s(shiftY+1, shiftX) = {'Center'};
                %         maxNo = numel(MCcalcExport(objId).DistributionCenters);
                %         s(shiftY+2:shiftY+1+maxNo, shiftX) = num2cell(cat(1, MCcalcExport(objId).DistributionCenters));
                %     end
                %     s(shiftY+1, shiftX+1) = {[num2str(objId) ' distribution']};
                %     s(shiftY+1, shiftX+numel(MCcalcExport)+2) = {[num2str(objId) ' normalized']};
                %     s(shiftY+2:shiftY+1+maxNo, shiftX+1) = num2cell(cat(1, MCcalcExport(objId).DistributionMinDist));
                %     s(shiftY+2:shiftY+1+maxNo, shiftX+numel(MCcalcExport)+2) = num2cell(cat(1, MCcalcExport(objId).DistributionMinDistNorm));
            end
            xlswrite2(outFn, s, 'General results', 'A1');
            
            % Sheet 2, Distribution of distances
            s = {'Distribution of minimal distances for objects'};
            shiftY = 2;
            shiftX = 2;
            % plot DistributionCenters only once, because they are the same for all objects
            s(shiftY+1, shiftX) = {['Distance, ' MCcalcExport(1).units]};
            maxNo = numel(MCcalcExport(1).DistributionCenters);
            s(shiftY+2:shiftY+1+maxNo, shiftX) = num2cell(cat(1, MCcalcExport(1).DistributionCenters));
            for objId=1:numel(MCcalcExport)
                shiftX = shiftX + 1;
                s(shiftY+1, shiftX) = {['Obj. ' num2str(objId)]};
                s(shiftY+2:shiftY+1+maxNo, shiftX) = num2cell(cat(1, MCcalcExport(objId).DistributionMinDist));
            end
            xlswrite2(outFn, s, 'Dist. of distances', 'A1');
            
            % Sheet 3, Distribution of normalized distances
            s = {'Normalized distribution to number of points of the main object perimeter'};
            shiftY = 2;
            shiftX = 2;
            % plot DistributionCenters only once, because they are the same for all objects
            s(shiftY+1, shiftX) = {['Distance, ' MCcalcExport(1).units]};
            s(shiftY+1, shiftX+1) = {'Averaged'};
            maxNo = numel(MCcalcExport(1).DistributionCenters);
            s(shiftY+2:shiftY+1+maxNo, shiftX) = num2cell(cat(1, MCcalcExport(1).DistributionCenters));
            s(shiftY+2:shiftY+1+maxNo, shiftX+1) = num2cell(cat(1, MCcalcExport(1).DistributionMinDistNormAv));
            
            shiftX = shiftX+6;
            s(shiftY+1, shiftX) = {['Distance, ' MCcalcExport(1).units]};
            s(shiftY+2:shiftY+1+maxNo, shiftX) = num2cell(cat(1, MCcalcExport(1).DistributionCenters));
            for objId=1:numel(MCcalcExport)
                shiftX = shiftX + 1;
                s(shiftY+1, shiftX+1) = {['Obj. ' num2str(objId)]};
                s(shiftY+2:shiftY+1+maxNo, shiftX+1) = num2cell(cat(1, MCcalcExport(objId).DistributionMinDistNorm));
            end
            xlswrite2(outFn, s, 'Dist. of distances (norm)', 'A1');
            
            % Sheet 4, Detected contacts
            if MCcalcExport(1).contactCutOff > 0
                s = {'Length of detected contacts'};
                s(2, 1) = {['Cut off distance: ' num2str(MCcalcExport(1).contactCutOff) ' ' MCcalcExport(1).units]};
                s(3, 1) = {['Fuse contacts with brakes smaller than : ' num2str(MCcalcExport(1).contactGapWidth) ' pixels']};
                %s(1, 6) = {'Length of contacts is based on length of the main object'};
                %s(2, 6) = {'Contacts should have 2 or more pixels'};
                
                s(5, 2) = {'Obj. Id'};
                s(5, 3) = {sprintf('PerimeterWithoutBorder, %s', MCcalcExport(1).units)};
                s(5, 4) = {'Number of contacts'};
                s(5, 5) = {sprintf('Sum length of contacts, %s', MCcalcExport(1).units)};
                s(5, 6) = {'Ratio Contacts/Obj'};
                s(5, 9) = {sprintf('Length of each contact, %s', MCcalcExport(1).units)};
                maxContactsNumber = max(arrayfun(@(x) numel(x.contactLength), MCcalcExport));
                s(5, 10+maxContactsNumber) = {'Mean distance of each contact'};
                
                for objId=1:numel(MCcalcExport)
                    s(objId+5, 2) = {['Obj. ' num2str(objId)]};
                    s(objId+5, 3) = num2cell(MCcalcExport(objId).mainPerimeterWithoutBorder);
                    s(objId+5, 4) = num2cell(numel(find(MCcalcExport(objId).contactLength>0)));
                    s(objId+5, 5) = num2cell(sum(MCcalcExport(objId).contactLength));
                    s(objId+5, 6) = num2cell( sum(MCcalcExport(objId).contactLength)/MCcalcExport(objId).mainPerimeterWithoutBorder );
                    s(objId+5, 9:8+numel(MCcalcExport(objId).contactLength)) = num2cell(cat(1, MCcalcExport(objId).contactLength));
                    s(objId+5, 10+maxContactsNumber:9+maxContactsNumber+numel(MCcalcExport(objId).contactLength)) = num2cell(cat(1, MCcalcExport(objId).contactMeanDistance));
                end
                xlswrite2(outFn, s, 'Contacts', 'A1');
            end
            
            
            % % Sheet 5 save actual numbers
            s = {'Check Sheet 1 also!!!'};
            s(1, 4) = {sprintf('RAW data, distance between the main and secondary organelle for each hit, i.e. when the ray hits the secondary object in %s', MCcalcExport(1).units)};
            s(2, 1) = {'ObjId:'};
            for objId=1:numel(MCcalcExport)
                maxNo = numel(MCcalcExport(objId).MinDist);
                
                s(2, objId+1) = {num2str(objId)};
                s(3:maxNo+2, objId+1) = num2cell(cat(1, MCcalcExport(objId).MinDist))';
            end
            xlswrite2(outFn, s, 'RAW dist to hits', 'A1');
        end
        
        
    end
end