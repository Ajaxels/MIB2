classdef mibLines3DController < handle
    % classdef mibLines3DController < handle
    % a controller class for the table views of lines 3d 
    
    % Copyright (C) 20.04.2018, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    
    % Updates
    % 
    
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        hAx = [];
        % axes for the 3D visualization figure
        hFig = [];
        % a handle to 3D visualization figure
        hPlot = [];
        % a handle to a plot on 3D visualization figure
        imarisOptions
        % a structure with export options for imaris
        % .radii - number with default radius
        % .color - default color [Red Green Blue Alpha] in range from 0 to 1;
        % .name - default name
        indicesEdges
        % indices of selected node in the in edgesViewTable 
        indicesNodes
        % indices of selected node in the in nodesViewTable 
        indicesTrees
        % indices of selected trees in the in treeViewTable 
        jScrollEdges
        % java handle to the scroll bar of obj.View.handles.edgesViewTable
        jScrollNodes
        % java handle to the scroll bar of obj.View.handles.nodesViewTable
        jScrollTrees
        % java handle to the scroll bar of obj.View.handles.treesViewTable
        jEdgesTable
        % java handle to the obj.View.handles.edgesViewTable
        jNodesTable
        % java handle to the obj.View.handles.nodesViewTable
        jTreeTable
        % java handle to the obj.View.handles.treesViewTable
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case 'updatedLines3D'
                    if obj.View.handles.autoRefreshCheck.Value == 0; return; end     % do not auto update the tables
                    switch evnt.Parameter
                        case 'Assign active node'
                            obj.updateWidgets();
                        case 'Delete node'
                            obj.updateWidgets();
                        case 'Modify active node'
                            obj.updateWidgets();
                        case 'New tree'
                            obj.updateWidgets();
                        case 'Split tree'
                            obj.updateWidgets();
                        case 'Add node'
                            obj.updateWidgets();
                        otherwise
                            obj.updateWidgets();
                    end
                case 'updateId'
                    obj.updateWidgets();
                case 'undoneBackup'
                    if strcmp(evnt.Parameter, 'lines3d')
                        obj.updateWidgets();
                    end
            end
        end
    end
    
    methods
        function obj = mibLines3DController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibLines3DGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            obj.imarisOptions.radii = NaN;
            obj.imarisOptions.color = [1 0 0 0];
            obj.imarisOptions.name = 'mibSpots';
            
            % find java object for the tree table
            obj.jScrollTrees = findjobj(obj.View.handles.treesViewTable);
            obj.jTreeTable = obj.jScrollTrees.getViewport.getComponent(0);
            obj.jTreeTable.setAutoResizeMode(obj.jTreeTable.AUTO_RESIZE_LAST_COLUMN);
            
            % find java object for the edges table
            obj.jScrollEdges = findjobj(obj.View.handles.edgesViewTable);
            obj.jEdgesTable = obj.jScrollEdges.getViewport.getComponent(0);
            obj.jEdgesTable.setAutoResizeMode(obj.jEdgesTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
            
            % find java object for the nodes table
            obj.jScrollNodes = findjobj(obj.View.handles.nodesViewTable);
            obj.jNodesTable = obj.jScrollNodes.getViewport.getComponent(0);
            obj.jNodesTable.setAutoResizeMode(obj.jNodesTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
            
            obj.indicesNodes = 0;
            obj.indicesTrees = 0;
            
            % add icons to buttons
            obj.View.handles.settingsBtn.CData = obj.mibModel.sessionSettings.guiImages.settings;
            
            obj.updateWidgets();
            
            obj.listener{1} = addlistener(obj.mibModel, 'updateId', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            obj.listener{2} = addlistener(obj.mibModel, 'updatedLines3D', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));   % listen for updated annotations
            obj.listener{3} = addlistener(obj.mibModel, 'undoneBackup', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));   % listen for updated annotations
        end
        
        function closeWindow(obj)
            % closing mibLines3DController window
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
            % update widgets and tables
            [noTrees, nodeByTree] = obj.mibModel.I{obj.mibModel.Id}.hLines3D.updateNumberOfTrees();
            if obj.mibModel.I{obj.mibModel.Id}.hLines3D.noTrees > 0
                w1 = obj.jTreeTable.getColumnModel.getColumn(0).getWidth;
                w2 = obj.jTreeTable.getColumnModel.getColumn(1).getWidth;
                N = histcounts(nodeByTree, 0.5:noTrees+.5);
                
                treeNames = obj.mibModel.I{obj.mibModel.Id}.hLines3D.getTreeNames();
                data1 = cell([noTrees, 2]);
                data1(:,1) = treeNames;
                data1(:,2) = num2cell(N');
                obj.View.handles.treesViewTable.Data = data1;
                obj.View.handles.treesViewTable.ColumnWidth = {w1, w2};     % resize the table
                
                activeTreeName = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.TreeName(obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId);
                if ~isempty(activeTreeName)
                    activeTreeIndex = find(ismember(treeNames, activeTreeName));

%                     %obj.jTreeTable.setValueAt(java.lang.Boolean(0), activeTreeIndex-1, 0);
%                     %obj.jTreeTable.setValueAt(java.lang.Boolean(1), activeTreeIndex-1, 2);
%                     pause(0.001);
%                     try
%                         obj.jTreeTable.changeSelection(activeTreeIndex-1, 0, false, false);
%                     catch err
%                     
%                     end
                    
                    % false, false: Clear the previous selection and ensure the new cell is selected. 
                    % false, true: Extend the previous selection (select a range of cells).
                    % true, false: Toggle selection
                    % true, true: Apply the selection state of the anchor to all cells between it and the specified cell.
                    
                    curTable = obj.View.handles.tableSelectionPopup.String{obj.View.handles.tableSelectionPopup.Value};
                    switch curTable
                        case 'Nodes'
                            obj.updateNodesViewTable(activeTreeIndex, nodeByTree);
                        case 'Edges'
                            obj.updateEdgesViewTable(activeTreeIndex, nodeByTree);
                    end
                    
                    % update text indicators
                    obj.View.handles.activeTreeText.String = sprintf('Active tree: %d', activeTreeIndex);
                    obj.View.handles.activeNodeText.String = sprintf('Active node: %d', obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId);
                end
            else
                obj.View.handles.treesViewTable.Data = {};
                obj.View.handles.nodesViewTable.Data = {};
                obj.View.handles.edgesViewTable.Data = {};
                obj.View.handles.activeTreeText.String = sprintf('Active tree: None');
                obj.View.handles.activeNodeText.String = sprintf('Active node: None');
            end
        end
        
        function updateEdgesViewTable(obj, activeTreeIndex, nodeByTree)
            % function updateEdgesViewTable(obj, activeTreeIndex, nodeByTree)
            % update edge table
            %
            % Parameters:
            % activeTreeIndex: index of active tree
            % nodeByTree: [@em optional], vector of indices, nodes belonging to the tree
            %
            % Return values:
            % 
            
            if nargin < 3; [~, nodeByTree] = obj.mibModel.I{obj.mibModel.Id}.hLines3D.updateNumberOfTrees(); end
            if nargin < 2; activeTreeIndex = obj.indicesTrees; end
            
            % store width of columns
            w1 = obj.jEdgesTable.getColumnModel.getColumn(0).getWidth;
            w2 = obj.jEdgesTable.getColumnModel.getColumn(1).getWidth;
            w3 = obj.jEdgesTable.getColumnModel.getColumn(2).getWidth;
            w4 = obj.jEdgesTable.getColumnModel.getColumn(3).getWidth;
            
            extraFields = [{'Weight'}; obj.mibModel.I{obj.mibModel.Id}.hLines3D.extraEdgeFields];            
            extraFieldsValue = obj.View.handles.edgesViewAdditionalField.Value;
            extraFieldsValue = min([extraFieldsValue, numel(extraFields)]);
            obj.View.handles.edgesViewAdditionalField.Value = extraFieldsValue;
            obj.View.handles.edgesViewAdditionalField.String = extraFields;
            extraParameter = extraFields{extraFieldsValue};
            
            NodesId = find(nodeByTree==activeTreeIndex);
            EdgeIds = find(ismember(obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Edges.EndNodes(:,1), NodesId));
            
            data2 = cell([numel(EdgeIds), 4]);
            if ~isempty(EdgeIds)
                data2(:,1) = num2cell(obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Edges.EndNodes(EdgeIds,1));
                data2(:,2) = num2cell(obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Edges.EndNodes(EdgeIds,2));
                if isnumeric(obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Edges.(extraParameter)(EdgeIds(1)))
                    obj.View.handles.edgesViewTable.ColumnFormat{3} = 'numeric';
                    data2(:,3) = num2cell(obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Edges.(extraParameter)(EdgeIds));
                else
                    obj.View.handles.edgesViewTable.ColumnFormat{3} = 'char';
                    data2(:,3) = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Edges.(extraParameter)(EdgeIds);
                end
                data2(:,4) = num2cell(obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Edges.Length(EdgeIds));
            end
            obj.View.handles.edgesViewTable.Data = data2;
            obj.View.handles.edgesViewTable.RowName = EdgeIds;
            obj.View.handles.edgesViewTable.ColumnName{3} = extraParameter;
            obj.View.handles.edgesViewTable.ColumnWidth = {w1, w2, w3, w4};     % resize the table
        end
        
        function activeIndex = updateNodesViewTable(obj, activeTreeIndex, nodeByTree)
            % function activeIndex = updateNodesViewTable(obj, activeTreeIndex, nodeByTree)
            % update nodes table
            %
            % Parameters:
            % activeTreeIndex: index of active tree
            % nodeByTree: [@em optional], vector of indices, nodes belonging to the tree
            %
            % Return values:
            % activeIndex: index of tha active node
            if nargin < 3; [~, nodeByTree] = obj.mibModel.I{obj.mibModel.Id}.hLines3D.updateNumberOfTrees(); end
            if nargin < 2; activeTreeIndex = obj.indicesTrees; end
            
            w1 = obj.jNodesTable.getColumnModel.getColumn(0).getWidth;
            w2 = obj.jNodesTable.getColumnModel.getColumn(1).getWidth;
            w3 = obj.jNodesTable.getColumnModel.getColumn(2).getWidth;
            w4 = obj.jNodesTable.getColumnModel.getColumn(3).getWidth;
            w5 = obj.jNodesTable.getColumnModel.getColumn(4).getWidth;
            
            extraFields = [{'Radius'}; obj.mibModel.I{obj.mibModel.Id}.hLines3D.extraNodeFields];            
            extraFieldsValue = obj.View.handles.nodesViewAdditionalField.Value;
            extraFieldsValue = min([extraFieldsValue, numel(extraFields)]);
            obj.View.handles.nodesViewAdditionalField.Value = extraFieldsValue;
            obj.View.handles.nodesViewAdditionalField.String = extraFields;
            extraParameter = extraFields{extraFieldsValue};
            
            NodesId = find(nodeByTree==activeTreeIndex);
            data2 = cell([numel(NodesId), 5]);
            data2(:,1) = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.NodeName(NodesId);
            if isnumeric(obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.(extraParameter)(NodesId(1)))
                obj.View.handles.nodesViewTable.ColumnFormat{2} = 'numeric';
                data2(:,2) = num2cell(obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.(extraParameter)(NodesId));
            else
                obj.View.handles.nodesViewTable.ColumnFormat{2} = 'char';
                data2(:,2) = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.(extraParameter)(NodesId);
            end
            data2(:,3) = num2cell(obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.PointsXYZ(NodesId,3));
            data2(:,4) = num2cell(obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.PointsXYZ(NodesId,1));
            data2(:,5) = num2cell(obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.PointsXYZ(NodesId,2));
            obj.View.handles.nodesViewTable.Data = data2;
            obj.View.handles.nodesViewTable.RowName = num2str(NodesId');
            obj.View.handles.nodesViewTable.ColumnName{2} = extraParameter;
            obj.View.handles.nodesViewTable.ColumnWidth = {w1, w2, w3, w4, w5};     % resize the table
            activeIndex = find(NodesId == obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId);   % index of the active node in the table
            %pause(0.01);
            if ~isempty(activeIndex)
                pause(0.01);
                obj.jNodesTable.changeSelection(activeIndex-1, 0, false, false);
            end
            %obj.jScrollNodes.getVerticalScrollBar.setValue(scroll);
        end
        
        function edgesViewTable_CellEditCallback(obj, eventdata)
            % function edgesViewTable_CellEditCallback(obj, eventdata)
            % callback for modification of cell in edgeViewTable
            %
            % Paramters:
            % eventdata: a structure with fields
            %	.Indices - row and column indices of the cell(s) edited
            %	.PreviousData - previous data for the cell(s) edited
            %	.EditData - string(s) entered by the user
            %	.NewData - EditData or its converted form set on the Data property. Empty if Data was not changed
            %	.Error - error string when failed to convert EditData to appropriate value for Data
            
            colId = eventdata.Indices(1,2);     % col index of the modified cell
            rowId = eventdata.Indices(1,1);     % row index of the modified cell
            edgeId = str2double(obj.View.handles.edgesViewTable.RowName(rowId,:));
            fieldName = obj.View.handles.edgesViewTable.ColumnName(colId);
            if isnumeric(eventdata.NewData)
                obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Edges.(fieldName{1})(edgeId) = eventdata.NewData;
            else
                obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Edges.(fieldName{1}){edgeId} = eventdata.NewData;
            end
        end
        
        function nodesViewTable_CellEditCallback(obj, eventdata)
            % function nodesViewTable_CellEditCallback(obj, eventdata)
            % callback for modification of cell in nodesViewTable
            %
            % Paramters:
            % eventdata: a structure with fields
            %	.Indices - row and column indices of the cell(s) edited
            %	.PreviousData - previous data for the cell(s) edited
            %	.EditData - string(s) entered by the user
            %	.NewData - EditData or its converted form set on the Data property. Empty if Data was not changed
            %	.Error - error string when failed to convert EditData to appropriate value for Data
        
            colId = eventdata.Indices(1,2);     % col index of the modified cell
            rowId = eventdata.Indices(1,1);     % row index of the modified cell
            nodeIndex = str2double(obj.View.handles.nodesViewTable.RowName(rowId,:));
            fieldName = obj.View.handles.nodesViewTable.ColumnName(colId);
            if colId < 3
                if isnumeric(eventdata.NewData)
                    obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.(fieldName{1})(nodeIndex) = eventdata.NewData;
                else
                    obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.(fieldName{1}){nodeIndex} = eventdata.NewData;
                end
            else    % modification of xyz coordinate
                xyzIndex = find(ismember({'x', 'y', 'z'}, fieldName));
                newCoordinates = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.PointsXYZ(nodeIndex, :);
                newCoordinates(xyzIndex) = eventdata.NewData; %#ok<FNDSB>
                obj.mibModel.I{obj.mibModel.Id}.hLines3D.updateNodeCoordinate(nodeIndex, newCoordinates(1), newCoordinates(2), newCoordinates(3));
                notify(obj.mibModel, 'plotImage');
            end
        end
        
        function settingsBtn_Callback(obj)
            % function settingsBtn_Callback(obj)
            % update settings for Lines3D
            
            settings = obj.mibModel.I{obj.mibModel.Id}.hLines3D.getOptions();
            
            global mibPath;
            prompts = {sprintf('Color for edges:'); sprintf('Color for the active tree:'); 'Color for nodes:'; 'Color for active node:'; 'Edge thickness (1-...):'; 'Node radius (1-...):'; 'Extra clipping (0-...):'};
            defAns = {sprintf('%.3f, %.3f, %.3f', settings.edgeColor(1), settings.edgeColor(2), settings.edgeColor(3)); ...
                sprintf('%.3f, %.3f, %.3f', settings.edgeActiveColor(1), settings.edgeActiveColor(2), settings.edgeActiveColor(3)); ...
                sprintf('%.3f, %.3f, %.3f', settings.nodeColor(1), settings.nodeColor(2), settings.nodeColor(3)); ...
                sprintf('%.3f, %.3f, %.3f', settings.nodeActiveColor(1), settings.nodeActiveColor(2), settings.nodeActiveColor(3)); ...
                sprintf('%d', settings.edgeThickness); ...
                sprintf('%d', settings.nodeRadius); ...
                sprintf('%d', settings.clipExtraThickness); ...
                };
            dlgTitle = 'Lines3D Settings';
            options.WindowStyle = 'normal';       % [optional] style of the window
            options.PromptLines = [1, 1, 1, 1, 1, 1, 1];   % [optional] number of lines for widget titles
            options.Title = 'For colors use [Red, Green, Blue] format with range between 0-1';
            options.TitleLines = 2;
            options.Columns = 2;    % [optional] make window x1.2 times wider
            options.WindowWidth = 1.2;    % [optional] make window x1.2 times wider
            options.Focus = 1;      % [optional] define index of the widget to get focus
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end
            
            errorText = '';
            settings2.edgeColor = str2num(answer{1}); %#ok<ST2NM>
            if isempty(isnan(settings2.edgeColor)) || isempty(settings2.edgeColor); errorText = [errorText '\nWrong edge color']; end
            settings2.edgeActiveColor = str2num(answer{2}); %#ok<ST2NM>
            if isempty(isnan(settings2.edgeActiveColor)) || isempty(settings2.edgeActiveColor); errorText = [errorText '\nWrong active tree color']; end
            settings2.nodeColor = str2num(answer{3}); %#ok<ST2NM>
            if isempty(isnan(settings2.nodeColor)) || isempty(settings2.nodeColor); errorText = [errorText '\nWrong node color']; end
            settings2.nodeActiveColor = str2num(answer{4}); %#ok<ST2NM>
            if isempty(isnan(settings2.nodeActiveColor)) || isempty(settings2.nodeActiveColor); errorText = [errorText '\nWrong active node color']; end
            settings2.edgeThickness = round(str2double(answer{5}));
            if isnan(settings2.edgeThickness) || settings2.edgeThickness < 1; errorText = [errorText '\nWrong edge thickness, should be above 1']; end
            settings2.nodeRadius = round(str2double(answer{6}));
            if isnan(settings2.nodeRadius) || settings2.nodeRadius < 1; errorText = [errorText '\nWrong node radius, should be above 1']; end
            settings2.clipExtraThickness = round(str2double(answer{7}));
            if isnan(settings2.clipExtraThickness) || settings2.nodeRadius < 0; errorText = [errorText '\nWrong clipping value, should be above 0']; end
            if ~isempty(errorText)
                msgbox(sprintf(errorText), 'Error', 'error');
                return;
            end
            obj.mibModel.I{obj.mibModel.Id}.hLines3D.setOptions(settings2);
            notify(obj.mibModel, 'plotImage');
        end
        
        function loadBtn_Callback(obj)
            % function loadBtn_Callback(obj)
            % load annotation from a file or import from Matlab
            button =  questdlg(sprintf('Would you like to import 3D lines from a file or from the main Matlab workspace?'),'Import/Load 3D lines','Load from a file','Import from Matlab','Cancel','Load from a file');
            switch button
                case 'Cancel'
                    return;
                case 'Import from Matlab'
                    % get list of available variables
                    availableVars = evalin('base', 'whos');
                    % find only the cell type, because labelsList is array of cells
                    idx = ismember({availableVars.class}, {'struct', 'graph'});
                    
                    labelsList = {availableVars(idx).name}';
                    idx = find(ismember(labelsList, 'Lines3D')==1);
                    if ~isempty(idx)
                        labelsList{end+1} = idx;
                    end
                    
                    title = 'Input 3D lines';
                    defAns = {labelsList};
                    prompts = {'Name for structure or graph object with 3D lines:'};
                    answer = mibInputMultiDlg([], prompts, defAns, title);
                    if isempty(answer); return; end
                    
                    Graph = evalin('base', answer{1});
                    obj.mibModel.mibDoBackup('lines3d');
                    
                    obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId = [];
                    if isa(Graph, 'graph')
                        Lines3D = struct();
                        Lines3D.G = Graph;
                    else
                        Lines3D = Graph;
                        if ~isfield(Lines3D, 'G')
                            msgbox(sprintf('!!! Error !!!\n\nThe imported structure %s should contain field G with a graph', answer{1}), 'Wrong format', 'error', 'modal');
                            return;
                        end
                    end
                case 'Load from a file'
                    [filename, path] = uigetfile(...
                        {'*.lines3d;',  'Matlab format (*.lines3d)'; ...
                        '*.*',  'All Files (*.*)'}, ...
                        'Load 3D lines...', obj.mibModel.myPath);
                    if isequal(filename, 0); return; end % check for cancel
                    
                    obj.mibModel.mibDoBackup('lines3d');
                    
                    res = load(fullfile(path, filename), '-mat');
                    fieldsNames = fieldnames(res);
                    Lines3D = res.(fieldsNames{1});
                    obj.mibModel.I{obj.mibModel.Id}.hLines3D.filename = fullfile(path, filename);
            end
            
            pixSize = obj.mibModel.getImageProperty('pixSize');
            
            recalculateFromPixels = 0;   % switch to recalculate or not coordinates from pixels to physical units
            % add variable units if they are missing
            if isempty(Lines3D.G.Nodes.Properties.VariableUnits)
                for varNameId = 1:numel(Lines3D.G.Nodes.Properties.VariableNames)
                    switch Lines3D.G.Nodes.Properties.VariableNames{varNameId}
                        case {'PointsXYZ', 'Radius'}
                            Lines3D.G.Nodes.Properties.VariableUnits{varNameId} = pixSize.units;
                        case {'TreeName', 'NodeName'}
                            Lines3D.G.Nodes.Properties.VariableUnits{varNameId} = 'string';
                        otherwise
                            Lines3D.G.Nodes.Properties.VariableUnits{varNameId} = '';
                    end
                end
            else
                pointsXYZindex = find(ismember(Lines3D.G.Nodes.Properties.VariableNames, 'PointsXYZ'));
                if strcmp(Lines3D.G.Nodes.Properties.VariableUnits{pointsXYZindex}, 'pixel') %#ok<FNDSB>
                    button = questdlg(sprintf('Would you like to recalculate points from pixels to the current units?\nNote: all other fields will stay as they are!'),...
                       'Recalculate coordinates', ...
                       'Recalculate', 'Keep as they are', 'Recalculate');
                    if strcmp(button, 'Recalculate'); recalculateFromPixels = 1; end
                end
            end
            
            % recalculate points from pixels to physical units
            if recalculateFromPixels
                [Lines3D.G.Nodes.PointsXYZ(:,1), Lines3D.G.Nodes.PointsXYZ(:,2), Lines3D.G.Nodes.PointsXYZ(:,3)] = ...
                    obj.mibModel.I{obj.mibModel.Id}.convertPixelsToUnits(Lines3D.G.Nodes.PointsXYZ(:,1), Lines3D.G.Nodes.PointsXYZ(:,2), Lines3D.G.Nodes.PointsXYZ(:,3)); 
                
                Lines3D.G.Nodes.Properties.VariableUnits{pointsXYZindex} = pixSize.units;
                if ismember('Edges', Lines3D.G.Edges.Properties.VariableNames)
                    Lines3D.G.Edges.Edges = [];   % remove edges, they will be recalculated in the Lines3D.replaceGraph function
                end
            end
            
%             % add pixSize structure
%             if ~isfield(Lines3D.G.Nodes.Properties.UserData, 'pixSize')
%                 pixSize = obj.mibModel.getImageProperty('pixSize');
%                 Lines3D.G.Nodes.Properties.UserData.pixSize = pixSize;
%             end
%             if ~isfield(Lines3D.G.Nodes.Properties.UserData, 'BoundingBox')
%                 Lines3D.G.Nodes.Properties.UserData.BoundingBox = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
%             end
            
            % update pixSize and Bounding box
            Lines3D.G.Nodes.Properties.UserData.pixSize = obj.mibModel.getImageProperty('pixSize');
            Lines3D.G.Nodes.Properties.UserData.BoundingBox = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
            
            obj.mibModel.I{obj.mibModel.Id}.hLines3D.replaceGraph(Lines3D.G);
            
            if isfield(Lines3D, 'Settings')
                obj.mibModel.I{obj.mibModel.Id}.hLines3D.setOptions(Lines3D.Settings);
            end
            if isfield(Lines3D, 'activeNodeId')
                obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId = Lines3D.activeNodeId;
            end
            
            obj.updateWidgets();
            
            % alternative way to call plot image, via notify listener
            eventdata = ToggleEventData(0);
            notify(obj.mibModel, 'plotImage', eventdata);
            disp('Import lines3D: done!')
        end
        
        function saveBtn_Callback(obj, treeIds)
            % function saveBtn_Callback(obj)
            % save annotations to a file or export to Matlab
            global mibPath;
            
            if nargin < 2; treeIds = []; end
            
            noTrees = obj.mibModel.I{obj.mibModel.Id}.hLines3D.noTrees;
            if noTrees < 1; return; end
            
            button =  questdlg(sprintf('Would you like to save 3D lines to a file or export to the main Matlab workspace?'),'Export/Save 3D lines','Save to a file','Export to Matlab','Cancel','Save to a file');
            if strcmp(button, 'Cancel'); return; end
            if strcmp(button, 'Export to Matlab')
                answer=mibInputDlg({mibPath}, sprintf('Please enter name for the structures with the Graph:'), ...
                    'Export to Matlab', 'Lines3D');
                if isempty(answer); return; end
                
                if isempty(treeIds)
                    Lines3D.G = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G;
                    Lines3D.activeNodeId = obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId;
                else
                    Lines3D.G = obj.mibModel.I{obj.mibModel.Id}.hLines3D.getTree(treeIds);
                    Lines3D.activeNodeId = size(Lines3D.G.Nodes, 1);
                end
                Lines3D.Settings = obj.mibModel.I{obj.mibModel.Id}.hLines3D.getOptions();
                
                assignin('base', answer{1}, Lines3D);
                fprintf('Export Lines3d: structure ''%s'' with fields .G and.Settings was exported to Matlab!\n', answer{1});
            else
                %obj.saveLines3DToFile(Lines3D);
                if isempty(obj.mibModel.I{obj.mibModel.Id}.hLines3D.filename)
                    fn_out = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
                    [path, fn_out, ext] = fileparts(fn_out);
                    if isempty(path); path = obj.mibModel.myPath; end
                    if isempty(fn_out)
                        fn_out = obj.mibModel.myPath;
                    else
                        fn_out = sprintf('Lines_%s', fn_out);
                        fn_out = fullfile(path, fn_out);
                    end
                else
                    fn_out = obj.mibModel.I{obj.mibModel.Id}.hLines3D.filename;
                end
                
                Filters = {'*.lines3d;',  'Matlab format (*.lines3d)';...
                    '*.am',   'Amira Spatial Graph ASCII (*.am)';...
                    '*.am',   'Amira Spatial Graph BINARY (*.am)';...
                    '*.xls',   'Excel format (*.xls)'; };
                
                [filename, path, FilterIndex] = uiputfile(Filters, 'Save Lines3D...', fn_out); %...
                if isequal(filename,0); return; end % check for cancel
                
                fn_out = fullfile(path, filename);
                
                switch Filters{FilterIndex, 2}
                    case 'Matlab format (*.lines3d)'
                        saveOptions.format = 'lines3d';
                    case {'Amira Spatial Graph ASCII (*.am)', 'Amira Spatial Graph BINARY (*.am)'}
                        if strcmp(Filters{FilterIndex, 2}, 'Amira Spatial Graph ASCII (*.am)')
                            saveOptions.format = 'amira-ascii';
                        else
                            saveOptions.format = 'amira-binary';
                        end
                        
                        extraNodeFields = obj.mibModel.I{obj.mibModel.Id}.hLines3D.extraNodeFields;
                        if ~isempty(extraNodeFields)
                            extraNodeFieldsNumeric = obj.mibModel.I{obj.mibModel.Id}.hLines3D.extraNodeFieldsNumeric;
                            extraNodeFields = extraNodeFields(extraNodeFieldsNumeric>0);
                        end
                        extraEdgeFields = obj.mibModel.I{obj.mibModel.Id}.hLines3D.extraEdgeFields;
                        if ~isempty(extraEdgeFields)
                            extraEdgeFieldsNumeric = obj.mibModel.I{obj.mibModel.Id}.hLines3D.extraEdgeFieldsNumeric;
                            extraEdgeFields = extraEdgeFields(extraEdgeFieldsNumeric>0);
                        end
                        
                        if ~isempty(extraEdgeFields) || ~isempty(extraNodeFields)
                            % add default fields
                            extraEdgeFields = [{'Length'; 'Weight'}; extraEdgeFields];
                            extraNodeFields = [{'Radius'}; extraNodeFields];
                            
                            selectedNode = obj.View.handles.nodesViewAdditionalField.String(obj.View.handles.nodesViewAdditionalField.Value);
                            if numel(extraNodeFields) < 2
                                prompts = {'Field for nodes:'; 'Field for edges:'};
                                defAns = {[extraNodeFields; find(ismember(extraNodeFields, selectedNode))]; extraEdgeFields};
                            else
                                nodeId2 = find(~ismember(extraNodeFields, selectedNode));
                                prompts = {'First field for nodes:'; 'Second field for nodes:'; 'Field for edges:'};
                                defAns = {[extraNodeFields; find(ismember(extraNodeFields, selectedNode))]; ...
                                    [extraNodeFields; nodeId2(1)]; ...
                                    extraEdgeFields};
                            end
                            
                            dlgTitle = 'Export to Amira';
                            options.WindowStyle = 'normal';       % [optional] style of the window
                            %options.PromptLines = [1, 1];   % [optional] number of lines for widget titles
                            options.Title = sprintf('Select fields to export\n(only numerical fields can be exported)');
                            options.TitleLines = 2;
                            options.Focus = 1;      % [optional] define index of the widget to get focus
                            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                            if isempty(answer); return; end
                            if numel(extraNodeFields) < 2
                                outputFieldNode = extraNodeFields(selIndex(1));
                                outputFieldEdge = extraEdgeFields(selIndex(2));
                            else
                                outputFieldNode = [extraNodeFields(selIndex(1)); extraNodeFields(selIndex(2))];
                                outputFieldEdge = extraEdgeFields(selIndex(3));
                            end
                        else
                            outputFieldNode = {'Radius'};
                            outputFieldEdge = {'Weight'};
                        end
                        saveOptions.NodeFieldName = outputFieldNode;
                        saveOptions.EdgeFieldName = outputFieldEdge;
                    case 'Excel format (*.xls)'
                        saveOptions.format = 'excel';
                end
                saveOptions.treeId = treeIds;
                obj.mibModel.I{obj.mibModel.Id}.hLines3D.saveToFile(fn_out, saveOptions);
                fprintf('Saving Lines3D to %s: done!\n', fn_out);
            end
        end
        
%         function saveLines3DToFile(obj, Lines3D)
%             % function saveAnnotationsToFile(obj, Lines3D)
%             % save Lines3D structure to a file
%             %
%             % Parameters:
%             % Lines3D: a structure with fields
%             %  .G graph object, that includes 'Edges' and 'Nodes' fields
%             %  .Settings a structure with settings 
%             global mibPath;
%             
%             if isempty(obj.mibModel.I{obj.mibModel.Id}.hLines3D.filename)
%                 fn_out = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
%                 [path, fn_out, ext] = fileparts(fn_out);
%                 if isempty(path); path = obj.mibModel.myPath; end
%                 if isempty(fn_out)
%                     fn_out = obj.mibModel.myPath;
%                 else
%                     fn_out = sprintf('Lines_%s', fn_out);
%                     fn_out = fullfile(path, fn_out);
%                 end
%             else
%                 fn_out = obj.mibModel.I{obj.mibModel.Id}.hLines3D.filename;
%             end
%             
%             Filters = {'*.lines3d;',  'Matlab format (*.lines3d)';...
%                 '*.am',   'Amira Spatial Graph ASCII (*.am)';...
%                 '*.am',   'Amira Spatial Graph BINARY (*.am)';...
%                 '*.xls',   'Excel format (*.xls)'; };
%             
%             [filename, path, FilterIndex] = uiputfile(Filters, 'Save Lines3D...', fn_out); %...
%             if isequal(filename,0); return; end % check for cancel
%             
%             fn_out = fullfile(path, filename);
%             
%             switch Filters{FilterIndex, 2}
%                 case 'Matlab format (*.lines3d)'
%                     saveOptions.format = 'lines3d';
%                 case {'Amira Spatial Graph ASCII (*.am)', 'Amira Spatial Graph BINARY (*.am)'}
%                     if strcmp(Filters{FilterIndex, 2}, 'Amira Spatial Graph ASCII (*.am)')
%                         saveOptions.format = 'amira-ascii';
%                     else
%                         saveOptions.format = 'amira-binary';
%                     end
%                     
%                     extraNodeFields = obj.mibModel.I{obj.mibModel.Id}.hLines3D.extraNodeFields;
%                     if ~isempty(extraNodeFields)
%                         extraNodeFieldsNumeric = obj.mibModel.I{obj.mibModel.Id}.hLines3D.extraNodeFieldsNumeric;
%                         extraNodeFields = extraNodeFields(extraNodeFieldsNumeric>0);
%                     end
%                     extraEdgeFields = obj.mibModel.I{obj.mibModel.Id}.hLines3D.extraEdgeFields;
%                     if ~isempty(extraEdgeFields)
%                         extraEdgeFieldsNumeric = obj.mibModel.I{obj.mibModel.Id}.hLines3D.extraEdgeFieldsNumeric;
%                         extraEdgeFields = extraEdgeFields(extraEdgeFieldsNumeric>0);
%                     end
%                     
%                     if ~isempty(extraEdgeFields) || ~isempty(extraNodeFields)
%                         % add default fields
%                         extraEdgeFields = [{'Length'; 'Weight'}; extraEdgeFields];
%                         extraNodeFields = [{'Radius'}; extraNodeFields];
%                         
%                         selectedNode = obj.View.handles.nodesViewAdditionalField.String(obj.View.handles.nodesViewAdditionalField.Value);
%                         if numel(extraNodeFields) < 2
%                             prompts = {'Field for nodes:'; 'Field for edges:'};
%                             defAns = {[extraNodeFields; find(ismember(extraNodeFields, selectedNode))]; extraEdgeFields};
%                         else
%                             nodeId2 = find(~ismember(extraNodeFields, selectedNode));
%                             prompts = {'First field for nodes:'; 'Second field for nodes:'; 'Field for edges:'};
%                             defAns = {[extraNodeFields; find(ismember(extraNodeFields, selectedNode))]; ...
%                                 [extraNodeFields; nodeId2(1)]; ...
%                                 extraEdgeFields};
%                         end
%                         
%                         dlgTitle = 'Export to Amira';
%                         options.WindowStyle = 'normal';       % [optional] style of the window
%                         %options.PromptLines = [1, 1];   % [optional] number of lines for widget titles
%                         options.Title = sprintf('Select fields to export\n(only numerical fields can be exported)');
%                         options.TitleLines = 2;
%                         options.Focus = 1;      % [optional] define index of the widget to get focus
%                         [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
%                         if isempty(answer); return; end
%                         if numel(extraNodeFields) < 2
%                             outputFieldNode = extraNodeFields(selIndex(1));
%                             outputFieldEdge = extraEdgeFields(selIndex(2));
%                         else
%                             outputFieldNode = [extraNodeFields(selIndex(1)); extraNodeFields(selIndex(2))];
%                             outputFieldEdge = extraEdgeFields(selIndex(3));
%                         end
%                     else
%                         outputFieldNode = {'Radius'};
%                         outputFieldEdge = {'Weight'};
%                     end
%                     saveOptions.NodeFieldName = outputFieldNode;
%                     saveOptions.EdgeFieldName = outputFieldEdge;
%                 case 'Excel format (*.xls)'
%                     saveOptions.format = 'excel';
%             end
%             
%             obj.mibModel.I{obj.mibModel.Id}.hLines3D.saveToFile(fn_out, saveOptions);
%             fprintf('Saving Lines3D to %s: done!\n', fn_out);
%             return;
%             
%             if strcmp('Matlab format (*.lines3d)', Filters{FilterIndex, 2})    % matlab format
%                 save(fn_out, 'Lines3D', '-mat', '-v7.3');
%                 obj.mibModel.I{obj.mibModel.Id}.hLines3D.filename = fn_out;
%             elseif strcmp('Excel format (*.xls)', Filters{FilterIndex, 2})    % excel format
%                 wb = waitbar(0,'Please wait...','Name','Generating Excel file...','WindowStyle','modal');
%                 warning off MATLAB:xlswrite:AddSheet
%                 
%                 % Sheet 1
%                 s = {sprintf('Lines3D for %s', obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));};
%                 s(2,1) = {sprintf('Lines3D filename: %s', obj.mibModel.I{obj.mibModel.Id}.hLines3D.filename)};
%                 s(4,1) = {'NODES'};
%                 
%                 Variables = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.Properties.VariableNames;
%                 s(6,2) = {'NodeId'}; s(6,3) = {'TreeName'}; s(6,4) = {'NodeName'}; s(6,5) = {'X'}; s(6,6) = {'Y'}; s(6,7) = {'Z'};
%                 Variables(ismember(Variables, {'PointsXYZ', 'TreeName', 'NodeName'})) = [];
%                 s(6,8:8+numel(Variables)-1) = Variables;                
%                 %Units = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.Properties.VariableUnits;
%                 %if ~isempty(Units)
%                 %    s(7,2:2+numel(Variables)-1) = Units;
%                 %end
%                 
%                 % sheet 2
%                 s2 = {sprintf('Lines3D for %s', obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));};
%                 s2(2,1) = {sprintf('Lines3D filename: %s', obj.mibModel.I{obj.mibModel.Id}.hLines3D.filename)};
%                 s2(4,1) = {'EDGES'};
%                 
%                 Variables = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Edges.Properties.VariableNames;
%                 s2(6,2) = {'EndNode1'}; s2(6,3) = {'EndNode2'}; s2(6,4) = {'EndNode1Name'}; s2(6,5) = {'EndNode2Name'};
%                 s2(6,6) = {'Weight'}; s2(6,7) = {'Length'};
%                 Variables(ismember(Variables, {'EndNodes', 'Weight', 'Length', 'Edges'})) = [];
%                 s2(6,8:8+numel(Variables)-1) = Variables;
% %                 Units = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Edges.Properties.VariableUnits;
% %                 if ~isempty(Units)
% %                     s2(7,2:2+numel(Variables)-1) = Units;
% %                 end
%                 
%                 dy1 = 8;
%                 dy2 = 8;
%                 waitbar(.1, wb);
%                 
%                 nodesCount = 0;
%                 for treeId = 1:obj.mibModel.I{obj.mibModel.Id}.hLines3D.noTrees
%                     [curTree, nodeIds, EdgesTable, NodesTable] = obj.mibModel.I{obj.mibModel.Id}.hLines3D.getTree(treeId);
%                     
%                     %TreeName = curTree.Nodes.TreeName(1,:);
%                     TreeName = NodesTable.TreeName(1,:);
%                     NodeNames = NodesTable.NodeName;    % store node names for generation of edges
%                     s(dy1, 1) = TreeName;
%                     [noRows, ~] = size(NodesTable);
%                     s(dy1:dy1+noRows-1, 2) = num2cell(nodeIds);
%                     s(dy1:dy1+noRows-1, 3) = NodesTable.TreeName;
%                     s(dy1:dy1+noRows-1, 4) = NodesTable.NodeName;
%                     s(dy1:dy1+noRows-1, 5:7) = [num2cell(NodesTable.PointsXYZ(:,1)), num2cell(NodesTable.PointsXYZ(:,2)), num2cell(NodesTable.PointsXYZ(:,3))];
%                     NodesTable.TreeName = [];
%                     NodesTable.NodeName = [];
%                     NodesTable.PointsXYZ = [];
%                     [~, noCols] = size(NodesTable);
%                     s(dy1:dy1+noRows-1, 8:8+noCols-1) = table2cell(NodesTable);
%                     dy1 = dy1 + noRows;
%                     
%                     s2(dy2, 1) = TreeName;
%                     [noRows, ~] = size(EdgesTable);
%                     s2(dy2:dy2+noRows-1, 2) = num2cell(EdgesTable.EndNodes(:,1));
%                     s2(dy2:dy2+noRows-1, 3) = num2cell(EdgesTable.EndNodes(:,2));
%                     s2(dy2:dy2+noRows-1, 4) = NodeNames(EdgesTable.EndNodes(:,1)-nodesCount);
%                     s2(dy2:dy2+noRows-1, 5) = NodeNames(EdgesTable.EndNodes(:,2)-nodesCount);
%                     s2(dy2:dy2+noRows-1, 6) = num2cell(EdgesTable.Weight);
%                     s2(dy2:dy2+noRows-1, 7) = num2cell(EdgesTable.Length);
%                     EdgesTable.EndNodes = [];
%                     EdgesTable.Weight = [];
%                     EdgesTable.Length = [];
%                     EdgesTable.Edges = [];  % do not save Edges
%                     [~, noCols] = size(EdgesTable);
%                     s2(dy2:dy2+noRows-1, 8:8+noCols-1) = table2cell(EdgesTable);
%                     dy2 = dy2 + noRows;
%                     nodesCount = nodesCount + size(NodesTable,1);
%                 end
%                 
%                 waitbar(.2, wb);
%                 xlswrite2(fn_out, s, 'Nodes', 'A1');
%                 waitbar(.7, wb);
%                 xlswrite2(fn_out, s2, 'Edges', 'A1');
%                 
%                 waitbar(1, wb);
%                 delete(wb);
%             else    % Spatial graph for Amira
%                 if strcmp(Filters{FilterIndex+numel(Filters)/2}, 'Amira Spatial Graph ASCII (*.am)')
%                     options.format = 'ascii';
%                 else
%                     options.format = 'binary';
%                 end
%                 options.overwrite = 1;
%                 
%                 extraNodeFields = obj.mibModel.I{obj.mibModel.Id}.hLines3D.extraNodeFields;
%                 if ~isempty(extraNodeFields)
%                     extraNodeFieldsNumeric = obj.mibModel.I{obj.mibModel.Id}.hLines3D.extraNodeFieldsNumeric;
%                     extraNodeFields = extraNodeFields(extraNodeFieldsNumeric>0);
%                 end
%                 extraEdgeFields = obj.mibModel.I{obj.mibModel.Id}.hLines3D.extraEdgeFields;
%                 if ~isempty(extraEdgeFields)
%                     extraEdgeFieldsNumeric = obj.mibModel.I{obj.mibModel.Id}.hLines3D.extraEdgeFieldsNumeric;
%                     extraEdgeFields = extraEdgeFields(extraEdgeFieldsNumeric>0);
%                 end
%                 
%                 if ~isempty(extraEdgeFields) || ~isempty(extraNodeFields)
%                     % add default fields
%                     extraEdgeFields = [{'Length'; 'Weight'}; extraEdgeFields];
%                     extraNodeFields = [{'Radius'}; extraNodeFields];
%                     
%                     selectedNode = obj.View.handles.nodesViewAdditionalField.String(obj.View.handles.nodesViewAdditionalField.Value);
%                     if numel(extraNodeFields) < 2
%                         prompts = {'Field for nodes:'; 'Field for edges:'};
%                         defAns = {[extraNodeFields; find(ismember(extraNodeFields, selectedNode))]; extraEdgeFields};
%                     else
%                         nodeId2 = find(~ismember(extraNodeFields, selectedNode));
%                         prompts = {'First field for nodes:'; 'Second field for nodes:'; 'Field for edges:'};
%                         defAns = {[extraNodeFields; find(ismember(extraNodeFields, selectedNode))]; ...
%                                   [extraNodeFields; nodeId2(1)]; ...   
%                                   extraEdgeFields};
%                     end
%                     dlgTitle = 'Export to Amira';
%                     options.WindowStyle = 'normal';       % [optional] style of the window
%                     %options.PromptLines = [1, 1];   % [optional] number of lines for widget titles
%                     options.Title = sprintf('Select fields to export\n(only numerical fields can be exported)');
%                     options.TitleLines = 2;
%                     options.Focus = 1;      % [optional] define index of the widget to get focus
%                     [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
%                     if isempty(answer); return; end
%                     if numel(extraNodeFields) < 2
%                         outputFieldNode = extraNodeFields(selIndex(1));
%                         outputFieldEdge = extraEdgeFields(selIndex(2));
%                     else
%                         outputFieldNode = [extraNodeFields(selIndex(1)); extraNodeFields(selIndex(2))];
%                         outputFieldEdge = extraEdgeFields(selIndex(3));
%                     end
%                 else
%                     outputFieldNode = {'Radius'};
%                     outputFieldEdge = {'Weight'};
%                 end
%                 options.NodeFieldName = outputFieldNode;
%                 options.EdgeFieldName = outputFieldEdge;
%                 
%                 Lines3D.G.Nodes.XData = Lines3D.G.Nodes.PointsXYZ(:,1);
%                 Lines3D.G.Nodes.YData = Lines3D.G.Nodes.PointsXYZ(:,2);
%                 Lines3D.G.Nodes.ZData = Lines3D.G.Nodes.PointsXYZ(:,3);
%                 Lines3D.G.Nodes = removevars(Lines3D.G.Nodes, 'PointsXYZ');     % remove PointsXYZ
%                 %Lines3D.G.Nodes.(outputFieldNode) = Lines3D.G.Nodes.(outputFieldNode);     % remove PointsXYZ
%                 %Lines3D.G.Nodes = removevars(Lines3D.G.Nodes, outputFieldNode);     % remove PointsXYZ
%                 
%                 % generate points for edge segments
%                 % require to have two points (starting and ending) for each
%                 % edge
%                 Lines3D.G.Edges.Points = repmat({zeros([2 6])}, [size(Lines3D.G.Edges,1) 1]);
%                 %storeEdgeValues = Lines3D.G.Edges.(outputFieldEdge{1});
%                 %Lines3D.G.Edges.(outputFieldEdge{1}) = zeros([size(Lines3D.G.Edges,1) 1]);
%                 for edgeId = 1:size(Lines3D.G.Edges,1)
%                     id1 = Lines3D.G.Edges.EndNodes(edgeId,1);
%                     id2 = Lines3D.G.Edges.EndNodes(edgeId,2);
%                     Lines3D.G.Edges.Points{edgeId, :} = ...
%                         [Lines3D.G.Nodes.XData([id1 id2]), Lines3D.G.Nodes.YData([id1 id2]), Lines3D.G.Nodes.ZData([id1 id2])];
%                     %Lines3D.G.Edges.(outputFieldEdge{1})(edgeId) = storeEdgeValues(edgeId);
%                 end
%                 graph2amiraSpatialGraph(fn_out, Lines3D.G, options);
%             end
%             fprintf('Saving Lines3D to %s: done!\n', fn_out);
%             
%         end
%         
        function deleteBtn_Callback(obj)
            % function deleteBtn_Callback(obj)
            % delete all annotations
            button = questdlg(sprintf('!!! Warning !!!\n\nYou are going to remove all 3d lines, are you sure?'), ...
                'Delete all', 'Delete', 'Cancel', 'Cancel');
            if strcmp(button, 'Cancel'); return; end
            
            obj.mibModel.mibDoBackup('lines3d');
            obj.mibModel.I{obj.mibModel.Id}.hLines3D.clearContents()
            notify(obj.mibModel, 'plotImage');
            obj.updateWidgets();
        end
        
        function nodesViewTable_CellSelectionCallback(obj, Indices, forceJump)
            % function nodesViewTable_CellSelectionCallback(obj, Indices, forceJump)
            % a callback for cell selection of obj.View.handles.nodesViewTable
            %
            % Parameters:
            % Indices: index of the selected cell, returned by eventdata.Indices structure of GUI
            % forceJump: switch 1 - jump to node, 0 - do as obj.View.handles.jumpCheck.Value indicates
            if nargin < 3; forceJump = 0; end
            
            if forceJump == 0; forceJump = obj.View.handles.jumpCheck.Value; end
            obj.indicesNodes = Indices;
            
            if forceJump == 1  % jump to the selected annotation
                obj.nodesViewTable_cb('Jump');
            end
        end
        
        function edgesViewTable_CellSelectionCallback(obj, Indices, forceJump)
            % function edgesViewTable_CellSelectionCallback(obj, Indices, forceJump)
            % a callback for cell selection of obj.View.handles.edgesViewTable
            %
            % Parameters:
            % Indices: index of the selected cell, returned by eventdata.Indices structure of GUI
            % forceJump: switch 1 - jump to node, 0 - do as obj.View.handles.jumpCheck.Value indicates
            if nargin < 3; forceJump = obj.View.handles.jumpCheck.Value; end
            
            obj.indicesEdges = Indices;
            
            if forceJump == 1  % jump to the selected annotation
                if isempty(obj.indicesEdges); return; end
                if obj.indicesEdges(1,2) > 2; return; end
                nodeId = cell2mat(obj.View.handles.edgesViewTable.Data(obj.indicesEdges(1,1), obj.indicesEdges(1,2)));
                obj.nodesViewTable_cb('Jump', nodeId);
            end
            
        end
        
        function treesViewTable_CellSelectionCallback(obj, Indices)
            % function treesViewTable_CellSelectionCallback(obj, Indices)
            % a callback for cell selection of obj.View.handles.treesViewTable
            %
            % Parameters:
            % Indices: index of the selected cell, returned by
            % eventdata.Indices structure of GUI
            
            if isempty(Indices); return; end
            if isempty(obj.View.handles.nodesViewTable.RowName(1)); return; end
            
            rowId = Indices(1);
            if obj.indicesTrees ~= rowId
                if isempty(obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId)
                    treeName = obj.mibModel.I{obj.mibModel.Id}.hLines3D.getTreeNames(rowId);
                    nodeIds = find(ismember(obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.TreeName, treeName));
                    if ~isempty(nodeIds)
                        obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId = nodeIds(end);
                    end
                end
                if ~isempty(obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId)
                    curTable = obj.View.handles.tableSelectionPopup.String{obj.View.handles.tableSelectionPopup.Value};
                    switch curTable
                        case 'Nodes'
                            obj.updateNodesViewTable(rowId);
                            nodeIds = str2num(obj.View.handles.nodesViewTable.RowName); %#ok<ST2NM>
                        case 'Edges'
                            obj.updateEdgesViewTable(rowId);
                            %nodeIds = unique(cell2mat(obj.View.handles.edgesViewTable.Data(:,1:2)));
                            nodeIds = cell2mat(obj.View.handles.edgesViewTable.Data(:,1:2));
                    end
                    [isActiveInTheTree, posX] = find(nodeIds == obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId); %#ok<EFIND>
                    if isempty(isActiveInTheTree)
                        switch curTable
                            case 'Nodes'
                                obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId = max(nodeIds);
                                isActiveInTheTree = numel(nodeIds);
                            case 'Edges'
                                obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId = max(nodeIds(:));
                                [isActiveInTheTree, posX] = find(nodeIds == obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId); %#ok<EFIND>
                        end
                    end
                    forceJump = 1;
                    switch curTable
                        case 'Nodes'
                            obj.nodesViewTable_CellSelectionCallback(isActiveInTheTree, forceJump);
                        case 'Edges'
                            obj.edgesViewTable_CellSelectionCallback([isActiveInTheTree, posX], forceJump);
                    end
                    obj.View.handles.activeNodeText.String = sprintf('Active node: %d', obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId);
                    obj.View.handles.activeTreeText.String = sprintf('Active tree: %d', rowId);
                end
            end
            obj.indicesTrees = Indices(:, 1);
        end
        
        function treesViewTable_CellEditCallback(obj, Indices)
            % function treesViewTable_CellEditCallback(obj, Indices)
            % a callback for cell edit of obj.View.handles.treesViewTable
            %
            % Parameters:
            % Indices: index of the selected cell, returned by
            % eventdata.Indices structure of GUI
            
            data = obj.View.handles.treesViewTable.Data;    % get table contents
            rowIndices = obj.View.handles.treesViewTable.RowName;  % get row names, that are indices for the labels.
            rowId = Indices(1);
            obj.mibModel.mibDoBackup('labels', 0);
            
            newLabelText = data(rowId, 1);
            newLabelValue = str2double(data{rowId, 2});
            newLabelPos(1) = str2double(data{rowId, 3});
            newLabelPos(2) = str2double(data{rowId, 4});
            newLabelPos(3) = str2double(data{rowId, 5});
            newLabelPos(4) = str2double(data{rowId, 6});
            obj.mibModel.I{obj.mibModel.Id}.hLabels.updateLabels(str2double(rowIndices(rowId,:)), newLabelText, newLabelPos, newLabelValue);
            notify(obj.mibModel, 'plotImage');  % notify to plot the image
        end
       
        function treesViewTable_cb(obj, parameter)
            %function treesViewTable_cb(obj, parameter)
            % callbacks for the context menu of obj.View.handles.treesViewTable
            %
            % Parameters:
            % parameter: a string with selected option
            global mibPath;
            if isempty(obj.indicesTrees); return; end
            switch parameter
                case 'rename'
                    rowId = obj.indicesTrees(:,1);
                    rowText = obj.View.handles.treesViewTable.Data(rowId(1),:);
                    currentName = rowText{1};
                    
                    answer = mibInputDlg({mibPath}, 'New name for the selected tree:', ...
                        'Rename', currentName);
                    if isempty(answer); return; end
                    
                    if sum(ismember(obj.View.handles.treesViewTable.Data(:,1), answer(1)))>0
                        msgbox(sprintf('!!! Warning !!!\n\nThe names of trees should be unique!'), 'Duplicated tree name', 'warn');
                        return;
                    end
                    obj.mibModel.mibDoBackup('lines3d');
                    
                    obj.mibModel.I{obj.mibModel.Id}.hLines3D.defaultTreeName = answer{1};
                    
                    obj.mibModel.mibDoBackup('lines3d');
                    ids = find(ismember(obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.TreeName, rowText(1))==1);
                    obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.TreeName(ids) = answer(1);
                    obj.updateWidgets();
                    notify(obj.mibModel, 'plotImage');  % notify to plot the image
                case 'find'
                    answer = mibInputDlg({mibPath}, 'Enter index of the node to find a corresponding tree:', ...
                        'Find tree', '1');
                    if isempty(answer); return; end
                    nodeId = str2double(answer{1});
                    if isnan(nodeId); return; end
                    
                    TreeName = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes(nodeId,:).TreeName;
                    TreeNames = obj.View.handles.treesViewTable.Data(:,1);
                    Indices = find(ismember(TreeNames, TreeName));
                    obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId = nodeId;
                    obj.jTreeTable.changeSelection(Indices-1, 0, false, false);
                case 'visualize'
                    rowId = obj.indicesTrees(:,1);
                    obj.visualizeBtn_Callback(rowId);
                case 'save'
                    treeIds = obj.indicesTrees(:,1);
                    if numel(treeIds) > 1
                        errordlg('Please select a single tree and try again!', 'Multiple trees selection');
                        return;
                    end
                    obj.saveBtn_Callback(treeIds);
                case 'delete'
                    obj.mibModel.mibDoBackup('lines3d');
                    rowId = obj.indicesTrees(:,1);
                    button =  questdlg(sprintf('!!! Warning !!!\n\nYou are going to delete selected trees!\nAre you sure?'), ...
                        'Delete tree(s)', 'Delete', 'Cancel', 'Cancel');
                    if strcmp(button, 'Cancel'); return; end
                    
                    obj.mibModel.I{obj.mibModel.Id}.hLines3D.deleteTree(rowId);
                    obj.updateWidgets();
                    obj.nodesViewTable_cb('Jump', obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId);
                    notify(obj.mibModel, 'plotImage');
            end
        end
        
        
        function edgesViewTable_cb(obj, parameter)
            % function edgesViewTable_cb(obj, parameter)
            % callbacks for the context menu of obj.View.handles.edgesViewTable
            %
            % Parameters:
            % parameter: a string with selected option
            
            if isempty(obj.indicesEdges); return; end
            switch parameter
                case 'Jump'
                    if obj.indicesEdges(1,2) > 2
                        errordlg('Please select a cell containing index of a node!', 'Wrong cell', 'modal');
                        return;
                    end
                    nodeId = cell2mat(obj.View.handles.edgesViewTable.Data(obj.indicesEdges(1,1), obj.indicesEdges(1,2)));
                    obj.nodesViewTable_cb('Jump', nodeId);
                case 'Active'
                    if obj.indicesEdges(1,2) > 2
                        errordlg('Please select a cell containing index of a node!', 'Wrong cell', 'modal');
                        return;
                    end
                    nodeId = cell2mat(obj.View.handles.edgesViewTable.Data(obj.indicesEdges(1,1), obj.indicesEdges(1,2)));
                    obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId = nodeId;
                    obj.nodesViewTable_cb('Jump', nodeId);
                    obj.View.handles.activeNodeText.String = sprintf('Active node: %d', obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId);
            end
            
        end
        
        function nodesViewTable_cb(obj, parameter, nodeId)
            % function nodesViewTable_cb(obj, parameter)
            % callbacks for the context menu of obj.View.handles.nodesViewTable
            %
            % Parameters:
            % parameter: a string with selected option
            % nodeId: [@em optional], index of the node to jump or modify
            
            global mibPath;
            if nargin < 3; nodeId = []; end
            
            if ~isempty(nodeId)
                nodeTableIndices = str2num(obj.View.handles.nodesViewTable.RowName);
                obj.indicesNodes = find(nodeTableIndices==nodeId); 
            end
            if isempty(obj.indicesNodes) && isempty(nodeId); return; end
            
            switch parameter
                case 'Jump'     % jump to the highlighted node
                    if isempty(nodeId)
                        rowId = obj.indicesNodes(1);
                        rowText = obj.View.handles.nodesViewTable.Data(rowId,:);
                    else
                        rowText{3} = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.PointsXYZ(nodeId, 3);     % z
                        rowText{4} = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.PointsXYZ(nodeId, 1);     % x
                        rowText{5} = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.PointsXYZ(nodeId, 2);     % y
                    end
                    
                    getDim.blockModeSwitch = 0;
                    [imgH, imgW, ~, imgZ] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'image', NaN, NaN, getDim);
                    orientation = obj.mibModel.getImageProperty('orientation');        
            
                    [rowText{4}, rowText{5}, rowText{3}] = obj.mibModel.I{obj.mibModel.Id}.convertUnitsToPixels(rowText{4}, rowText{5}, rowText{3});
                    
                    if orientation == 4   % xy
                        z = rowText{3};
                        x = rowText{4};
                        y = rowText{5};
                    elseif orientation == 1   % zx
                        z = rowText{5};
                        x = rowText{3};
                        y = rowText{4};
                    elseif orientation == 2   % zy
                        z = rowText{4};
                        x = rowText{3};
                        y = rowText{5};
                    end
                    
                    % do not jump when the node out of image boundaries
                    if x>imgW || y>imgH || z>imgZ
                        warndlg(sprintf('The node is outside of the image boundaries!'), 'Wrong coordinates');
                        return;
                    end
                    
                    % move image-view to the object
                    obj.mibModel.I{obj.mibModel.Id}.moveView(x, y);
                    
                    %                 % change t
                    %                 if obj.mibModel.getImageProperty('time') > 1
                    %                     eventdata = ToggleEventData(floor(t));
                    %                     notify(obj.mibModel, 'updateTimeSlider', eventdata);
                    %                 end
                    
                    % change z
                    if obj.mibModel.I{obj.mibModel.Id}.dim_yxczt(orientation) > 1
                        eventdata = ToggleEventData(round(z));
                        notify(obj.mibModel, 'updateLayerSlider', eventdata);
                    else
                        notify(obj.mibModel, 'plotImage');
                    end
                case 'Active'
                    rowId = obj.indicesNodes(1);
                    obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId = ...
                        str2double(obj.View.handles.nodesViewTable.RowName(rowId,:));
                    obj.nodesViewTable_cb('Jump');
                    obj.View.handles.activeNodeText.String = sprintf('Active node: %d', obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId);
                case 'Rename'
                    rowId = obj.indicesNodes(:,1);
                    rowText = obj.View.handles.nodesViewTable.Data(rowId(1),:);
                    currentName = rowText{1};
                    
                    answer = mibInputDlg({mibPath}, 'New name for the selected nodes:', ...
                        'Rename', currentName);
                    if isempty(answer); return; end
                    
                    obj.mibModel.mibDoBackup('lines3d');
                    nodesIds = str2num(obj.View.handles.nodesViewTable.RowName(rowId,:)); %#ok<ST2NM>
                    obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.NodeName(nodesIds) = repmat(answer(1), [numel(nodesIds),1]);
                    
                    obj.updateWidgets();
                    notify(obj.mibModel, 'plotImage');  % notify to plot the image
                case 'Pixels'   % show coordinate in pixels
                    rowId = obj.indicesNodes(1);
                    rowText = obj.View.handles.nodesViewTable.Data(rowId,:);
                    [x1, y1, z1] = obj.mibModel.I{obj.mibModel.Id}.convertUnitsToPixels(rowText{4}, rowText{5}, rowText{3});
                    orientation = obj.mibModel.getImageProperty('orientation');
                    
                    if orientation == 4   % xy
                        z = z1;
                        x = x1;
                        y = y1;
                    elseif orientation == 1   % zx
                        z = y1;
                        x = z1;
                        y = x1;
                    elseif orientation == 2   % zy
                        z = x1;
                        x = z1;
                        y = y1;
                    end
                    msgText = sprintf('The coordinate of the node %d\n(x,y,z = %f, %f, %f)\n\nin pixels:\nXY orientation:         %d, %d, %d\nCurrent orientation:  %d, %d, %d', rowId, rowText{4}, rowText{5}, rowText{3}, round(x1), round(y1), round(z1), round(x), round(y), round(z));
                    msgbox(msgText, 'Node coordinate');
                    
                case {'AnnotationsNew', 'AnnotationsAdd', 'AnnotationsDelete'}  % generate annotations from nodes
                    if strcmp(parameter, 'AnnotationsNew')    % clear existing annotations
                        if obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber() > 0
                            button = questdlg(sprintf('!!! Warning !!!\n\nDo you want to overwrite the existing annotations?'), ...
                                'Overwrite annotations', 'Overwrite', 'Cancel', 'Cancel');
                            if strcmp(button, 'Cancel'); return; end
                        end
                        obj.mibModel.mibDoBackup('labels', 0);
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.clearContents();
                    end
                    
                    if ~strcmp(parameter, 'AnnotationsDelete')
                        button = questdlg(sprintf('Would you like to use node names or node indices as labels?'), ...
                            'Define name for labels', 'Node names', 'Node indices', 'Cancel', 'Node names');
                        if strcmp(button, 'Cancel'); return; end
                    end
                    
                    rowId = obj.indicesNodes(:,1);
                    nodesIds = str2num(obj.View.handles.nodesViewTable.RowName(rowId,:)); %#ok<ST2NM>
                    
                    % [labelIndex, z x y t]
                    positionList = [obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.PointsXYZ(nodesIds, 3), ...
                                    obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.PointsXYZ(nodesIds, 1), ...
                                    obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.PointsXYZ(nodesIds, 2), ...
                                    ones([numel(nodesIds) 1])];
                    
                    % convert from units to pixels
                    [positionList(:,2), positionList(:,3), positionList(:,1)] = obj.mibModel.I{obj.mibModel.Id}.convertUnitsToPixels(positionList(:,2), positionList(:,3), positionList(:,1));
                    
                    if ~strcmp(parameter, 'AnnotationsDelete')
                        if strcmp(button, 'Node names')
                            labelList = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.NodeName(nodesIds);
                        else
                            labelList = cellstr(num2str(nodesIds));
                        end
                    end
                    
                    fieldName = obj.View.handles.nodesViewAdditionalField.String{obj.View.handles.nodesViewAdditionalField.Value};
                    
                    if ~isnumeric(obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.(fieldName)(1))
                        labelValues = zeros([numel(nodesIds) 1]);
                    else
                        labelValues = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G.Nodes.(fieldName)(nodesIds);
                    end
                    
                    if strcmp(parameter, 'AnnotationsDelete')
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.removeLabels(positionList);   % remove labels by position
                    else
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(labelList, positionList, labelValues);
                    end
                    obj.mibModel.mibShowAnnotationsCheck = 1;
                    
                    notify(obj.mibModel, 'updatedAnnotations');
                    notify(obj.mibModel, 'plotImage');
                    
                case 'Delete'   % delete the highlighted annotation
                    rowId = obj.indicesNodes(:,1);
                    nodesIds = str2num(obj.View.handles.nodesViewTable.RowName(rowId,:)); %#ok<ST2NM>
                    if numel(nodesIds) == 1
                        button =  questdlg(sprintf('Delete the following node?\n\nNode Id: %d', nodesIds),'Delete node', 'Delete', 'Cancel', 'Cancel');
                    else
                        button =  questdlg(sprintf('Delete the multiple nodes?'), 'Delete nodes','Delete','Cancel','Cancel');
                    end
                    if strcmp(button, 'Cancel'); return; end
                    
                    obj.mibModel.mibDoBackup('lines3d');
                    wb = waitbar(0, 'Please wait...', 'Name', 'Delete node');
                    index = 0;
                    for i=numel(nodesIds):-1:1
                        obj.mibModel.I{obj.mibModel.Id}.hLines3D.deleteNode(nodesIds(i)); 
                        notify(obj.mibModel, 'plotImage');  % notify to plot the image
                        index = index + 1;
                        waitbar(index/numel(nodesIds), wb);
                    end
                    obj.updateWidgets();
                    delete(wb);
                    notify(obj.mibModel, 'plotImage');  % notify to plot the image
            end
        end
        
        function visualizeBtn_Callback(obj, treeId)
            % function visualizeBtn_Callback(obj, treeId)
            % callback for press of the Visualize button
            % visualize the graph in 3D using a separate figure
            %
            % Parameters:
            % treeId: [@em optional] index of tree to visualize
            global mibPath;
            
            if nargin < 2; treeId = 0; end
            
            % check to show or not a slice
            prompts = {'Use default colors?', 'Add an orthoslice of the visualization?', 'Slice number:'};
            defAns = {true, false, num2str(obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber())};
            dlgTitle = 'Add slice';
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle);
            if isempty(answer); return; end
            
            if answer{2} == 1
                showSlice = str2double(answer{3});
            else
                showSlice = [];
            end
            
            defaultColors = answer{1};
            
            if isempty(obj.hFig)
                obj.hFig = figure();
                obj.hAx = axes();
            elseif ~isvalid(obj.hFig)
                obj.hFig = figure(); 
                obj.hAx = axes();
            end
            if treeId == 0
                nodeIds = [];
                Graph = obj.mibModel.I{obj.mibModel.Id}.hLines3D.G;
            else
                [Graph, nodeIds] = obj.mibModel.I{obj.mibModel.Id}.hLines3D.getTree(treeId);
            end
            if ~isempty(nodeIds)
                Graph.Nodes.Name = cellstr(num2str(nodeIds'));
            end
            
            pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            
            obj.hPlot = plot(obj.hAx, Graph);
            obj.hPlot.XData = Graph.Nodes.PointsXYZ(:,1);
            obj.hPlot.YData = Graph.Nodes.PointsXYZ(:,2);
            obj.hPlot.ZData = Graph.Nodes.PointsXYZ(:,3);
            obj.hAx.XLabel.String = ['X, ', pixSize.units];
            obj.hAx.YLabel.String = ['Y, ', pixSize.units];
            obj.hAx.ZLabel.String = ['Z, ', pixSize.units];
            obj.hAx.DataAspectRatio = [1 1 1];
            grid(obj.hAx, 'on');
            obj.hAx.XAxis.TickValues = obj.hAx.XAxis.Limits(1):diff(obj.hAx.XAxis.Limits)/5:obj.hAx.XAxis.Limits(2);
            obj.hAx.YAxis.TickValues = obj.hAx.YAxis.Limits(1):diff(obj.hAx.YAxis.Limits)/5:obj.hAx.YAxis.Limits(2);
            obj.hAx.ZAxis.TickValues = obj.hAx.ZAxis.Limits(1):diff(obj.hAx.ZAxis.Limits)/5:obj.hAx.ZAxis.Limits(2);
            if defaultColors == 0
                obj.hPlot.LineWidth = obj.mibModel.I{obj.mibModel.Id}.hLines3D.edgeThickness;
                obj.hPlot.MarkerSize = obj.mibModel.I{obj.mibModel.Id}.hLines3D.nodeRadius;
                obj.hPlot.EdgeColor =  obj.mibModel.I{obj.mibModel.Id}.hLines3D.edgeActiveColor;
                obj.hPlot.NodeColor = obj.mibModel.I{obj.mibModel.Id}.hLines3D.nodeColor;
            end
            
            % add an orthoslice to the image
            if ~isempty(showSlice)
                if showSlice > obj.mibModel.getImageProperty('depth')
                    showSlice = obj.mibModel.getImageProperty('depth');
                else
                    showSlice = max([1 showSlice]);
                end
                getRGBOptions.sliceNo = showSlice;
                getRGBOptions.mode = 'full';
                getRGBOptions.resize = 'no';
                
                img = obj.mibModel.getRGBimage(getRGBOptions);
                bb = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
                
                hold on;
                xValue = deal(bb(1):(bb(2)-bb(1))/size(img,2):bb(2));
                xValue = xValue(1:end-1);
                yValue = deal(bb(3):(bb(4)-bb(3))/size(img,1):bb(4));
                yValue = yValue(1:end-1);
                [xValue, yValue] = meshgrid(xValue, yValue);
                
                zValue = showSlice*pixSize.z+bb(5);
                surf(xValue, yValue, zValue+zeros([size(img, 1) size(img, 2)]), img, 'EdgeColor', 'none')
                colormap('gray');
                hold off;
                % update the z-limits
                %zlim = get(gca, 'zlim');
                %set(gca, 'zlim', [1 zlim(2)]);
                %set(gca, 'zlim', [1 zlim(2)]);
            end
            disp('Hint: render image to file with the following command:')
            disp('print(''MIB-snapshot.tif'', ''-dtiff'', ''-r600'',''-opengl'');');
        end
        
    end
end