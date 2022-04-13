classdef mibPreferencesAppController < handle
    % @type mibPreferencesAppController class displays preferences dialog
    % using appdesigner created GUI
    %
    % @code
    % obj.startController('mibPreferencesAppController'); // as GUI tool
    % @endcode
    
    % Copyright (C) 18.09.2020, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
        mibController
        % a handle to mibController class
        mibModel
        % handles to mibModel
        View
        % handle to the view / mibPreferencesAppGUI
        listener
        % a cell array with handles to listeners
        shownPanelTag
        % a tag of the shown panel
        oldPreferences
        % stored old preferences
        preferences
        % local copy of MIB preferences
        duplicateEntries  
        % array with duplicate key shortcut entries
        renderedPanels     % indices of panels that are already rendered, for faster change upon press on new tree node
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
        function obj = mibPreferencesAppController(mibModel, varargin)
            global GUIscaling;
            
            obj.mibModel = mibModel;    % assign model
            obj.mibController = varargin{1};    % get handle to controller
            
            guiName = 'mibPreferencesAppGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % init the widgets
            obj.shownPanelTag = 'UserInterfacePanel';
            obj.preferences = mibModel.preferences;
            obj.oldPreferences = mibModel.preferences;
            
            % update current preferences using those taken from dataset
            % logic for disable selection: it is always taken from the
            % currently shown dataset. The datasets are initialzed during
            % MIB startup with the settings in the preferences
            obj.preferences.System.EnableSelection = obj.mibModel.I{obj.mibModel.Id}.enableSelection;
            
            % move the window to the left hand side of the main window
            obj.View.gui = moveWindowOutside(obj.View.gui, 'center', 'center');
            
            % resize all elements of the GUI
            % mibRescaleWidgets(obj.View.gui); % this function is not yet
            % compatible with appdesigner
            
            % update font and size
            % you may need to replace "obj.View.handles.text1" with tag of any text field of your own GUI
            global Font;
            
            if ~isempty(Font)
                if obj.View.handles.UserInterfacePanel.FontSize ~= Font.FontSize+4 ...
                        || ~strcmp(obj.View.handles.UserInterfacePanel.FontName, Font.FontName)
                    mibUpdateFontSize(obj.View.gui, Font);
                end
            end
            obj.duplicateEntries = [];
            obj.updateWidgets();
            
            % obj.View.gui.WindowStyle = 'modal';     % make window modal
            
            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing mibPreferencesAppController window
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
        
        function updateWidgets(obj, panelId)
            % function updateWidgets(obj, panelId)
            % update widgets of this window
            %
            % Parameters:
            % panelId; [optional] handle to panel that has to be updated, when
            % missing all panels are updated
            % "UserInterfacePanel", 
            
            panelsList = {'UserInterfacePanel', 'ColorsPanel', 'BackupAndUndoPanel', ...
                'ExternalDirectoriesPanel', 'KeyboardShortcutsPanel', 'SegmentationToolsPanel'};
            
            if nargin < 2
                panelId = 'All'; 
                obj.renderedPanels = zeros([numel(panelsList) 1]);     % indices of the rendered panels
            end
            
            % % ---------  UserInterfacePanel ------------------
            if strcmp(panelId, 'All') || strcmp(panelId, 'UserInterfacePanel')
                if obj.renderedPanels(1) == 1; return; end  % already rendered
                if strcmp(obj.preferences.System.MouseWheel, 'zoom')   % zoom or scroll
                    obj.View.handles.MouseWheelActionDropDown.Value = 'Zoom In/Out';
                else
                    obj.View.handles.MouseWheelActionDropDown.Value = 'Change slices/frames';
                end
                if strcmp(obj.preferences.System.LeftMouseButton, 'pan')   % pan or select
                    obj.View.handles.LeftMouseActionDropDown.Value = 'Pan image';
                else
                    obj.View.handles.LeftMouseActionDropDown.Value = 'Selection/drawing';
                end
                obj.View.handles.ImageResizeMethodDropDown.Value = obj.preferences.System.ImageResizeMethod;


                if obj.mibModel.I{obj.mibModel.Id}.enableSelection == 1
                    obj.View.handles.EnableSelectionDropDown.Value = 'yes';
                else
                    obj.View.handles.EnableSelectionDropDown.Value = 'no';
                end

                obj.View.handles.RecentDirsNumber.Value = obj.preferences.System.Dirs.RecentDirsNumber;
                
                obj.View.handles.CurrentFontLabel.Text = ...
                    sprintf('Current font: [ %s, %d, %s ]', obj.preferences.System.Font.FontName,  obj.preferences.System.Font.FontSize, obj.preferences.System.Font.FontUnits);
                obj.View.handles.FontSizeEditField.Value = obj.preferences.System.Font.FontSize;
                obj.View.handles.FontSizeDireContentsEditField.Value = obj.preferences.System.FontSizeDirView;

                obj.View.handles.RecheckPeriod.Value = obj.preferences.System.Update.RecheckPeriod;
                
                obj.View.handles.SystemScalingEditField.Value = obj.preferences.System.GUI.systemscaling;
                obj.View.handles.mibScalingFactorEditField.Value = obj.preferences.System.GUI.scaling;
                obj.View.handles.uibuttongroup.Value = obj.preferences.System.GUI.uibuttongroup;
                obj.View.handles.uipanel.Value = obj.preferences.System.GUI.uipanel;
                obj.View.handles.uitab.Value = obj.preferences.System.GUI.uitab;
                obj.View.handles.uitabgroup.Value = obj.preferences.System.GUI.uitabgroup;
                obj.View.handles.axes.Value = obj.preferences.System.GUI.axes;
                obj.View.handles.uitable.Value = obj.preferences.System.GUI.uitable;
                obj.View.handles.uicontrol.Value = obj.preferences.System.GUI.uicontrol;
                obj.renderedPanels(1) = 1;
            end
            
            % % ---------  ColorsPanel ------------------
            if strcmp(panelId, 'All') || strcmp(panelId, 'ColorsPanel')
                if obj.renderedPanels(2) == 1; return; end  % already rendered
                
                obj.View.handles.SelectionColorButton.BackgroundColor = obj.preferences.Colors.SelectionColor;
                obj.View.handles.MaskColorButton.BackgroundColor = obj.preferences.Colors.MaskColor;
                obj.View.handles.AnnotationsColorButton.BackgroundColor = obj.preferences.SegmTools.Annotations.Color;

                % updating options for color palettes
                if obj.mibModel.getImageProperty('modelType') < 256
                    materialsNumber = numel(obj.mibModel.getImageProperty('modelMaterialNames'));
                else
                    materialsNumber = obj.mibModel.getImageProperty('modelType');
                end

                if materialsNumber > 12
                    paletteList = {'Distinct colors, 20 colors', 'Matlab Jet','Matlab Gray','Matlab Bone','Matlab HSV', 'Matlab Cool', 'Matlab Hot','Random Colors'};
                    obj.View.handles.PaletteGeneratorDropDown.Items = paletteList;
                elseif materialsNumber > 11
                    paletteList = {'Distinct colors, 20 colors', 'Qualitative (Monte Carlo->Half Baked), 3-12 colors','Matlab Jet','Matlab Gray','Matlab Bone','Matlab HSV', 'Matlab Cool', 'Matlab Hot','Random Colors'};
                    obj.View.handles.PaletteGeneratorDropDown.Items = paletteList;
                elseif materialsNumber > 9
                    paletteList = {'Distinct colors, 20 colors', 'Qualitative (Monte Carlo->Half Baked), 3-12 colors','Diverging (Deep Bronze->Deep Teal), 3-11 colors','Diverging (Ripe Plum->Kaitoke Green), 3-11 colors',...
                        'Diverging (Bordeaux->Green Vogue), 3-11 colors, 3-11 colors', 'Diverging (Carmine->Bay of Many), 3-11 colors',...
                        'Matlab Jet','Matlab Gray','Matlab Bone','Matlab HSV', 'Matlab Cool', 'Matlab Hot','Random Colors'};
                    obj.View.handles.PaletteGeneratorDropDown.Items = paletteList;
                elseif materialsNumber > 6
                    paletteList = {'Distinct colors, 20 colors', 'Qualitative (Monte Carlo->Half Baked), 3-12 colors','Diverging (Deep Bronze->Deep Teal), 3-11 colors','Diverging (Ripe Plum->Kaitoke Green), 3-11 colors',...
                        'Diverging (Bordeaux->Green Vogue), 3-11 colors, 3-11 colors', 'Diverging (Carmine->Bay of Many), 3-11 colors','Sequential (Kaitoke Green), 3-9 colors',...
                        'Sequential (Catalina Blue), 3-9 colors', 'Sequential (Maroon), 3-9 colors', 'Sequential (Astronaut Blue), 3-9 colors', 'Sequential (Downriver), 3-9 colors',...
                        'Matlab Jet','Matlab Gray','Matlab Bone','Matlab HSV', 'Matlab Cool', 'Matlab Hot','Random Colors'};
                    obj.View.handles.PaletteGeneratorDropDown.Items = paletteList;
                else
                    paletteList = {'Default, 6 colors', 'Distinct colors, 20 colors', 'Qualitative (Monte Carlo->Half Baked), 3-12 colors','Diverging (Deep Bronze->Deep Teal), 3-11 colors','Diverging (Ripe Plum->Kaitoke Green), 3-11 colors',...
                        'Diverging (Bordeaux->Green Vogue), 3-11 colors', 'Diverging (Carmine->Bay of Many), 3-11 colors','Sequential (Kaitoke Green), 3-9 colors',...
                        'Sequential (Catalina Blue), 3-9 colors', 'Sequential (Maroon), 3-9 colors', 'Sequential (Astronaut Blue), 3-9 colors', 'Sequential (Downriver), 3-9 colors',...
                        'Matlab Jet','Matlab Gray','Matlab Bone','Matlab HSV', 'Matlab Cool', 'Matlab Hot', 'Random Colors'};
                    obj.View.handles.PaletteGeneratorDropDown.Items = paletteList;
                end
                obj.updateColorsTables('ModelsColorsTable');  % redraw the color table
                obj.updateColorsTables('LUTColorsTable');  % redraw LUT color table
                obj.renderedPanels(2) = 1;
            end
            
            % % -------------- BackupAndUndoPanel ----------------
            if strcmp(panelId, 'All') || strcmp(panelId, 'BackupAndUndoPanel')
                if obj.renderedPanels(3) == 1; return; end  % already rendered
                if obj.preferences.Undo.Enable
                    obj.View.handles.EnableUndo.Value = true;
                    obj.View.handles.maxUndoHistory.Enable = 'on';
                    obj.View.handles.max3dUndoHistory.Enable = 'on';
                else
                    obj.View.handles.EnableUndo.Value = false;
                    obj.View.handles.maxUndoHistory.Enable = 'off';
                    obj.View.handles.max3dUndoHistory.Enable = 'off';
                end
                
                obj.View.handles.maxUndoHistory.Value = obj.preferences.Undo.MaxUndoHistory;
                obj.View.handles.max3dUndoHistory.Value = obj.preferences.Undo.Max3dUndoHistory;
                obj.renderedPanels(3) = 1; 
            end
            
            % % -------------- ExternalDirectoriesPanel ----------------
            if strcmp(panelId, 'All') || strcmp(panelId, 'ExternalDirectoriesPanel')
                if obj.renderedPanels(4) == 1; return; end  % already rendered
                obj.View.handles.FijiInstallationPath.Value = char(obj.preferences.ExternalDirs.FijiInstallationPath);
                obj.View.handles.OmeroInstallationPath.Value = char(obj.preferences.ExternalDirs.OmeroInstallationPath);
                obj.View.handles.ImarisInstallationPath.Value  = char(obj.preferences.ExternalDirs.ImarisInstallationPath);
                obj.View.handles.bm3dInstallationPath.Value = char(obj.preferences.ExternalDirs.bm3dInstallationPath);
                obj.View.handles.bm4dInstallationPath.Value = char(obj.preferences.ExternalDirs.bm4dInstallationPath);
                obj.View.handles.BioFormatsMemoizerMemoDir.Value = char(obj.preferences.ExternalDirs.BioFormatsMemoizerMemoDir);
                obj.View.handles.DeepMIBDir.Value = char(obj.preferences.ExternalDirs.DeepMIBDir);
                obj.renderedPanels(4) = 1; 
            end

            % % -------------- KeyboardShortcutsPanel ----------------
            if strcmp(panelId, 'All') || strcmp(panelId, 'KeyboardShortcutsPanel')
                if obj.renderedPanels(5) == 1; return; end  % already rendered
                % update table with contents of handles.KeyShortcuts
                % Column names and column format
                ColumnName =    {'',    'Action name',  'Key',      'Shift',    'Control',  'Alt'};
                ColumnFormat =  {'char','char',         'char',     'logical',  'logical',  'logical'};
                obj.View.handles.shortcutsTable.ColumnName = ColumnName;
                obj.View.handles.shortcutsTable.ColumnFormat = ColumnFormat;
                
                data(:,2) = obj.preferences.KeyShortcuts.Action;
                data(:,3) = obj.preferences.KeyShortcuts.Key;
                data(:,4) = num2cell(logical(obj.preferences.KeyShortcuts.shift));
                data(:,5) = num2cell(logical(obj.preferences.KeyShortcuts.control));
                data(:,6) = num2cell(logical(obj.preferences.KeyShortcuts.alt));

                obj.View.handles.shortcutsTable.ColumnWidth = {8, 'auto', 62, 46, 56, 46};
                
                removeStyle(obj.View.handles.shortcutsTable);    % remove current styles

                s1 = uistyle;
                s1.BackgroundColor = [0 1 0];
                addStyle(obj.View.handles.shortcutsTable, s1, 'column', 1);
                drawnow;
                
                ColumnEditable = [false false true true true true];
                obj.View.handles.shortcutsTable.ColumnEditable = ColumnEditable;
                obj.View.handles.shortcutsTable.Data = data;
                obj.renderedPanels(5) = 1; 
            end

            
            % % -------------- SegmentationToolsPanel ----------------
            if strcmp(panelId, 'All') || strcmp(panelId, 'SegmentationToolsPanel')
                if obj.renderedPanels(6) == 1; return; end  % already rendered
                
                obj.View.handles.annotationFontSize.Value = obj.View.handles.annotationFontSize.Items{obj.preferences.SegmTools.Annotations.FontSize};
                obj.View.handles.annotationShownExtraDepth.Value = obj.preferences.SegmTools.Annotations.ShownExtraDepth;
                
                obj.View.handles.InterpolationType.Value = obj.preferences.SegmTools.Interpolation.Type;
                obj.View.handles.InterpolationNumberOfPoints.Value = obj.preferences.SegmTools.Interpolation.NoPoints;
                obj.View.handles.InterpolationLineWidth.Value = obj.preferences.SegmTools.Interpolation.LineWidth;
                obj.renderedPanels(6) = 1; 
            end
            
            
        end
        
        function status = ApplyButtonPushedCallback(obj)
            % function ApplyButtonPushedCallback(obj)
            % apply preferences to MIB
            global Font scalingGUI;
            status = 0;
            
            % update font size
            Font = obj.preferences.System.Font;
            if obj.mibController.mibView.handles.mibZoomText.FontSize ~= obj.preferences.System.Font.FontSize || ...
                    ~strcmp(obj.mibController.mibView.handles.mibZoomText.FontName, obj.preferences.System.Font.FontName)
                mibUpdateFontSize(obj.mibController.mibView.gui, obj.preferences.System.Font);
                %mibUpdateFontSize(obj.View.gui, obj.preferences.System.Font);
            end
            obj.mibController.mibView.handles.mibFilesListbox.FontSize = obj.preferences.System.FontSizeDirView;
            
            % update key shortcuts
            if numel(obj.duplicateEntries) > 1
                uialert(obj.View.gui, ...
                    'Please check for duplicates in key shortcuts!', 'Duplicate shortcuts');
                return;
            end
            
            data = obj.View.handles.shortcutsTable.Data;
            obj.preferences.preferences.KeyShortcuts.Action = data(:, 2)';
            obj.preferences.KeyShortcuts.Key = data(:, 3)';
            obj.preferences.KeyShortcuts.shift = cell2mat(data(:, 4))';
            obj.preferences.KeyShortcuts.control = cell2mat(data(:, 5))';
            obj.preferences.KeyShortcuts.alt = cell2mat(data(:, 6))';
            
            % deal with change of selection mode
            if obj.preferences.System.EnableSelection == 1   % turn ON the Selection
                if obj.mibModel.getImageProperty('modelType') == 255 && isnan(obj.mibModel.I{obj.mibModel.Id}.selection{1}(1))
                    obj.mibModel.getImageMethod('clearSelection');
                elseif obj.mibModel.getImageProperty('modelType') == 63 && isnan(obj.mibModel.I{obj.mibModel.Id}.model{1}(1))
                    obj.mibModel.I{obj.mibModel.Id}.model{1} = zeros(...
                        [obj.mibModel.getImageProperty('height'), obj.mibModel.getImageProperty('width'), ...
                        obj.mibModel.getImageProperty('depth'), obj.mibModel.getImageProperty('time')], 'uint8');
                end
            else         % turn OFF the Selection, Mask, Model
                if obj.mibModel.getImageProperty('modelType') == 63
                    obj.mibModel.I{obj.mibModel.Id}.model{1} = NaN;
                else
                    obj.mibModel.I{obj.mibModel.Id}.selection{1} = NaN;
                end
                obj.mibModel.setImageProperty('modelExist', 0);
                obj.mibModel.setImageProperty('maskExist', 0);
                obj.mibModel.U.clearContents();  % delete backup history
            end
            obj.mibModel.I{obj.mibModel.Id}.enableSelection = obj.preferences.System.EnableSelection;
            
            obj.mibModel.preferences = obj.preferences;
            
            obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors = obj.preferences.Colors.ModelMaterialColors;
            obj.mibModel.I{obj.mibModel.Id}.lutColors = obj.preferences.Colors.LUTColors;
            
            obj.mibController.toolbarInterpolation_ClickedCallback('keepcurrent');     % update the interpolation button icon
            obj.mibController.toolbarResizingMethod_ClickedCallback('keepcurrent');
            
            % update imaris path using IMARISPATH enviromental variable
            if ~isempty(obj.mibModel.preferences.ExternalDirs.ImarisInstallationPath)
                setenv('IMARISPATH', obj.mibModel.preferences.ExternalDirs.ImarisInstallationPath);
            end
            
            scalingGUI = obj.preferences.System.GUI;   % update scalingGUI
            
            notify(obj.mibModel, 'plotImage');
            status = 1;
        end
        
        function RescaleGUIButtonPushed(obj)
            % function RescaleGUIButtonPushed(obj)
            % rescale user interface of MIB
            global scalingGUI;
            
            scalingGUI = obj.preferences.System.GUI;   % update scalingGUI
            mibRescaleWidgets(obj.mibController.mibView.gui);   % rescale main GUI
            drawnow;
            figure(obj.View.gui);   % set focus to main preference window and move it in front
        end
        
        function OKButtonPushedCallback(obj)
            % function OKButtonPushedCallback(obj)
            % callback on press of OK
            
            status = obj.ApplyButtonPushedCallback();
            if status == 0; return; end
            
            if obj.preferences.Undo.Enable == 0
                obj.mibModel.U.clearContents();
                obj.mibModel.U.enableSwitch = 0;
            else
                obj.mibModel.U.enableSwitch = 1;
            end
            
            if obj.preferences.Undo.Max3dUndoHistory ~= obj.mibModel.U.max3d_steps || obj.preferences.Undo.MaxUndoHistory ~= obj.mibModel.U.max_steps
                obj.mibModel.U.setNumberOfHistorySteps(obj.preferences.Undo.MaxUndoHistory, obj.preferences.Undo.Max3dUndoHistory);
            end
            
            if obj.preferences.System.EnableSelection == 1
                if isnan(obj.mibModel.I{obj.mibModel.Id}.selection{1}(1)) && obj.mibModel.I{obj.mibModel.Id}.modelType ~= 63
                    obj.mibModel.I{obj.mibModel.Id}.clearSelection();
                elseif obj.mibModel.I{obj.mibModel.Id}.modelType == 63 && isnan(obj.mibModel.I{obj.mibModel.Id}.model{1}(1))
                    obj.mibModel.I{obj.mibModel.Id}.model{1} = ...
                        zeros([size(obj.mibModel.I{obj.mibModel.Id}.img{1},1),size(obj.mibModel.I{obj.mibModel.Id}.img{1},2),...
                        size(obj.mibModel.I{obj.mibModel.Id}.img{1},4),size(obj.mibModel.I{obj.mibModel.Id}.img{1},5)], 'uint8');
                end
            else
                if obj.mibModel.I{obj.mibModel.Id}.modelType == 63
                    obj.mibModel.I{obj.mibModel.Id}.model{1} = NaN;
                    obj.mibModel.I{obj.mibModel.Id}.modelExist = 0;
                    obj.mibModel.I{obj.mibModel.Id}.maskExist = 0;
                else
                    obj.mibModel.I{obj.mibModel.Id}.selection{1} = NaN;
                end
                obj.mibModel.U.clearContents();  % delete backup history
            end
            obj.mibModel.I{obj.mibModel.Id}.enableSelection = obj.preferences.System.EnableSelection;
            
            % remove the brush cursor
            obj.mibController.mibSegmentationToolPopup_Callback();
            obj.mibController.updateGuiWidgets();
            
            notify(obj.mibModel, 'plotImage');
            obj.closeWindow();
        end
        
        function ColorPanelCallbacks(obj, event)
            % function ColorPanelsCallbacks(obj, event)
            % callbacks for modification of the Colors panel
            %
            % Parameters:
            % event: a structure to the GUI element that has triggered callback
            global mibPath;
            
            switch event.Source.Tag
                case 'SelectionColorButton'    % update selection color
                    sel_color = obj.preferences.Colors.SelectionColor;
                    c = uisetcolor(sel_color, 'Selection color');
                    if length(c) == 1; return; end
                    obj.preferences.Colors.SelectionColor = c;
                    obj.View.handles.SelectionColorButton.BackgroundColor = c;
                case 'MaskColorButton'          % update mask color
                    sel_color = obj.preferences.Colors.MaskColor;
                    c = uisetcolor(sel_color, 'Mask color');
                    if length(c) == 1; return; end
                    obj.preferences.Colors.MaskColor = c;
                    obj.View.handles.MaskColorButton.BackgroundColor = c;
                case 'AnnotationsColorButton'   % update annotations color
                    sel_color = obj.preferences.SegmTools.Annotations.Color;
                    c = uisetcolor(sel_color, 'Annotations color');
                    if length(c) == 1; return; end
                    obj.preferences.SegmTools.Annotations.Color = c;
                    obj.View.handles.AnnotationsColorButton.BackgroundColor = c;
                case 'PaletteGeneratorDropDown'     % generate palette
                    materialsNumber = numel(obj.mibModel.getImageProperty('modelMaterialNames'));
                    
                    switch obj.View.handles.PaletteGeneratorDropDown.Value
                        case 'Default, 6 colors'
                            obj.View.handles.NumberOfColorsDropDown.Items = {'6'};
                        case 'Distinct colors, 20 colors'
                            obj.View.handles.NumberOfColorsDropDown.Items = {'20'};
                        case 'Qualitative (Monte Carlo->Half Baked), 3-12 colors'
                            obj.View.handles.NumberOfColorsDropDown.Items = compose('%d', max([3, materialsNumber]):12);
                        case 'Diverging (Deep Bronze->Deep Teal), 3-11 colors'
                            obj.View.handles.NumberOfColorsDropDown.Items = compose('%d', max([3, materialsNumber]):11);
                        case 'Diverging (Ripe Plum->Kaitoke Green), 3-11 colors'
                            obj.View.handles.NumberOfColorsDropDown.Items = compose('%d', max([3, materialsNumber]):11);
                        case 'Diverging (Bordeaux->Green Vogue), 3-11 colors'
                            obj.View.handles.NumberOfColorsDropDown.Items = compose('%d', max([3, materialsNumber]):11);
                        case 'Diverging (Carmine->Bay of Many), 3-11 colors'
                            obj.View.handles.NumberOfColorsDropDown.Items = compose('%d', max([3, materialsNumber]):11);
                        case 'Sequential (Kaitoke Green), 3-9 colors'
                            obj.View.handles.NumberOfColorsDropDown.Items = compose('%d', max([3, materialsNumber]):9);
                        case 'Sequential (Catalina Blue), 3-9 colors'
                            obj.View.handles.NumberOfColorsDropDown.Items = compose('%d', max([3, materialsNumber]):9);
                        case 'Sequential (Maroon), 3-9 colors'
                            obj.View.handles.NumberOfColorsDropDown.Items = compose('%d', max([3, materialsNumber]):9);
                        case 'Sequential (Astronaut Blue), 3-9 colors'
                            obj.View.handles.NumberOfColorsDropDown.Items = compose('%d', max([3, materialsNumber]):9);
                        case 'Sequential (Downriver), 3-9 colors'
                            obj.View.handles.NumberOfColorsDropDown.Items = compose('%d', max([3, materialsNumber]):9);
                        case {'Matlab Jet','Matlab Gray','Matlab Bone','Matlab HSV', 'Matlab Cool', 'Matlab Hot', 'Random Colors'}
                            answer = mibInputDlg({mibPath}, ...
                                sprintf('Please enter number of colors\n(max. value is %d)', obj.mibModel.getImageProperty('modelType')), ...
                                'Define number of colors', num2str(max(materialsNumber, 6)));
                            if isempty(answer); return; end
                            noColors = str2double(answer{1});
                            if noColors > 255
                                errordlg(sprintf('!!! Error !!!\n\nNumber of colors should be below 256'), 'Too many colors');
                                figure(obj.View.gui);   % set focus to main preference window and move it in front
                                return;
                            end
                            obj.View.handles.NumberOfColorsDropDown.Items = compose('%d', noColors);
                    end
                    obj.updateColorPalette();
                case 'NumberOfColorsDropDown'
                    obj.updateColorPalette();
            end
            figure(obj.View.gui);   % set focus to main preference window and move it in front
        end
        
        function KeyboardShortcutsPanelCallbacks(obj, event)
            % function KeyboardShortcutsPanelCallbacks(obj, event)
            % callbacks for modification of the Keyboard shortcuts panel
            % Parameters:
            % event: a structure to the GUI element that has triggered callback
            
            switch event.Source.Tag
                case 'ResetKeyShortcutsButton'
                    selection = uiconfirm(obj.View.gui, ...
                        sprintf('!!! Warning !!!\n\nYou are going to reset all keyboard shortcuts to default values!'), ...
                        'Reset key shortcuts', 'Options', {'Confirm', 'Cancel'}, ...
                        'Icon', 'warning');
                    if strcmp(selection, 'Cancel'); return; end
                    obj.preferences.KeyShortcuts = generateDefaultKeyShortcuts();
                    obj.updateWidgets();
            end
                
        end
        
        function SegmentationPanelCallbacks(obj, event)
            % function SegmentationPanelCallbacks(obj, event)
            % callbacks for modification of the Segmentation tools panel
            % Parameters:
            % event: a structure to the GUI element that has triggered callback
            
            switch event.Source.Tag
                case 'annotationFontSize'
                    obj.preferences.SegmTools.Annotations.FontSize = find(ismember(obj.View.handles.annotationFontSize.Items, obj.View.handles.annotationFontSize.Value));
                case 'annotationShownExtraDepth'
                    obj.preferences.SegmTools.Annotations.ShownExtraDepth = obj.View.handles.annotationShownExtraDepth.Value;
                case 'InterpolationType'
                    obj.preferences.SegmTools.Interpolation.Type = obj.View.handles.InterpolationType.Value;
                case 'InterpolationNumberOfPoints'
                    obj.preferences.SegmTools.Interpolation.NoPoints = obj.View.handles.InterpolationNumberOfPoints.Value;
                case 'InterpolationLineWidth'
                    obj.preferences.SegmTools.Interpolation.LineWidth = obj.View.handles.InterpolationLineWidth.Value;
            end
        end
        
        function BackupAndUndoPanelCallbacks(obj, event)
            % function BackupAndUndoPanelCallbacks(obj, event)
            % callbacks for modification of the Undo and backup panel
            %
            % Parameters:
            % event: a structure to the GUI element that has triggered callback
            
            switch event.Source.Tag
                case 'EnableUndo'
                    obj.preferences.Undo.Enable = obj.View.handles.EnableUndo.Value;
                    obj.updateWidgets('BackupAndUndoPanel');
                case {'maxUndoHistory', 'max3dUndoHistory'}
                    valueMax = obj.View.handles.maxUndoHistory.Value;
                    valueMax3d = obj.View.handles.max3dUndoHistory.Value;
                    
                    if valueMax3d > valueMax
                        uialert(obj.View.gui, ...
                            sprintf('Error!\n\nThe number of 3D history steps should be lower or equal than total number of steps'),...
                            'Error!');
                        obj.View.handles.maxUndoHistory.Value = obj.preferences.Undo.MaxUndoHistory;
                        obj.View.handles.max3dUndoHistory.Value = obj.preferences.Undo.Max3dUndoHistory;
                        return;
                    end
                    obj.preferences.Undo.MaxUndoHistory = valueMax;
                    obj.preferences.Undo.Max3dUndoHistory = valueMax3d;
            end
        end
        
        function UserInterfacePanelCallbacks(obj, event)
            % function UserInterfacePanelCallbacks(obj, event)
            % callbacks for modification of the User Interface panel
            %
            % Parameters:
            % event: a structure to the GUI element that has triggered callback
            
            switch event.Source.Tag
                case 'MouseWheelActionDropDown'
                    if strcmp(obj.View.handles.MouseWheelActionDropDown.Value, 'Zoom In/Out')
                        obj.preferences.System.MouseWheel = 'zoom';   % zoom or scroll
                    else
                        obj.preferences.System.MouseWheel = 'scroll';
                    end
                case 'LeftMouseActionDropDown'
                    if strcmp(obj.View.handles.MouseWheelActionDropDown.Value, 'Pan image')
                        obj.preferences.System.LeftMouseButton = 'pan';   % zoom or scroll
                    else    % Selection/drawing
                        obj.preferences.System.LeftMouseButton = 'select';
                    end
                case 'ImageResizeMethodDropDown'
                    obj.preferences.System.ImageResizeMethod = obj.View.handles.ImageResizeMethodDropDown.Value;
                case 'EnableSelectionDropDown'
                    if strcmp(obj.View.handles.EnableSelectionDropDown.Value, 'yes')
                        obj.preferences.System.EnableSelection = 1;   % enable selection
                    else    % no = disable selection
                        selection = uiconfirm(obj.View.gui, ...
                            sprintf('!!! Warning !!!\n\nDisabling of the Selection layer delete the Model and Mask layers!!!\n\nThese changes will affect only the currently shown dataset and the future MIB sessions\n\nAre you sure?'), ...
                            'Turn off selection layer',...
                            'Icon', 'warning');
                        if strcmp(selection, 'Cancel')
                            obj.View.handles.EnableSelectionDropDown.Value = 'yes';
                            return; 
                        end
                        obj.preferences.System.EnableSelection = 0;
                    end
                case 'RecentDirsNumber'
                    obj.preferences.System.Dirs.RecentDirsNumber = obj.View.handles.RecentDirsNumber.Value;
                case 'FontSizeEditField'
                    obj.preferences.System.Font.FontSize = obj.View.handles.FontSizeEditField.Value;
                    obj.updateWidgets();
                case 'FontSizeDireContentsEditField'
                    obj.preferences.System.FontSizeDirView = obj.View.handles.FontSizeDireContentsEditField.Value;
                case 'SelectFontButton'
                    obj.preferences.System.Font.FontSize = obj.preferences.System.Font.FontSize;
                    selectedFont = uisetfont(obj.preferences.System.Font);
                    if ~isstruct(selectedFont); return; end
                    selectedFont.FontSize = selectedFont.FontSize;
                    selectedFont = rmfield(selectedFont, 'FontWeight');
                    selectedFont = rmfield(selectedFont, 'FontAngle');
                    
                    obj.preferences.System.Font = selectedFont;
                    obj.View.handles.FontSizeEditField.Value = obj.preferences.System.Font.FontSize;
                    mibUpdateFontSize(obj.View.gui, obj.preferences.System.Font);
                    figure(obj.View.gui);   % set focus to main preference window and move it in front
                case 'RecheckPeriod'
                    obj.preferences.System.Update.RecheckPeriod = obj.View.handles.RecheckPeriod.Value;
                case 'SystemScalingEditField'
                    obj.preferences.System.GUI.systemscaling = obj.View.handles.SystemScalingEditField.Value;
                case 'mibScalingFactorEditField'
                    obj.preferences.System.GUI.scaling = obj.View.handles.mibScalingFactorEditField.Value;
                case 'uibuttongroup'
                    obj.preferences.System.GUI.uibuttongroup = obj.View.handles.uibuttongroup.Value;
                case 'uipanel'
                    obj.preferences.System.GUI.uipanel = obj.View.handles.uipanel.Value;
                case 'uitab'
                    obj.preferences.System.GUI.uitab = obj.View.handles.uitab.Value;
                case 'uitabgroup'
                    obj.preferences.System.GUI.uitabgroup = obj.View.handles.uitabgroup.Value;
                case 'axes'
                    obj.preferences.System.GUI.axes = obj.View.handles.axes.Value;
                case 'uitable'
                    obj.preferences.System.GUI.uitable = obj.View.handles.uitable.Value;
                case 'uicontrol'
                    obj.preferences.System.GUI.uicontrol = obj.View.handles.uicontrol.Value;
                    
            end
        end
        
        
        function CategoriesTreeSelectionChanged(obj, selectedNodes)
            % function CategoriesTreeSelectionChanged(obj, selectedNodes)
            % callback for change of nodes of CategoriesTree
            %
            % Parameters:
            % selectedNodes: handle to the selected nodes
            
            % hide currently visible (previous) panel
            obj.View.handles.(obj.shownPanelTag).Visible = 'off';
            
            newPanelTag = [selectedNodes.Tag(1:end-4) 'Panel'];
            obj.View.handles.(newPanelTag).Visible = 'on';
            
            obj.shownPanelTag = newPanelTag;    % update currently selected node variable
            obj.updateWidgets(obj.shownPanelTag);
        end
        
        
        function updateColorPalette(obj)
            % function updateColorPalette(obj)
            % generate default colors for the selected palette
            
            % update color palette based on selected parameters in the paletteTypePopup and paletteColorNumberPopup popups
            colorsNo = str2double(obj.View.handles.NumberOfColorsDropDown.Value);
            
            switch obj.View.handles.PaletteGeneratorDropDown.Value
                case 'Default, 6 colors'
                    obj.preferences.Colors.ModelMaterialColors = [166 67 33; 71 178 126; 79 107 171; 150 169 213; 26 51 111; 255 204 102 ]/255;
                case 'Distinct colors, 20 colors'
                    %obj.preferences.Colors.ModelMaterialColors = [255 80 5; 255 255 128; 116 10 255; 0 153 143; 66 102 0; 255 168 187; 0 51 128; 194 0 136; 143 124 0; 148 255 181; 255 204 153; 76 0 92; 153 63 0; 0 117 220; 240 163 255; 255 255 0; 153 0 0; 94 241 242; 255 0 16; 255 164 5; 157 204 0; 224 255 102; 0 92 49; 25 25 25; 43 206 72; 128 128 128; 255 255 255]/255;
                    obj.preferences.Colors.ModelMaterialColors = [230 25 75; 255 225 25; 0 130 200; 245 130 48; 145 30 180; 70 240 240; 240 50 230; 210 245 60; 250 190 190; 0 128 128; 230 190 255; 170 110 40; 255 250 200; 128 0 0; 170 255 195; 128 128 0; 255 215 180; 0 0 128; 128 128 128; 60 180 75]/255;
                case 'Qualitative (Monte Carlo->Half Baked), 3-12 colors'
                    switch colorsNo
                        case 3; obj.preferences.Colors.ModelMaterialColors = [141,211,199; 255,255,179; 190,186,218]/255;
                        case 4; obj.preferences.Colors.ModelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114]/255;
                        case 5; obj.preferences.Colors.ModelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211]/255;
                        case 6; obj.preferences.Colors.ModelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98]/255;
                        case 7; obj.preferences.Colors.ModelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105]/255;
                        case 8; obj.preferences.Colors.ModelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105; 252,205,229]/255;
                        case 9; obj.preferences.Colors.ModelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105; 252,205,229; 217,217,217]/255;
                        case 10; obj.preferences.Colors.ModelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105; 252,205,229; 217,217,217; 188,128,189]/255;
                        case 11; obj.preferences.Colors.ModelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105; 252,205,229; 217,217,217; 188,128,189; 204,235,197]/255;
                        case 12; obj.preferences.Colors.ModelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105; 252,205,229; 217,217,217; 188,128,189; 204,235,197; 255,237,111]/255;
                    end
                case 'Diverging (Deep Bronze->Deep Teal), 3-11 colors'
                    switch colorsNo
                        case 3; obj.preferences.Colors.ModelMaterialColors = [216,179,101; 245,245,245; 90,180,172]/255;
                        case 4; obj.preferences.Colors.ModelMaterialColors = [166,97,26; 223,194,125; 128,205,193; 1,133,113]/255;
                        case 5; obj.preferences.Colors.ModelMaterialColors = [166,97,26; 223,194,125; 245,245,245; 128,205,193; 1,133,113]/255;
                        case 6; obj.preferences.Colors.ModelMaterialColors = [140,81,10; 216,179,101; 246,232,195; 199,234,229; 90,180,172; 1,102,94]/255;
                        case 7; obj.preferences.Colors.ModelMaterialColors = [140,81,10; 216,179,101; 246,232,195; 245,245,245; 199,234,229; 90,180,172; 1,102,94]/255;
                        case 8; obj.preferences.Colors.ModelMaterialColors = [140,81,10; 191,129,45; 223,194,125; 246,232,195; 199,234,229; 128,205,193; 53,151,143; 1,102,94]/255;
                        case 9; obj.preferences.Colors.ModelMaterialColors = [140,81,10; 191,129,45; 223,194,125; 246,232,195; 245,245,245; 199,234,229; 128,205,193; 53,151,143; 1,102,94]/255;
                        case 10; obj.preferences.Colors.ModelMaterialColors = [84,48,5; 140,81,10; 191,129,45; 223,194,125; 246,232,195; 199,234,229; 128,205,193; 53,151,143; 1,102,94; 0,60,48]/255;
                        case 11; obj.preferences.Colors.ModelMaterialColors = [84,48,5; 140,81,10; 191,129,45; 223,194,125; 246,232,195; 245,245,245; 199,234,229; 128,205,193; 53,151,143; 1,102,94; 0,60,48]/255;
                    end
                case 'Diverging (Ripe Plum->Kaitoke Green), 3-11 colors'
                    switch colorsNo
                        case 3; obj.preferences.Colors.ModelMaterialColors = [175,141,195; 247,247,247; 127,191,123]/255;
                        case 4; obj.preferences.Colors.ModelMaterialColors = [123,50,148; 194,165,207; 166,219,160; 0,136,55]/255;
                        case 5; obj.preferences.Colors.ModelMaterialColors = [123,50,148; 194,165,207; 247,247,247; 166,219,160; 0,136,55]/255;
                        case 6; obj.preferences.Colors.ModelMaterialColors = [118,42,131; 175,141,195; 231,212,232; 217,240,211; 127,191,123; 27,120,55]/255;
                        case 7; obj.preferences.Colors.ModelMaterialColors = [118,42,131; 175,141,195; 231,212,232; 247,247,247; 217,240,211; 127,191,123; 27,120,55]/255;
                        case 8; obj.preferences.Colors.ModelMaterialColors = [118,42,131; 153,112,171; 194,165,207; 231,212,232; 217,240,211; 166,219,160; 90,174,97; 27,120,55]/255;
                        case 9; obj.preferences.Colors.ModelMaterialColors = [118,42,131; 153,112,171; 194,165,207; 231,212,232; 247,247,247; 217,240,211; 166,219,160; 90,174,97; 27,120,55]/255;
                        case 10; obj.preferences.Colors.ModelMaterialColors = [64,0,75; 118,42,131; 153,112,171; 194,165,207; 231,212,232; 217,240,211; 166,219,160; 90,174,97; 27,120,55; 0,68,27]/255;
                        case 11; obj.preferences.Colors.ModelMaterialColors = [64,0,75; 118,42,131; 153,112,171; 194,165,207; 231,212,232; 247,247,247; 217,240,211; 166,219,160; 90,174,97; 27,120,55; 0,68,27]/255;
                    end
                case 'Diverging (Bordeaux->Green Vogue), 3-11 colors'
                    switch colorsNo
                        case 3; obj.preferences.Colors.ModelMaterialColors = [239,138,98; 247,247,247; 103,169,207]/255;
                        case 4; obj.preferences.Colors.ModelMaterialColors = [202,0,32; 244,165,130; 146,197,222; 5,113,176]/255;
                        case 5; obj.preferences.Colors.ModelMaterialColors = [202,0,32; 244,165,130; 247,247,247; 146,197,222; 5,113,176]/255;
                        case 6; obj.preferences.Colors.ModelMaterialColors = [178,24,43; 239,138,98; 253,219,199; 209,229,240; 103,169,207; 33,102,172]/255;
                        case 7; obj.preferences.Colors.ModelMaterialColors = [178,24,43; 239,138,98; 253,219,199; 247,247,247; 209,229,240; 103,169,207; 33,102,172]/255;
                        case 8; obj.preferences.Colors.ModelMaterialColors = [178,24,43; 214,96,77; 244,165,130; 253,219,199; 209,229,240; 146,197,222; 67,147,195; 33,102,172]/255;
                        case 9; obj.preferences.Colors.ModelMaterialColors = [178,24,43; 214,96,77; 244,165,130; 253,219,199; 247,247,247; 209,229,240; 146,197,222; 67,147,195; 33,102,172]/255;
                        case 10; obj.preferences.Colors.ModelMaterialColors = [103,0,31; 178,24,43; 214,96,77; 244,165,130; 253,219,199; 209,229,240; 146,197,222; 67,147,195; 33,102,172; 5,48,97]/255;
                        case 11; obj.preferences.Colors.ModelMaterialColors = [103,0,31; 178,24,43; 214,96,77; 244,165,130; 253,219,199; 247,247,247; 209,229,240; 146,197,222; 67,147,195; 33,102,172; 5,48,97]/255;
                    end
                case 'Diverging (Carmine->Bay of Many), 3-11 colors'
                    switch colorsNo
                        case 3; obj.preferences.Colors.ModelMaterialColors = [252,141,89; 255,255,191; 145,191,219]/255;
                        case 4; obj.preferences.Colors.ModelMaterialColors = [215,25,28; 253,174,97; 171,217,233; 44,123,182]/255;
                        case 5; obj.preferences.Colors.ModelMaterialColors = [215,25,28; 253,174,97; 255,255,191; 171,217,233; 44,123,182]/255;
                        case 6; obj.preferences.Colors.ModelMaterialColors = [215,48,39; 252,141,89; 254,224,144; 224,243,248; 145,191,219; 69,117,180]/255;
                        case 7; obj.preferences.Colors.ModelMaterialColors = [215,48,39; 252,141,89; 254,224,144; 255,255,191; 224,243,248; 145,191,219; 69,117,180]/255;
                        case 8; obj.preferences.Colors.ModelMaterialColors = [215,48,39; 244,109,67; 253,174,97; 254,224,144; 224,243,248; 171,217,233; 116,173,209; 69,117,180]/255;
                        case 9; obj.preferences.Colors.ModelMaterialColors = [215,48,39; 244,109,67; 253,174,97; 254,224,144; 255,255,191; 224,243,248; 171,217,233; 116,173,209; 69,117,180]/255;
                        case 10; obj.preferences.Colors.ModelMaterialColors = [165,0,38; 215,48,39; 244,109,67; 253,174,97; 254,224,144; 224,243,248; 171,217,233; 116,173,209; 69,117,180; 49,54,149]/255;
                        case 11; obj.preferences.Colors.ModelMaterialColors = [165,0,38; 215,48,39; 244,109,67; 253,174,97; 254,224,144; 255,255,191; 224,243,248; 171,217,233; 116,173,209; 69,117,180; 49,54,149]/255;
                    end
                case 'Sequential (Kaitoke Green), 3-9 colors'
                    switch colorsNo
                        case 3; obj.preferences.Colors.ModelMaterialColors = [229,245,249; 153,216,201; 44,162,95]/255;
                        case 4; obj.preferences.Colors.ModelMaterialColors = [237,248,251; 178,226,226; 102,194,164; 35,139,69]/255;
                        case 5; obj.preferences.Colors.ModelMaterialColors = [237,248,251; 178,226,226; 102,194,164; 44,162,95; 0,109,44]/255;
                        case 6; obj.preferences.Colors.ModelMaterialColors = [237,248,251; 204,236,230; 153,216,201; 102,194,164; 44,162,95; 0,109,44]/255;
                        case 7; obj.preferences.Colors.ModelMaterialColors = [237,248,251; 204,236,230; 153,216,201; 102,194,164; 65,174,118; 35,139,69; 0,88,36]/255;
                        case 8; obj.preferences.Colors.ModelMaterialColors = [247,252,253; 229,245,249; 204,236,230; 153,216,201; 102,194,164; 65,174,118; 35,139,69; 0,88,36]/255;
                        case 9; obj.preferences.Colors.ModelMaterialColors = [247,252,253; 229,245,249; 204,236,230; 153,216,201; 102,194,164; 65,174,118; 35,139,69; 0,109,44; 0,68,27]/255;
                    end
                case 'Sequential (Catalina Blue), 3-9 colors'
                    switch colorsNo
                        case 3; obj.preferences.Colors.ModelMaterialColors = [224,243,219; 168,221,181; 67,162,202]/255;
                        case 4; obj.preferences.Colors.ModelMaterialColors = [240,249,232; 186,228,188; 123,204,196; 43,140,190]/255;
                        case 5; obj.preferences.Colors.ModelMaterialColors = [240,249,232; 186,228,188; 123,204,196; 67,162,202; 8,104,172]/255;
                        case 6; obj.preferences.Colors.ModelMaterialColors = [240,249,232; 204,235,197; 168,221,181; 123,204,196; 67,162,202; 8,104,172]/255;
                        case 7; obj.preferences.Colors.ModelMaterialColors = [240,249,232; 204,235,197; 168,221,181; 123,204,196; 78,179,211; 43,140,190; 8,88,158]/255;
                        case 8; obj.preferences.Colors.ModelMaterialColors = [247,252,240; 224,243,219; 204,235,197; 168,221,181; 123,204,196; 78,179,211; 43,140,190; 8,88,158]/255;
                        case 9; obj.preferences.Colors.ModelMaterialColors = [247,252,240; 224,243,219; 204,235,197; 168,221,181; 123,204,196; 78,179,211; 43,140,190; 8,104,172; 8,64,129]/255;
                    end
                case 'Sequential (Maroon), 3-9 colors'
                    switch colorsNo
                        case 3; obj.preferences.Colors.ModelMaterialColors = [254,232,200; 253,187,132; 227,74,51]/255;
                        case 4; obj.preferences.Colors.ModelMaterialColors = [254,240,217; 253,204,138; 252,141,89; 215,48,31]/255;
                        case 5; obj.preferences.Colors.ModelMaterialColors = [254,240,217; 253,204,138; 252,141,89; 227,74,51; 179,0,0]/255;
                        case 6; obj.preferences.Colors.ModelMaterialColors = [254,240,217; 253,212,158; 253,187,132; 252,141,89; 227,74,51; 179,0,0]/255;
                        case 7; obj.preferences.Colors.ModelMaterialColors = [254,240,217; 253,212,158; 253,187,132; 252,141,89; 239,101,72; 215,48,31; 153,0,0]/255;
                        case 8; obj.preferences.Colors.ModelMaterialColors = [255,247,236; 254,232,200; 253,212,158; 253,187,132; 252,141,89; 239,101,72; 215,48,31; 153,0,0]/255;
                        case 9; obj.preferences.Colors.ModelMaterialColors = [255,247,236; 254,232,200; 253,212,158; 253,187,132; 252,141,89; 239,101,72; 215,48,31; 179,0,0; 127,0,0]/255;
                    end
                case 'Sequential (Astronaut Blue), 3-9 colors'
                    switch colorsNo
                        case 3; obj.preferences.Colors.ModelMaterialColors = [236,231,242; 166,189,219; 43,140,190]/255;
                        case 4; obj.preferences.Colors.ModelMaterialColors = [241,238,246; 189,201,225; 116,169,207; 5,112,176]/255;
                        case 5; obj.preferences.Colors.ModelMaterialColors = [241,238,246; 189,201,225; 116,169,207; 43,140,190; 4,90,141]/255;
                        case 6; obj.preferences.Colors.ModelMaterialColors = [241,238,246; 208,209,230; 166,189,219; 116,169,207; 43,140,190; 4,90,141]/255;
                        case 7; obj.preferences.Colors.ModelMaterialColors = [241,238,246; 208,209,230; 166,189,219; 116,169,207; 54,144,192; 5,112,176; 3,78,123]/255;
                        case 8; obj.preferences.Colors.ModelMaterialColors = [255,247,251; 236,231,242; 208,209,230; 166,189,219; 116,169,207; 54,144,192; 5,112,176; 3,78,123]/255;
                        case 9; obj.preferences.Colors.ModelMaterialColors = [255,247,251; 236,231,242; 208,209,230; 166,189,219; 116,169,207; 54,144,192; 5,112,176; 4,90,141; 2,56,88]/255;
                    end
                case 'Sequential (Downriver), 3-9 colors'
                    switch colorsNo
                        case 3; obj.preferences.Colors.ModelMaterialColors = [237,248,177; 127,205,187; 44,127,184]/255;
                        case 4; obj.preferences.Colors.ModelMaterialColors = [255,255,204; 161,218,180; 65,182,196; 34,94,168]/255;
                        case 5; obj.preferences.Colors.ModelMaterialColors = [255,255,204; 161,218,180; 65,182,196; 44,127,184; 37,52,148]/255;
                        case 6; obj.preferences.Colors.ModelMaterialColors = [255,255,204; 199,233,180; 127,205,187; 65,182,196; 44,127,184; 37,52,148]/255;
                        case 7; obj.preferences.Colors.ModelMaterialColors = [255,255,204; 199,233,180; 127,205,187; 65,182,196; 29,145,192; 34,94,168; 12,44,132]/255;
                        case 8; obj.preferences.Colors.ModelMaterialColors = [255,255,217; 237,248,177; 199,233,180; 127,205,187; 65,182,196; 29,145,192; 34,94,168; 12,44,132]/255;
                        case 9; obj.preferences.Colors.ModelMaterialColors = [255,255,217; 237,248,177; 199,233,180; 127,205,187; 65,182,196; 29,145,192; 34,94,168; 37,52,148; 8,29,88]/255;
                    end
                case 'Matlab Jet'
                    obj.preferences.Colors.ModelMaterialColors =  colormap(jet(colorsNo));
                case 'Matlab Gray'
                    obj.preferences.Colors.ModelMaterialColors =  colormap(gray(colorsNo));
                case 'Matlab Bone'
                    obj.preferences.Colors.ModelMaterialColors =  colormap(bone(colorsNo));
                case 'Matlab HSV'
                    obj.preferences.Colors.ModelMaterialColors =  colormap(hsv(colorsNo));
                case 'Matlab Cool'
                    obj.preferences.Colors.ModelMaterialColors =  colormap(cool(colorsNo));
                case 'Matlab Hot'
                    obj.preferences.Colors.ModelMaterialColors =  colormap(hot(colorsNo));
                case 'Random Colors'
                    rng('shuffle');     % randomize generator
                    obj.preferences.Colors.ModelMaterialColors =  colormap(rand([colorsNo,3]));
            end
            obj.updateColorsTables('ModelsColorsTable');
        end
        
        function updateColorsTables(obj, ColorTableTag, options)
            % function updateColorsTables(obj, ColorTableTag, options)
            % update color tables: ModelsColorsTable or LUTColorsTable
            %
            % Parameters:
            % ColorTableHandle: a string with a tag of the table: "ModelsColorsTable", "LUTColorsTable"
            % options:  a structure with additional parameters
            % .updateDataOnly - [logical, dafault=false] update the data in the table without
            % .rowId - [integer, default=[]] index of a row to update, when empty update the full table
            % redrawing the styles
            
            if nargin < 2; error('ColorTableTag  is missing'); end
            if nargin < 3; options = struct(); end
            if ~isfield(options, 'updateDataOnly'); options.updateDataOnly = false; end
            if ~isfield(options, 'rowId'); options.rowId = []; end
            
            switch ColorTableTag
                case 'ModelsColorsTable'
                    prefStruct = 'ModelMaterialColors';     % name of the struture in preferences
                case 'LUTColorsTable'
                    prefStruct = 'LUTColors';
            end
            
            if obj.mibModel.getImageProperty('modelType') > 255
                % disable the materials color table for models larger than 255
                obj.View.handles.ModelsColorsTable.Enable = 'off';
                return;
            else
                obj.View.handles.ModelsColorsTable.Enable = 'on';
            end
            
            if ~isempty(options.rowId)
                obj.View.handles.(ColorTableTag).BackgroundColor(options.rowId, :) = obj.preferences.Colors.(prefStruct)(options.rowId,:);
                if obj.View.handles.ScaleToOneCheckBox.Value == 1
                    obj.View.handles.(ColorTableTag).Data(options.rowId, 1:3) = num2cell(obj.preferences.Colors.(prefStruct)(options.rowId,:));
                else
                    obj.View.handles.(ColorTableTag).Data(options.rowId, 1:3) = num2cell(round(obj.preferences.Colors.(prefStruct)(options.rowId,:)*255));
                end
                return;
            end
            
            % add data to table
            if obj.View.handles.ScaleToOneCheckBox.Value == 1
                % scale to 1
                data = obj.preferences.Colors.(prefStruct)(1:min([255, size(obj.preferences.Colors.(prefStruct), 1)]),:);
            else
                % scale to 255
                data = round(obj.preferences.Colors.(prefStruct)(1:min([255, size(obj.preferences.Colors.(prefStruct), 1)]),:) *255);
            end
                
            data = num2cell(data);
            data(:,4) = {''};
            obj.View.handles.(ColorTableTag).Data = data;
            
            if ~options.updateDataOnly
                % define color styles
                origColors = [1 1 1; 0.94 0.94 0.94];
                if ~isempty(obj.preferences.Colors.(prefStruct))
                    obj.View.handles.(ColorTableTag).BackgroundColor = obj.preferences.Colors.(prefStruct);
                end

                removeStyle(obj.View.handles.(ColorTableTag));    % remove current styles

                s1 = uistyle;
                s1.BackgroundColor = origColors(1, :);
                addStyle(obj.View.handles.(ColorTableTag), s1, 'column', 1:3);
            end
            tableWidth = obj.View.handles.(ColorTableTag).Position(3);
            obj.View.handles.(ColorTableTag).ColumnWidth = {tableWidth/4.5, tableWidth/4.5, tableWidth/4.5, 30};
        end
        
        
        function TableCellSelectionCallback(obj, event)
            % function ModelsColorsTableCellSelection(obj, event)
            % callback for selection of a cell in ModelsColorsTable
            % 
            % Paramters:
            % event:  a handle to the event structure
            
            indices = event.Indices;
            sourceTable = event.Source.Tag;     % get tag to the pressed table
            
            obj.View.handles.(sourceTable).UserData = indices;   % store selected position
            if numel(indices) > 2 || indices(2) < 4; return; end
            
            switch sourceTable
                case 'ModelsColorsTable'
                    figTitle = ['Set color for material ' num2str(indices(1))];
                    c = uisetcolor(obj.preferences.Colors.ModelMaterialColors(indices(1),:), figTitle);
                    if sum(ismember(obj.preferences.Colors.ModelMaterialColors(indices(1),:), c)) == 3; return; end
                    obj.preferences.Colors.ModelMaterialColors(indices(1),:) = c;
                    updateColorTableOptions.rowId = indices(1);
                    obj.updateColorsTables('ModelsColorsTable', updateColorTableOptions);
                    
                case 'LUTColorsTable'
                    figTitle = ['Set color for channel ' num2str(indices(1))];
                    c = uisetcolor(obj.preferences.Colors.LUTColors(indices(1),:), figTitle);
                    if sum(ismember(obj.preferences.Colors.LUTColors(indices(1),:), c)) == 3; return; end
                    obj.preferences.Colors.LUTColors(indices(1),:) = c;
                    
                    updateColorTableOptions.rowId = indices(1);
                    obj.updateColorsTables('LUTColorsTable', updateColorTableOptions);
            end
            %obj.View.handles.(sourceTable).BackgroundColor(indices(1),:) = c;
            
        end
        
        function ModelsColorsTableContextMenuCallbacks(obj, event)
            % function ModelsColorsTableContextMenuCallbacks(obj, event)
            % callbacks for the context menu of ModelsColorsTable
            %
            % Paramters:
            % event:  a handle to the event structure
            
            global mibPath;
            
            position = obj.View.handles.ModelsColorsTable.UserData;   % position = [rowIndex, columnIndex]
            sourceTag = event.Source.Tag;     % get tag to the pressed table
            
            if isempty(position) && ismember(sourceTag, ...
                    {'InsertColorMenu', 'ReplaceWithRandomColorMenu', 'SwapTwoColorsMenu', ...
                    'DeleteColorsMenu'})
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nPlease select a row in the table first'), 'Error');
                return;
            end
                
            materialsNumber = numel(obj.mibModel.getImageProperty('modelMaterialNames'));
            rng('shuffle');     % randomize generator
            updateTableOptions.rowId = [];   % update the whole table
            
            switch sourceTag
                case 'ReverseColormapMenu'
                    obj.preferences.Colors.ModelMaterialColors = obj.preferences.Colors.ModelMaterialColors(end:-1:1,:);
                case 'InsertColorMenu'
                    noColors = size(obj.preferences.Colors.ModelMaterialColors, 1);
                    if position(1) == noColors
                        obj.preferences.Colors.ModelMaterialColors = [obj.preferences.Colors.ModelMaterialColors; rand([1,3])];
                    else
                        obj.preferences.Colors.ModelMaterialColors = ...
                            [obj.preferences.Colors.ModelMaterialColors(1:position(1),:); rand([1,3]); obj.preferences.Colors.ModelMaterialColors(position(1)+1:noColors,:)];
                    end
                case 'ReplaceWithRandomColorMenu'
                    obj.preferences.Colors.ModelMaterialColors(position(1),:) = rand([1,3]);
                    updateTableOptions.rowId = position(1); 
                case 'SwapTwoColorsMenu'
                    answer = mibInputDlg({mibPath}, sprintf('Enter a color number to swap with the selected\nSelected: %d', position(1)), 'Swap with', '1');
                    if size(answer) == 0; return; end
                    newIndex = str2double(answer{1});
                    if newIndex > size(obj.preferences.Colors.ModelMaterialColors,1) || newIndex < 1
                        errordlg(sprintf('The entered number is too big or too small\nIt should be between 0-%d', size(obj.preferences.Colors.ModelMaterialColors,1)), 'Wrong value');
                        return;
                    end
                    selectedColor = obj.preferences.Colors.ModelMaterialColors(position(1),:);
                    obj.preferences.Colors.ModelMaterialColors(position(1),:) = obj.preferences.Colors.ModelMaterialColors(newIndex,:);
                    obj.preferences.Colors.ModelMaterialColors(str2double(answer{1}),:) = selectedColor;
                    updateTableOptions.rowId = [position(1), newIndex];
                case 'DeleteColorsMenu'
                    obj.preferences.Colors.ModelMaterialColors(position(:,1),:) = [];
                case 'ImportFromMatlabMenu'
                    % get list of available variables
                    availableVars = evalin('base', 'whos');
                    idx = ismember({availableVars.class}, {'double', 'single'});
                    if sum(idx) == 0
                        errordlg(sprintf('!!! Error !!!\nNothing to import...'), 'Nothing to import');
                        return;
                    end
                    Vars = {availableVars(idx).name}';   
                    % find index of the I variable if it is present
                    idx2 = find(ismember(Vars, 'colormap')==1);
                    if ~isempty(idx2)
                        Vars{end+1} = idx2;
                    end
                    prompts = {sprintf('Input a variable that contains the colormap\n\nIt should be a matrix [colorNumber, [R,G,B]]:')};
                    defAns = {Vars};
                    title = 'Import colormap';
                    mibInputMultiDlgOptions.PromptLines = 3;
                    answer = mibInputMultiDlg({mibPath}, prompts, defAns, title, mibInputMultiDlgOptions);
                    if isempty(answer); return; end
                    
                    try
                        colormap = evalin('base',answer{1});
                    catch exception
                        errordlg(sprintf('The variable was not found in the Matlab base workspace:\n\n%s', exception.message), 'Misssing variable!', 'modal');
                        return;
                    end
                    
                    errorSwitch = 0;
                    if ndims(colormap) ~= 2; errorSwitch = 1;  end %#ok<ISMAT>
                    if size(colormap,2) ~= 3; errorSwitch = 1;  end
                    if max(max(colormap)) > 255 || min(min(colormap)) < 0; errorSwitch = 1;  end
                    
                    if errorSwitch == 1
                        errordlg(sprintf('Wrong format of the colormap!\n\nThe colormap should be a matrix [colorIndex, [R,G,B]],\nwith R,G,B between 0-1 or 0-255'),'Wrong colormap')
                        return;
                    end
                    if max(max(colormap)) > 1   % convert from 0-255 to 0-1
                        colormap = colormap/255;
                    end
                    obj.preferences.Colors.ModelMaterialColors = colormap;
                case 'ExportToMatlabMenu'
                    title = 'Export colormap';
                    prompt = sprintf('Input a destination variable for export\nA matrix containing the current colormap [colorNumber, [R,G,B]] will be assigned to this variable');
                    %answer = inputdlg(prompt,title,[1 30],{'colormap'},'on');
                    answer = mibInputDlg({mibPath}, prompt, title, 'colormap');
                    if size(answer) == 0; return; end
                    
                    assignin('base',answer{1}, obj.preferences.Colors.ModelMaterialColors);
                    fprintf('Colormap export: created variable %s in the Matlab workspace\n', answer{1});
                case 'LoadFromFileMenu'
                    [FileName,PathName] = mib_uigetfile({'*.cmap';'*.mat';'*.*'}, 'Load colormap',...
                        fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename')));
                    if FileName == 0; return; end
                    
                    load(fullfile(PathName, FileName), 'cmap', '-mat');
                    obj.preferences.Colors.ModelMaterialColors = cmap; 
                case 'SaveToFileMenu'
                    [PathName, FileName] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
                    [FileName, PathName] = uiputfile('*.cmap', 'Save colormap', fullfile(PathName, [FileName '.cmap']));
                    if FileName == 0; return; end
                    
                    cmap = obj.preferences.Colors.ModelMaterialColors; 
                    save(fullfile(PathName, FileName), 'cmap');
                    fprintf('MIB: the colormap was saved to %s\n', fullfile(PathName, FileName));
            end
            
            % generate random colors when number of colors less than number of
            % materials
            if size(obj.preferences.Colors.ModelMaterialColors, 1) < materialsNumber
                missingColors = materialsNumber - size(obj.preferences.Colors.ModelMaterialColors, 1);
                obj.preferences.Colors.ModelMaterialColors = [obj.preferences.Colors.ModelMaterialColors; rand([missingColors,3])];
            end
            
            obj.updateColorsTables('ModelsColorsTable', updateTableOptions);
        end
        
        function TableCellEditCallback(obj, event)
            % function TableCellEditCallback(obj, event)
            % callback for modification of cells in tables
            %
            % Paramters:
            % event:  a handle to the event structure
            indices = event.Indices;
            newData = event.NewData;
            
            if obj.View.handles.ScaleToOneCheckBox.Value    % range between 0 and 1
                if newData < 0 || newData > 1
                    uialert(obj.View.gui, sprintf('!!! Error !!!\nThe colors should be in range 0-1'), 'Wrong value');
                    obj.View.handles.(event.Source.Tag).Data(indices(1),indices(2)) = num2cell(event.PreviousData);
                    return;
                end
            else    % range between 0 and 255
                if newData < 0 || newData > 255
                    uialert(obj.View.gui, sprintf('!!! Error !!!\nThe colors should be in range 0-255'), 'Wrong value');
                    obj.View.handles.(event.Source.Tag).Data(indices(1),indices(2)) = num2cell(event.PreviousData);
                    return;
                end
            end
            
            if obj.View.handles.ScaleToOneCheckBox.Value    % range between 0 and 1
                scalingFactor = 1;  % divide the provided value by this factor
            else
                scalingFactor = 255; % divide the provided value by this factor
            end
            
            sourceTable = event.Source.Tag;     % get tag to the pressed table
            switch sourceTable
                case 'ModelsColorsTable'
                    if obj.mibModel.getImageProperty('modelType') > 255; return; end    % do not update for models larger than 255
                    
                    obj.preferences.Colors.ModelMaterialColors(indices(1), indices(2)) = newData/scalingFactor;
                    options.rowId = indices(1);
                    obj.updateColorsTables('ModelsColorsTable', options);
                case 'LUTColorsTable'
                    obj.preferences.Colors.LUTColors(indices(1), indices(2)) = newData/scalingFactor;
                    options.rowId = indices(1);
                    obj.updateColorsTables('LUTColorsTable', options);
            end
            
        end
        
        function ExternalDirSelect(obj, event)
            % function ExternalDirSelect(obj, event)
            % callback for press of select directory button
        
            switch event.Source.Tag
                case 'FijiDirSelectBtn'
                    field_name = 'FijiInstallationPath';
                case 'OmeroDirSelectBtn'
                    field_name = 'OmeroInstallationPath';
                case 'ImarisDirSelectBtn'
                    field_name = 'ImarisInstallationPath';
                case 'BM3DDirSelectBtn'
                    field_name = 'bm3dInstallationPath';
                case 'BM4DDirSelectBtn'
                    field_name = 'bm4dInstallationPath';
                case 'MemoizerDirSelectBtn'
                    field_name = 'BioFormatsMemoizerMemoDir';
                case 'DeepMIBDirSelectBtn'
                    field_name = 'DeepMIBDir';
            end
            
            folder_name = uigetdir(obj.preferences.ExternalDirs.(field_name), 'Select directory');
            if folder_name==0; return; end
            % the two following commands are fix of sending the DeepMIB
            % window behind main MIB window
            drawnow;
            figure(obj.View.gui);
            
            if strcmp(field_name, 'bm3dInstallationPath') || strcmp(field_name, 'bm4dInstallationPath')
                answer = uiconfirm(obj.View.gui, ...
                    sprintf('!!! Warning !!!\n\nPlease note that any unauthorized use of BM3D and BM4D filters for industrial or profit-oriented activities is expressively prohibited!'), ...
                    'License warning', 'Options', {'Acknowledge', 'Cancel'}, 'Icon', 'warning', 'DefaultOption', 1);
                if strcmp(answer, 'Cancel')
                    folder_name = '';
                end
            end
            obj.preferences.ExternalDirs.(field_name) = folder_name;
            obj.View.handles.(field_name).Value = folder_name;
        end
        
        function ExternalDirPathChange(obj, event)
            % function ExternalDirPathChange(obj, event)
            % update of external directories
            
            if ~isempty(obj.View.handles.(event.Source.Tag).Value)
                if exist(obj.View.handles.(event.Source.Tag).Value) ~= 7 %#ok<EXIST> % keep exists function here, for correct work with /Applications/Fiji.app 
                    uialert(obj.View.gui, ...
                        sprintf('!!! Warning !!!\n\nThe directory\n%s\nis missing', obj.View.handles.(event.Source.Tag).Value),...
                        'Wrong directory');
                    obj.View.handles.(event.Source.Tag).Value = char(obj.preferences.ExternalDirs.(event.Source.Tag));
                else
                    if strcmp(event.Source.Tag, 'bm3dInstallationPath') || strcmp(event.Source.Tag, 'bm4dInstallationPath')
                        answer = uiconfirm(obj.View.gui, ...
                            sprintf('!!! Warning !!!\n\nPlease note that any unauthorized use of BM3D and BM4D filters for industrial or profit-oriented activities is expressively prohibited!'), ...
                            'License warning', 'Options', {'Acknowledge', 'Cancel'}, 'Icon', 'warning', 'DefaultOption', 1);
                        if strcmp(answer, 'Cancel')
                            obj.View.handles.(event.Source.Tag).Value = '';
                        end
                    end
                    obj.preferences.ExternalDirs.(event.Source.Tag) = obj.View.handles.(event.Source.Tag).Value;
                end
            else
                obj.preferences.ExternalDirs.(event.Source.Tag) = [];
            end
        end
        
        function updateKeyShortcut(obj, eventdata)
            % function updateKeyShortcut(obj, event)
            % callback for change of key shortcuts in the table
            % obj.View.handles.shortcutsTable
            
            index = eventdata.Indices(1);
            data = obj.View.handles.shortcutsTable.Data;    % have to take the whole table as looking for duplicates
            
            % make it impossible to change Shift action for some actions
            if ismember(data(index, 2), obj.preferences.KeyShortcuts.Action(6:16))
                data(index, 4) = num2cell(false);
                obj.View.handles.shortcutsTable.Data = data;
            end
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
                    
                    button = uiconfirm(obj.View.gui, ...
                        sprintf('!!! Warning !!!\n\nA duplicate entry was found in the list of shortcuts!\nThe keystroke "%s" is already assigned to action number "%d"\n"%s"\n\nContinue anyway?', data{index, 3}, actionId(1), data{actionId(1), 2}),...
                        'Duplicate found!',...
                        'Options', {'Continue','Cancel'},'DefaultOption', 2, ...
                        'Icon','warning');
                    
                    if strcmp(button, 'Cancel')
                        data(index, eventdata.Indices(2)) = {eventdata.PreviousData};
                    else
                        obj.duplicateEntries = [obj.duplicateEntries ActionId];     % add index of a duplicate entry
                        obj.duplicateEntries = unique(obj.duplicateEntries);     % add index of a duplicate entry
                        
                        s = uistyle('BackgroundColor','red');
                        addStyle(obj.View.handles.shortcutsTable, s, 'cell', [ActionId', ones([numel(ActionId) 1])]);
                    end
                else
                    obj.duplicateEntries(obj.duplicateEntries==ActionId) = [];  % remove possible diplicate
                    s = uistyle('BackgroundColor', 'green');
                    if numel(obj.duplicateEntries) < 2
                        obj.duplicateEntries =[];
                        removeStyle(obj.View.handles.shortcutsTable);
                        addStyle(obj.View.handles.shortcutsTable, s, 'column', 1);
                    else
                        addStyle(obj.View.handles.shortcutsTable, s, 'cell', [index, 1]);
                    end
                end
            else
                obj.duplicateEntries(obj.duplicateEntries == index) = [];  % remove possible diplicate
                s = uistyle('BackgroundColor', 'green');
                if numel(obj.duplicateEntries) < 2
                    obj.duplicateEntries =[];
                    removeStyle(obj.View.handles.shortcutsTable);
                    addStyle(obj.View.handles.shortcutsTable, s, 'column', 1);
                else
                    addStyle(obj.View.handles.shortcutsTable, s, 'cell', [index, 1]);
                end
            end
            obj.View.handles.shortcutsTable.Data = data;
        end
        
        % ------------------------------------------------------------------
        % % Additional functions and callbacks
        function Calculate(obj)
            % start main calculation of the plugin
            
            % redraw the image if needed
            notify(obj.mibModel, 'plotImage');
            
        end
        
        
    end
end