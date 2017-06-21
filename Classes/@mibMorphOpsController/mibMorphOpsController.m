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
        type
        % type of action to perform
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
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            Font = obj.mibModel.preferences.Font;
            if obj.View.handles.infoText.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.infoText.FontName, Font.FontName)
                mibUpdateFontSize(obj.View.gui, Font);
            end
            obj.type = parameter;
            
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
            
            % highlight desired operation in the list
            list = obj.View.handles.morphOpsPopup.String;
            for i=1:numel(list)
                if strcmp(list{i}, obj.type)
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
            
            switch strtrim(selected)
                case 'branchpoints'
                    textString = sprintf('Find branch points of skeleton');
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
                case 'skel'
                    textString{1} = 'With Iterations = Inf, removes pixels on the boundaries of objects but does not allow objects to break apart.';
                    textString{2} = 'The pixels remaining make up the image skeleton. This option preserves the Euler number.';
                    obj.View.handles.infoText.String = textString;
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
            obj.type = selected;
        end
        
        function continueBtn_Callback(obj)
            % function continueBtn_Callback(obj)
            % callback for press of obj.View.handles.continueBtn

            if obj.View.handles.sliceRadio.Value == 1
                switch3d = 0;
            else
                switch3d = 1;
            end
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
            
            wb = waitbar(0,sprintf('Performing: %s\nPlease wait...', obj.type), 'Name', 'Morph Ops', 'WindowStyle', 'modal');
            if obj.mibModel.getImageProperty('time') == 1
                obj.mibModel.mibDoBackup('selection', switch3d);
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
                    elseif switch3d                         % 2D mode, whole dataset
                        selection = obj.mibModel.getData3D('selection', t, 0, NaN, getDataOptions);
                        maxVal = numel(selection)*size(selection{1}, 3);
                        for roiId=1:numel(selection)
                            for layer = 1:size(selection{roiId}, 3)
                                if max(max(selection{roiId}(:,:,layer))) == 0; continue; end;   % tweak to skip inversion, i.e. [0 0 0] -> [1 1 1] during normal use
                                selection{roiId}(:,:,layer) = bwulterode(selection{roiId}(:,:,layer), method, conn);
                                if mod(layer, 10)==0; waitbar(layer*roiId/maxVal, wb); end;
                            end
                        end
                        obj.mibModel.setData3D('selection', selection, t, 0, NaN, getDataOptions);
                    else                                    % 2D mode, single slice
                        selection = obj.mibModel.getData2D('selection', NaN, NaN, NaN, getDataOptions);
                        for roiId=1:numel(selection)
                            if max(max(selection{roiId})) == 0; continue; end;   % tweak to skip inversion, i.e. [0 0 0] -> [1 1 1] during normal use
                            selection{roiId} = bwulterode(selection{roiId}, method, conn);
                            waitbar(roiId/numel(selection), wb);
                        end
                        obj.mibModel.setData2D('selection', selection, NaN, NaN, NaN, getDataOptions);
                    end
                else    % branchpoints, diag, endpoints, skel, spur, thin
                    if switch3d
                        selection = obj.mibModel.getData3D('selection', t, 0, NaN, getDataOptions);
                        maxVal = numel(selection)*size(selection{1}, 3);
                        for roiId=1:numel(selection)
                            for layer = 1:size(selection{roiId}, 3)
                                selection{roiId}(:,:,layer) = bwmorph(selection{roiId}(:,:,layer), obj.type, iterNo);
                                %selection{roiId}(:,:,layer) = gather(bwmorph(gpuArray(logical(selection{roiId}(:,:,layer))),selected, iterNo));     % alternative version to use with GPU
                                if mod(layer, 10)==0; waitbar(layer*roiId/maxVal, wb); end;
                            end
                        end
                        obj.mibModel.setData3D('selection', selection, t, 0, NaN, getDataOptions);
                    else
                        selection = obj.mibModel.getData2D('selection', NaN, NaN, NaN, getDataOptions);
                        for roiId=1:numel(selection)
                            selection{roiId} = bwmorph(selection{roiId}, obj.type, iterNo);
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