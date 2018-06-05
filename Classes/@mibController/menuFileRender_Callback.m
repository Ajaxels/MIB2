function menuFileRender_Callback(obj, parameter)
% function menuFileRender_Callback(obj, parameter)
% a callback to MIB->Menu->File->Render volume...
%
% Parameters:
% parameter: a char that specify where to render the volume
% @li 'fiji' - using Fiji 3D viewer
% @li 'volviewer' - using Matlab VolumeViewer application
%
% % @note VolumeViewer is available only for the Matlab version of MIB,
% requires Matlab R2017a or newer!

% Copyright (C) 11.01.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 25.03.2018, updated to use also Matlab volume viewer app, previously
% named as menuFileRenderFiji_Callback

img = cell2mat(obj.mibModel.getData3D('image', NaN, 4));
switch parameter
    case 'fiji'
        mibRenderVolumeWithFiji(img, obj.mibModel.I{obj.mibModel.Id}.pixSize);
    case 'volviewer'
        if obj.matlabVersion >= 9.4
            tform = zeros(4);
            tform(1,1) = obj.mibModel.I{obj.mibModel.Id}.pixSize.x;
            tform(2,2) = obj.mibModel.I{obj.mibModel.Id}.pixSize.y;
            tform(3,3) = obj.mibModel.I{obj.mibModel.Id}.pixSize.z;
            tform(4,4) = 1;
            volumeViewer(squeeze(img), tform);
        else
            volumeViewer(squeeze(img));
        end
end