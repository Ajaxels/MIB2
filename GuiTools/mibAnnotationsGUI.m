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

function varargout = mibAnnotationsGUI(varargin)
% function varargout = mibAnnotationsGUI(varargin)
% mibAnnotationsGUI is a GUI tool to show list of labels

% Updates
% 25.01.2016, updated for 4D


% Edit the above text to modify the response to help mibAnnotationsGUI

% Last Modified by GUIDE v2.5 06-Feb-2024 18:16:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mibAnnotationsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mibAnnotationsGUI_OutputFcn, ...
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

% --- Executes just before mibAnnotationsGUI is made visible.
function mibAnnotationsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibAnnotationsGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

repositionSwitch = 1; % reposition the figure, when creating a new figure

%updateTable(handles);
% indeces of the selected rows
handles.indices = [];

handles.labelsTable_cm = uicontextmenu('Parent',handles.mibAnnotationsGUI);
uimenu(handles.labelsTable_cm, 'Label', 'Jump to annotation', 'Callback', {@tableContextMenu_cb, 'Jump'});
uimenu(handles.labelsTable_cm, 'Label', 'Add annotation...', 'Callback', {@tableContextMenu_cb, 'Add'});
uimenu(handles.labelsTable_cm, 'Label', 'Rename selected annotations...', 'Callback', {@tableContextMenu_cb, 'Rename'});
uimenu(handles.labelsTable_cm, 'Label', 'Batch modify selected annotations...', 'Callback', {@tableContextMenu_cb, 'Modify'});
uimenu(handles.labelsTable_cm, 'Label', 'Count selected annotations', 'Callback', {@tableContextMenu_cb, 'Count'});
uimenu(handles.labelsTable_cm, 'Label', 'Copy selected annotations to clipboard', 'Callback', {@tableContextMenu_cb, 'Clipboard'}, 'Separator', 'on');
uimenu(handles.labelsTable_cm, 'Label', 'Paste from clipboard to column', 'Callback', {@tableContextMenu_cb, 'ClipboardPaste'});
uimenu(handles.labelsTable_cm, 'Label', 'Convert selected annotations to Mask...', 'Callback', {@tableContextMenu_cb, 'Mask'});
uimenu(handles.labelsTable_cm, 'Label', 'Crop out patches around selected annotation...', 'Callback', {@tableContextMenu_cb, 'CropPatches'});
uimenu(handles.labelsTable_cm, 'Label', 'Interpolate between selected annotations...', 'Callback', {@tableContextMenu_cb, 'Interpolate'});
uimenu(handles.labelsTable_cm, 'Label', 'Export selected annotations...', 'Separator','on', 'Callback', {@tableContextMenu_cb, 'Export'});
uimenu(handles.labelsTable_cm, 'Label', 'Export selected annotations to Imaris', 'Callback', {@tableContextMenu_cb, 'Imaris'});
m09 = uimenu(handles.labelsTable_cm, 'Label', 'Order', 'Separator','on');
uimenu(handles.labelsTable_cm, 'Parent', m09, 'Label', 'Move to top  (Ctrl+Shift+Up)', 'Callback', {@tableContextMenu_cb, 'OrderTop'});
uimenu(handles.labelsTable_cm, 'Parent', m09, 'Label', 'Move up (Ctrl+Up)', 'Callback', {@tableContextMenu_cb, 'OrderUp'});
uimenu(handles.labelsTable_cm, 'Parent', m09, 'Label', 'Move down  (Ctrl+Down)', 'Callback', {@tableContextMenu_cb, 'OrderDown'});
uimenu(handles.labelsTable_cm, 'Parent', m09, 'Label', 'Move to bottom (Ctrl+Shift+Down)', 'Callback', {@tableContextMenu_cb, 'OrderBottom'});
uimenu(handles.labelsTable_cm, 'Label', 'Delete selected annotation(s)...', 'Separator','on', 'Callback', {@tableContextMenu_cb, 'Delete'});
set(handles.annotationTable,'UIContextMenu',handles.labelsTable_cm);


% update font and size
global Font;
if ~isempty(Font)
    if handles.jumpCheck.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.jumpCheck.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibAnnotationsGUI, Font);
    end
end
% resize all elements x1.25 times for macOS
mibRescaleWidgets(handles.mibAnnotationsGUI);

% Choose default command line output for mibAnnotationsGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibAnnotationsGUI wait for user response (see UIRESUME)
% uiwait(handles.mibAnnotationsGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibAnnotationsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes when user attempts to close mibAnnotationsGUI.
function mibAnnotationsGUI_CloseRequestFcn(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in closeBtn.
function closeBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

function tableContextMenu_cb(hObject, eventdata, parameter)
handles = guidata(hObject);
handles.winController.tableContextMenu_cb(parameter);
end


% --- Executes on button press in saveBtn.
function saveBtn_Callback(hObject, eventdata, handles)
handles.winController.saveBtn_Callback();
end

% --- Executes when entered data in editable cell(s) in annotationTable.
function annotationTable_CellEditCallback(hObject, eventdata, handles)
Indices = eventdata.Indices;
handles.winController.annotationTable_CellEditCallback(Indices)
end

% --- Executes when selected cell(s) is changed in annotationTable.
function annotationTable_CellSelectionCallback(hObject, eventdata, handles)
Indices = eventdata.Indices;
handles.winController.annotationTable_CellSelectionCallback(Indices);
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


% --- Executes on selection change in resortTablePopup.
function resortTablePopup_Callback(hObject, eventdata, handles)
handles.winController.resortTablePopup_Callback();
end


% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'techdoc/html/ug_panel_segm_tools.html#3'), '-helpbrowser');
end

function precisionEdit_Callback(hObject, eventdata, handles)
handles.winController.precisionEdit_Callback();
end


% --- Executes on key press with focus on annotationTable and none of its controls.
function annotationTable_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to annotationTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

if isempty(eventdata.Modifier); return; end

if ismember(eventdata.Key, {'uparrow', 'downarrow'}) && ...
        ismember('control', eventdata.Modifier)
    handles.winController.annotationTable_KeyPressFcn(eventdata);
end
end


% --- Executes on button press in settingsButton.
function settingsButton_Callback(hObject, eventdata, handles)
handles.winController.settingsBtn_Callback();
end


% --- Executes on key press with focus on mibAnnotationsGUI and none of its controls.
function mibAnnotationsGUI_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to mibAnnotationsGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

handles.winController.mibAnnotationsGUI_KeyPressFcn(eventdata);
end