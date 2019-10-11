classdef mibPluginController < handle
    % classdef mibPluginController < handle
    % This a template class for making GUI windows for MIB
    % it is the second version that was designed to be compatible with
    % future macro editor
    %
    % @code
    % obj.startController('mibPluginController'); // as GUI tool
    % @endcode
    % or 
    % @code 
    % // a code below was used for mibImageArithmeticController
    % BatchOpt.showWaitbar = 1;   // show or not the waitbar
    % BatchOpt.InputA = 'Container 1';  // index of the container that will be mapped to A variable
    % BatchOpt.DestinationClass = 'uint16';     // image class for results
    % BatchOpt.DestinationContainer = 'Container 3';        // destination container
    % BatchOpt.Expression = {'A = A*2'};          // expression to evaluate
    % obj.startController('mibPluginController', [], BatchOpt); // start mibPluginController in the batch mode
    % @endcode
    % or
    % @code
    % // trigger return of the possible Options using returnBatchOpt function
    % // using notify syncBatch event
    % obj.startController('mibPluginController', [], NaN);
    % @endcode
    
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        BatchOpt
        % a structure compatible with batch operation
        % name of each field should be displayed in a tooltip of GUI
        % it is recommended that the Tags of widgets match the name of the
        % fields in this structure
        % .showWaitbar - logical, true - show, false - do not show the waitbar
        % .Parameter - a string for the edit box
        % .Checkbox - a logical for the check box
        % .Popup - a cell string for the popup
        % .ColorChannel - cell string 'Ch 1' or 'Ch 2'... the color channel for thresholding
        % @li .Orientation, 1-zx, 2-zy, 4-yx of the dataset
        % @li .z -> [@em optional], [zmin, zmax] coordinates of the dataset to take after transpose, depth
        % @li .t -> [@em optional], [tmin, tmax] coordinates of the dataset to take after transpose, time
        % @li .y -> [@em optional], [ymin, ymax] coordinates of the dataset to take after transpose for level=1, height
        % @li .x -> [@em optional], [xmin, xmax] coordinates of the dataset to take after transpose for level=1, width
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
%         function ViewListner_Callback(obj, src, evnt)
%             switch src.Name
%                 case {'Id', 'newDatasetSwitch'}     % added in mibChildView
%                     obj.updateWidgets();
%                     %                 case 'slices'     % replaced with
%                     %                 'changeSlice', 'changeTime' events because slice is changed too often
%                     %                     if obj.listener{3}.Enabled
%                     %                         disp(toc)
%                     %                         obj.updateHist();
%                     %                     end
%             end
%         end
        
        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case {'updateGuiWidgets'}
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibPluginController(mibModel, varargin)
            obj.mibModel = mibModel;    % assign model
            
            % fill the BatchOpt structure with default values
            % fields of the structure should correspond to the starting
            % text in the each widget tooltip.
            % For example, this demo template has an edit box, where the
            % tooltip starts with "Parameter:...". Text Parameter
            % indicates field of the BatchOpt structure that defines value
            % for this widget
            obj.BatchOpt.showWaitbar = true;   % show or not the waitbar
            %obj.BatchOpt.ColorChannel = {'Ch 1'};    % color channel for thresholding
            %obj.BatchOpt.Orientation = 4;   % yx
            obj.BatchOpt.Parameter = 'my parameter';
            obj.BatchOpt.Checkbox = true;
            obj.BatchOpt.Popup = {'Container 1'};
            obj.BatchOpt.Radio1 = false;
            obj.BatchOpt.Radio2 = true;

            % check for the virtual stacking mode and close the controller if the plugin is not compatible with the virtual stacking mode
            if isprop(obj.mibModel.I{obj.mibModel.Id}, 'Virtual') && obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                obj.closeWindow();
                return;
            end
            
            % add here a code for the batch mode, for example
            % when the BatchOpt stucture is provided the controller will
            % use it as the parameters, and performs the function in the
            % headless mode without GUI
            
            if nargin == 3
                BatchOptInput = varargin{2};
                if isstruct(BatchOptInput) == 0 
                    if isnan(BatchOptInput)     % when varargin{2} == NaN return possible settings
                        obj.returnBatchOpt();   % obtain Batch parameters
                    else
                        errordlg(sprintf('A structure as the 4th parameter is required!')); 
                    end
                    notify(obj, 'closeEvent'); 
                    return
                end
                BatchOptInputFields = fieldnames(BatchOptInput);
                for i=1:numel(BatchOptInputFields)
                    obj.BatchOpt.(BatchOptInputFields{i}) = BatchOptInput.(BatchOptInputFields{i}); 
                end
                
                obj.calculateBtn_Callback();
                notify(obj, 'closeEvent');
                return;
            end
            
            guiName = 'mibPluginGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % init the widgets
            destBuffers = arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false);
            obj.View.handles.Popup.String = destBuffers;
            
			% move the window to the left hand side of the main window
            obj.View.gui = moveWindowOutside(obj.View.gui, 'left');
            
            % resize all elements of the GUI
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            % you may need to replace "obj.View.handles.text1" with tag of any text field of your own GUI
            global Font;
            if ~isempty(Font)
              if obj.View.handles.text1.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.text1.FontName, Font.FontName)
                  mibUpdateFontSize(obj.View.gui, Font);
              end
            end
            
			obj.updateWidgets();
			
			% obj.View.gui.WindowStyle = 'modal';     % make window modal
			
			% add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
             
            % option 2: in some situations
            % obj.listener{1} = addlistener(obj.mibModel, 'Id', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
            % obj.listener{2} = addlistener(obj.mibModel, 'newDatasetSwitch', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
        end
        
        function closeWindow(obj)
            % closing mibPluginController window
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
            
            fprintf('childController:updateWidgets: %g\n', toc);
        end
        
        function updateBatchOptFromGUI(obj, hObject)
            % function updateBatchOptFromGUI(obj, hObject)
            %
            % update obj.BatchOpt from widgets of GUI
            % use an external function (Tools\updateBatchOptFromGUI_Shared.m) that is common for all tools
            % compatible with the Batch mode
            %
            % Parameters:
            % hObject: a handle to a widget of GUI
            
            obj.BatchOpt = updateBatchOptFromGUI_Shared(obj.BatchOpt, hObject);
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
            
            % generate cell array of containers names for popup menus
            destBuffers = arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false);
            BatchOptOut.Popup{2} = destBuffers;
            
            % add position of the Plugin in the Menu Plugins
            BatchOptOut.mibBatchSectionName = 'Menu -> Tools';
            BatchOptOut.mibBatchActionName = 'My plugins --> My batch plugin';
            
            % trigger syncBatch event to send BatchOptOut to mibBatchController 
            eventdata = ToggleEventData(BatchOptOut);
            notify(obj.mibModel, 'syncBatch', eventdata);
        end
        
        
        % ------------------------------------------------------------------
        % % Additional functions and callbacks
        function calculateBtn_Callback(obj)
            % start main calculation of the plugin
            if obj.BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'My plugin'); end
            
            BatchOptLoc = obj.BatchOpt;
             
            fprintf('calculateBtn_Callback: Calculate button was pressed\n');
            
            if obj.BatchOpt.showWaitbar; delete(wb); end
            
            % redraw the image if needed
            notify(obj.mibModel, 'plotImage');
            
            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            obj.returnBatchOpt(BatchOptLoc);
            
        end
        
        
    end
end