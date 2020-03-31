function getDefaultParameters(obj)
% function getDefaultParameters()
% Set default or/and stored from a previous session parameters of MIB
%
% This function runs during initialization of mibController.m
%
% Parameters:
%
%
% Return values:

% %|
% @b Examples:
% @code mibController.getDefaultParameters();  // get default parameters and restore preferences @endcode
% @code obj.getDefaultParameters();   // Call within the class; get default parameters and restore preferences @endcode

% Copyright (C) 04.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%
global mibPath;

%% Restore preferences from the last time
prefdir = getPrefDir();
prefsFn = fullfile(prefdir, 'mib.mat');
if exist(prefsFn, 'file') ~= 0
    load(prefsFn); %#ok<LOAD>
    disp(['MIB: parameters file: ', prefsFn]);
end
if ispc
    start_path = 'C:';
else
    start_path = '/';
end

% set the global preferences
% see also mibPreferencesController.defaultBtn_Callback()
obj.mibModel.preferences.mouseWheel = 'scroll';  % type of the mouse wheel action, 'scroll': change slices; 'zoom': zoom in/out
obj.mibModel.preferences.mouseButton = 'select'; % swap the left and right mouse wheel actions, 'select': pick or draw with the left mouse button; 'pan': to move the image with the left mouse button
obj.mibModel.preferences.undo = 'yes';   % enable undo
obj.mibModel.preferences.imageResizeMethod = 'auto'; % image resizing method for zooming
obj.mibModel.preferences.disableSelection = 0;    % disable selection with the mouse
obj.mibModel.preferences.maskcolor = [255 0 255]/255;    % color for the mask layer
obj.mibModel.preferences.selectioncolor = [0 255 0]/255; % color for the selection layer
obj.mibModel.preferences.modelMaterialColors = [166 67 33;       % default colors for the materials of models
    71 178 126;
    79 107 171;
    150 169 213;
    26 51 111;
    255 204 102 ]/255;
obj.mibModel.preferences.mibSelectionTransparencySlider = .75;       % transparency of the selection layer
obj.mibModel.preferences.mibMaskTransparencySlider = 0;              % transparency of the mask layer
obj.mibModel.preferences.mibModelTransparencySlider = .75;           % transparency of the model layer
obj.mibModel.preferences.maxUndoHistory = 8;         % number of steps for the Undo history
obj.mibModel.preferences.max3dUndoHistory = 3;       % number of steps for the Undo history for whole dataset
obj.mibModel.preferences.lastSegmTool = [3, 4];  % fast access to the selection type tools with the 'd' shortcut
obj.mibModel.preferences.annotationColor = [1 1 0];  % color for annotations
obj.mibModel.preferences.annotationFontSize = 2;     % font size for annotations
obj.mibModel.preferences.interpolationType = 'shape';    % type of the interpolator to use
obj.mibModel.preferences.interpolationNoPoints = 200;     % number of points to use for the interpolation
obj.mibModel.preferences.interpolationLineWidth = 4;      % line width for the 'line' interpotator
obj.mibModel.preferences.lutColors = [       % add colors for color channels
    1 0 0     % red
    0 1 0     % green
    0 0 1     % blue
    1 0 1     % purple
    1 1 0     % yellow
    1 .65 0]; % orange
obj.mibModel.preferences.eraserRadiusFactor = 1.4;   % magnifying factor for the eraser
obj.mibModel.preferences.lastpath = start_path;      % define starting path

% default parameters for CLAHE
obj.mibModel.preferences.CLAHE.Mode = 'Current stack (3D)';
obj.mibModel.preferences.CLAHE.NumTiles = [8 8];
obj.mibModel.preferences.CLAHE.ClipLimit = 0.01;
obj.mibModel.preferences.CLAHE.NBins = 256;
obj.mibModel.preferences.CLAHE.Distribution = 'uniform';
obj.mibModel.preferences.CLAHE.Alpha = 0.4;

% define default parameters for slic/watershed superpixels
obj.mibModel.preferences.superpixels.watershed_n = 15;
obj.mibModel.preferences.superpixels.watershed_invert = 1;
obj.mibModel.preferences.superpixels.slic_n = 220;
obj.mibModel.preferences.superpixels.slic_compact = 50;

obj.mibModel.preferences.imagearithmetic.actions = {'I = I*2'};     % cell array with the recent image arithmetic functions
obj.mibModel.preferences.imagearithmetic.inputvars = {'I'};     % cell array with the input variables for the corresponding operation
obj.mibModel.preferences.imagearithmetic.outputvars = {'I'};     % cell array with the output variables for the corresponding operation
obj.mibModel.preferences.imagearithmetic.no_stored_actions = 10;

obj.mibModel.preferences.updateChecked = 0;     % time of the previus update check

% size of the grid for BW Mask thresholding
obj.mibModel.preferences.corrGridrunSize = 200;

% add default folders
obj.mibModel.preferences.dirs.fijiInstallationPath = [];
obj.mibModel.preferences.dirs.omeroInstallationPath = [];

% setting up directory for memoizer
obj.mibModel.preferences.dirs.BioFormatsMemoizerMemoDir = fullfile(tempdir, 'mibVirtual');
if ispc
    if exist('c:\temp', 'dir') == 7
        if exist('c:\temp\mibVirtual', 'dir') == 0
            try
                mkdir('c:\temp\mibVirtual');
                obj.mibModel.preferences.dirs.BioFormatsMemoizerMemoDir = 'c:\temp\mibVirtual';
            catch
                
            end
        else
            obj.mibModel.preferences.dirs.BioFormatsMemoizerMemoDir = 'c:\temp\mibVirtual';
        end
    end
else
    obj.mibModel.preferences.dirs.BioFormatsMemoizerMemoDir = fullfile(tempdir, 'mibVirtual');
    if exist(obj.mibModel.preferences.dirs.BioFormatsMemoizerMemoDir, 'dir') == 0
        mkdir(obj.mibModel.preferences.dirs.BioFormatsMemoizerMemoDir);
    end
end

% define gui scaling settings
obj.mibModel.preferences.gui.scaling = 1;   % scaling factor
obj.mibModel.preferences.gui.systemscaling = 1;   % scaling factor for the operating system (on Windows->Screen resolution->Make text and other items larger or smaller->
obj.mibModel.preferences.gui.uipanel = 1;   % scaling uipanel
obj.mibModel.preferences.gui.uibuttongroup = 1;   % scaling uibuttongroup
obj.mibModel.preferences.gui.uitab = 1;   % scaling uitab
obj.mibModel.preferences.gui.uitabgroup = 1;   % scaling uitabgroup
obj.mibModel.preferences.gui.axes = 1;   % scaling axes
obj.mibModel.preferences.gui.uitable = 1;   % scaling uicontrol
obj.mibModel.preferences.gui.uicontrol = 1;   % scaling uicontrol

% define settings for DeepMIB
obj.mibModel.preferences.deep.solverName = 'adam';
obj.mibModel.preferences.deep.MaxEpochs = 50;
obj.mibModel.preferences.deep.MiniBatchSize = 4;
obj.mibModel.preferences.deep.Shuffle = 'once';
obj.mibModel.preferences.deep.InitialLearnRate = 0.0005;
obj.mibModel.preferences.deep.LearnRateSchedule = 'piecewise';
obj.mibModel.preferences.deep.LearnRateDropPeriod = 10;
obj.mibModel.preferences.deep.LearnRateDropFactor = 0.1;
obj.mibModel.preferences.deep.L2Regularization = 0.0001;
obj.mibModel.preferences.deep.Momentum = 0.9;
obj.mibModel.preferences.deep.ValidationFrequency = 400;
obj.mibModel.preferences.deep.Plots = 'training-progress';
obj.mibModel.preferences.deep.OriginalTrainingImagesDir = obj.mibModel.myPath;
obj.mibModel.preferences.deep.OriginalPredictionImagesDir = obj.mibModel.myPath;
obj.mibModel.preferences.deep.ImageFilenameExtension = {'.AM'};
obj.mibModel.preferences.deep.ResultingImagesDir = obj.mibModel.myPath;
obj.mibModel.preferences.deep.CompressProcessedImages = false;
obj.mibModel.preferences.deep.ValidationFraction = {0.25};

obj.mibModel.preferences.deep.aug2D.FillValue = 255;  % settings for 2D augumentation
obj.mibModel.preferences.deep.aug2D.RandXReflection = true;
obj.mibModel.preferences.deep.aug2D.RandYReflection = true;
obj.mibModel.preferences.deep.aug2D.RandRotation = [-45, 45];  
obj.mibModel.preferences.deep.aug2D.RandScale = [.95 1.05];
obj.mibModel.preferences.deep.aug2D.RandXScale = [.95 1.05];
obj.mibModel.preferences.deep.aug2D.RandYScale = [.95 1.05];
obj.mibModel.preferences.deep.aug2D.RandXShear = [-5 5];
obj.mibModel.preferences.deep.aug2D.RandYShear = [-5 5];

% define keyboard shortcuts
maxShortCutIndex = 32;  % total number of shortcuts
obj.mibModel.preferences.KeyShortcuts.shift(1:maxShortCutIndex) = 0;
obj.mibModel.preferences.KeyShortcuts.control(1:maxShortCutIndex) = 0;
obj.mibModel.preferences.KeyShortcuts.alt(1:maxShortCutIndex) = 0;

obj.mibModel.preferences.KeyShortcuts.Key{1} = '1';
obj.mibModel.preferences.KeyShortcuts.Action{1} = 'Switch dataset to XY orientation';
obj.mibModel.preferences.KeyShortcuts.alt(1) = 1;

obj.mibModel.preferences.KeyShortcuts.Key{2} = '2';
obj.mibModel.preferences.KeyShortcuts.Action{2} = 'Switch dataset to ZY orientation';
obj.mibModel.preferences.KeyShortcuts.alt(2) = 1;

obj.mibModel.preferences.KeyShortcuts.Key{3} = '3';
obj.mibModel.preferences.KeyShortcuts.Action{3} = 'Switch dataset to ZX orientation';
obj.mibModel.preferences.KeyShortcuts.alt(3) = 1;

obj.mibModel.preferences.KeyShortcuts.Key{4} = 'i';
obj.mibModel.preferences.KeyShortcuts.Action{4} = 'Interpolate selection';

obj.mibModel.preferences.KeyShortcuts.Key{5} = 'i';
obj.mibModel.preferences.KeyShortcuts.Action{5} = 'Invert image';
obj.mibModel.preferences.KeyShortcuts.control(5) = 1;

obj.mibModel.preferences.KeyShortcuts.Key{6} = 'a';
obj.mibModel.preferences.KeyShortcuts.Action{6} = 'Add to selection to material';

obj.mibModel.preferences.KeyShortcuts.Key{7} = 's';
obj.mibModel.preferences.KeyShortcuts.Action{7} = 'Subtract from material';

obj.mibModel.preferences.KeyShortcuts.Key{8} = 'r';
obj.mibModel.preferences.KeyShortcuts.Action{8} = 'Replace material with current selection';

obj.mibModel.preferences.KeyShortcuts.Key{9} = 'c';
obj.mibModel.preferences.KeyShortcuts.Action{9} = 'Clear selection';

obj.mibModel.preferences.KeyShortcuts.Key{10} = 'f';
obj.mibModel.preferences.KeyShortcuts.Action{10} = 'Fill the holes in the Selection layer';

obj.mibModel.preferences.KeyShortcuts.Key{11} = 'z';
obj.mibModel.preferences.KeyShortcuts.Action{11} = 'Erode the Selection layer';

obj.mibModel.preferences.KeyShortcuts.Key{12} = 'x';
obj.mibModel.preferences.KeyShortcuts.Action{12} = 'Dilate the Selection layer';

obj.mibModel.preferences.KeyShortcuts.Key{13} = 'q';
obj.mibModel.preferences.KeyShortcuts.Action{13} = 'Zoom out/Previous slice';

obj.mibModel.preferences.KeyShortcuts.Key{14} = 'w';
obj.mibModel.preferences.KeyShortcuts.Action{14} = 'Zoom in/Next slice';

obj.mibModel.preferences.KeyShortcuts.Key{15} = 'downarrow';
obj.mibModel.preferences.KeyShortcuts.Action{15} = 'Previous slice';

obj.mibModel.preferences.KeyShortcuts.Key{16} = 'uparrow';
obj.mibModel.preferences.KeyShortcuts.Action{16} = 'Next slice';

obj.mibModel.preferences.KeyShortcuts.Key{17} = 'space';
obj.mibModel.preferences.KeyShortcuts.Action{17} = 'Show/hide the Model layer';

obj.mibModel.preferences.KeyShortcuts.Key{18} = 'space';
obj.mibModel.preferences.KeyShortcuts.Action{18} = 'Show/hide the Mask layer';
obj.mibModel.preferences.KeyShortcuts.control(18) = 1;

obj.mibModel.preferences.KeyShortcuts.Key{19} = 'space';
obj.mibModel.preferences.KeyShortcuts.Action{19} = 'Fix selection to material';
obj.mibModel.preferences.KeyShortcuts.shift(19) = 1;

obj.mibModel.preferences.KeyShortcuts.Key{20} = 's';
obj.mibModel.preferences.KeyShortcuts.Action{20} = 'Save image as...';
obj.mibModel.preferences.KeyShortcuts.control(20) = 1;

obj.mibModel.preferences.KeyShortcuts.Key{21} = 'c';
obj.mibModel.preferences.KeyShortcuts.Action{21} = 'Copy to buffer selection from the current slice';
obj.mibModel.preferences.KeyShortcuts.control(21) = 1;

obj.mibModel.preferences.KeyShortcuts.Key{22} = 'v';
obj.mibModel.preferences.KeyShortcuts.Action{22} = 'Paste buffered selection to the current slice';
obj.mibModel.preferences.KeyShortcuts.control(22) = 1;

obj.mibModel.preferences.KeyShortcuts.Key{23} = 'e';
obj.mibModel.preferences.KeyShortcuts.Action{23} = 'Toggle between the selected material and exterior';

obj.mibModel.preferences.KeyShortcuts.Key{24} = 'd';
obj.mibModel.preferences.KeyShortcuts.Action{24} = 'Loop through the list of favourite segmentation tools';

obj.mibModel.preferences.KeyShortcuts.Key{25} = 'leftarrow';
obj.mibModel.preferences.KeyShortcuts.Action{25} = 'Previous time point';

obj.mibModel.preferences.KeyShortcuts.Key{26} = 'rightarrow';
obj.mibModel.preferences.KeyShortcuts.Action{26} = 'Next time point';

obj.mibModel.preferences.KeyShortcuts.Key{27} = 'z';
obj.mibModel.preferences.KeyShortcuts.Action{27} = 'Undo/Redo last action';
obj.mibModel.preferences.KeyShortcuts.control(27) = 1;

obj.mibModel.preferences.KeyShortcuts.Key{28} = 'f';
obj.mibModel.preferences.KeyShortcuts.Action{28} = 'Find material under cursor';
obj.mibModel.preferences.KeyShortcuts.control(28) = 1;

obj.mibModel.preferences.KeyShortcuts.Key{29} = 'v';
obj.mibModel.preferences.KeyShortcuts.Action{29} = 'Paste buffered selection to all slices';
obj.mibModel.preferences.KeyShortcuts.control(29) = 1;
obj.mibModel.preferences.KeyShortcuts.shift(29) = 1;

obj.mibModel.preferences.KeyShortcuts.Key{30} = 'm';
obj.mibModel.preferences.KeyShortcuts.Action{30} = 'Add measurement (Measure tool)';

obj.mibModel.preferences.KeyShortcuts.Key{31} = 'e';
obj.mibModel.preferences.KeyShortcuts.control(31) = 1;
obj.mibModel.preferences.KeyShortcuts.Action{31} = 'Toggle current and previous buffer';

% add a new key shortcut to the end of the list
obj.mibModel.preferences.KeyShortcuts.Key{maxShortCutIndex} = 'n';
obj.mibModel.preferences.KeyShortcuts.Action{maxShortCutIndex} = 'Increse active material index by 1 for models with 65535 materials';

obj.mibModel.preferences.recentDirs = {};

% tips of a day settings
obj.mibModel.preferences.tips.currentTip = 1;   % index of the next tip to show
obj.mibModel.preferences.tips.showTips = 1;     % show or not the tips during startup
tipFolder = fullfile(obj.mibPath, 'Resources', 'tips', '*.html');
tipsFiles = dir(tipFolder);

%q = questdlg(sprintf('mib path: %s', obj.mibPath), 'yes');
%q = questdlg(sprintf('tipFolder: %s', tipFolder), 'yes');
%q = questdlg(sprintf('tipsFiles: %d', numel(tipsFiles)), 'yes');

obj.mibModel.preferences.tips.files = cell([numel(tipsFiles), 1]); % path to the tip files

for i=1:numel(tipsFiles)
    obj.mibModel.preferences.tips.files{i} = fullfile(fullfile(obj.mibPath, 'Resources', 'tips'), tipsFiles(i).name);
end

% define font structure
obj.mibModel.preferences.Font.FontName = 'Helvetica';
obj.mibModel.preferences.Font.FontUnits = 'points';
obj.mibModel.preferences.Font.FontSize = 8;
obj.mibModel.preferences.fontSizeDir = 9;        % font size for files and directories

% define file extensions
bioList = {'nii','mov','pic','ics','ids','lei','stk','nd','nd2','sld','pict'...
    ,'lsm','mdb','psd','img','hdr','svs','dv','r3d','dcm','dicom','fits','liff'...
    ,'jp2','lif','l2d','mnc','mrc','oib','oif','pgm','zvi','gel','ims','dm3','naf'...
    ,'seq','xdce','ipl','mrw','mng','nrrd','ome','amiramesh','labels','fli'...
    ,'arf','al3d','sdt','czi','c01','flex','ipw','raw','ipm','xv','lim','nef','apl','mtb'...
    ,'tnb','obsep','cxd','vws','xys','xml','dm4'};
image_formats = imformats;  % get readable image formats
if obj.matlabVersion < 8.0
    video_formats = mmreader.getFileFormats(); %#ok<DMMR> % get readable image formats
else
    video_formats = VideoReader.getFileFormats(); % get readable image formats
end
stdList = [image_formats.ext 'mrc' 'rec' 'am' 'nrrd' 'h5' 'xml' 'st' 'preali' {video_formats.Extension}];
obj.mibModel.preferences.Filefilter.stdExt = sort(stdList);
obj.mibModel.preferences.Filefilter.stdVirtExt = sort({'h5','hdf5','xml'});
obj.mibModel.preferences.Filefilter.bioExt = sort(bioList);
obj.mibModel.preferences.Filefilter.bioVirtExt = sort([{'am'}, bioList]);

%% update preferences
if exist('mib_pars', 'var') && isfield(mib_pars, 'preferences')
    realFields = fieldnames(obj.mibModel.preferences);
    loadedFields = fieldnames(mib_pars.preferences);
    % check difference between loaded and needed preferences
    if numel(setdiff(loadedFields, realFields)) + numel(setdiff(realFields, loadedFields)) == 0
        % check the font name
        fontList = listfonts();    % get available fonts
        if all(cellfun(@isempty, strfind(fontList, mib_pars.preferences.Font.FontName)))   % font does not exist
            fontName = obj.mibModel.preferences.Font.FontName;
        else        % font exist exist
            fontName = mib_pars.preferences.Font.FontName;
        end
        % update shortcuts and MIB preferences
        KeyShortcuts = obj.mibModel.preferences.KeyShortcuts;
        tipFiles = obj.mibModel.preferences.tips.files;     % store tip files
        
        if ~isfield(mib_pars.preferences.imagearithmetic, 'inputvars')  % add extra fields for the updated arithmetics
            mib_pars.preferences.imagearithmetic = obj.mibModel.preferences.imagearithmetic;
        end
        obj.mibModel.preferences = mib_pars.preferences;
        obj.mibModel.preferences.tips.files = tipFiles;     % update tip files with the current situation
        
        numberOfOldShortcuts = numel(mib_pars.preferences.KeyShortcuts.Key);
        numberOfNewShortcuts = numel(KeyShortcuts.Key);
        if numberOfOldShortcuts < numberOfNewShortcuts
            obj.mibModel.preferences.KeyShortcuts.shift(numberOfOldShortcuts+1:numberOfNewShortcuts) = KeyShortcuts.shift(numberOfOldShortcuts+1:numberOfNewShortcuts);
            obj.mibModel.preferences.KeyShortcuts.control(numberOfOldShortcuts+1:numberOfNewShortcuts) = KeyShortcuts.control(numberOfOldShortcuts+1:numberOfNewShortcuts);
            obj.mibModel.preferences.KeyShortcuts.alt(numberOfOldShortcuts+1:numberOfNewShortcuts) = KeyShortcuts.alt(numberOfOldShortcuts+1:numberOfNewShortcuts);
            obj.mibModel.preferences.KeyShortcuts.Key(numberOfOldShortcuts+1:numberOfNewShortcuts) = KeyShortcuts.Key(numberOfOldShortcuts+1:numberOfNewShortcuts);
            obj.mibModel.preferences.KeyShortcuts.Action(numberOfOldShortcuts+1:numberOfNewShortcuts) = KeyShortcuts.Action(numberOfOldShortcuts+1:numberOfNewShortcuts);
        end
        obj.mibModel.preferences.Font.FontName = fontName;
    end
    % add last path
    if isfield(mib_pars, 'lastpath')
        obj.mibModel.preferences.lastpath = mib_pars.lastpath;
    end
end
if isdir(obj.mibModel.preferences.lastpath) == 0 %#ok<ISDIR>
    obj.mibModel.preferences.lastpath = start_path;
end

% add potentially missing fields to preferences
if ~isfield(obj.mibModel.preferences.dirs, 'BioFormatsMemoizerMemoDir');  obj.mibModel.preferences.dirs.BioFormatsMemoizerMemoDir = 'c:\temp\mibVirtual'; end   % BioFormats Memoizer
if ~isfield(obj.mibModel.preferences.dirs, 'bm3dInstallationPath'); obj.mibModel.preferences.dirs.bm3dInstallationPath = []; end    % BM3D filter
if ~isfield(obj.mibModel.preferences.dirs, 'bm4dInstallationPath'); obj.mibModel.preferences.dirs.bm4dInstallationPath = []; end    % BM4D filter


%% Update Java libraries
% update Fiji and Omero libs if they are present in Matlab path already
warning_state = warning('off');     % store warning settings

%% Update External Dirs in preferences
% add BMxD to Matlab path
if ~isdeployed
    if exist(obj.mibModel.preferences.dirs.bm3dInstallationPath, 'dir') == 7; addpath(obj.mibModel.preferences.dirs.bm3dInstallationPath); end
    if exist(obj.mibModel.preferences.dirs.bm4dInstallationPath, 'dir') == 7; addpath(obj.mibModel.preferences.dirs.bm4dInstallationPath); end
end

% add Omero
if exist(obj.mibModel.preferences.dirs.omeroInstallationPath, 'dir') == 7
    if ~isdeployed
        if exist(fullfile(obj.mibModel.preferences.dirs.omeroInstallationPath, 'loadOmero.m'), 'file') == 2
            addpath(obj.mibModel.preferences.dirs.omeroInstallationPath);
            loadOmero();
        end
    else
        javapath = javaclasspath('-all');   % Get the Java classpath
        add_to_classpath(javapath, fullfile(obj.mibModel.preferences.dirs.omeroInstallationPath, 'libs'));
        import omero.*;
    end
else
    if ~isempty(obj.mibModel.preferences.dirs.omeroInstallationPath)
        fprintf('Warning! Omero path is not correct!\nPlease fix it using MIB Preferences dialog (MIB->Menu->File->Preferences->External dirs)');
    end
end

javapath = javaclasspath('-all');   % Get the Java classpath
% add Mij.jar to java class, seems to fix the problem of using MIB
% with the recent Fiji release
if all(cellfun(@isempty, strfind(javapath, 'mij.jar')))
    cPath = fullfile(obj.mibPath, 'jars', 'mij.jar');
    javaaddpath(cPath, '-end');
    fprintf('MIB: adding "%s" to Matlab java path\n', cPath);
end

% add Bio-formats java libraries
if all(cellfun(@isempty, strfind(javapath, 'bioformats_package.jar')))  %#ok<*STRCLFH>
    cPath = fullfile(obj.mibPath, 'ImportExportTools', 'BioFormats', 'bioformats_package.jar');
    javaaddpath(cPath, '-end');
    disp(['MIB: adding "' cPath '" to Matlab java path']);
end

% add ImageSelection.java for imclipboard
if all(cellfun(@isempty, strfind(javapath, 'ImageSelection')))
    cPath = fullfile(obj.mibPath, 'jars', 'ImageSelection');
    javaaddpath(cPath, '-end');
    fprintf('MIB: adding "%s" to Matlab java path\n', cPath);
end

% add MLDropTarget.java for Drag and Drop
if all(cellfun(@isempty, strfind(javapath, 'MLDropTarget')))
    cPath = fullfile(obj.mibPath, 'jars', 'MLDropTarget');
    javaaddpath(cPath, '-end');
    fprintf('MIB: adding "%s" to Matlab java path\n', cPath);
end

% Add Fiji.app
if exist(obj.mibModel.preferences.dirs.fijiInstallationPath, 'dir') == 7
    fprintf('MIB: adding Fiji libraries from "%s" .', obj.mibModel.preferences.dirs.fijiInstallationPath);
    if ~isdeployed
        addpath(fullfile(obj.mibModel.preferences.dirs.fijiInstallationPath, 'scripts'));    % add Fiji/scripts path to Matlab path
        fprintf('.');
        add_to_classpath(javapath, fullfile(obj.mibModel.preferences.dirs.fijiInstallationPath,'jars'));
        fprintf('.');
        add_to_classpath(javapath, fullfile(obj.mibModel.preferences.dirs.fijiInstallationPath,'plugins'));
        fprintf('.');
        fprintf('done\n');
    else
        % add Mij.jar to java class, seems to fix the problem of using MIB
        % with the recent Fiji release
        if all(cellfun(@isempty, strfind(javapath, 'mij.jar')))
            % Important!!!
            % during compiling include MIB/jars to the files installed for the end user
            % and do not include it into the required files to run
            cPath = fullfile(obj.mibPath, 'jars', 'mij.jar');
            javaaddpath(cPath);
            fprintf('MIB: adding %s to Matlab java path\n', cPath);
        end
        
        % Add all libraries in jars/ and plugins/ to the classpath
        add_to_classpath(javapath, fullfile(obj.mibModel.preferences.dirs.fijiInstallationPath, 'jars'));
        add_to_classpath(javapath, fullfile(obj.mibModel.preferences.dirs.fijiInstallationPath, 'plugins'));
        
        % Set the Fiji directory (and plugins.dir which is not Fiji.app/plugins/)
        java.lang.System.setProperty('ij.dir', obj.mibModel.preferences.dirs.fijiInstallationPath);
        java.lang.System.setProperty('plugins.dir', obj.mibModel.preferences.dirs.fijiInstallationPath);
    end
else
    if ~isempty(obj.mibModel.preferences.dirs.fijiInstallationPath)
        fprintf('Warning! Fiji path is not correct!\nPlease fix it using MIB Preferences dialog (MIB->Menu->File->Preferences->External dirs)');
    end
end

% add Apache POI java library for xlwrite
if ~ispc && all(cellfun(@isempty, strfind(javapath, 'poi-3.8-20120326.jar')))
    poi_path = fullfile(obj.mibPath, 'jars', 'xlwrite');
    fprintf('MIB: adding "%s" to Matlab java path\n', poi_path);
    
    javaaddpath(fullfile(poi_path, 'poi-3.8-20120326.jar'));
    javaaddpath(fullfile(poi_path, 'poi-ooxml-3.8-20120326.jar'));
    javaaddpath(fullfile(poi_path, 'poi-ooxml-schemas-3.8-20120326.jar'));
    javaaddpath(fullfile(poi_path, 'xmlbeans-2.3.0.jar'));
    javaaddpath(fullfile(poi_path, 'dom4j-1.6.1.jar'));
    javaaddpath(fullfile(poi_path, 'stax-api-1.0.1.jar'));
end
warning(warning_state);     % restore warning settings

% set Imaris path
loadImarisLib = 0;
if ~isfield(obj.mibModel.preferences.dirs, 'imarisInstallationPath')
    obj.mibModel.preferences.dirs.imarisInstallationPath = [];
    res = getenv('IMARISPATH');
    if isempty(res)
        obj.mibModel.preferences.dirs.imarisInstallationPath = [];
    else
        obj.mibModel.preferences.dirs.imarisInstallationPath = res;
        loadImarisLib = 1;
    end
else
    if exist(fullfile(obj.mibModel.preferences.dirs.imarisInstallationPath, 'XT', 'matlab'), 'dir') == 7
        setenv('IMARISPATH', obj.mibModel.preferences.dirs.imarisInstallationPath);
        loadImarisLib = 1;
    else
        obj.mibModel.preferences.dirs.imarisInstallationPath = [];
    end
end
if loadImarisLib && exist(fullfile(obj.mibModel.preferences.dirs.imarisInstallationPath, 'XT', 'matlab'), 'dir') == 7
    % Add the ImarisLib.jar package to the java class path
    if all(cellfun(@isempty, strfind(javapath, 'ImarisLib.jar')))
        javaaddpath(fullfile(obj.mibModel.preferences.dirs.imarisInstallationPath, 'XT', 'matlab', 'ImarisLib.jar'));
    end
    
end

%% Define session settings structure
% define default parameters for filters
if ~isfield(obj.mibModel.sessionSettings, 'ImageFilters') || ~isfield(obj.mibModel.sessionSettings.ImageFilters, 'TestImg')
    % preload an image used for filter previews
    obj.mibModel.sessionSettings.ImageFilters.TestImg = imread(fullfile(mibPath, 'Resources', 'test_img_for_previews.png'));
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Average.mibBatchTooltip.Info = 'Average filter<br>the filtering is done with <a href="https://www.mathworks.com/help/images/ref/imfilter.html" target="_blank">imfilter</a> function and the "<span style="color:red;">average</span>" predefined filter from <a href="https://www.mathworks.com/help/images/ref/fspecial.html" target="_blank">fspecial</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.Average.mibBatchTooltip.Info = 'Average filter, the filtering is done with imfilter (https://www.mathworks.com/help/images/ref/imfilter.html) function and the "average" predefined filter of fspecial (https://www.mathworks.com/help/images/ref/fspecial.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.Average.HSize = '3';
    obj.mibModel.sessionSettings.ImageFilters.Average.mibBatchTooltip.HSize = 'Size of the filter, specified as a positive integer or 2-element (3 element for 3D) vector of positive integers';
    obj.mibModel.sessionSettings.ImageFilters.Average.Padding = {'replicate'};
    obj.mibModel.sessionSettings.ImageFilters.Average.Padding{2} = {'replicate', 'symmetric', 'circular','custom'};
    obj.mibModel.sessionSettings.ImageFilters.Average.mibBatchTooltip.Padding = 'Outside values for "replicate" are equal the nearest array border value; for "symmetric" are computed by mirror-reflecting across the border; for "custom" are defined by the provided value; "circular" - implicitly assuming the input array is periodic';
    obj.mibModel.sessionSettings.ImageFilters.Average.PaddingValue{1} = 0;
    obj.mibModel.sessionSettings.ImageFilters.Average.PaddingValue{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.Average.mibBatchTooltip.PaddingValue = 'Padding value for the custom Padding option';
    obj.mibModel.sessionSettings.ImageFilters.Average.FilteringMode = {'corr'};
    obj.mibModel.sessionSettings.ImageFilters.Average.FilteringMode{2} = {'corr', 'conv'};
    obj.mibModel.sessionSettings.ImageFilters.Average.mibBatchTooltip.FilteringMode = 'perform multidimensional filtering using correlation (corr) or convolution (conv)';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Disk.mibBatchTooltip.Info = 'Circular averaging filter (pillbox)<br>the filtering is done with <a href="https://www.mathworks.com/help/images/ref/imfilter.html" target="_blank">imfilter</a> function and the "<span style="color:red;">disk</span>" predefined filter from <a href="https://www.mathworks.com/help/images/ref/fspecial.html" target="_blank">fspecial</a>.';
    else
        obj.mibModel.sessionSettings.ImageFilters.Disk.mibBatchTooltip.Info = 'Circular averaging filter (pillbox), the filtering is done with imfilter function (https://www.mathworks.com/help/images/ref/imfilter.html) and the "disk" predefined filter of fspecial (https://www.mathworks.com/help/images/ref/fspecial.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.Disk.Radius{1} = 3;
    obj.mibModel.sessionSettings.ImageFilters.Disk.Radius{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.Disk.mibBatchTooltip.Radius = 'Radius of a disk-shaped filter, specified as a positive number';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Entropy.mibBatchTooltip.Info = 'Local entropy filter, returns an image, where each output pixel contains the entropy (<em>-sum(p.*log2(p))</em>, where <em>p</em> contains the normalized histogram counts) of the defined neighborhood around the corresponding pixel, see details in <a href="https://www.mathworks.com/help/images/ref/entropyfilt.html" target="_blank">entropyfilt</a>.';
    else
        obj.mibModel.sessionSettings.ImageFilters.Entropy.mibBatchTooltip.Info = 'Local entropy filter, returns an image, where each output pixel contains the entropy ("-sum(p.*log2(p)", where "p" contains the normalized histogram counts) of the defined neighborhood around the corresponding pixel, see details in https://www.mathworks.com/help/images/ref/entropyfilt.html';
    end
    obj.mibModel.sessionSettings.ImageFilters.Entropy.NeighborhoodSize  = '3';
    obj.mibModel.sessionSettings.ImageFilters.Entropy.mibBatchTooltip.NeighborhoodSize = 'Size (y-by-x) of the neighborhood used to estimate the local entropy of the image; can be a single number';
    obj.mibModel.sessionSettings.ImageFilters.Entropy.StrelShape  = {'rectangle'};
    obj.mibModel.sessionSettings.ImageFilters.Entropy.StrelShape{2} = {'rectangle', 'disk'};
    obj.mibModel.sessionSettings.ImageFilters.Entropy.mibBatchTooltip.StrelShape = 'Shape of the strel element to be used';
    obj.mibModel.sessionSettings.ImageFilters.Entropy.NormalizationFactor{1} = 1;
    obj.mibModel.sessionSettings.ImageFilters.Entropy.NormalizationFactor{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.Entropy.NormalizationFactor{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.Entropy.mibBatchTooltip.NormalizationFactor = 'Normalization factor for scaling the resulting image';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Frangi.mibBatchTooltip.Info = 'Frangi filter to enhance elongated or tubular structures using Hessian-based multiscale filtering<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/fibermetric.html" target="_blank">fibermetric</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.Frangi.mibBatchTooltip.Info = 'Frangi filter to enhance elongated or tubular structures using Hessian-based multiscale filtering. The filtering is done with fibermetric (https://www.mathworks.com/help/images/ref/fibermetric.html)';        
    end
    obj.mibModel.sessionSettings.ImageFilters.Frangi.ThicknessRange  = '1 2 4 6';
    obj.mibModel.sessionSettings.ImageFilters.Frangi.mibBatchTooltip.ThicknessRange = 'Thickness of tubular structures in pixels, specified as a positive integer or vector of positive integers';
    obj.mibModel.sessionSettings.ImageFilters.Frangi.StructureSensitivity{1} = 2.55;
    obj.mibModel.sessionSettings.ImageFilters.Frangi.StructureSensitivity{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.Frangi.StructureSensitivity{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.Frangi.mibBatchTooltip.StructureSensitivity = 'The structure sensitivity is a threshold for differentiating the tubular structure from the background; calculated as 0.01*diff(getrangefromclass(I)). For example, it is 2.55 for uint8 and 0.01 for the range [0, 1]';
    obj.mibModel.sessionSettings.ImageFilters.Frangi.ObjectPolarity = {'dark'};
    obj.mibModel.sessionSettings.ImageFilters.Frangi.ObjectPolarity{2} = {'dark', 'bright'};
    obj.mibModel.sessionSettings.ImageFilters.Frangi.mibBatchTooltip.ObjectPolarity = 'dark: structures are darker than the background; bright: structures are lighter than the background';
    obj.mibModel.sessionSettings.ImageFilters.Frangi.NormalizationFactor{1} = 1;
    obj.mibModel.sessionSettings.ImageFilters.Frangi.NormalizationFactor{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.Frangi.NormalizationFactor{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.Frangi.mibBatchTooltip.NormalizationFactor = 'Normalization factor for scaling the resulting image';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Gaussian.mibBatchTooltip.Info = 'Rotationally symmetric Gaussian lowpass filter of size (Hsize) with standard deviation (Sigma).<br>The 2D filtering is done with <a href="https://www.mathworks.com/help/images/ref/imgaussfilt.html" target="_blank">imgaussfilt</a> and 3D with <a href="https://www.mathworks.com/help/images/ref/imgaussfilt3.html" target="_blank">imgaussfilt3</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.Gaussian.mibBatchTooltip.Info = 'Rotationally symmetric Gaussian lowpass filter of size (Hsize) with standard deviation (Sigma). The 2D filtering is done with imgaussfilt (https://www.mathworks.com/help/images/ref/imgaussfilt.html) and 3D with imgaussfilt3 (https://www.mathworks.com/help/images/ref/imgaussfilt3.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.Gaussian.HSize = '3';
    obj.mibModel.sessionSettings.ImageFilters.Gaussian.mibBatchTooltip.HSize = 'Size of the filter, specified as a positive integer or 2-element (3 element for 3D) vector of positive integers; HAS TO BE ODD';
    obj.mibModel.sessionSettings.ImageFilters.Gaussian.Sigma{1} = 0.6;
    obj.mibModel.sessionSettings.ImageFilters.Gaussian.Sigma{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.Gaussian.Sigma{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.Gaussian.mibBatchTooltip.Sigma = 'Standard deviation of the Gaussian distribution, normally = HSize/5';
    obj.mibModel.sessionSettings.ImageFilters.Gaussian.Padding = {'replicate'};
    obj.mibModel.sessionSettings.ImageFilters.Gaussian.Padding{2} = {'replicate', 'symmetric', 'circular','custom'};
    obj.mibModel.sessionSettings.ImageFilters.Gaussian.mibBatchTooltip.Padding = 'Outside values for "replicate" are equal the nearest array border value; for "symmetric" are computed by mirror-reflecting across the border; for "custom" are defined by the provided value; "circular" - implicitly assuming the input array is periodic';
    obj.mibModel.sessionSettings.ImageFilters.Gaussian.PaddingValue{1} = 0;
    obj.mibModel.sessionSettings.ImageFilters.Gaussian.PaddingValue{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.Gaussian.mibBatchTooltip.PaddingValue = 'Padding value for the custom Padding option';
    obj.mibModel.sessionSettings.ImageFilters.Gaussian.FilterDomain = {'auto'};
    obj.mibModel.sessionSettings.ImageFilters.Gaussian.FilterDomain{2} = {'auto', 'frequency', 'spatial'};
    obj.mibModel.sessionSettings.ImageFilters.Gaussian.mibBatchTooltip.FilterDomain = 'omain in which to perform filtering; auto: define based on internal heuristics';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Gradient.mibBatchTooltip.Info = 'Calculate image gradient<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/gradient.html" target="_blank">gradient</a> function and the acquired X,Y,Z components are converted to the resulting image as <em>sqrt(X<sup>2</sup> + Y<sup>2</sup> + Z<sup>2</sup>)</em>';
    else
        obj.mibModel.sessionSettings.ImageFilters.Gradient.mibBatchTooltip.Info = 'Calculate image gradientm, the filtering is done with gradient function (https://www.mathworks.com/help/images/ref/gradient.html) and the acquired X,Y,Z components are converted to the resulting image as "sqrt(X^2 + Y^2 + Z^2)"';        
    end
    obj.mibModel.sessionSettings.ImageFilters.Gradient.SpacingXYZ = '1';
    obj.mibModel.sessionSettings.ImageFilters.Gradient.mibBatchTooltip.SpacingXYZ = 'Spacing between points in each direction, specified as separate inputs (X,Y,Z) of scalars or a single number';
    obj.mibModel.sessionSettings.ImageFilters.Gradient.NormalizationFactor{1} = 1;
    obj.mibModel.sessionSettings.ImageFilters.Gradient.NormalizationFactor{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.Gradient.NormalizationFactor{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.Gradient.mibBatchTooltip.NormalizationFactor = 'Normalization factor for scaling the resulting image';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.LoG.mibBatchTooltip.Info = 'Filter the image using the Laplacian of Gaussian filter, which highlights the edges<br>The resulting image is converted to unsigned integers by its multiplying with the NormalizationFactor and adding half of max class integer value.  The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imfilter.html" target="_blank">imfilter</a> function and the "<span style="color:red;">log</span>" predefined filter from <a href="https://www.mathworks.com/help/images/ref/fspecial.html" target="_blank">fspecial</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.LoG.mibBatchTooltip.Info = 'Filter the image using the Laplacian of Gaussian filter, which highlights the edges. The resulting image is converted to unsigned integers by its multiplying with the NormalizationFactor and adding half of max class integer value.  The filtering is done with imfilter function (https://www.mathworks.com/help/images/ref/imfilter.html) and the "log" predefined filter of fspecial (https://www.mathworks.com/help/images/ref/fspecial.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.LoG.HSize = '5';
    obj.mibModel.sessionSettings.ImageFilters.LoG.mibBatchTooltip.HSize = 'Size of the filter, specified as a positive integer or 2-element (3 element for 3D) vector of positive integers';
    obj.mibModel.sessionSettings.ImageFilters.LoG.Sigma{1} = 1;
    obj.mibModel.sessionSettings.ImageFilters.LoG.Sigma{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.LoG.Sigma{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.LoG.mibBatchTooltip.Sigma = 'Standard deviation, specified as a positive number';
    obj.mibModel.sessionSettings.ImageFilters.LoG.NormalizationFactor{1} = 1;
    obj.mibModel.sessionSettings.ImageFilters.LoG.NormalizationFactor{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.LoG.NormalizationFactor{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.LoG.mibBatchTooltip.NormalizationFactor = 'Normalization factor for scaling the resulting image';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Motion.mibBatchTooltip.Info = 'Motion blur filter<br>the filtering is done with <a href="https://www.mathworks.com/help/images/ref/imfilter.html" target="_blank">imfilter</a> function and the "<span style="color:red;">motion</span>" predefined filter from <a href="https://www.mathworks.com/help/images/ref/fspecial.html" target="_blank">fspecial</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.Motion.mibBatchTooltip.Info = 'Motion blur filter, the filtering is done with imfilter function (https://www.mathworks.com/help/images/ref/imfilter.html) and the "motion" predefined filter of fspecial (https://www.mathworks.com/help/images/ref/fspecial.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.Motion.Length{1} = 5;
    obj.mibModel.sessionSettings.ImageFilters.Motion.Length{2} = [1 Inf];
    obj.mibModel.sessionSettings.ImageFilters.Motion.mibBatchTooltip.Length = 'Length of linear motion, specified as a numeric scalar, measured in pixels';
    obj.mibModel.sessionSettings.ImageFilters.Motion.Angle{1} = 0;
    obj.mibModel.sessionSettings.ImageFilters.Motion.Angle{2} = [0 360];
    obj.mibModel.sessionSettings.ImageFilters.Motion.mibBatchTooltip.Angle = 'Angle of the motion, specified as a numeric scalar, measured in degrees, in a counter-clockwise direction; 0 corrsponds to the X-direction';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Prewitt.mibBatchTooltip.Info = 'Prewitt filter for edge enhancement<br>the filtering is done with <a href="https://www.mathworks.com/help/images/ref/imfilter.html" target="_blank">imfilter</a> function and the "<span style="color:red;">prewitt</span>" predefined filter from <a href="https://www.mathworks.com/help/images/ref/fspecial.html" target="_blank">fspecial</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.Prewitt.mibBatchTooltip.Info = 'Prewitt filter for edge enhancement, the filtering is done with imfilter function (https://www.mathworks.com/help/images/ref/imfilter.html) and the "prewitt" predefined filter of fspecial (https://www.mathworks.com/help/images/ref/fspecial.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.Prewitt.Direction = {'X'};
    obj.mibModel.sessionSettings.ImageFilters.Prewitt.Direction{2} = {'X', 'Y', 'Z'};
    obj.mibModel.sessionSettings.ImageFilters.Prewitt.mibBatchTooltip.Direction = 'Gradient direction for the filter, Z is only used for the 3D filter';
    obj.mibModel.sessionSettings.ImageFilters.Prewitt.ReturnPart = {'both'};
    obj.mibModel.sessionSettings.ImageFilters.Prewitt.ReturnPart{2} = {'both', 'negative', 'positive'};
    obj.mibModel.sessionSettings.ImageFilters.Prewitt.mibBatchTooltip.ReturnPart = 'both: the resulting image is the absolute value of the filter; negative/positive: negative or positive part';
    obj.mibModel.sessionSettings.ImageFilters.Prewitt.NormalizationFactor{1} = 1;
    obj.mibModel.sessionSettings.ImageFilters.Prewitt.NormalizationFactor{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.Prewitt.NormalizationFactor{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.Prewitt.mibBatchTooltip.NormalizationFactor = 'Normalization factor for scaling the resulting image';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Range.mibBatchTooltip.Info = 'Local range filter, returns an image, where each output pixel contains the range value (maximum value - minimum value) of the defined neighborhood around the corresponding pixel. See details in <a href="https://www.mathworks.com/help/images/ref/rangefilt.html" target="_blank">rangefilt</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.Range.mibBatchTooltip.Info = 'Local range filter, returns an image, where each output pixel contains the range value (maximum value - minimum value) of the defined neighborhood around the corresponding pixel. See details in https://www.mathworks.com/help/images/ref/rangefilt.html';
    end
    obj.mibModel.sessionSettings.ImageFilters.Range.NeighborhoodSize  = '3';
    obj.mibModel.sessionSettings.ImageFilters.Range.mibBatchTooltip.NeighborhoodSize = 'Size (y-by-x) of the neighborhood used to estimate the local range of the image; can be a single number';
    obj.mibModel.sessionSettings.ImageFilters.Range.StrelShape  = {'rectangle'};
    obj.mibModel.sessionSettings.ImageFilters.Range.StrelShape{2} = {'rectangle', 'disk'};
    obj.mibModel.sessionSettings.ImageFilters.Range.mibBatchTooltip.StrelShape = 'Shape of the strel element to be used';
    obj.mibModel.sessionSettings.ImageFilters.Range.NormalizationFactor{1} = 1;
    obj.mibModel.sessionSettings.ImageFilters.Range.NormalizationFactor{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.Range.NormalizationFactor{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.Range.mibBatchTooltip.NormalizationFactor = 'Normalization factor for scaling the resulting image';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.SaltAndPepper.mibBatchTooltip.Info = 'Remove salt & pepper noise from image<br>The images are filtered using the median filter, after that a difference between the original and the median filtered images is taken. Pixels that have threshold higher than IntensityThreshold are considered as noise and removed';
    else
        obj.mibModel.sessionSettings.ImageFilters.SaltAndPepper.mibBatchTooltip.Info = 'Remove salt & pepper noise from image, the images are filtered using the median filter, after that a difference between the original and the median filtered images is taken. Pixels that have threshold higher than IntensityThreshold are considered as noise and removed';
    end
    obj.mibModel.sessionSettings.ImageFilters.SaltAndPepper.HSize = '3';
    obj.mibModel.sessionSettings.ImageFilters.SaltAndPepper.mibBatchTooltip.HSize = 'Size of the strel element for median filter';
    obj.mibModel.sessionSettings.ImageFilters.SaltAndPepper.IntensityThreshold{1} = 50;
    obj.mibModel.sessionSettings.ImageFilters.SaltAndPepper.IntensityThreshold{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.SaltAndPepper.mibBatchTooltip.IntensityThreshold = 'Noise intensity threshold, pixels that have intensity variation of original image -minus- median filtered image higher than this number will be removed. See <em>mibRemoveSaltAndPepperNoise.m</em> function for details.';
    obj.mibModel.sessionSettings.ImageFilters.SaltAndPepper.NoiseType = {'salt and pepper'};
    obj.mibModel.sessionSettings.ImageFilters.SaltAndPepper.NoiseType{2} = {'salt and pepper', 'salt only', 'pepper only'};
    obj.mibModel.sessionSettings.ImageFilters.SaltAndPepper.mibBatchTooltip.NoiseType = 'Noise type, salt - white noise pixels, pepper - dark noise pixels';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Sobel.mibBatchTooltip.Info = 'Sobel filter for edge enhancement<br>the filtering is done with <a href="https://www.mathworks.com/help/images/ref/imfilter.html" target="_blank">imfilter</a> function and the "sobel" predefined filter from <a href="https://www.mathworks.com/help/images/ref/fspecial.html" target="_blank">fspecial</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.Sobel.mibBatchTooltip.Info = 'Sobel filter for edge enhancement, the filtering is done with imfilter function (https://www.mathworks.com/help/images/ref/imfilter.html) and the "sobel" predefined filter of fspecial (https://www.mathworks.com/help/images/ref/fspecial.html)';        
    end
    obj.mibModel.sessionSettings.ImageFilters.Sobel.Direction = {'X'};
    obj.mibModel.sessionSettings.ImageFilters.Sobel.Direction{2} = {'X', 'Y', 'Z'};
    obj.mibModel.sessionSettings.ImageFilters.Sobel.mibBatchTooltip.Direction = 'Gradient direction for the filter, Z is only used for the 3D filter';
    obj.mibModel.sessionSettings.ImageFilters.Sobel.ReturnPart = {'both'};
    obj.mibModel.sessionSettings.ImageFilters.Sobel.ReturnPart{2} = {'both', 'negative', 'positive'};
    obj.mibModel.sessionSettings.ImageFilters.Sobel.mibBatchTooltip.ReturnPart = 'both: the resulting image is the absolute value of the filter; negative/positive: negative or positive part';
    obj.mibModel.sessionSettings.ImageFilters.Sobel.NormalizationFactor{1} = 1;
    obj.mibModel.sessionSettings.ImageFilters.Sobel.NormalizationFactor{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.Sobel.NormalizationFactor{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.Sobel.mibBatchTooltip.NormalizationFactor = 'Normalization factor for scaling the resulting image';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Std.mibBatchTooltip.Info = 'Local standard deviation of image. The value of each output pixel is the standard deviation of a neighborhood around the corresponding input pixel. The borders are extimated via symmetric padding: i.e. the values of padding pixels are a mirror reflection of the border pixels. See details in <a href="https://www.mathworks.com/help/images/ref/stdfilt.html" target="_blank">stdfilt</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.Std.mibBatchTooltip.Info = 'Local standard deviation of image. The value of each output pixel is the standard deviation of a neighborhood around the corresponding input pixel. The borders are extimated via symmetric padding: i.e. the values of padding pixels are a mirror reflection of the border pixels. See details in https://www.mathworks.com/help/images/ref/stdfilt.html';
    end
    obj.mibModel.sessionSettings.ImageFilters.Std.NeighborhoodSize  = '3';
    obj.mibModel.sessionSettings.ImageFilters.Std.mibBatchTooltip.NeighborhoodSize = 'Size (y-by-x) of the neighborhood used to estimate the local standard deviation of the image; can be a single number';
    obj.mibModel.sessionSettings.ImageFilters.Std.StrelShape  = {'rectangle'};
    obj.mibModel.sessionSettings.ImageFilters.Std.StrelShape{2} = {'rectangle', 'disk'};
    obj.mibModel.sessionSettings.ImageFilters.Std.mibBatchTooltip.StrelShape = 'Shape of the strel element to be used';
    obj.mibModel.sessionSettings.ImageFilters.Std.NormalizationFactor{1} = 1;
    obj.mibModel.sessionSettings.ImageFilters.Std.NormalizationFactor{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.Std.NormalizationFactor{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.Std.mibBatchTooltip.NormalizationFactor = 'Normalization factor for scaling the resulting image';
    
    % add common fields
    fieldNames = {'Padding', 'PaddingValue', 'FilteringMode'}; % define fields that should be copied from obj.mibModel.sessionSettings.ImageFilters.Average
    addToFilter = {'Disk', 'LoG','Motion','Prewitt','Sobel'}; % define filters to which these fields should be copied
    for filterId = 1:numel(addToFilter)
        for fieldId = 1:numel(fieldNames)
            obj.mibModel.sessionSettings.ImageFilters.(addToFilter{filterId}).(fieldNames{fieldId}) = obj.mibModel.sessionSettings.ImageFilters.Average.(fieldNames{fieldId});
            obj.mibModel.sessionSettings.ImageFilters.(addToFilter{filterId}).mibBatchTooltip.(fieldNames{fieldId}) = obj.mibModel.sessionSettings.ImageFilters.Average.mibBatchTooltip.(fieldNames{fieldId});
        end
    end
    
    obj.mibModel.sessionSettings.ImageFilters.DesiredFilterName = [];   % name of the last used filter
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Bilateral.mibBatchTooltip.Info = 'Edge preserving bilateral filtering of images with Gaussian kernels<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imbilatfilt.html" target="_blank">imbilatfilt</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.Bilateral.mibBatchTooltip.Info = 'Edge preserving bilateral filtering of images with Gaussian kernels. The filtering is done with imbilatfilt (https://www.mathworks.com/help/images/ref/imbilatfilt.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.Bilateral.degreeOfSmoothing = num2str(255^2*.01);
    obj.mibModel.sessionSettings.ImageFilters.Bilateral.mibBatchTooltip.degreeOfSmoothing = 'Degree of smoothing, specified as a positive number. The recommended value is calculated as 0.01*diff(GetRangeFromClass(I)).^2';
    obj.mibModel.sessionSettings.ImageFilters.Bilateral.spatialSigma{1} = 1;
    obj.mibModel.sessionSettings.ImageFilters.Bilateral.spatialSigma{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.Bilateral.spatialSigma{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.Bilateral.mibBatchTooltip.spatialSigma = 'Standard deviation of spatial Gaussian smoothing kernel, specified as a positive number';
    obj.mibModel.sessionSettings.ImageFilters.Bilateral.NeighborhoodSize = num2str(2*ceil(2*obj.mibModel.sessionSettings.ImageFilters.Bilateral.spatialSigma{1})+1);
    obj.mibModel.sessionSettings.ImageFilters.Bilateral.mibBatchTooltip.NeighborhoodSize = 'Neighborhood size, an odd-valued positive integer. By default, the neighborhood size is 2*ceil(2*SpatialSigma)+1 pixels';
    obj.mibModel.sessionSettings.ImageFilters.Bilateral.Padding = {'replicate'};
    obj.mibModel.sessionSettings.ImageFilters.Bilateral.Padding{2} = {'replicate', 'symmetric', 'custom'};
    obj.mibModel.sessionSettings.ImageFilters.Bilateral.mibBatchTooltip.Padding = 'Outside values for "replicate" are equal the nearest array border value; for "symmetric" are computed by mirror-reflecting across the border; for "custom" are defined by the provided value';
    obj.mibModel.sessionSettings.ImageFilters.Bilateral.PaddingValue{1} = 0;
    obj.mibModel.sessionSettings.ImageFilters.Bilateral.PaddingValue{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.Bilateral.mibBatchTooltip.PaddingValue = 'Padding value for the custom Padding option';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.AnisotropicDiffusion.mibBatchTooltip.Info = 'Edge preserving anisotropic diffusion filtering of images with Perona-Malik algorithm<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imdiffusefilt.html" target="_blank">imdiffusefilt</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.AnisotropicDiffusion.mibBatchTooltip.Info = 'Edge preserving anisotropic diffusion filtering of images with Perona-Malik algorithm. The filtering is done with imdiffusefilt (https://www.mathworks.com/help/images/ref/imdiffusefilt.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.AnisotropicDiffusion.GradientThreshold{1} = 10;
    obj.mibModel.sessionSettings.ImageFilters.AnisotropicDiffusion.GradientThreshold{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.AnisotropicDiffusion.mibBatchTooltip.GradientThreshold = 'In percentage of the image class range, controls the conduction process by classifying gradient values as an actual edge or as noise. Increasing the value of GradientThreshold smooths the image more';
    obj.mibModel.sessionSettings.ImageFilters.AnisotropicDiffusion.NumberOfIterations{1} = 5;
    obj.mibModel.sessionSettings.ImageFilters.AnisotropicDiffusion.NumberOfIterations{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.AnisotropicDiffusion.mibBatchTooltip.NumberOfIterations = 'Number of iterations to use in the diffusion process';
    obj.mibModel.sessionSettings.ImageFilters.AnisotropicDiffusion.Connectivity = {'maximal'};
    obj.mibModel.sessionSettings.ImageFilters.AnisotropicDiffusion.Connectivity{2} = {'maximal', 'minimal'};
    obj.mibModel.sessionSettings.ImageFilters.AnisotropicDiffusion.mibBatchTooltip.Connectivity = 'Connectivity of a pixel to its neighbors, maximal for 8 and minimal for 4';
    obj.mibModel.sessionSettings.ImageFilters.AnisotropicDiffusion.ConductionMethod = {'exponential'};
    obj.mibModel.sessionSettings.ImageFilters.AnisotropicDiffusion.ConductionMethod{2} = {'exponential', 'quadratic'};
    obj.mibModel.sessionSettings.ImageFilters.AnisotropicDiffusion.mibBatchTooltip.ConductionMethod = 'Exponential diffusion favors high-contrast edges over low-contrast edges. Quadratic diffusion favors wide regions over smaller regions';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.DNNdenoise.mibBatchTooltip.Info = 'Denoise image using deep neural network<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/denoiseimage.html" target="_blank">denoiseImage</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.DNNdenoise.mibBatchTooltip.Info = 'Denoise image using deep neural network. The filtering is done with denoiseimage function (https://www.mathworks.com/help/images/ref/denoiseimage.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.DNNdenoise.NetworkName = {'DnCNN'};
    obj.mibModel.sessionSettings.ImageFilters.DNNdenoise.NetworkName{2} = {'DnCNN'};
    obj.mibModel.sessionSettings.ImageFilters.DNNdenoise.mibBatchTooltip.NetworkName = 'Name of pretrained denoising deep neural network';
    obj.mibModel.sessionSettings.ImageFilters.DNNdenoise.GPUblock{1} = 512;
    obj.mibModel.sessionSettings.ImageFilters.DNNdenoise.GPUblock{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.DNNdenoise.mibBatchTooltip.GPUblock = 'Width of the image block to be denoised at once on GPU, decrease if getting out of GPU memory errors';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Median.mibBatchTooltip.Info = 'Median filtering of images in 2D or 3D. Each output pixel contains the median value in the specified neighborhood<br>The 2D filtering is done with <a href="https://www.mathworks.com/help/images/ref/medfilt2.html" target="_blank">medfilt2</a> and 3D with <a href="https://www.mathworks.com/help/images/ref/medfilt3.html" target="_blank">medfilt3</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.Median.mibBatchTooltip.Info = 'Median filtering of images in 2D or 3D. Each output pixel contains the median value in the specified neighborhood. The 2D filtering is done with medfilt2 function (https://www.mathworks.com/help/images/ref/medfilt2.html) and 3D with medfilt3 (https://www.mathworks.com/help/images/ref/medfilt3.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.Median.NeighborhoodSize  = '3';
    obj.mibModel.sessionSettings.ImageFilters.Median.mibBatchTooltip.NeighborhoodSize = 'Size (y-by-x-by-z) of the neighborhood used to calculate the median value';
    obj.mibModel.sessionSettings.ImageFilters.Median.Padding  = {'symmetric'};
    obj.mibModel.sessionSettings.ImageFilters.Median.Padding{2} = {'symmetric','zeros'};
    obj.mibModel.sessionSettings.ImageFilters.Median.mibBatchTooltip.Padding = 'symmetric: symmetrically extend the image at the boundaries; zeros: pad the image with 0s';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.NonLocalMeans.mibBatchTooltip.Info = 'Non-local means filter<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imnlmfilt.html" target="_blank">imnlmfilt</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.NonLocalMeans.mibBatchTooltip.Info = 'Non-local means filter<br>The filtering is done with imnlmfilt (https://www.mathworks.com/help/images/ref/imnlmfilt.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.NonLocalMeans.DegreeOfSmoothing = '';
    obj.mibModel.sessionSettings.ImageFilters.NonLocalMeans.mibBatchTooltip.DegreeOfSmoothing = 'Degree of smoothing (a positive number). As this value increases, the smoothing in the resulting image increases. When empty, the DegreeOfSmoothing is estimated as the standard deviation of noise from the image';
    obj.mibModel.sessionSettings.ImageFilters.NonLocalMeans.SearchWindowSize = '21';
    obj.mibModel.sessionSettings.ImageFilters.NonLocalMeans.mibBatchTooltip.SearchWindowSize = 'Search window size (an odd-valued positive integer). SearchWindowSize affects the performance linearly in terms of time. SearchWindowSize cannot be larger than the size of the input image';
    obj.mibModel.sessionSettings.ImageFilters.NonLocalMeans.ComparisonWindowSize = '5';
    obj.mibModel.sessionSettings.ImageFilters.NonLocalMeans.mibBatchTooltip.ComparisonWindowSize = 'Comparison window size (an odd-valued positive integer). ComparisonWindowSize must be less than or equal to SearchWindowSize';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Wiener.mibBatchTooltip.Info = 'Noise remove from images using a pixel-wise adaptive low-pass Wiener filter based on statistics estimated from a local neighborhood of each pixel<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/wiener2.html" target="_blank">wiener2</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.Wiener.mibBatchTooltip.Info = 'Noise remove from images using a pixel-wise adaptive low-pass Wiener filter based on statistics estimated from a local neighborhood of each pixel. The filtering is done with wiener2 function (https://www.mathworks.com/help/images/ref/wiener2.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.Wiener.NeighborhoodSize  = '3';
    obj.mibModel.sessionSettings.ImageFilters.Wiener.mibBatchTooltip.NeighborhoodSize = 'Size (m-by-n) of the neighborhood used to estimate the local image mean and standard deviation; can be a single number';
    obj.mibModel.sessionSettings.ImageFilters.Wiener.AdditiveNoise  = '';
    obj.mibModel.sessionSettings.ImageFilters.Wiener.mibBatchTooltip.AdditiveNoise = 'Additive noise, specified as a numeric array. If you do not specify noise, wiener2 calculates the mean of the local variance, mean2(localVar)';
    
    obj.mibModel.sessionSettings.ImageFilters.BMxD.mibBatchTooltip.Info = 'Filtering image using the block-matching and 3D collaborative algorithm, please note that this filter is only licensed to be used in non-profit organizations';
    obj.mibModel.sessionSettings.ImageFilters.BMxD.Sigma{1} = 6;
    obj.mibModel.sessionSettings.ImageFilters.BMxD.Sigma{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.BMxD.Sigma{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.BMxD.mibBatchTooltip.Sigma = 'Estimation of the noise in image intensities';
    obj.mibModel.sessionSettings.ImageFilters.BMxD.Profile = {'lc'};
    obj.mibModel.sessionSettings.ImageFilters.BMxD.Profile{2} = {'lc', 'np'};
    obj.mibModel.sessionSettings.ImageFilters.BMxD.mibBatchTooltip.Profile = 'lc: fast profile (faster); np: normal profile (slower)';
    
    %%
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.AddNoise.mibBatchTooltip.Info = 'Add noise to image<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imnoise.html" target="_blank">imnoise</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.AddNoise.mibBatchTooltip.Info = 'Add noise to image, the filtering is done with imnoise function (https://www.mathworks.com/help/images/ref/imnoise.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.AddNoise.Mode = {'gaussian'};
    obj.mibModel.sessionSettings.ImageFilters.AddNoise.Mode{2} = {'gaussian', 'poisson', 'salt & pepper', 'speckle'};
    obj.mibModel.sessionSettings.ImageFilters.AddNoise.mibBatchTooltip.Mode = 'Type of the noise to add';
    obj.mibModel.sessionSettings.ImageFilters.AddNoise.Mean = '0';
    obj.mibModel.sessionSettings.ImageFilters.AddNoise.mibBatchTooltip.Mean = '[Gaussian only] Noise mean';
    obj.mibModel.sessionSettings.ImageFilters.AddNoise.Variance = '0.01';
    obj.mibModel.sessionSettings.ImageFilters.AddNoise.mibBatchTooltip.Variance = '[Gaussian, Speckle only] Noise variance for gaussian, speckle';
    obj.mibModel.sessionSettings.ImageFilters.AddNoise.Density{1} = 0.05;
    obj.mibModel.sessionSettings.ImageFilters.AddNoise.Density{2} = [0 1];
    obj.mibModel.sessionSettings.ImageFilters.AddNoise.Density{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.AddNoise.mibBatchTooltip.Density = '[Salt & pepper only] Noise density for salt & pepper';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.mibBatchTooltip.Info = 'Fast local Laplacian filtering of images to enhance contrast, remove noise or smooth image details<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/locallapfilt.html" target="_blank">locallapfilt</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.mibBatchTooltip.Info = 'Fast local Laplacian filtering of images to enhance contrast, remove noise or smooth image details. The filtering is done with locallapfilt function (https://www.mathworks.com/help/images/ref/locallapfilt.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.EdgeAmplitude{1} = 0.1;
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.EdgeAmplitude{2} = [0 1];
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.EdgeAmplitude{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.mibBatchTooltip.EdgeAmplitude = 'Amplitude of edges [0-1]';
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.Smoothing{1} = 0.1;
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.Smoothing{2} = [0 100];
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.Smoothing{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.mibBatchTooltip.Smoothing = 'Smoothing of details, typical in range [0.01-10]. When below 1 - increases the details, effectively enhancing the local contrast of the image without affecting edges; when higher than 1 - smooths details in the input image while preserving crisp edges';
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.DynamicRange{1} = 1;
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.DynamicRange{2} = [0 10];
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.DynamicRange{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.mibBatchTooltip.DynamicRange = 'Dynamic range, typically in range [0-5]. When below 1 - Reduces the amplitude of edges in the image; above 1 - expands the dynamic range of the image';
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.ColorMode = {'luminance'};
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.ColorMode{2} = {'luminance', 'separate'};
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.mibBatchTooltip.ColorMode = 'Only for RGB images; luminance: converts RGB to grayscale before filtering and reintroduces color after filtering; separate: filters each color channel independently';
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.NumIntensityLevels = 'auto';
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.mibBatchTooltip.NumIntensityLevels = 'Number of intensity samples in the dynamic range of the input image, auto or a positive integer;  A higher number of samples gives results closer to exact local Laplacian filtering. A lower number increases the execution speed. Typical values are in the range [10, 100]';
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.useRGB = false;
    obj.mibModel.sessionSettings.ImageFilters.FastLocalLaplacian.mibBatchTooltip.useRGB = 'When checked the image is treated as an RGB image, otherwise as grayscale';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.FlatfieldCorrection.mibBatchTooltip.Info = 'Flat-field correction to the grayscale or RGB image. The correction uses Gaussian smoothing with a standard deviation of sigma to approximate the shading component of the image<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imflatfield.html" target="_blank">imflatfield</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.FlatfieldCorrection.mibBatchTooltip.Info = 'Flat-field correction to the grayscale or RGB image. The correction uses Gaussian smoothing with a standard deviation of sigma to approximate the shading component of the image. The filtering is done with imflatfield function (https://www.mathworks.com/help/images/ref/imflatfield.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.FlatfieldCorrection.Sigma = '30';
    obj.mibModel.sessionSettings.ImageFilters.FlatfieldCorrection.mibBatchTooltip.Sigma = 'Standard deviation of the Gaussian smoothing filter, specified as a positive number or a 2-element vector of positive numbers';
    %obj.mibModel.sessionSettings.ImageFilters.FlatfieldCorrection.useMask = false;
    %obj.mibModel.sessionSettings.ImageFilters.FlatfieldCorrection.mibBatchTooltip.useMask = 'When checked, apply the flat-field correction to the image only in the masked areas';
    obj.mibModel.sessionSettings.ImageFilters.FlatfieldCorrection.FilterHalfSize = '';
    obj.mibModel.sessionSettings.ImageFilters.FlatfieldCorrection.mibBatchTooltip.FilterHalfSize = 'Halfwidth size of the Gaussian filter, specified as a scalar or 2-element vector; when empty calculated from Sigma as "ceil(Sigma*2)"';
    obj.mibModel.sessionSettings.ImageFilters.FlatfieldCorrection.useRGB = false;
    obj.mibModel.sessionSettings.ImageFilters.FlatfieldCorrection.mibBatchTooltip.useRGB = 'When checked the image is treated as an RGB image, otherwise as grayscale';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.LocalBrighten.mibBatchTooltip.Info = 'Brighten low-light image<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imlocalbrighten.html" target="_blank">imlocalbrighten</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.LocalBrighten.mibBatchTooltip.Info = 'Brighten low-light image. The filtering is done with imlocalbrighten function (https://www.mathworks.com/help/images/ref/imlocalbrighten.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.LocalBrighten.Amount{1} = 1;
    obj.mibModel.sessionSettings.ImageFilters.LocalBrighten.Amount{2} = [0 1];
    obj.mibModel.sessionSettings.ImageFilters.LocalBrighten.Amount{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.LocalBrighten.mibBatchTooltip.Amount = 'Amount of the image brightening [0 1]. When the value is 1, brightens the low-light areas of A as much as possible';
    obj.mibModel.sessionSettings.ImageFilters.LocalBrighten.AlphaBlend = true;
    obj.mibModel.sessionSettings.ImageFilters.LocalBrighten.mibBatchTooltip.AlphaBlend = 'When true, the filter alpha blends the input image with the enhanced image to preserve brighter areas of the input image';
    obj.mibModel.sessionSettings.ImageFilters.LocalBrighten.useRGB = false;
    obj.mibModel.sessionSettings.ImageFilters.LocalBrighten.mibBatchTooltip.useRGB = 'When checked the image is treated as an RGB image, otherwise as grayscale';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.LocalContrast.mibBatchTooltip.Info = 'Edge-aware local contrast manipulation of images<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/localcontrast.html" target="_blank">localcontrast</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.LocalContrast.mibBatchTooltip.Info = 'Edge-aware local contrast manipulation of images. The filtering is done with localcontrast (https://www.mathworks.com/help/images/ref/localcontrast.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.LocalContrast.EdgeThreshold{1} = 0.3;
    obj.mibModel.sessionSettings.ImageFilters.LocalContrast.EdgeThreshold{2} = [0 1];
    obj.mibModel.sessionSettings.ImageFilters.LocalContrast.EdgeThreshold{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.LocalContrast.mibBatchTooltip.EdgeThreshold = 'Amplitude of strong edges to leave intact';
    obj.mibModel.sessionSettings.ImageFilters.LocalContrast.Amount{1} = 0.25;
    obj.mibModel.sessionSettings.ImageFilters.LocalContrast.Amount{2} = [-1 1];
    obj.mibModel.sessionSettings.ImageFilters.LocalContrast.Amount{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.LocalContrast.mibBatchTooltip.Amount = 'Amount of enhancement or smoothing desired, in the range [-1,1]. Negative values specify edge-aware smoothing, while positive values specify edge-aware enhancement';
    obj.mibModel.sessionSettings.ImageFilters.LocalContrast.useRGB = false;
    obj.mibModel.sessionSettings.ImageFilters.LocalContrast.mibBatchTooltip.useRGB = 'When checked the image is treated as an RGB image, otherwise as grayscale';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.ReduceHaze.mibBatchTooltip.Info = 'Reduce atmospheric haze<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imreducehaze.html" target="_blank">imreducehaze</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.ReduceHaze.mibBatchTooltip.Info = 'Reduce atmospheric haze. The filtering is done with imreducehaze function (https://www.mathworks.com/help/images/ref/imreducehaze.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.ReduceHaze.Amount{1} = 1;
    obj.mibModel.sessionSettings.ImageFilters.ReduceHaze.Amount{2} = [0 1];
    obj.mibModel.sessionSettings.ImageFilters.ReduceHaze.Amount{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.ReduceHaze.mibBatchTooltip.Amount = 'Amount of haze to remove [0-1]. When the value is 1, the filter reduces the maximum amount of haze';
    obj.mibModel.sessionSettings.ImageFilters.ReduceHaze.Method = {'simpledcp'};
    obj.mibModel.sessionSettings.ImageFilters.ReduceHaze.Method{2} = {'simpledcp', 'approxdcp'};
    obj.mibModel.sessionSettings.ImageFilters.ReduceHaze.mibBatchTooltip.Method = 'simpledcp: simple dark channel prior method; approxdcp: approximate dark channel prior method';
    obj.mibModel.sessionSettings.ImageFilters.ReduceHaze.AtmosphericLight = '0.5';
    obj.mibModel.sessionSettings.ImageFilters.ReduceHaze.mibBatchTooltip.AtmosphericLight = 'Maximum value to be treated as haze [0-1], a number or a 3-element vector for RGB';
    obj.mibModel.sessionSettings.ImageFilters.ReduceHaze.ContrastEnhancement = {'global'};
    obj.mibModel.sessionSettings.ImageFilters.ReduceHaze.ContrastEnhancement{2} = {'global','boost','none'};
    obj.mibModel.sessionSettings.ImageFilters.ReduceHaze.mibBatchTooltip.ContrastEnhancement = 'Contrast enhancement technique';
    obj.mibModel.sessionSettings.ImageFilters.ReduceHaze.useRGB = false;
    obj.mibModel.sessionSettings.ImageFilters.ReduceHaze.mibBatchTooltip.useRGB = 'When checked the image is treated as an RGB image, otherwise as grayscale';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.UnsharpMask.mibBatchTooltip.Info = 'Sharpen image using unsharp masking: when an image is sharpened by subtracting a blurred (unsharp) version of the image from itself<br>The filtering is done with <a href="https://www.mathworks.com/help/images/ref/imsharpen.html" target="_blank">imsharpen</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.UnsharpMask.mibBatchTooltip.Info = 'Sharpen image using unsharp masking: when an image is sharpened by subtracting a blurred (unsharp) version of the image from itself. The filtering is done with imsharpen function (https://www.mathworks.com/help/images/ref/imsharpen.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.UnsharpMask.Radius{1} = 1.5;
    obj.mibModel.sessionSettings.ImageFilters.UnsharpMask.Radius{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.UnsharpMask.Radius{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.UnsharpMask.mibBatchTooltip.Radius = 'Standard deviation of the Gaussian lowpass filter, specified as a positive number. This value controls the size of the region around the edge pixels that is affected by sharpening. A large value sharpens wider regions around the edges, whereas a small value sharpens narrower regions around edges';
    obj.mibModel.sessionSettings.ImageFilters.UnsharpMask.Amount{1} = 0.8;
    obj.mibModel.sessionSettings.ImageFilters.UnsharpMask.Amount{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.UnsharpMask.Amount{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.UnsharpMask.mibBatchTooltip.Amount = 'Strength of the sharpening effect, specified as a numeric scalar. A higher value leads to larger increase in the contrast of the sharpened pixels. Typical values for this parameter are within the range [0 2]';
    obj.mibModel.sessionSettings.ImageFilters.UnsharpMask.Threshold{1} = 0;
    obj.mibModel.sessionSettings.ImageFilters.UnsharpMask.Threshold{2} = [0 1];
    obj.mibModel.sessionSettings.ImageFilters.UnsharpMask.Threshold{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.UnsharpMask.mibBatchTooltip.Threshold = 'Minimum contrast required for a pixel to be considered an edge pixel. Higher values (closer to 1) allow sharpening only in high-contrast regions, such as strong edges, while leaving low-contrast regions unaffected. Lower values (closer to 0) additionally allow sharpening in relatively smoother regions of the image. This parameter is useful in avoiding sharpening noise in the output image';
    obj.mibModel.sessionSettings.ImageFilters.UnsharpMask.useRGB = false;
    obj.mibModel.sessionSettings.ImageFilters.UnsharpMask.mibBatchTooltip.useRGB = 'When checked the image is treated as an RGB image, otherwise as grayscale';
    
    %% Binarization
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Edge.mibBatchTooltip.Info = 'Find edges in intensity image;<br>the filtering is done with <a href="https://www.mathworks.com/help/images/ref/edge.html" target="_blank">edge</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.Edge.mibBatchTooltip.Info = 'Find edges in intensity image; the filtering is done with edge function (https://www.mathworks.com/help/images/ref/edge.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.Edge.DestinationLayer{1} = 'selection';
    obj.mibModel.sessionSettings.ImageFilters.Edge.DestinationLayer{2} = {'selection', 'mask'};
    obj.mibModel.sessionSettings.ImageFilters.Edge.mibBatchTooltip.DestinationLayer = 'The detected edges will be assigned to this layer';
    obj.mibModel.sessionSettings.ImageFilters.Edge.Method{1} = 'Canny';
    obj.mibModel.sessionSettings.ImageFilters.Edge.Method{2} = {'approxcanny', 'Canny', 'LaplacianOfGaussian', 'Prewitt', 'Roberts', 'Sobel'};
    obj.mibModel.sessionSettings.ImageFilters.Edge.mibBatchTooltip.Method = 'Edge detection method';
    obj.mibModel.sessionSettings.ImageFilters.Edge.Threshold = '';
    obj.mibModel.sessionSettings.ImageFilters.Edge.mibBatchTooltip.Threshold = 'Sensitivity threshold [0-1], when empty calculated automatically. For "Canny" and "approxcanny" can also be two numbers [0-1] for low and high thresholds';
    obj.mibModel.sessionSettings.ImageFilters.Edge.Direction{1} = 'both';
    obj.mibModel.sessionSettings.ImageFilters.Edge.Direction{2} = {'both', 'horizontal', 'vertical'};
    obj.mibModel.sessionSettings.ImageFilters.Edge.mibBatchTooltip.Direction = '[Prewitt, Roberts, Sobel only] direction of edges to detect';
    obj.mibModel.sessionSettings.ImageFilters.Edge.Sigma = '1.5';
    obj.mibModel.sessionSettings.ImageFilters.Edge.mibBatchTooltip.Sigma = '[Canny, LaplacianOfGaussian only] standard deviation of Sigma"';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.SlicClustering.mibBatchTooltip.Info = 'Cluster together pixels of similar intensity using the <a href="http://ivrl.epfl.ch/supplementary_material/RK_SLICSuperpixels/index.html" target="_blank">SLIC (Simple Linear Iterative Clustering) algorithm</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.SlicClustering.mibBatchTooltip.Info = 'Cluster together pixels of similar intensity using the SLIC (Simple Linear Iterative Clustering) algorithm (http://ivrl.epfl.ch/supplementary_material/RK_SLICSuperpixels/index.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.SlicClustering.DestinationLayer{1} = 'model';
    obj.mibModel.sessionSettings.ImageFilters.SlicClustering.DestinationLayer{2} = {'model'};
    obj.mibModel.sessionSettings.ImageFilters.SlicClustering.mibBatchTooltip.DestinationLayer = 'The detected edges will be assigned to this layer';
    obj.mibModel.sessionSettings.ImageFilters.SlicClustering.ClusterSize{1} = 500;
    obj.mibModel.sessionSettings.ImageFilters.SlicClustering.ClusterSize{2} = [1 Inf];
    obj.mibModel.sessionSettings.ImageFilters.SlicClustering.mibBatchTooltip.ClusterSize = 'Tentative size of clusters in pixels';
    obj.mibModel.sessionSettings.ImageFilters.SlicClustering.Compactness{1} = 99;
    obj.mibModel.sessionSettings.ImageFilters.SlicClustering.Compactness{2} = [1 Inf];
    obj.mibModel.sessionSettings.ImageFilters.SlicClustering.mibBatchTooltip.Compactness = 'Compactness factor, increasing the value will make clusters more square';
    obj.mibModel.sessionSettings.ImageFilters.SlicClustering.ChopX{1} = 1;
    obj.mibModel.sessionSettings.ImageFilters.SlicClustering.ChopX{2} = [1 Inf];
    obj.mibModel.sessionSettings.ImageFilters.SlicClustering.mibBatchTooltip.ChopX = '[Only for 3D] Chopping factor for large datasets, when this value is higher than one, the dataset is chopped into number of subvolumes that are processed separetly';
    obj.mibModel.sessionSettings.ImageFilters.SlicClustering.ChopY{1} = 1;
    obj.mibModel.sessionSettings.ImageFilters.SlicClustering.ChopY{2} = [1 Inf];
    obj.mibModel.sessionSettings.ImageFilters.SlicClustering.mibBatchTooltip.ChopY = '[Only for 3D] Chop factor for the Y-dimension';
    
    if obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.mibBatchTooltip.Info = 'Cluster together pixels based on presence of ridges using the <a href="https://se.mathworks.com/help/images/ref/watershed.html" target="_blank">watershed algorithm</a>.';
    else
        obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.mibBatchTooltip.Info = 'Cluster together pixels based on presence of ridges using the watershed algorithm (https://se.mathworks.com/help/images/ref/watershed.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.DestinationLayer{1} = 'model';
    obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.DestinationLayer{2} = {'model', 'mask', 'selection'};
    obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.mibBatchTooltip.DestinationLayer = 'The detected edges will be assigned to this layer';
    obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.ClusterSize{1} = 10;
    obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.ClusterSize{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.mibBatchTooltip.ClusterSize = 'Define size of clusters';
    obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.TypeOfSignal = {'black-on-white'};
    obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.TypeOfSignal{2} = {'black-on-white', 'white-on-black'};
    obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.mibBatchTooltip.TypeOfSignal = 'Type of signal, black-on-white means black ridges over the bright background, white-on-black - is other way around';
    obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.GapPolicy{1} = 'keep gaps';
    obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.GapPolicy{2} = {'keep gaps', 'remove gaps'};
    obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.mibBatchTooltip.GapPolicy = 'Keep or remove gaps between superpixels';
    obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.ResultingShape{1} = 'clusters';
    obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.ResultingShape{2} = {'clusters', 'ridges'};
    obj.mibModel.sessionSettings.ImageFilters.WatershedClustering.mibBatchTooltip.ResultingShape = 'Define desired result - clusters or ridges that separate clusters';
end


end


%%
function add_to_classpath(classpath, directory)
% Get all .jar files in the directory
test = dir(strcat([directory filesep '*.jar']));
path_= cell(0);
for i = 1:length(test)
    if not_yet_in_classpath(classpath, test(i).name)
        path_{length(path_) + 1} = strcat([directory filesep test(i).name]);
    end
end

% Add them to the classpath
if ~isempty(path_)
    try
        javaaddpath(path_, '-end');
    catch err
        sprintf('%s', err.identifier);
    end
end
end

%%
function test = not_yet_in_classpath(classpath, filename)
% Test whether the library was already imported
%expression = strcat([filesep filename '$']);
%test = isempty(cell2mat(regexp(classpath, expression)));
expression = strcat([filesep filename]);
test = isempty(cell2mat(strfind(classpath, expression)));
end