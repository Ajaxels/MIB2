% --- Executes on button press in maskShowCheck.
function mibChannelMixerTable_Callback(obj, type)
% function mibChannelMixerTable_Callback(obj, type)
% a callback for the context menu of obj.mibView.handles.mibChannelMixerTable
%
% Parameters:
% 
% Return values:
%

% Copyright (C) 07.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if isempty(obj.mibView.handles.mibChannelMixerTable.UserData)
    errordlg(sprintf('The color channel was not selected!\n\nPlease select it in the View Settings->Colors table with the left mouse button and try again.'),'Wrong selection');
    return;
end
rawId = obj.mibView.handles.mibChannelMixerTable.UserData;
if size(rawId,1) > 1 && ~strcmp(type, 'delete')
    errordlg(sprintf('Multiple color channels are selected!\n\nPlease select only one channel in the View Settings->Colors table with the left mouse button and try again.'), 'Wrong selection');
    return;
end

obj.mibModel.mibDoBackup('image', 1);

rawId_first = rawId(1,1);
switch type
    case 'insert'
        obj.mibModel.I{obj.mibModel.Id}.insertEmptyColorChannel(rawId_first+1);
        obj.updateGuiWidgets();
        obj.plotImage(1);
    case 'copy'
        obj.mibModel.I{obj.mibModel.Id}.copyColorChannel(rawId_first);
        obj.updateGuiWidgets();
        obj.plotImage(1);
    case 'rotate'
        % rotate specified color channel
        %if obj.mibModel.getImageProperty('time') < 2; obj.mibModel.mibDoBackup('image', 1); end;
        obj.mibModel.I{obj.mibModel.Id}.rotateColorChannel(rawId_first);
        obj.plotImage(1);
    case 'invert'
        % invert specified color channel
        % if obj.mibModel.getImageProperty('time') < 2; obj.mibModel.mibDoBackup('image', 1); end;
        obj.mibModel.I{obj.mibModel.Id}.invertColorChannel(rawId_first);
        obj.plotImage(1);
    case 'swap'
        % if obj.mibModel.getImageProperty('time') < 2; obj.mibModel.mibDoBackup('image', 1); end;
        obj.mibModel.I{obj.mibModel.Id}.swapColorChannels(rawId_first);
        obj.plotImage(1);
    case 'delete'
        rawId = rawId(:,1);
        obj.mibModel.I{obj.mibModel.Id}.deleteColorChannel(rawId);
        obj.updateGuiWidgets();
        obj.plotImage(1);
    case 'set color'
        Indices = [rawId_first, 3];
        obj.mibChannelMixerTable_CellSelectionCallback(Indices);
end

end