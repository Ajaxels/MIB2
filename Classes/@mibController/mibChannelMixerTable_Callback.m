function mibChannelMixerTable_Callback(obj, type)
% function mibChannelMixerTable_Callback(obj, type)
% a callback for the context menu of obj.mibView.handles.mibChannelMixerTable
%
% Parameters:
% type: a string with one of the possible options
% ''Insert empty channel'' - insert color channel
% ''Copy channel'' - copy one color channel to another
% ''Invert channel'' - invert color channel
% ''Rotate channel'' - rotate color channel
% ''Swap channels'' - swap two color channels
% ''Delete channel'' - delete color channel
% ''set color'' - set LUT color for the channel
%
% Return values
%

% Copyright (C) 07.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 26.05.2019, updated for the batch mode

% check for the virtual stacking mode and return
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1 && ~ismember(type, {'set color'})
    toolname = 'Actions with color channels are';
    warndlg(sprintf('!!! Warning !!!\n\n%s not available in the virtual stacking mode!\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

if isempty(obj.mibView.handles.mibChannelMixerTable.UserData)
    errordlg(sprintf('The color channel was not selected!\n\nPlease select it in the View Settings->Colors table with the left mouse button and try again.'),'Wrong selection');
    return;
end
rawId = obj.mibView.handles.mibChannelMixerTable.UserData;
if size(rawId,1) > 1 && ~strcmp(type, 'Delete channel')
    errordlg(sprintf('Multiple color channels are selected!\n\nPlease select only one channel in the View Settings->Colors table with the left mouse button and try again.'), 'Wrong selection');
    return;
end

rawId_first = rawId(1,1);
if strcmp(type, 'set color')
    Indices = [rawId_first, 3];
    obj.mibChannelMixerTable_CellSelectionCallback(Indices);
else
    obj.mibModel.colorChannelActions(type, rawId_first);
end

end