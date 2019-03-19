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
    % BatchOpt.InputA = {'Container 3'};  // index of the container that will be mapped to A variable
    % BatchOpt.ImageClass = {'uint16'};     // image class for results
    % BatchOpt.Destination = {'Container 3'};        // destination container
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
        % .InputA - a cell string, with the container that will be mapped to A variable, [default=1]
        % .InputB - a cell string, with the container that will be mapped to B variable, [default=1]
        % .InputC - a cell string, with the container that will be mapped to C variable, [default=1]
        % .ImageClass - a cell string, image class for results, [default = 'uint8']
        % .Destination - a cell string, destination container, [default=1]
        % .ConvertVia32 - a logical, use uint32 class for conversion or not, [default=1]
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
            obj.BatchOpt.showWaitbar = true;   % show or not the waitbar
            obj.BatchOpt.InputA = {'Container 1'};
            obj.BatchOpt.InputB = {'Container 1'};
            obj.BatchOpt.InputC = {'Container 1'};
            obj.BatchOpt.Destination = {'Container 1'};
            obj.BatchOpt.ImageClass = {'uint8'};
            obj.BatchOpt.ConvertVia32 = true;
            obj.BatchOpt.Expression = 'A = A*2';
            
            % check for the virtual stacking mode and close the controller if the plugin is not compatible with the virtual stacking mode
            if isprop(obj.mibModel.I{obj.mibModel.Id}, 'Virtual') && obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nImage Arithmetic is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
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
                    if isnan(BatchOptInput)
                        obj.returnBatchOpt();   % obtain Batch parameters
                    else
                        errordlg(sprintf('A structure as the 4th parameter is required!')); 
                    end
                    return;
                end
                BatchOptInputFields = fieldnames(BatchOptInput);
                for i=1:numel(BatchOptInputFields)
                    obj.BatchOpt.(BatchOptInputFields{i}) = BatchOptInput.(BatchOptInputFields{i}); 
                end
                
                obj.runExpressionBtn_Callback();
                return;
            end
            
            guiName = 'mibImageArithmeticGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % move the window to the left hand side of the main window
            obj.View.gui = moveWindowOutside(obj.View.gui, 'left');
            
            % generate cell array of containers names
            destBuffers = arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false);
            
            obj.BatchOpt.InputA = destBuffers(obj.mibModel.Id);
            obj.BatchOpt.Destination = destBuffers(obj.mibModel.Id);
            obj.View.handles.InputA.String = destBuffers;
            obj.View.handles.InputB.String = destBuffers;
            obj.View.handles.InputC.String = destBuffers;
            obj.View.handles.Destination.String = destBuffers;
            obj.View.handles.InputA.Value = find(ismember(destBuffers,obj.BatchOpt.InputA)==1);
            obj.View.handles.InputB.Value = find(ismember(destBuffers,obj.BatchOpt.InputB)==1);
            obj.View.handles.InputC.Value = find(ismember(destBuffers,obj.BatchOpt.InputC)==1);
            obj.View.handles.Destination.Value = find(ismember(destBuffers,obj.BatchOpt.Destination)==1);
            obj.View.handles.prevExpPopup.String = cellfun(@(x) strrep(x,sprintf('\n'),''), obj.mibModel.preferences.imagearithmetic.actions, 'UniformOutput', false); %#ok<SPRINTFN>
            
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
            
            classIndex = find(ismember({'uint8', 'uint16', 'uint32'}, obj.mibModel.I{obj.mibModel.Id}.meta('imgClass')) == 1);
            obj.View.handles.ImageClass.Value = classIndex;
            obj.BatchOpt.ImageClass = obj.View.handles.ImageClass.String(classIndex);
            
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
            % 
            
            if nargin < 2; BatchOptOut = obj.BatchOpt; end
            
            % generate cell array of containers names
            destBuffers = arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false);
            
            % add second field to popupmenus with all possible options
            BatchOptOut.InputA{2} = destBuffers;
            BatchOptOut.InputB{2} = destBuffers;
            BatchOptOut.InputC{2} = destBuffers;
            BatchOptOut.Destination{2} = destBuffers;
            BatchOptOut.ImageClass{2} = [{'uint8'},{'uint16'},{'uint32'}];
            
            % add position of the Plugin in the Menu Plugins
            BatchOptOut.mibBatchSectionName = 'Menu Image';
            BatchOptOut.mibBatchActionName = 'Tools for Images -> Image Arithmetics';
            
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
        
        % ------------------------------------------------------------------
        % % Additional functions and callbacks
        function runExpressionBtn_Callback(obj)
            % start main calculation of the plugin
            BatchOptLoc = obj.BatchOpt;
            
            if obj.BatchOpt.showWaitbar; wb = waitbar(0, sprintf('Performing:\n%s\nPlease wait...', BatchOptLoc.Expression), 'Name', 'Image arithmetics'); end
            logText = 'Arithmetics:';
            
            % generate cell array of containers names
            destBuffers = arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false);
            % obtain indices of the containers
            inputA_id = find(ismember(destBuffers,obj.BatchOpt.InputA)==1);
            inputB_id = find(ismember(destBuffers,obj.BatchOpt.InputB)==1);
            inputC_id = find(ismember(destBuffers,obj.BatchOpt.InputC)==1);
            dest_id = find(ismember(destBuffers,obj.BatchOpt.Destination)==1);
            
            % get A
            getDataOptions.blockModeSwitch = 0;
            getDataOptions.id = inputA_id;
            A = cell2mat(obj.mibModel.getData4D('image', 4, 0, getDataOptions));
            % convert class if needed
            if BatchOptLoc.ConvertVia32
                A = uint32(A);
            else
                if ~strcmp(class(A), BatchOptLoc.ImageClass)
                    switch BatchOptLoc.ImageClass
                        case 'uint8'
                            A = uint8(A);
                        case 'uint16'
                            A = uint16(A);
                        case 'unit32'
                            A = uint32(A);
                    end
                    logText = sprintf('%s ->%s;', logText, BatchOptLoc.ImageClass{1});
                end
            end
            if obj.BatchOpt.showWaitbar; waitbar(0.1, wb); end
            
            % get B if needed
            if strfind(BatchOptLoc.Expression, 'B')  %#ok<STRIFCND>
                getDataOptions.id = inputB_id;
                B = cell2mat(obj.mibModel.getData4D('image', 4, 0, getDataOptions));
                % convert class if needed
                if BatchOptLoc.ConvertVia32
                    B = uint32(B); %#ok<NASGU>
                else
                    if ~strcmp(class(B), BatchOptLoc.ImageClass)
                        switch BatchOptLoc.ImageClass{1}
                            case 'uint8'
                                B = uint8(B); %#ok<NASGU>
                            case 'uint16'
                                B = uint16(B); %#ok<NASGU>
                            case 'unit32'
                                B = uint32(B); %#ok<NASGU>
                        end
                    end
                end
                if obj.BatchOpt.showWaitbar; waitbar(0.2, wb); end
            end
            
            % get C if needed
            if strfind(BatchOptLoc.Expression, 'C')   %#ok<STRIFCND>
                getDataOptions.id = inputC_id;
                C = cell2mat(obj.mibModel.getData4D('image', 4, 0, getDataOptions));
                % convert class if needed
                if BatchOptLoc.ConvertVia32
                    C = uint32(C); %#ok<NASGU>
                else
                    if ~strcmp(class(C),  BatchOptLoc.ImageClass)
                        switch  BatchOptLoc.ImageClass{1}
                            case 'uint8'
                                C = uint8(C); %#ok<NASGU>
                            case 'uint16'
                                C = uint16(C); %#ok<NASGU>
                            case 'unit32'
                                C = uint32(C); %#ok<NASGU>
                        end
                    end
                end
                if obj.BatchOpt.showWaitbar; waitbar(0.3, wb); end
            end
            
            try
                expressionText = sprintf('%s;', BatchOptLoc.Expression);
                eval(expressionText);
            catch err
                if obj.BatchOpt.showWaitbar; delete(wb); end
                errordlg(sprintf('!!! Error !!!\n\nWrong expression!\n%s\nPlease try again!', err.message), 'Error');
            end
            
            if BatchOptLoc.showWaitbar; waitbar(0.8, wb); end
            logText = sprintf('%s: %s;', logText, BatchOptLoc.Expression);
            
            % convert to the destination class
            if BatchOptLoc.ConvertVia32
                switch BatchOptLoc.ImageClass{1}
                    case 'uint8'
                        A = uint8(A);
                    case 'uint16'
                        A = uint16(A);
                    case 'unit32'
                        A = uint32(A);
                end
                logText = sprintf('%s ->%s;', logText, BatchOptLoc.ImageClass{1});
            end
            
            if dest_id == obj.mibModel.Id && dest_id == inputA_id
                obj.mibModel.mibDoBackup('image', 1);
                getDataOptions.replaceDatasetSwitch = 1;    % force to replace dataset
                % when dimensions mismatch reinitialize the model
                if sum([size(A,1) size(A,2) size(A,4) size(A,5)] == size(obj.mibModel.I{obj.mibModel.Id}.model{1})) ~= 4
                    getDataOptions.keepModel = 0;
                end
                getDataOptions.id = dest_id;
                obj.mibModel.setData4D('image', A, 4, 0, getDataOptions);
                obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(logText);
                notify(obj.mibModel, 'updateId');
            else
                meta = containers.Map(keys(obj.mibModel.I{inputA_id}.meta), values(obj.mibModel.I{inputA_id}.meta));
                meta('imgClass') =  BatchOptLoc.ImageClass{1};
                meta('MaxInt') =  double(intmax(BatchOptLoc.ImageClass{1}));
                meta('Height') = size(A,1);
                meta('Width') = size(A,2);
                meta('Colors') = size(A,3);
                meta('Depth') = size(A,4);
                meta('Time') = size(A,5);
                obj.mibModel.I{dest_id} = mibImage(A, meta);
                
                eventdata = ToggleEventData(dest_id);
                notify(obj.mibModel, 'newDataset', eventdata);
                obj.mibModel.I{dest_id}.updateImgInfo(logText);
            end
            
            if BatchOptLoc.showWaitbar; waitbar(1, wb); end
            
            % store the expression and update prevExpPopup
            if ~ismember(BatchOptLoc.Expression, obj.mibModel.preferences.imagearithmetic.actions)
                obj.mibModel.preferences.imagearithmetic.actions(end+1) = {BatchOptLoc.Expression};
                if numel(obj.mibModel.preferences.imagearithmetic.actions) > obj.mibModel.preferences.imagearithmetic.no_stored_actions
                    obj.mibModel.preferences.imagearithmetic.actions = obj.mibModel.preferences.imagearithmetic.actions(2:end);
                end
                obj.View.handles.prevExpPopup.String = cellfun(@(x) strrep(x,sprintf('\n'),''), obj.mibModel.preferences.imagearithmetic.actions, 'UniformOutput', false); %#ok<SPRINTFN>
                obj.View.handles.prevExpPopup.Value = numel(obj.mibModel.preferences.imagearithmetic.actions);
            end
            
            if BatchOptLoc.showWaitbar; delete(wb); end
            notify(obj.mibModel, 'plotImage');
            
            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            obj.returnBatchOpt(BatchOptLoc);
            
        end
    end
end