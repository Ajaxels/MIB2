function menuModelAnn_Callback(obj, parameter)
% function menuModelAnn_Callback(obj, parameter)
% callback to Menu->Models->Annotations
%
% Parameters:
% parameter: a string with parameter
% @li 'list' - show list of annotations
% @li 'imaris' - export annotations to Imaris as spots
% @li 'delete' - % delete all annotations

% Copyright (C) 21.09.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%
global mibPath;

switch parameter
    case 'list'
        % show list of annotations
        obj.startController('mibAnnotationsController');
        obj.mibModel.mibShowAnnotationsCheck = 1;
    case 'imaris'
        % export annotations to Imaris
        [labelsList, labelValue, labelPositions] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels();
        if numel(labelsList) == 0; return; end
        labelPositions = [labelPositions(:,2), labelPositions(:,3), labelPositions(:,1), labelPositions(:,4)];   % reshape to [x, y, z, t]
        
        % recalculate position in respect to the bounding box
        bb = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
        pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
        labelPositions(:, 1) = labelPositions(:, 1)*pixSize.x + bb(1) - pixSize.x/2;
        labelPositions(:, 2) = labelPositions(:, 2)*pixSize.y + bb(3) - pixSize.y/2;
        labelPositions(:, 3) = labelPositions(:, 3)*pixSize.z + bb(5) - pixSize.z;
        
        radii = (max(labelPositions(:, 1))-min(labelPositions(:, 1)))/50/max(labelValue);
        
        prompt = {'Radius scaling factor for spots:', sprintf('Color [R, G, B, A]\nrange from 0 to 1'), 'Name for spots:'};
        defAns = {num2str(radii), '1, 0, 0, 0', 'mibSpots'};
        answer = mibInputMultiDlg({mibPath}, prompt, defAns, 'Export to Imaris');
        if isempty(answer); return; end
                    
        options.radii = labelValue * str2double(answer{1});
        options.color = str2num(answer{2}); %#ok<ST2NM>
        options.name = answer{3};
        obj.mibModel.connImaris = mibSetImarisSpots(labelPositions, obj.mibModel.connImaris, options);
    case 'delete'
        % delete all annotations
        obj.mibSegmAnnDeleteAllBtn_Callback();
end

end