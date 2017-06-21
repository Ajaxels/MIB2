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

%% Restore preferences from the last time
os = getenv('OS');
if strcmp(os,'Windows_NT')
    start_path = 'C:';
    fn = 'c:\temp\mib.mat';
    if exist(fn, 'file') ~= 0
        load(fn);
        disp(['MIB: parameters file: ', fn]);
    else    % check the windows temp folder (C:\Users\User-name\AppData\Local\Temp\)
        fn = fullfile(tempdir, 'mib.mat');
        if exist(fn,'file') ~= 0
            load(fn);
            disp(['MIB: parameters file: ', fn]);
        end
    end
else
    start_path = '/';
    if exist(fullfile(obj.mibPath, 'mib.mat'), 'file') ~= 0
        fn = fullfile(obj.mibPath, 'mib.mat');
    elseif exist(fullfile(tempdir, 'mib.mat'), 'file') ~= 0
        fn = fullfile(tempdir, 'mib.mat');
    else
        fn = [];
    end
    if ~isempty(fn)
        load(fn);
         disp(['MIB: parameters file: ', fn]);
    end
    
%         fn = [fileparts(which('mib.m')) filesep 'mib.mat'];
%         load(fn);
%         disp(['MIB: parameters file: ', fn]);
%     else % try Linux temp folder (/tmp)
%         fn = fullfile(tempdir, 'mib.mat');
%         if exist(fn,'file') ~= 0
%             load(fn);
%             disp(['MIB: parameters file: ', fn]);
%         end
%     end
    
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

obj.mibModel.preferences.updateChecked = 0;     % time of the previus update check

% size of the grid for BW Mask thresholding
obj.mibModel.preferences.corrGridrunSize = 200; 

% add default folders
obj.mibModel.preferences.dirs.fijiInstallationPath = [];
obj.mibModel.preferences.dirs.omeroInstallationPath = [];

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

% define keyboard shortcuts
maxShortCutIndex = 29;  % total number of shortcuts
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

obj.mibModel.preferences.KeyShortcuts.Key{maxShortCutIndex} = 'v';
obj.mibModel.preferences.KeyShortcuts.Action{maxShortCutIndex} = 'Paste buffered selection to all slices';
obj.mibModel.preferences.KeyShortcuts.control(maxShortCutIndex) = 1;
obj.mibModel.preferences.KeyShortcuts.shift(maxShortCutIndex) = 1;

obj.mibModel.preferences.recentDirs = {};

% define font structure
obj.mibModel.preferences.Font.FontName = 'Helvetica';
obj.mibModel.preferences.Font.FontUnits = 'points';
obj.mibModel.preferences.Font.FontSize = 8;
obj.mibModel.preferences.fontSizeDir = 9;        % font size for files and directories

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
        obj.mibModel.preferences = mib_pars.preferences;
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
if isdir(obj.mibModel.preferences.lastpath) == 0
    obj.mibModel.preferences.lastpath = start_path;
end
%% Update libraries
% update Fiji and Omero folders if they are present in Matlab path already
if ~isdeployed
    omeroDir = which('loadOmero');
    if ~isempty(omeroDir)
        obj.mibModel.preferences.dirs.omeroInstallationPath = fileparts(omeroDir);
    end
    
    mijiDir = which('Miji');
    if ~isempty(mijiDir)
        obj.mibModel.preferences.dirs.fijiInstallationPath = fileparts(fileparts(mijiDir));
    end
end

% add Omero libraries
if ~isempty(obj.mibModel.preferences.dirs.omeroInstallationPath)
    if exist(obj.mibModel.preferences.dirs.omeroInstallationPath, 'dir') ~= 7    % not a folder
        sprintf('Omero path is not correct!\n\nPlease fix it using MIB Preferences dialog (MIB->Menu->File->Preferences->External dirs)');
    else
        if isdeployed
            % add Omero libraries
            % Get the Java classpath
            classpath = javaclasspath('-all');
            OmeroClient_Jar = fullfile(obj.mibModel.preferences.dirs.omeroInstallationPath, 'libs', 'omero_client.jar');
            % Switch off warning
            warning_state = warning('off');
            if not_yet_in_classpath(classpath, OmeroClient_Jar)
                javaaddpath(OmeroClient_Jar);
            end
            import omero.*;
            % Switch warning back to initial settings
            warning(warning_state);
        else
            addpath(obj.mibModel.preferences.dirs.omeroInstallationPath);
            loadOmero(); 
        end
    end
end

% add Imaris and BioFormats java libraries to Java path;
if ~isdeployed
    javapath = javaclasspath('-all');
    
    % add bio-formats java libraries
    if all(cellfun(@isempty, strfind(javapath, 'bioformats_package.jar')))
        % if isempty(cell2mat(strfind(javapath, 'bioformats_package.jar'))); % this call is a bit slower
        lociPath = fullfile(obj.mibPath,'ImportExportTools','BioFormats','bioformats_package.jar');
        javaaddpath(lociPath, '-end');
        disp(['MIB: adding "' lociPath '" to Matlab java path']);
    end
end

% add Fiji libraries
if ~isempty(obj.mibModel.preferences.dirs.fijiInstallationPath)
    if exist(obj.mibModel.preferences.dirs.fijiInstallationPath, 'dir') ~= 7    % not a folder
        sprintf('Fiji path is not correct!\n\nPlease fix it using MIB Preferences dialog (MIB->Menu->File->Preferences->External dirs)');
    else
        if isdeployed
            % add Fiji libraries
            
            % Get the Java classpath
            classpath = javaclasspath('-all');
            
            % Add all libraries in jars/ and plugins/ to the classpath
            % Switch off warning
            warning_state = warning('off');
            add_to_classpath(classpath, fullfile(obj.mibModel.preferences.dirs.fijiInstallationPath, 'jars'));
            classpath = javaclasspath('-all');
            add_to_classpath(classpath, fullfile(obj.mibModel.preferences.dirs.fijiInstallationPath, 'plugins'));
            % Switch warning back to initial settings
            warning(warning_state);
            
            % Set the Fiji directory (and plugins.dir which is not Fiji.app/plugins/)
            java.lang.System.setProperty('ij.dir', obj.mibModel.preferences.dirs.fijiInstallationPath);
            java.lang.System.setProperty('plugins.dir', obj.mibModel.preferences.dirs.fijiInstallationPath);
        else
            addpath(fullfile(obj.mibModel.preferences.dirs.fijiInstallationPath, 'scripts'));    % add Fiji/scripts path to Matlab path
        end
    end
end

% add Apache POI java library for xlwrite
if ~ispc
    poi_path = fullfile(obj.mibPath,'ImportExportTools','xlwrite');
    javaaddpath(fullfile(poi_path, 'poi-3.8-20120326.jar'));
    javaaddpath(fullfile(poi_path, 'poi-ooxml-3.8-20120326.jar'));
    javaaddpath(fullfile(poi_path, 'poi-ooxml-schemas-3.8-20120326.jar'));
    javaaddpath(fullfile(poi_path, 'xmlbeans-2.3.0.jar'));
    javaaddpath(fullfile(poi_path, 'dom4j-1.6.1.jar'));
    javaaddpath(fullfile(poi_path, 'stax-api-1.0.1.jar'));
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