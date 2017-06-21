function mibRoiList_cm_Callback(obj, parameter)
% function mibRoiList_cm_Callback(obj, parameter)
% a callback for obj.mibView.handles.mibRoiList context menu
%
% Parameters:
% parameter: a string with selected action
% - @li ''rename'' - rename ROI
% - @li ''edit'' - modify ROI
% - @li ''remove'' - remove ROI
% 
% Return values:
% 

% Copyright (C) 13.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

global mibPath;

roiString = obj.mibView.handles.mibRoiList.String;
roiValue = obj.mibView.handles.mibRoiList.Value;
currentVal = roiString{roiValue};

if roiValue == 1; return; end;

index = obj.mibModel.I{obj.mibModel.Id}.hROI.findIndexByLabel(currentVal);

switch parameter
    case 'rename'  % set brightness on the screen to be the same as in the image
        answer = mibInputDlg({mibPath}, sprintf('Please add a new name for selected ROI:'), 'Rename ROI', currentVal);
        if isempty(answer); return; end;
        
        if sum(ismember([obj.mibModel.I{obj.mibModel.Id}.hROI.Data.label], answer))
            errordlg(sprintf('!!! Error !!!\n\nThe names for ROIs should be unique;\nPlease try another name!'));
            return;
        end
        
        obj.mibModel.I{obj.mibModel.Id}.hROI.Data(index).label = answer;
        
        % update roiList
        [number, indices] = obj.mibModel.I{obj.mibModel.Id}.hROI.getNumberOfROI();
        str2 = cell([number+1 1]);
        str2(1) = cellstr('All');
        for i=1:number
            %    str2(i+1) = cellstr(num2str(indices(i)));
            str2(i+1) = obj.mibModel.I{obj.mibModel.Id}.hROI.Data(indices(i)).label;
        end
        obj.mibView.handles.mibRoiList.String = str2;
    case 'edit'
        unFocus(obj.mibView.handles.mibRoiList);
        obj.mibModel.I{obj.mibModel.Id}.hROI.addROI(obj, [], index);
    case 'remove'
        obj.mibRoiRemoveBtn_Callback();
        notify(obj.mibModel, 'updateROI');  % notify mibModel about update of ROIs
end
obj.plotImage(0);
end
