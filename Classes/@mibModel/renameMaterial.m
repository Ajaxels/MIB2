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

function renameMaterial(obj, BatchOptIn)
% function renameMaterial(obj, BatchOptIn)
% rename selected or any specified material of the model
%
% Parameters:
% BatchOptIn: [@em optional], a structure with extra parameters or settings for the batch processing mode, when NaN return
%    a structure with default options via "syncBatch" event
% optional parameters
% @li .materialIndex -> index of material to rename, when 0 rename all
% materials, in this case the "newMaterialName" field needs to be populated with
% material names separated with commas
% @li .newMaterialName - string, a new name for the material or the list of new names separated with commas

% Updates
% 

global mibPath; % path to mib installation folder

% do nothing is selection is disabled
if obj.I{obj.Id}.enableSelection == 0; return; end
if obj.I{obj.Id}.modelExist == 0; return; end

if nargin < 2; BatchOptIn = struct(); end

BatchOpt = struct();
contIndex = max([1 obj.I{obj.Id}.selectedMaterial - 2]);   % do not change to obj.I{obj.Id}.getSelectedMaterialIndex() here!
BatchOpt.materialIndex = num2str(contIndex);
segmList = obj.getImageProperty('modelMaterialNames');
BatchOpt.newMaterialName = segmList{contIndex};
BatchOpt.mibBatchTooltip.materialIndex = 'Index of material to rename, when 0 rename all materials, in this case the "newMaterialName" field needs to be populated with material names separated with commas';
BatchOpt.mibBatchTooltip.newMaterialName = sprintf('New name for the material or the list of new names separated with commas');
BatchOpt.mibBatchSectionName = 'Panel -> Segmentation';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Rename material';

%% Batch mode check actions
if nargin == 2  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            eventdata = ToggleEventData(BatchOpt);
            notify(obj, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 2nd parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    end
else    % call from the segmentation popup menu
    answer = mibInputDlg({mibPath}, sprintf('Please add a new name for this material:'), 'Rename material', BatchOpt.newMaterialName);
    if isempty(answer); return; end
    
    BatchOpt.newMaterialName = answer{1};
end

materialId = str2num(BatchOpt.materialIndex); %#ok<ST2NM> 
if sum(isnan(materialId)) > 0
    errordlg(sprintf('!!! Error !!!\n\nWrong material index(es)\nPlease enter a numeric value(s)!'), 'Wrong material index', 'non-modal');
    return;
end

newMatNames = strsplit(BatchOpt.newMaterialName, ',');
newMatNames = strtrim(newMatNames);
newMatNames = newMatNames';
if materialId == 0  % rename all material names
    if numel(newMatNames) ~= numel(segmList)
        errordlg(sprintf('!!! Error !!!\n\nNumber of new material names should match number of materials (%d) in the table!', numel(segmList)), ...
            'Rename material', 'non-modal');
        return;
    end
    segmList = newMatNames;
else
    segmList(materialId) = newMatNames;
end

if obj.I{obj.Id}.modelType > 255
    materialId = round(str2double(newMatNames));
    if sum(isnan(materialId)) > 0
        errordlg(sprintf('!!! Error !!!\n\nWrong material index\nPlease enter a numeric value!'), 'Wrong material index', 'modal'); 
        return; 
    end
end

obj.setImageProperty('modelMaterialNames', segmList);

% update segmentation table
motifyEvent.Name = 'updateSegmentationTable';
eventdata = ToggleEventData(motifyEvent);
notify(obj, 'modelNotify', eventdata);

% notify the batch mode
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);




