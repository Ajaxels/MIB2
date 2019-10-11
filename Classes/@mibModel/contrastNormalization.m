function contrastNormalization(obj, target, BatchOptIn)
% function contrastNormalization(obj, target, BatchOptIn)
% Normalize contrast between the layers of the dataset
%
% Parameters:
% target: target for the normalization: 
%   - ''Z stack'' - normalize in the Z-dimension contrast using intensities of each complete slice
%   - ''Time series'' - normalize in the Time-dimension contrast using intensities of each complete slice
%   - ''Masked area'' - normalize contrast using intensities of only masked area at each slice
%   - ''Background'' - shift intensities of each image based on background
%   intensity that is marked as the mask
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Target - cell string, target for the normalization {'Z stack','Time series','Masked area','Background'}
% @li .Mode - cell string, {'Automatic'} or {'Manual'}; use Automatic to calculate Mean/Std or Manual to use predefined values BatchOpt.Mean and BatchOpt.Std
% @li .Mean - string, destination Mean value for the Manual mode
% @li .Std - string, destination Std value for the Manual mode
% @li .ColChannel - cell string,  {'All channels', 'Shown channels', 'ColCh 1'}, define color channels for normalization
% @li .Exculude - cell string, {'Whole range', 'Excude blacks', 'Excude
% whites'} define intensities to exclude from estimation of normalization coefficients
% @li .MaskLayer - cell string,  {'selection', 'mask'} - mask layer for ''Masked area'' and 'Background' modes
% @li .TimeSeriesNormalization - cell string,  {'Based on current 2D slice', 'Based on complete 3D stack'} - for ''Time series'' automatic mode obtain Mean/Std from the current 2D section
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
%
% Return values:
% 
%
%| For @em ''Z stack'' and ''Time series'':
% - calculate mean intensity and its std for the whole dataset (or a current slice for 'Time series', when BatchOpt.TimeSeriesNormalization = {'Based on current 2D slice'})
% - calculate mean intensities and std for each layer
% - shift each layer based on difference between mean values of each
% layer and the whole dataset, plus stretch based on ratio between std of
% the whole dataset and current layer
%
% For @em ''Masked area'':
% - calculate mean intensity for the masked or selected area for the whole dataset
% - calculate mean intensities for the masked or selected area for each layer
% - shift each layer based on difference between mean values of each
% layer and the whole dataset
%
% For @em ''Background'':
% - calculate mean intensity for the masked or selected area for the whole dataset
% - shift each slice by the mean intensity of the masked or selected areas

% Copyright (C) 03.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 27.04.2019, IB updated for the batch mode


global mibPath;

% populate session settings with default values
if ~isfield(obj.sessionSettings, 'normalizationMean')
    obj.sessionSettings.normalizationMean = 30000;     % define mean intensity for manual normalization
    obj.sessionSettings.normalizationStd = 3000;       % define std of intensity for manual normalization
end

%% Declaration of the BatchOpt structure
PossibleColChannels = arrayfun(@(x) sprintf('ColCh %d', x), 1:obj.I{obj.Id}.colors, 'UniformOutput', false);
PossibleColChannels = ['All channels', 'Shown channels', PossibleColChannels];
BatchOpt = struct();
BatchOpt.Target = {target};     % define normalization type
BatchOpt.Target{2} = {'Z stack','Time series','Masked area','Background'};
BatchOpt.Mode = {'Automatic'}; % use Automatic to calculate Mean/Std or Manual to use predefined values BatchOpt.Mean and BatchOpt.Std
BatchOpt.Mode{2} = {'Automatic', 'Manual'};
BatchOpt.Mean = num2str(obj.sessionSettings.normalizationMean); % Destination Mean value for the MAnual mode
BatchOpt.Std = num2str(obj.sessionSettings.normalizationStd);   % Destination Std value for the MAnual mode
BatchOpt.ColChannel = {'All channels'};     % Define color channels for normalization
BatchOpt.ColChannel{2} = PossibleColChannels;
BatchOpt.Exculude = {'Whole range'};        % Define intensities to exclude
BatchOpt.Exculude{2} = {'Whole range', 'Excude blacks', 'Excude whites'};
BatchOpt.MaskLayer = {'selection'};         % Mask layer for ''Masked area'' and 'Background' modes
BatchOpt.MaskLayer{2} = {'selection', 'mask'};
BatchOpt.TimeSeriesNormalization = {'Based on current 2D slice'};   % for ''Time series'' automatic mode obtain Mean/Std from the current 2D section
BatchOpt.TimeSeriesNormalization{2} = {'Based on current 2D slice', 'Based on complete 3D stack'};
BatchOpt.id = obj.Id;
BatchOpt.showWaitbar = true;   % show or not the waitbar

BatchOpt.mibBatchSectionName = 'Menu -> Image';
BatchOpt.mibBatchActionName = 'Contrast -> Normalize layers';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Target = sprintf('Normalize Z stack, frames of the time series, obtain normalization coef. from the masked areas (Masked area) or background normalization from the masked areas');
BatchOpt.mibBatchTooltip.Mode = sprintf('In the automatic mode the normalization coefficient are calculated from the stack, while in the manual mode the provided Mean and Std values are used');
BatchOpt.mibBatchTooltip.Mean = sprintf('[Only for Mode->Manual]\nnormalize intensities to this mean value');
BatchOpt.mibBatchTooltip.Std = sprintf('[Only for Mode->Manual]\nnormalize intensities to this std value');
BatchOpt.mibBatchTooltip.ColChannel = sprintf('Color channels for normalization');
BatchOpt.mibBatchTooltip.Exculude = sprintf('Exclude black or while pixels from the calculations of Mean and Std values');
BatchOpt.mibBatchTooltip.MaskLayer = sprintf('[Masked area and Background only]\nspecify the layer to obtain the masked areas');
BatchOpt.mibBatchTooltip.TimeSeriesNormalization = sprintf('[Time series only]\nCalculate mean/std for each 3D stack or only the shown Z-section');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

%%
if nargin == 3  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            eventdata = ToggleEventData(BatchOpt);
            notify(obj, 'syncBatch', eventdata);
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

%%

% check for the virtual stacking mode
if obj.I{BatchOpt.id}.Virtual.virtual == 1
    toolname = 'contrast normalization';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s are not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj, 'stopProtocol');
    return;
end

% check for color type
if strcmp(obj.I{BatchOpt.id}.meta('ColorType'), 'indexed')
    msgbox(sprintf('Please convert to grayscale or truecolor data format first!\nMenu->Image->Mode->'),...
        'Change format!', 'error', 'modal');
    notify(obj, 'stopProtocol');
    return;
end

%% Start the function
[maxH, maxW, maxC, maxZ, maxT] = obj.I{BatchOpt.id}.getDatasetDimensions('image', NaN);

% not batch mode, check for settings
if nargin < 3
    mibInputMultiDlgOpt.WindowStyle = 'normal';
    mibInputMultiDlgOpt.WindowWidth = 1.1;
    switch BatchOpt.Target{1}
        case {'Z stack', 'Time series'}
            prompts = {'Color channel:';
                'Detect automatically or use provided values for average intensity of the stack and its standard deviation'; ...
                'Average stack intensity (only for manual mode):'; 'Std of stack intensity (only for manual mode):'; ...
                'Intensities to consider:';
                'Normalization policy (only for Time Series):'};
            defAns = {[BatchOpt.ColChannel{2}, 1]; [BatchOpt.Mode{2}, 1]; BatchOpt.Mean; BatchOpt.Std; 
                      [BatchOpt.Exculude{2}, 1]; [BatchOpt.TimeSeriesNormalization{2}, 1]};
            dlgTitle = sprintf('%s normalization settings', BatchOpt.Target{1});
            mibInputMultiDlgOpt.PromptLines = [1, 2, 1, 1, 1, 1, 1];
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, mibInputMultiDlgOpt);
            if isempty(answer); return; end
            
            BatchOpt.ColChannel(1) = answer(1);
            BatchOpt.Mode(1) = answer(2);
            BatchOpt.Mean = answer{3};
            BatchOpt.Std = answer{4};
            BatchOpt.Exculude(1) = answer(5);
            BatchOpt.TimeSeriesNormalization(1) = answer(6);
        case 'Masked area'    
            prompts = {'Mask layer:';
                       'Color channel:';
                       'Detect automatically or use provided values for average intensity of the stack and its standard deviation'; ...
                       'Average stack intensity (only for manual mode):'; 'Std of stack intensity (only for manual mode):'; ...
                       'Intensities to consider:'};
            defAns = {[BatchOpt.MaskLayer{2}, 1]; [BatchOpt.ColChannel{2}, 1]; [BatchOpt.Mode{2}, 1]; BatchOpt.Mean; BatchOpt.Std; [BatchOpt.Exculude{2}, 1]};
            dlgTitle = 'Masked based normalization settings';
            mibInputMultiDlgOpt.PromptLines = [1, 1, 2, 1, 1, 1];
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, mibInputMultiDlgOpt);
            if isempty(answer); return; end
            
            BatchOpt.MaskLayer(1) = answer(1);
            BatchOpt.ColChannel(1) = answer(2);
            BatchOpt.Mode(1) = answer(3);
            BatchOpt.Mean = answer{4};
            BatchOpt.Std = answer{5};
            BatchOpt.Exculude(1) = answer(6);
        case 'Background'
            prompts = {'Mask layer:';
                       'Color channel:';
                       'Detect automatically or use provided values for average intensity of the stack and its standard deviation:'; ...
                       'Background intensity (only for manual mode):'};
            defAns = {[BatchOpt.MaskLayer{2}, 1]; [BatchOpt.ColChannel{2}, 1]; [BatchOpt.Mode{2}, 1]; BatchOpt.Mean};
            dlgTitle = 'Background based normalization settings';
            mibInputMultiDlgOpt.PromptLines = [1, 1, 2, 1];
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, mibInputMultiDlgOpt);
            if isempty(answer); return; end
            
            BatchOpt.MaskLayer(1) = answer(1);
            BatchOpt.ColChannel(1) = answer(2);
            BatchOpt.Mode(1) = answer(3);
            BatchOpt.Mean = answer{4};
    end
    
    if strcmp(BatchOpt.Mode{1}, 'Manual')
        obj.sessionSettings.normalizationMean = str2double(BatchOpt.Mean);
        obj.sessionSettings.normalizationStd = str2double(BatchOpt.Std);
    end
end

% check for presence of the mask layer if it is needed
useMask = 0;    % a switch indicating use or not the mask layer
if ismember(BatchOpt.Target{1}, {'Background', 'Masked area'})
    if strcmp(BatchOpt.MaskLayer{1}, 'mask')
        if obj.I{BatchOpt.id}.maskExist == 0
            msgbox(sprintf('!!! Error !!!\n\nNo mask information found!\n\nPlease draw Mask for each slice of the dataset and try again'),...
                'Missing the Mask!', 'error', 'modal');
            notify(obj, 'stopProtocol');
            return;
        end
    end
    useMask = 1;
end

% define time points
t1 = obj.I{BatchOpt.id}.getCurrentTimePoint();
t2 = t1;
z1 = 1;
z2 = maxZ;

if strcmp(BatchOpt.Target{1}, 'Time series') && obj.I{BatchOpt.id}.time > 1
    if strcmp(BatchOpt.TimeSeriesNormalization{1}, 'Based on current 2D slice')
        z1 = obj.I{BatchOpt.id}.getCurrentSliceNumber();
        z2 = z1;
    end
    t1 = 1;
    t2 = maxT;
end

if t1 == t2; obj.mibDoBackup('image', 1, BatchOpt); end   % do backup

% % detect whether it is possible to work with full dataset
% useFullDatasetSwitch = 0;
% if ispc   % memory is only available for windows
%     [userview, systemview] = memory;
%     datasetMemory = obj.I{BatchOpt.id}.getDatasetSizeInBytes();   % get physical size of datasets
%     if (systemview.PhysicalMemory.Available - userview.MemUsedMATLAB) / datasetMemory > 1
%         useFullDatasetSwitch = 1;
%     end
% end


%% --------------------
% use the slice-by-slice mode, because it seems to be faster for most cases
% the whole dataset mode make sense for the datasets with a very many sections

tic;
if BatchOpt.showWaitbar; wb = waitbar(0, sprintf('Normalizing dataset slice by slice\nPlease wait...'), 'Name', 'Normalizing layers...'); end

% obtain the color channel
switch BatchOpt.ColChannel{1}
    case 'All channels'
        colorChannel = 1:obj.I{BatchOpt.id}.colors;
    case 'Shown channels'
        colorChannel = maxC;
    otherwise
        colorChannel = str2double(BatchOpt.ColChannel{1}(7:end));
end

% check for exclude option
switch BatchOpt.Exculude{1}
    case 'Whole range'
        outliers = [];
    case 'Excude blacks'
        outliers = 0;
    case 'Excude whites'
        outliers  = obj.I{BatchOpt.id}.meta('MaxInt');
end

counter = 1;
maxC = numel(colorChannel);

if BatchOpt.showWaitbar; waitbar(0.01, wb); end

maxWaitbarIndex = maxZ*maxT*maxC;   % max index for the waitbar
MeanValsString = '';    % a string for storing mean values
StdValsString = '';    % a string for storing std values

% get target Mean and Std values for the Manual mode
imgMean = str2double(BatchOpt.Mean);
imgStd = str2double(BatchOpt.Std);

maxWaitbarValue = numel(colorChannel)*(t2-t1+1)*2;  % max waitbar value for Time series
waitbarIndex = 1;
options.id = BatchOpt.id;
for colCh = 1:numel(colorChannel)
    if ~strcmp(BatchOpt.Target{1}, 'Time series')
        mean_val = zeros(maxZ, 1);
        std_val = zeros(maxZ, 1);

        for t=t1:t2
            options.t = [t t];
            % calculate sdt and mean
            for z=z1:z2
                curr_img = cell2mat(obj.getData2D('image', z, NaN, colorChannel(colCh), options));

                if useMask == 0
                    if isempty(outliers)
                        mean_val(z) = mean2(curr_img);
                        std_val(z) = std2(curr_img);
                    else
                        if outliers == 0
                            mean_val(z) = mean(curr_img(curr_img>0));
                            std_val(z) = std(double(curr_img(curr_img>0)));
                        else
                            mean_val(z) = mean(curr_img(curr_img<outliers));
                            std_val(z) = std(double(curr_img(curr_img<outliers)));
                        end
                    end
                else
                    mask = cell2mat(obj.getData2D(BatchOpt.MaskLayer{1}, z, NaN, colorChannel(colCh), options));
                    if max(mask(:)) == 0
                        mean_val(z) = NaN;
                        std_val(z) = NaN;
                        continue;
                    end
                    mean_val(z) = mean2(curr_img(mask==1));
                    std_val(z) = std2(curr_img(mask==1));
                end
            end

            % find nan indices
            nanIds = find(isnan(mean_val));
            valIds = find(~isnan(mean_val));
            
            if strcmp(BatchOpt.Mode{1}, 'Automatic') 
                imgMean = mean(mean_val(valIds));
                imgStd = mean(std_val(valIds));
            end
            
            if isempty(MeanValsString)
                MeanValsString = sprintf('%.0f', imgMean);
                StdValsString = sprintf('%.0f', imgStd);
            else
                MeanValsString = sprintf('%s, %.0f', MeanValsString, imgMean);
                StdValsString = sprintf('%s, %.0f', StdValsString, imgStd);
            end
            
            fprintf('Contrast normalization: ColChL %d, Mean value: %f\n', colorChannel(colCh), imgMean);
            fprintf('Contrast normalization: ColChL %d, Std value: %f\n', colorChannel(colCh), imgStd);
            
            % fill gaps in the vectors
            for i=1:numel(nanIds)
                valIndex = find(valIds > nanIds(i), 1);
                if isempty(valIndex)
                    valIndex = find(valIds < nanIds(i), 1, 'last');
                end
                mean_val(nanIds(i)) = mean_val(valIds(valIndex));
                std_val(nanIds(i)) = std_val(valIds(valIndex));
            end

            if strcmp(BatchOpt.Target{1}, 'Background')    % intensities based on mean background value in the mask area
                for z=z1:z2
                    curr_img = cell2mat(obj.getData2D('image', z, NaN, colorChannel(colCh), options));
                    curr_img = double(curr_img) - mean_val(z) + imgMean;
                    obj.setData2D('image', curr_img, z, NaN, colorChannel(colCh), options);
                    if BatchOpt.showWaitbar; if mod(counter,10)==0; waitbar(counter/maxWaitbarIndex,wb); end; end
                    counter = counter + 1;
                end
            else
                for z=z1:z2
                    ratio = imgStd/std_val(z);
                    curr_img = cell2mat(obj.getData2D('image', z, NaN, colorChannel(colCh), options));
                    I1 = double(curr_img) - mean_val(z);
                    I1 = I1 * ratio;

                    if isempty(outliers)
                        curr_img = I1 + imgMean;
                    else
                        if outliers == 0
                            curr_img(curr_img>0) = I1(curr_img>0) + imgMean;
                        else
                            curr_img(curr_img<outliers) = I1(curr_img<outliers) + imgMean;
                        end
                    end
                    obj.setData2D('image', curr_img, z, NaN, colorChannel(colCh), options);

                    if BatchOpt.showWaitbar; if mod(counter,10)==0; waitbar(counter/maxWaitbarIndex,wb); end; end
                    counter = counter + 1;
                end
            end
        end
    else
        mean_val = zeros(maxT, 1);
        std_val = zeros(maxT, 1);
        for t=t1:t2
            options.t = [t t];
            if strcmp(BatchOpt.TimeSeriesNormalization, 'Based on current 2D slice')
                curr_img = double(cell2mat(obj.getData2D('image', z1, NaN, colorChannel(colCh), options)));
            else
                curr_img = double(cell2mat(obj.getData3D('image', t, colorChannel(colCh))));
            end
            mean_val(t) = mean(curr_img(:));
            std_val(t) = std(curr_img(:));
            if BatchOpt.showWaitbar 
                waitbar(waitbarIndex/maxWaitbarValue,wb); 
                waitbarIndex = waitbarIndex + 1;
            end
        end
        
        if strcmp(BatchOpt.Mode{1}, 'Automatic') 
            imgMean = mean(mean_val);
            imgStd = mean(std_val);
        end

        for t=t1:t2
            options.t = [t t];
            ratio = imgStd/std_val(t);
            for z=1:maxZ
                curr_img = cell2mat(obj.getData2D('image', z, NaN, colorChannel(colCh), options));
                I1 = double(curr_img) - mean_val(t);
                I1 = I1 * ratio;
                curr_img = I1 + imgMean;
                obj.setData2D('image', curr_img, z, NaN, colorChannel(colCh), options);
            end
            if BatchOpt.showWaitbar 
                waitbar(waitbarIndex/maxWaitbarValue,wb); 
                waitbarIndex = waitbarIndex + 1;
            end
        end
        MeanValsString = sprintf('%.0f', imgMean);
        StdValsString = sprintf('%.0f', imgStd);
        
    end
end

% update the log
log_text = sprintf('Normalize %s, mode: %s, Ch: %s, Mean: %s, Std: %s', BatchOpt.Target{1}, BatchOpt.Mode{1}, num2str(colorChannel), MeanValsString, StdValsString);
obj.I{BatchOpt.id}.updateImgInfo(log_text);

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);
notify(obj, 'plotImage');  % notify to plot the image

if BatchOpt.showWaitbar; delete(wb); end
toc
end