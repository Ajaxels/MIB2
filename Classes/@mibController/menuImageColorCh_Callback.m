function menuImageColorCh_Callback(obj, parameter)
% function menuImageColorCh_Callback(obj, parameter)
% callback to Menu->Image->Color Channels do actions with individual color channels
%
% Parameters:
% parameter: a string that defines image source:
% - 'Insert empty channel', insert an empty color channel to the specified position
% - 'Copy channel', copy color channel to a new position
% - 'Invert channel', invert color channel
% - 'Rotate channel', rotate color channel
% - 'Swap channels', swap two color channels
% - 'Delete channel', delete color channel from the dataset

% Copyright (C) 03.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 26.05.2019, updated for the batch mode

% check for the virtual stacking mode and close the controller
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    toolname = 'color channel actions';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s are not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

obj.mibModel.colorChannelActions(parameter);

end