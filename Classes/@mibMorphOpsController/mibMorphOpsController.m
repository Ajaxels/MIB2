classdef mibMorphOpsController < handle
    % @type mibMorphOpsController class is resposnible for showing the morphological operations for the selection layer window, 
    % available from MIB->Selection->Morphological 2D/3D operations
    
	% Copyright (C) 10.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
	% 
	% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
	%
	% Updates
	%     
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        matlabVersion
        % current version of Matlab
        type
        % type of action to perform
        type3d
        % type of action to perform for 3D objects
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case {'updateGuiWidgets'}
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibMorphOpsController(mibModel, parameter)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibMorphOpsGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % check for the virtual stacking mode and close the controller
            if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                toolname = 'Morphological operations are';
                warndlg(sprintf('!!! Warning !!!\n\n%s not yet available in the virtual stacking mode!\nPlease switch to the memory-resident mode and try again', ...
                    toolname), 'Not implemented');
                obj.closeWindow();
                return;
            end
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            Font = obj.mibModel.preferences.Font;
            if obj.View.handles.infoText.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.infoText.FontName, Font.FontName)
                mibUpdateFontSize(obj.View.gui, Font);
            end
            obj.type = parameter;
            obj.type3d = 'branchpoints';
            
            matlabVer = ver('matlab');
            obj.matlabVersion = str2double(matlabVer.Version);
            if obj.matlabVersion >= 9.4
                obj.View.handles.objects3D.Enable = 'on';
            end
            
            obj.updateWidgets();
			
			% add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing mibMorphOpsController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete childController window
            end
            
            % delete listeners, otherwise they stay after deleting of the
            % controller
            for i=1:numel(obj.listener)
                delete(obj.listener{i});
            end
            
            notify(obj, 'closeEvent');      % notify mibController that this child window is closed
        end
        
        function updateWidgets(obj)
            % function updateWidgets(obj)
            % update widgets of this window
            
            if obj.View.handles.objects3D.Value == 1
                typeId = obj.type3d;
                obj.View.handles.sliceRadio.Enable = 'off';
                obj.View.handles.datasetRadio.Value = 1;
            else
                typeId = obj.type;
                obj.View.handles.sliceRadio.Enable = 'on';
            end
            
            % highlight desired operation in the list
            list = obj.View.handles.morphOpsPopup.String;
            for i=1:numel(list)
                if strcmp(list{i}, typeId)
                    obj.View.handles.morphOpsPopup.Value = i;
                    continue;
                end
            end
            obj.morphOpsPopup_Callback();
            
        end
        
        % --- Executes on selection change in morphOpsPopup.
        function morphOpsPopup_Callback(obj)
            % function morphOpsPopup_Callback(obj)
            % callback for change of obj.View.handles.morphOpsPopup
            
            contents = cellstr(obj.View.handles.morphOpsPopup.String);
            selected = contents{obj.View.handles.morphOpsPopup.Value};
            
            obj.View.handles.ulterPanel.Visible = 'off';
            obj.View.handles.iterPanel.Visible = 'on';
            obj.View.handles.limitToRadio.String = 'Limit to:';
            
            if obj.View.handles.objects3D.Value == 1
                obj.View.handles.limitToRadio.Enable = 'off';
                obj.View.handles.infiniteRadio.Enable = 'off';
                obj.View.handles.iterEdit.Enable = 'off';
            else
                obj.View.handles.limitToRadio.Enable = 'on';
                obj.View.handles.infiniteRadio.Enable = 'on';
                obj.View.handles.iterEdit.Enable = 'on';
            end
            
            switch strtrim(selected)
                case 'branchpoints'
                    textString = sprintf('Find branch points of skeleton.\nBranch points are the pixels at the junction where multiple branches meet.\nTo find branch points, the image must be skeletonized.');
                    obj.View.handles.infoText.String = textString;
                case 'bwulterode'
                    textString{1} = 'The ultimate erosion computesthe ultimate erosion of the selection';
                    textString{2} = '0 1 1 1  ->  0 0 0 0';
                    textString{3} = '0 1 1 1  ->  0 0 1 0';
                    textString{4} = '0 1 1 1  ->  0 0 0 0';
                    textString{5} = '0 0 0 0  ->  0 0 0 0';
                    obj.View.handles.infoText.String = textString;
                    obj.View.handles.iterPanel.Visible = 'off';
                    obj.View.handles.ulterPanel.Visible = 'on';
                case 'clean'
                    textString = sprintf('Remove isolated voxels.\nAn isolated voxel is an individual, 26-connected voxel that is set to 1 that are surrounded by voxels set to 0');
                    obj.View.handles.infoText.String = textString;
                case 'diag'
                    textString{1} = 'Uses diagonal fill to eliminate 8-connectivity of the background. For example:';
                    textString{2} = '1 0 0 0  ->  1 1 0 0';
                    textString{3} = '0 1 0 0  ->  1 1 1 0';
                    textString{4} = '0 0 1 0  ->  0 1 1 0';
                    textString{5} = '0 0 1 0  ->  1 0 1 0';
                    obj.View.handles.infoText.String = textString;
                case 'endpoints'
                    textString{1} = 'Finds end points of skeleton. For example:';
                    textString{2} = '1 0 0 0  ->  1 0 0 0';
                    textString{3} = '0 1 0 0  ->  0 0 0 0';
                    textString{4} = '0 0 1 0  ->  0 0 1 0';
                    textString{5} = '0 0 0 0  ->  1 0 0 0';
                    obj.View.handles.infoText.String = textString;
                case 'fill'
                    textString = sprintf('Fill isolated interior voxels, setting them to 1.\nIsolated interior voxels are individual voxels that are set to 0 that are surrounded (6-connected) by voxels set to 1');
                    obj.View.handles.infoText.String = textString;
                case 'majority'
                    textString = sprintf('Keep a voxel set to 1 if 14 or more voxels (the majority) in its 3-by-3-by-3, 26-connected neighborhood are set to 1; otherwise, set the voxel to 0');
                    obj.View.handles.infoText.String = textString;
                case 'remove'
                    textString = sprintf('Remove interior voxels, setting it to 0.\nInterior voxels are individual voxels that are set to 1 that are surrounded (6-connected) by voxels set to 1');
                    obj.View.handles.infoText.String = textString;
                case 'skel'
                    textString{1} = 'With Iterations = Inf, removes pixels on the boundaries of objects but does not allow objects to break apart.';
                    textString{2} = 'The pixels remaining make up the image skeleton. This option preserves the Euler number.';
                    obj.View.handles.infoText.String = textString;
                    if obj.View.handles.objects3D.Value == 0
                        obj.View.handles.removeBranchesCheck.Enable = 'on';
                    else
                        obj.View.handles.removeBranchesCheck.Enable = 'off';
                    end
                    
                    if obj.matlabVersion >= 9.4
                        obj.View.handles.limitToRadio.Enable = 'on';
                        obj.View.handles.limitToRadio.String = 'Min branch length:';
                        obj.View.handles.iterEdit.Enable = 'on';
                        obj.View.handles.infiniteRadio.Enable = 'off';
                        obj.View.handles.limitToRadio.Value = 1;
                    end
                    
                case 'spur'
                    textString{1} = 'Removes spur pixels. For example:';
                    textString{2} = '0 0 0 0  ->  0 0 0 0';
                    textString{3} = '0 0 1 0  ->  0 0 0 0';
                    textString{4} = '0 1 0 0  ->  0 1 0 0';
                    textString{5} = '1 1 0 0  ->  1 1 0 0';
                    obj.View.handles.infoText.String = textString;
                case 'thin'
                    textString{1} = 'With Iterations = Inf, thins objects to lines. It removes pixels so that an object without holes shrinks to a minimally connected stroke, and an object with holes shrinks to a connectedring halfway between each hole and the outer boundary.';
                    textString{2} = 'This option preserves the Euler number.';
                    obj.View.handles.infoText.String = textString;
            end
            if obj.View.handles.objects3D.Value == 1
                obj.type3d = selected;
            else
                obj.type = selected;
            end
        end
        
        function continueBtn_Callback(obj)
            % function continueBtn_Callback(obj)
            % callback for press of obj.View.handles.continueBtn

            if obj.View.handles.sliceRadio.Value == 1
                datasetSwitch = 0;
            else
                datasetSwitch = 1;
            end
            
            removeBranchesCheck = obj.View.handles.removeBranchesCheck.Value;   % whether or not remove branches during thinning
            
            if strcmp(obj.type, 'bwulterode')
                conn = obj.View.handles.auxPopup1.String;
                conn = str2double(conn{obj.View.handles.auxPopup1.Value});
                method = obj.View.handles.auxPopup2.String;
                method = method{obj.View.handles.auxPopup2.Value};
            else
                if obj.View.handles.limitToRadio.Value == 1
                    iterNo = str2double(obj.View.handles.iterEdit.String);
                else
                    iterNo = 'Inf';
                end
            end
            
            if obj.View.handles.objects3D.Value == 0
                wb = waitbar(0,sprintf('Performing: %s\nPlease wait...', obj.type), 'Name', 'Morph Ops', 'WindowStyle', 'modal');
            else
                wb = waitbar(0,sprintf('Performing: %s\nPlease wait...', obj.type3d), 'Name', 'Morph Ops', 'WindowStyle', 'modal');
            end
            if obj.mibModel.getImageProperty('time') == 1
                obj.mibModel.mibDoBackup('selection', datasetSwitch);
            end
            
            tic
            for t=1:obj.mibModel.getImageProperty('time')
                getDataOptions.roiId = [];
                getDataOptions.t = [t t];
                if strcmp(obj.type, 'bwulterode')
                    if obj.View.handles.radioBtn3D.Value     % 3D mode
                        selection = obj.mibModel.getData3D('selection', t, 4, NaN, getDataOptions);
                        for roiId=1:numel(selection)
                            selection{roiId} = bwulterode(selection{roiId}, method, conn);
                        end
                        obj.mibModel.setData3D('selection', selection, t, 4, NaN, getDataOptions);
                    elseif datasetSwitch                         % 2D mode, whole dataset
                        selection = obj.mibModel.getData3D('selection', t, 0, NaN, getDataOptions);
                        maxVal = numel(selection)*size(selection{1}, 3);
                        for roiId=1:numel(selection)
                            for layer = 1:size(selection{roiId}, 3)
                                if max(max(selection{roiId}(:,:,layer))) == 0; continue; end   % tweak to skip inversion, i.e. [0 0 0] -> [1 1 1] during normal use
                                selection{roiId}(:,:,layer) = bwulterode(selection{roiId}(:,:,layer), method, conn);
                                if mod(layer, 10)==0; waitbar(layer*roiId/maxVal, wb); end
                            end
                        end
                        obj.mibModel.setData3D('selection', selection, t, 0, NaN, getDataOptions);
                    else                                    % 2D mode, single slice
                        selection = obj.mibModel.getData2D('selection', NaN, NaN, NaN, getDataOptions);
                        for roiId=1:numel(selection)
                            if max(max(selection{roiId})) == 0; continue; end   % tweak to skip inversion, i.e. [0 0 0] -> [1 1 1] during normal use
                            selection{roiId} = bwulterode(selection{roiId}, method, conn);
                            waitbar(roiId/numel(selection), wb);
                        end
                        obj.mibModel.setData2D('selection', selection, NaN, NaN, NaN, getDataOptions);
                    end
                else    % branchpoints, diag, endpoints, skel, spur, thin & 3D objects operations
                    if datasetSwitch
                        selection = obj.mibModel.getData3D('selection', t, 0, NaN, getDataOptions);
                        maxVal = numel(selection)*size(selection{1}, 3);
                        for roiId=1:numel(selection)
                            if obj.View.handles.objects3D.Value == 0   % perform 2D operations
                                for layer = 1:size(selection{roiId}, 3)
                                    if strcmp(obj.type, 'skel') && obj.matlabVersion >= 9.4
                                        selection{roiId}(:,:,layer) = bwskel(logical(selection{roiId}(:,:,layer)), 'MinBranchLength', iterNo);
                                    else
                                        selection{roiId}(:,:,layer) = bwmorph(selection{roiId}(:,:,layer), obj.type, iterNo);
                                        %selection{roiId}(:,:,layer) = gather(bwmorph(gpuArray(logical(selection{roiId}(:,:,layer))),selected, iterNo));     % alternative version to use with GPU
                                    end
                                    if removeBranchesCheck == 1 && (strcmp(obj.type, 'thin') || strcmp(obj.type, 'skel'))
                                        selection{roiId}(:,:,layer) = mibRemoveBranches(selection{roiId}(:,:,layer));
                                    end
                                    if mod(layer, 10)==0; waitbar(layer*roiId/maxVal, wb); end
                                end
                            else % perform 3D operations, for R2018a and newer
                                if strcmp(obj.type3d, 'skel')
                                    selection{roiId} = bwskel(logical(selection{roiId}), 'MinBranchLength', iterNo);
                                else
                                    selection{roiId} = bwmorph3(selection{roiId}, obj.type3d);
                                end
                                waitbar(roiId/numel(selection), wb); 
                            end
                        end
                        obj.mibModel.setData3D('selection', selection, t, 0, NaN, getDataOptions);
                    else
                        selection = obj.mibModel.getData2D('selection', NaN, NaN, NaN, getDataOptions);
                        for roiId=1:numel(selection)
                            if strcmp(obj.type, 'skel') && obj.matlabVersion >= 9.4
                                selection{roiId} = bwskel(logical(selection{roiId}), 'MinBranchLength', iterNo);
                            else
                                selection{roiId} = bwmorph(selection{roiId}, obj.type, iterNo);
                            end
                            if removeBranchesCheck == 1 && (strcmp(obj.type, 'thin') || strcmp(obj.type, 'skel'))
                                selection{roiId} = mibRemoveBranches(selection{roiId});
                            end
                            waitbar(roiId/numel(selection), wb);
                        end
                        obj.mibModel.setData2D('selection', selection, NaN, NaN, NaN, getDataOptions);
                    end
                end
            end
            notify(obj.mibModel, 'plotImage');
            delete(wb);
            toc
        end
    end
end