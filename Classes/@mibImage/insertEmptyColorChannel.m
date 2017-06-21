function insertEmptyColorChannel(obj, channel1)
% function insertEmptyColorChannel(obj, channel1)
% Insert an empty color channel to the specified position
%
% Parameters:
% channel1: [@em optional] the index of color channel to insert.
%
% Return values:

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.insertEmptyColorChannel(1);     // call from mibController; insert empty color channel to position 1 @endcode

% Copyright (C) 07.12.2016, Ilya Belevich (ilya.belevich @ helsinki.fi)
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% Updates
% 
% 
global mibPath; % path to mib installation folder

if nargin < 2
    channel1 = obj.colors + 1;
end

prompt = {sprintf('Insert empty color channel\n\nEnter position (1-%d):', obj.colors + 1)};
answer = mibInputDlg({mibPath}, prompt,'Insert empty color channel', {num2str(channel1)});
if size(answer) == 0; return; end;
channel1 = str2double(answer{1});
if channel1 < 1 || channel1 > obj.colors + 1 
    errordlg(sprintf('!!! Error !!!\n\nWrong channel number!\nThe channel numbers should be between 1 and %d', obj.colors),'Error');
    return;
end

wb = waitbar(0,sprintf('Inserting empty color channel to position %d\n\nPlease wait...', channel1),'Name','Insert empty color channels','WindowStyle','modal');
if channel1 == 1
    obj.img{1}(:,:,2:obj.colors+1,:,:) = obj.img{1};
    obj.img{1}(:,:,1,:,:) = zeros([obj.height, obj.width, 1, obj.depth, obj.time], class(obj.img{1})); 
    obj.lutColors = [rand([1, 3]); obj.lutColors];
elseif channel1 == obj.colors + 1
    obj.img{1}(:,:,obj.colors+1,:,:) = zeros([obj.height, obj.width, 1, obj.depth, obj.time], class(obj.img{1}));
    obj.lutColors = [obj.lutColors; rand([1, 3])];
else
    obj.img{1}(:,:,1:channel1-1,:,:) = obj.img{1}(:,:,1:channel1-1,:,:);
    obj.img{1}(:,:,channel1+1:obj.colors+1,:,:) = obj.img{1}(:,:,channel1:obj.colors,:,:);
    obj.img{1}(:,:,channel1,:,:) = zeros([obj.height, obj.width, 1, obj.depth, obj.time], class(obj.img{1}));
    obj.lutColors = [obj.lutColors(1:channel1-1,:); rand([1, 3]); obj.lutColors(channel1:end,:)];
end
waitbar(0.66, wb);
obj.colors = obj.colors + 1;
obj.viewPort.min(obj.colors) = 0;
obj.viewPort.max(obj.colors) = double(intmax(class(obj.img{1})));
obj.viewPort.gamma(obj.colors) = 1;
obj.meta('ColorType') = 'truecolor';

waitbar(.99, wb);

% generate the log text
log_text = sprintf('Insert empty color channel to position %d', channel1);
obj.updateImgInfo(log_text);

waitbar(1, wb);
delete(wb);
end