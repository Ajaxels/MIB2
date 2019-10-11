classdef mibImageArithmeticController < handle
    % classdef mibImageArithmeticController < handle
    % This class drives image arithmetic tools of MIB
    % using these tools it is possible to do custom arithmetic operations
    % with one or several open datasets
    % It is available from MIB->Menu->Image->Tools for Images->Image arithmetic
    % This tool can be started from mibController as
    %
    % @code
    % obj.startController('mibImageArithmeticController'); // as GUI tool
    % @endcode
    % or 
    % @code
    % BatchOpt.showWaitbar = true;   // show or not the waitbar
    % BatchOpt.Expression = 'A = A*2';          // expression to evaluate
    % obj.startController('mibImageArithmeticController', [], BatchOpt); // start mibImageArithmeticController in the headless mode
    % @endcode
    % or
    % @code
    % // trigger return of the possible Options using returnBatchOpt function
    % // using notify syncBatch event
    % obj.startController('mibImageArithmeticController', [], NaN);
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
        % .showWaitbar - a logical, 1 - show, 0 - do not show the waitbar, [default = 1] 
        % .Expression - a string with an expression to evaluate, [default = 'A = A*2']
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
        function obj = mibImageArithmeticController(mibModel, varargin)
            obj.mibModel = mibModel;    % assign model
            
            % fill the BatchOpt structure with default values
            % fields of the structure should correspond to the starting
            % text in the each widget tooltip.
            % For example, this widget has an edit box, where the
            % tooltip starts with "Expression:...". Text Expression
            % indicates field of the BatchOpt structure that defines value
            % for this widget
            obj.BatchOpt.InputVariables = 'I';
            obj.BatchOpt.OutputVariables = 'I';
            obj.BatchOpt.Expression = 'I = I*1.5';
            obj.BatchOpt.showWaitbar = true;   % show or not the waitbar
            
            % add section name and action name for the batch tool
            obj.BatchOpt.mibBatchSectionName = 'Menu -> Image';
            obj.BatchOpt.mibBatchActionName = 'Tools for Images -> Image Arithmetics';
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.InputVariables = 'A list with input variables: I-image; O-model; M-mask; S-selection; I2-obtain image from container 2, M3-mask from container 3; S-selection from the current container';
            obj.BatchOpt.mibBatchTooltip.OutputVariables = 'An output variable: I-image; O-model; M-mask; S-selection; I2-set image to container 2, M3-mask to container 3; S-selection to the current container';
            obj.BatchOpt.mibBatchTooltip.Expression = sprintf('String with an arithmetic expression to execute, see help of the tool for details');
            obj.BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

            % check for the virtual stacking mode and close the controller if the plugin is not compatible with the virtual stacking mode
            if isprop(obj.mibModel.I{obj.mibModel.Id}, 'Virtual') && obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nImage Arithmetic is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                obj.closeWindow();
                notify(obj.mibModel, 'stopProtocol');
                return;
            end
            
            % add here a code for the batch mode, for example
            % when the BatchOpt stucture is provided the controller will
            % use it as the parameters, and performs the function in the
            % headless mode without GUI
            if nargin == 3
                BatchOptInput = varargin{2};
                if isstruct(BatchOptInput) == 0 
                    if isnan(BatchOptInput)
                        obj.returnBatchOpt();   % obtain Batch parameters
                    else
                        errordlg(sprintf('A structure as the 4th parameter is required!')); 
                    end
                    return;
                end
                
                % add/update BatchOpt with the provided fields in BatchOptIn
                % combine fields from input and default structures
                obj.BatchOpt = updateBatchOptCombineFields_Shared(obj.BatchOpt, BatchOptInput);
                
                obj.runExpressionBtn_Callback();
                return;
            end
            
            guiName = 'mibImageArithmeticGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % move the window to the left hand side of the main window
            obj.View.gui = moveWindowOutside(obj.View.gui, 'left');
            
            obj.View.handles.InputVariables.String = obj.BatchOpt.InputVariables;
            obj.View.handles.OutputVariables.String = obj.BatchOpt.OutputVariables;
            obj.View.handles.prevExpPopup.String = cellfun(@(x) strrep(x,sprintf('\n'),''), obj.mibModel.preferences.imagearithmetic.actions, 'UniformOutput', false); %#ok<SPRINTFN>
            obj.View.handles.Expression.String = obj.BatchOpt.Expression;
            
            % resize all elements of the GUI
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            % you may need to replace "obj.View.handles.text1" with tag of any text field of your own GUI
            global Font;
            if ~isempty(Font)
                if obj.View.handles.infoText.FontSize ~= Font.FontSize ...
                        || ~strcmp(obj.View.handles.infoText.FontName, Font.FontName)
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
            % closing mibImageArithmeticController window
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
        
        function returnBatchOpt(obj, BatchOptOut)
            % return structure with Batch Options and possible configurations
            % Parameters:
            % BatchOptOut: a local structure with Batch Options generated
            % during Continue callback. It may contain more fields than
            % obj.BatchOpt structure
            
            if nargin < 2; BatchOptOut = obj.BatchOpt; end
            
            % trigger syncBatch event to send BatchOptOut to mibBatchController 
            eventdata = ToggleEventData(BatchOptOut);
            notify(obj.mibModel, 'syncBatch', eventdata);
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
        
        function updateWidgets(obj)
            % function updateWidgets(obj)
            % update widgets of this window
            
        end
        
        function prevExpPopup_Callback(obj)
            selectedExpression = obj.mibModel.preferences.imagearithmetic.actions{obj.View.handles.prevExpPopup.Value};
            obj.BatchOpt.Expression = selectedExpression;
            obj.View.handles.Expression.String = selectedExpression;
            obj.View.handles.InputVariables.String = obj.mibModel.preferences.imagearithmetic.inputvars{obj.View.handles.prevExpPopup.Value};
            obj.BatchOpt.InputVariables = obj.View.handles.InputVariables.String;
            obj.View.handles.OutputVariables.String = obj.mibModel.preferences.imagearithmetic.outputvars{obj.View.handles.prevExpPopup.Value};
            obj.BatchOpt.OutputVariables = obj.View.handles.OutputVariables.String;
        end
        
        % ------------------------------------------------------------------
        % % Additional functions and callbacks
        function runExpressionBtn_Callback(obj)
            % start arithmetics
            
            if obj.BatchOpt.showWaitbar; wb = waitbar(0, sprintf('Performing:\n%s\nPlease wait...', obj.BatchOpt.Expression), 'Name', 'Image arithmetics'); end
            logText = 'Arithmetics:';
            if obj.BatchOpt.showWaitbar; waitbar(0.05, wb); end
            
            % obtain datasets
            obtainedDatasets = {};
            getDataOptions.blockModeSwitch = 0;
            for chId =1:numel(obj.BatchOpt.InputVariables)
                switch obj.BatchOpt.InputVariables(chId)
                    case 'I'    % image
                        inputType = 'image';
                    case 'O'    % model
                        inputType = 'model';
                    case 'M'    % mask
                        inputType = 'mask';
                    case 'S'    % selection
                        inputType = 'selection';
                    otherwise
                        continue;
                end
                datasetInputString = obj.BatchOpt.InputVariables(chId);
                % obtain id of the dataset
                getDataOptions.id = obj.mibModel.Id;
                if chId < numel(obj.BatchOpt.InputVariables)
                    if ~isnan(str2double(obj.BatchOpt.InputVariables(chId+1)))
                        getDataOptions.id = str2double(obj.BatchOpt.InputVariables(chId+1));
                        datasetInputString = [datasetInputString num2str(getDataOptions.id)]; %#ok<AGROW>
                    end
                end
                if ismember(datasetInputString, obtainedDatasets); continue; end
                obtainedDatasets = [obtainedDatasets; {datasetInputString}]; %#ok<AGROW>
                
                execString = sprintf('%s = cell2mat(obj.mibModel.getData4D(''%s'', 4, NaN, getDataOptions));', datasetInputString, inputType);
                
                try
                    eval(execString);
                catch err
                    if obj.BatchOpt.showWaitbar; delete(wb); end
                    notify(obj.mibModel, 'stopProtocol');
                    errordlg(sprintf('Error in obj.mibModel.getData4D with the input string: %s and input type: %s!\n\nIdentifier: %s\nMessage: %s', datasetInputString, inputType, err.identifier, err.message), 'Wrong parameters');
                end
            end
            if obj.BatchOpt.showWaitbar; waitbar(0.2, wb); end
            
            % find output variable
            obj.BatchOpt.OutputVariables = strtrim(obj.BatchOpt.OutputVariables);
            switch obj.BatchOpt.OutputVariables(1)
                case 'I'
                    outputType = 'image';
                case 'O'
                    outputType = 'model';
                case 'M'
                    outputType = 'mask';
                case 'S'
                    outputType = 'selection';
                otherwise
                    errordlg(sprintf('!!! Error !!!\n\nWrong expression:\n%s', obj.BatchOpt.Expression));
                    notify(obj.mibModel, 'stopProtocol');
                    return;
            end
            setDataOptions.id = obj.mibModel.Id;
            setDataOptions.blockModeSwitch = 0;
            datasetOutputString = obj.BatchOpt.OutputVariables(1);
            if numel(obj.BatchOpt.OutputVariables) > 1
                if ~isnan(str2double(obj.BatchOpt.OutputVariables(2)))
                    setDataOptions.id = str2double(obj.BatchOpt.OutputVariables(2)); %#ok<STRNU>
                    datasetOutputString = [datasetOutputString obj.BatchOpt.OutputVariables(2)];
                end
            end
            if obj.BatchOpt.showWaitbar; waitbar(0.25, wb); end
            
            % evaluate expression
            try
                expressionText = sprintf('%s;', obj.BatchOpt.Expression);
                eval(expressionText);
            catch err
                if obj.BatchOpt.showWaitbar; delete(wb); end
                notify(obj.mibModel, 'stopProtocol');
                errordlg(sprintf('!!! Error !!!\n\nWrong expression!\n%s\nPlease try again!', err.message), 'Error');
                return;
            end
            if obj.BatchOpt.showWaitbar; waitbar(0.9, wb); end
            
            obj.mibModel.mibDoBackup(outputType, 1, setDataOptions);
            
            switch outputType
                case 'image'
                    if setDataOptions.id == obj.mibModel.Id
                        setDataOptions.replaceDatasetSwitch = 1;    % force to replace dataset
                        % when dimensions mismatch reinitialize the model
                        execString = sprintf('sum([size(%s,1) size(%s,2) size(%s,4) size(%s,5)] == [size(obj.mibModel.I{setDataOptions.id}.model{1},1) size(obj.mibModel.I{setDataOptions.id}.model{1},2) size(obj.mibModel.I{setDataOptions.id}.model{1},3) size(obj.mibModel.I{setDataOptions.id}.model{1},4)]) ~= 4', ...
                            datasetOutputString, datasetOutputString, datasetOutputString, datasetOutputString);
                        if eval(execString)     % when size of existing and new dataset mismatch reinit the model
                            setDataOptions.keepModel = 0;
                        end
                        execString = sprintf('obj.mibModel.setData4D(''%s'', %s, 4, NaN, setDataOptions);', outputType, datasetOutputString);
                        try
                            eval(execString);
                        catch err
                            errordlg(sprintf('Error in obj.mibModel.setData4D with %s!\n\nIdentifier: %s\nMessage: %s', outputType, err.identifier, err.message), 'Wrong parameters');
                            notify(obj.mibModel, 'stopProtocol');
                            if obj.BatchOpt.showWaitbar; delete(wb); end
                            return;
                        end
                        notify(obj.mibModel, 'updateId');
                    else
                        meta = containers.Map(keys(obj.mibModel.I{getDataOptions.id}.meta), values(obj.mibModel.I{getDataOptions.id}.meta));
                        try    
                            execStr = sprintf('meta(''imgClass'') =  class(%s);', datasetOutputString); eval(execStr);
                            meta('MaxInt') =  double(intmax(meta('imgClass'))); %#ok<NASGU>
                        
                            execStr = sprintf('meta(''Height'') = size(%s,1);', datasetOutputString); eval(execStr);
                            execStr = sprintf('meta(''Width'') = size(%s,2);', datasetOutputString); eval(execStr);
                            execStr = sprintf('meta(''Colors'') = size(%s,3);', datasetOutputString); eval(execStr);
                            execStr = sprintf('meta(''Depth'') = size(%s,4);', datasetOutputString); eval(execStr);
                            execStr = sprintf('meta(''Time'') = size(%s,5);', datasetOutputString); eval(execStr);
                            execStr = sprintf('obj.mibModel.I{setDataOptions.id} = mibImage(%s, meta);', datasetOutputString); eval(execStr);
                        catch err
                            errordlg(sprintf('Error in obj.mibModel.setData4D with %s!\n\nIdentifier: %s\nMessage: %s', outputType, err.identifier, err.message), 'Wrong parameters');
                            notify(obj.mibModel, 'stopProtocol');
                            if obj.BatchOpt.showWaitbar; delete(wb); end
                            return;
                        end
                        eventdata = ToggleEventData(setDataOptions.id);
                        notify(obj.mibModel, 'newDataset', eventdata);
                    end
                case 'model'
                    execString = sprintf('obj.mibModel.setData4D(''%s'', %s, 4, NaN, setDataOptions);', outputType, datasetOutputString);
                    try 
                        eval(execString);
                    catch err
                        errordlg(sprintf('Error in obj.mibModel.setData4D with %s!\n\nIdentifier: %s\nMessage: %s', outputType, err.identifier, err.message), 'Wrong parameters');
                        notify(obj.mibModel, 'stopProtocol');
                        if obj.BatchOpt.showWaitbar; delete(wb); end
                        return;
                    end
                    
                    obj.mibModel.I{setDataOptions.id}.modelMaterialNames = obj.mibModel.I{getDataOptions.id}.modelMaterialNames;
                    obj.mibModel.I{setDataOptions.id}.modelMaterialColors = obj.mibModel.I{getDataOptions.id}.modelMaterialColors;
                    notify(obj.mibModel, 'updateId');
                otherwise
                    execString = sprintf('obj.mibModel.setData4D(''%s'', %s, 4, NaN, setDataOptions);', outputType, datasetOutputString);
                    try 
                        eval(execString);
                    catch err
                        errordlg(sprintf('Error in obj.mibModel.setData4D with %s!\n\nIdentifier: %s\nMessage: %s', outputType, err.identifier, err.message), 'Wrong parameters');
                        notify(obj.mibModel, 'stopProtocol');
                        if obj.BatchOpt.showWaitbar; delete(wb); end
                        return;
                    end
                    notify(obj.mibModel, 'updateId');
                    
            end
            
            if obj.BatchOpt.showWaitbar; waitbar(0.95, wb); end
            
            logText = sprintf('%s: %s;', logText, obj.BatchOpt.Expression);
            obj.mibModel.I{setDataOptions.id}.updateImgInfo(logText);
            
            % store the expression and update prevExpPopup
            if ~ismember(obj.BatchOpt.Expression, obj.mibModel.preferences.imagearithmetic.actions)
                obj.mibModel.preferences.imagearithmetic.actions(end+1) = {obj.BatchOpt.Expression};
                obj.mibModel.preferences.imagearithmetic.outputvars(end+1) = {obj.BatchOpt.OutputVariables};
                obj.mibModel.preferences.imagearithmetic.inputvars(end+1) = {obj.BatchOpt.InputVariables};
                if numel(obj.mibModel.preferences.imagearithmetic.actions) > obj.mibModel.preferences.imagearithmetic.no_stored_actions
                    obj.mibModel.preferences.imagearithmetic.actions = obj.mibModel.preferences.imagearithmetic.actions(2:end);
                    obj.mibModel.preferences.imagearithmetic.outputvars = obj.mibModel.preferences.imagearithmetic.outputvars(2:end);
                    obj.mibModel.preferences.imagearithmetic.inputvars = obj.mibModel.preferences.imagearithmetic.inputvars(2:end);
                end
                obj.View.handles.prevExpPopup.String = cellfun(@(x) strrep(x,sprintf('\n'),''), obj.mibModel.preferences.imagearithmetic.actions, 'UniformOutput', false); %#ok<SPRINTFN>
                obj.View.handles.prevExpPopup.Value = numel(obj.mibModel.preferences.imagearithmetic.actions);
            end
            
            if obj.BatchOpt.showWaitbar; waitbar(1, wb); delete(wb); end
            notify(obj.mibModel, 'plotImage');
            
            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            obj.returnBatchOpt(obj.BatchOpt);

            
        end
    end
end