% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function shiftColorChannel(obj, channel1, dx, dy, fillValue, options)
% function shiftColorChannel(obj, channel1, dx, dy, options)
% Shift color channel (@em channel1) by @em dx/dy pixels
%
% Parameters:
% channel1: index of the color channel to shift
% dx: x-shift in pixels
% dy: y-shift in pixels
% fillValue: [@em optional, can be [], default==0] intensity value to fill a frame generated due to the shift of
% the color channel
% options: structure with additional parameters
% .showWaitbar - logical, @b 1 [@em default] - show the waitbar, @b 0 - do not show
%
% Return values:
%

%| 
% @b Examples:
% @code handles = obj.mibModel.I{obj.mibModel.Id}.shiftColorChannel(1, 10, -5);     // call from mibController; shift channel 1 by +10 pixels in X and -5 pixels in Y @endcode

% Updates
% 

if nargin < 6; options = struct; end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end

if isempty(fillValue); fillValue = 0; end

if options.showWaitbar
    wb = waitbar(0,sprintf('Shifting channel %d by dx=%d, dy=%d\n\nPlease wait...', channel1, dx, dy), 'Name', 'Shift channel', 'WindowStyle', 'modal'); 
end

if options.showWaitbar; waitbar(0.1, wb); end

if dx<0 && dy<0
    dx2 = abs(dx);
    dy2 = abs(dy);
    obj.img{1}(1:end-dy2,1:end-dx2, channel1, :, :) = obj.img{1}(dy2+1:end,dx2+1:end,channel1,:,:);
    obj.img{1}(end-dy2+1:end, :, channel1,:,:) = fillValue;
    obj.img{1}(:, end-dx2+1:end, channel1,:,:) = fillValue;
elseif dx<=0 && dy>=0
    dx2 = abs(dx);
    obj.img{1}(dy+1:end, 1:end-dx2, channel1,:,:) = obj.img{1}(1:end-dy, dx2+1:end, channel1,:,:);
    obj.img{1}(end-dx2+1:end, :, channel1,:,:) = fillValue;
    obj.img{1}(:, 1:dy, channel1,:,:) = fillValue;
elseif dx>=0 && dy<=0
    dy2 = abs(dy);
    obj.img{1}(1:end-dy2, dx+1:end, channel1,:,:) = obj.img{1}(dy2+1:end, 1:end-dx, channel1,:,:);
    obj.img{1}(end-dy2+1:end, :, channel1,:,:) = fillValue;
    obj.img{1}(:, 1:dx, channel1,:,:) = fillValue;
else
    obj.img{1}(dy+1:end, dx+1:end, channel1,:,:) = obj.img{1}(1:end-dy, 1:end-dx, channel1,:,:);
    obj.img{1}(1:dy, :, channel1,:,:) = fillValue;
    obj.img{1}(:, 1:dx, channel1,:,:) = fillValue;
end
    
if options.showWaitbar; waitbar(0.95, wb); end

% generate the log text
log_text = sprintf('Shift channel %d, dx=%d, dy=%d, fillValue=%d', channel1, dx, dy, fillValue);
obj.updateImgInfo(log_text);
if options.showWaitbar
    waitbar(1, wb);
    delete(wb);
end
end