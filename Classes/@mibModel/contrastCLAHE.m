function contrastCLAHE(obj, mode, colCh)
% function contrastCLAHE(obj, mode, colCh)
% Do CLAHE Contrast-limited adaptive histogram equalization for the XY plane of the dataset for the currently shown or
% all slices
%
% Parameters:
% mode: mode for use with CLAHE
% - @b 'CLAHE_2D' - apply for the currently shown slice
% - @b 'CLAHE_3D' - apply for the current shown stack
% - @b 'CLAHE_4D' - apply for the whole dataset
% colCh: an index of the color channel
%
% Return values:
% 

% Copyright (C) 03.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 3; colCh = 1; end;

prompt = {sprintf('You are going to change image contrast by Contrast-limited adaptive histogram equalization for color channel:%d\nYou can always undo it with Ctrl-Z\n\nEnter Number of Tiles:', colCh),...
    'Enter Clip Limit in the range [0 1] that specifies a contrast enhancement limit. Higher numbers result in more contrast:',...
    'Enter NBins, a positive integer scalar specifying the number of bins for the histogram used in building a contrast enhancing transformation. Higher values result in greater dynamic range at the cost of slower processing speed',...
    'Enter Distribution [uniform, rayleigh, exponential]:',...
    'Enter Alpha, a nonnegative real scalar specifying a distribution parameter, not for uniform distribution:'};
dlg_title = 'Enter CLAHE parameters';

def = {[num2str(obj.preferences.CLAHE.NumTiles(1)) ',' num2str(obj.preferences.CLAHE.NumTiles(2))],...
    num2str(obj.preferences.CLAHE.ClipLimit),num2str(obj.preferences.CLAHE.NBins),...
    obj.preferences.CLAHE.Distribution,num2str(obj.preferences.CLAHE.Alpha)};
answer = inputdlg(prompt, dlg_title, 1, def);
if isempty(answer); return; end;

tic
wb = waitbar(0,'Adjusting contrast with CLAHE...', 'Name', 'CLAHE', 'WindowStyle', 'modal');
str2 = cell2mat(answer(1));
commas = strfind(str2,',');
obj.preferences.CLAHE.NumTiles(1) = str2double(str2(1:commas(end)-1));
obj.preferences.CLAHE.NumTiles(2) = str2double(str2(commas(end)+1:end));
obj.preferences.CLAHE.ClipLimit = str2double(cell2mat(answer(2)));
obj.preferences.CLAHE.NBins = str2double(cell2mat(answer(3)));
obj.preferences.CLAHE.Distribution = cell2mat(answer(4));
obj.preferences.CLAHE.Alpha = str2double(cell2mat(answer(5)));
pause(.5);

% when only 1 time point replace CLAHE_4D with CLAHE_3D
if strcmp(mode, 'CLAHE_4D') && obj.I{obj.Id}.time ==1
    mode = 'CLAHE_3D';
end

if strcmp(mode, 'CLAHE_4D')
    timeVector = [1, obj.I{obj.Id}.time];
elseif strcmp(mode, 'CLAHE_3D')
    obj.mibDoBackup('image', 1);
    timeVector = [obj.I{obj.Id}.getCurrentTimePoint(), obj.I{obj.Id}.getCurrentTimePoint()];
else
    obj.mibDoBackup('image', 0);
    timeVector = [obj.I{obj.Id}.getCurrentTimePoint(), obj.I{obj.Id}.getCurrentTimePoint()];
end

Distribution = obj.preferences.CLAHE.Distribution;
NumTiles = obj.preferences.CLAHE.NumTiles;
ClipLimit = obj.preferences.CLAHE.ClipLimit;
NBins = obj.preferences.CLAHE.NBins;
Alpha = obj.preferences.CLAHE.Alpha;
getDataOptions.roiId = [];  % enable use of the ROI mode
for t=timeVector(1):timeVector(2)
    if ~strcmp(mode, 'CLAHE_2D')
        img = obj.getData3D('image', t, NaN, colCh, getDataOptions);
    else
        getDataOptions.t = [t t];
        img = obj.getData2D('image', obj.I{obj.Id}.getCurrentSliceNumber(), NaN, colCh, getDataOptions);
    end
    
    for ind = 1:numel(img)
        img2 = img{ind};
        parfor z=1:size(img{1}, 4)
            if strcmp(Distribution,'uniform')
                img2(:,:,1,z) = adapthisteq(img2(:,:,1,z),...
                    'NumTiles', NumTiles, 'clipLimit', ClipLimit, 'NBins', NBins,...
                    'Distribution', Distribution);
            else
                img2(:,:,1,z) = adapthisteq(img2(:,:,1,z),...
                    'NumTiles', NumTiles, 'clipLimit', ClipLimit, 'NBins', NBins,...
                    'Distribution', Distribution, 'Alpha', Alpha);
            end
        end
        img{ind} = img2;
    end
    
    if ~strcmp(mode, 'CLAHE_2D')
        obj.setData3D('image', img, t, NaN, colCh, getDataOptions);
    else
        getDataOptions.t = [t t];
        obj.setData2D('image', img, obj.I{obj.Id}.getCurrentSliceNumber(), NaN, colCh, getDataOptions);
    end
    waitbar(t/(timeVector(2)-timeVector(1)),wb);    
end

log_text = ['CLAHE; NumTiles: ' num2str(obj.preferences.CLAHE.NumTiles) ';clipLimit: ' num2str(obj.preferences.CLAHE.ClipLimit)...
    ';NBins:' num2str(obj.preferences.CLAHE.NBins) ';Distribution:' obj.preferences.CLAHE.Distribution ';Alpha:' num2str(obj.preferences.CLAHE.Alpha) ';ColCh:' num2str(colCh)];
obj.I{obj.Id}.updateImgInfo(log_text);
delete(wb);
toc
end
