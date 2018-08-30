function mibImageFilterDoitBtn_Callback(obj)
% function mibImageFilterDoitBtn_Callback(obj)
% a callback to the obj.mibView.handles.mibImageFilterDoitBtn, apply image filtering using the selected filter
%
% Parameters:
%
% Return values:
%

% Copyright (C) 11.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
    toolname = 'Image filters are';
    warndlg(sprintf('!!! Warning !!!\n\n%s not yet available in the virtual stacking mode!\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

filter_val = obj.mibView.handles.mibImageFilterPopup.Value;
filter_list = obj.mibView.handles.mibImageFilterPopup.String;

switch filter_list{filter_val}
%     case 'Edge Enhancing Coherence Filter'
%         obj.mibAnisotropicDiffusion('coherence_filter');
%         obj.plotImage(0);
%         return;
    case 'DNN Denoise'
        if obj.matlabVersion < 9.3
            errordlg(sprintf('!!! Error !!!\nMatlab R2017b or newer is required to use this function!'), 'Matlab version is too old');
            return;
        end
        n = gpuDeviceCount();
        if n==0
            button = questdlg(sprintf('!!! Warning !!!\n\nEfficient image denoising using deep neural network requires GPUs\nwithout GPU denoising will be extremely slow'),...
                'Deep neural network denoise', 'Proceed anyway', 'Cancel', 'Cancel');
            if strcmp(button, 'Cancel'); return; end
        end
    case 'Perona Malik anisotropic diffusion'
        obj.mibAnisotropicDiffusion('anisodiff');
        obj.plotImage(0);
        return;
%     case {'Diplib: Perona Malik anisotropic diffusion','Diplib: Robust Anisotropic Diffusion','Diplib: Mean Curvature Diffusion',...
%             'Diplib: Corner Preserving Diffusion','Diplib: Kuwahara filter for edge-preserving smoothing'}
%         obj.mibAnisotropicDiffusion('diplib');
%         obj.plotImage(0);
%         return;
end

tic
% define strel size
hsize_txt = obj.mibView.handles.mibImfiltPar1Edit.String;
semicolon = strfind(hsize_txt,';');
if ~isempty(semicolon)
    hsize(1) = str2double(hsize_txt(1:semicolon(1)-1));
    hsize(2) = str2double(hsize_txt(semicolon(1)+1:end));
else
    dashsign = strfind(hsize_txt,'-');
    if ~isempty(dashsign)
        hsize(1) = str2double(hsize_txt(1:dashsign(1)-1));
        hsize(2) = str2double(hsize_txt(dashsign(1)+1:end));
    else
        hsize(1) = str2double(hsize_txt);
        hsize(2) = hsize(1);    
    end
end

% define mode to apply a filter:
% 2D, shown slice
% 3D, current stack
% 4D, complete volume
mode = obj.mibView.handles.mibImageFiltersModePopup.String;
mode = mode{obj.mibView.handles.mibImageFiltersModePopup.Value};
if obj.mibModel.getImageProperty('time') == 1 && strcmp(mode, '4D, complete volume')
    mode = '3D, current stack';
end

% define what to do with the filtered image:
% Apply filter
% Apply and add to the image
% Apply and subtract from the image
doAfter = obj.mibView.handles.mibImageFiltersOptionsPopup.String;
doAfter = doAfter{obj.mibView.handles.mibImageFiltersOptionsPopup.Value};

options.dataType = '4D';    % 4D means that there are 4 dimensions in the dataset (h,w,c,z) to separate with selection, where it is only 3 (h,w,z)
options.fitType = cell2mat(filter_list(filter_val));
options.filters3DCheck = obj.mibView.handles.mibImageFilters3DCheck.Value;

%options.colorChannel = get(handles.ColChannelCombo,'Value')-1;
slices = obj.mibModel.getImageProperty('slices');
if numel(slices{3}) ~= 1    % get color channel from the selected in the Selection panel
    options.colorChannel = obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel;
else    % when only one color channel is shown, take it
    options.colorChannel = slices{3};
end

if strcmp(obj.mibView.handles.mibImfiltPar1Edit.Enable, 'on')
    options.hSize = hsize;
end
if strcmp(obj.mibView.handles.mibImfiltPar2Edit.Enable, 'on'); options.sigma = str2double(obj.mibView.handles.mibImfiltPar2Edit.String);  end
if strcmp(obj.mibView.handles.mibImfiltPar3Edit.Enable, 'on'); options.lambda = str2double(obj.mibView.handles.mibImfiltPar3Edit.String); end
if strcmp(obj.mibView.handles.mibImfiltPar4Edit.Enable, 'on'); options.beta2 = str2double(obj.mibView.handles.mibImfiltPar4Edit.String); end
if strcmp(obj.mibView.handles.mibImfiltPar5Edit.Enable, 'on'); options.beta3 = str2double(obj.mibView.handles.mibImfiltPar5Edit.String); end
if strcmp(obj.mibView.handles.mibImageFiltersTypePopup.Enable, 'on')
    if obj.mibView.handles.mibImageFiltersTypePopup.Value == 1
        options.BlackWhite = 1; 
    else
        options.BlackWhite = 0; 
    end
    options.padding = obj.mibView.handles.mibImageFiltersTypePopup.String{obj.mibView.handles.mibImageFiltersTypePopup.Value};
end

options.pixSize = obj.mibModel.getImageProperty('pixSize');    % for 3D gaussian filter
if obj.mibView.handles.mibRoiShowCheck.Value == 1   % when ROI mode is on, the returned dataset is transposed
    options.orientation = 4;
else
    options.orientation = obj.mibModel.getImageProperty('orientation');
end

showWaitbarLocal = 0;
getDataOptions.roiId = [];
if strcmp(mode, '4D, complete volume')
    timeVector = [1, obj.mibModel.getImageProperty('time')];
    options.showWaitbar = 0;    % do not show waitbar in the filtering function
    showWaitbarLocal = 1;
    wb = waitbar(0,['Applying ' options.fitType ' filter...'], 'Name', 'Filtering', 'WindowStyle', 'modal');
elseif strcmp(mode, '3D, current stack')
    obj.mibModel.mibDoBackup('image', 1, getDataOptions);
    timeVector = [obj.mibModel.I{obj.mibModel.Id}.getCurrentTimePoint(), obj.mibModel.I{obj.mibModel.Id}.getCurrentTimePoint()];
else
    obj.mibModel.mibDoBackup('image', 0, getDataOptions);
    timeVector = [obj.mibModel.I{obj.mibModel.Id}.getCurrentTimePoint(), obj.mibModel.I{obj.mibModel.Id}.getCurrentTimePoint()];
end

for t=timeVector(1):timeVector(2)
    if ~strcmp(mode, '2D, shown slice')
        img = obj.mibModel.getData3D('image', t, NaN, options.colorChannel, getDataOptions);
    else
        getDataOptions.t = [t t];
        img = obj.mibModel.getData2D('image', obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber(), NaN, options.colorChannel, getDataOptions);
    end
    
    for roi = 1:numel(img)
        switch doAfter
            case 'Apply filter'
                [img{roi}, log_text] = mibDoImageFiltering(img{roi}, options);
            case 'Apply and add to the image'
                [imgOut, log_text] = mibDoImageFiltering(img{roi}, options);
                img{roi} = img{roi}+imgOut;
            case 'Apply and subtract from the image'
                [imgOut, log_text] = mibDoImageFiltering(img{roi}, options);
                img{roi} = img{roi}-imgOut;
        end
    end
    
    if ~strcmp(mode, '2D, shown slice')
        obj.mibModel.setData3D('image', img, t, NaN, options.colorChannel, getDataOptions);
    else
        obj.mibModel.setData2D('image', img, obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber(), NaN, options.colorChannel, getDataOptions);
    end
    if showWaitbarLocal == 1
        waitbar(t/(timeVector(2)-timeVector(1)),wb);
    end
end

log_text = sprintf('%s, Mode:%s, Options:%s', log_text, mode, doAfter);
if strcmp(mode, '2D, shown slice')
    log_text = [log_text ',slice=' num2str(obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber())];
end
if showWaitbarLocal == 1
    delete(wb);
end
if isnan(log_text); return; end
%obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(log_text);
obj.mibModel.getImageMethod('updateImgInfo', NaN, log_text);

obj.plotImage(0);
toc
end