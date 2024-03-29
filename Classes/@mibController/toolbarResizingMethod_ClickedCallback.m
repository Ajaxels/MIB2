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

function toolbarResizingMethod_ClickedCallback(obj, options)
% function toolbarResizingMethod_ClickedCallback(obj, options)
% Function to set type of image interpolation for the visualization
%
% When the ''options'' variable is omitted the function works as a standard
% callback and changes the type of image interpolation: ''bicubic'' or ''nearest''.
% However, when ''options'' are specified the function sets the state of
% the button to the currently selected type.
%
% Parameters:
% options: [@em optional], 
% @li when @b ''keepcurrent'' set the state of the button to the currently
% selected type of the interpolation: @em
% obj.mibModel.preferences.System.ImageResizeMethod
%
% Return values:
% 

%| @b Examples:
% @code obj.toolbarResizingMethod('keepcurrent');     // call from mibController; update the image interpolation button icon @endcode

% Updates
% 

if nargin == 2  % when options are available
    if strcmp(options, 'keepcurrent')
        0;
    end
else
    if strcmp(obj.mibModel.preferences.System.ImageResizeMethod, 'bicubic')
        obj.mibModel.preferences.System.ImageResizeMethod = 'nearest';
    elseif strcmp(obj.mibModel.preferences.System.ImageResizeMethod, 'nearest')
        obj.mibModel.preferences.System.ImageResizeMethod = 'auto';
    else
        obj.mibModel.preferences.System.ImageResizeMethod = 'bicubic';
    end
end

if strcmp(obj.mibModel.preferences.System.ImageResizeMethod, 'auto')
    filename = 'image_auto.res';
    obj.mibView.handles.toolbarResizingMethod.TooltipString = 'automatic interpolation: bicubic for magnification < 100% and nearest for >=100%';
elseif strcmp(obj.mibModel.preferences.System.ImageResizeMethod, 'bicubic')
    filename = 'image_bicubic.res';
    obj.mibView.handles.toolbarResizingMethod.TooltipString = 'bicubic interpolation for the visualization, press for neareast';
else
    filename = 'image_nearest.res';
    obj.mibView.handles.toolbarResizingMethod.TooltipString = 'nearest interpolation for the visualization, press for bicubic';
end

img = load(fullfile(obj.mibPath, 'Resources', filename), '-mat');  % load icon
obj.mibView.handles.toolbarResizingMethod.CData = img.image;

if nargin < 2
    obj.plotImage();
end

%if isfield(handles, 'Img')
%    handles.Img{handles.Id}.I.plotImage(handles.imageAxes, handles, 0);     % redraw the image
%else
%    guidata(handles.mibGUI, handles);       % during init of MIB from im_browser_getDefaultParameters
%end
end
