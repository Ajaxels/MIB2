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

function mibBrushPanelInterpolationSettingsBtn_Callback(obj, hObject)
% mibBrushPanelInterpolationSettingsBtn_Callback(obj, hObject)
% callback for modification of superpixel mode settings of the brush tool
%
% Parameters:
% 

% Updates
% 

global mibPath;

if strcmp(obj.mibModel.preferences.SegmTools.Interpolation.Type, 'shape')
    typeVal = 1;
else
    typeVal = 2;
end

prompts = {'Interpolation type'; sprintf('Number of points\n(more points give smoother results\nbut longer to calculate):'); 'Line width (only for the line interpolation)'};
defAns = {{'Shape', 'Line', typeVal}; obj.mibModel.preferences.SegmTools.Interpolation.NoPoints; obj.mibModel.preferences.SegmTools.Interpolation.LineWidth};
dlgTitle = 'Interpolation settings';
options.WindowStyle = 'normal';       % [optional] style of the window
options.Focus = 1;      % [optional] define index of the widget to get focus
options.PromptLines = [1, 3, 1];   % [optional] number of lines for widget titles
[answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
if isempty(answer); return; end

noPoints = round(str2double(answer{2}));
if noPoints < 2
    errordlg(sprintf('!!! Error !!!\n\nNumber of points should be more than 1'), 'Wrong value');
    return;
end
lineWidth = round(str2double(answer{3}));
if lineWidth < 1
    errordlg(sprintf('!!! Error !!!\n\nLine width should be more than 0'), 'Wrong value');
    return;
end
    
obj.mibModel.preferences.SegmTools.Interpolation.Type = lower(answer{1});
obj.mibModel.preferences.SegmTools.Interpolation.NoPoints = noPoints;
obj.mibModel.preferences.SegmTools.Interpolation.LineWidth = lineWidth;
obj.toolbarInterpolation_ClickedCallback('keepcurrent');     % update the interpolation button icon
unFocus(obj.mibView.handles.mibBrushPanelInterpolationSettingsBtn);
end