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

function clearMask(obj, options)
% function clearMask(obj, options)
% Clear the 'Mask' layer. It is also possible to specify
% the area where the 'Mask' layer should be cleared using the options structure.
%
% Parameters:
% options: [@em optional] a structure with optional area to clear
% @li .y -> [@em optional], [ymin, ymax] coordinates of the dataset to take after transpose for level=1, height
% @li .x -> [@em optional], [xmin, xmax] coordinates of the dataset to take after transpose for level=1, width
% @li .z -> [@em optional], [zmin, zmax] coordinates of the dataset to take after transpose, depth
% @li .t -> [@em optional], [tmin, tmax] coordinates of the dataset to take after transpose, time
% @li .showWaitbar - [@em optional], [true, false] show or not the waitbar
%
% Return values:
%

%| 
% Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.clearMask();  // call from mibController; clear the mask layer @endcode

% Updates
% 01.11.2017, IB, updated syntax


% check for the virtual stacking mode and return
if obj.Virtual.virtual == 1
    obj.maskImg{1} = NaN;
    return;
end

if nargin < 2; options = []; end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end
if options.showWaitbar
    wb = waitbar(0, sprintf('Clearing the mask layer\nPlease wait...'), 'Name', 'Clear mask');
end

if isempty(options) % clear the whole mask
    if obj.modelType == 63  % 63 materials model type
        obj.model{1} = bitset(obj.model{1}, 7, 0);
    else
        obj.maskImg{1} = zeros(size(obj.selection{1}), 'uint8');
    end
    if options.showWaitbar; waitbar(.95, wb); end
    % extra things after clearing the whole Mask
    obj.maskExist = 0;
    [pathstr, fileName] = fileparts(obj.meta('Filename'));
    obj.maskImgFilename = fullfile(pathstr, ['Mask_' fileName '.mask']);
else
    Xlim = [1 obj.width];
    Ylim = [1 obj.height];
    Zlim = [1 obj.depth];
    Tlim = [1 obj.time];
    
    if ~isfield(options, 'x'); options.x = Xlim; end
    if ~isfield(options, 'y'); options.y = Ylim; end
    if ~isfield(options, 'z'); options.z = Zlim; end
    if ~isfield(options, 't'); options.t = Tlim; end
    
    options.x(1) = max([1 options.x(1)]);
    options.x(2) = min([obj.width options.x(2)]);
    options.y(1) = max([1 options.y(1)]);
    options.y(2) = min([obj.height options.y(2)]);
    options.z(1) = max([1 options.z(1)]);
    options.z(2) = min([obj.depth options.z(2)]);
    options.t(1) = max([1 options.t(1)]);
    options.t(2) = min([obj.time options.t(2)]);
    if options.showWaitbar; waitbar(.05, wb); end
    if obj.modelType == 63  % 63 materials model type
        obj.model{1}(options.y(1):options.y(2), options.x(1):options.x(2),options.z(1):options.z(2),options.t(1):options.t(2)) = ...
            bitset(obj.model{1}(options.y(1):options.y(2), options.x(1):options.x(2),options.z(1):options.z(2),options.t(1):options.t(2)), 7, 0);
    else
        obj.maskImg{1}(options.y(1):options.y(2), options.x(1):options.x(2),options.z(1):options.z(2),options.t(1):options.t(2)) = 0;
    end
end
if options.showWaitbar
    waitbar(1, wb);
    delete(wb);
end
end