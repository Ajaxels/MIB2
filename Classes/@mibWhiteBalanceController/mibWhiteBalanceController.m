% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

classdef mibWhiteBalanceController < handle
    % @type mibWhiteBalanceController class is a template class for using with
    % GUI developed using appdesigner of Matlab
    %
    % @code
    % obj.startController('mibWhiteBalanceController'); // as GUI tool
    % @endcode
    % or 
    % @code 
    % // a code below was used for mibImageArithmeticController
    % BatchOpt.Parameter = 'test';  // fill edit boxes as strings
    % BatchOpt.Checkbox = true;     // fill checkboxes with logicals: true/false
    % BatchOpt.Dropdown = {'value'};        // value for the popups as a cell
    % BatchOpt.Radio = {'Radio1'};          // selection of radio buttons, as cell with the handle of the target radio button
    % BatchOpt.showWaitbar = true;  // show or not the waitbar
    % obj.startController('mibWhiteBalanceController', [], BatchOpt); // start mibWhiteBalanceController in the batch mode
    % @endcode
    % or
    % @code
    % // trigger return of the possible Options using returnBatchOpt function
    % // using notify syncBatch event
    % obj.startController('mibWhiteBalanceController', [], NaN);
    % @endcode
    
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
        function obj = mibWhiteBalanceController(mibModel, varargin)
            obj.mibModel = mibModel;    % assign model
            
            %% fill the BatchOpt structure with default values
            % fields of the structure should correspond to the starting
            % text in the each widget tooltip.
            % For example, this demo template has an edit box, where the
            % tooltip starts with "Parameter:...". Text Parameter
            % indicates field of the BatchOpt structure that defines value
            % for this widget
            obj.BatchOpt.PickedRegion{1} = 'SelectedAreas';
            obj.BatchOpt.PickedRegion{2} = {'SelectedAreas', 'MaskedAreas', 'ManualValue'};
            obj.BatchOpt.ManualWhiteColor = '128 128 128';
            obj.BatchOpt.ColorSpace = {'sRGB'};
            obj.BatchOpt.ColorSpace{2} = {'sRGB', 'Adobe-RGB-1998', 'linear-RGB'};
            obj.BatchOpt.ChromaticAdaptationMethod = {'bradford'};
            obj.BatchOpt.ChromaticAdaptationMethod{2} = {'bradford', 'vonkries', 'simple'};
            obj.BatchOpt.showWaitbar = true;
            obj.BatchOpt.id = obj.mibModel.Id;  % optional
            
            %% part below is only valid for use of the plugin from MIB batch controller
            % comment it if intended use not from the batch mode
            obj.BatchOpt.mibBatchSectionName = 'Menu -> Image';    % section name for the Batch
            obj.BatchOpt.mibBatchActionName = 'Tools for Images -> White balance correction';           % name of the plugin
            
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.PickedRegion = 'Layers containing areas that should be white or gray';
            obj.BatchOpt.mibBatchTooltip.ManualWhiteColor = 'Provide 3 values that describe intensity in an area that should be white or gray';
            obj.BatchOpt.mibBatchTooltip.ColorSpace = sprintf('Color space of the image');
            obj.BatchOpt.mibBatchTooltip.ChromaticAdaptationMethod = sprintf('Chromatic adaptation method used to scale the RGB values');
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
                
                obj.correctWhiteBalance();
                notify(obj, 'closeEvent');
                return;
            end
            
            guiName = 'mibWhiteBalanceGUI';
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
            global Font;
            if ~isempty(Font)
              if obj.View.handles.ManualWhiteColor.FontSize ~= Font.FontSize + 4 ...    % guide font size is 4 points smaller than in appdesigner
                    || ~strcmp(obj.View.handles.ManualWhiteColor.FontName, Font.FontName)
                  mibUpdateFontSize(obj.View.gui, Font);
              end
            end
            
			obj.updateWidgets();
			obj.View.Figure.Figure.Visible = 'on';
			% obj.View.gui.WindowStyle = 'modal';     % make window modal
			
			% add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing mibWhiteBalanceController window
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
            web(fullfile(mibPath, 'techdoc/html/user-interface/menu/image/image-tools-whitebalance.html'), '-browser');
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
        function correctWhiteBalance(obj, mode)
            % start white balance correction procedure
            %
            % Parameters:
            % mode: an optional string with mode
            % ''Correct current'' -> correct white balance for the currently shown image
            % ''Correct all'' -> correct white balance for all images of the dataset
            
            if nargin < 2; mode = 'Correct all'; end
            
            [height, width, colors, depth, time] = obj.mibModel.I{obj.BatchOpt.id}.getDatasetDimensions('image');
            if numel(colors) ~= 3
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nWhite balance correction is only available for 3 color-channel RGB images!'), ...
                    'Wrong number of color channels');
                return;
            end
            
            manualWhiteColors = str2num(obj.BatchOpt.ManualWhiteColor); %#ok<ST2NM> 
            if numel(manualWhiteColors) ~= 3 && strcmp(obj.BatchOpt.PickedRegion{1}, ManualValue)
               uialert(app.Figure, ...
                   sprintf('!!! Error !!!\n\nPlease provide 3 values that describe intensity in an area that should be white or gray!'), ...
                   'Wrong value!');
               return;
            end
            
            if obj.BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'White balance correction'); end
            
            % check for the virtual stacking mode and close the controller if the plugin is not compatible with the virtual stacking mode
            if isprop(obj.mibModel.I{obj.BatchOpt.id}, 'Virtual') && obj.mibModel.I{obj.BatchOpt.id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                notify(obj.mibModel, 'stopProtocol'); % notify to stop execusion of the protocol
                obj.closeWindow();
                return;
            end
            
            currentMode = 0;
            if strcmp(mode, 'Correct current')
                currentMode = 1;
            end
            
            getDataOptions.id = obj.BatchOpt.id;
            % do backup
            if currentMode
                obj.mibModel.mibDoBackup('image', 0, getDataOptions);
            else
                obj.mibModel.mibDoBackup('image', 1, getDataOptions);
            end
            
            if currentMode
                z1 = obj.mibModel.I{obj.BatchOpt.id}.getCurrentSliceNumber();
                z2 = z1;
            else
                z1 = 1;
                z2 = depth;
            end
            
            index = 1;
            if strcmp(obj.BatchOpt.PickedRegion{1}, 'MaskedAreas')
                maskLayer = 'mask';
            else
                maskLayer = 'selection';
            end
            
            detectedWhiteColors = [];
            for z=z1:z2
                if obj.BatchOpt.showWaitbar; waitbar(z/depth, wb); end
                
                I = cell2mat(obj.mibModel.getData2D('image', z, NaN, NaN, getDataOptions));     % ype, slice_no, orient, col_channel, options
                if strcmp(obj.BatchOpt.PickedRegion{1}, 'ManualValue')
                    I = chromadapt(I, manualWhiteColors, ...
                        'ColorSpace', obj.BatchOpt.ColorSpace{1}, 'Method', obj.BatchOpt.ChromaticAdaptationMethod{1});
                else
                    M = cell2mat(obj.mibModel.getData2D(maskLayer, z, NaN, NaN, getDataOptions));
                    
                    % if mask/selection is present use it to get white
                    % point, otherwise use the previously obtained value
                    if sum(M(:)) > 0
                        detectedWhiteColors = zeros([3,1]);
                        for colCh=1:numel(colors)
                            chI = I(:,:,colCh);
                            detectedWhiteColors(colCh) = mean(chI(M==1));
                        end
                    elseif isempty(detectedWhiteColors)
                        continue;
                    end
                    I = chromadapt(I, detectedWhiteColors, ...
                        'ColorSpace', obj.BatchOpt.ColorSpace{1}, 'Method', obj.BatchOpt.ChromaticAdaptationMethod{1});
                end
                obj.mibModel.setData2D('image', I, z, NaN, NaN, getDataOptions);
            end
            if obj.BatchOpt.showWaitbar; delete(wb); end
            
            % redraw the image if needed
            notify(obj.mibModel, 'showMask');
            notify(obj.mibModel, 'plotImage');
            
            if currentMode == 0
                if strcmp(obj.BatchOpt.PickedRegion{1}, 'ManualValue')
                    obj.mibModel.I{obj.BatchOpt.id}.updateImgInfo(sprintf('WB correction: %d %d %d, %s, %s', manualWhiteColors(1), manualWhiteColors(2),manualWhiteColors(3), obj.BatchOpt.ColorSpace{1}, obj.BatchOpt.ChromaticAdaptationMethod{1}));
                else
                    obj.mibModel.I{obj.BatchOpt.id}.updateImgInfo(sprintf('WB correction using %s layer, %s, %s', maskLayer, obj.BatchOpt.ColorSpace{1}, obj.BatchOpt.ChromaticAdaptationMethod{1}));
                end
                % for batch need to generate an event and send the BatchOptLoc
                % structure with it to the macro recorder / mibBatchController
                obj.returnBatchOpt();
            end
        end
    end
end