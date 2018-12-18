classdef mibPreferencesController < handle
    % classdef mibPreferencesController < handle
    % a controller class for the MIB Preferences dialog
    
    % Copyright (C) 12.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    
    
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
            guiName = 'mibPreferencesGUI';
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
            if strcmp(obj.preferences.mouseWheel, 'zoom')   % zoom or scroll
                obj.View.handles.mouseWheelPopup.Value = 1;
            else
                obj.View.handles.mouseWheelPopup.Value = 2;
            end
            if strcmp(obj.preferences.mouseButton, 'pan')   % pan or select
                obj.View.handles.mouseButtonPopup.Value = 1;
            else
                obj.View.handles.mouseButtonPopup.Value = 2;
            end
            
            if strcmp(obj.preferences.undo, 'yes')
                obj.View.handles.undoPopup.Value = 1;
                obj.View.handles.maxUndoHistory.Enable = 'on';
                obj.View.handles.max3dUndoHistory.Enable = 'on';
            else
                obj.View.handles.undoPopup.Value = 2;
                obj.View.handles.maxUndoHistory.Enable = 'off';
                obj.View.handles.max3dUndoHistory.Enable = 'off';
            end
            
            if strcmp(obj.preferences.imageResizeMethod, 'auto')    % auto
                obj.View.handles.imresizePopup.Value = 1;
            elseif strcmp(obj.preferences.imageResizeMethod, 'nearest')    % nearest or bicubic
                obj.View.handles.imresizePopup.Value = 2;
            else
                obj.View.handles.imresizePopup.Value = 3;
            end
            
            if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 0
                obj.View.handles.disableSelectionPopup.Value = 1;
            else
                obj.View.handles.disableSelectionPopup.Value = 2;
            end
            if strcmp(obj.preferences.interpolationType, 'line')    % line or shape
                obj.View.handles.interpolationTypePopup.Value = 2;
                obj.View.handles.interpolationLineWidth.Enable = 'on';
            end
            
            obj.View.handles.annotationFontSizeCombo.Value = obj.preferences.annotationFontSize;
            obj.View.handles.fontSizeDirEdit.String = num2str(obj.preferences.fontSizeDir);
            obj.View.handles.fontSizeEdit.String = num2str(obj.preferences.Font.FontSize);
            
            obj.View.handles.maxUndoHistory.String = num2str(obj.preferences.maxUndoHistory);
            obj.View.handles.max3dUndoHistory.String = num2str(obj.preferences.max3dUndoHistory);
            obj.View.handles.interpolationNoPoints.String = num2str(obj.preferences.interpolationNoPoints);
            obj.View.handles.interpolationLineWidth.String = num2str(obj.preferences.interpolationLineWidth);
            
            obj.View.handles.annotationColorBtn.BackgroundColor = obj.preferences.annotationColor;
            obj.View.handles.colorMaskBtn.BackgroundColor = obj.preferences.maskcolor;
            obj.View.handles.colorSelectionBtn.BackgroundColor = obj.preferences.selectioncolor;
            
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
            switch paletteList{selectedVal}
                case 'Default, 6 colors'
                    obj.preferences.modelMaterialColors = [166 67 33; 71 178 126; 79 107 171; 150 169 213; 26 51 111; 255 204 102 ]/255;
                case 'Distinct colors, 20 colors'
                    %obj.preferences.modelMaterialColors = [255 80 5; 255 255 128; 116 10 255; 0 153 143; 66 102 0; 255 168 187; 0 51 128; 194 0 136; 143 124 0; 148 255 181; 255 204 153; 76 0 92; 153 63 0; 0 117 220; 240 163 255; 255 255 0; 153 0 0; 94 241 242; 255 0 16; 255 164 5; 157 204 0; 224 255 102; 0 92 49; 25 25 25; 43 206 72; 128 128 128; 255 255 255]/255;
                    obj.preferences.modelMaterialColors = [230 25 75; 255 225 25; 0 130 200; 245 130 48; 145 30 180; 70 240 240; 240 50 230; 210 245 60; 250 190 190; 0 128 128; 230 190 255; 170 110 40; 255 250 200; 128 0 0; 170 255 195; 128 128 0; 255 215 180; 0 0 128; 128 128 128; 60 180 75]/255;
                case 'Qualitative (Monte Carlo->Half Baked), 3-12 colors'
                    switch colorsNo
                        case 3; obj.preferences.modelMaterialColors = [141,211,199; 255,255,179; 190,186,218]/255;
                        case 4; obj.preferences.modelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114]/255;
                        case 5; obj.preferences.modelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211]/255;
                        case 6; obj.preferences.modelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98]/255;
                        case 7; obj.preferences.modelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105]/255;
                        case 8; obj.preferences.modelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105; 252,205,229]/255;
                        case 9; obj.preferences.modelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105; 252,205,229; 217,217,217]/255;
                        case 10; obj.preferences.modelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105; 252,205,229; 217,217,217; 188,128,189]/255;
                        case 11; obj.preferences.modelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105; 252,205,229; 217,217,217; 188,128,189; 204,235,197]/255;
                        case 12; obj.preferences.modelMaterialColors = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105; 252,205,229; 217,217,217; 188,128,189; 204,235,197; 255,237,111]/255;
                    end
                case 'Diverging (Deep Bronze->Deep Teal), 3-11 colors'
                    switch colorsNo
                        case 3; obj.preferences.modelMaterialColors = [216,179,101; 245,245,245; 90,180,172]/255;
                        case 4; obj.preferences.modelMaterialColors = [166,97,26; 223,194,125; 128,205,193; 1,133,113]/255;
                        case 5; obj.preferences.modelMaterialColors = [166,97,26; 223,194,125; 245,245,245; 128,205,193; 1,133,113]/255;
                        case 6; obj.preferences.modelMaterialColors = [140,81,10; 216,179,101; 246,232,195; 199,234,229; 90,180,172; 1,102,94]/255;
                        case 7; obj.preferences.modelMaterialColors = [140,81,10; 216,179,101; 246,232,195; 245,245,245; 199,234,229; 90,180,172; 1,102,94]/255;
                        case 8; obj.preferences.modelMaterialColors = [140,81,10; 191,129,45; 223,194,125; 246,232,195; 199,234,229; 128,205,193; 53,151,143; 1,102,94]/255;
                        case 9; obj.preferences.modelMaterialColors = [140,81,10; 191,129,45; 223,194,125; 246,232,195; 245,245,245; 199,234,229; 128,205,193; 53,151,143; 1,102,94]/255;
                        case 10; obj.preferences.modelMaterialColors = [84,48,5; 140,81,10; 191,129,45; 223,194,125; 246,232,195; 199,234,229; 128,205,193; 53,151,143; 1,102,94; 0,60,48]/255;
                        case 11; obj.preferences.modelMaterialColors = [84,48,5; 140,81,10; 191,129,45; 223,194,125; 246,232,195; 245,245,245; 199,234,229; 128,205,193; 53,151,143; 1,102,94; 0,60,48]/255;
                    end
                case 'Diverging (Ripe Plum->Kaitoke Green), 3-11 colors'
                    switch colorsNo
                        case 3; obj.preferences.modelMaterialColors = [175,141,195; 247,247,247; 127,191,123]/255;
                        case 4; obj.preferences.modelMaterialColors = [123,50,148; 194,165,207; 166,219,160; 0,136,55]/255;
                        case 5; obj.preferences.modelMaterialColors = [123,50,148; 194,165,207; 247,247,247; 166,219,160; 0,136,55]/255;
                        case 6; obj.preferences.modelMaterialColors = [118,42,131; 175,141,195; 231,212,232; 217,240,211; 127,191,123; 27,120,55]/255;
                        case 7; obj.preferences.modelMaterialColors = [118,42,131; 175,141,195; 231,212,232; 247,247,247; 217,240,211; 127,191,123; 27,120,55]/255;
                        case 8; obj.preferences.modelMaterialColors = [118,42,131; 153,112,171; 194,165,207; 231,212,232; 217,240,211; 166,219,160; 90,174,97; 27,120,55]/255;
                        case 9; obj.preferences.modelMaterialColors = [118,42,131; 153,112,171; 194,165,207; 231,212,232; 247,247,247; 217,240,211; 166,219,160; 90,174,97; 27,120,55]/255;
                        case 10; obj.preferences.modelMaterialColors = [64,0,75; 118,42,131; 153,112,171; 194,165,207; 231,212,232; 217,240,211; 166,219,160; 90,174,97; 27,120,55; 0,68,27]/255;
                        case 11; obj.preferences.modelMaterialColors = [64,0,75; 118,42,131; 153,112,171; 194,165,207; 231,212,232; 247,247,247; 217,240,211; 166,219,160; 90,174,97; 27,120,55; 0,68,27]/255;
                    end
                case 'Diverging (Bordeaux->Green Vogue), 3-11 colors'
                    switch colorsNo
                        case 3; obj.preferences.modelMaterialColors = [239,138,98; 247,247,247; 103,169,207]/255;
                        case 4; obj.preferences.modelMaterialColors = [202,0,32; 244,165,130; 146,197,222; 5,113,176]/255;
                        case 5; obj.preferences.modelMaterialColors = [202,0,32; 244,165,130; 247,247,247; 146,197,222; 5,113,176]/255;
                        case 6; obj.preferences.modelMaterialColors = [178,24,43; 239,138,98; 253,219,199; 209,229,240; 103,169,207; 33,102,172]/255;
                        case 7; obj.preferences.modelMaterialColors = [178,24,43; 239,138,98; 253,219,199; 247,247,247; 209,229,240; 103,169,207; 33,102,172]/255;
                        case 8; obj.preferences.modelMaterialColors = [178,24,43; 214,96,77; 244,165,130; 253,219,199; 209,229,240; 146,197,222; 67,147,195; 33,102,172]/255;
                        case 9; obj.preferences.modelMaterialColors = [178,24,43; 214,96,77; 244,165,130; 253,219,199; 247,247,247; 209,229,240; 146,197,222; 67,147,195; 33,102,172]/255;
                        case 10; obj.preferences.modelMaterialColors = [103,0,31; 178,24,43; 214,96,77; 244,165,130; 253,219,199; 209,229,240; 146,197,222; 67,147,195; 33,102,172; 5,48,97]/255;
                        case 11; obj.preferences.modelMaterialColors = [103,0,31; 178,24,43; 214,96,77; 244,165,130; 253,219,199; 247,247,247; 209,229,240; 146,197,222; 67,147,195; 33,102,172; 5,48,97]/255;
                    end
                case 'Diverging (Carmine->Bay of Many), 3-11 colors'
                    switch colorsNo
                        case 3; obj.preferences.modelMaterialColors = [252,141,89; 255,255,191; 145,191,219]/255;
                        case 4; obj.preferences.modelMaterialColors = [215,25,28; 253,174,97; 171,217,233; 44,123,182]/255;
                        case 5; obj.preferences.modelMaterialColors = [215,25,28; 253,174,97; 255,255,191; 171,217,233; 44,123,182]/255;
                        case 6; obj.preferences.modelMaterialColors = [215,48,39; 252,141,89; 254,224,144; 224,243,248; 145,191,219; 69,117,180]/255;
                        case 7; obj.preferences.modelMaterialColors = [215,48,39; 252,141,89; 254,224,144; 255,255,191; 224,243,248; 145,191,219; 69,117,180]/255;
                        case 8; obj.preferences.modelMaterialColors = [215,48,39; 244,109,67; 253,174,97; 254,224,144; 224,243,248; 171,217,233; 116,173,209; 69,117,180]/255;
                        case 9; obj.preferences.modelMaterialColors = [215,48,39; 244,109,67; 253,174,97; 254,224,144; 255,255,191; 224,243,248; 171,217,233; 116,173,209; 69,117,180]/255;
                        case 10; obj.preferences.modelMaterialColors = [165,0,38; 215,48,39; 244,109,67; 253,174,97; 254,224,144; 224,243,248; 171,217,233; 116,173,209; 69,117,180; 49,54,149]/255;
                        case 11; obj.preferences.modelMaterialColors = [165,0,38; 215,48,39; 244,109,67; 253,174,97; 254,224,144; 255,255,191; 224,243,248; 171,217,233; 116,173,209; 69,117,180; 49,54,149]/255;
                    end
                case 'Sequential (Kaitoke Green), 3-9 colors'
                    switch colorsNo
                        case 3; obj.preferences.modelMaterialColors = [229,245,249; 153,216,201; 44,162,95]/255;
                        case 4; obj.preferences.modelMaterialColors = [237,248,251; 178,226,226; 102,194,164; 35,139,69]/255;
                        case 5; obj.preferences.modelMaterialColors = [237,248,251; 178,226,226; 102,194,164; 44,162,95; 0,109,44]/255;
                        case 6; obj.preferences.modelMaterialColors = [237,248,251; 204,236,230; 153,216,201; 102,194,164; 44,162,95; 0,109,44]/255;
                        case 7; obj.preferences.modelMaterialColors = [237,248,251; 204,236,230; 153,216,201; 102,194,164; 65,174,118; 35,139,69; 0,88,36]/255;
                        case 8; obj.preferences.modelMaterialColors = [247,252,253; 229,245,249; 204,236,230; 153,216,201; 102,194,164; 65,174,118; 35,139,69; 0,88,36]/255;
                        case 9; obj.preferences.modelMaterialColors = [247,252,253; 229,245,249; 204,236,230; 153,216,201; 102,194,164; 65,174,118; 35,139,69; 0,109,44; 0,68,27]/255;
                    end
                case 'Sequential (Catalina Blue), 3-9 colors'
                    switch colorsNo
                        case 3; obj.preferences.modelMaterialColors = [224,243,219; 168,221,181; 67,162,202]/255;
                        case 4; obj.preferences.modelMaterialColors = [240,249,232; 186,228,188; 123,204,196; 43,140,190]/255;
                        case 5; obj.preferences.modelMaterialColors = [240,249,232; 186,228,188; 123,204,196; 67,162,202; 8,104,172]/255;
                        case 6; obj.preferences.modelMaterialColors = [240,249,232; 204,235,197; 168,221,181; 123,204,196; 67,162,202; 8,104,172]/255;
                        case 7; obj.preferences.modelMaterialColors = [240,249,232; 204,235,197; 168,221,181; 123,204,196; 78,179,211; 43,140,190; 8,88,158]/255;
                        case 8; obj.preferences.modelMaterialColors = [247,252,240; 224,243,219; 204,235,197; 168,221,181; 123,204,196; 78,179,211; 43,140,190; 8,88,158]/255;
                        case 9; obj.preferences.modelMaterialColors = [247,252,240; 224,243,219; 204,235,197; 168,221,181; 123,204,196; 78,179,211; 43,140,190; 8,104,172; 8,64,129]/255;
                    end
                case 'Sequential (Maroon), 3-9 colors'
                    switch colorsNo
                        case 3; obj.preferences.modelMaterialColors = [254,232,200; 253,187,132; 227,74,51]/255;
                        case 4; obj.preferences.modelMaterialColors = [254,240,217; 253,204,138; 252,141,89; 215,48,31]/255;
                        case 5; obj.preferences.modelMaterialColors = [254,240,217; 253,204,138; 252,141,89; 227,74,51; 179,0,0]/255;
                        case 6; obj.preferences.modelMaterialColors = [254,240,217; 253,212,158; 253,187,132; 252,141,89; 227,74,51; 179,0,0]/255;
                        case 7; obj.preferences.modelMaterialColors = [254,240,217; 253,212,158; 253,187,132; 252,141,89; 239,101,72; 215,48,31; 153,0,0]/255;
                        case 8; obj.preferences.modelMaterialColors = [255,247,236; 254,232,200; 253,212,158; 253,187,132; 252,141,89; 239,101,72; 215,48,31; 153,0,0]/255;
                        case 9; obj.preferences.modelMaterialColors = [255,247,236; 254,232,200; 253,212,158; 253,187,132; 252,141,89; 239,101,72; 215,48,31; 179,0,0; 127,0,0]/255;
                    end
                case 'Sequential (Astronaut Blue), 3-9 colors'
                    switch colorsNo
                        case 3; obj.preferences.modelMaterialColors = [236,231,242; 166,189,219; 43,140,190]/255;
                        case 4; obj.preferences.modelMaterialColors = [241,238,246; 189,201,225; 116,169,207; 5,112,176]/255;
                        case 5; obj.preferences.modelMaterialColors = [241,238,246; 189,201,225; 116,169,207; 43,140,190; 4,90,141]/255;
                        case 6; obj.preferences.modelMaterialColors = [241,238,246; 208,209,230; 166,189,219; 116,169,207; 43,140,190; 4,90,141]/255;
                        case 7; obj.preferences.modelMaterialColors = [241,238,246; 208,209,230; 166,189,219; 116,169,207; 54,144,192; 5,112,176; 3,78,123]/255;
                        case 8; obj.preferences.modelMaterialColors = [255,247,251; 236,231,242; 208,209,230; 166,189,219; 116,169,207; 54,144,192; 5,112,176; 3,78,123]/255;
                        case 9; obj.preferences.modelMaterialColors = [255,247,251; 236,231,242; 208,209,230; 166,189,219; 116,169,207; 54,144,192; 5,112,176; 4,90,141; 2,56,88]/255;
                    end
                case 'Sequential (Downriver), 3-9 colors'
                    switch colorsNo
                        case 3; obj.preferences.modelMaterialColors = [237,248,177; 127,205,187; 44,127,184]/255;
                        case 4; obj.preferences.modelMaterialColors = [255,255,204; 161,218,180; 65,182,196; 34,94,168]/255;
                        case 5; obj.preferences.modelMaterialColors = [255,255,204; 161,218,180; 65,182,196; 44,127,184; 37,52,148]/255;
                        case 6; obj.preferences.modelMaterialColors = [255,255,204; 199,233,180; 127,205,187; 65,182,196; 44,127,184; 37,52,148]/255;
                        case 7; obj.preferences.modelMaterialColors = [255,255,204; 199,233,180; 127,205,187; 65,182,196; 29,145,192; 34,94,168; 12,44,132]/255;
                        case 8; obj.preferences.modelMaterialColors = [255,255,217; 237,248,177; 199,233,180; 127,205,187; 65,182,196; 29,145,192; 34,94,168; 12,44,132]/255;
                        case 9; obj.preferences.modelMaterialColors = [255,255,217; 237,248,177; 199,233,180; 127,205,187; 65,182,196; 29,145,192; 34,94,168; 37,52,148; 8,29,88]/255;
                    end
                case 'Matlab Jet'
                    obj.preferences.modelMaterialColors =  colormap(jet(colorsNo));
                case 'Matlab Gray'
                    obj.preferences.modelMaterialColors =  colormap(gray(colorsNo));
                case 'Matlab Bone'
                    obj.preferences.modelMaterialColors =  colormap(bone(colorsNo));
                case 'Matlab HSV'
                    obj.preferences.modelMaterialColors =  colormap(hsv(colorsNo));
                case 'Matlab Cool'
                    obj.preferences.modelMaterialColors =  colormap(cool(colorsNo));
                case 'Matlab Hot'
                    obj.preferences.modelMaterialColors =  colormap(hot(colorsNo));
                case 'Random Colors'
                    rng('shuffle');     % randomize generator
                    obj.preferences.modelMaterialColors =  colormap(rand([colorsNo,3]));
            end
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
            modelMaterialColors_local = obj.preferences.modelMaterialColors(1:min([255, size(obj.preferences.modelMaterialColors, 1)]),:);
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
            data = cell([size(obj.preferences.lutColors, 1), 4]);
            for colorId = 1:size(obj.preferences.lutColors, 1)
                data{colorId, 1} = round(obj.preferences.lutColors(colorId, 1)*255);
                data{colorId, 2} = round(obj.preferences.lutColors(colorId, 2)*255);
                data{colorId, 3} = round(obj.preferences.lutColors(colorId, 3)*255);
                data{colorId, 4} = colergen(sprintf('''rgb(%d, %d, %d)''', ...
                    round(obj.preferences.lutColors(colorId, 1)*255), round(obj.preferences.lutColors(colorId, 2)*255), round(obj.preferences.lutColors(colorId, 3)*255)),'&nbsp;');  % rgb(0,255,0)
            end
            obj.View.handles.lutColorsTable.Data = data;
            obj.View.handles.lutColorsTable.ColumnWidth = {39 40 39 32};
        end
        
        function applyBtn_Callback(obj)
            % function applyBtn_Callback(obj)
            % apply preferences
            global Font;
            
            if obj.preferences.disableSelection == 0   % turn ON the Selection
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
            obj.mibModel.I{obj.mibModel.Id}.disableSelection = obj.preferences.disableSelection;
            
            % update font size
            obj.preferences.fontSizeDir = str2double(obj.View.handles.fontSizeDirEdit.String);
            obj.mibController.mibView.handles.mibFilesListbox.FontSize = obj.preferences.fontSizeDir;
            Font = obj.preferences.Font;
            
            if obj.mibController.mibView.handles.mibZoomText.FontSize ~= obj.preferences.Font.FontSize || ...
                    ~strcmp(obj.mibController.mibView.handles.mibZoomText.FontName, obj.preferences.Font.FontName)
                mibUpdateFontSize(obj.mibController.mibView.gui, obj.preferences.Font);
                mibUpdateFontSize(obj.View.gui, obj.preferences.Font);
            end
            obj.mibModel.preferences = obj.preferences;
            
            obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors = obj.preferences.modelMaterialColors;
            obj.mibModel.I{obj.mibModel.Id}.lutColors = obj.preferences.lutColors;
            
            obj.mibController.toolbarInterpolation_ClickedCallback('keepcurrent');     % update the interpolation button icon
            obj.mibController.toolbarResizingMethod_ClickedCallback('keepcurrent');
            
            % update imaris path using IMARISPATH enviromental variable
            if ~isempty(obj.mibModel.preferences.dirs.imarisInstallationPath)
                setenv('IMARISPATH', obj.mibModel.preferences.dirs.imarisInstallationPath);
            end
            
            notify(obj.mibModel, 'plotImage');
        end
        
        function OKBtn_Callback(obj)
            % function OKBtn_Callback(obj)
            % callback for press of obj.View.handles.OKBtn
            obj.applyBtn_Callback();
            
            obj.mibModel.setImageProperty('modelMaterialColors', obj.preferences.modelMaterialColors);
            obj.mibModel.setImageProperty('lutColors', obj.preferences.lutColors);
            
            if strcmp(obj.preferences.undo, 'no')
                obj.mibModel.U.clearContents();
                obj.mibModel.U.enableSwitch = 0;
            else
                obj.mibModel.U.enableSwitch = 1;
            end
            if obj.preferences.max3dUndoHistory ~= obj.mibModel.U.max3d_steps || obj.preferences.maxUndoHistory ~= obj.mibModel.U.max_steps
                obj.mibModel.U.setNumberOfHistorySteps(obj.preferences.maxUndoHistory, obj.preferences.max3dUndoHistory);
            end
            
            if obj.preferences.disableSelection == 0
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
            obj.mibModel.I{obj.mibModel.Id}.disableSelection = obj.preferences.disableSelection;
            
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
            obj.preferences.mouseWheel = list{obj.View.handles.mouseWheelPopup.Value};
        end
        
        function mouseButtonPopup_Callback(obj)
            % function mouseButtonPopup_Callback(obj)
            % callback for change of obj.View.handles.mouseButtonPopup
            list = obj.View.handles.mouseButtonPopup.String;
            obj.preferences.mouseButton = list{obj.View.handles.mouseButtonPopup.Value};
        end
        
        
        function undoPopup_Callback(obj)
            % function undoPopup_Callback(obj)
            % callback for change of obj.View.handles.undoPopup
            
            list = obj.View.handles.undoPopup.String;
            obj.preferences.undo = list{obj.View.handles.undoPopup.Value};
            if strcmp(obj.preferences.undo, 'no')
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
            obj.preferences.imageResizeMethod = list{obj.View.handles.imresizePopup.Value};
        end
        
        function colorSelectionBtn_Callback(obj)
            % function colorSelectionBtn_Callback(obj)
            % callback for press of obj.View.handles.colorSelectionBtn
            % set color for the selection layer
            sel_color = obj.preferences.selectioncolor;
            c = uisetcolor(sel_color, 'Select Selection color');
            if length(c) == 1; return; end
            obj.preferences.selectioncolor = c;
            obj.View.handles.colorSelectionBtn.BackgroundColor = obj.preferences.selectioncolor;
        end
        
        function colorMaskBtn_Callback(obj)
            % function colorMaskBtn_Callback(obj)
            % callback for press of obj.View.handles.colorMaskBtn
            % set color for the mask layer
            
            sel_color = obj.preferences.maskcolor;
            c = uisetcolor(sel_color, 'Select Selection color');
            if length(c) == 1; return; end
            obj.preferences.maskcolor = c;
            obj.View.handles.colorMaskBtn.BackgroundColor = obj.preferences.maskcolor;
        end
        
        function colorModelSelection_Callback(obj)
            % function colorModelSelection_Callback(obj)
            % callback for selection of colors in obj.View.handles.modelsColorsTable
            
            position = obj.View.handles.modelsColorsTable.UserData;
            if isempty(position)
                msgbox(sprintf('Error!\nPlease select a row in the table first'), 'Error!', 'error', 'modal');
                return;
            end
            figTitle = ['Set color for countour ' num2str(position(1))];
            c = uisetcolor(obj.preferences.modelMaterialColors(position(1),:), figTitle);
            if length(c) == 1; return; end
            obj.preferences.modelMaterialColors(position(1),:) = c;
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
                    obj.preferences.modelMaterialColors = obj.preferences.modelMaterialColors(end:-1:1,:);
                case 'insert'
                    noColors = size(obj.preferences.modelMaterialColors, 1);
                    if position(1) == noColors
                        obj.preferences.modelMaterialColors = [obj.preferences.modelMaterialColors; rand([1,3])];
                    else
                        obj.preferences.modelMaterialColors = ...
                            [obj.preferences.modelMaterialColors(1:position(1),:); rand([1,3]); obj.preferences.modelMaterialColors(position(1)+1:noColors,:)];
                    end
                case 'random'   % generate a random color
                    obj.preferences.modelMaterialColors(position(1),:) = rand([1,3]);
                case 'swap'     % swap two colors
                    answer = mibInputDlg({mibPath}, sprintf('Enter a color number to swap with the selected\nSelected: %d', position(1)), 'Swap with', '1');
                    if size(answer) == 0; return; end
                    
                    tableContents = obj.View.handles.modelsColorsTable.Data;
                    newIndex = str2double(answer{1});
                    if newIndex > size(tableContents,1) || newIndex < 1
                        errordlg(sprintf('The entered number is too big or too small\nIt should be between 0-%d', size(tableContents,1)), 'Wrong value');
                        return;
                    end
                    selectedColor = obj.preferences.modelMaterialColors(position(1),:);
                    obj.preferences.modelMaterialColors(position(1),:) = obj.preferences.modelMaterialColors(newIndex,:);
                    obj.preferences.modelMaterialColors(str2double(answer{1}),:) = selectedColor;
                case 'delete'   % delete selected color
                    obj.preferences.modelMaterialColors(position(:,1),:) = [];
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
                    obj.preferences.modelMaterialColors = colormap;
                case 'export'       % export color to Matlab workspace
                    title = 'Export colormap';
                    prompt = sprintf('Input a destination variable for export\nA matrix containing the current colormap [colorNumber, [R,G,B]] will be assigned to this variable');
                    %answer = inputdlg(prompt,title,[1 30],{'colormap'},'on');
                    answer = mibInputDlg({mibPath}, prompt, title, 'colormap');
                    if size(answer) == 0; return; end
                    assignin('base',answer{1}, obj.preferences.modelMaterialColors);
                    disp(['Colormap export: created variable ' answer{1} ' in the Matlab workspace']);
                case 'load'
                    [FileName,PathName] = uigetfile({'*.cmap';'*.mat';'*.*'}, 'Load colormap',...
                        fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename')));
                    if FileName == 0; return; end
                    load(fullfile(PathName, FileName),'-mat');
                    obj.preferences.modelMaterialColors = cmap; %#ok<NODEF>
                case 'save'
                    [PathName, FileName] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
                    [FileName, PathName] = uiputfile('*.cmap','Save colormap', fullfile(PathName, [FileName '.cmap']));
                    if FileName == 0; return; end
                    cmap = obj.preferences.modelMaterialColors; %#ok<NASGU>
                    save(fullfile(PathName, FileName), 'cmap');
                    disp(['MIB: the colormap was saved to ' fullfile(PathName, FileName)]);
            end
            
            % generate random colors when number of colors less than number of
            % materials
            if size(obj.preferences.modelMaterialColors, 1) < materialsNumber
                missingColors = materialsNumber - size(obj.preferences.modelMaterialColors, 1);
                obj.preferences.modelMaterialColors = [obj.preferences.modelMaterialColors; rand([missingColors,3])];
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
            
            obj.preferences.modelMaterialColors(eventdata.Indices(1), eventdata.Indices(2)) = eventdata.NewData/255;
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
            
            obj.preferences.lutColors(eventdata.Indices(1), eventdata.Indices(2)) = (eventdata.NewData)/255;
            obj.updateLUTColorTable();
        end
        
        function undoHistory_Callback(obj)
            % function undoHistory_Callback(obj)
            % callback for change undo history
            val = str2double(obj.View.handles.maxUndoHistory.String);
            val2 = str2double(obj.View.handles.max3dUndoHistory.String);
            if val < 1
                msgbox(sprintf('Error!\nThe minimal total number of history steps is 1'),'Error!','error','modal');
                obj.View.handles.maxUndoHistory.String = num2str(obj.preferences.maxUndoHistory);
                return;
            end
            if val2 < 0
                msgbox(sprintf('Error!\nThe minimal total number of 3D history steps is 0'),'Error!','error','modal');
                obj.View.handles.maxUndoHistory.String = num2str(handles.preferences.max2dUndoHistory);
                return;
            end
            
            if val2 > val
                msgbox(sprintf('Error!\nThe number of 3D history steps should be lower or equal than total number of steps'),'Error!','error','modal');
                obj.View.handles.maxUndoHistory.String = num2str(obj.preferences.maxUndoHistory);
                obj.View.handles.max3dUndoHistory.String = num2str(obj.preferences.max3dUndoHistory);
                return;
            end
            obj.preferences.maxUndoHistory = val;
            obj.preferences.max3dUndoHistory = val2;
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
                obj.preferences.disableSelection = 1;
            else
                obj.preferences.disableSelection = 0;
            end
        end
        
        function interpolationTypePopup_Callback(obj)
            % function interpolationTypePopup_Callback(obj)
            % callback for change of obj.View.handles.interpolationTypePopup
            
            value = obj.View.handles.interpolationTypePopup.Value;
            if value == 1   % shape interpolation
                obj.preferences.interpolationType = 'shape';
                obj.View.handles.interpolationLineWidth.Enable = 'off';
            else            % line interpolation
                obj.preferences.interpolationType = 'line';
                obj.View.handles.interpolationLineWidth.Enable = 'on';
            end
        end
        
        function interpolationNoPoints_Callback(obj)
            % function interpolationNoPoints_Callback(obj)
            % callback for change of obj.View.handles.interpolationNoPoints
            val = str2double(obj.View.handles.interpolationNoPoints.String);
            if val < 1
                msgbox(sprintf('Error!\nThe minimal number of interpolation points is 1'), 'Error!', 'error', 'modal');
                obj.View.handles.interpolationNoPoints.String = num2str(obj.preferences.interpolationNoPoints);
                return;
            end
            obj.preferences.interpolationNoPoints = val;
        end
        
        function interpolationLineWidth_Callback(obj)
            % function interpolationLineWidth_Callback(obj)
            % callback for change of obj.View.handles.interpolationLineWidth
            val = str2double(obj.View.handles.interpolationLineWidth.String);
            if val < 1
                msgbox(sprintf('Error!\nThe minimal number of the line width is 1'), 'Error!', 'error', 'modal');
                obj.View.handles.interpolationLineWidth.String = num2str(obj.preferences.interpolationLineWidth);
                return;
            end
            obj.preferences.interpolationLineWidth = val;
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
            c = uisetcolor(obj.preferences.lutColors(position(1),:), figTitle);
            if length(c) == 1; return; end
            obj.preferences.lutColors(position(1),:) = c;
            obj.updateLUTColorTable();
        end
        
        function fontSizeEdit_Callback(obj)
            % function fontSizeEdit_Callback(obj)
            % callback for change of obj.View.handles.fontSizeEdit
            % update font size for mibPreferencesGUI
            obj.preferences.Font.FontSize = str2double(obj.View.handles.fontSizeEdit.String);
        end
        
        function annotationColorBtn_Callback(obj)
            % function annotationColorBtn_Callback(obj)
            % callback for press of obj.View.handles.annotationColorBtn
            
            sel_color = obj.preferences.annotationColor;
            c = uisetcolor(sel_color, 'Select color for annotations');
            if length(c) == 1; return; end
            obj.preferences.annotationColor = c;
            obj.View.handles.annotationColorBtn.BackgroundColor = obj.preferences.annotationColor;
        end
        
        function annotationFontSizeCombo_Callback(obj)
            % function annotationFontSizeCombo_Callback(obj)
            % callback for press of obj.View.handles.annotationFontSizeCombo
            obj.preferences.annotationFontSize = obj.View.handles.annotationFontSizeCombo.Value;
        end
        
        function defaultBtn_Callback(obj)
            % function defaultBtn_Callback(obj)
            % callback for press of obj.View.handles.defaultBtn
            
            button = questdlg(sprintf('You are going to restore default settings\n(except the key shortcuts)\nAre you sure?'),...
                'Restore default settings', 'Restore', 'Cancel', 'Cancel');
            if strcmp(button, 'Cancel'); return; end
            
            obj.preferences.mouseWheel = 'scroll';  % type of the mouse wheel action, 'scroll': change slices; 'zoom': zoom in/out
            obj.preferences.mouseButton = 'select'; % swap the left and right mouse wheel actions, 'select': pick or draw with the left mouse button; 'pan': to move the image with the left mouse button
            obj.preferences.undo = 'yes';   % enable undo
            obj.preferences.imageResizeMethod = 'auto'; % image resizing method for zooming
            obj.preferences.disableSelection = 0;    % disable selection with the mouse
            obj.preferences.maskcolor = [255 0 255]/255;    % color for the mask layer
            obj.preferences.selectioncolor = [0 255 0]/255; % color for the selection layer
            obj.preferences.modelMaterialColors = [166 67 33;       % default colors for the materials of models
                71 178 126;
                79 107 171;
                150 169 213;
                26 51 111;
                255 204 102 ]/255;
            obj.preferences.mibSelectionTransparencySlider = .75;       % transparency of the selection layer
            obj.preferences.mibMaskTransparencySlider = 0;            % transparency of the mask layer
            obj.preferences.mibModelTransparencySlider = .75;           % transparency of the model layer
            obj.preferences.maxUndoHistory = 8;         % number of steps for the Undo history
            obj.preferences.max3dUndoHistory = 3;       % number of steps for the Undo history for whole dataset
            obj.preferences.lastSegmTool = [3, 4];  % fast access to the selection type tools with the 'd' shortcut
            obj.preferences.annotationColor = [1 1 0];  % color for annotations
            obj.preferences.annotationFontSize = 2;     % font size for annotations
            obj.preferences.interpolationType = 'shape';    % type of the interpolator to use
            obj.preferences.interpolationNoPoints = 200;     % number of points to use for the interpolation
            obj.preferences.interpolationLineWidth = 4;      % line width for the 'line' interpotator
            obj.preferences.lutColors = [       % add colors for color channels
                1 0 0     % red
                0 1 0     % green
                0 0 1     % blue
                1 0 1     % purple
                1 1 0     % yellow
                1 .65 0]; % orange
            
            obj.preferences.fontSizeDir = 10;        % font size for files and directories
            obj.preferences.fontSize = 8;      % font size for labels
            
            % default parameters for CLAHE
            obj.preferences.CLAHE.NumTiles = [8 8];
            obj.preferences.CLAHE.ClipLimit = 0.01;
            obj.preferences.CLAHE.NBins = 256;
            obj.preferences.CLAHE.Distribution = 'uniform';
            obj.preferences.CLAHE.Alpha = 0.4;
            
            % define default parameters for slic/watershed superpixels
            obj.preferences.superpixels.watershed_n = 15;
            obj.preferences.superpixels.watershed_invert = 1;
            obj.preferences.superpixels.slic_n = 220;
            obj.preferences.superpixels.slic_compact = 50;
            
            % define gui scaling settings
            obj.mibModel.preferences.gui.scaling = 1;   % scaling factor
            obj.mibModel.preferences.gui.uipanel = 1;   % scaling uipanel
            obj.mibModel.preferences.gui.uibuttongroup = 1;   % scaling uibuttongroup
            obj.mibModel.preferences.gui.uitab = 1;   % scaling uitab
            obj.mibModel.preferences.gui.uitabgroup = 1;   % scaling uitabgroup
            obj.mibModel.preferences.gui.axes = 1;   % scaling axes
            obj.mibModel.preferences.gui.uitable = 1;   % scaling uicontrol
            obj.mibModel.preferences.gui.uicontrol = 1;   % scaling uicontrol
            
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
            
            obj.preferences.Font = selectedFont;
            mibUpdateFontSize(obj.View.gui, obj.preferences.Font);
            obj.View.handles.fontSizeEdit.String = num2str(obj.preferences.Font.FontSize);
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
           
            defAns = {num2str(obj.preferences.gui.scaling), ...
                num2str(obj.preferences.gui.systemscaling), ...
                logical(obj.preferences.gui.uipanel), ...
                logical(obj.preferences.gui.uibuttongroup), ....
                logical(obj.preferences.gui.uitab),...
                logical(obj.preferences.gui.uitabgroup), ...
                logical(obj.preferences.gui.axes), ...
                logical(obj.preferences.gui.uitable),...
                logical(obj.preferences.gui.uicontrol)};
            answer = mibInputMultiDlg([], prompt, defAns, 'Scaling of widgets');
            if isempty(answer); return; end
            
            if str2double(answer{1}) <= 0 
                errordlg(sprintf('!!! Error !!!\nthe scaling factor should be larger than 0'));
                return;
            end
            obj.preferences.gui.scaling = str2double(answer{1});
            obj.preferences.gui.systemscaling = str2double(answer{2});
            obj.preferences.gui.uipanel = answer{3};
            obj.preferences.gui.uibuttongroup = answer{4};
            obj.preferences.gui.uitab = answer{5};
            obj.preferences.gui.uitabgroup = answer{6};
            obj.preferences.gui.axes = answer{7};
            obj.preferences.gui.uitable = answer{8};
            obj.preferences.gui.uicontrol = answer{9};
            
            scalingGUI = obj.preferences.gui;
            mibRescaleWidgets(obj.mibController.mibView.gui);
        end
    end
end