function mib()
% @mainpage Microscopy Image Browser
% @section intro Introduction
% @b Microscopy @b Image @b Browser is is a high-performance software package for advanced image processing, segmentation and visualization of multidimentional (2D-4D) datasets.
% Microscopy Image Browser is written in Matlab, but has a user friendly graphical interface that does not requre knowledge of Matlab and can be used by anybody.
% @section features Key Features
% - Works as a Matlab program under Windows/Linux/MacOS Matlab, or as a standalone application (Windows 64bit);
% - Open source, no license/fee required;
% - Extendable with custom plugins;
% - Generation of multidimentional image stacks;
% - Alignment of 3D stacks and images within these stacks;
% - Brightness, contrast, gamma, image mode adjustments, resize, crop functions;
% - Automatic/manual image segmentation with help of filters and interpolation in XY, XZ, or YZ planes;
% - Quantification and statistics for 2D/3D objects;
% - Export of images or models to Matlab, Amira, IMOD, TIF, NRRD formats;
% - Direct 3D visualization using Matlab isosurfaces or Fiji 3D viewer;
% - Log of performed actions;
% - Customizable Undo option
% - Colorblind friendly default color modeling scheme
% @section description Description
% Recent years witnessed a rapid development of 3D electron microscopy
% imaging techniques applied for the life science research. In addition to electron tomography
% (ET) that is effective on a subcellular level, several other alternative methods that extend the
% imaging up to the tissue level have been developed. Among these are new scanning electron microscopy (SEM)
% techniques that allow automated sequential imaging of a freshly cut block face of resin-embedded specimens
% using a back scatter detector. A fresh block face is created by an ultramicrotome inserted in the imaging
% chamber (Serial-Block Face SEM) or by focused ion beam (FIB-SEM). As a result, the amount and volumes of
% 3D datasets increases extensively raising a question of effective image processing and modeling.
% With development of Microscopy Image Browser (MIB) we address this problem and present a free,
% open-source software package, which can be used for image processing, analysis, segmentation and
% visualization of multidimensional datasets.
%
% @page install Download and installbination
% Please follow instructions on Microscopy Image Browser web page:
% http://mib.helsinki.fi

% Copyright (C) 2010-2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% add path to other directories
tic

% turn off warnings
warning('off', 'MATLAB:ui:javaframe:PropertyToBeRemoved'); 

if ~isdeployed
    func_name='mib.m';
    func_dir=which(func_name);
    func_dir=fileparts(func_dir);
    addpath(func_dir);
    addpath(fullfile(func_dir, 'Classes'));
    addpath(fullfile(func_dir, 'GuiTools'));
    addpath(fullfile(func_dir, 'GuiTools', 'volren'));
	addpath(fullfile(func_dir, 'ImportExportTools'));
    addpath(fullfile(func_dir, 'ImportExportTools','Amira'));
    addpath(fullfile(func_dir, 'ImportExportTools','BioFormats'));
    addpath(fullfile(func_dir, 'ImportExportTools','export_fig'));
	addpath(fullfile(func_dir, 'ImportExportTools','Fiji'));
    addpath(fullfile(func_dir, 'ImportExportTools','HDF5'));
	addpath(fullfile(func_dir, 'ImportExportTools','Imaris'));
    addpath(fullfile(func_dir, 'ImportExportTools','IMOD'));
    addpath(fullfile(func_dir, 'ImportExportTools','Omero'));
    addpath(fullfile(func_dir, 'ImportExportTools','nrrd'));
    addpath(fullfile(func_dir, 'ImportExportTools', 'xlwrite'));
    addpath(fullfile(func_dir, 'Resources'));
    addpath(fullfile(func_dir, 'techdoc'));
    addpath(fullfile(func_dir, 'Tools'));
    addpath(fullfile(func_dir, 'Tools','FastMarching'));
    addpath(fullfile(func_dir, 'Tools','FastMarching','functions'));
    addpath(fullfile(func_dir, 'Tools','FastMarching','shortestpath'));
    addpath(fullfile(func_dir, 'Tools','Frangi'));
    addpath(fullfile(func_dir, 'Tools','HistThresh'));
    addpath(fullfile(func_dir, 'Tools','imclipboard'));
    addpath(fullfile(func_dir, 'Tools','matGeom'));
    addpath(fullfile(func_dir, 'Tools','matGeom','geom2d'));
    addpath(fullfile(func_dir, 'Tools','matGeom','geom3d'));
    addpath(fullfile(func_dir, 'Tools','RandomForest'));
    addpath(fullfile(func_dir, 'Tools', 'RandomForest','RF_Class_C'));
    addpath(fullfile(func_dir, 'Tools', 'RandomForest','RF_Reg_C'));
    addpath(fullfile(func_dir, 'Tools', 'RandomForest','MembraneDetection'));
    addpath(fullfile(func_dir, 'Tools', 'RegionGrowing'));
    addpath(fullfile(func_dir, 'Tools', 'Supervoxels'));
end

model = mibModel();     % initialize the model
controller = mibController(model);  % initialize controller

toc