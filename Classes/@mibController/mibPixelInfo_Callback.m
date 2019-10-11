function mibPixelInfo_Callback(obj, parameter, BatchOptIn)
% function mibPixelInfo_Callback(obj, parameter, BatchOptIn)
% center image to defined position
% it is a callback from a popup menu above the pixel information field of
% the Path panel
% 
% Parameters:
% parameter: - a string that defines options:
% @li ''jump'' - center the viewing window around specified coordinates
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event
% @li .x -> string, x-coordinate, when missing or empty the view is not moved in this direction
% @li .y -> string, x-coordinate, when missing or empty the view is not moved in this direction
% @li .z -> string, x-coordinate, when missing or empty the view is not moved in this direction

% Copyright (C) 10.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 19.09.2019 updated for the batch mode

if nargin < 3; BatchOptIn = struct; end
if nargin < 2; parameter = []; end

if isempty(parameter); parameter = 'jump'; end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
xCent = num2str(obj.mibModel.I{obj.mibModel.Id}.axesX(1) + (obj.mibModel.I{obj.mibModel.Id}.axesX(2)-obj.mibModel.I{obj.mibModel.Id}.axesX(1))/2);
BatchOpt.x = xCent;
yCent = num2str(obj.mibModel.I{obj.mibModel.Id}.axesY(1) + (obj.mibModel.I{obj.mibModel.Id}.axesY(2)-obj.mibModel.I{obj.mibModel.Id}.axesY(1))/2);
BatchOpt.y = yCent;
zCent = num2str(obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber());

BatchOpt.z = zCent;
BatchOpt.mibBatchSectionName = 'Panel -> Image view';
BatchOpt.mibBatchActionName = 'Recenter the view';

% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.x = sprintf('New X coordinate of the central point, can be empty');
BatchOpt.mibBatchTooltip.y = sprintf('New Y coordinate of the central point, can be empty');
BatchOpt.mibBatchTooltip.z = sprintf('New Z coordinate of the central point, can be empty');

%%
if isstruct(BatchOptIn) == 0
    if isnan(BatchOptIn)     % when varargin{2} == NaN return possible settings
        % trigger syncBatch event to send BatchOptInOut to mibBatchController
        eventdata = ToggleEventData(BatchOpt);
        notify(obj.mibModel, 'syncBatch', eventdata);
    else
        errordlg(sprintf('A structure as the 2nd parameter is required!'));
    end
    return;
else
    % add/update BatchOpt with the provided fields in BatchOptIn
    % combine fields from input and default structures
    BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
end

if nargin < 3   % normal mode, obtain required parameters from a user
    switch parameter
        case 'jump'
            prompt = {sprintf('Enter destination in pixels\n\nX (1-%d):', obj.mibModel.I{obj.mibModel.Id}.width),...
                sprintf('Y (1-%d):', obj.mibModel.I{obj.mibModel.Id}.height),...
                sprintf('Z (1-%d):', obj.mibModel.I{obj.mibModel.Id}.depth)};
            defAns = {BatchOpt.x, BatchOpt.y, BatchOpt.z};
            
            mibInputMultiDlgOpt.PromptLines = [3, 1, 1];
            answer = mibInputMultiDlg({obj.mibPath}, prompt, defAns, 'Jump to:', mibInputMultiDlgOpt);
            if isempty(answer); return; end
            BatchOpt.x = answer{1};
            BatchOpt.y = answer{2};
            BatchOpt.z = answer{3};
    end
end

if isempty(BatchOpt.x); BatchOpt.x = xCent; end
if isempty(BatchOpt.y); BatchOpt.y = yCent; end
if isempty(BatchOpt.z); BatchOpt.z = zCent; end

x = str2double(BatchOpt.x);
y = str2double(BatchOpt.y);
z = str2double(BatchOpt.z);



switch parameter
    case 'jump'
        if obj.mibModel.I{obj.mibModel.Id}.width < x || obj.mibModel.I{obj.mibModel.Id}.height < y || ...
            x < 1 || y < 1 || isnan(x) || isnan(y) || isnan(z) 
            errordlg(sprintf('!!! Error !!!\nThe coordinates should be within the image boundaries!'),'Error');
            return;
        end
        
        if num2str(obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber()) ~= z
            obj.mibView.handles.mibChangeLayerEdit.String = BatchOpt.z;
            obj.mibChangeLayerEdit_Callback();
        end
        
        import java.awt.Robot;
        mouse = Robot;
        % set units to pixels
        obj.mibView.gui.Units = 'pixels';   % they were in points
        obj.mibView.handles.mibViewPanel.Units = 'pixels';   % they were in points
        
        pos1 = obj.mibView.gui.Position;
        pos2 = obj.mibView.handles.mibViewPanel.Position;
        pos3 = obj.mibView.handles.mibImageAxes.Position;
        screenSize = get(0, 'screensize');
        x1 = pos1(1) + pos2(1) + pos3(1) + pos3(3)/2;
        y1 = screenSize(4) - (pos1(2) + pos2(2) + pos3(2) + pos3(4)/2);
        mouse.mouseMove(x1*obj.mibModel.preferences.gui.systemscaling, y1*obj.mibModel.preferences.gui.systemscaling);
        % recenter the view
        obj.mibModel.I{obj.mibModel.Id}.moveView(x, y);
        
        % restore the units
        obj.mibView.gui.Units = 'points';
        obj.mibView.handles.mibViewPanel.Units = 'points';
        obj.plotImage(0);
end
end