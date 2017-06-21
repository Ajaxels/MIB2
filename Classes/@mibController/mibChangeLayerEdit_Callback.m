function mibChangeLayerEdit_Callback(obj, parameter)
% function mibChangeLayerEdit_Callback(obj, parameter)
% A callback for changing the slices of the 3D dataset by entering a new slice number
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
    val = str2double(obj.mibView.handles.mibChangeLayerEdit.String);
    status = obj.mibView.editbox_Callback(obj.mibView.handles.mibChangeLayerEdit,...
        'pint',1,[1 size(obj.mibModel.I{obj.mibModel.Id}.img{1}, obj.mibModel.I{obj.mibModel.Id}.orientation)]);
    if status == 0; return; end;
else
    if obj.mibModel.I{obj.mibModel.Id}.orientation == 4   % xy
        maxVal = obj.mibModel.I{obj.mibModel.Id}.depth;
    elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 1   % xz
        maxVal = obj.mibModel.I{obj.mibModel.Id}.height;
    elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 2   % yz
        maxVal = obj.mibModel.I{obj.mibModel.Id}.width;
    end
    
    if parameter == 0
        val = maxVal;
    else
        if parameter > maxVal
            val = maxVal;
        elseif parameter < 0
            val = 1;
        else
            val = parameter;
        end
    end
    obj.mibView.handles.mibChangeLayerEdit.String = num2str(val);
end
obj.mibView.handles.mibChangeLayerSlider.Value = val;
obj.mibChangeLayerSlider_Callback();
end