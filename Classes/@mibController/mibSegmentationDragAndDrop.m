function mibSegmentationDragAndDrop(obj, y, x, modifier)
% mibSegmentationDragAndDrop(y, x, modifier)
% Fix segmentation or mask/selection layers by dragging individual 2D/3D
% objects or complete models with a  mouse
%
% Parameters:
% y: y-coordinate of the mouse cursor at the starting point
% x: x-coordinate of the mouse cursor at the starting point
% modifier: a string, to specify what to do with the generated selection
% - @em ''shift'' - shift all object on the slice
% - @em ''control'' - shift only a single selected object
% Return values:
% 

%| @b Examples:
% @code obj.mibSegmentationDragAndDrop(50, 75, 'control');  // start the drag and drop tool from position [y,x]=50,75,10 @endcode

% Copyright (C) 05.08.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if isempty(modifier)
    obj.mibView.brushSelection = NaN;    % remove all brush_selection data
    return; 
end   % safety lock, drag and drop requires Shift or Control modifiers

% check for switch that disables segmentation tools
if obj.mibModel.disableSegmentation == 1; return; end
obj.mibView.brushPrevXY = [x, y];
layer = obj.mibView.handles.mibSegmDragDropLayer.String{obj.mibView.handles.mibSegmDragDropLayer.Value};
options.blockModeSwitch = 0;
[blockHeight, blockWidth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, NaN, options);

obj.mibView.brushSelection = {};
%obj.mibView.brushSelection{1} = logical(zeros([size(obj.mibView.Ishown,1) size(obj.mibView.Ishown,2)], 'uint8')); %#ok<LOGL>

%obj.mibView.brushSelection{1}(y,x) = 1;
getDataOptions.blockModeSwitch = 1;
selarea = cell2mat(obj.mibModel.getData2D(layer, NaN, NaN, NaN, getDataOptions));
selarea = imresize(selarea, [size(obj.mibView.Ishown, 1) size(obj.mibView.Ishown, 2)], 'nearest');

if strcmp(modifier, 'shift')
    if obj.mibView.handles.mibActions3dCheck.Value == 0
        mode = '2D, Slice';
        obj.mibModel.mibDoBackup('selection', 0); % do backup
    else
        mode = '3D, Stack';
        obj.mibModel.mibDoBackup('selection', 1); % do backup
    end
    obj.mibView.brushSelection = selarea;  
    obj.mibView.brushSelection(selarea>0) = 1;
elseif strcmp(modifier, 'control')
     if obj.mibView.handles.mibActions3dCheck.Value == 0
        mode = 'Object2D';
        obj.mibModel.mibDoBackup('selection', 0); % do backup
     else
         if obj.matlabVersion < 9.3
            errordlg(sprintf('!!! Error !!!\n\nThis option is only available for Matlab release R2017b and newer!'), 'Matlab is too old');
            return;
         end
         mode = 'Object3D';
        obj.mibModel.mibDoBackup('selection', 1); % do backup
    end
    if strcmp(layer, 'model')
        materialId = selarea(y, x);
        selarea(selarea~=materialId) = 0;
    end
    selarea = bwselect(selarea,x,y);
    obj.mibView.brushSelection = selarea;
end

obj.mibView.updateCursor('solid');   % set the brush cursor in the drawing mode
obj.mibView.gui.WindowButtonDownFcn = [];

obj.mibView.gui.Pointer = 'custom';
obj.mibView.gui.PointerShapeCData = nan(16);
obj.mibView.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowDragAndDropMotionFcn(obj.mibView.brushSelection));
obj.mibView.gui.WindowButtonUpFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonUpDragAndDropFcn(mode));

end
