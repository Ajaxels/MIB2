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

classdef mibMeasureToolController < handle
    % classdef mibMeasureToolController < handle
    % a controller class for the measurements subwindow available via
    % MIB->Menu->Tools->Measure length->Measure tool
    
    % Updates:
    % 04.10.2017, IB added possibility to do not calculate intensity
    % profiles, fix of recalculation bug, when measurements were moved to
    % the current slice
    
    properties
        mibController
        % handle to mibController
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        indices
        % indeces of the selected rows
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback(obj, src, evnt)
            switch evnt.Parameter.Name
                case 'addMeasurement'
                    obj.addBtn_Callback();
                case 'updatePosition'
                    % position of measurement was updated
                    if obj.View.handles.previewIntensityCheck.Value == 1
                        % show preview of the intensity profile
                        obj.previewIntensityProfile();
                    end
            end
        end

        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case {'updateGuiWidgets'}
                    obj.updateWidgets();
                case 'undoneBackup'
                    obj.updateTable();
                case 'updatePosition'
                    % position of measurement was updated
                    if obj.View.handles.previewIntensityCheck.Value == 1
                        % show preview of the intensity profile
                        obj.previewIntensityProfile();
                    end
                case 'addMeasurement'
                    obj.addBtn_Callback();
            end
        end
    end
    
    methods
        function obj = mibMeasureToolController(mibModel, mibController)
            obj.mibModel = mibModel;    % assign model
            obj.mibController = mibController;
            guiName = 'mibMeasureToolGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % add callback for keyboard press
            % an alternative solution is to notify mibModel as in mibStatisticsGUI.mibStatisticsGUI_KeyPressFcn
            % eventData = struct();
            % eventData.eventdata = eventdata;
            % eventData = ToggleEventData(eventData);
            % notify(handles.winController.mibModel, 'keyPressEvent', eventData);
            obj.View.gui.WindowKeyPressFcn = (@(hObject, eventdata, handles) obj.mibController.mibGUI_WindowKeyPressFcn(eventdata));   % turn ON callback for the keys

            obj.indices = [];
            obj.updateWidgets();
            
            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            obj.listener{2} = addlistener(obj.mibModel, 'undoneBackup', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            obj.listener{3} = addlistener(obj.mibModel.I{obj.mibModel.Id}.hMeasure, 'updatePosition', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            %obj.listener{4} = addlistener(obj.mibModel.I{obj.mibModel.Id}.hMeasure, 'addMeasurement', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            obj.listener{4} = addlistener(obj.mibModel, 'modelNotify', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing mibMeasureToolController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete mibMeasureToolController window
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
            % update widgets of the window
            
            % updating color channels
            maxColors = obj.mibModel.getImageProperty('colors');
            colList = cell([maxColors+1, 1]);
            colList(1) = {'All'};
            for col_ch=1:maxColors
                colList(col_ch+1) = cellstr(['Ch ' num2str(col_ch)]);
            end
            obj.View.handles.imageColChPopup.Value = 1;
            obj.View.handles.imageColChPopup.String = colList;
            
            if strcmp(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Options.splinemethod, 'spline')
                obj.View.handles.modePopup.Value = 1;
            else
                obj.View.handles.modePopup.Value = 2;
            end
            
            pixSize = obj.mibModel.getImageProperty('pixSize');
            pixString = sprintf('%f / %f / %f', pixSize.x, pixSize.y, pixSize.z);
            obj.View.handles.voxelSizeTxt.String = pixString;
            obj.updateTable();

            % update session settings
            if ~isfield(obj.mibModel.sessionSettings, 'measureTool')
                obj.mibModel.sessionSettings.measureTool.integrationWidth = '5';
                obj.mibModel.sessionSettings.measureTool.noPointsEdit = '5';
                obj.mibModel.sessionSettings.measureTool.Angle.Info = '';
                obj.mibModel.sessionSettings.measureTool.Caliper.Info = '';
                obj.mibModel.sessionSettings.measureTool.Circle.Info = '';
                obj.mibModel.sessionSettings.measureTool.DistanceFreehand.Info = '';
                obj.mibModel.sessionSettings.measureTool.DistanceLinear.Info = '';
                obj.mibModel.sessionSettings.measureTool.DistancePolyline.Info = '';
                obj.mibModel.sessionSettings.measureTool.Point.Info = '';
            end
            obj.View.handles.integrationWidth.String = obj.mibModel.sessionSettings.measureTool.integrationWidth;
            obj.View.handles.noPointsEdit.String = obj.mibModel.sessionSettings.measureTool.noPointsEdit;
        end
        
        function nRows = updateTable(obj)
            % function nRows = updateTable(obj)
            % update table with measurements
            % 
            % Parameters:
            %
            % Return values:
            % nRows: number of Rows in the table
            
            numberOfLabels = obj.mibModel.I{obj.mibModel.Id}.hMeasure.getNumberOfMeasurements();
            filterString = obj.View.handles.filterPopup.String;
            filterText = filterString{obj.View.handles.filterPopup.Value};
            obj.mibModel.I{obj.mibModel.Id}.hMeasure.typeToShow = filterText;     % update which measurements to show in the imageAxes
            if  ~strcmp(filterText, 'All')  % do filtering
                indeces=find(ismember([obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data.type], filterText));
            else
                indeces = 1:numberOfLabels;
            end
            
            if numel(indeces) >= 1
                data = cell([numel(indeces), 5]);
                data(:,1) = {obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(indeces).n}';
                data(:,2) = [obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(indeces).type]';
                data(:,3) = {obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(indeces).value}';
                data(:,4) = {obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(indeces).info}';
                data(:,5) = {obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(indeces).Z}';
                data(:,6) = {obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(indeces).T}';
                obj.View.handles.measureTable.Data = data;
            else
                data = cell([3,1]);
                obj.View.handles.measureTable.Data = data;
            end
            nRows = numel(indeces);
        end
        
        function addBtn_Callback(obj)
            % function addBtn_Callback(obj)
            % add a new measurement
            
            obj.mibModel.mibDoBackup('measurements', 0);
            
            colCh = obj.View.handles.imageColChPopup.Value - 1;
            typeString = obj.View.handles.measureTypePopup.String;
            finetuneCheck = obj.View.handles.finetuneCheck.Value;
            integrateCheck = obj.View.handles.integrateCheck.Value;
            integrationWidth = str2double(obj.View.handles.integrationWidth.String);
            noPoints = str2double(obj.View.handles.noPointsEdit.String);
            calcIntensity = obj.View.handles.calcIntensityCheck.Value;
            showEditInfoDlg = obj.View.handles.showEditInfoDlg.Value;   % show dialog to provide information about the measurement
            
            obj.View.handles.addBtn.BackgroundColor = 'r';
            %disableSegmentation = obj.mibController.mibView.disableSegmentation;
            obj.mibController.mibModel.disableSegmentation = 1;
            
            switch typeString{obj.View.handles.measureTypePopup.Value}
                case 'Angle'
                    if showEditInfoDlg
                        [~, obj.mibModel.sessionSettings.measureTool.Angle.Info] = obj.mibModel.I{obj.mibModel.Id}.hMeasure.AngleFun(obj.mibController, [], colCh, finetuneCheck, calcIntensity, obj.mibModel.sessionSettings.measureTool.Angle.Info);
                    else
                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.AngleFun(obj.mibController, [], colCh, finetuneCheck, calcIntensity, NaN);
                    end
                case 'Caliper'
                    if showEditInfoDlg
                        [~, obj.mibModel.sessionSettings.measureTool.Caliper.Info] = obj.mibModel.I{obj.mibModel.Id}.hMeasure.CaliperFun(obj.mibController, [], colCh, finetuneCheck, calcIntensity, obj.mibModel.sessionSettings.measureTool.Caliper.Info);
                    else
                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.CaliperFun(obj.mibController, [], colCh, finetuneCheck, calcIntensity, NaN);
                    end
                case 'Circle (R)'
                    if showEditInfoDlg
                        [~, obj.mibModel.sessionSettings.measureTool.Circle.Info] = obj.mibModel.I{obj.mibModel.Id}.hMeasure.CircleFun(obj.mibController, [], colCh, finetuneCheck, calcIntensity, obj.mibModel.sessionSettings.measureTool.Circle.Info);
                    else
                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.CircleFun(obj.mibController, [], colCh, finetuneCheck, calcIntensity, NaN);
                    end
                case 'Distance (freehand)'
                    freehandOptions.fixNumberPoints = obj.View.handles.fixNumberPoints.Value;
                    freehandOptions.noPointsEdit  = obj.View.handles.noPointsEdit.String;
                    if showEditInfoDlg
                        freehandOptions.infoDlgText = obj.mibModel.sessionSettings.measureTool.DistanceFreehand.Info;
                        [~, obj.mibModel.sessionSettings.measureTool.DistanceFreehand.Info] = obj.mibModel.I{obj.mibModel.Id}.hMeasure.DistanceFreeFun(obj.mibController, colCh, finetuneCheck, calcIntensity, freehandOptions);
                    else
                        freehandOptions.Info = NaN;
                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.DistanceFreeFun(obj.mibController, colCh, finetuneCheck, calcIntensity, freehandOptions);
                    end
                case 'Distance (linear)'
                    if ~integrateCheck; integrationWidth = []; end
                    if showEditInfoDlg
                        distanceLinearOptions.infoDlgText = obj.mibModel.sessionSettings.measureTool.DistanceLinear.Info;
                        [~, obj.mibModel.sessionSettings.measureTool.DistanceLinear.Info] = obj.mibModel.I{obj.mibModel.Id}.hMeasure.DistanceFun(obj.mibController, [], colCh, finetuneCheck, integrationWidth, calcIntensity, distanceLinearOptions);
                    else
                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.DistanceFun(obj.mibController, [], colCh, finetuneCheck, integrationWidth, calcIntensity);
                    end 
                case 'Distance (polyline)'
                    if showEditInfoDlg
                        distancePolylineOptions.infoDlgText = obj.mibModel.sessionSettings.measureTool.DistancePolyline.Info;
                        [~, obj.mibModel.sessionSettings.measureTool.DistancePolyline.Info] = obj.mibModel.I{obj.mibModel.Id}.hMeasure.DistancePolyFun(obj.mibController, [], colCh, noPoints, finetuneCheck, calcIntensity, distancePolylineOptions);
                    else
                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.DistancePolyFun(obj.mibController, [], colCh, noPoints, finetuneCheck, calcIntensity);
                    end
                case 'Point'
                    if showEditInfoDlg
                        [~, obj.mibModel.sessionSettings.measureTool.Point.Info] = obj.mibModel.I{obj.mibModel.Id}.hMeasure.PointFun(obj.mibController, [], colCh, finetuneCheck, calcIntensity, obj.mibModel.sessionSettings.measureTool.Point.Info);
                    else
                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.PointFun(obj.mibController, [], colCh, finetuneCheck, calcIntensity, NaN);
                    end
            end
            obj.mibController.mibModel.disableSegmentation = 0;
            obj.View.handles.addBtn.BackgroundColor = 'g';
            noRows = obj.updateTable();
            drawnow;            

            eventdata.Indices = [noRows, 2];   % store current indices, because they will be removed in obj.updateTable;
            obj.measureTable_CellSelectionCallback(eventdata);

            userData = obj.View.handles.measureTable.UserData;
            jTable = userData.jTable;   % jTable is initializaed in the beginning of mibGUI.m
            jTable.changeSelection(noRows-1, 1, false, false);    % automatically calls mibSegmentationTable_CellSelectionCallback

            % count user's points
            obj.mibModel.preferences.Users.Tiers.numberOfMeasurements = obj.mibModel.preferences.Users.Tiers.numberOfMeasurements+1;
            notify(obj.mibModel, 'updateUserScore');     % update score using default obj.mibModel.preferences.Users.singleToolScores increase


            %notify(obj.mibModel, 'plotImage');
            %obj.mibController.plotImage();
        end
        
        function previewIntensityProfile(obj)
            if ~strcmp(obj.mibModel.I{obj.mibModel.Id}.hMeasure.roi.type, 'imline')
                return;
            end
            position(:,1) = obj.mibModel.I{obj.mibModel.Id}.hMeasure.roi.pos(:,1)';     % x
            position(:,2) = obj.mibModel.I{obj.mibModel.Id}.hMeasure.roi.pos(:,2)';     % y
            
            % define coordinates for the image subwindow
            dXY = 0;    % increase image boundaries by this factor
            if obj.View.handles.integrateCheck.Value == 1
                dXY = str2double(obj.View.handles.noPointsEdit.String);
            end
            % find minimal coordinates of the subwindow 
            xMin = max([1 round(min(position(:,1)))-dXY]);
            yMin = max([1 round(min(position(:,2)))-dXY]);

            % calculate the distance (hypot = pythagoras)
            orientation = obj.mibModel.I{obj.mibModel.Id}.orientation;
            pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            if orientation == 1   % zx orientation
                % find maximal coordinates for the subwindow 
                xMax = min([max(round(position(:,1)))+dXY obj.mibModel.I{obj.mibModel.Id}.depth]);
                yMax = min([max(round(position(:,2)))+dXY obj.mibModel.I{obj.mibModel.Id}.width]);
                A = diff(position(:,1))*pixSize.z;
                B = diff(position(:,2))*pixSize.x;
                if obj.View.handles.integrateCheck.Value == 0
                    % create image space (for intensity)
                    %[x, y] = meshgrid(1:obj.mibModel.I{obj.mibModel.Id}.depth, 1:obj.mibModel.I{obj.mibModel.Id}.width);
                    [x, y] = meshgrid(1:xMax-xMin+1, 1:yMax-yMin+1);
                end
            elseif orientation == 2   % zy orientation
                % find maximal coordinates for the subwindow 
                xMax = min([max(round(position(:,1)))+dXY obj.mibModel.I{obj.mibModel.Id}.depth]);
                yMax = min([max(round(position(:,2)))+dXY obj.mibModel.I{obj.mibModel.Id}.height]);
                A = diff(position(:,1))*pixSize.z;
                B = diff(position(:,2))*pixSize.y;
                if obj.View.handles.integrateCheck.Value == 0
                    % create image space (for intensity)
                    %[x, y] = meshgrid(1:obj.mibModel.I{obj.mibModel.Id}.depth, 1:obj.mibModel.I{obj.mibModel.Id}.height);
                    [x, y] = meshgrid(1:xMax-xMin+1, 1:yMax-yMin+1);
                end
            else        % xy orientation
                % find maximal coordinates for the subwindow 
                xMax = min([max(round(position(:,1)))+dXY obj.mibModel.I{obj.mibModel.Id}.width]);
                yMax = min([max(round(position(:,2)))+dXY obj.mibModel.I{obj.mibModel.Id}.height]);
                A = diff(position(:,1))*pixSize.x;
                B = diff(position(:,2))*pixSize.y;
                if obj.View.handles.integrateCheck.Value == 0
                    % create image space (for intensity)
                    %[x, y] = meshgrid(1:obj.mibModel.I{obj.mibModel.Id}.width, 1:obj.mibModel.I{obj.mibModel.Id}.height);
                    [x, y] = meshgrid(1:xMax-xMin+1, 1:yMax-yMin+1);
                end
            end
            Distance = hypot(A,B);
            
            if obj.View.handles.integrateCheck.Value == 0
                 % calculate a length vector
                t = [ 0 ; hypot(diff(position(:,1)),diff(position(:,2))) ];
                t = cumsum(t);
                
                % discretize the measurement line
                %Ni = 200;
                Ni = max(t);
                ti = linspace(0, max(t), Ni);
                xi = interp1(t, position(:,1)-xMin, ti);
                yi = interp1(t, position(:,2)-yMin, ti);
            end
            
            colCh = obj.View.handles.imageColChPopup.Value - 1;
            getDataOptions.blockModeSwitch = 0;
            getDataOptions.y = [yMin, yMax];
            getDataOptions.x = [xMin, xMax];
            im = cell2mat(obj.mibModel.getData2D('image', NaN, NaN, colCh, getDataOptions));
            
            % interpolate the intensity profile along the measurement line
            if obj.View.handles.integrateCheck.Value == 0
                for ch=1:size(im, 3)
                    profile(ch, :) = interp2(x, y, double(im(:,:,ch)), xi, yi); %#ok<AGROW>
                end
            else
                profile = mibImageProfileIntegrate(im, position(1,1)-xMin, position(1,2)-yMin, position(2,1)-xMin, position(2,2)-yMin, str2double(obj.View.handles.noPointsEdit.String));
                %ti2 = linspace(0, Distance, size(profile,2));
                %Distance = profileLength*pixSize.x;
            end

            if obj.View.handles.integrateCheck.Value == 0
                ti = linspace(0, Distance, Ni);
            else
                ti = linspace(0, Distance, size(profile, 2));
            end
            h = plot(obj.View.handles.profileAxes, ti, profile(1:end,:));
            if colCh==0 && size(profile,1) > 1
                for colId=1:size(profile,1)
                    h(colId).Color = obj.mibModel.displayedLutColors(colId, :);
                end
            end
            ax = gca;
            ax.XLim = [0 ti(end)];
            ax.YLim = [min(min(profile)) max(max(profile))];
            grid;
        end
        
        function measureTable_CellSelectionCallback(obj, eventdata)
            % function measureTable_CellSelectionCallback(obj, eventdata)
            % a callback for selection of cells in obj.View.handles.measureTable
            %
            % Parameters:
            % eventdata:  structure with the following fields (see UITABLE)
            %	Indices - row and column indices of the cell(s) currently selecteds
            % noJumpSwitch: a logical switch that blocks jump to measurement

            if nargin == 2
                obj.indices = eventdata.Indices;
            end
            
            ids = obj.indices(:,1);
            ids = [obj.View.handles.measureTable.Data{ids,1}];
            cla(obj.View.handles.profileAxes);
            %obj.View.handles.profileAxes.NextPlot = 'add';
            
            lutColors = obj.mibModel.displayedLutColors;
            colCh = obj.View.handles.imageColChPopup.Value - 1;
            
            for i=1:numel(ids)
                if i == 2
                    obj.View.handles.profileAxes.NextPlot = 'add';
                end
                if colCh==0
                    noColorChannels = size(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(ids(i)).profile,1) - 1;
                    h{i} = plot(obj.View.handles.profileAxes, ...
                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(ids(i)).profile(1,:), ...
                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(ids(i)).profile(2:end,:));
                    %set(h{i}, 'color', colorOrder(mod(i, size(colorOrder,1))+1,:));
                    if noColorChannels > 1
                        for colId=1:noColorChannels
                            set(h{i}(colId), 'color', lutColors(colId,:));
                        end
                    end
                else
                    colId = min([colCh+1, size(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(ids(i)).profile,1)]);
                    h{i} = plot(obj.View.handles.profileAxes, ...
                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(ids(i)).profile(1,:), ...
                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(ids(i)).profile(colId,:));
                    if numel(ids) == 1
                        h{i}.Color = lutColors(colCh,:);
                    end
                end
            end
            grid on;
            obj.View.handles.profileAxes.NextPlot = 'replace';
            
            % jump to the selected measurement
            if obj.View.handles.autoJumpCheck.Value && size(obj.indices,1) == 1
                obj.measureTable_cm('Jump');
            end
            figure(obj.View.gui);
        end
        
        function measureTable_cm(obj, parameter)
            % function measureTable_cm(obj, parameter)
            % a context menu for obj.View.handles.measureTable
            %
            % Parameters:
            % parameter: a string with the selected entry:
            % @li 'ModifyInfo' - update info text
            % @li 'Jump' - jump to the selected measurement
            % @li 'Modify' - modify the selected measurement
            % @li 'Duplicate' - duplicate the selected measurement
            % @li 'Plot' - plot the intensity profile 
            % @li 'Kymograph' - generate kymograph
            % @li 'Delete' - delete the selected measurement
            
            global mibPath;
            
            data = obj.View.handles.measureTable.Data;
            if isempty(data{1,1}); return; end
            if isempty(obj.indices); return; end
            
            rowId = obj.indices(1,1);
            n = data{rowId,1};
            
            switch parameter
                case 'ModifyInfo'
                    rowIds = obj.indices(:,1);
                    prompts = {'Update info field:'};
                    defAns = {obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(data{rowIds(1),1}).info};
                    dlgTitle = 'Info field';
                    answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle);
                    if isempty(answer); return; end
                    for i=1:numel(rowIds)
                        n = data{rowIds(i),1};
                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(n).info = answer{1};
                    end
                    eventdata.Indices = obj.indices;   % store current indices, because they will be removed in obj.updateTable;
                    obj.updateTable();
                    drawnow;
                    obj.measureTable_CellSelectionCallback(eventdata);
                case 'Jump'
                    if size(obj.indices,1) > 1
                        errordlg('Please select a single cell and try again!','Wrong selection','modal');
                        return;
                    end
                    
                    t = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(n).T;
                    z = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(n).Z;
                    x = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(n).X;
                    y = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(n).Y;
                    % move image-view to the object
                    obj.mibModel.I{obj.mibModel.Id}.moveView(x(end), y(end));
                    
                    % change t
                    if obj.mibModel.getImageProperty('time') > 1
                        eventdata = ToggleEventData(floor(t));
                        notify(obj.mibModel, 'updateTimeSlider', eventdata);
                    end
                    
                    % change z
                    [~, ~, ~, depth] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'image');
                    %if size(handles.h.Img{handles.h.Id}.I.img, handles.h.Img{handles.h.Id}.I.orientation) > 1
                    if depth > 1
                        eventdata = ToggleEventData(floor(z));
                        notify(obj.mibModel, 'updateLayerSlider', eventdata);
                    else
                        notify(obj.mibModel, 'plotImage');
                    end
                case 'Modify'
                    if size(obj.indices, 1) > 1
                        errordlg('Please select a single entry and try again!', 'Wrong selection', 'modal');
                        return;
                    end
                    obj.mibModel.mibDoBackup('measurements', 0);
                    
                    % first jump to the measurement
                    z = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(n).Z;
                    t = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(n).T;
                    
                    % change t
                    if obj.mibModel.getImageProperty('time') > 1
                        obj.mibController.mibView.handles.mibChangeTimeEdit.String = floor(t);
                        obj.mibController.mibChangeTimeEdit_Callback();
                    end
                    
                    % change z
                    [~, ~, ~, depth] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'image');
                    %if size(handles.h.Img{handles.h.Id}.I.img, handles.h.Img{handles.h.Id}.I.orientation) > 1
                    if depth > 1
                        obj.mibController.mibView.handles.mibChangeLayerEdit.String = floor(z);
                        obj.mibController.mibChangeLayerEdit_Callback();
                    else
                        obj.mibController.plotImage();
                    end
                    
                    % update measurement
                    colCh = obj.View.handles.imageColChPopup.Value - 1;
                    integrateCheck = obj.View.handles.integrateCheck.Value;
                    widthProfile = [];
                    if integrateCheck
                        widthProfile = str2double(obj.View.handles.noPointsEdit.String);
                    end
                    calcIntensity = obj.View.handles.calcIntensityCheck.Value;
                    
                    obj.mibModel.I{obj.mibModel.Id}.hMeasure.editMeasurements(obj.mibController, n, colCh, widthProfile, 1, calcIntensity);
                    eventdata.Indices = obj.indices;   % store current indices, because they will be removed in obj.updateTable;
                    obj.updateTable();
                    drawnow;
                    obj.measureTable_CellSelectionCallback(eventdata);

                    userData = obj.View.handles.measureTable.UserData;
                    jTable = userData.jTable;   % jTable is initializaed in the beginning of mibGUI.m
                    jTable.changeSelection(obj.indices(1)-1, 1, false, false);    % automatically calls mibSegmentationTable_CellSelectionCallback

                case 'Recalculate'
                    obj.mibModel.mibDoBackup('measurements', 0);
                    wb = waitbar(0, sprintf('Recalculating the measurements\nPlease wait...'), 'Name', 'Recalculating');
                    % update measurement
                    colCh = obj.View.handles.imageColChPopup.Value - 1;
                    integrateCheck = obj.View.handles.integrateCheck.Value;
                    widthProfile = [];
                    if integrateCheck
                        widthProfile = str2double(obj.View.handles.noPointsEdit.String);
                    end
                    finetuneCheck = 0;
                    noOfMeasurements = size(obj.indices, 1);
                    calcIntensity = obj.View.handles.calcIntensityCheck.Value;
                    obj.mibModel.I{obj.mibModel.Id}.hMeasure.fixZ = true;  % do not update Z and T values when recalculating measurements
                    for i=1:noOfMeasurements
                        n = obj.indices(i,1);
                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.editMeasurements(obj.mibController, n, colCh, widthProfile, finetuneCheck, calcIntensity);
                        waitbar(i/noOfMeasurements);
                    end
                    obj.mibModel.I{obj.mibModel.Id}.hMeasure.fixZ = false;
                    eventdata.Indices = obj.indices;   % store current indices, because they will be removed in obj.updateTable;
                    obj.updateTable();
                    drawnow;
                    obj.measureTable_CellSelectionCallback(eventdata);
                    delete(wb);
                case 'Duplicate'
                    obj.mibModel.mibDoBackup('measurements', 0);
                    newData = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(n);
                    obj.mibModel.I{obj.mibModel.Id}.hMeasure.addMeasurements(newData, n);
                    obj.updateTable();
                    obj.mibController.plotImage();
                case 'Plot'
                    figure(1951);
                    clf;
                    ax = axes();
                    rowId = obj.indices(:,1);
                    n = [data{rowId, 1}];
                    ax.NextPlot = 'add';
                    
                    lutColors = obj.mibModel.displayedLutColors;
                    colCh = obj.View.handles.imageColChPopup.Value - 1;
                    
                    for i = n
                        if colCh==0
                            noColorChannels = size(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).profile,1) - 1;
                            h{i} = plot(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).profile(1,:), ...
                                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).profile(2:end,:),'.-');
                                    if noColorChannels > 1
                                        for colId=1:noColorChannels
                                            set(h{i}(colId), 'color', lutColors(colId,:));
                                        end
                                    end
                        else
                            colId = min([colCh+1, size(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).profile,1)]);
                            h{i} = plot(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).profile(1,:), ...
                                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).profile(colId,:));
                            if numel(n) == 1
                                h{i}.Color = lutColors(colCh,:);
                            end
                        end
                    end
                    legend(num2str(n'));
                    grid;
                    ax.NextPlot = 'replace';
                    title('Intensity profiles');
                    xlabel('Point number');
                    ylabel('Intensity');
                case 'Kymograph'
                    answer = questdlg('Save kymograph(s) to a file or preview in MIB (use preview only for a single measurement selected)?','Kymograph export','Save to file','Preview','Cancel','Save to file');
                    if strcmp(answer, 'Cancel'); return; end
                    if strcmp(answer, 'Save to file')
                        % select output directory and the template filename
                        [path, templateFn] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
                        fn_out = fullfile(path, [templateFn '_measure_.tif']);
                        Filters = {'*.tif',   'TIF image (*.tif)'; ...
                                   '*.tif',   'TIF image with scale bar (*.tif)'; ...
                                   '*.mat',   'MATLAB format (*.mat)'; ...
                                   '*.csv',   'Comma-separated value (*.csv)'};
                        [chemOptions.fnTemplate, chemOptions.outputDir, FilterIndex] = uiputfile(Filters, 'Save kymograph, set template', fn_out);
                        if chemOptions.fnTemplate == 0; return; end
                        chemOptions.outputFormat = Filters{FilterIndex}(end-2:end); % 'tif, csv, mat'
                        chemOptions.fnTemplate = chemOptions.fnTemplate(1:end-4);   % trim away the extension
                        if FilterIndex == 2
                            chemOptions.addScale = true;   % add scale bar to the images
                        else
                            chemOptions.addScale = false;
                        end
                    else
                        chemOptions.outputFormat = 'preview';
                    end
    
                    wb = waitbar(0, sprintf('Generating kymographs\nPlease wait...'), 'Name', 'Kymograph');
                    % update measurement
                    colCh = obj.View.handles.imageColChPopup.Value - 1;
                    integrateCheck = obj.View.handles.integrateCheck.Value;
                    widthProfile = [];
                    if integrateCheck
                        widthProfile = str2double(obj.View.handles.noPointsEdit.String);
                    end
                    chemOptions.widthProfile = widthProfile;
                     
                    noOfMeasurements = size(obj.indices, 1);
                    for i=1:noOfMeasurements
                        n = obj.indices(i,1);
                        if ~strcmp(chemOptions.outputFormat, 'preview')
                            chemOptions.outputFilename = fullfile(chemOptions.outputDir, sprintf('%s%.3d.%s', chemOptions.fnTemplate, n, chemOptions.outputFormat));
                        end
                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.generateKymograph(obj.mibController, n, colCh, chemOptions);
                        waitbar(i/noOfMeasurements);
                    end
                    
                    eventdata.Indices = obj.indices;   % store current indices, because they will be removed in obj.updateTable;
                    obj.updateTable();
                    drawnow;
                    obj.measureTable_CellSelectionCallback(eventdata);
                    delete(wb);
                case 'Delete'
                    obj.mibModel.mibDoBackup('measurements', 0);
                    rowId = obj.indices(:,1);
                    n = [data{rowId, 1}];
                    
                    obj.mibModel.I{obj.mibModel.Id}.hMeasure.removeMeasurements(n);
                    obj.updateTable();
                    obj.mibController.plotImage();
            end
        end
        
        function deleteAllBtn_Callback(obj)
            % function deleteAllBtn_Callback(obj)
            % a callback from obj.View.handles.deleteAllBtn to delete all
            % measurements
            obj.mibModel.mibDoBackup('measurements', 0);
            obj.mibModel.I{obj.mibModel.Id}.hMeasure.removeMeasurements();
            obj.updateTable();
            obj.mibController.plotImage();
        end
        
        function updatePlotSettings(obj)
            % function updatePlotSettings(obj)
            % a callback for press of obj.View.handles.markersCheck,
            % obj.View.handles.linesCheck, obj.View.handles.textCheck checkboxes
            
            obj.mibModel.I{obj.mibModel.Id}.hMeasure.Options.showMarkers = obj.View.handles.markersCheck.Value;
            obj.mibModel.I{obj.mibModel.Id}.hMeasure.Options.showLines = obj.View.handles.linesCheck.Value;
            obj.mibModel.I{obj.mibModel.Id}.hMeasure.Options.showText = obj.View.handles.textCheck.Value;
            obj.mibController.plotImage();
        end
        
        function optionsBtn_Callback(obj)
            % function optionsBtn_Callback(obj)
            % a callback for press of obj.View.handles.optionsBtn to define
            % look and feel of markers for measurements
            
            obj.mibModel.I{obj.mibModel.Id}.hMeasure.setOptions();
            obj.mibController.plotImage();
        end
        
        function interpolationModePopup_Callback(obj)
            % function interpolationModePopup_Callback(obj)
            % a callback for obj.View.handles.interpolationModePopup to
            % define type of interpolation for polylines
            
            methodString = obj.View.handles.interpolationModePopup.String;
            methodString = methodString{obj.View.handles.interpolationModePopup.Value};
            obj.mibModel.I{obj.mibModel.Id}.hMeasure.Options.splinemethod = methodString;
        end
        
        function loadBtn_Callback(obj)
            % function loadBtn_Callback(obj)
            % a callback for press of obj.View.handles.loadBtn
            % load measurements from a file or import from Matlab
            global mibPath;
            
            prompts = {'Load import the measurements from:'};
            defAns = {{'Load from a file', 'Import from MATLAB', 'Combine from individual measure files', 1}};
            dlgTitle = 'Load / import measurements';
            options.WindowStyle = 'normal'; 
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end 

            switch answer{1}
                case 'Import from MATLAB'
                    % get list of available variables
                    availableVars = evalin('base', 'whos');
                    idx = ismember({availableVars.class}, {'struct'});
                    if sum(idx) == 0
                        errordlg(sprintf('!!! Error !!!\nNothing to import...'), 'Nothing to import');
                        return;
                    end
                    Vars = {availableVars(idx).name}';        

                    % find index of the I variable if it is present
                    idx2 = find(ismember(Vars, 'mibMeasurements')==1);
                    if ~isempty(idx2)
                        Vars{end+1} = idx2;
                    end
                    prompts = {'A variable that contains compatible structure:'};
                    defAns = {Vars};
                    title = 'Input variable for import';
                    answer = mibInputMultiDlg({mibPath}, prompts, defAns, title);
                    if isempty(answer); return; end
                    obj.mibModel.mibDoBackup('measurements', 0);
                    dataIn = evalin('base',answer{1});
                    obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data = dataIn;
                case 'Load from a file'
                    [filename, path] = mib_uigetfile(...
                        {'*.measure;',  'Matlab format (*.measure)'; ...
                        '*.*',  'All Files (*.*)'}, ...
                        'Load measurements...', obj.mibModel.myPath);
                    if isequal(filename, 0); return; end % check for cancel
                    filename = filename{1}; 

                    obj.mibModel.mibDoBackup('measurements', 0);
                    res = load(fullfile(path, filename),'-mat');
                    if ~isfield(res.Data, 'T')  % loading old measurements before 4D datasets
                        [res.Data.T] = deal(1);
                    end
%                     % add a field introduced in 2.83
%                     if ~isfield(res.Data, 'info')
%                         [res.Data.info] = deal('');
%                     end
                    obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data = res.Data;
                case 'Combine from individual measure files'
                    [filename, pathIn] = mib_uigetfile(...
                        {'*.measure;',  'Matlab format (*.measure)'; ...
                        '*.*',  'All Files (*.*)'}, ...
                        'Load measurements...', obj.mibModel.myPath, 'on');
                    if isequal(filename, 0); return; end

                    if ~isfield(obj.mibModel.sessionSettings.measureTool, 'combineFiles')
                        obj.mibModel.sessionSettings.measureTool.combineFiles.sliceNumbers = '';
                        obj.mibModel.sessionSettings.measureTool.combineFiles.prefix = 'prefix_';
                        obj.mibModel.sessionSettings.measureTool.combineFiles.suffix = '_suffix';
                        obj.mibModel.sessionSettings.measureTool.combineFiles.numNumericChar = '4';
                    end

                    prompts = {'List slice numbers that correspond to the filename indices; keep empty when number of files correspond to the number of slices'; ...
                        sprintf('\nExample on how to define filename template:\nPrefix: "prefix_"\nSuffix: "_suffix"\nNumber of numeric charactrers: "4"\nGenerated filename: "prefix_0001_suffix.measure"\n\nTemplate A:'); ...
                        'TemplateB:'; 'Number of numeric charactrers:'};

                    defAns = {obj.mibModel.sessionSettings.measureTool.combineFiles.sliceNumbers, obj.mibModel.sessionSettings.measureTool.combineFiles.prefix, obj.mibModel.sessionSettings.measureTool.combineFiles.suffix, obj.mibModel.sessionSettings.measureTool.combineFiles.numNumericChar};
                    dlgTitle = 'Load / import measurements';
                    options.PromptLines = [2, 8, 1, 1];
                    options.WindowStyle = 'normal'; 
                    answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer); return; end 
                    
                    obj.mibModel.sessionSettings.measureTool.combineFiles.sliceNumbers = answer{1};
                    obj.mibModel.sessionSettings.measureTool.combineFiles.prefix = answer{2};
                    obj.mibModel.sessionSettings.measureTool.combineFiles.suffix = answer{3};
                    obj.mibModel.sessionSettings.measureTool.combineFiles.numNumericChar = answer{4};

                    sliceIds = str2num(obj.mibModel.sessionSettings.measureTool.combineFiles.sliceNumbers); %#ok<ST2NM> 
                    if isempty(sliceIds)
                        sliceIds = 1:numel(filename);
                    end
                    
                    prefix = obj.mibModel.sessionSettings.measureTool.combineFiles.prefix; %#ok<NASGU> 
                    suffix = obj.mibModel.sessionSettings.measureTool.combineFiles.suffix; %#ok<NASGU> 
                    noNumbers = str2double(obj.mibModel.sessionSettings.measureTool.combineFiles.numNumericChar);

                    for zIndex = 1:numel(sliceIds)
                        z = sliceIds(zIndex);
                        
                        % generate filename to load
                        genStr = sprintf("fnFull = fullfile(pathIn, sprintf('%%s%%.%dd%%s.measure', prefix, z, suffix));", noNumbers);
                        eval(genStr);
                        
                        dummy = load(fnFull, '-mat');
                        for mId = 1:numel(dummy.Data)
                            dummy.Data(mId).Z = z;
                        end
                    
                        if zIndex == 1
                            Data = dummy.Data;
                        else
                            Data = [Data, dummy.Data];
                        end
                    end
                    obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data = Data;
            end

            % add a field introduced in 2.83
            if ~isfield(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data, 'info')
                [obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data.info] = deal('');
            end

            obj.updateTable();
            
            obj.mibController.mibView.handles.mibShowAnnotationsCheck.Value = 1;
            obj.mibModel.mibShowAnnotationsCheck = 1;
            obj.mibController.plotImage();
            fprintf('MIB: import measurements  -> done!\n')
        end
        
        function saveBtn_Callback(obj)
            % function saveBtn_Callback(obj)
            % a callback for press of obj.View.handles.saveBtn
            % save measurements to a file or export to Matlab
            global mibPath;
            
            if numel(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data) < 1; return; end
            
            button =  questdlg(sprintf('Would you like to save measurements to a file or export to the main Matlab workspace?'), ...
                'Export/Save measurements', 'Save to a file', 'Export to Matlab', 'Cancel', 'Save to a file');
            if strcmp(button, 'Cancel'); return; end
            
            if strcmp(button, 'Export to Matlab')
                title = 'Input variable to export';
                def = 'mibMeasurements';
                prompt = {'A variable for the measurements structure:'};
                answer = mibInputDlg({mibPath}, prompt,title,def);
                if size(answer) == 0; return; end
                
                assignin('base', answer{1}, obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data);
                fprintf('MIB: export measurements ("%s") to Matlab -> done!\n', answer{1});
                return;
            end
            
            [dirOut, fn_out, extOut] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            if isempty(dirOut)
                dirOut = obj.mibModel.myPath;
            end
            fn_out = [fn_out '_measure'];
            fn_out = fullfile(dirOut, fn_out);

            Filters = {'*.measure',  'Matlab format (*.measure)';...
                       '*.xls',   'Excel format (*.xls)'; };
            
            [filename, path, FilterIndex] = uiputfile(Filters, 'Save measurements...', fn_out); %...
            if isequal(filename,0); return; end  % check for cancel
            fn_out = fullfile(path, filename);
            
            Data = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data; %#ok<NASGU>
            if strcmp('Matlab format (*.measure)', Filters{FilterIndex,2})    % matlab format
                save(fn_out, 'Data', '-mat', '-v7.3');
                fprintf('MIB: saving measurements to %s -> done!\n', fn_out);
            elseif strcmp('Excel format (*.xls)', Filters{FilterIndex,2})    % excel format
                wb = waitbar(0,'Please wait...','Name','Generating Excel file...', 'WindowStyle', 'modal');
                warning('off', 'MATLAB:xlswrite:AddSheet');
                % Sheet 1
                s = {sprintf('Measurements for %s', obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));};
                
                s(3,1:11) = {'Filename', 'N', 'Type', 'Length', 'Info', 'intensity', 'Integration width', '[tcoords]', '[zcoords]', '[xcoords]', '[ycoords]'};
                roiId = 4;
                
                shift = 1;
                
                % generate slice names for export
                if isKey(obj.mibModel.I{obj.mibModel.Id}.meta, 'SliceName') 
                    if numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName')) == obj.mibModel.I{obj.mibModel.Id}.depth
                        sliceNames = obj.mibModel.I{obj.mibModel.Id}.meta('SliceName');
                    else
                        sliceNames = repmat(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'), [obj.mibModel.I{obj.mibModel.Id}.depth, 1]);
                    end
                else
                    [~, sliceNames, ext] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
                    sliceNames = repmat({[sliceNames, ext]}, [obj.mibModel.I{obj.mibModel.Id}.depth, 1]);
                end

                for i=1:numel(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data)
                    % get the coordinates
                    if strcmp(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).type,'Circle (R)')
                        X = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).circ.xc ;
                        Y = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).circ.yc ;
                    elseif strcmp(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).type,'Distance (polyline)')
                        X = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).spline.x ;
                        Y = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).spline.y ;
                    else
                        X = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).X;
                        Y = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).Y;
                    end
                    % format to a string
                    xstr = '[';
                    ystr = '[';
                    for kk = 1:length(X)
                        if kk == 1
                            xstr = [ xstr sprintf('%.2f',X(kk)) ] ;
                            ystr = [ ystr sprintf('%.2f',Y(kk)) ] ;
                        else
                            xstr = [ xstr ' ; ' sprintf('%.2f',X(kk)) ] ;
                            ystr = [ ystr ' ; ' sprintf('%.2f',Y(kk)) ] ;
                        end
                    end
                    xstr = [ xstr ']' ];
                    ystr = [ ystr ']' ];
                    
                    s(roiId+shift, 1) = sliceNames(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).Z);
                    s{roiId+shift, 2} = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).n;
                    s{roiId+shift, 3} = cell2mat(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).type);
                    s{roiId+shift, 4} = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).value;
                    s{roiId+shift, 5} = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).info;
                    for j=1:numel(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).intensity)
                        s{roiId+shift+j-1, 6} = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).intensity(j);
                    end
                    s{roiId+shift, 7} = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).integrateWidth;
                    
                    s{roiId+shift, 8} = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).T;
                    s{roiId+shift, 9} = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).Z;
                    s{roiId+shift, 10} = xstr;
                    s{roiId+shift, 11} = ystr;
                    
                    shift = shift + numel(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).intensity);
                end
                xlswrite2(fn_out, s, 'Sheet1', 'A1');
                
                waitbar(.5, wb);
                
                % Sheet 2
                s = {sprintf('Measurements for %s', obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));};
                s{2,1} = 'Intensity profiles'; 
                
                rowId = 5;
                shift = 1;
                for i=1:numel(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data)
                    s{4,shift+1} = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).n;
                    noColChannels = size(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).profile, 1)-1;
                    noElements = size(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).profile, 2);
                    if strcmp(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).type, 'Circle (R)')
                        noColChannels = 1;
                        noElements = 1;
                        s(rowId:rowId+noElements-1, shift+1:shift+noColChannels) = ...
                            cellstr('not implemented');
                    else
                        s(rowId:rowId+noElements-1, shift+1:shift+noColChannels) = ...
                            num2cell(obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(i).profile(2:end,:)');    
                    end
                    shift = shift + noColChannels;
                end
                xlswrite2(fn_out, s, 'Sheet2', 'A1');
                
                waitbar(1, wb);
                delete(wb);
            end
        end
        
        function updateVoxelsButton_Callback(obj)
            % function updateVoxelsButton_Callback(obj)
            % a callback for press of obj.View.handles.updateVoxelsButton
            % to update size of voxels for the dataset
            obj.mibModel.I{obj.mibModel.Id}.updatePixSizeResolution();
            obj.mibController.updateAxesLimits('resize');
            obj.mibController.plotImage(1);
            obj.updateWidgets();
        end
        
    end
end