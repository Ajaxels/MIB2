function varargout = mibPreferencesGUI(varargin)
% varargout = mibPreferencesGUI(varargin)
% mibPreferencesGUI a dialog responsible for setting preferences for
% im_browser.m
%
% mibPreferencesGUI contains MATLAB code for mibPreferencesGUI.fig

% Copyright (C) 02.09.2014, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 26.10.2016, IB, updated for segmentation table

 

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mibPreferencesGUI_OpeningFcn, ...
    'gui_OutputFcn',  @mibPreferencesGUI_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
end
% End initialization code - DO NOT EDIT

% --- Executes just before mibpreferencesgui is made visible.
function mibPreferencesGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibpreferencesgui (see VARARGIN)

% Choose default command line output for mibpreferencesgui

% obtain controller
handles.winController = varargin{1};

% update font and size
global Font;
if ~isempty(Font)
    if handles.text2.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.text2.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibPreferencesGUI, Font);
    end
end

% resize all elements x1.25 times for macOS
mibRescaleWidgets(handles.mibPreferencesGUI);

% add context menu to the colormap table
handles.modelsColorsTable_cm = uicontextmenu('Parent', handles.mibPreferencesGUI);
uimenu(handles.modelsColorsTable_cm, 'Label', 'Reverse colormap', 'Callback', {@modelsColorsTable_cb, 'reverse'});
uimenu(handles.modelsColorsTable_cm, 'Label', 'Insert color', 'Separator', 'on', 'Callback', {@modelsColorsTable_cb, 'insert'});
uimenu(handles.modelsColorsTable_cm, 'Label', 'Replace with random color', 'Callback', {@modelsColorsTable_cb, 'random'});
uimenu(handles.modelsColorsTable_cm, 'Label', 'Swap two colors', 'Callback', {@modelsColorsTable_cb, 'swap'});
uimenu(handles.modelsColorsTable_cm, 'Label', 'Delete color(s)', 'Callback', {@modelsColorsTable_cb, 'delete'});
uimenu(handles.modelsColorsTable_cm, 'Label', 'Import from Matlab', 'Separator', 'on', 'Callback', {@modelsColorsTable_cb, 'import'});
uimenu(handles.modelsColorsTable_cm, 'Label', 'Export to Matlab', 'Callback', {@modelsColorsTable_cb, 'export'});
uimenu(handles.modelsColorsTable_cm, 'Label', 'Load from a file', 'Callback', {@modelsColorsTable_cb, 'load'});
uimenu(handles.modelsColorsTable_cm, 'Label', 'Save to a file', 'Callback', {@modelsColorsTable_cb, 'save'});
handles.modelsColorsTable.UIContextMenu = handles.modelsColorsTable_cm;

% Choose default command line output for mibdatasetinfogui
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'center', 'center');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibpreferencesgui wait for user response (see UIRESUME)
% uiwait(handles.mibPreferencesGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibPreferencesGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

varargout{1} = handles.output;
end

% --- Executes on button press in OKBtn.
function OKBtn_Callback(hObject, eventdata, handles)
% hObject    handle to OKBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.OKBtn_Callback();
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
% hObject    handle to cancelBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end


% --- Executes when user attempts to close mibPreferencesGUI.
function mibPreferencesGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibPreferencesGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();

end

% --- Executes on key press over mibPreferencesGUI with no controls selected.
function mibPreferencesGUI_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to mibPreferencesGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check for "enter" or "escape"
if isequal(get(hObject,'CurrentKey'), 'escape')
    handles.winController.closeWindow();
end

% if isequal(get(hObject,'CurrentKey'),'return')
%     uiresume(handles.mibPreferencesGUI);
% end
end

% --- Executes on selection change in mouseWheelPopup.
function mouseWheelPopup_Callback(hObject, eventdata, handles)
handles.winController.mouseWheelPopup_Callback();
end


% --- Executes on selection change in mouseButtonPopup.
function mouseButtonPopup_Callback(hObject, eventdata, handles)
handles.winController.mouseButtonPopup_Callback();
end


% --- Executes on selection change in undoPopup.
function undoPopup_Callback(hObject, eventdata, handles)
handles.winController.undoPopup_Callback();
end


% --- Executes on selection change in imresizePopup.
function imresizePopup_Callback(hObject, eventdata, handles)
handles.winController.imresizePopup_Callback();
end

% --- Executes on button press in colorSelectionBtn.
function colorSelectionBtn_Callback(hObject, eventdata, handles)
handles.winController.colorSelectionBtn_Callback();
end

% --- Executes on button press in colorMaskBtn.
function colorMaskBtn_Callback(hObject, eventdata, handles)
handles.winController.colorMaskBtn_Callback();
end

% --- Executes on press of the color selector for materials
function colorModelSelection_Callback(hObject, eventdata, handles)
handles.winController.colorModelSelection_Callback();
end

function updateModelColorTable(handles)
% adding colors to the color table for materials
handles.winController.updateModelColorTable();
end

function modelsColorsTable_cb(hObject, eventdata, parameter)
% callback to the popup menu of handles.modelsColorsTable
handles = guidata(hObject);
handles.winController.modelsColorsTable_cb(parameter);
end

function updateLUTColorTable(handles)
% adding colors to the color table for the color channels LUT
handles.winController.updateLUTColorTable();
end

% --- Executes when selected cell(s) is changed in modelsColorsTable.
function modelsColorsTable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to modelsColorsTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)

if isempty(eventdata.Indices); return; end; % for return after modelColorsTable_CellEditCallback error

handles.modelsColorsTable.UserData = eventdata.Indices;   % store selected position
guidata(hObject, handles); % Update handles structure

if eventdata.Indices(2) == 4    % start color selection dialog
    handles.winController.colorModelSelection_Callback();
end
end


% --- Executes when entered data in editable cell(s) in modelsColorsTable.
function modelsColorsTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to modelsColorsTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
handles.winController.modelsColorsTable_CellEditCallback(eventdata);
end

% --- Executes when entered data in editable cell(s) in modelsColorsTable.
function lutColorsTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to modelsColorsTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
handles.winController.lutColorsTable_CellEditCallback(eventdata);
end

% --- Executes on button press in applyBtn.
function applyBtn_Callback(hObject, eventdata, handles)
handles.winController.applyBtn_Callback();
end

function undoHistory_Callback(hObject, eventdata, handles)
handles.winController.undoHistory_Callback();
end


% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'techdoc/html/ug_gui_menu_file_preferences.html'), '-helpbrowser');
end

% --- Executes on selection change in disableSelectionPopup.
function disableSelectionPopup_Callback(hObject, eventdata, handles)
handles.winController.disableSelectionPopup_Callback();
end

% --- Executes on selection change in interpolationTypePopup.
function interpolationTypePopup_Callback(hObject, eventdata, handles)
handles.winController.interpolationTypePopup_Callback();
end

function interpolationNoPoints_Callback(hObject, eventdata, handles)
handles.winController.interpolationNoPoints_Callback();
end

function interpolationLineWidth_Callback(hObject, eventdata, handles)
handles.winController.interpolationLineWidth_Callback();
end


% --- Executes on selection change in maxModelPopup.
function maxModelPopup_Callback(hObject, eventdata, handles)
handles.winController.maxModelPopup_Callback();
end

% --- Executes when selected cell(s) is changed in modelsColorsTable.
function lutColorsTable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to modelsColorsTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
if isempty(eventdata.Indices); return; end; % for return after lutColorsTable_CellSelectionCallback error
handles.lutColorsTable.UserData = eventdata.Indices;   % store selected position
guidata(hObject, handles); % Update handles structure

if eventdata.Indices(2) == 4    % start color selection dialog
    handles.winController.colorChannelSelection_Callback();
end
end

% --- Executes on button of color stripe in the Color channels table
function colorChannelSelection_Callback(hObject, eventdata, handles)
handles.winController.colorChannelSelection_Callback();
end

function fontSizeDirEdit_Callback(hObject, eventdata, handles)

end

function fontSizeEdit_Callback(hObject, eventdata, handles)
% update font size for mibPreferencesGUI
handles.winController.fontSizeEdit_Callback();
end

% --- Executes on button press in annotationColorBtn.
function annotationColorBtn_Callback(hObject, eventdata, handles)
handles.winController.annotationColorBtn_Callback();
end


% --- Executes on selection change in annotationFontSizeCombo.
function annotationFontSizeCombo_Callback(hObject, eventdata, handles)
handles.winController.annotationFontSizeCombo_Callback();
end

% --- Executes on button press in defaultBtn.
function defaultBtn_Callback(hObject, eventdata, handles)
handles.winController.defaultBtn_Callback();    
end


% --- Executes on selection change in paletteTypePopup.
function paletteTypePopup_Callback(hObject, eventdata, handles)
handles.winController.paletteTypePopup_Callback();
end

function updateColorPalette(hObject, eventdata, handles)
handles.winController.updateColorPalette();
end

% --- Executes on button press in fontBtn.
function fontBtn_Callback(hObject, eventdata, handles)
handles.winController.fontBtn_Callback();
end

% --- Executes on button press in keyShortcutsBtn.
function keyShortcutsBtn_Callback(hObject, eventdata, handles)
handles.winController.keyShortcutsBtn_Callback();
end


% --- Executes on button press in externalDirsBtn.
function externalDirsBtn_Callback(hObject, eventdata, handles)
handles.winController.externalDirsBtn_Callback();
end


% --- Executes on button press in guiScalingBtn.
function guiScalingBtn_Callback(hObject, eventdata, handles)
handles.winController.guiScalingBtn_Callback();
end
