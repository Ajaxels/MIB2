function varargout = mibLines3DGUI(varargin)
% function varargout = mibLines3DGUI(varargin)
% mibLines3DGUI is a GUI tool to show list of labels

% Copyright (C) 16.05.2014, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 25.01.2016, updated for 4D


% Edit the above text to modify the response to help mibLines3DGUI

% Last Modified by GUIDE v2.5 25-Apr-2018 21:50:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibLines3DGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibLines3DGUI_OutputFcn, ...
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
% End initialization code - DO NOT EDIT
end

% --- Executes just before mibLines3DGUI is made visible.
function mibLines3DGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibLines3DGUI (see VARARGIN)

global mibPath;

% obtain controller
handles.winController = varargin{1};

% rearrange elements of GUI
handles.mibLines3DGUI.Position(3) = 270;
handles.tablePanel.Units = 'normalized';
handles.toolPanel.Units = 'normalized';
handles.edgesViewTable.Parent = handles.nodesViewTable.Parent;
handles.edgesViewTable.Position = handles.nodesViewTable.Position;
handles.edgesViewAdditionalField.Parent = handles.nodesViewAdditionalField.Parent;
handles.edgesViewAdditionalField.Position = handles.nodesViewAdditionalField.Position;
handles.edgesViewAdditionalField.Visible = 'off';

%updateTable(handles);
% indeces of the selected rows
handles.indices = [];

handles.nodesViewTable_cm = uicontextmenu('Parent',handles.mibLines3DGUI);
uimenu(handles.nodesViewTable_cm, 'Label', 'Jump to the node', 'Callback', {@nodesViewTable_cb, 'Jump'});
uimenu(handles.nodesViewTable_cm, 'Label', 'Set as active node', 'Callback', {@nodesViewTable_cb, 'Active'});
uimenu(handles.nodesViewTable_cm, 'Label', 'Rename selected nodes...', 'Callback', {@nodesViewTable_cb, 'Rename'});
uimenu(handles.nodesViewTable_cm, 'Label', 'Show coordinates in pixels...', 'Callback', {@nodesViewTable_cb, 'Pixels'});
uimenu(handles.nodesViewTable_cm, 'Label', 'New annotations from nodes', 'Separator','on', 'Callback', {@nodesViewTable_cb, 'AnnotationsNew'});
uimenu(handles.nodesViewTable_cm, 'Label', 'Add nodes to annotations', 'Callback', {@nodesViewTable_cb, 'AnnotationsAdd'});
uimenu(handles.nodesViewTable_cm, 'Label', 'Delete nodes from annotations', 'Callback', {@nodesViewTable_cb, 'AnnotationsDelete'});
uimenu(handles.nodesViewTable_cm, 'Label', 'Delete nodes...', 'Separator','on', 'Callback', {@nodesViewTable_cb, 'Delete'});
set(handles.nodesViewTable,'UIContextMenu',handles.nodesViewTable_cm);

handles.treesViewTable_cm = uicontextmenu('Parent',handles.mibLines3DGUI);
uimenu(handles.treesViewTable_cm, 'Label', 'Rename selected tree...', 'Callback', {@treesViewTable_cb, 'rename'});
uimenu(handles.treesViewTable_cm, 'Label', 'Find tree by node...', 'Callback', {@treesViewTable_cb, 'find'});
uimenu(handles.treesViewTable_cm, 'Label', 'Visualize in 3D selected tree(s)', 'Callback', {@treesViewTable_cb, 'visualize'});
uimenu(handles.treesViewTable_cm, 'Label', 'Save/export selected tree(s)', 'Callback', {@treesViewTable_cb, 'save'});
uimenu(handles.treesViewTable_cm, 'Label', 'Delete selected tree(s)...', 'Separator','on', 'Callback', {@treesViewTable_cb, 'delete'});
set(handles.treesViewTable,'UIContextMenu',handles.treesViewTable_cm);

handles.edgesViewTable_cm = uicontextmenu('Parent',handles.mibLines3DGUI);
uimenu(handles.edgesViewTable_cm, 'Label', 'Jump to the node', 'Callback', {@edgesViewTable_cb, 'Jump'});
uimenu(handles.edgesViewTable_cm, 'Label', 'Set as active node', 'Callback', {@edgesViewTable_cb, 'Active'});
set(handles.edgesViewTable,'UIContextMenu',handles.edgesViewTable_cm);

% update font and size
global Font;
if ~isempty(Font)
    if handles.jumpCheck.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.jumpCheck.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibLines3DGUI, Font);
    end
end
% resize all elements x1.25 times for macOS
handles.middlePanel.Units = 'points';   % change of units requires for correct resizing on Macs
handles.tablePanel.Units = 'points';
mibRescaleWidgets(handles.mibLines3DGUI);
handles.middlePanel.Units = 'normalized';
handles.tablePanel.Units = 'normalized';

% Choose default command line output for mibLines3DGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibLines3DGUI wait for user response (see UIRESUME)
% uiwait(handles.mibLines3DGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibLines3DGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes when user attempts to close mibLines3DGUI.
function mibLines3DGUI_CloseRequestFcn(hObject, eventdata, handles)
handles.winController.closeWindow();
end

function nodesViewTable_cb(hObject, eventdata, parameter)
handles = guidata(hObject);
handles.winController.nodesViewTable_cb(parameter);
end

function edgesViewTable_cb(hObject, eventdata, parameter)
handles = guidata(hObject);
handles.winController.edgesViewTable_cb(parameter);
end


function treesViewTable_cb(hObject, eventdata, parameter)
handles = guidata(hObject);
handles.winController.treesViewTable_cb(parameter);
end

% --- Executes on button press in saveBtn.
function saveBtn_Callback(hObject, eventdata, handles)
handles.winController.saveBtn_Callback();
end

% --- Executes when entered data in editable cell(s) in treesViewTable.
function treesViewTable_CellEditCallback(hObject, eventdata, handles)
Indices = eventdata.Indices;
handles.winController.treesViewTable_CellEditCallback(Indices)
end

% --- Executes when selected cell(s) is changed in treesViewTable.
function treesViewTable_CellSelectionCallback(hObject, eventdata, handles)
Indices = eventdata.Indices;
handles.winController.treesViewTable_CellSelectionCallback(Indices);
end


% --- Executes when selected cell(s) is changed in nodesViewTable.
function nodesViewTable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to nodesViewTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
Indices = eventdata.Indices;
handles.winController.nodesViewTable_CellSelectionCallback(Indices);
end


% --- Executes when selected cell(s) is changed in edgesViewTable.
function edgesViewTable_CellSelectionCallback(hObject, eventdata, handles)
Indices = eventdata.Indices;
handles.winController.edgesViewTable_CellSelectionCallback(Indices);
end

% --- Executes on button press in loadBtn.
function loadBtn_Callback(hObject, eventdata, handles)
handles.winController.loadBtn_Callback();
end

% --- Executes on button press in refreshBtn.
function refreshBtn_Callback(hObject, eventdata, handles)
handles.winController.updateWidgets();
end

% --- Executes on button press in deleteBtn.
function deleteBtn_Callback(hObject, eventdata, handles)
handles.winController.deleteBtn_Callback();
end


% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'techdoc/html/ug_panel_segm_tools.html#2'), '-helpbrowser');
end

% --- Executes on button press in settingsBtn.
function settingsBtn_Callback(hObject, eventdata, handles)
handles.winController.settingsBtn_Callback();
end

% --- Executes on selection change in nodesViewAdditionalField.
function nodesViewAdditionalField_Callback(hObject, eventdata, handles)
handles.winController.updateNodesViewTable();
end

% --- Executes on selection change in edgesViewAdditionalField.
function edgesViewAdditionalField_Callback(hObject, eventdata, handles)
handles.winController.updateEdgesViewTable();
end

% --- Executes when entered data in editable cell(s) in nodesViewTable.
function nodesViewTable_CellEditCallback(hObject, eventdata, handles)
handles.winController.nodesViewTable_CellEditCallback(eventdata);
end

% --- Executes when entered data in editable cell(s) in edgesViewTable.
function edgesViewTable_CellEditCallback(hObject, eventdata, handles)
handles.winController.edgesViewTable_CellEditCallback(eventdata);
end

% --- Executes on button press in visualizeBtn.
function visualizeBtn_Callback(hObject, eventdata, handles)
% hObject    handle to visualizeBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.visualizeBtn_Callback();
end


% --- Executes on selection change in tableSelectionPopup.
function tableSelectionPopup_Callback(hObject, eventdata, handles)
% hObject    handle to tableSelectionPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tableSelectionPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tableSelectionPopup
curVal = handles.tableSelectionPopup.String{handles.tableSelectionPopup.Value};
switch curVal
    case 'Nodes'
        handles.edgesViewTable.Visible = 'off';
        handles.nodesViewTable.Visible = 'on';
        handles.edgesViewAdditionalField.Visible = 'off';
        handles.nodesViewAdditionalField.Visible = 'on';
    case 'Edges'
        handles.nodesViewTable.Visible = 'off';
        handles.edgesViewTable.Visible = 'on';
        handles.nodesViewAdditionalField.Visible = 'off';
        handles.edgesViewAdditionalField.Visible = 'on';
end
handles.winController.updateWidgets();
end
