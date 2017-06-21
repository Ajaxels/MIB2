function menuModelsRender_Callback(obj, type)
% function menuModelsRender_Callback(obj, type)
% a callback to MIB->Menu->Models->Render model...
%
% Parameters:
% type: a string with desired rendering engine
% @li ''matlab'' - Matlab rendering
% @li ''fiji'' - Fiji rendering
% @li ''imaris'' - Imaris rendering

% Copyright (C) 11.01.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

if nargin < 2; type = 'matlab'; end;

switch type
    case 'matlab'
        obj.mibSegmentationTable_cm_Callback([], 'isosurface');
    case 'fiji'
        obj.mibSegmentationTable_cm_Callback([], 'volumeFiji');
    case 'imaris'
        % define index of material to model, NaN - model all
        if obj.mibModel.showAllMaterials == 1    % all materials
            options.materialIndex = 0;
        else
            options.materialIndex = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial - 2;
        end
        
        obj.connImaris = mibRenderModelImaris(obj.mibModel.I{obj.mibModel.Id}, obj.connImaris, options);
end