function menuFileRenderFiji_Callback(obj)
% function menuFileRenderFiji_Callback(obj)
% a callback to MIB->Menu->File->Render volume (with Fiji)...
%
% Parameters:

% Copyright (C) 11.01.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

img = cell2mat(obj.mibModel.getData3D('image', NaN, 4));
mibRenderVolumeWithFiji(img, obj.mibModel.I{obj.mibModel.Id}.pixSize);

end