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
    disp(['MIB parameters file: ', prefsFn]);
end
if ispc
    start_path = 'C:';
else
    start_path = '/';
end

% set the global preferences
% see also mibPreferencesController.defaultBtn_Callback()
obj.mibModel.preferences = obj.generateDefaultPreferences();

%% update preferences
if exist('mib_pars', 'var') && isfield(mib_pars, 'mibVersion')  %#ok<NODEF> % % detection for new preferences from MIB 2.72
    % concatenate stored with default preference structures only when
    % versions dismatch
    if mib_pars.mibVersion < obj.mibVersionNumeric
        if isfield(mib_pars.preferences.ExternalDirs, 'fijiInstallationPath')
            % fix of field names used before 2.80, where
            % fijiInstallationPath was used instead of FijiInstallationPath
            mib_pars.preferences = rmfield(mib_pars.preferences, 'ExternalDirs');
        end
        obj.mibModel.preferences = mibConcatenateStructures(obj.mibModel.preferences, mib_pars.preferences);
    elseif mib_pars.mibVersion == obj.mibVersionNumeric
        obj.mibModel.preferences = mib_pars.preferences; 
    end
end

if isdir(obj.mibModel.preferences.System.Dirs.LastPath) == 0 %#ok<ISDIR>
    obj.mibModel.preferences.System.Dirs.LastPath = start_path;
end

%% Update Java libraries
% update Fiji and Omero libs if they are present in Matlab path already
warning_state = warning('off');     % store warning settings

%% Update External Dirs in preferences
% add BMxD to Matlab path
if ~isdeployed
    if exist(obj.mibModel.preferences.ExternalDirs.bm3dInstallationPath, 'dir') == 7; addpath(obj.mibModel.preferences.ExternalDirs.bm3dInstallationPath); end
    if exist(obj.mibModel.preferences.ExternalDirs.bm4dInstallationPath, 'dir') == 7; addpath(obj.mibModel.preferences.ExternalDirs.bm4dInstallationPath); end
end

% add Omero
if exist(obj.mibModel.preferences.ExternalDirs.OmeroInstallationPath, 'dir') == 7
    if ~isdeployed
        if exist(fullfile(obj.mibModel.preferences.ExternalDirs.OmeroInstallationPath, 'loadOmero.m'), 'file') == 2
            addpath(obj.mibModel.preferences.ExternalDirs.OmeroInstallationPath);
            loadOmero();
        end
    else
        javapath = javaclasspath('-all');   % Get the Java classpath
        add_to_classpath(javapath, fullfile(obj.mibModel.preferences.ExternalDirs.OmeroInstallationPath, 'libs'));
        import omero.*;
    end
else
    if ~isempty(obj.mibModel.preferences.ExternalDirs.OmeroInstallationPath)
        fprintf('Warning! Omero path is not correct!\nPlease fix it using MIB Preferences dialog (MIB->Menu->File->Preferences->External dirs)\n');
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
if exist(obj.mibModel.preferences.ExternalDirs.FijiInstallationPath, 'dir') == 7
    fprintf('MIB: adding Fiji libraries from "%s" .', obj.mibModel.preferences.ExternalDirs.FijiInstallationPath);
    if ~isdeployed
        addpath(fullfile(obj.mibModel.preferences.ExternalDirs.FijiInstallationPath, 'scripts'));    % add Fiji/scripts path to Matlab path
        fprintf('.');
        add_to_classpath(javapath, fullfile(obj.mibModel.preferences.ExternalDirs.FijiInstallationPath,'jars'));
        fprintf('.');
        add_to_classpath(javapath, fullfile(obj.mibModel.preferences.ExternalDirs.FijiInstallationPath,'plugins'));
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
        add_to_classpath(javapath, fullfile(obj.mibModel.preferences.ExternalDirs.FijiInstallationPath, 'jars'));
        add_to_classpath(javapath, fullfile(obj.mibModel.preferences.ExternalDirs.FijiInstallationPath, 'plugins'));
        
        % Set the Fiji directory (and plugins.dir which is not Fiji.app/plugins/)
        java.lang.System.setProperty('ij.dir', obj.mibModel.preferences.ExternalDirs.FijiInstallationPath);
        java.lang.System.setProperty('plugins.dir', obj.mibModel.preferences.ExternalDirs.FijiInstallationPath);
    end
else
    if ~isempty(obj.mibModel.preferences.ExternalDirs.FijiInstallationPath)
        fprintf('Warning! Fiji path is not correct!\nPlease fix it using MIB Preferences dialog (MIB->Menu->File->Preferences->External dirs)\n');
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
if exist(fullfile(obj.mibModel.preferences.ExternalDirs.ImarisInstallationPath, 'XT', 'matlab'), 'dir') == 7
    setenv('IMARISPATH', obj.mibModel.preferences.ExternalDirs.ImarisInstallationPath);
    loadImarisLib = 1;
else
    obj.mibModel.preferences.ExternalDirs.ImarisInstallationPath = [];
end
if loadImarisLib && exist(fullfile(obj.mibModel.preferences.ExternalDirs.ImarisInstallationPath, 'XT', 'matlab'), 'dir') == 7
    % Add the ImarisLib.jar package to the java class path
    if all(cellfun(@isempty, strfind(javapath, 'ImarisLib.jar')))
        javaaddpath(fullfile(obj.mibModel.preferences.ExternalDirs.ImarisInstallationPath, 'XT', 'matlab', 'ImarisLib.jar'));
    end
    
end

%% Define session settings structure
% define default parameters for filters
if ~isfield(obj.mibModel.sessionSettings, 'ImageFilters') || ~isfield(obj.mibModel.sessionSettings.ImageFilters, 'TestImg')
    % preload an image used for filter previews
    obj.mibModel.sessionSettings.ImageFilters.TestImg = imread(fullfile(mibPath, 'Resources', 'test_img_for_previews.png'));
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Disk.mibBatchTooltip.Info = 'Circular averaging filter (pillbox)<br>the filtering is done with <a href="https://www.mathworks.com/help/images/ref/imfilter.html" target="_blank">imfilter</a> function and the "<span style="color:red;">disk</span>" predefined filter from <a href="https://www.mathworks.com/help/images/ref/fspecial.html" target="_blank">fspecial</a>.';
    else
        obj.mibModel.sessionSettings.ImageFilters.Disk.mibBatchTooltip.Info = 'Circular averaging filter (pillbox), the filtering is done with imfilter function (https://www.mathworks.com/help/images/ref/imfilter.html) and the "disk" predefined filter of fspecial (https://www.mathworks.com/help/images/ref/fspecial.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.Disk.Radius{1} = 3;
    obj.mibModel.sessionSettings.ImageFilters.Disk.Radius{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.Disk.mibBatchTooltip.Radius = 'Radius of a disk-shaped filter, specified as a positive number';
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.ElasticDistortion.mibBatchTooltip.Info = 'Elastic distortion filter, see details in <a href="http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.160.8494&rep=rep1&type=pdf" target="_blank">Best Practices for Convolutional Neural Networks Applied to Visual Document Analysis</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.ElasticDistortion.mibBatchTooltip.Info = 'Elastic distortion filter, see details in Best Practices for Convolutional Neural Networks Applied to Visual Document Analysis, http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.160.8494&rep=rep1&type=pdf';
    end
    obj.mibModel.sessionSettings.ImageFilters.ElasticDistortion.ScalingFactor{1} = 30;
    obj.mibModel.sessionSettings.ImageFilters.ElasticDistortion.ScalingFactor{2} = [1 Inf];
    obj.mibModel.sessionSettings.ImageFilters.ElasticDistortion.mibBatchTooltip.ScalingFactor = 'Scaling factor for distortions';
    obj.mibModel.sessionSettings.ImageFilters.ElasticDistortion.HSize = '7';
    obj.mibModel.sessionSettings.ImageFilters.ElasticDistortion.mibBatchTooltip.HSize = 'Size of the filter, specified as a positive integer or 2-element (3 element for 3D) vector of positive integers; HAS TO BE ODD';
    obj.mibModel.sessionSettings.ImageFilters.ElasticDistortion.Sigma{1} = 4;
    obj.mibModel.sessionSettings.ImageFilters.ElasticDistortion.Sigma{2} = [0 Inf];
    obj.mibModel.sessionSettings.ImageFilters.ElasticDistortion.Sigma{3} = 'off';
    obj.mibModel.sessionSettings.ImageFilters.ElasticDistortion.mibBatchTooltip.Sigma = 'Standard deviation of the Gaussian distribution, normally HSize/5';
    obj.mibModel.sessionSettings.ImageFilters.ElasticDistortion.DistortAllLAyers = true;
    obj.mibModel.sessionSettings.ImageFilters.ElasticDistortion.mibBatchTooltip.DistortAllLAyers = 'When ticked the distortions are applied to all layers except selection';
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
     if ~verLessThan('matlab', '9.8') % obj.matlabVersion >= 9.8
        obj.mibModel.sessionSettings.ImageFilters.Mode.mibBatchTooltip.Info = 'Mode filter<br>the filtering is done with <a href="https://se.mathworks.com/help/releases/R2020a/images/ref/modefilt.html" target="_blank">modefilt</a> function. Each output pixel contains the mode (most frequently occurring value) in the neighborhood around the corresponding pixel in the input image';
        obj.mibModel.sessionSettings.ImageFilters.Mode.FiltSize = '3 3 3';
        obj.mibModel.sessionSettings.ImageFilters.Mode.mibBatchTooltip.FiltSize = 'Size of filter in pixels as [height, width, depth]';
        obj.mibModel.sessionSettings.ImageFilters.Mode.Padding = {'symmetric'};
        obj.mibModel.sessionSettings.ImageFilters.Mode.Padding{2} = {'symmetric', 'replicate', 'zeros'};
        obj.mibModel.sessionSettings.ImageFilters.Mode.mibBatchTooltip.Padding = 'Padding method; symmetric - a mirror reflection of itself; replicate - repeating border elements; zeros - zero values';
    end  
    
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
        obj.mibModel.sessionSettings.ImageFilters.Median.mibBatchTooltip.Info = 'Median filtering of images in 2D or 3D. Each output pixel contains the median value in the specified neighborhood<br>The 2D filtering is done with <a href="https://www.mathworks.com/help/images/ref/medfilt2.html" target="_blank">medfilt2</a> and 3D with <a href="https://www.mathworks.com/help/images/ref/medfilt3.html" target="_blank">medfilt3</a>';
    else
        obj.mibModel.sessionSettings.ImageFilters.Median.mibBatchTooltip.Info = 'Median filtering of images in 2D or 3D. Each output pixel contains the median value in the specified neighborhood. The 2D filtering is done with medfilt2 function (https://www.mathworks.com/help/images/ref/medfilt2.html) and 3D with medfilt3 (https://www.mathworks.com/help/images/ref/medfilt3.html)';
    end
    obj.mibModel.sessionSettings.ImageFilters.Median.NeighborhoodSize  = '3';
    obj.mibModel.sessionSettings.ImageFilters.Median.mibBatchTooltip.NeighborhoodSize = 'Size (y-by-x-by-z) of the neighborhood used to calculate the median value';
    obj.mibModel.sessionSettings.ImageFilters.Median.Padding  = {'symmetric'};
    obj.mibModel.sessionSettings.ImageFilters.Median.Padding{2} = {'symmetric','zeros'};
    obj.mibModel.sessionSettings.ImageFilters.Median.mibBatchTooltip.Padding = 'symmetric: symmetrically extend the image at the boundaries; zeros: pad the image with 0s';
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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
    
    if ~verLessThan('matlab', '9.7') % obj.matlabVersion >= 9.7
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

% add CLAHE to session settings
% old preferences.CLAHE
obj.mibModel.sessionSettings.CLAHE.Mode = 'Current stack (3D)';
obj.mibModel.sessionSettings.CLAHE.NumTiles = [8 8];
obj.mibModel.sessionSettings.CLAHE.ClipLimit = 0.01;
obj.mibModel.sessionSettings.CLAHE.NBins = 256;
obj.mibModel.sessionSettings.CLAHE.Distribution = 'uniform';
obj.mibModel.sessionSettings.CLAHE.Alpha = 0.4;

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