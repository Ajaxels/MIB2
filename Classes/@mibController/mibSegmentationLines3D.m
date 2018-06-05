function mibSegmentationLines3D(obj, y, x, z, modifier)
% output = mibSegmentationLines3D(obj, y, x, z, modifier)
% Add and modify 3D lines
%
% Parameters:
% y: y-coordinate of the node
% x: x-coordinate of the node
% z: z-coordinate of the node
% modifier: a string, to specify what to do with the next point
% - @em empty - add as a new node to the existing tree
% - @em ''shift'' - defines as the first node of a new tree
%
% Return values:
%

% Copyright (C) 18.04.2018 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

%fprintf('x=%d, y=%d, z=%d\n', round(x), round(y), round(z));
obj.mibModel.mibDoBackup('lines3d');

[x, y, z] = obj.mibModel.I{obj.mibModel.Id}.convertPixelsToUnits(x, y, z);     % convert pixels to units
if isempty(modifier)
    action = obj.mibView.handles.mibSegmLines3DClickPopup.String{obj.mibView.handles.mibSegmLines3DClickPopup.Value};
else
    switch modifier{1}
        case 'shift'
            action = obj.mibView.handles.mibSegmLines3DShiftClickPopup.String{obj.mibView.handles.mibSegmLines3DShiftClickPopup.Value};
        case 'control'
            action = obj.mibView.handles.mibSegmLines3DCtrlClickPopup.String{obj.mibView.handles.mibSegmLines3DCtrlClickPopup.Value};
        case 'alt'
            action = obj.mibView.handles.mibSegmLines3DAltClickPopup.String{obj.mibView.handles.mibSegmLines3DAltClickPopup.Value};
        otherwise
            action = obj.mibView.handles.mibSegmLines3DClickPopup.String{obj.mibView.handles.mibSegmLines3DClickPopup.Value};
    end    
end

% if strcmp(modifier, 'shift')
%     action = obj.mibView.handles.mibSegmLines3DShiftClickPopup.String{obj.mibView.handles.mibSegmLines3DShiftClickPopup.Value};
% elseif strcmp(modifier, 'control') % delete the closest node to the clicked point
%     action = obj.mibView.handles.mibSegmLines3DCtrlClickPopup.String{obj.mibView.handles.mibSegmLines3DCtrlClickPopup.Value};
% else
%     action = obj.mibView.handles.mibSegmLines3DClickPopup.String{obj.mibView.handles.mibSegmLines3DClickPopup.Value};
% end

switch action
    case 'Assign active node'
        obj.mibModel.I{obj.mibModel.Id}.hLines3D.setActiveNode(x, y, z, obj.mibModel.I{obj.mibModel.Id}.orientation);
        eventdata = ToggleEventData('Assign active node');
    case 'Delete node'
        result = obj.mibModel.I{obj.mibModel.Id}.hLines3D.deleteNode(x, y, z, obj.mibModel.I{obj.mibModel.Id}.orientation);
        eventdata = ToggleEventData('Delete node');
    case 'Modify active node'
        nodeId = obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId;
        obj.mibModel.I{obj.mibModel.Id}.hLines3D.updateNodeCoordinate(nodeId, x, y, z);
        eventdata = ToggleEventData('Modify active node');
    case 'New tree'
        newTreeSwitch = 1;  % start a new tree
        options.pixSize = obj.mibModel.getImageProperty('pixSize');
        obj.mibModel.I{obj.mibModel.Id}.hLines3D.addNode(x, y, z, newTreeSwitch, options);
        eventdata = ToggleEventData('New tree');
    case 'Split tree'
        obj.mibModel.I{obj.mibModel.Id}.hLines3D.splitAtNode(x, y, z, obj.mibModel.I{obj.mibModel.Id}.orientation);
        eventdata = ToggleEventData('Split tree');
    case 'Add node'
        options.pixSize = obj.mibModel.getImageProperty('pixSize');
        options.BoundingBox = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
        obj.mibModel.I{obj.mibModel.Id}.hLines3D.addNode(x, y, z, 0, options);
        eventdata = ToggleEventData('Add node');
    case 'Insert node after active'
        activeNodeId = obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId;
        if isempty(activeNodeId); errordlg(sprintf('!!! Error !!!\nPlease select first an active node!\nA new node will be inserted after the active node'),'Missing active node'); return; end
        obj.mibModel.I{obj.mibModel.Id}.hLines3D.insertNode(activeNodeId, x, y, z);
        eventdata = ToggleEventData('Insert node');
    case 'Connect to node'
        % find index of the node to which connect the active node
        targetNodeId = obj.mibModel.I{obj.mibModel.Id}.hLines3D.findClosestNode(x, y, z, obj.mibModel.I{obj.mibModel.Id}.orientation);
        activeNodeId = obj.mibModel.I{obj.mibModel.Id}.hLines3D.activeNodeId;
        obj.mibModel.I{obj.mibModel.Id}.hLines3D.connectNodes(targetNodeId, activeNodeId);
        eventdata = ToggleEventData('Connect to node');
end

notify(obj.mibModel, 'updatedLines3D', eventdata);  % notify about update of the class
end