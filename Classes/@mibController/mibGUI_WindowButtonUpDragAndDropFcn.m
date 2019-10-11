function mibGUI_WindowButtonUpDragAndDropFcn(obj, mode, diffX, diffY, BatchOptIn)
% function mibGUI_WindowButtonUpDragAndDropFcn(obj, mode, diffX, diffY, BatchOptIn)
% callback for release of the mouse button after use of the Drag and Drop
% materials tool
%
% Parameters:
% mode: - mode for the drag and drop action
% @li - ''2D, Slice'', drag all selection shown on the current slice
% @li - ''Object2D'', drag the selected object only on the current slice
% @li - ''3D, Stack'', drag all selection for all slices of the dataset
% @li - ''Object3D'', drag the selected 3D object
% diffX: - [@em optional] optional value for shift in dX direction, not
% compatible with the ''Object2D'' mode
% diffY: - [@em optional] optional value for shift in dY direction, not
% compatible with the ''Object2D'' mode
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Target = 'Layer to be moved
% @li .Mode = 'Part of the dataset to be moved
% @li .shiftX = 'X-shift in pixels
% @li .shiftY = 'Y-shift in pixels
% @li .showWaitbar = 'Show or not the progress bar during execution
%
% Copyright (C) 05.08.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

if nargin < 4; diffY = []; end
if nargin < 3; diffX = []; end
if nargin < 2; mode = '2D, Slice'; end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
BatchOpt.id = obj.mibModel.Id;   % optional, id
BatchOpt.Target = obj.mibView.handles.mibSegmDragDropLayer.String(obj.mibView.handles.mibSegmDragDropLayer.Value);
BatchOpt.Target{2} = {'selection', 'mask', 'model'};
BatchOpt.Mode = {'2D, Slice'};     % '2D, Slice', '3D, Stack'
BatchOpt.Mode{2} = {'2D, Slice', '3D, Stack'};
if ~isempty(mode) && ismember(mode, BatchOpt.Mode{2})
    BatchOpt.Mode{1} = mode;
end
BatchOpt.shiftX =  '0';
if ~isempty(diffX); BatchOpt.shiftX = num2str(diffX); end
BatchOpt.shiftY =  '0';
if ~isempty(diffY); BatchOpt.shiftY = num2str(diffY); end
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.mibBatchSectionName = 'Panel -> Segmentation';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Drag & Drop materials';
BatchOpt.mibBatchTooltip.Target = 'Layer to be moved';
BatchOpt.mibBatchTooltip.Mode = 'Part of the dataset to be moved';
BatchOpt.mibBatchTooltip.shiftX = 'X-shift in pixels';
BatchOpt.mibBatchTooltip.shiftY = 'Y-shift in pixels';
BatchOpt.mibBatchTooltip.showWaitbar = 'Show or not the progress bar during execution';

%% Batch mode check actions
if nargin == 5  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj.mibModel, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 5th parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    end
    diffX = str2double(BatchOpt.shiftX);
    diffY = str2double(BatchOpt.shiftY);
    mode = BatchOpt.Mode{1};
else
    if nargin < 3
        pos = obj.mibView.handles.mibImageAxes.CurrentPoint;
        XLim = size(obj.mibView.Ishown,2);
        YLim = size(obj.mibView.Ishown,1);
        pos = round(pos);
        
        if pos(1,1)<=0; pos(1,1)=1; end
        if pos(1,1)>XLim; pos(1,1)=XLim; end
        if pos(1,2)<=0; pos(1,2)=1; end
        if pos(1,2)>YLim; pos(1,2)=YLim; end
        
        % calculate shift for the selection layer
        diffX = pos(1,1) - obj.mibView.brushPrevXY(1);
        diffY = pos(1,2) - obj.mibView.brushPrevXY(2);
        
        magFactor = obj.mibModel.getMagFactor();
        diffX = round(diffX*magFactor);
        diffY = round(diffY*magFactor);
    end
end

getDataOptions.blockModeSwitch = 0;
getDataOptions.id = BatchOpt.id;
[height, width, ~, depth, time] = obj.mibModel.I{BatchOpt.id}.getDatasetDimensions('image', NaN, NaN, getDataOptions);

switch mode
    case {'2D, Slice', 'Object2D'}
        selarea = cell2mat(obj.mibModel.getData2D(BatchOpt.Target{1}, NaN, NaN, NaN, getDataOptions));
        if strcmp(mode, 'Object2D')
            [xOut, yOut] = obj.mibModel.convertMouseToDataCoordinates(obj.mibView.brushPrevXY(1), obj.mibView.brushPrevXY(2), 'shown', 1);
            
            if strcmp(BatchOpt.Target{1}, 'model')
                materialId = selarea(ceil(yOut), ceil(xOut));
                currSelArea = selarea;
                selarea2 = zeros(size(selarea), 'uint8');
                selarea2(selarea==materialId) = 1;
                selarea = bwselect(selarea2, xOut, yOut);     % get translated object
                currSelArea(selarea==1) = 0;
            else
                materialId = 1;
                selarea2 = bwselect(selarea,xOut,yOut);     % get translated object
                currSelArea = selarea;  % store selected area
                currSelArea(selarea2 == 1) = 0;      % remove translated object
                selarea = selarea2;
            end
        end
        
        selAreaOut = zeros(size(selarea), 'uint8');
        w2 = width-abs(diffX);
        h2 = height-abs(diffY);
        if diffY>0 && diffX>0
            selAreaOut(diffY+1:end, diffX+1:end) = selarea(1:h2, 1:w2);
        elseif diffY>0 && diffX<=0
            selAreaOut(diffY+1:end, 1:w2) = selarea(1:h2, abs(diffX)+1:end);
        elseif diffY<=0 && diffX>0
            selAreaOut(1:h2, diffX+1:end) = selarea(abs(diffY)+1:end, 1:w2);
        elseif diffY<=0 && diffX<=0
            selAreaOut(1:h2, 1:w2) = selarea(abs(diffY)+1:end, abs(diffX)+1:end);
        end
        
        if strcmp(mode, 'Object2D')
            currSelArea(selAreaOut==1) = materialId;
            obj.mibModel.setData2D(BatchOpt.Target{1}, currSelArea, NaN, NaN, NaN, getDataOptions);
        else
            obj.mibModel.setData2D(BatchOpt.Target{1}, selAreaOut, NaN, NaN, NaN, getDataOptions);
        end
    case {'3D, Stack', 'Object3D'}
        if BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait'); end
        selarea = cell2mat(obj.mibModel.getData3D(BatchOpt.Target{1}, NaN, NaN, NaN, getDataOptions));
        if strcmp(mode, 'Object3D')
            [xOut, yOut] = obj.mibModel.convertMouseToDataCoordinates(obj.mibView.brushPrevXY(1), obj.mibView.brushPrevXY(2), 'shown', 1);
            zOut = obj.mibModel.I{BatchOpt.id}.getCurrentSliceNumber();
            if strcmp(BatchOpt.Target{1}, 'model')
                materialId = selarea(ceil(yOut), ceil(xOut), zOut);
                currSelArea = selarea;
                selarea2 = zeros(size(selarea), 'uint8');
                selarea2(selarea==materialId) = 1;
                selarea = bwselect3(selarea2, ceil(xOut), ceil(yOut), zOut);     % get translated object
                currSelArea(selarea==1) = 0;
            else
                materialId = 1;
                selarea2 = bwselect3(selarea,ceil(xOut),ceil(yOut),zOut);     % get translated object
                currSelArea = selarea;  % store selected area
                currSelArea(selarea2 == 1) = 0;      % remove translated object
                selarea = selarea2;
            end
        end
        if BatchOpt.showWaitbar; waitbar(0.5, wb); end
        selAreaOut = zeros(size(selarea), 'uint8');
        w2 = width-abs(diffX);
        h2 = height-abs(diffY);
        if diffY>0 && diffX>0
            selAreaOut(diffY+1:end, diffX+1:end, :) = selarea(1:h2, 1:w2, :);
        elseif diffY>0 && diffX<=0
            selAreaOut(diffY+1:end, 1:w2, :) = selarea(1:h2, abs(diffX)+1:end, :);
        elseif diffY<=0 && diffX>0
            selAreaOut(1:h2, diffX+1:end, :) = selarea(abs(diffY)+1:end, 1:w2, :);
        elseif diffY<=0 && diffX<=0
            selAreaOut(1:h2, 1:w2, :) = selarea(abs(diffY)+1:end, abs(diffX)+1:end, :);
        end
        if BatchOpt.showWaitbar; waitbar(0.9, wb); end
        if strcmp(mode, 'Object3D')
            currSelArea(selAreaOut==1) = materialId;
            obj.mibModel.setData3D(BatchOpt.Target{1}, currSelArea, NaN, NaN, NaN, getDataOptions);
        else
            obj.mibModel.setData3D(BatchOpt.Target{1}, selAreaOut, NaN, NaN, NaN, getDataOptions);
        end
        if BatchOpt.showWaitbar; waitbar(1, wb); delete(wb); end
end

obj.mibView.brushSelection = NaN;    % remove all brush_selection data
obj.mibView.brushPrevXY = NaN;

if nargin < 3; obj.mibView.gui.Pointer = 'crosshair'; end
obj.mibView.gui.WindowButtonUpFcn = [];
obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonDownFcn());
obj.mibView.gui.WindowKeyPressFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowKeyPressFcn(hObject, eventdata)); % turn ON callback for the keys

if obj.mibView.centerSpotHandle.enable
    obj.mibView.centerSpotHandle.handle.Visible = 'on';
end

obj.plotImage();
obj.mibView.updateCursor('dashed');
obj.mibView.gui.WindowScrollWheelFcn = (@(hObject, eventdata, handles) obj.mibGUI_ScrollWheelFcn(eventdata));   % moved from plotImage
obj.mibView.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.mibGUI_WinMouseMotionFcn());   % moved from plotImage


% notify the batch mode
if strcmp(mode, '2D, Slice') || strcmp(mode, '3D, Stack')
    BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
    eventdata = ToggleEventData(BatchOpt);
    notify(obj.mibModel, 'syncBatch', eventdata);
end
end
