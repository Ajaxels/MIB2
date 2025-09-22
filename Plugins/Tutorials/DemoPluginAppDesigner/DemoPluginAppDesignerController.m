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
% Date: 19.08.2025

classdef DemoPluginAppDesignerController < handle
    % @type DemoPluginAppDesignerController class is a template class for using with
    % GUI developed using appdesigner of Matlab
    %
    % @code
    % obj.startController('DemoPluginAppDesignerController'); // as GUI tool
    % @endcode
    % or 
    % @code 
    % // a code below was used for mibImageArithmeticController
    % BatchOpt.Parameter = 'test';  // fill edit boxes as strings
    % BatchOpt.Checkbox = true;     // fill checkboxes with logicals: true/false
    % BatchOpt.Popup = {'value'};        // value for the popups as a cell
    % BatchOpt.Radio = {'Radio1'};          // selection of radio buttons, as cell with the handle of the target radio button
    % BatchOpt.showWaitbar = true;  // show or not the waitbar
    % obj.startController('DemoPluginAppDesignerController', [], BatchOpt); // start DemoPluginAppDesignerController in the batch mode
    % @endcode
    % or
    % @code
    % // trigger return of the possible Options using returnBatchOpt function
    % // using notify syncBatch event
    % obj.startController('DemoPluginAppDesignerController', [], NaN);
    % @endcode
    
	% Updates
	%     
    
    % THIS PLUGIN IS AVAILABLE IN MIB under
	% MIB\Development\mibPluginGUI_ver3_appDesigner
    
    properties
        mibModel
        % handles to mibModel
        View
        % handle to the view / DemoPluginAppDesignerGUI
        listener
        % a cell array with handles to listeners
        BatchOpt
        % a structure compatible with batch operation
        % name of each field should be displayed in a tooltip of GUI
        % it is recommended that the Tags of widgets match the name of the
        % fields in this structure
        % .Parameter - [editbox], char/string 
        % .Checkbox - [checkbox], logical value true or false
        % .Dropdown{1} - [dropdown],  cell string for the dropdown
        % .Dropdown{2} - [optional], an array with possible options
        % .RadioButtonGroup{1} - selected Radio button
        % .RadioButtonGroup{2} - available radio buttons
        % .ParameterNumeric{1} - [numeric editbox], cell with a number 
        % .ParameterNumeric{2} - [optional], vector with limits [min, max]
        % .ParameterNumeric{3} - [optional], string 'on' - to round the value, 'off' to do not round the value
        % see constructor for details
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
        function obj = DemoPluginAppDesignerController(mibModel, varargin)
            obj.mibModel = mibModel;    % assign model
            
            %% fill the BatchOpt structure with default values
            % fields of the structure should correspond to the starting
            % text in the each widget tooltip.
            % For example, this demo template has an edit box, where the
            % tooltip starts with "Parameter:...". Text Parameter
            % indicates field of the BatchOpt structure that defines value
            % for this widget
            obj.BatchOpt.Parameter = 'my parameter';    % edit box
            obj.BatchOpt.Checkbox = true;   % checkbox
            obj.BatchOpt.Dropdown = {'Option 3'}; % dropdown menu
            obj.BatchOpt.Dropdown{2} = {'Option 1', 'Option 2', 'Option 3'}; % options for the dropdown menu
            obj.BatchOpt.RadioButtonGroup{1} = 'Radio2';    % selected radio button
            obj.BatchOpt.RadioButtonGroup{2} = {'Radio1', 'Radio2', 'Radio3'}; % list of available radio buttons
            obj.BatchOpt.ParameterNumeric{1} = 512.125;     % numeric value  for numeric edit or spinner box
            obj.BatchOpt.ParameterNumeric{2} = [0 1024];    % possible limits value
            obj.BatchOpt.ParameterNumeric{3} = 'off';    % round the numeric value
            obj.BatchOpt.showWaitbar = true;    % show or not the waitbar
            obj.BatchOpt.id = obj.mibModel.Id;  % optional
            
            %% part below is only valid for use of the plugin from MIB batch controller
            % comment it if intended use not from the batch mode
            obj.BatchOpt.mibBatchSectionName = 'Menu -> Plugins';    % section name for the Batch
            obj.BatchOpt.mibBatchActionName = 'Demo Plugin App Designer';           % name of the plugin
            
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.Parameter = sprintf('Provide text or number as string');
            obj.BatchOpt.mibBatchTooltip.Checkbox = sprintf('Specify checkboxes as logicals');
            obj.BatchOpt.mibBatchTooltip.Popup = sprintf('Popups populated using cells');
            obj.BatchOpt.mibBatchTooltip.Radio = sprintf('Selection of radio buttons, as cell with the handle of the target radio button');
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
            
            guiName = 'DemoPluginAppDesigner';
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
%             global Font;
%             if ~isempty(Font)
%               if obj.View.handles.text1.FontSize ~= Font.FontSize+4 ...   
%                     || ~strcmp(obj.View.handles.text1.FontName,
%                     Font.FontName) % font size for appdesigner +4 larger than that for guide 
%                   mibUpdateFontSize(obj.View.gui, Font);
%               end
%             end
            
			obj.updateWidgets();
			% update widgets from the BatchOpt structure
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);
            
			% obj.View.gui.WindowStyle = 'modal';     % make window modal
			
			% add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing DemoPluginAppDesignerController window
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
            
            % when elements GIU needs to be updated, update obj.BatchOpt
            % structure and after that update elements of GUI by the
            % following function
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);    %
            
            
            fprintf('childController:updateWidgets: %g\n', toc);
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
        function Calculate(obj)
            % start main calculation of the plugin
            if obj.BatchOpt.showWaitbar
                % wb = waitbar(0, 'Please wait...', 'Name', 'My plugin'); 
                pwb = PoolWaitbar(1, sprintf('Starting calculations\nPlease wait...'), [], ...
                    'My plugin', ...
                    obj.View.gui); 
                pwb.updateMaxNumberOfIterations(3);     % update number of max iterations for the waitbar
            end
            
            % check for the virtual stacking mode and close the controller if the plugin is not compatible with the virtual stacking mode
            if isprop(obj.mibModel.I{obj.BatchOpt.id}, 'Virtual') && obj.mibModel.I{obj.BatchOpt.id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                notify(obj.mibModel, 'stopProtocol'); % notify to stop execusion of the protocol
                obj.closeWindow();
                return;
            end
            
            text{1} = sprintf('Parameter: %s', obj.BatchOpt.Parameter);
            text{2} = sprintf('Checkbox: %d', obj.BatchOpt.Checkbox);
            text{3} = sprintf('Dropdown: %s', obj.BatchOpt.Dropdown{1});
            text{4} = sprintf('Radio: %s', obj.BatchOpt.Radio{1});
            text{5} = sprintf('Parameter num: %f', obj.BatchOpt.ParameterNumeric{1});
            % example of an error dialog
            try
                obj.View.handles.TextArea.Value = text;
            catch err
                mibShowErrorDialog(obj.View.gui, err, 'Error');
                if obj.BatchOpt.showWaitbar; delete(pwb); end
            end
            
            if obj.BatchOpt.showWaitbar
                if pwb.getCancelState(); delete(pwb); return; end % check for cancel
                pwb.updateText(sprintf('Updating text\nPlease wait...'));
                increment(pwb);
            end

            fprintf('calculateBtn_Callback: Calculate button was pressed\n');
            if obj.BatchOpt.showWaitbar
                %delete(wb); 
                delete(pwb); 
            end
            
            % redraw the image if needed
            notify(obj.mibModel, 'plotImage');
            
            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            obj.returnBatchOpt();
        end
        
        
    end
end