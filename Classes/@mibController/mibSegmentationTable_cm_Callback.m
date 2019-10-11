function mibSegmentationTable_cm_Callback(obj, hObject, type)
% function mibSegmentationTable_cm_Callback(obj, hObject, type)
% a callback to the context menu of mibView.handles.mibSegmentationTable
%
% Parameters:
% hObject: handle of the selected menu entry
% type: a string with parameters for the function
% @li ''showselected'' - toggle display of selected/all materials
% @li ''rename'' - Rename material
% @li ''set color'' - Set color of the selected material
% @li ''statistics'' - Get statistics for material
% @li ''mib'' - render as volume, R2018b and newer
% @li ''isosurface'' - Show isosurface (Matlab)
% @li ''isosurface2imaris'' - render isosurface in Matlab and export to Imaris
% @li ''volumeFiji'' - Show as volume (Fiji)

% Copyright (C) 29.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

global mibPath; % path to mib installation folder

switch type
    case 'showselected'
        obj.mibModel.showAllMaterials = 1 - obj.mibModel.showAllMaterials;    % invert the showAll toggle status
        obj.updateSegmentationTable();
        if obj.mibModel.showAllMaterials == 0
            hObject.Checked = 'on';
        else
            hObject.Checked = 'off';
        end
    case 'rename'
        contIndex = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial - 2;   % do not change to obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex() here!
        if contIndex < 1; return; end  % do not rename Mask/Exterior
        segmList = obj.mibModel.getImageProperty('modelMaterialNames');
        answer = mibInputDlg({mibPath}, sprintf('Please add a new name for this material:'), 'Rename material', segmList{contIndex});
        if ~isempty(answer)
            if obj.mibModel.I{obj.mibModel.Id}.modelType > 255
                materialId = round(str2double(answer{1}));
                if isnan(materialId); errordlg(sprintf('!!! Error !!!\n\nWrong material index\nWhen worlPlease enter a number!'), 'Wrong material index', 'modal'); return; end;
            end
            segmList(contIndex) = answer(1);
            obj.mibModel.setImageProperty('modelMaterialNames', segmList);
            obj.updateSegmentationTable();
        end
    case 'set color'
        contIndex = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial;
        if contIndex == 1   % set color for the mask layer
            c =  uisetcolor(obj.mibModel.preferences.maskcolor, 'Set color for Mask');
            if length(c) ~= 1
                obj.mibModel.preferences.maskcolor = c;
            end
        elseif contIndex > 2    % set color for the selected material
            figTitle = ['Set color for ' obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{contIndex-2}];
            c =  uisetcolor(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(contIndex-2,:), figTitle);
            if length(c) ~= 1
                obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(contIndex-2,:) = c;
            end
        end
        obj.updateSegmentationTable();
    case 'statistics'
        obj.startController('mibStatisticsController');
    case {'isosurface', 'isosurface2imaris'}
        contIndex = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
        
        options.fillBg = 0;
        if obj.mibView.getRoiSwitch == 1; options.roiId = []; end
        
        [height, width] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions();
        % define parameters for rendering
        prompt = {'Reduce the volume down to, width pixels [no volume reduction when 0]?',...
            'Smoothing 3d kernel, width (no smoothing when 0):',...
            'Maximal number of faces (no limit when 0):',...
            'Show orthoslice (enter a number slice number, or NaN):'};
        if max([height, width]) > 500
            defAns = {'500','5','300000','1'};
        else
            defAns = {'0','5','300000','1'};
        end
        mibInputMultiDlgOpt.PromptLines = [2, 1, 1, 2];
        answer = mibInputMultiDlg({obj.mibPath}, prompt, defAns, 'Isosurface parameters', mibInputMultiDlgOpt);
        if isempty(answer); return; end
        
        Options.reduce = str2double(answer{1});
        Options.smooth = str2double(answer{2});
        Options.maxFaces = str2double(answer{3});
        Options.slice = str2double(answer{4});
        
        if contIndex == -1
            model = obj.mibModel.getData3D('mask', NaN, NaN, NaN, options);
            contIndex = 1;
            modelMaterialColors = obj.mibModel.preferences.maskcolor;
            Options.modelMaterialNames = {'Mask'};
        else
            Options.modelMaterialNames = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames;
            modelMaterialColors = obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors;
            
            if obj.mibModel.showAllMaterials == 1
                prompts = {sprintf('Specify indices of materials to be rendered\nkeep the field empty to render all materials\n(for example, 2,4,6:8)')};
                defAns = {num2str(contIndex)};
                dlgTitle = 'Select materials';
                dlgOptions.WindowStyle = 'modal';
                dlgOptions.PromptLines = 3;
                answer2 = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, dlgOptions);
                if isempty(answer2); return; end    
                if isempty(answer2{1})
                    contIndex = NaN;
                else
                    contIndex = str2num(answer2{1}); %#ok<ST2NM>
                end
            end
            
            model = obj.mibModel.getData3D('model', NaN, NaN, NaN, options);
            if numel(model) > 1
                msgbox(sprintf('!!! Error !!!\nPlease select which of ROIs you would like to render!'), 'Error!', 'error');
                return;
            end
        end
        
        getRGBOptions.mode = 'full';
        getRGBOptions.resize = 'no';
        
        getRGBOptions.sliceNo = Options.slice;
        if ~isnan(Options.slice)
            if Options.slice > obj.mibModel.getImageProperty('depth')
                getRGBOptions.sliceNo = obj.mibModel.getImageProperty('depth');
                Options.slice = obj.mibModel.getImageProperty('depth');
            else
                getRGBOptions.sliceNo = max([1 Options.slice]);
                Options.slice = max([1 Options.slice]);
            end
            image = obj.mibModel.getRGBimage(getRGBOptions);
        else
            image = NaN;
        end
        
        bb = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();  % get bounding box
        if strcmp(type, 'isosurface2imaris')
            Options.exportToImaris = 1;
        end
        
        mibRenderModel(model{1}, contIndex, obj.mibModel.I{obj.mibModel.Id}.pixSize, bb, modelMaterialColors, image, Options);
    case 'mib'
        if obj.matlabVersion < 9.5
            errordlg(sprintf('!!! Error !!!\n\nHardware accelerated rendering is only available in Matlab R2018b or newer!'), 'Matlab version is too old');
            return;
        end
        
        contIndex = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
        options.fillBg = 0;
        
        if isfield(obj.mibModel.sessionSettings, 'VolumeRendering')
            options.Settings = obj.mibModel.sessionSettings.VolumeRendering;
        end
        
        if contIndex == -1
            if obj.mibModel.I{obj.mibModel.Id}.maskExist == 0
                errordlg(sprintf('!!! Error !!!\n\nMask was not found!'), 'Missing mask');
                return;
            end
            options.dataType = 'mask';
            options.colorChannel = 1;
            options.Settings.IsoColor = obj.mibModel.preferences.maskcolor;
        else
            options.dataType = 'model';
            modelMaterialColors = obj.mibModel.getImageProperty('modelMaterialColors');
            if contIndex > 0
                options.Settings.IsoColor = modelMaterialColors(contIndex,:);
            end
        end
                
        options.mode = 'Isosurface'; % 'VolumeRendering', 'MaximumIntensityProjection', 'Isosurface'
        options.colorChannel = contIndex;
        
        obj.startController('mibVolRenController', options);
        
    case 'volumeFiji'
        contIndex = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
        options.fillBg = 0;
        
        if contIndex == -1
            model = obj.mibModel.getData3D('mask', NaN, NaN, NaN, options);
            contIndex = 1;
            modelMaterialColors = obj.mibModel.preferences.maskcolor;
        else
            model = obj.mibModel.getData3D('model', NaN, NaN, NaN, options);
            if obj.mibModel.showAllMaterials == 1; contIndex = 0; end      % show all materials
            modelMaterialColors = obj.mibModel.getImageProperty('modelMaterialColors');
        end
        
        if numel(model) > 1
            msgbox(sprintf('Error!\nPlease select a ROI to render!'),'Error!','error');
            return;
        end
        mibRenderModelFiji(model{1}, contIndex, obj.mibModel.I{obj.mibModel.Id}.pixSize, modelMaterialColors);
    case 'unlinkaddto'
        obj.mibView.handles.mibSegmentationTable.UserData.unlink = 1 - obj.mibView.handles.mibSegmentationTable.UserData.unlink;    % invert the unlink toggle status
        obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial;
        if obj.mibView.handles.mibSegmentationTable.UserData.unlink == 1
            hObject.Checked = 'on';
        else
            hObject.Checked = 'off';
        end
        obj.updateSegmentationTable();
end
obj.plotImage(0);
end