function mibRemoveMaterialBtn_Callback(obj, BatchOptIn)
% function mibRemoveMaterialBtn_Callback(obj, BatchOptIn)
% callback to the obj.mibView.handles.mibRemoveMaterialBtn, remove material from the model
%
%
% Parameters:
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .MaterialIndices - a string, indices of materials to be removed
% @li .showWaitbar - logical, show or not the waitbar
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.mibRemoveMaterialBtn_Callback();     // add material to the model @endcode
 
% Copyright (C) 29.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 16.08.2017 IB added waitbar
% 15.11.2018, IB, added selection of materials
% 11.01.2019, IB improved performance
% 13.09.2019, IB updated for the batch mode

global mibPath;
if nargin < 2; BatchOptIn = struct(); end
unFocus(obj.mibView.handles.mibRemoveMaterialBtn); % remove focus from hObject

%% Declaration of the BatchOpt structure
BatchOpt = struct();
BatchOpt.MaterialIndices = '';   % name of the new material
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.mibModel.Id;   % optional, id

if obj.mibModel.I{BatchOpt.id}.selectedMaterial >= 3
    BatchOpt.MaterialIndices = num2str(obj.mibModel.I{BatchOpt.id}.getSelectedMaterialIndex());
end  

BatchOpt.mibBatchSectionName = 'Panel -> Segmentation';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Remove material';
BatchOpt.mibBatchTooltip.MaterialIndices = sprintf('Indices of materials to be removed from the model');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');


% do nothing is selection is disabled
if obj.mibModel.I{BatchOpt.id}.disableSelection == 1
    warndlg(sprintf('The models are switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),'The models are disabled');
    notify(obj.mibModel, 'stopProtocol');
    return;
end

if nargin == 2  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj.mibModel, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 2nd parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    end
    BatchModeSwitch = 1;
else
    prompts = {sprintf('Specify indices of materials to be removed\n(for example, 2,4,6:8)')};
    defAns = {BatchOpt.MaterialIndices};
    dlgTitle = 'Delete materials';
    options.WindowStyle = 'modal'; 
    options.PromptLines = 2;  
    answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
    if isempty(answer); return; end
    BatchOpt.MaterialIndices = answer{1};
    BatchModeSwitch = 0;
end

MaterialIndices = str2num(BatchOpt.MaterialIndices); %#ok<ST2NM>
if isempty(MaterialIndices) 
    warndlg(sprintf('Wrong material name: "%s"\nThe function requires a list of numbers, for example "1, 2, 3:5"', BatchOpt.MaterialIndices), 'Remove material');
    notify(obj.mibModel, 'stopProtocol');
    return;
end

modelMaterialNames = obj.mibModel.I{BatchOpt.id}.modelMaterialNames;    % list of materials of the model
if BatchModeSwitch == 0
    matListString = sprintf('%s, ', modelMaterialNames{MaterialIndices});
    matIndexString = sprintf('%d, ', MaterialIndices);
    msg = sprintf('You are going to delete material(s):\n"%s",\nwith indices: %s\n\nAre you sure?', matListString(1:end-2), matIndexString(1:end-2));
    button =  questdlg(msg, 'Delete materials?', 'Yes', 'Cancel', 'Cancel');
    if strcmp(button, 'Cancel') == 1; return; end
end

if BatchOpt.showWaitbar; wb = waitbar(0, sprintf('Deleting materials\nPlease wait...'), 'Name', 'Deleting materials'); end
%MaterialIndices = sort(MaterialIndices, 'descend');
MaterialIndices = sort(MaterialIndices);
keepMaterials = 1:numel(obj.mibModel.I{BatchOpt.id}.modelMaterialNames);
keepMaterials(ismember(keepMaterials, MaterialIndices)) = [];

options.blockModeSwitch=0;
options.id = BatchOpt.id;
if BatchOpt.showWaitbar; waitbar(0.05, wb); end
tic
maxIndex = obj.mibModel.I{BatchOpt.id}.time;
for t=1:maxIndex
    model2 = cell2mat(obj.mibModel.getData3D('model', t, 4, NaN, options));
    if obj.mibModel.I{BatchOpt.id}.modelType < 256
        [logicalMember, indexValue] = ismember(model2, keepMaterials);
        model = zeros(size(model2), class(model2));
        model(logicalMember==1) = indexValue(logicalMember==1);
        obj.mibModel.setData3D('model', model, t, 4, NaN, options);
    else
        model2(ismember(model2, MaterialIndices)) = 0;
        obj.mibModel.setData3D('model', model2, t, 4, NaN, options);
    end
    if BatchOpt.showWaitbar; waitbar(t/maxIndex , wb); end
end
clear model2;
if obj.mibModel.I{BatchOpt.id}.modelType < 256
    obj.mibModel.I{BatchOpt.id}.modelMaterialColors(MaterialIndices,:) = [];  % remove color of the removed material
    obj.mibModel.I{BatchOpt.id}.modelMaterialNames(MaterialIndices) = [];  % remove material name from the list of materials
    obj.updateSegmentationTable();
    obj.mibModel.I{BatchOpt.id}.lastSegmSelection = [2 1];
end
toc

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj.mibModel, 'syncBatch', eventdata);

if BatchOpt.showWaitbar; delete(wb); end
obj.plotImage(0);
end