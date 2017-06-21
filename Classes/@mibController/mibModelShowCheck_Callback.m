function mibModelShowCheck_Callback(obj)
% function mibModelShowCheck_Callback(obj)
% callback to the mibGUI.handles.mibModelShowCheck to toggle the Model layer on/off
%
% Parameters:
% 
% Return values
%

% Copyright (C) 20.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 


if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0
    obj.mibView.handles.mibModelShowCheck.Value = 0;
    obj.mibModel.mibModelShowCheck = 0;
    return;
end
obj.mibModel.mibModelShowCheck = obj.mibView.handles.mibModelShowCheck.Value;
obj.mibModel.I{obj.mibModel.Id}.generateModelColors();
obj.plotImage(0);
end
