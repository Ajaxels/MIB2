% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function mibRoiRemoveBtn_Callback(obj)
% function mibRoiRemoveBtn_Callback(obj)
% a callback to obj.mibView.handles.mibRoiRemoveBtn, remore selected ROI
%
% Parameters:
% 
% Return values:
% 

% Updates
% 

% Remove selected ROI
roiString = obj.mibView.handles.mibRoiList.String;
roiValue = obj.mibView.handles.mibRoiList.Value;
currentVal = roiString{roiValue};

index = obj.mibModel.I{obj.mibModel.Id}.hROI.findIndexByLabel(currentVal);
if roiValue == 1 
    button = questdlg(sprintf('!!! Warning !!!\nYou are going to delete all ROIs\nAre you sure?'), 'Delete ROIs!', 'Delete', 'Cancel', 'Cancel');
    if strcmp(button, 'Cancel'); return; end;
else
    button = questdlg(sprintf('You are going to delete\nROI region with label "%s"\nAre you sure?', ...
        cell2mat(obj.mibModel.I{obj.mibModel.Id}.hROI.Data(index).label)), 'Delete ROIs!', 'Delete', 'Cancel', 'Cancel');
    if strcmp(button, 'Cancel'); return; end;
end
obj.mibView.handles.mibRoiList.Value = 1;
obj.mibModel.I{obj.mibModel.Id}.hROI.removeROI(index);

% update roiList
[number, indices] = obj.mibModel.I{obj.mibModel.Id}.hROI.getNumberOfROI();
str2 = cell([number+1 1]);
str2(1) = cellstr('All');
for i=1:number
    %    str2(i+1) = cellstr(num2str(indices(i)));
    str2(i+1) = obj.mibModel.I{obj.mibModel.Id}.hROI.Data(indices(i)).label;
end
obj.mibView.handles.mibRoiList.String = str2;

%obj.mibView.handles.mibRoiList.Value = 1;
if obj.mibModel.I{obj.mibModel.Id}.hROI.getNumberOfROI(0) == 0; obj.mibView.handles.mibRoiShowCheck.Value = 0; end;
obj.mibRoiShowCheck_Callback();
end
