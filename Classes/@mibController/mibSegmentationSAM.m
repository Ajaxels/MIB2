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

function mibSegmentationSAM(obj, extraOptions, BatchOptIn)
% function mibSegmentationSAM(obj, extraOptions, BatchOptIn)
% Perform segmentation using segment-anything model https://segment-anything.com
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
BatchOpt.Method{2} = {'Interactive', 'Landmarks', 'Automatic everything'};
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
            errordlg(sprintf('A structure as the 2nd parameter is required!'));
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
    toolname = 'segment-everything model is';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode!\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

% check for switch that disables segmentation tools
if obj.mibModel.disableSegmentation == 1; return; end

methodToUse = obj.mibView.handles.mibSegmSAMMethod.Value; % 1,2,3,4
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
    status = obj.mibSegmentationSAM_requirements();
    if ~status; return; end
    if BatchOpt.showWaitbar 
        wb = waitbar(0, sprintf('\n\n'), 'Name', 'SAM segmentation'); 
        wb.Children.Title.Interpreter = 'none';
        waitbar(0, wb, sprintf('Initializing Python environment\n%s\nPlease wait...', obj.mibModel.preferences.SegmTools.SAM.backbone));
    end

    checkpointFilename = obj.mibModel.sessionSettings.SAMsegmenter.Links.checkpointFilename;
    onnxFilename = obj.mibModel.sessionSettings.SAMsegmenter.Links.onnxFilename;
    model_type = obj.mibModel.sessionSettings.SAMsegmenter.Links.backbone;

    % path to segment-anything package from github, https://github.com/facebookresearch/segment-anything
    samPath = obj.mibModel.preferences.SegmTools.SAM.sam_installation_path;

    onnx_model_path = fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, onnxFilename);
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

    if BatchOpt.showWaitbar; waitbar(0.1, wb); end
    % Add the SAM folder to the Python search path
    % Check if the path is already in py.sys.path
    pyPath = py.sys.path;
    if count(pyPath, samPath) == 0     % add to path
        insert(py.sys.path, int64(0), samPath);
    end

    %% SAM 2 TEST
    %pyrun('import torch');
    %pyrun('from sam2.build_sam import build_sam2');
    %pyrun('from sam2.sam2_image_predictor import SAM2ImagePredictor');

    % import required modules
    pyrun('import cv2');
    pyrun('import numpy as np')
    pyrun('from segment_anything import sam_model_registry, SamPredictor, SamAutomaticMaskGenerator');
    pyrun('import onnxruntime');
    pyrun(sprintf('onnx_model_path = "%s"', strrep(onnx_model_path, '\', '/')));
    % pyrun('print(onnx_model_path)')
    if BatchOpt.showWaitbar; waitbar(0.3, wb); end
    % print the list of available providers
    % CUDAExecutionProvider requires installation of onnxruntime-gpu
    % >> pip3 install onnxruntime-gpu
    % pyrun('print(onnxruntime.get_available_providers())')
    if strcmp(obj.mibModel.preferences.SegmTools.SAM.environment, 'cuda')
        pyrun('ort_session = onnxruntime.InferenceSession(onnx_model_path, providers=["CUDAExecutionProvider", "CPUExecutionProvider"])');
    else
        pyrun('ort_session = onnxruntime.InferenceSession(onnx_model_path, providers=["CPUExecutionProvider"])');
    end
    %pyrun('ort_session = onnxruntime.InferenceSession(onnx_model_path, providers=["CPUExecutionProvider"])');
    if BatchOpt.showWaitbar; waitbar(0.5, wb); end
    % define checkpoint and model type
    pyrun(sprintf('checkpoint = "%s"', strrep(checkpoint, '\', '/')));
    pyrun(sprintf('model_type = "%s"', model_type));

    % checks
    % pyrun(["import torch", ...
    %     "state_dict = torch.load(checkpoint)"])
    % 
    % pyrun(["import torch", ...
    %     "state_dict = torch.load(checkpoint, map_location=torch.device('cpu'))"])
    % 
    % 
    % pyrun(["try:", ...
    %     "    state_dict = torch.load(checkpoint)", ...
    %     "except Exception as e:", ...
    %     "    print(e)", ...
    %     "    import traceback", ...
    %     "    traceback.print_exc()"])

    % pyrun(["import torch", ...
    %        'print(torch.cuda.is_available())'])
    %
    % % checked: the file can be read
    % % pyrun("print(open(checkpoint, 'rb').read())")
    % 
    % pyrun('print(checkpoint)')
    % pyrun('import os')
    % pyrun('print(os.path.exists(checkpoint))')
    % 
    % pyrun('import torch')
    % pyrun('state_dict = torch.load(checkpoint)')
    % pyrun('import torch; print(torch.__version__)')
    % pyrun(sprintf('checkpoint = "%s"', '/nfs/home/456500414f5b2c6d/Documents/Workshop/Nets/sam_vit_b_01ec64.pth'));


    pyrun('sam = sam_model_registry[model_type](checkpoint=checkpoint)')
    if BatchOpt.showWaitbar; waitbar(0.7, wb); end
    % To use the ONNX model, the image must first be pre-processed using the SAM image encoder. 
    % This is a heavier weight process best performed on GPU. 
    % SamPredictor can be used as normal, then .get_image_embedding() will retreive the intermediate features.
    if strcmp(obj.mibModel.preferences.SegmTools.SAM.environment, 'cuda')
        pyrun('sam.to(device="cuda")');
    else
        pyrun('sam.to(device="cpu")');
    end
    %pyrun('sam.to(device="cpu")');
    if BatchOpt.showWaitbar; waitbar(0.8, wb); end
    pyrun('predictor = SamPredictor(sam)');
    if BatchOpt.showWaitbar; waitbar(0.9, wb); end
    pyrun('mask_generator = SamAutomaticMaskGenerator(sam)')
    if BatchOpt.showWaitbar; waitbar(1, wb); end
    delete(wb);
end

% define limits
t1 = 1;
t2 = obj.mibModel.I{BatchOpt.id}.time;
if strcmp(BatchOpt.Dataset{1}, '2D, Slice') || ...
        strcmp(BatchOpt.Method{1}, 'Interactive')
    z1 = obj.mibModel.I{BatchOpt.id}.getCurrentSliceNumber();
    z2 = z1;
else
    z1 = 1;
    z2 = obj.mibModel.I{BatchOpt.id}.depth;
end
noImages = (z2-z1+1)*(t2-t1+1);

% redefine showing of the progress bar
localWaitbar = BatchOpt.showWaitbar;
if strcmp(BatchOpt.Method{1}, 'Interactive') && ~obj.mibModel.preferences.SegmTools.SAM.showProgressBar
    localWaitbar = false;
end

if localWaitbar; wb = waitbar(0, sprintf('%s\nPlease wait...', BatchOpt.Method{1}), 'Name', 'Segment anything'); end

currViewPort = obj.mibModel.I{BatchOpt.id}.viewPort;
max_int = obj.mibModel.I{BatchOpt.id}.meta('MaxInt');
getDataOpt.id = BatchOpt.id;
% enable blocked mode switch
getLabelsOpt = struct();
if strcmp(BatchOpt.Method{1}, 'Interactive')
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
    if numel(obj.mibModel.sessionSettings.SAMsegmenter.Points.Value) == 1
        backupOptions.LinkedData.Points.Position = [];
        backupOptions.LinkedData.Points.Value = [];
    else
        backupOptions.LinkedData.Points.Position = obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(1:end-1,:);
        backupOptions.LinkedData.Points.Value = obj.mibModel.sessionSettings.SAMsegmenter.Points.Value(1:end-1);
    end
    backupOptions.LinkedVariable.Points = 'obj.mibModel.sessionSettings.SAMsegmenter.Points';
    obj.mibModel.mibDoBackup(BatchOpt.Destination{1}, 0, backupOptions);  % do backup
end

try
    for t=t1:t2
        getDataOpt.t = [t, t];
        
        for z=z1:z2
            % if showWaitbar && mod(layer_id, 10) == 1; increment(pw); end
            % get image
            imgIn = cell2mat(obj.mibModel.getData2D('image', z, obj.mibModel.I{BatchOpt.id}.orientation, NaN, getDataOpt));
            
            if size(imgIn, 3) ~= 1 && size(imgIn, 3) ~= 3
                errordlg(sprintf('!!! Error !!!\n\nSegmentation using segment-everything model is only available for grayscale and RGB images\nFor multi-channel images select a single channel in the Colors table and try again!'), ...
                    'SAM segmentation error');
                if localWaitbar; delete(wb); end
                return;
            end
    
            % convert to 8bit
            if ~isa(imgIn, 'uint8')
                if obj.mibModel.mibLiveStretchCheck
                    for i=1:size(imgIn,3)
                        imgIn(:,:,i) = imadjust(imgIn(:,:,i), stretchlim(imgIn(:,:,i),[0 1]),[]);
                    end
                    imgIn = uint8(imgIn/256);
                else
                    % convert to the 8bit image
                    if size(imgIn, 3) == 1
                        colCh = obj.mibModel.I{BatchOpt.id}.selectedColorChannel;
                        if currViewPort.min(colCh) ~= 0 || currViewPort.max(colCh) ~= max_int || currViewPort.gamma(colCh) ~= 1
                            imgIn = imadjust(imgIn, [currViewPort.min(colCh)/max_int currViewPort.max(colCh)/max_int], [0 1], currViewPort.gamma(colCh)); 
                        end
                    else
                        if max(currViewPort.min) > 0 || min(currViewPort.max) ~= max_int || sum(currViewPort.gamma) ~= 3
                            for colCh=1:3
                                imgIn(:,:,colCh) = imadjust(imgIn(:,:,colCh), [currViewPort.min(colCh)/max_int currViewPort.max(colCh)/max_int], [0 1], currViewPort.gamma(colCh)); 
                            end
                        end
                    end
                    imgIn = uint8(imgIn/256);
                end
            end
            
            % add padding to minimize edge artefacts
            if methodToUse == 1
                padSize = ceil(size(imgIn, 2)/256);
                imgIn = padarray(imgIn, [padSize padSize], 'symmetric', 'both');
            end
            % convert to RGB
            if size(imgIn, 3) == 1 %#ok<ISMAT>
                imgIn = repmat(imgIn, [1 1 3]);
            end
            switch methodToUse
                case 1  % Interactive in-view points
                    % check for points from different slices and remove points
                    % that do not belong to the current slice
                    currZ = obj.mibModel.I{BatchOpt.id}.getCurrentSliceNumber();
                    % get indices of the points on the current slice
                    pntIndices = obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(:,3) == currZ;
                    % keep only the points on the current slice
                    obj.mibModel.sessionSettings.SAMsegmenter.Points.Position = obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(pntIndices, :);
                    obj.mibModel.sessionSettings.SAMsegmenter.Points.Value = obj.mibModel.sessionSettings.SAMsegmenter.Points.Value(pntIndices);
                    % remove z-coordinate
                    labelPositions = obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(:, 1:2);
                    % shift coordinates
                    labelPositions(:,1) = ceil((labelPositions(:,1) - max([0 floor(obj.mibModel.I{BatchOpt.id}.axesX(1))])) );     % - .999/obj.magFactor subtract 1 pixel to put a marker to the left-upper corner of the pixel
                    labelPositions(:,2) = ceil((labelPositions(:,2) - max([0 floor(obj.mibModel.I{BatchOpt.id}.axesY(1))])) );
                    imgOut = pointsSAM(imgIn, labelPositions, obj.mibModel.sessionSettings.SAMsegmenter.Points.Value);
                    imgOut = imgOut(padSize+1:end-padSize, padSize+1:end-padSize);    % remove padding
                    % % --- for DEBUG --- %
                    % --- for DEBUG --- % imgOut = zeros([size(imgIn, 1), size(imgIn, 2)], 'uint8');
                    % --- for DEBUG --- % imgOut(imgIn(:,:,1)<imgIn(labelPositions(end,2), labelPositions(end,1), 1)) = 1;
                    
                    % limit to the selected material of the model
                    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial == 1
                        storedImageState = obj.mibModel.sessionSettings.SAMsegmenter.initialImageSelected(obj.mibModel.I{obj.mibModel.Id}.slices{1}(1):obj.mibModel.I{obj.mibModel.Id}.slices{1}(2), ...
                                obj.mibModel.I{obj.mibModel.Id}.slices{2}(1):obj.mibModel.I{obj.mibModel.Id}.slices{2}(2) );
                        imgOut = bitand(imgOut, storedImageState);
                    end

                    switch BatchOpt.Mode{1}
                        case 'replace'
                            obj.mibModel.setData2D(BatchOpt.Destination{1}, {imgOut}, NaN, NaN, obj.mibModel.I{BatchOpt.id}.selectedAddToMaterial-2, getDataOpt);
                        case 'add'
                            % crop the stored image to the current FoV
                            storedImageState = obj.mibModel.sessionSettings.SAMsegmenter.initialImageAddTo(obj.mibModel.I{obj.mibModel.Id}.slices{1}(1):obj.mibModel.I{obj.mibModel.Id}.slices{1}(2), ...
                                obj.mibModel.I{obj.mibModel.Id}.slices{2}(1):obj.mibModel.I{obj.mibModel.Id}.slices{2}(2) );
                            obj.mibModel.setData2D(BatchOpt.Destination{1}, {bitor(storedImageState, imgOut)}, NaN, NaN, obj.mibModel.I{BatchOpt.id}.selectedAddToMaterial-2, getDataOpt);
                        case 'subtract'
                            currLayer = cell2mat(obj.mibModel.getData2D(BatchOpt.Destination{1}, NaN, NaN, obj.mibModel.I{BatchOpt.id}.selectedAddToMaterial-2, getDataOpt));
                            obj.mibModel.setData2D(BatchOpt.Destination{1}, {currLayer - imgOut}, NaN, NaN, obj.mibModel.I{BatchOpt.id}.selectedAddToMaterial-2, getDataOpt);
                        case 'add, +next material'
                            selMaterialIndex = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo');

                            storedImageState = obj.mibModel.sessionSettings.SAMsegmenter.initialImageAddTo(obj.mibModel.I{obj.mibModel.Id}.slices{1}(1):obj.mibModel.I{obj.mibModel.Id}.slices{1}(2), ...
                                obj.mibModel.I{obj.mibModel.Id}.slices{2}(1):obj.mibModel.I{obj.mibModel.Id}.slices{2}(2) );
                            obj.mibModel.setData2D(BatchOpt.Destination{1}, {bitor(storedImageState, imgOut)}, NaN, NaN, selMaterialIndex, getDataOpt);

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
                case 2  % Landmarks
                    % get labels
                    [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{BatchOpt.id}.getSliceLabels(z, t, getLabelsOpt);
                    if isempty(labelsList); continue; end
                    % keep only x,y
                    labelPositions = labelPositions(:,2:3);
                    imgOut = pointsSAM(imgIn, labelPositions, labelValues);
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
                case 3  % Automatic everything
                    pyrun(['mask_generator = SamAutomaticMaskGenerator(' ...
                        'model = sam, ' ...
                        'points_per_side = pnts_p_side, ' ...
                        'points_per_batch = pnts_p_batch, ' ...
                        'pred_iou_thresh = pred_iou_th, ' ...
                        'stability_score_thresh = st_sco_th, ' ...
                        'crop_n_layers = crop_n_l, ' ...
                        'crop_nms_thresh = crop_n_th, ' ...
                        'crop_overlap_ratio = crop_ovl_rto, ' ...
                        'crop_n_points_downscale_factor = crop_n_pnts_downsc_f, ' ...
                        'min_mask_region_area = min_mask_reg_area)'], ...
                        pnts_p_side = py.numpy.int32(obj.mibModel.preferences.SegmTools.SAM.points_per_side), ...
                        pnts_p_batch = py.numpy.int32(obj.mibModel.preferences.SegmTools.SAM.points_per_batch), ...
                        pred_iou_th = py.numpy.float16(obj.mibModel.preferences.SegmTools.SAM.pred_iou_thresh), ...
                        st_sco_th = py.numpy.int32(obj.mibModel.preferences.SegmTools.SAM.stability_score_thresh), ...
                        crop_n_l = py.numpy.int32(obj.mibModel.preferences.SegmTools.SAM.crop_n_layers), ...
                        crop_n_th = py.numpy.float16(obj.mibModel.preferences.SegmTools.SAM.crop_nms_thresh), ...
                        crop_ovl_rto = py.numpy.float16(obj.mibModel.preferences.SegmTools.SAM.crop_overlap_ratio), ...
                        crop_n_pnts_downsc_f = obj.mibModel.preferences.SegmTools.SAM.crop_n_points_downscale_factor, ...
                        min_mask_reg_area = obj.mibModel.preferences.SegmTools.SAM.min_mask_region_area);
    
                    pyrun('predictor.set_image(image)', image=py.numpy.array(imgIn))
    
                    masks = pyrun('masks = mask_generator.generate(image)', 'masks', image=py.numpy.array(imgIn));
                    for maskId=1:double(py.len(masks))
                        currentMask = logical(masks{maskId}{'segmentation'});
                        if maskId==1; modelOut = zeros(size(currentMask), 'uint16'); end
                        modelOut(currentMask==1) = maskId;
                    end
                    obj.mibModel.setData2D('model', {modelOut}, z, NaN, NaN, getDataOpt);
            end
            counter = counter + 1;
            if localWaitbar; waitbar(counter/noImages, wb); end
        end
    end
catch err
    showErrorDialog(obj.mibView.gui, err, 'Problem', '', ...
        'You might be running out of GPU memory; try to decrease "Set the number of points run simultaneously by the model in SAM settings"');
    if localWaitbar; delete(wb); end
    return;

end
if localWaitbar; delete(wb); end
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

end

function imgOut = pointsSAM(imgIn, labelPositions, labelIndices)
% function imgOut = pointsSAM(imgIn, labelPositions, labelIndices)

pyrun('predictor.set_image(image)', image=py.numpy.array(imgIn))
pyrun('image_embedding = predictor.get_image_embedding().cpu().numpy()')

% duplicate the coordinate to preserve dimension
if size(labelPositions,1) == 1
    labelPositions = [labelPositions; labelPositions];
    labelIndices = [labelIndices labelIndices];
end

labelPositions = py.numpy.array(labelPositions);
pyrun('input_point = np.array(pointCoordinates)', pointCoordinates=labelPositions);
labelIndices = py.numpy.array(labelIndices);
pyrun('input_label = np.array(labelIndices)', labelIndices=labelIndices);

% Add a batch index, concatenate a padding point, and transform.
pyrun('onnx_coord = np.concatenate([input_point, np.array([[0.0, 0.0]])], axis=0)[None, :, :]');
pyrun('onnx_label = np.concatenate([input_label, np.array([-1])], axis=0)[None, :].astype(np.float32)');
pyrun('onnx_coord = predictor.transform.apply_coords(onnx_coord, image.shape[:2]).astype(np.float32)');

% Create an empty mask input and an indicator for no mask.
pyrun('onnx_mask_input = np.zeros((1, 1, 256, 256), dtype=np.float32)')
pyrun('onnx_has_mask_input = np.zeros(1, dtype=np.float32)')

pyrun(['ort_inputs = {' ...
    '"image_embeddings": image_embedding, ' ...
    '"point_coords": onnx_coord, ' ...
    '"point_labels": onnx_label, ' ...
    '"mask_input": onnx_mask_input, ' ...
    '"has_mask_input": onnx_has_mask_input, ' ...
    '"orig_im_size": np.array(image.shape[:2], dtype=np.float32)' ...
    '}'])

pyrun('masks, _, low_res_logits = ort_session.run(None, ort_inputs)');
imgOut = pyrun('masks = masks > predictor.model.mask_threshold', 'masks');   % do not remove ";", it hangs matlab
imgOut = uint8(squeeze(imgOut));

end