function mibBufferToggle_Callback(obj, Id, BatchOptIn)
% function mibBufferToggle_Callback(obj, Id, BatchOptIn)
% a callback to press of obj.mibView.handles.mibBufferToggle button
%
% Parameters:
% Id: index of the pressed toggle button
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables

% Copyright (C) 04.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 07.08.2019 updated for the batch mode

if nargin < 2; Id = '1'; end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
if ~isempty(Id)
    BatchOpt.ContainerId = {Id};
else
    BatchOpt.ContainerId = {num2str(obj.mibModel.Id)};
end
BatchOpt.ContainerId{2} = arrayfun(@(x) sprintf('%d', x), 1:obj.mibModel.maxId, 'UniformOutput', false);
BatchOpt.mibBatchSectionName = 'Panel -> Directory contents';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Change container';
BatchOpt.mibBatchTooltip.ContainerId = sprintf('Index of the container to select');

%% Batch mode check actions
if nargin == 3  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            eventdata = ToggleEventData(BatchOpt);
            notify(obj.mibModel, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 3rd parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    end
end


%% start function

obj.mibView.imh = matlab.graphics.primitive.Image('CData', []); 
Id = str2double(BatchOpt.ContainerId{1});
obj.updateShownId(Id);

% force button to be pressed, when using the batch mode
eval(sprintf('obj.mibView.handles.mibBufferToggle%d.Value = 1;', Id));

[path, fn, ext] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
if ~isempty(path);     obj.mibModel.myPath = path;   end
obj.updateFilelist([fn, ext]);
end