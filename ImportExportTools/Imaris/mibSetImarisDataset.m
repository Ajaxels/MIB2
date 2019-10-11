function connImaris = mibSetImarisDataset(mibImage, connImaris, options)
% function connImaris = mibSetImarisDataset(mibImage, connImaris, options)
% Send a dataset from MIB to Imaris
%
% Parameters:
% mibImage: an instance of mibImage with the dataset to export to Imaris
% connImaris: [@em optional] a handle to Imaris connection
% options: an optional structure with additional settings (for example, when is called
% from mibRenderModelImaris.m)
% @li .type -> [@em optional] type of dataset to send ('image', 'model', 'mask', 'selection')
% @li .modelIndex [@em optional] index of a model material to send, could be @em NaN
% @li .mode -> [@em optional] type of mode for sending ('3D', '4D')
% @li .insertInto -> [@em optional] a cell with index where to insert the Z-stack, when -1 replaces the whole dataset;
% @li .lutColors -> [@em optional] a matrix with colors for the color channels
% @li .showWaitbar -> logical show or not the waitbar
%
% Return values:
% connImaris:  a handle to Imaris connection

% @note
% uses IceImarisConnector bindings
% @b Requires:
% 1. set system environment variable IMARISPATH to the installation
% directory, for example "c:\tools\science\imaris"
% 2. restart Matlab

%|
% @b Examples:
% @code options.lutColors = obj.mibModel.displayedLutColors;   // call from mibController; get colors for the color channels @endcode
% @code obj.connImaris = mibSetImarisDataset(obj.mibModel.I{obj.mibModel.Id}, obj.connImaris, options);     // call from mibController; send dataset from matlab to imaris @endcode

% Copyright (C) 10.01.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 25.09.2017 IB updated connection to Imaris

global mibPath; 

if nargin < 3;     options = struct(); end
if nargin < 2;     connImaris = []; end

if mibImage.Virtual.virtual == 1 % virtual stack
    errordlg(sprintf('!!! Error !!!\n\nThis mode is not yet implemented for the virtual stacking mode'), 'Not implemented');
    return;
end

if ~isfield(options, 'type'); options.type = 'image'; end
if ~isfield(options, 'modelIndex'); options.modelIndex = NaN; end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end

% establish connection to Imaris
connImaris = mibConnectToImaris(connImaris);
if isempty(connImaris); return; end

if isfield(options, 'mode')     % mode already provided
    mode = options.mode;
else
    if mibImage.time > 1
        mode = questdlg(sprintf('Would you like to export currently shown 3D (W:H:C:Z) stack or complete 4D (W:H:C:Z:T) dataset to Imaris?'),...
            'Export to Imaris', '3D', '4D', 'Cancel', '3D');
        if strcmp(mode, 'Cancel'); return; end
    else
        mode = '3D';
    end
end

options.blockModeSwitch = 0;
[sizeY, sizeX, maxColors, sizeZ, maxTime] = mibImage.getDatasetDimensions('image', 4, NaN, options); % get dataset dimensions

blockSizeX = 512;
blockSizeY = 512;
blockSizeZ = 512;

useBlockMode = 0;
if sizeX*sizeY*sizeZ > 134217728 % = 512 x 512 x 512
    useBlockMode = 1;
end
if strcmp(options.type, 'image')
    noColors = numel(mibImage.slices{3});  % number of shown colors
    dataClass = mibImage.meta('imgClass');
else
    if isnan(options.modelIndex)
        noColors = numel(mibImage.modelMaterialNames);  % number of shown colors
        options.modelIndex = 1:numel(mibImage.modelMaterialNames);
    else
        noColors = numel(options.modelIndex);
    end
    dataClass = class(mibImage.model{1});
end

updateBoundingBox = 1;  % switch to update bouning box
% check whether replace the dataset or update a time point
if strcmp(mode, '4D')
    % create an empty dataset
    connImaris.createDataset(dataClass, sizeX, sizeY, sizeZ, noColors, maxTime);
    timePointsIn = 1:maxTime;   % list of time points in the MIB dataset
    timePointsOut = 1:maxTime;  % list of time points in the Imaris dataset
elseif isempty(connImaris.mImarisApplication.GetDataSet) && strcmp(mode, '3D')
    % create an empty dataset
    connImaris.createDataset(dataClass, sizeX, sizeY, sizeZ, noColors, 1);
    timePointsIn = mibImage.slices{5}(1);  % list of time points in the MIB dataset
    timePointsOut = 1;  % list of time points in the Imaris dataset
else
    [vSizeX, vSizeY, vSizeZ, vSizeC, vSizeT] = connImaris.getSizes();
    if vSizeZ > 1 && vSizeT > 1 && strcmp(mode, '3D')
        if ~isfield(options, 'insertInto')
            insertInto = mibInputDlg({mibPath}, ...
                sprintf('!!! Warning !!!\n\nA 5D dataset is open in Imaris!\nPlease enter a time point to update (starting from 0)\nor type "-1" to replace dataset completely'), ...
                'Time point', mibImage.slices{5}(1));
            if isempty(insertInto);            return;        end
        else
            insertInto = options.insertInto;
        end
        if str2double(insertInto{1}) == -1
            % create an empty dataset
            connImaris.createDataset(dataClass, sizeX, sizeY, sizeZ, noColors, 1);
            timePointsIn = mibImage.slices{5}(1);
            timePointsOut = 1;
        else
            timePointsIn = str2double(insertInto{1});
            timePointsOut = str2double(insertInto{1});
            updateBoundingBox = 0;
        end
    else
        % create an empty dataset
        connImaris.createDataset(dataClass, sizeX, sizeY, sizeZ, noColors, 1);
        timePointsIn = mibImage.slices{5}(1);  % list of time points in the MIB dataset
        timePointsOut = 1;  % list of time points in the Imaris dataset
    end
end
if options.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'Export image to Imaris'); end
callsId = 0;

if useBlockMode == 0
    maxWaitbarIndex = numel(timePointsIn)*noColors;
else
    maxWaitbarIndex = noColors*ceil(sizeZ/blockSizeZ)*ceil(sizeY/blockSizeY)*ceil(sizeX/blockSizeX)*numel(timePointsIn);
end

% generate random colors
if ~isfield(options, 'lutColors')
    options.lutColors = randi(255, [noColors, 3])/255;
end
colorData = options.lutColors;

getDataOptions.blockModeSwitch = 0;

tIndex = 1;
for t=timePointsIn
    getDataOptions.t = [t t];
    for colId = 1:noColors
        % get color channel
        if strcmp(options.type, 'image')
            colorIndex = mibImage.slices{3}(colId);    % index of the selected colors
        else
            colorIndex = options.modelIndex(colId);
        end
        
        img = squeeze(mibImage.getData(options.type, 4, colorIndex, getDataOptions));
        
        % set dataset as a new
        if useBlockMode == 0
            connImaris.setDataVolumeRM(img(:,:,:), colId-1, timePointsOut(tIndex)-1);
            callsId = callsId + 1;
        else
            for z=0:ceil(sizeZ/blockSizeZ)-1
                for y=0:ceil(sizeY/blockSizeY)-1
                    for x=0:ceil(sizeX/blockSizeX)-1
                        imgBlock = img(...
                            1+blockSizeY*y:min(blockSizeY+blockSizeY*y, sizeY) ,...
                            1+blockSizeX*x:min(blockSizeX+blockSizeX*x, sizeX) ,...
                            1+blockSizeZ*z:min(blockSizeZ+blockSizeZ*z, sizeZ));
                        
                        connImaris.mib_setDataSubVolumeRM(imgBlock,...
                            blockSizeX*x, blockSizeY*y, blockSizeZ*z,...
                            colId-1, timePointsOut(tIndex)-1,...
                            size(imgBlock,2), size(imgBlock,1), size(imgBlock,3));
                        callsId = callsId + 1;
                        if options.showWaitbar; waitbar(callsId/maxWaitbarIndex, wb); end
                    end
                end
            end
        end
        
        % update contrast for color channels
        if t == timePointsIn(1)
            if strcmp(options.type, 'image')
                % get color channel
                colorIndex = mibImage.slices{3}(colId);    % index of the selected colors
                
                connImaris.mImarisApplication.GetDataSet.SetChannelRange(colId-1, ...
                    mibImage.viewPort.min(colorIndex), mibImage.viewPort.max(colorIndex));
                connImaris.mImarisApplication.GetDataSet.SetChannelGamma(colId-1, mibImage.viewPort.gamma(colorIndex));
            
                ColorRGBA = colorData(colorIndex, :);
            
                % replace black with white
                for i=1:size(ColorRGBA,1)
                    if sum(ColorRGBA(i,:)) == 0
                        ColorRGBA(i,:) = [1 1 1];
                    end
                end
                ColorRGBA(4) = 0;   % add Alpha value
                ColorRGBA = connImaris.mapRgbaVectorToScalar(ColorRGBA);
            else
                % set color for the surface
                ColorRGBA = [mibImage.modelMaterialColors(colorIndex,:) 0];
                ColorRGBA = connImaris.mapRgbaVectorToScalar(ColorRGBA);   
                connImaris.mImarisApplication.GetDataSet.SetChannelRange(colId-1, ...
                    0, max(max(max(max(img)))));
            end
            connImaris.mImarisApplication.GetDataSet.SetChannelColorRGBA(colId-1, ColorRGBA);     % update color channel
        end
        if options.showWaitbar; waitbar(callsId/maxWaitbarIndex, wb); end
    end
    tIndex = tIndex + 1;
end

% update BoundingBox and Image Description
if updateBoundingBox == 1
    bb = mibImage.getBoundingBox();    % bb[xMin, xMax, yMin, yMax, zMin, zMax]
    connImaris.mImarisApplication.GetDataSet.SetExtendMinX(bb(1));
    connImaris.mImarisApplication.GetDataSet.SetExtendMaxX(bb(2));
    connImaris.mImarisApplication.GetDataSet.SetExtendMinY(bb(3));
    connImaris.mImarisApplication.GetDataSet.SetExtendMaxY(bb(4));
    connImaris.mImarisApplication.GetDataSet.SetExtendMinZ(bb(5));
    % fix of a problem of different calculations of the bounding box for a
    % single slice and Z-stack
    if size(img,4) > 1
        connImaris.mImarisApplication.GetDataSet.SetExtendMaxZ(bb(6)+mibImage.pixSize.z);
    else
        connImaris.mImarisApplication.GetDataSet.SetExtendMaxZ(bb(6));
    end
    
    logText = mibImage.meta('ImageDescription');
    linefeeds = strfind(logText,sprintf('|'));
    
    if ~isempty(linefeeds)
        for linefeed = 1:numel(linefeeds)
            if linefeed == 1
                logTextForm(linefeed) = cellstr(logText(1:linefeeds(1)-1)); %#ok<AGROW>
            else
                logTextForm(linefeed) = cellstr(logText(linefeeds(linefeed-1)+1:linefeeds(linefeed)-1)); %#ok<AGROW>
            end
        end
        if numel(logText(linefeeds(end)+1:end)) > 1
            logTextForm(linefeed+1) = cellstr(logText(linefeeds(end)+1:end));
        end
    else
        logTextForm = [];
    end
    logOut = [];
    for i=1:numel(logTextForm)
        logOut = [logOut sprintf('%s\n',logTextForm{i})];
    end
    connImaris.mImarisApplication.GetDataSet.SetParameter('Image', 'Description', logOut);
end

% set the time point for the dataset to sync it later with models
if numel(timePointsIn) == 1 && timePointsOut(1) == 1     % single 3D dataset
    connImaris.mImarisApplication.GetDataSet.SetTimePoint(0, '0000-01-00 00:00:00.000');
% elseif numel(timePointsIn) == 1 && timePointsOut(1) ~= 1  % single 3D dataset into the opened dataset
%     stringTime = datestr(datenum('0000-01-00 00:00:00.000', 'yyyy-mm-dd HH:MM:SS.FFF') + ...
%         datenum(sprintf('0000-01-00 00:00:%.3f', (timePointsIn(1)-1)*mibImage.pixSize.t), 'yyyy-mm-dd HH:MM:SS.FFF'),...
%         'yyyy-mm-dd HH:MM:SS.FFF');
%     connImaris.mImarisApplication.GetDataSet.SetTimePoint(timePointsOut(1), stringTime);
else
    stringTime = datestr(datenum('0000-01-00 00:00:00.000', 'yyyy-mm-dd HH:MM:SS.FFF') + ...
        datenum(sprintf('0000-01-00 00:00:%3f', (timePointsIn(1)-1)*mibImage.pixSize.t), 'yyyy-mm-dd HH:MM:SS.FFF'),...
        'yyyy-mm-dd HH:MM:SS.FFF');
    connImaris.mImarisApplication.GetDataSet.SetTimePoint(timePointsOut(1)-1, stringTime);
    connImaris.mImarisApplication.GetDataSet.SetTimePointsDelta(mibImage.pixSize.t);
end
if options.showWaitbar; delete(wb); end
end
