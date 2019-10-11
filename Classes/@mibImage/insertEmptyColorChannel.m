function insertEmptyColorChannel(obj, channel1, options)
% function insertEmptyColorChannel(obj, channel1, options)
% Insert an empty color channel to the specified position
%
% Parameters:
% channel1: [@em optional] the index of color channel to insert.
% options: structure with additional parameters
% .showWaitbar - logical, @b 1 [@em default] - show the waitbar, @b 0 - do not show
% Return values:

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.insertEmptyColorChannel(1);     // call from mibController; insert empty color channel to position 1 @endcode
%
% Copyright (C) 07.12.2016, Ilya Belevich (ilya.belevich @ helsinki.fi)
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% Updates
% 

global mibPath; % path to mib installation folder
if nargin < 3; options = struct; end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end

if nargin < 2;  channel1 = [];  end

if isempty(channel1)
    prompt = {sprintf('Insert empty color channel\n\nEnter position (1-%d):', obj.colors + 1)};
    answer = mibInputDlg({mibPath}, prompt,'Insert empty color channel', {num2str(channel1)});
    if size(answer) == 0; return; end
    channel1 = str2double(answer{1});
end

if channel1 < 1 || channel1 > obj.colors + 1 
    errordlg(sprintf('!!! Error !!!\n\nWrong channel number!\nThe channel numbers should be between 1 and %d', obj.colors),'Error');
    return;
end

if options.showWaitbar; wb = waitbar(0,sprintf('Inserting empty color channel to position %d\n\nPlease wait...', channel1),'Name','Insert empty color channels','WindowStyle','modal'); end
if channel1 == 1
    obj.img{1}(:,:,2:obj.colors+1,:,:) = obj.img{1};
    obj.img{1}(:,:,1,:,:) = zeros([obj.height, obj.width, 1, obj.depth, obj.time], obj.meta('imgClass')); 
    obj.lutColors = [rand([1, 3]); obj.lutColors];
elseif channel1 == obj.colors + 1
    obj.img{1}(:,:,obj.colors+1,:,:) = zeros([obj.height, obj.width, 1, obj.depth, obj.time], obj.meta('imgClass'));
    obj.lutColors = [obj.lutColors; rand([1, 3])];
else
    obj.img{1}(:,:,1:channel1-1,:,:) = obj.img{1}(:,:,1:channel1-1,:,:);
    obj.img{1}(:,:,channel1+1:obj.colors+1,:,:) = obj.img{1}(:,:,channel1:obj.colors,:,:);
    obj.img{1}(:,:,channel1,:,:) = zeros([obj.height, obj.width, 1, obj.depth, obj.time], obj.meta('imgClass'));
    obj.lutColors = [obj.lutColors(1:channel1-1,:); rand([1, 3]); obj.lutColors(channel1:end,:)];
end
if options.showWaitbar; waitbar(0.66, wb); end
obj.colors = obj.colors + 1;
obj.dim_yxczt(3) = obj.colors;
obj.viewPort.min(obj.colors) = 0;
obj.viewPort.max(obj.colors) = obj.meta('MaxInt');
obj.viewPort.gamma(obj.colors) = 1;
obj.meta('ColorType') = 'truecolor';

if options.showWaitbar; waitbar(.99, wb); end

% generate the log text
log_text = sprintf('Insert empty color channel to position %d', channel1);
obj.updateImgInfo(log_text);

if options.showWaitbar
    waitbar(1, wb);
    delete(wb);
end
end