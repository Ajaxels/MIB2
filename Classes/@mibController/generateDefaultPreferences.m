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

function Prefs = generateDefaultPreferences(obj)
% function Prefs = generateDefaultPreferences(obj)
% generate default preferences for MIB and save them to mat file
%
% Return values:
% Prefs: a structure with preferences

%% ----------- USER INTERFACE PANEL -----------
% type of the mouse wheel action, 'scroll': change slices; 'zoom': zoom in/out
% old preferences.mouseWheel
Prefs.System.MouseWheel = 'scroll';
   
% swap the left and right mouse wheel actions, 'select': pick or draw with the left mouse button; 'pan': to move the image with the left mouse button
% old preferences.mouseButton
Prefs.System.LeftMouseButton = 'select';

% image resizing method for zooming: 'auto', 'nearest', 'bicubic'
% old preferences.imageResizeMethod
Prefs.System.ImageResizeMethod = 'auto';

% Hold Alt + mouse scoll wheel to change time points (when true)
% Hold Alt + mouse scoll wheel to return back to the slice when Alt+scroll was triggered (when false)
Prefs.System.AltWithScrollWheel = false;

% enable selection with the mouse
% old preferences.disableSelection
Prefs.System.EnableSelection = 1;

% define font structure
% old: preferences.Font
Prefs.System.Font.FontName = 'Helvetica';
Prefs.System.Font.FontUnits = 'points';
Prefs.System.Font.FontSize = 8;
Prefs.System.FontSizeDirView = 9;      % old fontSizeDir!  % font size for files and directories

% define gui scaling settings
% old: preferences.gui.
Prefs.System.GUI.scaling = 1;   % scaling factor
Prefs.System.GUI.systemscaling = 1;   % scaling factor for the operating system (on Windows->Screen resolution->Make text and other items larger or smaller->
Prefs.System.GUI.uipanel = 1;   % scaling uipanel
Prefs.System.GUI.uibuttongroup = 1;   % scaling uibuttongroup
Prefs.System.GUI.uitab = 1;   % scaling uitab
Prefs.System.GUI.uitabgroup = 1;   % scaling uitabgroup
Prefs.System.GUI.axes = 1;   % scaling axes
Prefs.System.GUI.uitable = 1;   % scaling uicontrol
Prefs.System.GUI.uicontrol = 1;   % scaling uicontrol

% last used path from previous session
% old: preferences.lastpath
Prefs.System.Dirs.LastPath = '';
% ------- List of recent dirs from where images were loaded
% old: preferences.recentDirs
Prefs.System.Dirs.RecentDirs = {};
Prefs.System.Dirs.RecentDirsNumber = 14;

% time in days since the previus update check
% old: preferences.updateChecked
Prefs.System.Update.SinceLastCheck = 0; 
% old: was not encoded, 30 days
% Recheck period for the update, in days
Prefs.System.Update.RecheckPeriod = 30; 

% ------ File extensions --------
BioFormats = {'nii','mov','pic','ics','ids','lei','stk','nd','nd2','sld','pict'...
    ,'lsm','mdb','psd','img','hdr','svs','dv','r3d','dcm','dicom','fits','liff'...
    ,'jp2','lif','l2d','mnc','mrc','oib','oif','pgm','zvi','gel','ims','dm3','naf'...
    ,'seq','xdce','ipl','mrw','mng','nrrd','ome','amiramesh','labels','fli'...
    ,'arf','al3d','sdt','czi','c01','flex','ipw','raw','ipm','xv','lim','nef','apl','mtb'...
    ,'tnb','obsep','cxd','vws','xys','xml','dm4','ndpi'};
StdImgFormats = imformats;  % get readable image formats

% add video formats
if verLessThan('matlab', '8.0') % obj.matlabVersion < 8.0
    video_formats = mmreader.getFileFormats(); %#ok<DMMR> % get readable image formats
else
    video_formats = VideoReader.getFileFormats(); % get readable image formats
end
StdImgFormats = [StdImgFormats.ext 'mrc' 'rec' 'am' 'nrrd' 'h5' 'xml' 'st' 'preali' 'mibImg' {video_formats.Extension}];

% standard image extensions
% old: preferences.Filefilter.stdExt
Prefs.System.Files.StdExt = sort(StdImgFormats);
% standard image extensions, virtual mode
% old: preferences.Filefilter.stdVirtExt
Prefs.System.Files.StdVirtExt = sort({'h5','hdf5','xml'});
% bioformats
% old: preferences.Filefilter.bioExt
Prefs.System.Files.BioFormatsExt = sort(BioFormats);
% bioformats, virtual mode
% old: preferences.Filefilter.bioVirtExt
Prefs.System.Files.BioFormatsVirtExt = sort([{'am'}, BioFormats]);
Prefs.System.RenderingEngine = 'Viewer3d, R2022b';   % default rendering engine from R2022b, alternative is "Volshow, R2018b"

%% ----------- COLORS PANEL -----------

% default colors for the materials of models
% old: preferences.modelMaterialColors
Prefs.Colors.ModelMaterialColors = ...
    [166 67 33;
    79 107 171;
    255 204 102;
    150 169 213;
    71 178 126;
    26 51 111] /255;

% Default LUT for color channels
% old: preferences.lutColors
Prefs.Colors.LUTColors = [
    1 0 0     % red
    0 1 0     % green
    0 0 1     % blue
    1 0 1     % purple
    1 1 0     % yellow
    1 .65 0]; % orange

% color for the selection layer
% old: preferences.selectioncolor
Prefs.Colors.SelectionColor = [0 1 0];

% color for the mask layer
% old: preferences.maskcolor
Prefs.Colors.MaskColor = [1 0 1];    % color for the mask layer

% color for annotations, see below in the preferences.SegmTools.Annotations

% Selection layer transparency
% old: preferences.mibSelectionTransparencySlider
Prefs.Colors.SelectionTransparency = 0.75;

% Mask layer transparency
% old: preferences.mibMaskTransparencySlider
Prefs.Colors.MaskTransparency = 0;

% Model layer transparency
% old: preferences.Colors.ModelTransparency
Prefs.Colors.ModelTransparency = 0.75;

% ---------- Contours settings ----------
% fast or slow method for generating contours, 
% in the "performance" method when two objects are touching each other the contour is rendered using color of an earlier material
Prefs.Styles.Contour.ThicknessRendering = 'quality'; % 'performance' or 'quality'
Prefs.Styles.Contour.ThicknessModels = 1;  % thickness of contour lines for materials of the model
Prefs.Styles.Contour.ThicknessMasks = 1;  % thickness of contour lines for masks 
Prefs.Styles.Contour.ThicknessMethodMasks = 'inwards';  % mode for making the thicker contours, 'inwards' and 'outwards'

Prefs.Styles.Masks.ShowAsContours = true;  % show masks as contours, when false as filled shapes

%% ----------- BACKUP AND UNDO PANEL -----------

% enable undo
% old: preferences.undo = 'yes'
Prefs.Undo.Enable = 1;

% total number of steps for the Undo history
% old: preferences.Undo.MaxUndoHistory
Prefs.Undo.MaxUndoHistory = 8;

% number of steps for the Undo history for whole dataset
% old: preferences.Undo.Max3dUndoHistory
Prefs.Undo.Max3dUndoHistory = 3;

%% ----------- EXTERNAL DIRECTORIES PANEL -----------
% these paths should be updated on each workstation individually
% Fiji
% old: preferences.dirs.FijiInstallationPath
Prefs.ExternalDirs.FijiInstallationPath = [];

% Omero
% old: preferences.dirs.OmeroInstallationPath
Prefs.ExternalDirs.OmeroInstallationPath = [];

% Imaris
% old: preferences.dirs.ImarisInstallationPath
Prefs.ExternalDirs.ImarisInstallationPath = [];

% BM3D
% old: preferences.dirs.bm3dInstallationPath
Prefs.ExternalDirs.bm3dInstallationPath = [];

% BM4D
% old: preferences.dirs.bm4dInstallationPath
Prefs.ExternalDirs.bm4dInstallationPath = [];

% DeepMIB network architectures
Prefs.ExternalDirs.DeepMIBDir = tempdir;

% DeepMIB network architectures
Prefs.ExternalDirs.PythonInstallationPath = [];

% Bioformats Memoizer
% old: preferences.dirs.BioFormatsMemoizerMemoDir
Prefs.ExternalDirs.BioFormatsMemoizerMemoDir = [];

% setting up directory for memoizer
Prefs.ExternalDirs.BioFormatsMemoizerMemoDir = fullfile(tempdir, 'mibVirtual');
if ispc
    if exist('c:\temp', 'dir') == 7
        if exist('c:\temp\mibVirtual', 'dir') == 0
            try
                mkdir('c:\temp\mibVirtual');
                Prefs.ExternalDirs.BioFormatsMemoizerMemoDir = 'c:\temp\mibVirtual';
            catch
                
            end
        else
            Prefs.ExternalDirs.BioFormatsMemoizerMemoDir = 'c:\temp\mibVirtual';
        end
    end
else
    Prefs.ExternalDirs.BioFormatsMemoizerMemoDir = fullfile(tempdir, 'mibVirtual');
    if exist(Prefs.ExternalDirs.BioFormatsMemoizerMemoDir, 'dir') == 0
        mkdir(Prefs.ExternalDirs.BioFormatsMemoizerMemoDir);
    end
end


%% ----------- KEY SHORTCUTS PANEL -----------
Prefs.KeyShortcuts = generateDefaultKeyShortcuts();

%% ----------- SEGMENTATION TOOLS PANEL -------

% ---------- Annotations ----------
% Annotations color
% old: preferences.SegmTools.Annotations.Color
Prefs.SegmTools.Annotations.Color = [1 1 0];
% Annotations font size
% old: preferences.SegmTools.Annotations.FontSize
Prefs.SegmTools.Annotations.FontSize = 2;
Prefs.SegmTools.Annotations.ShownExtraDepth = 0;    % show annotation of previous and following slices, when above 0

% ---------- Interpolation ----------
% Interpolation type
% old: preferences.SegmTools.Interpolation.Type
Prefs.SegmTools.Interpolation.Type = 'shape';     % 'shape', 'line'
% Interpolation number of points
% old: preferences.SegmTools.Interpolation.NoPoints
Prefs.SegmTools.Interpolation.NoPoints = 200;
% Interpolation line width for the line type
% old: preferences.SegmTools.Interpolation.LineWidth
Prefs.SegmTools.Interpolation.LineWidth = 4;

% ---------- Previous segmentation tool ----------
% fast access to the selection type tools with the 'd' shortcut
% old: preferences.SegmTools.PreviousTool = [3, 4];
Prefs.SegmTools.PreviousTool = [3, 4];

% ----------  Brush tool   ----------
% Brush eraser factor
% old: preferences.SegmTools.Brush.EraserRadiusFactor
Prefs.SegmTools.Brush.EraserRadiusFactor = 1.5;

% ---------- Superpixels preferences ----------
% old: preferences.SegmTools.Superpixels.NoWatershed
Prefs.SegmTools.Superpixels.NoWatershed = 15;
% old: preferences.SegmTools.Superpixels.InvertWatershed
Prefs.SegmTools.Superpixels.InvertWatershed = 1;
% old: preferences.SegmTools.Superpixels.NoSLIC
Prefs.SegmTools.Superpixels.NoSLIC = 220;
% old: preferences.SegmTools.Superpixels.CompactSLIC
Prefs.SegmTools.Superpixels.CompactSLIC = 99;

% ---------- Segment-anything preferences ----------
% see mibController.mibSegmSAMPanel_Callbacks for details
Prefs.SegmTools.SAM.samVersion = 1; % use SAM1 or SAM2, when == 2
Prefs.SegmTools.SAM.linksFile = ['Resources', filesep, 'sam_links.json'];     % location of sam_links.json file with SAM links settings, relative to MIB path!
Prefs.SegmTools.SAM.backbone = 'vit_b (0.4Gb)';     % 'vit_h (2.5Gb)', 'vit_l (1.2Gb)', 'vit_b (0.4Gb)'
Prefs.SegmTools.SAM.environment = 'cuda';     % 'cuda', 'cpu'
Prefs.SegmTools.SAM.points_per_side = 32;
Prefs.SegmTools.SAM.points_per_batch = 64;
Prefs.SegmTools.SAM.pred_iou_thresh =  0.88;
Prefs.SegmTools.SAM.stability_score_thresh = 0.95;
Prefs.SegmTools.SAM.box_nms_thresh = 0.7;
Prefs.SegmTools.SAM.crop_n_layers = 0;
Prefs.SegmTools.SAM.crop_nms_thresh = 0.7;
Prefs.SegmTools.SAM.crop_overlap_ratio = 0.3413; % 512/1500
Prefs.SegmTools.SAM.crop_n_points_downscale_factor = 1;
% Prefs.SegmTools.SAM.point_grids: Optional[List[np.ndarray]] = None;
Prefs.SegmTools.SAM.min_mask_region_area = 0;
% The form masks are returned in. Can be 'binary_mask', 'uncompressed_rle', or 'coco_rle'. 
% 'coco_rle' requires pycocotools. For large resolutions, 'binary_mask' may consume 
% large amounts of memory
% Prefs.SegmTools.SAM.output_mode = "binary_mask";
Prefs.SegmTools.SAM.sam_installation_path = [];
Prefs.SegmTools.SAM.showProgressBar = false;     % show or not the progress bar dialog when doing SAM segmentation with points

% define separate settings for SAM2
Prefs.SegmTools.SAM2.linksFile = ['Resources', filesep, 'sam2_links.json'];     % location of sam_links.json file with SAM links settings, relative to MIB path!
Prefs.SegmTools.SAM2.backbone = 'sam2_hiera_t (0.15Gb)';     % 'sam2_hiera_t (0.15Gb), sam2_hiera_s (0.18Gb), sam2_hiera_base_plus (0.32Gb), sam2_hiera_l (0.90Gb)'
Prefs.SegmTools.SAM2.environment = 'cuda';     % 'cuda', 'cpu'
Prefs.SegmTools.SAM2.sam_installation_path = [];
Prefs.SegmTools.SAM2.showProgressBar = false;     % s

Prefs.SegmTools.SAM2.points_per_side = 32;
Prefs.SegmTools.SAM2.points_per_batch = 64;
Prefs.SegmTools.SAM2.pred_iou_thresh = 0.8;
Prefs.SegmTools.SAM2.stability_score_thresh = 0.95;
Prefs.SegmTools.SAM2.stability_score_offset = 1.0;
Prefs.SegmTools.SAM2.crop_n_layers = 0;
Prefs.SegmTools.SAM2.box_nms_thresh = 0.7;
Prefs.SegmTools.SAM2.crop_n_points_downscale_factor = 1;
Prefs.SegmTools.SAM2.min_mask_region_area = 0;
Prefs.SegmTools.SAM2.use_m2m = false;

% Presets
Prefs.SegmTools.Presets.Annotations.Set1.ShowPrompt = true;
Prefs.SegmTools.Presets.Annotations.Set1.FocusOnValue = false;
Prefs.SegmTools.Presets.Annotations.Set1.Size = 2;     % '1 (pt 8)', '2 (pt 10)', '3 (pt 12)', '4 (pt 14)', '5 (pt 16)', '6 (pt 18)', '7 (pt 20)'
Prefs.SegmTools.Presets.Annotations.Set1.Color = [1 1 0];
Prefs.SegmTools.Presets.Annotations.Set1.ExtraSlices = 0;
Prefs.SegmTools.Presets.Annotations.Set1.DisplayAs = 'Label + Value'; % 'Label + Value', 'Marker', 'Label', 'Value'
Prefs.SegmTools.Presets.Annotations.Set2.ShowPrompt = true;
Prefs.SegmTools.Presets.Annotations.Set2.FocusOnValue = false;
Prefs.SegmTools.Presets.Annotations.Set2.Size = 4;
Prefs.SegmTools.Presets.Annotations.Set2.Color = [1 1 0];
Prefs.SegmTools.Presets.Annotations.Set2.ExtraSlices = 0;
Prefs.SegmTools.Presets.Annotations.Set2.DisplayAs = 'Label + Value'; % 'Label + Value', 'Marker', 'Label', 'Value'
Prefs.SegmTools.Presets.Annotations.Set3.ShowPrompt = true;
Prefs.SegmTools.Presets.Annotations.Set3.FocusOnValue = false;
Prefs.SegmTools.Presets.Annotations.Set3.Size = 7;
Prefs.SegmTools.Presets.Annotations.Set3.Color = [1 1 0];
Prefs.SegmTools.Presets.Annotations.Set3.ExtraSlices = 0;
Prefs.SegmTools.Presets.Annotations.Set3.DisplayAs = 'Label + Value'; % 'Label + Value', 'Marker', 'Label', 'Value'

Prefs.SegmTools.Presets.Lines3D.Set1.Click = 'Add node';
Prefs.SegmTools.Presets.Lines3D.Set1.ShiftClick = 'New tree';
Prefs.SegmTools.Presets.Lines3D.Set1.CtrlClick = 'Assign active node';
Prefs.SegmTools.Presets.Lines3D.Set1.AltClick = 'Modify active node';
Prefs.SegmTools.Presets.Lines3D.Set2.Click = 'Add node';
Prefs.SegmTools.Presets.Lines3D.Set2.ShiftClick = 'New tree';
Prefs.SegmTools.Presets.Lines3D.Set2.CtrlClick = 'Assign active node';
Prefs.SegmTools.Presets.Lines3D.Set2.AltClick = 'Modify active node';
Prefs.SegmTools.Presets.Lines3D.Set3.Click = 'Add node';
Prefs.SegmTools.Presets.Lines3D.Set3.ShiftClick = 'New tree';
Prefs.SegmTools.Presets.Lines3D.Set3.CtrlClick = 'Assign active node';
Prefs.SegmTools.Presets.Lines3D.Set3.AltClick = 'Modify active node';

Prefs.SegmTools.Presets.Brush.Set1.Radius = '2';
Prefs.SegmTools.Presets.Brush.Set1.Watershed = false;
Prefs.SegmTools.Presets.Brush.Set1.SLIC = false;
Prefs.SegmTools.Presets.Brush.Set1.Eraser = '1.5';
Prefs.SegmTools.Presets.Brush.Set2.Radius = '8';
Prefs.SegmTools.Presets.Brush.Set2.Watershed = false;
Prefs.SegmTools.Presets.Brush.Set2.SLIC = false;
Prefs.SegmTools.Presets.Brush.Set2.Eraser = '1.5';
Prefs.SegmTools.Presets.Brush.Set3.Radius = '50';
Prefs.SegmTools.Presets.Brush.Set3.Watershed = false;
Prefs.SegmTools.Presets.Brush.Set3.SLIC = false;
Prefs.SegmTools.Presets.Brush.Set3.Eraser = '1.5';

Prefs.SegmTools.Presets.BWThresholding.Set1.Adaptive = false;
Prefs.SegmTools.Presets.BWThresholding.Set1.BlackOnWhite = 'black-on-white';
Prefs.SegmTools.Presets.BWThresholding.Set1.Switch3D = false;
Prefs.SegmTools.Presets.BWThresholding.Set1.Invert = false;
Prefs.SegmTools.Presets.BWThresholding.Set1.ParameterLo = '0';
Prefs.SegmTools.Presets.BWThresholding.Set1.ParameterHi = '255';
Prefs.SegmTools.Presets.BWThresholding.Set1.SliderStep = 3;
Prefs.SegmTools.Presets.BWThresholding.Set2.Adaptive = false;
Prefs.SegmTools.Presets.BWThresholding.Set2.BlackOnWhite = 'black-on-white';
Prefs.SegmTools.Presets.BWThresholding.Set2.Switch3D = false;
Prefs.SegmTools.Presets.BWThresholding.Set2.Invert = false;
Prefs.SegmTools.Presets.BWThresholding.Set2.ParameterLo = '0';
Prefs.SegmTools.Presets.BWThresholding.Set2.ParameterHi = '128';
Prefs.SegmTools.Presets.BWThresholding.Set2.SliderStep = 3;
Prefs.SegmTools.Presets.BWThresholding.Set3.Adaptive = false;
Prefs.SegmTools.Presets.BWThresholding.Set3.BlackOnWhite = 'black-on-white';
Prefs.SegmTools.Presets.BWThresholding.Set3.Switch3D = false;
Prefs.SegmTools.Presets.BWThresholding.Set3.Invert = false;
Prefs.SegmTools.Presets.BWThresholding.Set3.ParameterLo = '128';
Prefs.SegmTools.Presets.BWThresholding.Set3.ParameterHi = '255';
Prefs.SegmTools.Presets.BWThresholding.Set3.SliderStep = 3;

Prefs.SegmTools.Presets.DragNDrop.Set1.Shift= '1';
Prefs.SegmTools.Presets.DragNDrop.Set1.Layer= 'selection'; % 'selection', 'mask', 'model'
Prefs.SegmTools.Presets.DragNDrop.Set2.Shift= '4';
Prefs.SegmTools.Presets.DragNDrop.Set2.Layer= 'selection';
Prefs.SegmTools.Presets.DragNDrop.Set3.Shift= '10';
Prefs.SegmTools.Presets.DragNDrop.Set3.Layer= 'selection';

Prefs.SegmTools.Presets.MagicWand.Set1.Method= 'Magic Wand'; % 'Magic Wand' or 'Region Grow'
Prefs.SegmTools.Presets.MagicWand.Set1.VariationLo = '6';
Prefs.SegmTools.Presets.MagicWand.Set1.VariationHi = '6';
Prefs.SegmTools.Presets.MagicWand.Set1.Radius = '0';
Prefs.SegmTools.Presets.MagicWand.Set1.Connect = 8; % 8 or 4
Prefs.SegmTools.Presets.MagicWand.Set2.Method = 'Magic Wand'; % 'Magic Wand' or 'Region Grow'
Prefs.SegmTools.Presets.MagicWand.Set2.VariationLo = '12';
Prefs.SegmTools.Presets.MagicWand.Set2.VariationHi = '12';
Prefs.SegmTools.Presets.MagicWand.Set2.Radius = '0';
Prefs.SegmTools.Presets.MagicWand.Set2.Connect = 8; % 8 or 4
Prefs.SegmTools.Presets.MagicWand.Set3.Method = 'Region Grow'; % 'Magic Wand' or 'Region Grow'
Prefs.SegmTools.Presets.MagicWand.Set3.VariationLo = '24';
Prefs.SegmTools.Presets.MagicWand.Set3.VariationHi = '24';
Prefs.SegmTools.Presets.MagicWand.Set3.Radius = '0';
Prefs.SegmTools.Presets.MagicWand.Set3.Connect = 8; % 8 or 4

Prefs.SegmTools.Presets.MembraClickTracker.Set1.Scale = '0.2';
Prefs.SegmTools.Presets.MembraClickTracker.Set1.Width = '2';
Prefs.SegmTools.Presets.MembraClickTracker.Set1.StraightLine = false;
Prefs.SegmTools.Presets.MembraClickTracker.Set1.BlackSignal = true;
Prefs.SegmTools.Presets.MembraClickTracker.Set1.RecenterView= true;
Prefs.SegmTools.Presets.MembraClickTracker.Set2.Scale = '0.2';
Prefs.SegmTools.Presets.MembraClickTracker.Set2.Width = '4';
Prefs.SegmTools.Presets.MembraClickTracker.Set2.StraightLine = false;
Prefs.SegmTools.Presets.MembraClickTracker.Set2.BlackSignal = true;
Prefs.SegmTools.Presets.MembraClickTracker.Set2.RecenterView= true;
Prefs.SegmTools.Presets.MembraClickTracker.Set3.Scale = '0.2';
Prefs.SegmTools.Presets.MembraClickTracker.Set3.Width = '4';
Prefs.SegmTools.Presets.MembraClickTracker.Set3.StraightLine = true;
Prefs.SegmTools.Presets.MembraClickTracker.Set3.BlackSignal = true;
Prefs.SegmTools.Presets.MembraClickTracker.Set3.RecenterView= true;

Prefs.SegmTools.Presets.SAM.Set1.Method = 'Interactive';
Prefs.SegmTools.Presets.SAM.Set1.Dataset = '2D, Slice'; % '2D, Slice', '3D, Stack', 4D, Dataset'
Prefs.SegmTools.Presets.SAM.Set1.Destination = 'selection'; % 'selection', 'mask', 'model'
Prefs.SegmTools.Presets.SAM.Set1.Mode = 'replace'; % 'replace', 'add', 'subtract', 'add, +next material'
Prefs.SegmTools.Presets.SAM.Set2.Method = 'Interactive';
Prefs.SegmTools.Presets.SAM.Set2.Dataset = '3D, Stack'; % '2D, Slice', '3D, Stack', 4D, Dataset'
Prefs.SegmTools.Presets.SAM.Set2.Destination = 'model'; % 'selection', 'mask', 'model'
Prefs.SegmTools.Presets.SAM.Set2.Mode = 'add'; % 'replace', 'add', 'subtract', 'add, +next material'
Prefs.SegmTools.Presets.SAM.Set3.Method = 'Landmarks';
Prefs.SegmTools.Presets.SAM.Set3.Dataset = '3D, Stack'; % '2D, Slice', '3D, Stack', 4D, Dataset'
Prefs.SegmTools.Presets.SAM.Set3.Destination = 'selection'; % 'selection', 'mask', 'model'
Prefs.SegmTools.Presets.SAM.Set3.Mode = 'replace'; % 'replace', 'add', 'subtract', 'add, +next material'

% two favorite tools available via Ctrl+D and Shift+D key shortcuts
Prefs.SegmTools.FavoriteToolA = 'Brush';    % Shift+D, one of tools within the Segmentation panel
Prefs.SegmTools.FavoriteToolB = 'Segment-anything model'; % Ctrl+D, one of tools within the Segmentation panel

%% -------------  IMAGE PROCESSING TOOLS ----------

% ---------  Image Arithmetics ---------------------
% a cell array with the recent image arithmetic functions
% old: preferences.ImageArithmetic.Actions
Prefs.ImageArithmetic.Actions = {'I = I*2'};
% a cell array with the input variables for the corresponding operation
% old: imagearithmetic.inputvars
Prefs.ImageArithmetic.InputVars = {'I'};
% a cell array with the output variables for the corresponding operation
% old: imagearithmetic.outputvars
Prefs.ImageArithmetic.OutputVars = {'I'};
% Number of stored actions
% old: imagearithmetic.no_stored_actions
Prefs.ImageArithmetic.NoStoredActions = 10;

%% ------------- VolRen -------------
Prefs.VolRen.Viewer.backgroundColor = [0 0.329 0.529]; 
Prefs.VolRen.Viewer.gradientColor = [0 0.561 1];
Prefs.VolRen.Viewer.backgroundGradient = 'on';
Prefs.VolRen.Viewer.lighting = 'on';
Prefs.VolRen.Viewer.lightColor = [1 1 1];
Prefs.VolRen.Viewer.showScaleBar = true;
Prefs.VolRen.Viewer.scaleBarUnits = 'um';
Prefs.VolRen.Viewer.showOrientationAxes = true;
Prefs.VolRen.Viewer.showBox = true;
Prefs.VolRen.Viewer.AmbientLight = 0.4;
Prefs.VolRen.Viewer.DiffuseLight = 0.4;

% 'orbit' - rotation is done around the center of the volume
% 'cursor' - rotation around the clicked object
Prefs.VolRen.Viewer.rotationMode = 'orbit'; 

Prefs.VolRen.Volume.renderer = 'VolumeRendering';
Prefs.VolRen.Volume.gradientOpacityValue = 0.3;
Prefs.VolRen.Volume.volumeAlphaCurve.x = [0 .3 .7 1];
Prefs.VolRen.Volume.volumeAlphaCurve.y = [1 1 0 0];
Prefs.VolRen.Volume.isosurfaceValue = 0.5;
Prefs.VolRen.Volume.colormapName = 'gray';
Prefs.VolRen.Volume.colormapInvert = true;
Prefs.VolRen.Volume.colormapBlackPoint = 0;
Prefs.VolRen.Volume.colormapWhitePoint = 255;
Prefs.VolRen.Volume.markerSize = 15;

Prefs.VolRen.Animation.noFrames = 120;  % default number of frames
Prefs.VolRen.Animation.animationPath = struct();

%% ------------- DeepMIB -------------
% old: preferences.Deep
Prefs.Deep.OriginalTrainingImagesDir = '';
Prefs.Deep.OriginalPredictionImagesDir = '';
Prefs.Deep.ImageFilenameExtension = {'AM'};
Prefs.Deep.ResultingImagesDir = '';
Prefs.Deep.CompressProcessedImages = false;
Prefs.Deep.CompressProcessedModels = true;
Prefs.Deep.ValidationFraction = 0.25;
Prefs.Deep.MiniBatchSize = 1;
Prefs.Deep.RandomGeneratorSeed = 2;
Prefs.Deep.RelativePaths = false;

Prefs.Deep.TrainingOpt.solverName = 'adam';
Prefs.Deep.TrainingOpt.MaxEpochs = 500;
Prefs.Deep.TrainingOpt.Shuffle = 'every-epoch';
Prefs.Deep.TrainingOpt.InitialLearnRate = 0.001;
Prefs.Deep.TrainingOpt.LearnRateSchedule = 'piecewise';
Prefs.Deep.TrainingOpt.LearnRateDropPeriod = 50;
Prefs.Deep.TrainingOpt.LearnRateDropFactor = 0.9;
Prefs.Deep.TrainingOpt.L2Regularization = 0.0001;
Prefs.Deep.TrainingOpt.Momentum = 0.9;
Prefs.Deep.TrainingOpt.GradientDecayFactor = 0.9;    % new in version 2.71
Prefs.Deep.TrainingOpt.SquaredGradientDecayFactor = 0.999; % new in version 2.71
Prefs.Deep.TrainingOpt.ValidationFrequency = 0.2;
Prefs.Deep.TrainingOpt.ValidationPatience = Inf;   % new in version 2.71
Prefs.Deep.TrainingOpt.Plots = 'training-progress';  
Prefs.Deep.TrainingOpt.OutputNetwork = 'last-iteration';     % new in v 2.82, requires R2021b
Prefs.Deep.TrainingOpt.CheckpointFrequency = 200;              % new in v 2.83, requires R2022a

Prefs.Deep.InputLayerOpt.Normalization = 'none';
Prefs.Deep.InputLayerOpt.Mean = [];
Prefs.Deep.InputLayerOpt.StandardDeviation = [];
Prefs.Deep.InputLayerOpt.Min = [];
Prefs.Deep.InputLayerOpt.Max = [];

Prefs.Deep.ActivationLayerOpt.clippedReluLayer.Ceiling = 10;
Prefs.Deep.ActivationLayerOpt.leakyReluLayer.Scale = 0.01;
Prefs.Deep.ActivationLayerOpt.eluLayer.Alpha = 1;

Prefs.Deep.SegmentationLayerOpt.focalLossLayer.Alpha = 0.25;
Prefs.Deep.SegmentationLayerOpt.focalLossLayer.Gamma = 2;
Prefs.Deep.SegmentationLayerOpt.dicePixelCustom.ExcludeExerior = false;     % exclude exterior class from calculation of the loss function

Prefs.Deep.AugOpt2D = mibDeepGenerateDefaultAugmentationSettings('2D');
Prefs.Deep.AugOpt3D = mibDeepGenerateDefaultAugmentationSettings('3D');

Prefs.Deep.DynamicMaskOpt.Method = 'Keep above threshold';  % 'Keep above threshold' or 'Keep below threshold'
Prefs.Deep.DynamicMaskOpt.ThresholdValue = 0;
Prefs.Deep.DynamicMaskOpt.InclusionThreshold = 0;     % Inclusion threshold for mask blocks

Prefs.Deep.Metrics.Accuracy = true;  % parameters for metrics evaluation
Prefs.Deep.Metrics.BFscore = false;
Prefs.Deep.Metrics.GlobalAccuracy = true;
Prefs.Deep.Metrics.IOU = true;
Prefs.Deep.Metrics.WeightedIOU = true; 

% Settings for sending 
Prefs.Deep.SendReports.T_SendReports = false;   % main switch send or not the reports
Prefs.Deep.SendReports.TO_email = 'user@gmail.com';
Prefs.Deep.SendReports.SMTP_server = 'smtp-relay.brevo.com';
Prefs.Deep.SendReports.SMTP_port = '587';
Prefs.Deep.SendReports.SMTP_auth = true;
Prefs.Deep.SendReports.SMTP_starttls = true;
Prefs.Deep.SendReports.SMTP_username = 'user@gmail.com';
Prefs.Deep.SendReports.SMTP_password = '';
Prefs.Deep.SendReports.sendWhenFinished = false;
Prefs.Deep.SendReports.sendDuringRun = false;


%% ----------- TIP OF THE DAY --------------
% index of the next tip to show
% old: preferences.Tips.CurrentTipIndex
Prefs.Tips.CurrentTipIndex = 1;

% show or not the tips during startup
% old: preferences.Tips.ShowTips
Prefs.Tips.ShowTips = 1;

% List of files with tips, have to be initiated on the target workstation
% old: preferences.Tips.Files
Prefs.Tips.Files = [];

% tips of a day settings
% -> moved to getDefaultParameters, as those needs to be updated each MIB session
% tipFolder = fullfile(obj.mibPath, 'Resources', 'tips', '*.html');
% tipsFiles = dir(tipFolder);
% Prefs.Tips.Files = cell([numel(tipsFiles), 1]); % path to the tip files
% for i=1:numel(tipsFiles)
%     Prefs.Tips.Files{i} = fullfile(fullfile(obj.mibPath, 'Resources', 'tips'), tipsFiles(i).name);
% end

%%  ----------- USER SETTINGS --------------
Prefs.Users.Tiers.logStartDate = datetime('now');
Prefs.Users.Tiers.collectedPoints = 0;    % user points accumulated to unlock tiers in MIB
Prefs.Users.Tiers.mouseTravelDistance = 0;    % in meters, movement of mouse over the screen without painting in meters, directly translated into points
Prefs.Users.Tiers.brushTravelDistance = 0;    % in meters, movement of mouse during use of brush tool, translated into points as distance x10
Prefs.Users.Tiers.tierLevel = 1;

% specific tools counts
Prefs.Users.Tiers.numberOfLoadedDatasets = 0;   
Prefs.Users.Tiers.numberOfImageFilterings = 0;  
Prefs.Users.Tiers.numberOfBatchProcessings = 0; 
Prefs.Users.Tiers.numberOfSnapAndMovies = 0; 
Prefs.Users.Tiers.numberOfBall3D = 0;   
Prefs.Users.Tiers.numberOfLine3D = 0;   
Prefs.Users.Tiers.numberOfAnnotations = 0; 
Prefs.Users.Tiers.numberOfBWThresholdings = 0; 
Prefs.Users.Tiers.numberOfDragDropMaterials = 0;    
Prefs.Users.Tiers.numberOfLassos = 0;   
Prefs.Users.Tiers.numberOfMagicWands = 0; 
Prefs.Users.Tiers.numberOfObjectPickers = 0;    
Prefs.Users.Tiers.numberOfMembraneClickTrackers = 0; 
Prefs.Users.Tiers.numberOfSAMclicks = 0;    
Prefs.Users.Tiers.numberOfSpots = 0;    
Prefs.Users.Tiers.numberOfGraphcuts = 0;    
Prefs.Users.Tiers.numberOfTrainedDeepNetworks = 0; 
Prefs.Users.Tiers.numberOfInferencedDeepNetworks = 0; 
Prefs.Users.Tiers.numberOfMeasurements = 0; 
Prefs.Users.Tiers.numberOfGetStats = 0;    
Prefs.Users.Tiers.numberOfKeyShortcuts = 0; % key shortcuts

Prefs.Users.singleToolScores = 0.5;   % score awarded for a single standard tool use (i.e. Ball3D or spot)
Prefs.Users.tierPointsCoef = 500;  % for points calculations, as nextTier = tierPointsCoef * 2^[userTier];
                                   % requires to move brush for
                                   % (500*2^1)/10 meters to reach level 2, i.e. 1 brush meter is equeal to 10 mouse move meters
                                   % requires to move mouse for (500*2^1)/1 meters to reach level 2
Prefs.Users.tierLevelRanks = {...
    '1 - Microbe Enthusiast', ...
    '2 - Bacterial Boss', ...
    '3 - Organelle Magician', ...
    '4 - Mitochondria Navigator', ...
    '5 - Nucleus Ninja', ...
    '6 - Synapse Surfer', ...
    '7 - Cell Explorer', ...
    '8 - Magnification Maestro', ...
    '9 - Microscopy Mastermind', ...
    '10 - MIB Guru' };


%% ------------  SAVE TO MAT FILE   ------------
% outputPath = fileparts(which('mib.m'));
% outputPath = fullfile(outputPath, 'Resources', 'mibDefaultPrefs.mat');
% save(outputPath, 'Prefs');



end