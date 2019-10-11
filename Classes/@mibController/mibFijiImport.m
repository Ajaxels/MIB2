function mibFijiImport(obj)
% function mibFijiImport(obj)
%import dataset from Fiji to MIB
%
% Parameters:
% 
% Return values
%

% Copyright (C) 02.03.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

global mibPath;
% define type of the dataset
datasetTypeValue = obj.mibView.handles.mibFijiConnectTypePopup.Value;
datasetTypeList = obj.mibView.handles.mibFijiConnectTypePopup.String;
datasetType = datasetTypeList{datasetTypeValue};

% check for MIJ
if exist('MIJ','class') == 8
    if ~isempty(ij.gui.Toolbar.getInstance)
        ij_instance = char(ij.gui.Toolbar.getInstance.toString);
        % -> ij.gui.Toolbar[canvas1,3,41,548x27,invalid]
        if numel(strfind(ij_instance, 'invalid')) > 0    % instance already exist, but not shown
            Miji_wrapper(true);     % wrapper to Miji.m file
        end
    else
        Miji_wrapper(true);     % wrapper to Miji.m file
    end
else
   Miji_wrapper(true);     % wrapper to Miji.m file
end

datasetName = mibFijiSelectDataset();
if isnan(datasetName); return; end

% check for the virtual stacking mode and disable it
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    if ismember(datasetType, {'model','mask','selection'})
        toolname = datasetType;
        warndlg(sprintf('!!! Warning !!!\n\nIt is not yet possible to import %s in the virtual stacking mode!\nPlease switch to the memory-resident mode and try again', ...
            toolname), 'Not implemented');
        return;
    end
    
    % this code is ok when started from mibController
    result = obj.toolbarVirtualMode_ClickedCallback(0);  % switch to the memory-resident mode
    if isempty(result) || result == 1; return; end
end

img = MIJ.getImage(datasetName);
minVal = double(min(min(min(min(img)))));
maxVal = double(max(max(max(max(img)))));
if ndims(img) == 4 
    img = permute(img, [1 2 4 3]);
end
if minVal < 0   % shift the dataset to the positive values
    img = double(img);
    for i=1:size(img,3)
        img(:,:,i,:) = img(:,:,i,:) - minVal;
    end
end
    
if maxVal-minVal < 256  % convert image to uint8
    img = uint8(img);
elseif maxVal-minVal < 65536
    img = uint16(img);
elseif maxVal-minVal < 4294967296    
    img = uint32(img);
else
    msgbox(sprintf('Dataset format problem!'),...
        'Problem!','error');
    return;
end

roiNo = obj.mibModel.I{obj.mibModel.Id}.selectedROI;
% cancel if more than one roi selected
if roiNo > -1 && numel(roiNo) > 1
    msgbox('Please select ROI from the ROI list or unselect the ROI mode!','Select ROI!','warn','modal');
    return;
end

options.blockModeSwitch = 0;
options.roiId = roiNo;

if strcmp(datasetType, 'image')
    if ndims(img) == 3 && size(img, 3) ~= 3
        img = reshape(img, size(img,1), size(img,2), 1, size(img,3));
    end
    if roiNo == -1
        obj.mibModel.I{obj.mibModel.Id}.clearContents(img, [], obj.mibModel.preferences.disableSelection);
        obj.mibModel.I{obj.mibModel.Id}.updatePixSizeResolution();    % update pixels size, and resolution
        obj.mibModel.I{obj.mibModel.Id}.meta('Filename') = datasetName;
        notify(obj.mibModel, 'newDataset');   % notify mibController about a new dataset; see function obj.Listner2_Callback for details
    else
        obj.mibModel.setData3D(datasetType, img, NaN, 4, NaN, options);
    end
else
    if roiNo == -1
        if size(img, 1) ~= obj.mibModel.I{obj.mibModel.Id}.height || ...
                size(img,2) ~= obj.mibModel.I{obj.mibModel.Id}.width || ...
                size(img,3) ~= obj.mibModel.I{obj.mibModel.Id}.depth
            msgbox(sprintf('Dimensions mismatch!\nImage (HxWxZ) = %d x %d x d pixels\nModel (HxWxZ) = %d x %d x d pixels',...
                obj.mibModel.I{obj.mibModel.Id}.height, obj.mibModel.I{obj.mibModel.Id}.width, obj.mibModel.I{obj.mibModel.Id}.depth,...
                size(img,1), size(img,2), size(img,3)), 'Error!', 'error', 'modal');
            return;
        end
    end
    if strcmp(datasetType, 'model')
        if roiNo == -1
            obj.mibModel.createModel();
            obj.mibModel.setData3D('model', img, NaN, 4, NaN, options);
            % update modelMaterialNames
            for i=1:maxVal-minVal
                obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames(i,1) = cellstr(num2str(i));
            end
        else
            obj.mibModel.setData3D(datasetType, img, NaN, 4, NaN, options);
        end
        eventdata = ToggleEventData(1);   % show the model checkbox on
        notify(obj.mibModel, 'showModel', eventdata);
    elseif strcmp(datasetType, 'mask')
        img(img>1) = 1;     % convert to 0-1 range
        if roiNo == -1
            obj.mibModel.clearMask();
            obj.mibModel.setData3D(datasetType, img, NaN, 4, NaN, options);
        else
            obj.mibModel.setData3D(datasetType, img, NaN, 4, NaN, options);
        end
        obj.mibView.handles.mibMaskShowCheck.Value = 1;
        obj.mibMaskShowCheck_Callback();
    elseif strcmp(datasetType, 'selection')
        img(img>1) = 1;     % convert to 0-1 range
        obj.mibModel.setData3D(datasetType, img, NaN, 4, NaN, options);
    end
end
notify(obj.mibModel, 'plotImage');
end
