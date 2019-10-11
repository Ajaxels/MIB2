function result = updatePixSizeResolution(obj, pixSize)
% function result = updatePixSizeResolution(obj, pixSize)
% Update mibImage.pixelSize, mibImage.meta(''XResolution'') and
% mibImage.meta(''XResolution'') and mibImage.volren
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
% obj.mibModel.I{obj.mibModel.Id}.updatePixSizeResolution(pixSize);  // call from mibController, update parameters using voxels: 10x10x50nm in size 
% @endcode
% @code obj.mibModel.I{obj.mibModel.Id}.updatePixSizeResolution();  // call from mibController, update parameters of the dataset @endcode

% Copyright (C) 20.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 26.03.2019 moved to mibImage class from mibModel and renamed from updateParameters

result = 0;
global mibPath;

if nargin < 2
    prompts = {'Voxel size, X:'; 'Voxel size, Y:'; 'Voxel size, Z:'; 'Time between frames:'; 'Pixel units (m, cm, mm, um, nm):'; 'Time units:'};
    dlg_title = 'Dataset parameters';
    
    % generate the list of possible units and detect current one
    unitsList = {'m'; 'cm'; 'mm'; 'um'; 'nm'};  % make a list of possible units 
    unitsList{end+1} = find(ismember(unitsList, obj.pixSize.units)==1);   % find the current unit in the list
     
    defaultAns = {sprintf('%g', obj.pixSize.x),...
                  sprintf('%g', obj.pixSize.y),...
                  sprintf('%g', obj.pixSize.z),...
                  sprintf('%g', obj.pixSize.t),...
                  unitsList, obj.pixSize.tunits};
    dlgOptions.WindowStyle = 'normal';
    answer = mibInputMultiDlg({mibPath}, prompts, defaultAns, dlg_title, dlgOptions);
    if isempty(answer); return; end

    obj.pixSize.x = str2double(answer{1});
    obj.pixSize.y = str2double(answer{2});
    obj.pixSize.z = str2double(answer{3});
    obj.pixSize.t = str2double(answer{4});
    obj.pixSize.units = answer{5};
    obj.pixSize.tunits = answer{6};
else
    if isfield(pixSize, 'x'); obj.pixSize.x = pixSize.x; end
    if isfield(pixSize, 'y'); obj.pixSize.y = pixSize.y; end
    if isfield(pixSize, 'z'); obj.pixSize.z = pixSize.z; end
    if isfield(pixSize, 't'); obj.pixSize.t = pixSize.t; end
    if isfield(pixSize, 'units'); obj.pixSize.units = pixSize.units; end
    if isfield(pixSize, 'tunits'); obj.pixSize.tunits = pixSize.tunits; end
end
    
resolution = mibCalculateResolution(obj.pixSize);
obj.meta('XResolution') = resolution(1);
obj.meta('YResolution') = resolution(2);
obj.meta('ResolutionUnit') = 'Inch';
obj.updateBoundingBox();

magFactor =  obj.magFactor;
pixSize = obj.pixSize;

R = [0 0 0];
S = [1*magFactor,...
     1*magFactor,...
     1*pixSize.x/pixSize.z*magFactor];  
T = [0 0 0];
obj.volren.viewer_matrix = makeViewMatrix(R, S, T);
result = 1;
end
