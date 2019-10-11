classdef mibDatasetInfoController < handle
    % classdef mibDatasetInfoController < handle
    % a controller class for the Dataset information window available via
    % the Info button of the Path panel
    
    % Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
        rootNode
        % a variable for the root node of the uitree
        treeModel
        % a variable for  iutree Model
        uiTree
        % a variable for uiTree
        selectedNodeName
        % name of the selected node
        selectedNodePos
        % position of the selected node, a structure with .x and .y fields
        foundNode
        % a found node using the Search option
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case 'updateGuiWidgets'
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibDatasetInfoController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibDatasetInfoGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % setup uiTree
            % based on description by Yair Altman:
            % http://undocumentedmatlab.com/blog/customizing-uitree
            warning('off', 'MATLAB:uitreenode:DeprecatedFunction');
            warning('off', 'MATLAB:uitree:DeprecatedFunction');
            
            obj.selectedNodeName = [];
            obj.selectedNodePos = struct;
            obj.foundNode = [];
            
            import javax.swing.*
            import javax.swing.tree.*;
            
            %obj.rootNode = uitreenode('v0','root', 'meta', [], false);  % initialize the root node
            %obj.treeModel = DefaultTreeModel(obj.rootNode);     % set the tree Model
            [obj.uiTree, obj.View.handles.uiTreeContainer] = uitree('v0');   % create the uiTree
            obj.View.handles.uiTreeContainer.Parent = obj.View.handles.uiTreePanel;    % assign to the parent panel
            obj.View.handles.uiTreeContainer.Units = 'points';
            uiTreePanelPos = obj.View.handles.uiTreePanel.Position;
            obj.View.handles.uiTreeContainer.Position = [5, 5, uiTreePanelPos(3)-8, uiTreePanelPos(4)-8]; % resize uiTree

%             obj.uiTree.setModel(obj.treeModel);
%             obj.uiTree.setSelectedNode(obj.rootNode);   % make root the initially selected node
%             obj.uiTree.setMultipleSelectionEnabled(1);  % enable multiple selections
            
            % get all handles of the GUI
            windowHandles = guidata(obj.View.gui);
            % add uiTreeContainer to the list of handles, otherwise the Resize function is not working
            windowHandles.uiTreeContainer = obj.View.handles.uiTreeContainer;
            % update guidata
            guidata(obj.View.gui, windowHandles);
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.handles.mibDatasetInfoGUI);
            obj.updateWidgets();
            
            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            
        end
        
        function closeWindow(obj)
            % closing mibDatasetInfoController window
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
        
        function simplifyBtn_Callback(obj)
            % remove most of metadata
            res = questdlg(sprintf('!!! Warning !!!\n\nYou are going to remove most of metadata.\nThe bounding box and the lut colors will be preserved\n\nContinue?'), 'Remove metadata', 'Continue', 'Cancel', 'Cancel');
            if strcmp(res, 'Cancel'); return; end
            
            meta = obj.mibModel.getImageProperty('meta');
            keySet = keys(meta);
            
            mainKeys = {'Filename', 'Height','Width', 'Depth', 'Time', 'ImageDescription', 'ColorType', 'ResolutionUnit', ...
                'XResolution','YResolution','SliceName','SeriesNumber','lutColors'};
            removeKeysPos = ~ismember(keySet, mainKeys);
            removeKeys = keySet(removeKeysPos);
            remove(meta, removeKeys);
            obj.mibModel.setImageProperty('meta', meta);
            obj.updateWidgets();
        end
        
        function updateWidgets(obj)
            % % populate uiTree
            import javax.swing.*
            import javax.swing.tree.*;
            warning('off','MATLAB:uitreenode:DeprecatedFunction');
            warning('off','MATLAB:uitree:DeprecatedFunction');
            
            obj.foundNode = [];
            
            meta = obj.mibModel.getImageProperty('meta');
            keySet = keys(meta);
            
            obj.rootNode = uitreenode('v0','root', 'meta', [], false);  % initialize the root node
            obj.treeModel = DefaultTreeModel(obj.rootNode);     % set the tree Model
            obj.uiTree.setModel(obj.treeModel);
            if isempty(obj.selectedNodeName)
                obj.uiTree.setSelectedNode(obj.rootNode);   % make root the initially selected node
            end
            obj.uiTree.setMultipleSelectionEnabled(1);  % enable multiple selections
            
            % add main key
            mainKeys = {'Filename', 'Height','Width', 'Depth', 'Time', 'ImageDescription', 'ColorType', 'ResolutionUnit', ...
                'XResolution','YResolution','SliceName','SeriesNumber','lutColors'};
            mainKeysPos = ismember(keySet, mainKeys);
            mainKeys = keySet(mainKeysPos);
            syncNode = [];  % id of a node for uiTree sync
                        
            for keyId = 1:numel(mainKeys)
                if isnumeric(meta(mainKeys{keyId}))
                    val = meta(mainKeys{keyId});
                    if size(val,1) == 1
                        strVal = sprintf('%s: %s', mainKeys{keyId}, num2str(val));
                        childNode = uitreenode('v0',1, strVal, [], true);
                        obj.treeModel.insertNodeInto(childNode, obj.rootNode, obj.rootNode.getChildCount());
                    else
                        childNode = uitreenode('v0','dummy', mainKeys{keyId}, [], false);
                        obj.treeModel.insertNodeInto(childNode, obj.rootNode, obj.rootNode.getChildCount());
                        for chId = 1:size(val,1)
                            subChildNode = uitreenode('v0', num2str(chId), sprintf('%s', num2str(val(chId,:))), [], true);
                            obj.treeModel.insertNodeInto(subChildNode, childNode, childNode.getChildCount());
                        end
                    end
                elseif iscell(meta(mainKeys{keyId}))
                    elementList = meta(mainKeys{keyId});
                    if numel(elementList) == 1
                        strVal = sprintf('%s: %s',mainKeys{keyId}, elementList{1});
                        childNode = uitreenode('v0', '1', strVal, [], true);
                        obj.treeModel.insertNodeInto(childNode, obj.rootNode, obj.rootNode.getChildCount());
                    else
                        childNode = uitreenode('v0','dummy', mainKeys{keyId}, [], false);
                        obj.treeModel.insertNodeInto(childNode, obj.rootNode, obj.rootNode.getChildCount());
                        
                        for elelentId = 1:numel(elementList)
                            subChildNode = uitreenode('v0', num2str(elelentId), elementList{elelentId}, [], true);
                            obj.treeModel.insertNodeInto(subChildNode, childNode, childNode.getChildCount());
                        end
                    end
                else
                    strVal = sprintf('%s: %s',mainKeys{keyId}, meta(mainKeys{keyId}));
                    childNode = uitreenode('v0','dummy', strVal, [], true);
                    obj.treeModel.insertNodeInto(childNode, obj.rootNode, obj.rootNode.getChildCount());
                end
                % sync selected nodes
                if ~isempty(obj.selectedNodeName)
                    if strcmp(mainKeys{keyId}, obj.selectedNodeName)
                        syncNode = childNode;
                    end
                end
                drawnow;    % seems to be important, otherwise crashes
            end
            
            if isKey(meta,'meta')
                uiTreeRoot = parseStructToTree(meta('meta'), obj.treeModel, obj.rootNode);
                keySet(ismember(keySet, 'meta')) = [];
            end
            keySet(mainKeysPos) = [];
            
            childNode = uitreenode('v0','Extras', 'Extras', [], false);
            obj.treeModel.insertNodeInto(childNode, obj.rootNode, obj.rootNode.getChildCount());

            for keyId = 1:numel(keySet)
                if strcmp(keySet{keyId}, 'SeriesMetadata')
                    continue;   % this block of meta data will be shown later
                end
                if isnumeric(meta(keySet{keyId}))
                    strVal = sprintf('%s: %f',keySet{keyId}, meta(keySet{keyId}));
                    subChildNode = uitreenode('v0','Extras', strVal, [], true);
                    obj.treeModel.insertNodeInto(subChildNode, childNode, childNode.getChildCount());
                elseif iscell(meta(keySet{keyId}))
                    elementList = meta(keySet{keyId});
                    if numel(elementList) == 1
                        strVal = sprintf('%s: %s',keySet{keyId}, elementList{1});
                        subChildNode = uitreenode('v0','1', strVal, [], true);
                        obj.treeModel.insertNodeInto(subChildNode, childNode, childNode.getChildCount());
                    else
                        subChildNode = uitreenode('v0','Extras', keySet{keyId}, [], false);
                        obj.treeModel.insertNodeInto(subChildNode, childNode, childNode.getChildCount());
                        
                        for elelentId = 1:numel(elementList)
                            subChildNode2 = uitreenode('v0', num2str(elelentId), elementList{elelentId}, [], true);
                            obj.treeModel.insertNodeInto(subChildNode2, subChildNode, subChildNode.getChildCount());
                        end
                    end
                elseif isstruct(meta(keySet{keyId}))
                    fieldNames = fieldnames(meta(keySet{keyId}));
                    subChildNode = uitreenode('v0', keySet{keyId}, keySet{keyId}, [], false);
                    for i=1:numel(fieldNames)
                        if isnumeric(meta(keySet{keyId}).(fieldNames{i}))
                            strVal = sprintf('%s: %f',fieldNames{i}, meta(keySet{keyId}).(fieldNames{i}));
                        elseif isstruct(meta(keySet{keyId}).(fieldNames{i}))
                            % do nothing
                        else
                            strVal = sprintf('%s: %s',fieldNames{i}, meta(keySet{keyId}).(fieldNames{i}));
                        end
                        subChildNode.add(uitreenode('v0', strVal,  strVal,  [], true));
                    end
                    obj.treeModel.insertNodeInto(subChildNode, childNode, childNode.getChildCount());
                else
                    try
                        strVal = sprintf('%s: %s',keySet{keyId}, meta(keySet{keyId}));
                        subChildNode = uitreenode('v0','Extras', strVal, [], true);
                        obj.treeModel.insertNodeInto(subChildNode, childNode, childNode.getChildCount());
                    catch err
                        disp(err)
                    end
                end
                % sync selected nodes
                if ~isempty(obj.selectedNodeName)
                    if strcmp(keySet{keyId}, obj.selectedNodeName)
                        syncNode = subChildNode;
                    end
                end
            end
            
            
            if isKey(meta, 'SeriesMetadata')
                childNode = uitreenode('v0','root', 'SeriesMetadata', [], false);  % initialize the root node
                obj.treeModel.insertNodeInto(childNode, obj.rootNode, obj.rootNode.getChildCount());
                
                keySet2 = keys(meta('SeriesMetadata'));
                keyValues2 = values(meta('SeriesMetadata'));
                for keyId = 1:numel(keySet2)
                    currValue = cell2mat(keyValues2(keyId));
                    if isnumeric(currValue)
                        strVal = sprintf('%s: %f', keySet2{keyId}, cell2mat(keyValues2(keyId)));
                    elseif ischar(currValue)
                        strVal = sprintf('%s: %s', keySet2{keyId}, cell2mat(keyValues2(keyId)));
                    end
                    subChildNode = uitreenode('v0','SeriesMetadata', strVal, [], true);
                    obj.treeModel.insertNodeInto(subChildNode, childNode, childNode.getChildCount());
                end
            end
            
            obj.uiTree.expand(obj.rootNode);  % expand uiTree
            if ~isempty(syncNode)
                obj.uiTree.expand(syncNode);
                scrollPane = obj.uiTree.ScrollPane;
                scrollPaneViewport = scrollPane.getViewport;
                drawnow;
                obj.uiTree.setSelectedNode(syncNode);
                scrollPaneViewport.setViewPosition(java.awt.Point(str2double(obj.selectedNodePos.x), str2double(obj.selectedNodePos.y)));
                scrollPane.repaint;
            end
            obj.uiTree.NodeSelectedCallback = @obj.uiTreeNodeSelectedCallback;
        end
        
        function uiTreeNodeSelectedCallback(obj, varargin)
            % function uiTreeNodeSelectedCallback(obj, varargin)
            % a callback for selection of an entry in the uitree
            nodes = obj.uiTree.getSelectedNodes;
            if isempty(nodes); return; end
            
            % store name of the selected field for syncronization
            obj.selectedNodeName = char(nodes(1).getName);
            colonChar = strfind(obj.selectedNodeName, ':');
            if ~isempty(colonChar)
                obj.selectedNodeName = obj.selectedNodeName(1:colonChar-1);
            end
            scrollPane = obj.uiTree.ScrollPane;
            scrollPaneViewport = scrollPane.getViewport;
            %obj.selectedNodePos = scrollPaneViewport.getViewPosition;  % for some reason coordinates obtained with this method are getting reset after obj.uiTree.setSelectedNode(syncNode);
            posStr = char(scrollPaneViewport.getViewPosition.toString);     % so convert them to string
            index1 = strfind(posStr, '[x=');
            index2 = strfind(posStr, ',y=');
            obj.selectedNodePos.x = num2str(posStr(index1+3:index2-1));
            obj.selectedNodePos.y = num2str(posStr(index2+3:end-1));
            
            nodeName = char(nodes(1).getName);
            obj.View.handles.selectedText.String = nodeName;
        end
        
        function insertBtn_Callback(obj)
            % function insertBtn_Callback(obj)
            % a callback for insert entry button press
            
            options.Resize = 'on';
            prompt = {'New parameter name:','New parameter value:'};
            answer = inputdlg(prompt,'Insert an entry',[1; 5],{'', ''},options);
            if isempty(answer); return; end
            
            meta = obj.mibModel.getImageProperty('meta');
            meta(answer{1}) = answer{2};
            obj.mibModel.setImageProperty('meta', meta);
            obj.updateWidgets();
        end
        
        function modifyBtn_Callback(obj)
            % function modifyBtn_Callback(obj)
            % a callback for modify entry button press
            
            options.Resize = 'on';
            nodes = obj.uiTree.getSelectedNodes;
            nodeName = char(nodes(1).getName);
            colonChar = strfind(nodeName, ':');
            if ~isempty(colonChar)
                nodeName = nodeName(1:colonChar-1);
            end
            
            meta = obj.mibModel.getImageProperty('meta');
            
            subIndex = [];  % subindex of entries
            if ~isKey(meta, nodeName) && nodes(1).isLeaf
                parent = nodes(1).getParent;
                nodeName = char(parent(1).getName);
                colonChar = strfind(nodeName, ':');
                if ~isempty(colonChar)
                    nodeName = nodeName(1:colonChar-1);
                end
                subIndex = str2double(nodes(1).getValue);
            end
            
            if isKey(meta, nodeName)
                if isnumeric(meta(nodeName))
                    strVal{1} = nodeName;
                    value = meta(nodeName);
                    if ~isempty(subIndex)
                        value = value(subIndex, :);
                    end
                    strVal{2} = num2str(value);
                    answer = inputdlg({'New field name:','New value'}, 'Modify the entry',size(strVal{2},1), strVal, options);
                    if isempty(answer); return; end
                    if ~isempty(subIndex)
                        value = meta(nodeName);
                        value(subIndex, :) = str2num(answer{2});
                        meta(nodeName) = value;
                    else
                        remove(meta, nodeName);      % remove the old key
                        meta(answer{1}) = str2num(answer{2});
                    end
                elseif iscell(meta(nodeName))
                    if isempty(subIndex)
                        answer = inputdlg('New field name:', 'Modify the entry',1, {nodeName}, options);
                        if isempty(answer); return; end
                        value = meta(nodeName);
                        remove(meta, nodeName);      % remove the old key
                        meta(answer{1}) = value;
                    else
                        strVal{1} = nodeName;
                        value = meta(nodeName);
                        strVal{2} = value{subIndex};
                        answer = inputdlg({'New field name:','New value'}, 'Modify the entry',size(strVal{2},1), strVal, options);
                        if isempty(answer); return; end
                        value(subIndex) = answer(2);
                        meta(nodeName) = value;
                    end
                else
                    strVal{1} = nodeName;
                    strVal{2} = meta(nodeName);
                    answer = inputdlg({'New field name:','New value'}, 'Modify the entry',5, strVal, options);
                    if isempty(answer); return; end
                    remove(meta, nodeName);      % remove the old key
                    meta(answer{1}) = answer{2};
                end
            end
            obj.mibModel.setImageProperty('meta', meta);
            obj.updateWidgets();
        end
        
        function deleteBtn_Callback(obj)
            % function deleteBtn_Callback(obj)
            % delete selected entry from uitree
            button = questdlg(sprintf('Warning!!!\n\nYou are going to delete the highlighted parameters!\nAre you sure?'),'Delete entries','Delete','Cancel','Cancel');
            if strcmp(button, 'Cancel'); return; end
            
            meta = obj.mibModel.getImageProperty('meta');
            
            nodes = obj.uiTree.getSelectedNodes;
            %keySet = cell([numel(nodes), 1]);
            keySet = [];
            
            for i=1:numel(nodes)
                if nodes(i).getDepth > 0
                    childs = nodes(i).getChildCount();
                    keySetCurrent = cell([childs, 1]);
                    for childId=1:childs
                        nodeName = char(nodes(i).getChildAt(childId-1).getName());
                        colonChar = strfind(nodeName, ':');
                        if ~isempty(colonChar)
                            nodeName = nodeName(1:colonChar-1);
                        end
                        keySetCurrent{childId} = nodeName;
                    end
                else
                    nodeName = char(nodes(i).getName);
                    colonChar = strfind(nodeName, ':');
                    if ~isempty(colonChar)
                        nodeName = nodeName(1:colonChar-1);
                    end
                    keySetCurrent = nodeName;
                end
                keySet = [keySet; keySetCurrent];
            end
            remove(meta, keySet);
            obj.mibModel.setImageProperty('meta', meta);
            obj.updateWidgets();
        end
        
        function searchEdit_Callback(obj, parameter)
            % function searchEdit_Callback(obj, parameter)
            % search for desired text
            %
            % Parameters:
            % parameter: a string with parameter for the function
            % @li 'new' - start a new search
            % @li 'next' - find a next entry
            
            set(0, 'RecursionLimit', 1000); % increase limit for recursive search
            
            if strcmp(parameter, 'new')     % new search
                obj.foundNode = [];
            end
            strVal = obj.View.handles.searchEdit.String;
            try
                if isempty(obj.foundNode)
                    obj.foundNode = findNode(strVal, obj.rootNode);
                else
                    obj.foundNode = findNode(strVal, obj.foundNode.getNextNode);
                end
            catch err
                disp(err)
                obj.foundNode = [];
            end
               
            if isempty(obj.foundNode)
                msgbox('No matching results!','Search', 'warn', 'modal')
                return; 
            end;
            obj.uiTree.setSelectedNode(obj.foundNode);
        end
    end
end