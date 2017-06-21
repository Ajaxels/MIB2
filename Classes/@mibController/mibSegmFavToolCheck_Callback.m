function mibSegmFavToolCheck_Callback(obj)
% function mibSegmFavToolCheck_Callback(obj)
% callback to the obj.mibView.handles.mibSegmFavToolCheck, to add the
% selected tool to the list of favourites
%
% Parameters:
%
% Return values:
% 

% Copyright (C) 11.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

toolId = obj.mibView.handles.mibSegmentationToolPopup.Value;
favId = obj.mibView.handles.mibSegmFavToolCheck.Value;

if favId == 1 % add the selected tool to the list of fast access tools
    obj.mibModel.preferences.lastSegmTool(end+1) = toolId;
    obj.mibView.handles.mibSegmentationToolPopup.BackgroundColor = [1 .69 .39];
else    % remove the selected tool to the list of fast access tools
    pos = obj.mibModel.preferences.lastSegmTool(find(obj.mibModel.preferences.lastSegmTool == toolId, 1));
    obj.mibModel.preferences.lastSegmTool = obj.mibModel.preferences.lastSegmTool(obj.mibModel.preferences.lastSegmTool ~= pos);
    obj.mibView.handles.mibSegmentationToolPopup.BackgroundColor = [1 1 1];
end
obj.mibModel.preferences.lastSegmTool = sort(obj.mibModel.preferences.lastSegmTool);
end