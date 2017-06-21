classdef mibKeyShortcutsController < handle
    % classdef mibKeyShortcutsController < handle
    % a controller class for the MIB Key Shortcuts dialog
    
    % Copyright (C) 17.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    
    
    properties
        mibPreferencesController
        % handle to mibPreferencesController class
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        oldKeyShortcuts
        % stored old key shortcuts
        KeyShortcuts
        % local copy of MIB key shortcuts
        duplicateEntries  
        % array with duplicate entries
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
%     methods (Static)
%         function ViewListner_Callback(obj, src, evnt)
%             switch src.Name
%                 case 'Id'
%                     obj.updateWidgets();
%             end
%         end
%     end
    
    methods
        function obj = mibKeyShortcutsController(mibModel, mibPreferencesController)
            obj.mibModel = mibModel;    % assign model
            obj.mibPreferencesController = mibPreferencesController;
            obj.KeyShortcuts = mibPreferencesController.preferences.KeyShortcuts;
            obj.oldKeyShortcuts = mibPreferencesController.preferences.KeyShortcuts;
            guiName = 'mibKeyShortcutsGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            obj.duplicateEntries = [];  % array with duplicate entries
            
            obj.updateWidgets();
            obj.fitTextBtn_Callback();
            obj.View.gui.WindowStyle = 'modal';     % make window modal
            
            % add listner to obj.mibModel and call controller function as a callback
            % obj.listener{1} = addlistener(obj.mibModel, 'Id', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
        end
        
        function closeWindow(obj)
            % closing mibKeyShortcutsController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete childController window
            end
            
            % delete listeners, otherwise they stay after deleting of the
            % controller
            for i=1:numel(obj.listener)
                delete(obj.listener{i});
            end
            
            notify(obj, 'closeEvent');      % notify mibPreferencesController that this child window is closed
        end
        
        function updateWidgets(obj)
            % function updateWidgets(obj)
            % update widgets of the window
            
            % update table with contents of handles.KeyShortcuts
            % Column names and column format
            ColumnName =    {'',    'Action name',  'Key',      'Shift',    'Control',  'Alt'};
            ColumnFormat =  {'char','char',         'char',     'logical',  'logical',  'logical'};
            obj.View.handles.shortcutsTable.ColumnName = ColumnName;
            obj.View.handles.shortcutsTable.ColumnFormat = ColumnFormat;
            
            data(:,2) = obj.KeyShortcuts.Action;
            data(:,3) = obj.KeyShortcuts.Key;
            data(:,4) = num2cell(logical(obj.KeyShortcuts.shift));
            data(:,5) = num2cell(logical(obj.KeyShortcuts.control));
            data(:,6) = num2cell(logical(obj.KeyShortcuts.alt));
            
            colergen = @(color,text) ['<html><table border=0 width=20 bgcolor=''',color,'''><TR><TD>',text,'</TD></TR> </table></html>'];
            data(1:numel(obj.KeyShortcuts.Action), 1) = cellstr(repmat(colergen('rgb(0, 255, 0)', '&nbsp;'), numel(obj.KeyShortcuts.Action)));
            data(obj.duplicateEntries, 1) = cellstr(repmat(colergen('rgb(255, 0, 0)', '&nbsp;'), numel(obj.duplicateEntries)));
            
            ColumnEditable = [false false true true true true];
            obj.View.handles.shortcutsTable.ColumnEditable = ColumnEditable;
            obj.View.handles.shortcutsTable.Data = data;
        end
        
        function okBtn_Callback(obj)
            % function OKBtn_Callback(obj)
            % callback for press of obj.View.handles.OKBtn
            if numel(obj.duplicateEntries) > 1
                warndlg('Please check for duplicates!');
                return;
            end
            
            data = obj.View.handles.shortcutsTable.Data;
            obj.KeyShortcuts.Action = data(:, 2)';
            obj.KeyShortcuts.Key = data(:, 3)';
            obj.KeyShortcuts.shift = cell2mat(data(:, 4))';
            obj.KeyShortcuts.control = cell2mat(data(:, 5))';
            obj.KeyShortcuts.alt = cell2mat(data(:, 6))';
            
            obj.mibPreferencesController.preferences.KeyShortcuts = obj.KeyShortcuts;
            obj.closeWindow();
        end
        
        function fitTextBtn_Callback(obj)
            % function fitTextBtn_Callback(obj)
            % callback for press of obj.View.handles.fitTextBtn
            
            units = obj.View.handles.shortcutsTable.Units;
            obj.View.handles.shortcutsTable.Units = 'pixels';
            length1 = max(cellfun(@numel, obj.KeyShortcuts.Action));
            length2 = max(cellfun(@numel, obj.KeyShortcuts.Key));
            length = {10, length1*5, length2*7, 'auto', 'auto', 'auto'};
            obj.View.handles.shortcutsTable.ColumnWidth = 'auto';     % for some resons have to make it auto first, otherwise the table is not rescaled
            obj.View.handles.shortcutsTable.ColumnWidth = length;
            obj.View.handles.shortcutsTable.Units = units;
        end
        
        function shortcutsTable_CellEditCallback(obj, eventdata)
            % function shortcutsTable_CellEditCallback(obj, eventdata)
            % callback for modification of cells in obj.View.handles.shortcutsTable
            
            index = eventdata.Indices(1);
            data = obj.View.handles.shortcutsTable.Data;
            
            % make it impossible to change Shift action for some actions
            if ismember(data(index, 2), obj.KeyShortcuts.Action(6:16))
                data(index, 4) = num2cell(false);
                obj.View.handles.shortcutsTable.Data = data;
            end
            
            colergen = @(color,text) ['<html><table border=0 width=10 bgcolor=''',color,'''><TR><TD>',text,'</TD></TR> </table></html>'];
            if ~isempty(data{index, 3})
                % check for duplicates
                KeyShortcutsLocal.Key = data(:, 3)';
                KeyShortcutsLocal.shift = cell2mat(data(:, 4))';
                KeyShortcutsLocal.control = cell2mat(data(:, 5))';
                KeyShortcutsLocal.alt = cell2mat(data(:, 6))';
                
                shiftSw = data{index, 4};
                controlSw = data{index, 5};
                altSw = data{index, 6};
                
                ActionId = ismember(KeyShortcutsLocal.Key, data(index, 3)) & ismember(KeyShortcutsLocal.control, controlSw) & ...
                    ismember(KeyShortcutsLocal.shift, shiftSw) & ismember(KeyShortcutsLocal.alt, altSw);
                ActionId = find(ActionId > 0);    % action id is the index of the action, handles.preferences.KeyShortcuts.Action(ActionId)
                if numel(ActionId) > 1
                    actionId = ActionId(ActionId ~= index);
                    button = questdlg(sprintf('!!! Warning !!!\n\nA duplicate entry was found in the list of shortcuts!\nThe keystroke "%s" is already assigned to action number "%d"\n"%s"\n\nContinue anyway?', data{index, 3}, actionId, data{actionId, 2}),'Duplicate found!','Continue','Cancel','Cancel');
                    if strcmp(button, 'Cancel')
                        data(index, eventdata.Indices(2)) = {eventdata.PreviousData};
                    else
                        obj.duplicateEntries = [obj.duplicateEntries ActionId];     % add index of a duplicate entry
                        obj.duplicateEntries = unique(obj.duplicateEntries);     % add index of a duplicate entry
                        
                        data(ActionId, 1) = cellstr(repmat(colergen('rgb(255, 0, 0)','&nbsp;'), numel(ActionId)));
                    end;
                else
                    obj.duplicateEntries(obj.duplicateEntries==ActionId) = [];  % remove possible diplicate
                    if numel(obj.duplicateEntries) < 2
                        obj.duplicateEntries =[];
                        data(1:size(data,1), 1) = cellstr(repmat(colergen('rgb(0, 255, 0)', '&nbsp;'), size(data,1)));
                    else
                        data(index, 1) = cellstr(colergen('rgb(0, 255, 0)', '&nbsp;'));
                    end
                end
            else
                obj.duplicateEntries(obj.duplicateEntries == index) = [];  % remove possible diplicate
                if numel(obj.duplicateEntries) < 2
                    obj.duplicateEntries =[];
                    data(1:size(data,1), 1) = cellstr(repmat(colergen('rgb(0, 255, 0)', '&nbsp;'), size(data,1)));
                else
                    data(index, 1) = cellstr(colergen('rgb(0, 255, 0)', '&nbsp;'));
                end
            end
            obj.View.handles.shortcutsTable.Data = data;
        end
        
        function defaultBtn_Callback(obj)
            % function defaultBtn_Callback(obj)
            % callback for press of obj.View.handles.defaultBtn
            
            button = questdlg(sprintf('You are going to restore default key shortcuts\nAre you sure?'),...
                'Restore default shortcuts', 'Restore', 'Cancel', 'Cancel');
            if strcmp(button, 'Cancel'); return; end
            
            maxShortCutIndex = 29;  % total number of shortcuts
            obj.KeyShortcuts.shift(1:maxShortCutIndex) = 0;
            obj.KeyShortcuts.control(1:maxShortCutIndex) = 0;
            obj.KeyShortcuts.alt(1:maxShortCutIndex) = 0;
            
            obj.KeyShortcuts.Key{1} = '1';
            obj.KeyShortcuts.Action{1} = 'Switch dataset to XY orientation';
            obj.KeyShortcuts.alt(1) = 1;
            
            obj.KeyShortcuts.Key{2} = '2';
            obj.KeyShortcuts.Action{2} = 'Switch dataset to ZX orientation';
            obj.KeyShortcuts.alt(2) = 1;
            
            obj.KeyShortcuts.Key{3} = '3';
            obj.KeyShortcuts.Action{3} = 'Switch dataset to ZY orientation';
            obj.KeyShortcuts.alt(3) = 1;
            
            obj.KeyShortcuts.Key{4} = 'i';
            obj.KeyShortcuts.Action{4} = 'Interpolate selection';
            
            obj.KeyShortcuts.Key{5} = 'i';
            obj.KeyShortcuts.Action{5} = 'Invert image';
            obj.KeyShortcuts.control(5) = 1;
            
            obj.KeyShortcuts.Key{6} = 'a';
            obj.KeyShortcuts.Action{6} = 'Add to selection to material';
            
            obj.KeyShortcuts.Key{7} = 's';
            obj.KeyShortcuts.Action{7} = 'Subtract from material';
            
            obj.KeyShortcuts.Key{8} = 'r';
            obj.KeyShortcuts.Action{8} = 'Replace material with current selection';
            
            obj.KeyShortcuts.Key{9} = 'c';
            obj.KeyShortcuts.Action{9} = 'Clear selection';
            
            obj.KeyShortcuts.Key{10} = 'f';
            obj.KeyShortcuts.Action{10} = 'Fill the holes in the Selection layer';
            
            obj.KeyShortcuts.Key{11} = 'z';
            obj.KeyShortcuts.Action{11} = 'Erode the Selection layer';
            
            obj.KeyShortcuts.Key{12} = 'x';
            obj.KeyShortcuts.Action{12} = 'Dilate the Selection layer';
            
            obj.KeyShortcuts.Key{13} = 'q';
            obj.KeyShortcuts.Action{13} = 'Zoom out/Previous slice';
            
            obj.KeyShortcuts.Key{14} = 'w';
            obj.KeyShortcuts.Action{14} = 'Zoom in/Next slice';
            
            obj.KeyShortcuts.Key{15} = 'downarrow';
            obj.KeyShortcuts.Action{15} = 'Previous slice';
            
            obj.KeyShortcuts.Key{16} = 'uparrow';
            obj.KeyShortcuts.Action{16} = 'Next slice';
            
            obj.KeyShortcuts.Key{17} = 'space';
            obj.KeyShortcuts.Action{17} = 'Show/hide the Model layer';
            
            obj.KeyShortcuts.Key{18} = 'space';
            obj.KeyShortcuts.Action{18} = 'Show/hide the Mask layer';
            obj.KeyShortcuts.control(18) = 1;
            
            obj.KeyShortcuts.Key{19} = 'space';
            obj.KeyShortcuts.Action{19} = 'Fix selection to material';
            obj.KeyShortcuts.shift(19) = 1;
            
            obj.KeyShortcuts.Key{20} = 's';
            obj.KeyShortcuts.Action{20} = 'Save image as...';
            obj.KeyShortcuts.control(20) = 1;
            
            obj.KeyShortcuts.Key{21} = 'c';
            obj.KeyShortcuts.Action{21} = 'Copy to buffer selection from the current slice';
            obj.KeyShortcuts.control(21) = 1;
            
            obj.KeyShortcuts.Key{22} = 'v';
            obj.KeyShortcuts.Action{22} = 'Paste buffered selection to the current slice';
            obj.KeyShortcuts.control(22) = 1;
            
            obj.KeyShortcuts.Key{23} = 'e';
            obj.KeyShortcuts.Action{23} = 'Toggle between the selected material and exterior';
            
            obj.KeyShortcuts.Key{24} = 'd';
            obj.KeyShortcuts.Action{24} = 'Loop through the list of favourite segmentation tools';
            
            obj.KeyShortcuts.Key{25} = 'leftarrow';
            obj.KeyShortcuts.Action{25} = 'Previous time point';
            
            obj.KeyShortcuts.Key{26} = 'rightarrow';
            obj.KeyShortcuts.Action{26} = 'Next time point';
            
            obj.KeyShortcuts.Key{27} = 'z';
            obj.KeyShortcuts.Action{27} = 'Undo/Redo last action';
            obj.KeyShortcuts.control(27) = 1;
            
            obj.KeyShortcuts.Key{28} = 'f';
            obj.KeyShortcuts.Action{28} = 'Find material under cursor';
            obj.KeyShortcuts.control(28) = 1;
            
            obj.KeyShortcuts.Key{maxShortCutIndex} = 'v';
            obj.KeyShortcuts.Action{maxShortCutIndex} = 'Paste buffered selection to all slices';
            obj.KeyShortcuts.control(maxShortCutIndex) = 1;
            obj.KeyShortcuts.shift(maxShortCutIndex) = 1;
            
            obj.duplicateEntries = [];  % array with duplicate entries
            
            obj.updateWidgets();
            obj.fitTextBtn_Callback();    % adjust columns
        end
        
    end
end