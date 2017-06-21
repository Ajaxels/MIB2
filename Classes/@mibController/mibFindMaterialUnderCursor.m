function mibFindMaterialUnderCursor(obj)
% function mibFindMaterialUnderCursor(obj)
% find material under the mouse cursor, a callback for Ctrl+F key shortcut
%
% Parameters:
%

% Copyright (C) 21.04.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

%global mibPath; % path to mib installation folder

% cancel when model is not present
if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0; return; end

xyString = obj.mibView.handles.mibPixelInfoTxt2.String;
colon = strfind(xyString, ':');
bracket = strfind(xyString, '(');
x1 = str2double(xyString(1:colon(1)-1));
y1 = str2double(xyString(colon(1)+1:bracket(1)-1));
inImage = str2double(xyString(bracket+1));  % when inImage is a number the mouse cursor is above the image
inAxes = 1;
if xyString(1) == 'X'; inAxes = 0; end     % when inAxes is 1, the mouse cursor above the image axes

if isnan(inImage); return; end

z = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
switch obj.mibModel.I{obj.mibModel.Id}.orientation
    case 4  % yx
        x = x1;
        y = y1;
    case 1  % xz
        y = z;
        x = y1;
        z = x1;
    case 2  % yz
        x = z;
        y = y1;
        z = x1;
end
options.blockModeSwitch = 0;
options.y = [y y];
options.x = [x x];
materialIndex = cell2mat(obj.mibModel.getData2D('model', z, NaN, NaN, options));

if obj.mibModel.I{obj.mibModel.Id}.modelType < 256 
    %obj.mibModel.I{obj.mibModel.Id}.selectedMaterial = materialIndex+2;
    eventdata2.Indices = [materialIndex+2, 2];
else
    if materialIndex == 0
        eventdata2.Indices = [2, 2];
    else
        if obj.mibModel.I{obj.mibModel.Id}.selectedMaterial > 2
            obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{obj.mibModel.I{obj.mibModel.Id}.selectedMaterial-2} = num2str(materialIndex);
            eventdata2.Indices = [obj.mibModel.I{obj.mibModel.Id}.selectedMaterial, 2];
        else
            obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{1} = num2str(materialIndex);
            eventdata2.Indices = [3, 2];
        end
    end
end
obj.mibSegmentationTable_CellSelectionCallback(eventdata2);     % update mibSegmentationTable

% if obj.mibModel.I{obj.mibModel.Id}.orientation == 4 || isnan(inImage) %|| x < 1 || x > handles.Img{handles.Id}.I.no_stacks;
%     return;
% elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 1
%     obj.mibModel.I{obj.mibModel.Id}.current_yxz(2) = y;
%     obj.mibModel.I{obj.mibModel.Id}.current_yxz(3) = x;
% elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 2
%     obj.mibModel.I{obj.mibModel.Id}.current_yxz(1) = y;
%     obj.mibModel.I{obj.mibModel.Id}.current_yxz(3) = x;
% end

end