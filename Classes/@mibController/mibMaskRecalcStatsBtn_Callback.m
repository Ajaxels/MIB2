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

function mibMaskRecalcStatsBtn_Callback(obj)
% function mibMaskRecalcStatsBtn_Callback(obj)
% recalculate objects for Mask or Model layer to use with the Object Picker
% tool in 3D
%
% This function populates mibModel.maskStat structure
%
%

% Updates
% 25.08.2023, selection of mask or model is done based on the selected row in the segmentation table

type = 'model';     % type of data for calculation of stats
colchannel = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
if colchannel == -1
    type = 'mask';
    colchannel = 0;
    materialName = 'Mask';
elseif colchannel == 0
    materialName = 'Exterior';
else
    if obj.mibModel.I{obj.mibModel.Id}.modelType > 255
        %materialName = num2str(colchannel);    % get material name
        materialName = 'all objects';    % get material name
    else
        materialName = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{colchannel};    % get material name
    end
end

wb = waitbar(0, sprintf('Calculating statistics for %s\nPlease wait...', materialName), 'WindowStyle', 'modal');
getDataOptions.blockModeSwitch = 0;

if obj.mibView.handles.mibMagicwandConnectCheck4.Value
    connectionType = 6; % 6-neighbour points
else
    connectionType = 26; % 26-neighbour points
end

switch type
    case 'model'
        if obj.mibModel.I{obj.mibModel.Id}.modelType < 65535
            % generate
            % maskStat.NumObjects -> label field
            % maskStat.L -> label field
            % maskStat.bb -> label field
            obj.mibModel.I{obj.mibModel.Id}.maskStat = bwconncomp(cell2mat(obj.mibModel.getData3D(type, NaN, 4, colchannel, getDataOptions)), connectionType);
            obj.mibModel.I{obj.mibModel.Id}.maskStat.L = labelmatrix(obj.mibModel.I{obj.mibModel.Id}.maskStat);     % create a label matrix for fast search of the indices
            obj.mibModel.I{obj.mibModel.Id}.maskStat.bb = regionprops(obj.mibModel.I{obj.mibModel.Id}.maskStat, 'BoundingBox');     % create a label matrix for fast search of the indices
            obj.mibModel.I{obj.mibModel.Id}.maskStat = rmfield(obj.mibModel.I{obj.mibModel.Id}.maskStat, 'PixelIdxList');   % remove PixelIdxList it is not needed anymore
        else
            % generate: maskStat{objId}.maskStat
            obj.mibModel.I{obj.mibModel.Id}.maskStat = regionprops(cell2mat(obj.mibModel.getData3D(type, NaN, 4, NaN, getDataOptions)), 'PixelIdxList');
        end
    case 'mask'
        % generate
            % maskStat.NumObjects -> label field
            % maskStat.L -> label field
            % maskStat.bb -> label field
            obj.mibModel.I{obj.mibModel.Id}.maskStat = bwconncomp(cell2mat(obj.mibModel.getData3D(type, NaN, 4, colchannel, getDataOptions)), connectionType);
            obj.mibModel.I{obj.mibModel.Id}.maskStat.L = labelmatrix(obj.mibModel.I{obj.mibModel.Id}.maskStat);     % create a label matrix for fast search of the indices
            obj.mibModel.I{obj.mibModel.Id}.maskStat.bb = regionprops(obj.mibModel.I{obj.mibModel.Id}.maskStat, 'BoundingBox');     % create a label matrix for fast search of the indices
            obj.mibModel.I{obj.mibModel.Id}.maskStat = rmfield(obj.mibModel.I{obj.mibModel.Id}.maskStat, 'PixelIdxList');   % remove PixelIdxList it is not needed anymore
end

delete(wb);

end