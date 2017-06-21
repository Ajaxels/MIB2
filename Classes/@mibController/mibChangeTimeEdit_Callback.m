function mibChangeTimeEdit_Callback(obj, parameter)
% function mibChangeTimeEdit_Callback(obj, parameter)
% A callback for changing the time points of the dataset by entering a new time value
% 
% Parameters:
% parameter: [@b optional], when provided:
% @li 0 - set dataset to the last slice, used as a callback for mibView.mibLastSliceBtn
% @li 1 - set dataset to the first slice, used as a callback for mibView.mibFirstSliceBtn
%
% Return values:
%

% Copyright (C) 04.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 2
    val = str2double(obj.mibView.handles.mibChangeTimeEdit.String);
    status = obj.mibView.editbox_Callback(obj.mibView.handles.mibChangeTimeEdit,...
        'pint',1,[1 obj.mibModel.I{obj.mibModel.Id}.time]);
    if status == 0; return; end;
else
    maxTime = obj.mibModel.I{obj.mibModel.Id}.time;
    if parameter == 0
        val = maxTime;
    elseif parameter > maxTime
        val = maxTime;
    elseif parameter < 0
        val = 1;
    else
        val = parameter;
    end
    obj.mibView.handles.mibChangeTimeEdit.String = num2str(val);
end
obj.mibView.handles.mibChangeTimeSlider.Value = val;
obj.mibChangeTimeSlider_Callback();
end