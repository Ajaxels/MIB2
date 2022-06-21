function Prefs = generateDefaultPreferences(obj)
% function Prefs = generateDefaultPreferences(obj)
% generate default preferences for MIB and save them to mat file
%
% Return values:
% Prefs: a structure with preferences

% Copyright (C) 04.12.2020 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

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


%% ----------- COLORS PANEL -----------

% default colors for the materials of models
% old: preferences.modelMaterialColors
Prefs.Colors.ModelMaterialColors = ...
    [166 67 33;
    71 178 126;
    79 107 171;
    150 169 213;
    26 51 111;
    255 204 102 ]/255;

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
Prefs.Deep.TrainingOpt.MaxEpochs = 50;
Prefs.Deep.TrainingOpt.Shuffle = 'every-epoch';
Prefs.Deep.TrainingOpt.InitialLearnRate = 0.0005;
Prefs.Deep.TrainingOpt.LearnRateSchedule = 'piecewise';
Prefs.Deep.TrainingOpt.LearnRateDropPeriod = 10;
Prefs.Deep.TrainingOpt.LearnRateDropFactor = 0.1;
Prefs.Deep.TrainingOpt.L2Regularization = 0.0001;
Prefs.Deep.TrainingOpt.Momentum = 0.9;
Prefs.Deep.TrainingOpt.GradientDecayFactor = 0.9;    % new in version 2.71
Prefs.Deep.TrainingOpt.SquaredGradientDecayFactor = 0.9; % new in version 2.71
Prefs.Deep.TrainingOpt.ValidationFrequency = 2;
Prefs.Deep.TrainingOpt.ValidationPatience = Inf;   % new in version 2.71
Prefs.Deep.TrainingOpt.Plots = 'training-progress';  
Prefs.Deep.TrainingOpt.OutputNetwork = 'last-iteration';     % new in v 2.82, requires R2021b
Prefs.Deep.TrainingOpt.CheckpointFrequency = 1;              % new in v 2.83, requires R2022a

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

Prefs.Deep.AugOpt2D = struct();
Prefs.Deep.AugOpt2D.Fraction = .9;
Prefs.Deep.AugOpt2D.FillValue = 255;
Prefs.Deep.AugOpt2D.RandXReflection = [1 0.05];
Prefs.Deep.AugOpt2D.RandYReflection = [1 0.05];
Prefs.Deep.AugOpt2D.Rotation90 = [1 0.05];
Prefs.Deep.AugOpt2D.ReflectedRotation90 = [1 0.05];
Prefs.Deep.AugOpt2D.RandRotation = [-10 10 0.05];
Prefs.Deep.AugOpt2D.RandXScale = [1 1.1 0.05];
Prefs.Deep.AugOpt2D.RandYScale = [1 1.1 0.05];
Prefs.Deep.AugOpt2D.RandScale = [1 1.1 0.05];
Prefs.Deep.AugOpt2D.RandXShear = [-10 10 0.05];
Prefs.Deep.AugOpt2D.RandYShear = [-10 10 0.05];
Prefs.Deep.AugOpt2D.HueJitter = [-0.03 0.03 0.05];
Prefs.Deep.AugOpt2D.SaturationJitter = [-.05 .05 0.05];
Prefs.Deep.AugOpt2D.BrightnessJitter = [-.1 .1 0.05];
Prefs.Deep.AugOpt2D.ContrastJitter = [.9 1.1 0.05];
Prefs.Deep.AugOpt2D.GaussianNoise = [0 0.005 0.05]; % variance
Prefs.Deep.AugOpt2D.PoissonNoise = [1 0.05];
Prefs.Deep.AugOpt2D.ImageBlur = [0 .5 0.05];

% settings for 3D augumentation, same as for 2D but with addition of RandZReflection
Prefs.Deep.AugOpt3D = Prefs.Deep.AugOpt2D;
Prefs.Deep.AugOpt3D.RandZReflection = [1 0.05];

Prefs.Deep.DynamicMaskOpt.Method = 'Keep above threshold';  % 'Keep above threshold' or 'Keep below threshold'
Prefs.Deep.DynamicMaskOpt.ThresholdValue = 0;
Prefs.Deep.DynamicMaskOpt.InclusionThreshold = 0;     % Inclusion threshold for mask blocks

Prefs.Deep.Metrics.Accuracy = true;  % parameters for metrics evaluation
Prefs.Deep.Metrics.BFscore = false;
Prefs.Deep.Metrics.GlobalAccuracy = true;
Prefs.Deep.Metrics.IOU = true;
Prefs.Deep.Metrics.WeightedIOU = true; 

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

%% ------------  SAVE TO MAT FILE   ------------
% outputPath = fileparts(which('mib.m'));
% outputPath = fullfile(outputPath, 'Resources', 'mibDefaultPrefs.mat');
% save(outputPath, 'Prefs');



end