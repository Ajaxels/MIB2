function menuModelsRender_Callback(obj, type)
% function menuModelsRender_Callback(obj, type)
% a callback to MIB->Menu->Models->Render model...
%
% Parameters:
% type: a string with desired rendering engine
% @li ''matlab'' - Matlab rendering
% @li ''matlabImaris'' - render model in Matlab and export the rendered
% @li ''volviewer'' - render model in Matlab Volume Viewer application (only for Matlab version of MIB)
% surface to Imaris
% @li ''fiji'' - Fiji rendering
% @li ''imaris'' - Imaris rendering, i.e. send first a model as a volume and use Imaris to generate the surface

% Copyright (C) 11.01.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 28.03.2018, IB, added rendering using Matlab volume viewer

% check for the virtual stacking mode and return
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    toolname = 'models are';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

if nargin < 2; type = 'matlab'; end

switch type
    case 'mib'
        contIndex = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
        modelMaterialNames = obj.mibModel.getImageProperty('modelMaterialNames');
        if contIndex < 0
            textStr = 'Mask';
        elseif contIndex == 0
            textStr = 'Exterior';
        else
            textStr = modelMaterialNames{contIndex};
        end
        
        answer = questdlg(sprintf('!!! Attention !!!\n\nThe volume rendering will display a material selected in the Segmentation table!\nCurrent selection is "%s"', textStr),...
            'Warning', 'Continue', 'Cancel', 'Continue');
        if strcmp(answer, 'Cancel'); return; end
        obj.mibSegmentationTable_cm_Callback([], 'mib');
    case 'matlab'
        obj.mibSegmentationTable_cm_Callback([], 'isosurface');
    case 'matlabImaris'
        obj.mibSegmentationTable_cm_Callback([], 'isosurface2imaris');
    case 'volviewer'
        if isdeployed
            errordlg(sprintf('!!! Error !!!\n\nRendering in Matlab VolumeViewer app is only available for the Matlab version of MIB'), 'Not available');
            return;
        end
        if obj.mibModel.showAllMaterials == 1    % all materials
            materialIndex = NaN;
        else
            materialIndex = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
        end
        img = cell2mat(obj.mibModel.getData3D('model', NaN, 4, materialIndex));
        if obj.matlabVersion >= 9.6
            % % Labels only is not compatible with the scale factor
            %answer = questdlg(sprintf('Would you like to have the volume exported together with the model?'), ...
            %        'Include volume', 'Volume with model', 'Only model', 'Cancel', 'Only model');
            %if strcmp(answer, 'Cancel'); return; end
            
            %if strcmp(answer, 'Only model')
            %    volumeViewer(squeeze(img), 'VolumeType', 'Labels', 'ScaleFactors', [obj.mibModel.I{obj.mibModel.Id}.pixSize.x obj.mibModel.I{obj.mibModel.Id}.pixSize.y obj.mibModel.I{obj.mibModel.Id}.pixSize.z]);
            %else
            
            res = questdlg('Would you like to export the model as a volume for volume rendering or as materials together with the original dataset?', ...
                'Render model', 'As Volume', 'As materials', 'Cancel', 'As volume');
            if strcmp(res, 'Cancel'); return; end
            
            if strcmp(res, 'As Volume')
                tform = zeros(4);
                tform(1,1) = obj.mibModel.I{obj.mibModel.Id}.pixSize.x;
                tform(2,2) = obj.mibModel.I{obj.mibModel.Id}.pixSize.y;
                tform(3,3) = obj.mibModel.I{obj.mibModel.Id}.pixSize.z;
                tform(4,4) = 1;
                volumeViewer(img, tform);
            else
                Volume = cell2mat(obj.mibModel.getData3D('image', NaN, 4));
                if size(Volume, 3) > 1
                    errordlg(sprintf('!!! Error !!!\n\nVolume viewer is not compatible with multicolor images;\nplease keep only a single color channel displayed and try again!'), 'Not implemented');
                    return;
                end

                volumeViewer(squeeze(Volume), img, 'ScaleFactors', [obj.mibModel.I{obj.mibModel.Id}.pixSize.x obj.mibModel.I{obj.mibModel.Id}.pixSize.y obj.mibModel.I{obj.mibModel.Id}.pixSize.z]);
            end
        elseif obj.matlabVersion >= 9.4
            tform = zeros(4);
            tform(1,1) = obj.mibModel.I{obj.mibModel.Id}.pixSize.x;
            tform(2,2) = obj.mibModel.I{obj.mibModel.Id}.pixSize.y;
            tform(3,3) = obj.mibModel.I{obj.mibModel.Id}.pixSize.z;
            tform(4,4) = 1;
            volumeViewer(img, tform);
        else
            volumeViewer(img);
        end
    case 'fiji'
        obj.mibSegmentationTable_cm_Callback([], 'volumeFiji');
    case 'imaris'
        % define index of material to model, NaN - model all
        if obj.mibModel.showAllMaterials == 1    % all materials
            options.materialIndex = 0;
        else
            options.materialIndex = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
        end
        
        obj.mibModel.connImaris = mibRenderModelImaris(obj.mibModel.I{obj.mibModel.Id}, obj.mibModel.connImaris, options);
end