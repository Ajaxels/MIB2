function mibZoomEdit_Callback(obj, BatchOptIn)
% function mibZoomEdit_Callback(obj, BatchOptIn)
% callback function for modification of the handles.mibZoomEdit 
%
% Parameters:
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event
% @li .Mode -> cell, magnification mode: 'Fit to screen', '100%', 'Zoom in', 'Zoom out', 'Set magnification'
% @li .MagnificationValue -> string, new magnification value

% Copyright (C) 10.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 19.09.2019 updated for the batch mode

if nargin < 2; BatchOptIn = struct; unFocus(obj.mibView.handles.mibZoomEdit);   end
zoomEdit = obj.mibView.handles.mibZoomEdit.String;

%% Declaration of the BatchOpt structure
BatchOpt = struct();
BatchOpt.Mode = {'Set magnification'};
BatchOpt.Mode{2} = {'Set magnification', 'Fit to screen', '100%', 'Zoom in', 'Zoom out'};
BatchOpt.MagnificationValue = zoomEdit(1:end-2);

BatchOpt.mibBatchSectionName = 'Panel -> Image view';
BatchOpt.mibBatchActionName = 'Change magnification';

% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Mode = sprintf('Enter a new slice number; use 0 to show the last slice of the dataset');
BatchOpt.mibBatchTooltip.MagnificationValue = sprintf('[Set magnification], desired magnification value in %%');

%%
if isstruct(BatchOptIn) == 0
    if isnan(BatchOptIn)     % when varargin{2} == NaN return possible settings
        % trigger syncBatch event to send BatchOptInOut to mibBatchController
        eventdata = ToggleEventData(BatchOpt);
        notify(obj.mibModel, 'syncBatch', eventdata);
    else
        errordlg(sprintf('A structure as the 1st parameter is required!'));
    end
    return;
else
    % add/update BatchOpt with the provided fields in BatchOptIn
    % combine fields from input and default structures
    BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
end

%%
switch BatchOpt.Mode{1}
    case 'Fit to screen'
        obj.updateAxesLimits('resize');       
        obj.plotImage(0); 
        return;
    case '100%'
        BatchOpt.MagnificationValue = '100';
    case 'Zoom in'
        BatchOpt.MagnificationValue = num2str(str2double(zoomEdit(1:end-1))*2);
    case 'Zoom out'
        BatchOpt.MagnificationValue = num2str(str2double(zoomEdit(1:end-1))/2);
end
zoom = str2double(BatchOpt.MagnificationValue);
if isnan(zoom)
    zoom = 100; 
    obj.mibView.handles.mibZoomEdit.String = '100 %';
end
newMagFactor = 100/zoom;
obj.updateAxesLimits('zoom', [], newMagFactor);

obj.plotImage(0);   
end