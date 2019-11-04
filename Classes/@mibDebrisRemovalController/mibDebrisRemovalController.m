classdef mibDebrisRemovalController < handle
    % @type mibDebrisRemovalController class is a template class for using with
    % GUI developed using appdesigner of Matlab
    %
    % @code
    % obj.startController('mibDebrisRemovalController'); // as GUI tool
    % @endcode
    % or 
    % @code 
    % // a code below was used for mibImageArithmeticController
    % BatchOpt.Parameter = 'test';  // fill edit boxes as strings
    % BatchOpt.Checkbox = true;     // fill checkboxes with logicals: true/false
    % BatchOpt.Dropdown = {'value'};        // value for the popups as a cell
    % BatchOpt.Radio = {'Radio1'};          // selection of radio buttons, as cell with the handle of the target radio button
    % BatchOpt.showWaitbar = true;  // show or not the waitbar
    % obj.startController('mibDebrisRemovalController', [], BatchOpt); // start mibDebrisRemovalController in the batch mode
    % @endcode
    % or
    % @code
    % // trigger return of the possible Options using returnBatchOpt function
    % // using notify syncBatch event
    % obj.startController('mibDebrisRemovalController', [], NaN);
    % @endcode
    
    % Copyright (C) 17.09.2019, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
        % handles to mibModel
        View
        % handle to the view / DebrisRemovalGUI
        listener
        % a cell array with handles to listeners
        BatchOpt
        % a structure compatible with batch operation
        % name of each field should be displayed in a tooltip of GUI
        % it is recommended that the Tags of widgets match the name of the
        % fields in this structure
        % .Parameter - a string for the edit box
        % .Checkbox - a logical for the check box
        % .Dropdown - a cell string for the dropdown
        % .Radio - cell string 'Radio1' or 'Radio2'... the color channel for thresholding
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback(obj, src, evnt)
            switch evnt.EventName
                case {'updateGuiWidgets'}
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibDebrisRemovalController(mibModel, varargin)
            obj.mibModel = mibModel;    % assign model
            
            %% fill the BatchOpt structure with default values
            % fields of the structure should correspond to the starting
            % text in the each widget tooltip.
            % For example, this demo template has an edit box, where the
            % tooltip starts with "Parameter:...". Text Parameter
            % indicates field of the BatchOpt structure that defines value
            % for this widget
            obj.BatchOpt.DetectionMode{1} = 'AutomaticDetection';
            obj.BatchOpt.DetectionMode{2} = {'AutomaticDetection', 'MaskedAreas', 'SelectedAreas'};
            obj.BatchOpt.Intensitythreshold{1} = 100;
            obj.BatchOpt.Intensitythreshold{2} = [0 Inf];   % limits
            obj.BatchOpt.Intensitythreshold{3} = 'on';      % round the value
            obj.BatchOpt.ObjectSizeTheshold{1} = 1000;
            obj.BatchOpt.ObjectSizeTheshold{2} = [0, Inf];
            obj.BatchOpt.ObjectSizeTheshold{3} = 'on';
            obj.BatchOpt.StrelSize{1} = 7;
            obj.BatchOpt.StrelSize{2} = [1, Inf];
            obj.BatchOpt.StrelSize{3} = 'on';
            obj.BatchOpt.HighlightAs = {'mask'};
            obj.BatchOpt.HighlightAs{2} = {'mask', 'selection'};
            
            obj.BatchOpt.showWaitbar = true;
            obj.BatchOpt.id = obj.mibModel.Id;  % optional
            
            %% part below is only valid for use of the plugin from MIB batch controller
            % comment it if intended use not from the batch mode
            obj.BatchOpt.mibBatchSectionName = 'Menu -> Image';    % section name for the Batch
            obj.BatchOpt.mibBatchActionName = 'Tools for Images -> Debris removal';           % name of the plugin
            
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.Intensitythreshold = sprintf('Intensity threshold for detection of debris in the difference of images');
            obj.BatchOpt.mibBatchTooltip.ObjectSizeTheshold = sprintf('Detected objects larger than this value are considered as debris and removed');
            obj.BatchOpt.mibBatchTooltip.StrelSize = sprintf('Size of the strel element for morphological operations');
            obj.BatchOpt.mibBatchTooltip.HighlightAs = sprintf('Highlight removed debris as mask or selection layer');
            obj.BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not waitbar');

            %% add here a code for the batch mode, for example
            % when the BatchOpt stucture is provided the controller will
            % use it as the parameters, and performs the function in the
            % headless mode without GUI
            if nargin == 3
                BatchOptIn = varargin{2};
                if isstruct(BatchOptIn) == 0 
                    if isnan(BatchOptIn)     % when varargin{2} == NaN return possible settings
                        obj.returnBatchOpt();   % obtain Batch parameters
                    else
                        errordlg(sprintf('A structure as the 3rd parameter is required!')); 
                    end
                    notify(obj, 'closeEvent'); 
                    return
                end
                % add/update BatchOpt with the provided fields in BatchOptIn
                % combine fields from input and default structures
                obj.BatchOpt = updateBatchOptCombineFields_Shared(obj.BatchOpt, BatchOptIn);
                
                obj.Calculate();
                notify(obj, 'closeEvent');
                return;
            end
            
            guiName = 'mibDebrisRemovalGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % init the widgets
            %destBuffers = arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false);
            %obj.View.handles.Popup.String = destBuffers;
            
			% move the window to the left hand side of the main window
            obj.View.gui = moveWindowOutside(obj.View.gui, 'left');
            
            % resize all elements of the GUI
            % mibRescaleWidgets(obj.View.gui); % this function is not yet
            % compatible with appdesigner
            
            % update font and size
            % you may need to replace "obj.View.handles.text1" with tag of any text field of your own GUI
            % % this function is not yet
%             global Font;
%             if ~isempty(Font)
%               if obj.View.handles.text1.FontSize ~= Font.FontSize ...
%                     || ~strcmp(obj.View.handles.text1.FontName, Font.FontName)
%                   mibUpdateFontSize(obj.View.gui, Font);
%               end
%             end
            
			obj.updateWidgets();
			obj.View.Figure.Figure.Visible = 'on';
			% obj.View.gui.WindowStyle = 'modal';     % make window modal
			
			% add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing mibDebrisRemovalController window
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
            
            % updateWidgets normally triggered during change of MIB
            % buffers, make sure that any widgets related changes are
            % correctly propagated into the BatchOpt structure
            if isfield(obj.BatchOpt, 'id'); obj.BatchOpt.id = obj.mibModel.Id; end
            
            % update widgets from the BatchOpt structure
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);
        end
        
        function updateBatchOptFromGUI(obj, event)
            % function updateBatchOptFromGUI(obj, event)
            %
            % update obj.BatchOpt from widgets of GUI
            % use an external function (Tools\updateBatchOptFromGUI_Shared.m) that is common for all tools
            % compatible with the Batch mode
            %
            % Parameters:
            % event: event from the callback
            
            obj.BatchOpt = updateBatchOptFromGUI_Shared(obj.BatchOpt, event.Source);
        end
        
        function Help_Callback(obj)
            % function Help_Callback(obj)
            %
            % show the help page

            global mibPath;
            web(fullfile(mibPath, 'techdoc', 'html', 'ug_gui_menu_image.html'), '-helpbrowser');
        end
        
        function returnBatchOpt(obj, BatchOptOut)
            % return structure with Batch Options and possible configurations
            % via the notify 'syncBatch' event
            % Parameters:
            % BatchOptOut: a local structure with Batch Options generated
            % during Continue callback. It may contain more fields than
            % obj.BatchOpt structure
            % 
            if nargin < 2; BatchOptOut = obj.BatchOpt; end
            
            if isfield(BatchOptOut, 'id'); BatchOptOut = rmfield(BatchOptOut, 'id'); end  % remove id field
            % trigger syncBatch event to send BatchOptOut to mibBatchController 
            eventdata = ToggleEventData(BatchOptOut);
            notify(obj.mibModel, 'syncBatch', eventdata);
        end
        
        
        % ------------------------------------------------------------------
        % % Additional functions and callbacks
        function Calculate(obj, mode)
            % start main calculation of the plugin
            %
            % Parameters:
            % mode: an optional string with mode
            % ''Current'' -> remove debris from the current slice
            % ''Remove all'' -> remove debris for the whole dataset
            if nargin < 2; mode = 'Remove all'; end
            if obj.BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'Debris removal'); end
            
            % check for the virtual stacking mode and close the controller if the plugin is not compatible with the virtual stacking mode
            if isprop(obj.mibModel.I{obj.BatchOpt.id}, 'Virtual') && obj.mibModel.I{obj.BatchOpt.id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                notify(obj.mibModel, 'stopProtocol'); % notify to stop execusion of the protocol
                obj.closeWindow();
                return;
            end
            
            currentMode = 0;
            if strcmp(mode, 'Current')
                currentMode = 1;
            end
            
            getDataOptions.id = obj.BatchOpt.id;
            if currentMode
                obj.mibModel.mibDoBackup('image', 0, getDataOptions);
            else
                obj.mibModel.mibDoBackup('image', 1, getDataOptions);
            end
            [height, width, colors, depth, time] = obj.mibModel.I{obj.BatchOpt.id}.getDatasetDimensions('image');
            
            %if strcmp(obj.BatchOpt.HighlightAs{1}, 'mask')
            %    obj.mibModel.I{obj.BatchOpt.id}.clearMask();
            %else
            %    obj.mibModel.I{obj.BatchOpt.id}.clearSelection();
            %end
            if currentMode
                z1 = obj.mibModel.I{obj.BatchOpt.id}.getCurrentSliceNumber();
                z2 = z1;
                if z1 < 2 || z2 > depth-1
                    errordlg(sprintf('!!! Error !!!\nThe current slice should be between 2 and %d', depth-1), 'Wrong slice');
                    if obj.BatchOpt.showWaitbar; delete(wb); end
                    return;
                end
            else
                z1 = 2;
                z2 = depth-1;
            end
            
            index = 1;
            noFixedObjects = 0;
            if strcmp(obj.BatchOpt.DetectionMode{1}, 'MaskedAreas')
                maskLayer = 'mask';
            else
                maskLayer = 'selection';
            end
            
            for z=z1:z2
                if obj.BatchOpt.showWaitbar; waitbar(z/depth, wb); end
                if strcmp(obj.BatchOpt.DetectionMode{1}, 'AutomaticDetection')
                    % get image
                    if index > 2
                        I1 = I2;
                        I2 = I3;
                        Iprev = Icurr;
                        Icurr = Inext;

                        Inext = cell2mat(obj.mibModel.getData2D('image', z+1, NaN, NaN, getDataOptions));     % ype, slice_no, orient, col_channel, options
                        I3 = Inext + imbothat(Inext, strel('disk', obj.BatchOpt.StrelSize{1}, 0));
                    else
                        Iprev = cell2mat(obj.mibModel.getData2D('image', z-1, NaN, NaN, getDataOptions));
                        Icurr = cell2mat(obj.mibModel.getData2D('image', z, NaN, NaN, getDataOptions));
                        Inext = cell2mat(obj.mibModel.getData2D('image', z+1, NaN, NaN, getDataOptions));

                        I1 = Iprev + imbothat(Iprev, strel('disk', obj.BatchOpt.StrelSize{1}, 0));
                        I2 = Icurr + imbothat(Icurr, strel('disk', obj.BatchOpt.StrelSize{1}, 0));
                        I3 = Inext + imbothat(Inext, strel('disk', obj.BatchOpt.StrelSize{1}, 0));
                    end

                    % get difference
                    dI1 = I1-I2;
                    dI2 = I3-I2;
                    dI = dI1+dI2;

                    S = zeros(size(dI), 'uint8');
                    S(dI > obj.BatchOpt.Intensitythreshold{1}) = 1;
                    CC = bwconncomp(S, 8);
                    STATS = regionprops(CC, {'Area','PixelIdxList'});
                    if numel(STATS) == 0; continue; end

                    for objId = 1:numel(STATS)
                        if STATS(objId).Area < obj.BatchOpt.ObjectSizeTheshold{1}
                            S(STATS(objId).PixelIdxList) = 0;
                        end
                    end
                    S = imdilate(S, strel('disk', 5, 0));
                    S = imfill(S);
                    S = imerode(S, strel('disk', 3, 0));
                    obj.mibModel.setData2D(obj.BatchOpt.HighlightAs{1}, S, z, NaN, NaN, getDataOptions);
                else    % use existing mask
                    % get image
                    if index > 2
                        Iprev = Icurr;
                        Icurr = Inext;
                        Inext = cell2mat(obj.mibModel.getData2D('image', z+1, NaN, NaN, getDataOptions));     % ype, slice_no, orient, col_channel, options
                    else
                        Iprev = cell2mat(obj.mibModel.getData2D('image', z-1, NaN, NaN, getDataOptions));
                        Icurr = cell2mat(obj.mibModel.getData2D('image', z, NaN, NaN, getDataOptions));
                        Inext = cell2mat(obj.mibModel.getData2D('image', z+1, NaN, NaN, getDataOptions));
                    end
                    S = cell2mat(obj.mibModel.getData2D(maskLayer, z, NaN, NaN, getDataOptions));
                end
                
                Iout = Icurr;
                Ipatch = Iprev/2+Inext/2;
                %Ipatch = Iprev+Inext;
                Iout(S==1) = Ipatch(S==1);
                obj.mibModel.setData2D('image', Iout, z, NaN, NaN, getDataOptions);
                
                index = index + 1;
            end
            if obj.BatchOpt.showWaitbar; delete(wb); end
            
            % redraw the image if needed
            notify(obj.mibModel, 'showMask');
            notify(obj.mibModel, 'plotImage');
            
            if currentMode == 0
                if strcmp(obj.BatchOpt.DetectionMode{1}, 'AutomaticDetection')
                    obj.mibModel.I{obj.BatchOpt.id}.updateImgInfo(sprintf('Debris removal: threshold: %d, size limit: %d, strel: %d', ...
                        obj.BatchOpt.Intensitythreshold{1}, obj.BatchOpt.ObjectSizeTheshold{1}, obj.BatchOpt.StrelSize{1}));
                else
                    obj.mibModel.I{obj.BatchOpt.id}.updateImgInfo(sprintf('Debris removal using %s', obj.BatchOpt.DetectionMode{1}));
                end
                % for batch need to generate an event and send the BatchOptLoc
                % structure with it to the macro recorder / mibBatchController
                obj.returnBatchOpt();
            end
        end
        
        
    end
end