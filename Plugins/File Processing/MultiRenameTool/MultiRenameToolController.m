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

classdef MultiRenameToolController < handle
    % @type MultiRenameToolController class is a template class for using with
    % GUI developed using appdesigner of Matlab
    %
    % @code
    % obj.startController('MultiRenameToolController'); // as GUI tool
    % @endcode
    % or 
    % @code 
    % // a code below was used for mibImageArithmeticController
    % BatchOpt.Parameter = 'test';  // fill edit boxes as strings
    % BatchOpt.Checkbox = true;     // fill checkboxes with logicals: true/false
    % BatchOpt.Popup = {'value'};        // value for the popups as a cell
    % BatchOpt.Radio = {'Radio1'};          // selection of radio buttons, as cell with the handle of the target radio button
    % BatchOpt.showWaitbar = true;  // show or not the waitbar
    % obj.startController('MultiRenameToolController', [], BatchOpt); // start MultiRenameToolController in the batch mode
    % @endcode
    % or
    % @code
    % // trigger return of the possible Options using returnBatchOpt function
    % // using notify syncBatch event
    % obj.startController('MultiRenameToolController', [], NaN);
    % @endcode
    
	% Updates
	%     
    
    properties
        mibModel
        % handles to mibModel
        View
        % handle to the view / MultiRenameToolGUI
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
        % .Radio - [radiobuttons], cell string 'Radio1' or 'Radio2'...
        % .ParameterNumeric{1} - [numeric editbox], cell with a number 
        % .ParameterNumeric{2} - [optional], vector with limits [min, max]
        % .ParameterNumeric{3} - [optional], string 'on' - to round the value, 'off' to do not round the value
        autoPreview
        % auto preview changes without pressing of the Preview results button
        fileListInput
        % list of input files, a structure with fields:
        % .fn - cell array of filenames
        % .ext - cell array of extensions
        % .path - string with filename path

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
        function obj = MultiRenameToolController(mibModel, varargin)
            obj.mibModel = mibModel;    % assign model
            
            %% fill the BatchOpt structure with default values
            % fields of the structure should correspond to the starting
            % text in the each widget tooltip.
            % For example, this demo template has an edit box, where the
            % tooltip starts with "Parameter:...". Text Parameter
            % indicates field of the BatchOpt structure that defines value
            % for this widget
            obj.BatchOpt.FilenameTemplate = '[N]';
            obj.BatchOpt.ExtensionTemplate = '[E]';
            obj.BatchOpt.FilenameOptions = {'Name, [N]'};
            obj.BatchOpt.FilenameOptions{2} = {'Counter, [C]', 'Extension, [E]', 'Name, [N]', 'Parent folder, [P]'};
            obj.BatchOpt.CounterDigits{1} = 4;     % numeric value
            obj.BatchOpt.CounterDigits{2} = [1 999];    % possible limits value
            obj.BatchOpt.CounterDigits{3} = 'on';    % round the numeric value
            obj.BatchOpt.CounterStart{1} = 1;     % numeric value
            obj.BatchOpt.CounterStart{2} = [1 999999];    % possible limits value
            obj.BatchOpt.CounterStart{3} = 'on';    % round the numeric value
            obj.BatchOpt.CounterStep{1} = 1;     % numeric value
            obj.BatchOpt.CounterStep{2} = [1 999999];    % possible limits value
            obj.BatchOpt.CounterStep{3} = 'on';    % round the numeric value
            obj.BatchOpt.SearchFor = '';
            obj.BatchOpt.ReplaceWith = '';
            obj.BatchOpt.Lettercase = {'Unchanged'};
            obj.BatchOpt.Lettercase{2} = {'Unchanged', 'UPPERCASE', 'lowercase'};
            obj.BatchOpt.MatchCase = false;
            obj.BatchOpt.AddZerosToNumbers = false;
            obj.BatchOpt.ExcludePrefixes = '';  % when adding leading zero exclude these prefixes with numbers from the conversion
            obj.BatchOpt.showWaitbar = true;
            %             obj.BatchOpt.id = obj.mibModel.Id;  % optional
            %
            %             %% part below is only valid for use of the plugin from MIB batch controller
            %             % comment it if intended use not from the batch mode
            %             obj.BatchOpt.mibBatchSectionName = 'Menu -> Plugins';    % section name for the Batch
            %             obj.BatchOpt.mibBatchActionName = 'MultiRenameTool';           % name of the plugin
            %             % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.FilenameTemplate = sprintf('Specify filename using a combination of free text and available templates');
            obj.BatchOpt.mibBatchTooltip.ExtensionTemplate = sprintf('Specify filename extension using a combination of free text and available templates');
            obj.BatchOpt.mibBatchTooltip.FilenameOptions = sprintf('List of available templates for filenames, press the Insert option buton to add it to the filename template');
            obj.BatchOpt.mibBatchTooltip.CounterDigits = sprintf('Number of digits in filename counter');
            obj.BatchOpt.mibBatchTooltip.CounterStart = sprintf('Starting value for the counter');
            obj.BatchOpt.mibBatchTooltip.CounterStep = sprintf('Counter step');
            obj.BatchOpt.mibBatchTooltip.SearchFor = sprintf('Define search template for text');
            obj.BatchOpt.mibBatchTooltip.ReplaceWith = sprintf('Replace the found text with new text');
            obj.BatchOpt.mibBatchTooltip.Lettercase = sprintf('Change or keep latter case');
            obj.BatchOpt.mibBatchTooltip.MatchCase = sprintf('Match letter case when searching');
            obj.BatchOpt.mibBatchTooltip.AddZerosToNumbers = sprintf('Search for numbers and convert them to the specified number of digits');
            obj.BatchOpt.mibBatchTooltip.ExcludePrefixes = sprintf('When adding leading zero exclude these prefixes with numbers from the conversion, use commas or spaces to separate prefixes');
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
                
                %obj.Calculate();
                notify(obj, 'closeEvent');
                return;
            end
            
            guiName = 'MultiRenameToolGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % init the widgets
            %destBuffers = arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false);
            %obj.View.handles.Popup.String = destBuffers;
            obj.fileListInput = struct();
            obj.fileListInput.fn = {};
            obj.fileListInput.ext = {};
            obj.fileListInput.path = {};

            obj.autoPreview = true;

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
            % obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));   
        end
        
        function closeWindow(obj)
            % closing MultiRenameToolController window
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
            
            infoText = ['<div style="font-family: Sans-serif; font-size: 9pt;">' ...
                '<b>[C]</b> - add filename counter<br>' ...
                '<b>[E]</b> - add filename extension<br>' ...
                '<b>[N]</b> - add filename<br>' ...
                '<b>[P]</b> - add parent folder<br>'];

            obj.View.handles.infoHTML1.HTMLSource = sprintf('<p style="font-family: Sans-serif; font-size: 9pt;">%s</p>', infoText);

            obj.View.handles.autoPreview.Value = obj.autoPreview;

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
            % auto preview results
            if obj.autoPreview; obj.preview(); end
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
        function selectFiles(obj)
            % function selectFiles(obj)
            % select list of files that should be renamed
            
            fileFilter = {'*.*',  'All Files (*.*)'; ...
                '*.am',  'AmiraMesh Files (*.am)'; ...
                '*.jpg',  'JPG Files (*.jpg)'; ...
                '*.png',  'PNG Files (*.png)'; ...
                '*.tif',  'TIF Files (*.tif)'};
            [file, path, indx] = mib_uigetfile(fileFilter, 'Select files', obj.mibModel.myPath, 'on');
            drawnow;
            figure(obj.View.gui);
            if isequal(file, 0); return; end
            
            [~, file, ext] = fileparts(file);
            ext = strrep(ext, '.', '');     % remove leading dot
            if ~iscell(file)
                obj.fileListInput.fn = {file};
                obj.fileListInput.ext = {ext};
            else
                obj.fileListInput.fn = file;
                obj.fileListInput.ext = ext;
            end
            if path(end)==filesep; path = path(1:end-1); end    % remove ending slash
            obj.fileListInput.path = path;
            
            obj.View.handles.PathToFiles.Value = path;
            obj.updateFileListTable();
        end

        function updateFileListTable(obj)
            % function updateFileListTable(obj)
            % update the file list table

            newNames = obj.processFileNames(obj.fileListInput.fn, obj.BatchOpt.FilenameTemplate);
            newExtensions = obj.processFileNames(obj.fileListInput.ext, obj.BatchOpt.ExtensionTemplate);
                        
            % Update table
            obj.View.handles.FileListTable.Data = table(obj.fileListInput.fn', obj.fileListInput.ext', newNames', newExtensions', ...
                'VariableNames', {'Old name','Old extension','New name', 'New extension'});
            obj.View.handles.FileListTable.ColumnName = {'Old name','Old extension','New name', 'New extension'};
        end

        function autoPreviewValueChanged(obj)
            % function autoPreviewValueChanged(obj)
            % modify the auto preview state
            obj.autoPreview = obj.View.handles.autoPreview.Value;
        end

        function preview(obj)
            % function Preview(obj)
            % preview results of the renaming operation
            obj.updateFileListTable()
        end

        function T = processFileNames(obj, S, template)
            % Inputs:
            % S - input cell array of strings (original filenames)
            % template - string specifying output format with [C], [E], [N], [P] placeholders and free text
            
            % preserve space for the output
            T = cell(size(S));

            % Generate T based on template and counter
            for i = 1:length(S)
                % Counter string with specified digits
                counter = sprintf(['%0' num2str(obj.BatchOpt.CounterDigits{1}) 'd'], obj.BatchOpt.CounterStart{1} + (i-1)*obj.BatchOpt.CounterStep{1});

                % Replace templates in the user-provided template string
                temp = template;
                temp = strrep(temp, '[C]', counter);           % Counter
                temp = strrep(temp, '[E]', obj.fileListInput.ext{i});        % Extension without dot
                temp = strrep(temp, '[N]', obj.fileListInput.fn{i});              % Name
                temp = strrep(temp, '[P]', fileparts(obj.fileListInput.path));       % Parent folder

                T{i} = temp;
            end

            % Fix numbers if requested
            if obj.BatchOpt.AddZerosToNumbers
                % convert obj.BatchOpt.ExcludePrefixes to cell array
                % Remove leading/trailing whitespace
                exclude_prefixes = strtrim(obj.BatchOpt.ExcludePrefixes);
                % Check if commas are present
                if contains(obj.BatchOpt.ExcludePrefixes, ',')
                    % Split by commas and trim each element
                    exclude_prefixes = split(exclude_prefixes, ',');
                    exclude_prefixes = strtrim(exclude_prefixes);
                else
                    % Split by spaces (one or more)
                    exclude_prefixes = split(exclude_prefixes, whitespacePattern);
                    exclude_prefixes = strtrim(exclude_prefixes);
                end

                num_digits =obj.BatchOpt.CounterDigits{1};

                for i = 1:length(T)
                    current_str = T{i};

                    % Step 1: Find all numbers and their positions
                    [matches, tokens, starts] = regexp(current_str, '\d+', 'match', 'tokens', 'start');

                    if ~isempty(matches)
                        % Step 2: Determine which numbers to exclude based on prefixes
                        exclude_flags = false(size(matches));
                        for p = 1:length(exclude_prefixes)
                            prefix = exclude_prefixes{p};
                            % Find positions where this prefix appears
                            prefix_starts = strfind(current_str, prefix);
                            for ps = prefix_starts
                                prefix_end = ps + length(prefix) - 1;
                                % Check if any number starts right after this prefix
                                for m = 1:length(starts)
                                    if starts(m) == prefix_end + 1
                                        exclude_flags(m) = true;
                                    end
                                end
                            end
                        end

                        % Step 3: Replace numbers, working backwards to avoid overlap issues
                        for j = length(matches):-1:1
                            if ~exclude_flags(j)  % Only pad if not excluded
                                % Extract the number
                                num_str = matches{j};
                                num = str2double(num_str);

                                % Format the number with the specified number of digits
                                padded_num = sprintf(['%0' num2str(num_digits) 'd'], num);

                                % Replace the original number with the padded version
                                start_pos = starts(j);
                                current_str = [current_str(1:start_pos-1) ...
                                    padded_num ...
                                    current_str(start_pos+length(num_str):end)];
                            end
                        end
                    end

                    % Update the cell array with the modified string
                    T{i} = current_str;
                end
            end

            % Search and replace in T
            if ~isempty(obj.BatchOpt.SearchFor)
                if obj.BatchOpt.MatchCase
                    % Case-sensitive replacement
                    T = strrep(T, obj.BatchOpt.SearchFor, obj.BatchOpt.ReplaceWith);
                else
                    % Case-insensitive replacement
                    for i = 1:length(T)
                        T{i} = regexprep(T{i}, regexptranslate('escape', obj.BatchOpt.SearchFor), obj.BatchOpt.ReplaceWith, 'ignorecase');
                    end
                end
            end

            % Adjust letter case
            switch obj.BatchOpt.Lettercase{1}
                case 'lowercase'
                    T = lower(T);
                case 'UPPERCASE'
                    T = upper(T);
                case 'Unchanged'
                    % Do nothing
                otherwise
                    errodlg('Invalid letter_case value. Options are: ''unchanged'', ''lower'', ''upper''. No case adjustment applied.');
            end
        end

        function T = pad_numbers_exclude_prefixes(T, num_digits, exclude_prefixes)
            % T: cell array of strings
            % num_digits: desired number of digits (e.g., 3 for '001')
            % exclude_prefixes: cell array of prefixes after which numbers should NOT be padded

            for i = 1:length(T)
                current_str = T{i};

                % Step 1: Find all numbers and their positions
                [matches, tokens, starts] = regexp(current_str, '\d+', 'match', 'tokens', 'start');

                if ~isempty(matches)
                    % Step 2: Determine which numbers to exclude based on prefixes
                    exclude_flags = false(size(matches));
                    for p = 1:length(exclude_prefixes)
                        prefix = exclude_prefixes{p};
                        % Find positions where this prefix appears
                        prefix_starts = strfind(current_str, prefix);
                        for ps = prefix_starts
                            prefix_end = ps + length(prefix) - 1;
                            % Check if any number starts right after this prefix
                            for m = 1:length(starts)
                                if starts(m) == prefix_end + 1
                                    exclude_flags(m) = true;
                                end
                            end
                        end
                    end

                    % Step 3: Replace numbers, working backwards to avoid overlap issues
                    for j = length(matches):-1:1
                        if ~exclude_flags(j)  % Only pad if not excluded
                            % Extract the number
                            num_str = matches{j};
                            num = str2double(num_str);

                            % Format the number with the specified number of digits
                            padded_num = sprintf(['%0' num2str(num_digits) 'd'], num);

                            % Replace the original number with the padded version
                            start_pos = starts(j);
                            current_str = [current_str(1:start_pos-1) ...
                                padded_num ...
                                current_str(start_pos+length(num_str):end)];
                        end
                    end
                end

                % Update the cell array with the modified string
                T{i} = current_str;
            end
        end

        function helpButton_Callback(obj)
            global mibPath;
            web(fullfile(mibPath, 'techdoc/html/user-interface/plugins/file-processing/multi-rename-tool.html'), '-browser');
        end

        function FileListTableContextMenu(obj, operation)
            % function FileListTableContextMenu(obj, operation)
            % context menu callbacks for obj.View.handles.FileListTable
            %
            % Parameters:
            % operation: string with required operation:
            % @li "RemoveFromList" - selected files remove from the list

            if isempty(obj.View.handles.FileListTable.Data); return; end

            rowsId = unique(obj.View.handles.FileListTable.Selection(:,1));
            switch operation
                case 'RemoveFromList'
                    obj.fileListInput.fn(rowsId) = [];
                    obj.fileListInput.ext(rowsId) = [];
            end
            obj.updateFileListTable();
        end

        function rename(obj)
            % start main calculation of the plugin
            newNames = obj.processFileNames(obj.fileListInput.fn, obj.BatchOpt.FilenameTemplate);
            newExtensions = obj.processFileNames(obj.fileListInput.ext, obj.BatchOpt.ExtensionTemplate);
            oldFullFiles = fullfile(obj.fileListInput.path, strcat(obj.fileListInput.fn, '.', obj.fileListInput.ext));
            newFullFiles = fullfile(obj.fileListInput.path, strcat(newNames, '.', newExtensions));
            noFiles = numel(oldFullFiles);

            if obj.BatchOpt.showWaitbar
                pwb = PoolWaitbar(1, sprintf('Starting calculations\nPlease wait...'), [], ...
                    'My plugin', ...
                    obj.View.gui);
                pwb.updateMaxNumberOfIterations(noFiles);     % update number of max iterations for the waitbar
                pwb.setIncrement(10);
            end

            try
                for i=1:noFiles
                    % if files the same, skip
                    if ~strcmp(oldFullFiles{i}, newFullFiles{i})
                        % rename files
                        movefile(oldFullFiles{i}, newFullFiles{i});
                    end
                    
                    if mod(i, 10)
                        if obj.BatchOpt.showWaitbar
                            if pwb.getCancelState(); delete(pwb); return; end % check for cancel
                            %pwb.updateText(sprintf('Updating text\nPlease wait...'));
                            increment(pwb);
                        end

                    end
                end
            catch err
                mibShowErrorDialog(obj.View.gui, err, 'Error');
                if obj.BatchOpt.showWaitbar; delete(pwb); end
            end

            if obj.BatchOpt.showWaitbar
                delete(pwb);
            end

            % redraw the image if needed
            % notify(obj.mibModel, 'plotImage');

            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            % obj.returnBatchOpt();
        end
        
        
    end
end