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

function mibBrushSuperpixelsEdit_Callback(obj, hObject)
% mibBrushSuperpixelsEdit_Callback(obj, hObject)
% callback for modification of superpixel mode settings of the brush tool
%
% Parameters:
% 

% Updates
% 

val = round(str2double(hObject.String));

if obj.mibView.handles.mibBrushSuperpixelsCheck.Value == 1  % slic mode
    switch hObject.Tag
        case 'mibSuperpixelsNumberEdit'
            if val < 1 
                errordlg(sprintf('!!! Error !!!\nthe value should be positive integer!'), 'Wrong value', 'modal');
                obj.mibView.handles.mibSuperpixelsCompactEdit.String = num2str(obj.mibModel.preferences.SegmTools.Superpixels.NoSLIC);
                return;
            end
            obj.mibModel.preferences.SegmTools.Superpixels.NoSLIC = val;
        case 'mibSuperpixelsCompactEdit'
            if val < 0 
                errordlg(sprintf('!!! Error !!!\nthe value should be positive integer!'), 'Wrong value', 'modal');
                obj.mibView.handles.mibSuperpixelsCompactEdit.String = num2str(obj.mibModel.preferences.SegmTools.Superpixels.CompactSLIC);
                return;
            end
            obj.mibModel.preferences.SegmTools.Superpixels.CompactSLIC = val;
    end
elseif obj.mibView.handles.mibBrushSuperpixelsWatershedCheck.Value == 1     % watershed mode
    switch hObject.Tag
        case 'mibSuperpixelsNumberEdit'
            if val < 0 
                errordlg(sprintf('!!! Error !!!\nthe value should be positive integer or 0!'), 'Wrong value', 'modal');
                obj.mibView.handles.mibSuperpixelsCompactEdit.String = num2str(obj.mibModel.preferences.SegmTools.Superpixels.NoWatershed);
                return;
            end
            obj.mibModel.preferences.SegmTools.Superpixels.NoWatershed = val;
        case 'mibSuperpixelsCompactEdit'
            if ~ismember(val, [0 1]) 
                errordlg(sprintf('!!! Error !!!\nthe value should be 0 or 1!'), 'Wrong value', 'modal');
                obj.mibView.handles.mibSuperpixelsCompactEdit.String = num2str(obj.mibModel.preferences.SegmTools.Superpixels.InvertWatershed);
                return;
            end
            obj.mibModel.preferences.SegmTools.Superpixels.InvertWatershed = val;
    end
end

end