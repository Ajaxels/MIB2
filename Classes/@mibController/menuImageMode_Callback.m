function status = menuImageMode_Callback(obj, hObject, BatchOptIn)
% function status = menuImageMode_Callback(obj, hObject, BatchOptIn)
% callback to the Menu->Image->Mode, convert image to different formats
%
% Parameters:
% hObject: handle to the selected menu entry
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Target - cell string, {'Grayscale', 'RGB Color', 'HSV Color', 'Indexed', '8 bit', '16 bit', '32 bit'} - convert dataset to one of these options
% @li .showWaitbar - logical, show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
% 
% Return values:
% status: result of the funtion, 1-success, 0-fail
%| 
% @b Examples:
% @code 
% // for the batch mode
% BatchOptIn.Target = {'Grayscale'};     // define to where convert the dataset
% obj.menuImageMode_Callback([], BatchOptIn); // call from mibController class;
% @endcode


% Copyright (C) 03.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 12.03.2019, IB updated for the batch mode

status = 0;
if nargin < 3; BatchOptIn = struct; end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
BatchOpt.Target = {'Grayscale'};
BatchOpt.Target{2} = {'Grayscale', 'RGB Color', 'HSV Color', 'Indexed', '8 bit', '16 bit', '32 bit'};
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.mibModel.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Image'; % define secion name for the Batch mode
BatchOpt.mibBatchActionName = 'Mode';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Target = sprintf('Possible modes for image conversion');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

if nargin == 3 % batch mode 
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
end

% check for the virtual stacking mode and close the controller
if obj.mibModel.I{BatchOpt.id}.Virtual.virtual == 1
    toolname = 'image conversion tools';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s are not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj.mibModel, 'stopProtocol');
    return;
end

if nargin < 3
    switch get(hObject,'tag')
        case 'menuImageGrayscale'
            BatchOpt.Target{1} = 'Grayscale';
        case 'menuImageRGBColor'
            BatchOpt.Target{1} = 'RGB Color';
        case 'menuImageHSVColor'
            BatchOpt.Target{1} = 'HSV Color';
        case 'menuImageIndexed'
            BatchOpt.Target{1} = 'Indexed';
        case 'menuImage8bit'
            BatchOpt.Target{1} = '8 bit';
        case 'menuImage16bit'
            BatchOpt.Target{1} = '16 bit';
        case 'menuImage32bit'
            BatchOpt.Target{1} = '32 bit';
    end
end

if obj.mibModel.I{BatchOpt.id}.time < 2
    backupOpt.id = BatchOpt.id;
    obj.mibModel.mibDoBackup('image', 1, backupOpt); 
end    
convertOpt.showWaitbar = BatchOpt.showWaitbar;
switch BatchOpt.Target{1}
    case 'Grayscale'
        if strcmp(obj.mibModel.I{BatchOpt.id}.meta('ColorType'), 'truecolor') && obj.mibModel.I{BatchOpt.id}.colors > 3
            if ~isfield(BatchOptIn, 'mibBatchTooltip')  % standard mode
                button = questdlg(sprintf('!!! Attention !!!\n\nDirect conversion of the multichannel image to greyscale is not possible\nHowever it is possible to perform conversion using the LUT colors'),'Multiple color channels','Convert','Cancel','Cancel');
                if strcmp(button, 'Cancel'); return; end
                if obj.mibModel.I{BatchOpt.id}.useLUT == 0
                    errordlg('Please make sure that the LUT checkbox in the View settings panel is checked!','LUT is not selected');
                    return;
                end
            end
            obj.mibModel.I{BatchOpt.id}.useLUT = 0;
            obj.View.handles.mibLutCheckbox.Value = 0;
        end
        status = obj.mibModel.I{BatchOpt.id}.convertImage('grayscale', convertOpt);
    case 'RGB Color'
        status = obj.mibModel.I{BatchOpt.id}.convertImage('truecolor', convertOpt);
    case 'HSV Color'
        status = obj.mibModel.I{BatchOpt.id}.convertImage('hsvcolor', convertOpt);
    case 'Indexed'
        if strcmp(obj.mibModel.I{BatchOpt.id}.meta('ColorType'), 'truecolor') && obj.mibModel.I{BatchOpt.id}.colors > 3
            if ~isfield(BatchOptIn, 'mibBatchTooltip')  % standard mode
                button = questdlg(sprintf('!!! Attention !!!\n\nDirect conversion of the multichannel image to greyscale is not possible\nHowever it is possible to perform conversion using the LUT colors'),...
                    'Multiple color channels', 'Convert', 'Cancel', 'Cancel');
                if strcmp(button, 'Cancel'); return; end
                if obj.mibModel.I{BatchOpt.id}.useLUT == 0
                    errordlg('Please make sure that the LUT checkbox in the View settings panel is checked!','LUT is not selected');
                    return;
                end
            end
            obj.mibModel.I{BatchOpt.id}.useLUT = 0;
            obj.View.handles.mibLutCheckbox.Value = 0;
        end
        status = obj.mibModel.I{BatchOpt.id}.convertImage('indexed', convertOpt);
    case '8 bit'
        status = obj.mibModel.I{BatchOpt.id}.convertImage('uint8', convertOpt);
    case '16 bit'
        status = obj.mibModel.I{BatchOpt.id}.convertImage('uint16', convertOpt);
    case '32 bit'
        status = obj.mibModel.I{BatchOpt.id}.convertImage('uint32', convertOpt);
end

if status == 0; notify(obj.mibModel, 'stopProtocol'); end

BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj.mibModel, 'syncBatch', eventdata);

obj.updateGuiWidgets();
obj.plotImage();
end