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

function mibRoiShowCheck_Callback(obj, parameter)
% function mibRoiShowCheck_Callback(obj, parameter)
% toggle show/hide state of ROIs, as callback of mibGUI.handles.mibRoiShowCheck
%
% Parameters:
% parameter: a string: when 'noplot' do not redraw the image (used from updateGuiWidgets function)

% Updates
% 

if nargin < 2; parameter = ''; end;

if numel(obj.mibView.handles.mibRoiList.String) == 1
    obj.mibView.handles.mibRoiShowCheck.Value = 0;
    obj.mibView.handles.toolbarShowROISwitch.State = 'off';
    if ~strcmp(parameter, 'noplot')
        obj.plotImage(0);
    end
    obj.mibModel.I{obj.mibModel.Id}.selectedROI = -1;   % no roi is displayed
    return;
end
val = obj.mibView.handles.mibRoiShowCheck.Value;

if val == 1
    obj.mibView.handles.toolbarShowROISwitch.State = 'on';
    roiList = obj.mibView.handles.mibRoiList.String; 
    roiNo = obj.mibView.handles.mibRoiList.Value; 
    obj.mibModel.I{obj.mibModel.Id}.selectedROI = obj.mibModel.I{obj.mibModel.Id}.hROI.findIndexByLabel(roiList{roiNo}); 
else
    obj.mibView.handles.toolbarShowROISwitch.State = 'off';
    obj.mibModel.I{obj.mibModel.Id}.selectedROI = -1;   % no roi is displayed
end
if ~strcmp(parameter, 'noplot')
    obj.plotImage();
end
end