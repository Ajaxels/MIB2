function mibMaskGenerator(obj, type)
% function mibMaskGenerator(obj, type)
% generate the 'Mask' later
%
% Parameters:
% type: a type of the mask generator:
% - ''new'' - generate a new mask
% - ''add'' - generate mask and add it to the existing mask
%
% Return values:
% 

% Copyright (C) 02.03.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% check for the virtual stacking mode and return
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    toolname = 'mask generators are';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode!\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

tic
pos = obj.mibView.handles.mibMaskGenTypePopup.Value;
fulllist = obj.mibView.handles.mibMaskGenTypePopup.String;
text_str = fulllist{pos};
all_sw = obj.mibView.handles.mibMaskGenPanel2DAllRadio.Value;   % do for all slices
threeD = obj.mibView.handles.mibMaskGenPanel3DAllRadio.Value;   % do in 3D
selected_color = obj.mibView.handles.mibColChannelCombo.Value - 1;
if selected_color == 0 
    if obj.mibModel.getImageProperty('colors') == 1
        selected_color = 1;
    else
        msgbox(sprintf('Please select the color channel!\nUse the Color channel combobox in the Selection panel'), 'Error!', 'error', 'modal');
        return;
    end
end

outputType = 'mask';
if str2double(obj.mibView.handles.mibFrangiBWThreshold.String) == 0 && strcmp(text_str, 'Frangi filter')
    button = questdlg(sprintf('!!! Warning !!!\nThe result of the Frangi filter with the B/W Thresholding value == 0 is non-thresholded filtered image.\nThe current image will be removed!\n\nAre you sure?'),...
        'Update existing image!', 'Continue', 'Cancel', 'Cancel');
    if strcmp(button, 'Cancel')
        return;
    end
    outputType = 'image';
end

% set 2D mode when dataset has onle a single section
if obj.mibModel.getImageProperty('depth') == 1
    all_sw = 0;
    threeD = 0;
end
if threeD == 1; all_sw = 1; end     % use set the all_sw when using the 3D mode

if strcmp(outputType, 'image')
    obj.mibModel.mibDoBackup('image', all_sw);
else
    if obj.mibModel.getImageProperty('modelType') ~= 63
        if obj.mibModel.getImageProperty('maskExist') == 0 % preallocate memory for the mask
            obj.mibModel.I{obj.mibModel.Id}.maskImg{1} = zeros([obj.mibModel.I{obj.mibModel.Id}.height, obj.mibModel.I{obj.mibModel.Id}.width, ...
                obj.mibModel.I{obj.mibModel.Id}.depth, obj.mibModel.I{obj.mibModel.Id}.time], 'uint8');
        else
            obj.mibModel.mibDoBackup('mask', all_sw);
        end
    else
        obj.mibModel.mibDoBackup('everything', all_sw);
    end
end

getDataOptions.roiId = [];  % enable the ROI mode
if all_sw
    imgIn = obj.mibModel.getData3D('image', NaN, NaN, selected_color, getDataOptions);
    orientation = obj.mibModel.I{obj.mibModel.Id}.orientation;
    orientation = 4;
else
    imgIn = obj.mibModel.getData2D('image', NaN, NaN, selected_color, getDataOptions);
    orientation = 4;
end

indeces = obj.mibModel.I{obj.mibModel.Id}.selectedROI;

for indexId = 1:numel(imgIn)
    img = imgIn{indexId};
    datasetOptions.roiId = indeces(indexId);
    permuteSw = 0;
    %mask = zeros(size(img,1), size(img,2), size(img,4), 'uint8');
    switch text_str
        case 'Frangi filter'
            text = obj.mibView.handles.mibFrangiRange.String;
            dash = strfind(text, '-');
            Options.FrangiScaleRange = [str2double(text(1:dash-1)) str2double(text(dash+1:end))];
            Options.FrangiScaleRatio = str2double(obj.mibView.handles.mibFrangiRatio.String);
            Options.FrangiBetaOne = str2double(obj.mibView.handles.mibFrangiBeta1.String);
            Options.FrangiBetaTwo = str2double(obj.mibView.handles.mibFrangiBeta2.String);
            Options.FrangiBetaThree = str2double(obj.mibView.handles.mibFrangiBeta3.String);
            Options.BlackWhite = obj.mibView.handles.mibFrangiBlackonwhite.Value;
            Options.verbose = 0;
            Options2.bwthreshold = str2double(obj.mibView.handles.mibFrangiBWThreshold.String);
            Options2.sizefilter = str2double(obj.mibView.handles.mibFrangiBWSize.String);
            
            if threeD == 1   % do Frangi filter in 3d
                mask = mibGetFrangiMask(img, Options, Options2, '3d', orientation); %#ok<*AGROW>
                type='new';
            else                % do Frangi filter in 2d
                if all_sw
                    mask = mibGetFrangiMask(img, Options, Options2, '2d', orientation);
                else
                    mask = mibGetFrangiMask(img, Options, Options2, '2d', orientation, 1);
                end
            end
        case 'Strel filter'
            Options.bwthreshold = str2double(obj.mibView.handles.mibStrelThresholdEdit.String);
            Options.sizefilter = str2double(obj.mibView.handles.mibStrelSizeLimitEdit.String);
            Options.strelfill = obj.mibView.handles.mibStrelfillCheck.Value;
            Options.blackwhite = obj.mibView.handles.mibStrelBWCheck.Value;
            Options.threeD = threeD;
            Options.all_sw = all_sw;
            Options.orientation = orientation;
            Options.currentIndex = 1;
            se_size_txt = obj.mibView.handles.mibStrelSizeMaskEdit.String;
            semicolon = strfind(se_size_txt,';');
            if ~isempty(semicolon)  % when 2 values are provided take them
                Options.se_size(1) = str2double(se_size_txt(1:semicolon(1)-1));     % for x and y
                Options.se_size(2) = str2double(se_size_txt(semicolon(1)+1:end));   % for z
            else                    % when only 1 value - calculate the second from the pixSize
                Options.se_size(1) = str2double(se_size_txt);
                Options.se_size(2) = round(Options.se_size(1)*obj.mibModel.I{obj.mibModel.Id}.pixSize.x/obj.mibModel.I{obj.mibModel.Id}.pixSize.z);
            end
            mask = mibGetStrelMask(img, Options);
        case 'BW thresholding'
            
        case 'Morphological filters'
            extraList = obj.mibView.handles.mibMorphPanelTypeSelectPopup.String;
            Options.type = extraList{obj.mibView.handles.mibMorphPanelTypeSelectPopup.Value};
            Options.h = str2double(obj.mibView.handles.mibMorphPanelThresholdEdit.String);
            Options.conn = str2double(obj.mibView.handles.mibMorphPanelConnectivityEdit.String);
            Options.Hthres = str2double(obj.mibView.handles.mibMorphPanelHThresholdEdit.String);
            Options.threeD = threeD;
            Options.all_sw = all_sw;
            Options.orientation = orientation;
            Options.currentIndex = 1;
            mask = mibGetMorphMask(img, Options);
    end
    
    % permute if the output type is image
    if strcmp(outputType, 'image')
        mask = permute(mask,[1 2 4 3]);
    end
    
    if all_sw
        if strcmp(type,'new')   % make completely new mask
            obj.mibModel.setData3D(outputType, mask, NaN, permuteSw, NaN, datasetOptions);
        elseif strcmp(type,'add')   % add generated mask to the preexisting one
            currMask = obj.mibModel.getData3D(outputType, NaN, permuteSw, NaN, datasetOptions);
            currMask{1}(mask==1) = 1;
            obj.mibModel.setData3D(outputType, currMask, NaN, permuteSw, NaN, datasetOptions);
        end
    else
        if strcmp(type,'new')   % make completely new mask
            obj.mibModel.setData2D(outputType, mask, NaN, NaN, NaN, datasetOptions);
        elseif strcmp(type,'add')   % add generated mask to the preexisting one
            currMask = obj.mibModel.getData2D(outputType, NaN, NaN, NaN, datasetOptions);
            currMask{1}(mask==1) = 1;
            obj.mibModel.setData2D(outputType, currMask, NaN, NaN, NaN, datasetOptions);
        end
    end
end
if strcmp(outputType, 'mask')
    obj.mibView.handles.mibMaskShowCheck.Value = 1;
    obj.mibModel.mibMaskShowCheck = 1;
end
obj.plotImage();
end
