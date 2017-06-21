function result = updateParameters(obj, pixSize)
% function result = updateParameters(obj, pixSize)
% Update mibImage.pixelSize, mibImage.meta(''XResolution'') and
% mibImage.meta(''XResolution'') and mibView.volren
%
% The function starts a dialog to update voxel size and the units of the dataset. As result the voxel dimensions will be updated;
% in addition mibImage.meta(''XResolution'') and mibImage.meta(''YResolution'') keys will be recalculated.
%
% Parameters:
% pixSize: - [@e optional], a structure with new parameters, may have the following fields
% - @b .x - physical voxel size in X, a number
% - @b .y - physical voxel size in Y, a number
% - @b .z - physical voxel size in Z, a number 
% - @b .t - time difference between the frames, a number 
% - @b .units - physical units for voxels, (m, cm, mm, um, nm)
% - @b .tunits - time unit 

% Return values:
% result: @b 1 - success, @b 0 - cancel

%| 
% @b Examples:
% @code
% pixSize.x = 10;
% pixSize.y = 10;
% pixSize.z = 50;
% pixSize.units = 'nm';
% obj.mibModel.updateParameters(pixSize);  // call from mibController, update parameters using voxels: 10x10x50nm in size @endcode
% @endcode
% @code obj.mibModel.obj.updateParameters();  // call from mibController, update parameters of the dataset @endcode

% Copyright (C) 20.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

result = 0;

if nargin < 2
    prompt = {'Voxel size, X:','Voxel size, Y:','Voxel size, Z:','Time between frames:','Pixel units (m, cm, mm, um, nm):','Time units:'};
    title = 'Dataset parameters';
    lines = [1 30];
    def = {sprintf('%g',obj.I{obj.Id}.pixSize.x),...
        sprintf('%g',obj.I{obj.Id}.pixSize.y),...
        sprintf('%g',obj.I{obj.Id}.pixSize.z),...
        sprintf('%g',obj.I{obj.Id}.pixSize.t),...
        obj.I{obj.Id}.pixSize.units,...
        obj.I{obj.Id}.pixSize.tunits};
    dlgOptions.Resize = 'on';
    dlgOptions.WindowStyle = 'normal';
    answer = inputdlg(prompt,title,lines,def,dlgOptions);
    if size(answer) == 0; return; end;

    obj.I{obj.Id}.pixSize.x = str2double(answer{1});
    obj.I{obj.Id}.pixSize.y = str2double(answer{2});
    obj.I{obj.Id}.pixSize.z = str2double(answer{3});
    obj.I{obj.Id}.pixSize.t = str2double(answer{4});
    obj.I{obj.Id}.pixSize.units = answer{5};
    obj.I{obj.Id}.pixSize.tunits = answer{6};
else
    if isfield(pixSize, 'x'); obj.I{obj.Id}.pixSize.x = pixSize.x; end;
    if isfield(pixSize, 'y'); obj.I{obj.Id}.pixSize.y = pixSize.y; end;
    if isfield(pixSize, 'z'); obj.I{obj.Id}.pixSize.z = pixSize.z; end;
    if isfield(pixSize, 't'); obj.I{obj.Id}.pixSize.t = pixSize.t; end;
    if isfield(pixSize, 'units'); obj.I{obj.Id}.pixSize.units = pixSize.units; end;
    if isfield(pixSize, 'tunits'); obj.I{obj.Id}.pixSize.tunits = pixSize.tunits; end;
end
    
resolution = mibCalculateResolution(obj.I{obj.Id}.pixSize);
obj.I{obj.Id}.meta('XResolution') = resolution(1);
obj.I{obj.Id}.meta('YResolution') = resolution(2);
obj.I{obj.Id}.meta('ResolutionUnit') = 'Inch';
obj.I{obj.Id}.updateBoundingBox();

magFactor =  obj.getMagFactor();
pixSize = obj.getImageProperty('pixSize');

R = [0 0 0];
S = [1*magFactor,...
     1*magFactor,...
     1*pixSize.x/pixSize.z*magFactor];  
T = [0 0 0];
obj.I{obj.Id}.volren.viewer_matrix = makeViewMatrix(R, S, T);
result = 1;
end
