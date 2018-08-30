function newMode = toolbarVirtualMode_ClickedCallback(obj, options)
% function newMode = toolbarVirtualMode_ClickedCallback(obj, options)
% Function to switch between loading datasets to memory or reading them
% from HDD on demand
%
% When the ''options'' variable is omitted the function works as a standard
% callback and changes the image loading mode: memory or hdd
% However, when ''options'' are specified the function sets the state of
% the button to the currently selected type.
%
% Parameters:
% options: [@em optional], 
% @li when @b ''keepcurrent'' set the state of the button to the currently
% selected in mibImage.Virtual.virtual
% @li when @b 0 - uses the memory-resident mode, i.e. when the images loaded to memory
% @li when @b 1 - uses the HDD-resident mode (virtual stacking), i.e. when the images kept on a hard drive
%
% Return values:
% newMode: result of the function,
% @li [] - nothing was changed
% @li 0 - switched to the memory-resident mode
% @li 1 - switched to the virtual stacking mode
%
%| @b Examples:
% @code obj.toolbarVirtualMode_ClickedCallback();     // call from mibController; switch the mode @endcode

% Copyright (C) 30.07.2018, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
%
global mibPath;

if nargin == 2  % when options are available
    if strcmp(options, 'keepcurrent')
        newMode = [];
    else
        newMode = options;
    end
else
    newMode = abs(obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual-1);
end

% toggle the virtual switch
if ~isempty(newMode)
    newMode = obj.mibModel.I{obj.mibModel.Id}.switchVirtualStackingMode(newMode, obj.mibModel.preferences.disableSelection);
    obj.mibModel.I{obj.mibModel.Id}.clearContents();
    eventdata = ToggleEventData(obj.mibModel.Id);
    notify(obj.mibModel, 'newDataset', eventdata);
    obj.plotImage(1);
end

if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    % fprintf('Virtual mode is enabled\n');
    filename = 'hdd.res';
    %obj.mibModel.disableSegmentation = 1;
    obj.mibView.handles.toolbarInterpolation.TooltipString = 'The virtual stacking mode is enabled';
elseif obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 0
    % fprintf('Virtual mode is disabled\n');  
    filename = 'chip.res';
    obj.mibView.handles.toolbarInterpolation.TooltipString = 'The virtual stacking mode is disabled';
    %obj.mibModel.disableSegmentation = 0;
end

img = load(fullfile(mibPath, 'Resources', filename), '-mat');  % load icon
obj.mibView.handles.toolbarVirtualMode.CData = img.image;
end

