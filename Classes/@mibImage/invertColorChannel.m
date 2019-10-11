function invertColorChannel(obj, channel1, options)
% function invertColorChannel(obj, channel1, options)
% Invert color channel of the dataset
%
% The specified @em channel1 will be inverted
%
% Parameters:
% channel1: [@em optional] index of the color channel to invert
% options: structure with additional parameters
% .showWaitbar - logical, @b 1 [@em default] - show the waitbar, @b 0 - do not show
%
% Return values:

%| 
% @b Examples:
% @code handles = obj.mibModel.I{obj.mibModel.Id}.invertColorChannels(1);     // call from mibController; invert color channel 1 @endcode

% Copyright (C) 07.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% Updates
% 26.05.2019, added options

global mibPath; % path to mib installation folder

if nargin < 3; options = struct; end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end

if nargin < 2; channel1 = []; end

if isempty(channel1)
    channel1 = max([1 obj.selectedColorChannel]);
    PossibleColChannels = arrayfun(@(x) sprintf('ColCh %d', x), 1:obj.colors, 'UniformOutput', false);
    PossibleColChannels{end+1} = channel1;
    mibInputMultiDlgOptions.PromptLines = 1;
    
    prompt = {'Select color channel to invert'};
    defAns = {PossibleColChannels};
    [answer, selIndices] = mibInputMultiDlg({mibPath}, prompt, defAns, 'Invert color channel', mibInputMultiDlgOptions);
    if isempty(answer); return; end
    
    channel1 = selIndices(1);
end

if options.showWaitbar; wb = waitbar(0,sprintf('Inverting color channel: %d\n\nPlease wait...', channel1), 'Name', 'Invert color channel', 'WindowStyle', 'modal'); end

maxval = obj.meta('MaxInt');
if options.showWaitbar; waitbar(0.1, wb); end
obj.img{1}(:,:,channel1,:,:) = maxval - obj.img{1}(:, :, channel1, :, :);
if options.showWaitbar; waitbar(0.95, wb); end

% generate the log text
log_text = sprintf('Invert color channel %d', channel1);
obj.updateImgInfo(log_text);
if options.showWaitbar
    waitbar(1, wb);
    delete(wb);
end
end