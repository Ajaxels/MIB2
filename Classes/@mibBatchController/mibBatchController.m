classdef mibBatchController < handle
    % classdef mibBatchController < handle
    % This a template class for making GUI windows for MIB
    % it is the second version that was designed to be compatible with
    % future macro editor
    %
    % @code
    % obj.startController('mibBatchController'); // as GUI tool
    % @endcode
    
    
    properties
        mibController
        % handle to mibController
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        CurrentBatch
        % a structure with selected Batch options, returned by returnBatchOpt function of the controller
        jSelectedActionTable
        % a handle to java class for the selectedActionTable
        jSelectedActionTableScroll
        % a handle to java class for the selectedActionTable scroll
        Protocol
        % a structure with picked actions that should be executed
        ProtocolBackups
        % a cell array with backuped protocols
        ProtocolBackupsCurrNumber
        % current number of the protocol history
        ProtocolBackupsMaxNumber
        % maximal number of protocol history for backup
        Sections
        % a strutcure with available Sections and corresponding actions
        % Sections(id).Name -> name of available section (i.e. 'Menu File', 'Menu Dataset')
        % Sections(id).Actions(id2).Name -> name of an action available for the selected section (i.e. 'Tools for Images -> Image Arithmetics', 'Semi-automatic segmentation --> Global thresholding')
        % Sections(id).Actions(id2).Parameters -> a structure with parameters for the action
        selectedActionTableIndex
        % index of a row selected in the selectedActionTable
        protocolListIndex
        % index of a row selected in the protocolList
        selectedSection
        % index of the selected section, i.e. id for obj.Sections(id) updated by obj.View.handles.sectionPopup
        selectedAction
        % index of the selected action for the currect section, i.e. id2 for Sections(id).Actions(id2) updated by obj.View.handles.actionPopup
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
                case 'syncBatch'
                    obj.selectedActionTableIndex = 1;
                    obj.updateWidgets();
                    obj.updateSelectedActionTable(evnt.Parameter);  % update the selected action table
                    %obj.displaySelectedActionTableItems();
            end
        end
    end
    
    methods
        % declaration of functions in the external files, keep empty line in between for the doc generator
        updateWidgets(obj)  % update widgets of the GUI
        
        function obj = mibBatchController(mibModel, varargin)
            obj.mibModel = mibModel;    % assign model
            obj.mibController = varargin{1};    % obtain mibController
            % check for the virtual stacking mode and close the controller if the plugin is not compatible with the virtual stacking mode
            if isprop(obj.mibModel.I{obj.mibModel.Id}, 'Virtual') && obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                obj.closeWindow();
                return;
            end
            
            obj.Protocol = [];
            obj.ProtocolBackups = {};
            
            % generate Actions structure
            secIndex = 1;
            obj.Sections(secIndex).Name = 'Menu Dataset';
            obj.Sections(secIndex).Actions(1).Name = 'Crop dataset';
            obj.Sections(secIndex).Actions(1).Command = 'obj.mibController.startController(''mibCropController'', [], Batch);';
            obj.Sections(secIndex).Actions(2).Name = 'Resample...';
            obj.Sections(secIndex).Actions(2).Command = 'obj.mibController.startController(''mibResampleController'', [], Batch);';
            obj.Sections(secIndex).Actions(3).Name = 'Transform...';
            obj.Sections(secIndex).Actions(3).Command = 'obj.mibController.menuDatasetTrasform_Callback([], Batch);';
            obj.Sections(secIndex).Actions(4).Name = 'Transform... --> Add frame (width/height)';
            obj.Sections(secIndex).Actions(4).Command = 'obj.mibController.menuDatasetTrasform_Callback(''Add frame (width/height)'', Batch);';
            obj.Sections(secIndex).Actions(5).Name = 'Transform... --> Add frame (dX/dY)';
            obj.Sections(secIndex).Actions(5).Command = 'obj.mibController.menuDatasetTrasform_Callback(''Add frame (dX/dY)'', Batch);';
            obj.Sections(secIndex).Actions(6).Name = 'Parameters';
            obj.Sections(secIndex).Actions(6).Command = 'obj.mibController.menuDatasetParameters_Callback([], Batch);';
            secIndex = secIndex + 1;
            obj.Sections(secIndex).Name = 'Menu Image';
            obj.Sections(secIndex).Actions(1).Name = 'Mode';
            obj.Sections(secIndex).Actions(1).Command = 'obj.mibController.menuImageMode_Callback([], Batch)';
            obj.Sections(secIndex).Actions(2).Name = 'Tools for Images -> Image Arithmetics';
            obj.Sections(secIndex).Actions(2).Command = 'obj.mibController.startController(''mibImageArithmeticController'', [], Batch)';
            secIndex = secIndex + 1;
            obj.Sections(secIndex).Name = 'Menu Tools';
            obj.Sections(secIndex).Actions(1).Name = 'Semi-automatic segmentation --> Global thresholding';
            obj.Sections(secIndex).Actions(1).Command = 'obj.mibController.startController(''mibHistThresController'', [], Batch)';
            secIndex = secIndex + 1;
            obj.Sections(secIndex).Name = 'Service steps';
            obj.Sections(secIndex).Actions(1).Name = 'STOP EXECUTION';
            obj.Sections(secIndex).Actions(1).Command = [];
            
            % init default selections
            obj.selectedSection = 1;
            obj.selectedAction = 1;
            obj.protocolListIndex = 0;
            obj.selectedActionTableIndex = 0;
            obj.ProtocolBackupsCurrNumber = 0;
            obj.ProtocolBackupsMaxNumber = 10;
            
            guiName = 'mibBatchGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % move the window to the left hand side of the main window
            obj.View.gui = moveWindowOutside(obj.View.gui, 'left');
            
            % resize all elements of the GUI
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            % you may need to replace "obj.View.handles.text1" with tag of any text field of your own GUI
            global Font;
            if ~isempty(Font)
                if obj.View.handles.sectionNameText.FontSize ~= Font.FontSize ...
                        || ~strcmp(obj.View.handles.sectionNameText.FontName, Font.FontName)
                    mibUpdateFontSize(obj.View.gui, Font);
                end
            end
            
            % update GUI widgets
            obj.View.handles.sectionPopup.String = {obj.Sections.Name}';
            
            % find java object for the segmentation table
            obj.jSelectedActionTableScroll = findjobj(obj.View.handles.selectedActionTable);
            obj.jSelectedActionTable = obj.jSelectedActionTableScroll.getViewport.getComponent(0);
            obj.jSelectedActionTable.setAutoResizeMode(obj.jSelectedActionTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
            
            obj.updateWidgets();
            
            % add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen for update of widgets
            obj.listener{2} = addlistener(obj.mibModel, 'syncBatch', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen for return of the batch structure
            
            % option 2: in some situations
            % obj.listener{1} = addlistener(obj.mibModel, 'Id', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
            % obj.listener{2} = addlistener(obj.mibModel, 'newDatasetSwitch', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
        end
        
        
        
        function closeWindow(obj)
            % closing mibBatchController window
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
        
        % ------------------------------------------------------------------
        % % Additional functions and callbacks
        function selectAction_Callback(obj, hObject)
            % function selectAction_Callback(obj, hObject)
            % callback for change of the selected actions in popups:
            % sectionPopup and actionPopup defined by hObject
            
            switch hObject.Tag
                case 'sectionPopup'
                    obj.selectedSection = hObject.Value;
                    obj.selectedAction = 1;
                case 'actionPopup'
                    obj.selectedAction = hObject.Value;
            end
            
            if isempty(obj.Sections(obj.selectedSection).Actions(obj.selectedAction).Command)
                Batch.mibBatchSectionName = 'Service steps';
                Batch.mibBatchActionName = 'STOP EXECUTION';
                Batch.Description = 'Wait for a user';
                obj.updateSelectedActionTable(Batch);
            else
                Batch = NaN; %#ok<NASGU>    % when Parameter is NaN calling of the command returns structure with possible options
                eval(obj.Sections(obj.selectedSection).Actions(obj.selectedAction).Command);
            end
            obj.selectedActionTableIndex = 1;
            obj.updateWidgets();
            obj.displaySelectedActionTableItems();
        end
        
        function updateSelectedActionTable(obj, BatchOpt)
            % update selected action table using the BatchOpt structure
            % Parameters:
            % BatchOpt: a structure with parameters
            % .Checkbox - logical, true/false, will be displayed as a checkbox
            % .Popupmenu - a cell array with 2 items for popupmenus.
            % .Popupmenu(1) - {'Container 1'}, selected item
            % .Popupmenu(2) - [{Container 1'},{Container 2'},{Container 3'}]
            % .Editbox - a string for edit box
            
            % update sections list
            obj.selectedSection = find(ismember({obj.Sections.Name}, BatchOpt.mibBatchSectionName) == 1);
            % update actions list
            obj.selectedAction = find(ismember({obj.Sections(obj.selectedSection).Actions.Name}, BatchOpt.mibBatchActionName));
            obj.updateWidgets();
            
            obj.CurrentBatch = BatchOpt;
            fieldNames = fieldnames(BatchOpt);
            
            % remove mibBatchSectionName and mibBatchActionName
            fieldNames(ismember(fieldNames, {'mibBatchSectionName', 'mibBatchActionName'})) = [];
            
            %obj.View.handles.selectedActionTable.RowName = fieldNames;  % row names are too wide, do not use them
            
            
            tData = cell([numel(fieldNames), 2]);
            %tData(:,1) = fieldNames;
            tData(:,1) = cellfun(@(x) sprintf('<html><b>%s</b></html>', x), fieldNames, 'UniformOutput', false);
            
            for rowId = 1:numel(fieldNames)
                if iscell(BatchOpt.(fieldNames{rowId}))
                    tData{rowId,2} = BatchOpt.(fieldNames{rowId}){1};
                elseif islogical(BatchOpt.(fieldNames{rowId}))
                    tData{rowId,2} = BatchOpt.(fieldNames{rowId});
                else
                    tData{rowId,2} = num2str(BatchOpt.(fieldNames{rowId}));
                end
            end
            obj.View.handles.selectedActionTable.Data = tData;
        end
        
        function displaySelectedActionTableItems(obj)
            % display current options for the highlighted row in the selectedActionTable
            
            if obj.selectedActionTableIndex == 0; return; end
            if isempty(obj.CurrentBatch); return; end
            
            obj.View.handles.selectedActionTableCellCheck.Visible = 'off';
            obj.View.handles.selectedActionTableCellPopup.Visible = 'off';
            obj.View.handles.selectedActionTableCellEdit.Visible = 'off';
            obj.View.handles.selectedActionTableCellNumericEdit.Visible = 'off';
            
            fieldNames = fieldnames(obj.CurrentBatch);
            % remove mibBatchSectionName and mibBatchActionName
            fieldNames(ismember(fieldNames, {'mibBatchSectionName', 'mibBatchActionName'})) = [];
            
            if isempty(fieldNames)
                obj.View.handles.selectedActionTableCellText.String = '';
                return; 
            end
            
            obj.View.handles.selectedActionTableCellText.String = fieldNames{obj.selectedActionTableIndex};
            
            if isnumeric(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}))
                obj.View.handles.selectedActionTableCellNumericEdit.Visible = 'on';
                obj.View.handles.selectedActionTableCellNumericEdit.String = num2str(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}));
            else
                switch class(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}))
                    case 'cell'
                        obj.View.handles.selectedActionTableCellPopup.Visible = 'on';
                        if numel(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex})) == 1
                            warndlg(sprintf('!!! Warning !!!\n\nThe possible configurations for this widgets were not provided!'));
                            obj.View.handles.selectedActionTableCellPopup.String = obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}){1};
                            obj.View.handles.selectedActionTableCellPopup.Value = 1;
                        else
                            obj.View.handles.selectedActionTableCellPopup.String = obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}){2};
                            obj.View.handles.selectedActionTableCellPopup.Value = ...
                                find(ismember(obj.View.handles.selectedActionTableCellPopup.String, obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex})(1)));
                        end
                    case 'logical'
                        obj.View.handles.selectedActionTableCellCheck.Visible = 'on';
                        obj.View.handles.selectedActionTableCellCheck.Value = obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex});
                    case 'char'
                        obj.View.handles.selectedActionTableCellEdit.Visible = 'on';
                        obj.View.handles.selectedActionTableCellEdit.String = obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex});
                end
            end
        end
        
        function selectedActionTableItem_Update(obj, hObject)
            % update selected action in selectedActionTable
            if obj.selectedActionTableIndex == 0; return; end
            fieldNames = fieldnames(obj.CurrentBatch);
            
            % remove mibBatchSectionName and mibBatchActionName
            fieldNames(ismember(fieldNames, {'mibBatchSectionName', 'mibBatchActionName'})) = [];
            
            switch hObject.Tag
                case 'selectedActionTableCellPopup'    % for popup menus
                    if numel(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex})) > 1
                        obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex})(1) = ...
                            obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}){2}(hObject.Value);
                        obj.View.handles.selectedActionTable.Data{obj.selectedActionTableIndex,2} = obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}){1};
                    end
                case 'selectedActionTableCellCheck'     % for checkboxes
                    obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}) = logical(hObject.Value);
                    obj.View.handles.selectedActionTable.Data{obj.selectedActionTableIndex,2} = logical(hObject.Value);
                case 'selectedActionTableCellEdit'      % for text edits
                    obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}) = hObject.String;
                    obj.View.handles.selectedActionTable.Data{obj.selectedActionTableIndex,2} = hObject.String;
                case 'selectedActionTableCellNumericEdit'   % for numeric edits
                    newValue =  str2num(hObject.String);      %#ok<ST2NM>
                    if ismember(fieldNames{obj.selectedActionTableIndex}, {'x', 'y', 'z', 't'}) && numel(newValue) == 1
                        newValue = [newValue newValue];
                    end
                    obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}) = newValue;
                    obj.View.handles.selectedActionTable.Data{obj.selectedActionTableIndex,2} = num2str(newValue);
            end
        end
        
        function selectedActionTable_ContextCallback(obj, parameter)
            % function selectedActionTable_ContextCallback(obj, parameter)
            % callback for context menu over selectedActionTable
            global mibPath;
            if obj.selectedActionTableIndex == 0; return; end
            
            switch parameter
                case 'add'
                    if isempty(obj.CurrentBatch); return; end
                    
                    prompts = {'Parameter type'; 'Parameter name'; 'Parameter value'};
                    defAns = {{'numeric', 1}; {'z', 'x', 'y', 't', 1}; '1'};
                    dlgTitle = 'Please specify parameter to add';
                    options.WindowStyle = 'normal';       
                    options.PromptLines = [1, 1, 1]; 
                    options.Title = 'Add parameter'; 
                    options.TitleLines = 1;  
                    options.WindowWidth = 1; 
                    options.Focus = 3;      
                    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer); return; end
                    switch answer{1}
                        case 'numeric'
                            newValue =  str2num(answer{3});      %#ok<ST2NM>
                            if ismember(answer{2}, {'x', 'y', 'z', 't'}) && numel(newValue) == 1
                                newValue = [newValue newValue];
                            end
                            obj.CurrentBatch.(answer{2}) = newValue;
                    end
                    obj.updateSelectedActionTable(obj.CurrentBatch);
                case 'delete'
                    if isempty(obj.CurrentBatch); return; end
                    
                    fieldNames = fieldnames(obj.CurrentBatch);
                    % remove mibBatchSectionName and mibBatchActionName
                    fieldNames(ismember(fieldNames, {'mibBatchSectionName', 'mibBatchActionName'})) = [];
                    obj.CurrentBatch = rmfield(obj.CurrentBatch, fieldNames{obj.selectedActionTableIndex});
                    obj.selectedActionTableIndex = obj.selectedActionTableIndex - 1;
                    obj.updateSelectedActionTable(obj.CurrentBatch);
            end
        end
        
        function deleteProtocol(obj)
            % function deleteProtocol(obj)
            % delete current protocol
            obj.BackupProtocol();   % store the current protocol
            
            obj.Protocol = [];
            obj.protocolListIndex = 0;
            obj.updateProtocolList();
            obj.protocolList_SelectionCallback();
        end
        
        function saveProtocol(obj)
            % function saveProtocol(obj)
            % save protocol to a file
            
            if isempty(obj.Protocol); return; end
            
            fn_out = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
            dotIndex = strfind(fn_out,'.');
            if ~isempty(dotIndex); fn_out = fn_out(1:dotIndex-1); end
            if isempty(strfind(fn_out,'/')) && isempty(strfind(fn_out,'\')) %#ok<STREMP>
                fn_out = fullfile(obj.mibModel.myPath, fn_out);
            end
            if isempty(fn_out); fn_out = obj.mibModel.myPath; end
            
            Filters = {'*.mibProtocol;',  'Matlab format (*.mibProtocol)';...
                       '*.xls',   'Excel format (*.xls)'; };
            
            [filename, path, FilterIndex] = uiputfile(Filters, 'Save protocol...', fn_out); %...
            if isequal(filename,0); return; end % check for cancel
            fn_out = fullfile(path, filename);
            
            switch Filters{FilterIndex,2}
                case 'Matlab format (*.mibProtocol)'
                    Protocol = obj.Protocol; %#ok<PROP>
                    save(fn_out, 'Protocol', '-mat', '-v7.3');
                case 'Excel format (*.xls)'
                    warning off MATLAB:xlswrite:AddSheet;
                    wb = waitbar(0, sprintf('Saving to Excel\nPlease wait...'));
                    % Sheet 1
                    s = {sprintf('MIB protocol file: %s', fn_out)};
                    s(3,1) = {'Step'}; s(3,2) = {'Section name'}; s(3,3) = {'Action name'}; s(3,4) = {'Command'};
                    s(3,5) = {'Parameter name'}; s(3,6) = {'Parameter value'};
                    lineIndex = 4;
                    for protId = 1:numel(obj.Protocol)
                        s(lineIndex,1) = {sprintf('%d', protId)};
                        s(lineIndex,2) = {obj.Protocol(protId).mibBatchSectionName};
                        s(lineIndex,3) = {obj.Protocol(protId).mibBatchActionName};
                        s(lineIndex,4) = {obj.Protocol(protId).Command};
                        fieldNames = fieldnames(obj.Protocol(protId).Batch);
                        for i=1:numel(fieldNames)
                            s(lineIndex,5) = fieldNames(i);
                            if iscell(obj.Protocol(protId).Batch.(fieldNames{i}))
                                s(lineIndex,6) = {obj.Protocol(protId).Batch.(fieldNames{i}){1}};
                            else
                                s(lineIndex,6) = {obj.Protocol(protId).Batch.(fieldNames{i})};
                            end
                            lineIndex = lineIndex + 1;
                        end
                        if isempty(fieldNames); lineIndex = lineIndex + 1; end  % to fix position for the STOP EXECUTION
                    end
                    waitbar(.2, wb);
                    xlswrite2(fn_out, s, 'Protocol', 'A1');
                    waitbar(1, wb);
                    delete(wb);
            end
            fprintf('mib: protocol was saved to "%s"\n', fn_out);
        end
        
        function loadProtocol(obj)
            % function loadProtocol(obj)
            % load protocol from a file
            
            if isempty(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'))
                path = obj.mibView.handles.mibPathEdit.String;
            else
                path = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            end
            
            [filename, path] = uigetfile(...
                {'*.mibProtocol',  'Matlab format (*.mibProtocol)'; ...
                '*.*',  'All Files (*.*)'}, ...
                'Load a protocol...',path);
            if isequal(filename,0); return; end % check for cancel
            res = load(fullfile(path, filename), '-mat');
            obj.BackupProtocol();   % store the current protocol
            obj.Protocol = res.Protocol;
            obj.protocolListIndex = 1;
            obj.updateProtocolList();
            obj.protocolList_SelectionCallback();
        end
        
        function protocolActions_Callback(obj, options)
            % function protocolActions_Callback(obj, options)
            % options to modify protocol
            % options: a string with action to perform to the protocol
            % 'add' - add selected action to the protocol
            % 'insert' - insert selected action to the protocol
            % 'insertstop' - insert a stop action
            % 'update' - update selected action of the protocol
            % 'show' -  display settings for the selected action
            % 'delete' - delete selected action from the protocol
            
            switch options
                case {'add', 'insert', 'update'}      % add, insert or update selected action to the protocol
                    if isempty(obj.CurrentBatch)
                        warndlg(sprintf('!!! Warning !!!\n\nPlease select an action to perform from the list of available actions and try again!'), 'The action was not selected!');
                        return;
                    end
                    obj.BackupProtocol();   % store the current protocol
                    switch options
                        case 'add'
                            obj.protocolListIndex = numel(obj.Protocol)+1;
                        case 'insert'
                            obj.protocolListIndex = max([1 obj.protocolListIndex]);
                            obj.Protocol(obj.protocolListIndex+1:numel(obj.Protocol)+1) = obj.Protocol(obj.protocolListIndex:numel(obj.Protocol));
                        case 'update'
                            if obj.protocolListIndex==0; obj.protocolListIndex=1; end
                    end
                    obj.Protocol(obj.protocolListIndex).mibBatchSectionName = obj.CurrentBatch.mibBatchSectionName;
                    obj.Protocol(obj.protocolListIndex).mibBatchActionName = obj.CurrentBatch.mibBatchActionName;
                    obj.Protocol(obj.protocolListIndex).Command = obj.Sections(obj.selectedSection).Actions(obj.selectedAction).Command;
                    obj.Protocol(obj.protocolListIndex).Batch = rmfield(obj.CurrentBatch, {'mibBatchSectionName','mibBatchActionName'});
                    obj.View.handles.protocolList.Value = obj.protocolListIndex;
                case 'insertstop'
                    obj.BackupProtocol();   % store the current protocol
                    obj.protocolListIndex = max([1 obj.protocolListIndex]);
                    obj.Protocol(obj.protocolListIndex+1:numel(obj.Protocol)+1) = obj.Protocol(obj.protocolListIndex:numel(obj.Protocol));
                    
                    obj.Protocol(obj.protocolListIndex).mibBatchSectionName = 'Service steps';
                    obj.Protocol(obj.protocolListIndex).mibBatchActionName = 'STOP EXECUTION';
                    obj.Protocol(obj.protocolListIndex).Command = [];
                    obj.Protocol(obj.protocolListIndex).Batch = struct();
                    obj.Protocol(obj.protocolListIndex).Batch.Description = 'Wait for a user';
                    obj.View.handles.protocolList.Value = obj.protocolListIndex;
                case 'show'
                    if obj.protocolListIndex == 0; return; end
                    obj.protocolList_SelectionCallback();
                case 'moveup'
                    if obj.protocolListIndex < 2; return; end
                    obj.BackupProtocol();   % store the current protocol
                    currAction = obj.Protocol(obj.protocolListIndex);
                    obj.Protocol(obj.protocolListIndex) = obj.Protocol(obj.protocolListIndex-1);
                    obj.Protocol(obj.protocolListIndex-1) = currAction;
                    obj.protocolListIndex = obj.protocolListIndex - 1;
                case 'movedown'
                    if obj.protocolListIndex == numel(obj.Protocol); return; end
                    obj.BackupProtocol();   % store the current protocol
                    currAction = obj.Protocol(obj.protocolListIndex);
                    obj.Protocol(obj.protocolListIndex) = obj.Protocol(obj.protocolListIndex+1);
                    obj.Protocol(obj.protocolListIndex+1) = currAction;
                    obj.protocolListIndex = obj.protocolListIndex + 1;
                case 'delete'
                    if obj.protocolListIndex == 0; return; end
                    obj.BackupProtocol();   % store the current protocol
                    obj.Protocol(obj.protocolListIndex) = [];
                    obj.protocolListIndex = obj.protocolListIndex - 1;
                    if numel(obj.Protocol)>0 && obj.protocolListIndex == 0
                        obj.protocolListIndex = 1;
                    end
                    if obj.protocolListIndex > 0; obj.View.handles.protocolList.Value = obj.protocolListIndex; end
            end
            obj.updateProtocolList();
            obj.protocolList_SelectionCallback();
        end
    
        function protocolList_SelectionCallback(obj)
            % function protocolList_SelectionCallback(obj)
            % callback for selection of a row in protocolList
            if obj.protocolListIndex == 0; return; end
            
            BatchOpt = obj.Protocol(obj.protocolListIndex).Batch;
            BatchOpt.mibBatchSectionName = obj.Protocol(obj.protocolListIndex).mibBatchSectionName;
            BatchOpt.mibBatchActionName = obj.Protocol(obj.protocolListIndex).mibBatchActionName;
            obj.updateSelectedActionTable(BatchOpt);
            
            obj.selectedActionTableIndex = 1;
            obj.displaySelectedActionTableItems();
        end
        
        function updateProtocolList(obj)
            % function updateProtocolList(obj)
            % update protocol list
            
            tData = cell([numel(obj.Protocol), 1]);
            for rowId = 1:numel(obj.Protocol)
                tData{rowId} = sprintf('%d. %s -> %s',rowId,obj.Protocol(rowId).mibBatchSectionName, obj.Protocol(rowId).mibBatchActionName);
            end
            obj.View.handles.protocolList.Value = 1;
            obj.View.handles.protocolList.String = tData;
            if obj.protocolListIndex > 0; obj.View.handles.protocolList.Value = obj.protocolListIndex; end
        end
        
        function BackupProtocol(obj)
            % function BackupProtocol(obj)
            % backup the current protocol
            %if isempty(obj.Protocol); return; end
            
            obj.ProtocolBackupsCurrNumber = obj.ProtocolBackupsCurrNumber + 1;
            obj.ProtocolBackups(obj.ProtocolBackupsCurrNumber:end) = [];
            if obj.ProtocolBackupsCurrNumber > obj.ProtocolBackupsMaxNumber     % limit of backup steps reached
                obj.ProtocolBackupsCurrNumber = obj.ProtocolBackupsCurrNumber - 1;
                obj.ProtocolBackups = obj.ProtocolBackups(2:obj.ProtocolBackupsCurrNumber);
            end
            obj.ProtocolBackups{obj.ProtocolBackupsCurrNumber} = obj.Protocol;
        end
        
        function BackupProtocolRestore(obj, mode)
            % function BackupProtocolRestore(obj, mode)
            % restore protocol from the backup
            % Parameters:
            % mode: a string
            %  'undo' - to make an undo
            %  'redo' - to make a redo
            
            if nargin < 2; mode = 'undo'; end
            switch mode
                case 'undo'
                    if obj.ProtocolBackupsCurrNumber == 0; return; end % first history entry is reached
                    currProtocol = obj.Protocol;
                    obj.Protocol = obj.ProtocolBackups{obj.ProtocolBackupsCurrNumber};
                    obj.ProtocolBackups{obj.ProtocolBackupsCurrNumber} = currProtocol;
                    obj.ProtocolBackupsCurrNumber = obj.ProtocolBackupsCurrNumber - 1;
                    obj.protocolListIndex = obj.protocolListIndex - 1;
                case 'redo'
                    if obj.ProtocolBackupsCurrNumber == obj.ProtocolBackupsMaxNumber || obj.ProtocolBackupsCurrNumber == numel(obj.ProtocolBackups)
                        return; 
                    end % last history entry is reached
                    obj.ProtocolBackupsCurrNumber = min([obj.ProtocolBackupsCurrNumber + 1, numel(obj.ProtocolBackups)]);
                    currProtocol = obj.Protocol;
                    obj.Protocol = obj.ProtocolBackups{obj.ProtocolBackupsCurrNumber};
                    obj.ProtocolBackups{obj.ProtocolBackupsCurrNumber} = currProtocol;
                    obj.protocolListIndex = min([obj.protocolListIndex + 1, numel(obj.View.handles.protocolList.String)]);
            end
            obj.updateProtocolList();
            %obj.protocolList_SelectionCallback();
        end
        
        function runProtocolBtn_Callback(obj, parameter)
            % function runProtocolBtn_Callback(obj, parameter)
            % run the protocol
            % 
            % Parameters:
            % parameter: a string with details
            %   'complete' - run all steps of the protocol
            %   'from' - run the protocol from the selected step
            %   'step' - run the selected step only
            %   'stepadvance' - run the selected step and advance to next
            
            if isempty(obj.Protocol); return; end
            
            switch parameter
                case 'complete'
                    startStep = 1;
                    finishStep = numel(obj.Protocol);
                case 'from'
                    startStep = obj.protocolListIndex;
                    finishStep = numel(obj.Protocol);
                case {'step', 'stepadvance'}
                    startStep = obj.protocolListIndex;
                    finishStep = obj.protocolListIndex;
                    if strcmp(parameter, 'stepadvance') && ...
                            strcmp(obj.Protocol(startStep).mibBatchSectionName, 'Service steps') && ...
                            strcmp(obj.Protocol(startStep).mibBatchActionName, 'STOP EXECUTION')
                        obj.protocolListIndex = min([obj.protocolListIndex + 1, numel(obj.Protocol)]);
                        obj.updateProtocolList();
                        obj.protocolList_SelectionCallback();
                        return;
                    end
            end
            
            %if obj.BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', [obj.BatchOpt.Method ' thresholding']); end
            for stepId = startStep:finishStep
                if strcmp(obj.Protocol(stepId).mibBatchSectionName, 'Service steps') && strcmp(obj.Protocol(stepId).mibBatchActionName, 'STOP EXECUTION')
                    % stop the protocol
                    obj.View.handles.protocolList.Value = stepId;
                    obj.protocolListIndex = stepId;
                    return;
                end
                Batch = obj.Protocol(stepId).Batch; %#ok<NASGU>
                % remove possible settings for the comboboxes from the
                % Batch structure
                fieldNames = fieldnames(Batch);
                for fName = 1:numel(fieldNames)
                    if iscell(Batch.(fieldNames{fName}))
                        Batch.(fieldNames{fName}) = Batch.(fieldNames{fName})(1);
                    end
                end
                obj.View.handles.protocolList.Value = stepId;
                eval(obj.Protocol(stepId).Command);
            end
            if strcmp(parameter, 'stepadvance')
                obj.protocolListIndex = min([obj.protocolListIndex + 1, numel(obj.Protocol)]);
                obj.updateProtocolList();
                obj.protocolList_SelectionCallback();
            end
            %if obj.BatchOpt.showWaitbar; delete(wb); end
        end
    end
end