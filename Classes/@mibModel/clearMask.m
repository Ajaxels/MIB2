function clearMask(obj, BatchOptIn)
% function clearMask(obj, BatchOptIn)
% clear the Mask layer
%
% Parameters:
% BatchOptIn: [@em optional], a structure with extra parameters or settings for the batch processing mode, when NaN return
%    a structure with default options via "syncBatch" event
% optional parameters
% @li .y -> [@em optional], [ymin, ymax] coordinates of the dataset to take after transpose for level=1, height
% @li .x -> [@em optional], [xmin, xmax] coordinates of the dataset to take after transpose for level=1, width
% @li .z -> [@em optional], [zmin, zmax] coordinates of the dataset to take after transpose, depth
% @li .t -> [@em optional], [tmin, tmax] coordinates of the dataset to take after transpose, time
% @li .id -> [@em optional], index of the dataset to clear the mask

% Copyright (C) 08.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

BatchOpt = struct();
BatchOpt.Info = 'no parameters for this function';
BatchOpt.id = obj.Id;   % default BatchOpt.id
BatchOpt.mibBatchTooltip.Info = 'compatible with .x .y .z. .t .id fields';

BatchOpt.mibBatchSectionName = 'Menu -> Mask';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Clear mask';

%% Batch mode check actions
if nargin == 2  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');
            eventdata = ToggleEventData(BatchOpt);
            notify(obj, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    end
end

if isfield(BatchOpt, 'x') || isfield(BatchOpt, 'y') || isfield(BatchOpt, 'z') || isfield(BatchOpt, 't')
    obj.mibDoBackup('mask', 1, BatchOpt);
    obj.I{BatchOpt.id}.clearMask(BatchOpt);
else
    obj.mibDoBackup('mask', 1, BatchOpt);
    obj.I{BatchOpt.id}.clearMask();
end
notify(obj, 'showMask');
notify(obj, 'plotImage');

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);

end