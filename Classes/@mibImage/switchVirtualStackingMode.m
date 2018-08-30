function newMode = switchVirtualStackingMode(obj, newMode, disableSelection)
% function newMode = switchVirtualStackingMode(obj, newMode, disableSelection)
% Function to switch between loading datasets to memory or reading them
% from HDD on demand
%
% Parameters:
% newMode: [@em optional],
% @li when @b 0 - uses the memory-resident mode, i.e. when the images loaded to memory
% @li when @b 1 - uses the HDD-resident mode (virtual stacking), i.e. when the images kept on a hard drive
% disableSelection: [@em optional] a switch to set disableSelection based on mibModel.preferences
%
% Return values:
% newMode: result of the function,
% @li [] - nothing was changed
% @li 0 - switched to the memory-resident mode
% @li 1 - switched to the virtual stacking mode

%|
% @b Examples:
% @code result = obj.mibModel.I{obj.mibModel.Id}.switchVirtualStackingMode(1, obj.mibModel.preferences.disableSelection);  // enable the virtual stacking mode @endcode

% Copyright (C) 06.08.2018, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

if nargin < 3; disableSelection = []; end

if ~strcmp(obj.meta('Filename'), 'none.tif')
    if ~isempty(newMode) && newMode ~= obj.Virtual.virtual
        if newMode == 0
            fromMode = 'the HDD-resident';
            toMode = 'the memory-resident based';
        else
            fromMode = 'the memory-resident';
            toMode = 'the HDD-resident';
        end
        
        reply = questdlg(...
            sprintf('!!! Warning !!!\n\nYou are going to switch the mode from %s to %s.\nThe current dataset will be closed!', fromMode, toMode),...
            'Switch mode', 'Continue', 'Cancel', 'Cancel');
        if strcmp(reply, 'Cancel'); newMode = []; return; end
    end
end

% set the virtual mode switch
if ~isempty(newMode)
    obj.Virtual.virtual = newMode;
    if newMode == 1     % virtual
        obj.disableSelection = 1;  % turn off the selection layer for the virtual mode
    else
        % switch from virtual to the normal mode
        if ~isempty(disableSelection)
            obj.disableSelection = disableSelection;
        end
        obj.closeVirtualDataset();    % close the virtual datasets
    end
end
end