function mibImg = mibImageDeepCopy(obj, fromId, toId)
% function mibImg = mibImageDeepCopy(obj, fromId, toId)
% copy mibImage class from one container to another; used in mibBufferToggleContext_Callback, duplicate
% 
% Parameters:
% fromId: [@em optional] - index of the original dataset, default obj.Id;
% fromId can also be an instance of mibImage class
% toId: index of the dataset to where copy the image, when omitted, the
% resulting image will be exported to return variable mibImg
%
% Return values:
% mibImg: a deep copy of the image in fromId; exported only when toId is
% missing

% Copyright (C) 01.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 21.11.2019, swapped fromId and toId, added fromId to be a member of mibImage class, added return value mibImg 

mibImg = [];

%if nargin < 3;  error('The destination is missing!'); end
if nargin < 2; 	fromId = obj.Id; end

wb = waitbar(0, 'Please wait...', 'Name', 'Copy dataset', 'WindowStyle', 'modal');

if isa(fromId, 'mibImage')  % make a copy of the fromId to mibImg
    mibImg = copy(fromId);
    if fromId.Virtual.virtual == 1 && strcmp(fromId.Virtual.objectType{1}, 'bioformats')  % copy handles of the virtual image files
        mibImg.img = fromId.img;
    end
    waitbar(0.5, wb);
    mibImg.meta = containers.Map(keys(fromId.meta), values(fromId.meta));  % make a copy of img_info containers.Map
    waitbar(0.6, wb);
    mibImg.hROI = copy(fromId.hROI);     % copy hROI class contents
    waitbar(0.7, wb);
    mibImg.hROI.mibImage = mibImg;     % re-reference mibImage
    waitbar(0.8, wb);
    mibImg.hLabels  = copy(fromId.hLabels);
    waitbar(0.85, wb);
    mibImg.hLines3D  = copy(fromId.hLines3D);
    waitbar(0.9, wb);
    mibImg.hMeasure  = copy(fromId.hMeasure);
    mibImg.hMeasure.hImg  = mibImg; % re-reference mibImage
else
    mibImg = copy(obj.I{fromId});
    if obj.I{fromId}.Virtual.virtual == 1 && strcmp(obj.I{fromId}.Virtual.objectType{1}, 'bioformats')  % copy handles of the virtual image files
        mibImg.img = obj.I{fromId}.img;
    end
    waitbar(0.5, wb);
    mibImg.meta = containers.Map(keys(obj.I{fromId}.meta), values(obj.I{fromId}.meta));  % make a copy of img_info containers.Map
    waitbar(0.6, wb);
    mibImg.hROI = copy(obj.I{fromId}.hROI);     % copy hROI class contents
    waitbar(0.7, wb);
    mibImg.hROI.mibImage = mibImg;     % re-reference mibImage
    waitbar(0.8, wb);
    mibImg.hLabels  = copy(obj.I{fromId}.hLabels);
    waitbar(0.85, wb);
    mibImg.hLines3D  = copy(obj.I{fromId}.hLines3D);
    waitbar(0.9, wb);
    mibImg.hMeasure  = copy(obj.I{fromId}.hMeasure);
    mibImg.hMeasure.hImg  = mibImg; % re-reference mibImage
end

if nargin == 3   % make a deep copy of mibImage to another container
    obj.I{toId}.closeVirtualDataset();    % close virtual datasets at destination
    obj.I{toId} = mibImg;
    %obj.I{toId} = copy(obj.I{fromId});
    
end

waitbar(1, wb);

% obj.I{toId}.closeVirtualDataset();    % close virtual datasets at destination
% 
% obj.I{toId} = copy(obj.I{fromId});
% if obj.I{fromId}.Virtual.virtual == 1 && strcmp(obj.I{fromId}.Virtual.objectType{1}, 'bioformats')  % copy handles of the virtual image files
%     obj.I{toId}.img = obj.I{fromId}.img;
% %     obj.I{toId}.img = cell([numel(obj.I{fromId}.img), 1]); % clear .img at destination
% %     for i=1:numel(obj.I{fromId}.img)
% %         obj.I{toId}.img{i} = loci.formats.Memoizer(bfGetReader(), 0);
% %         obj.I{toId}.img{i}.setId(obj.I{fromId}.Virtual.filenames{i});
% %         obj.I{toId}.img{i}.setSeries(obj.I{fromId}.Virtual.seriesName{i}-1);
% %         obj.I{toId}.img{i}.close();
% %     end
% end
% waitbar(0.5, wb);
% obj.I{toId}.meta = containers.Map(keys(obj.I{fromId}.meta), values(obj.I{fromId}.meta));  % make a copy of img_info containers.Map
% waitbar(0.6, wb);
% obj.I{toId}.hROI = copy(obj.I{fromId}.hROI);     % copy hROI class contents
% waitbar(0.7, wb);
% obj.I{toId}.hROI.mibImage = obj.I{toId};     % re-reference mibImage
% waitbar(0.8, wb);
% obj.I{toId}.hLabels  = copy(obj.I{fromId}.hLabels);
% waitbar(0.85, wb);
% obj.I{toId}.hLines3D  = copy(obj.I{fromId}.hLines3D);
% waitbar(0.9, wb);
% obj.I{toId}.hMeasure  = copy(obj.I{fromId}.hMeasure);
% obj.I{toId}.hMeasure.hImg  = obj.I{toId}; % re-reference mibImage
% waitbar(1, wb);


delete(wb);
end