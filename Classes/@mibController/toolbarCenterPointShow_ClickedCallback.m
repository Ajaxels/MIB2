function toolbarCenterPointShow_ClickedCallback(obj)
% function toolbarCenterPointShow_ClickedCallback(obj)
% a callback for press of obj.mibView.toolbarCenterPointShow in the toolbar
% of MIB. Toggles display of a center point over the mibImageAxis
%
% Parameters:

% Copyright (C) 05.10.2018, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 
global mibPath;

if obj.matlabVersion < 9.5
    warndlg(sprintf('!!! Warning !!!\n\nThis feature requires MAtlab R2018b or newer'), 'Matlab version is too old');
    return; 
end

if strcmp(obj.mibView.handles.toolbarCenterPointShow.State, 'on')
    % enable the center spot
    obj.mibView.centerSpotHandle.enable = 1;
    
    if isempty(obj.mibView.centerSpotHandle.handle) || isvalid(obj.mibView.centerSpotHandle.handle) == 0
       obj.mibView.centerSpotHandle.handle = drawpoint('Position', [mean(obj.mibView.handles.mibImageAxes.XLim) mean(obj.mibView.handles.mibImageAxes.YLim)], ...
                'Deletable', false,...
                'parent', obj.mibView.handles.mibImageAxes,...
                'Color', 'y');
    end
    obj.mibView.centerSpotHandle.handle.Visible = 'on';
    filename = 'center_cross_on.res';
else
    % disable the spot
    obj.mibView.centerSpotHandle.enable = 0;
    obj.mibView.centerSpotHandle.handle.Visible = 'off';
    %delete(obj.mibView.centerSpotHandle.handle);
    %obj.mibView.centerSpotHandle.handle = [];
        filename = 'center_cross_off.res';
end
img = load(fullfile(mibPath, 'Resources', filename), '-mat');  % load icon
obj.mibView.handles.toolbarCenterPointShow.CData = img.image;
obj.plotImage();

