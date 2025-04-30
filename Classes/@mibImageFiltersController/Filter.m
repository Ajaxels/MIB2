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

function img = Filter(obj, img, batchModeSwitch)
% function Filter(obj, img, batchModeSwitch)
% filter image using the selected filter
%
% Parameters:
% img: [@em optional], an image to filter, normally should be empty, in
% this case the parameters are taken from obj.BatchOpt structure
% batchModeSwitch: [@em optional], a logical switch indicating the use of
% the batch mode

%if obj.BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'My plugin'); end

if nargin < 3; batchModeSwitch = 0; end
if nargin < 2; img = []; end

% generate BatchOptOut structure
%obj.BatchOpt.ImageFilters.(obj.BatchOpt.FilterName{1}) = obj.ImageFilters.(obj.BatchOpt.FilterName{1});
BatchOptOut = obj.BatchOpt;

% % add parameters of the selected filter to the BatchOptOut structure
if batchModeSwitch == 0     % no need in the batch mode, because all parameters are provided
    ImageFiltersFields = fieldnames(obj.ImageFilters.(BatchOptOut.FilterName{1}));
    for i=1:numel(ImageFiltersFields)
        if strcmp(ImageFiltersFields{i}, 'mibBatchTooltip'); continue; end     % do not keep mibTooltips, it will be added in obj.returnBatchOpt function
        BatchOptOut.(ImageFiltersFields{i}) = obj.ImageFilters.(BatchOptOut.FilterName{1}).(ImageFiltersFields{i});
    end
end

obj.ImageFilters.DesiredFilterName = BatchOptOut.FilterName{1}; % update the last used filter name

% check parameters
if strcmp(BatchOptOut.FilterName{1}, 'DistanceMap')
    % check source layer and method
    errorMessage = [];
    if BatchOptOut.Mode3D == 1 && ~strcmp(BatchOptOut.Method{1}, 'euclidean')
        errorMessage = sprintf('!!! Warning !!!\n\nDistanceMap in the 3D mode is implemented only for the "euclidean" method!\nPlease chanage the Method field to "euclidean" or switch off 3D and try again');
    end
    if strcmp(BatchOptOut.SourceLayer{1}, 'image')
        errorMessage = sprintf('!!! Error !!!\n\nThe source layer for the DistanceMap filter should be one of these: "selection", "mask", or "model"');
    end
    if ~isempty(errorMessage )
        uialert(obj.View.gui, ...
            errorMessage, 'Wrong parameters!');
        return;
    end
end

returnBatchSettings = 0;    % switch to return settings to the mibBatchController
if isempty(img)
    % check for the virtual stacking mode and close the controller if the plugin is not compatible with the virtual stacking mode
    if isprop(obj.mibModel.I{obj.BatchOpt.id}, 'Virtual') && obj.mibModel.I{obj.BatchOpt.id}.Virtual.virtual == 1
        warndlg(sprintf('!!! Warning !!!\n\nThis tool is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
            'Not implemented');
        notify(obj.mibModel, 'stopProtocol'); % notify to stop execusion of the protocol
        obj.closeWindow();
        return;
    end

    getDataOptions.roiId = [];
    getDataOptions.id = obj.BatchOpt.id;
    
    if strcmp(BatchOptOut.FilterGroup{1}, 'Image Binarization')
        backupLayer = BatchOptOut.DestinationLayer{1};
    else
        backupLayer = BatchOptOut.SourceLayer{1};
    end
    % define if full backup is needed
    if strcmp(BatchOptOut.FilterName{1}, 'ElasticDistortion') && BatchOptOut.DistortAllLAyers
        backupLayer = 'mibImage';
    end
    if strcmp(BatchOptOut.FilterName{1}, 'DistanceMap')
        backupLayer = 'mibImage';
    end
    
    switch obj.BatchOpt.DatasetType{1}
        case '2D, Slice'
            obj.mibModel.mibDoBackup(backupLayer, 0, getDataOptions);
            timeVector = [obj.mibModel.I{obj.BatchOpt.id}.getCurrentTimePoint(), obj.mibModel.I{obj.BatchOpt.id}.getCurrentTimePoint()];
        case '3D, Stack'
            obj.mibModel.mibDoBackup(backupLayer, 1, getDataOptions);
            timeVector = [obj.mibModel.I{obj.BatchOpt.id}.getCurrentTimePoint(), obj.mibModel.I{obj.BatchOpt.id}.getCurrentTimePoint()];
        case '4D, Dataset'
            timeVector = [1, obj.mibModel.I{obj.BatchOpt.id}.time];
            %options.showWaitbar = 0;    % do not show waitbar in the filtering function
            %showWaitbarLocal = 1;
            %wb = waitbar(0,['Applying ' options.fitType ' filter...'], 'Name', 'Filtering', 'WindowStyle', 'modal');
    end
    returnBatchSettings = 1;    % return settings to BatchController
end

% check for 3D mode
if BatchOptOut.Mode3D == 1 && ismember(BatchOptOut.FilterName{1}, obj.Filters3D) == 0
    errordlg(sprintf('!!! Error !!!\n\nThe selected filter (%s) is only available in 2D mode!\nPlease change Mode3D parameter to false', BatchOptOut.FilterName{1}));
    return;
end

% filter the provided img
t1 = tic;
if ~isempty(img)
    BatchOptOut.ColorChannel{1} = 1;
    BatchOptOut.Mode3D = false;
    % check for RGB images
    if isfield(BatchOptOut, 'useRGB') && BatchOptOut.useRGB == 1
        if size(img,3) ~= 3; return; end
    end
    
    switch BatchOptOut.ActionToResult{1}
        case 'Fitler image'
            img = mibDoImageFiltering2(img, BatchOptOut, obj.mibModel.cpuParallelLimit);
        case 'Filter and add'
            imgOut = mibDoImageFiltering2(img, BatchOptOut, obj.mibModel.cpuParallelLimit);
            img = img + imgOut;
        case 'Filter and subtract'
            imgOut = mibDoImageFiltering2(img, BatchOptOut, obj.mibModel.cpuParallelLimit);
            img = img - imgOut;
    end
    if size(img, 4)+size(img, 3) > 2; toc; end
    return;
end

% get color channels
switch BatchOptOut.ColorChannel{1}
    case 'All'
        colChannel = 0;
    case 'Displayed'
        colChannel = NaN;
    otherwise
        colChannel = str2double(BatchOptOut.ColorChannel{1});
end
if strcmp(BatchOptOut.SourceLayer{1}, 'model') %&& ~strcmp(BatchOptOut.FilterName{1}, 'ElasticDistortion')
    colChannel = str2double(BatchOptOut.MaterialIndex);
end

% define layers to be processed
if strcmp(BatchOptOut.FilterName{1}, 'ElasticDistortion') && BatchOptOut.DistortAllLAyers
    if obj.mibModel.I{obj.BatchOpt.id}.modelType == 63
        sourceLayersList = {'image', 'everything'};
    else
        sourceLayersList = {'image', 'model', 'mask'};
    end
else
    sourceLayersList = BatchOptOut.SourceLayer(1);
end

for sourceLayerId = 1:numel(sourceLayersList)
    BatchOptOut.SourceLayer(1) = sourceLayersList(sourceLayerId);
    for t=timeVector(1):timeVector(2)
        if ~strcmp(BatchOptOut.DatasetType{1}, '2D, Slice')
            img = obj.mibModel.getData3D(sourceLayersList{sourceLayerId}, t, NaN, colChannel, getDataOptions);
        else
            getDataOptions.t = [t t];
            img = obj.mibModel.getData2D(sourceLayersList{sourceLayerId}, obj.mibModel.I{obj.BatchOpt.id}.getCurrentSliceNumber(), NaN, colChannel, getDataOptions);
        end

        if strcmp(BatchOptOut.FilterGroup{1}, 'Image Binarization') && size(img{1}, 3) > 1
            errordlg(sprintf('!!! Error !!!\n\nPlease select a single color channel before binarization'), 'Too many color channels');
            return;
        end

        % add the following code inside the new imageFilter function
        for roi = 1:numel(img)
            if ismember(BatchOptOut.FilterName{1}, {'SlicClustering', 'WatershedClustering'}) % adjust the image and convert to 8bit
                currViewPort = obj.mibModel.I{obj.mibModel.Id}.viewPort;
                if colChannel == 0  % define index of the color channel
                    col_channel = 1;
                else
                    col_channel = colChannel;
                end
                if isa(img{roi}, 'uint16')
                    if obj.mibModel.mibLiveStretchCheck   % on fly mode
                        for sliceId=1:size(img{roi}, 4)
                            img{roi}(:,:,1,sliceId) = imadjust(img{roi}(:,:,1,sliceId), stretchlim(img{roi}(:,:,1,sliceId),[0 1]),[]);
                        end
                    else
                        for sliceId=1:size(img{roi}, 4)
                            img{roi}(:,:,1,sliceId) = imadjust(img{roi}(:,:,1,sliceId), [currViewPort.min(col_channel)/65535 currViewPort.max(col_channel)/65535],[0 1],currViewPort.gamma(col_channel));
                        end
                    end
                    img{roi} = uint8(img{roi}/255);
                else
                    if currViewPort.min(col_channel) > 1 || currViewPort.max(col_channel) < 255
                        for sliceId=1:size(img{roi}, 4)
                            img{roi}(:,:,1,sliceId) = imadjust(img{roi}(:,:,1,sliceId), [currViewPort.min(col_channel)/255 currViewPort.max(col_channel)/255],[0 1],currViewPort.gamma(col_channel));
                        end
                    end
                end
            end

            switch BatchOptOut.ActionToResult{1}
                case 'Fitler image'
                    [img{roi}, log_text] = mibDoImageFiltering2(img{roi}, BatchOptOut, obj.mibModel.cpuParallelLimit);
                case 'Filter and add'
                    [imgOut, log_text] = mibDoImageFiltering2(img{roi}, BatchOptOut, obj.mibModel.cpuParallelLimit);
                    img{roi} = img{roi}+imgOut;
                case 'Filter and subtract'
                    [imgOut, log_text] = mibDoImageFiltering2(img{roi}, BatchOptOut, obj.mibModel.cpuParallelLimit);
                    img{roi} = img{roi}-imgOut;
            end
            if ~strcmp(sourceLayersList{sourceLayerId}, 'image') && ~ismember(BatchOptOut.FilterName{1}, {'DistanceMap'})
                img{roi} = squeeze(img{roi});
            end
        end

        if ismember(BatchOptOut.FilterName{1}, {'DistanceMap'})
            % apply result to the image layer
            % convert image to a different class
            if strcmp(obj.mibModel.I{obj.mibModel.Id}.meta('imgClass'), class(img{1}(1))) == 0
                convertOpt.showWaitbar = true;
                obj.mibModel.I{obj.mibModel.Id}.convertImage(class(img{1}(1)), convertOpt);
                notify(obj.mibModel, 'newDatasetLite');
            end
            if strcmp(BatchOptOut.DatasetType{1}, '2D, Slice')
                obj.mibModel.setData2D('image', img, obj.mibModel.I{obj.BatchOpt.id}.getCurrentSliceNumber(), NaN, 1, getDataOptions);
            else
                obj.mibModel.setData3D('image', img, t, NaN, 1, getDataOptions);
            end
        elseif ~ismember(BatchOptOut.FilterName{1}, obj.BinarizationFiltersList)
            if strcmp(BatchOptOut.FilterName{1}, 'MathOps')
                if ~strcmp(class(img{1}), obj.mibModel.I{obj.mibModel.Id}.meta('imgClass'))
                    % convert the current image into the new output format
                    obj.mibModel.I{obj.mibModel.Id}.convertImage(class(img{1}));
                end
            end
            if ~strcmp(BatchOptOut.DatasetType{1}, '2D, Slice')
                obj.mibModel.setData3D(sourceLayersList{sourceLayerId}, img, t, NaN, colChannel, getDataOptions);
            else
                obj.mibModel.setData2D(sourceLayersList{sourceLayerId}, img, obj.mibModel.I{obj.BatchOpt.id}.getCurrentSliceNumber(), NaN, colChannel, getDataOptions);
            end
        else    % for binarization filters
            if strcmp(BatchOptOut.DestinationLayer{1}, 'model')
                if isa(img{1}, 'uint16'); ModelType = 65535; else; ModelType = 4294967295; end  % define model type
                if ~strcmp(BatchOptOut.DatasetType{1}, '2D, Slice')
                    obj.mibModel.createModel(ModelType);
                    obj.mibModel.setData3D(BatchOptOut.DestinationLayer{1}, img, t, NaN, NaN, getDataOptions);
                else
                    if obj.mibModel.I{obj.mibModel.Id}.modelType ~= ModelType
                        obj.mibModel.createModel(ModelType);
                    end
                    obj.mibModel.setData2D(BatchOptOut.DestinationLayer{1}, img, obj.mibModel.I{obj.BatchOpt.id}.getCurrentSliceNumber(), NaN, NaN, getDataOptions);
                end 
                notify(obj.mibModel, 'showModel');
            else
                if ~strcmp(BatchOptOut.DatasetType{1}, '2D, Slice')
                    obj.mibModel.setData3D(BatchOptOut.DestinationLayer{1}, img, t, NaN, NaN, getDataOptions);
                else
                    obj.mibModel.setData2D(BatchOptOut.DestinationLayer{1}, img, obj.mibModel.I{obj.BatchOpt.id}.getCurrentSliceNumber(), NaN, NaN, getDataOptions);
                end 
                if strcmp(BatchOptOut.DestinationLayer{1}, 'mask'); notify(obj.mibModel, 'showMask'); end
            end
        end

        %     if showWaitbarLocal == 1
        %         waitbar(t/(timeVector(2)-timeVector(1)),wb);
        %     end
    end
end
if strcmp(BatchOptOut.DatasetType{1}, '2D, Slice')
    log_text = [log_text ', slice=' num2str(obj.mibModel.I{obj.BatchOpt.id}.getCurrentSliceNumber())];
end
if isnan(log_text); return; end
if ~strcmp(BatchOptOut.FilterGroup{1}, 'Image Binarization') && ~ismember(BatchOptOut.SourceLayer{1}, {'selection', 'mask', 'model'})
    obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(log_text);    % update the log
end
toc(t1);
%if obj.BatchOpt.showWaitbar; delete(wb); end

% count user's points
obj.mibModel.preferences.Users.Tiers.numberOfImageFilterings = obj.mibModel.preferences.Users.Tiers.numberOfImageFilterings+1;
eventdata = ToggleEventData(2);    % scale scoring by factor 2
notify(obj.mibModel, 'updateUserScore', eventdata);

% redraw the image if needed
notify(obj.mibModel, 'plotImage');

% for batch need to generate an event and send the BatchOptLoc
% structure with it to the macro recorder / mibBatchController
if returnBatchSettings; obj.returnBatchOpt(BatchOptOut); end
end