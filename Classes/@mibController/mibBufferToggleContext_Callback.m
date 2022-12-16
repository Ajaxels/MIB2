function mibBufferToggleContext_Callback(obj, parameter, buttonID, BatchOptIn)
% function mibBufferToggleContext_Callback(obj, parameter, buttonID, BatchOptIn)
% callback function for the popup menu of the buffer buttons in the upper
% part of the @em Directory @em contents panel. This callback is triggered
% from all those buttons.
% 
% Parameters:
% parameter: - a string that defines options:
% @li @b ''duplicate'' - duplicate the dataset to another buffer
% @li @b ''sync_xy'' - synchronize datasets with another dataset in XY
% @li @b ''sync_xyz'' - synchronize datasets with another dataset in XYZ
% @li @b ''sync_xyzt'' - synchronize datasets with another dataset in XYZT
% @li @b ''link_views'' - link the view between two containers
% @li @b ''close'' - delete the dataset
% @li @b ''closeAll'' - delete all datasets
% buttonID: - a number (from 1 to 9) of the pressed toggle button.
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables

% Copyright (C) 04.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 07.08.2019 updated for the batch mode
% 06.10.2022 added link views

global mibPath; % path to mib installation folder

%% Declaration of the BatchOpt structure
BatchOpt = struct();
switch parameter
    case 'link_views'
        destinationButton = obj.mibModel.maxId;
        for i=1:obj.mibModel.maxId-1
            if ~strcmp(obj.mibModel.I{i}.meta('Filename'), 'none.tif') && i ~= obj.mibModel.Id
                destinationButton = i;
                break;
            end
        end
        if isempty(buttonID)
            BatchOpt.ContainerA = {'Current'};
            buttonID = obj.mibModel.Id;
        else
            BatchOpt.ContainerA = {sprintf('Container %d', buttonID)};
        end

        BatchOpt.ContainerA{2} = [{'Current'}, arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false)];
        BatchOpt.ContainerB = {sprintf('Container %d', destinationButton)};
        BatchOpt.ContainerB{2} = arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false);
        % generate a string for evaluation
        buttonIDHandle = sprintf('mibBufferToggle%i', buttonID);
        linked = obj.mibView.handles.(buttonIDHandle).ContextMenu.Children(3).Text(1) == '['; % check for "[Linked..."
        if linked
            BatchOpt.Linked = false;
        else
            BatchOpt.Linked = true;
        end
        BatchOpt.mibBatchTooltip.ContainerA = sprintf('Index of the first container to link the views');
        BatchOpt.mibBatchTooltip.ContainerB = sprintf('Index of the second container to link the views');
        BatchOpt.mibBatchTooltip.Linked = sprintf('Check to link the views between ContainerA and ContainerB');
        BatchOpt.mibBatchActionName = 'Link views';
    case {'duplicate', 'mirror'}
        destinationButton = obj.mibModel.maxId;
        for i=1:obj.mibModel.maxId-1
            if strcmp(obj.mibModel.I{i}.meta('Filename'), 'none.tif')
                destinationButton = i;  % index of the destination container
                break;
            end
        end
        if isempty(buttonID)
            BatchOpt.Source = {'Current'};
        else
            BatchOpt.Source = {sprintf('Container %d', buttonID)};
        end
        BatchOpt.Source{2} = [{'Current'}, arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false)];
        BatchOpt.Destination = {sprintf('Container %d', destinationButton)};
        BatchOpt.Destination{2} = arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false);
        BatchOpt.showWaitbar = true;   % show or not the waitbar
        BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');
        if strcmp(parameter, 'duplicate')
            BatchOpt.mibBatchTooltip.Source = sprintf('Index of the source container with a dataset to copy');
            BatchOpt.mibBatchTooltip.Destination = sprintf('Index of the destination container to copy the current dataset');
            BatchOpt.mibBatchActionName = 'Duplicate dataset';
        else    % mirror
            BatchOpt.mibBatchTooltip.Source = sprintf('Index of the source container with a dataset to mirror');
            BatchOpt.mibBatchTooltip.Destination = sprintf('Index of the destination container to mirror the current image');
            BatchOpt.mibBatchActionName = 'Duplicate dataset';
        end
    case 'close'
        if isempty(buttonID)
            BatchOpt.Target = {'Current'};
        else
            BatchOpt.Target = {sprintf('Container %d', buttonID)};
        end
        BatchOpt.Target{2} = [{'Current'}, arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false)];
        BatchOpt.mibBatchTooltip.Target = sprintf('Index of the target container with a dataset to close');
        BatchOpt.mibBatchActionName = 'Close dataset';
    case 'closeAll'
        BatchOpt.AreYouSure = false;
        BatchOpt.showWaitbar = true;   % show or not the waitbar
        BatchOpt.mibBatchTooltip.AreYouSure = sprintf('Confirm closing of all datasets');
        BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');
        BatchOpt.mibBatchActionName = 'Close all datasets';
    case {'sync_xy', 'sync_xyz', 'sync_xyzt'}
        destinationButton = obj.mibModel.maxId;
        for i=1:obj.mibModel.maxId-1
            if ~strcmp(obj.mibModel.I{i}.meta('Filename'), 'none.tif') && i ~= obj.mibModel.Id
                destinationButton = i;
                break;
            end
        end
        if isempty(buttonID)
            BatchOpt.ApplyTo = {'Current'};
        else
            BatchOpt.ApplyTo = {sprintf('Container %d', buttonID)};
        end
        BatchOpt.ApplyTo{2} = [{'Current'}, arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false)];
        BatchOpt.GetFrom = {sprintf('Container %d', destinationButton)};
        BatchOpt.GetFrom{2} = arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false);
        BatchOpt.Mode = {parameter};
        BatchOpt.Mode{2} = {'sync_xy', 'sync_xyz', 'sync_xyzt'};
        
        BatchOpt.mibBatchTooltip.ApplyTo = sprintf('Index of a container to be synchronized with another one');
        BatchOpt.mibBatchTooltip.GetFrom = sprintf('Index of a container with desired viewing parameters');
        BatchOpt.mibBatchTooltip.Mode = sprintf('Specify dimensions that should be synchronized');
        BatchOpt.mibBatchActionName = 'Sync views';
        
end
BatchOpt.mibBatchSectionName = 'Panel -> Directory contents';    % section name for the Batch

%% Batch mode check actions
if nargin == 4  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            eventdata = ToggleEventData(BatchOpt);
            notify(obj.mibModel, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 4th parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    end
end

switch parameter
    case 'link_views'
        if strcmp(BatchOpt.ContainerA{1}, 'Current')
            buttonID = obj.mibModel.Id;
        else
            buttonID = str2double(BatchOpt.ContainerA{1}(10:end));
        end
        buttonIDHandle = sprintf('mibBufferToggle%i', buttonID);

        if BatchOpt.Linked == false
            sourceButtonStr = obj.mibView.handles.(buttonIDHandle).ContextMenu.Children(3).Text(10);
            sourceButtonStr = ['mibBufferToggle', sourceButtonStr];
            destinationButtonStr = obj.mibView.handles.(buttonIDHandle).ContextMenu.Children(3).Text(16);
            destinationButtonHandle = ['mibBufferToggle', destinationButtonStr];
            
            obj.mibView.handles.(sourceButtonStr).ContextMenu.Children(3).Text = 'Link view with... [Unlinked]';
            obj.mibView.handles.(destinationButtonHandle).ContextMenu.Children(3).Text = 'Link view with... [Unlinked]';
        else
            if obj.mibModel.I{buttonID}.volren.show == 1; return; end
            if nargin < 4
                prompts = {'Enter number of the dataset to link the view with:'};
                defAns = {arrayfun(@(x) {num2str(x)}, 1:obj.mibModel.maxId)};
                defAns{1}(end+1) = {destinationButton};
                title = 'Link views';
                answer = mibInputMultiDlg({mibPath}, prompts, defAns, title);
                if isempty(answer); return; end
                BatchOpt.ContainerB(1) = {sprintf('Container %s', answer{1})};
            end
            destinationButton = str2double(BatchOpt.ContainerB{1}(10:end));

            if destinationButton == buttonID
                warndlg(sprintf('!!! Warning !!!\n\nPlease select 2 different datasets!\n\nSelected datasets:\n   %s\n   %s', BatchOpt.ContainerA{1}, BatchOpt.ContainerB{1}), 'Wrong selection!');
                return;
            end

            if obj.mibModel.I{buttonID}.orientation ~= obj.mibModel.I{destinationButton}.orientation
                errordlg(sprintf('The datasets should be in the same orientation!\n\nFor example, switch orientation of both datasets to XY (the XY button in the toolbar) and try again'),'Wrong buffer'); notify(obj.mibModel, 'stopProtocol'); return;
            end
            
            destinationButtonHandle = sprintf('mibBufferToggle%i', destinationButton);
            % check whether the destination is already linked
            if obj.mibView.handles.(destinationButtonHandle).ContextMenu.Children(3).Text(1) == '['
                warndlg(sprintf('!!! Warnining !!!\n\nThe second dataset in %s is already linked!\nUnlink it first and repeat the operation', BatchOpt.ContainerB{1}), 'Already linked!');
                notify(obj.mibModel, 'stopProtocol');
                return;
            end
            obj.mibView.handles.(buttonIDHandle).ContextMenu.Children(3).Text = sprintf('[Linked: %i <-> %i] press to unlink', buttonID, destinationButton);
            obj.mibView.handles.(destinationButtonHandle).ContextMenu.Children(3).Text = sprintf('[Linked: %i <-> %i] press to unlink', destinationButton, buttonID);
        end
        % notify the batch mode
        eventdata = ToggleEventData(BatchOpt);
        notify(obj.mibModel, 'syncBatch', eventdata);
    case {'duplicate', 'mirror'}    % duplicate dataset to a new position
        if nargin < 4 
            prompts = {'Enter the destination buffer:'};
            defAns = {arrayfun(@(x) {sprintf('%d', x)}, 1:obj.mibModel.maxId)};
            defAns{1}(end+1) = {destinationButton};
            title = 'Duplicate dataset';
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, title);
            if isempty(answer); return; end
            BatchOpt.Destination(1) = {sprintf('Container %s', answer{1})};
            
            destinationButton = str2double(BatchOpt.Destination{1}(10:end));  
            if ~strcmp(obj.mibModel.I{destinationButton}.meta('Filename'), 'none.tif')
                button = questdlg(sprintf('You are going to overwrite dataset in buffer %d\n\nAre you sure?', destinationButton), ...
                    '!! Warning !!', 'Overwrite', 'Cancel', 'Cancel');
                if strcmp(button, 'Cancel'); return; end
            end    
        end
        
        if strcmp(BatchOpt.Source{1}, 'Current')
            buttonID = obj.mibModel.Id;
        else
            buttonID = str2double(BatchOpt.Source{1}(10:end));
        end
        destinationButton = str2double(BatchOpt.Destination{1}(10:end));
        
        if strcmp(parameter, 'duplicate')
            if BatchOpt.showWaitbar; wb = waitbar(0, sprintf('Duplicate from %s to %s\nPlease wait...', BatchOpt.Source{1}, BatchOpt.Destination{1}), 'Name', 'Duplicate', 'WindowStyle', 'modal'); end
            
            obj.mibModel.mibImageDeepCopy(buttonID, destinationButton);
            if BatchOpt.showWaitbar; waitbar(0.9, wb); end
            bufferId = sprintf('mibBufferToggle%d', destinationButton);
            if ismac()
                obj.mibView.handles.(bufferId).ForegroundColor = [0 1 0];   % make green
            else
                obj.mibView.handles.(bufferId).BackgroundColor = [0 1 0]; % make green
            end
            obj.mibView.handles.(bufferId).TooltipString = obj.mibModel.I{i}.meta('Filename');     % make a tooltip as filename
        else    % mirror
            if BatchOpt.showWaitbar; wb = waitbar(0, sprintf('Mirror image from %s to %s\nPlease wait...', BatchOpt.Source{1}, BatchOpt.Destination{1}), 'Name', 'Mirror', 'WindowStyle', 'modal'); end
            obj.mibModel.mibImageDeepCopy(buttonID, destinationButton);
        end
        if BatchOpt.showWaitbar; waitbar(1, wb); delete(wb); end

        % notify the batch mode
        eventdata = ToggleEventData(BatchOpt);
        notify(obj.mibModel, 'syncBatch', eventdata);
    case {'sync_xy', 'sync_xyz', 'sync_xyzt'}  % synchronize view with another opened dataset
        if nargin < 4
            prompts = {'Enter number of the dataset to synchronize with:'};
            defAns = {arrayfun(@(x) {num2str(x)}, 1:obj.mibModel.maxId)};
            defAns{1}(end+1) = {destinationButton};
            title = 'Synchronize dataset';
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, title);
            if isempty(answer); return; end
            BatchOpt.GetFrom(1) = {sprintf('Container %s', answer{1})};
        end
        destinationButton = str2double(BatchOpt.GetFrom{1}(10:end));  
        if strcmp(BatchOpt.ApplyTo{1}, 'Current')
            buttonID = obj.mibModel.Id;
        else
            buttonID = str2double(BatchOpt.ApplyTo{1}(10:end));
        end
        
        if obj.mibModel.I{buttonID}.orientation ~= obj.mibModel.I{destinationButton}.orientation
            errordlg(sprintf('The datasets should be in the same orientation!\n\nFor example, switch orientation of both datasets to XY (the XY button in the toolbar) and try again'),'Wrong buffer'); notify(obj.mibModel, 'stopProtocol'); return;
        end
        
        if obj.mibModel.I{buttonID}.volren.show == 0
            [axesX, axesY] = obj.mibModel.getAxesLimits(destinationButton);
            obj.mibModel.setAxesLimits(axesX, axesY, buttonID);
            obj.mibModel.setMagFactor(obj.mibModel.getMagFactor(destinationButton), buttonID);
            
            if strcmp(BatchOpt.Mode{1}, 'sync_xyz') || strcmp(BatchOpt.Mode{1}, 'sync_xyzt')   % sync in z, t as well
                destZ = obj.mibModel.I{destinationButton}.slices{obj.mibModel.I{destinationButton}.orientation}(1);
                if destZ > obj.mibModel.I{buttonID}.dim_yxczt(obj.mibModel.I{buttonID}.orientation)
                    warndlg(sprintf('The second dataset has the Z value higher than the Z-dimension of the first dataset!\n\nThe synchronization was done in the XY mode.'),'Dimensions mismatch!');
                    notify(obj.mibModel, 'stopProtocol');
                    return;
                end
                if obj.mibModel.I{buttonID}.depth > 1
                    obj.mibView.handles.mibChangeLayerEdit.String = destZ;
                    obj.mibChangeLayerEdit_Callback();
                end
                if strcmp(BatchOpt.Mode{1}, 'sync_xyzt') && obj.mibModel.I{buttonID}.time > 1
                    destT = obj.mibModel.I{destinationButton}.slices{5}(1);
                    if destT > obj.mibModel.I{buttonID}.time
                        warndlg(sprintf('The second dataset has the T value higher than the T-dimension of the first dataset!\n\nThe synchronization was done in the XYZ mode.'),'Dimensions mismatch!');
                        obj.plotImage(0);
                        notify(obj.mibModel, 'stopProtocol');
                        return;
                    end
                    obj.mibView.handles.mibChangeTimeEdit.String = destT;
                    obj.mibChangeTimeEdit_Callback();
                end
            end
        else
             obj.mibView.volren{buttonID}.viewer_matrix = obj.mibView.volren{destinationButton}.viewer_matrix;
        end
        obj.plotImage(0);
    case 'close'    % close dataset
        if strcmp(BatchOpt.Target{1}, 'Current')
            buttonID = obj.mibModel.Id;
        else
            buttonID = str2double(BatchOpt.Target{1}(10:end));
        end
        
        mibImageOptions = struct();
        mibImageOptions.virtual = obj.mibModel.I{buttonID}.Virtual.virtual;
        
        obj.mibView.gui.WindowButtonMotionFcn = [];  % have to turn off windowbuttonmotionfcn, otherwise give error after delete(obj.mibView.handles.Img{button}.I); during mouse movement
        obj.mibModel.I{buttonID}.closeVirtualDataset();    % close the virtual datasets 
        
        delete(obj.mibModel.I{buttonID});
        obj.mibModel.I{buttonID} = mibImage([], [], mibImageOptions);    % create instance for keeping images;
        
        eventdata = ToggleEventData(buttonID);
        notify(obj.mibModel, 'newDataset', eventdata);
        
        if buttonID == obj.mibModel.Id; obj.plotImage(1); end   % redraw the current dataset
        % notify the batch mode
        eventdata = ToggleEventData(BatchOpt);
        notify(obj.mibModel, 'syncBatch', eventdata);
    case 'closeAll'     % clear all stored datasets
        if nargin < 4
            button = questdlg(sprintf('!!! Warning !!!\n\nYou are going to close all open datasets!\nContinue?'),...
                'Clear memory', 'Continue', 'Cancel', 'Cancel');
            if strcmp(button, 'Cancel'); return; end
            BatchOpt.AreYouSure = true;
        end
        if BatchOpt.AreYouSure == false; return; end
        
        if BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'Close all datasets', 'WindowStyle', 'modal'); end
        
        % initialize image buffer with dummy images
        obj.mibModel.Id = 1;   % number of the selected buffer
        obj.mibView.gui.WindowButtonMotionFcn = [];  % have to turn off windowbuttonmotionfcn, otherwise give error after delete(obj.mibView.handles.Img{button}.I); during mouse movement
        for button=1:obj.mibModel.maxId
            mibImageOptions = struct();
            mibImageOptions.virtual = obj.mibModel.I{button}.Virtual.virtual;
            obj.mibModel.I{button}.closeVirtualDataset();    % close the virtual datasets
            
            delete(obj.mibModel.I{button});
            obj.mibModel.I{button} = mibImage([],[],mibImageOptions);    % create instanse for keeping images;
            obj.updateAxesLimits('resize', button);
            bufferId = sprintf('mibBufferToggle%d', button);
            obj.mibView.handles.(bufferId).Value = 0;
            if BatchOpt.showWaitbar; waitbar(button/obj.mibModel.maxId, wb); end
        end
        obj.mibView.handles.mibBufferToggle1.Value = 1;
        notify(obj.mibModel, 'newDataset');  % notify about a new dataset
        obj.plotImage(1);
        if BatchOpt.showWaitbar; delete(wb); end
        
        % notify the batch mode
        eventdata = ToggleEventData(BatchOpt);
        notify(obj.mibModel, 'syncBatch', eventdata);
end

end
