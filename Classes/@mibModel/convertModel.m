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

function convertModel(obj, ModelType, BatchOptIn)
% function convertModel(obj, ModelType, BatchOptIn)
% convert model to the specified type
%
% Parameters:
% ModelType: a double that specifies new type of the model, can be @em empty, @em default = 63
% @li 63 - model with 63 materials, the fastest to use, utilize less memory
% @li 255 - model with 255 materials, the slower to use, utilize x2 more memory than 63-material type
% @li 65535 - model with 65535 materials, utilize x2 more memory than 255-material type
% @li 4294967295 - model with 4294967295 materials, utilize x2 more memory than 65535-material type
% @li 2.4 - detect all 2D objects (connectivity 4) in all materials of the current model and generate a new model, where each object has an unique index
% @li 2.8 - detect all 2D objects (connectivity 8) in all materials of the current model and generate a new model, where each object has an unique index
% @li 3.6 - detect all 3D objects (connectivity 6) in all materials of the current model and generate a new model, where each object has an unique index
% @li 3.26 - detect all 3D objects (connectivity 26) in all materials of the current model and generate a new model, where each object has an unique index
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .ModelType - cell string, {'63', '255', '65535', '4294967295', 
%     'indexed objects 2D/4', 'indexed objects 2D/6', 'indexed objects 3D/8', 'indexed objects 3D/26'} - type of the model to convert to
% @li .ContainerId - cell string, {'Container %d'} - container, where to do conversion
% @li .showWaitbar - logical, show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset

% Updates
% 04.12.2017, IB, added 4294967295 materials
% 11.06.2019, IB, moded from mibController and updated for the batch mode
% 26.03.2022, IB added 2.4, 2.6, 3.8, 3.26 model types

if nargin < 2; ModelType = []; end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
if ~isempty(ModelType)
    switch ModelType
        case 2.4
            BatchOpt.ModelType = {'indexed objects 2D/4'};
        case 2.8
            BatchOpt.ModelType = {'indexed objects 2D/8'};
        case 3.6
            BatchOpt.ModelType = {'indexed objects 3D/6'};
        case 3.26
            BatchOpt.ModelType = {'indexed objects 3D/26'};
        otherwise
            BatchOpt.ModelType = {num2str(ModelType)};
    end
else
    BatchOpt.ModelType = {'63'};
end
BatchOpt.ModelType{2} = {'63', '255', '65535', '4294967295', ...
    'indexed objects 2D/4', 'indexed objects 2D/8', 'indexed objects 3D/6', 'indexed objects 3D/26'};

BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Models';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Convert type';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.ModelType = sprintf('Specify type of the new model; the model type indicates the maximum number of materials. More materials require more memory and slower to work with');
BatchOpt.mibBatchTooltip.ContainerId = sprintf('Use "Current" to convert the currently shown model, or specify the index of the container with the model');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');


%% Batch mode check actions
if nargin == 3  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 4rd parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    end
end

%%
switch BatchOpt.ModelType{1}
    case 'indexed objects 2D/4'
        ModelType = 2.4;
    case 'indexed objects 2D/8'
        ModelType = 2.8;
    case 'indexed objects 3D/6'
        ModelType = 3.6;
    case 'indexed objects 3D/26'
        ModelType = 3.26;
    otherwise
        ModelType = str2double(BatchOpt.ModelType{1});
end
if ModelType == obj.I{BatchOpt.id}.modelType
    % nothing to convert
    return;
end
obj.I{BatchOpt.id}.convertModel(ModelType);
notify(obj, 'newDataset');

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);

notify(obj, 'plotImage');
end