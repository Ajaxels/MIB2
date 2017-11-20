function connImaris = mibRenderModelImaris(mibImage, connImaris, options)
% function connImaris = mibRenderModelImaris(mibImage, connImaris)
% Render a model in Imaris. 
%
% Parameters:
% mibImage: an instance of mibImage with the model to export to Imaris
% connImaris: [@em optional] a handle to imaris connection
% options: an optional structure with additional settings
% @li .materialIndex - an index of material to render. When 0 - render all
% 
%
% Return values:
% connImaris: a handle to imaris connection


% @note 
% uses IceImarisConnector bindings
% @b Requires:
% 1. set system environment variable IMARISPATH to the installation
% directory, for example "c:\tools\science\imaris"
% 2. restart Matlab
% 

%|
% @b Examples:
% @code obj.connImaris = mibRenderModelImaris(obj.mibModel.I{obj.mibModel.Id}, obj.connImaris);     // call from mibController; render the model in Imaris @endcode

% Copyright (C) 11.01.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% Written with a help of an old code SurfacesFromSegmentationImage.m by
% Igor Beati, Bitplane.
%
% Updates
% 25.09.2017 IB updated connection to Imaris

global mibPath;

if nargin < 3; options = struct(); end
if nargin < 2; connImaris = []; end

if ~isfield(options, 'materialIndex'); options.materialIndex = 0; end  % render all materials by default

answer = inputdlg(sprintf('!!! ATTENTION !!!\n\nA volume that is currently open in Imaris will be removed!\nYou can preserve it by importing it into MIB and exporting it back to Imaris after the surface is generated.\n\nTo proceed further please define a smoothing factor,\na number, 0 or higher (IN IMAGE UNITS);\ncurrent voxel size: %.4f x %.4f x %.4f:', ...
    mibImage.pixSize.x, mibImage.pixSize.y, mibImage.pixSize.z), 'Smoothing factor', 1, {'0'});
if isempty(answer); return; end
vSmoothing = str2double(answer{1});

% establishing connection to Imaris
connImaris = mibConnectToImaris(connImaris);
if isempty(connImaris); return; end

% define index of material to model, NaN - model all
if options.materialIndex == 0    % all materials
    materialStart = 1;  
    materialEnd = numel(mibImage.modelMaterialNames);  
    vNumberOfObjects = numel(mibImage.modelMaterialNames);
else
    materialStart = options.materialIndex;  
    materialEnd = options.materialIndex;  
    vNumberOfObjects = 1;
end

if mibImage.time > 1
    mode = questdlg(sprintf('Would you like to export currently shown 3D (W:H:C:Z) stack or complete 4D (W:H:C:Z:T) dataset to Imaris?'),...
        'Export to Imaris', '3D', '4D', 'Cancel', '3D');
    if strcmp(mode, 'Cancel'); return; end
else
    mode = '3D';
end
if ~isempty(connImaris.mImarisApplication.GetDataSet) && strcmp(mode, '3D')
    [vSizeX, vSizeY, vSizeZ, vSizeC, vSizeT] = connImaris.getSizes();
    if vSizeZ > 1 && vSizeT > 1 && strcmp(mode, '3D')
        insertInto = mibInputDlg({mibPath}, sprintf('!!! Warning !!!\n\nA 5D dataset is open in Imaris!\nPlease enter a time point to update (starting from 0)\nor type "-1" to replace dataset completely'), 'Time point', mibImage.slices{5}(1));
        if isempty(insertInto); return; end
        imarisOptions.insertInto = insertInto;
    end
end
imarisOptions.type = 'model';
imarisOptions.mode = mode;

wb = waitbar(0, 'Please wait...','Name','Rendering model in Imaris');
tic
for vIndex = materialStart:materialEnd
    imarisOptions.modelIndex = vIndex;
    %-- to export as multiple color channels --% imarisOptions.modelIndex = NaN;
    connImaris = mibSetImarisDataset(mibImage, connImaris, imarisOptions);
    aDataSet = connImaris.mImarisApplication.GetDataSet();
    if isempty(aDataSet)
        errordlg(sprintf('!!! Error !!!\nThe dataset was not transferred...'),'Error');
        delete(wb);
        return;
    end
    
    % generate surface
    vSurfaces = connImaris.mImarisApplication.GetImageProcessing.DetectSurfaces(...
       aDataSet, [], 0, vSmoothing, 0, 0, .5, '');     
    
%-- to export as multiple color channels --%     for vIndex = materialStart:materialEnd
%-- to export as multiple color channels --%         vSurfaces = connImaris.mImarisApplication.GetImageProcessing.DetectSurfaces(...
%-- to export as multiple color channels --%             aDataSet, [], vIndex-1, vSmoothing, 0, 0, .5, '');
%-- to export as multiple color channels --%         vSurfaces.SetName(mibImage.modelMaterialNames{vIndex});
%-- to export as multiple color channels --%         % set color for the surface
%-- to export as multiple color channels --%         ColorRGBA = [mibImage.modelMaterialColors(vIndex,:), 0];
%-- to export as multiple color channels --%         ColorRGBA = connImaris.mapRgbaVectorToScalar(ColorRGBA);
%-- to export as multiple color channels --%         vSurfaces.SetColorRGBA(ColorRGBA);
%-- to export as multiple color channels --%         % add surface to scene
%-- to export as multiple color channels --%         connImaris.mImarisApplication.GetSurpassScene.AddChild(vSurfaces, -1);
%-- to export as multiple color channels --%     end
    
    vSurfaces.SetName(mibImage.modelMaterialNames{vIndex});
    % set color for the surface
    ColorRGBA = [mibImage.modelMaterialColors(vIndex,:), 0];
    ColorRGBA = connImaris.mapRgbaVectorToScalar(ColorRGBA);
    vSurfaces.SetColorRGBA(ColorRGBA);
    
    % add surface to scene
    connImaris.mImarisApplication.GetSurpassScene.AddChild(vSurfaces, -1);
    waitbar(vIndex / vNumberOfObjects, wb);
end
delete(wb);
toc
end