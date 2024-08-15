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
        linksFile = fullfile(obj.mibPath, obj.mibModel.preferences.SegmTools.SAM.linksFile);
        linksJSON = fileread(linksFile);
        linksStruct = jsondecode(linksJSON);
        % get names of available SAM backbones
        sam_names = {linksStruct.name};

        prompts = {'Backbone (requires download)'; ...
            'The number of points to be sampled along one side of the image [points_per_side]'; 
            'Sets the number of points run simultaneously by the model. Higher numbers may be faster but use more GPU memory [points_per_batch]';
            'Filtering threshold in [0,1], using the model''s predicted mask quality [pred_iou_thresh]';
            'Filtering threshold in [0,1], using the stability of the mask under changes to the cutoff used to binarize the model''s mask predictions [stability_score_thresh]';
            'The box IoU cutoff used by non-maximal suppression to filter duplicate masks [box_nms_thresh]';
            'If >0, mask prediction will be run again on crops of the image. Sets the number of layers to run, where each layer has 2^i_layer number of image crops [crop_n_layers]';
            'The box IoU cutoff used by non-maximal suppression to filter duplicate masks between different crops [crop_nms_thresh]';
            'Sets the degree to which crops overlap. In the first crop layer, crops will overlap by this fraction of the image length. Later layers with more crops scale down this overlap [crop_overlap_ratio]';
            'The number of points-per-side sampled in layer n is scaled down by crop_n_points_downscale_factor^n [crop_n_points_downscale_factor]';
            'If >0, postprocessing will be applied to remove disconnected regions and holes in masks with area smaller than min_mask_region_area [min_mask_region_area]';
            'Execution environment(cpu is ~30-60 times slower than cuda)';
            'Show the progress bar in the interactive mode';
            'Relative to MIB installation path to "sam_links.json" with links to SAM backbones'
            'PATH to segment-anything installation';
            'Check to select path to segment-anything';
            'Check to reset settings to default values...'};

        defAns = {{sam_names{:}, find(ismember(sam_names, obj.mibModel.preferences.SegmTools.SAM.backbone))};
                    num2str(obj.mibModel.preferences.SegmTools.SAM.points_per_side); 
                    num2str(obj.mibModel.preferences.SegmTools.SAM.points_per_batch); 
                    num2str(obj.mibModel.preferences.SegmTools.SAM.pred_iou_thresh); 
                    num2str(obj.mibModel.preferences.SegmTools.SAM.stability_score_thresh); 
                    num2str(obj.mibModel.preferences.SegmTools.SAM.box_nms_thresh); 
                    num2str(obj.mibModel.preferences.SegmTools.SAM.crop_n_layers); 
                    num2str(obj.mibModel.preferences.SegmTools.SAM.crop_nms_thresh); 
                    num2str(obj.mibModel.preferences.SegmTools.SAM.crop_overlap_ratio); 
                    num2str(obj.mibModel.preferences.SegmTools.SAM.crop_n_points_downscale_factor); 
                    num2str(obj.mibModel.preferences.SegmTools.SAM.min_mask_region_area); 
                    {'cuda', 'cpu', find(ismember({'cuda', 'cpu'}, obj.mibModel.preferences.SegmTools.SAM.environment))};
                    obj.mibModel.preferences.SegmTools.SAM.showProgressBar;
                    obj.mibModel.preferences.SegmTools.SAM.linksFile;
                    obj.mibModel.preferences.SegmTools.SAM.sam_installation_path;
                    false;
                    false};
        
        dlgTitle = 'Segment-anything settings';
        options.WindowStyle = 'normal';       % [optional] style of the window
        options.PromptLines = [1, 2, 2, 2, 3, 2, 3, 2, 3, 2, 3, 1, 2, 2, 1, 1];   % [optional] number of lines for widget titles
        options.Title = sprintf('Usage of Segment-anything requires Python installation with all necessary modules. Please refer to documentation on how to set it up.\nThe selected backbone will be downloaded to DeepMIB temporary directory that can be updated from Menu->File->Preferences->External Dirs');
        options.TitleLines = 4;                   % [optional] make it twice tall, number of text lines for the title
        options.WindowWidth = 2.5;    % [optional] make window x1.2 times wider
        options.Columns = 2;    % [optional] define number of columns
        options.Focus = 1;      % [optional] define index of the widget to get focus
        options.HelpUrl = 'https://mib.helsinki.fi/downloads_systemreq_sam.html'; % [optional], an url for the Help button
        [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
        if isempty(answer); return; end
        
        if answer{17}
            answer2 = questdlg(sprintf('!!! Warning !!!\n\nYou are going to reset SAM settings to default values!\nProceed?'),'Reset SAM', 'Reset', 'Do not reset, just update', 'Cancel', 'Cancel');
            if strcmp(answer2, 'Cancel')
                return
            elseif strcmp(answer2, 'Reset')
                % restore default values
                if ~strcmp(obj.mibModel.preferences.SegmTools.SAM.backbone, 'vit_b (0.4Gb)')
                    % force to resent python during next usage
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
                obj.mibModel.preferences.SegmTools.SAM.showProgressBar = true;
                return
            end
        end

        if answer{16}
            selpath = uigetdir(obj.mibModel.preferences.SegmTools.SAM.sam_installation_path, 'segment-anything location');
            if selpath == 0; return; end
            obj.mibModel.preferences.SegmTools.SAM.sam_installation_path = selpath;
        else
            obj.mibModel.preferences.SegmTools.SAM.sam_installation_path = answer{15};
        end

        if ~strcmp(obj.mibModel.preferences.SegmTools.SAM.backbone, answer{1})
            % force to reset python during next usage
            obj.mibModel.mibPython = [];
        end
        if ~strcmp(answer{12}, obj.mibModel.preferences.SegmTools.SAM.environment)
            obj.mibModel.mibPython = [];
        end

        obj.mibModel.preferences.SegmTools.SAM.backbone = answer{1};
        obj.mibModel.preferences.SegmTools.SAM.points_per_side = str2double(answer{2});
        obj.mibModel.preferences.SegmTools.SAM.points_per_batch = str2double(answer{3});
        obj.mibModel.preferences.SegmTools.SAM.pred_iou_thresh = str2double(answer{4});
        obj.mibModel.preferences.SegmTools.SAM.stability_score_thresh = str2double(answer{5});
        obj.mibModel.preferences.SegmTools.SAM.box_nms_thresh = str2double(answer{6});
        obj.mibModel.preferences.SegmTools.SAM.crop_n_layers = str2double(answer{7});
        obj.mibModel.preferences.SegmTools.SAM.crop_nms_thresh = str2double(answer{8});
        obj.mibModel.preferences.SegmTools.SAM.crop_overlap_ratio = str2double(answer{9});
        obj.mibModel.preferences.SegmTools.SAM.crop_n_points_downscale_factor = str2double(answer{10});
        obj.mibModel.preferences.SegmTools.SAM.min_mask_region_area = str2double(answer{11});
        obj.mibModel.preferences.SegmTools.SAM.environment = answer{12};
        obj.mibModel.preferences.SegmTools.SAM.showProgressBar = logical(answer{13});

        % check for the SAM-links file
        newLinksFile = fullfile(obj.mibPath, answer{14});
        if exist(newLinksFile, 'file') == 0
            errordlg(sprintf('!!! Error !!!\n\nThe provided file:\n%s\nwith SAM links does not exist!\n\nKeeping the previous version:\n%s', newLinksFile, linksFile), 'Wrong JSON file');
        else
            obj.mibModel.preferences.SegmTools.SAM.linksFile = answer{14};
        end
        obj.mibSegmentationSAM_requirements();
        
    case 'mibSegmSAMSegment'
        obj.mibSegmentationSAM();
end
unFocus(obj.mibView.handles.mibSegmSelectedOnlyCheck);   % remove focus from hObject
end