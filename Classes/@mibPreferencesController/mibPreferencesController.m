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

classdef mibPreferencesController < handle
    % classdef mibPreferencesController < handle
    % a controller class for the MIB Preferences dialog
        
    properties
        mibController
        % a handle to mibController class
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        oldPreferences
        % stored old preferences
        preferences
        % local copy of MIB preferences
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback(obj, src, evnt)
            switch src.Name
                case 'Id'
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibPreferencesController(mibModel, mibController)
            obj.mibModel = mibModel;    % assign model
            obj.mibController = mibController;
            obj.preferences = mibModel.preferences;
            obj.oldPreferences = mibModel.preferences;
                        
            % update current preferences using those taken from dataset
            % logic for disable selection: it is always taken from the
            % currently shown dataset. The datasets are initialzed during
            % MIB startup with the settings in the preferences
            obj.preferences.System.EnableSelection = obj.mibModel.I{obj.mibModel.Id}.enableSelection;
            
            guiName = 'mibPreferencesGUI';  % an old guide version
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            obj.updateWidgets();
            obj.View.gui.WindowStyle = 'modal';     % make window modal
            
            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'Id', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
        end
        
        function closeWindow(obj)
            % closing mibPreferencesController window
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
            % update widgets of the window
            
            % update widgets
            if strcmp(obj.preferences.System.MouseWheel, 'zoom')   % zoom or scroll
                obj.View.handles.mouseWheelPopup.Value = 1;
            else
                obj.View.handles.mouseWheelPopup.Value = 2;
            end
            if strcmp(obj.preferences.System.LeftMouseButton, 'pan')   % pan or select
                obj.View.handles.mouseButtonPopup.Value = 1;
            else
                obj.View.handles.mouseButtonPopup.Value = 2;
            end
            
            if obj.preferences.Undo.Enable == 1
                obj.View.handles.undoPopup.Value = 1;
                obj.View.handles.maxUndoHistory.Enable = 'on';
                obj.View.handles.max3dUndoHistory.Enable = 'on';
            else
                obj.View.handles.undoPopup.Value = 2;
                obj.View.handles.maxUndoHistory.Enable = 'off';
                obj.View.handles.max3dUndoHistory.Enable = 'off';
            end
            
            if strcmp(obj.preferences.System.ImageResizeMethod, 'auto')    % auto
                obj.View.handles.imresizePopup.Value = 1;
            elseif strcmp(obj.preferences.System.ImageResizeMethod, 'nearest')    % nearest or bicubic
                obj.View.handles.imresizePopup.Value = 2;
            else
                obj.View.handles.imresizePopup.Value = 3;
            end
            
            if obj.mibModel.I{obj.mibModel.Id}.enableSelection == 1
                obj.View.handles.disableSelectionPopup.Value = 1;
            else
                obj.View.handles.disableSelectionPopup.Value = 2;
            end
            if strcmp(obj.preferences.SegmTools.Interpolation.Type, 'line')    % line or shape
                obj.View.handles.interpolationTypePopup.Value = 2;
                obj.View.handles.interpolationLineWidth.Enable = 'on';
            end
            
            obj.View.handles.annotationFontSizeCombo.Value = obj.preferences.SegmTools.Annotations.FontSize;
            obj.View.handles.fontSizeDirEdit.String = num2str(obj.preferences.System.FontSizeDirView);
            obj.View.handles.fontSizeEdit.String = num2str(obj.preferences.System.Font.FontSize);
            
            obj.View.handles.maxUndoHistory.String = num2str(obj.preferences.Undo.MaxUndoHistory);
            obj.View.handles.max3dUndoHistory.String = num2str(obj.preferences.Undo.Max3dUndoHistory);
            obj.View.handles.interpolationNoPoints.String = num2str(obj.preferences.SegmTools.Interpolation.NoPoints);
            obj.View.handles.interpolationLineWidth.String = num2str(obj.preferences.SegmTools.Interpolation.LineWidth);
            
            obj.View.handles.annotationColorBtn.BackgroundColor = obj.preferences.SegmTools.Annotations.Color;
            obj.View.handles.colorMaskBtn.BackgroundColor = obj.preferences.Colors.MaskColor;
            obj.View.handles.colorSelectionBtn.BackgroundColor = obj.preferences.Colors.SelectionColor;
            
            % updating options for color palettes
            if obj.mibModel.getImageProperty('modelType') < 256
                materialsNumber = numel(obj.mibModel.getImageProperty('modelMaterialNames'));
            else
                materialsNumber = obj.mibModel.getImageProperty('modelType');
            end
            
            if materialsNumber > 12
                paletteList = {'Distinct colors, 20 colors', 'Matlab Jet','Matlab Gray','Matlab Bone','Matlab HSV', 'Matlab Cool', 'Matlab Hot','Random Colors'};
                obj.View.handles.paletteTypePopup.String = paletteList;
            elseif materialsNumber > 11
                paletteList = {'Distinct colors, 20 colors', 'Qualitative (Monte Carlo->Half Baked), 3-12 colors','Matlab Jet','Matlab Gray','Matlab Bone','Matlab HSV', 'Matlab Cool', 'Matlab Hot','Random Colors'};
                obj.View.handles.paletteTypePopup.String = paletteList;
            elseif materialsNumber > 9
                paletteList = {'Distinct colors, 20 colors', 'Qualitative (Monte Carlo->Half Baked), 3-12 colors','Diverging (Deep Bronze->Deep Teal), 3-11 colors','Diverging (Ripe Plum->Kaitoke Green), 3-11 colors',...
                    'Diverging (Bordeaux->Green Vogue), 3-11 colors, 3-11 colors', 'Diverging (Carmine->Bay of Many), 3-11 colors',...
                    'Matlab Jet','Matlab Gray','Matlab Bone','Matlab HSV', 'Matlab Cool', 'Matlab Hot','Random Colors'};
                obj.View.handles.paletteTypePopup.String = paletteList;
            elseif materialsNumber > 6
                paletteList = {'Distinct colors, 20 colors', 'Qualitative (Monte Carlo->Half Baked), 3-12 colors','Diverging (Deep Bronze->Deep Teal), 3-11 colors','Diverging (Ripe Plum->Kaitoke Green), 3-11 colors',...
                    'Diverging (Bordeaux->Green Vogue), 3-11 colors, 3-11 colors', 'Diverging (Carmine->Bay of Many), 3-11 colors','Sequential (Kaitoke Green), 3-9 colors',...
                    'Sequential (Catalina Blue), 3-9 colors', 'Sequential (Maroon), 3-9 colors', 'Sequential (Astronaut Blue), 3-9 colors', 'Sequential (Downriver), 3-9 colors',...
                    'Matlab Jet','Matlab Gray','Matlab Bone','Matlab HSV', 'Matlab Cool', 'Matlab Hot','Random Colors'};
                obj.View.handles.paletteTypePopup.String = paletteList;
            else
                paletteList = {'Default, 6 colors', 'Distinct colors, 20 colors', 'Qualitative (Monte Carlo->Half Baked), 3-12 colors','Diverging (Deep Bronze->Deep Teal), 3-11 colors','Diverging (Ripe Plum->Kaitoke Green), 3-11 colors',...
                    'Diverging (Bordeaux->Green Vogue), 3-11 colors', 'Diverging (Carmine->Bay of Many), 3-11 colors','Sequential (Kaitoke Green), 3-9 colors',...
                    'Sequential (Catalina Blue), 3-9 colors', 'Sequential (Maroon), 3-9 colors', 'Sequential (Astronaut Blue), 3-9 colors', 'Sequential (Downriver), 3-9 colors',...
                    'Matlab Jet','Matlab Gray','Matlab Bone','Matlab HSV', 'Matlab Cool', 'Matlab Hot', 'Random Colors'};
                obj.View.handles.paletteTypePopup.String = paletteList;
            end
            
            % adding colors to the materials color table
            obj.updateModelColorTable();
            
            % adding colors to the LUT color table for color channels
            obj.updateLUTColorTable();
        end
        
        function paletteTypePopup_Callback(obj)
            % function paletteTypePopup_Callback(obj)
            % update palette colors, obj.View.handles.paletteColorNumberPopup
            global mibPath;
            
            selectedVal = obj.View.handles.paletteTypePopup.Value;
            paletteList = obj.View.handles.paletteTypePopup.String;
            if ischar(paletteList); paletteList = cellstr(paletteList); end
            
            obj.View.handles.paletteColorNumberPopup.Value = 1;
            
            materialsNumber = numel(obj.mibModel.getImageProperty('modelMaterialNames'));
            
            switch paletteList{selectedVal}
                case 'Default, 6 colors'
                    obj.View.handles.paletteColorNumberPopup.String = '6';
                case 'Distinct colors, 20 colors'
                    obj.View.handles.paletteColorNumberPopup.String = '20';
                case 'Qualitative (Monte Carlo->Half Baked), 3-12 colors'
                    obj.View.handles.paletteColorNumberPopup.String = num2cell(max([3, materialsNumber]):12);
                case 'Diverging (Deep Bronze->Deep Teal), 3-11 colors'
                    obj.View.handles.paletteColorNumberPopup.String = num2cell(max([3, materialsNumber]):11);
                case 'Diverging (Ripe Plum->Kaitoke Green), 3-11 colors'
                    obj.View.handles.paletteColorNumberPopup.String = num2cell(max([3, materialsNumber]):11);
                case 'Diverging (Bordeaux->Green Vogue), 3-11 colors'
                    obj.View.handles.paletteColorNumberPopup.String = num2cell(max([3, materialsNumber]):11);
                case 'Diverging (Carmine->Bay of Many), 3-11 colors'
                    obj.View.handles.paletteColorNumberPopup.String = num2cell(max([3, materialsNumber]):11);
                case 'Sequential (Kaitoke Green), 3-9 colors'
                    obj.View.handles.paletteColorNumberPopup.String = num2cell(max([3, materialsNumber]):9);
                case 'Sequential (Catalina Blue), 3-9 colors'
                    obj.View.handles.paletteColorNumberPopup.String = num2cell(max([3, materialsNumber]):9);
                case 'Sequential (Maroon), 3-9 colors'
                    obj.View.handles.paletteColorNumberPopup.String = num2cell(max([3, materialsNumber]):9);
                case 'Sequential (Astronaut Blue), 3-9 colors'
                    obj.View.handles.paletteColorNumberPopup.String = num2cell(max([3, materialsNumber]):9);
                case 'Sequential (Downriver), 3-9 colors'
                    obj.View.handles.paletteColorNumberPopup.String = num2cell(max([3, materialsNumber]):9);
                case {'Matlab Jet','Matlab Gray','Matlab Bone','Matlab HSV', 'Matlab Cool', 'Matlab Hot', 'Random Colors'}
                    answer = mibInputDlg({mibPath}, sprintf('Please enter number of colors\n(max. value is %d)', obj.mibModel.getImageProperty('modelType')), 'Define number of colors', num2str(max(materialsNumber, 6)));
                    if isempty(answer); return; end
                    noColors = str2double(answer{1});
                    obj.View.handles.paletteColorNumberPopup.String = num2cell(noColors);
            end
            obj.updateColorPalette();
        end
        
        function updateColorPalette(obj)
            % function updateColorPalette(obj)
            % generate default colors for the selected palette
            
            % update color palette based on selected parameters in the paletteTypePopup and paletteColorNumberPopup popups
            selectedVal = obj.View.handles.paletteTypePopup.Value;
            paletteList = obj.View.handles.paletteTypePopup.String;
            if ischar(paletteList); paletteList = cellstr(paletteList); end
            
            colorList = obj.View.handles.paletteColorNumberPopup.String;
            colorVal = obj.View.handles.paletteColorNumberPopup.Value;
            if iscell(colorList)
                colorsNo = str2double(colorList{colorVal});
            else
                colorsNo = str2double(colorList);
            end
			
            obj.preferences.Colors.ModelMaterialColors = mibGenerateDefaultSegmentationPalette(paletteList{selectedVal}, colorsNo);
            obj.updateModelColorTable();
        end
        
        function updateModelColorTable(obj)
            % function updateModelColorTable(obj)
            % update the obj.View.handles.modelsColorsTable with palette colors
            
            if obj.mibModel.getImageProperty('modelType') > 255
                % disable the materials color table for models larger than 255
                obj.View.handles.modelsColorsTable.Enable = 'off';
                return; 
            else
                obj.View.handles.modelsColorsTable.Enable = 'on';
            end    
            
            % position: define the row to be selected
            colergen = @(color,text) ['<html><table border=0 width=40 bgcolor=',color,'><TR><TD>',text,'</TD></TR> </table></html>'];
            modelMaterialColors_local = obj.preferences.Colors.ModelMaterialColors(1:min([255, size(obj.preferences.Colors.ModelMaterialColors, 1)]),:);
            data = cell([size(modelMaterialColors_local, 1), 4]);
            for colorId = 1:size(modelMaterialColors_local, 1)
                data{colorId, 1} = round(modelMaterialColors_local(colorId, 1)*255);
                data{colorId, 2} = round(modelMaterialColors_local(colorId, 2)*255);
                data{colorId, 3} = round(modelMaterialColors_local(colorId, 3)*255);
                data{colorId, 4} = colergen(sprintf('''rgb(%d, %d, %d)''', ...
                    round(modelMaterialColors_local(colorId, 1)*255), round(modelMaterialColors_local(colorId, 2)*255), round(modelMaterialColors_local(colorId, 3)*255)),'&nbsp;');  % rgb(0,255,0)
            end
            obj.View.handles.modelsColorsTable.Data = data;
            obj.View.handles.modelsColorsTable.ColumnWidth = {39 40 39 32};
        end
        
        function updateLUTColorTable(obj)
            % adding colors to the color table for the color channels LUT
            
            colergen = @(color,text) ['<html><table border=0 width=40 bgcolor=',color,'><TR><TD>',text,'</TD></TR> </table></html>'];
            data = cell([size(obj.preferences.Colors.LUTColors, 1), 4]);
            for colorId = 1:size(obj.preferences.Colors.LUTColors, 1)
                data{colorId, 1} = round(obj.preferences.Colors.LUTColors(colorId, 1)*255);
                data{colorId, 2} = round(obj.preferences.Colors.LUTColors(colorId, 2)*255);
                data{colorId, 3} = round(obj.preferences.Colors.LUTColors(colorId, 3)*255);
                data{colorId, 4} = colergen(sprintf('''rgb(%d, %d, %d)''', ...
                    round(obj.preferences.Colors.LUTColors(colorId, 1)*255), round(obj.preferences.Colors.LUTColors(colorId, 2)*255), round(obj.preferences.Colors.LUTColors(colorId, 3)*255)),'&nbsp;');  % rgb(0,255,0)
            end
            obj.View.handles.lutColorsTable.Data = data;
            obj.View.handles.lutColorsTable.ColumnWidth = {39 40 39 32};
        end
        
        function applyBtn_Callback(obj)
            % function applyBtn_Callback(obj)
            % apply preferences
            global Font;
            
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
            
            % update font size
            obj.preferences.System.FontSizeDirView = str2double(obj.View.handles.fontSizeDirEdit.String);
            obj.mibController.mibView.handles.mibFilesListbox.FontSize = obj.preferences.System.FontSizeDirView;
            Font = obj.preferences.System.Font;
            
            if obj.mibController.mibView.handles.mibZoomText.FontSize ~= obj.preferences.System.Font.FontSize || ...
                    ~strcmp(obj.mibController.mibView.handles.mibZoomText.FontName, obj.preferences.System.Font.FontName)
                mibUpdateFontSize(obj.mibController.mibView.gui, obj.preferences.System.Font);
                mibUpdateFontSize(obj.View.gui, obj.preferences.System.Font);
            end
            obj.mibModel.preferences = obj.preferences;
            
            obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors = obj.preferences.Colors.ModelMaterialColors;
            obj.mibModel.I{obj.mibModel.Id}.lutColors = obj.preferences.Colors.LUTColors;
            
            obj.mibController.toolbarInterpolation_ClickedCallback('keepcurrent');     % update the interpolation button icon
            obj.mibController.toolbarResizingMethod_ClickedCallback('keepcurrent');
            
            % update imaris path using IMARISPATH enviromental variable
            if ~isempty(obj.mibModel.preferences.ExternalDirs.ImarisInstallationPath)
                setenv('IMARISPATH', obj.mibModel.preferences.ExternalDirs.ImarisInstallationPath);
            end
            
            notify(obj.mibModel, 'plotImage');
        end
        
        function OKBtn_Callback(obj)
            % function OKBtn_Callback(obj)
            % callback for press of obj.View.handles.OKBtn
            obj.applyBtn_Callback();
            
            obj.mibModel.setImageProperty('modelMaterialColors', obj.preferences.Colors.ModelMaterialColors);
            obj.mibModel.setImageProperty('lutColors', obj.preferences.Colors.LUTColors);
            
            if obj.mibModel.preferences.Undo.Enable == 0
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
                else
                    obj.mibModel.I{obj.mibModel.Id}.selection{1} = NaN;
                end
                obj.mibModel.U.clearContents();  % delete backup history
            end
            obj.mibModel.I{obj.mibModel.Id}.enableSelection = obj.preferences.System.EnableSelection;
            
            % remove the brush cursor
            obj.mibController.mibSegmentationToolPopup_Callback();
            obj.mibController.updateGuiWidgets();
            
            obj.mibController.toolbarInterpolation_ClickedCallback('keepcurrent');     % update the interpolation button icon
            obj.mibController.toolbarResizingMethod_ClickedCallback('keepcurrent');
            
            notify(obj.mibModel, 'plotImage');
            obj.closeWindow();
            
        end
        
        function mouseWheelPopup_Callback(obj)
            % function mouseWheelPopup_Callback()
            % callback for change of obj.View.handles.mouseWheelPopup
            list = obj.View.handles.mouseWheelPopup.String;
            obj.preferences.System.MouseWheel = list{obj.View.handles.mouseWheelPopup.Value};
        end
        
        function mouseButtonPopup_Callback(obj)
            % function mouseButtonPopup_Callback(obj)
            % callback for change of obj.View.handles.mouseButtonPopup
            list = obj.View.handles.mouseButtonPopup.String;
            obj.preferences.System.LeftMouseButton = list{obj.View.handles.mouseButtonPopup.Value};
        end
        
        
        function undoPopup_Callback(obj)
            % function undoPopup_Callback(obj)
            % callback for change of obj.View.handles.undoPopup
            
            list = obj.View.handles.undoPopup.String;
            if strcmp(list{obj.View.handles.undoPopup.Value}, 'yes')
                obj.preferences.Undo.Enable = 1;
            else
                obj.preferences.Undo.Enable = 0;
            end
            
            if obj.preferences.Undo.Enable == 0
                obj.View.handles.maxUndoHistory.Enable = 'off';
                obj.View.handles.max3dUndoHistory.Enable = 'off';
            else
                obj.View.handles.maxUndoHistory.Enable = 'on';
                obj.View.handles.max3dUndoHistory.Enable = 'on';
            end
        end
        
        function imresizePopup_Callback(obj)
            % function imresizePopup_Callback(obj)
            % callback for change of obj.View.handles.imresizePopup
            list = obj.View.handles.imresizePopup.String;
            obj.preferences.System.ImageResizeMethod = list{obj.View.handles.imresizePopup.Value};
        end
        
        function colorSelectionBtn_Callback(obj)
            % function colorSelectionBtn_Callback(obj)
            % callback for press of obj.View.handles.colorSelectionBtn
            % set color for the selection layer
            sel_color = obj.preferences.Colors.SelectionColor;
            c = uisetcolor(sel_color, 'Select Selection color');
            if length(c) == 1; return; end
            obj.preferences.Colors.SelectionColor = c;
            obj.View.handles.colorSelectionBtn.BackgroundColor = obj.preferences.Colors.SelectionColor;
        end
        
        function colorMaskBtn_Callback(obj)
            % function colorMaskBtn_Callback(obj)
            % callback for press of obj.View.handles.colorMaskBtn
            % set color for the mask layer
            
            sel_color = obj.preferences.Colors.MaskColor;
            c = uisetcolor(sel_color, 'Select Selection color');
            if length(c) == 1; return; end
            obj.preferences.Colors.MaskColor = c;
            obj.View.handles.colorMaskBtn.BackgroundColor = obj.preferences.Colors.MaskColor;
        end
        
        function colorModelSelection_Callback(obj)
            % function colorModelSelection_Callback(obj)
            % callback for selection of colors in obj.View.handles.modelsColorsTable
            
            position = obj.View.handles.modelsColorsTable.UserData;
            if isempty(position)
                msgbox(sprintf('Error!\nPlease select a row in the table first'), 'Error!', 'error', 'modal');
                return;
            end
            figTitle = ['Set color for material ' num2str(position(1))];
            c = uisetcolor(obj.preferences.Colors.ModelMaterialColors(position(1),:), figTitle);
            if length(c) == 1; return; end
            obj.preferences.Colors.ModelMaterialColors(position(1),:) = c;
            obj.updateModelColorTable();
        end
        
        function modelsColorsTable_cb(obj, parameter)
            % function modelsColorsTable_cb(obj, parameter)
            % callback for context menu of obj.View.handles.modelsColorsTable
            global mibPath;
            
            position = obj.View.handles.modelsColorsTable.UserData;   % position = [rowIndex, columnIndex]
            if isempty(position) && (~strcmp(parameter, 'reverse') && ~strcmp(parameter, 'import') && ~strcmp(parameter, 'export') ...
                    && ~strcmp(parameter, 'load') && ~strcmp(parameter, 'save'))
                msgbox(sprintf('Error!\nPlease select a row in the table first'), 'Error!', 'error', 'modal');
                return;
            end
            
            materialsNumber = numel(obj.mibModel.getImageProperty('modelMaterialNames'));
            rng('shuffle');     % randomize generator
            
            switch parameter
                case 'reverse'  % reverse the colormap
                    obj.preferences.Colors.ModelMaterialColors = obj.preferences.Colors.ModelMaterialColors(end:-1:1,:);
                case 'insert'
                    noColors = size(obj.preferences.Colors.ModelMaterialColors, 1);
                    if position(1) == noColors
                        obj.preferences.Colors.ModelMaterialColors = [obj.preferences.Colors.ModelMaterialColors; rand([1,3])];
                    else
                        obj.preferences.Colors.ModelMaterialColors = ...
                            [obj.preferences.Colors.ModelMaterialColors(1:position(1),:); rand([1,3]); obj.preferences.Colors.ModelMaterialColors(position(1)+1:noColors,:)];
                    end
                case 'random'   % generate a random color
                    obj.preferences.Colors.ModelMaterialColors(position(1),:) = rand([1,3]);
                case 'swap'     % swap two colors
                    answer = mibInputDlg({mibPath}, sprintf('Enter a color number to swap with the selected\nSelected: %d', position(1)), 'Swap with', '1');
                    if size(answer) == 0; return; end
                    
                    tableContents = obj.View.handles.modelsColorsTable.Data;
                    newIndex = str2double(answer{1});
                    if newIndex > size(tableContents,1) || newIndex < 1
                        errordlg(sprintf('The entered number is too big or too small\nIt should be between 0-%d', size(tableContents,1)), 'Wrong value');
                        return;
                    end
                    selectedColor = obj.preferences.Colors.ModelMaterialColors(position(1),:);
                    obj.preferences.Colors.ModelMaterialColors(position(1),:) = obj.preferences.Colors.ModelMaterialColors(newIndex,:);
                    obj.preferences.Colors.ModelMaterialColors(str2double(answer{1}),:) = selectedColor;
                case 'delete'   % delete selected color
                    obj.preferences.Colors.ModelMaterialColors(position(:,1),:) = [];
                case 'import'   % import color from matlab workspace
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
                case 'export'       % export color to Matlab workspace
                    title = 'Export colormap';
                    prompt = sprintf('Input a destination variable for export\nA matrix containing the current colormap [colorNumber, [R,G,B]] will be assigned to this variable');
                    %answer = inputdlg(prompt,title,[1 30],{'colormap'},'on');
                    answer = mibInputDlg({mibPath}, prompt, title, 'colormap');
                    if size(answer) == 0; return; end
                    assignin('base',answer{1}, obj.preferences.Colors.ModelMaterialColors);
                    disp(['Colormap export: created variable ' answer{1} ' in the Matlab workspace']);
                case 'load'
                    [fileName, pathName] = mib_uigetfile({'*.cmap';'*.mat';'*.*'}, 'Load colormap',...
                        fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename')));
                    if isequal(fileName, 0); return; end
                    load(fullfile(pathName, fileName{1}), '-mat'); %#ok<LOAD>
                    obj.preferences.Colors.ModelMaterialColors = cmap; %#ok<NODEF>
                case 'save'
                    [pathName, fileName] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
                    [fileName, pathName] = uiputfile('*.cmap', 'Save colormap', fullfile(pathName, [fileName '.cmap']));
                    if fileName == 0; return; end
                    cmap = obj.preferences.Colors.ModelMaterialColors; %#ok<NASGU>
                    save(fullfile(pathName, fileName), 'cmap');
                    disp(['MIB: the colormap was saved to ' fullfile(pathName, fileName)]);
            end
            
            % generate random colors when number of colors less than number of
            % materials
            if size(obj.preferences.Colors.ModelMaterialColors, 1) < materialsNumber
                missingColors = materialsNumber - size(obj.preferences.Colors.ModelMaterialColors, 1);
                obj.preferences.Colors.ModelMaterialColors = [obj.preferences.Colors.ModelMaterialColors; rand([missingColors,3])];
            end
            
            obj.updateModelColorTable();
        end
        
        function modelsColorsTable_CellEditCallback(obj, eventdata)
            % function modelsColorsTable_CellEditCallback(obj, eventdata)
            % callback for cell edit in obj.View.handles.modelsColorsTable
            %
            % Parameters:
            % eventdata: structure with selected cell index
            
            if obj.mibModel.getImageProperty('modelType') > 255; return; end    % do not update for models larger than 255
            
            if eventdata.NewData < 0 || eventdata.NewData > 255
                msgbox(sprintf('Error!\nThe colors should be in range 0-255'), 'Error!', 'error', 'modal');
                obj.updateModelColorTable();
                return;
            end
            
            obj.preferences.Colors.ModelMaterialColors(eventdata.Indices(1), eventdata.Indices(2)) = eventdata.NewData/255;
            obj.updateModelColorTable();
        end
        
        function lutColorsTable_CellEditCallback(obj, eventdata)
            % function lutColorsTable_CellEditCallback(obj, eventdata)
            % callback for cell edit in obj.View.handles.lutColorsTable
            %
            % Parameters:
            % eventdata: structure with selected cell index
            if eventdata.NewData < 0 || eventdata.NewData > 255
                msgbox(sprintf('Error!\nThe colors should be in range 0-255'),'Error!','error','modal');
                obj.updateLUTColorTable();
                return;
            end
            
            obj.preferences.Colors.LUTColors(eventdata.Indices(1), eventdata.Indices(2)) = (eventdata.NewData)/255;
            obj.updateLUTColorTable();
        end
        
        function undoHistory_Callback(obj)
            % function undoHistory_Callback(obj)
            % callback for change undo history
            val = str2double(obj.View.handles.maxUndoHistory.String);
            val2 = str2double(obj.View.handles.max3dUndoHistory.String);
            if val < 1
                msgbox(sprintf('Error!\nThe minimal total number of history steps is 1'),'Error!','error','modal');
                obj.View.handles.maxUndoHistory.String = num2str(obj.preferences.Undo.MaxUndoHistory);
                return;
            end
            if val2 < 0
                msgbox(sprintf('Error!\nThe minimal total number of 3D history steps is 0'),'Error!','error','modal');
                obj.View.handles.maxUndoHistory.String = num2str(handles.preferences.max2dUndoHistory);
                return;
            end
            
            if val2 > val
                msgbox(sprintf('Error!\nThe number of 3D history steps should be lower or equal than total number of steps'),'Error!','error','modal');
                obj.View.handles.maxUndoHistory.String = num2str(obj.preferences.Undo.MaxUndoHistory);
                obj.View.handles.max3dUndoHistory.String = num2str(obj.preferences.Undo.Max3dUndoHistory);
                return;
            end
            obj.preferences.Undo.MaxUndoHistory = val;
            obj.preferences.Undo.Max3dUndoHistory = val2;
        end
        
        function disableSelectionPopup_Callback(obj)
            % function disableSelectionPopup_Callback(obj)
            % callback for selection of obj.View.handles.disableSelectionPopup
            value = obj.View.handles.disableSelectionPopup.Value;
            if value == 2   % yes
                button = questdlg(sprintf('!!! Warning !!!\nDisabling of the Selection layer delete the Model and Mask layers!!!\n\nAre you sure?'), 'Model will be removed!', 'Continue', 'Cancel', 'Cancel');
                if strcmp(button, 'Cancel')
                    obj.View.handles.disableSelectionPopup.Value = 1;
                    return;
                end
                obj.preferences.System.EnableSelection = 0;
            else
                obj.preferences.System.EnableSelection = 1;
            end
        end
        
        function interpolationTypePopup_Callback(obj)
            % function interpolationTypePopup_Callback(obj)
            % callback for change of obj.View.handles.interpolationTypePopup
            
            value = obj.View.handles.interpolationTypePopup.Value;
            if value == 1   % shape interpolation
                obj.preferences.SegmTools.Interpolation.Type = 'shape';
                obj.View.handles.interpolationLineWidth.Enable = 'off';
            else            % line interpolation
                obj.preferences.SegmTools.Interpolation.Type = 'line';
                obj.View.handles.interpolationLineWidth.Enable = 'on';
            end
        end
        
        function interpolationNoPoints_Callback(obj)
            % function interpolationNoPoints_Callback(obj)
            % callback for change of obj.View.handles.interpolationNoPoints
            val = str2double(obj.View.handles.interpolationNoPoints.String);
            if val < 1
                msgbox(sprintf('Error!\nThe minimal number of interpolation points is 1'), 'Error!', 'error', 'modal');
                obj.View.handles.interpolationNoPoints.String = num2str(obj.preferences.SegmTools.Interpolation.NoPoints);
                return;
            end
            obj.preferences.SegmTools.Interpolation.NoPoints = val;
        end
        
        function interpolationLineWidth_Callback(obj)
            % function interpolationLineWidth_Callback(obj)
            % callback for change of obj.View.handles.interpolationLineWidth
            val = str2double(obj.View.handles.interpolationLineWidth.String);
            if val < 1
                msgbox(sprintf('Error!\nThe minimal number of the line width is 1'), 'Error!', 'error', 'modal');
                obj.View.handles.interpolationLineWidth.String = num2str(obj.preferences.SegmTools.Interpolation.LineWidth);
                return;
            end
            obj.preferences.SegmTools.Interpolation.LineWidth = val;
        end
        
        function colorChannelSelection_Callback(obj)
            % function colorChannelSelection_Callback(obj)
            % callback for change of obj.View.handles.lutColorsTable
            % selection of color stripe in the Color channels table
            
            position = obj.View.handles.lutColorsTable.UserData;
            if isempty(position)
                msgbox(sprintf('Error!\nPlease select a row in the table first'), 'Error!', 'error', 'modal');
                return;
            end
            figTitle = ['Set color for channel ' num2str(position(1))];
            c = uisetcolor(obj.preferences.Colors.LUTColors(position(1),:), figTitle);
            if length(c) == 1; return; end
            obj.preferences.Colors.LUTColors(position(1),:) = c;
            obj.updateLUTColorTable();
        end
        
        function fontSizeEdit_Callback(obj)
            % function fontSizeEdit_Callback(obj)
            % callback for change of obj.View.handles.fontSizeEdit
            % update font size for mibPreferencesGUI
            obj.preferences.System.Font.FontSize = str2double(obj.View.handles.fontSizeEdit.String);
        end
        
        function annotationColorBtn_Callback(obj)
            % function annotationColorBtn_Callback(obj)
            % callback for press of obj.View.handles.annotationColorBtn
            
            sel_color = obj.preferences.SegmTools.Annotations.Color;
            c = uisetcolor(sel_color, 'Select color for annotations');
            if length(c) == 1; return; end
            obj.preferences.SegmTools.Annotations.Color = c;
            obj.View.handles.annotationColorBtn.BackgroundColor = obj.preferences.SegmTools.Annotations.Color;
        end
        
        function annotationFontSizeCombo_Callback(obj)
            % function annotationFontSizeCombo_Callback(obj)
            % callback for press of obj.View.handles.annotationFontSizeCombo
            obj.preferences.SegmTools.Annotations.FontSize = obj.View.handles.annotationFontSizeCombo.Value;
        end
        
        function defaultBtn_Callback(obj)
            % function defaultBtn_Callback(obj)
            % callback for press of obj.View.handles.defaultBtn
            
            button = questdlg(sprintf('You are going to restore default settings\n(except the key shortcuts)\nAre you sure?'),...
                'Restore default settings', 'Restore', 'Cancel', 'Cancel');
            if strcmp(button, 'Cancel'); return; end
            
            obj.preferences.System.MouseWheel = 'scroll';  % type of the mouse wheel action, 'scroll': change slices; 'zoom': zoom in/out
            obj.preferences.System.LeftMouseButton = 'select'; % swap the left and right mouse wheel actions, 'select': pick or draw with the left mouse button; 'pan': to move the image with the left mouse button
            obj.preferences.Undo.Enable = 1;   % enable undo
            obj.preferences.System.ImageResizeMethod = 'auto'; % image resizing method for zooming
            obj.preferences.System.EnableSelection = 1;    % disable selection with the mouse
            obj.preferences.Colors.MaskColor = [255 0 255]/255;    % color for the mask layer
            obj.preferences.Colors.SelectionColor = [0 255 0]/255; % color for the selection layer
            obj.preferences.Colors.ModelMaterialColors = [166 67 33;       % default colors for the materials of models
                71 178 126;
                79 107 171;
                150 169 213;
                26 51 111;
                255 204 102 ]/255;
            obj.preferences.Colors.SelectionTransparency = .75;       % transparency of the selection layer
            obj.preferences.Colors.MaskTransparency = 0;            % transparency of the mask layer
            obj.preferences.Colors.ModelTransparency = .75;           % transparency of the model layer
            obj.preferences.Undo.MaxUndoHistory = 8;         % number of steps for the Undo history
            obj.preferences.Undo.Max3dUndoHistory = 3;       % number of steps for the Undo history for whole dataset
            obj.preferences.SegmTools.PreviousTool = [3, 4];  % fast access to the selection type tools with the 'd' shortcut
            obj.preferences.SegmTools.Annotations.Color = [1 1 0];  % color for annotations
            obj.preferences.SegmTools.Annotations.FontSize = 2;     % font size for annotations
            obj.preferences.SegmTools.Interpolation.Type = 'shape';    % type of the interpolator to use
            obj.preferences.SegmTools.Interpolation.NoPoints = 200;     % number of points to use for the interpolation
            obj.preferences.SegmTools.Interpolation.LineWidth = 4;      % line width for the 'line' interpotator
            obj.preferences.Colors.LUTColors = [       % add colors for color channels
                1 0 0     % red
                0 1 0     % green
                0 0 1     % blue
                1 0 1     % purple
                1 1 0     % yellow
                1 .65 0]; % orange
            
            obj.preferences.System.FontSizeDirView = 10;        % font size for files and directories
            obj.preferences.fontSize = 8;      % font size for labels
            
            % define default parameters for slic/watershed superpixels
            obj.preferences.SegmTools.Superpixels.NoWatershed = 15;
            obj.preferences.SegmTools.Superpixels.InvertWatershed = 1;
            obj.preferences.SegmTools.Superpixels.NoSLIC = 220;
            obj.preferences.SegmTools.Superpixels.CompactSLIC = 50;
            
            % define gui scaling settings
            obj.mibModel.preferences.System.GUI.scaling = 1;   % scaling factor
            obj.mibModel.preferences.System.GUI.uipanel = 1;   % scaling uipanel
            obj.mibModel.preferences.System.GUI.uibuttongroup = 1;   % scaling uibuttongroup
            obj.mibModel.preferences.System.GUI.uitab = 1;   % scaling uitab
            obj.mibModel.preferences.System.GUI.uitabgroup = 1;   % scaling uitabgroup
            obj.mibModel.preferences.System.GUI.axes = 1;   % scaling axes
            obj.mibModel.preferences.System.GUI.uitable = 1;   % scaling uicontrol
            obj.mibModel.preferences.System.GUI.uicontrol = 1;   % scaling uicontrol
            
            obj.updateWidgets();
        end
        
        function fontBtn_Callback(obj)
            % function fontBtn_Callback(obj)
            % callback for press of obj.View.handles.fontBtn
            
            currFont = get(obj.View.handles.text2);
            selectedFont = uisetfont(currFont);
            if ~isstruct(selectedFont); return; end
            selectedFont = rmfield(selectedFont, 'FontWeight');
            selectedFont = rmfield(selectedFont, 'FontAngle');
            
            obj.preferences.System.Font = selectedFont;
            mibUpdateFontSize(obj.View.gui, obj.preferences.System.Font);
            obj.View.handles.fontSizeEdit.String = num2str(obj.preferences.System.Font.FontSize);
        end
        
        function keyShortcutsBtn_Callback(obj)
            % function keyShortcutsBtn_Callback(obj)
            % start a dialog for selection of key shortcuts
            
            obj.mibController.startController('mibKeyShortcutsController', obj);
        end
        
        function externalDirsBtn_Callback(obj)
            % function externalDirsBtn_Callback(obj)
            % define external directories, for example of Fiji
            obj.mibController.startController('mibExternalDirsController', obj);
        end
        
        function guiScalingBtn_Callback(obj)
            % function guiScalingBtn_Callback(obj)
            % modify gui scaling settings
            
            global scalingGUI;
            
            prompt = {'Scaling factor for MIB:', ...
                'Operating system scaling factor:', ...
                'scale uipanel:', ...
                'scale uibuttongroup:', ...
                'scale uitab:',...
                'scale uitabgroup:', ...
                'scale axes:', ...
                'scale uitable:', ...
                'scale uicontrol:'};
           
            defAns = {num2str(obj.preferences.System.GUI.scaling), ...
                num2str(obj.preferences.System.GUI.systemscaling), ...
                logical(obj.preferences.System.GUI.uipanel), ...
                logical(obj.preferences.System.GUI.uibuttongroup), ....
                logical(obj.preferences.System.GUI.uitab),...
                logical(obj.preferences.System.GUI.uitabgroup), ...
                logical(obj.preferences.System.GUI.axes), ...
                logical(obj.preferences.System.GUI.uitable),...
                logical(obj.preferences.System.GUI.uicontrol)};
            answer = mibInputMultiDlg([], prompt, defAns, 'Scaling of widgets');
            if isempty(answer); return; end
            
            if str2double(answer{1}) <= 0 
                errordlg(sprintf('!!! Error !!!\nthe scaling factor should be larger than 0'));
                return;
            end
            obj.preferences.System.GUI.scaling = str2double(answer{1});
            obj.preferences.System.GUI.systemscaling = str2double(answer{2});
            obj.preferences.System.GUI.uipanel = answer{3};
            obj.preferences.System.GUI.uibuttongroup = answer{4};
            obj.preferences.System.GUI.uitab = answer{5};
            obj.preferences.System.GUI.uitabgroup = answer{6};
            obj.preferences.System.GUI.axes = answer{7};
            obj.preferences.System.GUI.uitable = answer{8};
            obj.preferences.System.GUI.uicontrol = answer{9};
            
            scalingGUI = obj.preferences.System.GUI;
            mibRescaleWidgets(obj.mibController.mibView.gui);
        end
    end
end