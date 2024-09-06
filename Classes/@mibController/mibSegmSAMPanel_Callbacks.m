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

function mibSegmSAMPanel_Callbacks(obj, tag)
% function mibSegmSAMPanel_Callbacks(obj, tag)
% callbacks for widgets of obj.mibView.handles.mibSegmSAMPanel
%
% Parameters:
% tag: handle to a widget that has been modified
%
% Return values:
%

% Updates
% 

global mibPath;

switch tag
    case 'mibSegmSAMMethod'
        switch obj.mibView.handles.mibSegmSAMMethod.String{obj.mibView.handles.mibSegmSAMMethod.Value}
            case {'Interactive'}
                obj.mibView.handles.mibSegmSAMSegment.Enable = 'off';
                obj.mibView.handles.mibSegmSAMDataset.Enable = 'off';
                obj.mibView.handles.mibSegmSAMDestination.Enable = 'on';
                % force to select the selection layer after change of methods
                obj.mibView.handles.mibSegmSAMDestination.Value = find(ismember('selection', obj.mibView.handles.mibSegmSAMDestination.String));
                obj.mibView.handles.mibSegmSAMMode.Enable = 'on';
                obj.mibView.handles.mibSegmSAMMode.String = {'replace', 'add', 'subtract', 'add, +next material'};
                obj.mibView.handles.mibSegmSAMAnnotations.Enable = 'off';
            case 'Landmarks'
                obj.mibView.handles.mibSegmSAMSegment.Enable = 'on';
                obj.mibView.handles.mibSegmSAMDataset.Enable = 'on';
                obj.mibView.handles.mibSegmSAMDestination.Enable = 'on';
                % force to select the selection layer after change of methods
                obj.mibView.handles.mibSegmSAMDestination.Value = find(ismember('selection', obj.mibView.handles.mibSegmSAMDestination.String));
                obj.mibView.handles.mibSegmSAMMode.Enable = 'on';
                if obj.mibView.handles.mibSegmSAMMode.Value == 4; obj.mibView.handles.mibSegmSAMMode.Value = 1; end
                obj.mibView.handles.mibSegmSAMMode.String = {'replace', 'add', 'subtract'};
                obj.mibView.handles.mibSegmSAMAnnotations.Enable = 'on';
            case 'Automatic everything'
                obj.mibView.handles.mibSegmSAMSegment.Enable = 'on';
                obj.mibView.handles.mibSegmSAMDataset.Enable = 'on';
                obj.mibView.handles.mibSegmSAMDestination.Enable = 'off';
                obj.mibView.handles.mibSegmSAMDestination.Value = 3;
                obj.mibView.handles.mibSegmSAMMode.Value = 1;
                obj.mibView.handles.mibSegmSAMMode.Enable = 'off';
                obj.mibView.handles.mibSegmSAMAnnotations.Enable = 'off';
        end
    case 'mibSegmSAMSettings'
        % get settings file with links to SAM backbones
        
        % update name of json file for SAM2
        if obj.mibModel.preferences.SegmTools.SAM.samVersion == 1
            linksFile = fullfile(obj.mibPath, obj.mibModel.preferences.SegmTools.SAM.linksFile);
        else
            linksFile = fullfile(obj.mibPath, obj.mibModel.preferences.SegmTools.SAM2.linksFile);
        end
        
        linksJSON = fileread(linksFile);
        linksStruct = jsondecode(linksJSON);
        % get names of available SAM backbones
        sam_names = {linksStruct.name};

        if obj.mibModel.preferences.SegmTools.SAM.samVersion == 1
            prompts = {'Backbone (requires download)'; ...
                'Execution environment(cpu is ~30-60 times slower than cuda)';
                'Show the progress bar in the interactive mode';
                'Location of "sam_links.json" with links to SAM backbones, relative to MIB installation path'
                'PATH to segment-anything installation';
                'Check to select path to segment-anything';
                'Check to reset settings to default values...';
                sprintf('---------------------------- Automatic mode settings ----------------------------\npoints_per_side: the number of points to be sampled along one side of the image [def=32]'); 
                'points_per_batch: sets the number of points run simultaneously by the model. Higher numbers may be faster but use more GPU memory [def=64]';
                'pred_iou_thresh: filtering threshold in [0,1], using the model''s predicted mask quality [def=0.88]';
                'stability_score_thresh: filtering threshold in [0,1], using the stability of the mask under changes to the cutoff used to binarize the model''s mask predictions [def=0.95]';
                'box_nms_thresh: the box IoU cutoff used by non-maximal suppression to filter duplicate masks [def=0.7]';
                'crop_n_layers: if >0, mask prediction will be run again on crops of the image. Sets the number of layers to run, where each layer has 2^i_layer number of image crops [def=0]';
                'crop_nms_thresh: the box IoU cutoff used by non-maximal suppression to filter duplicate masks between different crops [def=0.7]';
                'crop_overlap_ratio: sets the degree to which crops overlap. In the first crop layer, crops will overlap by this fraction of the image length. Later layers with more crops scale down this overlap [def=0.3413]';
                'crop_n_points_downscale_factor: the number of points-per-side sampled in layer n is scaled down by crop_n_points_downscale_factor^n [def=1]';
                'min_mask_region_area: if >0, postprocessing will be applied to remove disconnected regions and holes in masks with area smaller than min_mask_region_area [def=0]'};
    
            defAns = {{sam_names{:}, find(ismember(sam_names, obj.mibModel.preferences.SegmTools.SAM.backbone))};
                        {'cuda', 'cpu', find(ismember({'cuda', 'cpu'}, obj.mibModel.preferences.SegmTools.SAM.environment))};
                        obj.mibModel.preferences.SegmTools.SAM.showProgressBar;
                        obj.mibModel.preferences.SegmTools.SAM.linksFile;
                        obj.mibModel.preferences.SegmTools.SAM.sam_installation_path;
                        false;
                        false;
                        num2str(obj.mibModel.preferences.SegmTools.SAM.points_per_side); 
                        num2str(obj.mibModel.preferences.SegmTools.SAM.points_per_batch); 
                        num2str(obj.mibModel.preferences.SegmTools.SAM.pred_iou_thresh); 
                        num2str(obj.mibModel.preferences.SegmTools.SAM.stability_score_thresh); 
                        num2str(obj.mibModel.preferences.SegmTools.SAM.box_nms_thresh); 
                        num2str(obj.mibModel.preferences.SegmTools.SAM.crop_n_layers); 
                        num2str(obj.mibModel.preferences.SegmTools.SAM.crop_nms_thresh); 
                        num2str(obj.mibModel.preferences.SegmTools.SAM.crop_overlap_ratio); 
                        num2str(obj.mibModel.preferences.SegmTools.SAM.crop_n_points_downscale_factor); 
                        num2str(obj.mibModel.preferences.SegmTools.SAM.min_mask_region_area)}; %#ok<CCAT>
            
            dlgTitle = 'Segment-anything settings';
            options.WindowStyle = 'normal';       % [optional] style of the window
            options.PromptLines = [1, 1, 2, 2, 1, 1, 2, 4, 2, 2, 3, 2, 3, 2, 3, 2, 3];   % [optional] number of lines for widget titles
            options.Title = sprintf('Usage of Segment-anything requires Python installation with all necessary modules. Please refer to documentation on how to set it up.\nThe selected backbone will be downloaded to DeepMIB temporary directory that can be updated from Menu->File->Preferences->External Dirs');
            options.TitleLines = 4;                   % [optional] make it twice tall, number of text lines for the title
            options.WindowWidth = 2.5;    % [optional] make window x1.2 times wider
            options.Columns = 2;    % [optional] define number of columns
            options.Focus = 1;      % [optional] define index of the widget to get focus
            options.HelpUrl = 'https://mib.helsinki.fi/downloads_systemreq_sam.html'; % [optional], an url for the Help button
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end
        
            if answer{7}
                answer2 = questdlg(sprintf(['!!! Warning !!!\n\nYou are going to reset SAM settings to default values!\n\n' ...
                    'Note!\n' ...                    
                    'After that you need to specify location of segment-anything-2 and upate other settings if needed']), ...
                    'Reset SAM', 'Reset', 'Do not reset, just update', 'Cancel', 'Cancel');
                if strcmp(answer2, 'Cancel')
                    return
                elseif strcmp(answer2, 'Reset')
                    % restore default values
                    if ~strcmp(obj.mibModel.preferences.SegmTools.SAM.backbone, 'vit_b (0.4Gb)')
                        % force to reset python during next usage
                        obj.mibModel.mibPython = [];
                    end
                    obj.mibModel.preferences.SegmTools.SAM.backbone = 'vit_b (0.4Gb)';     % 'vit_h (2.5Gb)', 'vit_l (1.2Gb)', 'vit_b (0.4Gb)'
                    obj.mibModel.preferences.SegmTools.SAM.points_per_side = 32;
                    obj.mibModel.preferences.SegmTools.SAM.points_per_batch = 64;
                    obj.mibModel.preferences.SegmTools.SAM.pred_iou_thresh =  0.88;
                    obj.mibModel.preferences.SegmTools.SAM.stability_score_thresh = 0.95;
                    obj.mibModel.preferences.SegmTools.SAM.box_nms_thresh = 0.7;
                    obj.mibModel.preferences.SegmTools.SAM.crop_n_layers = 0;
                    obj.mibModel.preferences.SegmTools.SAM.crop_nms_thresh = 0.7;
                    obj.mibModel.preferences.SegmTools.SAM.crop_overlap_ratio = 0.3413;
                    obj.mibModel.preferences.SegmTools.SAM.crop_n_points_downscale_factor = 1;
                    obj.mibModel.preferences.SegmTools.SAM.min_mask_region_area = 0;
                    obj.mibModel.preferences.SegmTools.SAM.showProgressBar = false;
                    return
                end
            end

            if answer{6}
                try
                    selpath = uigetdir(obj.mibModel.preferences.SegmTools.SAM.sam_installation_path, 'segment-anything location');
                catch err
                    selpath = uigetdir([], 'segment-anything location');
                end
                if selpath == 0; return; end
                obj.mibModel.preferences.SegmTools.SAM.sam_installation_path = selpath;
            else
                obj.mibModel.preferences.SegmTools.SAM.sam_installation_path = answer{5};
            end

            if ~strcmp(obj.mibModel.preferences.SegmTools.SAM.backbone, answer{1})
                % force to reset python during next usage
                obj.mibModel.mibPython = [];
            end
            if ~strcmp(answer{2}, obj.mibModel.preferences.SegmTools.SAM.environment)
                obj.mibModel.mibPython = [];
            end

            obj.mibModel.preferences.SegmTools.SAM.backbone = answer{1};
            obj.mibModel.preferences.SegmTools.SAM.points_per_side = str2double(answer{8});
            obj.mibModel.preferences.SegmTools.SAM.points_per_batch = str2double(answer{9});
            obj.mibModel.preferences.SegmTools.SAM.pred_iou_thresh = str2double(answer{10});
            obj.mibModel.preferences.SegmTools.SAM.stability_score_thresh = str2double(answer{11});
            obj.mibModel.preferences.SegmTools.SAM.box_nms_thresh = str2double(answer{12});
            obj.mibModel.preferences.SegmTools.SAM.crop_n_layers = str2double(answer{13});
            obj.mibModel.preferences.SegmTools.SAM.crop_nms_thresh = str2double(answer{14});
            obj.mibModel.preferences.SegmTools.SAM.crop_overlap_ratio = str2double(answer{15});
            obj.mibModel.preferences.SegmTools.SAM.crop_n_points_downscale_factor = str2double(answer{16});
            obj.mibModel.preferences.SegmTools.SAM.min_mask_region_area = str2double(answer{17});
            obj.mibModel.preferences.SegmTools.SAM.environment = answer{2};
            obj.mibModel.preferences.SegmTools.SAM.showProgressBar = logical(answer{3});

            % check for the SAM-links file
            newLinksFile = fullfile(obj.mibPath, answer{4});
            if exist(newLinksFile, 'file') == 0
                errordlg(sprintf('!!! Error !!!\n\nThe provided file:\n%s\nwith SAM links does not exist!\n\nKeeping the previous version:\n%s', newLinksFile, linksFile), 'Wrong JSON file');
            else
                obj.mibModel.preferences.SegmTools.SAM.linksFile = answer{4};
            end
            obj.mibSegmentationSAM_requirements(1);
        else
          % SAM 2

          % points_per_side (int or None): The number of points to be sampled
          %   along one side of the image. The total number of points is
          %   points_per_side**2. If None, 'point_grids' must provide explicit
          %   point sampling.

          % points_per_batch (int): Sets the number of points run simultaneously
          %   by the model. Higher numbers may be faster but use more GPU memory.
          % pred_iou_thresh (float): A filtering threshold in [0,1], using the
          %   model's predicted mask quality.
          % stability_score_thresh (float): A filtering threshold in [0,1], using
          %   the stability of the mask under changes to the cutoff used to binarize
          %   the model's mask predictions.
          % stability_score_offset (float): The amount to shift the cutoff when
          %   calculated the stability score.
          % mask_threshold (float): Threshold for binarizing the mask logits
          % box_nms_thresh (float): The box IoU cutoff used by non-maximal
          %   suppression to filter duplicate masks.
          % crop_n_layers (int): If >0, mask prediction will be run again on
          %   crops of the image. Sets the number of layers to run, where each
          %   layer has 2**i_layer number of image crops.
          % crop_nms_thresh (float): The box IoU cutoff used by non-maximal
          %   suppression to filter duplicate masks between different crops.
          % crop_overlap_ratio (float): Sets the degree to which crops overlap.
          %   In the first crop layer, crops will overlap by this fraction of
          %   the image length. Later layers with more crops scale down this overlap.
          % crop_n_points_downscale_factor (int): The number of points-per-side
          %   sampled in layer n is scaled down by crop_n_points_downscale_factor**n.
          % point_grids (list(np.ndarray) or None): A list over explicit grids
          %   of points used for sampling, normalized to [0,1]. The nth grid in the
          %   list is used in the nth crop layer. Exclusive with points_per_side.
          % min_mask_region_area (int): If >0, postprocessing will be applied
          %   to remove disconnected regions and holes in masks with area smaller
          %   than min_mask_region_area. Requires opencv.
          % output_mode (str): The form masks are returned in. Can be 'binary_mask',
          %   'uncompressed_rle', or 'coco_rle'. 'coco_rle' requires pycocotools.
          %   For large resolutions, 'binary_mask' may consume large amounts of
          %   memory.
          % use_m2m (bool): Whether to add a one step refinement using previous mask predictions.
          % multimask_output (bool): Whether to output multimask at each point of the grid.

            prompts = {'Backbone (requires download)'; ...
                       'Execution environment(cpu is ~30-60 times slower than cuda)';
                       'Show the progress bar in the interactive mode';
                       'Location of "sam2_links.json" with links to SAM backbones, relative to MIB installation path'
                       'PATH to segment-anything-2 installation';
                       'Check to select path to segment-anything-2';
                       'Check to reset settings to default values...';
                       sprintf('---------------------------- Automatic mode settings ----------------------------\npoints_per_side: the number of points to be sampled along one side of the image. The total number of points is points_per_side**2 [def=32]');
                       'points_per_batch: sets the number of points run simultaneously by the model. Higher numbers may be faster but use more GPU memory [def=64]';
                       'pred_iou_thresh: a filtering threshold in [0, 1], using the model predicted mask quality [def=0.8]';
                       'stability_score_thresh: a filtering threshold in [0, 1], using the stability of the mask under changes to the cutoff used to binarize the models mask predictions (def=0.95)';
                       'stability_score_offset: the amount to shift the cutoff when calculated the stability score [def=1.0]';
                       'crop_n_layers: if >0, mask prediction will be run again on crops of the image. Sets the number of layers to run, where each layer has 2**i_layer number of image crops [def=0]';
                       'box_nms_thresh: the box IoU cutoff used by non-maximal suppression to filter duplicate mask [def=0.7]';
                       'crop_n_points_downscale_factor: The number of points-per-side sampled in layer n is scaled down by crop_n_points_downscale_factor**n [def=1]';
                       'min_mask_region_area: if >0, postprocessing will be applied to remove disconnected regions and holes in masks with area smaller than min_mask_region_area [def=0]';
                       'use_m2m: add refinement using previous mask [def=false]'};
            defAns = {{sam_names{:}, find(ismember(sam_names, obj.mibModel.preferences.SegmTools.SAM2.backbone))};
                        {'cuda', 'cpu', find(ismember({'cuda', 'cpu'}, obj.mibModel.preferences.SegmTools.SAM2.environment))};
                        obj.mibModel.preferences.SegmTools.SAM2.showProgressBar;
                        obj.mibModel.preferences.SegmTools.SAM2.linksFile;
                        obj.mibModel.preferences.SegmTools.SAM2.sam_installation_path;
                        false;
                        false;
                        num2str(obj.mibModel.preferences.SegmTools.SAM2.points_per_side);
                        num2str(obj.mibModel.preferences.SegmTools.SAM2.points_per_batch);
                        num2str(obj.mibModel.preferences.SegmTools.SAM2.pred_iou_thresh);
                        num2str(obj.mibModel.preferences.SegmTools.SAM2.stability_score_thresh);
                        num2str(obj.mibModel.preferences.SegmTools.SAM2.stability_score_offset);
                        num2str(obj.mibModel.preferences.SegmTools.SAM2.crop_n_layers);
                        num2str(obj.mibModel.preferences.SegmTools.SAM2.box_nms_thresh);
                        num2str(obj.mibModel.preferences.SegmTools.SAM2.crop_n_points_downscale_factor);
                        num2str(obj.mibModel.preferences.SegmTools.SAM2.min_mask_region_area);
                        obj.mibModel.preferences.SegmTools.SAM2.use_m2m};
        
            dlgTitle = 'Segment-anything-2 settings';
            options.WindowStyle = 'normal';       % [optional] style of the window
            options.PromptLines = [1, 1, 1, 2, 1, 1, 1, 4,2,2,3,2,3,2,2,3,1];   % [optional] number of lines for widget titles
            options.Title = sprintf('Usage of Segment-anything requires Python installation with all necessary modules. Please refer to documentation on how to set it up.\nThe selected backbone will be downloaded to DeepMIB temporary directory that can be updated from Menu->File->Preferences->External Dirs');
            options.TitleLines = 3;                   % [optional] make it twice tall, number of text lines for the title
            options.WindowWidth = 2.6;    % [optional] make window x1.2 times wider
            options.Columns = 2;    % [optional] define number of columns
            options.Focus = 1;      % [optional] define index of the widget to get focus
            options.HelpUrl = 'https://mib.helsinki.fi/downloads_systemreq_sam2.html'; % [optional], an url for the Help button
            
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end

            if answer{7}
                answer2 = questdlg(sprintf(['!!! Warning !!!\n\nYou are going to reset SAM2 settings to default values!\n\n' ...
                    'Note!\n' ...                    
                    'After that you need to specify location of segment-anything-2 and upate other settings if needed']), ...
                    'Reset SAM', 'Reset', 'Do not reset, just update', 'Cancel', 'Cancel');
                if strcmp(answer2, 'Cancel')
                    return
                elseif strcmp(answer2, 'Reset')
                    % restore default values
                    if ~strcmp(obj.mibModel.preferences.SegmTools.SAM2.backbone, 'sam2_hiera_t (0.15Gb)')
                        % force to reset python during next usage
                        obj.mibModel.mibPython = [];
                    end
                    obj.mibModel.preferences.SegmTools.SAM2.backbone = 'sam2_hiera_t (0.15Gb)';     % 'sam2_hiera_t (0.15Gb), sam2_hiera_s (0.18Gb), sam2_hiera_base_plus (0.32Gb), sam2_hiera_l (0.90Gb)'
                    obj.mibModel.preferences.SegmTools.SAM2.showProgressBar = false;
                    obj.mibModel.preferences.SegmTools.SAM2.points_per_side = 32;
                    obj.mibModel.preferences.SegmTools.SAM2.points_per_batch = 64;
                    obj.mibModel.preferences.SegmTools.SAM2.pred_iou_thresh = 0.8;
                    obj.mibModel.preferences.SegmTools.SAM2.stability_score_thresh = 0.95;
                    obj.mibModel.preferences.SegmTools.SAM2.stability_score_offset = 1.0;
                    obj.mibModel.preferences.SegmTools.SAM2.crop_n_layers = 0;
                    obj.mibModel.preferences.SegmTools.SAM2.box_nms_thresh = 0.7;
                    obj.mibModel.preferences.SegmTools.SAM2.crop_n_points_downscale_factor = 1;
                    obj.mibModel.preferences.SegmTools.SAM2.min_mask_region_area = 0;
                    obj.mibModel.preferences.SegmTools.SAM2.use_m2m = false;
                    return
                end
            end

            if answer{6}
                try
                    selpath = uigetdir(obj.mibModel.preferences.SegmTools.SAM.sam_installation_path, 'segment-anything-2 location');
                catch err
                    selpath = uigetdir([], 'segment-anything-2 location');
                end
                if selpath == 0; return; end
                obj.mibModel.preferences.SegmTools.SAM2.sam_installation_path = selpath;
            else
                obj.mibModel.preferences.SegmTools.SAM2.sam_installation_path = answer{5};
            end

            if ~strcmp(obj.mibModel.preferences.SegmTools.SAM2.backbone, answer{1})
                % force to reset python during next usage
                obj.mibModel.mibPython = [];
            end
            if ~strcmp(answer{2}, obj.mibModel.preferences.SegmTools.SAM.environment)
                obj.mibModel.mibPython = [];
            end

            obj.mibModel.preferences.SegmTools.SAM2.backbone = answer{1};
            obj.mibModel.preferences.SegmTools.SAM2.environment = answer{2};
            obj.mibModel.preferences.SegmTools.SAM2.showProgressBar = logical(answer{3});

            obj.mibModel.preferences.SegmTools.SAM2.points_per_side = round(str2double(answer{8}));
            obj.mibModel.preferences.SegmTools.SAM2.points_per_batch = round(str2double(answer{9}));
            obj.mibModel.preferences.SegmTools.SAM2.pred_iou_thresh = str2double(answer{10});
            obj.mibModel.preferences.SegmTools.SAM2.stability_score_thresh = str2double(answer{11});
            obj.mibModel.preferences.SegmTools.SAM2.stability_score_offset = str2double(answer{12});
            obj.mibModel.preferences.SegmTools.SAM2.crop_n_layers = round(str2double(answer{13}));
            obj.mibModel.preferences.SegmTools.SAM2.box_nms_thresh = str2double(answer{14});
            obj.mibModel.preferences.SegmTools.SAM2.crop_n_points_downscale_factor = round(str2double(answer{15}));
            obj.mibModel.preferences.SegmTools.SAM2.min_mask_region_area = round(str2double(answer{16}));
            obj.mibModel.preferences.SegmTools.SAM2.use_m2m = logical(answer{17});

            % check for the SAM-links file
            newLinksFile = fullfile(obj.mibPath, answer{4});
            if exist(newLinksFile, 'file') == 0
                errordlg(sprintf('!!! Error !!!\n\nThe provided file:\n%s\nwith SAM links does not exist!\n\nKeeping the previous version:\n%s', newLinksFile, linksFile), 'Wrong JSON file');
            else
                obj.mibModel.preferences.SegmTools.SAM2.linksFile = answer{4};
            end
            obj.mibSegmentationSAM_requirements(obj.mibModel.preferences.SegmTools.SAM.samVersion);
        end
    case 'mibSegmSAMSegment'
        if strcmp(obj.mibView.handles.mibSegmSAMMethod.String{obj.mibView.handles.mibSegmSAMMethod.Value}, 'Automatic everything') && ...
            obj.mibModel.I{obj.mibModel.Id}.modelType < 65535
            
            errordlg(sprintf('!!! Error !!!\n\nTo use segment-anything in the automatic mode the model should be able to keep 65535 or more materials!\n\nCreate a new model or change the type of the current model from\nMenu->Models->Convert type'), 'Wrong model type');
            return;
        end
        
        switch obj.mibModel.preferences.SegmTools.SAM.samVersion
            case 1
                obj.mibSegmentationSAM();
            case 2
                obj.mibSegmentationSAM2();
        end
    case 'mibSAM2checkbox'
        obj.mibModel.preferences.SegmTools.SAM.samVersion = 1;
        if obj.mibView.handles.mibSAM2checkbox.Value == 1 % use SAM2
            obj.mibModel.preferences.SegmTools.SAM.samVersion = 2;
        end
        obj.mibModel.mibPython = [];
end
unFocus(obj.mibView.handles.mibSegmSelectedOnlyCheck);   % remove focus from hObject
end