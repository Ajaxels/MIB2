function mibAutoBrightnessBtn_Callback(obj)
% function mibAutoBrightnessBtn_Callback(obj)
% Adjust brightness automatically for the shown image
%
% The function stretch the image min and max intensity values to fill the
% minimal and maximal values of the image container. When
% handles.brightnessFixCheck == 1 the coefficients are calculated for the
% whole 3D dataset; when handles.brightnessFixCheck == 0 each single slice
% adjusted individually.
%
% Parameters:
% 
% Return values
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

prompt = {sprintf('!!! WARNING !!!\nThis function will recalculate intensities of the images!!!\nIf you want to adjust contrast without modification of intensities, please use the Display button in the View Settings panel!\n\nEnter low limit of saturation [0-1], %%:'),...
                  'Enter high limit of saturation [0-1], %%:'};
dlg_title = 'Enter limits for contrast stretching';
num_lines = 1;
def = {'0.01','0.99'};
answer = inputdlg(prompt, dlg_title, num_lines, def);
if isempty(answer); return; end;

low_lim = str2double(cell2mat(answer(1)));
high_lim = str2double(cell2mat(answer(2)));

maxC = obj.mibModel.getImageProperty('colors');
color_id = obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel;
if color_id == 0    % do for all colors individually
    color_start = 1;
    color_end = maxC;
else    % do for selected color channel only
    color_start = color_id;
    color_end = color_id;
end

wb = waitbar(0,'Auto brightness adjustment...', 'Name', 'Auto brightness', 'WindowStyle', 'modal');

max_layer = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, obj.mibModel.I{obj.mibModel.Id}.orientation);
maxT = obj.mibModel.getImageProperty('time');
if maxT == 1; obj.mibModel.mibDoBackup('image', 1); end;

options.roiId = [];
for t=1:maxT
    img = obj.mibModel.getData3D('image', t, NaN, NaN, options);
    for roi=1:numel(img)
        if obj.mibView.handles.mibBrightnessFixCheck.Value == 1         % adjust brightness with fixed coefficients
            for color_id=color_start:color_end   % number of color channels
                stretchPar = zeros([max_layer 2]);
                for layer_id=1:max_layer % finding the widest stretching coefficients
                    stretchPar(layer_id,:) = stretchlim(img{roi}(:,:,color_id,layer_id), [low_lim high_lim]);
                end
                minPar = min(stretchPar(:,1));  % left border
                maxPar = max(stretchPar(:,2));  % rigth border
                for layer_id=1:max_layer
                    slice = img{roi}(:, :, color_id, layer_id);
                    img{roi}(:, :, color_id, layer_id) = imadjust(slice, [minPar maxPar]);
                end;
                waitbar(color_id/maxC,wb);
            end
        else
            for layer_id=1:max_layer
                for color_id=color_start:color_end
                    slice = img{roi}(:,:,color_id,layer_id);
                    img{roi}(:, :, color_id, layer_id) = imadjust(slice, stretchlim(slice, [low_lim high_lim]));
                end
                if mod(layer_id, 10) == 0; waitbar(layer_id/max_layer,wb); end;
            end
        end;
    end
    obj.mibModel.setData3D('image', img, t, NaN, NaN, options);
end

log_text = ['Auto Brightness; Fixed:' num2str(obj.mibView.handles.mibBrightnessFixCheck.Value) ';Stretch:[' num2str(low_lim) '-' num2str(high_lim) ']; ColorCh:' num2str(obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel)];
obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(log_text);
delete(wb);
obj.plotImage(0);
end
