function mibColChannelCombo_Callback(obj)
% function mibColChannelCombo_Callback(obj)
% callback for modification of obj.View.handles.mibColorChannelCombo box
%
% Parameters:
% 

% Copyright (C) 10.03.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

val = obj.mibView.handles.mibColChannelCombo.Value - 1;
obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel = val;

end
