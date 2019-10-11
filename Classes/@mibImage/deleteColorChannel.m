function deleteColorChannel(obj, channel1, options)
% function deleteColorChannel(obj, channel1, options)
% Delete specified color channel from the dataset
%
% Parameters:
% channel1: [@em optional] the index of color channel to delete.
% options: structure with additional parameters
% .showWaitbar - logical, @b 1 [@em default] - show the waitbar, @b 0 - do not show
%
% Return values:
% status: result of the function: 0-fail/1-success

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.deleteColorChannel(3);     // call from mibController; delete color channel 3 from the obj.img @endcode
% @code obj.mibModel.getImageMethod('deleteColorChannel', NaN, 3); // call from mibController via a wrapper function getImageMethod @endcode

% Copyright (C) 07.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% Updates
% 

global mibPath; % path to mib installation folder

if obj.colors < 2; errordlg(sprintf('Error!\nThere is only one color available!\nCancelling...'), 'Not enough colors','modal'); return; end
if nargin < 3; options = struct; end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end

if nargin < 2; channel1 = []; end
if isempty(channel1)
    prompt = {sprintf('Delete color channel\n\nEnter number of the color channel to be deleted:')};
    answer = mibInputDlg({mibPath}, prompt, 'Delete color channel', {num2str(channel1(1)')});
    if size(answer) == 0; return; end
    channel1 = str2num(answer{1}{1}); %#ok<ST2NM>
end

if min(channel1) < 1 || max(channel1) > obj.colors 
    errordlg(sprintf('!!! Error !!!\n\nWrong channel number!\nThe channel numbers should be between 1 and %d', obj.colors),'Error');
    return;
end

% if numel(channel1) > 1
%     button = questdlg(sprintf('!!! Warning !!!\n\nYou are going to delete channels: %s\nAre you sure?', mat2str(channel1)),'Delete color channels','Delete','Cancel','Cancel');
%     if strcmp(button, 'Cancel'); return; end;
% end

if options.showWaitbar; wb = waitbar(0,sprintf('Deleting color channel %d from the dataset\n\nPlease wait...',channel1),'Name','Delete color channels','WindowStyle','modal'); end
colorList = 1:obj.colors;
obj.img{1} = obj.img{1}(:,:,~ismember(colorList, channel1),:,:);
if options.showWaitbar; waitbar(0.66, wb); end
obj.colors = obj.colors - numel(channel1);
obj.dim_yxczt(3) = obj.colors;

%obj.viewPort.min = obj.viewPort.min(colorList(colorList~=channel1));
%obj.viewPort.max = obj.viewPort.max(colorList(colorList~=channel1));
%obj.viewPort.gamma = obj.viewPort.gamma(colorList(colorList~=channel1));
obj.viewPort.min = obj.viewPort.min(~ismember(colorList, channel1));
obj.viewPort.max = obj.viewPort.max(~ismember(colorList, channel1));
obj.viewPort.gamma = obj.viewPort.gamma(~ismember(colorList, channel1));

obj.slices{3} = obj.slices{3}(~ismember(obj.slices{3}, channel1));
obj.slices{3}(obj.slices{3} > max(channel1)) = obj.slices{3}(obj.slices{3} > max(channel1)) - numel(channel1);

% remove information about the lut
obj.lutColors(channel1,:) = [];
if isKey(obj.meta, 'lutColors')
    lutColorsLocal = obj.meta('lutColors');
    lutColorsLocal(channel1,:) = [];
    obj.meta('lutColors') = lutColorsLocal;
end

if options.showWaitbar; waitbar(.99, wb); end

if obj.colors == 1
    obj.meta('ColorType') = 'grayscale';
end
if isempty(obj.slices{3})
    obj.slices{3} = 1;
end

% generate the log text
log_text = sprintf('Delete color channel(s) %s', mat2str(channel1));
obj.updateImgInfo(log_text);
if options.showWaitbar
    waitbar(1, wb);
    delete(wb);
end
end