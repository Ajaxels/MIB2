function mibImageDeepCopy(obj, toId, fromId)
% function mibImageDeepCopy(obj, toId, fromId)
% copy mibImage class from one container to another; used in mibBufferToggleContext_Callback, duplicate
% 
% Parameters:
% toId: index of the dataset to wh
% fromId: [@em optional] - index of the original dataset, default obj.Id

% Copyright (C) 01.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 3; 	fromId = obj.Id; end
if nargin < 2;  error('The destination is missing!'); end

wb = waitbar(0, 'Please wait...', 'Name', 'Copy dataset', 'WindowStyle', 'modal');

obj.I{toId}.closeVirtualDataset();    % close virtual datasets at destination

obj.I{toId} = copy(obj.I{fromId});
if obj.I{fromId}.Virtual.virtual == 1 && strcmp(obj.I{fromId}.Virtual.objectType{1}, 'bioformats')  % copy handles of the virtual image files
    obj.I{toId}.img = obj.I{fromId}.img;
%     obj.I{toId}.img = cell([numel(obj.I{fromId}.img), 1]); % clear .img at destination
%     for i=1:numel(obj.I{fromId}.img)
%         obj.I{toId}.img{i} = loci.formats.Memoizer(bfGetReader(), 0);
%         obj.I{toId}.img{i}.setId(obj.I{fromId}.Virtual.filenames{i});
%         obj.I{toId}.img{i}.setSeries(obj.I{fromId}.Virtual.seriesName{i}-1);
%         obj.I{toId}.img{i}.close();
%     end
end
waitbar(0.5, wb);
obj.I{toId}.meta = containers.Map(keys(obj.I{fromId}.meta), values(obj.I{fromId}.meta));  % make a copy of img_info containers.Map
waitbar(0.6, wb);
obj.I{toId}.hROI = copy(obj.I{fromId}.hROI);     % copy hROI class contents
waitbar(0.7, wb);
obj.I{toId}.hROI.mibImage = obj.I{toId};     % re-reference mibImage
waitbar(0.8, wb);
obj.I{toId}.hLabels  = copy(obj.I{fromId}.hLabels);
waitbar(0.85, wb);
obj.I{toId}.hLines3D  = copy(obj.I{fromId}.hLines3D);
waitbar(0.9, wb);
obj.I{toId}.hMeasure  = copy(obj.I{fromId}.hMeasure);
obj.I{toId}.hMeasure.hImg  = obj.I{toId}; % re-reference mibImage
waitbar(1, wb);
delete(wb);
end