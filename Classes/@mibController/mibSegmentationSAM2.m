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
% Date: 12.08.2024

function mibSegmentationSAM2(obj, extraOptions, BatchOptIn)
% function mibSegmentationSAM2(obj, extraOptions, BatchOptIn)
% Perform segmentation using segment-anything-2 model https://github.com/facebookresearch/segment-anything-2
%
% Parameters:
% extraOptions: structure with additional options
%  @li .addNextMaterial, [logical], switch to add next material for the "add, +next material" mode
% BatchOptIn: structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Method - Specify method how SAM should be executed
%       -> "Interactive", by interactively adding point
%       -> "Landmarks", process the placed points all at once
%       -> "Automatic everything", automatically segment all objects on the image
% @li .Dataset - segment the current slice (2D, Slice), current stack (3D, Stack) or the whole dataset(4D, Dataset)
% @li .Destination - string with MIB layer to apply results of the segmentation (selection, mask, model)
% @li .showWaitbar - Show or not the progress bar during execution
% Return values:
%

% Updates
%

if nargin < 2; extraOptions = []; end

if isempty(extraOptions); extraOptions = struct(); end
if ~isfield(extraOptions, 'addNextMaterial'); extraOptions.addNextMaterial = true; end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
BatchOpt.id = obj.mibModel.Id;   % optional, id
BatchOpt.Method = obj.mibView.handles.mibSegmSAMMethod.String(obj.mibView.handles.mibSegmSAMMethod.Value);
BatchOpt.Method{2} = {'Interactive', 'Interactive 3D', 'Landmarks', 'Automatic everything'};
BatchOpt.Dataset = obj.mibView.handles.mibSegmSAMDataset.String(obj.mibView.handles.mibSegmSAMDataset.Value);     % '2D, Slice', '3D, Stack', '4D, Dataset'
BatchOpt.Dataset{2} = {'2D, Slice', '3D, Stack', '4D, Dataset'};
BatchOpt.Destination = obj.mibView.handles.mibSegmSAMDestination.String(obj.mibView.handles.mibSegmSAMDestination.Value);     % {'selection', 'mask', 'model'}'
BatchOpt.Destination{2} = {'selection', 'mask', 'model'};
BatchOpt.Mode = obj.mibView.handles.mibSegmSAMMode.String(obj.mibView.handles.mibSegmSAMMode.Value);    % 'replace', 'add', 'subtract'
BatchOpt.Mode{2} = {'replace', 'add', 'subtract'};
BatchOpt.showWaitbar = true;   % show or not the waitbar

BatchOpt.mibBatchSectionName = 'Panel -> Segmentation';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Segment-anything model';

% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Method = sprintf('Specify method how SAM should be executed');
BatchOpt.mibBatchTooltip.Dataset = sprintf('Apply SAM for the current slice (2D, Slice), current stack (3D, Stack) or the whole dataset(4D, Dataset)');
BatchOpt.mibBatchTooltip.Destination = sprintf('Destination layer for the results');

% do backup of the current state
doBackup = true;

%% Batch mode check actions
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
    if ismember(BatchOpt.Method{1}, {'Interactive'})
        errordlg(sprintf('"%s" mode is not available in the batch processing mode!', BatchOpt.Method{1}));
        return;
    end
end

% check for the virtual stacking mode and return
if obj.mibModel.I{BatchOpt.id}.Virtual.virtual == 1
    toolname = 'segment-everything-2 model is';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode!\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

% check for switch that disables segmentation tools
if obj.mibModel.disableSegmentation == 1; return; end

methodToUse = find(ismember(BatchOpt.Method{2}, BatchOpt.Method{1})); % 1, 2, 3, 4: ['Interactive', 'Interactive 3D', 'Landmarks', 'Automatic everything'
% create a new model. if needed
switch BatchOpt.Method{1}
    case 'Automatic everything'
        if obj.mibModel.I{BatchOpt.id}.modelExist
            if obj.mibModel.I{BatchOpt.id}.modelType == 65353
                obj.mibModel.createModel(65535);
            elseif (~strcmp(BatchOpt.Dataset{1}, '2D, Slice') && obj.mibModel.I{BatchOpt.id}.depth > 1) || ...
                    (strcmp(BatchOpt.Dataset{1}, '2D, Slice') && obj.mibModel.I{BatchOpt.id}.depth == 1)
                obj.mibModel.createModel(65535);
            end
        else
            obj.mibModel.createModel(65535);
        end
    otherwise
        if strcmp(BatchOpt.Destination{1}, 'model')
            if numel(obj.mibModel.I{BatchOpt.id}.modelMaterialNames) == 0
                msgbox(sprintf('Please create the Model and add there a material first!\n\nPress the "+" in the Segmentation panel'), 'The model is missing!', 'warn');
                return;
            end
            if obj.mibModel.I{BatchOpt.id}.selectedMaterial < 2; return; end
        end
end

% init python environment
if isempty(obj.mibModel.mibPython)
    % check python requirements
    samVersion = 2;
    status = obj.mibSegmentationSAM_requirements(samVersion);
    if ~status; return; end

    if BatchOpt.showWaitbar
        wb = waitbar(0, sprintf('\n\n'), 'Name', 'SAM2 segmentation');
        wb.Children.Title.Interpreter = 'none';
        waitbar(0, wb, sprintf('Initializing Python environment\n%s\nPlease wait...', obj.mibModel.preferences.SegmTools.SAM2.backbone));
    end

    checkpointFilename = obj.mibModel.sessionSettings.SAMsegmenter.Links.checkpointFilename;
    modelCfgFilename = obj.mibModel.sessionSettings.SAMsegmenter.Links.modelCfgFilename;
    if ~ispc; modelCfgFilename = strrep(modelCfgFilename, '%2B', '+'); end % swap %2B with + for Linux
    %model_type = obj.mibModel.sessionSettings.SAMsegmenter.Links.backbone;

    % path to segment-anything package from github, https://github.com/facebookresearch/segment-anything
    samPath = obj.mibModel.preferences.SegmTools.SAM2.sam_installation_path;

    if ispc() % for PC the full absolute path is used
        model_cfg = fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, modelCfgFilename);
    else
        % for linux it is important to copy *.yaml configs to sam2
        % subfolder of segment-anything-2
        % in this case only modelCfgFilename is used to initalize it
        model_cfg = modelCfgFilename;
    end
    checkpoint = fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, checkpointFilename);

    % enable Focus on value in the annotations panel
    obj.mibModel.mibAnnValueEccentricCheck = true;
    obj.mibView.handles.mibAnnValueEccentricCheck.Value = true;

    %obj.mibModel.mibPython = pyenv( ...
    %    Version=obj.mibModel.preferences.ExternalDirs.PythonInstallationPath, ...
    %   ExecutionMode = 'InProcess');     % InProcess or OutOfProcess

    try
        obj.mibModel.mibPython = pyenv( ...
            'Version', obj.mibModel.preferences.ExternalDirs.PythonInstallationPath, ...
            'ExecutionMode', 'OutOfProcess');     % InProcess or OutOfProcess
    catch err
        if strcmp(err.identifier, 'MATLAB:Pyenv:PythonLoaded')
            terminate(pyenv);
            obj.mibModel.mibPython = pyenv( ...
                'Version', obj.mibModel.preferences.ExternalDirs.PythonInstallationPath, ...
                'ExecutionMode', 'OutOfProcess');     % InProcess or OutOfProcess
        end
    end

    if BatchOpt.showWaitbar; waitbar(0.5, wb); end
    % Add the SAM folder to the Python search path
    % Check if the path is already in py.sys.path
    pyPath = py.sys.path;
    if count(pyPath, samPath) == 0     % add to path
        insert(py.sys.path, int64(0), samPath);
    end

    % import required modules
    pyrun('import torch');
    if BatchOpt.showWaitbar; waitbar(0.7, wb); end
    pyrun('import numpy as np');
    pyrun('from sam2.build_sam import build_sam2');
    if BatchOpt.showWaitbar; waitbar(0.8, wb); end
    pyrun('from sam2.sam2_image_predictor import SAM2ImagePredictor');
    pyrun('from sam2.automatic_mask_generator import SAM2AutomaticMaskGenerator');
    pyrun('from sam2.build_sam import build_sam2_video_predictor');
    if BatchOpt.showWaitbar; waitbar(0.9, wb); end

    % pyrun('torch.autocast(device_type="cuda", dtype=torch.bfloat16).__enter__()');
    pyrun(sprintf('torch.autocast(device_type="%s", dtype=torch.bfloat16).__enter__()', ...
        obj.mibModel.preferences.SegmTools.SAM2.environment));

    % turn on tfloat32 for Ampere GPUs (https://pytorch.org/docs/stable/notes/cuda.html#tensorfloat-32-tf32-on-ampere-devices)
    pyrun(sprintf(['' ...
        'if torch.cuda.get_device_properties(0).major >= 8:\n' ...
        '   torch.backends.cuda.matmul.allow_tf32 = True\n' ...
        '   torch.backends.cudnn.allow_tf32 = True']));

    pyrun(sprintf('checkpoint = "%s"', strrep(checkpoint, '\', '/'))); % checkpoint = "./checkpoints/sam2_hiera_large.pt"
    pyrun(sprintf('model_cfg = "%s"', strrep(model_cfg, '\', '/')));  % model_cfg = "sam2_hiera_tiny.yaml"

    % set predictor status in false state
    pyrun('predictor2D = 0');
    pyrun('predictor3D = 0');
    pyrun('predictorMasks = 0');

    if BatchOpt.showWaitbar; waitbar(1, wb); end
    delete(wb);
end

% init predictors
try
    switch BatchOpt.Method{1}
        case {'Interactive', 'Landmarks'}
            notInitStatus = pyrun('notInitStatus = predictor2D==0', 'notInitStatus');
            if notInitStatus
                if BatchOpt.showWaitbar
                    wb = waitbar(0, sprintf('\n\n'), 'Name', 'SAM2 segmentation');
                    wb.Children.Title.Interpreter = 'none';
                    waitbar(0, wb, sprintf('Initializing SAM2 predictor for %s\n%s\nPlease wait...', BatchOpt.Method{1}, obj.mibModel.preferences.SegmTools.SAM2.backbone));
                    drawnow;
                end
                pyrun(sprintf('sam2_model = build_sam2(model_cfg, checkpoint, device="%s")', obj.mibModel.preferences.SegmTools.SAM2.environment)); % sam2_model = build_sam2(model_cfg, sam2_checkpoint, device="cuda")
                % init predictor for the interactive mode for images
                pyrun('predictor2D = SAM2ImagePredictor(sam2_model)');
            end
        case 'Interactive 3D'
            notInitStatus = pyrun('notInitStatus = predictor3D==0', 'notInitStatus');
            if notInitStatus
                if BatchOpt.showWaitbar
                    wb = waitbar(0, sprintf('\n\n'), 'Name', 'SAM2 segmentation');
                    wb.Children.Title.Interpreter = 'none';
                    waitbar(0, wb, sprintf('Initializing SAM2 predictor for %s\n%s\nPlease wait...', BatchOpt.Method{1}, obj.mibModel.preferences.SegmTools.SAM2.backbone));
                    drawnow;
                end
                % init predictor for the interactive mode for video
                pyrun(sprintf('predictor3D = build_sam2_video_predictor(model_cfg, checkpoint, device="%s")', obj.mibModel.preferences.SegmTools.SAM2.environment));  % predictor = build_sam2_video_predictor(model_cfg, sam2_checkpoint, device=device)
            end
        case 'Automatic everything'
            notInitStatus = pyrun('notInitStatus = predictorMasks==0', 'notInitStatus');
            if notInitStatus
                if BatchOpt.showWaitbar
                    wb = waitbar(0, sprintf('\n\n'), 'Name', 'SAM2 segmentation');
                    wb.Children.Title.Interpreter = 'none';
                    waitbar(0, wb, sprintf('Initializing SAM2 predictor for %s\n%s\nPlease wait...', BatchOpt.Method{1}, obj.mibModel.preferences.SegmTools.SAM2.backbone));
                    drawnow;
                end
                % init mask generator for automatic mode
                %pyrun('predictorMasks = SAM2AutomaticMaskGenerator(sam2_model)');
                pyrun(sprintf('sam2_model = build_sam2(model_cfg, checkpoint, device="%s", apply_postprocessing=False)', obj.mibModel.preferences.SegmTools.SAM2.environment)); % sam2_model = build_sam2(model_cfg, sam2_checkpoint, device="cuda")
                pyrun(['predictorMasks = SAM2AutomaticMaskGenerator(' ...
                    'model = sam2_model, ' ...
                    'points_per_side = pnts_p_side, ' ...
                    'points_per_batch = pnts_p_batch, ' ...
                    'pred_iou_thresh = pred_iou_th, ' ...
                    'stability_score_thresh = st_sco_th, ' ...
                    'stability_score_offset = st_sco_offset, ' ...
                    'crop_n_layers = crop_n_l, ' ...
                    'box_nms_thresh = box_nms_thresh, ' ...
                    'crop_n_points_downscale_factor = crop_n_pnts_downsc_f, ' ...
                    'min_mask_region_area = min_mask_reg_area,' ...
                    'use_m2m = bool(use_m2m),)'], ...
                    pnts_p_side = py.numpy.int32(obj.mibModel.preferences.SegmTools.SAM2.points_per_side), ...
                    pnts_p_batch = py.numpy.int32(obj.mibModel.preferences.SegmTools.SAM2.points_per_batch), ...
                    pred_iou_th = py.numpy.float16(obj.mibModel.preferences.SegmTools.SAM2.pred_iou_thresh), ...
                    st_sco_th = py.numpy.float16(obj.mibModel.preferences.SegmTools.SAM2.stability_score_thresh), ...
                    st_sco_offset = py.numpy.float16(obj.mibModel.preferences.SegmTools.SAM2.stability_score_offset), ...
                    crop_n_l = py.numpy.int32(obj.mibModel.preferences.SegmTools.SAM2.crop_n_layers), ...
                    box_nms_thresh = py.numpy.float16(obj.mibModel.preferences.SegmTools.SAM2.box_nms_thresh), ...
                    crop_n_pnts_downsc_f = py.numpy.int32(obj.mibModel.preferences.SegmTools.SAM2.crop_n_points_downscale_factor), ...
                    min_mask_reg_area = py.numpy.int32(obj.mibModel.preferences.SegmTools.SAM2.min_mask_region_area), ...
                    use_m2m = obj.mibModel.preferences.SegmTools.SAM2.use_m2m);
            end
    end
    if BatchOpt.showWaitbar && exist('wb', 'var'); waitbar(1, wb); delete(wb); end
catch err
    showErrorDialog(obj.mibView.gui, err, 'Problem', '', ...
        'Try to copy yaml configs to the specified SAM2 directory');
    obj.mibModel.mibPython = [];
    if BatchOpt.showWaitbar; delete(wb); end
    return;
end

% define limits
t1 = 1;
t2 = obj.mibModel.I{BatchOpt.id}.time;
if strcmp(BatchOpt.Dataset{1}, '2D, Slice') && methodToUse ~= 2  % not for Interactive 3D
    z1 = obj.mibModel.I{BatchOpt.id}.getCurrentSliceNumber();
    z2 = z1;
else
    switch BatchOpt.Method{1}
        case {'Interactive', 'Interactive 3D'}
            % when click is done on the same slice or when a new click is
            % done with a different value, make 2D segmentation
            if numel(obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(:,3)) > 1 && ...
                    (obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(end,3)-obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(end-1,3) == 0 || ...
                    abs(diff(obj.mibModel.sessionSettings.SAMsegmenter.Points.Value(end-1:end))) == 1)
                z1 = obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(end,3);
                z2 = z1;
            else
                z1 = min(obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(:,3));
                z2 = max(obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(:,3));
            end
        case 'Landmarks'
            z1 = obj.mibModel.I{BatchOpt.id}.hLabels.getMinValueZ();
            z2 = obj.mibModel.I{BatchOpt.id}.hLabels.getMaxValueZ();
        otherwise
            z1 = 1;
            z2 = obj.mibModel.I{BatchOpt.id}.depth;
    end
end
noImages = (z2-z1+1)*(t2-t1+1);

% redefine showing of the progress bar
localWaitbar = BatchOpt.showWaitbar;
if ismember(BatchOpt.Method{1}, {'Interactive', 'Interactive 3D'}) && ~obj.mibModel.preferences.SegmTools.SAM2.showProgressBar && noImages == 1
    localWaitbar = false;
end

if localWaitbar; wb = waitbar(0, sprintf('%s\nPlease wait...', BatchOpt.Method{1}), 'Name', 'Segment anything'); end

getDataOpt.id = BatchOpt.id;

% enable blocked mode switch
getLabelsOpt = struct();
if ismember(BatchOpt.Method{1}, {'Interactive', 'Interactive 3D'})
    getDataOpt.blockModeSwitch = true;

    getLabelsOpt.blockModeSwitch = true;
    getLabelsOpt.shiftCoordinates = true;
    if ismember(BatchOpt.Mode{1}, {'add',  'add, +next material'})
        % do not make backup in this mode
        % as it has already beeen made in mibController.mibGUI_WindowButtonDownFcn
        doBackup = false;
    end
else
    if obj.mibModel.I{BatchOpt.id}.blockModeSwitch
        getLabelsOpt.blockModeSwitch = true;
        getLabelsOpt.shiftCoordinates = true;
    end
end

counter = 0;
tic;

% do backup
if t2-t1 == 0 && doBackup
    getDatasetDimensionsOpt.blockModeSwitch = 0;
    [blockHeight, blockWidth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, NaN, getDatasetDimensionsOpt);
    [axesX, axesY] = obj.mibModel.getAxesLimits();
    backupOptions.x(1) = max([1 ceil(axesX(1))]);
    backupOptions.x(2) = min([ceil(axesX(2)), blockWidth]);
    backupOptions.y(1) = max([1 ceil(axesY(1))]);
    backupOptions.y(2) = min([ceil(axesY(2)), blockHeight]);
    backupOptions.z(1) = z1;
    backupOptions.z(2) = z2;
    if numel(obj.mibModel.sessionSettings.SAMsegmenter.Points.Value) == 1 %#ok<ISCL>
        backupOptions.LinkedData.Points.Position = [];
        backupOptions.LinkedData.Points.Value = [];
    else
        backupOptions.LinkedData.Points.Position = obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(1:end-1,:);
        backupOptions.LinkedData.Points.Value = obj.mibModel.sessionSettings.SAMsegmenter.Points.Value(1:end-1);
    end
    backupOptions.LinkedVariable.Points = 'obj.mibModel.sessionSettings.SAMsegmenter.Points';
    obj.mibModel.mibDoBackup(BatchOpt.Destination{1}, 1, backupOptions);  % do backup
end

% define default output data type when generating data by pointsSAM and pointsVideoSAM
% should be changed when BatchOpt.Mode{1}=='add' and Destination='model';
castDataType = 'uint8';
% modelDataType = 'uint8';
% if obj.mibModel.I{obj.mibModel.Id}.modelType > 256 && obj.mibModel.I{obj.mibModel.Id}.modelType < 65536
%     modelDataType = 'uint16';
% elseif obj.mibModel.I{obj.mibModel.Id}.modelType > 65536
%     modelDataType = 'uint32';
% end
% if (strcmp(BatchOpt.Mode{1}, 'add') || strcmp(BatchOpt.Mode{1}, 'subtract')) ...
%         && strcmp(BatchOpt.Destination{1}, 'model') && obj.mibModel.I{obj.mibModel.Id}.modelType > 256
%     castDataType = modelDataType;
% end

% get current contrast
currViewPort = obj.mibModel.I{BatchOpt.id}.viewPort;
liveStretch = obj.mibModel.mibLiveStretchCheck;
colCh = obj.mibModel.I{BatchOpt.id}.selectedColorChannel;

try
    for t=t1:t2
        getDataOpt.t = [t, t];
        if methodToUse == 2   % 'Interactive 3D'
            % code below is an adapation of video segmentation from SAM2 for 3D microscopy datasets
            % it requires addition of init_state_from_array function into sam2_video_predictor.py in order to work
            % Performance x2 times better:
            % VideoSeg = 10.4328sec
            % SliceBySlice = 20.1215sec

            if localWaitbar && t1==t2 
                waitbar(0.05, wb, sprintf('%s: preparing data\nPlease wait...', BatchOpt.Method{1})); 
                drawnow;
            end

            getDataOpt.z = [z1 z2];
            dataset = cell2mat(obj.mibModel.getData3D('image', t, obj.mibModel.I{BatchOpt.id}.orientation, NaN, getDataOpt));
            % check for correct number of color channels, adjust contast, do image padding and convert to RGB
            [dataset, padSize] = checkAndPreprocessImage(dataset, methodToUse, currViewPort, colCh, liveStretch);
            if isnan(dataset(1))
                if localWaitbar; delete(wb); end
                return;
            end

            % % get indices of the points on the slice where seeds were placed
            % pntIndices = ~isnan(obj.mibModel.sessionSettings.SAMsegmenter.Points.Value);
            % % get positions, keep only x,y,z
            % labelPositions = obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(pntIndices, 1:2);
            % labelValues = obj.mibModel.sessionSettings.SAMsegmenter.Points.Value(pntIndices);

            % get positions, x,y,z
            labelPositions = obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(:, 1:3);
            labelValues = obj.mibModel.sessionSettings.SAMsegmenter.Points.Value;

            % shift coordinates
            labelPositions(:,1) = ceil((labelPositions(:,1) - max([0 floor(obj.mibModel.I{BatchOpt.id}.axesX(1))])) +padSize);     % - .999/obj.magFactor subtract 1 pixel to put a marker to the left-upper corner of the pixel
            labelPositions(:,2) = ceil((labelPositions(:,2) - max([0 floor(obj.mibModel.I{BatchOpt.id}.axesY(1))])) +padSize) ;
            labelPositions(:,3) = labelPositions(:,3) - z1;

            % do SAM2 segmentation using the provided list of points using predictor for video
            
            [h1, w1, c1, d1] = size(dataset);
            % use pre-resizing when h1 or w1 > 1024 
            % to minimize data exchange between MATLAB and Python
            useResize = false; 
            if h1 > 1024 || w1 > 1024; useResize = true; end
            useResize = false;
            if useResize
                dataset2 = zeros([1024 1024 c1 d1], class(dataset));
                scaleH = 1024/h1;
                scaleW = 1024/w1;
                % scale coordinates of seeds
                labelPositions(:,2) = labelPositions(:,2)*scaleH;
                labelPositions(:,1) = labelPositions(:,1)*scaleW;
                for z=1:d1
                    dataset2(:,:,:,z) = imresize(dataset(:,:,:,z), [1024 1024], 'bicubic');
                end
                if localWaitbar && t1==t2 
                    waitbar(0.15, wb, sprintf('%s: starting SAM\nPlease wait...', BatchOpt.Method{1})); 
                end
                dataset2 = pointsVideoSAM(dataset2, labelPositions, labelValues, castDataType);
                if localWaitbar && t1==t2 
                    waitbar(0.9, wb, sprintf('%s: upsampling results\nPlease wait...', BatchOpt.Method{1})); 
                end
                dataset = zeros([h1 w1 d1], class(dataset2));
                sigma = 1/min([scaleH scaleW]);
                for z=1:d1
                    mask = imresize(dataset2(:,:,z), [h1, w1], 'nearest');
                    dataset(:,:,z) = imgaussfilt(mask, sigma); % 'FilterSize', 2*ceil(2*sigma)+1
                end

            else
                if localWaitbar && t1==t2 
                    waitbar(0.15, wb, sprintf('%s: starting SAM\nPlease wait...', BatchOpt.Method{1})); 
                    drawnow;
                end
                dataset = pointsVideoSAM(dataset, labelPositions, labelValues, castDataType);
                if localWaitbar && t1==t2 
                    waitbar(0.9, wb, sprintf('%s: finalizing\nPlease wait...', BatchOpt.Method{1})); 
                end
            end

            dataset = dataset(padSize+1:end-padSize, padSize+1:end-padSize, :, :);    % remove padding    

            % auto fill the shape when auto fill is checked
            if obj.mibView.handles.mibAutoFillCheck.Value
                for z=1:size(dataset, 3)
                    dataset(:,:,z) = imfill(dataset(:,:,z));
                end
            end

            % limit to the selected material of the model
            if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial == true
                %storedImageState = obj.mibModel.sessionSettings.SAMsegmenter.initialImageSelected(obj.mibModel.I{obj.mibModel.Id}.slices{1}(1):obj.mibModel.I{obj.mibModel.Id}.slices{1}(2), ...
                %    obj.mibModel.I{obj.mibModel.Id}.slices{2}(1):obj.mibModel.I{obj.mibModel.Id}.slices{2}(2) );
                %dataset = bitand(dataset, storedImageState);
                dataset = bitand(dataset, obj.mibModel.sessionSettings.SAMsegmenter.initialImageSelected);
            end
            
            selMaterialIndex = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo');
            switch BatchOpt.Mode{1}
                case 'replace'
                    obj.mibModel.setData3D(BatchOpt.Destination{1}, dataset , t, obj.mibModel.I{BatchOpt.id}.orientation, selMaterialIndex, getDataOpt);
                case 'add'
                    % crop the stored image to the current FoV
                    % storedImageState = obj.mibModel.sessionSettings.SAMsegmenter.initialImageAddTo(obj.mibModel.I{obj.mibModel.Id}.slices{1}(1):obj.mibModel.I{obj.mibModel.Id}.slices{1}(2), ...
                    %     obj.mibModel.I{obj.mibModel.Id}.slices{2}(1):obj.mibModel.I{obj.mibModel.Id}.slices{2}(2) );
                    % obj.mibModel.setData2D(BatchOpt.Destination{1}, {bitor(storedImageState, dataset)}, z, NaN, selMaterialIndex, getDataOpt);
                    obj.mibModel.setData3D(BatchOpt.Destination{1}, {bitor(obj.mibModel.sessionSettings.SAMsegmenter.initialImageAddTo, dataset)}, t, obj.mibModel.I{BatchOpt.id}.orientation, selMaterialIndex, getDataOpt);
                case 'subtract'
                    %currLayer = cell2mat(obj.mibModel.getData2D(BatchOpt.Destination{1}, z, NaN, selMaterialIndex, getDataOpt));
                    %obj.mibModel.setData2D(BatchOpt.Destination{1}, {currLayer - imgOut}, z, NaN, selMaterialIndex, getDataOpt);
                    currLayer = cell2mat(obj.mibModel.getData3D(BatchOpt.Destination{1}, t, NaN, selMaterialIndex, getDataOpt));
                    obj.mibModel.setData3D(BatchOpt.Destination{1}, {currLayer - dataset}, t, NaN, selMaterialIndex, getDataOpt);
                case 'add, +next material'
                    %storedImageState = obj.mibModel.sessionSettings.SAMsegmenter.initialImageAddTo(obj.mibModel.I{obj.mibModel.Id}.slices{1}(1):obj.mibModel.I{obj.mibModel.Id}.slices{1}(2), ...
                    %    obj.mibModel.I{obj.mibModel.Id}.slices{2}(1):obj.mibModel.I{obj.mibModel.Id}.slices{2}(2) );
                    %obj.mibModel.setData2D(BatchOpt.Destination{1}, {bitor(storedImageState, imgOut)}, z, NaN, selMaterialIndex, getDataOpt);
                    obj.mibModel.setData3D(BatchOpt.Destination{1}, {bitor(obj.mibModel.sessionSettings.SAMsegmenter.initialImageAddTo, dataset)}, t, NaN, selMaterialIndex, getDataOpt);

                    % add next material
                    if extraOptions.addNextMaterial
                        obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames = {num2str(selMaterialIndex), num2str(selMaterialIndex+1) };
                        eventdata2.Indices = [obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial, 3];
                        if size(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors, 1) < selMaterialIndex+1  % generate a random color
                            obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(selMaterialIndex+1, :) = rand(1,3);
                        end
                        obj.updateSegmentationTable();
                        obj.mibSegmentationTable_CellSelectionCallback(eventdata2);     % update mibSegmentationTable
                    end
            end
        else   % 'Interactive', 'Landmarks', 'Automatic everything'
            for z=z1:z2
                if methodToUse == 3 % landmark mode
                    [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{BatchOpt.id}.getSliceLabels(z, t, getLabelsOpt);
                    if isempty(labelsList)
                        counter = counter + 1;
                        if localWaitbar && mod(counter, 10); waitbar(counter/noImages, wb); end
                        continue;
                    end
                end

                % get image
                imgIn = cell2mat(obj.mibModel.getData2D('image', z, obj.mibModel.I{BatchOpt.id}.orientation, NaN, getDataOpt));
                % check for correct number of color channels, adjust contast, do image padding and convert to RGB
                [imgIn, padSize] = checkAndPreprocessImage(imgIn, methodToUse, currViewPort, colCh, liveStretch);
                if isnan(imgIn(1))
                    if localWaitbar; delete(wb); end
                    return;
                end

                switch methodToUse
                    case 1  % Interactive in-view points
                        % get indices of the points on the current slice
                        pntIndices = obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(:,3) == z;
                        % get positions, keep only x,y
                        labelPositions = obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(pntIndices, 1:2);
                        labelValues = obj.mibModel.sessionSettings.SAMsegmenter.Points.Value(pntIndices);

                        % shift coordinates
                        labelPositions(:,1) = ceil((labelPositions(:,1) - max([0 floor(obj.mibModel.I{BatchOpt.id}.axesX(1))])) +padSize);     % - .999/obj.magFactor subtract 1 pixel to put a marker to the left-upper corner of the pixel
                        labelPositions(:,2) = ceil((labelPositions(:,2) - max([0 floor(obj.mibModel.I{BatchOpt.id}.axesY(1))])) +padSize);

                        % do SAM2 segmentation using the provided list of points

                        [h1, w1, c1, d1] = size(imgIn);
                        % use pre-resizing when h1 or w1 > 1024
                        % to minimize data exchange between MATLAB and Python
                        useResize = false;
                        if h1 > 1024 || w1 > 1024; useResize = true; end
                        if useResize
                            scaleH = 1024/h1;
                            scaleW = 1024/w1;
                            % scale coordinates of seeds
                            labelPositions(:,2) = labelPositions(:,2)*scaleH;
                            labelPositions(:,1) = labelPositions(:,1)*scaleW;
                            
                            imgIn = imresize(imgIn, [1024 1024], 'bicubic');
                            
                            imgOut = pointsSAM(imgIn, labelPositions, labelValues, castDataType);
                            sigma = 1/min([scaleH scaleW]);
                            imgOut = imresize(imgOut, [h1, w1], 'nearest');
                            imgOut = imgaussfilt(imgOut, sigma); % 'FilterSize', 2*ceil(2*sigma)+1
                        else
                            imgOut = pointsSAM(imgIn, labelPositions, labelValues, castDataType);
                        end

                        imgOut = imgOut(padSize+1:end-padSize, padSize+1:end-padSize);    % remove padding
                        % % --- for DEBUG --- %
                        % --- for DEBUG --- % imgOut = zeros([size(imgIn, 1), size(imgIn, 2)], 'uint8');
                        % --- for DEBUG --- % imgOut(imgIn(:,:,1)<imgIn(labelPositions(end,2), labelPositions(end,1), 1)) = 1;

                        % auto fill the shape when auto fill is checked
                        if obj.mibView.handles.mibAutoFillCheck.Value
                            imgOut = imfill(imgOut);
                        end

                        % limit to the selected material of the model
                        if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial == 1
                            %storedImageState = obj.mibModel.sessionSettings.SAMsegmenter.initialImageSelected(obj.mibModel.I{obj.mibModel.Id}.slices{1}(1):obj.mibModel.I{obj.mibModel.Id}.slices{1}(2), ...
                            %    obj.mibModel.I{obj.mibModel.Id}.slices{2}(1):obj.mibModel.I{obj.mibModel.Id}.slices{2}(2) );
                            %imgOut = bitand(imgOut, storedImageState);
                            imgOut = bitand(imgOut, obj.mibModel.sessionSettings.SAMsegmenter.initialImageSelected);
                        end
                        selMaterialIndex = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo');
                        switch BatchOpt.Mode{1}
                            case 'replace'
                                obj.mibModel.setData2D(BatchOpt.Destination{1}, {imgOut}, z, NaN, selMaterialIndex, getDataOpt);
                            case 'add'
                                % crop the stored image to the current FoV
                                %storedImageState = obj.mibModel.sessionSettings.SAMsegmenter.initialImageAddTo(obj.mibModel.I{obj.mibModel.Id}.slices{1}(1):obj.mibModel.I{obj.mibModel.Id}.slices{1}(2), ...
                                %    obj.mibModel.I{obj.mibModel.Id}.slices{2}(1):obj.mibModel.I{obj.mibModel.Id}.slices{2}(2) );
                                %obj.mibModel.setData2D(BatchOpt.Destination{1}, {bitor(storedImageState, imgOut)}, z, NaN, selectedMaterial, getDataOpt);
                                obj.mibModel.setData2D(BatchOpt.Destination{1}, {bitor(obj.mibModel.sessionSettings.SAMsegmenter.initialImageAddTo, imgOut)}, z, NaN, selMaterialIndex, getDataOpt);
                            case 'subtract'
                                currLayer = cell2mat(obj.mibModel.getData2D(BatchOpt.Destination{1}, z, NaN, selMaterialIndex, getDataOpt));
                                obj.mibModel.setData2D(BatchOpt.Destination{1}, {currLayer - imgOut}, z, NaN, selMaterialIndex, getDataOpt);
                            case 'add, +next material'
                                %storedImageState = obj.mibModel.sessionSettings.SAMsegmenter.initialImageAddTo(obj.mibModel.I{obj.mibModel.Id}.slices{1}(1):obj.mibModel.I{obj.mibModel.Id}.slices{1}(2), ...
                                %    obj.mibModel.I{obj.mibModel.Id}.slices{2}(1):obj.mibModel.I{obj.mibModel.Id}.slices{2}(2) );
                                %obj.mibModel.setData2D(BatchOpt.Destination{1}, {bitor(storedImageState, imgOut)}, z, NaN, selMaterialIndex, getDataOpt);
                                obj.mibModel.setData2D(BatchOpt.Destination{1}, {bitor(obj.mibModel.sessionSettings.SAMsegmenter.initialImageAddTo(:,:,z-z1+1), imgOut)}, z, NaN, selMaterialIndex, getDataOpt);
                                
                                % add next material
                                if extraOptions.addNextMaterial
                                    obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames = {num2str(selMaterialIndex), num2str(selMaterialIndex+1) };
                                    eventdata2.Indices = [obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial, 3];
                                    if size(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors, 1) < selMaterialIndex+1  % generate a random color
                                        obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(selMaterialIndex+1, :) = rand(1,3);
                                    end
                                    obj.updateSegmentationTable();
                                    obj.mibSegmentationTable_CellSelectionCallback(eventdata2);     % update mibSegmentationTable
                                end
                        end
                    case 3  % Landmarks
                        % get labels, keep only x,y
                        labelPositions = labelPositions(:,2:3);
                        imgOut = pointsSAM(imgIn, labelPositions, labelValues);
                        % auto fill the shape when auto fill is checked
                        if obj.mibView.handles.mibAutoFillCheck.Value
                            imgOut = imfill(imgOut);
                        end

                        switch BatchOpt.Mode{1}
                            case 'replace'
                                obj.mibModel.setData2D(BatchOpt.Destination{1}, {imgOut}, z, NaN, obj.mibModel.I{BatchOpt.id}.selectedAddToMaterial-2, getDataOpt);
                            case 'add'
                                currLayer = cell2mat(obj.mibModel.getData2D(BatchOpt.Destination{1}, z, NaN, obj.mibModel.I{BatchOpt.id}.selectedAddToMaterial-2, getDataOpt));
                                obj.mibModel.setData2D(BatchOpt.Destination{1}, {bitor(currLayer, imgOut)}, z, NaN, obj.mibModel.I{BatchOpt.id}.selectedAddToMaterial-2, getDataOpt);
                            case 'subtract'
                                currLayer = cell2mat(obj.mibModel.getData2D(BatchOpt.Destination{1}, z, NaN, obj.mibModel.I{BatchOpt.id}.selectedAddToMaterial-2, getDataOpt));
                                obj.mibModel.setData2D(BatchOpt.Destination{1}, {currLayer - imgOut}, z, NaN, obj.mibModel.I{BatchOpt.id}.selectedAddToMaterial-2, getDataOpt);
                        end
                    case 4  % Automatic everything
                        masks = pyrun('masks = predictorMasks.generate(image)', 'masks', image=py.numpy.array(imgIn));
                        for maskId=1:double(py.len(masks))
                            currentMask = uint8(masks{maskId}{'segmentation'});
                            if maskId==1; modelOut = zeros(size(currentMask), 'uint16'); end
                            modelOut(currentMask==1) = maskId;
                        end
                        obj.mibModel.setData2D('model', {modelOut}, z, NaN, NaN, getDataOpt);
                end
                counter = counter + 1;
                if localWaitbar && mod(counter, 10); waitbar(counter/noImages, wb); end
            end
        end
    end
catch err
    showErrorDialog(obj.mibView.gui, err, 'Problem', '', ...
        'You might be running out of GPU memory; try to decrease "Set the number of points run simultaneously by the model in SAM settings"');
    if localWaitbar; delete(wb); end
    return;

end
toc

% count user's points
obj.mibModel.preferences.Users.Tiers.numberOfSAMclicks = obj.mibModel.preferences.Users.Tiers.numberOfSAMclicks+1;
eventdata = ToggleEventData(2);    % scale scoring by factor 2
notify(obj.mibModel, 'updateUserScore', eventdata);

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj.mibModel, 'syncBatch', eventdata);
if strcmp(BatchOpt.Destination{1}, 'mask')
    notify(obj.mibModel, 'showMask');   % turn on the show mask checkbox
end

notify(obj.mibModel, 'plotImage');
if localWaitbar; delete(wb); end

end

function [imgIn, padSize] = checkAndPreprocessImage(imgIn, methodToUse, currViewPort, colCh, liveStretch)
% function imgIn = checkAndPreprocessImage(imgIn, methodToUse)
% check for correct number of color channels, adjust
% contast, do image padding and convert to RGB
%
% Parameters:
% imgIn: matrix [height, width, colors, colors] to check and process
% methodToUse: index of the SAM2 method that was used, 1-Interactive, 2-Interactive 3D, 3-Landmarks, 4-Automatic
%
% Return values:
% imgIn: converted image
% padSize: size of padding used for the Interactive mode
% currViewPort: current viewport settings, comes from obj.mibModel.I{BatchOpt.id}.viewPort as
% .min
% .max
% .gamma
% colCh: selected color channels
% liveStretch: [logical] switch to automatically stretch the contrast

padSize = 0;
if size(imgIn, 3) ~= 1 && size(imgIn, 3) ~= 3
    errordlg(sprintf('!!! Error !!!\n\nSegmentation using segment-everything model is only available for grayscale and RGB images\nFor multi-channel images select a single channel in the Colors table and try again!'), ...
        'SAM segmentation error');
    imgIn = NaN;
    return;
end

% convert to 8bit
if ~isa(imgIn, 'uint8')
    max_int = double(intmax(class(imgIn)));
    if liveStretch
        for z=1:size(imgIn, 4)
            for i=1:size(imgIn,3)
                imgIn(:,:,i,z) = imadjust(imgIn(:,:,i,z), stretchlim(imgIn(:,:,i,z), [0 1]), []);
            end
        end
        imgIn = uint8(imgIn/256);
    else
        % convert to the 8bit image
        if size(imgIn, 3) == 1
            %colCh = obj.mibModel.I{BatchOpt.id}.selectedColorChannel;
            if currViewPort.min(colCh) ~= 0 || currViewPort.max(colCh) ~= max_int || currViewPort.gamma(colCh) ~= 1
                for z=1:size(imgIn, 4)
                    imgIn(:,:,:,z) = imadjust(imgIn(:,:,:,z), [currViewPort.min(colCh)/max_int currViewPort.max(colCh)/max_int], [0 1], currViewPort.gamma(colCh));
                end
            end
        else
            if max(currViewPort.min) > 0 || min(currViewPort.max) ~= max_int || sum(currViewPort.gamma) ~= 3
                for z=1:size(imgIn, 4)
                    for colCh=1:3
                        imgIn(:,:,colCh,z) = imadjust(imgIn(:,:,colCh,z), [currViewPort.min(colCh)/max_int currViewPort.max(colCh)/max_int], [0 1], currViewPort.gamma(colCh));
                    end
                end
            end
        end
        imgIn = uint8(imgIn/256);
    end
end

% add padding to minimize edge artefacts
if methodToUse == 1 || methodToUse == 2  % 'Interactive', 'Interactive 3D'
    padSize = ceil(size(imgIn, 2)/256);
    imgIn = padarray(imgIn, [padSize padSize], 'symmetric', 'both');
end

% convert to RGB
if size(imgIn, 3) == 1 %#ok<ISMAT>
    imgIn = repmat(imgIn, [1 1 3 1]);
end
end

function imgOut = pointsSAM(imgIn, labelPositions, labelIndices, castDataType)
% function imgOut = pointsSAM(imgIn, labelPositions, labelIndices, castDataType)
% do interactive prediction of 2D image in imgIn using seeds in
% labelPositions and labelIndices
%
% Parameters:
% imgIn: image to segment (height, width, colors)
% labelPositions: matrix of coordinates for seeds ([seedId; x,y])
% labelIndices: matrix positive (1) and negative seeds (0)
% castDataType: string with class to cast output imgOut
%
% Return values:
% imgOut: results of the segmentation, 2D image (height, width)

if nargin < 4; castDataType = 'uint8'; end

% send image to predictor
pyrun('predictor2D.set_image(image)', image=py.numpy.array(imgIn))

%pyrun(["with torch.inference_mode(), torch.autocast('cuda', dtype=torch.bfloat16):", ...
%       "    predictor2D.set_image(image)", ...
%       "    masks, _, _ = predictor2D.predict(<input_prompts>)"], ...
%       image=py.numpy.array(imgIn))

% duplicate the coordinate to preserve dimension
if size(labelPositions,1) == 1
    labelPositions = [labelPositions; labelPositions];
    labelIndices = [labelIndices labelIndices];
end

labelPositions = py.numpy.array(labelPositions);
pyrun('input_point = np.array(pointCoordinates)', pointCoordinates=labelPositions);
labelIndices = py.numpy.array(labelIndices);
pyrun('input_label = np.array(labelIndices)', labelIndices=labelIndices);

% pyrun('print(predictor2D._features["image_embed"].shape, predictor2D._features["image_embed"][-1].shape)')

multipleMasks = false;
if multipleMasks
    pyrun(['masks, scores, logits = predictor2D.predict(', ...
        'point_coords=input_point,', ...
        'point_labels=input_label,', ...
        'multimask_output=True)']);
    pyrun('sorted_ind = np.argsort(scores)[::-1]');
    imgOut = pyrun('masks = masks[sorted_ind]', 'masks');
    pyrun('scores = scores[sorted_ind]');
    pyrun('logits = logits[sorted_ind]');
else
    % imgOut = pyrun(['masks, scores, logits = predictor2D.predict(', ...
    %     'point_coords=input_point,', ...
    %     'point_labels=input_label,', ...
    %     'multimask_output=False)'], 'masks');

    imgOut = pyrun([...
        ['with torch.no_grad():' ...
        '   masks, scores, logits = predictor2D.predict('], ...
        '   point_coords=input_point,', ...
        '   point_labels=input_label,', ...
        '   multimask_output=False)'] ...
    , 'masks');

    % this part is testing of adding prediction from a previous iteration
    % as a mask from the next iteration.
    % the prediction (logits) should be resized to 256x256
    % add to mibGUI_WindowButtonDownFcn.m before "obj.mibModel.sessionSettings.SAMsegmenter.Points.Position = [w, h, z];"
    %   global logits
    %   logits = [];
    % use firstRun = 1; to make initial prediction and after that change to
    % firstRun = 0; to get predictions using logits from the previous
    % iteration
    %
    % global logits
    % firstRun = 1;
    % if ~isempty(logits); firstRun = 0; end
    % if firstRun
    %     [imgOut, scores, logits] = pyrun(['masks, scores, logits = predictor2D.predict(', ...
    %         'point_coords=input_point,', ...
    %         'point_labels=input_label,', ...
    %         'multimask_output=False)'], 'masks');
    % else
    %     % this code is adaptation from
    %     % https://github.com/computational-cell-analytics/micro-sam/blob/master/micro_sam/prompt_based_segmentation.py#L98
    %     pyrun('logits = logits', logits=logits); % send logits to python
    %     % resize to 256x256 and pad if needed
    %
    %     pyrun('from segment_anything.utils.transforms import ResizeLongestSide'); % import ResizeLongestSide
    %     pyrun('expected_shape = (256, 256)');
    %     pyCommand = sprintf(['if logits.shape[1] == logits.shape[2]: \n' ...
    %                          '    trafo = ResizeLongestSide(expected_shape[0])\n' ...
    %                          '    logits = trafo.apply_image_torch(torch.from_numpy(logits[None]))\n' ...
    %                          'else:  # shape is not square resize the longest side to expected shape\n' ...
    %                          '    trafo = ResizeLongestSide(expected_shape[0])\n' ...
    %                          '    logits = trafo.apply_image_torch(torch.from_numpy(logits[None]))\n' ...
    %                          '    # pad the other side\n' ...
    %                          '    b, c, h, w = logits.shape\n' ...
    %                          '    padh = expected_shape[0] - h\n' ...
    %                          '    padw = expected_shape[1] - w\n' ...
    %                          '    # IMPORTANT: need to pad with zero, otherwise SAM doesnt understand the padding\n' ...
    %                          '    pad_width = ((0, 0), (0, 0), (0, padh), (0, padw))\n' ...
    %                          '    logits = np.pad(logits, pad_width, mode="constant", constant_values=0)\n' ...
    %                    ]);
    %
    %     pyrun(pyCommand)
    %
    %     [imgOut, scores, logits] = pyrun(['masks, scores, logits = predictor2D.predict(', ...
    %         'point_coords=input_point,', ...
    %         'point_labels=input_label,', ...
    %         'mask_input=logits,', ...
    %         'multimask_output=False)'], 'masks');
    % end
end
imgOut = cast(squeeze(imgOut), castDataType);
%pyrun('print(masks.shape)')

% clear GPU memory
pyrun([
    "import torch", ...
    "import gc", ...
    "torch.cuda.empty_cache()", ...
    "torch.cuda.synchronize()", ...
    "gc.collect()"
]);

end

function dataset = pointsVideoSAM(dataset, labelPositions, labelValues, castDataType)
% function dataset = pointsVideoSAM(dataset, labelPositions, labelValues, castDataType)
% do SAM2 segmentation using the provided list of points using predictor for video
%
% Parameters:
% dataset: 3D dataset to predict as [height, width, colors, depth]
% labelPositions: list of seeds from the first slice of the dataset
% labelValues: values of the seeds: 1-positiva, 0-negative
% castDataType: string with class to cast output imgOut
%
% Return values:
% dataset: results of the segmentation, 3D image (height, width, depth)

[height, width, colors, depth] = size(dataset);

% permute to [depth, height, width, colors]
dataset = permute(dataset, [4 1 2 3]); 

% get indices of the points on the slice where seeds were placed
pntIndices = ~isnan(labelValues);
start_frame_idx = labelPositions(pntIndices, 3);
% flip z of the dataset as the propagation of slices goes forward
use_reverse = false; % reverse the dataset for propagation backwards
if start_frame_idx ~= 0
    use_reverse = true;
    dataset = flip(dataset, 1);
end
% get positions, keep only x,y,z
labelPositions = labelPositions(pntIndices, 1:2);
labelValues = labelValues(pntIndices);

% initialize predictor with dataset
pyrun('inference_state = predictor3D.init_state_from_array(image_array=image)', image=py.numpy.array(dataset))
% reset the state of the predictor
pyrun('predictor3D.reset_state(inference_state)')
% get dimensions of the dataset to allicate space for output
pyrun('num_frames, height, width = image.shape[0], image.shape[1], image.shape[2]')

% the back propagation does not work, so starting from slice 0
%pyrun('ann_frame_idx = start_frame_idx', 'start_frame_idx', int32(start_frame_idx));
pyrun('ann_frame_idx = 0');
pyrun('ann_obj_id = 1')  % give a unique id to each object we interact with (it can be any integers)
pyrun('reverse_mode = use_reverse', 'use_reverse', use_reverse);

% duplicate the coordinate to preserve dimension
if size(labelPositions, 1) == 1
    labelPositions = [labelPositions; labelPositions];
    labelValues = [labelValues labelValues];
end

% Let's add a positive click at (x, y)
%labelPositions = py.numpy.array(labelPositions);
% send coordinates to python
pyrun('points = np.array(pointCoordinates, dtype=np.float32)', pointCoordinates=labelPositions);
% send seeds to python, '1' means positive click and '0' means negative click
pyrun('labels = np.array(labelValues, np.int32)', labelValues=labelValues);

if depth == 1  % when only a single slice provided
    % pyrun(['_, out_obj_ids, out_mask_logits = predictor3D.add_new_points_or_box(', ...
    %     'inference_state=inference_state,', ...
    %     'frame_idx=ann_frame_idx,', ...
    %     'obj_id=ann_obj_id,', ...
    %     'points=points,', ...
    %     'labels=labels)']);  % clear_old_points=True possible additional parameter

    pyrun(['with torch.no_grad():' ...
           '    _, out_obj_ids, out_mask_logits = predictor3D.add_new_points_or_box(', ...
           '        inference_state=inference_state,', ...
           '        frame_idx=ann_frame_idx,', ...
           '        obj_id=ann_obj_id,', ...
           '        points=points,', ...
           '        labels=labels)'   ]);  % clear_old_points=True possible additional parameter

    dataset = pyrun('mask = (out_mask_logits[0] > 0.0).cpu().numpy()', 'mask');
    dataset = squeeze(dataset); % squeeze dimensions
else
    % propagate the prompts to get the masklet across the video
    % run propagation throughout the video and collect the results in a dict
    % pyrun(['predictor3D.add_new_points_or_box(', ...
    %     'inference_state=inference_state,', ...
    %     'frame_idx=ann_frame_idx,', ...
    %     'obj_id=ann_obj_id, ', ...
    %     'points=points,', ...
    %     'labels=labels,', ...
    %     'clear_old_points=True)']);

    pyrun(['with torch.no_grad():' ...
           '    predictor3D.add_new_points_or_box(', ...
           '        inference_state=inference_state,', ...
           '        frame_idx=ann_frame_idx,', ...
           '        obj_id=ann_obj_id, ', ...
           '        points=points,', ...
           '        labels=labels,', ...
           '        clear_old_points=True)']);

    % allocate space for the output
    pyrun('video_masks = np.zeros((height, width, num_frames), dtype=np.bool_)'); 
    % % run rediction and assemble results in video_masks matrix
    % % required uncommenting of flip Z below
    % pyrun(sprintf([...
    %     'for out_frame_idx, out_obj_ids, out_mask_logits in predictor3D.propagate_in_video(inference_state):\n' ...
    %     '    masks = (out_mask_logits > 0.0).cpu().numpy()\n' ...
    %     '    masks = masks.squeeze(1)\n' ...  % Shape: (num_objects, height, width)
    %     '    video_masks[:, :, out_frame_idx] = masks[0, :, :]\n' ...
    %     ]));

    % % this is alternative version when feeling video_masks in the reversed order in python
    pyrun(sprintf([...
        'for out_frame_idx, out_obj_ids, out_mask_logits in predictor3D.propagate_in_video(inference_state):\n' ...
        '   masks = (out_mask_logits > 0.0).cpu().numpy()\n' ...
        '   masks = masks.squeeze(1)\n' ...  % Shape: (num_objects, height, width)
        '   if reverse_mode:\n' ...
        '       video_masks[:, :, num_frames - 1 - out_frame_idx] = masks[0, :, :]\n' ... % reverse mode, fill from top -> down
        '   else:\n' ...
        '       video_masks[:, :, out_frame_idx] = masks[0, :, :]\n' ...            % normal mode, fill from bottom -> up
        ]));
    
    % Retrieve the numpy matrix and convert to MATLAB array
    dataset = pyrun('video_masks', 'video_masks');
end
dataset = cast(dataset, castDataType); % Shape: [height, width, depth]

% clear GPU memory
pyrun([
    "del inference_state", ...
    "import torch", ...
    "import gc", ...
    "gc.collect()", ...
    "torch.cuda.empty_cache()", ...
    "torch.cuda.synchronize()" ...
]);

% flip Z for results when using the reverse mode
% if use_reverse
%    dataset = flip(dataset, 3);
% end
end
