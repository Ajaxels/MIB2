function menuDatasetTrasform_Callback(obj, mode, BatchOpt)
% function menuDatasetTrasform_Callback(obj, mode, BatchOpt)
% a callback to Menu->Dataset->Transform...
% do different transformation with the dataset
%
% Parameters:
% mode: a string with a transormation mode:
% @li 'Add frame (width/height)', add a frame around the dataset by providing new width and height
% @li 'Add frame (dX/dY)', add a frame around the dataset by providing vertical and horizontal shifts
% @li 'Flip horizontally', flip the dataset horizontally
% @li 'Flip vertically', flip the dataset vertically
% @li 'Flip Z', flip the Z-stacks of the dataset
% @li 'Flip T', flip the time vector of the dataset
% @li 'Rotate 90 degrees', rotate dataset 90 degrees clockwise
% @li 'Rotate -90 degrees', rotate dataset 90 degrees counterclockwise
% @li 'Transpose XY -> ZX', transpose the dataset so that YX->XZ
% @li 'Transpose XY -> ZY', transpose the dataset so that YX->YZ
% @li 'Transpose ZX -> ZY', transpose the dataset so that XZ->YZ
% @li 'Transpose Z<->T', transpose the dataset so that Z->T
% BatchOpt: a structure for batch processing mode

% Copyright (C) 01.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 13.03.2018 IB, added Add Frame mode
% 12.03.2019, IB updated for the batch mode

% check for the virtual stacking mode and close the controller
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    toolname = 'transformations';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s are not yet available in the virtual stacking mode\nplease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end
obj.mibModel.U.clearContents(); % clear undo history
PossibleOptions = {'Flip horizontally', 'Flip vertically', 'Flip Z', 'Flip T', ...
    'Rotate 90 degrees', 'Rotate -90 degrees', ...
    'Transpose XY -> ZX', 'Transpose XY -> ZY', 'Transpose ZX -> ZY', 'Transpose Z<->T'};
PossibleOptinsPosition = {'Center', 'Left-upper corner', 'Right-upper corner', 'Left-bottom corner','Right-bottom corner'};


if nargin == 3
    if isstruct(BatchOpt) == 0
        if isnan(BatchOpt)     % when varargin{3} == NaN return possible settings
            BatchOpt = struct();
            BatchOpt.showWaitbar = true;   % show or not the waitbar
            BatchOpt.mibBatchSectionName = 'Menu Dataset';
            if isempty(mode)
                BatchOpt.Transform = {'Flip horizontally'};
                BatchOpt.Transform{2} = PossibleOptions;
                BatchOpt.mibBatchActionName = 'Transform...';
            else
                options.blockModeSwitch = 0;
                [height, width] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, 0, options);
                switch mode
                    case 'Add frame (width/height)'
                        BatchOpt.mibBatchActionName = 'Transform... --> Add frame (width/height)';
                        BatchOpt.Position = {'Center'};
                        BatchOpt.Position{2} = PossibleOptinsPosition;
                        BatchOpt.NewImageWidth = num2str(width);
                        BatchOpt.NewImageHeight = num2str(height);
                        BatchOpt.FrameColorIntensity = '0';
                    case 'Add frame (dX/dY)'
                        BatchOpt.mibBatchActionName = 'Transform... --> Add frame (dX/dY)';
                        BatchOpt.FrameWidth = '10';
                        BatchOpt.FrameHeight = '10';
                        BatchOpt.IntensityPadValue = num2str(intmax(obj.mibModel.I{obj.mibModel.Id}.meta('imgClass')));
                        BatchOpt.Method = {'use the pad value'};
                        BatchOpt.Method{2} = {'use the pad value', 'replicate', 'circular', 'symmetric'};
                        BatchOpt.Direction = {'both'};
                        BatchOpt.Direction{2} = {'both', 'pre', 'post'};
                end
            end
            
            % trigger syncBatch event to send BatchOptOut to mibBatchController
            eventdata = ToggleEventData(BatchOpt);
            notify(obj.mibModel, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 3rd parameter is required!'));
        end
        return;
    end
end

if nargin < 3
    BatchOpt = struct();
    BatchOpt.mibBatchSectionName = 'Menu Dataset';
    BatchOpt.showWaitbar = true;   % show or not the waitbar

    switch mode
        case {'Flip horizontally', 'Flip vertically', 'Flip Z', 'Flip T'}
            BatchOpt.mibBatchActionName = 'Transform...';
            BatchOpt.Transform = {mode};
            BatchOpt.Transform{2} = PossibleOptions;
        case {'Rotate 90 degrees', 'Rotate -90 degrees'}
            BatchOpt.mibBatchActionName = 'Transform...';
            BatchOpt.Transform = {mode};
            BatchOpt.Transform{2} = PossibleOptions;
        case {'Transpose XY -> ZX', 'Transpose XY -> ZY','Transpose ZX -> ZY','Transpose Z<->T'}
            BatchOpt.mibBatchActionName = 'Transform...';
            BatchOpt.Transform = {mode};
            BatchOpt.Transform{2} = PossibleOptions;
    end
end

switch mode
    case {'Flip horizontally', 'Flip vertically', 'Flip Z', 'Flip T'}
        obj.mibModel.flipDataset(BatchOpt.Transform{1}, BatchOpt.showWaitbar);
        BatchOpt.mibBatchActionName = 'Transform...';
        BatchOpt.Transform{2} = PossibleOptions;
    case {'Rotate 90 degrees', 'Rotate -90 degrees'}
        obj.mibModel.rotateDataset(BatchOpt.Transform{1}, BatchOpt.showWaitbar);
        BatchOpt.mibBatchActionName = 'Transform...';
        BatchOpt.Transform{2} = PossibleOptions;
    case {'Transpose XY -> ZX', 'Transpose XY -> ZY','Transpose ZX -> ZY','Transpose Z<->T'}
        obj.mibModel.transposeDataset(BatchOpt.Transform{1}, BatchOpt.showWaitbar);
        BatchOpt.mibBatchActionName = 'Transform...';
        BatchOpt.Transform{2} = PossibleOptions;
    case 'Add frame (width/height)'
        BatchOpt = obj.mibModel.I{obj.mibModel.Id}.addFrameToImage(BatchOpt);
        BatchOpt.mibBatchActionName = 'Transform... --> Add frame (width/height)';
        BatchOpt.Position{2} = PossibleOptinsPosition;
        notify(obj.mibModel, 'newDataset');  % notify newDataset with the index of the dataset
        obj.plotImage();
    case 'Add frame (dX/dY)'
        if ~isfield(BatchOpt, 'FrameWidth')
            BatchOpt = obj.mibModel.addFrame();
        else
            BatchOpt = obj.mibModel.addFrame(BatchOpt);
        end
        BatchOpt.mibBatchActionName = 'Transform... --> Add frame (dX/dY)';
end

% trigger syncBatch event to send BatchOptOut to mibBatchController 
% add position of the Plugin in the Menu Plugins
BatchOpt.mibBatchSectionName = 'Menu Dataset';
eventdata = ToggleEventData(BatchOpt);
notify(obj.mibModel, 'syncBatch', eventdata);

end