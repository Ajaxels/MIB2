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

function mibImg = mibImageDeepCopy(obj, fromId, toId, options)
% function mibImg = mibImageDeepCopy(obj, fromId, toId, options)
% copy mibImage class from one container to another; used in mibBufferToggleContext_Callback, duplicate
% 
% Parameters:
% fromId: [@em optional] - index of the original dataset, default obj.Id;
% fromId can also be an instance of mibImage class
% toId: index of the dataset to where copy the image, when omitted, the
% resulting image will be exported to return variable mibImg
% options: [@em optional] - structure with additional parameters
% @li .showWaitbar - logical show or not the waitbar (default=true)
%
% Return values:
% mibImg: a deep copy of the image in fromId; exported only when toId is
% missing

% Updates
% 21.11.2019, swapped fromId and toId, added fromId to be a member of mibImage class, added return value mibImg 
% 12.09.2023, added options parameter

mibImg = [];

if nargin < 4; 	options = struct(); end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end

%if nargin < 3;  error('The destination is missing!'); end
if nargin < 2; 	fromId = obj.Id; end

if options.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'Copy dataset', 'WindowStyle', 'modal'); end

if isa(fromId, 'mibImage')  % make a copy of the fromId to mibImg
    mibImg = copy(fromId);
    if fromId.Virtual.virtual == 1 && strcmp(fromId.Virtual.objectType{1}, 'bioformats')  % copy handles of the virtual image files
        mibImg.img = fromId.img;
    end
    if options.showWaitbar; waitbar(0.5, wb); end
    mibImg.meta = containers.Map(keys(fromId.meta), values(fromId.meta));  % make a copy of img_info containers.Map
    if options.showWaitbar; waitbar(0.6, wb); end
    mibImg.hROI = copy(fromId.hROI);     % copy hROI class contents
    if options.showWaitbar; waitbar(0.7, wb); end
    mibImg.hROI.mibImage = mibImg;     % re-reference mibImage
    if options.showWaitbar; waitbar(0.8, wb); end
    mibImg.hLabels  = copy(fromId.hLabels);
    if options.showWaitbar; waitbar(0.85, wb); end
    mibImg.hLines3D  = copy(fromId.hLines3D);
    if options.showWaitbar; waitbar(0.9, wb); end
    mibImg.hMeasure  = copy(fromId.hMeasure);
    mibImg.hMeasure.hImg  = mibImg; % re-reference mibImage
else
    mibImg = copy(obj.I{fromId});
    if obj.I{fromId}.Virtual.virtual == 1 && strcmp(obj.I{fromId}.Virtual.objectType{1}, 'bioformats')  % copy handles of the virtual image files
        mibImg.img = obj.I{fromId}.img;
    end
    if options.showWaitbar; waitbar(0.5, wb); end
    mibImg.meta = containers.Map(keys(obj.I{fromId}.meta), values(obj.I{fromId}.meta));  % make a copy of img_info containers.Map
    if options.showWaitbar; waitbar(0.6, wb); end
    mibImg.hROI = copy(obj.I{fromId}.hROI);     % copy hROI class contents
    if options.showWaitbar; waitbar(0.7, wb); end
    mibImg.hROI.mibImage = mibImg;     % re-reference mibImage
    if options.showWaitbar; waitbar(0.8, wb); end
    mibImg.hLabels  = copy(obj.I{fromId}.hLabels);
    if options.showWaitbar; waitbar(0.85, wb); end
    mibImg.hLines3D  = copy(obj.I{fromId}.hLines3D);
    if options.showWaitbar; waitbar(0.9, wb); end
    mibImg.hMeasure  = copy(obj.I{fromId}.hMeasure);
    mibImg.hMeasure.hImg  = mibImg; % re-reference mibImage
end

if nargin > 2   % make a deep copy of mibImage to another container
    obj.I{toId}.closeVirtualDataset();    % close virtual datasets at destination
    obj.I{toId} = mibImg;
    %obj.I{toId} = copy(obj.I{fromId});
    
end

if options.showWaitbar; waitbar(1, wb); end

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


if options.showWaitbar; delete(wb); end
end