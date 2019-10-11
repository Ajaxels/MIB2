function result = menuDatasetParameters_Callback(obj, pixSize, BatchOptIn)
% function result = menuDatasetParameters_Callback(obj, pixSize, BatchOptIn)
% a callback for MIB->Menu->Dataset->Parameters
%
% Parameters:
% pixSize: - [@e optional], a structure with new parameters, may have the following fields
% - @b .x - physical voxel size in X, a number
% - @b .y - physical voxel size in Y, a number
% - @b .z - physical voxel size in Z, a number 
% - @b .t - time difference between the frames, a number 
% - @b .units - physical units for voxels, (m, cm, mm, um, nm)
% - @b .tunits - time unit 
% BatchOptIn: a structure for batch processing mode, when NaN return
% a structure with default options via "syncBatch" event
% @li .VoxelX - string, physical voxel size in X
% @li .VoxelY - string, physical voxel size in Y
% @li .VoxelZ - string, physical voxel size in Z
% @li .VoxelT - string, time difference between the frames
% @li .Units - cell string, {'m','cm','mm','um','nm'} - identifier of physical units
% @li .TimeUnits - string, identifier of time units
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset

% Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% `

result = 0;

% specify default BatchOptIn
PossibleOptions = {'m','cm','mm','um','nm'};
pixSizeTemp = obj.mibModel.I{obj.mibModel.Id}.pixSize;
BatchOpt = struct();
BatchOpt.VoxelX = num2str(pixSizeTemp.x);
BatchOpt.VoxelY = num2str(pixSizeTemp.y);
BatchOpt.VoxelZ = num2str(pixSizeTemp.z);
BatchOpt.VoxelT = num2str(pixSizeTemp.t);
BatchOpt.Units = {'um'};
BatchOpt.Units{2} = PossibleOptions;
BatchOpt.TimeUnits = 's';
BatchOpt.id = obj.mibModel.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Dataset';
BatchOpt.mibBatchActionName = 'Parameters';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.VoxelX = sprintf('Specify voxel size in the X-dimension');
BatchOpt.mibBatchTooltip.VoxelY = sprintf('Specify voxel size in the Y-dimension');
BatchOpt.mibBatchTooltip.VoxelZ = sprintf('Specify voxel size in the Z-dimension');
BatchOpt.mibBatchTooltip.VoxelT = sprintf('Specify time step for time series');
BatchOpt.mibBatchTooltip.Units = sprintf('Physical units used for calibration');
BatchOpt.mibBatchTooltip.TimeUnits = sprintf('Time units');

if nargin == 3  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
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

if nargin < 2
    result = obj.mibModel.I{BatchOpt.id}.updatePixSizeResolution();
else
    if isempty(pixSize)
        pixSize = struct();
        pixSize.x = str2double(BatchOpt.VoxelX);
        pixSize.y = str2double(BatchOpt.VoxelY);
        pixSize.z = str2double(BatchOpt.VoxelZ);
        pixSize.t = str2double(BatchOpt.VoxelT);
        pixSize.units = BatchOpt.Units{1};
        pixSize.tunits = BatchOpt.TimeUnits;
    end
    result = obj.mibModel.I{BatchOpt.id}.updatePixSizeResolution(pixSize);    
end

if result == 1
    pixSize = obj.mibModel.I{BatchOpt.id}.pixSize;
    BatchOpt.VoxelX = num2str(pixSize.x);
    BatchOpt.VoxelY = num2str(pixSize.y);
    BatchOpt.VoxelZ = num2str(pixSize.z);
    BatchOpt.VoxelT = num2str(pixSize.t);
    BatchOpt.Units = {pixSize.units};
    BatchOpt.Units{2} = PossibleOptions;
    BatchOpt.TimeUnits = pixSize.tunits;
    
    obj.updateAxesLimits([], BatchOpt.id);
    
    % notify the batch mode
    BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
    eventdata = ToggleEventData(BatchOpt);
    notify(obj.mibModel, 'syncBatch', eventdata);
    obj.plotImage(1);
end
end
