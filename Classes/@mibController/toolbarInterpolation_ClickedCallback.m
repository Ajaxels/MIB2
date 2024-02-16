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

function toolbarInterpolation_ClickedCallback(obj, options)
% function toolbarInterpolation_ClickedCallback(obj, options)
% Function to set the state of the interpolation button in the toolbar.
%
% When the ''options'' variable is omitted the function works as a standard
% callback and changes the type of interpolation: ''shape'' or ''line''.
% However, when ''options'' are specified the function sets the state of
% the button to the currently selected type.
%
% Parameters:
% options: [@em optional], 
% @li when @b ''keepcurrent'' set the state of the button to the currently
% selected type of the interpolation.
%
% Return values:
% 
%| @b Examples:
% @code obj.toolbarInterpolation_ClickedCallback('keepcurrent');     // call from mibController; update the interpolation button icon @endcode

% Updates
% 
global mibPath;

if nargin == 2  % when options are available
    if strcmp(options, 'keepcurrent')
        0;
    end
else
    if strcmp(obj.mibModel.preferences.SegmTools.Interpolation.Type, 'shape')
        obj.mibModel.preferences.SegmTools.Interpolation.Type = 'line';
    else
        obj.mibModel.preferences.SegmTools.Interpolation.Type = 'shape';
    end
end
if strcmp(obj.mibModel.preferences.SegmTools.Interpolation.Type, 'line')
    filename = 'line_interpolation.res';
    obj.mibView.handles.toolbarInterpolation.TooltipString = 'Use LINE interpolation';
    obj.mibView.handles.menuSelectionInterpolate.Label = 'Interpolate as Line (I)';
else
    filename = 'shape_interpolation.res';
    obj.mibView.handles.toolbarInterpolation.TooltipString = 'Use SHAPE interpolation';
    obj.mibView.handles.menuSelectionInterpolate.Label = 'Interpolate as Shape (I)';
end

img = load(fullfile(mibPath, 'Resources', filename), '-mat');  % load icon
obj.mibView.handles.toolbarInterpolation.CData = img.image;
end

