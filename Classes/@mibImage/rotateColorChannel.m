function rotateColorChannel(obj, channel1, angle, options)
% function rotateColorChannel(obj, channel1, angle, options)
% Rotate color channel of the dataset
%
% The specified @em channel1 will be rotated
%
% Parameters:
% channel1: [@em optional] index of the color channel to invert, can be empty
% angle: [@em optional] rotation angle, should be a number: 90, 180 or -90, can be empty
% options: structure with additional parameters
% .showWaitbar - logical, @b 1 [@em default] - show the waitbar, @b 0 - do not show

%
% Return values:

%| 
% @b Examples:
% @code 
% obj.mibModel.I{obj.mibModel.Id}.rotateColorChannel(1, 90);     // call from mibController; rotate color channel 1 by 90 degrees 
% @endcode

% Copyright (C) 07.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 26.05.2019, added options

global mibPath; % path to mib installation folder

if nargin < 4; options = struct; end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end

if obj.width ~= obj.height; errordlg(sprintf('!!! Error !!!\n\nThe rotation of a channel is only possible for a square-shaped images'),'Wrong image dimensions'); return; end
if nargin < 3; angle = []; end
if nargin < 2; channel1 = []; end

if isempty(channel1) || isempty(angle)
    if isempty(channel1); channel1 = max([1 obj.selectedColorChannel]); end
    if isempty(angle); angle = '90'; end
    
    textString1 = 'Color channel to rotate:';
    textString2 = 'Rotation angle (90, 180, -90):';
    prompt = {textString1; textString2};
    mibInputMultiDlgOptions.PromptLines = [1, 1];
    
    PossibleColChannels = arrayfun(@(x) sprintf('ColCh %d', x), 1:obj.colors, 'UniformOutput', false);
    PossibleColChannels{end+1} = channel1;
    defAns = {PossibleColChannels, angle};
    [answer, selIndices] = mibInputMultiDlg({mibPath}, prompt, defAns, 'Rotate color channel', mibInputMultiDlgOptions);
    if isempty(answer); return; end
    
    channel1 = selIndices(1);
    angle = str2double(answer{2});
    
    if mod(angle, 90) ~= 0
        errordlg(sprintf('!!! Error !!!\n\nThe rotation angle should be one of these numbers: 90, 180, -90'), 'Wrong rotation!');
        return;
    end
end
% rotate color channel
if options.showWaitbar; wb = waitbar(0,sprintf('Rotating (%d) color channel %d\nPlease wait...', angle, channel1), 'Name', 'Rotate color channel', 'WindowStyle','modal'); end

noIter = -round(angle/90);   % number of rotation iterations

for t=1:obj.time
    for slice = 1:obj.depth
        obj.img{1}(:, :, channel1, slice, t) = rot90(obj.img{1}(:, :, channel1, slice, t), noIter);
    end
    if options.showWaitbar; waitbar(t/obj.time, wb); end
end
if options.showWaitbar; waitbar(1, wb); end
log_text = sprintf('Rotate color channel %d by %d degrees', channel1, angle);
obj.updateImgInfo(log_text);
if options.showWaitbar; delete(wb); end
end