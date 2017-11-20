% --- Executes on key release with focus on im_browser or any of its controls.
function mibGUI_WindowKeyPressFcn_BrushSuperpixel(obj, eventdata)
% function mibGUI_WindowKeyPressFcn_BrushSuperpixel(obj, eventdata)
% a function to check key callbacks when using the Brush in the Superpixel mode
%
% Parameters:
% eventdata:  structure with the following fields (see FIGURE)
%	Key -> name of the key that was released, in lower case
%	Character -> character interpretation of the key(s) that was released
%	Modifier -> name(s) of the modifier key(s) (i.e., control, shift) released

% Copyright (C) 15.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

% return when editing the edit boxes
%if strcmp(get(get(hObject,'CurrentObject'),'style'), 'edit'); return; end;

char=eventdata.Key;
if strcmp(char, 'alt'); return; end
modifier = eventdata.Modifier;

% find a shortcut action
controlSw = 0;
shiftSw = 0;
altSw = 0;
if ismember('control', modifier); controlSw = 1; end
if ismember('shift', modifier) 
    if ismember(char, obj.mibModel.preferences.KeyShortcuts.Key(6:16))   % override the Shift state for actions that work for all slices
        shiftSw = 0;  
    else
        shiftSw = 1; 
    end
end
if ismember('alt', modifier); altSw = 1; end
ActionId = ismember(obj.mibModel.preferences.KeyShortcuts.Key, char) & ismember(obj.mibModel.preferences.KeyShortcuts.control, controlSw) & ...
    ismember(obj.mibModel.preferences.KeyShortcuts.shift, shiftSw) & ismember(obj.mibModel.preferences.KeyShortcuts.alt, altSw);
ActionId = find(ActionId>0);    % action id is the index of the action, obj.mibModel.preferences.KeyShortcuts.Action(ActionId)

if ~isempty(ActionId) % find in the list of existing shortcuts
    switch obj.mibModel.preferences.KeyShortcuts.Action{ActionId}
        case 'Undo/Redo last action'
            if numel(obj.mibView.brushSelection{2}.selectedSlicIndices) == 0
                return;
            end
            removeId = obj.mibView.brushSelection{2}.selectedSlicIndices(end);
            obj.mibView.brushSelection{2}.selectedSlicIndices(end) = [];
            obj.mibView.brushSelection{2}.selectedSlic(obj.mibView.brushSelection{2}.slic == removeId) = 0;
            
            CData = obj.mibView.brushSelection{2}.CData;
            CData(obj.mibView.brushSelection{2}.selectedSlic==1) = intmax(class(obj.mibView.Ishown))*.4;
            obj.mibView.imh.CData = CData;
    end
end
end  % ------ end of im_browser_WindowKeyPressFcn_BrushSuperpixel
